       IDENTIFICATION DIVISION.
      ******************************************************************
      *                      **- DCBT310M -**                         **
      ******************************************************************
      ** CREATORE   : SEMAGROUP ITALIA                                **
      ** DATA       : 29/04/2003                                      **
      ******************************************************************
      ** SERVIZIO   : PO                                              **
      ** TIPO       : BATCH                                           **
      ** LINK DA    : -------                                         **
      ** TRANSID    : -------                                         **
      ** MAPPA      : -------                                         **
      ** DB2        : SI                                              **
      ******************************************************************
      ** SCOPO      : IL PROGRAMMA LEGGE I FLUSSI RICEVUTI DAI VARI   **
      **              SERVIZI E PROVVEDE A CONTROLLARE LA LORO VALIDI-**
      **              TA.                                             **
      **              TAGLIATORE DI TESTE                             **
      ******************************************************************
      ** FILE E TABELLE UTILIZZATE:                                   **
      ** NOME     TIPO ACC DESCRIZIONE                                **
      **          SEQ                                                 **
      ******************************************************************
      ** DATA         MODIFICA                                 ACRON  **
LF0205** 24022005     CAMBIATO TRACCIATO DI INPUT DCCYB010 - DCCYB01M **
LF0205** 24022005     AGGIUNTO CARICAMENTO DIVISE IN WORKING DCTBDIVA **
LF0205** 24022005     CONTROLLATA DIVISA E IMPORTO ORIGINARIO         **
LF0205** 24022005     IL PROGRAMMA E' DIVENTATO DB2.                  **
FORZA ** 03022006     INSERITA FORZATURE PER ELIMINARE GLI UFFICI     **
FORZA **              VALORIZZATI PER SIC ACCENTRATI                  **
AP0206** 06022006     SI DISTINGUONO I COCONT IN "ORDINARI" E         **
AP0206**              "REPLICA" PER SUCCESSIVA STAMPA DI SINTESI      **
      ******************************************************************
RL0101**06062006      REPLICA COCONT:                                 **
RL0101**              MODIFICATA LUNGHEZZA FLUSSO DI INPUT E OUTPUT   **
RL0101**              MEMORIZZARE LA CHIAVE ORIGINARIA NE             **
RL0101**              ASTERISCATO CONTROLLO SOTTOSISTEMA DIVERSO DA   **
RL0101**              DA QUELLO DI TESTA                              **
      ******************************************************************
RL0102**30112006      CODICE IVA
      ******************************************************************

       PROGRAM-ID. DCBT310M.
       ENVIRONMENT   DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT  SECTION.
       FILE-CONTROL.
           SELECT FLINP     ASSIGN TO FLINP
                     FILE STATUS IS W-FS-FLINP.

           SELECT FLSRC     ASSIGN TO FLSRC
                     FILE STATUS IS W-FS-FLSRC.

           SELECT FLOUT     ASSIGN TO FLOUT
                     FILE STATUS IS W-FS-FLOUT.

           SELECT DETSCA    ASSIGN TO DETSCA
                     FILE STATUS IS W-FS-DETSCA.

           SELECT SCARTI    ASSIGN TO SCARTI
                     FILE STATUS IS W-FS-SCARTI.

           SELECT STAMPA    ASSIGN TO STAMPA
                     FILE STATUS IS W-FS-STAMPA.

      *--- FLUSSO MAIL CON UFFICI VIRTUALI
           SELECT FLMAILUV  ASSIGN TO FLMAILUV
                     FILE STATUS IS W-FS-FLMAILUV.

       DATA DIVISION.
       FILE SECTION.

       FD FLSRC
           RECORDING MODE F
           LABEL RECORD IS STANDARD
           DATA  RECORD IS ARC-FLSRC.
       01  ARC-FLSRC                 PIC X(080).

       FD  FLINP
           RECORDING MODE F
           LABEL RECORD IS STANDARD
           DATA  RECORD IS ARC-FLINP.
RL0101*01  ARC-FLINP                 PIC X(100).
      *01  ARC-FLINP                 PIC X(120).
ECCE   01  ARC-FLINP                 PIC X(150).

       FD  FLOUT
           RECORDING MODE F
           LABEL RECORD IS STANDARD
           DATA  RECORD IS ARC-FLOUT.
RL0101*01  ARC-FLOUT                 PIC X(100).
RL0101*01  ARC-FLOUT                 PIC X(120).
ECCE   01  ARC-FLOUT                 PIC X(150).

       FD  DETSCA
           RECORDING MODE F
           LABEL RECORD IS STANDARD
           DATA  RECORD IS ARC-DETSCA.
       01  ARC-DETSCA                PIC X(102).

       FD  SCARTI
           RECORDING MODE F
           LABEL RECORD IS STANDARD
           DATA  RECORD IS ARC-SCARTI.
       01  ARC-SCARTI                PIC X(100).

       FD  STAMPA
           RECORDING MODE F
           LABEL RECORD IS STANDARD
           DATA  RECORD IS ARC-STAMPA.
       01  ARC-STAMPA                PIC X(150).

       FD  FLMAILUV
           RECORDING MODE F
           LABEL RECORD IS STANDARD
           DATA  RECORD IS ARC-FLMAILUV.
       01  ARC-FLMAILUV              PIC X(080).

       WORKING-STORAGE SECTION.

      ******************************************************************
      * STRUTTURE DATI FLUSSI IN ARRIVO.                               *
      ******************************************************************
RL0101*--- ASTERISCATA PERCHÛ INCLUSO TUTTO NELLA COPY DCCYB02M
RL0101*--- IN + CI SONO I CAMPI NUOVI (KEY ORIGINARIA)
      *01  REC-DCCYINP.
LF0205*    COPY DCCYB01M.
      *    02 DCCYINP-SOTTSIS-T      PIC  X(03).
      *    02 DCCYINP-DT-CONT-T      PIC  9(08).
      *    02 DCCYINP-PROG-T         PIC  9(04).
      *    02 DCCYINP-FLG-RN         PIC  X(01).
      *    02 DCCYINP-IDE-FL         PIC  S9(18) COMP-3.

