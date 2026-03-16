# 📜 EcoNutri: AI Assistant Context & Implementation Standards

## 🎯 1. Project Mission & Core Values
EcoNutri là Dashboard tư vấn dinh dưỡng cá nhân hóa dựa trên tiêu chí **Sustainable AI**:
- **Offline-First:** Xử lý ảnh (YOLO) và dữ liệu nhạy cảm ngay trên thiết bị để bảo vệ quyền riêng tư.
- **Resource-Efficient:** Sử dụng Quantized LLM (GGUF) và Local Database để tối ưu tài nguyên (Green AI).
- **Credibility:** Tư vấn phải có dẫn nguồn tri thức y khoa từ hệ thống RAG.

---

## 🏗 2. Layered Architecture (Directory Responsibilities)
Hệ thống tuân thủ nghiêm ngặt tính đóng gói (Encapsulation). Tuyệt đối không viết logic trộn lẫn giữa các lớp:

- **Presentation Layer (`src/app.py`)**
  - Quản lý giao diện Streamlit và Dashboard.
  - Tiếp nhận Input (ảnh, text) và hiển thị Output. Không xử lý logic nghiệp vụ tại đây.
  - `.streamlit/config.toml`: Cấu hình giao diện (Theme colors, Font), cổng kết nối (Port), và giới hạn Server (VD: maxUploadSize cho ảnh món ăn).

- **Infrastructure Layer (`src/core/`)**
  - `config.py`: Quản lý Settings bằng Pydantic (đọc từ .env và yaml).
  - `constants.py`: Lưu trữ hằng số y khoa (Ngưỡng BMI, Calories chuẩn, Macro ratios).
  - `exceptions.py`: Định nghĩa các lỗi hệ thống tùy chỉnh (Custom Exceptions).

- **Business Logic Layer (`src/services/`)**
  - `orchestrator.py`: "Bộ não" trung tâm, điều phối dữ liệu từ RAG, SQL Profile, và Real-time context cho LLM.
  - `user_service.py`: Xử lý Profile và logic gợi ý đặc sản theo mùa/vùng miền (Seasonality).
  - `diary_service.py`: Xử lý logic lưu trữ và truy xuất nhật ký ăn uống.

- **Inference Layer (`src/engines/`)**
  - `vision_engine.py`: Wrapper thực thi model YOLO để nhận diện món ăn.
  - `rag_engine.py`: Xử lý logic truy vấn Vector Database.
  - `calculator.py`: Engine tính toán các chỉ số cơ thể (%Bodyfat, BMI, BMR).

- **Data Access Layer (`src/repositories/`)**
  - `sql_repo.py`: Thực hiện mọi truy vấn vào SQLite (`econutri.db`).
  - `vector_repo.py`: Thực hiện truy vấn vào Vector Store (`ChromaDB/FAISS`).

- **Contracts Layer (`src/schemas/`)**
  - Định nghĩa cấu trúc dữ liệu bằng Pydantic Models (`user_schema.py`, `vision_schema.py`) để đảm bảo tính nhất quán khi truyền dữ liệu giữa các layer.

- **Utilities Layer (`src/utils/`)**
  - `image_processor.py`: Tiền xử lý ảnh (resize, padding, normalize) trước khi đưa vào model YOLO.

---

## ⚙️ 3. Configuration Management
- **Static Configs (`configs/`)**: 
  - `base.yaml`: Cấu hình chung hệ thống.
  - `prompts.yaml`: Quản lý System Prompts (Cấm hard-code prompt trong code).
  - `vision.yaml`: Tham số tinh chỉnh YOLO (Confidence, NMS threshold).
- **Environment**: Thông tin nhạy cảm nằm ở `.env`.

---

## 🌊 4. Critical Logic Flows (System Execution)

### A. Luồng Quản lý Người dùng (User Profile Flow) - NEW
1. **Input**: Người dùng nhập (Tuổi, Giới tính, Chiều cao $H$, Cân nặng $W$) trên Dashboard.
2. **Validation**: Kiểm tra qua `schemas/user_schema.py`.
3. **Calculation**: `services/user_service.py` gọi `engines/calculator.py` để tính toán
4. **Storage**: `repositories/sql_repo.py` thực hiện INSERT/UPDATE vào bảng `user_profile` trong `database/econutri.db`.

### B. Vision & Nutrition Flow
`User Upload` ➔ `utils/image_processor.py` ➔ `engines/vision_engine.py` (load `weights/yolo_26n_best.pt`) ➔ `schemas/vision_schema.py` ➔ `repositories/sql_repo.py` (tra cứu bảng `nutrition_reference`) ➔ `services/diary_service.py` ➔ `database/econutri.db`.
Lưu ý: nếu ảnh chứa món ăn thì cần lưu lại ảnh vào `data/user_images`

### C. Chatbot Orchestration Flow (The Central Logic)
Khi người dùng đặt câu hỏi, `services/orchestrator.py` phải tổng hợp ngữ cảnh theo thứ tự:
1. Truy xuất tri thức y khoa từ `vector_repo.py`.
2. Lấy Profile người dùng (chiều cao, cân nặng, bệnh lý/dị ứng) từ `sql_repo.py`.
3. Lấy Nhật ký ăn uống gần đây từ `sql_repo.py`.
4. Lấy thông tin mùa màng & đặc sản vùng miền từ `user_service.py` (tra bảng `season`).
5. Tổng hợp Prompt ➔ Thực thi LLM (`weights/qwen2.5-3b-instruct-q4_k_m.gguf`).

---

## 🛠 5. Coding Standards for AI
- **Singleton Pattern:** Load model YOLO và LLM một lần duy nhất (hoặc dùng `@st.cache_resource`).
- **Type Safety:** Bắt buộc sử dụng Type Hints cho tất cả các function.
- **Pydantic Validation:** Luôn kiểm tra dữ liệu đầu vào bằng Schemas trước khi xử lý.
- **No Direct SQL:** Không import `sqlite3` ngoài file `sql_repo.py`.
- **Green AI:** Tối ưu hóa vòng lặp, ưu tiên xử lý mảng bằng numpy/pandas.

---

## 📁 6. Database Storage
- **Relational (SQLite):** `database/econutri.db` (Bao gồm các bảng: user_profile, nutrition_diary, nutrition_reference, season).
- **Vector (ChromaDB):** `database/vector_store/`.
- **Initialization:** Code khởi tạo phải nằm trong `scripts/init_db.py` và `scripts/ingest_knowledge.py`.