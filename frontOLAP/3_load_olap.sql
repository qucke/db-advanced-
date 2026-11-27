CREATE OR REPLACE PROCEDURE load_dimensions()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO dim_ranges (external_id, name, factor)
    SELECT external_id, name, factor FROM stg.ranges
    ON CONFLICT (external_id) DO NOTHING;

    INSERT INTO dim_categories (external_id, name, parent_id)
    SELECT external_id, name, parent_id FROM stg.categories
    ON CONFLICT (external_id) DO NOTHING;

    INSERT INTO dim_vendors (external_id, name, parent_id, parent_name)
    SELECT external_id, name, parent_id, parent_name FROM stg.vendors
    ON CONFLICT (external_id) DO NOTHING;

    INSERT INTO dim_personnel (external_id, name, last_name, first_name, middle_name, access_level, has_pos_access, is_deleted)
    SELECT external_id, name, last_name, first_name, middle_name, access_level, has_pos_access, is_deleted
    FROM stg.personnel
    ON CONFLICT (external_id) DO NOTHING;

    INSERT INTO dim_products (external_id, external_code, name, category_id, range_id, cost, is_active)
    SELECT s.external_id, s.external_code, s.name, c.id, r.id, s.cost, s.is_active
    FROM stg.products AS s
    LEFT JOIN dim_categories AS c ON c.external_id = s.category_external_id
    LEFT JOIN dim_ranges AS r ON r.external_id = s.range_external_id
    ON CONFLICT (external_id) DO NOTHING;

    INSERT INTO dim_storages (external_id, name, company_external_id, company_name, responsible_person_id)
    SELECT s.external_id, s.name, s.company_external_id, s.company_name, p.id
    FROM stg.storages AS s
    LEFT JOIN dim_personnel AS p ON p.external_id = s.responsible_person_external_id
    ON CONFLICT (external_id) DO NOTHING;

    INSERT INTO dim_payment_types (external_id, name)
    SELECT external_id, name FROM stg.payment_types
    ON CONFLICT (external_id) DO NOTHING;

    INSERT INTO dim_operation_types (external_id, name, factor)
    SELECT external_id, name, factor FROM stg.operation_types
    ON CONFLICT (external_id) DO NOTHING;

    INSERT INTO dim_event_types (name)
    SELECT name FROM stg.event_types
    WHERE name IS NOT NULL
    ON CONFLICT (name) DO NOTHING;

    INSERT INTO dim_event_types (name)
    SELECT DISTINCT event_type_name FROM stg.personnel_sessions
    WHERE event_type_name IS NOT NULL
    ON CONFLICT (name) DO NOTHING;
END;
$$;

