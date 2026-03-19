-- Kích hoạt khóa ngoại trong SQLite (tùy chọn, nên chạy mỗi khi kết nối db)
PRAGMA foreign_keys = ON;-- ==========================================

-- 1. CÁC BẢNG ĐỘC LẬP (Không chứa khóa ngoại)
-- ==========================================

-- Bảng user_profile
CREATE TABLE IF NOT EXISTS user_profile (
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng food_categories
CREATE TABLE IF NOT EXISTS food_categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL,
    description TEXT
);

-- Bảng nutrition_reference
CREATE TABLE IF NOT EXISTS nutrition_reference (
    food_name TEXT PRIMARY KEY,
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

-- Bảng regions
CREATE TABLE IF NOT EXISTS regions (
    region_id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_name TEXT NOT NULL,
    geographic_zone TEXT
);

-- Bảng seasons (Từ file full.sql gốc)
CREATE TABLE IF NOT EXISTS seasons (
    season_id INTEGER PRIMARY KEY,
    season_name TEXT NOT NULL,
    month_start INTEGER CHECK(month_start >= 1 AND month_start <= 12),
    month_end INTEGER CHECK(month_end >= 1 AND month_end <= 12)
);

-- ==========================================
-- 2. CÁC BẢNG PHỤ THUỘC (Chứa khóa ngoại)
-- ==========================================

-- Bảng nutrition_diary
CREATE TABLE IF NOT EXISTS nutrition_diary (
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
    fiber REAL,
    image_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_profile(user_id),
    FOREIGN KEY (food_name) REFERENCES nutrition_reference(food_name)
);

-- Bảng regional_specialties
CREATE TABLE IF NOT EXISTS regional_specialties (
    specialty_id INTEGER PRIMARY KEY AUTOINCREMENT,
    specialty_name TEXT NOT NULL,
    base_food_name TEXT,
    region_id INTEGER,
    category_id INTEGER,
    peak_harvest_note TEXT,
    FOREIGN KEY (base_food_name) REFERENCES nutrition_reference(food_name),
    FOREIGN KEY (category_id) REFERENCES food_categories(category_id),
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- Bảng specialty_nutrition
CREATE TABLE IF NOT EXISTS specialty_nutrition (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    specialty_id INTEGER,
    calories_100g REAL,
    protein_100g REAL,
    fat_100g REAL,
    carb_100g REAL,
    fiber_100g REAL,
    carbon_footprint_100g REAL,
    FOREIGN KEY (specialty_id) REFERENCES regional_specialties(specialty_id)
);

-- Bảng specialty_seasons
CREATE TABLE IF NOT EXISTS specialty_seasons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    specialty_id INTEGER,
    season_id INTEGER,
    quality_rating TEXT,
    FOREIGN KEY (specialty_id) REFERENCES regional_specialties(specialty_id),
    FOREIGN KEY (season_id) REFERENCES seasons(season_id)
);

-- ==========================================
-- 3. BẢNG MÙA VỤ TÙY CHỈNH (Từ mẫu của bạn)
-- ==========================================
CREATE TABLE IF NOT EXISTS season (
    season_id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_name TEXT NOT NULL,
    food_type TEXT NOT NULL CHECK(food_type IN ('rau', 'dac_san')),
    region_code TEXT NOT NULL CHECK(region_code IN ('bac', 'trung', 'nam')),
    month_start INTEGER NOT NULL CHECK(month_start BETWEEN 1 AND 12),
    month_end INTEGER NOT NULL CHECK(month_end BETWEEN 1 AND 12),
    note TEXT,
    source TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(food_name, food_type, region_code, month_start, month_end)
);

-- ==========================================
-- 4. TẠO INDEX (Đã thêm IF NOT EXISTS)
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_diary_user ON nutrition_diary(user_id);
CREATE INDEX IF NOT EXISTS idx_specialty_category ON regional_specialties(category_id);
CREATE INDEX IF NOT EXISTS idx_specialty_region ON regional_specialties(region_id);
CREATE INDEX IF NOT EXISTS idx_season_region_month ON season(region_code, month_start, month_end);
CREATE INDEX IF NOT EXISTS idx_season_food_type ON season(food_type);

-- ==========================================
-- 5. CHÈN DỮ LIỆU MẪU (Từ mẫu của bạn)
-- ==========================================
INSERT OR IGNORE INTO nutrition_reference
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


-- ==========================================
-- 1. BẢNG DANH MỤC MÓN ĂN (food_categories)
-- ==========================================
INSERT OR IGNORE INTO food_categories (category_id, category_name, description) VALUES
(1, 'Món Nước', 'Các loại bún, phở, miến, hủ tiếu, bánh canh...'),
(2, 'Món Cơm', 'Cơm tấm, cơm rang, cơm niêu, cơm phần...'),
(3, 'Món Cuốn & Gỏi', 'Gỏi cuốn, phở cuốn, nộm, gỏi ngó sen...'),
(4, 'Món Chiên/Xào', 'Các món xào mặn, chiên giòn, xào tỏi...'),
(5, 'Bánh Truyền Thống', 'Bánh chưng, bánh tét, bánh xèo, bánh bèo, bánh bột lọc...'),
(6, 'Thịt & Gia Cầm', 'Thịt lợn, bò, gà, vịt chế biến cơ bản...'),
(7, 'Hải Sản', 'Cá, tôm, cua, mực, ốc...'),
(8, 'Rau Củ Tươi', 'Rau xanh, củ quả luộc, xào, ăn sống...'),
(9, 'Trái Cây', 'Trái cây tươi đặc sản các vùng miền...'),
(10, 'Đồ Uống & Tráng Miệng', 'Chè, sinh tố, nước ép, cà phê...');

-- ==========================================
-- 2. BẢNG VÙNG MIỀN (regions)
-- ==========================================
INSERT OR IGNORE INTO regions (region_id, region_name, geographic_zone) VALUES
(1, 'Đồng bằng sông Hồng', 'Bắc Bộ'),
(2, 'Đông Bắc Bộ', 'Bắc Bộ'),
(3, 'Tây Bắc Bộ', 'Bắc Bộ'),
(4, 'Bắc Trung Bộ', 'Trung Bộ'),
(5, 'Nam Trung Bộ', 'Trung Bộ'),
(6, 'Tây Nguyên', 'Trung Bộ'),
(7, 'Đông Nam Bộ', 'Nam Bộ'),
(8, 'Đồng bằng sông Cửu Long', 'Nam Bộ');

-- ==========================================
-- 3. BẢNG MÙA VỤ CHUẨN (seasons)
-- ==========================================
INSERT OR IGNORE INTO seasons (season_id, season_name, month_start, month_end) VALUES
(1, 'Mùa Xuân', 1, 3),
(2, 'Mùa Hạ', 4, 6),
(3, 'Mùa Thu', 7, 9),
(4, 'Mùa Đông', 10, 12),
(5, 'Quanh năm', 1, 12),
(6, 'Đầu mùa mưa (Nam Bộ)', 5, 7),
(7, 'Mùa nước nổi (ĐBSCL)', 8, 11);

-- ==========================================
-- 4. BẢNG THÔNG TIN DINH DƯỠNG (nutrition_reference)
-- Mở rộng thêm Nông sản, Thực phẩm thô & Đặc sản
-- ==========================================
INSERT OR IGNORE INTO nutrition_reference 
(food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber) 
VALUES
-- Món nước (Bổ sung thêm)
('Pho-ga', '1 to', 400, 22, 50, 12, 3, 750, 300, 80, 30, 0.5, 4, 0, 2),
('Bun-cha-Ha-Noi', '1 phan', 550, 25, 65, 20, 10, 800, 350, 60, 20, 0.6, 5, 0, 3),
('Banh-da-cua', '1 to', 410, 18, 55, 10, 4, 700, 320, 150, 40, 0.4, 8, 0, 4),
('Bun-quay-Phu-Quoc', '1 to', 380, 20, 50, 8, 2, 600, 280, 70, 10, 0.3, 5, 0, 2),

-- Cơm & Bánh
('Com-chay-kho-quet', '1 phan', 450, 15, 60, 18, 8, 850, 200, 50, 10, 0.2, 2, 0, 2),
('Banh-cuon-Thanh-Tri', '1 dia', 280, 10, 42, 6, 2, 400, 150, 40, 5, 0.2, 0, 0, 1),
('Banh-khot-Vung-Tau', '1 dia (8 cai)', 350, 12, 40, 15, 3, 450, 200, 60, 20, 0.3, 2, 0, 2),
('Banh-trang-Tron', '1 bich', 320, 8, 45, 10, 12, 650, 180, 50, 15, 0.2, 5, 0, 3),

-- Rau củ quả thô (100g chuẩn)
('Rau-muong-luoc', '100g', 30, 3, 3, 0.2, 1, 50, 300, 70, 60, 0.1, 20, 0, 2.5),
('Rau-lang-luoc', '100g', 35, 2.5, 4, 0.2, 1, 40, 280, 60, 50, 0.1, 15, 0, 3),
('Mong-toi-nau-canh', '100g', 25, 2, 3, 0.1, 0.5, 30, 250, 80, 45, 0.1, 12, 0, 2.5),
('Ca-chua-tuoi', '100g', 18, 0.9, 3.9, 0.2, 2.6, 5, 237, 10, 42, 0.1, 14, 0, 1.2),
('Khoai-lang-luoc', '100g', 86, 1.6, 20, 0.1, 4, 55, 337, 30, 141, 0.2, 2.4, 0, 3),
('Bi-do-luoc', '100g', 26, 1, 6.5, 0.1, 1.4, 1, 340, 21, 53, 0.1, 9, 0, 0.5),

-- Trái cây (100g chuẩn)
('Thanh-long-ruot-do', '100g', 60, 1.2, 13, 0.5, 8, 0, 250, 15, 5, 0.1, 10, 0, 3),
('Sau-rieng', '100g', 147, 1.5, 27, 5.3, 20, 2, 436, 6, 2, 0.1, 19, 0, 3.8),
('Xoai-cat-Hoa-Loc', '100g', 60, 0.8, 15, 0.4, 14, 1, 168, 11, 54, 0.1, 36, 0, 1.6),
('Buoi-Nam-Roi', '100g', 38, 0.7, 9.6, 0.1, 7, 0, 135, 12, 0, 0.1, 61, 0, 1),
('Vai-thieu', '100g', 66, 0.8, 16.5, 0.4, 15, 1, 171, 5, 0, 0.1, 71, 0, 1.3),
('Nhan-long', '100g', 60, 1.3, 15, 0.1, 14, 0, 266, 1, 0, 0.1, 84, 0, 1.1),
('Man-Moc-Chau', '100g', 46, 0.7, 11.4, 0.3, 9.9, 0, 157, 6, 17, 0.1, 9.5, 0, 1.4),

-- Thịt cá thô (100g sống)
('Thit-lon-ba-chi', '100g', 260, 16, 0, 21, 0, 60, 250, 10, 0, 0.4, 0, 0.5, 0),
('Thit-bo-thăn', '100g', 143, 26, 0, 3.5, 0, 55, 330, 12, 0, 0.6, 0, 0.1, 0),
('Uc-ga', '100g', 165, 31, 0, 3.6, 0, 74, 256, 15, 0, 0.5, 0, 0, 0),
('Ca-loc-dong', '100g', 97, 18, 0, 2.5, 0, 50, 300, 40, 10, 0.2, 0, 1, 0),
('Tom-su', '100g', 99, 24, 0.2, 0.3, 0, 111, 259, 70, 5, 0.1, 2, 0.1, 0);

-- ==========================================
-- 5. BẢNG ĐẶC SẢN VÙNG MIỀN (regional_specialties)
-- ==========================================
INSERT OR IGNORE INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note) VALUES
('Phở Bò Hà Nội', 'Pho', 1, 1, 'Ngon nhất khi ăn vào mùa đông'),
('Bún Chả Hà Nội', 'Bun-cha-Ha-Noi', 1, 3, 'Phổ biến quanh năm'),
('Bánh Đa Cua Hải Phòng', 'Banh-da-cua', 2, 1, 'Hải sản tươi ngon nhất vào mùa hè'),
('Vải Thiều Thanh Hà', 'Vai-thieu', 1, 9, 'Thu hoạch rộ tháng 5 - tháng 7'),
('Mận Hậu Mộc Châu', 'Man-Moc-Chau', 3, 9, 'Thu hoạch rộ tháng 4 - tháng 6'),
('Bún Bò Huế', 'Bun-bo-Hue', 4, 1, 'Ngon nhất vào mùa mưa miền Trung'),
('Mì Quảng', 'Mi-quang', 5, 1, 'Đặc sản xứ Quảng, ăn quanh năm'),
('Cao Lầu Hội An', 'Cao-lau', 5, 1, 'Sợi mì đặc trưng ngâm tro tràm'),
('Bánh Khọt Vũng Tàu', 'Banh-khot-Vung-Tau', 7, 5, 'Hải sản tươi ngon quanh năm'),
('Sầu Riêng Chợ Lách', 'Sau-rieng', 8, 9, 'Đỉnh vụ tháng 5 - tháng 8'),
('Bưởi Năm Roi', 'Buoi-Nam-Roi', 8, 9, 'Ngon nhất dịp cận Tết âm lịch'),
('Bún Quậy Phú Quốc', 'Bun-quay-Phu-Quoc', 8, 1, 'Hải sản tươi sống, quậy tại chỗ'),
('Thanh Long Bình Thuận', 'Thanh-long-ruot-do', 5, 9, 'Thu hoạch chính vụ hè thu'),
('Cơm Tấm Sài Gòn', 'Com-tam', 7, 2, 'Món ăn sáng/đêm huyền thoại Nam Bộ');

