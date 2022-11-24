       IDENTIFICATION DIVISION.                                         00000100
      *********************************************************         00000200
      *                                                                 00000300
      *  NOME DEL PROGRAMMA        'ARRAB003'                           00000400
      *  ------------------------------------------------------         00000500
      *          GESTIONE FLUSSO PER EDWH: ESTRATTORE                   00000600
      *                                                                 00000700
      *                                                                 00000800
      *          GIORNALIERA   - SCTBTTAF                               00000900
      *********************************************************         00001000
      *                                                                 00001100
       PROGRAM-ID. ARRAB003.                                            00001200
       AUTHOR. ELSAGDATAMAT.                                            00001300
       ENVIRONMENT DIVISION.                                            00001400
       CONFIGURATION SECTION.                                           00001500
       SPECIAL-NAMES.                                                   00001600
           DECIMAL-POINT IS COMMA.                                      00001700
      *                                                                 00001800
       INPUT-OUTPUT SECTION.                                            00001900
       FILE-CONTROL.                                                    00002000
      *                                                                 00002100
           SELECT FILETTAF ASSIGN TO FILETTAF                           00002200
                   FILE STATUS STATUS-FILEIN.                           00002300
      *                                                                 00002400
           SELECT FILEEDWH ASSIGN TO FILEEDWH                           00002500
                   FILE STATUS STATUS-FILEOUT.                          00002600
      *                                                                 00002700
           SELECT FILESCA ASSIGN TO FILESCA                             00002800
                   FILE STATUS STATUS-FILESCA.                          00002900
                                                                        00003000
      *                                                                 00003100
       DATA DIVISION.                                                   00003200
       FILE SECTION.                                                    00003300
      *                                                                 00003400
       FD  FILETTAF                                                     00003500
           LABEL RECORDS STANDARD                                       00003600
           BLOCK 0 RECORDS.                                             00003700
       01  REC-TTAF                 PIC X(66).                          00003800
                                                                        00003900
      *                                                                 00004000
       FD  FILEEDWH                                                     00004100
           LABEL RECORDS STANDARD                                       00004200
           BLOCK 0 RECORDS.                                             00004300
       01  REC-EDWH                 PIC X(77).                          00004400
                                                                        00004500
      *                                                                 00004600
       FD  FILESCA                                                      00004700
           LABEL RECORDS STANDARD                                       00004800
           BLOCK 0 RECORDS.                                             00004900
       01  REC-SCARTI               PIC X(116).                         00005000
                                                                        00005100
      *********************************************************         00005200
       WORKING-STORAGE SECTION.                                         00005300
      *********************************************************         00005400
      *                                                                 00005500
      *                                                                 00005600
      **-------------------------------------------------------         00005700
      **   TRACCIATO RECORD FILE DI INPUT.                              00005800
      **-------------------------------------------------------         00005900
      *                                                                 00006000
          COPY ARRAC03B.                                                00006100
                                                                        00006200
      *                                                                 00006300
      **-------------------------------------------------------         00006400
      **   TRACCIATO RECORD FILE DI OUTPUT.                             00006500
      **-------------------------------------------------------         00006600
      *                                                                 00006700
          COPY ARRAC03C.                                                00006800
      *                                                                 00006900
      **-------------------------------------------------------         00007000
      **   TRACCIATO RECORD FILE DI SCARTI.                             00007100
      **-------------------------------------------------------         00007200
      *                                                                 00007300
          COPY ARRAC03D.                                                00007400
      **-------------------------------------------------------         00007500
                                                                        00007600
      **-------------------------------------------------------         00007700
      *                                                                 00007800
       01  W-SQLCODE                PIC  9(003) VALUE ZERO.             00007900
       01  WS-DATA                  PIC  9(008) VALUE ZEROES.           00008000
       01  SK-DATA                  PIC S9(8) COMP-3.                   00008100
       01  FINE-TAB-TRIC            PIC  X(002) VALUE SPACES.           00008200
       01  FINE-TAB-TSTO            PIC  X(002) VALUE SPACES.           00008300
       01  FINE-TAB-TTAF            PIC  X(002) VALUE SPACES.           00008310
       01  CTR-SCRITTI-Z            PIC ZZZ.ZZ9.                        00008400
       01  CTR-SCRITTI              PIC 9(10)      VALUE 0.             00008500
       01  CTR-SCARTI-Z             PIC ZZZ.ZZ9.                        00008600
       01  CTR-SCARTI               PIC 9(10)      VALUE 0.             00008700
       01  CTR-READ                 PIC 9(10)      VALUE 0.             00008800
       01  CTR-READ-Z               PIC ZZZ.ZZ9.                        00008810
       01  CTR-ELAB                 PIC 9(10)      VALUE 0.             00008900
       01  CTR-ELAB-Z               PIC ZZZ.ZZ9.                        00009000
       01  CTR-ELAB-ATT             PIC 9(10)      VALUE 0.             00009010
       01  CTR-ELAB-ATT-Z           PIC ZZZ.ZZ9.                        00009020
       01  CTR-ELAB-EST             PIC 9(10)      VALUE 0.             00009030
       01  CTR-ELAB-EST-Z           PIC ZZZ.ZZ9.                        00009040
       01  CTR-SEL-TTAF             PIC 9(10)      VALUE 0.             00009100
       01  CTR-SEL-TTAF-Z           PIC ZZZ.ZZ9.                        00009200
       01  CTR-SEL-TRIC             PIC 9(10)      VALUE 0.             00009210
       01  CTR-SEL-TRIC-Z           PIC ZZZ.ZZ9.                        00009220
       01  CTR-SEL-TSTO             PIC 9(10)      VALUE 0.             00009300
       01  CTR-SEL-TSTO-Z           PIC ZZZ.ZZ9.                        00009400
       01  FINE-FILE                PIC XX         VALUE 'NO'.          00009500
       01  CTR-RIGA                 PIC 9(10)      VALUE 0.             00009600
      *                                                                 00009700
       01  W-IMP-TTAF               PIC 9(11).                          00009710
      *                                                                 00009711
       01  W-IMPORTO                PIC 9(11).                          00009712
       01  W-IMPORTO-A REDEFINES W-IMPORTO PIC X(11).                   00009713
      *                                                                 00009714
       01  W-IMPORTO-R REDEFINES W-IMPORTO-A.                           00009715
           05 W-IMP-INT             PIC 9(08).                          00009716
           05 W-IMP-PUNTO           PIC X(01).                          00009717
           05 W-IMP-DEC             PIC 9(02).                          00009718
      *                                                                 00009720
      *                                                                 00009730
       01  W-IMPORTO15              PIC 9(13)V99.                       00009740
       01  W-IMPORTO15-R REDEFINES W-IMPORTO15.                         00009741
           05 W-IMP15-INT           PIC 9(13).                          00009742
           05 W-IMP15-DEC           PIC 9(02).                          00009744
      *                                                                 00009790
      *                                                                 00009791
       01  W-DES1                   PIC X(30).                          00009792
       01  W-DES2                   PIC X(30).                          00009793
      *                                                                 00009800
       01  STATUS-FILEIN            PIC X(02).                          00009900
       01  STATUS-FILEOUT           PIC X(02).                          00010000
       01  STATUS-FILESCA           PIC X(02).                          00010100
                                                                        00010200
                                                                        00010300
      *********************************************************         00010400
      *********************************************************         00010500
      *    AREE DI COMODO PER SEGNALAZIONE ERRORE DB2                   00010600
      *********************************************************         00010700
       01  WS-SQLCODE                       PIC ----9.                  00010800
                                                                        00010900
      *********************************************************         00011000
      *********************************************************         00011100
      *    SCHEDA PARAMETRO: TIPO ELABORAZIONE ('A', 'E')               00011200
      *********************************************************         00011300
       01 PARAM-SCHEDA.                                                 00011400
          05 SK-TIPO-ELAB                   PIC X(1).                   00011500
      *                                                                 00011600
      ********************                                              00011700
      * INCLUDE DELL'SQL *                                              00011800
      ********************                                              00011900
           EXEC SQL                                                     00012000
                INCLUDE SQLCA                                           00012100
           END-EXEC.                                                    00012200
                                                                        00012300
      ******************************                                    00012400
      * INCLUDE DELLE TABELLE DB2  *                                    00012500
      ******************************                                    00012600
           EXEC SQL                                                     00012700
                INCLUDE SCTBTRIC                                        00012800
           END-EXEC.                                                    00012900
                                                                        00013000
           EXEC SQL                                                     00013100
                INCLUDE SCTBTSTO                                        00013200
           END-EXEC.                                                    00013300
                                                                        00013310
           EXEC SQL                                                     00013320
                INCLUDE SCTBTTAF                                        00013330
           END-EXEC.                                                    00013340
                                                                        00013400
      ***********************                                           00013500
      * CAMPI DELLA CEE3ABD *                                           00013600
      ***********************                                           00013700
      *                                                                 00013800
       01 CEE3ABD                           PIC X(8)  VALUE 'CEE3ABD'.  00013900
       01 TIMING                            PIC S9(4) BINARY.           00014000
       01 ABDCODE                           PIC S9(4) BINARY.           00014100
      *                                                                 00014200
      *                                                                 00014300
      ***************************************                           00014400
      * P R O C E D U R E   D I V I S I O N                             00014500
      ***************************************                           00014600
       PROCEDURE DIVISION.                                              00014700
       MAIN.                                                            00014800
      *                                                                 00014900
           PERFORM INIZIO-PROG        THRU INIZIO-PROG-EX.              00015000
      *                                                                 00015100
           PERFORM ELABORA            THRU ELABORA-EX                   00015200
                                UNTIL FINE-FILE  = 'SI'.                00015300
      *                                                                 00015400
           PERFORM FINE-PGM           THRU   FINE-PGM-EX.               00015500
      *                                                                 00015600
           STOP RUN.                                                    00015700
      *                                                                 00015800
      *============                                                     00015900
       INIZIO-PROG.                                                     00016000
      *============                                                     00016100
      *                                                                 00016200
           INITIALIZE REC-EX003.                                        00016300
                                                                        00016310
           DISPLAY '*------------------------------------------*'       00016320
           DISPLAY '*        INIZIO PROGRAMMA ARRAB003         *'       00016340
           DISPLAY '*------------------------------------------*'       00016350
      *                                                                 00016400
           OPEN  INPUT  FILETTAF.                                       00016500
      *                                                                 00016600
           IF STATUS-FILEIN NOT = '00'                                  00016700
              DISPLAY '********ATTENZIONE************'                  00016800
              DISPLAY '*                            *'                  00016900
              DISPLAY '*    PROGRAMMA ARRAB003      *'                  00017000
              DISPLAY '*                            *'                  00017100
              DISPLAY '* ERRORE APERTURA FILE INPUT *'                  00017200
              DISPLAY '*                            *'                  00017300
              DISPLAY '*  FILE STATUS : ' STATUS-FILEIN                 00017400
              DISPLAY '*                            *'                  00017500
              DISPLAY '******************************'                  00017600
              PERFORM ABEND     THRU ABEND-EX                           00017700
           END-IF.                                                      00017800
      *                                                                 00017900
           OPEN  OUTPUT  FILEEDWH.                                      00018000
      *                                                                 00018100
           IF STATUS-FILEOUT NOT = '00'                                 00018200
              DISPLAY '********ATTENZIONE************'                  00018300
              DISPLAY '*                            *'                  00018400
              DISPLAY '*    PROGRAMMA ARRAB003      *'                  00018500
              DISPLAY '*                            *'                  00018600
              DISPLAY '* ERRORE APERTURA FILE OUTPUT*'                  00018700
              DISPLAY '*                            *'                  00018800
              DISPLAY '*  FILE STATUS : ' STATUS-FILEOUT                00018900
              DISPLAY '*                            *'                  00019000
              DISPLAY '******************************'                  00019100
              PERFORM ABEND     THRU ABEND-EX                           00019200
           END-IF.                                                      00019300
      *                                                                 00019400
           OPEN  OUTPUT  FILESCA.                                       00019500
      *                                                                 00019600
           IF STATUS-FILESCA NOT = '00'                                 00019700
              DISPLAY '********ATTENZIONE************'                  00019800
              DISPLAY '*                            *'                  00019900
              DISPLAY '*    PROGRAMMA ARRAB003      *'                  00020000
              DISPLAY '*                            *'                  00020100
              DISPLAY '* ERRORE APERTURA FILE SCARTI*'                  00020200
              DISPLAY '*                            *'                  00020300
              DISPLAY '*  FILE STATUS : ' STATUS-FILESCA                00020400
              DISPLAY '*                            *'                  00020500
              DISPLAY '******************************'                  00020600
              PERFORM ABEND     THRU ABEND-EX                           00020700
           END-IF.                                                      00020800
                                                                        00020900
      *                                                                 00021000
           ACCEPT WS-DATA                FROM DATE YYYYMMDD.            00021010
           ACCEPT PARAM-SCHEDA           FROM SYSIN.                    00021100
      *                                                                 00021200
           IF PARAM-SCHEDA NOT = ('A' AND 'E')                          00021300
              DISPLAY '********ATTENZIONE************'                  00021400
              DISPLAY '*                            *'                  00021500
              DISPLAY '*    PROGRAMMA ARRAB003      *'                  00021600
              DISPLAY '*                            *'                  00021700
              DISPLAY '* SCHEDA PARAMETRO ERRATA    *'                  00021800
              DISPLAY '*                            *'                  00021900
              DISPLAY '*  SCHEDA   : ' PARAM-SCHEDA                     00022000
              DISPLAY '*                            *'                  00022100
              DISPLAY '******************************'                  00022200
              PERFORM ABEND     THRU ABEND-EX                           00022300
           END-IF.                                                      00022400
                                                                        00022500
           PERFORM READ-TTAF          THRU READ-TTAF-EX.                00022600
                                                                        00022700
      *                                                                 00022800
      *===============                                                  00022900
       INIZIO-PROG-EX.                                                  00023000
           EXIT.                                                        00023100
      *===============                                                  00023200
      *                                                                 00023300
      *========                                                         00023400
       ELABORA.                                                         00023500
      *========                                                         00023600
      *                                                                 00023700
           INITIALIZE                         FINE-TAB-TRIC             00023800
                                              FINE-TAB-TSTO             00023900
                                              FINE-TAB-TTAF             00023910
                                              REC-OU003                 00024000
                                              REC-SCA003                00024100
                                              W-IMP-TTAF                00024101
                                              DCLSCTBTRIC               00024110
                                              DCLSCTBTSTO               00024120
                                              DCLSCTBTTAF               00024130
                                                                        00024200
      *                                                                 00024210