RL0101     COPY DCCYB02M.

       01  KEY-FLINP.
           02 DCCYINP-SOTTSIS-KEY    PIC  X(03).
           02 DCCYINP-DT-CONT-KEY    PIC  9(08).
           02 DCCYINP-PROG-KEY       PIC  9(04).

       01  KEY-FLINP-OLD.
           02 DCCYINP-SOTTSIS-KEY-OLD    PIC  X(03).
           02 DCCYINP-DT-CONT-KEY-OLD    PIC  9(08).
           02 DCCYINP-PROG-KEY-OLD       PIC  9(04).

       01  W-FLG-RN-OLD                  PIC X(1) VALUE SPACES.


       01  W-APP-COCONT                 PIC X(08) VALUE SPACES.

      ***************************************************************
      ** TRACCIATO RECORD FILE DI OUTPUT DATA DI AVVIO DI SRC      **
      ***************************************************************
           COPY RCCYASRC.

      ***************************************************************
      ** TRACCIATO RECORD DELLA ROUTINE COBRTG01                   **
      ***************************************************************
           COPY COCRTG01.

       01  W-FILIALE                     PIC X(05) VALUE SPACES.
       01  W-TROVATO                     PIC X(01) VALUE SPACES.
       01  COBRTG01                      PIC X(08) VALUE'COBRTG01'.

      ******************************************************************
      *  AREE PER REPORTISTICA   -  TRACCIATO FILE STAMPA              *
      ******************************************************************
      *
      **   INTESTAZIONE FISSA
      *
       01  REC-FLMAILUV               PIC X(80) VALUE SPACES.

       01  W-PRIMA                    PIC X(1) VALUE 'S'.

       01  RIGA1.
           02 FILLER                  PIC X(47)
                    VALUE '*** POSTE ITALIANE  C.N.E.D. ROMA ***'.
           02 FILLER                  PIC X(12)       VALUE SPACES.
           02 FILLER                  PIC X(21)       VALUE SPACES.

      *
      **   DETTAGLIO ESITO ELABORAZIONE FLUSSO
      *
      *---PARTE FISSA

       01  RIGA1-ST.
           02 FILLER                  PIC X(50)  VALUE
              'FLUSSI CON UFFICI VIRTUALI - ELABORAZIONE DEL'.
           02 FILLER                  PIC X(01)  VALUE SPACES.
           02 W-RIGA1-ST-DT-ELAB      PIC X(10)  VALUE SPACES.
           02 FILLER                  PIC X(21)  VALUE SPACES.

       01  RIGA2-ST.
           02 FILLER                  PIC X(08)  VALUE 'COD.UFF:'.
           02 FILLER                  PIC X(01)  VALUE SPACES.
           02 W-RIGA2-UFFICIO         PIC X(05)  VALUE SPACES.
           02 FILLER                  PIC X(03)  VALUE ' - ' .
           02 FILLER                  PIC X(10)  VALUE 'COD.SOTT.:'.
           02 FILLER                  PIC X(01)  VALUE SPACES.
           02 W-RIGA2-COD-SOTT        PIC X(03)  VALUE SPACES.
           02 FILLER                  PIC X(03)  VALUE ' - ' .
           02 FILLER                  PIC X(13)  VALUE 'DATA CONTAB :'.
           02 FILLER                  PIC X(01)  VALUE SPACES.
           02 W-RIGA2-ST-DATA-CONT    PIC X(08)  VALUE SPACES.
           02 FILLER                  PIC X(03)  VALUE ' - ' .
           02 FILLER                  PIC X(07)  VALUE 'COCONT:'.
           02 FILLER                  PIC X(01)  VALUE SPACES.
           02 W-RIGA2-ST-COCONT       PIC X(08)  VALUE SPACES.



       01  RIGA-VUOTA                 PIC X(80)  VALUE SPACES.

       01  REC-SCARTI.
           03 DCCYSCA-SOTTSIS-T      PIC  X(03).
           03 DCCYSCA-DT-CONT-T      PIC  9(08).
           03 DCCYSCA-PROG-T         PIC  9(04).
           03 DCCYSCA-TIPO-ERRORE    PIC  X(02).
           03 DCCYSCA-MSG-ERRORE     PIC  X(60).
           03 DCCYSCA-FLG-RN         PIC  X(01).
           03 FILLER                 PIC  X(22).

       01  REC-DETSCA.
           03 DETSCA-DATI          PIC X(100)           VALUE SPACE.
           03 DETSCA-ERR           PIC X(002)           VALUE SPACE.

      *--- COPY ERRORI
           COPY DCCYERR.

       01  W-DATA-NUM1          PIC 9(08)            VALUE ZEROES.
       01  W-DATA-ALF REDEFINES W-DATA-NUM1 PIC X(08).

       01 W-TAB-UFF-FIL.
         02  W-ELEM   OCCURS 17000 TIMES.
             05 W-TAB-COD-UFF               PIC X(5).
             05 W-TAB-FILIALE               PIC X(5).
       01 W-IND-MAX                         PIC S9(8) COMP VALUE 17000.

       01  W-TIPO-ERRORE            PIC X(02)            VALUE SPACES.
       01  W-TIPO-ERRORE-SALVATO    PIC X(02)            VALUE SPACES.
       01  W-TIPO-ERRORE-S-N REDEFINES W-TIPO-ERRORE-SALVATO
                                    PIC 9(2).

       01  W-CONT-FLINP             PIC  9(15)           VALUE ZEROES.
       01  W-CONT-FLOUT             PIC  9(15)           VALUE ZEROES.
       01  W-CONT-DETSCA            PIC  9(15)           VALUE ZEROES.
       01  W-CONT-SCARTI            PIC  9(15)           VALUE ZEROES.
       01  W-CONT-STAMPA            PIC  9(15)           VALUE ZEROES.
       01  W-CONT-FLMAILUV          PIC  9(15)           VALUE ZEROES.
       01  W-CONT-RECORD-SCARTA     PIC  9(15)           VALUE ZEROES.

       01  SKEDA.
           03 ANNO-SK               PIC 9(4)           VALUE ZEROES.
           03 MESE-SK               PIC 9(2)           VALUE ZEROES.
           03 GIORNO-SK             PIC 9(2)           VALUE ZEROES.

       01  W-APP-DATA.
           03 W-APP-AAAA            PIC 9(4)           VALUE ZEROES.
           03 FILLER                PIC X(1)           VALUE '-'.
           03 W-APP-MM              PIC 9(2)           VALUE ZEROES.
           03 FILLER                PIC X(1)           VALUE '-'.
           03 W-APP-GG              PIC 9(2)           VALUE ZEROES.

       01  W-IMPORTO            PIC S9(16)V9(2) COMP-3 VALUE ZEROES.

      ******************************************************************
      * VARIABILI DI APPOGGIO UTILIZZATE ALL'INTERNO DEL PROGRAMMA     *
      ******************************************************************

       01 W-FS-FLINP                 PIC X(02)         VALUE '00'.
       01 W-FS-FLOUT                 PIC X(02)         VALUE '00'.
       01 W-FS-DETSCA                PIC X(02)         VALUE '00'.
       01 W-FS-SCARTI                PIC X(02)         VALUE '00'.
       01 W-FS-STAMPA                PIC X(02)         VALUE '00'.
       01 W-FS-FLMAILUV              PIC X(02)         VALUE '00'.
       01 W-FS-FLSRC                 PIC X(02)         VALUE '00'.

      *- ORA DI SISTEMA
       01 W-TIME-SYS                 PIC  9(06)           VALUE ZEROES.

       01 W-STAMPA                   PIC 9(1)             VALUE ZEROES.

      *- DATA DI SISTEMA
       01 W-DATA-SYS.
           03 W-ANNO                 PIC  9(02)           VALUE ZEROES.
           03 W-MESE                 PIC  9(02)           VALUE ZEROES.
           03 W-GIORNO               PIC  9(02)           VALUE ZEROES.

      *- DATA NUMERICA
       01 W-DATA-NUM.
           03 W-SECOLO               PIC  9(02) VALUE 20.
           03 W-ANNO                 PIC  9(02) VALUE ZEROES.
           03 W-MESE                 PIC  9(02) VALUE ZEROES.
           03 W-GIORNO               PIC  9(02) VALUE ZEROES.

       01 W-DATA-NUM-X               PIC  X(8) VALUE SPACES.
       01 W-DATA-NUM-N REDEFINES     W-DATA-NUM-X PIC 9(8).

      *- DATA ALFANUMERICA
       01 W-DATA-ALFA.
           03 W-GIORNO               PIC  X(02)           VALUE SPACES.
           03 FILLER                 PIC  X(01)           VALUE '/'   .
           03 W-MESE                 PIC  X(02)           VALUE SPACES.
           03 FILLER                 PIC  X(01)           VALUE '/'   .
           03 W-ANNO                 PIC  X(02)           VALUE SPACES.

       01  W-NUMERO                  PIC 9(02)          VALUE ZEROES.
       01  W-RESTO-A                 PIC 9(02)          VALUE ZEROES.
       01  W-TESTA                   PIC X(01)          VALUE SPACES.

      ******************************************************************
      * TABELLA PER CONTROLLO DATE                                     *
      ******************************************************************

       01  TAB-DATE.
           02  FILLER                   PIC X(04)     VALUE '0131'.
           02  FILLER                   PIC X(04)     VALUE '0228'.
           02  FILLER                   PIC X(04)     VALUE '0331'.
           02  FILLER                   PIC X(04)     VALUE '0430'.
           02  FILLER                   PIC X(04)     VALUE '0531'.
           02  FILLER                   PIC X(04)     VALUE '0630'.
           02  FILLER                   PIC X(04)     VALUE '0731'.
           02  FILLER                   PIC X(04)     VALUE '0831'.
           02  FILLER                   PIC X(04)     VALUE '0930'.
           02  FILLER                   PIC X(04)     VALUE '1031'.
           02  FILLER                   PIC X(04)     VALUE '1130'.
           02  FILLER                   PIC X(04)     VALUE '1231'.

       01 FILLER REDEFINES TAB-DATE.
           02  W-ELEM   OCCURS 12 TIMES.
               05 W-MM                  PIC 9(2).
               05 W-GG                  PIC 9(2).

       01 REC-INTESTAZ.
           03 FILLER                 PIC X(35) VALUE
              'COD.SOTT;DATA CONTABILE;PROGR.;R/N;'.
           03 FILLER                 PIC X(60) VALUE
              'DESCRIZIONE;'.

       01 REC-STAMPA.
           03 FILLER                 PIC X(2).
           03 W-SOTTSIS              PIC X(3).
           03 FILLER                 PIC X(3).
           03 W-PUNTO-VIRGOLA1       PIC X(1).
           03 W-DATA-CONT            PIC X(10).
           03 FILLER                 PIC X(4).
           03 W-PUNTO-VIRGOLA2       PIC X(1).
           03 W-PROG                 PIC X(04).
           03 FILLER                 PIC X(2).
           03 W-PUNTO-VIRGOLA3       PIC X(1).
           03 FILLER                 PIC X(1).
           03 W-FLAG-RN              PIC X(1).
           03 FILLER                 PIC X(1).
           03 W-PUNTO-VIRGOLA4       PIC X(1).
           03 W-MSG-ERRORE           PIC X(60).
           03 W-PUNTO-VIRGOLA5       PIC X(1).

      ******************************************************************
      * TABELLA APPOGGIO PER DESCRIZIONE E E-MAIL SERVIZI              *
      ******************************************************************

      ******************************************************************
      *  VARIABILI DI APPOGGIO UTILIZZATE PER I CICLI
      ******************************************************************

       01 W-DATA                     PIC 9(08)            VALUE ZEROES.
       01 FILLER REDEFINES W-DATA.
          03 W-DATA-AA               PIC 9(04).
          03 W-DATA-MM               PIC 9(02).
          03 W-DATA-GG               PIC 9(02).
       01 W-IND                      PIC S9(8)     COMP   VALUE ZEROES.

       01  W-DCBTR07          PIC X(07)            VALUE 'DCBTR07'.
           COPY DCCYR07.

      ******************************************************************
      *  FLAGS
      ******************************************************************
       01 W-ERRORE                   PIC X(01)            VALUE SPACES.

      ******************************************************************
