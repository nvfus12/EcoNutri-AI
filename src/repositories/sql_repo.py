import sqlite3
import logging
from contextlib import contextmanager
from typing import List, Dict, Any, Optional

# File này chịu trách nhiệm giao tiếp ĐỘC QUYỀN với database/econutri.db
# Các hàm trong này sẽ được orchestrator.py gọi để lấy context.

class SQLiteRepo:
    def __init__(self, db_path: str = "database/econutri.db"):
        self.db_path = db_path

    @contextmanager
    def get_connection(self):
        """
        Quản lý kết nối tới SQLite một cách an toàn.
        Sử dụng sqlite3.Row để trả về dữ liệu dưới dạng Dictionary thay vì Tuple.
        """
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        except sqlite3.Error as e:
            logging.error(f"Lỗi truy vấn Database: {e}")
            conn.rollback()
            raise
        finally:
            conn.close()

    # ==========================================
    # 1. QUẢN LÝ NGƯỜI DÙNG (Mapping với user_schema.py)
    # ==========================================

    def create_user(self, user_data: Dict[str, Any]) -> int:
        """
        Thêm người dùng mới vào hệ thống.
        user_data có thể bao gồm: name, age, weight, height, daily_calories_goal...
        """
        query = """
            INSERT INTO users (name, age, weight, height, daily_calories_goal)
            VALUES (:name, :age, :weight, :height, :daily_calories_goal)
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, user_data)
            conn.commit()
            return cursor.lastrowid

    def get_user_profile(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Lấy thông tin profile của user để tính toán dinh dưỡng."""
        query = "SELECT * FROM users WHERE id = ?"
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    # ==========================================
    # 2. QUẢN LÝ LỊCH SỬ ĂN UỐNG (Mapping với vision_schema.py)
    # ==========================================

    def save_vision_log(self, user_id: int, food_name: str, calories: float, image_path: str) -> int:
        """
        Lưu kết quả detect từ YOLO (vision_engine.py) vào database.
        Ghi nhận món ăn người dùng đã chụp và lượng calo tương ứng.
        """
        query = """
            INSERT INTO meal_logs (user_id, food_name, calories, image_path, created_at)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id, food_name, calories, image_path))
            conn.commit()
            return cursor.lastrowid

    def get_daily_calories(self, user_id: int, date_str: str) -> float:
        """
        Tính tổng calo mà người dùng đã tiêu thụ trong một ngày.
        date_str format: 'YYYY-MM-DD'
        Phục vụ cho Dashboard hiển thị trên Streamlit.
        """
        query = """
            SELECT SUM(calories) as total_cal 
            FROM meal_logs 
            WHERE user_id = ? AND date(created_at) = ?
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id, date_str))
            result = cursor.fetchone()
            return result["total_cal"] if result and result["total_cal"] else 0.0

    def get_user_meal_history(self, user_id: int, limit: int = 10) -> List[Dict[str, Any]]:
        """Lấy danh sách các món ăn gần đây user đã quét."""
        query = """
            SELECT id, food_name, calories, image_path, created_at 
            FROM meal_logs 
            WHERE user_id = ? 
            ORDER BY created_at DESC 
            LIMIT ?
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id, limit))
            return [dict(row) for row in cursor.fetchall()]

# Khởi tạo sẵn một instance để các module khác (như orchestrator.py) có thể import và dùng luôn
db_repo = SQLiteRepo()