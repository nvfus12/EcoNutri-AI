import sqlite3
import os
import sys
import logging
from pathlib import Path

# Thêm thư mục gốc vào sys.path để import được src
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.core.config import settings

# Cấu hình logging để dễ dàng theo dõi quá trình chạy script
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def initialize_database():
    """
    Hàm đọc file schema.sql và thực thi để khởi tạo database.
    """
    # Kiểm tra xem file schema có tồn tại không
    schema_path = settings.BASE_DIR / "database" / "schema.sql"
    if not schema_path.exists():
        logging.error(f"Không tìm thấy file cấu trúc cơ sở dữ liệu tại: {schema_path}")
        return

    # Tạo thư mục database nếu chưa tồn tại
    os.makedirs(settings.DB_PATH.parent, exist_ok=True)

    logging.info(f"Bắt đầu khởi tạo cơ sở dữ liệu: {settings.DB_PATH}")

    # Đọc nội dung file schema.sql
    try:
        with open(schema_path, "r", encoding="utf-8") as f:
            schema_script = f.read()
    except Exception as e:
        logging.error(f"Lỗi khi đọc file {schema_path}: {e}")
        return

    # Kết nối tới SQLite và thực thi script
    try:
        # Connect sẽ tự động tạo file econutri.db nếu nó chưa có
        with sqlite3.connect(settings.DB_PATH) as conn:
            cursor = conn.cursor()
            
            # Sử dụng executescript để chạy nhiều câu lệnh SQL cùng lúc (CREATE, INSERT...)
            cursor.executescript(schema_script)
            
            conn.commit()
            logging.info("Khởi tạo cơ sở dữ liệu THÀNH CÔNG! Các bảng đã được tạo.")
            
    except sqlite3.Error as e:
        logging.error(f"Lỗi khi thực thi SQLite: {e}")
    except Exception as e:
        logging.error(f"Đã xảy ra lỗi không xác định: {e}")

if __name__ == "__main__":
    # Chỉ chạy hàm khởi tạo khi file này được gọi trực tiếp
    initialize_database()