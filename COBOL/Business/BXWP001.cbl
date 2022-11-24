************************************************************************
*********              SAVING ALLOCATOR                        *********
*********   I N Q U I R Y  RECUPERO CONFIGURAZIONE             *********
************************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.     BXWP001.
       AUTHOR.         ALMAVIVA.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

      ******************************************************************
      *** AREA INPUT
      ******************************************************************
       01  BXWCI001-AREA.
           COPY BXWI0101.
      ******************************************************************
      *** AREA OUTPUT
      ******************************************************************
       01  BXWCO001-AREA.
           COPY BXWO0101.

      ******************************************************************
      *** COPY PER REPERIMENTO MESSAGGI DI ERRORE
      ******************************************************************
       01 L-MADAREA.
           COPY BFCLMMAD.
           COPY BFCLMMSG.
           COPY BFCWMMAD.
           COPY BFCWMMSG.
           COPY BFCWSMSG.

      ******************************************************************
      *** COPY PER CONTROLLO DATA
      ******************************************************************
           COPY  XSADAT.
       01 XSXDAT                         PIC  X(08) VALUE 'XSXDAT  '.
       01 BFDMSG                         PIC X(06)  VALUE 'BFDMSG'.
      *
       01 W-NOME-ROUTINE                 PIC  X(08) VALUE SPACES.
      *
      ******************************************************************
       01 BFGTI1                         PIC  X(08) VALUE 'BFGTI1'.
       01 W-AREA-LTI1.
           COPY  BFCLSTI1.
      ******************************************************************
       01 WS-RESP                        PIC S9(08) COMP.
       01 WS-ERRORE                      PIC X(01).
          88 NO-ERRORE                       VALUE SPACES .
          88 SI-ERRORE                       VALUE 'S'.
          88 SI-WARNING                      VALUE 'W'.

       01 WS-PROFILO.
          03 COMMA-TERMINALE             PIC X(4).
          03 COMMA-USERID                PIC X(8).
          03 COMMA-PROFILO               PIC X(8).
          03 COMMA-DIP                   PIC X(5).

       01 MSG-OUT.
          03 CODICE-ERRORE               PIC X(04).
          03 MESSAGGIO                   PIC X(73).
          03 FUNZIONE                    PIC X(03).

      ******************************************************************
      *    AREE DI COMODO PER DATE
      ******************************************************************
       01  W-EIB-TEMPO                   PIC 9(018)  COMP-3.
       01  APPO-TEMPO.
           05  W-EIB-DATA.
               10  W-EIB-ANNO            PIC 9(004).
               10  W-EIB-MESE            PIC 9(002).
               10  W-EIB-GG              PIC 9(002).
           05  W-EIB-DATA-R REDEFINES W-EIB-DATA PIC 9(08).
           05  FILLER                    PIC X(007).
           05  W-EIB-ORA                 PIC X(006).

       01  ORA-EIBTIME                   PIC 9(7).
       01  ORA-DIVISA REDEFINES ORA-EIBTIME.
           05 FILLER                     PIC X.
           05 HHMMSS                     PIC X(6).

       01  W-DATA-VER.
           05  W-ANNO-VER                PIC 9(04).                     04806100
           05  W-MESE-VER                PIC 9(02).                     04806000
           05  W-GIORNO-VER              PIC 9(02).                     04805400
       01  W-DATA-VER-SEGNO REDEFINES W-DATA-VER PIC S9(08).
      *****************************************************************
       01 W-DATA-DB2                    PIC X(10).

       01 COM-DATA-EMISS.
          05 COM-AAAA-E                PIC  9(0004).
          05 COM-MM-E                  PIC  9(0002).
          05 COM-GG-E                  PIC  9(0002).
       01 COM-DATA-EMISS-R REDEFINES COM-DATA-EMISS PIC 9(0008).

       01 COM-DATA-RIMB.
          05 COM-AAAA-R                PIC  9(0004).
          05 COM-MM-R                  PIC  9(0002).
          05 COM-GG-R                  PIC  9(0002).
       01 COM-DATA-RIMB-R REDEFINES COM-DATA-RIMB PIC 9(0008).

       01 COM-DATA-NASC.
          05 COM-AAAA-N                PIC  9(0004).
          05 COM-MM-N                  PIC  9(0002).
          05 COM-GG-N                  PIC  9(0002).
       01 COM-DATA-NASC-R REDEFINES COM-DATA-NASC PIC 9(0008).

       01 COM-DATA-SCAD.
          10 COM-AAAA-S                PIC  9(0004).
          10 COM-MM-S                  PIC  9(0002).
          10 COM-GG-S                  PIC  9(0002).
       01 COM-DATA-SCAD-R REDEFINES COM-DATA-SCAD PIC 9(0008).

       01 COM-DATA-PRES.
          10 COM-AAAA-P                PIC  9(0004).
          10 COM-MM-P                  PIC  9(0002).
          10 COM-GG-P                  PIC  9(0002).
       01 COM-DATA-PRES-R REDEFINES COM-DATA-PRES PIC 9(0008).

       01 COM-DATA-ULTR.
          10 COM-AAAA-UL               PIC  9(0004).
          10 COM-MM-UL                 PIC  9(0002).
          10 COM-GG-UL                 PIC  9(0002).
       01 COM-DATA-ULTR-R REDEFINES COM-DATA-ULTR PIC 9(0008).

       01  DATA-RIF                 PIC X(10) VALUE '2005-09-05'.       5-09-05'
       01  DATA-RIF-DAL             PIC X(10) VALUE '2003-10-04'.       3-10-04'
       01  DATA-RIF-AL              PIC X(10) VALUE '2007-11-01'.       7-11-01'

       01 CAMPI-COMODO.
           05  WS-DATA-8.                                               00146000
               10  WS-DATA-AA            PIC 9(4).                      00146100
               10  WS-DATA-MM            PIC 9(2).                      00146200
               10  WS-DATA-GG            PIC 9(2).                      00146300
           05  WS-DT-EMISSIONE.                                         00146000
               10  WS-DT-AA            PIC 9(4).                        00146100
               10  WS-DT-MM            PIC 9(2).                        00146200
               10  WS-DT-GG            PIC 9(2).                        00146300
           05  DATA-AAAA-MM-GG.                                         00146400
               10  WS-AA                 PIC 9(4).                      00146600
               10  FILLER                PIC X(1) VALUE '-'.            00146700
               10  WS-MM                 PIC 9(2).                      00146800
               10  FILLER                PIC X(1) VALUE '-'.            00146900
               10  WS-GG                 PIC 9(2).                      00147000
           05  W-CODICE.                                                00147200
               10  W-SQL                 PIC X(4).                      00147300
               10  W-RET-COD             PIC X(2).                      00147400

       01 W-POS-ERR                      PIC 9(02).
       01 W-SERIE-OUT                    PIC X(12).
       01 W-FASCIA                       PIC 9(01).
       01 W-DOPPIA-FASCIA                PIC X(02).
       01 W-IMPOSTA-PREM                 PIC X(02).
       01 W-PRESCRITTO                   PIC X(02).
       01 W-CEDOLE                       PIC X(02).
       01 W-ELABORA                      PIC X(02).
       01 W-TAGLIO-CNTRV                 PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-NETTO                   PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-IMP-LORDO               PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-IMP-NETTO               PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-IMP-RIT-FIS             PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-IMP-IMPOSTE             PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-IMP-NETTO-PREM          PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-LORDO-PREM              PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-RIT-PREM                PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-IMP-CED-REST            PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-IMP-RESIDUO             PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-NETTO-EUR               PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-LORDO-EUR               PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-RIT-EUR                 PIC 9(15)V9(3) VALUE ZERO.
       01 W-APPO-IMP-OPER                PIC S9(15)V9(03).
       01 WS-IMPORTO                     PIC S9(15)V9(03).
       01 W-APPO-TAGLIO-EUR              PIC 9(15)V9(3) VALUE ZERO.
       01 WS-TOT-CEDOLE                  PIC S9(15)V9(03) COMP-3.

       01 WS-APPO-SQLCODE                PIC S9(09).
      *
      *--- AREE PER ERRORE GENERICO
       01  DATI-ERR.
           05  DATI-ERR-PGM              PIC X(008)  VALUE SPACE.
           05  DATI-ERR-ABEND            PIC X(004)  VALUE SPACE.
           05  DATI-ERR-TIPOTERM         PIC X(001)  VALUE SPACE.
           05  DATI-ERR-EIB              PIC X(100)  VALUE SPACE.
           05  DATI-ERR-MES1             PIC X(060)  VALUE SPACE.
           05  DATI-ERR-MES2             PIC X(060)  VALUE SPACE.
           05  DATI-ERR-DES1             PIC X(010)  VALUE SPACE.
           05  DATI-ERR-DES2             PIC X(010)  VALUE SPACE.
           05  FILLER                    PIC X(047)  VALUE SPACE.

      *------------------------------------------------------*
      *---     MODULI RICHIAMATI                          ---*
      *------------------------------------------------------*
      ******************************************************************
      *        AREA PER TABELLE DB2
      ******************************************************************

           EXEC SQL INCLUDE SQLCA   END-EXEC.
           EXEC SQL INCLUDE BX$TEMP END-EXEC.
           EXEC SQL INCLUDE BX$MATR END-EXEC.
      *
      *********************************************************
      * DECLARE PER LETTURA TABELLA TEMPO
      *********************************************************
            EXEC SQL DECLARE CUR-TEMP CURSOR FOR
                 SELECT TEMP_COD_TEMPO
                       ,TEMP_DESCRIZ
                       ,TEMP_DESCR_COMM
                   FROM BXTEMP
                  WHERE :W-DATA-DB2
                        BETWEEN TEMP_DT_INI_VAL AND
                                TEMP_DT_FINE_VAL
                  WITH UR
            END-EXEC.

      *********************************************************
      * DECLARE PER LETTURA TABELLA MATRICE
      *********************************************************
            EXEC SQL DECLARE CUR-MATR CURSOR FOR
                 SELECT MATR_COD_PROD
                       ,MATR_VINC_COND
                       ,MATR_DURATA
                   FROM BXMATR
                  WHERE :W-DATA-DB2
                        BETWEEN MATR_DT_INI_VAL AND
                                MATR_DT_FINE_VAL
                  GROUP BY MATR_COD_PROD, MATR_VINC_COND,
                           MATR_DURATA
                  ORDER BY MATR_DURATA
                  WITH UR
            END-EXEC.
      *
      *
       01 WS-TIME-DB2                   PIC X(10).
      *-----------------------------------------------------------------
       LINKAGE SECTION.
      *-----------------------------------------------------------------
       01  DFHCOMMAREA                  PIC X(2984).

      *-----------------------------------------------------------------
       PROCEDURE DIVISION.
      *-----------------------------------------------------------------

           EXEC CICS HANDLE   ABEND
                              LABEL     (ERRORE-GENER)
                              END-EXEC.

       PROGRAM-INIZIO.

      *    DISPLAY 'INIZIO BXWP001'
           PERFORM OPERAZ-INIZIALI   THRU OPERAZ-INIZIALI-EX

           PERFORM CONTROLLI-INPUT   THRU CONTROLLI-INPUT-EX

           PERFORM IMPOSTA-OUT        THRU IMPOSTA-OUT-EX.

           PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX.

      *-----------------
       OPERAZ-INIZIALI.
      *-----------------
      *    DISPLAY 'BXWP001 OPERAZ-INIZIALI'

           MOVE DFHCOMMAREA         TO ci001-area-input.
           SET NO-ERRORE            TO TRUE

           MOVE 'OK' TO cO001-cod-rit

           EXEC SQL
                SET :WS-TIME-DB2 = CURRENT TIME
           END-EXEC.

      *-----------------
       OPERAZ-INIZIALI-EX.
      *-----------------
           EXIT.

      *-----------------
       CONTROLLI-INPUT.
      *-----------------
      *    DISPLAY 'BXWP001 CONTROLLI-INPUT'
      *--- DATA OPERAZOINE
           IF ci001-data-oper EQUAL SPACES
                              OR ZEROES
                              OR LOW-VALUE
                              OR HIGH-VALUE
              SET SI-ERRORE    TO   TRUE
              MOVE   'E54'               TO   W-1MSG-COD-DIAGN
              PERFORM MESSAGGIO-ERRORE   THRU MESSAGGIO-ERRORE-EX
              STRING 'W02 ' WMSG-DESC-ESTESA  DELIMITED BY SIZE
                      INTO MSG-OUT            END-STRING
              PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
           END-IF.

           PERFORM CONTROLLO-DATA THRU CONTROLLO-DATA-EX.

       CONTROLLI-INPUT-EX.
           EXIT.

      *---> CONTROLLO DATA OPERAZIONE

       CONTROLLO-DATA.                                                  01343100
                                                                        01343901
      *    DISPLAY 'BXWP001 CONTROLLO-DATA'
      *    DISPLAY 'BXWP001 ci001-data-oper : ' ci001-data-oper
           INITIALIZE                         UTDATA-PARAM.
           MOVE 9                        TO   UTDATA-FUNZIONE.
           MOVE 0                        TO   UTDATA-FUNZIONE-2.
           MOVE ci001-data-oper(1:4)     TO   W-ANNO-VER.
           MOVE ci001-data-oper(6:2)     TO   W-MESE-VER.
           MOVE ci001-data-oper(9:2)     TO   W-GIORNO-VER.
      *    DISPLAY 'BXWP001 W-DATA-VER : ' W-DATA-VER
           MOVE W-DATA-VER               TO   UTDATA-DATA-1.

           EXEC CICS LINK PROGRAM  (XSXDAT)
                          COMMAREA (UTDATA-PARAM)
                          RESP     (WS-RESP)
           END-EXEC.

           IF WS-RESP NOT EQUAL DFHRESP(NORMAL)
              SET SI-ERRORE TO TRUE
              STRING 'S36 ' 'ERRORE ROUTINE XSXDAT' DELIMITED BY SIZE
                               INTO MSG-OUT END-STRING
              MOVE   0        TO co001-num-descr
                                 co001-tab-descr2-num
              MOVE   0        TO co001-num-prod
                                 co001-tab-prod2-num
              PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX.

           IF UTDATA-ERRORE NOT = ZERO
              SET SI-ERRORE TO TRUE
              STRING 'S37 ' 'ERRORE ROUTINE XSXDAT' DELIMITED BY SIZE
                               INTO MSG-OUT  END-STRING
              MOVE   0        TO co001-num-descr
                                 co001-tab-descr2-num
              MOVE   0        TO co001-num-prod
                                 co001-tab-prod2-num
              PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX.

       CONTROLLO-DATA-EX.
           EXIT.
      *
      *-------------------
       IMPOSTA-OUT.
      *-------------------
      *    DISPLAY 'BXWP001 IMPOSTA-OUT'
           PERFORM VALORIZZA-TEMPO    THRU VALORIZZA-TEMPO-EX
           PERFORM VALORIZZA-PRODOTTI THRU VALORIZZA-PRODOTTI-EX.
      *----
       IMPOSTA-OUT-EX.
           EXIT.
      *----
       VALORIZZA-TEMPO.
           PERFORM LEGGI-BXTEMP THRU LEGGI-BXTEMP-EX.
       VALORIZZA-TEMPO-EX.
           EXIT.
      *----
       VALORIZZA-PRODOTTI.
           PERFORM LEGGI-BXMATR THRU LEGGI-BXMATR-EX.
       VALORIZZA-PRODOTTI-EX.
           EXIT.
      *----
      *-------------------
       LEGGI-BXTEMP.
      *-------------------

      *    DISPLAY 'BXWP001 LEGGI-BXTEMP'
           PERFORM OPEN-CUR-TEMP
              THRU OPEN-CUR-TEMP-EX.

           PERFORM FETCH-CUR-TEMP
              THRU FETCH-CUR-TEMP-EX
             UNTIL SQLCODE = +100

           PERFORM CLOSE-CUR-TEMP
              THRU CLOSE-CUR-TEMP-EX.

      *-------------------
       LEGGI-BXTEMP-EX.
      *-------------------
           EXIT.
      *-------------------
       OPEN-CUR-TEMP.
      *-------------------
      *    DISPLAY 'BXWP001 OPEN-CUR-TEMP'
           MOVE  ci001-data-oper  TO W-DATA-DB2
           EXEC SQL
              OPEN CUR-TEMP
           END-EXEC.
      *
           MOVE SQLCODE         TO WS-APPO-SQLCODE
      *    DISPLAY 'BXWP001 OPEN-CUR-TEMP SQLCODE: ' WS-APPO-SQLCODE
           EVALUATE SQLCODE
               WHEN 0
                    CONTINUE
               WHEN +100
                    PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
               WHEN OTHER
                    SET SI-ERRORE TO TRUE
                    STRING 'E03 ' 'ERR.OPEN CUR-TEMP: SQLCODE '
                            WS-APPO-SQLCODE
                            DELIMITED BY SIZE INTO MSG-OUT
                    PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
           END-EVALUATE.
      *
       OPEN-CUR-TEMP-EX.
      *-------------------
           EXIT.
      *-------------------
       FETCH-CUR-TEMP.
      *
      *    DISPLAY 'BXWP001 FETCH-CUR-TEMP'
           EXEC SQL
              FETCH CUR-TEMP
               INTO :TEMP-COD-TEMPO
                   ,:TEMP-DESCRIZ
                   ,:TEMP-DESCR-COMM
           END-EXEC.
      *
           MOVE SQLCODE     TO WS-APPO-SQLCODE
      *    DISPLAY 'BXWP001 FETCH-CUR-TEMP SQLCODE: ' WS-APPO-SQLCODE
           EVALUATE SQLCODE
               WHEN 0
                    ADD    1        TO co001-num-descr
                                       co001-tab-descr2-num
                    MOVE TEMP-DESCR-COMM
                                    TO co001-descr-comm(co001-num-descr)
                    MOVE TEMP-DESCRIZ
                                    TO co001-descr(co001-num-descr)
                    MOVE TEMP-COD-TEMPO
                                    TO co001-cod-tempo(co001-num-descr)
                    MOVE 0
                                    TO co001-cod-imp(co001-num-descr)
               WHEN +100
                    IF co001-num-descr > 0
                       CONTINUE
                    ELSE
                       MOVE 0       TO co001-num-descr
                                       co001-tab-descr2-num
                       MOVE 0       TO co001-num-prod
                                       co001-tab-prod2-num
                       SET SI-ERRORE TO TRUE
                       STRING 'E03 ' 'ERR.FETCH CUR-TEMP: SQLCODE '
                               WS-APPO-SQLCODE ' NESSUN DATO'
                               DELIMITED BY SIZE INTO MSG-OUT
                       PERFORM FINE-PROGRAMMA  THRU FINE-PROGRAMMA-EX
                    END-IF
               WHEN OTHER
                    SET SI-ERRORE TO TRUE
                    STRING 'E03 ' 'ERR.FETCH CUR-TEMP: SQLCODE '
                            WS-APPO-SQLCODE
                            DELIMITED BY SIZE INTO MSG-OUT
                    PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
           END-EVALUATE.

       FETCH-CUR-TEMP-EX.
      *-------------------
           EXIT.
      *----------------------
       CLOSE-CUR-TEMP.
      *----------------------
      *    DISPLAY 'BXWP001 CLOSE-CUR-TEMP'
           EXEC SQL
              CLOSE CUR-TEMP
           END-EXEC.
      *
           MOVE SQLCODE         TO WS-APPO-SQLCODE
      *    DISPLAY 'BXWP001 CLOSE-CUR-TEMP SQLCODE: ' WS-APPO-SQLCODE
           EVALUATE SQLCODE
               WHEN 0
                    CONTINUE
               WHEN OTHER
                    SET SI-ERRORE TO TRUE
                    STRING 'E03 ' 'ERR.CLOSE CUR-TEMP: SQLCODE '
                           WS-APPO-SQLCODE
                           DELIMITED BY SIZE INTO MSG-OUT
                    PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
           END-EVALUATE.
      *----------------------
       CLOSE-CUR-TEMP-EX.
      *----------------------
           EXIT.
      *-------------------
       LEGGI-BXMATR.
      *-------------------
      *    DISPLAY 'BXWP001 LEGGI-BXMATR'

           PERFORM OPEN-CUR-MATR
              THRU OPEN-CUR-MATR-EX.

           PERFORM FETCH-CUR-MATR
              THRU FETCH-CUR-MATR-EX
             UNTIL SQLCODE = +100

           PERFORM CLOSE-CUR-MATR
              THRU CLOSE-CUR-MATR-EX.

      *-------------------
       LEGGI-BXMATR-EX.
      *-------------------
           EXIT.
      *-------------------
       OPEN-CUR-MATR.
      *    DISPLAY 'BXWP001 OPEN-CUR-MATR'
      *-------------------
           MOVE  ci001-data-oper  TO W-DATA-DB2
           EXEC SQL
              OPEN CUR-MATR
           END-EXEC.
      *
           MOVE SQLCODE         TO WS-APPO-SQLCODE
      *    DISPLAY 'BXWP001 OPEN-CUR-MATR  SQLCODE: ' WS-APPO-SQLCODE
           EVALUATE SQLCODE
               WHEN 0
                    CONTINUE
               WHEN +100
                    MOVE   0        TO co001-num-prod
                                       co001-tab-prod2-num
                    PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
               WHEN OTHER
                    SET SI-ERRORE TO TRUE
                    STRING 'E03 ' 'ERR.OPEN CUR-MATR: SQLCODE '
                            WS-APPO-SQLCODE
                            DELIMITED BY SIZE INTO MSG-OUT
                    PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
           END-EVALUATE.
      *
       OPEN-CUR-MATR-EX.
      *-------------------
           EXIT.
      *-------------------
       FETCH-CUR-MATR.
      *    DISPLAY 'BXWP001 FETCH-CUR-MATR'
      *
           EXEC SQL
              FETCH CUR-MATR
               INTO :MATR-COD-PROD
                   ,:MATR-VINC-COND
                   ,:MATR-DURATA
           END-EXEC.
      *
           MOVE SQLCODE         TO WS-APPO-SQLCODE
      *    DISPLAY 'BXWP001 FETCH-CUR-MATR SQLCODE: ' WS-APPO-SQLCODE
           EVALUATE SQLCODE
               WHEN 0
                   ADD    1            TO co001-num-prod
                                          co001-tab-prod2-num
                   MOVE MATR-COD-PROD  TO co001-cod-prod(co001-num-prod)
                   MOVE MATR-VINC-COND TO co001-cod-vinc(co001-num-prod)
               WHEN +100
                    IF co001-num-prod > 0
                       CONTINUE
                    ELSE
                       MOVE 0       TO co001-num-prod
                                       co001-tab-prod2-num
                       SET SI-ERRORE TO TRUE
                       STRING 'E03 ' 'ERR.FETCH CUR-MATR: SQLCODE '
                               WS-APPO-SQLCODE ' NESSUN DATO'
                               DELIMITED BY SIZE INTO MSG-OUT
                       PERFORM FINE-PROGRAMMA  THRU FINE-PROGRAMMA-EX
                    END-IF
               WHEN OTHER
                    SET SI-ERRORE TO TRUE
                    STRING 'E03 ' 'ERR.FETCH CUR-MATR: SQLCODE '
                            WS-APPO-SQLCODE
                            DELIMITED BY SIZE INTO MSG-OUT
                    PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
           END-EVALUATE.

       FETCH-CUR-MATR-EX.
      *-------------------
           EXIT.
      *----------------------
       CLOSE-CUR-MATR.
      *----------------------
      *    DISPLAY 'BXWP001 CLOSE-CUR-MATR'
           EXEC SQL
              CLOSE CUR-MATR
           END-EXEC.
      *
           MOVE SQLCODE         TO WS-APPO-SQLCODE
      *    DISPLAY 'BXWP001 CLOSE-CUR-MATR SQLCODE: ' WS-APPO-SQLCODE
           EVALUATE SQLCODE
               WHEN 0
                    CONTINUE
               WHEN OTHER
                    SET SI-ERRORE TO TRUE
                    STRING 'E03 ' 'ERR.CLOSE CUR-MATR: SQLCODE '
                           WS-APPO-SQLCODE
                           DELIMITED BY SIZE INTO MSG-OUT
                    PERFORM FINE-PROGRAMMA     THRU FINE-PROGRAMMA-EX
           END-EVALUATE.
      *----------------------
       CLOSE-CUR-MATR-EX.
      *----------------------
           EXIT.
