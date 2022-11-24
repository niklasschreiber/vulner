       IDENTIFICATION DIVISION.
      ******************************************************************
      **                      *- RCBT045 -*                           **
      ******************************************************************
      ** CREATORE   : ENGINEERING                                     **
      ** DATA       : GIUGNO 2005                                     **
      ******************************************************************
      ** SERVIZIO   : -------                                         **
      ** TIPO       : BATCH                                           **
      ** LINK DA    : -------                                         **
      ** TRANSID    : -------                                         **
      ** MAPPA      : -------                                         **
      ** DB2        : SI                                              RE
      ******************************************************************
      ** NUOVE RELEASE                                                **
      ** RL0101 : ACCESSO ALL ROUTINE ANAGRAFICA RCBTR02 UTILIZZANDO  **
      **          IL TIPO RICHIESTA '1' PER CONTROLLARE LA VOCE DACO  **
      **          PER DATA OPERAZIONE UP INVECE CHE PER DATA ELABORAZ **
      ******************************************************************00001400
      ** SCOPO      : IL PROGRAMMA ESEGUE LE NECESSARIE ELABORAZIONI  **
      **              PER L'AQUISIZIONE DEI DATI DEL FLUSSO RCCY021   **
      **              NEL QUALE VENGONO ESEGUITI CONTROLLI PER LA     **
      **              CREAZIONE DI UN FLUSSO DI OUPUT IN USCITA DI    **
      **              UN FLUSSO SCART E DI UNO STORICO.               **
      **                                                              **
      ******************************************************************
      ** FILE INPUT:  FLICOPA  (COPY RCCY021)                         **
      **                                                              **
      ** TAB  INPUT : TGTBTG01                                        **
      ** FILE OUTPUT: FLOCOPA                                         **
      ** FILE OUTPUT: FLOSTORI                                        **
      ** FILE OUTPUT: FLOSCART                                        **
      ** FILE OUTPUT: FLOCOUPD                                        **
      ** FILE OUTPUT: FLORACC                                         **
      ******************************************************************
      ** MODIFICHE:                                                   **
      ** 20.01.2006 ALESSIA PROIETTI BERTOLINI      COMMENTO "200106" **
      **            L'ALIMENTAZIONE DELLE COPA VIENE ACCETTATA BATCH  **
      **            ANCHE QUANDO COPA-ALIM = 'T' (BATCH E ONLINE)     **
      ******************************************************************
       PROGRAM-ID. RCBT045.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT  FLICOPA ASSIGN TO FLICOPA
                   FILE STATUS IS FS-FLICOPA.

           SELECT  FLIPARM ASSIGN TO FLIPARM
                   FILE STATUS IS RCCYPARM-FS-FLIPARM.

           SELECT  FLOCOPA   ASSIGN TO FLOCOPA
                   FILE STATUS IS FS-FLOCOPA.

           SELECT  FLOCOUPD  ASSIGN TO FLOCOUPD
                   FILE STATUS IS FS-FLOCOUPD.

           SELECT  FLOSCART ASSIGN TO FLOSCART
                   FILE STATUS IS FS-FLOSCART.

           SELECT  FLOSTORI ASSIGN TO FLOSTORI
                   FILE STATUS IS FS-FLOSTORI.

           SELECT  FLORACC  ASSIGN TO FLORACC
                   FILE STATUS IS FS-FLORACC.

       DATA DIVISION.
       FILE SECTION.

       FD  FLICOPA
           RECORDING F
           LABEL RECORD IS STANDARD
           DATA RECORD IS REC-FLICOPA.
       01  REC-FLICOPA               PIC X(270).

       FD  FLIPARM
           RECORDING F
           LABEL RECORD IS STANDARD
           DATA RECORD IS REC-FLIPARM.
       01  REC-FLIPARM               PIC X(080).

       FD  FLOCOPA
           RECORDING F
           LABEL RECORD IS STANDARD
           DATA RECORD IS REC-FLOCOPA.
       01  REC-FLOCOPA               PIC X(342).

       FD  FLOCOUPD
           RECORDING F
           LABEL RECORD IS STANDARD
           DATA RECORD IS REC-FLOCOUPD.
       01  REC-FLOCOUPD              PIC X(342).

       FD  FLOSCART
           RECORDING F
           LABEL RECORD IS STANDARD
           DATA RECORD IS REC-FLOSCART.
       01  REC-FLOSCART             PIC X(270).

       FD  FLOSTORI
           RECORDING F
           LABEL RECORD IS STANDARD
           DATA RECORD IS REC-FLOSTORI.
       01  REC-FLOSTORI              PIC X(342).

       FD  FLORACC
           RECORDING F
           LABEL RECORD IS STANDARD
           DATA RECORD IS REC-FLORACC.
       01  REC-FLORACC               PIC X(050).

       WORKING-STORAGE SECTION.

       77  FS-FLICOPA              PIC XX   VALUE SPACES.
       77  FS-FLOSCART             PIC XX   VALUE SPACES.
       77  FS-FLOCOPA              PIC XX   VALUE SPACES.
       77  FS-FLOCOUPD             PIC XX   VALUE SPACES.
       77  FS-FLOSTORI             PIC XX   VALUE SPACES.
       77  FS-FLORACC              PIC XX   VALUE SPACES.
       77  W-SQLCODE                 PIC ++++9  VALUE ZEROES.
       77  W-DATA-INIT               PIC X(10)  VALUE '0001-01-01'.
       77  W-EDIT                    PIC ZZZ.ZZZ.ZZ9 VALUE SPACES.

      * FLAG PER SEGNALAZIONE ERRORE DI ELABORAZIONE.
       01  FL-ERRORE                 PIC X(001)          VALUE 'N'.

KEY   ***************************************************************
KEY   ** CHIAVE X EMAIL                                            **
KEY   ***************************************************************
KEY    01  W-KEY-NOTE.
KEY        03 FILLER               PIC X(01) VALUE SPACES.
KEY        03 W-KEY-NOTE-DATA      PIC X(10) VALUE SPACES.
KEY        03 FILLER               PIC X(01) VALUE SPACES.
KEY        03 W-KEY-NOTE-COD-UFF   PIC X(05) VALUE SPACES.
KEY   *    03 FILLER               PIC X(01) VALUE SPACES.
KEY        03 W-KEY-NOTE-VDACO     PIC X(05) VALUE SPACES.

      * TABELLA DI WORKING PER SCARICO ARCHIVIO DB2.
       01 W-TAB.
          03 W-TAB-ELEM          OCCURS 200.
             05 W-TAB-VDACO-L    PIC X(005).
             05 W-TAB-VDACO-E    PIC X(005).
             05 W-TAB-DTINI-VAL  PIC X(010).
             05 W-TAB-DTFIN-VAL  PIC X(010).
             05 W-TAB-NUMCOPA    PIC 9(015).

      * TABELLA DI WORKING PER SCARICO ARCHIVIO DB2.
       01 W-TCOPA.
          03 W-TAB-ELEM          OCCURS 200.
             05 W-TCOPA-VDACO-L    PIC X(005).
             05 W-TCOPA-VDACO-E    PIC X(005).
             05 W-TCOPA-DTINI-VAL  PIC X(010).
             05 W-TCOPA-DTFIN-VAL  PIC X(010).
             05 W-TCOPA-NUMCOPA    PIC 9(015).

      * INDICE E VALORE MAX DELL'INDICE PER TABELLA WORKING.
       01 W-IND                  PIC S9(004) COMP    VALUE ZEROES.
       01 W-IND-MAX              PIC S9(004) COMP    VALUE 200.
       01 W-IND-TAB2             PIC S9(004) COMP    VALUE ZEROES.
       01 W-IND-TAB2-MAX         PIC S9(004) COMP    VALUE ZEROES.

