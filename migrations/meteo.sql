DO $main$
BEGIN
    -- 1. Таблица именованных констант
    CREATE TABLE IF NOT EXISTS Constants (
        code text PRIMARY KEY,
        value numeric NOT NULL
    );

    INSERT INTO Constants (code, value) VALUES
    ('PRESSURE', 750),          
    ('TEMPERATURE', 15.9),      
    ('PRESSURE_NEG', 500),      
    ('TEMPERATURE_NEG', 50),    
    ('HEIGHT_NEG', 5000)        
    ON CONFLICT (code) DO UPDATE SET value = EXCLUDED.value;

    CREATE OR REPLACE FUNCTION get_constant(p_code text)
    RETURNS numeric LANGUAGE sql AS $func$
        SELECT value FROM Constants WHERE code = p_code;
    $func$;

    -- 2. Функция ДДЧЧМ
    CREATE OR REPLACE FUNCTION calc_ddchhm(p_time timestamp DEFAULT current_timestamp)
    RETURNS text LANGUAGE sql AS $func$
        SELECT to_char(p_time, 'DDHH24') || floor(extract(minute FROM p_time) / 10)::int::text;
    $func$;

    -- 3. Функция ВВВВ
    CREATE OR REPLACE FUNCTION calc_vvvv(p_height int)
    RETURNS text LANGUAGE sql AS $func$
        SELECT lpad(
            (CASE WHEN p_height < 0 THEN get_constant('HEIGHT_NEG') + abs(p_height) ELSE p_height END)::int::text,
            4, '0'
        );
    $func$;

    -- 4. Функция БББТТ 
    CREATE OR REPLACE FUNCTION calc_bbbtt(p_pressure numeric, p_temperature numeric)
    RETURNS text LANGUAGE sql AS $func$
    WITH c AS (
        SELECT 
            get_constant('PRESSURE') AS p0,
            get_constant('TEMPERATURE') AS t0,
            get_constant('PRESSURE_NEG') AS pn,
            get_constant('TEMPERATURE_NEG') AS tn
    ),
    v AS (
        SELECT 
            p_pressure - c.p0 AS dp,
            round(
                p_temperature + COALESCE(calc_interpolation(p_temperature, get_temp_bounds_from_table(p_temperature)), 0) - c.t0
            ) AS dt,
            c.pn, c.tn
        FROM c
    )
    SELECT 
        lpad((CASE WHEN dp < 0 THEN pn + abs(dp) ELSE dp END)::int::text, 3, '0') ||
        lpad((CASE WHEN dt < 0 THEN tn + abs(dt) ELSE dt END)::int::text, 2, '0')
    FROM v;
    $func$;

END $main$;