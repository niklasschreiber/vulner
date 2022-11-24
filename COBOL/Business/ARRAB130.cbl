       IDENTIFICATION DIVISION.                                         00000100
       PROGRAM-ID. ARRAB130.                                            00000200
      ******************************************************************00000300
      *  INTERFACCIA DI CONTROLLO SUI RAPPORTI CON SCOPERTO DI CONTO   *00000400
      ******************************************************************00000500
       ENVIRONMENT DIVISION.                                            00000600
       CONFIGURATION SECTION.                                           00000700
       SPECIAL-NAMES.                                                   00000800
           DECIMAL-POINT IS COMMA.                                      00000900
       DATA DIVISION.                                                   00001000
      *                                                                 00001100
       WORKING-STORAGE SECTION.                                         00001200
      ***************************************************************** 00001300
      *      AREA PER DB2                                             * 00001400
      ***************************************************************** 00001500
      *AD+AD- IL 15112005                                               00001600
      *AD+   AGGIUNTO IL CONTROLLO DEL RECUPERATO SULLA TLIQ            00001700
      *AD-   ELIMITATO ACCESSO SULLA LCTBRCA PER CONTROLLO 161SI        00001800
      *AD-   ELIMITATO ACCESSO SULLA SCTBTTFA                           00001810
      ***************************************************************** 00001900
           EXEC SQL INCLUDE SQLCA     END-EXEC.                         00002000
      *                                                                 00002100
      ***************************************************************** 00002200
      *      INCLUDE TABELLE DB2                                      * 00002300
      ***************************************************************** 00002400
           EXEC SQL INCLUDE SCTBTTAF  END-EXEC.                         00002500
           EXEC SQL INCLUDE SCTBTLIQ  END-EXEC.                         00002600
      *                                                                 00002700
      ******************************************************************00002800
      *      TRACCIATO AREA PER CHIAMATA ROUTINE DI RICERCA MOVIMENTI  *00002900
      ******************************************************************00003000
           COPY PPTCNIMM.                                               00003100
      *                                                                 00003200
      ******************************************************************00003300
      *      VARIABILI DI COMODO                                       *00003400
      ******************************************************************00003500
       01  WS-TIMESTAMP              PIC X(26).                         00003600
       01  WS-TIMESTAMP-RED.                                            00003700
           05  DATA-SIST-AMG.                                           00003800
             10  ANNO-SIST           PIC X(04).                         00003900
             10  FILLER              PIC X(01).                         00004000
             10  MESE-SIST           PIC X(02).                         00004100
             10  FILLER              PIC X(01).                         00004200
             10  GIORNO-SIST         PIC X(02).                         00004300
           05  FILLER                PIC X(16).                         00004400
                                                                        00004500
       01  DATA-SISTEMA              PIC 9(8).                          00004600
       01  DATA-SITEMA-RED REDEFINES DATA-SISTEMA.                      00004700
           05  GIORNO-SISTEMA        PIC X(02).                         00004800
           05  MESE-SISTEMA          PIC X(02).                         00004900
           05  ANNO-SISTEMA          PIC X(04).                         00005000
                                                                        00005100
       01  WS-DATA-DA.                                                  00005200
           05  WS-SSAA-DA           PIC 9(04).                          00005300
           05  FILLER               PIC 9(04).                          00005400
       01  WS-DATA-DA-N REDEFINES WS-DATA-DA                            00005500
                                    PIC 9(08).                          00005600
      *                                                                 00005700
       01  WS-TEMPO                 PIC 9(18) COMP-3.                   00005800
       01  WS-APPO-TEMPO.                                               00005900
           03 WS-APPO-DATA.                                             00006000
              05 WS-APPO-GG         PIC 9(02).                          00006100
              05 WS-APPO-MM         PIC 9(02).                          00006200
              05 WS-APPO-SSAA       PIC 9(04).                          00006300
           03 FILLER                PIC X(3).                           00006400
           03 WS-APPO-ORA           PIC X(8).                           00006500
      *                                                                 00006600
       01  WS-DT-VAL-DA-X.                                              00006700
           05  WS-SSAA-VAL-DA       PIC 9(04).                          00006800
           05  WS-MM-VAL-DA         PIC 9(02).                          00006900
           05  FILLER               PIC 9(02).                          00007000
       01  WS-DT-VAL-DA REDEFINES WS-DT-VAL-DA-X                        00007100
                                    PIC 9(08).                          00007200
      *                                                                 00007300
       01  WS-DATA-VALUTA.                                              00007400
           05  WS-SSAA-VAL          PIC 9(04).                          00007500
           05  FILLER               PIC 9(04) VALUE 1231.               00007600
       01  WS-DATA-VALUTA-N REDEFINES WS-DATA-VALUTA                    00007700
                                    PIC 9(08).                          00007800
      *                                                                 00007900
       01  WS-DATA-INIZIO.                                              00008000
           05  WS-SSAA-INI          PIC 9(04).                          00008100
           05  FILLER               PIC 9(04) VALUE 0101.               00008200
      *                                                                 00008300
       01  WS-DATA-FINE.                                                00008400
           05  WS-SSAA-FINE         PIC 9(04).                          00008500
           05  WS-MM-FINE           PIC 9(02).                          00008600
           05  WS-GG-FINE           PIC 9(02).                          00008700
      *                                                                 00008800
       01  WS-DATA-DAY.                                                 00008900
           05  FILLER               PIC 9(02).                          00009000
           05  WS-MM-DAY            PIC 9(02).                          00009100
           05  WS-SSAA-DAY          PIC 9(04).                          00009200
      *                                                                 00009300
       01  WS-SQLCODE               PIC ----.                           00009400
      *                                                                 00009500
       01  WS-PROGRAM                PIC X(8) VALUE SPACES.             00009600
      *                                                                 00009700
       01  W-NUMERO-APPO            PIC 9(012).                         00009800
       01  W-CATEG-APPO             PIC 9(04).                          00009900
                                                                        00010000
       01  W-RAPPORTO.                                                  00010100
         05  W-ISTITUT                PIC X(002) .                      00010200
         05  W-SERVIZIO               PIC X(002) .                      00010300
         05  W-FILIALE                PIC X(005) .                      00010400
         05  W-NUMERO                 PIC 9(012) .                      00010500
         05  W-CATEGORIA              PIC X(004) .                      00010600
         05  W-FILLER                 PIC X(005) .                      00010700
                                                                        00010800
       01  W-DATA-INIZ-APPO         PIC 9(08).                          00010900
       01  W-DATA-INIZ-APPO-RED REDEFINES W-DATA-INIZ-APPO.             00011000
         05 W-ANNO-INI               PIC X(004).                        00011100
         05 W-DATA-INPUT-INI.                                           00011200
           07  W-MESE-INI               PIC X(002).                     00011300
           07  W-GIORNO-INI             PIC X(002).                     00011400
                                                                        00011500
                                                                        00011600
      ******************************************************************00011700
      *    AREA PER ACCESSO ARCHIVI                                     00011800
      ******************************************************************00011900
       01  FILLER                   PIC X(16) VALUE '**AREA-ARCHIVIO*'. 00012000
       01  AREA-ARCHIVIO.                                               00012100
           02  ARCHIVIO-SW          PIC X(02).                          00012200
           02  ARCHIVIO-TRAC        PIC X(04).                          00012300
           02  ARCHIVIO-FUNZ        PIC X(03).                          00012400
           02  ARCHIVIO-PGM         PIC X(08).                          00012500
           02  ARCHIVIO-DATA        PIC X(08).                          00012600
           02  ARCHIVIO-ORA         PIC X(06).                          00012700
           02  ARCHIVIO-TIPOMOD     PIC X(01).                          00012800
           02  ARCHIVIO-RETCODE     PIC X(06).                          00012900
           02  ARCHIVIO-FILLER      PIC X(71).                          00013000
           02  ARCHIVIO-REC         PIC X(01000).                       00013100
      ******************************************************************00013200
      *    ARCHIVIO STORICO RICHIESTE DI CONVERSIONI E DIVISE           00013300
      ******************************************************************00013400
       01  FILLER                   PIC X(16) VALUE '****LIRDCNV*****'. 00013500
           COPY LIRCDCNV.                                               00013600
      ******************************************************************00013700
      *    AREA PER ACCESSO ARCHIVIO LIRDRCA                            00013800
      ******************************************************************00013900
       01  FILLER                   PIC X(16) VALUE '**AREA-LIRDRCA *'. 00014000
       01  AREA-LIRDRCA.                                                00014100
           03  SW-LIRDRCA           PIC X(02) VALUE SPACES.             00014200
             88  SI-LIRDRCA                   VALUE 'SI'.               00014300
             88  NF-LIRDRCA                   VALUE 'NF'.               00014400
             88  DP-LIRDRCA                   VALUE 'DP'.               00014500
             88  FF-LIRDRCA                   VALUE 'FF'.               00014600
             88  NO-LIRDRCA                   VALUE 'NO'.               00014700
             88  ER-LIRDRCA                   VALUE 'ER'.               00014800
           03  LIRDRCA-TRAC         PIC X(04).                          00014900
           03  LIRDRCA-FUNZ         PIC X(03).                          00015000
           03  LIRDRCA-PGM          PIC X(08).                          00015100
           03  LIRDRCA-DATA         PIC X(08).                          00015200
           03  LIRDRCA-ORA          PIC X(06).                          00015300
           03  LIRDRCA-TIPOMOD      PIC X(01) VALUE 'A'.                00015400
           03  LIRDRCA-RETCODE      PIC X(06).                          00015500
           03  LIRDRCA-FILLER       PIC X(71).                          00015600
      ******************************************************************00015700
      *    ARCHIVIO RIEPILOGO MOVIMENTI PER CAUSALE                     00015800
      ******************************************************************00015900
       01  FILLER                   PIC X(16) VALUE '*****LIRDRCA****'. 00016000
           COPY LIRCDRCA.                                               00016100
      ******************************************************************00016200
      *    TRACCIATO PER ELABORAZIONE RIEPILOGO MOVIMENTI PER CAUSALE   00016300
      *                                                                 00016400
      *    TIPORIC: 1=DETERMINAZIONE ULTIMO MOVIMENTO,                  00016500
      *             2=TOTALIZZAZIONE NUMERO OPERAZIONI ED IMPORTI       00016600
      *    FLAGDA : D=CAUSALE DARE, A=CAUSALE AVERE                     00016700
      *    RETCODE: SPACE=OK, NF=MOVIMENTO NON TROVATO                  00016800
      ******************************************************************00016900
       01  FILLER                   PIC X(16) VALUE '******LR44******'. 00017000
       01  LR44-01.                                                     00017100
           COPY LIRCLR44.                                               00017200
      ******************************************************************00017300
      *    TRACCIATO PER SEGNALAZIONE ANOMALIE                          00017400
      *                                                                 00017500
      *    ERR    : S=ERRORE BLOCCANTE (ABEND),                         00017600
      *             N=SEGNALAZIONE (DISPLAY)                            00017700
      ******************************************************************00017800
       01  FILLER                   PIC X(16) VALUE '******LR00******'. 00017900
       01  LR00-01.                                                     00018000
           COPY LIRCLR00.                                               00018100
       LINKAGE SECTION.                                                 00018200
           COPY ARC130B.                                                00018300
      ******************************************************************00018400
      *                                                                 00018500
      ******************************************************************00018600
      *             P R O C E D U R E     D I V I S I O N              *00018700
      ******************************************************************00018800
       PROCEDURE DIVISION USING ARC130B.                                00018900
      *                                                                 00019000
           INITIALIZE ARC130B-DATI-OUTPUT.                              00019100
                                                                        00019200
           PERFORM 00050-PRENDI-DATA       THRU 00050-EX.               00019300
      *                                                                 00019400
           IF ARC130B-MESSAGGIO = ' '                                   00019500
              PERFORM 00100-CONTROLLI-INPUT   THRU 00100-EX             00019600
           END-IF.                                                      00019700
      *                                                                 00019800
           IF ARC130B-MESSAGGIO = ' '                                   00019900
              PERFORM 00200-ELABORAZIONE      THRU 00200-EX             00020000
           END-IF.                                                      00020100
                                                                        00020200
           GOBACK.                                                      00020300
      *                                                                 00020400
       00050-PRENDI-DATA.                                               00020500
      *                                                                 00020600
           PERFORM C0000-LEGGI-TIMESTAMP THRU  EX-C0000-LEGGI-TIMESTAMP.00020700
      *                                                                 00020800
           MOVE DATA-SITEMA-RED   TO WS-DATA-DAY.                       00020900
                                                                        00021100
      *                                                                 00021200
       00050-EX.                                                        00021300
           EXIT.                                                        00021400
      *                                                                 00021500
       00100-CONTROLLI-INPUT.                                           00021600
      *                                                                 00021700