RL0101* CAMPO DI COMODO PER APPOGGIO DATA OPERAZIONE UP E VOCE DACO
RL0101 01 W-VDACO-OLD            PIC  X(005)         VALUE SPACES.
RL0101 01 W-DTOPER-OLD           PIC  X(010)         VALUE SPACES.

      * CAMPO DI COMODO PER APPOGGIO NUMERO COPA
       01 W-APPO-NUMCOPA         PIC  9(015)         VALUE ZEROES.

      ***************************************************************
      ** COMODI PER TRATTAMENTO DATE                               **
      ***************************************************************
       01 W-COUNT                 PIC S9(8) COMP     VALUE ZEROES.
XSCAD  01 W-INDI                  PIC S9(04) COMP   VALUE 0.
       01 W-DATA                  PIC X(10)         VALUE SPACES.
       01 FILLER REDEFINES W-DATA.
          03 W-DATA-AA            PIC 9(04).
          03 FILLER               PIC X(01).
          03 W-DATA-MM            PIC 9(02).
          03 FILLER               PIC X(01).
          03 W-DATA-GG            PIC 9(02).

       01 W-DATA2                 PIC 9(8)          VALUE ZEROES.
       01 W-DATA-NUM.
           03 W-ANNO-NUM          PIC 9(02)         VALUE ZEROES.
           03 W-MESE-NUM          PIC 9(02)         VALUE ZEROES.
           03 W-GIORNO-NUM        PIC 9(02)         VALUE ZEROES.

       01 W-DATA-ALFA.
           03 FILLER              PIC X(02)         VALUE '20'.
           03 W-ANNO-ALFA         PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(01)         VALUE '-'.
           03 W-MESE-ALFA         PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(01)         VALUE '-'.
           03 W-GIORNO-ALFA       PIC 9(02)         VALUE ZEROES.
        01 DATA-OGGI REDEFINES W-DATA-ALFA PIC X(10).

        01 W-TIME1.
           03 W-TIME1-ORA         PIC 9(02)         VALUE ZEROES.
           03 W-TIME1-MIN         PIC 9(02)         VALUE ZEROES.
           03 W-TIME1-SEC         PIC 9(02)         VALUE ZEROES.
           03 W-TIME1-DEC         PIC 9(02)         VALUE ZEROES.

        01 W-TIME2.
           03 FILLER              PIC X(02)         VALUE '20'.
           03 W-TIME2-ANNO        PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(01)         VALUE '-'.
           03 W-TIME2-MESE        PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(01)         VALUE '-'.
           03 W-TIME2-GIORNO      PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(01)         VALUE '-'.
           03 W-TIME2-ORA         PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(01)         VALUE '.'.
           03 W-TIME2-MIN         PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(01)         VALUE '.'.
           03 W-TIME2-SEC         PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(01)         VALUE '.'.
           03 W-TIME2-DEC         PIC 9(02)         VALUE ZEROES.
           03 FILLER              PIC X(04)         VALUE '0000'.
        01 TIME-OGGI REDEFINES W-TIME2 PIC X(26).

        01  W-NUMERO              PIC 9(02)          VALUE ZEROES.
        01  W-RESTO-A             PIC 9(02)          VALUE ZEROES.
        01  W-TESTA               PIC X(01)          VALUE SPACES.
        01  W-ERRORE              PIC XX             VALUE SPACES.
        88  ERRORE                                   VALUE 'SI'.

      ** **********************************************************  **
      **     STRUTTURE PER POTER GIRARE LE DATE NEL FILE FLORILIO    **
      ** *********************************************************** **
       01 DATA-APPOGGIO.
          02 AAAA-APP        PIC 9(4)            VALUE     0.
          02 MM-APP          PIC 9(2)            VALUE     0.
          02 GG-APP          PIC 9(2)            VALUE     0.

       01 DATA-GIRATA.
          02 AAAA-GIR        PIC X(4)            VALUE SPACE.
          02 FILLER          PIC X               VALUE   '-'.
          02 MM-GIR          PIC X(2)            VALUE SPACE.
          02 FILLER          PIC X               VALUE   '-'.
          02 GG-GIR          PIC X(2)            VALUE SPACE.

      ******************************************************************
      * TABELLA PER CONTROLLO DATE                                     *
      ******************************************************************
       01  TAB-DATE.
           02  FILLER                   PIC X(04)     VALUE '0131'.
           02  FILLER                   PIC X(04)     VALUE '0228'.
           02  FILLER                   PIC X(04)     VALUE '0331'.
           02  FILLER                   PIC X(04)     VALUE '0430'.
           02  FILLER                   PIC X(04)     VALUE '0531'.
           02  FILLER                   PIC X(04)     VALUE '0630'.
           02  FILLER                   PIC X(04)     VALUE '0731'.
           02  FILLER                   PIC X(04)     VALUE '0831'.
           02  FILLER                   PIC X(04)     VALUE '0930'.
           02  FILLER                   PIC X(04)     VALUE '1031'.
           02  FILLER                   PIC X(04)     VALUE '1130'.
           02  FILLER                   PIC X(04)     VALUE '1231'.

       01 FILLER REDEFINES TAB-DATE.
           02  W-ELEM   OCCURS 12 TIMES.
               05 W-MM                  PIC 9(2).
               05 W-GG                  PIC 9(2).

      ** *********************************************************** **
      **    CHIAVE DI ROTTURA PER ACCESSO ROUTINE RCBTR03            **
      ** *********************************************************** **
       01  W-KEY-OLD.
           03 W-KEY-OLD-PART         PIC X(04) VALUE SPACES.
           03 W-KEY-OLD-COD-UFF      PIC X(05) VALUE SPACES.
           03 W-KEY-OLD-DTOPER       PIC X(10) VALUE SPACES.
           03 W-KEY-OLD-VDACO        PIC X(05) VALUE SPACES.

       01  W-KEY-NEW.
           03 W-KEY-NEW-PART         PIC X(04) VALUE SPACES.
           03 W-KEY-NEW-COD-UFF      PIC X(05) VALUE SPACES.
           03 W-KEY-NEW-DTOPER       PIC X(10) VALUE SPACES.
           03 W-KEY-NEW-VDACO        PIC X(05) VALUE SPACES.

      ***************************************************************
      ** APPOGGI PER CHIAVI BILANCIAMENTO                          **
      ***************************************************************
       01  W-KEY-DACO.
           03 W-KEY-DACO-COD-UFF      PIC X(05) VALUE SPACES.
           03 W-KEY-DACO-DTOPER       PIC X(10) VALUE SPACES.
           03 W-KEY-DACO-VDACO        PIC X(05) VALUE SPACES.

       01  W-KEY-PART.
           03 W-KEY-PART-COD-UFF      PIC X(05) VALUE SPACES.
           03 W-KEY-PART-DTOPER       PIC X(10) VALUE SPACES.
           03 W-KEY-PART-VDACO        PIC X(05) VALUE SPACES.

       01  W-KEY-PART-OLD             PIC X(20) VALUE SPACES.
       01  W-IND-1                    PIC 9(03) VALUE 0.

      ***************************************************************
      ** CONTATORI                                                 **
      ***************************************************************
       01  CTR-FLICOPA           PIC S9(09) COMP-3 VALUE ZEROES.
       01  CTR-FLOCOPA           PIC S9(09) COMP-3 VALUE ZEROES.
       01  CTR-FLOCOUPD          PIC S9(09) COMP-3 VALUE ZEROES.
       01  CTR-FLOSCART          PIC S9(09) COMP-3 VALUE ZEROES.
       01  CTR-FLOSTORI          PIC S9(09) COMP-3 VALUE ZEROES.
       01  CTR-FLORACC           PIC S9(09) COMP-3 VALUE ZEROES.
       01  CTR-RCBTR02           PIC S9(09) COMP-3 VALUE ZEROES.
       01  TIPO-ERRORE           PIC X             VALUE SPACE.

      ** *********************************************************** **
      **    CAMPO PER CHIAMATA DINAMICA ROUTINE DI ACCESSO ALLA      **
      **    TABELLA DB2 TGTBTG01                                     **
      ** *********************************************************** **
       01 COBRTG01           PIC X(08)           VALUE 'COBRTG01'.

      ***************************************************************
      ** TRACCIATO RECORD DEL FILE INPUT                           **
      ***************************************************************
       01 REC-COPA.
           COPY RCCY021.

      ***************************************************************
      ** TRACCIATO RECORD DELLA SCHEDA PARAMETRO FLIPARM           **
      ***************************************************************
           COPY RCCYPARM.

      ***************************************************************
      ** AREA PER CHIAMATA RCBTR05 RICERCA DATE IN RCTBRSTA        **
      ***************************************************************
           COPY RCCYR05.

      ***************************************************************
      ** TRACCIATO RECORD DELLA ROUTINE RCBTR02                    **
      ***************************************************************
           COPY RCCYR02.

      ***************************************************************
      ** TRACCIATO OUTPUT FILE FLORACC                             **
      ***************************************************************
       01 FLORACC-REC.
           COPY RCCY050.

      ***************************************************************
      ** TRACCIATO RECORD DELLA ROUTINE COBRTG01                   **
      ***************************************************************
           COPY COCRTG01.

      ***************************************************************
      ** TRACCIATI PER ACCESSI DB2                                 **
      ***************************************************************
            EXEC SQL INCLUDE SQLCA END-EXEC.
            EXEC SQL INCLUDE RCCYANVD END-EXEC.
            EXEC SQL INCLUDE RCCYCOPA END-EXEC.
            EXEC SQL INCLUDE RCCYRSTA END-EXEC.

      *****************************************************************
      **                                                             **
      **                     R C B T 0 3 1                           **
      **                                                             **
      *****************************************************************
       PROCEDURE DIVISION.

       INIZIO-PGM-RCBT045.

           PERFORM OP-INIZIALI         THRU  EX-OP-INIZIALI.

           PERFORM ELABORAZIONE        THRU  EX-ELABORAZIONE.

           PERFORM OP-FINALI           THRU  EX-OP-FINALI.

       FINE-PGM-RCBT045.
           EXIT.

      ******************************************************************
      *************           OPERAZIONI INIZIALI           ************
      ******************************************************************
       OP-INIZIALI.

           DISPLAY '**************************************************'.
           DISPLAY '*--              INIZIO RCBT045                --*'.
           DISPLAY '**************************************************'.

           PERFORM ACCETTA-FLIPARM  THRU EX-ACCETTA-FLIPARM.

           ACCEPT W-DATA-NUM     FROM  DATE.
           MOVE   W-GIORNO-NUM   TO    W-GIORNO-ALFA.
           MOVE   W-MESE-NUM     TO    W-MESE-ALFA.
           MOVE   W-ANNO-NUM     TO    W-ANNO-ALFA.

           ACCEPT W-TIME1        FROM TIME.
           MOVE W-GIORNO-NUM     TO    W-TIME2-GIORNO.
           MOVE W-MESE-NUM       TO    W-TIME2-MESE.
           MOVE W-ANNO-NUM       TO    W-TIME2-ANNO.
           MOVE W-TIME1-ORA      TO    W-TIME2-ORA.
           MOVE W-TIME1-MIN      TO    W-TIME2-MIN.
           MOVE W-TIME1-SEC      TO    W-TIME2-SEC.
           MOVE W-TIME1-DEC      TO    W-TIME2-DEC.

           OPEN INPUT FLICOPA.
           IF FS-FLICOPA NOT = '00'
              DISPLAY 'ERRORE APERTURA FILE FLICOPA  : ' FS-FLICOPA
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT FLOCOPA.
           IF FS-FLOCOPA NOT = '00'
              DISPLAY 'ERRORE APERTURA FILE FLOCOPA  : ' FS-FLOCOPA
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT FLOCOUPD.
           IF FS-FLOCOUPD NOT = '00'
              DISPLAY 'ERRORE APERTURA FILE FLOCOUPD : ' FS-FLOCOUPD
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT FLOSCART.
           IF FS-FLOSCART NOT = '00'
              DISPLAY 'ERRORE APERTURA FILE FLOSCART : ' FS-FLOSCART
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT FLOSTORI.
           IF FS-FLOSTORI NOT = '00'
              DISPLAY 'ERRORE APERTURA FILE FLOSTORI: ' FS-FLOSTORI
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           OPEN OUTPUT FLORACC.
           IF FS-FLORACC NOT = '00'
              DISPLAY 'ERRORE APERTURA FILE FLORACC : ' FS-FLORACC
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           PERFORM  RICERCA-RSTA    THRU    EXIT-RICERCA-RSTA.

       EX-OP-INIZIALI.
           EXIT.

      ******************************************************************
      * RICERCA ULTIMA DATA SVECCHIAMENTO ELABORATA                    *
      ******************************************************************
       RICERCA-RSTA.

           INITIALIZE RCCYR05.
           MOVE '1'       TO R05-TIPO-DATA.
           MOVE '4'       TO R05-TRICH.
           MOVE 'RCBTR05' TO R05-PGM-CALL.
           CALL R05-PGM-CALL USING RCCYR05.
           IF R05-RETURN-CODE = '9' OR
              R05-RETURN-CODE = '1'
              DISPLAY R05-MSGERR ':' R05-SQLCODE
              MOVE 'S' TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF.

           IF R05-RETURN-CODE = '0'
              INITIALIZE DCLRCTBRSTA
              MOVE R05-DCLRCTBRSTA          TO DCLRCTBRSTA
              DISPLAY ' ULTIMA DATA SVECCHIAMENTO: ' RSTA-DTA
              DISPLAY ' '
           END-IF.

       EXIT-RICERCA-RSTA.
           EXIT.

      ******************************************************************
      ***************  ELABORAZIONE  ***********************************
      ******************************************************************
       ELABORAZIONE.

           MOVE ZEROES                TO W-IND-TAB2-MAX.

           PERFORM LEGGI-FLICOPA    THRU EX-LEGGI-FLICOPA.

           PERFORM CARICA-TABELLA   THRU EX-CARICA-TABELLA.

           PERFORM UNTIL FS-FLICOPA = '10'

              PERFORM CONTROLLI THRU EX-CONTROLLI

              IF ERRORE

                PERFORM IMPOSTA-NOTE         THRU EX-IMPOSTA-NOTE
                IF TIPO-ERRORE = '4'
                   PERFORM VALORIZZA-CAMPI   THRU EX-VALORIZZA-CAMPI
                   MOVE SPACES               TO RCCY021-NOTE
                   MOVE ZEROES               TO COPA-NUMCOPA
                   PERFORM SCRITTURA-FLOSTORI
                      THRU EX-SCRITTURA-FLOSTORI
                ELSE
                   PERFORM SCRITTURA-FLOSCART
                      THRU EX-SCRITTURA-FLOSCART
                END-IF
              ELSE
                 INITIALIZE W-KEY-NEW
                 PERFORM VALORIZZA-CAMPI THRU EX-VALORIZZA-CAMPI
                 IF COPA-DTANN = '0001-01-01'
                    PERFORM VALORIZZA-NUMCOPA
                       THRU EX-VALORIZZA-NUMCOPA
                    MOVE W-APPO-NUMCOPA TO COPA-NUMCOPA
                    PERFORM SCRITTURA-FLOCOPA
                       THRU EX-SCRITTURA-FLOCOPA
                 ELSE
                    MOVE ZEROES    TO COPA-NUMCOPA
                    PERFORM SCRITTURA-FLOCOUPD
                       THRU EX-SCRITTURA-FLOCOUPD
                 END-IF

                 MOVE R02-ANVD-PART      TO W-KEY-NEW-PART
                 MOVE RCCY021-COD-UFF    TO W-KEY-NEW-COD-UFF
                 MOVE RCCY021-DTOPER     TO W-KEY-NEW-DTOPER
                 MOVE RCCY021-VDACO      TO W-KEY-NEW-VDACO
                 IF W-KEY-NEW NOT = W-KEY-OLD
                    PERFORM  VALORIZZA-FLORACC
                       THRU  EX-VALORIZZA-FLORACC
                    INITIALIZE W-KEY-OLD
                    MOVE W-KEY-NEW TO W-KEY-OLD
                 END-IF
              END-IF

              PERFORM LEGGI-FLICOPA     THRU EX-LEGGI-FLICOPA

           END-PERFORM.

           PERFORM AGGIORNA-RCTBANVD    THRU EX-AGGIORNA-RCTBANVD.

       EX-ELABORAZIONE.
           EXIT.

      ******************************************************************
       VALORIZZA-FLORACC.

           INITIALIZE FLORACC-REC.

           MOVE  R02-ANVD-PART        TO RCCY050-PART.
           MOVE  R02-ANVD-FG-NOVISSRC TO RCCY050-FG-NOVISSRC.
           MOVE  R02-ANVD-TIPO-VDACO  TO RCCY050-TIPO-VDACO
           MOVE  RCCY021-DTOPER       TO RCCY050-DTCONT.
           MOVE  RCCY021-COD-UFF      TO RCCY050-COD-UFF.
           MOVE  RCCY021-VDACO        TO RCCY050-VDACO.
           MOVE  '0'                  TO RCCY050-FG-SQUAD.
           MOVE  TG01-UO-SUP-ID       TO RCCY050-COD-FIL.
           MOVE  TG01-COD-CUAS        TO RCCY050-COD-CUAS.
           MOVE  RCCYPARM-DTELAB      TO RCCY050-DTRICE.
           MOVE  '0'                  TO RCCY050-ARRIVATA0.
           MOVE  'C'                  TO RCCY050-ORIG.

           PERFORM SCRITTURA-FLORACC     THRU EX-SCRITTURA-FLORACC.

       EX-VALORIZZA-FLORACC.
           EXIT.

      ******************************************************************
       LEGGI-FLICOPA.

           READ FLICOPA INTO REC-COPA.

           IF FS-FLICOPA NOT = '00' AND '10'
              DISPLAY 'ERRORE LETTURA FILE FLICOPA : ' FS-FLICOPA
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           ELSE
              IF FS-FLICOPA = '00'
                 ADD 1 TO CTR-FLICOPA
              END-IF
           END-IF.

       EX-LEGGI-FLICOPA.
           EXIT.

      ******************************************************************
       CONTROLLI.

           MOVE SPACES TO W-ERRORE.

           PERFORM CONTROLLA-FRAZ
              THRU EX-CONTROLLA-FRAZ.