MP0511     IF     SK-TIPO-ELAB    =   'E'                               00024220
MP0511            PERFORM ELAB-TAB-TIPO-EST   THRU ELAB-TAB-TIPO-EST-EX 00024221
MP0511     END-IF                                                       00024222
      *                                                                 00024230
           INITIALIZE                         FINE-TAB-TRIC             00024240
                                              FINE-TAB-TSTO             00024250
                                              DCLSCTBTRIC               00024260
                                              DCLSCTBTSTO               00024270
                                                                        00024280
           PERFORM ELAB-TAB-TIPO-RS      THRU ELAB-TAB-TIPO-RS-EX       00024300
           IF      FINE-TAB-TRIC             = 'SI'                     00024301
           AND     FINE-TAB-TSTO             = 'SI'                     00024302
                   PERFORM WRITE-OUT-SCA  THRU WRITE-OUT-SCA-EX         00024303
                   PERFORM READ-TTAF      THRU READ-TTAF-EX             00024304
                   GO TO ELABORA-EX                                     00024305
           END-IF                                                       00024306
           INITIALIZE                         FINE-TAB-TRIC             00024310
                                              FINE-TAB-TSTO             00024320
                                              DCLSCTBTRIC               00024330
                                              DCLSCTBTSTO               00024340
                                                                        00024400
      *    VARIATE SPEC. FUNZIONALI 03/05/2011                          00024500
      *    PERFORM ELAB-TAB-TIPO-PUN     THRU ELAB-TAB-TIPO-PUN-EX      00024501
      *    IF      FINE-TAB-TRIC             = 'SI'                     00024502
      *    AND     FINE-TAB-TSTO             = 'SI'                     00024503
      *            PERFORM WRITE-OUT-SCA  THRU WRITE-OUT-SCA-EX         00024504
      *            PERFORM READ-TTAF      THRU READ-TTAF-EX             00024505
      *            GO TO ELABORA-EX                                     00024506
      *    END-IF                                                       00024507
      *                                                                 00024508
           INITIALIZE                         FINE-TAB-TRIC             00024509
                                              FINE-TAB-TSTO             00024510
                                              DCLSCTBTRIC               00024511
                                              DCLSCTBTSTO               00024512
                                                                        00024513
           PERFORM ELAB-TAB-TIPO-ESITO   THRU ELAB-TAB-TIPO-ESITO-EX    00024520
           IF      FINE-TAB-TRIC             = 'SI'                     00024530
           AND     FINE-TAB-TSTO             = 'SI'                     00024540
                   PERFORM WRITE-OUT-SCA  THRU WRITE-OUT-SCA-EX         00024550
                   PERFORM READ-TTAF      THRU READ-TTAF-EX             00024560
                   GO TO ELABORA-EX                                     00024570
           END-IF                                                       00024580
                                                                        00025300
           PERFORM WRITE-OUT-EDWH        THRU WRITE-OUT-EDWH-EX         00025310
                                                                        00025320
           PERFORM READ-TTAF             THRU READ-TTAF-EX.             00025400
                                                                        00025500
      *                                                                 00025600
      *===========                                                      00025700
       ELABORA-EX.                                                      00025800
           EXIT.                                                        00025900
      *===========                                                      00026000
      *                                                                 00026100
      *==================                                               00026200
