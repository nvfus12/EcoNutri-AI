import os
import pdfplumber
import chromadb

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


# =============================
# LOAD PDF FOLDER
# =============================

all_docs = []
all_meta = []
all_ids = []

print("Loading PDFs from:", PDF_FOLDER)

for file in os.listdir(PDF_FOLDER):

    if file.endswith(".pdf"):

        path = os.path.join(PDF_FOLDER, file)

        print("Processing:", file)

        docs, meta, ids = process_pdf(path)

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
