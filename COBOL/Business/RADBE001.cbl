      ******************************************************************00000202
      *                                                                 00000702
      * PRODOTTO : SISTEMA RAPPORTI DORMIENTI                           00000602
      *                                                                 00000702
      * PROGRAMMA: RADBE001,COBOL/BATCH                                 00000802
      *                                                                 00000702
      * SCHEDULAZ: ESTEMPORANEA                                         00001006
      *                                                                 00001106
      * AUTORE   : ENGINEERING                                          00001202
      *                                                                 00001302
      * FUNZIONE : ESTRATTORE RAPPORTI DORMIENTI PER D/R, PER FASE      00001506
      *            INIZIALE                                             00001606
      *                                                                 00000702
      * INPUT    : IFILDR  - FILE RAPPORTI DORMIENTI DR PERIODO TRANSIT.00001806
      *            IFILRCC - FILE MOVIMENTI DI RISVEGLIO CONTABILI      00001906
      *            IFILRCNC- FILE MOVIMENTI DI RISVEGLIO NON CONTABILI  00002006
      *                                                                 00000702
      * OUTPUT   : OFILRADO- FILE STORICO RAPPORTI DORMIENTI E PREDORM. 00002106
      *                                                                 00000702
      ******************************************************************00002506
       IDENTIFICATION DIVISION.                                         00002606
       PROGRAM-ID. RADB0001.                                            00003002
      ******************************************************************00004002
       ENVIRONMENT DIVISION.                                            00015001
       CONFIGURATION SECTION.                                           00016001
TEST   SOURCE-COMPUTER. IBM-3090 WITH DEBUGGING MODE.                   00016102
       SPECIAL-NAMES.                                                   00019001
           DECIMAL-POINT IS COMMA.                                      00019101
      *-----------------------------------------------------------------00019202
       INPUT-OUTPUT SECTION.                                            00019301
       FILE-CONTROL.                                                    00019401
           SELECT  IFILDR    ASSIGN  TO  IFILDR                         00019503
                             FILE STATUS IS FS-IFILDR.                  00019603
           SELECT  IFILRCC   ASSIGN  TO  IFILRCC                        00019703
                             FILE STATUS IS FS-IFILRCC.                 00019803
           SELECT  IFILRCNC  ASSIGN  TO  IFILRCNC                       00019903
                             FILE STATUS IS FS-IFILRCNC.                00020003
           SELECT  OFILRADO  ASSIGN  TO  OFILRADO                       00021003
                             FILE STATUS IS FS-OFILRADO.                00021103
      ******************************************************************00021404
       DATA DIVISION.                                                   00022001
       FILE SECTION.                                                    00023001
       FD  IFILDR    LABEL RECORD STANDARD                              00035003
                     RECORDING MODE IS F                                00036001
                     BLOCK CONTAINS 0.                                  00037003
       01  IDR-REC.                                                     00039003
           05 IDR-REC-KEY.                                              00039203
              10 IDR-REC-CAMPO              PIC X(10).                  00039303
           05                               PIC X(70).                  00039203
      *                                                                 00039603
       FD  IFILRCC   LABEL RECORD STANDARD                              00039703
                     RECORDING MODE IS F                                00039803
                     BLOCK CONTAINS 0.                                  00039903
       01  IRCC-REC.                                                    00040003
           05 IRCC-REC-KEY.                                             00041003
              10 IRCC-REC-CAMPO             PIC X(10).                  00042003
           05                               PIC X(70).                  00039203
      *                                                                 00046001
       FD  IFILRCNC  LABEL RECORD STANDARD                              00047003
                     RECORDING MODE IS F                                00048001
                     BLOCK CONTAINS 0.                                  00049003
       01  IRCNC-REC.                                                   00049103
           05 IRCNC-REC-KEY.                                            00049203
              10 IRCNC-REC-CAMPO            PIC X(10).                  00049303
           05                               PIC X(70).                  00039203
      *                                                                 00049404
       FD  OFILRADO  LABEL RECORD STANDARD                              00049504
                     RECORDING MODE IS F                                00049604
                     BLOCK CONTAINS 0.                                  00049704
       01  ORADO-REC.                                                   00049804
           05 ORADO-REC-KEY.                                            00049904
              10 ORADO-REC-CAMPO            PIC X(10).                  00050004
           05                               PIC X(70).                  00039203
      *-----------------------------------------------------------------00076102
       WORKING-STORAGE SECTION.                                         00077001
      *--- VARIABILI DI LAVORO                                          00077103
       01  WS-LAVORO.                                                   00078003
           05 WS-LETTI-IFILDR               PIC 9(09).                  00078103
           05 WS-LETTI-IFILRCC              PIC 9(09).
           05 WS-LETTI-IFILRCNC             PIC 9(09).
           05 WS-SCRITTI-OFILRADO           PIC 9(09).
      *--- COSTANTI                                                     00089503
       01  WS-COSTANTI-E-SWITCH.                                        00089603
           05 WS-RADBE001                   PIC X(08) VALUE 'RADBE001'. 00078103
           05 FS-IFILDR                     PIC X(02).
           05 FS-IFILRCC                    PIC X(02).
           05 FS-IFILRCNC                   PIC X(02).
           05 FS-OFILRADO                   PIC X(02).
      ******************************************************************00336001
       PROCEDURE DIVISION.                                              00339201
