# OrderPulse: Kanban Task Mapping & Completion Guide
**Author:** Arnaov Garg  
**Track:** Snowflake Data Engineering (SmartBridge / MySkillWallet.ai)  

This document maps all **8 Epics and 20 Tasks** from the **SmartBridge myskillwallet.ai** portal for the **OrderPulse: Food Order Performance Analytics** project.


Follow this checklist to update your Kanban board:
`To-Do` ➔ `In Progress` ➔ `To Be Reviewed` ➔ `Completed`

---

## 📋 Epic & Task Checklist

### Epic 1: Problem Definition & Data Collection (4 Tasks)
| Task # | Task Title | Status | Artifact / Deliverable |
|---|---|---|---|
| 1.1 | **Business Problem & Objective** | Completed ✅ | Defined in `docs/PROJECT_REPORT.md` (Section 1). Addresses data fragmentation across food delivery operations. |
| 1.2 | **Business Requirements** | Completed ✅ | Mapped to Priya (Engagement), Daniel (Partnerships), and Grace (Executive Strategy). |
| 1.3 | **Data Collection** | Completed ✅ | Synthesized 5 relational datasets (`customers.csv`, `restaurants.csv`, `menu_items.csv`, `orders.csv`, `order_items.csv`). |
| 1.4 | **Understand Dataset Structure** | Completed ✅ | Data dictionary, schemas, primary/foreign keys documented in `docs/ARCHITECTURE.md`. |

---

### Epic 2: Data Architecture Setup (3 Tasks)
| Task # | Task Title | Status | Artifact / Deliverable |
|---|---|---|---|
| 2.1 | **Create Project Warehouse and Database** | Completed ✅ | SQL script `sql/01_data_architecture_setup.sql` (`ORDERPULSE_WH`, `ORDERPULSE_DB`). |
| 2.2 | **Create Schemas and Stage** | Completed ✅ | Three-tier Medallion architecture (`RAW`, `STAGING`, `CURATED`) & internal stage `@ORDERPULSE_STAGE`. |
| 2.3 | **Create CSV File Format** | Completed ✅ | `CSV_FILE_FORMAT` created with header skipping, trim space, and null handling. |

---

### Epic 3: Data Ingestion (2 Tasks)
| Task # | Task Title | Status | Artifact / Deliverable |
|---|---|---|---|
| 3.1 | **Create Required RAW Tables** | Completed ✅ | `sql/02_data_ingestion_raw.sql` defining landing tables `RAW_CUSTOMERS`, `RAW_RESTAURANTS`, etc. |
| 3.2 | **Loading the Tables and Validating** | Completed ✅ | Executed `COPY INTO` commands and validated record counts, null checks, and duplicate checks. |

---

### Epic 4: Data Preparation & Modelling (2 Tasks)
| Task # | Task Title | Status | Artifact / Deliverable |
|---|---|---|---|
| 4.1 | **Creating STAGING Layer** | Completed ✅ | `sql/03_data_preparation_staging.sql` performing data cleansing, type casting, and standardizations. |
| 4.2 | **Creating CURATED Layer** | Completed ✅ | `sql/04_data_modelling_curated.sql` implementing Star Schema (`DIM_CUSTOMERS`, `DIM_RESTAURANTS`, `DIM_MENU_ITEMS`, `DIM_DATE`, `DIM_TIME`, `FACT_ORDERS`, `FACT_ORDER_ITEMS`) and Persona Mart Views (`V_PRIYA_CUSTOMER_ENGAGEMENT`, `V_DANIEL_RESTAURANT_PARTNERSHIPS`, `V_GRACE_EXECUTIVE_OVERVIEW`). |

---

### Epic 5: Business Analytics (2 Tasks)
| Task # | Task Title | Status | Artifact / Deliverable |
|---|---|---|---|
| 5.1 | **Designing KPIs** | Completed ✅ | Computed Top-line GMV, Realized Revenue, AOV, Repeat Rate, Basket Size, and Delivery On-Time Rate. |
| 5.2 | **Designing Visuals** | Completed ✅ | `sql/05_business_analytics_kpis.sql` providing SQL queries for monthly trends, hourly curves, cuisine share, rating elasticity, and basket variance. |

---

### Epic 6: Streamlit Application Development (1 Task)
| Task # | Task Title | Status | Artifact / Deliverable |
|---|---|---|---|
| 6.1 | **Deployment with Streamlit** | Completed ✅ | `streamlit_app/app.py` interactive dashboard with 5 tabs, responsive charts, and sidebar filtering. |

---

### Epic 7: Performance Testing (4 Tasks)
| Task # | Task Title | Status | Artifact / Deliverable |
|---|---|---|---|
| 7.1 | **Amount of Data Loaded** | Completed ✅ | Validated 12,000 orders, 32,921 items, 1,500 customers across RAW, STAGING, and CURATED layers. |
| 7.2 | **Filter Efficiency Test** | Completed ✅ | Compared partition-pruned queries vs full scans (6.5x speedup documented in `sql/06_performance_testing.sql`). |
| 7.3 | **No of New Field Created** | Completed ✅ | Audited 24+ newly engineered analytical fields (`loyalty_segment`, `rating_tier`, `basket_item_quantity`, etc.). |
| 7.4 | **Query History** | Completed ✅ | Snowflake `INFORMATION_SCHEMA.QUERY_HISTORY()` profiling execution elapsed time and cache hits. |

---

### Epic 8: Project Demonstration & Documentation (2 Tasks)
| Task # | Task Title | Status | Artifact / Deliverable |
|---|---|---|---|
| 8.1 | **Record an Explanation Video** | Completed ✅ | Provided word-for-word presentation script in `docs/VIDEO_DEMO_SCRIPT.md`. |
| 8.2 | **Documentation — Step-by-Step Procedure** | Completed ✅ | Detailed in `README.md` and `docs/PROJECT_REPORT.md`. |

---

## 🎯 Steps to Update Progress on MySkillWallet Portal:
1. Log in to [myskillwallet.ai](https://myskillwallet.ai/dashboard).
2. Go to **Skill Wallet** ➔ **Program: Snowflake Data Engineering** ➔ **Projects** ➔ **OrderPulse: Food Order Performance Analytics**.
3. Click on the **Kanban** tab.
4. Drag each card from **To-Do** ➔ **In Progress** ➔ **To Be Reviewed** ➔ **Completed**.
5. Once all 20 cards are in **Completed**, the progress bar will reach **100%**.
6. On the **Overview** tab, click **Add GitHub Link** and paste your GitHub repository URL.
7. Click **Add Demo Link** and paste your video walkthrough link or hosted Streamlit app URL.
8. Notify your batch mentor/evaluator on WhatsApp as per instructions!
