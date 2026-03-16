import os
from pathlib import Path
from typing import Optional
import yaml
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

# Xác định thư mục gốc của dự án (Root Directory)
ROOT_DIR = Path(__file__).resolve().parent.parent.parent

class Settings(BaseSettings):
    # --- THÔNG TIN CHUNG ---
    APP_NAME: str = "EcoNutri"
    VERSION: str = "1.0.0"
    DEBUG: bool = False

    # --- ĐƯỜNG DẪN HỆ THỐNG (Paths) ---
    BASE_DIR: Path = ROOT_DIR
    DB_PATH: Path = ROOT_DIR / "database" / "econutri.db"
    VECTOR_STORE_DIR: Path = ROOT_DIR / "database" / "vector_store"
    IMAGE_UPLOAD_DIR: Path = ROOT_DIR / "data" / "user_images"
    
    # --- CẤU HÌNH AI MODELS ---
    # YOLO Model
    YOLO_MODEL_PATH: Path = ROOT_DIR / "weights" / "yolo26n_best.pt"
    YOLO_CONFIDENCE: float = 0.45
    
    # Local LLM (Qwen via llama-cpp-python)
    LLM_MODEL_PATH: Path = ROOT_DIR / "weights" / "qwen2.5-3b-instruct-q4_k_m.gguf"
    LLM_CONTEXT_WINDOW: int = 4096
    LLM_TEMPERATURE: float = 0.2 # Thấp để đảm bảo câu trả lời chính xác, ít "sáng tạo" quá đà
    
    # --- CẤU HÌNH DATABASE & RAG ---
    CHUNK_SIZE: int = 500
    CHUNK_OVERLAP: int = 50
    TOP_K_RETRIEVAL: int = 3 # Số lượng tài liệu y khoa lấy ra mỗi lần query

    # --- BIẾN MÔI TRƯỜNG (Sẽ đọc từ file .env) ---
    # Dù chạy local, đôi khi bạn vẫn cần API key cho Weather hoặc Maps nếu mở rộng
    OPENWEATHER_API_KEY: Optional[str] = None
    SECRET_KEY: str = "hackathon-secret-key-2024"

    # Ưu tiên đọc từ file .env
    model_config = SettingsConfigDict(
        env_file=ROOT_DIR / ".env",
        env_file_encoding='utf-8',
        extra='ignore'
    )

    @classmethod
    def load_from_yaml(cls, yaml_path: str = "configs/base.yaml") -> "Settings":
        """
        Ghi đè cấu hình từ file YAML (nếu cần thiết cho các thông số phi nhạy cảm)
        """
        full_path = ROOT_DIR / yaml_path
        if full_path.exists():
            with open(full_path, "r", encoding="utf-8") as f:
                yaml_data = yaml.safe_load(f)
                return cls(**yaml_data)
        return cls()

# Khởi tạo instance global để sử dụng toàn hệ thống
settings = Settings()

# Đảm bảo các thư mục cần thiết tồn tại
os.makedirs(settings.IMAGE_UPLOAD_DIR, exist_ok=True)
os.makedirs(settings.VECTOR_STORE_DIR, exist_ok=True)