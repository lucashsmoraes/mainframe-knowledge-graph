"""Carrega dados parseados das planilhas Excel no Neo4j."""

import json
from pathlib import Path
from neo4j import GraphDatabase

NEO4J_URI = "bolt://localhost:7687"
NEO4J_USER = "neo4j"
NEO4J_PASS = "mainframe2024"

PARSED_FILE = Path("02_parsed/excel_parsed/consumers_consolidated.json")


def load_excel_to_graph():
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASS))

    if not PARSED_FILE.exists():
        print(f"⚠️  Arquivo não encontrado: {PARSED_FILE}")
        print("   Execute 'python scripts/parse_excel.py' primeiro.")
        return

    data = json.loads(PARSED_FILE.read_text(encoding="utf-8"))

    with driver.session() as session:
        # 1. Criar nós Consumer
        for consumer in data["consumers"]:
            print(f"👤 Consumer: {consumer['name']}")
            session.run(
                """
                MERGE (c:Consumer {name: $name})
                SET c.area = $area,
                    c.responsavel = $responsavel,
                    c.criticidade = $criticidade
                """,
                name=consumer["name"],
                area=consumer.get("area"),
                responsavel=consumer.get("responsavel"),
                criticidade=consumer.get("criticidade"),
            )

        # 2. Criar relacionamentos CONSUMES
        for rel in data["relationships"]:
            session.run(
                """
                MATCH (c:Consumer {name: $consumer})
                MERGE (p:Program {name: $program})
                MERGE (c)-[r:CONSUMES]->(p)
                SET r.interface_type = $iface,
                    r.description = $desc
                """,
                consumer=rel["consumer"],
                program=rel["program"],
                iface=rel.get("interface_type"),
                desc=rel.get("description"),
            )

        # 3. Criar nós Job (se existirem nos dados)
        for prog in data.get("programs", []):
            if prog.get("job"):
                session.run(
                    """
                    MERGE (j:Job {name: $job})
                    WITH j
                    MATCH (p:Program {name: $prog})
                    MERGE (j)-[:EXECUTES]->(p)
                    """,
                    job=prog["job"],
                    prog=prog["name"],
                )

    driver.close()
    print("✅ Carga Excel completa!")


if __name__ == "__main__":
    load_excel_to_graph()
