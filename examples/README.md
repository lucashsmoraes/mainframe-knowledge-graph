# Exemplos para Teste do Pipeline

Esta pasta contém dados de exemplo para testar o pipeline do Knowledge Graph.

## Conteúdo

### 📄 `cobol/` — 10 Programas COBOL

| Programa | Descrição | Tem Comentários? | Operações SQL | Chama |
|---|---|---|---|---|
| PGMCLI01 | Consulta de cliente | ✅ Sim | SELECT TB_CLIENTE, INSERT TB_LOG | - |
| PGMCLI02 | Inclusão de cliente | ✅ Sim | INSERT TB_CLIENTE, INSERT TB_LOG | PGMVAL01 |
| PGMCLI03 | Alteração de cliente | ✅ Sim | SELECT/UPDATE TB_CLIENTE, INSERT TB_LOG | PGMVAL01 |
| PGMCLI04 | Exclusão lógica | ✅ Sim | SELECT/UPDATE TB_CLIENTE, UPDATE TB_TELEFONE, INSERT TB_LOG | - |
| PGMVAL01 | Validação de CPF | ✅ Sim | SELECT TB_CLIENTE | - |
| PGMEND01 | Manutenção de endereço | ✅ Sim | SELECT/INSERT/UPDATE TB_ENDERECO, SELECT TB_CEP, SELECT TB_CLIENTE, INSERT TB_LOG | - |
| PGMTEL01 | Manutenção de telefone | ✅ Sim | SELECT/INSERT/UPDATE/DELETE TB_TELEFONE, SELECT TB_CLIENTE, SELECT TB_DDD, INSERT TB_LOG | - |
| PGMREL01 | Relatório de clientes | ✅ Sim | SELECT TB_CLIENTE/TB_ENDERECO/TB_TELEFONE, INSERT TB_LOG | PGMVAL01 |
| PGMDEP01 | Manutenção de dependentes | ✅ Sim | SELECT/INSERT/DELETE TB_DEPENDENTE, SELECT TB_CLIENTE, INSERT TB_LOG | PGMVAL01 |
| **PGMCLI05** | *(sem descrição)* | ❌ Não | SELECT/UPDATE TB_CLIENTE, UPDATE TB_ENDERECO/TB_TELEFONE, INSERT TB_LOG | - |
| **PGMCLI06** | *(sem descrição)* | ❌ Não | SELECT/UPDATE/INSERT TB_CLIENTE, UPDATE/INSERT TB_ENDERECO, UPDATE TB_TELEFONE/TB_DEPENDENTE, INSERT TB_LOG | - |

### 📊 `excel/` — Planilha de Consumidores

Arquivo CSV com 21 relacionamentos consumidor→programa, incluindo:
- 6 sistemas consumidores (Internet Banking, App Mobile, Call Center, etc.)
- Criticidades: Crítica, Alta, Média
- Tipos: Online/CICS, Batch, Arquivo
- 5 Jobs batch referenciados

> **Nota**: Para usar com o parser, converta para `.xlsx` ou ajuste o parser para ler CSV.

### 📝 `docs/` — Documentações

- `manual_PGMCLI01.md`: Documentação detalhada do programa de consulta
- `modulo_cadastro.md`: Visão geral do domínio cadastral com descrição de tabelas e regras de negócio

## Como Usar

```bash
# Copie os exemplos para as pastas de input
cp examples/cobol/*.cbl 01_input/cobol/
cp examples/docs/*.md 01_input/docs/
# Converta o CSV para XLSX ou ajuste o parser

# Execute o pipeline
python scripts/parse_cobol.py
python scripts/parse_excel.py
python 03_graph/load_cobol.py
python 03_graph/load_excel.py
python scripts/parse_docs.py
python 03_graph/load_docs.py
```

## O que esperar no grafo

Após a carga, o grafo deve conter aproximadamente:
- **10 nós Program**
- **8 nós Table** (TB_CLIENTE, TB_ENDERECO, TB_TELEFONE, TB_DEPENDENTE, TB_LOG_OPERACAO, TB_CEP, TB_DDD, TB_DEPENDENTE)
- **~30 nós Column**
- **~10 nós Copybook** (CPYCLI01, CPYERRO, CPYLOG01, CPYVAL01, CPYEND01, CPYTEL01, CPYDEP01)
- **6+ nós Consumer**
- **~40 relacionamentos READS/WRITES**
- **~5 relacionamentos CALLS**
- **~21 relacionamentos CONSUMES**
