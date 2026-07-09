      ******************************************************************
      * PROGRAMA: PGMCLI01
      * DESCRICAO: Consulta de dados cadastrais de cliente por CPF.
      *            Busca informacoes na tabela TB_CLIENTE e retorna
      *            os dados completos do cliente incluindo nome,
      *            data de nascimento, situacao cadastral e data
      *            da ultima atualizacao. Utilizado pelos canais
      *            digitais e atendimento presencial.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2019-03-15
      * TABELAS: TB_CLIENTE (LEITURA)
      *          TB_LOG_OPERACAO (ESCRITA)
      * COPYBOOKS: CPYCLI01, CPYERRO, CPYLOG01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMCLI01.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-NR-CPF             PIC 9(11).
       01 WS-NM-CLIENTE         PIC X(60).
       01 WS-DT-NASCIMENTO      PIC X(10).
       01 WS-CD-SITUACAO        PIC X(01).
       01 WS-DT-ATUALIZACAO     PIC X(26).
       01 WS-CD-AGENCIA         PIC 9(04).
       01 WS-NR-CONTA           PIC 9(10).
       01 WS-CD-OPERACAO        PIC X(03) VALUE 'CON'.
       01 WS-TIMESTAMP          PIC X(26).
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       
       COPY CPYCLI01.
       COPY CPYERRO.
       COPY CPYLOG01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-CONSULTAR-CLIENTE
           IF WS-RETURN-CODE EQUAL ZEROS
              PERFORM 3000-REGISTRAR-LOG
           END-IF
           PERFORM 9000-FINALIZAR
           STOP RUN.
       
       1000-INICIALIZAR.
           INITIALIZE WS-NM-CLIENTE
           INITIALIZE WS-DT-NASCIMENTO
           MOVE ZEROS TO WS-RETURN-CODE.
       
       2000-CONSULTAR-CLIENTE.
           EXEC SQL
              SELECT NR_CPF,
                     NM_CLIENTE,
                     DT_NASCIMENTO,
                     CD_SITUACAO,
                     DT_ATUALIZACAO,
                     CD_AGENCIA,
                     NR_CONTA
              FROM TB_CLIENTE
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_SITUACAO = 'A'
           END-EXEC.
           
           EVALUATE SQLCODE
              WHEN 0
                 CONTINUE
              WHEN 100
                 MOVE 4 TO WS-RETURN-CODE
              WHEN OTHER
                 MOVE 12 TO WS-RETURN-CODE
           END-EVALUATE.
       
       3000-REGISTRAR-LOG.
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
                  'PGMCLI01',
                  'CONSULTA DADOS CADASTRAIS')
           END-EXEC.
       
       9000-FINALIZAR.
           EXEC SQL
              COMMIT
           END-EXEC.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
