

from src.repositories.sql_repo import SQLRepository


class DiaryService:

    def __init__(self):
        self.repo = SQLRepository()

    # CREATE
    def add_food_entry(self, data):
        """
        data = (user_id, food_name, meal_type, portion_g, calories,
                carbon_footprint, sugar_g, fat_g, protein_g, carb_g, image_path)
        """
        return self.repo.add_diary(data)

    # READ
    def get_user_diary(self, user_id):
        return self.repo.get_user_diary(user_id)

    # UPDATE
    def update_food_entry(self, diary_id, data):
        return self.repo.update_diary(diary_id, data)

    # DELETE
    def delete_food_entry(self, diary_id):
        return self.repo.delete_diary(diary_id)