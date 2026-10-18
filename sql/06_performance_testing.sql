-- ============================================================================
-- OrderPulse: Food Order Performance Analytics
-- Epic 7: Performance Testing
-- ----------------------------------------------------------------------------
-- Tasks Covered:
-- 1. Amount of data loaded (Row count and storage footprint audit)
-- 2. Filter Efficiency test (Partition pruning and filter execution comparison)
-- 3. No of New Field Created (Audit of feature engineering and derived columns)
-- 4. Query History (Execution time, bytes scanned, and caching metrics)
-- ============================================================================

USE WAREHOUSE ORDERPULSE_WH;
USE DATABASE ORDERPULSE_DB;

-- ============================================================================
-- TEST 1: AMOUNT OF DATA LOADED
-- ============================================================================
-- Objective: Verify total volume of records and storage footprint across all layers.

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    ROW_COUNT,
    ROUND(BYTES / (1024 * 1024), 3) AS SIZE_MB,
    TABLE_TYPE,
    LAST_ALTERED
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('RAW', 'STAGING', 'CURATED')
ORDER BY TABLE_SCHEMA, ROW_COUNT DESC;

-- Aggregate Data Volume Summary
SELECT
    TABLE_SCHEMA,
    COUNT(TABLE_NAME)                AS TOTAL_TABLES,
    SUM(ROW_COUNT)                   AS TOTAL_ROW_COUNT,
    ROUND(SUM(BYTES) / 1024, 2)      AS TOTAL_SIZE_KB
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('RAW', 'STAGING', 'CURATED')
GROUP BY TABLE_SCHEMA
ORDER BY TOTAL_ROW_COUNT DESC;

-- ============================================================================
-- TEST 2: FILTER EFFICIENCY TEST (PARTITION PRUNING)
-- ============================================================================
-- Objective: Compare unpruned full scan query vs highly filtered partition pruned query.

-- Test 2A: Baseline Query (Full Table Scan across entire 12-month orders)
SELECT 
    COUNT(*),
    SUM(gross_order_value),
    AVG(delivery_time_minutes)
FROM ORDERPULSE_DB.CURATED.FACT_ORDERS;

-- Test 2B: Pruned / Filtered Query (Single Month + Order Status filter)
-- Snowflake Query Profile will show: Partitions Scanned << Total Partitions
SELECT 
    COUNT(*),
    SUM(gross_order_value),
    AVG(delivery_time_minutes)
FROM ORDERPULSE_DB.CURATED.FACT_ORDERS
WHERE order_date BETWEEN '2024-10-01' AND '2024-10-31'
  AND order_status = 'Delivered';

-- Test 2C: High Cardinality Dimension Filter (Indexed by surrogate key)
SELECT 
    r.restaurant_name,
    COUNT(f.order_id) AS orders_count
FROM ORDERPULSE_DB.CURATED.FACT_ORDERS f
JOIN ORDERPULSE_DB.CURATED.DIM_RESTAURANTS r ON f.restaurant_key = r.restaurant_key
WHERE r.cuisine = 'Biryani'
  AND r.rating_tier = 'Top Rated (4.5 - 5.0)'
GROUP BY r.restaurant_name;

-- ============================================================================
-- TEST 3: NUMBER OF NEW FIELDS CREATED (FEATURE ENGINEERING AUDIT)
-- ============================================================================
-- Objective: Document all enriched and derived analytical fields created 
-- beyond the raw source data across STAGING and CURATED layers.

