       IDENTIFICATION DIVISION.                                         00000100
      ******************************************************************00000200
      ******************************************************************00000300
      *                      **- RCBT001 -**                          **00000400
      ******************************************************************00000500
      ** CREATORE   : ENGINEERING                                     **00000600
      ** DATA       : 08/08/2005                                      **00000700
      ***************** ************************************************00000800
      ** TIPO       : BATCH                                           **00001000
      ** DB2        : SI                                              **00001400
      ******************************************************************00001500
      ** IL PROGRAMMA ACCEDE ALLA TABELLA RCBTRSTA E PER PRENDERE LA  **00001500
      ** RCTBRSTA_DTA. SE DATA CONTABILE ANTECEDENTE ALLA DATA        **00001500
      ** ESTRATTA SCRIVE IL FLUSSO FLOANTE ALTRIMENTI FLOPART         **00001500
      ******************************************************************00001500
       PROGRAM-ID. RCBT001.                                             00001700
       ENVIRONMENT DIVISION.                                            00001800
       CONFIGURATION SECTION.                                           00001900
       SPECIAL-NAMES.                                                   00002000
           DECIMAL-POINT IS COMMA.                                      00002100
       INPUT-OUTPUT SECTION.                                            00002200
       FILE-CONTROL.                                                    00002300
                                                                        00002400
           SELECT    FLIPART                                            00002500
           ASSIGN TO FLIPART                                            00002600
           FILE STATUS IS W-FS-FLIPART.                                 00002700
                                                                        00002840
           SELECT    FLIPARM
           ASSIGN TO FLIPARM
           FILE STATUS IS RCCYPARM-FS-FLIPARM.                          00004600

           SELECT    FLOPART                                            00002900
           ASSIGN TO FLOPART                                            00003000
           FILE STATUS IS W-FS-FLOPART.                                 00003100
                                                                        00003600
           SELECT    FLOANTE                                            00002900
           ASSIGN TO FLOANTE                                            00003000
           FILE STATUS IS W-FS-FLOANTE.                                 00003100
                                                                        00003600
       DATA DIVISION.                                                   00003700
       FILE SECTION.                                                    00003800
                                                                        00003900
       FD  FLIPART                                                      00004000
           RECORDING F                                                  00004100
           LABEL RECORD IS STANDARD                                     00004200
           DATA RECORD IS REC-FLIPART.                                  00004300
       01  REC-FLIPART               PIC X(038).                        00004400
                                                                        00004500
       FD  FLIPARM                                                      00007400
           RECORDING F                                                  00007500
           LABEL RECORD IS STANDARD                                     00007600
           BLOCK CONTAINS 0 RECORDS                                     00007700
           DATA RECORD IS REC-FLIPARM.                                  00007800
       01  REC-FLIPARM              PIC X(080).                         00008000
                                                                        00004560
       FD  FLOPART                                                      00004600
           RECORDING F                                                  00004700
           LABEL RECORD IS STANDARD                                     00004800
           DATA RECORD IS REC-FLOPART.                                  00004900
       01  REC-FLOPART               PIC X(038).                        00005000
                                                                        00005100
       FD  FLOANTE                                                      00004600
           RECORDING F                                                  00004700
           LABEL RECORD IS STANDARD                                     00004800
           DATA RECORD IS REC-FLOPART.                                  00004900
       01  REC-FLOANTE               PIC X(038).                        00005000
                                                                        00005100
                                                                        00005700
       WORKING-STORAGE SECTION.                                         00005800
                                                                        00005900
           EXEC SQL INCLUDE SQLCA END-EXEC.

           EXEC SQL INCLUDE RCCYRSTA END-EXEC.

      ***************************************************************
      ** TRACCIATO RECORD DELLA SCHEDA PARAMETRO FLIPARM           **
      ***************************************************************
           COPY RCCYPARM.

      ***************************************************************
      ** AREA PER CHIAMATA RCBTR05 RICERCA DATE IN RCTBRSTA        **
      ***************************************************************
           COPY RCCYR05.

       01 W-FS-FLIPART              PIC X(2)          VALUE '00'.       00006000
       01 W-FS-FLOPART              PIC X(2)          VALUE '00'.       00006100
       01 W-FS-FLOANTE              PIC X(2)          VALUE '00'.       00006100

       01 W-SQLCODE                 PIC ++++9         VALUE ZEROES.
       01 W-DT-RSTA                 PIC 9(8)          VALUE ZEROES.
       01 FILLER REDEFINES W-DT-RSTA.
          03 W-DT-RSTA-AA           PIC X(4).
          03 W-DT-RSTA-MM           PIC X(2).
          03 W-DT-RSTA-GG           PIC X(2).

       01 W-CONT-FLIPART            PIC S9(9) COMP-3  VALUE ZEROES.     00006400
       01 W-CONT-FLOPART            PIC S9(9) COMP-3  VALUE ZEROES.     00006500
       01 W-CONT-FLOANTE            PIC S9(9) COMP-3  VALUE ZEROES.     00006500
       01 SALVA-DATA-TESTA          PIC S9(09) COMP-3 VALUE ZEROES.     00006500
       01 SALVA-COD-SERV-TESTA      PIC  X(03)        VALUE SPACES.     00006500
                                                                        00008800
      *- DATA DI SISTEMA                                                00009500
       01  W-DATA-SYS.                                                  00009600
           03 W-ANNO                 PIC  9(02)           VALUE ZEROES. 00009700
           03 W-MESE                 PIC  9(02)           VALUE ZEROES. 00009800
           03 W-GIORNO               PIC  9(02)           VALUE ZEROES. 00009900
                                                                        00010000
      *- DATA NUMERICA                                                  00010100
       01  W-DATA-NUM.                                                  00010200
           03 FILLER                 PIC  9(02)           VALUE 20.     00010300
           03 W-ANNO                 PIC  9(02)           VALUE ZEROES. 00010400
           03 W-MESE                 PIC  9(02)           VALUE ZEROES. 00010500
           03 W-GIORNO               PIC  9(02)           VALUE ZEROES. 00010600
                                                                        00010700
      *- DATA ALFANUMERICA
       01 W-DATA-ALFA.
           03 W-SEC                  PIC  X(02)           VALUE '20'.
           03 W-ANNO                 PIC  X(02)           VALUE SPACES.
           03 FILLER                 PIC  X(01)           VALUE '-'   .
           03 W-MESE                 PIC  X(02)           VALUE SPACES.
           03 FILLER                 PIC  X(01)           VALUE '-'   .
           03 W-GIORNO               PIC  X(02)           VALUE SPACES.

       01 REC-RCCY010.
          COPY RCCY010.
                                                                        00013800
      ***************************************************************** 00015500
      *                                                               * 00015600
      *                   INIZIO  PGM                                 * 00015700
      *                                                               * 00015800
      ***************************************************************** 00015900
       PROCEDURE DIVISION.                                              00016000
                                                                        00016100
       INIZIO-RCBT001.                                                  00016200
                                                                        00016300
           PERFORM OP-INIZ         THRU  EX-OP-INIZ.                    00016400
                                                                        00016500
           PERFORM ELABORAZIONE    THRU  EX-ELABORAZIONE.               00016600
                                                                        00016700
           PERFORM OP-FINALI       THRU  EX-OP-FINALI.                  00016800
                                                                        00016900
       FINE-RCBT001.                                                    00017000
           EXIT.                                                        00017100
      ******************************************************************00017200
      *                                                                *00017300
      *               OPERAZIONI INIZIALI                              *00017400
      *                                                                *00017500
      ******************************************************************00017600
       OP-INIZ.                                                         00017700
                                                                        00017800
           DISPLAY '*************************************************'.
           DISPLAY '*--              INIZIO RCBT001               --*'
           DISPLAY '*************************************************'.

           MOVE 0        TO RETURN-CODE                                 00017900
                                                                        00018000
           DISPLAY '                - PROGRAMMA RCBT001: -'.            00018100
           DISPLAY ' '.                                                 00018200
           DISPLAY '                ELABORAZIONE IN CORSO....'.         00018300
           DISPLAY ' '.                                                 00018400
           DISPLAY ' '.                                                 00018500

           OPEN INPUT FLIPART.                                          00018700
           IF W-FS-FLIPART NOT = '00'                                   00018900
              DISPLAY 'ERRORE APERTURA FILE FLIPART :' W-FS-FLIPART     00019000
              MOVE 500       TO RETURN-CODE                             00019100
              PERFORM OP-FINALI THRU EX-OP-FINALI                       00019200
           END-IF.                                                      00019300
                                                                        00019400
           OPEN OUTPUT FLOPART.                                         00019500
           IF W-FS-FLOPART NOT = '00'                                   00019800
              DISPLAY 'ERRORE APERTURA FILE FLOPART :' W-FS-FLOPART     00019900
              MOVE 500       TO RETURN-CODE                             00020000
              PERFORM OP-FINALI THRU EX-OP-FINALI                       00020100
           END-IF.                                                      00020200
                                                                        00021300
           OPEN OUTPUT FLOANTE.                                         00019500
           IF W-FS-FLOANTE NOT = '00'                                   00019800
              DISPLAY 'ERRORE APERTURA FILE FLOANTE :' W-FS-FLOANTE     00019900
              MOVE 500       TO RETURN-CODE                             00020000
              PERFORM OP-FINALI THRU EX-OP-FINALI                       00020100
           END-IF.                                                      00020200

           ACCEPT W-DATA-SYS FROM DATE.
           MOVE CORRESPONDING W-DATA-SYS TO W-DATA-NUM
           MOVE CORRESPONDING W-DATA-NUM TO W-DATA-ALFA.
           DISPLAY 'DATA DI SISTEMA          : ' W-DATA-ALFA
           DISPLAY ' '

           PERFORM ACCETTA-FLIPARM  THRU EX-ACCETTA-FLIPARM.            00044600

           PERFORM  RICERCA-RSTA    THRU    EXIT-RICERCA-RSTA.
                                                                        00021300
       EX-OP-INIZ.                                                      00021400
           EXIT.                                                        00021500
                                                                        00021600
      ******************************************************************00021700
       RICERCA-RSTA.
      *
           INITIALIZE RCCYR05.
           MOVE '1'       TO R05-TIPO-DATA.
           MOVE '4'       TO R05-TRICH.
           MOVE 'RCBTR05' TO R05-PGM-CALL.
           CALL R05-PGM-CALL USING RCCYR05.
           IF R05-RETURN-CODE = '9' OR
              R05-RETURN-CODE = '1'
              DISPLAY R05-MSGERR ':' R05-SQLCODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           IF R05-RETURN-CODE = '0'
              MOVE R05-DCLRCTBRSTA  TO DCLRCTBRSTA
              MOVE  RSTA-DTA(1:4)   TO W-DT-RSTA-AA
              MOVE  RSTA-DTA(6:2)   TO W-DT-RSTA-MM
              MOVE  RSTA-DTA(9:2)   TO W-DT-RSTA-GG
              DISPLAY 'DATA ESTRATTA DA TAB.RICHIESTE: ' RSTA-DTA
           END-IF.
      *
       EXIT-RICERCA-RSTA.
           EXIT.
      *
      ******************************************************************00021700
      *                                                                *00021800
      *        CICLO PRINCIPALE DI ELABORAZIONE FLUSSO DI INPUT        *00021900
      *                                                                *00022000
      ******************************************************************00022100
       ELABORAZIONE.                                                    00022200
                                                                        00022300
           PERFORM LETTURA-FLIPART THRU EX-LETTURA-FLIPART.             00022400

           PERFORM UNTIL W-FS-FLIPART = '10'                            00022600

              IF RCCY010-TIPO-REC = 'A'
                 IF SALVA-DATA-TESTA >= W-DT-RSTA
                    PERFORM SCRIVI-FLOPART    THRU EX-SCRIVI-FLOPART       00023
                 ELSE
                    PERFORM SCRIVI-FLOANTE    THRU EX-SCRIVI-FLOANTE       00023
                 END-IF
                 PERFORM LETTURA-FLIPART      THRU EX-LETTURA-FLIPART   00025000
              END-IF

              PERFORM UNTIL W-FS-FLIPART = '10'
                         OR RCCY010-TIPO-REC = 'Z'
                         OR RCCY010-TIPO-REC = 'A'

                 IF SALVA-DATA-TESTA >= W-DT-RSTA
                    PERFORM SCRIVI-FLOPART    THRU EX-SCRIVI-FLOPART    00023400
                 ELSE
                    PERFORM SCRIVI-FLOANTE    THRU EX-SCRIVI-FLOANTE    00023400
                 END-IF
                 PERFORM LETTURA-FLIPART      THRU EX-LETTURA-FLIPART   00025000
              END-PERFORM

              IF RCCY010-TIPO-REC = 'Z'
                 IF SALVA-DATA-TESTA >= W-DT-RSTA
                    PERFORM SCRIVI-FLOPART    THRU EX-SCRIVI-FLOPART       00023
                 ELSE
                    PERFORM SCRIVI-FLOANTE    THRU EX-SCRIVI-FLOANTE       00023
                 END-IF
                 PERFORM LETTURA-FLIPART      THRU EX-LETTURA-FLIPART   00025000
              END-IF

           END-PERFORM.                                                 00025200
                                                                        00025408
       EX-ELABORAZIONE.                                                 00025410
           EXIT.                                                        00025500
                                                                        00025600
      ******************************************************************00025700
       LETTURA-FLIPART.                                                 00026200
           READ FLIPART INTO REC-RCCY010.                               00026300
           IF W-FS-FLIPART NOT = '00' AND '10'                          00026400
              DISPLAY 'ERRORE LETTURA FILE FLIPART ' W-FS-FLIPART       00026500
              MOVE 500          TO RETURN-CODE                          00026600
              PERFORM OP-FINALI THRU EX-OP-FINALI                       00026700
           END-IF.                                                      00026800
                                                                        00026900
           IF W-FS-FLIPART = '00'                                       00027000
              ADD 1                       TO W-CONT-FLIPART             00027100
              IF RCCY010-TIPO-REC = 'A'                                 00025100
                 MOVE RCCY010-DT-CONT-T   TO SALVA-DATA-TESTA
                 MOVE RCCY010-COD-SERV-T  TO SALVA-COD-SERV-TESTA
              END-IF
           END-IF.                                                      00027200
                                                                        00027300
       EX-LETTURA-FLIPART.                                              00027400
           EXIT.                                                        00027500
      ******************************************************************00041200
                                                                        00027600
       SCRIVI-FLOPART.                                                  00038600
                                                                        00038700
           WRITE REC-FLOPART FROM REC-RCCY010.                          00038800
           ADD 1 TO W-CONT-FLOPART.                                     00039400
                                                                        00039500
       EX-SCRIVI-FLOPART.                                               00039600
           EXIT.                                                        00039700
                                                                        00039800
       SCRIVI-FLOANTE.                                                  00038600
                                                                        00038700
           WRITE REC-FLOANTE FROM REC-RCCY010.                          00038800
           ADD 1 TO W-CONT-FLOANTE.
                                                                        00038700
       EX-SCRIVI-FLOANTE.                                               00039600
           EXIT.                                                        00039700
                                                                        00039800
      ******************************************************************00041200
      *            ELABORAZIONI FINALI                                 *00041400
      ******************************************************************00041600
       OP-FINALI.                                                       00041700
                                                                        00041800
           CLOSE FLIPART.                                               00041900
           IF W-FS-FLIPART NOT = '00'                                   00042100
              DISPLAY 'ERRORE CHIUSURA FILE DI INPUT1' W-FS-FLIPART     00042200
              MOVE 500     TO RETURN-CODE                               00042300
           END-IF.                                                      00042400
                                                                        00042500
           CLOSE FLOPART.                                               00042600
           IF W-FS-FLOPART NOT = '00'                                   00042800
              DISPLAY 'ERRORE CHIUSURA FILE FLOPART '  W-FS-FLOPART     00042900
              MOVE 500     TO RETURN-CODE                               00043000
           END-IF.                                                      00043100

           CLOSE FLOANTE.                                               00042600
           IF W-FS-FLOANTE NOT = '00'                                   00042800
              DISPLAY 'ERRORE CHIUSURA FILE FLOANTE ' W-FS-FLOANTE      00042900
              MOVE 500     TO RETURN-CODE                               00043000
           END-IF.                                                      00043100
           IF RCCYPARM-ERRORE = 'S'
              MOVE 500                   TO RETURN-CODE
           END-IF.                                                      00043100
                                                                        00044000
           DISPLAY ' '.
           DISPLAY ' CODICE SERVIZIO ELABORATO        :'
                     SALVA-COD-SERV-TESTA.
           DISPLAY ' '.
           DISPLAY ' TOTALE RECORD LETTI FILEIN       :' W-CONT-FLIPART 00044200
           DISPLAY ' TOTALE RECORD SCRITTI OUTPUT     :' W-CONT-FLOPART 00044300
           DISPLAY ' TOTALE RECORD ANTECEDENTI DT SVEC:' W-CONT-FLOANTE 00044300
           DISPLAY '*************************************************'.
           DISPLAY '*--              FINE   RCBT001               --*'
           DISPLAY '*************************************************'.
                                                                        00044900
           STOP RUN.                                                    00045000
                                                                        00045100
       EX-OP-FINALI.                                                    00045200
           EXIT.                                                        00045300
      ******************************************************************
      ** LA LABEL ASTERISCATA DI SEGUITO VIENE ESPLOSA ALL'INTERNO    **
      ** DELLA COPY DI PROCEDURE RCCPPARM                             **
      ******************************************************************
      *ACCETTA-FLIPARM.

           COPY RCCPPARM.

      *EX-ACCETTA-FLIPARM.
      *    EXIT.
