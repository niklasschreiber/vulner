       IDENTIFICATION DIVISION.                                         00000100
       PROGRAM-ID. RCTB102.                                             00000200
      ******************************************************************00000300
      **  CREATORE    --> ENGINEERING                                 **00000400
      **  DATA        --> DICEMBRE 2005                               **00000500
      ******************************************************************00000600
      **  SERVIZIO    --> --------                                    **00000700
      **  TIPO        --> BATCH                                       **00000800
      **  LINK DA     --> --------                                    **00000900
      **  TRANSID     --> --------                                    **00001000
      **  MAPPA       --> --------                                    **00001100
      **  DB2         --> SI                                          **00001200
      ******************************************************************00001300
      **  SCOPO       --> IL PROGRAMMA SI OCCUPA DI POPOLARE LA       **00001400
      **                  TABELLA DB2 RCTBGEUP(GESTIONE UP),          **00001500
      **                  ESTRAENDO DAL FILE DELLE SQUADRATURE VERE   **00001600
      ******************************************************************00001700
      **  FILE INPUT  --> FLIPARM    (PARAMETRI IN INPUT)             **00001800
      **              --> FLISTA01   (SQ VERE IN INPUT)               **00001900
      **  FILE OUTPUT --> FLOGEUP    (SEQ PER TAB DB2 RCTBGEUP)       **00002000
      ******************************************************************00002100
       ENVIRONMENT DIVISION.                                            00002200
       CONFIGURATION SECTION.                                           00002300
       SPECIAL-NAMES.                                                   00002400
           DECIMAL-POINT IS COMMA.                                      00002500
                                                                        00002600
       INPUT-OUTPUT SECTION.                                            00002700
       FILE-CONTROL.                                                    00002800
                                                                        00002900
      * ARCHIVIO SQUADRATURE VERE IN INPUT                              00003000
           SELECT    FLISTA01                                           00003100
           ASSIGN TO FLISTA01                                           00003200
           FILE STATUS IS FS-FLISTA01.                                  00003300
                                                                        00003400
      * ARCHIVIO PARAMETRI.                                             00003500
           SELECT    FLIPARM                                            00003600
           ASSIGN TO FLIPARM                                            00003700
           FILE STATUS IS RCCYPARM-FS-FLIPARM.                          00003800
                                                                        00003900
      * SEQUENZIALE PER CARICAMNTO TAB DB2 RCTBGEUP                     00004000
           SELECT    FLOGEUP                                            00004100
           ASSIGN TO FLOGEUP                                            00004200
           FILE STATUS IS FS-FLOGEUP.                                   00004300
                                                                        00004400
       DATA DIVISION.                                                   00004500
       FILE SECTION.                                                    00004600
                                                                        00004700
       FD FLISTA01                                                      00004800
           RECORDING F                                                  00004900
           LABEL RECORD IS STANDARD                                     00005000
           BLOCK CONTAINS 0 RECORDS                                     00005100
           DATA RECORD IS REC-FLISTA01.                                 00005200
       01 REC-FLISTA01        PIC X(092).                               00005300
                                                                        00005400
       FD FLIPARM                                                       00005500
           RECORDING F                                                  00005600
           LABEL RECORD IS STANDARD                                     00005700
           BLOCK CONTAINS 0 RECORDS                                     00005800
           DATA RECORD IS REC-FLIPARM.                                  00005900
       01 REC-FLIPARM         PIC X(080).                               00006000
                                                                        00006100
       FD FLOGEUP                                                       00006200
           RECORDING F                                                  00006300
           LABEL RECORD IS STANDARD                                     00006400
           BLOCK CONTAINS 0 RECORDS                                     00006500
           DATA RECORD IS REC-FLOGEUP.                                  00006600
       01 REC-FLOGEUP         PIC X(059).                               00006800
                                                                        00006900
       WORKING-STORAGE SECTION.                                         00007000
                                                                        00007100
      * FILE STATUS.                                                    00007200
       01 FS-FLISTA01            PIC X(002)          VALUE '00'.        00007300
       01 FS-FLOGEUP             PIC X(002)          VALUE '00'.        00007400
                                                                        00007500
      * CONTATORI PER I RECORD LETTI E SCRITTI.                         00007600
       01 CTR-FLISTA01           PIC S9(009) COMP-3  VALUE ZEROES.      00007700
       01 CTR-FLOGEUP            PIC S9(009) COMP-3  VALUE ZEROES.      00007800
       01 CTR-ESISTE             PIC S9(009) COMP-3  VALUE ZEROES.      00007900
       01 CTR-FLISTA01-ED        PIC ZZZ.ZZZ.ZZ9     VALUE SPACES.      00008000
       01 CTR-FLOGEUP-ED         PIC ZZZ.ZZZ.ZZ9     VALUE SPACES.      00008100
       01 CTR-ESISTE-ED          PIC ZZZ.ZZZ.ZZ9     VALUE SPACES.      00008200
                                                                        00008300
       01 W-COUNT-GEUP           PIC S9(005) COMP-3  VALUE ZEROES.      00008400
       01 W-ESISTE-GEUP          PIC  X(002)         VALUE SPACES.      00008500
       01 W-TIMESTAMP            PIC  X(026)         VALUE SPACES.      00008600
                                                                        00008700
      ***************************************************************   00008800
      ** AREA LETTURA FILE IN INPUT                                **   00008900
      ***************************************************************   00009000
       01  W-FLISTA01.                                                  00009100
           10 FLISTA01-DTCONT     PIC X(10).                            00009200
           10 FILLER              PIC X(1).                             00009300
           10 FLISTA01-COD-UFF    PIC X(5).                             00009400
           10 FILLER              PIC X(1).                             00009500
           10 FLISTA01-VDACO      PIC X(5).                             00009600
           10 FILLER              PIC X(1).                             00009700
           10 FLISTA01-D-IMPORTO  PIC 9(16)V9(2).                       00009800
           10 FILLER              PIC X(1).                             00009900
           10 FLISTA01-P-IMPORTO  PIC 9(16)V9(2).                       00010000
           10 FILLER              PIC X(1).                             00010100
           10 FLISTA01-S-IMPORTO  PIC X(19).                            00010200
           10 FILLER              PIC X(1).                             00010300
           10 FLISTA01-COD-FIL    PIC X(5).                             00010400
           10 FILLER              PIC X(1).                             00010500
           10 FLISTA01-PART       PIC X(4).                             00010600
           10 FILLER              PIC X(2).                             00010700
      *                                                                 00010800
      ** *********************************************************** ** 00010900
      * VARIABILE DI APPOGGIO PER VISUALIZZAZIONE A VIDEO DELL'SQLCODE  00011000
      ** *********************************************************** ** 00011100
       01 W-SQLCODE              PIC ++++9           VALUE SPACES.      00011200
                                                                        00011300
      ** *********************************************************** ** 00011400
      **    FLAG PER GESTIONE ERRORE                                 ** 00011500
      ** *********************************************************** ** 00011600
       77  FL-ERRORE                 PIC X               VALUE   'N'.   00011700
                                                                        00011800
      ***************************************************************   00011900
      ** TRACCIATO RECORD DELLA SCHEDA PARAMETRO FLIPARM           **   00012000
      ***************************************************************   00012100
           COPY RCCYPARM.                                               00012200
                                                                        00012300
      * INCLUSIONE STRUTTURE DB2.                                       00012400
           EXEC SQL INCLUDE SQLCA END-EXEC.                             00012500
                                                                        00012600
      * INCLUSIONE TABELLA TOTALI PARTITE                               00012700
           EXEC SQL INCLUDE RCCYGEUP END-EXEC.                          00012800
                                                                        00012900
       LINKAGE SECTION.                                                 00013000
                                                                        00013100
      ******************************************************************00013200
      ************            PROCEDURE DIVISION            ************00013300
      ******************************************************************00013400
       PROCEDURE DIVISION.                                              00013500
                                                                        00013600
       INIZIO-PGM-RCTB102.                                              00013700
                                                                        00013800
           PERFORM OP-INIZIALI       THRU  EX-OP-INIZIALI.              00013900
                                                                        00014000
           PERFORM ELABORAZIONE      THRU  EX-ELABORAZIONE.             00014100
                                                                        00014200
           PERFORM OP-FINALI         THRU  EX-OP-FINALI.                00014300
                                                                        00014400
       FINE-PGM-RCTB102.                                                00014500
           EXIT.                                                        00014600
                                                                        00014700
      ******************************************************************00014800
      *************           OPERAZIONI INIZIALI           ************00014900
      ******************************************************************00015000
       OP-INIZIALI.                                                     00015100
                                                                        00015200
           PERFORM DISPLAY-INIZIALI  THRU  EX-DISPLAY-INIZIALI.         00015300
                                                                        00015400
           PERFORM APERTURA-FILE     THRU  EX-APERTURA-FILE.            00015500
                                                                        00015600
       EX-OP-INIZIALI.                                                  00015700
           EXIT.                                                        00015800
      ***************************************************************** 00015900
                                                                        00016000
       DISPLAY-INIZIALI.                                                00016100
                                                                        00016200
           DISPLAY '***************************************************'00016300
                   '**'.                                                00016400
           DISPLAY '*--              INIZIO RCTB102                   -'00016500
                   '-*'.                                                00016600
           DISPLAY '***************************************************'00016700
                                                                        00016800
                                                                        00016900
           PERFORM ACCETTA-FLIPARM   THRU  EX-ACCETTA-FLIPARM.          00017000
                                                                        00017100
       EX-DISPLAY-INIZIALI.                                             00017200
           EXIT.                                                        00017300
                                                                        00017400
      ***************************************************************** 00017500
       APERTURA-FILE.                                                   00017600
                                                                        00017700
           OPEN INPUT FLISTA01.                                         00017800
           IF FS-FLISTA01 NOT = '00'                                    00017900
              DISPLAY 'ERRORE APERTURA FILE FLISTA01 ' FS-FLISTA01      00018000
              MOVE 'S' TO FL-ERRORE                                     00018100
              PERFORM OP-FINALI  THRU EX-OP-FINALI                      00018200
           END-IF.                                                      00018300
                                                                        00018400
           OPEN OUTPUT FLOGEUP.                                         00018500
           IF FS-FLOGEUP NOT = '00'                                     00018600
              DISPLAY 'ERRORE APERTURA FILE FLOGEUP ' FS-FLOGEUP        00018700
              MOVE 'S' TO FL-ERRORE                                     00018800
              PERFORM OP-FINALI  THRU EX-OP-FINALI                      00018900
           END-IF.                                                      00019000
                                                                        00019100
       EX-APERTURA-FILE.                                                00019200
           EXIT.                                                        00019300
                                                                        00019400
      ******************************************************************00019500
      ***********            ELABORAZIONE                  *************00019600
      ******************************************************************00019700
       ELABORAZIONE.                                                    00019800
                                                                        00019900
           PERFORM LEGGI-FLISTA01 THRU EX-LEGGI-FLISTA01.               00020000
                                                                        00020100
           PERFORM UNTIL FS-FLISTA01 = '10'                             00020200
                                                                        00020300
              PERFORM VERIFICA-GEUP       THRU EX-VERIFICA-GEUP         00020400
              IF W-ESISTE-GEUP = 'SI'                                   00020500
                 ADD 1 TO CTR-ESISTE                                    00020600
              ELSE                                                      00020700
                 PERFORM VALORIZZA-FLOGEUP THRU EX-VALORIZZA-FLOGEUP    00020800
                 PERFORM SCRIVI-FLOGEUP    THRU EX-SCRIVI-FLOGEUP       00020900
              END-IF                                                    00021000
              PERFORM LEGGI-FLISTA01        THRU EX-LEGGI-FLISTA01      00021100
           END-PERFORM.                                                 00021200
                                                                        00021300
       EX-ELABORAZIONE.                                                 00021400
           EXIT.                                                        00021500
                                                                        00021600
      ******************************************************************00021700
       VALORIZZA-FLOGEUP.                                               00021800
                                                                        00021900
           INITIALIZE DCLRCTBGEUP.                                      00022000
                                                                        00022001
           MOVE FLISTA01-PART       TO GEUP-PART.                       00022010
           MOVE FLISTA01-DTCONT     TO GEUP-DTCONT.                     00022020
           MOVE FLISTA01-VDACO      TO GEUP-VDACO.                      00022030
           MOVE FLISTA01-COD-UFF    TO GEUP-COD-UFF.                    00022040
                                                                        00022100
           MOVE  0                  TO GEUP-FLAG-UFF.                   00022200
           MOVE  W-TIMESTAMP        TO GEUP-TIMEST.                     00022300
           MOVE  'RCBT102'          TO GEUP-UTENTE.                     00022400
                                                                        00023700
       EX-VALORIZZA-FLOGEUP.                                            00024000
           EXIT.                                                        00024100
                                                                        00024200
      ***************************************************************** 00024300
       LEGGI-FLISTA01.                                                  00024400
                                                                        00024500
           INITIALIZE REC-FLISTA01.                                     00024600
                                                                        00024700
           READ FLISTA01 INTO W-FLISTA01.                               00024800
           IF FS-FLISTA01 NOT = '00' AND '10'                           00024900
              DISPLAY 'ERRORE LETTURA FILE FLISTA01 ' FS-FLISTA01       00025000
              MOVE 'S' TO FL-ERRORE                                     00025100
              PERFORM OP-FINALI THRU EX-OP-FINALI                       00025200
           END-IF.                                                      00025300
                                                                        00025400
           IF FS-FLISTA01 = '00'                                        00025500
              ADD 1 TO  CTR-FLISTA01                                    00025600
           END-IF.                                                      00025700
                                                                        00025800
       EX-LEGGI-FLISTA01.                                               00025900
           EXIT.                                                        00026000
                                                                        00026100
      ******************************************************************00026200
       SCRIVI-FLOGEUP.                                                  00026300
                                                                        00026400
           INITIALIZE REC-FLOGEUP.                                      00026500
                                                                        00026600
           WRITE REC-FLOGEUP FROM DCLRCTBGEUP.                          00026700
           IF FS-FLOGEUP NOT = '00'                                     00026800
              DISPLAY 'ERRORE SCRITTURA SU FILE FLOGEUP ' FS-FLOGEUP    00026900
              MOVE 'S' TO FL-ERRORE                                     00027000
              PERFORM OP-FINALI THRU EX-OP-FINALI                       00027100
           END-IF.                                                      00027200
           ADD 1                            TO CTR-FLOGEUP.             00027300
                                                                        00027400
       EX-SCRIVI-FLOGEUP.                                               00027500
           EXIT.                                                        00027600
                                                                        00027700
      ***************************************************************** 00027800
       VERIFICA-GEUP.                                                   00027900
                                                                        00028000
           MOVE ZEROES                 TO W-COUNT-GEUP                  00028100
           MOVE SPACES                 TO W-TIMESTAMP                   00028101
           MOVE FLISTA01-PART          TO GEUP-PART                     00028110
           MOVE FLISTA01-DTCONT        TO GEUP-DTCONT                   00028120
           MOVE FLISTA01-VDACO         TO GEUP-VDACO                    00028130
           MOVE FLISTA01-COD-UFF       TO GEUP-COD-UFF                  00028140
           EXEC SQL                                                     00028200
               SELECT COUNT(*), CURRENT TIMESTAMP                       00028300
                 INTO :W-COUNT-GEUP, :W-TIMESTAMP                       00028400
                 FROM RCTBGEUP                                          00028500
                WHERE GEUP_PART      =:GEUP-PART                        00028600
                  AND GEUP_DTCONT    =:GEUP-DTCONT                      00028700
                  AND GEUP_VDACO     =:GEUP-VDACO                       00028800
                  AND GEUP_COD_UFF   =:GEUP-COD-UFF                     00028900
           END-EXEC.                                                    00029000
                                                                        00029100
           IF SQLCODE NOT = 0                                           00029200
              MOVE SQLCODE TO W-SQLCODE                                 00029300
              DISPLAY 'ERRORE VERIFICA RICERCA GEUP  ' W-SQLCODE        00029400
              MOVE 'S' TO FL-ERRORE                                     00029500
              PERFORM OP-FINALI THRU EX-OP-FINALI                       00029600
           END-IF.                                                      00029700
                                                                        00029800
           IF W-COUNT-GEUP = ZEROES                                     00029900
              MOVE 'NO' TO W-ESISTE-GEUP                                00030000
           ELSE                                                         00030100
              MOVE 'SI' TO W-ESISTE-GEUP                                00030200
           END-IF.                                                      00030300
