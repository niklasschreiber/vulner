      ******************************************************************
      * NOTE :
      ******************************************************************
      *
      * PRODOTTO : SISTEMA RAPPORTI DORMIENTI
      *
      * FUNZIONE : PREVIEW INVIO A MEF
      *
      * AUTORE   : ENGINEERING
      *
      * PROGRAMMA: RADBT006, COBOL/BATCH
      *
      * PLAN     : RADOPX01
      *
      * INPUT    : RAPP. DORM., POSIZIONI CC E DR
      *
      * OUTPUT   : RAPP. DORM., MEF OFF  LINE, MEF ALTRI, LOG ERRORI
      *            LOGICI
      *
      ******************************************************************
090218* 09/02/2018 TABULATO BLOCCHI SIRADO - GENERA UN LOG PER I SOLI DR
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. RADBT006.
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
110257*                                  - DORMIENTI   INPUT
110257     SELECT  IFILPRE        ASSIGN    TO IFILPRE
110257                            FILE STATUS IS WS-FS-IFILPRE.
      *                                  - DORMIENTI   INPUT
           SELECT  IFILRADO       ASSIGN    TO IFILRADO
                                  FILE STATUS IS WS-FS-IFILRADO.
      *                                  - ESTINZIONI  INPUT
           SELECT  IFILPOSI       ASSIGN    TO IFILPOSI
                                  FILE STATUS IS WS-FS-IFILPOSI.
      *                                  - MEF OFFLINE OUTPUT
           SELECT  OFILMEFO       ASSIGN    TO OFILMEFO
                                  FILE STATUS IS WS-FS-OFILMEFO.
      *                                  - LOG ERRORI  OUTPUT
090218     SELECT  OFILEDR        ASSIGN    TO OFILEDR
090218                            FILE STATUS IS WS-FS-OFILEDR.
090218*                                  - LOG ERRORI  OUTPUT
           SELECT  OFILLOGA       ASSIGN    TO OFILLOGA
                                  FILE STATUS IS WS-FS-OFILLOGA.
      *                                  - LOG ERRORI  OUTPUT
110257     SELECT  OFILPRE        ASSIGN    TO OFILPRE
110257                            FILE STATUS IS WS-FS-OFILPRE.
      ******************************************************************
       DATA DIVISION.
       FILE SECTION.
110257 FD  IFILPRE
110257     LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
110257 01  REC-IFILPRE                   PIC  X(0237).
       FD  IFILRADO
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-IFILRADO                  PIC  X(0326).
       FD  IFILPOSI
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-IFILPOSI                  PIC  X(0020).
       FD  OFILMEFO
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILMEFO                  PIC  X(0614).
090218 FD  OFILEDR
090218     LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
090218 01  REC-OFILEDR                   PIC  X(0021).
       FD  OFILLOGA
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILLOGA                  PIC  X(0150).
110257 FD  OFILPRE
110257     LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
110257 01  REC-OFILPRE                   PIC  X(0237).
      *-----------------------------------------------------------------
       WORKING-STORAGE SECTION.
      *                                  - COPY FILE DORMIENTI
           COPY RADFDRAD.
      *                                  - COPY FILE MEF
           COPY RADCDMEF.
      *                                  - COPY FILE LOG ERRORI
           COPY RADCLOGA.
      *                                  - COPY FILE RADBRIC
110257     COPY RADCDBRI.
090218*
090218 01  OFILEDR-RECF.
090218     02  OFILEDR-FILIALE                PIC X(5).
090218     02  OFILEDR-RAPPORT                PIC 9(12).
090218     02  OFILEDR-CATRAPP                PIC X(4).
      *                                  - AREA FILE POSIZIONI
       01  AREA-IFILPOSI.
           03 POSI-TIPSERV               PIC X(03).
           03 POSI-RAPPORT               PIC S9(12) COMP-3.
           03 POSI-IMPORTO               PIC S9(15)V9(03) COMP-3.
      *                                  - COPY ROUTINE ANAG COD.FISCALE
           COPY ACS099A.
      *                                  - COPY ROUTINE ANAG COLLEGATI
       01  AREA-ACS023.
           COPY ACS023A.
      *                                  - COPY ROUTINE ANAG INTESTAT.
       01  AREA-ACS108.
           COPY ACS108A.
      *                                  - COPY ROUTINE NAZIONI
           COPY ACZ023A.
      *                                  - COPY ROUTINE CAB  COBRTG01
           COPY COCRTG01.
      *                                  - COPY ROUTINE ANAG OFF-LINE
           COPY SRVCDR09.
      *                                  - COPY ROUTINE ANAG SVN
           COPY SRVCDVNN.
      *                                  - AREA SRVYDNVN
       01  AREA-SRVYDNVN.
           03  ARCHIVIO-SW               PIC X(02).
           03  ARCHIVIO-TRAC             PIC X(04).
           03  ARCHIVIO-FUNZ             PIC X(03).
           03  ARCHIVIO-PGM              PIC X(08).
           03  ARCHIVIO-DATA             PIC X(08).
           03  ARCHIVIO-ORA              PIC X(06).
           03  ARCHIVIO-TIPOMOD          PIC X(01).
           03  ARCHIVIO-RETCODE          PIC X(06).
           03  ARCHIVIO-FILLER           PIC X(71).
           03  ARCHIVIO-REC              PIC X(01000).
      *                                  - VARIABILI DI LAVORO
       01  WS-LAVORO.
110257     05 WS-FS-IFILPRE              PIC X(02).
           05 WS-FS-IFILRADO             PIC X(02).
           05 WS-FS-IFILPOSI             PIC X(02).
           05 WS-FS-OFILMEFO             PIC X(02).
           05 WS-FS-OFILEDR              PIC X(02).
           05 WS-FS-OFILLOGA             PIC X(02).
           05 WS-FS-OFILPRE              PIC X(02).
           05 WS-KEY-RADRADO             PIC X(14).
           05 WS-KEY-RADPOSI             PIC X(14).
           05 WS-PIC06-9                 PIC 9(06).
           05 WS-PIC06-X        REDEFINES
              WS-PIC06-9                 PIC X(06).
           05 WS-PIC08-9                 PIC 9(08).
           05 WS-PIC08-X        REDEFINES
              WS-PIC08-9                 PIC X(08).
           05 WS-PIC12-9                 PIC 9(12).
           05 WS-PIC12-X        REDEFINES
              WS-PIC12-9                 PIC X(12).
           05 WS-PIC07V02-9              PIC 9(07)V9(02).
           05 WS-PIC07V02-X1    REDEFINES
              WS-PIC07V02-9.
              10 WS-PIC07V-X1            PIC X(07).
              10 WS-PICV02-X1            PIC X(02).
           05 WS-PIC12V02-9              PIC 9(12)V9(02).
           05 WS-PIC12V02-X2    REDEFINES
              WS-PIC12V02-9.
              10 WS-PIC12V-X2            PIC X(12).
              10 WS-PICV02-X2            PIC X(02).
           05 WS-EDI10.
              10 WS-EDI10-07             PIC X(07).
              10 WS-EDI10-V              PIC X(01).
              10 WS-EDI10-02             PIC X(02).
           05 WS-EDI15.
              10 WS-EDI15-12             PIC X(12).
              10 WS-EDI15-V              PIC X(01).
              10 WS-EDI15-02             PIC X(02).
           05 WS-APPO-COD-FISC           PIC X(16).
           05 WS-APPO-OFILMEFO           PIC X(614).
           05 WS-APPO-OFILEDR            PIC X(021).
           05 WS-APPO-PRIMO-ACS108       PIC X(1800).
           05 WS-COUNT-CLL-RAPP          PIC 9(05)  COMP-3.
           05 WS-COUNT-RAPP-ELAB         PIC 9(09)  COMP-3.
           05 WS-COUNT-TITOLARI          PIC 9(09)  COMP-3.
           05 WS-IND01                   PIC 9(05)  COMP-3.
           05 WS-SUM-IMPORTO             PIC 9(12)V9(02).
           05 WS-SEGNO                   PIC X(01).
           05 WS-I-CAB-ASSENTE           PIC S9(15) COMP-3.
           05 WS-I-COD-FISC-ERR          PIC S9(15) COMP-3.
           05 WS-I-SCART-NO-AN           PIC S9(15) COMP-3.
           05 WS-I-SCART-NO-POSIZ        PIC S9(15) COMP-3.
           05 WS-I-SCART-NO-SALDO        PIC S9(15) COMP-3.
           05 WS-I-SCART-NO-VN           PIC S9(15) COMP-3.
           05 WS-I-SCART-DTVAL           PIC S9(15) COMP-3.
           05 WS-I-SCART-TIPSERV         PIC S9(15) COMP-3.
           05 WS-I-TOT-IFILPOSI          PIC S9(15) COMP-3.
           05 WS-I-TOT-IFILRADO          PIC S9(15) COMP-3.
           05 WS-I-TOT-SCART-ALL         PIC S9(15) COMP-3.
           05 WS-O-TOT-FF                PIC S9(15) COMP-3.
           05 WS-O-TOT-FILLOGA           PIC S9(15) COMP-3.
           05 WS-O-TOT-NL                PIC S9(15) COMP-3.
           05 WS-O-TOT-NL-NN-COI         PIC S9(15) COMP-3.
           05 WS-O-TOT-NL-COI-SENZA      PIC S9(15) COMP-3.
           05 WS-O-TOT-NL-COI            PIC S9(15) COMP-3.
           05 WS-O-TOT-RAPPO             PIC S9(15) COMP-3.
           05 WS-O-TOT-REC               PIC S9(15) COMP-3.
           05 WS-O-TOT-REC0              PIC S9(15) COMP-3.
           05 WS-O-TOT-REC1              PIC S9(15) COMP-3.
           05 WS-O-TOT-REC2              PIC S9(15) COMP-3.
           05 WS-O-TOT-REC9              PIC S9(15) COMP-3.
