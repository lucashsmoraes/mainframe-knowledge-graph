# Documentação do Módulo de Cadastro

## Visão Geral do Domínio

O módulo de cadastro é responsável pela gestão completa dos dados cadastrais dos clientes, incluindo:

- **Dados pessoais**: Nome, CPF, RG, data de nascimento, nome da mãe
- **Endereços**: Residencial, comercial, correspondência
- **Telefones**: Celular, residencial, comercial, recado
- **Dependentes**: Vinculados ao cliente titular

## Tabelas do Domínio

### TB_CLIENTE
Tabela principal com dados do cliente. Campos críticos:
- NR_CPF: Chave primária, identificação única
- CD_SITUACAO: A=Ativo, I=Inativo, M=Mesclado, B=Bloqueado
- CD_MOTIVO_INAT: Motivo da inativação (INA=Inatividade, MRG=Merge, JUD=Judicial)

### TB_ENDERECO
Endereços do cliente. Um cliente pode ter vários endereços.
- CD_TIPO_ENDERECO: R=Residencial, C=Comercial, O=Correspondência

### TB_TELEFONE
Telefones do cliente. Limite de 5 por cliente ativo.
- CD_TIPO_TELEFONE: C=Celular, R=Residencial, O=Comercial, D=Recado, F=Fax

### TB_DEPENDENTE
Dependentes vinculados ao titular.
- CD_PARENTESCO: CO=Cônjuge, FI=Filho, PA=Pai/Mãe

### TB_LOG_OPERACAO
Registro de auditoria de todas as operações realizadas.
- CD_OPERACAO: CON=Consulta, INC=Inclusão, ALT=Alteração, EXC=Exclusão, INA=Inativação, ENR=Enriquecimento, MRG=Merge, REL=Relatório, BAT=Batch

### TB_CEP
Tabela de CEPs válidos, atualizada mensalmente pelos Correios.

### TB_DDD
Tabela de DDDs válidos com localidade.

## Fluxo de Processos Batch

### JOBINA01 (Mensal)
Executa o programa PGMCLI05 para desativação automática de clientes que não acessam o sistema há mais de 365 dias. Processo crítico que afeta TB_CLIENTE, TB_ENDERECO e TB_TELEFONE.

### JOBENR01 (Semanal)
Executa o programa PGMCLI06 para enriquecimento e merge de cadastros duplicados. Recebe arquivo externo com dados atualizados e consolida na base.

### JOBREL01/JOBREL02 (Mensal/Trimestral)
Executam o programa PGMREL01 para geração de relatórios gerenciais e de auditoria.

## Regras de Negócio Críticas

1. **Validação de CPF**: Todo CPF deve ser validado pelo programa PGMVAL01 antes de inclusão ou alteração.
2. **Exclusão Lógica**: Nunca se exclui fisicamente um cliente. A exclusão é sempre lógica (CD_SITUACAO = 'I').
3. **Auditoria**: Toda operação deve gerar registro em TB_LOG_OPERACAO.
4. **Merge Cadastral**: Ao mesclar dois cadastros, o de origem recebe situação 'M' e todos os dados são migrados para o destino.
