FROM python:3.10

# Cài đặt các thư viện hệ thống cần thiết để build llama-cpp-python và chạy YOLO (OpenCV)
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy file requirements và cài đặt
COPY requirements.txt .

# Cập nhật công cụ build và setuptools (cung cấp distutils) trước khi cài đặt
RUN pip install --no-cache-dir --upgrade pip "setuptools<70.0.0" wheel
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ mã nguồn vào container
COPY . .

EXPOSE 8501

# Khởi chạy ứng dụng Streamlit, lắng nghe ở tất cả IP để Cloud có thể route tới
CMD ["streamlit", "run", "src/app.py", "--server.port=8501", "--server.address=0.0.0.0"]