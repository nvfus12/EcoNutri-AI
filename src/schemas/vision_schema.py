from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class FoodDetection(BaseModel):
    # Khớp 100% với các cột trong SQL nutrition_reference
    food_name: str
    confidence: float = 0.0
    
    calories: Optional[float] = 0.0
    protein: Optional[float] = 0.0
    carb: Optional[float] = 0.0
    fat: Optional[float] = 0.0
    sugar: Optional[float] = 0.0
    fiber: Optional[float] = 0.0
    
    sodium: Optional[float] = 0.0
    potassium: Optional[float] = 0.0
    calcium: Optional[float] = 0.0
    
    vitamin_a: Optional[float] = 0.0
    vitamin_b: Optional[float] = 0.0
    vitamin_c: Optional[float] = 0.0
    vitamin_d: Optional[float] = 0.0
    
    source: Optional[str] = None

class VisionResult(BaseModel):
    detected_items: List[FoodDetection]
    total_calories: float = 0.0
    total_protein: float = 0.0
    total_carb: float = 0.0
    total_fat: float = 0.0
    
    image_width: Optional[int] = None
    image_height: Optional[int] = None
    processed_at: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    def update_totals(self):
        """Cập nhật tổng chỉ số sau khi đã lấy dữ liệu từ DB"""
        self.total_calories = round(sum(d.calories for d in self.detected_items), 2)
        self.total_protein = round(sum(d.protein for d in self.detected_items), 2)
        self.total_carb = round(sum(d.carb for d in self.detected_items), 2)
        self.total_fat = round(sum(d.fat for d in self.detected_items), 2)