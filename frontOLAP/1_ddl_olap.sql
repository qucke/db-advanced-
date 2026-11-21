CREATE SCHEMA IF NOT EXISTS stg;

-- измеренмя

CREATE SEQUENCE IF NOT EXISTS seq_dim_ranges;
CREATE TABLE IF NOT EXISTS dim_ranges (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_ranges'),
    external_id bigint UNIQUE,
    name text,
    factor double precision,
    date_add timestamp DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS seq_dim_categories;
CREATE TABLE IF NOT EXISTS dim_categories (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_categories'),
    external_id bigint UNIQUE,
    name text,
    parent_id bigint,
    date_add timestamp DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS seq_dim_vendors;
CREATE TABLE IF NOT EXISTS dim_vendors (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_vendors'),
    external_id bigint UNIQUE,
    name text,
    parent_id bigint,
    parent_name text,
    date_add timestamp DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS seq_dim_personnel;
CREATE TABLE IF NOT EXISTS dim_personnel (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_personnel'),
    external_id bigint UNIQUE,
    name text,
    last_name text,
    first_name text,
    middle_name text,
    access_level smallint,
    has_pos_access boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    date_add timestamp DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS seq_dim_payment_types;
CREATE TABLE IF NOT EXISTS dim_payment_types (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_payment_types'),
    external_id bigint UNIQUE,
    name text,
    date_add timestamp DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS seq_dim_operation_types;
CREATE TABLE IF NOT EXISTS dim_operation_types (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_operation_types'),
    external_id bigint UNIQUE,
    name text,
    factor smallint CHECK (factor IN (-1, 1)),
    date_add timestamp DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS seq_dim_event_types;
CREATE TABLE IF NOT EXISTS dim_event_types (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_event_types'),
    external_id bigint UNIQUE,
    name text UNIQUE,
    date_add timestamp DEFAULT now()
);

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

CREATE SEQUENCE IF NOT EXISTS seq_dim_products;
CREATE TABLE IF NOT EXISTS dim_products (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_products'),
    external_id bigint UNIQUE,
    external_code text,
    name text,
    category_id bigint REFERENCES dim_categories(id),
    range_id bigint REFERENCES dim_ranges(id),
    cost numeric(18,2),
    is_active boolean DEFAULT true,
    date_add timestamp DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS seq_dim_storages;
CREATE TABLE IF NOT EXISTS dim_storages (
    id bigint PRIMARY KEY DEFAULT nextval('seq_dim_storages'),
    external_id bigint UNIQUE,
    name text,
    company_external_id bigint,
    company_name text,
    responsible_person_id bigint REFERENCES dim_personnel(id),
    date_add timestamp DEFAULT now()
);

-- факты
CREATE SEQUENCE IF NOT EXISTS seq_fact_purchases;
CREATE TABLE IF NOT EXISTS fact_purchases (
    id bigint PRIMARY KEY DEFAULT nextval('seq_fact_purchases'),
    time_id bigint REFERENCES dim_time(id),
    product_id bigint REFERENCES dim_products(id),
    vendor_id bigint REFERENCES dim_vendors(id),
    category_id bigint REFERENCES dim_categories(id),
    storage_id bigint REFERENCES dim_storages(id),
    range_id bigint REFERENCES dim_ranges(id),
    lines_count bigint,
    quantity numeric(18,4),
    amount numeric(18,2),
    avg_price numeric(18,2),
    date_add timestamp DEFAULT now(),
    UNIQUE (time_id, product_id, vendor_id, storage_id, range_id)
);

CREATE SEQUENCE IF NOT EXISTS seq_fact_sales;
CREATE TABLE IF NOT EXISTS fact_sales (
    id bigint PRIMARY KEY DEFAULT nextval('seq_fact_sales'),
    time_id bigint REFERENCES dim_time(id),
    product_id bigint REFERENCES dim_products(id),
    category_id bigint REFERENCES dim_categories(id),
    receipts_count bigint,
    lines_count bigint,
    quantity numeric(18,3),
    revenue numeric(18,2),
    refund_amount numeric(18,2),
    net_revenue numeric(18,2),
    date_add timestamp DEFAULT now(),
    UNIQUE (time_id, product_id)
);

CREATE SEQUENCE IF NOT EXISTS seq_fact_payments;
CREATE TABLE IF NOT EXISTS fact_payments (
    id bigint PRIMARY KEY DEFAULT nextval('seq_fact_payments'),
    time_id bigint REFERENCES dim_time(id),
    payment_type_id bigint REFERENCES dim_payment_types(id),
    operations_count bigint,
    amount numeric(18,2),
    date_add timestamp DEFAULT now(),
    UNIQUE (time_id, payment_type_id)
);

CREATE SEQUENCE IF NOT EXISTS seq_fact_personnel;
CREATE TABLE IF NOT EXISTS fact_personnel (
    id bigint PRIMARY KEY DEFAULT nextval('seq_fact_personnel'),
    time_id bigint REFERENCES dim_time(id),
    person_id bigint REFERENCES dim_personnel(id),
    event_type_id bigint REFERENCES dim_event_types(id),
    sessions_count bigint DEFAULT 0,
    errors_count bigint DEFAULT 0,
    bonus_records_count bigint DEFAULT 0,
    bonus_value numeric(18,2) DEFAULT 0,
    date_add timestamp DEFAULT now(),
    UNIQUE (time_id, person_id, event_type_id)
);

CREATE SEQUENCE IF NOT EXISTS seq_fact_stock;
CREATE TABLE IF NOT EXISTS fact_stock (
    id bigint PRIMARY KEY DEFAULT nextval('seq_fact_stock'),
    time_id bigint REFERENCES dim_time(id),
    product_id bigint REFERENCES dim_products(id),
    storage_id bigint REFERENCES dim_storages(id),
    operation_type_id bigint REFERENCES dim_operation_types(id),
    range_id bigint REFERENCES dim_ranges(id),
    lines_count bigint,
    quantity numeric(18,4),
    amount numeric(18,2),
    turnover_amount numeric(18,2),
    date_add timestamp DEFAULT now(),
    UNIQUE (time_id, product_id, storage_id, operation_type_id, range_id)
);

-- баланс
CREATE OR REPLACE VIEW v_stock_balance AS
SELECT
    f.time_id, f.product_id, f.storage_id, f.range_id,
    SUM(CASE WHEN o.factor = 1 THEN f.quantity ELSE 0 END) AS incoming_quantity,
    SUM(CASE WHEN o.factor = -1 THEN -f.quantity ELSE 0 END) AS outgoing_quantity,
    SUM(f.quantity) AS balance_quantity,
    SUM(f.amount) AS balance_amount
FROM fact_stock f
JOIN dim_operation_types o ON o.id = f.operation_type_id
GROUP BY f.time_id, f.product_id, f.storage_id, f.range_id;

-- stg
CREATE TABLE IF NOT EXISTS stg.ranges (
    external_id bigint PRIMARY KEY,
    name text,
    factor double precision
);

CREATE TABLE IF NOT EXISTS stg.categories (
    external_id bigint PRIMARY KEY,
    name text,
    parent_id bigint
);

CREATE TABLE IF NOT EXISTS stg.vendors (
    external_id bigint PRIMARY KEY,
    name text,
    parent_id bigint,
    parent_name text
);

CREATE TABLE IF NOT EXISTS stg.personnel (
    external_id bigint PRIMARY KEY,
    name text,
    last_name text,
    first_name text,
    middle_name text,
    access_level smallint,
    has_pos_access boolean,
    is_deleted boolean
);

CREATE TABLE IF NOT EXISTS stg.payment_types (
    external_id bigint PRIMARY KEY,
    name text
);

CREATE TABLE IF NOT EXISTS stg.operation_types (
    external_id bigint PRIMARY KEY,
    name text,
    factor smallint
);

CREATE TABLE IF NOT EXISTS stg.event_types (name text PRIMARY KEY);

CREATE TABLE IF NOT EXISTS stg.products (
    external_id bigint PRIMARY KEY,
    external_code text,
    name text,
    category_external_id bigint,
    range_external_id bigint,
    cost numeric(18,2),
    is_active boolean
);

CREATE TABLE IF NOT EXISTS stg.storages (
    external_id bigint PRIMARY KEY,
    name text,
    company_external_id bigint,
    company_name text,
    responsible_person_external_id bigint
);

CREATE TABLE IF NOT EXISTS stg.purchases (
    time_code integer,
    product_external_id bigint,
    vendor_external_id bigint,
    category_external_id bigint,
    storage_external_id bigint,
    range_external_id bigint,
    lines_count bigint,
    quantity numeric(18,4),
    amount numeric(18,2),
    avg_price numeric(18,2),
    PRIMARY KEY (time_code, product_external_id, vendor_external_id, storage_external_id, range_external_id)
);

CREATE TABLE IF NOT EXISTS stg.sales (
    time_code integer,
    product_external_id bigint,
    category_external_id bigint,
    receipts_count bigint,
    lines_count bigint,
    quantity numeric(18,3),
    revenue numeric(18,2),
    refund_amount numeric(18,2),
    net_revenue numeric(18,2),
    PRIMARY KEY (time_code, product_external_id)
);

CREATE TABLE IF NOT EXISTS stg.payments (
    time_code integer,
    payment_type_external_id bigint,
    operations_count bigint,
    amount numeric(18,2),
    PRIMARY KEY (time_code, payment_type_external_id)
);

CREATE TABLE IF NOT EXISTS stg.personnel_sessions (
    time_code integer,
    person_external_id bigint,
    event_type_name text,
    sessions_count bigint,
    errors_count bigint,
    PRIMARY KEY (time_code, person_external_id, event_type_name)
);

CREATE TABLE IF NOT EXISTS stg.personnel_bonus (
    time_code integer,
    person_external_id bigint,
    bonus_records_count bigint,
    bonus_value numeric(18,2),
    PRIMARY KEY (time_code, person_external_id)
);

CREATE TABLE IF NOT EXISTS stg.stock (
    time_code integer,
    product_external_id bigint,
    storage_external_id bigint,
    operation_type_external_id bigint,
    range_external_id bigint,
    lines_count bigint,
    quantity numeric(18,4),
    amount numeric(18,2),
    turnover_amount numeric(18,2),
    PRIMARY KEY (time_code, product_external_id, storage_external_id, operation_type_external_id, range_external_id)
);