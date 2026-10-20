-- ============================================================================
-- OrderPulse: Food Order Performance Analytics
-- Epic 5: Business Analytics
-- ----------------------------------------------------------------------------
-- Tasks Covered:
-- 1. Designing KPIs (Executive, Engagement, Restaurant, Delivery)
-- 2. Designing Visuals (Data queries powering BI dashboards & charts)
-- ============================================================================

USE WAREHOUSE ORDERPULSE_WH;
USE DATABASE ORDERPULSE_DB;
USE SCHEMA ORDERPULSE_DB.CURATED;

-- ============================================================================
-- SECTION 1: CORE PLATFORM KPIS
-- ============================================================================

-- KPI Summary Query
SELECT
    COUNT(f.order_id)                                                       AS total_orders,
    ROUND(SUM(f.gross_order_value), 2)                                      AS gross_order_value_gmv,
    ROUND(SUM(f.realized_revenue), 2)                                       AS realized_revenue,
    ROUND(SUM(f.gross_order_value) - SUM(f.realized_revenue), 2)            AS lost_revenue_cancellations,
    ROUND(AVG(f.gross_order_value), 2)                                      AS overall_aov,
    ROUND(AVG(f.basket_item_quantity), 2)                                   AS avg_basket_size_items,
    ROUND(COUNT_IF(f.is_delivered = 1) * 100.0 / COUNT(f.order_id), 2)      AS on_time_delivery_rate_pct,
    ROUND(COUNT_IF(f.is_delivered_late = 1) * 100.0 / COUNT(f.order_id), 2) AS late_delivery_rate_pct,
    ROUND(COUNT_IF(f.is_cancelled = 1) * 100.0 / COUNT(f.order_id), 2)      AS cancellation_rate_pct,
    ROUND(AVG(CASE WHEN f.is_delivered_late = 1 OR f.is_delivered = 1 THEN f.delivery_time_minutes END), 1) AS avg_delivery_time_mins
FROM FACT_ORDERS f;

-- Customer Engagement KPIs (Priya)
SELECT
    COUNT(customer_id)                                                      AS total_registered_customers,
    COUNT_IF(lifetime_orders > 0)                                           AS active_ordering_customers,
    COUNT_IF(is_repeat_customer = TRUE)                                     AS repeat_customers_count,
    ROUND(COUNT_IF(is_repeat_customer = TRUE) * 100.0 / COUNT_IF(lifetime_orders > 0), 2) AS repeat_customer_rate_pct,
    COUNT_IF(loyalty_segment = 'Single-Order Customer')                     AS single_order_customers_count,
    ROUND(COUNT_IF(loyalty_segment = 'Single-Order Customer') * 100.0 / COUNT_IF(lifetime_orders > 0), 2) AS single_order_rate_pct,
    ROUND(AVG(lifetime_orders), 2)                                          AS avg_orders_per_customer
FROM DIM_CUSTOMERS;

-- ============================================================================
-- SECTION 2: QUERIES FOR VISUALIZATIONS & CHARTS
-- ============================================================================

-- Visual 1: Monthly Demand & Revenue Trend (Grace - Executive Overview)
SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(f.order_id)                               AS monthly_orders,
    ROUND(SUM(f.gross_order_value), 2)              AS gross_sales,
    ROUND(SUM(f.realized_revenue), 2)               AS realized_sales,
    ROUND(AVG(f.gross_order_value), 2)              AS monthly_aov
FROM FACT_ORDERS f
JOIN DIM_DATE d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- Visual 2: Hourly Demand & Peak Meal Period Heatmap (Grace & Operations)
SELECT
    t.hour_24,
    t.time_label,
    t.meal_period,
    COUNT(f.order_id)                               AS order_count,
    ROUND(SUM(f.gross_order_value), 2)              AS total_sales,
    ROUND(AVG(f.delivery_time_minutes), 1)          AS avg_delivery_time
FROM FACT_ORDERS f
JOIN DIM_TIME t ON f.time_key = t.time_key
GROUP BY t.hour_24, t.time_label, t.meal_period
ORDER BY t.hour_24;

-- Visual 3: Customer Loyalty Segmentation Breakdown (Priya - Customer Engagement)
SELECT
    c.loyalty_segment,
    COUNT(c.customer_id)                            AS customer_count,
    ROUND(COUNT(c.customer_id) * 100.0 / SUM(COUNT(c.customer_id)) OVER(), 2) AS customer_share_pct,
    SUM(c.lifetime_orders)                          AS total_orders,
    ROUND(SUM(c.lifetime_spend), 2)                 AS total_spend,
    ROUND(AVG(c.customer_aov), 2)                   AS avg_order_value
