       ID DIVISION.                                                     00000010
      *---------------------------------------------------------------* 00000020
      *----------------------   ENGINEERING  -------------------------* 00000030
      *---------------------------------------------------------------* 00000040
      * IL SEGUENTE PROGRAMMA VIENE ATTIVATO CHIAMATO DA WEB SUPPORT  * 00000050
      *---------------------------------------------------------------* 00000060
      *------------------------   RCTP000   --------------------------* 00000070
      *---------------------------------------------------------------* 00000080
      *----  RICEVE IN QUERY STRING LA USERID ED IL TOKEN E CREA  ----* 00000090
      *----  LA CODA USER RECUPERANDO OPPORTUNAMENTE LE INFORMAZ  ----* 00000091
      *----  IONI NECESSARIE                                      ----* 00000092
      *----  VERIFICA LA VALIDITA' DELL'ATTIVAZIONE DELL'APPLICA  ----* 00000093
      *----  ZIONE ED IN ASSENZA DI ERRORI ATTIVA IN XCTL IL      ----* 00000094
      *----  MENU' GENERALE (RCTP001)                             ----* 00000095
      *---------------------------------------------------------------* 00000096
      *--!!  CAPS IMPOSTATO AD OFF PER ESIGENZE DI SINTASSI HTML  !!--* 00000097
      *--!!!!!!!!!!!!!!!!!!!!! NON MODIFICARE !!!!!!!!!!!!!!!!!!!!!!!!* 00000098
      *---------------------------------------------------------------* 00000099
       PROGRAM-ID. RCTP000.                                             00000100
       ENVIRONMENT DIVISION.                                            00000101
       CONFIGURATION SECTION.                                           00000102
       SPECIAL-NAMES.                                                   00000103
           DECIMAL-POINT IS COMMA.                                      00000104
       DATA DIVISION.                                                   00000110
       WORKING-STORAGE SECTION.                                         00000200
      *---------------------------------------------------------------* 00002300
      * COMODI DI ELABORAZIONE                                          00003200
      *---------------------------------------------------------------* 00003300
       01  RCTP000-DD-NUM       PIC 9(02)                     VALUE 0.  00003301
       01  RCTP000-MM-NUM       PIC 9(02)                     VALUE 0.  00003302
       01  RCTP000-AAAA-NUM     PIC 9(04)                     VALUE 0.  00003303
       01  RCTP000-RISULTATO    PIC 9(05)                     VALUE 0.  00003304
       01  RCTP000-RESTO        PIC 9(05)                     VALUE 0.  00003305
                                                                        00003310
      *---------------------------------------------------------------* 00003400
      * COPY CONTROLLO SICUREZZA                                        00003410
      *---------------------------------------------------------------* 00003420
           COPY RCCYS000.                                               00003500
      *---------------------------------------------------------------* 00003501
      * AREA DI I/O PER CHIAMATA ROUTINE MSTPRACF                       00003502
      *---------------------------------------------------------------* 00003503
      *    COPY MSCPRACF.                                               00003504
           COPY WVCPRACF.                                               00003505
                                                                        00003506
      ***************************************************************** 00003507
      ** AREA PER CHIAMATA RCBTR05 RICERCA DATE IN  RCTBRSTA         ** 00003508
      ***************************************************************** 00003509
           COPY RCCYR05.                                                00003510
      *---------------------------------------------------------------* 00003600
      * COPY INCLUSIONE TABELLE DB2                                     00003700
      *---------------------------------------------------------------* 00003800
           EXEC SQL INCLUDE SQLCA                                       00004100
           END-EXEC.                                                    00004200
                                                                        00004201
           EXEC SQL INCLUDE RCCYRSTA                                    00004700
           END-EXEC.                                                    00004800
      *---------------------------------------------------------------* 00007020
      * AREA DI I/O PER CHIAMATA ROUTINE ACCESSO TGTBTG01               00007030
      *---------------------------------------------------------------* 00007040
       01  RCTP000-COTRTG01     PIC X(08)             VALUE 'COTRTG01'. 00007050
            COPY COCRTG01.                                              00007060
      *---------------------------------------------------------------* 00007101
      *--- TEMPLATE DELLA MAPPA GENERALIZZATA DI ERRORE           ----* 00007102
      *---------------------------------------------------------------* 00007103
       01  TOKEN                 PIC   X(16)          VALUE SPACES.     00007106
       01  CHARSET               PIC   X(40)          VALUE             00007107
           'ISO-8859-1                              '.                  00007108
       01  HOSTCODEPAGE          PIC    X(08)         VALUE '037'.      00007109
      *---------------------------------------------------------------* 00007110
      * COPY VALORIZZAZIONE HEADER DI MAPPA                             00007111
      *---------------------------------------------------------------* 00007112
           COPY RCCYHEAD.                                               00007113
      *---------------------------------------------------------------* 00007114
      * COPY VALORIZZAZIONE FOOTER DI MAPPA                             00007115
      *---------------------------------------------------------------* 00007116
           COPY RCCYFOOT.                                               00007117
      ***************************************************************** 00007200
       PROCEDURE DIVISION.                                              00019700
                                                                        00019820
           MOVE 'RCTP000'                  TO RCCYS000-PGM.             00019821
                                                                        00019822
           PERFORM ESTRAI-QUERYSTRING                                   00019838
              THRU ESTRAI-QUERYSTRING-EX.                               00019840
                                                                        00019850
      *    PERFORM LEGGI-CODE                                           00020101
      *       THRU LEGGI-CODE-EX.                                       00020102
                                                                        00020103
           PERFORM VERIFICA-ATTIVAZIONE                                 00020110
              THRU VERIFICA-ATTIVAZIONE-EX.                             00020120
                                                                        00020130
           PERFORM CANCELLA-CODE                                        00020140
              THRU CANCELLA-CODE-EX.                                    00020141
                                                                        00020142
           PERFORM VALORIZZA-CODE                                       00020143
              THRU VALORIZZA-CODE-EX                                    00020144
                                                                        00020145
           PERFORM XCTL-MENU                                            00020147
              THRU XCTL-MENU-EX                                         00020148
                                                                        00020170
           PERFORM FINE.                                                00023800
                                                                        00023900
       ESTRAI-QUERYSTRING.                                              00023912
           EXEC CICS WEB EXTRACT                                        00023920
                         QUERYSTRING(RCCYS000-QUERYSTRING)              00023930
                         QUERYSTRLEN(RCCYS000-QUERYSTRING-L)            00023940
                         NOHANDLE                                       00023950
           END-EXEC.                                                    00023960
                                                                        00023961
           UNSTRING RCCYS000-QUERYSTRING  DELIMITED BY '?' OR ' '       00023970
               INTO RCCYS000-USERID                                     00023980
                    RCCYS000-TOKEN                                      00023990
           END-UNSTRING.                                                00023994
           INSPECT RCCYS000-USERID CONVERTING                           00023995
                   "abcdefghijklmnopqrstuvwxyz"                         00023997
                TO "ABCDEFGHIJKLMNOPQRSTUVWXYZ".                        00023998
           INSPECT RCCYS000-TOKEN  CONVERTING                           00023999
                   "abcdefghijklmnopqrstuvwxyz"                         00024000
                TO "ABCDEFGHIJKLMNOPQRSTUVWXYZ".                        00024001
           INSPECT RCCYS000-USERID REPLACING                            00024002
               ALL LOW-VALUE BY SPACES.                                 00024003
           INSPECT RCCYS000-TOKEN  REPLACING                            00024004
               ALL LOW-VALUE BY SPACES.                                 00024005
                                                                        00024006
           IF RCCYS000-USERID = SPACES OR RCCYS000-TOKEN = SPACES       00024011
              MOVE    1                        TO RCCYS000-ERR-ACT      00024012
              MOVE    RCCYS000-PGM             TO RCCYM000-ERR-PGM      00024013
              MOVE    ALL LOW-VALUES           TO RCCYM000-ERR-CODEX    00024014
              MOVE    SPACES                   TO RCCYM000-ERR-TRATTINO 00024015
              MOVE    'SESSIONE NON RILEVATA. EFFETTUARE LOG-IN'        00024016
                                               TO RCCYM000-ERR-MSG      00024017
              PERFORM SEND-ERRORE                                       00024018
                 THRU SEND-ERRORE-EX                                    00024019
           END-IF.                                                      00024021
       ESTRAI-QUERYSTRING-EX.                                           00024026
           EXIT.                                                        00024027
                                                                        00024028
       LEGGI-CODE.                                                      00024029
      *----- LETTURA CODA TOKEN                                         00024030
           INITIALIZE                       RCCYS000-NOME-TS-TOK.       00024031
           MOVE RCCYS000-TOKEN           TO RCCYS000-NOME-TS-TOK-TOKEN. 00024032
           MOVE 1                        TO RCCYS000-ITEM.              00024033
           EXEC CICS READQ  TS  QNAME  (RCCYS000-NOME-TS-TOK)           00024034
                                INTO   (RCCYS000-TS-TOK)                00024035
                                LENGTH (LENGTH OF RCCYS000-TS-TOK)      00024036
                                ITEM   (RCCYS000-ITEM)                  00024037
                                NOHANDLE                                00024038
                                RESP   (RCCYS000-RESP)                  00024039
           END-EXEC.                                                    00024040
           IF RCCYS000-RESP NOT EQUAL DFHRESP(NORMAL) AND               00024041
              RCCYS000-RESP NOT EQUAL DFHRESP(QIDERR)                   00024042
              MOVE    2                        TO RCCYS000-ERR-ACT      00024043
              MOVE    RCCYS000-PGM             TO RCCYM000-ERR-PGM      00024044
              MOVE    RCCYS000-RESP            TO RCCYM000-ERR-CODEX    00024045
              MOVE    'ERRORE LETTURA CODA TOKEN'                       00024046
                                               TO RCCYM000-ERR-MSG      00024047
              PERFORM SEND-ERRORE                                       00024048
                 THRU SEND-ERRORE-EX                                    00024049
           END-IF.                                                      00024050
      *--- LETTURA CODA USER                                            00024051
           INITIALIZE                       RCCYS000-NOME-TS-UID.       00024052
           MOVE RCCYS000-TS-TOK-USERID   TO RCCYS000-NOME-TS-UID-USERID.00024053
           MOVE '000'                    TO RCCYS000-NOME-TS-UID-PGM.   00024060
           MOVE '1'                      TO RCCYS000-NOME-TS-UID-PROGR. 00024070
           MOVE 1                        TO RCCYS000-ITEM.              00024080
           EXEC CICS READQ  TS  QNAME  (RCCYS000-NOME-TS-UID)           00024090
                                INTO   (RCCYS000-TS-UID)                00024091
                                LENGTH (LENGTH OF RCCYS000-TS-UID)      00024092
                                ITEM   (RCCYS000-ITEM)                  00024093
                                NOHANDLE                                00024094
                                RESP   (RCCYS000-RESP)                  00024095
           END-EXEC.                                                    00024096
           IF RCCYS000-RESP NOT EQUAL DFHRESP(NORMAL) AND               00024097
              RCCYS000-RESP NOT EQUAL DFHRESP(QIDERR)                   00024098
              MOVE    2                        TO RCCYS000-ERR-ACT      00024099
              MOVE    RCCYS000-PGM             TO RCCYM000-ERR-PGM      00024100
              MOVE    RCCYS000-RESP            TO RCCYM000-ERR-CODEX    00024101
              MOVE    'ERRORE LETTURA CODA USER '                       00024102
                                               TO RCCYM000-ERR-MSG      00024103
              PERFORM SEND-ERRORE                                       00024104
                 THRU SEND-ERRORE-EX                                    00024105
           END-IF.                                                      00024106
           IF RCCYS000-RESP = DFHRESP(QIDERR)                           00024107
              MOVE    1                        TO RCCYS000-ERR-ACT      00024108
              MOVE    RCCYS000-PGM             TO RCCYM000-ERR-PGM      00024109
              MOVE    ALL LOW-VALUES           TO RCCYM000-ERR-CODEX    00024110
              MOVE    SPACES                   TO RCCYM000-ERR-TRATTINO 00024111
      *       MOVE    RCCYS000-RESP            TO RCCYM000-ERR-CODEX    00024112
              MOVE    'SESSIONE NON RILEVATA. EFFETTUARE LOG-IN'        00024113
                                               TO RCCYM000-ERR-MSG      00024114
              PERFORM SEND-ERRORE                                       00024115
                 THRU SEND-ERRORE-EX                                    00024116
           END-IF.                                                      00024120
      *----- VERIFICA CONGRUENZA                                        00024126
           IF RCCYS000-TS-UID-TOKEN NOT = RCCYS000-TOKEN                00024127
              MOVE    1                        TO RCCYS000-ERR-ACT      00024128
              MOVE    RCCYS000-PGM             TO RCCYM000-ERR-PGM      00024129
              MOVE    ALL LOW-VALUES           TO RCCYM000-ERR-CODEX    00024130
              MOVE    SPACES                   TO RCCYM000-ERR-TRATTINO 00024131
      *       MOVE    RCCYS000-RESP            TO RCCYM000-ERR-CODEX    00024132
              MOVE    'UTENTE GIA'' IN SESSIONE. EFFETTUARE LOG-OFF'    00024133
                                               TO RCCYM000-ERR-MSG      00024134
              PERFORM SEND-ERRORE                                       00024135
                 THRU SEND-ERRORE-EX                                    00024136
           END-IF.                                                      00024137
       LEGGI-CODE-EX.                                                   00024138
           EXIT.                                                        00024139
                                                                        00024140
       VERIFICA-ATTIVAZIONE.                                            00024141
           MOVE RCCYS000-USERID              TO WVRACF-USERID           00024142
           MOVE RCCYS000-TOKEN               TO WVRACF-TOKEN            00024143
                                                                        00024144
