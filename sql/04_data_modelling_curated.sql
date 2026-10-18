-- ============================================================================
-- OrderPulse: Food Order Performance Analytics
-- Epic 4: Data Preparation & Modelling (Part 2: CURATED Layer)
-- ----------------------------------------------------------------------------
-- Tasks Covered:
-- 2. Creating CURATED layer
--    - Star Schema Dimensional Modelling (Facts and Dimensions)
--    - Customer RFM / Loyalty Segmentation
--    - Restaurant Rating Tiers and Cuisine Performance
--    - Time and Date Dimensions with Peak Meal Slots
--    - Specific Analytical Mart Views for Priya, Daniel, and Grace
-- ============================================================================

USE WAREHOUSE ORDERPULSE_WH;
USE DATABASE ORDERPULSE_DB;
USE SCHEMA ORDERPULSE_DB.CURATED;

-- ----------------------------------------------------------------------------
-- 1. DIM_DATE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_DATE AS
WITH date_spine AS (
    SELECT DATEADD(DAY, SEQ4(), '2023-01-01'::DATE) AS full_date
    FROM TABLE(GENERATOR(ROWCOUNT => 731)) -- Covers 2023 and 2024
)
SELECT
    TO_NUMBER(TO_CHAR(full_date, 'YYYYMMDD')) AS date_key,
    full_date,
    DATE_PART('YEAR', full_date)               AS year,
    DATE_PART('QUARTER', full_date)            AS quarter,
    DATE_PART('MONTH', full_date)              AS month,
    MONTHNAME(full_date)                       AS month_name,
    DATE_PART('DAY', full_date)                AS day,
    DAYOFWEEK(full_date)                       AS day_of_week,
    DAYNAME(full_date)                         AS day_name,
    CASE WHEN DAYOFWEEK(full_date) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend
FROM date_spine;

-- ----------------------------------------------------------------------------
-- 2. DIM_TIME (Peak Meal Periods)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_TIME AS
WITH hours AS (
    SELECT SEQ4() AS hour_24
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
)
SELECT
    hour_24 AS time_key,
    hour_24,
    LPAD(hour_24::VARCHAR, 2, '0') || ':00' AS time_label,
    CASE 
        WHEN hour_24 BETWEEN 7 AND 10  THEN 'Breakfast (7 AM - 11 AM)'
        WHEN hour_24 BETWEEN 11 AND 15 THEN 'Lunch Peak (11 AM - 4 PM)'
        WHEN hour_24 BETWEEN 16 AND 18 THEN 'Snacks (4 PM - 7 PM)'
        WHEN hour_24 BETWEEN 19 AND 22 THEN 'Dinner Peak (7 PM - 11 PM)'
        ELSE 'Late Night (11 PM - 7 AM)'
    END AS meal_period,
    CASE 
        WHEN hour_24 IN (12, 13, 14, 20, 21) THEN TRUE
        ELSE FALSE
    END AS is_peak_hour
FROM hours;

-- ----------------------------------------------------------------------------
-- 3. DIM_CUSTOMERS (with Loyalty & Frequency Segmentation for Priya)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_CUSTOMERS AS
WITH cust_metrics AS (
    SELECT
        customer_id,
        COUNT(order_id)                                  AS total_orders,
        COUNT_IF(is_realized = TRUE)                     AS realized_orders,
        COALESCE(SUM(CASE WHEN is_realized = TRUE THEN total_amount ELSE 0 END), 0.00) AS total_spend,
        COALESCE(AVG(CASE WHEN is_realized = TRUE THEN total_amount END), 0.00)        AS avg_order_value,
        MIN(order_date)                                  AS first_order_date,
        MAX(order_date)                                  AS last_order_date
    FROM ORDERPULSE_DB.STAGING.STG_ORDERS
    GROUP BY customer_id
)
SELECT
    MD5(c.customer_id)                                 AS customer_key,
    c.customer_id,
    c.customer_name,
    c.email,
    c.phone,
    c.city,
    c.age,
    CASE 
        WHEN c.age < 25 THEN '18-24 (Gen Z)'
        WHEN c.age BETWEEN 25 AND 34 THEN '25-34 (Young Professionals)'
        WHEN c.age BETWEEN 35 AND 49 THEN '35-49 (Family Segment)'
        ELSE '50+ (Seniors)'
    END                                                AS age_group,
    c.signup_date,
    COALESCE(m.total_orders, 0)                        AS lifetime_orders,
    COALESCE(m.realized_orders, 0)                     AS realized_orders,
    COALESCE(m.total_spend, 0.00)                      AS lifetime_spend,
    ROUND(COALESCE(m.avg_order_value, 0.00), 2)        AS customer_aov,
    m.first_order_date,
    m.last_order_date,
    -- Priya's Requirement: Segmentation by ordering frequency
    CASE 
        WHEN COALESCE(m.total_orders, 0) = 0 THEN 'Inactive / No Orders'
        WHEN COALESCE(m.total_orders, 0) = 1 THEN 'Single-Order Customer'
        WHEN COALESCE(m.total_orders, 0) BETWEEN 2 AND 4 THEN 'Occasional Buyer (2-4)'
        WHEN COALESCE(m.total_orders, 0) BETWEEN 5 AND 9 THEN 'Frequent Buyer (5-9)'
        ELSE 'Loyal / VIP Customer (10+)'
    END                                                AS loyalty_segment,
    CASE 
        WHEN COALESCE(m.total_orders, 0) > 1 THEN TRUE 
        ELSE FALSE 
    END                                                AS is_repeat_customer
