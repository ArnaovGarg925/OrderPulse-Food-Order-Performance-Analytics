"""
OrderPulse: Food Order Performance Analytics
Dataset Generation Script
Generates consistent, realistic relational CSV files:
1. customers.csv
2. restaurants.csv
3. menu_items.csv
4. orders.csv
5. order_items.csv
"""

import csv
import random
import os
from datetime import datetime, timedelta

# Set fixed seed for reproducibility
random.seed(42)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)

# 1. PARAMETERS & REFERENCE DATA
CITIES = ["Mumbai", "Delhi", "Bengaluru", "Hyderabad", "Pune", "Chennai", "Kolkata"]

CUISINES = [
    "North Indian", "South Indian", "Chinese", "Biryani", 
    "Italian", "Fast Food", "Desserts & Bakery", "Mughlai", "Healthy & Salads"
]

RESTAURANT_NAMES_PREFIX = [
    "Royal", "Spice", "Golden", "The Great", "Urban", "Flavors of", "Tandoori", 
    "Bawarchi", "Cafe", "Bistro", "Dragon", "Mama", "Paradise", "Curry", "Saffron",
    "Chaat", "Bella", "Taco", "Green", "Daily", "Little", "Sweet", "Grand"
]
RESTAURANT_NAMES_SUFFIX = [
    "Treat", "Darbar", "Junction", "Kitchen", "Corner", "Bites", "Dine", 
    "Hub", "Express", "House", "Villa", "Boutique", "Point", "Grill", "Court"
]

FIRST_NAMES = [
    "Aarav", "Vivaan", "Aditya", "Vihaan", "Arjun", "Reyansh", "Muhammad", "Sai",
    "Ayaan", "Krishna", "Ishaan", "Shaurya", "Atharva", "Advik", "Pranav", "Advaith",
    "Aanya", "Diya", "Saanvi", "Aadhya", "Ananya", "Pari", "Myra", "Anika", "Navya",
    "Riya", "Ira", "Sara", "Avni", "Kavya", "Pooja", "Priya", "Rahul", "Rohan", "Sneha",
    "Vikram", "Tanvi", "Neha", "Karan", "Simran", "Amit", "Deepak", "Sunita", "Rajesh"
]

LAST_NAMES = [
    "Sharma", "Verma", "Patel", "Gupta", "Singh", "Reddy", "Nair", "Iyer", "Chowdhury",
    "Mehta", "Joshi", "Bhat", "Kulkarni", "Deshmukh", "Pillai", "Das", "Banerjee",
    "Chatterjee", "Mukherjee", "Kapoor", "Khanna", "Malhotra", "Saxena", "Agarwal"
]

