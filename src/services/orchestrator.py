from pathlib import Path
from src.repositories.sql_repo import SQLRepository
from src.utils.image_processor import ImageProcessor
from src.services.user_service import UserService
from src.services.safety_router import SafetyRouter
from src.engines.calculator import NutritionCalculator
from src.services.weather_service import WeatherService
from datetime import datetime
import re
import time

class ContextOrchestrator:
    def __init__(self, vision_engine, sql_repo, vector_repo, llm_engine):
        self.vision_engine = vision_engine
        self.sql_repo = sql_repo
        self.vector_repo = vector_repo
        self.llm_engine = llm_engine
        self.img_processor = ImageProcessor()
        self.user_service = UserService()
        self.safety_router = SafetyRouter()

    @staticmethod
    def _is_numeric_nutrition_query(text: str) -> bool:
        lowered = (text or "").lower()
        return bool(
            re.search(
                r"\b(calo|kcal|protein|carb|fat|chat\s*beo|chat\s*dam|bao\s*nhieu|dinh\s*duong)\b",
                lowered,
            )
        )

    def get_user_profile(self, user_id: int):
        """Ủy quyền lấy hồ sơ người dùng (Tránh UI gọi trực tiếp DB)."""
        return self.sql_repo.get_user_profile(user_id)

    def upsert_user_profile(self, user_id: int, user_data: dict):
        """Tự động tính toán chỉ số cơ thể trước khi lưu hồ sơ xuống DB."""
        weight = float(user_data.get("weight_kg", 0) or 0)
        height = float(user_data.get("height_cm", 0) or 0)
        age = int(user_data.get("age", 0) or 0)
        gender = user_data.get("gender", "other")
        activity_level = user_data.get("activity_level", "sedentary")
        
        # Chỉ tính toán khi người dùng đã nhập đủ số đo cơ bản
        if weight > 0 and height > 0 and age > 0:
            try:
                bmi_res = NutritionCalculator.calculate_bmi(weight, height)
                user_data["bmi"] = bmi_res["bmi"]
                
                bmr = NutritionCalculator.calculate_bmr(weight, height, age, gender)
                user_data["bmr"] = bmr
                
                tdee = NutritionCalculator.calculate_tdee(bmr, activity_level)
                user_data["tdee"] = tdee
                
                body_fat = NutritionCalculator.estimate_body_fat(bmi_res["bmi"], age, gender)
                user_data["body_fat_percent"] = body_fat
            except Exception:
                pass  # Bỏ qua nếu có lỗi ngoại lệ (vd: thiếu constants)

        return self.sql_repo.upsert_user_profile(user_id, user_data)

    def get_macro_targets(self, tdee: float, goal: str):
        return NutritionCalculator.get_macro_targets(tdee, goal)

    def get_weight_history(self, user_id: int):
        return self.sql_repo.get_weight_history(user_id)

    def get_nutrition_history(self, user_id: int):
        return self.sql_repo.get_nutrition_history(user_id)

    def get_user_diary(self, user_id: int, limit: int = 50):
        """Ủy quyền lấy nhật ký ăn uống của người dùng."""
        return self.sql_repo.get_recent_diary(user_id, limit)

    def get_daily_calories(self, user_id: int, date_str: str):
        return self.sql_repo.get_daily_calories(user_id, date_str)

    def process_full_vision_flow(self, raw_image_path: str, user_id: int):
        """Luồng 2B: Tiền xử lý -> Nhận diện -> Đối chiếu DB -> Lưu Diary"""
        if self.vision_engine is None:
            raise RuntimeError("Vision engine chưa được khởi tạo. Hãy nạp YOLO trước khi phân tích ảnh.")

        # 1. Tiền xử lý ảnh (hỗ trợ UploadedFile từ Streamlit, bytes hoặc path)
        if hasattr(raw_image_path, "read") and hasattr(raw_image_path, "name"):
            raw_bytes = raw_image_path.read()
            processed_img = self.img_processor.process_upload(
                raw_bytes=raw_bytes,
                filename=raw_image_path.name,
                user_id=user_id,
            )
        elif isinstance(raw_image_path, (bytes, bytearray)):
            processed_img = self.img_processor.process_upload(
                raw_bytes=bytes(raw_image_path),
                filename=f"capture_{user_id}.jpg",
                user_id=user_id,
            )
        else:
            processed_img = self.img_processor.process_from_path(Path(raw_image_path), user_id=user_id)
        
        # 2. Nhận diện (Inference) - vision_engine.py
        vision_res = self.vision_engine.predict(str(processed_img.saved_path))
        vision_res.image_path = str(processed_img.saved_path)
        
        # --- BỘ LỌC ĐỘ TIN CẬY (CONFIDENCE FILTER) ---
        # Chặn các nhận diện sai (False Positive) như khuôn mặt thành món ăn
        MIN_CONFIDENCE = 0.7  
        filtered_items = []
        for item in vision_res.detected_items:
            conf = getattr(item, "confidence", 1.0)
            if conf is None or conf >= MIN_CONFIDENCE:
                filtered_items.append(item)
        vision_res.detected_items = filtered_items

        # Nếu không nhận diện được món ăn nào, xóa ảnh vật lý và bỏ qua việc lưu DB
        if not vision_res.detected_items:
            try:
                path_to_remove = Path(processed_img.saved_path)
                if path_to_remove.exists():
                    path_to_remove.unlink()
            except Exception:
                pass
            vision_res.image_path = None
            return vision_res

        # 3. Tra cứu dinh dưỡng & tính toán - calculator.py (gọi qua repo)
        for item in vision_res.detected_items:
            data = self.sql_repo.get_nutrition_ref(item.food_name)
            if data:
                for key, val in data.items():
                    if hasattr(item, key):  # Chốt chặn an toàn: Chỉ gán nếu trường tồn tại trong Schema
                        setattr(item, key, val)
        
        vision_res.update_totals()
        
        # 4. Lưu nhật ký
        self.sql_repo.save_diary(user_id, vision_res)
        
        return vision_res

    def get_personalized_advice(self, user_id: int, user_query: str, current_vision_res=None, recent_chat=None, user_lat=None, user_lon=None):
        """Luồng 2C: Gom Context (Profile + Diary + Season + RAG) -> LLM"""
        # 1. Lấy Profile & Nhật ký gần đây
        profile = self.sql_repo.get_user_profile(user_id)

        # 1.1. Chặn truy vấn y khoa/không an toàn trước khi vào LLM.
        safety_result = self.safety_router.route(user_query)
        if safety_result.get("is_unsafe"):
            def safety_stream():
                text = safety_result.get("response", "")
                for i in range(0, len(text), 4):
                    yield text[i:i+4]
                    time.sleep(0.015)
            return (safety_stream(), {})

        history = self.sql_repo.get_recent_diary(user_id, limit=5)
        
        # 2. Lấy rau + đặc sản theo vùng và thời gian hiện tại
        
        current_time = datetime.now().strftime("%d/%m/%Y %H:%M")
        current_weather = WeatherService.get_current_weather(lat=user_lat, lon=user_lon)

        seasonal_info = self.sql_repo.get_personalized_seasonal_recommendations(
            user_id=user_id,
            at_time=None,
            limit=6,
            lat=user_lat,
        )
        
        # 3. Truy xuất tri thức y khoa - RAG
        if self.vector_repo is not None:
            kb_context = self.vector_repo.search(user_query)
        else:
            kb_context = {
                "documents": [],
                "metadatas": [],
                "ids": [],
                "notice": "Vector repository chưa khởi tạo, đang chạy chế độ không RAG.",
            }

        structured_facts = self.sql_repo.search_nutrition_facts(user_query, limit=5)

        # Với câu hỏi cần số liệu mà không có dữ liệu tin cậy thì không gọi LLM để tránh bịa số.
        if self._is_numeric_nutrition_query(user_query):
            has_docs = bool(kb_context.get("documents"))
            if not structured_facts and not has_docs:
                return (
                    "Data not available: Hiện chưa có dữ liệu định lượng đáng tin cậy cho truy vấn này."
                )
        
        # 4. Hợp nhất ngữ cảnh thành Prompt (Dựa trên configs/prompts.yaml)
        context = {
            "current_time": current_time,
            "current_weather": current_weather,
            "profile": profile,
            "recent_history": history,
            "current_meal": current_vision_res.dict() if current_vision_res else "N/A",
            "seasonal_tips": seasonal_info,
            "medical_knowledge": kb_context,
            "structured_facts": structured_facts,
            "recent_chat": (recent_chat or [])[-8:],
        }
        
        # 5. Thực thi LLM (Qwen 2.5/3.5 GGUF)
        if self.llm_engine is not None:
            # Trả về stream và context để UI xử lý hậu kỳ (gắn suffix)
            if hasattr(self.llm_engine, "generate_stream"):
                answer_stream = self.llm_engine.generate_stream(user_query, context)
                return (answer_stream, context)

            if hasattr(self.llm_engine, "generate"):
                def _compat_stream():
                    yield self.llm_engine.generate(user_query, context)

                return (_compat_stream(), context)

        # Fallback nếu LLM engine không có sẵn
        def fallback_stream():
            veg_names = [item.get("food_name") for item in seasonal_info.get("vegetables", [])][:3]
            specialty_names = [item.get("food_name") for item in seasonal_info.get("specialties", [])][:3]
            fallback_text = (
                "Hệ thống đang chạy fallback vì chưa nạp LLM engine. "
                f"Vùng: {seasonal_info.get('region_code')} - Mùa: {seasonal_info.get('season')}. "
                f"Rau gợi ý: {', '.join(veg_names) if veg_names else 'chưa có dữ liệu'}. "
                f"Đặc sản gợi ý: {', '.join(specialty_names) if specialty_names else 'chưa có dữ liệu'}."
            )
            yield fallback_text
        
        return (fallback_stream(), {})

    def get_advice_suffix(self, context, response_text: str = ""):
        """Lấy phần phụ lục (citations, warnings) từ LLM engine."""
        if self.llm_engine and context:
            return self.llm_engine.get_response_suffix(context, response_text)
        return ""