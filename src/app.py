import sys
import importlib
import json
import re
import time
import unicodedata
from pathlib import Path
import hashlib
from typing import Any, Dict
from datetime import datetime
import pandas as pd

import streamlit as st

# Hỗ trợ chạy trực tiếp: python src/app.py
# Khi đó cần thêm thư mục gốc project vào sys.path để import được package src.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.core.config import settings
from src.services.orchestrator import ContextOrchestrator
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

        .main .block-container {
            padding-bottom: 24px;
        }
    </style>
    """,
    unsafe_allow_html=True,
)


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
            from src.engines.llm_engine import LocalLLMEngine
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


@st.cache_resource(show_spinner=False)
def get_cached_system():
    return bootstrap_system()

orch, system_status = get_cached_system()

# Luồng 2A: Quản lý đăng nhập / xác thực
def get_users_db_path():
    return settings.BASE_DIR / "data" / "users.json"

def load_users():
    path = get_users_db_path()
    if path.exists():
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_users(users_data):
    path = get_users_db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(users_data, f, ensure_ascii=False, indent=2)

if "logged_in" not in st.session_state:
    st.session_state.logged_in = False
    st.session_state.user_id = None
    st.session_state.username = None

if not st.session_state.logged_in:
    st.markdown("<h2 style='text-align: center; color: #165a38; margin-top: 50px;'>Chào mừng đến với EcoNutri</h2>", unsafe_allow_html=True)
    
    col1, col2, col3 = st.columns([1, 1, 1])
    with col2:
        tab_login, tab_register = st.tabs(["🔐 Đăng nhập", "📝 Đăng ký"])
        
        with tab_login:
            with st.form("login_form"):
                username = st.text_input("Tên đăng nhập")
                password = st.text_input("Mật khẩu", type="password")
                if st.form_submit_button("Đăng nhập", use_container_width=True, type="primary"):
                    users = load_users()
                    hashed_pw = hashlib.sha256(password.encode()).hexdigest()
                    if username in users and users[username]["password"] == hashed_pw:
                        st.session_state.logged_in = True
                        st.session_state.user_id = users[username]["user_id"]
                        st.session_state.username = username
                        st.rerun()
                    else:
                        st.error("Tên đăng nhập hoặc mật khẩu không đúng.")
                        
        with tab_register:
            with st.form("register_form"):
                new_username = st.text_input("Tên đăng nhập mới")
                new_password = st.text_input("Mật khẩu", type="password")
                confirm_password = st.text_input("Xác nhận mật khẩu", type="password")
                if st.form_submit_button("Đăng ký", use_container_width=True):
                    users = load_users()
                    if new_username in users:
                        st.error("Tên đăng nhập đã tồn tại.")
                    elif new_password != confirm_password:
                        st.error("Mật khẩu xác nhận không khớp.")
                    elif len(new_username) < 3 or len(new_password) < 3:
                        st.error("Tài khoản và mật khẩu phải từ 3 ký tự trở lên.")
                    else:
                        # Cấp một user_id duy nhất cho tài khoản này
                        new_id = int(time.time())
                        users[new_username] = {
                            "password": hashlib.sha256(new_password.encode()).hexdigest(),
                            "user_id": new_id
                        }
                        save_users(users)
                        st.success("Đăng ký thành công! Hãy chuyển sang tab Đăng nhập.")

    st.stop()  # Ngừng render các phần bên dưới nếu chưa đăng nhập

def get_chat_file_path(user_id):
    return settings.BASE_DIR / "data" / f"chat_history_{user_id}.json"

def save_active_chat_history():
    if st.session_state.get("logged_in") and st.session_state.get("user_id"):
        path = get_chat_file_path(st.session_state.user_id)
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(st.session_state.chat_sessions, f, ensure_ascii=False, indent=2)

# Luồng 2A.1: Quản lý Sidebar Lịch sử Chat
if "chat_sessions" not in st.session_state:
    path = get_chat_file_path(st.session_state.user_id)
    loaded_data = None
    if path.exists():
        try:
            with open(path, "r", encoding="utf-8") as f:
                loaded_data = json.load(f)
        except Exception:
            pass
    
    if loaded_data:
        st.session_state.chat_sessions = loaded_data
    else:
        init_id = str(int(time.time() * 1000))
        st.session_state.chat_sessions = {init_id: {"title": "Hội thoại mới", "messages": []}}

if "active_session_id" not in st.session_state or st.session_state.active_session_id not in st.session_state.chat_sessions:
    st.session_state.active_session_id = list(st.session_state.chat_sessions.keys())[0]

with st.sidebar:
    # Tiêu đề chính của ứng dụng, thay thế cho hero section
    st.markdown("<h1 style='font-size: 28px; color: #173b2f; margin-bottom: 20px;'>🍃 EcoNutri</h1>", unsafe_allow_html=True)

    st.markdown(f"👤 **Xin chào, {st.session_state.get('username', 'User')}**")
    
    with st.expander("⚙️ Đổi mật khẩu"):
        with st.form("change_password_form"):
            old_pw = st.text_input("Mật khẩu cũ", type="password")
            new_pw = st.text_input("Mật khẩu mới", type="password")
            confirm_pw = st.text_input("Xác nhận mật khẩu mới", type="password")
            if st.form_submit_button("Cập nhật mật khẩu", use_container_width=True):
                users = load_users()
                username = st.session_state.username
                if hashlib.sha256(old_pw.encode()).hexdigest() != users[username]["password"]:
                    st.error("Mật khẩu cũ không đúng.")
                elif new_pw != confirm_pw:
                    st.error("Mật khẩu mới không khớp.")
                elif len(new_pw) < 3:
                    st.error("Mật khẩu mới phải từ 3 ký tự.")
                else:
                    users[username]["password"] = hashlib.sha256(new_pw.encode()).hexdigest()
                    save_users(users)
                    st.success("Đổi mật khẩu thành công!")

    # Nút đăng xuất
    if st.button("🚪 Đăng xuất", use_container_width=True):
        st.session_state.logged_in = False
        st.session_state.user_id = None
        st.session_state.username = None
        if "chat_sessions" in st.session_state:
            del st.session_state["chat_sessions"]
        if "active_session_id" in st.session_state:
            del st.session_state["active_session_id"]
        if "user_lat" in st.session_state:
            del st.session_state["user_lat"]
        if "user_lon" in st.session_state:
            del st.session_state["user_lon"]
        if "location_asked" in st.session_state:
            del st.session_state["location_asked"]
        st.rerun()
    st.divider()

    st.header("💬 Lịch sử hội thoại")
    if st.button("➕ Cuộc trò chuyện mới", use_container_width=True, type="primary"):
        new_id = str(int(time.time() * 1000))
        st.session_state.chat_sessions[new_id] = {"title": "Hội thoại mới", "messages": []}
        st.session_state.active_session_id = new_id
        save_active_chat_history()
        st.rerun()
    st.divider()
    
    for s_id, s_data in reversed(list(st.session_state.chat_sessions.items())):
        btn_type = "primary" if s_id == st.session_state.active_session_id else "secondary"
        if st.button(f"📝 {s_data['title']}", key=f"btn_{s_id}", use_container_width=True, type=btn_type):
            st.session_state.active_session_id = s_id
            st.rerun()

@st.cache_data(ttl=900)  # Cache 15 phút để tiết kiệm tài nguyên và API
def get_weather_header(lat, lon):
    from src.services.weather_service import WeatherService
    # Trả về cả chuỗi thời tiết và tên thành phố (nếu có)
    return WeatherService.get_current_weather_with_city(lat=lat, lon=lon)

if "location_asked" not in st.session_state:
    st.session_state.location_asked = False
if "user_lat" not in st.session_state:
    st.session_state.user_lat = None
if "user_lon" not in st.session_state:
    st.session_state.user_lon = None

current_profile = orch.get_user_profile(st.session_state.user_id) or {}
user_lat = st.session_state.user_lat
user_lon = st.session_state.user_lon

if not st.session_state.location_asked and (user_lat is None or user_lon is None):
    st.markdown("<h3 style='text-align: center; color: #165a38; margin-top: 20px;'>📍 Cập nhật vị trí tự động</h3>", unsafe_allow_html=True)
    st.info("Ứng dụng cần biết vị trí của bạn để hiển thị thời tiết và gợi ý đặc sản vùng miền. Bạn có muốn lấy vị trí tự động qua mạng (IP) không cần dùng quyền trình duyệt không?")
    
    col1, col2, col3 = st.columns([1, 2, 1])
    with col2:
        if st.button("✅ Cho phép tự động lấy vị trí", use_container_width=True, type="primary"):
            import urllib.request
            import json
            try:
                req = urllib.request.Request("http://ip-api.com/json/", headers={'User-Agent': 'Mozilla/5.0'})
                with urllib.request.urlopen(req, timeout=5) as response:
                    data = json.loads(response.read().decode())
                    if data.get("status") == "success":
                        new_lat = data.get("lat")
                        new_lon = data.get("lon")
                        st.session_state.user_lat = new_lat
                        st.session_state.user_lon = new_lon
                        st.session_state.location_asked = True
                        st.success(f"Đã xác định vị trí thành công (Lat: {new_lat}, Lon: {new_lon})!")
                        time.sleep(1)
                        st.rerun()
                    else:
                        st.error("Dịch vụ IP không trả về kết quả.")
                        st.session_state.location_asked = True
                        time.sleep(1)
                        st.rerun()
            except Exception as e:
                st.error(f"Lỗi mạng khi lấy vị trí: {e}")
                st.session_state.location_asked = True
                time.sleep(1)
                st.rerun()
                
        if st.button("❌ Bỏ qua (Tôi sẽ tự nhập sau)", use_container_width=True):
            st.session_state.location_asked = True
            st.rerun()
            
    st.stop()  # Dừng ở đây chờ người dùng quyết định

weather_info, resolved_city = get_weather_header(user_lat, user_lon)
display_loc = resolved_city if resolved_city else (f"GPS: {user_lat:.4f}, {user_lon:.4f}" if user_lat and user_lon else "Chưa có vị trí")

now_str = datetime.now().strftime("%H:%M | %d/%m/%Y")
today_str = datetime.now().strftime("%Y-%m-%d")

tdee = current_profile.get("tdee")
goal = current_profile.get("goal", "maintain")
consumed_calories = orch.get_daily_calories(st.session_state.user_id, today_str)

if tdee:
    macro_targets = orch.get_macro_targets(tdee, goal)
    target_calories = macro_targets["target_calories"]
    diff = consumed_calories - target_calories
    if diff > 0:
        calorie_msg = f"Hôm nay bạn đã dư thừa {diff:.0f} kcal"
    elif diff < 0:
        calorie_msg = f"Hôm nay bạn đang thâm hụt {abs(diff):.0f} kcal"
    else:
        calorie_msg = "Hôm nay bạn đã ăn vừa đủ lượng calo mục tiêu"
else:
    calorie_msg = f"Hôm nay bạn đã tiêu thụ {consumed_calories:.0f} kcal (Cập nhật hồ sơ để xem mục tiêu)"

st.markdown(f"<div style='background-color: #e8f8ef; padding: 10px 15px; border-radius: 10px; color: #165a38; margin-bottom: 15px; font-weight: 500; font-size: 15px;'>📍 {display_loc} &nbsp;&nbsp;|&nbsp;&nbsp; 🕒 {now_str} &nbsp;&nbsp;|&nbsp;&nbsp; {weather_info} &nbsp;&nbsp;|&nbsp;&nbsp; ⚡ {calorie_msg}</div>", unsafe_allow_html=True)

tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs(["📸 Phân tích bữa ăn", "💬 Tư vấn thông minh", "👤 Hồ sơ người dùng", "📊 Chỉ số cơ thể", "📔 Nhật ký ăn uống", "📈 Biểu đồ theo dõi"])

with tab1:
    left_col, right_col = st.columns([2, 1], gap="large")

    with left_col:
        st.subheader("Nhận diện món ăn")
        
        # Tùy chọn nguồn ảnh
        input_source = st.radio("Chọn nguồn ảnh:", ["📁 Tải ảnh lên", "📸 Chụp từ Camera"], horizontal=True)
        
        raw_image = None
        if input_source == "📁 Tải ảnh lên":
            raw_image = st.file_uploader("Kéo thả hoặc chọn file ảnh món ăn...", type=["jpg", "jpeg", "png", "webp"])
            if raw_image:
                st.image(raw_image, caption="Ảnh chuẩn bị phân tích", use_container_width=True)
        else:
            raw_image = st.camera_input("Chụp ảnh món ăn")

        if raw_image:
            if st.button("🔍 Tiến hành phân tích", use_container_width=True, type="primary"):
                with st.spinner("Đang tính toán dinh dưỡng..."):
                    try:
                        result = orch.process_full_vision_flow(raw_image, st.session_state.user_id)
                        st.success("✅ Phân tích hoàn tất!")
                        
                        # Cải thiện giao diện hiển thị thay vì dùng st.json()
                        items = getattr(result, "detected_items", [])
                        if not items:
                            st.warning("Không nhận diện được món ăn nào rõ ràng trong ảnh.")
                        else:
                            st.markdown("### 📊 Tổng quan dinh dưỡng")
                            # Lấy kết quả trực tiếp từ Orchestrator, không xử lý logic tính toán ở tầng giao diện
                            t_cal = getattr(result, "total_calories", 0)
                            t_pro = getattr(result, "total_protein", 0)
                            t_carb = getattr(result, "total_carb", 0)
                            t_fat = getattr(result, "total_fat", 0)

                            # Cấp cho cột đầu tiên nhiều không gian hơn một chút (tỷ lệ 1.4 so với 1 của các cột khác)
                            m1, m2, m3, m4 = st.columns([1.4, 1, 1, 1])
                            m1.metric("Calories", f"{t_cal:.0f} kcal")
                            m2.metric("Protein", f"{t_pro:.1f} g")
                            m3.metric("Carb", f"{t_carb:.1f} g")
                            m4.metric("Fat", f"{t_fat:.1f} g")

                            st.markdown("### 🍲 Chi tiết món ăn")
                            for item in items:
                                name = getattr(item, "food_name", "Không rõ").title()
                                cal = getattr(item, "calories", 0) or 0

                                with st.expander(f"🍱 **{name}** - {cal:.0f} kcal", expanded=True):
                                    # Chuyển đối tượng thành dictionary để đọc động toàn bộ tham số
                                    if hasattr(item, "model_dump"):
                                        item_data = item.model_dump()
                                    elif hasattr(item, "dict"):
                                        item_data = item.dict()
                                    else:
                                        item_data = vars(item)
                                        
                                    # Lọc bỏ các trường dữ liệu tĩnh, giữ lại thông số dinh dưỡng
                                    exclude_keys = {"food_name", "confidence", "serving_size", "source", "calories"}
                                    nutrients = {
                                        k: v for k, v in item_data.items() 
                                        if k not in exclude_keys and isinstance(v, (int, float)) and v is not None
                                    }
                                    
                                    if nutrients:
                                        nutri_keys = list(nutrients.keys())
                                        # Trải đều thành các hàng, mỗi hàng chứa 3 cột số liệu
                                        for i in range(0, len(nutri_keys), 3):
                                            cols = st.columns(3)
                                            for j, nut_k in enumerate(nutri_keys[i:i+3]):
                                                v = nutrients[nut_k]
                                                label = nut_k.replace("_", " ").title()
                                                # Chọn đơn vị hiển thị (mg hoặc g)
                                                unit = "mg" if any(x in nut_k for x in ["sodium", "potassium", "calcium", "vitamin"]) else "g"
                                                cols[j].markdown(f"**{label}:** {v:.1f} {unit}")
                                    else:
                                        st.write("Không có thông tin chi tiết.")
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

        ctrl_col1, ctrl_col2 = st.columns([1, 2])
        with ctrl_col1:
            if st.button("🗑️ Xóa hội thoại này", use_container_width=True):
                active_id = st.session_state.active_session_id
                if len(st.session_state.chat_sessions) > 1:
                    del st.session_state.chat_sessions[active_id]
                    st.session_state.active_session_id = list(st.session_state.chat_sessions.keys())[0]
                else:
                    # Nếu chỉ còn 1 hội thoại, thì làm mới nó
                    st.session_state.chat_sessions[active_id]["messages"] = []
                    st.session_state.chat_sessions[active_id]["title"] = "Hội thoại mới"
                save_active_chat_history()
                st.rerun()
        with ctrl_col2:
            isolated_test_mode = st.checkbox(
                "Chế độ test độc lập từng câu",
                value=True,
                help="Bật để mỗi câu hỏi được xử lý độc lập, không mang theo lịch sử chat trước đó.",
            )

        # Luồng 2C: Chatbot & Context Orchestration
        active_id = st.session_state.active_session_id
        current_chat_history = st.session_state.chat_sessions[active_id]["messages"]

        # Bọc lịch sử chat trong container có chiều cao cố định để thanh chat luôn ở dưới
        chat_container = st.container(height=350, border=False)
        
        with chat_container:
            for msg in current_chat_history:
                with st.chat_message(msg["role"]):
                    st.markdown(str(msg["content"]))

        # Đặt input ở cuối luồng render; sau khi gửi sẽ rerun để lịch sử hiển thị phía trên input.
        prompt = st.chat_input("Hỏi chuyên gia EcoNutri...")
        if prompt:
            if isolated_test_mode:
                current_chat_history.clear()

            current_chat_history.append({"role": "user", "content": prompt})

            # Tự động đặt tên hội thoại theo câu hỏi đầu tiên
            if len(current_chat_history) == 1:
                short_title = prompt[:20] + "..." if len(prompt) > 20 else prompt
                st.session_state.chat_sessions[active_id]["title"] = short_title

            save_active_chat_history()

            # Hiển thị ngay câu hỏi của user và render câu trả lời dạng luồng (streaming)
            with chat_container:
                with st.chat_message("user"):
                    st.markdown(prompt)

                recent_turns = current_chat_history[-4:]

                with st.chat_message("assistant"):
                    try:
                        with st.spinner("EcoNutri đang suy nghĩ..."):
                            response_obj = orch.get_personalized_advice(
                                st.session_state.user_id,
                                prompt,
                                recent_chat=recent_turns,
                                user_lat=st.session_state.user_lat,
                                user_lon=st.session_state.user_lon,
                            )

                        response = ""
                        if isinstance(response_obj, tuple) and len(response_obj) == 2:
                            answer_stream, advice_context = response_obj
                            
                            # Cải tiến UX: Hiển thị text đang gõ (Streaming) giống ChatGPT
                            message_placeholder = st.empty()
                            streamed_text = ""
                            buffer = []
                            last_update = time.time()
                            for chunk in answer_stream:
                                buffer.append(str(chunk))
                                # Cập nhật UI mỗi 0.05 giây hoặc khi buffer có 5 chunks để giảm tải render
                                if time.time() - last_update > 0.05 or len(buffer) > 5:
                                    streamed_text += "".join(buffer)
                                    buffer.clear()
                                    message_placeholder.markdown(streamed_text + "▌")
                                    last_update = time.time()
                            
                            # Xả nốt buffer cuối cùng
                            if buffer:
                                streamed_text += "".join(buffer)
                                message_placeholder.markdown(streamed_text + "▌")
                                
                            suffix = str(orch.get_advice_suffix(advice_context, response_text=streamed_text) or "")
                            if suffix:
                                streamed_text += "\n\n" + suffix
                            
                            message_placeholder.markdown(streamed_text)
                            response = streamed_text
                        else:
                            response = str(response_obj)
                            st.markdown(response)

                        if not response or not str(response).strip():
                            response = "Mình đã nhận câu hỏi, nhưng LLM vừa trả về rỗng. Bạn thử hỏi chi tiết hơn một chút nhé."
                            st.markdown(response)

                        current_chat_history.append({"role": "assistant", "content": response})
                        save_active_chat_history()
                    except Exception as exc:
                        error_msg = f"Không thể tạo tư vấn lúc này: {exc}"
                        st.error(error_msg)
                        current_chat_history.append({"role": "assistant", "content": error_msg})
                        save_active_chat_history()

            st.rerun()

with tab3:
    st.subheader("👤 Hồ sơ người dùng")
    
    # Đặt form vào cột giữa để giao diện không bị quá rộng
    p_col1, p_col2, p_col3 = st.columns([1, 2, 1])
    with p_col2:
        # Ủy quyền cho Orchestrator thay vì gọi trực tiếp sql_repo (tránh vi phạm Layered Architecture)
        existing_profile = orch.get_user_profile(st.session_state.user_id) or {}
        
            
        with st.form("user_profile_form_tab3", clear_on_submit=False):
            name = st.text_input("Tên", value=existing_profile.get("name", ""))
            age = st.number_input("Tuổi", min_value=0, max_value=120, value=int(existing_profile.get("age") or 0), step=1)
            job = st.text_input("Công việc", value=existing_profile.get("job", ""))
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
            allergies = st.text_input("Dị ứng", value=existing_profile.get("allergies", ""))
            medical_conditions = st.text_input("Bệnh lý nền", value=existing_profile.get("medical_conditions", ""))

            save_profile = st.form_submit_button("💾 Lưu hồ sơ", use_container_width=True)
            if save_profile:
                orch.upsert_user_profile(
                    user_id=st.session_state.user_id,
                    user_data={
                        "name": name, "age": age, "job": job, "gender": gender, "height_cm": height_cm,
                        "weight_kg": weight_kg, "activity_level": activity_level, "goal": goal,
                        "allergies": allergies, "medical_conditions": medical_conditions,
                    },
                )
                st.success("Đã lưu hồ sơ vào database.")
                time.sleep(0.5)
                st.rerun()

with tab4:
    st.subheader("📊 Chỉ số cơ thể (Body Metrics)")
    
    # Lấy thông tin user (đã bao gồm các chỉ số được lưu trong CSDL)
    existing_profile = orch.get_user_profile(st.session_state.user_id) or {}
    
    bmi = existing_profile.get("bmi")
    bmr = existing_profile.get("bmr")
    tdee = existing_profile.get("tdee")
    body_fat = existing_profile.get("body_fat_percent")

    if bmi is not None and bmr is not None and tdee is not None and body_fat is not None:
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("BMI", f"{bmi:.1f}", help="Chỉ số khối cơ thể (Body Mass Index)")
        c2.metric("BMR", f"{bmr:.0f} kcal", help="Tỷ lệ trao đổi chất cơ bản (Basal Metabolic Rate)")
        c3.metric("TDEE", f"{tdee:.0f} kcal", help="Tổng lượng năng lượng tiêu hao mỗi ngày (Total Daily Energy Expenditure)")
        c4.metric("Body Fat", f"{body_fat:.1f} %", help="Tỷ lệ mỡ cơ thể ước tính")
        
        st.info("💡 **Lưu ý:** Các chỉ số được tự động tính toán bằng công thức y khoa dựa trên Hồ sơ người dùng của bạn. Tỷ lệ mỡ (Body Fat) là giá trị ước lượng tương đối.")
        
        goal = existing_profile.get("goal", "maintain")
        macro_targets = orch.get_macro_targets(tdee, goal)
        st.divider()
        st.markdown("### 🎯 Mục tiêu dinh dưỡng hàng ngày")
        st.markdown(f"Dựa trên mục tiêu **{goal}** và TDEE của bạn, đây là lượng calo và Macro khuyến nghị mỗi ngày:")
        mc1, mc2, mc3, mc4 = st.columns(4)
        mc1.metric("Calories Mục tiêu", f"{macro_targets['target_calories']:.0f} kcal")
        mc2.metric("Protein (Đạm)", f"{macro_targets['protein']:.1f} g")
        mc3.metric("Carb (Tinh bột)", f"{macro_targets['carb']:.1f} g")
        mc4.metric("Fat (Chất béo)", f"{macro_targets['fat']:.1f} g")
    else:
        st.warning("⚠️ Vui lòng chuyển sang tab 'Hồ sơ người dùng' và điền đầy đủ (Tuổi, Giới tính, Chiều cao, Cân nặng, Mức vận động) rồi bấm Lưu hồ sơ để xem các chỉ số này!")

with tab5:
    st.subheader("📔 Nhật ký ăn uống")
    
    diary_entries = orch.get_user_diary(st.session_state.user_id, limit=50)
    
    if not diary_entries:
        st.info("Bạn chưa có nhật ký ăn uống nào. Hãy sử dụng tab 'Phân tích bữa ăn' để nhận diện và thêm món ăn mới nhé!")
    else:
        for entry in diary_entries:
            food_name = str(entry.get("food_name", "Không rõ")).title()
            cal = entry.get("calories") or 0.0
            created_at = entry.get("created_at", "")
            
            with st.expander(f"🍽️ **{food_name}** - {cal:.0f} kcal ({created_at})"):
                col1, col2, col3 = st.columns(3)
                col1.metric("Protein", f"{entry.get('protein') or 0:.1f} g")
                col2.metric("Carb", f"{entry.get('carb') or 0:.1f} g")
                col3.metric("Fat", f"{entry.get('fat') or 0:.1f} g")
                
                img_path = entry.get("image_path")
                if img_path:
                    p = Path(img_path)
                    if p.exists():
                        st.image(str(p), caption="Ảnh gốc đã tải lên", width=300)

with tab6:
    st.subheader("📈 Biểu đồ theo dõi")
    
    ctrl_col1, ctrl_col2 = st.columns(2)
    with ctrl_col1:
        metric_choice = st.selectbox("Chọn chỉ số theo dõi:", ["Cân nặng (kg)", "Calories tiêu thụ (kcal)", "Protein tiêu thụ (g)"])
    with ctrl_col2:
        time_agg = st.radio("Hiển thị theo:", ["Ngày", "Tuần", "Tháng"], horizontal=True)

    if metric_choice == "Cân nặng (kg)":
        weights = orch.get_weight_history(st.session_state.user_id)
        if not weights:
            st.info("Chưa có dữ liệu cân nặng. Hãy sang tab 'Hồ sơ người dùng' nhấn lưu hồ sơ để ghi nhận!")
        else:
            df = pd.DataFrame(weights)
            df['dt'] = pd.to_datetime(df['recorded_at'])
            if time_agg == "Ngày":
                df['Thời gian'] = df['dt'].dt.strftime('%Y-%m-%d')
            elif time_agg == "Tuần":
                df['Thời gian'] = df['dt'].dt.strftime('%Y-W%V')
            else:
                df['Thời gian'] = df['dt'].dt.strftime('%Y-%m')
                
            df_agg = df.groupby('Thời gian')['weight_kg'].mean().reset_index()
            st.line_chart(df_agg.set_index('Thời gian'), y='weight_kg')
            
    else:
        nutritions = orch.get_nutrition_history(st.session_state.user_id)
        if not nutritions:
            st.info("Chưa có dữ liệu ăn uống. Hãy sử dụng tính năng 'Phân tích bữa ăn' để ghi nhận nhé!")
        else:
            df = pd.DataFrame(nutritions)
            df['dt'] = pd.to_datetime(df['created_at'])
            if time_agg == "Ngày":
                df['Thời gian'] = df['dt'].dt.strftime('%Y-%m-%d')
            elif time_agg == "Tuần":
                df['Thời gian'] = df['dt'].dt.strftime('%Y-W%V')
            else:
                df['Thời gian'] = df['dt'].dt.strftime('%Y-%m')
                
            if metric_choice == "Calories tiêu thụ (kcal)":
                df_agg = df.groupby('Thời gian')['calories'].sum().reset_index()
                st.line_chart(df_agg.set_index('Thời gian'), y='calories')
            elif metric_choice == "Protein tiêu thụ (g)":
                df_agg = df.groupby('Thời gian')['protein'].sum().reset_index()
                st.line_chart(df_agg.set_index('Thời gian'), y='protein')