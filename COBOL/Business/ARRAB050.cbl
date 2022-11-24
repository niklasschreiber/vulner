      *----------------------------------------------------------------*00010000
      * -----STAMPA DEI SALDI E MOVIMENTI SCARTATI------                00010199
      *    CONTROLLO FORMALE DEI FILES RICEVUTI DALL'ENTE GARANTE.      00011000
      *    IL PROGRAMMA VERIFICA LA VALIDITA DELL'INFORMAZIONE RICEVUTA 00012000
      *    VIA FTP:                                                     00013000
      *             CONTROLLO QUANTITA RECORDS INDICATI NEL RECORD TAPPO00013100
      *             E QUELLI EFFETTIVAMENTE CONTENUTI NEL FILE          00013200
      *    SE IL CONTROLLO VA A BUON FINE VIENE STAMPATO IL TABULATO CON00013367
      *    L' ELENCO DEI SALDI E DEI MOVIMENTI ASSOCIATI.               00013467
      *----------------------------------------------------------------*00014000
      * 181000 ===> INSERITO CONTROLLO DELLA LETTURA FUORI CICLO      * 00015099
      *             FILE VUOTO ==> RETURN-CODE = 4                    * 00016099
      ***************************************************************** 00017099
       IDENTIFICATION DIVISION.                                         00020000
      *_________________________________________________________________00030000
       PROGRAM-ID.   ARRAB050.                                          00040028
       AUTHOR.                                                          00050000
      *_________________________________________________________________00060000
      *                           ARRAB050                              00070028
      *_________________________________________________________________00080000
       ENVIRONMENT DIVISION.                                            00105000
      *_________________________________________________________________00106000
       CONFIGURATION SECTION.                                           00107000
      *_________________________________________________________________00108000
          SPECIAL-NAMES.                                                00109000
              DECIMAL-POINT IS COMMA.                                   00110000
      *_________________________________________________________________00120000
       INPUT-OUTPUT SECTION.                                            00130000
      *_________________________________________________________________00140000
      *                                                                 00150000
       FILE-CONTROL.                                                    00160000
      *                                                                 00170000
           SELECT  FILE63    ASSIGN  TO FILE63                          00181099
                 FILE  STATUS  IS  W-STAT00.                            00190000
      *                                                                 00240004
           SELECT  FILE62    ASSIGN  TO FILE62                          00241099
                 FILE  STATUS  IS  W-STAT01.                            00242004
      *                                                                 00242113
           SELECT  STAMPA    ASSIGN  TO STAMPA                          00242213
                 FILE  STATUS  IS  W-STAT02.                            00242313
      *_________________________________________________________________00243004
       DATA DIVISION.                                                   00250000
      *_________________________________________________________________00260000
       FILE SECTION.                                                    00270000
      *_________________________________________________________________00280000
      *                                                                 00351000
       FD  FILE63                                                       00357199
           LABEL RECORD STANDARD                                        00357200
           RECORDING MODE IS F                                          00357300
           BLOCK CONTAINS 0 RECORDS.                                    00357400
       01  REC-SAL             PIC X(59).                               00357529
      *                                                                 00357604
       FD  FILE62                                                       00357799
           LABEL RECORD STANDARD                                        00357804
           RECORDING MODE IS F                                          00357904
           BLOCK CONTAINS 0 RECORDS.                                    00358004
       01  REC-MOV             PIC X(60).                               00358199
      *                                                                 00358213
       FD  STAMPA                                                       00358313
           LABEL RECORD STANDARD                                        00358413
           RECORDING MODE IS F                                          00358513
           BLOCK CONTAINS 0 RECORDS.                                    00358613
       01  REC-SMOV            PIC X(132).                              00358738
      *_________________________________________________________________00359000
       WORKING-STORAGE SECTION.                                         00440000
      *_________________________________________________________________00450000
                                                                        00481000
      ***************************************************************** 00482119
      *   COPY PER I TRACCIATI DI INPUT.                              * 00482219
      ***************************************************************** 00482319
           COPY ARRAC020.                                               00483004
      *                                                                 00484000
           COPY ARRAC021.                                               00485004
      *                                                                 00485104
           COPY ARRAC022.                                               00485204
      *                                                                 00485304
           COPY ARRAC023.                                               00485404
      ***************************************************************** 00485551
      *   COPY PER L' ACCESSO ALL' ANAGRAFE                           * 00485699
      ***************************************************************** 00485751
      *                                                                 00485899
       01  ACS108-AREA.                                                 00485999
           COPY ACS108A.                                                00486099
      ***************************************************************** 00506919
      *   COPY PER IL TRACCIATO DI STAMPA                             * 00507019
      ***************************************************************** 00507119
           COPY STAMPAC.                                                00507219
      *                                                                 00507313
        COPY DYNACALL.                                                  00507413
      *_________________________________________________________________00507700
      *     CAMPI    DI   WORKING   PER    GESTIONE    ABEND            00507800
      *_________________________________________________________________00507900
      *                                                                 00508000
       77  COMP-CODE                PIC S9(04) COMP VALUE +5555.        00508100
      *                                                                 00508200
       01  W-PROGRAM                PIC X(08)  VALUE SPACES.            00508300
      *_________________________________________________________________00508400
      *     CAMPI    DI   WORKING   PER    GESTIONE    ANOMALIA         00508500
      *_________________________________________________________________00508600
      *                                                                 00508700
       01  W-CONTROLLO              PIC 9 VALUE ZERO.                   00509000
      *                                                                 00509100
       01  W-FLAG-ELA               PIC X(01).                          00509200
      *                                                                 00509300
       01  R-CODE                   PIC 9(09) VALUE 0.                  00509400
      *                                                                 00509500
       01  W-SQLCODE                PIC 9(3) VALUE 0.                   00509600
      *                                                                 00510000
       01  CTR-REC-TOT              PIC 9(07) VALUE 0.                  00520000
      *                                                                 00520104
       01  CTR-REC-TOT-SCRITTI      PIC 9(07) VALUE 0.                  00520105
      *                                                                 00520106
       01  CTR-REC-TOT1             PIC 9(07) VALUE 0.                  00520204
      *                                                                 00521000
       01  W-COMODO                 PIC 9(02) VALUE 0.                  00522000
      *                                                                 00523004
       01  W-COMODO1                PIC 9(02) VALUE 0.                  00524004
      *                                                                 00530000
       01  W-N-REC-TOT              PIC 9(07) VALUE 0.                  00540000
      *                                                                 00541004
       01  W-N-REC-TOT1             PIC 9(07) VALUE 0.                  00542004
      *                                                                 00550000
       01  W-STAT00                 PIC X(02) VALUE SPACES.             00661000
      *                                                                 00662004
       01  W-STAT01                 PIC X(02) VALUE SPACES.             00663004
      *                                                                 01520000
       01  W-STAT02                 PIC X(02) VALUE SPACES.             01520217
      *                                                                 01520317
       01  W-TTAR-PROGR             PIC 9(5) VALUE ZERO.                01521000
      *                                                                 01521117
       01  W-CONTR                  PIC 9(2) VALUE 57.                  01521268
      *                                                                 01521568
       01  W-MAXR-47                PIC 9(2) VALUE 47.                  01521681
      *                                                                 01521768
       01  W-MAXR-52                PIC 9(2) VALUE 52.                  01521868
      *                                                                 01521968
       01  W-MAXR-62                PIC 9(2) VALUE 62.                  01522068
      *                                                                 01522168
       01  W-CONT-SCART             PIC 9(2) VALUE ZERO.                01522268
      *                                                                 01522368
       01  WS-PAG                   PIC 9(3) VALUE ZERO.                01522468
      *                                                                 01522568
       01  WS-IMPORTO-EUR           PIC ---.---.---.--9,999.            01522699
      *                                                                 01522799
       01  WS-IMPORTO               PIC ---.---.---.--9.                01522899
      *                                                                 01522999
       01  WS-SALDO-EUR             PIC ZZZ.ZZZ.ZZZ.ZZ9,999.            01523099
      *                                                                 01523199
       01  WS-SALDO                 PIC ZZZ.ZZZ.ZZZ.ZZ9.                01523299
      *                                                                 01523399
       01  WS-CONTA-RIGHE           PIC 9(02) VALUE ZERO.               01523499
      *                                                                 01523599
       01  WS-INDICE-RIGA           PIC 9(02) VALUE ZERO.               01523699
      *                                                                 01523799
       01  WS-IND                   PIC 9(02) VALUE ZERO.               01523800
      *                                                                 01523810
       01  WS-SCRIVI-SALDI          PIC 9(01) VALUE ZERO.               01523899
      *                                                                 01523999
       01  WS-SCRIVI-MOV            PIC 9(01) VALUE ZERO.               01524099
      *                                                                 01524199
       01  IND1                     PIC S9(4) COMP.                     01524299
      *                                                                 01525096
       01  WS-ACS108                PIC 9(03) VALUE ZERO.               01526099
      *                                                                 01527099
       01  WS-ACS108-INT-RIDOTTA    PIC X(35) VALUE SPACES.             01528099
      *                                                                 01528199
       01  WS-ACS108-RAGSOC         PIC X(40) VALUE SPACES.             01528299
      *                                                                 01529099
       01  W-DATA-ELAB.                                                 01530000
           03  W-DATA-ELAB-AA   PIC 9(04).                              01540000
           03  W-DATA-ELAB-MM   PIC 9(02).                              01550000
           03  W-DATA-ELAB-GG   PIC 9(02).                              01560000
      *                                                                 01560199
       01  W-DATA-ELAB-RED REDEFINES W-DATA-ELAB PIC 9(08).             01560299
      *                                                                 01560318
       01  WS-DT-STAMPA.                                                01560418
           03  WS-DT-STAMPA-AA  PIC 9(04).                              01560518
           03  WS-DT-STAMPA-MM  PIC 9(02).                              01560618
           03  WS-DT-STAMPA-GG  PIC 9(02).                              01560718
      *                                                                 01560818
       01  W-ARRAC020.                                                  01561008
           10 W-ARRAC020-TIPO-REC      PIC  X(02).                      01562008
           10 W-ARRAC020-NDG           PIC  X(12).                      01563086
           10 W-ARRAC020-SERVIZIO      PIC  X(03).                      01564086
           10 W-ARRAC020-CATEGORIA     PIC  X(04).                      01565086
           10 W-ARRAC020-FILIALE       PIC  X(05).                      01566086
           10 W-ARRAC020-NUMERO        PIC  9(12).                      01567086
           10 W-ARRAC020-SEGNO         PIC  X(01).                      01567108
           10 W-ARRAC020-UTILIZZO-FIDO PIC  9(12)V9(3).                 01568008
           10 W-ARRAC020-DIVISA        PIC  X(03).                      01569008
           10 W-ARRAC020-DT-VAL        PIC  9(08).                      01569108
      *                                                                 01569209
       01  W-ARRAC021.                                                  01569309
           10 W-ARRAC021-TIPO-REC      PIC  X(02).                      01569409
           10 W-ARRAC021-NDG           PIC  X(12).                      01569686
           10 W-ARRAC021-SERVIZIO      PIC  X(03).                      01569786
           10 W-ARRAC021-CATEGORIA     PIC  X(04).                      01569886
           10 W-ARRAC021-FILIALE       PIC  X(05).                      01569986
           10 W-ARRAC021-NUMERO        PIC  9(12).                      01570086
           10 W-ARRAC021-SALDO-PPREN   PIC  9(12)V9(3).                 01570109
           10 W-ARRAC021-DIVISA        PIC  X(03).                      01570209
           10 W-ARRAC021-IMPORTO-AFF   PIC  9(12)V9(3).                 01570309
           10 W-ARRAC021-COD-ANOM      PIC  X(02).                      01570409
      *                                                                 01570509
       01  W-ARRAC022.                                                  01570609
           10 W-ARRAC022-TIPO-REC        PIC  X(02).                    01570726
           10 W-ARRAC022-DT-INVIO-FLUSSO PIC  9(08).                    01570826
           10 W-ARRAC022-PROGR           PIC  9(05).                    01570909
           10 W-ARRAC022-N-REC-TOT       PIC  9(07).                    01571009
           10 W-ARRAC022-TOT-SALDI-ITL   PIC  9(12)V9(3).               01571309
           10 W-ARRAC022-TOT-SALDI-EUR   PIC  9(12)V9(3).               01571509
      *                                                                 01571709
       01  W-ARRAC023.                                                  01571809
           10 W-ARRAC023-TIPO-REC     PIC  X(02).                       01571909
           10 W-ARRAC023-DT-INVIO     PIC  9(08).                       01572009
           10 W-ARRAC023-PROGR        PIC  9(05).                       01572109
           10 W-ARRAC023-N-REC-TOT    PIC  9(07).                       01572209
           10 W-ARRAC023-SALDID-ITL   PIC  9(12)V9(3).                  01572309
           10 W-ARRAC023-SALDIA-ITL   PIC  9(12)V9(3).                  01572409
           10 W-ARRAC023-SALDID-EUR   PIC  9(12)V9(3).                  01572509
           10 W-ARRAC023-SALDIA-EUR   PIC  9(12)V9(3).                  01572609
      *                                                                 01573009
      *---------------------------------------------------------------* 01580000
