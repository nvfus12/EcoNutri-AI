import re
import unicodedata
from pathlib import Path
from typing import Any, Dict, Optional


class SafetyRouter:
    """Bộ định tuyến an toàn để chặn truy vấn y khoa nguy cơ cao trước khi gọi LLM."""

    def __init__(self, model_path: Optional[Path] = None):
        self.model = None
        self.model_path = model_path or (Path(__file__).resolve().parent.parent.parent / "assets" / "safety_router.joblib")
        self._try_load_model()

    @staticmethod
    def _normalize(text: str) -> str:
        if not text:
            return ""
        text = unicodedata.normalize("NFD", text.lower())
        text = "".join(ch for ch in text if unicodedata.category(ch) != "Mn")
        return text

    def _try_load_model(self) -> None:
        try:
            import joblib

            if self.model_path.exists():
                self.model = joblib.load(self.model_path)
        except Exception:
            self.model = None

    @staticmethod
    def _unsafe_template() -> str:
        return (
            "Tôi là trợ lý dinh dưỡng, không phải bác sĩ. Với tình trạng y tế hoặc thuốc đang dùng, "
            "bạn cần tham khảo bác sĩ/chuyên gia y tế để được tư vấn an toàn và cá nhân hóa. "
            "Nếu bạn muốn, tôi có thể hỗ trợ các nguyên tắc ăn uống chung không thay thế chẩn đoán y khoa."
        )

    def _rule_based_medical_flag(self, normalized_query: str) -> bool:
        medical_keywords = [
            "suy than",
            "than man",
            "tieu duong",
            "duong huyet",
            "gout",
            "da day",
            "mo mau",
            "ung thu",
            "hoa tri",
            "xa tri",
            "tim mach",
            "cao huyet ap",
            "huyet ap",
            "dot quy",
            "gan nhiem mo",
            "thuoc ke don",
            "ke don",
            "phac do",
            "insulin",
            "metformin",
            "warfarin",
            "prednisone",
            "khang dong",
            "khang sinh",
            "lieu thuoc",
            "don thuoc",
        ]
        return any(term in normalized_query for term in medical_keywords)

    def _rule_based_danger_goal_flag(self, normalized_query: str) -> bool:
        if re.search(r"duoi\s*1200\s*(kcal|calo)", normalized_query):
            return True

        # Ví dụ: "giam 5kg trong 3 ngay", "giam 4 kg trong 2 tuan"
        match = re.search(r"giam\s*(\d+(?:\.\d+)?)\s*kg\s*trong\s*(\d+(?:\.\d+)?)\s*(ngay|tuan|thang)", normalized_query)
        if not match:
            return False

        kg = float(match.group(1))
        duration = float(match.group(2))
        unit = match.group(3)

        if duration <= 0:
            return True

        if unit == "ngay":
            weeks = duration / 7.0
        elif unit == "tuan":
            weeks = duration
        else:  # thang
            weeks = duration * 4.0

        if weeks <= 0:
            return True

        kg_per_week = kg / weeks
        return kg_per_week > 1.0

    def route(self, query: str) -> Dict[str, Any]:
        normalized_query = self._normalize(query)

        if self._rule_based_medical_flag(normalized_query) or self._rule_based_danger_goal_flag(normalized_query):
            return {
                "label": "unsafe_medical",
                "is_unsafe": True,
                "response": self._unsafe_template(),
                "confidence": 1.0,
                "source": "rules",
            }

        if self.model is not None:
            try:
                pred = self.model.predict([query])[0]
                if str(pred).lower() in {"unsafe", "unsafe_medical", "medical"}:
                    confidence = None
                    if hasattr(self.model, "predict_proba"):
                        probs = self.model.predict_proba([query])[0]
                        confidence = float(max(probs))
                    return {
                        "label": "unsafe_medical",
                        "is_unsafe": True,
                        "response": self._unsafe_template(),
                        "confidence": confidence,
                        "source": "model",
                    }
            except Exception:
                pass

        return {
            "label": "safe",
            "is_unsafe": False,
            "response": "",
            "confidence": 1.0,
            "source": "rules",
        }
