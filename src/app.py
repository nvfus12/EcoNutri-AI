import sys
import importlib
import re
import unicodedata
from pathlib import Path
from typing import Any, Dict

import streamlit as st

# Hỗ trợ chạy trực tiếp: python src/app.py
# Khi đó cần thêm thư mục gốc project vào sys.path để import được package src.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.core.config import settings
from src.services.context_orchestrator import ContextOrchestrator
from src.repositories.sql_repo import SQLRepository
# Import các module khác...

st.set_page_config(
    page_title="EcoNutri Dashboard",
    page_icon="🍃",
    layout="wide",
)

st.markdown(
    """
    <style>
        .hero {
            background: linear-gradient(120deg, #e8f7ee 0%, #f7f8f2 50%, #e9f2fb 100%);
            border: 1px solid #d6e9dc;
            border-radius: 16px;
            padding: 18px 22px;
            margin-bottom: 14px;
        }
        .hero h1 {
            margin: 0;
            color: #173b2f;
            font-size: 40px;
            letter-spacing: 0.2px;
        }
        .hero p {
            margin: 6px 0 0;
            color: #37574d;
            font-size: 16px;
        }
        .stat-chip {
            display: inline-block;
            margin: 4px 6px 0 0;
            padding: 6px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
            border: 1px solid #d8d8d8;
            background: #ffffff;
            color: #29303b;
        }
        .stat-on {
            background: #e8f8ef;
            border-color: #b8e4c8;
            color: #165a38;
        }
        .stat-off {
            background: #fff2f2;
            border-color: #f3c7c7;
            color: #8a2a2a;
        }
        .panel-card {
            background: #f7faf8;
            border: 1px solid #dce8df;
            border-radius: 14px;
            padding: 12px;
        }
    </style>
    """,
    unsafe_allow_html=True,
)


