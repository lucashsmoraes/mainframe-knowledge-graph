      ******************************************************************
      * PROGRAMA: PGMCLI03
      * DESCRICAO: Alteracao de dados cadastrais do cliente.
      *            Permite atualizar nome, data de nascimento,
      *            nome da mae, RG e agencia/conta do cliente.
      *            Valida o CPF chamando PGMVAL01 antes de
      *            efetuar a atualizacao. Registra a operacao
      *            no log incluindo os campos alterados.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2019-06-10
      * TABELAS: TB_CLIENTE (LEITURA/ESCRITA)
      *          TB_LOG_OPERACAO (ESCRITA)
      * PROGRAMAS CHAMADOS: PGMVAL01
      * COPYBOOKS: CPYCLI01, CPYERRO, CPYLOG01, CPYVAL01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMCLI03.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-NR-CPF             PIC 9(11).
       01 WS-NM-CLIENTE         PIC X(60).
       01 WS-NM-CLIENTE-ANT     PIC X(60).
       01 WS-DT-NASCIMENTO      PIC X(10).
       01 WS-NM-MAE             PIC X(60).
       01 WS-NR-RG              PIC X(15).
       01 WS-CD-AGENCIA         PIC 9(04).
       01 WS-NR-CONTA           PIC 9(10).
       01 WS-CD-SITUACAO        PIC X(01).
       01 WS-CD-OPERACAO        PIC X(03) VALUE 'ALT'.
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-DS-CAMPOS-ALT      PIC X(200).
       
       01 WS-AREA-VALIDACAO.
          05 WS-VAL-CPF         PIC 9(11).
          05 WS-VAL-TIPO        PIC X(01).
          05 WS-VAL-RETORNO     PIC S9(04) COMP.
       
       COPY CPYCLI01.
       COPY CPYERRO.
       COPY CPYLOG01.
       COPY CPYVAL01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-VALIDAR-EXISTENCIA
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 2500-VALIDAR-CPF
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 3000-ALTERAR-CLIENTE
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 4000-REGISTRAR-LOG
           END-IF
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE
           MOVE SPACES TO WS-DS-CAMPOS-ALT.
       
       2000-VALIDAR-EXISTENCIA.
           EXEC SQL
              SELECT NM_CLIENTE,
                     CD_SITUACAO
              FROM TB_CLIENTE
              WHERE NR_CPF = :WS-NR-CPF
           END-EXEC.
           
           IF SQLCODE EQUAL 100
              MOVE 4 TO WS-RETURN-CODE
           END-IF
           IF SQLCODE NOT EQUAL 0 AND
              SQLCODE NOT EQUAL 100
              MOVE 12 TO WS-RETURN-CODE
           END-IF
           IF CD-SITUACAO EQUAL 'I'
              MOVE 8 TO WS-RETURN-CODE
           END-IF
           MOVE WS-NM-CLIENTE TO WS-NM-CLIENTE-ANT.
       
       2500-VALIDAR-CPF.
           MOVE WS-NR-CPF TO WS-VAL-CPF
           MOVE 'F' TO WS-VAL-TIPO
           MOVE ZEROS TO WS-VAL-RETORNO
           CALL 'PGMVAL01' USING WS-AREA-VALIDACAO
           IF WS-VAL-RETORNO NOT EQUAL ZEROS
              MOVE 8 TO WS-RETURN-CODE
           END-IF.
       
       3000-ALTERAR-CLIENTE.
           EXEC SQL
              UPDATE TB_CLIENTE
              SET NM_CLIENTE     = :WS-NM-CLIENTE,
                  DT_NASCIMENTO  = :WS-DT-NASCIMENTO,
                  NM_MAE         = :WS-NM-MAE,
                  NR_RG          = :WS-NR-RG,
                  CD_AGENCIA     = :WS-CD-AGENCIA,
                  NR_CONTA       = :WS-NR-CONTA,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_SITUACAO = 'A'
           END-EXEC.
           
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       4000-REGISTRAR-LOG.
           STRING 'ALTERACAO CADASTRAL - CAMPOS: '
                  WS-DS-CAMPOS-ALT
                  DELIMITED BY SIZE
                  INTO WS-DS-CAMPOS-ALT
           END-STRING.
           
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
                  'PGMCLI03',
                  :WS-DS-CAMPOS-ALT)
           END-EXEC.
       
       9000-FINALIZAR.
           IF WS-RETURN-CODE EQUAL ZEROS
              EXEC SQL COMMIT END-EXEC
           ELSE
              EXEC SQL ROLLBACK END-EXEC
           END-IF.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