RL0101     IF NOT ERRORE
RL0101        MOVE RCCY021-DTOPER TO W-DATA
RL0101
RL0101        PERFORM CONTROLLA-DATA
RL0101           THRU EX-CONTROLLA-DATA
RL0101     END-IF.

           IF NOT ERRORE
              PERFORM CONTROLLA-VDACO
                 THRU EX-CONTROLLA-VDACO
           END-IF.

           IF NOT ERRORE
              IF RCCY021-IDCORR = SPACES OR LOW-VALUE
                  MOVE 'SI'             TO W-ERRORE
MP+               MOVE '5'              TO TIPO-ERRORE
              END-IF
           END-IF.

           IF NOT ERRORE
              IF RCCY021-IMPORTO NOT NUMERIC
                  MOVE 'SI'             TO W-ERRORE
MP+               MOVE '6'              TO TIPO-ERRORE
              END-IF
           END-IF.

           IF NOT ERRORE
              MOVE RCCY021-DTIM-3270 TO W-DATA
              PERFORM CONTROLLA-DATA
                 THRU EX-CONTROLLA-DATA
           END-IF.

           IF RCCY021-DTANN NOT EQUAL SPACES AND NOT ERRORE
              MOVE RCCY021-DTANN TO W-DATA

              PERFORM CONTROLLA-DATA
                 THRU EX-CONTROLLA-DATA

           END-IF.

