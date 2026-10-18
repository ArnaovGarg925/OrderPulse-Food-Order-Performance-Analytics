-- ============================================================================
-- OrderPulse: Food Order Performance Analytics
-- Epic 2: Data Architecture Setup
-- ----------------------------------------------------------------------------
-- Tasks Covered:
-- 1. Create project Warehouse and Database
-- 2. Create Schemas (RAW, STAGING, CURATED) and Internal Stage
-- 3. Create CSV File Format
-- ============================================================================

-- Step 1: Create Virtual Warehouse
CREATE WAREHOUSE IF NOT EXISTS ORDERPULSE_WH
    WITH 
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Virtual Warehouse for OrderPulse Food Order Analytics ETL and Queries';

USE WAREHOUSE ORDERPULSE_WH;

-- Step 2: Create Project Database
CREATE DATABASE IF NOT EXISTS ORDERPULSE_DB
    COMMENT = 'Central Database for OrderPulse Food Order Performance Analytics';

USE DATABASE ORDERPULSE_DB;

-- Step 3: Create Medallion Architecture Schemas
-- Schema 1: RAW - Holds ingested raw CSV files without alteration
CREATE SCHEMA IF NOT EXISTS ORDERPULSE_DB.RAW
    COMMENT = 'Raw ingestion layer containing landing tables matching CSV structure';

-- Schema 2: STAGING - Data cleansing, casting, standardized values, null handling
CREATE SCHEMA IF NOT EXISTS ORDERPULSE_DB.STAGING
    COMMENT = 'Staging layer for clean, standardized, and typed relational tables';

-- Schema 3: CURATED - Star Schema (Dimensions & Facts) + Business Marts for personas
CREATE SCHEMA IF NOT EXISTS ORDERPULSE_DB.CURATED
    COMMENT = 'Curated dimensional model (Facts, Dimensions) and analytical views';

-- Step 4: Create CSV File Format in RAW Schema
USE SCHEMA ORDERPULSE_DB.RAW;

CREATE OR REPLACE FILE FORMAT CSV_FILE_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '', '\\N')
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    COMMENT = 'Standard CSV file format for OrderPulse data files';

-- Step 5: Create Internal Stage for File Uploads
CREATE OR REPLACE STAGE ORDERPULSE_STAGE
    FILE_FORMAT = CSV_FILE_FORMAT
    COMMENT = 'Internal stage for landing OrderPulse CSV files before ingestion';

-- Verify Setup
SHOW WAREHOUSES LIKE 'ORDERPULSE_WH';
SHOW SCHEMAS IN DATABASE ORDERPULSE_DB;
SHOW STAGES IN SCHEMA ORDERPULSE_DB.RAW;
SHOW FILE FORMATS IN SCHEMA ORDERPULSE_DB.RAW;