MENU_CATALOG = {
    "North Indian": [
        ("Paneer Butter Masala", "Main Course", True, 260),
        ("Dal Makhani", "Main Course", True, 220),
        ("Butter Naan", "Breads & Rice", True, 50),
        ("Garlic Naan", "Breads & Rice", True, 65),
        ("Tandoori Roti", "Breads & Rice", True, 30),
        ("Butter Chicken", "Main Course", False, 320),
        ("Chicken Tikka", "Appetizer", False, 280),
        ("Paneer Tikka", "Appetizer", True, 250),
        ("Jeera Rice", "Breads & Rice", True, 150),
        ("Gulab Jamun (2 pcs)", "Dessert", True, 80)
    ],
    "South Indian": [
        ("Masala Dosa", "Main Course", True, 120),
        ("Idli Sambar (2 pcs)", "Main Course", True, 80),
        ("Medu Vada (2 pcs)", "Appetizer", True, 90),
        ("Ghee Roast Dosa", "Main Course", True, 150),
        ("Rava Masala Dosa", "Main Course", True, 140),
        ("Filter Coffee", "Beverage", True, 60),
        ("Curd Rice", "Breads & Rice", True, 110),
        ("Uttapam", "Main Course", True, 130),
        ("Payasam", "Dessert", True, 90)
    ],
    "Biryani": [
        ("Hyderabadi Chicken Dum Biryani", "Main Course", False, 290),
        ("Hyderabadi Mutton Biryani", "Main Course", False, 380),
        ("Paneer Dum Biryani", "Main Course", True, 240),
        ("Veg Dum Biryani", "Main Course", True, 210),
        ("Chicken 65", "Appetizer", False, 240),
        ("Mirchi Ka Salan", "Main Course", True, 100),
        ("Raita", "Breads & Rice", True, 50),
        ("Double Ka Meetha", "Dessert", True, 95)
    ],
    "Chinese": [
        ("Veg Hakka Noodles", "Main Course", True, 180),
        ("Chicken Fried Rice", "Main Course", False, 220),
        ("Veg Manchurian Dry", "Appetizer", True, 190),
        ("Chilli Chicken Gravy", "Main Course", False, 260),
        ("Spring Rolls (4 pcs)", "Appetizer", True, 160),
        ("Hot & Sour Soup", "Appetizer", True, 130),
        ("Chicken Momos (6 pcs)", "Appetizer", False, 180),
        ("Veg Momos (6 pcs)", "Appetizer", True, 140)
    ],
    "Italian": [
        ("Margherita Pizza", "Main Course", True, 320),
        ("Farmhouse Veg Pizza", "Main Course", True, 390),
        ("Chicken Pepperoni Pizza", "Main Course", False, 450),
        ("Penne Alfredo Veg", "Main Course", True, 310),
        ("Penne Arrabbiata Chicken", "Main Course", False, 360),
        ("Garlic Bread with Cheese", "Appetizer", True, 160),
        ("Tiramisu Cup", "Dessert", True, 180)
    ],
    "Fast Food": [
        ("Veg Whopper Burger", "Main Course", True, 170),
        ("Crispy Chicken Burger", "Main Course", False, 210),
        ("French Fries (Large)", "Appetizer", True, 110),
        ("Peri Peri Fries", "Appetizer", True, 130),
        ("Veg Cheese Sandwich", "Main Course", True, 120),
        ("Cold Coffee with Ice Cream", "Beverage", True, 120),
        ("Oreo Thick Shake", "Beverage", True, 150),
        ("Soft Drink (500ml)", "Beverage", True, 60)
    ],
    "Desserts & Bakery": [
        ("Choco Lava Cake", "Dessert", True, 110),
        ("Red Velvet Pastry", "Dessert", True, 130),
        ("Belgian Chocolate Waffle", "Dessert", True, 190),
        ("Butterscotch Sundae", "Dessert", True, 150),
        ("Brownie with Hot Fudge", "Dessert", True, 160),
        ("Blueberry Cheesecake Slice", "Dessert", True, 220)
    ],
    "Mughlai": [
        ("Mutton Rogan Josh", "Main Course", False, 420),
        ("Chicken Korma", "Main Course", False, 360),
        ("Shahi Paneer", "Main Course", True, 280),
        ("Galouti Kebab (4 pcs)", "Appetizer", False, 340),
        ("Roomali Roti", "Breads & Rice", True, 45),
        ("Mughlai Paratha", "Breads & Rice", False, 160),
        ("Phirni", "Dessert", True, 90)
    ],
    "Healthy & Salads": [
        ("Greek Salad with Feta", "Main Course", True, 240),
        ("Grilled Chicken Caesar Salad", "Main Course", False, 290),
        ("Quinoa & Veggie Bowl", "Main Course", True, 270),
        ("Fresh Fruit Bowl", "Dessert", True, 160),
        ("Cold Pressed Green Juice", "Beverage", True, 140),
        ("Protein Smoothie Bowl", "Main Course", True, 220)
    ]
}

def generate_customers(num_customers=1500):
    customers = []
    start_date = datetime(2023, 1, 1)
    
    for i in range(1, num_customers + 1):
        cid = f"CUST_{i:05d}"
        fn = random.choice(FIRST_NAMES)
        ln = random.choice(LAST_NAMES)
        name = f"{fn} {ln}"
        email = f"{fn.lower()}.{ln.lower()}{random.randint(10, 999)}@example.com"
        phone = f"+91{random.randint(7000000000, 9999999999)}"
        city = random.choice(CITIES)
        age = random.randint(18, 62)
        signup_dt = start_date + timedelta(days=random.randint(0, 500))
        customers.append({
            "customer_id": cid,
            "customer_name": name,
            "email": email,
            "phone": phone,
            "city": city,
            "age": age,
            "signup_date": signup_dt.strftime("%Y-%m-%d")
        })
    return customers

def generate_restaurants(num_restaurants=80):
    restaurants = []
    used_names = set()
    
    for i in range(1, num_restaurants + 1):
        rid = f"REST_{i:04d}"
        cuisine = random.choice(CUISINES)
        city = random.choice(CITIES)
        
        while True:
            rname = f"{random.choice(RESTAURANT_NAMES_PREFIX)} {random.choice(RESTAURANT_NAMES_SUFFIX)}"
            full_name = f"{rname} - {city}"
            if full_name not in used_names:
                used_names.add(full_name)
                break
        
        # Ratings distribution: mostly 3.6 to 4.8
        rating = round(random.gauss(4.2, 0.4), 1)
        rating = max(3.0, min(4.9, rating))
        
        cost_for_two = random.choice([300, 450, 600, 800, 1000, 1400])
        is_active = True if random.random() > 0.05 else False
        
        restaurants.append({
            "restaurant_id": rid,
            "restaurant_name": rname,
            "cuisine": cuisine,
            "city": city,
            "rating": rating,
            "cost_for_two": cost_for_two,
            "is_active": is_active
        })
    return restaurants

