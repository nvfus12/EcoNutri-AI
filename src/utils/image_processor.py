"""
image_processor.py
------------------
Tiền xử lý ảnh (Image Pre-processing Utility)

Nhiệm vụ:
  Đứng giữa đầu vào của người dùng (upload ảnh trên Streamlit) và
  vision_engine.py (YOLO inference).

Flow:
  [User upload ảnh trên Streamlit]
       │
       ▼
  image_processor.py  ← file này
    1. Validate ảnh (định dạng, kích thước file)
    2. Resize / letterbox về kích thước chuẩn cho YOLO
    3. Lưu bản gốc vào IMAGE_UPLOAD_DIR với tên file an toàn
    4. Trả về (numpy_array, saved_path) cho vision_engine.py
       │
       ▼
  vision_engine.py  →  YOLO inference  →  VisionResult schema
"""

from __future__ import annotations

import hashlib
import io
import logging
import time
from pathlib import Path
from typing import Optional, Tuple

import cv2
import numpy as np
from PIL import Image, UnidentifiedImageError

from src.core.config import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Hằng số
# ---------------------------------------------------------------------------

# Các định dạng ảnh được chấp nhận
ALLOWED_EXTENSIONS: set[str] = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}

# Giới hạn kích thước file: 10 MB
MAX_FILE_SIZE_BYTES: int = 10 * 1024 * 1024

# Kích thước cạnh dài tối đa khi resize (YOLO sẽ nhận ảnh này)
# YOLOv8n mặc định 640×640 - letterbox giữ nguyên tỷ lệ
YOLO_INPUT_SIZE: int = 640

# Chất lượng nén khi lưu JPEG
JPEG_QUALITY: int = 92


# ---------------------------------------------------------------------------
# Custom exception
# ---------------------------------------------------------------------------

class ImageProcessingError(ValueError):
    """Raise khi ảnh không hợp lệ hoặc xử lý thất bại."""


# ---------------------------------------------------------------------------
# Hàm nội bộ (private helpers)
# ---------------------------------------------------------------------------

def _validate_file_size(raw_bytes: bytes) -> None:
    """Kiểm tra kích thước file không vượt MAX_FILE_SIZE_BYTES."""
    size = len(raw_bytes)
    if size == 0:
        raise ImageProcessingError("File ảnh rỗng (0 bytes).")
    if size > MAX_FILE_SIZE_BYTES:
        mb = size / (1024 * 1024)
        raise ImageProcessingError(
            f"File ảnh quá lớn ({mb:.1f} MB). Giới hạn tối đa là "
            f"{MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB."
        )


def _validate_extension(filename: str) -> None:
    """Kiểm tra đuôi file nằm trong danh sách cho phép."""
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ImageProcessingError(
            f"Định dạng '{ext}' không được hỗ trợ. "
            f"Chỉ chấp nhận: {', '.join(sorted(ALLOWED_EXTENSIONS))}."
        )


def _bytes_to_pil(raw_bytes: bytes) -> Image.Image:
    """Chuyển bytes thô sang PIL Image, phát hiện file giả mạo."""
    try:
        img = Image.open(io.BytesIO(raw_bytes))
        img.verify()  # Phát hiện file bị corrupt
        # Phải mở lại sau verify() vì PIL đóng stream
        img = Image.open(io.BytesIO(raw_bytes))
        return img
    except UnidentifiedImageError as exc:
        raise ImageProcessingError("Không nhận dạng được file ảnh. File có thể bị lỗi hoặc bị giả mạo.") from exc
    except Exception as exc:
        raise ImageProcessingError(f"Lỗi khi đọc ảnh: {exc}") from exc


def _to_rgb_numpy(pil_img: Image.Image) -> np.ndarray:
    """
    Chuẩn hóa kênh màu về RGB uint8.
    Xử lý các trường hợp: RGBA, grayscale (L), palette (P), CMYK...
    """
    if pil_img.mode == "RGBA":
        # Ghép alpha lên nền trắng
        background = Image.new("RGB", pil_img.size, (255, 255, 255))
        background.paste(pil_img, mask=pil_img.split()[3])
        pil_img = background
    elif pil_img.mode != "RGB":
        pil_img = pil_img.convert("RGB")

    img_np = np.array(pil_img, dtype=np.uint8)
    # PIL → numpy đã là RGB; YOLO và OpenCV cần nhất quán
    return img_np  # shape: (H, W, 3), dtype: uint8, channels: RGB


