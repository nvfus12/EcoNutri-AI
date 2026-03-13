import os
from src.engines.vision_engine import VisionEngine
from src.repositories.sql_repo import SQLRepository
from src.repositories.vector_repo import VectorRepository
from src.utils.image_processor import ImageProcessor
from src.services.user_service import UserService

class ContextOrchestrator:
    def __init__(self, vision_engine, sql_repo, vector_repo, llm_engine):
        self.vision_engine = vision_engine
        self.sql_repo = sql_repo
        self.vector_repo = vector_repo
        self.llm_engine = llm_engine
        self.img_processor = ImageProcessor()
        self.user_service = UserService(sql_repo)

    def process_full_vision_flow(self, raw_image_path: str, user_id: int):
        """Luồng 2B: Tiền xử lý -> Nhận diện -> Đối chiếu DB -> Lưu Diary"""
        # 1. Tiền xử lý ảnh (Resize, Enhance) - image_processor.py
        processed_img_path = self.img_processor.preprocess(raw_image_path)
        
        # 2. Nhận diện (Inference) - vision_engine.py
        vision_res = self.vision_engine.predict(processed_img_path)
        
        # 3. Tra cứu dinh dưỡng & tính toán - calculator.py (gọi qua repo)
        for item in vision_res.detected_items:
            data = self.sql_repo.get_nutrition_ref(item.food_name)
            if data:
                for key, val in data.items(): setattr(item, key, val)
        
        vision_res.update_totals()
        
        # 4. Lưu nhật ký - diary_service.py logic
        self.sql_repo.save_diary(user_id, vision_res)
        
        return vision_res

    def get_personalized_advice(self, user_id: int, user_query: str, current_vision_res=None):
        """Luồng 2C: Gom Context (Profile + Diary + Season + RAG) -> LLM"""
        # 1. Lấy Profile & Nhật ký gần đây
        profile = self.user_service.get_profile(user_id)
        history = self.sql_repo.get_recent_diary(user_id, limit=5)
        
        # 2. Lấy đặc sản vùng miền theo mùa - Luồng Season
        seasonal_info = self.user_service.get_seasonal_recommendations(profile['location'])
        
        # 3. Truy xuất tri thức y khoa - RAG
        kb_context = self.vector_repo.search(user_query)
        
        # 4. Hợp nhất ngữ cảnh thành Prompt (Dựa trên configs/prompts.yaml)
        context = {
            "profile": profile,
            "recent_history": history,
            "current_meal": current_vision_res.dict() if current_vision_res else "N/A",
            "seasonal_tips": seasonal_info,
            "medical_knowledge": kb_context
        }
        
        # 5. Thực thi LLM (Qwen 2.5/3.5 GGUF)
        response = self.llm_engine.generate(user_query, context)
        return response