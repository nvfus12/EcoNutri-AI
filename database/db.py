import sqlite3

DB_NAME = "nutrition_ai.db"

def get_conn():
    return sqlite3.connect(DB_NAME)

# ========== USER PROFILE ==========

def create_user(data):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO user_profile 
        (name, age, gender, height_cm, weight_kg, body_fat_percent,
         activity_level, location, season, bmr, tdee)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
    """, data)
    conn.commit()
    conn.close()


def get_user(user_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT * FROM user_profile WHERE user_id=?", (user_id,))
    row = cur.fetchone()
    conn.close()
    return row


def update_user(user_id, data):
    """Update a user record. ``data`` should be a tuple containing
    (name, age, gender, height_cm, weight_kg, body_fat_percent,
     activity_level, location, season, bmr, tdee).
    """
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        UPDATE user_profile
        SET name=?, age=?, gender=?, height_cm=?, weight_kg=?, body_fat_percent=?,
            activity_level=?, location=?, season=?, bmr=?, tdee=?
        WHERE user_id=?
    """, data + (user_id,))
    conn.commit()
    conn.close()


def delete_user(user_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("DELETE FROM user_profile WHERE user_id=?", (user_id,))
    conn.commit()
    conn.close()


# ========== FOOD ==========

def create_food(data):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        INSERT OR IGNORE INTO food_reference
        (name, calories_100g, protein_100g, fat_100g, carb_100g,
         sugar_100g, fiber_100g, vitamin_json, mineral_json, carbon_100g, source)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
    """, data)
    conn.commit()
    conn.close()


def get_food_by_name(name):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT * FROM food_reference WHERE name=?", (name,))
    row = cur.fetchone()
    conn.close()
    return row


def get_food(food_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT * FROM food_reference WHERE food_id=?", (food_id,))
    row = cur.fetchone()
    conn.close()
    return row


def update_food(food_id, data):
    """Update a food reference. ``data`` tuple should match the columns in
    order: (name, calories_100g, protein_100g, fat_100g, carb_100g,
     sugar_100g, fiber_100g, vitamin_json, mineral_json, carbon_100g, source)
    """
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        UPDATE food_reference
        SET name=?, calories_100g=?, protein_100g=?, fat_100g=?, carb_100g=?,
            sugar_100g=?, fiber_100g=?, vitamin_json=?, mineral_json=?, carbon_100g=?, source=?
        WHERE food_id=?
    """, data + (food_id,))
    conn.commit()
    conn.close()


def delete_food(food_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("DELETE FROM food_reference WHERE food_id=?", (food_id,))
    conn.commit()
    conn.close()


# ========== DIARY ==========

def add_diary(data):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO nutrition_diary
        (user_id, food_id, meal_type, portion_g, calories, carbon_footprint,
         sugar_g, fat_g, protein_g, carb_g, image_path)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
    """, data)
    conn.commit()
    conn.close()


def get_user_diary(user_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        SELECT d.created_at, f.name, d.calories, d.carbon_footprint
        FROM nutrition_diary d
        JOIN food_reference f ON d.food_id = f.food_id
        WHERE d.user_id=?
        ORDER BY d.created_at DESC
    """, (user_id,))
    rows = cur.fetchall()
    conn.close()
    return rows


def update_diary(diary_id, data):
    """Modify an existing diary entry. ``data`` should be a tuple with the
    same fields as ``add_diary`` except the ID.
    """
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        UPDATE nutrition_diary
        SET user_id=?, food_id=?, meal_type=?, portion_g=?, calories=?, carbon_footprint=?,
            sugar_g=?, fat_g=?, protein_g=?, carb_g=?, image_path=?
        WHERE diary_id=?
    """, data + (diary_id,))
    conn.commit()
    conn.close()


def delete_diary(diary_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("DELETE FROM nutrition_diary WHERE diary_id=?", (diary_id,))
    conn.commit()
    conn.close()
