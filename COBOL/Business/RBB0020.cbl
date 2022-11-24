       ID DIVISION.
       PROGRAM-ID.         RBB0020.
      *================================================================*
      *    P R O G E T T O  : G.A.R.I.                                 *
      *----------------------------------------------------------------*
      *                                                                *
      *      NNN     NNN         CCCCCCC        HHH   HHH              *
      *      NNNNN   NNN        CCCCCCCC        HHH   HHH              *
      *      NNNNNN  NNN        CCC             HHHHHHHHH              *
      *      NNN NNNNNNN        CCC             HHHHHHHHH              *
      *      NNN   NNNNN  ...   CCCCCCCC  ...   HHH   HHH  ...         *
      *      NNN     NNN  ...    CCCCCCC  ...   HHH   HHH  ...         *
      *                                                                *
      *----------------------------------------------------------------*
      *      NETWORK            COMPUTER        HOUSE      - BOLOGNA - *
      *----------------------------------------------------------------*
      *  VERSIONE XX.XX DEL : 21/10/87 --- ULTIMA MODIFICA : 27/05/88  *
      *================================================================*
      *  OGGETTO:                                                      *
      *             STAMPA DEI CODICI UTENTE                           *
      *                                                                *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA
           C01 IS ACAPO.
      *================================================================*
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT  SKEDA ASSIGN TO ISKEDA.
      *----
           SELECT  UTENTI   ASSIGN TO UTENTI.
      *----
           SELECT  STAMPA   ASSIGN TO STAMPA.
      *================================================================*
       DATA DIVISION.
       FILE SECTION.
      *----------------------------------------------------------------*
       FD  SKEDA                   LABEL RECORD STANDARD
                                   BLOCK  0 RECORDS.
       01  SKEDA-RECORD.
           03  TIPO-SKEDA                PIC X(03).
           03  FILLER                    PIC X.
           03  SK-CDA                    PIC X(02).
           03  FILLER                    PIC X(74).
      *----------------------------------------------------------------*
       FD  UTENTI                   LABEL RECORD STANDARD
                                    BLOCK  0  RECORDS.
       01  UTENTI-FD                      PIC X(200).
      *----------------------------------------------------------------*
       FD  STAMPA                   LABEL RECORD STANDARD
                                    BLOCK  0  RECORDS.
       01  STAMPA-FD                      PIC X(133).
      *----------------------------------------------------------------*
           EJECT
       WORKING-STORAGE SECTION.
      *================================================================*
      *       W O R K I N G     S T O R A G E     U T E N T E
      *================================================================*
       77  CTR                             PIC 99   VALUE 60.
       77  ED-Z9                           PIC Z.ZZZ.ZZ9.
       77  CTR-LETTI                       PIC 9(7) VALUE ZERO.
       77  ST-UTENTI                       PIC XX   VALUE ZERO.
       77  ST-STAMPA                       PIC XX   VALUE ZERO.
       77  DATA-EDIT                       PIC Z9/99/99.
      *----------------------------------------------------------------*
       01  FINE-FILE                       PIC XXX   VALUE SPACES.
           88   EOF               VALUE 'EOF'.
      *----------------------------------------------------------------*
      *           CAMPI PER PREPARARE LA DATA ALLA STAMPA
      *----------------------------------------------------------------*
       01  DATAMG.
           03  WK-AA                    PIC 99.
           03  WK-MM                    PIC 99.
           03  WK-GG                    PIC 99.
       01  DATGMA                       PIC 9(6)  VALUE ZERO.
       01  FILLER  REDEFINES DATGMA.
           03  GG                       PIC 99.
           03  MM                       PIC 99.
           03  AA                       PIC 99.
      *----------------------------------------------------------------*
      *           RECORD PER STAMPA TABULATO
      *----------------------------------------------------------------*
       01  TESTATA1.
           03  FILLER                   PIC X(6)    VALUE SPACES.
           03  FILLER                   PIC X(13) VALUE 'PGM:  RBB0020'.
           03  FILLER                   PIC X(23)   VALUE SPACES.
           03  FILLER                   PIC X(41)
                      VALUE '        LISTA DEGLI UTENTI               '.
           03  FILLER                   PIC X(23)   VALUE SPACES.
           03  FILLER                   PIC X(13) VALUE 'DATA ELAB.:  '.
           03  DATA-ELAB                PIC X(8).
           03  FILLER                   PIC X(5)   VALUE SPACES.
      *-------
       01  TESTATA2.
           03  FILLER                   PIC X(106) VALUE SPACES.
           03  FILLER                   PIC X(13) VALUE 'PAGINA    :  '.
           03  ST-PAG                   PIC 9(2)   VALUE ZERO.
           03  FILLER                   PIC X(11)  VALUE SPACES.
      *-------
       01  TESTATA3.
           03  FILLER                   PIC X(5)   VALUE SPACES.
           03  FILLER                   PIC X(21)
                              VALUE 'CODICE UTENTI      : '.
           03  COD-ABI                  PIC X(02)  VALUE SPACES.
           03  FILLER                   PIC X(104)  VALUE SPACES.
      *-------
      *--------
       01  RIGA.
           03  FILLER                   PIC X(07) VALUE SPACES.
           03  ST-UT                    PIC X(06) VALUE 'UTENTE'.
           03  FILLER                   PIC X(07) VALUE SPACES.
           03  ST-PAS                   PIC X(08) VALUE 'PASSWORD'.
           03  FILLER                   PIC X(05) VALUE SPACES.
           03  ST-COD                   PIC X(02) VALUE 'CA'.
           03  FILLER                   PIC X(13) VALUE SPACES.
           03  ST-DESC                  PIC X(11) VALUE 'DESCRIZIONE'.
           03  FILLER                   PIC X(21) VALUE SPACES.
           03  ST-TER                   PIC X(09) VALUE 'TERMINALE'.
           03  FILLER                   PIC X(02) VALUE SPACES.
           03  ST-STA                   PIC X(09) VALUE 'STAMPANTE'.
           03  FILLER                   PIC X(03) VALUE SPACES.
           03  ST-PAS                   PIC X(01) VALUE 'P'.
           03  FILLER                   PIC X(03) VALUE SPACES.
           03  ST-UTE                   PIC X(05) VALUE 'C-UTE'.
           03  FILLER                   PIC X(03) VALUE SPACES.
           03  ST-UFF                   PIC X(05) VALUE 'C-UFF'.
           03  FILLER                   PIC X(03) VALUE SPACES.
           03  ST-FIL                   PIC X(05) VALUE 'C-FIL'.
           03  FILLER                   PIC X(04) VALUE SPACES.
      *--------
       01  RIGA-STAMPA                  PIC X(132) VALUE SPACES.
       01  ST-LIV1 REDEFINES RIGA-STAMPA.
           03 FILLER                    PIC X(05).
           03 ST-UTENTE                 PIC X(10).
           03 FILLER                    PIC X(03).
           03 ST-PASSWORD               PIC X(12).
           03 FILLER                    PIC X(03).
           03 ST-CDA                    PIC X(02).
           03 FILLER                    PIC X(03).
           03 ST-DESCUTE                PIC X(40).
           03 FILLER                    PIC X(03).
           03 ST-TERM1                  PIC X(08).
           03 FILLER                    PIC X(03).
           03 ST-STAM1                  PIC X(08).
           03 FILLER                    PIC X(03).
           03 ST-STPASS                 PIC X(01).
           03 FILLER                    PIC X(03).
           03 ST-CODUTE                 PIC X(05).
           03 FILLER                    PIC X(03).
           03 ST-CODUFF                 PIC X(05).
           03 FILLER                    PIC X(03).
           03 ST-CODFIL                 PIC X(05).
           03 FILLER                    PIC X(04).
      *------
       01  ST-LIV2.
           03  FILLER                   PIC X(82) VALUE SPACES.
           03  ST-TERM                  PIC X(08).
           03  FILLER                   PIC X(03) VALUE SPACES.
           03  ST-STAM                  PIC X(08).
           03  FILLER                   PIC X(31) VALUE SPACES.
      *-------
      *================================================================*
      *---- INDICE
      *================================================================*
      *
       01  INDSTA      PIC S9(1) COMP SYNC VALUE +0.
      *
      *================================================================*
      *----------------------------------------------------------------*
      *        COPY  TRACCIATO RECORD UTENTIAZIONI                     *
      *----------------------------------------------------------------*
           COPY RBAR012.
           EJECT
      *----------------------------------------------------------------*
      *        COPY  TRACCIATO RECORD MESSAGGI DI ERRORE               *
      *----------------------------------------------------------------*
           COPY RBAWERR.
           EJECT
      *================================================================*
       PROCEDURE DIVISION.
      *================================================================*
           PERFORM   OPEN-FILE    THRU  OPEN-FILE-EX.
      *
      *
           PERFORM   LEGGI        THRU  LEGGI-EX.
      *
           PERFORM   CORPO-PGM    THRU  CORPO-PGM-EX
                                  UNTIL EOF.
      *
           PERFORM   CLOSE-PGM    THRU  CLOSE-PGM-EX.
      *
           GOBACK.
           EJECT
      *================================================================*
      *  MESSAGGI INIZIALI ED APERTURA FILES
      *================================================================*
       OPEN-FILE.
      *