def generate_menu_items(restaurants):
    menu_items = []
    item_id_counter = 1
    
    for rest in restaurants:
        cuisine = rest["cuisine"]
        primary_catalog = MENU_CATALOG.get(cuisine, [])
        # Each restaurant picks 6 to 10 items from primary cuisine catalog
        selected_items = random.sample(primary_catalog, min(len(primary_catalog), random.randint(6, 9)))
        
        # Maybe add 1 or 2 beverages or desserts from Fast Food / Desserts
        if cuisine not in ["Fast Food", "Desserts & Bakery"] and random.random() < 0.7:
            bonus = random.sample(MENU_CATALOG["Fast Food"][-3:], 1) + random.sample(MENU_CATALOG["Desserts & Bakery"][:3], 1)
            selected_items.extend(bonus)
            
        for item_name, category, is_veg, base_price in selected_items:
            mid = f"ITEM_{item_id_counter:05d}"
            item_id_counter += 1
            # slight price variance by restaurant
            price = round(base_price * random.uniform(0.9, 1.25), -1)
            price = max(30.0, float(price))
            menu_items.append({
                "item_id": mid,
                "restaurant_id": rest["restaurant_id"],
                "item_name": item_name,
                "category": category,
                "is_veg": is_veg,
                "price": price
            })
    return menu_items

def generate_orders_and_items(customers, restaurants, menu_items, total_orders=12000):
    orders = []
    order_items = []
    
    # Map menu items by restaurant
    rest_menu = {}
    for item in menu_items:
        rid = item["restaurant_id"]
        if rid not in rest_menu:
            rest_menu[rid] = []
        rest_menu[rid].append(item)
        
    # Map restaurants by city
    city_restaurants = {}
    for r in restaurants:
        c = r["city"]
        if c not in city_restaurants:
            city_restaurants[c] = []
        city_restaurants[c].append(r)
        
    # Customer ordering probability: Power law / Pareto distribution
    # ~25% one-time buyers, ~45% occasional (2-4 orders), ~25% frequent (5-10 orders), ~5% VIP (11+ orders)
    customer_weights = []
    for c in customers:
        rnd = random.random()
        if rnd < 0.30:
            weight = 1       # One-time or rare
        elif rnd < 0.75:
            weight = random.randint(3, 7)
        elif rnd < 0.95:
            weight = random.randint(8, 18)
        else:
            weight = random.randint(20, 45) # VIP
        customer_weights.append(weight)
        
    start_date = datetime(2024, 1, 1, 8, 0, 0)
    end_date = datetime(2024, 12, 31, 23, 0, 0)
    total_seconds = int((end_date - start_date).total_seconds())
    
    # Realistic meal peak hours distribution
    # 8-11: Breakfast (10%), 12-15: Lunch (30%), 16-18: Snacks (12%), 19-23: Dinner (42%), 23-2: Late night (6%)
    hour_weights = {
        8: 2, 9: 3, 10: 4, 11: 5,
        12: 9, 13: 12, 14: 8, 15: 3,
        16: 3, 17: 4, 18: 5,
        19: 9, 20: 15, 21: 14, 22: 9,
        23: 3, 0: 2, 1: 1
    }
    hours_list = list(hour_weights.keys())
    hours_probs = [hour_weights[h] for h in hours_list]
    
    order_item_counter = 1
    
    for i in range(1, total_orders + 1):
        oid = f"ORD_{i:06d}"
        cust = random.choices(customers, weights=customer_weights, k=1)[0]
        cust_id = cust["customer_id"]
        cust_city = cust["city"]
        
        # Pick restaurant in same city (or 3% chance outside)
        available_rests = city_restaurants.get(cust_city, restaurants)
        # Weight restaurant by rating
        rest_weights = [max(1.0, (r["rating"] - 2.5) ** 2) for r in available_rests]
        rest = random.choices(available_rests, weights=rest_weights, k=1)[0]
        rest_id = rest["restaurant_id"]
        
        # Order date & time
        day_offset = random.randint(0, 365)
        chosen_date = start_date + timedelta(days=day_offset)
        chosen_hour = random.choices(hours_list, weights=hours_probs, k=1)[0]
        chosen_minute = random.randint(0, 59)
        chosen_second = random.randint(0, 59)
        
        order_datetime = datetime(
            chosen_date.year, chosen_date.month, chosen_date.day,
            chosen_hour, chosen_minute, chosen_second
        )
        
        # Basket: 1 to 5 distinct items from restaurant
        items_avail = rest_menu.get(rest_id, [])
        if not items_avail:
            continue
        basket_size = min(len(items_avail), random.choices([1, 2, 3, 4, 5, 6], weights=[15, 35, 25, 15, 7, 3])[0])
        chosen_items = random.sample(items_avail, basket_size)
        
        subtotal = 0.0
        for itm in chosen_items:
            qty = random.choices([1, 2, 3, 4], weights=[70, 20, 7, 3])[0]
            item_price = float(itm["price"])
            item_subtotal = round(qty * item_price, 2)
            subtotal += item_subtotal
            
            order_items.append({
                "order_item_id": f"OITM_{order_item_counter:07d}",
                "order_id": oid,
                "item_id": itm["item_id"],
                "quantity": qty,
                "unit_price": item_price,
                "item_subtotal": item_subtotal
            })
            order_item_counter += 1
            
        # Delivery fee & discounts
        delivery_fee = 0.0 if subtotal > 500 else random.choice([30.0, 40.0, 50.0])
        discount = 0.0
        if subtotal > 400 and random.random() < 0.45:
            discount = round(min(subtotal * 0.15, 100.0), 2)
            
        tax = round((subtotal - discount) * 0.05, 2)
        total_amount = round(subtotal - discount + delivery_fee + tax, 2)
        
        # Order Outcome: Delivered (82%), Delivered Late (11%), Cancelled (7%)
        outcome_rnd = random.random()
        if outcome_rnd < 0.07:
            order_status = "Cancelled"
            delivery_time_min = None
            cancellation_reason = random.choice([
                "Customer changed mind", "Restaurant delay in preparation", 
                "Delivery partner unavailable", "Address unreachable", "Payment failure"
            ])
        elif outcome_rnd < 0.18:
            order_status = "Delivered Late"
            delivery_time_min = random.randint(48, 95)
            cancellation_reason = None
        else:
            order_status = "Delivered"
            delivery_time_min = random.randint(18, 44)
            cancellation_reason = None
            
        payment_mode = random.choices(
            ["UPI", "Credit Card", "Debit Card", "Net Banking", "Cash on Delivery"],
            weights=[55, 20, 10, 5, 10]
        )[0]
        
        orders.append({
            "order_id": oid,
            "customer_id": cust_id,
            "restaurant_id": rest_id,
            "order_datetime": order_datetime.strftime("%Y-%m-%d %H:%M:%S"),
            "subtotal": round(subtotal, 2),
            "discount_amount": discount,
            "delivery_fee": delivery_fee,
            "tax_amount": tax,
            "total_amount": total_amount,
            "payment_mode": payment_mode,
            "order_status": order_status,
            "delivery_time_minutes": delivery_time_min if delivery_time_min is not None else "",
            "cancellation_reason": cancellation_reason if cancellation_reason else ""
        })
        
    return orders, order_items