LF0205                                                                  00540000
LF0205 01   MAX-ELEM                   PIC S9(4)     COMP   VALUE 300.
LF0205 01   WS-DIVA-COM-STATUS               PIC X(02) VALUE SPACES.
LF0205 01   WS-DIVA-COM-DIVISA               PIC X(03) VALUE SPACES.
LF0205 01   WS-DIVA-TAB-DIVISE.
LF0205      03  WS-DIVA-ELEM   OCCURS 300 INDEXED BY WS-DIVA-IND.
LF0205          05  WS-DIVA-EL-DIVISE      PIC X(03).
LF0205                                                                  00540000
LF0205 01  C1000-ERROR-MESSAGE.
LF0205     10  C1000-ERROR-LEN    COMP          PIC S9(04) VALUE +960.
LF0205     10  C1000-ERROR-TEXT                 PIC X(120)
LF0205          OCCURS 8 TIMES INDEXED BY C1000-ERROR-INDEX.
LF0205 01  C1000-ERROR-TEXT-LEN   COMP          PIC S9(09) VALUE +120.
LF0205                                                                  00540000
LF0205 01 W-SQLCODE                  PIC +++++.
LF0205 01 WS-CONTA-ELEM              PIC 9(3)  VALUE ZEROES.
LF0205******************************************************************00500000
LF0205     EXEC SQL INCLUDE SQLCA END-EXEC.                             00510000
LF0205                                                                  00520000
LF0205     EXEC SQL INCLUDE DCCYDIVA END-EXEC.                          00530000
LF0205     EXEC SQL INCLUDE DCCYECUP END-EXEC.                          00530000
LF0205                                                                  00520000
LF0205     EXEC SQL DECLARE CURDIVA CURSOR                              00016700
LF0205          FOR SELECT                                              00016800
LF0205                   DCTBDIVA_COD                                   00016900
LF0205          FROM DCTBDIVA                                           00017500
LF0205          WHERE    DCTBDIVA_COD > ''                              00017600
LF0205          ORDER BY DCTBDIVA_COD                                   00017900
LF0205     END-EXEC.                                                    00018200

       PROCEDURE DIVISION.

       INIZIO-DCBT310M.

           PERFORM OP-INIZ          THRU EX-OP-INIZ.

           PERFORM ELABORAZIONE     THRU EX-ELABORAZIONE.

           PERFORM OP-FINALI        THRU EX-OP-FINALI.

       FINE-DCBT310M.
           EXIT.

      ******************************************************************
      *             OPERAZIONI INIZIALI                                *
      ******************************************************************

       OP-INIZ.

           DISPLAY '*************************************************'.
           DISPLAY '*--              INIZIO DCBT310M               --*'
           DISPLAY '*************************************************'.

           OPEN INPUT  FLINP.

           IF W-FS-FLINP NOT EQUAL '00'
              DISPLAY 'ERRORE APERTURA ARCHIVIO INPUT: '
                                               W-FS-FLINP
              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN INPUT FLSRC

           IF W-FS-FLSRC NOT EQUAL '00'
              DISPLAY 'ERRORE APERTURA ARCHIVIO FLSRC '
                                               W-FS-FLSRC
              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.


           OPEN OUTPUT FLOUT.

           IF W-FS-FLOUT NOT EQUAL '00'
              DISPLAY 'ERRORE APERTURA ARCHIVIO OUTPUT:'
                                               W-FS-FLOUT
              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT DETSCA

           IF W-FS-DETSCA NOT EQUAL '00'
              DISPLAY 'ERRORE APERTURA ARCHIVIO DETSCA '
                                               W-FS-DETSCA
              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT SCARTI

           IF W-FS-SCARTI NOT EQUAL '00'
              DISPLAY 'ERRORE APERTURA ARCHIVIO SCARTI '
                                               W-FS-SCARTI
              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT STAMPA.

           IF W-FS-STAMPA NOT EQUAL '00'
              DISPLAY 'ERRORE APERTURA ARCHIVIO STAMPA :'
                                               W-FS-STAMPA
              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT FLMAILUV.

           IF W-FS-FLMAILUV NOT EQUAL '00'
              DISPLAY 'ERRORE APERTURA ARCHIVIO FLMAILUV:'
                                               W-FS-FLMAILUV
              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           PERFORM LEGGI-FLSRC
              THRU EX-LEGGI-FLSRC


           ACCEPT W-DATA-SYS FROM DATE
           MOVE CORRESPONDING W-DATA-SYS TO W-DATA-NUM
           MOVE CORRESPONDING W-DATA-NUM TO W-DATA-ALFA.
           MOVE W-DATA-NUM               TO W-DATA-NUM-X.

           ACCEPT SKEDA.
           MOVE ANNO-SK                TO W-APP-AAAA.
           MOVE MESE-SK                TO W-APP-MM.
           MOVE GIORNO-SK              TO W-APP-GG.

           MOVE SPACES                 TO W-TAB-UFF-FIL.

           PERFORM CARICA-ECCEZIONI  THRU CARICA-ECCEZIONI-EX.

       EX-OP-INIZ.
           EXIT.

      ******************************************************************
      * SI PROCEDE CON L'ELABORAZIONE LEGGENDO I FLUSSI E FACENDO TUTTI*
      * I RELATIVI CONTROLLI, DOPO DI CHE SI SCRIVONO I FILES DI OUTPUT*
      ******************************************************************

       ELABORAZIONE.
*********** CARICAMENTO TABELLA DI WORKING DELLE DIVISE.                00030400
LF0205     INITIALIZE WS-DIVA-TAB-DIVISE.
LF0205     PERFORM CICLO-READ-TBDIVA THRU EX-CICLO-READ-TBDIVA.

           PERFORM LEGGI-FLINP THRU EX-LEGGI-FLINP.
           IF W-FS-FLINP EQUAL '10'
              DISPLAY 'ARCHIVIO FLINP VUOTO: ' W-FS-FLINP
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           PERFORM UNTIL W-FS-FLINP = '10'

              MOVE KEY-FLINP           TO KEY-FLINP-OLD
              MOVE DCCYINP-FLG-RN      TO W-FLG-RN-OLD

              MOVE ZEROES              TO W-CONT-RECORD-SCARTA
              MOVE SPACES              TO W-TIPO-ERRORE-SALVATO

              PERFORM UNTIL W-FS-FLINP = '10'  OR
                            KEY-FLINP NOT = KEY-FLINP-OLD

                 PERFORM CONTROLLI-FORMALI     THRU EX-CONTROLLI-FORMALI

                 PERFORM SCRIVI-OUTPUT         THRU EX-SCRIVI-OUTPUT

                 IF W-TIPO-ERRORE NOT = SPACES
                    MOVE W-TIPO-ERRORE         TO W-TIPO-ERRORE-SALVATO
                    ADD 1                      TO W-CONT-RECORD-SCARTA
                    PERFORM SCRIVI-DETSCA      THRU EX-SCRIVI-DETSCA
                 END-IF

                 PERFORM LEGGI-FLINP           THRU EX-LEGGI-FLINP

              END-PERFORM
              IF W-CONT-RECORD-SCARTA > ZEROES
                 PERFORM SCRIVI-SCARTI THRU EX-SCRIVI-SCARTI
                 PERFORM GESTIONE-STAMPA   THRU EX-GESTIONE-STAMPA
              END-IF

           END-PERFORM.

       EX-ELABORAZIONE.
           EXIT.

       LEGGI-FLSRC.
           READ FLSRC INTO RCCYASRC-REC.

           IF W-FS-FLSRC NOT EQUAL '00'
              DISPLAY 'ERRORE LETTURA FLSRC: ' W-FS-FLSRC
              DISPLAY 'DATA AVVIO SRC NON PRESENTE'
              MOVE 500                     TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.
           IF RCCYASRC-DTAVVIO-NUM  NOT NUMERIC
              DISPLAY 'DATA AVVIO SRC NON NUMERICA'
              MOVE 500                     TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.
           DISPLAY '   DATA AVVIO SRC : '  RCCYASRC-DTAVVIO-NUM.

       EX-LEGGI-FLSRC.
           EXIT.

       LEGGI-FLINP.
           READ FLINP INTO REC-DCCYINP.

           IF W-FS-FLINP NOT EQUAL '00' AND '10'
              DISPLAY 'ERRORE LETTURA FLINP: ' W-FS-FLINP
              MOVE 500                     TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           IF W-FS-FLINP EQUAL '00'
              ADD 1 TO W-CONT-FLINP
              MOVE DCCYINP-SOTTSIS-T TO DCCYINP-SOTTSIS-KEY
              MOVE DCCYINP-DT-CONT-T TO DCCYINP-DT-CONT-KEY
              MOVE DCCYINP-PROG-T    TO DCCYINP-PROG-KEY
           END-IF.

           IF W-FS-FLINP EQUAL '00'
