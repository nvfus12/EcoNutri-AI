"""
Constants for EcoNutri Project.
Dùng cho tính toán chỉ số (Calculator) và thiết lập ngưỡng cảnh báo (Chatbot).
"""

# =============================
# 1. CHỈ SỐ BMI (Chuẩn Asian-Pacific)
# =============================
# Người Việt Nam áp dụng chuẩn IDI & WPRO
BMI_UNDERWEIGHT = 18.5
BMI_NORMAL_MAX = 22.9
BMI_OVERWEIGHT_MAX = 24.9
# BMI >= 25.0 được coi là béo phì (Obese)

# =============================
# 2. HẰNG SỐ DINH DƯỠNG (Calories per Gram)
# =============================
CALORIES_PER_PROTEIN = 4
CALORIES_PER_CARB = 4
CALORIES_PER_FAT = 9
CALORIES_PER_ALCOHOL = 7

# =============================
# 3. NGƯỠNG CẢNH BÁO SỨC KHỎE (Daily Limits - Người trưởng thành)
# =============================
# Dựa trên khuyến nghị của WHO
MAX_DAILY_SUGAR_GRAMS = 50.0   # ~10% tổng năng lượng
MAX_DAILY_SALT_MILLIGRAMS = 5000.0 # ~5g muối (Sodium tương ứng ~2000mg)
MAX_DAILY_SODIUM_MILLIGRAMS = 2000.0

# =============================
# 4. HẰNG SỐ TÍNH BMR (Mifflin-St Jeor Equation)
# =============================
BMR_MALE_ADJUSTMENT = 5
BMR_FEMALE_ADJUSTMENT = -161

# =============================
# 5. HỆ SỐ HOẠT ĐỘNG (Activity Multipliers - TDEE)
# =============================
ACTIVITY_MULTIPLIERS = {
    "sedentary": 1.2,          # Ít vận động, làm việc văn phòng
    "lightly_active": 1.375,   # Tập nhẹ 1-3 ngày/tuần
    "moderately_active": 1.55, # Tập vừa 3-5 ngày/tuần
    "very_active": 1.725,      # Tập nặng 6-7 ngày/tuần
    "extra_active": 1.9        # Vận động viên, công việc chân tay nặng
}

# =============================
# 6. TỶ LỆ MACRO KHUYẾN NGHỊ (Default Balance)
# =============================
DEFAULT_MACRO_RATIO = {
    "protein": 0.20, # 20%
    "carb": 0.50,    # 50%
    "fat": 0.30      # 30%
}

# =============================
# 7. CHỈ SỐ MÙA VỤ & ĐỊA PHƯƠNG (Mapping mẫu)
# =============================
SEASONS = {
    "SPRING": [2, 3, 4],
    "SUMMER": [5, 6, 7],
    "AUTUMN": [8, 9, 10],
    "WINTER": [11, 12, 1]
}