      ******************************************************************
      * NOTE :
      ******************************************************************
      *
      * PRODOTTO : SISTEMA RAPPORTI DORMIENTI
      *
      * FUNZIONE : PILOTA ESTINZIONI AL MEF
      *
      * AUTORE   : ENGINEERING
      *
      * PROGRAMMA: RADBT013, COBOL/BATCH
      *
      * PLAN     : RADOPX01
      *
      * INPUT    : RAPP. DORMIENTI
      *
      * INPUT    : RAPP. SALDI
      *
      * OUTPUT   : RAPP. DORMIENTI ESTRATTI
      *
      * OUTPUT   : RAPP. ERRORI LOG
      *
      *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. RADBT013.
       AUTHOR.
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
TEST  *SOURCE-COMPUTER. IBM-3090 WITH DEBUGGING MODE.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *-----------------------------------------------------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *                                  - DORMIENTI   INPUT
           SELECT  IFILRADO       ASSIGN    TO IFILRADO
                                  FILE STATUS IS WS-FS-IFILRADO.
      *                                  - SALDI  INPUT
           SELECT  IFILSALD       ASSIGN    TO IFILSALD
                                  FILE STATUS IS WS-FS-IFILSALD.
      *                                  - ESTINZIONI  INPUT
           SELECT  OFILRADO       ASSIGN    TO OFILRADO
                                  FILE STATUS IS WS-FS-OFILRADO.
      *                                  - ESTINZIONI  INPUT
120218     SELECT  OFILGUID       ASSIGN    TO OFILGUID
120218                            FILE STATUS IS WS-FS-OFILGUID.
      *                                  - LOG ERRORI  OUTPUT
           SELECT  OFILLOGA       ASSIGN    TO OFILLOGA
                                  FILE STATUS IS WS-FS-OFILLOGA.
      ******************************************************************
       DATA DIVISION.
       FILE SECTION.
       FD  IFILRADO
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-IFILRADO                  PIC  X(0326).
       FD  IFILSALD
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-IFILSALD                  PIC  X(0020).
       FD  OFILRADO
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILRADO                  PIC  X(0043).
120218 FD  OFILGUID
120218     LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
120218 01  REC-OFILGUID                  PIC  X(0036).
       FD  OFILLOGA
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILLOGA                  PIC  X(0150).
      *-----------------------------------------------------------------
       WORKING-STORAGE SECTION.
      *                                  - COPY FILE DORMIENTI INPUT
           COPY RADFDRAD.
      *                                  - COPY FILE ERRORI
           COPY RADCLOGA.
      *                                  - AREA FILE ESTRAZIONI OUTPUT
       01  AREA-OFILRADO.
           03 OFIL-TIPSERV               PIC X(02).
           03 OFIL-FILLER1               PIC X(01) VALUE ';'.
           03 OFIL-FILIALE               PIC X(05).
           03 OFIL-FILLER2               PIC X(01) VALUE ';'.
           03 OFIL-RAPPORT               PIC X(12).
           03 OFIL-FILLER3               PIC X(01) VALUE ';'.
           03 OFIL-CATRAPP               PIC X(04).
           03 OFIL-FILLER4               PIC X(01) VALUE ';'.
      *    03 OFIL-FILLER                PIC X(07).
           03 OFIL-SALDO                 PIC +++++++++++9,99.
           03 OFIL-FILLER5               PIC X(01) VALUE ';'.

