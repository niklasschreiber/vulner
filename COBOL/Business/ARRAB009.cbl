      ***************************************************************** 00010001
       IDENTIFICATION DIVISION.                                         00020000
      *                                                                 00030001
       PROGRAM-ID.   ARRAB009.                                          00040001
       AUTHOR.                                                          00050000
      ***************************************************************** 00060001
      *                           ARRAB009                            * 00070001
      ***************************************************************** 00080001
      *  PROCEDURA DI LETTURA FILE DI RITORNO DA D.BANK               * 00090001
      *  CON TIPO RECORD '70'                                         * 00091001
      *  PER AGGIORNAMENTO DELLA TABELLA RICHIESTE TRIC               * 00100001
      *  E SCRITTURE DI UN FILE RELATIVO AD EVENTUALI ANOMALIE        * 00110001
      *  RISCONTRATE                                                  * 00120001
      ***************************************************************** 00130000
      * 090101 ===> AGGIUNTA VALORIZZAZIONE PER DATA RISPOSTA ENTE E  * 00131014
      *             FILIALE RICHIEDENTE SU FILE DELLE ANOMALIE        * 00132014
      ***************************************************************** 00133014
      * 250702 ===> AGGIUNTA LA STORICIZZAZIONE DELLA TABELLA         * 00133015
      *             SCTBTSTO NEL CASO CHE ARRIVI UN TIPO RECORD '70'  * 00133016
      *             LA MODIFICE E' STATA APPORTATA PRIMA              * 00133017
      *             DELL' UPDATE SULLA TABELLA SCTBTRIC               * 00133018
      ***************************************************************** 00133019
      *040902 ====> GESTIONE DELLE RINUNCIA CLIENTE                   * 00133020
      *141102 ====> VALORIZZATA IN FILE ANOMALIE LA DTA INVIO ENTE    * 00133021
      *100206 ====> VALORIZZATO IL CAMPO ESITO A 'KO' PER STAMPADB    * 00133022
      *             ANOMALIE                                          * 00133023
      ***************************************************************** 00133030
       ENVIRONMENT DIVISION.                                            00140000
      *                                                                 00150001
       CONFIGURATION SECTION.                                           00160000
      *                                                                 00170001
       SOURCE-COMPUTER. IBM-3090 WITH DEBUGGING MODE.                   00170100
       OBJECT-COMPUTER. HOST.                                           00170200
      *                                                                 00171001
          SPECIAL-NAMES.                                                00180000
              DECIMAL-POINT IS COMMA.                                   00190000
      *                                                                 00200001
       INPUT-OUTPUT SECTION.                                            00210000
      *                                                                 00220001
       FILE-CONTROL.                                                    00240000
      *                                                                 00271000
           SELECT  FILE70   ASSIGN  TO FILE70                           00272001
                 FILE  STATUS  IS  W-STAT01.                            00273000
      *                                                                 00280000
           SELECT  ANOMALIE ASSIGN TO UR-S-ANOMALIE                     00290000
                 FILE  STATUS  IS  W-STATO2.                            00300000
      *                                                                 00310001
       DATA DIVISION.                                                   00320000
      *                                                                 00330001
       FILE SECTION.                                                    00340000
      *                                                                 00350001
       FD  FILE70                                                       00421001
           LABEL RECORD STANDARD                                        00422000
           RECORDING MODE IS F                                          00423000
           BLOCK CONTAINS 0 RECORDS.                                    00424000
       01  K-REC-INP1          PIC X(46).                               00425000
      *                                                                 00426000
       FD  ANOMALIE                                                     00430000
           LABEL RECORD STANDARD                                        00440000
           RECORDING MODE IS F                                          00450000
           BLOCK CONTAINS 0 RECORDS.                                    00460000
       01  K-REC-OUT           PIC X(659).                              00470000
      *                                                                 00480001
       WORKING-STORAGE SECTION.                                         00490000
      *                                                                 00520000
           COPY ARRAC007.                                               00530000
      *                                                                 00531000
           COPY ARRAC029.                                               00532001
      *                                                                 00540000
       01  ACUT64A.                                                     00542000
           COPY ACUT64A.                                                00543000
      *                                                                 00544000
           COPY PPTCUPCC.                                               00550000
      *                                                                 00560000
        COPY DYNACALL.                                                  00570000
      ***************************************************************** 00580001
      *     CAMPI    DI   WORKING   PER    GESTIONE    ABEND          * 00590001
      ***************************************************************** 00600001
      *                                                                 00610000
       77  COMP-CODE                PIC S9(04) COMP VALUE +5555.        00620000
      *                                                                 00630000
       01  W-PROGRAM                PIC X(08)  VALUE SPACES.            00640000
      ***************************************************************** 00650001
      *                                                                 00680000
       01  IND1                     PIC S9(4) COMP.                     00690000
      *                                                                 00700000
       01  W-CONTROLLO              PIC 9 VALUE ZERO.                   00710000
      *                                                                 00720000
       01  W-CONGRUENZA             PIC X(02) VALUE SPACES.             00730000
      *                                                                 00740000
       01  W-FLAG-ELA               PIC X(01).                          00750000
      *                                                                 00760000
       01  R-CODE                   PIC 9(09) VALUE 0.                  00770000
      *                                                                 00780000
       01  CTR-REC-TOT              PIC 9(08) VALUE 0.                  00790000
      *                                                                 00800000
       01  CTR-ANOMALIE             PIC 9(08) VALUE 0.                  00810000
      *                                                                 00820000
       01  W-N-REC-TOT              PIC 9(08) VALUE 0.                  00830000
      *                                                                 00840000
       01  W-SQLCODE                PIC 999   VALUE ZERO.               00850000
      *                                                                 00860000
       01  W-TTCO-IMPORTO           PIC S9(12)V9(3).                    00870000
      *                                                                 00880000
       01  W-STAT01                 PIC X(02) VALUE SPACES.             00900000
       01  W-STATO2                 PIC X(02) VALUE SPACES.             00910000
      *                                                                 00910010
