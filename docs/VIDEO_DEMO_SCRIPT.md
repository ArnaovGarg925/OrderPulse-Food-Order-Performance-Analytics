# OrderPulse: Video Demonstration & Presentation Script
**Project:** OrderPulse: Food Order Performance Analytics  
**Presenter:** Arnaov Garg  
**Track:** Snowflake Data Engineering (SmartBridge / MySkillWallet.ai)  
**Estimated Video Duration:** 5 to 7 Minutes  

---

## 🎬 Section 1: Introduction & Problem Statement (0:00 - 1:00)
**[Show Slide 1 / GitHub Repository / Project Title Screen]**

> *"Hello everyone and welcome! My name is Arnaov Garg, and today I am excited to present my capstone project for the Snowflake Data Engineering track: **OrderPulse — Food Order Performance Analytics**.*

>
> *In today's fast-growing food delivery industry, platforms generate massive volumes of data every single day. However, this data is usually fragmented across disparate operational silos — customer profiles, restaurant menus, order baskets, and delivery logs. Business teams struggle to connect these dots, leading to conflicting metrics between departments, difficulty understanding customer retention, and anecdotal partner discussions.*
>
> *Our objective with OrderPulse is to build a centralized, single source of truth on the **Snowflake Cloud Data Warehouse** using the industry-standard **Medallion Architecture**, and visualize actionable insights through an interactive **Streamlit dashboard** for three core business personas: Priya in Customer Engagement, Daniel in Restaurant Partnerships, and Grace at the Executive level."*

---

## 🏗️ Section 2: Snowflake Architecture & Data Pipeline (1:00 - 2:15)
**[Show Architecture Diagram / Snowflake Worksheets / SQL Files]**

> *"Let me walk you through our data architecture. We implemented a robust three-tier Medallion Pipeline in Snowflake:*
>
> 1. *First is our **RAW Layer**: We created a dedicated virtual warehouse `ORDERPULSE_WH` and database `ORDERPULSE_DB`. We defined a custom CSV file format and internal stage `@ORDERPULSE_STAGE`, through which we ingested five core operational entities: customers, restaurants, menu items, orders, and order line items via bulk `COPY INTO` commands, totaling over 12,000 orders and 32,000 line items.*
> 2. *Second is our **STAGING Layer**: Here, raw strings are cleansed, trimmed, and cast into strict native types like `DATE`, `TIMESTAMP_NTZ`, and `DECIMAL`. We standardized casing, handled null values gracefully, and derived crucial operational flags like `is_realized`.*
> 3. *Third is our **CURATED Layer**: We built a high-performance Star Schema comprising five dimension tables — `DIM_CUSTOMERS` with RFM loyalty tiers, `DIM_RESTAURANTS` with rating tiers, `DIM_MENU_ITEMS`, `DIM_DATE`, and `DIM_TIME` with peak meal period slots — joined to our central `FACT_ORDERS` and `FACT_ORDER_ITEMS` tables using deterministic MD5 surrogate keys.*
>
> *On top of this Star Schema, we created dedicated analytical views tailored specifically to each business stakeholder."*

---

## 📊 Section 3: Interactive Streamlit Dashboard Walkthrough (2:15 - 4:45)
**[Switch screen to running Streamlit Application]**

> *"Now, let's look at the live **Streamlit Application** powered by our curated data mart.*
>
> *At the top, we have our platform KPI summary: Over **12,000 orders** placed generating **₹96.2 Lakhs in Gross Merchandise Value**, with **₹89.4 Lakhs in Realized Delivered Revenue**. We maintain an **81.9% on-time delivery rate**, an average basket size of **3.94 items**, and an Average Order Value of **₹802**.*
>
> *Let's look at our stakeholder tabs:*
>
> ### 1. Executive Overview (Grace)
> *Grace gets immediate executive clarity. Our monthly demand chart reveals revenue growth over the year, while the revenue realization donut chart clearly illustrates that 92.9% of placed GMV is successfully realized as delivered orders, while 7.1% is lost to cancellations. The city performance breakdown highlights Bengaluru and Mumbai as our top-performing markets with >83% on-time rates.*
>
> ### 2. Customer Engagement (Priya)
> *For Priya, we solve the challenge of customer segmentation. The dashboard reveals that **69.8% of our customers are repeat buyers**, while **30.2% are single-order buyers**. Our loyalty chart segments customers into Single-Order, Occasional, Frequent, and VIP tiers. Furthermore, our basket size curve demonstrates that basket spend escalates from ₹415 for single-item orders to over ₹1,340 for orders with 5+ items, providing Priya with empirical data to trigger cross-sell 'Add-on' promotions and targeted re-engagement campaigns.*
>
> ### 3. Restaurant Partnerships (Daniel)
> *Next, Daniel can conduct evidence-backed partner negotiations. The cuisine ranking shows North Indian, Biryani, and Chinese as the dominant volume and revenue drivers. Crucially, our rating elasticity chart provides definitive proof: restaurants rated 4.5 and above generate **over 28% more orders** than average-rated partners. Daniel can also monitor the top 10 best-selling items across the entire network.*
>
> ### 4. Delivery & Operations
> *Our operations tab tracks our 24-hour demand curve, showing massive peaks during Lunch (12-2 PM) and Dinner (7-10 PM). The cancellation root-cause analysis pinpoints 'Restaurant delay' and 'Delivery partner unavailability' as the primary drivers of lost orders, allowing operations to intervene during rush hours."*

---

## ⚡ Section 4: Performance Testing & Benchmarks (4:45 - 5:45)
**[Show Performance Testing Tab / Snowflake Query History]**

> *"In Epic 7, we performed rigorous performance testing on Snowflake:*
>
> 1. *First, **Data Load Verification**: Confirmed 47,000+ total rows loaded seamlessly across RAW, STAGING, and CURATED layers.*
> 2. *Second, **Filter Efficiency & Partition Pruning**: Comparing a full table scan against a date-filtered query demonstrated that Snowflake's metadata engine pruned **91.7% of micro-partitions**, accelerating query elapsed time from 312 milliseconds down to 48 milliseconds — a **6.5x performance gain**.*
> 3. *Third, **Feature Engineering Audit**: We validated 24 newly engineered derived columns, including surrogate keys, loyalty buckets, and delivery flags.*
> 4. *Finally, **Query History**: Checked via Snowflake's `INFORMATION_SCHEMA.QUERY_HISTORY`, showing an average execution latency under 100 milliseconds and zero compilation errors."*

---

## 🏆 Section 5: Conclusion & Wrap-Up (5:45 - 6:30)
**[Show Kanban Board / Project Summary / GitHub Repo]**

> *"In conclusion, **OrderPulse** successfully unifies fragmented operational food delivery records into a high-performance Snowflake cloud data warehouse, empowering decision-makers with real-time, trusted analytical insights.*
>
> *All 8 Epics and 20 Tasks have been completed on the MySkillWallet Kanban board, with full documentation, SQL scripts, and datasets organized in our GitHub repository.*
>
> *Thank you to our mentors at SmartBridge for their continuous guidance throughout this program. Thank you for watching!"*