*EHM       IF RCCYS000-USERID = 'LEONARDO' AND                          00024146
*EHM          RCCYS000-TOKEN  = '543210987654321'                       00024147
*EHM          CONTINUE                                                  00024148
*EHM       ELSE                                                         00024149
                                                                        00024151
           EXEC CICS LINK PROGRAM (RCCYS000-ATTIVAZIONE)                00024152
                          COMMAREA(WVRACF-AREA)                         00024153
                          LENGTH  (LENGTH OF WVRACF-AREA)               00024160
           END-EXEC                                                     00024170
                                                                        00024180
           IF WVRACF-ESITO NOT =  0                                     00024190
              MOVE    RCCYS000-PGM           TO RCCYM000-ERR-PGM        00024191
              MOVE    WVRACF-ESITO         TO RCCYM000-ERR-CODEX        00024192
              MOVE    WVRACF-DESC-ESITO    TO RCCYM000-ERR-MSG          00024193
              MOVE    1                      TO RCCYS000-ERR-ACT        00024194
              PERFORM SEND-ERRORE                                       00024197
                 THRU SEND-ERRORE-EX                                    00024198
*EHM       END-IF                                                       00024199
           END-IF.                                                      00024200
      *--- VALORIZZO IL NOME CODE DI TS PER LA SICUREZZA                00024201
           MOVE RCCYS000-USERID     TO    RCCYS000-NOME-TS-UID-USERID.  00024202
           MOVE '000'               TO    RCCYS000-NOME-TS-UID-PGM.     00024203
           MOVE '1'                 TO    RCCYS000-NOME-TS-UID-PROGR.   00024204
                                                                        00024205
           MOVE RCCYS000-TOKEN      TO    RCCYS000-NOME-TS-TOK-TOKEN.   00024206
                                                                        00024207
       VERIFICA-ATTIVAZIONE-EX.                                         00024210
           EXIT.                                                        00024300
                                                                        00024400
       OTTIENI-LINK.                                                    00024410
           INITIALIZE                        WVHOME-AREA.               00024420
           MOVE RCCYS000-USERID           TO WVHOME-USERID.             00024421
           MOVE RCCYS000-TOKEN            TO WVHOME-TOKEN.              00024422
                                                                        00024423
           EXEC CICS LINK PROGRAM (RCCYS000-LINK)                       00024424
                          COMMAREA(WVHOME-AREA)                         00024425
                          LENGTH  (LENGTH OF WVHOME-AREA)               00024426
           END-EXEC.                                                    00024427
                                                                        00024428
           MOVE WVHOME-LINK                TO RCCYM000-M000ACT1-URL.    00024440
       OTTIENI-LINK-EX.                                                 00024441
           EXIT.                                                        00024442
                                                                        00024443
       CANCELLA-CODE.                                                   00024444
               EXEC CICS DELETEQ TS  QNAME(RCCYS000-NOME-TS-UID)        00024445
                                     NOHANDLE                           00024446
               END-EXEC.                                                00024450
               EXEC CICS DELETEQ TS  QNAME(RCCYS000-NOME-TS-TOK)        00024460
                                     NOHANDLE                           00024461
               END-EXEC.                                                00024462
       CANCELLA-CODE-EX.                                                00024470
           EXIT.                                                        00024480
                                                                        00024490
       VALORIZZA-CODE.                                                  00024500
           MOVE    WVRACF-USERID           TO RCCYS000-TS-UID-USER      00024506
                                                RCCYS000-TS-TOK-USERID  00024507
           MOVE    WVRACF-TOKEN            TO RCCYS000-TS-UID-TOKEN     00024508
           MOVE    WVRACF-PROFILO          TO RCCYS000-TS-UID-PROFILO   00024510
           MOVE    WVRACF-LIV-USERID    TO RCCYS000-TS-UID-LIV-USERID   00024520
