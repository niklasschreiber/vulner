      ****************************************************************  00000100
      * PROGRAMMA LEGGE  coda mq E SALVA DATI A DB CON INSERT        *  00000200
      * CANALE CBIPX                                                 *  00000300
      * TRANSID : FXM2                                               *  00000400
      * VERSIONE CON RESTART + VALIDATION XML                        *  00000500
      *--------------------------------------------------------------*  00000600
      * RIFER. DATA       USER DESCRIZIONE                           *  00000700
      * ------ ---------- ---- ------------------------------------- *  00000800
      ****************************************************************  00000900
      *                                                                 00001000
       IDENTIFICATION DIVISION.                                         00001100
       PROGRAM-ID.       FXP02020.                                      00001200
       ENVIRONMENT DIVISION.                                            00001300
       DATA DIVISION.                                                   00001400
       WORKING-STORAGE SECTION.                                         00001500
                                                                        00001600
       01  h2-oggetto            pic   x(50) value                      00001610
           'Transazione cics ???? in Errore                  '.         00001620
                                                                        00001630
       01  h2-descrizione        pic   x(80) value                      00001640
           'Verificare la Validazione XML                    '.         00001650
                                                                        00001660
       01  h2-email              pic   x(40) value                      00001670
           'm.campanozzi                            '.                  00001680
                                                                        00001690
       01  FXBMAIL               pic   x(08)     value 'FXBMAIL '.      00001691
                                                                        00001692
       01  ebcdic-ccsid              pic    9(04) binary value 1140.    00001700
       01  ascii-ccsid               pic    9(04) binary value 819.     00001800
                                                                        00001900
ottcon*01  OUTput-ebcdic             pic    x(4194304)                  00002000
ottcon*    value spaces.                                                00002100
       01  ascii-INPUT               pic    x(4194304)                  00002200
           value spaces.                                                00002300
                                                                        00002400
       01  temp-national             pic    n(08) national.             00002500
                                                                        00002600
       01  ELEM-MSG                  pic    x(8388608)                  00002700
           value spaces.                                                00002800
                                                                        00002900
       01  h2-xmldoc             pic   x(8388608) value spaces.         00002910
       01  h2-template           pic   x(48)     value 'CREDITI'.       00002920
       01  h2-rc                 pic   9(08)     value zeroes.          00002930
       01  h2-resp               pic   9(08)     value zeroes.          00002931
       01  h2-msg-err            pic   x(40)     value spaces.          00002932
       01  FXBXMLVA              pic   x(08)     value 'FXBXMLVA'.      00002940
       01  EZACIC15              pic   x(08)     value 'EZACIC15'.      00002941
                                                                        00002950
       01  IND-CAR                pic s9(9)   value zeroes.             00003000
       01  IND-CAR2               pic s9(9)   value zeroes.             00003100
       01  IND-DOC                PIC S9(9)   VALUE ZEROES.             00003110
       01  WRK-KEY-EBM            PIC  X(24)  VALUE SPACES.             00003120
       01 TIME-SYS                  PIC S9(15) COMP-3.                  00003200
       01 DAY-SYS                   PIC S9(08) COMP.                    00003300
                                                                        00003400
       01 WRK-TCLOSEX.                                                  00003500
          03 WRK-TCLOSE               PIC 9(04).                        00003600
       01 WRK-ORAMIN.                                                   00003700
          03 WRK-ORA                  PIC 9(02).                        00003800
          03 WRK-MIN                  PIC 9(02).                        00003900
                                                                        00004000
       01 TIME-CODA.                                                    00004100
          03 CODA-GIORNO            PIC X(2).                           00004200
          03 FILLER                 PIC X VALUE '-'.                    00004300
          03 CODA-MESE              PIC X(2).                           00004400
          03 FILLER                 PIC X VALUE '-'.                    00004500
          03 CODA-ANNO              PIC X(4).                           00004600
          03 FILLER                 PIC X VALUE '-'.                    00004700
          03 CODA-ORA               PIC X(2).                           00004800
          03 FILLER                 PIC X VALUE '.'.                    00004900
          03 CODA-MIN               PIC X(2).                           00005000
          03 FILLER                 PIC X VALUE '.'.                    00005100
          03 CODA-SEC               PIC X(2).                           00005200
                                                                        00005300
       01 WK-INTERVAL               PIC 9(6)  VALUE ZEROES.             00005400
       01 AUTOSTART                 PIC X(2)  VALUE SPACES.             00005500
       01 CODA-TS                   PIC X(8)  VALUE 'FXM22000'.         00005600
BPOA14 01 WRK-NOME                  PIC X(8)  VALUE SPACES.             00005700
       01 AREA-TS.                                                      00005800
          03 FILLER                  PIC X(22)                          00005900
             VALUE 'ULTIMO AGGIORNAMENTO: '.                            00006000
          03 ULTIMA-CALL             PIC X(19).                         00006100
          03 FILLER                  PIC X(29)                          00006200
             VALUE 'PROCEDURA ATT(A)/DISATT(D) : '.                     00006300
          03 STATO                   PIC X.                             00006400
          03 FILLER                  PIC X(5) VALUE '- FZ:'.            00006500
          03 FUNZ                    PIC X.                             00006600
                                                                        00006700
       01 WK-RESOURCE-NAME.                                             00006800
          05 WK-RESOURCE-SYST        PIC X(04) VALUE SPACES.            00006900
          05 WK-RESOURCE-TRAN        PIC X(04) VALUE SPACES.            00007000
       01 WK-RESOURCE-LEN            PIC S9(4) COMP VALUE ZEROES.       00007100
                                                                        00007200
       01  W-CAMPI.                                                     00007300
          03 WRK-BLOCCA-SAB         PIC X(1).                           00007400
          03 WRK-BLOCCA-DOM         PIC X(1).                           00007500
          03 WK-RESPONSE            PIC  9(10) VALUE ZEROES.            00007600
          03 WK-APPLICAZ            PIC X(10).                          00007700
          03 WK-TOT-MSG             PIC 9(02).                          00007800
          03 WK-CIST                PIC 9(05).                          00007900
