      ******************************************************************
      * PROGRAMA: PGMEND01
      * DESCRICAO: Manutencao de enderecos do cliente.
      *            Permite consultar, incluir e atualizar enderecos
      *            na tabela TB_ENDERECO. Cada cliente pode ter
      *            multiplos enderecos (residencial, comercial,
      *            correspondencia). O programa valida o CEP
      *            consultando a tabela TB_CEP e registra
      *            todas as operacoes no log.
      * AUTOR: EQUIPE CADASTRO
      * DATA: 2020-02-14
      * TABELAS: TB_ENDERECO (LEITURA/ESCRITA)
      *          TB_CEP (LEITURA)
      *          TB_CLIENTE (LEITURA)
      *          TB_LOG_OPERACAO (ESCRITA)
      * COPYBOOKS: CPYCLI01, CPYEND01, CPYERRO, CPYLOG01
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMEND01.
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       01 WS-SQLCODE            PIC S9(09) COMP.
       01 WS-NR-CPF             PIC 9(11).
       01 WS-CD-TIPO-ENDER      PIC X(01).
       01 WS-DS-LOGRADOURO      PIC X(80).
       01 WS-NR-ENDERECO        PIC X(10).
       01 WS-DS-COMPLEMENTO     PIC X(40).
       01 WS-NM-BAIRRO          PIC X(40).
       01 WS-NM-CIDADE          PIC X(40).
       01 WS-CD-UF              PIC X(02).
       01 WS-NR-CEP             PIC 9(08).
       01 WS-NM-CIDADE-CEP      PIC X(40).
       01 WS-CD-UF-CEP          PIC X(02).
       01 WS-CD-OPERACAO        PIC X(03).
       01 WS-CD-ACAO            PIC X(01).
       01 WS-RETURN-CODE        PIC S9(04) COMP VALUE ZEROS.
       
       COPY CPYCLI01.
       COPY CPYEND01.
       COPY CPYERRO.
       COPY CPYLOG01.
       
       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 1500-VALIDAR-CLIENTE
           IF WS-RETURN-CODE EQUAL ZEROS
              EVALUATE WS-CD-ACAO
                 WHEN 'C'
                    PERFORM 2000-CONSULTAR-ENDERECO
                 WHEN 'I'
                    PERFORM 2500-VALIDAR-CEP
                    IF WS-RETURN-CODE EQUAL ZEROS
                       PERFORM 3000-INCLUIR-ENDERECO
                    END-IF
                 WHEN 'A'
                    PERFORM 2500-VALIDAR-CEP
                    IF WS-RETURN-CODE EQUAL ZEROS
                       PERFORM 4000-ALTERAR-ENDERECO
                    END-IF
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
       
       2000-CONSULTAR-ENDERECO.
           EXEC SQL
              SELECT DS_LOGRADOURO,
                     NR_ENDERECO,
                     DS_COMPLEMENTO,
                     NM_BAIRRO,
                     NM_CIDADE,
                     CD_UF,
                     NR_CEP
              FROM TB_ENDERECO
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_TIPO_ENDERECO = :WS-CD-TIPO-ENDER
           END-EXEC.
           IF SQLCODE EQUAL 100
              MOVE 4 TO WS-RETURN-CODE
           END-IF.
       
       2500-VALIDAR-CEP.
           EXEC SQL
              SELECT NM_CIDADE,
                     CD_UF
              FROM TB_CEP
              WHERE NR_CEP = :WS-NR-CEP
           END-EXEC.
           IF SQLCODE EQUAL 100
              MOVE 8 TO WS-RETURN-CODE
           ELSE
              MOVE WS-NM-CIDADE-CEP TO WS-NM-CIDADE
              MOVE WS-CD-UF-CEP TO WS-CD-UF
           END-IF.
       
       3000-INCLUIR-ENDERECO.
           MOVE 'INC' TO WS-CD-OPERACAO.
           EXEC SQL
              INSERT INTO TB_ENDERECO
                 (NR_CPF,
                  CD_TIPO_ENDERECO,
                  DS_LOGRADOURO,
                  NR_ENDERECO,
                  DS_COMPLEMENTO,
                  NM_BAIRRO,
                  NM_CIDADE,
                  CD_UF,
                  NR_CEP,
                  DT_INCLUSAO,
                  DT_ATUALIZACAO)
              VALUES
                 (:WS-NR-CPF,
                  :WS-CD-TIPO-ENDER,
                  :WS-DS-LOGRADOURO,
                  :WS-NR-ENDERECO,
                  :WS-DS-COMPLEMENTO,
                  :WS-NM-BAIRRO,
                  :WS-NM-CIDADE,
                  :WS-CD-UF,
                  :WS-NR-CEP,
                  CURRENT TIMESTAMP,
                  CURRENT TIMESTAMP)
           END-EXEC.
           IF SQLCODE NOT EQUAL 0
              MOVE 12 TO WS-RETURN-CODE
           END-IF.
       
       4000-ALTERAR-ENDERECO.
           MOVE 'ALT' TO WS-CD-OPERACAO.
           EXEC SQL
              UPDATE TB_ENDERECO
              SET DS_LOGRADOURO  = :WS-DS-LOGRADOURO,
                  NR_ENDERECO    = :WS-NR-ENDERECO,
                  DS_COMPLEMENTO = :WS-DS-COMPLEMENTO,
                  NM_BAIRRO      = :WS-NM-BAIRRO,
                  NM_CIDADE      = :WS-NM-CIDADE,
                  CD_UF          = :WS-CD-UF,
                  NR_CEP         = :WS-NR-CEP,
                  DT_ATUALIZACAO = CURRENT TIMESTAMP
              WHERE NR_CPF = :WS-NR-CPF
                AND CD_TIPO_ENDERECO = :WS-CD-TIPO-ENDER
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
                  :WS-NR-CPF,
                  CURRENT TIMESTAMP,
                  'PGMEND01',
                  'MANUTENCAO ENDERECO')
           END-EXEC.
       
       9000-FINALIZAR.
           IF WS-RETURN-CODE EQUAL ZEROS
              EXEC SQL COMMIT END-EXEC
           ELSE
              EXEC SQL ROLLBACK END-EXEC
           END-IF.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