RL0101*    IF NOT ERRORE
RL0101*       MOVE RCCY021-DTOPER TO W-DATA
RL0101*
RL0101*       PERFORM CONTROLLA-DATA
RL0101*          THRU EX-CONTROLLA-DATA
RL0101*    END-IF.

           IF NOT ERRORE
              IF RCCY021-DTIM-3270 < RCCY021-DTOPER
                 MOVE '7' TO TIPO-ERRORE
                 MOVE 'SI'                    TO W-ERRORE
              END-IF
           END-IF.

           IF NOT ERRORE
              IF RCCY021-DTOPER < RSTA-DTA
                 MOVE 'SI' TO W-ERRORE
                 MOVE '4' TO TIPO-ERRORE
              END-IF
           END-IF.

       EX-CONTROLLI.
           EXIT.

      ** ******************************************************** **
      **   CALL ALLA ROUTINE CHE ACCEDE ALLA TABELLA TGTBTG01 PER **
      **   REPERIRE LE INFORMAZIONI FILIALE E CODICE CUAS         **
      ** ******************************************************** **
       CONTROLLA-FRAZ.

           MOVE '00000'             TO TG01-CDBAN0.
           MOVE RCCY021-COD-UFF     TO TG01-CDDIP0.
           MOVE '00'                TO TG01-CDDPU0.
           MOVE 'SIC'               TO TG01-MODORG.

           CALL COBRTG01 USING TG01-AREA.