MP0511 ELAB-TAB-TIPO-EST.                                               00026300
      *==================                                               00026400
      *                                                                 00026500
      *   ELABORAZIONE DELLE PRATICHE ESTINTE                           00026600
      *                                                                 00026601
           MOVE   EX003-FILIALE        TO  TTAF-FILIALE                 00026620
           MOVE   EX003-NUMERO         TO  TTAF-NUMERO                  00026630
           MOVE   EX003-SERVIZIO       TO  TTAF-SERVIZIO                00026640
           MOVE   EX003-CATEGORIA      TO  TTAF-CATEGORIA               00026650
           MOVE   EX003-NDG            TO  TTAF-NDG                     00026660
           MOVE   EX003-STATO          TO  TTAF-STATO                   00026670
      *                                                                 00026679
      **   DISPLAY 'ELAB-TAB-TIPO-EST>  '                               00026680
           PERFORM SEL-SCTBTTAF    THRU SEL-SCTBTTAF-EX                 00026700
      **   DISPLAY 'ELAB-TAB-TIPO-EST>  ' FINE-TAB-TTAF                 00026710
                                                                        00026800
           IF  FINE-TAB-TTAF       NOT    = 'SI'                        00026801
      *                                                                 00026802
      * VALORIZZA AREA OUTPUT                                           00026803
      *                                                                 00026804
               MOVE   ZERO             TO   W-IMPORTO                   00026807
               MOVE   ZERO             TO   W-IMP-INT                   00026808
               MOVE   ZERO             TO   W-IMP-DEC                   00026809
               MOVE   ZERO             TO   W-IMP15-INT                 00026810
               MOVE   ZERO             TO   W-IMP15-DEC                 00026811
               MOVE   '.'              TO   W-IMP-PUNTO                 00026812
               MOVE   TTAF-LIM-FIDO                                     00026814
                                       TO   W-IMPORTO15                 00026815
               MOVE   W-IMP15-INT      TO   W-IMP-INT                   00026817
               MOVE   W-IMP15-DEC      TO   W-IMP-DEC                   00026818
               MOVE   W-IMPORTO        TO   W-IMP-TTAF                  00026819
      **       DISPLAY 'W-IMP-TTAF       >  ' W-IMP-TTAF                00026820
           END-IF.                                                      00026830
      *                                                                 00027243
      *                                                                 00027300
      *=====================                                            00027400
