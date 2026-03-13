from repository.vector_repo import VectorRepository
from repository.sql_repo import SQLRepository

import yaml
import os


class RAGEngine:

    def __init__(self):

        # =============================
        # LOAD REPOSITORIES
        # =============================

        self.vector_repo = VectorRepository()
        self.sql_repo = SQLRepository()

        # =============================
        # LOAD PROMPTS
        # =============================

        prompt_path = os.path.join(
            "prompts",
            "prompts.yaml"
        )

        with open(prompt_path, "r", encoding="utf-8") as f:
            self.prompts = yaml.safe_load(f)

    # ==================================
    # RETRIEVE CONTEXT FROM VECTOR DB
    # ==================================

    def retrieve_knowledge(self, query, top_k=5):

        documents, metadata = self.vector_repo.search(
            query=query,
            top_k=top_k
        )

        context = "\n\n".join(documents)

        return context

    # ==================================
    # BUILD PROMPT FOR LLM
    # ==================================

    def build_prompt(self, query, context):

        template = self.prompts["rag_prompt"]

        prompt = template.format(
            context=context,
            question=query
        )

        return prompt

    # ==================================
    # MAIN RAG PIPELINE
    # ==================================

    def run(self, query):

        # 1️⃣ Retrieve knowledge
        context = self.retrieve_knowledge(query)

        # 2️⃣ Build prompt
        prompt = self.build_prompt(query, context)

        return prompt