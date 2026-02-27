import sqlite3

conn = sqlite3.connect("nutrition_ai.db")

with open("create_tables.sql", "r", encoding="utf-8") as f:
    conn.executescript(f.read())

conn.close()
print("✅ Database created successfully!")