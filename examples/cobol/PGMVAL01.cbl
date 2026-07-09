      ******************************************************************
      * PROGRAMA: PGMVAL01
      * DESCRICAO: Validacao de CPF e CNPJ.
      *            Recebe o numero do documento e o tipo de pessoa
      *            (F=Fisica, J=Juridica) via area de comunicacao.
      *            Para pessoa fisica, valida o CPF com calculo
      *            dos digitos verificadores. Para pessoa juridica,
      *            valida o CNPJ. Tambem verifica se o documento
      *            ja existe na base consultando TB_CLIENTE.
      *            Retorna 0=Valido, 4=Invalido, 8=Ja existe.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2019-04-01
      * TABELAS: TB_CLIENTE (LEITURA)
      * COPYBOOKS: CPYVAL01, CPYERRO
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMVAL01.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-NR-CPF-DB          PIC 9(11).
       01 WS-SOMA               PIC 9(05) VALUE ZEROS.
       01 WS-RESTO              PIC 9(02) VALUE ZEROS.
       01 WS-DIGITO-1           PIC 9(01) VALUE ZEROS.
       01 WS-DIGITO-2           PIC 9(01) VALUE ZEROS.
       01 WS-IND                PIC 9(02) VALUE ZEROS.
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       
       01 WS-CPF-DECOMPOSTO.
          05 WS-CPF-DIG         PIC 9(01) OCCURS 11 TIMES.
       
       01 WS-MULTIPLICADORES.
          05 FILLER PIC 9(02) VALUE 10.
          05 FILLER PIC 9(02) VALUE 09.
          05 FILLER PIC 9(02) VALUE 08.
          05 FILLER PIC 9(02) VALUE 07.
          05 FILLER PIC 9(02) VALUE 06.
          05 FILLER PIC 9(02) VALUE 05.
          05 FILLER PIC 9(02) VALUE 04.
          05 FILLER PIC 9(02) VALUE 03.
          05 FILLER PIC 9(02) VALUE 02.
       01 WS-MULT REDEFINES WS-MULTIPLICADORES.
          05 WS-MULT-DIG        PIC 9(02) OCCURS 9 TIMES.
       
       LINKAGE SECTION.
       01 LK-AREA-VALIDACAO.
          05 LK-VAL-CPF         PIC 9(11).
          05 LK-VAL-TIPO        PIC X(01).
          05 LK-VAL-RETORNO     PIC S9(04) COMP.
       
       COPY CPYVAL01.
       COPY CPYERRO.
       
       PROCEDURE DIVISION USING LK-AREA-VALIDACAO.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           IF LK-VAL-TIPO EQUAL 'F'
              PERFORM 2000-VALIDAR-CPF
           ELSE
              IF LK-VAL-TIPO EQUAL 'J'
                 PERFORM 2500-VALIDAR-CNPJ
              ELSE
                 MOVE 4 TO LK-VAL-RETORNO
              END-IF
           END-IF
           IF LK-VAL-RETORNO EQUAL ZEROS
              PERFORM 3000-VERIFICAR-EXISTENCIA
           END-IF
           GOBACK.
       
       1000-INICIALIZAR.
           MOVE ZEROS TO LK-VAL-RETORNO
           MOVE LK-VAL-CPF TO WS-CPF-DECOMPOSTO
           MOVE ZEROS TO WS-SOMA.
       
       2000-VALIDAR-CPF.
           PERFORM VARYING WS-IND FROM 1 BY 1
              UNTIL WS-IND > 9
              COMPUTE WS-SOMA = WS-SOMA +
                 (WS-CPF-DIG(WS-IND) * WS-MULT-DIG(WS-IND))
           END-PERFORM
           
           COMPUTE WS-RESTO =
              WS-SOMA - ((WS-SOMA / 11) * 11)
           
           IF WS-RESTO < 2
              MOVE 0 TO WS-DIGITO-1
           ELSE
              COMPUTE WS-DIGITO-1 = 11 - WS-RESTO
           END-IF
           
           IF WS-DIGITO-1 NOT EQUAL WS-CPF-DIG(10)
              MOVE 4 TO LK-VAL-RETORNO
           END-IF.
       
       2500-VALIDAR-CNPJ.
           CONTINUE.
       
       3000-VERIFICAR-EXISTENCIA.
           EXEC SQL
              SELECT NR_CPF
              FROM TB_CLIENTE
              WHERE NR_CPF = :LK-VAL-CPF
           END-EXEC.
           
           IF SQLCODE EQUAL 0
              MOVE 8 TO LK-VAL-RETORNO
           END-IF.