090218     05 WS-O-TOT-REC1-DR           PIC S9(15) COMP-3.
090218     05 WS-O-TOT-REC-DR            PIC S9(15) COMP-3.
           05 WS-SYSIN-SKED.
              10 WS-SYSIN-DATFINE        PIC  9(08).
              10 WS-SYSIN-DATOPC         PIC  9(08).
              10 WS-SYSIN-DATOPC-R REDEFINES
                 WS-SYSIN-DATOPC         PIC  X(08).
           05  CAMPI-EDIT       OCCURS  30.
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
               10 WS-DATASYS.
                   15 DATASYS-GG         PIC 9(02).
                   15 DATASYS-MM         PIC 9(02).
                   15 DATASYS-AAAA       PIC 9(04).
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
       01  WK-COSTANTI-E-SWITCH.
110257     05 WK-DATA-RICH               PIC 9(08) VALUE ZEROES.
110257     05 WK-DATA-FINE               PIC 9(08) VALUE ZEROES.
           05 WK-ACS023BT                PIC X(08) VALUE 'ACS023BT'.
           05 WK-ACS099BT                PIC X(08) VALUE 'ACS099BT'.
           05 WK-ACS108BT                PIC X(08) VALUE 'ACS108BT'.
           05 WK-ACZ023BT                PIC X(08) VALUE 'ACZ023BT'.
           05 WK-COBRTG01                PIC X(08) VALUE 'COBRTG01'.
           05 WK-RADBT006                PIC X(08) VALUE 'RADBT006'.
           05 WK-SRVB0010                PIC X(08) VALUE 'SRVB0010'.
           05 WK-SRVYDNVN                PIC X(08) VALUE 'SRVYDNVN'.
           05 WK-FASE                    PIC X(30) VALUE
                                             'PREVIEW INVIO A MEF'.
           05 WK-SALDO-NNVAL             PIC S9(15)V9(03) COMP-3
                                                   VALUE +100,00.
           05 WK-OFFLINE                 PIC X(01) VALUE 'N'.
           05 SW-CONTINUA                PIC X(01).
             88 NO-CONTINUA                        VALUE '0'.
             88 SI-CONTINUA                        VALUE '1'.
           05 SW-COLLEGATI               PIC X(01).
             88 NO-COLLEGATI                       VALUE '0'.
             88 SI-COLLEGATI                       VALUE '1'.
      *-----------------------------------------------------------------
       LINKAGE SECTION.
      ******************************************************************
       PROCEDURE DIVISION.
TEST  DDECLARATIVES.
TEST  DCOBOL2-DEBUG SECTION.
TEST  D    USE FOR DEBUGGING ON ALL PROCEDURES.
TEST  DCOBOL2-DEBUG-PARA.
TEST  D    DISPLAY WK-RADBT006 ' --> ' DEBUG-ITEM.
TEST  DEND DECLARATIVES.
      *-----------------------------------
           PERFORM C00010-INIT
           PERFORM UNTIL WS-FS-IFILRADO = '10'
              IF RADRADO-TIPSERV = 'CC' OR 'DR' OR 'DT'
110257*          IF RADRADO-DATFINE > WS-SYSIN-DATFINE
110257           IF RADRADO-DATFINE > WK-DATA-FINE
                    PERFORM C00620-GEST-SCART-DTVAL
                    PERFORM C01050-LEGGE-IFILRADO
                 ELSE
                    PERFORM C00100-GEST-RADO-POSI
                 END-IF
              ELSE
                PERFORM C00630-GEST-SCART-TIPSERV
                PERFORM C01050-LEGGE-IFILRADO
              END-IF
           END-PERFORM
           PERFORM C00210-FINE.
      *-----------------------------------
      *
      *-----------------------------------
       C00010-INIT.
           INITIALIZE WS-LAVORO
           PERFORM C01130-ACCEPT-TIMEDATE
110257*    PERFORM C01140-ACCEPT-SYSIN
           MOVE WK-RADBT006              TO ERR-PROGRAMMA
           MOVE DIS-DATE                 TO DIS-DATE-INI
           MOVE DIS-TIME                 TO DIS-TIME-INI
           PERFORM C00020-DISPL-INIT
110257     PERFORM C01010-APRE-IFILPRE
           PERFORM C01010-APRE-IFILRADO
           PERFORM C01020-APRE-IFILPOSI
           PERFORM C01030-APRE-OFILMEFO
090218     PERFORM C01035-APRE-OFILEDR
           PERFORM C01040-APRE-OFILLOGA
110257     PERFORM C01040-APRE-OFILPRE
110257     PERFORM C01050-LEGGE-IFILPRE
           PERFORM C01050-LEGGE-IFILRADO
           PERFORM C01060-LEGGE-IFILPOSI
           PERFORM C00510-PREP-REC0.
      *-----------------------------------
      *
      *-----------------------------------
       C00020-DISPL-INIT.
           DISPLAY
           '*======================================================*'
           DISPLAY
           '*====        INIZIO ELABORAZIONE PROGRAMMA         ====*'
           DISPLAY
           '*====   DATA INIZIO: ' DIS-DATE-INI
           DISPLAY
           '*====    ORA INIZIO: ' DIS-TIME-INI.
      *-----------------------------------
      *
      *-----------------------------------
       C00100-GEST-RADO-POSI.
           IF WS-KEY-RADRADO > WS-KEY-RADPOSI
              PERFORM C01060-LEGGE-IFILPOSI
           ELSE
              IF WS-KEY-RADRADO = WS-KEY-RADPOSI
                 PERFORM C00110-GEST-RAPPORTO
              ELSE
                 IF WS-KEY-RADRADO < WS-KEY-RADPOSI
                    PERFORM C00640-GEST-SCART-NOPOSIZ
                 END-IF
              END-IF
              PERFORM C01050-LEGGE-IFILRADO
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00110-GEST-RAPPORTO.
           IF POSI-IMPORTO > WK-SALDO-NNVAL
              EVALUATE RADRADO-TIPSERV
                WHEN 'CC'
                WHEN 'DT'
                  PERFORM C00140-GEST-ONLINE
                WHEN 'DR'
                  PERFORM C01150-CHIAMA-SRVB0010
                  IF DR09-FLAGCON = WK-OFFLINE
                     PERFORM C00120-GEST-DR-OFFLN
                  ELSE
                     PERFORM C00140-GEST-ONLINE
                  END-IF
              END-EVALUATE
           ELSE
              PERFORM C00650-GEST-SCART-SALDO-NNVAL
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00120-GEST-DR-OFFLN.
           PERFORM C01160-CHIAMA-COBRTG01
           PERFORM C01170-CHIAMA-SRVYDNVN
           IF SI-CONTINUA
              PERFORM C00130-GEST-OUT-DR-OFFLN
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00130-GEST-OUT-DR-OFFLN.
           PERFORM C00520-PREP-OFFLN-REC1
           MOVE RADMEF-REC1-FRAME        TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
           ADD 1                         TO WS-O-TOT-REC1
090218     IF  RADRADO-TIPSERV  = 'DR'
090218         ADD 1                     TO WS-O-TOT-REC1-DR
090218     END-IF
090218     PERFORM C01075-SCRIVE-OFILEDR
           PERFORM C00530-PREP-OFFLN-REC2
           MOVE RADMEF-REC2-FRAME        TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
           ADD 1                         TO WS-O-TOT-REC2
                                            WS-O-TOT-FF
                                            WS-COUNT-TITOLARI.
      *-----------------------------------
      *
      *-----------------------------------
       C00140-GEST-ONLINE.
           PERFORM C01160-CHIAMA-COBRTG01
           IF  (RADRADO-TIPSERV = 'DR')
           AND (RADRADO-CATRAPP = '2120' OR '2620')
              PERFORM C00150-GEST-ONL-212620
           ELSE
              PERFORM C01180-CHIAMA01-ACS108BT
              IF SI-CONTINUA
                 IF L-ACS108-NAT-GIURIDICA = 'COI'
                    PERFORM C00160-GEST-COLLEGATI
                 ELSE
                    PERFORM C00200-GEST-OUT-ONLNNCLL
                    ADD 1                TO WS-O-TOT-NL-NN-COI
                                            WS-COUNT-TITOLARI
           END-IF END-IF END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00150-GEST-ONL-212620.
           PERFORM C00540-PREP-ONL-DR212620-REC1
           MOVE RADMEF-REC1-FRAME        TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
           ADD 1                         TO WS-O-TOT-REC1
