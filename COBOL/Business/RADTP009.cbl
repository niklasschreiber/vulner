      ******************************************************************00000100
      * NOTE:                                                           00000200
      ******************************************************************00000300
      *                                                                 00000400
      * PRODOTTO : SISTEMA RAPPORTI DORMIENTI                           00000500
      *                                                                 00000600
      * FUNZIONE : INSERIMENTO PARAMETRI                                00000700
      *                                                                 00000800
      * AUTORE   : ENGINEERING                                          00000900
      *                                                                 00001000
      * PROGRAMMA: RADTP009, COBOL/CICS                                 00001100
      *                                                                 00001200
      * MAPSET   : RADSH09                                              00001300
      *                                                                 00001400
      * MAPPA    : RADMH09                                              00001500
      *                                                                 00001600
      * TRANSID  : RADO                                                 00001700
      *                                                                 00001800
      * PLAN     : RADOPX01                                             00001900
      *                                                                 00002000
      ******************************************************************00002100
       IDENTIFICATION DIVISION.                                         00002200
       PROGRAM-ID.    RADTP009.                                         00002300
      ******************************************************************00002400
       ENVIRONMENT DIVISION.                                            00002500
       CONFIGURATION SECTION.                                           00002600
       SPECIAL-NAMES.                                                   00002700
           DECIMAL-POINT IS COMMA.                                      00002800
      ******************************************************************00002900
       DATA DIVISION.                                                   00003000
       WORKING-STORAGE SECTION.                                         00003100
       01                           PIC X(16) VALUE '** AREA TRACE **'. 00003200
           COPY RADCXW00.                                               00003300
      *---   TRACCIATO COMMAREA                                         00003400
       01                           PIC X(16) VALUE '*** COMMAREA ***'. 00003500
       01  TRASF-DATI.                                                  00003600
0212       02 TR-DATI-PSEUDO.                                           00003700
             03  TR-IND-PSEUDO      PIC 9(02).                          00003800
      *  TABELLA PER PSEUDOCONVERSAZIONALITA E PAGINAZIONE              00003900
             03  TR-PSEUDO          OCCURS 10.                          00004000
               04  TR-GIRO          PIC 9(02).                          00004100
               04  TR-PROGRAM       PIC X(08).                          00004200
               04  TR-ITEM          PIC S9(04) COMP.                    00004300
               04  TR-NPAGINA       PIC 9(05).                          00004400
               04  TR-IND-SEL       PIC 9(02).                          00004500
               04  TR-IND-LAST      PIC 9(02).                          00004600