BP8018    03 WK-NUM-ERR             PIC 9.                              00008000
BP8018    03 WK-MAX-ERR             PIC 9.                              00008100
          03 MAX-MSG                PIC 9(02).                          00008200
          03 WK-TIMETASK            PIC S9(08) COMP.                    00008300
          03 WK-MSG-CONSOLE         PIC X(100).                         00008400
          03 WK-MSG-CONSOLE-LEN     PIC S9(08) COMP VALUE +0.           00008500
          03 WRK-ORA-511            PIC 9(2) VALUE ZEROES.              00008600
          03 WRK-ORA-105            PIC 9(2) VALUE ZEROES.              00008700
          03 WRK-MIN-511            PIC 9(2) VALUE ZEROES.              00008800
          03 WRK-MIN-105            PIC 9(2) VALUE ZEROES.              00008900
          03 WRK-MIN-DIFF           PIC 9(2) VALUE ZEROES.              00009000
          03 WK-ERROR.                                                  00009100
             05 WK-ERROR-CODE       PIC X(08).                          00009200
             05 F                   PIC X(02)       VALUE '  '.         00009300
             05 WK-ERROR-DESC       PIC X(100).                         00009400
          03 LEN                    PIC S9(04) COMP VALUE +0.           00009500
                                                                        00009600
       01  WRK-VARIABILI.                                               00009700
           02 WCM-WTIME-T               PIC X(26).                      00009800
           02 WCM-WTIME.                                                00009900
              05  WCM-WTIME-AAAA        PIC X(4).                       00010000
              05  FILLER                PIC X(1).                       00010100
              05  WCM-WTIME-MM          PIC X(2).                       00010200
              05  FILLER                PIC X(1).                       00010300
              05  WCM-WTIME-GG          PIC X(2).                       00010400
              05  FILLER                PIC X(1).                       00010500
              05  WCM-WTIME-HH          PIC X(2).                       00010600
              05  FILLER                PIC X(1).                       00010700
              05  WCM-WTIME-MIN         PIC X(2).                       00010800
              05  FILLER                PIC X(1).                       00010900
              05  WCM-WTIME-SS          PIC X(2).                       00011000
              05  FILLER                PIC X(1).                       00011100
              05  WCM-WTIME-CC          PIC X(6).                       00011200
                                                                        00011300
       01 TIME-APPOGGIO.                                                00011400
          03 ANNO-APP               PIC X(4).                           00011500
          03 FILLER                 PIC X.                              00011600
          03 MESE-APP               PIC X(2).                           00011700
          03 FILLER                 PIC X.                              00011800
          03 GIORNO-APP             PIC X(2).                           00011900
          03 FILLER                 PIC X.                              00012000
          03 ORA                    PIC X(2).                           00012100
          03 FILLER                 PIC X.                              00012200
          03 MIN                    PIC X(2).                           00012300
          03 FILLER                 PIC X.                              00012400
          03 SEC                    PIC X(2).                           00012500
          03 FILLER                 PIC X.                              00012600
          03 DEC                    PIC X(6).                           00012700
                                                                        00012800
       01 DB2-ERROR-MESSAGE              PIC X(20) VALUE SPACE.         00012900
       01 LO-MSG                       USAGE IS SQL TYPE                00013000
                                             IS CLOB (4M).              00013100
                                                                        00013200
       01 WRK-TRANSID                    PIC X(04) VALUE SPACE.         00013300
                                                                        00013400
           COPY FXWSQLRC.                                               00013500
           EXEC SQL INCLUDE SQLCA END-EXEC.                             00013600
           EXEC SQL INCLUDE FXGMQINP END-EXEC.                          00013700
           EXEC SQL INCLUDE FXGMQSET END-EXEC.                          00013800
           EXEC SQL INCLUDE FXGMQLOG END-EXEC.                          00013900
           EXEC SQL INCLUDE FXGXCOFF END-EXEC.                          00014000
                                                                        00014100
      *----------------------------------------------------------       00014200
      *----    Moduli Applicativi Call Dinamiche          -------       00014300
      *----------------------------------------------------------       00014400
      *01  h2-progdb              pic  x(08)   value 'H2PROGDB'.        00014500
       01  h2-progdb              pic  x(08)   value 'EERXDB01'.        00014600
      *---------------------------------------------------------------* 00014700
      *           Area per la Ricostruzione  da  XML==>Dati           * 00014800
      *---------------------------------------------------------------* 00014900
       01 h2-rkp                   pic s9(08)  comp value zeroes.       00015000
       01 h2-msgl                  pic s9(08)  comp value zeroes.       00015100
       01 h2-msg.                                                       00015200
      *   05 h2-elem      occurs 1 to   32000                           00015300
          05 h2-elem      occurs 1 to   4194304                         00015400
             depending on h2-msgl  pic X.                               00015500
      *----------------------------------------------------------       00015600
      *---- Aree per la Chiamata alla CEELOCT             -------       00015700
      *----------------------------------------------------------       00015800
       01 lilian                  pic s9(9) binary.                     00015900
       01 seconds                 comp-2.                               00016000
       01 gregorn                 pic x(17).                            00016100
       01 h2-data                 pic x(20) value spaces.               00016200
      *--------------------------------------------------------------   00016300
      *  Definizioni per la chiamata al modulo CEEMOUT Call. Servic *   00016400
      *--------------------------------------------------------------   00016500
       01 areamsg                 pic   x(130)   value spaces.          00016600
       01 msgstr.                                                       00016700
         02 vstring-length        pic  s9(4)     binary.                00016800
         02 vstring-text.                                               00016900
            03  vstring-char      pic   x,                              00017000
                occurs 0 to 256 times                                   00017100
                depending on vstring-length                             00017200
                            of msgstr.                                  00017300
       01 destin                  pic s9(9) binary.                     00017400
       01 fc.                                                           00017500
         02  condition-token-value.                                     00017600
         copy  ceeigzct.                                                00017700
           03  case-1-condition-id.                                     00017800
               04  severity       pic s9(4) binary.                     00017900
               04  msg-no         pic s9(4) binary.                     00018000
           03  case-2-condition-id                                      00018100
               redefines case-1-condition-id.                           00018200
               04  class-code     pic s9(4) binary.                     00018300
               04  cause-code     pic s9(4) binary.                     00018400
           03  case-sev-ctl       pic x.                                00018500
           03  facility-id        pic xxx.                              00018600
         02  i-s-info             pic s9(9) binary.                     00018700
      *----------------------------------------------------------       00018800
      *    The following copy files define API control blocks.          00018900
      *----------------------------------------------------------       00019000
      *01  w05-message-data       pic  x(32000) value spaces.           00019100
       01  w05-message-data       pic  X(4194304) value spaces.         00019200
                                                                        00019300
       01  h2-table-nelem         pic  9(08)    comp value zeroes.      00019400
       01  h2-last                pic  x(01)    value spaces.           00019500
      *01  h2-table.                                                    00019600
      *    05 h2-table-elem       PIC  X(32000) occurs 125 times.       00019700
       01  h2-table.                                                    00019800
           05 h2-table-elem       PIC  X(4194304).                      00019900
                                                                        00020000
       01  w05-mqm-object-descriptor.                                   00020100
           copy cmqodv.                                                 00020200
       01  w05-mqm-message-descriptor.                                  00020300
           copy cmqmd2v.                                                00020400
       01  w05-mqm-put-message-options.                                 00020500
           copy cmqpmov.                                                00020600
      *--------------------------------------------------------------   00020700
      *    Copy file of constants (for filling in the control blocks)   00020800
      *    and return codes (for testing the result of a call)          00020900
      *--------------------------------------------------------------   00021000
       01  w05-mqm-constants.                                           00021100
           copy cmqv.                                                   00021200
       01  w05-mqm-get-message-options.                                 00021300
           copy cmqgmov.                                                00021400
      *-------------------------------------------------------------    00021500
      *    W06 - Return values                                          00021600
      *-------------------------------------------------------------    00021700
       01  conta                  pic 9(03)   value zeroes.             00021800
       01  h2-qname               pic x(48)   value spaces.             00021900
       01  h2-trace               pic x(01)   value spaces.             00022000
       01  h2-mqm                 pic x(48)   value spaces.             00022100
       01  h2-conn                pic s9(9)   binary.                   00022200
       01  h2-compcode            pic s9(9)   binary.                   00022300
       01  h2-reason              pic s9(9)   binary.                   00022400
       01  h2-options             pic s9(9)   binary.                   00022500
       01  h2-obj                 pic s9(9)   binary.                   00022600
                                                                        00022700
      *01  h2-pathl               pic s9(9)   binary value 32000.       00022800
       01  h2-pathl-buf           pic s9(9)   binary value 4194304.     00022900
       01  h2-pathl-dat           pic s9(9)   binary value zeroes.      00023000
       01  conv-lenght            pic  9(8)   binary value zeroes.      00023010
                                                                        00023100
       01  h2-retrieve            pic  x(80)  value spaces.             00023200
       01  h2-response            pic  9(08)  comp value zeroes.        00023300
                                                                        00023400
       PROCEDURE DIVISION.                                              00023500
                                                                        00023600
           EXEC SQL SET :WCM-WTIME-T = CURRENT TIMESTAMP                00023700
           END-EXEC                                                     00023800
                                                                        00023900
           DISPLAY 'INIZIO PGM FXP02020: ' WCM-WTIME-T                  00024000
                                                                        00024100
      *--------------------------------------------------------------*  00024200
      * VERIFICA STATO DELLA TRANSAZIONE                                00024300
      *--------------------------------------------------------------*  00024400
      *--- INIZIALIZZA LE AREE DI LAVORO                                00024500
           PERFORM 00-INITIALIZE                                        00024600
              THRU 00-INITIALIZE-END                                    00024700
      *---                                                              00024800
      *    PERFORM CONTROLLO-RISORSA                                    00024900
      *       THRU CONTROLLO-RISORSA-END                                00025000
                                                                        00025100
      *    PERFORM LEGGI-DATIMQ THRU LEGGI-DATIMQ-END                   00025200
           MOVE 'BPIO.EBM.EST.PAS.OUT.QUEUE' TO H2-QNAME                00025201
           MOVE 'DQMA'       TO H2-MQM.                                 00025210
           MOVE 'T'          TO H2-TRACE.                               00025220
           MOVE 1            TO MAX-MSG.                                00025230
           MOVE 5            TO WK-MAX-ERR.                             00025240
                                                                        00025300
      *    PERFORM VERIFICA-STATO THRU VERIFICA-STATO-END               00025400
      *                                                                 00025500
      *    IF AUTOSTART NOT = 'SI'                                      00025600
      *       PERFORM 80-FINE-TRAN                                      00025700
      *          THRU 80-FINE-TRAN-END                                  00025800
      *    END-IF.                                                      00025900
                                                                        00026000
      *    PERFORM CONTROLLA-CUTOFF                                     00026100
      *       THRU CONTROLLA-CUTOFF-END                                 00026200
      *                                                                 00026300
      *    PERFORM CONTROLLA-SAB-DOM                                    00026400
      *       THRU CONTROLLA-SAB-DOM-END                                00026500
      *                                                                 00026600
      *--------------------------------------------------------------*  00026700
      * FINE VERIFICA STATO DELLA TRANSAZIONE                           00026800
      *--------------------------------------------------------------*  00026900
                                                                        00027000
      *--------------------------------------------------------------*  00027100
      * ELABORAZIONE                                                    00027200
      *--------------------------------------------------------------*  00027300
      *    PERFORM ESEGUO-RETRIEVE THRU ESEGUO-RETRIEVE-END.            00027400
                                                                        00027500
           PERFORM ESEGUO-CONNECT  THRU ESEGUO-CONNECT-END.             00027600
                                                                        00027700
           PERFORM ESEGUO-OPEN     THRU ESEGUO-OPEN-END.                00027800
                                                                        00027900
           PERFORM ESEGUO-GET      THRU ESEGUO-GET-END.                 00028000
      *--------------------------------------------------------------*  00028100
      * FINE ELABORAZIONE                                               00028200
      *--------------------------------------------------------------*  00028300
                                                                        00028400
                                                                        00028500
      *--------------------------------------------------------------*  00028600
      * FINE PROGRAMMA                                                  00028700
      *--------------------------------------------------------------*  00028800
                                                                        00028900
       H2-SCRIVI-MSG.                                                   00029000
           add 1                      to h2-table-nelem                 00029100
           move w05-message-data      to h2-table-elem.                 00029200
           PERFORM CONVERTI THRU CONVERTI-END                           00029300
      *    move spaces      to   OUTput-ebcdic.                         00029310
      *    move h2-table-elem TO OUTput-ebcdic.                         00029320
           if h2-trace equal 'T'                                        00029400
              perform h2-preleva-data thru h2-preleva-data-end          00029500
              display                                                   00029600
              h2-data ' Grouping = '  mqgmo-groupstatus                 00029700
                      ' Msg = ' w05-message-data(01:500)                00029800
           end-if.                                                      00029900
       H2-SCRIVI-MSG-END.   EXIT.                                       00030000
                                                                        00030100
       H2-MQCLOSE.                                                      00030200
                                                                        00030300
           move mqco-none             to h2-options.                    00030400
                                                                        00030500
           CALL 'MQCLOSE' USING  h2-conn                                00030600
                                 h2-obj                                 00030700
                                 h2-options                             00030800
                                 h2-compcode                            00030900
                                 h2-reason.                             00031000
           if h2-compcode not equal zeroes                              00031100
              display                                                   00031200
              h2-data ' Errore ' h2-reason ' Nella Close Della Coda '   00031300
               h2-qname                                                 00031400
              INITIALIZE     WK-ERROR                                   00031500
              MOVE 'CLOSE   '            TO WK-ERROR-CODE               00031600
              MOVE 'ERRORE CLOSE   :'    TO WK-ERROR-DESC (1:16)        00031700
              MOVE h2-compcode           TO WK-RESPONSE                 00031800
              MOVE WK-RESPONSE           TO WK-ERROR-DESC (17:10)       00031900
              PERFORM VALORIZZA-LOG THRU VALORIZZA-LOG-END              00032000
                PERFORM FINE-ANOMALA THRU FINE-ANOMALA-END              00032100
           end-if.                                                      00032200
       H2-MQCLOSE-END.   EXIT.                                          00032300
                                                                        00032400
       H2-MQDISC.                                                       00032500
           CALL 'MQDISC'  USING  h2-conn                                00032600
                                 h2-compcode                            00032700
                                 h2-reason.                             00032800
           if h2-compcode not equal zeroes                              00032900
              perform h2-preleva-data thru h2-preleva-data-end          00033000
              display                                                   00033100
              h2-data ' Errore ' h2-reason ' Nella Disconnect a '       00033200
               h2-mqm                                                   00033300
              INITIALIZE     WK-ERROR                                   00033400
              MOVE 'MQDISC  '            TO WK-ERROR-CODE               00033500
              MOVE 'ERRORE MQDISC  :'    TO WK-ERROR-DESC (1:16)        00033600
              MOVE h2-compcode           TO WK-RESPONSE                 00033700
              MOVE WK-RESPONSE           TO WK-ERROR-DESC (17:10)       00033800
              PERFORM VALORIZZA-LOG THRU VALORIZZA-LOG-END              00033900
                PERFORM FINE-ANOMALA THRU FINE-ANOMALA-END              00034000
           end-if.                                                      00034100
       H2-MQDISC-END.   EXIT.                                           00034200
                                                                        00034300
       H2-PRELEVA-DATA.                                                 00034400
           call 'CEELOCT' using lilian, seconds, gregorn, fc.           00034500
           move gregorn(01:4)         to      h2-data(01:04).           00034600
           move '/'                   to      h2-data(05:01).           00034700
           move gregorn(05:2)         to      h2-data(06:02).           00034800
           move '/'                   to      h2-data(08:01).           00034900
           move gregorn(07:2)         to      h2-data(09:02).           00035000
           move ' '                   to      h2-data(11:01).           00035100
           move gregorn(09:2)         to      h2-data(12:02).           00035200
           move ':'                   to      h2-data(14:01).           00035300
           move gregorn(11:2)         to      h2-data(15:02).           00035400
           move ':'                   to      h2-data(17:01).           00035500
           move gregorn(13:2)         to      h2-data(18:02).           00035600
       H2-PRELEVA-DATA-END. EXIT.                                       00035700
       INSERISCI-MSG.                                                   00035800
           display 'inserisci-msg'                                      00035900
           display 'numero messaggio: ' h2-table-nelem                  00036000
           display 'flag last       : ' h2-last                         00036100
           display 'messaggio       : ' h2-table (1:500)                00036200
           display 'chiama routine eexrdb01'                            00036300
           perform chiama-routine thru end-chiama-routine               00036400
           PERFORM CARICA-MSG     THRU END-CARICA-MSG                   00036500
           initialize h2-table.                                         00036600
           display 'end-inserisci-msg'.                                 00036700
       END-INSERISCI-MSG.  EXIT.                                        00036800
       CHIAMA-ROUTINE.                                                  00036900
      *    call h2-progdb using dfheiblk dfhcommarea                    00037000
      *                         h2-table h2-table-nelem                 00037100
      *                         h2-last.                                00037200
           INITIALIZE LO-msg DCLFXAMQINP                                00037300
           DISPLAY 'LO-MSG-LENGTH:'  LO-MSG-LENGTH                      00037400
           MOVE h2-pathl-dat     TO LO-msg-LENGTH                       00037500
