import os
import tempfile
from fastapi import FastAPI, UploadFile, File

from src.engines.vision_engine import VisionEngine

app = FastAPI(title="EcoNutri Vision API")

# Khởi tạo YOLO model (Sẽ chiếm khoảng 100MB RAM)
vision_engine = VisionEngine()

@app.post("/v1/vision/detect")
async def detect_food(file: UploadFile = File(...)):
    contents = await file.read()
    
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(contents)
        tmp_path = tmp.name

    try:
        res = vision_engine.predict(tmp_path)
        return res.model_dump() if hasattr(res, "model_dump") else res.dict()
    finally:
        os.remove(tmp_path)