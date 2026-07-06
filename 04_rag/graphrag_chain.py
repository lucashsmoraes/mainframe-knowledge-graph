"""Pipeline GraphRAG: combina busca no grafo + busca semântica + LLM."""

import re
from neo4j import GraphDatabase
import chromadb

try:
    from langchain_google_genai import (
        GoogleGenerativeAIEmbeddings,
        ChatGoogleGenerativeAI,
    )
except ImportError:
    print("⚠️  Instale: pip install langchain-google-genai")
    exit(1)

NEO4J_URI = "bolt://localhost:7687"
NEO4J_USER = "neo4j"
NEO4J_PASS = "mainframe2024"

# =====================================================
#  1. CAMADA DE BUSCA NO GRAFO
# =====================================================

CYPHER_TEMPLATES = {
    "impacto_tabela": {
        "description": "Impacto de alterar uma tabela",
        "query": """
            MATCH (t:Table {name: $entity})<-[r:READS|WRITES]-(p:Program)
            OPTIONAL MATCH (c:Consumer)-[:CONSUMES]->(p)
            RETURN t.name AS tabela,
                   type(r) AS operacao,
                   p.name AS programa,
                   p.lines_of_code AS linhas,
                   c.name AS consumidor,
                   c.criticidade AS criticidade
            ORDER BY c.criticidade DESC
        """,
    },
    "impacto_programa": {
        "description": "Impacto de alterar um programa",
        "query": """
            MATCH (p:Program {name: $entity})
            OPTIONAL MATCH (p)-[:READS|WRITES]->(t:Table)
            OPTIONAL MATCH (p)-[:CALLS]->(called:Program)
            OPTIONAL MATCH (caller:Program)-[:CALLS]->(p)
            OPTIONAL MATCH (c:Consumer)-[:CONSUMES]->(p)
            RETURN p.name AS programa,
                   collect(DISTINCT t.name) AS tabelas,
                   collect(DISTINCT called.name) AS chama,
                   collect(DISTINCT caller.name) AS chamado_por,
                   collect(DISTINCT c.name) AS consumidores
        """,
    },
    "consumidores_criticos": {
        "description": "Consumidores de alta criticidade",
        "query": """
            MATCH (c:Consumer)-[:CONSUMES]->(p:Program)
            WHERE c.criticidade IN ['Alta', 'Crítica']
            OPTIONAL MATCH (p)-[:READS|WRITES]->(t:Table)
            RETURN c.name AS consumidor,
                   c.criticidade AS criticidade,
                   collect(DISTINCT p.name) AS programas,
                   collect(DISTINCT t.name) AS tabelas
            ORDER BY c.criticidade DESC
        """,
    },
    "dependencias_programa": {
        "description": "Cadeia completa de dependências de um programa",
        "query": """
            MATCH path = (p:Program {name: $entity})-[:CALLS*1..5]->(dep:Program)
            RETURN [node IN nodes(path) | node.name] AS cadeia_de_calls,
                   length(path) AS profundidade
            ORDER BY profundidade
        """,
    },
}


def query_graph(question: str, entity: str = None) -> str:
    """Busca informações estruturadas no grafo."""
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASS))
    results = []

    with driver.session() as session:
        q_lower = question.lower()

        if any(w in q_lower for w in ["impacto", "alterar", "mudar", "tabela"]):
            if entity:
                result = session.run(
                    CYPHER_TEMPLATES["impacto_tabela"]["query"],
                    entity=entity.upper(),
                )
                results = [dict(r) for r in result]

        elif any(w in q_lower for w in ["programa", "rotina", "depende"]):
            if entity:
                result = session.run(
                    CYPHER_TEMPLATES["impacto_programa"]["query"],
                    entity=entity.upper(),
                )
                results = [dict(r) for r in result]

        elif any(w in q_lower for w in ["crítico", "criticidade", "risco"]):
            result = session.run(
                CYPHER_TEMPLATES["consumidores_criticos"]["query"]
            )
            results = [dict(r) for r in result]

        # Fallback: busca genérica
        if not results and entity:
            result = session.run(
                """
                MATCH (n)
                WHERE n.name = $entity
                OPTIONAL MATCH (n)-[r]-(m)
                RETURN labels(n)[0] AS tipo_origem,
                       n.name AS nome,
                       type(r) AS relacao,
                       labels(m)[0] AS tipo_destino,
                       m.name AS conectado_a
                LIMIT 20
                """,
                entity=entity.upper(),
            )
            results = [dict(r) for r in result]

    driver.close()
    return str(results) if results else "Nenhum resultado encontrado no grafo."


