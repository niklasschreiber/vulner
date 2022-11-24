      ******************************************************************00000100
TOK   * NOTE:                                                           00000200
      ******************************************************************00000300
      *                                                                 00000400
      * PRODOTTO : DRNI                                                 00000500
      *                                                                 00000600
      * FUNZIONE : INSERIM. RICHIESTA LISTA MOVIMENTI PER RAPPORTI DI   00000700
      *            SERVIZIO                                             00000700
      *                                                                 00000800
      * AUTORE   : ENGINEERING SPA                                      00000900
      *                                                                 00001000
      * PROGRAMMA: DLRH0500, COBOL/CICS                                 00001100
      *                                                                 00001200
      * MAPSET   : DLRMH05                                              00001300
      *                                                                 00001400
      * MAPPE    : DLRMH05                                              00001500
      *                                                                 00001600
      * TRANSID  : DRNI                                                 00001700
      *                                                                 00001800
      * PLAN     : DRLIPX01                                             00001900
      *                                                                 00002000
      ******************************************************************00002100
       IDENTIFICATION DIVISION.                                         00002200
       PROGRAM-ID.    DLRH0500.                                         00002300
      ******************************************************************00002400
       ENVIRONMENT DIVISION.                                            00002500
       CONFIGURATION SECTION.                                           00002600
       SPECIAL-NAMES.                                                   00002700
           DECIMAL-POINT IS COMMA.                                      00002800
      ******************************************************************00002900
       DATA DIVISION.                                                   00003000
       WORKING-STORAGE SECTION.                                         00003100
       01                           PIC X(16) VALUE '** AREA TRACE **'.
          COPY SSVCXW00.
      *---   TRACCIATO COMMAREA                                         00003400
       01                           PIC X(16) VALUE '**  COMMAREA  **'. 00003500
       01  TRASF-DATI.                                                  00003600