CREATE OR REPLACE PROCEDURE load_facts(p_full_refresh boolean DEFAULT false)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_full_refresh THEN
        TRUNCATE TABLE fact_purchases, fact_sales, fact_payments, fact_personnel, fact_stock RESTART IDENTITY;
    ELSE
        DELETE FROM fact_purchases WHERE time_id IN (
            SELECT t.id FROM dim_time t JOIN (
                SELECT DISTINCT time_code FROM stg.purchases
                ) s ON s.time_code = t.external_id);
        DELETE FROM fact_sales WHERE time_id IN (
            SELECT t.id FROM dim_time t JOIN (
                SELECT DISTINCT time_code FROM stg.sales
                ) s ON s.time_code = t.external_id);
        DELETE FROM fact_payments WHERE time_id IN (
            SELECT t.id FROM dim_time t JOIN (
                SELECT DISTINCT time_code FROM stg.payments
                ) s ON s.time_code = t.external_id);
        DELETE FROM fact_personnel WHERE time_id IN (
            SELECT t.id FROM dim_time t JOIN (
                SELECT time_code FROM stg.personnel_sessions UNION SELECT time_code FROM stg.personnel_bonus
                ) s ON s.time_code = t.external_id);
        DELETE FROM fact_stock WHERE time_id IN (
            SELECT t.id FROM dim_time t JOIN (
                SELECT DISTINCT time_code FROM stg.stock
                ) s ON s.time_code = t.external_id);
    END IF;

    INSERT INTO fact_purchases (time_id, product_id, vendor_id, category_id, storage_id, range_id, lines_count, quantity, amount, avg_price)
    SELECT t.id, p.id, v.id, c.id, st.id, r.id, s.lines_count, s.quantity, s.amount, s.avg_price
    FROM stg.purchases AS s
    JOIN dim_time AS t ON t.external_id = s.time_code
    LEFT JOIN dim_products AS p ON p.external_id = s.product_external_id
    LEFT JOIN dim_vendors AS v ON v.external_id = s.vendor_external_id
    LEFT JOIN dim_categories AS c ON c.external_id = s.category_external_id
    LEFT JOIN dim_storages AS st ON st.external_id = s.storage_external_id
    LEFT JOIN dim_ranges AS r ON r.external_id = s.range_external_id
    ON CONFLICT (time_id, product_id, vendor_id, storage_id, range_id) DO NOTHING;

    INSERT INTO fact_sales (time_id, product_id, category_id, receipts_count, lines_count, quantity, revenue, refund_amount, net_revenue)
    SELECT t.id, p.id, c.id, s.receipts_count, s.lines_count, s.quantity, s.revenue, s.refund_amount, s.net_revenue
    FROM stg.sales AS s
    JOIN dim_time AS t ON t.external_id = s.time_code
    LEFT JOIN dim_products AS p ON p.external_id = s.product_external_id
    LEFT JOIN dim_categories AS c ON c.external_id = s.category_external_id
    ON CONFLICT (time_id, product_id) DO NOTHING;

    INSERT INTO fact_payments (time_id, payment_type_id, operations_count, amount)
    SELECT t.id, pt.id, s.operations_count, s.amount
    FROM stg.payments AS s
    JOIN dim_time AS t ON t.external_id = s.time_code
    LEFT JOIN dim_payment_types AS pt ON pt.external_id = s.payment_type_external_id
    ON CONFLICT (time_id, payment_type_id) DO NOTHING;

    INSERT INTO fact_personnel (time_id, person_id, event_type_id, sessions_count, errors_count, bonus_records_count, bonus_value)
    SELECT t.id, p.id, e.id, s.sessions_count, s.errors_count, 0, 0
    FROM stg.personnel_sessions AS s
    JOIN dim_time AS t ON t.external_id = s.time_code
    LEFT JOIN dim_personnel AS p ON p.external_id = s.person_external_id
    JOIN dim_event_types AS e ON e.name = s.event_type_name
    ON CONFLICT (time_id, person_id, event_type_id) DO NOTHING;

    INSERT INTO fact_personnel (time_id, person_id, event_type_id, sessions_count, errors_count, bonus_records_count, bonus_value)
    SELECT t.id, p.id, e.id, 0, 0, s.bonus_records_count, s.bonus_value
    FROM stg.personnel_bonus AS s
    JOIN dim_time AS t ON t.external_id = s.time_code
    LEFT JOIN dim_personnel AS p ON p.external_id = s.person_external_id
    JOIN dim_event_types AS e ON e.name = 'Бонусные начисления'
    ON CONFLICT (time_id, person_id, event_type_id) DO NOTHING;

    INSERT INTO fact_stock (time_id, product_id, storage_id, operation_type_id, range_id, lines_count, quantity, amount, turnover_amount)
    SELECT t.id, p.id, st.id, o.id, r.id, s.lines_count, s.quantity, s.amount, s.turnover_amount
    FROM stg.stock AS s
    JOIN dim_time AS t ON t.external_id = s.time_code
    LEFT JOIN dim_products AS p ON p.external_id = s.product_external_id
    LEFT JOIN dim_storages AS st ON st.external_id = s.storage_external_id
    LEFT JOIN dim_operation_types AS o ON o.external_id = s.operation_type_external_id
    LEFT JOIN dim_ranges AS r ON r.external_id = s.range_external_id
    ON CONFLICT (time_id, product_id, storage_id, operation_type_id, range_id) DO NOTHING;
END;
$$;

CREATE OR REPLACE PROCEDURE load_all(p_full_refresh boolean DEFAULT false)
LANGUAGE plpgsql
AS $$
BEGIN
    CALL load_dimensions();
    CALL load_facts(p_full_refresh);
END;
$$;

BEGIN;
CALL load_all(false);
COMMIT;