# =====================================================
#  2. CAMADA DE BUSCA SEMÂNTICA (DOCUMENTAÇÕES)
# =====================================================


def query_docs(question: str, top_k: int = 5) -> str:
    """Busca chunks relevantes nas documentações via embeddings."""
    embeddings = GoogleGenerativeAIEmbeddings(model="models/text-embedding-004")
    chroma_client = chromadb.PersistentClient(path="./chroma_db")

    try:
        collection = chroma_client.get_collection("mainframe_docs")
    except Exception:
        return "Vector store não encontrado. Execute load_docs.py primeiro."

    query_embedding = embeddings.embed_query(question)
    results = collection.query(
        query_embeddings=[query_embedding], n_results=top_k
    )

    if not results["documents"][0]:
        return "Nenhuma documentação relevante encontrada."

    context_parts = []
    for doc, metadata in zip(results["documents"][0], results["metadatas"][0]):
        source = metadata.get("source_file", "desconhecido")
        context_parts.append(f"[Fonte: {source}]\n{doc}")

    return "\n\n---\n\n".join(context_parts)


# =====================================================
#  3. ORQUESTRADOR: COMBINA GRAFO + DOCS + LLM
# =====================================================


def extract_entity_from_question(question: str) -> str | None:
    """Tenta extrair o nome da entidade principal da pergunta."""
    patterns = [
        r"(TB[_\s][A-Z0-9_]+)",
        r"(PGM[A-Z0-9_]+)",
        r"(JOB[A-Z0-9_]+)",
        r'"([^"]+)"',
        r"'([^']+)'",
    ]
    for pattern in patterns:
        match = re.search(pattern, question.upper())
        if match:
            return match.group(1).replace(" ", "_")
    return None


SYSTEM_PROMPT = """Você é um assistente especialista em modernização de mainframe.
Você tem acesso a um Knowledge Graph com informações sobre programas COBOL,
tabelas DB2, consumidores de rotinas, jobs e documentações.

Ao responder:
1. Use os DADOS DO GRAFO para informações estruturadas (dependências, impacto,
   relacionamentos)
2. Use o CONTEXTO DOCUMENTAL para explicações, regras de negócio e detalhes
3. Sempre cite as fontes (programa, tabela, documento)
4. Se não tiver informação suficiente, diga explicitamente o que falta
5. Responda em português
"""


def ask(question: str) -> str:
    """Função principal: recebe pergunta, retorna resposta completa."""
    print(f"\n{'=' * 60}")
    print(f"❓ Pergunta: {question}")
    print(f"{'=' * 60}")

    entity = extract_entity_from_question(question)
    print(f"🔍 Entidade detectada: {entity or 'nenhuma'}")

    print("📊 Buscando no grafo...")
    graph_context = query_graph(question, entity)
    print(f"   → {len(graph_context)} chars de contexto do grafo")

    print("📚 Buscando nas documentações...")
    doc_context = query_docs(question)
    print(f"   → {len(doc_context)} chars de contexto documental")

    llm = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        temperature=0.1,
    )

    full_prompt = f"""{SYSTEM_PROMPT}

## DADOS DO GRAFO (relacionamentos estruturados):
{graph_context}

## CONTEXTO DOCUMENTAL (documentações relevantes):
{doc_context}

## PERGUNTA DO USUÁRIO:
{question}

Responda de forma clara e estruturada, citando as fontes:"""

    print("🤖 Gerando resposta...")
    response = llm.invoke(full_prompt)

    print(f"\n{'─' * 60}")
    print(response.content)
    print(f"{'─' * 60}")

    return response.content


if __name__ == "__main__":
    perguntas = [
        "Qual o impacto de alterar a tabela TB_CLIENTE?",
        "O que faz o programa PGMCLI01?",
        "Quais são os consumidores mais críticos?",
        "Quais programas dependem do PGMLOG01?",
    ]

    for pergunta in perguntas:
        ask(pergunta)
        print("\n" + "=" * 80 + "\n")