250702 01 APPO-TRIC-COD-ANOM         PIC X(30) VALUE SPACES.            00910100
250702 01 APPO-TRIC-ESITO            PIC X(2)  VALUE SPACES.            00910200
250702 01 APPO-TRIC-STATO-RICH       PIC 9     VALUE 0.                 00910300
250702 01 W-CTR-INSERITI             PIC 9(08) VALUE 0.                 00910400
      *                                                                 00930000
       01  WS-TIME-ODIERNA.                                             00930100
           02 WS-HH                    PIC 99.                          00930200
           02 WS-MM                    PIC 99.                          00930300
           02 WS-SS                    PIC 99.                          00930400
      *                                                                 00930502
       01  WS-TIME.                                                     00930602
           02 WS-HH                    PIC 99.                          00930702
           02 FILLER                   PIC X  VALUE ':'.                00930802
           02 WS-MM                    PIC 99.                          00930902
           02 FILLER                   PIC X  VALUE ':'.                00931002
           02 WS-SS                    PIC 99.                          00931102
      *                                                                 00931202
       01  WS-DATA-ODIERNA.                                             00931302
           02 WS-AA                    PIC 99.                          00931402
           02 WS-MM                    PIC 99.                          00931502
           02 WS-GG                    PIC 99.                          00931602
      *                                                                 00931702
       01  WS-DATA.                                                     00931802
           02 WS-GG                    PIC 99.                          00931902
           02 FILLER                   PIC X  VALUE '/'.                00932002
           02 WS-MM                    PIC 99.                          00932102
           02 FILLER                   PIC X  VALUE '/'.                00932202
           02 WS-SEC                   PIC 99 VALUE 20.                 00932302
           02 WS-AA                    PIC 99.                          00932402
      *                                                                 00933002
       01  W-DATA-ELAB.                                                 00940000
           03  W-DATA-ELAB-AA   PIC 9(04).                              00950000
           03  W-DATA-ELAB-MM   PIC 9(02).                              00960000
           03  W-DATA-ELAB-GG   PIC 9(02).                              00970000
      *                                                                 00980000
       01  W-DATA-ELAB-RED     REDEFINES   W-DATA-ELAB  PIC 9(8).       00990000
      *                                                                 01000000
       01  WS-DATA-ATTIVITA     PIC 9(08).                              01010000
      *                                                                 01020000
       01  W-ESITO.                                                     01030000
           03  W-ESITO-1        PIC X(05).                              01040000
           03  W-ESITO-2        PIC X(05).                              01050000
           03  W-ESITO-3        PIC X(05).                              01060000
           03  W-ESITO-4        PIC X(05).                              01070000
      *                                                                 01080000
       01  W-COD-ANOM.                                                  01090000
           03  W-COD-ANOM-1     PIC 9(05).                              01100000
           03  W-COD-ANOM-2     PIC 9(05).                              01110000
           03  W-COD-ANOM-3     PIC 9(05).                              01120000
           03  W-COD-ANOM-4     PIC 9(05).                              01130000
           03  W-COD-ANOM-5     PIC 9(05).                              01140000
           03  W-COD-ANOM-6     PIC 9(05).                              01150000
      *                                                                 01160001
       01 WS-APP-REC.                                                   01161000
          03 WS-APP-TIPO-REC    PIC X(02).                              01162000
          03 WS-APP-NDG         PIC X(12).                              01162100
          03 WS-APP-SERVIZIO    PIC X(03).                              01163000
          03 WS-APP-CATEGORIA   PIC X(04).                              01164000
          03 WS-APP-FILIALE     PIC X(05).                              01165000
          03 WS-APP-NUMERO      PIC 9(12).                              01166000
