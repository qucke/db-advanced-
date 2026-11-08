DO $$
BEGIN
    CREATE TYPE input_params_type AS
    (height numeric(8,2), temperature numeric(8,2),
        pressure numeric(8,2), wind_direction numeric(8,2),
        wind_speed numeric(8,2), bullet_range numeric(8,2));

    CREATE OR REPLACE FUNCTION public.correction_value(
        p_params public.input_params_type,
        p_type_id integer,
        p_column_val integer
    ) RETURNS integer
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_result integer;
        v_height_id integer;
        v_header_arr integer[];
        v_idx integer;
    BEGIN
        SELECT id INTO v_height_id 
        FROM public.calc_correction_heights 
        WHERE height = p_params.height 
        LIMIT 1;

        SELECT h.header_values INTO v_header_arr
        FROM public.calc_correction_types t
        JOIN public.calc_correction_headers h ON h.id = t.header_id
        WHERE t.id = p_type_id;

        IF v_header_arr IS NULL THEN
            RETURN NULL;
        END IF;

        v_idx := array_position(v_header_arr, p_column_val);    
        IF v_idx IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT c.row_values[v_idx] INTO v_result
        FROM public.calc_correction c
        WHERE c.type_id = p_type_id
        AND c.height_id = v_height_id
        LIMIT 1;
        RETURN v_result;
    END;
    $func$;


    CREATE OR REPLACE FUNCTION public.wind_speed(
        p_params public.input_params_type,
        p_type_id integer
    ) RETURNS integer
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_result integer;
        v_height_id integer;
        v_header_arr integer[];
        v_wind_value numeric;
        v_best_header integer;
        v_idx integer;
        c_type_speed_vr CONSTANT int := 4;
    BEGIN
        IF p_type_id = c_type_speed_vr OR p_type_id = 5 THEN
            v_wind_value := coalesce(p_params.bullet_range, 0);
        ELSE
            v_wind_value := coalesce(p_params.wind_speed, 0);
        END IF;

        SELECT id INTO v_height_id 
        FROM public.calc_correction_heights 
        WHERE height = p_params.height 
        LIMIT 1;

        SELECT h.header_values INTO v_header_arr
        FROM public.calc_correction_types t
        JOIN public.calc_correction_headers h ON h.id = t.header_id
        WHERE t.id = p_type_id;

        IF v_header_arr IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT headers.value, headers.i
        INTO v_best_header, v_idx
        FROM unnest(v_header_arr) WITH ORDINALITY AS headers(value, i)
        ORDER BY abs(headers.value - v_wind_value), headers.value
        LIMIT 1;

        SELECT c.row_values[v_idx] INTO v_result
        FROM public.calc_correction c
        WHERE c.type_id = p_type_id
        AND c.height_id = v_height_id
        LIMIT 1;

        RETURN v_result;
    END;
    $func$;
    CREATE OR REPLACE PROCEDURE public.calc_meteo_bulletin(
        p public.input_params_type,
        p_equipment_id int
    )
    LANGUAGE plpgsql
    AS $proc$
    DECLARE
        c_eq_dmk CONSTANT int := 1;
        c_eq_vr  CONSTANT int := 2;
        c_base_temp CONSTANT numeric := 15.9;
        c_wind_zero_dmk CONSTANT numeric := 3.0;
        c_wind_zero_vr  CONSTANT numeric := 40.0;
        c_type_temp_pos CONSTANT int := 8;
        c_type_temp_neg CONSTANT int := 9;
        c_type_speed_vr CONSTANT int := 4;
        c_type_dir_vr   CONSTANT int := 5;
        c_type_speed_dmk CONSTANT int := 6;
        c_type_dir_dmk  CONSTANT int := 7;

        v_temp_type integer;
        v_speed_type integer;
        v_dir_type integer;
        v_delta integer;
        v_wind_value numeric;
        v_wind_zero boolean;
    BEGIN
        v_delta := round(p.temperature + public.fn_calc_temperature_interpolation(p.temperature) - c_base_temp)::integer;
        IF p_equipment_id = c_eq_dmk THEN
            v_speed_type := c_type_speed_dmk;
            v_dir_type   := c_type_dir_dmk;
            v_wind_value := coalesce(p.wind_speed, 0);
            v_wind_zero  := v_wind_value < c_wind_zero_dmk;
            
        ELSE p_equipment_id = c_eq_vr THEN
            v_speed_type := c_type_speed_vr;
            v_dir_type   := c_type_dir_vr;
            v_wind_value := coalesce(p.bullet_range, 0);
            v_wind_zero  := v_wind_value < c_wind_zero_vr;        
        END IF;

        v_temp_type := CASE WHEN v_delta < 0 THEN c_type_temp_neg ELSE c_type_temp_pos END;

        CREATE TEMP TABLE IF NOT EXISTS calc_meteo_result (
            height integer,
            tt text,
            hh text,
            cc text
        );
        TRUNCATE TABLE calc_meteo_result;

        INSERT INTO calc_meteo_result (height, tt, hh, cc)
        SELECT
            h.height,
            lpad((CASE
                    WHEN v_delta < 0 THEN 50 + abs(x.corr)
                    ELSE x.corr
                END)::text, 2, '0') AS tt,
                
            CASE
                WHEN v_wind_zero THEN '00'
                ELSE lpad(
                    mod(coalesce(p.wind_direction, 0)::integer +
                    (SELECT c.row_values[1]
                    FROM public.calc_correction c
                    WHERE c.type_id = v_dir_type
                        AND c.height_id = h.id), 60)::text, 2, '0')
            END AS hh,
            
            CASE
                WHEN v_wind_zero THEN '00'
                ELSE lpad(public.wind_speed(p, v_speed_type)::text, 2, '0')
            END AS cc
            
        FROM public.calc_correction_heights h
        CROSS JOIN LATERAL (
            SELECT
                coalesce(public.correction_value(p, v_temp_type, (abs(v_delta) / 10) * 10), 0)
                + coalesce(public.correction_value(p, v_temp_type, abs(v_delta) % 10), 0) AS corr
        ) x ORDER BY h.height;

    END;
    $proc$;
    
