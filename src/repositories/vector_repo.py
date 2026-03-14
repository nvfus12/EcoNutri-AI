"""
Vector Repository for EcoNutri

Handles:
- Vector DB connection
- Embedding queries
- Semantic search
"""

import hashlib
import chromadb
from sentence_transformers import SentenceTransformer


class VectorRepository:

    def __init__(
        self,
        db_path="database/vector_store",
        collection_name="nutrition_knowledge",
        embedding_model="sentence-transformers/all-MiniLM-L6-v2"
    ):
        """
        Initialize vector database and embedding model
        """

        self.embedding_model_name = embedding_model
        self.model = None
        self.degraded_mode = False

        # Load embedding model (force CPU) with a stable fallback model.
        print("Loading embedding model...")
        try:
            self.model = SentenceTransformer(embedding_model, device="cpu")
        except Exception as first_exc:
            fallback_model = "sentence-transformers/all-MiniLM-L6-v2"
            print(f"Primary embedding model failed: {first_exc}")
            print(f"Falling back to: {fallback_model}")
            try:
                self.model = SentenceTransformer(fallback_model, device="cpu")
                self.embedding_model_name = fallback_model
            except Exception as second_exc:
                # Ultimate fallback to keep app available even when transformer stack breaks.
                print(f"Fallback embedding model failed: {second_exc}")
                print("Switching vector repository to degraded mode (no semantic ranking).")
                self.degraded_mode = True

        # Connect to ChromaDB
        print("Connecting to vector database...")
        self.client = chromadb.PersistentClient(path=db_path)

        # Load collection
        self.collection = self.client.get_or_create_collection(
            name=collection_name
        )

        mode = "degraded" if self.degraded_mode else self.embedding_model_name
        print(f"Vector repository ready. mode={mode}")


    # ===================================
    # EMBED QUERY
    # ===================================

    def embed_query(self, query: str):
        """
        Convert query into embedding vector
        """
        if self.model is not None:
            embedding = self.model.encode(
                ["query: " + query]
            )
            return embedding[0].tolist()

        # Degraded deterministic embedding to keep API shape stable.
        digest = hashlib.sha256(query.encode("utf-8")).digest()
        vector = []
        for i in range(64):
            byte = digest[i % len(digest)]
            vector.append((byte / 255.0) * 2 - 1)
        return vector


    # ===================================
    # SEMANTIC SEARCH
    # ===================================

    def search(self, query, top_k=3):
        """
        Perform semantic search in vector database
        """
        if self.collection.count() == 0:
            return {
                "documents": [],
                "metadatas": [],
                "ids": []
            }

        if self.degraded_mode:
            # In degraded mode, return latest documents without semantic ranking.
            rows = self.collection.get(limit=top_k, include=["documents", "metadatas"])
            return {
                "documents": rows.get("documents", []),
                "metadatas": rows.get("metadatas", []),
                "ids": rows.get("ids", [])
            }

        query_embedding = self.embed_query(query)

        try:
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k
            )

            documents = results["documents"][0]
            metadatas = results.get("metadatas", [[]])[0]
            ids = results["ids"][0]

            return {
                "documents": documents,
                "metadatas": metadatas,
                "ids": ids
            }
        except Exception:
            # Graceful fallback when embedding dimension mismatches existing collection.
            rows = self.collection.get(limit=top_k, include=["documents", "metadatas"])
            return {
                "documents": rows.get("documents", []),
                "metadatas": rows.get("metadatas", []),
                "ids": rows.get("ids", [])
            }


    # ===================================
    # GET CONTEXT FOR RAG
    # ===================================

    def get_context(self, query, top_k=3):
        """
        Retrieve documents and build context string
        """

        results = self.search(query, top_k)

        documents = results["documents"]

        context = "\n\n".join(documents)

        return context, results["metadatas"]


    # ===================================
    # COUNT DOCUMENTS
    # ===================================

    def count_documents(self):
        """
        Count number of documents in vector DB
        """

        return self.collection.count()