DEBUG *    IF TG01-ESITO = 'OK'
DEBUG *       DISPLAY 'ESITO OK ROUTINE COBRTG01 : ' TG01-ESITO
DEBUG *       DISPLAY 'UO SUP ID   : ' TG01-UO-SUP-ID
DEBUG *       DISPLAY 'COD CUAS    : ' TG01-COD-CUAS
DEBUG *    END-IF.

           IF TG01-ESITO = 'KO'
              DISPLAY 'TG01 ESITO   : ' TG01-ESITO
              DISPLAY 'TG01 SQLCODE : ' TG01-SQLCODE
              DISPLAY 'TG01 MESS    : ' TG01-MESS
              IF TG01-SQLCODE = 100
                 MOVE 'SI'               TO W-ERRORE
                 MOVE '1'                TO TIPO-ERRORE
              ELSE
                 MOVE 'SI'               TO W-ERRORE
                 MOVE 'S'         TO FL-ERRORE
                 PERFORM OP-FINALI THRU EX-OP-FINALI
              END-IF
           END-IF.

           IF TG01-ESITO = 'WA'
              DISPLAY 'TG01 ESITO   : ' TG01-ESITO
              DISPLAY 'TG01 MESS    : ' TG01-MESS
              DISPLAY 'UFFICIO      : ' RCCY021-COD-UFF
              MOVE 'SI'               TO W-ERRORE
              MOVE '1'                TO TIPO-ERRORE
           END-IF.

       EX-CONTROLLA-FRAZ.
           EXIT.

      ******************************************************************
       CONTROLLA-VDACO.

RL0101     IF (RCCY021-VDACO  NOT = W-VDACO-OLD OR
RL0101         RCCY021-DTOPER NOT = W-DTOPER-OLD)

              INITIALIZE        RCCYR02
              MOVE '01'            TO R02-TIPO-FUNZ
              MOVE 'RCBTR02'       TO R02-PGM-CALL
RL0101*       MOVE RCCYPARM-DTELAB TO R02-DATA
RL0101        MOVE RCCY021-DTOPER  TO R02-DATA
              MOVE RCCY021-VDACO   TO R02-VDACO

              CALL  R02-PGM-CALL USING RCCYR02

RL0101        MOVE SPACES          TO W-VDACO-OLD W-DTOPER-OLD
RL0101        MOVE RCCY021-VDACO   TO W-VDACO-OLD
RL0101        MOVE RCCY021-DTOPER  TO W-DTOPER-OLD
RL0101     END-IF.

           IF R02-RETURN-CODE = '1'
              DISPLAY 'RETURN CODE : ' R02-RETURN-CODE
              DISPLAY 'TIPO FUNZ : ' R02-TIPO-FUNZ
              DISPLAY 'PGM CALL  : ' R02-PGM-CALL
              DISPLAY 'DATA      : ' R02-DATA
              DISPLAY 'VOCE DACO : ' R02-VDACO

              MOVE 'SI'          TO W-ERRORE
              MOVE '2'           TO TIPO-ERRORE
           END-IF

           IF R02-RETURN-CODE = '9'
              DISPLAY 'CI PASSO:' R02-RETURN-CODE
              DISPLAY 'DATI:' R02-RCTBANVD
              DISPLAY 'DATI:' R02-ELEM-RCTBANVD(1)
              DISPLAY 'R02-IND ' R02-IND
              DISPLAY 'R02-INDMAX ' R02-IND-MAX
              DISPLAY 'R02-SQL    ' R02-SQLCODE
              DISPLAY 'R02-MSGERR ' R02-MSGERR
              DISPLAY 'ESITO 9 SU CHIAMATA ROUTINE RCBTR02'

              MOVE 'SI'           TO W-ERRORE
              MOVE 'S'            TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           END-IF

      *----VENGONO PRESE SOLE LE COPA CHE ACCETTANO ALIMENTAZIONE BATCH
           IF R02-RETURN-CODE = '0'
200106        IF R02-ANVD-VDACO-E = 'ED05F' OR 'EA13F'
                 CONTINUE
              ELSE
