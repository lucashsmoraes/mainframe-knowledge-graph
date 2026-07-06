"""Carrega dados parseados do COBOL no Neo4j."""

import json
from pathlib import Path
from neo4j import GraphDatabase

NEO4J_URI = "bolt://localhost:7687"
NEO4J_USER = "neo4j"
NEO4J_PASS = "mainframe2024"

PARSED_DIR = Path("02_parsed/cobol_parsed")


def load_cobol_to_graph():
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASS))

    json_files = [f for f in PARSED_DIR.glob("*.json") if f.name != "_SUMMARY.json"]

    if not json_files:
        print(f"⚠️  Nenhum JSON encontrado em {PARSED_DIR}")
        print("   Execute 'python scripts/parse_cobol.py' primeiro.")
        return

    with driver.session() as session:
        for jf in sorted(json_files):
            data = json.loads(jf.read_text(encoding="utf-8"))
            prog = data["program_name"]
            print(f"🔄 Carregando: {prog}")

            # 1. Criar nó Program
            session.run(
                """
                MERGE (p:Program {name: $name})
                SET p.source_file = $source_file,
                    p.lines_of_code = $loc
                """,
                name=prog,
                source_file=data["source_file"],
                loc=data["lines_of_code"],
            )

            # 2. Criar nós Table + relacionamentos READS
            for table in data["tables_read"]:
                session.run(
                    """
                    MERGE (t:Table {name: $table})
                    WITH t
                    MATCH (p:Program {name: $prog})
                    MERGE (p)-[:READS]->(t)
                    """,
                    table=table,
                    prog=prog,
                )

            # 3. Criar nós Table + relacionamentos WRITES
            for table in data["tables_written"]:
                session.run(
                    """
                    MERGE (t:Table {name: $table})
                    WITH t
                    MATCH (p:Program {name: $prog})
                    MERGE (p)-[:WRITES]->(t)
                    """,
                    table=table,
                    prog=prog,
                )

            # 4. Criar relacionamentos CALLS
            for called in data["calls"]:
                session.run(
                    """
                    MERGE (target:Program {name: $called})
                    WITH target
                    MATCH (source:Program {name: $prog})
                    MERGE (source)-[:CALLS]->(target)
                    """,
                    called=called,
                    prog=prog,
                )

            # 5. Criar nós Copybook + relacionamentos INCLUDES
            for cpyname in data["copybooks"]:
                session.run(
                    """
                    MERGE (c:Copybook {name: $cpyname})
                    WITH c
                    MATCH (p:Program {name: $prog})
                    MERGE (p)-[:INCLUDES]->(c)
                    """,
                    cpyname=cpyname,
                    prog=prog,
                )

            # 6. Criar nós Column + relacionamentos
            for sql_stmt in data["sql_statements"]:
                for col_name in sql_stmt.get("columns", []):
                    for table in sql_stmt.get("tables", []):
                        session.run(
                            """
                            MERGE (col:Column {name: $col_name, table: $table})
                            WITH col
                            MATCH (t:Table {name: $table})
                            MERGE (col)-[:BELONGS_TO]->(t)
                            WITH col
                            MATCH (p:Program {name: $prog})
                            MERGE (p)-[:USES_COLUMN]->(col)
                            """,
                            col_name=col_name,
                            table=table,
                            prog=prog,
                        )

    driver.close()
    print("✅ Carga COBOL completa!")


if __name__ == "__main__":
    load_cobol_to_graph()
