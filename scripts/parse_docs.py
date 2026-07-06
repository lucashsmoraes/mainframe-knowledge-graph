"""Parser de documentações: chunking + entity linking."""

import json
import re
from pathlib import Path

INPUT_DIR = Path("01_input/docs")
OUTPUT_DIR = Path("02_parsed/docs_parsed")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Carregar nomes de entidades conhecidas (do parsing anterior)
KNOWN_ENTITIES = set()
cobol_summary = Path("02_parsed/cobol_parsed/_SUMMARY.json")
if cobol_summary.exists():
    summary = json.loads(cobol_summary.read_text())
    KNOWN_ENTITIES.update(summary.get("programs", []))

for jf in Path("02_parsed/cobol_parsed").glob("*.json"):
    if jf.name.startswith("_"):
        continue
    data = json.loads(jf.read_text())
    KNOWN_ENTITIES.update(data.get("tables_read", []))
    KNOWN_ENTITIES.update(data.get("tables_written", []))

CHUNK_SIZE = 800
CHUNK_OVERLAP = 200


def extract_text_from_file(filepath: Path) -> str:
    """Extrai texto de diferentes formatos."""
    suffix = filepath.suffix.lower()

    if suffix in (".txt", ".md"):
        return filepath.read_text(encoding="utf-8", errors="replace")

    elif suffix == ".docx":
        try:
            from docx import Document

            doc = Document(str(filepath))
            return "\n".join(p.text for p in doc.paragraphs)
        except ImportError:
            print("   ⚠️  Instale: pip install python-docx")
            return ""

    elif suffix == ".pdf":
        try:
            from PyPDF2 import PdfReader

            reader = PdfReader(str(filepath))
            return "\n".join(page.extract_text() or "" for page in reader.pages)
        except ImportError:
            print("   ⚠️  Instale: pip install PyPDF2")
            return ""

    else:
        print(f"   ⚠️  Formato não suportado: {suffix}")
        return ""


def chunk_text(text: str) -> list[str]:
    """Divide texto em chunks com overlap."""
    chunks = []
    start = 0
    while start < len(text):
        end = start + CHUNK_SIZE
        chunk = text[start:end]
        if end < len(text):
            last_period = chunk.rfind(".")
            if last_period > CHUNK_SIZE * 0.5:
                chunk = chunk[:last_period + 1]
                end = start + last_period + 1
        chunks.append(chunk.strip())
        start = end - CHUNK_OVERLAP
    return [c for c in chunks if len(c) > 50]


def find_entity_mentions(text: str) -> list[str]:
    """Encontra menções a entidades conhecidas no texto."""
    text_upper = text.upper()
    found = []
    for entity in KNOWN_ENTITIES:
        if entity in text_upper:
            found.append(entity)
    return found


def main():
    doc_files = list(INPUT_DIR.rglob("*"))
    doc_files = [
        f
        for f in doc_files
        if f.is_file() and f.suffix.lower() in (".txt", ".md", ".docx", ".pdf")
    ]

    if not doc_files:
        print(f"⚠️  Nenhuma documentação encontrada em {INPUT_DIR}")
        return

    all_chunks = []
    for filepath in sorted(doc_files):
        print(f"📝 Processando: {filepath.name}")

        text = extract_text_from_file(filepath)
        if not text:
            continue

        chunks = chunk_text(text)
        print(f"   ✅ {len(chunks)} chunks gerados")

        for i, chunk_text_content in enumerate(chunks):
            entities = find_entity_mentions(chunk_text_content)
            all_chunks.append(
                {
                    "doc_id": f"{filepath.stem}_{i:04d}",
                    "source_file": filepath.name,
                    "chunk_index": i,
                    "text": chunk_text_content,
                    "entity_mentions": entities,
                    "char_count": len(chunk_text_content),
                }
            )
            if entities:
                print(f"      Chunk {i}: menções a {entities}")

    output_file = OUTPUT_DIR / "all_chunks.json"
    output_file.write_text(
        json.dumps(all_chunks, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    chunks_with_entities = [c for c in all_chunks if c["entity_mentions"]]
    print(f"\n📊 Resumo:")
    print(f"   {len(doc_files)} documentos processados")
    print(f"   {len(all_chunks)} chunks gerados")
    print(
        f"   {len(chunks_with_entities)} chunks com entidades linkáveis "
        f"({100 * len(chunks_with_entities) / max(len(all_chunks), 1):.0f}%)"
    )


if __name__ == "__main__":
    main()
