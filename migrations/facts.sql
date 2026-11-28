DO $$
BEGIN
    BEGIN
    CREATE SEQUENCE IF NOT EXISTS seq_fact_purchases;
    CREATE TABLE IF NOT EXISTS fact_purchases(
        id BIGINT NOT NULL PRIMARY KEY DEFAUL NEXTVAL('public.seq_fact_purchases'),
        product_id BIGINT NOT NULL,
        range_id BIGINT NOT NULL,
        category_id BIGINT NOT NULL,
        vendor_id BIGINT NOT NULL,
        quantity NUMERIC(18,4) NOT NULL,
        amount NUMERIC(18,2) NOT NULL,
        time_id BIGINT NOT NULL,
        date_add TIMESTAMP NOT NULL DEFAULT NOW()
    );

    COMMENT ON TABLE fact_purchases IS 'Таблица фактов закупки';
    COMMENT ON COLUMN fact_purchases.id IS 'Уникальный код';
    COMMENT ON COLUMN fact_purchases.product_id IS 'Код номенклатцры';
    COMMENT ON COLUMN fact_purchases.range_id IS 'Код единицы измерения';
    COMMENT ON COLUMN fact_purchases.category_id IS 'Код категории номенклатуры';
    COMMENT ON COLUMN fact_purchases.vendor_id IS 'Код поставщика';
    COMMENT ON COLUMN fact_purchases.quantity IS 'Количество';
    COMMENT ON COLUMN fact_purchases.amount IS 'Сумма';
    COMMENT ON COLUMN fact_purchases.time_id IS 'Код временного отрезка';
    COMMENT ON COLUMN fact_purchases.date_add IS 'Дата записи';


    END;

    BEGIN

    ALTER TABLE fact_purchases ADD FOREIGN KEY (product_id) REFERENCES dim_products (id);
    ALTER TABLE fact_purchases ADD FOREIGN KEY (range_id) REFERENCES dim_ranges (id);
    ALTER TABLE fact_purchases ADD FOREIGN KEY (category_id) REFERENCES dim_categories (id);
    ALTER TABLE fact_purchases ADD FOREIGN KEY (vendor_id) REFERENCES dim_vendors (id);
    ALTER TABLE fact_purchases ADD FOREIGN KEY (time_id) REFERENCES dim_time (id);

    END;
END $$