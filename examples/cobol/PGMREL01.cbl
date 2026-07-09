      ******************************************************************
      * PROGRAMA: PGMREL01
      * DESCRICAO: Geracao de relatorio de clientes ativos.
      *            Consulta clientes ativos com seus enderecos e
      *            telefones, gerando um relatorio consolidado.
      *            Permite filtrar por agencia e por faixa de
      *            data de inclusao. O relatorio e gravado em
      *            arquivo sequencial para envio aos gestores.
      *            Chama PGMVAL01 para validar o formato dos
      *            parametros de entrada.
      * AUTOR: EQUIPE RELATORIOS
      * DATA: 2021-01-25
      * TABELAS: TB_CLIENTE (LEITURA)
      *          TB_ENDERECO (LEITURA)
      *          TB_TELEFONE (LEITURA)
      *          TB_LOG_OPERACAO (ESCRITA)
      * PROGRAMAS CHAMADOS: PGMVAL01
      * COPYBOOKS: CPYCLI01, CPYEND01, CPYTEL01, CPYERRO, CPYLOG01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMREL01.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-RELATORIO
              ASSIGN TO RELCLI
              ORGANIZATION IS SEQUENTIAL
              FILE STATUS IS WS-FS-REL.
       
       DATA DIVISION.
       FILE SECTION.
       FD ARQ-RELATORIO.
       01 REG-RELATORIO          PIC X(200).
       
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-FS-REL             PIC X(02).
       01 WS-NR-CPF             PIC 9(11).
       01 WS-NM-CLIENTE         PIC X(60).
       01 WS-DT-NASCIMENTO      PIC X(10).
       01 WS-CD-AGENCIA         PIC 9(04).
       01 WS-NR-CONTA           PIC 9(10).
       01 WS-CD-SITUACAO        PIC X(01).
       01 WS-DS-LOGRADOURO      PIC X(80).
       01 WS-NM-CIDADE          PIC X(40).
       01 WS-CD-UF              PIC X(02).
       01 WS-NR-DDD             PIC 9(03).
       01 WS-NR-TELEFONE        PIC 9(09).
       01 WS-CD-AGENCIA-FILTRO  PIC 9(04) VALUE ZEROS.
       01 WS-DT-INICIO          PIC X(10).
       01 WS-DT-FIM             PIC X(10).
       01 WS-QTD-REGISTROS      PIC 9(07) VALUE ZEROS.
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-FIM-CURSOR         PIC X(01) VALUE 'N'.
       
       01 WS-AREA-VALIDACAO.
          05 WS-VAL-CPF         PIC 9(11).
          05 WS-VAL-TIPO        PIC X(01).
          05 WS-VAL-RETORNO     PIC S9(04) COMP.
       
       COPY CPYCLI01.
       COPY CPYEND01.
       COPY CPYTEL01.
       COPY CPYERRO.
       COPY CPYLOG01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-ABRIR-CURSOR
           PERFORM 3000-PROCESSAR-CLIENTES
              UNTIL WS-FIM-CURSOR EQUAL 'S'
           PERFORM 4000-FECHAR-CURSOR
           PERFORM 5000-REGISTRAR-LOG
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE
           MOVE ZEROS TO WS-QTD-REGISTROS
           OPEN OUTPUT ARQ-RELATORIO.
       
       2000-ABRIR-CURSOR.
           EXEC SQL
              DECLARE CUR_CLIENTES CURSOR FOR
              SELECT C.NR_CPF,
                     C.NM_CLIENTE,
                     C.DT_NASCIMENTO,
                     C.CD_AGENCIA,
                     C.NR_CONTA
              FROM TB_CLIENTE C
              WHERE C.CD_SITUACAO = 'A'
                AND (C.CD_AGENCIA = :WS-CD-AGENCIA-FILTRO
                     OR :WS-CD-AGENCIA-FILTRO = 0)
                AND C.DT_INCLUSAO BETWEEN :WS-DT-INICIO
                                       AND :WS-DT-FIM
              ORDER BY C.NM_CLIENTE
           END-EXEC.
           
           EXEC SQL
              OPEN CUR_CLIENTES
           END-EXEC.
       
       3000-PROCESSAR-CLIENTES.
           EXEC SQL
              FETCH CUR_CLIENTES
              INTO :WS-NR-CPF,
                   :WS-NM-CLIENTE,
                   :WS-DT-NASCIMENTO,
                   :WS-CD-AGENCIA,
                   :WS-NR-CONTA
           END-EXEC.
           
           IF SQLCODE EQUAL 100
              MOVE 'S' TO WS-FIM-CURSOR
           ELSE
              PERFORM 3100-BUSCAR-ENDERECO
              PERFORM 3200-BUSCAR-TELEFONE
              PERFORM 3300-GRAVAR-REGISTRO
              ADD 1 TO WS-QTD-REGISTROS
           END-IF.
       
       3100-BUSCAR-ENDERECO.
           EXEC SQL
              SELECT DS_LOGRADOURO,
                     NM_CIDADE,
                     CD_UF
              FROM TB_ENDERECO
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_TIPO_ENDERECO = 'R'
           END-EXEC.
       
       3200-BUSCAR-TELEFONE.
           EXEC SQL
              SELECT NR_DDD,
                     NR_TELEFONE
              FROM TB_TELEFONE
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_TIPO_TELEFONE = 'C'
                AND CD_SITUACAO = 'A'
           END-EXEC.
       
       3300-GRAVAR-REGISTRO.
           MOVE SPACES TO REG-RELATORIO
           STRING WS-NR-CPF DELIMITED SIZE
                  ';' DELIMITED SIZE
                  WS-NM-CLIENTE DELIMITED SIZE
                  ';' DELIMITED SIZE
                  WS-CD-AGENCIA DELIMITED SIZE
                  ';' DELIMITED SIZE
                  WS-NM-CIDADE DELIMITED SIZE
                  ';' DELIMITED SIZE
                  WS-CD-UF DELIMITED SIZE
                  ';' DELIMITED SIZE
                  WS-NR-DDD DELIMITED SIZE
                  WS-NR-TELEFONE DELIMITED SIZE
                  INTO REG-RELATORIO
           END-STRING.
           WRITE REG-RELATORIO.
       
       4000-FECHAR-CURSOR.
           EXEC SQL
              CLOSE CUR_CLIENTES
           END-EXEC.
           CLOSE ARQ-RELATORIO.
       
       5000-REGISTRAR-LOG.
           EXEC SQL
              INSERT INTO TB_LOG_OPERACAO
                 (CD_OPERACAO,
                  NR_CPF,
                  DT_OPERACAO,
                  CD_PROGRAMA,
                  DS_DETALHE)
              VALUES
                 ('REL',
                  0,
                  CURRENT TIMESTAMP,
                  'PGMREL01',
                  'RELATORIO CLIENTES ATIVOS')
           END-EXEC.
       
       9000-FINALIZAR.
           EXEC SQL COMMIT END-EXEC.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