ottcon     MOVE h2-table-elem    TO LO-msg-DATA (1:LO-msg-LENGTH)       00037600
ottcon*    MOVE OUTput-ebcdic    TO LO-msg-DATA (1:LO-msg-LENGTH)       00037700
           MOVE 0                TO MQINP-STATO-LAV                     00037800
           MOVE h2-table-nelem   TO MQINP-PRG-RIGA                      00037900
           MOVE h2-last          TO MQINP-ULT-RIGA                      00038000
           MOVE MQSET-CANALE     TO MQINP-CANALE                        00038100
           MOVE '0001-01-01-01.01.01.000001' TO MQINP-WTIME-LAV         00038200
           display 'LO-msg-DATA1: ' LO-msg-DATA (1:10)                  00038300
           display 'LO-msg-DATA : ' LO-msg-DATA (1:800)                 00038400
           display 'MQINP-stato-lav  : ' MQINP-stato-lav                00038500
           display 'MQINP-PRG-RIGA : ' MQINP-PRG-RIGA                   00038600
           display 'MQINP-ULT-RIGA : ' MQINP-ULT-RIGA                   00038700
           display 'eseguo insert  '                                    00038800
           EXEC SQL                                                     00038900
             INSERT INTO FXAMQINP                                       00039000
                   (MQINP_WTIME_ACQ                                     00039100
                   ,MQINP_STATO_LAV                                     00039200
                   ,MQINP_PRG_RIGA                                      00039300
                   ,MQINP_ULT_RIGA                                      00039400
                   ,MQINP_KEY_EBM_INP                                   00039500
                   ,MQINP_CANALE                                        00039600
                   ,MQINP_WTIME_LAV                                     00039700
                   ,MQINP_ZXML)                                         00039800
               VALUES                                                   00039900
                  (CURRENT TIMESTAMP                                    00040000
                  ,:MQINP-STATO-LAV                                     00040100
                  ,:MQINP-PRG-RIGA                                      00040200
                  ,:MQINP-ULT-RIGA                                      00040300
                  ,:MQINP-KEY-EBM-INP                                   00040400
                  ,:MQINP-CANALE                                        00040500
                  ,:MQINP-WTIME-LAV                                     00040600
                  ,:LO-MSG)                                             00040700
           END-EXEC                                                     00040800
                                                                        00040900
           display 'sqlcode  INSERT-BASE-TABLE :' SQLCODE               00041000
           EVALUATE SQLCODE                                             00041100
             WHEN 0         CONTINUE                                    00041200
                                                                        00041300
             WHEN OTHER     MOVE 'INSERT FXAMQINP '   TO                00041400
                              DB2-ERROR-MESSAGE                         00041500
                                                                        00041600
                     PERFORM DB2-ERROR THRU END-DB2-ERROR               00041700
           END-EVALUATE                                                 00041800
                                                                        00041900
           display 'fine   INSERT-BASE-TABLE'.                          00042000
       END-CHIAMA-ROUTINE.   EXIT.                                      00042100
       DB2-ERROR SECTION.                                               00042200
           DISPLAY 'ERROR DB2 BECAUSE OF SQLCODE : ' SQLCODE            00042300
                                                                        00042400
           DISPLAY 'PLACE OF ERROR              : ' DB2-ERROR-MESSAGE   00042500
                                                                        00042600
           DISPLAY 'SQLCA                       : ' SQLCA.              00042700
                                                                        00042800
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC                        00042810
*          GOBACK.                                                      00042900
           EXEC CICS RETURN END-EXEC.                                   00042910
      *    INITIALIZE     WK-ERROR                                      00043000
      *    MOVE 'DB2ERROR'            TO WK-ERROR-CODE                  00043100
      *    MOVE DB2-ERROR-MESSAGE     TO WK-ERROR-DESC (1:16)           00043200
      *    MOVE 'SQLCODE : '          TO WK-ERROR-DESC (17:10)          00043300
      *    MOVE  SQLCODE              TO WK-ERROR-DESC (27:10)          00043400
      *    MOVE 'SQLCA   : '          TO WK-ERROR-DESC (37:10)          00043500
      *    MOVE  SQLCA                TO WK-ERROR-DESC (47:10)          00043600
      *    PERFORM VALORIZZA-LOG THRU VALORIZZA-LOG-END                 00043700
      *    PERFORM FINE-ANOMALA THRU FINE-ANOMALA-END.                  00043800
       END-DB2-ERROR. EXIT.                                             00043900
       ESEGUO-RETRIEVE.                                                 00044000
           exec cics retrieve       into   (h2-retrieve)                00044100
                                    length (length of h2-retrieve)      00044200
                                    resp   (h2-response)                00044300
                                    nohandle                            00044400
                                    end-exec.                           00044500
                                                                        00044600
           if h2-response not equal dfhresp(normal)                     00044700
              perform h2-preleva-data thru h2-preleva-data-end          00044800
              display                                                   00044900
              h2-data ' Errore ' h2-response ' Nella Cics Retrieve '    00045000
              display 'h2-retrieve : ' h2-retrieve                      00045100
              display 'length retrieve : ' length of h2-retrieve        00045200
              INITIALIZE     WK-ERROR                                   00045300
              MOVE 'RETRIEVE'            TO WK-ERROR-CODE               00045400
              MOVE 'ERRORE RETRIEVE:'    TO WK-ERROR-DESC (1:16)        00045500
              MOVE h2-compcode           TO WK-RESPONSE                 00045600
              MOVE WK-RESPONSE           TO WK-ERROR-DESC (17:10)       00045700
              MOVE H2-RETRIEVE           TO WK-ERROR-DESC (27:)         00045800
              PERFORM VALORIZZA-LOG THRU VALORIZZA-LOG-END              00045900
              PERFORM FINE-ANOMALA THRU FINE-ANOMALA-END                00046000
           end-if.                                                      00046100
                                                                        00046200
           unstring h2-retrieve     delimited by all ','                00046300
                    into h2-mqm h2-trace h2-qname.                      00046400
                                                                        00046500
           inspect h2-mqm     replacing all low-values by ' '.          00046600
           inspect h2-qname   replacing all low-values by ' '.          00046700
           inspect h2-trace   replacing all low-values by ' '.          00046800
       ESEGUO-RETRIEVE-END. EXIT.                                       00046900
                                                                        00047000
       ESEGUO-CONNECT.                                                  00047100
           call 'MQCONN' using h2-mqm                                   00047200
                               h2-conn                                  00047300
                               h2-compcode                              00047400
                               h2-reason.                               00047500
           if h2-compcode not equal zeroes                              00047600
              perform h2-preleva-data thru h2-preleva-data-end          00047700
              display                                                   00047800
              h2-data ' Errore ' h2-reason ' Nella Connect al Qmanager '00047900
                h2-mqm                                                  00048000
              EXEC CICS RETURN END-EXEC                                 00048010
      *       INITIALIZE     WK-ERROR                                   00048100
      *       MOVE 'CONNECT '            TO WK-ERROR-CODE               00048200
      *       MOVE 'ERRORE CONNECT :'    TO WK-ERROR-DESC (1:16)        00048300
      *       MOVE h2-compcode           TO WK-RESPONSE                 00048400
      *       MOVE WK-RESPONSE           TO WK-ERROR-DESC (17:10)       00048500
      *       MOVE H2-MQM                TO WK-ERROR-DESC (27:)         00048600
      *       PERFORM VALORIZZA-LOG THRU VALORIZZA-LOG-END              00048700
      *         PERFORM FINE-ANOMALA THRU FINE-ANOMALA-END              00048800
           end-if.                                                      00048900
                                                                        00049000
      *    PERFORM LEGGI-DATIMQ THRU LEGGI-DATIMQ-END.                  00049100
                                                                        00049200
      *    MOVE 'BPIO.EBM.EST.MUL.OUT.QUEUE' TO H2-QNAME                00049300
           move mqot-q                      to   mqod-objecttype.       00049400
           move h2-qname                    to   mqod-objectname.       00049500
           move spaces                      to   mqod-dynamicqname.     00049600
           compute h2-options = mqoo-input-exclusive.                   00049700
       ESEGUO-CONNECT-END. EXIT.                                        00049800
                                                                        00049900
       ESEGUO-OPEN.                                                     00050000
           call 'MQOPEN' using h2-conn                                  00050100
                               mqod                                     00050200
                               h2-options                               00050300
                               h2-obj                                   00050400
                               h2-compcode                              00050500
                               h2-reason.                               00050600
           if h2-compcode not equal zeroes                              00050700
              perform h2-preleva-data thru h2-preleva-data-end          00050800
              display                                                   00050900
              h2-data ' Errore ' h2-reason ' Nella Open della Coda '    00051000
               h2-qname                                                 00051100
                 PERFORM H2-MQDISC  THRU H2-MQDISC-END                  00051200
              EXEC CICS RETURN END-EXEC                                 00051210
      *       INITIALIZE     WK-ERROR                                   00051300
      *       MOVE 'OPEN    '            TO WK-ERROR-CODE               00051400
      *       MOVE 'ERRORE OPEN    :'    TO WK-ERROR-DESC (1:16)        00051500
      *       MOVE h2-compcode           TO WK-RESPONSE                 00051600
      *       MOVE WK-RESPONSE           TO WK-ERROR-DESC (17:10)       00051700
      *       PERFORM VALORIZZA-LOG THRU VALORIZZA-LOG-END              00051800
      *         PERFORM FINE-ANOMALA THRU FINE-ANOMALA-END              00051900
           end-if.                                                      00052000
       ESEGUO-OPEN-END.    EXIT.                                        00052100
                                                                        00052200
       ESEGUO-GET.                                                      00052300
           move mqmo-none           to mqgmo-matchoptions.              00052400
           move 2                   to mqgmo-version.                   00052500
           move zeroes              to  WK-TOT-MSG.                     00052600
                                                                        00052700
           PERFORM UNTIL                                                00052800
      *       (H2-REASON  NOT EQUAL ZEROES) OR                          00052900
              (H2-REASON  NOT EQUAL ZEROES or  WK-TOT-MSG = MAX-MSG)    00053000
              display 'sono until'                                      00053100
              display 'H2-REASON:' H2-REASON                            00053200
              display 'h2-compcode:' h2-compcode                        00053300
              display 'tot msg    :' WK-TOT-MSG                         00053400
              move zeroes                      to  h2-msgl              00053500
              move zeroes                      to  h2-rkp               00053600
              move spaces                      to  w05-message-data     00053700
              move mqci-none                   to  mqmd-correlid        00053800
              move mqmi-none                   to  mqmd-msgid           00053900
              move spaces                      to  mqmd-replytoq        00054000
              move spaces                      to  mqmd-replytoqmgr     00054100
              move 5                           to  mqmd-priority        00054200
              move mqper-persistent            to  mqmd-persistence     00054300
                                                                        00054400
              compute mqgmo-options   =   mqgmo-no-syncpoint  +         00054500
      *                                   MQGMO-CONVERT       +         00054600
                                          mqgmo-logical-order +         00054700
                                          mqgmo-all-msgs-available      00054800
                                                                        00054900
              call 'MQGET' using    h2-conn                             00055000
                                    h2-obj                              00055100
                                    mqmd                                00055200
                                    mqgmo                               00055300
                                    h2-pathl-buf                        00055400
                                    w05-message-data                    00055500
                                    h2-pathl-dat                        00055600
                                    h2-compcode                         00055700
                                    h2-reason                           00055800
              if h2-compcode not equal zeroes                           00055900
                 perform h2-preleva-data thru h2-preleva-data-end       00056000
                 display                                                00056100
                   h2-data  ' ' h2-reason                               00056200
                   '  Non ci Sono Piu Messaggi Nella Coda '             00056300
                   h2-qname                                             00056400
                 PERFORM H2-MQCLOSE THRU H2-MQCLOSE-END                 00056500
                 PERFORM H2-MQDISC  THRU H2-MQDISC-END                  00056600
                 EXEC CICS RETURN END-EXEC                              00056610
      *          MOVE 000100 TO WK-INTERVAL                             00056700
      *          PERFORM FINE-OK THRU FINE-OK-END                       00056800
              end-if                                                    00056900
                                                                        00057000
              display 'h2-pathl1:' h2-pathl-buf                         00057100
              display 'h2-pathl2:' h2-pathl-dat                         00057200
              PERFORM H2-PRELEVA-DATA THRU H2-PRELEVA-DATA-END          00057300
                                                                        00057400
              move mqmo-match-group-id to mqgmo-matchoptions            00057500
      *** messaggio in group                                            00057600
              if mqgmo-groupstatus  equal mqgs-msg-in-group             00057700
                 PERFORM H2-SCRIVI-MSG THRU H2-SCRIVI-MSG-END           00057800
                 move 'N'             to h2-last                        00057900
                 display 'msg in group : '   h2-table-nelem             00058000
                 perform inserisci-msg thru end-inserisci-msg           00058100
              else                                                      00058200
      *** messaggio last in group                                       00058300
                 move mqmo-none        to mqgmo-matchoptions            00058400
                 PERFORM H2-SCRIVI-MSG THRU H2-SCRIVI-MSG-END           00058500
                 display 'msg last group :' h2-table-nelem              00058600
                 move 'S'             to h2-last                        00058700
                 perform inserisci-msg thru end-inserisci-msg           00058800
      *          perform ESEGUI-VALIDATION thru ESEGUI-VALIDATION-END   00058900
                 move zeroes          to h2-table-nelem                 00059000
                 move 'N'             to h2-last                        00059100
                 ADD 1                to WK-TOT-MSG                     00059200
              end-if                                                    00059300
              end-perform.                                              00059400
              display 'end-perform'                                     00059500
              display 'H2-REASON:' H2-REASON                            00059600
              display 'h2-compcode:' h2-compcode                        00059700
              display 'tot msg    :' WK-TOT-MSG                         00059800
              IF WK-TOT-MSG = MAX-MSG                                   00059900
                 PERFORM H2-MQCLOSE THRU H2-MQCLOSE-END                 00060000
                 PERFORM H2-MQDISC  THRU H2-MQDISC-END                  00060100
                 EXEC CICS RETURN END-EXEC                              00060110
      *          MOVE 000010 TO WK-INTERVAL                             00060200
      *          PERFORM FINE-OK-0 THRU FINE-OK-0-END                   00060300
              END-IF.                                                   00060400
       ESEGUO-GET-END.     EXIT.                                        00060500
       LEGGI-DATIMQ.                                                    00060600
            initialize DCLFXTMQSET.                                     00060700
            MOVE SPACES   TO WRK-TRANSID.                               00060800
            MOVE EIBTRNID TO WRK-TRANSID.                               00060900
            MOVE WRK-TRANSID TO MQSET-TRANSID.                          00061000
            DISPLAY 'WRK-TRANSID:' WRK-TRANSID.                         00061100
           EXEC SQL  SELECT MQSET_TRANSID,                              00061200
                            MQSET_CANALE,                               00061300
                            MQSET_NAMEMQ,                               00061400
                            MQSET_TYPEMQ,                               00061500
                            MQSET_STATO_TRAN,                           00061600
                            MQSET_DATE_STATO_TRAN,                      00061700
                            MQSET_TOT_ERR,                              00061800
                            MQSET_TRACE,                                00061900
                            MQSET_MAXMSG,                               00062000
                            MQSET_MAXERR                                00062100
                     INTO  :MQSET-TRANSID,                              00062200
                           :MQSET-CANALE,                               00062300
                           :MQSET-NAMEMQ,                               00062400
                           :MQSET-TYPEMQ,                               00062500
                           :MQSET-STATO-TRAN,                           00062600
                           :MQSET-DATE-STATO-TRAN,                      00062700
                           :MQSET-TOT-ERR,                              00062800
                           :MQSET-TRACE,                                00062900
                           :MQSET-MAXMSG,                               00063000
                           :MQSET-MAXERR                                00063100
                     FROM    FXTMQSET                                   00063200
                     WHERE                                              00063300
                            MQSET_TRANSID = :MQSET-TRANSID              00063400
           END-EXEC                                                     00063500
           MOVE SQLCODE  TO W-SQLCODE                                   00063600
           IF NOT W-SQL-OK                                              00063700
              MOVE 'SELECT FXTMQSET '   TO                              00063800
                              DB2-ERROR-MESSAGE                         00063900
                                                                        00064000
              PERFORM DB2-ERROR THRU END-DB2-ERROR                      00064100
           END-IF                                                       00064200
           MOVE MQSET-NAMEMQ TO H2-QNAME.                               00064300
           MOVE MQSET-TYPEMQ TO H2-MQM.                                 00064400
           MOVE MQSET-TRACE  TO H2-TRACE.                               00064500
           MOVE MQSET-MAXMSG TO MAX-MSG.                                00064600
           MOVE MQSET-MAXERR TO WK-MAX-ERR.                             00064700
       LEGGI-DATIMQ-END.   EXIT.                                        00064800
       FINE-OK.                                                         00064900
      *    GOBACK.                                                      00065000
      *--------------------------------------------------------------*  00065100
      * RESTART DELLA TRANSAZIONE                                       00065200
      *--------------------------------------------------------------*  00065300
                                                                        00065400
           MOVE ZEROES TO WK-NUM-ERR                                    00065500
           PERFORM AGGIORNA-DATIMQ                                      00065600
              THRU AGGIORNA-DATIMQ-END                                  00065700
                                                                        00065800
           PERFORM 95-RESTART-TRAN                                      00065900
              THRU 95-RESTART-TRAN-END                                  00066000
           .                                                            00066100
       FINE-OK-END.  EXIT.                                              00066200
       FINE-OK-0.                                                       00066300
      *    GOBACK.                                                      00066400
      *--------------------------------------------------------------*  00066500
      * RESTART DELLA TRANSAZIONE                                       00066600
      *--------------------------------------------------------------*  00066700
                                                                        00066800
           MOVE ZEROES TO WK-NUM-ERR                                    00066900
           PERFORM AGGIORNA-DATIMQ                                      00067000
              THRU AGGIORNA-DATIMQ-END                                  00067100
                                                                        00067200
           PERFORM 95-RESTART-TRAN-0                                    00067300
              THRU 95-RESTART-TRAN-0-END                                00067400
           .                                                            00067500
       FINE-OK-0-END.  EXIT.                                            00067600
       FINE-ANOMALA.                                                    00067700
      *------ ANNULLA LE MODIFICHE AL DB IN CASO DI ERRORE              00067800
              EXEC CICS SYNCPOINT ROLLBACK END-EXEC                     00067900
                                                                        00068000
      *------ SCRIVE LA TABELLA DI LOG (FXTMQLOG)                       00068100
              PERFORM SCRIVI-LOG                                        00068200
                 THRU SCRIVI-LOG-END                                    00068300
                                                                        00068400
              IF SQLCODE NOT = ZEROES                                   00068500
                 PERFORM 80-FINE-TRAN                                   00068600
                    THRU 80-FINE-TRAN-END                               00068700
              ELSE                                                      00068800
      *------ CONFERMA LA SCRITTURA DEL LOG                             00068900
              EXEC CICS SYNCPOINT END-EXEC                              00069000
              END-IF                                                    00069100
                                                                        00069200
