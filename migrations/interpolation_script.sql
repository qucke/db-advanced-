DO $$
BEGIN
    -- 1. Создание типа данных для структуры интерполяции
    BEGIN
        CREATE TYPE calc_point AS (
            x0 numeric,
            y0 numeric,
            x1 numeric,
            y1 numeric
        );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;

    -- 2. Функция для определения параметров (границ) интерполяции по температуре из таблицы
	CREATE OR REPLACE FUNCTION get_temp_bounds_from_table(p_temp numeric)
	RETURNS calc_point AS $func$
	DECLARE
    	v_bounds calc_point;
	BEGIN
    	IF p_temp <= 0 THEN
        	-- Для t <= 0: коррекция = 0
        	v_bounds.x0 := 0;
        	v_bounds.y0 := 0;
        	v_bounds.x1 := 0;
        	v_bounds.y1 := 0;
        	RETURN v_bounds;
    	ELSIF p_temp < 5 THEN
        	v_bounds.x0 := 0;
        	v_bounds.y0 := 0;
        	v_bounds.x1 := 5;
        	v_bounds.y1 := 0.5;
        	RETURN v_bounds;
    	END IF;
    
    	SELECT temperature, correction
    	INTO v_bounds.x0, v_bounds.y0
    	FROM calc_temperature_correction
    	WHERE temperature <= p_temp
    	ORDER BY temperature DESC
    	LIMIT 1;

    	SELECT temperature, correction
    	INTO v_bounds.x1, v_bounds.y1
    	FROM calc_temperature_correction
    	WHERE temperature >= p_temp
    	ORDER BY temperature ASC
    	LIMIT 1;

    	-- Если температура ниже минимальной в таблице
    	IF v_bounds.x0 IS NULL THEN
        	SELECT temperature, correction INTO v_bounds.x0, v_bounds.y0
        	FROM calc_temperature_correction ORDER BY temperature ASC LIMIT 1;
        	v_bounds.x1 := v_bounds.x0;
        	v_bounds.y1 := v_bounds.y0;
    	END IF;

    	-- Если температура выше максимальной в таблице
    	IF v_bounds.x1 IS NULL THEN
        	SELECT temperature, correction INTO v_bounds.x1, v_bounds.y1
        	FROM calc_temperature_correction ORDER BY temperature DESC LIMIT 1;
        	v_bounds.x0 := v_bounds.x1;
        	v_bounds.y0 := v_bounds.y1;
    	END IF;

    	RETURN v_bounds;
	END;
	$func$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION calc_interpolation(x numeric, bounds calc_point)
    RETURNS numeric AS $func$
    DECLARE
        dx numeric;
        dy numeric;
        v_result numeric;
    BEGIN
        dx := bounds.x1 - bounds.x0;
        dy := bounds.y1 - bounds.y0;
        
        IF dx = 0 OR dx IS NULL THEN
            v_result := bounds.y0;
        ELSE
            v_result := bounds.y0 + ((x - bounds.x0) * dy) / dx;
        END IF;
        
        RETURN round(v_result::numeric, 2);
    END;
    $func$ LANGUAGE plpgsql;

END $$;