090101    03 WS-DT-RIS-ENT      PIC 9(08).                              01167015
090101    03 WS-FIL-RICH        PIC X(05).                              01168015
      ***************************************************************** 01170001
      *                     INCLUDE  TABELLE  DB2                     * 01180001
      ***************************************************************** 01190001
      *                                                                 01200000
           EXEC  SQL  INCLUDE  SQLCA      END-EXEC.                     01210000
           EXEC  SQL  INCLUDE  SCTBTRIC       END-EXEC.                 01220000
           EXEC  SQL  INCLUDE  SCTBTDAT       END-EXEC.                 01251000
250702     EXEC  SQL  INCLUDE  SCTBTSTO       END-EXEC.                 01251100
250702     EXEC  SQL  INCLUDE  RIC024CD       END-EXEC.                 01251200
                                                                        01251300
      ***************************************************************** 01260001
       PROCEDURE DIVISION.                                              01270000
      *                                                                 01280001
                                                                        01290000
      *                                                                 01296000
           PERFORM  INIZIO   THRU  INIZIO-EX.                           01320000
      *                                                                 01371200
           PERFORM 02050-LEGGI-INPUT-70 THRU 02050-EX                   01372101
                   UNTIL W-STAT01  = '10'.                              01372200
      *                                                                 01372300
           PERFORM 20100-CHIUDI-FILE70    THRU  20100-EX.               01373001
      *                                                                 01380000
           PERFORM 40000-CHIUDI-FILE-OUT  THRU 40000-EX.                01390000
      *                                                                 01400000
       FINE-PROGRAMMA.                                                  01410000
           DISPLAY '*************************************************'. 01430001
           DISPLAY '*        FINE ELABORAZIONE PGM ARRAB009         *'. 01430101
           DISPLAY '*************************************************'. 01430201
           DISPLAY '*DATA ELABORAZIONE : ' WS-DATA                      01430303
      -            '                 *'.                                01430404
           DISPLAY '*                                               *'. 01430501
           DISPLAY '*ORA ELABORAZIONE__: ' WS-TIME                      01430603
      -            '                   *'.                              01430704
           DISPLAY '*************************************************'. 01430801
           DISPLAY '*RECORD LETTI__________________: ' CTR-REC-TOT      01431003
      -            '       *'.                                          01431104
           DISPLAY '*                                               *'. 01432001
           DISPLAY '*RECORD SCRITTI SU ANOMALIE____: ' CTR-ANOMALIE     01440003
      -            '       *'.                                          01440104
           DISPLAY '*                                               *'. 01440105
           DISPLAY '*RECORD INSERITI SULLA TSTO____: ' W-CTR-INSERITI   01440106
      -            '       *'.                                          01440107
           DISPLAY '*************************************************'. 01441001
           STOP RUN.                                                    01450000
                                                                        01460000
      ******************************************************************01470000
      *     ROUTINE DI INIZIO PROGRAMMA                                *01471001
      ******************************************************************01472001
       INIZIO.                                                          01480000
                                                                        01490000
           PERFORM 00950-CERCA-DATA THRU 00950-EX.                      01500100
           ACCEPT WS-DATA-ODIERNA FROM DATE.                            01501000
           MOVE CORRESPONDING WS-DATA-ODIERNA TO WS-DATA.               01501102
           ACCEPT WS-TIME-ODIERNA FROM TIME.                            01502000
           MOVE CORRESPONDING WS-TIME-ODIERNA TO WS-TIME.               01502102
           PERFORM 30100-APRI-FILE70 THRU 30100-EX.                     01502201
           PERFORM 50000-APRI-FILE-OUT  THRU  50000-EX.                 01503000
                                                                        01510000
                                                                        01530000
       INIZIO-EX. EXIT.                                                 01540000
      ***************************************************************** 01540100
      *                                                                 01540200
      ***************************************************************** 01540300
250702 00500-SCRIVI-STORICO.                                            01540400
                                                                        01540500
            MOVE WS-APP-NUMERO TO TRIC-NUMERO.                          01540600
                                                                        01540700
            PERFORM 00501-APRI-CURSORE THRU 00501-EX.                   01540800
                                                                        01540900
            PERFORM 00505-FETCH THRU 00505-EX.                          01541000
                                                                        01541100
            PERFORM UNTIL SQLCODE = 100                                 01541200
               PERFORM 00502-INSERISCI  THRU 00502-EX                   01541300
               PERFORM 00505-FETCH      THRU 00505-EX                   01541400
            END-PERFORM.                                                01541500
                                                                        01541600
            PERFORM 00503-CHIUDI-CURSORE   THRU 00503-EX.               01541700
                                                                        01541800
