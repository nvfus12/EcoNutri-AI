"""
EcoNutri Core Package
Lớp vỏ bọc (Encapsulation) cho toàn bộ logic nghiệp vụ của dự án.
"""

__version__ = "1.0.0"
__author__ = "EcoNutri Team"

# Export các thành phần quan trọng để app.py truy cập dễ dàng hơn
# Thay vì: from src.services.orchestrator import ContextOrchestrator
# Ta có thể dùng: from src import ContextOrchestrator

from src.core.config import settings
from src.services.orchestrator import ContextOrchestrator
from src.engines.vision_engine import VisionEngine
from src.engines.calculator import NutritionCalculator
from src.repositories.sql_repo import SQLRepository

__all__ = [
    "settings",
    "ContextOrchestrator",
    "VisionEngine",
    "NutritionCalculator",
    "SQLRepository"
]