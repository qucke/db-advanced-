DO $$
BEGIN
    DROP TABLE IF EXISTS public.calc_correction CASCADE;
    DROP TABLE IF EXISTS public.calc_correction_types CASCADE;
    DROP TABLE IF EXISTS public.calc_correction_headers CASCADE;
    DROP TABLE IF EXISTS public.calc_correction_heights CASCADE;
    DROP SEQUENCE IF EXISTS public.calc_correction_seq CASCADE;
    DROP SEQUENCE IF EXISTS public.calc_correction_headers_seq CASCADE;
    DROP SEQUENCE IF EXISTS public.calc_correction_types_seq CASCADE;
    DROP SEQUENCE IF EXISTS public.calc_correction_height_seq CASCADE;

    BEGIN
        CREATE SEQUENCE public.calc_correction_height_seq;
        CREATE TABLE public.calc_correction_heights (
            id integer PRIMARY KEY NOT NULL DEFAULT nextval('public.calc_correction_height_seq'),
            height integer NOT NULL
        );

        CREATE SEQUENCE public.calc_correction_types_seq;
        CREATE TABLE public.calc_correction_types (
            id integer NOT NULL PRIMARY KEY DEFAULT nextval('public.calc_correction_types_seq'),
            parent_id integer,
            measurment_equipment_id integer,
            description text NOT NULL,
            header_values integer[]
        );

        CREATE SEQUENCE public.calc_correction_seq;
        CREATE TABLE public.calc_correction (
            id integer NOT NULL PRIMARY KEY DEFAULT nextval('public.calc_correction_seq'),
            height_id integer NOT NULL,
            type_id integer NOT NULL,
            row_values integer[]
        );
    END;


    BEGIN
        INSERT INTO public.calc_correction_heights(height)
        VALUES(200),(400),(800),(1200),(1600),(2000),(2400),(3000),(4000);

        INSERT INTO public.calc_correction_types(id, description, parent_id, measurment_equipment_id, header_values)
        VALUES
        (1, 'Таблица 2', NULL, NULL, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),
        (2, 'Таблица 3, скорость среднего ветра', NULL, NULL, NULL),
        (3, 'Таблица 3, направление среднего ветра', NULL, NULL, NULL),
        (4, 'Таблица 3, Скорость среднего ветра (ВР)', 2, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),
        (5, 'Таблица 3, Направление среднего ветра (ВР)', 3, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),
        (6, 'Таблица 3, Скорость среднего ветра (ДМК)', 2, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]),
        (7, 'Таблица 3, Направление среднего ветра (ДМК)', 3, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]),
        (8, 'Таблица 2, Отрицательные температуры', 1, NULL, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),
        (9, 'Таблица 2, Положительные температуры', 1, NULL, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]);

        PERFORM setval('public.calc_correction_types_seq', (SELECT MAX(id) FROM public.calc_correction_types));
		
        INSERT INTO public.calc_correction(height_id, type_id, row_values)
        VALUES
        -- Таблица 2, отрицательные значения
        (1, 8, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), -- 200
        (2, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -38, -48]), -- 400
        (3, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), -- 800
        (4, 8, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), -- 1200
        (5, 8, array[-1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]), -- 1600
        (6, 8, array[-1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40]), -- 2000
        (7, 8, array[-1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38]), -- 2400
        (8, 8, array[-1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37]), -- 3000
        (9, 8, array[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34]), -- 4000
        -- Таблица 2, положительные значения
        (1, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 200
        (2, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 400
        (3, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 800
        (4, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1200
        (5, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1600
        (6, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2000
        (7, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2400
        (8, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 3000
        (9, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 4000
        -- Таблица 3, Скорость среднего ветра (ВР)
        (1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), -- 200
        (2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), -- 400
        (3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16]), -- 800
        (4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15, 15, 16]), -- 1200
        (5, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 17]), -- 1600
        (6, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18]), -- 2000
        (7, 4, array[4, 6, 8, 9, 9, 10, 12, 14, 15, 16, 18, 19]), -- 2400
        (8, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 15, 17, 18, 19]), -- 3000
        (9, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 16, 18, 19, 20]), -- 4000
        -- Таблица 3, Направление среднего ветра (ВР)
        (1, 5, array[0]), -- 200
        (2, 5, array[1]), -- 400
        (3, 5, array[2]), -- 800
        (4, 5, array[2]), -- 1200
        (5, 5, array[3]), -- 1600
        (6, 5, array[3]), -- 2000
        (7, 5, array[3]), -- 2400
        (8, 5, array[4]), -- 3000
        (9, 5, array[4]), -- 4000
        -- Таблица 3, Скорость среднего ветра (ДМК)
        (1, 6, array[4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22]), -- 200
        (2, 6, array[5, 7, 10, 11, 12, 14, 17, 18, 20, 22, 23, 25, 27]), -- 400
        (3, 6, array[5, 8, 10, 11, 13, 15, 18, 19, 21, 23, 25, 27, 28]), -- 800
        (4, 6, array[5, 8, 11, 12, 13, 16, 19, 20, 22, 24, 26, 28, 30]), -- 1200
        (5, 6, array[6, 8, 11, 13, 14, 17, 20, 21, 23, 25, 27, 29, 32]), -- 1600
        (6, 6, array[6, 9, 11, 13, 14, 17, 20, 21, 24, 26, 28, 30, 32]), -- 2000
        (7, 6, array[6, 9, 12, 14, 15, 18, 21, 22, 25, 27, 29, 32, 34]), -- 2400
        (8, 6, array[6, 9, 12, 14, 15, 18, 21, 23, 25, 28, 30, 32, 36]), -- 3000
        (9, 6, array[6, 10, 12, 14, 16, 19, 22, 24, 26, 29, 32, 34, 36]), -- 4000
        -- Таблица 3, Направление среднего ветра (ДМК)
        (1, 7, array[1]), -- 200
        (2, 7, array[2]), -- 400
        (3, 7, array[3]), -- 800
        (4, 7, array[3]), -- 1200
        (5, 7, array[4]), -- 1600
        (6, 7, array[4]), -- 2000
        (7, 7, array[4]), -- 2400
        (8, 7, array[5]), -- 3000
        (9, 7, array[5]); -- 4000

    END;

    BEGIN
        CREATE SEQUENCE public.calc_correction_headers_seq;
        CREATE TABLE public.calc_correction_headers (
            id integer PRIMARY KEY NOT NULL DEFAULT nextval('public.calc_correction_headers_seq'),
            header_values integer[] NOT NULL
        );
        COMMENT ON TABLE public.calc_correction_headers IS 'Справочник заголовков таблиц корректировок';
        COMMENT ON COLUMN public.calc_correction_headers.id IS 'Уникальный код';
        COMMENT ON COLUMN public.calc_correction_headers.header_values IS 'Массив значений заголовка';

		INSERT INTO public.calc_correction_headers(header_values)
        SELECT DISTINCT header_values
        FROM public.calc_correction_types
        WHERE header_values IS NOT NULL;

        ALTER TABLE public.calc_correction_types ADD COLUMN header_id integer;
        UPDATE public.calc_correction_types AS t
        SET header_id = h.id
        FROM public.calc_correction_headers AS h
        WHERE h.header_values = t.header_values;

        ALTER TABLE public.calc_correction_types
            ADD CONSTRAINT fk_calc_correction_types_header
            FOREIGN KEY (header_id) REFERENCES public.calc_correction_headers(id);

        ALTER TABLE public.calc_correction_types DROP COLUMN header_values;

        COMMENT ON COLUMN public.calc_correction_types.header_id IS 'Ссылка на справочник заголовков';
    END;
END $$;