090218     IF  RADRADO-TIPSERV  = 'DR'
090218         ADD 1                     TO WS-O-TOT-REC1-DR
090218     END-IF
090218     PERFORM C01075-SCRIVE-OFILEDR
           PERFORM C00550-PREP-ONL-DR212620-REC2
           MOVE RADMEF-REC2-FRAME        TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
           ADD 1                         TO WS-O-TOT-REC2
                                            WS-O-TOT-NL
                                            WS-COUNT-TITOLARI.
      *-----------------------------------
      *
      *-----------------------------------
       C00160-GEST-COLLEGATI.
           PERFORM C00180-GEST-OUT-ONL-CLL-R1
           MOVE L-ACS108-ARG             TO WS-APPO-PRIMO-ACS108
           INITIALIZE WS-COUNT-CLL-RAPP
                      AREA-ACS023
           MOVE '00000'                  TO L-ACS023-BANCA
           MOVE L-ACS108-A-NDG           TO L-ACS023-NDG
           MOVE '2'                      TO L-ACS023-FUNZIONE
           PERFORM C01200-CHIAMA-ACS023BT
           PERFORM C00170-CICLO-COLLEGATI
             UNTIL NO-COLLEGATI
           IF WS-COUNT-CLL-RAPP = ZEROES
              PERFORM C00660-GEST-SCART-COI-SENZA
              MOVE WS-APPO-PRIMO-ACS108  TO L-ACS108-ARG
              PERFORM C00190-GEST-OUT-ONL-CLL-R2
              ADD 1                      TO WS-O-TOT-NL-NN-COI
                                            WS-COUNT-TITOLARI
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00170-CICLO-COLLEGATI.
           PERFORM VARYING WS-IND01 FROM 1 BY 1
             UNTIL WS-IND01 > 10
                OR (L-ACS023-NDG-LTO-X(WS-IND01) = SPACES OR ZEROES)
              IF L-ACS023-TIPO-COL(WS-IND01) = '101'
                 PERFORM C01190-CHIAMA02-ACS108BT
                 IF SI-CONTINUA
                    ADD 1                TO WS-COUNT-CLL-RAPP
                    PERFORM C00190-GEST-OUT-ONL-CLL-R2
                    ADD 1                TO WS-O-TOT-NL-COI
                                            WS-COUNT-TITOLARI
                 END-IF
              END-IF
           END-PERFORM
           IF L-ACS023-FLG-CHIAMATA < 99999
              INITIALIZE L-ACS023-OUTPUT
              PERFORM C01200-CHIAMA-ACS023BT
           ELSE
              SET NO-COLLEGATI           TO TRUE
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00180-GEST-OUT-ONL-CLL-R1.
           PERFORM C00560-PREP-ONL-ALTRO-REC1
           MOVE RADMEF-REC1-FRAME        TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
090218*    ADD 1                         TO WS-O-TOT-REC1.
090218     ADD 1                         TO WS-O-TOT-REC1
090218     IF  RADRADO-TIPSERV  = 'DR'
090218         ADD 1                     TO WS-O-TOT-REC1-DR
090218     END-IF
090218     PERFORM C01075-SCRIVE-OFILEDR.
      *-----------------------------------
      *
      *-----------------------------------
       C00190-GEST-OUT-ONL-CLL-R2.
           PERFORM C00570-PREP-ONL-ALTRO-REC2
           MOVE RADMEF-REC2-FRAME        TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
           ADD 1                         TO WS-O-TOT-REC2.
      *-----------------------------------
      *
      *-----------------------------------
       C00200-GEST-OUT-ONLNNCLL.
           PERFORM C00560-PREP-ONL-ALTRO-REC1
           MOVE RADMEF-REC1-FRAME        TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
           ADD 1                         TO WS-O-TOT-REC1
090218     IF  RADRADO-TIPSERV  = 'DR'
090218         ADD 1                     TO WS-O-TOT-REC1-DR
090218     END-IF
090218     PERFORM C01075-SCRIVE-OFILEDR
           PERFORM C00570-PREP-ONL-ALTRO-REC2
           MOVE RADMEF-REC2-FRAME        TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
           ADD 1                         TO WS-O-TOT-REC2.
      *-----------------------------------
      *
      *-----------------------------------
       C00210-FINE.
110257     PERFORM C01080-SCRIVE-OFILPRE

           IF WS-O-TOT-REC > ZEROES
              PERFORM C00610-PREP-REC9
           END-IF
110257     PERFORM C01090-CHIUDE-IFILPRE
           PERFORM C01090-CHIUDE-IFILRADO
           PERFORM C01100-CHIUDE-IFILPOSI
           PERFORM C01110-CHIUDE-OFILMEFO
090218     PERFORM C01115-CHIUDE-OFILEDR
           PERFORM C01120-CHIUDE-OFILLOGA
