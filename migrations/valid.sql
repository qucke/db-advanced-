DO $$
BEGIN
    BEGIN
        ALTER TABLE types_parameters ADD COLUMN min_val numeric;
        ALTER TABLE types_parameters ADD COLUMN max_val numeric;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;

    UPDATE types_parameters SET min_val = -9999, max_val = 9999 WHERE id = 1; -- Высота 
    UPDATE types_parameters SET min_val = -58, max_val = 58 WHERE id = 2;     -- Температура
    UPDATE types_parameters SET min_val = 500, max_val = 900 WHERE id = 3;    -- Давление
    UPDATE types_parameters SET min_val = 0, max_val = 59 WHERE id = 4;       -- Направление ветра
    UPDATE types_parameters SET min_val = 0, max_val = 15 WHERE id = 5;       -- Скорость ветра 
    UPDATE types_parameters SET min_val = 0, max_val = 150 WHERE id = 6;      -- Дальность сноса 

    -- 1. Справочник сообщений об ошибках
    CREATE TABLE IF NOT EXISTS Errors (
        code text PRIMARY KEY,
        message text NOT NULL
    );
    
    INSERT INTO Errors (code, message) VALUES
    ('MISSING_PARAM', 'Отсутствует обязательный параметр'),
    ('FORBIDDEN_PARAM', 'Параметр недопустим для данного оборудования'),
    ('OUT_OF_RANGE', 'Значение вне допустимого диапазона')
    ON CONFLICT (code) DO NOTHING;

    -- 2. Типы данных
    BEGIN
        CREATE TYPE parameter_value AS (parametr_id int, parametr_value numeric);
    EXCEPTION WHEN duplicate_object THEN NULL; END;
    
    BEGIN
        CREATE TYPE parameter_list AS (equipment_id int, params parameter_value[]);
    EXCEPTION WHEN duplicate_object THEN NULL; END;

    -- 3. Функция валидации параметров
    CREATE OR REPLACE FUNCTION validate_parameters(p_list parameter_list)
    RETURNS text
    LANGUAGE plpgsql
    STABLE AS $func$
    DECLARE
        v_errors text := '';
        v_item parameter_value;
        v_type types_parameters%ROWTYPE;
        v_required int[];
        v_seen int[] := ARRAY[]::int[];
        v_id int;
    BEGIN
        v_required := CASE p_list.equipment_id
            WHEN 1 THEN ARRAY[1, 2, 3, 4, 5]
            WHEN 2 THEN ARRAY[1, 2, 3, 4, 6]
            ELSE NULL
        END;

        FOREACH v_item IN ARRAY p_list.params LOOP
            v_seen := v_seen || v_item.parametr_id;
            
            SELECT * INTO v_type FROM types_parameters WHERE id = v_item.parametr_id;
            
            -- Проверка на недопустимый параметр
            IF v_required IS NOT NULL AND NOT (v_item.parametr_id = ANY(v_required)) THEN
                v_errors := v_errors || format('%s: %s; ', 
                    (SELECT message FROM Errors WHERE code = 'FORBIDDEN_PARAM'), v_type.name);
            END IF;

            -- Проверка диапазона 
            IF v_item.parametr_value IS NULL OR v_item.parametr_value < v_type.min_val OR v_item.parametr_value > v_type.max_val THEN
                v_errors := v_errors || format('%s: %s = %s (допустимо %s..%s); ', 
                    (SELECT message FROM Errors WHERE code = 'OUT_OF_RANGE'), 
                    v_type.name, COALESCE(v_item.parametr_value::text, 'NULL'), v_type.min_val, v_type.max_val);
            END IF;
        END LOOP;

        -- Проверка отсутствия обязательных параметров
        IF v_required IS NOT NULL THEN
            FOREACH v_id IN ARRAY v_required LOOP
                IF NOT (v_id = ANY(v_seen)) THEN
                    v_errors := v_errors || format('%s: %s; ', 
                        (SELECT message FROM Errors WHERE code = 'MISSING_PARAM'), 
                        (SELECT name FROM types_parameters WHERE id = v_id));
                END IF;
            END LOOP;
        END IF;

        IF length(v_errors) = 0 THEN RETURN NULL; END IF;
        RETURN trim(trailing '; ' FROM v_errors);
    END;
    $func$;

    -- 4. Отчет "Список параметров с ошибками" 
    CREATE OR REPLACE FUNCTION get_parameter_errors()
    RETURNS TABLE (
        "№" int,
        "Тип оборудования" text,
        "Высота метеопоста" numeric,
        "Температура" numeric,
        "Давление" numeric,
        "Направление ветра" numeric,
        "Скорость ветра" numeric,
        "Дальность сноса пуль" numeric,
        "Флаг: Есть ошибка" boolean,
        "Описание ошибки" text
    )
    LANGUAGE sql STABLE AS $func$
    WITH batches AS (
        SELECT 
            l.id,
            e.name AS equipment_name,
            max(p.parametr_value) FILTER (WHERE p.parametr_id = 1) AS station_high,
            max(p.parametr_value) FILTER (WHERE p.parametr_id = 2) AS temperature,
            max(p.parametr_value) FILTER (WHERE p.parametr_id = 3) AS pressure,
            max(p.parametr_value) FILTER (WHERE p.parametr_id = 4) AS wind_direction,
            max(p.parametr_value) FILTER (WHERE p.parametr_id = 5) AS wind_speed,
            max(p.parametr_value) FILTER (WHERE p.parametr_id = 6) AS bullet_drift,
            validate_parameters(
                ROW(l.equipment_id, 
                    COALESCE(array_agg(ROW(p.parametr_id, p.parametr_value)::parameter_value ORDER BY p.id), ARRAY[]::parameter_value[])
                )::parameter_list
            ) AS error_text
        FROM logs l
        JOIN equipments e ON e.id = l.equipment_id
        LEFT JOIN parameters p ON p.log_id = l.id
        GROUP BY l.id, l.equipment_id, e.name
    )
    SELECT 
        b.id, b.equipment_name, b.station_high, b.temperature, b.pressure, 
        b.wind_direction, b.wind_speed, b.bullet_drift,
        (b.error_text IS NOT NULL) AS "Флаг: Есть ошибка",
        b.error_text AS "Описание ошибки"
    FROM batches b
    ORDER BY b.id;
    $func$;

    -- 5. Отчет "Лучший стрелок" 
    CREATE OR REPLACE FUNCTION get_best_shooters()
    RETURNS TABLE (
        "Пользователь" text,
        "Количество ошибок" int,
        "Ошибочных пачек" int,
        "Всего пачек" int,
        "Место" int,
        "Лучший стрелок" bool
    )
    LANGUAGE sql STABLE AS $func$
    WITH batches AS (
        SELECT 
            l.id, l.user_id,
            validate_parameters(
                ROW(l.equipment_id, 
                    COALESCE(array_agg(ROW(p.parametr_id, p.parametr_value)::parameter_value ORDER BY p.id), ARRAY[]::parameter_value[])
                )::parameter_list
            ) AS error_text
        FROM logs l
        LEFT JOIN parameters p ON p.log_id = l.id
        GROUP BY l.id, l.user_id, l.equipment_id
    ),
    stats AS (
        SELECT 
            u.id AS user_id, u.name AS user_name,
            count(b.id) AS logs_count,
            count(*) FILTER (WHERE b.error_text IS NOT NULL) AS bad_batches,
            COALESCE(sum(length(b.error_text) - length(replace(b.error_text, ';', ''))), 0)::int AS error_count
        FROM users u
        LEFT JOIN batches b ON b.user_id = u.id
        GROUP BY u.id, u.name
    ),
    ranked AS (
        SELECT 
            s.*,
            rank() OVER (PARTITION BY (s.logs_count > 0) ORDER BY s.error_count ASC, s.bad_batches ASC) AS place,
            min(s.error_count) OVER (PARTITION BY (s.logs_count > 0)) AS best_error_count
        FROM stats s
    )
    SELECT 
        r.user_name, r.error_count, r.bad_batches, r.logs_count, r.place,
        (r.logs_count > 0 AND r.error_count = r.best_error_count) AS "Лучший стрелок"
    FROM ranked r
    ORDER BY r.place, r.logs_count DESC;
    $func$;

END $$;