120218 01  AREA-OFILGUID.
120218     03 OGUI-TIPSERV               PIC X(02).
120218     03 OGUI-FILLER1               PIC X(01) VALUE ';'.
120218     03 OGUI-FILIALE               PIC X(05).
120218     03 OGUI-FILLER2               PIC X(01) VALUE ';'.
120218     03 OGUI-RAPPORT               PIC X(12).
120218     03 OGUI-FILLER3               PIC X(01) VALUE ';'.
120218     03 OGUI-CATRAPP               PIC X(04).
120218     03 OGUI-FILLER4               PIC X(01) VALUE ';'.
120218     03 OGUI-DTESTRA               PIC 9(08).
120218     03 OGUI-FILLER5               PIC X(01) VALUE ';'.

      *                                  - AREA FILE POSIZIONI
       01  AREA-IFILSALD.
           03 SALDI-TIPSERV              PIC X(03).
           03 SALDI-RAPPORT              PIC S9(12) COMP-3.
           03 SALDI-IMPORTO              PIC S9(15)V9(03) COMP-3.

      *                                  - COSTANTI DI LAVORO

       01  WK-COSTANTI-FLAG.
           05 WK-RADYDBRI                PIC X(08) VALUE 'RADYDBRI'.
      *                                  - VARIABILI DI LAVORO

       01  WS-LAVORO.
           05 WS-FS-IFILRADO             PIC X(02).
           05 WS-FS-IFILSALD             PIC X(02).
           05 WS-FS-OFILRADO             PIC X(02).
120218     05 WS-FS-OFILGUID             PIC X(02).
           05 WS-FS-OFILLOGA             PIC X(02).
           05 WS-KEY-IFILRADO.
              07 WS-KEY-TSRADO           PIC X(02).
              07 WS-KEY-RAPRADO          PIC 9(12).
           05 WS-KEY-IFILSALD.
              07 WS-KEY-TSSALDI          PIC X(02).
              07 WS-KEY-RAPSALDI         PIC 9(12).
           05 WS-KEY-LOGA4.
              07 WS-KEY-LOGA4-TS         PIC X(02).
              07 WS-KEY-FILLER           PIC X(01) VALUE '-'.
              07 WS-KEY-LOGA4-RAP        PIC X(13).
           05 WS-PIC12-9                 PIC 9(12).
           05 WS-PIC12-X        REDEFINES
              WS-PIC12-9                 PIC X(12).
           05 WS-SAVE-SALDO              PIC S9(12)V99.
           05 WS-TOT-IFILRADO            PIC S9(18) COMP-3.
           05 WS-TOT-IFILSALD            PIC S9(18) COMP-3.
           05 WS-TOT-SCART-X-STATO       PIC S9(18) COMP-3.
           05 WS-TOT-SCART-X-DTFIN       PIC S9(18) COMP-3.
           05 WS-TOT-ESTR                PIC S9(18) COMP-3.
           05 WS-TOT-BIL                 PIC S9(18) COMP-3.
           05 WS-TOT-OFILRADO            PIC S9(18) COMP-3.
