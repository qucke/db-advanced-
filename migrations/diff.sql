DO $$
BEGIN
    CREATE SEQUENCE IF NOT EXISTS public.calc_correction_headers_seq;
    
    CREATE TABLE IF NOT EXISTS public.calc_correction_headers (
        id integer NOT NULL DEFAULT nextval('public.calc_correction_headers_seq'),
        header_values integer[] NOT NULL
    );
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction_headers' 
          AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE public.calc_correction_headers 
            ADD CONSTRAINT pk_calc_correction_headers PRIMARY KEY (id);
    END IF;
    
    ALTER SEQUENCE public.calc_correction_headers_seq 
        OWNED BY public.calc_correction_headers.id;
    
    COMMENT ON TABLE public.calc_correction_headers IS 'Справочник заголовков таблиц корректировок';
    COMMENT ON COLUMN public.calc_correction_headers.id IS 'Уникальный код';
    COMMENT ON COLUMN public.calc_correction_headers.header_values IS 'Массив значений заголовка';
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'calc_correction_types' AND column_name = 'header_id'
    ) THEN
        ALTER TABLE public.calc_correction_types ADD COLUMN header_id integer;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'calc_correction_types' AND column_name = 'header_values'
    ) THEN
        INSERT INTO public.calc_correction_headers (header_values)
        SELECT DISTINCT header_values 
        FROM public.calc_correction_types 
        WHERE header_values IS NOT NULL
        ON CONFLICT DO NOTHING;
        
        UPDATE public.calc_correction_types AS t
        SET header_id = h.id
        FROM public.calc_correction_headers AS h
        WHERE h.header_values = t.header_values;
        
        ALTER TABLE public.calc_correction_types DROP COLUMN header_values;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'calc_correction_types' 
          AND constraint_name = 'fk_calc_correction_types_header'
    ) THEN
        ALTER TABLE public.calc_correction_types 
            ADD CONSTRAINT fk_calc_correction_types_header 
            FOREIGN KEY (header_id) REFERENCES public.calc_correction_headers(id);
    END IF;
    
    COMMENT ON COLUMN public.calc_correction_types.header_id IS 'Ссылка на справочник заголовков';
    
    INSERT INTO public.calc_correction_headers (id, header_values)
    VALUES 
        (1, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30])
    ON CONFLICT (id) DO UPDATE SET header_values = EXCLUDED.header_values;
    
    INSERT INTO public.calc_correction_headers (id, header_values)
    VALUES 
        (2, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50])
    ON CONFLICT (id) DO UPDATE SET header_values = EXCLUDED.header_values;
    
    INSERT INTO public.calc_correction_headers (id, header_values)
    VALUES 
        (3, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150])
    ON CONFLICT (id) DO UPDATE SET header_values = EXCLUDED.header_values;
    
    INSERT INTO public.calc_correction_headers (id, header_values)
    VALUES 
        (4, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150])
    ON CONFLICT (id) DO UPDATE SET header_values = EXCLUDED.header_values;
    
    INSERT INTO public.calc_correction_headers (id, header_values)
    VALUES 
        (5, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
    ON CONFLICT (id) DO UPDATE SET header_values = EXCLUDED.header_values;
    
    INSERT INTO public.calc_correction_headers (id, header_values)
    VALUES 
        (6, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
    ON CONFLICT (id) DO UPDATE SET header_values = EXCLUDED.header_values;
    
    PERFORM setval('public.calc_correction_headers_seq', 
        (SELECT MAX(id) FROM public.calc_correction_headers));
    
    UPDATE public.calc_correction_types SET header_id = 2 WHERE id = 8;
    UPDATE public.calc_correction_types SET header_id = 1 WHERE id = 9;
    UPDATE public.calc_correction_types SET header_id = 3 WHERE id = 4;
    UPDATE public.calc_correction_types SET header_id = 4 WHERE id = 5;
    UPDATE public.calc_correction_types SET header_id = 5 WHERE id = 6;
    UPDATE public.calc_correction_types SET header_id = 6 WHERE id = 7;
    
    INSERT INTO public.measurment_settings (key, value, description)
    VALUES 
        -- Пороги нулевого ветра
        ('wind_zero_dmk', '3.0', 'Порог нулевого ветра для ДМК'),
        ('wind_zero_vr', '40.0', 'Порог нулевого ветра для ВР'),    
        -- Идентификаторы оборудования
        ('equipment_dmk_id', '1', 'ID оборудования ДМК'),
        ('equipment_vr_id', '2', 'ID оборудования ВР'),
        -- Идентификаторы типов таблиц коррекций
        ('type_temp_pos_id', '9', 'ID типа: Таблица 2, Положительные температуры'),
        ('type_temp_neg_id', '8', 'ID типа: Таблица 2, Отрицательные температуры'),
        ('type_speed_vr_id', '4', 'ID типа: Таблица 3, Скорость (ВР)'),
        ('type_dir_vr_id', '5', 'ID типа: Таблица 3, Направление (ВР)'),
        ('type_speed_dmk_id', '6', 'ID типа: Таблица 3, Скорость (ДМК)'),
        ('type_dir_dmk_id', '7', 'ID типа: Таблица 3, Направление (ДМК)')
    ON CONFLICT (key) DO NOTHING;
END $$;