027500*      INCLUDE  TABELLE  DB2                                    * 01590000
027600*---------------------------------------------------------------* 01600000
027700*                                                                 01610000
028202     EXEC  SQL  INCLUDE  SQLCA     END-EXEC.                      01630000
028203     EXEC  SQL  INCLUDE  SCTBTTAR  END-EXEC.                      01650000
028203     EXEC  SQL  INCLUDE  SCTBTANO  END-EXEC.                      01660025
028203     EXEC  SQL  INCLUDE  SCTBTDAT  END-EXEC.                      01670099
028209                                                                  01680000
       PROCEDURE DIVISION.                                              01790000
      *_________________________________________________________________01800000
      *                                                                 01810000
DEBU       DISPLAY 'INIZIO PGM ARRAB050'                                01820099
      *                                                                 01821000
           PERFORM  INIZIO   THRU  INIZIO-EX.                           01830007
                                                                        01840000
           PERFORM 08000-LEGGO-INPUT THRU 08000-EX.                     01840107
      *                                                                 01840700
           PERFORM 00100-CONTROLLO1 THRU 00100-EX                       01841207
            UNTIL W-STAT00 NOT = '00' AND W-STAT01 NOT = '00'.          01841333
      *                                                                 01842100
           PERFORM 88888-CHIUDI-FILES THRU  88888-EX.                   01842807
      *                                                                 01842900
           PERFORM 08050-APRI-FILES THRU  08050-EX.                     01843019
      *                                                                 01843315
           PERFORM 00110-CONTROLLO2 THRU 00110-EX.                      01843415
      *                                                                 01843607
           PERFORM  88888-CHIUDI-FILES THRU  88888-EX.                  01861007
      *                                                                 01862000
           PERFORM 08050-APRI-FILES THRU  08050-EX.                     01863019
      *                                                                 01864015
           PERFORM 00080-LEGGO-TESTA-ANOMALI THRU 00080-EX.             01864236
           PERFORM 00090-LEGGO-TESTA-SCARTI THRU 00090-EX.              01864337
           PERFORM 00109-LEGGO-ANOMALI THRU 00109-EX.                   01864439
           PERFORM 00111-LEGGO-SCARTI THRU 00111-EX.                    01864640
      *                                                                 01864715
           PERFORM 08100-APRI-STAMPA THRU 08100-EX.                     01865015
      *                                                                 01865115
           PERFORM 08150-PREPARA-STAMPA THRU 08150-EX                   01865215
            UNTIL W-STAT00  NOT = '00' AND W-STAT01  NOT = '00'.        01865357
      *                                                                 01866015
           IF CTR-REC-TOT-SCRITTI = 0                                   01866016
              PERFORM 00000-INTESTAZIONE-VUOTA THRU 00000-EX            01866017
           END-IF.                                                      01866018
                                                                        01866019
           PERFORM 08250-CHIUDI-STAMPA THRU 08250-EX.                   01866115
      *                                                                 01866215
           PERFORM  88888-CHIUDI-FILES THRU  88888-EX.                  01867015
      *                                                                 01881000
           DISPLAY '**************************************************'.01881199
           DISPLAY '*        FINE ELABORAZIONE PGM ARRAB050          *'.01881299
           DISPLAY '**************************************************'.01881399
DEBU       DISPLAY '*RECORD LETTI                                    *'.01882099
DEBU       DISPLAY '*  SU SALDI ANOMALI_______: ' CTR-REC-TOT           01882199
      -            '              *'.                                   01882299
DEBU       DISPLAY '*  SU MOVIMENTI SCARTATI__: ' CTR-REC-TOT1          01883099
      -            '              *'.                                   01883199
DEBU       DISPLAY '*RECORD PRESENTI                                 *'.01884099
DEBU       DISPLAY '*  SU SALDI ANOMALI_______: ' W-N-REC-TOT           01884199
      -            '              *'.                                   01884299
DEBU       DISPLAY '*  SU MOVIMENTI SCARTATI__: ' W-N-REC-TOT1          01885099
      -            '              *'.                                   01885199
DEBU       DISPLAY '*  SCRITTI IN STAMPA______: ' CTR-REC-TOT-SCRITTI   01885200
      -            '              *'.                                   01885300
           DISPLAY '**************************************************'.01886099
       FINE-PROGRAMMA.                                                  01890000
DEBU       DISPLAY 'FINE  PGM ARRAB050' .                               01891099
           STOP RUN.                                                    01900000
                                                                        01910000
      ***************************************************************** 01920064
      * ROUTINE DI INIZIO PROGHRAMMA COMPRENDENTE:                    * 01921064
      * 1) ACCETTAZIONE DELLA DATA DI SISTEMA;                        * 01921164
      * 2) APERTURA DEI DATASET DI INPUT.                             * 01921264
      ***************************************************************** 01922064
       INIZIO.                                                          01930000
                                                                        01940000
