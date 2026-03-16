import os
import json
import pdfplumber
import chromadb
import pandas as pd

from sentence_transformers import SentenceTransformer

# =============================
# PROJECT ROOT PATH
# =============================

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PDF_FOLDER = os.path.join(BASE_DIR, "data", "knowledges")
DB_PATH = os.path.join(BASE_DIR, "database", "vector_store")

# =============================
# EMBEDDING MODEL
# =============================

EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
ENCODE_BATCH_SIZE = 16
UPSERT_CHUNK_SIZE = 128

print("Loading embedding model:", EMBEDDING_MODEL)
model = SentenceTransformer(EMBEDDING_MODEL, device="cpu")

# =============================
# VECTOR DATABASE
# =============================

client = chromadb.PersistentClient(path=DB_PATH)

collection = client.get_or_create_collection(
    name="nutrition_knowledge"
)

# =============================
# CHUNK FUNCTION
# =============================

def chunk_text(text, chunk_size=800, overlap=150):

    chunks = []
    start = 0

    while start < len(text):

        end = start + chunk_size
        chunk = text[start:end]

        chunks.append(chunk)

        start += chunk_size - overlap

    return chunks


# =============================
# READ PDF
# =============================

def process_pdf(file_path):

    documents = []
    metadatas = []
    ids = []

    file_name = os.path.basename(file_path)

    with pdfplumber.open(file_path) as pdf:

        for page_number, page in enumerate(pdf.pages):

            text = page.extract_text()

            if text is None:
                continue

            chunks = chunk_text(text)

            for i, chunk in enumerate(chunks):

                # Unique ID
                doc_id = f"{file_name}_{page_number}_{i}"

                documents.append(chunk)

                metadatas.append({
                    "source": file_name,
                    "page": page_number + 1,
                    "chunk": i,
                    "topic": "nutrition"
                })

                ids.append(doc_id)

    return documents, metadatas, ids


def process_text_file(file_path):
    documents = []
    metadatas = []
    ids = []

    file_name = os.path.basename(file_path)
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    chunks = chunk_text(content)
    for i, chunk in enumerate(chunks):
        doc_id = f"{file_name}_text_{i}"
        documents.append(chunk)
        metadatas.append({
            "source": file_name,
            "page": None,
            "chunk": i,
            "topic": "nutrition",
            "source_type": "text"
        })
        ids.append(doc_id)

    return documents, metadatas, ids


def process_csv_or_json(file_path):
    documents = []
    metadatas = []
    ids = []

    file_name = os.path.basename(file_path)
    ext = os.path.splitext(file_name)[1].lower()

    if ext == ".csv":
        df = pd.read_csv(file_path)
    elif ext == ".json":
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, list):
            df = pd.DataFrame(data)
        elif isinstance(data, dict):
            if "data" in data and isinstance(data["data"], list):
                df = pd.DataFrame(data["data"])
            else:
                df = pd.DataFrame([data])
        else:
            df = pd.DataFrame()
    else:
        return documents, metadatas, ids

    if df.empty:
        return documents, metadatas, ids

    df = df.fillna("")

    preferred_cols = ["food_name", "calories", "protein", "fat", "carb", "fiber", "source"]
    available_cols = [col for col in preferred_cols if col in df.columns]
    if not available_cols:
        available_cols = list(df.columns[: min(10, len(df.columns))])

    for i, row in df.iterrows():
        parts = [f"{col}: {row[col]}" for col in available_cols if str(row[col]).strip()]
        if not parts:
            continue

        text = " | ".join(parts)
        doc_id = f"{file_name}_row_{i}"

        documents.append(text)
        metadatas.append({
            "source": file_name,
            "page": None,
            "chunk": int(i),
            "topic": "nutrition",
            "source_type": "table"
        })
        ids.append(doc_id)

    return documents, metadatas, ids


# =============================
# LOAD PDF FOLDER
# =============================

all_docs = []
all_meta = []
all_ids = []

print("Loading PDFs from:", PDF_FOLDER)

for file in os.listdir(PDF_FOLDER):
    path = os.path.join(PDF_FOLDER, file)
    lower_file = file.lower()

    print("Processing:", file)

    if lower_file.endswith(".pdf"):
        docs, meta, ids = process_pdf(path)
    elif lower_file.endswith((".txt", ".md")):
        docs, meta, ids = process_text_file(path)
    elif lower_file.endswith((".csv", ".json")):
        docs, meta, ids = process_csv_or_json(path)
    else:
        print("Skipped (unsupported):", file)
        continue

    all_docs.extend(docs)
    all_meta.extend(meta)
    all_ids.extend(ids)

print("Total chunks:", len(all_docs))

# =============================
# CREATE EMBEDDINGS
# =============================

print("Creating embeddings and upserting to ChromaDB...")

total = len(all_docs)
stored = 0

for start in range(0, total, UPSERT_CHUNK_SIZE):
    end = min(start + UPSERT_CHUNK_SIZE, total)

    docs_chunk = all_docs[start:end]
    meta_chunk = all_meta[start:end]
    ids_chunk = all_ids[start:end]

    embeddings_chunk = model.encode(
        ["passage: " + d for d in docs_chunk],
        normalize_embeddings=True,
        batch_size=ENCODE_BATCH_SIZE,
        show_progress_bar=False
    )

    # upsert để có thể chạy lại nhiều lần mà không bị lỗi duplicate id
    collection.upsert(
        documents=docs_chunk,
        embeddings=embeddings_chunk,
        metadatas=meta_chunk,
        ids=ids_chunk
    )

    stored += len(docs_chunk)
    print(f"Upserted {stored}/{total} chunks...")

print("✅ Data stored successfully in:", DB_PATH)
print("Total stored/upserted:", stored)