TEST  DDECLARATIVES.                                                    00339302
TEST  DCOBOL2-DEBUG SECTION.                                            00339402
TEST  D    USE FOR DEBUGGING ON ALL PROCEDURES.                         00339502
TEST  DCOBOL2-DEBUG-PARA.                                               00339602
TEST  D    DISPLAY WS-RADBE001 '--> ' DEBUG-ITEM.                       00339702
TEST  DEND DECLARATIVES.                                                00339802
      *----------------------------------------------------------------*00339902
       MAIN.                                                            00340201
           DISPLAY '***************************************'.           00363003
           DISPLAY '* INIZIO PROGRAMMA ' WS-RADBE001.                   00364003
           DISPLAY '*-------------------------------------*'.           00365003
           PERFORM A00010-INIT.                                         00349603
           PERFORM B00010-ELAB                                          00349803
             UNTIL IDR-REC-KEY = HIGH-VALUE.                            00349903
           PERFORM C00010-END.                                          00352003
      *-------------------------------------------                      00359503
      *                                                                 00359603
      *-------------------------------------------                      00359703
       A00010-INIT.                                                     00359803
           PERFORM A00005-INIZIALIZZA.                                  00369403
           PERFORM A00020-OPEN-ALL-FILE.                                00369403
           PERFORM A00030-1A-READ-ALL-FILE-INPUT.                       00369403
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       A00005-INIZIALIZZA.                                              00369403
           INITIALIZE WS-LAVORO.                                        00369403
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       A00020-OPEN-ALL-FILE.                                            00409503
           OPEN INPUT IFILDR.                                           00411003
           IF FS-IFILDR NOT = '00'                                      00412003
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE        '                      00413205
              DISPLAY '* APERTURA FILE IFILDR    '                      00413305
              DISPLAY '* CODICE ERRORE: ' FS-IFILDR                     00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C90000-GEST-ERR                                   00416005
           END-IF.                                                      00417001
           OPEN INPUT IFILRCC.                                          00419103
           IF FS-IFILRCC NOT = '00'                                     00419203
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE        '                      00413205
              DISPLAY '* APERTURA FILE IFILRCC   '                      00413305
              DISPLAY '* CODICE ERRORE: ' FS-IFILRCC                    00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C90000-GEST-ERR                                   00416005
           END-IF.                                                      00420301
           OPEN INPUT IFILRCNC.                                         00420503
           IF FS-IFILRCNC NOT = '00'                                    00419203
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE        '                      00413205
              DISPLAY '* APERTURA FILE IFILRCNC  '                      00413305
              DISPLAY '* CODICE ERRORE: ' FS-IFILRCNC                   00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C90000-GEST-ERR                                   00416005
           END-IF.                                                      00426001
           OPEN OUTPUT OFILRADO.                                        00429003
           IF FS-OFILRADO NOT = '00'                                    00429103
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE        '                      00413205
              DISPLAY '* APERTURA FILE OFILRADO  '                      00413305
              DISPLAY '* CODICE ERRORE: ' FS-OFILRADO                   00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C90000-GEST-ERR                                   00416005
           END-IF.                                                      00430201
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       A00030-1A-READ-ALL-FILE-INPUT.                                   00369403
           PERFORM B01100-READ-IFILDR.                                  00369603
           IF IDR-REC-KEY = HIGH-VALUE
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE  '                            00413205
              DISPLAY '* FILE IFILDR VUOTO '                            00413305
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C90000-GEST-ERR                                   00416005
           END-IF.
           PERFORM B01160-READ-IFILRCNC.                                00369903
           PERFORM B01150-READ-IFILRCC.                                 00370003
      *-------------------------------------------                      00374003
      * PER CIASCUN RECORD LETTO IN INPUT EFFETTUA CTRL FORMALI SUI DATI00375003
      * SE NO ERRORE, GESTIONE RISVEGLI                                 00375003
      *-------------------------------------------                      00376003
       B00010-ELAB.                                                     00499001
           PERFORM B00100-CHECK-DATI-IFILDR.
           PERFORM B00110-CHECK-DATI-IFILRCC.
           PERFORM B00120-CHECK-DATI-IFILRCNC.
           PERFORM B00210-GEST-RISVEGLI.
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B00100-CHECK-DATI-IFILDR.
TEST       DISPLAY '*--- B00100'.
      *    IF
      *       DISPLAY '*-------------------------------------*'         00365003
      *       DISPLAY '* ERRORE BLOCCANTE                     '         00413205
      *       DISPLAY '* DATI ERRATI NEL RECORD FILE IFILDR   '         00413305
      *       DISPLAY '* CHIAVE DEL RECORD: ' IDR-REC-KEY               00413405
      *       DISPLAY '*-------------------------------------*'         00365003
      *       PERFORM C90000-GEST-ERR                                   00416005
      *    END-IF.
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B00110-CHECK-DATI-IFILRCC.
TEST       DISPLAY '*--- B00110'.
      *    IF
      *       DISPLAY '*-------------------------------------*'         00365003
      *       DISPLAY '* ERRORE BLOCCANTE                     '         00413205
      *       DISPLAY '* DATI ERRATI NEL RECORD FILE IFILRCC  '         00413305
      *       DISPLAY '* CHIAVE DEL RECORD: ' IRCC-REC-KEY              00413405
      *       DISPLAY '*-------------------------------------*'         00365003
      *       PERFORM C90000-GEST-ERR                                   00416005
      *    END-IF.
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B00120-CHECK-DATI-IFILRCNC.
TEST       DISPLAY '*--- B00120'.
      *    IF
      *       DISPLAY '*-------------------------------------*'         00365003
      *       DISPLAY '* ERRORE BLOCCANTE                     '         00413205
      *       DISPLAY '* DATI ERRATI NEL RECORD FILE IFILRCNC '         00413305
      *       DISPLAY '* CHIAVE DEL RECORD: ' IRCNC-REC-KEY             00413405
      *       DISPLAY '*-------------------------------------*'         00365003
      *       PERFORM C90000-GEST-ERR                                   00416005
      *    END-IF.
      *-------------------------------------------                      00374003
      * VERIFICA ESISTENZA MOVIMENTI DI RISVEGLIO SU IFILRCC E IFILRCNC 00375003
      * SE NON ESISTONO RISVEGLI SCRIVE IL RECORD LETTO SU OFILRADO     00375003
      *-------------------------------------------                      00376003
       B00210-GEST-RISVEGLI.
           EVALUATE TRUE
             WHEN IDR-REC-KEY > IRCC-REC-KEY
               PERFORM B01150-READ-IFILRCC
             WHEN IDR-REC-KEY = IRCC-REC-KEY
               PERFORM B01100-READ-IFILDR
               PERFORM B01150-READ-IFILRCC
             WHEN IDR-REC-KEY < IRCC-REC-KEY
               PERFORM B00220-GEST-RISV-IRCNC
           END-EVALUATE.
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B00220-GEST-RISV-IRCNC.
           EVALUATE TRUE
             WHEN IDR-REC-KEY > IRCNC-REC-KEY
               PERFORM B01160-READ-IFILRCNC
             WHEN IDR-REC-KEY = IRCNC-REC-KEY
               PERFORM B01100-READ-IFILDR
               PERFORM B01160-READ-IFILRCNC
             WHEN IDR-REC-KEY < IRCNC-REC-KEY
      *        PERFORM B00030-GEST-ANAGRAFE
               PERFORM B01200-PREP-OFILRADO
               PERFORM B01210-SCRIVE-OFILRADO
               PERFORM B01100-READ-IFILDR
           END-EVALUATE.
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B01100-READ-IFILDR.                                              00432003
           READ IFILDR                                                  00438003
              AT END                                                    00438003
              MOVE HIGH-VALUE               TO IDR-REC                  00439003
           END-READ.                                                    00439201
           IF FS-IFILDR = '00'                                          00439403
              ADD 1                         TO WS-LETTI-IFILDR          00459001
           ELSE                                                         00439403