*EHM       IF  WVRACF-PROFILO = 'SCOADMIN'          OR                  00024521
*EHM          (RCCYS000-USERID  = 'LEONARDO'         AND                00024522
*EHM           RCCYS000-TOKEN   = '543210987654321')                    00024523
*EHM  *    IF (RCCYS000-USERID = 'LEONARDO'         AND                 00024524
*EHM  *        RCCYS000-TOKEN  = '543210987654321')  OR                 00024525
*EHM  *        RCCYS000-USERID = 'ENG3004 '          OR                 00024526
*EHM  *        RCCYS000-USERID = 'ATM1003 '          OR                 00024527
*EHM  *        RCCYS000-USERID = 'DEM1002 '          OR                 00024528
*EHM  *        RCCYS000-USERID = 'ROB1002 '          OR                 00024529
*EHM***        RCCYS000-USERID = 'LUR5001 '          OR                 00024530
*EHM  *        RCCYS000-USERID = 'FAL1001 '          OR                 00024531
*EHM  *        RCCYS000-USERID = 'GIM1002 '          OR                 00024532
*EHM  *        RCCYS000-USERID = 'MOS1001 '                             00024533
*EHM          MOVE 'Z'                      TO RCCYS000-TS-UID-IDENT    00024534
*EHM          MOVE '0'                      TO RCCYS000-TS-UID-ABILITA  00024535
*EHM          MOVE SPACES                   TO RCCYS000-TS-UID-FILIALE  00024536
*EHM       ELSE                                                         00024537
           PERFORM ACCESSO-TGTBTG01                                     00024538
              THRU ACCESSO-TGTBTG01-EX                                  00024540