120218     05 WS-TOT-OFILGUID            PIC S9(18) COMP-3.
           05 WS-TOT-OFILLOGA            PIC S9(18) COMP-3.
           05 WS-TOT-BRIC-LETTI          PIC S9(18) COMP-3.
           05  WS-SYSIN-DTFI.
              10 WS-SYSIN-DTFI1          PIC  9(08).
           05  WS-SYSIN-DATE.
              10 WS-SYSIN-DATA1          PIC  9(08).
           05  WS-SYSIN-DATE-R  REDEFINES
               WS-SYSIN-DATE.
              10 WS-SYSIN-DATA1-R        PIC  X(08).
           05  CAMPI-EDIT       OCCURS  20.
               10  NUM-EDIT              PIC ---.---.---.--9.
           05  CAMPI-TIMEDATE.
               10  WSS-DATE-SIS.
                   15  WSS-AAAA          PIC 9(04).
                   15  WSS-MM            PIC 9(02).
                   15  WSS-GG            PIC 9(02).
               10  WSS-TIME-SIS.
                   15  WSS-ORA           PIC 9(02).
                   15  WSS-MIN           PIC 9(02).
                   15  WSS-SEC           PIC 9(02).
               10  DIS-DATE.
                   15  DIS-GG            PIC 9(02).
                   15  FILL-DT1          PIC X(01).
                   15  DIS-MM            PIC 9(02).
                   15  FILL-DT2          PIC X(01).
                   15  DIS-AAAA          PIC 9(04).
               10  DIS-TIME.
                   15  DIS-ORA           PIC 9(02).
                   15  FILL-TM1          PIC X(01).
                   15  DIS-MIN           PIC 9(02).
                   15  FILL-TM2          PIC X(01).
                   15  DIS-SEC           PIC 9(02).
               10  DIS-DATE-INI          PIC X(10).
               10  DIS-TIME-INI          PIC X(08).
               10  WS-DATA-RICH          PIC 9(08).
               10 WS-DATASYS.
                   15 DATASYS-AAAA       PIC 9(04).
                   15 DATASYS-MM         PIC 9(02).
                   15 DATASYS-GG         PIC 9(02).
               10 WS-ORASYS.
                   15 ORASYS-HH          PIC 9(02).
                   15 ORASYS-MM          PIC 9(02).
                   15 ORASYS-SS          PIC 9(02).
           05  CAMPI-ERRORE.
               10  ERR-PROGRAMMA         PIC X(08).
               10  ERR-PUNTO             PIC X(04).
               10  ERR-DESCRIZIONE       PIC X(80).
               10  ERR-CODICE-X          PIC X(06).
               10  ERR-CODICE-Z          PIC -----9.
               10  ERR-DATI              PIC X(30).
               10  ERR-GRAVE             PIC X(02).

      *                                  - COSTANTI E SWITCH
       01  WK-COSTANTI-E-SWITCH.
           05 WK-DA-ELAB                 PIC X(01) VALUE 'N'.
           05 WK-RADBT013                PIC X(08) VALUE 'RADBT013'.
      * DESCRIZIONE DA MODIFICARE------------------>
           05 WK-FASE.
              07 FILLER                PIC X(12) VALUE 'PILOTA '.
              07 FILLER                PIC X(14) VALUE 'ESTINZIONI'.

      *--- COPY ROUTINE RADYDBRI
           COPY RADCDBRI.
      *--- COMMAREA GENERALIZZATA ROUTINE
       01  AREA-ARCHIVIO.
           03 ARCHIVIO-SW                PIC X(02).
           03 ARCHIVIO-TRAC              PIC X(04).
           03 ARCHIVIO-FUNZ              PIC X(03).
           03 ARCHIVIO-PGM               PIC X(08).
           03 ARCHIVIO-DATA              PIC X(08).
           03 ARCHIVIO-ORA               PIC X(06).
           03 ARCHIVIO-TIPOMOD           PIC X(01).
           03 ARCHIVIO-RETCODE           PIC X(06).
           03 ARCHIVIO-FILLER            PIC X(71).
           03 ARCHIVIO-REC               PIC X(1000).
      ******************************************************************
       PROCEDURE DIVISION.
TEST  DDECLARATIVES.
TEST  DCOBOL2-DEBUG SECTION.
TEST  D    USE FOR DEBUGGING ON ALL PROCEDURES.
TEST  DCOBOL2-DEBUG-PARA.
TEST  D    DISPLAY WK-RADBT013 ' --> ' DEBUG-ITEM.
TEST  DEND DECLARATIVES.
      *-----------------------------------

           PERFORM C00010-INIT.
           IF WK-DA-ELAB = 'S'
              PERFORM UNTIL WS-FS-IFILRADO = '10'

                 PERFORM C00100-PREP-KEYS
                 EVALUATE TRUE

                    WHEN WS-KEY-IFILSALD > WS-KEY-IFILRADO
                       IF RADRADO-STRAPPO = '03'
                          IF (RADRADO-DATFINE NOT > WS-SYSIN-DTFI1)
                             ADD 1                TO WS-TOT-ESTR
                             PERFORM C00110-PREP-LOG
                             PERFORM C08110-WRITE-OFILLOGA
                             PERFORM C00100-PREP-OUT
                             PERFORM C08080-WRITE-OFILRADO
120218                       PERFORM C00100-PREP-OUT2
120218                       PERFORM C08080-WRITE-OFILGUID
                          ELSE
                             ADD 1             TO WS-TOT-SCART-X-DTFIN
                          END-IF
                       ELSE
                          ADD 1                TO WS-TOT-SCART-X-STATO
                       END-IF
                       PERFORM C08060-READ-IFILRADO

                    WHEN WS-KEY-IFILSALD = WS-KEY-IFILRADO
                         IF RADRADO-STRAPPO = '03'
                            IF (RADRADO-DATFINE NOT > WS-SYSIN-DTFI1)
                               ADD 1                TO WS-TOT-ESTR
                               ADD 1                TO WS-TOT-BIL
                               PERFORM C00100-PREP-OUT
                               PERFORM C08080-WRITE-OFILRADO
