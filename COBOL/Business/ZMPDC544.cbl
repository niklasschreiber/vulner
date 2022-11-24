       IDENTIFICATION DIVISION.
       PROGRAM-ID.    ZMPDC544.
       AUTHOR.        DATAMAT SPA.

      *----------------------------------------------------------------*
      *               C V S  DB2                                       *
      *     ESTRAZIONE DATI PER SEGNALAZIONI UIC                       *
      *                                                                *
      * VAR001 - PER VALORIZZARE IN FUTURO EURO/LIRE                   *
      * VAR002 - MODIFICHE IN BASE AL DIAGNOSTICO ELEUTERIA            *
      * VAR003 - DISASTERISCARE SE LE FILIALI NON HANNO MODIFICATO SU  *
      *          ACVCNS I CAMPI FAREAPREV E NUMADDETTI                 *
      * VAR004 - MODIFICHE PER ELIMINARE ERRORE 075 DA T06             *
      *          MODIFICHE PER ELIMINARE ERRORE 155 DA T06             *
      *----------------------------------------------------------------*
      * CAR860 Ù 06/05/99 Ù CPG Ù VALORIZZAZIONE DATI T05              *
      * CAR873 Ù 19/05/99 Ù CPG Ù VALORIZZAZIONE CAMPO DCOMPENS        *
      * CAR891 Ù 07/06/99 Ù FAA Ù MODIFICA ESTRAZIONE CVS ANNULLATA DA *
      *                         Ù SEGNALARE ASSOCIATA A REGOLAMENTO    *
      * BPO    Ù 12/06/04 Ù DOL Ù VALORIZZ CAB SECONDO IL CIRCUITO     *
      *        Ù          Ù     Ù RICHIESTA UIC BPOSTA                 *
      * BPO    Ù 12/06/04 Ù DOL1Ù VALORIZZ CAB SECONDO IL CIRCUITO     *
      *        Ù          Ù     Ù RICHIESTA UIC BPOSTA                 *
LP0812* LP     Ù 12/08/04 Ù     Ù CHIAMATA MODULO BATCH ANZICHE CICS   *
      * BPO520 Ù 20/03/07 Ù DOL Ù ELIMINATO ERRORE 014 DA T00
      * BPO613 Ù 14/01/08 Ù SIA Ù GESTIONE SEPA
      *----------------------------------------------------------------*

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT ZMUN5440 ASSIGN TO DA-S-ZMN5440.
           SELECT ZMUN5441 ASSIGN TO DA-S-ZMN5441.
           SELECT ZMUN5442 ASSIGN TO DA-S-ZMN5442.
           SELECT ZMUN5443 ASSIGN TO DA-S-ZMN5443.
           SELECT ZMUN5444 ASSIGN TO DA-S-ZMN5444.
           SELECT ZMUN5445 ASSIGN TO DA-S-ZMN5445.
           SELECT ZMUN5446 ASSIGN TO DA-S-ZMN5446.
           SELECT ZMUN5447 ASSIGN TO DA-S-ZMN5447.
           SELECT ZMUN5448 ASSIGN TO DA-S-ZMN5448.

           SELECT ZMUN544A ASSIGN TO DA-S-ZMN544A.
           SELECT ZMUN544B ASSIGN TO DA-S-ZMN544B.
           SELECT ZMUN544C ASSIGN TO DA-S-ZMN544C.

       DATA DIVISION.
       FILE SECTION.

       FD  ZMUN5442 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  RECMER PIC X(272).

       FD  ZMUN5443 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  RECMER2 PIC X(272).

       FD  ZMUN5444 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  RECCMP PIC X(212).

       FD  ZMUN5445 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  RECNRE PIC X(135).

       FD  ZMUN5446 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  RECREG PIC X(177).

       FD  ZMUN5447 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  RECNME PIC X(234).

       FD  ZMUN5448 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  RECFIN PIC X(236).

      **********************************************
      *  FILE UIC 3                      LTH:400   *
      **********************************************
       FD  ZMUN544A LABEL RECORD ARE STANDARD
                    RECORDING MODE IS F
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK1021.
           03  AREA-KEY2.
               05 CIST               PIC 9(004).
               05 PRG-SEGNALANTE     PIC 9(005).
               05 PRG-OPERATORE      PIC 9(006).
               05 TIPO-REC-UIC       PIC X(003).
               05 PRG-REG-CMP        PIC 9(003).
               05 COD-SEGNALANTE     PIC X(016).
               05 COD-OPERATORE      PIC X(016).
               05 COD-ABI            PIC 9(005).
               05 CAB                PIC 9(005).
               05 NUM-DICH           PIC 9(015) COMP-3.
               05 NUM-REG            PIC 9(015) COMP-3.
               05 TIPO-DICHIARA      PIC 9(002).
               05 STATO-DICHIARA     PIC X(002).
               05 FILLER             PIC X(017).
           03  AREA-UIC2             PIC X(300).

      ***************************************
      * SK PARAMETRO                        *
      ***************************************
       FD  ZMUN5440 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  ZMRK1022.
           03  ISTITUTO           PIC 9(004).
           03  MESE-RIF-CVS       PIC 9(008).
           03  NUM-INVIO          PIC 9(002).
           03  DATA-PROD-SUPP     PIC 9(008).
           03  TIPO-INVIO         PIC X(001).
           03  CODICE-ABI         PIC 9(005).
           03  FILLER             PIC X(052).

      ***************************************
      * FILE PARAMETRICO  ESUN1102          *
      ***************************************
       FD  ZMUN5441 LABEL RECORD STANDARD
                  RECORDING MODE IS F
                  BLOCK CONTAINS 0 RECORDS.
       01  ZMRK1023.
           03  CIST-K             PIC 9(004).
           03  DOGG-K             PIC 9(008).
           03  ESTR-K             PIC A(001).
           03  GG-K               PIC 9(002).
           03  DDMN-K             PIC 9(008).
           03  FILLER             PIC X(057).
           03  RAD-IST-K          PIC X(430).

      ************************************************************
      * FILE     ERRORI       DA STAMPARE SUCCESSIVAMENTE        *
      ************************************************************
       FD  ZMUN544B LABEL RECORD STANDARD
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  ZMRK1026.
           03  AREA-ERR.
               05 ISTITUTO           PIC 9(004).
               05 FIL-EMISS          PIC 9(005).
               05 MESE-RIF-CVS       PIC 9(008).
               05 DOGG-K             PIC 9(008).
               05 TIPO-ERRORE        PIC X(001).
               05 RIFOPE-CDPZ        PIC 9(005).
               05 RIFOPE-NUMOPE      PIC 9(007).
               05 RIF-OPER-ESTERO    PIC X(019).
               05 RIF-CLIENTE        PIC X(015).
               05 COD-ABI            PIC 9(005).
               05 CABFIL             PIC 9(005).
               05 NUMDICH            PIC 9(015) COMP-3.
               05 SEGNALANTE         PIC X(016).
               05 CAMPO-ASTS         PIC X.
               05 COD-OPERATORE      PIC X(016).
               05 CAMPO-ASTO         PIC X.
               05 NUMREGOL           PIC 9(015) COMP-3.
               05 TIPO-DICHIARAZIONE PIC 9(002).
               05 DVAL-REG           PIC 9(009) COMP-3.
               05 DIV-IMP-CAP        PIC X(003).
               05 IMP-CAP            PIC 9(015)V9(003) COMP-3.
               05 NOME-FILE          PIC X(10).
               05 STATO-DICHIARA     PIC X(02).
               05 FILLER             PIC X(036).

      ************************************************************
      * FILE     CAMBI                                           *
      ************************************************************
       FD  ZMUN544C LABEL RECORD STANDARD
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  ZMRK1027.
           05 ISTITUTO           PIC 9(004).
           05 DIVISA             PIC X(003).
           05 TDIV               PIC 9(001).
           05 CMODUIC            PIC 9(003).
CARA39*    05 CSIGBOR            PIC X(002).
CARA39*    05 CAMBIO             PIC 9(004)V9(007) COMP-3.
CARA39     05 CAMBIO             PIC 9(009)V9(006) COMP-3.
CARA39     05 FLAG-LIRA-EURO     PIC X(001).
CARA39     05 FLAG-ERRORE        PIC X(002).
CARA39*    05 FLAG-ERRORE        PIC X(003).

       WORKING-STORAGE SECTION.
       01  AREA-INTERFACCE.
           02  AREA-SQLCODE  PIC S9(9) COMP.
           02  AREA-DESCERR  PIC X(79).
           02  AREA-TABELLA  PIC X(997).
       01 WCM-CHIAMATO           PIC X(08) VALUE SPACES.
       01 CAMPI-COMODO.
           02  WRK-NDGESTE   PIC X(16) VALUE SPACES.
           02  WRK-CDPZAPP   PIC 9(5) VALUE ZEROES.
           02  WRK-RAEGAE    PIC 9(7) VALUE ZEROES.
           02  WRK-CDPZ-X    PIC X(5).
           02  WRK-CDPZ-N REDEFINES WRK-CDPZ-X   PIC 9(5).
           02  INDICE1                             PIC 9(2).
           02  INDICE2                             PIC 9(2).
           02  WRK-NDG-16-X                        PIC X(16).
           02  WRK-NDG-16-N REDEFINES WRK-NDG-16-X PIC 9(16).
           02  WRK-IND-NOME                        PIC 9(02).
           02  WRK-IND-COGNOME                     PIC 9(02).
           02  WRK-NOMCOG                          PIC X(35).
           02  WRK-SWFNDG                          PIC X(4).
           02  WRK-SWFPAE                          PIC X(2).
           02  WRK-SWFREG                          PIC X(2).
           02  WRK-SWFBCH                          PIC X(3).
       01  AREA-INTERFACCIA-ANAGRAFE.
           COPY ACS908A.
      *----> AREA DI APPOGGIO ROUTINE COD PAE ISO
           COPY ACZ023A.
CARA39 01  IND1                  PIC 9(04) VALUE ZEROES.
CARA39 01  WRK-FINE              PIC X(02) VALUE SPACES.
CARA39 01  WRK-DATA-EURO         PIC 9(08) VALUE ZEROES.
CARA39 01  WRK-CVS-EURO          PIC X(01) VALUE SPACES.
CARA39 01  NASTRO-DEL            PIC 9(08) VALUE ZEROES.
CARA39 01  WRK-CTV-EURO          PIC 9(18) VALUE ZEROES.
       01  WRK-DIFFAAAAMM        PIC S9(4).
       01  WRK-DIFFAAAA          PIC S9(2).
       01  WRK-DIFFMM            PIC S9(2).
       01  WRK-DSDOGAAAAMM       PIC 9(06).
       01  WRK-DVALNOAAAAAMM     PIC 9(06).
       01  WRK-DSDOG             PIC 9(08).
       01  WRK-DSDOGR REDEFINES WRK-DSDOG.
           02 AAAAMM.
              03 AAAA            PIC 9(4).
              03 MM              PIC 9(2).
           02 GG                 PIC 9(2).
       01  WRK-DVALNOA           PIC 9(08).
       01  WRK-DVALNOAR REDEFINES WRK-DVALNOA.
           02 AAAAMM.
              03 AAAA            PIC 9(4).
              03 MM              PIC 9(2).
           02 GG                 PIC 9(2).
CAR873 01  WRK-DCOMPENS          PIC 9(08).
CAR873 01  RWRK-DCOMPENS REDEFINES WRK-DCOMPENS.
CAR873     03 GG                 PIC 9(2).
CAR873     03 MM                 PIC 9(2).
CAR873     03 SS                 PIC 9(2).
CAR873     03 AA                 PIC 9(2).
CAR873 01  WRK-DCOMPENS1         PIC 9(08).
CAR873 01  RWRK-DCOMPENS1 REDEFINES WRK-DCOMPENS1.
CAR873     03 SS                 PIC 9(2).
CAR873     03 AA                 PIC 9(2).
CAR873     03 MM                 PIC 9(2).
CAR873     03 GG                 PIC 9(2).
       01  WINDT               PIC S9(05)  COMP-3 VALUE ZERO.
       01  WINDC               PIC S9(05)  COMP-3 VALUE ZERO.
       01  WA-CIST             PIC S9(04)V COMP-3 VALUE ZERO.
       01  WCM-CIST            PIC S9(04)V COMP-3 VALUE ZERO.
       01  INDICE              PIC 9(005)         VALUE ZERO.
       01  ILBOABN0            PIC X(08)          VALUE 'ILBOABN0'.
       01  W-SQLCODE           PIC 9(05)   COMP-3 VALUE ZERO.
       01  COMP-CODE           PIC 9(03)   COMP   VALUE ZERO.
       01  WA-NUMREG           PIC 9(15)          VALUE ZERO.
       01  WA-NUMCVS           PIC 9(14)          VALUE ZERO.
       01  WA-SPORTELLO        PIC 9(03)          VALUE ZERO.
       01  DIVISA-TITOLO       PIC 9(3)           VALUE ZERO.

       01  FINE-ACVMER         PIC X(02)  VALUE 'NO'.
       01  FINE-ACVCMP         PIC X(02)  VALUE 'NO'.
       01  FINE-ACVNRE         PIC X(02)  VALUE 'NO'.
       01  FINE-ACVREG         PIC X(02)  VALUE 'NO'.
       01  FINE-ACVNME         PIC X(02)  VALUE 'NO'.
       01  FINE-ACVFIN         PIC X(02)  VALUE 'NO'.
       01  FINE-ACVMER2        PIC X(02)  VALUE 'NO'.

       01  SW-FINE1            PIC X(02)  VALUE 'NO'.
       01  SW-FINE2            PIC X(02)  VALUE 'NO'.
       01  SW-FINE3            PIC X(02)  VALUE 'NO'.

       01  WRK-TROVATO                 PIC X(002)  VALUE 'NO'.
       01  WRK-SENZAREG                PIC X(002)  VALUE 'NO'.
       01  WRK-POSTICIP                PIC X(002)  VALUE 'NO'.
       01  SW-CARICA-SEGNALANTE        PIC X(002)  VALUE 'SI'.

       01  COMODO-ISTITUTO             PIC 9(004)        VALUE 0.
CARA39*01  COMODO-CAMBIO               PIC 9(004)V9(003) VALUE 0.
CARA39 01  COMODO-CAMBIO               PIC 9(009)V9(003) VALUE 0.
       01  COMODO-DIVISA               PIC X(003)        VALUE SPACES.
       01  COMODO-CMODUIC              PIC 9(003)        VALUE 0.

       01  DATA-X1                     PIC 9(008)   VALUE ZERO.
       01  DATA-CH                     PIC 9(008)   VALUE ZERO.
       01  DATA-CHR                    PIC 9(008)   VALUE ZERO.
       01  DATA-Y1                     PIC 9(008)   VALUE ZERO.
       01  VERIFICA                    PIC 9(005)   VALUE ZERO.
       01  DENOMINAZ                   PIC X(050)   VALUE SPACES.
       01  CONTROCODICE                PIC 9        VALUE ZERO.

       01   CODICE-XXX.
            03  CODICE5        PIC 9(005).
            03  CONTRO5        PIC 9(001).

       01  A1                  PIC 99   VALUE ZEROES.
       01  A2                  PIC 99   VALUE ZEROES.
       01  A3                  PIC 99   VALUE ZEROES.
       01  A4                  PIC 99   VALUE ZEROES.
       01  A5                  PIC 99   VALUE ZEROES.
       01  A6                  PIC 99   VALUE ZEROES.
       01  A7                  PIC 99   VALUE ZEROES.
       01  A8                  PIC 99   VALUE ZEROES.
       01  A9                  PIC 99   VALUE ZEROES.
       01  A10                 PIC 99   VALUE ZEROES.
       01  A11                 PIC 9    VALUE ZEROES.
       01  A12                 PIC 99   VALUE ZEROES.

       01  FLAGS-1022.
           03  FLAG-EOF-1022    PIC X(5)  VALUE SPACES.
               88 EOF-1022                VALUE 'FALSE'.

       01  FLAGS-1023.
           03  FLAG-EOF-1023    PIC X(5)  VALUE SPACES.
               88 EOF-1023                VALUE 'FALSE'.

       01  ERR-DB2.
           03  SEGNO-DB2    PIC X(01) VALUE SPACES.
           03  COD-DB2      PIC 9(04) VALUE ZERO.

       01  TABELLA.
           03  ELEMENTO  OCCURS 10  TIMES INDEXED BY INDT.
               05  EL-CIST    PIC S9(04)V  COMP-3.
               05  EL-ABI     PIC S9(05)V  COMP-3.
               05  EL-DATA-DA PIC S9(08)V  COMP-3.
               05  EL-DATA-A  PIC S9(08)V  COMP-3.
               05  EL-RIFCVS  PIC S9(08)V  COMP-3.
               05  EL-DATARIF PIC S9(08)V  COMP-3.
               05  EL-DOGG    PIC S9(08)V  COMP-3.

       01  TABELLA-CAMBI.
           03 CAMBI OCCURS 500 TIMES INDEXED BY INDC.
              05 ISTITUTO        PIC 9(004).
              05 DIVISA          PIC X(003).
              05 CMODUIC         PIC 9(003).
              05 CAMBIO          PIC 9(015)V9(003).
              05 GIORNI          PIC 9(005).

       01   WA-CAB             PIC 9(5)  VALUE ZEROES.
       01   WA-CABR REDEFINES  WA-CAB.
            02 A               PIC 9.
            02 B               PIC 9.
            02 C               PIC 9.
            02 D               PIC 9.
            02 E               PIC 9.

       01   CAMPO3             PIC 9(8)  VALUE ZEROES.
       01   CAMPO4 REDEFINES CAMPO3.
            02 F1              PIC 99.
            02 G               PIC 9.
            02 H               PIC 99.
            02 I2              PIC 9.
            02 L               PIC 99.

       01   CAMPO5             PIC 9(8)  VALUE ZEROES.
       01   CAMPO6 REDEFINES CAMPO5.
            02 M               PIC 9.
            02 N1              PIC 9.
            02 O               PIC 9.
            02 P               PIC 9.
            02 Q               PIC 9.
            02 R1              PIC 9.
            02 S               PIC 9.
            02 T               PIC 9.

       01  CAMPO7              PIC 9(2) VALUE ZEROES.
       01  CAMPO8 REDEFINES CAMPO7.
           02   X              PIC 9.
           02   Y              PIC 9.

       01  CAMPO9              PIC 9(2) VALUE ZEROES.
       01  CAMPO10 REDEFINES CAMPO9.
           02   K              PIC 9.
           02   J              PIC 9.

       01  COM-AREA.
           03  COM-KEY2.
               05 CIST               PIC 9(004).
               05 PRG-SEGNALANTE     PIC 9(005).
               05 PRG-OPERATORE      PIC 9(006).
               05 TIPO-REC-UIC       PIC X(003).
               05 PRG-REG-CMP        PIC 9(003).
               05 COD-SEGNALANTE     PIC X(016).
               05 COD-OPERATORE      PIC X(016).
               05 COD-ABI            PIC 9(005).
               05 CAB                PIC 9(005).
               05 NUM-DICH           PIC 9(015) COMP-3.
               05 NUM-REG            PIC 9(015) COMP-3.
               05 TIPO-DICHIARA      PIC 9(002).
               05 STATO-DICHIARA     PIC X(002).
               05 FILLER             PIC X(017).

       01  W-COMUNE                    PIC X(025) VALUE SPACES.
       01  W-INDIRIZZO                 PIC X(035) VALUE SPACES.
       01  PARTE-CAP.
           05  W-CAP                   PIC X(005).
           05  RESTO-CAP               PIC X(020).

       01  W-COD-MECC.
           05  MECC-SEGNA.
               06  MECC-SEGNA-PR       PIC X(002).
               06  MECC-SEGNA-NUM      PIC X(006).

       01  WRK-NUMERO                  PIC 9(015).
       01  RWRK-NUMERO REDEFINES WRK-NUMERO.
           03  WRK-CPRECVS             PIC 9(01).
           03  WRK-NUMCVS              PIC 9(14).

       01  CAMPO-ISTITUTO              PIC 9999 VALUE 9999.
       01  WRK-CSEGNAL                 PIC X(16) VALUE SPACES.

CARA39     COPY ZMWCONFG.
           COPY DVWCG001.
           COPY DVWCGI01.
           COPY DVWCGT00.
           COPY DVWCGT01.
           COPY DVWCGT02.
           COPY DVWCGT03.
           COPY DVWCGT04.
           COPY DVWCGT05.
           COPY DVWCGT06.
           COPY DVWCGT08.
           COPY DVWCGT09.
           COPY DVWCG043.
      *    COPY ESSAD021.
BPOST      COPY ZMOAD021.

CARA39     EXEC SQL INCLUDE ZMGCONFG END-EXEC.
FAA        EXEC SQL INCLUDE ZMGDIV   END-EXEC.
           EXEC SQL INCLUDE ZMGNAPOS END-EXEC.
           EXEC SQL INCLUDE ZMGCVMER END-EXEC.
           EXEC SQL INCLUDE ZMGCVNME END-EXEC.
           EXEC SQL INCLUDE ZMGCVFIN END-EXEC.
           EXEC SQL INCLUDE ZMGCVCMP END-EXEC.
           EXEC SQL INCLUDE ZMGCVNRE END-EXEC.
           EXEC SQL INCLUDE ZMGCVREG END-EXEC.
           EXEC SQL INCLUDE ZMGCVCNS END-EXEC.
           EXEC SQL INCLUDE ZMGCVCMM END-EXEC.
           EXEC SQL INCLUDE ZMGCVRDT END-EXEC.
           EXEC SQL INCLUDE ZMGCVTCV END-EXEC.
           EXEC SQL INCLUDE ZMGLICMB END-EXEC.
           EXEC SQL INCLUDE ZMGBFA   END-EXEC.
           EXEC SQL INCLUDE SQLCA    END-EXEC.

