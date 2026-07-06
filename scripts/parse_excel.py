"""Parser Excel: extrai consumidores, jobs e interfaces das planilhas."""

import pandas as pd
import json
from pathlib import Path

INPUT_DIR = Path("01_input/excel")
OUTPUT_DIR = Path("02_parsed/excel_parsed")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ============================================================
# 🔧 CONFIGURAÇÃO: Mapeie as colunas da SUA planilha aqui
# ============================================================
COLUMN_MAP = {
    "programa": "Programa",
    "consumidor": "Sistema Consumidor",
    "area": "Área",
    "responsavel": "Responsável",
    "criticidade": "Criticidade",
    "tipo_interface": "Tipo Interface",
    "frequencia": "Frequência",
    "job": "Job",
    "descricao": "Descrição",
}


def find_column(df: pd.DataFrame, standard_name: str) -> str | None:
    """Encontra a coluna no DataFrame, tentando match flexível."""
    mapped_name = COLUMN_MAP.get(standard_name)

    if mapped_name and mapped_name in df.columns:
        return mapped_name

    if mapped_name:
        for col in df.columns:
            if col.strip().lower() == mapped_name.strip().lower():
                return col

    return None


def parse_excel_file(filepath: Path) -> list[dict]:
    """Parseia uma planilha Excel e retorna lista de relacionamentos."""
    xl = pd.ExcelFile(filepath)
    all_records = []

    for sheet_name in xl.sheet_names:
        print(f"   📋 Sheet: '{sheet_name}'")
        df = pd.read_excel(filepath, sheet_name=sheet_name)

        if df.empty:
            print(f"      ⏭️  Vazia, pulando")
            continue

        prog_col = find_column(df, "programa")

        if not prog_col:
            print(
                f"      ⚠️  Coluna de programa não encontrada. "
                f"Colunas disponíveis: {list(df.columns)}"
            )
            continue

        for _, row in df.iterrows():
            programa = str(row.get(prog_col, "")).strip().upper()
            if not programa or programa == "NAN":
                continue

            record = {
                "programa": programa,
                "source_file": filepath.name,
                "source_sheet": sheet_name,
            }

            for field, _ in COLUMN_MAP.items():
                if field == "programa":
                    continue
                col = find_column(df, field)
                if col and pd.notna(row.get(col)):
                    record[field] = str(row[col]).strip()

            all_records.append(record)

    return all_records


def consolidate_consumers(records: list[dict]) -> dict:
    """Agrupa registros por consumidor, gerando estrutura limpa."""
    consumers = {}
    programs = {}
    relationships = []

    for rec in records:
        prog_name = rec["programa"]
        cons_name = rec.get("consumidor", "DESCONHECIDO")

        if prog_name not in programs:
            programs[prog_name] = {
                "name": prog_name,
                "type": rec.get("tipo_interface", "desconhecido"),
                "frequency": rec.get("frequencia"),
                "job": rec.get("job"),
            }

        if cons_name not in consumers:
            consumers[cons_name] = {
                "name": cons_name,
                "area": rec.get("area"),
                "responsavel": rec.get("responsavel"),
                "criticidade": rec.get("criticidade"),
            }

        relationships.append(
            {
                "consumer": cons_name,
                "program": prog_name,
                "interface_type": rec.get("tipo_interface"),
                "description": rec.get("descricao"),
            }
        )

    return {
        "consumers": list(consumers.values()),
        "programs": list(programs.values()),
        "relationships": relationships,
    }


def main():
    excel_files = list(INPUT_DIR.glob("*.xlsx")) + list(INPUT_DIR.glob("*.xls"))

    if not excel_files:
        print(f"⚠️  Nenhum arquivo Excel encontrado em {INPUT_DIR}")
        return

    all_records = []
    for filepath in sorted(excel_files):
        print(f"📊 Parseando: {filepath.name}")
        records = parse_excel_file(filepath)
        all_records.extend(records)
        print(f"   ✅ {len(records)} registros extraídos")

    consolidated = consolidate_consumers(all_records)

    output_file = OUTPUT_DIR / "consumers_consolidated.json"
    output_file.write_text(
        json.dumps(consolidated, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    print(f"\n📊 Resumo:")
    print(f"   {len(consolidated['consumers'])} consumidores únicos")
    print(f"   {len(consolidated['programs'])} programas referenciados")
    print(f"   {len(consolidated['relationships'])} relacionamentos")


if __name__ == "__main__":
    main()