def _letterbox_resize(
    img_rgb: np.ndarray,
    target_size: int = YOLO_INPUT_SIZE,
) -> np.ndarray:
    """
    Resize ảnh về target_size × target_size bằng letterbox (giữ tỷ lệ gốc).
    Phần thừa được pad bằng màu xám (114, 114, 114) - chuẩn ultralytics.

    Trả về:
        numpy array uint8 RGB, shape (target_size, target_size, 3)
    """
    h, w = img_rgb.shape[:2]

    # Tính tỷ lệ scale
    scale = target_size / max(h, w)
    new_w = int(round(w * scale))
    new_h = int(round(h * scale))

    # Resize (dùng INTER_LINEAR cho ảnh phóng to, INTER_AREA cho thu nhỏ)
    interp = cv2.INTER_LINEAR if scale > 1 else cv2.INTER_AREA
    # cv2 cần BGR; nhưng letterbox + pad không phụ thuộc màu kênh nên OK với RGB
    resized = cv2.resize(img_rgb, (new_w, new_h), interpolation=interp)

    # Tạo canvas pad
    canvas = np.full((target_size, target_size, 3), 114, dtype=np.uint8)
    pad_top = (target_size - new_h) // 2
    pad_left = (target_size - new_w) // 2
    canvas[pad_top : pad_top + new_h, pad_left : pad_left + new_w] = resized

    return canvas  # (640, 640, 3) RGB


def _generate_safe_filename(original_filename: str, user_id: Optional[int] = None) -> str:
    """
    Tạo tên file an toàn: không chứa ký tự đặc biệt, không bị trùng lặp.
    Format: <user_id>_<timestamp_ms>_<hash6>.<ext>
    """
    ext = Path(original_filename).suffix.lower() or ".jpg"
    timestamp_ms = int(time.time() * 1000)
    hash_suffix = hashlib.md5(f"{original_filename}{timestamp_ms}".encode()).hexdigest()[:6]
    uid_prefix = f"{user_id}_" if user_id is not None else ""
    return f"{uid_prefix}{timestamp_ms}_{hash_suffix}{ext}"


def _save_original_image(raw_bytes: bytes, save_path: Path) -> None:
    """Lưu bytes ảnh gốc ra đĩa (không rescale, giữ chất lượng gốc)."""
    save_path.parent.mkdir(parents=True, exist_ok=True)
    save_path.write_bytes(raw_bytes)
    logger.debug("Đã lưu ảnh gốc: %s (%d bytes)", save_path, len(raw_bytes))


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