110257     PERFORM C01120-CHIUDE-OFILPRE
           PERFORM C01130-ACCEPT-TIMEDATE
           PERFORM C09020-STATISTICHE
           PERFORM C09030-END.
      *-----------------------------------
      *
      *-----------------------------------
       C00510-PREP-REC0.
           MOVE ZEROES                   TO MEF-R0-TP-REC
           MOVE '07601'                  TO MEF-R0-ABI-ANIA
           MOVE '03200'                  TO MEF-R0-CAB
           MOVE 'POSTE ITALIANE'         TO MEF-R0-DENOM-IMPR
           MOVE WS-DATASYS               TO MEF-R0-DTFILE
           COMPUTE DATASYS-AAAA = DATASYS-AAAA - 1 END-COMPUTE
           MOVE DATASYS-AAAA             TO MEF-R0-ANNO-RIF
           MOVE '001'                    TO MEF-R0-PROG-CONS
           MOVE ZEROES                   TO MEF-R0-PROG-RETT
           MOVE SPACES                   TO MEF-R0-FILLER01
           MOVE '*'                      TO MEF-R0-FINE-REC.
      *-----------------------------------
      *
      *-----------------------------------
       C00520-PREP-OFFLN-REC1.
           MOVE '1'                      TO MEF-R1-TP-REC
           MOVE '07601'                  TO MEF-R1-ABI
           MOVE TG01-CAB-SPORT           TO MEF-R1-CAB
           MOVE 'POSTE ITALIANE'         TO MEF-R1-DENOM-IMPR
           MOVE RADRADO-FILIALE          TO MEF-R1-AGENZIA
           MOVE VNN-CODFILI-VNL          TO MEF-R1-ID-RAPPO(1:5)
           MOVE '/'                      TO MEF-R1-ID-RAPPO(6:1)
           MOVE VNN-NUMRAPP-VNL          TO WS-PIC12-9
           MOVE WS-PIC12-X(7:)           TO MEF-R1-ID-RAPPO(7:)
           EVALUATE RADRADO-CATRAPP
             WHEN '2120'
             WHEN '2620'
               MOVE 'LIBRETTO DI DEPOSITO AL PORTATORE'
                                         TO MEF-R1-TP-RAPPO
             WHEN OTHER
               MOVE 'LIBRETTO DI DEPOSITO NOMINATIVO'
                                         TO MEF-R1-TP-RAPPO
           END-EVALUATE
           PERFORM C00600-PREP-IMPO
           MOVE WS-EDI10                 TO MEF-R1-IMPO
           MOVE SPACES                   TO MEF-R1-FILLER01
           MOVE '*'                      TO MEF-R1-FINE-REC
           MOVE WS-KEY-RADRADO           TO RADMEF-KEY-PILO1
           .
      *-----------------------------------
      *
      *-----------------------------------
       C00530-PREP-OFFLN-REC2.
           MOVE '2'                      TO MEF-R2-TP-REC
           MOVE '07601'                  TO MEF-R2-ABI
           MOVE TG01-CAB-SPORT           TO MEF-R2-CAB
           MOVE VNN-CODFILI-VNL          TO MEF-R2-ID-RAPPO(1:5)
           MOVE '/'                      TO MEF-R2-ID-RAPPO(6:1)
           MOVE VNN-NUMRAPP-VNL          TO WS-PIC12-9
           MOVE WS-PIC12-X(7:)           TO MEF-R2-ID-RAPPO(7:)
           MOVE 'N'                      TO MEF-R2-NAT-GIUR
           MOVE 'DENOMINAZIONE'          TO MEF-R2-COGN-DENOM
           MOVE SPACES                   TO MEF-R2-NOME
                                            MEF-R2-CF-PIVA
                                            MEF-R2-DTNASC
                                            MEF-R2-LOC-NASC
                                            MEF-R2-PROV-NASC
                                            MEF-R2-FILLER01
           MOVE '*'                      TO MEF-R2-FINE-REC
           MOVE WS-KEY-RADRADO           TO RADMEF-KEY-PILO2
           .
      *-----------------------------------
      *
      *-----------------------------------
       C00540-PREP-ONL-DR212620-REC1.
           MOVE '1'                      TO MEF-R1-TP-REC
           MOVE '07601'                  TO MEF-R1-ABI
           MOVE TG01-CAB-SPORT           TO MEF-R1-CAB
           MOVE 'POSTE ITALIANE'         TO MEF-R1-DENOM-IMPR
           MOVE RADRADO-FILIALE          TO MEF-R1-AGENZIA
           MOVE RADRADO-RAPPORT          TO WS-PIC12-9
           MOVE WS-PIC12-X               TO MEF-R1-ID-RAPPO
           MOVE 'LIBRETTO DI DEPOSITO AL PORTATORE'
                                         TO MEF-R1-TP-RAPPO
           PERFORM C00600-PREP-IMPO
           MOVE WS-EDI10                 TO MEF-R1-IMPO
           MOVE SPACES                   TO MEF-R1-FILLER01
           MOVE '*'                      TO MEF-R1-FINE-REC
           MOVE WS-KEY-RADRADO           TO RADMEF-KEY-PILO1
           .
      *-----------------------------------
      *
      *-----------------------------------
       C00550-PREP-ONL-DR212620-REC2.
           MOVE '2'                      TO MEF-R2-TP-REC
           MOVE '07601'                  TO MEF-R2-ABI
           MOVE TG01-CAB-SPORT           TO MEF-R2-CAB
           MOVE RADRADO-RAPPORT          TO WS-PIC12-9
           MOVE WS-PIC12-X               TO MEF-R2-ID-RAPPO
           MOVE 'F'                      TO MEF-R2-NAT-GIUR
           MOVE 'PORTATORE'              TO MEF-R2-COGN-DENOM
           MOVE SPACES                   TO MEF-R2-NOME
                                            MEF-R2-CF-PIVA
                                            MEF-R2-DTNASC
                                            MEF-R2-LOC-NASC
                                            MEF-R2-PROV-NASC
                                            MEF-R2-FILLER01
           MOVE '*'                      TO MEF-R2-FINE-REC
           MOVE WS-KEY-RADRADO           TO RADMEF-KEY-PILO2
           .
      *-----------------------------------
      *
      *-----------------------------------
       C00560-PREP-ONL-ALTRO-REC1.
           MOVE '1'                      TO MEF-R1-TP-REC
           MOVE '07601'                  TO MEF-R1-ABI
           MOVE TG01-CAB-SPORT           TO MEF-R1-CAB
           MOVE 'POSTE ITALIANE'         TO MEF-R1-DENOM-IMPR
           MOVE RADRADO-FILIALE          TO MEF-R1-AGENZIA
           MOVE RADRADO-RAPPORT          TO WS-PIC12-9
           MOVE WS-PIC12-X               TO MEF-R1-ID-RAPPO
           EVALUATE RADRADO-TIPSERV
             WHEN 'CC'
               MOVE 'CONTO CORRENTE'     TO MEF-R1-TP-RAPPO
             WHEN 'DR'
               MOVE 'LIBRETTO DI DEPOSITO NOMINATIVO'
                                         TO MEF-R1-TP-RAPPO
             WHEN 'DT'
               MOVE 'DEPOSITO TITOLI'    TO MEF-R1-TP-RAPPO
           END-EVALUATE
           PERFORM C00600-PREP-IMPO
           MOVE WS-EDI10                 TO MEF-R1-IMPO
           MOVE SPACES                   TO MEF-R1-FILLER01
           MOVE '*'                      TO MEF-R1-FINE-REC
           MOVE WS-KEY-RADRADO           TO RADMEF-KEY-PILO1
           .
      *-----------------------------------
      *
      *-----------------------------------
       C00570-PREP-ONL-ALTRO-REC2.
           MOVE '2'                      TO MEF-R2-TP-REC
           MOVE '07601'                  TO MEF-R2-ABI
           MOVE TG01-CAB-SPORT           TO MEF-R2-CAB
           MOVE RADRADO-RAPPORT          TO WS-PIC12-9
           MOVE WS-PIC12-X               TO MEF-R2-ID-RAPPO
           IF L-ACS108-NAT-GIURIDICA = 'PF'
              PERFORM C00580-PREP-ONL-REC2-PF
           ELSE
              PERFORM C00590-PREP-ONL-REC2-PALTRO
           END-IF
           MOVE SPACES                   TO MEF-R2-FILLER01
           MOVE '*'                      TO MEF-R2-FINE-REC
           MOVE WS-KEY-RADRADO           TO RADMEF-KEY-PILO2
           .
      *-----------------------------------
      *
      *-----------------------------------
       C00580-PREP-ONL-REC2-PF.
           MOVE 'F'                           TO MEF-R2-NAT-GIUR
           MOVE L-ACS108-COGNOME              TO MEF-R2-COGN-DENOM
           MOVE L-ACS108-NOME                 TO MEF-R2-NOME
           MOVE L-ACS108-COD-FISCALE          TO WS-APPO-COD-FISC
           PERFORM C01210-CHIAMA-ACS099BT
           MOVE WS-APPO-COD-FISC              TO MEF-R2-CF-PIVA
           MOVE L-ACS108-DATA-NASC-COS-X(7:2) TO MEF-R2-DTNASC(1:2)
           MOVE L-ACS108-DATA-NASC-COS-X(5:2) TO MEF-R2-DTNASC(3:2)
           MOVE L-ACS108-DATA-NASC-COS-X(1:4) TO MEF-R2-DTNASC(5:4)
           IF L-ACS108-NAZ-NASCITA = SPACES
              MOVE L-ACS108-LUOGO-NASCITA     TO MEF-R2-LOC-NASC
              MOVE L-ACS108-PROV-NASCITA      TO MEF-R2-PROV-NASC
