       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMCLI06.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-ENTRADA
              ASSIGN TO ARQENTR
              ORGANIZATION IS SEQUENTIAL
              FILE STATUS IS WS-FS-ENT.
       
       DATA DIVISION.
       FILE SECTION.
       FD ARQ-ENTRADA.
       01 REG-ENTRADA            PIC X(300).
       
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-FS-ENT             PIC X(02).
       01 WS-NR-CPF             PIC 9(11).
       01 WS-NM-CLIENTE         PIC X(60).
       01 WS-NM-CLIENTE-ARQ     PIC X(60).
       01 WS-NR-RG-ARQ          PIC X(15).
       01 WS-NM-MAE-ARQ         PIC X(60).
       01 WS-DS-EMAIL-ARQ       PIC X(80).
       01 WS-NR-DDD-ARQ         PIC 9(03).
       01 WS-NR-TELEFONE-ARQ    PIC 9(09).
       01 WS-NR-CEP-ARQ         PIC 9(08).
       01 WS-DS-LOGRADOURO-ARQ  PIC X(80).
       01 WS-CD-SITUACAO        PIC X(01).
       01 WS-QTD-ATUALIZ        PIC 9(07) VALUE ZEROS.
       01 WS-QTD-NOVOS          PIC 9(07) VALUE ZEROS.
       01 WS-QTD-ERROS          PIC 9(07) VALUE ZEROS.
       01 WS-QTD-TOTAL          PIC 9(07) VALUE ZEROS.
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-FIM-ARQUIVO        PIC X(01) VALUE 'N'.
       01 WS-COMMIT-COUNT       PIC 9(05) VALUE ZEROS.
       01 WS-CLIENTE-EXISTE     PIC X(01) VALUE 'N'.
       
       01 WS-AREA-VALIDACAO.
          05 WS-VAL-CPF         PIC 9(11).
          05 WS-VAL-TIPO        PIC X(01).
          05 WS-VAL-RETORNO     PIC S9(04) COMP.
       
       COPY CPYCLI01.
       COPY CPYEND01.
       COPY CPYERRO.
       COPY CPYLOG01.
       COPY CPYVAL01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-LER-REGISTRO
           PERFORM 3000-PROCESSAR
              UNTIL WS-FIM-ARQUIVO EQUAL 'S'
           PERFORM 8000-REGISTRAR-RESUMO
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE
           MOVE ZEROS TO WS-QTD-ATUALIZ
           MOVE ZEROS TO WS-QTD-NOVOS
           MOVE ZEROS TO WS-QTD-ERROS
           MOVE ZEROS TO WS-QTD-TOTAL
           OPEN INPUT ARQ-ENTRADA.
       
       2000-LER-REGISTRO.
           READ ARQ-ENTRADA INTO REG-ENTRADA
              AT END
                 MOVE 'S' TO WS-FIM-ARQUIVO
              NOT AT END
                 UNSTRING REG-ENTRADA DELIMITED BY ';'
                    INTO WS-NR-CPF
                         WS-NM-CLIENTE-ARQ
                         WS-NR-RG-ARQ
                         WS-NM-MAE-ARQ
                         WS-DS-EMAIL-ARQ
                         WS-NR-DDD-ARQ
                         WS-NR-TELEFONE-ARQ
                         WS-NR-CEP-ARQ
                         WS-DS-LOGRADOURO-ARQ
                 END-UNSTRING
           END-READ.
       
       3000-PROCESSAR.
           ADD 1 TO WS-QTD-TOTAL
           PERFORM 3100-VALIDAR-CPF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 3200-VERIFICAR-EXISTENCIA
              IF WS-CLIENTE-EXISTE EQUAL 'S'
                 PERFORM 4000-ATUALIZAR-CLIENTE
                 PERFORM 5000-ATUALIZAR-ENDERECO
              ELSE
                 PERFORM 6000-INCLUIR-CLIENTE
                 PERFORM 6500-INCLUIR-ENDERECO
              END-IF
              IF WS-RETURN-CODE EQUAL ZEROS
                 PERFORM 7000-REGISTRAR-LOG
              END-IF
           ELSE
              ADD 1 TO WS-QTD-ERROS
              MOVE ZEROS TO WS-RETURN-CODE
           END-IF
           ADD 1 TO WS-COMMIT-COUNT
           IF WS-COMMIT-COUNT >= 1000
              EXEC SQL COMMIT END-EXEC
              MOVE ZEROS TO WS-COMMIT-COUNT
           END-IF
           PERFORM 2000-LER-REGISTRO.
       
       3100-VALIDAR-CPF.
           MOVE WS-NR-CPF TO WS-VAL-CPF
           MOVE 'F' TO WS-VAL-TIPO
           MOVE ZEROS TO WS-VAL-RETORNO
           CALL 'PGMVAL01' USING WS-AREA-VALIDACAO
           IF WS-VAL-RETORNO EQUAL 4
              MOVE 8 TO WS-RETURN-CODE
           ELSE
              MOVE ZEROS TO WS-RETURN-CODE
           END-IF.
       
       3200-VERIFICAR-EXISTENCIA.
           MOVE 'N' TO WS-CLIENTE-EXISTE.
           EXEC SQL
              SELECT NM_CLIENTE,
                     CD_SITUACAO
              FROM TB_CLIENTE
              WHERE NR_CPF = :WS-NR-CPF
           END-EXEC.
           IF SQLCODE EQUAL 0
              MOVE 'S' TO WS-CLIENTE-EXISTE
           END-IF.
       
       4000-ATUALIZAR-CLIENTE.
           EXEC SQL
              UPDATE TB_CLIENTE
              SET NM_CLIENTE     = :WS-NM-CLIENTE-ARQ,
                  NR_RG          = :WS-NR-RG-ARQ,
                  NM_MAE         = :WS-NM-MAE-ARQ,
                  DS_EMAIL       = :WS-DS-EMAIL-ARQ,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF
           END-EXEC.
           IF SQLCODE EQUAL 0
              ADD 1 TO WS-QTD-ATUALIZ
           ELSE
              ADD 1 TO WS-QTD-ERROS
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       5000-ATUALIZAR-ENDERECO.
           EXEC SQL
              UPDATE TB_ENDERECO
              SET DS_LOGRADOURO  = :WS-DS-LOGRADOURO-ARQ,
                  NR_CEP         = :WS-NR-CEP-ARQ,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_TIPO_ENDERECO = 'R'
           END-EXEC.
       
       6000-INCLUIR-CLIENTE.
           EXEC SQL
              INSERT INTO TB_CLIENTE
                 (NR_CPF,
                  NM_CLIENTE,
                  NR_RG,
                  NM_MAE,
                  DS_EMAIL,
                  CD_SITUACAO,
                  DT_INCLUSAO,
                  DT_ATUALIZACAO)
              VALUES
                 (:WS-NR-CPF,
                  :WS-NM-CLIENTE-ARQ,
                  :WS-NR-RG-ARQ,
                  :WS-NM-MAE-ARQ,
                  :WS-DS-EMAIL-ARQ,
                  'A',
                  CURRENT TIMESTAMP,
                  CURRENT TIMESTAMP)
           END-EXEC.
           IF SQLCODE EQUAL 0
              ADD 1 TO WS-QTD-NOVOS
           ELSE
              ADD 1 TO WS-QTD-ERROS
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       6500-INCLUIR-ENDERECO.
           EXEC SQL
              INSERT INTO TB_ENDERECO
                 (NR_CPF,
                  CD_TIPO_ENDERECO,
                  DS_LOGRADOURO,
                  NR_CEP,
                  DT_INCLUSAO,
                  DT_ATUALIZACAO)
              VALUES
                 (:WS-NR-CPF,
                  'R',
                  :WS-DS-LOGRADOURO-ARQ,
                  :WS-NR-CEP-ARQ,
                  CURRENT TIMESTAMP,
                  CURRENT TIMESTAMP)
           END-EXEC.
       
       7000-REGISTRAR-LOG.
           EXEC SQL
              INSERT INTO TB_LOG_OPERACAO
                 (CD_OPERACAO,
                  NR_CPF,
                  DT_OPERACAO,
                  CD_PROGRAMA,
                  DS_DETALHE)
              VALUES
                 ('ENR',
                  :WS-NR-CPF,
                  CURRENT TIMESTAMP,
                  'PGMCLI06',
                  'ENRIQUECIMENTO CADASTRAL BATCH')
           END-EXEC.
       
       8000-REGISTRAR-RESUMO.
           EXEC SQL
              INSERT INTO TB_LOG_OPERACAO
                 (CD_OPERACAO,
                  NR_CPF,
                  DT_OPERACAO,
                  CD_PROGRAMA,
                  DS_DETALHE)
              VALUES
                 ('BAT',
                  0,
                  CURRENT TIMESTAMP,
                  'PGMCLI06',
                  'RESUMO ENRIQUECIMENTO BATCH')
           END-EXEC.
       
       9000-FINALIZAR.
           CLOSE ARQ-ENTRADA.
           EXEC SQL COMMIT END-EXEC.
           DISPLAY 'PGMCLI06 - TOTAL:       ' WS-QTD-TOTAL
           DISPLAY 'PGMCLI06 - ATUALIZADOS: ' WS-QTD-ATUALIZ
           DISPLAY 'PGMCLI06 - NOVOS:       ' WS-QTD-NOVOS
           DISPLAY 'PGMCLI06 - ERROS:       ' WS-QTD-ERROS
           MOVE WS-RETURN-CODE TO RETURN-CODE.
