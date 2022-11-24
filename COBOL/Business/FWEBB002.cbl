       IDENTIFICATION DIVISION.                                         00000100
      *                                                                 00000200
      ***************************************************************** 00000400
      *                                                               * 00000500
      *  NOME DEL PROGRAMMA        'FWEBB002'                         * 00000600
      *                                                               * 00000700
      *  PROGRAMMA : MERGE TRA I DATASET PRODOTTI DAI PROGRAMMI *       00000800
      *              FWEBB001                                         * 00000900
      *                                                               * 00001000
      *                                                               * 00001100
      ***************************************************************** 00001200
       PROGRAM-ID. FWEBB002.                                            00001300
       AUTHOR. GEPINDATITALIA.                                          00001400
       ENVIRONMENT DIVISION.                                            00001500
       CONFIGURATION SECTION.                                           00001600
       SPECIAL-NAMES.                                                   00001700
           DECIMAL-POINT IS COMMA.                                      00001800
       INPUT-OUTPUT SECTION.                                            00001900
       FILE-CONTROL.                                                    00002000
      *                                                                 00002100
           SELECT FILEIN1 ASSIGN TO FILEIN1                             00002200
                  FILE STATUS IS STATUS-FILEIN1.                        00002300
           SELECT FILEIN2 ASSIGN TO FILEIN2                             00002400
                  FILE STATUS IS STATUS-FILEIN2.                        00002500
           SELECT FILEOUT ASSIGN TO FILEOUT                             00002600
                  FILE STATUS IS STATUS-FILEOUT.                        00002700
      *                                                                 00002800
      ***********************************************************       00002900
       DATA DIVISION.                                                   00003000
      ***********************************************************       00003100
       FILE SECTION.                                                    00003200
      ***********************************************************       00003300
       FD  FILEIN1                                                      00003400
           LABEL RECORDS STANDARD                                       00003500
           RECORDING MODE IS F                                          00003600
           BLOCK 0 RECORDS.                                             00003700
       01  REC-FILEIN1             PIC X(221).                          00003800
                                                                        00003900
       FD  FILEIN2                                                      00004000
           LABEL RECORDS STANDARD                                       00004100
           RECORDING MODE IS F                                          00004200
           BLOCK 0 RECORDS.                                             00004300
       01  REC-FILEIN2             PIC X(221).                          00004400
                                                                        00004500
       FD  FILEOUT                                                      00004600
           LABEL RECORDS STANDARD                                       00004700
           RECORDING MODE IS F                                          00004800
           BLOCK 0 RECORDS.                                             00004900
       01  REC-FILEOUT             PIC X(221).                          00005000
                                                                        00005100
                                                                        00005200
      ***********************************************************       00005300
       WORKING-STORAGE SECTION.                                         00005400
      ***********************************************************       00005500
      *                                                                 00005600
      *===============================================================* 00005700
      *==> CAMPI DI APPOGGIO PER FILE STATUS DEI FILES                  00005800
      *===============================================================* 00005900
       01  STATUS-FILEIN1             PIC  X(02) VALUE SPACES.          00006000
       01  STATUS-FILEIN2             PIC  X(02) VALUE SPACES.          00006100
       01  STATUS-FILEOUT             PIC  X(02) VALUE SPACES.          00006200
       01  STATUS-FILESCA             PIC  X(02) VALUE SPACES.          00006300
      *                                                                 00006400
       01 CNT-READ-INP1               PIC 9(10) VALUE ZERO.             00006500
       01 CNT-READ-INP2               PIC 9(10) VALUE ZERO.             00006600
       01 CNT-READ-INP1-Z             PIC Z.ZZZ.ZZ9.                    00006700
       01 CNT-READ-INP2-Z             PIC Z.ZZZ.ZZ9.                    00006800
       01 CNT-SCR-INS                 PIC 9(10) VALUE ZERO.             00006900
       01 CNT-SCR-AGG                 PIC 9(10) VALUE ZERO.             00007000
       01 CNT-SCR-TOT                 PIC 9(10) VALUE ZERO.             00007100
       01 CNT-SCR-SCA                 PIC 9(10) VALUE ZERO.             00007200
       01 CNT-SCR-SCA-Z               PIC Z.ZZZ.ZZ9.                    00007300
       01 CNT-SCR-SCA-B-Z             PIC Z.ZZZ.ZZ9.                    00007400
       01 CNT-SCR-INS-Z               PIC Z.ZZZ.ZZ9.                    00007500
       01 CNT-SCR-AGG-Z               PIC Z.ZZZ.ZZ9.                    00007600
       01 CNT-SCR-TOT-Z               PIC Z.ZZZ.ZZ9.                    00007700
       01 WS-DATA-PARAM               PIC X(08).                        00007800
       01 WS-DATA-PARAM-C             PIC X(08).                        00007900
                                                                        00008000
       01 FINE-FILE-INP1              PIC X(02) VALUE 'NO'.             00008100
       01 FINE-FILE-INP2              PIC X(02) VALUE 'NO'.             00008200
                                                                        00008300
       01 APPO-KEY-INP1.                                                00008400
          05 APPO-ARE-COU-INP1          PIC X(05).                      00008500
          05 APPO-COD-FIL-INP1          PIC X(05).                      00008600
          05 APPO-COD-FRA-INP1          PIC X(05).                      00008700
                                                                        00008800
       01 APPO-KEY-INP2.                                                00008900
          05 APPO-ARE-COU-INP2          PIC X(05).                      00009000
          05 APPO-COD-FIL-INP2          PIC X(05).                      00009100
          05 APPO-COD-FRA-INP2          PIC X(05).                      00009200
                                                                        00009300
       01 WS-REC-INP1                   PIC X(221).                     00009400
      *   10 WS-REC-FILL-1              PIC X(175).                     00009500
      *   10 WS-REC-OPER-1              PIC X(001).                     00009600
                                                                        00009700
       01 WS-REC-INP2                   PIC X(221).                     00009800
                                                                        00009900
      ***********************************************************       00010000
      *            STRUTTURA DEI RECORDS DI INPUT                       00010100
      ***********************************************************       00010200
      *                                                                 00010300
          COPY FWEBC001.                                                00010400
      *                                                                 00010500
       01 WS-DATA-SYS               PIC 9(08) VALUE ZEROES.             00010600
      *                                                                 00010700
      ***********************                                           00010800
      * CAMPI DELLA CEE3ABD *                                           00010900
      ***********************                                           00011000
      *                                                                 00011100
       01 CEE3ABD                           PIC X(8)  VALUE 'CEE3ABD'.  00011200
       01 TIMING                            PIC S9(4) BINARY.           00011300
       01 ABDCODE                           PIC S9(4) BINARY.           00011400
      *                                                                 00011500
      ***************************************                           00011600
      * P R O C E D U R E   D I V I S I O N                             00011700
      ***************************************                           00011800
       PROCEDURE DIVISION.                                              00011900
       MAIN.                                                            00012000
      *                                                                 00012100
           PERFORM   INIZIO-PROG        THRU   INIZIO-PROG-EX.          00012200
      *                                                                 00012300
           PERFORM   ELABORA-FLUSSI    THRU ELABORA-FLUSSI-EX           00012400
           UNTIL     FINE-FILE-INP1 = 'SI' OR                           00012500
                     FINE-FILE-INP2 = 'SI'                              00012600
      *                                                                 00012700
           IF FINE-FILE-INP2 = 'NO'                                     00012800
              PERFORM ELABORA-FILEIN2  THRU ELABORA-FILEIN2-EX          00012900
               UNTIL  FINE-FILE-INP2 = 'SI'                             00013000
           END-IF.                                                      00013100
      *                                                                 00013200
           IF FINE-FILE-INP1 = 'NO'                                     00013300
              PERFORM ELABORA-FILEIN1  THRU ELABORA-FILEIN1-EX          00013400
               UNTIL  FINE-FILE-INP1 = 'SI'                             00013500
           END-IF.                                                      00013600
      *                                                                 00013700
           PERFORM   STATISTICHE        THRU   STATISTICHE-EX.          00013800
      *                                                                 00013900
       FINE-PROGRAMMA.                                                  00014000
      *                                                                 00014100
           STOP RUN.                                                    00014200
      *                                                                 00014300
      *************                                                     00014400
       INIZIO-PROG.                                                     00014500
      *************                                                     00014600
                                                                        00014700
           ACCEPT  WS-DATA-PARAM    FROM  SYSIN.                        00014800
                                                                        00014900
           MOVE    WS-DATA-PARAM(01:02)   TO  WS-DATA-PARAM-C(07:02)    00015000
           MOVE    WS-DATA-PARAM(03:02)   TO  WS-DATA-PARAM-C(06:02).   00015100
           MOVE    WS-DATA-PARAM(05:04)   TO  WS-DATA-PARAM-C(01:04).   00015200
                                                                        00015300
           MOVE    SPACES          TO WS-REC-INP1.                      00015400
           MOVE    SPACES          TO WS-REC-INP2.                      00015500
                                                                        00015600
           ACCEPT  WS-DATA-SYS   FROM DATE YYYYMMDD                     00015700
                                                                        00015800
           IF WS-DATA-PARAM > WS-DATA-SYS                               00015900
              DISPLAY '********ATTENZIONE************'                  00016000
              DISPLAY '*                            *'                  00016100
              DISPLAY '*    PROGRAMMA FWEBB002      *'                  00016200
              DISPLAY '*                            *'                  00016300
              DISPLAY '*  DATA PARAMETRO MAGGIORE   *'                  00016400
              DISPLAY '*  DELLA DATA ELABORAZIONE   *'                  00016500
              DISPLAY '*                            *'                  00016600
              DISPLAY '*  DATA PARAMETRO    : ' WS-DATA-PARAM           00016700
              DISPLAY '*  DATA ELABORAZIONE : ' WS-DATA-SYS             00016800
              DISPLAY '*                            *'                  00016900
              DISPLAY '******************************'                  00017000
              PERFORM ABEND-PGM THRU ABEND-PGM-EX                       00017100
           END-IF.                                                      00017200
      *                                                                 00017300
           OPEN  INPUT FILEIN1                                          00017400
                                                                        00017500
           IF STATUS-FILEIN1 NOT = '00'                                 00017600
              DISPLAY '********ATTENZIONE************'                  00017700
              DISPLAY '*                            *'                  00017800
              DISPLAY '*    PROGRAMMA FWEBB002      *'                  00017900
              DISPLAY '*                            *'                  00018000
              DISPLAY '*  ERRORE APERTURA FILEIN1   *'                  00018100
              DISPLAY '*                            *'                  00018200
              DISPLAY '*  FILE STATUS : ' STATUS-FILEIN1                00018300
              DISPLAY '******************************'                  00018400
              PERFORM ABEND-PGM THRU ABEND-PGM-EX                       00018500
           END-IF.                                                      00018600
      *                                                                 00018700
           OPEN  INPUT FILEIN2                                          00018800
                                                                        00018900
           IF STATUS-FILEIN2 NOT = '00'                                 00019000
              DISPLAY '********ATTENZIONE************'                  00019100
              DISPLAY '*                            *'                  00019200
              DISPLAY '*    PROGRAMMA FWEBB002      *'                  00019300
              DISPLAY '*                            *'                  00019400
              DISPLAY '*  ERRORE APERTURA FILEIN2   *'                  00019500
              DISPLAY '*                            *'                  00019600
              DISPLAY '*  FILE STATUS : ' STATUS-FILEIN2                00019700
              DISPLAY '******************************'                  00019800
              PERFORM ABEND-PGM THRU ABEND-PGM-EX                       00019900
           END-IF.                                                      00020000
      *                                                                 00020100
           OPEN  OUTPUT  FILEOUT.                                       00020200
                                                                        00020300
           IF STATUS-FILEOUT NOT = '00'                                 00020400
              DISPLAY '********ATTENZIONE************'                  00020500
              DISPLAY '*                            *'                  00020600
              DISPLAY '*    PROGRAMMA FWEBB002      *'                  00020700
              DISPLAY '*                            *'                  00020800
              DISPLAY '*  ERRORE APERTURA FILEOUT   *'                  00020900
              DISPLAY '*                            *'                  00021000
              DISPLAY '*  FILE STATUS : ' STATUS-FILEOUT                00021100
              DISPLAY '******************************'                  00021200
              PERFORM ABEND-PGM THRU ABEND-PGM-EX                       00021300
           END-IF.                                                      00021400
      *                                                                 00021500
      *                                                                 00021600
      *                                                                 00021700
      *=============================================================*   00021800
      *    PRIMA LETTURA FILE INP1                                  *   00021900
      *=============================================================*   00022000
                                                                        00022100
           READ FILEIN1 INTO REC-FWEBC001                               00022200
                AT END MOVE 'SI' TO FINE-FILE-INP1.                     00022300
                                                                        00022400
           IF STATUS-FILEIN1 = '10'                                     00022500
              DISPLAY '*************ATTENZIONE**************'           00022600
              DISPLAY '*                                   *'           00022700
              DISPLAY '* PROGRAMMA FWEBB002                *'           00022800
              DISPLAY '*                                   *'           00022900
              DISPLAY '* FILE: FILEIN1 VUOTO               *'           00023000
              DISPLAY '*                                   *'           00023100
              DISPLAY '*************************************'           00023200
           ELSE                                                         00023300
              IF STATUS-FILEIN1 NOT = '00'                              00023400
                 DISPLAY '********ATTENZIONE************'               00023500
                 DISPLAY '*                            *'               00023600
                 DISPLAY '*    PROGRAMMA FWEBB002      *'               00023700
                 DISPLAY '*                            *'               00023800
                 DISPLAY '*   ERRORE LETTURA FILEIN1   *'               00023900
                 DISPLAY '*                            *'               00024000
                 DISPLAY '*  FILE STATUS : ' STATUS-FILEIN1             00024100
                 DISPLAY '*                            *'               00024200
                 DISPLAY '******************************'               00024300
                 PERFORM ABEND-PGM THRU ABEND-PGM-EX                    00024400
              ELSE                                                      00024500
                 ADD  1                       TO CNT-READ-INP1          00024600
                 MOVE FWEBC001-AREA-COUT      TO APPO-ARE-COU-INP1      00024700
                 MOVE FWEBC001-CODI-FILI      TO APPO-COD-FIL-INP1      00024800
                 MOVE FWEBC001-CODI-FRAZ      TO APPO-COD-FRA-INP1      00024900
                 MOVE REC-FWEBC001            TO WS-REC-INP1            00025000
              END-IF                                                    00025100
           END-IF.                                                      00025200
      *                                                                 00025300
      *                                                                 00025400
      *=============================================================*   00025500
      *    PRIMA LETTURA FILE INP2                                  *   00025600
      *=============================================================*   00025700
      *                                                                 00025800
           READ FILEIN2 INTO REC-FWEBC001                               00025900
           AT END MOVE 'SI' TO FINE-FILE-INP2.                          00026000
                                                                        00026100
           IF STATUS-FILEIN2 = '10'                                     00026200
              DISPLAY '*************ATTENZIONE**************'           00026300
              DISPLAY '*                                   *'           00026400
              DISPLAY '* PROGRAMMA FWEBB002                *'           00026500
              DISPLAY '*                                   *'           00026600
              DISPLAY '* FILE: FILEIN2 VUOTO               *'           00026700
              DISPLAY '*                                   *'           00026800
              DISPLAY '*************************************'           00026900
           ELSE                                                         00027000
              IF STATUS-FILEIN2 NOT = '00'                              00027100
                 DISPLAY '********ATTENZIONE************'               00027200
                 DISPLAY '*                            *'               00027300
                 DISPLAY '*    PROGRAMMA FWEBB002      *'               00027400
                 DISPLAY '*                            *'               00027500
                 DISPLAY '*   ERRORE LETTURA FILEIN2   *'               00027600
                 DISPLAY '*                            *'               00027700
                 DISPLAY '*  FILE STATUS : ' STATUS-FILEIN2             00027800
                 DISPLAY '*                            *'               00027900
                 DISPLAY '******************************'               00028000
                 PERFORM ABEND-PGM THRU ABEND-PGM-EX                    00028100
              ELSE                                                      00028200
                 ADD  1                       TO CNT-READ-INP2          00028300
                 MOVE FWEBC001-AREA-COUT      TO APPO-ARE-COU-INP2      00028400
                 MOVE FWEBC001-CODI-FILI      TO APPO-COD-FIL-INP2      00028500
                 MOVE FWEBC001-CODI-FRAZ      TO APPO-COD-FRA-INP2      00028600
                 MOVE REC-FWEBC001            TO WS-REC-INP2            00028700
              END-IF                                                    00028800
           END-IF.                                                      00028900
      *                                                                 00029000
      ****************                                                  00029100
       INIZIO-PROG-EX.                                                  00029200
           EXIT.                                                        00029300
      ****************                                                  00029400
      *                                                                 00029500
      *                                                                 00029600
      ****************                                                  00029700
       ELABORA-FLUSSI.                                                  00029800
      ****************                                                  00029900
      *                                                                 00030000
      *    DISPLAY 'INPUT 1 = ' WS-REC-INP1.                            00030100
      *    DISPLAY 'INPUT 2 = ' WS-REC-INP2.                            00030200
           IF WS-REC-INP1 = WS-REC-INP2                                 00030300
              PERFORM LEGGI-FILE-INP1     THRU LEGGI-FILE-INP1-EX       00030400
              PERFORM LEGGI-FILE-INP2     THRU LEGGI-FILE-INP2-EX       00030500
           ELSE                                                         00030600
              IF APPO-KEY-INP1  = APPO-KEY-INP2                         00030700
                 MOVE 'U'                      TO WS-REC-INP1(176:01)   00030800
                 PERFORM SCRIVI-FILEOUT      THRU SCRIVI-FILEOUT-EX     00030900
                 PERFORM LEGGI-FILE-INP1     THRU LEGGI-FILE-INP1-EX    00031000
                 PERFORM LEGGI-FILE-INP2     THRU LEGGI-FILE-INP2-EX    00031100
              ELSE                                                      00031200
                 IF APPO-KEY-INP1 > APPO-KEY-INP2                       00031300
                    PERFORM SCRIVI-CHIUSI    THRU SCRIVI-CHIUSI-EX      00031400
                    PERFORM LEGGI-FILE-INP2  THRU LEGGI-FILE-INP2-EX    00031500
                 ELSE                                                   00031600
                    PERFORM SCRIVI-FILEOUT   THRU SCRIVI-FILEOUT-EX     00031700
                    PERFORM LEGGI-FILE-INP1  THRU LEGGI-FILE-INP1-EX    00031800
                 END-IF                                                 00031900
              END-IF                                                    00032000
           END-IF.                                                      00032100
      *                                                                 00032200
      *                                                                 00032300
      *******************                                               00032400
       ELABORA-FLUSSI-EX.                                               00032500
           EXIT.                                                        00032600
      *******************                                               00032700
      *                                                                 00032800
      *                                                                 00032900
      ******************                                                00033000
       LEGGI-FILE-INP1.                                                 00033100
      ******************                                                00033200
      *                                                                 00033300
           READ FILEIN1 INTO REC-FWEBC001                               00033400
                AT END MOVE 'SI' TO FINE-FILE-INP1.                     00033500
                                                                        00033600
           IF FINE-FILE-INP1 NOT = 'SI'                                 00033700
              MOVE FWEBC001-AREA-COUT      TO APPO-ARE-COU-INP1         00033800
              MOVE FWEBC001-CODI-FILI      TO APPO-COD-FIL-INP1         00033900
              MOVE FWEBC001-CODI-FRAZ      TO APPO-COD-FRA-INP1         00034000
              MOVE REC-FWEBC001            TO WS-REC-INP1               00034100
              ADD  1                       TO CNT-READ-INP1             00034200
           END-IF.                                                      00034300
      *                                                                 00034400
      *********************                                             00034500
       LEGGI-FILE-INP1-EX.                                              00034600
           EXIT.                                                        00034700
      *********************                                             00034800
      *                                                                 00034900
      *                                                                 00035000
      ******************                                                00035100
       LEGGI-FILE-INP2.                                                 00035200
      ******************                                                00035300
      *                                                                 00035400
           READ FILEIN2 INTO REC-FWEBC001                               00035500
             AT END MOVE 'SI' TO FINE-FILE-INP2.                        00035600
                                                                        00035700
           IF FINE-FILE-INP2 NOT = 'SI'                                 00035800
              MOVE FWEBC001-AREA-COUT      TO APPO-ARE-COU-INP2         00035900
              MOVE FWEBC001-CODI-FILI      TO APPO-COD-FIL-INP2         00036000
              MOVE FWEBC001-CODI-FRAZ      TO APPO-COD-FRA-INP2         00036100
              MOVE REC-FWEBC001            TO WS-REC-INP2               00036200
              ADD  1                       TO CNT-READ-INP2             00036300
           END-IF.                                                      00036400
      *                                                                 00036500
      *********************                                             00036600
       LEGGI-FILE-INP2-EX.                                              00036700
           EXIT.                                                        00036800
      *********************                                             00036900
      *                                                                 00037000
      ******************                                                00037100
       ELABORA-FILEIN1.                                                 00037200
      ******************                                                00037300
      *                                                                 00037400
           PERFORM SCRIVI-FILEOUT  THRU SCRIVI-FILEOUT-EX.              00037500
      *                                                                 00037600
           PERFORM LEGGI-FILE-INP1 THRU LEGGI-FILE-INP1-EX.             00037700
      *                                                                 00037800
      *********************                                             00037900
       ELABORA-FILEIN1-EX.                                              00038000
           EXIT.                                                        00038100
      *********************                                             00038200
      *                                                                 00038300
      *                                                                 00038400
      *                                                                 00038500
      ******************                                                00038600
       ELABORA-FILEIN2.                                                 00038700
      ******************                                                00038800
      *                                                                 00038900
           PERFORM SCRIVI-CHIUSI   THRU SCRIVI-CHIUSI-EX.               00039000
      *                                                                 00039100
           PERFORM LEGGI-FILE-INP2 THRU LEGGI-FILE-INP2-EX.             00039200
      *                                                                 00039300
      *                                                                 00039400
      *********************                                             00039500
       ELABORA-FILEIN2-EX.                                              00039600
           EXIT.                                                        00039700
      *********************                                             00039800
      *                                                                 00039900
      *                                                                 00040000
      *                                                                 00040100
      ****************                                                  00040200
       SCRIVI-FILEOUT.                                                  00040300
      ****************                                                  00040400
      *                                                                 00040500
           IF   WS-REC-INP1(176:01) = 'I'                               00040600
                ADD   1                   TO CNT-SCR-INS                00040700
           ELSE                                                         00040800
                ADD   1                   TO CNT-SCR-AGG                00040900
           END-IF.                                                      00041000
                                                                        00041100
           WRITE REC-FILEOUT            FROM WS-REC-INP1.               00041200
                                                                        00041300
           ADD   1                        TO CNT-SCR-TOT.               00041400
      *                                                                 00041500
      *******************                                               00041600
       SCRIVI-FILEOUT-EX.                                               00041700
           EXIT.                                                        00041800
      *******************                                               00041900
      *                                                                 00042000
      *                                                                 00042100
      ****************                                                  00042200
       SCRIVI-CHIUSI.                                                   00042300
      ****************                                                  00042400
      *                                                                 00042500
           MOVE WS-DATA-PARAM             TO WS-REC-INP2(161:08).       00042600
           MOVE 'C'                       TO WS-REC-INP2(174:01).       00042700
           MOVE 'U'                       TO WS-REC-INP2(176:01).       00042800
           WRITE REC-FILEOUT            FROM WS-REC-INP2.               00042900
      *                                                                 00043000
           ADD   1                        TO CNT-SCR-AGG.               00043100
           ADD   1                        TO CNT-SCR-TOT.               00043200
      *                                                                 00043300
      *******************                                               00043400
       SCRIVI-CHIUSI-EX.                                                00043500
           EXIT.                                                        00043600
      *******************                                               00043700
      *                                                                 00043800
      *                                                                 00043900
      *******                                                           00044000
       ABEND.                                                           00044100
      *******                                                           00044200
           MOVE  12         TO  RETURN-CODE.                            00044300
           STOP RUN.                                                    00044400
      *                                                                 00044500
      **********                                                        00044600
       ABEND-EX.                                                        00044700
           EXIT.                                                        00044800
      **********                                                        00044900
      *                                                                 00045000
      *                                                                 00045100
       STATISTICHE.                                                     00045200
      *                                                                 00045300
           CLOSE FILEIN1.                                               00045400
                                                                        00045500
           IF STATUS-FILEIN1 NOT = '00'                                 00045600
              DISPLAY '********ATTENZIONE************'                  00045700
              DISPLAY '*                            *'                  00045800
              DISPLAY '*    PROGRAMMA FWEBB002      *'                  00045900
              DISPLAY '*                            *'                  00046000
              DISPLAY '*  ERRORE CHIUSURA FILEIN1   *'                  00046100
              DISPLAY '*                            *'                  00046200
              DISPLAY '*  FILE STATUS : ' STATUS-FILEIN1                00046300
              DISPLAY '******************************'                  00046400
              PERFORM ABEND-PGM THRU ABEND-PGM-EX                       00046500
           END-IF.                                                      00046600
      *                                                                 00046700
           CLOSE FILEIN2.                                               00046800
                                                                        00046900
           IF STATUS-FILEIN2 NOT = '00'                                 00047000
              DISPLAY '********ATTENZIONE************'                  00047100
              DISPLAY '*                            *'                  00047200
              DISPLAY '*    PROGRAMMA FWEBB002      *'                  00047300
              DISPLAY '*                            *'                  00047400
              DISPLAY '*  ERRORE CHIUSURA FILEIN2   *'                  00047500
              DISPLAY '*                            *'                  00047600
              DISPLAY '*  FILE STATUS : ' STATUS-FILEIN2                00047700
              DISPLAY '******************************'                  00047800
              PERFORM ABEND-PGM THRU ABEND-PGM-EX                       00047900
           END-IF.                                                      00048000
      *                                                                 00048100
           CLOSE FILEOUT.                                               00048200
                                                                        00048300
           IF STATUS-FILEOUT NOT = '00'                                 00048400
              DISPLAY '********ATTENZIONE************'                  00048500
              DISPLAY '*                            *'                  00048600
              DISPLAY '*    PROGRAMMA FWEBB002      *'                  00048700
              DISPLAY '*                            *'                  00048800
              DISPLAY '*  ERRORE CHIUSURA FILEOUT   *'                  00048900
              DISPLAY '*                            *'                  00049000
              DISPLAY '*  FILE STATUS : ' STATUS-FILEOUT                00049100
              DISPLAY '******************************'                  00049200
              PERFORM ABEND-PGM THRU ABEND-PGM-EX                       00049300
           END-IF.                                                      00049400
      *                                                                 00049500
      *                                                                 00049600
           MOVE CNT-READ-INP1            TO  CNT-READ-INP1-Z.           00049700
           MOVE CNT-READ-INP2            TO  CNT-READ-INP2-Z.           00049800
           MOVE CNT-SCR-INS              TO  CNT-SCR-INS-Z.             00049900
           MOVE CNT-SCR-AGG              TO  CNT-SCR-AGG-Z.             00050000
           MOVE CNT-SCR-TOT              TO  CNT-SCR-TOT-Z.             00050100
                                                                        00050200
           DISPLAY '*-------------------------------------------*'.     00050300
           DISPLAY '*         INIZIO PROGRAMMA FWEBB002         *'.     00050400
           DISPLAY '*                                           *'.     00050500
           DISPLAY '*         ELABORAZIONE DEL ' WS-DATA-SYS.           00050600
           DISPLAY '*                                           *'.     00050700
           DISPLAY '*-------------------------------------------*'.     00050800
           DISPLAY '*--------------------------------------------*'.    00050900
           DISPLAY '*                                            *'.    00051000
           DISPLAY '* RECORD LETTI FILE ATTUALE    => ' CNT-READ-INP1-Z.00051100
           DISPLAY '* RECORD LETTI FILE PRECEDENTE => ' CNT-READ-INP2-Z.00051200
           DISPLAY '* RECORD SCRITTI IN INSERIMENTO=> ' CNT-SCR-INS-Z.  00051300
           DISPLAY '* RECORD SCRITTI IN AGGIORNAM. => ' CNT-SCR-AGG-Z.  00051400
           DISPLAY '* RECORD TOTALE SCRITTI        => ' CNT-SCR-TOT-Z.  00051500
           DISPLAY '*                                            *'.    00051600
           DISPLAY '*        FINE ELABORAZIONE FWEBB002          *'.    00051700
           DISPLAY '*                                            *'.    00051800
           DISPLAY '*--------------------------------------------*'.    00051900
      *                                                                 00052000
      *                                                                 00052100
       STATISTICHE-EX.                                                  00052200
           EXIT.                                                        00052300
      *===========*                                                     00052400
       ABEND-PGM.                                                       00052500
      *===========*                                                     00052600
           CALL CEE3ABD USING ABDCODE TIMING.                           00052700
      *==============*                                                  00052800
       ABEND-PGM-EX.                                                    00052900
           EXIT.                                                        00053000
      *==============*                                                  00053100
