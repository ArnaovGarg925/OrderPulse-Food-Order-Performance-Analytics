# OrderPulse: Food Order Performance Analytics
## Comprehensive End-to-End Capstone Project Report
**Track:** Snowflake Data Engineering (SmartBridge / MySkillWallet.ai)  
**Author:** Arnaov Garg  
**Email:** ag5088@srmist.edu.in  
**Institution:** SRM Institute of Science and Technology (SRMIST)  
**Date:** October 2026  



---

## Executive Summary
In the modern online food ordering industry, operational datasets spanning customers, restaurant partners, menus, orders, and delivery fulfillment typically reside in disparate, transactional silos. This fragmentation prevents business leaders from obtaining a single, reliable source of truth regarding customer loyalty, demand fluctuations, basket economics, and service reliability.

**OrderPulse** delivers an enterprise-grade cloud analytics platform built on **Snowflake's Medallion Architecture** (`RAW` ➔ `STAGING` ➔ `CURATED`). The pipeline ingests over **12,000 orders**, **32,900+ order line items**, **600+ menu items**, and **80 restaurant partners** across major Indian metropolitan cities, transforming them into an optimized Star Schema and three persona-specific analytical data marts. An interactive **Streamlit web application** is deployed on top of the curated mart to enable instantaneous, self-service decision-making.

---

## 1. Problem Definition & Objectives (Epic 1)

### 1.1 Core Business Problem
- **Data Fragmentation:** Crucial business entities (customers, restaurants, menus, orders, line items) exist across disparate systems without an integrated data model.
- **Inconsistent Metrics:** Conflicting definitions of metrics like Gross Merchandise Value (GMV) vs. Realized Delivered Revenue lead to delayed executive decisions.
- **Blind Spots in Customer Retention:** Inability to distinguish between one-time shoppers and high-value repeat loyalists hinders customer acquisition and engagement strategies.
- **Anecdotal Partner Negotiations:** Lack of quantitative evidence relating restaurant ratings, cuisine demand, and menu item popularity makes partnership management subjective.

### 1.2 Target Business Personas & Requirements
1. **Scenario 1 — Priya (Customer Engagement Manager):**
   - Single view of customer ordering frequency and loyalty tiers.
   - Exact share of one-time order customers vs. repeat loyal customers.
   - Identification of basket size variance (units and spend) to drive cross-sell promotions.
2. **Scenario 2 — Daniel (Restaurant Partnerships Manager):**
   - High-demand cuisines and popular menu items by city.
   - Empirical proof of whether restaurant ratings directly drive order volume.
   - Menu pricing analysis and vegetarian vs. non-vegetarian demand shares.
3. **Scenario 3 — Grace (Business Executive):**
   - High-level demand trends and seasonal revenue fluctuations.
   - Clear accounting of gross placed orders vs. realized revenue (net of cancellations).
   - Delivery SLA compliance (On-time vs. Late delivery rates) across operational cities.

---

## 2. Data Architecture Setup (Epic 2)

### 2.1 Virtual Warehouse & Database Setup
- **Virtual Warehouse:** `ORDERPULSE_WH` (Size: `X-SMALL`, Auto-suspend: `60s`, Auto-resume: `TRUE`). Minimizes credit consumption while ensuring sub-second query performance.
- **Database:** `ORDERPULSE_DB`.
- **Schemas:**
  1. `RAW`: Landing zone for unadulterated CSV file data.
  2. `STAGING`: Cleansed, standardized, typed tables with audit lineage.
  3. `CURATED`: Star schema dimensional model and analytical views.

### 2.2 Storage & File Format Setup
- **File Format:** `CSV_FILE_FORMAT` (`TYPE = 'CSV'`, `FIELD_DELIMITER = ','`, `SKIP_HEADER = 1`, `TRIM_SPACE = TRUE`, `NULL_IF = ('NULL', '', '\\N')`).
- **Internal Stage:** `@ORDERPULSE_STAGE` created inside `ORDERPULSE_DB.RAW` to stage raw CSV files securely.

---

## 3. Data Ingestion (Epic 3)

### 3.1 Raw Table Ingestion
Raw tables were instantiated with permissive `VARCHAR` types to guarantee zero load failures during raw ingestion:
- `RAW_CUSTOMERS` (1,500 rows)
- `RAW_RESTAURANTS` (80 rows)
- `RAW_MENU_ITEMS` (612 rows)
- `RAW_ORDERS` (12,000 rows)
- `RAW_ORDER_ITEMS` (32,921 rows)

### 3.2 Loading & Validation
Files were ingested using `COPY INTO` commands with `ON_ERROR = 'CONTINUE'`. Post-load validation verified 100% record integrity, matching source file row counts without column truncation or corrupted delimiters.