130900*    MOVE FUNCTION CURRENT-DATE(1:8)  TO W-DATA-ELAB              01950099
           PERFORM 00950-CERCA-DATA THRU 00950-EX.                      01951099
                                                                        01960000
           PERFORM 08050-APRI-FILES THRU  08050-EX.                     01970019
                                                                        02140000
       INIZIO-EX. EXIT.                                                 02150000
                                                                        02160000
      ***************************************************************** 02160164
      *  ROUTINE DI APERTURA DEI DATASET DI INPUT                     * 02160264
      ***************************************************************** 02160364
       08050-APRI-FILES.                                                02161019
           PERFORM 30000-APRI-ANOMALI   THRU  30000-EX.                 02161215
           PERFORM 31000-APRI-SCARTATI  THRU  31000-EX.                 02161315
       08050-EX.                                                        02161419
           EXIT.                                                        02161515
      ***************************************************************** 02162064
      *  ROUTINE DI CHIUSURA DEI DATASET DI INPUT                     * 02162164
      ***************************************************************** 02162264
       88888-CHIUDI-FILES.                                              02162364
                                                                        02162464
           PERFORM 20000-CHIUDI-ANOMALI   THRU  20000-EX.               02162664
           PERFORM 21000-CHIUDI-SCARTATI  THRU  21000-EX.               02162764
                                                                        02163000
       88888-EX. EXIT.                                                  02163100
                                                                        02163200
      ***************************************************************** 02163364
      *  LETTURA RECORD DI TESTA PER LEGGERE IL NUMERO TOTALE DEI     * 02163464
      *  RECORDS CONTENUTI NEL FILE DEI SALDI ANOMALI                 * 02163564
      ***************************************************************** 02163664
       00080-LEGGO-TESTA-ANOMALI.                                       02163703
      *                                                                 02163800
           READ  FILE63 INTO ARRAC022.                                  02164099
           IF  W-STAT00 NOT = '00' AND NOT = '10'                       02164200
DEBU           DISPLAY 'ERRORE LETTURA FILE INPUT FILE63 ' W-STAT00     02164399
DEBU           DISPLAY 'W-STAT00 : ' W-STAT00                           02164499
DEBU           DISPLAY 'LABEL 00080-LEGGO-TESTA-ANOMALI'                02164599
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  02164600
           END-IF.                                                      02164700
      *                                                                 02164800
181000     IF W-STAT00 = '10'                                           02165599
181000         DISPLAY 'FILE DEI SALDI ANOMALI VUOTO'                   02165699
181000         MOVE 4 TO RETURN-CODE                                    02165799
181000         GO TO 00080-EX                                           02165899
181000     END-IF.                                                      02165999
      *                                                                 02166099
       00080-EX.                                                        02168503
             EXIT.                                                      02168600
      ***************************************************************** 02168764
      *  LETTURA RECORD DI TESTA PER LEGGERE IL NUMERO TOTALE DEI     * 02168864
      *  RECORDS CONTENUTI NEL FILE DEI MOVIMENTI SCARTATI            * 02168964
      ***************************************************************** 02169064
       00090-LEGGO-TESTA-SCARTI.                                        02169103
      *                                                                 02169203
           READ  FILE62 INTO ARRAC023.                                  02169499
           IF  W-STAT01 NOT = '00' AND NOT = '10'                       02169603
DEBU           DISPLAY 'ERRORE LETTURA FILE INPUT FILE62' W-STAT01      02169799
DEBU           DISPLAY 'W-STAT01 : ' W-STAT01                           02169899
DEBU           DISPLAY 'LABEL 00090-LEGGO-TESTA-SCARTI'                 02169999
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  02170003
           END-IF.                                                      02170103
      *                                                                 02170203
181000     IF W-STAT01 = '10'                                           02170399
181000         DISPLAY 'FILE DEI MOVIMENTI SCARTATI VUOTO'              02170499
181000         MOVE 4 TO RETURN-CODE                                    02170599
181000         GO TO FINE-PROGRAMMA                                     02170699
181000     END-IF.                                                      02170799
      *                                                                 02172403
181000     IF RETURN-CODE = 4                                           02172599
181000        GO TO FINE-PROGRAMMA                                      02172699
181000     END-IF.                                                      02172799
      *                                                                 02172899
       00090-EX.                                                        02172903
             EXIT.                                                      02173003
      ***************************************************************** 02173164
      *PERFORM DI CONTROLLO PER VERIFICARE IL NUMERO TOTALE DEI RECORD* 02173264
      *DI DETTAGLIO CONTENUTI NEI DATASET DI INPUT                    * 02173364
      ***************************************************************** 02173464
       00100-CONTROLLO1.                                                02173503
      *                                                                 02173603
           IF W-STAT00 NOT = '10'                                       02173604
              PERFORM 00105-LEGGI-ANOMALI THRU 00105-EX                 02173832
           END-IF.                                                      02173833
      *                                                                 02173910
           IF W-STAT01 NOT = '10'                                       02173920
             PERFORM 00106-LEGGI-SCARTI  THRU 00106-EX                  02174032
           END-IF.                                                      02174033
      *                                                                 02175010
       00100-EX.                                                        02178803
             EXIT.                                                      02178903
      ***************************************************************** 02179064
      * ROUTINE DI LETTURA DEL FILE DI INPUT DEI SALDI ANOMALI PER VE-* 02179164
      * RIFICARE IL NUMERO EFFETTIVO DI RECORD DI DETTAGLIO CONTENUTI * 02179264
      ***************************************************************** 02179364
       00105-LEGGI-ANOMALI.                                             02179464
           READ  FILE63 INTO ARRAC021                                   02179699
                 AT END GO TO 00105-EX.                                 02179764
      *                                                                 02179864
           IF W-STAT00 = '10'                                           02179964
DEBU          DISPLAY 'NON CI SONO RECORD DA ELABORARE '                02180099
              GO TO 00105-EX                                            02180164
           END-IF.                                                      02180264
      *                                                                 02180364
160702*    IF W-STAT00 = '46'                                           02180464
160702*       GO TO 00105-EX                                            02180564
160702*    END-IF.                                                      02180664
                                                                        02180665
      *                                                                 02180764
160702*    IF W-STAT00 NOT EQUAL '00' AND '10' AND '46'                 02180864
160702     IF W-STAT00 NOT EQUAL '00' AND '10'                          02180865
DEBU          DISPLAY 'ERRORE ' W-STAT00 'SU LETTURA FILE63'            02180999
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     02181064
           END-IF.                                                      02181164
      *                                                                 02181264
           IF  ARRAC021-TIPO-REC    = '63'                              02181364
               ADD 1 TO CTR-REC-TOT                                     02181503
           ELSE                                                         02181603
DEBU           DISPLAY                                                  02181799
DEBU                 'TIPO RECORD NON PREVISTO: ' ARRAC021-TIPO-REC     02181899
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  02181903
           END-IF.                                                      02182003
      *                                                                 02182103
           MOVE ARRAC021-TIPO-REC  TO  W-COMODO.                        02182208
           MOVE ARRAC021-TIPO-REC  TO  W-ARRAC021-TIPO-REC.             02182308
       00105-EX.                                                        02183103
           EXIT.                                                        02183203
      ***************************************************************** 02183364
      * ROUTINE DI LETTURA DEL FILE DI INPUT DEI SALDI ANOMALI DA STA-* 02183464
      * MPARE                                                         * 02183564
      ***************************************************************** 02183664
       00109-LEGGO-ANOMALI.                                             02183790
           READ  FILE63 INTO ARRAC021                                   02183999
                 AT END MOVE 999999999999 TO W-ARRAC021-NUMERO          02184064
                        MOVE '10'         TO W-STAT00.                  02184065
                                                                        02184165
           IF W-STAT00 = '10'                                           02184264
              IF W-ARRAC021-NUMERO NOT = 999999999999                   02184265
DEBU             DISPLAY 'NON CI SONO RECORD DA ELABORARE PER I SALDI'  02184266
              END-IF                                                    02184268
              GO TO 00109-EX                                            02184464
           END-IF.                                                      02184564
      *                                                                 02184639
           IF W-STAT00 NOT EQUAL '00' AND '10'                          02184739
DEBU          DISPLAY 'ERRORE ' W-STAT00 'SU LETTURA FILE63'            02184899
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     02184939
           END-IF.                                                      02185039
      *                                                                 02185142
           MOVE SPACE              TO  L-ACS108-ARG.                    02185299
           MOVE ZERO               TO  L-ACS108-I-BANCA.                02185399
           MOVE ZERO               TO  L-ACS108-I-DATA-RIF.             02185499
           MOVE ' '                TO  L-ACS108-I-TIPO-RICH.            02185599
           MOVE ARRAC021-NDG       TO  W-ARRAC021-NDG                   02185699
                                       L-ACS108-I-NDG.                  02185799
           MOVE ARRAC021-SERVIZIO  TO  W-ARRAC021-SERVIZIO              02185899
                                       L-ACS108-I-SERVIZIO.             02185999
           MOVE ARRAC021-CATEGORIA TO  W-ARRAC021-CATEGORIA             02186099
                                       L-ACS108-I-CATEGORIA.            02186199
           MOVE ARRAC021-FILIALE   TO  W-ARRAC021-FILIALE               02186299
                                       L-ACS108-I-FILIALE.              02186399
           MOVE ARRAC021-NUMERO    TO  W-ARRAC021-NUMERO                02186499
                                       L-ACS108-I-NUMERO.               02186599
           PERFORM 00220-ACCESSO-ANAG THRU 00220-ACCESSO-ANAG-EX.       02186699
           ADD 1                   TO  WS-ACS108.                       02186799
           IF WS-ACS108 = 1                                             02186999
              MOVE L-ACS108-INT-RIDOTTA TO WS-ACS108-INT-RIDOTTA        02187099
              MOVE L-ACS108-RAGSOC-1    TO WS-ACS108-RAGSOC             02187199
           END-IF.                                                      02187299
           PERFORM 08300-CERCA-DESCR THRU 08300-EX.                     02187339
       00109-EX.                                                        02187439
           EXIT.                                                        02187539
      ***************************************************************** 02187664
      * ROUTINE DI LETTURA DEL FILE DI INPUT DEI MOVIMENTI SCARTATI   * 02187764
      * PER VERIFICARE IL NUMERO DI RECORD DI DETTAGLIO CONTENUTI     * 02187864
      ***************************************************************** 02187964
       00106-LEGGI-SCARTI.                                              02188064
           READ  FILE62 INTO ARRAC020                                   02188199
                 AT END GO TO 00106-EX.                                 02188264
      *                                                                 02188364
           IF W-STAT01 = '10'                                           02188464