AD-   *    IF  WS-MM-DAY NOT = 12                                       00021800
AD-   *    AND WS-MM-DAY NOT = 01                                       00021900
AD-   *    AND WS-MM-DAY NOT = 02                                       00022000
AD-   *       MOVE '01'           TO ARC130B-RETCODE                    00022100
AD-   *       STRING 'ROUTINE ARRAB130 (SCOPERTO DI CONTO) ATTUALMENTE '00022200
AD-   *              'NON OPERANTE' DELIMITED BY SIZE                   00022300
AD-   *                         INTO ARC130B-MESSAGGIO                  00022400
AD-   *       PERFORM 00214-FINE THRU 00214-EX                          00022500
AD-   *    END-IF.                                                      00022600
      *                                                                 00022700
AD-   *    IF WS-MM-DAY = 12                                            00022800
AD-   *       MOVE '09'        TO ARC130B-RETCODE                       00022900
AD-   *       STRING 'CONTO IN ATTESA ADDEBITO COMMISSIONI SCOPERTO '   00023000
AD-   *              'DI CONTO PER FINE ANNO'                           00023100
AD-   *                        DELIMITED BY SIZE                        00023200
AD-   *                        INTO ARC130B-MESSAGGIO                   00023300
AD-   *              PERFORM 00214-FINE THRU 00214-EX                   00023400
AD-   *    END-IF.                                                      00023500
                                                                        00023600
           IF ARC130B-SERVIZIO NOT = 'CC'                               00023700
              MOVE '02'           TO ARC130B-RETCODE                    00023800
              MOVE 'SERVIZIO RICHIESTO ERRATO'                          00023900
                                  TO ARC130B-MESSAGGIO                  00024000
              PERFORM 00214-FINE THRU 00214-EX                          00024100
           END-IF.                                                      00024200
      *                                                                 00024300
           IF ARC130B-CATEGORIA NOT NUMERIC                             00024400
              MOVE '03'           TO ARC130B-RETCODE                    00024500
              MOVE 'CATEGORIA RICHIESTA NON NUMERICA'                   00024600
                                  TO ARC130B-MESSAGGIO                  00024700
              PERFORM 00214-FINE THRU 00214-EX                          00024800
           END-IF.                                                      00024900
      *                                                                 00025000
           IF ARC130B-FILIALE NOT NUMERIC                               00025100
              MOVE '04'           TO ARC130B-RETCODE                    00025200
              MOVE 'FILIALE RICHIESTA NON NUMERICA'                     00025300
                                  TO ARC130B-MESSAGGIO                  00025400
              PERFORM 00214-FINE THRU 00214-EX                          00025500
           END-IF.                                                      00025600
      *                                                                 00025700
           IF ARC130B-NUMERO NOT NUMERIC                                00025800
              MOVE '05'           TO ARC130B-RETCODE                    00025900
              MOVE 'NUMERO RAPPORTO RICHIESTO NON NUMERICO'             00026000
                                  TO ARC130B-MESSAGGIO                  00026100
              PERFORM 00214-FINE THRU 00214-EX                          00026200
           END-IF.                                                      00026300
      *                                                                 00026400
       00100-EX.                                                        00026500
           EXIT.                                                        00026600
      *                                                                 00026700
       00200-ELABORAZIONE.                                              00026800
      *                                                                 00026900
                                                                        00027000