BP8018        IF WK-NUM-ERR EQUAL WK-MAX-ERR                            00069300
                 PERFORM 80-FINE-TRAN                                   00069400
                    THRU 80-FINE-TRAN-END                               00069500
BP8018        ELSE                                                      00069600
BP8018           ADD 1            TO WK-NUM-ERR                         00069700
                 PERFORM AGGIORNA-DATIMQ                                00069800
                    THRU AGGIORNA-DATIMQ-END                            00069900
                 MOVE 000100 TO WK-INTERVAL                             00070000
                 PERFORM 95-RESTART-TRAN                                00070100
                    THRU 95-RESTART-TRAN-END                            00070200
              END-IF.                                                   00070300
       FINE-ANOMALA-END.  EXIT.                                         00070400
      *--------------------------------------------------------------*  00070500
       CONTROLLO-RISORSA.                                               00070600
           DISPLAY 'CONTROLLO-RISORSA'.                                 00070700
                                                                        00070800
           MOVE 8              TO WK-RESOURCE-LEN                       00070900
           MOVE 'ESTD'         TO WK-RESOURCE-SYST                      00071000
           MOVE WRK-TRANSID    TO WK-RESOURCE-TRAN                      00071100
                                                                        00071200
           MOVE DFHVALUE(TASK) TO WK-TIMETASK                           00071300
                                                                        00071400
           EXEC CICS HANDLE CONDITION ENQBUSY(190-ENQBUSY) END-EXEC     00071500
                                                                        00071600
           EXEC CICS ENQ RESOURCE(WK-RESOURCE-NAME)                     00071700
                         LENGTH(WK-RESOURCE-LEN)                        00071800
                         MAXLIFETIME(WK-TIMETASK)                       00071900
                         NOSUSPEND                                      00072000
           END-EXEC                                                     00072100
                                                                        00072200
           EXEC CICS IGNORE CONDITION ENQBUSY END-EXEC                  00072300
           .                                                            00072400
       CONTROLLO-RISORSA-END.                                           00072500
           EXIT.                                                        00072600
      *--------------------------------------------------------------*  00072700
       190-ENQBUSY.                                                     00072800
           DISPLAY '190-ENQBUSY'.                                       00072900
                                                                        00073000
           MOVE +200                TO LEN                              00073100
                                                                        00073200
           MOVE 000030 TO WK-INTERVAL                                   00073300
      *--- OPZIONE INTERVAL NEL FORMATO HHMMSS                          00073400
           EXEC CICS START                                              00073500
                     TRANSID(WRK-TRANSID)                               00073600
                     INTERVAL(000030)                                   00073700
           END-EXEC                                                     00073800
                                                                        00073900
           EXEC CICS RETURN END-EXEC                                    00074000
           .                                                            00074100
       190-ENQBUSY-END.                                                 00074200
           EXIT.                                                        00074300
                                                                        00074400
      *--------------------------------------------------------------*  00074500
       00-INITIALIZE.                                                   00074600
                                                                        00074700
           INITIALIZE     W-CAMPI                                       00074800
           MOVE 7601           TO WK-CIST                               00074900
