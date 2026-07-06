"""Parser COBOL: extrai tabelas, CALLs, copybooks e SQL de código COBOL."""

import re
import json
from pathlib import Path

INPUT_DIR = Path("01_input/cobol")
OUTPUT_DIR = Path("02_parsed/cobol_parsed")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def extract_program_name(source: str, filename: str) -> str:
    """Extrai o PROGRAM-ID do fonte COBOL."""
    match = re.search(r"PROGRAM-ID\.\s+([A-Za-z0-9\-]+)", source, re.IGNORECASE)
    if match:
        return match.group(1).upper().replace("-", "")
    return Path(filename).stem.upper()


def extract_sql_blocks(source: str) -> list[dict]:
    """Extrai todos os blocos EXEC SQL ... END-EXEC."""
    sql_blocks = []
    pattern = r"EXEC\s+SQL\s*(.*?)\s*END-EXEC"
    matches = re.findall(pattern, source, re.DOTALL | re.IGNORECASE)

    for raw_sql in matches:
        # Limpa o SQL
        clean_sql = re.sub(r"\n\s{6}\-", " ", raw_sql)
        clean_sql = re.sub(r"\s+", " ", clean_sql).strip()

        # Tipo de operação
        sql_upper = clean_sql.upper()
        if sql_upper.startswith("SELECT"):
            op_type = "SELECT"
        elif sql_upper.startswith("INSERT"):
            op_type = "INSERT"
        elif sql_upper.startswith("UPDATE"):
            op_type = "UPDATE"
        elif sql_upper.startswith("DELETE"):
            op_type = "DELETE"
        elif "DECLARE" in sql_upper and "CURSOR" in sql_upper:
            op_type = "CURSOR"
        else:
            op_type = "OTHER"

        # Tabelas
        tables = re.findall(
            r"(?:FROM|INTO|UPDATE|JOIN|TABLE)\s+([A-Z][A-Z0-9_\.]+)",
            clean_sql,
            re.IGNORECASE,
        )
        tables = [t.split(".")[-1].upper() for t in tables]
        tables = list(dict.fromkeys(tables))

        # Colunas
        columns = []
        if op_type == "SELECT":
            col_match = re.search(
                r"SELECT\s+(.*?)\s+FROM", clean_sql, re.IGNORECASE | re.DOTALL
            )
            if col_match:
                col_str = col_match.group(1)
                if "*" not in col_str:
                    columns = [
                        c.strip().split(".")[-1].upper()
                        for c in col_str.split(",")
                        if c.strip() and not c.strip().startswith(":")
                    ]
        elif op_type == "INSERT":
            col_match = re.search(
                r"INTO\s+\S+\s*\((.*?)\)", clean_sql, re.IGNORECASE
            )
            if col_match:
                columns = [c.strip().upper() for c in col_match.group(1).split(",")]

        sql_blocks.append(
            {
                "type": op_type,
                "tables": tables,
                "columns": columns,
                "raw_sql": clean_sql,
            }
        )

    return sql_blocks


def extract_calls(source: str) -> list[str]:
    """Extrai todos os CALLs para outros programas."""
    calls = re.findall(
        r"CALL\s+['\"]([A-Za-z0-9\-]+)['\"]", source, re.IGNORECASE
    )
    return list(set(c.upper().replace("-", "") for c in calls))


def extract_copybooks(source: str) -> list[str]:
    """Extrai todos os COPY (copybooks incluídos)."""
    copies = re.findall(r"COPY\s+([A-Za-z0-9\-]+)", source, re.IGNORECASE)
    return list(set(c.upper().replace("-", "") for c in copies))


def parse_cobol_file(filepath: Path) -> dict:
    """Parseia um arquivo COBOL completo."""
    source = filepath.read_text(encoding="latin-1")

    program_name = extract_program_name(source, filepath.name)
    sql_blocks = extract_sql_blocks(source)
    calls = extract_calls(source)
    copybooks = extract_copybooks(source)

    tables_read = set()
    tables_written = set()
    for sql in sql_blocks:
        if sql["type"] in ("SELECT", "CURSOR"):
            tables_read.update(sql["tables"])
        elif sql["type"] in ("INSERT", "UPDATE", "DELETE"):
            tables_written.update(sql["tables"])

    line_count = len(source.splitlines())

    return {
        "program_name": program_name,
        "source_file": filepath.name,
        "lines_of_code": line_count,
        "tables_read": sorted(tables_read),
        "tables_written": sorted(tables_written),
        "calls": sorted(calls),
        "copybooks": sorted(copybooks),
        "sql_statements": sql_blocks,
    }


def main():
    """Processa todos os arquivos COBOL do diretório de input."""
    cobol_files = list(INPUT_DIR.glob("*.cbl")) + list(INPUT_DIR.glob("*.cob"))

    if not cobol_files:
        print(f"⚠️  Nenhum arquivo COBOL encontrado em {INPUT_DIR}")
        print("   Coloque seus .cbl ou .cob nessa pasta e rode novamente.")
        return

    results = []
    for filepath in sorted(cobol_files):
        print(f"📄 Parseando: {filepath.name}")
        parsed = parse_cobol_file(filepath)
        results.append(parsed)

        output_file = OUTPUT_DIR / f"{parsed['program_name']}.json"
        output_file.write_text(
            json.dumps(parsed, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(
            f"   ✅ {parsed['program_name']}: "
            f"{len(parsed['tables_read'])} tabelas lidas, "
            f"{len(parsed['tables_written'])} escritas, "
            f"{len(parsed['calls'])} calls, "
            f"{len(parsed['copybooks'])} copybooks"
        )

    # Resumo consolidado
    summary_file = OUTPUT_DIR / "_SUMMARY.json"
    summary = {
        "total_programs": len(results),
        "total_tables": len(
            set(t for r in results for t in r["tables_read"] + r["tables_written"])
        ),
        "total_calls": len(set(c for r in results for c in r["calls"])),
        "total_copybooks": len(set(c for r in results for c in r["copybooks"])),
        "programs": [r["program_name"] for r in results],
    }
    summary_file.write_text(
        json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(
        f"\n📊 Resumo: {summary['total_programs']} programas, "
        f"{summary['total_tables']} tabelas, "
        f"{summary['total_calls']} calls"
    )


if __name__ == "__main__":
    main()