200106           IF R02-ANVD-COPA-ALIM NOT = 'B'  AND  'T'
                    MOVE 'SI'          TO W-ERRORE
                    MOVE '8'           TO TIPO-ERRORE
                 END-IF
              END-IF
           END-IF.
           ADD 1 TO CTR-RCBTR02.

       EX-CONTROLLA-VDACO.
           EXIT.

      ******************************************************************
       CARICA-TABELLA.

      * CARICAMENTO IN UNA TABELLA DI WORKING DI TUTTI I RECORD        *
      * DELL'ARCHIVIO DB2 RCTBANVD, MEMORIZZANDO LE VDACO-L (VOCI DACO *
      * LIRE) E LE VDACO-E (VOCI DACO EURO) RELATIVE ACQUISITE TRAMITE *
      * ACCESSO ALLA ROUTINE ANAGRAFICA RCBTR02                        *

           INITIALIZE        RCCYR02.

           MOVE '02'             TO R02-TIPO-FUNZ
           MOVE 'RCBTR02'        TO R02-PGM-CALL
           MOVE RCCYPARM-DTELAB  TO R02-DATA

           CALL  R02-PGM-CALL USING RCCYR02

           IF R02-RETURN-CODE NOT = '0'
              DISPLAY 'CI PASSO:' R02-RETURN-CODE
              DISPLAY 'DATI:' R02-RCTBANVD
              DISPLAY 'DATI:' R02-ELEM-RCTBANVD(1)
              DISPLAY 'R02-IND ' R02-IND
              DISPLAY 'R02-INDMAX ' R02-IND-MAX
              DISPLAY 'R02-SQL    ' R02-SQLCODE
              DISPLAY 'R02-MSGERR ' R02-MSGERR

              MOVE 500         TO RETURN-CODE
              DISPLAY 'ESITO DIVERSO DA 0 SU CHIAMATA ROUTINE RCBTR02'
              DISPLAY 'R02-RETURN-CODE :' R02-RETURN-CODE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           ELSE
              PERFORM SCRIVI-TABWORK
                 THRU SCRIVI-TABWORK
           END-IF.

       EX-CARICA-TABELLA.
           EXIT.

      *****************************************************************
       SCRIVI-TABWORK.

           MOVE 1 TO W-IND.

           PERFORM VARYING R02-IND FROM 1 BY 1 UNTIL
                                             R02-IND > R02-IND-MAX
               MOVE R02-TAB-ANVD-VDACO-L(R02-IND)
                                            TO W-TAB-VDACO-L(W-IND)
               MOVE R02-TAB-ANVD-VDACO-E(R02-IND)
                                            TO W-TAB-VDACO-E(W-IND)
               MOVE R02-TAB-ANVD-DTINI-VAL(R02-IND)
                                            TO W-TAB-DTINI-VAL(W-IND)
               MOVE R02-TAB-ANVD-DTFIN-VAL(R02-IND)
                                            TO W-TAB-DTFIN-VAL(W-IND)
               MOVE R02-TAB-ANVD-NUMCOPA(R02-IND)
                                            TO W-TAB-NUMCOPA(W-IND)

               ADD 1                        TO W-IND
           END-PERFORM.
      *    MOVE R02-IND-MAX                 TO W-IND-MAX-TAB2.

       EX-SCRIVI-TABWORK.
           EXIT.

      ******************************************************************
       CONTROLLA-DATA.

           IF W-DATA-AA NOT NUMERIC OR
              W-DATA-MM NOT NUMERIC OR
              W-DATA-GG NOT NUMERIC
              MOVE 'SI'            TO W-ERRORE
MP+           MOVE '3'             TO TIPO-ERRORE
           END-IF
           DIVIDE W-DATA-AA BY 4 GIVING W-NUMERO REMAINDER W-RESTO-A
           IF W-RESTO-A = 0
              MOVE '29' TO W-GG(2)
           END-IF.
           IF W-DATA-AA = 0
              MOVE 'SI'            TO W-ERRORE
MP+           MOVE '3'             TO TIPO-ERRORE
           END-IF.
           IF W-DATA-MM > 12 OR
              W-DATA-MM = 0
              MOVE 'SI'            TO W-ERRORE
MP+           MOVE '3'             TO TIPO-ERRORE
           ELSE
              IF W-DATA-GG > W-GG (W-DATA-MM) OR
                 W-DATA-GG = 0
                 MOVE 'SI'         TO W-ERRORE
