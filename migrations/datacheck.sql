--Каждый пользователь имеет одинаковое количество измерений
SELECT 
    u.id AS user_id, 
    u.name AS user_name, 
    COUNT(l.id) AS log_count
FROM users u
LEFT JOIN logs l ON u.id = l.user_id
GROUP BY u.id, u.name
ORDER BY log_count DESC;

--У нас нет пустых пачек измерения
SELECT 
    l.id AS empty_log_id, 
    l.date, 
    u.name AS user_name
FROM logs l
LEFT JOIN parameters p ON l.id = p.log_id
JOIN users u ON l.user_id = u.id
WHERE p.id IS NULL;

--Каждая пачка измерений содержит полное количеситво параметров (5 шт)
SELECT 
    log_id, 
    COUNT(id) AS parameters_count
FROM parameters
GROUP BY log_id
HAVING COUNT(id) != 5;

--Все значения который сформировал корректны и в рамках нужного нам диаппазонов
SELECT 
    p.id, p.log_id, 
    tp.name AS parameter_name, 
    p.parametr_value,
    CASE 
        WHEN p.parametr_id = 2 AND (p.parametr_value < -58 OR p.parametr_value > 58) THEN 'Температура вне [-58; 58]'
        WHEN p.parametr_id = 3 AND (p.parametr_value < 500 OR p.parametr_value > 900) THEN 'Давление вне [500; 900]'
        WHEN p.parametr_id = 4 AND (p.parametr_value < 0 OR p.parametr_value > 59) THEN 'Направление ветра вне [0; 59]'
        WHEN p.parametr_id = 5 AND (p.parametr_value < 0 OR p.parametr_value > 15) THEN 'Скорость ветра вне [0; 15]'
        WHEN p.parametr_id = 6 AND (p.parametr_value < 0 OR p.parametr_value > 150) THEN 'Снос пуль вне [0; 150]'
    END AS error_description
FROM parameters p
JOIN types_parameters tp ON p.parametr_id = tp.id
WHERE 
    (p.parametr_id = 2 AND (p.parametr_value < -58 OR p.parametr_value > 58)) OR
    (p.parametr_id = 3 AND (p.parametr_value < 500 OR p.parametr_value > 900)) OR
    (p.parametr_id = 4 AND (p.parametr_value < 0 OR p.parametr_value > 59)) OR
    (p.parametr_id = 5 AND (p.parametr_value < 0 OR p.parametr_value > 15)) OR
    (p.parametr_id = 6 AND (p.parametr_value < 0 OR p.parametr_value > 150));

--Все единицы измерения верны и корректны по отношению к указанным параметрам
SELECT 
    p.id, p.log_id,
    tp.name AS parameter_name,
    um_expected.name AS correct_unit,
    um_actual.name AS actual_unit
FROM parameters p
JOIN types_parameters tp ON p.parametr_id = tp.id
JOIN units_measurement um_expected ON tp.unit_id = um_expected.id
JOIN units_measurement um_actual ON p.units_id = um_actual.id
WHERE tp.unit_id != p.units_id;