DO $$
BEGIN
    CREATE SEQUENCE IF NOT EXISTS public.calc_correction_height_seq;
    
    CREATE TABLE IF NOT EXISTS public.calc_correction_heights (
        id integer NOT NULL DEFAULT nextval('public.calc_correction_height_seq'),
        height integer NOT NULL
    );
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction_heights' 
          AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE public.calc_correction_heights 
            ADD CONSTRAINT pk_calc_correction_heights PRIMARY KEY (id);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction_heights' 
          AND constraint_name = 'uq_calc_correction_heights_height'
    ) THEN
        ALTER TABLE public.calc_correction_heights 
            ADD CONSTRAINT uq_calc_correction_heights_height UNIQUE (height);
    END IF;
    
    ALTER SEQUENCE public.calc_correction_height_seq 
        OWNED BY public.calc_correction_heights.id;
    
    COMMENT ON TABLE public.calc_correction_heights IS 'Справочник высот для расчетов';
    COMMENT ON COLUMN public.calc_correction_heights.id IS 'Уникальный идентификатор';
    COMMENT ON COLUMN public.calc_correction_heights.height IS 'Высота в метрах';
        
    CREATE SEQUENCE IF NOT EXISTS public.calc_correction_types_seq;
    
    CREATE TABLE IF NOT EXISTS public.calc_correction_types (
        id integer NOT NULL DEFAULT nextval('public.calc_correction_types_seq'),
        parent_id integer,
        measurment_equipment_id integer,
        description text NOT NULL
    );
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction_types' 
          AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE public.calc_correction_types 
            ADD CONSTRAINT pk_calc_correction_types PRIMARY KEY (id);
    END IF;
    
    ALTER SEQUENCE public.calc_correction_types_seq 
        OWNED BY public.calc_correction_types.id;
    
    COMMENT ON TABLE public.calc_correction_types IS 'Справочник типов таблиц исключений';
    COMMENT ON COLUMN public.calc_correction_types.id IS 'Уникальный идентификатор';
    COMMENT ON COLUMN public.calc_correction_types.parent_id IS 'Родительский тип (для иерархии)';
    COMMENT ON COLUMN public.calc_correction_types.measurment_equipment_id IS 'Тип измерительного оборудования';
    COMMENT ON COLUMN public.calc_correction_types.description IS 'Описание типа таблицы';
    
    CREATE SEQUENCE IF NOT EXISTS public.calc_correction_seq;
    
    CREATE TABLE IF NOT EXISTS public.calc_correction (
        id integer NOT NULL DEFAULT nextval('public.calc_correction_seq'),
        height_id integer NOT NULL,
        type_id integer NOT NULL,
        row_values integer[] NOT NULL
    );
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction' 
          AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE public.calc_correction 
            ADD CONSTRAINT pk_calc_correction PRIMARY KEY (id);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction' 
          AND constraint_name = 'uq_calc_correction_height_type'
    ) THEN
        ALTER TABLE public.calc_correction 
            ADD CONSTRAINT uq_calc_correction_height_type UNIQUE (height_id, type_id);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction' 
          AND constraint_name = 'fk_calc_correction_height'
    ) THEN
        ALTER TABLE public.calc_correction 
            ADD CONSTRAINT fk_calc_correction_height 
            FOREIGN KEY (height_id) REFERENCES public.calc_correction_heights(id);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction' 
          AND constraint_name = 'fk_calc_correction_type'
    ) THEN
        ALTER TABLE public.calc_correction 
            ADD CONSTRAINT fk_calc_correction_type 
            FOREIGN KEY (type_id) REFERENCES public.calc_correction_types(id);
    END IF;
    
    ALTER SEQUENCE public.calc_correction_seq 
        OWNED BY public.calc_correction.id;
    
    COMMENT ON TABLE public.calc_correction IS 'Таблица значений коррекций';
    COMMENT ON COLUMN public.calc_correction.id IS 'Уникальный идентификатор';
    COMMENT ON COLUMN public.calc_correction.height_id IS 'Ссылка на высоту';
    COMMENT ON COLUMN public.calc_correction.type_id IS 'Ссылка на тип таблицы';
    COMMENT ON COLUMN public.calc_correction.row_values IS 'Массив значений коррекций';
    
    -- Заполнение таблиц данными
    
    INSERT INTO public.calc_correction_heights (height)
    VALUES (200), (400), (800), (1200), (1600), (2000), (2400), (3000), (4000)
    ON CONFLICT (height) DO NOTHING;
    
    INSERT INTO public.calc_correction_types (id, description, parent_id, measurment_equipment_id)
    VALUES 
        (1, 'Таблица 2', NULL, NULL),
        (2, 'Таблица 3, скорость среднего ветра', NULL, NULL),
        (3, 'Таблица 3, направление среднего ветра', NULL, NULL),
        (4, 'Таблица 3, Скорость среднего ветра (ВР)', 2, 2),
        (5, 'Таблица 3, Направление среднего ветра (ВР)', 3, 2),
        (6, 'Таблица 3, Скорость среднего ветра (ДМК)', 2, 1),
        (7, 'Таблица 3, Направление среднего ветра (ДМК)', 3, 1),
        (8, 'Таблица 2, Отрицательные температуры', 1, NULL),
        (9, 'Таблица 2, Положительные температуры', 1, NULL)
    ON CONFLICT (id) DO NOTHING;
    
    PERFORM setval('public.calc_correction_types_seq', (SELECT MAX(id) FROM public.calc_correction_types));
    
    INSERT INTO public.calc_correction (height_id, type_id, row_values)
    VALUES 
        (1, 8, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), -- 200
        (2, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -38, -48]), -- 400
        (3, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), -- 800
        (4, 8, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), -- 1200
        (5, 8, array[-1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]), -- 1600
        (6, 8, array[-1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40]), -- 2000
        (7, 8, array[-1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38]), -- 2400
        (8, 8, array[-1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37]), -- 3000
        (9, 8, array[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34])  -- 4000
    ON CONFLICT (height_id, type_id) DO NOTHING;

    INSERT INTO public.calc_correction (height_id, type_id, row_values)
    VALUES 
        (1, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 200
        (2, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 400
        (3, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 800
        (4, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1200
        (5, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1600
        (6, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2000
        (7, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2400
        (8, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 3000
        (9, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30])  -- 4000
    ON CONFLICT (height_id, type_id) DO NOTHING;
    
    INSERT INTO public.calc_correction (height_id, type_id, row_values)
    VALUES 
        (1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), -- 200
        (2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), -- 400
        (3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16]), -- 800
        (4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15, 15, 16]), -- 1200
        (5, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 17]), -- 1600
        (6, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18]), -- 2000
        (7, 4, array[4, 6, 8, 9, 9, 10, 12, 14, 15, 16, 18, 19]), -- 2400
        (8, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 15, 17, 18, 19]), -- 3000
        (9, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 16, 18, 19, 20])  -- 4000
    ON CONFLICT (height_id, type_id) DO NOTHING;
    
    INSERT INTO public.calc_correction (height_id, type_id, row_values)
    VALUES 
        (1, 5, array[0]), -- 200
        (2, 5, array[1]), -- 400
        (3, 5, array[2]), -- 800
        (4, 5, array[2]), -- 1200
        (5, 5, array[3]), -- 1600
        (6, 5, array[3]), -- 2000
        (7, 5, array[3]), -- 2400
        (8, 5, array[4]), -- 3000
        (9, 5, array[4])  -- 4000
    ON CONFLICT (height_id, type_id) DO NOTHING;
    
    INSERT INTO public.calc_correction (height_id, type_id, row_values)
    VALUES 
        (1, 6, array[4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22]), -- 200
        (2, 6, array[5, 7, 10, 11, 12, 14, 17, 18, 20, 22, 23, 25, 27]), -- 400
        (3, 6, array[5, 8, 10, 11, 13, 15, 18, 19, 21, 23, 25, 27, 28]), -- 800
        (4, 6, array[5, 8, 11, 12, 13, 16, 19, 20, 22, 24, 26, 28, 30]), -- 1200
        (5, 6, array[6, 8, 11, 13, 14, 17, 20, 21, 23, 25, 27, 29, 32]), -- 1600
        (6, 6, array[6, 9, 11, 13, 14, 17, 20, 21, 24, 26, 28, 30, 32]), -- 2000
        (7, 6, array[6, 9, 12, 14, 15, 18, 21, 22, 25, 27, 29, 32, 34]), -- 2400
        (8, 6, array[6, 9, 12, 14, 15, 18, 21, 23, 25, 28, 30, 32, 36]), -- 3000
        (9, 6, array[6, 10, 12, 14, 16, 19, 22, 24, 26, 29, 32, 34, 36])  -- 4000
    ON CONFLICT (height_id, type_id) DO NOTHING;
    
    INSERT INTO public.calc_correction (height_id, type_id, row_values)
    VALUES 
        (1, 7, array[1]), -- 200
        (2, 7, array[2]), -- 400
        (3, 7, array[3]), -- 800
        (4, 7, array[3]), -- 1200
        (5, 7, array[4]), -- 1600
        (6, 7, array[4]), -- 2000
        (7, 7, array[4]), -- 2400
        (8, 7, array[5]), -- 3000
        (9, 7, array[5])  -- 4000
    ON CONFLICT (height_id, type_id) DO NOTHING;
    
END $$;