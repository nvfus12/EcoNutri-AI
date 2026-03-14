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


class LocalLLMEngine:
    """Wrapper mỏng cho llama-cpp để dùng chung với orchestrator."""

    def __init__(self, model_path: Path, n_ctx: int = 4096):
        llama_module = importlib.import_module("llama_cpp")
        llama_cls = getattr(llama_module, "Llama")
        self.model = llama_cls(model_path=str(model_path), n_ctx=n_ctx, verbose=False)

    def generate(self, user_query: str, context: Dict[str, Any]) -> str:
        prompt = (
            "Bạn là chuyên gia dinh dưỡng EcoNutri.\n"
            f"Câu hỏi: {user_query}\n"
            f"Hồ sơ: {context.get('profile')}\n"
            f"Lịch sử gần đây: {context.get('recent_history')}\n"
            f"Gợi ý mùa vụ: {context.get('seasonal_tips')}\n"
            f"Tri thức y khoa: {context.get('medical_knowledge')}\n"
            "Trả lời ngắn gọn, cá nhân hóa và có hành động cụ thể."
        )
        response = self.model.create_completion(
            prompt=prompt,
            max_tokens=128,
            temperature=settings.LLM_TEMPERATURE,
            stop=["\n\nUser:", "\n\nQ:"],
        )
        return response["choices"][0]["text"].strip()

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
st.title("🍃 EcoNutri Dashboard")

# Luồng 2A: Quản lý người dùng
if "user_id" not in st.session_state:
    st.session_state.user_id = 1 # Giả lập session người dùng

with st.sidebar:
    st.header("📊 Chỉ số cơ thể (Offline)")
    st.caption(
        f"Engine status - Vision: {system_status['vision']} | "
        f"Vector: {system_status['vector']} | LLM: {system_status['llm']}"
    )
    for note in system_status["notes"]:
        st.warning(note)
    # Form nhập liệu Profile...

tab1, tab2 = st.tabs(["📸 Phân tích bữa ăn", "💬 Tư vấn thông minh"])

with tab1:
    # Luồng 2B: Nhận diện thực phẩm
    uploaded_file = st.camera_input("Chụp ảnh món ăn")
    if uploaded_file:
        # Lưu và xử lý qua Orchestrator
        with st.spinner("Đang tính toán dinh dưỡng..."):
            try:
                result = orch.process_full_vision_flow(uploaded_file, st.session_state.user_id)
                st.json(result.dict()) # Hiển thị Calories, Macro...
            except Exception as exc:
                st.error(f"Không thể phân tích ảnh lúc này: {exc}")

with tab2:
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