FM0513        IF L-ACS108-PROV-NASCITA = 'EE'
FM0513           MOVE 'ESTERO'                TO MEF-R2-PROV-NASC
FM0513        END-IF
           ELSE
              PERFORM C01220-CHIAMA-ACZ023BT
              MOVE ACZ023-DESCR-EST           TO MEF-R2-LOC-NASC
              MOVE 'ESTERO'                   TO MEF-R2-PROV-NASC
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C00590-PREP-ONL-REC2-PALTRO.
           MOVE 'G'                      TO MEF-R2-NAT-GIUR
           STRING L-ACS108-RAGSOC-1
                  L-ACS108-RAGSOC-2
                  L-ACS108-RAGSOC-3
             DELIMITED BY SIZE         INTO MEF-R2-COGN-DENOM
           END-STRING
           IF L-ACS108-COD-FISCALE > SPACES
              MOVE L-ACS108-COD-FISCALE  TO WS-APPO-COD-FISC
              PERFORM C01210-CHIAMA-ACS099BT
              MOVE WS-APPO-COD-FISC(6:11) TO MEF-R2-CF-PIVA
           ELSE
              MOVE L-ACS108-PARTITA-IVA  TO MEF-R2-CF-PIVA
           END-IF
           MOVE SPACES                   TO MEF-R2-NOME
           MOVE ZEROES                   TO MEF-R2-DTNASC
           MOVE SPACES                   TO MEF-R2-LOC-NASC
                                            MEF-R2-PROV-NASC.
      *-----------------------------------
      *
      *-----------------------------------
       C00600-PREP-IMPO.
           ADD POSI-IMPORTO              TO WS-SUM-IMPORTO
           MOVE POSI-IMPORTO             TO WS-PIC07V02-9
           MOVE WS-PIC07V-X1             TO WS-EDI10-07
           MOVE ','                      TO WS-EDI10-V
           MOVE WS-PICV02-X1             TO WS-EDI10-02.
      *-----------------------------------
      *
      *-----------------------------------
       C00610-PREP-REC9.
           MOVE '9'                      TO MEF-R9-TP-REC
           COMPUTE WS-COUNT-RAPP-ELAB = WS-I-TOT-IFILRADO      -
                                        WS-I-SCART-TIPSERV     -
                                        WS-I-SCART-DTVAL       -
                                        WS-I-SCART-NO-POSIZ    -
                                        WS-I-SCART-NO-SALDO    -
                                        WS-I-SCART-NO-VN       -
                                        WS-I-SCART-NO-AN
           END-COMPUTE
           MOVE WS-COUNT-RAPP-ELAB       TO WS-PIC06-9
           MOVE WS-PIC06-X               TO MEF-R9-TOT-RAPPORT
           MOVE WS-COUNT-TITOLARI        TO WS-PIC06-9
           MOVE WS-PIC06-X               TO MEF-R9-TOT-TITOLARI
           MOVE WS-SUM-IMPORTO           TO WS-PIC12V02-9
           MOVE WS-PIC12V-X2             TO WS-EDI15-12
           MOVE ','                      TO WS-EDI15-V
           MOVE WS-PICV02-X2             TO WS-EDI15-02
           MOVE WS-EDI15                 TO MEF-R9-TOT-IMPORTI
           MOVE SPACES                   TO MEF-R9-FILLER01
           MOVE '*'                      TO MEF-R9-FINE-REC
           MOVE RADMEF-REC9              TO REC-OFILMEFO
           PERFORM C01070-SCRIVE-OFILMEFO
           ADD 1                         TO WS-O-TOT-REC9.
      *-----------------------------------
      *
      *-----------------------------------
       C00620-GEST-SCART-DTVAL.
           PERFORM C00670-PREP-LOG-GEN
           MOVE 'RAPP. CON DATA FINE VALIDITA'' FUORI RANGE '
                                         TO LOGA-DESCANOM
           MOVE RADRADO-DATFINE          TO WS-PIC08-9
           MOVE WS-PIC08-X               TO LOGA-DESCANOM(43:8)
           PERFORM C01080-SCRIVE-OFILLOGA
           ADD 1                         TO WS-I-SCART-DTVAL.
      *-----------------------------------
      *
      *-----------------------------------
       C00630-GEST-SCART-TIPSERV.
           PERFORM C00670-PREP-LOG-GEN
           MOVE 'CODICE SERVIZIO DEL RAPP. <> ''CC/DR/DT'''
                                         TO LOGA-DESCANOM
           PERFORM C01080-SCRIVE-OFILLOGA
           ADD 1                         TO WS-I-SCART-TIPSERV.
      *-----------------------------------
      *
      *-----------------------------------
       C00640-GEST-SCART-NOPOSIZ.
           PERFORM C00670-PREP-LOG-GEN
           MOVE 'RAPPORTO ''DR'' DI IFILRADO ASSENTE SU IFILPOSI'
                                         TO LOGA-DESCANOM
           PERFORM C01080-SCRIVE-OFILLOGA
           ADD 1                         TO WS-I-SCART-NO-POSIZ.
      *-----------------------------------
      *
      *-----------------------------------
       C00650-GEST-SCART-SALDO-NNVAL.
           MOVE POSI-IMPORTO             TO WS-PIC07V02-9
           IF POSI-IMPORTO < ZEROES
              MOVE '-'                   TO WS-SEGNO
           ELSE
              MOVE '+'                   TO WS-SEGNO
           END-IF
           PERFORM C00670-PREP-LOG-GEN
           STRING 'RAPPORTO CON SALDO NON VALIDO: '
                   WS-SEGNO
                   WS-PIC07V-X1
                   ','
                   WS-PICV02-X1
             DELIMITED BY SIZE         INTO LOGA-DESCANOM
           END-STRING
           PERFORM C01080-SCRIVE-OFILLOGA
           ADD 1                         TO WS-I-SCART-NO-SALDO.
      *-----------------------------------
      *
      *-----------------------------------
       C00660-GEST-SCART-COI-SENZA.
           PERFORM C00670-PREP-LOG-GEN
           MOVE 'RAPPORTO ''COI'' MA SENZA COLLEGATI'
                                         TO LOGA-DESCANOM
           PERFORM C01080-SCRIVE-OFILLOGA
           ADD 1                         TO WS-O-TOT-NL-COI-SENZA.
      *-----------------------------------
      *
      *-----------------------------------
       C00670-PREP-LOG-GEN.
           PERFORM C01130-ACCEPT-TIMEDATE
           INITIALIZE RADSLOGA-REC
           MOVE DIS-GG                   TO LOGA-DATAELAB(7:2)
           MOVE DIS-MM                   TO LOGA-DATAELAB(5:2)
           MOVE DIS-AAAA                 TO LOGA-DATAELAB(1:4)
           MOVE WK-FASE                  TO LOGA-FASE
           MOVE WK-RADBT006              TO LOGA-PROGRAMMA
           MOVE WS-KEY-RADRADO           TO LOGA-KEY.
110257*-----------------------------------
110257*
110257*-----------------------------------
110257 C01010-APRE-IFILPRE.
110257     OPEN INPUT IFILPRE
110257     IF WS-FS-IFILPRE  = '00'
110257        CONTINUE
110257     ELSE
110257        MOVE '0001'                TO ERR-PUNTO
110257        MOVE 'OPEN IFILPRE '       TO ERR-DESCRIZIONE
110257        MOVE WS-FS-IFILPRE         TO ERR-CODICE-X
110257        PERFORM C09000-ERRORE
110257        PERFORM C09030-END
110257     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01010-APRE-IFILRADO.
           OPEN INPUT IFILRADO
           IF WS-FS-IFILRADO = '00'
              CONTINUE
           ELSE
              MOVE '0001'                TO ERR-PUNTO
              MOVE 'OPEN IFILRADO'       TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILRADO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01020-APRE-IFILPOSI.
           OPEN INPUT IFILPOSI
           IF WS-FS-IFILPOSI = '00'
              CONTINUE
           ELSE
              MOVE '0003'                TO ERR-PUNTO
              MOVE 'OPEN IFILPOSI'       TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILPOSI        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01030-APRE-OFILMEFO.
           OPEN OUTPUT OFILMEFO
           IF WS-FS-OFILMEFO = '00'
              CONTINUE
           ELSE
              MOVE '0005'                TO ERR-PUNTO
              MOVE 'OPEN OFILMEFO'       TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILMEFO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
090218*-----------------------------------
      *
      *-----------------------------------
       C01035-APRE-OFILEDR.
           OPEN OUTPUT OFILEDR
           IF WS-FS-OFILEDR = '00'
              CONTINUE
           ELSE
              MOVE '0105'                TO ERR-PUNTO
              MOVE 'OPEN OFILEDR '       TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILEDR         TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
090218     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01040-APRE-OFILLOGA.
           OPEN OUTPUT OFILLOGA
           IF WS-FS-OFILLOGA = '00'
              CONTINUE
           ELSE
              MOVE '0007'                TO ERR-PUNTO
              MOVE 'OPEN OFILLOGA'       TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILLOGA        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
