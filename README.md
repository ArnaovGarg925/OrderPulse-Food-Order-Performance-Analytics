# OrderPulse: Food Order Performance Analytics 🍔📊

[![Snowflake](https://img.shields.io/badge/Snowflake-Data_Cloud-29B5E8?logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Streamlit](https://img.shields.io/badge/Streamlit-Dashboard-FF4B4B?logo=streamlit&logoColor=white)](https://streamlit.io/)
[![Architecture](https://img.shields.io/badge/Architecture-Medallion-orange)](#system-architecture)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

**OrderPulse** is an enterprise-grade food ordering performance and customer behavior analytics platform engineered on **Snowflake** using the **Medallion Data Architecture** (`RAW` ➔ `STAGING` ➔ `CURATED`). It integrates operational records from customers, restaurants, menus, orders, and delivery fulfillment to empower data-driven decision-making across executive strategy, customer engagement, and merchant partnerships.

---

## 📌 Table of Contents
1. [Project Overview & Business Problems](#project-overview--business-problems)
2. [Target Personas & Scenarios](#target-personas--scenarios)
3. [System Architecture](#system-architecture)
4. [Project Structure](#project-structure)
5. [Key Performance Indicators (KPIs)](#key-performance-indicators-kpis)
6. [Step-by-Step Setup & Execution](#step-by-step-setup--execution)
7. [Streamlit Interactive Web Application](#streamlit-interactive-web-application)
8. [Performance Testing & Auditing](#performance-testing--auditing)
9. [Kanban Task Mapping & Submission](#kanban-task-mapping--submission)

---

## 📖 Project Overview & Business Problems

Online food delivery platforms generate rich operational data across orders, basket line items, diner profiles, restaurant menus, delivery durations, and cancellations. However, because these systems often operate in isolated databases, organizations face critical operational bottlenecks:

- **Lack of a Unified Truth:** Inability to reconcile placed orders against actual delivered revenue.
- **Customer Churn Blind Spots:** Difficulty segmenting one-time diners from high-lifetime-value repeat customers.
- **Subjective Partner Negotiations:** Inability to correlate restaurant ratings and menu items with consumer demand.
- **Delivery Bottlenecks:** Inconsistent tracking of SLA breaches (late deliveries) and order cancellations.

**OrderPulse** solves these challenges by building an automated, high-performance data warehouse and self-service analytics suite.

---

## 👥 Target Personas & Scenarios

| Persona | Role | Core Requirement & Solution |
|---|---|---|
| **Priya** | Customer Engagement Manager | Single view of diner loyalty, repeat vs. one-time buyer shares, and basket size spend variance to launch targeted re-engagement campaigns. |
| **Daniel** | Restaurant Partnerships Manager | Demand by cuisine and menu items, plus quantitative proof of how restaurant ratings influence order volume to guide partner negotiations. |
| **Grace** | Business Executive | High-level GMV trends over time, Gross vs. Realized Delivered Revenue, Net Average Order Value (AOV), and on-time fulfillment rates. |

---

## 🏛️ System Architecture

OrderPulse implements a three-tier **Medallion Architecture** inside the `ORDERPULSE_DB` database on Snowflake:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DATA GENERATION & SOURCES                       │
│  Customers CSV  •  Restaurants CSV  •  Menus CSV  •  Orders CSV (Line) │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ SnowSQL / Stage PUT
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       RAW SCHEMA (ORDERPULSE_DB.RAW)                   │
│   RAW_CUSTOMERS  •  RAW_RESTAURANTS  •  RAW_MENU_ITEMS                 │
│   RAW_ORDERS     •  RAW_ORDER_ITEMS                                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Data Cleansing, Casting, Null Defaults
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    STAGING SCHEMA (ORDERPULSE_DB.STAGING)              │
│   STG_CUSTOMERS  •  STG_RESTAURANTS  •  STG_MENU_ITEMS                 │
│   STG_ORDERS     •  STG_ORDER_ITEMS                                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Star Schema Dimensional Modelling
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
│                        STREAMLIT WEB DASHBOARD                         │
│   Interactive Multi-Tab Dashboard (Executive, Priya, Daniel, Ops)      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📂 Project Structure

```
OrderPulse_Food_Order_Performance_Analytics/
├── data/                                 # Generated Relational CSV Datasets
│   ├── customers.csv                    # 1,500 Customer demographics
│   ├── restaurants.csv                  # 80 Restaurant partner profiles
│   ├── menu_items.csv                   # 612 Dishes across 9 cuisines
│   ├── orders.csv                       # 12,000 Food delivery orders
│   ├── order_items.csv                  # 32,921 Order basket line items
│   └── orderpulse_local.db              # Local SQLite analytical database
├── scripts/
│   └── generate_dataset.py              # Reproducible dataset generator script
├── sql/                                 # Complete Snowflake SQL Scripts
│   ├── 01_data_architecture_setup.sql   # Warehouse, DB, Schemas, Stage, Formats
│   ├── 02_data_ingestion_raw.sql        # RAW Tables, COPY INTO, Integrity checks
│   ├── 03_data_preparation_staging.sql  # Cleansing, Casting, Lineage, Flags
│   ├── 04_data_modelling_curated.sql    # Star Schema Facts, Dims & Persona Marts
│   ├── 05_business_analytics_kpis.sql   # KPI calculation & Visual dashboard queries
│   └── 06_performance_testing.sql       # Pruning tests, Storage & Query history audit
├── streamlit_app/                       # Interactive Streamlit Web Application
│   ├── app.py                           # Multi-tab dashboard application
│   ├── requirements.txt                 # Application python dependencies
│   └── .streamlit/
│       └── config.toml                  # Dark theme styling configuration
├── docs/                                # Project Documentation & Submission Assets
│   ├── PROJECT_REPORT.md                # Comprehensive 8-Epic capstone report
│   ├── ARCHITECTURE.md                  # Detailed data pipeline architecture & ERD
│   └── KANBAN_TASK_MAPPING.md           # 20-Task mapping for MySkillWallet portal
├── run_pipeline_local.py                # Local offline pipeline executor
└── README.md                            # Main project documentation
```

---

## 📈 Key Performance Indicators (KPIs)

Based on 12,000 orders spanning 7 major cities:

| Metric | Measured Value | Business Meaning |
|---|---|---|
| **Total Order Volume** | **12,000** | Full year operations across 7 metro cities. |
| **Gross Merchandise Value (GMV)** | **₹96,22,612.70** | Total order value placed by customers. |
| **Realized Delivered Revenue** | **₹89,37,747.85** | 92.88% of placed GMV successfully delivered. |
| **Lost Cancellation Value** | **₹6,84,864.85** | 7.12% value loss due to order cancellations. |
| **Average Order Value (AOV)** | **₹801.88** | High basket value driven by multi-item family meals. |
| **Repeat Customer Rate** | **69.8%** | 1,047 out of 1,500 active customers are repeat buyers. |
| **Single-Order Customer Rate** | **30.2%** | 453 customers placed only 1 order (retention priority). |
| **On-Time Delivery Rate** | **81.93%** | Delivered within 45-minute SLA benchmark. |
| **Late Delivery Rate** | **11.00%** | Exceeded 45 minutes (mostly peak dinner windows). |
| **Cancellation Rate** | **7.07%** | Low platform order attrition rate. |

---

## 🚀 Step-by-Step Setup & Execution

### Option A: Running on Snowflake Data Cloud
1. Log in to your Snowflake Account (`app.snowflake.com`).
2. Open a new SQL Worksheet and execute the SQL scripts sequentially:
   - Run `sql/01_data_architecture_setup.sql` to establish `ORDERPULSE_WH`, `ORDERPULSE_DB`, schemas, and stages.
   - Run `sql/02_data_ingestion_raw.sql` to create raw tables and stage data via `COPY INTO`.
   - Run `sql/03_data_preparation_staging.sql` to build the typed, cleansed staging tables.
   - Run `sql/04_data_modelling_curated.sql` to construct the Star Schema and Persona Views.
   - Run `sql/05_business_analytics_kpis.sql` to evaluate all KPI queries.
   - Run `sql/06_performance_testing.sql` to review partition pruning and query histories.

### Option B: Running Locally (1-Click Local Execution)
```bash
# 1. Clone repository
git clone https://github.com/your-username/OrderPulse-Food-Order-Analytics.git
cd OrderPulse-Food-Order-Analytics

# 2. Install dependencies
pip install -r streamlit_app/requirements.txt

# 3. (Optional) Re-generate fresh datasets
python scripts/generate_dataset.py

# 4. Run local ETL pipeline (loads into local SQLite database)
python run_pipeline_local.py

# 5. Launch interactive Streamlit Web Dashboard
streamlit run streamlit_app/app.py
```

The Streamlit dashboard will open in your browser at `http://localhost:8501`.

---

## 🖥️ Streamlit Interactive Web Application

The interactive web dashboard includes 5 comprehensive tabs:
1. **👑 Executive Overview (Grace):** Monthly GMV and revenue realization trends, GMV share donut chart, city-wise delivery reliability scorecard.
2. **🎯 Customer Engagement (Priya):** Repeat vs. Single-Order ratios, RFM loyalty distribution, basket size vs. spend elasticity curve, and automated retention recommendations.
3. **🍽️ Restaurant Partnerships (Daniel):** Demand by cuisine, empirical rating elasticity curve (orders per partner by rating tier), top 10 best-selling menu items.
4. **🚚 Delivery & Operations:** 24-hour demand curve (peak ordering windows), cancellation root-cause pie chart, delivery duration distribution histogram.
5. **⚡ Snowflake Architecture & Testing:** Pipeline data lineage diagram, storage volume audit, micro-partition pruning performance benchmarks, and query elapsed time comparisons.

---

## ⚡ Performance Testing & Auditing

1. **Amount of Data Loaded:** Verified 47,113 total records across `RAW`, `STAGING`, and `CURATED` layers.
2. **Filter Efficiency (Partition Pruning):**
   - *Baseline Full Scan:* 312 ms elapsed time.
   - *Date-Range Pruned Scan:* Pruned **91.7% of micro-partitions**, reducing execution time to **48 ms (6.5x speedup)**.
   - *Result Cache Hit:* Served instantly in **12 ms (26x speedup)**.
3. **Engineered Analytical Fields:** Audited **24+ newly derived features** across Staging and Curated layers (`loyalty_segment`, `rating_tier`, `basket_item_quantity`, `is_realized_flag`, etc.).
4. **Query History:** Evaluated query execution stats via `INFORMATION_SCHEMA.QUERY_HISTORY()`, confirming sub-100ms latency.

---

## 📋 Kanban Task Mapping & Submission

All **8 Epics and 20 Tasks** have been implemented:

- [x] **Epic 1: Problem Definition & Data Collection** (4 Tasks)
- [x] **Epic 2: Data Architecture Setup** (3 Tasks)
- [x] **Epic 3: Data Ingestion** (2 Tasks)
- [x] **Epic 4: Data Preparation & Modelling** (2 Tasks)
- [x] **Epic 5: Business Analytics** (2 Tasks)
- [x] **Epic 6: Streamlit Application Development** (1 Task)
- [x] **Epic 7: Performance Testing** (4 Tasks)
- [x] **Epic 8: Project Demonstration & Documentation** (2 Tasks)

*Refer to [docs/KANBAN_TASK_MAPPING.md](docs/KANBAN_TASK_MAPPING.md) for step-by-step instructions on updating the cards on MySkillWallet.ai and submitting your GitHub and Demo links!*

---

## 👤 Author
- **Name:** Arnaov Garg
- **Email:** ag5088@srmist.edu.in
- **Institution:** SRM Institute of Science and Technology (SRMIST)
- **Program:** Snowflake Data Engineering (SmartBridge / MySkillWallet.ai)
- **Role:** Data Engineer & System Architect


---

## 📜 License
This project is open-source and available under the [MIT License](LICENSE).

