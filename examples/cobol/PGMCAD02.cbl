      ******************************************************************
      * PROGRAMA: PGMCAD02
      * DESCRICAO: Transacao CICS de manutencao complementar.
      *            Orquestra as operacoes de endereco, telefone
      *            e dependentes do cliente. Recebe o CPF e a
      *            sub-acao do operador e despacha para o programa
      *            especializado. Utilizado pelas agencias,
      *            call center e canais digitais.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2020-05-01
      * PROGRAMAS CHAMADOS: PGMEND01, PGMTEL01, PGMDEP01
      * COPYBOOKS: CPYCLI01, CPYERRO, CPYCAD02
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMCAD02.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-CD-MODULO          PIC X(01).
       01 WS-CD-ACAO            PIC X(01).
       01 WS-NR-CPF             PIC 9(11).
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       01 WS-MSG-RETORNO        PIC X(80).
       
       01 WS-AREA-ENDERECO.
          05 WS-END-CPF         PIC 9(11).
          05 WS-END-TIPO        PIC X(01).
          05 WS-END-LOGRADOURO  PIC X(80).
          05 WS-END-NUMERO      PIC X(10).
          05 WS-END-COMPL       PIC X(40).
          05 WS-END-BAIRRO      PIC X(40).
          05 WS-END-CIDADE      PIC X(40).
          05 WS-END-UF          PIC X(02).
          05 WS-END-CEP         PIC 9(08).
          05 WS-END-ACAO        PIC X(01).
          05 WS-END-RETORNO     PIC S9(04) COMP.
       
       01 WS-AREA-TELEFONE.
          05 WS-TEL-CPF         PIC 9(11).
          05 WS-TEL-TIPO        PIC X(01).
          05 WS-TEL-DDD         PIC 9(03).
          05 WS-TEL-NUMERO      PIC 9(09).
          05 WS-TEL-ACAO        PIC X(01).
          05 WS-TEL-RETORNO     PIC S9(04) COMP.
       
       01 WS-AREA-DEPENDENTE.
          05 WS-DEP-CPF-TIT     PIC 9(11).
          05 WS-DEP-CPF-DEP     PIC 9(11).
          05 WS-DEP-NOME        PIC X(60).
          05 WS-DEP-DT-NASC     PIC X(10).
          05 WS-DEP-PARENT      PIC X(02).
          05 WS-DEP-ACAO        PIC X(01).
          05 WS-DEP-RETORNO     PIC S9(04) COMP.
       
       COPY CPYCLI01.
       COPY CPYERRO.
       COPY CPYCAD02.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-RECEBER-TELA
           PERFORM 3000-DESPACHAR
           PERFORM 4000-ENVIAR-RETORNO
           STOP RUN.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO WS-RETURN-CODE.
       
       2000-RECEBER-TELA.
           CONTINUE.
       
       3000-DESPACHAR.
           EVALUATE WS-CD-MODULO
              WHEN 'E'
                 MOVE WS-NR-CPF TO WS-END-CPF
                 MOVE WS-CD-ACAO TO WS-END-ACAO
                 CALL 'PGMEND01' USING WS-AREA-ENDERECO
                 MOVE WS-END-RETORNO TO WS-RETURN-CODE
              WHEN 'T'
                 MOVE WS-NR-CPF TO WS-TEL-CPF
                 MOVE WS-CD-ACAO TO WS-TEL-ACAO
                 CALL 'PGMTEL01' USING WS-AREA-TELEFONE
                 MOVE WS-TEL-RETORNO TO WS-RETURN-CODE
              WHEN 'D'
                 MOVE WS-NR-CPF TO WS-DEP-CPF-TIT
                 MOVE WS-CD-ACAO TO WS-DEP-ACAO
                 CALL 'PGMDEP01' USING WS-AREA-DEPENDENTE
                 MOVE WS-DEP-RETORNO TO WS-RETURN-CODE
              WHEN OTHER
                 MOVE 4 TO WS-RETURN-CODE
           END-EVALUATE.
       
       4000-ENVIAR-RETORNO.
           EVALUATE WS-RETURN-CODE
              WHEN 0
                 MOVE 'OPERACAO REALIZADA COM SUCESSO'
                    TO WS-MSG-RETORNO
              WHEN OTHER
                 MOVE 'ERRO NA OPERACAO'
                    TO WS-MSG-RETORNO
           END-EVALUATE.
