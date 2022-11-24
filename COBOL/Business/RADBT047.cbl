      ******************************************************************00000100
      * NOTE:                                                           00000200
      ******************************************************************00000300
      *                                                                 00000400
      * NAME        : RADBT047                                          00000500
      *                                                                 00000600
      * FUNCTION    : PGM CHE CONTROLLA I PARAMETRI INSERITI            00000700
      *               NELLA RADBRIC E LI AGGIORNA                       00000710
      *                                                                 00000900
      * DESCRIZIONE : INSERISCE L'ESITO DELLE ELABORAZIONI BATCH        00001110
      *                                                                 00001140
      * AUTHOR   : DEMURTAS CRISTIANO RIADATTATO DA VINCENZO ERRIQUENZ  00001200
      *                                                                 00001900
      ******************************************************************00002000
       IDENTIFICATION DIVISION.                                         00002100
       PROGRAM-ID. RADBT047.                                            00002200
       AUTHOR.     ENGINEERING SPA.                                     00002300
      ******************************************************************00002400
       ENVIRONMENT DIVISION.                                            00002500
       CONFIGURATION SECTION.                                           00002600
TEST  *SOURCE-COMPUTER. IBM-3090 WITH DEBUGGING MODE.                   00002700
       SPECIAL-NAMES.                                                   00002800
           DECIMAL-POINT IS COMMA.                                      00002900
      *-----------------------------------------------------------------00003000
       INPUT-OUTPUT SECTION.                                            00003100
       FILE-CONTROL.                                                    00003200
      ******************************************************************00004500
       DATA DIVISION.                                                   00004600
       FILE SECTION.                                                    00004700
      *-----------------------------------------------------------------00006000
       WORKING-STORAGE SECTION.                                         00006100
      *--- COSTANTI E SWITCHES                                          00006200
       01  DAT-ELAB                      PIC X(08).                     00006210
       01  DATA-RICH                     PIC 9(08).                     00006211
                                                                        00006220
       01  WK-COSTANTI-FLAG.                                            00006300
           05 WK-RADBT047                PIC X(08) VALUE 'RADBT047'.    00006400
           05 WK-RADYDBRI                PIC X(08) VALUE 'RADYDBRI'.    00006500
      *--- VARIABILI                                                    00006800
       01  WS-LAVORO.                                                   00006900
           05 WK-SYSIN-DATA              PIC 9(08).                     00007220
           05 WS-PIC08-9                 PIC 9(08).                     00008000
           05 WS-PIC08-X       REDEFINES                                00008100
              WS-PIC08-9                 PIC X(08).                     00008200
           05 WS-TOT-BRIC-LETTI          PIC 9(08) VALUE 0.             00008800
           05 WS-TOT-SCRITTI-I           PIC 9(08).                     00009000
           05 WS-TOT-SCRITTI-D           PIC 9(08).                     00009010
           05  CAMPI-EDIT      OCCURS 20 TIMES.                         00009100
               10 NUM-EDIT               PIC ---.---.---.--9.           00009200
           05 CAMPI-ERRORE.                                             00009300
               10 ERR-PROGRAMMA          PIC X(08).                     00009400
               10 ERR-PUNTO              PIC X(04).                     00009500
               10 ERR-DESCRIZIONE        PIC X(80).                     00009600
               10 ERR-CODICE-X           PIC X(06).                     00009700
               10 ERR-CODICE-Z           PIC -----9.                    00009800
               10 ERR-DATI               PIC X(80).                     00009900
               10 ERR-GRAVE              PIC X(02).                     00010000
                                                                        00011200
      ******************************************************************00011300
      * COPY FILE PARAMETRO PER GESTIONE RICHIESTE DI ELABORAZIONE     *00011400
      *                     DI TIPO INFORMATIVO/DISPOSITIVO            *00011500
      *                                                                *00011600
      * LENGTH 030 BYTES                                               *00011700
      *                                                                *00011800
      ******************************************************************00012091
       01  RADBT047-REC.                                                00012092
           05 T047-DATA-ELAB      PIC 9(8).                             00012093
           05 T047-TIPO-FUNZ      PIC X(3).                             00012094
           05 T047-STATO          PIC X(1).                             00012096
           05 T047-TIPO-RICH      PIC X(1).                             00012097
           05 T047-ESITO-ELAB     PIC X(2).                             00012098
           05 T047-MODULO         PIC X(8).                             00012099
           05 FILLER              PIC X(07).                            00012100
      *--- COPY ROUTINE RADYDBRI                                        00012110
           COPY RADCDBRI.                                               00012200
      *--- COMMAREA GENERALIZZATA ROUTINE                               00012800
       01  AREA-ARCHIVIO.                                               00012900
           03 ARCHIVIO-SW                PIC X(02).                     00013000
           03 ARCHIVIO-TRAC              PIC X(04).                     00013100
           03 ARCHIVIO-FUNZ              PIC X(03).                     00013200
           03 ARCHIVIO-PGM               PIC X(08).                     00013300
           03 ARCHIVIO-DATA              PIC X(08).                     00013400
           03 ARCHIVIO-ORA               PIC X(06).                     00013500
           03 ARCHIVIO-TIPOMOD           PIC X(01).                     00013600
           03 ARCHIVIO-RETCODE           PIC X(06).                     00013700
           03 ARCHIVIO-FILLER            PIC X(71).                     00013800
           03 ARCHIVIO-REC               PIC X(1000).                   00013900
      ******************************************************************00013910
       LINKAGE SECTION.                                                 00013971
       01  LINK-REC.                                                    00013980
           05 LINK-DATA-ELAB      PIC 9(8).                             00013990
           05 LINK-TIPO-FUNZ      PIC X(3).                             00013991
           05 LINK-STATO          PIC X(1).                             00013992
           05 LINK-TIPO-RICH      PIC X(1).                             00013993
           05 LINK-ESITO-ELAB     PIC X(2).                             00013994
           05 LINK-MODULO         PIC X(8).                             00013995
           05 LINK-CHIAMA         PIC X(4).                             00013996
           05 LINK-ESITO          PIC X(2).                             00013997
      ******************************************************************00014000
       PROCEDURE DIVISION USING LINK-REC.                               00014100
