# OrderPulse: System Architecture & Data Pipeline
**Author:** Arnaov Garg  
**Track:** Snowflake Data Engineering (SmartBridge / MySkillWallet.ai)  

## 1. High-Level Architecture Overview
OrderPulse implements the industry-standard **Medallion Data Architecture** (RAW ➔ STAGING ➔ CURATED) on the **Snowflake Data Cloud**. It ingests fragmented operational food delivery records and transforms them into an optimized dimensional model with persona-driven analytical data marts.


```
┌────────────────────────────────────────────────────────────────────────┐
│                        DATA GENERATION & SOURCES                       │
│  Customers CSV  •  Restaurants CSV  •  Menus CSV  •  Orders CSV (Line) │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ SnowSQL / Snowflake Stage PUT
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        ORDERPULSE_STAGE (Internal)                     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ COPY INTO (CSV_FILE_FORMAT)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       RAW SCHEMA (ORDERPULSE_DB.RAW)                   │
│   RAW_CUSTOMERS  •  RAW_RESTAURANTS  •  RAW_MENU_ITEMS                 │
│   RAW_ORDERS     •  RAW_ORDER_ITEMS                                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Cleaning, Null Handling, Casting
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    STAGING SCHEMA (ORDERPULSE_DB.STAGING)              │
│   STG_CUSTOMERS  •  STG_RESTAURANTS  •  STG_MENU_ITEMS                 │
│   STG_ORDERS     •  STG_ORDER_ITEMS                                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Star Schema Modelling & Feature Eng
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    CURATED SCHEMA (ORDERPULSE_DB.CURATED)              │
│  Dimensions:  DIM_CUSTOMERS (RFM), DIM_RESTAURANTS, DIM_MENU_ITEMS,    │
│               DIM_DATE, DIM_TIME (Peak Meal Periods)                   │
│  Facts:       FACT_ORDERS (Realized/Lost GMV), FACT_ORDER_ITEMS        │
│  Data Marts:  V_PRIYA_CUSTOMER_ENGAGEMENT                              │
│               V_DANIEL_RESTAURANT_PARTNERSHIPS                         │
│               V_GRACE_EXECUTIVE_OVERVIEW                               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Snowflake Connector / SQL Queries
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               STREAMLIT CLOUD & PERFORMANCE BENCHMARKS                 │
│   Interactive Multi-Tab Dashboard (Grace, Priya, Daniel, Operations)   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Medallion Layer Specifications

### 2.1 RAW Layer (`ORDERPULSE_DB.RAW`)
- **Objective:** Pure ingestion of CSV landing files without transformations.
- **File Format:** `CSV_FILE_FORMAT` (`TYPE = CSV`, `FIELD_DELIMITER = ','`, `SKIP_HEADER = 1`, `TRIM_SPACE = TRUE`).
- **Stage:** `@ORDERPULSE_STAGE`.
- **Tables:**
  - `RAW_CUSTOMERS` (7 columns)
  - `RAW_RESTAURANTS` (7 columns)
  - `RAW_MENU_ITEMS` (6 columns)
  - `RAW_ORDERS` (13 columns)
  - `RAW_ORDER_ITEMS` (6 columns)

### 2.2 STAGING Layer (`ORDERPULSE_DB.STAGING`)
- **Objective:** Cleaning, trimming, data typing, and null management.
- **Transformations:**
  - `TRY_TO_DATE()` and `TRY_TO_TIMESTAMP_NTZ()` for reliable date parsing.
  - Standardized casing (`INITCAP`, `UPPER`, `LOWER`).
  - Coalesced numeric nulls with `0.00`.
  - Derived operational flags like `is_realized` (identifying delivered orders generating real cash inflow).
  - Added ETL metadata audit column `stg_loaded_at`.

### 2.3 CURATED Layer (`ORDERPULSE_DB.CURATED`)
- **Objective:** Dimensional Modelling (Star Schema) and Business Marts.
- **Surrogate Keys:** Generated using deterministic `MD5()` hashes of natural business keys (`customer_key`, `restaurant_key`, `item_key`, `order_key`).
- **Fact Tables:**
  - `FACT_ORDERS`: Grain = 1 order per row. Measures: `gross_order_value`, `discount_amount`, `delivery_fee`, `tax_amount`, `realized_revenue`, `basket_item_quantity`, `delivery_time_minutes`.
  - `FACT_ORDER_ITEMS`: Grain = 1 item per order line. Measures: `quantity`, `unit_price`, `item_subtotal`.
- **Dimension Tables:**
  - `DIM_CUSTOMERS`: Enriched with RFM segmentation (`loyalty_segment`: Single-Order, Occasional, Frequent, VIP), repeat buyer flag, lifetime orders, lifetime spend.
  - `DIM_RESTAURANTS`: Enriched with `rating_tier` (Top Rated 4.5+, High 4.0-4.4, Average 3.5-3.9, Low <3.5) and `cost_tier`.
  - `DIM_MENU_ITEMS`: Enriched with `price_tier` and vegetarian preference labels.
  - `DIM_DATE`: Date spine covering 731 days with quarters, months, day names, and weekend flags.
  - `DIM_TIME`: 24-hour time spine segmented into operational meal slots: *Breakfast (7-11 AM)*, *Lunch Peak (11 AM-4 PM)*, *Snacks (4-7 PM)*, *Dinner Peak (7-11 PM)*, *Late Night (11 PM-7 AM)*.

---

## 3. Persona-Driven Data Marts
1. **`V_PRIYA_CUSTOMER_ENGAGEMENT`**: Single view of customer ordering behavior for CRM teams, tracking repeat share, churn-risk single buyers, and basket size variance.
2. **`V_DANIEL_RESTAURANT_PARTNERSHIPS`**: Commercial evidence mart evaluating cuisine demand, restaurant rating elasticity, and menu item sales contribution.
3. **`V_GRACE_EXECUTIVE_OVERVIEW`**: Executive scorecard tracking monthly GMV growth, realized vs lost revenue from cancellations, net AOV, and on-time fulfillment rates.