110257*-----------------------------------
110257*
110257*-----------------------------------
110257 C01040-APRE-OFILPRE.
110257     OPEN OUTPUT OFILPRE
110257     IF WS-FS-OFILPRE  = '00'
110257        CONTINUE
110257     ELSE
110257        MOVE '0007'                TO ERR-PUNTO
110257        MOVE 'OPEN OFILPRE '       TO ERR-DESCRIZIONE
110257        MOVE WS-FS-OFILPRE         TO ERR-CODICE-X
110257        PERFORM C09000-ERRORE
110257        PERFORM C09030-END
110257     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
110257 C01050-LEGGE-IFILPRE.
110257     READ IFILPRE  END-READ
110257     EVALUATE WS-FS-IFILPRE
110257        WHEN '00'
110257          INITIALIZE                    RADCDBRI-REC
110257          MOVE REC-IFILPRE           TO BRIC-RIGA-TAB
110257          MOVE BRIC-DATA-RICH        TO WK-DATA-RICH
110257          MOVE WK-DATA-RICH(7:2)     TO DATASYS-GG
110257          MOVE WK-DATA-RICH(5:2)     TO DATASYS-MM
110257          MOVE WK-DATA-RICH(1:4)     TO DATASYS-AAAA
110257          MOVE BRIC-PB04-DATA-FINE   TO WK-DATA-FINE
110257        WHEN '10'
110257          DISPLAY 'FLUSSO IFILPRE RICHIESTE VUOTO'
110257        WHEN OTHER
110257          MOVE '0010'              TO ERR-PUNTO
110257          MOVE 'READ IFILPRE '     TO ERR-DESCRIZIONE
110257          MOVE WS-FS-IFILPRE       TO ERR-CODICE-X
110257          PERFORM C09000-ERRORE
110257          PERFORM C09030-END
110257     END-EVALUATE.
110257
110257     DISPLAY '-----------------------------------'.
110257     DISPLAY 'DATA LIMITE FINE VALIDITA: ' WK-DATA-FINE .
110257     DISPLAY '-----------------------------------'.
110257     DISPLAY '                                   '.

      *-----------------------------------
      *
      *-----------------------------------
       C01050-LEGGE-IFILRADO.
           READ IFILRADO END-READ
           EVALUATE WS-FS-IFILRADO
              WHEN '00'
                ADD 1                    TO WS-I-TOT-IFILRADO
                MOVE REC-IFILRADO        TO RADRADO-RECF
                MOVE RADRADO-TIPSERV     TO WS-KEY-RADRADO(1:2)
                MOVE RADRADO-RAPPORT     TO WS-PIC12-9
                MOVE WS-PIC12-X          TO WS-KEY-RADRADO(3:12)
              WHEN '10'
                IF WS-I-TOT-IFILRADO = ZEROES
                   PERFORM C01053-DISPLAY-MSG
                END-IF
              WHEN OTHER
                MOVE '0010'              TO ERR-PUNTO
                MOVE 'READ IFILRADO'     TO ERR-DESCRIZIONE
                MOVE WS-FS-IFILRADO      TO ERR-CODICE-X
                PERFORM C09000-ERRORE
                PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C01053-DISPLAY-MSG.
           DISPLAY
           '*====----------------------------------------------====*'
           DISPLAY
           '*====             A T T E N Z I O N E              ====*'
           DISPLAY
           '*====          FILE INPUT IFILRADO VUOTO           ====*'.
      *-----------------------------------
      *
      *-----------------------------------
       C01060-LEGGE-IFILPOSI.
           READ IFILPOSI END-READ
           EVALUATE WS-FS-IFILPOSI
              WHEN '00'
                ADD 1                    TO WS-I-TOT-IFILPOSI
                MOVE REC-IFILPOSI        TO AREA-IFILPOSI
                MOVE POSI-TIPSERV(1:2)   TO WS-KEY-RADPOSI(1:2)
                MOVE POSI-RAPPORT        TO WS-PIC12-9
                MOVE WS-PIC12-X          TO WS-KEY-RADPOSI(3:12)
              WHEN '10'
                IF WS-I-TOT-IFILPOSI = ZEROES
                   PERFORM C01063-DISPLAY-MSG
                END-IF
                MOVE HIGH-VALUES         TO WS-KEY-RADPOSI
              WHEN OTHER
                MOVE '0012'              TO ERR-PUNTO
                MOVE 'READ IFILPOSI'     TO ERR-DESCRIZIONE
                MOVE WS-FS-IFILPOSI      TO ERR-CODICE-X
                PERFORM C09000-ERRORE
                PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C01063-DISPLAY-MSG.
           DISPLAY
           '*====----------------------------------------------====*'
           DISPLAY
           '*====             A T T E N Z I O N E              ====*'
           DISPLAY
           '*====          FILE INPUT IFILPOSI VUOTO           ====*'.
      *-----------------------------------
      *
      *-----------------------------------
       C01070-SCRIVE-OFILMEFO.
           IF WS-O-TOT-REC = ZEROES
              PERFORM C01072-SCRIVE-OFILMEFO-REC0
           END-IF
           WRITE REC-OFILMEFO END-WRITE
           IF WS-FS-OFILMEFO = '00'
              ADD 1                      TO WS-O-TOT-REC
           ELSE
              MOVE '0020'                TO ERR-PUNTO
              MOVE 'WRITE OFILMEFO'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILMEFO        TO ERR-CODICE-X
              MOVE REC-OFILMEFO          TO ERR-DATI
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01072-SCRIVE-OFILMEFO-REC0.
           MOVE REC-OFILMEFO             TO WS-APPO-OFILMEFO
           MOVE RADMEF-REC0              TO REC-OFILMEFO
           WRITE REC-OFILMEFO END-WRITE
           IF WS-FS-OFILMEFO = '00'
              ADD 1                      TO WS-O-TOT-REC
                                            WS-O-TOT-REC0
              MOVE WS-APPO-OFILMEFO      TO REC-OFILMEFO
           ELSE
              MOVE '0022'                TO ERR-PUNTO
              MOVE 'WRITE OFILMEFO'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILMEFO        TO ERR-CODICE-X
              MOVE REC-OFILMEFO          TO ERR-DATI
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
090218*-----------------------------------
      *
      *-----------------------------------
       C01075-SCRIVE-OFILEDR.
           IF RADRADO-TIPSERV = 'DR'
              MOVE RADRADO-FILIALE        TO OFILEDR-FILIALE
              MOVE RADRADO-RAPPORT        TO OFILEDR-RAPPORT
              MOVE RADRADO-CATRAPP        TO OFILEDR-CATRAPP
              MOVE OFILEDR-RECF           TO REC-OFILEDR
              WRITE REC-OFILEDR END-WRITE
              IF WS-FS-OFILEDR = '00'
                 ADD 1                      TO WS-O-TOT-REC-DR
              ELSE
                 MOVE '0120'                TO ERR-PUNTO
                 MOVE 'WRITE OFILEDR '      TO ERR-DESCRIZIONE
                 MOVE WS-FS-OFILEDR         TO ERR-CODICE-X
                 MOVE REC-OFILEDR           TO ERR-DATI
                 PERFORM C09000-ERRORE
                 PERFORM C09030-END
              END-IF
090218     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01080-SCRIVE-OFILLOGA.
           MOVE RADSLOGA-REC             TO REC-OFILLOGA.
           WRITE REC-OFILLOGA END-WRITE
           IF WS-FS-OFILLOGA = '00'
              ADD 1                      TO WS-O-TOT-FILLOGA
           ELSE
              MOVE '0024'                TO ERR-PUNTO
              MOVE 'WRITE OFILLOGA'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILLOGA        TO ERR-CODICE-X
              MOVE REC-OFILLOGA          TO ERR-DATI
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
110257*-----------------------------------
110257*
110257*-----------------------------------
110257 C01080-SCRIVE-OFILPRE.
110257     WRITE REC-OFILPRE                FROM BRIC-RIGA-TAB
110257     IF WS-FS-OFILPRE  = '00'
110257        CONTINUE
110257     ELSE
110257        MOVE '0024'                TO ERR-PUNTO
110257        MOVE 'WRITE OFILPRE '      TO ERR-DESCRIZIONE
110257        MOVE WS-FS-OFILPRE         TO ERR-CODICE-X
110257        MOVE REC-OFILPRE           TO ERR-DATI
110257        PERFORM C09000-ERRORE
110257        PERFORM C09030-END
110257     END-IF.

110257*-----------------------------------
110257*
110257*-----------------------------------
110257 C01090-CHIUDE-IFILPRE.
110257     CLOSE IFILPRE
110257     IF WS-FS-IFILPRE  = '00'
110257        CONTINUE
110257     ELSE
110257        MOVE '0030'                TO ERR-PUNTO
110257        MOVE 'CLOSE IFILPRE '      TO ERR-DESCRIZIONE
110257        MOVE WS-FS-IFILPRE         TO ERR-CODICE-X
110257        PERFORM C09000-ERRORE
110257        PERFORM C09030-END
110257     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01090-CHIUDE-IFILRADO.
           CLOSE IFILRADO
           IF WS-FS-IFILRADO = '00'
              CONTINUE
           ELSE
              MOVE '0030'                TO ERR-PUNTO
              MOVE 'CLOSE IFILRADO'      TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILRADO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01100-CHIUDE-IFILPOSI.
           CLOSE IFILPOSI
           IF WS-FS-IFILPOSI = '00'
              CONTINUE
           ELSE
              MOVE '0032'                TO ERR-PUNTO
              MOVE 'CLOSE IFILPOSI'      TO ERR-DESCRIZIONE
              MOVE WS-FS-IFILPOSI        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01110-CHIUDE-OFILMEFO.
           CLOSE OFILMEFO
           IF WS-FS-OFILMEFO = '00'
              CONTINUE
           ELSE
              MOVE '0034'                TO ERR-PUNTO
              MOVE 'CLOSE OFILMEFO'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILMEFO        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
090218*-----------------------------------
      *
      *-----------------------------------
       C01115-CHIUDE-OFILEDR.
           CLOSE OFILEDR
           IF WS-FS-OFILEDR = '00'
              CONTINUE
           ELSE
              MOVE '0134'                TO ERR-PUNTO
              MOVE 'CLOSE OFILEDR '      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILEDR         TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
090218     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01120-CHIUDE-OFILLOGA.
           CLOSE OFILLOGA
           IF WS-FS-OFILLOGA = '00'
              CONTINUE
           ELSE
              MOVE '0036'                TO ERR-PUNTO
              MOVE 'CLOSE OFILLOGA'      TO ERR-DESCRIZIONE
              MOVE WS-FS-OFILLOGA        TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
110257*-----------------------------------
110257*
110257*-----------------------------------
110257 C01120-CHIUDE-OFILPRE.
110257     CLOSE OFILPRE
110257     IF WS-FS-OFILPRE  = '00'
110257        CONTINUE
110257     ELSE
110257        MOVE '0036'                TO ERR-PUNTO
110257        MOVE 'CLOSE OFILPRE '      TO ERR-DESCRIZIONE
110257        MOVE WS-FS-OFILPRE         TO ERR-CODICE-X
110257        PERFORM C09000-ERRORE
110257        PERFORM C09030-END
110257     END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01130-ACCEPT-TIMEDATE.
           ACCEPT WSS-TIME-SIS FROM TIME
           MOVE WSS-ORA                         TO DIS-ORA
                                                   ORASYS-HH
           MOVE WSS-MIN                         TO DIS-MIN
                                                   ORASYS-MM
           MOVE WSS-SEC                         TO DIS-SEC
                                                   ORASYS-SS
           MOVE ':'                             TO FILL-TM1
           MOVE ':'                             TO FILL-TM2
           ACCEPT WSS-DATE-SIS FROM DATE YYYYMMDD
           MOVE WSS-AAAA                        TO DIS-AAAA
           MOVE WSS-MM                          TO DIS-MM
           MOVE WSS-GG                          TO DIS-GG
           MOVE '-'                             TO FILL-DT1
           MOVE '-'                             TO FILL-DT2.
      *-----------------------------------
      *
      *-----------------------------------
       C01140-ACCEPT-SYSIN.