TEST  DDECLARATIVES.                                                    00014200
TEST  DCOBOL2-DEBUG SECTION.                                            00014300
TEST  D    USE FOR DEBUGGING ON ALL PROCEDURES.                         00014400
TEST  DCOBOL2-DEBUG-BRIC.                                               00014500
TEST  D    DISPLAY WK-RADBT047 '--> ' DEBUG-ITEM.                       00014600
TEST  DEND DECLARATIVES.                                                00014700
      *-----------------------------------                              00014800
      *                                                                 00014900
      *-----------------------------------                              00015000
           PERFORM C00010-INIZIO                                        00015100
      * ELABORA                                                         00015200
           PERFORM C00100-CTR-AGGIORNA-RADBRIC                          00015310
      * FINE                                                            00015320
           PERFORM C00800-FINE.                                         00017200
      *-----------------------------------                              00017300
      *                                                                 00017400
      *-----------------------------------                              00017500
       C00010-INIZIO.                                                   00017600
           DISPLAY                                                      00017700
           '*======================================================*'   00017800
           DISPLAY                                                      00017900
           '*====        I N I Z I O   P R O G R A M M A       ====*'   00018000
           DISPLAY                                                      00018100
           '*======================================================*'   00018200
           INITIALIZE WS-LAVORO                                         00018300
      * SCHEDA PARAMETRO - DATA OPC                                     00018301
           IF LINK-CHIAMA = 'GD20'                                      00018302
              DISPLAY ' *** RADBT047 CHIAMATO TRAMITE DRSBGD20 *** '    00018303
              DISPLAY ' *** DA FIFLB274 / FIFLB276 / FIFLB279  *** '    00018304
              DISPLAY '-------------'                                   00018305
              DISPLAY 'PARAMETRI DI RICERCA SU RADBRIC PASSATI TRAMITE P00018306
      -               'ROGRAMMA ' LINK-MODULO ' - ROUTINE ' LINK-CHIAMA 00018307
              DISPLAY 'DATA-ELAB  ' LINK-DATA-ELAB                      00018308
              DISPLAY 'TIPO-FUNZ  ' LINK-TIPO-FUNZ                      00018309
              DISPLAY 'STATO      ' LINK-STATO                          00018310
              DISPLAY 'TIPO-RICH  ' LINK-TIPO-RICH                      00018311
              DISPLAY 'ESITO-ELAB ' LINK-ESITO-ELAB                     00018312
              DISPLAY '-------------'                                   00018313
              MOVE LINK-REC    TO RADBT047-REC                          00018315
              MOVE 'OK'        TO LINK-ESITO                            00018316
           ELSE                                                         00018317
              DISPLAY ' *** RADBT047 CHIAMATO DA PROCEDURE SIRADO *** ' 00018318
              DISPLAY ' *** RADOH00G / RADO200G / RADO600G        *** ' 00018319
              ACCEPT RADBT047-REC FROM SYSIN                            00018320
              DISPLAY '-------------'                                   00018321
              DISPLAY 'PARAMETRI DI RICERCA SU RADBRIC PASSATI TRAMITE S00018322
      -               'YSIN DAL PROGRAMMA ' T047-MODULO                 00018323
              DISPLAY 'DATA-ELAB  ' T047-DATA-ELAB                      00018324
              DISPLAY 'TIPO-FUNZ  ' T047-TIPO-FUNZ                      00018325
              DISPLAY 'STATO      ' T047-STATO                          00018326
              DISPLAY 'TIPO-RICH  ' T047-TIPO-RICH                      00018327
              DISPLAY 'ESITO-ELAB ' T047-ESITO-ELAB                     00018328
              DISPLAY '-------------'                                   00018329
           END-IF                                                       00018330
      *                                                                 00018340
           MOVE WK-RADBT047              TO ERR-PROGRAMMA               00018400
           PERFORM C00900-READ-RADYDBRI.                                00018500
      *-----------------------------------                              00018900
      *                                                                 00019000
      *-----------------------------------                              00019100
       C00100-CTR-AGGIORNA-RADBRIC.                                     00019200
      *                                                                 00019210
           EVALUATE BRIC-STATO                                          00019211
           WHEN 'D'                                                     00019212
              CONTINUE                                                  00019213
           WHEN 'A'                                                     00019214
              IF DATA-RICH  = T047-DATA-ELAB                            00019215