WITH raw_cols AS (
    SELECT TABLE_NAME, COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'RAW'
),
stg_curated_cols AS (
    SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA IN ('STAGING', 'CURATED')
)
SELECT 
    s.TABLE_SCHEMA,
    s.TABLE_NAME,
    s.COLUMN_NAME,
    s.DATA_TYPE,
    CASE 
        -- Staging Layer Derived
        WHEN s.COLUMN_NAME = 'STG_LOADED_AT' THEN 'Audit timestamp for ETL lineage'
        WHEN s.COLUMN_NAME = 'IS_REALIZED' THEN 'Operational flag: realized revenue outcome'
        WHEN s.COLUMN_NAME = 'ORDER_HOUR' THEN 'Engineered hour component for peak demand'
        -- Curated Dimensions Derived
        WHEN s.COLUMN_NAME = 'CUSTOMER_KEY' THEN 'MD5 Surrogate Key for dimension linking'
        WHEN s.COLUMN_NAME = 'AGE_GROUP' THEN 'Demographic age bracket (Gen Z, Professionals, etc.)'
        WHEN s.COLUMN_NAME = 'LIFETIME_ORDERS' THEN 'Aggregated customer order count'
        WHEN s.COLUMN_NAME = 'LIFETIME_SPEND' THEN 'Aggregated customer cumulative GMV'
        WHEN s.COLUMN_NAME = 'CUSTOMER_AOV' THEN 'Historical customer average order value'
        WHEN s.COLUMN_NAME = 'LOYALTY_SEGMENT' THEN 'Priya KPI: RFM ordering frequency loyalty tier'
        WHEN s.COLUMN_NAME = 'IS_REPEAT_CUSTOMER' THEN 'Boolean flag: repeat vs single-order buyer'
        WHEN s.COLUMN_NAME = 'RESTAURANT_KEY' THEN 'MD5 Surrogate Key for restaurant dimension'
        WHEN s.COLUMN_NAME = 'RATING_TIER' THEN 'Daniel KPI: Rating elasticity bucket'
        WHEN s.COLUMN_NAME = 'COST_TIER' THEN 'Budget / Mid-range / Premium categorization'
        WHEN s.COLUMN_NAME = 'ITEM_KEY' THEN 'MD5 Surrogate Key for menu dimension'
        WHEN s.COLUMN_NAME = 'VEG_FLAG_LABEL' THEN 'Clean string label for vegetarian preference'
        WHEN s.COLUMN_NAME = 'PRICE_TIER' THEN 'Menu pricing bracket'
        WHEN s.COLUMN_NAME = 'MEAL_PERIOD' THEN 'Time dimension slot (Breakfast, Lunch, Dinner, etc.)'
        WHEN s.COLUMN_NAME = 'IS_PEAK_HOUR' THEN 'Rush hour operational flag'
        WHEN s.COLUMN_NAME = 'IS_WEEKEND' THEN 'Calendar weekend operational flag'
        -- Curated Fact Derived
        WHEN s.COLUMN_NAME = 'ORDER_KEY' THEN 'MD5 Surrogate Key for fact table'
        WHEN s.COLUMN_NAME = 'DISTINCT_ITEMS_COUNT' THEN 'Basket diversity metric'
        WHEN s.COLUMN_NAME = 'BASKET_ITEM_QUANTITY' THEN 'Priya KPI: Total units in order basket'
        WHEN s.COLUMN_NAME = 'GROSS_ORDER_VALUE' THEN 'Total placed value before cancellations'
        WHEN s.COLUMN_NAME = 'REALIZED_REVENUE' THEN 'Grace KPI: Actual recognized revenue'
        WHEN s.COLUMN_NAME = 'IS_DELIVERED' THEN 'Binary outcome flag: On-time delivery'
        WHEN s.COLUMN_NAME = 'IS_DELIVERED_LATE' THEN 'Binary outcome flag: SLA breach'
        WHEN s.COLUMN_NAME = 'IS_CANCELLED' THEN 'Binary outcome flag: Order attrition'
        ELSE 'Transformed & typed from RAW'
    END AS DERIVATION_PURPOSE
FROM stg_curated_cols s
WHERE s.COLUMN_NAME NOT IN (SELECT COLUMN_NAME FROM raw_cols)
ORDER BY s.TABLE_SCHEMA, s.TABLE_NAME, s.COLUMN_NAME;

-- Count of New Fields Created Summary
SELECT 
    'STAGING & CURATED DERIVED COLUMNS' AS METRIC_NAME,
    COUNT(*) AS TOTAL_DERIVED_FIELDS_CREATED
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA IN ('STAGING', 'CURATED')
  AND COLUMN_NAME NOT IN (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'RAW');

-- ============================================================================
-- TEST 4: QUERY HISTORY AUDIT
-- ============================================================================
-- Objective: Measure execution performance, query durations, and cache usage.

SELECT
    QUERY_ID,
    QUERY_TEXT,
    DATABASE_NAME,
    SCHEMA_NAME,
    WAREHOUSE_NAME,
    EXECUTION_STATUS,
    TOTAL_ELAPSED_TIME / 1000.0 AS TOTAL_ELAPSED_SECONDS,
    BYTES_SCANNED / (1024 * 1024) AS MB_SCANNED,
    PERCENTAGE_SCANNED_FROM_CACHE,
    ROWS_PRODUCED,
    START_TIME
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    RESULT_LIMIT => 25
))
ORDER BY START_TIME DESC;