-- ==========================================
-- 6. BẢNG DINH DƯỠNG ĐẶC SẢN (specialty_nutrition)
-- Dữ liệu / 100g cho các đặc sản
-- ==========================================
INSERT OR IGNORE INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g) VALUES
(1, 110, 6, 3, 15, 0.5, 2.5),  -- Phở Bò
(2, 180, 8, 9, 18, 1, 3.0),    -- Bún Chả
(4, 66, 0.8, 0.4, 16.5, 1.3, 0.5), -- Vải thiều
(5, 46, 0.7, 0.3, 11.4, 1.4, 0.4), -- Mận hậu
(6, 120, 7, 4.5, 15, 1, 2.8),  -- Bún Bò Huế
(10, 147, 1.5, 5.3, 27, 3.8, 1.2), -- Sầu Riêng
(13, 60, 1.2, 0.5, 13, 3, 0.6); -- Thanh Long

-- ==========================================
-- 7. BẢNG MÙA VỤ ĐẶC SẢN (specialty_seasons)
-- Liên kết Đặc sản với Mùa vụ
-- ==========================================
INSERT OR IGNORE INTO specialty_seasons (specialty_id, season_id, quality_rating) VALUES
(1, 4, 'Excellent'), -- Phở mùa đông
(4, 2, 'Premium'),   -- Vải thiều mùa hè
(5, 2, 'Premium'),   -- Mận hậu mùa hè
(10, 6, 'Excellent'),-- Sầu riêng đầu mùa mưa
(11, 4, 'Premium'),  -- Bưởi mùa đông (cận Tết)
(13, 3, 'Good');     -- Thanh long mùa thu

