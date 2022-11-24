      ******************************************************************00000100
      * NOTE     : SOSP PRESENTI                                        00000200
      *                                                                 00000300
      ******************************************************************00000400
      * MODIFICHE                                                       00000500
      *-----------------------------------                              00000600
      * DATA       : 24/03/2020                                         00000700
      * TAG        : 240320                                             00000800
      * AUTORE     : ENGINEERING - FIDES                                00000900
      * DESCRIZIONE: IMPLEMENTAZIONE GESTIONE CAMPO TIPO RECORD DELLA   00001000
      *              CAUSALE                                            00001100
      *-----------------------------------                              00001200
      ***************************************************************** 00001300
      *                                                                 00001400
      * PRODOTTO : INIZIATIVA 110656                                    00001500
      *                                                                 00001600
      *                                                                 00001700
      * FUNZIONE : AGGIORNAMENTO DESCRIZIONI CAUSALE                    00001800
      *            WRAPPER                                              00001900
      *                                                                 00002000
      * AUTORE   : ENGINEERING I.I.SPA                                  00002100
      *                                                                 00002200
      * PROGRAMMA: FHWPWS02, COBOL/CICS                                 00002300
      *                                                                 00002400
      * TRANSID  : FHW2                                                 00002500
      *                                                                 00002600
      * PLAN/COLL: PFMCPX01/PFMCKX01                                    00002700
      *                                                                 00002800
      ******************************************************************00002900
       IDENTIFICATION DIVISION.                                         00003000
       PROGRAM-ID. FHWPWS02.                                            00003100
      ******************************************************************00003200
       ENVIRONMENT DIVISION.                                            00003300
       CONFIGURATION SECTION.                                           00003400
TEST  *SOURCE-COMPUTER. IBM-3090 WITH DEBUGGING MODE.                   00003500
       SPECIAL-NAMES.                                                   00003600
           DECIMAL-POINT IS COMMA.                                      00003700
      ******************************************************************00003800
       DATA DIVISION.                                                   00003900
       WORKING-STORAGE SECTION.                                         00004000
      *---                               AREA INTERFACCIA INPUT         00004100
       01                           PIC X(16) VALUE '**  FHW02I01  **'. 00004200
       01  FHW02I01-AREA.                                               00004300
           COPY FHW02I01.                                               00004400
      *---                               AREA INTERFACCIA OUTPUT        00004500
       01                           PIC X(16) VALUE '**  FHW02O01  **'. 00004600
       01  FHW02O01-AREA.                                               00004700
           COPY FHW02O01.                                               00004800
      *---                               AREA ROUTINE FHTP0001          00004900
       01                           PIC X(16) VALUE '**  FHCBL001  **'. 00005000
           COPY FHCBL001.                                               00005100
      *---                               COSTANTI E FLAG                00005200
       01                           PIC X(16) VALUE '** WK-COSTANTI**'. 00005300
       01  WK-COSTANTI-FLAG.                                            00005400
240320*    03 WK-REQLEN             PIC 9(05) VALUE 164.                00005500
240320*    03 WK-REQLEN             PIC 9(05) VALUE 171.                00005600
           03 WK-REQLEN             PIC 9(05) VALUE 186.                00005610
           03 WK-RESLEN             PIC 9(05) VALUE 88.                 00005700
SOSP  *    03 WK-SEMA               PIC X(04) VALUE '????'.             00005800
           03 WK-FHTP0001           PIC X(08) VALUE 'FHTP0001'.         00005900
           03 WK-FHWPWS02           PIC X(08) VALUE 'FHWPWS02'.         00006000
           03 FL-ERRORE             PIC 9(03).                          00006100
              88 NO-ERRORE                    VALUE ZEROES.             00006200
              88 SI-ERRORE                    VALUE 999.                00006300
      *---                               VARIABILI DI LAVORO            00006400
       01                           PIC X(16) VALUE '**  WS-LAVORO **'. 00006500
       01  WS-LAVORO.                                                   00006600
           03 WS-APPO-RESP          PIC 9(08).                          00006700
           03 WS-APPO-DESCERR       PIC X(80).                          00006800
           03 WS-DATI-CICS.                                             00006900
              05 WS-CX-ABEND        PIC X(04).                          00007000
              05 WS-CX-ABSTIME      PIC S9(15) PACKED-DECIMAL.          00007100
              05 WS-CX-APPLID       PIC X(08).                          00007200
              05 WS-CX-LINK-PGM     PIC X(08).                          00007300
              05 WS-CX-RESP         PIC S9(08) BINARY.                  00007400
              05 WS-CX-STATUS       PIC 9(08)  BINARY.                  00007500
              05 WS-CX-USERID       PIC X(08).                          00007600
              05 WS-CX-YEAR         PIC S9(08) BINARY.                  00007700
              05 WS-CX-ANNO         PIC 9(04).                          00007800
              05 WS-CX-GGMMAA       PIC 9(06).                          00007900
              05 WS-CX-AAMMGG       PIC 9(06).                          00008000
              05 WS-CX-AAAAMMGG     PIC 9(08).                          00008100
              05 WS-CX-GGMMAAAA     PIC 9(08).                          00008200
              05 WS-CX-HHMMSS       PIC 9(06).                          00008300
      *-----------------------------------------------------------------00008400
       LINKAGE SECTION.                                                 00008500
       01  DFHCOMMAREA              PIC X(1000).                        00008600
      ******************************************************************00008700
       PROCEDURE DIVISION.                                              00008800
      *    DISPLAY 'INIZIO FHWPWS02'.                                   00008810
                                                                        00008820
           PERFORM C00010-INIZIO                                        00008900