G2A000*    ACCEPT DATAMG          FROM DATE.
G2A000     CALL 'RBBADATE' USING DATAMG.
           MOVE WK-AA             TO AA.
           MOVE WK-MM             TO MM.
           MOVE WK-GG             TO GG.
           MOVE DATGMA            TO DATA-EDIT.
           MOVE DATA-EDIT         TO DATA-ELAB.
           DISPLAY SPACES.
           DISPLAY '***** INIZIO RBB0020 ***** - DATA : '  DATA-EDIT.
      *---
           OPEN INPUT SKEDA.
           READ SKEDA AT END
              MOVE  12         TO WK-RETURN-CODE
              MOVE   2         TO WK-MSGER-CALL
              MOVE  'READ'     TO WK-MSGER-TIPO
              MOVE  'ISKEDA'   TO WK-MSGER-FILE
              MOVE  ZERO       TO WK-MSGER-STATUS
              MOVE  'IL FILE SKEDA E" VUOTO' TO WK-MSGER-DESCR
              DISPLAY   WK-MSG-ERRORE.
           OPEN INPUT UTENTI.
           IF ST-UTENTI NOT EQUAL  '00'
              MOVE   2         TO WK-MSGER-CALL
              MOVE  'OPEN'     TO WK-MSGER-TIPO
              MOVE  'UTENTI'   TO WK-MSGER-FILE
              MOVE  ST-UTENTI  TO WK-MSGER-STATUS
              MOVE  SPACES     TO WK-MSGER-DESCR
              DISPLAY   WK-MSG-ERRORE
              MOVE  12         TO WK-RETURN-CODE.
      *---
           OPEN OUTPUT STAMPA.
           IF ST-STAMPA NOT EQUAL  '00'
              MOVE   3         TO WK-MSGER-CALL
              MOVE  'OPEN'     TO WK-MSGER-TIPO
              MOVE  'STAMPA'   TO WK-MSGER-FILE
              MOVE  ST-STAMPA  TO WK-MSGER-STATUS
              MOVE  SPACES     TO WK-MSGER-DESCR
              DISPLAY   WK-MSG-ERRORE
              MOVE  12         TO WK-RETURN-CODE.
      *---
       OPEN-FILE-EX.
           EXIT.
      *================================================================*
       LEGGI.
      *

           READ UTENTI   INTO RBAR012
                                AT END MOVE 'EOF' TO FINE-FILE
                                       GO TO LEGGI-EX.
      *
           IF RBAR012-UTENTE EQUAL TO '0000000000'
                                GO TO LEGGI.
           IF ST-UTENTI NOT EQUAL ZERO
              MOVE 4          TO WK-MSGER-CALL
              MOVE 'READ'     TO WK-MSGER-TIPO
              MOVE 'UTENTI'   TO WK-MSGER-FILE
              MOVE ST-UTENTI  TO WK-MSGER-STATUS
              MOVE SPACE      TO WK-MSGER-DESCR
              DISPLAY WK-MSG-ERRORE
              MOVE 12         TO WK-RETURN-CODE
              GO TO LEGGI-EX.
      *
           ADD 1                  TO CTR-LETTI.
       LEGGI-EX.
      *================================================================*
       CORPO-PGM.
      *
           IF SK-CDA EQUAL TO RBAR012-CDA OR SK-CDA EQUAL TO SPACES
           PERFORM ELEMENTI       THRU    ELEMENTI-EX.
           PERFORM LEGGI          THRU    LEGGI-EX.
           ADD 1 TO CTR.
      *
       CORPO-PGM-EX.
      *================================================================*
       ELEMENTI.
               MOVE 1 TO INDSTA
               MOVE RBAR012-UTENTE   TO ST-UTENTE
               MOVE '************'   TO ST-PASSWORD
               MOVE RBAR012-CDA TO ST-CDA
               MOVE RBAR012-DESCUTE  TO ST-DESCUTE
               MOVE RBAR012-TERMID(INDSTA) TO ST-TERM1
               MOVE RBAR012-STAMID(INDSTA) TO ST-STAM1
               MOVE RBAR012-STPASSW  TO ST-STPASS
               MOVE RBAR012-UTENTE   TO ST-CODUTE
               MOVE RBAR012-CODUTFIL TO ST-CODUFF
               MOVE RBAR012-CODFIL   TO ST-CODFIL.
               PERFORM    STAMPA-LIV THRU   STAMPA-LIV-EX.
      *
       ELEMENTI-EX.
      *================================================================*
       STAMPA-LIV.
      *
           IF CTR GREATER 55
           WRITE  STAMPA-FD FROM TESTATA1 AFTER ACAPO
           ADD 1 TO ST-PAG
           WRITE  STAMPA-FD FROM TESTATA2
           MOVE SK-CDA TO COD-ABI
           WRITE  STAMPA-FD FROM TESTATA3  AFTER ADVANCING 3 LINES
           WRITE STAMPA-FD FROM RIGA AFTER ADVANCING 3 LINES
           MOVE 10 TO CTR.
            WRITE STAMPA-FD FROM RIGA-STAMPA AFTER ADVANCING 2 LINES.
            MOVE SPACES TO RIGA-STAMPA.
            ADD 3 TO CTR.
      *----
            PERFORM LIVELLO THRU LIVELLO-EX
                     2 TIMES.
      *
       STAMPA-LIV-EX.
      *================================================================*
      *
      * CONTROLLO SULL'ESISTENZA DI PIU TERMINALI E STAMPANTI USATE    *
      *
       LIVELLO.
            ADD 1 TO INDSTA.
            IF RBAR012-TERMID(INDSTA) NOT EQUAL SPACES OR
                 RBAR012-STAMID(INDSTA) NOT EQUAL SPACES
                    MOVE RBAR012-TERMID(INDSTA) TO ST-TERM
                     MOVE RBAR012-STAMID(INDSTA) TO ST-STAM
                     WRITE STAMPA-FD FROM ST-LIV2
                     ADD 1 TO CTR
                     MOVE SPACES TO ST-LIV2.
       LIVELLO-EX.
           EXIT.
      *================================================================*
       CLOSE-PGM.
      *
           CLOSE SKEDA.
           CLOSE UTENTI.
           CLOSE STAMPA.
      *
           DISPLAY SPACES
           MOVE CTR-LETTI   TO ED-Z9.
           DISPLAY '***** MESSAGGI LETTI . . . . . . .' ED-Z9
           DISPLAY SPACES
           DISPLAY '***** FINE   RBB0020  *****'.
      *
       CLOSE-PGM-EX.
           EXIT.