BP8018*    MOVE 5              TO WK-MAX-ERR                            00075000
           MOVE SPACES   TO WRK-TRANSID.                                00075100
           MOVE EIBTRNID TO WRK-TRANSID.                                00075200
           .                                                            00075300
       00-INITIALIZE-END.                                               00075400
           EXIT.                                                        00075500
                                                                        00075600
      **------------------------------------------------------------**  00075700
       VERIFICA-STATO.                                                  00075800
           DISPLAY 'VERIFICA-STATO'.                                    00075900
BP8018     MOVE MQSET-TOT-ERR TO WK-NUM-ERR                             00076000
           MOVE SPACES        TO AUTOSTART                              00076100
                                                                        00076200
           EVALUATE MQSET-STATO-TRAN                                    00076300
              WHEN 'D'                                                  00076400
                 MOVE 'NO' TO AUTOSTART                                 00076500
                 PERFORM VERIFICA-SE-START-MAN                          00076600
                    THRU VERIFICA-SE-START-MAN-END                      00076700
              WHEN 'A'                                                  00076800
                 MOVE 'SI' TO AUTOSTART                                 00076900
              WHEN OTHER                                                00077000
                 MOVE 'A'  TO MQSET-STATO-TRAN                          00077100
                 MOVE 'SI' TO AUTOSTART                                 00077200
                 MOVE ZEROES TO WK-NUM-ERR                              00077300
      *          MOVE ZEROES TO MQSET-TOT-ERR                           00077400
                 PERFORM AGGIORNA-STATO                                 00077500
                    THRU AGGIORNA-STATO-END                             00077600
           END-EVALUATE.                                                00077700
                                                                        00077800
       VERIFICA-STATO-END.                                              00077900
           EXIT.                                                        00078000
       AGGIORNA-STATO.                                                  00078100
           DISPLAY 'AGGIORNA-STATO'.                                    00078200
            MOVE WRK-TRANSID TO MQSET-TRANSID.                          00078300
            MOVE WK-NUM-ERR TO MQSET-TOT-ERR                            00078400
           EXEC SQL  UPDATE  FXTMQSET                                   00078500
                  SET MQSET_STATO_TRAN      = :MQSET-STATO-TRAN,        00078600
                      MQSET_DATE_STATO_TRAN = CURRENT TIMESTAMP,        00078700
                      MQSET_TOT_ERR         = :MQSET-TOT-ERR            00078800
                     WHERE                                              00078900
                            MQSET_TRANSID = :MQSET-TRANSID              00079000
           END-EXEC                                                     00079100
           MOVE SQLCODE  TO W-SQLCODE                                   00079200
           IF NOT W-SQL-OK                                              00079300
              MOVE 'UPDATE FXTMQSET '   TO                              00079400
                              DB2-ERROR-MESSAGE                         00079500
                                                                        00079600
              PERFORM DB2-ERROR THRU END-DB2-ERROR                      00079700
           END-IF.                                                      00079800
           PERFORM WRITE-CODA-TS                                        00079900
              THRU WRITE-CODA-TS-END.                                   00080000
       AGGIORNA-STATO-END.                                              00080100
           EXIT.                                                        00080200
       AGGIORNA-DATIMQ.                                                 00080300
           DISPLAY 'AGGIORNA-DATIMQ'.                                   00080400
            MOVE WRK-TRANSID TO MQSET-TRANSID.                          00080500
            MOVE WK-NUM-ERR TO MQSET-TOT-ERR                            00080600
           EXEC SQL  UPDATE  FXTMQSET                                   00080700
                  SET MQSET_DATE_STATO_TRAN = CURRENT TIMESTAMP,        00080800
                      MQSET_TOT_ERR         = :MQSET-TOT-ERR            00080900
                     WHERE                                              00081000
                            MQSET_TRANSID = :MQSET-TRANSID              00081100
           END-EXEC                                                     00081200
           MOVE SQLCODE  TO W-SQLCODE                                   00081300
           IF NOT W-SQL-OK                                              00081400
              MOVE 'UPDATE2 FXTMQSET '   TO                             00081500
                              DB2-ERROR-MESSAGE                         00081600
                                                                        00081700
              PERFORM DB2-ERROR THRU END-DB2-ERROR                      00081800
           END-IF.                                                      00081900
           PERFORM WRITE-CODA-TS                                        00082000
              THRU WRITE-CODA-TS-END.                                   00082100
       AGGIORNA-DATIMQ-END.                                             00082200
           EXIT.                                                        00082300
       80-FINE-TRAN.                                                    00082400
           DISPLAY '80-FINE-TRAN'.                                      00082500
                                                                        00082600
                                                                        00082700
           MOVE 'D'              TO MQSET-STATO-TRAN                    00082800
      *    MOVE ZEROES TO MQSET-TOT-ERR                                 00082900
           MOVE WK-NUM-ERR TO MQSET-TOT-ERR                             00083000
           PERFORM AGGIORNA-STATO                                       00083100
              THRU AGGIORNA-STATO-END                                   00083200
                                                                        00083300
      *    PERFORM WRITE-CODA-TS                                        00083400
      *       THRU WRITE-CODA-TS-END.                                   00083500
                                                                        00083600
           PERFORM MESSAGGIO-STOP                                       00083700
              THRU MESSAGGIO-STOP-END                                   00083800
                                                                        00083900
           EXEC CICS RETURN END-EXEC                                    00084000
           .                                                            00084100
       80-FINE-TRAN-END.                                                00084200
           EXIT.                                                        00084300
       WRITE-CODA-TS.                                                   00084400
           DISPLAY 'WRITE-CODA-TS'.                                     00084500
                                                                        00084600
           MOVE MQSET-STATO-TRAN   TO STATO.                            00084700
                                                                        00084800
           EXEC SQL SET :WCM-WTIME-T = CURRENT TIMESTAMP                00084900
           END-EXEC                                                     00085000
                                                                        00085100
      * IL FORMATO DEL TIMESTAMP CHE VA REGISTRATO SULLA CODA           00085200
      * CHE POI APPARIRA' SULLA MAPPA DEL PGM MGP02646 E'               00085300
      * GG-MM-AAAA-HH.MM.SS                                             00085400
                                                                        00085500
           MOVE WCM-WTIME-T  TO TIME-APPOGGIO                           00085600
           MOVE ANNO-APP     TO CODA-ANNO                               00085700
           MOVE MESE-APP     TO CODA-MESE                               00085800
           MOVE GIORNO-APP   TO CODA-GIORNO                             00085900
           MOVE ORA          TO CODA-ORA                                00086000
           MOVE MIN          TO CODA-MIN                                00086100
           MOVE SEC          TO CODA-SEC                                00086200
           MOVE TIME-CODA    TO ULTIMA-CALL                             00086300