AD-   *    PERFORM 00210-SELECT-SCTBTTAF     THRU 00210-EX.             00027100
                                                                        00027200
      *                                                                 00027300
AD-   *    MOVE TTAF-DT-VAL-DA    TO WS-DATA-DA-N.                      00027400
      *                                                                 00027500
                                                                        00027600
AD-   *    IF WS-MM-DAY = 01 OR 02                                      00027700
           COMPUTE WS-SSAA-DAY = (WS-SSAA-DAY - 1)                      00027800
AD-   *    END-IF.                                                      00027900
                                                                        00028000
      *                                                                 00028100
AD-   *    IF TTAF-STATO = 'RR'                                         00028200
AD-   *    OR TTAF-STATO = 'RC'                                         00028300
AD-   *    OR TTAF-STATO = 'R3'                                         00028400
AD-   *       IF WS-SSAA-DA = WS-SSAA-DAY                               00028500
AD-   *          PERFORM 00212-CTRL-SCTBTLIQ  THRU 00212-EX             00028600
AD-   *       ELSE                                                      00028700
AD-   *          IF WS-SSAA-DA < WS-SSAA-DAY                            00028800
AD-   *             MOVE '08'     TO ARC130B-RETCODE                    00028900
AD-   *             STRING 'CONTO ESTINGUIBILE E CON AFFIDAMENTO '      00029000
AD-   *                    'REVOCATO'                                   00029100
AD-   *                           DELIMITED BY SIZE                     00029200
AD-   *                         INTO ARC130B-MESSAGGIO                  00029300
AD-   *                         PERFORM 00214-FINE THRU 00214-EX        00029400
AD-   *          ELSE                                                   00029500
AD-   *             PERFORM 00211-SELECT-SCTBTTAF-RS  THRU 00211-EX     00029600
AD-   *             MOVE TTAF-DT-VAL-DA  TO WS-DT-VAL-DA                00029700
AD-   *             IF (WS-MM-VAL-DA = 01 OR 02)                        00029800
AD-   *             AND WS-SSAA-VAL-DA = WS-SSAA-DA                     00029900
AD-   *                MOVE '08'     TO ARC130B-RETCODE                 00030000
AD-   *                STRING 'CONTO ESTINGUIBILE E CON AFFIDAMENTO '   00030100
AD-   *                       'REVOCATO'                                00030200
AD-   *                              DELIMITED BY SIZE                  00030300
AD-   *                            INTO ARC130B-MESSAGGIO               00030400
AD-   *                            PERFORM 00214-FINE THRU 00214-EX     00030500
AD-   *             ELSE                                                00030600
AD-   *             END-IF                                              00030700
AD-   *          END-IF                                                 00030800
AD-   *       END-IF                                                    00030900
AD-   *    ELSE                                                         00031000
AD-   *       MOVE '07'           TO ARC130B-RETCODE                    00031100
AD-   *       MOVE 'CONTO TROVATO CON AFFIDAMENTO ATTIVO'               00031200
AD-   *                           TO ARC130B-MESSAGGIO                  00031300
AD-   *                                                                 00031400
AD-   *                            PERFORM 00214-FINE THRU 00214-EX     00031500
AD-   *    END-IF.                                                      00031600
                                                                        00031700