-- ==========================================
-- 8. BẢNG TÙY CHỈNH THEO THÁNG (season)
-- Bảng này bạn tự định nghĩa (food_type in 'rau', 'dac_san' / region_code in 'bac','trung','nam')
-- ==========================================
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source) VALUES
-- Mùa Rau Củ
('Rau Muống', 'rau', 'bac', 4, 10, 'Mọc rộ vào mùa hè và thu', 'Viện Dinh Dưỡng'),
('Rau Muống', 'rau', 'nam', 1, 12, 'Khí hậu ấm áp nên có quanh năm', 'Sở NN&PTNT'),
('Rau Ngót', 'rau', 'bac', 3, 9, 'Nhiều lá, non vào mùa nóng', 'Dữ liệu Nông nghiệp'),
('Rau Đắng', 'rau', 'nam', 5, 10, 'Nhiều vào mùa mưa', 'Sở NN&PTNT'),
('Su Hào', 'rau', 'bac', 10, 3, 'Ưa lạnh, củ giòn ngọt vào mùa đông', 'Viện Dinh Dưỡng'),
('Bắp Cải', 'rau', 'bac', 10, 3, 'Cuộn chặt, ngọt nước mùa đông lạnh', 'Viện Dinh Dưỡng'),
('Bông Điên Điển', 'rau', 'nam', 8, 11, 'Đặc trưng mùa nước nổi miền Tây', 'Đặc sản Đồng Tháp'),

-- Mùa Đặc Sản Trái Cây / Món Ăn
('Vải Thiều Thanh Hà', 'dac_san', 'bac', 5, 7, 'Ngọt lịm, hạt nhỏ', 'Cổng TTĐT Hải Dương'),
('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 7, 9, 'Cùi dày, mọng nước', 'Cổng TTĐT Hưng Yên'),
('Mận Hậu Mộc Châu', 'dac_san', 'bac', 4, 6, 'Quả to, giòn, chua ngọt', 'Sơn La Tourism'),
('Bơ Sáp Đắk Lắk', 'dac_san', 'trung', 5, 8, 'Thịt vàng, béo ngậy', 'Tây Nguyên Nông Sản'),
('Sầu Riêng Ri6', 'dac_san', 'nam', 4, 8, 'Hạt lép, cơm vàng', 'Nông Sản Chợ Lách'),
('Dâu Tây Đà Lạt', 'dac_san', 'trung', 1, 12, 'Có quanh năm nhưng ngon nhất mùa khô (T11-T4)', 'Lâm Đồng OCOP'),
('Chôm Chôm Nhãn', 'dac_san', 'nam', 6, 8, 'Trái nhỏ, tróc hạt, giòn', 'Đồng Nai OCOP'),
('Dưa Hấu Long An', 'dac_san', 'nam', 11, 2, 'Rộ vào dịp Tết Nguyên Đán', 'Long An Nông Nghiệp'),
('Bưởi Đoan Hùng', 'dac_san', 'bac', 9, 12, 'Quả nhỏ, tép ráo, ngọt thanh', 'Phú Thọ OCOP'),
('Bưởi Da Xanh', 'dac_san', 'nam', 1, 12, 'Thu hoạch quanh năm, ngon nhất cuối năm', 'Bến Tre OCOP');

CREATE TABLE IF NOT EXISTS user_weight_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    weight_kg REAL,
    recorded_at TIMESTAMP DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (user_id) REFERENCES user_profile(user_id)
);