250702 00500-EX.                                                        01541900
           EXIT.                                                        01542000
                                                                        01542100
      ***************************************************************** 01542200
      *                                                                 01542300
      ***************************************************************** 01542400
250702 00501-APRI-CURSORE.                                              01542500
                                                                        01542600
            EXEC SQL INCLUDE RIC001CO   END-EXEC.                       01542700
                                                                        01542800
            INITIALIZE W-SQLCODE.                                       01542900
            MOVE SQLCODE TO W-SQLCODE.                                  01543000
            IF SQLCODE NOT EQUAL 0                                      01543100
               DISPLAY 'LABEL 00501-APRE-CURSORE-A1'                    01543200
               DISPLAY 'OPEN CURSOR: RIC001CO'                          01543300
               DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE        01543400
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  01543500
            END-IF.                                                     01543600
                                                                        01543700
250702 00501-EX.                                                        01543800
           EXIT.                                                        01543900
                                                                        01544000
      ***************************************************************** 01544100
      *                                                                 01544200
      ***************************************************************** 01544300
250702 00502-INSERISCI.                                                 01544400
                                                                        01544500
            MOVE  TRIC-NDG-PF         TO TSTO-NDG-PF.                   01544600
            MOVE  TRIC-SERVIZIO       TO TSTO-SERVIZIO.                 01544700
            MOVE  TRIC-CATEGORIA      TO TSTO-CATEGORIA.                01544800
            MOVE  TRIC-FILIALE        TO TSTO-FILIALE.                  01544900
            MOVE  TRIC-NUMERO         TO TSTO-NUMERO.                   01545000
            MOVE  TRIC-NDG-COI        TO TSTO-NDG-COI.                  01545100
            MOVE  TRIC-TIP-ATTIV      TO TSTO-TIP-ATTIV.                01545200
            MOVE  TRIC-STATO-RICH     TO TSTO-STATO-RICH.               01545300
            MOVE  TRIC-LIM-FIDO       TO TSTO-LIM-FIDO.                 01545400
            MOVE  TRIC-DIV-FIDO       TO TSTO-DIV-FIDO.                 01545500
            MOVE  TRIC-COD-ANOM       TO TSTO-COD-ANOM.                 01545600
            MOVE  TRIC-SETT-PROD      TO TSTO-SETT-PROD.                01545700
            MOVE  TRIC-COD-AFF        TO TSTO-COD-AFF.                  01545800
            MOVE  TRIC-ESITO          TO TSTO-ESITO.                    01545900
            MOVE  TRIC-NUM-PROT       TO TSTO-NUM-PROT.                 01546000
            MOVE  TRIC-TIPO-PROT      TO TSTO-TIPO-PROT.                01546100
            MOVE  TRIC-BAD-CUST       TO TSTO-BAD-CUST.                 01546200
            MOVE  TRIC-ACCR-STIP      TO TSTO-ACCR-STIP.                01546300
            MOVE  TRIC-IMP-STIP       TO TSTO-IMP-STIP.                 01546400
            MOVE  TRIC-DIV-STIP       TO TSTO-DIV-STIP.                 01546500
            MOVE  TRIC-DT-INV-ENT     TO TSTO-DT-INV-ENT.               01546600
            MOVE  TRIC-DT-RIS-ENT     TO TSTO-DT-RIS-ENT.               01546700
            MOVE  TRIC-DT-RIC-ATT     TO TSTO-DT-RIC-ATT.               01546800
            MOVE  TRIC-DT-ATT-VF      TO TSTO-DT-ATT-VF.                01546900
            MOVE  TRIC-DT-ATT-ESTINZ  TO TSTO-DT-ATT-ESTINZ.            01547000
            MOVE  W-DATA-ELAB-RED     TO TSTO-DT-VAL-A.                 01547100
            MOVE  TRIC-DT-STAMPA-AVV  TO TSTO-DT-STAMPA-AVV.            01547200
            MOVE  'ARRAB009'          TO TSTO-COD-OPER.                 01547300
            MOVE  TRIC-TERM-RICH      TO TSTO-TERM-RICH.                01547400
            MOVE  TRIC-FIL-RICH       TO TSTO-FIL-RICH.                 01547500
                                                                        01547600
            EXEC SQL INCLUDE  STO001IN     END-EXEC.                    01547700
                                                                        01547800
            MOVE SQLCODE TO W-SQLCODE                                   01547900
                                                                        01548000
            IF SQLCODE NOT EQUAL 0                                      01548100
               DISPLAY '00502-INSERISCI'                                01548200
               DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE        01548300
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  01548400
            END-IF.                                                     01548500
                                                                        01548600
            ADD 1 TO W-CTR-INSERITI.                                    01548700
                                                                        01548800