DEBU          DISPLAY 'NON CI SONO RECORD DA ELABORARE '                02188599
              GO TO 00106-EX                                            02188664
           END-IF.                                                      02188764
      *                                                                 02188885
160702*    IF W-STAT01 = '46'                                           02188985
160702*       GO TO 00106-EX                                            02189085
160702*    END-IF.                                                      02189185
      *                                                                 02189285
           IF W-STAT01 NOT EQUAL '00' AND '10'                          02189385
DEBU          DISPLAY 'ERRORE ' W-STAT01 'SU LETTURA FILE62'            02189499
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     02189585
           END-IF.                                                      02189685
      *                                                                 02189785
           IF  ARRAC020-TIPO-REC    = '62'                              02189885
               ADD 1 TO CTR-REC-TOT1                                    02189985
           ELSE                                                         02190085
DEBU           DISPLAY                                                  02190199
DEBU                 'TIPO RECORD NON PREVISTO: ' ARRAC020-TIPO-REC     02190299
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  02190385
           END-IF.                                                      02190485
      *                                                                 02190585
           MOVE ARRAC020-TIPO-REC  TO  W-COMODO1.                       02190685
           MOVE ARRAC020-TIPO-REC  TO  W-ARRAC020-TIPO-REC.             02190785
       00106-EX.                                                        02190885
           EXIT.                                                        02191039
      ***************************************************************** 02192064
      * ROUTINE DI LETTURA DEL FILE DI INPUT DEI MOVIMENTI SCARTATI DA* 02192164
      * STAMPARE                                                      * 02192264
      ***************************************************************** 02192364
       00111-LEGGO-SCARTI.                                              02192464
           READ  FILE62 INTO ARRAC020                                   02192699
160702*          AT END MOVE '10' TO W-STAT01.                          02192864
160702           AT END MOVE 999999999999 TO W-ARRAC020-NUMERO          02192865
                        MOVE '10' TO W-STAT01.                          02192964
           IF W-STAT01 = '10'                                           02193064
160702        GO TO 00111-EX                                            02193065
160702*       PERFORM 00107-STAMPA-ANOMALI THRU 00107-EX                02193264
160702*       GO TO 00111-EX                                            02193364
           END-IF.                                                      02193464
      *                                                                 02193556
           IF W-STAT01 NOT EQUAL '00' AND '10'                          02193657
DEBU          DISPLAY 'ERRORE ' W-STAT01 'SU LETTURA FILE62'            02193799
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     02193856
           END-IF.                                                      02193956
      *                                                                 02194056
           MOVE SPACE              TO  L-ACS108-ARG.                    02194199
           MOVE ZERO               TO  L-ACS108-I-BANCA.                02194299
           MOVE ZERO               TO  L-ACS108-I-DATA-RIF.             02194399
           MOVE ' '                TO  L-ACS108-I-TIPO-RICH.            02194499
           MOVE ARRAC020-NDG       TO  W-ARRAC020-NDG                   02194599
                                       L-ACS108-I-NDG.                  02194699
           MOVE ARRAC020-SERVIZIO  TO  W-ARRAC020-SERVIZIO              02194799
                                       L-ACS108-I-SERVIZIO.             02194899
           MOVE ARRAC020-CATEGORIA TO  W-ARRAC020-CATEGORIA             02194999
                                       L-ACS108-I-CATEGORIA.            02195099
           MOVE ARRAC020-FILIALE   TO  W-ARRAC020-FILIALE               02195199
                                       L-ACS108-I-FILIALE.              02195299
           MOVE ARRAC020-NUMERO    TO  W-ARRAC020-NUMERO                02195399
                                       L-ACS108-I-NUMERO.               02195499
           PERFORM 00220-ACCESSO-ANAG THRU 00220-ACCESSO-ANAG-EX.       02195599
       00111-EX.                                                        02195639
           EXIT.                                                        02195739
      ***************************************************************** 02195864
      * ROUTINE PER LA VERIFICA DELLA CONGRUENZA TRA IL TOTALE DEI RE-* 02195964
      * CORD DICHIARATI NEL RECORD DI TESTA E IL TOTALE EFFETTIVO DEI * 02196064
      * RECORD PRESENTI (RECORD DI DETTAGLIO + RECORD DI TESTA)       * 02196164
      ***************************************************************** 02196264
       00110-CONTROLLO2.                                                02196364
      *                                                                 02196464
           IF CTR-REC-TOT  NOT GREATER 1                                02196564
DEBU          DISPLAY 'IL FILE DEI SALDI ANOMALI CONTIENE SOLO IL RECORD02196699
DEBU  -        ' DI TESTA'                                              02196799
           END-IF.                                                      02196864
      *                                                                 02196964
           IF CTR-REC-TOT1 NOT GREATER 1                                02197064
DEBU          DISPLAY 'IL FILE DEI MOVIMENTI SCARTATI CONTIENE SOLO IL R02197199
DEBU  -        'ECORD DI TESTA'                                         02197299
           END-IF.                                                      02197364
      *                                                                 02197464
           IF W-N-REC-TOT  = CTR-REC-TOT                                02197664
              CONTINUE                                                  02197764
           ELSE                                                         02197864
              DISPLAY '00110-CONTROLLO2'                                02197964
              DISPLAY 'NON C''E'' CORRISPONDENZA TRA IL TOTALE DEI'     02198099
              DISPLAY 'RECORD DEL TAPPO E IL NUMERO EFFETIVO DEI RECORD'02198199
              DISPLAY 'DI DETTAGLIO'                                    02198299
              PERFORM 20000-CHIUDI-ANOMALI  THRU 20000-EX               02198364
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     02198464
           END-IF.                                                      02198564
      *                                                                 02198664
           IF W-N-REC-TOT1  = CTR-REC-TOT1                              02198964
              GO TO 00110-EX                                            02199064
           ELSE                                                         02199164
              DISPLAY '00110-CONTROLLO2'                                02199264
              DISPLAY 'NON C''E'' CORRISPONDENZA TRA IL TOTALE DEI'     02199399
              DISPLAY 'RECORD DEL TAPPO E IL NUMERO EFFETIVO DEI RECORD'02199499
              DISPLAY 'DI DETTAGLIO'                                    02199599
              PERFORM 21000-CHIUDI-SCARTATI THRU 21000-EX               02199964
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     02200064
           END-IF.                                                      02200164
      *                                                                 02200264
       00110-EX.                                                        02200364
             EXIT.                                                      02200464
      ***************************************************************** 02200564
      * PERFORM DI RICERCA DEL NUMERO PROGRESSIVO SULLA TABELLA TTAR  * 02200664
      ***************************************************************** 02200764
       00120-CONTROLLA-TTAR.                                            02200864
190900*    MOVE W-COMODO TO TTAR-TIP-REC.                               02200999
           EXEC SQL INCLUDE TAR001SM END-EXEC.                          02201064
           MOVE SQLCODE TO W-SQLCODE.                                   02201164
           IF W-SQLCODE = 0                                             02201264
              MOVE TTAR-PROGR TO W-TTAR-PROGR                           02201364
              COMPUTE W-TTAR-PROGR = W-TTAR-PROGR + 1                   02202064
              PERFORM 00130-CONTROLLA-PROGR THRU 00130-EX               02210000
              GO TO 00120-EX                                            02211000
           END-IF.                                                      02220000
           IF W-SQLCODE = 100                                           02230000
              DISPLAY 'LABEL 00120-CONTROLLA-TTAR'                      02230199
              DISPLAY 'OCCORRENZA NON TROVATA SU TABELLA TTAR'          02230299
              GO TO 00120-EX                                            02251000
           END-IF.                                                      02252000
           IF W-SQLCODE NOT EQUAL 0 AND 100                             02253000
              DISPLAY 'LABEL 00120-CONTROLLA-TTAR'                      02254000
              DISPLAY 'ERRORE SQL = ' W-SQLCODE ' SU SCTBTTAR'          02254100
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     02254200
           END-IF.                                                      02254300
       00120-EX.                                                        02254400
           EXIT.                                                        02254500
      ***************************************************************** 02254664
      * ROUTINE DI CONTROLLO PER VERIFICARE LA CONGRUENZA TRA IL PRO- * 02254764
      * GRESSIVO CONTENUTO NEL RECORD DI TESTA DEI DATASET DI INPUT E * 02254864
      * IL PROGRESSIVO DELLA TABELLA TTAR INCREMENTATO DI 1           * 02254964
      ***************************************************************** 02255064
       00130-CONTROLLA-PROGR.                                           02255164
           IF W-ARRAC022-PROGR = W-ARRAC023-PROGR                       02255364
            AND W-ARRAC022-PROGR = W-TTAR-PROGR                         02255464
              MOVE '63'                   TO TTAR-TIP-REC               02255699
              MOVE W-N-REC-TOT            TO TTAR-N-REC-TOT             02255799
              MOVE ARRAC022-TOT-SALDI-ITL TO TTAR-SALDID-ITL            02255899
              MOVE ZEROES                 TO TTAR-SALDIA-ITL            02255999
              MOVE ARRAC022-TOT-SALDI-EUR TO TTAR-SALDID-EUR            02256099
              MOVE ZEROES                 TO TTAR-SALDIA-EUR            02256199
              PERFORM 25000-INSERISCI-TTAR THRU 25000-EX                02256299
              MOVE '62'                   TO TTAR-TIP-REC               02256599
              MOVE W-N-REC-TOT1           TO TTAR-N-REC-TOT             02256699
              MOVE ARRAC023-TOT-DARE-ITL  TO TTAR-SALDID-ITL            02256799
              MOVE ARRAC023-TOT-AVERE-ITL TO TTAR-SALDIA-ITL            02256899
              MOVE ARRAC023-TOT-DARE-EUR  TO TTAR-SALDID-EUR            02256999
              MOVE ARRAC023-TOT-AVERE-EUR TO TTAR-SALDIA-EUR            02257099
              PERFORM 25000-INSERISCI-TTAR THRU 25000-EX                02257199
              GO TO 00130-EX                                            02257399
           ELSE                                                         02257407