FROM ORDERPULSE_DB.STAGING.STG_CUSTOMERS c
LEFT JOIN cust_metrics m ON c.customer_id = m.customer_id;

-- ----------------------------------------------------------------------------
-- 4. DIM_RESTAURANTS (with Rating Tiers for Daniel)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_RESTAURANTS AS
SELECT
    MD5(r.restaurant_id)                               AS restaurant_key,
    r.restaurant_id,
    r.restaurant_name,
    r.cuisine,
    r.city,
    r.rating,
    -- Daniel's Requirement: Rating impact tier
    CASE 
        WHEN r.rating >= 4.5 THEN 'Top Rated (4.5 - 5.0)'
        WHEN r.rating >= 4.0 THEN 'High Rated (4.0 - 4.4)'
        WHEN r.rating >= 3.5 THEN 'Average Rated (3.5 - 3.9)'
        ELSE 'Low Rated (< 3.5)'
    END                                                AS rating_tier,
    r.cost_for_two,
    CASE 
        WHEN r.cost_for_two <= 350 THEN 'Budget Friendly'
        WHEN r.cost_for_two <= 700 THEN 'Mid-Range'
        ELSE 'Premium Dining'
    END                                                AS cost_tier,
    r.is_active
FROM ORDERPULSE_DB.STAGING.STG_RESTAURANTS r;

-- ----------------------------------------------------------------------------
-- 5. DIM_MENU_ITEMS (Category & Pricing Tiers)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_MENU_ITEMS AS
SELECT
    MD5(m.item_id)                                     AS item_key,
    m.item_id,
    m.restaurant_id,
    m.item_name,
    m.category,
    m.is_veg,
    CASE WHEN m.is_veg THEN 'Vegetarian' ELSE 'Non-Vegetarian' END AS veg_flag_label,
    m.price,
    CASE 
        WHEN m.price < 100 THEN 'Economy (< ₹100)'
        WHEN m.price <= 250 THEN 'Standard (₹100 - ₹250)'
        WHEN m.price <= 400 THEN 'Premium (₹250 - ₹400)'
        ELSE 'Luxury (> ₹400)'
    END                                                AS price_tier
FROM ORDERPULSE_DB.STAGING.STG_MENU_ITEMS m;

-- ----------------------------------------------------------------------------
-- 6. FACT_ORDERS (Core Order Analytics Fact)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_ORDERS AS
WITH basket_summary AS (
    SELECT 
        order_id,
        COUNT(order_item_id) AS distinct_items_count,
        SUM(quantity)        AS total_quantity
    FROM ORDERPULSE_DB.STAGING.STG_ORDER_ITEMS
    GROUP BY order_id
)
SELECT
    MD5(o.order_id)                                    AS order_key,
    o.order_id,
    MD5(o.customer_id)                                 AS customer_key,
    o.customer_id,
    MD5(o.restaurant_id)                               AS restaurant_key,
    o.restaurant_id,
    TO_NUMBER(TO_CHAR(o.order_date, 'YYYYMMDD'))       AS date_key,
    o.order_hour                                       AS time_key,
    o.order_datetime,
    o.order_date,
    o.order_hour,
    COALESCE(b.distinct_items_count, 1)                AS distinct_items_count,
    COALESCE(b.total_quantity, 1)                      AS basket_item_quantity,
    o.subtotal,
    o.discount_amount,
    o.delivery_fee,
    o.tax_amount,
    o.total_amount                                     AS gross_order_value,
    -- Realized revenue: 0 if cancelled
    CASE WHEN o.is_realized THEN o.total_amount ELSE 0.00 END AS realized_revenue,
    o.payment_mode,
    o.order_status,
    o.delivery_time_minutes,
    o.cancellation_reason,
    -- Outcome flags
    CASE WHEN o.order_status = 'Delivered' THEN 1 ELSE 0 END        AS is_delivered,
    CASE WHEN o.order_status = 'Delivered Late' THEN 1 ELSE 0 END   AS is_delivered_late,
    CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END        AS is_cancelled,
    CASE WHEN o.is_realized THEN 1 ELSE 0 END                       AS is_realized_flag
