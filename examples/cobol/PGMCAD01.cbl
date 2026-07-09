      ******************************************************************
      * PROGRAMA: PGMCAD01
      * DESCRICAO: Transacao CICS de cadastro completo de clientes.
      *            Menu principal do modulo cadastral que orquestra
      *            as operacoes de consulta, inclusao, alteracao e
      *            exclusao de clientes. Recebe a acao do operador
      *            via tela CICS e despacha para o programa
      *            especializado correspondente.
      *            Utilizado pelas agencias e call center.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2019-08-01
      * PROGRAMAS CHAMADOS: PGMCLI01, PGMCLI02, PGMCLI03, PGMCLI04
      * COPYBOOKS: CPYCLI01, CPYERRO, CPYCAD01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMCAD01.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-CD-ACAO            PIC X(01).
       01 WS-NR-CPF             PIC 9(11).
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-MSG-RETORNO        PIC X(80).
       
       01 WS-AREA-CLIENTE.
          05 WS-CLI-CPF         PIC 9(11).
          05 WS-CLI-NOME        PIC X(60).
          05 WS-CLI-DT-NASC     PIC X(10).
          05 WS-CLI-SEXO        PIC X(01).
          05 WS-CLI-MAE         PIC X(60).
          05 WS-CLI-AGENCIA     PIC 9(04).
          05 WS-CLI-CONTA       PIC 9(10).
          05 WS-CLI-TIPO        PIC X(01).
          05 WS-CLI-RG          PIC X(15).
          05 WS-CLI-SITUACAO    PIC X(01).
          05 WS-CLI-RETORNO     PIC S9(04) COMP.
       
       COPY CPYCLI01.
       COPY CPYERRO.
       COPY CPYCAD01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-RECEBER-TELA
           PERFORM 3000-DESPACHAR-ACAO
           PERFORM 4000-ENVIAR-RETORNO
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE
           MOVE SPACES TO WS-MSG-RETORNO.
       
       2000-RECEBER-TELA.
           CONTINUE.
       
       3000-DESPACHAR-ACAO.
           MOVE WS-NR-CPF TO WS-CLI-CPF
           EVALUATE WS-CD-ACAO
              WHEN 'C'
                 CALL 'PGMCLI01' USING WS-AREA-CLIENTE
              WHEN 'I'
                 CALL 'PGMCLI02' USING WS-AREA-CLIENTE
              WHEN 'A'
                 CALL 'PGMCLI03' USING WS-AREA-CLIENTE
              WHEN 'E'
                 CALL 'PGMCLI04' USING WS-AREA-CLIENTE
              WHEN OTHER
                 MOVE 4 TO WS-RETURN-CODE
                 MOVE 'ACAO INVALIDA' TO WS-MSG-RETORNO
           END-EVALUATE
           MOVE WS-CLI-RETORNO TO WS-RETURN-CODE.
       
       4000-ENVIAR-RETORNO.
           EVALUATE WS-RETURN-CODE
              WHEN 0
                 MOVE 'OPERACAO REALIZADA COM SUCESSO'
                    TO WS-MSG-RETORNO
              WHEN 4
                 MOVE 'CLIENTE NAO ENCONTRADO'
                    TO WS-MSG-RETORNO
              WHEN 8
                 MOVE 'DADOS INVALIDOS'
                    TO WS-MSG-RETORNO
              WHEN OTHER
                 MOVE 'ERRO INTERNO - CONTACTE SUPORTE'
                    TO WS-MSG-RETORNO
           END-EVALUATE.
