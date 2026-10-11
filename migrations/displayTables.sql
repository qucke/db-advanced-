SELECT 
    ROW_NUMBER() OVER (ORDER BY table_name) AS "№",
    table_name AS "Наименование",
    CASE 
        WHEN table_type = 'BASE TABLE' THEN 'Таблица'
        ELSE table_type 
    END AS "Тип"
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;