MP0511 ELAB-TAB-TIPO-EST-EX.                                            00027410
           EXIT.                                                        00027600
      *=====================                                            00027700
      *                                                                 00027701
      *================                                                 00027702
       ELAB-TAB-TIPO-RS.                                                00027703
      *================                                                 00027704
      *                                                                 00027705
      *   ELABORAZIONE DELLE PRATICHE DI RICHIESTA = "RS"               00027706
      *                                                                 00027707
           MOVE   99999999             TO  TRIC-DT-VAL-A                00027708
           MOVE   EX003-FILIALE        TO  TRIC-FILIALE                 00027709
           MOVE   EX003-NUMERO         TO  TRIC-NUMERO                  00027710
           MOVE   EX003-SERVIZIO       TO  TRIC-SERVIZIO                00027711
           MOVE   EX003-CATEGORIA      TO  TRIC-CATEGORIA               00027712
           MOVE   EX003-NDG            TO  TRIC-NDG-PF                  00027713
           MOVE   'RS'                 TO  TRIC-TIP-ATTIV.              00027714
      *                                                                 00027715
      **   DISPLAY 'ELAB-TAB-TIPO-RS>   '                               00027716
           PERFORM SEL-SCTBTRIC    THRU SEL-SCTBTRIC-EX                 00027717
                                                                        00027718
           IF  FINE-TAB-TRIC       NOT    = 'SI'                        00027719
      *                                                                 00027720
      * VALORIZZA AREA OUTPUT                                           00027721
      *                                                                 00027722
               MOVE   TRIC-DT-RIC-ATT  TO   OU003-DT-RICH               00027723
                                                                        00027724
               MOVE   ZERO             TO   W-IMPORTO                   00027725
               MOVE   ZERO             TO   W-IMP-INT                   00027726
               MOVE   ZERO             TO   W-IMP-DEC                   00027727
               MOVE   ZERO             TO   W-IMP15-INT                 00027728
               MOVE   ZERO             TO   W-IMP15-DEC                 00027729
               MOVE   '.'              TO   W-IMP-PUNTO                 00027730
               MOVE   TRIC-LIM-FIDO                                     00027731
                                       TO   W-IMPORTO15                 00027732
               MOVE   W-IMP15-INT      TO   W-IMP-INT                   00027733
               MOVE   W-IMP15-DEC      TO   W-IMP-DEC                   00027734
               MOVE   W-IMPORTO        TO   OU003-IMP-RICH              00027735
           END-IF                                                       00027736
                                                                        00027737
           IF  FINE-TAB-TRIC              = 'SI'                        00027738
      *                                                                 00027739
      * PROSEGUE A VERIFICARE TSTO  ....                                00027740
      *                                                                 00027741
               MOVE   99999999         TO  TSTO-DT-VAL-A                00027742
               MOVE   EX003-FILIALE    TO  TSTO-FILIALE                 00027743
               MOVE   EX003-NUMERO     TO  TSTO-NUMERO                  00027744
               MOVE   EX003-SERVIZIO   TO  TSTO-SERVIZIO                00027745
               MOVE   EX003-CATEGORIA  TO  TSTO-CATEGORIA               00027746
               MOVE   EX003-NDG        TO  TSTO-NDG-PF                  00027747
               MOVE   'RS'             TO  TSTO-TIP-ATTIV               00027748
               PERFORM SEL-SCTBTSTO    THRU SEL-SCTBTSTO-EX             00027749
                                                                        00027750
               IF  FINE-TAB-TSTO      NOT     = 'SI'                    00027751
      *                                                                 00027752
      * VALORIZZAZIONE RECORD DI OUTPUT                                 00027753
      *                                                                 00027754
                   MOVE   TSTO-DT-RIC-ATT  TO   OU003-DT-RICH           00027755
                                                                        00027756
                   MOVE   ZERO             TO   W-IMPORTO               00027757
                   MOVE   ZERO             TO   W-IMP-INT               00027758
                   MOVE   ZERO             TO   W-IMP-DEC               00027759
                   MOVE   ZERO             TO   W-IMP15-INT             00027760
                   MOVE   ZERO             TO   W-IMP15-DEC             00027761
                   MOVE   '.'              TO   W-IMP-PUNTO             00027762
                   MOVE   TSTO-LIM-FIDO                                 00027763
                                           TO   W-IMPORTO15             00027764
                   MOVE   W-IMP15-INT      TO   W-IMP-INT               00027765
                   MOVE   W-IMP15-DEC      TO   W-IMP-DEC               00027766
                   MOVE   W-IMPORTO        TO   OU003-IMP-RICH          00027767
                                                                        00027768
               END-IF                                                   00027769
           END-IF                                                       00027770
      *                                                                 00027771
           INITIALIZE W-DES1 W-DES2                                     00027772
      *                                                                 00027773
           IF      FINE-TAB-TRIC             = 'SI'                     00027774
                   MOVE    'TRIC'                                       00027775
                                            TO W-DES1                   00027776
           END-IF                                                       00027777
           IF      FINE-TAB-TSTO             = 'SI'                     00027778
                   MOVE    'TSTO'                                       00027779
                                            TO W-DES2                   00027780
           END-IF                                                       00027781
           IF      FINE-TAB-TRIC             = 'SI'                     00027782
           AND     FINE-TAB-TSTO             = 'SI'                     00027783
                   STRING 'PRATICA ANOMALA IN TABELLA: '                00027784
                          W-DES1 ' ' W-DES2                             00027785
                                     DELIMITED BY SIZE                  00027786
                          INTO SCA003-DES-ANOM                          00027787
           END-IF.                                                      00027788
      *                                                                 00027789
      *                                                                 00027790
      *===================                                              00027791
       ELAB-TAB-TIPO-RS-EX.                                             00027792
           EXIT.                                                        00027793
      *===================                                              00027794
      *                                                                 00027795
      *===================                                              00027796
       ELAB-TAB-TIPO-PUN.                                               00027797
      *===================                                              00027798
      *                                                                 00027799
      *   ELABORAZIONE DELLE PRATICHE DI RICHIESTA = PUNTUALE           00027800
           MOVE   99999999             TO  TRIC-DT-VAL-A                00027801
           MOVE   EX003-FILIALE        TO  TRIC-FILIALE                 00027802
           MOVE   EX003-NUMERO         TO  TRIC-NUMERO                  00027803
           MOVE   EX003-SERVIZIO       TO  TRIC-SERVIZIO                00027804
           MOVE   EX003-CATEGORIA      TO  TRIC-CATEGORIA               00027810
           MOVE   EX003-NDG            TO  TRIC-NDG-PF                  00027820
           MOVE   EX003-STATO          TO  TRIC-TIP-ATTIV               00027830
      *                                                                 00027840
      **   DISPLAY 'ELAB-TAB-TIPO-PUN>  '                               00027841
           PERFORM SEL-SCTBTRIC    THRU SEL-SCTBTRIC-EX                 00027850
                                                                        00027860
      *    IF  FINE-TAB-TRIC         NOT  = 'SI'                        00027870
      *                                                                 00027871
      * VALORIZZA AREA OUTPUT                                           00027872
      *                                                                 00027873
      *        MOVE   TRIC-ESITO       TO   OU003-COD-ESITO             00027894
      *        MOVE   TRIC-DT-RIC-ATT  TO   OU003-DT-ESITO              00027896
      *    END-IF                                                       00027898
                                                                        00027900
           IF  FINE-TAB-TRIC              = 'SI'                        00027901
      *                                                                 00027902
      * PROSEGUE A VERIFICARE TSTO  ....                                00027903
      *                                                                 00027904
               MOVE   99999999         TO  TSTO-DT-VAL-A                00027905
               MOVE   EX003-FILIALE    TO  TSTO-FILIALE                 00027906
               MOVE   EX003-NUMERO     TO  TSTO-NUMERO                  00027907
               MOVE   EX003-SERVIZIO   TO  TSTO-SERVIZIO                00027908
               MOVE   EX003-CATEGORIA  TO  TSTO-CATEGORIA               00027909
               MOVE   EX003-NDG        TO  TSTO-NDG-PF                  00027910
               MOVE   EX003-STATO      TO  TSTO-TIP-ATTIV               00027911
               PERFORM SEL-SCTBTSTO    THRU SEL-SCTBTSTO-EX             00027912
                                                                        00027913
      *        IF  FINE-TAB-TSTO      NOT     = 'SI'                    00027914
      *                                                                 00027915
      * VALORIZZAZIONE RECORD DI OUTPUT                                 00027916
      *                                                                 00027920
      *            MOVE   TSTO-ESITO       TO   OU003-COD-ESITO         00027929
      *            MOVE   TSTO-DT-RIC-ATT  TO   OU003-DT-ESITO          00027930
      *        END-IF                                                   00027932
           END-IF                                                       00027933
      *                                                                 00027934
           INITIALIZE W-DES1 W-DES2                                     00027935
      *                                                                 00027936
           IF      FINE-TAB-TRIC             = 'SI'                     00027937
                   MOVE    'TRIC'                                       00027938
                                            TO W-DES1                   00027939
           END-IF                                                       00027940
           IF      FINE-TAB-TSTO             = 'SI'                     00027941
                   MOVE    'TSTO'                                       00027942
                                            TO W-DES2                   00027943
           END-IF                                                       00027944
           IF      FINE-TAB-TRIC             = 'SI'                     00027945
           AND     FINE-TAB-TSTO             = 'SI'                     00027946
                   STRING 'PRATICA ANOMALA IN TABELLA: '                00027947
                          W-DES1 ' ' W-DES2                             00027948
                                     DELIMITED BY SIZE                  00027949
                          INTO SCA003-DES-ANOM                          00027950
           END-IF.                                                      00027962
      *                                                                 00027963
      *                                                                 00027994
      *====================                                             00027995
       ELAB-TAB-TIPO-PUN-EX.                                            00027996
           EXIT.                                                        00027997
      *====================                                             00027998
      *                                                                 00027999
      *===================                                              00028000
       ELAB-TAB-TIPO-ESITO.                                             00028001
      *===================                                              00028002
      *                                                                 00028003
      *   ELABORAZIONE DELLE PRATICHE DI TIPO ESITO = 'OK'              00028004
           MOVE   99999999             TO  TRIC-DT-VAL-A                00028005
           MOVE   EX003-FILIALE        TO  TRIC-FILIALE                 00028006
           MOVE   EX003-NUMERO         TO  TRIC-NUMERO                  00028007
           MOVE   EX003-SERVIZIO       TO  TRIC-SERVIZIO                00028008
           MOVE   EX003-CATEGORIA      TO  TRIC-CATEGORIA               00028009
           MOVE   EX003-NDG            TO  TRIC-NDG-PF                  00028010
           MOVE   'OK'                 TO  TRIC-ESITO.                  00028011
      *                                                                 00028012
      **   DISPLAY 'ELAB-TAB-TIPO-ESITO> '                              00028013
           PERFORM SEL-SCTBTRIC-ESITO  THRU SEL-SCTBTRIC-ESITO-EX       00028014
                                                                        00028015
           IF  FINE-TAB-TRIC          NOT = 'SI'                        00028016
      *                                                                 00028017
      * VALORIZZAZIONE RECORD DI OUTPUT                                 00028018
      *                                                                 00028019
               MOVE   TRIC-SETT-PROD   TO   OU003-COD-SETT-PROD         00028020
           END-IF                                                       00028021
                                                                        00028022
           IF  FINE-TAB-TRIC              = 'SI'                        00028023
      *                                                                 00028024
      * VALORIZZAZIONE RECORD DI OUTPUT                                 00028025
      *                                                                 00028026
               MOVE   99999999         TO  TSTO-DT-VAL-A                00028027
               MOVE   EX003-FILIALE    TO  TSTO-FILIALE                 00028028
               MOVE   EX003-NUMERO     TO  TSTO-NUMERO                  00028029
               MOVE   EX003-SERVIZIO   TO  TSTO-SERVIZIO                00028030
               MOVE   EX003-CATEGORIA  TO  TSTO-CATEGORIA               00028031
               MOVE   EX003-NDG        TO  TSTO-NDG-PF                  00028032
               MOVE   'OK'             TO  TSTO-ESITO                   00028033
               PERFORM SEL-SCTBTSTO-ESITO  THRU SEL-SCTBTSTO-ESITO-EX   00028034
                                                                        00028035
               IF  FINE-TAB-TSTO       NOT    = 'SI'                    00028036
      *                                                                 00028037
      * VALORIZZAZIONE RECORD DI OUTPUT                                 00028038
      *                                                                 00028039
                   MOVE   TSTO-SETT-PROD   TO   OU003-COD-SETT-PROD     00028040
               END-IF                                                   00028048
           END-IF                                                       00028049
      *                                                                 00028050
           INITIALIZE W-DES1 W-DES2                                     00028051
      *                                                                 00028052
           IF      FINE-TAB-TRIC             = 'SI'                     00028053
                   MOVE    'TRIC'                                       00028054
                                            TO W-DES1                   00028055
           END-IF                                                       00028056
           IF      FINE-TAB-TSTO             = 'SI'                     00028057
                   MOVE    'TSTO'                                       00028058
                                            TO W-DES2                   00028059
           END-IF                                                       00028060
           IF      FINE-TAB-TRIC             = 'SI'                     00028061
           AND     FINE-TAB-TSTO             = 'SI'                     00028062
                   STRING 'PRATICA ANOMALA IN TABELLA: '                00028063
                          W-DES1 ' ' W-DES2                             00028064
                                     DELIMITED BY SIZE                  00028065
                          INTO SCA003-DES-ANOM                          00028066
           END-IF.                                                      00028069
      *                                                                 00028070
      *                                                                 00028080
      *                                                                 00028109
      *======================                                           00028110
       ELAB-TAB-TIPO-ESITO-EX.                                          00028111
           EXIT.                                                        00028112
      *======================                                           00028113
                                                                        00028114
                                                                        00028115
      *=============                                                    00028116
       READ-TTAF.                                                       00028120
      *=============                                                    00028200
      *                                                                 00028300
      * READ FILE                                                       00028400
           READ FILETTAF      INTO REC-EX003                            00028500
             AT END                                                     00028600
               MOVE 'SI'        TO FINE-FILE                            00028700
             NOT AT END                                                 00028800
               ADD   1          TO CTR-READ                             00028900
           END-READ.                                                    00029000
                                                                        00029100
           IF  STATUS-FILEIN EQUAL '10' AND CTR-READ EQUAL 0            00029200
               DISPLAY '**----------------------------------**'         00029300
               DISPLAY '**      FILE  SCTBTTAF VUOTO        **'         00029400
               DISPLAY '**----------------------------------**'         00029500
           END-IF.                                                      00029700
      *                                                                 00029800
      *===========                                                      00029900
       READ-TTAF-EX.                                                    00030000
           EXIT.                                                        00030100
      *===========                                                      00030200
      *=============                                                    00030300
       WRITE-OUT-EDWH.                                                  00030400
      *=============                                                    00030500
      *                                                                 00030600
      *                                                                 00030700
      * VALORIZZAZIONE RECORD DI OUTPUT                                 00030800
      *                                                                 00030900
           ADD    1                       TO   CTR-ELAB                 00031000
      *                                                                 00031010
           IF     SK-TIPO-ELAB    =   'A'                               00031020
                  ADD    1                TO   CTR-ELAB-ATT             00031030
                  MOVE   EX003-NUMERO     TO   OU003-NUMERO             00031100
                  MOVE   EX003-FILIALE    TO   OU003-FRAZ               00031200
                                                                        00031500
                  MOVE   ZERO             TO   W-IMPORTO                00031600
                  MOVE   ZERO             TO   W-IMP-INT                00031601
                  MOVE   ZERO             TO   W-IMP-DEC                00031602
                  MOVE   '.'              TO   W-IMP-PUNTO              00031603
                  MOVE   EX003-LIM-FIDO-INT   TO   W-IMP-INT            00031610
                  MOVE   EX003-LIM-FIDO-DEC   TO   W-IMP-DEC            00031620
                  MOVE   W-IMPORTO        TO   OU003-ULT-FIDO           00031650
                                                                        00031660
                  MOVE   EX003-DT-VAL-DA  TO   OU003-DT-ULT-FIDO        00031700
                                                                        00031710
                  MOVE   'OK'             TO   OU003-COD-ESITO          00031720
                  MOVE   EX003-DT-VAL-DA  TO   OU003-DT-ESITO           00031730
                                                                        00031740
                  MOVE   ZERO             TO   OU003-DT-EST             00031800
                  MOVE   SPACE            TO   OU003-CAUS-EST           00031900
           END-IF                                                       00032100
      *                                                                 00032200
           IF     SK-TIPO-ELAB    =   'E'                               00032300
                  ADD    1                TO   CTR-ELAB-EST             00032310
                  MOVE   EX003-NUMERO     TO   OU003-NUMERO             00032320
                  MOVE   EX003-FILIALE    TO   OU003-FRAZ               00032330
                  MOVE   EX003-DT-VAL-DA  TO   OU003-DT-ULT-FIDO        00032400
                  MOVE   EX003-DT-VAL-DA  TO   OU003-DT-EST             00032410
                  MOVE   EX003-STATO      TO   OU003-CAUS-EST           00032420
