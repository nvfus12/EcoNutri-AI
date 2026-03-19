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
    # Bảng ánh xạ YOLO labels (không dấu) sang tiếng Việt có dấu chuẩn
    # Đảm bảo LLM nhận được context đúng chính tả, không bị nhiễm "thói quen" viết không dấu
    FOOD_NAME_MAP = {
        "bun cha": "Bún chả",
        "bun cha ha noi": "Bún chả Hà Nội",
        "bun bo hue": "Bún bò Huế",
        "bun dau mam tom": "Bún đậu mắm tôm",
        "pho": "Phở",
        "banh mi": "Bánh mì",
        "com tam": "Cơm tấm",
        "com tam sai gon": "Cơm tấm Sài Gòn",
        "mi quang": "Mì Quảng",
        "hu tieu": "Hủ tiếu",
        "hu tieu nam vang": "Hủ tiếu Nam Vang",
        "banh cuon": "Bánh cuốn",
        "banh xeo": "Bánh xèo",
        "xoi": "Xôi",
        "ca kho": "Cá kho",
        "thit kho": "Thịt kho",
        "rau muong": "Rau muống",
        "bap cai": "Bắp cải",
        "su hao": "Su hào",
        "rau ngot": "Rau ngót",
        "rau cai": "Rau cải"
    }

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
                # Hỗ trợ an toàn cho cả trường hợp kết quả trả về là float hoặc dict
                bmi_val = bmi_res.get("bmi", bmi_res) if isinstance(bmi_res, dict) else bmi_res
                user_data["bmi"] = bmi_val
                
                bmr = NutritionCalculator.calculate_bmr(weight, height, age, gender)
                user_data["bmr"] = bmr
                
                tdee = NutritionCalculator.calculate_tdee(bmr, activity_level)
                user_data["tdee"] = tdee
                
                body_fat = NutritionCalculator.estimate_body_fat(bmi_val, age, gender)
                user_data["body_fat_percent"] = body_fat
            except Exception as e:
                import logging
                logging.error(f"Lỗi tính toán chỉ số cơ thể: {e}")
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
            raw_yolo_name = getattr(item, "food_name", "")
            
            # Bước 3.1: Vẫn dùng tên không dấu của YOLO để tra cứu DB an toàn
            data = self.sql_repo.get_nutrition_ref(raw_yolo_name)
            if data:
                for key, val in data.items():
                    if hasattr(item, key):  # Chốt chặn an toàn: Chỉ gán nếu trường tồn tại trong Schema
                        setattr(item, key, val)
                        
            # Bước 3.2: CHUẨN HÓA TÊN CÓ DẤU TRƯỚC KHI LƯU VÀO NHẬT KÝ VÀ UI
            norm_name = raw_yolo_name.lower().strip()
            if norm_name in self.FOOD_NAME_MAP:
                item.food_name = self.FOOD_NAME_MAP[norm_name]
            elif norm_name:
                item.food_name = raw_yolo_name.capitalize() # Viết hoa chữ cái đầu nếu không có trong Map
        
        vision_res.update_totals()
        
        # 4. Lưu nhật ký
        self.sql_repo.save_diary(user_id, vision_res)
        
        return vision_res

    def get_personalized_advice(self, user_id: int, user_query: str, current_vision_res=None, recent_chat=None, user_lat=None, user_lon=None):
        """Luồng 2C: Gom Context (Profile + Diary + Season + RAG) -> LLM"""
        # Bước 1: Chặn các truy vấn không an toàn trước khi xử lý
        safety_result = self.safety_router.route(user_query)
        if safety_result.get("is_unsafe"):
            def safety_stream():
                text = safety_result.get("response", "")
                for i in range(0, len(text), 4):
                    yield text[i:i+4]
                    time.sleep(0.015)
            return (safety_stream(), {})

        # --- TỐI ƯU HÓA: PHÂN TÍCH Ý ĐỊNH NGƯỜI DÙNG ĐỂ GIẢM TẢI TRUY VẤN ---
        query_norm = self.llm_engine._normalize_for_intent(user_query) if self.llm_engine else user_query.lower()
        
        # Bước 2: Lấy context mặc định (luôn cần)
        profile = self.sql_repo.get_user_profile(user_id)
        history = self.sql_repo.get_recent_diary(user_id, limit=5)
        
        # Chuẩn hóa lại lịch sử ngay trong lúc nạp Context (đề phòng dữ liệu cũ từ DB chưa có dấu)
        for h in history:
            fname = str(h.get("food_name", "")).lower().strip()
            if fname in self.FOOD_NAME_MAP:
                h["food_name"] = self.FOOD_NAME_MAP[fname]
        current_time = datetime.now().strftime("%d/%m/%Y %H:%M")
        
        # Bước 3: Lấy context có điều kiện dựa trên ý định của câu hỏi
        kb_context = {}
        seasonal_info = {}
        structured_facts = []
        current_weather = "Không rõ" # Chỉ lấy khi cần

        # Ý định gợi ý món ăn (hôm nay ăn gì, gợi ý món) -> Cần thông tin mùa vụ + thời tiết
        is_suggestion_query = bool(re.search(r"\b(goi y|an gi|mon nao|thuc don|hom nay)\b", query_norm))
        if is_suggestion_query:
            seasonal_info = self.sql_repo.get_personalized_seasonal_recommendations(
                user_id=user_id, at_time=None, limit=6, lat=user_lat
            )
            current_weather = WeatherService.get_current_weather(lat=user_lat, lon=user_lon)

        # Ý định tra cứu kiến thức (hỏi đáp, định nghĩa, so sánh) -> Cần RAG
        is_knowledge_query = bool(re.search(r"\b(la gi|the nao|co tot khong|nen an|can tranh|so sanh|vi sao|tai sao)\b", query_norm))
        if self.vector_repo and (is_knowledge_query or not is_suggestion_query): # Chạy RAG nếu là câu hỏi kiến thức hoặc không rõ ý định
            kb_context = self.vector_repo.search(user_query)
        
        # Ý định tra cứu dinh dưỡng cụ thể (bao nhiêu calo) -> Cần DB dinh dưỡng
        if self._is_numeric_nutrition_query(user_query):
            structured_facts = self.sql_repo.search_nutrition_facts(user_query, limit=5)
            # Với câu hỏi cần số liệu mà không có dữ liệu tin cậy thì không gọi LLM để tránh bịa số.
            has_docs = bool(kb_context.get("documents"))
            if not structured_facts and not has_docs:
                def numeric_fallback_stream():
                    yield "Hiện tại EcoNutri chưa có dữ liệu dinh dưỡng đáng tin cậy cho món ăn bạn hỏi. Bạn có thể thử với các món phổ biến khác nhé."
                return (numeric_fallback_stream(), {})
        
        # Bước 4: Hợp nhất toàn bộ ngữ cảnh đã thu thập
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
        
        # Bước 5: Thực thi LLM
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