250702 00502-EX.                                                        01548900
           EXIT.                                                        01549000
                                                                        01549100
      ***************************************************************** 01549200
      *                                                                 01549300
      ***************************************************************** 01549400
250702 00503-CHIUDI-CURSORE.                                            01549500
                                                                        01549600
            EXEC SQL   INCLUDE RIC001CC   END-EXEC.                     01549700
                                                                        01549800
            INITIALIZE W-SQLCODE.                                       01549900
            MOVE SQLCODE TO W-SQLCODE.                                  01550000
            IF SQLCODE NOT EQUAL 0                                      01550100
               DISPLAY 'LABEL 00503-CHIUDI-CURSORE-A1'                  01550200
               DISPLAY 'CLOSE CURSOR: RIC001CO'                         01550300
               DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE        01550400
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  01550500
            END-IF.                                                     01550600
                                                                        01550700
250702 00503-EX.                                                        01550800
           EXIT.                                                        01550900
                                                                        01551000
      ***************************************************************** 01551100
      *                                                                 01551200
      ***************************************************************** 01551300
       00505-FETCH.                                                     01551400
                                                                        01551500
           EXEC SQL  INCLUDE RIC001CF    END-EXEC.                      01551600
                                                                        01551700
           MOVE SQLCODE TO W-SQLCODE.                                   01551800
           IF SQLCODE NOT EQUAL 0 AND 100                               01551900
               DISPLAY 'LABEL 00505-FETCH CURSORE-A1'                   01552000
               DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE        01552100
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  01552200
            END-IF.                                                     01552300
                                                                        01552400
       00505-EX.                                                        01552500
           EXIT.                                                        01552600
                                                                        01552700
      ***************************************************************** 03520000
      *     ROUTINE DI AGGIORNAMENTO DELLA TABELLA RICHIESTE          * 03521000
      ***************************************************************** 03522000
       00420-VARIA-RIC.                                                 03530000
      *                                                                 03540000
           MOVE WS-APP-SERVIZIO   TO  TRIC-SERVIZIO.                    03770000
           MOVE WS-APP-CATEGORIA  TO  TRIC-CATEGORIA.                   03780000
           MOVE WS-APP-FILIALE    TO  TRIC-FILIALE.                     03790000
           MOVE WS-APP-NUMERO     TO  TRIC-NUMERO.                      03800000
      *                                                                 03810000
           MOVE WS-APP-TIPO-REC   TO  TRIC-TIP-ATTIV.                   03820000
           MOVE SPACES            TO  TRIC-NUM-PROT.                    03840000
           MOVE SPACES            TO  TRIC-TIPO-PROT.                   03850000
           MOVE ZEROES            TO  TRIC-DT-ATT-VF.                   03860000
           MOVE W-DATA-ELAB-RED   TO  TRIC-DT-RIS-ENT                   03870016
                                      TRIC-DT-RIC-ATT.                  03871016
                                                                        03871017
250702     MOVE APPO-TRIC-COD-ANOM       TO  TRIC-COD-ANOM.             03871018
250702     MOVE APPO-TRIC-ESITO          TO  TRIC-ESITO.                03871019
250702     MOVE APPO-TRIC-STATO-RICH     TO  TRIC-STATO-RICH.           03871020
                                                                        03871021