AD+        PERFORM 00212-CTRL-SCTBTLIQ  THRU 00212-EX.                  00031800
                                                                        00031900
                                                                        00032000
      *                                                                 00032100
       00200-EX.                                                        00032200
           EXIT.                                                        00032300
      *                                                                 00032400
       00210-SELECT-SCTBTTAF.                                           00032500
      *                                                                 00032600
           MOVE ARC130B-SERVIZIO  TO TTAF-SERVIZIO.                     00032700
           MOVE ARC130B-CATEGORIA TO TTAF-CATEGORIA.                    00032800
           MOVE ARC130B-FILIALE   TO TTAF-FILIALE.                      00032900
           MOVE ARC130B-NUMERO    TO TTAF-NUMERO.                       00033000
                                                                        00033100
           DISPLAY 'SERVIZIO'    TTAF-SERVIZIO.                         00033200
           DISPLAY 'CAT'         TTAF-CATEGORIA.                        00033300
           DISPLAY 'FIL'         TTAF-FILIALE.                          00033400
           DISPLAY 'NUM'         TTAF-NUMERO.                           00033500
      *                                                                 00033600
           EXEC SQL                                                     00033700
                 SELECT MAX(TTAF_DT_VAL_A)                              00033800
                  INTO :TTAF-DT-VAL-A                                   00033900
                 FROM SCTBTTAF                                          00034000
                   WHERE TTAF_SERVIZIO  = :TTAF-SERVIZIO                00034100
                     AND TTAF_CATEGORIA = :TTAF-CATEGORIA               00034200
                     AND TTAF_FILIALE   = :TTAF-FILIALE                 00034300
                     AND TTAF_NUMERO    = :TTAF-NUMERO                  00034400
                     AND TTAF_STATO NOT IN ('70','80')                  00034500
           END-EXEC.                                                    00034600
      *                                                                 00034700
           IF  SQLCODE NOT = ZERO                                       00034800
           AND SQLCODE NOT = 100                                        00034900
           DISPLAY 'UFF1'        TTAF-NUMERO                            00035000
              MOVE SQLCODE        TO WS-SQLCODE                         00035100
              MOVE '90'           TO ARC130B-RETCODE                    00035200
              STRING 'ERRORE DB2 - SQLCODE: ' WS-SQLCODE                00035300
                                DELIMITED BY SIZE                       00035400
                                INTO ARC130B-MESSAGGIO                  00035500
                                PERFORM 00214-FINE THRU 00214-EX        00035600
           END-IF.                                                      00035700
      *                                                                 00035800
           IF SQLCODE = 100                                             00035900
              MOVE '06'           TO ARC130B-RETCODE                    00036000
              MOVE 'CONTO RICHIESTO NON AFFIDATO'                       00036100
                                  TO ARC130B-MESSAGGIO                  00036200
                                  PERFORM 00214-FINE THRU 00214-EX      00036300
           END-IF.                                                      00036400
      *                                                                 00036500
           IF SQLCODE = 0                                               00036600
              EXEC SQL                                                  00036700
                SELECT  TTAF_STATO,                                     00036800
                        TTAF_DT_VAL_DA                                  00036900
                  INTO :TTAF-STATO,                                     00037000
                       :TTAF-DT-VAL-DA                                  00037100
                  FROM  SCTBTTAF                                        00037200
                 WHERE  TTAF_SERVIZIO  = :TTAF-SERVIZIO                 00037300
                   AND  TTAF_CATEGORIA = :TTAF-CATEGORIA                00037400
                   AND  TTAF_FILIALE   = :TTAF-FILIALE                  00037500
                   AND  TTAF_NUMERO    = :TTAF-NUMERO                   00037600
                   AND  TTAF_DT_VAL_A  = :TTAF-DT-VAL-A                 00037700
                   AND  TTAF_STATO NOT IN ('70','80')                   00037800
              END-EXEC                                                  00037900
                                                                        00038000
              IF  SQLCODE NOT = ZERO                                    00038100
                  MOVE SQLCODE        TO WS-SQLCODE                     00038200
                  MOVE '90'           TO ARC130B-RETCODE                00038300
           DISPLAY 'UFF'         TTAF-NUMERO                            00038400
                  STRING 'ERRORE DB2 - SQLCODE: ' WS-SQLCODE            00038500
                                DELIMITED BY SIZE                       00038600
                                INTO ARC130B-MESSAGGIO                  00038700
                                PERFORM 00214-FINE THRU 00214-EX        00038800
              END-IF                                                    00038900
                                                                        00039000
           END-IF.                                                      00039100
       00210-EX.                                                        00039200
           EXIT.                                                        00039300
      *                                                                 00039400
       00211-SELECT-SCTBTTAF-RS.                                        00039500
      *                                                                 00039600
           MOVE ARC130B-SERVIZIO  TO TTAF-SERVIZIO.                     00039700
           MOVE ARC130B-CATEGORIA TO TTAF-CATEGORIA.                    00039800
           MOVE ARC130B-FILIALE   TO TTAF-FILIALE.                      00039900
           MOVE ARC130B-NUMERO    TO TTAF-NUMERO.                       00040000
      *                                                                 00040100
           EXEC SQL                                                     00040200
                SELECT  MAX(TTAF_DT_VAL_DA)                             00040300
                  INTO :TTAF-DT-VAL-DA                                  00040400
                  FROM  SCTBTTAF                                        00040500
                 WHERE  TTAF_SERVIZIO  = :TTAF-SERVIZIO                 00040600
                   AND  TTAF_CATEGORIA = :TTAF-CATEGORIA                00040700
                   AND  TTAF_FILIALE   = :TTAF-FILIALE                  00040800
                   AND  TTAF_NUMERO    = :TTAF-NUMERO                   00040900
                   AND  TTAF_STATO     = 'RS'                           00041000
           END-EXEC.                                                    00041100
      *                                                                 00041200
           IF SQLCODE NOT = ZERO                                        00041300
              MOVE SQLCODE        TO WS-SQLCODE                         00041400
              MOVE '90'           TO ARC130B-RETCODE                    00041500
              STRING 'ERRORE DB2 - SQLCODE: ' WS-SQLCODE                00041600
                                DELIMITED BY SIZE                       00041700
                                INTO ARC130B-MESSAGGIO                  00041800
                                PERFORM 00214-FINE THRU 00214-EX        00041900
           END-IF.                                                      00042000
      *                                                                 00042100
       00211-EX.                                                        00042200
           EXIT.                                                        00042300
      *                                                                 00042400
       00212-CTRL-SCTBTLIQ.                                             00042500
      *                                                                 00042600
           MOVE ARC130B-SERVIZIO  TO TLIQ-SERVIZIO.                     00042700
           MOVE ARC130B-CATEGORIA TO TLIQ-CATEGORIA.                    00042800
           MOVE ARC130B-FILIALE   TO TLIQ-FILIALE.                      00042900
           MOVE ARC130B-NUMERO    TO TLIQ-NUMERO.                       00043000
           MOVE WS-SSAA-DAY       TO WS-SSAA-VAL.                       00043100
           MOVE WS-DATA-VALUTA-N  TO TLIQ-DT-VALUTA-PT.                 00043200
      *                                                                 00043300
           EXEC SQL                                                     00043400
                SELECT  TLIQ_IMP_COM_PPTT,                              00043500