MP+              MOVE '3'          TO TIPO-ERRORE
              END-IF
           END-IF.

       EX-CONTROLLA-DATA.
           EXIT.

      ******************************************************************
       VALORIZZA-CAMPI.

           INITIALIZE DCLRCTBCOPA.

      *--PARTIZIONE
           MOVE R02-ANVD-PART          TO COPA-PART.

      *--SEGNO
           IF RCCY021-VDACO(2:1) = 'D'
              MOVE 'D' TO COPA-SEGNO
           ELSE
              MOVE 'A' TO COPA-SEGNO
           END-IF.

      *--DATA ELABORAZIONE (VERIFICA PER PRENDERLA DA OPC)
           MOVE RCCYPARM-DTELAB     TO COPA-DTELAB.

      *--CODICE FILIALE
           MOVE TG01-UO-SUP-ID      TO COPA-COD-FIL.

      *--CODICE CUAS
           MOVE TG01-COD-CUAS        TO COPA-COD-CUAS.

      *--BATCH  FISSO
           MOVE 'BATCH'             TO COPA-UTENTE.
           MOVE  SPACE              TO COPA-UTENTE-UFF.

           ACCEPT W-TIME1        FROM TIME.
           MOVE W-GIORNO-NUM     TO    W-TIME2-GIORNO.
           MOVE W-MESE-NUM       TO    W-TIME2-MESE.
           MOVE W-ANNO-NUM       TO    W-TIME2-ANNO.
           MOVE W-TIME1-ORA      TO    W-TIME2-ORA.
           MOVE W-TIME1-MIN      TO    W-TIME2-MIN.
           MOVE W-TIME1-SEC      TO    W-TIME2-SEC.
           MOVE W-TIME1-DEC      TO    W-TIME2-DEC.

           MOVE TIME-OGGI TO COPA-TIMEINS.

           MOVE RCCY021-DTOPER      TO COPA-DTCONT.

           MOVE RCCY021-COD-UFF     TO COPA-COD-UFF.
           MOVE RCCY021-VDACO       TO COPA-VDACO.
           MOVE RCCY021-IDCORR      TO COPA-IDCORR.
           MOVE RCCY021-IMPORTO     TO COPA-IMPORTO.

           PERFORM VARYING W-IND-1 FROM 100 BY -1
                     UNTIL W-IND-1 = 0 OR
                     RCCY021-NOTE (W-IND-1:1) NOT EQUAL SPACES
           END-PERFORM.
           MOVE W-IND-1             TO COPA-NOTE-LEN.
           MOVE RCCY021-NOTE        TO COPA-NOTE-TEXT.
           MOVE RCCY021-DTIM-3270   TO COPA-DTIMM-3270.

           PERFORM VARYING W-IND-1 FROM 100 BY -1
                     UNTIL W-IND-1 = 0 OR
                     RCCY021-NOTEANN (W-IND-1:1) NOT EQUAL SPACES
           END-PERFORM.
           MOVE W-IND-1             TO COPA-NOTEANN-LEN.
           MOVE RCCY021-NOTEANN     TO COPA-NOTEANN-TEXT.

           IF RCCY021-DTANN NOT EQUAL SPACES
              MOVE RCCY021-DTANN       TO COPA-DTANN
           ELSE
              MOVE '0001-01-01'        TO COPA-DTANN
           END-IF.

       EX-VALORIZZA-CAMPI.
           EXIT.

      ******************************************************************
       VALORIZZA-NUMCOPA.

           MOVE ZEROES TO W-APPO-NUMCOPA.

           PERFORM VARYING W-IND-TAB2 FROM 1 BY 1
              UNTIL W-IND-TAB2 > W-IND-TAB2-MAX
                 OR RCCY021-VDACO = W-TCOPA-VDACO-E(W-IND-TAB2)
                 OR RCCY021-VDACO = W-TCOPA-VDACO-L(W-IND-TAB2)
           END-PERFORM

           IF W-IND-TAB2 > W-IND-TAB2-MAX
              PERFORM VARYING W-IND FROM 1 BY 1
                 UNTIL W-IND > W-IND-MAX
                    OR RCCY021-VDACO = W-TAB-VDACO-E(W-IND)
                    OR RCCY021-VDACO = W-TAB-VDACO-L(W-IND)
              END-PERFORM

              IF W-IND > W-IND-MAX
                 DISPLAY 'VDACO NON PRESENTE SULLA TABELLA DI '
                 DISPLAY 'WORKING CONTENENTE TUTTE LE VOCI DACO'
                 DISPLAY 'RCCY021-VDACO : ' RCCY021-VDACO
                 MOVE 'S'        TO FL-ERRORE
                 PERFORM OP-FINALI  THRU EX-OP-FINALI
              ELSE
                 ADD 1           TO W-IND-TAB2-MAX
                 MOVE W-TAB-NUMCOPA(W-IND)
                                 TO W-TCOPA-NUMCOPA(W-IND-TAB2-MAX)
                 ADD 1           TO W-TCOPA-NUMCOPA(W-IND-TAB2-MAX)
                 MOVE W-TCOPA-NUMCOPA(W-IND-TAB2-MAX)
                                 TO W-APPO-NUMCOPA
                 MOVE W-TAB-VDACO-E(W-IND)
                                 TO W-TCOPA-VDACO-E(W-IND-TAB2-MAX)
                 MOVE W-TAB-VDACO-L(W-IND)
                                 TO W-TCOPA-VDACO-L(W-IND-TAB2-MAX)
                 MOVE W-TAB-DTINI-VAL(W-IND)
                                 TO W-TCOPA-DTINI-VAL(W-IND-TAB2-MAX)
                 MOVE W-TAB-DTFIN-VAL(W-IND)
                                 TO W-TCOPA-DTFIN-VAL(W-IND-TAB2-MAX)
              END-IF

           ELSE
              ADD 1              TO W-TCOPA-NUMCOPA(W-IND-TAB2)
              MOVE W-TCOPA-NUMCOPA(W-IND-TAB2)
                                 TO W-APPO-NUMCOPA
           END-IF.

       EX-VALORIZZA-NUMCOPA.
           EXIT.

      ******************************************************************
       AGGIORNA-RCTBANVD.

           PERFORM VARYING W-IND-TAB2 FROM 1 BY 1
              UNTIL W-IND-TAB2 > W-IND-TAB2-MAX

                 MOVE W-TCOPA-NUMCOPA(W-IND-TAB2)
                                 TO ANVD-NUMCOPA
                 MOVE W-TCOPA-VDACO-E(W-IND-TAB2)
                                 TO ANVD-VDACO-E
                 MOVE W-TCOPA-VDACO-L(W-IND-TAB2)
                                 TO ANVD-VDACO-L
                 MOVE W-TCOPA-DTINI-VAL(W-IND-TAB2)
                                 TO ANVD-DTINI-VAL
                 MOVE W-TCOPA-DTFIN-VAL(W-IND-TAB2)
                                 TO ANVD-DTFIN-VAL

                 EXEC SQL UPDATE RCTBANVD
                    SET ANVD_NUMCOPA    =:ANVD-NUMCOPA
                  WHERE ANVD_VDACO_E    =:ANVD-VDACO-E
                    AND ANVD_VDACO_L    =:ANVD-VDACO-L
                    AND ANVD_DTINI_VAL  =:ANVD-DTINI-VAL
                    AND ANVD_DTFIN_VAL  =:ANVD-DTFIN-VAL
                  END-EXEC

                  IF SQLCODE NOT EQUAL 0
                     MOVE SQLCODE   TO W-SQLCODE
                     DISPLAY 'ERRORE UPDATE RCTBANVD :'  W-SQLCODE
                     MOVE 'S'       TO FL-ERRORE
                     PERFORM OP-FINALI    THRU EX-OP-FINALI
                  END-IF

           END-PERFORM.

       EX-AGGIORNA-RCTBANVD.
           EXIT.

      ******************************************************************
       IMPOSTA-NOTE.
DEBUG *    DISPLAY 'SCRITTURA FLOSCART'.
LT+        MOVE SPACES TO RCCY021-NOTE.

           EVALUATE TRUE
            WHEN TIPO-ERRORE = '1'
             MOVE 'FRAZ. INVALIDO                      ' TO RCCY021-NOTE
            WHEN TIPO-ERRORE = '2'
             MOVE 'V.DACO ERRATA                       ' TO RCCY021-NOTE
            WHEN TIPO-ERRORE = '3'
             MOVE 'DATA FORM.ERRATA                    ' TO RCCY021-NOTE
            WHEN TIPO-ERRORE = '4'
             MOVE 'DT OPER < DT SVE                    ' TO RCCY021-NOTE
            WHEN TIPO-ERRORE = '5'
             MOVE 'IDCORR ERRATO                       ' TO RCCY021-NOTE
            WHEN TIPO-ERRORE = '6'
             MOVE 'IMP.NON NUMERICO                    ' TO RCCY021-NOTE
            WHEN TIPO-ERRORE = '7'
             MOVE 'DT.OPER > DT.IMM                    ' TO RCCY021-NOTE
            WHEN TIPO-ERRORE = '8'
             MOVE 'VOCE NO ALIM BATCH                  ' TO RCCY021-NOTE
           END-EVALUATE.

           MOVE RCCY021-DTOPER                   TO W-KEY-NOTE-DATA
           MOVE RCCY021-COD-UFF                  TO W-KEY-NOTE-COD-UFF
           MOVE RCCY021-VDACO                    TO W-KEY-NOTE-VDACO
           MOVE W-KEY-NOTE                       TO RCCY021-NOTE(17:22).

       EX-IMPOSTA-NOTE.
           EXIT.

       SCRITTURA-FLOSCART.
           WRITE REC-FLOSCART FROM REC-COPA.

           IF FS-FLOSCART NOT = '00'
              DISPLAY 'ERRORE IN SCRITTURA FLOSCART:' FS-FLOSCART
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           ELSE
             ADD 1 TO CTR-FLOSCART
             MOVE SPACE TO TIPO-ERRORE
           END-IF.

       EX-SCRITTURA-FLOSCART.
           EXIT.

      ******************************************************************
       SCRITTURA-FLOCOPA.

