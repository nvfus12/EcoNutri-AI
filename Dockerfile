FROM python:3.10

# Cài đặt các thư viện hệ thống cần thiết để build llama-cpp-python và chạy YOLO (OpenCV)
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy file requirements và cài đặt
COPY requirements.txt .

# Khắc phục triệt để lỗi biên dịch bằng cách lấy thẳng bản cài sẵn (Wheel)
ENV SETUPTOOLS_USE_DISTUTILS=stdlib
RUN pip install --no-cache-dir --upgrade pip "setuptools<65.0.0" wheel
RUN pip install --no-cache-dir -r requirements.txt --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu

# Copy toàn bộ mã nguồn vào container
COPY . .

EXPOSE 8501

# Khởi chạy ứng dụng Streamlit, lắng nghe ở tất cả IP để Cloud có thể route tới
CMD ["streamlit", "run", "src/app.py", "--server.port=8501", "--server.address=0.0.0.0"]