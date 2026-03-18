import importlib
import os
import re
import unicodedata
import time
from pathlib import Path
from typing import Any, Dict
import yaml

from src.core.config import settings

class LocalLLMEngine:
    """Wrapper mỏng cho llama-cpp để dùng chung với orchestrator."""

    def __init__(self, model_path: Path, n_ctx: int = 4096):
        llama_module = importlib.import_module("llama_cpp")
        llama_cls = getattr(llama_module, "Llama")
        self.model = llama_cls(
            model_path=str(model_path), 
            n_ctx=n_ctx, 
            n_threads=max(1, os.cpu_count() - 1),  # Dùng tối đa CPU trừ 1 luồng cho HĐH
            n_gpu_layers=-1,  # Đẩy toàn bộ layers lên GPU nếu có. Đặt = 0 nếu chỉ muốn dùng CPU.
            verbose=False
        )
        self.prompts = self._load_prompts()

    def _load_prompts(self) -> Dict[str, str]:
        prompt_path = settings.BASE_DIR / "configs" / "prompts.yaml"
        if prompt_path.exists():
            with open(prompt_path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        return {}

    @staticmethod
    def _missing_profile_fields(profile: Dict[str, Any]) -> list[str]:
        field_map = {
            "age": "tuổi",
            "gender": "giới tính",
            "height_cm": "chiều cao",
            "weight_kg": "cân nặng",
            "activity_level": "mức vận động",
            "goal": "mục tiêu",
        }
        missing = []
        for key, label in field_map.items():
            value = profile.get(key)
            if value in (None, "", 0):
                missing.append(label)
        return missing

    @staticmethod
    def _safe_float(value: Any) -> float:
        try:
            return float(value)
        except Exception:
            return 0.0

    @staticmethod
    def _extract_weight_goal_kg(query: str) -> tuple[float | None, float | None]:
        """Tách mục tiêu cân nặng dạng 'từ 50 cân xuống 48 cân' hoặc '50kg -> 48kg'."""
        if not query:
            return None, None

        text = query.lower().replace(",", ".")

        patterns = [
            r"tu\s*(\d+(?:\.\d+)?)\s*(?:kg|kilo|c[aâ]n)?\s*(?:xuong|xuong|ve|về|->|to)\s*(\d+(?:\.\d+)?)\s*(?:kg|kilo|c[aâ]n)?",
            r"(\d+(?:\.\d+)?)\s*(?:kg|kilo|c[aâ]n)\s*(?:xuong|xuong|ve|về|->|to)\s*(\d+(?:\.\d+)?)\s*(?:kg|kilo|c[aâ]n)",
        ]

        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                start_w = float(match.group(1))
                target_w = float(match.group(2))
                return start_w, target_w

        return None, None

    @staticmethod
    def _strip_chinese_chars(text: str, is_stream_token: bool = False) -> str:
        """Loại bỏ tuyệt đối ký tự Trung Quốc khỏi câu trả lời."""
        if not text:
            return text
        # CJK Unified Ideographs + CJK Compatibility Ideographs
        cleaned = re.sub(r"[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]", "", text)
        
        if is_stream_token:
            return cleaned  # Giữ nguyên khoảng trắng tự nhiên của token để chữ không bị dính
            
        # Gom khoảng trắng thừa sau khi loại ký tự (dành cho text nguyên khối)
        cleaned = re.sub(r"\s{2,}", " ", cleaned)
        cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
        return cleaned.strip()

    @staticmethod
    def _normalize_for_intent(text: str) -> str:
        """Lowercase + bỏ dấu tiếng Việt để bắt intent ổn định với nhiều cách gõ."""
        if not text:
            return ""
        text = unicodedata.normalize("NFD", text.lower())
        text = "".join(ch for ch in text if unicodedata.category(ch) != "Mn")
        return text

    def generate_stream(self, user_query: str, context: Dict[str, Any]):
        """
        Tạo câu trả lời từ LLM và stream từng token.
        Đây là một generator function.
        """
        query = (user_query or "").strip()

        normalized = query.lower()
        intent_text = self._normalize_for_intent(query)

        has_plan_intent = bool(re.search(r"\b(ke\s*hoach|lap\s*ke\s*hoach|plan|lo\s*trinh)\b", intent_text))
        has_weight_loss_intent = bool(re.search(r"\b(giam\s*can|giam\s*mo)\b", intent_text))
        has_week_month_horizon = bool(
            re.search(
                r"\b(tuan|theo\s*tuan|tung\s*tuan|4\s*tuan|thang|1\s*thang|mot\s*thang|month|week)\b",
                intent_text,
            )
        )

        weekly_mode = has_weight_loss_intent and has_week_month_horizon and (has_plan_intent or "cho toi" in intent_text)

        profile = context.get("profile") or {}
        recent_history = context.get("recent_history") or []
        current_time = context.get("current_time") or "Không rõ"
        current_weather = context.get("current_weather") or "Không rõ"
        current_meal = context.get("current_meal") or "N/A"
        seasonal = context.get("seasonal_tips") or {}
        veg = [x.get("food_name") for x in seasonal.get("vegetables", []) if x.get("food_name")][:3]
        specs = [x.get("food_name") for x in seasonal.get("specialties", []) if x.get("food_name")][:3]
        kb_data = context.get("medical_knowledge") or {}
        docs = kb_data.get("documents", [])[:2]
        metadatas = kb_data.get("metadatas", [])[:2]
        has_internal_docs = bool(docs)

        history_foods = [item.get("food_name") for item in recent_history if item.get("food_name")][:5]
        history_calories = sum(float(item.get("calories", 0) or 0) for item in recent_history)

        user_context = (
            f"Câu hỏi người dùng: {query}\n"
            f"Thời gian hiện tại: {current_time} | Thời tiết: {current_weather}\n"
            f"Hồ sơ: age={profile.get('age')}, gender={profile.get('gender')}, goal={profile.get('goal')}, "
            f"activity_level={profile.get('activity_level')}\n"
            f"Nhật ký gần đây: foods={history_foods if history_foods else 'không có'}, "
            f"total_calories_recent={round(history_calories, 1)}\n"
            f"Bữa ăn hiện tại: {current_meal}\n"
            f"Mùa/vùng: season={seasonal.get('season')}, region={seasonal.get('region_code')}\n"
            f"Rau gợi ý: {', '.join(veg) if veg else 'không có'}\n"
            f"Đặc sản gợi ý: {', '.join(specs) if specs else 'không có'}\n"
            f"Trích đoạn tài liệu: {docs if docs else 'không có'}\n"
            f"Metadata nguồn: {metadatas if metadatas else 'không có'}"
        )

        missing_profile_fields = self._missing_profile_fields(profile)

        system_prompt = self.prompts.get("base_system_prompt", "")

        if weekly_mode:
            system_prompt += "\n" + self.prompts.get("weekly_plan_prompt", "")
        else:
            system_prompt += "\n" + self.prompts.get("daily_advice_prompt", "")

        # Lắp ráp thủ công chuỗi Prompt theo chuẩn ChatML để vượt rào lỗi sampler
        raw_prompt = f"<|im_start|>system\n{system_prompt}<|im_end|>\n<|im_start|>user\n{user_context}<|im_end|>\n<|im_start|>assistant\n"

        response = self.model(
            prompt=raw_prompt,
            stream=True,  # Bật chế độ streaming
            max_tokens=2048,
            temperature=min(max(settings.LLM_TEMPERATURE, 0.15), 0.45),
            top_p=0.9,
            stop=["\n\nUser:", "\n\nQ:", "(Hồ sơ)", "(EcoNutri)", "<|im_end|>"],
        )
        
        # Yield từng token từ stream
        for chunk in response:
            content = chunk["choices"][0].get("text", "")
            if content:
                # Hậu xử lý đơn giản trên từng token để tránh ký tự không mong muốn
                cleaned_token = content.replace('"', '').replace('“', '').replace('”', '')
                if "(Hồ sơ)" in cleaned_token or "(EcoNutri)" in cleaned_token:
                    continue
                yield self._strip_chinese_chars(cleaned_token, is_stream_token=True)

    def get_response_suffix(self, context: Dict[str, Any], response_text: str = "") -> str:
        """Tạo phần phụ lục (citations, warnings) để nối vào cuối câu trả lời."""
        if not context:
            return ""

        # Tránh thêm trích dẫn nếu AI đang chào hỏi hoặc từ chối câu hỏi không liên quan
        text_lower = response_text.lower()
        is_greeting = any(text_lower.startswith(g) for g in ["xin chào", "chào", "hi ", "hello "]) and len(text_lower) < 150
        is_rejection = "xin lỗi" in text_lower and ("chỉ hỗ trợ" in text_lower or "trợ lý dinh dưỡng" in text_lower)

        profile = context.get("profile") or {}
        kb_data = context.get("medical_knowledge") or {}
        metadatas = kb_data.get("metadatas", [])[:2]
        has_internal_docs = bool(kb_data.get("documents", []))
        missing_profile_fields = self._missing_profile_fields(profile)

        suffix_parts = []

        # Chỉ nhắc bổ sung hồ sơ nếu không phải đang chào hỏi
        if missing_profile_fields and not is_greeting:
            suffix_parts.append(
                "**Gợi ý:** Để tư vấn chính xác hơn, bạn nên bổ sung: "
                + ", ".join(missing_profile_fields)
                + "."
            )
        
        return "\n\n".join(filter(None, suffix_parts))