BP8018     MOVE WK-NUM-ERR   TO FUNZ                                    00086400
           EXEC CICS IGNORE CONDITION QIDERR     END-EXEC               00086500
           EXEC CICS DELETEQ TS QUEUE(CODA-TS) END-EXEC                 00086600
           MOVE +80          TO LEN.                                    00086700
           EXEC CICS WRITEQ TS                                          00086800
                     QUEUE (CODA-TS)                                    00086900
                     FROM  (AREA-TS)                                    00087000
                     LENGTH(LEN)                                        00087100
           END-EXEC.                                                    00087200
                                                                        00087300
       WRITE-CODA-TS-END.                                               00087400
           EXIT.                                                        00087500
       MESSAGGIO-STOP.                                                  00087600
           DISPLAY 'MESSAGGIO-STOP'.                                    00087700
                                                                        00087800
      *--- MANDA IL MESSAGGIO A CONSOLE CHE LA EHAK SI E' FERMATA       00087900
           MOVE 'BPODOCBI'               TO WK-MSG-CONSOLE              00088000
           MOVE ' TRANSAZIONE FXM2 FERMA -  MQ PER CBIP XML'            00088100
                                         TO WK-MSG-CONSOLE(09:46)       00088200
                                                                        00088300
           MOVE +55                      TO WK-MSG-CONSOLE-LEN          00088400
                                                                        00088500
      *    DISPLAY 'MSG-CONSOLE : ' WK-MSG-CONSOLE(1:WK-MSG-CONSOLE-LEN)00088600
                                                                        00088700
           EXEC CICS WRITE OPERATOR TEXT(WK-MSG-CONSOLE)                00088800
                              TEXTLENGTH(WK-MSG-CONSOLE-LEN)            00088900
           END-EXEC                                                     00089000
           .                                                            00089100
       MESSAGGIO-STOP-END.                                              00089200
           EXIT.                                                        00089300
                                                                        00089400
      *--------------------------------------------------------------*  00089500
       95-RESTART-TRAN.                                                 00089600
           DISPLAY '95-RESTART-TRAN'.                                   00089700
                                                                        00089800
           MOVE +200                TO LEN                              00089900
                                                                        00090000
           EXEC CICS START                                              00090100
                     TRANSID(WRK-TRANSID)                               00090200
                     INTERVAL(000100)                                   00090300
           END-EXEC                                                     00090400
                                                                        00090500
           EXEC CICS RETURN END-EXEC                                    00090600
           .                                                            00090700
       95-RESTART-TRAN-END.                                             00090800
           EXIT.                                                        00090900
                                                                        00091000
       95-RESTART-TRAN-0.                                               00091100
           DISPLAY '95-RESTART-TRAN-0'.                                 00091200
                                                                        00091300
           MOVE +200                TO LEN                              00091400
                                                                        00091500
           EXEC CICS START                                              00091600
                     TRANSID(WRK-TRANSID)                               00091700
                     INTERVAL(000010)                                   00091800
           END-EXEC                                                     00091900
                                                                        00092000
           EXEC CICS RETURN END-EXEC                                    00092100
           .                                                            00092200
       95-RESTART-TRAN-0-END.                                           00092300
           EXIT.                                                        00092400
                                                                        00092500
      **------------------------------------------------------------**  00092600
       VERIFICA-SE-START-MAN.                                           00092700
           DISPLAY 'VERIFICA-SE-START-MAN'.                             00092800
                                                                        00092900
      *- DEVO CONFRONTARE I DUE TIMESTAMP : QUELLO DI DISATTIVAZIONE    00093000
      *- DELLA TRANSAZIONE SULLA TABELLA MQSET E QUELLO DI LAVORAZIONE. 00093100
      *- SE LA DIFFERENZA E' MAGGIORE A 3 MINUTI SIGNIFICA CHE STIAMO   00093200
      *- ATTIVANDO LA TRANSAZIONE DIRETTAMENTE DA CICS E PERTANTO VA    00093300
      *- FORZATO LO STATO AD ATTIVO. IN CASO CONTRARIO (RESTART AUTOM   00093400
      *- ATIVA) SI LASCIA LO STATO DISATTIVO                            00093500
                                                                        00093600
      *--- CONTROLLA ANNO                                               00093700
           IF MQSET-DATE-STATO-TRAN(1:4) NOT EQUAL WCM-WTIME-T(1:4)     00093800
              PERFORM IMPOSTA-STATO-ATTIVO                              00093900
                 THRU IMPOSTA-STATO-ATTIVO-END                          00094000
              GO TO VERIFICA-SE-START-MAN-END.                          00094100
                                                                        00094200
      *--- CONTROLLA MESE                                               00094300
           IF MQSET-DATE-STATO-TRAN(6:2) NOT EQUAL WCM-WTIME-T(6:2)     00094400
              PERFORM IMPOSTA-STATO-ATTIVO                              00094500
                 THRU IMPOSTA-STATO-ATTIVO-END                          00094600
              GO TO VERIFICA-SE-START-MAN-END.                          00094700
                                                                        00094800
      *--- CONTROLLA GIORNO                                             00094900
           IF MQSET-DATE-STATO-TRAN(9:2) NOT EQUAL WCM-WTIME-T(9:2)     00095000
              PERFORM IMPOSTA-STATO-ATTIVO                              00095100
                 THRU IMPOSTA-STATO-ATTIVO-END                          00095200
              GO TO VERIFICA-SE-START-MAN-END.                          00095300
                                                                        00095400
      *--- CONTROLLA ORA                                                00095500
           IF MQSET-DATE-STATO-TRAN(12:2) NOT EQUAL WCM-WTIME-T(12:2)   00095600
              MOVE MQSET-DATE-STATO-TRAN(12:2) TO WRK-ORA-511           00095700
              MOVE WCM-WTIME-T(12:2) TO WRK-ORA-105                     00095800
              MOVE MQSET-DATE-STATO-TRAN(15:2) TO WRK-MIN-511           00095900
              MOVE WCM-WTIME-T(15:2) TO WRK-MIN-105                     00096000
              COMPUTE WRK-MIN-511 = WRK-MIN-511 + (60 * WRK-ORA-511)    00096100
              COMPUTE WRK-MIN-105 = WRK-MIN-105 + (60 * WRK-ORA-105)    00096200
              COMPUTE WRK-MIN-DIFF = WRK-MIN-105 - WRK-MIN-511          00096300
              IF WRK-MIN-DIFF GREATER 3                                 00096400
                 display 'ore: passo per maggiore 3 minuti'             00096500
                 PERFORM IMPOSTA-STATO-ATTIVO                           00096600
                    THRU IMPOSTA-STATO-ATTIVO-END                       00096700
              END-IF                                                    00096800
              GO TO VERIFICA-SE-START-MAN-END.                          00096900
                                                                        00097000
      *--- CONTROLLA MINUTI (LIMITE : DIFFERENZA DI PIU' DI 3 MINUTI)   00097100
           IF MQSET-DATE-STATO-TRAN(15:2) NOT EQUAL WCM-WTIME-T(15:2)   00097200
              MOVE MQSET-DATE-STATO-TRAN(15:2) TO WRK-MIN-511           00097300
              MOVE WCM-WTIME-T(15:2) TO WRK-MIN-105                     00097400
              COMPUTE WRK-MIN-DIFF = WRK-MIN-105 - WRK-MIN-511          00097500
              IF WRK-MIN-DIFF GREATER 3                                 00097600
                 display 'min: passo per maggiore 3 minuti'             00097700
                 PERFORM IMPOSTA-STATO-ATTIVO                           00097800
                    THRU IMPOSTA-STATO-ATTIVO-END                       00097900
              END-IF                                                    00098000
              GO TO VERIFICA-SE-START-MAN-END.                          00098100
           .                                                            00098200
       VERIFICA-SE-START-MAN-END.                                       00098300
           EXIT.                                                        00098400
       IMPOSTA-STATO-ATTIVO.                                            00098500
           DISPLAY 'IMPOSTA-STATO-ATTIVO'.                              00098600
                                                                        00098700
      *--- AGGIORNO LA mqset cON LO STATO AD ATTIVO, E IL TIMESTAMP DI  00098800
      *--- ATTIVAZIONE, MENTRE tot errori  RIMANE QUELLA DELL'ESTRAZIONE00098900
                                                                        00099000
           MOVE 'A'          TO MQSET-STATO-TRAN                        00099100
           MOVE WK-NUM-ERR   TO MQSET-TOT-ERR                           00099200
                                                                        00099300
           PERFORM AGGIORNA-STATO                                       00099400
              THRU AGGIORNA-STATO-END                                   00099500
                                                                        00099600
           MOVE 'SI'                TO AUTOSTART                        00099700
           .                                                            00099800
       IMPOSTA-STATO-ATTIVO-END.                                        00099900
           EXIT.                                                        00100000
       VALORIZZA-LOG.                                                   00100100
           DISPLAY 'VALORIZZA-LOG'.                                     00100200
           INITIALIZE DCLFXTMQLOG                                       00100300
           MOVE WRK-TRANSID TO MQLOG-TRANSID                            00100400
           MOVE MQSET-CANALE  TO MQLOG-APPLICAZ (1:6)                   00100500
           MOVE '- MQ'       TO MQLOG-APPLICAZ (7:4).                   00100600
           MOVE WK-ERROR TO MQLOG-ZAREA.                                00100700
       VALORIZZA-LOG-END.                                               00100800
           EXIT.                                                        00100900
       SCRIVI-LOG.                                                      00101000
           DISPLAY 'SCRIVI-LOG'.                                        00101100
           display 'eseguo insert2 '                                    00101200
           EXEC SQL                                                     00101300
             INSERT INTO FXTMQLOG                                       00101400
                   (MQLOG_WTIME                                         00101500
                   ,MQLOG_TRANSID                                       00101600
                   ,MQLOG_APPLICAZ                                      00101700
                   ,MQLOG_STATO                                         00101800
                   ,MQLOG_ZAREA)                                        00101900
               VALUES                                                   00102000
                  (CURRENT TIMESTAMP                                    00102100
                  ,:MQLOG-TRANSID                                       00102200
                  ,:MQLOG-APPLICAZ                                      00102300
                  ,:MQLOG-STATO                                         00102400
                  ,:MQLOG-ZAREA)                                        00102500
           END-EXEC                                                     00102600
                                                                        00102700
           display 'sqlcode  INSERT-BASE-TABLE :' SQLCODE               00102800
           EVALUATE SQLCODE                                             00102900
             WHEN 0         CONTINUE                                    00103000
                                                                        00103100
             WHEN OTHER     MOVE 'INSERT FXTMQLOG '   TO                00103200
                              DB2-ERROR-MESSAGE                         00103300
           DISPLAY 'SQLCODE : ' SQLCODE                                 00103400
           DISPLAY 'SQLCA   : ' SQLCA                                   00103500
           END-EVALUATE                                                 00103600
           .                                                            00103700
       SCRIVI-LOG-END.                                                  00103800
           EXIT.                                                        00103900
                                                                        00104000
       CONTROLLA-CUTOFF.                                                00104100
                                                                        00104200
           MOVE ZEROES                   TO WRK-TCLOSE                  00104300
           INITIALIZE                       DCLFXAXCOFF                 00104400
                                                                        00104500
      *-- IMPOSTA LE CHIAVI PER ACCESSO A TABELLA FXAXCOFF              00104600
           MOVE WK-CIST                  TO XCOFF-CIST                  00104700
           MOVE 'AMQ'                    TO XCOFF-FASE                  00104800
                                                                        00104900
           EXEC SQL INCLUDE FXS91904    END-EXEC                        00105000
                                                                        00105100
           IF W-SQLCODE EQUAL ZERO                                      00105200
              MOVE XCOFF-ORAFINE         TO WRK-TCLOSE                  00105300
              IF XCOFF-FSAB EQUAL 'N'                                   00105400
                 MOVE 'S'                TO WRK-BLOCCA-SAB              00105500
              END-IF                                                    00105600
              IF XCOFF-FDOM EQUAL 'N'                                   00105700
                 MOVE 'S'                TO WRK-BLOCCA-DOM              00105800
              END-IF                                                    00105900
           ELSE                                                         00106000
              MOVE 'SELECT FXAXCOFF '   TO                              00106100
                              DB2-ERROR-MESSAGE                         00106200
                                                                        00106300
                     PERFORM DB2-ERROR THRU END-DB2-ERROR               00106400
           END-IF                                                       00106500
      *--- CONFRONTO I DUE ORARI : WRK-TCLOSEX E WRK-ORAMIN             00106600
           MOVE WCM-WTIME-T(12:2) TO WRK-ORA OF WRK-ORAMIN.             00106700
           MOVE WCM-WTIME-T(15:2) TO WRK-MIN OF WRK-ORAMIN.             00106800
           IF WRK-ORAMIN GREATER WRK-TCLOSEX                            00106900
              PERFORM 80-FINE-TRAN                                      00107000
                 THRU 80-FINE-TRAN-END                                  00107100
           END-IF                                                       00107200
           .                                                            00107300
       CONTROLLA-CUTOFF-END.                                            00107400
           EXIT.                                                        00107500
                                                                        00107600
       CONTROLLA-SAB-DOM.                                               00107700
BP6013        EXEC CICS ASKTIME                                         00107800
BP6013                  ABSTIME(TIME-SYS)                               00107900
BP6013        END-EXEC                                                  00108000
BP6013                                                                  00108100
BP6013        EXEC CICS FORMATTIME                                      00108200
BP6013                  ABSTIME(TIME-SYS)                               00108300
BP6013                  DAYOFWEEK(DAY-SYS)                              00108400
BP6013        END-EXEC                                                  00108500
BP6013                                                                  00108600
BP6013*--- DAY-SYS = 0 --> DOMENICA                                     00108700
BP6013*--- DAY-SYS = 6 --> SABATO                                       00108800
BP6013     IF (DAY-SYS EQUAL 6 AND                                      00108900
               WRK-BLOCCA-SAB  = 'S' ) OR                               00109000
              (DAY-SYS EQUAL 0 AND                                      00109100
               WRK-BLOCCA-DOM  = 'S' )                                  00109200
              PERFORM 80-FINE-TRAN                                      00109300
                 THRU 80-FINE-TRAN-END                                  00109400
           END-IF                                                       00109500
           .                                                            00109600
       CONTROLLA-SAB-DOM-END.                                           00109700
           EXIT.                                                        00109800
                                                                        00109900
       CONVERTI.                                                        00110000
      *     converto ascii in ebcdic                                    00110010
      *    move spaces      to   OUTput-ebcdic.                         00110100
      *    move spaces      to   ascii-INPUT.                           00110200
      *    move h2-table-elem TO ascii-INPUT.                           00110300
      *                                                                 00110400
      *    move function                                                00110600
      *         display-of                                              00110700
      *         (   function national-of                                00110800
      *               (ascii-INPUT ascii-ccsid),                        00110900
      *             ebcdic-ccsid                                        00111000
      *         )                                                       00111100
      *      to OUTput-ebcdic.                                          00111200
ottcon*    move spaces TO OUTput-ebcdic.                                00111201
           move zeroes to conv-lenght.                                  00111203
ottcon*    move h2-table-elem TO OUTput-ebcdic.                         00111204
           move h2-pathl-dat to conv-lenght.                            00111205
ottcon*    call EZACIC15 using OUTput-ebcdic conv-lenght.               00111210
ottcon     call EZACIC15 using h2-table-elem conv-lenght.               00111220
       CONVERTI-END.                                                    00111300
           EXIT.                                                        00111400
       CARICA-MSG.                                                      00111500
           DISPLAY 'CARICA-MSG'                                         00111600
           if h2-table-nelem = 1                                        00111610
               move SPACES to WRK-KEY-EBM                               00111700
               move zeroes to ind-car                                   00111701
               move zeroes to ind-doc                                   00111710
               move spaces to ELEM-MSG                                  00111800
               COMPUTE ind-car = h2-pathl-dat - 24                      00111900
ottcon*        MOVE OUTPUT-EBCDIC (25:ind-car)                          00112000
ottcon         MOVE h2-table-elem (25:ind-car)                          00112010
                                  TO ELEM-MSG  (1:ind-car)              00112100
               move ind-car to ind-doc                                  00112110
ottcon*        MOVE OUTPUT-EBCDIC (1:24) TO WRK-KEY-EBM                 00112120
ottcon         MOVE h2-table-elem (1:24) TO WRK-KEY-EBM                 00112130
           else                                                         00112200
             if h2-table-nelem = 2                                      00112300
               move zeroes to ind-car2                                  00112400
               move h2-pathl-dat to ind-car2                            00112500
ottcon*        MOVE OUTPUT-EBCDIC TO ELEM-MSG ((ind-car + 1):ind-car2)  00112600
ottcon         MOVE h2-table-elem TO ELEM-MSG ((ind-car + 1):ind-car2)  00112601
               compute ind-doc = ind-car + ind-car2                     00112610
             else                                                       00112700
               PERFORM ERRORE-DIMENSIONE THRU                           00112800
                       ERRORE-DIMENSIONE-END                            00112900
             end-if                                                     00113000
           end-if.                                                      00113100
           DISPLAY 'IND-CAR:' IND-CAR                                   00113110
           DISPLAY 'IND-CAR2:' IND-CAR2                                 00113111
           DISPLAY 'IND-DOC :' IND-DOC                                  00113112
           DISPLAY 'ELEM-MSG:' ELEM-MSG(1:IND-DOC).                     00113120
       END-CARICA-MSG.                                                  00113200
           EXIT.                                                        00113300
       ERRORE-DIMENSIONE.                                               00113400
           DISPLAY 'ERRORE-DIMENSIONE'                                  00113410
              INITIALIZE     WK-ERROR                                   00113500
              MOVE 'CARICA.T'            TO WK-ERROR-CODE               00113600
              MOVE 'MESSAGGIO SU PIU  DI 2 RIGHE'                       00113700
                                         TO WK-ERROR-DESC (1:28)        00113800
              MOVE 'KEY EBM : '                                         00113810
                                         TO WK-ERROR-DESC (29:10)       00113820
              MOVE WRK-KEY-EBM                                          00113830
                                         TO WK-ERROR-DESC (39:24)       00113840
              PERFORM VALORIZZA-LOG THRU VALORIZZA-LOG-END              00113900
      *------ ANNULLA LE MODIFICHE AL DB IN CASO DI ERRORE              00114000
              EXEC CICS SYNCPOINT ROLLBACK END-EXEC                     00114100
                                                                        00114200
      *------ SCRIVE LA TABELLA DI LOG (FXTMQLOG)                       00114300
              PERFORM SCRIVI-LOG                                        00114400
                 THRU SCRIVI-LOG-END                                    00114500
                                                                        00114600
              IF SQLCODE NOT = ZEROES                                   00114700
                 PERFORM 80-FINE-TRAN                                   00114800
                    THRU 80-FINE-TRAN-END                               00114900
              ELSE                                                      00115000
      *------ CONFERMA LA SCRITTURA DEL LOG                             00115100
              EXEC CICS SYNCPOINT END-EXEC                              00115200
                                                                        00115300
                 PERFORM 80-FINE-TRAN                                   00115400
                    THRU 80-FINE-TRAN-END                               00115500
              END-IF.                                                   00115600
       ERRORE-DIMENSIONE-END.                                           00115700
           EXIT.                                                        00115800
       ESEGUI-VALIDATION.                                               00115900
           DISPLAY 'ESEGUI-VALIDATION'.                                 00115901
           INITIALIZE h2-xmldoc  h2-rc h2-resp h2-msg-err               00115910
           move ELEM-MSG to h2-xmldoc                                   00115911
           call FXBXMLVA using dfheiblk dfhcommarea                     00115912
              h2-xmldoc h2-template h2-rc h2-resp h2-msg-err.           00115920
                                                                        00115930
           display 'h2-rc      OF FXBXMLVA : ' h2-rc.                   00115940
           display 'h2-resp    OF FXBXMLVA : ' h2-resp.                 00115941
           display 'h2-msg-err of FXBXMLVA : ' h2-msg-err.              00115942
           if h2-rc not = zeroes                                        00115943
              perform invia-email thru invia-email                      00115944
           end-if                                                       00115945
           if h2-resp not = zeroes                                      00115946
              perform invia-email thru invia-email                      00115947
           DISPLAY 'ESEGUI-VALIDATION-END'.                             00115950
       ESEGUI-VALIDATION-END.                                           00116000
           EXIT.                                                        00116100
       invia-email.                                                     00116200
           call FXBMAIL  using dfheiblk dfhcommarea                     00116201
                               h2-oggetto h2-descrizione                00116202
                               h2-email.                                00116203
       invia-email-END.                                                 00116210
           EXIT.                                                        00116300