110257*    ACCEPT WS-SYSIN-SKED FROM SYSIN
110257*    MOVE WS-SYSIN-DATOPC-R(7:2)   TO DATASYS-GG
110257*    MOVE WS-SYSIN-DATOPC-R(5:2)   TO DATASYS-MM
110257*    MOVE WS-SYSIN-DATOPC-R(1:4)   TO DATASYS-AAAA.

      *-----------------------------------
      *
      *-----------------------------------
       C01150-CHIAMA-SRVB0010.
           INITIALIZE DR09
           MOVE '2'                      TO DR09-TIPORIC
           MOVE RADRADO-RAPPORT          TO DR09-RAPPORT
           CALL WK-SRVB0010 USING DR09 END-CALL
           IF DR09-RETCODE = '2'
              MOVE '0040'                TO ERR-PUNTO
              MOVE DR09-DESERR           TO ERR-DESCRIZIONE
              MOVE DR09-CODERR           TO ERR-CODICE-X
              PERFORM C09000-ERRORE
              PERFORM C09030-END
           END-IF.
      *-----------------------------------
      *
      *-----------------------------------
       C01160-CHIAMA-COBRTG01.
           INITIALIZE TG01-AREA
           MOVE ZEROES                   TO TG01-CDBAN0
           MOVE RADRADO-FILIALE          TO TG01-CDDIP0
           MOVE ZEROES                   TO TG01-CDDPU0
           MOVE 'SIC'                    TO TG01-MODORG
           CALL WK-COBRTG01 USING TG01-AREA END-CALL
           EVALUATE TG01-ESITO
             WHEN 'OK'
               IF TG01-CAB-SPORT = SPACES
                  PERFORM C01163-GEST-CAB-ASSENTE
               END-IF
             WHEN OTHER
               IF TG01-SQLCODE = +100
                  PERFORM C01163-GEST-CAB-ASSENTE
               ELSE
                  MOVE '0042'            TO ERR-PUNTO
                  MOVE 'ERRORE ROUTINE COBRTG01'
                                         TO ERR-DESCRIZIONE
                  MOVE TG01-ESITO        TO ERR-CODICE-X
                  MOVE TG01-SQLCODE      TO ERR-CODICE-Z
                  PERFORM C09000-ERRORE
                  PERFORM C09030-END
              END-IF
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C01163-GEST-CAB-ASSENTE.
           PERFORM C00670-PREP-LOG-GEN
           STRING 'CAB ASSENTE PER L''AGENZIA: '
                   RADRADO-FILIALE
             DELIMITED BY SIZE         INTO LOGA-DESCANOM
           END-STRING
           PERFORM C01080-SCRIVE-OFILLOGA
           ADD 1                         TO WS-I-CAB-ASSENTE
           MOVE ZEROES                   TO TG01-CAB-SPORT.
      *-----------------------------------
      *
      *-----------------------------------
       C01170-CHIAMA-SRVYDNVN.
           INITIALIZE AREA-SRVYDNVN
                      SRVDVNN-REC
           MOVE '0001'                   TO ARCHIVIO-TRAC
           MOVE 'RED'                    TO ARCHIVIO-FUNZ
           MOVE RADRADO-RAPPORT          TO VNN-NUMRAPP-NDR
           MOVE SRVDVNN-REC              TO ARCHIVIO-REC
           CALL WK-SRVYDNVN USING AREA-SRVYDNVN END-CALL
           EVALUATE ARCHIVIO-SW
             WHEN 'SI'
               SET SI-CONTINUA           TO TRUE
               MOVE ARCHIVIO-REC         TO SRVDVNN-REC
             WHEN 'NF'
               SET NO-CONTINUA           TO TRUE
               PERFORM C00670-PREP-LOG-GEN
               MOVE 'RAPPORTO INESISTENTE IN ANAGRAFE VNL'
                                         TO LOGA-DESCANOM
               PERFORM C01080-SCRIVE-OFILLOGA
               ADD 1                     TO WS-I-SCART-NO-VN
             WHEN OTHER
               MOVE '0044'               TO ERR-PUNTO
               MOVE DR09-DESERR          TO ERR-DESCRIZIONE
               MOVE DR09-CODERR          TO ERR-CODICE-X
               PERFORM C09000-ERRORE
               PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      * CALL BY RAPPORTO
      *-----------------------------------
       C01180-CHIAMA01-ACS108BT.
           INITIALIZE AREA-ACS108
           MOVE SPACE                    TO L-ACS108-I-TIPO-RICH
           MOVE RADRADO-TIPSERV          TO L-ACS108-I-SERVIZIO
           MOVE RADRADO-FILIALE          TO L-ACS108-I-FILIALE
           MOVE RADRADO-RAPPORT          TO L-ACS108-I-NUMERO
           MOVE RADRADO-CATRAPP          TO L-ACS108-I-CATEGORIA
           CALL WK-ACS108BT USING AREA-ACS108 END-CALL
           EVALUATE L-ACS108-RET-CODE
             WHEN ZEROES
               SET SI-CONTINUA           TO TRUE
             WHEN 5
             WHEN 2
               SET NO-CONTINUA           TO TRUE
               PERFORM C00670-PREP-LOG-GEN
               MOVE 'RAPPORTO INESISTENTE IN ANAGRAFE ANA'
                                         TO LOGA-DESCANOM
               PERFORM C01080-SCRIVE-OFILLOGA
               ADD 1                     TO WS-I-SCART-NO-AN
             WHEN OTHER
               MOVE '0046'               TO ERR-PUNTO
               MOVE 'ERRORE CALL ACS108BT' TO ERR-DESCRIZIONE
               MOVE L-ACS108-RET-CODE    TO ERR-CODICE-X
               PERFORM C09000-ERRORE
               PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      * CALL BY NDG
      *-----------------------------------
       C01190-CHIAMA02-ACS108BT.
           INITIALIZE AREA-ACS108
           MOVE 'A'                      TO L-ACS108-I-TIPO-RICH
           MOVE L-ACS023-NDG-LTO-X(WS-IND01)
                                         TO L-ACS108-I-NDG-X
           CALL WK-ACS108BT USING AREA-ACS108 END-CALL
           EVALUATE L-ACS108-RET-CODE
             WHEN ZEROES
               SET SI-CONTINUA           TO TRUE
             WHEN 5
             WHEN 2
               SET NO-CONTINUA           TO TRUE
               PERFORM C00670-PREP-LOG-GEN
               MOVE 'NDG RAPPORTO LEGATO ASSENTE IN ANAG. LEGATI'
                                         TO LOGA-DESCANOM
               MOVE L-ACS023-NDG-LTO-X(WS-IND01) TO LOGA-KEY
               PERFORM C01080-SCRIVE-OFILLOGA
               ADD 1                     TO WS-I-SCART-NO-AN
             WHEN OTHER
               MOVE '0048'               TO ERR-PUNTO
               MOVE 'ERRORE CALL ACS108BT'       TO ERR-DESCRIZIONE
               MOVE L-ACS108-RET-CODE    TO ERR-CODICE-X
               PERFORM C09000-ERRORE
               PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C01200-CHIAMA-ACS023BT.
           CALL WK-ACS023BT USING AREA-ACS023 END-CALL
           EVALUATE L-ACS023-RET-CODE
             WHEN '00'
               SET SI-COLLEGATI          TO TRUE
             WHEN '07'
             WHEN '09'
               SET NO-COLLEGATI          TO TRUE
             WHEN OTHER
               MOVE '0050'               TO ERR-PUNTO
               MOVE 'ERRORE CALL ACS023BT' TO ERR-DESCRIZIONE
               MOVE L-ACS023-RET-CODE    TO ERR-CODICE-X
               PERFORM C09000-ERRORE
               PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C01210-CHIAMA-ACS099BT.
           INITIALIZE ACS099A
           MOVE L-ACS108-COGNOME         TO ACS099-COGNOME
           MOVE L-ACS108-NOME            TO ACS099-NOME
           MOVE L-ACS108-DATA-NASC-COS-X(7:2)
                                         TO ACS099-DATADINASCITA(1:2)
           MOVE L-ACS108-DATA-NASC-COS-X(5:2)
                                         TO ACS099-DATADINASCITA(3:2)
           MOVE L-ACS108-DATA-NASC-COS-X(1:4)
                                         TO ACS099-DATADINASCITA(5:4)
           MOVE L-ACS108-SESSO           TO ACS099-SESSO
           IF L-ACS108-PROV-NASCITA = SPACES
             MOVE SPACES                 TO ACS099-LOC-NASCITA
                                            ACS099-PROV-NASCITA
             MOVE L-ACS108-LUOGO-NASCITA TO ACS099-NAZ-NASCITA
             MOVE SPACES                 TO ACS099-COD-NAZ-NASCITA
           ELSE
             MOVE L-ACS108-LUOGO-NASCITA TO ACS099-LOC-NASCITA
             MOVE L-ACS108-PROV-NASCITA  TO ACS099-PROV-NASCITA
             MOVE SPACES                 TO ACS099-NAZ-NASCITA
                                            ACS099-COD-NAZ-NASCITA
           END-IF
           MOVE WS-APPO-COD-FISC         TO ACS099-COD-FISC-I
           CALL WK-ACS099BT USING ACS099A END-CALL
           EVALUATE ACS099-RETCOD
             WHEN ZEROES
               CONTINUE
             WHEN 1