DEBUG *    DISPLAY ' PART: '    GEUP-PART                               00030400
DEBUG *            ' DTCONT: '  GEUP-DTCONT                             00030500
DEBUG *            ' VDACO: '   GEUP-VDACO                              00030600
DEBUG *            ' COD-UFF: '  GEUP-COD-UFF                           00030700
DEBUG *            ' SQL: ' SQLCODE                                     00030800
DEBUG *            ' COUNT : ' W-COUNT-GEUP                             00030900
DEBUG *            ' ESISTE : ' W-ESISTE-GEUP.                          00031000
                                                                        00031100
       EX-VERIFICA-GEUP.                                                00031200
           EXIT.                                                        00031300
                                                                        00031400
      ******************************************************************00031500
      ***********      OPERAZIONI FINALI                   *************00031600
      ******************************************************************00031700
       OP-FINALI.                                                       00031800
                                                                        00031900
           PERFORM VISUALIZZA-CONTATORI  THRU  EX-VISUALIZZA-CONTATORI. 00032000
                                                                        00032100
           PERFORM CHIUSURA-FILE         THRU  EX-CHIUSURA-FILE.        00032200
                                                                        00032300
           PERFORM DISPLAY-FINALI-E-STOP THRU  EX-DISPLAY-FINALI-E-STOP.00032400
                                                                        00032500
       EX-OP-FINALI.                                                    00032600
           EXIT.                                                        00032700
                                                                        00032800
      ***************************************************************** 00032900
       VISUALIZZA-CONTATORI.                                            00033000
                                                                        00033100
           DISPLAY ' '.                                                 00033200
           MOVE CTR-FLISTA01 TO CTR-FLISTA01-ED.                        00033300
           DISPLAY ' RECORD LETTI FLUSSO SQVERE               '         00033400
                                                       CTR-FLISTA01-ED. 00033500
           DISPLAY ' '.                                                 00033600
                                                                        00033700
           MOVE CTR-ESISTE    TO CTR-ESISTE-ED.                         00033800
           DISPLAY ' DI CUI GIë PRESENTI IN RCTBGEUP          '         00033900
                                                         CTR-ESISTE-ED. 00034000
           DISPLAY ' '.                                                 00034100
                                                                        00034200
           MOVE CTR-FLOGEUP TO CTR-FLOGEUP-ED.                          00034300
           DISPLAY ' DI CUI DA CARICARE IN RCTBGEUP           '         00034400
                                                        CTR-FLOGEUP-ED. 00034500
           DISPLAY ' '.                                                 00034600
                                                                        00034700
       EX-VISUALIZZA-CONTATORI.                                         00034800
           EXIT.                                                        00034900
                                                                        00035000
      ******************************************************************00035100
       CHIUSURA-FILE.                                                   00035200
                                                                        00035300
           CLOSE FLISTA01.                                              00035400
           IF FS-FLISTA01 NOT = '00'                                    00035500
              DISPLAY 'ERRORE CHIUSURA FILE FLISTA01 ' FS-FLISTA01      00035600
              MOVE 'S' TO FL-ERRORE                                     00035700
           END-IF.                                                      00035800
                                                                        00035900
           CLOSE FLOGEUP.                                               00036000
           IF FS-FLOGEUP NOT = '00'                                     00036100
              DISPLAY 'ERRORE CHIUSURA FILE FLOGEUP ' FS-FLOGEUP        00036200
              MOVE 'S' TO FL-ERRORE                                     00036300
           END-IF.                                                      00036400
                                                                        00036500
       EX-CHIUSURA-FILE.                                                00036600
           EXIT.                                                        00036700
                                                                        00036800
      ***************************************************************** 00036900
       DISPLAY-FINALI-E-STOP.                                           00037000
                                                                        00037100
           DISPLAY ' '.                                                 00037200
           DISPLAY '***************************************************'00037300
                   '**'.                                                00037400
           DISPLAY '*--                FINE RCTB102                   -'00037500
                   '-*'.                                                00037600
           DISPLAY '***************************************************'00037700
                   '**'.                                                00037800
                                                                        00037900
           IF FL-ERRORE = 'S' OR                                        00038000
              RCCYPARM-ERRORE = 'S'                                     00038100
              MOVE 500 TO RETURN-CODE                                   00038200
           END-IF.                                                      00038300
                                                                        00038400
           STOP RUN.                                                    00038500
                                                                        00038600
       EX-DISPLAY-FINALI-E-STOP.                                        00038700
           EXIT.                                                        00038800
                                                                        00038900
      ******************************************************************00039000
      ** LA LABEL ASTERISCATA DI SEGUITO VIENE ESPLOSA ALL'INTERNO    **00039100
      ** DELLA COPY DI PROCEDURE RCCPPARM                             **00039200
      ******************************************************************00039300
      *ACCETTA-FLIPARM.                                                 00039400
                                                                        00039500
           COPY RCCPPARM.                                               00039600
                                                                        00039700
      *EX-ACCETTA-FLIPARM.                                              00039800
      *    EXIT.                                                        00039900