250702     MOVE  0                 TO  TRIC-DT-INV-ENT.                 03871030
                                                                        03871040
           MOVE 'ARRAB009'        TO  TRIC-COD-OPER.                    03872017
      *                                                                 03880000
           EXEC SQL INCLUDE  RIC011UP     END-EXEC.                     03890000
      *                                                                 03900000
           MOVE SQLCODE TO W-SQLCODE.                                   03910000
      *                                                                 03920000
           IF SQLCODE NOT EQUAL 0                                       03930000
              DISPLAY 'LABEL 00420-VARIA-RIC'                           03940000
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' SQLCODE           03950000
              PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                   03960000
           END-IF.                                                      03970000
      *                                                                 03980000
       00420-EX.                                                        03990000
           EXIT.                                                        04000000
      ***************************************************************** 08551001
      * -ANALISI TIPO RECORD 70                                       * 08552001
      * -CONTROLLO CONGRUENZA TIPO-RECORD / TIPO-ATTIVITA             * 08553001
      * -AGGIORNAMENTO TABELLA RICHIESTE                              * 08554001
      ***************************************************************** 08560001
       03200-ELABORA-REC-70.                                            08560101
      *                                                                 08562100
           MOVE ARRAC029-TIP-REC   TO WS-APP-TIPO-REC.                  08562201
           MOVE ARRAC029-NDG       TO WS-APP-NDG.                       08562301
           MOVE ARRAC029-SERVIZIO  TO WS-APP-SERVIZIO.                  08562401
           MOVE ARRAC029-CATEGORIA TO WS-APP-CATEGORIA.                 08562501
           MOVE ARRAC029-NUMERO    TO WS-APP-NUMERO.                    08562601
           MOVE ARRAC029-FILIALE   TO WS-APP-FILIALE.                   08562701
      *                                                                 08563000
           PERFORM 03250-CONGRUENZA-REC   THRU  03250-EX.               08564000
      *                                                                 08565000
           IF W-CONGRUENZA  = 'KO'                                      08566000
                GO TO 03200-EX                                          08567000
           END-IF.                                                      08568000
      *                                                                 08570200
           MOVE     '2'    TO   TRIC-STATO-RICH                         08570300
250702                          APPO-TRIC-STATO-RICH.                   08570310
      *                                                                 08570400
250702     PERFORM 00500-SCRIVI-STORICO      THRU 00500-EX.             08570401
      *                                                                 08570410
           PERFORM 00420-VARIA-RIC           THRU 00420-EX.             08570500
      *                                                                 08570600
       03200-EX. EXIT.                                                  08570700
      ***************************************************************** 08570801
      *   ROUTINE DI CONTROLLO CONGRUENZA TIPO RECORD/TIPO ATTIVITA'  * 08570901
      ***************************************************************** 08571001
       03250-CONGRUENZA-REC.                                            08571101
      *                                                                 08571201
           MOVE ARRAC029-NDG        TO  TRIC-NDG-PF                     08571301
           MOVE ARRAC029-SERVIZIO   TO  TRIC-SERVIZIO                   08571401
           MOVE ARRAC029-CATEGORIA  TO  TRIC-CATEGORIA                  08571501
           MOVE ARRAC029-FILIALE    TO  TRIC-FILIALE                    08571601
           MOVE ARRAC029-NUMERO     TO  TRIC-NUMERO                     08571701
      *                                                                 08571801
           EXEC SQL  INCLUDE RIC012SL   END-EXEC.                       08571901
      *                                                                 08572001
           MOVE SQLCODE TO W-SQLCODE.                                   08572101
           IF SQLCODE = 100                                             08572201
              DISPLAY '************************************************'08572305
              DISPLAY '*          LABEL 03250-CONGRUENZA-REC          *'08572405
              DISPLAY '************************************************'08572505
              DISPLAY '*NDG ========> ' ARRAC029-NDG ' <================08572608
      -               '= *'                                             08572709
              DISPLAY '*SERVIZIO ===> ' ARRAC029-SERVIZIO ' <===========08572808
      -               '=============== *'                               08572909
              DISPLAY '*CATEGORIA ==> ' ARRAC029-CATEGORIA ' <==========08573008
      -               '=============== *'                               08573109
              DISPLAY '*FILIALE ====> ' ARRAC029-FILIALE ' <============08573208
      -               '============ *'                                  08573309
              DISPLAY '*NUMERO =====> ' ARRAC029-NUMERO ' <=============08573408
      -               '==== *'                                          08573509
              DISPLAY '*----------------------------------------------*'08573605
              DISPLAY '* OCCORRENZA NON PRESENTE SU ARCHIVIO RICHIESTE*'08573705
              DISPLAY '************************************************'08573805
              MOVE    927       TO ARRAC007-MSG-01                      08573905
090101        MOVE 0            TO WS-DT-RIS-ENT                        08574015
090101        MOVE SPACES       TO WS-FIL-RICH                          08574115
              MOVE 'KO'     TO        W-CONGRUENZA                      08574211
              PERFORM 10000-SCRIVI-ANOMALIE  THRU  10000-EX             08574311
              GO TO 03250-EX                                            08574411
           END-IF.                                                      08574511
           IF SQLCODE NOT EQUAL 0 AND 100                               08574611
              DISPLAY 'LABEL 03250-CONGRUENZA-REC'                      08574711
              DISPLAY 'ERRORE SQL ' W-SQLCODE ' SU LETTURA RICHIESTE'   08574811
              PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                   08574911
           END-IF.                                                      08575011
      *                                                                 08575114
