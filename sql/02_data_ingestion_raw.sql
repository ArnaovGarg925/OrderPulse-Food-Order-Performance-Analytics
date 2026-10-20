-- ============================================================================
-- OrderPulse: Food Order Performance Analytics
-- Epic 3: Data Ingestion
-- ----------------------------------------------------------------------------
-- Tasks Covered:
-- 1. Create required RAW tables
-- 2. Loading the Tables (via COPY INTO) and Validating
-- ============================================================================

USE WAREHOUSE ORDERPULSE_WH;
USE DATABASE ORDERPULSE_DB;
USE SCHEMA ORDERPULSE_DB.RAW;

-- ----------------------------------------------------------------------------
-- 1. CREATE RAW TABLES
-- ----------------------------------------------------------------------------

-- Table 1: RAW_CUSTOMERS
CREATE OR REPLACE TABLE RAW_CUSTOMERS (
    customer_id      VARCHAR(50),
    customer_name    VARCHAR(255),
    email            VARCHAR(255),
    phone            VARCHAR(50),
    city             VARCHAR(100),
    age              VARCHAR(50),
    signup_date      VARCHAR(50)
)
COMMENT = 'Raw landing table for customer demographics and signups';

-- Table 2: RAW_RESTAURANTS
CREATE OR REPLACE TABLE RAW_RESTAURANTS (
    restaurant_id    VARCHAR(50),
    restaurant_name  VARCHAR(255),
    cuisine          VARCHAR(100),
    city             VARCHAR(100),
    rating           VARCHAR(50),
    cost_for_two     VARCHAR(50),
    is_active        VARCHAR(50)
)
COMMENT = 'Raw landing table for restaurant partner profiles and metrics';

-- Table 3: RAW_MENU_ITEMS
CREATE OR REPLACE TABLE RAW_MENU_ITEMS (
    item_id          VARCHAR(50),
    restaurant_id    VARCHAR(50),
    item_name        VARCHAR(255),
    category         VARCHAR(100),
    is_veg           VARCHAR(50),
    price            VARCHAR(50)
)
COMMENT = 'Raw landing table for restaurant menu items and prices';

-- Table 4: RAW_ORDERS
CREATE OR REPLACE TABLE RAW_ORDERS (
    order_id               VARCHAR(50),
    customer_id            VARCHAR(50),
    restaurant_id          VARCHAR(50),
    order_datetime         VARCHAR(50),
    subtotal               VARCHAR(50),
    discount_amount        VARCHAR(50),
    delivery_fee           VARCHAR(50),
    tax_amount             VARCHAR(50),
    total_amount           VARCHAR(50),
    payment_mode           VARCHAR(50),
    order_status           VARCHAR(50),
    delivery_time_minutes  VARCHAR(50),
    cancellation_reason    VARCHAR(255)
)
COMMENT = 'Raw landing table for food orders and outcomes';

-- Table 5: RAW_ORDER_ITEMS
CREATE OR REPLACE TABLE RAW_ORDER_ITEMS (
    order_item_id    VARCHAR(50),
    order_id         VARCHAR(50),
    item_id          VARCHAR(50),
    quantity         VARCHAR(50),
    unit_price       VARCHAR(50),
    item_subtotal    VARCHAR(50)
)
COMMENT = 'Raw landing table for order line item baskets';

-- ----------------------------------------------------------------------------
-- 2. FILE STAGING INSTRUCTIONS
-- ----------------------------------------------------------------------------
-- To stage files from local terminal using SnowSQL:
-- PUT file://./data/customers.csv @ORDERPULSE_STAGE AUTO_COMPRESS=TRUE;
-- PUT file://./data/restaurants.csv @ORDERPULSE_STAGE AUTO_COMPRESS=TRUE;
-- PUT file://./data/menu_items.csv @ORDERPULSE_STAGE AUTO_COMPRESS=TRUE;
-- PUT file://./data/orders.csv @ORDERPULSE_STAGE AUTO_COMPRESS=TRUE;
-- PUT file://./data/order_items.csv @ORDERPULSE_STAGE AUTO_COMPRESS=TRUE;

-- List files in the stage to verify
LIST @ORDERPULSE_STAGE;

-- ----------------------------------------------------------------------------
-- 3. COPY INTO COMMANDS
-- ----------------------------------------------------------------------------

COPY INTO RAW_CUSTOMERS
FROM @ORDERPULSE_STAGE/customers.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FILE_FORMAT)
ON_ERROR = 'CONTINUE';

COPY INTO RAW_RESTAURANTS
FROM @ORDERPULSE_STAGE/restaurants.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FILE_FORMAT)
ON_ERROR = 'CONTINUE';

COPY INTO RAW_MENU_ITEMS
FROM @ORDERPULSE_STAGE/menu_items.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FILE_FORMAT)
ON_ERROR = 'CONTINUE';

COPY INTO RAW_ORDERS
FROM @ORDERPULSE_STAGE/orders.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FILE_FORMAT)
ON_ERROR = 'CONTINUE';

COPY INTO RAW_ORDER_ITEMS
FROM @ORDERPULSE_STAGE/order_items.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FILE_FORMAT)
ON_ERROR = 'CONTINUE';

-- ----------------------------------------------------------------------------
-- 4. VALIDATION & DATA INTEGRITY CHECKS
-- ----------------------------------------------------------------------------

-- Check 1: Record Counts Across RAW Tables
SELECT 'RAW_CUSTOMERS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM RAW_CUSTOMERS
UNION ALL
SELECT 'RAW_RESTAURANTS', COUNT(*) FROM RAW_RESTAURANTS
UNION ALL
SELECT 'RAW_MENU_ITEMS', COUNT(*) FROM RAW_MENU_ITEMS
UNION ALL
SELECT 'RAW_ORDERS', COUNT(*) FROM RAW_ORDERS
UNION ALL
SELECT 'RAW_ORDER_ITEMS', COUNT(*) FROM RAW_ORDER_ITEMS;

-- Check 2: Sample Validation from each table
SELECT * FROM RAW_CUSTOMERS LIMIT 5;
SELECT * FROM RAW_RESTAURANTS LIMIT 5;
SELECT * FROM RAW_MENU_ITEMS LIMIT 5;
SELECT * FROM RAW_ORDERS LIMIT 5;
SELECT * FROM RAW_ORDER_ITEMS LIMIT 5;

-- Check 3: Null Key Checks
SELECT 
    COUNT_IF(customer_id IS NULL) AS null_cust_ids,
    COUNT(*) AS total_records
FROM RAW_CUSTOMERS;

SELECT 
    COUNT_IF(order_id IS NULL) AS null_order_ids,
    COUNT(*) AS total_orders
FROM RAW_ORDERS;