H00G          AND (T047-MODULO = 'RADBT013' OR                          00019216
200G               T047-MODULO = 'RADBT036' OR                          00019217
600G               T047-MODULO = 'RADBT080')                            00019218
              AND BRIC-TIPO-FUNZ = T047-TIPO-FUNZ                       00019219
              AND BRIC-TIPO-RICH = T047-TIPO-RICH                       00019220
                 MOVE 'E'         TO BRIC-STATO                         00019221
                 PERFORM C00900-UPDT-RADYDBRI                           00019222
              END-IF                                                    00019223
           WHEN 'E'                                                     00019224
              IF BRIC-ESITO-ELAB = 'EL'                                 00019225
                 IF DATA-RICH  <  T047-DATA-ELAB                        00019226
                 AND BRIC-TIPO-FUNZ = T047-TIPO-FUNZ                    00019227
                 AND BRIC-TIPO-RICH = T047-TIPO-RICH                    00019228
                    PERFORM C00900-UPDT-RADYDBRI                        00019229
                 END-IF                                                 00019230
              END-IF                                                    00019240
           END-EVALUATE.                                                00020410
      *                                                                 00020420
      *-----------------------------------                              00020900
      *                                                                 00021000
      *-----------------------------------                              00021100
       C00800-FINE.                                                     00021200
           PERFORM C90010-STATISTICHE                                   00021400
           PERFORM C99999-END.                                          00021500
      *-----------------------------------                              00021600
      * LETTURA  TABELLA RADBRIC : GESTIONE RICHIESTE                   00021700
      *-----------------------------------                              00021800
       C00900-READ-RADYDBRI.                                            00021900
           INITIALIZE AREA-ARCHIVIO                                     00022000
                      RADCDBRI-REC                                      00022100
           MOVE T047-DATA-ELAB           TO BRIC-DATA-RICH              00022200
           MOVE RADCDBRI-REC             TO ARCHIVIO-REC                00022300
           MOVE '0003'                   TO ARCHIVIO-TRAC               00022400
           MOVE 'RED'                    TO ARCHIVIO-FUNZ               00022500
           CALL WK-RADYDBRI USING AREA-ARCHIVIO END-CALL                00022600
           EVALUATE ARCHIVIO-SW                                         00022700
             WHEN 'SI'                                                  00022800
               ADD 1                     TO WS-TOT-BRIC-LETTI END-ADD   00022900
               MOVE ARCHIVIO-REC         TO RADCDBRI-REC                00023000
               MOVE BRIC-DATA-RICH       TO DATA-RICH                   00023010
      *                                                                 00023011
             WHEN 'NF'                                                  00023100
               CONTINUE                                                 00023200
             WHEN OTHER                                                 00023700
               MOVE '0012'               TO ERR-PUNTO                   00023800
               MOVE 'ERRORE ACCESSO ROUTINE RADYDBRI'                   00023900
                                         TO ERR-DESCRIZIONE             00024000
               MOVE ARCHIVIO-RETCODE     TO ERR-CODICE-X                00024100
               PERFORM C90020-ERRORE-BLOCCANTE                          00024200
           END-EVALUATE.                                                00024300
      *-----------------------------------                              00024400
      * AGGIORNA TABELLA RADBRIC : GESTIONE RICHIESTE                   00024500
      *-----------------------------------                              00024600
       C00900-UPDT-RADYDBRI.                                            00024700
           INITIALIZE AREA-ARCHIVIO                                     00024800
           MOVE T047-TIPO-FUNZ           TO BRIC-TIPO-FUNZ              00025000
      *    MOVE T047-DATA-ELAB           TO BRIC-DATA-RICH              00025100
           MOVE T047-TIPO-RICH           TO BRIC-TIPO-RICH              00025300
           MOVE T047-ESITO-ELAB          TO BRIC-ESITO-ELAB             00025400
           EVALUATE BRIC-ESITO-ELAB                                     00025500
             WHEN 'OK'                                                  00025600
               MOVE 'ELAB. ESEGUITA CORRETTAMENTE'                      00025700
                                         TO BRIC-DESCR-ESITO            00025800
             WHEN 'KO'                                                  00025900
               STRING 'PGM '                                            00026000
                      T047-MODULO                                       00026100
                      ' IN CHIUSURA FORZ.'                              00026200
               DELIMITED BY SIZE     INTO   BRIC-DESCR-ESITO            00026300
             WHEN 'EL'                                                  00026400
               MOVE 'PROCEDURA IN ELABORAZIONE'                         00026500
                                             TO BRIC-DESCR-ESITO        00026600
           END-EVALUATE.                                                00026700
           MOVE RADCDBRI-REC             TO ARCHIVIO-REC                00026800
           MOVE '0001'                   TO ARCHIVIO-TRAC               00026900
           MOVE 'UPD'                    TO ARCHIVIO-FUNZ               00027000
           CALL WK-RADYDBRI USING AREA-ARCHIVIO END-CALL                00027100
           EVALUATE ARCHIVIO-SW                                         00027200
             WHEN 'SI'                                                  00027300
               IF T047-TIPO-RICH = 'I'                                  00027310
                  ADD 1                  TO WS-TOT-SCRITTI-I END-ADD    00027400
               ELSE                                                     00027401
                  ADD 1                  TO WS-TOT-SCRITTI-D END-ADD    00027410
               END-IF                                                   00027420
               MOVE ARCHIVIO-REC         TO RADCDBRI-REC                00027500
               MOVE BRIC-DATA-RICH       TO DATA-RICH                   00027600
      *                                                                 00027700
             WHEN 'NF'                                                  00027800
               MOVE '0010'               TO ERR-PUNTO                   00027900
               MOVE SPACES               TO BRIC-TIPO-RICH              00028000
               MOVE 'DATI ASSENTI PER UPDATE'                           00028100
                                         TO ERR-DESCRIZIONE             00028200
               MOVE ARCHIVIO-RETCODE     TO ERR-CODICE-X                00028300
               PERFORM C90020-ERRORE-BLOCCANTE                          00028400
             WHEN OTHER                                                 00028500
               MOVE '0012'               TO ERR-PUNTO                   00028600
               MOVE 'ERRORE ACCESSO ROUTINE RADYDBRI'                   00028700
                                         TO ERR-DESCRIZIONE             00028800
               MOVE ARCHIVIO-RETCODE     TO ERR-CODICE-X                00028900
               PERFORM C90020-ERRORE-BLOCCANTE                          00029000
           END-EVALUATE.                                                00029100
      *-----------------------------------                              00030800
      *                                                                 00030900
      *-----------------------------------                              00031000
      *-----------------------------------                              00047300
      *                                                                 00047400
      *-----------------------------------                              00047500
       C90010-STATISTICHE.                                              00047600
           MOVE WS-TOT-BRIC-LETTI        TO NUM-EDIT(01)                00047800
           MOVE WS-TOT-SCRITTI-I         TO NUM-EDIT(02)                00048400
           MOVE WS-TOT-SCRITTI-D         TO NUM-EDIT(03)                00048410
           DISPLAY                                                      00048500
           '*======================================================*'   00048600
           DISPLAY                                                      00048700
           '*                S T A T I S T I C H E                 *'   00048800
           DISPLAY                                                      00048900
           '*======================================================*'   00049000