120218                         PERFORM C00100-PREP-OUT2
120218                         PERFORM C08080-WRITE-OFILGUID
                            ELSE
                               ADD 1             TO WS-TOT-SCART-X-DTFIN
                            END-IF
                         ELSE
                            ADD 1                TO WS-TOT-SCART-X-STATO
                         END-IF
                         PERFORM C08060-READ-IFILRADO
                         PERFORM C08070-READ-IFILSALD

                    WHEN WS-KEY-IFILSALD < WS-KEY-IFILRADO
                       PERFORM C08070-READ-IFILSALD

                 END-EVALUATE

              END-PERFORM
           END-IF.
           PERFORM C01000-FINE.


      *-----------------------------------
      *
      *-----------------------------------
       C00010-INIT.
           INITIALIZE WS-LAVORO.
           MOVE WK-RADBT013              TO ERR-PROGRAMMA.
           PERFORM C08180-ACCEPT-TIMEDATE.
           MOVE DIS-DATE                 TO DIS-DATE-INI.
           MOVE DIS-TIME                 TO DIS-TIME-INI.
           PERFORM C08000-OPEN-IFILRADO
           PERFORM C08010-OPEN-IFILSALD
           PERFORM C08020-OPEN-OFILRADO
120218     PERFORM C08020-OPEN-OFILGUID
           PERFORM C08030-OPEN-OFILLOGA
           PERFORM C00020-DISPL-INIT.
           PERFORM C08185-ACCEPT-SYSIN.
           PERFORM C00030-GEST-SYSIN.
           PERFORM C00900-CALL-RADYDBRI.
TOGL       DISPLAY'OPC1   ' WS-SYSIN-DATA1
TOGL       DISPLAY'DTRICH ' WS-DATA-RICH
           IF WS-SYSIN-DATA1 = WS-DATA-RICH
           AND BRIC-TIPO-FUNZ = 'EST'
           AND BRIC-STATO     = 'A'
           AND BRIC-TIPO-RICH = 'I'
              PERFORM C08060-READ-IFILRADO
              PERFORM C08070-READ-IFILSALD
              MOVE 'S'    TO WK-DA-ELAB
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00020-DISPL-INIT.
           DISPLAY
           '*======================================================*'.
           DISPLAY
           '*====        INIZIO ELABORAZIONE PROGRAMMA         ====*'.
           DISPLAY
           '*====   DATA INIZIO: ' DIS-DATE-INI.
           DISPLAY
           '*====    ORA INIZIO: ' DIS-TIME-INI.
      *-----------------------------------
      * CHIAMATA ALLA ROUTINE RADYDBRI CHE ACCEDE ALLA RADBRIC
      *-----------------------------------
       C00900-CALL-RADYDBRI.
           INITIALIZE AREA-ARCHIVIO
                      RADCDBRI-REC
           MOVE WS-SYSIN-DATA1           TO BRIC-DATA-RICH
           MOVE RADCDBRI-REC             TO ARCHIVIO-REC
           MOVE '0003'                   TO ARCHIVIO-TRAC
           MOVE 'RED'                    TO ARCHIVIO-FUNZ
           CALL WK-RADYDBRI USING AREA-ARCHIVIO END-CALL
           EVALUATE ARCHIVIO-SW
             WHEN 'SI'
               ADD 1                     TO WS-TOT-BRIC-LETTI END-ADD
               MOVE ARCHIVIO-REC         TO RADCDBRI-REC
               MOVE BRIC-DATA-RICH       TO WS-DATA-RICH
               MOVE BRIC-PB01-DT-FINEPER TO WS-SYSIN-DTFI
      *
             WHEN 'NF'
               CONTINUE
             WHEN OTHER
               MOVE '0012'               TO ERR-PUNTO
               MOVE 'ERRORE ACCESSO ROUTINE RADYDBRI'
                                         TO ERR-DESCRIZIONE
               MOVE ARCHIVIO-RETCODE     TO ERR-CODICE-X
               PERFORM C09000-ERRORE
               PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C00030-GEST-SYSIN.
           IF (WS-SYSIN-DATA1-R NOT NUMERIC)
           OR (WS-SYSIN-DATA1-R = ZEROES)
           OR (WS-SYSIN-DATA1-R = 99999999)
              MOVE '0001'                TO ERR-PUNTO
              MOVE 'VALORE SYSIN ERRATO' TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILRADO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00100-PREP-OUT.
           INITIALIZE AREA-OFILRADO
           IF WS-KEY-IFILSALD = WS-KEY-IFILRADO
              MOVE SALDI-IMPORTO         TO WS-SAVE-SALDO
           END-IF.
           MOVE WS-SAVE-SALDO            TO OFIL-SALDO
           MOVE RADRADO-TIPSERV          TO OFIL-TIPSERV
           MOVE RADRADO-FILIALE          TO OFIL-FILIALE
           MOVE RADRADO-RAPPORT          TO WS-PIC12-9
           MOVE WS-PIC12-X               TO OFIL-RAPPORT
           MOVE RADRADO-CATRAPP          TO OFIL-CATRAPP
           MOVE ';'                      TO OFIL-FILLER1
                                            OFIL-FILLER2
                                            OFIL-FILLER3
                                            OFIL-FILLER4
                                            OFIL-FILLER5.
      *    DISPLAY 'AREA-OFILRADO ' AREA-OFILRADO
           MOVE AREA-OFILRADO            TO REC-OFILRADO.
      *-----------------------------------
