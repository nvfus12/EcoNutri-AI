FROM python:3.10-slim

# Cài đặt các thư viện hệ thống cần thiết để build llama-cpp-python và chạy YOLO (OpenCV)
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    libgl1 \
    libglib2.0-0 \
    python3-dev \
    python3-distutils \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy file requirements và cài đặt
COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip wheel "setuptools<70.0.0"

# Ép các thư viện khi build phải dùng distutils của hệ thống
ENV SETUPTOOLS_USE_DISTUTILS=stdlib
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ mã nguồn vào container
COPY . .

EXPOSE 8501

# Khởi chạy ứng dụng Streamlit, lắng nghe ở tất cả IP để Cloud có thể route tới
CMD ["streamlit", "run", "src/app.py", "--server.port=8501", "--server.address=0.0.0.0"]