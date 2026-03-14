from pathlib import Path
from src.repositories.sql_repo import SQLRepository
from src.utils.image_processor import ImageProcessor
from src.services.user_service import UserService

class ContextOrchestrator:
    def __init__(self, vision_engine, sql_repo, vector_repo, llm_engine):
        self.vision_engine = vision_engine
        self.sql_repo = sql_repo
        self.vector_repo = vector_repo
        self.llm_engine = llm_engine
        self.img_processor = ImageProcessor()
        self.user_service = UserService()

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
        
        # 3. Tra cứu dinh dưỡng & tính toán - calculator.py (gọi qua repo)
        for item in vision_res.detected_items:
            data = self.sql_repo.get_nutrition_ref(item.food_name)
            if data:
                for key, val in data.items(): setattr(item, key, val)
        
        vision_res.update_totals()
        
        # 4. Lưu nhật ký
        self.sql_repo.save_diary(user_id, vision_res)
        
        return vision_res

    def get_personalized_advice(self, user_id: int, user_query: str, current_vision_res=None):
        """Luồng 2C: Gom Context (Profile + Diary + Season + RAG) -> LLM"""
        # 1. Lấy Profile & Nhật ký gần đây
        profile = self.sql_repo.get_user_profile(user_id)
        history = self.sql_repo.get_recent_diary(user_id, limit=5)
        
        # 2. Lấy rau + đặc sản theo vùng và thời gian hiện tại
        user_location = profile.get("location") if profile else None
        seasonal_info = self.sql_repo.get_personalized_seasonal_recommendations(
            user_id=user_id,
            location=user_location,
            at_time=None,
            limit=6,
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
        
        # 4. Hợp nhất ngữ cảnh thành Prompt (Dựa trên configs/prompts.yaml)
        context = {
            "profile": profile,
            "recent_history": history,
            "current_meal": current_vision_res.dict() if current_vision_res else "N/A",
            "seasonal_tips": seasonal_info,
            "medical_knowledge": kb_context
        }
        
        # 5. Thực thi LLM (Qwen 2.5/3.5 GGUF)
        if self.llm_engine is not None:
            answer = self.llm_engine.generate(user_query, context)
            if answer and str(answer).strip():
                return answer
            return "LLM đã xử lý nhưng chưa tạo được câu trả lời. Bạn thử hỏi cụ thể hơn về mục tiêu dinh dưỡng nhé."

        veg_names = [item.get("food_name") for item in seasonal_info.get("vegetables", [])][:3]
        specialty_names = [item.get("food_name") for item in seasonal_info.get("specialties", [])][:3]
        return (
            "Hệ thống đang chạy fallback vì chưa nạp LLM engine. "
            f"Vùng: {seasonal_info.get('region_code')} - Mùa: {seasonal_info.get('season')}. "
            f"Rau gợi ý: {', '.join(veg_names) if veg_names else 'chưa có dữ liệu'}. "
            f"Đặc sản gợi ý: {', '.join(specialty_names) if specialty_names else 'chưa có dữ liệu'}."
        )