-- Bảng lưu trữ thông tin người dùng
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    age INTEGER,
    weight REAL,
    height REAL,
    daily_calories_goal REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng lưu trữ lịch sử các món ăn đã quét (nhận diện từ YOLO)
CREATE TABLE IF NOT EXISTS meal_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    food_name TEXT NOT NULL,
    calories REAL NOT NULL,
    image_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- (Tùy chọn) Thêm sẵn một user mặc định để test hệ thống
INSERT INTO users (name, age, weight, height, daily_calories_goal) 
VALUES ('Test User', 20, 65.0, 170.0, 2000.0);