AD+                     TLIQ_IMP_RECUP                                  00043600
                  INTO :TLIQ-IMP-COM-PPTT,                              00043700
AD+                    :TLIQ-IMP-RECUP                                  00043800
                  FROM  SCTBTLIQ                                        00043900
                 WHERE  TLIQ_SERVIZIO     = :TLIQ-SERVIZIO              00044000
                   AND  TLIQ_CATEGORIA    = :TLIQ-CATEGORIA             00044100
                   AND  TLIQ_FILIALE      = :TLIQ-FILIALE               00044200
                   AND  TLIQ_NUMERO       = :TLIQ-NUMERO                00044300
                   AND  TLIQ_DT_VALUTA_PT = :TLIQ-DT-VALUTA-PT          00044400
           END-EXEC.                                                    00044500
      *                                                                 00044600
           IF  SQLCODE NOT = ZERO                                       00044700
           AND SQLCODE NOT = 100                                        00044800
              MOVE SQLCODE        TO WS-SQLCODE                         00044900
              MOVE '90'           TO ARC130B-RETCODE                    00045000
              STRING 'ERRORE DB2 - SQLCODE: ' WS-SQLCODE                00045100
                                DELIMITED BY SIZE                       00045200
                                INTO ARC130B-MESSAGGIO                  00045300
                                PERFORM 00214-FINE THRU 00214-EX        00045400
           END-IF.                                                      00045500
      *                                                                 00045600
           IF SQLCODE = 100                                             00045700
              MOVE '06'           TO ARC130B-RETCODE                    00045800
              MOVE 'CONTO RICHIESTO NON AFFIDATO'                       00045900
                                  TO ARC130B-MESSAGGIO                  00046000
                                  PERFORM 00214-FINE THRU 00214-EX      00046100
           END-IF.                                                      00046200
      *                                                                 00046300
           IF TLIQ-IMP-COM-PPTT = ZERO                                  00046400
              MOVE '08'     TO ARC130B-RETCODE                          00046500
              STRING 'CONTO ESTINGUIBILE'                               00046600
                            DELIMITED BY SIZE                           00046800
                          INTO ARC130B-MESSAGGIO                        00046900
                          PERFORM 00214-FINE THRU 00214-EX              00047000