class LocalLLMEngine:
    """Wrapper mỏng cho llama-cpp để dùng chung với orchestrator."""

    def __init__(self, model_path: Path, n_ctx: int = 4096):
        llama_module = importlib.import_module("llama_cpp")
        llama_cls = getattr(llama_module, "Llama")
        self.model = llama_cls(model_path=str(model_path), n_ctx=n_ctx, verbose=False)

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
    def _strip_chinese_chars(text: str) -> str:
        """Loại bỏ tuyệt đối ký tự Trung Quốc khỏi câu trả lời."""
        if not text:
            return text
        # CJK Unified Ideographs + CJK Compatibility Ideographs
        cleaned = re.sub(r"[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]", "", text)
        # Gom khoảng trắng thừa sau khi loại ký tự
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

    def generate(self, user_query: str, context: Dict[str, Any]) -> str:
        query = (user_query or "").strip()
        if query.lower() in {"hi", "hello", "xin chào", "chào", "hey"}:
            return "Xin chào! Mình là EcoNutri. Bạn muốn tư vấn bữa ăn, giảm cân hay kiểm soát calo hôm nay?"

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

        # Chỉ cần là yêu cầu giảm cân theo mốc tuần/tháng là ép vào kế hoạch tuần.
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
            return self._strip_chinese_chars(self._build_monthly_weekly_plan(
                query=query,
                profile=profile,
                seasonal=seasonal,
                metadatas=metadatas,
                has_internal_docs=has_internal_docs,
                missing_fields_vi=missing_profile_fields,
            ))

        system_prompt = (
            "Bạn là chuyên gia dinh dưỡng EcoNutri, ưu tiên khuyến nghị thực tế và có lý do rõ ràng. "
            "Trả lời bằng tiếng Việt, dễ hiểu, tuyệt đối không tự đóng vai user. "
            "Nếu thiếu dữ liệu, nói rõ phần nào thiếu thay vì bịa. "
            "Không dùng ngoặc kép bao toàn bộ câu trả lời, không lặp prompt đầu vào."
        )

        if weekly_mode:
            system_prompt += (
                "\nNgười dùng đang yêu cầu kế hoạch theo tuần/tháng. "
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
            system_prompt += (
                "\nBắt buộc trả lời theo đúng 5 mục sau:\n"
                "1) Tóm tắt đánh giá (1-2 câu)\n"
                "2) Lý do chính (3 gạch đầu dòng, nêu vì sao)\n"
                "3) Gợi ý cụ thể cho hôm nay (2-4 gạch đầu dòng, có định lượng gần đúng nếu phù hợp)\n"
                "4) Lưu ý rủi ro/cảnh báo (nếu có)\n"
                "5) Cơ sở tham khảo (nêu ngắn gọn nguồn từ ngữ cảnh nếu có, nếu không thì ghi 'chưa có tài liệu nội bộ')"
            )

        response = self.model.create_chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_context},
            ],
            max_tokens=360,
            temperature=min(max(settings.LLM_TEMPERATURE, 0.15), 0.45),
            top_p=0.9,
            repeat_penalty=1.1,
            stop=["\n\nUser:", "\n\nQ:", "(Hồ sơ)", "(EcoNutri)"],
        )

        text = response["choices"][0]["message"]["content"].strip()
        # Hậu xử lý để loại bỏ phần quote/lặp không mong muốn.
        text = text.strip('"“”')
        if "(Hồ sơ)" in text:
            text = text.split("(Hồ sơ)")[0].strip()
        if "(EcoNutri)" in text:
            text = text.split("(EcoNutri)")[0].strip()

        if has_internal_docs and metadatas:
            cite_lines = []
            for md in metadatas:
                source = md.get("source") if isinstance(md, dict) else None
                page = md.get("page") if isinstance(md, dict) else None
                if source:
                    cite_lines.append(f"- {source}" + (f" (trang {page})" if page else ""))
            if cite_lines:
                text += "\n\nTrích dẫn nội bộ:\n" + "\n".join(cite_lines[:2])

        # Bổ sung nhắc người dùng cập nhật hồ sơ và trạng thái tài liệu khi còn thiếu.
        if missing_profile_fields:
            text += (
                "\n\nThông tin bạn nên bổ sung để tư vấn chính xác hơn: "
                + ", ".join(missing_profile_fields)
                + ". Bạn có thể nhập và lưu ở panel 'Hồ sơ người dùng' bên phải tab Tư vấn thông minh."
            )
        if not has_internal_docs:
            text += (
                "\n\nLưu ý: Hiện chưa có tài liệu nội bộ từ kho PDF (vector store rỗng hoặc chưa ingest), "
                "nên phần tham chiếu tài liệu đang hạn chế."
            )

        if not text:
            return self._strip_chinese_chars((
                "1) Tóm tắt đánh giá: Hiện chưa đủ dữ liệu để tư vấn sâu.\n"
                "2) Lý do chính:\n- Thiếu ngữ cảnh hồ sơ hoặc nhật ký ăn gần đây\n"
                "- Chưa có đủ tài liệu nội bộ từ vector\n- Câu hỏi còn quá ngắn\n"
                "3) Gợi ý cụ thể cho hôm nay:\n- Bổ sung mục tiêu (giảm cân/tăng cơ)\n"
                "- Cho mình chiều cao, cân nặng và bữa gần nhất\n"
                "4) Lưu ý rủi ro/cảnh báo: Không nên áp dụng chế độ cắt calo mạnh khi chưa có dữ liệu cá nhân.\n"
                "5) Cơ sở tham khảo: chưa có tài liệu nội bộ"
            ))

        return self._strip_chinese_chars(text)