DEBU          DISPLAY 'PROGRESSIVO TABELLA = ' W-TTAR-PROGR             02257599
DEBU          DISPLAY 'PROGRESSIVO FLUSSO SALDI = ' W-ARRAC022-PROGR    02258099
DEBU          DISPLAY 'PROGRESSIVO FLUSSO MOVIMENTI = ' W-ARRAC023-PROGR02258199
              DISPLAY 'DISCONTINUITA'' SU INVIO FLUSSO'                 02259007
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     02259107
           END-IF.                                                      02259207
       00130-EX.                                                        02259307
           EXIT.                                                        02259407
      ***************************************************************** 02282099
      * ROUTINE DI CHIUSURA DEL FILE DEI SALDI ANOMALI                * 02290064
      ***************************************************************** 02300064
       20000-CHIUDI-ANOMALI.                                            06195105
           CLOSE FILE63.                                                06195399
           IF  W-STAT00  NOT = '00'                                     06195400
               DISPLAY 'ERRORE CHIUSURA FILE63 ' W-STAT00               06195599
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  06195600
           END-IF.                                                      06195700
       20000-EX. EXIT.                                                  06195800
      ***************************************************************** 06195964
      * ROUTINE DI CHIUSURA DEL FILE DEI MOVIMENTI SCARTATI           * 06196064
      ***************************************************************** 06196164
       21000-CHIUDI-SCARTATI.                                           06196264
           CLOSE FILE62.                                                06196499
           IF  W-STAT01  NOT = '00'                                     06196564
               DISPLAY 'ERRORE CHIUSURA FILE62 ' W-STAT01               06196699
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  06196764
           END-IF.                                                      06196864
       21000-EX. EXIT.                                                  06196964
      ***************************************************************** 06197064
      * ROUTINE DI APERTURA DEL FILE DEI SALDI ANOMALI                * 06197164
      ***************************************************************** 06197264
       30000-APRI-ANOMALI.                                              06197364
           OPEN  INPUT  FILE63.                                         06197599
           IF  W-STAT00  NOT = '00'                                     06197664
               DISPLAY 'ERRORE APERTURA FILE63 ' W-STAT00               06197799
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  06197864
           END-IF.                                                      06197964
       30000-EX. EXIT.                                                  06198064
      ***************************************************************** 06198164
      * ROUTINE DI APERTURA DEL FILE DEI MOVIMENTI SCARTATI           * 06198264
      ***************************************************************** 06198364
       31000-APRI-SCARTATI.                                             06198464
           OPEN  INPUT  FILE62.                                         06198699
           IF  W-STAT01  NOT = '00'                                     06198764
               DISPLAY 'ERRORE APERTURA FILE62 ' W-STAT01               06198899
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  06198964
           END-IF.                                                      06199001
       31000-EX. EXIT.                                                  06200001
      ***************************************************************** 06202164
      * ROUTINE DI GESTIONE ABEND                                     * 06202264
      ***************************************************************** 06202364
064100 GEST-ABEND.                                                      06202464
064200                                                                  06203000
064310     MOVE   'ILBOABN0'  TO  W-PROGRAM.                            06210000
064400                                                                  06220000
064500     CALL   W-PROGRAM  USING  COMP-CODE.                          06230000
064600                                                                  06240000
064700 EX-GEST-ABEND. EXIT.                                             06250000
      *-------------------------------------------------                06250100
      *-------------------------------------------------                06251000
      *-----  F I N E    P R O G R A M M A -------------                06252000
      *-------------------------------------------------                06253000
      *-------------------------------------------------                06255000
      ***************************************************************** 06255164
      * ROUTINE COMPRENDENTE LETTURA DEI DATASET DI INPUT E CONTROLLO * 06255264
      * DEL TIPO RECORD CONTENUTO                                     * 06255364
      ***************************************************************** 06255464
       08000-LEGGO-INPUT.                                               06256006
            PERFORM 00080-LEGGO-TESTA-ANOMALI THRU 00080-EX.            06256206
      *                                                                 06256306
            PERFORM 00090-LEGGO-TESTA-SCARTI  THRU 00090-EX.            06256506
      *                                                                 06256606
           IF  ARRAC022-TIPO-REC = '00' AND ARRAC023-TIPO-REC = '00'    06256708
               MOVE ARRAC022            TO  W-ARRAC022                  06256807
               MOVE ARRAC022-N-REC-TOT  TO  W-N-REC-TOT                 06256907
               MOVE ARRAC022-TIPO-REC   TO  W-COMODO                    06257099
               MOVE ARRAC022-PROGR      TO  W-ARRAC022-PROGR            06257199
               MOVE '63'                TO TTAR-TIP-REC                 06257299
190900*        PERFORM 00120-CONTROLLA-TTAR THRU 00120-EX               06257399
               MOVE 1 TO CTR-REC-TOT                                    06257407
               MOVE ARRAC023            TO  W-ARRAC023                  06257507
               MOVE ARRAC023-N-REC-TOT  TO  W-N-REC-TOT1                06257607
               MOVE ARRAC023-TIPO-REC   TO  W-COMODO1                   06257799
               MOVE 1 TO CTR-REC-TOT1                                   06257807
               MOVE ARRAC023-PROGR      TO  W-ARRAC023-PROGR            06257966
