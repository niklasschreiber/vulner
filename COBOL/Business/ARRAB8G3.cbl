       IDENTIFICATION DIVISION.
      *_________________________________________________________________
       PROGRAM-ID.   ARRAB8G3.
       AUTHOR.
      *_________________________________________________________________
      *_   AGGIORNAMENTO TABELLA SCTBTMON (MONITORAGGIO)
      *-----------------------------------------------------------------
      *****************************************************************
       ENVIRONMENT DIVISION.
      *_________________________________________________________________
       CONFIGURATION SECTION.
      *_________________________________________________________________
          SPECIAL-NAMES.
              DECIMAL-POINT IS COMMA.
      *_________________________________________________________________
       INPUT-OUTPUT SECTION.
      *_________________________________________________________________
      *
       FILE-CONTROL.
      *
           SELECT  OUTREVOC ASSIGN   TO OUTREVOC
                 FILE  STATUS  IS  W-STAT01.
      *
       DATA DIVISION.
      *_________________________________________________________________
       FILE SECTION.
      *_________________________________________________________________
       FD  OUTREVOC
           LABEL RECORD STANDARD
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  REC-OUTREVOC        PIC X(289).
      *_________________________________________________________________
      *_________________________________________________________________
       WORKING-STORAGE SECTION.

       01 W-CTR-LETTI-DIS          PIC 9(09) VALUE 0.
       01 CTR-ESTINTI              PIC 9(09) VALUE 0.
       01 W-CTR-BILA               PIC 9(09) VALUE 0.
       01 W-CTR-LETTI-OUTREVOC   PIC 9(09) VALUE 0.
       01 WS-COUNT-UPD             PIC 9(09) VALUE 0.
       01 WS-PROGRAM               PIC X(008)  VALUE SPACE.

       01 DATA-INIZIO-VAL-RED      PIC 9(8).
       01 DATA-INIZIO-VAL REDEFINES DATA-INIZIO-VAL-RED.
          05 DATA-INIZIO-VAL-AAAA  PIC X(04).
          05 DATA-INIZIO-VAL-MM    PIC X(02).
          05 DATA-INIZIO-VAL-GG    PIC X(02).

       01 REC-DATA.
           02  ANNO                        PIC 9(4).
           02  MESE                        PIC 9(2).
           02  GIORNO                      PIC 9(2).
       01 RED-REC-DATA REDEFINES REC-DATA  PIC 9(08).

      *---------------------------------------------------------------* 00008800
      *      VARIABILI PER ACCEPT DELLA DATA DA SISTEMA               * 00008900
      *---------------------------------------------------------------* 00009000
       01  WS-TIMESTAMP              PIC X(26).                         00009100
       01  WS-TIMESTAMP-RED.                                            00009200
           05  DATA-SIST-AMG.                                           00009300
             10  ANNO-SIST           PIC X(04).                         00009400
             10  FILLER              PIC X(01).                         00009500
             10  MESE-SIST           PIC X(02).                         00009600
             10  FILLER              PIC X(01).                         00009700
             10  GIORNO-SIST         PIC X(02).                         00009800
           05  FILLER                PIC X(16).                         00009900
                                                                        00010000
       01  DATA-SISTEMA              PIC 9(8).                          00010100
       01  DATA-SITEMA-RED REDEFINES DATA-SISTEMA.                      00010200
           05  ANNO-SISTEMA          PIC X(04).                         00010300
           05  MESE-SISTEMA          PIC X(02).                         00010400
           05  GIORNO-SISTEMA        PIC X(02).                         00010500


      * VARIABILI DI APPOGGIO
        COPY DYNACALL.
      * COPY PER CHIAMATA CALCOLI GIORNI
           COPY XSADAT.
      *_________________________________________________________________
      *     CAMPI    DI   WORKING   PER    GESTIONE    ABEND
      *_________________________________________________________________
      *
       77  COMP-CODE                PIC S9(04) COMP VALUE +5555.
      *
       01  W-PROGRAM                PIC X(08)  VALUE SPACES.
      *_________________________________________________________________
      *     CAMPI    DI   WORKING   PER    GESTIONE    ANOMALIA
      *_________________________________________________________________
      *
       01  W-STAT01                 PIC X(02) VALUE SPACES.
       01  W-STAT02                 PIC X(02) VALUE SPACES.
       01  W-STAT03                 PIC X(02) VALUE SPACES.
       01  W-STAT04                 PIC X(02) VALUE SPACES.
       01  W-STAT05                 PIC X(02) VALUE SPACES.
       01  W-SQLCODE                PIC +++9.

      ***************************************************************** *
      *    SCHEDA PARAMETRO IMMISSIONE
      *
      *    IL RETCODE PUO  ASSUMERE I SEGUENTI VALORI :
      *       SP = LA DATA E' RECUPERATA DALLA SCHEDA PARAMETRO
      *       SI = LA DATA E' QUELLA DI SISTEMA
      ***************************************************************** *
       01  FILLER                   PIC X(16) VALUE '******SD01******'.
       01  SD01-01.
           COPY STDCSD01.
                                                                        *
       01  FILLER                   PIC X(16) VALUE '*****COMODI*****'.
       01  COMODI.
           03  TR-CALL              PIC X(8).
       01  FILLER                   PIC X(16) VALUE '***COMODI-ANOM**'.
       01  COMODI-ANOM.
           03  NOMEPGM              PIC X(8)  VALUE SPACES.
           03  DATASYS-AAAAMMGG.
             05  DATASYS-SEC        PIC 9(2)  VALUE ZERO.
             05  DATASYS-AAMMGG.
               07  DATASYS-AA       PIC 9(2)  VALUE ZERO.
               07  DATASYS-MM       PIC 9(2)  VALUE ZERO.
               07  DATASYS-GG       PIC 9(2)  VALUE ZERO.
           03  ORASYS.
             07  ORASYS-HH          PIC 9(2)  VALUE ZERO.
             07  ORASYS-MM          PIC 9(2)  VALUE ZERO.
             07  ORASYS-SS          PIC 9(2)  VALUE ZERO.

      *AREE PER MESSAGGI D'ERRORE
       01  MESS1         PIC X(22) VALUE 'ERRORE RISCONTRATO..: '.
       01  MESS2         PIC X(35) VALUE SPACES.
       01  MESS3         PIC X(10) VALUE SPACES.

      **************************************************************
      *    AREE PER ERRORE GENERICO
      **************************************************************
       01  DATI-ERR.
           03  DATI-ERR-MES1        PIC X(60)   VALUE SPACES.
           03  DATI-ERR-MES2        PIC X(60)   VALUE SPACES.
           03  DATI-ERR-DES1        PIC X(10)   VALUE SPACES.
           03  DATI-ERR-DES2        PIC X(10)   VALUE SPACES.
           03  DATI-ERR-FLAG        PIC X(01)   VALUE SPACES.

      ************************************************
      *    AREA PER ACCESSO ARCHIVIO STDS004
      ************************************************
       01  FILLER                PIC X(16) VALUE '**AREA-STDS004 *'.
       01  AREA-STDS004.
           03  SW-STDS004           PIC X(02) VALUE SPACES.
             88  SI-STDS004                   VALUE 'SI'.
             88  NF-STDS004                   VALUE 'NF'.
             88  DP-STDS004                   VALUE 'DP'.
             88  FF-STDS004                   VALUE 'FF'.
             88  NO-STDS004                   VALUE 'NO'.
             88  ER-STDS004                   VALUE 'ER'.
            03  STDS004-TRAC         PIC X(04).
            03  STDS004-FUNZ         PIC X(03).
            03  STDS004-IN           PIC X(00208).
            03  STDS004-OUT          PIC X(00208).
            03  STDS004-PGM          PIC X(08).
            03  STDS004-DATA         PIC X(08).
            03  STDS004-ORA          PIC X(06).
            03  STDS004-TIPOMOD      PIC X(01) VALUE 'A'.
            03  STDS004-RETCODE      PIC X(06).
            03  STDS004-FILLER       PIC X(71).
      ************************************************************      *
      **    ARCHIVIO STATISTICHE  PROGRAMMI BATCH
      ************************************************************      *
        01  FILLER                  PIC X(16) VALUE '*****STDS004****'.  *****
            COPY STDCS004.                                                   *

      *---------------------------------------------------------------* 00010600
      *      INCLUDE  TABELLE  DB2                                    * 00010700
      *---------------------------------------------------------------* 00010800
      *                                                                 00010900
           EXEC  SQL  INCLUDE  SQLCA     END-EXEC.                      00011000
           EXEC  SQL  INCLUDE  SCTBTMON  END-EXEC.                      00011100

       PROCEDURE DIVISION.

           PERFORM  00100-INIZIO             THRU  00100-EX.

           PERFORM  00200-ELABORA            THRU  00200-EX.

           PERFORM  00300-FINE               THRU  00300-EX.

       FINE-PROGRAMMA.
           STOP RUN.

      *****************************************************************
      * ROUTINE DI INIZIO PROGRAMMA COMPRENDENTE:                     *
      * APERTURA DEL DATASET                                          *
      *****************************************************************
       00100-INIZIO.

           PERFORM C0000-LEGGI-TIMESTAMP THRU  EX-C0000-LEGGI-TIMESTAMP.
           DISPLAY '-------------------------------------'.
           DISPLAY ' I N I Z I O  P G M   A R R A B 8 G 3'.
           DISPLAY '-------------------------------------'.
           DISPLAY 'DATA/ORA ELABORAZIONE:' WS-TIMESTAMP.

           PERFORM 00110-APERTURE THRU  00110-EX.


       00100-EX.
           EXIT.

      *****************************************************************
      *  ROUTINE DI APERTURA DEL DATASET                              *
      *****************************************************************
       00110-APERTURE.

           OPEN INPUT OUTREVOC.
           IF W-STAT01 NOT = '00'
              DISPLAY 'LABEL 00110-APERTURE'
              DISPLAY 'ERRORE ' W-STAT01 ' SU APERTURA OUTREVOC'
              PERFORM 9999-GEST-ABEND THRU 9999-EX.

       00110-EX.
           EXIT.

       00200-ELABORA.
      *****************************************************************
      *  ELABORAZIONE:                                                *
      *****************************************************************

           PERFORM 00281-LEGGI-OUTREVOC THRU 00281-EX.
           PERFORM UNTIL W-STAT01 = '10'
              PERFORM 00286-UPD-TMON        THRU 00286-EX
              PERFORM 00281-LEGGI-OUTREVOC  THRU 00281-EX
           END-PERFORM.

       00200-EX.
           EXIT.

       00281-LEGGI-OUTREVOC.
      *****************************************************************
      * LETTURA FILE DI INPUT OUTREVOC                                *
      *****************************************************************
           INITIALIZE TMON.

           READ  OUTREVOC INTO TMON.

           IF W-STAT01 NOT EQUAL '10' AND '00'
              DISPLAY 'ERRORE LETTURA FILE OUTREVOC:' W-STAT01
              DISPLAY '00281-LEGGI-OUTREVOC'
              PERFORM 9999-GEST-ABEND THRU 9999-EX.

           IF W-STAT01 =  '00'
             ADD 1 TO W-CTR-LETTI-OUTREVOC
                      W-CTR-LETTI-DIS

             IF W-CTR-LETTI-DIS = 10000
                DISPLAY 'LETTI FINORA OUTREVOC:' W-CTR-LETTI-OUTREVOC
                MOVE 0 TO W-CTR-LETTI-DIS
             END-IF
           END-IF.

           IF W-STAT01 = '10' AND W-CTR-LETTI-OUTREVOC = 0
              DISPLAY 'FILE OUTREVOC VUOTO'
           END-IF.

       00281-EX.
           EXIT.

       00286-UPD-TMON.

           EXEC SQL INCLUDE MON001UP END-EXEC.

           MOVE SQLCODE    TO W-SQLCODE.

           IF SQLCODE = 100
              DISPLAY 'LABEL 00286-UPD-TMON'
              DISPLAY 'OCCORRENZA NON TROVATA SU TABELLA TMON'
              DISPLAY 'FILIALE  :' TMON-FILIALE
              DISPLAY 'NUMERO   :' TMON-NUMERO
              DISPLAY 'CATEGORIA:' TMON-CATEGORIA
           END-IF.

           IF SQLCODE NOT EQUAL 0 AND 100
              DISPLAY 'LABEL 00286-UPD-TMON'
              DISPLAY 'ERRORE DB2 UPDATE SU TMON '     W-SQLCODE
              DISPLAY 'FILIALE  :' TMON-FILIALE
              DISPLAY 'NUMERO   :' TMON-NUMERO
              DISPLAY 'CATEGORIA:' TMON-CATEGORIA
              PERFORM 9999-GEST-ABEND THRU 9999-EX
           END-IF.

           IF SQLCODE = 0
              ADD 1 TO WS-COUNT-UPD
           END-IF.

       00286-EX.
           EXIT.
       00300-FINE.
      *****************************************************************
      * ROUTINE DI CHIUSURA DEL FILE DI OUTPUT                        *
      *****************************************************************

           PERFORM 00310-CHIUSURE     THRU 00310-EX.

           PERFORM 00320-STATISTICHE  THRU 00320-EX.

       00300-EX.
           EXIT.

       00310-CHIUSURE.
      *****************************************************************
      * CHIUSURE DEI FILE                                             *
      *****************************************************************

           CLOSE OUTREVOC.
           IF W-STAT01 NOT = '00' AND '10'
              DISPLAY 'LABEL 00310-CHIUSURE'
              DISPLAY 'ERRORE ' W-STAT01 ' SU CHIUSURA OUTREVOC'
              PERFORM 9999-GEST-ABEND THRU 9999-EX.


       00310-EX.
           EXIT.

       00320-STATISTICHE.
      *****************************************************************
      * ROUTINE DI VISUALIZZAZIONE DEI RISULTATI DEL PGM              *
      *****************************************************************
              DISPLAY '*-----------------------------------------*'.
              DISPLAY '*       F I N E       P R O G R A M M A   *'.
              DISPLAY '*-----------------------------------------*'.
              DISPLAY '*          A R R A B 8 G 3                *'.
              DISPLAY '*-----------------------------------------*'.
              DISPLAY '*  STATISTICHE NUMERO DI RECORD TRATTATI  *'.
              DISPLAY '*-----------------------------------------*'.
              DISPLAY '*TOT. REC.LETTI IN OUTREVOC                 :'
                      W-CTR-LETTI-OUTREVOC.
              DISPLAY '*TOT. REC. AGGIORNATI IN TMON               :'
                      WS-COUNT-UPD.
       00320-EX.
             EXIT.

      ***************************************************************** 00036800
      * ROUTINE DI REPERIMENTO DEL TIMESTAMP                          * 00036900
      ***************************************************************** 00037000
       C0000-LEGGI-TIMESTAMP.                                           00037100
           EXEC SQL                                                     00037200
                SET :WS-TIMESTAMP = CURRENT TIMESTAMP                   00037300
           END-EXEC.                                                    00037400

           MOVE SQLCODE TO W-SQLCODE.
                                                                        00037500
           IF SQLCODE NOT = ZERO                                        00037600
              DISPLAY 'LABEL C0000-TIMESTAMP'                           00037700
              DISPLAY 'ERRORE ' W-SQLCODE                               00037800
                      ' SU TIMESTAMP'                                   00037900
              PERFORM 9999-GEST-ABEND THRU 9999-EX
           END-IF.                                                      00038100
                                                                        00038200
           MOVE WS-TIMESTAMP                TO WS-TIMESTAMP-RED.        00038300
                                                                        00038400
           MOVE ANNO-SIST                   TO ANNO-SISTEMA.            00038500
                                                                        00038600
           MOVE MESE-SIST                   TO MESE-SISTEMA.            00038700
                                                                        00038800
           MOVE GIORNO-SIST                 TO GIORNO-SISTEMA.          00038900
                                                                        00039000
      *    DISPLAY 'DATA-SISTEMA:' DATA-SISTEMA.                        00039100
                                                                        00039200
       EX-C0000-LEGGI-TIMESTAMP.                                        00039300
           EXIT.                                                        00039400

       9999-GEST-ABEND.

           MOVE 'ILBOABN0' TO WS-PROGRAM.

           CALL WS-PROGRAM USING COMP-CODE.

       9999-EX.
           EXIT.
