-- ============================================================================
-- OrderPulse: Food Order Performance Analytics
-- Epic 4: Data Preparation & Modelling (Part 1: STAGING Layer)
-- ----------------------------------------------------------------------------
-- Tasks Covered:
-- 1. Creating STAGING layer
--    - Cleaning raw data, handling NULLs
--    - Explicit casting to appropriate data types (DATE, TIMESTAMP, NUMERIC)
--    - Standardization of casing and categorical flags
--    - Deriving initial operational flags
-- ============================================================================

USE WAREHOUSE ORDERPULSE_WH;
USE DATABASE ORDERPULSE_DB;
USE SCHEMA ORDERPULSE_DB.STAGING;

-- ----------------------------------------------------------------------------
-- 1. STG_CUSTOMERS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_CUSTOMERS AS
SELECT
    TRIM(customer_id)::VARCHAR(50)                    AS customer_id,
    INITCAP(TRIM(customer_name))::VARCHAR(255)        AS customer_name,
    LOWER(TRIM(email))::VARCHAR(255)                  AS email,
    TRIM(phone)::VARCHAR(50)                          AS phone,
    INITCAP(TRIM(city))::VARCHAR(100)                 AS city,
    TRY_TO_NUMBER(TRIM(age))::INTEGER                 AS age,
    TRY_TO_DATE(TRIM(signup_date), 'YYYY-MM-DD')      AS signup_date,
    CURRENT_TIMESTAMP()                               AS stg_loaded_at
FROM ORDERPULSE_DB.RAW.RAW_CUSTOMERS
WHERE customer_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 2. STG_RESTAURANTS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_RESTAURANTS AS
SELECT
    TRIM(restaurant_id)::VARCHAR(50)                  AS restaurant_id,
    INITCAP(TRIM(restaurant_name))::VARCHAR(255)      AS restaurant_name,
    INITCAP(TRIM(cuisine))::VARCHAR(100)              AS cuisine,
    INITCAP(TRIM(city))::VARCHAR(100)                 AS city,
    COALESCE(TRY_TO_DECIMAL(TRIM(rating), 3, 1), 0.0) AS rating,
    TRY_TO_NUMBER(TRIM(cost_for_two))::INTEGER        AS cost_for_two,
    CASE 
        WHEN LOWER(TRIM(is_active)) IN ('true', '1', 't', 'yes') THEN TRUE
        ELSE FALSE
    END                                               AS is_active,
    CURRENT_TIMESTAMP()                               AS stg_loaded_at
FROM ORDERPULSE_DB.RAW.RAW_RESTAURANTS
WHERE restaurant_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 3. STG_MENU_ITEMS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_MENU_ITEMS AS
SELECT
    TRIM(item_id)::VARCHAR(50)                        AS item_id,
    TRIM(restaurant_id)::VARCHAR(50)                  AS restaurant_id,
    INITCAP(TRIM(item_name))::VARCHAR(255)            AS item_name,
    INITCAP(TRIM(category))::VARCHAR(100)             AS category,
    CASE 
        WHEN LOWER(TRIM(is_veg)) IN ('true', '1', 't', 'yes') THEN TRUE
        ELSE FALSE
    END                                               AS is_veg,
    COALESCE(TRY_TO_DECIMAL(TRIM(price), 10, 2), 0.0) AS price,
    CURRENT_TIMESTAMP()                               AS stg_loaded_at
FROM ORDERPULSE_DB.RAW.RAW_MENU_ITEMS
WHERE item_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 4. STG_ORDERS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_ORDERS AS
SELECT
    TRIM(order_id)::VARCHAR(50)                       AS order_id,
    TRIM(customer_id)::VARCHAR(50)                    AS customer_id,
    TRIM(restaurant_id)::VARCHAR(50)                  AS restaurant_id,
    TRY_TO_TIMESTAMP_NTZ(TRIM(order_datetime), 'YYYY-MM-DD HH24:MI:SS') AS order_datetime,
    TRY_TO_DATE(TRIM(order_datetime))                 AS order_date,
    DATE_PART('HOUR', TRY_TO_TIMESTAMP_NTZ(TRIM(order_datetime), 'YYYY-MM-DD HH24:MI:SS')) AS order_hour,
    COALESCE(TRY_TO_DECIMAL(TRIM(subtotal), 10, 2), 0.00)        AS subtotal,
    COALESCE(TRY_TO_DECIMAL(TRIM(discount_amount), 10, 2), 0.00) AS discount_amount,
    COALESCE(TRY_TO_DECIMAL(TRIM(delivery_fee), 10, 2), 0.00)    AS delivery_fee,
    COALESCE(TRY_TO_DECIMAL(TRIM(tax_amount), 10, 2), 0.00)       AS tax_amount,
    COALESCE(TRY_TO_DECIMAL(TRIM(total_amount), 10, 2), 0.00)     AS total_amount,
    UPPER(TRIM(payment_mode))::VARCHAR(50)            AS payment_mode,
    INITCAP(TRIM(order_status))::VARCHAR(50)          AS order_status,
    TRY_TO_NUMBER(TRIM(delivery_time_minutes))::INTEGER AS delivery_time_minutes,
    NULLIF(TRIM(cancellation_reason), '')::VARCHAR(255) AS cancellation_reason,
    -- Derived operational flag: Realized revenue (Only delivered or delivered late generate revenue)
    CASE 
        WHEN INITCAP(TRIM(order_status)) IN ('Delivered', 'Delivered Late') THEN TRUE
        ELSE FALSE
    END                                               AS is_realized,
    CURRENT_TIMESTAMP()                               AS stg_loaded_at
FROM ORDERPULSE_DB.RAW.RAW_ORDERS
WHERE order_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 5. STG_ORDER_ITEMS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_ORDER_ITEMS AS
SELECT
    TRIM(order_item_id)::VARCHAR(50)                  AS order_item_id,
    TRIM(order_id)::VARCHAR(50)                       AS order_id,
    TRIM(item_id)::VARCHAR(50)                        AS item_id,
    TRY_TO_NUMBER(TRIM(quantity))::INTEGER            AS quantity,
    COALESCE(TRY_TO_DECIMAL(TRIM(unit_price), 10, 2), 0.00)    AS unit_price,
    COALESCE(TRY_TO_DECIMAL(TRIM(item_subtotal), 10, 2), 0.00) AS item_subtotal,
    CURRENT_TIMESTAMP()                               AS stg_loaded_at
FROM ORDERPULSE_DB.RAW.RAW_ORDER_ITEMS
WHERE order_item_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 6. VALIDATION CHECKS ON STAGING
-- ----------------------------------------------------------------------------
SELECT 'STG_CUSTOMERS' AS TBL, COUNT(*) AS CNT FROM STG_CUSTOMERS
UNION ALL
SELECT 'STG_RESTAURANTS', COUNT(*) FROM STG_RESTAURANTS
UNION ALL
SELECT 'STG_MENU_ITEMS', COUNT(*) FROM STG_MENU_ITEMS
UNION ALL
SELECT 'STG_ORDERS', COUNT(*) FROM STG_ORDERS
UNION ALL
SELECT 'STG_ORDER_ITEMS', COUNT(*) FROM STG_ORDER_ITEMS;
