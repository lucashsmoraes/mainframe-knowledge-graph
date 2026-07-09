      ******************************************************************
      * PROGRAMA: PGMDEP01
      * DESCRICAO: Manutencao de dependentes do cliente.
      *            Permite incluir, consultar e excluir dependentes
      *            vinculados a um cliente titular. Cada dependente
      *            possui CPF proprio, grau de parentesco e data
      *            de nascimento. O programa valida se o cliente
      *            titular existe e esta ativo, e verifica
      *            duplicidade de CPF do dependente.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2021-08-10
      * TABELAS: TB_DEPENDENTE (LEITURA/ESCRITA)
      *          TB_CLIENTE (LEITURA)
      *          TB_LOG_OPERACAO (ESCRITA)
      * PROGRAMAS CHAMADOS: PGMVAL01
      * COPYBOOKS: CPYCLI01, CPYDEP01, CPYERRO, CPYLOG01, CPYVAL01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMDEP01.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-NR-CPF-TITULAR     PIC 9(11).
       01 WS-NR-CPF-DEPEND      PIC 9(11).
       01 WS-NM-DEPENDENTE      PIC X(60).
       01 WS-DT-NASCIMENTO      PIC X(10).
       01 WS-CD-PARENTESCO       PIC X(02).
       01 WS-CD-ACAO            PIC X(01).
       01 WS-CD-OPERACAO        PIC X(03).
       01 WS-QTD-DEPEND         PIC 9(02) VALUE ZEROS.
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       
       01 WS-AREA-VALIDACAO.
          05 WS-VAL-CPF         PIC 9(11).
          05 WS-VAL-TIPO        PIC X(01).
          05 WS-VAL-RETORNO     PIC S9(04) COMP.
       
       COPY CPYCLI01.
       COPY CPYDEP01.
       COPY CPYERRO.
       COPY CPYLOG01.
       COPY CPYVAL01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 1500-VALIDAR-TITULAR
           IF WS-RETURN-CODE EQUAL ZEROS
              EVALUATE WS-CD-ACAO
                 WHEN 'C'
                    PERFORM 2000-CONSULTAR-DEPENDENTES
                 WHEN 'I'
                    PERFORM 2500-VALIDAR-CPF-DEPEND
                    IF WS-RETURN-CODE EQUAL ZEROS
                       PERFORM 3000-INCLUIR-DEPENDENTE
                    END-IF
                 WHEN 'E'
                    PERFORM 4000-EXCLUIR-DEPENDENTE
                 WHEN OTHER
                    MOVE 4 TO WS-RETURN-CODE
              END-EVALUATE
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 5000-REGISTRAR-LOG
           END-IF
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE.
       
       1500-VALIDAR-TITULAR.
           EXEC SQL
              SELECT NR_CPF
              FROM TB_CLIENTE
              WHERE NR_CPF = :WS-NR-CPF-TITULAR
                AND CD_SITUACAO = 'A'
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 4 TO WS-RETURN-CODE
           END-IF.
       
       2000-CONSULTAR-DEPENDENTES.
           EXEC SQL
              SELECT COUNT(*)
              INTO :WS-QTD-DEPEND
              FROM TB_DEPENDENTE
              WHERE NR_CPF_TITULAR = :WS-NR-CPF-TITULAR
                AND CD_SITUACAO = 'A'
           END-EXEC.
       
       2500-VALIDAR-CPF-DEPEND.
           MOVE WS-NR-CPF-DEPEND TO WS-VAL-CPF
           MOVE 'F' TO WS-VAL-TIPO
           MOVE ZEROS TO WS-VAL-RETORNO
           CALL 'PGMVAL01' USING WS-AREA-VALIDACAO
           IF WS-VAL-RETORNO NOT EQUAL ZEROS
              MOVE 8 TO WS-RETURN-CODE
           END-IF.
       
       3000-INCLUIR-DEPENDENTE.
           MOVE 'INC' TO WS-CD-OPERACAO.
           EXEC SQL
              INSERT INTO TB_DEPENDENTE
                 (NR_CPF_TITULAR,
                  NR_CPF_DEPENDENTE,
                  NM_DEPENDENTE,
                  DT_NASCIMENTO,
                  CD_PARENTESCO,
                  CD_SITUACAO,
                  DT_INCLUSAO)
              VALUES
                 (:WS-NR-CPF-TITULAR,
                  :WS-NR-CPF-DEPEND,
                  :WS-NM-DEPENDENTE,
                  :WS-DT-NASCIMENTO,
                  :WS-CD-PARENTESCO,
                  'A',
                  CURRENT TIMESTAMP)
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       4000-EXCLUIR-DEPENDENTE.
           MOVE 'EXC' TO WS-CD-OPERACAO.
           EXEC SQL
              DELETE FROM TB_DEPENDENTE
              WHERE NR_CPF_TITULAR = :WS-NR-CPF-TITULAR
                AND NR_CPF_DEPENDENTE = :WS-NR-CPF-DEPEND
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       5000-REGISTRAR-LOG.
           EXEC SQL
              INSERT INTO TB_LOG_OPERACAO
                 (CD_OPERACAO,
                  NR_CPF,
                  DT_OPERACAO,
                  CD_PROGRAMA,
                  DS_DETALHE)
              VALUES
                 (:WS-CD-OPERACAO,
                  :WS-NR-CPF-TITULAR,
                  CURRENT TIMESTAMP,
                  'PGMDEP01',
                  'MANUTENCAO DEPENDENTE')
           END-EXEC.
       
       9000-FINALIZAR.
           IF WS-RETURN-CODE EQUAL ZEROS
              EXEC SQL COMMIT END-EXEC
           ELSE
              EXEC SQL ROLLBACK END-EXEC
           END-IF.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
