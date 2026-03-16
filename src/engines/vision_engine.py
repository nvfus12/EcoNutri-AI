import yaml
import os
from datetime import datetime
from ultralytics import YOLO
from src.schemas.vision_schema import VisionResult, FoodDetection
from src.core.config import settings

class VisionEngine:
    def __init__(self, config_path: str = None):
        if config_path is None:
            config_path = str(settings.BASE_DIR / "configs" / "vision.yaml")
        # Load cấu hình từ file YAML
        with open(config_path, 'r', encoding='utf-8') as f:
            self.config = yaml.safe_load(f)
        
        # Khởi tạo model YOLO (Chỉ load 1 lần - Singleton pattern)
        self.model = YOLO(self.config['model']['weights_path'])
        self.label_map = self.config.get('label_mapping', {})

    def predict(self, image_path: str) -> VisionResult:
        """Nhận diện món ăn và trả về Schema chuẩn"""
        
        # Chạy Inference
        results = self.model.predict(
            source=image_path,
            conf=self.config['model']['conf_threshold'],
            iou=self.config['model']['iou_threshold'],
            imgsz=self.config['model']['img_size'],
            device=self.config['inference']['device'],
            verbose=False
        )

        result_item = results[0]
        detected_items = []

        for box in result_item.boxes:
            raw_label = result_item.names[int(box.cls[0])]
            confidence = float(box.conf[0])

            # Chuẩn hóa tên nhãn sang tên trong Database (nếu có mapping)
            food_name = self.label_map.get(raw_label, raw_label)

            # Tạo object FoodDetection (Lúc này chỉ có tên và độ tin cậy)
            # Các chỉ số dinh dưỡng sẽ được điền vào ở tầng Service/Repository sau
            detection = FoodDetection(
                food_name=food_name,
                confidence=confidence
            )
            detected_items.append(detection)

        # Trả về kết quả tổng hợp
        return VisionResult(
            detected_items=detected_items,
            image_width=result_item.orig_shape[1],
            image_height=result_item.orig_shape[0]
        )

# Khởi tạo instance dùng chung cho toàn hệ thống
# vision_engine = VisionEngine()