FORZA         IF DCCYB01M-COD-UFF NOT = SPACES     AND
FORZA            DCCYB01M-COD-UFF NOT = HIGH-VALUE AND
FORZA            DCCYB01M-COD-UFF NOT = LOW-VALUE

      *--- FORZATURA INSERITA PER MOVIMENTI CCP CON UFFICIO IN INPUT
      *--- VALORIZZATI, MA RIFERITI A CENTRO
                 IF (DCCYB01M-COCONT  = 'DCAEA10C' AND
                     DCCYB01M-CAUSALE = 'POTAX')   OR

                    (DCCYB01M-COCONT  = 'DCAEA10N' AND
                     DCCYB01M-CAUSALE = 'POTAX')   OR

                    (DCCYB01M-COCONT  = 'DCAEA10N' AND
                     DCCYB01M-CAUSALE = '1610')    OR

                    (DCCYB01M-COCONT  = 'DCAED02Q' AND
                     DCCYB01M-CAUSALE = 'POTAX')

FORZA               MOVE SPACES TO DCCYB01M-COD-UFF
FORZA                              DCCYB01M-FILIALE
                 END-IF


      *--- SE IL SOTTISISTEMA Û = SPACES
      *--- SIGNIFICA CHE Û UN RECORD NORMALE (NON UN ECCEZIONE)
                 IF DCCYINP-SOTTSIS-ORIG = SPACES

                   MOVE DCCYB01M-COCONT    TO R07-COCONT
                   MOVE DCCYB01M-SOTTSIS   TO R07-CODSOT
                   MOVE DCCYB01M-CAUSALE   TO R07-CAUSALE

                    PERFORM CERCA-ECCEZIONI
                       THRU CERCA-ECCEZIONI-EX
                    IF R07-TROVATO-FORZ = 'S'
                       CONTINUE
                    ELSE
                       MOVE SPACES TO DCCYB01M-COD-UFF
                                      DCCYB01M-FILIALE
FORZA *          IF (DCCYB01M-COCONT(1:3) = 'DCA'      OR
FORZA *             DCCYB01M-COCONT      = 'DCBSQUAC' OR
FORZA *             DCCYB01M-COCONT      = 'DCBSQUMP' OR
FORZA *             DCCYB01M-COCONT(1:7) = 'DCBVIAG'  OR
      *             DCCYB01M-SOTTSIS     = 'SR0'      OR
      *             DCCYB01M-SOTTSIS     = 'DCD'      OR
      *             DCCYB01M-SOTTSIS     = 'DC1'      OR
      *            (DCCYB01M-SOTTSIS     = 'SR7'      AND
      *            (DCCYB01M-COCONT      = 'DCB06LDC' OR
      *             DCCYB01M-COCONT      = 'DCB06GOC' OR
      *             DCCYB01M-COCONT      = 'DCT06VG1' OR
      *             DCCYB01M-COCONT      = 'DCT06VG2' OR
      *             DCCYB01M-COCONT      = 'DCT06VG3' OR
      *             DCCYB01M-COCONT      = 'DCT06VG4' OR
      *             DCCYB01M-COCONT      = 'DCT06VG5' OR
      *             DCCYB01M-COCONT      = 'DCT06VG6' OR
      *             DCCYB01M-COCONT      = 'DCT06VG7' OR
      *             DCCYB01M-COCONT      = 'DCT06VG8')))
      *
      *
FORZA *             CONTINUE
FORZA *          ELSE
FORZA **            DISPLAY 'RIPULITO UFFICIO : '
FORZA **                    ' DCCYB01M-SOTTSIS:' DCCYB01M-SOTTSIS
FORZA **                    ' DCCYB01M-COCONT :' DCCYB01M-COCONT
FORZA **                    ' DCCYB01M-DT-CONT:' DCCYB01M-DT-CONT
FORZA **                    ' DCCYB01M-DT-OPER:' DCCYB01M-DT-OPER
FORZA **
FORZA *             MOVE SPACES TO DCCYB01M-COD-UFF
FORZA *                            DCCYB01M-FILIALE
FORZA *          END-IF
                 ELSE
FORZA *          IF (DCCYINP-COCONT-ORIG(1:3) = 'DCA'      OR
FORZA *             DCCYINP-COCONT-ORIG      = 'DCBSQUAC' OR
FORZA *             DCCYINP-COCONT-ORIG      = 'DCBSQUMP' OR
FORZA *             DCCYINP-COCONT-ORIG(1:7) = 'DCBVIAG'  OR
      *             DCCYINP-SOTTSIS-ORIG     = 'SR0'      OR
      *             DCCYINP-SOTTSIS-ORIG     = 'DC1'      OR
      *             DCCYINP-SOTTSIS-ORIG     = 'DCD'     OR
      *            (DCCYB01M-SOTTSIS     = 'SR7'      AND
      *            (DCCYB01M-COCONT      = 'DCB06LDC' OR
      *             DCCYB01M-COCONT      = 'DCB06GOC' OR
      *             DCCYB01M-COCONT      = 'DCT06VG1' OR
      *             DCCYB01M-COCONT      = 'DCT06VG2' OR
      *             DCCYB01M-COCONT      = 'DCT06VG3' OR
      *             DCCYB01M-COCONT      = 'DCT06VG4' OR
      *             DCCYB01M-COCONT      = 'DCT06VG5' OR
      *             DCCYB01M-COCONT      = 'DCT06VG6' OR
      *             DCCYB01M-COCONT      = 'DCT06VG7' OR
      *             DCCYB01M-COCONT      = 'DCT06VG8')))

                    MOVE DCCYINP-COCONT-ORIG  TO R07-COCONT
                    MOVE DCCYINP-SOTTSIS-ORIG TO R07-CODSOT
                    MOVE DCCYB01M-CAUSALE     TO R07-CAUSALE

                    PERFORM CERCA-ECCEZIONI
                       THRU CERCA-ECCEZIONI-EX
                    IF R07-TROVATO-FORZ = 'S'
                       CONTINUE
                    ELSE
                       MOVE SPACES TO DCCYB01M-COD-UFF
                                      DCCYB01M-FILIALE
                 END-IF
              END-IF
           END-IF.

110506*--- INSERITA FORZATURA PER SOTTOSISTEMA ASP
110506*--- SE FILIALE HIGH-VALUE O LOW-VALUE SI FORZA A SPACES
110506     IF W-FS-FLINP EQUAL '00'
110506        IF DCCYB01M-FILIALE = HIGH-VALUE OR
110506           DCCYB01M-FILIALE = LOW-VALUE
110506           MOVE SPACES TO DCCYB01M-FILIALE
110506        END-IF
110506     END-IF.

RL0102*--- SI FORZA A SPACES IL CODICE IVA  NEL CASO IN CUI Û LOW-VALUE
RL0102*--- O HIGT-VALUE
RL0102     IF DCCYB01M-COD-IVA = LOW-VALUE OR
RL0102        DCCYB01M-COD-IVA = HIGH-VALUE
RL0102        MOVE SPACES TO DCCYB01M-COD-IVA
RL0102     END-IF

