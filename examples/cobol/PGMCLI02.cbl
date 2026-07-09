      ******************************************************************
      * PROGRAMA: PGMCLI02
      * DESCRICAO: Inclusao de novo cliente no sistema cadastral.
      *            Recebe os dados do cliente via area de comunicacao,
      *            valida o CPF chamando o programa PGMVAL01,
      *            insere o registro na tabela TB_CLIENTE e
      *            registra a operacao na tabela TB_LOG_OPERACAO.
      *            Em caso de CPF invalido, retorna codigo 8.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2019-05-20
      * TABELAS: TB_CLIENTE (ESCRITA)
      *          TB_LOG_OPERACAO (ESCRITA)
      * PROGRAMAS CHAMADOS: PGMVAL01
      * COPYBOOKS: CPYCLI01, CPYERRO, CPYLOG01, CPYVAL01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMCLI02.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-NR-CPF             PIC 9(11).
       01 WS-NM-CLIENTE         PIC X(60).
       01 WS-DT-NASCIMENTO      PIC X(10).
       01 WS-CD-SEXO            PIC X(01).
       01 WS-NM-MAE             PIC X(60).
       01 WS-CD-AGENCIA         PIC 9(04).
       01 WS-NR-CONTA           PIC 9(10).
       01 WS-CD-TIPO-PESSOA     PIC X(01).
       01 WS-NR-RG              PIC X(15).
       01 WS-CD-SITUACAO        PIC X(01) VALUE 'A'.
       01 WS-CD-OPERACAO        PIC X(03) VALUE 'INC'.
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-RETURN-VALID       PIC S9(04) COMP VALUE ZEROS.
       
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
           PERFORM 2000-VALIDAR-CPF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 3000-INCLUIR-CLIENTE
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 4000-REGISTRAR-LOG
           END-IF
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE
           MOVE ZEROS TO WS-RETURN-VALID.
       
       2000-VALIDAR-CPF.
           MOVE WS-NR-CPF TO WS-VAL-CPF
           MOVE WS-CD-TIPO-PESSOA TO WS-VAL-TIPO
           MOVE ZEROS TO WS-VAL-RETORNO
           
           CALL 'PGMVAL01' USING WS-AREA-VALIDACAO
           
           MOVE WS-VAL-RETORNO TO WS-RETURN-VALID
           IF WS-RETURN-VALID NOT EQUAL ZEROS
              MOVE 8 TO WS-RETURN-CODE
           END-IF.
       
       3000-INCLUIR-CLIENTE.
           EXEC SQL
              INSERT INTO TB_CLIENTE
                 (NR_CPF,
                  NM_CLIENTE,
                  DT_NASCIMENTO,
                  CD_SEXO,
                  NM_MAE,
                  CD_AGENCIA,
                  NR_CONTA,
                  CD_TIPO_PESSOA,
                  NR_RG,
                  CD_SITUACAO,
                  DT_INCLUSAO,
                  DT_ATUALIZACAO)
              VALUES
                 (:WS-NR-CPF,
                  :WS-NM-CLIENTE,
                  :WS-DT-NASCIMENTO,
                  :WS-CD-SEXO,
                  :WS-NM-MAE,
                  :WS-CD-AGENCIA,
                  :WS-NR-CONTA,
                  :WS-CD-TIPO-PESSOA,
                  :WS-NR-RG,
                  :WS-CD-SITUACAO,
                  CURRENT TIMESTAMP,
                  CURRENT TIMESTAMP)
           END-EXEC.
           
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
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
                  'PGMCLI02',
                  'INCLUSAO CLIENTE CADASTRAL')
           END-EXEC.
       
       9000-FINALIZAR.
           IF WS-RETURN-CODE EQUAL ZEROS
              EXEC SQL
                 COMMIT
              END-EXEC
           ELSE
              EXEC SQL
                 ROLLBACK
              END-EXEC
           END-IF.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
