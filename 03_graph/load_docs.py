"""Carrega documentações no Vector Store (ChromaDB) e no Neo4j."""

import json
from pathlib import Path
from neo4j import GraphDatabase

try:
    from langchain_google_genai import GoogleGenerativeAIEmbeddings
except ImportError:
    print("⚠️  Instale: pip install langchain-google-genai")
    exit(1)

import chromadb

NEO4J_URI = "bolt://localhost:7687"
NEO4J_USER = "neo4j"
NEO4J_PASS = "mainframe2024"

CHUNKS_FILE = Path("02_parsed/docs_parsed/all_chunks.json")


def load_docs():
    if not CHUNKS_FILE.exists():
        print(f"⚠️  Arquivo não encontrado: {CHUNKS_FILE}")
        print("   Execute 'python scripts/parse_docs.py' primeiro.")
        return

    # 1. Inicializar embedding model
    embeddings = GoogleGenerativeAIEmbeddings(model="models/text-embedding-004")

    # 2. Inicializar ChromaDB (vector store local)
    chroma_client = chromadb.PersistentClient(path="./chroma_db")
    collection = chroma_client.get_or_create_collection(
        name="mainframe_docs", metadata={"hnsw:space": "cosine"}
    )

    # 3. Carregar chunks
    chunks = json.loads(CHUNKS_FILE.read_text(encoding="utf-8"))
    print(f"📚 Carregando {len(chunks)} chunks...")

    # 4. Gerar embeddings em batches
    BATCH_SIZE = 50
    for i in range(0, len(chunks), BATCH_SIZE):
        batch = chunks[i : i + BATCH_SIZE]
        texts = [c["text"] for c in batch]
        ids = [c["doc_id"] for c in batch]
        metadatas = [
            {
                "source_file": c["source_file"],
                "chunk_index": c["chunk_index"],
                "entities": ",".join(c["entity_mentions"]),
            }
            for c in batch
        ]

        # Gerar embeddings
        vectors = embeddings.embed_documents(texts)

        # Inserir no ChromaDB
        collection.add(
            ids=ids,
            embeddings=vectors,
            documents=texts,
            metadatas=metadatas,
        )
        print(
            f"   ✅ Batch {i // BATCH_SIZE + 1}: " f"{len(batch)} chunks inseridos"
        )

    # 5. Criar nós Document e links no Neo4j
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASS))
    with driver.session() as session:
        # Agrupar chunks por documento
        docs = {}
        for chunk in chunks:
            src = chunk["source_file"]
            if src not in docs:
                docs[src] = []
            docs[src].append(chunk)

        for doc_name, doc_chunks in docs.items():
            print(f"📄 Neo4j: {doc_name}")

            # Criar nó Document
            session.run(
                """
                MERGE (d:Document {doc_id: $doc_id})
                SET d.title = $title,
                    d.chunk_count = $chunks
                """,
                doc_id=doc_name,
                title=doc_name,
                chunks=len(doc_chunks),
            )

            # Criar links Document → Program/Table
            all_entities = set()
            for chunk in doc_chunks:
                all_entities.update(chunk["entity_mentions"])

            for entity in all_entities:
                session.run(
                    """
                    MATCH (d:Document {doc_id: $doc_id})
                    MATCH (p:Program {name: $entity})
                    MERGE (p)-[:DOCUMENTED_BY]->(d)
                    """,
                    doc_id=doc_name,
                    entity=entity,
                )
                session.run(
                    """
                    MATCH (d:Document {doc_id: $doc_id})
                    MATCH (t:Table {name: $entity})
                    MERGE (t)-[:DOCUMENTED_BY]->(d)
                    """,
                    doc_id=doc_name,
                    entity=entity,
                )

    driver.close()
    print("✅ Documentações carregadas no Vector Store e Neo4j!")


if __name__ == "__main__":
    load_docs()
