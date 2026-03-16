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

    food_name TEXT UNIQUE,
    serving_size TEXT,

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

    vitamin_a REAL,
    vitamin_b REAL,
    vitamin_c REAL,
    vitamin_d REAL,

    fiber REAL

    image_path TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES user_profile(user_id)
);
INSERT INTO nutrition_reference
(food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber)
VALUES

('Banh-beo','1 dia',250,6,40,6,2,300,120,30,10,0.2,2,0,2),
('Banh-bot-loc','1 cai',270,8,38,7,2,350,140,40,15,0.2,3,0,2),
('Banh-can','1 phan',320,10,45,10,3,420,160,50,20,0.3,3,0,3),
('Banh-canh','1 bat',420,20,55,12,4,650,220,70,30,0.4,4,0,3),
('Banh-chung','1 mieng',600,18,80,20,3,700,250,60,20,0.5,2,0,4),
('Banh-cuon','1 dia',300,12,45,8,2,450,200,60,25,0.3,3,0,2),
('Banh-duc','1 phan',220,6,42,4,2,280,110,40,15,0.2,2,0,2),
('Banh-gio','1 cai',350,14,48,12,3,520,200,60,20,0.3,3,0,3),
('Banh-khot','1 dia',330,10,35,15,3,500,180,50,25,0.3,4,0,3),
('Banh-mi','1 o',350,12,45,10,4,550,220,70,30,0.4,5,0,3),

('Banh-pia','1 cai',400,8,55,15,10,420,160,50,20,0.3,2,0,3),
('Banh-tet','1 mieng',620,18,85,22,4,720,260,60,20,0.5,2,0,4),
('Banh-trang-nuong','1 cai',280,9,32,12,3,500,170,60,30,0.3,4,0,2),
('Banh-xeo','1 cai',450,18,40,20,4,650,240,80,40,0.4,5,0,4),

('Bun-bo-Hue','1 bat',480,28,60,18,5,900,320,90,50,0.6,6,0,4),
('Bun-dau-mam-tom','1 phan',520,24,45,26,4,950,300,100,40,0.5,5,0,4),
('Bun-mam','1 bat',500,25,55,18,6,980,310,90,50,0.6,6,0,4),
('Bun-rieu','1 bat',420,22,55,12,4,850,290,80,40,0.5,6,0,3),
('Bun-thit-nuong','1 phan',480,26,60,16,5,750,300,80,45,0.5,6,0,4),

('Ca-kho-to','1 phan',350,32,10,20,3,800,420,70,40,0.5,3,0,1),
('Canh-chua','1 bat',200,18,15,6,4,500,350,60,45,0.4,10,0,2),
('Cao-lau','1 to',450,24,60,14,4,780,290,80,40,0.5,5,0,3),
('Chao-long','1 bat',380,20,40,15,2,700,250,60,30,0.4,4,0,2),
('Com-tam','1 dia',520,28,65,18,5,820,310,90,40,0.6,5,0,3),

('Goi-cuon','1 cuon',200,10,30,5,2,350,200,70,50,0.4,8,0,3),
('Hu-tieu','1 to',420,22,60,12,4,800,300,80,40,0.5,6,0,3),
('Mi-quang','1 to',430,24,55,14,4,780,290,80,45,0.5,6,0,3),
('Nem-chua','1 cai',300,18,15,20,3,900,220,60,30,0.4,3,0,1),
('Pho','1 to',450,25,55,15,4,850,320,90,40,0.6,5,0,3),

('Xoi-xeo','1 suat',550,14,80,18,5,650,260,70,30,0.4,3,0,4);