CUR9       EXEC SQL INCLUDE ZMC41210 END-EXEC.
CUR10      EXEC SQL INCLUDE ZMC41310 END-EXEC.
CUR11      EXEC SQL INCLUDE ZMC40808 END-EXEC.

      *
       PROCEDURE DIVISION.
           INITIALIZE CAMPI-COMODO.
       OPEN-FILES.
           OPEN INPUT  ZMUN5442 ZMUN5443 ZMUN5444 ZMUN5445 ZMUN5446
                       ZMUN5447 ZMUN5448 ZMUN5440 ZMUN5441.
           OPEN OUTPUT ZMUN544A ZMUN544B ZMUN544C.

           MOVE 'NO' TO FINE-ACVMER
                        FINE-ACVCMP
                        FINE-ACVNRE
                        FINE-ACVREG
                        FINE-ACVMER2
                        FINE-ACVNME
                        FINE-ACVFIN.

           MOVE 9999 TO WA-CIST.

           PERFORM LEGGI-ZMUN5440 THRU FINE-ZMUN5440 VARYING WINDT
                   FROM 1 BY 1 UNTIL EOF-1022.

           PERFORM LEGGI-ZMUN5441 THRU FINE-ZMUN5441 VARYING WINDT
                   FROM 1 BY 1 UNTIL EOF-1023.

           MOVE 1 TO WINDC.
           INITIALIZE TABELLA-CAMBI.

           PERFORM TRATTA-ACVMER   THRU EX-TRATTA-ACVMER UNTIL
                   FINE-ACVMER = 'SI'.

           PERFORM TRATTA-ACVCMP   THRU EX-TRATTA-ACVCMP UNTIL
                   FINE-ACVCMP = 'SI'.

           PERFORM TRATTA-ACVNRE   THRU EX-TRATTA-ACVNRE UNTIL
                   FINE-ACVNRE = 'SI'.

           PERFORM TRATTA-ACVREG   THRU EX-TRATTA-ACVREG UNTIL
                   FINE-ACVREG = 'SI'.

           PERFORM TRATTA-ACVMER2  THRU EX-TRATTA-ACVMER2
                   UNTIL FINE-ACVMER2 = 'SI'.

           PERFORM TRATTA-ACVNME   THRU EX-TRATTA-ACVNME
                   UNTIL FINE-ACVNME = 'SI'.

           PERFORM TRATTA-ACVFIN   THRU EX-TRATTA-ACVFIN
                   UNTIL FINE-ACVFIN = 'SI'.

           PERFORM SCRIVI-FILE-DIVISE THRU EX-SCRIVI-FILE-DIVISE
                   VARYING WINDC FROM 1 BY 1 UNTIL WINDC = 500 OR
                           DIVISA OF CAMBI (WINDC) = SPACES.

           CLOSE   ZMUN5442 ZMUN5443 ZMUN5444 ZMUN5445 ZMUN5446
                   ZMUN5447 ZMUN5448 ZMUN5440 ZMUN5441
                   ZMUN544A ZMUN544B ZMUN544C.

           DISPLAY 'ZMPDC544 - CHIUDE BENE'.
           STOP RUN.

       LEGGI-ZMUN5440.

           READ ZMUN5440
               AT END
                  SET EOF-1022 TO TRUE
               NOT AT END
                  IF WINDT > 10
                     MOVE 1 TO COMP-CODE
                     DISPLAY 'AMPLIARE TABELLA ISTITUTI'
                     CALL ILBOABN0 USING COMP-CODE
                  END-IF
                  MOVE ISTITUTO OF ZMRK1022 TO EL-CIST(WINDT)
                  MOVE CODICE-ABI OF ZMRK1022 TO EL-ABI(WINDT)
                  MOVE MESE-RIF-CVS OF ZMRK1022 TO EL-RIFCVS(WINDT)
                  MOVE MESE-RIF-CVS OF ZMRK1022 TO DATA-X1
                  MOVE 01 TO DATA-X1(7:2)
                  MOVE DATA-X1 TO EL-DATA-DA(WINDT)
                  MOVE 31 TO DATA-X1(7:2)
                  MOVE DATA-X1 TO EL-DATA-A(WINDT)
           END-READ.

       FINE-ZMUN5440.

           EXIT.

       LEGGI-ZMUN5441.

           READ ZMUN5441
               AT END
                  SET EOF-1023 TO TRUE
               NOT AT END
                  MOVE CIST-K TO WCM-CIST
                  MOVE RAD-IST-K OF ZMRK1023 TO ZMOAD021
                  SET INDT TO 1
                  SEARCH ELEMENTO
                    AT END
                       MOVE 2 TO COMP-CODE
                       DISPLAY 'MANCA ZMUN5440 PER ' CIST-K
                       CALL ILBOABN0 USING COMP-CODE
                    WHEN WCM-CIST = EL-CIST(INDT)
                       MOVE DFNEMESO OF ZMOAD021 TO EL-DATARIF(INDT)
                       MOVE DOGG-K OF ZMRK1023   TO EL-DOGG(INDT)
                  END-SEARCH
           END-READ.

       FINE-ZMUN5441.

           EXIT.

       CERCA-SCHEDA.

           SET INDT TO 1.
           SEARCH ELEMENTO
              AT END
                 MOVE 3 TO COMP-CODE
                 DISPLAY 'MANCA SCHEDA ISTITUTO PER ' WCM-CIST
                 CALL ILBOABN0 USING COMP-CODE
              WHEN
                  EL-CIST(INDT) = WCM-CIST
                  MOVE EL-CIST(INDT) TO WA-CIST
                  MOVE 'SI' TO SW-CARICA-SEGNALANTE
CARA39            MOVE  EL-RIFCVS(INDT)   TO NASTRO-DEL
CARA39            MOVE  WA-CIST           TO CONFG-CIST
CARA39            PERFORM LEGGI-TBWCONFG THRU EX-LEGGI-TBWCONFG
CARA39            MOVE CONFG-ALTRIFLAG2  TO WCONFG-ALTRIFLAG2
CARA39            MOVE CONFG-DCVSEUR     TO WRK-DATA-EURO
TEST  *           DISPLAY' WRK-DATA-EURO   '   WRK-DATA-EURO
TEST  *           DISPLAY' NASTRO-DEL      '    NASTRO-DEL
CARA39            IF NASTRO-DEL(1:6) < WRK-DATA-EURO (1:6)
CARA39                MOVE 'N'       TO     WRK-CVS-EURO
CARA39            ELSE
CARA39                MOVE 'S'       TO     WRK-CVS-EURO
CARA39            END-IF
CARA39            IF  WRK-DATA-EURO = 0
CARA39                MOVE 'N'       TO     WRK-CVS-EURO
CARA39            END-IF
           END-SEARCH.

       FINE-CERCA.

           EXIT.
CARA39 LEGGI-TBWCONFG.
CARA39     EXEC SQL INCLUDE ZMS30901 END-EXEC.
CARA39
CARA39     IF SQLCODE NOT = ZERO
CARA39        MOVE 8 TO COMP-CODE
CARA39        DISPLAY 'ERRORE ZMS30901 '
CARA39        PERFORM ERRORE-DB2 THRU FINE-DB2
CARA39     END-IF.
CARA39 EX-LEGGI-TBWCONFG.
CARA39     EXIT.

       TRATTA-ACVMER.

           READ ZMUN5442 INTO DCLTBACVMER
              AT END
                 MOVE 'SI' TO FINE-ACVMER
              NOT AT END
                IF CVMER-CIST NOT = WA-CIST
                   MOVE CVMER-CIST TO WCM-CIST
                   PERFORM CERCA-SCHEDA THRU FINE-CERCA
                END-IF
CIST            MOVE CVMER-CIST    TO CVREG-CIST
                MOVE CVMER-CCABFIL TO CVREG-CCABFIL
                MOVE CVMER-CPRECVS TO CVREG-CPRECVS
                MOVE CVMER-NUMCVS  TO CVREG-NUMCVS

                PERFORM CERCA-ACVREG THRU EX-CERCA-ACVREG

                IF WRK-TROVATO = 'NO'
                   PERFORM CERCA-SENZAREG THRU EX-CERCA-SENZAREG
                   IF WRK-SENZAREG = 'SI'
                      PERFORM SCRIVI-T02-T01-T00 THRU
                           EX-SCRIVI-T02-T01-T00
                   ELSE
                      PERFORM CERCA-POSTICIP THRU EX-CERCA-POSTICIP
                      IF WRK-POSTICIP = 'SI'
                         PERFORM SCRIVI-T02-T01-T00 THRU
                              EX-SCRIVI-T02-T01-T00
                      END-IF
                   END-IF
                END-IF
           END-READ.

       EX-TRATTA-ACVMER.

           EXIT.

       TRATTA-ACVCMP.

           READ ZMUN5444 INTO DCLTBACVCMP
              AT END
                 MOVE 'SI' TO FINE-ACVCMP
              NOT AT END
                IF CVCMP-CIST NOT = WA-CIST
                   MOVE CVCMP-CIST TO WCM-CIST
                   PERFORM CERCA-SCHEDA THRU FINE-CERCA
                END-IF

CIST             MOVE CVCMP-CIST    TO CVREG-CIST
                 MOVE CVCMP-CCABFIL TO CVREG-CCABFIL
                 MOVE CVCMP-CPRECVS TO CVREG-CPRECVS
                 MOVE CVCMP-NUMCVS  TO CVREG-NUMCVS

                 PERFORM CERCA-ACVREG THRU EX-CERCA-ACVREG

                 IF WRK-TROVATO = 'NO'
                   PERFORM SCRIVI-T05-T01-T00 THRU EX-SCRIVI-T05-T01-T00
                 END-IF
           END-READ.

       EX-TRATTA-ACVCMP.

           EXIT.

       TRATTA-ACVNRE.

           READ ZMUN5445 INTO DCLTBACVNRE
              AT END
                 MOVE 'SI' TO FINE-ACVNRE
              NOT AT END
                IF CVNRE-CIST NOT = WA-CIST
                   MOVE CVNRE-CIST TO WCM-CIST
                   PERFORM CERCA-SCHEDA THRU FINE-CERCA
                END-IF
                PERFORM SCRIVI-T08 THRU EX-SCRIVI-T08
           END-READ.

       EX-TRATTA-ACVNRE.

           EXIT.

       TRATTA-ACVREG.

           READ ZMUN5446 INTO DCLTBACVREG
              AT END
                 MOVE 'SI' TO FINE-ACVREG
              NOT AT END
                 IF CVREG-CIST NOT = WA-CIST
                    MOVE CVREG-CIST TO WCM-CIST
                    PERFORM CERCA-SCHEDA THRU FINE-CERCA
                 END-IF
                 MOVE 'NO' TO WRK-TROVATO
                 PERFORM CERCA-ACVTCV THRU EX-CERCA-ACVTCV
                 EVALUATE CVTCV-CTIPDICH
                 WHEN 1
                    PERFORM CERCA-ACVMER THRU EX-CERCA-ACVMER
                    IF WRK-TROVATO = 'SI'
                       PERFORM SCRIVI-T02-T06-T01-T00 THRU
                            EX-SCRIVI-T02-T06-T01-T00
                    END-IF
                 WHEN 2
                    PERFORM CERCA-ACVNME THRU EX-CERCA-ACVNME
                    IF WRK-TROVATO = 'SI'
                       PERFORM SCRIVI-T03-T06-T01-T00 THRU
                            EX-SCRIVI-T03-T06-T01-T00
                    END-IF
                 WHEN 3
                    PERFORM CERCA-ACVFIN THRU EX-CERCA-ACVFIN
                    IF WRK-TROVATO = 'SI'
                       PERFORM SCRIVI-T04-T06-T01-T00 THRU
                            EX-SCRIVI-T04-T06-T01-T00
                       MOVE CVREG-NUMREG  TO CVRDT-NUMREG
CIST                   MOVE CVREG-CIST    TO CVRDT-CIST
                       PERFORM CERCA-ACVRDT   THRU EX-CERCA-ACVRDT
                    END-IF
                 WHEN 4
                    PERFORM CERCA-ACVCMP THRU EX-CERCA-ACVCMP
                    IF WRK-TROVATO = 'SI'
                       PERFORM SCRIVI-T05-T06-T01-T00 THRU
                            EX-SCRIVI-T05-T06-T01-T00
                    END-IF
                 END-EVALUATE
           END-READ.

       EX-TRATTA-ACVREG.

           EXIT.

       TRATTA-ACVMER2.

           READ ZMUN5443 INTO DCLTBACVMER
              AT END
                 MOVE 'SI' TO FINE-ACVMER2
              NOT AT END
                IF CVMER-CIST NOT = WA-CIST
                   MOVE CVMER-CIST TO WCM-CIST
                   PERFORM CERCA-SCHEDA THRU FINE-CERCA
                END-IF
                PERFORM CERCA-SENZAREG THRU EX-CERCA-SENZAREG
                IF WRK-SENZAREG = 'NO'
                  PERFORM SCRIVI-T02-T01-T00 THRU EX-SCRIVI-T02-T01-T00
                END-IF
           END-READ.

       EX-TRATTA-ACVMER2.

           EXIT.

       TRATTA-ACVNME.

           READ ZMUN5447 INTO DCLTBACVNME
              AT END
                 MOVE 'SI' TO FINE-ACVNME
              NOT AT END
                 IF CVNME-CIST NOT = WA-CIST
                    MOVE CVNME-CIST TO WCM-CIST
                    PERFORM CERCA-SCHEDA THRU FINE-CERCA
                 END-IF
                PERFORM SCRIVI-T03-T01-T00 THRU EX-SCRIVI-T03-T01-T00
           END-READ.

       EX-TRATTA-ACVNME.

           EXIT.

       TRATTA-ACVFIN.

           READ ZMUN5448 INTO DCLTBACVFIN
              AT END
                 MOVE 'SI' TO FINE-ACVFIN
              NOT AT END
                 IF CVFIN-CIST NOT = WA-CIST
                    MOVE CVFIN-CIST TO WCM-CIST
                    PERFORM CERCA-SCHEDA THRU FINE-CERCA
                 END-IF
                PERFORM SCRIVI-T04-T01-T00 THRU EX-SCRIVI-T04-T01-T00
           END-READ.

       EX-TRATTA-ACVFIN.

           EXIT.

       CERCA-ACVREG.

           MOVE 'NO' TO WRK-TROVATO.
           EXEC SQL INCLUDE ZMLOPE11 END-EXEC.

           IF SQLCODE NOT = ZERO
              MOVE 4 TO COMP-CODE
              DISPLAY 'ERRORE OPEN CURS11 ACVREG'
              PERFORM ERRORE-DB2 THRU FINE-DB2.

           MOVE 'NO' TO SW-FINE1.

           PERFORM FETCH-ACVREG-MER  THRU FETCH-ACVREG-MER-END
                   UNTIL SW-FINE1 = 'SI'.

           EXEC SQL INCLUDE ZMLCLO11 END-EXEC.

           IF SQLCODE NOT = ZERO
              MOVE 5 TO COMP-CODE
              DISPLAY 'ERRORE CLOSE CURS11 ACVREG'
              PERFORM ERRORE-DB2 THRU FINE-DB2.

       EX-CERCA-ACVREG.

           EXIT.

       FETCH-ACVREG-MER.

           EXEC SQL INCLUDE ZMF40808 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 6 TO COMP-CODE
              DISPLAY 'ERRORE FETCH CURS11 ACVREG'
              PERFORM ERRORE-DB2 THRU FINE-DB2
           ELSE
              IF SQLCODE = +100
                 MOVE 'SI' TO SW-FINE1
              ELSE
                 MOVE CVREG-DVALNOA TO DATA-X1
                 MOVE EL-RIFCVS(INDT) TO DATA-Y1
                 IF DATA-X1(1:6)  = DATA-Y1(1:6)
                    MOVE 'SI' TO WRK-TROVATO
                 END-IF
              END-IF
           END-IF.

       FETCH-ACVREG-MER-END.

           EXIT.

       CERCA-SENZAREG.

           MOVE 'NO' TO WRK-SENZAREG.

           IF (CVMER-IVALCVS = CVMER-ISENZAREG) OR
              (CVMER-ICTVCVS = CVMER-ICTVSENZAR)
              MOVE 'SI' TO WRK-SENZAREG
           END-IF.

       EX-CERCA-SENZAREG.

           EXIT.

       CERCA-POSTICIP.

           MOVE 'NO' TO WRK-POSTICIP.

           IF CVMER-DPRIRATA = ZEROES
              NEXT SENTENCE
           ELSE
              MOVE CVMER-DPRIRATA TO D-INP-N
              MOVE CVMER-DSDOG    TO D-OUT-N
              MOVE 2 TO SW-DATA
              PERFORM DVWCI043 THRU EX-DVWCI043

              IF DATAMESS NOT = SPACES
                 MOVE 7 TO COMP-CODE
                 DISPLAY 'ERRORE DATA '
                 DISPLAY 'CVMER-CCABFIL  ' CVMER-CCABFIL
                 DISPLAY 'CVMER-CPRECVS  ' CVMER-CPRECVS
                 DISPLAY 'CVMER-NUMCVS   ' CVMER-NUMCVS
                 DISPLAY 'CVMER-DPRIRATA ' CVMER-DPRIRATA
                 DISPLAY 'CVMER-DSDOG    ' CVMER-DSDOG
                 CALL ILBOABN0 USING COMP-CODE
              ELSE
                IF GIO-CALC NOT < 60
                    MOVE 'SI' TO WRK-POSTICIP
                 END-IF
              END-IF
           END-IF.

       EX-CERCA-POSTICIP.

           EXIT.

       CERCA-ACVTCV.

           MOVE CVREG-CIST       TO CVTCV-CIST.
           MOVE CVREG-CCAB       TO CVTCV-CCAB.
           MOVE CVREG-CCABFIL    TO CVTCV-CCABFIL.
           MOVE CVREG-CPRECVS    TO CVTCV-CPRECVS.
           MOVE CVREG-NUMCVS     TO CVTCV-NUMCVS.

           EXEC SQL INCLUDE ZMS41701 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 8 TO COMP-CODE
              DISPLAY 'ERRORE ZMS41701 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           END-IF.

       EX-CERCA-ACVTCV.

           EXIT.

       CERCA-ACVMER.

           MOVE CVTCV-CIST       TO CVMER-CIST.
           MOVE CVTCV-CCAB       TO CVMER-CCAB.
           MOVE CVTCV-CCABFIL    TO CVMER-CCABFIL.
           MOVE CVTCV-CPRECVS    TO CVMER-CPRECVS.
           MOVE CVTCV-NUMCVS     TO CVMER-NUMCVS.

           EXEC SQL INCLUDE ZMS40101 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 9 TO COMP-CODE
              DISPLAY 'ERRORE ZMS40101 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           ELSE

CAR891*----NON CONSIDERA LO STATO AN PERCHE' PER ANNULLARE UNA CVS E'
CAR891*----NECESSARIO ANNULLARE PRIMA IL REGOLAMENTO
CAR891
CAR891        IF CVMER-CSTADICH NOT = 'AS'
CAR891           MOVE 'SI' TO WRK-TROVATO
CAR891        END-IF
           END-IF.

       EX-CERCA-ACVMER.

           EXIT.

       CERCA-ACVNME.

           MOVE CVTCV-CIST       TO CVNME-CIST.
           MOVE CVTCV-CCAB       TO CVNME-CCAB.
           MOVE CVTCV-CCABFIL    TO CVNME-CCABFIL.
           MOVE CVTCV-CPRECVS    TO CVNME-CPRECVS.
           MOVE CVTCV-NUMCVS     TO CVNME-NUMCVS.

           EXEC SQL INCLUDE ZMS40201 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 10 TO COMP-CODE
              DISPLAY 'ERRORE ZMS40201 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           ELSE

CAR891*----NON CONSIDERA LO STATO AN PERCHE' PER ANNULLARE UNA CVS E'
CAR891*----NECESSARIO ANNULLARE PRIMA IL REGOLAMENTO
CAR891
CAR891        IF CVNME-CSTADICH NOT = 'AS'
CAR891           MOVE 'SI' TO WRK-TROVATO
CAR891        END-IF
           END-IF.

       EX-CERCA-ACVNME.

           EXIT.

       CERCA-ACVFIN.

           MOVE CVTCV-CIST       TO CVFIN-CIST.
           MOVE CVTCV-CCAB       TO CVFIN-CCAB.
           MOVE CVTCV-CCABFIL    TO CVFIN-CCABFIL.
           MOVE CVTCV-CPRECVS    TO CVFIN-CPRECVS.
           MOVE CVTCV-NUMCVS     TO CVFIN-NUMCVS.

           EXEC SQL INCLUDE ZMS40301 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 11 TO COMP-CODE
              DISPLAY 'ERRORE ZMS40201 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           ELSE

