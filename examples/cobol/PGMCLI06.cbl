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
       01 WS-QTD-MESCLADOS      PIC 9(07) VALUE ZEROS.
       01 WS-QTD-ERROS          PIC 9(07) VALUE ZEROS.
       01 WS-QTD-TOTAL          PIC 9(07) VALUE ZEROS.
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-FIM-ARQUIVO        PIC X(01) VALUE 'N'.
       01 WS-COMMIT-COUNT       PIC 9(05) VALUE ZEROS.
       01 WS-NR-CPF-DESTINO     PIC 9(11).
       01 WS-NR-CPF-ORIGEM      PIC 9(11).
       
       COPY CPYCLI01.
       COPY CPYEND01.
       COPY CPYTEL01.
       COPY CPYERRO.
       COPY CPYLOG01.
       
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
           MOVE ZEROS TO WS-QTD-MESCLADOS
           MOVE ZEROS TO WS-QTD-ERROS
           MOVE ZEROS TO WS-QTD-TOTAL
           OPEN INPUT ARQ-ENTRADA.
       
       2000-LER-REGISTRO.
           READ ARQ-ENTRADA INTO REG-ENTRADA
              AT END
                 MOVE 'S' TO WS-FIM-ARQUIVO
              NOT AT END
                 UNSTRING REG-ENTRADA DELIMITED BY ';'
                    INTO WS-NR-CPF-ORIGEM
                         WS-NR-CPF-DESTINO
                 END-UNSTRING
           END-READ.
       
       3000-PROCESSAR.
           ADD 1 TO WS-QTD-TOTAL
           PERFORM 3100-VALIDAR-ORIGEM
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 3200-VALIDAR-DESTINO
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 4000-MIGRAR-ENDERECOS
              PERFORM 5000-MIGRAR-TELEFONES
              PERFORM 5500-MIGRAR-DEPENDENTES
              PERFORM 6000-INATIVAR-ORIGEM
              PERFORM 7000-REGISTRAR-LOG
              ADD 1 TO WS-QTD-MESCLADOS
           ELSE
              ADD 1 TO WS-QTD-ERROS
              MOVE ZEROS TO WS-RETURN-CODE
           END-IF
           ADD 1 TO WS-COMMIT-COUNT
           IF WS-COMMIT-COUNT >= 100
              EXEC SQL COMMIT END-EXEC
              MOVE ZEROS TO WS-COMMIT-COUNT
           END-IF
           PERFORM 2000-LER-REGISTRO.
       
       3100-VALIDAR-ORIGEM.
           EXEC SQL
              SELECT NM_CLIENTE,
                     CD_SITUACAO
              FROM TB_CLIENTE
              WHERE NR_CPF = :WS-NR-CPF-ORIGEM
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 4 TO WS-RETURN-CODE
           END-IF.
       
       3200-VALIDAR-DESTINO.
           EXEC SQL
              SELECT NM_CLIENTE
              FROM TB_CLIENTE
              WHERE NR_CPF = :WS-NR-CPF-DESTINO
                AND CD_SITUACAO = 'A'
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 4 TO WS-RETURN-CODE
           END-IF.
       
       4000-MIGRAR-ENDERECOS.
           EXEC SQL
              UPDATE TB_ENDERECO
              SET NR_CPF         = :WS-NR-CPF-DESTINO,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF-ORIGEM
           END-EXEC.
       
       5000-MIGRAR-TELEFONES.
           EXEC SQL
              UPDATE TB_TELEFONE
              SET NR_CPF         = :WS-NR-CPF-DESTINO,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF-ORIGEM
           END-EXEC.
       
       5500-MIGRAR-DEPENDENTES.
           EXEC SQL
              UPDATE TB_DEPENDENTE
              SET NR_CPF_TITULAR = :WS-NR-CPF-DESTINO,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF_TITULAR = :WS-NR-CPF-ORIGEM
           END-EXEC.
       
       6000-INATIVAR-ORIGEM.
           EXEC SQL
              UPDATE TB_CLIENTE
              SET CD_SITUACAO    = 'M',
                  CD_MOTIVO_INAT = 'MRG',
                  DT_INATIVACAO  = CURRENT TIMESTAMP,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF-ORIGEM
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
                 ('MRG',
                  :WS-NR-CPF-DESTINO,
                  CURRENT TIMESTAMP,
                  'PGMCLI06',
                  'MERGE CADASTRAL - DUPLICIDADE')
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
                  'RESUMO MERGE CADASTRAL')
           END-EXEC.
       
       9000-FINALIZAR.
           CLOSE ARQ-ENTRADA.
           EXEC SQL COMMIT END-EXEC.
           DISPLAY 'PGMCLI06 - TOTAL:      ' WS-QTD-TOTAL
           DISPLAY 'PGMCLI06 - MESCLADOS:  ' WS-QTD-MESCLADOS
           DISPLAY 'PGMCLI06 - ERROS:      ' WS-QTD-ERROS
           MOVE WS-RETURN-CODE TO RETURN-CODE.