TEST       DISPLAY '*-- IDR-REC: ' IDR-REC                              00365003
              IF IDR-REC-KEY < HIGH-VALUE                               00439403
                 DISPLAY '*-------------------------------------*'      00365003
                 DISPLAY '* ERRORE BLOCCANTE    '                       00413205
                 DISPLAY '* LETTURA FILE IFILDR '                       00413305
                 DISPLAY '* CODICE ERRORE: ' FS-IFILDR                  00413405
                 DISPLAY '*-------------------------------------*'      00365003
                 PERFORM C90000-GEST-ERR                                00416005
              END-IF                                                    00439901
           END-IF.                                                      00439901
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B01150-READ-IFILRCC.                                             00449003
           READ IFILRCC                                                 00438003
              AT END                                                    00438003
              MOVE HIGH-VALUE               TO IRCC-REC                 00439003
           END-READ.                                                    00439201
           IF FS-IFILRCC = '00'                                         00439403
              ADD 1                         TO WS-LETTI-IFILRCC         00459001
           ELSE                                                         00439403
TEST       DISPLAY '*-- IRCC-REC: ' IRCC-REC                            00365003
              IF IRCC-REC-KEY < HIGH-VALUE                              00439403
                 DISPLAY '*-------------------------------------*'      00365003
                 DISPLAY '* ERRORE BLOCCANTE        '                   00413205
                 DISPLAY '* LETTURA FILE IFIRCC     '                   00413305
                 DISPLAY '* CODICE ERRORE: ' FS-IFILRCC                 00413405
                 DISPLAY '*-------------------------------------*'      00365003
                 PERFORM C90000-GEST-ERR                                00416005
              END-IF                                                    00439901
           END-IF.                                                      00439901
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B01160-READ-IFILRCNC.                                            00459703
           READ IFILRCNC                                                00438003
              AT END                                                    00438003
              MOVE HIGH-VALUE               TO IRCNC-REC                00439003
           END-READ.                                                    00439201
           IF FS-IFILRCNC = '00'                                        00439403
              ADD 1                         TO WS-LETTI-IFILRCNC        00459001
           ELSE                                                         00439403
