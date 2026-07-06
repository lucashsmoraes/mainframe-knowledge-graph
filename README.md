# 🏢 Mainframe Knowledge Graph

Unifica código COBOL, tabelas DB2, consumidores de rotinas, documentações e planilhas em um **Grafo de Conhecimento** consultável por IA (**GraphRAG**).

## 🎯 O que faz?

- **Parseia código COBOL** → extrai tabelas, CALLs entre programas, copybooks, colunas SQL
- **Parseia planilhas Excel** → mapeia consumidores e jobs às rotinas
- **Processa documentações** → chunking + embeddings + entity linking
- **Carrega tudo no Neo4j** → grafo navegável de dependências
- **GraphRAG com LLM** → IA que consulta grafo + docs para responder perguntas

## 📁 Estrutura do Projeto

```
mainframe-knowledge-graph/
│
├── 01_input/                  # Fontes de dados
│   ├── cobol/                 # Código-fonte COBOL (.cbl, .cob, .cpy)
│   ├── excel/                 # Planilhas Excel (.xlsx)
│   ├── docs/                  # Documentações (.docx, .pdf, .txt, .md)
│   └── jcl/                   # JCLs (opcional)
│
├── 02_parsed/                 # Saída dos parsers (JSONs intermediários)
│   ├── cobol_parsed/          # Um JSON por programa COBOL
│   ├── excel_parsed/          # Um JSON por planilha
│   └── docs_parsed/           # Chunks das documentações
│
├── 03_graph/                  # Scripts de carga no Neo4j
│   ├── load_cobol.py
│   ├── load_excel.py
│   ├── load_docs.py
│   └── schema.cypher
│
├── 04_rag/                    # Pipeline de IA (GraphRAG)
│   ├── graphrag_chain.py
│   └── streamlit_app.py
│
├── scripts/                   # Utilitários de parsing
│   ├── parse_cobol.py
│   ├── parse_excel.py
│   └── parse_docs.py
│
├── docker-compose.yml
├── requirements.txt
└── .gitignore
```

## 🚀 Quick Start

### 1. Clone e instale

```bash
git clone https://github.com/lucashsmoraes/mainframe-knowledge-graph.git
cd mainframe-knowledge-graph
pip install -r requirements.txt
```

### 2. Suba o Neo4j

```bash
docker-compose up -d
```

Acesse `http://localhost:7474` — login: `neo4j` / senha: `mainframe2024`

### 3. Coloque seus dados

- Código COBOL em `01_input/cobol/`
- Planilhas Excel em `01_input/excel/`
- Documentações em `01_input/docs/`

### 4. Execute o pipeline

```bash
# Fase 1: Parse COBOL
python scripts/parse_cobol.py

# Fase 2: Parse Excel
python scripts/parse_excel.py

# Fase 3: Carregar no Neo4j
python 03_graph/load_cobol.py
python 03_graph/load_excel.py

# Fase 4: Processar documentações
python scripts/parse_docs.py
python 03_graph/load_docs.py

# Fase 5: Iniciar chat
cd 04_rag
streamlit run streamlit_app.py
```

## 📊 Modelo do Grafo

### Nós
| Tipo | Descrição |
|---|---|
| `Program` | Programa COBOL |
| `Table` | Tabela DB2 |
| `Column` | Coluna de tabela |
| `Copybook` | Copybook incluído |
| `Consumer` | Sistema consumidor |
| `Job` | Job de execução |
| `Document` | Documentação |

### Relacionamentos
| Relação | De → Para |
|---|---|
| `READS` | Program → Table |
| `WRITES` | Program → Table |
| `CALLS` | Program → Program |
| `INCLUDES` | Program → Copybook |
| `USES_COLUMN` | Program → Column |
| `CONSUMES` | Consumer → Program |
| `EXECUTES` | Job → Program |
| `DOCUMENTED_BY` | Program/Table → Document |
| `BELONGS_TO` | Column → Table |

## 🤖 Exemplos de Perguntas (GraphRAG)

- "Qual o impacto de alterar a tabela TB_CLIENTE?"
- "Quais sistemas consomem o programa PGMCLI01?"
- "Quais são os consumidores de alta criticidade?"
- "Me explique a regra de cálculo de juros"
- "Qual a cadeia de dependências do PGMLOG01?"

## 🛠️ Tecnologias

- **Neo4j** — Banco de grafos
- **ChromaDB** — Vector store para embeddings
- **LangChain** — Orquestração do pipeline RAG
- **Google Gemini** — LLM e embeddings
- **Streamlit** — Interface de chat
- **Python** — Scripts de parsing e carga

## 📄 Licença

MIT
