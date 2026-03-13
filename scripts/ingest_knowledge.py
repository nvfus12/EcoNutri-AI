import os
import pdfplumber
import chromadb

from sentence_transformers import SentenceTransformer

# =============================
# EMBEDDING MODEL
# =============================

model = SentenceTransformer("BAAI/bge-base-en-v1.5")

# =============================
# VECTOR DATABASE
# =============================

client = chromadb.PersistentClient(path="database")

collection = client.get_or_create_collection(
    name="nutrition_knowledge"
)

# =============================
# CHUNK FUNCTION
# =============================

def chunk_text(text, chunk_size=500, overlap=100):

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

    with pdfplumber.open(file_path) as pdf:

        for page_number, page in enumerate(pdf.pages):

            text = page.extract_text()

            if text is None:
                continue

            chunks = chunk_text(text)

            for i, chunk in enumerate(chunks):

                doc_id = f"{page_number}_{i}"

                documents.append(chunk)

                metadatas.append({
                    "source": os.path.basename(file_path),
                    "topic": "nutrition",
                    "page": page_number + 1
                })

                ids.append(doc_id)

    return documents, metadatas, ids


# =============================
# LOAD PDF FOLDER
# =============================

pdf_folder = "../data/knowledges"
all_docs = []
all_meta = []
all_ids = []

for file in os.listdir(pdf_folder):

    if file.endswith(".pdf"):

        path = os.path.join(pdf_folder, file)

        docs, meta, ids = process_pdf(path)

        all_docs.extend(docs)
        all_meta.extend(meta)
        all_ids.extend(ids)

# =============================
# CREATE EMBEDDING
# =============================

embeddings = model.encode(
    ["passage: " + d for d in all_docs],
    show_progress_bar=True
)

# =============================
# SAVE TO VECTOR DB
# =============================

collection.add(
    documents=all_docs,
    embeddings=embeddings,
    metadatas=all_meta,
    ids=all_ids
)

print("Data stored in database/")