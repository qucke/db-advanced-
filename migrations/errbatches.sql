DO $$
BEGIN
    ALTER TABLE parameters DROP CONSTRAINT IF EXISTS chk_parameter_ranges;

    -- Вставляем тестовые данные с ошибками
    INSERT INTO logs (id, user_id, equipment_id, date) VALUES
    (5, 1, 1, TIMESTAMP '2026-10-20 08:00:00'),
    (6, 2, 2, TIMESTAMP '2026-10-20 09:00:00'),
    (7, 3, 1, TIMESTAMP '2026-10-20 10:00:00'),
    (8, 4, 2, TIMESTAMP '2026-10-20 11:00:00')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO parameters (log_id, parametr_id, units_id, parametr_value) VALUES
    (5, 1, 1, 100), (5, 2, 3, 120), (5, 3, 2, 765), (5, 4, 4, 15), (5, 5, 5, 5),
    (6, 1, 1, 150), (6, 2, 3, 15), (6, 3, 2, 700), (6, 4, 4, 10), (6, 5, 5, 5),
    (7, 1, 1, 1200), (7, 2, 3, -45), (7, 4, 4, 58), (7, 5, 5, 12),
    (8, 1, 1, 510), (8, 2, 3, 25), (8, 3, 2, 742), (8, 4, 4, 15), (8, 6, 1, 10)
    ON CONFLICT DO NOTHING;

    -- Добавляем ограничение с флагом NOT VALID 
    ALTER TABLE parameters 
        ADD CONSTRAINT chk_parameter_ranges CHECK (
            parametr_id = 1 OR  
            (parametr_id = 2 AND parametr_value BETWEEN -58 AND 58) OR   
            (parametr_id = 3 AND parametr_value BETWEEN 500 AND 900) OR  
            (parametr_id = 4 AND parametr_value BETWEEN 0 AND 59) OR     
            (parametr_id = 5 AND parametr_value BETWEEN 0 AND 15) OR     
            (parametr_id = 6 AND parametr_value BETWEEN 0 AND 150)       
        ) NOT VALID;
        
    RAISE NOTICE 'Ограничение добавлено с флагом NOT VALID - новые записи будут проверяться, существующие проигнорированы';
END $$;