import sqlite3

conn = sqlite3.connect('database/econutri.db')
c = conn.cursor()
c.execute("SELECT sql FROM sqlite_master WHERE type='table' and name in ('regional_specialties', 'nutrition_reference', 'specialty_nutrition', 'specialty_seasons', 'season');")
for r in c.fetchall():
    print(r[0])
    print('---')
conn.close()