---

## 4. Data Preparation & Modelling (Epic 4)

### 4.1 Staging Transformations (`ORDERPULSE_DB.STAGING`)
1. **Type Casting:** Converted strings to native Snowflake types (`DATE`, `TIMESTAMP_NTZ`, `NUMBER(10,2)`, `INTEGER`, `BOOLEAN`).
2. **String Standardization:** Handled whitespace via `TRIM()`, standardized proper casing via `INITCAP()`, and lowercased email addresses.
3. **Null Handling & Defaulting:** Applied `COALESCE()` on pricing and discount fields to prevent downstream arithmetic calculation errors.
4. **Derived Lineage:** Added `stg_loaded_at` timestamp and an operational `is_realized` flag (`TRUE` when status is `Delivered` or `Delivered Late`).

### 4.2 Curated Star Schema Modelling (`ORDERPULSE_DB.CURATED`)
The dimensional model implements surrogate keys generated via `MD5()` hash functions:

```
                          ┌────────────────────────┐
                          │       DIM_DATE         │
                          │   (date_key [PK])      │
                          └───────────┬────────────┘
                                      │
┌────────────────────────┐            │            ┌────────────────────────┐
│     DIM_CUSTOMERS      │            ▼            │    DIM_RESTAURANTS     │
│  (customer_key [PK])   ├──────► FACT_ORDERS ◄────┤  (restaurant_key [PK]) │
└────────────────────────┘       (order_key [PK])  └────────────────────────┘
                                      ▲
                                      │
                          ┌───────────┴────────────┐
                          │       DIM_TIME         │
                          │   (time_key [PK])      │
                          └────────────────────────┘
                                      ▲
                                      │
                          ┌───────────┴────────────┐
                          │    FACT_ORDER_ITEMS    │
                          │(order_item_key [PK])   │
                          └───────────┬────────────┘
                                      │
                                      ▼
                          ┌────────────────────────┐
                          │     DIM_MENU_ITEMS     │
                          │    (item_key [PK])     │
                          └────────────────────────┘
```

#### Feature Engineering & Segmentation:
- **`DIM_CUSTOMERS`:**
  - `loyalty_segment`: `Single-Order Customer` (1 order), `Occasional Buyer (2-4)`, `Frequent Buyer (5-9)`, `Loyal / VIP (10+)`.
  - `is_repeat_customer`: Boolean flag indicating retention.
  - `customer_aov`: Lifetime average spend per order.
- **`DIM_RESTAURANTS`:**
  - `rating_tier`: `Top Rated (4.5 - 5.0)`, `High Rated (4.0 - 4.4)`, `Average Rated (3.5 - 3.9)`, `Low Rated (< 3.5)`.
  - `cost_tier`: `Budget Friendly`, `Mid-Range`, `Premium Dining`.
- **`DIM_TIME`:**
  - `meal_period`: `Breakfast (7-11 AM)`, `Lunch Peak (11 AM-4 PM)`, `Snacks (4-7 PM)`, `Dinner Peak (7-11 PM)`, `Late Night (11 PM-7 AM)`.
- **`FACT_ORDERS`:**
  - `gross_order_value`: Total placed order amount.
  - `realized_revenue`: Actual revenue recognized (₹0.00 for cancelled orders).
  - `basket_item_quantity`: Total item units in basket.
  - `is_delivered`, `is_delivered_late`, `is_cancelled`: Binary flags for fast aggregation.

---

## 5. Business Analytics & Scenario Findings (Epic 5)

### 5.1 Platform KPI Summary
| Metric | Platform Value | Business Interpretation |
|---|---|---|
| **Total Orders Placed** | **12,000** | High order volume spanning a full calendar year across 7 cities. |
| **Gross Merchandise Value (GMV)** | **₹96,22,612.70** | Total order value placed across the platform. |
| **Realized Revenue** | **₹89,37,747.85** | 92.88% of GMV successfully converted into realized revenue. |
| **Lost Cancellation Revenue** | **₹6,84,864.85** | 7.12% value loss due to order cancellations. |
| **Overall Average Order Value (AOV)** | **₹801.88** | Healthy basket spend driven by family & combo meal orders. |
| **Average Basket Size** | **3.94 items** | High average item count per basket. |
| **On-Time Delivery Rate** | **81.93%** | Orders delivered within the 45-minute benchmark SLA. |
| **Late Delivery Rate** | **11.00%** | Deliveries exceeding 45 minutes (mostly peak dinner hours). |
| **Cancellation Rate** | **7.07%** | Low platform churn rate. |

---

### 5.2 Scenario Deep-Dives

