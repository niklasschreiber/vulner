       IDENTIFICATION DIVISION.                                         00000100
       PROGRAM-ID.    ARRA845B.                                         00000200
       AUTHOR. BANKSIEL.                                                00000300
       ENVIRONMENT DIVISION.                                            00000400
       CONFIGURATION SECTION.                                           00000500
       SPECIAL-NAMES.                                                   00000600
           DECIMAL-POINT IS COMMA.                                      00000700
      ****************************************************************  00000800
      *    PROGRAMMA DI ARRICCHIMENTO ANAGRAFICO PER SEGNALAZIONI    *  00000900
      *    CONTI PRESENTI SU INDICE  AL CCU                          *  00000910
      ****************************************************************  00001000
       INPUT-OUTPUT SECTION.                                            00001100
       FILE-CONTROL.                                                    00001200
                                                                        00001300
           SELECT INPROTA ASSIGN TO INPROTA                             00001400
                  FILE STATUS IS FS-INPROTA.                            00001500
                                                                        00001600
           SELECT  OUTROTA  ASSIGN  TO OUTROTA                          00001700
                   FILE  STATUS  IS  FS-OUTROTA.                        00001800
                                                                        00001900
           SELECT  OUTANOM  ASSIGN  TO OUTANOM                          00001910
                   FILE  STATUS  IS  FS-OUTANOM.                        00001920
                                                                        00001930
       DATA DIVISION.                                                   00002000
       FILE SECTION.                                                    00002100
                                                                        00002200
       FD  INPROTA  LABEL RECORD STANDARD                               00002300
                    RECORDING MODE IS F                                 00002400
                    BLOCK CONTAINS 0 RECORDS.                           00002500
       01  REC-INPROTA            PIC X(170) .                          00002600
      *                                                                 00002700
                                                                        00002800
       FD  OUTROTA                                                      00002900
           LABEL RECORD STANDARD                                        00003000
           RECORDING MODE IS F                                          00003100
           BLOCK CONTAINS 0 RECORDS.                                    00003200
       01  REC-OUTROTA            PIC X(496).                           00003300
                                                                        00003400
       FD  OUTANOM                                                      00003410
           LABEL RECORD STANDARD                                        00003420
           RECORDING MODE IS F                                          00003430
           BLOCK CONTAINS 0 RECORDS.                                    00003440
       01  REC-OUTANOM            PIC X(496).                           00003450
                                                                        00003460
      ******************************************************************00003500
      *               W O R K I N G     S T O R A G E                  *00003600
      ******************************************************************00003700
       WORKING-STORAGE SECTION.                                         00003800
                                                                        00003900
      ******************************************************************00004000
      *      CAMPI  PER  GESTIONE  ABEND                               *00004100
      ******************************************************************00004200
       77  COMP-CODE                PIC S9(004) COMP VALUE +5555.       00004300
       01  WS-PROGRAM               PIC X(008)  VALUE SPACE.            00004400
      ******************************************************************00004500
      *      FILE STATUS                                               *00004600
      ******************************************************************00004700
       01  FS-INPROTA               PIC X(002)  VALUE SPACE.            00004800
       01  FS-OUTROTA               PIC X(002)  VALUE SPACE.            00004900
       01  FS-OUTANOM               PIC X(002)  VALUE SPACE.            00004910
                                                                        00005000
       01 WS-SKEDA.                                                     00005100
          05 WS-DATA-ODIERNA       PIC 9(8).                            00005200
                                                                        00005300
      ******************************************************************00005710
      *      TRACCIATO DI OUTPUT                                       *00005720
      ******************************************************************00005730
           COPY ARRAC845.                                               00005740
      ******************************************************************00005741
      * COBOL DECLARATION FOR TABLE DRACC0C.SCTBROTA                   *00005742
      ******************************************************************00005743
       01  WS-ROTA.                                                     00005744
           10 TROT-SERVIZIO        PIC X(3).                            00005745
           10 TROT-CATEGORIA       PIC X(4).                            00005746
           10 TROT-FILIALE         PIC X(5).                            00005747
           10 TROT-NUMERO          PIC S9(12)V USAGE COMP-3.            00005748
           10 TROT-NDG             PIC X(12).                           00005749
           10 TROT-DATA-1          PIC S9(6)V USAGE COMP-3.             00005750
           10 TROT-UTIL-1          PIC S9(11)V9(2) USAGE COMP-3.        00005751
           10 TROT-IMP-ACCR-1      PIC S9(11)V9(2) USAGE COMP-3.        00005752
           10 TROT-DATA-2          PIC S9(6)V USAGE COMP-3.             00005753
           10 TROT-UTIL-2          PIC S9(11)V9(2) USAGE COMP-3.        00005754
           10 TROT-IMP-ACCR-2      PIC S9(11)V9(2) USAGE COMP-3.        00005755
           10 TROT-DATA-3          PIC S9(6)V USAGE COMP-3.             00005756
           10 TROT-UTIL-3          PIC S9(11)V9(2) USAGE COMP-3.        00005757
           10 TROT-IMP-ACCR-3      PIC S9(11)V9(2) USAGE COMP-3.        00005758
           10 TROT-DATA-4          PIC S9(6)V USAGE COMP-3.             00005759
           10 TROT-UTIL-4          PIC S9(11)V9(2) USAGE COMP-3.        00005760
           10 TROT-IMP-ACCR-4      PIC S9(11)V9(2) USAGE COMP-3.        00005761
           10 TROT-DATA-5          PIC S9(6)V USAGE COMP-3.             00005762
           10 TROT-UTIL-5          PIC S9(11)V9(2) USAGE COMP-3.        00005763
           10 TROT-IMP-ACCR-5      PIC S9(11)V9(2) USAGE COMP-3.        00005764
           10 TROT-DATA-6          PIC S9(6)V USAGE COMP-3.             00005765
           10 TROT-UTIL-6          PIC S9(11)V9(2) USAGE COMP-3.        00005766
           10 TROT-IMP-ACCR-6      PIC S9(11)V9(2) USAGE COMP-3.        00005767
           10 TROT-TOT-SEGN-CONS   PIC S9(8)V USAGE COMP-3.             00005768
           10 TROT-TOT-SEGNALA     PIC S9(8)V USAGE COMP-3.             00005769
           10 TROT-DATA-RIL        PIC S9(8)V USAGE COMP-3.             00005770
           10 TROT-IMP-FIDO        PIC S9(11)V9(2) USAGE COMP-3.        00005771
           10 TROT-SETT-PROD       PIC X(2).                            00005772
           10 TROT-SALDCONT        PIC S9(11)V9(2) USAGE COMP-3.        00005773
                                                                        00005774
      *                                                                 00005775
      * COPY DI RICHIAMO ACS108                                         00005776
       01  ACS108-AREA.                                                 00005777
           COPY ACS108A.                                                00005780
                                                                        00005800
      * COPY DI RICHIAMO ACS035                                         00005802
                                                                        00005803
      *ROUTINE DEI TELEFONI                                             00005804
      *                                                                 00005805
       01 ACS035-AREA.                                                  00005806
           COPY ACS035A.                                                00005807
      *                                                                 00005808
       01 ACS035BT                    PIC X(08) VALUE 'ACS035BT'.       00005809
       01 W-SQLCODE                   PIC 999 VALUE 0.                  00005810
       01 SW-FINE-TEL                 PIC 9 VALUE 0.                    00005811
       01 SW-TEL1-TROVATO             PIC 9 VALUE 0.                    00005812
       01 SW-TEL2-TROVATO            PIC 9 VALUE 0.                     00005814
       01 FLAG-TANG                  PIC X(002) VALUE SPACES.           00005815
       01 FLAG-ACS035                PIC X(002) VALUE SPACES.           00005816
       01 APPO-PRE-TEL-1             PIC 9(006) VALUE 0.                00005818
       01 APPO-NUM-TEL-1             PIC 9(010) VALUE 0.                00005819
       01 APPO-PRE-TEL-2             PIC 9(006) VALUE 0.                00005820
       01 APPO-NUM-TEL-2             PIC 9(010) VALUE 0.                00005821
       01 WS-TANG-NDG                PIC X(012) VALUE SPACES.           00005822
       01 WS-TANG-ANNI         PIC S9(2)V USAGE COMP-3.                 00005823
       01 WS-TANG-MESI         PIC S9(2)V USAGE COMP-3.                 00005824
       01 WS-TANG-IND-PREC     PIC X(35).                               00005825
       01 WS-TANG-LOC-PREC     PIC X(30).                               00005826
       01 WS-TANG-PROV-PREC    PIC X(2).                                00005827
       01 WS-TANG-STATO-PREC   PIC X(4).                                00005828
       01 WS-TANG-IND-RES      PIC X(35).                               00005829
       01 WS-TANG-CAP-RES      PIC X(5).                                00005830
       01 WS-TANG-LOC-RES      PIC X(30).                               00005831
       01 WS-TANG-PROV-RES     PIC X(2).                                00005832
       01 WS-TANG-COM-RIL      PIC X(30).                               00005833
       01 WS-TANG-PROV-RIL     PIC X(2).                                00005834
       01 WS-TANG-TEL1         PIC X(12).                               00005835
       01 WS-TANG-TEL2         PIC X(12).                               00005836
       01 WS-TANG-DT-INSER     PIC S9(8)V USAGE COMP-3.                 00005837
       01 WS-TANG-DT-ULT-AGG   PIC S9(8)V USAGE COMP-3.                 00005838
       01 WS-TANG-COD-OPER     PIC X(8).                                00005839
       01 WS-TANG-TERM-RICH    PIC X(5).                                00005840
       01 WS-TANG-FIL-RICH     PIC X(5).                                00005841
       01 WS-COUNT-SCRITTI-OUT       PIC 9(08) VALUE 0.                 00005842
       01 WS-COUNT-SCRITTI-ANOM      PIC 9(08) VALUE 0.                 00005843
                                                                        00005844
       01 WS-APPO-PRE-TEL1.                                             00005845
          05 TELEFONO1             PIC 9(012).                          00005846
       01 WS-APPO-PRE-TEL REDEFINES  WS-APPO-PRE-TEL1.                  00005847
          05 PRE-TEL-1-RED         PIC X(004).                          00005848
          05 PRE-TRAT1-RED         PIC X(001).                          00005849
          05 TEL-1-RED             PIC X(007).                          00005850
                                                                        00005851
       01 WS-APPO-PRE-TEL2.                                             00005852
          05 TELEFONO2             PIC 9(012).                          00005853
       01 WS-APPO-PRE-TEL-2 REDEFINES  WS-APPO-PRE-TEL2.                00005854
          05 PRE-TEL-2-RED         PIC X(004).                          00005855
          05 PRE-TRAT2-RED         PIC X(001).                          00005856
          05 TEL-2-RED             PIC X(007).                          00005857
                                                                        00005858
       01 WS-TEL-TANG1          PIC X(012) VALUE SPACES.                00005859
       01 WS-TEL-TANG2          PIC X(012) VALUE SPACES.                00005860
                                                                        00005861
       01 WS-TEL-1              PIC X(012) VALUE SPACES.                00005862
       01 WS-TEL-2              PIC X(012) VALUE SPACES.                00005863
                                                                        00005864
       01  W-COMPONI-DI.                                                00005865
           03 WS-COMPONI-AZZERA VALUE SPACES.                           00005866
              05 W-TAB-COMPONI OCCURS 12.                               00005867
                 07 WS-COMPONI   PIC X.                                 00005868
                                                                        00005869
       01  W-TAB-TEL.                                                   00005870
           03 W-TEL-AZZERA VALUE SPACES.                                00005871
              05 W-TAB-ITEM OCCURS 12.                                  00005872
                 07 W-ELE-TEL              PIC X.                       00005873
                                                                        00005874
       01 W-IND                            PIC 99 VALUE 0.              00005875
       01 W-IND2                           PIC 99 VALUE 0.              00005876
                                                                        00005877
      ******************************************************************00005878
           COPY DYNACALL.                                               00005880
      ******************************************************************00005900
      *      CONTATORI PER CHIUSURA ELABORAZIONE                       *00006000
      ******************************************************************00006100
       01  WS-CTR-READ              PIC 9(08)  VALUE ZERO.              00006200
       01  WS-CTR-WRITE             PIC 9(08)  VALUE ZERO.              00006300
       01  WS-NO-NUM-VALIDI         PIC 9(08)  VALUE ZERO.              00006301
       01  WS-NO-ACS108             PIC 9(08)  VALUE ZERO.              00006303
                                                                        00006305
       01 AREA-TEL.                                                     00006306
           03  AREA-TELEFONO-AB     PIC X(12).                          00006307
           03  AREA-TELEFONO-RE     PIC X(12).                          00006308
           03  AREA-ESITO           PIC X(02).                          00006309
           03  AREA-DESCR-ERR       PIC X(50).                          00006310
                                                                        00006311
                                                                        00006312
      *---------------------------------------------------------------* 00006313
      *      INCLUDE  TABELLE  DB2                                    * 00006320
      *---------------------------------------------------------------* 00006330
      *                                                                 00006340
           EXEC  SQL  INCLUDE  SQLCA     END-EXEC.                      00006350
           EXEC  SQL  INCLUDE  SCTBTANG  END-EXEC.                      00006360
                                                                        00006370
                                                                        00006400
      ******************************************************************00007600
      *                 L I N K A G E     S E C T I O N                *00007700
      ******************************************************************00007800
       LINKAGE SECTION.                                                 00007900
                                                                        00007901
                                                                        00008000
      ******************************************************************00008100
      *             P R O C E D U R E     D I V I S I O N              *00008200
      ******************************************************************00008300
       PROCEDURE DIVISION.                                              00008400
      *                                                                 00008500
           PERFORM 00100-INIZIO         THRU 00100-EX.                  00008600
      *                                                                 00008700
           PERFORM 00200-LEGGI-INPROTA  THRU 00200-EX.                  00008800
      *                                                                 00008900
           PERFORM 00300-ELABORA        THRU 00300-EX                   00009000
             UNTIL FS-INPROTA = '10'.                                   00009100
      *                                                                 00009200
           PERFORM 00400-OPER-FINALI    THRU 00400-EX.                  00009300
      *                                                                 00009400
      *                                                                 00009500
           STOP RUN.                                                    00009600
      *                                                                 00009700
      *                                                                 00009800
      *                                                                 00009900
       00100-INIZIO.                                                    00010000
                                                                        00010001
           ACCEPT WS-SKEDA FROM SYSIN.                                  00010002
                                                                        00010003
           DISPLAY '*************************************'.             00010010
           DISPLAY ' I N I Z I O  P G M   A R R A 8 4 5 B'.             00010100
           DISPLAY '*************************************'.             00010200
           DISPLAY 'D A T A  O D I E R N A: ' WS-DATA-ODIERNA.          00010310
           DISPLAY '-------------------------------------'.             00010320
                                                                        00010400
      *                                                                 00010600
           OPEN INPUT INPROTA.                                          00010610
           IF FS-INPROTA NOT = '00'                                     00010700
              DISPLAY 'ERRORE APERTURA INPROTA STATUS = ' FS-INPROTA    00010800
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00010900
           END-IF.                                                      00011000
      *                                                                 00011100
           OPEN OUTPUT OUTROTA.                                         00011110
           IF FS-OUTROTA NOT = '00'                                     00011200
              DISPLAY 'ERRORE APERTURA OUTROTA STATUS = ' FS-OUTROTA    00011300
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00011400
           END-IF.                                                      00011500
      *                                                                 00011600
           OPEN OUTPUT OUTANOM.                                         00011610
           IF FS-OUTANOM NOT = '00'                                     00011620
              DISPLAY 'ERRORE APERTURA OUTANOM STATUS = ' FS-OUTANOM    00011630
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00011640
           END-IF.                                                      00011650
      *                                                                 00011660
       00100-EX.                                                        00011700
           EXIT.                                                        00011800
                                                                        00011900
       00200-LEGGI-INPROTA.                                             00012000
      *                                                                 00012100
           READ INPROTA INTO WS-ROTA.                                   00012210
      *                                                                 00012300
           IF  FS-INPROTA NOT = '00'                                    00012400
           AND FS-INPROTA NOT = '10'                                    00012500
              DISPLAY 'ERRORE LETTURA INPROTA, STATUS = ' FS-INPROTA    00012600
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00012700
           END-IF.                                                      00012800
      *                                                                 00012900
           IF FS-INPROTA NOT = '10'                                     00012910
              ADD 1                 TO WS-CTR-READ                      00012920
           END-IF.                                                      00012930
                                                                        00012940
           IF FS-INPROTA = '10' AND WS-CTR-READ =  0                    00013000
              DISPLAY 'FILE DI INPUT INPROTA VUOTO'                     00013001
           END-IF.                                                      00013002
      *                                                                 00013300
       00200-EX.                                                        00013400
           EXIT.                                                        00013500
                                                                        00013600
       00300-ELABORA.                                                   00013700
                                                                        00013710
           INITIALIZE ARRAC845-REC.                                     00013800
                                                                        00013801
           INITIALIZE WS-TEL-TANG1                                      00013802
                      WS-TEL-TANG2.                                     00013810
                                                                        00013820
           PERFORM 00220-ACCESSO-ANAG THRU 00220-EX.                    00013900
      *                                                                 00014000
           IF FLAG-TANG = 'KO' AND FLAG-ACS035 = 'KO'                   00014010
              PERFORM 00225-SCRIVI-SCARTI      THRU 00225-EX            00014014
           ELSE                                                         00014015
              PERFORM 00226-SCRIVI-OUT         THRU 00226-EX            00014016
           END-IF.                                                      00014020
                                                                        00014030
           PERFORM 00200-LEGGI-INPROTA      THRU 00200-EX.              00014100
      *                                                                 00014200
       00300-EX.                                                        00014300
           EXIT.                                                        00014400
                                                                        00014500
                                                                        00017600
      ***************************************************************** 00017610
      *      ROUTINE DI ACCESSO AL DB ANAGRAFE                        * 00017620
      ***************************************************************** 00017630
       00220-ACCESSO-ANAG.                                              00017640
                                                                        00017650
           INITIALIZE TELEFONO1 TELEFONO2 WS-TEL-TANG1                  00017651
                      ARRAC845-MOTIVO WS-TEL-TANG2 WS-TEL-1 WS-TEL-2.   00017652
                                                                        00017654
           MOVE SPACE                      TO L-ACS108-ARG.             00017660
           MOVE ZERO                       TO L-ACS108-I-BANCA.         00017670
           MOVE ZERO                       TO L-ACS108-I-DATA-RIF.      00017680
           MOVE ' '                        TO L-ACS108-I-TIPO-RICH.     00017690
           MOVE TROT-SERVIZIO              TO L-ACS108-I-SERVIZIO       00017692
           MOVE TROT-FILIALE               TO L-ACS108-I-FILIALE        00017693
           MOVE TROT-CATEGORIA             TO L-ACS108-I-CATEGORIA      00017694
           MOVE TROT-NUMERO                TO L-ACS108-I-NUMERO         00017695
           MOVE TROT-NDG                   TO L-ACS108-I-NDG.           00017699
           EXEC SQL INCLUDE EXACS108 END-EXEC.                          00017701
      *                                                                 00017702
           IF L-ACS108-RET-CODE  = ZERO                                 00017703
              PERFORM 00221-VALORIZZA-ANAGRAFICA THRU 00221-EX          00017705
              PERFORM 00223-VALORIZZA-DATI-TANG  THRU 00223-EX          00017707
              PERFORM ACCEDI-ACS035 THRU ACCEDI-ACS035-EX               00017709
              PERFORM CNTRL-ACS035  THRU CNTRL-ACS035-EX                00017711
              IF TELEFONO1 = 0 AND TELEFONO2 = 0                        00017713
                                                                        00017714
                 MOVE 'KO' TO FLAG-ACS035                               00017715
              ELSE                                                      00017717
                 PERFORM 00222-CONTROLLO-FORMALE-TEL THRU EX-00222      00017719
              END-IF                                                    00017724
           END-IF.                                                      00017725
      * * * * * * * * * * * * * * * * * * * * * *                       00017726
      * GESTIONE RET-CODE  PER CODICE ANOMALIA  *                       00017727
      * * * * * * * * * * * * * * * * * * * * * *                       00017728
           IF L-ACS108-RET-CODE  = 2                                    00017729
                 MOVE 'KO' TO FLAG-ACS035                               00017727
                 MOVE 'KO' TO FLAG-TANG                                 00017732
              DISPLAY ' RAPPORTO INESISTENTE     '                      00017733
              DISPLAY ' CODICE DI RITORNO MODULO ' L-ACS108-RET-CODE    00017734
              DISPLAY ' NDG              =       ' TROT-NDG             00017735
              DISPLAY ' SERVIZIO         =       ' TROT-SERVIZIO        00017736
              DISPLAY ' CATEGORIA        =       ' TROT-CATEGORIA       00017737
              DISPLAY ' FILIALE          =       ' TROT-FILIALE         00017738
              DISPLAY ' NUMERO           =       ' TROT-NUMERO          00017739
              MOVE  'RAPPORTO INESISTENTE IN ACS108' TO ARRAC845-MOTIVO 00017740
              GO TO 00220-EX                                            00017741
           END-IF.                                                      00017742
      *                                                                 00017743
           IF L-ACS108-RET-CODE  = 7                                    00017744
              MOVE 'KO' TO FLAG-ACS035                                  00017741
              MOVE 'KO' TO FLAG-TANG                                    00017747
              DISPLAY ' CHIAVE ANAGR. INESISTENTE' L-ACS108-RET-CODE    00017748
              DISPLAY ' NDG              =       ' TROT-NDG             00017749
              DISPLAY ' SERVIZIO         =       ' TROT-SERVIZIO        00017750
              DISPLAY ' CATEGORIA        =       ' TROT-CATEGORIA       00017751
              DISPLAY ' FILIALE          =       ' TROT-FILIALE         00017752
              DISPLAY ' NUMERO           =       ' TROT-NUMERO          00017753
              MOVE  'CHIAVE ANAGR. INESISTENTE IN ACS108'               00017754
                                               TO ARRAC845-MOTIVO       00017755
              GO TO 00220-EX                                            00017756
           END-IF.                                                      00017757
      *                                                                 00017758
           IF L-ACS108-RET-CODE  NOT = 2 AND                            00017759
              L-ACS108-RET-CODE  NOT = 7 AND                            00017760
              L-ACS108-RET-CODE  NOT = 0                                00017761
              MOVE 'KO' TO FLAG-ACS035                                  00017757
              MOVE 'KO' TO FLAG-TANG                                    00017765
              DISPLAY ' ABEND SISTEMA ' L-ACS108-RET-CODE               00017766
              DISPLAY ' NDG              =       ' TROT-NDG             00017767
              DISPLAY ' SERVIZIO         =       ' TROT-SERVIZIO        00017768
              DISPLAY ' CATEGORIA        =       ' TROT-CATEGORIA       00017769
              DISPLAY ' FILIALE          =       ' TROT-FILIALE         00017770
              DISPLAY ' NUMERO           =       ' TROT-NUMERO          00017771
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00017772
           END-IF.                                                      00017773
      *                                                                 00017774
       00220-EX.                                                        00017775
           EXIT.                                                        00017776
                                                                        00017777
       00221-VALORIZZA-ANAGRAFICA.                                      00017778
                                                                        00017779
           IF L-ACS108-INT-PART1 = SPACES  AND                          00017780
              L-ACS108-INT-PART2 = SPACES                               00017781
                                                                        00017782
              MOVE L-ACS108-INT-POSTALE1 TO ARRAC845-INTEST-1           00017783
              MOVE L-ACS108-INT-POSTALE2 TO ARRAC845-INTEST-2           00017784
              MOVE L-ACS108-IND-POSTALE  TO ARRAC845-INDIRIZZO          00017785
              MOVE L-ACS108-CAP-POSTALE  TO ARRAC845-CAP                00017786
              MOVE L-ACS108-LOC-POSTALE  TO ARRAC845-LOCALITA           00017787
              MOVE L-ACS108-NAZ-POSTALE  TO ARRAC845-NAZIONE            00017788
           ELSE                                                         00017789
              MOVE L-ACS108-IND-PART     TO  ARRAC845-INDIRIZZO         00017790
              MOVE L-ACS108-CAP-PART     TO  ARRAC845-CAP               00017791
              MOVE L-ACS108-LOC-PART     TO  ARRAC845-LOCALITA          00017792
              MOVE L-ACS108-NAZ-PART     TO  ARRAC845-NAZIONE           00017793
              MOVE L-ACS108-INT-PART1    TO ARRAC845-INTEST-1           00017794
              MOVE L-ACS108-INT-PART2    TO ARRAC845-INTEST-2           00017795
           END-IF.                                                      00017796
                                                                        00017797
       00221-EX.                                                        00017798
           EXIT.                                                        00017799
                                                                        00017800
       00222-CONTROLLO-FORMALE-TEL.                                     00017794
                                                                        00017802
           INITIALIZE WS-COMPONI-AZZERA W-TEL-AZZERA WS-TEL-1 WS-TEL-2. 00017796
                                                                        00017804
           MOVE TELEFONO1        TO W-TEL-AZZERA.                       00017805
                                                                        00017806
           MOVE 1 TO W-IND.                                             00017807
           MOVE 1 TO W-IND2.                                            00017808
           PERFORM UNTIL W-IND > 12                                     00017809
              IF W-ELE-TEL(W-IND) NOT = SPACE                           00017810
                 MOVE W-ELE-TEL(W-IND) TO WS-COMPONI(W-IND2)            00017811
                 ADD 1 TO W-IND2                                        00017812
              END-IF                                                    00017813
              ADD 1 TO W-IND                                            00017814
           END-PERFORM.                                                 00017815
                                                                        00017816
           MOVE WS-COMPONI-AZZERA TO WS-TEL-1.                          00017817
                                                                        00017818
           INITIALIZE WS-COMPONI-AZZERA W-TEL-AZZERA.                   00017819
                                                                        00017820
           MOVE TELEFONO2        TO W-TEL-AZZERA.                       00017854
                                                                        00017855
           MOVE 1 TO W-IND.                                             00017856
           MOVE 1 TO W-IND2.                                            00017857
           PERFORM UNTIL W-IND > 12                                     00017858
              IF W-ELE-TEL(W-IND) NOT = SPACE                           00017859
                 MOVE W-ELE-TEL(W-IND) TO WS-COMPONI(W-IND2)            00017860
                 ADD 1 TO W-IND2                                        00017861
              END-IF                                                    00017862
              ADD 1 TO W-IND                                            00017863
           END-PERFORM.                                                 00017864
                                                                        00017865
           MOVE WS-COMPONI-AZZERA TO WS-TEL-2.                          00017866
                                                                        00017867
           INITIALIZE AREA-TEL.                                         00017870
                                                                        00017871
           MOVE WS-TEL-1         TO AREA-TELEFONO-AB.                   00017834
           MOVE WS-TEL-2         TO AREA-TELEFONO-RE.                   00017835
      *                                                                 00017873
           MOVE 'ARRABTE1' TO WS-PROGRAM.                               00017874
      *                                                                 00017875
           CALL WS-PROGRAM USING AREA-TEL.                              00017876
                                                                        00017877
           IF AREA-ESITO = '00'                                         00017878
              MOVE 'OK' TO FLAG-ACS035                                  00017842
           ELSE                                                         00017880
              MOVE 'KO' TO FLAG-ACS035                                  00017844
           END-IF.                                                      00017882
                                                                        00017883
       EX-00222.                                                        00017847
           EXIT.                                                        00017885
       00223-VALORIZZA-DATI-TANG.                                       00017887
           MOVE TROT-NDG                   TO WS-TANG-NDG.              00017888
                                                                        00017889
           EXEC SQL INCLUDE ANG005SL END-EXEC.                          00017890
                                                                        00017891
           INITIALIZE W-SQLCODE.                                        00017892
                                                                        00017893
           MOVE SQLCODE TO W-SQLCODE.                                   00017894
                                                                        00017895
           IF SQLCODE = 0                                               00017896
              IF (WS-TANG-TEL1 = '9999' OR LOW-VALUE OR SPACES) AND     00017897
                 (WS-TANG-TEL2 = '9999' OR LOW-VALUE OR SPACES)         00017898
                  MOVE 'KO' TO FLAG-TANG                                00017899
              ELSE                                                      00017900
                 MOVE '  ' TO FLAG-TANG                                 00017901
                 IF WS-TANG-TEL1 NOT = '9999' AND LOW-VALUE AND SPACES  00017902
                    MOVE WS-TANG-TEL1 TO WS-TEL-TANG1                   00017903
                 END-IF                                                 00017904
                 IF WS-TANG-TEL2 NOT = '9999' AND LOW-VALUE AND SPACES  00017905
                    MOVE WS-TANG-TEL2 TO WS-TEL-TANG2                   00017906
                 END-IF                                                 00017907
              END-IF                                                    00017908
           END-IF.                                                      00017909
           IF SQLCODE = 100                                             00017910
              DISPLAY 'LABEL 00223-VALORIZZA-DATI-TANG'                 00017911
              DISPLAY 'NDG NON TROVATO SU SCTBTANG:' TROT-NDG           00017912
              MOVE 'KO' TO FLAG-TANG                                    00017913
           END-IF.                                                      00017914
                                                                        00017915
           IF SQLCODE NOT EQUAL 0 AND 100                               00017916
              DISPLAY 'NDG NON TROVATO SU SCTBTANG:' TROT-NDG           00017917
              DISPLAY 'LABEL 00223-VALORIZZA-DATI-TANG'                 00017918
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE         00017919
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00017920
           END-IF.                                                      00017921
                                                                        00017922
       00223-EX.                                                        00017923
           EXIT.                                                        00017924
                                                                        00017925
       ACCEDI-ACS035.                                                   00017926
                                                                        00017927
           INITIALIZE     ACS035-IN-OUT.                                00017928
           MOVE  0                   TO SW-FINE-TEL.                    00017929
           MOVE  0                   TO ACS035-DATA-RIF.                00017930
           MOVE  0                   TO SW-TEL1-TROVATO                 00017931
           MOVE  0                   TO SW-TEL2-TROVATO                 00017932
           MOVE '00000'              TO ACS035-BANCA                    00017933
           MOVE TROT-NDG             TO ACS035-NDG                      00017934
           MOVE SPACES               TO ACS035-COD-TEL                  00017935
           MOVE 3                    TO ACS035-NUM-MAX                  00017936
                                                                        00017937
           CALL  ACS035BT  USING  ACS035-AREA.                          00017938
                                                                        00017939
       ACCEDI-ACS035-EX.                                                00017940
           EXIT.                                                        00017941
                                                                        00017942
       CNTRL-ACS035.                                                    00017943
           IF  ACS035-RETCODE = ZEROES                                  00017944
               PERFORM CONTROLLO-TEL THRU CONTROLLO-TEL-EX              00017945
               VARYING ACS035-IND FROM 1 BY 1                           00017946
               UNTIL  ACS035-IND > 20                                   00017947
               OR     ACS035-COD-TEL-OUT(ACS035-IND) = SPACES           00017948
               OR     SW-FINE-TEL = 1                                   00017949
           ELSE                                                         00017950
              IF ACS035-RETCODE = 10                                    00017951
                 MOVE 0 TO APPO-PRE-TEL-1                               00017952
                 MOVE 0 TO APPO-NUM-TEL-1                               00017953
                 MOVE 0 TO APPO-PRE-TEL-2                               00017954
                 MOVE 0 TO APPO-NUM-TEL-2                               00017955
              ELSE                                                      00017956
                 DISPLAY  'ERRORE ACS035BT - ' ACS035-RETCODE           00017957
                      ' PER NDG ' TROT-NDG                              00017958
              END-IF                                                    00017959
           END-IF.                                                      00017960
       CNTRL-ACS035-EX.                                                 00017961
           EXIT.                                                        00017962
                                                                        00017963
       CONTROLLO-TEL.                                                   00017964
            IF SW-TEL1-TROVATO = 1 AND SW-TEL2-TROVATO = 1              00017965
               MOVE 1  TO SW-FINE-TEL                                   00017966
            END-IF.                                                     00017967
                                                                        00017968
            IF ACS035-COD-TEL-OUT(ACS035-IND) = 'TEL1'                  00017969
               MOVE ACS035-PREFISSO-OUT(ACS035-IND) TO APPO-PRE-TEL-1   00017970
               MOVE APPO-PRE-TEL-1                  TO PRE-TEL-1-RED    00017971
               MOVE '/'                             TO PRE-TRAT1-RED    00017972
               MOVE ACS035-NUMERO-OUT(ACS035-IND)   TO APPO-NUM-TEL-1   00017973
               MOVE APPO-NUM-TEL-1                  TO TEL-1-RED        00017974
               MOVE 1 TO SW-TEL1-TROVATO                                00017975
            ELSE                                                        00017976
               IF ACS035-COD-TEL-OUT(ACS035-IND) = 'TEL2'               00017977
               MOVE ACS035-PREFISSO-OUT(ACS035-IND) TO APPO-PRE-TEL-2   00017978
               MOVE APPO-PRE-TEL-2                  TO PRE-TEL-2-RED    00017979
               MOVE '/'                             TO PRE-TRAT2-RED    00017980
               MOVE ACS035-NUMERO-OUT(ACS035-IND)   TO APPO-NUM-TEL-2   00017981
               MOVE APPO-NUM-TEL-2                  TO TEL-2-RED        00017982
               MOVE 1 TO SW-TEL2-TROVATO                                00017983
               END-IF                                                   00017984
           END-IF.                                                      00017985
                                                                        00017986
       CONTROLLO-TEL-EX.                                                00017987
           EXIT.                                                        00017988
                                                                        00017989
       00225-SCRIVI-SCARTI.                                             00017990
           MOVE TROT-SERVIZIO   TO ARRAC845-SERVIZIO           .        00017991
           MOVE TROT-CATEGORIA  TO ARRAC845-CATEGORIA          .        00017992
           MOVE TROT-FILIALE    TO ARRAC845-FILIALE            .        00017993
           MOVE TROT-NUMERO     TO ARRAC845-NUMERO             .        00017994
           MOVE TROT-NDG        TO ARRAC845-NDG                .        00017995
           MOVE TROT-DATA-1     TO ARRAC845-DATA-1             .        00017996
           MOVE TROT-UTIL-1     TO ARRAC845-UTIL-1             .        00017997
           MOVE TROT-IMP-ACCR-1 TO ARRAC845-IMP-ACCR-1         .        00017998
           MOVE TROT-DATA-2     TO ARRAC845-DATA-2             .        00017999
           MOVE TROT-UTIL-2     TO ARRAC845-UTIL-2             .        00018000
           MOVE TROT-IMP-ACCR-2 TO ARRAC845-IMP-ACCR-2         .        00018001
           MOVE TROT-DATA-3     TO ARRAC845-DATA-3             .        00018002
           MOVE TROT-UTIL-3     TO ARRAC845-UTIL-3             .        00018003
           MOVE TROT-IMP-ACCR-3 TO ARRAC845-IMP-ACCR-3         .        00018004
           MOVE TROT-DATA-4     TO ARRAC845-DATA-4             .        00018005
           MOVE TROT-UTIL-4     TO ARRAC845-UTIL-4             .        00018006
           MOVE TROT-IMP-ACCR-4 TO ARRAC845-IMP-ACCR-4         .        00018007
           MOVE TROT-DATA-5     TO ARRAC845-DATA-5             .        00018008
           MOVE TROT-UTIL-5     TO ARRAC845-UTIL-5             .        00018009
           MOVE TROT-IMP-ACCR-5 TO ARRAC845-IMP-ACCR-5         .        00018010
           MOVE TROT-DATA-6     TO ARRAC845-DATA-6             .        00018011
           MOVE TROT-UTIL-6     TO ARRAC845-UTIL-6             .        00018012
           MOVE TROT-IMP-ACCR-6 TO ARRAC845-IMP-ACCR-6         .        00018013
           MOVE TROT-TOT-SEGN-CONS TO ARRAC845-TOT-SEGN-CONS   .        00018014
           MOVE TROT-TOT-SEGNALA TO ARRAC845-TOT-SEGNALA       .        00018015
           MOVE TROT-DATA-RIL   TO ARRAC845-DATA-RIL           .        00018016
           MOVE TROT-IMP-FIDO   TO ARRAC845-IMP-FIDO           .        00018017
           MOVE TROT-SETT-PROD  TO ARRAC845-SETT-PROD          .        00018018
           MOVE TROT-SALDCONT   TO ARRAC845-SALDCONT           .        00018019
           MOVE WS-TEL-1        TO ARRAC845-NUMTEL1            .        00018020
           MOVE WS-TEL-2        TO ARRAC845-NUMTEL2            .        00018021
           INSPECT WS-TEL-TANG1 REPLACING ALL '-' BY '/'       .        00018022
           MOVE WS-TEL-TANG1    TO ARRAC845-NUMTEL3            .        00018023
           INSPECT WS-TEL-TANG2 REPLACING ALL '-' BY '/'       .        00018024
           MOVE WS-TEL-TANG2    TO ARRAC845-NUMTEL4            .        00018025
           MOVE SPACES          TO ARRAC845-FILLER             .        00018026
                                                                        00018027
           IF ARRAC845-MOTIVO = SPACES                                  00018028
              MOVE  'NESSUNO NUMERO TELEF. VALIDO' TO ARRAC845-MOTIVO   00018029
              ADD 1 TO WS-NO-NUM-VALIDI                                 00018030
           ELSE                                                         00018031
              ADD 1 TO WS-NO-ACS108                                     00018032
           END-IF.                                                      00018033
                                                                        00018034
           WRITE REC-OUTANOM           FROM ARRAC845-REC.               00018035
                                                                        00018036
           INITIALIZE ARRAC845-REC.                                     00018037
                                                                        00018038
           IF FS-OUTANOM NOT EQUAL ZERO                                 00018039
              DISPLAY 'LABEL 00225-SCRIVI-SCARTI'                       00018040
              DISPLAY 'ERRORE ' FS-OUTANOM ' SU SCRITTURA OUTANOM'      00018041
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00018042
           END-IF.                                                      00018043
                                                                        00018044
           ADD 1 TO WS-COUNT-SCRITTI-ANOM.                              00018045
       00225-EX.                                                        00018046
           EXIT.                                                        00018047
                                                                        00018048
       00226-SCRIVI-OUT.                                                00018049
           MOVE TROT-SERVIZIO   TO ARRAC845-SERVIZIO           .        00018050
           MOVE TROT-CATEGORIA  TO ARRAC845-CATEGORIA          .        00018051
           MOVE TROT-FILIALE    TO ARRAC845-FILIALE            .        00018052
           MOVE TROT-NUMERO     TO ARRAC845-NUMERO             .        00018053
           MOVE TROT-NDG        TO ARRAC845-NDG                .        00018054
           MOVE TROT-DATA-1     TO ARRAC845-DATA-1             .        00018055
           MOVE TROT-UTIL-1     TO ARRAC845-UTIL-1             .        00018056
           MOVE TROT-IMP-ACCR-1 TO ARRAC845-IMP-ACCR-1         .        00018057
           MOVE TROT-DATA-2     TO ARRAC845-DATA-2             .        00018058
           MOVE TROT-UTIL-2     TO ARRAC845-UTIL-2             .        00018059
           MOVE TROT-IMP-ACCR-2 TO ARRAC845-IMP-ACCR-2         .        00018060
           MOVE TROT-DATA-3     TO ARRAC845-DATA-3             .        00018061
           MOVE TROT-UTIL-3     TO ARRAC845-UTIL-3             .        00018062
           MOVE TROT-IMP-ACCR-3 TO ARRAC845-IMP-ACCR-3         .        00018063
           MOVE TROT-DATA-4     TO ARRAC845-DATA-4             .        00018064
           MOVE TROT-UTIL-4     TO ARRAC845-UTIL-4             .        00018065
           MOVE TROT-IMP-ACCR-4 TO ARRAC845-IMP-ACCR-4         .        00018066
           MOVE TROT-DATA-5     TO ARRAC845-DATA-5             .        00018067
           MOVE TROT-UTIL-5     TO ARRAC845-UTIL-5             .        00018068
           MOVE TROT-IMP-ACCR-5 TO ARRAC845-IMP-ACCR-5         .        00018069
           MOVE TROT-DATA-6     TO ARRAC845-DATA-6             .        00018070
           MOVE TROT-UTIL-6     TO ARRAC845-UTIL-6             .        00018071
           MOVE TROT-IMP-ACCR-6 TO ARRAC845-IMP-ACCR-6         .        00018072
           MOVE TROT-TOT-SEGN-CONS TO ARRAC845-TOT-SEGN-CONS   .        00018073
           MOVE TROT-TOT-SEGNALA TO ARRAC845-TOT-SEGNALA       .        00018074
           MOVE TROT-DATA-RIL   TO ARRAC845-DATA-RIL           .        00018075
           MOVE TROT-IMP-FIDO   TO ARRAC845-IMP-FIDO           .        00018076
           MOVE TROT-SETT-PROD  TO ARRAC845-SETT-PROD          .        00018077
           MOVE TROT-SALDCONT   TO ARRAC845-SALDCONT           .        00018078
                                                                        00018079
           IF TELEFONO1 = 0                                             00018080
              MOVE SPACES       TO ARRAC845-NUMTEL1                     00018081
           ELSE                                                         00018082
              MOVE WS-TEL-1     TO ARRAC845-NUMTEL1                     00018083
           END-IF.                                                      00018084
                                                                        00018085
           IF TELEFONO2 = 0                                             00018086
              MOVE SPACES       TO ARRAC845-NUMTEL2                     00018087
           ELSE                                                         00018088
              MOVE WS-TEL-2     TO ARRAC845-NUMTEL2                     00018089
           END-IF.                                                      00018090
                                                                        00018091
           INSPECT WS-TEL-TANG1 REPLACING ALL '-' BY '/'       .        00018092
           MOVE WS-TEL-TANG1    TO ARRAC845-NUMTEL3            .        00018093
           INSPECT WS-TEL-TANG2 REPLACING ALL '-' BY '/'       .        00018094
           MOVE WS-TEL-TANG2    TO ARRAC845-NUMTEL4            .        00018095
           MOVE SPACES          TO ARRAC845-FILLER             .        00018096
           MOVE SPACES          TO ARRAC845-MOTIVO             .        00018097
                                                                        00018098
           WRITE REC-OUTROTA           FROM ARRAC845-REC.               00018099
                                                                        00018100
           IF FS-OUTROTA NOT EQUAL ZERO                                 00018101
              DISPLAY 'LABEL 00226-SCRIVI-OUT'                          00018102
              DISPLAY 'ERRORE ' FS-OUTROTA ' SU SCRITTURA OUTROTA'      00018103
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00018104
           END-IF.                                                      00018105
                                                                        00018106
           ADD 1 TO WS-COUNT-SCRITTI-OUT.                               00018107
                                                                        00018108
       00226-EX.                                                        00018109
           EXIT.                                                        00018110
                                                                        00018111
       00400-OPER-FINALI.                                               00018112
      *                                                                 00018113
           DISPLAY '*********************************************'.     00018114
           DISPLAY '*                                           *'.     00018115
           DISPLAY '*         RIEPILOGO FINALE ARRA845B         *'.     00018120
           DISPLAY '*                                           *'.     00018200
           DISPLAY '*********************************************'.     00018300
           DISPLAY '*                                           *'.     00018400
           DISPLAY '* REC. LETTI IN INPROTA..: ' WS-CTR-READ.           00018500
           DISPLAY '*                                           *'.     00018600
           DISPLAY '* REC. SCRITTI IN OUTROTA: ' WS-COUNT-SCRITTI-OUT.  00018700
           DISPLAY '*                                           *'.     00018800
           DISPLAY '* REC. SCRITTI IN OUTANOM: ' WS-COUNT-SCRITTI-ANOM. 00018810
           DISPLAY '* DI CUI___________________'.                       00018812
           DISPLAY '* NESSUN NUM.TEL.VALIDO  : ' WS-NO-NUM-VALIDI.      00018820
           DISPLAY '* NON TROVATO IN ANAGRAFE: ' WS-NO-ACS108    .      00018830
           DISPLAY '*********************************************'.     00018900
      *                                                                 00019000
           PERFORM 00500-CHIUSURE  THRU 00500-EX.                       00019100
      *                                                                 00019200
       00400-EX.                                                        00019300
           EXIT.                                                        00019400
                                                                        00019500
       00500-CHIUSURE.                                                  00019600
      *                                                                 00019700
           CLOSE INPROTA                                                00019800
                 OUTROTA                                                00019900
                 OUTANOM.                                               00019910
      *                                                                 00020000
           IF FS-INPROTA NOT = '00'                                     00020100
              DISPLAY 'ERRORE CHIUSURA INPROTA, STATUS = ' FS-INPROTA   00020200
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00020300
           END-IF.                                                      00020400
      *                                                                 00020500
           IF FS-OUTROTA NOT = '00'                                     00020600
              DISPLAY 'ERRORE CHIUSURA OUTROTA, STATUS = ' FS-OUTROTA   00020700
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00020800
           END-IF.                                                      00020900
      *                                                                 00021000
           IF FS-OUTANOM NOT = '00'                                     00021010
              DISPLAY 'ERRORE CHIUSURA OUTANOM, STATUS = ' FS-OUTANOM   00021020
              PERFORM 9999-GEST-ABEND THRU 9999-EX                      00021030
           END-IF.                                                      00021040
      *                                                                 00021050
       00500-EX.                                                        00021100
           EXIT.                                                        00021200
                                                                        00021300
       9999-GEST-ABEND.                                                 00021400
      *                                                                 00021500
           MOVE 'ILBOABN0' TO WS-PROGRAM.                               00021600
      *                                                                 00021700
           CALL WS-PROGRAM USING COMP-CODE.                             00021800
      *                                                                 00021900
       9999-EX.                                                         00022000
           EXIT.                                                        00022100
      *                                                                 00022200
      *                                                                 00022300
      *                                                                 00022400