120218 C00100-PREP-OUT2.
120218     INITIALIZE AREA-OFILGUID
120218     MOVE RADRADO-TIPSERV          TO OGUI-TIPSERV
120218     MOVE RADRADO-FILIALE          TO OGUI-FILIALE
120218     MOVE RADRADO-RAPPORT          TO WS-PIC12-9
120218     MOVE WS-PIC12-X               TO OGUI-RAPPORT
120218     MOVE RADRADO-CATRAPP          TO OGUI-CATRAPP
120218     MOVE RADRADO-DTESTRA          TO OGUI-DTESTRA
120218     MOVE ';'                      TO OGUI-FILLER1
120218                                      OGUI-FILLER2
120218                                      OGUI-FILLER3
120218                                      OGUI-FILLER4
120218                                      OGUI-FILLER5.
120218     MOVE AREA-OFILGUID            TO REC-OFILGUID.
      *-----------------------------------
      *
      *-----------------------------------
       C01000-FINE.
           PERFORM C08120-CLOSE-IFILRADO.
           PERFORM C08130-CLOSE-IFILSALD.
           PERFORM C08140-CLOSE-OFILRADO.
120218     PERFORM C08140-CLOSE-OFILGUID.
           PERFORM C08150-CLOSE-OFILLOGA.
           PERFORM C09020-STATISTICHE.
           PERFORM C09030-END.
      *-----------------------------------
      *
      *-----------------------------------
       C08000-OPEN-IFILRADO.
           OPEN INPUT IFILRADO.
           IF WS-FS-IFILRADO = '00'
              EXIT
           ELSE
              MOVE '0010'                TO ERR-PUNTO
              MOVE 'OPEN IFILRADO'       TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILRADO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08010-OPEN-IFILSALD.
           OPEN INPUT IFILSALD.
           IF WS-FS-IFILSALD = '00'
              EXIT
           ELSE
              MOVE '0010'                TO ERR-PUNTO
              MOVE 'OPEN IFILSALD'       TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILSALD        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08020-OPEN-OFILRADO.
           OPEN OUTPUT OFILRADO.
           IF WS-FS-OFILRADO = '00'
              EXIT
           ELSE
              MOVE '0011'                TO ERR-PUNTO
              MOVE 'OPEN OFILRADO'       TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILRADO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
