"""
Vector Repository for EcoNutri

Handles:
- Vector DB connection
- Embedding queries
- Semantic search
"""

import chromadb
from sentence_transformers import SentenceTransformer


class VectorRepository:

    def __init__(
        self,
        db_path="database",
        collection_name="nutrition_knowledge",
        embedding_model="BAAI/bge-base-en-v1.5"
    ):
        """
        Initialize vector database and embedding model
        """

        # Load embedding model
        print("Loading embedding model...")
        self.model = SentenceTransformer(embedding_model)

        # Connect to ChromaDB
        print("Connecting to vector database...")
        self.client = chromadb.PersistentClient(path=db_path)

        # Load collection
        self.collection = self.client.get_or_create_collection(
            name=collection_name
        )

        print("Vector repository ready.")


    # ===================================
    # EMBED QUERY
    # ===================================

    def embed_query(self, query: str):
        """
        Convert query into embedding vector
        """

        embedding = self.model.encode(
            ["query: " + query]
        )

        return embedding[0].tolist()


    # ===================================
    # SEMANTIC SEARCH
    # ===================================

    def search(self, query, top_k=3):
        """
        Perform semantic search in vector database
        """

        query_embedding = self.embed_query(query)

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