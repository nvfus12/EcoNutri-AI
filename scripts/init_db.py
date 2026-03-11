import sqlite3
import os
import logging

# Cấu hình logging để dễ dàng theo dõi quá trình chạy script
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Định nghĩa đường dẫn file (giả sử script được chạy từ thư mục gốc của project)
DB_PATH = os.path.join("database", "econutri.db")
SCHEMA_PATH = os.path.join("database", "schema.sql")

def initialize_database():
    """
    Hàm đọc file schema.sql và thực thi để khởi tạo database.
    """
    # Kiểm tra xem file schema có tồn tại không
    if not os.path.exists(SCHEMA_PATH):
        logging.error(f"Không tìm thấy file cấu trúc cơ sở dữ liệu tại: {SCHEMA_PATH}")
        return

    # Tạo thư mục database nếu chưa tồn tại
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    logging.info(f"Bắt đầu khởi tạo cơ sở dữ liệu: {DB_PATH}")

    # Đọc nội dung file schema.sql
    try:
        with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
            schema_script = f.read()
    except Exception as e:
        logging.error(f"Lỗi khi đọc file {SCHEMA_PATH}: {e}")
        return

    # Kết nối tới SQLite và thực thi script
    try:
        # Connect sẽ tự động tạo file econutri.db nếu nó chưa có
        with sqlite3.connect(DB_PATH) as conn:
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