120218 C08020-OPEN-OFILGUID.
120218     OPEN OUTPUT OFILGUID.
120218     IF WS-FS-OFILGUID = '00'
120218        EXIT
120218     ELSE
120218        MOVE '0011'                TO ERR-PUNTO
120218        MOVE 'OPEN OFILGUID'       TO ERR-DESCRIZIONE
120218        MOVE WS-FS-OFILGUID        TO ERR-CODICE-X
120218        PERFORM C09000-ERRORE
120218        PERFORM C09030-END
120218     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08030-OPEN-OFILLOGA.
           OPEN OUTPUT OFILLOGA.
           IF WS-FS-OFILLOGA = '00'
              EXIT
           ELSE
              MOVE '0011'                TO ERR-PUNTO
              MOVE 'OPEN OFILLOGA'       TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILLOGA        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08060-READ-IFILRADO.
           READ IFILRADO INTO RADRADO-RECF.
           EVALUATE WS-FS-IFILRADO
              WHEN '00'
                ADD 1                    TO WS-TOT-IFILRADO
                MOVE RADRADO-SALDO       TO WS-SAVE-SALDO
              WHEN '10'
                MOVE HIGH-VALUE          TO RADRADO-TIPSERV
                MOVE 999999999999        TO RADRADO-RAPPORT
              WHEN OTHER
                MOVE '0012'              TO ERR-PUNTO
                MOVE 'READ IFILRADO'     TO ERR-DESCRIZIONE
                MOVE WS-FS-IFILRADO      TO ERR-CODICE-X
                PERFORM C09000-ERRORE
                PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C08070-READ-IFILSALD.
           READ IFILSALD.
           EVALUATE WS-FS-IFILSALD
              WHEN '00'
                ADD 1                    TO WS-TOT-IFILSALD
                MOVE REC-IFILSALD        TO AREA-IFILSALD
              WHEN '10'
                MOVE HIGH-VALUE          TO SALDI-TIPSERV
                MOVE 999999999999        TO SALDI-RAPPORT
              WHEN OTHER
                MOVE '0012'              TO ERR-PUNTO
                MOVE 'READ IFILRADO'     TO ERR-DESCRIZIONE
                MOVE WS-FS-IFILRADO      TO ERR-CODICE-X
                PERFORM C09000-ERRORE
                PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C00100-PREP-KEYS.
           MOVE RADRADO-TIPSERV          TO WS-KEY-TSRADO
           MOVE RADRADO-RAPPORT          TO WS-KEY-RAPRADO
           MOVE SALDI-TIPSERV            TO WS-KEY-TSSALDI
           MOVE SALDI-RAPPORT            TO WS-KEY-RAPSALDI.
      *-----------------------------------
      *
      *-----------------------------------
       C08080-WRITE-OFILRADO.
           WRITE REC-OFILRADO.
           IF WS-FS-OFILRADO = '00'
              ADD 1                      TO WS-TOT-OFILRADO
           ELSE
              MOVE '0013'                TO ERR-PUNTO
              MOVE 'WRITE OFILRADO'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILRADO        TO ERR-CODICE-X
              MOVE REC-OFILRADO          TO ERR-DATI
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
120218 C08080-WRITE-OFILGUID.
120218     WRITE REC-OFILGUID.
120218     IF WS-FS-OFILGUID = '00'
120218        ADD 1                      TO WS-TOT-OFILGUID
120218     ELSE
120218        MOVE '0013'                TO ERR-PUNTO
120218        MOVE 'WRITE OFILGUID'      TO ERR-DESCRIZIONE
120218        MOVE WS-FS-OFILGUID        TO ERR-CODICE-X
120218        MOVE REC-OFILGUID          TO ERR-DATI
120218        PERFORM C09000-ERRORE
120218        PERFORM C09030-END
120218     END-IF.
LOG   *-----------------------------------
LOG   *
LOG   *-----------------------------------
       C00110-PREP-LOG.
           INITIALIZE RADSLOGA-REC.
           PERFORM C08180-ACCEPT-TIMEDATE.
           MOVE DATASYS-GG               TO LOGA-DATAELAB(7:2).
           MOVE DATASYS-MM               TO LOGA-DATAELAB(5:2).
           MOVE DATASYS-AAAA             TO LOGA-DATAELAB(1:4).
           MOVE WK-FASE                  TO LOGA-FASE.
           MOVE WK-RADBT013              TO LOGA-PROGRAMMA.
           IF WS-KEY-IFILSALD > WS-KEY-IFILRADO
              MOVE 'RAPPORTO DI RADO NON PRESENTE IN POSIZIONI'
                                         TO LOGA-DESCANOM
              MOVE WS-KEY-TSRADO         TO WS-KEY-LOGA4-TS
              MOVE WS-KEY-RAPRADO        TO WS-KEY-LOGA4-RAP
           END-IF.
      *    IF WS-KEY-IFILSALD < WS-KEY-IFILRADO
      *       ADD 1                      TO WS-TOT-LOG-NORADO
      *       MOVE 'RAPPORTO DI SALDI ASSENTE SU RADO'
      *                                  TO LOGA-DESCANOM
      *       MOVE SALDI-TIPSERV         TO WS-KEY-LOGA4-TS
      *       MOVE WS-KEY-RAPSALDI       TO WS-KEY-LOGA4-RAP
      *    END-IF
      *    IF WS-KEY-IFILRADO = WS-KEY-IFILSALD
      *       MOVE WS-DESCANOM           TO LOGA-DESCANOM
      *       MOVE RADRADO-TIPSERV       TO WS-KEY-LOGA4-TS
      *       MOVE WS-KEY-RAPRADO        TO WS-KEY-LOGA4-RAP
      *    END-IF
           MOVE WS-KEY-LOGA4             TO LOGA-KEY.
      *-----------------------------------
      *
      *-----------------------------------
       C08110-WRITE-OFILLOGA.
           WRITE REC-OFILLOGA FROM RADSLOGA-REC.
           IF WS-FS-OFILLOGA = '00'
              ADD 1                      TO WS-TOT-OFILLOGA
           ELSE
              MOVE '0008'                TO ERR-PUNTO
              MOVE 'WRITE OFILLOGA'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILLOGA        TO ERR-CODICE-X
              MOVE REC-OFILLOGA          TO ERR-DATI
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08120-CLOSE-IFILRADO.
           CLOSE IFILRADO.
           IF WS-FS-IFILRADO = '00'
              EXIT
           ELSE
              MOVE '0014'                TO ERR-PUNTO
              MOVE 'CLOSE IFILRADO'      TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILRADO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08130-CLOSE-IFILSALD.
           CLOSE IFILSALD.
           IF WS-FS-IFILSALD = '00'
              EXIT
           ELSE
              MOVE '0014'                TO ERR-PUNTO
              MOVE 'CLOSE IFILSALD'      TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILSALD        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08140-CLOSE-OFILRADO.
           CLOSE OFILRADO.
           IF WS-FS-OFILRADO = '00'
              EXIT
           ELSE
              MOVE '0015'                TO ERR-PUNTO
              MOVE 'CLOSE OFILRADO'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILRADO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