0212       02 TR-DATI-PSEUDO.                                           00003700
             03  TR-IND-PSEUDO      PIC 9(02).                          00003800
             03  TR-PSEUDO          OCCURS 10.                          00004000
               04  TR-GIRO          PIC 9(02).                          00004100
               04  TR-PROGRAM       PIC X(08).                          00004200
               04  TR-ITEM          PIC S9(04) BINARY.                  00004300
               04  TR-NPAGINA       PIC 9(05).                          00004400
               04  TR-IND-SEL       PIC 9(02).                          00004500
               04  TR-IND-LAST      PIC 9(02).                          00004600
           COPY DLRCD100.                                               00004700
      *--- COPY ROUTINE DLRXDRNI                                        00005401
       01                           PIC X(16) VALUE '**  DLRCDRNI  **'. 00005410
           COPY DLRCDRNI.                                               00005420
      *--- COPY ACCESSO GTTBCC03
       01                           PIC X(16) VALUE '**  GTTBCC03  **'.
           COPY GTCC03C0.
      *--- COPY ROUTINE SRVI0022                                        00005430
       01                           PIC X(16) VALUE '**  SRVCD022  **'. 00005460
           COPY SRVCD022.                                               00005470
      *--- COPY ROUTINE SRVI0090
       01                           PIC X(16) VALUE '**  SRVCRVB5  **'.
       01  AREA-SRVCRVB5.
           COPY SRVCRVB5.
      *--- COPY ROUTINE SRVXD002                                        00005401
       01                           PIC X(16) VALUE '**  SRVCD002  **'. 00005410
           COPY SRVCD002.                                               00005420
      *--- AREA DI INTERFACCIA TB2XR002 CON MODULI I/O SPECIFICI
       01                           PIC X(16) VALUE '**  AREA-TBO2 **'.
       01  AREA-TBO2.
           COPY TB2CTBO2.
      *--- COPY ROUTINE STVO0390
       01                           PIC X(16) VALUE '**  STVO0390  **'.
       01  DATI-ERR.
           05 DATI-ERR-PGM          PIC X(08).
           05 DATI-ERR-ABEND        PIC X(04).
           05 DATI-ERR-TIPOTERM     PIC X(01).
           05 DATI-ERR-EIB          PIC X(100).
           05 DATI-ERR-MES1         PIC X(60).
           05 DATI-ERR-MES2         PIC X(60).
           05 DATI-ERR-DES1         PIC X(10).
           05 DATI-ERR-DES2         PIC X(10).
           05 DATI-ERR-FILLER       PIC X(47).
      *--- AREA STANDARD PER ROUTINE SERVIZIO                           00012801
       01                           PIC X(16) VALUE '**  ARCHIVIO  **'. 00012802
       01  AREA-ARCHIVIO.                                               00012840
           03  ARCHIVIO-SW          PIC X(02).                          00012850
           03  ARCHIVIO-TRAC        PIC X(04).                          00012860
           03  ARCHIVIO-FUNZ        PIC X(03).                          00012870
           03  ARCHIVIO-PGM         PIC X(08).                          00012880
           03  ARCHIVIO-DATA        PIC X(08).                          00012890
           03  ARCHIVIO-ORA         PIC X(06).                          00012891
           03  ARCHIVIO-TIPOMOD     PIC X(01).                          00012892
           03  ARCHIVIO-RETCODE     PIC X(06).                          00012893
           03  ARCHIVIO-FILLER      PIC X(71).                          00012894
           03  ARCHIVIO-REC         PIC X(01000).                       00012895
      *--- COPY MAPPA                                                   00005495
       01                           PIC X(16) VALUE '**   MAPPA    **'. 00005496
           COPY DLRMH05.                                                00005497
      *--- COPY AID                                                     00005500
       01                           PIC X(16) VALUE '**   DFHAID   **'. 00005600
           COPY DFHAID.                                                 00005700
      *--- VARIABILI DI LAVORO                                          00005800
       01                           PIC X(16) VALUE '**   LAVORO   **'. 00005900
       01  WS-LAVORO.                                                   00006000
           05 WS-SEMA               PIC X(04).                          00009701
           05 WS-PROG-MAX           PIC 9(07).                          00009701
           05 WS-CAMPI-CX.                                              00006200
              10 WS-CX-ABSTIME      PIC S9(15) PACKED-DECIMAL.          00007300
              10 WS-CX-AAMMGG       PIC 9(06).                          00006600
              10 WS-CX-AAAAMMGG     PIC 9(08).                          00006700
              10 WS-CX-GGMMAA       PIC 9(06).                          00006500
              10 WS-CX-GGMMAAAA     PIC 9(08).                          00006800
              10 WS-CX-GGMMAAAA-T   PIC X(10).                          00006900
              10 WS-CX-HHMMSS       PIC 9(06).                          00007000
              10 WS-CX-HHMMSS-P     PIC X(05).                          00007100
              10 WS-CX-MSG-LEN      PIC S9(04) BINARY.                  00006300
              10 WS-CX-MSG-TEXT     PIC X(1920).                        00006200
              10 WS-CX-RESP         PIC S9(08) BINARY.                  00006100
              10 WS-CX-STATUS       PIC 9(08)  BINARY.                  00006400
              10 WS-CX-XCTL         PIC X(08).                          00007200
              10 WS-CX-LINK-PGM     PIC X(08).                          00007200
           05 WS-DESC-ERRO-GENE.                                        00009195
              10 WS-ERRO-MESSAGG    PIC X(56).                          00009196
              10 WS-CODI-ERRO-GENE.                                     00009197
                 15 WS-ERRO-COABEND PIC X(04).                          00009198
                 15 WS-ERRO-DESCRIZ PIC X(10).                          00009199
      *--- COSTANTI                                                     00009200
       01                           PIC X(16) VALUE '*** COSTANTI ***'. 00009300
       01  WK-COSTANTI.                                                 00009400
           05 WK-MAP                PIC X(07) VALUE 'DLRMH05'.          00009600
           05 WK-PGM                PIC X(08) VALUE 'DLRH0500'.         00009700
           05 WK-SEMA-DRLI          PIC X(04) VALUE 'DRLI'.             00009701
           05 WK-SEMA-DRLQ          PIC X(04) VALUE 'DRLQ'.             00009701
           05 WK-TRAN               PIC X(04) VALUE 'DRNI'.             00009701
           05 WK-DLRXDRNI           PIC X(08) VALUE 'DLRXDRNI'.
           05 WK-GTCC03X0           PIC X(08) VALUE 'GTCC03X0'.
           05 WK-SRVI0022           PIC X(08) VALUE 'SRVI0022'.         00009800
           05 WK-SRVI0090           PIC X(08) VALUE 'SRVI0090'.         00009810
           05 WK-SRVXD002           PIC X(08) VALUE 'SRVXD002'.         00009801
           05 WK-STVO0390           PIC X(08) VALUE 'STVO0390'.         00009810
           05 SW-ERRORE             PIC X(01).                          00009900
              88 NO-ERRORE                    VALUE ZEROES.             00010000
              88 SI-ERRORE                    VALUE '1'.                00010100
      *---  AREA ATTRIBUTI STANDARD                                     00010200
       01                           PIC X(16) VALUE '**  ATTRIBUTI **'. 00010300
       01  ATTRIBUTI-BMS.                                               00010400
           03  ATTR-ASK-NOR         PIC X        VALUE '0'.             00010500
           03  ATTR-ASK-NOR-FSE     PIC X        VALUE '1'.             00010600
           03  ATTR-ASK-BRT         PIC X        VALUE '8'.             00010700
           03  ATTR-ASK-BRT-FSE     PIC X        VALUE '9'.             00010800
           03  ATTR-ASK-DRK         PIC X        VALUE '@'.             00010900
           03  ATTR-ASK-DRK-FSE     PIC X        VALUE ''''.            00011000
           03  ATTR-PRO-NOR         PIC X        VALUE '-'.             00011100
           03  ATTR-PRO-NOR-FSE     PIC X        VALUE '/'.             00011200
           03  ATTR-PRO-BRT         PIC X        VALUE 'Y'.             00011300
           03  ATTR-PRO-BRT-FSE     PIC X        VALUE 'Z'.             00011400
           03  ATTR-PRO-DRK         PIC X        VALUE '%'.             00011500
           03  ATTR-PRO-DRK-FSE     PIC X        VALUE '_'.             00011600
           03  ATTR-UNP-NOR         PIC X        VALUE ' '.             00011700
           03  ATTR-UNP-NOR-FSE     PIC X        VALUE 'A'.             00011800
           03  ATTR-UNP-NOR-NUM     PIC X        VALUE '&'.             00011900
           03  ATTR-UNP-NOR-NUM-FSE PIC X        VALUE 'J'.             00012000
           03  ATTR-UNP-BRT         PIC X        VALUE 'H'.             00012100
           03  ATTR-UNP-BRT-FSE     PIC X        VALUE 'I'.             00012200
           03  ATTR-UNP-BRT-NUM     PIC X        VALUE 'Q'.             00012300
           03  ATTR-UNP-BRT-NUM-FSE PIC X        VALUE 'R'.             00012400
           03  ATTR-UNP-DRK         PIC X        VALUE '<'.             00012500
           03  ATTR-UNP-DRK-FSE     PIC X        VALUE '('.             00012600
           03  ATTR-UNP-DRK-NUM     PIC X        VALUE '*'.             00012700
           03  ATTR-UNP-DRK-NUM-FSE PIC X        VALUE ')'.             00012800
      *-----------------------------------------------------------------00012900
       LINKAGE SECTION.                                                 00013000
       01  DFHCOMMAREA              PIC X(10000).                       00013100
      ******************************************************************00013200
       PROCEDURE DIVISION.                                              00013300
           PERFORM C00010-INIT                                          00013400
           PERFORM C00020-CTRL-OPERATIVITA                              00038501
           EVALUATE TR-GIRO(TR-IND-PSEUDO)                              00014700
             WHEN ZERO                                                  00014800
               PERFORM C00100-CICLO-1                                   00014900
               MOVE 1                    TO TR-GIRO(TR-IND-PSEUDO)      00014700
             WHEN 1                                                     00015500
               PERFORM C00200-CICLO-2                                   00015600
             WHEN OTHER                                                 00015800
               PERFORM C00040-CICLO-ERR                                 00015802
           END-EVALUATE                                                 00016500
           PERFORM X00080-RETURN-TRANSID.                               00016700
      *-----------------------------------                              00016800
      *                                                                 00016900
      *----------------------------------                               00017000
       C00010-INIT.                                                     00017100
           MOVE 'C00010-INIT'            TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM X00000-HANDLE-ABEND                                  00017400
           MOVE DFHCOMMAREA              TO TRASF-DATI                  00014070
           INITIALIZE DATI-ERR                                          00017900
                      WS-LAVORO                                         00017900
           SET NO-ERRORE                 TO TRUE                        00017900
           PERFORM X00040-GEST-DT-HH.                                   00017910
      *-----------------------------------                              00102810
      *                                                                 00102820
      *-----------------------------------                              00102830
       C00020-CTRL-OPERATIVITA.                                         00102840
           MOVE 'C00020-CTRL-OPERATIVITA' TO SSVCXW-NOME-ROUTINE
                                          PERFORM SSVCXP00-TRACE
           MOVE WK-SEMA-DRLI              TO WS-SEMA                    00102850
           PERFORM X00030-INQUIRY                                       00102850
           IF WS-CX-STATUS NOT = 23                                     00102860
              SET SI-ERRORE              TO TRUE                        00102880
              INITIALIZE D022-COM-MESSAGE                               00102880
              MOVE 397                   TO D022-COM-IN-CODMESS         00102890
              MOVE WK-PGM                TO D022-COM-ERR-PRGMESS        00102892
              MOVE '02'                  TO D022-COM-ERR-POSME-1        00102893
                                            D022-COM-ERR-POSME-2        00102894
              PERFORM C90060-IMPO-MESS                                  00033207
              PERFORM C01000-BACK-1-LIV
           END-IF                                                       00085791
           MOVE WK-SEMA-DRLQ              TO WS-SEMA                    00102850
           PERFORM X00030-INQUIRY                                       00102850
           IF WS-CX-STATUS NOT = 23                                     00102860
              SET SI-ERRORE              TO TRUE                        00102880
              INITIALIZE D022-COM-MESSAGE                               00102880
              MOVE 410                   TO D022-COM-IN-CODMESS         00102890
              MOVE WK-PGM                TO D022-COM-ERR-PRGMESS        00102892
              MOVE '04'                  TO D022-COM-ERR-POSME-1        00102893
                                            D022-COM-ERR-POSME-2        00102894
              PERFORM C90060-IMPO-MESS                                  00033207
              PERFORM C01000-BACK-1-LIV
           END-IF.                                                      00085791
      *-----------------------------------                              00024300
      *                                                                 00024200
      *-----------------------------------                              00024300
       C00040-CICLO-ERR.                                                00015802
           MOVE 'C00040-CICLO-ERR'       TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           SET SI-ERRORE                 TO TRUE                        00102880
           INITIALIZE D022-COM-MESSAGE                                  00015802
           MOVE 22                       TO D022-COM-IN-CODMESS         00015803
           MOVE WK-PGM                   TO D022-COM-ERR-PRGMESS        00015805
           MOVE '06'                     TO D022-COM-ERR-POSME-1        00015806
                                            D022-COM-ERR-POSME-2        00015807
           PERFORM C90060-IMPO-MESS                                     00033207
           PERFORM C01000-BACK-1-LIV.
      *-----------------------------------                              00024100
      *                                                                 00024200
      *-----------------------------------                              00024300
       C00100-CICLO-1.                                                  00024400
           MOVE 'C00100-CICLO-1'         TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM C00920-READ-DLRXDRNI
           IF NO-ERRORE
              PERFORM C01020-PREP-MAP-VAR                               00016600
              PERFORM C00110-PREP-MAP-FISSA
           END-IF
           IF SI-ERRORE
              PERFORM C01000-BACK-1-LIV
           END-IF.
      *-----------------------------------                              00031800
      *                                                                 00031900
      *-----------------------------------                              00032000
       C00110-PREP-MAP-FISSA.                                           00025000
           MOVE 'C00110-PREP-MAP-FISSA'  TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM C00120-GEST-DECODIFICA
           IF NO-ERRORE
              PERFORM C00130-GEST-INTESTAZ                              00025000
              IF NO-ERRORE
                 PERFORM C00140-GEST-ALTRI-CAMPI                        00025000
                 PERFORM C01050-SET-OUT-CONF                            00025000
                 PERFORM C00150-GEST-ATTR-FISSA                         00025000
                 PERFORM X00060-SEND-ERASE                              00107300
              END-IF
           END-IF.
      *-----------------------------------                              00032000
      *                                                                 00031900
      *-----------------------------------                              00032000
       C00120-GEST-DECODIFICA.                                          00025000
           MOVE 'C00120-GEST-DECODIFICA' TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM C00900-READ-GTTBCC03
           IF NO-ERRORE
              MOVE CC03-DESCRIZ          TO H05DECAO
           END-IF.
      *-----------------------------------                              00032000
      *                                                                 00031900
      *-----------------------------------                              00032000
       C00130-GEST-INTESTAZ.                                            00025000
           MOVE 'C00130-GEST-INTESTAZ'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM C00910-CHIAMA-SRVI0090
           IF NO-ERRORE
              IF RVB5-ANAG-NAT-GIURI = 'PF '
                  MOVE RVB5-ANAG-COGNOME TO H05INT1O
                  MOVE RVB5-ANAG-NOME    TO H05INT2O
                  MOVE RVB5-ANAG-LUOGODATAN TO H05INT3O
              ELSE
                  MOVE RVB5-ANAG-RAGSOC1 TO H05INT1O
                  MOVE RVB5-ANAG-RAGSOC2 TO H05INT2O
                  MOVE RVB5-ANAG-RAGSOC3 TO H05INT3O
              END-IF
              IF RVB5-NDG-INTEST = LOW-VALUES OR SPACES OR ZEROES
                 MOVE ZEROES             TO H05CNDGO
              ELSE
                 MOVE RVB5-NDG-INTEST    TO H05CNDGO
              END-IF
           END-IF.
      *-----------------------------------                              00024100
      *                                                                 00024200
      *-----------------------------------                              00024300
       C00140-GEST-ALTRI-CAMPI.                                         00024400
           MOVE 'C00140-GEST-ALTRI-CAMPI' TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           MOVE D100-DIV                 TO H05DIVIO
           MOVE WK-TRAN                  TO H05TRANO(1:4)               00104810
           MOVE WK-MAP                   TO H05TRANO(5:7)               00104900
           MOVE D100-RAPPORTO-NUM        TO H05DEPOO
           MOVE D100-CATRAPP             TO H05CATEO
           MOVE D100-DATA-APETGG         TO H05DTACO(01:02)
           MOVE D100-DATA-APETMM         TO H05DTACO(04:02)
           MOVE D100-DATA-APETAA         TO H05DTACO(07:04)
           MOVE '/'                      TO H05DTACO(03:01)
                                            H05DTACO(06:01)
           MOVE D100-FILAPPA             TO H05FIAPO
           INITIALIZE H05CONFO                                          00024700
                      H05MES1O.                                         00024700
      *-----------------------------------                              00031800
      *                                                                 00031900
      *-----------------------------------                              00032000
       C00150-GEST-ATTR-FISSA.                                          00025000
           MOVE 'C00150-GEST-ATTR-FISSA' TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           MOVE ATTR-ASK-NOR-FSE         TO H05TRANA                    00025000
           MOVE ATTR-ASK-BRT-FSE         TO H05DEPOA
                                            H05CATEA
                                            H05DECAA
                                            H05DIVIA
                                            H05INT1A
                                            H05CNDGA
                                            H05INT2A
                                            H05DTACA
                                            H05INT3A
                                            H05FIAPA
                                            H05MES1A
           MOVE ATTR-UNP-NOR-FSE         TO H05CONFA                    00025000
           MOVE -1                       TO H05CONFL.                   00025000
      *-----------------------------------
      *
      *-----------------------------------
       C00200-CICLO-2.
           MOVE 'C00200-CICLO-2'         TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           IF EIBAID = DFHCLEAR                                         00013500
              PERFORM C01010-BACK-2-LIV                                 00013800
           ELSE                                                         00013500
              PERFORM X00020-RECEIVE                                    00015200
              PERFORM C00220-INIT-CICLO-2                               00015300
              EVALUATE EIBAID                                           00032410
                WHEN DFHPF3                                             00032500
                  PERFORM C01000-BACK-1-LIV                             00032700
                WHEN DFHPF4                                             00032600
                  PERFORM C01010-BACK-2-LIV                             00032700
                WHEN DFHENTER                                           00033000
                  PERFORM C00230-GEST-ENTER                             00033100
                WHEN OTHER                                              00033200
                  PERFORM C00210-GEST-ERR-EIBAID                        00033100
              END-EVALUATE                                              00033900
              PERFORM C01020-PREP-MAP-VAR                               00016600
              PERFORM C01050-SET-OUT-CONF
              PERFORM X00070-SEND-DATAONLY                              00107300
           END-IF.                                                      00033900
      *-----------------------------------                              00028800
      *                                                                 00028900
      *-----------------------------------                              00029000
       C00210-GEST-ERR-EIBAID.                                          00033100
           MOVE 'C00210-GEST-ERR-EIBAID' TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INITIALIZE D022-COM-MESSAGE                                  00033201
           MOVE 384                      TO D022-COM-IN-CODMESS         00033202
           MOVE WK-PGM                   TO D022-COM-ERR-PRGMESS        00033204
           MOVE '20'                     TO D022-COM-ERR-POSME-1        00033205
                                            D022-COM-ERR-POSME-2        00033206
           PERFORM C90060-IMPO-MESS.                                    00033207
      *-----------------------------------                              00028800
      *                                                                 00028900
      *-----------------------------------                              00029000
       C00220-INIT-CICLO-2.                                             00029100
           MOVE 'C00220-INIT-CICLO-2'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           SET NO-ERRORE                 TO TRUE                        00036600
           INSPECT H05CONFI REPLACING ALL '_' BY SPACES                 00029400
           INSPECT H05CONFI REPLACING ALL LOW-VALUE BY SPACES           00030600
           INITIALIZE H05MES1O                                          00041400
           MOVE ATTR-UNP-NOR-FSE         TO H05CONFA                    00033208
           MOVE -1                       TO H05CONFL                    00033208
           MOVE ATTR-ASK-BRT-FSE         TO H05MES1A.                   00027500
      *-----------------------------------
      *
      *-----------------------------------
       C00230-GEST-ENTER.
           MOVE 'C00230-GEST-ENTER'      TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM C00240-CTRL-CONF
           IF NO-ERRORE
              EVALUATE H05CONFI
                WHEN 'NO'
                  PERFORM C01000-BACK-1-LIV
                WHEN 'SI'
                  IF NO-ERRORE
                     PERFORM C00250-GEST-ARCHIVI
                     IF NO-ERRORE
                        PERFORM C00270-GEST-RITORNO
                  END-IF END-IF
              END-EVALUATE
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00240-CTRL-CONF.
           MOVE 'C00220-CTRL-CONF'       TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EVALUATE H05CONFI
             WHEN 'NO'
             WHEN 'SI'
               CONTINUE
             WHEN OTHER
               SET SI-ERRORE             TO TRUE
               INITIALIZE D022-COM-MESSAGE                              00033201
               MOVE 507                  TO D022-COM-IN-CODMESS         00033202
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS        00033204
               MOVE '24'                 TO D022-COM-ERR-POSME-1        00033205
                                            D022-COM-ERR-POSME-2        00033206
               PERFORM C90060-IMPO-MESS                                 00033207
               MOVE ATTR-UNP-BRT-FSE     TO H05CONFA
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C00250-GEST-ARCHIVI.
           MOVE 'C00250-GEST-ARCHIVI'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM C00920-READ-DLRXDRNI
           IF NO-ERRORE
              PERFORM C00930-MAX-DLRXDRNI
              IF NO-ERRORE
                 PERFORM C00260-PREP-WRT
                 PERFORM C00940-WRT-DLRXDRNI
              END-IF
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00260-PREP-WRT.
           MOVE 'C00260-PREP-WRT'        TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           COMPUTE WS-PROG-MAX = RNI-PROGRES + 1 END-COMPUTE
           INITIALIZE DLRDRNI-REC
           MOVE WS-CX-AAAAMMGG           TO RNI-DATA-RICH
           MOVE WS-PROG-MAX              TO RNI-PROGRES
           MOVE D100-FILIALE             TO RNI-FILIALE
           MOVE D100-RAPPORTO-NUM        TO RNI-RAPPORT
           MOVE D100-CATRAPP             TO RNI-CATRAPP
           MOVE '4'                      TO RNI-TIPO-RICH
           MOVE D100-DATA-DA             TO RNI-DATA-INIZ
           MOVE D100-DATA-A              TO RNI-DATA-FINE
           MOVE '3'                      TO RNI-TIPO-DEST1
           MOVE D100-DATIMM              TO RNI-DATAIMM
           MOVE D100-ORAIMM              TO RNI-ORAIMM
           MOVE D100-TERMIMM             TO RNI-TERMIMM
           MOVE D100-COPERIM             TO RNI-COPERIM
           MOVE D100-AUTORIM             TO RNI-AUTORIM
           MOVE D100-DIPEIMM             TO RNI-DIPEIMM.
      *-----------------------------------
      *
      *-----------------------------------
       C00270-GEST-RITORNO.
           MOVE 'C00270-GEST-RITORNO'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           SET SI-ERRORE                 TO TRUE
           INITIALIZE D022-COM-MESSAGE
           MOVE 404                      TO D022-COM-IN-CODMESS
           MOVE WK-PGM                   TO D022-COM-ERR-PRGMESS
           MOVE '26'                     TO D022-COM-ERR-POSME-1
                                            D022-COM-ERR-POSME-2
           PERFORM C90060-IMPO-MESS                                     00033207
           PERFORM C01000-BACK-1-LIV.
      *-----------------------------------
      *
      *-----------------------------------
       C00900-READ-GTTBCC03.
           MOVE 'C00900-READ-GTTBCC03'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INITIALIZE AREA-TBO2
                      CC03-REC
           MOVE '00001'                  TO CC03-ISTITUT
           MOVE D100-CATRAPP             TO CC03-CATRAPP
           MOVE CC03-KEY                 TO TBO2-KEYTABE
           MOVE 'RED'                    TO TBO2-TABFUNZ
           MOVE 'CC03'                   TO TBO2-CODTABE
           MOVE WK-GTCC03X0              TO WS-CX-LINK-PGM
           PERFORM X00150-LINK-GENSPEC
           EVALUATE TBO2-RETCODE
             WHEN 'SI'
               MOVE TBO2-DATITAB         TO CC03-DATI
             WHEN 'NF'
               SET SI-ERRORE             TO TRUE
               INITIALIZE D022-COM-MESSAGE
               MOVE 750                  TO D022-COM-IN-CODMESS
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS
               MOVE '54'                 TO D022-COM-ERR-POSME-1
                                            D022-COM-ERR-POSME-2
               PERFORM C90060-IMPO-MESS
             WHEN OTHER
               SET SI-ERRORE             TO TRUE
               INITIALIZE D022-COM-MESSAGE
               MOVE 745                  TO D022-COM-IN-CODMESS
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS
               MOVE '56'                 TO D022-COM-ERR-POSME-1
                                            D022-COM-ERR-POSME-2
               PERFORM C90060-IMPO-MESS
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C00910-CHIAMA-SRVI0090.
           MOVE 'C00910-CHIAMA-SRVI0090' TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INITIALIZE AREA-SRVCRVB5
           IF  D100-CONVERTITO = 'SI'
           OR  D100-CODINDG-POSI >= D100-CODINDG-MIN
               MOVE '1'                  TO RVB5-TIPORIC
           ELSE
               MOVE '2'                  TO RVB5-TIPORIC
           END-IF
           MOVE '00001'                  TO RVB5-ISTITUT
           MOVE 'DR'                     TO RVB5-TIPSERV
           MOVE D100-FILIALE             TO RVB5-FILIALE
           MOVE D100-RAPPORTO            TO RVB5-RAPPORT
           MOVE D100-CATRAPP             TO RVB5-CATRAPP
           PERFORM X00110-LINK-SRVI0090
           EVALUATE RVB5-RETCODE
             WHEN ZERO
               CONTINUE
             WHEN '1'
             WHEN '2'
               SET SI-ERRORE             TO TRUE                        00102880
               INITIALIZE D022-COM-MESSAGE                              00102880
               MOVE 244                  TO D022-COM-IN-CODMESS         00102890
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS        00102892
               MOVE '58'                 TO D022-COM-ERR-POSME-1        00102893
                                            D022-COM-ERR-POSME-2        00102894
               PERFORM C90060-IMPO-MESS                                 00033207
             WHEN OTHER
               SET SI-ERRORE             TO TRUE                        00102880
               INITIALIZE D022-COM-MESSAGE                              00102880
               MOVE 382                  TO D022-COM-IN-CODMESS         00102890
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS        00102892
               MOVE '62'                 TO D022-COM-ERR-POSME-1        00102893
                                            D022-COM-ERR-POSME-2        00102894
               PERFORM C90060-IMPO-MESS                                 00033207
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C00920-READ-DLRXDRNI.
           MOVE 'C00920-READ-DLRXDRNI'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INITIALIZE AREA-ARCHIVIO
                      DLRDRNI-REC
           MOVE WS-CX-AAAAMMGG           TO RNI-DATA-RICH
           MOVE D100-FILIALE             TO RNI-FILIALE
           MOVE D100-RAPPORTO-NUM        TO RNI-RAPPORT
           MOVE D100-CATRAPP             TO RNI-CATRAPP
           MOVE DLRDRNI-REC              TO ARCHIVIO-REC
           MOVE 'RE1'                    TO ARCHIVIO-FUNZ
           MOVE WK-DLRXDRNI              TO WS-CX-LINK-PGM              00122761
           PERFORM X00120-LINK-STANDARD
           EVALUATE ARCHIVIO-SW
             WHEN 'SI'
               SET SI-ERRORE             TO TRUE                        00102880
               INITIALIZE D022-COM-MESSAGE                              00102880
               MOVE 758                  TO D022-COM-IN-CODMESS         00102890
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS        00102892
               MOVE '64'                 TO D022-COM-ERR-POSME-1        00102893
                                            D022-COM-ERR-POSME-2        00102894
               PERFORM C90060-IMPO-MESS                                 00033207
             WHEN 'NF'
               MOVE ARCHIVIO-REC         TO DLRDRNI-REC
             WHEN OTHER
               SET SI-ERRORE             TO TRUE                        00102880
               INITIALIZE D022-COM-MESSAGE                              00102880
               MOVE 382                  TO D022-COM-IN-CODMESS         00102890
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS        00102892
               MOVE '66'                 TO D022-COM-ERR-POSME-1        00102893
                                            D022-COM-ERR-POSME-2        00102894
               PERFORM C90060-IMPO-MESS                                 00033207
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C00930-MAX-DLRXDRNI.
           MOVE 'C00930-MAX-DLRXDRNI'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INITIALIZE AREA-ARCHIVIO
                      DLRDRNI-REC
           MOVE WS-CX-AAAAMMGG           TO RNI-DATA-RICH
           MOVE DLRDRNI-REC              TO ARCHIVIO-REC
           MOVE 'MAX'                    TO ARCHIVIO-FUNZ
           MOVE WK-DLRXDRNI              TO WS-CX-LINK-PGM              00122761
           PERFORM X00120-LINK-STANDARD
           IF AREA-ARCHIVIO = HIGH-VALUES
               SET SI-ERRORE             TO TRUE                        00102880
               INITIALIZE D022-COM-MESSAGE                              00102880
               MOVE 382                  TO D022-COM-IN-CODMESS         00102890
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS        00102892
               MOVE '68'                 TO D022-COM-ERR-POSME-1        00102893
                                            D022-COM-ERR-POSME-2        00102894
               PERFORM C90060-IMPO-MESS                                 00033207
           ELSE
               MOVE ARCHIVIO-REC         TO DLRDRNI-REC
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00940-WRT-DLRXDRNI.
           MOVE 'C00940-WRT-DLRXDRNI'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INITIALIZE AREA-ARCHIVIO
           MOVE DLRDRNI-REC              TO ARCHIVIO-REC
           MOVE 'WRT'                    TO ARCHIVIO-FUNZ
           MOVE WK-DLRXDRNI              TO WS-CX-LINK-PGM              00122761
           PERFORM X00120-LINK-STANDARD
           EVALUATE ARCHIVIO-SW
             WHEN 'SI'
               CONTINUE
             WHEN OTHER
               SET SI-ERRORE             TO TRUE                        00102880
               INITIALIZE D022-COM-MESSAGE                              00102880
               MOVE 382                  TO D022-COM-IN-CODMESS         00102890
               MOVE WK-PGM               TO D022-COM-ERR-PRGMESS        00102892
               MOVE '72'                 TO D022-COM-ERR-POSME-1        00102893
                                            D022-COM-ERR-POSME-2        00102894
               PERFORM C90060-IMPO-MESS                                 00033207
           END-EVALUATE.
      *-----------------------------------                              00034000
      *                                                                 00034100
      *-----------------------------------                              00034200
       C01000-BACK-1-LIV.                                               00034300
           MOVE 'C01000-BACK-1-LIV'      TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           IF SI-ERRORE
              MOVE 'SI'                  TO D100-COD-MES
              MOVE H05MES1O              TO D100-DES-MES
           ELSE                                                         00013800
              MOVE 'NO'                  TO D100-COD-MES
              INITIALIZE D100-DES-MES
           END-IF                                                       00013800
           INITIALIZE TR-PROGRAM(TR-IND-PSEUDO)                         00035000
           SUBTRACT 1 FROM TR-IND-PSEUDO END-SUBTRACT                   00034800
           MOVE TR-PROGRAM(TR-IND-PSEUDO) TO WS-CX-XCTL                 00034900
           PERFORM X00090-XCTL-FUNZIONE.                                00035100
      *-----------------------------------
      *
      *-----------------------------------
       C01010-BACK-2-LIV.
           MOVE 'C01010-BACK-2-LIV'      TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INITIALIZE TR-PROGRAM(TR-IND-PSEUDO)                         00035000
           IF D100-DRMG EQUAL 'X'
              SUBTRACT 2 FROM TR-IND-PSEUDO END-SUBTRACT
           ELSE
              SUBTRACT 1 FROM TR-IND-PSEUDO END-SUBTRACT
           END-IF
           MOVE TR-PROGRAM(TR-IND-PSEUDO) TO WS-CX-XCTL
           PERFORM X00090-XCTL-FUNZIONE.
      *-----------------------------------                              00104200
      *                                                                 00104300
      *-----------------------------------                              00104400
       C01020-PREP-MAP-VAR.                                             00104600
           MOVE 'C01020-PREP-MAP-VAR'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           MOVE WS-CX-GGMMAAAA(1:2)      TO WS-CX-GGMMAAAA-T(1:2)       00105100
           MOVE WS-CX-GGMMAAAA(3:2)      TO WS-CX-GGMMAAAA-T(4:2)       00105200
           MOVE WS-CX-GGMMAAAA(5:4)      TO WS-CX-GGMMAAAA-T(7:4)       00105300
           MOVE '/'                      TO WS-CX-GGMMAAAA-T(3:1)       00105400
                                            WS-CX-GGMMAAAA-T(6:1)       00105500
           MOVE WS-CX-GGMMAAAA-T         TO H05DATAO                    00105600
           MOVE WS-CX-HHMMSS(1:2)        TO WS-CX-HHMMSS-P(1:2)         00105700
           MOVE WS-CX-HHMMSS(3:2)        TO WS-CX-HHMMSS-P(4:2)         00105800
           MOVE ':'                      TO WS-CX-HHMMSS-P(3:1)         00105900
           MOVE WS-CX-HHMMSS-P           TO H05ORAO                     00106000
           MOVE ATTR-ASK-NOR-FSE         TO H05DATAA                    00105600
                                            H05ORAA.                    00105600
      *-----------------------------------                              00104200
      *                                                                 00104300
      *-----------------------------------                              00104400
       C01050-SET-OUT-CONF.                                             00104600
           MOVE 'C01050-SET-OUT-CONF'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INSPECT H05CONFO REPLACING ALL SPACES BY '_'.                00106100
      *-----------------------------------                              00110911
      *                                                                 00110912
      *-----------------------------------                              00110913
       C90010-GEST-ABEND.                                               00110914
           MOVE 'C90010-GEST-ABEND'      TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM X00010-ABEND                                         00110915
           PERFORM C90030-ERRORE-GENER.                                 00110916
      *-----------------------------------                              00110918
      *                                                                 00110919
      *-----------------------------------                              00110920
       C90020-CHECK-ESITO-CICS.                                         00110921
           IF WS-CX-RESP NOT = ZEROES                                   00110922
              PERFORM C90030-ERRORE-GENER                               00110923
           END-IF.                                                      00110924
      *-----------------------------------                              00110925
      *                                                                 00110926
      *-----------------------------------                              00110927
       C90030-ERRORE-GENER.                                             00110928
           MOVE 'C90030-ERRORE-GENER'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           MOVE DFHEIBLK                 TO DATI-ERR-EIB                00110930
           MOVE WK-PGM                   TO DATI-ERR-PGM                00110931
           PERFORM X00100-LINK-STVO0390                                 00110932
           PERFORM C90040-SYSTEM-ERRO                                   00110935
           SET SI-ERRORE                 TO TRUE
           PERFORM C01000-BACK-1-LIV.
      *-----------------------------------                              00110954
      * IMPOSTAZIONE DELL'ERRORE DI SISTEMA                             00110955
      *-----------------------------------                              00110956
       C90040-SYSTEM-ERRO.                                              00110957
           MOVE 'C90040-SYSTEM-ERRO'     TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           PERFORM C90050-ACCESSO-SRVXD002                              00110958
           IF ARCHIVIO-REC > LOW-VALUES                                 00110959
              MOVE M02-CV07-MESSAGG-01   TO WS-ERRO-MESSAGG             00110960
              MOVE M02-CV07-COABEND      TO WS-ERRO-COABEND             00110961
              MOVE M02-CV07-DESCRIZ-01   TO WS-ERRO-DESCRIZ             00110962
              IF M02-CV07-MESSAGG-01 GREATER SPACES                     00110970
                 INITIALIZE D022-COM-MESSAGE                            00110971
                 MOVE 1                  TO D022-COM-IN-CODMESS         00110972
                 MOVE WS-DESC-ERRO-GENE  TO D022-COM-IN-SPEMESS         00110973
                 MOVE M02-CV07-PROG      TO D022-COM-ERR-PRGMESS        00110974
                 MOVE '80'               TO D022-COM-ERR-POSME-1        00110975
                                            D022-COM-ERR-POSME-2        00110976
              ELSE                                                      00110977
                 INITIALIZE D022-COM-MESSAGE                            00110978
                 MOVE 22                 TO D022-COM-IN-CODMESS         00110979
                 MOVE WS-CODI-ERRO-GENE  TO D022-COM-IN-SPEMESS         00110980
                 MOVE WK-SRVXD002        TO D022-COM-ERR-PRGMESS        00110981
                 MOVE '82'               TO D022-COM-ERR-POSME-1        00110982
                                            D022-COM-ERR-POSME-2        00110983
              END-IF                                                    00110984
              IF ARCHIVIO-SW = 'DP'                                     00110985
                 INITIALIZE D022-COM-MESSAGE                            00110986
                 MOVE 121                TO D022-COM-IN-CODMESS         00110987
                 MOVE WK-SRVXD002        TO D022-COM-ERR-PRGMESS        00110989
                 MOVE '84'               TO D022-COM-ERR-POSME-1        00110990
                                            D022-COM-ERR-POSME-2        00110991
              END-IF                                                    00110992
           END-IF                                                       00110993
           PERFORM C90060-IMPO-MESS.                                    00110994
      *-----------------------------------                              00110995
      *                                                                 00110996
      *-----------------------------------                              00110997
       C90050-ACCESSO-SRVXD002.                                         00110998
           MOVE 'C90050-ACCESSO-SRVXD002' TO SSVCXW-NOME-ROUTINE
                                          PERFORM SSVCXP00-TRACE
           INITIALIZE AREA-ARCHIVIO                                     00110999
                      SRVD002-REC                                       00111000
           MOVE WS-CX-AAAAMMGG           TO M02-CV07-DATAIMM            00111001
           MOVE EIBTASKN                 TO M02-CV07-NUMTASK            00111002
           MOVE 'RED'                    TO ARCHIVIO-FUNZ               00111003
           MOVE SRVD002-REC              TO ARCHIVIO-REC                00111005
           PERFORM X00130-LINK-SRVXD002                                 00111006
           IF AREA-ARCHIVIO = HIGH-VALUES                               00111016
              MOVE LOW-VALUES            TO AREA-ARCHIVIO               00111017
              INITIALIZE D022-COM-MESSAGE                               00111018
              MOVE 121                   TO D022-COM-IN-CODMESS         00111019
              MOVE WK-SRVXD002           TO D022-COM-ERR-PRGMESS        00111021
              MOVE '86'                  TO D022-COM-ERR-POSME-1        00111022
                                            D022-COM-ERR-POSME-2        00111023
           ELSE                                                         00111032
              MOVE ARCHIVIO-REC          TO SRVD002-REC                 00111033
           END-IF.                                                      00111034
      *-----------------------------------                              00111036
      *                                                                 00111037
      *-----------------------------------                              00111038
       C90060-IMPO-MESS.                                                00111039
           MOVE 'C90060-IMPO-MESS'       TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           INITIALIZE D022-AREA                                         00111040
           MOVE D022-COM-DATI-IN         TO D022-DATI-IN                00111041
           PERFORM X00140-LINK-SRVI0022                                 00111042
           IF D022-AREA EQUAL HIGH-VALUES                               00111043
              INITIALIZE D022-COM-MESSAGE                               00111044
              STRING '88'                                               00111045
                     WK-PGM                                             00111046
                     '88'                                               00111045
                     ' ANOMALIA TECNICA ROUTINE SRVI0022'               00111047
                DELIMITED BY SIZE      INTO H05MES1O                    00111048
              END-STRING                                                00111049
           ELSE                                                         00111052
              MOVE D022-COM-ERR-POSME-1  TO D022-ERR-POSME-1            00111053
              MOVE D022-COM-ERR-PRGMESS  TO D022-ERR-PRGMESS            00111054
              MOVE D022-COM-ERR-POSME-2  TO D022-ERR-POSME-2            00111056
              MOVE D022-OUT-MESSAGE      TO D022-ERR-DESMESS            00111057
              MOVE D022-ERR-MESSAGE      TO H05MES1O                    00111058
           END-IF.                                                      00111059
      *-----------------------------------                              00111060
      *                                                                 00111061
      *-----------------------------------                              00111062
       C90100-FINE-LAVORO.                                              00111063
           MOVE 'C90100-FINE-LAVORO'     TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           IF NO-ERRORE                                                 00111064
              MOVE '*** FINE LAVORO ***' TO WS-CX-MSG-TEXT              00111065
              MOVE 20                    TO WS-CX-MSG-LEN
           END-IF                                                       00111064
           PERFORM X00050-SEND-TEXT.                                    00111066
      *-----------------------------------                              00111067
      *                                                                 00111070
      *-----------------------------------                              00111100
       X00000-HANDLE-ABEND.                                             00111110
           MOVE 'X00000-HANDLE-ABEND'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS HANDLE ABEND                                       00111120
                     LABEL(C90010-GEST-ABEND)                           00111130
                     RESP(WS-CX-RESP)                                   00111140
           END-EXEC                                                     00111150
           PERFORM C90020-CHECK-ESITO-CICS.                             00017800
      *-----------------------------------                              00111160
      *                                                                 00111170
      *-----------------------------------                              00111180
       X00010-ABEND.                                                    00111200
           MOVE 'X00010-ABEND 01'        TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS ASSIGN                                             00111500
                     ABCODE(DATI-ERR-ABEND)                             00111600
                     RESP(WS-CX-RESP)                                   00112580
           END-EXEC                                                     00111800
           PERFORM C90020-CHECK-ESITO-CICS                              00112591
           MOVE 'X00010-ABEND 02'        TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS HANDLE ABEND                                       00112200
                     CANCEL                                             00112300
                     RESP(WS-CX-RESP)                                   00112580
           END-EXEC                                                     00112500
           PERFORM C90020-CHECK-ESITO-CICS.                             00112591
      *-----------------------------------                              00112510
      *                                                                 00112520
      *-----------------------------------                              00112530
       X00020-RECEIVE.                                                  00112540
           MOVE 'X00020-RECEIVE'         TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS RECEIVE                                            00112550
                     MAP(WK-MAP)                                        00112560
                     INTO(DLRMH05I)                                     00112570
                     RESP(WS-CX-RESP)                                   00112580
           END-EXEC                                                     00112590
           PERFORM C90020-CHECK-ESITO-CICS.                             00112591
      *-----------------------------------                              00112600
      *                                                                 00112610
      *-----------------------------------                              00112620
       X00030-INQUIRY.                                                  00112630
           MOVE 'X00030-INQUIRY'         TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS INQUIRE                                            00112640
                     TRANS(WS-SEMA)                                     00112650
                     STATUS(WS-CX-STATUS)                               00112660
                     RESP(WS-CX-RESP)                                   00112670
           END-EXEC                                                     00112680
           PERFORM C90020-CHECK-ESITO-CICS.                             00112690
      *-----------------------------------                              00115400
      *                                                                 00115500
      *-----------------------------------                              00115600
       X00040-GEST-DT-HH.                                               00115700
           MOVE 'X00040-GEST-DT-HH 01' TO SSVCXW-NOME-ROUTINE
                                          PERFORM SSVCXP00-TRACE
           EXEC CICS ASKTIME                                            00116000
                     ABSTIME(WS-CX-ABSTIME)                             00116100
                     RESP(WS-CX-RESP)                                   00116200
           END-EXEC                                                     00116300
           PERFORM C90020-CHECK-ESITO-CICS                              00116400
           MOVE 'X00040-GEST-DT-HH 02' TO SSVCXW-NOME-ROUTINE
                                          PERFORM SSVCXP00-TRACE
           EXEC CICS FORMATTIME                                         00116700
                     ABSTIME(WS-CX-ABSTIME)                             00116800
                     DDMMYY(WS-CX-GGMMAA)                               00116900
                     YYMMDD(WS-CX-AAMMGG)                               00117000
                     DDMMYYYY(WS-CX-GGMMAAAA)                           00117100
                     YYYYMMDD(WS-CX-AAAAMMGG)                           00117200
                     TIME(WS-CX-HHMMSS)                                 00117300
                     RESP(WS-CX-RESP)                                   00117400
           END-EXEC                                                     00117500
           PERFORM C90020-CHECK-ESITO-CICS.                             00117600
      *-----------------------------------                              00117610
      *                                                                 00117620
      *-----------------------------------                              00117630
       X00050-SEND-TEXT.                                                00117640
           MOVE 'X00050-SEND-TEXT'       TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS SEND                                               00117650
                     TEXT                                               00117660
                     FROM(WS-CX-MSG-TEXT)                               00117670
                     LENGTH(WS-CX-MSG-LEN)                              00117680
                     ERASE                                              00117690
                     NOHANDLE                                           00117691
           END-EXEC                                                     00117692
           EXEC CICS RETURN END-EXEC.                                   00117693
      *-----------------------------------                              00117700
      *                                                                 00117800
      *-----------------------------------                              00117900
       X00060-SEND-ERASE.                                               00118000
           MOVE 'X00060-SEND-ERASE'      TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS SEND                                               00118300
                     MAP(WK-MAP)                                        00118400
                     FROM(DLRMH05O)                                     00118500
                     ERASE                                              00118600
                     CURSOR                                             00118700
                     FREEKB                                             00118800
                     RESP(WS-CX-RESP)                                   00117400
           END-EXEC                                                     00119000
           PERFORM C90020-CHECK-ESITO-CICS.                             00117600
      *-----------------------------------                              00117700
      *                                                                 00117800
      *-----------------------------------                              00117900
       X00070-SEND-DATAONLY.                                            00118000
           MOVE 'X00070-SEND-DATAONLY'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS SEND                                               00118300
                     MAP(WK-MAP)                                        00118400
                     FROM(DLRMH05O)                                     00118500
                     DATAONLY                                           00118600
                     CURSOR                                             00118700
                     FREEKB                                             00118800
                     RESP(WS-CX-RESP)                                   00117400
           END-EXEC                                                     00119000
           PERFORM C90020-CHECK-ESITO-CICS.                             00117600
      *-----------------------------------                              00119200
      *                                                                 00119300
      *-----------------------------------                              00119400
       X00080-RETURN-TRANSID.                                           00119500
           EXEC CICS RETURN                                             00119800
                     TRANSID(EIBTRNID)                                  00119900
                     COMMAREA(TRASF-DATI)                               00120000
                     LENGTH(LENGTH OF TRASF-DATI)                       00120100
                     NOHANDLE                                           00120200
           END-EXEC.                                                    00120300
      *-----------------------------------                              00120400
      *                                                                 00120500
      *-----------------------------------                              00120600
       X00090-XCTL-FUNZIONE.                                            00120700
           EXEC CICS XCTL                                               00120800
                     PROGRAM(WS-CX-XCTL)                                00120900
                     COMMAREA(TRASF-DATI)                               00121000
                     LENGTH(LENGTH OF TRASF-DATI)                       00121100
                     NOHANDLE                                           00120200
           END-EXEC.                                                    00121300
      *-----------------------------------                              00121500
      *                                                                 00121600
      *-----------------------------------                              00121700
       X00100-LINK-STVO0390.                                            00121710
           MOVE 'X00100-LINK-STVO0390'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS LINK                                               00121720
                     PROGRAM(WK-STVO0390)                               00121721
                     COMMAREA(DATI-ERR)                                 00121730
                     LENGTH(LENGTH OF DATI-ERR)                         00121740
                     RESP(WS-CX-RESP)                                   00117400
           END-EXEC                                                     00121750
           PERFORM C90020-CHECK-ESITO-CICS.                             00117600
      *-----------------------------------                              00121500
      *                                                                 00121600
      *-----------------------------------                              00121700
       X00110-LINK-SRVI0090.                                            00121710
           MOVE 'X00110-LINK-SRVI0090'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS LINK                                               00121720
                     PROGRAM(WK-SRVI0090)                               00121721
                     COMMAREA(AREA-SRVCRVB5)
                     LENGTH(RVB5-LEN)
                     RESP(WS-CX-RESP)                                   00117400
           END-EXEC                                                     00121750
           PERFORM C90020-CHECK-ESITO-CICS.                             00117600
      *-----------------------------------                              00122743
       X00120-LINK-STANDARD.                                            00122750
           MOVE 'X00120-LINK-STANDARD'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS LINK                                               00122760
                     PROGRAM(WS-CX-LINK-PGM)                            00122761
                     COMMAREA(AREA-ARCHIVIO)                            00122770
                     LENGTH(LENGTH OF AREA-ARCHIVIO)                    00122780
                     RESP(WS-CX-RESP)                                   00117400
           END-EXEC                                                     00122730
           PERFORM C90020-CHECK-ESITO-CICS.                             00117600
      *-----------------------------------                              00122510
      *                                                                 00122520
      *-----------------------------------                              00122530
       X00130-LINK-SRVXD002.                                            00122600
           MOVE 'X00130-LINK-SRVXD002'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS LINK                                               00122700
                     PROGRAM(WK-SRVXD002)                               00122701
                     COMMAREA(AREA-ARCHIVIO)                            00122710
                     LENGTH(LENGTH OF AREA-ARCHIVIO)                    00122720
                     RESP(WS-CX-RESP)                                   00117400
           END-EXEC                                                     00122730
           PERFORM C90020-CHECK-ESITO-CICS.                             00117600
      *-----------------------------------                              00122741
      *                                                                 00122742
      *-----------------------------------                              00122743
       X00140-LINK-SRVI0022.                                            00122750
           MOVE 'X00140-LINK-SRVI0022'   TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS LINK                                               00122760
                     PROGRAM(WK-SRVI0022)                               00122761
                     COMMAREA(D022-AREA)                                00122770
                     LENGTH(LENGTH OF D022-AREA)                        00122780
                     RESP(WS-CX-RESP)                                   00117400
           END-EXEC                                                     00122730
           PERFORM C90020-CHECK-ESITO-CICS.                             00117600
      *-----------------------------------
      *
      *-----------------------------------
       X00150-LINK-GENSPEC.
           MOVE 'X00150-LINK-GENSPEC'    TO SSVCXW-NOME-ROUTINE
                                         PERFORM SSVCXP00-TRACE
           EXEC CICS LINK
                     PROGRAM(WS-CX-LINK-PGM)
                     COMMAREA(AREA-TBO2)
                     LENGTH(LENGTH OF AREA-TBO2)
                     RESP(WS-CX-RESP)
           END-EXEC
           PERFORM C90020-CHECK-ESITO-CICS.
      *-----------------------------------
      *
      *-----------------------------------
           COPY SSVCXP00.
      **********************       END      ****************************00122900
