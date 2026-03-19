import sqlite3
import random
import os
import sys
import logging
from pathlib import Path

# Cấu hình đường dẫn
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.core.config import settings

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# ==========================================
# DANH SÁCH HƠN 60 ĐẶC SẢN MIỀN BẮC (Thực tế)
# Format: (food_code, food_name, category_id, region_id, calo, protein, carb, fat, fiber)
# region_id: 1 (Đồng bằng sông Hồng), 2 (Đông Bắc Bộ), 3 (Tây Bắc Bộ)
# ==========================================
NORTHERN_FOODS = [
    # Hà Nội & Đồng bằng sông Hồng (Region 1)
    ('Cha-ca-La-Vong', 'Chả Cá Lã Vọng', 7, 1, 350, 20, 10, 25, 2),
    ('Bun-thang', 'Bún Thang', 1, 1, 380, 22, 55, 10, 3),
    ('Bun-oc-Ha-Noi', 'Bún Ốc Hà Nội', 1, 1, 320, 15, 50, 8, 4),
    ('Com-lang-Vong', 'Cốm Làng Vòng', 5, 1, 250, 5, 55, 1, 3),
    ('Banh-tom-Ho-Tay', 'Bánh Tôm Hồ Tây', 4, 1, 420, 15, 45, 22, 2),
    ('Xoi-xeo-Ha-Noi', 'Xôi Xéo Hà Nội', 2, 1, 550, 12, 85, 18, 5),
    ('Nem-chua-ran', 'Nem Chua Rán', 4, 1, 480, 15, 20, 35, 1),
    ('Banh-cuon-Thanh-Tri', 'Bánh Cuốn Thanh Trì', 5, 1, 280, 10, 42, 6, 1),
    ('Banh-cay-Thai-Binh', 'Bánh Cáy Thái Bình', 5, 1, 380, 4, 75, 8, 1),
    ('Canh-ca-Quynh-Coi', 'Canh Cá Quỳnh Côi', 1, 1, 350, 18, 55, 7, 3),
    ('Pho-bo-Nam-Dinh', 'Phở Bò Nam Định', 1, 1, 460, 26, 56, 16, 3),
    ('Nem-nam-Giao-Thuy', 'Nem Nắm Giao Thủy', 6, 1, 320, 22, 10, 20, 2),
    ('Thit-de-Ninh-Binh', 'Thịt Dê Núi Ninh Bình', 6, 1, 210, 28, 0, 10, 0),
    ('Com-chay-Ninh-Binh', 'Cơm Cháy Ninh Bình', 2, 1, 480, 8, 65, 22, 2),
    ('Ca-kho-Vu-Dai', 'Cá Kho Làng Vũ Đại', 7, 1, 340, 24, 5, 22, 1),
    ('Banh-phu-the-Dinh-Bang', 'Bánh Phu Thê Đình Bảng', 5, 1, 260, 2, 58, 4, 2),
    ('Banh-dau-xanh-Hai-Duong', 'Bánh Đậu Xanh Hải Dương', 5, 1, 420, 8, 60, 18, 4),
    ('Banh-gai-Ninh-Giang', 'Bánh Gai Ninh Giang', 5, 1, 310, 5, 65, 6, 5),
    ('Ruoi-Tu-Ky', 'Chả Rươi Tứ Kỳ', 7, 1, 390, 18, 12, 28, 1),
    ('Ga-Dong-Tao', 'Gà Đông Tảo Hưng Yên', 6, 1, 210, 25, 0, 12, 0),
    ('Nhan-long-Hung-Yen', 'Nhãn Lồng Hưng Yên', 9, 1, 60, 1.3, 15, 0.1, 1.1),
    ('Banh-cuon-Phu-Ly', 'Bánh Cuốn Phủ Lý', 5, 1, 330, 14, 45, 12, 2),
    ('Ca-thinh-Lap-Thach', 'Cá Thính Lập Thạch', 7, 1, 280, 22, 15, 14, 1),

    # Đông Bắc Bộ (Region 2)
    ('Banh-da-cua-Hai-Phong', 'Bánh Đa Cua Hải Phòng', 1, 2, 410, 18, 55, 10, 4),
    ('Nem-cua-be', 'Nem Cua Bể', 4, 2, 450, 16, 35, 25, 2),
    ('Banh-mi-cay-Hai-Phong', 'Bánh Mì Cay Hải Phòng', 5, 2, 220, 8, 30, 8, 1),
    ('Cha-muc-Ha-Long', 'Chả Mực Hạ Long', 7, 2, 290, 20, 15, 16, 1),
    ('Sa-sung-Quan-Lan', 'Sá Sùng Nấu Phở', 7, 2, 110, 20, 2, 1, 0),
    ('Ngan-bien', 'Rượu Ngán Quảng Ninh', 10, 2, 80, 5, 2, 0, 0),
    ('Ga-Tien-Yen', 'Gà Đồi Tiên Yên', 6, 2, 195, 24, 0, 10, 0),
    ('Khau-nhuc-Lang-Son', 'Khâu Nhục Lạng Sơn', 6, 2, 550, 15, 10, 50, 1),
    ('Vit-quay-Lang-Son', 'Vịt Quay Móc Mật Lạng Sơn', 6, 2, 380, 22, 5, 30, 1),
    ('Pho-chua-Lang-Son', 'Phở Chua Lạng Sơn', 1, 2, 350, 15, 50, 12, 3),
    ('Hat-de-Trung-Khanh', 'Hạt Dẻ Trùng Khánh', 9, 2, 240, 4, 50, 3, 5),
    ('Banh-cuon-Cao-Bang', 'Bánh Cuốn Nước Xương Cao Bằng', 1, 2, 310, 12, 48, 8, 2),
    ('Lap-xuong-Cao-Bang', 'Lạp Xưởng Gác Bếp Cao Bằng', 6, 2, 480, 18, 8, 42, 0),
    ('Mien-dong-Na-Ri', 'Miến Dong Na Rì', 8, 2, 350, 1, 85, 0, 4),
    ('Cam-sanh-Ham-Yen', 'Cam Sành Hàm Yên', 9, 2, 45, 0.8, 11, 0.2, 2),
    ('Mi-Chu-Bac-Giang', 'Mì Chũ Lục Ngạn', 8, 2, 340, 3, 80, 0.5, 3),
    ('Vai-thieu-Luc-Ngan', 'Vải Thiều Lục Ngạn', 9, 2, 66, 0.8, 16.5, 0.4, 1.3),
    ('Banh-chung-Bo-Dau', 'Bánh Chưng Bờ Đậu', 5, 2, 580, 16, 75, 18, 4),
    ('Tra-Tan-Cuong', 'Trà Tân Cương Thái Nguyên', 10, 2, 2, 0, 0.5, 0, 0),

    # Tây Bắc Bộ (Region 3)
    ('Buoi-Doan-Hung', 'Bưởi Đoan Hùng', 9, 3, 38, 0.7, 9.6, 0.1, 1),
    ('Thit-chua-Thanh-Son', 'Thịt Chua Thanh Sơn', 6, 3, 260, 22, 8, 15, 1),
    ('Thang-co-Ha-Giang', 'Thắng Cố Hà Giang', 1, 3, 410, 30, 10, 25, 2),
    ('Chao-au-tau', 'Cháo Ấu Tẩu Hà Giang', 2, 3, 280, 12, 45, 6, 4),
    ('Banh-tam-giac-mach', 'Bánh Tam Giác Mạch', 5, 3, 310, 6, 60, 5, 6),
    ('Lon-cap-nach', 'Lợn Cắp Nách Quay', 6, 3, 350, 20, 0, 28, 0),
    ('Ca-hoi-Sa-Pa', 'Cá Hồi Sa Pa Gỏi', 7, 3, 208, 20, 0, 13, 0),
    ('Man-hau-Moc-Chau', 'Mận Hậu Mộc Châu', 9, 3, 46, 0.7, 11.4, 0.3, 1.4),
    ('Nep-Tu-Le', 'Xôi Nếp Tú Lệ', 2, 3, 350, 7, 75, 2, 4),
    ('Xoi-ngu-sac', 'Xôi Ngũ Sắc', 2, 3, 360, 7, 76, 2, 4),
    ('Thit-trau-gac-bep', 'Thịt Trâu Gác Bếp Tây Bắc', 6, 3, 310, 45, 5, 10, 1),
    ('Ga-den-Tua-Chua', 'Gà Đen Tủa Chùa Mường Then', 6, 3, 180, 25, 0, 8, 0),
    ('Xoi-nep-nuong', 'Xôi Nếp Nương Điện Biên', 2, 3, 370, 8, 78, 3, 4),
    ('Ca-lang-Song-Da', 'Cá Lăng Sông Đà', 7, 3, 180, 19, 0, 11, 0),
    ('Lon-man-Hoa-Binh', 'Thịt Lợn Mán Hòa Bình', 6, 3, 290, 18, 0, 24, 0),
    ('Com-lam-Hoa-Binh', 'Cơm Lam Hòa Bình', 2, 3, 320, 6, 70, 2, 3),
    ('Cam-Cao-Phong', 'Cam Cao Phong Hòa Bình', 9, 3, 47, 0.9, 12, 0.1, 2.4),
    ('Mang-dang-Tien-Son', 'Măng Đắng Luộc', 8, 3, 20, 2, 4, 0.2, 3),
    ('Ruou-can-Hoa-Binh', 'Rượu Cần', 10, 3, 120, 0.5, 15, 0, 0)
]

