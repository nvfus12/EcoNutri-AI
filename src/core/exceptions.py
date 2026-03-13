"""
Custom Exceptions for EcoNutri.
Giúp quản lý lỗi tập trung, tránh crash ứng dụng và cung cấp thông báo UX thân thiện.
"""

class EcoNutriError(Exception):
    """Lớp lỗi cơ sở cho toàn bộ dự án."""
    def __init__(self, message="Đã xảy ra lỗi hệ thống tại EcoNutri"):
        self.message = message
        super().__init__(self.message)

# =============================
# 1. LỖI TẦNG AI (VISION & RAG)
# =============================
class VisionEngineError(EcoNutriError):
    """Lỗi xảy ra trong quá trình nhận diện hình ảnh YOLO."""
    pass

class ModelNotFoundError(VisionEngineError):
    """Lỗi khi không tìm thấy file trọng số (.pt hoặc .gguf)."""
    pass

class RAGEngineError(EcoNutriError):
    """Lỗi khi truy vấn Vector Database hoặc gọi LLM."""
    pass

# =============================
# 2. LỖI TẦNG DỮ LIỆU (SQL & REPO)
# =============================
class DatabaseError(EcoNutriError):
    """Lỗi liên quan đến truy vấn SQLite."""
    pass

class UserNotFoundError(DatabaseError):
    """Lỗi khi không tìm thấy Profile người dùng."""
    pass

class FoodReferenceNotFoundError(DatabaseError):
    """Lỗi khi YOLO nhận diện được món nhưng DB nutrition_reference không có dữ liệu."""
    pass

# =============================
# 3. LỖI TẦNG NGHIỆP VỤ (VALIDATION)
# =============================
class ValidationError(EcoNutriError):
    """Lỗi khi người dùng nhập liệu sai (Ví dụ: Chiều cao = 0)."""
    pass

class InsufficientDataError(EcoNutriError):
    """Lỗi khi không đủ context để Orchestrator đưa ra lời khuyên."""
    pass