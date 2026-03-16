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
            "location": "địa điểm",
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

    def _build_monthly_weekly_plan(
        self,
        query: str,
        profile: Dict[str, Any],
        seasonal: Dict[str, Any],
        metadatas: list,
        has_internal_docs: bool,
        missing_fields_vi: list[str],
    ) -> str:
        age = int(profile.get("age") or 0)
        gender = (profile.get("gender") or "other").lower()
        goal = profile.get("goal") or "lose"
        activity_level = profile.get("activity_level") or "sedentary"
        tdee = self._safe_float(profile.get("tdee"))
        start_weight, target_weight = self._extract_weight_goal_kg(query)

        # fallback lấy từ hồ sơ nếu prompt không nói rõ
        if start_weight is None:
            current_w = self._safe_float(profile.get("weight_kg"))
            if current_w > 0:
                start_weight = current_w
        if target_weight is None and start_weight is not None:
            target_weight = max(start_weight - 1.0, 35.0)

        total_loss = None
        weekly_delta = None
        if start_weight is not None and target_weight is not None and start_weight > target_weight:
            total_loss = round(start_weight - target_weight, 2)
            weekly_delta = round(total_loss / 4, 2)

        if tdee > 0:
            calorie_target = int(max(1200, tdee - 350))
        else:
            calorie_target = 1700 if gender == "male" else 1500

        # Người < 18 tuổi: ưu tiên an toàn, giảm thâm hụt năng lượng.
        if 0 < age < 18:
            calorie_target = max(calorie_target, 1800)

        veg = [x.get("food_name") for x in seasonal.get("vegetables", []) if x.get("food_name")][:3]
        specs = [x.get("food_name") for x in seasonal.get("specialties", []) if x.get("food_name")][:2]
        veg_text = ", ".join(veg) if veg else "rau xanh theo mùa"
        spec_text = ", ".join(specs) if specs else "đặc sản địa phương"

        plan = [
            "1) Mục tiêu 1 tháng:",
            (
                (
                    f"- Mục tiêu đề xuất: từ {start_weight:.1f} kg xuống {target_weight:.1f} kg trong 4 tuần "
                    f"(giảm khoảng {total_loss:.1f} kg), duy trì khoảng {calorie_target} kcal/ngày."
                )
                if total_loss is not None
                else (
                    f"- Mục tiêu đề xuất: tối ưu thành phần cơ thể theo hướng {goal}, "
                    f"duy trì năng lượng khoảng {calorie_target} kcal/ngày và tăng thói quen vận động đều."
                )
            ),
            "",
            "2) Kế hoạch 4 tuần:",
            (
                f"- Tuần 1: Ổn định nề nếp ăn. Calories mục tiêu ~{calorie_target} kcal/ngày. "
                "Thực đơn mẫu: sáng (yến mạch + trứng), trưa (cơm vừa + đạm nạc + rau), "
                "tối (đạm nhẹ + rau + canh). Vận động: đi bộ nhanh 25-30 phút/ngày. "
                + (
                    f"Theo dõi: cân nặng mục tiêu cuối tuần ~{(start_weight - weekly_delta):.1f} kg, vòng bụng, mức đói buổi tối."
                    if weekly_delta is not None and start_weight is not None
                    else "Theo dõi: cân nặng, vòng bụng, mức đói buổi tối."
                )
            ),
            (
                f"- Tuần 2: Tăng chất lượng khẩu phần. Duy trì ~{calorie_target} kcal/ngày, "
                f"ưu tiên {veg_text}. Vận động: 3 buổi sức mạnh nhẹ + 2 buổi cardio. "
                + (
                    f"Theo dõi: cân nặng mục tiêu cuối tuần ~{(start_weight - 2 * weekly_delta):.1f} kg, năng lượng ban ngày, chất lượng giấc ngủ."
                    if weekly_delta is not None and start_weight is not None
                    else "Theo dõi: năng lượng ban ngày, chất lượng giấc ngủ."
                )
            ),
            (
                "- Tuần 3: Củng cố kỷ luật. Giữ tỉ lệ đạm cao hơn, giảm đồ ngọt nước và đồ chiên. "
                + (
                    f"Vận động: tăng tổng bước chân thêm 10-15%. Theo dõi: cân nặng mục tiêu cuối tuần ~{(start_weight - 3 * weekly_delta):.1f} kg."
                    if weekly_delta is not None and start_weight is not None
                    else "Vận động: tăng tổng bước chân thêm 10-15%. Theo dõi: tiến độ cân nặng theo tuần."
                )
            ),
            (
                f"- Tuần 4: Tối ưu và duy trì. Lồng ghép linh hoạt món địa phương ({spec_text}) theo khẩu phần nhỏ, "
                + (
                    f"không phá vỡ tổng calories. Mục tiêu cuối tháng ~{target_weight:.1f} kg. "
                    "So sánh số đo đầu-tháng/cuối-tháng để chốt kế hoạch tháng sau."
                    if target_weight is not None
                    else "không phá vỡ tổng calories. Theo dõi: so sánh số đo đầu-tháng/cuối-tháng để chốt kế hoạch tháng sau."
                )
            ),
            "",
            "3) Lý do khoa học:",
            "- Giảm năng lượng vừa phải giúp duy trì cơ và giảm nguy cơ tăng cân trở lại.",
            "- Chia nhỏ mục tiêu theo tuần giúp dễ theo dõi và điều chỉnh hành vi ăn uống.",
            "- Kết hợp dinh dưỡng + vận động cho hiệu quả bền vững hơn chỉ siết ăn.",
            "",
            "4) Cảnh báo an toàn:",
            "- Không giảm cân quá nhanh (>1% cân nặng/tuần).",
            "- Nếu có bệnh nền hoặc mệt kéo dài, cần trao đổi bác sĩ/chuyên gia dinh dưỡng.",
        ]

        if 0 < age < 18:
            plan.append("- Người dưới 18 tuổi nên ưu tiên phát triển thể chất, tránh cắt calo quá mạnh.")

        plan.append("")
        plan.append("5) Trích dẫn nội bộ:")
        if has_internal_docs and metadatas:
            cites = []
            for md in metadatas[:2]:
                source = md.get("source") if isinstance(md, dict) else None
                page = md.get("page") if isinstance(md, dict) else None
                if source:
                    cites.append(f"- {source}" + (f" (trang {page})" if page else ""))
            plan.extend(cites if cites else ["- Có dữ liệu nội bộ nhưng chưa xác định được nguồn cụ thể"]) 
        else:
            plan.append("- Chưa có tài liệu nội bộ")

        plan.append("")
        if missing_fields_vi:
            plan.append(
                "Dữ liệu người dùng cần bổ sung để cá nhân hóa tốt hơn: " + ", ".join(missing_fields_vi) + "."
            )
        else:
            plan.append("Dữ liệu người dùng đã đủ cơ bản để cá nhân hóa kế hoạch theo tuần.")

        return "\n".join(plan)

    def generate_stream(self, user_query: str, context: Dict[str, Any]):
        """
        Tạo câu trả lời từ LLM và stream từng token.
        Đây là một generator function.
        """
        query = (user_query or "").strip()
        if query.lower() in {"hi", "hello", "xin chào", "chào", "hey"}:
            # Với câu chào, ta cũng yield để UI xử lý đồng nhất
            yield "Xin chào! Mình là EcoNutri. Bạn muốn tư vấn bữa ăn, giảm cân hay kiểm soát calo hôm nay?"
            return

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
            f"Hồ sơ: age={profile.get('age')}, gender={profile.get('gender')}, goal={profile.get('goal')}, "
            f"location={profile.get('location')}, activity_level={profile.get('activity_level')}\n"
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

        if weekly_mode:
            response_text = self._strip_chinese_chars(self._build_monthly_weekly_plan(
                query=query,
                profile=profile,
                seasonal=seasonal,
                metadatas=metadatas,
                has_internal_docs=has_internal_docs,
                missing_fields_vi=missing_profile_fields,
            ))
            # Đây là text tĩnh, ta sẽ yield từng chunk để giả lập streaming cho UI
            for i in range(0, len(response_text), 8):
                yield response_text[i:i+8]
                time.sleep(0.01)
            return

        system_prompt = self.prompts.get("base_system_prompt",
            "Bạn là chuyên gia dinh dưỡng EcoNutri. "
            "QUY TẮC: 1. Nếu câu hỏi KHÔNG LIÊN QUAN đến dinh dưỡng/sức khỏe (vd: giải trí, thể thao), TỪ CHỐI NGAY bằng câu: "
            "'Xin lỗi, tôi là trợ lý dinh dưỡng EcoNutri nên chỉ hỗ trợ các vấn đề ăn uống, sức khỏe.' "
            "2. Trả lời ngắn gọn, trực diện, không dài dòng. "
            "3. Nếu có 'Trích đoạn tài liệu' thì dùng nó, nếu không thì dùng kiến thức chung và KHÔNG bịa nguồn. "
            "4. Tuyệt đối không tự đóng vai user."
        )

        if weekly_mode:
            system_prompt += "\n" + self.prompts.get("weekly_plan_prompt",
                "Người dùng đang yêu cầu kế hoạch theo tuần/tháng. "
                "Bắt buộc xuất đúng cấu trúc sau:\n"
                "1) Mục tiêu 1 tháng (1-2 câu)\n"
                "2) Kế hoạch 4 tuần (tuần 1-4), mỗi tuần gồm:\n"
                "- Mục tiêu tuần\n- Calories mục tiêu/ngày (ước lượng)\n"
                "- Gợi ý thực đơn mẫu 1 ngày (sáng/trưa/tối + snack)\n"
                "- Vận động gợi ý\n- Chỉ số cần theo dõi\n"
                "3) Lý do khoa học (3 gạch đầu dòng)\n"
                "4) Cảnh báo an toàn\n"
                "5) Trích dẫn nội bộ (nếu có dữ liệu PDF)"
            )
        else:
            system_prompt += "\n" + self.prompts.get("daily_advice_prompt",
                "Bắt buộc trả lời theo đúng 5 mục sau:\n"
                "1) Tóm tắt vấn đề\n2) Gợi ý cụ thể hôm nay\n3) Lưu ý rủi ro\n"
            )

        response = self.model.create_chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_context},
            ],
            stream=True,  # Bật chế độ streaming
            max_tokens=360,
            temperature=min(max(settings.LLM_TEMPERATURE, 0.15), 0.45),
            top_p=0.9,
            repeat_penalty=1.1,
            stop=["\n\nUser:", "\n\nQ:", "(Hồ sơ)", "(EcoNutri)"],
        )
        
        # Yield từng token từ stream
        for chunk in response:
            content = chunk["choices"][0]["delta"].get("content")
            if content:
                # Hậu xử lý đơn giản trên từng token để tránh ký tự không mong muốn
                cleaned_token = content.replace('"', '').replace('“', '').replace('”', '')
                if "(Hồ sơ)" in cleaned_token or "(EcoNutri)" in cleaned_token:
                    continue
                yield self._strip_chinese_chars(cleaned_token, is_stream_token=True)

    def get_response_suffix(self, context: Dict[str, Any]) -> str:
        """Tạo phần phụ lục (citations, warnings) để nối vào cuối câu trả lời."""
        if not context:
            return ""

        profile = context.get("profile") or {}
        kb_data = context.get("medical_knowledge") or {}
        metadatas = kb_data.get("metadatas", [])[:2]
        has_internal_docs = bool(kb_data.get("documents", []))
        missing_profile_fields = self._missing_profile_fields(profile)

        suffix_parts = []
        if has_internal_docs and metadatas:
            cite_lines = []
            for md in metadatas:
                source = md.get("source") if isinstance(md, dict) else None
                page = md.get("page") if isinstance(md, dict) else None
                if source:
                    cite_lines.append(f"• {source}" + (f" (trang {page})" if page else ""))
            if cite_lines:
                suffix_parts.append("**Trích dẫn nội bộ:**\n" + "\n".join(cite_lines[:2]))

        if missing_profile_fields:
            suffix_parts.append(
                "**Gợi ý:** Để tư vấn chính xác hơn, bạn nên bổ sung: "
                + ", ".join(missing_profile_fields)
                + "."
            )
        
        return "\n\n".join(filter(None, suffix_parts))