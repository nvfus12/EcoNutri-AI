-- Bảng lưu trữ thông tin người dùng
CREATE TABLE user_profile (

    user_id INTEGER PRIMARY KEY AUTOINCREMENT,

    name TEXT,
    age INTEGER,
    gender TEXT,

    height_cm REAL,
    weight_kg REAL,

    job TEXT,
    activity_level TEXT,

    allergies TEXT,
    medical_conditions TEXT,

    goal TEXT,

    bmi REAL,
    bmr REAL,
    tdee REAL,

    body_fat_percent REAL,

    location TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE nutrition_reference (

    food_id INTEGER PRIMARY KEY AUTOINCREMENT,

    food_name TEXT UNIQUE,

    calories REAL,
    protein REAL,
    carb REAL,
    fat REAL,
    sugar REAL,

    sodium REAL,
    potassium REAL,
    calcium REAL,

    vitamin_a REAL,
    vitamin_b REAL,
    vitamin_c REAL,
    vitamin_d REAL,

    fiber REAL,

    source TEXT
);

CREATE TABLE nutrition_diary (

    diary_id INTEGER PRIMARY KEY AUTOINCREMENT,

    user_id INTEGER,

    food_name TEXT,

    meal_type TEXT,

    portion_g REAL,

    calories REAL,
    protein REAL,
    carb REAL,
    fat REAL,
    sugar REAL,

    sodium REAL,
    potassium REAL,
    calcium REAL,

    image_path TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES user_profile(user_id)
);