090101     MOVE TRIC-DT-RIS-ENT TO WS-DT-RIS-ENT.                       08575215
090101     MOVE TRIC-FIL-RICH   TO WS-FIL-RICH.                         08575315
                                                                        08575316
250702     MOVE TRIC-COD-ANOM   TO APPO-TRIC-COD-ANOM.                  08575317
250702     MOVE TRIC-ESITO      TO APPO-TRIC-ESITO    .                 08575318
250702     MOVE TRIC-STATO-RICH TO APPO-TRIC-STATO-RICH.                08575319
                                                                        08575320
      *                                                                 08575411
040902*    IF TRIC-TIP-ATTIV  NOT = 'RR'                                08575511
040902     IF TRIC-TIP-ATTIV  NOT = 'RR' AND 'RC'                       08575512
              MOVE    920          TO ARRAC007-MSG-01                   08575614
              MOVE 'KO'     TO        W-CONGRUENZA                      08575911
              PERFORM 10000-SCRIVI-ANOMALIE  THRU  10000-EX             08576011
              GO TO 03250-EX                                            08576111
           END-IF.                                                      08576211
      *                                                                 08576311
           IF  TRIC-STATO-RICH  < 3                                     08576411
               MOVE    920       TO ARRAC007-MSG-01                     08576511
               MOVE 'KO'     TO        W-CONGRUENZA                     08576611
               PERFORM 10000-SCRIVI-ANOMALIE  THRU  10000-EX            08576711
               GO TO 03250-EX                                           08576811
           END-IF.                                                      08576911
      *                                                                 08577011
       03250-EX. EXIT.                                                  08577111
      ***************************************************************** 08577211
      *   LETTURA FILE DI INPUT:                                      * 08578001
      *                         IL FILE E GIA STATO CONTROLLATO       * 08580001
      *                         NELLA QUANTITA' DEI  RECORDS          * 08590001
      ***************************************************************** 08600001
       02050-LEGGI-INPUT-70.                                            09312001
      *                                                                 09315000
           MOVE   SPACES   TO        W-CONGRUENZA.                      09316000
      *                                                                 09317000
           READ FILE70  INTO ARRAC029-REC.                              09318001
      *                                                                 09319000
           IF W-STAT01 NOT = '00' AND NOT = '10'                        09319300
               DISPLAY 'LABEL 02050-LEGGI-INPUT'                        09319500
               DISPLAY 'ERRORE LETTURA  FILE70' W-STAT01                09319601
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  09319700
           END-IF.                                                      09319800
      *                                                                 09320000
           IF W-STAT01  = '10'                                          09320100
              GO TO 02050-EX                                            09320200
           END-IF.                                                      09320300
      *                                                                 09320400
           IF ARRAC029-TIP-REC = '00'                                   09320501
              GO TO 02050-EX                                            09320600
           END-IF.                                                      09320700
      *                                                                 09320800
           ADD 1   TO  CTR-REC-TOT.                                     09320900
      *                                                                 09321000
           PERFORM 03200-ELABORA-REC-70 THRU 03200-EX.                  09321101
      *                                                                 09321400
       02050-EX. EXIT.                                                  09321500
      ***************************************************************** 13640000
      *       ROUTINE DI SCRITTURA DEL FILE DI OUTPUT                 * 13641000
      ***************************************************************** 13642000
       10000-SCRIVI-ANOMALIE.                                           13650000
      *                                                                 13670000
           IF  W-CONGRUENZA  = 'KO'                                     13680000
               MOVE    'I'       TO ARRAC007-I-E-ANOM                   13690000
           ELSE                                                         13700000
               MOVE    'E'       TO ARRAC007-I-E-ANOM                   13710000
           END-IF.                                                      13720000
           MOVE WS-APP-TIPO-REC  TO ARRAC007-TIPO-REC.                  13720100
100206     MOVE 'KO'             TO ARRAC007-ESITO.                     13720200
           MOVE WS-APP-NDG       TO ARRAC007-NDG.                       13721000
           MOVE WS-APP-SERVIZIO  TO ARRAC007-SERVIZIO.                  13722000
           MOVE WS-APP-CATEGORIA TO ARRAC007-CATEGORIA.                 13723000
           MOVE WS-APP-FILIALE   TO ARRAC007-FILIALE.                   13724000
           MOVE WS-APP-NUMERO    TO ARRAC007-NUMERO.                    13725000