# --- GIAI ĐOẠN 1: KHỞI TẠO (Initial ization) ---
def bootstrap_system():
    # Khởi tạo toàn bộ "xương sống" dữ liệu như System Flow mô tả
    # (Đọc config, init DB, load models)
    status = {
        "vision": "off",
        "vector": "off",
        "llm": "off",
        "vector_docs": 0,
        "notes": [],
    }

    sql_repo = SQLRepository()

    vision_engine = None
    try:
        from src.engines.vision_engine import VisionEngine
        vision_engine = VisionEngine()
        status["vision"] = "on"
    except Exception as exc:
        status["notes"].append(f"Vision chưa sẵn sàng: {exc}")

    vector_repo = None
    try:
        from src.repositories.vector_repo import VectorRepository
        vector_repo = VectorRepository()
        status["vector"] = "on"
        status["vector_docs"] = int(vector_repo.count_documents())
        if status["vector_docs"] == 0:
            status["notes"].append(
                "Vector đã bật nhưng chưa có tài liệu nội bộ. Hãy chạy scripts/ingest_knowledge.py để nạp PDF."
            )
    except Exception as exc:
        status["notes"].append(f"Vector chưa sẵn sàng: {exc}")

    llm_engine = None
    try:
        if settings.LLM_MODEL_PATH.exists():
            llm_engine = LocalLLMEngine(
                model_path=settings.LLM_MODEL_PATH,
                n_ctx=settings.LLM_CONTEXT_WINDOW,
            )
            status["llm"] = "on"
        else:
            status["notes"].append(f"Không tìm thấy model LLM: {settings.LLM_MODEL_PATH}")
    except Exception as exc:
        status["notes"].append(f"LLM chưa sẵn sàng: {exc}")

    orchestrator = ContextOrchestrator(
        vision_engine=vision_engine,
        sql_repo=sql_repo,
        vector_repo=vector_repo,
        llm_engine=llm_engine,
    )

    return orchestrator, status


orch, system_status = bootstrap_system()

# --- GIAI ĐOẠN 2: GIAO DIỆN & TƯƠNG TÁC ---
st.markdown(
    """
    <div class="hero">
        <h1>🍃 EcoNutri Dashboard</h1>
        <p>Theo dõi dinh dưỡng, phân tích bữa ăn và nhận tư vấn cá nhân hóa theo vùng - mùa vụ.</p>
    </div>
    """,
    unsafe_allow_html=True,
)

# Luồng 2A: Quản lý người dùng
if "user_id" not in st.session_state:
    st.session_state.user_id = 1 # Giả lập session người dùng

with st.sidebar:
    st.header("📊 Chỉ số cơ thể (Offline)")
    vision_cls = "stat-on" if system_status["vision"] == "on" else "stat-off"
    vector_cls = "stat-on" if system_status["vector"] == "on" else "stat-off"
    llm_cls = "stat-on" if system_status["llm"] == "on" else "stat-off"
    st.markdown(
        (
            f"<span class='stat-chip {vision_cls}'>Vision: {system_status['vision']}</span>"
            f"<span class='stat-chip {vector_cls}'>Vector: {system_status['vector']}</span>"
            f"<span class='stat-chip {llm_cls}'>LLM: {system_status['llm']}</span>"
        ),
        unsafe_allow_html=True,
    )
    st.caption(f"Tài liệu nội bộ trong vector store: {system_status.get('vector_docs', 0)}")

    for note in system_status["notes"]:
        st.warning(note)

    with st.expander("Gợi ý cho tôi", expanded=False):
        st.markdown(
            """
            1. Tab `Tư vấn thông minh`: nhập câu hỏi ngắn như `Bữa sáng cho người giảm cân?`
            2. Tab `Phân tích bữa ăn`: chụp món ăn, bấm gửi để kiểm tra vision flow.
            3. Nếu engine nào `off`, xem cảnh báo ngay bên trên để sửa dependency.
            """
        )

tab1, tab2 = st.tabs(["📸 Phân tích bữa ăn", "💬 Tư vấn thông minh"])

with tab1:
    left_col, right_col = st.columns([2, 1], gap="large")

    with left_col:
        st.subheader("Nhận diện món ăn")
        uploaded_file = st.camera_input("Chụp ảnh món ăn")
        if uploaded_file:
            with st.spinner("Đang tính toán dinh dưỡng..."):
                try:
                    result = orch.process_full_vision_flow(uploaded_file, st.session_state.user_id)
                    st.success("Phân tích xong")
                    st.json(result.dict())
                except Exception as exc:
                    st.error(f"Không thể phân tích ảnh lúc này: {exc}")

    with right_col:
        st.subheader("Gợi ý sử dụng")
        st.markdown("<div class='panel-card'>", unsafe_allow_html=True)
        st.write("• Chụp rõ món ăn, đủ ánh sáng")
        st.write("• Hạn chế nền quá rối")
        st.write("• Ảnh cận cảnh 1-2 món để tăng độ chính xác")
        st.markdown("</div>", unsafe_allow_html=True)