class ImageProcessor:
    """
    Lớp tiền xử lý ảnh trước khi đưa vào YOLO.

    Sử dụng điển hình (ở Streamlit hoặc orchestrator.py):
    -------------------------------------------------------
        processor = ImageProcessor()

        # Từ Streamlit UploadedFile
        result = processor.process_upload(
            raw_bytes   = uploaded_file.read(),
            filename    = uploaded_file.name,
            user_id     = st.session_state.user_id,
        )

        # Đưa vào vision_engine
        yolo_result = vision_engine.detect(result.model_input_array)

        # Lưu vào DB
        db_repo.save_vision_log(
            user_id    = user_id,
            food_name  = yolo_result.food_name,
            calories   = yolo_result.calories,
            image_path = str(result.saved_path),
        )
    """

    def __init__(
        self,
        upload_dir: Optional[Path] = None,
        yolo_size: int = YOLO_INPUT_SIZE,
    ) -> None:
        self.upload_dir = upload_dir or settings.IMAGE_UPLOAD_DIR
        self.yolo_size = yolo_size

    # ------------------------------------------------------------------
    # Phương thức chính
    # ------------------------------------------------------------------

    def process_upload(
        self,
        raw_bytes: bytes,
        filename: str,
        user_id: Optional[int] = None,
    ) -> "ProcessedImage":
        """
        Pipeline đầy đủ: validate → decode → resize → save.

        Parameters
        ----------
        raw_bytes : bytes
            Bytes thô của file ảnh (từ st.file_uploader hoặc IO stream).
        filename : str
            Tên file gốc, dùng để kiểm tra extension và tạo tên lưu trữ.
        user_id : int | None
            ID người dùng (dùng để tổ chức thư mục và đặt tên file).

        Returns
        -------
        ProcessedImage
            Chứa: numpy array RGB sẵn cho YOLO, đường dẫn file đã lưu,
            kích thước gốc, kích thước sau resize.

        Raises
        ------
        ImageProcessingError
            Khi file không hợp lệ hoặc xử lý thất bại.
        """
        logger.info("Bắt đầu xử lý ảnh: '%s' (user_id=%s)", filename, user_id)

        # Bước 1: Validate đầu vào
        _validate_extension(filename)
        _validate_file_size(raw_bytes)

        # Bước 2: Decode sang PIL → numpy RGB
        pil_img = _bytes_to_pil(raw_bytes)
        original_size: Tuple[int, int] = pil_img.size  # (W, H)
        img_rgb = _to_rgb_numpy(pil_img)

        # Bước 3: Letterbox resize về kích thước YOLO
        model_input = _letterbox_resize(img_rgb, target_size=self.yolo_size)

        # Bước 4: Lưu ảnh gốc
        safe_name = _generate_safe_filename(filename, user_id)
        # Tổ chức theo thư mục user nếu có
        sub_dir = self.upload_dir / str(user_id) if user_id is not None else self.upload_dir
        saved_path = sub_dir / safe_name
        _save_original_image(raw_bytes, saved_path)

        logger.info(
            "Xử lý ảnh xong. Gốc: %s → YOLO: (%d,%d). Lưu tại: %s",
            original_size,
            self.yolo_size,
            self.yolo_size,
            saved_path,
        )

        return ProcessedImage(
            model_input_array=model_input,
            saved_path=saved_path,
            original_size=original_size,
            resized_size=(self.yolo_size, self.yolo_size),
        )

    def process_from_path(self, image_path: Path, user_id: Optional[int] = None) -> "ProcessedImage":
        """
        Xử lý ảnh từ đường dẫn file cục bộ.
        Hữu ích cho script test hoặc batch processing.
        """
        if not image_path.exists():
            raise ImageProcessingError(f"File không tồn tại: {image_path}")
        raw_bytes = image_path.read_bytes()
        return self.process_upload(raw_bytes, image_path.name, user_id)


# ---------------------------------------------------------------------------
# Data class kết quả
# ---------------------------------------------------------------------------

class ProcessedImage:
    """
    Kết quả trả về từ ImageProcessor.process_upload().

    Attributes
    ----------
    model_input_array : np.ndarray
        Ảnh RGB uint8 đã letterbox (640×640×3), sẵn sàng đưa vào YOLO.
        vision_engine.py sẽ tự normalize (÷255) trước khi infer.
    saved_path : Path
        Đường dẫn tuyệt đối tới file ảnh gốc đã lưu trên đĩa.
        Dùng để ghi vào cột `image_path` trong bảng `meal_logs`.
    original_size : Tuple[int, int]
        Kích thước gốc (width, height) của ảnh trước khi resize.
    resized_size : Tuple[int, int]
        Kích thước canvas sau letterbox (thường là 640, 640).
    """

    def __init__(
        self,
        model_input_array: np.ndarray,
        saved_path: Path,
        original_size: Tuple[int, int],
        resized_size: Tuple[int, int],
    ) -> None:
        self.model_input_array = model_input_array
        self.saved_path = saved_path
        self.original_size = original_size
        self.resized_size = resized_size

    def __repr__(self) -> str:
        return (
            f"ProcessedImage("
            f"original={self.original_size}, "
            f"resized={self.resized_size}, "
            f"saved='{self.saved_path.name}')"
        )


# ---------------------------------------------------------------------------
# Singleton (dùng trong toàn hệ thống như db_repo)
# ---------------------------------------------------------------------------

image_processor = ImageProcessor()
