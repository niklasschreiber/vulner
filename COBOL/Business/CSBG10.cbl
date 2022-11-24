       IDENTIFICATION DIVISION.
       PROGRAM-ID.    CSBG10.
      *
      *****************************************************************
      * INVIO RICHIESTE ALLA CGLOBAL
      * . VENGONO LETTE IN JOIN DALLE TABELLE:
      *   CM67 CM65 CM20 CM25 E CM13
      *   TUTTE LE OCCORRENZE RELATIVE ALLE CARTE 'VO' E 'VCED'
      *   A CONDIZIONE CHE IL DETTAGLIO CM65 NON SIA STATO GI�
      *   INVIATO A CGLOBAL (DA CM13 CDSTA0 = 'RS')
      *   E CHE IL PACCO CON IL DETTAGLIO SIA STATO APERTO IN FILIALE
      *   (DA CM20 CDESI0 = 'AP)
      *   P.S. POSSONO ESISTERE PIU DETTAGLI (CM65) PER RICHIESTA (CM67)
      *   C'� UN RAPPORTO DI 1/1 TRA CM65 E CM25) E LA CM20 SI SPOSANO
      *   PER NUMERO PLICO
      *****************************************************************
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-3090 WITH DEBUGGING MODE.
       OBJECT-COMPUTER. IBM-370.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *
           SELECT FILECOMU     ASSIGN TO FILECOMU
                               ORGANIZATION SEQUENTIAL
                               ACCESS SEQUENTIAL
                               FILE STATUS STATUS-FILECOMU.
      *
      ***********************************************************
      *
       DATA DIVISION.
       FILE SECTION.

       FD FILECOMU LABEL RECORD STANDARD
                   BLOCK 0 RECORDS
                   RECORDING MODE IS F.
          01 REC-FILECOMU.
             03 OUT-ABI          PIC X(05).
             03 OUT-CAB          PIC X(05).
             03 OUT-TIPO-CARTA   PIC X(02) VALUE 'AS'.
             03 OUT-SOTTOTIPO    PIC X(06).
             03 OUT-TIPO-STAMPA  PIC X(02).
             03 OUT-NUM-ECON     PIC 9(12).
             03 OUT-COD-SICU     PIC X(08).
      *      03 OUT-CDBAN0   PIC X(05).
      *      03 OUT-FLSTO0   PIC X(01).
      *      03 OUT-TPDOC0   PIC X(02).
      *      03 OUT-CDMDT0   PIC X(06).
      *      03 OUT-TPSTA0   PIC X(02).
      *      03 OUT-NRECP0   PIC 9(12).
      *      03 OUT-NRECU0   PIC 9(12).
      *      03 OUT-QTMDR0   PIC 9(08).
      *      03 OUT-CDRCH0   PIC 9(10).
      *      03 OUT-DTRCH0   PIC X(08).
      *      03 OUT-CDSTA0   PIC X(02).
      *      03 OUT-XIDUTV   PIC X(08).
      *      03 OUT-XTERMV   PIC X(04).
      *      03 OUT-XDTMSV   PIC X(08).
      *      03 OUT-XHOMSV   PIC 9(06).
      *      03 OUT-XDTINV   PIC X(08).
      ***********************************************************
       WORKING-STORAGE SECTION.
      ***********************************************************
      *
PV0315
PV0315*--- SKEDA PARAMETRO
PV0315 01 W-SKEDA-PARAM.
PV0315    05 W-DATA-ELAB                   PIC X(8).
PV0315
PV0315*--- VARIABILI DI APPOGGIO
PV0315 01 APPO-DATA-ELAB                      PIC X(08).

      *--- FILE STATUS
       01 STATUS-FILECOMU                  PIC X(02)       VALUE SPACES.

      *--- CONTATORI
       01 LETTI                            PIC 9(12)       VALUE ZEROES.
       01 SCRITTI-OUT                      PIC 9(12)       VALUE ZEROES.
       01 INSERT-RS                        PIC 9(12)       VALUE ZEROES.
       01 UPDATE-RT                        PIC 9(12)       VALUE ZEROES.
       01 TOT-CARTE                        PIC 9(12)       VALUE ZEROES.
       01 TOT-CARTE-R                      PIC 9(12)       VALUE ZEROES.

      *--- VARIABILI DI APPOGGIO

       01 PRIMA-VOLTA                         PIC X(02) VALUE 'SI'.
       01 APPO-SCRITTURA                      PIC X(02) VALUE SPACES.
       01 APPO-STESSO                         PIC X(02) VALUE SPACES.

       01 APPO-CDMDT0                         PIC X(06) VALUE SPACES.


       01 APPO-NRECU0                         PIC 9(12) VALUE ZERO.
       01 APPO-NRECP0                         PIC 9(12) VALUE ZERO.
       01 SAVE-NRECP0                         PIC 9(12) VALUE ZERO.
       01 SAVE-NRECU0                         PIC 9(12) VALUE ZERO.
       01 APPO-QTEVA0                         PIC 9(12) VALUE ZERO.
       01 APPO-ECONOMALE                      PIC 9(12) VALUE ZERO.

       01 DATA-SISTEMA                        PIC X(08) VALUE SPACES.
       01 DATASYS.
          03  DATASYS-AA                      PIC 9(4)  VALUE ZERO.
          03  FILLER                          PIC X(1)  VALUE SPACES.
          03  DATASYS-MM                      PIC 9(2)  VALUE ZERO.
          03  FILLER                          PIC X(1)  VALUE SPACES.
          03  DATASYS-GG                      PIC 9(2)  VALUE ZERO.

       01 ORASYS.
          03  ORASYS-HH                       PIC 9(2)  VALUE ZERO.
          03  ORASYS-MM                       PIC 9(2)  VALUE ZERO.
          03  ORASYS-SS                       PIC 9(2)  VALUE ZERO.
       01 ORASYS-NUM                          PIC 9(6)  VALUE ZERO.

           EXEC SQL INCLUDE SQLCA     END-EXEC

      *BEGIN DB2
       01                 DE67.
            05            DE67-CDBAN0 PICTURE X(05).
            05            DE67-CDRCH0 PICTURE S9(10)
                               COMPUTATIONAL-3.
            05            DE67-DTRCH0 PICTURE X(8).
            05            DE67-TPDOC0 PICTURE X(02).
            05            DE67-CDMDT0 PICTURE X(06).
            05            DE67-TPSTA0 PICTURE X(02).
            05            DE67-FLQTN0 PICTURE X.
            05            DE67-FLPRM0 PICTURE X.
            05            DE67-FLGTP0 PICTURE X(01).
            05            DE67-CDDIPL PICTURE X(05).
            05            DE67-CDDPUL PICTURE X(02).
            05            DE67-NRECP0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE67-NRECU0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE67-QTMDR0 PICTURE S9(08)
                               COMPUTATIONAL-3.
            05            DE67-TPENP0 PICTURE X(02).
            05            DE67-CDENT0 PICTURE X(05).
            05            DE67-CDDIP0 PICTURE X(05).
            05            DE67-CDDPU0 PICTURE X(02).
            05            DE67-QTEVA0 PICTURE S9(8)
                               COMPUTATIONAL-3.
            05            DE67-TPENT0 PICTURE X(02).
            05            DE67-XIDUVA PICTURE X(8).
            05            DE67-XIDUAP PICTURE X(8).
            05            DE67-XIDUTI PICTURE X(8).
            05            DE67-CDSRC0 PICTURE X(02).
            05            DE67-NRREG0 PICTURE S9(8)
                               COMPUTATIONAL-3.
            05            DE67-DTRIG0 PICTURE X(8).
            05            DE67-DSNOT0 PICTURE X(55).
            05            DE67-CDDIPV PICTURE X(05).
            05            DE67-CDDPUV PICTURE X(02).
            05            DE67-XIDUTV PICTURE X(8).
            05            DE67-XTERMV PICTURE X(04).
            05            DE67-XDTMSV PICTURE X(8).
            05            DE67-XHOMSV PICTURE S9(06)
                               COMPUTATIONAL-3.
            05            DE67-DTIPL0 PICTURE X(8).
            05            DE67-XDTINV PICTURE X(8).

       01                 DE65.
            05            DE65-CDBAN0 PICTURE X(05).
            05            DE65-CDRCH0 PICTURE S9(10)
                               COMPUTATIONAL-3.
            05            DE65-DTRCH0 PICTURE X(8).
            05            DE65-TPDOC0 PICTURE X(02).
            05            DE65-CDMDT0 PICTURE X(06).
            05            DE65-TPSTA0 PICTURE X(02).
            05            DE65-NRECP0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE65-NRECU0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE65-QTMOD0 PICTURE S9(08)
                               COMPUTATIONAL-3.

       01                 DE10.
            05            DE10-CDBAN0 PICTURE X(05).
            05            DE10-TPDOC0 PICTURE X(02).
            05            DE10-CDMDT0 PICTURE X(06).
            05            DE10-TPSTA0 PICTURE X(02).
            05            DE10-CDDIPL PICTURE X(05).
            05            DE10-CDDPUL PICTURE X(02).
            05            DE10-TPUBF0 PICTURE X(02).
            05            DE10-CDDIPF PICTURE X(05).
            05            DE10-CDDPUF PICTURE X(02).
            05            DE10-CDCABR PICTURE X(07).
            05            DE10-CDABI1 PICTURE X(07).
            05            DE10-CDNDG0 PICTURE X(09).
            05            DE10-CDDPRS PICTURE X(05).
            05            DE10-CDDURS PICTURE X(02).
            05            DE10-NRECP0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE10-NRECU0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE10-CDSTV0 PICTURE X(02).
            05            DE10-CDSBV0 PICTURE X(02).
            05            DE10-CDSTV1 PICTURE X(02).
            05            DE10-CDSBV1 PICTURE X(02).
            05            DE10-FLPRZ0 PICTURE X(01).
            05            DE10-DTCAR0 PICTURE X(08).
            05            DE10-NRCAR1 PICTURE S9(10)
                               COMPUTATIONAL-3.
            05            DE10-FLIOR0 PICTURE X(01).
            05            DE10-CDRCH0 PICTURE S9(10)
                               COMPUTATIONAL-3.
            05            DE10-DTRCH0 PICTURE X(8).
            05            DE10-RIFOR0 PICTURE X(10).
            05            DE10-NRPLI1 PICTURE S9(10)
                               COMPUTATIONAL-3.
            05            DE10-DTCRP0 PICTURE X(08).
            05            DE10-CDDIV0 PICTURE X(03).
            05            DE10-IMCCR0 PICTURE S9(15)
                               COMPUTATIONAL-3.
            05            DE10-XTERMV PICTURE X(04).
            05            DE10-XIDUTV PICTURE X(08).
            05            DE10-CDDIPV PICTURE X(05).
            05            DE10-CDDPUV PICTURE X(02).
            05            DE10-XDTMSV PICTURE X(08).
            05            DE10-XHOMSV PICTURE S9(06)
                               COMPUTATIONAL-3.

       01                 DE13.
            05            DE13-CDBAN0 PICTURE X(05).
            05            DE13-FLSTO0 PICTURE X(01).
            05            DE13-TPDOC0 PICTURE X(02).
            05            DE13-CDMDT0 PICTURE X(06).
            05            DE13-TPSTA0 PICTURE X(02).
            05            DE13-NRECP0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE13-NRECU0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE13-QTMDR0 PICTURE S9(12)
                               COMPUTATIONAL-3.
            05            DE13-CDRCH0 PICTURE S9(10)
                               COMPUTATIONAL-3.
            05            DE13-DTRCH0 PICTURE X(08).
            05            DE13-CDSTA0 PICTURE X(02).
            05            DE13-XTERMV PICTURE X(04).
            05            DE13-XIDUTV PICTURE X(08).
            05            DE13-XDTMSV PICTURE X(08).
            05            DE13-XHOMSV PICTURE S9(06)
                               COMPUTATIONAL-3.
            05            DE13-XDTINV PICTURE X(8).
      *END   DB2

           EXEC SQL DECLARE SEL67 CURSOR FOR
                    SELECT ALL
                           A.CDBAN0,
                           A.TPDOC0,
                           A.CDMDT0,
                           A.TPSTA0,
                           A.CDRCH0,
                           A.DTRCH0,
                           A.QTMDR0,
                           A.QTEVA0,
                           B.NRECP0,
                           B.NRECU0
                     FROM CMRICHIESTER A
                        , CMDETRICHEST B
                        , CMDETTRICHI  C
                        , CMPLICO  D
                        , CMRICTIP F
            WHERE A.CDBAN0 = '00000'
              AND A.TPDOC0 = 'AS'
              AND A.CDMDT0 IN ('VO' , 'VCED')
              AND A.TPSTA0 = ' '
              AND A.XDTINV ^= ' '
              AND ( A.CDSRC0 = 'CH'
               OR  (A.CDSRC0 = 'AP'
              AND   A.QTEVA0 > 0 ) )
              AND B.TPDOC0 = A.TPDOC0
              AND B.CDMDT0 = A.CDMDT0
              AND B.TPSTA0 = A.TPSTA0
              AND B.CDRCH0 = A.CDRCH0
              AND C.TPDOC0 = A.TPDOC0
              AND C.CDMDT0 = A.CDMDT0
              AND C.TPSTA0 = A.TPSTA0
              AND C.NRECP0 = B.NRECP0
              AND C.NRECU0 = B.NRECU0
              AND D.NRPLI1 = C.NRPLI1
              AND D.CDESI0 = 'AP'
              AND F.TPDOC0 = A.TPDOC0
              AND F.CDMDT0 = A.CDMDT0
              AND F.TPSTA0 = A.TPSTA0
              AND F.CDRCH0 = A.CDRCH0
              AND F.CDSTA0 = 'RT'
              AND NOT EXISTS (SELECT * FROM CMRICTIP E
                               WHERE E.TPDOC0 = C.TPDOC0
                                 AND E.CDMDT0 = C.CDMDT0
                                 AND E.TPSTA0 = C.TPSTA0
                                 AND E.NRECP0 = C.NRECP0
                                 AND E.NRECU0 = C.NRECU0
                                 AND E.CDSTA0   = 'RS')
                       ORDER BY
                            A.TPDOC0,A.CDMDT0,A.TPSTA0,
                            A.XDTMSV,A.XHOMSV
           END-EXEC.
      *
      ***********************************************************
      * PROCEDURE DIVISION
      ***********************************************************
      *
       PROCEDURE DIVISION.
      *DECLARATIVES.
      *COBOL-II-DEBUG   SECTION.
      *    USE FOR DEBUGGING ON ALL PROCEDURES.
      *COBOL-II-DEBUG-PARA.
      *       DISPLAY '>' DEBUG-ITEM '<'.
      *END DECLARATIVES.
      *

           PERFORM 010-OPER-INIZ            THRU 010-EX.

           PERFORM 020-ELABORAZIONE         THRU 020-EX.

           PERFORM 030-OPER-FINALI          THRU 030-EX.
      *
      *---------------
       010-OPER-INIZ.
      *--------------
      *
           MOVE FUNCTION CURRENT-DATE       TO   DATA-SISTEMA

           ACCEPT ORASYS                    FROM TIME
           MOVE   ORASYS                    TO ORASYS-NUM.

           DISPLAY '************************************************'.
           DISPLAY '*        I N I Z I O    C S B G 1 0            *'.
           DISPLAY '************************************************'.
PV0315
PV0315     ACCEPT W-SKEDA-PARAM.
PV0315
PV0315     MOVE  W-DATA-ELAB    TO APPO-DATA-ELAB.
      *
      *--- APERTURA FILE DI OUTPUT

           OPEN OUTPUT FILECOMU.
           IF STATUS-FILECOMU NOT = '00'
              DISPLAY '************************************'
              DISPLAY '*  ERRORE APERTURA FILE OUTPUT     *'
              DISPLAY '*  FILE-STATUS : ' STATUS-FILECOMU
              DISPLAY '************************************'
              MOVE 12                            TO   RETURN-CODE
              GOBACK
           END-IF.
      *
      *--- APERTURA DEL CURSORE

              EXEC SQL
                OPEN SEL67
              END-EXEC.

              IF SQLCODE NOT = ZEROES
                 DISPLAY '************************************'
                 DISPLAY '*  ERRORE OPEN CURSORE             *'
                 DISPLAY '*  SQLCODE     : ' SQLCODE
                 DISPLAY '************************************'
                 EXEC SQL ROLLBACK END-EXEC
                 MOVE 12                          TO   RETURN-CODE
                 GOBACK
              END-IF

              PERFORM 021-FETCH-CURS      THRU 021-EX
              .
      *
      *-------------
       010-EX. EXIT.
      *-------------
      *
       020-ELABORAZIONE.
      *-----------------
      *
           PERFORM UNTIL SQLCODE = 100
              PERFORM 021-FETCH-CURS   THRU 021-EX
           END-PERFORM.
      *
      *-------------
       020-EX. EXIT.
      *-------------
      *
      *-----------------------
       021-FETCH-CURS.
      *-----------------------
      *
              EXEC SQL
                FETCH SEL67
                INTO  :DE67-CDBAN0,
                      :DE67-TPDOC0,
                      :DE67-CDMDT0,
                      :DE67-TPSTA0,
                      :DE67-CDRCH0,
                      :DE67-DTRCH0,
                      :DE67-QTMDR0,
                      :DE67-QTEVA0,
                      :DE65-NRECP0,
                      :DE65-NRECU0
              END-EXEC.

           IF SQLCODE NOT = 100
            AND SQLCODE NOT = ZEROES
              DISPLAY '*********************************'
              DISPLAY '*  ERRORE FETCH CURSORE         *'
              DISPLAY '*  SQLCODE     : ' SQLCODE
              DISPLAY '*********************************'
              EXEC SQL ROLLBACK END-EXEC
              MOVE 12                          TO   RETURN-CODE
              GOBACK
           END-IF

           IF SQLCODE = 100
              IF PRIMA-VOLTA = 'SI'
                 DISPLAY '************************************'
                 DISPLAY '*             C_GLOBAL             *'
                 DISPLAY '*        NON CI SONO CARTE         *'
                 DISPLAY '*             VO E VCED            *'
                 DISPLAY '*          DA ELABORARE            *'
                 DISPLAY '************************************'
              END-IF
           END-IF

           IF SQLCODE = 0
              MOVE 'NO' TO PRIMA-VOLTA
              ADD  1    TO LETTI
              COMPUTE TOT-CARTE =
                 TOT-CARTE + DE67-QTEVA0
              COMPUTE TOT-CARTE-R =
                 TOT-CARTE-R + DE67-QTMDR0
      *       PERFORM 023-UPDATE-CM13-RT THRU 023-EX
              PERFORM 024-INSERT-CM13-RS THRU 024-EX
              PERFORM 025-AGGIO-CM67     THRU 025-EX
              MOVE 'SI' TO APPO-SCRITTURA
      *       MOVE DE13-NRECP0  TO APPO-ECONOMALE
              MOVE DE13-NRECP0  TO APPO-ECONOMALE
              PERFORM 026-SCRITTURA-OUT THRU 026-EX
                UNTIL APPO-SCRITTURA = 'NO'
           END-IF
           .
      *
      *-------------
       021-EX. EXIT.
      *-------------
      *
      *-----------------------
       023-UPDATE-CM13-RT.
      *-----------------------
      *
           MOVE DE67-CDBAN0  TO DE13-CDBAN0
           MOVE DE67-TPDOC0  TO DE13-TPDOC0
           MOVE DE67-CDMDT0  TO DE13-CDMDT0
           MOVE DE67-TPSTA0  TO DE13-TPSTA0
           MOVE DE67-CDRCH0  TO DE13-CDRCH0
           MOVE DE67-DTRCH0  TO DE13-DTRCH0
      *
           EXEC SQL
              UPDATE      CMRICTIP
              SET FLSTO0 ='S'
              WHERE CDBAN0 = :DE13-CDBAN0
                AND TPDOC0 = :DE13-TPDOC0
                AND CDMDT0 = :DE13-CDMDT0
                AND TPSTA0 = :DE13-TPSTA0
                AND CDRCH0 = :DE13-CDRCH0
                AND DTRCH0 = :DE13-DTRCH0
                AND CDSTA0 = 'RT'
                AND XIDUTV = 'CSBT10'
                AND FLSTO0 = 'N'
           END-EXEC

           IF SQLCODE NOT = ZEROES
              DISPLAY '*****************************************'
              DISPLAY '*  ERRORE UPDATE TABELLA CM13 STATO: RT *'
              DISPLAY '*  SQLCODE         : ' SQLCODE
              DISPLAY '*****************************************'
              EXEC SQL ROLLBACK END-EXEC
              MOVE 12                          TO   RETURN-CODE
              GOBACK
           ELSE
              ADD 1 TO UPDATE-RT
           END-IF
           .
      *
      *-------------
       023-EX. EXIT.
      *-------------
      *
      *-----------------------
       024-INSERT-CM13-RS.
      *-----------------------
      *
           MOVE DE67-CDBAN0  TO DE13-CDBAN0
           MOVE DE67-TPDOC0  TO DE13-TPDOC0
           MOVE DE67-CDMDT0  TO DE13-CDMDT0
           MOVE DE67-TPSTA0  TO DE13-TPSTA0
           MOVE DE65-NRECP0  TO DE13-NRECP0
           MOVE DE65-NRECU0  TO DE13-NRECU0
      **   COMPUTE APPO-NRECU0 =
      *         DE65-NRECP0 + DE67-QTMDR0 - 1
      **        DE65-NRECP0 + DE67-QTEVA0 - 1
      **   MOVE APPO-NRECU0  TO DE13-NRECU0
      **   COMPUTE SAVE-NRECP0 =
      **           DE13-NRECU0 + 1
      *    MOVE DE67-QTMDR0  TO DE13-QTMDR0
      ***  MOVE DE67-QTEVA0  TO DE13-QTMDR0
           COMPUTE APPO-QTEVA0 =
                DE65-NRECU0 - DE65-NRECP0 + 1
           MOVE APPO-QTEVA0  TO DE13-QTMDR0
           MOVE DE67-CDRCH0  TO DE13-CDRCH0
           MOVE DE67-DTRCH0  TO DE13-DTRCH0
           MOVE DATA-SISTEMA TO DE13-XDTMSV
PV0315*                         DE13-XDTINV
PV0315     MOVE APPO-DATA-ELAB   TO DE13-XDTINV
           MOVE ORASYS-NUM   TO DE13-XHOMSV
      *
           EXEC SQL
              INSERT INTO CMRICTIP
              VALUES (:DE13-CDBAN0
                    , 'N'
                    , :DE67-TPDOC0
                    , :DE67-CDMDT0
                    , :DE67-TPSTA0
                    , :DE13-NRECP0
                    , :DE13-NRECU0
                    , :DE13-QTMDR0
                    , :DE67-CDRCH0
                    , :DE67-DTRCH0
                    , 'RS'
                    , 'BATC'
                    , 'CSBG10'
                    , :DE13-XDTMSV
                    , :DE13-XHOMSV
                    , :DE13-XDTINV)
           END-EXEC

           IF SQLCODE NOT = ZEROES
              DISPLAY '*****************************************'
              DISPLAY '*  ERRORE INSERT TABELLA CM13 STATO: RS *'
              DISPLAY '*  SQLCODE         : ' SQLCODE
              DISPLAY '*****************************************'
              EXEC SQL ROLLBACK END-EXEC
              MOVE 12                          TO   RETURN-CODE
              GOBACK
           ELSE
              ADD 1 TO INSERT-RS
           END-IF
           .
      *
      *-------------
       024-EX. EXIT.
      *-------------
      *
      *-----------------------
       025-AGGIO-CM67.
      *-----------------------
      *
           EXEC SQL
              UPDATE CMRICHIESTER
PV0315*          SET XDTINV       = :DATA-SISTEMA
PV0315           SET XDTINV       = :APPO-DATA-ELAB
                     WHERE CDBAN0 = :DE67-CDBAN0
                     AND   CDRCH0 = :DE67-CDRCH0
                     AND   DTRCH0 = :DE67-DTRCH0
           END-EXEC

           IF SQLCODE NOT = ZEROES
              DISPLAY '**************************************'
              DISPLAY '*  ERRORE AGGIORNAMENTO TABELLA CM67 *'
              DISPLAY '*  SQLCODE : ' SQLCODE
              DISPLAY '*  CDBAN0  : ' DE67-CDBAN0
              DISPLAY '*  CDRCH0  : ' DE67-CDRCH0
              DISPLAY '*  DTRCH0  : ' DE67-DTRCH0
              DISPLAY '**************************************'
              EXEC SQL ROLLBACK END-EXEC
              MOVE 12                          TO   RETURN-CODE
              GOBACK
           END-IF
           .
      *
      *-------------
       025-EX. EXIT.
      *-------------
      *
      *-----------------------
       026-SCRITTURA-OUT.
      *-----------------------
      *
      * PRIMA DI SCRIVERE IL FILE DI OUTPUT PREDISPORRE UNA CHIAMATA
      * AD UNA ROUTINE 'XXXXXX' PER PRELEVARE IL CODICE SICUREZZA
      *
           INITIALIZE REC-FILECOMU.

           MOVE '07601'        TO OUT-ABI
           MOVE 'AS'           TO OUT-TIPO-CARTA
           EVALUATE DE67-CDMDT0
              WHEN 'VO'
                 MOVE '05000'  TO OUT-CAB
              WHEN 'VCED'
                 MOVE '05199'  TO OUT-CAB
           END-EVALUATE
           MOVE DE67-CDMDT0    TO OUT-SOTTOTIPO
           MOVE DE67-TPSTA0    TO OUT-TIPO-STAMPA
           MOVE APPO-ECONOMALE TO OUT-NUM-ECON

      * QUANDO FUNZIONERA' LA ROUTINE METTERE CAMPO GIUSTO
      * PERFORM 027-RICEVI-CS  THRU 027-EX
           MOVE SPACE          TO OUT-COD-SICU

           WRITE REC-FILECOMU
           IF STATUS-FILECOMU   NOT = '00'
              DISPLAY '***************************************'
              DISPLAY '*  ERRORE SCRITTURA FILE SCARTI       *'
              DISPLAY '*  FILE-STATUS : ' STATUS-FILECOMU
              DISPLAY '***************************************'
              MOVE 12                   TO   RETURN-CODE
              GOBACK
           END-IF
           ADD 1 TO SCRITTI-OUT
           COMPUTE APPO-ECONOMALE = APPO-ECONOMALE + 1
           IF APPO-ECONOMALE > DE13-NRECU0
              MOVE 'NO' TO APPO-SCRITTURA.
      *
      *-------------
       026-EX. EXIT.
      *-------------
      *
      *-----------------------
      *027-RICEVI-CS.
      *-----------------------
      *
      *    MOVE OUT-ABI            TO ....
      *    MOVE OUT-CAB
      *    MOVE OUT-TIPO-CARTA
      *    MOVE OUT-SOTTOTIPO
      *    MOVE OUT-TIPO-STAMPA
      *    MOVE OUT-NUM-ECON
      *
      *    CALL 'NOME ROUTINE'
      *
      *    MOVE COD-SIC-DA-ROUTINE TO OUT-COD-SICU
      *
      *-------------
      *027-EX. EXIT.
      *-------------
      *
      *-------------
       030-OPER-FINALI.
      *-------------
      *
      *--- CHIUDO CURSORE

              EXEC SQL CLOSE SEL67  END-EXEC
              IF SQLCODE NOT = ZEROES
                 DISPLAY '************************************'
                 DISPLAY '*  ERRORE CHIUSURA CURSORE         *'
                 DISPLAY '*  SQLCODE     : ' SQLCODE
                 DISPLAY '************************************'
                 EXEC SQL ROLLBACK END-EXEC
                 MOVE 12                          TO   RETURN-CODE
                 GOBACK
              END-IF

      *--- CHIUDO FILE

           CLOSE FILECOMU.

           IF STATUS-FILECOMU   NOT = '00'
              DISPLAY '************************************'
              DISPLAY '*  ERRORE CHIUSURA FILE OUTPUT     *'
              DISPLAY '*  FILE-STATUS : ' STATUS-FILECOMU
              DISPLAY '************************************'
              MOVE 12                            TO   RETURN-CODE
              GOBACK
           END-IF

           DISPLAY '*********************************************'
           DISPLAY '* ELABORAZIONE TERMINATA CORRETTAMENTE     **'
           DISPLAY '*********************************************'
           DISPLAY '* NUMERO RICHIESTE ELABORATE       :' LETTI
           DISPLAY '* QTA CARTE RICHIESTE              :' TOT-CARTE-R
           DISPLAY '* QTA CARTE EVASE SU RICHIESTE     :' TOT-CARTE
           DISPLAY '* RECORD SCRITTI SU FILE RICHIESTE :' SCRITTI-OUT
           DISPLAY '* OCCORRENZE REGISTRATE SU CM13    :' INSERT-RS
      *    DISPLAY '* OCCORRENZE AGGIORMATE SU CM13    :' UPDATE-RT
           DISPLAY '*********************************************'

           STOP RUN.
      *
      *-------------
       030-EX. EXIT.
      *-------------
      *
