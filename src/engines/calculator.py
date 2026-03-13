import math
from src.core.constants import (
    BMI_UNDERWEIGHT, BMI_NORMAL_MAX, BMI_OVERWEIGHT_MAX,
    CALORIES_PER_PROTEIN, CALORIES_PER_CARB, CALORIES_PER_FAT,
    BMR_MALE_ADJUSTMENT, BMR_FEMALE_ADJUSTMENT,
    ACTIVITY_MULTIPLIERS, DEFAULT_MACRO_RATIO
)
from src.core.exceptions import ValidationError

class NutritionCalculator:
    """
    Engine thực hiện các tính toán chỉ số cơ thể và nhu cầu dinh dưỡng.
    """

    @staticmethod
    def calculate_bmi(weight: float, height_cm: float) -> dict:
        """
        Tính toán BMI (Body Mass Index) theo chuẩn Asian-Pacific.
        Công thức: $$BMI = \frac{weight(kg)}{height(m)^2}$$
        """
        if height_cm <= 0 or weight <= 0:
            raise ValidationError("Chiều cao và cân nặng phải lớn hơn 0.")
            
        height_m = height_cm / 100
        bmi = round(weight / (height_m ** 2), 2)
        
        # Phân loại theo chuẩn Asian
        if bmi < BMI_UNDERWEIGHT:
            category = "Thiếu cân"
        elif bmi <= BMI_NORMAL_MAX:
            category = "Bình thường"
        elif bmi <= BMI_OVERWEIGHT_MAX:
            category = "Thừa cân"
        else:
            category = "Béo phì"
            
        return {"bmi": bmi, "category": category}

    @staticmethod
    def calculate_bmr(weight: float, height_cm: float, age: int, gender: str) -> float:
        """
        Tính BMR theo công thức Mifflin-St Jeor.
        Nam: $$BMR = 10w + 6.25h - 5a + 5$$
        Nữ: $$BMR = 10w + 6.25h - 5a - 161$$
        """
        adjustment = BMR_MALE_ADJUSTMENT if gender.lower() == "male" else BMR_FEMALE_ADJUSTMENT
        bmr = (10 * weight) + (6.25 * height_cm) - (5 * age) + adjustment
        return round(bmr, 2)

    @staticmethod
    def calculate_tdee(bmr: float, activity_level: str) -> float:
        """Tính tổng năng lượng tiêu thụ hàng ngày (Total Daily Energy Expenditure)"""
        multiplier = ACTIVITY_MULTIPLIERS.get(activity_level, 1.2)
        return round(bmr * multiplier, 2)

    @staticmethod
    def estimate_body_fat(bmi: float, age: int, gender: str) -> float:
        """
        Ước tính %Body Fat dựa trên BMI (Công thức Adult Body Fat).
        Nam: $$BF = 1.20 \times BMI + 0.23 \times Age - 16.2$$
        Nữ: $$BF = 1.20 \times BMI + 0.23 \times Age - 5.4$$
        """
        gender_val = 1 if gender.lower() == "male" else 0
        body_fat = (1.20 * bmi) + (0.23 * age) - (10.8 * gender_val) - 5.4
        return round(max(body_fat, 0), 2)

    @classmethod
    def get_macro_targets(cls, tdee: float, goal: str = "maintain") -> dict:
        """
        Tính toán mục tiêu Macro (Protein, Carb, Fat) dựa trên mục tiêu.
        goal: 'lose', 'maintain', 'gain'
        """
        # Điều chỉnh Calo theo mục tiêu
        if goal == "lose":
            target_calories = tdee - 500  # Thâm hụt 500kcal
        elif goal == "gain":
            target_calories = tdee + 500  # Dư thừa 500kcal
        else:
            target_calories = tdee

        # Tính toán theo tỷ lệ chuẩn trong constants
        protein_g = (target_calories * DEFAULT_MACRO_RATIO["protein"]) / CALORIES_PER_PROTEIN
        carb_g = (target_calories * DEFAULT_MACRO_RATIO["carb"]) / CALORIES_PER_CARB
        fat_g = (target_calories * DEFAULT_MACRO_RATIO["fat"]) / CALORIES_PER_FAT

        return {
            "target_calories": round(target_calories, 0),
            "protein": round(protein_g, 1),
            "carb": round(carb_g, 1),
            "fat": round(fat_g, 1)
        }