TEMP       IF W-FS-FLINP EQUAL '00'
TEMP  *       IF DCCYB01M-DT-OPER NOT = DCCYB01M-DT-CONT
TEMP  *          IF DCCYB01M-SOTTSIS = 'SRC'
TEMP  **            OR DCCYB01M-COCONT (1:5) = 'DCTEA'
TEMP  **            OR DCCYB01M-COCONT (1:5) = 'DCTED'
TEMP  *             DISPLAY 'DT CONT. DIVERSA DA DT OPER.     :'
TEMP  *                                            ' ' DCCYB01M-COCONT
TEMP  *                                            ' ' DCCYB01M-SOTTSIS
TEMP  *                                            ' ' DCCYB01M-DT-CONT
TEMP  *                                            ' ' DCCYB01M-CAUSALE
TEMP  *                                            ' ' DCCYB01M-SEGNO
TEMP  *                                            ' ' DCCYB01M-DIVISA
TEMP  *                                            ' ' DCCYB01M-DT-OPER
TEMP  *
TEMP  *          ELSE
TEMP  *             DISPLAY 'DT CONT. DIVERSA DA DT OPER.     :'
TEMP  *                                            ' ' DCCYB01M-COCONT
TEMP  *                                            ' ' DCCYB01M-SOTTSIS
TEMP  *                                            ' ' DCCYB01M-DT-CONT
TEMP  *                                            ' ' DCCYB01M-CAUSALE
TEMP  *                                            ' ' DCCYB01M-SEGNO
TEMP  *                                            ' ' DCCYB01M-DIVISA
TEMP  *                                            ' ' DCCYB01M-DT-OPER
TEMP  *                                            ' DT OPER RICOPERTA'
      *
      *          END-IF
TEMP  *       END-IF

TEMP          IF DCCYB01M-SOTTSIS = 'SRC' OR
TEMP             DCCYB01M-SOTTSIS = 'SR0' OR
TEMP             DCCYB01M-SOTTSIS = 'DC1' OR
OPR              DCCYB01M-SOTTSIS = 'OPR'
RL0101*          OR DCCYB01M-COCONT (1:3) = 'DCV'
TEMP  *          OR DCCYB01M-COCONT (1:5) = 'DCTEA'
TEMP  *          OR DCCYB01M-COCONT (1:5) = 'DCTED'
TEMP             CONTINUE
TEMP          ELSE
TEMP             IF DCCYB01M-DT-OPER NOT = DCCYB01M-DT-CONT
TEMP                IF DCCYB01M-DT-OPER  NOT < RCCYASRC-DTAVVIO-NUM
TEMP                   MOVE DCCYB01M-DT-CONT       TO DCCYB01M-DT-OPER
TEMP                END-IF
TEMP             END-IF
TEMP          END-IF
TEMP       END-IF.

      *--- COME RICHISTA DI ALESSIA DEL 13/08/2014
           IF W-FS-FLINP EQUAL '00'
              IF DCCYB01M-COD-UFF = '77555' OR
                 DCCYB01M-COD-UFF = '55111' OR
                 DCCYB01M-COD-UFF = '77333'
                 PERFORM GESTIONE-FLMAILUV THRU EX-GESTIONE-FLMAILUV
              END-IF
           END-IF.

       EX-LEGGI-FLINP.
           EXIT.

       GESTIONE-FLMAILUV.
           IF W-PRIMA = 'S'
              MOVE RIGA1              TO REC-FLMAILUV
              PERFORM SCRIVI-FLMAILUV THRU EX-SCRIVI-FLMAILUV

              MOVE W-APP-DATA         TO W-RIGA1-ST-DT-ELAB
              MOVE RIGA1-ST           TO REC-FLMAILUV
              PERFORM SCRIVI-FLMAILUV THRU EX-SCRIVI-FLMAILUV

              MOVE RIGA-VUOTA         TO REC-FLMAILUV
              PERFORM SCRIVI-FLMAILUV THRU EX-SCRIVI-FLMAILUV

              MOVE 'N'                TO W-PRIMA
           END-IF.

           MOVE DCCYB01M-COD-UFF      TO W-RIGA2-UFFICIO.
           MOVE DCCYB01M-SOTTSIS      TO W-RIGA2-COD-SOTT
           MOVE DCCYB01M-DT-CONT      TO W-RIGA2-ST-DATA-CONT
           MOVE DCCYB01M-COCONT       TO W-RIGA2-ST-COCONT
           MOVE RIGA2-ST              TO REC-FLMAILUV
           PERFORM SCRIVI-FLMAILUV    THRU EX-SCRIVI-FLMAILUV

           .
       EX-GESTIONE-FLMAILUV.
           EXIT.

      ******************************************************************
      * SCRITTURA FILE CON RECORDS BUONI                               *
      ******************************************************************
       SCRIVI-OUTPUT.

           WRITE ARC-FLOUT             FROM REC-DCCYINP.
           ADD 1 TO W-CONT-FLOUT.

       EX-SCRIVI-OUTPUT.
           EXIT.
      ******************************************************************
      * SCRITTURA FILE CON RECORDS SCARTATI PER ERRORI FORMALI         *
      ******************************************************************
       SCRIVI-DETSCA.

           INITIALIZE REC-DETSCA.
           MOVE REC-DCCYINP      TO DETSCA-DATI.
           MOVE W-TIPO-ERRORE    TO DETSCA-ERR.
           WRITE ARC-DETSCA      FROM REC-DETSCA.
           ADD 1                 TO W-CONT-DETSCA.

       EX-SCRIVI-DETSCA.
           EXIT.

       GESTIONE-STAMPA.
           IF W-STAMPA = 0
              WRITE ARC-STAMPA FROM REC-INTESTAZ
              MOVE 1 TO W-STAMPA
           END-IF

           MOVE SPACES                       TO REC-STAMPA.
           MOVE DCCYINP-SOTTSIS-KEY-OLD      TO W-SOTTSIS.
           MOVE DCCYINP-DT-CONT-KEY-OLD(1:4) TO W-DATA-CONT(1:4)
           MOVE DCCYINP-DT-CONT-KEY-OLD(5:2) TO W-DATA-CONT(6:2)
           MOVE DCCYINP-DT-CONT-KEY-OLD(7:2) TO W-DATA-CONT(9:2)
           MOVE '/'                          TO W-DATA-CONT(5:1)
                                                W-DATA-CONT(8:1)
           MOVE DCCYINP-PROG-KEY-OLD         TO W-PROG.
           MOVE W-FLG-RN-OLD                 TO W-FLAG-RN.
           MOVE DCCYSCA-MSG-ERRORE           TO W-MSG-ERRORE
           MOVE ';'              TO W-PUNTO-VIRGOLA1
                                    W-PUNTO-VIRGOLA2
                                    W-PUNTO-VIRGOLA3
                                    W-PUNTO-VIRGOLA4
                                    W-PUNTO-VIRGOLA5.

           PERFORM SCRIVI-STAMPA    THRU EX-SCRIVI-STAMPA.

       EX-GESTIONE-STAMPA.
           EXIT.

       SCRIVI-STAMPA.

           WRITE ARC-STAMPA FROM REC-STAMPA.

           ADD 1 TO W-CONT-STAMPA.

       EX-SCRIVI-STAMPA.
           EXIT.


       SCRIVI-FLMAILUV.

           WRITE ARC-FLMAILUV FROM REC-FLMAILUV.

           ADD 1 TO W-CONT-FLMAILUV.

       EX-SCRIVI-FLMAILUV.
           EXIT.


       SCRIVI-SCARTI.
           MOVE SPACES TO  REC-SCARTI.
           MOVE DCCYINP-SOTTSIS-KEY-OLD TO DCCYSCA-SOTTSIS-T.
           MOVE DCCYINP-DT-CONT-KEY-OLD TO DCCYSCA-DT-CONT-T.
           MOVE DCCYINP-PROG-KEY-OLD    TO DCCYSCA-PROG-T.
           IF W-CONT-RECORD-SCARTA = 1
              MOVE W-TIPO-ERRORE-SALVATO TO DCCYSCA-TIPO-ERRORE
              MOVE DCCYERR-MGS-ERR(W-TIPO-ERRORE-S-N)
                                         TO DCCYSCA-MSG-ERRORE
           ELSE
              MOVE '99'                  TO DCCYSCA-TIPO-ERRORE
              MOVE 'PRESENTI PIU'' ERRORI FORMALI NEL FLUSSO'
                                         TO DCCYSCA-MSG-ERRORE
           END-IF.
           MOVE W-FLG-RN-OLD     TO DCCYSCA-FLG-RN.

           WRITE ARC-SCARTI FROM REC-SCARTI.

           ADD 1 TO W-CONT-SCARTI.

       EX-SCRIVI-SCARTI.
           EXIT.

       CONTROLLI-FORMALI.

           MOVE SPACES TO W-TIPO-ERRORE.

           IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-TIPO-REC NOT = 'S'
                    MOVE '26'        TO W-TIPO-ERRORE
              END-IF
           END-IF.

           IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-COCONT = SPACES OR LOW-VALUE
                 MOVE '11'        TO W-TIPO-ERRORE
              END-IF
           END-IF

           IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-SOTTSIS =  SPACES OR LOW-VALUE
                 MOVE '12'        TO W-TIPO-ERRORE
              ELSE
