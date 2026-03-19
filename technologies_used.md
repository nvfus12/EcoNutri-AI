# 🛠 Danh sách Công nghệ & Framework sử dụng trong EcoNutri-AI

Dự án **EcoNutri-AI** là một ứng dụng tư vấn dinh dưỡng cá nhân hóa tích hợp AI. Dựa trên tính chất của dự án (Offline-first, Green AI, RAG) và cấu trúc mã nguồn, dưới đây là danh sách toàn bộ các công nghệ, thư viện, mô hình và API được sử dụng:

## 1. Ngôn ngữ & Nền tảng (Core)
*   **Python (3.x)**: Trái tim của toàn bộ backend, machine learning và logic nghiệp vụ.
*   **Thư viện tiện ích Core**: 
    - `os`, `sys`, `pathlib`: Quản lý đường dẫn và files.
    - `datetime`, `time`: Xử lý mốc thời gian, tính toán ngày tháng theo mùa màng.
    - `json`, `re`, `hashlib`, `urllib`: Chuẩn hóa text, mã hóa, gọi REST API.

## 2. Giao diện Cửa sổ & Trải nghiệm Người dùng (Frontend Layer)
*   **Streamlit (`streamlit`)**: Khung ứng dụng Web UI. Dùng để render toàn bộ Giao diện Chatbot, tải ảnh lên, cập nhật profile bệnh lý, sinh biểu đồ, mà không cần Frontend rời (React/Vue).
    - Tận dụng `st.session_state` để lưu trữ chuỗi hội thoại.
    - Sử dụng `@st.cache_resource` hoặc `@st.cache_data` để khởi tạo Singleton mô hình AI, giúp tăng tốc tối đa trải nghiệm truy xuất.

## 3. Trí tuệ Nhân tạo & Thuật Toán (AI / ML / DL)
Dự án áp dụng chặt chẽ "Green AI": ưu tiên Local Inference, tiết kiệm vRAM, hạn chế Cloud API:
*   **Thị giác Máy tính (Computer Vision)**:
    *   **Ultralytics YOLO (`ultralytics`)**: Framework nhận diện hình ảnh.
    *   **Model**: `nvfus12/Vietnam-food-object-detection` (`yolo26n_best.pt`) - Huấn luyện riêng để nhận diện các món ăn thuần Việt Nam.
*   **Xử lý Ngôn ngữ Tự nhiên & Sinh tạo (LLMs)**:
    *   **Llama.cpp (`llama-cpp-python`)**: Binding giúp biên dịch C/C++ để chạy các mô hình AI lượng tử hóa (GGUF) trực tiếp trên CPU/GPU phổ thông cục bộ.
    *   **Models**: 
        - `Qwen/Qwen2.5-3B-Instruct-GGUF` (Model chính chạy suy luận logic Chat/Dinh dưỡng).
        - `Qwen/Qwen2.5-0.5B-Instruct-GGUF` (Dự phòng cho thiết bị cấu hình siêu yếu).
*   **Truy xuất thông tin (RAG Text Embedding)**:
    *   **Sentence Transformers (`sentence_transformers`)**: Xây dựng biểu diễn Vector cho câu.
    *   **Model**: `all-MiniLM-L6-v2` (Siêu nhẹ, tốc độ cao để nhúng dữ liệu y khoa).
*   **Bộ lọc An toàn Cơ bản (Safety/Profanity Filter)**:
    *   **Scikit-Learn & Joblib (`scikit-learn`, `joblib`)**: Xây dựng thuật toán ML cổ điển lọc các câu hỏi độc hại, lệch chuẩn trước khi đưa tới LLM.
    *   **Model**: `nvfus12/eco-nutri-questions-filter` (`safety_filter_model.joblib`).
*   **Hugging Face Hub (`huggingface_hub`)**: Kho tài nguyên model registry, dùng bộ SDK để `hf_hub_download` kéo tự động các weight AI trên về `/weights`.

## 4. Xử lý Dữ liệu lớn & Hình ảnh (Data & Image Processing)
*   **Trích xuất Tài Liệu**:
    *   **PDFPlumber (`pdfplumber`)**: Công cụ trích xuất text/bảng biểu cực kỳ chính xác từ các sách Y khoa, sách Sinh lý học gốc (file PDF) để đưa vào Vector DB mà không bị vỡ layout.
*   **Toán học & Tiền xử lý**:
    *   **Pandas & NumPy (`pandas`, `numpy`)**: Đóng vai trò làm Dataframe, matrix engine.
*   **Thao tác Ảnh (Image Prep)**:
    *   **OpenCV & Pillow (`opencv-python-headless`, `cv2`, `PIL`)**: Decode, resize pixel, padding vuông tạo bounding boxes để YOLO nhận diện.

## 5. Lưu trữ Dữ liệu (Databases & Vector Storage)
Triết lý Offline-first, không phụ thuộc Máy chủ Server:
*   **SQLite (`sqlite3`)**: Cơ sở dữ liệu RDMS cục bộ (`econutri.db`). Đảm nhận xử lý các schema `user_profile`, `nutrition_diary`, và cả dữ liệu `season`, `regional_specialties`.
*   **ChromaDB (`chromadb`)**: Hệ quản trị Vector Database (`database/vector_store`). "Trái tim" của hệ thống RAG, lưu trữ Embeddings các kiến thức Dinh dưỡng để truy xuất theo khoảng cách Euclidean / Cosine.

## 6. Kiến trúc Dự án & Dịch vụ Mở rộng (Services & Architecture)
*   **External APIs**:
    *   **OpenWeatherMap API**: Tích hợp module `weather_service.py` để lấy thời tiết theo vĩ độ kinh độ gốc hoặc query theo City Name, tạo insight khí hậu ảnh hưởng thế nào đến mùa màng dinh dưỡng.
*   **Cấu trúc & Design Patterns**:
    *   **Pydantic & Pydantic-Settings (`pydantic`)**: Parsing, Type Hints, Data Validation qua các `schemas/`.
    *   **PyYAML (`PyYAML`, `yaml`)**: Parser file cấu hình `configs/`.
    *   **Kiến trúc Domain-Driven**: Cấu trúc thành các tầng (Layer) rõ ràng nhắm tối ưu hóa Unit Testing: *Presentation Layer* (`app`), *Business Logic* (`services`), *Data Access* (`repositories`), *Inference* (`engines`).

---
_Đây là tài liệu được tổng hợp tự động dựa trên `requirements.txt`, `project_context.md`, và cấu trúc thực tế của folder hệ thống tại dự án EcoNutri-AI._