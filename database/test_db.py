from db import create_user, create_food, add_diary, get_user_diary, get_food_by_name

# 1. Thêm user
create_user((
    "Nguyen Van A", 21, "male",
    170, 65, 18,
    "moderate", "Ha Noi", "winter",
    1600, 2400
))

# 2. Thêm món ăn
create_food((
    "Bún chả",
    180, 15, 7, 25,
    5, 2,
    '{"B1":0.1}',
    '{"Fe":1.5}',
    1.8,
    "Vietnam Nutrition Institute"
))

# 3. Ghi nhật ký
food = get_food_by_name("Bún chả")

add_diary((
    1, food[0], "lunch", 250,
    450, 3.2,
    12, 15, 30, 55,
    "buncha.jpg"
))

# 4. Xem kết quả
print(get_user_diary(1))

# 5. Cập nhật và xóa (ví dụ) – sử dụng các hàm CRUD mới
from db import get_user, update_user, delete_user, get_food, update_food, delete_food, update_diary, delete_diary

# Fetch and update user
print("Before user update:", get_user(1))
update_user(1, (
    "Nguyen Van A (updated)", 22, "male",
    171, 66, 17,
    "active", "Ha Noi", "summer",
    1650, 2500
))
print("After user update:", get_user(1))

# Delete the food we inserted earlier
food_id = food[0]
print("Deleting food with id", food_id)
delete_food(food_id)
print("Food exists?", get_food(food_id))

# Update diary entry (if it exists)
print("Updating diary entry 1")
update_diary(1, (
    1, food_id, "dinner", 300,
    500, 3.5,
    15, 18, 35, 60,
    "buncha_updated.jpg"
))

# Finally, wipe out test user
print("Deleting user 1")
delete_user(1)