DEBUG *    DISPLAY 'SCRITTURA FLOCOPA'.

           WRITE REC-FLOCOPA FROM DCLRCTBCOPA.

           IF FS-FLOCOPA NOT = '00'
              DISPLAY 'ERRORE IN SCRITTURA FLOCOPA:' FS-FLOCOPA
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           ELSE
              ADD 1 TO CTR-FLOCOPA
           END-IF.

       EX-SCRITTURA-FLOCOPA.
           EXIT.

      ******************************************************************
       SCRITTURA-FLOCOUPD.

DEBUG *    DISPLAY 'SCRITTURA FLOCOUPD'.

           WRITE REC-FLOCOUPD FROM DCLRCTBCOPA.

           IF FS-FLOCOUPD NOT = '00'
              DISPLAY 'ERRORE IN SCRITTURA FLOCOUPD :' FS-FLOCOUPD
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           ELSE
              ADD 1 TO CTR-FLOCOUPD
           END-IF.

       EX-SCRITTURA-FLOCOUPD.
           EXIT.

      ******************************************************************
       SCRITTURA-FLOSTORI.

      *    DISPLAY 'SCRITTURA FLOSTORI'.

           WRITE REC-FLOSTORI FROM DCLRCTBCOPA.

           IF FS-FLOSTORI NOT = '00'
              DISPLAY 'ERRORE IN SCRITTURA FLOSTORI :' FS-FLOSTORI
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           ELSE
              ADD 1 TO CTR-FLOSTORI
           END-IF.

       EX-SCRITTURA-FLOSTORI.
           EXIT.

      ******************************************************************
       SCRITTURA-FLORACC.

      *    DISPLAY 'SCRITTURA FLORACC'.
           INITIALIZE REC-FLORACC.

           WRITE REC-FLORACC  FROM FLORACC-REC.

           IF FS-FLORACC NOT = '00'
              DISPLAY 'ERRORE IN SCRITTURA FLORACC :' FS-FLORACC
              MOVE 'S'         TO FL-ERRORE
              PERFORM OP-FINALI THRU EX-OP-FINALI
           ELSE
              ADD 1 TO CTR-FLORACC
           END-IF.

       EX-SCRITTURA-FLORACC.
           EXIT.

      ******************************************************************
      ***********  OPERAZIONI FINALI  **********************************
      ******************************************************************
       OP-FINALI.

           PERFORM VISUALIZZA-CONTATORI  THRU  EX-VISUALIZZA-CONTATORI.
           PERFORM CHIUSURA-FILE         THRU  EX-CHIUSURA-FILE.
           PERFORM DISPLAY-FINALI-E-STOP THRU  EX-DISPLAY-FINALI-E-STOP.

       EX-OP-FINALI.
           EXIT.

      ******************************************************************
       VISUALIZZA-CONTATORI.

           DISPLAY '**************************************************'.

           DISPLAY ' '.
           MOVE CTR-FLICOPA                        TO  W-EDIT.
           DISPLAY 'RECORD LETTI                     : ' W-EDIT.
           MOVE CTR-FLOCOPA                        TO  W-EDIT.
           DISPLAY 'RECORD SCRITTI FLOCOPA           : ' W-EDIT.
           MOVE CTR-FLOCOUPD                       TO  W-EDIT.
           DISPLAY 'RECORD SCRITTI ANNULLATI         : ' W-EDIT.
           MOVE CTR-FLORACC                        TO  W-EDIT.
           DISPLAY 'RECORD SCRITTI PER TAB RACCORDI  : ' W-EDIT.
           MOVE CTR-FLOSCART                       TO  W-EDIT.
           DISPLAY 'RECORD SCARTATI FLOSCART         : ' W-EDIT.
           MOVE CTR-FLOSTORI                       TO  W-EDIT.
           DISPLAY 'RECORD STORIO FLOSTORI           : ' W-EDIT.
           MOVE CTR-RCBTR02                        TO  W-EDIT.
           DISPLAY 'ACCESSI ROUTINE RCBTR02          : ' W-EDIT.
           DISPLAY '**************************************************'.

       EX-VISUALIZZA-CONTATORI.
           EXIT.

      ******************************************************************
       CHIUSURA-FILE.

           CLOSE FLICOPA.
           IF FS-FLICOPA NOT = '00'
              DISPLAY 'ERRORE CHIUSURA FILE FLICOPA: ' FS-FLICOPA
              MOVE 'S'         TO FL-ERRORE
           END-IF.

           CLOSE FLOSCART.
           IF FS-FLOSCART NOT = '00'
              DISPLAY 'ERRORE CHIUSURA FILE FLOSCART: ' FS-FLOSCART
              MOVE 'S'         TO FL-ERRORE
           END-IF.

           CLOSE FLOCOPA.
           IF FS-FLOCOPA NOT = '00'
              DISPLAY 'ERRORE CHIUSURA FILE FLOCOPA : '  FS-FLOCOPA
              MOVE 'S'         TO FL-ERRORE
           END-IF.

           CLOSE FLOCOUPD.
           IF FS-FLOCOUPD NOT = '00'
              DISPLAY 'ERRORE CHIUSURA FILE FLOCOUPD: '  FS-FLOCOUPD
              MOVE 'S'         TO FL-ERRORE
           END-IF.

           CLOSE FLOSTORI.
           IF FS-FLOSTORI NOT = '00'
              DISPLAY 'ERRORE CHIUSURA FILE FLOSTORI:' FS-FLOSTORI
              MOVE 'S'         TO FL-ERRORE
           END-IF.

           CLOSE FLORACC.
           IF FS-FLORACC NOT = '00'
              DISPLAY 'ERRORE CHIUSURA FILE FLORACC :' FS-FLORACC
              MOVE 'S'         TO FL-ERRORE
           END-IF.

       EX-CHIUSURA-FILE.
           EXIT.

      ******************************************************************
       DISPLAY-FINALI-E-STOP.

            DISPLAY '**************************************************'
            DISPLAY '*'
            DISPLAY '*--               FINE RCBT045                 --*'
            DISPLAY '*'
            DISPLAY '**************************************************'

           IF FL-ERRORE = 'S' OR
              RCCYPARM-ERRORE = 'S'
              EXEC SQL ROLLBACK END-EXEC
              MOVE 500 TO RETURN-CODE
           END-IF.

           STOP RUN.

       EX-DISPLAY-FINALI-E-STOP.
           EXIT.

      ******************************************************************
      ** LA LABEL ASTERISCATA DI SEGUITO VIENE ESPLOSA ALL'INTERNO    **
      ** DELLA COPY DI PROCEDURE RCCPPARM                             **
      ******************************************************************
      *ACCETTA-FLIPARM.

           COPY RCCPPARM.

      *EX-ACCETTA-FLIPARM.
      *    EXIT.

