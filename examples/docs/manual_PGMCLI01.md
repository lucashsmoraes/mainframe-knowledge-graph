# Documentação do Programa PGMCLI01

## Visão Geral

O programa PGMCLI01 é responsável pela consulta de dados cadastrais de clientes no sistema mainframe. Este programa é um dos mais críticos do módulo de cadastro, sendo utilizado por todos os canais de atendimento (Internet Banking, App Mobile, Call Center e agências).

## Regras de Negócio

1. **Consulta por CPF**: O programa recebe o número do CPF como parâmetro e busca o registro na tabela TB_CLIENTE.
2. **Filtro de Situação**: Apenas clientes com situação ativa (CD_SITUACAO = 'A') são retornados. Clientes inativos não aparecem na consulta.
3. **Registro de Log**: Toda consulta realizada gera um registro na tabela TB_LOG_OPERACAO com o código 'CON', permitindo rastreabilidade e auditoria.
4. **Códigos de Retorno**:
   - 0: Consulta realizada com sucesso
   - 4: Cliente não encontrado ou inativo
   - 12: Erro de banco de dados

## Dados Retornados

- Número do CPF
- Nome completo do cliente
- Data de nascimento
- Código de situação cadastral
- Data da última atualização
- Agência e conta vinculadas

## Consumidores

Este programa é consumido pelos seguintes sistemas:
- Internet Banking (criticidade crítica)
- App Mobile (criticidade crítica)
- Atendimento Call Center (criticidade alta)

## Dependências

- Tabela TB_CLIENTE: tabela principal de dados cadastrais
- Tabela TB_LOG_OPERACAO: tabela de auditoria

## Observações

Este programa tem alto volume de execuções diárias (estimativa de 500.000 chamadas/dia) e qualquer alteração deve passar por testes rigorosos de performance.