SOSP  *    PERFORM C00020-CTRL-SEMA                                     00009000
           PERFORM C00100-CTRL-INPUT-SERV                               00009100
           EVALUATE w02iXcanale                                         00009200
             WHEN 'PFMC'                                                00009300
               PERFORM C01000-GEST-PFMC                                 00009400
           END-EVALUATE                                                 00009500
           PERFORM C99000-FINE                                          00009600
           .                                                            00009700
      *-----------------------------------                              00009800
      *                                                                 00009900
      *-----------------------------------                              00010000
       C00010-INIZIO.                                                   00010100
TEST  *    DISPLAY 'C00010-INIZIO'                                      00010200
           PERFORM X00010-HANDLE-ABEND                                  00010300
           MOVE DFHCOMMAREA(1:WK-REQLEN) TO FHW02I01-AREA               00010700
           INITIALIZE WS-LAVORO                                         00011700
           SET NO-ERRORE                 TO TRUE                        00011800
           PERFORM X00030-FROM-CICS                                     00011900
           .                                                            00012000
      *-----------------------------------                              00012100
      *                                                                 00012200
      *-----------------------------------                              00012300
SOSP  *C00020-CTRL-SEMA.                                                00012400
TEST  *    DISPLAY 'C00020-CTRL-SEMA'                                   00012500
      *    PERFORM X00040-INQUIRY                                       00012600
      *    IF WS-CX-STATUS NOT = 23                                     00012700
      *       SET SI-ERRORE              TO TRUE                        00012800
      *       STRING '10' WK-FHWPWS02 '10'                              00012900
      *              'SOTTOSISTEMA XXXX MOMENTANEAMENTE NON DIS         00013000
      *         DELIMITED BY SIZE      INTO WS-APPO-DESCERR             00013100
      *       END-STRING                                                00013200
      *       PERFORM C99000-FINE                                       00013300
      *    END-IF                                                       00013400
      *    .                                                            00013500
      *-----------------------------------                              00013600
      * CONTROLLI SULL'INPUT DI GESTIONE SERVIZIO                       00013700
      *-----------------------------------                              00013800
       C00100-CTRL-INPUT-SERV.                                          00013900