190900*        MOVE W-COMODO1 TO TTAR-TIP-REC                           06258099
               PERFORM 00120-CONTROLLA-TTAR THRU 00120-EX               06258166
               GO TO 08000-EX                                           06258207
           END-IF.                                                      06258307
      *                                                                 06258407
           IF ARRAC022-TIPO-REC NOT = '00'                              06258508
              DISPLAY 'ELABORAZIONE RIFIUTATA PER ASSENZA '             06258607
              DISPLAY 'REC. DI TESTA NEL FILE DI INPUT : FILE63'        06258799
              PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                   06258807
           END-IF.                                                      06258907
      *                                                                 06259007
           IF ARRAC023-TIPO-REC NOT = '00'                              06259108
              DISPLAY 'ELABORAZIONE RIFIUTATA PER ASSENZA '             06259207
              DISPLAY 'REC. DI TESTA NEL FILE DI INPUT : FILE62'        06259399
              PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                   06259407
           END-IF.                                                      06259507
       08000-EX.                                                        06259607
           EXIT.                                                        06260007
      ***************************************************************** 06260164
      * ROUTINE DI APERTURA DEL DATASET DI OUTPUT PER LA STAMPA       * 06260264
      ***************************************************************** 06260364
       08100-APRI-STAMPA.                                               06260464
           OPEN OUTPUT STAMPA.                                          06260664
           IF W-STAT02 NOT = '00' AND '10'                              06260764
              DISPLAY 'LABEL 08100-APRI-STAMPA'                         06260864
              DISPLAY 'ERRORE ' W-STAT02 ' SU APERTURA STAMPA'          06260964
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     06261064
           END-IF.                                                      06261164
       08100-EX.                                                        06261264
           EXIT.                                                        06261364
      ***************************************************************** 06262064
      * ROUTINE DI PREPARAZIONE DELLA STAMPA                          * 06263064
      ***************************************************************** 06264064
       08150-PREPARA-STAMPA.                                            06270015
           IF W-ARRAC021-NUMERO < W-ARRAC020-NUMERO                     06271287
              PERFORM 00107-STAMPA-ANOMALI THRU 00107-EX                06271586
              PERFORM 00109-LEGGO-ANOMALI  THRU 00109-EX                06271686
              MOVE 0 TO WS-SCRIVI-MOV                                   06271799
              GO TO 08150-EX                                            06271886
           END-IF.                                                      06271991
           IF W-ARRAC021-NUMERO > W-ARRAC020-NUMERO                     06272091
              PERFORM 00111-LEGGO-SCARTI THRU 00111-EX                  06272386
              GO TO 08150-EX                                            06273086
           END-IF.                                                      06274146
      *                                                                 06275015
           IF W-ARRAC021-NUMERO = W-ARRAC020-NUMERO                     06276087
              PERFORM 00108-STAMPA-SCARTATI THRU 00108-EX               06277016
              PERFORM 00111-LEGGO-SCARTI  THRU 00111-EX                 06278040
              GO TO 08150-EX                                            06279015
           END-IF.                                                      06279115
      *                                                                 06279215
       08150-EX.                                                        06280015
           EXIT.                                                        06290015
      ***************************************************************** 06291064
      * ROUTINE DI CHIUSURA DEL DATASET DI OUTPUT PER LA STAMPA       * 06292064
      ***************************************************************** 06293064
       08250-CHIUDI-STAMPA.                                             06300015
           CLOSE STAMPA.                                                06301015
           IF W-STAT02 NOT = '00' AND '10'                              06302015
              DISPLAY 'LABEL 08250-CHIUDI-STAMPA'                       06303015
              DISPLAY 'ERRORE ' W-STAT02 ' SU CHIUSURA STAMPA'          06304015
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     06305015
           END-IF.                                                      06306015
       08250-EX.                                                        06310015
           EXIT.                                                        06320015
      ***************************************************************** 06321064
      * ROUTINE DI STAMPA DEL RECORD DEI SALDI ANOMALI                * 06322064
      ***************************************************************** 06323064
       00107-STAMPA-ANOMALI.                                            06330015
           IF W-CONTR NOT LESS W-MAXR-52 AND NOT GREATER W-MAXR-62      06330399
              MOVE 0 TO W-CONTR                                         06330493
              PERFORM 10000-SCRIVI-INTEST THRU 10000-EX                 06330599
              PERFORM 10200-VAL-DETT-SALDI THRU 10200-EX                06330699
              MOVE 3 TO WS-CONTA-RIGHE                                  06334294
              PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                  06334394
               VARYING WS-INDICE-RIGA FROM 1 BY 1                       06334494
                UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                   06334594
              WRITE REC-SMOV FROM WS-DETT5-ST                           06334694
              ADD 1 TO CTR-REC-TOT-SCRITTI                              06334695
              MOVE 19 TO W-CONTR                                        06334794
              MOVE 1 TO WS-SCRIVI-MOV                                   06334899
           END-IF.                                                      06334996
           IF WS-SCRIVI-MOV = 0                                         06335199
              MOVE 2 TO WS-CONTA-RIGHE                                  06335296
              PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                  06335396
               VARYING WS-INDICE-RIGA FROM 1 BY 1                       06335496
                UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                   06335596
              WRITE REC-SMOV FROM WS-INTEST7                            06335696
              ADD 1 TO CTR-REC-TOT-SCRITTI                              06335697
              PERFORM 10200-VAL-DETT-SALDI THRU 10200-EX                06335799
              MOVE 2 TO WS-CONTA-RIGHE                                  06336895
              PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                  06336995
               VARYING WS-INDICE-RIGA FROM 1 BY 1                       06337095
                UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                   06337195
              WRITE REC-SMOV FROM WS-DETT5-ST                           06337295
              ADD 1 TO CTR-REC-TOT-SCRITTI                              06337296
              ADD 6 TO W-CONTR                                          06337395
           END-IF.                                                      06337693
           MOVE 5                    TO WS-CONTA-RIGHE.                 06337779
           PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                     06337863
            VARYING WS-INDICE-RIGA FROM 1 BY 1                          06337963
             UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE.                     06338063
           MOVE TANO-DESCR1          TO WS-DESCR-ST.                    06338199
           IF ARRAC021-DIVISA = 'ITL'                                   06338399
              MOVE ARRAC021-SALDO-PPREN TO WS-SALDO                     06338499
              MOVE WS-SALDO             TO WS-SALDO-ST                  06339099
           ELSE                                                         06339199
              MOVE ARRAC021-SALDO-PPREN TO WS-SALDO-EUR                 06339299
              MOVE WS-SALDO-EUR         TO WS-SALDO-ST                  06339399
           END-IF.                                                      06339499
           WRITE REC-SMOV FROM WS-INTEST6.                              06339549
           ADD 1 TO CTR-REC-TOT-SCRITTI.                                06339550
           MOVE 1 TO WS-SCRIVI-SALDI.                                   06339676
           ADD 6 TO W-CONTR.                                            06341079
       00107-EX.                                                        06342015
           EXIT.                                                        06350015
      ***************************************************************** 06360064
      * ROUTINE DI STAMPA DEL RECORD DEI MOVIMENTI SCARTATI           * 06361064
      ***************************************************************** 06362064
       00108-STAMPA-SCARTATI.                                           06370016
           MOVE ARRAC020-DT-VAL       TO WS-DT-STAMPA.                  06370418
           IF W-CONTR NOT LESS W-MAXR-52 AND NOT GREATER W-MAXR-62      06371168
              MOVE 0 TO WS-SCRIVI-SALDI                                 06371276
              PERFORM 10000-SCRIVI-INTEST THRU 10000-EX                 06380299
              PERFORM 10100-VALORIZZA-DETT THRU 10100-EX                06380399
              PERFORM 10050-SCRIVI-DETT THRU 10050-EX                   06381599
              MOVE 3 TO WS-CONTA-RIGHE                                  06381679
              PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                  06381748
               VARYING WS-INDICE-RIGA FROM 1 BY 1                       06381848
                UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                   06381948
              WRITE REC-SMOV FROM WS-DETT5-ST                           06382048
              ADD 1 TO CTR-REC-TOT-SCRITTI                              06382049
              MOVE 19 TO W-CONTR                                        06382179
              MOVE 1 TO WS-SCRIVI-MOV                                   06382293
              GO TO 00108-EX                                            06383048
           END-IF.                                                      06383168
           IF W-CONTR < W-MAXR-47                                       06383380
              IF WS-SCRIVI-SALDI = 0                                    06383776
                 PERFORM 10150-INIZIALIZZA-DETT THRU 10150-EX           06384699
                 PERFORM 10050-SCRIVI-DETT THRU 10050-EX                06384799
                 MOVE 2                     TO WS-CONTA-RIGHE           06385271
                 PERFORM 90000-SCRIVI-SPACE THRU 90000-EX               06385371
                 VARYING WS-INDICE-RIGA FROM 1 BY 1                     06385471
                 UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                  06385571
                 WRITE REC-SMOV FROM WS-DETT5-ST                        06385671
                 ADD 1 TO CTR-REC-TOT-SCRITTI                           06385672
                 ADD 3 TO W-CONTR                                       06385771
                 MOVE 1 TO WS-SCRIVI-MOV                                06385893
                 GO TO 00108-EX                                         06385971
              END-IF                                                    06386078
              IF WS-SCRIVI-SALDI = 1                                    06386178
                 MOVE 2 TO WS-CONTA-RIGHE                               06386272
                 PERFORM 90000-SCRIVI-SPACE THRU 90000-EX               06386371
                  VARYING WS-INDICE-RIGA FROM 1 BY 1                    06386471
                   UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                06386571
                 WRITE REC-SMOV FROM WS-INTEST7                         06386672
                 ADD 1 TO CTR-REC-TOT-SCRITTI                           06386673
                 PERFORM 10100-VALORIZZA-DETT THRU 10100-EX             06386799
                 PERFORM 10050-SCRIVI-DETT THRU 10050-EX                06387599
                 MOVE 2 TO WS-CONTA-RIGHE                               06388071
                 PERFORM 90000-SCRIVI-SPACE THRU 90000-EX               06388171
                  VARYING WS-INDICE-RIGA FROM 1 BY 1                    06388271
                   UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                06388371
                 WRITE REC-SMOV FROM WS-DETT5-ST                        06388471
                 ADD 1 TO CTR-REC-TOT-SCRITTI                           06388472
                 ADD 6 TO W-CONTR                                       06388582
                 MOVE 0 TO WS-SCRIVI-SALDI                              06388676
                 MOVE 1 TO WS-SCRIVI-MOV                                06388793
                 GO TO 00108-EX                                         06388896
              END-IF                                                    06389072
           END-IF.                                                      06390072
           IF W-CONTR < W-MAXR-52 AND W-CONTR > W-MAXR-47               06400099
              IF WS-SCRIVI-SALDI = 0                                    06410099
                 PERFORM 10150-INIZIALIZZA-DETT THRU 10150-EX           06420099
                 PERFORM 10050-SCRIVI-DETT THRU 10050-EX                06430099
                 MOVE 2                     TO WS-CONTA-RIGHE           06440099
                 PERFORM 90000-SCRIVI-SPACE THRU 90000-EX               06441099
                 VARYING WS-INDICE-RIGA FROM 1 BY 1                     06442099
                 UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                  06442199
                 WRITE REC-SMOV FROM WS-DETT5-ST                        06442299
                 ADD 1 TO CTR-REC-TOT-SCRITTI                           06442300
                 ADD 3 TO W-CONTR                                       06442399
                 MOVE 1 TO WS-SCRIVI-MOV                                06442499
                 GO TO 00108-EX                                         06442599
              END-IF                                                    06442699
              IF WS-SCRIVI-SALDI = 1                                    06442799
                 MOVE 2 TO WS-CONTA-RIGHE                               06442899
                 PERFORM 90000-SCRIVI-SPACE THRU 90000-EX               06442999
                  VARYING WS-INDICE-RIGA FROM 1 BY 1                    06443099
                   UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                06443199
                 WRITE REC-SMOV FROM WS-INTEST7                         06443299
                 ADD 1 TO CTR-REC-TOT-SCRITTI                           06443300
                 PERFORM 10100-VALORIZZA-DETT THRU 10100-EX             06443399
                 PERFORM 10050-SCRIVI-DETT THRU 10050-EX                06443499
                 MOVE 2 TO WS-CONTA-RIGHE                               06443599
                 PERFORM 90000-SCRIVI-SPACE THRU 90000-EX               06443699
                  VARYING WS-INDICE-RIGA FROM 1 BY 1                    06443799
                   UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE                06443899
                 WRITE REC-SMOV FROM WS-DETT5-ST                        06443999
                 ADD 1 TO CTR-REC-TOT-SCRITTI                           06444000
                 ADD 6 TO W-CONTR                                       06444099
                 MOVE 0 TO WS-SCRIVI-SALDI                              06444199
                 MOVE 1 TO WS-SCRIVI-MOV                                06444299
                 GO TO 00108-EX                                         06444399
              END-IF                                                    06444499
           END-IF.                                                      06444599
       00108-EX.                                                        06445099
           EXIT.                                                        06450016
      ***************************************************************** 06451064
      * ROUTINE DI RICERCA DELLA DESCRIZIONE DEL CODICE ANOMALIA SULLA* 06452064
      * TABELLA SCTBTANO.                                             * 06452164
      ***************************************************************** 06453064
       08300-CERCA-DESCR.                                               06460025
           MOVE ARRAC021-COD-ANOM  TO  TANO-CODICE.                     06461025
           MOVE 'I'                TO  TANO-FLG-I-E.                    06461199
           EXEC SQL INCLUDE ANO001SL END-EXEC.                          06462025
           MOVE SQLCODE TO W-SQLCODE.                                   06463025
           IF W-SQLCODE = 0                                             06464025
              GO TO 08300-EX                                            06465025
           END-IF.                                                      06466025
           IF W-SQLCODE = 100                                           06467025
              DISPLAY 'LABEL 08300-CERCA-DESCR'                         06468025
              DISPLAY 'CODICE ANOMALIA ==> ' ARRAC021-COD-ANOM ' <== '  06468199
              DISPLAY 'OCCORRENZA NON PRESENTE SU DB SCTBTANO'          06469025
           END-IF.                                                      06469125
           IF W-SQLCODE NOT EQUAL 0 AND 100                             06469225
              DISPLAY 'LABEL 08300-CERCA-DESCR'                         06469325
              DISPLAY 'ERRORE SQL ' W-SQLCODE ' SU TABELLA SCTBTANO'    06469425
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     06469525
           END-IF.                                                      06469625
       08300-EX.                                                        06470025
           EXIT.                                                        06480025
      ***************************************************************** 06481064
      * ROUTINE DI SCRITTURA DELLE RIGHE VUOTE                        * 06482064
      ***************************************************************** 06483064
       90000-SCRIVI-SPACE.                                              06490048
           IF WS-INDICE-RIGA > WS-CONTA-RIGHE                           06490148
              GO TO 90000-EX                                            06490248
           END-IF.                                                      06490348
           WRITE REC-SMOV FROM WS-INTEST8.                              06491048
           ADD 1 TO CTR-REC-TOT-SCRITTI.                                06491049
       90000-EX.                                                        06500048
           EXIT.                                                        06510048
      ***************************************************************** 06520050
      *      ROUTINE DI ACCESSO AL DB POSIZIONI                       * 06530050
      ***************************************************************** 06540050
       00220-ACCESSO-ANAG.                                              06550099
                                                                        06580099