with tab2:
    chat_col, profile_col = st.columns([2, 1], gap="large")

    with profile_col:
        st.subheader("👤 Hồ sơ người dùng")
        existing_profile = orch.sql_repo.get_user_profile(st.session_state.user_id) or {}
        with st.form("user_profile_form_tab2", clear_on_submit=False):
            name = st.text_input("Tên", value=existing_profile.get("name", ""))
            age = st.number_input("Tuổi", min_value=0, max_value=120, value=int(existing_profile.get("age") or 0), step=1)
            gender = st.selectbox(
                "Giới tính",
                options=["male", "female", "other"],
                index=["male", "female", "other"].index(existing_profile.get("gender", "other"))
                if existing_profile.get("gender", "other") in ["male", "female", "other"]
                else 2,
            )
            height_cm = st.number_input(
                "Chiều cao (cm)",
                min_value=0.0,
                max_value=250.0,
                value=float(existing_profile.get("height_cm") or 0.0),
                step=0.5,
            )
            weight_kg = st.number_input(
                "Cân nặng (kg)",
                min_value=0.0,
                max_value=300.0,
                value=float(existing_profile.get("weight_kg") or 0.0),
                step=0.1,
            )
            activity_level = st.selectbox(
                "Mức vận động",
                options=["sedentary", "light", "moderate", "active", "very_active"],
                index=["sedentary", "light", "moderate", "active", "very_active"].index(
                    existing_profile.get("activity_level", "sedentary")
                )
                if existing_profile.get("activity_level", "sedentary") in ["sedentary", "light", "moderate", "active", "very_active"]
                else 0,
            )
            goal = st.selectbox(
                "Mục tiêu",
                options=["lose", "maintain", "gain"],
                index=["lose", "maintain", "gain"].index(existing_profile.get("goal", "maintain"))
                if existing_profile.get("goal", "maintain") in ["lose", "maintain", "gain"]
                else 1,
            )
            location = st.text_input("Địa điểm", value=existing_profile.get("location", ""))
            allergies = st.text_input("Dị ứng", value=existing_profile.get("allergies", ""))
            medical_conditions = st.text_input("Bệnh lý nền", value=existing_profile.get("medical_conditions", ""))

            save_profile = st.form_submit_button("💾 Lưu hồ sơ")
            if save_profile:
                orch.sql_repo.upsert_user_profile(
                    user_id=st.session_state.user_id,
                    user_data={
                        "name": name,
                        "age": age,
                        "gender": gender,
                        "height_cm": height_cm,
                        "weight_kg": weight_kg,
                        "activity_level": activity_level,
                        "goal": goal,
                        "location": location,
                        "allergies": allergies,
                        "medical_conditions": medical_conditions,
                    },
                )
                st.success("Đã lưu hồ sơ vào database.")

    with chat_col:
        st.subheader("Chat với chuyên gia dinh dưỡng")

        # Luồng 2C: Chatbot & Context Orchestration
        if "chat_history" not in st.session_state:
            st.session_state.chat_history = []

        for msg in st.session_state.chat_history:
            with st.chat_message(msg["role"]):
                st.write(msg["content"])

        # Chat UI logic...
        if prompt := st.chat_input("Hỏi chuyên gia EcoNutri..."):
            st.session_state.chat_history.append({"role": "user", "content": prompt})
            with st.chat_message("user"):
                st.write(prompt)

            try:
                with st.spinner("EcoNutri đang suy nghĩ..."):
                    response = orch.get_personalized_advice(st.session_state.user_id, prompt)

                if not response or not str(response).strip():
                    response = "Mình đã nhận câu hỏi, nhưng LLM vừa trả về rỗng. Bạn thử hỏi chi tiết hơn một chút nhé."

                st.session_state.chat_history.append({"role": "assistant", "content": response})
                with st.chat_message("assistant"):
                    st.write(response)
            except Exception as exc:
                error_msg = f"Không thể tạo tư vấn lúc này: {exc}"
                st.session_state.chat_history.append({"role": "assistant", "content": error_msg})
                with st.chat_message("assistant"):
                    st.error(error_msg)