MP0511*                                                                 00032501
MP0511*           MOVE   ZERO             TO   W-IMPORTO                00032502
MP0511*           MOVE   ZERO             TO   W-IMP-INT                00032503
MP0511*           MOVE   ZERO             TO   W-IMP-DEC                00032504
MP0511*           MOVE   '.'              TO   W-IMP-PUNTO              00032510
MP0511*           MOVE   EX003-LIM-FIDO-INT   TO   W-IMP-INT            00032531
MP0511*           MOVE   EX003-LIM-FIDO-DEC   TO   W-IMP-DEC            00032532
MP0511*           MOVE   ZERO                 TO   W-IMP-INT            00032533
MP0511*           MOVE   ZERO                 TO   W-IMP-DEC            00032534
MP0511            MOVE   W-IMP-TTAF           TO   OU003-ULT-FIDO       00032535
                                                                        00032542
                  MOVE   'OK'             TO   OU003-COD-ESITO          00032550
                  MOVE   EX003-DT-VAL-DA  TO   OU003-DT-ESITO           00032560
           END-IF                                                       00033200
                                                                        00033300
                                                                        00033400
           WRITE REC-EDWH        FROM REC-OU003.                        00033500
      *                                                                 00033600
      *                                                                 00033700
           IF STATUS-FILEOUT NOT = '00'                                 00033800
              DISPLAY '*************ATTENZIONE**************'           00033900
              DISPLAY '*                                   *'           00034000
              DISPLAY '*       PROGRAMMA ARRAB003          *'           00034100
              DISPLAY '* ERRORE SCRITTURA RECORD NEL       *'           00034200
              DISPLAY '*        FLUSSO DI OUTPUT           *'           00034300
              DISPLAY '*************************************'           00034400
              PERFORM   ABEND   THRU      ABEND-EX                      00034500
           END-IF.                                                      00034600
                                                                        00034700
           ADD   1                TO CTR-SCRITTI.                       00034800
                                                                        00034900
      *                                                                 00035000
      *================                                                 00035100
       WRITE-OUT-EDWH-EX.                                               00035200
           EXIT.                                                        00035300
      *================                                                 00035400
      *                                                                 00035500
      *=============                                                    00035600
       WRITE-OUT-SCA.                                                   00035700
      *=============                                                    00035800
      *                                                                 00035900
      * VALORIZZAZIONE RECORD DI OUTPUT                                 00036000
      *                                                                 00036100
                                                                        00036200
           MOVE  EX003-FILIALE     TO   SCA003-FILIALE                  00036300
           MOVE  EX003-NUMERO      TO   SCA003-NUMERO                   00036400
           MOVE  EX003-SERVIZIO    TO   SCA003-SERVIZIO                 00036500
           MOVE  EX003-CATEGORIA   TO   SCA003-CATEGORIA                00036600
           MOVE  EX003-DT-VAL-DA   TO   SCA003-DT-VAL-DA                00036700
           MOVE  EX003-DT-VAL-A    TO   SCA003-DT-VAL-A                 00036800
           MOVE  EX003-STATO       TO   SCA003-STATO                    00036900
           MOVE  EX003-LIM-FIDO    TO   SCA003-LIM-FIDO                 00037000
           MOVE  SK-TIPO-ELAB      TO   SCA003-TIPO-ELAB.               00037100
           WRITE REC-SCARTI        FROM REC-SCA003.                     00037400
                                                                        00037500
           IF STATUS-FILESCA NOT = '00'                                 00037700
             DISPLAY '*************ATTENZIONE**************'            00037800
             DISPLAY '*                                   *'            00037900
             DISPLAY '*       PROGRAMMA ARRAB003          *'            00038000
             DISPLAY '* ERRORE SCRITTURA RECORD NEL       *'            00038100
             DISPLAY '*        FLUSSO DI OUTPUT           *'            00038200
             DISPLAY '*************************************'            00038300
             PERFORM   ABEND   THRU      ABEND-EX                       00038400
           END-IF.                                                      00038500
                                                                        00038600
           ADD   1                TO CTR-SCARTI.                        00038700
                                                                        00039000
      *================                                                 00039100
       WRITE-OUT-SCA-EX.                                                00039200
           EXIT.                                                        00039300
      *================                                                 00039310
                                                                        00039400
      *==============                                                   00039500
       SEL-SCTBTTAF.                                                    00039600
      *==============                                                   00039700
      *                                                                 00039800
      *========================================================         00039900
      * SELECT PUNTUALE                                                 00040000
      * PER LA RICERCA NELLA TABELLA                                    00040100
      * SCTBTTAF                                                        00040200
      *========================================================         00040300
                                                                        00041002
      **   DISPLAY 'TTAF          --> ' EX003-STATO                     00041003
      **   ' ' FINE-TAB-TTAF                                            00041004
      **   DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                   00041005
      **   DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                    00041006
      **   DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO                  00041007
      **   DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA                 00041008
      **   DISPLAY 'EX003-NDG     --> ' EX003-NDG                       00041009
      **   DISPLAY 'EX003-STATO   --> ' EX003-STATO                     00041010
      *                                                                 00041030
           EXEC SQL                                                     00041100
              SELECT                                                    00041200
                         TTAF_LIM_FIDO                                  00041700
                       , TTAF_STATO                                     00041800
                       , TTAF_NUMERO                                    00042000
                       INTO                                             00042100
                        :TTAF-LIM-FIDO                                  00042101
                       ,:TTAF-STATO                                     00042102
                       ,:TTAF-NUMERO                                    00042103
                       FROM  SCTBTTAF A                                 00042120
              WHERE                                                     00042200
                       TTAF_NUMERO     = :TTAF-NUMERO                   00042210
              AND      TTAF_NDG        = :TTAF-NDG                      00042220
              AND      TTAF_FILIALE    = :TTAF-FILIALE                  00042300
              AND      TTAF_SERVIZIO   = :TTAF-SERVIZIO                 00042500
              AND      TTAF_CATEGORIA  = :TTAF-CATEGORIA                00042600
              AND      TTAF_STATO                                       00042800
                   NOT IN ('RC', 'R3', 'RR', '70', '80')                00042810
              AND      TTAF_DT_VAL_A   =                                00042820
                      (SELECT MAX(TTAF_DT_VAL_A)                        00042830
                         FROM SCTBTTAF B                                00042840
                         WHERE B.TTAF_NUMERO = A.TTAF_NUMERO            00042850
                         AND   B.TTAF_NDG    = A.TTAF_NDG               00042851
                         AND   B.TTAF_STATO                             00042860
                               NOT IN ('RC', 'R3', 'RR', '70', '80')    00042870
                       )                                                00042880
              AND      TTAF_DT_VAL_DA  =                                00042890
                      (SELECT MAX(TTAF_DT_VAL_DA)                       00042891
                         FROM SCTBTTAF C                                00042892
                         WHERE C.TTAF_NUMERO = A.TTAF_NUMERO            00042893
                         AND   C.TTAF_NDG    = A.TTAF_NDG               00042894
                         AND   C.TTAF_STATO                             00042895
                               NOT IN ('RC', 'R3', 'RR', '70', '80')    00042896
                       )                                                00042897
           END-EXEC.                                                    00042900
                                                                        00043000
                                                                        00043100
           MOVE SQLCODE                   TO W-SQLCODE.                 00043200
                                                                        00043300
           IF W-SQLCODE = 0                                             00043400
              ADD     1                   TO CTR-SEL-TTAF               00043500
      **      DISPLAY 'W-SQLCODE     --> ' W-SQLCODE                    00043600
      **      DISPLAY 'TTAF-LIM-FIDO --> ' TTAF-LIM-FIDO                00043700
           END-IF.                                                      00044400
                                                                        00044500
           IF W-SQLCODE = 100                                           00044600
              MOVE     'SI'               TO FINE-TAB-TTAF              00044700
           END-IF.                                                      00044800
                                                                        00044810
           IF W-SQLCODE = 811                                           00044820
              MOVE     'SI'               TO FINE-TAB-TTAF              00044821
              DISPLAY '*---------------------------------------*'       00044822
              DISPLAY '*- ATTENZIONE  !! '                              00044823
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTTAF: ' W-SQLCODE   00044824
              DISPLAY '*---------------------------------------*'       00044825
              DISPLAY '*--KEY:                                 *'       00044826
              DISPLAY '*---------------------------------------*'       00044827
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00044829
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00044830
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00044831
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00044832
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00044833
              DISPLAY 'EX003-STATO   --> ' EX003-STATO                  00044834
              DISPLAY '*---------------------------------------*'       00044835
           END-IF.                                                      00044840
                                                                        00044850
           IF W-SQLCODE NOT = 0 AND 100 AND 811                         00044860
              DISPLAY '*---------------------------------------*'       00045100
              DISPLAY '*- ATTENZIONE  !! '                              00045200
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTTAF: ' W-SQLCODE   00045300
              DISPLAY '*---------------------------------------*'       00045301
              DISPLAY '*--KEY:                                 *'       00045302
              DISPLAY '*---------------------------------------*'       00045303
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00045320
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00045330
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00045340
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00045350
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00045360
              DISPLAY 'EX003-STATO   --> ' EX003-STATO                  00045370
              DISPLAY '*---------------------------------------*'       00045400
              PERFORM ABEND     THRU ABEND-EX                           00045500
           END-IF.                                                      00045600
      *                                                                 00045700
      *==============                                                   00045800
       SEL-SCTBTTAF-EX.                                                 00045900
           EXIT.                                                        00046000
      *==============                                                   00046100
                                                                        00046110
      *==============                                                   00046120
       SEL-SCTBTRIC.                                                    00046130
      *==============                                                   00046140
      *                                                                 00046150
      *========================================================         00046160
      * SELECT PUNTUALE                                                 00046170
      * PER LA RICERCA NELLA TABELLA                                    00046180
      * SCTBTRIC                                                        00046190
      *========================================================         00046191
      **                                                                00046192
      **   DISPLAY 'TRIC          --> ' EX003-STATO                     00046193
      **   ' ' FINE-TAB-TRIC ' ' FINE-TAB-TSTO                          00046194
      **   DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A                  00046195
      **   DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                   00046196
      **   DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                    00046197
      **   DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO                  00046198
      **   DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA                 00046199
      **   DISPLAY 'EX003-NDG     --> ' EX003-NDG                       00046200
      **   DISPLAY 'EX003-STATO   --> ' EX003-STATO                     00046201
      **   DISPLAY 'EX003-LIM-FIDO->  ' EX003-LIM-FIDO                  00046202
      *                                                                 00046203
           EXEC SQL                                                     00046204
              SELECT                                                    00046205
                         TRIC_DT_RIC_ATT                                00046206
                       , TRIC_DT_VAL_A                                  00046207
                       , TRIC_LIM_FIDO                                  00046208
                       , TRIC_ESITO                                     00046209
                       , TRIC_SETT_PROD                                 00046210
                       INTO                                             00046211
                         :TRIC-DT-RIC-ATT                               00046212
                       , :TRIC-DT-VAL-A                                 00046213
                       , :TRIC-LIM-FIDO                                 00046214
                       , :TRIC-ESITO                                    00046215
                       , :TRIC-SETT-PROD                                00046216
                       FROM  SCTBTRIC                                   00046217
              WHERE                                                     00046218
                       TRIC_NUMERO     = :TRIC-NUMERO                   00046219
              AND      TRIC_NDG_PF     = :TRIC-NDG-PF                   00046220
              AND      TRIC_FILIALE    = :TRIC-FILIALE                  00046221
              AND      TRIC_SERVIZIO   = :TRIC-SERVIZIO                 00046222
              AND      TRIC_CATEGORIA  = :TRIC-CATEGORIA                00046223
              AND      TRIC_TIP_ATTIV  = 'RS'                           00046224
              AND      TRIC_STATO_RICH  =  3                            00046225
           END-EXEC.                                                    00046226
                                                                        00046227
                                                                        00046228
           MOVE SQLCODE                   TO W-SQLCODE.                 00046229
                                                                        00046230
           IF W-SQLCODE = 0                                             00046231
              ADD     1                   TO CTR-SEL-TRIC               00046232
      **      DISPLAY 'W-SQLCODE     --> ' W-SQLCODE                    00046233
           END-IF.                                                      00046234
                                                                        00046235
           IF W-SQLCODE = 100                                           00046236
              MOVE     'SI'               TO FINE-TAB-TRIC              00046237
           END-IF.                                                      00046238
                                                                        00046239
           IF W-SQLCODE = 811                                           00046240
              MOVE     'SI'               TO FINE-TAB-TRIC              00046241
              DISPLAY '*---------------------------------------*'       00046242
              DISPLAY '*- ATTENZIONE  !! '                              00046243
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTRIC: ' W-SQLCODE   00046244
              DISPLAY '*---------------------------------------*'       00046245
              DISPLAY '*--KEY:                                 *'       00046246
              DISPLAY '*---------------------------------------*'       00046247
              DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A               00046248
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00046249
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00046250
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00046251
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00046252
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00046253
              DISPLAY '*---------------------------------------*'       00046254
           END-IF.                                                      00046255
                                                                        00046256
           IF W-SQLCODE NOT = 0 AND 100 AND 811                         00046257
              DISPLAY '*---------------------------------------*'       00046258
              DISPLAY '*- ATTENZIONE  !! '                              00046259
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTRIC: ' W-SQLCODE   00046260
              DISPLAY '*---------------------------------------*'       00046261
              DISPLAY '*--KEY:                                 *'       00046262
              DISPLAY '*---------------------------------------*'       00046263
              DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A               00046264
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00046265
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00046266
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00046267
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00046268
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00046269
              DISPLAY '*---------------------------------------*'       00046270
              PERFORM ABEND     THRU ABEND-EX                           00046271
           END-IF.                                                      00046272
      *                                                                 00046273
      *==============                                                   00046274
       SEL-SCTBTRIC-EX.                                                 00046275
           EXIT.                                                        00046276
      *==============                                                   00046277
                                                                        00046280
                                                                        00046300
      *==============                                                   00046400
       SEL-SCTBTSTO.                                                    00046500
      *==============                                                   00046600
      *                                                                 00046700
      *========================================================         00046800
      * SELECT PUNTUALE                                                 00046900
      * PER LA RICERCA NELLA TABELLA                                    00047000
      * SCTBTSTO                                                        00047100
      *========================================================         00047200
      *                                                                 00047300
      **                                                                00047910
      **   DISPLAY 'TSTO          --> ' EX003-STATO                     00047920
      **   ' ' FINE-TAB-TRIC ' ' FINE-TAB-TSTO                          00047921
      **   DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A                  00047924
      **   DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                   00047925
      **   DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                    00047926
      **   DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO                  00047927
      **   DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA                 00047928
      **   DISPLAY 'EX003-NDG     --> ' EX003-NDG                       00047929
      **   DISPLAY 'EX003-STATO   --> ' EX003-STATO                     00047930
      **   DISPLAY 'EX003-LIM-FIDO->  ' EX003-LIM-FIDO                  00047931
      *                                                                 00047940
                                                                        00048000
           EXEC SQL                                                     00048100
              SELECT                                                    00048200
                         TSTO_DT_RIC_ATT                                00048400
                       , TSTO_LIM_FIDO                                  00049000
                       , TSTO_ESITO                                     00049001
                       , TSTO_SETT_PROD                                 00049002
                       INTO                                             00049010
                         :TSTO-DT-RIC-ATT                               00049080
                       , :TSTO-LIM-FIDO                                 00049090
                       , :TSTO-ESITO                                    00049091
                       , :TSTO-SETT-PROD                                00049093
                       FROM  SCTBTSTO A                                 00049100
              WHERE                                                     00049200
                       TSTO_NUMERO     = :TSTO-NUMERO                   00049300
              AND      TSTO_NDG_PF     = :TSTO-NDG-PF                   00049400
              AND      TSTO_FILIALE    = :TSTO-FILIALE                  00049500
              AND      TSTO_SERVIZIO   = :TSTO-SERVIZIO                 00049600
              AND      TSTO_CATEGORIA  = :TSTO-CATEGORIA                00049700
              AND      TSTO_TIP_ATTIV = 'RS'                            00049710
              AND      TSTO_STATO_RICH  =  3                            00049720
              AND      TSTO_DT_VAL_A  = (                               00049740
                SELECT MAX(TSTO_DT_VAL_A) FROM  SCTBTSTO B              00049750
                  WHERE B.TSTO_NUMERO = A.TSTO_NUMERO                   00049760
                  AND   B.TSTO_NDG_PF = A.TSTO_NDG_PF                   00049770
                  AND   B.TSTO_TIP_ATTIV = 'RS'                         00049800
                  AND   B.TSTO_STATO_RICH  =  3)                        00049810
           END-EXEC.                                                    00049900
                                                                        00050400
           MOVE SQLCODE                   TO W-SQLCODE.                 00050500
                                                                        00050600
           IF W-SQLCODE = 0                                             00050700
              ADD     1                 TO CTR-SEL-TSTO                 00050800
      **      DISPLAY 'W-SQLCODE     --> ' W-SQLCODE                    00050900
           END-IF.                                                      00051700
                                                                        00051800
           IF W-SQLCODE = 100                                           00051900
              MOVE     'SI'             TO FINE-TAB-TSTO                00052000
           END-IF.                                                      00052100
                                                                        00052110
           IF W-SQLCODE = 811                                           00052120
              MOVE     'SI'             TO FINE-TAB-TSTO                00052130
              DISPLAY '*---------------------------------------*'       00052131
              DISPLAY '*- ATTENZIONE  !! '                              00052132
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTSTO: ' W-SQLCODE   00052133
              DISPLAY '*--KEY:                                 *'       00052134
              DISPLAY '*---------------------------------------*'       00052135
              DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A               00052136
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00052137
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00052138
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00052139
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00052140
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00052141
              DISPLAY '*---------------------------------------*'       00052142
           END-IF.                                                      00052150
                                                                        00052200
           IF W-SQLCODE NOT = 0 AND 100 AND 811                         00052300
              DISPLAY '*---------------------------------------*'       00052400
              DISPLAY '*- ATTENZIONE  !! '                              00052500
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTSTO: ' W-SQLCODE   00052600
              DISPLAY '*--KEY:                                 *'       00052610
              DISPLAY '*---------------------------------------*'       00052620
              DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A               00052630
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00052640
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00052650
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00052660
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00052670
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00052680
              DISPLAY '*---------------------------------------*'       00052700
              PERFORM ABEND     THRU ABEND-EX.                          00052800
      *                                                                 00052900
      *==============                                                   00053000
       SEL-SCTBTSTO-EX.                                                 00053100
           EXIT.                                                        00053200
      *==============                                                   00053300
      *                                                                 00053400
                                                                        00053410
      *==================                                               00053420
       SEL-SCTBTRIC-ESITO.                                              00053430
      *==================                                               00053440
      *                                                                 00053450
      *========================================================         00053460
      * SELECT PUNTUALE                                                 00053470
      * PER LA RICERCA NELLA TABELLA                                    00053480
      * SCTBTRIC - ESITO                                                00053490
      *========================================================         00053491
      **                                                                00053492
      **   DISPLAY 'TRIC          --> ' EX003-STATO                     00053493
      **   ' ' FINE-TAB-TRIC ' ' FINE-TAB-TSTO                          00053494
      **   DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A                  00053495
      **   DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                   00053496
      **   DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                    00053497
      **   DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO                  00053498
      **   DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA                 00053499
      **   DISPLAY 'EX003-NDG     --> ' EX003-NDG                       00053500
      **   DISPLAY 'EX003-STATO   --> ' EX003-STATO                     00053501
      **   DISPLAY 'EX003-LIM-FIDO->  ' EX003-LIM-FIDO                  00053502
      *                                                                 00053503
           EXEC SQL                                                     00053504
              SELECT                                                    00053505
                         TRIC_DT_RIC_ATT                                00053506
                       , TRIC_DT_VAL_A                                  00053507
                       , TRIC_LIM_FIDO                                  00053508
                       , TRIC_ESITO                                     00053509
                       , TRIC_SETT_PROD                                 00053510
                       INTO                                             00053511
                         :TRIC-DT-RIC-ATT                               00053512
                       , :TRIC-DT-VAL-A                                 00053513
                       , :TRIC-LIM-FIDO                                 00053514
                       , :TRIC-ESITO                                    00053515
                       , :TRIC-SETT-PROD                                00053516
                       FROM  SCTBTRIC                                   00053517
              WHERE                                                     00053518
                       TRIC_NUMERO     = :TRIC-NUMERO                   00053519
              AND      TRIC_NDG_PF     = :TRIC-NDG-PF                   00053520
              AND      TRIC_FILIALE    = :TRIC-FILIALE                  00053521
              AND      TRIC_SERVIZIO   = :TRIC-SERVIZIO                 00053522
              AND      TRIC_CATEGORIA  = :TRIC-CATEGORIA                00053523
              AND      TRIC_ESITO      = :TRIC-ESITO                    00053524
           END-EXEC.                                                    00053528
                                                                        00053529
                                                                        00053530
           MOVE SQLCODE                   TO W-SQLCODE.                 00053531
                                                                        00053532
           IF W-SQLCODE = 0                                             00053533
              ADD     1                   TO CTR-SEL-TRIC               00053534
      **      DISPLAY 'W-SQLCODE     --> ' W-SQLCODE                    00053535
           END-IF.                                                      00053536
                                                                        00053537
           IF W-SQLCODE = 100                                           00053538
              MOVE     'SI'               TO FINE-TAB-TRIC              00053539
           END-IF.                                                      00053540
                                                                        00053541
           IF W-SQLCODE = 811                                           00053542
              MOVE     'SI'               TO FINE-TAB-TRIC              00053543
              DISPLAY '*---------------------------------------*'       00053544
              DISPLAY '*- ATTENZIONE  !! '                              00053545
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTRIC: ' W-SQLCODE   00053546
              DISPLAY '*---------------------------------------*'       00053547
              DISPLAY '*--KEY:                                 *'       00053548
              DISPLAY '*---------------------------------------*'       00053549
              DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A               00053550
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00053551
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00053552
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00053553
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00053554
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00053555
           END-IF.                                                      00053556
                                                                        00053557
           IF W-SQLCODE NOT = 0 AND 100 AND 811                         00053558
              DISPLAY '*---------------------------------------*'       00053559
              DISPLAY '*- ATTENZIONE  !! '                              00053560
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTRIC: ' W-SQLCODE   00053561
              DISPLAY '*---------------------------------------*'       00053562
              DISPLAY '*--KEY:                                 *'       00053563
              DISPLAY '*---------------------------------------*'       00053564
              DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A               00053565
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00053566
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00053567
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00053568
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00053569
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00053570
              DISPLAY '*---------------------------------------*'       00053571
              PERFORM ABEND     THRU ABEND-EX                           00053572
           END-IF.                                                      00053573
      *                                                                 00053574
      *=====================                                            00053575
       SEL-SCTBTRIC-ESITO-EX.                                           00053576
           EXIT.                                                        00053577
      *=====================                                            00053578
                                                                        00053579
                                                                        00053580
      *==================                                               00053581
       SEL-SCTBTSTO-ESITO.                                              00053582
      *==================                                               00053583
      *                                                                 00053584
      *========================================================         00053585
      * SELECT PUNTUALE                                                 00053586
      * PER LA RICERCA NELLA TABELLA                                    00053587
      * SCTBTSTO - ESITO                                                00053588
      *========================================================         00053589
      *                                                                 00053590
      **                                                                00053591
      **   DISPLAY 'TSTO          --> ' EX003-STATO                     00053592
      **   ' ' FINE-TAB-TRIC ' ' FINE-TAB-TSTO                          00053593
      **   DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A                  00053594
      **   DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                   00053595
      **   DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                    00053596
      **   DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO                  00053597
      **   DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA                 00053598
      **   DISPLAY 'EX003-NDG     --> ' EX003-NDG                       00053599
      **   DISPLAY 'EX003-STATO   --> ' EX003-STATO                     00053600
      **   DISPLAY 'EX003-LIM-FIDO->  ' EX003-LIM-FIDO                  00053601
      *                                                                 00053602
                                                                        00053603
           EXEC SQL                                                     00053604
              SELECT                                                    00053605
                         TSTO_DT_RIC_ATT                                00053606
                       , TSTO_LIM_FIDO                                  00053607
                       , TSTO_ESITO                                     00053608
                       , TSTO_SETT_PROD                                 00053609
                       INTO                                             00053610
                         :TSTO-DT-RIC-ATT                               00053611
                       , :TSTO-LIM-FIDO                                 00053612
                       , :TSTO-ESITO                                    00053613
                       , :TSTO-SETT-PROD                                00053614
                       FROM  SCTBTSTO A                                 00053615
              WHERE                                                     00053616
                       TSTO_NUMERO     = :TSTO-NUMERO                   00053617
              AND      TSTO_NDG_PF     = :TSTO-NDG-PF                   00053618
              AND      TSTO_FILIALE    = :TSTO-FILIALE                  00053619
              AND      TSTO_SERVIZIO   = :TSTO-SERVIZIO                 00053620
              AND      TSTO_CATEGORIA  = :TSTO-CATEGORIA                00053621
              AND      TSTO_ESITO      = 'OK'                           00053622
               AND TSTO_DT_VAL_A  = (                                   00053623
                SELECT MAX(TSTO_DT_VAL_A) FROM  SCTBTSTO B              00053624
                  WHERE B.TSTO_NUMERO = A.TSTO_NUMERO                   00053625
                  AND   B.TSTO_NDG_PF = A.TSTO_NDG_PF                   00053626
                  AND   B.TSTO_ESITO      = 'OK')                       00053627
           END-EXEC.                                                    00053628
                                                                        00053629
           MOVE SQLCODE                   TO W-SQLCODE.                 00053630
                                                                        00053631
           IF W-SQLCODE = 0                                             00053632
              ADD     1                 TO CTR-SEL-TSTO                 00053633
      **      DISPLAY 'W-SQLCODE     --> ' W-SQLCODE                    00053634
           END-IF.                                                      00053635
                                                                        00053636
           IF W-SQLCODE = 100                                           00053637
              MOVE     'SI'             TO FINE-TAB-TSTO                00053638
           END-IF.                                                      00053639
                                                                        00053640
           IF W-SQLCODE = 811                                           00053641
              MOVE     'SI'             TO FINE-TAB-TSTO                00053642
              DISPLAY '*---------------------------------------*'       00053643
              DISPLAY '*- ATTENZIONE  !! '                              00053644
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTSTO: ' W-SQLCODE   00053645
              DISPLAY '*--KEY:                                 *'       00053646
              DISPLAY '*---------------------------------------*'       00053647
              DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A               00053648
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00053649
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00053650
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00053651
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00053652
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00053653
              DISPLAY '*---------------------------------------*'       00053654
           END-IF.                                                      00053655
                                                                        00053656
           IF W-SQLCODE NOT = 0 AND 100 AND 811                         00053657
              DISPLAY '*---------------------------------------*'       00053658
              DISPLAY '*- ATTENZIONE  !! '                              00053659
              DISPLAY '*- ERRORE SELECT IN TAB. SCTBTSTO: ' W-SQLCODE   00053660
              DISPLAY '*--KEY:                                 *'       00053661
              DISPLAY '*---------------------------------------*'       00053662
              DISPLAY 'EX003-DT-VAL-A--> ' EX003-DT-VAL-A               00053663
              DISPLAY 'EX003-FILIALE---> ' EX003-FILIALE                00053664
              DISPLAY 'EX003-NUMERO ---> ' EX003-NUMERO                 00053665
              DISPLAY 'EX003-SERVIZIO--> ' EX003-SERVIZIO               00053666
              DISPLAY 'EX003-CATEGORIA-> ' EX003-CATEGORIA              00053667
              DISPLAY 'EX003-NDG     --> ' EX003-NDG                    00053668
              DISPLAY '*---------------------------------------*'       00053669
              PERFORM ABEND     THRU ABEND-EX.                          00053670
      *                                                                 00053671
      *=====================                                            00053672
       SEL-SCTBTSTO-ESITO-EX.                                           00053673
           EXIT.                                                        00053674
      *=====================                                            00053675
      *                                                                 00053676
                                                                        00053677
      *                                                                 00053680
      *======                                                           00053700
       ABEND.                                                           00053800
      *======                                                           00053900
      *                                                                 00054000
           MOVE  12         TO  RETURN-CODE.                            00054100
           STOP RUN.                                                    00054200
      *                                                                 00054300
      *=========                                                        00054400
       ABEND-EX.                                                        00054500
           EXIT.                                                        00054600
      *=========                                                        00054700
      *                                                                 00054800
      *=========                                                        00054900
       FINE-PGM.                                                        00055000
      *=========                                                        00055100
      *                                                                 00055200
           CLOSE FILEEDWH.                                              00055300
           IF STATUS-FILEOUT NOT = '00'                                 00055400
              DISPLAY '********ATTENZIONE************'                  00055500
              DISPLAY '*                            *'                  00055600
              DISPLAY '*    PROGRAMMA ARRAB003      *'                  00055700
              DISPLAY '*                            *'                  00055800
              DISPLAY '* ERRORE CHIUSURA FILE EDWH  *'                  00055900
              DISPLAY '*                            *'                  00056000
              DISPLAY '*  FILE STATUS : ' STATUS-FILEOUT                00056100
              DISPLAY '*                            *'                  00056200
              DISPLAY '******************************'                  00056300
              PERFORM ABEND     THRU ABEND-EX                           00056400
           END-IF.                                                      00056500
                                                                        00056600
           CLOSE FILESCA.                                               00056700
           IF STATUS-FILESCA NOT = '00'                                 00056800
              DISPLAY '********ATTENZIONE************'                  00056900
              DISPLAY '*                            *'                  00057000
              DISPLAY '*    PROGRAMMA ARRAB003      *'                  00057100
              DISPLAY '*                            *'                  00057200
              DISPLAY '* ERRORE CHIUSURA FILE SCARTI*'                  00057300
              DISPLAY '*                            *'                  00057400
              DISPLAY '*  FILE STATUS : ' STATUS-FILESCA                00057500
              DISPLAY '*                            *'                  00057600
              DISPLAY '******************************'                  00057700
              PERFORM ABEND     THRU ABEND-EX                           00057800
           END-IF.                                                      00057900
                                                                        00058000
           CLOSE FILETTAF.                                              00058100
           IF STATUS-FILEIN NOT = '00'                                  00058200
              DISPLAY '********ATTENZIONE************'                  00058300
              DISPLAY '*                            *'                  00058400
              DISPLAY '*    PROGRAMMA ARRAB003      *'                  00058500
              DISPLAY '*                            *'                  00058600
              DISPLAY '* ERRORE CHIUSURA FILE INPUT *'                  00058700
              DISPLAY '*                            *'                  00058800
              DISPLAY '*  FILE STATUS : ' STATUS-FILEIN                 00058900
              DISPLAY '*                            *'                  00059000
              DISPLAY '******************************'                  00059100
              PERFORM ABEND     THRU ABEND-EX                           00059200
           END-IF.                                                      00059300
                                                                        00059400
           MOVE CTR-READ                 TO CTR-READ-Z                  00059500
           MOVE CTR-ELAB                 TO CTR-ELAB-Z                  00059510
           MOVE CTR-ELAB-ATT             TO CTR-ELAB-ATT-Z              00059520
           MOVE CTR-ELAB-EST             TO CTR-ELAB-EST-Z              00059530
           MOVE CTR-SCRITTI              TO CTR-SCRITTI-Z               00059600
           MOVE CTR-SCARTI               TO CTR-SCARTI-Z.               00059700
           MOVE CTR-SEL-TRIC             TO CTR-SEL-TRIC-Z              00059800
           MOVE CTR-SEL-TSTO             TO CTR-SEL-TSTO-Z              00059900
           MOVE CTR-SEL-TTAF             TO CTR-SEL-TTAF-Z.             00059910
                                                                        00060000
           DISPLAY '*------------------------------------------*'       00060100
           DISPLAY '*                                          *'       00060200
           DISPLAY '*        FINE   PROGRAMMA ARRAB003         *'       00060300
           DISPLAY '*                                          *'       00060400
           DISPLAY '*     ELABORAZIONE DEL ' WS-DATA                    00060500
           DISPLAY '*                                          *'       00060600
           DISPLAY '*               FLUSSO EDWH                *'       00060700
           DISPLAY '*                                          *'       00060800
           DISPLAY '*------------------------------------------*'       00060900
           DISPLAY '* RECORD LETTI (A,B)         =>:' CTR-READ-Z        00061200
           DISPLAY '*------------------------------------------*'       00061201
           DISPLAY '* ACCESSI IN TABELLE:                      *'       00061202
           DISPLAY '* - SEL. SCTBTTAF (C)        =>:' CTR-SEL-TTAF-Z    00061203
           DISPLAY '* - SEL. SCTBTRIC (C)        =>:' CTR-SEL-TRIC-Z    00061204
           DISPLAY '* - SEL. SCTBTSTO (C)        =>:' CTR-SEL-TSTO-Z    00061205
           DISPLAY '*------------------------------------------*'       00061206
           DISPLAY '* ELABORATI (A,B)            =>:' CTR-ELAB-Z        00061210
           DISPLAY '*------------------------------------------*'       00061211
           DISPLAY '* - DI CUI SCRITTI (A)       =>:' CTR-SCRITTI-Z     00061212
           DISPLAY '* - DI CUI ANOMALI (A)       =>:' CTR-SCARTI-Z      00061213
           DISPLAY '*------------------------------------------*'       00061214
           DISPLAY '* DI CUI:                                  *'       00061220
           DISPLAY '* - ATTIVI (A)               =>:' CTR-ELAB-ATT-Z    00061230
           DISPLAY '* - ESTINTI(B)               =>:' CTR-ELAB-EST-Z    00061240
           DISPLAY '*                                          *'       00061800
           DISPLAY '*     FINE ELABORAZIONE ARRAB003           *'       00061900
           DISPLAY '*                                          *'       00062000
           DISPLAY '*------------------------------------------*'.      00062100
      *                                                                 00062200
      *                                                                 00062300
      *=============                                                    00062400
       FINE-PGM-EX.                                                     00062500
           EXIT.                                                        00062600
      *=============                                                    00062700