FM0319*    DISPLAY ' TOT. REC. RADBRIC LETTI________: ' NUM-EDIT(01)    00049100
FM0319*    DISPLAY '                                  '                 00049200
           DISPLAY ' RICHIESTE INFORMATIVE AGGIORNATE'                  00050200
           DISPLAY ' (SOLO PER FUNZIONE "EST")......: ' NUM-EDIT(02)    00050210
           DISPLAY '                                  '                 00050300
           DISPLAY ' RICHIESTE DISPOSITIVE AGGIORNATE'                  00050301
           DISPLAY ' (PER FUNZIONE "EST" O "RIE")...: ' NUM-EDIT(03)    00050310
           DISPLAY '                                 '                  00050311
           DISPLAY ' NEL CASO IN CUI ENTRAMBI I CONTATORI SIANO = ZERO' 00050312
           DISPLAY ' SIGNIFICA CHE NON ESISTONO RIHIESTE "EST" O "RIE"' 00050313
           DISPLAY ' ATTIVE O IN ELABORAZIONE'                          00050314
           DISPLAY                                                      00050315
           '*======================================================*'.  00050316
      *                                                                 00050317
       C90020-ERRORE-BLOCCANTE.                                         00050800
           DISPLAY                                                      00050900
           '*======================================================*'   00051000
           DISPLAY                                                      00051100
           '*====                 ERRORE GRAVE                 ====*'   00051200
           DISPLAY                                                      00051300
           '*====----------------------------------------------====*'   00051400
           DISPLAY                                                      00051500
           '*====   PROGRAMMA    : ' ERR-PROGRAMMA                      00051600
           DISPLAY                                                      00051700
           '*====   PUNTO        : ' ERR-PUNTO                          00051800
           DISPLAY                                                      00051900
           '*====   DESCRIZIONE  : ' ERR-DESCRIZIONE                    00052000
           DISPLAY                                                      00052100
           '*====   CODICE-X     : ' ERR-CODICE-X                       00052200
           DISPLAY                                                      00052300
           '*====   CODICE-9     : ' ERR-CODICE-Z                       00052400
           DISPLAY                                                      00052500
           '*====   DATI         : ' ERR-DATI                           00052600
           DISPLAY                                                      00052700
           '*====----------------------------------------------====*'   00052800
           DISPLAY                                                      00052900
           '*====                 ERRORE GRAVE                 ====*'   00053000
           DISPLAY                                                      00053100
           '*======================================================*'   00053200
           MOVE 12                       TO RETURN-CODE                 00053300
           MOVE 'KO'                     TO LINK-ESITO                  00053310
           PERFORM C99999-END.                                          00053400
      *-----------------------------------                              00053500
      *                                                                 00053600
      *-----------------------------------                              00053700
       C99999-END.                                                      00053800
           DISPLAY                                                      00053900
           '*======================================================*'   00054000
           DISPLAY                                                      00054100
           '*====        F I N E       P R O G R A M M A       ====*'   00054200
           DISPLAY                                                      00054300
           '*======================================================*'   00054400
           GOBACK.                                                      00054500
      **********************       END      ****************************00054600