LF0205           IF DCCYB01M-SOTTSIS NOT = DCCYINP-SOTTSIS-T
RL0101*--- SE IL SOTTOSISTEMA DI TESTA Û DIVERSO DA QUELLO PRESENTE
RL0101*--- NEL RECORD SINTETICO POTREBBE ESSERE UN RECORD REPLICA
RL0101*--- IN QUESTO CASO SI CONTROLLA IL SOTTOSISTEMA ORIGINARIO
RL0101              IF DCCYINP-SOTTSIS-ORIG NOT = SPACES AND
RL0101                 DCCYINP-COCONT-ORIG  NOT = SPACES AND
RL0101                 DCCYINP-DIVISA-ORIG  NOT = SPACES AND
RL0101                 DCCYINP-SEGNO-ORIG   NOT = SPACES
RL0101                 IF DCCYINP-SOTTSIS-ORIG NOT = DCCYINP-SOTTSIS-T
RL0101                    MOVE '24'        TO W-TIPO-ERRORE
RL0101                 END-IF
RL0101              ELSE
                       MOVE '24'        TO W-TIPO-ERRORE
RL0101              END-IF
                 END-IF
              END-IF
           END-IF

           IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-DT-CONT = SPACES OR LOW-VALUE
                 MOVE '13'        TO W-TIPO-ERRORE
              ELSE
LF0205           MOVE DCCYB01M-DT-CONT      TO W-DATA-ALF
                 MOVE W-DATA-NUM1           TO W-DATA
                 PERFORM CONTROLLA-DATA
                    THRU EX-CONTROLLA-DATA
                 IF W-ERRORE = 'S'
                    MOVE '14'        TO W-TIPO-ERRORE
                 ELSE
LF0205              IF DCCYINP-DT-CONT-T NOT = DCCYB01M-DT-CONT
                       MOVE '25'        TO W-TIPO-ERRORE
                    END-IF
                 END-IF
              END-IF
           END-IF

           IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-DT-OPER = SPACES OR LOW-VALUE
                 MOVE '15'        TO W-TIPO-ERRORE
              ELSE
LF0205           MOVE DCCYB01M-DT-OPER      TO W-DATA-ALF
                 MOVE W-DATA-NUM1           TO W-DATA
                 PERFORM CONTROLLA-DATA
                    THRU EX-CONTROLLA-DATA
                 IF W-ERRORE = 'S'
                    MOVE '16'        TO W-TIPO-ERRORE
                 END-IF
              END-IF
           END-IF

           IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-IMPORTO NOT NUMERIC
                 MOVE '18'        TO W-TIPO-ERRORE
              END-IF
           END-IF.

LF0205     IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-IMPORTO-ORIG NOT NUMERIC
LF0205           MOVE '28'        TO W-TIPO-ERRORE
LF0205        END-IF
LF0205     END-IF.

LF0405     IF W-TIPO-ERRORE = SPACES
LF0405        IF  DCCYB01M-IMPORTO      = ZEROES
LF0405            MOVE '17'        TO W-TIPO-ERRORE
LF0405        END-IF
LF0405     END-IF.

LF0505     IF W-TIPO-ERRORE = SPACES
LF0505        IF  DCCYB01M-IMPORTO-ORIG = ZEROES
LF0505            MOVE '27'        TO W-TIPO-ERRORE
LF0505        END-IF
LF0505     END-IF.

           IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-DIVISA = SPACES OR LOW-VALUE
                 MOVE '19'        TO W-TIPO-ERRORE.

           IF W-TIPO-ERRORE = SPACES
IF1312        IF DCCYB01M-DIVISA NOT = 'ITL'
LF0205*          IF DCCYB010-DIVISA NOT = 'E' AND 'L'
      *             MOVE '20'        TO W-TIPO-ERRORE
LF0205           MOVE DCCYB01M-DIVISA   TO WS-DIVA-COM-DIVISA
LF0205           MOVE SPACES            TO WS-DIVA-COM-STATUS
LF0205           PERFORM VALIDA-DIVISA  THRU EX-VALIDA-DIVISA
LF0205           IF WS-DIVA-COM-STATUS =  'KO'
LF0205              MOVE '20'        TO W-TIPO-ERRORE
IF1312           END-IF
IF1312        END-IF
IF1312     END-IF.

           IF W-TIPO-ERRORE = SPACES
LF0205*       IF DCCYB010-DIVISA = 'L'
LF0205        IF DCCYB01M-DIVISA = 'ITL'
IF1212*          IF DCCYB01M-IMPORTO = DCCYB01M-IMPORTO-ORIG
                    COMPUTE W-IMPORTO ROUNDED =
IF1212*                               DCCYB01M-IMPORTO  / 1936,27
LF0205                           DCCYB01M-IMPORTO-ORIG  / 1936,27
                    COMPUTE W-IMPORTO = W-IMPORTO * 100
IF1212*             MOVE W-IMPORTO    TO DCCYB01M-IMPORTO
IF1212              MOVE W-IMPORTO    TO DCCYB01M-IMPORTO-ORIG
IF1212*          END-IF
IF1212           MOVE 'EUR' TO DCCYB01M-DIVISA
              END-IF
           END-IF
********
LF0305     IF W-TIPO-ERRORE = SPACES
LF0305        IF DCCYB01M-DIVISA = 'EUR'
LF0305           IF DCCYB01M-IMPORTO  NOT = DCCYB01M-IMPORTO-ORIG
LF0305              MOVE '29'        TO W-TIPO-ERRORE
LF0305           END-IF
LF0305        END-IF
LF0305     END-IF.

      *    IF W-TIPO-ERRORE = SPACES
LF0205*       IF DCCYB01M-CAUSALE = SPACES
      *          MOVE '21'        TO W-TIPO-ERRORE
      *       END-IF
      *    END-IF.

           IF W-TIPO-ERRORE = SPACES
LF0205        IF DCCYB01M-SEGNO = SPACES
                 MOVE '22'        TO W-TIPO-ERRORE
              ELSE
LF0205           IF DCCYB01M-SEGNO NOT = 'A' AND 'D'
                    MOVE '23'        TO W-TIPO-ERRORE
??????*          ELSE
??????*             MOVE DCCYB01M-SEGNO TO DCCYB01M-SEGNO
                 END-IF
              END-IF
           END-IF.

           IF W-TIPO-ERRORE = SPACES
              IF  DCCYB01M-COD-UFF NOT = SPACES     AND
                  DCCYB01M-COD-UFF NOT = HIGH-VALUE AND
                  DCCYB01M-COD-UFF NOT = LOW-VALUE

                 MOVE SPACES TO W-FILIALE

                 PERFORM CONTROLLA-UFF-WOR
                    THRU EX-CONTROLLA-UFF-WOR
                 IF W-TROVATO = 'N'
                    PERFORM CONTROLLA-UFF-DB2
                       THRU EX-CONTROLLA-UFF-DB2
                    IF W-TROVATO = 'S'
                       MOVE DCCYB01M-COD-UFF     TO W-TAB-COD-UFF(W-IND)
                       MOVE W-FILIALE            TO W-TAB-FILIALE(W-IND)
                    ELSE
                       MOVE '38'                 TO W-TIPO-ERRORE
                    END-IF
                 END-IF
                 MOVE W-FILIALE               TO DCCYB01M-FILIALE

              END-IF
           END-IF.

