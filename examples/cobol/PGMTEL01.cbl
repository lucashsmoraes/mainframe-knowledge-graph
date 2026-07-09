      ******************************************************************
      * PROGRAMA: PGMTEL01
      * DESCRICAO: Manutencao de telefones do cliente.
      *            Permite incluir, alterar e excluir telefones
      *            vinculados a um cliente na tabela TB_TELEFONE.
      *            Cada cliente pode ter ate 5 telefones cadastrados
      *            (celular, residencial, comercial, recado, fax).
      *            Valida o DDD consultando TB_DDD e registra
      *            operacoes no log.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2020-04-18
      * TABELAS: TB_TELEFONE (LEITURA/ESCRITA)
      *          TB_CLIENTE (LEITURA)
      *          TB_DDD (LEITURA)
      *          TB_LOG_OPERACAO (ESCRITA)
      * COPYBOOKS: CPYCLI01, CPYTEL01, CPYERRO, CPYLOG01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMTEL01.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-NR-CPF             PIC 9(11).
       01 WS-CD-TIPO-FONE       PIC X(01).
       01 WS-NR-DDD             PIC 9(03).
       01 WS-NR-TELEFONE        PIC 9(09).
       01 WS-CD-ACAO            PIC X(01).
       01 WS-CD-OPERACAO        PIC X(03).
       01 WS-QTD-TELEFONES      PIC 9(02) VALUE ZEROS.
       01 WS-NM-LOCALIDADE      PIC X(40).
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       
       COPY CPYCLI01.
       COPY CPYTEL01.
       COPY CPYERRO.
       COPY CPYLOG01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 1500-VALIDAR-CLIENTE
           IF WS-RETURN-CODE EQUAL ZEROS
              EVALUATE WS-CD-ACAO
                 WHEN 'I'
                    PERFORM 2000-VALIDAR-DDD
                    IF WS-RETURN-CODE EQUAL ZEROS
                       PERFORM 2500-VERIFICAR-LIMITE
                       IF WS-RETURN-CODE EQUAL ZEROS
                          PERFORM 3000-INCLUIR-TELEFONE
                       END-IF
                    END-IF
                 WHEN 'A'
                    PERFORM 2000-VALIDAR-DDD
                    IF WS-RETURN-CODE EQUAL ZEROS
                       PERFORM 4000-ALTERAR-TELEFONE
                    END-IF
                 WHEN 'E'
                    PERFORM 5000-EXCLUIR-TELEFONE
                 WHEN OTHER
                    MOVE 4 TO WS-RETURN-CODE
              END-EVALUATE
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 6000-REGISTRAR-LOG
           END-IF
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE.
       
       1500-VALIDAR-CLIENTE.
           EXEC SQL
              SELECT NR_CPF
              FROM TB_CLIENTE
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_SITUACAO = 'A'
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 4 TO WS-RETURN-CODE
           END-IF.
       
       2000-VALIDAR-DDD.
           EXEC SQL
              SELECT NM_LOCALIDADE
              FROM TB_DDD
              WHERE NR_DDD = :WS-NR-DDD
           END-EXEC.
           IF SQLCODE EQUAL 100
              MOVE 8 TO WS-RETURN-CODE
           END-IF.
       
       2500-VERIFICAR-LIMITE.
           EXEC SQL
              SELECT COUNT(*)
              INTO :WS-QTD-TELEFONES
              FROM TB_TELEFONE
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_SITUACAO = 'A'
           END-EXEC.
           IF WS-QTD-TELEFONES >= 5
              MOVE 8 TO WS-RETURN-CODE
           END-IF.
       
       3000-INCLUIR-TELEFONE.
           MOVE 'INC' TO WS-CD-OPERACAO.
           EXEC SQL
              INSERT INTO TB_TELEFONE
                 (NR_CPF,
                  CD_TIPO_TELEFONE,
                  NR_DDD,
                  NR_TELEFONE,
                  CD_SITUACAO,
                  DT_INCLUSAO,
                  DT_ATUALIZACAO)
              VALUES
                 (:WS-NR-CPF,
                  :WS-CD-TIPO-FONE,
                  :WS-NR-DDD,
                  :WS-NR-TELEFONE,
                  'A',
                  CURRENT TIMESTAMP,
                  CURRENT TIMESTAMP)
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       4000-ALTERAR-TELEFONE.
           MOVE 'ALT' TO WS-CD-OPERACAO.
           EXEC SQL
              UPDATE TB_TELEFONE
              SET NR_DDD        = :WS-NR-DDD,
                  NR_TELEFONE   = :WS-NR-TELEFONE,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_TIPO_TELEFONE = :WS-CD-TIPO-FONE
                AND CD_SITUACAO = 'A'
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       5000-EXCLUIR-TELEFONE.
           MOVE 'EXC' TO WS-CD-OPERACAO.
           EXEC SQL
              DELETE FROM TB_TELEFONE
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_TIPO_TELEFONE = :WS-CD-TIPO-FONE
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       6000-REGISTRAR-LOG.
           EXEC SQL
              INSERT INTO TB_LOG_OPERACAO
                 (CD_OPERACAO,
                  NR_CPF,
                  DT_OPERACAO,
                  CD_PROGRAMA,
                  DS_DETALHE)
              VALUES
                 (:WS-CD-OPERACAO,
                  :WS-NR-CPF,
                  CURRENT TIMESTAMP,
                  'PGMTEL01',
                  'MANUTENCAO TELEFONE')
           END-EXEC.
       
       9000-FINALIZAR.
           IF WS-RETURN-CODE EQUAL ZEROS
              EXEC SQL COMMIT END-EXEC
           ELSE
              EXEC SQL ROLLBACK END-EXEC
           END-IF.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
