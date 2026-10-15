SELECT 
    ROW_NUMBER() OVER (ORDER BY c.table_name, c.ordinal_position) AS "№",
    c.table_name AS "Таблица",
    c.column_name AS "Столбец",
    c.data_type AS "Тип данных",
    CASE 
        WHEN c.is_nullable = 'NO' THEN 'NOT NULL' 
        ELSE 'NULL' 
    END AS "Допускает NULL",
    CASE
        WHEN pk.constraint_name IS NOT NULL THEN 'PRIMARY KEY'
        WHEN fk.constraint_name IS NOT NULL THEN 'FOREIGN KEY'
        WHEN c.column_default IS NOT NULL THEN 'DEFAULT'
        ELSE '-'
    END AS "Ограничение / Свойство"
FROM information_schema.columns c
LEFT JOIN information_schema.key_column_usage pk 
    ON c.table_name = pk.table_name 
    AND c.column_name = pk.column_name 
    AND pk.constraint_name LIKE '%_pkey'
LEFT JOIN information_schema.key_column_usage fk 
    ON c.table_name = fk.table_name 
    AND c.column_name = fk.column_name 
    AND fk.constraint_name LIKE '%_fkey'
WHERE c.table_schema = 'public'
ORDER BY c.table_name, c.ordinal_position;


SELECT 
    ROW_NUMBER() OVER (ORDER BY sequencename) AS "№",
    sequencename AS "Наименование",
    'Счетчик (Sequence)' AS "Тип",
    data_type AS "Тип данных",
    last_value AS "Текущее значение",
    start_value AS "Начальное значение",
    increment_by AS "Шаг"
FROM pg_sequences
WHERE schemaname = 'public'
ORDER BY sequencename;