FROM DIM_CUSTOMERS c
GROUP BY c.loyalty_segment
ORDER BY total_orders DESC;

-- Visual 4: Basket Size Distribution & Spending Patterns (Priya - Customer Engagement)
SELECT
    f.basket_item_quantity                          AS items_in_basket,
    COUNT(f.order_id)                               AS total_orders,
    ROUND(COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER(), 2) AS order_pct,
    ROUND(AVG(f.gross_order_value), 2)              AS avg_basket_spend,
    ROUND(SUM(f.gross_order_value), 2)              AS total_basket_gmv
FROM FACT_ORDERS f
GROUP BY f.basket_item_quantity
ORDER BY f.basket_item_quantity;

-- Visual 5: Cuisine Popularity & Revenue Contribution (Daniel - Restaurant Partnerships)
SELECT
    r.cuisine,
    COUNT(DISTINCT r.restaurant_id)                 AS total_restaurants,
    COUNT(f.order_id)                               AS total_orders,
    ROUND(SUM(f.realized_revenue), 2)               AS realized_revenue,
    ROUND(AVG(f.gross_order_value), 2)              AS avg_order_value,
    ROUND(COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER(), 2) AS order_share_pct
FROM FACT_ORDERS f
JOIN DIM_RESTAURANTS r ON f.restaurant_key = r.restaurant_key
GROUP BY r.cuisine
ORDER BY total_orders DESC;

-- Visual 6: Restaurant Rating Influence on Order Demand (Daniel - Restaurant Partnerships)
SELECT
    r.rating_tier,
    COUNT(DISTINCT r.restaurant_id)                 AS restaurants_in_tier,
    COUNT(f.order_id)                               AS total_orders,
    ROUND(COUNT(f.order_id) * 1.0 / COUNT(DISTINCT r.restaurant_id), 1) AS orders_per_restaurant,
    ROUND(SUM(f.realized_revenue), 2)               AS total_revenue,
    ROUND(AVG(f.gross_order_value), 2)              AS avg_order_value
FROM FACT_ORDERS f
JOIN DIM_RESTAURANTS r ON f.restaurant_key = r.restaurant_key
GROUP BY r.rating_tier
ORDER BY total_orders DESC;

-- Visual 7: Top 10 Best-Selling Menu Items (Daniel - Menu Optimization)
SELECT
    m.item_name,
    m.category,
    m.veg_flag_label,
    m.price_tier,
    SUM(foi.quantity)                               AS total_units_sold,
    ROUND(SUM(foi.item_subtotal), 2)                AS total_item_revenue,
    COUNT(DISTINCT foi.order_id)                    AS orders_containing_item
FROM FACT_ORDER_ITEMS foi
JOIN DIM_MENU_ITEMS m ON foi.item_key = m.item_key
GROUP BY m.item_name, m.category, m.veg_flag_label, m.price_tier
ORDER BY total_units_sold DESC
LIMIT 10;

-- Visual 8: City-wise Order Volume & Delivery Reliability (Grace - Executive Overview)
SELECT
    c.city,
    COUNT(f.order_id)                               AS total_orders,
    ROUND(SUM(f.realized_revenue), 2)               AS total_realized_revenue,
    ROUND(COUNT_IF(f.is_delivered = 1) * 100.0 / COUNT(f.order_id), 2)      AS on_time_rate_pct,
    ROUND(COUNT_IF(f.is_delivered_late = 1) * 100.0 / COUNT(f.order_id), 2) AS late_rate_pct,
    ROUND(COUNT_IF(f.is_cancelled = 1) * 100.0 / COUNT(f.order_id), 2)      AS cancellation_rate_pct,
    ROUND(AVG(CASE WHEN f.is_delivered = 1 OR f.is_delivered_late = 1 THEN f.delivery_time_minutes END), 1) AS avg_delivery_minutes
FROM FACT_ORDERS f
JOIN DIM_CUSTOMERS c ON f.customer_key = c.customer_key
GROUP BY c.city
ORDER BY total_orders DESC;

-- Visual 9: Cancellation Reasons Breakdown (Grace & Operations)
SELECT
    COALESCE(f.cancellation_reason, 'Unspecified')  AS cancellation_reason,
    COUNT(f.order_id)                               AS cancelled_orders_count,
    ROUND(SUM(f.gross_order_value), 2)              AS lost_order_value,
    ROUND(COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER(), 2) AS pct_of_cancellations
FROM FACT_ORDERS f
WHERE f.is_cancelled = 1
GROUP BY f.cancellation_reason
ORDER BY cancelled_orders_count DESC;