AD+        ELSE                                                         00047100
AD+           IF TLIQ-IMP-RECUP NOT = 0                                 00047200
AD+              MOVE '08'     TO ARC130B-RETCODE                       00047300
AD+              STRING 'CONTO ESTINGUIBILE'                            00047400
AD+                            DELIMITED BY SIZE                        00047600
AD+                          INTO ARC130B-MESSAGGIO                     00047700
AD+                          PERFORM 00214-FINE THRU 00214-EX           00047800
AD+                                                                     00047900
AD+           ELSE                                                      00048000
AD+              MOVE '09'        TO ARC130B-RETCODE                    00048100
AD+              STRING 'CONTO IN ATTESA ADDEBITO COMMISSIONI SCOPERTO '00048200
AD+                     'DI CONTO PER FINE ANNO'                        00048300
AD+                               DELIMITED BY SIZE                     00048400
AD+                             INTO ARC130B-MESSAGGIO                  00048500
AD+                          PERFORM 00214-FINE THRU 00214-EX           00048600
AD+           END-IF                                                    00048700
AD+        END-IF.                                                      00048800
AD-   *       MOVE  'OIN'                    TO   LIRDRCA-FUNZ          00048900
AD-   *       PERFORM ACCESS-LIRDRCA-Y12    THRU ACCESS-LIRDRCA-Y12-EX  00049000
AD-   *                                                                 00049100
AD-   *       MOVE TLIQ-NUMERO          TO   W-NUMERO-APPO              00049200
AD-   *       MOVE TLIQ-CATEGORIA       TO   W-CATEG-APPO               00049300
AD-   *       MOVE W-NUMERO-APPO        TO   W-NUMERO                   00049400
AD-   *       MOVE W-CATEG-APPO         TO   W-CATEGORIA                00049500
AD-   *       MOVE '01'                 TO   W-ISTITUT                  00049600
AD-   *       MOVE TLIQ-SERVIZIO        TO   W-SERVIZIO                 00049700
AD-   *       MOVE TLIQ-FILIALE         TO   W-FILIALE                  00049800
AD-   *       MOVE WS-DATA-INIZIO       TO   W-DATA-INIZ-APPO           00049900
AD-   *       MOVE ' '                  TO   W-FILLER                   00050000
AD-   *                                                                 00050100
AD-   *       MOVE SPACE                       TO    LR44               00050200
AD-   *       MOVE '161SI     '                TO    LR44-CAUSALE       00050300
AD-   *       MOVE 'D'                         TO    LR44-FLAGDA        00050400
AD-   *       MOVE '2'                         TO    LR44-TIPORIC       00050500
AD-   *       MOVE W-RAPPORTO                  TO    LR44-CODRAP        00050600
AD-   *       MOVE W-DATA-INIZ-APPO            TO    LR44-DATINIZ       00050700
AD-   *       MOVE 99999999                    TO    LR44-DATFINE       00050800
AD-   *                                                                 00050900
AD-   *                                                                 00051000
AD-   *       CALL 'LIRB0111' USING LR44                                00051100
AD-   *       IF LR44-RETCODE             NOT EQUAL 'NF'                00051200
AD-   *          MOVE '08'     TO ARC130B-RETCODE                       00051300
AD-   *          STRING 'CONTO ESTINGUIBILE E CON AFFIDAMENTO '         00051400
AD-   *                 'REVOCATO'                                      00051500
AD-   *                        DELIMITED BY SIZE                        00051600
AD-   *                      INTO ARC130B-MESSAGGIO                     00051700
AD-   *                      PERFORM 00214-FINE THRU 00214-EX           00051800
AD-   *       END-IF                                                    00051900
AD-   *       IF LR44-RETCODE EQUAL 'NF'                                00052000
AD-   *          MOVE '09'        TO ARC130B-RETCODE                    00052100
AD-   *          STRING 'CONTO IN ATTESA ADDEBITO COMMISSIONI SCOPERTO '00052200
AD-   *                 'DI CONTO PER FINE ANNO'                        00052300
AD-   *                           DELIMITED BY SIZE                     00052400
AD-   *                         INTO ARC130B-MESSAGGIO                  00052500
AD-   *                      PERFORM 00214-FINE THRU 00214-EX           00052600
AD-   *       END-IF                                                    00052700
      *       IF NIMM-RETCODE NOT = '00' AND '01'                       00052800
      *          MOVE '80'           TO ARC130B-RETCODE                 00052900
      *          STRING 'ERRORE ROUTINE "PPTONIMM" - RET.CODE: '        00053000
      *                  NIMM-RETCODE                                   00053100
      *                         DELIMITED BY SIZE                       00053200
      *                            INTO ARC130B-MESSAGGIO               00053300
      *                            PERFORM 00214-FINE THRU 00214-EX     00053400
      *       END-IF                                                    00053500
      *                                                                 00053600
       00212-EX.                                                        00053700
           EXIT.                                                        00053800
      *                                                                 00053900
       00213-LINK-PPTONIMM.                                             00054000
      *                                                                 00054100
           MOVE 'PPTONIMM' TO WS-PROGRAM.                               00054200
                                                                        00054300
           CALL WS-PROGRAM USING PPTCNIMM.                              00054400
      *                                                                 00054500
       00213-EX.                                                        00054600
           EXIT.                                                        00054700
      *                                                                 00054800
       00214-FINE.                                                      00054900
      *                                                                 00055000
      *    MOVE 'OIN'                    TO   LIRDRCA-FUNZ.             00055100
      *    PERFORM ACCESS-LIRDRCA-Y12    THRU ACCESS-LIRDRCA-Y12-EX.    00055200
                                                                        00055300
           GOBACK.                                                      00055400
      *                                                                 00055500
       00214-EX.                                                        00055600
           EXIT.                                                        00055700
      *                                                                 00055800
      ***************************************************************** 00055900
      * ROUTINE DI REPERIMENTO DEL TIMESTAMP                          * 00056000
      ***************************************************************** 00056100
       C0000-LEGGI-TIMESTAMP.                                           00056200
           EXEC SQL                                                     00056300
                SET :WS-TIMESTAMP = CURRENT TIMESTAMP                   00056400
           END-EXEC.                                                    00056500
                                                                        00056600
           IF SQLCODE NOT = ZERO                                        00056700
              DISPLAY 'LABEL C0000-TIMESTAMP'                           00056800
              DISPLAY 'ERRORE ' SQLCODE                                 00056900
                      ' SU TIMESTAMP'                                   00057000
                 STRING 'ERRORE ACQUISIZIONE DATA DI SISTEMA'           00057100
                         DELIMITED BY SIZE                              00057200
                         INTO ARC130B-MESSAGGIO                         00057300
           END-IF.                                                      00057400
                                                                        00057500
           MOVE WS-TIMESTAMP                TO WS-TIMESTAMP-RED.        00057600
                                                                        00057700
           MOVE ANNO-SIST                   TO ANNO-SISTEMA             00057800
                                               WS-SSAA-INI.             00057900
                                                                        00058000
           MOVE MESE-SIST                   TO MESE-SISTEMA.            00058100
                                                                        00058200
           MOVE GIORNO-SIST                 TO GIORNO-SISTEMA.          00058300
                                                                        00058400
      *    DISPLAY 'DATA-SISTEMA:' DATA-SISTEMA.                        00058500
                                                                        00058600
       EX-C0000-LEGGI-TIMESTAMP.                                        00058700
           EXIT.                                                        00058800
                                                                        00058900
       ACCESS-LIRDRCA-Y12.                                              00059000
                                                                        00059100
           MOVE SPACES              TO AREA-ARCHIVIO.                   00059200
           MOVE LIRDRCA-TRAC        TO ARCHIVIO-TRAC.                   00059300
           MOVE LIRDRCA-FUNZ        TO ARCHIVIO-FUNZ.                   00059400
           MOVE 'ARRAB130'          TO ARCHIVIO-PGM.                    00059500
           MOVE DATA-SIST-AMG       TO ARCHIVIO-DATA.                   00059600
           MOVE 0                   TO ARCHIVIO-ORA.                    00059700
           MOVE LIRDRCA-TIPOMOD     TO ARCHIVIO-TIPOMOD.                00059800
           MOVE LIRDRCA-REC         TO ARCHIVIO-REC.                    00059900
           CALL 'LIRYDRCA'          USING AREA-ARCHIVIO.                00060000
           MOVE ARCHIVIO-REC        TO LIRDRCA-REC.                     00060100
           MOVE ARCHIVIO-SW         TO SW-LIRDRCA.                      00060200
       ACCESS-LIRDRCA-Y12-EX.                                           00060300
           EXIT.                                                        00060400
                                                                        00060500