FROM ORDERPULSE_DB.STAGING.STG_ORDERS o
LEFT JOIN basket_summary b ON o.order_id = b.order_id;

-- ----------------------------------------------------------------------------
-- 7. FACT_ORDER_ITEMS (Line Item Basket Fact)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_ORDER_ITEMS AS
SELECT
    MD5(oi.order_item_id)                              AS order_item_key,
    oi.order_item_id,
    MD5(oi.order_id)                                   AS order_key,
    oi.order_id,
    MD5(oi.item_id)                                    AS item_key,
    oi.item_id,
    oi.quantity,
    oi.unit_price,
    oi.item_subtotal
FROM ORDERPULSE_DB.STAGING.STG_ORDER_ITEMS oi;

-- ============================================================================
-- 8. CURATED BUSINESS MART VIEWS (PERSONA-SPECIFIC)
-- ============================================================================

-- Persona 1: Priya — Customer Engagement & Loyalty View
CREATE OR REPLACE VIEW V_PRIYA_CUSTOMER_ENGAGEMENT AS
SELECT
    c.loyalty_segment,
    COUNT(c.customer_id)                                            AS total_customers,
    ROUND(COUNT(c.customer_id) * 100.0 / SUM(COUNT(c.customer_id)) OVER(), 2) AS customer_share_pct,
    SUM(c.lifetime_orders)                                          AS total_orders_placed,
    SUM(c.lifetime_spend)                                           AS total_revenue_generated,
    ROUND(AVG(c.customer_aov), 2)                                   AS avg_customer_order_value,
    ROUND(AVG(c.lifetime_orders), 2)                                AS avg_orders_per_customer
FROM DIM_CUSTOMERS c
GROUP BY c.loyalty_segment;

-- Persona 2: Daniel — Restaurant Partnerships & Menu Performance View
CREATE OR REPLACE VIEW V_DANIEL_RESTAURANT_PARTNERSHIPS AS
SELECT
    r.cuisine,
    r.rating_tier,
    COUNT(DISTINCT r.restaurant_id)                                 AS active_restaurant_count,
    COUNT(f.order_id)                                              AS total_orders,
    ROUND(SUM(f.realized_revenue), 2)                               AS realized_revenue,
    ROUND(AVG(f.gross_order_value), 2)                              AS avg_order_value,
    ROUND(AVG(r.rating), 2)                                         AS avg_rating
FROM DIM_RESTAURANTS r
LEFT JOIN FACT_ORDERS f ON r.restaurant_key = f.restaurant_key
GROUP BY r.cuisine, r.rating_tier;

-- Persona 3: Grace — Executive Business Demand & Reliability View
CREATE OR REPLACE VIEW V_GRACE_EXECUTIVE_OVERVIEW AS
SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(f.order_id)                                               AS total_order_volume,
    COUNT_IF(f.is_delivered = 1)                                   AS on_time_delivered_orders,
    COUNT_IF(f.is_delivered_late = 1)                              AS late_delivered_orders,
    COUNT_IF(f.is_cancelled = 1)                                    AS cancelled_orders,
    ROUND(COUNT_IF(f.is_delivered = 1) * 100.0 / COUNT(f.order_id), 2)      AS on_time_rate_pct,
    ROUND(COUNT_IF(f.is_delivered_late = 1) * 100.0 / COUNT(f.order_id), 2) AS late_rate_pct,
    ROUND(COUNT_IF(f.is_cancelled = 1) * 100.0 / COUNT(f.order_id), 2)      AS cancellation_rate_pct,
    ROUND(SUM(f.gross_order_value), 2)                              AS gross_merchandise_value,
    ROUND(SUM(f.realized_revenue), 2)                               AS realized_delivered_value,
    ROUND(SUM(f.gross_order_value) - SUM(f.realized_revenue), 2)    AS lost_cancellation_value,
    ROUND(AVG(f.gross_order_value), 2)                              AS average_order_value
FROM FACT_ORDERS f
JOIN DIM_DATE d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;
