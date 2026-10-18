"""
OrderPulse: Local Pipeline Runner (SQLite / Python Standard Library)
Allows local testing and offline verification of the OrderPulse data pipeline.
Executes data ingestion, transformations, dimension/fact creation, and KPI calculations.
"""

import sqlite3
import csv
import os
import hashlib

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
DB_PATH = os.path.join(BASE_DIR, "data", "orderpulse_local.db")

def get_connection():
    return sqlite3.connect(DB_PATH)

def md5(val):
    if val is None:
        return None
    return hashlib.md5(str(val).encode('utf-8')).hexdigest()

def setup_local_pipeline():
    conn = get_connection()
    conn.create_function("MD5", 1, md5)
    cursor = conn.cursor()
    
    print("=== Step 1: Loading RAW Tables ===")
    
    # 1. RAW_CUSTOMERS
    cursor.execute("DROP TABLE IF EXISTS RAW_CUSTOMERS;")
    cursor.execute("""
        CREATE TABLE RAW_CUSTOMERS (
            customer_id TEXT, customer_name TEXT, email TEXT, phone TEXT,
            city TEXT, age TEXT, signup_date TEXT
        );
    """)
    with open(os.path.join(DATA_DIR, "customers.csv"), 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        cursor.executemany("""
            INSERT INTO RAW_CUSTOMERS VALUES (:customer_id, :customer_name, :email, :phone, :city, :age, :signup_date)
        """, list(reader))
        
    # 2. RAW_RESTAURANTS
    cursor.execute("DROP TABLE IF EXISTS RAW_RESTAURANTS;")
    cursor.execute("""
        CREATE TABLE RAW_RESTAURANTS (
            restaurant_id TEXT, restaurant_name TEXT, cuisine TEXT, city TEXT,
            rating TEXT, cost_for_two TEXT, is_active TEXT
        );
    """)
    with open(os.path.join(DATA_DIR, "restaurants.csv"), 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        cursor.executemany("""
            INSERT INTO RAW_RESTAURANTS VALUES (:restaurant_id, :restaurant_name, :cuisine, :city, :rating, :cost_for_two, :is_active)
        """, list(reader))

    # 3. RAW_MENU_ITEMS
    cursor.execute("DROP TABLE IF EXISTS RAW_MENU_ITEMS;")
    cursor.execute("""
        CREATE TABLE RAW_MENU_ITEMS (
            item_id TEXT, restaurant_id TEXT, item_name TEXT, category TEXT,
            is_veg TEXT, price TEXT
        );
    """)
    with open(os.path.join(DATA_DIR, "menu_items.csv"), 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        cursor.executemany("""
            INSERT INTO RAW_MENU_ITEMS VALUES (:item_id, :restaurant_id, :item_name, :category, :is_veg, :price)
        """, list(reader))

    # 4. RAW_ORDERS
    cursor.execute("DROP TABLE IF EXISTS RAW_ORDERS;")
    cursor.execute("""
        CREATE TABLE RAW_ORDERS (
            order_id TEXT, customer_id TEXT, restaurant_id TEXT, order_datetime TEXT,
            subtotal TEXT, discount_amount TEXT, delivery_fee TEXT, tax_amount TEXT,
            total_amount TEXT, payment_mode TEXT, order_status TEXT,
            delivery_time_minutes TEXT, cancellation_reason TEXT
        );
    """)
    with open(os.path.join(DATA_DIR, "orders.csv"), 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        cursor.executemany("""
            INSERT INTO RAW_ORDERS VALUES (:order_id, :customer_id, :restaurant_id, :order_datetime,
            :subtotal, :discount_amount, :delivery_fee, :tax_amount, :total_amount,
            :payment_mode, :order_status, :delivery_time_minutes, :cancellation_reason)
        """, list(reader))

    # 5. RAW_ORDER_ITEMS
    cursor.execute("DROP TABLE IF EXISTS RAW_ORDER_ITEMS;")
    cursor.execute("""
        CREATE TABLE RAW_ORDER_ITEMS (
            order_item_id TEXT, order_id TEXT, item_id TEXT,
            quantity TEXT, unit_price TEXT, item_subtotal TEXT
        );
    """)
    with open(os.path.join(DATA_DIR, "order_items.csv"), 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        cursor.executemany("""
            INSERT INTO RAW_ORDER_ITEMS VALUES (:order_item_id, :order_id, :item_id, :quantity, :unit_price, :item_subtotal)
        """, list(reader))
        
    print("Raw tables loaded successfully.")
    
    print("=== Step 2: Creating STAGING Layer ===")
    cursor.execute("DROP TABLE IF EXISTS STG_CUSTOMERS;")
    cursor.execute("""
        CREATE TABLE STG_CUSTOMERS AS
        SELECT
            TRIM(customer_id) AS customer_id,
            TRIM(customer_name) AS customer_name,
            LOWER(TRIM(email)) AS email,
            TRIM(phone) AS phone,
            TRIM(city) AS city,
            CAST(age AS INTEGER) AS age,
            signup_date,
            CURRENT_TIMESTAMP AS stg_loaded_at
        FROM RAW_CUSTOMERS;
    """)

    cursor.execute("DROP TABLE IF EXISTS STG_RESTAURANTS;")
    cursor.execute("""
        CREATE TABLE STG_RESTAURANTS AS
        SELECT
            TRIM(restaurant_id) AS restaurant_id,
            TRIM(restaurant_name) AS restaurant_name,
            TRIM(cuisine) AS cuisine,
            TRIM(city) AS city,
            CAST(rating AS REAL) AS rating,
            CAST(cost_for_two AS INTEGER) AS cost_for_two,
            CASE WHEN LOWER(is_active) IN ('true', '1') THEN 1 ELSE 0 END AS is_active,
            CURRENT_TIMESTAMP AS stg_loaded_at
        FROM RAW_RESTAURANTS;
    """)

    cursor.execute("DROP TABLE IF EXISTS STG_MENU_ITEMS;")
    cursor.execute("""
        CREATE TABLE STG_MENU_ITEMS AS
        SELECT
            TRIM(item_id) AS item_id,
            TRIM(restaurant_id) AS restaurant_id,
            TRIM(item_name) AS item_name,
            TRIM(category) AS category,
            CASE WHEN LOWER(is_veg) IN ('true', '1') THEN 1 ELSE 0 END AS is_veg,
            CAST(price AS REAL) AS price,
            CURRENT_TIMESTAMP AS stg_loaded_at
        FROM RAW_MENU_ITEMS;
    """)

    cursor.execute("DROP TABLE IF EXISTS STG_ORDERS;")
    cursor.execute("""
        CREATE TABLE STG_ORDERS AS
        SELECT
            TRIM(order_id) AS order_id,
            TRIM(customer_id) AS customer_id,
            TRIM(restaurant_id) AS restaurant_id,
            order_datetime,
            SUBSTR(order_datetime, 1, 10) AS order_date,
            CAST(SUBSTR(order_datetime, 12, 2) AS INTEGER) AS order_hour,
            CAST(subtotal AS REAL) AS subtotal,
            CAST(discount_amount AS REAL) AS discount_amount,
            CAST(delivery_fee AS REAL) AS delivery_fee,
            CAST(tax_amount AS REAL) AS tax_amount,
            CAST(total_amount AS REAL) AS total_amount,
            TRIM(payment_mode) AS payment_mode,
            TRIM(order_status) AS order_status,
            CASE WHEN delivery_time_minutes = '' THEN NULL ELSE CAST(delivery_time_minutes AS INTEGER) END AS delivery_time_minutes,
            cancellation_reason,
            CASE WHEN order_status IN ('Delivered', 'Delivered Late') THEN 1 ELSE 0 END AS is_realized,
            CURRENT_TIMESTAMP AS stg_loaded_at
        FROM RAW_ORDERS;
    """)

    cursor.execute("DROP TABLE IF EXISTS STG_ORDER_ITEMS;")
    cursor.execute("""
        CREATE TABLE STG_ORDER_ITEMS AS
        SELECT
            TRIM(order_item_id) AS order_item_id,
            TRIM(order_id) AS order_id,
            TRIM(item_id) AS item_id,
            CAST(quantity AS INTEGER) AS quantity,
            CAST(unit_price AS REAL) AS unit_price,
            CAST(item_subtotal AS REAL) AS item_subtotal,
            CURRENT_TIMESTAMP AS stg_loaded_at
        FROM RAW_ORDER_ITEMS;
    """)
    print("Staging tables created successfully.")

    print("=== Step 3: Creating CURATED Dimensional Model ===")
    
    # DIM_CUSTOMERS
    cursor.execute("DROP TABLE IF EXISTS DIM_CUSTOMERS;")
    cursor.execute("""
        CREATE TABLE DIM_CUSTOMERS AS
        WITH cust_metrics AS (
            SELECT
                customer_id,
                COUNT(order_id) AS total_orders,
                SUM(is_realized) AS realized_orders,
                SUM(CASE WHEN is_realized = 1 THEN total_amount ELSE 0 END) AS total_spend,
                AVG(CASE WHEN is_realized = 1 THEN total_amount END) AS avg_order_value,
                MIN(order_date) AS first_order_date,
                MAX(order_date) AS last_order_date
            FROM STG_ORDERS
            GROUP BY customer_id
        )
        SELECT
            MD5(c.customer_id) AS customer_key,
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
            END AS age_group,
            c.signup_date,
            COALESCE(m.total_orders, 0) AS lifetime_orders,
            COALESCE(m.realized_orders, 0) AS realized_orders,
            ROUND(COALESCE(m.total_spend, 0), 2) AS lifetime_spend,
            ROUND(COALESCE(m.avg_order_value, 0), 2) AS customer_aov,
            m.first_order_date,
            m.last_order_date,
            CASE 
                WHEN COALESCE(m.total_orders, 0) = 0 THEN 'Inactive'
                WHEN COALESCE(m.total_orders, 0) = 1 THEN 'Single-Order Customer'
                WHEN COALESCE(m.total_orders, 0) BETWEEN 2 AND 4 THEN 'Occasional Buyer (2-4)'
                WHEN COALESCE(m.total_orders, 0) BETWEEN 5 AND 9 THEN 'Frequent Buyer (5-9)'
                ELSE 'Loyal / VIP Customer (10+)'
            END AS loyalty_segment,
            CASE WHEN COALESCE(m.total_orders, 0) > 1 THEN 1 ELSE 0 END AS is_repeat_customer
        FROM STG_CUSTOMERS c
        LEFT JOIN cust_metrics m ON c.customer_id = m.customer_id;
    """)

    # DIM_RESTAURANTS
    cursor.execute("DROP TABLE IF EXISTS DIM_RESTAURANTS;")
    cursor.execute("""
        CREATE TABLE DIM_RESTAURANTS AS
        SELECT
            MD5(restaurant_id) AS restaurant_key,
            restaurant_id,
            restaurant_name,
            cuisine,
            city,
            rating,
            CASE 
                WHEN rating >= 4.5 THEN 'Top Rated (4.5 - 5.0)'
                WHEN rating >= 4.0 THEN 'High Rated (4.0 - 4.4)'
                WHEN rating >= 3.5 THEN 'Average Rated (3.5 - 3.9)'
                ELSE 'Low Rated (< 3.5)'
            END AS rating_tier,
            cost_for_two,
            CASE 
                WHEN cost_for_two <= 350 THEN 'Budget Friendly'
                WHEN cost_for_two <= 700 THEN 'Mid-Range'
                ELSE 'Premium Dining'
            END AS cost_tier,
            is_active
        FROM STG_RESTAURANTS;
    """)

    # DIM_MENU_ITEMS
    cursor.execute("DROP TABLE IF EXISTS DIM_MENU_ITEMS;")
    cursor.execute("""
        CREATE TABLE DIM_MENU_ITEMS AS
        SELECT
            MD5(item_id) AS item_key,
            item_id,
            restaurant_id,
            item_name,
            category,
            is_veg,
            CASE WHEN is_veg = 1 THEN 'Vegetarian' ELSE 'Non-Vegetarian' END AS veg_flag_label,
            price,
            CASE 
                WHEN price < 100 THEN 'Economy (< ₹100)'
                WHEN price <= 250 THEN 'Standard (₹100 - ₹250)'
                WHEN price <= 400 THEN 'Premium (₹250 - ₹400)'
                ELSE 'Luxury (> ₹400)'
            END AS price_tier
        FROM STG_MENU_ITEMS;
    """)

    # FACT_ORDERS
    cursor.execute("DROP TABLE IF EXISTS FACT_ORDERS;")
    cursor.execute("""
        CREATE TABLE FACT_ORDERS AS
        WITH basket_summary AS (
            SELECT 
                order_id,
                COUNT(order_item_id) AS distinct_items_count,
                SUM(quantity) AS total_quantity
            FROM STG_ORDER_ITEMS
            GROUP BY order_id
        )
        SELECT
            MD5(o.order_id) AS order_key,
            o.order_id,
            MD5(o.customer_id) AS customer_key,
            o.customer_id,
            MD5(o.restaurant_id) AS restaurant_key,
            o.restaurant_id,
            REPLACE(o.order_date, '-', '') AS date_key,
            o.order_hour AS time_key,
            o.order_datetime,
            o.order_date,
            o.order_hour,
            COALESCE(b.distinct_items_count, 1) AS distinct_items_count,
            COALESCE(b.total_quantity, 1) AS basket_item_quantity,
            o.subtotal,
            o.discount_amount,
            o.delivery_fee,
            o.tax_amount,
            o.total_amount AS gross_order_value,
            CASE WHEN o.is_realized = 1 THEN o.total_amount ELSE 0.0 END AS realized_revenue,
            o.payment_mode,
            o.order_status,
            o.delivery_time_minutes,
            o.cancellation_reason,
            CASE WHEN o.order_status = 'Delivered' THEN 1 ELSE 0 END AS is_delivered,
            CASE WHEN o.order_status = 'Delivered Late' THEN 1 ELSE 0 END AS is_delivered_late,
            CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END AS is_cancelled,
            o.is_realized AS is_realized_flag
        FROM STG_ORDERS o
        LEFT JOIN basket_summary b ON o.order_id = b.order_id;
    """)

    # FACT_ORDER_ITEMS
    cursor.execute("DROP TABLE IF EXISTS FACT_ORDER_ITEMS;")
    cursor.execute("""
        CREATE TABLE FACT_ORDER_ITEMS AS
        SELECT
            MD5(oi.order_item_id) AS order_item_key,
            oi.order_item_id,
            MD5(oi.order_id) AS order_key,
            oi.order_id,
            MD5(oi.item_id) AS item_key,
            oi.item_id,
            oi.quantity,
            oi.unit_price,
            oi.item_subtotal
        FROM STG_ORDER_ITEMS oi;
    """)
    print("Curated tables created successfully.")
    
    conn.commit()
    
    print("\n=== Pipeline Verification & Core KPIs ===")
    cursor.execute("""
        SELECT 
            COUNT(*) AS total_orders,
            ROUND(SUM(gross_order_value), 2) AS gmv,
            ROUND(SUM(realized_revenue), 2) AS realized_revenue,
            ROUND(AVG(gross_order_value), 2) AS aov,
            ROUND(AVG(basket_item_quantity), 2) AS avg_basket_size,
            ROUND(AVG(is_delivered) * 100, 2) AS on_time_rate,
            ROUND(AVG(is_delivered_late) * 100, 2) AS late_rate,
            ROUND(AVG(is_cancelled) * 100, 2) AS cancel_rate
        FROM FACT_ORDERS;
    """)
    res = cursor.fetchone()
    print(f"Total Orders:        {res[0]:,}")
    print(f"Gross GMV:           Rs. {res[1]:,.2f}")
    print(f"Realized Revenue:    Rs. {res[2]:,.2f}")
    print(f"Average Order Value: Rs. {res[3]:.2f}")
    print(f"Avg Basket Size:     {res[4]:.2f} items")
    print(f"On-Time Rate:        {res[5]}%")
    print(f"Late Delivery Rate:  {res[6]}%")
    print(f"Cancellation Rate:   {res[7]}%")

    
    conn.close()
    print("\nLocal pipeline execution finished successfully! Database saved to:", DB_PATH)

if __name__ == "__main__":
    setup_local_pipeline()
