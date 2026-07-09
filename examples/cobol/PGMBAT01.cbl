      ******************************************************************
      * PROGRAMA: PGMBAT01
      * DESCRICAO: Orquestrador de processos batch do modulo cadastral.
      *            Coordena a execucao sequencial dos programas
      *            batch de manutencao de base: primeiro executa
      *            a inativacao de clientes sem acesso (PGMCLI05),
      *            depois o enriquecimento/merge cadastral (PGMCLI06)
      *            e por fim gera o relatorio consolidado (PGMREL01).
      *            Controla retornos e aborta a cadeia em caso
      *            de erro critico.
      * AUTOR: EQUIPE OPERACOES
      * DATA: 2022-03-15
      * PROGRAMAS CHAMADOS: PGMCLI05, PGMCLI06, PGMREL01
      * COPYBOOKS: CPYCLI01, CPYERRO, CPYLOG01, CPYBAT01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMBAT01.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-RETURN-STEP        PIC S9(04) COMP VALUE ZEROS.
       01 WS-STEP-ATUAL         PIC X(20).
       01 WS-DT-INICIO          PIC X(26).
       01 WS-DT-FIM             PIC X(26).
       01 WS-SQLCODE            PIC S9(09) COMP.
       
       01 WS-PARM-INATIVACAO.
          05 WS-INA-DT-CORTE    PIC X(10).
          05 WS-INA-RETORNO     PIC S9(04) COMP.
       
       01 WS-PARM-ENRIQUEC.
          05 WS-ENR-ARQ-ENTRADA PIC X(44).
          05 WS-ENR-RETORNO     PIC S9(04) COMP.
       
       01 WS-PARM-RELATORIO.
          05 WS-REL-AGENCIA     PIC 9(04).
          05 WS-REL-DT-INI      PIC X(10).
          05 WS-REL-DT-FIM      PIC X(10).
          05 WS-REL-RETORNO     PIC S9(04) COMP.
       
       COPY CPYCLI01.
       COPY CPYERRO.
       COPY CPYLOG01.
       COPY CPYBAT01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-STEP-INATIVACAO
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 3000-STEP-ENRIQUECIMENTO
           END-IF
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 4000-STEP-RELATORIO
           END-IF
           PERFORM 5000-REGISTRAR-LOG
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE
           DISPLAY 'PGMBAT01 - INICIO CADEIA BATCH'.
       
       2000-STEP-INATIVACAO.
           MOVE 'INATIVACAO' TO WS-STEP-ATUAL
           DISPLAY 'PGMBAT01 - STEP: ' WS-STEP-ATUAL
           MOVE ZEROS TO WS-INA-RETORNO
           CALL 'PGMCLI05' USING WS-PARM-INATIVACAO
           MOVE WS-INA-RETORNO TO WS-RETURN-STEP
           IF WS-RETURN-STEP NOT EQUAL ZEROS
              DISPLAY 'PGMBAT01 - ERRO STEP INATIVACAO: '
                 WS-RETURN-STEP
              MOVE WS-RETURN-STEP TO WS-RETURN-CODE
           END-IF.
       
       3000-STEP-ENRIQUECIMENTO.
           MOVE 'ENRIQUECIMENTO' TO WS-STEP-ATUAL
           DISPLAY 'PGMBAT01 - STEP: ' WS-STEP-ATUAL
           MOVE ZEROS TO WS-ENR-RETORNO
           CALL 'PGMCLI06' USING WS-PARM-ENRIQUEC
           MOVE WS-ENR-RETORNO TO WS-RETURN-STEP
           IF WS-RETURN-STEP NOT EQUAL ZEROS
              DISPLAY 'PGMBAT01 - ERRO STEP ENRIQUECIMENTO: '
                 WS-RETURN-STEP
              MOVE WS-RETURN-STEP TO WS-RETURN-CODE
           END-IF.
       
       4000-STEP-RELATORIO.
           MOVE 'RELATORIO' TO WS-STEP-ATUAL
           DISPLAY 'PGMBAT01 - STEP: ' WS-STEP-ATUAL
           MOVE ZEROS TO WS-REL-AGENCIA
           MOVE ZEROS TO WS-REL-RETORNO
           CALL 'PGMREL01' USING WS-PARM-RELATORIO
           MOVE WS-REL-RETORNO TO WS-RETURN-STEP
           IF WS-RETURN-STEP NOT EQUAL ZEROS
              DISPLAY 'PGMBAT01 - ERRO STEP RELATORIO: '
                 WS-RETURN-STEP
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
                 ('BAT',
                  0,
                  CURRENT TIMESTAMP,
                  'PGMBAT01',
                  'FIM CADEIA BATCH CADASTRAL')
           END-EXEC.
       
       9000-FINALIZAR.
           EXEC SQL COMMIT END-EXEC.
           DISPLAY 'PGMBAT01 - FIM CADEIA. RC=' WS-RETURN-CODE
           MOVE WS-RETURN-CODE TO RETURN-CODE.