2000       COPY RADCX001.                                               00004700
3000       02                       PIC X(3000).                        00004800
      *---   COPY MESSAGGI ERRORE                                       00004810
       01                           PIC X(16) VALUE '*** AREA MSG ***'. 00004820
           COPY RADCX002.                                               00004830
      *---   COPY DESCRIZIONI                                           00004840
       01                           PIC X(16) VALUE '* DESCRIZIONI  *'. 00004850
           COPY RADCX003.                                               00004860
      *---   COPY PARAMETRI                                             00004900
       01                           PIC X(16) VALUE '* AREA RADCDPAR*'. 00005000
           COPY RADCDPAR.                                               00005100
      *---   COPY MAPPA                                                 00005200
       01                           PIC X(16) VALUE '** AREA MAPPA **'. 00005300
           COPY RADMH09.                                                00005400
      *---   COPY AID                                                   00005800
       01                           PIC X(16) VALUE '* AREA SISTEMA *'. 00005900
           COPY DFHAID.                                                 00006000
      *---   COPY RADXDPAR                                              00006100
       01                           PIC X(16) VALUE '* AREA RADXDPAR*'. 00006200
       01  AREA-RADXDPAR.                                               00006300
           03  ARCHIVIO-SW          PIC X(02).                          00006400
           03  ARCHIVIO-TRAC        PIC X(04).                          00006500
           03  ARCHIVIO-FUNZ        PIC X(03).                          00006600
           03  ARCHIVIO-PGM         PIC X(08).                          00006700
           03  ARCHIVIO-DATA        PIC X(08).                          00006800
           03  ARCHIVIO-ORA         PIC X(06).                          00006900
           03  ARCHIVIO-TIPOMOD     PIC X(01).                          00007000
      *---                                '000000' = OK                 00007100
      *                                   '000001' = ERRORE X SEND      00007200
      *                                   '000002' = ERRORE X MSG       00007300
           03  ARCHIVIO-RETCODE     PIC X(06).                          00007400
           03  ARCHIVIO-PAG-TOT     PIC 9(05).                          00007500
           03  ARCHIVIO-FILLER      PIC X(66).                          00007600
           03  ARCHIVIO-REC         PIC X(03000).                       00007700
      *--- VARIABILI DI LAVORO                                          00007800
       01                           PIC X(16) VALUE '***  LAVORO  ***'. 00007900
       01  WS-LAVORO.                                                   00008000
           05 WS-RESP               PIC S9(08) BINARY.                  00008400
           05 WS-MSG-TEXT           PIC X(1920).                        00008500
           05 WS-MSG-LEN            PIC S9(04) BINARY.                  00008600
           05 WS-RADR               PIC 9(08)  BINARY.                  00008700
           05 WS-GGMMAA             PIC 9(06).                          00008800
           05 WS-AAMMGG             PIC 9(06).                          00008900
           05 WS-AAAAMMGG           PIC 9(08).                          00009000
           05 WS-GGMMAAAA           PIC 9(08).                          00009100
           05 WS-GGMMAAAA-TRAT      PIC X(10).                          00009200
           05 WS-HHMMSS             PIC 9(06).                          00009300
           05 WS-HHMMSS-PUNT        PIC X(05).                          00009400
           05 WS-XCTL               PIC X(08).                          00009500
           05 WS-ABSTIME            PIC S9(15) PACKED-DECIMAL.          00009600
           05 WS-RADPARA-REC-LEN    PIC 9(09)  BINARY.                  00010300
      *--- COSTANTI E FLAGS                                             00011700
       01                           PIC X(16) VALUE '*** COSTANTI ***'. 00011800
       01  WK-COSTANTI.                                                 00011900
           05 WK-TRAN               PIC X(04)  VALUE 'RADO'.            00012000
           05 WK-MAP                PIC X(07)  VALUE 'RADMH09'.         00012100
           05 WK-PGM                PIC X(08)  VALUE 'RADTP009'.        00012200
           05 WK-RADXDPAR           PIC X(08)  VALUE 'RADXDPAR'.        00012300
           05 WK-RADR               PIC X(04)  VALUE 'RADR'.            00012400
           05 WK-SWITCH-ERRORE      PIC X(01).                          00012500
              88 NO-ERR                        VALUE ZEROES.            00012600
              88 SI-ERR                        VALUE '1'.               00012700
      *---  AREA ATTRIBUTI STANDARD                                     00013700
       01                           PIC X(16) VALUE '**  ATTRIBUTI **'. 00013800
       01  ATTRIBUTI-BMS.                                               00013900
           03  ATTR-ASK-NOR         PIC X        VALUE '0'.             00014000
           03  ATTR-ASK-NOR-FSE     PIC X        VALUE '1'.             00014100
           03  ATTR-ASK-BRT         PIC X        VALUE '8'.             00014200
           03  ATTR-ASK-BRT-FSE     PIC X        VALUE '9'.             00014300
           03  ATTR-ASK-DRK         PIC X        VALUE '@'.             00014400
           03  ATTR-ASK-DRK-FSE     PIC X        VALUE ''''.            00014500
           03  ATTR-PRO-NOR         PIC X        VALUE '-'.             00014600
           03  ATTR-PRO-NOR-FSE     PIC X        VALUE '/'.             00014700
           03  ATTR-PRO-BRT         PIC X        VALUE 'Y'.             00014800
           03  ATTR-PRO-BRT-FSE     PIC X        VALUE 'Z'.             00014900
           03  ATTR-PRO-DRK         PIC X        VALUE '%'.             00015000
           03  ATTR-PRO-DRK-FSE     PIC X        VALUE '_'.             00015100
           03  ATTR-UNP-NOR         PIC X        VALUE ' '.             00015200
           03  ATTR-UNP-NOR-FSE     PIC X        VALUE 'A'.             00015300
           03  ATTR-UNP-NOR-NUM     PIC X        VALUE '&'.             00015400
           03  ATTR-UNP-NOR-NUM-FSE PIC X        VALUE 'J'.             00015500
           03  ATTR-UNP-BRT         PIC X        VALUE 'H'.             00015600
           03  ATTR-UNP-BRT-FSE     PIC X        VALUE 'I'.             00015700
           03  ATTR-UNP-BRT-NUM     PIC X        VALUE 'Q'.             00015800
           03  ATTR-UNP-BRT-NUM-FSE PIC X        VALUE 'R'.             00015900
           03  ATTR-UNP-DRK         PIC X        VALUE '<'.             00016000
           03  ATTR-UNP-DRK-FSE     PIC X        VALUE '('.             00016100
           03  ATTR-UNP-DRK-NUM     PIC X        VALUE '*'.             00016200
           03  ATTR-UNP-DRK-NUM-FSE PIC X        VALUE ')'.             00016300
      *-----------------------------------------------------------------00016400
       LINKAGE SECTION.                                                 00016500
       01  DFHCOMMAREA              PIC X(10000).                       00016600
      ******************************************************************00016700
       PROCEDURE DIVISION.                                              00016800
           PERFORM C00010-INIT.                                         00016900
           IF EIBAID = DFHCLEAR                                         00017000
              IF EIBCALEN NOT = ZEROES                                  00017100
                 MOVE DFHCOMMAREA            TO TRASF-DATI              00017200
                 PERFORM C90100-FINE-LAVORO                             00017300
              END-IF                                                    00017400
           END-IF.                                                      00017500
           MOVE DFHCOMMAREA                  TO TRASF-DATI.             00017600
           IF TR-PROGRAM(TR-IND-PSEUDO) NOT = WK-PGM                    00017700
              MOVE TR-PROGRAM(TR-IND-PSEUDO) TO WS-XCTL                 00017800
              PERFORM X00030-XCTL-FUNZIONE                              00017900
           END-IF.                                                      00018000
           PERFORM C00020-INQUIRY-TRANS.                                00018100
           EVALUATE RADCX1-STAT                                         00018200
             WHEN '0'                                                   00018300
               PERFORM C00035-CHECK-PARAM                               00018400
               PERFORM C00840-PREP-MAPPA-BODY-X01                       00018410
               MOVE '1'                      TO RADCX1-STAT             00018500
             WHEN '1'                                                   00018600
               PERFORM C00040-GEST-INPUT                                00018700
             WHEN '2'                                                   00018800
???            PERFORM C00030-TEST-ERR-RITORNO                          00018900
               MOVE '1'                      TO RADCX1-STAT             00019100
             WHEN '3'                                                   00019110
               PERFORM C00300-GEST-CONF                                 00019120
             WHEN OTHER                                                 00019200
               MOVE '01'                     TO RADCX1-DESERR(1:2)      00019300
               MOVE WK-PGM                   TO RADCX1-DESERR(3:8)      00019400
               MOVE ' '                      TO RADCX1-DESERR(11:1)     00019500
               MOVE RADCX2-ELEM(004)         TO RADCX1-DESERR(12:)      00019600
               MOVE 3                        TO RADCX1-RETCODE          00019700
               PERFORM C00060-BACK-1-LIV                                00019800
           END-EVALUATE.                                                00019900
           PERFORM C00870-PREP-MAPPA-TESTA.                             00020000
           PERFORM X00050-SEND-ERASE.                                   00020020
           PERFORM X00060-RETURN-TRANSID.                               00020100
      *-----------------------------------                              00020200
      *                                                                 00020300
      *----------------------------------                               00020400
       C00010-INIT.                                                     00020500
           MOVE 'C00010-INIT'            TO RADCXW-NOME-ROUTINE.        00020600
                                         PERFORM RADCXP00-TRACE.        00020700
           EXEC CICS HANDLE ABEND                                       00020800
                     LABEL(C90150-GEST-ABEND)                           00020900
                     RESP(WS-RESP)                                      00021000
           END-EXEC.                                                    00021100
           PERFORM C90200-CHECK-ESITO-CICS.                             00021200
           INITIALIZE WS-LAVORO.                                        00021300
           MOVE LENGTH OF RADPARA-REC    TO WS-RADPARA-REC-LEN.         00021400
      *-----------------------------------                              00021500
      * CONTROLLO OPERATIVITA                                           00021600
      *-----------------------------------                              00021700
       C00020-INQUIRY-TRANS.                                            00021800
           MOVE 'C00020-INQUIRY-TRANS'   TO RADCXW-NOME-ROUTINE.        00021900
                                         PERFORM RADCXP00-TRACE.        00022000
           PERFORM X00080-INQUIRY.                                      00022100
           IF WS-RADR NOT = 23                                          00022200
              MOVE '02'                  TO RADCX1-DESERR(1:2)          00022300
              MOVE WK-PGM                TO RADCX1-DESERR(3:8)          00022400
              MOVE ' '                   TO RADCX1-DESERR(11:1)         00022500
              MOVE RADCX2-ELEM(004)      TO RADCX1-DESERR(12:)          00022600
              MOVE 3                     TO RADCX1-RETCODE              00022700
              PERFORM C00060-BACK-1-LIV                                 00022800
           END-IF.                                                      00022900
      *-----------------------------------                              00023000
      * TEST SUL RETCODE DI COMMAREA NEL CASO                           00023100
      * IN CUI HO INTERCETTATO UN ERRORE IN UNO                         00023200
      * DEI PROGRAMMI CHIAMATI CON XCTL VALORI:                         00023300
      * '3' =  VIENE IMPOSTATA LA DESCRIZIONE DI ERRORE                 00023400
      *        DI RITORNO DA PGM CHIAMATI CON XCTL                      00023500
      *-----------------------------------                              00023600
       C00030-TEST-ERR-RITORNO.                                         00023700
           MOVE 'C00030-TEST-ERR-RITORNO' TO RADCXW-NOME-ROUTINE.       00023800
                                         PERFORM RADCXP00-TRACE.        00023900
           EVALUATE RADCX1-RETCODE                                      00024000
             WHEN ZERO                                                  00024100
               CONTINUE                                                 00024200
???          WHEN 3                                                     00024300
               MOVE RADCX1-DESERR        TO H09MES1I                    00024400
               MOVE 0                    TO RADCX1-RETCODE              00024600
               MOVE SPACES               TO RADCX1-DESERR               00024700
             WHEN OTHER                                                 00024800
               PERFORM C90150-GEST-ABEND                                00024900
           END-EVALUATE.                                                00025000
      *-----------------------------------                              00029300
      *                                                                 00029400
      *-----------------------------------                              00029500
       C00035-CHECK-PARAM.                                              00029600
           MOVE 'C00035-CHECK-PARAM'         TO RADCXW-NOME-ROUTINE.    00029700
                                             PERFORM RADCXP00-TRACE.    00029800
           INITIALIZE AREA-RADXDPAR                                     00029801
                      RADPARA-REC.                                      00029802
           MOVE '0002'                       TO ARCHIVIO-TRAC.          00029803
           MOVE 'RED'                        TO ARCHIVIO-FUNZ.          00029804
PK         MOVE RADCX1-SL01-COD-SERV         TO PAR-RDPA-TIPSERV.       00029806
PK         MOVE RADCX1-SL01-TIP-PARAM        TO PAR-RDPA-TIPARAM.       00029807
PK         MOVE RADCX1-SL01-COD-PARAM        TO PAR-RDPA-COPARAM.       00029808
           MOVE RADPARA-REC                  TO ARCHIVIO-REC.           00029811
           PERFORM X00100-LINK.                                         00029812
           EVALUATE ARCHIVIO-RETCODE                                    00029813
             WHEN '000000'                                              00029814
               IF ARCHIVIO-SW = 'NF'                                    00029815
                  CONTINUE                                              00029816
               ELSE                                                     00029817
                  MOVE '03'                  TO RADCX1-DESERR(1:2)      00029818
                  MOVE WK-PGM                TO RADCX1-DESERR(3:8)      00029819
                  MOVE ' '                   TO RADCX1-DESERR(11:1)     00029820
                  MOVE RADCX2-ELEM(058)      TO RADCX1-DESERR(12:)      00029821
                  MOVE 3                     TO RADCX1-RETCODE          00029822
                  PERFORM C00060-BACK-1-LIV                             00029823
               END-IF                                                   00029829
             WHEN '000001'                                              00029830
               IF ARCHIVIO-SW = 'AB'                                    00029831
                  MOVE ARCHIVIO-REC(WS-RADPARA-REC-LEN:720)             00029832
                                             TO RADCX2-MSG-ERR-ABEND    00029833
                  MOVE RADCX2-MSG-ERR-ABEND  TO WS-MSG-TEXT             00029834
               ELSE                                                     00029835
                  MOVE ARCHIVIO-REC(WS-RADPARA-REC-LEN:720)             00029836
                                             TO RADCX2-MSG-ERR-HANDLE   00029837
                  MOVE RADCX2-MSG-ERR-HANDLE TO WS-MSG-TEXT             00029838
               END-IF                                                   00029839
               MOVE RADCX2-MSG-ERR-LEN       TO WS-MSG-LEN              00029840
               PERFORM X00020-SEND-TEXT                                 00029841
               PERFORM X00090-SYNCROLL                                  00029842
             WHEN '000002'                                              00029843
               MOVE ARCHIVIO-REC(WS-RADPARA-REC-LEN:80)                 00029844
                                             TO RADCX1-DESERR           00029845
               MOVE 3                        TO RADCX1-RETCODE          00029846
               PERFORM X00090-SYNCROLL                                  00029847
               PERFORM C00060-BACK-1-LIV                                00029848
           END-EVALUATE.                                                00029849
      *-----------------------------------                              00029850
      *                                                                 00029851
      *-----------------------------------                              00029852
       C00040-GEST-INPUT.                                               00029853
           MOVE 'C00040-GEST-INPUT'      TO RADCXW-NOME-ROUTINE.        00029854
                                         PERFORM RADCXP00-TRACE.        00029860
           PERFORM X00070-RECEIVE.                                      00029900
           PERFORM C00050-PREP-INPUT.                                   00030000
           EVALUATE EIBAID                                              00030100
             WHEN DFHPF3                                                00030200
               PERFORM C00060-BACK-1-LIV                                00030300
             WHEN DFHPF4                                                00030400
               SUBTRACT 1 FROM TR-IND-PSEUDO                            00030500
               PERFORM C00060-BACK-1-LIV                                00030600
             WHEN DFHCLEAR                                              00031100
               PERFORM C90100-FINE-LAVORO                               00031200
             WHEN DFHENTER                                              00031300
               PERFORM C00070-GEST-ENTER                                00031400
             WHEN OTHER                                                 00031500
               MOVE '04'                 TO H09MES1I(1:2)               00031600
               MOVE WK-PGM               TO H09MES1I(3:8)               00031700
               MOVE ' '                  TO H09MES1I(11:1)              00031800
               MOVE RADCX2-ELEM(001)     TO H09MES1I(12:)               00031900
               MOVE -1                   TO H09PRDEL                    00032000
               INSPECT H09PRDEI REPLACING ALL SPACES BY '_'             00032010
               MOVE ATTR-UNP-NOR-FSE     TO H09PRDEA                    00032020
           END-EVALUATE.                                                00032100
      *-----------------------------------                              00032200
      *                                                                 00032300
      *-----------------------------------                              00032400
       C00050-PREP-INPUT.                                               00032500
           MOVE 'C00050-PREP-INPUT'      TO RADCXW-NOME-ROUTINE.        00032600
                                         PERFORM RADCXP00-TRACE.        00032700
           INSPECT H09PRDEI REPLACING ALL '_' BY SPACES.                00034000
           INSPECT H09PRDEI REPLACING ALL LOW-VALUE BY SPACES.          00034100
      *-----------------------------------                              00034800
      *                                                                 00034900
      *-----------------------------------                              00035000
       C00060-BACK-1-LIV.                                               00035100
           MOVE 'C00060-BACK-1-LIV'       TO RADCXW-NOME-ROUTINE.       00035200
                                          PERFORM RADCXP00-TRACE.       00035300
           SUBTRACT 1 FROM TR-IND-PSEUDO.                               00035400
           INITIALIZE RADCX1-DATI-PAGINAZIONE                           00035500
                      RADCX1-SL01-MAPPA.                                00035600
           MOVE '2'                       TO RADCX1-STAT.               00035700
           MOVE TR-PROGRAM(TR-IND-PSEUDO) TO WS-XCTL.                   00035800
           PERFORM X00030-XCTL-FUNZIONE.                                00035900
      *-----------------------------------                              00054100
      *                                                                 00054200
      *-----------------------------------                              00054300
       C00070-GEST-ENTER.                                               00054400
           MOVE 'C00070-GEST-ENTER'      TO RADCXW-NOME-ROUTINE.        00054500
                                         PERFORM RADCXP00-TRACE.        00054600
           PERFORM C00080-PREP-CTRL.                                    00054700
           SET NO-ERR                    TO TRUE.                       00054800
           PERFORM C00090-CTRL-DESC.                                    00054900
           IF NO-ERR                                                    00055000
              PERFORM C00850-PREP-MAPPA-BODY-X03                        00055100
              MOVE '3'                   TO RADCX1-STAT                 00055210
           END-IF.                                                      00055300
      *-----------------------------------                              00055400
      *                                                                 00055500
      *-----------------------------------                              00055600
       C00080-PREP-CTRL.                                                00055700
           MOVE 'C00080-PREP-CTRL'       TO RADCXW-NOME-ROUTINE.        00055800
                                         PERFORM RADCXP00-TRACE.        00055900
           MOVE ATTR-UNP-NOR-FSE         TO H09PRDEA.                   00057410
           MOVE SPACES                   TO H09MES1I.                   00057420
      *-----------------------------------                              00057500
      *                                                                 00057600
      *-----------------------------------                              00057700
       C00090-CTRL-DESC.                                                00057800
           MOVE 'C00090-CTRL-DESC'       TO RADCXW-NOME-ROUTINE.        00057900
                                         PERFORM RADCXP00-TRACE.        00058000
           IF H09PRDEI = SPACES                                         00058100
              SET SI-ERR                 TO TRUE                        00058300
              MOVE '05'                  TO H09MES1I(1:2)               00058400
              MOVE WK-PGM                TO H09MES1I(3:8)               00058500
              MOVE ' '                   TO H09MES1I(11:1)              00058600
              MOVE RADCX2-ELEM(012)      TO H09MES1I(12:)               00058700
              MOVE -1                    TO H09PRDEL                    00058900
              INSPECT H09PRDEI REPLACING ALL SPACES BY '_'              00059000
              MOVE ATTR-UNP-NOR-FSE      TO H09PRDEA                    00059010
           END-IF.                                                      00059100
      *-----------------------------------                              00060700
      *                                                                 00060800
      *-----------------------------------                              00060900
       C00300-GEST-CONF.                                                00061000
           MOVE 'C00300-GEST-CONF'       TO RADCXW-NOME-ROUTINE.        00061100
                                         PERFORM RADCXP00-TRACE.        00061200
           PERFORM X00070-RECEIVE.                                      00061210
           PERFORM C00310-PREP-INPUT.                                   00061220
           EVALUATE EIBAID                                              00061230
             WHEN DFHPF3                                                00061240
               PERFORM C00060-BACK-1-LIV                                00061250
             WHEN DFHPF4                                                00061260
               SUBTRACT 1 FROM TR-IND-PSEUDO                            00061270
               PERFORM C00060-BACK-1-LIV                                00061280
             WHEN DFHCLEAR                                              00061290
               PERFORM C90100-FINE-LAVORO                               00061291
             WHEN DFHENTER                                              00061292
               PERFORM C00320-GEST-INPUT-CONF                           00061293
             WHEN OTHER                                                 00061294
               MOVE '06'                 TO H09MES1I(1:2)               00061295
               MOVE WK-PGM               TO H09MES1I(3:8)               00061296
               MOVE ' '                  TO H09MES1I(11:1)              00061297
               MOVE RADCX2-ELEM(001)     TO H09MES1I(12:)               00061298
               MOVE -1                   TO H09CONFL                    00061299
               INSPECT H09CONFI REPLACING ALL SPACES BY '_'             00061300
               MOVE ATTR-UNP-NOR-FSE     TO H09CONFA                    00061301
               MOVE ATTR-ASK-BRT-FSE     TO H09PRDEA                    00061302
           END-EVALUATE.                                                00061303
      *-----------------------------------                              00061304
      *                                                                 00061305
      *-----------------------------------                              00061306
       C00310-PREP-INPUT.                                               00061307
           MOVE 'C00310-PREP-INPUT'      TO RADCXW-NOME-ROUTINE.        00061308
                                         PERFORM RADCXP00-TRACE.        00061309
           INSPECT H09CONFI REPLACING ALL '_' BY SPACES.                00061312
           INSPECT H09CONFI REPLACING ALL LOW-VALUE BY SPACES.          00061314
           MOVE ATTR-ASK-BRT-FSE         TO H09PRDEA                    00061316
                                            H09CNF1A                    00061317
                                            H09CNF2A.                   00061318
      *-----------------------------------                              00061319
      *                                                                 00061320
      *-----------------------------------                              00061321
       C00320-GEST-INPUT-CONF.                                          00061322
           MOVE 'C00320-GEST-INPUT-CONF' TO RADCXW-NOME-ROUTINE.        00061323
                                         PERFORM RADCXP00-TRACE.        00061324
           PERFORM C00330-PREP-CTRL.                                    00061325
           SET NO-ERR                    TO TRUE.                       00061326
           PERFORM C00340-CTRL-CONF.                                    00061327
           IF NO-ERR                                                    00061328
              IF H09CONFI = 'S'                                         00061329
                 PERFORM C00350-PREP-INSERT                             00061330
                 PERFORM C00360-INSERT                                  00061331
                 MOVE '07'               TO RADCX1-DESERR(1:2)          00061332
                 MOVE WK-PGM             TO RADCX1-DESERR(3:8)          00061333
                 MOVE ' '                TO RADCX1-DESERR(11:1)         00061334
                 MOVE RADCX2-ELEM(056)   TO RADCX1-DESERR(12:)          00061335
                 MOVE 3                  TO RADCX1-RETCODE              00061336
                 PERFORM C00060-BACK-1-LIV                              00061337
              ELSE                                                      00061338
                 MOVE '1'                TO RADCX1-STAT                 00061339
                 PERFORM C00860-PREP-MAPPA-BODY-X04                     00061341
              END-IF                                                    00061343
           END-IF.                                                      00061344
      *-----------------------------------                              00061345
      *                                                                 00061346
      *-----------------------------------                              00061347
       C00330-PREP-CTRL.                                                00061348
           MOVE 'C00330-PREP-CTRL'       TO RADCXW-NOME-ROUTINE.        00061349
                                         PERFORM RADCXP00-TRACE.        00061350
           MOVE ATTR-UNP-NOR-FSE         TO H09CONFA.                   00061360
           MOVE SPACES                   TO H09MES1I.                   00061370
      *-----------------------------------                              00061380
      *                                                                 00061390
      *-----------------------------------                              00061400
       C00340-CTRL-CONF.                                                00061500
           MOVE 'C00340-CTRL-CONF'       TO RADCXW-NOME-ROUTINE.        00061600
                                         PERFORM RADCXP00-TRACE.        00061700
           IF H09CONFI > SPACES                                         00062510
              IF H09CONFI NOT = 'S' AND 'N'                             00062511
                 SET SI-ERR              TO TRUE                        00062520
                 MOVE '08'               TO H09MES1I(1:2)               00062530
                 MOVE WK-PGM             TO H09MES1I(3:8)               00062540
                 MOVE ' '                TO H09MES1I(11:1)              00062550
                 MOVE RADCX2-ELEM(055)   TO H09MES1I(12:)               00062560
                 MOVE -1                 TO H09CONFL                    00062570
                 INSPECT H09CONFI REPLACING ALL SPACES BY '_'           00062571
                 MOVE ATTR-UNP-BRT-FSE   TO H09CONFA                    00062572
              END-IF                                                    00062580
           END-IF.                                                      00062590
           IF H09CONFI = SPACES                                         00062591
              SET SI-ERR                 TO TRUE                        00062592
              MOVE '09'                  TO H09MES1I(1:2)               00062593
              MOVE WK-PGM                TO H09MES1I(3:8)               00062594
              MOVE ' '                   TO H09MES1I(11:1)              00062595
              MOVE RADCX2-ELEM(012)      TO H09MES1I(12:)               00062596
              MOVE -1                    TO H09CONFL                    00062597
              INSPECT H09CONFI REPLACING ALL SPACES BY '_'              00062598
              MOVE ATTR-UNP-BRT-FSE      TO H09CONFA                    00062599
           END-IF.                                                      00062600
      *-----------------------------------                              00062700
      *                                                                 00062800
      *-----------------------------------                              00062900
       C00350-PREP-INSERT.                                              00062910
           MOVE 'C00350-PREP-INSERT'     TO RADCXW-NOME-ROUTINE.        00063100
                                         PERFORM RADCXP00-TRACE.        00063110
           INITIALIZE AREA-RADXDPAR.                                    00063111
           MOVE '0001'                   TO ARCHIVIO-TRAC.              00063113
           MOVE 'WRT'                    TO ARCHIVIO-FUNZ.              00063114
           MOVE '01'                     TO PAR-RDPA-ISTITUT.           00063115
PK         MOVE RADCX1-SL01-COD-SERV     TO PAR-RDPA-TIPSERV.           00063116
PK         MOVE RADCX1-SL01-TIP-PARAM    TO PAR-RDPA-TIPARAM.           00063117
PK         MOVE RADCX1-SL01-COD-PARAM    TO PAR-RDPA-COPARAM.           00063148
PK         MOVE '0'                      TO PAR-RDPA-STPARAM.           00063149
           MOVE H09PRDEI                 TO PAR-RDPA-DEPARAM.           00063150
           PERFORM X00040-GEST-DATA-ORA.                                00063151
PK         MOVE WS-AAAAMMGG              TO PAR-RDPA-DTINIVA.           00063159
           MOVE 99999999                 TO PAR-RDPA-DTFINVA.           00063160
           MOVE WS-AAAAMMGG              TO PAR-RDPA-DATAIMM.           00063161
           MOVE WS-HHMMSS                TO PAR-RDPA-ORAIMM.            00063162
           MOVE EIBTRMID                 TO PAR-RDPA-TERMI.             00063163
           MOVE RADCX1-PROFILO           TO PAR-RDPA-COPERI.            00063164
           MOVE SPACES                   TO PAR-RDPA-AUTORI.            00063165
           MOVE RADCX1-DIPEIMM           TO PAR-RDPA-DIPEIMM.           00063166
           MOVE ZEROES                   TO PAR-RDPA-DATPERI            00063167
                                            PAR-RDPA-ORAPERI            00063168
                                            PAR-RDPA-DATAANN            00063169
                                            PAR-RDPA-ORAANN.            00063170
           MOVE SPACES                   TO PAR-RDPA-TERMA              00063171
                                            PAR-RDPA-COPERA             00063172
                                            PAR-RDPA-AUTORA             00063173
                                            PAR-RDPA-DIPEANN.           00063174
           MOVE ZEROES                   TO PAR-RDPA-DATPERA            00063175
                                            PAR-RDPA-ORAPERA.           00063176
           MOVE RADPARA-REC              TO ARCHIVIO-REC.               00063180
      *-----------------------------------                              00063181
      *                                                                 00063182
      *-----------------------------------                              00063183
       C00360-INSERT.                                                   00063184
           MOVE 'C00360-INSERT'          TO RADCXW-NOME-ROUTINE.        00063185
                                         PERFORM RADCXP00-TRACE.        00063186
           PERFORM X00100-LINK.                                         00063187
           EVALUATE ARCHIVIO-RETCODE                                    00063188
             WHEN '000000'                                              00063189
               CONTINUE                                                 00063190
             WHEN '000001'                                              00063191
               IF ARCHIVIO-SW = 'AB'                                    00063192
                  MOVE ARCHIVIO-REC(WS-RADPARA-REC-LEN:720)             00063193
                                             TO RADCX2-MSG-ERR-ABEND    00063194
                  MOVE RADCX2-MSG-ERR-ABEND  TO WS-MSG-TEXT             00063195
               ELSE                                                     00063196
                  MOVE ARCHIVIO-REC(WS-RADPARA-REC-LEN:720)             00063197
                                             TO RADCX2-MSG-ERR-HANDLE   00063198
                  MOVE RADCX2-MSG-ERR-HANDLE TO WS-MSG-TEXT             00063199
               END-IF                                                   00063200
               MOVE RADCX2-MSG-ERR-LEN       TO WS-MSG-LEN              00063201
               PERFORM X00020-SEND-TEXT                                 00063204
               PERFORM X00090-SYNCROLL                                  00063205
             WHEN '000002'                                              00063206
               MOVE ARCHIVIO-REC(WS-RADPARA-REC-LEN:80)                 00063207
                                             TO RADCX1-DESERR           00063208
               MOVE 3                        TO RADCX1-RETCODE          00063209
               PERFORM X00090-SYNCROLL                                  00063210
               PERFORM C00060-BACK-1-LIV                                00063211
           END-EVALUATE.                                                00063212
      *-----------------------------------                              00063213
      *                                                                 00063214
      *-----------------------------------                              00063215
       C00840-PREP-MAPPA-BODY-X01.                                      00063216
           MOVE 'C00840-PREP-MAPPA-BODY-X01'  TO RADCXW-NOME-ROUTINE.   00063217
                                              PERFORM RADCXP00-TRACE.   00063218
           MOVE SPACES                        TO H09PRDEI               00063224
                                                 H09CNF1I               00063226
                                                 H09CONFI               00063227
                                                 H09CNF2I.              00063228
           INSPECT H09PRDEI REPLACING ALL SPACES BY '_'.                00063229
           MOVE ATTR-UNP-NOR-FSE              TO H09PRDEA.              00063230
           MOVE -1                            TO H09PRDEL.              00063233
      *-----------------------------------                              00063240
      *                                                                 00063300
      *-----------------------------------                              00063400
       C00850-PREP-MAPPA-BODY-X03.                                      00063500
           MOVE 'C00850-PREP-MAPPA-BODY-X03'  TO RADCXW-NOME-ROUTINE.   00063600
                                              PERFORM RADCXP00-TRACE.   00063700
           INSPECT H09PRDEI REPLACING ALL '_' BY SPACES.                00063800
           INSPECT H09PRDEI REPLACING ALL LOW-VALUE BY SPACES.          00063900
           MOVE 'CONFERMA:'                   TO H09CNF1I.              00063910
           MOVE '(S=SI,N=NO)'                 TO H09CNF2I.              00063920
           MOVE ATTR-ASK-BRT-FSE              TO H09PRDEA               00064000
                                                 H09CNF1A               00064010
                                                 H09CNF2A.              00064020
           MOVE '_'                           TO H09CONFI.              00064300
           MOVE ATTR-UNP-NOR-FSE              TO H09CONFA.              00064400
           MOVE -1                            TO H09CONFL.              00064500
      *-----------------------------------                              00064600
      *                                                                 00064700
      *-----------------------------------                              00064800
       C00860-PREP-MAPPA-BODY-X04.                                      00064900
           MOVE 'C00860-PREP-MAPPA-BODY-X04'  TO RADCXW-NOME-ROUTINE.   00065000
                                              PERFORM RADCXP00-TRACE.   00065100
           MOVE SPACES                        TO H09CNF1I               00065700
                                                 H09CONFI               00065800
                                                 H09CNF2I.              00065900
           INSPECT H09PRDEI REPLACING ALL SPACES BY '_'.                00066000
           MOVE ATTR-UNP-NOR-FSE              TO H09PRDEA.              00066100
           MOVE ATTR-ASK-DRK-FSE              TO H09CNF1A               00066200
                                                 H09CONFA               00066300
                                                 H09CNF2A.              00066400
           MOVE -1                            TO H09PRDEL.              00066500
      *-----------------------------------                              00124800
      *                                                                 00124900
      *-----------------------------------                              00125000
       C00870-PREP-MAPPA-TESTA.                                         00125100
           MOVE 'C00870-PREP-MAPPA-TESTA'  TO RADCXW-NOME-ROUTINE.      00125200
                                           PERFORM RADCXP00-TRACE.      00125300
           MOVE WK-TRAN                    TO H09TRANI(1:4).            00125400
           MOVE WK-MAP                     TO H09TRANI(5:7).            00125500
           PERFORM X00040-GEST-DATA-ORA.                                00125600
           MOVE WS-GGMMAAAA(1:2)           TO WS-GGMMAAAA-TRAT(1:2).    00125700
           MOVE WS-GGMMAAAA(3:2)           TO WS-GGMMAAAA-TRAT(4:2).    00125800
           MOVE WS-GGMMAAAA(5:4)           TO WS-GGMMAAAA-TRAT(7:4).    00125900
           MOVE '/'                        TO WS-GGMMAAAA-TRAT(3:1)     00126000
                                              WS-GGMMAAAA-TRAT(6:1).    00126100
           MOVE WS-GGMMAAAA-TRAT           TO H09DATAI.                 00126200
           MOVE WS-HHMMSS(1:2)             TO WS-HHMMSS-PUNT(1:2).      00126300
           MOVE WS-HHMMSS(3:2)             TO WS-HHMMSS-PUNT(4:2).      00126400
           MOVE ':'                        TO WS-HHMMSS-PUNT(3:1).      00126500
           MOVE WS-HHMMSS-PUNT             TO H09ORAI.                  00126600
           MOVE RADCX1-SL01-COD-SERV       TO H09SERCI.                 00126700
           EVALUATE RADCX1-SL01-COD-SERV                                00126800
             WHEN 'CC'                                                  00126900
               MOVE RADCX3-LS-DESC(01)(3:) TO H09SERDI                  00127000
             WHEN 'DR'                                                  00127100
               MOVE RADCX3-LS-DESC(02)(3:) TO H09SERDI                  00127200
             WHEN 'DT'                                                  00127300
               MOVE RADCX3-LS-DESC(03)(3:) TO H09SERDI                  00127400
           END-EVALUATE.                                                00127500
           MOVE RADCX1-SL01-COD-PARAM      TO H09PRCDI.                 00127600
      *-----------------------------------                              00134800
      *                                                                 00134900
      *-----------------------------------                              00135000
       C90100-FINE-LAVORO.                                              00135100
           MOVE 'C90100-FINE-LAVORO'     TO RADCXW-NOME-ROUTINE.        00135200
                                         PERFORM RADCXP00-TRACE.        00135300
           MOVE '*** FINE LAVORO ***'    TO WS-MSG-TEXT.                00135400
           MOVE 20                       TO WS-MSG-LEN.                 00135500
           PERFORM X00020-SEND-TEXT.                                    00135600
      *-----------------------------------                              00135700
      *                                                                 00135800
      *-----------------------------------                              00135900
       C90150-GEST-ABEND.                                               00136000
           MOVE RADCXW-NOME-ROUTINE      TO WS-PARAGRAFO                00136100
                                         OF RADCX2-MSG-ERR-ABEND.       00136200
           PERFORM X00010-ABEND.                                        00136300
           PERFORM X00090-SYNCROLL.                                     00136310
           MOVE WK-PGM                   TO WS-PROGRAMMA                00136400
                                         OF RADCX2-MSG-ERR-ABEND.       00136500
           MOVE RADCX2-MSG-ERR-ABEND     TO WS-MSG-TEXT.                00136600
           MOVE RADCX2-MSG-ERR-LEN       TO WS-MSG-LEN.                 00136700
           PERFORM X00020-SEND-TEXT.                                    00136800
      *-----------------------------------                              00136900
      *                                                                 00137000
      *-----------------------------------                              00137100
       C90200-CHECK-ESITO-CICS.                                         00137200
           IF WS-RESP NOT = ZEROES                                      00137300
              MOVE RADCXW-NOME-ROUTINE     TO WS-PARAGRAFO              00137400
                                           OF RADCX2-MSG-ERR-HANDLE     00137500
              MOVE WK-PGM                  TO WS-PROGRAMMA              00137600
                                           OF RADCX2-MSG-ERR-HANDLE     00137700
              MOVE WS-RESP                 TO WS-RESP-9                 00137800
              MOVE RADCX2-MSG-ERR-HANDLE   TO WS-MSG-TEXT               00137900
              MOVE RADCX2-MSG-ERR-LEN      TO WS-MSG-LEN                00138000
              PERFORM X00020-SEND-TEXT                                  00138100
              PERFORM X00090-SYNCROLL                                   00138110
           END-IF.                                                      00138200
      *-----------------------------------                              00138300
      *                                                                 00138400
      *-----------------------------------                              00138500
       X00010-ABEND.                                                    00138600
           MOVE 'X00010-ABEND 1'         TO RADCXW-NOME-ROUTINE.        00138700
                                         PERFORM RADCXP00-TRACE.        00138800
           EXEC CICS ASSIGN                                             00138900
                     ABCODE(WS-ABEND-CODE)                              00139000
                     RESP(WS-RESP)                                      00139100
           END-EXEC.                                                    00139200
           PERFORM C90200-CHECK-ESITO-CICS.                             00139300
           MOVE 'X00010-ABEND 2'         TO RADCXW-NOME-ROUTINE.        00139400
                                         PERFORM RADCXP00-TRACE.        00139500
           EXEC CICS HANDLE ABEND                                       00139600
                     CANCEL                                             00139700
                     RESP(WS-RESP)                                      00139800
           END-EXEC.                                                    00139900
           PERFORM C90200-CHECK-ESITO-CICS.                             00140000
      *-----------------------------------                              00140100
      *                                                                 00140200
      *-----------------------------------                              00140300
       X00020-SEND-TEXT.                                                00140400
           MOVE 'X00020-SEND-TEXT'       TO RADCXW-NOME-ROUTINE.        00140500
                                         PERFORM RADCXP00-TRACE.        00140600
           EXEC CICS SEND                                               00140700
                     TEXT                                               00140800
                     FROM(WS-MSG-TEXT)                                  00140900
                     LENGTH(WS-MSG-LEN)                                 00141000
                     ERASE                                              00141100
                     RESP(WS-RESP)                                      00141200
           END-EXEC.                                                    00141300
           EXEC CICS RETURN END-EXEC.                                   00141400
      *-----------------------------------                              00141500
      *                                                                 00141600
      *-----------------------------------                              00141700
       X00030-XCTL-FUNZIONE.                                            00141800
           MOVE 'X00030-XCTL-FUNZIONE'   TO RADCXW-NOME-ROUTINE.        00141900
                                         PERFORM RADCXP00-TRACE.        00142000
           EXEC CICS XCTL                                               00142100
                     PROGRAM(WS-XCTL)                                   00142200
                     COMMAREA(TRASF-DATI)                               00142300
                     LENGTH(LENGTH OF TRASF-DATI)                       00142400
                     RESP(WS-RESP)                                      00142500
           END-EXEC.                                                    00142600
           PERFORM C90200-CHECK-ESITO-CICS.                             00142700
      *-----------------------------------                              00142800
      * ACQUISIZIONE DATA E ORA                                         00142900
      *-----------------------------------                              00143000
       X00040-GEST-DATA-ORA.                                            00143100
           MOVE 'X00040-GEST-DATA-ORA 1' TO RADCXW-NOME-ROUTINE.        00143200
                                         PERFORM RADCXP00-TRACE.        00143300
           EXEC CICS ASKTIME                                            00143400
                     ABSTIME(WS-ABSTIME)                                00143500
                     RESP(WS-RESP)                                      00143600
           END-EXEC.                                                    00143700
           PERFORM C90200-CHECK-ESITO-CICS.                             00143800
           MOVE 'X00040-GEST-DATA-ORA 2' TO RADCXW-NOME-ROUTINE.        00143900
                                         PERFORM RADCXP00-TRACE.        00144000
           EXEC CICS FORMATTIME                                         00144100
                     ABSTIME(WS-ABSTIME)                                00144200
                     DDMMYY(WS-GGMMAA)                                  00144300
                     YYMMDD(WS-AAMMGG)                                  00144400
                     DDMMYYYY(WS-GGMMAAAA)                              00144500
                     YYYYMMDD(WS-AAAAMMGG)                              00144600
                     TIME(WS-HHMMSS)                                    00144700
                     RESP(WS-RESP)                                      00144800
           END-EXEC.                                                    00144900
           PERFORM C90200-CHECK-ESITO-CICS.                             00145000
      *-----------------------------------                              00145100
      *                                                                 00145200
      *-----------------------------------                              00145300
       X00050-SEND-ERASE.                                               00145400
           MOVE 'X00050-SEND-ERASE'      TO RADCXW-NOME-ROUTINE.        00145500
                                         PERFORM RADCXP00-TRACE.        00145600
           EXEC CICS SEND                                               00145700
                     MAP(WK-MAP)                                        00145800
                     FROM(RADMH09I)                                     00145900
                     ERASE                                              00146000
                     CURSOR                                             00146100
                     FREEKB                                             00146200
                     RESP(WS-RESP)                                      00146300
           END-EXEC.                                                    00146400
           PERFORM C90200-CHECK-ESITO-CICS.                             00146500
      *-----------------------------------                              00146600
      *                                                                 00146700
      *-----------------------------------                              00146800
       X00060-RETURN-TRANSID.                                           00146900
           MOVE 'X00060-RETURN-TRANSID'  TO RADCXW-NOME-ROUTINE.        00147000
                                         PERFORM RADCXP00-TRACE.        00147100
           EXEC CICS RETURN                                             00147200
                     TRANSID(WK-TRAN)                                   00147300
                     COMMAREA(TRASF-DATI)                               00147400
                     LENGTH(LENGTH OF TRASF-DATI)                       00147500
                     RESP(WS-RESP)                                      00147600
           END-EXEC.                                                    00147700
      *-----------------------------------                              00147800
      *                                                                 00147900
      *-----------------------------------                              00148000
       X00070-RECEIVE.                                                  00148100
           MOVE 'X00070-RECEIVE'         TO RADCXW-NOME-ROUTINE.        00148200
                                         PERFORM RADCXP00-TRACE.        00148300
           EXEC CICS RECEIVE                                            00148400
                     MAP(WK-MAP)                                        00148500
                     INTO(RADMH09I)                                     00148600
                     RESP(WS-RESP)                                      00148700
           END-EXEC.                                                    00148800
           PERFORM C90200-CHECK-ESITO-CICS.                             00148900
      *-----------------------------------                              00149000
      *                                                                 00149100
      *-----------------------------------                              00149200
       X00080-INQUIRY.                                                  00149300
           MOVE 'X00080-INQUIRY'         TO RADCXW-NOME-ROUTINE.        00149400
                                         PERFORM RADCXP00-TRACE.        00149500
           EXEC CICS INQUIRY                                            00149600
                     TRANS(WK-RADR)                                     00149700
                     STATUS(WS-RADR)                                    00149800
                     RESP(WS-RESP)                                      00149900
           END-EXEC.                                                    00150000
           PERFORM C90200-CHECK-ESITO-CICS.                             00150100
      *-----------------------------------                              00150200
      *                                                                 00150300
      *-----------------------------------                              00150400
       X00090-SYNCROLL.                                                 00150500
           MOVE 'X00090-SYNCROLL'        TO RADCXW-NOME-ROUTINE.        00150600
                                         PERFORM RADCXP00-TRACE.        00150700
           EXEC CICS SYNCPOINT                                          00150800
                     ROLLBACK                                           00150900
                     NOHANDLE                                           00151000
           END-EXEC.                                                    00151300
      *-----------------------------------                              00151410
      *                                                                 00151420
      *-----------------------------------                              00151430
       X00100-LINK.                                                     00151440
           MOVE 'X00100-LINK'            TO RADCXW-NOME-ROUTINE.        00151450
                                         PERFORM RADCXP00-TRACE.        00151460
           EXEC CICS LINK                                               00151470
                     PROGRAM(WK-RADXDPAR)                               00151480
                     COMMAREA(AREA-RADXDPAR)                            00151490
                     LENGTH(LENGTH OF AREA-RADXDPAR)                    00151491
                     RESP(WS-RESP)                                      00151492
           END-EXEC.                                                    00151493
           PERFORM C90200-CHECK-ESITO-CICS.                             00151494
      *-----------------------------------                              00151500
      *                                                                 00151600
      *-----------------------------------                              00151700
           COPY RADCXP00.                                               00151800