********************************************************************

      *-----------------------------------------------------------------

       RICAVA-EIBDATE.                                                  05240000
      *    DISPLAY 'BXWP001 RICAVA-EIBDATE'

           EXEC CICS ASKTIME    ABSTIME  (W-EIB-TEMPO) END-EXEC.

           EXEC CICS FORMATTIME ABSTIME  (W-EIB-TEMPO)
                                YYYYMMDD (W-EIB-DATA)
                                TIME     (W-EIB-ORA)   END-EXEC.

       RICAVA-EIBDATE-EX.                                               05500000
           EXIT.                                                        05510000

      *
      *--> CHIAMATA WS-ESA ROUTINE X LA GESTIONE DELL'ERRORE

       MESSAGGIO-ERRORE.
      *    DISPLAY 'BXWP001 MESSAGGIO-ERRORE'

           MOVE ZERO                     TO   L-MADIN-CODICE
                                              L-MADIN-FUNZIONE
                                              L-MADIN-NOME-ENTITA
                                              L-MADIN-NUM-SEL
                                              L-MADOUT-RET-CODE.
           MOVE SPACES                   TO   L-MADIN-ORDINAMENTO
                                              L-MADIN-SELEZIONE
                                              L-ENTITA
                                              L-MADOUT-NOME-MAD
                                              L-MADOUT-DEBUG.
           MOVE SPACES                   TO   L-MADCOMODO.

           MOVE '&&'                     TO   L-MADCOMODO1.

           MOVE W-BFDMSG                 TO   L-MADIN-CODICE.
           MOVE W-RICERCA                TO   L-MADIN-FUNZIONE.
           MOVE W-MSG                    TO   L-MADIN-NOME-ENTITA.
           MOVE W-1MSG-COD-DIAGN         TO   L-1MSG-COD-DIAGN.

           CALL BFDMSG                        USING L-MADAREA.

           IF L-MADOUT-RET-CODE = ZEROES
              STRING L-1MSG-COD-DIAGN ' - ' LMSG-DESC-DIAGN
              DELIMITED BY SIZE        INTO   WMSG-DESC-DIAGN
           ELSE
              SET SI-ERRORE   TO   TRUE
              IF L-MADOUT-RET-CODE = 11
                 STRING 'CODICE NON TROVATO IN TAB.ERRORI: '
                       L-1MSG-COD-DIAGN DELIMITED BY SIZE
                                     INTO WMSG-DESC-DIAGN
              ELSE
                  MOVE 'ERRORE GRAVE DB. TAB.ERRORI'
                                       TO WMSG-DESC-DIAGN
              END-IF
           END-IF.
       MESSAGGIO-ERRORE-EX.
           EXIT.

      *-----------------------------------------------------------------
       FINE-PROGRAMMA.
      *-----------------------------------------------------------------
      *    DISPLAY 'BXWP001 FINE-PROGRAMMA'
           EVALUATE  TRUE
              WHEN NO-ERRORE
                   MOVE 'OK'                TO co001-cod-rit
                   MOVE spaces              TO co001-descerr
                   MOVE spaces              TO co001-moduerr
              WHEN SI-ERRORE
                   MOVE 'KO'                TO co001-cod-rit
                   MOVE MSG-OUT             TO co001-descerr
                   MOVE 'BXWP001'           TO cO001-moduerr
              WHEN SI-WARNING
                   MOVE 'KO'                TO co001-cod-rit
                   MOVE MSG-OUT             TO co001-descerr
                   MOVE 'BXWP001'           TO cO001-moduerr
           END-EVALUATE.

           MOVE cO001-area-output        TO DFHCOMMAREA.

           PERFORM USCITA                THRU USCITA-EX.

       FINE-PROGRAMMA-EX.
           EXIT.

      *--> ERRORE GENERICO CICS

       ERRORE-GENER.
      *    DISPLAY 'BXWP001 ERRORE-GENER'

           MOVE  DFHEIBLK                TO   DATI-ERR-EIB.
           MOVE 'BXWP001'                TO   DATI-ERR-PGM.

           EXEC CICS ASSIGN ABCODE (DATI-ERR-ABEND)
           END-EXEC.
           EXEC CICS HANDLE ABEND CANCEL
           END-EXEC.
           EXEC CICS HANDLE CONDITION ERROR
           END-EXEC.

           STRING '999 ERRORE SOTTOSISTEMA SA: '  DATI-ERR-ABEND
           DELIMITED BY SIZE          INTO  co001-descerr

           MOVE  cO001-area-output       TO   DFHCOMMAREA.

           PERFORM USCITA                THRU USCITA-EX.

       ERRORE-GENER-EX.
           EXIT.

      *--> USCITA TRANSAZIONE

       USCITA.
      *    DISPLAY 'BXWP001 USCITA'
           EXEC CICS RETURN END-EXEC.
       USCITA-EX.
           EXIT.