#### Scenario 1: Priya — Customer Engagement Analysis
- **Repeat vs. Single-Order Ratio:**
  - Out of 1,500 registered customers, **69.8% (1,047 customers)** are repeat buyers, while **30.2% (453 customers)** are single-order buyers.
  - Single-order customers represent an immediate retention campaign opportunity.
- **Basket Size Economics:**
  - 1-item orders average ₹415 AOV.
  - 3-item orders average ₹785 AOV.
  - 5+ item orders average ₹1,340+ AOV.
- **Recommendation:** Implement checkout prompts ("Add a beverage/dessert for ₹49") and targeted "Welcome Back" discounts (20% off) for 1-time buyers within 10 days of signup.

#### Scenario 2: Daniel — Restaurant Partnerships Analysis
- **Rating Elasticity on Demand:**
  - Restaurants in the **Top Rated (4.5 - 5.0)** tier average **194 orders per restaurant**.
  - Restaurants in the **High Rated (4.0 - 4.4)** tier average **151 orders per restaurant**.
  - Restaurants in the **Average/Low (< 3.9)** tier average **under 92 orders per restaurant**.
  - *Finding:* A 0.5-star increase in rating correlates with an approximate **28% increase in order volume**.
- **Top Cuisines:**
  1. *North Indian* (₹18.4 Lakhs revenue)
  2. *Biryani* (₹16.8 Lakhs revenue)
  3. *Chinese* (₹14.2 Lakhs revenue)
- **Recommendation:** Leverage data during partner onboarding to show how maintaining >4.2 ratings and offering signature Biryani/North Indian combos dramatically increases partner earnings.

#### Scenario 3: Grace — Executive Demand & Reliability
- **Demand Seasonality:**
  - Order volume peaks during Q4 (October - December) driven by festivals and weekend evening ordering.
  - Peak ordering occurs between **7:00 PM and 10:00 PM** (Dinner Peak accounts for 43% of daily orders).
- **Service Reliability:**
  - Bengaluru and Mumbai boast the highest on-time rates (>83%).
  - Hyderabad and Delhi experience higher late delivery rates during monsoon and peak Friday/Saturday dinners.
- **Cancellation Root Causes:**
  - 38% "Restaurant delay in preparation".
  - 27% "Delivery partner unavailable during peak rain/hours".
  - 18% "Customer changed mind".

---

## 6. Streamlit Application Development (Epic 6)
An interactive dashboard application was engineered using **Streamlit**, **Pandas**, and **Plotly Express**:
- **Multi-Tab Architecture:**
  - Tab 1: Executive Overview (Grace)
  - Tab 2: Customer Engagement (Priya)
  - Tab 3: Restaurant Partnerships (Daniel)
  - Tab 4: Delivery & Operations
  - Tab 5: Snowflake Architecture & Testing
- **Dynamic Interactivity:** Real-time filtering by Date Range, City, Cuisine, and Order Status.
- **Zero-Setup Local & Cloud Support:** Connects natively to Snowflake or falls back transparently to the local database.

---

## 7. Performance Testing & Auditing (Epic 7)

### 7.1 Amount of Data Loaded
- **RAW Layer:** 5 tables, 47,113 total landing rows.
- **STAGING Layer:** 5 tables, 47,113 cleansed rows.
- **CURATED Layer:** 5 dimensions, 2 fact tables, and 3 analytical views.
- **Total Relational Footprint:** Under 12 MB compressed, optimal for Snowflake micro-partition clustering.

### 7.2 Filter Efficiency & Micro-Partition Pruning
- **Full Table Scan (Baseline):** Scans 100% of micro-partitions. Elapsed time: ~312 ms.
- **Partition-Pruned Query (`order_date` BETWEEN Oct 1 and Oct 31):** Snowflake's metadata engine pruned 91.7% of micro-partitions, reading only 8.3% of data. Elapsed time: ~48 ms (**6.5x performance speedup**).
- **Result Cache Hit:** Identical analytical query served from Snowflake Result Cache in **12 ms (26x speedup)**.

### 7.3 Audit of Engineered Fields (24+ New Columns)
- Documented 24 distinct analytical columns engineered during ETL, including surrogate keys, RFM loyalty tiers, rating brackets, meal periods, and binary outcome indicators.

### 7.4 Query History Analysis
- Audited via `TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())`. Confirmed zero compilation errors, average query execution under 100 ms on `ORDERPULSE_WH` (X-Small), and efficient warehouse auto-suspend after 60 seconds.

---

## 8. Conclusion
OrderPulse demonstrates the full power of Snowflake's cloud data warehouse and Streamlit visualization capabilities. By transforming disconnected operational records into a unified, high-performance dimensional model, stakeholders across customer engagement, merchant partnerships, and executive management gain clear, evidence-backed clarity to optimize revenue, delight diners, and improve fulfillment reliability.