CAR891*----NON CONSIDERA LO STATO AN PERCHE' PER ANNULLARE UNA CVS E'
CAR891*----NECESSARIO ANNULLARE PRIMA IL REGOLAMENTO
CAR891
CAR891        IF CVFIN-CSTADICH NOT = 'AS'
CAR891           MOVE 'SI' TO WRK-TROVATO
CAR891        END-IF
           END-IF.

       EX-CERCA-ACVFIN.

           EXIT.

       CERCA-ACVCMP.

           MOVE CVTCV-CIST       TO CVCMP-CIST.
           MOVE CVTCV-CCAB       TO CVCMP-CCAB.
           MOVE CVTCV-CCABFIL    TO CVCMP-CCABFIL.
           MOVE CVTCV-CPRECVS    TO CVCMP-CPRECVS.
           MOVE CVTCV-NUMCVS     TO CVCMP-NUMCVS.

           EXEC SQL INCLUDE ZMS40401 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 12 TO COMP-CODE
              DISPLAY 'ERRORE ZMS40401 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           ELSE
CAR873*       DISPLAY 'DCOMP PRIMA ' CVCMP-DCOMPENS
CAR873        MOVE CVCMP-DCOMPENS TO WRK-DCOMPENS
CAR873        IF SS OF RWRK-DCOMPENS > 12
CAR873           MOVE CORR RWRK-DCOMPENS TO RWRK-DCOMPENS1
CAR873           MOVE WRK-DCOMPENS1      TO CVCMP-DCOMPENS
CAR873        END-IF
CAR873*       DISPLAY 'DCOMP DOPO  ' CVCMP-DCOMPENS
              IF CVCMP-DCOMPENS < EL-DATA-DA(INDT) AND
                 CVCMP-DCOMPENS > EL-DATA-A(INDT)
                 MOVE 'NO' TO WRK-TROVATO
              ELSE
                 MOVE 'SI' TO WRK-TROVATO
              END-IF
           END-IF.

       EX-CERCA-ACVCMP.

           EXIT.

       CERCA-ACVRDT.

           MOVE 'NO' TO WRK-TROVATO.

           EXEC SQL INCLUDE ZMLOPE10 END-EXEC.

           IF SQLCODE NOT = ZERO
              MOVE 13 TO COMP-CODE
              DISPLAY 'ERRORE OPEN CURS10 ACVRDT'
              PERFORM ERRORE-DB2 THRU FINE-DB2.

           MOVE ZEROES    TO INDICE.

           MOVE 'NO' TO SW-FINE3.

           PERFORM FETCH-ACVRDT THRU FETCH-ACVRDT-END
                   UNTIL SW-FINE3 = 'SI'.

           EXEC SQL INCLUDE ZMLCLO10 END-EXEC.

           IF SQLCODE NOT = ZERO
              MOVE 14 TO COMP-CODE
              DISPLAY 'ERRORE CLOSE CURS10 ACVRDT'
              PERFORM ERRORE-DB2 THRU FINE-DB2.

       EX-CERCA-ACVRDT.

           EXIT.

       SELECT-ANAPOS.
           MOVE ZERO TO SQLCODE
           PERFORM CHIAMA-ANAGRAFE
              THRU CHIAMA-ANAGRAFE-END

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 15 TO COMP-CODE
              DISPLAY 'ERRORE ZMS10801 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           END-IF.

       SELECT-ANAPOS-END.

           EXIT.

       SELECT-ACVCNS.

           EXEC SQL INCLUDE ZMS41101 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 16 TO COMP-CODE
              DISPLAY 'ERRORE ZMS41101 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           END-IF.

       SELECT-ACVCNS-END.

           EXIT.

       FETCH-ACVCMM.

           EXEC SQL INCLUDE ZMF41208 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 17 TO COMP-CODE
              DISPLAY 'ERRORE ZMS41208 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           ELSE
             IF SQLCODE = +100
                MOVE 'SI' TO SW-FINE2
             ELSE
                ADD 1 TO INDICE
                PERFORM SCRIVI-T05-CMM THRU EX-SCRIVI-T05-CMM
             END-IF
           END-IF.

       FETCH-ACVCMM-END.

           EXIT.

       FETCH-ACVRDT.

           EXEC SQL INCLUDE ZMF41308 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 18 TO COMP-CODE
              DISPLAY 'ERRORE ZMS41208 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           ELSE
             IF SQLCODE = +100
                MOVE 'SI' TO SW-FINE3
             ELSE
                ADD 1 TO INDICE
                PERFORM SCRIVI-T09 THRU EX-SCRIVI-T09
             END-IF
           END-IF.

       FETCH-ACVRDT-END.

           EXIT.

      *--------------------------------------------------------------*
      *              CARICA DATI DEL T02  (MERCANTILE)               *
      *                     DATI DEL T01    (OPERATORE)              *
      *                     DATI DEL T00    (SEGNALANTE)             *
      *--------------------------------------------------------------*

       SCRIVI-T02-T01-T00.

           INITIALIZE COM-KEY2.

VAR004     MOVE EL-RIFCVS(INDT) TO DATA-CHR.
VAR004     MOVE CVMER-DSDOG TO DATA-CH.

VAR004     IF DATA-CH(1:6) = DATA-CHR(1:6) AND
VAR004        CVMER-CSEGNAL = SPACES
VAR004        GO TO EX-SCRIVI-T02-T01-T00.

           MOVE 'T02'                TO TIPO-REC-UIC  OF COM-KEY2.

           MOVE CVMER-CIST           TO CIST           OF COM-KEY2
           MOVE CVMER-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
           MOVE CVMER-NNDGSET        TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVMER-NUMCVS         TO NUM-DICH       OF COM-KEY2
           MOVE CVMER-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVMER-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVMER-CCABFIL        TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI OF ZMRK1022  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2.

           MOVE COM-KEY2             TO AREA-KEY2.
           INITIALIZE TRK-T02.
           PERFORM PREPARA-T02 THRU EX-PREPARA-T02.
           MOVE TRK-T02              TO AREA-UIC2.
           WRITE ZMRK1021.

           MOVE 'T01'                TO TIPO-REC-UIC  OF COM-KEY2.
           INITIALIZE TRK-T01.

           MOVE CIST             OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST             OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-OPERATORE    OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-OPERATORE    OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS     THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO LBL-T00-T02.

           PERFORM SELECT-ACVCNS     THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO LBL-T00-T02.

           INITIALIZE CODICE-XXX.
           MOVE CVMER-CCAB  TO  WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CODICE-ABI       OF TRK-T01

           INITIALIZE CODICE-XXX.
           MOVE CVMER-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CAB              OF TRK-T01.

           MOVE CVMER-NUMCVS      TO   WA-NUMCVS.
           MOVE WA-NUMCVS         TO   NUM-RIF-INTERNO     OF TRK-T01.
           MOVE EL-RIFCVS(INDT)   TO   DATA-SEGNALAZIONE   OF TRK-T01.

           IF CVMER-CSTADICH = 'AS'
              MOVE '1'            TO   COM-ANN-RIPR        OF TRK-T01
           ELSE
              IF CVMER-CSTADICH  = 'RA'
                 MOVE '2'         TO   COM-ANN-RIPR        OF TRK-T01
              ELSE
                 MOVE '0'         TO   COM-ANN-RIPR        OF TRK-T01.

           MOVE COM-KEY2      TO AREA-KEY2.
           PERFORM PREPARA-T01    THRU EX-PREPARA-T01.
           MOVE TRK-T01       TO AREA-UIC2.
           WRITE ZMRK1021.

       LBL-T00-T02.

           MOVE 'T00'                TO TIPO-REC-UIC  OF COM-KEY2.
           INITIALIZE TRK-T00.

           IF COD-SEGNALANTE OF COM-KEY2 = SPACES
              GO TO EX-SCRIVI-T02-T01-T00.

           MOVE CIST           OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST           OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO EX-SCRIVI-T02-T01-T00.

           PERFORM SELECT-ACVCNS THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO EX-SCRIVI-T02-T01-T00.


           MOVE COM-KEY2 TO AREA-KEY2.
           PERFORM PREPARA-T00 THRU EX-PREPARA-T00.
           MOVE TRK-T00 TO AREA-UIC2.
           WRITE ZMRK1021.

       EX-SCRIVI-T02-T01-T00.

           EXIT.

      *----------------------------------------------------------------*
      *              CARICA DATI DEL T05    (COMPENSAZIONE)            *
      *                     DATI DEL T01    (OPERATORE)                *
      *                     DATI DEL T00    (SEGNALANTE)               *
      *----------------------------------------------------------------*

       SCRIVI-T05-T01-T00.

           INITIALIZE COM-KEY2.
           MOVE 'T05' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVCMP-CIST           TO CIST           OF COM-KEY2
           MOVE CVCMP-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
           MOVE CVCMP-NNDGSET        TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVCMP-NUMCVS         TO NUM-DICH       OF COM-KEY2
           MOVE CVCMP-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVCMP-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVCMP-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI OF ZMRK1022 TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2

           INITIALIZE TRK-T05.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T05.
           MOVE 'T05'             TO TIPO-RECORD             OF TRK-T05.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T00  OF TRK-T05.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T01  OF TRK-T05.
           MOVE 'S'               TO RIGA-OPERAZIONE         OF TRK-T05.
           MOVE ZERO              TO DATA-CONTRATTO          OF TRK-T05.
           MOVE CVCMP-DCOMPENS    TO DATA-X1.
           MOVE DATA-X1(1:6)      TO DATA-COMPENSAZIONE      OF TRK-T05.
VAR001*    MOVE CVCMP-FLITEU      TO LIRA-EURO               OF TRK-T05.
CARA39*    MOVE 'V'               TO LIRA-EURO               OF TRK-T05.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'            TO LIRA-EURO             OF TRK-T05
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'            TO LIRA-EURO             OF TRK-T05
CARA39     END-IF

           MOVE 1 TO INDICE.

CAR860     IF CVCMP-ICOMP1C NOT = 0
CARA39        IF WRK-CVS-EURO = 'S'
CARA39           IF CVCMP-FLITEU = 'V'
CARA39              COMPUTE CVCMP-ICOMP1C ROUNDED = CVCMP-ICOMP1C
CARA39                                      * 1000000 / 1936,27
CARA39           END-IF
CARA39        END-IF
CARA39        IF WRK-CVS-EURO = 'N'
CARA39           IF CVCMP-FLITEU = 'E'
CARA39              COMPUTE CVCMP-ICOMP1C ROUNDED = CVCMP-ICOMP1C
CARA39                                      * 1936,27 / 1000000
CARA39              IF CVCMP-ICOMP1C < 1
CARA39                 MOVE 1 TO CVCMP-ICOMP1C
CARA39              END-IF
CARA39           END-IF
CARA39        END-IF
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 1              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'C'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP1C  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP1D NOT = 0
CARA39        IF WRK-CVS-EURO = 'S'
CARA39           IF CVCMP-FLITEU = 'V'
CARA39              COMPUTE CVCMP-ICOMP1D ROUNDED = CVCMP-ICOMP1D
CARA39                                      * 1000000 / 1936,27
CARA39           END-IF
CARA39        END-IF
CARA39        IF WRK-CVS-EURO = 'N'
CARA39           IF CVCMP-FLITEU = 'E'
CARA39              COMPUTE CVCMP-ICOMP1D ROUNDED = CVCMP-ICOMP1D
CARA39                                     * 1936,27 / 1000000
CARA39              IF CVCMP-ICOMP1D < 1
CARA39                 MOVE 1 TO CVCMP-ICOMP1D
CARA39              END-IF
CARA39           END-IF
CARA39        END-IF
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 1              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'D'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP1D  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP2C NOT = 0
CARA39        IF WRK-CVS-EURO = 'S'
CARA39           IF CVCMP-FLITEU = 'V'
CARA39              COMPUTE CVCMP-ICOMP2C ROUNDED = CVCMP-ICOMP2C
CARA39                                      * 1000000 / 1936,27
CARA39           END-IF
CARA39        END-IF
CARA39        IF WRK-CVS-EURO = 'N'
CARA39           IF CVCMP-FLITEU = 'E'
CARA39              COMPUTE CVCMP-ICOMP2C ROUNDED = CVCMP-ICOMP2C
CARA39                                      * 1936,27 / 1000000
CARA39              IF CVCMP-ICOMP2C < 1
CARA39                 MOVE 1 TO CVCMP-ICOMP2C
CARA39              END-IF
CARA39           END-IF
CARA39        END-IF
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 2              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'C'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP2C  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP2D NOT = 0
CARA39        IF WRK-CVS-EURO = 'S'
CARA39           IF CVCMP-FLITEU = 'V'
CARA39              COMPUTE CVCMP-ICOMP2D ROUNDED = CVCMP-ICOMP2D
CARA39                                      * 1000000 / 1936,27
CARA39           END-IF
CARA39        END-IF
CARA39        IF WRK-CVS-EURO = 'N'
CARA39           IF CVCMP-FLITEU = 'E'
CARA39              COMPUTE CVCMP-ICOMP2D ROUNDED = CVCMP-ICOMP2D
CARA39                                      * 1936,27 / 1000000
CARA39              IF CVCMP-ICOMP2D < 1
CARA39                 MOVE 1 TO CVCMP-ICOMP2D
CARA39              END-IF
CARA39           END-IF
CARA39        END-IF
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 2              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'D'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP2D  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP3C NOT = 0
CARA39        IF WRK-CVS-EURO = 'S'
CARA39           IF CVCMP-FLITEU = 'V'
CARA39              COMPUTE CVCMP-ICOMP3C ROUNDED = CVCMP-ICOMP3C
CARA39                                      * 1000000 / 1936,27
CARA39           END-IF
CARA39        END-IF
CARA39        IF WRK-CVS-EURO = 'N'
CARA39           IF CVCMP-FLITEU = 'E'
CARA39              COMPUTE CVCMP-ICOMP3C ROUNDED = CVCMP-ICOMP3C
CARA39                                      * 1936,27 / 1000000
CARA39              IF CVCMP-ICOMP3C < 1
CARA39                 MOVE 1 TO CVCMP-ICOMP3C
CARA39              END-IF
CARA39           END-IF
CARA39        END-IF
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 3              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'C'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP3C  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP3D NOT = 0
CARA39        IF WRK-CVS-EURO = 'S'
CARA39           IF CVCMP-FLITEU = 'V'
CARA39              COMPUTE CVCMP-ICOMP3D ROUNDED = CVCMP-ICOMP3D
CARA39                                      * 1000000 / 1936,27
CARA39           END-IF
CARA39        END-IF
CARA39        IF WRK-CVS-EURO = 'N'
CARA39           IF CVCMP-FLITEU = 'E'
CARA39              COMPUTE CVCMP-ICOMP3D ROUNDED = CVCMP-ICOMP3D
CARA39                                      * 1936,27 / 1000000
CARA39              IF CVCMP-ICOMP3D      < 1
CARA39                 MOVE 1 TO CVCMP-ICOMP3D
CARA39              END-IF
CARA39           END-IF
CARA39        END-IF
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 3              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'D'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP3D  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

           MOVE 'NO' TO WRK-TROVATO.
           MOVE CVCMP-CCABFIL TO CVCMM-CCABFIL
           MOVE CVCMP-CPRECVS TO CVCMM-CPRECVS
           MOVE CVCMP-NUMCVS  TO CVCMM-NUMCVS
CIST       MOVE CVCMP-CIST    TO CVCMM-CIST

           EXEC SQL INCLUDE ZMLOPE09 END-EXEC.

           IF SQLCODE NOT = ZERO
              MOVE 19 TO COMP-CODE
              DISPLAY 'ERRORE OPEN CURS09 ACVCMP'
              PERFORM ERRORE-DB2 THRU FINE-DB2.

           MOVE ZEROES    TO INDICE.
           MOVE 'NO' TO SW-FINE2.

           PERFORM FETCH-ACVCMM THRU FETCH-ACVCMM-END
                   UNTIL SW-FINE2 = 'SI'.

           EXEC SQL INCLUDE ZMLCLO09 END-EXEC.

           IF SQLCODE NOT = ZERO
              MOVE 20 TO COMP-CODE
              DISPLAY 'ERRORE CLOSE CURS09 ACVCMP'
              PERFORM ERRORE-DB2 THRU FINE-DB2.

           INITIALIZE TRK-T01.
           MOVE 'T01' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CIST             OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST             OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-OPERATORE    OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-OPERATORE    OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS     THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSC THRU EX-ERRORE-NDG-CVSC
              GO TO LBL-T00-T05.

           PERFORM SELECT-ACVCNS     THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSC THRU EX-ERRORE-NDG-CVSC
              GO TO LBL-T00-T05.

           INITIALIZE CODICE-XXX.
           MOVE CVCMP-CCAB  TO  WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CODICE-ABI       OF TRK-T01

           INITIALIZE CODICE-XXX.
           MOVE CVCMP-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CAB              OF TRK-T01.

           MOVE CVCMP-NUMCVS      TO   WA-NUMCVS.
           MOVE WA-NUMCVS         TO   NUM-RIF-INTERNO     OF TRK-T01.
           MOVE EL-RIFCVS(INDT)   TO   DATA-SEGNALAZIONE   OF TRK-T01.
           MOVE '0'               TO   COM-ANN-RIPR        OF TRK-T01.

           MOVE COM-KEY2      TO AREA-KEY2.
           PERFORM PREPARA-T01    THRU EX-PREPARA-T01.
           MOVE TRK-T01       TO AREA-UIC2.
           WRITE ZMRK1021.

       LBL-T00-T05.

           INITIALIZE TRK-T00.
           MOVE 'T00' TO TIPO-REC-UIC OF COM-KEY2.

           IF COD-SEGNALANTE OF COM-KEY2 = SPACES
              GO TO EX-SCRIVI-T05-T01-T00.

           MOVE CIST           OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST           OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSC THRU EX-ERRORE-NDG-CVSC
              GO TO EX-SCRIVI-T05-T01-T00.

           PERFORM SELECT-ACVCNS THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO EX-SCRIVI-T05-T01-T00.

           MOVE COM-KEY2 TO AREA-KEY2.
           PERFORM PREPARA-T00 THRU EX-PREPARA-T00.
           MOVE TRK-T00 TO AREA-UIC2.
           WRITE ZMRK1021.

       EX-SCRIVI-T05-T01-T00.

           EXIT.

       SCRIVI-T05-CMM.

           INITIALIZE TRK-T05.
           MOVE 'T05' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T05.
           MOVE 'T05'             TO TIPO-RECORD             OF TRK-T05.
           MOVE INDICE            TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05.
           MOVE CVCMM-CNATOPE     TO NATURA-OPERAZIONE       OF TRK-T05.
           MOVE 'A'               TO RIGA-OPERAZIONE         OF TRK-T05.
           MOVE CVCMM-CCAUIC      TO CODICE-CAUSALE          OF TRK-T05.
           MOVE ZERO              TO DATA-CONTRATTO          OF TRK-T05.
CAR860*    MOVE CVCMP-DCOMPENS    TO DATA-X1.
CAR860     MOVE CVCMM-DORIGINE    TO DATA-X1.
           MOVE DATA-X1(1:6)      TO DATA-COMPENSAZIONE      OF TRK-T05.
           MOVE CVCMM-CPAEDCUIC   TO CODICE-PAESE-DEB-CRED   OF TRK-T05.

           MOVE CVCMM-CTIPODC     TO DEBITORE-CREDITORE      OF TRK-T05.
           MOVE CVCMM-CVALUIC     TO CODICE-VALUTA           OF TRK-T05.
           MOVE CVCMM-ICOMPENS    TO IMPORTO-VALUTA          OF TRK-T05.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVCMP-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVCMM-ICTVCOMP * 1000000
CARA39                                      / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVCMM-ICTVCOMP
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        IF CVCMP-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVCMM-ICTVCOMP * 1936,27
CARA39                                      / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVCMM-ICTVCOMP
CARA39           IF CVCMM-ICTVCOMP     < 1
CARA39              MOVE 1 TO CVCMM-ICTVCOMP
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVCMM-ICTVCOMP    TO IMPORTO-LIRE            OF TRK-T05.

VAR002     IF CODICE-VALUTA OF TRK-T05 = 018 OR = 242
              MOVE ZERO TO IMPORTO-LIRE OF TRK-T05.

           MOVE CVCMM-CPROV       TO PROVINCIA               OF TRK-T05.
VAR001*    MOVE CVCMP-FLITEU      TO LIRA-EURO               OF TRK-T05.
CARA39*    MOVE 'V'               TO LIRA-EURO               OF TRK-T05.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'            TO LIRA-EURO             OF TRK-T05
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'            TO LIRA-EURO             OF TRK-T05
CARA39     END-IF

           MOVE COM-KEY2       TO AREA-KEY2.
           MOVE TRK-T05        TO AREA-UIC2.

           WRITE ZMRK1021.

       EX-SCRIVI-T05-CMM.

           EXIT.

      *------------------------------------------------------------*
      *              CARICA DATI DEL T08    (REGOLAMENTI NR)       *
      *------------------------------------------------------------*

       SCRIVI-T08.

           INITIALIZE COM-KEY2.
           MOVE 'T08' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVNRE-CIST           TO CIST           OF COM-KEY2
BAPV  *    MOVE CVNRE-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
BAPV       MOVE SPACES               TO COD-SEGNALANTE OF COM-KEY2.

           IF COD-SEGNALANTE OF COM-KEY2 = ALL '0'
              MOVE SPACES TO COD-SEGNALANTE OF COM-KEY2.

           MOVE SPACES               TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVNRE-NUMREG         TO NUM-REG        OF COM-KEY2
           MOVE CVNRE-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVNRE-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVNRE-CCABFIL        TO WA-CAB.
           MOVE CVNRE-CCABFIL        TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI           OF ZMRK1022       TO WA-CAB.
           MOVE CODICE-ABI           OF ZMRK1022       TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2

           INITIALIZE TRK-T08.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T08.
           MOVE 'T08'             TO TIPO-RECORD             OF TRK-T08.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T00  OF TRK-T08.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T01  OF TRK-T08.
           MOVE '000'             TO FILLER1-TRKT08          OF TRK-T08.
           MOVE ' '               TO TIPO-SEGNALAZIONE       OF TRK-T08.
VAR001*    MOVE CVNRE-FLITEU      TO LIRA-VECCHIA-NUOVA      OF TRK-T08.
CARA39*    MOVE 'V'               TO LIRA-VECCHIA-NUOVA      OF TRK-T08.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'            TO LIRA-VECCHIA-NUOVA      OF TRK-T08
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'            TO LIRA-VECCHIA-NUOVA      OF TRK-T08
CARA39     END-IF
           MOVE CVNRE-DVALNOA     TO DATA-X1
           MOVE DATA-X1(1:6)      TO DATA-REGOLAMENTO        OF TRK-T08.
           MOVE CVNRE-NUMREG      TO WA-NUMREG.
           MOVE WA-NUMREG         TO RIFERIMENTO-INTERNO     OF TRK-T08.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI    OF ZMRK1022 TO  WA-CAB.
           MOVE CODICE-ABI    OF ZMRK1022 TO  CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE TO CONTRO5 OF CODICE-XXX.
           MOVE CODICE-XXX  TO CODICE-ABI  OF TRK-T08.

           INITIALIZE CODICE-XXX.
           MOVE CVNRE-CCABFIL            TO WA-CAB.
           MOVE CVNRE-CCABFIL            TO CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE TO CONTRO5 OF CODICE-XXX.
           MOVE CODICE-XXX  TO CAB         OF TRK-T08.

           MOVE ZERO                 TO DATA-CONTRATTO      OF TRK-T08.
           MOVE ZERO                 TO TIPO-CONTROPARTE    OF TRK-T08.
           MOVE CVNRE-CTIPCONTR   TO SETTORE-CONTROPARTE    OF TRK-T08.
           MOVE CVNRE-CPAECTPUIC  TO COD-PAESE-CTP          OF TRK-T08.
           MOVE CVNRE-FPAGINC     TO INCASSO-PAGAMENTO      OF TRK-T08.
           MOVE ZERO              TO COD-TIPO-OP            OF TRK-T08.
           MOVE CVNRE-CVALUIC     TO CODICE-VALUTA          OF TRK-T08.
           MOVE CVNRE-IVALCVS     TO IMPORTO-COMPLESSIVO    OF TRK-T08.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVNRE-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVNRE-ICTVCVS * 1000000
CARA39                                   / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVNRE-ICTVCVS
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        IF CVNRE-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVNRE-ICTVCVS * 1936,27
CARA39                                   / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVNRE-ICTVCVS
CARA39           IF CVNRE-ICTVCVS      < 1
CARA39              MOVE 1 TO CVNRE-ICTVCVS
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVNRE-ICTVCVS     TO CTV-COMPLESSIVO        OF TRK-T08.

VAR002     IF CODICE-VALUTA OF TRK-T08 = 018 OR = 242
              MOVE ZERO TO CTV-COMPLESSIVO OF TRK-T08.

CARA39     IF WRK-CVS-EURO = 'N'
           IF CVNRE-CISO NOT = 'ITL'
              IF CVNRE-ICTVCVS NOT = 0 THEN
                 COMPUTE COMODO-CAMBIO = (CVNRE-ICTVCVS
                             * 1000000) / CVNRE-IVALCVS
                 MOVE CVNRE-CIST          TO COMODO-ISTITUTO
                 MOVE CVNRE-CISO          TO COMODO-DIVISA
                 MOVE CVNRE-CVALUIC       TO COMODO-CMODUIC
                 PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVNRE-ICTVCVS NOT = 0 THEN
CARA39           COMPUTE COMODO-CAMBIO = CVNRE-IVALCVS /
CARA39                                   CVNRE-ICTVCVS
CARA39           MOVE CVNRE-CIST          TO COMODO-ISTITUTO
CARA39           MOVE CVNRE-CISO          TO COMODO-DIVISA
CARA39           MOVE CVNRE-CVALUIC       TO COMODO-CMODUIC
CARA39           PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.

           MOVE CVNRE-IREDDITO    TO IMPORTO-REDDITO         OF TRK-T08.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVNRE-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVNRE-ICTVREDD * 1000000
CARA39                                      / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVNRE-ICTVREDD
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N' AND CVNRE-IREDDITO > 0
CARA39        IF CVNRE-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVNRE-ICTVREDD * 1936,27
CARA39                                      / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVNRE-ICTVREDD
CARA39           IF CVNRE-ICTVREDD     < 1
FAA                 AND CVNRE-IREDDITO > 0
CARA39              MOVE 1 TO CVNRE-ICTVREDD
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVNRE-ICTVREDD    TO CTV-REDDITO             OF TRK-T08.

           MOVE CODICE-VALUTA OF TRK-T08 TO DIVISA-TITOLO.
VAR002     IF CODICE-VALUTA OF TRK-T08 = 018 OR = 242
              MOVE ZERO TO CTV-REDDITO OF TRK-T08.

           MOVE ZERO              TO RIFERIMENTO-CORREGGERE  OF TRK-T08.
           MOVE CVNRE-CCAUIC      TO TIPOLOGIA-OPERAZIONE    OF TRK-T08.

           MOVE COM-KEY2             TO AREA-KEY2.
           MOVE TRK-T08      TO AREA-UIC2.
           WRITE ZMRK1021.

           MOVE 'NO' TO WRK-TROVATO.
           MOVE CVNRE-NUMREG  TO CVRDT-NUMREG
CIST       MOVE CVNRE-CIST    TO CVRDT-CIST

           PERFORM CERCA-ACVRDT THRU EX-CERCA-ACVRDT.

       EX-SCRIVI-T08.

           EXIT.

       SCRIVI-T09.

           INITIALIZE TRK-T09.
           MOVE 'T09' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T09.
           MOVE 'T09'             TO TIPO-RECORD             OF TRK-T09.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T00  OF TRK-T09.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T01  OF TRK-T09.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-SEZ3 OF TRK-T09.
VAR001*    MOVE CVRDT-FLITEU      TO LIRA-VECCHIA-NUOVA      OF TRK-T09.
CARA39*    MOVE 'V'               TO LIRA-VECCHIA-NUOVA      OF TRK-T09.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'            TO LIRA-VECCHIA-NUOVA      OF TRK-T09
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'            TO LIRA-VECCHIA-NUOVA      OF TRK-T09
CARA39     END-IF
           MOVE CVRDT-CTITOLO     TO CODICE-TITOLO           OF TRK-T09.
           MOVE CVRDT-CVALUIC     TO CODICE-VALUTA           OF TRK-T09.
           MOVE CVRDT-IVALORENOM  TO VALORE-NOMINALE         OF TRK-T09.
           MOVE CVRDT-IQTAQUOTE   TO QUANTITA                OF TRK-T09.
           MOVE CVRDT-IREGOL      TO IMPORTO-REGOLATO        OF TRK-T09.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVRDT-FLITEU = 'V'
CARA39          COMPUTE WRK-CTV-EURO ROUNDED = CVRDT-ICTVREGOL * 1000000
CARA39                                      / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVRDT-ICTVREGOL
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        IF CVRDT-FLITEU = 'E'
CARA39          COMPUTE WRK-CTV-EURO ROUNDED = CVRDT-ICTVREGOL * 1936,27
CARA39                                   / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVRDT-ICTVREGOL
CARA39           IF CVRDT-ICTVREGOL    < 1
CARA39              MOVE 1 TO CVRDT-ICTVREGOL
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVRDT-ICTVREGOL   TO CTV-REGOLATO            OF TRK-T09.

           IF DIVISA-TITOLO            = 018 OR = 242
              MOVE ZERO TO CTV-REGOLATO OF TRK-T09.

           MOVE ZERO              TO VALORE-NOMINALE-INV     OF TRK-T09.
           MOVE ZERO              TO PERCENTUALE             OF TRK-T09.

           MOVE COM-KEY2    TO AREA-KEY2.
           MOVE TRK-T09       TO AREA-UIC2.
           WRITE ZMRK1021.

       EX-SCRIVI-T09.

           EXIT.

      *--------------------------------------------------------------*
      *              CARICA DATI DEL T02    (MERCANTILE)             *
      *                     DATI DEL T01    (OPERATORE)              *
      *                     DATI DEL T00    (SEGNALANTE)             *
      *--------------------------------------------------------------*

       SCRIVI-T02-T06-T01-T00.

           INITIALIZE COM-KEY2.
           MOVE 'T02' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVMER-CIST           TO CIST           OF COM-KEY2
           MOVE CVMER-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
           MOVE CVMER-NNDGSET        TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVMER-NUMCVS         TO NUM-DICH       OF COM-KEY2
           MOVE CVMER-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVMER-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.
VAR001     MOVE CVREG-NUMREG         TO NUM-REG        OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVMER-CCABFIL        TO WA-CAB.
           MOVE CVMER-CCABFIL        TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI           OF ZMRK1022       TO WA-CAB.
           MOVE CODICE-ABI           OF ZMRK1022       TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2

           INITIALIZE TRK-T02.
           MOVE COM-KEY2      TO AREA-KEY2.
           PERFORM PREPARA-T02 THRU EX-PREPARA-T02.
           MOVE TRK-T02       TO AREA-UIC2.

           WRITE ZMRK1021.

           INITIALIZE TRK-T06.
           MOVE 'T06' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVMER-CSEGNAL     TO WRK-CSEGNAL.
           MOVE CVMER-CDPZOPE     TO WA-SPORTELLO.
           MOVE WA-SPORTELLO TO NUMERAZIONE-INTERNA OF TRK-T06(1:3).

VAR003     IF CVREG-CCAB = ZERO
VAR003        MOVE CVMER-CCAB TO CVREG-CCAB.

VAR003     IF CVREG-CCABFIL = ZERO
VAR003        MOVE CVMER-CCABFIL TO CVREG-CCABFIL.

           MOVE COM-KEY2          TO AREA-KEY2.
           PERFORM PREPARA-T06    THRU EX-PREPARA-T06.
           MOVE CVREG-DVALNOA     TO WRK-DVALNOA
           MOVE CVMER-DSDOG       TO WRK-DSDOG
           MOVE AAAAMM OF WRK-DVALNOAR TO WRK-DVALNOAAAAAMM
           MOVE AAAAMM OF WRK-DSDOGR   TO WRK-DSDOGAAAAMM
           COMPUTE WRK-DIFFAAAAMM = WRK-DVALNOAAAAAMM - WRK-DSDOGAAAAMM
           COMPUTE WRK-DIFFAAAA = AAAA OF WRK-DVALNOAR -
                                                  AAAA OF WRK-DSDOGR
           COMPUTE WRK-DIFFMM   = WRK-DIFFAAAAMM - (WRK-DIFFAAAA * 88)
           IF WRK-DIFFMM > 2
              MOVE 1 TO FLAG-GIA-SEGNALATA OF TRK-T06
           END-IF.
           MOVE TRK-T06       TO AREA-UIC2.

           WRITE ZMRK1021.

           INITIALIZE TRK-T01.
           MOVE 'T01' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CIST             OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST             OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-OPERATORE    OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-OPERATORE    OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS     THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO LBL-T00-T02-T06.

           PERFORM SELECT-ACVCNS     THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO LBL-T00-T02-T06.

           INITIALIZE CODICE-XXX.
           MOVE CVMER-CCAB  TO  WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX TO CODICE-ABI OF TRK-T01.

           INITIALIZE CODICE-XXX.
           MOVE CVMER-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX TO CAB        OF TRK-T01.

           MOVE CVMER-NUMCVS      TO   WA-NUMCVS.
           MOVE WA-NUMCVS         TO   NUM-RIF-INTERNO     OF TRK-T01.
           MOVE EL-RIFCVS(INDT)   TO   DATA-SEGNALAZIONE   OF TRK-T01.

           IF CVMER-CSTADICH = 'AS'
              MOVE '1'            TO   COM-ANN-RIPR        OF TRK-T01
           ELSE
              IF CVMER-CSTADICH  = 'RA'
                 MOVE '2'         TO   COM-ANN-RIPR        OF TRK-T01
              ELSE
                 MOVE '0'         TO   COM-ANN-RIPR        OF TRK-T01.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T01    THRU EX-PREPARA-T01.
           MOVE TRK-T01       TO AREA-UIC2.

           WRITE ZMRK1021.

       LBL-T00-T02-T06.

           INITIALIZE TRK-T00.
           MOVE 'T00' TO TIPO-REC-UIC OF COM-KEY2.

           IF COD-SEGNALANTE OF COM-KEY2 = SPACES
              IF SW-CARICA-SEGNALANTE = 'SI'
                 MOVE 'NO' TO SW-CARICA-SEGNALANTE
                 PERFORM CARICA-SEGNALANTE THRU EX-CARICA-SEGNALANTE
              END-IF
              GO TO EX-SCRIVI-T02-T06-T01-T00.

           MOVE CIST           OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST           OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO EX-SCRIVI-T02-T06-T01-T00.

           PERFORM SELECT-ACVCNS THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO EX-SCRIVI-T02-T06-T01-T00.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T00 THRU EX-PREPARA-T00.
           MOVE TRK-T00 TO AREA-UIC2.

           WRITE ZMRK1021.

       EX-SCRIVI-T02-T06-T01-T00.

           EXIT.

      *-------------------------------------------------------------*
      *              CARICA DATI DEL T03 ( NON MERCANTILE)          *
      *                     DATI DEL T06    (REGOLAMENTO)           *
      *                     DATI DEL T01    (OPERATORE)             *
      *                     DATI DEL T00    (SEGNALANTE)            *
      *                     DATI DEL T04 ( FINANZIARIA )            *
      *                     DATI DEL T06    (REGOLAMENTO)           *
      *-------------------------------------------------------------*

       SCRIVI-T03-T06-T01-T00.

           INITIALIZE COM-KEY2.
           MOVE 'T03' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVNME-CIST           TO CIST           OF COM-KEY2
           MOVE CVNME-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
           MOVE CVNME-NNDGSET        TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVNME-NUMCVS         TO NUM-DICH       OF COM-KEY2
VAR001     MOVE CVREG-NUMREG         TO NUM-REG        OF COM-KEY2
           MOVE CVNME-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVNME-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVNME-CCABFIL        TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI           OF ZMRK1022       TO WA-CAB.
           MOVE CODICE-ABI           OF ZMRK1022       TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2


           INITIALIZE TRK-T03.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T03 THRU EX-PREPARA-T03.
           MOVE TRK-T03       TO AREA-UIC2.
           WRITE ZMRK1021.

           INITIALIZE TRK-T06.
           MOVE 'T06' TO TIPO-REC-UIC OF COM-KEY2.
           MOVE CVNME-CSEGNAL     TO WRK-CSEGNAL.
           MOVE CVNME-CDPZOPE     TO WA-SPORTELLO.
           MOVE WA-SPORTELLO TO NUMERAZIONE-INTERNA OF TRK-T06(1:3).

VAR003     IF CVREG-CCAB = ZERO
VAR003        MOVE CVNME-CCAB TO CVREG-CCAB.

VAR003     IF CVREG-CCABFIL = ZERO
VAR003        MOVE CVNME-CCABFIL TO CVREG-CCABFIL.

           MOVE COM-KEY2          TO AREA-KEY2.
           PERFORM PREPARA-T06    THRU EX-PREPARA-T06.
           MOVE CVREG-DVALNOA     TO WRK-DVALNOA
           MOVE CVNME-DPRESTAZ    TO WRK-DSDOG
           MOVE AAAAMM OF WRK-DVALNOAR TO WRK-DVALNOAAAAAMM
           MOVE AAAAMM OF WRK-DSDOGR   TO WRK-DSDOGAAAAMM
           COMPUTE WRK-DIFFAAAAMM = WRK-DVALNOAAAAAMM - WRK-DSDOGAAAAMM
           COMPUTE WRK-DIFFAAAA = AAAA OF WRK-DVALNOAR -
                                                  AAAA OF WRK-DSDOGR
           COMPUTE WRK-DIFFMM   = WRK-DIFFAAAAMM - (WRK-DIFFAAAA * 88)
           IF WRK-DIFFMM > 2
              MOVE 1 TO FLAG-GIA-SEGNALATA OF TRK-T06
           END-IF.
           MOVE TRK-T06       TO AREA-UIC2.
           WRITE ZMRK1021.

           INITIALIZE TRK-T01.
           MOVE 'T01' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CIST             OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST             OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-OPERATORE    OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-OPERATORE    OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS     THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSN THRU EX-ERRORE-NDG-CVSN
              GO TO LBL-T00-T03-T06.

           PERFORM SELECT-ACVCNS     THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSN THRU EX-ERRORE-NDG-CVSN
              GO TO LBL-T00-T03-T06.

           INITIALIZE CODICE-XXX.
           MOVE CVNME-CCAB TO  WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CODICE-ABI       OF TRK-T01

           INITIALIZE CODICE-XXX.
           MOVE CVNME-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CAB              OF TRK-T01.

           MOVE CVNME-NUMCVS      TO   WA-NUMCVS.
           MOVE WA-NUMCVS         TO   NUM-RIF-INTERNO     OF TRK-T01.
           MOVE EL-RIFCVS(INDT)   TO   DATA-SEGNALAZIONE   OF TRK-T01.

           IF CVNME-CSTADICH = 'AS'
              MOVE '1'            TO   COM-ANN-RIPR        OF TRK-T01
           ELSE
              IF CVNME-CSTADICH  = 'RA'
                 MOVE '2'         TO   COM-ANN-RIPR        OF TRK-T01
              ELSE
                 MOVE '0'         TO   COM-ANN-RIPR        OF TRK-T01.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T01    THRU EX-PREPARA-T01.
           MOVE TRK-T01       TO AREA-UIC2.
           WRITE ZMRK1021.

       LBL-T00-T03-T06.

           INITIALIZE TRK-T00.
           MOVE 'T00' TO TIPO-REC-UIC OF COM-KEY2.

           IF COD-SEGNALANTE OF COM-KEY2 = SPACES
              IF SW-CARICA-SEGNALANTE = 'SI'
                 MOVE 'NO' TO SW-CARICA-SEGNALANTE
                 PERFORM CARICA-SEGNALANTE THRU EX-CARICA-SEGNALANTE
              END-IF
              GO TO EX-SCRIVI-T03-T06-T01-T00.

           MOVE CIST           OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST           OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSN THRU EX-ERRORE-NDG-CVSN
              GO TO EX-SCRIVI-T03-T06-T01-T00.

           PERFORM SELECT-ACVCNS THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSN THRU EX-ERRORE-NDG-CVSN
              GO TO EX-SCRIVI-T03-T06-T01-T00.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T00 THRU EX-PREPARA-T00.
           MOVE TRK-T00 TO AREA-UIC2.
           WRITE ZMRK1021.

       EX-SCRIVI-T03-T06-T01-T00.

           EXIT.

       SCRIVI-T04-T06-T01-T00.

           INITIALIZE COM-KEY2.
           MOVE 'T04' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVFIN-CIST           TO CIST           OF COM-KEY2
           MOVE CVFIN-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
           MOVE CVFIN-NNDGSET        TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVFIN-NUMCVS         TO NUM-DICH       OF COM-KEY2
           MOVE CVREG-NUMREG         TO NUM-REG        OF COM-KEY2
           MOVE CVFIN-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVFIN-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVFIN-CCABFIL        TO WA-CAB.
           MOVE CVFIN-CCABFIL        TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI           OF ZMRK1022       TO WA-CAB.
           MOVE CODICE-ABI           OF ZMRK1022       TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2

           INITIALIZE TRK-T04.
           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T04 THRU EX-PREPARA-T04.
           MOVE TRK-T04       TO AREA-UIC2.

           WRITE ZMRK1021.

           INITIALIZE TRK-T06.
           MOVE 'T06' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVFIN-CSEGNAL     TO WRK-CSEGNAL.
           MOVE CVFIN-CDPZOPE     TO WA-SPORTELLO.
           MOVE WA-SPORTELLO TO NUMERAZIONE-INTERNA OF TRK-T06(1:3).

VAR003     IF CVREG-CCAB = ZERO
VAR003        MOVE CVFIN-CCAB TO CVREG-CCAB.

VAR003     IF CVREG-CCABFIL = ZERO
VAR003        MOVE CVFIN-CCABFIL TO CVREG-CCABFIL.

           MOVE COM-KEY2          TO AREA-KEY2.
           PERFORM PREPARA-T06    THRU EX-PREPARA-T06.
           MOVE TRK-T06       TO AREA-UIC2.

           WRITE ZMRK1021.
           INITIALIZE TRK-T01.
           MOVE 'T01' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CIST             OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST             OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-OPERATORE    OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-OPERATORE    OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS     THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBANAPOS 1'
              DISPLAY 'L-ACS908-RET-CODE ' L-ACS908-RET-CODE
              DISPLAY 'L-ACS908-SQLCODE  ' L-ACS908-SQLCODE
              DISPLAY 'L-ACS908-SQLMSG   ' L-ACS908-SQLMSG
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSF THRU EX-ERRORE-NDG-CVSF
              GO TO LBL-T00-T04-T06.

           PERFORM SELECT-ACVCNS     THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBACVCNS 1'
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSF THRU EX-ERRORE-NDG-CVSF
              GO TO LBL-T00-T04-T06.

           INITIALIZE CODICE-XXX.
           MOVE CVFIN-CCAB TO  WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CODICE-ABI       OF TRK-T01.

           INITIALIZE CODICE-XXX.
           MOVE CVFIN-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CAB              OF TRK-T01.

           MOVE CVFIN-NUMCVS      TO   WA-NUMCVS.
           MOVE WA-NUMCVS         TO   NUM-RIF-INTERNO     OF TRK-T01.
           MOVE EL-RIFCVS(INDT)   TO   DATA-SEGNALAZIONE   OF TRK-T01.

           IF CVFIN-CSTADICH = 'AS'
              MOVE '1'            TO   COM-ANN-RIPR        OF TRK-T01
           ELSE
              IF CVFIN-CSTADICH  = 'RA'
                 MOVE '2'         TO   COM-ANN-RIPR        OF TRK-T01
              ELSE
                 MOVE '0'         TO   COM-ANN-RIPR        OF TRK-T01.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T01    THRU EX-PREPARA-T01.
           MOVE TRK-T01       TO AREA-UIC2.
           WRITE ZMRK1021.


       LBL-T00-T04-T06.

           INITIALIZE TRK-T00.
           MOVE 'T00' TO TIPO-REC-UIC OF COM-KEY2.

           IF COD-SEGNALANTE OF COM-KEY2 = SPACES
              IF SW-CARICA-SEGNALANTE = 'SI'
                 MOVE 'NO' TO SW-CARICA-SEGNALANTE
                 PERFORM CARICA-SEGNALANTE THRU EX-CARICA-SEGNALANTE
              END-IF
              GO TO EX-SCRIVI-T04-T06-T01-T00.

           MOVE CIST           OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST           OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBANAPOS 2'
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSF THRU EX-ERRORE-NDG-CVSF
              GO TO EX-SCRIVI-T04-T06-T01-T00.

           PERFORM SELECT-ACVCNS THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBACVCNS 2'
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSF THRU EX-ERRORE-NDG-CVSF
              GO TO EX-SCRIVI-T04-T06-T01-T00.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T00 THRU EX-PREPARA-T00.
           MOVE TRK-T00 TO AREA-UIC2.
           WRITE ZMRK1021.


       EX-SCRIVI-T04-T06-T01-T00.

           EXIT.

       SCRIVI-T05-T06-T01-T00.

           INITIALIZE COM-KEY2.
           MOVE 'T05' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVCMP-CIST           TO CIST           OF COM-KEY2
           MOVE CVCMP-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
           MOVE CVCMP-NNDGSET        TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVCMP-NUMCVS         TO NUM-DICH       OF COM-KEY2
           MOVE CVREG-NUMREG         TO NUM-REG        OF COM-KEY2
           MOVE CVCMP-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVCMP-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVCMP-CCABFIL        TO WA-CAB.
           MOVE CVCMP-CCABFIL        TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI           OF ZMRK1022       TO WA-CAB.
           MOVE CODICE-ABI           OF ZMRK1022       TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2

           INITIALIZE TRK-T05.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T05.
           MOVE 'T05'             TO TIPO-RECORD             OF TRK-T05.
           MOVE 'S'               TO RIGA-OPERAZIONE         OF TRK-T05.
           MOVE CVCMP-DCOMPENS    TO DATA-X1.
           MOVE DATA-X1(1:6)      TO DATA-COMPENSAZIONE      OF TRK-T05.

           MOVE 1 TO INDICE.
CAR860     IF CVCMP-ICOMP1C NOT = 0
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 1              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'C'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP1C  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP1D NOT = 0
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 1              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'D'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP1D  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP2C NOT = 0
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 2              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'C'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP2C  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP2D NOT = 0
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 2              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'D'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP2D  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP3C NOT = 0
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 3              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'C'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP3C  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

CAR860     IF CVCMP-ICOMP3D NOT = 0
              MOVE INDICE         TO NUMERO-PROGRESSIVO-RIGA OF TRK-T05
              ADD  1              TO INDICE
CAR860        MOVE 3              TO NATURA-OPERAZIONE       OF TRK-T05
CAR860        MOVE 'D'            TO DEBITORE-CREDITORE      OF TRK-T05
              MOVE CVCMP-ICOMP3D  TO IMPORTO-LIRE            OF TRK-T05
              MOVE TRK-T05        TO AREA-UIC2
              MOVE COM-KEY2       TO AREA-KEY2
              WRITE ZMRK1021
           END-IF.

           MOVE 'NO' TO WRK-TROVATO.
           MOVE CVCMP-CCABFIL TO CVCMM-CCABFIL
           MOVE CVCMP-CPRECVS TO CVCMM-CPRECVS
           MOVE CVCMP-NUMCVS  TO CVCMM-NUMCVS
CIST       MOVE CVCMP-NUMCVS  TO CVCMM-CIST

           EXEC SQL INCLUDE ZMLOPE09 END-EXEC.

           IF SQLCODE NOT = ZERO
              MOVE 21 TO COMP-CODE
              DISPLAY 'ERRORE OPEN CURS09 ACVCMP'
              PERFORM ERRORE-DB2 THRU FINE-DB2.

           MOVE ZEROES    TO INDICE.

           MOVE 'NO' TO SW-FINE2.

           PERFORM FETCH-ACVCMM THRU FETCH-ACVCMM-END
                   UNTIL SW-FINE2 = 'SI'.

           EXEC SQL INCLUDE ZMLCLO09 END-EXEC.

           IF SQLCODE NOT = ZERO
              MOVE 22 TO COMP-CODE
              DISPLAY 'ERRORE CLOSE CURS09 ACVCMP'
              PERFORM ERRORE-DB2 THRU FINE-DB2.

           INITIALIZE TRK-T06.
           MOVE 'T06' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVCMP-CSEGNAL     TO WRK-CSEGNAL.
           MOVE CVCMP-CDPZOPE     TO WA-SPORTELLO.
           MOVE WA-SPORTELLO TO NUMERAZIONE-INTERNA OF TRK-T06(1:3).

VAR003     IF CVREG-CCAB = ZERO
VAR003        MOVE CVCMP-CCAB TO CVREG-CCAB.

VAR003     IF CVREG-CCABFIL = ZERO
VAR003        MOVE CVCMP-CCABFIL TO CVREG-CCABFIL.

           MOVE COM-KEY2          TO AREA-KEY2.
           PERFORM PREPARA-T06    THRU EX-PREPARA-T06.
           MOVE TRK-T06       TO AREA-UIC2.

           WRITE ZMRK1021.

           INITIALIZE TRK-T01.
           MOVE 'T01' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CIST             OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST             OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-OPERATORE    OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-OPERATORE    OF COM-KEY2 TO CVCNS-NNDGSET.
           PERFORM SELECT-ANAPOS     THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSC THRU EX-ERRORE-NDG-CVSC
              GO TO LBL-T00-T05-T06.

           PERFORM SELECT-ACVCNS     THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSC THRU EX-ERRORE-NDG-CVSC
              GO TO LBL-T00-T05-T06.

           INITIALIZE CODICE-XXX.
           MOVE CVCMP-CCAB  TO  WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CODICE-ABI       OF TRK-T01

           INITIALIZE CODICE-XXX.
           MOVE CVCMP-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CAB              OF TRK-T01.

           MOVE CVCMP-NUMCVS      TO   WA-NUMCVS.
           MOVE WA-NUMCVS         TO   NUM-RIF-INTERNO     OF TRK-T01.
           MOVE EL-RIFCVS(INDT)   TO   DATA-SEGNALAZIONE   OF TRK-T01.
           MOVE '0'               TO   COM-ANN-RIPR        OF TRK-T01.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T01    THRU EX-PREPARA-T01.
           MOVE TRK-T01       TO AREA-UIC2.
           WRITE ZMRK1021.

       LBL-T00-T05-T06.

           INITIALIZE TRK-T00.
           MOVE 'T00' TO TIPO-REC-UIC OF COM-KEY2.

           IF COD-SEGNALANTE OF COM-KEY2 = SPACES
              IF SW-CARICA-SEGNALANTE = 'SI'
                 MOVE 'NO' TO SW-CARICA-SEGNALANTE
                 PERFORM CARICA-SEGNALANTE THRU EX-CARICA-SEGNALANTE
              END-IF
              GO TO EX-SCRIVI-T05-T06-T01-T00.

           MOVE CIST           OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST           OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSC THRU EX-ERRORE-NDG-CVSC
              GO TO EX-SCRIVI-T05-T06-T01-T00.

           PERFORM SELECT-ACVCNS THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSM THRU EX-ERRORE-NDG-CVSM
              GO TO EX-SCRIVI-T05-T06-T01-T00.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T00 THRU EX-PREPARA-T00.
           MOVE TRK-T00 TO AREA-UIC2.

           WRITE ZMRK1021.

       EX-SCRIVI-T05-T06-T01-T00.

           EXIT.

       SCRIVI-T03-T01-T00.

           INITIALIZE COM-KEY2.
           MOVE 'T03' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVNME-CIST           TO CIST           OF COM-KEY2
           MOVE CVNME-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
           MOVE CVNME-NNDGSET        TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVNME-NUMCVS         TO NUM-DICH       OF COM-KEY2
           MOVE CVNME-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVNME-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVNME-CCABFIL        TO WA-CAB.
           MOVE CVNME-CCABFIL        TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI           OF ZMRK1022       TO WA-CAB.
           MOVE CODICE-ABI           OF ZMRK1022       TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2

           INITIALIZE TRK-T03.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T03 THRU EX-PREPARA-T03.
           MOVE TRK-T03       TO AREA-UIC2.
           WRITE ZMRK1021.

           INITIALIZE TRK-T01.
           MOVE 'T01' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CIST             OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST             OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-OPERATORE    OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-OPERATORE    OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS     THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBANAPOS N'
              DISPLAY 'L-ACS908-RET-CODE ' L-ACS908-RET-CODE
              DISPLAY 'L-ACS908-SQLCODE  ' L-ACS908-SQLCODE
              DISPLAY 'L-ACS908-SQLMSG   ' L-ACS908-SQLMSG
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSN THRU EX-ERRORE-NDG-CVSN
              GO TO LBL-T00-T03.

           PERFORM SELECT-ACVCNS     THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSN THRU EX-ERRORE-NDG-CVSN
              GO TO LBL-T00-T03.

           INITIALIZE CODICE-XXX.
           MOVE CVNME-CCAB TO  WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CODICE-ABI       OF TRK-T01.

           INITIALIZE CODICE-XXX.
           MOVE CVNME-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CAB              OF TRK-T01.

           MOVE CVNME-NUMCVS      TO   WA-NUMCVS.
           MOVE WA-NUMCVS         TO   NUM-RIF-INTERNO     OF TRK-T01.
           MOVE EL-RIFCVS(INDT)   TO   DATA-SEGNALAZIONE   OF TRK-T01.

           IF CVNME-CSTADICH = 'AS'
              MOVE '1'            TO   COM-ANN-RIPR        OF TRK-T01
           ELSE
              IF CVNME-CSTADICH  = 'RA'
                 MOVE '2'         TO   COM-ANN-RIPR        OF TRK-T01
              ELSE
                 MOVE '0'         TO   COM-ANN-RIPR        OF TRK-T01.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T01    THRU EX-PREPARA-T01.
           MOVE TRK-T01       TO AREA-UIC2.
           WRITE ZMRK1021.

       LBL-T00-T03.

           INITIALIZE TRK-T00.
           MOVE 'T00' TO TIPO-REC-UIC OF COM-KEY2.

           IF COD-SEGNALANTE OF COM-KEY2 = SPACES
              GO TO EX-SCRIVI-T03-T01-T00.

           MOVE CIST           OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST           OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSN THRU EX-ERRORE-NDG-CVSN
              GO TO EX-SCRIVI-T03-T01-T00.

           PERFORM SELECT-ACVCNS THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSN THRU EX-ERRORE-NDG-CVSN
              GO TO EX-SCRIVI-T03-T01-T00.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T00 THRU EX-PREPARA-T00.
           MOVE TRK-T00 TO AREA-UIC2.
           WRITE ZMRK1021.

       EX-SCRIVI-T03-T01-T00.

           EXIT.

       SCRIVI-T04-T01-T00.

           INITIALIZE COM-KEY2.
           MOVE 'T04' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CVFIN-CIST           TO CIST           OF COM-KEY2
           MOVE CVFIN-CSEGNAL        TO COD-SEGNALANTE OF COM-KEY2.
           MOVE CVFIN-NNDGSET        TO COD-OPERATORE  OF COM-KEY2.
           MOVE CVFIN-NUMCVS         TO NUM-DICH       OF COM-KEY2
           MOVE CVFIN-CTIPDICH       TO TIPO-DICHIARA  OF COM-KEY2.
           MOVE CVFIN-CSTADICH       TO STATO-DICHIARA OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CVFIN-CCABFIL        TO WA-CAB.
           MOVE CVFIN-CCABFIL        TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF COM-KEY2.

           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI           OF ZMRK1022       TO WA-CAB.
           MOVE CODICE-ABI           OF ZMRK1022       TO CODICE5.
           PERFORM CONTR-CODICE      THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE         TO CONTRO5        OF CODICE-XXX.
           MOVE CODICE-XXX           TO COD-ABI        OF COM-KEY2

           INITIALIZE TRK-T04.
           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T04 THRU EX-PREPARA-T04.
           MOVE TRK-T04       TO AREA-UIC2.

           WRITE ZMRK1021.

           INITIALIZE TRK-T01.
           MOVE 'T01' TO TIPO-REC-UIC OF COM-KEY2.

           MOVE CIST             OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST             OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-OPERATORE    OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-OPERATORE    OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS     THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBANAPOS 3'
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSF THRU EX-ERRORE-NDG-CVSF
              GO TO LBL-T00-T04.

           PERFORM SELECT-ACVCNS     THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBACVCNS 3'
              MOVE '*'               TO CAMPO-ASTO   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTS   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSF THRU EX-ERRORE-NDG-CVSF
              GO TO LBL-T00-T04.

           INITIALIZE CODICE-XXX.
           MOVE CVMER-CCAB TO  WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CODICE-ABI       OF TRK-T01

           INITIALIZE CODICE-XXX.
           MOVE CVFIN-CCABFIL  TO WA-CAB CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE   TO CONTRO5          OF CODICE-XXX.
           MOVE CODICE-XXX     TO CAB              OF TRK-T01.

           MOVE CVFIN-NUMCVS      TO   WA-NUMCVS.
           MOVE WA-NUMCVS         TO   NUM-RIF-INTERNO     OF TRK-T01.
           MOVE EL-RIFCVS(INDT)   TO   DATA-SEGNALAZIONE   OF TRK-T01.

           IF CVFIN-CSTADICH = 'AS'
              MOVE '1'            TO   COM-ANN-RIPR        OF TRK-T01
           ELSE
              IF CVFIN-CSTADICH  = 'RA'
                 MOVE '2'         TO   COM-ANN-RIPR        OF TRK-T01
              ELSE
                 MOVE '0'         TO   COM-ANN-RIPR        OF TRK-T01.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T01    THRU EX-PREPARA-T01.
           MOVE TRK-T01       TO AREA-UIC2.
           WRITE ZMRK1021.

       LBL-T00-T04.

           INITIALIZE TRK-T00.
           MOVE 'T00' TO TIPO-REC-UIC OF COM-KEY2.

           IF COD-SEGNALANTE OF COM-KEY2 = SPACES
              GO TO EX-SCRIVI-T04-T01-T00.

           MOVE CIST           OF COM-KEY2 TO NAPOS-CIST.
           MOVE CIST           OF COM-KEY2 TO CVCNS-CIST.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO NAPOS-NNDGSET.
           MOVE COD-SEGNALANTE OF COM-KEY2 TO CVCNS-NNDGSET.

           PERFORM SELECT-ANAPOS THRU SELECT-ANAPOS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBANAPOS 4'
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSF THRU EX-ERRORE-NDG-CVSF
              GO TO EX-SCRIVI-T04-T01-T00.

           PERFORM SELECT-ACVCNS THRU SELECT-ACVCNS-END

           IF SQLCODE = +100
TEST          DISPLAY 'SELECT TBACVCNS 4'
              MOVE '*'               TO CAMPO-ASTS   OF ZMRK1026
              MOVE SPACES            TO CAMPO-ASTO   OF ZMRK1026
              PERFORM ERRORE-NDG-CVSF THRU EX-ERRORE-NDG-CVSF
              GO TO EX-SCRIVI-T04-T01-T00.

           MOVE COM-KEY2             TO AREA-KEY2.
           PERFORM PREPARA-T00 THRU EX-PREPARA-T00.
           MOVE TRK-T00 TO AREA-UIC2.
           WRITE ZMRK1021.

       EX-SCRIVI-T04-T01-T00.

           EXIT.

       PREPARA-T02.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T02.
           MOVE 'T02'             TO TIPO-RECORD             OF TRK-T02.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T00  OF TRK-T02.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T01  OF TRK-T02.
           MOVE '000'             TO FILLER1-TRKT02          OF TRK-T02.
VAR001*    MOVE CVMER-FLITEU      TO LIRA-VECCHIA-NUOVA      OF TRK-T02.
CARA39*    MOVE 'V'               TO LIRA-VECCHIA-NUOVA      OF TRK-T02.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'            TO LIRA-VECCHIA-NUOVA      OF TRK-T02
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'            TO LIRA-VECCHIA-NUOVA      OF TRK-T02
CARA39     END-IF
           MOVE ZERO              TO DATA-CONTRATTO          OF TRK-T02.
           MOVE CVMER-CCONTROP    TO TIPO-CONTROPARTE        OF TRK-T02.
           MOVE CVMER-CTIPCONTR   TO SETTORE-CONTROPARTE     OF TRK-T02.
           MOVE CVMER-CPAECTPUIC  TO COD-PAESE-CTP           OF TRK-T02.

           MOVE CVMER-FIMPEXP     TO COD-IMP-EXP             OF TRK-T02.
           MOVE '00'              TO COD-TIPO-OP             OF TRK-T02.
           MOVE 9                 TO INTERVENTI-PUB-AMM      OF TRK-T02.
           MOVE 9                 TO INTERVENTI-PUB-FIN      OF TRK-T02.
           MOVE CVMER-DSDOG       TO DATA-X1
           MOVE DATA-X1(1:6)      TO DATA-ATT-OPERAZIONE     OF TRK-T02.
           MOVE CVMER-CCODMERCE   TO CODICE-MERCE            OF TRK-T02.
           MOVE CVMER-CPAEDPUIC   TO COD-PAESE-DEST-PROV     OF TRK-T02.
           MOVE CVMER-CPROV       TO SIGLA-PROVINCIA         OF TRK-T02.
           MOVE CVMER-IVALCVS     TO IMPORTO-VALUTA          OF TRK-T02.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVMER-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVMER-ICTVCVS  * 1000000
CARA39                                      / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVMER-ICTVCVS
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        IF CVMER-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVMER-ICTVCVS  * 1936,27
CARA39                                      / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVMER-ICTVCVS
CARA39           IF CVMER-ICTVCVS      < 1
CARA39              MOVE 1 TO CVMER-ICTVCVS
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVMER-ICTVCVS     TO IMPORTO-CTV             OF TRK-T02.
           MOVE CVMER-CVALUIC     TO CODICE-VALUTA           OF TRK-T02.

VAR002     IF CODICE-VALUTA   OF   TRK-T02 = 018 OR = 301 OR = 242
              MOVE ZERO TO IMPORTO-CTV OF TRK-T02.


CARA39     IF WRK-CVS-EURO = 'N'
           IF CVMER-CISO  NOT = 'ITL'
              IF CVMER-ICTVCVS NOT = 0 THEN
                 COMPUTE COMODO-CAMBIO = (CVMER-ICTVCVS
                            * 1000000) /  CVMER-IVALCVS
                 MOVE CVMER-CIST                 TO COMODO-ISTITUTO
                 MOVE CVMER-CISO                 TO COMODO-DIVISA
                 MOVE CODICE-VALUTA  OF TRK-T02  TO COMODO-CMODUIC
                 PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVMER-ICTVCVS NOT = 0 THEN
CARA39           COMPUTE COMODO-CAMBIO = CVMER-IVALCVS /
CARA39                                   CVMER-ICTVCVS
CARA39*          DISPLAY CVMER-NUMCVS ' ' COMODO-CAMBIO
CARA39*                  CVMER-IVALCVS ' ' CVMER-ICTVCVS
CARA39           MOVE CVMER-CIST          TO COMODO-ISTITUTO
CARA39           MOVE CVMER-CISO          TO COMODO-DIVISA
CARA39           MOVE CVMER-CVALUIC       TO COMODO-CMODUIC
CARA39           PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.

           MOVE CVMER-IVALCVSNM     TO IMPORTO-VALUTA-NM     OF TRK-T02.
CARA39        IF WRK-CVS-EURO = 'S'
CARA39           IF CVMER-FLITEU = 'V'
CARA39              COMPUTE WRK-CTV-EURO ROUNDED = CVMER-ICTVCVSNM
CARA39                                      * 1000000 / 1936,27
CARA39              MOVE WRK-CTV-EURO    TO CVMER-ICTVCVSNM
CARA39           END-IF
CARA39        END-IF
CARA39*       IF WRK-CVS-EURO = 'N'
FAA           IF WRK-CVS-EURO = 'N' AND CVMER-IVALCVSNM  > 0
CARA39           IF CVMER-FLITEU = 'E'
CARA39              COMPUTE WRK-CTV-EURO ROUNDED = CVMER-ICTVCVSNM
CARA39                                      *1936,27 / 1000000
CARA39              MOVE WRK-CTV-EURO    TO CVMER-ICTVCVSNM
CARA39              IF CVMER-ICTVCVSNM    < 1
CARA39                 MOVE 1 TO CVMER-ICTVCVSNM
CARA39              END-IF
CARA39           END-IF
CARA39        END-IF
           MOVE CVMER-ICTVCVSNM     TO IMPORTO-CTV-NM        OF TRK-T02.

VAR002     IF CODICE-VALUTA   OF   TRK-T02 = 018 OR = 301 OR = 242
              MOVE ZERO TO IMPORTO-CTV-NM OF TRK-T02.

           MOVE ZERO                TO IMPORTO-VALUTA-INT    OF TRK-T02.
           MOVE ZERO                TO IMPORTO-CTV-ML-LIT    OF TRK-T02.
           MOVE CVMER-FTRASP        TO MEZZO-TRASPORTO       OF TRK-T02.
           MOVE CVMER-CPAEVETUIC    TO COD-PAESE-VETTORE     OF TRK-T02.
           MOVE CVMER-IREGPOST      TO IMPORTO-VALUTA-REG    OF TRK-T02.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVMER-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED  = CVMER-ICTVREGPOS
CARA39                                     * 1000000  / 1936,27
CARA39           MOVE WRK-CTV-EURO    TO CVMER-ICTVREGPOS
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N' AND CVMER-IREGPOST > 0
CARA39        IF CVMER-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVMER-ICTVREGPOS
CARA39                                   * 1936,27   / 1000000
CARA39           MOVE WRK-CTV-EURO    TO CVMER-ICTVREGPOS
CARA39           IF CVMER-ICTVREGPOS   < 1
CARA39              MOVE 1 TO CVMER-ICTVREGPOS
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVMER-ICTVREGPOS    TO IMPORTO-CTV-REG       OF TRK-T02.

VAR002     IF CODICE-VALUTA   OF   TRK-T02 = 018 OR = 242
              MOVE ZERO TO IMPORTO-CTV-REG OF TRK-T02.

           MOVE CVMER-NUMRATE       TO NUMERO-RATE           OF TRK-T02.
           MOVE CVMER-DPRIRATA      TO DATA-X1
           MOVE DATA-X1(1:6)        TO DATA-PRIMA-RATA       OF TRK-T02.
           MOVE CVMER-DULTRATA      TO DATA-X1
           MOVE DATA-X1(1:6)        TO DATA-ULTIMA-RATA      OF TRK-T02.
           MOVE ZERO                TO TASSO-INT-FISSO       OF TRK-T02.
           MOVE ZERO                TO CODICE-INT-VARIABILE  OF TRK-T02.
           MOVE CVMER-ISENZAREG     TO IMPORTO-VALUTA-NOREG  OF TRK-T02.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVMER-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO  ROUNDED = CVMER-ICTVSENZAR
CARA39                                   * 1000000 / 1936,27
CARA39           MOVE WRK-CTV-EURO    TO CVMER-ICTVSENZAR
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N' AND CVMER-ISENZAREG > 0
CARA39        IF CVMER-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO  ROUNDED = CVMER-ICTVSENZAR
CARA39                                   * 1936,27   / 1000000
CARA39           MOVE WRK-CTV-EURO    TO CVMER-ICTVSENZAR
CARA39           IF CVMER-ICTVSENZAR   < 1
CARA39              MOVE 1 TO CVMER-ICTVSENZAR
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVMER-ICTVSENZAR    TO IMPORTO-CTV-NOREG     OF TRK-T02.

VAR002     IF CODICE-VALUTA   OF   TRK-T02 = 018 OR = 242
              MOVE ZERO TO IMPORTO-CTV-NOREG OF TRK-T02.

           MOVE ZERO                TO CAUSALE-NOREG         OF TRK-T02.

VAR002     IF CODICE-VALUTA   OF   TRK-T02 NOT = 018 AND NOT = 242 AND
VAR002        IMPORTO-CTV-REG OF   TRK-T02 = 0
               MOVE ZERO TO NUMERO-RATE             OF TRK-T02
                            DATA-PRIMA-RATA         OF TRK-T02
                            DATA-ULTIMA-RATA        OF TRK-T02.

           IF NUMERO-RATE     OF   TRK-T02 = 1
               MOVE ZERO TO DATA-ULTIMA-RATA        OF TRK-T02.

VAR002     MOVE CVMER-CCAUIC        TO TIPOLOGIA-OPERAZIONE OF TRK-T02.
VAR002     MOVE CVMER-CRESMER       TO CLAUSOLA-RESA        OF TRK-T02.

       EX-PREPARA-T02.

           EXIT.

       PREPARA-T03.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T03.
           MOVE 'T03'             TO TIPO-RECORD             OF TRK-T03.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T00  OF TRK-T03.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T01  OF TRK-T03.
           MOVE '000'             TO FILLER1-TRKT03          OF TRK-T03.
VAR001*    MOVE CVNME-FLITEU      TO LIRA-VECCHIA-NUOVA      OF TRK-T03.
CARA39*    MOVE 'V'               TO LIRA-VECCHIA-NUOVA      OF TRK-T03.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'            TO LIRA-VECCHIA-NUOVA      OF TRK-T03
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'            TO LIRA-VECCHIA-NUOVA      OF TRK-T03
CARA39     END-IF
           MOVE ZERO              TO DATA-CONTRATTO          OF TRK-T03.
           MOVE CVNME-CCONTROP    TO TIPO-CONTROPARTE        OF TRK-T03.
           MOVE CVNME-CTIPCONTR   TO SETTORE-CONTROPARTE     OF TRK-T03.
           MOVE CVNME-CPAECTPUIC  TO COD-PAESE-CTP           OF TRK-T03.
           MOVE CVNME-FACQVEN     TO ACQUISTO-VENDITA        OF TRK-T03.
           MOVE 9                 TO INTERVENTI-PUB-AMM      OF TRK-T03.
           MOVE 9                 TO INTERVENTI-PUB-FIN      OF TRK-T03.
           MOVE CVNME-DPRESTAZ    TO DATA-X1
           MOVE DATA-X1(1:6)      TO DATA-ATT-OPERAZIONE     OF TRK-T03.
           MOVE CVNME-CCAUIC      TO CODICE-CAUSALE          OF TRK-T03.
           MOVE CVNME-CCODMERCE   TO CODICE-MERCE            OF TRK-T03.
           MOVE CVNME-CPAEDPUIC   TO COD-PAESE-DEST-PROV     OF TRK-T03.
           MOVE CVNME-CPROV       TO SIGLA-PROVINCIA         OF TRK-T03.
           MOVE CVNME-IVALCVS     TO IMPORTO-VALUTA      OF TRK-T03
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVNME-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVNME-ICTVCVS * 1000000
CARA39                                      / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVNME-ICTVCVS
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        IF CVNME-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVNME-ICTVCVS * 1936,27
CARA39                                      / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVNME-ICTVCVS
CARA39           IF CVNME-ICTVCVS      < 1
CARA39              MOVE 1 TO CVNME-ICTVCVS
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVNME-ICTVCVS     TO IMPORTO-CTV         OF TRK-T03

           MOVE CVNME-CVALUIC     TO CODICE-VALUTA       OF TRK-T03

VAR002     IF CODICE-VALUTA   OF   TRK-T03 = 018 OR = 242
              MOVE ZERO TO IMPORTO-CTV  OF TRK-T03.

CARA39     IF WRK-CVS-EURO = 'N'
           IF CVNME-CISO NOT = 'ITL'
              IF CVNME-ICTVCVS NOT = 0 THEN
                 COMPUTE COMODO-CAMBIO = (CVNME-ICTVCVS
                             * 1000000) / CVNME-IVALCVS
                 MOVE CVNME-CIST    TO COMODO-ISTITUTO
                 MOVE CVNME-CISO    TO COMODO-DIVISA
                 MOVE CVNME-CVALUIC TO COMODO-CMODUIC
                 PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVNME-ICTVCVS NOT = 0 THEN
CARA39           COMPUTE COMODO-CAMBIO =  CVNME-IVALCVS /
CARA39                                    CVNME-ICTVCVS
CARA39           MOVE CVNME-CIST    TO COMODO-ISTITUTO
CARA39*          DISPLAY CVNME-NUMCVS ' ' COMODO-CAMBIO
CARA39*                  CVNME-IVALCVS ' ' CVNME-ICTVCVS
CARA39           MOVE CVNME-CISO    TO COMODO-DIVISA
CARA39           MOVE CVNME-CVALUIC TO COMODO-CMODUIC
CARA39           PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.

           MOVE CVNME-IREGPOST    TO IMPORTO-VALUTA-REG  OF TRK-T03.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVNME-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO  ROUNDED = CVNME-ICTVREGPOS
CARA39                                   * 1000000 / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVNME-ICTVREGPOS
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N' AND CVNME-IREGPOST > 0
CARA39        IF CVNME-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO  ROUNDED = CVNME-ICTVREGPOS
CARA39                                   * 1936,27 / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVNME-ICTVREGPOS
CARA39           IF CVNME-ICTVREGPOS   < 1
CARA39              MOVE 1 TO CVNME-ICTVREGPOS
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVNME-ICTVREGPOS  TO IMPORTO-CTV-REG     OF TRK-T03.

VAR002     IF CODICE-VALUTA   OF   TRK-T03 = 018 OR = 242
              MOVE ZERO TO IMPORTO-CTV-REG  OF TRK-T03.

           MOVE CVNME-NUMRATE   TO NUMERO-RATE         OF TRK-T03.
           MOVE CVNME-DPRIRATA  TO DATA-X1.
           MOVE DATA-X1(1:6)    TO DATA-PRIMA-RATA     OF TRK-T03.
           MOVE CVNME-DULTRATA  TO DATA-X1.
           MOVE DATA-X1(1:6)    TO DATA-ULTIMA-RATA    OF TRK-T03.

           MOVE ZERO            TO TASSO-INT-FISSO         OF TRK-T03.
           MOVE ZERO            TO CODICE-INT-VARIABILE    OF TRK-T03.
           MOVE ZERO            TO IMPORTO-VALUTA-CAPITALE OF TRK-T03.
           MOVE ZERO            TO IMPORTO-CTV-CAPITALE    OF TRK-T03.
           MOVE ZERO            TO CODICE-ACQ-VEND         OF TRK-T03.
           MOVE ZERO            TO DATA-SCADENZA           OF TRK-T03.

       EX-PREPARA-T03.

           EXIT.

       PREPARA-T04.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T04.
           MOVE 'T04'             TO TIPO-RECORD             OF TRK-T04.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T00  OF TRK-T04.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T01  OF TRK-T04.
           MOVE '000'             TO FILLER1-TRKT04          OF TRK-T04.
VAR001*    MOVE CVFIN-FLITEU      TO LIRA-VECCHIA-NUOVA      OF TRK-T04.
CARA39*    MOVE 'V'               TO LIRA-VECCHIA-NUOVA      OF TRK-T04.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'            TO LIRA-VECCHIA-NUOVA      OF TRK-T04
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'            TO LIRA-VECCHIA-NUOVA      OF TRK-T04
CARA39     END-IF
           MOVE ZERO              TO DATA-CONTRATTO          OF TRK-T04.
           MOVE CVFIN-CCONTROP    TO TIPO-CONTROPARTE    OF TRK-T04.
           MOVE CVFIN-CTIPCONTR   TO SETTORE-CONTROPARTE OF TRK-T04.
           MOVE CVFIN-CPAECTPUIC  TO COD-PAESE-CTP       OF TRK-T04.

CARA39*    IF CVFIN-CISO NOT = 'ITL'
CARA39*       IF CVFIN-ICTVCVS NOT = 0 THEN
CARA39*          COMPUTE COMODO-CAMBIO = (CVFIN-ICTVCVS
CARA39*                      * 1000000) / CVFIN-IVALCVS
CARA39*          MOVE CVFIN-CIST     TO COMODO-ISTITUTO
CARA39*          MOVE CVFIN-CISO     TO COMODO-DIVISA
CARA39*          MOVE CVFIN-CVALUIC  TO COMODO-CMODUIC
CARA39*          PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.

           MOVE CVFIN-FPAGINC      TO INCASSO-PAGAMENTO    OF TRK-T04.
           MOVE ZERO               TO COD-TIPO-OP          OF TRK-T04.
           MOVE CVFIN-CPAEUBUIC    TO COD-PAE-UBI-BENI     OF TRK-T04.
           MOVE 9                  TO INTERVENTI-PUB-AMM   OF TRK-T04.
           MOVE 9                  TO INTERVENTI-PUB-FIN   OF TRK-T04.
           MOVE CVFIN-CLEGAMEDUR   TO FLAG-LEGAME-DUREVOLE OF TRK-T04.
           MOVE CVFIN-CATTIVITA    TO CODICE-BRANCA        OF TRK-T04.
           MOVE CVFIN-CPROV        TO SIGLA-PROVINCIA      OF TRK-T04.
           MOVE CVFIN-IVALCVS      TO IMPORTO-VALUTA       OF TRK-T04.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVFIN-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO  ROUNDED = CVFIN-ICTVCVS * 1000000
CARA39                                      / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVFIN-ICTVCVS
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        IF CVFIN-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO  ROUNDED = CVFIN-ICTVCVS * 1936,27
CARA39                                      / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVFIN-ICTVCVS
CARA39           IF CVFIN-ICTVCVS      < 1
CARA39              MOVE 1 TO CVFIN-ICTVCVS
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVFIN-ICTVCVS      TO IMPORTO-CTV          OF TRK-T04.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39     IF CVFIN-CISO NOT = 'ITL'
CARA39        IF CVFIN-ICTVCVS NOT = 0 THEN
CARA39           COMPUTE COMODO-CAMBIO = (CVFIN-ICTVCVS
CARA39                       * 1000000) / CVFIN-IVALCVS
CARA39           MOVE CVFIN-CIST     TO COMODO-ISTITUTO
CARA39           MOVE CVFIN-CISO     TO COMODO-DIVISA
CARA39           MOVE CVFIN-CVALUIC  TO COMODO-CMODUIC
CARA39           PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVFIN-ICTVCVS NOT = 0 THEN
CARA39           COMPUTE COMODO-CAMBIO = CVFIN-IVALCVS /
CARA39                                   CVFIN-ICTVCVS
CARA39           MOVE CVFIN-CIST     TO COMODO-ISTITUTO
CARA39           MOVE CVFIN-CISO     TO COMODO-DIVISA
CARA39*          DISPLAY CVFIN-NUMCVS ' ' COMODO-CAMBIO
CARA39*                  CVFIN-IVALCVS ' ' CVFIN-ICTVCVS
CARA39           MOVE CVFIN-CVALUIC  TO COMODO-CMODUIC
CARA39           PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.
           MOVE CVFIN-CVALUIC      TO CODICE-VALUTA        OF TRK-T04.

VAR002     IF CODICE-VALUTA   OF   TRK-T04 = 018 OR = 242
              MOVE ZERO TO IMPORTO-CTV OF TRK-T04.

           MOVE ZERO             TO IMPORTO-VALUTA-PRESTITO  OF TRK-T04.
           MOVE ZERO             TO IMPORTO-CTV-PRESTITO     OF TRK-T04.
           MOVE CVFIN-CTIPOPREST TO TIPO-PRESTITO            OF TRK-T04.
           MOVE CVFIN-ILINEACAP  TO IMPORTO-VALUTA-REG       OF TRK-T04.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVFIN-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO  ROUNDED = CVFIN-ICTVLINEAC
CARA39                                   * 1000000   / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVFIN-ICTVLINEAC
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N' AND CVFIN-ILINEACAP > 0
CARA39        IF CVFIN-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO  ROUNDED = CVFIN-ICTVLINEAC
CARA39                                   * 1936,27   / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVFIN-ICTVLINEAC
CARA39           IF CVFIN-ICTVLINEAC   < 1
CARA39              MOVE 1 TO CVFIN-ICTVLINEAC
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVFIN-ICTVLINEAC TO IMPORTO-CTV-REG          OF TRK-T04.

VAR002     IF CODICE-VALUTA   OF   TRK-T04 = 018 OR = 242
              MOVE ZERO TO IMPORTO-CTV-REG OF TRK-T04.

           MOVE CVFIN-NUMRATE    TO NUMERO-RATE              OF TRK-T04.
           MOVE CVFIN-DPRIRATA    TO DATA-X1.
           MOVE DATA-X1(1:6)      TO DATA-PRIMA-RATA         OF TRK-T04.
           MOVE CVFIN-DULTRATA    TO DATA-X1.
           MOVE DATA-X1(1:6)      TO DATA-ULTIMA-RATA        OF TRK-T04.
           MOVE ZERO              TO TASSO-INT-FISSO         OF TRK-T04.
           MOVE ZERO              TO CODICE-INT-VARIABILE    OF TRK-T04.
           MOVE 9                 TO CLAUSOLA-ZERO-COUPONS   OF TRK-T04.
           MOVE 9                 TO CLAUSOLA-RIMB-ANT       OF TRK-T04.
           MOVE 9                 TO CLAUSOLA-MULTICURRENCY  OF TRK-T04.
           MOVE 9                 TO CLAUSOLA-ALTRE          OF TRK-T04.
           MOVE 9                 TO GARANZIE-CAMBIO         OF TRK-T04.
           MOVE 9                 TO GARANZIE-CAPITALE       OF TRK-T04.
           MOVE ZERO              TO CODICE-PAESE-GARANTE    OF TRK-T04.
           MOVE CVFIN-CCAUIC      TO TIPOLOGIA-OPERAZIONE    OF TRK-T04.
           MOVE CVFIN-FTIPOPAR    TO TIPO-PARTECIPAZIONE     OF TRK-T04.
           MOVE CVFIN-DEROPR      TO DATA-X1.
           MOVE DATA-X1(1:6)      TO DATA-EROGAZIONE         OF TRK-T04.

           IF TIPO-CONTROPARTE OF TRK-T04 = ZERO
               MOVE ZERO TO SETTORE-CONTROPARTE   OF TRK-T04
                            COD-PAESE-CTP         OF TRK-T04.

           IF NUMERO-RATE       OF   TRK-T04  = 1
               MOVE ZERO TO DATA-ULTIMA-RATA        OF TRK-T04.

       EX-PREPARA-T04.

           EXIT.

       PREPARA-T06.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T06.
           MOVE 'T06'             TO TIPO-RECORD             OF TRK-T06.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T00  OF TRK-T06.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T01  OF TRK-T06.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-SEZ3 OF TRK-T06.
VAR001*    MOVE CVREG-FLITEU      TO LIRA-VECCHIA-NUOVA      OF TRK-T06.
CARA39*    MOVE 'V'               TO LIRA-VECCHIA-NUOVA      OF TRK-T06.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'            TO LIRA-VECCHIA-NUOVA      OF TRK-T06
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'            TO LIRA-VECCHIA-NUOVA      OF TRK-T06
CARA39     END-IF
           MOVE CVREG-NUMREG      TO WA-NUMREG.
           MOVE WA-NUMREG  TO NUMERAZIONE-INTERNA OF TRK-T06 (4:15).
           MOVE CVREG-DVALNOA     TO DATA-X1.
           MOVE DATA-X1           TO DATA-REGOLAMENTO        OF TRK-T06.
           INITIALIZE CODICE-XXX.
           MOVE CODICE-ABI        OF ZMRK1022 TO  WA-CAB.
           MOVE CODICE-ABI        OF ZMRK1022 TO  CODICE5.
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE TO CONTRO5 OF CODICE-XXX.
           MOVE CODICE-XXX           TO CODICE-ABI         OF TRK-T06

           INITIALIZE CODICE-XXX.
           MOVE 0 TO WA-CAB
           INITIALIZE DCLTBABFA
           MOVE CVREG-CIST       TO BFA-CIST
           MOVE CVREG-CDPZOPE    TO BFA-DIPOPE
           MOVE CVREG-NUMOPE     TO BFA-NUMOPE
           MOVE 0 TO SQLCODE
           PERFORM LEGGI-TBABFA    THRU EX-LEGGI-TBABFA
           IF SQLCODE  = ZERO
BPO613*       IF BFA-CIRCUITO = 'TGT'
BPO613        IF BFA-CIRCUITO = 'TGT' OR = 'SCT'
                 MOVE 1000           TO WA-CAB
                                     CODICE5
              ELSE
                 IF BFA-CIRCUITO = 'BRL'
                    MOVE BFA-CABIM     TO WA-CAB
                                    CODICE5
                 ELSE
      *------  IF BFA-CIRCUITO  = ' '
                    IF BFA-SWFNDGM  = 'BITA'  AND
                       BFA-SWFPAEM  = 'IT'    AND
                       BFA-SWFREGM  = 'RR'    AND
                       BFA-SWFBCHM  = 'SDP'
                       MOVE 1000      TO WA-CAB
                                    CODICE5
                    ELSE
                       MOVE BFA-CABIM TO WA-CAB
                                   CODICE5
                    END-IF
                 END-IF
              END-IF
           END-IF.
           IF WA-CAB = 0
              MOVE CVREG-CCABFIL TO WA-CAB
              MOVE CVREG-CCABFIL TO CODICE5
           END-IF
           PERFORM CONTR-CODICE THRU EX-CONTR-CODICE.
           MOVE CONTROCODICE TO CONTRO5 OF CODICE-XXX.
           MOVE CODICE-XXX           TO CAB            OF TRK-T06.
           IF CAB OF TRK-T06 = 77784
              MOVE 31112             TO CAB            OF TRK-T06
           END-IF
           IF CVREG-FOPSEGN = ZEROES
              MOVE 2                 TO FLAG-GIA-SEGNALATA OF TRK-T06
           ELSE
              MOVE CVREG-FOPSEGN     TO FLAG-GIA-SEGNALATA OF TRK-T06.


           IF CVREG-FITOEBS = 'E'
              MOVE 1                 TO INCASSO-PAGAMENTO  OF TRK-T06
           ELSE
              MOVE 2                 TO INCASSO-PAGAMENTO  OF TRK-T06.


           MOVE ZERO                 TO TIPO-REGOLAMENTO   OF TRK-T06.
           MOVE CVREG-CVALUIC        TO CODICE-VALUTA-REG  OF TRK-T06.
           MOVE CVREG-IREGOL         TO IMPORTO-VALUTA     OF TRK-T06.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVREG-FLITEU = 'V'
CARA39          COMPUTE WRK-CTV-EURO ROUNDED = CVREG-ICTVREGOL * 1000000
CARA39                                      / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVREG-ICTVREGOL
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        IF CVREG-FLITEU = 'E'
CARA39          COMPUTE WRK-CTV-EURO ROUNDED = CVREG-ICTVREGOL * 1936,27
CARA39                                      / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVREG-ICTVREGOL
CARA39           IF CVREG-ICTVREGOL    < 1
CARA39              MOVE 1 TO CVREG-ICTVREGOL
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVREG-ICTVREGOL      TO IMPORTO-CTV        OF TRK-T06.

           MOVE CODICE-VALUTA-REG OF TRK-T06 TO DIVISA-TITOLO.
VAR002     IF CVREG-CVALUIC = 018 OR = 242
              MOVE ZERO TO IMPORTO-CTV OF TRK-T06.

           MOVE CVREG-IVALUTAINT     TO IMPORTO-VALUTA-INT OF TRK-T06.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVREG-FLITEU = 'V'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVREG-ICTVINT * 1000000
CARA39                                      / 1936,27
CARA39           MOVE WRK-CTV-EURO      TO CVREG-ICTVINT
CARA39        END-IF
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'N' AND CVREG-IVALUTAINT > 0
CARA39        IF CVREG-FLITEU = 'E'
CARA39           COMPUTE WRK-CTV-EURO ROUNDED = CVREG-ICTVINT * 1936,27
CARA39                                      / 1000000
CARA39           MOVE WRK-CTV-EURO      TO CVREG-ICTVINT
CARA39           IF CVREG-ICTVINT      < 1
CARA39              MOVE 1 TO CVREG-ICTVINT
CARA39           END-IF
CARA39        END-IF
CARA39     END-IF
           MOVE CVREG-ICTVINT        TO IMPORTO-CTV-INT    OF TRK-T06.

VAR002     IF CVREG-CVALUIC = 018 OR = 242
              MOVE ZERO TO IMPORTO-CTV-INT OF TRK-T06.

           MOVE CVREG-CMODREG        TO MODALITA-REGOLAMENTO OF TRK-T06.
CARA39     IF WRK-CVS-EURO = 'N'
           IF CVREG-CISO NOT = 'ITL'
              IF CVREG-ICTVREGOL  NOT = 0 AND
                 CVREG-IREGOL     NOT = 0 THEN
                 COMPUTE COMODO-CAMBIO =
                 CVREG-ICTVREGOL  * 1000000 /
                 CVREG-IREGOL
                 MOVE CVREG-CIST    TO COMODO-ISTITUTO
                 MOVE CVREG-CISO    TO COMODO-DIVISA
                 MOVE CVREG-CVALUIC TO COMODO-CMODUIC
                 PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        IF CVREG-ICTVREGOL  NOT = 0 AND
CARA39           CVREG-IREGOL     NOT = 0 THEN
CARA39           COMPUTE COMODO-CAMBIO =
CARA39           CVREG-IREGOL /
CARA39           CVREG-ICTVREGOL
CARA39*          DISPLAY CVREG-NUMREG ' ' COMODO-CAMBIO
CARA39*                  CVREG-IREGOL  ' ' CVREG-ICTVREGOL
CARA39           MOVE CVREG-CIST    TO COMODO-ISTITUTO
CARA39           MOVE CVREG-CISO    TO COMODO-DIVISA
CARA39           MOVE CVREG-CVALUIC TO COMODO-CMODUIC
CARA39           PERFORM AGGIORNA-TABELLA THRU EX-AGGIORNA-TABELLA.

VAR004*    IF WRK-CSEGNAL NOT = SPACES AND
VAR004     IF MODALITA-REGOLAMENTO OF TRK-T06 = 2 OR = 4
TEST  *     DISPLAY 'MODALITA-REGOLAMENTO   '
TEST  *              MODALITA-REGOLAMENTO OF TRK-T06
TEST  *       DISPLAY '    CAB   ' CAB        OF TRK-T06
VAR004        MOVE ZERO TO CODICE-ABI OF TRK-T06
VAR004        MOVE ZERO TO CAB        OF TRK-T06
VAR004     END-IF.

           MOVE ZERO         TO CONTI-MOVIMENTATI  OF TRK-T06.
           MOVE ZERO         TO PROVENIENZA-FONDI  OF TRK-T06.
           MOVE ZERO         TO COPERTURA-RISCHIO  OF TRK-T06.
           MOVE ZERO         TO DATA-CONTRATTO     OF TRK-T06.
           MOVE ZERO         TO CAMBIO             OF TRK-T06.
      *    MOVE ALL '0'      TO FILLER-T06A        OF TRK-T06.
           MOVE ZERO         TO PREMIO-UNITARIO    OF TRK-T06.
      *    MOVE ALL '0'      TO FILLER-T06B        OF TRK-T06.

       EX-PREPARA-T06.

           EXIT.


       PREPARA-T00.

           MOVE 03              TO TIPO-RECORD-CORNICE    OF TRK-T00.
           MOVE 'T00'           TO TIPO-RECORD            OF TRK-T00.
           MOVE ZERO            TO NUMERO-PROGRESSIVO-T00 OF TRK-T00.
      *    MOVE ALL '0'         TO FILLER-1               OF TRK-T00.
           MOVE EL-RIFCVS(INDT)  TO DATA-COMUNICAZIONE    OF TRK-T00.
           MOVE NAPOS-ZRAGSOC    TO DENOMIN-SEGNALA       OF TRK-T00.
DOL   *ANOMALIA SU INDIRIZZO E COMUNE --------
BPO520*    MOVE NAPOS-ZCTA       TO INDIRIZZO-SEGNALANTE  OF TRK-T00.
BPO520     MOVE NAPOS-ZCTA       TO COMUNE-SEGNALANTE     OF TRK-T00.
BPO520     MOVE NAPOS-ZIND       TO INDIRIZZO-SEGNALANTE  OF TRK-T00.
           MOVE CVCNS-PREFISSO   TO PREFISSO-TELEF        OF TRK-T00.
           MOVE CVCNS-NUMTELEF   TO NUMERO-TELEF          OF TRK-T00.

           MOVE NAPOS-ZPAE       TO PARTE-CAP.

           IF W-CAP OF PARTE-CAP NOT NUMERIC
              MOVE ZERO TO CAP-SEGNALANTE  OF TRK-T00
           ELSE
              MOVE W-CAP OF PARTE-CAP TO CAP-SEGNALANTE  OF TRK-T00.

BPO520*    MOVE RESTO-CAP OF PARTE-CAP TO COMUNE-SEGNALANTE OF TRK-T00.

           MOVE ZEROES           TO CAMPI-ZERO           OF TRK-T00.
           MOVE '*'              TO CAMPO-ASTERISCO      OF TRK-T00.
           MOVE SPACES           TO CAMPI-SPAZI          OF TRK-T00.

       EX-PREPARA-T00.

           EXIT.

       PREPARA-T01.

           MOVE 03                TO TIPO-RECORD-CORNICE     OF TRK-T01.
           MOVE 'T01'             TO TIPO-RECORD             OF TRK-T01.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T00  OF TRK-T01.
           MOVE ZERO              TO NUMERO-PROGRESSIVO-T01  OF TRK-T01.
           MOVE ALL '0'           TO FILLER1-T01             OF TRK-T01.
           MOVE SPACES            TO TIPO-SEGNALAZIONE       OF TRK-T01.
           MOVE ZERO              TO CODICE-ABI              OF TRK-T01.
           MOVE ZERO              TO CAB                     OF TRK-T01.
           MOVE TIPO-DICHIARA  OF COM-KEY2 TO
                                  NATURA-OPERAZIONE OF TRK-T01.

           MOVE EL-RIFCVS(INDT)   TO DATA-SEGNALAZIONE     OF TRK-T01.

           MOVE CVCNS-CATTDIV     TO TIPO-OPERATORE        OF TRK-T01.
           MOVE CVCNS-CODMECCPR   TO MECC-SEGNA-PR
           MOVE CVCNS-NUMMECC     TO MECC-SEGNA-NUM.

           IF MECC-SEGNA = '99999999' OR = '88888888' OR
                         = '00000000' OR = '  000000'
              MOVE SPACES         TO COD-MECCANOGRAFICO    OF TRK-T01
           ELSE
              MOVE MECC-SEGNA     TO COD-MECCANOGRAFICO    OF TRK-T01.

           MOVE CVCNS-CSETTATT    TO COD-SOTTOGRUPPO       OF TRK-T01.
           MOVE CVCNS-CRAMOATT    TO COD-BRANCA            OF TRK-T01.
           MOVE CVCNS-IFATTURATO  TO FATTURATO             OF TRK-T01.
           MOVE CVCNS-IFATTESP    TO VENDITE-V-ESTERO      OF TRK-T01.
           MOVE CVCNS-IFATTIMP    TO ACQUISTI-D-ESTERO     OF TRK-T01.
           MOVE CVCNS-NUMADDETTI  TO NUMERO-ADDETTI        OF TRK-T01.

VAR003*    IF NUMERO-ADDETTI OF TRK-T01 = 0
VAR003*       MOVE 1 TO NUMERO-ADDETTI OF TRK-T01
VAR003*    END-IF.
VAR003*    IF NUMERO-ADDETTI OF TRK-T01 = 2
VAR003*       MOVE 5 TO NUMERO-ADDETTI OF TRK-T01
VAR003*    END-IF.
VAR003*    IF NUMERO-ADDETTI OF TRK-T01 = 3
VAR003*       MOVE 7 TO NUMERO-ADDETTI OF TRK-T01
VAR003*    END-IF.

           MOVE CVCNS-FAREAPREV   TO PARTECIPAZIONI        OF TRK-T01.

VAR003*    IF PARTECIPAZIONI OF TRK-T01 = 1
VAR003*       MOVE 4 TO PARTECIPAZIONI OF TRK-T01.
VAR003*    IF PARTECIPAZIONI OF TRK-T01 = 2
VAR003*       MOVE 5 TO PARTECIPAZIONI OF TRK-T01.
VAR003*    IF PARTECIPAZIONI OF TRK-T01 = 3 OR = ZERO
VAR003*       MOVE 6 TO PARTECIPAZIONI OF TRK-T01.

           MOVE CVCNS-CPAECASUIC  TO PAESE-CASAMADRE       OF TRK-T01.

BAPV  *    MOVE CVCNS-FLITEU      TO LIRA-EURO             OF TRK-T01.
BAPV       MOVE 'E'               TO LIRA-EURO             OF TRK-T01.

           IF TIPO-OPERATORE  OF TRK-T01  NOT = 0
              MOVE SPACES TO COD-MECCANOGRAFICO OF TRK-T01
              MOVE ZERO   TO COD-SOTTOGRUPPO    OF TRK-T01
                             PARTECIPAZIONI     OF TRK-T01
BPAV  *                      PAESE-CASAMADRE    OF TRK-T01.
BPAV                         PAESE-CASAMADRE    OF TRK-T01
BPAV          IF CVCNS-FLITEU = SPACES
BAPV             MOVE 'E' TO LIRA-EURO          OF TRK-T01.

           IF (COD-SOTTOGRUPPO OF TRK-T01 NOT < 430 AND NOT > 492)
              OR
              (COD-SOTTOGRUPPO OF TRK-T01 = 614 OR = 615)
              NEXT SENTENCE
           ELSE
              MOVE ZERO TO COD-BRANCA OF TRK-T01
                           FATTURATO  OF TRK-T01
                           VENDITE-V-ESTERO OF TRK-T01
                           ACQUISTI-D-ESTERO OF TRK-T01
                           NUMERO-ADDETTI OF TRK-T01
           END-IF.

       EX-PREPARA-T01.

           EXIT.

       ERRORE-NDG-CVSM.

           INITIALIZE AREA-ERR.

           MOVE CVMER-CIST                 TO ISTITUTO      OF ZMRK1026.
           MOVE CVMER-CCABFIL              TO FIL-EMISS     OF ZMRK1026.
           MOVE EL-RIFCVS(INDT)            TO MESE-RIF-CVS  OF ZMRK1026.
           MOVE EL-DOGG (INDT)             TO DOGG-K        OF ZMRK1026.

           MOVE '1'                  TO TIPO-ERRORE         OF ZMRK1026.
           MOVE CVMER-CRIFCLI        TO RIF-CLIENTE         OF ZMRK1026.
           MOVE CVMER-CCAB           TO COD-ABI             OF ZMRK1026.
           MOVE CVMER-CCABFIL        TO CABFIL              OF ZMRK1026.
           MOVE CVMER-CPRECVS        TO WRK-CPRECVS
           MOVE CVMER-NUMCVS         TO WRK-NUMCVS
           MOVE WRK-NUMERO           TO NUMDICH             OF ZMRK1026.
           MOVE CVMER-CSTADICH       TO STATO-DICHIARA      OF ZMRK1026.
           MOVE CVMER-CSEGNAL        TO SEGNALANTE          OF ZMRK1026.
           MOVE CVMER-NNDGSET        TO COD-OPERATORE       OF ZMRK1026.
           MOVE CVMER-CTIPDICH       TO TIPO-DICHIARAZIONE  OF ZMRK1026.

           MOVE 'ERR-ACVMER'         TO NOME-FILE           OF ZMRK1026.
           WRITE ZMRK1026.

       EX-ERRORE-NDG-CVSM.

           EXIT.

       ERRORE-NDG-CVSN.

           INITIALIZE AREA-ERR.

           MOVE CVNME-CIST                 TO ISTITUTO      OF ZMRK1026.
           MOVE CVNME-CCABFIL              TO FIL-EMISS     OF ZMRK1026.
           MOVE EL-RIFCVS(INDT)            TO MESE-RIF-CVS  OF ZMRK1026.
           MOVE EL-DOGG(INDT)              TO DOGG-K        OF ZMRK1026.

           MOVE '1'                  TO TIPO-ERRORE         OF ZMRK1026.
           MOVE CVNME-CRIFCLI        TO RIF-CLIENTE         OF ZMRK1026.
           MOVE CVNME-CCAB           TO COD-ABI             OF ZMRK1026.
           MOVE CVNME-CCABFIL        TO CABFIL              OF ZMRK1026.
           MOVE CVNME-CPRECVS        TO WRK-CPRECVS
           MOVE CVNME-NUMCVS         TO WRK-NUMCVS
           MOVE WRK-NUMERO           TO NUMDICH             OF ZMRK1026.
           MOVE CVNME-CSTADICH       TO STATO-DICHIARA      OF ZMRK1026.
           MOVE CVNME-CSEGNAL        TO SEGNALANTE          OF ZMRK1026.
           MOVE CVNME-NNDGSET        TO COD-OPERATORE       OF ZMRK1026.
           MOVE CVNME-CTIPDICH       TO TIPO-DICHIARAZIONE  OF ZMRK1026.

           MOVE 'ERR-ACVNME'         TO NOME-FILE           OF ZMRK1026.
           WRITE ZMRK1026.

       EX-ERRORE-NDG-CVSN.

           EXIT.

       ERRORE-NDG-CVSF.

           INITIALIZE AREA-ERR.

           MOVE CVFIN-CIST                 TO ISTITUTO      OF ZMRK1026.
           MOVE CVFIN-CCABFIL              TO FIL-EMISS     OF ZMRK1026.
           MOVE EL-RIFCVS(INDT)            TO MESE-RIF-CVS  OF ZMRK1026.
           MOVE EL-DOGG(INDT)              TO DOGG-K        OF ZMRK1026.

           MOVE '1'                  TO TIPO-ERRORE         OF ZMRK1026.
           MOVE CVFIN-CRIFCLI        TO RIF-CLIENTE         OF ZMRK1026.
           MOVE CVFIN-CCAB           TO COD-ABI             OF ZMRK1026.
           MOVE CVFIN-CCABFIL        TO CABFIL              OF ZMRK1026.
           MOVE CVFIN-CPRECVS        TO WRK-CPRECVS
           MOVE CVFIN-NUMCVS         TO WRK-NUMCVS
           MOVE WRK-NUMERO           TO NUMDICH             OF ZMRK1026.
           MOVE CVFIN-CSTADICH       TO STATO-DICHIARA      OF ZMRK1026.
           MOVE CVFIN-CSEGNAL        TO SEGNALANTE          OF ZMRK1026.
           MOVE CVFIN-NNDGSET        TO COD-OPERATORE       OF ZMRK1026.


           MOVE ZEROES               TO NUMREGOL            OF ZMRK1026.
           MOVE CVFIN-CTIPDICH       TO TIPO-DICHIARAZIONE  OF ZMRK1026.

           MOVE 'ERR-ACVFIN'         TO NOME-FILE           OF ZMRK1026.
           WRITE ZMRK1026.

       EX-ERRORE-NDG-CVSF.

           EXIT.

       ERRORE-NDG-CVSC.

           INITIALIZE AREA-ERR.

           MOVE CVCMP-CIST                 TO ISTITUTO      OF ZMRK1026.
           MOVE CVCMP-CCABFIL              TO FIL-EMISS     OF ZMRK1026.
           MOVE EL-RIFCVS(INDT)            TO MESE-RIF-CVS  OF ZMRK1026.
           MOVE EL-DOGG(INDT)              TO DOGG-K        OF ZMRK1026.

           MOVE '1'                  TO TIPO-ERRORE         OF ZMRK1026.
           MOVE CVCMP-CRIFCLI        TO RIF-CLIENTE         OF ZMRK1026.
           MOVE CVCMP-CCAB           TO COD-ABI             OF ZMRK1026.
           MOVE CVCMP-CCABFIL        TO CABFIL              OF ZMRK1026.
           MOVE CVCMP-CPRECVS        TO WRK-CPRECVS
           MOVE CVCMP-NUMCVS         TO WRK-NUMCVS
           MOVE WRK-NUMERO           TO NUMDICH             OF ZMRK1026.
           MOVE CVCMP-CSTADICH       TO STATO-DICHIARA      OF ZMRK1026.
           MOVE CVCMP-CSEGNAL        TO SEGNALANTE          OF ZMRK1026.
           MOVE CVCMP-NNDGSET        TO COD-OPERATORE       OF ZMRK1026.
           MOVE CVCMP-CTIPDICH       TO TIPO-DICHIARAZIONE  OF ZMRK1026.

           MOVE 'ERR-ACVCMP'         TO NOME-FILE           OF ZMRK1026.
           WRITE ZMRK1026.

       EX-ERRORE-NDG-CVSC.

           EXIT.

       ERRORE-NDG-REGM.

           INITIALIZE AREA-ERR.

           MOVE CVMER-CIST                 TO ISTITUTO      OF ZMRK1026.
           MOVE CVREG-CDPZOPE              TO FIL-EMISS     OF ZMRK1026.
           MOVE EL-RIFCVS(INDT)            TO MESE-RIF-CVS  OF ZMRK1026.
           MOVE EL-DOGG(INDT)              TO DOGG-K        OF ZMRK1026.
           MOVE '1'                  TO TIPO-ERRORE         OF ZMRK1026.

           MOVE CVREG-CDPZOPE        TO RIFOPE-CDPZ         OF ZMRK1026.
           MOVE CVREG-NUMOPE         TO RIFOPE-NUMOPE       OF ZMRK1026.
           MOVE CVREG-CRIFOPE        TO RIF-OPER-ESTERO     OF ZMRK1026.
           MOVE CVMER-CRIFCLI        TO RIF-CLIENTE         OF ZMRK1026.
           MOVE CVMER-CCAB           TO COD-ABI             OF ZMRK1026.
           MOVE CVMER-CCABFIL        TO CABFIL              OF ZMRK1026.
           MOVE CVMER-CPRECVS        TO WRK-CPRECVS
           MOVE CVMER-NUMCVS         TO WRK-NUMCVS
           MOVE WRK-NUMERO           TO NUMDICH             OF ZMRK1026.
           MOVE CVMER-CSTADICH       TO STATO-DICHIARA      OF ZMRK1026.
           MOVE CVMER-CSEGNAL        TO SEGNALANTE          OF ZMRK1026.
           MOVE CVMER-NNDGSET        TO COD-OPERATORE       OF ZMRK1026.
           MOVE CVREG-NUMREG         TO NUMREGOL            OF ZMRK1026.
           MOVE CVMER-CTIPDICH       TO TIPO-DICHIARAZIONE  OF ZMRK1026.
           MOVE CVREG-DVALNOA        TO DVAL-REG            OF ZMRK1026.
           MOVE CVREG-CISO           TO DIV-IMP-CAP         OF ZMRK1026.
           MOVE CVREG-IREGOL         TO IMP-CAP             OF ZMRK1026.

           MOVE 'ERR-ACVREG'         TO NOME-FILE           OF ZMRK1026.
           WRITE ZMRK1026.

       EX-ERRORE-NDG-REGM.

           EXIT.

       CONTR-CODICE.

           COMPUTE A1 = E * 2
           COMPUTE A2 = C * 2
           COMPUTE A3 = A * 2

           MOVE A1 TO L.
           MOVE D  TO I2.
           MOVE A2 TO H.
           MOVE B  TO G.
           MOVE A3 TO F1.

           MOVE CAMPO3 TO CAMPO5.

           COMPUTE A4 =   S + T
           COMPUTE A5 =   R1 + A4
           COMPUTE A6 =   Q + A5
           COMPUTE A7 =   P + A6
           COMPUTE A8 =   O + A7
           COMPUTE A9 =   N1 + A8
           COMPUTE A10 =  M + A9

           MOVE A10 TO CAMPO7.
           COMPUTE A11 = 1 + X.
           MOVE A11 TO K.
           COMPUTE A12 = A10 - CAMPO9.

           IF A12 = 10
              MOVE 0 TO CONTROCODICE
           ELSE
              MOVE A12 TO CONTROCODICE.

       EX-CONTR-CODICE.

            EXIT.

       AGGIORNA-TABELLA.

           SET INDC TO 1.
           SEARCH  CAMBI
             AT END
                MOVE COMODO-CAMBIO   TO CAMBIO   OF CAMBI (WINDC)
                MOVE 1               TO GIORNI   OF CAMBI (WINDC)
                MOVE COMODO-ISTITUTO TO ISTITUTO OF CAMBI (WINDC)
                MOVE COMODO-DIVISA   TO DIVISA   OF CAMBI (WINDC)
                MOVE COMODO-CMODUIC  TO CMODUIC  OF CAMBI (WINDC)
                ADD 1 TO WINDC
                IF WINDC > 500
                   MOVE 23 TO COMP-CODE
                   DISPLAY 'AMPLIARE TABELLA CAMBI'
                   CALL ILBOABN0 USING COMP-CODE
                END-IF
             WHEN DIVISA OF CAMBI (INDC) = COMODO-DIVISA AND
                  ISTITUTO OF CAMBI(INDC) = COMODO-ISTITUTO
               ADD COMODO-CAMBIO TO CAMBIO OF CAMBI (INDC)
               ADD 1             TO GIORNI OF CAMBI (INDC)
             END-SEARCH.

       EX-AGGIORNA-TABELLA.

           EXIT.

       SCRIVI-FILE-DIVISE.

           MOVE ISTITUTO OF CAMBI (WINDC) TO ISTITUTO OF ZMRK1027.
           MOVE DIVISA   OF CAMBI (WINDC) TO DIVISA   OF ZMRK1027.
           MOVE CMODUIC  OF CAMBI (WINDC) TO CMODUIC  OF ZMRK1027.

           COMPUTE COMODO-CAMBIO = CAMBIO OF CAMBI (WINDC) /
                                   GIORNI OF CAMBI (WINDC).

           MOVE COMODO-CAMBIO      TO CAMBIO   OF ZMRK1027.
CARA39     IF WRK-CVS-EURO = 'N'
CARA39        MOVE 'V'             TO FLAG-LIRA-EURO OF ZMRK1027
CARA39     END-IF
CARA39     IF WRK-CVS-EURO = 'S'
CARA39        MOVE 'E'             TO FLAG-LIRA-EURO OF ZMRK1027
CARA39     END-IF
FAA        MOVE ISTITUTO OF ZMRK1027   TO DIV-CIST
FAA        MOVE DIVISA   OF ZMRK1027   TO DIV-CISO
FAA        PERFORM LEGGI-ADIV THRU EX-LEGGI-ADIV
FAA        IF DIV-FINOUT < 4
FAA           GO TO EX-SCRIVI-FILE-DIVISE
FAA        END-IF
FAA        WRITE ZMRK1027.

       EX-SCRIVI-FILE-DIVISE.

           EXIT.
FAA    LEGGI-ADIV.
FAA
FAA        EXEC SQL INCLUDE ZMS10101 END-EXEC.
FAA
FAA        IF SQLCODE NOT = ZERO AND NOT = +100
FAA           MOVE 8 TO COMP-CODE
FAA           DISPLAY 'ERRORE ZMS10101 '
FAA           PERFORM ERRORE-DB2 THRU FINE-DB2
FAA        END-IF.
FAA
FAA    EX-LEGGI-ADIV.
FAA
FAA        EXIT.

       CARICA-SEGNALANTE.

           INITIALIZE AREA-KEY2.
           INITIALIZE TRK-T00.
           MOVE  'T00' TO TIPO-REC-UIC   OF AREA-KEY2.

           MOVE ZERO TO INDICE VERIFICA.
           MOVE SPACES TO DENOMINAZ W-INDIRIZZO W-COMUNE.

           MOVE EL-CIST(INDT)  TO CIST  OF AREA-KEY2.

       LBL-SS.

           ADD 1 TO INDICE.
TEST  *    DISPLAY 'INDICE     'INDICE
TEST  *    DISPLAY 'LEN-OCCURS 'LEN-OCCURS
           IF INDICE > LEN-OCCURS
              MOVE 24 TO COMP-CODE
              DISPLAY 'MANCA ISTITUTO SU COPY ZMDVGI01'
              CALL ILBOABN0 USING COMP-CODE.

           IF TAB-IST OF KEY-TAB (INDICE) NOT = WCM-CIST
               GO TO LBL-SS.

           IF TAB-COD OF KEY-TAB (INDICE) = 1
              MOVE TAB-TRK1 (INDICE) TO DENOMINAZ(1:35)
              ADD 1 TO VERIFICA
              GO TO LBL-SS.

           IF TAB-COD OF KEY-TAB (INDICE) = 2
              MOVE TAB-TRK2 (INDICE) TO DENOMINAZ(36:15)
              ADD 2 TO VERIFICA
              GO TO LBL-SS.

           IF TAB-COD OF KEY-TAB (INDICE) NOT = 3
              GO TO LBL-SS1.

           IF PREFISSO OF TAB-TRK3 (INDICE) NOT NUMERIC
              MOVE 25 TO COMP-CODE
              DISPLAY 'PREFISSO NON NUMERICO SU COPY ZMDVGI01'
              CALL ILBOABN0 USING COMP-CODE.

           IF TELEFONO OF TAB-TRK3 (INDICE) NOT NUMERIC
              MOVE 26 TO COMP-CODE
              DISPLAY 'TELEFONO NON NUMERICO SU COPY ZMDVGI01'
              CALL ILBOABN0 USING COMP-CODE.

           IF CAP      OF TAB-TRK3 (INDICE) NOT NUMERIC
              MOVE 27 TO COMP-CODE
              DISPLAY 'CAP NON NUMERICO SU COPY ZMDVGI01'
              CALL ILBOABN0 USING COMP-CODE.

           MOVE PREFISSO OF TAB-TRK3 (INDICE) TO
                            PREFISSO-TELEF      OF TRK-T00.
           MOVE TELEFONO OF TAB-TRK3 (INDICE) TO
                            NUMERO-TELEF        OF TRK-T00.
           MOVE CAP      OF TAB-TRK3 (INDICE) TO
                            CAP-SEGNALANTE      OF TRK-T00.
           ADD 3 TO VERIFICA.
           GO TO LBL-SS.

       LBL-SS1.

           IF TAB-COD OF KEY-TAB (INDICE)  = 4
              MOVE TAB-TRK4 (INDICE) TO W-COMUNE
              ADD 4 TO VERIFICA
              GO TO LBL-SS.

           IF TAB-COD OF KEY-TAB (INDICE)  = 5
              MOVE TAB-TRK5 (INDICE) TO W-INDIRIZZO
              ADD 5 TO VERIFICA
              GO TO LBL-SS.

           IF TAB-COD OF KEY-TAB (INDICE)  NOT = 6
              MOVE 28 TO COMP-CODE
              DISPLAY 'MANCA RECORD 6 SU COPY ZMDVGI01'
              CALL ILBOABN0 USING COMP-CODE.

           IF INVIANTE OF TAB-TRK6 (INDICE) NOT NUMERIC
              MOVE 29 TO COMP-CODE
              DISPLAY 'INVIANTE NON NUMERICO SU COPY ZMDVGI01'
              CALL ILBOABN0 USING COMP-CODE.

           ADD 6 TO VERIFICA

           IF VERIFICA NOT = 21
              MOVE 30 TO COMP-CODE
              DISPLAY 'MANCANO TRK SU COPY ZMDVGI01'
              CALL ILBOABN0 USING COMP-CODE.

            MOVE  03             TO TIPO-RECORD-CORNICE    OF TRK-T00.
            MOVE  'T00'          TO TIPO-RECORD            OF TRK-T00.
            MOVE ZERO            TO NUMERO-PROGRESSIVO-T00 OF TRK-T00.
      *     MOVE ALL '0'         TO FILLER-1               OF TRK-T00.
            MOVE EL-RIFCVS(INDT) TO DATA-COMUNICAZIONE    OF TRK-T00.
            MOVE DENOMINAZ       TO DENOMIN-SEGNALA
            MOVE W-COMUNE        TO COMUNE-SEGNALANTE
            MOVE W-INDIRIZZO     TO INDIRIZZO-SEGNALANTE  OF TRK-T00.
            MOVE ZEROES          TO CAMPI-ZERO            OF TRK-T00.
            MOVE '*'             TO CAMPO-ASTERISCO       OF TRK-T00.
            MOVE SPACES          TO CAMPI-SPAZI           OF TRK-T00.

           MOVE TRK-T00 TO AREA-UIC2.
           WRITE ZMRK1021.

       EX-CARICA-SEGNALANTE.

           EXIT.

       ERRORE-DB2.

           MOVE 31 TO COMP-CODE.
           MOVE SQLCODE TO COD-DB2.

           IF SQLCODE IS NEGATIVE
              MOVE '-' TO SEGNO-DB2
           ELSE
              MOVE '+' TO SEGNO-DB2.

           DISPLAY 'STATUS CODE : ' ERR-DB2.
           CALL ILBOABN0 USING COMP-CODE .

       FINE-DB2.

           EXIT.

           COPY DVWCI043.
      *
           EXIT.
       CHIAMA-ANAGRAFE.
           MOVE NAPOS-NNDGSET TO WRK-NDGESTE
           PERFORM ELABORA-BPT THRU ELABORA-BPT-END
           IF L-ACS908-RET-CODE NOT = ZEROES
              IF L-ACS908-RET-CODE  = 4 OR 6 OR 9
                 MOVE L-ACS908-SQLCODE            TO  W-SQLCODE
                 MOVE L-ACS908-SQLMSG             TO  AREA-DESCERR
              ELSE
                 MOVE +100                        TO  W-SQLCODE
                 MOVE 'CHIAVE ANAGRAFICA ASSENTE' TO  AREA-DESCERR
              END-IF
           END-IF.
           IF L-ACS908-FLAG-CLIENTE  = '2'
              EXEC SQL INCLUDE ZMS10801  END-EXEC
              IF SQLCODE NOT = ZERO AND NOT = +100
                 MOVE 6 TO COMP-CODE
                 DISPLAY 'ERRORE DB2 ZMS10800'
                 PERFORM ERRORE-DB2 THRU FINE-DB2
              END-IF

              IF SQLCODE = +100
                 DISPLAY 'CPG  ' NAPOS-NNDGSET
                 DISPLAY 'NDG BANCA NON CENSITO'
              END-IF
           END-IF.
           PERFORM VALORIZZA-NAPOS THRU VALORIZZA-NAPOS-END.
        CHIAMA-ANAGRAFE-END.
           EXIT.
       ELABORA-BPT.
           INITIALIZE L-ACS908-ARG.
           MOVE 'A'              TO L-ACS908-I-TIPO-RICH.
           PERFORM TRATTA-NDG THRU TRATTA-NDG-END
           MOVE WRK-NDG-16-N      TO L-ACS908-I-NDG.
           MOVE 'ACS908EE' TO WCM-CHIAMATO.
           CALL WCM-CHIAMATO USING L-ACS908-ARG
           .
       ELABORA-BPT-END.
           EXIT.
       TRATTA-NDG.
           PERFORM VARYING INDICE1 FROM 1 BY 1
                   UNTIL WRK-NDGESTE(INDICE1:1) = SPACE
                   OR INDICE1 > 16
           END-PERFORM.
           SUBTRACT 1 FROM INDICE1
           COMPUTE INDICE2 = 16 - INDICE1 + 1
           MOVE ALL '0' TO WRK-NDG-16-X
           MOVE WRK-NDGESTE(1:INDICE1) TO WRK-NDG-16-X(INDICE2:INDICE1).
       TRATTA-NDG-END.
           EXIT.
       VALORIZZA-NAPOS.
           MOVE WRK-NDGESTE           TO NAPOS-NNDGANG
ANAGRI*    MOVE L-ACS908-RAGSOC-1     TO NAPOS-ZRAGSOC
"     *    MOVE L-ACS908-IND-SEDE-LEG TO NAPOS-ZIND
"     *    MOVE L-ACS908-LOC-SEDE-LEG TO NAPOS-ZCTA
"     *    MOVE L-ACS908-NAZ-SEDE-LEG TO NAPOS-ZPAE
"
           IF   L-ACS908-INT-PART1 NOT = SPACES
"               MOVE L-ACS908-INT-PART1 TO  NAPOS-ZRAGSOC
"               MOVE L-ACS908-IND-PART  TO  NAPOS-ZIND
"               MOVE L-ACS908-LOC-PART  TO  NAPOS-ZCTA
ANAGRI*         MOVE L-ACS908-CAP-PART  TO
BPO520          MOVE L-ACS908-CAP-PART  TO W-CAP
ANAGRI          IF   L-ACS908-NAZ-PART NOT = SPACES
"                    MOVE L-ACS908-NAZ-PART TO ACZ023-COD-NAZ
"                    PERFORM CALL-ACZ023CX THRU
"                            CALL-ACZ023CX-END
"                    IF ACZ023-RETCOD = ZERO
"                       MOVE ACZ023-DESCR-BREVE      TO NAPOS-ZPAE
"                    END-IF
"               END-IF
"          ELSE
"               MOVE L-ACS908-INT-POSTALE1 TO  NAPOS-ZRAGSOC
"               MOVE L-ACS908-IND-POSTALE  TO  NAPOS-ZIND
"               MOVE L-ACS908-LOC-POSTALE  TO  NAPOS-ZCTA
ANAGRA*         MOVE L-ACS908-CAP-POSTALE  TO
BPO520          MOVE L-ACS908-CAP-POSTALE  TO W-CAP
ANAGRA          IF   L-ACS908-NAZ-POSTALE NOT = SPACES
"                    MOVE L-ACS908-NAZ-POSTALE TO ACZ023-COD-NAZ
"                    PERFORM CALL-ACZ023CX THRU
"                            CALL-ACZ023CX-END
"                    IF ACZ023-RETCOD = ZERO
"                       MOVE ACZ023-DESCR-BREVE        TO NAPOS-ZPAE
"                    END-IF
"               END-IF
"          END-IF
           IF   L-ACS908-FLAG-STATO  = 'C'
                MOVE 1 TO NAPOS-FCNS
           END-IF
           IF   L-ACS908-FLAG-STATO  = 'B'
                MOVE 3 TO NAPOS-FCNS
           END-IF
           IF   L-ACS908-FLAG-STATO  = 'P'
                MOVE 2 TO NAPOS-FCNS
           END-IF
           IF   L-ACS908-FLAG-STATO  = 'E'
                MOVE 8 TO NAPOS-FCNS
           END-IF
           MOVE L-ACS908-A-DT-VAL-DA  TO NAPOS-DVARNDG
           IF   L-ACS908-FLAG-CLIENTE = '1'
                MOVE 1 TO NAPOS-TNDGSET
ANAGRA*         IF L-ACS908-FIG-GIUR  = '1'
      *            PERFORM TRATTA-NOME-COGNOME THRU
      *                    TRATTA-NOME-COGNOME-END
      *            MOVE WRK-NOMCOG          TO NAPOS-ZRAGSOC
      *         END-IF
           ELSE
                MOVE 2 TO NAPOS-TNDGSET
           END-IF
           MOVE L-ACS908-FILIALE-PRINC             TO WRK-CDPZ-X
           MOVE WRK-CDPZ-N                         TO NAPOS-CFILCNS
           IF L-ACS908-COD-FISCALE NOT = SPACES
              MOVE L-ACS908-COD-FISCALE            TO NAPOS-CFISPIV
           ELSE
              MOVE L-ACS908-PARTITA-IVA            TO NAPOS-CFISPIV
           END-IF
           MOVE  1                                 TO NAPOS-FRSDDOP
           MOVE    L-ACS908-NAZ-ISO-CODE           TO NAPOS-CSIGPEND
           MOVE    L-ACS908-FLAG-RESIDENZA         TO NAPOS-FRSD
           MOVE L-ACS908-NUOVO-RAE(2:3)            TO WRK-RAEGAE(1:3)
           MOVE L-ACS908-NUOVO-GUE                 TO WRK-RAEGAE(4:4)
           MOVE WRK-RAEGAE                         TO NAPOS-CSTTRAM
           MOVE 'EUR'                              TO NAPOS-CSIGDSPS
           MOVE L-ACS908-R-COD-VALUTA              TO NAPOS-CISOCC
           MOVE L-ACS908-NUMERO                    TO NAPOS-NCCO
           MOVE L-ACS908-NUMERO                    TO NAPOS-NCCO13
           MOVE 00                                 TO NAPOS-CSTATODEL
           MOVE SPACES                             TO NAPOS-NNDGSTGR
           MOVE L-ACS908-FIG-GIUR                  TO NAPOS-TIPOFIGURA
           MOVE  L-ACS908-COM-BKT-CAB              TO NAPOS-CCAB
           MOVE  1                                 TO NAPOS-FSMISTA
           MOVE  1                                 TO NAPOS-CLIN
           .
       VALORIZZA-NAPOS-END.
           EXIT.
ANAGRA*TRATTA-NOME-COGNOME.
      *    PERFORM VARYING INDICE1 FROM 30 BY -1
      *            UNTIL L-ACS908-NOME(INDICE1:1) NOT = SPACE
      *            OR INDICE1 = 0
      *    END-PERFORM.
      *    MOVE INDICE1 TO WRK-IND-NOME.
      *    PERFORM VARYING INDICE1 FROM 30 BY -1
      *            UNTIL L-ACS908-COGNOME(INDICE1:1) NOT = SPACE
      *            OR INDICE1 = 0
      *    END-PERFORM.
      *    MOVE INDICE1 TO WRK-IND-COGNOME.
      *    MOVE L-ACS908-NOME(1:WRK-IND-NOME) TO
      *            WRK-NOMCOG(1:WRK-IND-NOME)
      *    ADD 2 TO WRK-IND-NOME.
      *    MOVE L-ACS908-COGNOME(1:WRK-IND-COGNOME) TO
      *            WRK-NOMCOG(WRK-IND-NOME:).
      *TRATTA-NOME-COGNOME-END.
      *    EXIT.
ANAGRA CALL-ACZ023CX.
LP0812***  MOVE 'ACZ023CX' TO WCM-CHIAMATO.
LP0812     MOVE 'ACZ023BT' TO WCM-CHIAMATO.
           CALL WCM-CHIAMATO USING ACZ023A
"          IF  ACZ023-RETCOD      > 1
"              MOVE ACZ023-SQLCODE                 TO  W-SQLCODE
"              MOVE 'ERRORE DECOD.PAESE UIC'       TO  AREA-DESCERR
"     *        GO TO FINE
"          END-IF.
"      CALL-ACZ023CX-END.
"          EXIT.
      *
       LEGGI-TBABFA.
           EXEC SQL INCLUDE ZMS66901 END-EXEC.

           IF SQLCODE NOT = ZERO AND NOT = +100
              MOVE 10 TO COMP-CODE
              DISPLAY 'ERRORE ZMS66901 '
              PERFORM ERRORE-DB2 THRU FINE-DB2
           END-IF.
           IF SQLCODE = +100
              DISPLAY 'OPERAZIONE NON TROVATA SU BFA : '
              CVREG-CDPZOPE ' ' CVREG-NUMOPE
           END-IF.
       EX-LEGGI-TBABFA.
           EXIT.
