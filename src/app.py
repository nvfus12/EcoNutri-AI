import sys
import importlib
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

    def generate(self, user_query: str, context: Dict[str, Any]) -> str:
        query = (user_query or "").strip()
        if query.lower() in {"hi", "hello", "xin chào", "chào", "hey"}:
            return "Xin chào! Mình là EcoNutri. Bạn muốn tư vấn bữa ăn, giảm cân hay kiểm soát calo hôm nay?"

        profile = context.get("profile") or {}
        seasonal = context.get("seasonal_tips") or {}
        veg = [x.get("food_name") for x in seasonal.get("vegetables", []) if x.get("food_name")][:3]
        specs = [x.get("food_name") for x in seasonal.get("specialties", []) if x.get("food_name")][:3]
        docs = (context.get("medical_knowledge") or {}).get("documents", [])[:2]

        user_context = (
            f"Câu hỏi người dùng: {query}\n"
            f"Hồ sơ: age={profile.get('age')}, gender={profile.get('gender')}, goal={profile.get('goal')}, "
            f"location={profile.get('location')}\n"
            f"Mùa/vùng: season={seasonal.get('season')}, region={seasonal.get('region_code')}\n"
            f"Rau gợi ý: {', '.join(veg) if veg else 'không có'}\n"
            f"Đặc sản gợi ý: {', '.join(specs) if specs else 'không có'}\n"
            f"Tài liệu tham khảo ngắn: {docs if docs else 'không có'}"
        )

        system_prompt = (
            "Bạn là chuyên gia dinh dưỡng EcoNutri. "
            "Trả lời bằng tiếng Việt tự nhiên, ngắn gọn 3-5 câu. "
            "Không lặp lại câu hỏi, không trích dẫn hội thoại giả, không tự đóng vai người dùng. "
            "Không dùng ngoặc kép bao toàn bộ câu trả lời. "
            "Luôn đưa 1-2 gợi ý hành động cụ thể."
        )

        response = self.model.create_chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_context},
            ],
            max_tokens=196,
            temperature=min(max(settings.LLM_TEMPERATURE, 0.1), 0.5),
            top_p=0.9,
            stop=["\n\nUser:", "\n\nQ:", "(Hồ sơ)", "(EcoNutri)"],
        )

        text = response["choices"][0]["message"]["content"].strip()
        # Hậu xử lý để loại bỏ phần quote/lặp không mong muốn.
        text = text.strip('"“”')
        if "(Hồ sơ)" in text:
            text = text.split("(Hồ sơ)")[0].strip()
        if "(EcoNutri)" in text:
            text = text.split("(EcoNutri)")[0].strip()

        return text

# --- GIAI ĐOẠN 1: KHỞI TẠO (Initial ization) ---
def bootstrap_system():
    # Khởi tạo toàn bộ "xương sống" dữ liệu như System Flow mô tả
    # (Đọc config, init DB, load models)
    status = {
        "vision": "off",
        "vector": "off",
        "llm": "off",
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