FM0513*        MOVE SPACES               TO WS-APPO-COD-FISC
               PERFORM C00670-PREP-LOG-GEN
               MOVE 'CODICE FISCALE ERRATO PER IL RAPPORTO'
                                         TO LOGA-DESCANOM
               PERFORM C01080-SCRIVE-OFILLOGA
               ADD 1                     TO WS-I-COD-FISC-ERR
             WHEN OTHER
               MOVE '0052'               TO ERR-PUNTO
               MOVE 'ERRORE CALL ACS099BT'    TO ERR-DESCRIZIONE
               MOVE ACS099-RETCOD        TO ERR-CODICE-X
               MOVE ACS099-SQLCODE       TO ERR-CODICE-Z
               PERFORM C09000-ERRORE
               PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C01220-CHIAMA-ACZ023BT.
           INITIALIZE ACZ023A
           MOVE L-ACS108-NAZ-NASCITA     TO ACZ023-COD-NAZ
           CALL WK-ACZ023BT USING ACZ023A END-CALL
           EVALUATE ACZ023-RETCOD
             WHEN ZEROES
               CONTINUE
             WHEN OTHER
               MOVE '0054'               TO ERR-PUNTO
               MOVE 'ERRORE CALL ACZ023BT' TO ERR-DESCRIZIONE
               MOVE ACZ023-RETCOD        TO ERR-CODICE-X
               PERFORM C09000-ERRORE
               PERFORM C09030-END
           END-EVALUATE.
      *-----------------------------------
      *
      *-----------------------------------
       C09000-ERRORE.
           DISPLAY
           '*====----------------------------------------------====*'
           DISPLAY
           '*====                 ERRORE GRAVE                 ====*'
           DISPLAY
           '*====----------------------------------------------====*'
           DISPLAY
           '*====   PROGRAMMA    : ' ERR-PROGRAMMA
           DISPLAY
           '*====   PUNTO        : ' ERR-PUNTO
           DISPLAY
           '*====   DESCRIZIONE  : ' ERR-DESCRIZIONE
           DISPLAY
           '*====   CODICE-X     : ' ERR-CODICE-X
           DISPLAY
           '*====   CODICE-9     : ' ERR-CODICE-Z
           DISPLAY
           '*====   DATI         : ' ERR-DATI
           MOVE 12                              TO RETURN-CODE.
TEST  D    PERFORM C09020-STATISTICHE.
      *-----------------------------------
      *
      *-----------------------------------
       C09020-STATISTICHE.
           MOVE WS-I-TOT-IFILRADO               TO NUM-EDIT(01)
           COMPUTE WS-I-TOT-SCART-ALL = WS-I-SCART-TIPSERV     +
                                        WS-I-SCART-DTVAL       +
                                        WS-I-SCART-NO-POSIZ    +
                                        WS-I-SCART-NO-SALDO    +
                                        WS-I-SCART-NO-VN       +
                                        WS-I-SCART-NO-AN
           END-COMPUTE
           MOVE WS-I-TOT-SCART-ALL              TO NUM-EDIT(02)
           MOVE WS-I-SCART-TIPSERV              TO NUM-EDIT(03)
           MOVE WS-I-SCART-DTVAL                TO NUM-EDIT(04)
           MOVE WS-I-SCART-NO-POSIZ             TO NUM-EDIT(05)
           MOVE WS-I-SCART-NO-SALDO             TO NUM-EDIT(06)
           MOVE WS-I-SCART-NO-VN                TO NUM-EDIT(07)
           MOVE WS-I-SCART-NO-AN                TO NUM-EDIT(08)
           MOVE WS-O-TOT-NL-COI-SENZA           TO NUM-EDIT(09)
           MOVE WS-I-CAB-ASSENTE                TO NUM-EDIT(10)
           MOVE WS-I-COD-FISC-ERR               TO NUM-EDIT(11)
           MOVE WS-I-TOT-IFILPOSI               TO NUM-EDIT(12)
           MOVE WS-O-TOT-REC                    TO NUM-EDIT(13)
           MOVE WS-O-TOT-REC0                   TO NUM-EDIT(14)
           MOVE WS-O-TOT-REC1                   TO NUM-EDIT(15)
           MOVE WS-O-TOT-REC2                   TO NUM-EDIT(16)
           MOVE WS-O-TOT-REC9                   TO NUM-EDIT(17)
           COMPUTE WS-O-TOT-NL = WS-O-TOT-NL-NN-COI +
                                 WS-O-TOT-NL-COI
           END-COMPUTE
           COMPUTE WS-O-TOT-RAPPO = WS-O-TOT-FF +
                                    WS-O-TOT-NL
           END-COMPUTE
           MOVE WS-O-TOT-RAPPO                  TO NUM-EDIT(18)
           MOVE WS-O-TOT-FF                     TO NUM-EDIT(19)
           MOVE WS-O-TOT-NL                     TO NUM-EDIT(20)
           MOVE WS-O-TOT-NL-COI                 TO NUM-EDIT(21)
           MOVE WS-O-TOT-NL-NN-COI              TO NUM-EDIT(22)
           MOVE WS-O-TOT-FILLOGA                TO NUM-EDIT(23)
090818     MOVE WS-O-TOT-REC1-DR                TO NUM-EDIT(24)
090218     MOVE WS-O-TOT-REC-DR                 TO NUM-EDIT(25)
           DISPLAY
           '*====----------------------------------------------====*'
           DISPLAY
           '*====            S T A T I S T I C H E             ====*'
           DISPLAY
           '*====----------------------------------------------====*'
           DISPLAY ' TOT. LETTI RAPPORTI.........: ' NUM-EDIT(01)
           DISPLAY '  DI CUI SCARTATI............: ' NUM-EDIT(02)
           DISPLAY '   PER TIPO SERVIZIO.........: ' NUM-EDIT(03)
           DISPLAY '   PER DATA VALIDITA.........: ' NUM-EDIT(04)
           DISPLAY '   PER ASSENZA POSIZIONI.....: ' NUM-EDIT(05)
           DISPLAY '   PER SALDO POSIZ. NO VALIDO: ' NUM-EDIT(06)
           DISPLAY '   PER ASSENZA VNL...........: ' NUM-EDIT(07)
           DISPLAY '   PER ASSENZA ANAGRAFICA....: ' NUM-EDIT(08)
           DISPLAY '  DI CUI COINTESTATI SENZA...  '
           DISPLAY '   COINTESTATARI.............: ' NUM-EDIT(09)
           DISPLAY '  DI CUI SENZA CAB...........: ' NUM-EDIT(10)
           DISPLAY '  DI CUI CON COD.FISC. ERRATO: ' NUM-EDIT(11)
           DISPLAY ' TOT. LETTI POSIZIONI........: ' NUM-EDIT(12)
           DISPLAY '                               '
           DISPLAY ' TOT. SCRITTI MEF              '
           DISPLAY '  RECORDS....................: ' NUM-EDIT(13)
           DISPLAY '   DI CUI TIPO RECORD 0......: ' NUM-EDIT(14)
           DISPLAY '          TIPO RECORD 1......: ' NUM-EDIT(15)
           DISPLAY '          TIPO RECORD 2......: ' NUM-EDIT(16)
           DISPLAY '          TIPO RECORD 9......: ' NUM-EDIT(17)
           DISPLAY '  RAPPORTI...................: ' NUM-EDIT(18)
           DISPLAY '   DI CUI OFFLINE............: ' NUM-EDIT(19)
           DISPLAY '          ONLINE.............: ' NUM-EDIT(20)
           DISPLAY '           DI CUI COINTESTATI: ' NUM-EDIT(21)
           DISPLAY '                  UNICO INTES: ' NUM-EDIT(22)
           DISPLAY ' TOT. SCRITTI LOG............: ' NUM-EDIT(23)
090218     DISPLAY ' TOT. SCRITTI RECORD 1 PER DR: ' NUM-EDIT(24)
090218     DISPLAY ' TOT. SCRITTI PILOTA.........: ' NUM-EDIT(25).
      *-----------------------------------
      *
      *-----------------------------------
       C09030-END.
           PERFORM C01130-ACCEPT-TIMEDATE
           DISPLAY
           '*====----------------------------------------------====*'
           DISPLAY
           '*====          FINE ELABORAZIONE PROGRAMMA         ====*'
           DISPLAY
           '*====     DATA FINE: ' DIS-DATE
           DISPLAY
           '*====      ORA FINE: ' DIS-TIME
           DISPLAY
           '*======================================================*'
           GOBACK.
      *=====================      END       ****************************