DEBU  *    MOVE SPACE                      TO L-ACS108-ARG.             06650099
DEBU  *    MOVE ZERO                       TO L-ACS108-I-BANCA.         06660099
DEBU  *    MOVE ZERO                       TO L-ACS108-I-DATA-RIF.      06670099
DEBU  *    MOVE ' '                        TO L-ACS108-I-TIPO-RICH.     06680099
DEBU  *    MOVE ARRAC020-NDG               TO L-ACS108-I-NDG.           06690099
DEBU  *    MOVE ARRAC020-SERVIZIO          TO L-ACS108-I-SERVIZIO.      06700099
DEBU  *    MOVE ARRAC020-CATEGORIA         TO L-ACS108-I-CATEGORIA.     06710099
DEBU  *    MOVE ARRAC020-FILIALE           TO L-ACS108-I-FILIALE.       06720099
DEBU  *    MOVE ARRAC020-NUMERO            TO L-ACS108-I-NUMERO.        06730099
      *                                                                 06748199
           EXEC SQL INCLUDE EXACS108 END-EXEC.                          06749099
      *                                                                 06749499
           IF L-ACS108-RET-CODE  = ZERO                                 06749599
              GO TO 00220-ACCESSO-ANAG-EX                               06750399
           END-IF.                                                      06750499
      * * * * * * * * * * * * * * * * * * * * * *                       06750599
      * GESTIONE RET-CODE  PER CODICE ANOMALIA  *                       06750699
      * * * * * * * * * * * * * * * * * * * * * *                       06750799
           IF L-ACS108-RET-CODE  = 2                                    06750899
DEBU          DISPLAY ' RAPPORTO INESISTENTE     '                      06750999
DEBU          DISPLAY ' CODICE DI RITORNO MODULO ' L-ACS108-RET-CODE    06751099
DEBU          DISPLAY ' NDG              =       ' L-ACS108-I-NDG       06751199
DEBU          DISPLAY ' SERVIZIO         =       ' L-ACS108-I-SERVIZIO  06751299
DEBU          DISPLAY ' CATEGORIA        =       ' L-ACS108-I-CATEGORIA 06751399
DEBU          DISPLAY ' FILIALE          =       ' L-ACS108-I-FILIALE   06751499
DEBU          DISPLAY ' NUMERO           =       ' L-ACS108-I-NUMERO    06751599
           END-IF.                                                      06751699
DEBU  *                                                                 06751799
           IF L-ACS108-RET-CODE  = 7                                    06751899
DEBU          DISPLAY ' CHIAVE ANAGR. INESISTENTE' L-ACS108-RET-CODE    06751999
           END-IF.                                                      06752099
      *                                                                 06752199
           IF L-ACS108-RET-CODE  NOT = 2 AND                            06752299
              L-ACS108-RET-CODE  NOT = 7                                06752399