AP0206     IF W-TIPO-ERRORE = SPACES
AP0206
AP0206*--- COCONT DI "REPLICA"
AP0206        IF  DCCYB01M-COCONT (1:5) EQUAL 'DCAE1'   OR
AP0206            DCCYB01M-COCONT (1:5) EQUAL 'DCAE2'   OR
AP0206            DCCYB01M-COCONT (1:5) EQUAL 'DCAE5'
AP0206           MOVE '2'    TO DCCYB01M-TIPO-COCONT
AP0206        ELSE
AP0206*--- COCONT "ORDINARI"
AP0206           MOVE '1'    TO DCCYB01M-TIPO-COCONT
AP0206        END-IF
AP0206
AP0206     END-IF.

       EX-CONTROLLI-FORMALI.
           EXIT.

       CONTROLLA-DATA.
           MOVE 'N'                           TO W-ERRORE
           DIVIDE W-DATA-AA BY 4 GIVING W-NUMERO
                                 REMAINDER W-RESTO-A
           IF W-RESTO-A = 0
              MOVE '29' TO W-GG(2)
           END-IF.
           IF W-DATA-AA = 0 OR W-DATA-AA NOT NUMERIC
              MOVE 'S'                        TO W-ERRORE
           END-IF.
           IF W-DATA-MM > 12 OR
              W-DATA-MM = 0  OR
              W-DATA-MM NOT NUMERIC
              MOVE 'S'                        TO W-ERRORE
           ELSE
              IF W-DATA-GG > W-GG (W-DATA-MM) OR
                 W-DATA-GG = 0 OR
                 W-DATA-GG NOT NUMERIC
                 MOVE 'S'                     TO W-ERRORE
              END-IF
           END-IF.

       EX-CONTROLLA-DATA.
           EXIT.

      ******************************************************************
       OP-FINALI.

           CLOSE FLINP
                 FLSRC
                 FLOUT
                 DETSCA
                 STAMPA
                 FLMAILUV.

           DISPLAY ' '.
           DISPLAY ' RECORD   LETTI   FLINP   :' W-CONT-FLINP.
           DISPLAY ' RECORD   SCRITTI FLOUT   :' W-CONT-FLOUT.
           DISPLAY ' RECORD   SCRITTI DETSCA  :' W-CONT-DETSCA.
           DISPLAY ' RECORD   SCRITTI SCARTI  :' W-CONT-SCARTI.
           DISPLAY ' RECORD   SCRITTI MAIL    :' W-CONT-FLMAILUV.
           DISPLAY ' '
           DISPLAY '*************************************************'.
           DISPLAY '*--              FINE   DCBT310M               --*'
           DISPLAY '*************************************************'.


           STOP RUN.
       EX-OP-FINALI.
           EXIT.
LF0205*---------------------------------------------------------------*
LF0205 CICLO-READ-TBDIVA.
LF0205*----------------------------------------------------------------*
LF0205*
LF0205     EXEC SQL OPEN CURDIVA END-EXEC                               00023630
LF0205*
LF0205     IF SQLCODE NOT EQUAL 0                                       00023640
LF0205        MOVE SQLCODE     TO W-SQLCODE                             00023650
LF0205        DISPLAY 'ERRORE OPEN CURDIVA  :' W-SQLCODE                00023660
LF0205        PERFORM ERR-DB2-DSNTIAR THRU  EX-ERR-DB2-DSNTIAR
LF0205*       MOVE 1         TO W-ERRORE                                00023671
IF0905        MOVE 500          TO RETURN-CODE
LF0205        PERFORM OP-FINALI THRU EX-OP-FINALI                       00023680
LF0205     END-IF.                                                      00023690
LF0205*
LF0205     PERFORM LETTURA-TBDIVA  THRU  EX-READ-TBDIVA
LF0205          UNTIL SQLCODE = 100.
LF0205*
LF0205     EXEC SQL CLOSE CURDIVA END-EXEC                              00023630
LF0205*
LF0205     IF SQLCODE NOT EQUAL 0                                       00023640
LF0205        MOVE SQLCODE     TO W-SQLCODE                             00023650
LF0205        DISPLAY 'ERRORE CLOSE CURDIVA  :' W-SQLCODE               00023660
LF0205        PERFORM ERR-DB2-DSNTIAR THRU  EX-ERR-DB2-DSNTIAR
LF0205*       MOVE 1         TO W-ERRORE                                00023671
IF0905        MOVE 500          TO RETURN-CODE
LF0205        PERFORM OP-FINALI THRU EX-OP-FINALI                       00023680
LF0205     END-IF.                                                      00023690
LF0205*
LF0205     EXEC SQL COMMIT  END-EXEC.                                   00023630
LF0205*
LF0205 EX-CICLO-READ-TBDIVA.
LF0205     EXIT.                                                        00023630
LF0205*
LF0205 LETTURA-TBDIVA.                                                  00028100
LF0205*
LF0205     EXEC SQL FETCH CURDIVA                                       00028200
LF0205              INTO                                                00028300
LF0205                  :DCTBDIVA-COD                                   00028310
LF0205     END-EXEC.                                                    00029100
LF0205*
LF0205     IF SQLCODE NOT EQUAL 0 AND 100                               00029300
LF0205        MOVE SQLCODE     TO W-SQLCODE                             00029400
LF0205        DISPLAY 'ERRORE LETTURA TABELLA DCTBDIVA:' W-SQLCODE      00029500
LF0205        PERFORM ERR-DB2-DSNTIAR THRU  EX-ERR-DB2-DSNTIAR
LF0205*       MOVE 1         TO W-ERRORE                                00029610
IF0905        MOVE 500          TO RETURN-CODE
LF0205        PERFORM OP-FINALI THRU EX-OP-FINALI.                      00029700
LF0205*
LF0205     IF SQLCODE EQUAL ZERO
LF0205        ADD     1          TO WS-CONTA-ELEM
LF0205        IF WS-CONTA-ELEM > MAX-ELEM
LF0205           DISPLAY 'SUPERATO LIMITE ELEMENTI WORK TABLE DIVISE '  00029500
LF0205*          MOVE 1         TO W-ERRORE                             00029610
IF0905           MOVE 500          TO RETURN-CODE
LF0205           PERFORM OP-FINALI THRU EX-OP-FINALI                    00029700
LF0205        ELSE                                                      00029700
LF0205           MOVE DCTBDIVA-COD TO WS-DIVA-EL-DIVISE (WS-CONTA-ELEM).
LF0205*
LF0205 EX-READ-TBDIVA.
LF0205     EXIT.
LF0205                                                                  00520000
LF0205*----------------------------------------------------------------*
LF0205 VALIDA-DIVISA.
LF0205*----------------------------------------------------------------*
LF0205     SET WS-DIVA-IND TO 1.
LF0205     SEARCH WS-DIVA-ELEM
LF0205         AT END
LF0205            MOVE 'KO'              TO WS-DIVA-COM-STATUS
LF0305            DISPLAY 'DIVISA NON TROVATA IN TABELLA '
LF0305                                          WS-DIVA-COM-DIVISA
LF0205            GO TO EX-VALIDA-DIVISA
LF0205         WHEN WS-DIVA-EL-DIVISE(WS-DIVA-IND)
LF0205                                   = WS-DIVA-COM-DIVISA
LF0205              MOVE 'OK'         TO WS-DIVA-COM-STATUS.
LF0205 EX-VALIDA-DIVISA.
LF0205     EXIT.
LF0205*---------------------------------------------------------------*
LF0205 ERR-DB2-DSNTIAR.
LF0205*---------------------------------------------------------------*
LF0205*
LF0205     CALL 'DSNTIAR'
LF0205           USING SQLCA C1000-ERROR-MESSAGE C1000-ERROR-TEXT-LEN.
LF0205*
LF0205     IF  RETURN-CODE = ZERO
LF0205          PERFORM ERR-DB2-PRINT THRU  EX-ERR-DB2-PRINT
LF0205                 VARYING C1000-ERROR-INDEX
LF0205                 FROM 1 BY 1 UNTIL C1000-ERROR-INDEX GREATER 8
LF0205     ELSE
LF0205         DISPLAY ' ERRORE DURANTE CHIAMATA DSNTIAR '.
LF0205 EX-ERR-DB2-DSNTIAR.
LF0205     EXIT.
LF0205*
LF0205 ERR-DB2-PRINT.
LF0205     DISPLAY         C1000-ERROR-TEXT(C1000-ERROR-INDEX) .
LF0205 EX-ERR-DB2-PRINT.
LF0205     EXIT.

       CONTROLLA-UFF-WOR.

           MOVE 'N' TO W-TROVATO
           PERFORM VARYING W-IND FROM 1 BY 1 UNTIL W-IND > W-IND-MAX
                                        OR W-TROVATO = 'S'
                                        OR W-TAB-COD-UFF(W-IND) = SPACES
              IF W-TAB-COD-UFF(W-IND) = DCCYB01M-COD-UFF
                 MOVE W-TAB-FILIALE(W-IND)  TO W-FILIALE
                 MOVE 'S'                   TO W-TROVATO
              END-IF
           END-PERFORM.
           IF W-IND > W-IND-MAX
              DISPLAY 'TABELLA DI WORKING UFFICI INSUFFICIENTE '
              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

       EX-CONTROLLA-UFF-WOR.
           EXIT.

       CONTROLLA-UFF-DB2.
           MOVE '00000'             TO TG01-CDBAN0.
           MOVE DCCYB01M-COD-UFF    TO TG01-CDDIP0.
           MOVE '00'                TO TG01-CDDPU0.
           MOVE 'SIC'               TO TG01-MODORG.

           CALL COBRTG01 USING TG01-AREA.

           IF TG01-ESITO = 'OK' OR TG01-ESITO = 'WA'
              MOVE TG01-UO-SUP-ID(1:5)    TO W-FILIALE
              MOVE 'S'                    TO W-TROVATO
           END-IF.

           IF TG01-ESITO = 'KO'
              IF TG01-SQLCODE = 100
                 DISPLAY 'UFFICIO NON TROVATO ' DCCYB01M-COD-UFF
