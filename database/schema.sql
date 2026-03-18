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