TEST  *    DISPLAY 'C00100-CTRL-INPUT-SERV'                             00014000
      *    DISPLAY 'w02iXtipoXcanale-num >' w02iXtipoXcanale-num '<'    00014010
      *    DISPLAY 'w02iXtipoXcanale     >' w02iXtipoXcanale     '<'    00014020
                                                                        00014030
           IF w02iXcanale NOT = 'PFMC'                                  00014100
              SET SI-ERRORE              TO TRUE                        00014200
              STRING '12' WK-FHWPWS02 '12'                              00014300
                     'CANALE VALORE ERRATO'                             00014400
                DELIMITED BY SIZE       INTO WS-APPO-DESCERR            00014500
              END-STRING                                                00014600
              PERFORM C99000-FINE                                       00014700
           END-IF                                                       00014800
           IF w02iXtipoXsotts NOT = 'CC' AND 'MO'                       00014900
              SET SI-ERRORE              TO TRUE                        00015000
              STRING '14' WK-FHWPWS02 '14'                              00015100
                     'TIPO SOTTOSISTEMA VALORE ERRATO'                  00015200
                DELIMITED BY SIZE       INTO WS-APPO-DESCERR            00015300
              END-STRING                                                00015400
              PERFORM C99000-FINE                                       00015500
           END-IF                                                       00015600
           IF w02iXcodXcaus = LOW-VALUES OR SPACES OR ZEROES OR         00015700
                              HIGH-VALUES                               00015800
              SET SI-ERRORE              TO TRUE                        00015900
              STRING '16' WK-FHWPWS02 '16'                              00016000
                     'CODICE CAUSALE VALORE ERRATO'                     00016100
                DELIMITED BY SIZE       INTO WS-APPO-DESCERR            00016200
              END-STRING                                                00016300
              PERFORM C99000-FINE                                       00016400
           END-IF                                                       00016500
           IF w02iXdescXbrvXcau-num = 1                                 00016600
              IF w02iXdescXbrvXcau = LOW-VALUES OR SPACES OR ZEROES OR  00016700
                                     HIGH-VALUES                        00016800
                 SET SI-ERRORE           TO TRUE                        00016900
                 STRING '18' WK-FHWPWS02 '18'                           00017000
                        'DESCRIZIONE BREVE CAUSALE VALORE ERRATO'       00017100
                   DELIMITED BY SIZE    INTO WS-APPO-DESCERR            00017200
                 END-STRING                                             00017300
                 PERFORM C99000-FINE                                    00017400
           END-IF END-IF                                                00017500
           IF w02iXdescXbrvXmovXpr-num = 1                              00017600
              IF w02iXdescXbrvXmovXpr = LOW-VALUES OR SPACES OR         00017700
                                        ZEROES OR HIGH-VALUES           00017800
                 SET SI-ERRORE           TO TRUE                        00017900
                 STRING '22' WK-FHWPWS02 '22'                           00018000
                        'DESCRIZIONE BREVE MOVIMENTO VALORE ERRATO'     00018100
                   DELIMITED BY SIZE    INTO WS-APPO-DESCERR            00018200
                 END-STRING                                             00018300
                 PERFORM C99000-FINE                                    00018400
           END-IF END-IF                                                00018500
           IF w02iXdescXmovXpr-num = 1                                  00018600
              IF w02iXdescXmovXpr = LOW-VALUES OR SPACES OR ZEROES OR   00018700
                                    HIGH-VALUES                         00018800
                 SET SI-ERRORE           TO TRUE                        00018900
                 STRING '24' WK-FHWPWS02 '24'                           00019000
                        'DESCRIZIONE MOVIMENTO VALORE ERRATO'           00019100
                   DELIMITED BY SIZE    INTO WS-APPO-DESCERR            00019200
                 END-STRING                                             00019300
                 PERFORM C99000-FINE                                    00019400
           END-IF END-IF                                                00019500
           IF w02iXtipoXcanale-num = 1                                  00019501
              IF w02iXtipoXcanale = LOW-VALUES OR SPACES OR ZEROES OR   00019510
                                    HIGH-VALUES                         00019520
              SET SI-ERRORE              TO TRUE                        00019530
              STRING '26' WK-FHWPWS02 '26'                              00019540
                     'TIPO CANALE NON VALORIZZATO'                      00019550
                DELIMITED BY SIZE       INTO WS-APPO-DESCERR            00019560
              END-STRING                                                00019570
              PERFORM C99000-FINE                                       00019580
              END-IF                                                    00019581
           END-IF                                                       00019590
           IF w02iXcopevar = LOW-VALUES OR SPACES OR ZEROES OR          00019600
                             HIGH-VALUES                                00019700
              SET SI-ERRORE              TO TRUE                        00019800
              STRING '26' WK-FHWPWS02 '26'                              00019900
                     'CODICE OPERATORE VALORE ERRATO'                   00020000
                DELIMITED BY SIZE       INTO WS-APPO-DESCERR            00020100
              END-STRING                                                00020200
              PERFORM C99000-FINE                                       00020300
           END-IF                                                       00020400
           .                                                            00020500
      *-----------------------------------                              00020600
      *                                                                 00020700
      *-----------------------------------                              00020800
       C01000-GEST-PFMC.                                                00020900
TEST  *    DISPLAY 'C01000-GEST-PFMC'                                   00021000
           PERFORM C01010-PREP-X-FHTP0001                               00021100
           PERFORM C80010-CHIAMA-FHTP0001                               00021200
           .                                                            00021300
      *-----------------------------------                              00021400
      *                                                                 00021500
      *-----------------------------------                              00021600
       C01010-PREP-X-FHTP0001.                                          00021700