090101     MOVE WS-DT-RIS-ENT    TO ARRAC007-DT-RIS-ENT.                13726014
090101     MOVE WS-FIL-RICH      TO ARRAC007-FIL-RICH.                  13727014
141102     MOVE TRIC-DT-INV-ENT  TO ARRAC007-DT-INV-ENT.                13727015
      *                                                                 13730000
           WRITE K-REC-OUT  FROM  ARRAC007.                             13740000
      *                                                                 13750000
           IF W-STATO2 NOT = ZERO                                       13760000
              DISPLAY 'LABEL: 10000-SCRIVI-ANOMALIE'                    13780000
              DISPLAY 'ERRORE SCRITTURA ANOMALIE ' W-STATO2             13781000
              PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                   13790000
           END-IF.                                                      13800000
      *                                                                 13810000
           ADD  1  TO   CTR-ANOMALIE.                                   13811000
      *                                                                 13812000
       10000-EX. EXIT.                                                  13820000
      ***************************************************************** 13901100
      *       ROUTINE DI CHIUSURA DEL FILE DI INPUT                   * 13901200
      ***************************************************************** 13901300
       20100-CHIUDI-FILE70.                                             13902001
      *                                                                 13903000
           CLOSE FILE70.                                                13904001
           IF  W-STAT01  NOT = '00'                                     13905000
               DISPLAY 'ERRORE CHIUSURA FILE70  ' W-STAT01              13906001
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  13907000
           END-IF.                                                      13908000
       20100-EX. EXIT.                                                  13909000
      ***************************************************************** 13991000
      *       ROUTINE DI CHIUSURA DEL FILE DI OUTPUT DELLE ANOMALIE   * 13992000
      ***************************************************************** 13993000
       40000-CHIUDI-FILE-OUT.                                           14000000
           CLOSE ANOMALIE.                                              14010000
           IF  W-STATO2  NOT = '00'                                     14020000
               DISPLAY 'ERRORE CHIUSURA ANOMALIE ' W-STATO2             14030000
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  14040000
           END-IF.                                                      14050000
       40000-EX. EXIT.                                                  14060000
      ***************************************************************** 14071000
      *       ROUTINE DI APERTURA DEL FILE DI OUTPUT DELLE ANOMALIE   * 14072000
      ***************************************************************** 14073000
       50000-APRI-FILE-OUT.                                             14080000
           OPEN  OUTPUT ANOMALIE.                                       14090000
           IF  W-STATO2  NOT = '00'                                     14100000
               DISPLAY 'ERRORE APERTURA ANOMALIE  ' W-STATO2            14110000
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  14120000
           END-IF.                                                      14130000
       50000-EX. EXIT.                                                  14140000
      ***************************************************************** 14150001
      *       ROUTINE DI GESTIONE DELL' ABEND                         * 14151001
      ***************************************************************** 14152001
       GEST-ABEND.                                                      14160000
                                                                        14170000
           MOVE   'ILBOABN0'  TO  W-PROGRAM.                            14180000
                                                                        14190000
           CALL   W-PROGRAM  USING  COMP-CODE.                          14200000
                                                                        14210000
       EX-GEST-ABEND. EXIT.                                             14220000
      ***************************************************************** 14234000
      *       ROUTINE DI APERTURA DEL FILE DI INPUT                   * 14234100
      ***************************************************************** 14234200
       30100-APRI-FILE70.                                               14235001
           OPEN  INPUT  FILE70.                                         14236001
           IF  W-STAT01  NOT = '00'                                     14237000
               DISPLAY 'ERRORE APERTURA FILE70   ' W-STAT01             14238001
               PERFORM GEST-ABEND  THRU  EX-GEST-ABEND                  14239000
           END-IF.                                                      14239100
       30100-EX.                                                        14239200
           EXIT.                                                        14239300
      ***************************************************************** 14239400
      * ROUTINE PER LA RICERCA DELLA DATA RICHIESTA E DATA BATCH SU   * 14239500
      * TABELLA TDAT.NEL CASO IN CUI DATA RICHIESTA NON SIA VALO-     * 14239600
      * RIZZATA IL PROGRAMMA CONTINUA NELL' ELABORAZIONE ASSUMENDO LA * 14239700
      * DATA BATCH COME DATA DI SISTEMA.                              * 14239800
      ***************************************************************** 14239900
       00950-CERCA-DATA.                                                14240000
           EXEC SQL INCLUDE DATA01SL END-EXEC.                          14240100
           IF TDAT-BATCH NOT = 0                                        14240200
              MOVE TDAT-BATCH TO W-DATA-ELAB-RED                        14240300
              GO TO 00950-EX                                            14240400
           ELSE                                                         14240500
DEBU          DISPLAY 'ATTENZIONE-VALORIZZARE LA DATA TDAT_BATCH SU DB S14240600
DEBU  -        'CTBTDAT'                                                14240700
              PERFORM GEST-ABEND THRU EX-GEST-ABEND                     14240800
           END-IF.                                                      14240900
       00950-EX.                                                        14241000
           EXIT.                                                        14241100
