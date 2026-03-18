import requests
from pathlib import Path
from src.schemas.vision_schema import VisionResult

class CloudVisionEngine:
    """
    Engine ảo chạy ở Local, nhận đường dẫn ảnh, gửi lên Vision API trên Cloud 
    và trả về schema VisionResult chuẩn cho Orchestrator.
    """
    def __init__(self, api_url: str):
        self.api_url = api_url

    def predict(self, image_path: str) -> VisionResult:
        url = f"{self.api_url}/v1/vision/detect"
        
        with open(image_path, "rb") as f:
            files = {"file": (Path(image_path).name, f, "image/jpeg")}
            response = requests.post(url, files=files, timeout=60)
            response.raise_for_status()
            
            data = response.json()
            return VisionResult(**data)