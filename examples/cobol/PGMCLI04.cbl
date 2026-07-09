      ******************************************************************
      * PROGRAMA: PGMCLI04
      * DESCRICAO: Exclusao logica de cliente do sistema cadastral.
      *            Nao remove fisicamente o registro, apenas altera
      *            o campo CD_SITUACAO para 'I' (Inativo) e
      *            registra a data de inativacao. Tambem exclui
      *            os telefones vinculados (exclusao logica) e
      *            registra toda a operacao no log.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2019-07-22
      * TABELAS: TB_CLIENTE (LEITURA/ESCRITA)
      *          TB_TELEFONE (ESCRITA)
      *          TB_LOG_OPERACAO (ESCRITA)
      * COPYBOOKS: CPYCLI01, CPYERRO, CPYLOG01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMCLI04.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-NR-CPF             PIC 9(11).
       01 WS-NM-CLIENTE         PIC X(60).
       01 WS-CD-SITUACAO        PIC X(01).
       01 WS-CD-MOTIVO          PIC X(03).
       01 WS-DS-MOTIVO          PIC X(100).
       01 WS-CD-OPERACAO        PIC X(03) VALUE 'EXC'.
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-QTD-TEL-INAT       PIC 9(05) VALUE ZEROS.
       
       COPY CPYCLI01.
       COPY CPYERRO.
       COPY CPYLOG01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-VALIDAR-CLIENTE
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 3000-INATIVAR-CLIENTE
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 3500-INATIVAR-TELEFONES
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 4000-REGISTRAR-LOG
           END-IF
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE
           MOVE ZEROS TO WS-QTD-TEL-INAT.
       
       2000-VALIDAR-CLIENTE.
           EXEC SQL
              SELECT NM_CLIENTE,
                     CD_SITUACAO
              FROM TB_CLIENTE
              WHERE NR_CPF = :WS-NR-CPF
           END-EXEC.
           
           EVALUATE SQLCODE
              WHEN 0
                 IF WS-CD-SITUACAO EQUAL 'I'
                    MOVE 4 TO WS-RETURN-CODE
                 END-IF
              WHEN 100
                 MOVE 4 TO WS-RETURN-CODE
              WHEN OTHER
                 MOVE 12 TO WS-RETURN-CODE
           END-EVALUATE.
       
       3000-INATIVAR-CLIENTE.
           EXEC SQL
              UPDATE TB_CLIENTE
              SET CD_SITUACAO    = 'I',
                  DT_INATIVACAO  = CURRENT TIMESTAMP,
                  CD_MOTIVO_INAT = :WS-CD-MOTIVO,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_SITUACAO = 'A'
           END-EXEC.
           
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       3500-INATIVAR-TELEFONES.
           EXEC SQL
              UPDATE TB_TELEFONE
              SET CD_SITUACAO    = 'I',
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_SITUACAO = 'A'
           END-EXEC.
           
           MOVE SQLCODE TO WS-SQLCODE.
       
       4000-REGISTRAR-LOG.
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
                  'PGMCLI04',
                  :WS-DS-MOTIVO)
           END-EXEC.
       
       9000-FINALIZAR.
           IF WS-RETURN-CODE EQUAL ZEROS
              EXEC SQL COMMIT END-EXEC
           ELSE
              EXEC SQL ROLLBACK END-EXEC
           END-IF.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
