DO $$
BEGIN
    CREATE OR REPLACE FUNCTION public.get_setting(p_key text)
    RETURNS text
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_value text;
    BEGIN
        SELECT value INTO v_value
        FROM public.measurment_settings
        WHERE key = p_key;
        IF v_value IS NULL THEN
            RAISE EXCEPTION 'Настройка с ключом "%" не найдена', p_key;
        END IF;
        RETURN v_value;
    END;
    $func$;

    CREATE OR REPLACE FUNCTION public.format_tt(p_delta integer, p_corr integer)
    RETURNS text
    LANGUAGE plpgsql
    AS $func$
    BEGIN
        RETURN lpad((CASE WHEN p_delta < 0 THEN 50 + abs(p_corr) ELSE abs(p_corr) END)::text, 2, '0');
    END;
    $func$;

    CREATE OR REPLACE FUNCTION public.format_hh(p_wind_dir integer, p_angle_corr integer)
    RETURNS text
    LANGUAGE plpgsql
    AS $func$
    BEGIN
        RETURN lpad(mod(p_wind_dir + p_angle_corr, 60)::text, 2, '0');
    END;
    $func$;

    CREATE OR REPLACE FUNCTION public.format_cc(p_speed integer)
    RETURNS text
    LANGUAGE plpgsql
    AS $func$
    BEGIN
        RETURN lpad(coalesce(p_speed, 0)::text, 2, '0');
    END;
    $func$;

    CREATE OR REPLACE FUNCTION public.correction_value(
        p_type_id integer,
        p_height_id integer,
        p_column_val integer
    ) RETURNS integer
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_header_arr integer[];
        v_idx integer;
        v_result integer;
    BEGIN
        IF p_column_val IS NULL OR p_column_val = 0 THEN
            RETURN 0;
        END IF;

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
        AND c.height_id = p_height_id;

        RETURN v_result;
    END;
    $func$;
    
    CREATE OR REPLACE FUNCTION public.wind_speed(
        p_params public.input_params_type,
        p_type_id integer,
        p_height_id integer
    ) RETURNS integer
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_header_arr integer[];
        v_wind_value numeric;
        v_idx integer;
        v_result integer;
    BEGIN
        IF p_type_id IN (public.get_setting('type_speed_vr_id')::integer,
                        public.get_setting('type_dir_vr_id')::integer) THEN
            v_wind_value := coalesce(p_params.bullet_demolition_range, 0);
        ELSE
            v_wind_value := coalesce(p_params.wind_speed, 0);
        END IF;

        SELECT h.header_values INTO v_header_arr
        FROM public.calc_correction_types t
        JOIN public.calc_correction_headers h ON h.id = t.header_id
        WHERE t.id = p_type_id;

        IF v_header_arr IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT headers.i INTO v_idx
        FROM unnest(v_header_arr) WITH ORDINALITY AS headers(value, i)
        ORDER BY abs(headers.value - v_wind_value), headers.value
        LIMIT 1;

        SELECT c.row_values[v_idx] INTO v_result
        FROM public.calc_correction c
        WHERE c.type_id = p_type_id
        AND c.height_id = p_height_id;

        RETURN v_result;
    END;
    $func$;

    CREATE OR REPLACE FUNCTION public.wind_angle_corr(
        p_type_id integer,
        p_height_id integer
    ) RETURNS integer
    LANGUAGE plpgsql
    AS $func$
    BEGIN
        RETURN coalesce((SELECT c.row_values[1]
            FROM public.calc_correction c
            WHERE c.type_id = p_type_id
            AND c.height_id = p_height_id),0);
    END;
    $func$;

    CREATE OR REPLACE PROCEDURE public.calc_meteo_bulletin(
        p public.input_params_type,
        p_equipment_id int
    )
    LANGUAGE plpgsql
    AS $proc$
    DECLARE
        v_temp_type integer;
        v_speed_type integer;
        v_dir_type integer;
        v_delta integer;
        v_wind_value numeric;
        v_wind_zero boolean;
    BEGIN
        v_delta := floor(p.temperature + public.fn_calc_temperature_interpolation(p.temperature) - public.get_setting('calc_table_temperature')::numeric
        )::integer;

        IF p_equipment_id = public.get_setting('equipment_dmk_id')::integer THEN
            v_speed_type := public.get_setting('type_speed_dmk_id')::integer;
            v_dir_type := public.get_setting('type_dir_dmk_id')::integer;
            v_wind_value := coalesce(p.wind_speed, 0);
            v_wind_zero := v_wind_value < public.get_setting('wind_zero_dmk')::numeric;

        ELSE
            v_speed_type := public.get_setting('type_speed_vr_id')::integer;
            v_dir_type := public.get_setting('type_dir_vr_id')::integer;
            v_wind_value := coalesce(p.bullet_demolition_range, 0);
            v_wind_zero := v_wind_value < public.get_setting('wind_zero_vr')::numeric;
        END IF;

        v_temp_type := CASE
            WHEN v_delta < 0 THEN public.get_setting('type_temp_neg_id')::integer
            ELSE public.get_setting('type_temp_pos_id')::integer
        END;

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
            public.format_tt(v_delta, x.corr) AS tt,
            CASE WHEN v_wind_zero THEN '00'
                ELSE public.format_hh(coalesce(p.wind_direction, 0)::integer,public.wind_angle_corr(v_dir_type, h.id))
            END AS hh,
            CASE WHEN v_wind_zero THEN '00'
                ELSE public.format_cc(public.wind_speed(p, v_speed_type, h.id))
            END AS cc
        FROM public.calc_correction_heights h
        CROSS JOIN LATERAL (
            SELECT coalesce(public.correction_value(v_temp_type, h.id, (abs(v_delta) / 10) * 10), 0)
                + coalesce(public.correction_value(v_temp_type, h.id, abs(v_delta) % 10), 0) AS corr) x ORDER BY h.height;
    END;
    $proc$;
END $$;