-- ==========================================
-- DỮ LIỆU ĐẶC SẢN MIỀN BẮC (TỰ ĐỘNG THÊM VÀO)
-- ==========================================
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Cha-ca-La-Vong', '100g/1 phần', 350, 20, 10, 25, 1.35, 258.54, 107.89, 36.89, 1.65, 0.8, 19.71, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Chả Cá Lã Vọng', 'Cha-ca-La-Vong', 1, 7, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Cha-ca-La-Vong');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 350, 20, 25, 10, 2, 1.58
FROM regional_specialties WHERE base_food_name = 'Cha-ca-La-Vong'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cha-ca-La-Vong');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Cha-ca-La-Vong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cha-ca-La-Vong' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Cha-ca-La-Vong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cha-ca-La-Vong' AND ss.season_id = 3);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Cá Lã Vọng', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Bun-thang', '100g/1 phần', 380, 22, 55, 10, 3.58, 427.51, 216.98, 34.62, 39.67, 0.17, 5.31, 0.0, 3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bún Thang', 'Bun-thang', 1, 1, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Bun-thang');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 380, 22, 10, 55, 3, 3.43
FROM regional_specialties WHERE base_food_name = 'Bun-thang'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Bun-thang');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Bun-thang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Bun-thang' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Bun-thang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Bun-thang' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Thang', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Bun-oc-Ha-Noi', '100g/1 phần', 320, 15, 50, 8, 4.71, 249.25, 265.35, 82.63, 36.21, 0.28, 10.35, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bún Ốc Hà Nội', 'Bun-oc-Ha-Noi', 1, 1, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Bun-oc-Ha-Noi');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 320, 15, 8, 50, 4, 2.46
FROM regional_specialties WHERE base_food_name = 'Bun-oc-Ha-Noi'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Bun-oc-Ha-Noi');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Bun-oc-Ha-Noi'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Bun-oc-Ha-Noi' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Good'
FROM regional_specialties WHERE base_food_name = 'Bun-oc-Ha-Noi'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Bun-oc-Ha-Noi' AND ss.season_id = 3);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bún Ốc Hà Nội', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Com-lang-Vong', '100g/1 phần', 250, 5, 55, 1, 6.24, 196.22, 129.44, 65.39, 2.32, 0.14, 5.78, 0.0, 3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cốm Làng Vòng', 'Com-lang-Vong', 1, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Com-lang-Vong');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 250, 5, 1, 55, 3, 2.15
FROM regional_specialties WHERE base_food_name = 'Com-lang-Vong'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-lang-Vong');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Com-lang-Vong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-lang-Vong' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Com-lang-Vong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-lang-Vong' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cốm Làng Vòng', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-tom-Ho-Tay', '100g/1 phần', 420, 15, 45, 22, 8.63, 390.7, 122.08, 80.8, 28.81, 0.65, 15.68, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Tôm Hồ Tây', 'Banh-tom-Ho-Tay', 1, 4, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-tom-Ho-Tay');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 420, 15, 22, 45, 2, 0.56
FROM regional_specialties WHERE base_food_name = 'Banh-tom-Ho-Tay'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-tom-Ho-Tay');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-tom-Ho-Tay'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-tom-Ho-Tay' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Banh-tom-Ho-Tay'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-tom-Ho-Tay' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tôm Hồ Tây', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Xoi-xeo-Ha-Noi', '100g/1 phần', 550, 12, 85, 18, 7.95, 367.55, 238.39, 43.87, 6.77, 0.76, 16.12, 0.0, 5, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Xôi Xéo Hà Nội', 'Xoi-xeo-Ha-Noi', 1, 2, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Xoi-xeo-Ha-Noi');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 550, 12, 18, 85, 5, 1.59
FROM regional_specialties WHERE base_food_name = 'Xoi-xeo-Ha-Noi'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-xeo-Ha-Noi');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Xoi-xeo-Ha-Noi'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-xeo-Ha-Noi' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Xoi-xeo-Ha-Noi'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-xeo-Ha-Noi' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Xéo Hà Nội', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Nem-chua-ran', '100g/1 phần', 480, 15, 20, 35, 2.44, 340.33, 253.58, 21.56, 29.66, 0.57, 6.24, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Nem Chua Rán', 'Nem-chua-ran', 1, 4, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Nem-chua-ran');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 480, 15, 35, 20, 1, 1.18
FROM regional_specialties WHERE base_food_name = 'Nem-chua-ran'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-chua-ran');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Nem-chua-ran'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-chua-ran' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Nem-chua-ran'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-chua-ran' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Chua Rán', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-cuon-Thanh-Tri', '100g/1 phần', 280, 10, 42, 6, 6.56, 283.47, 124.57, 40.16, 45.11, 0.85, 13.46, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Cuốn Thanh Trì', 'Banh-cuon-Thanh-Tri', 1, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Thanh-Tri');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 280, 10, 6, 42, 1, 3.57
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Thanh-Tri'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Thanh-Tri');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Thanh-Tri'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Thanh-Tri' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Thanh-Tri'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Thanh-Tri' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Thanh Trì', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-cay-Thai-Binh', '100g/1 phần', 380, 4, 75, 8, 2.63, 316.47, 292.99, 29.39, 10.7, 0.7, 0.22, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Cáy Thái Bình', 'Banh-cay-Thai-Binh', 1, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-cay-Thai-Binh');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 380, 4, 8, 75, 1, 0.99
FROM regional_specialties WHERE base_food_name = 'Banh-cay-Thai-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cay-Thai-Binh');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-cay-Thai-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cay-Thai-Binh' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Banh-cay-Thai-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cay-Thai-Binh' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cáy Thái Bình', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Canh-ca-Quynh-Coi', '100g/1 phần', 350, 18, 55, 7, 9.08, 482.44, 155.88, 75.24, 13.55, 0.77, 9.3, 0.0, 3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Canh Cá Quỳnh Côi', 'Canh-ca-Quynh-Coi', 1, 1, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Canh-ca-Quynh-Coi');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 350, 18, 7, 55, 3, 3.01
FROM regional_specialties WHERE base_food_name = 'Canh-ca-Quynh-Coi'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Canh-ca-Quynh-Coi');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Canh-ca-Quynh-Coi'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Canh-ca-Quynh-Coi' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Good'
FROM regional_specialties WHERE base_food_name = 'Canh-ca-Quynh-Coi'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Canh-ca-Quynh-Coi' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Canh Cá Quỳnh Côi', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Pho-bo-Nam-Dinh', '100g/1 phần', 460, 26, 56, 16, 9.91, 274.48, 256.96, 24.14, 33.54, 0.46, 17.38, 0.0, 3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Phở Bò Nam Định', 'Pho-bo-Nam-Dinh', 1, 1, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Pho-bo-Nam-Dinh');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 460, 26, 16, 56, 3, 2.29
FROM regional_specialties WHERE base_food_name = 'Pho-bo-Nam-Dinh'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Pho-bo-Nam-Dinh');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Pho-bo-Nam-Dinh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Pho-bo-Nam-Dinh' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Pho-bo-Nam-Dinh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Pho-bo-Nam-Dinh' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Bò Nam Định', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Nem-nam-Giao-Thuy', '100g/1 phần', 320, 22, 10, 20, 2.18, 447.45, 104.41, 26.66, 17.39, 0.81, 5.81, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Nem Nắm Giao Thủy', 'Nem-nam-Giao-Thuy', 1, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Nem-nam-Giao-Thuy');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 320, 22, 20, 10, 2, 2.76
FROM regional_specialties WHERE base_food_name = 'Nem-nam-Giao-Thuy'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-nam-Giao-Thuy');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Nem-nam-Giao-Thuy'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-nam-Giao-Thuy' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Nem-nam-Giao-Thuy'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-nam-Giao-Thuy' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Nắm Giao Thủy', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Thit-de-Ninh-Binh', '100g/1 phần', 210, 28, 0, 10, 4.05, 320.95, 244.04, 65.91, 13.53, 0.89, 16.42, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Thịt Dê Núi Ninh Bình', 'Thit-de-Ninh-Binh', 1, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Thit-de-Ninh-Binh');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 210, 28, 10, 0, 0, 2.61
FROM regional_specialties WHERE base_food_name = 'Thit-de-Ninh-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-de-Ninh-Binh');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Good'
FROM regional_specialties WHERE base_food_name = 'Thit-de-Ninh-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-de-Ninh-Binh' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Thit-de-Ninh-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-de-Ninh-Binh' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Dê Núi Ninh Bình', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Com-chay-Ninh-Binh', '100g/1 phần', 480, 8, 65, 22, 7.43, 171.42, 119.84, 94.65, 42.45, 0.8, 18.89, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cơm Cháy Ninh Bình', 'Com-chay-Ninh-Binh', 1, 2, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Com-chay-Ninh-Binh');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 480, 8, 22, 65, 2, 1.88
FROM regional_specialties WHERE base_food_name = 'Com-chay-Ninh-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-chay-Ninh-Binh');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Good'
FROM regional_specialties WHERE base_food_name = 'Com-chay-Ninh-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-chay-Ninh-Binh' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Com-chay-Ninh-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-chay-Ninh-Binh' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Cháy Ninh Bình', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ca-kho-Vu-Dai', '100g/1 phần', 340, 24, 5, 22, 9.68, 94.07, 130.74, 73.69, 36.65, 0.55, 0.38, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cá Kho Làng Vũ Đại', 'Ca-kho-Vu-Dai', 1, 7, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ca-kho-Vu-Dai');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 340, 24, 22, 5, 1, 1.01
FROM regional_specialties WHERE base_food_name = 'Ca-kho-Vu-Dai'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-kho-Vu-Dai');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Ca-kho-Vu-Dai'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-kho-Vu-Dai' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ca-kho-Vu-Dai'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-kho-Vu-Dai' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Kho Làng Vũ Đại', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-phu-the-Dinh-Bang', '100g/1 phần', 260, 2, 58, 4, 8.4, 55.04, 169.13, 37.27, 19.71, 0.91, 16.45, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Phu Thê Đình Bảng', 'Banh-phu-the-Dinh-Bang', 1, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-phu-the-Dinh-Bang');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 260, 2, 4, 58, 2, 1.59
FROM regional_specialties WHERE base_food_name = 'Banh-phu-the-Dinh-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-phu-the-Dinh-Bang');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Banh-phu-the-Dinh-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-phu-the-Dinh-Bang' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-phu-the-Dinh-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-phu-the-Dinh-Bang' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Phu Thê Đình Bảng', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-dau-xanh-Hai-Duong', '100g/1 phần', 420, 8, 60, 18, 9.95, 354.9, 272.87, 51.03, 5.09, 0.87, 2.29, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Đậu Xanh Hải Dương', 'Banh-dau-xanh-Hai-Duong', 1, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-dau-xanh-Hai-Duong');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 420, 8, 18, 60, 4, 0.86
FROM regional_specialties WHERE base_food_name = 'Banh-dau-xanh-Hai-Duong'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-dau-xanh-Hai-Duong');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-dau-xanh-Hai-Duong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-dau-xanh-Hai-Duong' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-dau-xanh-Hai-Duong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-dau-xanh-Hai-Duong' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đậu Xanh Hải Dương', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-gai-Ninh-Giang', '100g/1 phần', 310, 5, 65, 6, 9.78, 124.82, 273.72, 75.34, 33.86, 0.47, 14.1, 0.0, 5, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Gai Ninh Giang', 'Banh-gai-Ninh-Giang', 1, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-gai-Ninh-Giang');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 310, 5, 6, 65, 5, 2.69
FROM regional_specialties WHERE base_food_name = 'Banh-gai-Ninh-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-gai-Ninh-Giang');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-gai-Ninh-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-gai-Ninh-Giang' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-gai-Ninh-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-gai-Ninh-Giang' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Gai Ninh Giang', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ruoi-Tu-Ky', '100g/1 phần', 390, 18, 12, 28, 3.84, 384.71, 295.38, 87.97, 28.27, 0.37, 2.85, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Chả Rươi Tứ Kỳ', 'Ruoi-Tu-Ky', 1, 7, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ruoi-Tu-Ky');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 390, 18, 28, 12, 1, 2.15
FROM regional_specialties WHERE base_food_name = 'Ruoi-Tu-Ky'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ruoi-Tu-Ky');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ruoi-Tu-Ky'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ruoi-Tu-Ky' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Ruoi-Tu-Ky'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ruoi-Tu-Ky' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Rươi Tứ Kỳ', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ga-Dong-Tao', '100g/1 phần', 210, 25, 0, 12, 2.93, 320.01, 284.86, 96.29, 41.1, 0.81, 15.35, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Gà Đông Tảo Hưng Yên', 'Ga-Dong-Tao', 1, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ga-Dong-Tao');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 210, 25, 12, 0, 0, 1.7
FROM regional_specialties WHERE base_food_name = 'Ga-Dong-Tao'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-Dong-Tao');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ga-Dong-Tao'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-Dong-Tao' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Ga-Dong-Tao'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-Dong-Tao' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đông Tảo Hưng Yên', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Nhan-long-Hung-Yen', '100g/1 phần', 60, 1.3, 15, 0.1, 7.62, 114.83, 291.71, 70.01, 34.53, 0.57, 3.73, 0.0, 1.1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Nhãn Lồng Hưng Yên', 'Nhan-long-Hung-Yen', 1, 9, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Nhan-long-Hung-Yen');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 60, 1.3, 0.1, 15, 1.1, 3.46
FROM regional_specialties WHERE base_food_name = 'Nhan-long-Hung-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nhan-long-Hung-Yen');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Nhan-long-Hung-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nhan-long-Hung-Yen' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Good'
FROM regional_specialties WHERE base_food_name = 'Nhan-long-Hung-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nhan-long-Hung-Yen' AND ss.season_id = 3);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nhãn Lồng Hưng Yên', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-cuon-Phu-Ly', '100g/1 phần', 330, 14, 45, 12, 5.16, 139.25, 199.39, 81.35, 24.22, 0.21, 12.57, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Cuốn Phủ Lý', 'Banh-cuon-Phu-Ly', 1, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Phu-Ly');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 330, 14, 12, 45, 2, 2.63
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Phu-Ly'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Phu-Ly');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Phu-Ly'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Phu-Ly' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Phu-Ly'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Phu-Ly' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Phủ Lý', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ca-thinh-Lap-Thach', '100g/1 phần', 280, 22, 15, 14, 1.25, 82.72, 258.23, 20.84, 34.07, 0.22, 1.14, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cá Thính Lập Thạch', 'Ca-thinh-Lap-Thach', 1, 7, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ca-thinh-Lap-Thach');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 280, 22, 14, 15, 1, 0.79
FROM regional_specialties WHERE base_food_name = 'Ca-thinh-Lap-Thach'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-thinh-Lap-Thach');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Ca-thinh-Lap-Thach'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-thinh-Lap-Thach' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Ca-thinh-Lap-Thach'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-thinh-Lap-Thach' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Thính Lập Thạch', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-da-cua-Hai-Phong', '100g/1 phần', 410, 18, 55, 10, 9.78, 430.07, 178.62, 69.73, 30.84, 0.34, 18.54, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Đa Cua Hải Phòng', 'Banh-da-cua-Hai-Phong', 2, 1, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-da-cua-Hai-Phong');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 410, 18, 10, 55, 4, 0.78
FROM regional_specialties WHERE base_food_name = 'Banh-da-cua-Hai-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-da-cua-Hai-Phong');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Banh-da-cua-Hai-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-da-cua-Hai-Phong' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Good'
FROM regional_specialties WHERE base_food_name = 'Banh-da-cua-Hai-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-da-cua-Hai-Phong' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Đa Cua Hải Phòng', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Nem-cua-be', '100g/1 phần', 450, 16, 35, 25, 2.24, 310.45, 242.93, 20.32, 26.23, 0.71, 12.56, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Nem Cua Bể', 'Nem-cua-be', 2, 4, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Nem-cua-be');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 450, 16, 25, 35, 2, 1.76
FROM regional_specialties WHERE base_food_name = 'Nem-cua-be'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-cua-be');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Nem-cua-be'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-cua-be' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Nem-cua-be'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nem-cua-be' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Nem Cua Bể', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-mi-cay-Hai-Phong', '100g/1 phần', 220, 8, 30, 8, 5.01, 72.45, 243.78, 58.95, 17.63, 0.76, 14.0, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Mì Cay Hải Phòng', 'Banh-mi-cay-Hai-Phong', 2, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-mi-cay-Hai-Phong');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 220, 8, 8, 30, 1, 2.52
FROM regional_specialties WHERE base_food_name = 'Banh-mi-cay-Hai-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-mi-cay-Hai-Phong');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Good'
FROM regional_specialties WHERE base_food_name = 'Banh-mi-cay-Hai-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-mi-cay-Hai-Phong' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Banh-mi-cay-Hai-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-mi-cay-Hai-Phong' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Mì Cay Hải Phòng', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Cha-muc-Ha-Long', '100g/1 phần', 290, 20, 15, 16, 7.2, 353.26, 192.88, 93.32, 49.71, 0.66, 7.44, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Chả Mực Hạ Long', 'Cha-muc-Ha-Long', 2, 7, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Cha-muc-Ha-Long');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 290, 20, 16, 15, 1, 3.92
FROM regional_specialties WHERE base_food_name = 'Cha-muc-Ha-Long'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cha-muc-Ha-Long');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Cha-muc-Ha-Long'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cha-muc-Ha-Long' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Good'
FROM regional_specialties WHERE base_food_name = 'Cha-muc-Ha-Long'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cha-muc-Ha-Long' AND ss.season_id = 3);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Chả Mực Hạ Long', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Sa-sung-Quan-Lan', '100g/1 phần', 110, 20, 2, 1, 7.24, 217.91, 178.07, 53.25, 37.51, 0.81, 18.82, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Sá Sùng Nấu Phở', 'Sa-sung-Quan-Lan', 2, 7, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Sa-sung-Quan-Lan');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 110, 20, 1, 2, 0, 2.4
FROM regional_specialties WHERE base_food_name = 'Sa-sung-Quan-Lan'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Sa-sung-Quan-Lan');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Sa-sung-Quan-Lan'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Sa-sung-Quan-Lan' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Sa-sung-Quan-Lan'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Sa-sung-Quan-Lan' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Sá Sùng Nấu Phở', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ngan-bien', '100g/1 phần', 80, 5, 2, 0, 7.49, 305.38, 183.63, 72.95, 37.47, 0.33, 3.48, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Rượu Ngán Quảng Ninh', 'Ngan-bien', 2, 10, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ngan-bien');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 80, 5, 0, 2, 0, 2.39
FROM regional_specialties WHERE base_food_name = 'Ngan-bien'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ngan-bien');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Ngan-bien'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ngan-bien' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Good'
FROM regional_specialties WHERE base_food_name = 'Ngan-bien'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ngan-bien' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Ngán Quảng Ninh', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ga-Tien-Yen', '100g/1 phần', 195, 24, 0, 10, 9.17, 328.47, 264.9, 99.6, 46.28, 0.75, 3.35, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Gà Đồi Tiên Yên', 'Ga-Tien-Yen', 2, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ga-Tien-Yen');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 195, 24, 10, 0, 0, 3.6
FROM regional_specialties WHERE base_food_name = 'Ga-Tien-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-Tien-Yen');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Good'
FROM regional_specialties WHERE base_food_name = 'Ga-Tien-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-Tien-Yen' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ga-Tien-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-Tien-Yen' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đồi Tiên Yên', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Khau-nhuc-Lang-Son', '100g/1 phần', 550, 15, 10, 50, 6.28, 232.97, 117.08, 87.48, 28.71, 0.13, 8.34, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Khâu Nhục Lạng Sơn', 'Khau-nhuc-Lang-Son', 2, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Khau-nhuc-Lang-Son');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 550, 15, 50, 10, 1, 2.38
FROM regional_specialties WHERE base_food_name = 'Khau-nhuc-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Khau-nhuc-Lang-Son');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Khau-nhuc-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Khau-nhuc-Lang-Son' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Khau-nhuc-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Khau-nhuc-Lang-Son' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Khâu Nhục Lạng Sơn', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Vit-quay-Lang-Son', '100g/1 phần', 380, 22, 5, 30, 6.53, 434.32, 247.49, 80.77, 6.2, 0.23, 11.84, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Vịt Quay Móc Mật Lạng Sơn', 'Vit-quay-Lang-Son', 2, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Vit-quay-Lang-Son');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 380, 22, 30, 5, 1, 3.95
FROM regional_specialties WHERE base_food_name = 'Vit-quay-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Vit-quay-Lang-Son');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Vit-quay-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Vit-quay-Lang-Son' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Vit-quay-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Vit-quay-Lang-Son' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vịt Quay Móc Mật Lạng Sơn', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Pho-chua-Lang-Son', '100g/1 phần', 350, 15, 50, 12, 7.19, 97.22, 259.82, 60.97, 34.15, 0.9, 0.89, 0.0, 3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Phở Chua Lạng Sơn', 'Pho-chua-Lang-Son', 2, 1, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Pho-chua-Lang-Son');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 350, 15, 12, 50, 3, 1.99
FROM regional_specialties WHERE base_food_name = 'Pho-chua-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Pho-chua-Lang-Son');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Pho-chua-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Pho-chua-Lang-Son' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Pho-chua-Lang-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Pho-chua-Lang-Son' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Phở Chua Lạng Sơn', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Hat-de-Trung-Khanh', '100g/1 phần', 240, 4, 50, 3, 6.68, 159.31, 175.27, 56.82, 2.56, 0.48, 4.87, 0.0, 5, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Hạt Dẻ Trùng Khánh', 'Hat-de-Trung-Khanh', 2, 9, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Hat-de-Trung-Khanh');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 240, 4, 3, 50, 5, 2.1
FROM regional_specialties WHERE base_food_name = 'Hat-de-Trung-Khanh'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Hat-de-Trung-Khanh');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Hat-de-Trung-Khanh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Hat-de-Trung-Khanh' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Hat-de-Trung-Khanh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Hat-de-Trung-Khanh' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Hạt Dẻ Trùng Khánh', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-cuon-Cao-Bang', '100g/1 phần', 310, 12, 48, 8, 1.69, 156.29, 129.47, 98.68, 28.4, 0.64, 12.98, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Cuốn Nước Xương Cao Bằng', 'Banh-cuon-Cao-Bang', 2, 1, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Cao-Bang');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 310, 12, 8, 48, 2, 1.72
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Cao-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Cao-Bang');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Cao-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Cao-Bang' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Banh-cuon-Cao-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-cuon-Cao-Bang' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Cuốn Nước Xương Cao Bằng', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Lap-xuong-Cao-Bang', '100g/1 phần', 480, 18, 8, 42, 9.5, 253.64, 223.49, 68.82, 40.96, 0.99, 3.68, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Lạp Xưởng Gác Bếp Cao Bằng', 'Lap-xuong-Cao-Bang', 2, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Lap-xuong-Cao-Bang');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 480, 18, 42, 8, 0, 2.23
FROM regional_specialties WHERE base_food_name = 'Lap-xuong-Cao-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lap-xuong-Cao-Bang');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Lap-xuong-Cao-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lap-xuong-Cao-Bang' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Lap-xuong-Cao-Bang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lap-xuong-Cao-Bang' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lạp Xưởng Gác Bếp Cao Bằng', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Mien-dong-Na-Ri', '100g/1 phần', 350, 1, 85, 0, 1.38, 459.91, 136.69, 18.14, 5.24, 0.14, 0.04, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Miến Dong Na Rì', 'Mien-dong-Na-Ri', 2, 8, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Mien-dong-Na-Ri');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 350, 1, 0, 85, 4, 1.91
FROM regional_specialties WHERE base_food_name = 'Mien-dong-Na-Ri'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mien-dong-Na-Ri');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Mien-dong-Na-Ri'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mien-dong-Na-Ri' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Mien-dong-Na-Ri'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mien-dong-Na-Ri' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Miến Dong Na Rì', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Cam-sanh-Ham-Yen', '100g/1 phần', 45, 0.8, 11, 0.2, 9.06, 489.6, 214.64, 69.06, 2.98, 0.62, 18.71, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cam Sành Hàm Yên', 'Cam-sanh-Ham-Yen', 2, 9, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Cam-sanh-Ham-Yen');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 45, 0.8, 0.2, 11, 2, 3.95
FROM regional_specialties WHERE base_food_name = 'Cam-sanh-Ham-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cam-sanh-Ham-Yen');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Cam-sanh-Ham-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cam-sanh-Ham-Yen' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Cam-sanh-Ham-Yen'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cam-sanh-Ham-Yen' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Sành Hàm Yên', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Mi-Chu-Bac-Giang', '100g/1 phần', 340, 3, 80, 0.5, 7.96, 272.15, 241.68, 28.47, 6.55, 0.79, 9.64, 0.0, 3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Mì Chũ Lục Ngạn', 'Mi-Chu-Bac-Giang', 2, 8, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Mi-Chu-Bac-Giang');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 340, 3, 0.5, 80, 3, 3.45
FROM regional_specialties WHERE base_food_name = 'Mi-Chu-Bac-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mi-Chu-Bac-Giang');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Mi-Chu-Bac-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mi-Chu-Bac-Giang' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Mi-Chu-Bac-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mi-Chu-Bac-Giang' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mì Chũ Lục Ngạn', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Vai-thieu-Luc-Ngan', '100g/1 phần', 66, 0.8, 16.5, 0.4, 4.41, 332.67, 210.59, 62.9, 41.34, 0.13, 8.2, 0.0, 1.3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Vải Thiều Lục Ngạn', 'Vai-thieu-Luc-Ngan', 2, 9, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Vai-thieu-Luc-Ngan');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 66, 0.8, 0.4, 16.5, 1.3, 3.62
FROM regional_specialties WHERE base_food_name = 'Vai-thieu-Luc-Ngan'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Vai-thieu-Luc-Ngan');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Vai-thieu-Luc-Ngan'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Vai-thieu-Luc-Ngan' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Vai-thieu-Luc-Ngan'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Vai-thieu-Luc-Ngan' AND ss.season_id = 3);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Vải Thiều Lục Ngạn', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-chung-Bo-Dau', '100g/1 phần', 580, 16, 75, 18, 2.25, 437.04, 148.31, 46.3, 28.78, 0.4, 0.35, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Chưng Bờ Đậu', 'Banh-chung-Bo-Dau', 2, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-chung-Bo-Dau');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 580, 16, 18, 75, 4, 2.38
FROM regional_specialties WHERE base_food_name = 'Banh-chung-Bo-Dau'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-chung-Bo-Dau');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Banh-chung-Bo-Dau'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-chung-Bo-Dau' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Banh-chung-Bo-Dau'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-chung-Bo-Dau' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Chưng Bờ Đậu', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Tra-Tan-Cuong', '100g/1 phần', 2, 0, 0.5, 0, 4.29, 63.43, 175.01, 74.1, 17.31, 0.8, 14.28, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Trà Tân Cương Thái Nguyên', 'Tra-Tan-Cuong', 2, 10, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Tra-Tan-Cuong');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 2, 0, 0, 0.5, 0, 1.36
FROM regional_specialties WHERE base_food_name = 'Tra-Tan-Cuong'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Tra-Tan-Cuong');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Tra-Tan-Cuong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Tra-Tan-Cuong' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Tra-Tan-Cuong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Tra-Tan-Cuong' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Trà Tân Cương Thái Nguyên', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Buoi-Doan-Hung', '100g/1 phần', 38, 0.7, 9.6, 0.1, 5.09, 252.17, 174.11, 89.0, 20.82, 0.45, 14.18, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bưởi Đoan Hùng', 'Buoi-Doan-Hung', 3, 9, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Buoi-Doan-Hung');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 38, 0.7, 0.1, 9.6, 1, 2.48
FROM regional_specialties WHERE base_food_name = 'Buoi-Doan-Hung'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Buoi-Doan-Hung');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Buoi-Doan-Hung'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Buoi-Doan-Hung' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Good'
FROM regional_specialties WHERE base_food_name = 'Buoi-Doan-Hung'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Buoi-Doan-Hung' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bưởi Đoan Hùng', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Thit-chua-Thanh-Son', '100g/1 phần', 260, 22, 8, 15, 4.85, 430.49, 268.32, 19.86, 3.47, 0.43, 0.12, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Thịt Chua Thanh Sơn', 'Thit-chua-Thanh-Son', 3, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Thit-chua-Thanh-Son');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 260, 22, 15, 8, 1, 2.6
FROM regional_specialties WHERE base_food_name = 'Thit-chua-Thanh-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-chua-Thanh-Son');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Thit-chua-Thanh-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-chua-Thanh-Son' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Thit-chua-Thanh-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-chua-Thanh-Son' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Chua Thanh Sơn', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Thang-co-Ha-Giang', '100g/1 phần', 410, 30, 10, 25, 4.94, 377.37, 171.06, 44.51, 11.96, 0.84, 2.12, 0.0, 2, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Thắng Cố Hà Giang', 'Thang-co-Ha-Giang', 3, 1, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Thang-co-Ha-Giang');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 410, 30, 25, 10, 2, 1.26
FROM regional_specialties WHERE base_food_name = 'Thang-co-Ha-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thang-co-Ha-Giang');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Thang-co-Ha-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thang-co-Ha-Giang' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Thang-co-Ha-Giang'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thang-co-Ha-Giang' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thắng Cố Hà Giang', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Chao-au-tau', '100g/1 phần', 280, 12, 45, 6, 1.11, 273.37, 258.78, 33.17, 37.05, 0.67, 18.28, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cháo Ấu Tẩu Hà Giang', 'Chao-au-tau', 3, 2, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Chao-au-tau');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 280, 12, 6, 45, 4, 0.69
FROM regional_specialties WHERE base_food_name = 'Chao-au-tau'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Chao-au-tau');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Chao-au-tau'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Chao-au-tau' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Chao-au-tau'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Chao-au-tau' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cháo Ấu Tẩu Hà Giang', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Banh-tam-giac-mach', '100g/1 phần', 310, 6, 60, 5, 4.63, 256.59, 163.83, 55.64, 22.61, 0.51, 2.28, 0.0, 6, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Bánh Tam Giác Mạch', 'Banh-tam-giac-mach', 3, 5, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Banh-tam-giac-mach');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 310, 6, 5, 60, 6, 0.55
FROM regional_specialties WHERE base_food_name = 'Banh-tam-giac-mach'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-tam-giac-mach');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Banh-tam-giac-mach'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-tam-giac-mach' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Banh-tam-giac-mach'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Banh-tam-giac-mach' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Bánh Tam Giác Mạch', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Lon-cap-nach', '100g/1 phần', 350, 20, 0, 28, 4.53, 231.15, 195.04, 16.47, 47.43, 0.18, 14.91, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Lợn Cắp Nách Quay', 'Lon-cap-nach', 3, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Lon-cap-nach');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 350, 20, 28, 0, 0, 2.38
FROM regional_specialties WHERE base_food_name = 'Lon-cap-nach'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lon-cap-nach');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Lon-cap-nach'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lon-cap-nach' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Lon-cap-nach'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lon-cap-nach' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Lợn Cắp Nách Quay', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ca-hoi-Sa-Pa', '100g/1 phần', 208, 20, 0, 13, 6.66, 189.93, 149.04, 52.39, 32.16, 0.6, 3.51, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cá Hồi Sa Pa Gỏi', 'Ca-hoi-Sa-Pa', 3, 7, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ca-hoi-Sa-Pa');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 208, 20, 13, 0, 0, 0.93
FROM regional_specialties WHERE base_food_name = 'Ca-hoi-Sa-Pa'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-hoi-Sa-Pa');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ca-hoi-Sa-Pa'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-hoi-Sa-Pa' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ca-hoi-Sa-Pa'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-hoi-Sa-Pa' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Hồi Sa Pa Gỏi', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Man-hau-Moc-Chau', '100g/1 phần', 46, 0.7, 11.4, 0.3, 4.52, 439.78, 219.78, 84.07, 46.77, 0.81, 1.78, 0.0, 1.4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Mận Hậu Mộc Châu', 'Man-hau-Moc-Chau', 3, 9, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Man-hau-Moc-Chau');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 46, 0.7, 0.3, 11.4, 1.4, 3.37
FROM regional_specialties WHERE base_food_name = 'Man-hau-Moc-Chau'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Man-hau-Moc-Chau');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Man-hau-Moc-Chau'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Man-hau-Moc-Chau' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Man-hau-Moc-Chau'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Man-hau-Moc-Chau' AND ss.season_id = 3);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Mận Hậu Mộc Châu', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Nep-Tu-Le', '100g/1 phần', 350, 7, 75, 2, 5.4, 398.59, 116.77, 91.59, 11.01, 0.14, 12.7, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Xôi Nếp Tú Lệ', 'Nep-Tu-Le', 3, 2, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Nep-Tu-Le');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 350, 7, 2, 75, 4, 1.01
FROM regional_specialties WHERE base_food_name = 'Nep-Tu-Le'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nep-Tu-Le');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Nep-Tu-Le'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nep-Tu-Le' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Nep-Tu-Le'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Nep-Tu-Le' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Tú Lệ', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Xoi-ngu-sac', '100g/1 phần', 360, 7, 76, 2, 6.41, 163.97, 178.21, 67.44, 19.74, 0.98, 19.02, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Xôi Ngũ Sắc', 'Xoi-ngu-sac', 3, 2, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Xoi-ngu-sac');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 360, 7, 2, 76, 4, 1.17
FROM regional_specialties WHERE base_food_name = 'Xoi-ngu-sac'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-ngu-sac');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Xoi-ngu-sac'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-ngu-sac' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Xoi-ngu-sac'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-ngu-sac' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Ngũ Sắc', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Thit-trau-gac-bep', '100g/1 phần', 310, 45, 5, 10, 2.96, 54.52, 215.23, 54.28, 24.59, 0.31, 14.01, 0.0, 1, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Thịt Trâu Gác Bếp Tây Bắc', 'Thit-trau-gac-bep', 3, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Thit-trau-gac-bep');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 310, 45, 10, 5, 1, 3.5
FROM regional_specialties WHERE base_food_name = 'Thit-trau-gac-bep'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-trau-gac-bep');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Thit-trau-gac-bep'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-trau-gac-bep' AND ss.season_id = 1);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Thit-trau-gac-bep'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Thit-trau-gac-bep' AND ss.season_id = 3);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Trâu Gác Bếp Tây Bắc', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ga-den-Tua-Chua', '100g/1 phần', 180, 25, 0, 8, 6.33, 273.94, 281.52, 51.42, 5.84, 0.3, 13.39, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Gà Đen Tủa Chùa Mường Then', 'Ga-den-Tua-Chua', 3, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ga-den-Tua-Chua');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 180, 25, 8, 0, 0, 2.65
FROM regional_specialties WHERE base_food_name = 'Ga-den-Tua-Chua'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-den-Tua-Chua');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ga-den-Tua-Chua'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-den-Tua-Chua' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Ga-den-Tua-Chua'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ga-den-Tua-Chua' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Gà Đen Tủa Chùa Mường Then', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Xoi-nep-nuong', '100g/1 phần', 370, 8, 78, 3, 4.26, 160.14, 247.15, 37.83, 35.58, 0.6, 5.49, 0.0, 4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Xôi Nếp Nương Điện Biên', 'Xoi-nep-nuong', 3, 2, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Xoi-nep-nuong');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 370, 8, 3, 78, 4, 2.72
FROM regional_specialties WHERE base_food_name = 'Xoi-nep-nuong'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-nep-nuong');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Xoi-nep-nuong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-nep-nuong' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Xoi-nep-nuong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Xoi-nep-nuong' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Xôi Nếp Nương Điện Biên', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ca-lang-Song-Da', '100g/1 phần', 180, 19, 0, 11, 1.53, 143.6, 178.61, 84.47, 49.94, 0.73, 11.7, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cá Lăng Sông Đà', 'Ca-lang-Song-Da', 3, 7, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ca-lang-Song-Da');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 180, 19, 11, 0, 0, 1.18
FROM regional_specialties WHERE base_food_name = 'Ca-lang-Song-Da'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-lang-Song-Da');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ca-lang-Song-Da'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-lang-Song-Da' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Ca-lang-Song-Da'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ca-lang-Song-Da' AND ss.season_id = 2);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cá Lăng Sông Đà', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Lon-man-Hoa-Binh', '100g/1 phần', 290, 18, 0, 24, 3.43, 271.76, 285.37, 26.64, 2.66, 0.77, 7.14, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Thịt Lợn Mán Hòa Bình', 'Lon-man-Hoa-Binh', 3, 6, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Lon-man-Hoa-Binh');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 290, 18, 24, 0, 0, 0.71
FROM regional_specialties WHERE base_food_name = 'Lon-man-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lon-man-Hoa-Binh');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Good'
FROM regional_specialties WHERE base_food_name = 'Lon-man-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lon-man-Hoa-Binh' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Lon-man-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Lon-man-Hoa-Binh' AND ss.season_id = 3);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Thịt Lợn Mán Hòa Bình', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Com-lam-Hoa-Binh', '100g/1 phần', 320, 6, 70, 2, 7.36, 220.47, 284.11, 78.42, 38.37, 0.65, 0.95, 0.0, 3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cơm Lam Hòa Bình', 'Com-lam-Hoa-Binh', 3, 2, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Com-lam-Hoa-Binh');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 320, 6, 2, 70, 3, 0.97
FROM regional_specialties WHERE base_food_name = 'Com-lam-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-lam-Hoa-Binh');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Com-lam-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-lam-Hoa-Binh' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Com-lam-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Com-lam-Hoa-Binh' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cơm Lam Hòa Bình', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Cam-Cao-Phong', '100g/1 phần', 47, 0.9, 12, 0.1, 6.28, 216.22, 154.66, 10.55, 14.56, 0.47, 12.92, 0.0, 2.4, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Cam Cao Phong Hòa Bình', 'Cam-Cao-Phong', 3, 9, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Cam-Cao-Phong');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 47, 0.9, 0.1, 12, 2.4, 0.81
FROM regional_specialties WHERE base_food_name = 'Cam-Cao-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cam-Cao-Phong');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Good'
FROM regional_specialties WHERE base_food_name = 'Cam-Cao-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cam-Cao-Phong' AND ss.season_id = 4);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Cam-Cao-Phong'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Cam-Cao-Phong' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Cam Cao Phong Hòa Bình', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Mang-dang-Tien-Son', '100g/1 phần', 20, 2, 4, 0.2, 2.61, 169.84, 164.21, 44.47, 37.7, 0.65, 7.65, 0.0, 3, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Măng Đắng Luộc', 'Mang-dang-Tien-Son', 3, 8, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Mang-dang-Tien-Son');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 20, 2, 0.2, 4, 3, 3.58
FROM regional_specialties WHERE base_food_name = 'Mang-dang-Tien-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mang-dang-Tien-Son');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 2, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Mang-dang-Tien-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mang-dang-Tien-Son' AND ss.season_id = 2);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 1, 'Excellent'
FROM regional_specialties WHERE base_food_name = 'Mang-dang-Tien-Son'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Mang-dang-Tien-Son' AND ss.season_id = 1);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Măng Đắng Luộc', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO nutrition_reference (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
VALUES ('Ruou-can-Hoa-Binh', '100g/1 phần', 120, 0.5, 15, 0, 6.2, 222.69, 273.9, 73.69, 0.81, 0.82, 1.71, 0.0, 0, 'Viện Dinh Dưỡng Quốc Gia');
INSERT INTO regional_specialties (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
SELECT 'Rượu Cần', 'Ruou-can-Hoa-Binh', 3, 10, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống'
WHERE NOT EXISTS (SELECT 1 FROM regional_specialties WHERE base_food_name = 'Ruou-can-Hoa-Binh');
INSERT INTO specialty_nutrition (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
SELECT specialty_id, 120, 0.5, 0, 15, 0, 3.83
FROM regional_specialties WHERE base_food_name = 'Ruou-can-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_nutrition sn JOIN regional_specialties rs ON sn.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ruou-can-Hoa-Binh');
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 3, 'Good'
FROM regional_specialties WHERE base_food_name = 'Ruou-can-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ruou-can-Hoa-Binh' AND ss.season_id = 3);
INSERT INTO specialty_seasons (specialty_id, season_id, quality_rating)
SELECT specialty_id, 4, 'Premium'
FROM regional_specialties WHERE base_food_name = 'Ruou-can-Hoa-Binh'
AND NOT EXISTS (SELECT 1 FROM specialty_seasons ss JOIN regional_specialties rs ON ss.specialty_id = rs.specialty_id WHERE rs.base_food_name = 'Ruou-can-Hoa-Binh' AND ss.season_id = 4);
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 1, 1, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 2, 2, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 3, 3, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 4, 4, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 5, 5, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 6, 6, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 7, 7, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 8, 8, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 9, 9, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 10, 10, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 11, 11, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');
INSERT OR IGNORE INTO season (food_name, food_type, region_code, month_start, month_end, note, source)
VALUES ('Rượu Cần', 'dac_san', 'bac', 12, 12, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri');