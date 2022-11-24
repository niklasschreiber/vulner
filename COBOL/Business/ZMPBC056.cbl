       IDENTIFICATION DIVISION.
       PROGRAM-ID.    ZMPBC056.
       AUTHOR.        DATAMAT SPA.
      *================================================================*
      * Prodotto...................................................... *
      * Siseb 3 - Batch                                                *
      * Oggetto....................................................... *
      *----------------------------------------------------------------*
      * ZMPBC056                                                       *
      *----------------------------------------------------------------*
      * ESTRAZIONE S/C RIVALUTATI                                      *
      *----------------------------------------------------------------*
      * Data.... Prg.. Autore Descrizione Modifica.................... *
      * 14111997 00001 CAF    Gestione SC su 5 posizioni               *
      * 14111997 00000 LAA    Creazione oggetto                        *
      * 18121997 00014 CUA    Nomenclatura  trk  record                *
      *================================================================*
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *    SELECT ESUN0567 ASSIGN TO UT-S-ESN0567.
      *    SELECT ESUN0568 ASSIGN TO UT-S-ESN0568.
      *    SELECT ESUN0569 ASSIGN TO UT-S-ESN0569.
           SELECT ZMUN0561 ASSIGN TO UT-S-ZMUN0561.
           SELECT ZMUN0562 ASSIGN TO UT-S-ZMUN0562.
           SELECT ZMUN0563 ASSIGN TO UT-S-ZMUN0563.
       DATA DIVISION.
       FILE SECTION.
       FD  ZMUN0561 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0561.
           03  ISTITUTO            PIC 9(004).
           03  CAPOZONA            PIC 9(005).
           03  DIPENDENZA1         PIC 9(005).
           03  SEGNO               PIC X(001).
           03  CODICE-UIC-BASE     PIC 9(006).
           03  LIRE-VALUTA         PIC 9(001).
           03  TIPO-S-C            PIC 9(003).
      *
      ***--------------------- INIZIO - 00001 -----------------------***
      *
      *    03  S-C                 PIC 9(003).
           03  S-C                 PIC S9(005)    COMP-3.
      *
      ***---------------------- FINE - 00001 ------------------------***
      *
           03  DIVISA-SIGLA        PIC X(003).
           03  DIVISA-CODICE       PIC 9(003).
           03  TIPO-DIVISA         PIC 9(001).
           03  CAB-DIVISA          PIC 9(005).
           03  PAGINA-1M           PIC X(002).
           03  COLONNA-1M          PIC X(002).
           03  NDG                 PIC 9(009)         COMP-3.
           03  SUFFISSO            PIC 9(002).
           03  DIPENDENZA2         PIC 9(005).
           03  NUMERO              PIC 9(007)         COMP-3.
           03  FLAG-RAPP-RECIPR    PIC 9(001).
           03  DATA-ULT-MOV        PIC 9(009)         COMP-3.
           03  DATA-ACCENS         PIC 9(009)         COMP-3.
           03  IMPORTO-ACCENS      PIC S9(015)V999    COMP-3.
           03  NDG-NON-CONT1       PIC 9(009)         COMP-3.
           03  NDG-NON-CONT2       PIC 9(009)         COMP-3.
           03  PAESE-N-CONT-SIGLA1 PIC X(002).
           03  PAESE-N-CONT-COD1   PIC 9(003).
           03  PAESE-N-CONT-SIGLA2 PIC X(002).
           03  PAESE-N-CONT-COD2   PIC 9(003).
      *
      ***--------------------- INIZIO - 00001 -----------------------***
      *
      *    03  SC-CONTROPARTITA    PIC 9(003).
           03  SC-CONTROPARTITA    PIC S9(005)    COMP-3.
      *
      ***---------------------- FINE - 00001 ------------------------***
      *
           03  DIVISA-CONTR-SIGLA  PIC X(003).
           03  DIVISA-CONTR-COD    PIC 9(003).
           03  CAMBIO-ACCENS       PIC 9(004)V9(7)    COMP-3.
           03  CAMBIO-RIVALUT      PIC 9(004)V9(7)    COMP-3.
           03  SCAD-TASS-FORMATT   PIC X(010).
           03  SCAD-TASSO          PIC 9(009)         COMP-3.
           03  SCAD-OPERAZ         PIC 9(009)         COMP-3.
           03  DATA-VALUTA         PIC 9(009)         COMP-3.
           03  TASSO-RAPPORTO      PIC 9(004)V9(7)    COMP-3.
           03  TASSO-CC            PIC 9(004)V9(7)    COMP-3.
           03  FLAG-RAGGR-PAESE    PIC 9(001).
           03  FLAG-CONTR-TERM     PIC 9(001).
           03  SALDO-CONTABILE     PIC S9(015)V999     COMP-3.
      ***----- 0057A EURO2002-I
      *    03  CTV-SALDO-CONTAB    PIC S9(018)         COMP-3.
           03  CTV-SALDO-CONTAB    PIC S9(015)V999     COMP-3.
      ***----- 0057A EURO2002-F
           03  SALDO-LIQUIDO       PIC S9(015)V999     COMP-3.
      ***----- 0057A EURO2002-I
      *    03  CTV-SALDO-LIQ       PIC S9(018)         COMP-3.
           03  CTV-SALDO-LIQ       PIC S9(015)V999     COMP-3.
      ***----- 0057A EURO2002-F
           03  MOVIMENTI-DARE      PIC S9(015)V999     COMP-3.
           03  MOVIMENTI-AVERE     PIC S9(015)V999     COMP-3.
      ***----- 0057A EURO2002-I
      *    03  CTV-MOVIM-D         PIC S9(018)         COMP-3.
      *    03  CTV-MOVIM-A         PIC S9(018)         COMP-3.
      *    03  NUMERO-MOV-D        PIC S9(018)         COMP-3.
      *    03  NUMERO-MOV-A        PIC S9(018)         COMP-3.
           03  CTV-MOVIM-D         PIC S9(015)V999     COMP-3.
           03  CTV-MOVIM-A         PIC S9(015)V999     COMP-3.
           03  NUMERO-MOV-D        PIC S9(015)V999     COMP-3.
           03  NUMERO-MOV-A        PIC S9(015)V999     COMP-3.
      ***----- 0057A EURO2002-F
           03  TIPO-NDG            PIC 9(001).
           03  SIGLA-PAESE-NDG     PIC X(002).
           03  CODICE-PAESE-NDG    PIC 9(003).
           03  TIPO-PAESE          PIC 9(001).
           03  CONTINENTE          PIC 9(001).
           03  ZONA-MONETARIA      PIC 9(002).
           03  NDG-CASAMADRE       PIC 9(009)         COMP-3.
           03  RAG-SOCIALE1        PIC X(035).
           03  RAG-SOCIALE2        PIC X(035).
           03  RESIDENZA           PIC 9(001).
           03  CODICE-PROVINCIA    PIC 9(003).
           03  CODICE-ATTIVITA     PIC 9(006).
           03  CODICE-FISCALE      PIC X(016).
           03  DIP-APPOGGIO        PIC 9(005).
           03  CAB-DIRETTO         PIC 9(005).
           03  CAB-CASAMADRE       PIC 9(005).
           03  CODICE-UIC-BANCA    PIC 9(004).
           03  CODICE-ABI-BANCA    PIC 9(005).
           03  NUM-MECCANOGRAF     PIC X(010).
           03  FLAG-RAPP-ISTITUTO  PIC 9(001).
           03  N-ANAGRAF-GENER     PIC 9(009)         COMP-3.
           03  FLAG-IDENTIF-BANCA  PIC 9(001).
           03  CATEG-TASSI-PASS    PIC 9(004).
           03  CATEG-FIDO          PIC 9(004).
           03  FLAG-RISCHIO        PIC 9(001).
           03  FLAG-TIPO-MODELLO   PIC 9(001).
           03  FLAG-RIVALUTAZ      PIC 9(001).
           03  FLAG-TESOR-ITALIA   PIC 9(001).
           03  CATEG-POS-V-EST     PIC 9(004).
           03  CATEG-DISP-IMP      PIC 9(004).
           03  RACCORDO-RATE-RISC  PIC 9(004).
           03  CODICE-UIC-ATTIVO   PIC 9(006).
           03  CODICE-UIC-ATT-DER  PIC 9(006).
           03  CODICE-UIC-PASSIVO  PIC 9(006).
           03  CODICE-UIC-PASS-DER PIC 9(006).
           03  CODICE-MATRICE      PIC 9(006).
           03  RESIDENZA-S-C       PIC 9(001).
           03  DATA-SEGNALAZIONE   PIC 9(009)          COMP-3.
           03  REMUNERAZ-C-VALUT   PIC 9(001).
           03  DURATA              PIC 9(001).
           03  MASTRO-RIFERIM      PIC X(011).
           03  FILLER              PIC X(014).
       FD  ZMUN0562 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0562.
           03 CIST-K               PIC 9(004).
           03 DOGG-K               PIC 9(008).
           03 ESTR-K               PIC A(001).
           03 GG-K                 PIC 9(002).
           03 DDOM-K               PIC 9(008).
           03 FILLER               PIC X(057).
           03 RAD-IST-K            PIC X(430).
       FD  ZMUN0563 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0563.
           03  ISTITUTO           PIC 9(004).
           03  CAPOZONA           PIC 9(005).
           03  DIPENDENZA         PIC 9(005).
           03  DATA-ESECUZIONE    PIC 9(009)     COMP-3.
           03  DATA-CONTAB        PIC 9(009)     COMP-3.
           03  TIPO-SC            PIC 9(003).
      *
      ***--------------------- INIZIO - 00001 -----------------------***
      *
      *    03  S-C                PIC 9(003).
           03  S-C                PIC S9(005)    COMP-3.
      *
      ***---------------------- FINE - 00001 ------------------------***
      *
           03  CODICE-MASTRO      PIC X(011).
           03  TRK                PIC 9.
      ***----- 0057A EURO2002-I
      *    03  SALDO-INIZIALE     PIC S9(018)     COMP-3.
      *    03  MOVIMENTI-DARE     PIC 9(018)     COMP-3.
      *    03  MOVIMENTI-AVERE    PIC 9(018)     COMP-3.
           03  SALDO-INIZIALE     PIC S9(015)V999    COMP-3.
           03  MOVIMENTI-DARE     PIC 9(015)V999     COMP-3.
           03  MOVIMENTI-AVERE    PIC 9(015)V999     COMP-3.
      ***----- 0057A EURO2002-F
           03  NUMERO-MOV-DARE    PIC 9(007)      COMP-3.
           03  NUMERO-MOV-AVERE   PIC 9(007)      COMP-3.
       WORKING-STORAGE SECTION.
       77 CAMPO-ISTITUTO         PIC 9(004).
          COPY SYWCI005.
       01 W-COM-SCRIVI           PIC 9(001)    VALUE 0.
      ***----- 0057A EURO2002-I
      *01 CONTATORE-SC           PIC S9(018)    COMP-3 VALUE 0.
      *01 MOV-DARE               PIC S9(018)    COMP-3 VALUE 0.
      *01 MOV-AVERE              PIC S9(018)    COMP-3 VALUE 0.
       01 CONTATORE-SC           PIC S9(015)V999 COMP-3 VALUE 0.
       01 MOV-DARE               PIC S9(015)V999 COMP-3 VALUE 0.
       01 MOV-AVERE              PIC S9(015)V999 COMP-3 VALUE 0.
      ***----- 0057A EURO2002-F
       01 FLAGESEC               PIC 9 VALUE 0.
       01 SW                     PIC 9.
       01 SW-UTE                 PIC 9.
       01 SW-IST                 PIC 9.
       01 DATAFIME               PIC 9(009)      COMP-3.
       01 DATACHIU               PIC 9(009)      COMP-3.
       01 CUTE-UME               PIC 9(005).
       01 DIPENDENZA1-BIS        PIC 9(005).
       01 DIPENDENZA2-BIS        PIC 9(005).
       01 DOGG-COM               PIC 9(009)      COMP-3.
       01 KEY-ROTTURA.
          03  CIST-R       PIC 9(004).
          03  MASTRO-R     PIC X(011).
      *
      ***--------------------- INIZIO - 00001 -----------------------***
      *
      *   03  SC-R         PIC 9(003).
          03  SC-R         PIC S9(005)    COMP-3.
      *
      ***---------------------- FINE - 00001 ------------------------***
      *
       01 KEY-LETTURA.
          03  CIST-L       PIC 9(004).
          03  MASTRO-L     PIC X(011).
      *
      ***--------------------- INIZIO - 00001 -----------------------***
      *
      *   03  SC-L         PIC 9(003).
          03  SC-L         PIC S9(005)    COMP-3.
      *
      ***---------------------- FINE - 00001 ------------------------***
      *
       01 KEY-ROTTURA2.
          03  CIST-R       PIC 9(004).
          03  TIPOSC-R     PIC 9(003).
       01 KEY-LETTURA2.
          03  CIST-L       PIC 9(004).
          03  TIPOSC-L     PIC 9(003).
          COPY ZMOAD011.
          COPY ZMOAD021.
       PROCEDURE DIVISION.
       OPEN-FILES.
           OPEN  INPUT  ZMUN0561.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE01.
           OPEN  INPUT  ZMUN0562.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE02.
           OPEN  OUTPUT ZMUN0563.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE03.
       INIZIALIZZA.
           MOVE ALL '9' TO KEY-ROTTURA.
           MOVE 9999 TO CAMPO-ISTITUTO.
           MOVE 1 TO SW.
      ************************************************************
      *    LEGGO FILE CONTABILITA' PERIODO                       *
      ************************************************************
       READ-CONTAB.
           DISPLAY  'LEGGI READ-CONTAB'.
           READ ZMUN0561 AT END
             PERFORM ULTIMO-RECORD THRU EX-ULTIMO-RECORD
             GO TO WRITE-FINE.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE04.
           DISPLAY 'FLAG DI RIVALUTAZIONE ' FLAG-RIVALUTAZ.
           IF FLAG-RIVALUTAZ OF ZMRK0561 NOT = 2 AND NOT = 3 AND
                                        NOT = 4 AND NOT = 5 AND
                                        NOT = 6 AND NOT = 7 AND
                                        NOT = 8 AND NOT = 9 THEN
             GO TO READ-CONTAB.
           MOVE 1       TO      W-COM-SCRIVI.
           IF FLAG-RIVALUTAZ OF ZMRK0561 = 0 THEN
             GO TO ERRORE4.
           DISPLAY 'PREPARA KEY LETTURA '.
       PREPARA-KEY-LETTURA.
           MOVE ISTITUTO       OF ZMRK0561 TO CIST-L OF KEY-LETTURA
           MOVE MASTRO-RIFERIM OF ZMRK0561 TO MASTRO-L OF KEY-LETTURA
           MOVE S-C            OF ZMRK0561 TO SC-L     OF KEY-LETTURA
           MOVE ISTITUTO       OF ZMRK0561 TO CIST-L OF KEY-LETTURA2
           MOVE TIPO-S-C       OF ZMRK0561 TO TIPOSC-L OF KEY-LETTURA2
           display 'test su prepara '
      ************************************************************
      *    TEST SULLA CADUTA DI CONTROLLO                        *
      ************************************************************
           IF KEY-LETTURA NOT = KEY-ROTTURA THEN
              GO TO ROTTURA2.
       ROTTURA1.
           MOVE 0 TO SW.
           COMPUTE CONTATORE-SC = CONTATORE-SC + CTV-SALDO-CONTAB
           OF ZMRK0561.
           MOVE KEY-LETTURA         TO KEY-ROTTURA
           MOVE KEY-LETTURA2        TO KEY-ROTTURA2
           MOVE DIPENDENZA1 OF ZMRK0561 TO DIPENDENZA1-BIS
           MOVE CAPOZONA    OF ZMRK0561 TO DIPENDENZA2-BIS
           MOVE 0 TO CIST-L         OF KEY-LETTURA
           MOVE SPACES TO MASTRO-L  OF KEY-LETTURA
           MOVE 0 TO TIPOSC-L       OF KEY-LETTURA2
           MOVE 0 TO SC-L           OF KEY-LETTURA
           GO TO READ-CONTAB.
       ROTTURA2.
           IF SW = 1 THEN
              PERFORM READ-PARAMETRO THRU EX-READ-PARAMETRO
              MOVE ISTITUTO OF ZMRK0561 TO CAMPO-ISTITUTO
              GO TO ROTTURA1.
           IF CONTATORE-SC = 0 THEN
              MOVE 0 TO MOV-DARE
              MOVE 0 TO MOV-AVERE
           ELSE
              IF CONTATORE-SC > 0 THEN
                 MOVE 0 TO MOV-DARE
                 MOVE CONTATORE-SC TO MOV-AVERE
              ELSE
                 IF CONTATORE-SC < 0 THEN
                    MOVE CONTATORE-SC TO MOV-DARE
                    MOVE 0 TO MOV-AVERE.
           PERFORM PREPARA-RECORD THRU EX-PREPARA-RECORD.
           WRITE ZMRK0563.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE06.
           MOVE 0 TO CONTATORE-SC
           IF CAMPO-ISTITUTO NOT = ISTITUTO OF ZMRK0561
              PERFORM READ-PARAMETRO THRU EX-READ-PARAMETRO
              MOVE ISTITUTO OF ZMRK0561 TO CAMPO-ISTITUTO.
           GO TO ROTTURA1.
      ************************************************************
      *    PREPARO RECORD DI OUTPUT                              *
      ************************************************************
       PREPARA-RECORD.
           MOVE CIST-R OF KEY-ROTTURA     TO ISTITUTO OF ZMRK0563
           MOVE CUTE-UME                  TO CAPOZONA OF ZMRK0563
           MOVE DIPENDENZA1-BIS           TO DIPENDENZA  OF ZMRK0563
           MOVE DATAFIME              TO DATA-ESECUZIONE OF ZMRK0563
           MOVE DATAFIME              TO DATA-CONTAB     OF ZMRK0563
           MOVE TIPOSC-R OF KEY-ROTTURA2 TO TIPO-SC      OF ZMRK0563
           MOVE SC-R OF KEY-ROTTURA     TO S-C           OF ZMRK0563
           MOVE MASTRO-R OF KEY-ROTTURA TO CODICE-MASTRO OF ZMRK0563
           MOVE 2                       TO TRK           OF ZMRK0563
           MOVE 0        TO SALDO-INIZIALE               OF ZMRK0563
           MOVE MOV-DARE TO MOVIMENTI-DARE               OF ZMRK0563
           MOVE MOV-AVERE TO MOVIMENTI-AVERE             OF ZMRK0563
           MOVE 0 TO NUMERO-MOV-DARE                     OF ZMRK0563
           MOVE 0 TO NUMERO-MOV-AVERE                    OF ZMRK0563.
       EX-PREPARA-RECORD.
           EXIT.
       ULTIMO-RECORD.

           IF W-COM-SCRIVI NOT = 1
              GO TO EX-ULTIMO-RECORD
           END-IF

           IF CONTATORE-SC = 0 THEN
              MOVE 0 TO MOV-DARE
              MOVE 0 TO MOV-AVERE
           ELSE
              IF CONTATORE-SC > 0 THEN
                 MOVE 0 TO MOV-DARE
                 MOVE CONTATORE-SC TO MOV-AVERE
              ELSE
                 IF CONTATORE-SC < 0 THEN
                    MOVE CONTATORE-SC TO MOV-DARE
                    MOVE 0 TO MOV-AVERE.
           PERFORM PREPARA-RECORD THRU EX-PREPARA-RECORD.
           WRITE ZMRK0563.
           IF  I-O-TEST NOT = '00'
              GO TO ERRORE07.
       EX-ULTIMO-RECORD.
           EXIT.
      ************************************************************
      *    CARICA PARAMETRI DALLA SCHEDA PARAMETRO               *
      ************************************************************
       READ-PARAMETRO.
           READ ZMUN0562 AT END GO TO ERRORE1.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE05.
           IF CIST-K OF ZMRK0562 NOT = ISTITUTO OF ZMRK0561
              GO TO READ-PARAMETRO.
           MOVE DOGG-K OF ZMRK0562 TO DOGG-COM
           MOVE RAD-IST-K TO ZMOAD021
           MOVE FFNEMESO OF ZMOAD021 TO FLAGESEC.
           MOVE DFNEMESO OF ZMOAD021 TO DATAFIME.
           MOVE DCHIQDR  OF ZMOAD021 TO DATACHIU
           MOVE CUTEUME  OF ZMOAD021 TO CUTE-UME.
       EX-READ-PARAMETRO.
            EXIT.
       ERRORE1.
           MOVE 999 TO RETURN-CODE
           DISPLAY 'ZMPBC056 - ERRORE CARICA-PARAM.   '
           GO TO FINE.
       ERRORE4.
           MOVE 999 TO RETURN-CODE
           DISPLAY 'ZMPBC056 - ERRORE FLAG-RIVAL = 0  '
           GO TO FINE.
       ERRORE01.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPBC056 - ERRORE OPEN FILE ZMUN0561'.
           DISPLAY 'ZMPBC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE02.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPBC056 - ERRORE OPEN FILE ZMUN0562'.
           DISPLAY 'ZMPBC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE03.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPBC056 - ERRORE OPEN FILE ZMUN0563'.
           DISPLAY 'ZMPBC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE04.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPBC056 - ERRORE READ FILE ZMUN0561'.
           DISPLAY 'ZMPBC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE05.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPBC056 - ERRORE READ FILE ZMUN0562'.
           DISPLAY 'ZMPBC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE06.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPBC056 - ERRORE WRITE FILE ZMUN0563'.
           DISPLAY 'ZMPBC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE07.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPBC056 - ERRORE WRITE FILE ZMUN0563'.
           DISPLAY 'ZMPBC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       WRITE-FINE.
           MOVE 0 TO RETURN-CODE
           DISPLAY 'ZMPBC056 - CHIUDE BENE'.
       FINE.
           CLOSE ZMUN0561 ZMUN0562.
           CLOSE ZMUN0563.
           COPY SYWCI006.
           STOP RUN.
