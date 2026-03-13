# src/services/user_service.py

class UserService:

    # ===== BMI =====
    def calculate_bmi(self, weight_kg, height_cm):
        height_m = height_cm / 100
        bmi = weight_kg / (height_m ** 2)
        return round(bmi, 2)

    # ===== BMR (Mifflin-St Jeor) =====
    def calculate_bmr(self, weight_kg, height_cm, age, gender):

        if gender.lower() == "male":
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
        else:
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161

        return round(bmr, 2)

    # ===== TDEE =====
    def calculate_tdee(self, bmr, activity_level):

        activity_map = {
            "sedentary": 1.2,
            "light": 1.375,
            "moderate": 1.55,
            "active": 1.725,
            "very_active": 1.9
        }

        multiplier = activity_map.get(activity_level, 1.2)

        return round(bmr * multiplier, 2)

    # ===== Body Fat (US Navy Method - simplified) =====
    def estimate_body_fat(self, bmi, age, gender):

        if gender.lower() == "male":
            body_fat = 1.20 * bmi + 0.23 * age - 16.2
        else:
            body_fat = 1.20 * bmi + 0.23 * age - 5.4

        return round(body_fat, 2)