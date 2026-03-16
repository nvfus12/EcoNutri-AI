# Data Sources de xuat cho RAG dinh duong

## 1) Bang thanh phan thuc pham Viet Nam (NIN)
- Muc tieu: bo sung du lieu vi mo cho mon Viet.
- Dinh dang nen dung: CSV hoac JSON theo cot:
  - food_name, calories, protein, fat, carb, fiber, source

## 2) USDA FoodData Central
- Muc tieu: du lieu thuc pham tho chuan hoa.
- Co the tai ve va chuyen ve CSV/JSON roi dat vao thu muc nay.

## 3) Huong dan dinh duong lam sang (Bo Y te)
- Muc tieu: canh bao benh ly theo boi canh Viet Nam.
- Dinh dang: PDF.

## Cach nap vao vector store
1. Dat file vao data/knowledges.
2. Chay: python scripts/ingest_knowledge.py
3. Kiem tra so luong chunks trong UI EcoNutri.

## Luu y
- Uu tien nguon co trich dan ro rang.
- Khong dua thong tin thuoc ke don vao phan tu van tu dong.
