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
from src.services.orchestrator import ContextOrchestrator
from src.repositories.sql_repo import SQLRepository
from src.engines.llm_engine import LocalLLMEngine
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


# --- GIAI ĐOẠN 1: KHỞI TẠO (Initial ization) ---
@st.cache_resource(show_spinner="Đang nạp mô hình AI vào bộ nhớ (Chỉ chạy 1 lần duy nhất)...")
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
        
        # Bổ sung tùy chọn Tải ảnh / Chụp ảnh
        input_method = st.radio("Phương thức đầu vào:", ["Tải ảnh lên 📁", "Chụp ảnh 📸"], horizontal=True)
        
        if input_method == "Tải ảnh lên 📁":
            uploaded_file = st.file_uploader("Chọn ảnh món ăn", type=["jpg", "jpeg", "png", "webp"])
        else:
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

        # Tạo container có chiều cao cố định để nội dung chat có thể scroll
        chat_container = st.container(height=550, border=False)

        with chat_container:
            for msg in st.session_state.chat_history:
                with st.chat_message(msg["role"]):
                    st.write(msg["content"])

        # Chat UI logic...
        if prompt := st.chat_input("Hỏi chuyên gia EcoNutri..."):
            st.session_state.chat_history.append({"role": "user", "content": prompt})
            with chat_container:
                with st.chat_message("user"):
                    st.write(prompt)

            try:
                with st.spinner("EcoNutri đang suy nghĩ..."):
                    # Luồng mới: Lấy stream và context
                    response_stream, context_for_suffix = orch.get_personalized_advice(
                        st.session_state.user_id, prompt
                    )

                with chat_container:
                    with st.chat_message("assistant"):
                        # 1. Render stream chính
                        full_response = st.write_stream(response_stream)

                        # 2. Lấy và render phần phụ lục (citations, warnings)
                        suffix = orch.get_advice_suffix(context_for_suffix)
                        if suffix:
                            st.markdown(suffix, unsafe_allow_html=True)

                # 3. Lưu toàn bộ vào lịch sử chat
                final_message = (full_response + "\n\n" + suffix).strip()
                st.session_state.chat_history.append({"role": "assistant", "content": final_message})

            except Exception as exc:
                error_msg = f"Không thể tạo tư vấn lúc này: {exc}"
                st.session_state.chat_history.append({"role": "assistant", "content": error_msg})
                st.rerun() # Chạy lại để hiển thị lỗi trong chat