120218 C08140-CLOSE-OFILGUID.
120218     CLOSE OFILGUID.
120218     IF WS-FS-OFILGUID = '00'
120218        EXIT
120218     ELSE
120218        MOVE '0015'                TO ERR-PUNTO
120218        MOVE 'CLOSE OFILGUID'      TO ERR-DESCRIZIONE
120218        MOVE WS-FS-OFILGUID        TO ERR-CODICE-X
120218        PERFORM C09000-ERRORE
120218        PERFORM C09030-END
120218     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08150-CLOSE-OFILLOGA.
           CLOSE OFILLOGA.
           IF WS-FS-OFILLOGA = '00'
              EXIT
           ELSE
              MOVE '0015'                TO ERR-PUNTO
              MOVE 'CLOSE OFILLOGA'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILLOGA        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C08180-ACCEPT-TIMEDATE.
           ACCEPT WSS-TIME-SIS FROM TIME.
           MOVE WSS-ORA                         TO DIS-ORA
                                                   ORASYS-HH.
           MOVE WSS-MIN                         TO DIS-MIN
                                                   ORASYS-MM.
           MOVE WSS-SEC                         TO DIS-SEC
                                                   ORASYS-SS.
           MOVE ':'                             TO FILL-TM1.
           MOVE ':'                             TO FILL-TM2.
           ACCEPT WSS-DATE-SIS FROM DATE YYYYMMDD.
           MOVE WSS-AAAA                        TO DIS-AAAA
                                                   DATASYS-AAAA.
           MOVE WSS-MM                          TO DIS-MM
                                                   DATASYS-MM.
           MOVE WSS-GG                          TO DIS-GG
                                                   DATASYS-GG.
           MOVE '-'                             TO FILL-DT1.
           MOVE '-'                             TO FILL-DT2.
      *-----------------------------------
      *
      *-----------------------------------
       C08185-ACCEPT-SYSIN.
           ACCEPT WS-SYSIN-DATE FROM SYSIN.
      *-----------------------------------
      *
      *-----------------------------------
       C09000-ERRORE.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====                 ERRORE GRAVE                 ====*'.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====   PROGRAMMA    : ' ERR-PROGRAMMA.
           DISPLAY
           '*====   PUNTO        : ' ERR-PUNTO.
           DISPLAY
           '*====   DESCRIZIONE  : ' ERR-DESCRIZIONE.
           DISPLAY
           '*====   CODICE-X     : ' ERR-CODICE-X.
           DISPLAY
           '*====   CODICE-9     : ' ERR-CODICE-Z.
           DISPLAY
           '*====   DATI         : ' ERR-DATI.
           MOVE 12                              TO RETURN-CODE.

      *-----------------------------------
      *
      *-----------------------------------
       C09020-STATISTICHE.
           MOVE WS-TOT-IFILRADO                 TO NUM-EDIT(01).
           MOVE WS-TOT-IFILSALD                 TO NUM-EDIT(02).
           MOVE WS-TOT-BIL                      TO NUM-EDIT(03).
           MOVE WS-TOT-SCART-X-STATO            TO NUM-EDIT(04).
           MOVE WS-TOT-SCART-X-DTFIN            TO NUM-EDIT(05).
           MOVE WS-TOT-ESTR                     TO NUM-EDIT(06).
           MOVE WS-TOT-OFILRADO                 TO NUM-EDIT(07).