TEST       DISPLAY '*-- IRCNC-REC: ' IRCNC-REC                          00365003
              IF IRCNC-REC-KEY < HIGH-VALUE                             00439403
                 DISPLAY '*-------------------------------------*'      00365003
                 DISPLAY '* ERRORE BLOCCANTE        '                   00413205
                 DISPLAY '* LETTURA FILE IFIRCNC    '                   00413305
                 DISPLAY '* CODICE ERRORE: ' FS-IFILRCNC                00413405
                 DISPLAY '*-------------------------------------*'      00365003
                 PERFORM C90000-GEST-ERR                                00416005
              END-IF                                                    00439901
           END-IF.                                                      00439901
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B01200-PREP-OFILRADO.
           MOVE IDR-REC                     TO ORADO-REC.               00489201
TEST  D    DISPLAY '*--- IDR-REC  : ' IDR-REC.                          00489201
TEST  D    DISPLAY '*--- ORADO-REC: ' ORADO-REC.                        00489201
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       B01210-SCRIVE-OFILRADO.                                          00485001
           WRITE ORADO-REC.                                             00489201
           IF FS-OFILRADO = '00'                                        00489301
              ADD 1                         TO WS-SCRITTI-OFILRADO      00490001
           ELSE                                                         00489901
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE         '                     00413205
              DISPLAY '* SCRITTURA FILE OFILRCC   '                     00413305
              DISPLAY '* CODICE ERRORE: ' FS-OFILRADO                   00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C90000-GEST-ERR                                   00416005
           END-IF.                                                      00491001
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       C00010-END.                                                      00352003
           PERFORM C00020-CHIUDE-ALL-FILE.                              00559703
           PERFORM C99999-FINE.                                         00559703
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       C00020-CHIUDE-ALL-FILE.                                          00352003
           CLOSE IFILDR.                                                00559703
           IF FS-IFILDR NOT = '00'                                      00559803
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE        '                      00413205
              DISPLAY '* CHIUSURA FILE IFILDR    '                      00413305
              DISPLAY '* CODICE ERRORE: ' FS-IFILDR                     00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C99999-FINE                                       00416005
           END-IF.                                                      00559803
           CLOSE IFILRCC.                                               00564003
           IF FS-IFILRCC NOT = '00'                                     00559803
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE        '                      00413205
              DISPLAY '* CHIUSURA FILE IFILRCC   '                      00413305
              DISPLAY '* CODICE ERRORE: ' FS-IFILRCC                    00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C99999-FINE                                       00416005
           END-IF.                                                      00559803
           CLOSE IFILRCNC.                                              00564003
           IF FS-IFILRCNC NOT = '00'                                    00559803
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE        '                      00413205
              DISPLAY '* CHIUSURA FILE IFILRCNC   '                     00413305
              DISPLAY '* CODICE ERRORE: ' FS-IFILRCNC                   00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C99999-FINE                                       00416005
           END-IF.                                                      00559803
           CLOSE OFILRADO.                                              00564003
           IF FS-OFILRADO NOT = '00'                                    00559803
              DISPLAY '*-------------------------------------*'         00365003
              DISPLAY '* ERRORE BLOCCANTE        '                      00413205
              DISPLAY '* CHIUSURA FILE OFILRADO   '                     00413305
              DISPLAY '* CODICE ERRORE: ' FS-OFILRADO                   00413405
              DISPLAY '*-------------------------------------*'         00365003
              PERFORM C99999-FINE                                       00416005
           END-IF.                                                      00559803
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       C90000-GEST-ERR.                                                 00352003
           MOVE 12                          TO RETURN-CODE.             00569803
           PERFORM C99999-FINE.                                         00559703
      *-------------------------------------------                      00374003
      *                                                                 00375003
      *-------------------------------------------                      00376003
       C99999-FINE.                                                     00559703
           DISPLAY '*-------------------------------------*'.           00569803
           DISPLAY '*             STATISTICHE'.                         00570103
           DISPLAY '*             -----------'.                         00570103
           DISPLAY '*RECORD LETTI   DA IFILDR  :' WS-LETTI-IFILDR.      00570103
           DISPLAY '*               DA IFILRCC :' WS-LETTI-IFILRCC.     00570203
           DISPLAY '*               DA IFILRCNC:' WS-LETTI-IFILRCNC.    00570303
           DISPLAY '*RECORD SCRITTI SU OFILRADO:' WS-SCRITTI-OFILRADO.  00570403
           DISPLAY '*-------------------------------------*'.           00365003
           DISPLAY '* FINE PROGRAMMA ' WS-RADBE001.                     00364003
           DISPLAY '***************************************'.           00363003
           STOP RUN.                                                    00570603
      **********************       FINE     ****************************01129203