def write_csv(filepath, fieldnames, data):
    with open(filepath, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"Generated {filepath}: {len(data)} rows")

def main():
    print("Starting OrderPulse dataset generation...")
    
    customers = generate_customers(num_customers=1500)
    write_csv(
        os.path.join(DATA_DIR, "customers.csv"),
        ["customer_id", "customer_name", "email", "phone", "city", "age", "signup_date"],
        customers
    )
    
    restaurants = generate_restaurants(num_restaurants=80)
    write_csv(
        os.path.join(DATA_DIR, "restaurants.csv"),
        ["restaurant_id", "restaurant_name", "cuisine", "city", "rating", "cost_for_two", "is_active"],
        restaurants
    )
    
    menu_items = generate_menu_items(restaurants)
    write_csv(
        os.path.join(DATA_DIR, "menu_items.csv"),
        ["item_id", "restaurant_id", "item_name", "category", "is_veg", "price"],
        menu_items
    )
    
    orders, order_items = generate_orders_and_items(customers, restaurants, menu_items, total_orders=12000)
    write_csv(
        os.path.join(DATA_DIR, "orders.csv"),
        ["order_id", "customer_id", "restaurant_id", "order_datetime", "subtotal", "discount_amount", 
         "delivery_fee", "tax_amount", "total_amount", "payment_mode", "order_status", "delivery_time_minutes", "cancellation_reason"],
        orders
    )
    
    write_csv(
        os.path.join(DATA_DIR, "order_items.csv"),
        ["order_item_id", "order_id", "item_id", "quantity", "unit_price", "item_subtotal"],
        order_items
    )
    
    print("Dataset generation complete!")

if __name__ == "__main__":
    main()
