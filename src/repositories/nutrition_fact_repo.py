import logging
import re
import sqlite3
import unicodedata
from contextlib import contextmanager
from typing import Any, Dict, List

from src.repositories.sql_repo import SQLRepository


class NutritionFactRepository:
    """Tra cứu số liệu dinh dưỡng từ database 'econutri.db' thay vì file CSV/JSON rời rạc."""

    def __init__(self):
        # Không cần init data_dir hay csv nữa, dùng thẳng SQLRepo
        # Mặc định SQLRepo đã trỏ tới database/econutri.db trong config của nó
        self.sql_repo = SQLRepository()

    @staticmethod
    def _normalize(text: str) -> str:
        if not text:
            return ""
        # Chuẩn hóa tiếng Việt, bỏ dấu, lower case
        text = unicodedata.normalize("NFD", str(text).lower())
        text = "".join(ch for ch in text if unicodedata.category(ch) != "Mn")
        text = re.sub(r"\s+", " ", text).strip()
        return text

    def search_by_query(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """
        Tìm kiếm món ăn trong bảng 'nutrition_reference' của SQLite.
        Logic: Tìm theo tên món (LIKE %query%) hoặc khớp từ khóa chính.
        """
        qn = self._normalize(query)
        if not qn or len(qn) < 2:
            return []

        results = []
        try:
            with self.sql_repo.get_connection() as conn:
                # 1. Tìm ưu tiên: Tên món chứa đúng cụm từ query (độ chính xác cao nhất)
                # Ví dụ query="pho bo" -> WHERE food_name LIKE '%pho bo%'
                # Lưu ý: Cần đảm bảo bảng nutrition_reference trong DB đã có cột food_name chuẩn hóa hoặc tìm tương đối
                # Ở đây giả định cột food_name lưu tiếng Việt có dấu/hoặc không dấu tùy data gốc
                
                # Cách tốt nhất: Tìm theo LIKE %query% (chấp nhận query không dấu tìm món có dấu khó khăn nếu DB chưa chuẩn hóa)
                # Giải pháp nhanh: Tìm LIKE %query%
                
                sql_pattern = f"%{qn}%"
                cursor = conn.execute(
                    """
                    SELECT food_name, calories, protein, carb, fat, fiber, source
                    FROM nutrition_reference
                    WHERE food_name LIKE ? OR food_name LIKE ?
                    LIMIT ?
                    """,
                    (sql_pattern, sql_pattern.title(), limit) # Tìm thường và In hoa chữ cái đầu
                )
                
                rows = cursor.fetchall()
                for row in rows:
                    results.append(dict(row))

                # 2. Fallback: Nếu không thấy (hoặc ít quá), thử tìm theo từ khóa dài nhất trong query
                if len(results) < limit:
                    keywords = [k for k in qn.split() if len(k) >= 3]
                    if keywords:
                        # Lấy từ khóa dài nhất làm trọng tâm (ví dụ "pho" trong "an pho")
                        main_keyword = max(keywords, key=len)
                        
                        # Tránh query lại trùng lặp nếu keyword chính là toàn bộ query
                        if main_keyword != qn:
                            fallback_pattern = f"%{main_keyword}%"
                            remain_limit = limit - len(results)
                            cursor = conn.execute(
                                """
                                SELECT food_name, calories, protein, carb, fat, fiber, source
                                FROM nutrition_reference
                                WHERE food_name LIKE ?
                                LIMIT ?
                                """,
                                (fallback_pattern, remain_limit)
                            )
                            fallback_rows = cursor.fetchall()
                            
                            # Deduplicate (tránh trùng món đã có ở bước 1)
                            existing_names = {r["food_name"] for r in results}
                            for row in fallback_rows:
                                if row["food_name"] not in existing_names:
                                    results.append(dict(row))

        except Exception as e:
            logging.error(f"Lỗi tìm kiếm dinh dưỡng trong DB (NutritionFactRepo): {e}")
            return []

        return results
