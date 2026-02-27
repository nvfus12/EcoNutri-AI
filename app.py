import streamlit as st
import sys
sys.path.append("database")

from database.db import get_user_diary 

st.set_page_config(page_title="EcoNutri AI", layout="wide")

st.set_page_config(page_title="EcoNutri AI", layout="wide")

st.title("🌱 EcoNutri AI – Nutrition & Sustainability Dashboard")

st.subheader("📊 Nhật ký ăn uống")

user_id = st.number_input("Nhập User ID", min_value=1, value=1)

if st.button("Xem nhật ký"):
    logs = get_user_diary(user_id)
    if logs:
        st.table(logs)
    else:
        st.warning("Chưa có dữ liệu")