*EHM       END-IF.                                                      00024541
           PERFORM RICERCA-DT-SV                                        00024550
              THRU RICERCA-DT-SV-EX.                                    00024560
           PERFORM SCRIVI-CODA-UID                                      00024590
              THRU SCRIVI-CODA-UID-EX.                                  00024591
           PERFORM SCRIVI-CODA-TOK                                      00024592
              THRU SCRIVI-CODA-TOK-EX.                                  00024593
       VALORIZZA-CODE-EX.                                               00024600
           EXIT.                                                        00024700
                                                                        00024800
       ACCESSO-TGTBTG01.                                                00083500
           MOVE '00000'                      TO TG01-CDBAN0.            00083600
           MOVE WVRACF-IDENTIFICATIVO(1:5) TO TG01-CDDIP0.              00083610
           MOVE WVRACF-IDENTIFICATIVO(6:2) TO TG01-CDDPU0.              00083620
           MOVE 'SIC'                        TO TG01-MODORG.            00083700
                                                                        00083710
           EXEC CICS LINK PROGRAM (RCTP000-COTRTG01)                    00083720
                          COMMAREA(TG01-AREA)                           00083730
                          LENGTH  (LENGTH OF TG01-AREA)                 00083740
           END-EXEC.                                                    00083750
                                                                        00083760
           IF TG01-ESITO NOT = 'OK'                                     00084600
              MOVE    2                           TO RCCYS000-ERR-ACT   00084610
              MOVE 'RCTP000'                      TO RCCYM000-ERR-PGM   00084700
              MOVE TG01-SQLCODE                   TO RCCYM000-ERR-CODE  00084800
              MOVE TG01-MESS                      TO RCCYM000-ERR-MSG   00084900
              PERFORM SEND-ERRORE                                       00085000
                 THRU SEND-ERRORE-EX                                    00085100
           END-IF.                                                      00085700
                                                                        00085701
           MOVE TG01-TIPO-UFF               TO RCCYS000-TS-UID-IDENT.   00085702
           MOVE '9'                         TO RCCYS000-TS-UID-ABILITA. 00085705
           IF TG01-TIPO-UFF = 'D'                                       00085706
              MOVE TG01-UO-SUP-ID(1:5)      TO RCCYS000-TS-UID-FILIALE  00085707
              MOVE TG01-CDDIP0              TO RCCYS000-TS-UID-UP       00085708
           ELSE                                                         00085712
              MOVE TG01-CDDIP0              TO RCCYS000-TS-UID-FILIALE  00085713
           END-IF.                                                      00085714
           MOVE TG01-CUAS                   TO RCCYS000-TS-UID-CUAS.    00085715
       ACCESSO-TGTBTG01-EX.                                             00085800
           EXIT.                                                        00085900
                                                                        00086000
       RICERCA-DT-SV.                                                   00086010
                                                                        00086011
           INITIALIZE RCCYR05.                                          00086012
           MOVE '1'       TO R05-TIPO-DATA.                             00086013
           MOVE '4'       TO R05-TRICH.                                 00086014
           MOVE 'RCBTR05' TO R05-PGM-CALL.                              00086015
           CALL R05-PGM-CALL USING RCCYR05.                             00086016
           IF R05-RETURN-CODE = '9' OR                                  00086017
              R05-RETURN-CODE = '1'                                     00086018
              MOVE  2                         TO RCCYS000-ERR-ACT       00086020
              MOVE 'RCTP000'                  TO RCCYM000-ERR-PGM       00086098
              MOVE R05-SQLCODE                TO RCCYM000-ERR-CODE      00086099
              MOVE 'DB2: ERRORE CALL RCTBR05' TO RCCYM000-ERR-MSG       00086100
              PERFORM SEND-ERRORE                                       00086101
                 THRU SEND-ERRORE-EX                                    00086102
           END-IF.                                                      00086103
                                                                        00086104
           IF R05-RETURN-CODE = '0'                                     00086106
              MOVE  R05-DCLRCTBRSTA TO DCLRCTBRSTA                      00086107
              IF RSTA-UTENTE = 'AVVIO'                                  00086108
                 PERFORM CALCOLA-DATA                                   00086109
                    THRU CALCOLA-DATA-EX                                00086110
              END-IF                                                    00086114
              MOVE  RSTA-DTA(1:4)   TO RCCYS000-TS-UID-DT-SV(1:4)       00086115
              MOVE  RSTA-DTA(6:2)   TO RCCYS000-TS-UID-DT-SV(5:2)       00086116
              MOVE  RSTA-DTA(9:2)   TO RCCYS000-TS-UID-DT-SV(7:2)       00086117
           END-IF.                                                      00086119
                                                                        00086120
       RICERCA-DT-SV-EX.                                                00086121
           EXIT.                                                        00086122
                                                                        00086123
       CALCOLA-DATA.                                                    00086124
           MOVE  RSTA-DTA(1:4)         TO RCTP000-AAAA-NUM              00086125
           MOVE  RSTA-DTA(6:2)         TO RCTP000-MM-NUM                00086126
           MOVE  RSTA-DTA(9:2)         TO RCTP000-DD-NUM                00086127
           IF RCTP000-DD-NUM    = 01                                    00086128
              IF RCTP000-MM-NUM = 01                                    00086129
                 MOVE 12                TO RCTP000-MM-NUM               00086130
              ELSE                                                      00086131
                 SUBTRACT 1           FROM RCTP000-MM-NUM               00086132
              END-IF                                                    00086133
              IF RCTP000-MM-NUM = 12                                    00086134
                 SUBTRACT 1           FROM RCTP000-AAAA-NUM             00086135
                 MOVE 31                TO RCTP000-DD-NUM               00086136
              ELSE                                                      00086137
                 IF RCTP000-MM-NUM = 11 OR 04 OR 06 OR 09               00086138
                    MOVE 30             TO RCTP000-DD-NUM               00086139
                 END-IF                                                 00086140
                 IF RCTP000-MM-NUM = 01 OR 03 OR 05 OR 07               00086141
                                        OR 08 OR 10                     00086142
                    MOVE 31             TO RCTP000-DD-NUM               00086143
                 END-IF                                                 00086144
                 IF RCTP000-MM-NUM = 02                                 00086146
                    DIVIDE RCTP000-AAAA-NUM BY 4                        00086147
                                        GIVING RCTP000-RISULTATO        00086148
                                     REMAINDER RCTP000-RESTO            00086149
                    IF RCTP000-RESTO NOT EQUAL ZERO                     00086150
                       MOVE 28    TO RCTP000-DD-NUM                     00086151
                    ELSE                                                00086152
                       MOVE 29    TO RCTP000-DD-NUM                     00086153
                    END-IF                                              00086154
                 END-IF                                                 00086155
              END-IF                                                    00086158
           ELSE                                                         00086159
              SUBTRACT 1              FROM RCTP000-DD-NUM               00086160
           END-IF.                                                      00086161
           MOVE  RCTP000-AAAA-NUM       TO RSTA-DTA(1:4).               00086162
           MOVE  RCTP000-MM-NUM         TO RSTA-DTA(6:2).               00086163
           MOVE  RCTP000-DD-NUM         TO RSTA-DTA(9:2).               00086164
       CALCOLA-DATA-EX.                                                 00086194
           EXIT.                                                        00086195
                                                                        00086196
       SCRIVI-CODA-UID.                                                 00086197
           EXEC CICS WRITEQ TS   QNAME   (RCCYS000-NOME-TS-UID)         00086200
                                 FROM    (RCCYS000-TS-UID)              00086300
                                 LENGTH  (LENGTH OF RCCYS000-TS-UID)    00086400
                                 RESP    (RCCYS000-RESP)                00086410
                                 NOHANDLE                               00086500
           END-EXEC.                                                    00086600
           IF RCCYS000-RESP NOT = 0                                     00086601
              MOVE  2                             TO RCCYS000-ERR-ACT   00086602
              MOVE 'RCTP000'                      TO RCCYM000-ERR-PGM   00086610
              MOVE RCCYS000-RESP                  TO RCCYM000-ERR-CODEX 00086620
              MOVE 'ERRORE SCRITTURA CODA USER  ' TO RCCYM000-ERR-MSG   00086630
              PERFORM SEND-ERRORE                                       00086640
                 THRU SEND-ERRORE-EX                                    00086650
           END-IF.                                                      00086660
       SCRIVI-CODA-UID-EX.                                              00086700
           EXIT.                                                        00086800
                                                                        00086900
       SCRIVI-CODA-TOK.                                                 00086901
           EXEC CICS WRITEQ TS   QNAME   (RCCYS000-NOME-TS-TOK)         00086902
                                 FROM    (RCCYS000-TS-TOK)              00086903
                                 LENGTH  (LENGTH OF RCCYS000-TS-TOK)    00086904
                                 RESP    (RCCYS000-RESP)                00086905
                                 NOHANDLE                               00086906
           END-EXEC.                                                    00086907
           IF RCCYS000-RESP NOT = 0                                     00086908
              MOVE  2                             TO RCCYS000-ERR-ACT   00086909
              MOVE 'RCTP000'                      TO RCCYM000-ERR-PGM   00086910
              MOVE RCCYS000-RESP                  TO RCCYM000-ERR-CODEX 00086911
              MOVE 'ERRORE SCRITTURA CODA TOKEN ' TO RCCYM000-ERR-MSG   00086912
              PERFORM SEND-ERRORE                                       00086913
                 THRU SEND-ERRORE-EX                                    00086914
           END-IF.                                                      00086915
       SCRIVI-CODA-TOK-EX.                                              00086916
           EXIT.                                                        00086917
                                                                        00086918
       SEND-ERRORE.                                                     00086919
           PERFORM VALORIZZA-HEADER                                     00086920
              THRU VALORIZZA-HEADER-EX.                                 00086930
                                                                        00086940
           PERFORM VALORIZZA-FOOTER                                     00086950
              THRU VALORIZZA-FOOTER-EX.                                 00086960
                                                                        00086970
           PERFORM VALORIZZA-BODY                                       00086980
              THRU VALORIZZA-BODY-EX.                                   00086990
                                                                        00086991
           PERFORM CREA-DOCUMENTO                                       00086992
              THRU CREA-DOCUMENTO-EX.                                   00086993
                                                                        00086994
           PERFORM SPEDISCI-MAPPA-HTML                                  00086995
              THRU SPEDISCI-MAPPA-HTML-EX.                              00086996
                                                                        00086997
           PERFORM FINE.                                                00086998
                                                                        00086999
       SEND-ERRORE-EX.                                                  00087000
           EXIT.                                                        00087100
                                                                        00087200
       VALORIZZA-BODY.                                                  00087210
           MOVE '- ERRORE'                    TO RCCYHEAD-TITOLO.       00087220
           MOVE ALL LOW-VALUE                 TO RCCYFOOT-USERID.       00087230
           MOVE ALL LOW-VALUE                 TO RCCYHEAD-JSMNUFLOAT.   00087240
      *    MOVE ALL LOW-VALUE                 TO RCCYHEAD-INITTABDATI.  00087241
           MOVE ALL LOW-VALUE                 TO RCCYFOOT-ERRORE.       00087250
                                                                        00087253
           MOVE '&RCIM016='                   TO RCCYM000-RCIM016.      00087258
           MOVE RCCYHEAD-PATH                 TO RCCYM000-RCIM016-URL.  00087259
           MOVE 'LOADIMG/RCIM016'             TO RCCYM000-RCIM016-VAR.  00087260
                                                                        00087261
           IF RCCYS000-ERR-ACT = 0                                      00087267
              MOVE 'javascript:history.back(-1);'                       00087268
                                              TO RCCYM000-M000ACT1-URL  00087269
              MOVE 'Torna Indietro'           TO RCCYM000-M000ACT1-TXT  00087270
              MOVE ALL LOW-VALUE              TO RCCYM000-M000ACT2      00087271
           END-IF.                                                      00087272
           IF RCCYS000-ERR-ACT = 1                                      00087273
              MOVE RCCYHEAD-PATH              TO RCCYM000-M000ACT1-PATH 00087275
              MOVE 'RCTP999/RCMP999'          TO RCCYM000-M000ACT1-VAR  00087276
              IF RCCYS000-TOKEN NOT = SPACES                            00087277
                 MOVE '?'                     TO RCCYM000-M000ACT1-PI   00087278
                 MOVE RCCYS000-TOKEN          TO RCCYM000-M000ACT1-QSTR 00087279
              END-IF                                                    00087282
              MOVE 'Riconnettersi'            TO RCCYM000-M000ACT1-TXT  00087283
              MOVE ALL LOW-VALUE              TO RCCYM000-M000ACT2      00087284
           END-IF.                                                      00087285
           IF RCCYS000-ERR-ACT = 2                                      00087286
              MOVE 'javascript:history.back(-1);'                       00087287
                                              TO RCCYM000-M000ACT1-URL  00087288
              MOVE 'Riprova   o '             TO RCCYM000-M000ACT1-TXT  00087289
              MOVE 'javascript:self.close(-1);'                         00087290
                                              TO RCCYM000-M000ACT2-URL  00087291
              MOVE 'Chiudi SRC'               TO RCCYM000-M000ACT2-TXT  00087292
           END-IF.                                                      00087293
                                                                        00087294
           MOVE '&RCMPHEAD='                  TO RCCYM000-RCMPHEAD-VAR. 00087295
           MOVE RCCYHEAD-HEAD                 TO RCCYM000-RCMPHEADER.   00087296
           MOVE '&RCMPFOOT='                  TO RCCYM000-RCMPFOOT-VAR. 00087297
           MOVE RCCYFOOT-FOOT                 TO RCCYM000-RCMPFOOTER.   00087298
                                                                        00087299
       VALORIZZA-BODY-EX.                                               00087300
           EXIT.                                                        00087301
                                                                        00087302
       CREA-DOCUMENTO.                                                  00087303
           EXEC CICS DOCUMENT CREATE                                    00087304
                     DOCTOKEN    (TOKEN)                                00087305
                     TEMPLATE    (RCCYS000-TEMPLATE-ERR)                00087306
                     SYMBOLLIST  (RCCYS000-HTML-SEND-ERR)               00087307
                     LISTLENGTH  (LENGTH OF RCCYS000-HTML-SEND-ERR)     00087308
                     NOHANDLE                                           00087309
           END-EXEC.                                                    00087310
       CREA-DOCUMENTO-EX.                                               00087311
           EXIT.                                                        00087312
                                                                        00087313
       SPEDISCI-MAPPA-HTML.                                             00087314
           EXEC CICS WEB SEND     DOCTOKEN    (TOKEN)                   00087315
                                  CLNTCODEPAGE(CHARSET)                 00087316
                                  NOHANDLE                              00087317
           END-EXEC.                                                    00087318
                                                                        00087319
       SPEDISCI-MAPPA-HTML-EX.                                          00087320
           EXIT.                                                        00087321
                                                                        00087322
       XCTL-MENU.                                                       00087323
           MOVE RCCYS000-TS-UID-USER        TO RCCYS000-USERID.         00087324
           MOVE RCCYS000-TS-UID-TOKEN       TO RCCYS000-TOKEN.          00087330
           EXEC CICS XCTL PROGRAM('RCTP001')                            00087340
                          COMMAREA(RCCYS000-COMMAREA)                   00087350
           END-EXEC.                                                    00087360
       XCTL-MENU-EX.                                                    00087400
           EXIT.                                                        00087500
                                                                        00087600
       FINE.                                                            00090300
           EXEC CICS RETURN   END-EXEC.                                 00090400
           GOBACK.                                                      00090500
                                                                        00090600
      *---------------------------------------------------------------* 00090700
      * COPY DI PROCEDURE PER VALORIZZAZIONE AMBIENTE E HEADER          00090800
      *---------------------------------------------------------------* 00090900
           COPY RCCPHEAD.                                               00091000
      *---------------------------------------------------------------* 00091100
      * COPY DI PROCEDURE PER VALORIZZAZIONE FOOTER                     00091200
      *---------------------------------------------------------------* 00091300
           COPY RCCPFOOT.                                               00091400
