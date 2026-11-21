CREATE SEQUENCE IF NOT EXISTS seq_dim_time;

CREATE TABLE IF NOT EXISTS dim_time (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_time'),
    external_id bigint NOT NULL UNIQUE,
    month_start_date date NOT NULL,
    month_end_date date NOT NULL,
    month_name text NOT NULL,
    year integer NOT NULL,
    quarter_number integer NOT NULL,
    quarter_name text NOT NULL,
    date_add timestamp DEFAULT now()
);

CREATE OR REPLACE FUNCTION fill_time_dimension(
    p_from date DEFAULT '2020-01-01',
    p_to date DEFAULT '2026-12-01'
) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_month date;
    v_count integer := 0;
    v_external_id integer;
    v_month_name text;
    v_quarter_no integer;
    v_quarter_name text;
BEGIN
    v_month := date_trunc('month', p_from)::date;

    WHILE v_month <= date_trunc('month', p_to)::date LOOP
        v_external_id := EXTRACT(YEAR FROM v_month)::integer * 100 + EXTRACT(MONTH FROM v_month)::integer;

        v_month_name := CASE EXTRACT(MONTH FROM v_month)::integer
            WHEN 1 THEN 'Январь'
            WHEN 2 THEN 'Февраль'
            WHEN 3 THEN 'Март'
            WHEN 4 THEN 'Апрель'
            WHEN 5 THEN 'Май'
            WHEN 6 THEN 'Июнь'
            WHEN 7 THEN 'Июль'
            WHEN 8 THEN 'Август'
            WHEN 9 THEN 'Сентябрь'
            WHEN 10 THEN 'Октябрь'
            WHEN 11 THEN 'Ноябрь'
            WHEN 12 THEN 'Декабрь'
        END;

        v_quarter_no := EXTRACT(QUARTER FROM v_month)::integer;

        v_quarter_name := CASE v_quarter_no
            WHEN 1 THEN 'I квартал'
            WHEN 2 THEN 'II квартал'
            WHEN 3 THEN 'III квартал'
            WHEN 4 THEN 'IV квартал'
        END;

        INSERT INTO dim_time (external_id, month_start_date, month_end_date, month_name, year, quarter_number, quarter_name)
        VALUES (v_external_id, v_month, (v_month + INTERVAL '1 month - 1 day')::date, v_month_name, EXTRACT(YEAR FROM v_month)::integer, v_quarter_no, v_quarter_name)
        ON CONFLICT (external_id) DO NOTHING;

        v_count := v_count + 1;
        v_month := (v_month + INTERVAL '1 month')::date;
    END LOOP;

    RETURN v_count;
END;
$$;

SELECT fill_time_dimension('2020-01-01', '2026-12-01') AS months_filled;

SELECT count(*) AS total_months, min(external_id) AS first_code, max(external_id) AS last_code
FROM dim_time;

SELECT external_id, month_start_date, month_end_date, month_name, year, quarter_number, quarter_name
FROM dim_time ORDER BY external_id LIMIT 12;