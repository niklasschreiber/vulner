      *-----------------------------------------------------------------00000100
       IDENTIFICATION DIVISION.                                         00000200
      *_________________________________________________________________00000300
       PROGRAM-ID.   ARRA840B.                                          00000400
       AUTHOR.                                                          00000500
      *_________________________________________________________________00000600
      ***************************************************************** 00000700
       ENVIRONMENT DIVISION.                                            00000800
      *_________________________________________________________________00000900
       CONFIGURATION SECTION.                                           00001000
      *_________________________________________________________________00001100
          SPECIAL-NAMES.                                                00001200
              DECIMAL-POINT IS COMMA.                                   00001300
      *_________________________________________________________________00001400
       INPUT-OUTPUT SECTION.                                            00001500
      *_________________________________________________________________00001600
      *                                                                 00001700
       FILE-CONTROL.                                                    00001800
           SELECT  FILEROTA ASSIGN  TO FILEROTA                         00001900
                 FILE  STATUS  IS  W-STAT02.                            00002000
                                                                        00002100
           SELECT  FILEVIP ASSIGN   TO FILEVIP                          00002200
                 FILE  STATUS  IS  W-STAT03.                            00002300
                                                                        00002400
           SELECT  FILEFILT ASSIGN  TO FILEFILT                         00002500
                 FILE  STATUS  IS  W-STAT01.                            00002600
      *                                                                 00002700
           SELECT  FILESCAR ASSIGN  TO FILESCAR                         00002800
                 FILE  STATUS  IS  W-STAT04.                            00002900
      *                                                                 00003000
      *_________________________________________________________________00003100
       DATA DIVISION.                                                   00003200
      *_________________________________________________________________00003300
       FILE SECTION.                                                    00003400
      *_________________________________________________________________00003500
       FD  FILEROTA                                                     00003600
           LABEL RECORD STANDARD                                        00003700
           RECORDING MODE IS F                                          00003800
           BLOCK CONTAINS 0 RECORDS.                                    00003900
       01  REC-FILEROTA       PIC X(170).                               00004000
      *_________________________________________________________________00004100
                                                                        00004200
       FD  FILEVIP                                                      00004300
           LABEL RECORD STANDARD                                        00004400
           RECORDING MODE IS F                                          00004500
           BLOCK CONTAINS 0 RECORDS.                                    00004600
       01  REC-FILEVIP        PIC X(21).                                00004700
      *_________________________________________________________________00004800
       FD  FILEFILT                                                     00004900
           LABEL RECORD STANDARD                                        00005000
           RECORDING MODE IS F                                          00005100
           BLOCK CONTAINS 0 RECORDS.                                    00005200
       01  REC-FILEFILT       PIC X(170).                               00005300
      *_________________________________________________________________00005400
       FD  FILESCAR                                                     00005500
           LABEL RECORD STANDARD                                        00005600
           RECORDING MODE IS F                                          00005700
           BLOCK CONTAINS 0 RECORDS.                                    00005800
       01  REC-FILESCAR       PIC X(200).                               00005900
      *_________________________________________________________________00006000
       WORKING-STORAGE SECTION.                                         00006100
      *---------------------------------------------------------------* 00006200
      *      INCLUDE  TABELLE  DB2                                    * 00006300
      *---------------------------------------------------------------* 00006400
      *                                                                 00006500
           EXEC  SQL  INCLUDE  SQLCA     END-EXEC.                      00006600
           EXEC  SQL  INCLUDE  SCTBTTCO  END-EXEC.                      00006700
      *                                                                 00006800
      ***AREA DI COMODO PER TEST SU SQLCODE***                          00006900
       01  R-CODE         PIC +++++9.                                   00007000
                                                                        00007100
       01 WS-CAMPO-PERC            PIC 9V9(2)   VALUE 0.                00007200
                                                                        00007300
       01 WS-SKEDA.                                                     00007400
          05 WS-DATA-ODIERNA       PIC 9(8).                            00007500
          05 WS-PERC               PIC 9(2).                            00007600
      ***************************************************************** 00007700
      *      TRACCIATO DEL FILE DI OUTPUT-INPUT                       * 00007800
      ***************************************************************** 00007900
                                                                        00008000
       01 WS-IMP-FIDO                PIC S9(11)V9(2) VALUE ZERO.        00008100
       01 WS-IMP-FIDO-COMP           PIC S9(11)V9(2) USAGE COMP-3.      00008200
       01 WS-IMP-TTCO                PIC S9(13)V9(2) VALUE ZERO.        00008300
       01 WS-IMP-PERC                PIC S9(12)V9(2).                   00008400
       01 KEY-FILEVIP                PIC 9(12).                         00008500
       01 KEY-FILEROTA               PIC 9(12).                         00008600
                                                                        00008700
       01 W-CTR-LETTI-FILEROTA     PIC 9(09) VALUE 0.                   00008800
       01 W-CTR-FILEVIP            PIC 9(09) VALUE 0.                   00008900
       01 W-CTR-LETTI-FILEVIP      PIC 9(09) VALUE 0.                   00009000
       01 W-CTR-SCRITTI-SCART      PIC 9(09) VALUE 0.                   00009100
       01 W-CTR-SCRITTI-FILTR      PIC 9(09) VALUE 0.                   00009200
       01 W-CTR-VIP                PIC 9(09) VALUE 0.                   00009300
       01 W-CTR-PERC               PIC 9(09) VALUE 0.                   00009400
                                                                        00009500
      * VARIABILI DI APPOGGIO                                           00009600
        COPY DYNACALL.                                                  00009700
                                                                        00009800
      * COPY IN INPUT                                                   00009900
                                                                        00010000
       COPY ARRAC840.                                                   00010100
       COPY ARRAC84B.                                                   00010200
                                                                        00010300
                                                                        00010400
       01  W-ROTA.                                                      00010500
           10 W-TROT-SERVIZIO        PIC X(3).                          00010600
           10 W-TROT-CATEGORIA       PIC X(4).                          00010700
           10 W-TROT-FILIALE         PIC X(5).                          00010800
           10 W-TROT-NUMERO          PIC S9(12)V USAGE COMP-3.          00010900
           10 W-TROT-NDG             PIC X(12).                         00011000
           10 W-TROT-DATA-1          PIC S9(6)V USAGE COMP-3.           00011100
           10 W-TROT-UTIL-1          PIC S9(11)V9(2) USAGE COMP-3.      00011200
           10 W-TROT-IMP-ACCR-1      PIC S9(11)V9(2) USAGE COMP-3.      00011300
           10 W-TROT-DATA-2          PIC S9(6)V USAGE COMP-3.           00011400
           10 W-TROT-UTIL-2          PIC S9(11)V9(2) USAGE COMP-3.      00011500
           10 W-TROT-IMP-ACCR-2      PIC S9(11)V9(2) USAGE COMP-3.      00011600
           10 W-TROT-DATA-3          PIC S9(6)V USAGE COMP-3.           00011700
           10 W-TROT-UTIL-3          PIC S9(11)V9(2) USAGE COMP-3.      00011800
           10 W-TROT-IMP-ACCR-3      PIC S9(11)V9(2) USAGE COMP-3.      00011900
           10 W-TROT-DATA-4          PIC S9(6)V USAGE COMP-3.           00012000
           10 W-TROT-UTIL-4          PIC S9(11)V9(2) USAGE COMP-3.      00012100
           10 W-TROT-IMP-ACCR-4      PIC S9(11)V9(2) USAGE COMP-3.      00012200
           10 W-TROT-DATA-5          PIC S9(6)V USAGE COMP-3.           00012300
           10 W-TROT-UTIL-5          PIC S9(11)V9(2) USAGE COMP-3.      00012400
           10 W-TROT-IMP-ACCR-5      PIC S9(11)V9(2) USAGE COMP-3.      00012500
           10 W-TROT-DATA-6          PIC S9(6)V USAGE COMP-3.           00012600
           10 W-TROT-UTIL-6          PIC S9(11)V9(2) USAGE COMP-3.      00012700
           10 W-TROT-IMP-ACCR-6      PIC S9(11)V9(2) USAGE COMP-3.      00012800
           10 W-TROT-TOT-SEGN-CONS   PIC S9(8)V USAGE COMP-3.           00012900
           10 W-TROT-TOT-SEGNALA     PIC S9(8)V USAGE COMP-3.           00013000
           10 W-TROT-DATA-RIL        PIC S9(8)V USAGE COMP-3.           00013100
           10 W-TROT-IMP-FIDO        PIC S9(11)V9(2) USAGE COMP-3.      00013200
           10 W-TROT-SETT-PROD       PIC X(2).                          00013300
           10 W-TROT-SALDCONT        PIC S9(11)V9(2) USAGE COMP-3.      00013400
                                                                        00013500
                                                                        00013600
                                                                        00013700
       01  W-ESCI               PIC 9 VALUE 0.                          00013800
       01  W-UTIL               PIC XX VALUE SPACES.                    00013900
       01  W-TROVATO            PIC 9  VALUE 0.                         00014000
       01  W-TROVATO-GEST       PIC XX VALUE SPACES.                    00014100
       01  W-APPO-TSET-COMM-PT  PIC 9(11)V9(02) VALUE 0.                00014200
       01  W-APPO-TSET-COMM-DB  PIC 9(11)V9(02) VALUE 0.                00014300
       01  CONTA-SQUADRA        PIC 9(9) VALUE 0.                       00014400
       01  CONTA-RETROCES       PIC 9(9) VALUE 0.                       00014500
       01  WS-TOT-RET-PT        PIC 9(13)V9(02) VALUE 0.                00014600
       01  WS-TOT-RET-DB        PIC 9(13)V9(02) VALUE 0.                00014700
       01  WS-APPO-DT-VAL-DB    PIC 9(8)  VALUE 0.                      00014800
       01  WS-APPO-DT-ELAB-DB    PIC 9(8)  VALUE 0.                     00014900
                                                                        00015000
       01 WS-APPO-CODICE              PIC 9(2) VALUE 0.                 00015100
       01 W-TABELLA.                                                    00015200
          02 W-DATI-TSET       OCCURS 200.                              00015300
             10 W-TSET-CODICE          PIC 9(2) .                       00015400
             10 W-TSET-DESCRIZ         PIC X(20).                       00015500
             10 W-TSET-CODAFF1         PIC 9(2) .                       00015600
             10 W-TSET-CODAFF2         PIC 9(2) .                       00015700
             10 W-TSET-CODAFF3         PIC 9(2) .                       00015800
             10 W-TSET-CODAFF4         PIC 9(2) .                       00015900
             10 W-TSET-CODAFF5         PIC 9(2) .                       00016000
             10 W-TSET-CODAFF6         PIC 9(2) .                       00016100
             10 W-TSET-CODAFF7         PIC 9(2) .                       00016200
             10 W-TSET-CODAFF8         PIC 9(2) .                       00016300
             10 W-TSET-CIAE            PIC 9(4) .                       00016400
             10 W-TSET-COMM-DB         PIC 9(11)V9(02) .                00016500
             10 W-TSET-COMM-PT         PIC 9(11)V9(02) .                00016600
             10 W-TSET-DATI-PRECED     PIC X.                           00016700
                                                                        00016800
      *_________________________________________________________________00016900
      *     CAMPI    DI   WORKING   PER    GESTIONE    ABEND            00017000
      *_________________________________________________________________00017100
      *                                                                 00017200
       77  COMP-CODE                PIC S9(04) COMP VALUE +5555.        00017300
      *                                                                 00017400
       01  WS-PROGRAM                PIC X(08)  VALUE SPACES.           00017500
      *_________________________________________________________________00017600
      *     CAMPI    DI   WORKING   PER    GESTIONE    ANOMALIA         00017700
      *_________________________________________________________________00017800
      *                                                                 00017900
       01  W-STAT01                 PIC X(02) VALUE SPACES.             00018000
       01  W-STAT02                 PIC X(02) VALUE SPACES.             00018100
       01  W-STAT03                 PIC X(02) VALUE SPACES.             00018200
       01  W-STAT04                 PIC X(02) VALUE SPACES.             00018300
       01  W-SQLCODE                PIC +++9.                           00018400
                                                                        00018500
      ***************************************************************** 00018600
      *    SCHEDA PARAMETRO IMMISSIONE                                  00018700
      *                                                                 00018800
      *    IL RETCODE PUO  ASSUMERE I SEGUENTI VALORI :                 00018900
      *       SP = LA DATA E' RECUPERATA DALLA SCHEDA PARAMETRO         00019000
      *       SI = LA DATA E' QUELLA DI SISTEMA                         00019100
      ***************************************************************** 00019200
       01  FILLER                   PIC X(16) VALUE '******SD01******'. 00019300
       01  SD01-01.                                                     00019400
           COPY STDCSD01.                                               00019500
                                                                        00019600
      *AREE PER MESSAGGI D'ERRORE                                       00019700
       01  MESS1         PIC X(22) VALUE 'ERRORE RISCONTRATO..: '.      00019800
       01  MESS2         PIC X(35) VALUE SPACES.                        00019900
       01  MESS3         PIC X(10) VALUE SPACES.                        00020000
                                                                        00020100
      **************************************************************    00020200
      *    AREE PER ERRORE GENERICO                                     00020300
      **************************************************************    00020400
       01  DATI-ERR.                                                    00020500
           03  DATI-ERR-MES1        PIC X(60)   VALUE SPACES.           00020600
           03  DATI-ERR-MES2        PIC X(60)   VALUE SPACES.           00020700
           03  DATI-ERR-DES1        PIC X(10)   VALUE SPACES.           00020800
           03  DATI-ERR-DES2        PIC X(10)   VALUE SPACES.           00020900
           03  DATI-ERR-FLAG        PIC X(01)   VALUE SPACES.           00021000
                                                                        00021100
      ************************************************                  00021200
      *    AREA PER ACCESSO ARCHIVIO STDS004                            00021300
      ************************************************                  00021400
       01  FILLER                PIC X(16) VALUE '**AREA-STDS004 *'.    00021500
       01  AREA-STDS004.                                                00021600
           03  SW-STDS004           PIC X(02) VALUE SPACES.             00021700
             88  SI-STDS004                   VALUE 'SI'.               00021800
             88  NF-STDS004                   VALUE 'NF'.               00021900
             88  DP-STDS004                   VALUE 'DP'.               00022000
             88  FF-STDS004                   VALUE 'FF'.               00022100
             88  NO-STDS004                   VALUE 'NO'.               00022200
             88  ER-STDS004                   VALUE 'ER'.               00022300
            03  STDS004-TRAC         PIC X(04).                         00022400
            03  STDS004-FUNZ         PIC X(03).                         00022500
            03  STDS004-IN           PIC X(00208).                      00022600
            03  STDS004-OUT          PIC X(00208).                      00022700
            03  STDS004-PGM          PIC X(08).                         00022800
            03  STDS004-DATA         PIC X(08).                         00022900
            03  STDS004-ORA          PIC X(06).                         00023000
            03  STDS004-TIPOMOD      PIC X(01) VALUE 'A'.               00023100
            03  STDS004-RETCODE      PIC X(06).                         00023200
            03  STDS004-FILLER       PIC X(71).                         00023300
      ************************************************************      00023400
      **    ARCHIVIO STATISTICHE  PROGRAMMI BATCH                       00023500
      ************************************************************      00023600
        01  FILLER                  PIC X(16) VALUE '*****STDS004****'. 00023700
            COPY STDCS004.                                              00023800
                                                                        00023900
                                                                        00024000
       01  W-SKEDA.                                                     00024100
           05 W-SKED-DATA         PIC   9(8).                           00024200
                                                                        00024300
       PROCEDURE DIVISION.                                              00024400
                                                                        00024500
           PERFORM  00100-INIZIO             THRU  00100-EX.            00024600
                                                                        00024700
           PERFORM  00200-ELABORA            THRU  00200-EX.            00024800
                                                                        00024900
           PERFORM  00300-FINE               THRU  00300-EX.            00025000
                                                                        00025100
       FINE-PROGRAMMA.                                                  00025200
           STOP RUN.                                                    00025300
                                                                        00025400
      ***************************************************************** 00025500
      * ROUTINE DI INIZIO PROGRAMMA COMPRENDENTE:                     * 00025600
      * APERTURA DEL DATASET DI OUTPUT.                               * 00025700
      ***************************************************************** 00025800
       00100-INIZIO.                                                    00025900
           ACCEPT WS-SKEDA FROM SYSIN.                                  00026000
                                                                        00026100
           DISPLAY '*************************************'.             00026200
           DISPLAY ' I N I Z I O  P G M   A R R A 8 4 0 B'.             00026300
           DISPLAY '*************************************'.             00026400
           DISPLAY 'D A T A  O D I E R N A: ' WS-DATA-ODIERNA.          00026500
           DISPLAY '-------------------------------------'.             00026600
           DISPLAY ' PERCENTUALE : '  WS-PERC.                          00026700
                                                                        00026800
                                                                        00026900
           PERFORM 00110-APERTURE THRU  00110-EX.                       00027000
                                                                        00027100
           PERFORM 00281-LEGGI-FILEROTA THRU 00281-EX.                  00027200
                                                                        00027300
           PERFORM 00282-LEGGI-FILEVIP THRU 00282-EX.                   00027400
                                                                        00027500
       00100-EX.                                                        00027600
           EXIT.                                                        00027700
                                                                        00027800
      ***************************************************************** 00027900
      *  ROUTINE DI APERTURA DEL DATASET DI OUTPUT                    * 00028000
      ***************************************************************** 00028100
       00110-APERTURE.                                                  00028200
                                                                        00028300
           OPEN INPUT FILEROTA.                                         00028400
           IF W-STAT02 NOT = '00'                                       00028500
              DISPLAY 'LABEL 00110-APERTURA'                            00028600
              DISPLAY 'ERRORE ' W-STAT02 ' SU APERTURA FILEROTA'        00028700
              MOVE 'ERRORE APERTURA FILEROTA' TO DATI-ERR-MES1          00028800
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00028900
                                                                        00029000
           OPEN INPUT FILEVIP.                                          00029100
           IF W-STAT03 NOT = '00'                                       00029200
              DISPLAY 'LABEL 00110-APERTURA'                            00029300
              DISPLAY 'ERRORE ' W-STAT03 ' SU APERTURA FILEVIP'         00029400
              MOVE 'ERRORE APERTURA FILEVIP' TO DATI-ERR-MES1           00029500
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00029600
                                                                        00029700
           OPEN OUTPUT FILEFILT.                                        00029800
           IF W-STAT01 NOT = '00'                                       00029900
              DISPLAY 'LABEL 00110-APERTURA'                            00030000
              DISPLAY 'ERRORE ' W-STAT01 ' SU APERTURA FILEFILT'        00030100
              MOVE 'ERRORE APERTURA FILEROTA' TO DATI-ERR-MES1          00030200
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00030300
                                                                        00030400
                                                                        00030500
           OPEN OUTPUT FILESCAR.                                        00030600
           IF W-STAT04 NOT = '00'                                       00030700
              DISPLAY 'LABEL 00110-APERTURA'                            00030800
              DISPLAY 'ERRORE ' W-STAT04 ' SU APERTURA FILEFILT'        00030900
              MOVE 'ERRORE APERTURA FILEROTA' TO DATI-ERR-MES1          00031000
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00031100
                                                                        00031200
       00110-EX.                                                        00031300
           EXIT.                                                        00031400
                                                                        00031500
       00200-ELABORA.                                                   00031600
      ***************************************************************** 00031700
      *  ELABORAZIONE:                                                * 00031800
      ***************************************************************** 00031900
                                                                        00032000
           PERFORM UNTIL W-STAT02 = '10' AND W-STAT03 = '10'            00032100
                  EVALUATE TRUE                                         00032200
                    WHEN KEY-FILEROTA = KEY-FILEVIP                     00032300
                         MOVE W-ROTA  TO  ARRAC84B-REC                  00032400
                         MOVE 'VIP'   TO  ARRAC84B-MOTIVO-SCARTO        00032500
                         ADD 1 TO W-CTR-VIP                             00032600
                         PERFORM 00283-WRITE          THRU 00283-EX     00032700
                         PERFORM 00281-LEGGI-FILEROTA THRU 00281-EX     00032800
                         PERFORM 00282-LEGGI-FILEVIP THRU 00282-EX      00032900
                    WHEN KEY-FILEROTA < KEY-FILEVIP                     00033000
                         PERFORM 00284-ACCESSO-SCTBTTCO THRU 00284-EX   00033100
                         PERFORM 00281-LEGGI-FILEROTA THRU 00281-EX     00033200
                    WHEN KEY-FILEROTA > KEY-FILEVIP                     00033300
                         PERFORM 00282-LEGGI-FILEVIP THRU 00282-EX      00033400
                  END-EVALUATE                                          00033500
           END-PERFORM.                                                 00033600
       00200-EX.                                                        00033700
           EXIT.                                                        00033800
                                                                        00033900
                                                                        00034000
       00281-LEGGI-FILEROTA.                                            00034100
      ***************************************************************** 00034200
      * LETTURA FILE DI INPUT FILEROTA                                * 00034300
      ***************************************************************** 00034400
                                                                        00034500
           READ FILEROTA INTO W-ROTA.                                   00034600
                                                                        00034700
                                                                        00034800
           IF W-STAT02 NOT EQUAL '10' AND '00'                          00034900
              DISPLAY 'ERRORE LETTURA FILE FILEROTA:' W-STAT02          00035000
              DISPLAY '00281-LEGGI-FILEROTA'                            00035100
              MOVE 'ERRORE LETTURA FILEROTA    ' TO DATI-ERR-MES1       00035200
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00035300
                                                                        00035400
           IF W-STAT02 =  '00'                                          00035500
              MOVE W-TROT-NUMERO     TO  KEY-FILEROTA                   00035600
              ADD 1 TO W-CTR-LETTI-FILEROTA                             00035700
           END-IF.                                                      00035800
                                                                        00035900
           IF W-STAT02 =  '10' AND W-CTR-LETTI-FILEROTA = 0             00036000
              DISPLAY 'FILE INDICE ROTAZIONE VUOTO '                    00036100
           END-IF.                                                      00036200
                                                                        00036300
           IF W-STAT02 =  '10'                                          00036400
             MOVE 999999999999          TO KEY-FILEROTA                 00036500
           END-IF.                                                      00036600
                                                                        00036700
                                                                        00036800
       00281-EX.                                                        00036900
           EXIT.                                                        00037000
                                                                        00037100
      ***************************************************************** 00037200
      * LETTURA FILE DI INPUT UNLOAD SCTBTSAL                         * 00037300
      ***************************************************************** 00037400
       00282-LEGGI-FILEVIP.                                             00037500
                                                                        00037600
           READ FILEVIP INTO ARRAC840-REC.                              00037700
                                                                        00037800
           IF W-STAT03 NOT EQUAL '10' AND '00'                          00037900
              DISPLAY 'ERRORE LETTURA FILEVIP:' W-STAT03                00038000
              DISPLAY 'LABEL 00282-LETTURA'                             00038100
              MOVE 'ERRORE LETTURA FILEVIP' TO DATI-ERR-MES1            00038200
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00038300
                                                                        00038400
           IF W-STAT03 =  '00'                                          00038500
              MOVE ARRAC840-NUMERO       TO KEY-FILEVIP                 00038600
              ADD 1 TO W-CTR-LETTI-FILEVIP                              00038700
           END-IF.                                                      00038800
                                                                        00038900
           IF W-STAT03 =  '10' AND W-CTR-LETTI-FILEVIP = 0              00039000
              DISPLAY 'SCARICO SCTBTSAL VUOTO'                          00039100
           END-IF.                                                      00039200
                                                                        00039300
           IF W-STAT03 =  '10'                                          00039400
             MOVE 999999999999          TO KEY-FILEVIP                  00039500
           END-IF.                                                      00039600
                                                                        00039700
       00282-EX.                                                        00039800
           EXIT.                                                        00039900
                                                                        00040000
                                                                        00040100
       00283-WRITE.                                                     00040200
      *   FLUSSO INDICE ROTAZIONE SCARTATI                              00040300
            WRITE REC-FILESCAR FROM ARRAC84B-REC.                       00040400
            ADD 1 TO W-CTR-SCRITTI-SCART.                               00040500
       00283-EX.                                                        00040600
           EXIT.                                                        00040700
                                                                        00040800
       00285-WRITE.                                                     00040900
      *   FLUSSO INDICE ROTAZIONE FILTRATO                              00041000
            WRITE REC-FILEFILT FROM W-ROTA.                             00041100
            ADD 1 TO W-CTR-SCRITTI-FILTR.                               00041200
       00285-EX.                                                        00041300
           EXIT.                                                        00041400
                                                                        00041500
       00284-ACCESSO-SCTBTTCO.                                          00041600
           INITIALIZE DCLSCTBTTCO                                       00041700
                      WS-IMP-FIDO                                       00041800
                      WS-IMP-FIDO-COMP.                                 00041900
                                                                        00042000
           MOVE W-TROT-IMP-FIDO  TO WS-IMP-FIDO.                        00042100
           MOVE WS-IMP-FIDO      TO WS-IMP-FIDO-COMP.                   00042200
                                                                        00042300
           MOVE WS-IMP-FIDO-COMP  TO TTCO-IMPORTO.                      00042400
                                                                        00042500
                                                                        00042600
                                                                        00042700
           EXEC SQL INCLUDE TCO006SL END-EXEC.                          00042800
      *                                                                 00042900
           IF SQLCODE NOT = 0                                           00043000
              MOVE SQLCODE TO R-CODE                                    00043100
              DISPLAY 'ERRORE SELECT SU SCTBTTCO ' R-CODE               00043200
              MOVE 'ERRORE SELECT  SCTBTCCO    ' TO DATI-ERR-MES1       00043300
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00043400
           END-IF.                                                      00043500
                                                                        00043600
           MOVE ZERO            TO  WS-CAMPO-PERC(1:1).                 00043700
           MOVE WS-PERC(1:1)    TO  WS-CAMPO-PERC(2:1).                 00043800
           MOVE WS-PERC(2:1)    TO  WS-CAMPO-PERC(3:1).                 00043900
                                                                        00044000
                                                                        00044100
           IF W-TROT-IMP-ACCR-1   > ZERO                                00044200
              COMPUTE WS-IMP-PERC = (TTCO-IMP-MIN-ST * WS-CAMPO-PERC) - 00044300
                                         TTCO-IMP-MIN-ST                00044400
              COMPUTE WS-IMP-PERC = WS-IMP-PERC * -1                    00044500
                                                                        00044600
              IF W-TROT-IMP-ACCR-1   > WS-IMP-PERC                      00044700
                 MOVE W-ROTA  TO  ARRAC84B-REC                          00044800
                 MOVE 'ACCREDITO MAGGIORE DEL 95%' TO                   00044900
                                                 ARRAC84B-MOTIVO-SCARTO 00045000
      *   FLUSSO INDICE ROTAZIONE SCARTATI                              00045100
                         ADD 1 TO W-CTR-PERC                            00045200
                         PERFORM 00283-WRITE     THRU 00283-EX          00045300
              ELSE                                                      00045400
      *   FLUSSO INDICE ROTAZIONE FILTRATO                              00045500
                         PERFORM 00285-WRITE     THRU 00285-EX          00045600
                                                                        00045700
              END-IF                                                    00045800
           ELSE                                                         00045900
      *   FLUSSO INDICE ROTAZIONE FILTRATO                              00046000
                         PERFORM 00285-WRITE     THRU 00285-EX          00046100
           END-IF.                                                      00046200
                                                                        00046300
                                                                        00046400
       00284-EX.                                                        00046500
           EXIT.                                                        00046600
                                                                        00046700
       00300-FINE.                                                      00046800
      ***************************************************************** 00046900
      * ROUTINE DI CHIUSURA DEL FILE DI OUTPUT                        * 00047000
      ***************************************************************** 00047100
                                                                        00047200
           PERFORM 00310-CHIUSURE     THRU 00310-EX.                    00047300
                                                                        00047400
           PERFORM 00320-STATISTICHE  THRU 00320-EX.                    00047500
                                                                        00047600
       00300-EX.                                                        00047700
           EXIT.                                                        00047800
                                                                        00047900
       00310-CHIUSURE.                                                  00048000
      ***************************************************************** 00048100
      * CHIUSURE DEI FILE                                             * 00048200
      ***************************************************************** 00048300
                                                                        00048400
           CLOSE FILEROTA.                                              00048500
           IF W-STAT02 NOT = '00' AND '10'                              00048600
              DISPLAY 'LABEL 00310-CHIUSURE'                            00048700
              DISPLAY 'ERRORE ' W-STAT02 ' SU CHIUSURA FILEROTA'        00048800
              MOVE 'ERRORE CHIUSURA FILEROTA     ' TO DATI-ERR-MES1     00048900
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00049000
                                                                        00049100
           CLOSE FILEVIP.                                               00049200
           IF W-STAT03 NOT = '00' AND '10'                              00049300
              DISPLAY 'LABEL 00310-CHIUSURE'                            00049400
              DISPLAY 'ERRORE ' W-STAT03 ' SU CHIUSURA FILEVIP'         00049500
              MOVE 'ERRORE CHIUSURA FILEVIP ' TO DATI-ERR-MES1          00049600
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00049700
                                                                        00049800
           CLOSE FILEFILT.                                              00049900
           IF W-STAT01 NOT = '00' AND '10'                              00050000
              DISPLAY 'LABEL 00310-CHIUSURE'                            00050100
              DISPLAY 'ERRORE ' W-STAT01 ' SU CHIUSURA FILEFILT'        00050200
              MOVE 'ERRORE CHIUSURA FILEFILT  ' TO DATI-ERR-MES1        00050300
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00050400
                                                                        00050500
           CLOSE FILESCAR.                                              00050600
           IF W-STAT04 NOT = '00' AND '10'                              00050700
              DISPLAY 'LABEL 00310-CHIUSURE'                            00050800
              DISPLAY 'ERRORE ' W-STAT04 ' SU CHIUSURA FILEFILT'        00050900
              MOVE 'ERRORE CHIUSURA FILEFILT  ' TO DATI-ERR-MES1        00051000
              PERFORM 9999-GEST-ABEND THRU 9999-EX.                     00051100
                                                                        00051200
                                                                        00051300
      *    MOVE 'CLO'               TO STDS004-FUNZ.                    00051400
      *    PERFORM ACCESS-STDS004-019    THRU ACCESS-STDS004-019-EX.    00051500
                                                                        00051600
       00310-EX.                                                        00051700
           EXIT.                                                        00051800
                                                                        00051900
       00320-STATISTICHE.                                               00052000
      ***************************************************************** 00052100
      * ROUTINE DI VISUALIZZAZIONE DEI RISULTATI DEL PGM              * 00052200
      ***************************************************************** 00052300
              DISPLAY '*-----------------------------------------*'.    00052400
              DISPLAY '*       F I N E       P R O G R A M M A   *'.    00052500
              DISPLAY '*-----------------------------------------*'.    00052600
              DISPLAY '*          ARRA840B                       *'.    00052700
              DISPLAY '*-----------------------------------------*'.    00052800
              DISPLAY '*  STATISTICHE NUMERO DI RECORD TRATTATI  *'.    00052900
              DISPLAY '*-----------------------------------------*'.    00053000
              DISPLAY '*TOT. REC. LETTI SU FILEROTA                  :' 00053100
                      W-CTR-LETTI-FILEROTA.                             00053200
              DISPLAY '*TOT. REC. LETTI SU FILEVIP                   :' 00053300
                      W-CTR-LETTI-FILEVIP.                              00053400
              DISPLAY '*TOT. REC. SCARTATI VIP                       :' 00053500
                      W-CTR-VIP                                         00053600
              DISPLAY '*TOT. REC. SCARTATI PER PERCENTUALE MAGG.     :' 00053700
                      W-CTR-PERC                                        00053800
              DISPLAY '*TOT. REC. OUTPUT                             :' 00053900
                      W-CTR-SCRITTI-FILTR.                              00054000
       00320-EX.                                                        00054100
             EXIT.                                                      00054200
      *                                                                 00054300
                                                                        00054400
       9999-GEST-ABEND.                                                 00054500
             MOVE 'ILBOABN0' TO WS-PROGRAM.                             00054600
             CALL WS-PROGRAM USING COMP-CODE.                           00054700
       9999-EX.                                                         00054800
             EXIT.                                                      00054900
                                                                        00055000
                                                                        00055100
                                                                        00055200
                                                                        00055300
      ***************************************************************** 00055400
       SCR-SEGNALAZ-021-EX.                                             00055500
           EXIT.                                                        00055600
      *                                                                 00055700
      *ACCESS-STDS004-019.                                              00055800
      *------------------------------------------------------------     00055900
      * 019 ROUTINE PER ACCESSO ALL'ARCHIVIO STDS004                    00056000
      *------------------------------------------------------------     00056100
      *    MOVE 'ARRA840B'          TO STDS004-PGM.                     00056200
      *    MOVE ZERO                TO STDS004-DATA.                    00056300
      *    MOVE ZERO                TO STDS004-ORA.                     00056400
      *    MOVE STDS004-REC         TO STDS004-IN.                      00056500
      *    CALL 'STDYS004'          USING AREA-STDS004.                 00056600
      *    MOVE STDS004-OUT         TO STDS004-REC.                     00056700
      *------------------------------------------------------------     00056800
      *ACCESS-STDS004-019-EX.                                           00056900
      *    EXIT.                                                        00057000
