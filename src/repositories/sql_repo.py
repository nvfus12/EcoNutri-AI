import logging
import sqlite3
from contextlib import contextmanager
from datetime import datetime
from typing import Any, Dict, List, Optional


class SQLRepository:
    """Repository tổng hợp toàn bộ truy vấn SQL cho EcoNutri."""

    def __init__(self, db_path: str = "database/econutri.db"):
        self.db_path = db_path
        self._ensure_seasonal_catalog()

    @contextmanager
    def get_connection(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        except sqlite3.Error as exc:
            logging.error("Lỗi truy vấn Database: %s", exc)
            conn.rollback()
            raise
        finally:
            conn.close()

    def _ensure_seasonal_catalog(self) -> None:
        """Tạo bảng mùa vụ/đặc sản nếu thiếu và seed dữ liệu mẫu."""
        create_table_query = """
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
        """
        create_index_query = """
            CREATE INDEX IF NOT EXISTS idx_season_region_month
            ON season(region_code, month_start, month_end);
        """
        seed_rows = [
            ("Rau cai ngot", "rau", "bac", 10, 2, "Hop mua lanh", "local"),
            ("Rau cai thia", "rau", "bac", 11, 2, "Giau chat xo", "local"),
            ("Rau muong", "rau", "bac", 4, 9, "Pho bien mua nong", "local"),
            ("Sua hao", "rau", "bac", 11, 2, "Rau mua dong", "local"),
            ("Bun cha Ha Noi", "dac_san", "bac", 1, 12, "Dac san vung Bac", "local"),
            ("Cha ca La Vong", "dac_san", "bac", 1, 12, "Dac san vung Bac", "local"),
            ("Rau tap tang", "rau", "trung", 3, 8, "Mon rau dia phuong", "local"),
            ("Bau", "rau", "trung", 5, 10, "Mat cho mua he", "local"),
            ("Bi do", "rau", "trung", 9, 2, "Tot cho tieu hoa", "local"),
            ("Mi Quang", "dac_san", "trung", 1, 12, "Dac san mien Trung", "local"),
            ("Bun bo Hue", "dac_san", "trung", 1, 12, "Dac san mien Trung", "local"),
            ("Rau day", "rau", "nam", 5, 11, "Hop khi hau am", "local"),
            ("Rau den", "rau", "nam", 4, 10, "Pho bien o mien Nam", "local"),
            ("Bong bi", "rau", "nam", 6, 11, "Rau mua mua", "local"),
            ("Com tam Sai Gon", "dac_san", "nam", 1, 12, "Dac san mien Nam", "local"),
            ("Hu tieu Nam Vang", "dac_san", "nam", 1, 12, "Pho bien mien Nam", "local"),
        ]
        insert_query = """
            INSERT OR IGNORE INTO season
            (food_name, food_type, region_code, month_start, month_end, note, source)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """

        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(create_table_query)
            cursor.execute(create_index_query)
            cursor.executemany(insert_query, seed_rows)
            conn.commit()

    @staticmethod
    def _parse_month(at_time: Optional[Any]) -> int:
        if at_time is None:
            return datetime.now().month
        if isinstance(at_time, datetime):
            return at_time.month
        if isinstance(at_time, str):
            text = at_time.strip()
            try:
                return datetime.fromisoformat(text).month
            except ValueError:
                if len(text) == 7:
                    return datetime.strptime(text, "%Y-%m").month
                return datetime.strptime(text, "%Y-%m-%d").month
        raise ValueError("at_time phải là datetime hoặc chuỗi 'YYYY-MM-DD'/'YYYY-MM'.")

    @staticmethod
    def resolve_region_from_coordinates(lat: Optional[float]) -> str:
        """Xác định mã vùng (bac/trung/nam) dựa vào Vĩ độ (Latitude) của Việt Nam."""
        if lat is None or lat == 0.0:
            return "nam"

        if lat >= 19.0:
            return "bac"
        elif 11.5 <= lat < 19.0:
            return "trung"
        else:
            return "nam"

    @staticmethod
    def _month_to_season(month: int) -> str:
        if month in (2, 3, 4):
            return "spring"
        if month in (5, 6, 7):
            return "summer"
        if month in (8, 9, 10):
            return "autumn"
        return "winter"

    def create_user(self, user_data: Dict[str, Any]) -> int:
        """Thêm user profile mới vào bảng user_profile."""
        query = """
            INSERT INTO user_profile (
                name, age, gender, height_cm, weight_kg, job,
                activity_level, allergies, medical_conditions, goal,
                bmi, bmr, tdee, body_fat_percent
            )
            VALUES (
                :name, :age, :gender, :height_cm, :weight_kg, :job,
                :activity_level, :allergies, :medical_conditions, :goal,
                :bmi, :bmr, :tdee, :body_fat_percent
            )
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, user_data)
            conn.commit()
            return cursor.lastrowid

    def upsert_user_profile(self, user_id: int, user_data: Dict[str, Any]) -> int:
        """Tạo mới hoặc cập nhật hồ sơ người dùng theo user_id."""
        safe_data = {
            "name": user_data.get("name", "User"),
            "age": int(user_data.get("age", 0) or 0),
            "gender": user_data.get("gender", "other"),
            "height_cm": float(user_data.get("height_cm", 0) or 0),
            "weight_kg": float(user_data.get("weight_kg", 0) or 0),
            "job": user_data.get("job", ""),
            "activity_level": user_data.get("activity_level", "sedentary"),
            "allergies": user_data.get("allergies", ""),
            "medical_conditions": user_data.get("medical_conditions", ""),
            "goal": user_data.get("goal", "maintain"),
            "bmi": user_data.get("bmi"),
            "bmr": user_data.get("bmr"),
            "tdee": user_data.get("tdee"),
            "body_fat_percent": user_data.get("body_fat_percent"),
        }

        existing = self.get_user_profile(user_id)

        if existing:
            update_query = """
                UPDATE user_profile
                SET name = :name,
                    age = :age,
                    gender = :gender,
                    height_cm = :height_cm,
                    weight_kg = :weight_kg,
                    job = :job,
                    activity_level = :activity_level,
                    allergies = :allergies,
                    medical_conditions = :medical_conditions,
                    goal = :goal,
                    bmi = :bmi,
                    bmr = :bmr,
                    tdee = :tdee,
                    body_fat_percent = :body_fat_percent
                WHERE user_id = :user_id
            """
            payload = {**safe_data, "user_id": user_id}
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(update_query, payload)
                
                # Ghi nhận tự động lịch sử thay đổi cân nặng
                if safe_data["weight_kg"] > 0:
                    cursor.execute(
                        "INSERT INTO user_weight_history (user_id, weight_kg) VALUES (?, ?)",
                        (user_id, safe_data["weight_kg"])
                    )
                conn.commit()
            return user_id

        insert_query = """
            INSERT INTO user_profile (
                user_id, name, age, gender, height_cm, weight_kg, job,
                activity_level, allergies, medical_conditions, goal,
                    bmi, bmr, tdee, body_fat_percent
            )
            VALUES (
                :user_id, :name, :age, :gender, :height_cm, :weight_kg, :job,
                :activity_level, :allergies, :medical_conditions, :goal,
                    :bmi, :bmr, :tdee, :body_fat_percent
            )
        """
        payload = {**safe_data, "user_id": user_id}
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(insert_query, payload)
            
            # Ghi nhận tự động lịch sử thay đổi cân nặng
            if safe_data["weight_kg"] > 0:
                cursor.execute(
                    "INSERT INTO user_weight_history (user_id, weight_kg) VALUES (?, ?)",
                    (user_id, safe_data["weight_kg"])
                )
            conn.commit()
        return user_id

    def get_user_profile(self, user_id: int) -> Optional[Dict[str, Any]]:
        query = "SELECT * FROM user_profile WHERE user_id = ?"
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def get_nutrition_ref(self, food_name: str) -> Optional[Dict[str, Any]]:
        query = "SELECT * FROM nutrition_reference WHERE LOWER(food_name) = LOWER(?)"
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (food_name,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def search_nutrition_facts(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Tìm kiếm thông tin dinh dưỡng của các món ăn được nhắc đến trong câu hỏi."""
        if not query:
            return []
            
        import unicodedata
        # Bỏ dấu tiếng Việt để so khớp với dữ liệu dạng không dấu (slug) trong DB
        normalized_query = unicodedata.normalize('NFD', query).encode('ascii', 'ignore').decode('utf-8').lower()
        
        sql_query = """
            SELECT * 
            FROM nutrition_reference 
            WHERE ? LIKE '%' || LOWER(REPLACE(food_name, '-', ' ')) || '%'
               OR ? LIKE '%' || LOWER(food_name) || '%'
            LIMIT ?
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(sql_query, (normalized_query, normalized_query, limit))
            return [dict(row) for row in cursor.fetchall()]

    def save_vision_log(self, user_id: int, food_name: str, calories: float, image_path: str) -> int:
        query = """
            INSERT INTO nutrition_diary (user_id, food_name, calories, image_path, created_at)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id, food_name, calories, image_path))
            conn.commit()
            return cursor.lastrowid

    def save_diary(self, user_id: int, vision_res: Any, meal_type: str = "auto_detect") -> int:
        """Lưu toàn bộ detected_items từ VisionResult vào nutrition_diary."""
        query = """
            INSERT INTO nutrition_diary (
                user_id, food_name, meal_type, portion_g,
                calories, protein, carb, fat, sugar,
                sodium, potassium, calcium,
                vitamin_a, vitamin_b, vitamin_c, vitamin_d,
                image_path, created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            inserted = 0
            for item in getattr(vision_res, "detected_items", []):
                cursor.execute(
                    query,
                    (
                        user_id,
                        getattr(item, "food_name", "unknown"),
                        meal_type,
                        None,
                        float(getattr(item, "calories", 0.0) or 0.0),
                        float(getattr(item, "protein", 0.0) or 0.0),
                        float(getattr(item, "carb", 0.0) or 0.0),
                        float(getattr(item, "fat", 0.0) or 0.0),
                        float(getattr(item, "sugar", 0.0) or 0.0),
                        float(getattr(item, "sodium", 0.0) or 0.0),
                        float(getattr(item, "potassium", 0.0) or 0.0),
                        float(getattr(item, "calcium", 0.0) or 0.0),
                        float(getattr(item, "vitamin_a", 0.0) or 0.0),
                        float(getattr(item, "vitamin_b", 0.0) or 0.0),
                        float(getattr(item, "vitamin_c", 0.0) or 0.0),
                        float(getattr(item, "vitamin_d", 0.0) or 0.0),
                        getattr(vision_res, "image_path", None),
                    ),
                )
                inserted += 1

            conn.commit()
            return inserted

    def get_recent_diary(self, user_id: int, limit: int = 5) -> List[Dict[str, Any]]:
        query = """
            SELECT diary_id, food_name, meal_type, calories, protein, carb, fat, image_path, created_at
            FROM nutrition_diary
            WHERE user_id = ?
            ORDER BY created_at DESC
            LIMIT ?
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id, limit))
            return [dict(row) for row in cursor.fetchall()]

    def get_daily_calories(self, user_id: int, date_str: str) -> float:
        query = """
            SELECT SUM(calories) as total_cal
            FROM nutrition_diary
            WHERE user_id = ? AND DATE(created_at) = ?
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id, date_str))
            result = cursor.fetchone()
            return float(result["total_cal"] or 0.0) if result else 0.0

    def get_weight_history(self, user_id: int) -> List[Dict[str, Any]]:
        query = """
            SELECT weight_kg, recorded_at 
            FROM user_weight_history 
            WHERE user_id = ? 
            ORDER BY recorded_at ASC
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id,))
            return [dict(row) for row in cursor.fetchall()]

    def get_nutrition_history(self, user_id: int) -> List[Dict[str, Any]]:
        query = """
            SELECT calories, protein, created_at 
            FROM nutrition_diary 
            WHERE user_id = ? 
            ORDER BY created_at ASC
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user_id,))
            return [dict(row) for row in cursor.fetchall()]

    def get_user_meal_history(self, user_id: int, limit: int = 10) -> List[Dict[str, Any]]:
        return self.get_recent_diary(user_id=user_id, limit=limit)

    def get_seasonal_foods(
        self,
        region_code: str = "nam",
        at_time: Optional[Any] = None,
        food_type: Optional[str] = None,
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        """Truy vấn danh sách rau/đặc sản theo vùng và thời gian."""
        month = self._parse_month(at_time)

        with self.get_connection() as conn:
            cursor = conn.cursor()
            
            if food_type == "dac_san":
                # Bản nâng cấp: Gộp dữ liệu từ bảng chuẩn hoá và bảng phẳng (season)
                zone_map = {"bac": "Bắc", "trung": "Trung", "nam": "Nam"}
                zone_keyword = f"%{zone_map.get(region_code, '')}%"
                
                query = """
                    SELECT rs.specialty_name as food_name, 
                           'dac_san' as food_type, 
                           ? as region_code, 
                           s.month_start, 
                           s.month_end, 
                           rs.peak_harvest_note as note,
                           'Từ hệ thống chuẩn hoá' as source
                    FROM regional_specialties rs
                    JOIN regions r ON rs.region_id = r.region_id
                    JOIN specialty_seasons ss ON rs.specialty_id = ss.specialty_id
                    JOIN seasons s ON ss.season_id = s.season_id
                    WHERE r.geographic_zone LIKE ?
                      AND (
                            (s.month_start <= s.month_end AND ? BETWEEN s.month_start AND s.month_end)
                            OR
                            (s.month_start > s.month_end AND (? >= s.month_start OR ? <= s.month_end))
                      )
                    UNION
                    SELECT food_name, food_type, region_code, month_start, month_end, note, source
                    FROM season
                    WHERE region_code = ? AND food_type = 'dac_san'
                      AND (
                            (month_start <= month_end AND ? BETWEEN month_start AND month_end)
                            OR
                            (month_start > month_end AND (? >= month_start OR ? <= month_end))
                      )
                    ORDER BY food_name ASC
                    LIMIT ?
                """
                params = [
                    region_code, zone_keyword, month, month, month,
                    region_code, month, month, month,
                    limit
                ]
                cursor.execute(query, params)
            else:
                base_query = """
                    SELECT food_name, food_type, region_code, month_start, month_end, note, source
                    FROM season
                    WHERE region_code = ?
                """
                params: List[Any] = [region_code]
                
                if food_type:
                    base_query += " AND food_type = ?"
                    params.append(food_type)
                    
                base_query += """
                  AND (
                        (month_start <= month_end AND ? BETWEEN month_start AND month_end)
                        OR
                        (month_start > month_end AND (? >= month_start OR ? <= month_end))
                  )
                  ORDER BY food_name ASC LIMIT ?
                """
                params.extend([month, month, month, limit])
                cursor.execute(base_query, params)
                
            return [dict(row) for row in cursor.fetchall()]

    def get_personalized_seasonal_recommendations(
        self,
        user_id: Optional[int] = None,
        at_time: Optional[Any] = None,
        limit: int = 10,
        lat: Optional[float] = None,
    ) -> Dict[str, Any]:
        """
        Method tổng hợp theo user + vùng + thời gian.
        Trả về cả rau và đặc sản phù hợp cho ngữ cảnh hiện tại.
        """
        month = self._parse_month(at_time)
        region_code = self.resolve_region_from_coordinates(lat)

        vegetables = self.get_seasonal_foods(
            region_code=region_code,
            at_time=at_time,
            food_type="rau",
            limit=limit,
        )
        specialties = self.get_seasonal_foods(
            region_code=region_code,
            at_time=at_time,
            food_type="dac_san",
            limit=limit,
        )

        return {
            "latitude": lat,
            "region_code": region_code,
            "month": month,
            "season": self._month_to_season(month),
            "vegetables": vegetables,
            "specialties": specialties,
        }


# Compatibility alias để các module cũ vẫn hoạt động.
SQLiteRepo = SQLRepository

# Instance dùng chung toàn hệ thống
db_repo = SQLRepository()