TEST  *    DISPLAY 'C01010-PREP-X-FHTP0001'                             00021800
           INITIALIZE BL001-REC                                         00021900
                      BL001-AREA-DATI-WS02                              00022000
           MOVE 'WS02'                   TO BL001-TIPSERV               00022100
           MOVE w02iXcanale              TO BL001-AIS02-CANALE          00022200
           MOVE w02iXtipoXsotts          TO BL001-AIS02-TIPO-SOTTS      00022300
           MOVE w02iXcodXcaus            TO BL001-AIS02-COD-CAUS        00022400
           IF w02iXdescXbrvXcau-num = 1                                 00022500
              MOVE w02iXdescXbrvXcau     TO BL001-AIS02-DESC-BRV-CAU    00022600
           END-IF                                                       00022700
           IF w02iXdescXbrvXmovXpr-num = 1                              00022800
              MOVE w02iXdescXbrvXmovXpr  TO BL001-AIS02-DESC-BRV-MOV-PR 00022900
           END-IF                                                       00023000
           IF w02iXdescXmovXpr-num = 1                                  00023100
              MOVE w02iXdescXmovXpr      TO BL001-AIS02-DESC-MOV-PR     00023200
           END-IF                                                       00023300
240320     IF w02iXtipoXrec-num = 1                                     00023310
240320        MOVE w02iXtipoXrec         TO BL001-AIS02-TIPOREC         00023320
240320     END-IF                                                       00023330
           IF w02iXtipoXcanale-num = 1                                  00023400
              MOVE w02iXtipoXcanale      TO BL001-AIS02-TIPOCAN         00023500
           END-IF                                                       00023600
           MOVE w02iXcopevar             TO BL001-AIS02-COPEVAR         00023700
           .                                                            00023800
      *-----------------------------------                              00023900
      *                                                                 00024000
      *-----------------------------------                              00024100
       C80010-CHIAMA-FHTP0001.                                          00024200
TEST  *    DISPLAY 'C80010-CHIAMA-FHTP0001'                             00024300
           PERFORM X00050-LINK-FHTP0001                                 00024400
           EVALUATE BL001-RETCODE                                       00024500
             WHEN ZEROES                                                00024600
               CONTINUE                                                 00024700
             WHEN OTHER                                                 00024800
               SET SI-ERRORE             TO TRUE                        00024900
               MOVE BL001-DESC-ERR       TO WS-APPO-DESCERR             00025000
           END-EVALUATE                                                 00025100
           .                                                            00025200
      *-----------------------------------                              00025300
      *                                                                 00025400
      *-----------------------------------                              00025500
       C90010-PROGRAM-ABEND.                                            00025600
TEST  *    DISPLAY 'C90010-PROGRAM-ABEND'                               00025700
           SET SI-ERRORE                 TO TRUE                        00025800
           PERFORM X00020-ASSIGN-ABEND                                  00025900
           STRING '28' WK-FHWPWS02 '28'                                 00026000
                  ' ERRORE CICS ABEND: '                                00026100
                  WS-CX-ABEND                                           00026200
             DELIMITED BY SIZE         INTO WS-APPO-DESCERR             00026300
           END-STRING                                                   00026400
           PERFORM C99000-FINE                                          00026500
           .                                                            00026600
      *-----------------------------------                              00026700
      *                                                                 00026800
      *-----------------------------------                              00026900
       C90020-CHECK-ESITO-CICS.                                         00027000
TEST  *    DISPLAY 'C90020-CHECK-ESITO-CICS'                            00027100
           IF WS-CX-RESP NOT = ZEROES                                   00027200
              SET SI-ERRORE              TO TRUE                        00027300
              MOVE WS-CX-RESP            TO WS-APPO-RESP                00027400
              STRING '32' WK-FHWPWS02 '32'                              00027500
                     ' ERRORE CICS CONDITION: '                         00027600
                     WS-APPO-RESP                                       00027700
                DELIMITED BY SIZE      INTO WS-APPO-DESCERR             00027800
              END-STRING                                                00027900
              PERFORM C99000-FINE                                       00028000
           END-IF                                                       00028100
           .                                                            00028200
      *-----------------------------------                              00028300
      *                                                                 00028400
      *-----------------------------------                              00028500
       C99000-FINE.                                                     00028600
TEST  *    DISPLAY 'C99000-FINE'                                        00028700
           INITIALIZE FHW02O01-AREA                                     00028800
           MOVE FL-ERRORE                TO w02oXretcode                00028900
           IF SI-ERRORE                                                 00029000
              EXEC CICS SYNCPOINT ROLLBACK END-EXEC                     00029100
              MOVE 1                     TO w02oXdescXerr-num           00029200
              MOVE WS-APPO-DESCERR       TO w02oXdescXerr               00029300
           END-IF                                                       00029400
           MOVE FHW02O01-AREA            TO DFHCOMMAREA(1:WK-RESLEN)    00029500
           PERFORM X90000-RETURN                                        00029900
           .                                                            00030000
      *-----------------------------------                              00030100
      *                                                                 00030200
      *-----------------------------------                              00030300
       X00010-HANDLE-ABEND.                                             00030400
