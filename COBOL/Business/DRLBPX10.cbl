      *================================================================*
      *   PROCEDURA : ESTEMPORANEA                                     *
      *                                                                *
      *   FUNZIONE  : RISCEGLIO DORMIENTI                              *
      *                                                                *
      *   PROGRAMMA : DRLBPX10                                         *
      *                                                                *
      *   SCHEDULE  : ESTEMPORANEA                                     *
      *                                                                *
      *   AUTORE    : ENG                                              *
      *================================================================*
      *  FILE SEQUENZIALI IN INPUT                                     *
      *                                                                *
      *  IFILINPU . FLUSSO DEI RAPPORTI NON RISVEGLIATI                *
      *                                                                *
      *  IFILRADO . FLUSSO SCARICO DA TABELLA RADRADO                  *
      *                                                                *
      *----------------------------------------------------------------*
      *  FILE SEQUENZIALI IN OUTPUT                                    *
      *                                                                *
      *  OFILRADO . FLUSSO NEL FORMATO RADRADO COI CAMPI AGGIORNATI    *
      *                                                                *
      *  OFILELOG . FLUSSO LOG E ANOMALIE                              *
      *                                                                *
      *================================================================*
      *   I D E N T I F I C A T I O N   D I V I S I O N                *
      *================================================================*
       IDENTIFICATION DIVISION.
      *================================================================*
       PROGRAM-ID. DRLBPX10.
       AUTHOR.
      *================================================================*
      *   E N V I R O N M E N T   D I V I S I O N                      *
      *================================================================*
       ENVIRONMENT DIVISION.
      *================================================================*
      **                                                               *
      *================================================================*
      *   C O N F I G U R A T I O N   S E C T I O N                    *
      *================================================================*
       CONFIGURATION SECTION.
      *================================================================*
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *================================================================*
      *   I N P U T - O U T P U T   S E C T I O N                      *
      *================================================================*
       INPUT-OUTPUT SECTION.
      *================================================================*
       FILE-CONTROL.
      *                                                                *
           SELECT  IFILINPU       ASSIGN         TO IFILINPU
                                  FILE STATUS IS FS-IFILINPU.
      *                                                                *
           SELECT  IFILRADO       ASSIGN         TO IFILRADO
                                  FILE STATUS IS FS-IFILRADO.
      *                                                                *
           SELECT  OFILRADO       ASSIGN         TO OFILRADO
                                  FILE STATUS IS FS-OFILRADO.
      *                                                                *
           SELECT  OFILELOG       ASSIGN         TO OFILELOG
                                  FILE STATUS IS FS-OFILELOG.
      *                                                                *
      *================================================================*
      *   D A T A   D I V I S I O N                                    *
      *================================================================*
       DATA DIVISION.
      *================================================================*
      *                                                                *
      *================================================================*
      *   F I L E   S E C T I O N                                      *
      *================================================================*
       FILE SECTION.
      *================================================================*
      *                                                                *
       FD  IFILINPU
           LABEL RECORD STANDARD BLOCK 0 RECORDS
           RECORDING MODE IS F.
       01  REC-IFILINPU                  PIC  X(020).
      *                                                                *
       FD  IFILRADO
           LABEL RECORD STANDARD BLOCK 0 RECORDS
           RECORDING MODE IS F.
       01  REC-IFILRADO                  PIC  X(326).
      *                                                                *
       FD  OFILRADO
           LABEL RECORD STANDARD BLOCK 0 RECORDS
           RECORDING MODE IS F.
       01  REC-OFILRADO                  PIC  X(326).
      *                                                                *
       FD  OFILELOG
           LABEL RECORD STANDARD BLOCK 0 RECORDS
           RECORDING MODE IS F.
       01  REC-OFILELOG                  PIC  X(80).
      *                                                                *
      *================================================================*
      *   W O R K I N G - S T O R A G E   S E C T I O N                *
      *================================================================*
       WORKING-STORAGE SECTION.
      *================================================================*
      *    AREA DI COMODO PER GESTIONE IFILINPU                        *
      *================================================================*
       01  IFILINPU-REC.
           05  IFILINPU-RAP              PIC  9(0012).
           05  IFILINPU-DTSTAMPA         PIC  9(0008).
      *                                                                *
       01  IFILINPU-KEY.
           05  IFILINPU-KEY-RAP                   PIC  9(0012).
      *
      *================================================================*
      *    AREA DI COMODO PER GESTIONE IFILRADO / OFILRADO             *
      *================================================================*
       COPY RADFDRAD.
      *                                                                *
       01  IFILRADO-KEY.
           05 IFILRADO-KEY-RAP               PIC 9(0012).


      *================================================================*
      *    AREA DI COMODO PER GESTIONE OFILELOG                        *
      *================================================================*
       01  OUT-OFILELOG.
           05 LOG-RAP                    PIC 9(12).
           05 LOG-DESCR                  PIC X(30).
           05 FILLER                     PIC X(38).

      *================================================================*
      *    AREA DI COMODO PER ELABORAZIONE PROGRAMMA                   *
      *================================================================*
       01  INDICE                        PIC 9(02).

       01  WK-COSTANTI-FLAG.
           05 WK-DRLBPX10                PIC X(08) VALUE 'DRLBPX10'.
      *
       01  WK-DATA-NASCITA.
           05  WK-ANNO-NASC                 PIC 9(4).
           05  WK-MESE-NASC                 PIC 9(2).
           05  WK-GG-NASC                   PIC 9(2).
      *
       01  SYS-DATA.
           03 SYS-AA                         PIC 9(2).
           03 SYS-MM                         PIC 9(2).
           03 SYS-GG                         PIC 9(2).
      *
       01  SYS-TIME.
           03 SYS-HH                         PIC 9(2).
           03 SYS-MIN                        PIC 9(2).
           03 FILLER                         PIC 9(2).
      *
       01 WS-PIC08.
          05 WS-PIC08-9                 PIC 9(08).
          05 WS-PIC08-X      REDEFINES
             WS-PIC08-9                 PIC X(08).
      *
       01 WS-APPO-DATE.
          05 WS-AP-GG                PIC X(02).
          05 FILLER                  PIC X(01) VALUE '.'.
          05 WS-AP-MM                PIC X(02).
          05 FILLER                  PIC X(01) VALUE '.'.
          05 WS-AP-AAAA              PIC X(04).
      *
       01  CAMPI-X-ELABORAZIONE.
           05  CAMPI-COMODO.
               10  FLG-PRM               PIC  X(0002).
                   88  FLG-PRM-SI        VALUE 'SI'.
                   88  FLG-PRM-NO        VALUE 'NO'.
               10  FLG-POS               PIC  X(0002).
                   88  FLG-POS-SI        VALUE 'SI'.
                   88  FLG-POS-NO        VALUE 'NO'.
               10  FLG-ANA               PIC  X(0002).
                   88  FLG-ANA-SI        VALUE 'SI'.
                   88  FLG-ANA-NO        VALUE 'NO'.
           05  CONTATORI.
               10  TOT-RED-IFILINPU         PIC  9(0015).
               10  TOT-RED-IFILRADO         PIC  9(0015).
               10  TOT-WRT-OFILRADO         PIC  9(0015).
               10  TOT-NON-CENSITI          PIC  9(0015).
               10  TOT-VARIATI              PIC  9(0015).

           05  CONTATORI-EDIT.
               10  ELEM-TOT-EDIT      OCCURS  20.
                   15  EDIT-I            PIC  ---.---.---.--9.
                   15  EDIT-D            PIC  ---.---.---.---.--9,999.
      *
      *================================================================*
      *  AREE DI COMODO PER GESTIONE ERRORE                            *
      *================================================================*
           05 CAMPI-ERRORE.
               10 ERR-PROGRAMMA          PIC X(08).
               10 ERR-PUNTO              PIC X(04).
               10 ERR-DESCRIZIONE        PIC X(80).
               10 ERR-CODICE-X           PIC X(06).
               10 ERR-CODICE-Z           PIC -----9.
               10 ERR-DATI               PIC X(80).
               10 ERR-GRAVE              PIC X(02).
      *================================================================*
      *  AREE DI COMODO PER GESTIONE STATUS DEI FILE                   *
      *================================================================*
           05  STATUS-FILE.
               10  FS-IFILINPU           PIC  X(0002).
                   88  FS-IFILINPU-OK    VALUE '00'.
                   88  FS-IFILINPU-EF    VALUE '10'.
               10  FS-IFILRADO           PIC  X(0002).
                   88  FS-IFILRADO-OK    VALUE '00'.
                   88  FS-IFILRADO-EF    VALUE '10'.
               10  FS-OFILRADO           PIC  X(0002).
                   88  FS-OFILRADO-OK    VALUE '00'.
               10  FS-OFILELOG           PIC  X(0002).
                   88  FS-OFILELOG-OK    VALUE '00'.
      *================================================================*
      *   L I N K A G E   S E C T I O N                                *
      *================================================================*
       LINKAGE SECTION.
      *================================================================*
      *                                                                *
      *================================================================*
      *   P R O C E D U R E   D I V I S I O N                          *
      *================================================================*
       PROCEDURE DIVISION.
      *================================================================*
      *   M A I N                                                      *
      *================================================================*
       INIZIO-MAIN.
           PERFORM INIZIO                      THRU INIZIO-EX.
           PERFORM ELABORA                     THRU ELABORA-EX
             UNTIL FS-IFILINPU-EF
               AND FS-IFILRADO-EF.
           PERFORM FINE                        THRU FINE-EX.
       FINE-MAIN.
           STOP RUN.

      *================================================================*
       INIZIO.
      *================================================================*
           DISPLAY '*==============================================*'.
           DISPLAY '*====       INIZIO PROGRAMMA DRLBPX10      ====*'.
           DISPLAY '*====  BILANCIAMENTO DORMIENTI / RADRADO   ====*'.
           DISPLAY '*==============================================*'.
      *
           ACCEPT SYS-DATA   FROM DATE.
      *
           ACCEPT SYS-TIME FROM TIME.
      *
           INITIALIZE CAMPI-X-ELABORAZIONE.
           MOVE WK-DRLBPX10              TO ERR-PROGRAMMA
      *
           PERFORM OPEN-FILES            THRU OPEN-FILES-EX.
           PERFORM RED-IFILINPU          THRU RED-IFILINPU-EX.
           PERFORM RED-IFILRADO          THRU RED-IFILRADO-EX.
      *
       INIZIO-EX.
           EXIT.

      *================================================================*
       ELABORA.
      *================================================================*
      *
           IF IFILINPU-KEY = IFILRADO-KEY
              PERFORM ELA-OFILRADO            THRU ELA-OFILRADO-EX
              PERFORM RED-IFILINPU            THRU RED-IFILINPU-EX
              PERFORM RED-IFILRADO            THRU RED-IFILRADO-EX
           ELSE
              IF IFILRADO-KEY > IFILINPU-KEY
                 PERFORM SEGNALA-ANOMALIA     THRU SEGNALA-ANOMALIA-EX
                 PERFORM RED-IFILINPU         THRU RED-IFILINPU-EX
              ELSE
                  IF IFILRADO-KEY < IFILINPU-KEY
                     PERFORM WRT-OFILRADO     THRU WRT-OFILRADO-EX
                     PERFORM RED-IFILRADO     THRU RED-IFILRADO-EX
                  END-IF
              END-IF
           END-IF.
       ELABORA-EX.
           EXIT.

      *================================================================*
       ELA-OFILRADO.
      *================================================================*
      *

           MOVE '04'                   TO RADRADO-STRAPPO
           MOVE ZEROES                 TO RADRADO-DATFINE
           MOVE 20150417               TO RADRADO-DTMORIS
           MOVE 'N'                    TO RADRADO-TIPOOPE
           MOVE 'ONCDRI04  '           TO RADRADO-CARISVE

           ADD 1  TO TOT-VARIATI
           PERFORM WRT-OFILRADO      THRU WRT-OFILRADO-EX.

      *
       ELA-OFILRADO-EX.
           EXIT.

      *================================================================*
       FINE.
      *================================================================*
           PERFORM CLOSE-FILES           THRU CLOSE-FILES-EX.
           PERFORM STATISTICHE           THRU STATISTICHE-EX.
       FINE-EX.
           EXIT.
      *================================================================*
       STATISTICHE.
      *================================================================*
           MOVE TOT-RED-IFILINPU         TO EDIT-I(1).
           MOVE TOT-RED-IFILRADO         TO EDIT-I(2).
           MOVE TOT-WRT-OFILRADO         TO EDIT-I(3).
           MOVE TOT-NON-CENSITI          TO EDIT-I(4).
           MOVE TOT-VARIATI              TO EDIT-I(5).
      *
           DISPLAY '*==============================================*'
           DISPLAY '*====          STATISTICHE FINALI          ====*'
           DISPLAY '*==============================================*'
           DISPLAY ' TOTALE LETTI IN INPUT.......:' EDIT-I(1).
           DISPLAY '*====--------------------------------------====*'
           DISPLAY ' TOTALE LETTI SU RADRADO.....:' EDIT-I(2).
           DISPLAY '*====--------------------------------------====*'
           DISPLAY ' TOTALE SCRITTI IN OUTPUT....:' EDIT-I(3).
           DISPLAY '     DI CUI VARIATI..........:' EDIT-I(5).
           DISPLAY '*====--------------------------------------====*'
           DISPLAY ' TOTALE NON CENSITI..........:' EDIT-I(4).
           DISPLAY '*==============================================*'.
       STATISTICHE-EX.
           EXIT.
      *================================================================*
       OPEN-FILES.
      *================================================================*
           OPEN INPUT  IFILINPU.
           IF NOT FS-IFILINPU-OK
              MOVE '0001'                        TO ERR-PUNTO
              MOVE SPACES                        TO ERR-DESCRIZIONE
              MOVE 'OPEN IFILINPU'               TO ERR-DESCRIZIONE
              MOVE FS-IFILINPU                   TO ERR-CODICE-X
              MOVE 'SI'                          TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE          THRU GESTIONE-ERRORE-EX
              PERFORM STATISTICHE              THRU STATISTICHE-EX
              STOP RUN
           END-IF.
      *
           OPEN INPUT  IFILRADO.
           IF NOT FS-IFILRADO-OK
              MOVE '0002'                        TO ERR-PUNTO
              MOVE SPACES                        TO ERR-DESCRIZIONE
              MOVE 'OPEN IFILRADO'               TO ERR-DESCRIZIONE
              MOVE FS-IFILRADO                   TO ERR-CODICE-X
              MOVE 'SI'                          TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE          THRU GESTIONE-ERRORE-EX
              PERFORM STATISTICHE              THRU STATISTICHE-EX
              STOP RUN
           END-IF.
      *
           OPEN OUTPUT OFILRADO.
           IF NOT FS-OFILRADO-OK
              MOVE '0003'                        TO ERR-PUNTO
              MOVE SPACES                        TO ERR-DESCRIZIONE
              MOVE 'OPEN OFILRADO'               TO ERR-DESCRIZIONE
              MOVE FS-OFILRADO                   TO ERR-CODICE-X
              MOVE 'SI'                          TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE          THRU GESTIONE-ERRORE-EX
              PERFORM STATISTICHE              THRU STATISTICHE-EX
              STOP RUN
           END-IF.
      *
           OPEN OUTPUT OFILELOG.
           IF NOT FS-OFILELOG-OK
              MOVE '0003'                        TO ERR-PUNTO
              MOVE SPACES                        TO ERR-DESCRIZIONE
              MOVE 'OPEN OFILELOG'               TO ERR-DESCRIZIONE
              MOVE FS-OFILELOG                   TO ERR-CODICE-X
              MOVE 'SI'                          TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE          THRU GESTIONE-ERRORE-EX
              PERFORM STATISTICHE              THRU STATISTICHE-EX
              STOP RUN
           END-IF.
      *
       OPEN-FILES-EX.
           EXIT.
      *================================================================*
       CLOSE-FILES.
      *================================================================*
           CLOSE       IFILINPU.
           IF NOT FS-IFILINPU-OK
              MOVE '0004'                        TO ERR-PUNTO
              MOVE SPACES                        TO ERR-DESCRIZIONE
              MOVE 'CLOSE IFILINPU'              TO ERR-DESCRIZIONE
              MOVE FS-IFILINPU                   TO ERR-CODICE-X
              MOVE 'SI'                          TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE          THRU GESTIONE-ERRORE-EX
              PERFORM STATISTICHE              THRU STATISTICHE-EX
              STOP RUN
           END-IF.
      *
           CLOSE       IFILRADO.
           IF NOT FS-IFILRADO-OK
              MOVE '0005'                        TO ERR-PUNTO
              MOVE SPACES                        TO ERR-DESCRIZIONE
              MOVE 'CLOSE IFILRADO'              TO ERR-DESCRIZIONE
              MOVE FS-IFILRADO                   TO ERR-CODICE-X
              MOVE 'SI'                          TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE          THRU GESTIONE-ERRORE-EX
              PERFORM STATISTICHE              THRU STATISTICHE-EX
              STOP RUN
           END-IF.
      *
           CLOSE       OFILRADO.
           IF NOT FS-OFILRADO-OK
              MOVE '0006'                        TO ERR-PUNTO
              MOVE SPACES                        TO ERR-DESCRIZIONE
              MOVE 'CLOSE OFILRADO'              TO ERR-DESCRIZIONE
              MOVE FS-OFILRADO                   TO ERR-CODICE-X
              MOVE 'SI'                          TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE          THRU GESTIONE-ERRORE-EX
              PERFORM STATISTICHE              THRU STATISTICHE-EX
              STOP RUN
           END-IF.
      *
           CLOSE       OFILELOG.
           IF NOT FS-OFILELOG-OK
              MOVE '0006'                        TO ERR-PUNTO
              MOVE SPACES                        TO ERR-DESCRIZIONE
              MOVE 'CLOSE OFILELOG'              TO ERR-DESCRIZIONE
              MOVE FS-OFILELOG                   TO ERR-CODICE-X
              MOVE 'SI'                          TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE          THRU GESTIONE-ERRORE-EX
              PERFORM STATISTICHE              THRU STATISTICHE-EX
              STOP RUN
           END-IF.
      *
       CLOSE-FILES-EX.
           EXIT.
      *================================================================*
       RED-IFILINPU.
      *================================================================*
           READ IFILINPU.
           EVALUATE TRUE
              WHEN FS-IFILINPU-OK
                   ADD 1                         TO TOT-RED-IFILINPU
                   INITIALIZE                       IFILINPU-REC
                                                    IFILINPU-KEY
                   MOVE REC-IFILINPU             TO IFILINPU-REC
                   MOVE IFILINPU-RAP             TO IFILINPU-KEY-RAP

              WHEN FS-IFILINPU-EF
                   IF TOT-RED-IFILINPU = ZEROES
                      DISPLAY '**********************************'
                      DISPLAY '****  ATTENZIONE FILE VUOTO   ****'
                      DISPLAY '****  I  F  I  L  I  N  P  U  ****'
                      DISPLAY '**********************************'

                      MOVE '0013'                   TO ERR-PUNTO
                      MOVE SPACES                   TO ERR-DESCRIZIONE
                      MOVE 'IFILINPU VUOTO'         TO ERR-DESCRIZIONE
                      MOVE FS-IFILINPU              TO ERR-CODICE-X
                      MOVE 'SI'                     TO ERR-GRAVE
                      PERFORM GESTIONE-ERRORE    THRU GESTIONE-ERRORE-EX
                      PERFORM STATISTICHE         THRU STATISTICHE-EX
                      STOP RUN
                   END-IF

                   INITIALIZE                       IFILINPU-KEY
                   MOVE  999999999999            TO IFILINPU-KEY-RAP

              WHEN OTHER
                   MOVE '0009'                   TO ERR-PUNTO
                   MOVE SPACES                   TO ERR-DESCRIZIONE
                   MOVE 'LETTURA IFILINPU'       TO ERR-DESCRIZIONE
                   MOVE FS-IFILINPU              TO ERR-CODICE-X
                   MOVE 'SI'                     TO ERR-GRAVE
                   PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
                   PERFORM STATISTICHE         THRU STATISTICHE-EX
                   STOP RUN
           END-EVALUATE.
       RED-IFILINPU-EX.
           EXIT.
      *================================================================*
       RED-IFILRADO.
      *================================================================*
           READ IFILRADO.
           EVALUATE TRUE
              WHEN FS-IFILRADO-OK
                   ADD 1                         TO TOT-RED-IFILRADO
                   INITIALIZE                       RADRADO-RECF
                                                    IFILRADO-KEY
                   MOVE REC-IFILRADO             TO RADRADO-RECF
                   MOVE RADRADO-RAPPORT          TO IFILRADO-KEY-RAP

              WHEN FS-IFILRADO-EF
                   IF TOT-RED-IFILRADO = ZEROES
                      DISPLAY '**********************************'
                      DISPLAY '****  ATTENZIONE FILE VUOTO   ****'
                      DISPLAY '****  I  F  I  L  R  A  D  O  ****'
                      DISPLAY '**********************************'

                      MOVE '0014'                   TO ERR-PUNTO
                      MOVE SPACES                   TO ERR-DESCRIZIONE
                      MOVE 'IFILRADO VUOTO'         TO ERR-DESCRIZIONE
                      MOVE FS-IFILRADO              TO ERR-CODICE-X
                      MOVE 'SI'                     TO ERR-GRAVE
                      PERFORM GESTIONE-ERRORE    THRU GESTIONE-ERRORE-EX
                      PERFORM STATISTICHE         THRU STATISTICHE-EX
                      STOP RUN
                   END-IF

                   INITIALIZE                       IFILRADO-KEY
                   MOVE  999999999999            TO IFILRADO-KEY-RAP

              WHEN OTHER
                   MOVE '0010'                   TO ERR-PUNTO
                   MOVE SPACES                   TO ERR-DESCRIZIONE
                   MOVE 'LETTURA IFILRADO'       TO ERR-DESCRIZIONE
                   MOVE FS-IFILRADO              TO ERR-CODICE-X
                   MOVE 'SI'                     TO ERR-GRAVE
                   PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
                   PERFORM STATISTICHE         THRU STATISTICHE-EX
                   STOP RUN
           END-EVALUATE.
       RED-IFILRADO-EX.
           EXIT.

      *================================================================*
       WRT-OFILRADO.
      *================================================================*
      *
           INITIALIZE REC-OFILRADO.
      *
           WRITE REC-OFILRADO FROM RADRADO-RECF.
      *
           EVALUATE TRUE
              WHEN FS-OFILRADO-OK
                   ADD 1                         TO TOT-WRT-OFILRADO

              WHEN OTHER
                   MOVE '0011'                   TO ERR-PUNTO
                   MOVE SPACES                   TO ERR-DESCRIZIONE
                   MOVE 'WRITE OFILRADO'         TO ERR-DESCRIZIONE
                   MOVE FS-OFILRADO              TO ERR-CODICE-X
                   MOVE 'SI'                     TO ERR-GRAVE
                   PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
                   PERFORM STATISTICHE         THRU STATISTICHE-EX
                   STOP RUN
           END-EVALUATE.
      *
       WRT-OFILRADO-EX.
           EXIT.

      *================================================================*
       WRT-OFILELOG.
      *================================================================*
      *
      *    INITIALIZE OUT-OFILELOG.

           MOVE IFILINPU-KEY-RAP                    TO LOG-RAP.
           MOVE OUT-OFILELOG                        TO REC-OFILELOG.
           WRITE REC-OFILELOG.
      *
           EVALUATE TRUE
              WHEN FS-OFILELOG-OK
                   CONTINUE

              WHEN OTHER
                   MOVE '0011'                   TO ERR-PUNTO
                   MOVE SPACES                   TO ERR-DESCRIZIONE
                   MOVE 'WRITE OFILELOG'         TO ERR-DESCRIZIONE
                   MOVE FS-OFILELOG              TO ERR-CODICE-X
                   MOVE 'SI'                     TO ERR-GRAVE
                   PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
                   PERFORM STATISTICHE         THRU STATISTICHE-EX
                   STOP RUN
           END-EVALUATE.
      *
       WRT-OFILELOG-EX.
           EXIT.

      *================================================================*
       GESTIONE-ERRORE.
      *================================================================*
           DISPLAY '*==============================================*'.
           DISPLAY '*====             ERRORE GRAVE             ====*'
           DISPLAY '*====--------------------------------------====*'.
           DISPLAY '*====   PUNTO        : ' ERR-PUNTO.
           DISPLAY '*====   DESCRIZIONE  : ' ERR-DESCRIZIONE.
           DISPLAY '*====   CODICE X     : ' ERR-CODICE-X.
           DISPLAY '*====   CODICE 9     : ' ERR-CODICE-Z.
           DISPLAY '*====--------------------------------------====*'.
           DISPLAY '*====             ERRORE GRAVE             ====*'
           DISPLAY '*==============================================*'.
           MOVE 12                               TO RETURN-CODE.
       GESTIONE-ERRORE-EX.
           EXIT.


      *-----------------------------------
      *
      *-----------------------------------

      *-----------------------------------
      *
      *-----------------------------------
       SEGNALA-ANOMALIA.
           INITIALIZE OUT-OFILELOG.
           MOVE 'RAPPORTO NON PRESENTE SU RADRADO'  TO LOG-DESCR.
           ADD 1                                    TO TOT-NON-CENSITI.
           PERFORM WRT-OFILELOG THRU WRT-OFILELOG-EX.
       SEGNALA-ANOMALIA-EX.
           EXIT.
