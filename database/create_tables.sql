PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS user_profile (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    age INTEGER,
    gender TEXT,
    height_cm REAL,
    weight_kg REAL,
    body_fat_percent REAL,
    activity_level TEXT,
    location TEXT,
    season TEXT,
    bmr REAL,
    tdee REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS food_reference (
    food_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    calories_100g REAL,
    protein_100g REAL,
    fat_100g REAL,
    carb_100g REAL,
    sugar_100g REAL,
    fiber_100g REAL,
    vitamin_json TEXT,
    mineral_json TEXT,
    carbon_100g REAL,
    source TEXT
);

CREATE TABLE IF NOT EXISTS nutrition_diary (
    diary_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    food_id INTEGER,
    meal_type TEXT,
    portion_g REAL,
    calories REAL,
    carbon_footprint REAL,
    sugar_g REAL,
    fat_g REAL,
    protein_g REAL,
    carb_g REAL,
    image_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES user_profile(user_id),
    FOREIGN KEY (food_id) REFERENCES food_reference(food_id)
);