TEST  *    DISPLAY 'X00010-HANDLE-ABEND'                                00030500
           EXEC CICS HANDLE ABEND                                       00030600
                     LABEL(C90010-PROGRAM-ABEND)                        00030700
                     NOHANDLE                                           00030800
           END-EXEC                                                     00030900
           .                                                            00031000
      *-----------------------------------                              00031100
      *                                                                 00031200
      *-----------------------------------                              00031300
       X00020-ASSIGN-ABEND.                                             00031400
TEST  *    DISPLAY 'X00020-ASSIGN-ABEND'                                00031500
           EXEC CICS ASSIGN                                             00031600
                     ABCODE(WS-CX-ABEND)                                00031700
                     NOHANDLE                                           00031800
           END-EXEC                                                     00031900
           .                                                            00032000
      *-----------------------------------                              00032100
      *                                                                 00032200
      *-----------------------------------                              00032300
       X00030-FROM-CICS.                                                00032400
TEST  *    DISPLAY 'X00030-FROM-CICS-01'                                00032500
           EXEC CICS ASSIGN USERID(WS-CX-USERID)                        00032600
                            APPLID(WS-CX-APPLID)                        00032700
                            RESP(WS-CX-RESP)                            00032800
           END-EXEC                                                     00032900
           PERFORM C90020-CHECK-ESITO-CICS                              00033000
TEST  *    DISPLAY 'X00030-FROM-CICS-02'                                00033100
           EXEC CICS ASKTIME                                            00033200
                     ABSTIME(WS-CX-ABSTIME)                             00033300
                     RESP(WS-CX-RESP)                                   00033400
           END-EXEC                                                     00033500
           PERFORM C90020-CHECK-ESITO-CICS                              00033600
TEST  *    DISPLAY 'X00030-FROM-CICS-03'                                00033700
           EXEC CICS FORMATTIME                                         00033800
                     ABSTIME(WS-CX-ABSTIME)                             00033900
                     DDMMYY(WS-CX-GGMMAA)                               00034000
                     YYMMDD(WS-CX-AAMMGG)                               00034100
                     DDMMYYYY(WS-CX-GGMMAAAA)                           00034200
                     YYYYMMDD(WS-CX-AAAAMMGG)                           00034300
                     YEAR(WS-CX-YEAR)                                   00034400
                     TIME(WS-CX-HHMMSS)                                 00034500
                     RESP(WS-CX-RESP)                                   00034600
           END-EXEC                                                     00034700
           PERFORM C90020-CHECK-ESITO-CICS                              00034800
           .                                                            00034900
      *-----------------------------------                              00035000
      *                                                                 00035100
      *-----------------------------------                              00035200
SOSP  *X00040-INQUIRY.                                                  00035300
TEST  *    DISPLAY 'X00040-INQUIRY'                                     00035400
      *    EXEC CICS INQUIRE                                            00035500
      *              TRANS(WK-SEMA)                                     00035600
      *              STATUS(WS-CX-STATUS)                               00035700
      *              RESP(WS-CX-RESP)                                   00035800
      *    END-EXEC                                                     00035900
      *    PERFORM C90020-CHECK-ESITO-CICS                              00036000
      *    .                                                            00036100
      *-----------------------------------                              00036200
      *                                                                 00036300
      *-----------------------------------                              00036400
       X00050-LINK-FHTP0001.                                            00036500
TEST  *    DISPLAY 'X00050-LINK-FHTP0001'                               00036600
           EXEC CICS LINK                                               00036700
                     PROGRAM(WK-FHTP0001)                               00036800
                     COMMAREA(BL001-REC)                                00036900
                     LENGTH(LENGTH OF BL001-REC)                        00037000
                     RESP(WS-CX-RESP)                                   00037100
           END-EXEC                                                     00037200
           PERFORM C90020-CHECK-ESITO-CICS                              00037300
           .                                                            00037400
      *-----------------------------------                              00037500
      *                                                                 00037600
      *-----------------------------------                              00037700
       X90000-RETURN.                                                   00037800
           EXEC CICS RETURN                                             00037900
                     NOHANDLE                                           00038000
           END-EXEC                                                     00038100
           .                                                            00038200
      **********************       END      ****************************00038300