120218     MOVE WS-TOT-OFILGUID                 TO NUM-EDIT(10).
           MOVE WS-TOT-OFILLOGA                 TO NUM-EDIT(08).
           MOVE WS-TOT-BRIC-LETTI               TO NUM-EDIT(09).
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====            S T A T I S T I C H E             ====*'.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY ' TOT. LETTI RADBRIC..........: ' NUM-EDIT(09).
           DISPLAY ' TOT. LETTI RAPPORTI.........: ' NUM-EDIT(01).
           DISPLAY ' TOT. LETTI SALDI............: ' NUM-EDIT(02).
           DISPLAY '   DI  CUI BILANCIATI........: ' NUM-EDIT(03).
           DISPLAY '   DI CUI SCARTATI             '.
           DISPLAY '     PER STATO...............: ' NUM-EDIT(04).
           DISPLAY '     PER DATA FINE VALIDITA..: ' NUM-EDIT(05).
           DISPLAY '   DI CUI DA ESTRARRE........: ' NUM-EDIT(06).
           DISPLAY '                               '.
           DISPLAY ' TOT. SCRITTI RAPPORTI.......: ' NUM-EDIT(07).
           DISPLAY ' TOT. SCRITTI LOG............: ' NUM-EDIT(08).
120218     DISPLAY ' TOT. SCRITTI PILOTA.........: ' NUM-EDIT(10).
      *-----------------------------------
      *
      *-----------------------------------
       C09030-END.
           PERFORM C08180-ACCEPT-TIMEDATE.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====          FINE ELABORAZIONE PROGRAMMA         ====*'.
           DISPLAY
           '*====     DATA FINE: ' DIS-DATE.
           DISPLAY
           '*====      ORA FINE: ' DIS-TIME.
           DISPLAY
           '*======================================================*'.
           STOP RUN.
      *=====================      END       ****************************