DEBU          DISPLAY ' ABEND SISTEMA ' L-ACS108-RET-CODE               06752499
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     06752599
           END-IF.                                                      06752699
      *                                                                 06752799
       00220-ACCESSO-ANAG-EX.                                           06753099
           EXIT.                                                        06760050
      ***************************************************************** 06761099
      *  ROUTINE DI SCRITTURA DELLE INTESTAZIONI                      * 06762099
      ***************************************************************** 06763099
       10000-SCRIVI-INTEST.                                             06770099
           MOVE 'ARRAB050'         TO WS-PGM-ST.                        06771099
           MOVE W-DATA-ELAB-GG     TO WS-DD-ST.                         06772099
           MOVE W-DATA-ELAB-MM     TO WS-MM-ST.                         06773099
           MOVE W-DATA-ELAB-AA     TO WS-SSAA-ST.                       06774099
           WRITE REC-SMOV FROM WS-INTEST1 AFTER ADVANCING PAGE.         06775099
           ADD 1 TO CTR-REC-TOT-SCRITTI.                                06775100
           MOVE 2 TO WS-CONTA-RIGHE.                                    06776099
           PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                     06777099
            VARYING WS-INDICE-RIGA FROM 1 BY 1                          06778099
             UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE.                     06779099
           ADD 1 TO WS-PAG.                                             06779199
           MOVE WS-PAG TO WS-PAG-ST.                                    06779299
           WRITE REC-SMOV FROM WS-INTEST2.                              06779399
           ADD 1 TO CTR-REC-TOT-SCRITTI.                                06779400
           MOVE 3 TO WS-CONTA-RIGHE.                                    06779499
           PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                     06779599
            VARYING WS-INDICE-RIGA FROM 1 BY 1                          06779699
             UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE.                     06779799
           WRITE REC-SMOV FROM WS-INTEST3.                              06779899
           ADD 1 TO CTR-REC-TOT-SCRITTI.                                06779900
           MOVE 2 TO WS-CONTA-RIGHE.                                    06779999
           PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                     06780099
            VARYING WS-INDICE-RIGA FROM 1 BY 1                          06780199
             UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE.                     06780299
           WRITE REC-SMOV FROM WS-INTEST4.                              06780399
           ADD 1 TO CTR-REC-TOT-SCRITTI.                                06780400
           MOVE 3 TO WS-CONTA-RIGHE.                                    06780499
           PERFORM 90000-SCRIVI-SPACE THRU 90000-EX                     06780599
            VARYING WS-INDICE-RIGA FROM 1 BY 1                          06780699
             UNTIL WS-INDICE-RIGA > WS-CONTA-RIGHE.                     06780799
           WRITE REC-SMOV FROM WS-INTEST5.                              06780899
           ADD 1 TO CTR-REC-TOT-SCRITTI.                                06780900
       10000-EX.                                                        06781099
           EXIT.                                                        06790099
      ***************************************************************** 06791099
      *  ROUTINE DI SCRITTURA DEL DETTAGLIO PER I MOVIMENTI           * 06792099
      ***************************************************************** 06793099
       10050-SCRIVI-DETT.                                               06800099
           IF ARRAC020-SEGNO = '-'                                      06800199
              COMPUTE ARRAC020-UTILIZZO-FIDO =                          06800299
                      ARRAC020-UTILIZZO-FIDO * (-1)                     06800399
           END-IF.                                                      06800499
           IF ARRAC020-DIVISA = 'ITL'                                   06801199
              MOVE ARRAC020-UTILIZZO-FIDO TO WS-IMPORTO                 06801299
              MOVE WS-IMPORTO             TO WS-IMP-ST                  06802099
           ELSE                                                         06802199
              MOVE ARRAC020-UTILIZZO-FIDO TO WS-IMPORTO-EUR             06802299
              MOVE WS-IMPORTO-EUR         TO WS-IMP-ST                  06802399
           END-IF.                                                      06802499
           MOVE WS-DT-STAMPA-GG         TO WS-GGVAL-ST.                 06803099
           MOVE WS-DT-STAMPA-MM         TO WS-MMVAL-ST.                 06804099
           MOVE WS-DT-STAMPA-AA         TO WS-SSAAVAL-ST.               06805099
       10050-EX.                                                        06810099
           EXIT.                                                        06820099
      ***************************************************************** 06821099
      *  ROUTINE DI VALORIZZAZIONE DEL DETTAGLIO PER I MOVIMENTI      * 06822099
      ***************************************************************** 06823099
       10100-VALORIZZA-DETT.                                            06830099
           MOVE ARRAC020-NDG       TO WS-NDG-ST.                        06831099
           IF L-ACS108-RAGSOC-1 = SPACES                                06831899
              MOVE L-ACS108-INT-RIDOTTA TO WS-INTEST-ST                 06831999
           ELSE                                                         06832099
              MOVE L-ACS108-RAGSOC-1    TO WS-INTEST-ST                 06832199
           END-IF.                                                      06832399
           MOVE ARRAC020-CATEGORIA TO WS-CAT-ST.                        06833099
           MOVE ARRAC020-FILIALE   TO WS-FIL-ST.                        06834099
           MOVE ARRAC020-NUMERO    TO WS-NUM-ST.                        06835099
           MOVE ARRAC020-DIVISA    TO WS-DIV-ST.                        06836099
       10100-EX.                                                        06840099
           EXIT.                                                        06850099
      ***************************************************************** 06851099
      *  ROUTINE DI INIZIALIZZAZIONE DEL DETTAGLIO PER I MOVIMENTI    * 06852099
      ***************************************************************** 06853099
       10150-INIZIALIZZA-DETT.                                          06854099
           MOVE SPACES                TO WS-NDG-ST.                     06860099
           MOVE SPACES                TO WS-INTEST-ST.                  06870099
           MOVE SPACES                TO WS-CAT-ST.                     06880099
           MOVE SPACES                TO WS-FIL-ST.                     06890099
           MOVE SPACES                TO WS-NUM-ST.                     06900099
           MOVE SPACES                TO WS-DIV-ST.                     06910099
       10150-EX.                                                        06920099
           EXIT.                                                        06930099
      ***************************************************************** 06931099
      *  ROUTINE DI INIZIALIZZAZIONE DEL DETTAGLIO PER I SALDI        * 06932099
      ***************************************************************** 06933099
       10200-VAL-DETT-SALDI.                                            06940099
           MOVE ARRAC021-NDG       TO WS-NDG-ST.                        06941099
           IF WS-ACS108 = 1                                             06941399
              IF WS-ACS108-RAGSOC = SPACES                              06941499
                 MOVE WS-ACS108-INT-RIDOTTA TO WS-INTEST-ST             06941599
              ELSE                                                      06941699
                 MOVE WS-ACS108-RAGSOC      TO WS-INTEST-ST             06941799
              END-IF                                                    06941899
           ELSE                                                         06941999
              IF L-ACS108-RAGSOC-1 = SPACES                             06942099
                 MOVE L-ACS108-INT-RIDOTTA TO WS-INTEST-ST              06942199
              ELSE                                                      06942299
                 MOVE L-ACS108-RAGSOC-1    TO WS-INTEST-ST              06942399
              END-IF                                                    06942499
           END-IF.                                                      06942599
           MOVE ARRAC021-CATEGORIA   TO WS-CAT-ST.                      06943199
           MOVE ARRAC021-FILIALE     TO WS-FIL-ST.                      06944099
           MOVE ARRAC021-NUMERO      TO WS-NUM-ST.                      06945099
           MOVE SPACE                TO WS-SGN-ST.                      06946099
           MOVE ARRAC021-SALDO-PPREN TO WS-IMPORTO.                     06947099
           MOVE WS-IMPORTO           TO WS-IMP-ST.                      06948099
           MOVE SPACES               TO WS-DTVAL-ST.                    06949099
           MOVE ARRAC021-DIVISA      TO WS-DIV-ST.                      06949100
       10200-EX.                                                        06950099
           EXIT.                                                        06960099
      ***************************************************************** 06970099
      * ROUTINE PER LA RICERCA DELLA DATA RICHIESTA E DATA BATCH SU   * 06980099
      * TABELLA TDAT.NEL CASO IN CUI DATA RICHIESTA NON SIA VALO-     * 06990099
      * RIZZATA IL PROGRAMMA CONTINUA NELL' ELABORAZIONE ASSUMENDO LA * 07000099
      * DATA BATCH COME DATA DI SISTEMA.                              * 07010099
      ***************************************************************** 07020099
       00950-CERCA-DATA.                                                07030099
           EXEC SQL INCLUDE DATA01SL END-EXEC.                          07040099
           MOVE SQLCODE TO W-SQLCODE.                                   07041099
           IF W-SQLCODE NOT = 0 AND 100                                 07042099
              DISPLAY 'LABEL 00950-CERCA-DATA'                          07043099
              DISPLAY 'ERRORE ' W-SQLCODE ' SU LETTURA SCTBTDAT'        07043199
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     07043299
           END-IF.                                                      07044099
           IF TDAT-BATCH NOT = 0                                        07050099
              MOVE TDAT-BATCH TO W-DATA-ELAB-RED                        07060099
              GO TO 00950-EX                                            07070099
           ELSE                                                         07080099
DEBU          DISPLAY 'ATTENZIONE-VALORIZZARE LA DATA TDAT_BATCH SU DB S07090099
DEBU  -        'CTBTDAT'                                                07100099
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     07110099
           END-IF.                                                      07120099
       00950-EX.                                                        07130099
           EXIT.                                                        07140099
      ***************************************************************** 07150099
      * INSERIMENTO DEL RECORD SU TABELLA SCTBTTAR                    * 07160099
      ***************************************************************** 07170099
       25000-INSERISCI-TTAR.                                            07180099
190900*    MOVE W-COMODO        TO TTAR-TIP-REC.                        07190099
           MOVE W-TTAR-PROGR    TO TTAR-PROGR.                          07200099
           MOVE W-DATA-ELAB-RED TO TTAR-DT-ARRIVO.                      07210099
190900*    MOVE W-N-REC-TOT     TO TTAR-N-REC-TOT.                      07220099
190900*    MOVE ZEROES          TO TTAR-SALDID-ITL.                     07230099
190900*    MOVE ZEROES          TO TTAR-SALDIA-ITL.                     07240099
190900*    MOVE ZEROES          TO TTAR-SALDID-EUR.                     07250099
190900*    MOVE ZEROES          TO TTAR-SALDIA-EUR.                     07260099
           EXEC SQL INCLUDE TAR001IN END-EXEC.                          07270099
           MOVE SQLCODE TO W-SQLCODE.                                   07280099
           IF W-SQLCODE = 0                                             07290099
              GO TO 25000-EX                                            07300099
           END-IF.                                                      07310099
           IF SQLCODE NOT EQUAL 0                                       07320099
              DISPLAY 'LABEL 25000-INSERISCI-TTAR'                      07330099
              DISPLAY 'ERRORE SQL ' W-SQLCODE ' SU INSERIMENTO SCTBTTAR'07340099
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     07350099
           END-IF.                                                      07360099
       25000-EX.                                                        07370099
           EXIT.                                                        07380099
                                                                        07380100
      ***************************************************************** 07380101
      *                                                                 07380102
      ***************************************************************** 07380103
       00000-INTESTAZIONE-VUOTA.                                        07380104
                                                                        07380105
           MOVE 'ARRAB050'         TO WS-PGM-ST.                        07380110
           MOVE W-DATA-ELAB-GG     TO WS-DD-ST.                         07380200
           MOVE W-DATA-ELAB-MM     TO WS-MM-ST.                         07380300
           MOVE W-DATA-ELAB-AA     TO WS-SSAA-ST.                       07380400
           WRITE REC-SMOV FROM WS-INTEST1 AFTER ADVANCING PAGE.         07380500
           MOVE 1      TO WS-PAG-ST.                                    07381200
           WRITE REC-SMOV FROM WS-INTEST2.                              07381300
           WRITE REC-SMOV FROM WS-INTEST3.                              07381900
           WRITE REC-SMOV FROM WS-INTEST4.                              07382500
                                                                        07382501
           MOVE 0 TO WS-IND.                                            07382502
           PERFORM UNTIL WS-IND > 15                                    07382510
              WRITE REC-SMOV FROM WS-INTEST8                            07382512
              ADD  1     TO  WS-IND                                     07382513
           END-PERFORM.                                                 07382520
           WRITE REC-SMOV FROM WS-INTEST9.                              07382521
                                                                        07382530
       00000-EX.                                                        07382600
           EXIT.                                                        07382700