ATTE  *--- ATTENZIONE FORZATURA DEL 23/01/2006
ATTE  *          MOVE 'AG000'                TO W-FILIALE
ATTE  *          MOVE 'S'                    TO W-TROVATO
ATTE  *--- FINE ATTENZIONE FORZATURA DEL 23/01/2006
              ELSE
                 DISPLAY 'ERRORE ROUTINE X ACCESSO TGTBTG01: '
                         TG01-SQLCODE
                      ' ' TG01-ESITO
                 MOVE 500               TO RETURN-CODE
                 PERFORM OP-FINALI THRU EX-OP-FINALI
              END-IF
           END-IF.
           IF W-TROVATO = 'S'
              IF W-FILIALE  = SPACES OR LOW-VALUE OR HIGH-VALUE
                 DISPLAY 'FILIALE A BLANK!!!!'
                 DISPLAY 'REC-DCCYINP--->'  REC-DCCYINP
                 DISPLAY '-----------------------------------------'
              END-IF
           END-IF.
                                                                        00079800
       EX-CONTROLLA-UFF-DB2.
           EXIT.

       CARICA-ECCEZIONI.

           DISPLAY 'CARICA '
           INITIALIZE                     DCCYR07.
           MOVE '01'                      TO R07-TIPO-FUNZIONE.
           MOVE W-DCBTR07                 TO R07-PGM-CALL.
           MOVE W-APP-DATA                TO R07-DATA.

           CALL R07-PGM-CALL USING DCCYR07
           IF R07-RETURN-CODE = '9'
              DISPLAY 'ERRORE CALL DCBTR07   ' R07-MSGERR
                      ' ' R07-SQLCODE

              MOVE 500                   TO RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           DISPLAY 'CARICATE ' R07-IND-MAX ' ECCEZIONI UP '.

       CARICA-ECCEZIONI-EX.
           EXIT.
                                                                        00128600
                                                                        00028301
       CERCA-ECCEZIONI.                                                 00028446
                                                                        00028447
           IF (R07-CODSOT  = SPACES OR LOW-VALUE OR HIGH-VALUE) AND     00028448
              (R07-COCONT  = SPACES OR LOW-VALUE OR HIGH-VALUE) AND     00028449
              (R07-CAUSALE = SPACES OR LOW-VALUE OR HIGH-VALUE)         00028450
              MOVE '9'         TO R07-RETURN-CODE                       00028451
              MOVE 'DCBTR07 - INPUT NON VALORIZZATI '                   00028452
                               TO R07-MSGERR                            00028453
              PERFORM OP-FINALI        THRU EX-OP-FINALI
           END-IF.                                                      00028455
                                                                        00028456
           MOVE 'N' TO R07-TROVATO-FORZ                                 00028457
                                                                        00028514
           PERFORM VARYING R07-IND FROM 1 BY 1 UNTIL                    00028516
                                          R07-IND  > R07-IND-MAX-TAB    00028517
                                       OR R07-TROVATO-FORZ = 'S'        00028461
                                                                        00028630
              MOVE R07-TAB-ECUP(R07-IND) TO DCLDCTBECUP                 00028634
                                                                        00028635
              EVALUATE DCTBECUP-FLAG                                    00028636
      *--- SOTTOSISTEMA + CODICE COCONT + CAUSALE                       00028637
              WHEN   7                                                  00028638
      *          DISPLAY 'CI SONO'                                      00028639
      *                  ' R07-CODSOT ' R07-CODSOT                      00028640
      *                  ' R07-COCONT ' R07-COCONT                      00028641
      *                  ' R07-CAUSALE' R07-CAUSALE                     00028642
      *                                                                 00028643
                                                                        00028644
                 MOVE DCTBECUP-COCONT TO W-APP-COCONT                   00028645
                 IF W-APP-COCONT(DCTBECUP-INIZ:DCTBECUP-FINE) =         00028646
                    R07-COCONT(DCTBECUP-INIZ:DCTBECUP-FINE)  AND        00028647
                    DCTBECUP-CAUSALE = R07-CAUSALE           AND        00028648
                    DCTBECUP-CODSOT  = R07-CODSOT                       00028649
                                                                        00028650
                    MOVE 'S' TO R07-TROVATO-FORZ                        00028651
      *             DISPLAY 'TROVATO A 7'                               00028652
                 END-IF                                                 00028653
                                                                        00028654
      *--- CODICE SOTTOSISTEMA                                          00028655
              WHEN   1                                                  00028656
                 IF DCTBECUP-CODSOT = R07-CODSOT                        00028657
                    MOVE 'S' TO R07-TROVATO-FORZ                        00028658
      *             DISPLAY 'TROVATO A 1'                               00028652
                 END-IF                                                 00028659
                                                                        00028660
      *--- CODICE COCONT                                                00028661
              WHEN   2                                                  00028662
      *          DISPLAY 'CI SONO 2'                                    00028663
                 MOVE DCTBECUP-COCONT TO W-APP-COCONT                   00028664
                 IF W-APP-COCONT                                        00028665
                 (DCTBECUP-INIZ:DCTBECUP-FINE) =                        00028666
                    R07-COCONT(DCTBECUP-INIZ:DCTBECUP-FINE)             00028667
                    MOVE 'S' TO R07-TROVATO-FORZ                        00028668
      *             DISPLAY 'TROVATO A 2'                               00028652
                 END-IF                                                 00028670
                                                                        00028671
      *--- CODICE CAUSALE                                               00028672
              WHEN   3                                                  00028673
                 IF DCTBECUP-CAUSALE = R07-CAUSALE                      00028674
                    MOVE 'S' TO R07-TROVATO-FORZ                        00028675
      *             DISPLAY 'TROVATO A 3'                               00028652
                 END-IF                                                 00028676
                                                                        00028677
      *--- CODICE COCONT + SOTTOSISTEMA                                 00028678
              WHEN   4                                                  00028679
                 MOVE DCTBECUP-COCONT TO W-APP-COCONT                   00028680
                 IF W-APP-COCONT                                        00028681
                 (DCTBECUP-INIZ:DCTBECUP-FINE) =                        00028682
                                R07-COCONT(DCTBECUP-INIZ:DCTBECUP-FINE) 00028683
                    AND                                                 00028684
                    DCTBECUP-CODSOT = R07-CODSOT                        00028685
                    MOVE 'S' TO R07-TROVATO-FORZ                        00028686
      *             DISPLAY 'TROVATO A 4'                               00028652
                 END-IF                                                 00028687
                                                                        00028688
      *--- SOTTOSISTEMA + CAUSALE                                       00028689
              WHEN   5                                                  00028690
                 IF DCTBECUP-CAUSALE = R07-CAUSALE AND                  00028691
                    DCTBECUP-CODSOT = R07-CODSOT                        00028692
                    MOVE 'S' TO R07-TROVATO-FORZ                        00028693
      *             DISPLAY 'TROVATO A 5'                               00028652
                 END-IF                                                 00028694
                                                                        00028695
      *--- CODICE COCONT + CAUSALE                                      00028696
              WHEN   6                                                  00028697
                 MOVE DCTBECUP-COCONT TO W-APP-COCONT                   00028698
                 IF W-APP-COCONT(DCTBECUP-INIZ:DCTBECUP-FINE) =         00028699
                    R07-COCONT(DCTBECUP-INIZ:DCTBECUP-FINE)  AND        00028700
                    DCTBECUP-CAUSALE = R07-CAUSALE                      00028701
                    MOVE 'S' TO R07-TROVATO-FORZ                        00028702
      *             DISPLAY 'TROVATO A 6'                               00028652
                 END-IF                                                 00028703
                                                                        00028704
                                                                        00028705
              END-EVALUATE                                              00028547
      *       DISPLAY 'TROVATO ------> ' R07-TROVATO-FORZ               00028707
                                                                        00028708
           END-PERFORM.                                                 00028550
                                                                        00028551
                                                                        00028552
       CERCA-ECCEZIONI-EX.                                              00028553
           EXIT.                                                        00028711
                                                                        00028712
                                                                        00128600

***********************************************************
********* FINE PROGRAMMA **********************************
***********************************************************