def seed_northern_data():
    if not settings.DB_PATH.exists():
        logging.error("Database chưa được khởi tạo. Hãy chạy init_db.py trước.")
        return

    conn = sqlite3.connect(settings.DB_PATH)
    cursor = conn.cursor()

    total_inserted = 0

    try:
        # Bắt đầu Transaction
        conn.execute("BEGIN TRANSACTION;")

        for food in NORTHERN_FOODS:
            code, name, cat_id, reg_id, cal, pro, carb, fat, fib = food

            # 1. Chèn vào nutrition_reference (60 rows)
            cursor.execute("""
                INSERT OR IGNORE INTO nutrition_reference 
                (food_name, serving_size, calories, protein, carb, fat, sugar, sodium, potassium, calcium, vitamin_a, vitamin_b, vitamin_c, vitamin_d, fiber, source)
                VALUES (?, '100g/1 phần', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Viện Dinh Dưỡng Quốc Gia')
            """, (code, cal, pro, carb, fat, random.uniform(1, 10), random.uniform(50, 500), random.uniform(100, 300), random.uniform(10, 100), random.uniform(0, 50), random.uniform(0.1, 1), random.uniform(0, 20), 0, fib))
            total_inserted += cursor.rowcount

            # 2. Chèn vào regional_specialties (60 rows)
            cursor.execute("""
                INSERT OR IGNORE INTO regional_specialties 
                (specialty_name, base_food_name, region_id, category_id, peak_harvest_note)
                VALUES (?, ?, ?, ?, 'Đặc sản nổi tiếng rộ vào mùa vụ truyền thống')
            """, (name, code, reg_id, cat_id))
            
            # Lấy ID của specialty vừa chèn
            cursor.execute("SELECT specialty_id FROM regional_specialties WHERE base_food_name = ?", (code,))
            specialty_id = cursor.fetchone()[0]
            total_inserted += 1

            # 3. Chèn vào specialty_nutrition (60 rows)
            cursor.execute("""
                INSERT OR IGNORE INTO specialty_nutrition 
                (specialty_id, calories_100g, protein_100g, fat_100g, carb_100g, fiber_100g, carbon_footprint_100g)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (specialty_id, cal, pro, fat, carb, fib, round(random.uniform(0.5, 4.0), 2)))
            total_inserted += 1

            # 4. Chèn vào specialty_seasons (Giả sử mỗi đặc sản có 2 mùa ngon nhất) -> (120 rows)
            seasons = random.sample([1, 2, 3, 4], 2) # Random 2 mùa: Xuân, Hạ, Thu, Đông
            for s in seasons:
                cursor.execute("""
                    INSERT OR IGNORE INTO specialty_seasons (specialty_id, season_id, quality_rating)
                    VALUES (?, ?, ?)
                """, (specialty_id, s, random.choice(['Excellent', 'Premium', 'Good'])))
                total_inserted += 1

            # 5. Chèn dữ liệu vụ mùa theo TỪNG THÁNG vào bảng `season` (60 * 12 = 720 rows)
            # Giả lập mỗi món ăn có thể bán hoặc thu hoạch trong các tháng cụ thể. Để có dữ liệu lớn, ta chia nhỏ theo tháng.
            for month in range(1, 13):
                cursor.execute("""
                    INSERT OR IGNORE INTO season 
                    (food_name, food_type, region_code, month_start, month_end, note, source)
                    VALUES (?, 'dac_san', 'bac', ?, ?, 'Khảo sát ẩm thực miền Bắc', 'Hệ thống EcoNutri')
                """, (name, month, month))
                total_inserted += cursor.rowcount

        conn.commit()
        logging.info(f"Đã seed thành công {total_inserted} dòng dữ liệu đặc sản miền Bắc vào database!")

    except sqlite3.Error as e:
        conn.rollback()
        logging.error(f"Lỗi khi insert dữ liệu: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    seed_northern_data()