       ID DIVISION.                                                     00000100
      *---------------------------------------------------------------* 00000200
      *----------------------   ENGINEERING  -------------------------* 00000300
      *---------------------------------------------------------------* 00000400
      * IL SEGUENTE PROGRAMMA VIENE ATTIVATO CHIAMATO DA WEB SUPPORT  * 00000500
      *---------------------------------------------------------------* 00000600
      *------------------------   RCTP011   --------------------------* 00000700
      *---------------------------------------------------------------* 00000800
      *----                    FILTRO PARTITE                     ----* 00000900
      *---------------------------------------------------------------* 00001000
      *--!!  CAPS IMPOSTATO AD OFF PER ESIDENZE DI SINTASSI HTML  !!--* 00001100
      *--!!!!!!!!!!!!!!!!!!!!! NON MODIFICARE !!!!!!!!!!!!!!!!!!!!!!!!* 00001200
      *---------------------------------------------------------------* 00001300
       PROGRAM-ID. RCTP011.                                             00001400
       ENVIRONMENT DIVISION.                                            00001500
       CONFIGURATION SECTION.                                           00001510
       SPECIAL-NAMES.                                                   00001520
           DECIMAL-POINT IS COMMA.                                      00001530
       DATA DIVISION.                                                   00001600
       WORKING-STORAGE SECTION.                                         00001700
      *---------------------------------------------------------------* 00001800
      *--- TEMPLATE DELLA MAPPA RCMP001 (MENU)                    ----* 00001900
      *---------------------------------------------------------------* 00002000
       01  TEMPLATE              PIC   X(48)          VALUE             00002100
           'RCMP011                                         '.          00002200
       01  TOKEN                 PIC   X(16)          VALUE SPACES.     00002300
       01  CHARSET               PIC   X(40)          VALUE             00002400
           'ISO-8859-1                              '.                  00002500
       01  HOSTCODEPAGE          PIC    X(08)         VALUE '037'.      00002600
      *---------------------------------------------------------------* 00002700
      * COPY CONTROLLO SICUREZZA                                        00002800
      *---------------------------------------------------------------* 00002900
           COPY RCCYS000.                                               00003000
      *---------------------------------------------------------------* 00003100
      * COPY VALORIZZAZIONE HEADER DI MAPPA                             00003200
      *---------------------------------------------------------------* 00003300
           COPY RCCYHEAD.                                               00003400
      *---------------------------------------------------------------* 00003500
      * COPY VALORIZZAZIONE FOOTER DI MAPPA                             00003600
      *---------------------------------------------------------------* 00003700
           COPY RCCYFOOT.                                               00003800
      *---------------------------------------------------------------* 00003900
      * AREA PER INVIO DATI IN MAPPA RCMP001 (MENU)                     00004000
      *---------------------------------------------------------------* 00004100
       01 HTML-SEND.                                                    00004200
           COPY RCCYM011.                                               00004300
      *---------------------------------------------------------------* 00004400
      * AREA DI I/O PER CHIAMATA ROUTINE ACCESSO TGTBTG01               00004500
      *---------------------------------------------------------------* 00004600
        01  RCTP011-COTRTG01     PIC X(08)            VALUE 'COTRTG01'. 00004700
            COPY COCRTG01.                                              00004800
      *---------------------------------------------------------------* 00004900
      * AREA DI I/O PER CHIAMATA ROUTINE ACCESSO RCTPANVD               00005000
      *---------------------------------------------------------------* 00005100
        01  RCTP011-RCTPANVD     PIC X(07)            VALUE 'RCBTR02'.  00005200
            COPY RCCYR02.                                               00005310
      *---------------------------------------------------------------- 00005400
      *---- INCLUDE DELLE STRUTTURE SQL                                 00005500
      *---------------------------------------------------------------- 00005600
           EXEC SQL INCLUDE SQLCA                                       00005700
           END-EXEC.                                                    00005800
           EXEC SQL INCLUDE TGTBTG01                                    00005900
           END-EXEC.                                                    00006000
      *---------------------------------------------------------------* 00006100
       01  RCTP011-COUNT                PIC S9(8) COMP  VALUE ZEROES.   00006200
       01  RCTP011-METHOD                     PIC X(04) VALUE SPACES.   00006300
       01  RCTP011-FL-ERR                     PIC X(01) VALUE    '0'.   00006400
                                                                        00006500
      *--- COMODI PER DATE -------------------------------------------* 00006600
       01  RCTP011-ABSTIME                    PIC S9(15)                00006700
                                                 COMP-3 VALUE ZEROES.   00006800
       01  RCTP011-DT-SYS.                                              00006900
           02 DT-SYS-AAAA                     PIC X(04) VALUE SPACES.   00007000
           02 DT-SYS-MM                       PIC X(02) VALUE SPACES.   00007100
           02 DT-SYS-GG                       PIC X(02) VALUE SPACES.   00007200
                                                                        00007300
       01  RCTP011-DT-FMT.                                              00007400
           02 DT-FMT-AAAA                     PIC X(04) VALUE SPACES.   00007500
           02 FILLER                          PIC X(01) VALUE '-'.      00007600
           02 DT-FMT-MM                       PIC X(02) VALUE SPACES.   00007700
           02 FILLER                          PIC X(01) VALUE '-'.      00007800
           02 DT-FMT-GG                       PIC X(02) VALUE SPACES.   00007900
      *---------------------------------------------------------------* 00008000
      * COPY CONTROLLO DATE (CODA)                                      00008100
      *---------------------------------------------------------------* 00008200
           COPY RCCYCODA.                                               00008300
                                                                        00008400
      *---------------------------------------------------------------* 00008500
      *---------------------------------------------------------------* 00008600
      * COMMAREA PER PASSAGGIO DATI AL RCTP012                          00008700
      *---------------------------------------------------------------* 00008800
       01  RCTP011-COMMAREA.                                            00008900
           02 RCTP011-COMMAREA-TOKEN          PIC X(15).                00009000
           02 RCTP011-COMMAREA-FIL            PIC X(05).                00009100
           02 RCTP011-COMMAREA-UFF            PIC X(05).                00009110
           02 RCTP011-COMMAREA-VDACO          PIC X(05).                00009200
           02 RCTP011-COMMAREA-DATA           PIC X(08).                00009300
           02 RCTP011-COMMAREA-DACO           PIC X(01).                00009400
           02 RCTP011-COMMAREA-TIPO           PIC X(01).                00009410
           02 RCTP011-COMMAREA-VIS            PIC X(01).                00009500
           02 RCTP011-COMMAREA-PART           PIC X(04).                00009510
           02 RCTP011-COMMAREA-APER           PIC X(01).                00009520
      *---------------------------------------------------------------* 00009600
       LINKAGE SECTION.                                                 00009700
       01  DFHCOMMAREA                        PIC X(004).               00009800
      ***************************************************************** 00009900
       PROCEDURE DIVISION.                                              00010000
                                                                        00010100
           MOVE 'RCTP011'                      TO RCCYS000-PGM.         00010200
                                                                        00010300
           MOVE DFHCOMMAREA                    TO RCTP011-METHOD.       00010400
                                                                        00010500
           PERFORM OTTIENI-DT-SYS                                       00010510
              THRU OTTIENI-DT-SYS-EX.                                   00010520
                                                                        00010530
           IF RCTP011-METHOD = 'POST'                                   00010600
              PERFORM RICEVI-MAPPA                                      00010700
                 THRU RICEVI-MAPPA-EX                                   00010800
              PERFORM CONTROLLI-FORMALI                                 00010900
                 THRU CONTROLLI-FORMALI-EX                              00011000
                                                                        00011010
              MOVE    RCCYM011-TOKEN-V         TO RCCYS000-TOKEN        00011100
                                                                        00011110
              IF RCTP011-FL-ERR = '0'                                   00011200
                 MOVE RCCYS000-TOKEN           TO RCTP011-COMMAREA-TOKEN00011300
                 MOVE RCCYM011-FIL-V           TO RCTP011-COMMAREA-FIL  00011400
                 MOVE SPACE                    TO RCTP011-COMMAREA-UFF  00011410
                 MOVE RCCYM011-VDACO-V         TO RCTP011-COMMAREA-VDACO00011500
      *          MOVE RCCYM011-DATA-V          TO RCTP011-COMMAREA-DATA 00011600
                 MOVE RCCYM011-DACO-V          TO RCTP011-COMMAREA-DACO 00011700
                 MOVE SPACES                   TO RCTP011-COMMAREA-TIPO 00011710
                 MOVE RCCYM011-VIS-V           TO RCTP011-COMMAREA-VIS  00011800
                 MOVE SPACES                   TO RCTP011-COMMAREA-APER 00011810
                 EXEC CICS XCTL                                         00011900
                      PROGRAM ('RCTP012')                               00012000
                      COMMAREA(RCTP011-COMMAREA)                        00012100
                 END-EXEC                                               00012200
      *          MOVE 'SONO PASSATO'           TO RCCYFOOT-ERR-MSG      00012300
              END-IF                                                    00012400
           END-IF.                                                      00012500
                                                                        00012600
           PERFORM CONTROLLO-ACCESSO                                    00012700
              THRU CONTROLLO-ACCESSO-EX.                                00012800
                                                                        00012900
           PERFORM VALORIZZA-HEADER                                     00013000
              THRU VALORIZZA-HEADER-EX.                                 00013100
                                                                        00013200
           PERFORM VALORIZZA-FOOTER                                     00013300
              THRU VALORIZZA-FOOTER-EX.                                 00013400
                                                                        00013500
           PERFORM VALORIZZA-BODY                                       00013600
              THRU VALORIZZA-BODY-EX.                                   00013700
                                                                        00013800
           PERFORM CREA-DOCUMENTO                                       00013900
              THRU CREA-DOCUMENTO-EX.                                   00014000
                                                                        00014100
           PERFORM SPEDISCI-MAPPA-HTML                                  00014200
              THRU SPEDISCI-MAPPA-HTML-EX.                              00014300
                                                                        00014400
           PERFORM FINE.                                                00014500
                                                                        00014600
       RICEVI-MAPPA.                                                    00014700
           PERFORM VARYING RCCYM011-IND FROM 1 BY 1 UNTIL               00014800
                           RCCYM011-IND > RCCYM011-IND-MAX              00014900
              EXEC CICS WEB READ                                        00015000
                        FORMFIELD  (RCCYM011-NOME(RCCYM011-IND))        00015100
                        NAMELENGTH (RCCYM011-LNOME(RCCYM011-IND))       00015200
                        VALUE      (RCCYM011-VALORE(RCCYM011-IND))      00015300
                        VALUELENGTH(RCCYM011-LVALORE(RCCYM011-IND))     00015400
                        RESP       (RCCYM011-RESP)                      00015500
                        NOHANDLE                                        00015600
              END-EXEC                                                  00015700
              IF RCCYM011-RESP NOT = DFHRESP(NORMAL)                    00015800
                 MOVE    2                    TO RCCYS000-ERR-ACT       00015900
                 MOVE    RCCYS000-PGM         TO RCCYM000-ERR-PGM       00016000
                 MOVE    SQLCODE              TO RCCYM000-ERR-CODE      00016100
                 MOVE    'ERRORE RICEZIONE FORM HTML'                   00016200
                                               TO RCCYM000-ERR-MSG      00016300
                 PERFORM SEND-ERRORE                                    00016400
                    THRU SEND-ERRORE-EX                                 00016500
              END-IF                                                    00016600
              INSPECT RCCYM011-VALORE(RCCYM011-IND)  REPLACING          00016700
                  ALL LOW-VALUE BY SPACES                               00016800
              INSPECT RCCYM011-VALORE(RCCYM011-IND)  CONVERTING         00016900
                      "abcdefghijklmnopqrstuvwxyz"                      00017000
                   TO "ABCDEFGHIJKLMNOPQRSTUVWXYZ"                      00017100
           END-PERFORM.                                                 00017200
       RICEVI-MAPPA-EX.                                                 00017300
           EXIT.                                                        00017400
                                                                        00017500
      *---- CONTROLLI DI ESISTENZA DEI CAMPI                            00017600
      *---- E VERIFICA DELLA CORRETTEZZA IN BASE ALL'UTENTE             00017700
       CONTROLLI-FORMALI.                                               00017800
      *---- LETTURA CODA USER PER RECUPERO LIVELLO UTENZA               00018100
           INITIALIZE                       RCCYS000-NOME-TS-TOK.       00018200
           MOVE RCCYM011-TOKEN-V         TO RCCYS000-NOME-TS-TOK-TOKEN. 00018300
           MOVE 1                        TO RCCYS000-ITEM.              00018400
           PERFORM LEGGI-CODA-TOKEN                                     00018500
              THRU LEGGI-CODA-TOKEN-EX.                                 00018600
           INITIALIZE                       RCCYS000-NOME-TS-UID.       00018700
           MOVE RCCYS000-TS-TOK-USERID   TO RCCYS000-NOME-TS-UID-USERID.00018800
           MOVE '000'                    TO RCCYS000-NOME-TS-UID-PGM.   00018900
           MOVE '1'                      TO RCCYS000-NOME-TS-UID-PROGR. 00019000
           MOVE 1                        TO RCCYS000-ITEM.              00019100
           PERFORM LEGGI-CODA-USER                                      00019200
              THRU LEGGI-CODA-USER-EX.                                  00019300
                                                                        00019400
           IF (RCCYM011-FIL-V       = SPACES AND                        00019500
               RCCYM011-VDACO-V     = SPACES AND                        00019600
               RCCYM011-DATA-V      = SPACES) OR                        00019700
              (RCCYM011-FIL-V   NOT = SPACES AND                        00019800
               RCCYM011-VDACO-V     = SPACES AND                        00019900
               RCCYM011-DATA-V      = SPACES) OR                        00020000
              (RCCYM011-FIL-V       = SPACES AND                        00020100
               RCCYM011-VDACO-V NOT = SPACES AND                        00020200
               RCCYM011-DATA-V      = SPACES) OR                        00020300
              (RCCYM011-FIL-V       = SPACES AND                        00020400
               RCCYM011-VDACO-V     = SPACES AND                        00020500
               RCCYM011-DATA-V  NOT = SPACES)                           00020600
              MOVE '1'             TO RCTP011-FL-ERR                    00020700
              MOVE 'E'' NECESSARIO COMPILARE ALMENO DUE CAMPI!'         00020800
                                   TO RCCYFOOT-ERR-MSG                  00020900
           END-IF.                                                      00021000
           IF RCTP011-FL-ERR = '0'                                      00021100
              IF RCCYM011-FIL-V NOT = SPACES                            00021200
                 PERFORM CONTROLLO-FILIALE                              00021300
                    THRU CONTROLLO-FILIALE-EX                           00021400
                 IF RCTP011-FL-ERR = '0'                                00021500
                    IF RCCYS000-TS-UID-IDENT       = 'F' AND            00021600
                       RCCYS000-TS-UID-FILIALE NOT = RCCYM011-FIL-V     00021700
                       MOVE '2'       TO RCTP011-FL-ERR                 00021800
                       MOVE 'UTENTE NON ABILITATO ALLA FILIALE INDICATA'00021900
                                      TO RCCYFOOT-ERR-MSG               00022000
                    END-IF                                              00022100
                 END-IF                                                 00022200
              END-IF                                                    00022300
              IF RCTP011-FL-ERR = '0'                                   00022400
                 IF RCCYM011-VDACO-V NOT = SPACE                        00022500
                    PERFORM CONTROLLO-VDACO                             00022600
                       THRU CONTROLLO-VDACO-EX                          00022700
                 ELSE                                                   00022800
                    IF RCCYM011-DATA-V = SPACE                          00022900
                       MOVE '6'       TO RCTP011-FL-ERR                 00023000
                       MOVE 'VOCE DACO E DATA NON VALORIZZATI'          00023100
                                      TO RCCYFOOT-ERR-MSG               00023200
                    END-IF                                              00023300
                 END-IF                                                 00023400
              END-IF                                                    00023500
              IF RCTP011-FL-ERR = '0'                                   00023600
                 PERFORM CONTROLLO-DATA                                 00023700
                    THRU CONTROLLO-DATA-EX                              00023800
              END-IF                                                    00023900
           END-IF.                                                      00024000
       CONTROLLI-FORMALI-EX.                                            00024100
           EXIT.                                                        00024200
                                                                        00024300
       CONTROLLO-FILIALE.                                               00024400
           MOVE '00000'                      TO TG01-CDBAN0.            00024500
           MOVE RCCYM011-FIL-V               TO TG01-CDDIP0.            00024600
           MOVE '00'                         TO TG01-CDDPU0.            00024700
           MOVE 'SIC'                        TO TG01-MODORG.            00024800
                                                                        00024900
           EXEC CICS LINK PROGRAM (RCTP011-COTRTG01)                    00025000
                          COMMAREA(TG01-AREA)                           00025100
                          LENGTH  (LENGTH OF TG01-AREA)                 00025200
           END-EXEC.                                                    00025300
                                                                        00025400
           IF TG01-ESITO NOT = 'OK' AND TG01-SQLCODE NOT = 0            00025500
                                    AND TG01-SQLCODE NOT = 100          00025600
              MOVE    2                     TO RCCYS000-ERR-ACT         00025700
              MOVE    RCCYS000-PGM          TO RCCYM000-ERR-PGM         00025800
              MOVE    TG01-SQLCODE          TO RCCYM000-ERR-CODE        00025900
              MOVE    TG01-MESS             TO RCCYM000-ERR-MSG         00026000
              PERFORM SEND-ERRORE                                       00026100
                 THRU SEND-ERRORE-EX                                    00026200
           END-IF.                                                      00026300
           IF TG01-SQLCODE = 100                                        00026400
              MOVE '1'                   TO RCTP011-FL-ERR              00026500
              MOVE 'FILIALE INESISTENTE'                                00026600
                                         TO RCCYFOOT-ERR-MSG            00026700
           END-IF.                                                      00026800
       CONTROLLO-FILIALE-EX.                                            00026900
           EXIT.                                                        00027000
                                                                        00027100
       CONTROLLO-VDACO.                                                 00029900
           INITIALIZE               RCCYR02.                            00030010
           MOVE RCCYM011-VDACO-V TO R02-VDACO.                          00030100
           MOVE '01'             TO R02-TIPO-FUNZ.                      00030200
           MOVE 'RCBTR02'        TO R02-PGM-CALL.                       00030300
           MOVE RCTP011-DT-FMT   TO R02-DATA.                           00030400
                                                                        00030410
           CALL R02-PGM-CALL USING RCCYR02                              00030500
                                                                        00030600
           IF R02-RETURN-CODE = '9'                                     00031000
              MOVE    2                    TO RCCYS000-ERR-ACT          00031100
              MOVE    RCCYS000-PGM         TO RCCYM000-ERR-PGM          00031200
              MOVE    R02-SQLCODE          TO RCCYM000-ERR-CODE         00031300
              MOVE    R02-MSGERR           TO RCCYM000-ERR-MSG          00031400
              PERFORM SEND-ERRORE                                       00031500
                 THRU SEND-ERRORE-EX                                    00031600
           END-IF.                                                      00031700
           IF R02-RETURN-CODE = '1'                                     00031800
              MOVE '4'                        TO RCTP011-FL-ERR         00031900
              MOVE 'VOCE DACO INESISTENTE'    TO RCCYFOOT-ERR-MSG       00032000
           END-IF.                                                      00032100
           MOVE R02-ANVD-PART                 TO RCTP011-COMMAREA-PART. 00032140
       CONTROLLO-VDACO-EX.                                              00032200
           EXIT.                                                        00032300
                                                                        00032400
       CONTROLLO-DATA.                                                  00036600
           IF RCCYM011-DATA-V  NOT = SPACES                             00036700
      *---- VERIFICA FORMALE DATA CON CODA                              00036800
              MOVE RCCYM011-DATA-V      TO CODA-INPUT                   00036900
              PERFORM RCCODA                                            00037000
              IF CODA-RETURN NOT = 0                                    00037100
                 MOVE '7'               TO RCTP011-FL-ERR               00037200
                 MOVE 'DATA DIGITATA NON CORRETTA'                      00037300
                                        TO RCCYFOOT-ERR-MSG             00037400
              ELSE                                                      00037500
                 MOVE CODA-OUT-AAAAMMGG TO RCTP011-COMMAREA-DATA        00037600
                 MOVE CODA-OUT-CHAR     TO RCCYM011-DATA-V              00037610
                 IF CODA-OUT-AAAAMMGG NOT LESS RCTP011-DT-SYS           00037700
                    MOVE '8'            TO RCTP011-FL-ERR               00037800
                    MOVE 'DATA INSERITA NON INFERIORE A OGGI'           00037900
                                        TO RCCYFOOT-ERR-MSG             00038000
                 END-IF                                                 00038100
                 IF RCTP011-FL-ERR = '0'                                00038200
                    IF CODA-OUT-AAAAMMGG LESS RCCYS000-TS-UID-DT-SV     00038300
                       MOVE '9'         TO RCTP011-FL-ERR               00038400
                       MOVE                                             00038500
              'DATA INSERITA INFERIORE ALLA DATA ULTIMO SVECCHIAMENTO'  00038600
                                        TO RCCYFOOT-ERR-MSG             00038700
                    END-IF                                              00038800
                 END-IF                                                 00038900
              END-IF                                                    00039000
           ELSE                                                         00039001
      *-----------------------------------                              00039100
              MOVE RCCYM011-DATA-V      TO RCTP011-COMMAREA-DATA        00039110
           END-IF.                                                      00039200
       CONTROLLO-DATA-EX.                                               00039300
           EXIT.                                                        00039400
                                                                        00039500
       OTTIENI-DT-SYS.                                                  00039600
           EXEC CICS ASKTIME                                            00039700
                     ABSTIME  (RCTP011-ABSTIME)                         00039800
           END-EXEC.                                                    00039900
           EXEC CICS FORMATTIME                                         00040000
                     ABSTIME  (RCTP011-ABSTIME)                         00040100
                     YYYYMMDD (RCTP011-DT-SYS)                          00040200
           END-EXEC.                                                    00040300
           MOVE DT-SYS-AAAA                   TO DT-FMT-AAAA.           00040400
           MOVE DT-SYS-MM                     TO DT-FMT-MM.             00040500
           MOVE DT-SYS-GG                     TO DT-FMT-GG.             00040600
       OTTIENI-DT-SYS-EX.                                               00040700
           EXIT.                                                        00040800
                                                                        00040900
       VALORIZZA-BODY.                                                  00041000
      *** ---  VALORIZZAZIONE ELEMENTI LAYOUT                           00041100
           MOVE '- Sintetico Partite'         TO RCCYHEAD-TITOLO.       00041200
           MOVE ALL LOW-VALUE                 TO RCCYHEAD-JSMNUFLOAT.   00041400
           MOVE ALL LOW-VALUE                 TO RCCYHEAD-ERRORE.       00041600
                                                                        00041700
      *** ---  MIN DATA E MAX DATA PER CALENDARIO                       00041800
           MOVE RCCYS000-TS-UID-DT-SV(1:4)    TO RCCYM011-M011AMIN.     00041910
           MOVE RCCYS000-TS-UID-DT-SV(5:2)    TO RCCYM011-M011MMIN.     00041920
           MOVE RCCYS000-TS-UID-DT-SV(7:2)    TO RCCYM011-M011DMIN.     00041930
           MOVE DT-SYS-AAAA                   TO RCCYM011-M011AMAX.     00041940
           MOVE DT-SYS-MM                     TO RCCYM011-M011MMAX.     00041950
           MOVE DT-SYS-GG                     TO RCCYM011-M011DMAX.     00041960
                                                                        00042100
           PERFORM LIVELLO-UTENZA                                       00042200
              THRU LIVELLO-UTENZA-EX.                                   00042300
                                                                        00042400
      *** ---  ELEMENTI DEL FORM                                        00042500
           MOVE RCCYS000-TOKEN                TO RCCYM011-RCTOKEN.      00042600
           IF RCCYM011-FIL-V NOT = SPACES                               00042700
              MOVE RCCYM011-FIL-V             TO RCCYM011-M011FIL.      00042800
           IF RCCYM011-VDACO-V NOT = SPACES                             00042900
              MOVE RCCYM011-VDACO-V           TO RCCYM011-M011VDACO.    00043000
           IF RCCYM011-DATA-V NOT = SPACES                              00043100
              MOVE RCCYM011-DATA-V            TO RCCYM011-M011DATA.     00043200
                                                                        00043300
           MOVE 'checked'                     TO RCCYM011-M011DACO0.    00043400
           IF RCCYM011-DACO-V NOT = SPACES                              00043500
              IF RCCYM011-DACO-V = '1'                                  00043600
                 MOVE 'checked'               TO RCCYM011-M011DACO1     00043700
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011DACO0     00043800
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011DACO2     00043900
              END-IF                                                    00044000
              IF RCCYM011-DACO-V = '2'                                  00044100
                 MOVE 'checked'               TO RCCYM011-M011DACO2     00044200
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011DACO0     00044300
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011DACO1     00044400
              END-IF                                                    00044500
           END-IF.                                                      00044600
                                                                        00044700
           MOVE 'checked'                     TO RCCYM011-M011VIS1.     00044710
           IF RCCYM011-VIS-V NOT = SPACES                               00044800
              IF RCCYM011-VIS-V = '0'                                   00044900
                 MOVE 'checked'               TO RCCYM011-M011VIS0      00045000
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS1      00045100
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS2      00045200
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS3      00045300
              END-IF                                                    00045400
              IF RCCYM011-VIS-V = '1'                                   00045500
                 MOVE 'checked'               TO RCCYM011-M011VIS1      00045600
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS0      00045700
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS2      00045800
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS3      00045900
              END-IF                                                    00046000
              IF RCCYM011-VIS-V = '2'                                   00046100
                 MOVE 'checked'               TO RCCYM011-M011VIS2      00046200
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS0      00046300
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS1      00046400
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS3      00046500
              END-IF                                                    00046600
              IF RCCYM011-VIS-V = '3'                                   00046700
                 MOVE 'checked'               TO RCCYM011-M011VIS3      00046800
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS0      00046900
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS1      00047000
                 MOVE ALL LOW-VALUE           TO RCCYM011-M011VIS2      00047100
              END-IF                                                    00047200
           END-IF.                                                      00047300
                                                                        00047400
      *** ---  VALORIZZAZIONE IMMAGINI E COLLEGAMENTI                   00047500
           MOVE '&M011ACT='                   TO RCCYM011-M011ACT.      00047600
           MOVE RCCYHEAD-PATH                 TO RCCYM011-M011ACT-URL.  00047700
           MOVE 'RCTP011/RCMP011'             TO RCCYM011-M011ACT-VAR.  00047800
                                                                        00047900
           MOVE '&RCIM017='                   TO RCCYM011-RCIM017.      00048000
           MOVE RCCYHEAD-PATH                 TO RCCYM011-RCIM017-URL.  00048100
           MOVE 'LOADIMG/RCIM017'             TO RCCYM011-RCIM017-VAR.  00048200
                                                                        00048300
           MOVE '&RCIM021='                   TO RCCYM011-RCIM021.      00048400
           MOVE RCCYHEAD-PATH                 TO RCCYM011-RCIM021-URL.  00048500
           MOVE 'LOADIMG/RCIM021'             TO RCCYM011-RCIM021-VAR.  00048600
                                                                        00048700
           MOVE '&RCCSS02='                   TO RCCYM011-RCCSS02.      00048800
           MOVE RCCYHEAD-PATH                 TO RCCYM011-RCCSS02-URL.  00048900
           MOVE 'LOADIMG/RCCSS02'             TO RCCYM011-RCCSS02-VAR.  00049000
                                                                        00049100
           MOVE '&RCJS002='                   TO RCCYM011-RCJS002.      00049200
           MOVE RCCYHEAD-PATH                 TO RCCYM011-RCJS002-URL.  00049300
           MOVE 'LOADIMG/RCJS002'             TO RCCYM011-RCJS002-VAR.  00049400
                                                                        00049500
           MOVE '&RCMPHEAD='                  TO RCCYM011-RCMPHEAD-VAR. 00049600
           MOVE RCCYHEAD-HEAD                 TO RCCYM011-RCMPHEADER.   00049700
           MOVE '&RCMPFOOT='                  TO RCCYM011-RCMPFOOT-VAR. 00049800
           MOVE RCCYFOOT-FOOT                 TO RCCYM011-RCMPFOOTER.   00049900
                                                                        00050000
       VALORIZZA-BODY-EX.                                               00050100
           EXIT.                                                        00050200
                                                                        00050300
       LIVELLO-UTENZA.                                                  00050400
           EVALUATE RCCYS000-TS-UID-IDENT                               00050500
                                                                        00050600
      *---> 'X': DI DIREZIONE                                           00050700
      *          WHEN 'X'                                               00050800
      *             MOVE SPACE                   TO DBCYM002-M002FIL    00050900
      *---> 'A': DI CUAS                                                00051000
      *          WHEN 'A'                                               00051100
      *             MOVE SPACE                   TO DBCYM002-M002FIL    00051200
      *---> 'F': DI FILIALE                                             00051300
                 WHEN 'F'                                               00051400
                    MOVE RCCYS000-TS-UID-FILIALE TO RCCYM011-FIL-V      00051500
                    MOVE 'READONLY'              TO RCCYM011-M011FILR   00051600
                                                                        00051700
      *---> 'D': DI UFFICIO                                             00051800
                 WHEN 'D'                                               00051900
                    MOVE RCCYS000-TS-UID-FILIALE TO RCCYM011-FIL-V      00052000
                    MOVE 'READONLY'              TO RCCYM011-M011FILR   00052100
                                                                        00052200
           END-EVALUATE.                                                00052300
       LIVELLO-UTENZA-EX.                                               00052400
           EXIT.                                                        00052500
                                                                        00052600
       CREA-DOCUMENTO.                                                  00052700
           EXEC CICS DOCUMENT CREATE  DOCTOKEN    (TOKEN)               00052800
                                      TEMPLATE    (TEMPLATE)            00052900
                                      SYMBOLLIST  (HTML-SEND)           00053000
                                      LISTLENGTH  (LENGTH OF HTML-SEND) 00053100
                                      NOHANDLE                          00053200
                                      END-EXEC.                         00053300
       CREA-DOCUMENTO-EX.                                               00053400
           EXIT.                                                        00053500
                                                                        00053600
       SPEDISCI-MAPPA-HTML.                                             00053700
           EXEC CICS WEB SEND         DOCTOKEN    (TOKEN)               00053800
                                      CLNTCODEPAGE(CHARSET)             00053900
                                      NOHANDLE                          00054000
           END-EXEC.                                                    00054100
                                                                        00054200
       SPEDISCI-MAPPA-HTML-EX.                                          00054300
           EXIT.                                                        00054400
                                                                        00054500
       FINE.                                                            00054600
           EXEC CICS RETURN   END-EXEC.                                 00054700
           GOBACK.                                                      00054800
                                                                        00054900
      *---------------------------------------------------------------* 00055000
      * COPY DI PROCEDURE PER CONTROLLO SICUREZZA                       00055100
      *---------------------------------------------------------------* 00055200
           COPY RCCPS000.                                               00055300
      *---------------------------------------------------------------* 00055400
      * COPY DI PROCEDURE PER VALORIZZAZIONE AMBIENTE E HEADER          00055500
      *---------------------------------------------------------------* 00055600
           COPY RCCPHEAD.                                               00055700
      *---------------------------------------------------------------* 00055800
      * COPY DI PROCEDURE PER VALORIZZAZIONE FOOTER                     00055900
      *---------------------------------------------------------------* 00056000
           COPY RCCPFOOT.                                               00056100
      *---------------------------------------------------------------* 00056200
      * COPY DI PROCEDURE PER CONTROLLO FORMALE DATE                    00056300
      *---------------------------------------------------------------* 00056400
           COPY RCCPCODA.                                               00056500
