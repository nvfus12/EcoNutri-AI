import streamlit as st
from src.core.config import settings
from src.services.orchestrator import ContextOrchestrator
# Import các module khác...

# --- GIAI ĐOẠN 1: KHỞI TẠO (Initial ization) ---
@st.cache_resource
def bootstrap_system():
    # Khởi tạo toàn bộ "xương sống" dữ liệu như System Flow mô tả
    # (Đọc config, init DB, load models)
    return ContextOrchestrator(...) # Trả về orchestrator đã nạp đủ engine

orch = bootstrap_system()

# --- GIAI ĐOẠN 2: GIAO DIỆN & TƯƠNG TÁC ---
st.title("🍃 EcoNutri Dashboard")

# Luồng 2A: Quản lý người dùng
if "user_id" not in st.session_state:
    st.session_state.user_id = 1 # Giả lập session người dùng

with st.sidebar:
    st.header("📊 Chỉ số cơ thể (Offline)")
    # Form nhập liệu Profile...

tab1, tab2 = st.tabs(["📸 Phân tích bữa ăn", "💬 Tư vấn thông minh"])

with tab1:
    # Luồng 2B: Nhận diện thực phẩm
    uploaded_file = st.camera_input("Chụp ảnh món ăn")
    if uploaded_file:
        # Lưu và xử lý qua Orchestrator
        with st.spinner("Đang tính toán dinh dưỡng..."):
            result = orch.process_full_vision_flow(uploaded_file, st.session_state.user_id)
            st.json(result.dict()) # Hiển thị Calories, Macro...

with tab2:
    # Luồng 2C: Chatbot & Context Orchestration
    if "chat_history" not in st.session_state:
        st.session_state.chat_history = []

    # Chat UI logic...
    if prompt := st.chat_input("Hỏi chuyên gia EcoNutri..."):
        response = orch.get_personalized_advice(st.session_state.user_id, prompt)
        st.write(response)