       IDENTIFICATION DIVISION.
       PROGRAM-ID.    ZMPDC056.
       AUTHOR.        DATAMAT SPA.
      *================================================================*
      * PRODOTTO...................................................... *
      * SISEB 3 - BATCH                                                *
      * OGGETTO....................................................... *
      *----------------------------------------------------------------*
      * ZMPDC056                                                       *
      *----------------------------------------------------------------*
      *          STAMPA  ESTRATTI  CONTO  GIORNALIERI                  *
      *          VERSIONE MULTIBANCA                                   *
      *  EX-ESPBN034 -                                                 *
      *----------------------------------------------------------------*
      * DATA.... PRG.. AUTORE DESCRIZIONE MODIFICA.................... *
      * 08022003 0089A SAF    CHIAMARE LE ROUTINE SIA BATCH CHE ON LINE*
      * 01061999 00045        MODIFICA PER DIVISE NON LIRE-EURO
      * 17021999 00044 VAC    MODIFICA STABELLAMENTI                   *
      * 29121998 A0005 CRM    MODIFICA CAMPO-25 X EURO                 *
      * 26111998 A0004 DEM    MODIFICA NCON                            *
      * 23101998 A0003 DPS    GESTIONE CORRETTA CONTATORE OPERAZIONE   *
      * 08091998 A0001 CRM    VALORIZZAZIONE DI TIP-092                *
      * 11061998 00028 BUA    GESTIONE ABEND ILBOABN0                  *
      * 11061998 00023 BUA    ELIMINAZIONE COMMIT                      *
      * 04061998 00023 CRM    ELIMINAZIONE COMMIT                      *
      * 01061998 00029 CUA    INSERIMENTO COD.IST. R.1 COL.2 DI STAMPA *
      * 24051998 00022 CRM    VALORIZZAZIONE DI UTENO_CTROPE7          *
      * 19121997 00014 LAA    NOMENCLATURA  TRK  RECORD                *
      * 12121997 00005 LAA    GESTIONE SFORAMENTO TABELLE DI WORKING   *
      * 12121997 00005 LAA    GESTIONE SFORAMENTO TB.     DI WORKING   *
      * 12121997 00001 LAA    GESTIONE SC SU 5 POSIZIONI               *
      * 12121997 00000 LAA    CREAZIONE OGGETTO                        *
      * 20092006 BPO416       INSERIMENTO PGM NEL BATCH SERALE         *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *
           SELECT ZMUN0561 ASSIGN TO ZMUN0561.
           SELECT ZMUN0562 ASSIGN TO ZMUN0562.
           SELECT ZMUN0563 ASSIGN TO ZMUN0563.
           SELECT ZMUN0564 ASSIGN TO ZMUN0564.
           SELECT ZMUS0565 ASSIGN TO ZMUS0565.
           SELECT ZMUS0566 ASSIGN TO ZMUS0566.
           SELECT ZMUS0567 ASSIGN TO ZMUS0567.
           SELECT ZMUN0568 ASSIGN TO ZMUN0568.
           SELECT ZMUN0569 ASSIGN TO ZMUN0569.
           SELECT ZMUN056A ASSIGN TO ZMUN056A.
      *
       DATA DIVISION.
       FILE SECTION.
      *
      ***************************************************************
      *               TESTATA ESTRATTI GIORNALIERI                  *
      ***************************************************************
      *
       FD  ZMUN0561 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0561.
           03  TESTATA.
               05  CIST           PIC 9(004).
               05  CTIPSTC        PIC 9(003).
               05  CSTC           PIC S9(005)   COMP-3.
               05  CISO           PIC X(003).
               05  NNDGSET        PIC 9(009)         COMP-3.
               05  NSUFABT        PIC 9(002).
               05  DPZMTT         PIC 9(005).
           03  DULTESTR           PIC 9(009)         COMP-3.
           03  NUM-ESTR           PIC 9(007)         COMP-3.
           03  SALDO-ESTR         PIC S9(015)V9(003) COMP-3.
           03  FILLER             PIC X(016).
      *
      ***************************************************************
      *                    MOVIMENTI  E  SALDI                      *
      ***************************************************************
      *
       FD  ZMUN0562 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0562.
           03  TESTATA.
               05  CIST-T         PIC 9(004).
               05  DPZCPZ-T       PIC 9(005).
               05  DPZDES-T       PIC 9(005).
               05  DPZMTT-T       PIC 9(005).
               05  NPRGOPE-T      PIC 9(007)         COMP-3.
               05  TRK-T          PIC 9(004).
               05  NMOV-T         PIC 9(004).
               05  LITVAL-T       PIC 9(001).
               05  OPERAZIONE     PIC X(300).
               05  OPER-R  REDEFINES OPERAZIONE.
                   07  FILLER     PIC X(056).
                   07  DESCOPE    PIC 9(009)         COMP-3.
                   07  FILLER     PIC X(239).
BAVC27*    03  DATI-V             PIC X(726).
BAVC27     03  DATI-V             PIC X(746).
           03  DATI-TRK1   REDEFINES DATI-V.
               05  BOLLI          PIC 9(001) OCCURS 4.
BAVC27*        05  MOVIMENTO      PIC X(230).
BAVC27         05  MOVIMENTO      PIC X(250).
               05  MOV-R  REDEFINES MOVIMENTO.
                   07  FILLER     PIC X(067).
                   07  IMOV       PIC S9(15)V9(003)  COMP-3.
                   07  FILLER     PIC X(067).
                   07  NPRNCCO    PIC 9(007)         COMP-3.
                   07  FILLER     PIC X(082).
               05  LORORIF        PIC X(016).
               05  DESCRIF        PIC X(035).
               05  DATI-NDG       PIC X(300).
               05  DATI-NDGR REDEFINES DATI-NDG.
                   07  FILLERN    PIC X(29).
                   07  RAGSOCNDG  PIC X(140).
                   07  FILLERN1   PIC X(131).
EURO  **       05  FIGNONCONT     PIC X(140).
EURO           05  FIGNONCONT.
EURO               07 DIV-ORIGINE        PIC X(003).
EURO               07 IMP-ORIGINE        PIC S9(015)V9(003) COMP-3.
EURO               07 FILLER             PIC X(127).
               05  QUADRATURA     PIC 9(001).
BAVC27     03  FILLER         PIC X(072).
      *
      ***************************************************************
      *                  INVENTARIO  C/ABITUALI                     *
      ***************************************************************
      *
       FD  ZMUN0563 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0563.
           03  TEST-ABT.
               05  CIST-T         PIC 9(004).
               05  DPZCPZ-T       PIC 9(005).
               05  NNDG-T         PIC 9(009)         COMP-3.
               05  CTIPSTC-T      PIC 9(003).
               05  CSTC-T         PIC S9(005)   COMP-3.
               05  CISO-T         PIC X(003).
               05  NSUFABT-T      PIC 9(002).
               05  DPZMTT-T       PIC 9(005).
               05  NPRGOPE-T      PIC 9(007)         COMP-3.
               05  DSCAOUT-T      PIC X(010).
           03  RAPPORTO           PIC X(120).
           03  SCADENZA           PIC X(190).
BAVC27*    03  DATIANAG           PIC X(130).
BAVC27     03  DATIANAG           PIC X(143).
           03  COND-RAPP-SPESE    PIC X(016).
           03  COND-RAPP-ESTR     PIC X(016).
           03  SOTTOCONTI         PIC X(200).
BAVC27*    03  ANAGRAFICO         PIC X(300).
BAVC27     03  ANAGRAFICO         PIC X(314).
           03  CONDIZIONI         PIC X(016).
           03  PAESI              PIC X(060).
BAVC27     03  FILLER             PIC X(081).
      *
      ***************************************************************
      *                        TABELLE                              *
      ***************************************************************
      *
       FD  ZMUN0564 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0564.
           03  NOME-SEG           PIC X(008).
           03  SEGMENTO           PIC X(430).
      *
      ***************************************************************
      *                 STAMPA   ELENCO   INTERNO                   *
      ***************************************************************
      *
       FD  ZMUS0565 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMR0565                PIC X(133).
      *
      ***************************************************************
      *                 STAMPA   VIA   LETTERA                      *
      ***************************************************************
      *
       FD  ZMUS0566 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMR0566                PIC X(133).
      *
      ***************************************************************
      *                 STAMPA   VIA   SWIFT                        *
      ***************************************************************
      *
       FD  ZMUS0567 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMR0567                PIC X(133).
      *
      ***************************************************************
      *               TESTATA ESTRATTI GIORNALIERI                  *
      ***************************************************************
      *
       FD  ZMUN0568 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0568.
           03  TESTATA.
               05  CIST           PIC 9(004).
               05  CTIPSTC        PIC 9(003).
               05  CSTC           PIC S9(005)   COMP-3.
               05  CISO           PIC X(003).
               05  NNDGSET        PIC 9(009)         COMP-3.
               05  NSUFABT        PIC 9(002).
               05  DPZMTT         PIC 9(005).
           03  DULTESTR           PIC 9(009)         COMP-3.
           03  NUM-ESTR           PIC 9(007)         COMP-3.
           03  SALDO-ESTR         PIC S9(015)V9(003) COMP-3.
           03  FILLER             PIC X(016).
      *
      ***************************************************************
      *                      PARAMETRI                              *
      ***************************************************************
      *
       FD  ZMUN0569 LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK0569.
           03  CIST-P         PIC 9(004).
           03  DLAV-P         PIC 9(008).
           03  DLAVRP REDEFINES DLAV-P.
               05  AA-OGGI    PIC 9999.
               05  FILLER     PIC 9999.
           03  FILLER         PIC X(003).
           03  DDMN-P         PIC 9(008).
           03  DDMNRP REDEFINES DDMN-P.
               05  AA-DOMANI  PIC 9999.
               05  FILLER     PIC 9999.
           03  FILLER         PIC X(057).
           03  RAD-IST.
               05  FILLER         PIC X(015).
               05  DES-IST        PIC X(040).
               05  FILLER         PIC X(375).
      *
      ***************************************************************
      *        MOVIMENTI SPUNTA ESTRATTI CONTO                      *
      ***************************************************************
      *
       FD  ZMUN056A LABEL RECORD STANDARD
                    BLOCK CONTAINS 0 RECORDS.
       01  ZMRK056A.
           05  ISTITUTO       PIC 9(004).
           05  IND-SW         PIC X(011).
           05  DATA-OGGI      PIC 9(006).
           05  DATA-VALUTA    PIC 9(006).
           05  IMPORTO-ESTR   PIC 9(010)V9(002).
           05  SEGNO-ESTR     PIC X(001).
           05  RIFERIMENTO    PIC 9(007).
           03  TIPO-MOV       PIC X(001).
           03  DIVISA-ESTR    PIC X(003).
      *
       WORKING-STORAGE SECTION.
EURO   01  W-KSAVE                    PIC 9(04) VALUE 0.
EURO   01  SUB9.
EURO       03 C001                    PIC X(01) VALUE 'Q'.
EURO       03 C002                    PIC X(01) VALUE 'Q'.
EURO       03 C1                      PIC X(01) VALUE '/'.
EURO       03 C2                      PIC X(04) VALUE 'OCMT'.
EURO       03 C3                      PIC X(01) VALUE '/'.
EURO       03 C4                      PIC X(03).
EURO       03 C5                      PIC X(17).

      *----------INIZIO - 00044 -----------------------------------***
       01 APPO        PIC 9(4) VALUE ZERO.
       01 LIMITE      PIC 9(4) VALUE ZERO.
      *----------FINE   - 00044 -----------------------------------***
      ***--------------------- INIZIO - 00005 -----------------------***
       01 WN-DIM-UTEN    PIC 9(5) VALUE 16000.
       01 WX-NOMTAB      PIC X(8).
      ***---------------------  FINE  - 00005 -----------------------***
       01  W-SQLCODE-X             PIC X(010) VALUE SPACES.
       01  WN-SQLCODE              PIC 9(010) VALUE 0.
       01  FIL-50-LM               PIC 9(005) VALUE 0.
       01  FIL-PRIMA               PIC X(025) VALUE SPACES.
       01  KONT11                  PIC 9(005) VALUE 0.
       01  LUNG                    PIC 9(004) VALUE 0.
       01  NUM-CH                  PIC 9(004) VALUE 0.
       01  L                       PIC 9(004) VALUE 0.
       01  K                       PIC 9(004) VALUE 0.
       01  ESTR-5                  PIC 9(007).
       01  ESTR-6                  PIC 9(007).
       01  NUMERO-CONTO            PIC X(010).
      *----------------- INIZIO A0004 --------------------------*
       01  W-NUMERO-CONTO.
SAF   *    03  DESC    PIC X(12) VALUE 'ESTERO LIRE '.
      *    03  NUMC    PIC X(10).
           03  DESC    PIC X(06) VALUE 'ESTERO'.
           03  FILLER  PIC X VALUE '-'.
           03  CISO-9  PIC X(03).
           03  FILLER  PIC X VALUE '-'.
           03  CSTC-9  PIC 9(05).
           03  FILLER  PIC X VALUE '-'.
           03  SUFF-9  PIC 9(02).
           03  FILLER  PIC X VALUE '-'.
           03  NNDG-9  PIC 9(09).
      *    03  FILLER  PIC X.
      *----------------- FINE   A0004 --------------------------*
       01  NUMERO-ESTRATTO         PIC 9(005).
       01  COD-TRA                 PIC X(004).
       01  S-DATA                  PIC 9(006).
       01  CONTA-LTT               PIC 9(006) VALUE 0.
       01  CONTA-SWI               PIC 9(006) VALUE 0.
       01  TIPO-NDG                PIC 9(001).
       01  CLIN-60      PIC 9(001).
       01  CLIN-61      PIC 9(001).
       01  KONT-50      PIC 9(003)           VALUE 0.
       01  KONT-60      PIC 9(003)           VALUE 0.
       01  KONT-70      PIC 9(003)           VALUE 0.
       01  INDICE-50    PIC 9(004)           VALUE 0.
       01  INDICE-60    PIC 9(004)           VALUE 0.
       01  INDICE-70    PIC 9(004)           VALUE 0.
       01  DATAX-50     PIC X(010).
       01  DATAX-60     PIC X(010).
       01  DATAX-70     PIC X(010).
       01  DATAX-51     PIC X(010).
       01  DATAX-61     PIC X(010).
       01  DATAX-71     PIC X(010).
       01  DATAY-50     PIC X(005).
       01  DATAY-60     PIC X(005).
       01  DATAY-70     PIC X(005).
       01  DEC-FIL-50   PIC X(025).
       01  DEC-FIL-60   PIC X(025).
       01  DEC-FIL-60X  PIC X(025).
       01  DEC-50       PIC X(037).
       01  DEC-51       PIC X(008).
       01  DEC-51-A     PIC X(008).
       01  DEC-52       PIC X(007).
       01  DEC-52-A     PIC X(007).
       01  DEC-53       PIC X(001).
       01  DEC-60       PIC X(042).
       01  DEC-61       PIC X(007).
       01  DEC-62       PIC X(008).
       01  DEC-63       PIC X(007).
       01  SAL-50       PIC S9(013)V9(003)    VALUE 0.
       01  SAL-51       PIC S9(013)V9(003)    VALUE 0.
       01  SAL-52       PIC S9(013)V9(003)    VALUE 0.
       01  IMOV-50      PIC S9(013)V9(003).
       01  SAL-60       PIC S9(013)V9(003)    VALUE 0.
       01  SAL-61       PIC S9(013)V9(003)    VALUE 0.
       01  SAL-62       PIC S9(013)V9(003)    VALUE 0.
       01  IMOV-60      PIC S9(013)V9(003).
       01  SAL-70       PIC S9(013)V9(003)    VALUE 0.
       01  SAL-71       PIC S9(013)V9(003)    VALUE 0.
       01  SAL-72       PIC S9(013)V9(003)    VALUE 0.
       01  IMOV-70      PIC S9(013)V9(003).
       01  SGN-50       PIC X(001).
       01  SGN-51       PIC X(001).
       01  SGN-51-A     PIC X(001).
       01  SGN-70       PIC X(001).
       01  SGN-71       PIC X(001).
       01  SW-UTE       PIC 9(001).
      ***--------------------- INIZIO - 00005 -----------------------***
      *77  INDICE       PIC 9(004) VALUE ZERO.
       01  INDICE       PIC 9(005) VALUE ZERO.
      *77  INDICE-UTE   PIC 9(004) VALUE ZERO.
       01  INDICE-UTE   PIC 9(005) VALUE ZERO.
      ***---------------------  FINE  - 00005 -----------------------***
       01  CONTATORE    PIC 9(007) VALUE ZERO.
       01  CAMPO-ISTITUTO PIC 9(004).
       01  IST-COMODO   PIC 9(004).
      *
       01  FRASE-01     PIC X(011).
       01  FRASE-02     PIC X(002).
       01  FR-021       PIC X(004).
       01  FRASE-03     PIC X(011).
       01  FRASE-04     PIC X(011).
       01  FRASE-05     PIC X(037).
       01  FRASE-06     PIC X(033).
       01  FRASE-07     PIC X(008).
       01  FRASE-08     PIC X(042).
       01  FRASE-09     PIC X(034).
       01  FRASE-10     PIC X(025).
       01  FRASE-11     PIC X(035).
       01  FRASE-12     PIC X(007).
       01  FRASE-13     PIC X(007).
       01  DES-ISTITUTO PIC X(040).
       01  DES-FILIALE  PIC X(035).
       01  DES-ZIND     PIC X(035).
       01  DES-ZCTA     PIC X(035).
       01  DES-ZPAE     PIC X(035).
       01  ZRAGSOC-L    PIC X(035).
       01  ZIND-L       PIC X(035).
       01  ZCTA-L       PIC X(035).
       01  ZPAE-L       PIC X(035).
       01  SW-IST       PIC 9(001)    VALUE 0.
       01  SW-FIL       PIC 9(001)    VALUE 0.
       01  SW-FILIALE   PIC 9(001)    VALUE 0.
      ***------------------ INIZIO 00028 -----------------------***
       01  COMP-CODE    PIC 9(003) COMP.
       01  ILBOABN0     PIC X(08) VALUE 'ILBOABN0'.
      ***------------------  FINE  00028 -----------------------***
           COPY SYWCI005.
      ***------------------ INIZIO A0003 -----------------------***
           COPY ZMWCONFG.
           COPY ZMWNOPER.

       01  FLAG-WCONFG-GESTNOPE.
           05  FLAG-CONTATORE-PRIMI2     PIC 9(2).
           05  FLAG-CONTATORE-RESTO      PIC 9(5).

      ***------------------  FINE  A0003 -----------------------***
      ***CAMPI DI PROVA
       01  DISP-UTENO-CCTRUTE        PIC S9(2)V USAGE COMP-3.
       01  DISP-UTENO-CTROP          PIC S9(5)V USAGE COMP-3.
       01  DISP-UTENO-CTROPE7        PIC S9(7)V USAGE COMP-3.
      ***CAMPI DI PROVA
      *
       01  SALX50       PIC X(022).
       01  SARV50 REDEFINES SALX50.
           03  FILLER   PIC X.
           03  SALV50   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9,99+.
       01  SARI50 REDEFINES SALX50.
           03  FILLER   PIC XXXX.
           03  SALI50   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9+.
      *
       01  MOVX50       PIC X(022).
       01  MORV50 REDEFINES MOVX50.
           03  FILLER   PIC X.
           03  MOVV50   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9,99+.
       01  MORI50 REDEFINES MOVX50.
           03  FILLER   PIC XXXX.
           03  MOVI50   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9+.
      *
       01  SALX51       PIC X(022).
       01  SARV51 REDEFINES SALX51.
           03  FILLER   PIC X.
           03  SALV51   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9,99+.
       01  SARI51 REDEFINES SALX51.
           03  FILLER   PIC XXXX.
           03  SALI51   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9+.
      *
       01  SALX51-A       PIC X(022).
       01  SARV51 REDEFINES SALX51-A.
           03  FILLER   PIC X.
           03  SALV51-A   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9,99+.
       01  SARI51 REDEFINES SALX51-A.
           03  FILLER   PIC XXXX.
           03  SALI51-A   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9+.
      *
       01  SALX60       PIC X(022).
       01  SARV60 REDEFINES SALX60.
           03  FILLER   PIC X.
           03  SALV60   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9,99+.
       01  SARI60 REDEFINES SALX60.
           03  FILLER   PIC XXXX.
           03  SALI60   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9+.
      *
       01  MOVX60       PIC X(022).
       01  MORV60 REDEFINES MOVX60.
           03  FILLER   PIC X.
           03  MOVV60   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9,99+.
       01  MORI60 REDEFINES MOVX60.
           03  FILLER   PIC XXXX.
           03  MOVI60   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9+.
      *
       01  SALX61       PIC X(022).
       01  SARV61 REDEFINES SALX61.
           03  FILLER   PIC X.
           03  SALV61   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9,99+.
       01  SARI61 REDEFINES SALX61.
           03  FILLER   PIC XXXX.
           03  SALI61   PIC Z.ZZZ.ZZZ.ZZZ.ZZ9+.
      *
       01  DIVISA       PIC X(003).
       01  DIVIS REDEFINES DIVISA.
           03  ALTRI    PIC X(002).
           03  TERZO    PIC X(001).
      *
       01  COM-IMPORTO PIC Z(12)9,9(3).
       01  R-COM-IMPORTO REDEFINES COM-IMPORTO.
           02 ELE-IMP OCCURS 17 PIC X.
       01  COM-IMPORTO-1.
           02 ELE-IMP-1 OCCURS 17 PIC X.
       01  ELEMENTO     PIC X(100).
       01  RED-ELE REDEFINES ELEMENTO.
           03  ELE      PIC X(001)  OCCURS 100.
       01  RIGA-SW.
           03  RIGA-1   PIC X(001).
           03  RIGA-2   PIC X(001).
           03  RIGA-3   PIC 9(002).
           03  RIGA-4   PIC X(001).
           03  RIGA-5   PIC X(001).
           03  FILLER   PIC X(002).
           03  RIGA-6   PIC X(025).
           03  RIGA-7   PIC X(099).
      ***----------------------- INIZIO - 00044 -------------------***
      *** ATTENZIONE: SE SI MODIFICA LA LUNGHEZZA DI RIGA-7 CORREGGERE
      ***             LE MODIFICHE CON MARCATORE 00044
      ***----------------------- FINE   - 00044 -------------------***
       01  CAMPO37      PIC X(037).
       01  CAMPO371 REDEFINES CAMPO37.
           03  C-11     PIC X(016).
           03  C-12     PIC X(007).
           03  C-13     PIC X(004).
           03  C-14     PIC X(010).
       01  CAMPO372 REDEFINES CAMPO37.
           03  C-21     PIC X(019).
           03  C-22     PIC X(007).
           03  C-24     PIC X(011).
       01  CAMPO42      PIC X(042).
       01  CAMPO421 REDEFINES CAMPO42.
           03  D-10     PIC X(006).
           03  D-11     PIC X(015).
           03  D-12     PIC X(007).
           03  D-13     PIC X(004).
           03  D-14     PIC X(010).
       01  CAMPO422 REDEFINES CAMPO42.
           03  D-20     PIC X(006).
           03  D-21     PIC X(018).
           03  D-22     PIC X(007).
           03  D-24     PIC X(011).
       01  CAMPO423 REDEFINES CAMPO42.
           03  D-30     PIC X(006).
           03  D-31     PIC X(008).
           03  D-32     PIC X(007).
           03  D-33     PIC X(007).
           03  D-34     PIC X(004).
           03  D-35     PIC X(010).
       01  NUM-70.
           03  NUM-71   PIC 9(005).
           03  NUM-72   PIC X(001) VALUE '/'.
           03  NUM-73   PIC 9(003).
       01  SLD-70.
           03  SLD-71   PIC X(001).
           03  SLD-72   PIC X(006).
           03  SLD-73   PIC X(003).
           03  SLD-74   PIC X(017).
       01  MOV-70.
           03  MOV-71   PIC 9(006).
           03  MOV-73   PIC X(001).
           03  MOV-74   PIC X(100).
           03  MOV-74-X REDEFINES MOV-74.
               05  MOV-741 PIC X OCCURS 100.
       01  MOV-72   PIC 9(004).
       01  DEC-54.
           03  CD-1     PIC X(003).
           03  CD-2     PIC X(010).
       01  DEC-70.
           03  CD-71    PIC 9(005).
           03  CD-72    PIC 9(007).
       01  DEC-71.
           03  CD-73    PIC X(002) VALUE '//'.
           03  CD-74    PIC X(016).
SAF   *01  DEC-72       PIC X(034).
SAF    01  DEC-72.
SAF        03  DEC-72-A PIC X(016).
SAF        03  DEC-72-B PIC X(016).
SAF        03  DEC-72-C PIC X(002).
SAF    01  DEC-72-1.
SAF        03  DEC-72-1-X PIC X(002).
SAF        03  DEC-72-1-A PIC X(016).
SAF        03  DEC-72-1-Y PIC X(002).
SAF        03  DEC-72-1-B PIC X(016).
SAF        03  DEC-72-1-Z PIC X(002).
SAF        03  DEC-72-1-C PIC X(002).
       01  DEC-64.
           03  DC-1     PIC X(003).
           03  DC-2     PIC X(010).
       01  CONTR-50.
           03  PAG-50   PIC 9(003).
           03  SEG-50   PIC X(029).
       01  CONTR-60.
           03  PAG-60   PIC 9(003).
           03  SEG-60   PIC X(029).
       01  CONTR-61.
           03  SEG-61   PIC X(029).
       01  CONTR-70.
           03  PAG-70   PIC 9(003).
           03  SEG-70   PIC X(029).
      *
       01  T-0.
           03  T-01     PIC 9(002).
           03  T-02     PIC 9(005).
      **** MODIFICA SWIFT 940 INIZIO
       01  T-1.
           03  T-11     PIC 9(005).
           03  T-12     PIC X(001)  VALUE '-'.
           03  T-13     PIC 9(007).
           03  T-14     PIC X(001)  VALUE '/'.
           03  T-15     PIC 9(007)  VALUE 0.
           03  T-16     PIC X(001)  VALUE '/'.
           03  T-17     PIC 9(005).
           03  T-18     PIC X(001)  VALUE '-'.
           03  T-19     PIC 9(007).
           03  T-81     PIC X(001)  VALUE '/'.
           03  T-82     PIC 9(004).
           03  T-83     PIC X(003)  VALUE SPACES.
      **** MODIFICA SWIFT 940 FINE
      *
      **** MODIFICA SWIFT 940 INIZIO
       01  T-2.
           03  T-21     PIC X(030)  VALUE SPACES.
           03  T-22     PIC 9(005).
           03  T-23     PIC X(001)  VALUE '-'.
           03  T-24     PIC 9(007).
           03  T-25     PIC X(014)  VALUE ' PRIORITA'': 02'.
      **** MODIFICA SWIFT 940 FINE
      *
       01  T-3.
           03  T-31     PIC X(032)  VALUE '       DESTINATARIA'.
           03  T-32     PIC X(035).
       01  T-4.
           03  T-41     PIC X(032)  VALUE SPACES.
           03  T-42     PIC X(035).
       01  T-9.
           03  T-91     PIC 9(001).
           03  T-92     PIC X(132).
       01  SALVA-TESTATA.
           03  TESTATA.
               05  CIST           PIC 9(004).
               05  CTIPSTC        PIC 9(003).
      ***--------------------- INIZIO - 00001 -----------------------***
      *        05  CSTC           PIC 9(003).
               05  CSTC           PIC S9(005)   COMP-3.
      ***---------------------  FINE  - 00001 -----------------------***
               05  CISO           PIC X(003).
               05  NNDGSET        PIC 9(009)         COMP-3.
               05  NSUFABT        PIC 9(002).
               05  DPZMTT         PIC 9(005).
           03  DULTESTR           PIC 9(009)         COMP-3.
           03  NUM-ESTR           PIC 9(007)         COMP-3.
           03  SALDO-ESTR         PIC S9(015)V9(003) COMP-3.
           03  FILLER             PIC X(016).
      *
       01  RAP-MOV-X              PIC X(029).
       01  RAP-MOV REDEFINES RAP-MOV-X.
           03  CIST               PIC 9(004).
           03  DPZMTT             PIC 9(005).
           03  CTIPSTC            PIC 9(003).
      ***--------------------- INIZIO - 00001 -----------------------***
      *    03  CSTC               PIC 9(003).
           03  CSTC               PIC S9(005)   COMP-3.
      ***---------------------  FINE  - 00001 -----------------------***
           03  CISO               PIC X(003).
           03  NNDGSET            PIC 9(009).
           03  NSUFABT            PIC 9(002).
       01  RAP-INV-X              PIC X(029).
       01  RAP-INV REDEFINES RAP-INV-X.
           03  CIST               PIC 9(004).
           03  DPZMTT             PIC 9(005).
           03  CTIPSTC            PIC 9(003).
      ***--------------------- INIZIO - 00001 -----------------------***
      *    03  CSTC               PIC 9(003).
           03  CSTC               PIC S9(005)   COMP-3.
      ***---------------------  FINE  - 00001 -----------------------***
           03  CISO               PIC X(003).
           03  NNDGSET            PIC 9(009).
           03  NSUFABT            PIC 9(002).
      *
       01  DATAXX.
           03  GG    PIC 99.
           03  SS1   PIC X VALUE '/'.
           03  MM    PIC 99.
           03  SS2   PIC X VALUE '/'.
           03  AA    PIC 9(04).
       01  DATA-A    PIC 9(08).
       01  DATA-AR REDEFINES DATA-A.
           03  AA    PIC 9(04).
           03  MM    PIC 99.
           03  GG    PIC 99.
       01  DATA-C    PIC 9(08).
       01  DATA-CR REDEFINES DATA-C.
           03  CC    PIC 99.
           03  P-DATA.
               05  AA    PIC 99.
               05  MM    PIC 99.
               05  GG    PIC 99.
       01  DATA-L    PIC 9(08).
       01  DATA-LR REDEFINES DATA-L.
           03  CC    PIC 99.
           03  L-DATA.
               05  AA    PIC 99.
               05  MM    PIC 99.
               05  GG    PIC 99.
       01  DATA-B    PIC 9(08).
       01  DATA-BR REDEFINES DATA-B.
           03  CCC   PIC 9999.
           03  Q-DATA.
               05  MM    PIC 99.
               05  GG    PIC 99.
       01  DATAYY.
           03  GG    PIC 99.
           03  SS1   PIC X VALUE '/'.
           03  MM    PIC 99.
      *
       01  DATA-AK         PIC 9(008).
       01  DATA-A-A REDEFINES DATA-AK.
           03  AA    PIC 9(002).
           03  BB    PIC 9(002).
           03  MM    PIC 9(002).
           03  GG    PIC 9(002).
      *
       01  DATA-BK.
           03  GG    PIC 9(002).
           03  MM    PIC 9(002).
           03  BB    PIC 9(002).
      *
       01  CAMPO-OPERAZIONE     PIC 9(007).
       01  CAMPO-OPERAZIONE-A REDEFINES CAMPO-OPERAZIONE.
           03  CAMPO-AA         PIC 9(002).
           03  CAMPO-BB         PIC 9(005).
      *
       01  TAB-UTE.
      ***--------------------- INIZIO - 00005 -----------------------***
      *    03 UTE OCCURS 1500 TIMES.
LILLA *    03 UTE OCCURS 2000   TIMES.
LILLA      03 UTE OCCURS 16000  TIMES.
      ***---------------------  FINE  - 00005 -----------------------***
              05  ESCAD021   PIC X(015).
              05  CTABXXXX   PIC X(025).
              05  CTAB0001  REDEFINES CTABXXXX.
                  07  ZFIL       PIC X(025).
       01  SSA-UTE.
           03  F2           PIC X(003) VALUE ALL '0'.
           03  COD-UTE      PIC X(005).
           03  F3           PIC X(007) VALUE ALL '0'.
       01  CLIENTE       PIC X(300).
           COPY ZMOAD011.
           COPY ZMOAD021.
           COPY ZMOCD011.
           COPY ZMODD011.
           COPY ZMODD021.
           COPY ZMODD025.
           COPY ZMODD027.
           COPY ZMOFD011.
           COPY ZMOFD021.
           COPY ZMWCG092.
      *
      *
       01  CAMPI-PER-NOREPORT.
           02  COM-CONTR-50          PIC X(32).
           02  COM-CONTR-60          PIC X(32).
           02  COM-CONTR-61          PIC X(29).
           02  CTR-PAG-5             PIC 9(05)  VALUE ZEROS.
           02  CTR-RIG-5             PIC 9(02)  VALUE 98.
           02  CTR-PAG-6             PIC 9(05)  VALUE ZEROS.
           02  CTR-RIG-6             PIC 9(02)  VALUE 98.
      *
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *****************************************************************
      ***------------------- INIZIO - 00044 ------------------------***
      *01  WRK-BYTE-DA               PIC 9(02) VALUE ZEROS.
       01  WRK-BYTE-DA               PIC 9(03) VALUE ZEROS.
      ***------------------- FINE   - 00044 ------------------------***
       01  WRK-NR-PRG                PIC 9(02) VALUE ZEROS.
       01  WRK-IND5                  PIC 9(01) VALUE ZEROS.
       01  CONT-UPDATE               PIC 9(03) VALUE ZEROS.
       01  WCM-CHIAMATO              PIC X(08).
       01  COMODO-ZINDSWF.
           03  COMODO-SWFNDG         PIC X(4).
           03  COMODO-SWFPAE         PIC X(2).
           03  COMODO-SWFREG         PIC X(2).
           03  COMODO-SWFBCH         PIC X(3).
       01  NUMOPE-NUMERICO           PIC 9(7).
       01  COMODO-NUMOPE  REDEFINES  NUMOPE-NUMERICO.
           03  COMODO-PREF           PIC 9(2).
           03  COMODO-CONT           PIC 9(5).
       COPY ZMWPRMGO.
       01  IND-DMSGO                 PIC  9(2) VALUE ZEROS.
       01  MAX-DMSGO                 PIC  9(2) VALUE 88.
       01  W-NPRGRIGA                PIC S9(3) VALUE ZEROS.
       01  W-NUM-OPE                 PIC  9(7) VALUE ZEROS.
      *------------- COMMAREA
       01  WRK-DFHCOMMAREA.
           COPY ZMWLIN50.
      *------------- AREA PER CODICI ERRORI SQL (SQLCODE)
           COPY ZMWSQLRC.
      *---------------------------------------------------------------*
      *  AREA RISERVATA AL DB2                                        *
      *---------------------------------------------------------------*
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *---------------------------------------------------------------*
      *  DCLGEN TABELLE DB2                                           *
      *---------------------------------------------------------------*
      *------------------  TRACCIATO RECORD TABELLA ZM.TBADMSG  (121)
           EXEC SQL INCLUDE ZMGDMSG  END-EXEC.
      *------------------  TRACCIATO RECORD TABELLA ZM.TBADMSGO (122)
           EXEC SQL INCLUDE ZMGDMSGO END-EXEC.
      *------------------  TRACCIATO RECORD TABELLA ZM.TBAOPE   (115)
           EXEC SQL INCLUDE ZMGOPE   END-EXEC.
      *------------------  TRACCIATO RECORD TABELLA ZM.TBTUTENO (   )
           EXEC SQL INCLUDE ZMGUTENO END-EXEC.
      *------------------  TRACCIATO RECORD TABELLA ZM.TBTAPROC (   )
           EXEC SQL INCLUDE ZMGAPROC END-EXEC.
      *------------------  TRACCIATO RECORD TABELLA ZM.TBWCONFG (   )
           EXEC SQL INCLUDE ZMGCONFG END-EXEC.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
       01  RIGA-BIANCA.
           05  FILLER                PIC X(133) VALUE SPACES.
       01  INTEST5-1.
      *------------------------- INIZIO 00029 ------------------------*
      *    05  FILLER                PIC X(03) VALUE '1 #'.
           05  FILLER                PIC X(1)  VALUE SPACES.
           05  S-DPZCPZ-T-A          PIC 9(05).
           05  FILLER                PIC X(02) VALUE  ' #'.
      *-------------------------  FINE  00029 ------------------------*
           05  S-CIST-P-1            PIC 9(04).
           05  FILLER                PIC X     VALUE '/'.
           05  S-DPZCPZ-T            PIC 9(05).
           05  FILLER                PIC X(37)
               VALUE '/ZMPDC056/EB09/0929/053/ZMUS0565/   #'.
           05  S-DLAV-P              PIC 9(08).
           05  FILLER                PIC X     VALUE '#'.
      *------------------------- INIZIO 00029 ------------------------*
      *    05  FILLER                PIC X(74) VALUE SPACES.
           05  FILLER                PIC X(69) VALUE SPACES.
      *-------------------------  FINE  00029 ------------------------*
       01  INTEST5-2.
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-CIST-P-2            PIC 9(04).
           05  FILLER                PIC X(04) VALUE SPACES.
           05  S-DES-IST             PIC X(40).
           05  FILLER                PIC X(06) VALUE SPACES.
           05  FILLER                PIC X(26) VALUE
               'AREA AFFARI INTERNAZIONALI'.
           05  FILLER                PIC X(31) VALUE SPACES.
           05  FILLER                PIC X(19) VALUE
               'PROSP. N. 13022 CEC'.
       01  INTEST5-3.
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-FIL-50-LM           PIC ZZ999.
           05  FILLER                PIC X     VALUE '-'.
           05  S-DEC-FIL-50          PIC X(25).
           05  FILLER                PIC X(15) VALUE SPACES.
           05  FILLER                PIC X(41) VALUE
           'MOVIMENTAZIONE GIORNALIERA CONTI ABITUALI'.
           05  FILLER                PIC X(24) VALUE SPACES.
           05  FILLER                PIC X(10) VALUE 'FOGLIO N. '.
           05  S-PAGE-COUNTER        PIC Z(05).
       01  INTEST5-6.
           05  FILLER                PIC X(02) VALUE SPACES.
           05  FILLER                PIC X(09) VALUE 'CONTO N. '.
           05  S-NCON-1              PIC X(10).
           05  FILLER                PIC X(04) VALUE ' IN '.
           05  S-CISO-T-1            PIC X(03).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-ZRAGSOC             PIC X(35).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-ZCTACOR             PIC X(35).
           05  FILLER                PIC X(05) VALUE 'RIF. '.
           05  S-CONTATORE-1         PIC 9(07).
           05  FILLER                PIC X(21) VALUE SPACES.
       01  INTEST5-7.
           05  FILLER                PIC X(02) VALUE SPACES.
           05  FILLER                PIC X(12) VALUE 'ESTRATTO N. '.
           05  S-ESTR-5              PIC 9(07).
           05  FILLER                PIC X(11) VALUE ' FOGLIO N. '.
           05  S-KONT-50             PIC 9(03).
           05  FILLER                PIC X(62) VALUE SPACES.
           05  FILLER                PIC X(08) VALUE 'AVVISO: '.
           05  S-TAVVERGI            PIC X(03).
           05  FILLER                PIC X(25) VALUE SPACES.
       01  INTEST5-9.
           05  FILLER                PIC X(28) VALUE SPACES.
           05  FILLER                PIC X(06) VALUE 'SALDO '.
           05  S-DEC-50              PIC X(37).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-SALX50              PIC X(22).
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-SGN-50              PIC X(01).
           05  FILLER                PIC X(36) VALUE SPACES.
       01  INTEST5-11.
           05  FILLER                PIC X(02) VALUE SPACES.
           05  FILLER                PIC X(41)
               VALUE 'DATA. RIFERIMENTO../MATRIC./OPERAZIONE N.'.
           05  FILLER                PIC X(28)
               VALUE ' LORO RIFERIMENTO VALUTA....'.
           05  FILLER                PIC X(23)
               VALUE ' IMPORTO...............'.
           05  FILLER                PIC X(16)
               VALUE ' D/C DESCRIZIONE'.
           05  FILLER                PIC X(23) VALUE SPACES.
       01  DE-5.
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-DATAY-50            PIC X(05).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-CDPZRIF-1           PIC 9(05).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-NOPERIF-1           PIC 9(07).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-NMTRUTE             PIC 9(07).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-DPZMTT-T-1          PIC 9(05).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-NPRGOPE-T           PIC 9(07).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-LORORIF-1           PIC X(16).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-DATAX-51            PIC X(10).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-MOVX50              PIC X(22).
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-DEC-53              PIC X(01).
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-DESCRIF-1           PIC X(34).
       01  FOOT5-1.
           05  FILLER                PIC X(28) VALUE SPACES.
           05  FILLER                PIC X(06) VALUE 'SALDO '.
           05  S-DEC-51              PIC X(08).
           05  FILLER                PIC X(08) VALUE ' A LORO '.
           05  S-DEC-52              PIC X(08).
           05  S-DEC-54              PIC X(13).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-SALX51              PIC X(22).
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-SGN-51              PIC X(01).
           05  FILLER                PIC X(37) VALUE SPACES.
       01  FOOT5-2.
           05  FILLER                PIC X(28) VALUE SPACES.
           05  FILLER                PIC X(06) VALUE 'SALDO '.
           05  S-DEC-51-A            PIC X(08).
           05  FILLER                PIC X(08) VALUE ' A LORO '.
           05  S-DEC-52-A            PIC X(08).
           05  FILLER                PIC X(14) VALUE SPACES.
           05  S-SALX51-A            PIC X(22).
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-SGN-51-A            PIC X(01).
           05  FILLER                PIC X(37) VALUE SPACES.
      *
      ***************************************************************
      *                 STAMPA   VIA   LETTERA                      *
      ***************************************************************
      *
       01  INTEST6-1.
           05  FILLER                PIC X(02) VALUE ' *'.
           05  FILLER                PIC X(131) VALUE SPACES.
       01  INTEST6-4.
           05  FILLER                PIC X(47) VALUE SPACES.
           05  FILLER                PIC X(36)
               VALUE 'ISCR. ALL''ALBO DEI GRUPPI BANCARI  '.
           05  FILLER                PIC X(50) VALUE SPACES.
       01  INTEST6-9.
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-FRASE-01            PIC X(11).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-NCON-2              PIC X(10).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-FRASE-02            PIC X(02).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-CISO-T-2            PIC X(03).
           05  FILLER                PIC X(08) VALUE SPACES.
           05  S-FR-021              PIC X(04).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-CONTATORE-2         PIC 9(07).
           05  FILLER                PIC X(05) VALUE SPACES.
      ***--------------------- INIZIO - 00001 -----------------------***
      *    05 S-CSTC-T               PIC X(03).
           05 S-CSTC-T               PIC X(05).
      ***---------------------  FINE  - 00001 -----------------------***
           05  FILLER                PIC X(01) VALUE '-'.
           05  S-CISO-T-3            PIC X(03).
           05  FILLER                PIC X(01) VALUE '-'.
           05  S-NNDG-T              PIC 9(09).
           05  FILLER                PIC X(01) VALUE '-'.
           05  S-NSUFABT-T           PIC 9(02).
           05  FILLER                PIC X(01) VALUE '-'.
           05  S-DPZMTT-T-2          PIC 9(05).
           05  FILLER                PIC X(31) VALUE SPACES.
       01  INTEST6-10.
           05  FILLER                PIC X(02) VALUE SPACES.
           05  S-FRASE-03            PIC X(11).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-ESTR-6              PIC 9(07).
           05  FILLER                PIC X(04) VALUE SPACES.
           05  S-FRASE-04            PIC X(11).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-KONT-60             PIC 9(03).
           05  FILLER                PIC X(93) VALUE SPACES.
       01  INTEST6-12.
           05  FILLER                PIC X(07) VALUE SPACES.
           05  S-DEC-60              PIC X(42).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-SALX60              PIC X(22).
           05  S-FRASE-12            PIC X(07).
           05  FILLER                PIC X(54) VALUE SPACES.
       01  INTEST6-14.
           05  FILLER                PIC X(04) VALUE SPACES.
           05  S-FRASE-05            PIC X(37).
           05  S-FRASE-06            PIC X(33).
           05  S-FRASE-07            PIC X(08).
           05  FILLER                PIC X(51) VALUE SPACES.
       01  DE-6.
           05  FILLER                PIC X(04) VALUE SPACES.
           05  S-DATAY-60            PIC X(05).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-CDPZRIF-2           PIC 9(05).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-NOPERIF-2           PIC 9(07).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-LORORIF-2           PIC X(16).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-DATAX-61            PIC X(10).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-MOVX60              PIC X(22).
           05  S-DEC-61              PIC X(08).
           05  FILLER                PIC X(51) VALUE SPACES.
       01  DE-6B.
           05  FILLER                PIC X(04) VALUE SPACES.
           05  S-DESCRIF-2           PIC X(34).
           05  FILLER                PIC X(95) VALUE SPACES.
       01  FOOT6-56.
           05  FILLER                PIC X(09) VALUE SPACES.
           05  S-FRASE-08            PIC X(42).
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-SALX61              PIC X(22).
           05  S-FRASE-13            PIC X(07).
           05  FILLER                PIC X(52) VALUE SPACES.
       01  FOOT6-63.
           05  FILLER                PIC X(40) VALUE SPACES.
           05  S-ZRAGSOC-L           PIC X(35).
           05  FILLER                PIC X(58) VALUE SPACES.
       01  FOOT6-64.
           05  FILLER                PIC X(40) VALUE SPACES.
           05  S-ZIND-L              PIC X(35).
           05  FILLER                PIC X(58) VALUE SPACES.
       01  FOOT6-65.
           05  FILLER                PIC X(40) VALUE SPACES.
           05  S-ZCTA-L              PIC X(35).
           05  FILLER                PIC X(58) VALUE SPACES.
       01  FOOT6-66.
           05  FILLER                PIC X(05) VALUE SPACES.
           05  S-FIL-PRIMA           PIC X(25).
           05  FILLER                PIC X(10) VALUE SPACES.
           05  S-ZPAE-L              PIC X(35).
           05  FILLER                PIC X(58) VALUE SPACES.
       01  FOOT6-69.
           05  FILLER                PIC X(05) VALUE SPACES.
           05  S-FRASE-09            PIC X(34).
           05  S-FRASE-10            PIC X(25).
           05  FILLER                PIC X(69) VALUE SPACES.
       01  FOOT6-70.
           05  FILLER                PIC X(05) VALUE SPACES.
           05  S-FRASE-11            PIC X(35).
           05  FILLER                PIC X(93) VALUE SPACES.
      *
      ***************************************************************
      *                 STAMPA   VIA   SWIFT                        *
      ***************************************************************
      *
       01  DE-7.
           05  FILLER                PIC X(01) VALUE SPACES.
           05  S-RIGA-SW             PIC X(132).
      ***************************************************************
       PROCEDURE DIVISION.
      ***************************************************************
       OPEN-FILES.
           OPEN INPUT  ZMUN0561.
           OPEN INPUT  ZMUN0562.
           OPEN INPUT  ZMUN0563.
           OPEN INPUT  ZMUN0564.
           OPEN INPUT  ZMUN0569.
           OPEN OUTPUT ZMUS0565.
           OPEN OUTPUT ZMUS0566.
           OPEN OUTPUT ZMUS0567.
           OPEN OUTPUT ZMUN0568.
           OPEN OUTPUT ZMUN056A.
      *
           MOVE 0 TO CONTATORE FIL-50-LM.
           MOVE 9999 TO CAMPO-ISTITUTO.
      ************************************************************
      *       GESTIONE FILE DEI SALDI DEGLI ESTRATTI             *
      ************************************************************
       FUORI-CICLO.
           READ ZMUN0561 AT END
                MOVE 0 TO CONTATORE
                PERFORM AZZ-REC-TESTATA THRU EX-AZZ-REC-TESTATA
                GO TO INIZIO.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE08.
           MOVE ZMRK0561 TO SALVA-TESTATA.
           MOVE NUM-ESTR OF ZMRK0561 TO CONTATORE.
           MOVE CIST     OF ZMRK0561 TO IST-COMODO.
       LOOP-READ.
           READ ZMUN0561 AT END GO TO INIZIO.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE09.
           MOVE ZMRK0561 TO ZMRK0568.
           WRITE ZMRK0568.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE14.
           GO TO LOOP-READ.
       INIZIO.
      *
      *    DISPLAY 'ZMPDC056 - CONT. ESTRATTI : ' CONTATORE.
      ************************************************************
      *       APPARIGLIAMENTO INVENTARIO - MOVIMENTI             *
      ************************************************************
           PERFORM LEGGI-INVENTARIO THRU EX-LEGGI-INVENTARIO.
       LBL01.
           PERFORM LEGGI-MOVIMENTI THRU EX-LEGGI-MOVIMENTI.
           MOVE ZEROES  TO  WRK-NR-PRG.
       CONFRONTO.
           DISPLAY 'CONFRONTO'.
           DISPLAY 'RAP-INV-X = ' RAP-INV-X'<'.
           DISPLAY 'RAP-MOV-X = ' RAP-MOV-X'<'.

           IF RAP-MOV-X > RAP-INV-X THEN
             PERFORM LEGGI-INVENTARIO THRU EX-LEGGI-INVENTARIO
             MOVE ZEROES  TO  WRK-NR-PRG
             GO TO CONFRONTO.
           IF RAP-MOV-X = RAP-INV-X THEN
              IF RAP-MOV-X = HIGH-VALUES THEN
                 PERFORM REC-TESTATA THRU EX-REC-TESTATA
                 PERFORM 400-FOOT5   THRU 400-FOOT5-END
                 PERFORM 410-FOOT6   THRU 410-FOOT6-END
                 GO TO WRITE-FINE
              ELSE
      * EURO-I QUESTE SONO SOSPESE
      ****      ACCEDERE PER PRENDERE IL FTIPOCONTO
      ****       IF B-FTIPOCONTO = 'S' OR 'L' OR 'R'
      ****          PERFORM LEGGI-MOVIMENTI THRU EX-LEGGI-MOVIMENTI
      ****          GO TO CONFRONTO
      ****       ELSE
      * EURO-F
                 GO TO VEDI-TIPO-RECORD.
           IF RAP-MOV-X < RAP-INV-X THEN
             PERFORM LEGGI-MOVIMENTI THRU EX-LEGGI-MOVIMENTI
             GO TO CONFRONTO.
      *
       VEDI-NUMERO.
              SUBTRACT 1 FROM NPRNCCO OF ZMRK0562.
       EX-VEDI-NUMERO.
           EXIT.
       VEDI-TIPO-RECORD.
           IF TRK-T OF ZMRK0562 = 0 THEN
              PERFORM VEDI-NUMERO THRU EX-VEDI-NUMERO
              PERFORM SALVA-DATI-00 THRU EX-SALVA-DATI-00
              PERFORM LEGGI-MOVIMENTI THRU EX-LEGGI-MOVIMENTI
              GO TO CONFRONTO.
           IF TRK-T OF ZMRK0562 = 1 THEN
              PERFORM SALVA-DATI-01 THRU EX-SALVA-DATI-01
              PERFORM LEGGI-MOVIMENTI THRU EX-LEGGI-MOVIMENTI
              GO TO CONFRONTO.
           IF TRK-T OF ZMRK0562 = 2 THEN
              PERFORM SALVA-DATI-02 THRU EX-SALVA-DATI-02
              PERFORM LEGGI-MOVIMENTI THRU EX-LEGGI-MOVIMENTI
              GO TO CONFRONTO.
      *
       SALVA-DATI-00.

           DISPLAY 'SONO IN SALVA DATI 00'.

           MOVE DATIANAG   OF ZMRK0563 TO ZMODD025.

LILLA      DISPLAY 'FLAG PERIOD. ESTRAT = ' TAVVERGI OF ZMODD025.

           IF TAVVERGI OF ZMODD025 = 'NES' THEN
              PERFORM LEGGI-INVENTARIO THRU EX-LEGGI-INVENTARIO
              GO TO CONFRONTO.
           PERFORM 300-PRENOTA-CONTATORE
              THRU 300-PRENOTA-CONTATORE-END.
      ***------------------ INIZIO - A0003 ----------------------***
DPS  **    MOVE  UTENO-CTROP           TO  CONTATORE.
DPS   *    MOVE  UTENO-CTROPE7         TO  CONTATORE.
CRM        MOVE W-NUM-OPE              TO CONTATORE.
CRM   *    IF CONFG-GESTNOPE = '0'
CRM   *       MOVE NO-NUMOPE              TO FLAG-WCONFG-GESTNOPE
CRM   *       MOVE FLAG-CONTATORE-RESTO   TO CONTATORE
CRM   *       MOVE FLAG-CONTATORE-RESTO   TO W-NUM-OPE
CRM   *    ELSE
CRM   *       MOVE NO-NUMOPE              TO CONTATORE
CRM   *       MOVE NO-NUMOPE              TO W-NUM-OPE
CRM   *    END-IF.
      ***------------------ FINE   - A0003 ----------------------***
           PERFORM DATI-00-TAB THRU EX-DATI-00-TAB.
LILLA      DISPLAY 'FLAG PERIOD. ESTRAT 1 = ' TAVVERGI OF ZMODD025.

           IF TAVVERGI OF ZMODD025 = 'LTT' OR = 'RAC' THEN
              ADD 1 TO CONTA-LTT
              PERFORM DATI-00-LTT THRU EX-DATI-00-LTT.

           IF TAVVERGI OF ZMODD025 = 'SW1' OR = 'SW2' OR
                                   = 'SW3' OR = 'SW4' THEN
              ADD 1 TO CONTA-SWI
              PERFORM DATI-00-SWI THRU EX-DATI-00-SWI.
       EX-SALVA-DATI-00.
           EXIT.
       READ-PARAMETRO.
           READ ZMUN0569 AT END GO TO ERRORE3.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE10.
           IF CIST-P OF ZMRK0569 NOT = CIST-T OF ZMRK0563
              GO TO READ-PARAMETRO.
           MOVE DLAV-P TO DATA-L.
           MOVE DLAV-P TO DATA-A.
           MOVE CORR DATA-AR TO DATAXX.
           MOVE DATAXX TO DATAX-50.
           IF SW-IST = 0
              MOVE DES-IST TO DES-ISTITUTO
              MOVE 1 TO SW-IST.
       EX-READ-PARAMETRO.
           EXIT.
      ************************************************************
      * AZZERAMENTO TABELLA IN MEMORIA   UTENTI (0001)
      ************************************************************
       AZZERA-TABELLA.

           MOVE 0  TO INDICE.
       LBL00.
           ADD 1 TO INDICE.
      ***--------------------- INIZIO - 00005 -----------------------***
      *    IF INDICE > 1500 THEN GO TO EX-AZZERA-TABELLA.
           IF INDICE > WN-DIM-UTEN THEN GO TO EX-AZZERA-TABELLA.
      ***---------------------  FINE  - 00005 -----------------------***
           MOVE SPACES TO UTE (INDICE).
           GO TO LBL00.

       EX-AZZERA-TABELLA.
           EXIT.
      ************************************************************
      * CARICAMENTO TABELLA IN MEMORIA   UTENTI (0001)
      ************************************************************
       READ-TABELLA.

           MOVE 0 TO INDICE-UTE SW-UTE.
       READ-TAB.
           READ ZMUN0564 AT END GO TO ERRORE4.

           IF NOME-SEG OF ZMRK0564 = 'ESSAD011' THEN
             MOVE SEGMENTO OF ZMRK0564 TO  ZMOAD011
             DISPLAY ' CIST = ' CIST OF ZMOAD011 '<'
             DISPLAY ' CTAB = ' CTAB OF ZMOAD011 '<'
             DISPLAY ' CIST-T = ' CIST-T OF ZMRK0563 '<'
             DISPLAY ' CSTC-T = ' CSTC-T OF ZMRK0563 '<'
             DISPLAY ' CISO-T = ' CISO-T OF ZMRK0563 '<'
             IF CIST OF ZMOAD011 = CIST-T OF ZMRK0563
                IF CTAB OF  ZMOAD011 = 0001
                   MOVE 1 TO SW-UTE
                   GO TO READ-TAB
                ELSE
                   IF CTAB OF ZMOAD011 > 0001 THEN
                      MOVE 0 TO SW-UTE
                      GO TO INIZIALIZZA
                   ELSE
                      MOVE 0 TO SW-UTE
                      GO TO READ-TAB
              ELSE
                 GO TO READ-TAB.
           IF NOME-SEG OF ZMRK0564 NOT = 'ESSAD021' THEN
             GO TO READ-TAB.
           IF SW-UTE = 1 THEN
              MOVE SEGMENTO TO ZMOAD021
              IF NMTRUTE OF ZMOAD021 NOT = 0 THEN
                 GO TO READ-TAB
              ELSE
                 ADD 1 TO INDICE-UTE
      ***----------------------- INIZIO - 00005 -------------------***
      *
              IF  INDICE-UTE >  WN-DIM-UTEN  THEN
                 MOVE  'TAB-UTE' TO WX-NOMTAB
                 GO TO ERRORE-DIM
              ELSE
      *
      ***----------------------- FINE - 00005 ---------------------***
      *
                 MOVE ESCAD021 OF ZMOAD021 TO ESCAD021 OF
                                           UTE (INDICE-UTE)
                 MOVE ZFIL    OF ZMOAD021  TO ZFIL    OF
                                           UTE (INDICE-UTE)
                 GO TO READ-TAB.
           GO TO READ-TAB.
       INIZIALIZZA.
           ADD 1 TO INDICE-UTE.
           MOVE '999999999999999'  TO ESCAD021 OF UTE (INDICE-UTE).
       EX-READ-TABELLA.
           EXIT.
      *
       DATI-00-TAB.
           MOVE RAP-INV-X               TO SEG-50.
           MOVE 1                       TO PAG-50.
           MOVE 0                       TO INDICE-50.
           MOVE OPERAZIONE  OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO   OF ZMRK0562 TO ZMOFD021.
      *
           MOVE ANAGRAFICO OF ZMRK0563 TO ZMOCD011.
           MOVE TNDGSET     OF ZMOCD011 TO TIPO-NDG.
           MOVE CLIN        OF ZMOCD011 TO CLIN-60.
           MOVE CISO-T      OF ZMRK0563 TO DIVISA.
      *
           MOVE DPZCPZ-T    OF ZMRK0563 TO COD-UTE.
           PERFORM RICERCA-UTE THRU EX-RICERCA-UTE.
           IF INDICE-UTE = 999 THEN GO TO ERRORE2.
           MOVE COD-UTE TO FIL-50-LM.
           MOVE ZFIL OF UTE (INDICE-UTE) TO DEC-FIL-50.
           MOVE NPRNCCO OF ZMRK0562 TO ESTR-5.
           MOVE 1 TO KONT-50.
           MOVE SPACES TO CAMPO37.
           MOVE 'INIZIALE A LORO' TO C-11.
           MOVE IMOV      OF ZMOFD021  TO SAL-50.
      *
           PERFORM R-IMP-1 THRU END-R-IMP-1.
      *
           MOVE IMOV      OF ZMOFD021  TO SAL-52.
           IF SAL-50 < 0 THEN
              MOVE 'D'       TO SGN-50
              MOVE 'DEBITO'  TO C-12
           ELSE
              MOVE 'C'       TO SGN-50
              MOVE 'CREDITO' TO C-12.
           MOVE ' AL '    TO C-13.
           MOVE DESCOPE OF ZMOFD011 TO DATA-A.
           MOVE CORR DATA-AR TO DATAXX.
           MOVE DATAXX TO C-14.
           MOVE CAMPO37 TO DEC-50.
       EX-DATI-00-TAB.
           EXIT.
      *
       DATI-00-LTT.
           MOVE RAP-INV-X               TO SEG-60 SEG-61.
           MOVE 1                       TO PAG-60.
           MOVE 0                       TO INDICE-60.
           MOVE ANAGRAFICO  OF ZMRK0563 TO ZMOCD011.
           MOVE TNDGSET OF ZMOCD011     TO TIPO-NDG.
           MOVE ZMOCD011                TO CLIENTE.
           MOVE CLIN        OF ZMOCD011 TO CLIN-60.
      *
           MOVE OPERAZIONE  OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO   OF ZMRK0562 TO ZMOFD021.
           MOVE DPZCPZ-T    OF ZMRK0563 TO COD-UTE.
           PERFORM RICERCA-UTE THRU EX-RICERCA-UTE.
           IF INDICE-UTE = 999 THEN GO TO ERRORE2.
              MOVE ZFIL      OF UTE (INDICE-UTE) TO DEC-FIL-60
           MOVE 1 TO KONT-60.
           MOVE NPRNCCO OF ZMRK0562 TO ESTR-6.
           IF CLIN-60 = 1 THEN
            IF TIPO-NDG = 1 THEN
              MOVE 'DATA. NOSTRO RIF... CAUSALE ........ ' TO FRASE-05
              MOVE 'VALUTA.... IMPORTO.............. '     TO FRASE-06
              MOVE 'A VOSTRO'                              TO FRASE-07
            ELSE
              MOVE 'DATA. NOSTRO RIF... VOSTRO RIF...... ' TO FRASE-05
              MOVE 'VALUTA.... IMPORTO.............. '     TO FRASE-06
              MOVE 'A VOSTRO'                              TO FRASE-07.
           IF CLIN-60 = 2 THEN
            IF TIPO-NDG = 1 THEN
              MOVE 'DATE. OUR REF...... REMARKS......... ' TO FRASE-05
              MOVE 'VALUE..... AMOUNT............... '     TO FRASE-06
              MOVE 'YOUR....'                              TO FRASE-07
            ELSE
              MOVE 'DATE. OUR REF...... YOUR REF........ ' TO FRASE-05
              MOVE 'VALUE..... AMOUNT............... '     TO FRASE-06
              MOVE 'YOUR....'                              TO FRASE-07.
           IF CLIN-60 = 3 THEN
            IF TIPO-NDG = 1 THEN
              MOVE 'DATUM UNSER ZEICHEN IHR ZEICHEN..... ' TO FRASE-05
              MOVE 'WERT...... BETRAG............... '     TO FRASE-06
              MOVE 'ZU IHREN'                              TO FRASE-07
            ELSE
              MOVE 'DATUM UNSER ZEICHEN IHR ZEICHEN..... ' TO FRASE-05
              MOVE 'WERT...... BETRAG............... '     TO FRASE-06
              MOVE 'ZU IHREN'                              TO FRASE-07.
           IF CLIN-60 = 4 THEN
            IF TIPO-NDG = 1 THEN
              MOVE 'DATE. OUR RIF...... REMARKS......... ' TO FRASE-05
              MOVE 'VALUE..... AMOUNT............... '     TO FRASE-06
              MOVE 'YOUR....'                              TO FRASE-07
            ELSE
              MOVE 'DATE. OUR RIF...... YOUR RIF........ ' TO FRASE-05
              MOVE 'VALUE..... AMOUNT............... '     TO FRASE-06
              MOVE 'YOUR....'                              TO FRASE-07.
           IF CLIN-60 = 1 THEN
              MOVE 'CONTO    N.'        TO FRASE-01
              MOVE 'IN'                 TO FRASE-02
              MOVE 'RIF.'               TO FR-021
              MOVE 'ESTRATTO N.'        TO FRASE-03
              MOVE 'FOGLIO   N.'        TO FRASE-04.
           IF CLIN-60 = 2 THEN
              MOVE 'ACCOUNT NO.'        TO FRASE-01
              MOVE 'IN'                 TO FRASE-02
              MOVE 'REF.'               TO FR-021
              MOVE 'STATEM. NO.'        TO FRASE-03
              MOVE 'SHEET   NO.'        TO FRASE-04.
           IF CLIN-60 = 3 THEN
              MOVE 'KONTO   NR.'        TO FRASE-01
              MOVE 'IN'                 TO FRASE-02
              MOVE 'REF.'               TO FR-021
              MOVE 'KONTOAUSZUG'        TO FRASE-03
              MOVE 'BLATT   NR.'        TO FRASE-04.
           IF CLIN-60 = 4 THEN
              MOVE 'ACCOUNT NO.'        TO FRASE-01
              MOVE 'IN'                 TO FRASE-02
              MOVE 'REF.'               TO FR-021
              MOVE 'STATEM. NO.'        TO FRASE-03
              MOVE 'SHEET   NO.'        TO FRASE-04.
           MOVE SPACES TO CAMPO42 FRASE-12.
           IF CLIN-60 = 1 THEN
              MOVE 'SALDO '         TO D-10
              MOVE 'INIZIALE A VS.' TO D-11.
           IF CLIN-60 = 2 THEN
              MOVE 'OPENIN'          TO D-10
              MOVE 'G BALANCE AS AT' TO D-11
              MOVE '       '         TO D-12.
           IF CLIN-60 = 3 THEN
              MOVE 'SALDO '         TO D-10
              MOVE 'AM  ZU IHREN  ' TO D-11.
           IF CLIN-60 = 4 THEN
              MOVE 'OPENIN'          TO D-10
              MOVE 'G BALANCE AS AT' TO D-11
              MOVE '       '         TO D-12.
           MOVE IMOV      OF ZMOFD021  TO SAL-60.
      *
           PERFORM R-IMP-4 THRU END-R-IMP-4
      *
           MOVE IMOV      OF ZMOFD021  TO SAL-62.
           IF SAL-60 < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'DEBITO '  TO D-12.
           IF SAL-60 < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'DEBIT  '  TO FRASE-12.
           IF SAL-60 < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'LASTEN '  TO D-12.
           IF SAL-60 < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'DEBIT  '  TO FRASE-12.
           IF SAL-60 NOT < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'CREDITO'  TO D-12.
           IF SAL-60 NOT < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'CREDIT '  TO FRASE-12.
           IF SAL-60 NOT < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'GUNSTEN'  TO D-12.
           IF SAL-60 NOT < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'CREDIT '  TO FRASE-12.
           IF CLIN-60 = 1 THEN
              MOVE ' AL '    TO D-13.
           IF CLIN-60 = 2 THEN
              MOVE '    '    TO D-13.
           IF CLIN-60 = 3 THEN
              MOVE '    '    TO D-13.
           IF CLIN-60 = 4 THEN
              MOVE '    '    TO D-13.
           MOVE DESCOPE OF ZMOFD011 TO DATA-A.
           MOVE CORR DATA-AR TO DATAXX.
           IF CLIN-60 = 1 THEN
              MOVE DATAXX TO D-14.
           IF CLIN-60 = 2 THEN
              MOVE DATAXX TO D-14.
           IF CLIN-60 = 3 THEN
              MOVE DATAXX TO D-14.
           IF CLIN-60 = 4 THEN
              MOVE DATAXX TO D-14.
           MOVE CAMPO42 TO DEC-60.
       EX-DATI-00-LTT.
           EXIT.
      *
       DATI-00-SWI.
           DISPLAY ' SONO IN DATI SWI '.

           MOVE RAP-INV-X               TO SEG-70.
           MOVE 1                       TO PAG-70.
           MOVE 0                       TO INDICE-70.
           MOVE OPERAZIONE  OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO   OF ZMRK0562 TO ZMOFD021.
           MOVE 1 TO KONT-70.
           MOVE IMOV      OF ZMOFD021  TO SAL-70.
           MOVE IMOV      OF ZMOFD021  TO SAL-72.
           IF SAL-70 < 0 THEN
              MOVE 'D'       TO SGN-70
           ELSE
              MOVE 'C'       TO SGN-70.
      *
           MOVE DESCOPE OF ZMOFD011 TO DATA-C.
      *
      **** INSERIRE SWIFT 940 INIZIO
           MOVE SPACES                      TO T-83.
           MOVE 'MESSAGGIO S.W.I.F.T. 950 NUM. ' TO T-21.
      **** INSERIRE SWIFT 940 FINE
      *
           MOVE SPACES                 TO RIGA-SW.
           MOVE DPZMTT-T  OF ZMRK0563  TO T-11 T-17.
           MOVE CONTATORE              TO T-0.
           MOVE T-0                    TO T-13 T-19.
           MOVE CIST-T    OF ZMRK0563  TO T-82.
      *
      **** MODIFICA SWIFT 940 INIZIO
           IF TNDGSET OF ZMOCD011 = 1
                      AND ZINDSWF OF ZMODD025 NOT = SPACES
              MOVE 'MESSAGGIO S.W.I.F.T. 940 NUM. ' TO T-21
              MOVE '940'                       TO T-83.
      **** MODIFICA SWIFT 940 FINE
      *
           MOVE T-1                    TO T-92.
           MOVE 1                      TO T-91.
           MOVE T-9                    TO RIGA-SW.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *
           MOVE SPACES                 TO RIGA-SW.
           MOVE DPZMTT-T  OF ZMRK0563  TO T-22.
           MOVE CONTATORE              TO T-0.
           MOVE T-0                    TO T-24.
           MOVE T-2                    TO T-92.
           MOVE 1                      TO T-91.
           MOVE T-9                    TO RIGA-SW.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *
           MOVE SPACES                 TO RIGA-SW.
           MOVE ZRAGSOC   OF ZMOCD011  TO T-32.
           MOVE T-3                    TO T-92.
           MOVE 1                      TO T-91.
           MOVE T-9                    TO RIGA-SW.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *
           MOVE SPACES                 TO RIGA-SW.
           MOVE ZCTA      OF ZMOCD011  TO T-42.
           MOVE T-4                    TO T-92.
           MOVE 1                      TO T-91.
           MOVE T-9                    TO RIGA-SW.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *
           MOVE SPACES                 TO RIGA-SW.
           MOVE ZINDSWF   OF ZMODD025  TO T-42.
           MOVE T-4                    TO T-92.
           MOVE 1                      TO T-91.
           MOVE T-9                    TO RIGA-SW.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *          INSERIMENTO AGGIORNAMENTO TABELLA ZM.TBADMSG         *
      *****************************************************************

           PERFORM 100-SCRIVI-ADMSG    THRU 100-SCRIVI-ADMSG-END.


      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
       CAMPO-20.
           MOVE SPACES TO RIGA-SW.
           MOVE 3 TO RIGA-1.
           MOVE ':' TO RIGA-2.
           MOVE 20 TO RIGA-3.
           MOVE ':' TO RIGA-4.
           MOVE 'RIFERIMENTO' TO RIGA-6.
           MOVE L-DATA TO RIGA-7.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 210-CAMPO20         THRU 210-CAMPO20-END.
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
       EX-CAMPO-20.
       CAMPO-25.
           MOVE SPACES TO RIGA-SW.
           MOVE 3 TO RIGA-1.
           MOVE ':' TO RIGA-2.
           MOVE 25 TO RIGA-3.
           MOVE ':' TO RIGA-4.
           MOVE 'NUMERO CONTO' TO RIGA-6.
      *---------------- INIZIO SAF   ---------------------------------*
00045 *    MOVE 'ESTERO      ' TO DESC OF W-NUMERO-CONTO
00045 *    MOVE CISO-T OF ZMRK0563 TO DESC OF W-NUMERO-CONTO (8 : 3)
      *---------------- INIZIO A0005 ---------------------------------*
      *    IF CISO-T OF ZMRK0563 = 'EUR'
      *       MOVE 'ESTERO EURO ' TO DESC OF W-NUMERO-CONTO
00045 *    ELSE
00045 *       MOVE 'ESTERO LIRE ' TO DESC OF W-NUMERO-CONTO
      *    END-IF.
00045 *    IF CISO-T OF ZMRK0563 = 'ITL'
00045 *       MOVE 'ESTERO LIRE ' TO DESC OF W-NUMERO-CONTO
00045 *    END-IF.
      *---------------- FINE   A0005 ---------------------------------*
      *---------------- INIZIO A0004 ---------------------------------*
      *    MOVE NCON OF ZMODD025 TO NUMC OF W-NUMERO-CONTO.
00045      MOVE 'ESTERO'       TO DESC OF W-NUMERO-CONTO

           MOVE  CISO     OF RAP-INV  TO  CISO-9 OF W-NUMERO-CONTO
           MOVE  CSTC     OF RAP-INV  TO  CSTC-9 OF W-NUMERO-CONTO
           MOVE  NSUFABT  OF RAP-INV  TO  SUFF-9 OF W-NUMERO-CONTO
           MOVE  NNDGSET  OF RAP-INV  TO  NNDG-9 OF W-NUMERO-CONTO
      *    MOVE  DPZMTT   OF RAP-INV  TO  CDPZ-9 OF W-NUMERO-CONTO
      *---------------- FINE   SAF   ---------------------------------*
      *    MOVE NCON OF ZMODD025 TO RIGA-7.
           MOVE W-NUMERO-CONTO   TO RIGA-7.
      *    MOVE NCON OF ZMODD025 TO NUMERO-CONTO.
      *---------------- FINE   A0004 ---------------------------------*
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 220-CAMPO25         THRU 220-CAMPO25-END.
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
       EX-CAMPO-25.
       CAMPO-28.
           MOVE SPACES TO RIGA-SW.
           MOVE 3 TO RIGA-1.
           MOVE ':' TO RIGA-2.
           MOVE 28 TO RIGA-3.
           MOVE ':' TO RIGA-4.
           MOVE 'NUMERO ESTRATTO' TO RIGA-6.
           MOVE NPRNCCO OF ZMRK0562 TO NUM-71.
           MOVE NPRNCCO OF ZMRK0562 TO NUMERO-ESTRATTO.
           MOVE KONT-70             TO NUM-73.
           MOVE NUM-70              TO RIGA-7.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 230-CAMPO28         THRU 230-CAMPO28-END.
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
       EX-CAMPO-28.
       CAMPO-60F.
           MOVE SPACES TO RIGA-SW.
           MOVE 3 TO RIGA-1.
           MOVE ':' TO RIGA-2.
           MOVE 60 TO RIGA-3.
           MOVE 'F' TO RIGA-4.
           MOVE ':' TO RIGA-5.
           MOVE 'SALDO INIZIALE' TO RIGA-6.
           MOVE SGN-70              TO SLD-71.
           MOVE P-DATA              TO SLD-72.
           MOVE P-DATA              TO S-DATA.
           MOVE CISO-T OF ZMRK0563  TO SLD-73.
           MOVE CISO-T OF ZMRK0563  TO DIVISA.
           MOVE SAL-70              TO COM-IMPORTO.
           MOVE 0 TO K.
           PERFORM ROUT-IMP THRU END-ROUT-IMP.
           MOVE COM-IMPORTO-1       TO SLD-74.
           MOVE SLD-70              TO RIGA-7.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 240-CAMPO60F        THRU 240-CAMPO60F-END.
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
       EX-CAMPO-60F.
       EX-DATI-00-SWI.
           EXIT.
      *
       SALVA-DATI-01.
LILLA      DISPLAY 'FNON IN SALVA DATI 01'.

           MOVE DATIANAG   OF ZMRK0563 TO ZMODD025.

LILLA      DISPLAY 'FLAG PERIOD. ESTRAT = ' TAVVERGI OF ZMODD025.

           IF TAVVERGI OF ZMODD025 = 'NES' THEN
              GO TO EX-SALVA-DATI-01.
           PERFORM DATI-01-TAB THRU EX-DATI-01-TAB.
           IF TAVVERGI OF ZMODD025 = 'LTT' OR = 'RAC' THEN
              PERFORM DATI-01-LTT THRU EX-DATI-01-LTT.
           IF TAVVERGI OF ZMODD025 = 'SW1' OR = 'SW2' OR
                                   = 'SW3' OR = 'SW4' THEN
              PERFORM DATI-01-SWI THRU EX-DATI-01-SWI.
       EX-SALVA-DATI-01.
           EXIT.
      *
       DATI-01-TAB.
           ADD 1 TO INDICE-50.
           IF INDICE-50 > 35 THEN
              ADD 1        TO PAG-50
              MOVE PAG-50  TO KONT-50
              MOVE SAL-52    TO SAL-51
      *
              PERFORM R-IMP-3 THRU END-R-IMP-3
      *
              MOVE SAL-52    TO SAL-50
      *
              PERFORM R-IMP-1 THRU END-R-IMP-1
      *
              MOVE 'PARZIALE' TO DEC-51
              MOVE SPACES TO DEC-54 CAMPO37
              MOVE 'A RIPORTARE A LORO' TO C-21
              MOVE 1       TO INDICE-50
              IF SAL-51 < 0 THEN
                 MOVE 'D'      TO SGN-50 SGN-51
                 MOVE 'DEBITO' TO DEC-52 C-22
                 MOVE CAMPO37 TO DEC-50
              ELSE
                 MOVE 'C'      TO SGN-50 SGN-51
                 MOVE 'CREDITO' TO DEC-52 C-22
                 MOVE CAMPO37 TO DEC-50.
           MOVE ANAGRAFICO  OF ZMRK0563 TO ZMOCD011.
           MOVE OPERAZIONE OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO  OF ZMRK0562 TO ZMOFD021.
           MOVE DESCOPE    OF ZMOFD011 TO DATA-A.
           MOVE CORR DATA-AR TO DATAYY.
           MOVE DATAYY TO DATAY-50.
           MOVE DVAL       OF ZMOFD021 TO DATA-A.
           MOVE CORR DATA-AR TO DATAXX.
           MOVE DATAXX TO DATAX-51.
           MOVE IMOV  OF ZMOFD021 TO IMOV-50.
      *
              PERFORM R-IMP-2 THRU END-R-IMP-2
      *
           ADD  IMOV  OF ZMOFD021 TO SAL-52.
           IF IMOV-50 < 0 THEN
              MOVE 'D' TO DEC-53
           ELSE
              MOVE 'C' TO DEC-53.
           PERFORM 2000-STAMPA5
              THRU 2000-STAMPA5-END.
           IF CTIPSTC-T OF ZMRK0563 = 101
                           AND ZINDSWF OF ZMODD025 NOT = SPACES
             PERFORM CREA-ESTRATTO THRU EX-CREA-ESTRATTO.
       EX-DATI-01-TAB.
           EXIT.
       CREA-ESTRATTO.
           MOVE CIST-T OF ZMRK0563 TO ISTITUTO OF ZMRK056A.
           MOVE ZINDSWF OF ZMODD025 TO IND-SW OF ZMRK056A.
           MOVE DLAV-P OF ZMRK0569 TO DATA-AK.
           MOVE CORR DATA-A-A TO DATA-BK.
           MOVE DATA-BK TO DATA-OGGI OF ZMRK056A.
           MOVE DVAL OF ZMOFD021 TO DATA-AK.
           MOVE CORR DATA-A-A TO DATA-BK.
           MOVE DATA-BK TO DATA-VALUTA OF ZMRK056A.
           MOVE IMOV OF ZMOFD021 TO IMPORTO-ESTR OF ZMRK056A.
           IF IMOV OF ZMOFD021 < 0
              MOVE 'D' TO SEGNO-ESTR OF ZMRK056A
           ELSE
              MOVE 'C' TO SEGNO-ESTR OF ZMRK056A.
           MOVE NPRGOPE-T OF ZMRK0562 TO RIFERIMENTO OF ZMRK056A.
           MOVE NPRGOPE-T OF ZMRK0562 TO CAMPO-OPERAZIONE.
           IF CAMPO-AA = 82
              MOVE 'S' TO TIPO-MOV OF ZMRK056A
           ELSE
              MOVE ' ' TO TIPO-MOV OF ZMRK056A.
           MOVE CISO OF ZMOFD021 TO DIVISA-ESTR OF ZMRK056A.
           WRITE ZMRK056A.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE15.
       EX-CREA-ESTRATTO.
           EXIT.
      *
       DATI-01-LTT.
           ADD 1 TO INDICE-60.
           IF INDICE-60 NOT > 20 THEN GO TO LTT-01.
           ADD 1          TO PAG-60.
           MOVE PAG-60    TO KONT-60.
           MOVE SAL-62    TO SAL-61.
      *
           PERFORM R-IMP-6 THRU END-R-IMP-6
      *
           MOVE SAL-62    TO SAL-60.
      *
           PERFORM R-IMP-4 THRU END-R-IMP-4
      *
           MOVE SPACES TO CAMPO42 FRASE-12 FRASE-13.
           IF CLIN-60 = 1 THEN
              MOVE 'SALDO '        TO D-30
              MOVE 'PARZIALE'      TO D-31
              MOVE ' A VS. '       TO D-32.
           IF CLIN-60 = 2 THEN
              MOVE 'INTERM'        TO D-30
              MOVE 'EDIATE C'      TO D-31
              MOVE 'LOSING '       TO D-32
              MOVE 'BALANCE'       TO D-33.
           IF CLIN-60 = 3 THEN
              MOVE 'ZWISCH'        TO D-30
              MOVE 'ENSALDO '      TO D-31
              MOVE 'ZU IHRE'       TO D-32
              MOVE 'N      '       TO D-33.
           IF CLIN-60 = 4 THEN
              MOVE 'INTERM'        TO D-30
              MOVE 'EDIATE C'      TO D-31
              MOVE 'LOSING '       TO D-32
              MOVE 'BALANCE'       TO D-33.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'DEBITO '    TO D-33.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'DEBIT  '    TO FRASE-13.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'LATESN '    TO D-33.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'DEBIT  '    TO FRASE-13.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'CREDITO'    TO D-33.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'CREDIT '    TO FRASE-13.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'GUNSTEN'    TO D-33.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'CREDIT '    TO FRASE-13.
           MOVE CAMPO42 TO FRASE-08.
           MOVE SPACES TO CAMPO42.
           IF CLIN-60 = 1 THEN
              MOVE 'SALDO '            TO D-20
              MOVE 'A RIPORTARE A VS.' TO D-21.
           IF CLIN-60 = 2 THEN
              MOVE 'INTERM'        TO D-30
              MOVE 'EDIATE O'      TO D-31
              MOVE 'PENING '       TO D-32
              MOVE 'BALANCE'       TO D-33.
           IF CLIN-60 = 3 THEN
              MOVE 'ZWISCH'            TO D-20
              MOVE 'ENSALDO ZU IHREN ' TO D-21.
           IF CLIN-60 = 4 THEN
              MOVE 'INTERM'        TO D-30
              MOVE 'EDIATE O'      TO D-31
              MOVE 'PENING '       TO D-32
              MOVE 'BALANCE'       TO D-33.
           MOVE 1       TO INDICE-60.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'DEBITO ' TO D-22.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'DEBIT  ' TO FRASE-12.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'LASTEN ' TO D-22.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'DEBIT  ' TO FRASE-12.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'CREDITO' TO D-22.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'CREDIT ' TO FRASE-12.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'GUNSTEN' TO D-22.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'CREDIT ' TO FRASE-12.
           MOVE CAMPO42 TO DEC-60.
       LTT-01.
           MOVE CLIENTE                TO ZMOCD011.
           IF SW-FIL = 0
              MOVE ZRAGSOC OF ZMOCD011 TO DES-FILIALE
              MOVE 1 TO SW-FIL.
           MOVE OPERAZIONE OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO  OF ZMRK0562 TO ZMOFD021.
           MOVE DESCOPE    OF ZMOFD011 TO DATA-A.
           MOVE CORR DATA-AR TO DATAYY.
           MOVE DATAYY TO DATAY-60.
           MOVE DVAL       OF ZMOFD021 TO DATA-A.
           MOVE CORR DATA-AR TO DATAXX.
           MOVE DATAXX TO DATAX-61.
           MOVE IMOV  OF ZMOFD021 TO IMOV-60.
      *
           PERFORM R-IMP-5 THRU END-R-IMP-5
      *
           ADD  IMOV  OF ZMOFD021 TO SAL-62.
           IF IMOV-60 < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'DEBITO ' TO DEC-61.
           IF IMOV-60 < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'DEBIT  ' TO DEC-61.
           IF IMOV-60 < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'LASTEN ' TO DEC-61.
           IF IMOV-60 < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'DEBIT  ' TO DEC-61.
           IF IMOV-60 NOT < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'CREDITO' TO DEC-61.
           IF IMOV-60 NOT < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'CREDIT ' TO DEC-61.
           IF IMOV-60 NOT < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'GUNSTEN' TO DEC-61.
           IF IMOV-60 NOT < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'CREDIT ' TO DEC-61.
           PERFORM 2100-STAMPA6
              THRU 2100-STAMPA6-END.
           MOVE DES-IST             TO DES-ISTITUTO.
           MOVE DEC-FIL-60          TO DEC-FIL-60X FIL-PRIMA.
           MOVE ZRAGSOC OF ZMOCD011 TO DES-FILIALE.
           MOVE ZINDCOR OF ZMODD025 TO DES-ZIND.
           MOVE ZCTACOR OF ZMODD025 TO DES-ZCTA.
           MOVE ZPAE    OF ZMOCD011 TO DES-ZPAE.
       EX-DATI-01-LTT.
           EXIT.
      *
       SEGNO.
           IF SAL-71 < 0 THEN
              MOVE 'D' TO SGN-70 SGN-71
           ELSE
              MOVE 'C' TO SGN-70 SGN-71.
       EX-SEGNO.
           EXIT.
      *
       DATI-01-SWI.
           ADD 1 TO INDICE-70.
           IF INDICE-70 > 25  THEN
              MOVE OPERAZIONE OF ZMRK0562 TO ZMOFD011
              MOVE DESCOPE    OF ZMOFD011 TO DATA-C
              ADD 1          TO PAG-70
              MOVE 1         TO INDICE-70
              MOVE PAG-70    TO KONT-70
              MOVE SAL-72    TO SAL-71
              MOVE SAL-72    TO SAL-70
              PERFORM SEGNO THRU EX-SEGNO
              MOVE SPACES TO RIGA-SW
              MOVE 3 TO RIGA-1
              MOVE ':' TO RIGA-2
              MOVE 62 TO RIGA-3
              MOVE 'M' TO RIGA-4
              MOVE ':' TO RIGA-5
              MOVE 'SALDO FINALE PARZIALE' TO RIGA-6
              MOVE SGN-71              TO SLD-71
              MOVE S-DATA              TO SLD-72
              MOVE CISO-T OF ZMRK0563  TO SLD-73
              MOVE SAL-71              TO COM-IMPORTO
              MOVE 0 TO K
              PERFORM ROUT-IMP THRU END-ROUT-IMP
              MOVE COM-IMPORTO-1       TO SLD-74
              MOVE SLD-70              TO RIGA-7
              PERFORM 2200-STAMPA7
                 THRU 2200-STAMPA7-END
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 250-CAMPO62M        THRU 250-CAMPO62M-END
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
      *
      *    ADD 1 TO CONTATORE
           PERFORM 300-PRENOTA-CONTATORE
              THRU 300-PRENOTA-CONTATORE-END
      ***------------------ INIZIO - A0003 ----------------------***
DPS  **    MOVE  UTENO-CTROP           TO  CONTATORE
DPS   *    MOVE  UTENO-CTROPE7         TO  CONTATORE
CRM        MOVE  W-NUM-OPE             TO CONTATORE
CRM   *    IF CONFG-GESTNOPE = '0'
CRM   *       MOVE NO-NUMOPE              TO FLAG-WCONFG-GESTNOPE
CRM   *       MOVE FLAG-CONTATORE-RESTO   TO CONTATORE
CRM   *    ELSE
CRM   *       MOVE NO-NUMOPE              TO CONTATORE
CRM   *    END-IF
      ***------------------ FINE   - A0003 ----------------------***
      *
           MOVE SPACES                 TO RIGA-SW
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *
           MOVE SPACES                 TO RIGA-SW
           MOVE DPZMTT-T  OF ZMRK0563  TO T-11 T-17
           MOVE CONTATORE              TO T-0
           MOVE T-0                    TO T-13 T-19
           MOVE T-1                    TO T-92
           MOVE 1                      TO T-91
           MOVE T-9                    TO RIGA-SW
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *
           MOVE SPACES                 TO RIGA-SW
           MOVE DPZMTT-T  OF ZMRK0563  TO T-22
           MOVE CONTATORE              TO T-0
           MOVE T-0                    TO T-24
           MOVE T-2                    TO T-92
           MOVE 1                      TO T-91
           MOVE T-9                    TO RIGA-SW
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *
           MOVE SPACES                 TO RIGA-SW
           MOVE ZRAGSOC   OF ZMOCD011  TO T-32
           MOVE T-3                    TO T-92
           MOVE 1                      TO T-91
           MOVE T-9                    TO RIGA-SW
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *
           MOVE SPACES                 TO RIGA-SW
           MOVE ZCTA      OF ZMOCD011  TO T-42
           MOVE T-4                    TO T-92
           MOVE 1                      TO T-91
           MOVE T-9                    TO RIGA-SW
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *
           MOVE SPACES                 TO RIGA-SW
           MOVE ZINDSWF   OF ZMODD025  TO T-42
           MOVE T-4                    TO T-92
           MOVE 1                      TO T-91
           MOVE T-9                    TO RIGA-SW
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *          INSERIMENTO AGGIORNAMENTO TABELLA ZM.TBADMSG         *
      *****************************************************************

           PERFORM 100-SCRIVI-ADMSG    THRU 100-SCRIVI-ADMSG-END

      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
      *
      * CAMPO-20
           MOVE SPACES TO RIGA-SW
           MOVE 3 TO RIGA-1
           MOVE ':' TO RIGA-2
           MOVE 20 TO RIGA-3
           MOVE ':' TO RIGA-4
           MOVE 'RIFERIMENTO' TO RIGA-6
           MOVE L-DATA TO RIGA-7
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 210-CAMPO20         THRU 210-CAMPO20-END
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
      * EX-CAMPO-20
      * CAMPO-25
           MOVE SPACES TO RIGA-SW
           MOVE 3 TO RIGA-1
           MOVE ':' TO RIGA-2
           MOVE 25 TO RIGA-3
           MOVE ':' TO RIGA-4
           MOVE 'NUMERO CONTO' TO RIGA-6
      *---------------- INIZIO A0004 ---------------------------------*
      *    MOVE NUMERO-CONTO     TO RIGA-7
           MOVE W-NUMERO-CONTO     TO RIGA-7
      *---------------- FINIZIO A0004 ---------------------------------*
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 220-CAMPO25         THRU 220-CAMPO25-END
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
      * EX-CAMPO-25
      * CAMPO-28
           MOVE SPACES TO RIGA-SW
           MOVE 3 TO RIGA-1
           MOVE ':' TO RIGA-2
           MOVE 28 TO RIGA-3
           MOVE ':' TO RIGA-4
           MOVE 'NUMERO ESTRATTO' TO RIGA-6
           MOVE NUMERO-ESTRATTO     TO NUM-71
           MOVE KONT-70             TO NUM-73
           MOVE NUM-70              TO RIGA-7
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 230-CAMPO28         THRU 230-CAMPO28-END
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
      * EX-CAMPO-28
      * CAMPO-60M
           MOVE SPACES TO RIGA-SW
           MOVE 3 TO RIGA-1
           MOVE ':' TO RIGA-2
           MOVE 60 TO RIGA-3
           MOVE 'M' TO RIGA-4
           MOVE ':' TO RIGA-5
           MOVE 'SALDO INIZIALE PARZIALE' TO RIGA-6
           MOVE SGN-70              TO SLD-71
           MOVE S-DATA              TO SLD-72
           MOVE DIVISA              TO SLD-73
           MOVE SAL-70              TO COM-IMPORTO
           MOVE 0 TO K
           PERFORM ROUT-IMP THRU END-ROUT-IMP
           MOVE COM-IMPORTO-1       TO SLD-74
           MOVE SLD-70              TO RIGA-7
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 260-CAMPO60M        THRU 260-CAMPO60M-END
           END-IF.
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
      * EX-CAMPO-60M.
           MOVE OPERAZIONE OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO  OF ZMRK0562 TO ZMOFD021.
           MOVE DESCOPE    OF ZMOFD011 TO DATA-B.
           MOVE DVAL       OF ZMOFD021 TO DATA-C.
           MOVE IMOV  OF ZMOFD021 TO IMOV-70.
           ADD  IMOV  OF ZMOFD021 TO SAL-72.
           IF IMOV-70 < 0 THEN
              MOVE 'D' TO MOV-73
           ELSE
              MOVE 'C' TO MOV-73.
       CAMPO-61.
           MOVE SPACES TO RIGA-SW.
           MOVE 3 TO RIGA-1.
           MOVE ':' TO RIGA-2.
           MOVE 61 TO RIGA-3.
           MOVE ':' TO RIGA-4.
           MOVE 'MOVIMENTO     ' TO RIGA-6.
           MOVE P-DATA              TO MOV-71.
           MOVE Q-DATA              TO MOV-72.
           MOVE IMOV-70             TO COM-IMPORTO.
           MOVE 0 TO K.
           PERFORM ROUT-IMP THRU END-ROUT-IMP.
           MOVE COM-IMPORTO-1       TO MOV-74.
           ADD 1 TO K.
      ***
           IF CCAUNOP OF ZMOFD021 NOT = SPACES AND NOT = LOW-VALUE
              MOVE 'N'                 TO TIP-092-1
              MOVE CCAUNOP OF ZMOFD021 TO TIP-092-2
           ELSE
              MOVE CPCS    OF ZMOFD011 TO CPCS-092-I
              PERFORM ZMWCI092 THRU EX-ZMWCI092
           END-IF.
      ***------------------------ INIZIO - A0001 -------------------***
           MOVE 'NMSC'              TO TIP-092.
      ***------------------------ FINE   - A0001 -------------------***
           MOVE TIP-092             TO COD-TRA.
           MOVE COD-TRA             TO ELEMENTO.
           MOVE NPRGOPE-T OF ZMRK0562 TO CAMPO-OPERAZIONE.
990429***  IF CAMPO-AA = 66
990429     IF CAMPO-AA = 00
              MOVE 'FINT' TO ELEMENTO.
           MOVE 4                   TO LUNG.
           PERFORM COMPATTA THRU EX-COMPATTA.
      ***
           IF LORORIF OF ZMRK0562 NOT = SPACES
              AND NOT = HIGH-VALUE
              MOVE LORORIF OF ZMRK0562 TO ELEMENTO
           ELSE
              IF NOPELOR OF ZMOFD011 NOT = SPACES
              AND NOT = HIGH-VALUE
                 MOVE NOPELOR OF ZMOFD011 TO ELEMENTO
              ELSE
                 MOVE 'NONE' TO ELEMENTO.
      *---------------------------------------------------------------*
      *       MOVE DPZMTT-T  OF ZMRK0562 TO CD-71                     *
      *       MOVE NPRGOPE-T OF ZMRK0562 TO CD-72                     *
      *       MOVE DEC-70              TO ELEMENTO.                   *
      *---------------------------------------------------------------*
           MOVE 0 TO NUM-CH.
           PERFORM CONTA-CH THRU EX-CONTA-CH.
           MOVE NUM-CH              TO LUNG.
           PERFORM COMPATTA THRU EX-COMPATTA.
SAF   *    MOVE CDPZRIF OF ZMOFD011 TO CD-71.
SAF   *    MOVE NOPERIF OF ZMOFD011 TO CD-72.
SAF   *    IF CD-71 = 0 OR CD-72 = 0 THEN
              MOVE DPZMTT-T  OF ZMRK0562 TO CD-71
              MOVE NPRGOPE-T OF ZMRK0562 TO CD-72.
           MOVE DEC-70              TO CD-74.
           MOVE DEC-71              TO ELEMENTO.
           MOVE 14                  TO LUNG.
           PERFORM COMPATTA THRU EX-COMPATTA.
           IF DESCRIF OF ZMRK0562 NOT = SPACES THEN
              MOVE DESCRIF OF ZMRK0562 TO DEC-72
SAF           MOVE SPACES              TO DEC-72-1
SAF           MOVE '//'                TO DEC-72-1-X
SAF           MOVE DEC-72-A            TO DEC-72-1-A
SAF           IF DEC-72-B NOT = SPACES THEN
SAF              MOVE '//'                TO DEC-72-1-Y
SAF              MOVE DEC-72-B            TO DEC-72-1-B
SAF              IF DEC-72-C NOT = SPACES THEN
SAF                 MOVE '//'                TO DEC-72-1-Z
SAF                 MOVE DEC-72-C            TO DEC-72-1-C
SAF              ELSE
SAF                 MOVE SPACES              TO DEC-72-1-Z DEC-72-1-C
SAF              END-IF
SAF           ELSE
SAF              MOVE SPACES              TO DEC-72-1-Y DEC-72-1-B
SAF                                          DEC-72-1-Z DEC-72-1-C
SAF           END-IF
SAF   *       MOVE DEC-72              TO ELEMENTO
SAF   *       MOVE 34                  TO LUNG
SAF           MOVE DEC-72-1            TO ELEMENTO
SAF           MOVE 40                  TO LUNG
              PERFORM COMPATTA THRU EX-COMPATTA.
      *
           MOVE MOV-70              TO RIGA-7.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *---------------------------------------------------------------*
           MOVE 1   TO  WRK-BYTE-DA
           ADD  1   TO  WRK-NR-PRG
990603     MOVE 35               TO  LIMITE
           PERFORM 270-CAMPO61 THRU 270-CAMPO61-END
           VARYING WRK-IND5 FROM 1 BY 1
             UNTIL RIGA-7(WRK-BYTE-DA:35) NOT > SPACES.
      *---------------------------------------------------------------*
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************
       EX-CAMPO-61.
       EX-DATI-01-SWI.
           EXIT.
      *
       CONTA-CH.
           PERFORM CONTA-CH-1 VARYING L FROM 16 BY -1 UNTIL L < 1.
           COMPUTE NUM-CH = 16 - NUM-CH.
           GO TO EX-CONTA-CH.
       CONTA-CH-1.
           IF ELE (L) = ' ' THEN
              ADD 1 TO NUM-CH.
       EX-CONTA-CH.
           EXIT.
      *
       COMPATTA.
           PERFORM COMPA-1 VARYING L FROM 1 BY 1 UNTIL L > LUNG.
           GO TO EX-COMPATTA.
       COMPA-1.
           MOVE ELE (L) TO MOV-741 (K).
           ADD 1 TO K.
       EX-COMPATTA.
           EXIT.
      *
       SALVA-DATI-02.
           DISPLAY 'SONO IN SALVA DATI 02'.

           MOVE DATIANAG   OF ZMRK0563 TO ZMODD025.

LILLA      DISPLAY 'FLAG PERIOD. ESTRAT = ' TAVVERGI OF ZMODD025.

           IF TAVVERGI OF ZMODD025 = 'NES' THEN
              GO TO EX-SALVA-DATI-02.

           PERFORM DATI-02-TAB THRU EX-DATI-02-TAB.

           IF TAVVERGI OF ZMODD025 = 'LTT' OR = 'RAC' THEN
              PERFORM DATI-02-LTT THRU EX-DATI-02-LTT.

           IF TAVVERGI OF ZMODD025 = 'SW1' OR = 'SW2' OR
                                   = 'SW3' OR = 'SW4' THEN
              PERFORM DATI-02-SWI THRU EX-DATI-02-SWI.
       EX-SALVA-DATI-02.
           EXIT.
      *
       DATI-02-TAB.
           MOVE OPERAZIONE  OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO   OF ZMRK0562 TO ZMOFD021.
           MOVE IMOV        OF ZMOFD021 TO SAL-51.
      *
              PERFORM R-IMP-3 THRU END-R-IMP-3
      *
           IF SAL-51 < 0 THEN
              MOVE 'D'       TO SGN-51
              MOVE 'DEBITO'  TO DEC-52
           ELSE
              MOVE 'C'       TO SGN-51
              MOVE 'CREDITO' TO DEC-52.
           MOVE 'FINALE ' TO DEC-51.
           MOVE DESCOPE OF ZMOFD011 TO DATA-A.
           MOVE CORR DATA-AR TO DATAXX.
           MOVE DATAXX TO CD-2.
           MOVE 'AL '  TO CD-1.
           COMPUTE SAL-51 = SAL-51 - ISBIMPMA
      *
              PERFORM R-IMP-LIQ THRU END-R-IMP-LIQ
      *
           IF SAL-51 < 0 THEN
              MOVE 'D'       TO SGN-51-A
              MOVE 'DEBITO'  TO DEC-52-A
           ELSE
              MOVE 'C'       TO SGN-51-A
              MOVE 'CREDITO' TO DEC-52-A.
           MOVE 'LIQUIDO' TO DEC-51-A.
       EX-DATI-02-TAB.
           EXIT.
      *
       DATI-02-LTT.
           MOVE ZRAGSOC OF ZMOCD011 TO ZRAGSOC-L.
           MOVE ZIND    OF ZMOCD011 TO ZIND-L.
           MOVE ZINDCOR OF ZMODD025 TO ZCTA-L.
           MOVE ZCTACOR OF ZMODD025 TO ZPAE-L.
           MOVE OPERAZIONE  OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO   OF ZMRK0562 TO ZMOFD021.
           MOVE IMOV        OF ZMOFD021 TO SAL-61.
      *
           PERFORM R-IMP-6 THRU END-R-IMP-6
      *
           MOVE SPACES  TO CAMPO42 FRASE-13.
           IF CLIN-60 = 1 THEN
              MOVE 'SALDO '    TO D-30
              MOVE 'FINALE  '  TO D-31
              MOVE ' A VS. '   TO D-32
              MOVE ' AL '      TO D-34.
           IF CLIN-60 = 2 THEN
              MOVE 'CLOSIN'    TO D-30
              MOVE 'G BALANC'  TO D-31
              MOVE 'E AS AT'   TO D-32.
           IF CLIN-60 = 3 THEN
              MOVE 'SCHLUS'    TO D-30
              MOVE 'SALDO ZU'  TO D-31
              MOVE ' IHREN '   TO D-32
              MOVE '    '      TO D-34.
           IF CLIN-60 = 4 THEN
              MOVE 'CLOSIN'    TO D-30
              MOVE 'G BALANC'  TO D-31
              MOVE 'E AS AT'   TO D-32.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'DEBITO '  TO D-33.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'DEBIT  '  TO FRASE-13.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'LASTEN '  TO D-33.
           IF SAL-61 < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'DEBIT  '  TO FRASE-13.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 1 THEN
                 MOVE 'CREDITO'  TO D-33.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 2 THEN
                 MOVE 'CREDIT '  TO FRASE-13.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 3 THEN
                 MOVE 'GUNSTEN'  TO D-33.
           IF SAL-61 NOT < 0 THEN
              IF CLIN-60 = 4 THEN
                 MOVE 'CREDIT '  TO FRASE-13.
           MOVE DESCOPE OF ZMOFD011 TO DATA-A.
           MOVE CORR DATA-AR TO DATAXX.
           IF CLIN-60 = 1 THEN
              MOVE DATAXX TO D-35.
           IF CLIN-60 = 2 THEN
              MOVE DATAXX TO D-35.
           IF CLIN-60 = 3 THEN
              MOVE DATAXX TO D-35.
           IF CLIN-60 = 4 THEN
              MOVE DATAXX TO D-35.
           MOVE CAMPO42 TO FRASE-08.
           IF CLIN-60 = 1 THEN
              MOVE 'VI PREGHIAMO DI VERIFICARE QUESTO '    TO FRASE-09
              MOVE 'ESTRATTO E DI COMUNICARCI'             TO FRASE-10
              MOVE 'IMMEDIATAMENTE EVENTUALI DIFFERENZE'   TO FRASE-11.
           IF CLIN-60 = 2 THEN
              MOVE 'PLEASE CHECK THIS STATEMENT OF ACC'    TO FRASE-09
              MOVE 'OUNT AND INFORM US       '             TO FRASE-10
              MOVE 'IMMEDIATELY OF ANY DISCREPANCY     '   TO FRASE-11.
           IF CLIN-60 = 3 THEN
              MOVE 'WIR BITTEN SIE, DEN AUSZUG ZU UEBE'    TO FRASE-09
              MOVE 'RPRUEFEN UND EINWENDUNGEN'             TO FRASE-10
              MOVE 'UNVERZUEGLICH ZU ERHEBEN           '   TO FRASE-11.
           IF CLIN-60 = 4 THEN
              MOVE 'PLEASE CHECK THIS STATEMENT OF ACC'    TO FRASE-09
              MOVE 'OUNT AND INFORM US       '             TO FRASE-10
              MOVE 'IMMEDIATELY OF ANY DISCREPANCY     '   TO FRASE-11.
       EX-DATI-02-LTT.
           EXIT.
      *
       DATI-02-SWI.
           MOVE OPERAZIONE  OF ZMRK0562 TO ZMOFD011.
           MOVE MOVIMENTO   OF ZMRK0562 TO ZMOFD021.
           MOVE IMOV        OF ZMOFD021 TO SAL-71.
           IF SAL-71 < 0 THEN
              MOVE 'D'       TO SGN-71
           ELSE
              MOVE 'C'       TO SGN-71.
           MOVE DESCOPE OF ZMOFD011 TO DATA-C.
       CAMPO-62F.
           MOVE SPACES TO RIGA-SW.
           MOVE 3 TO RIGA-1.
           MOVE ':' TO RIGA-2.
           MOVE 62 TO RIGA-3.
           MOVE 'F' TO RIGA-4.
           MOVE ':' TO RIGA-5.
           MOVE 'SALDO FINALE' TO RIGA-6.
           MOVE SGN-71              TO SLD-71.
           MOVE P-DATA              TO SLD-72.
           MOVE DIVISA              TO SLD-73.
           MOVE SAL-71              TO COM-IMPORTO.
           MOVE 0 TO K.
           PERFORM ROUT-IMP THRU END-ROUT-IMP.
           MOVE COM-IMPORTO-1       TO SLD-74.
           MOVE SLD-70              TO RIGA-7.
           PERFORM 2200-STAMPA7
              THRU 2200-STAMPA7-END.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 15-05-97 - INIZIO -            *
      *---------------------------------------------------------------*
           PERFORM 280-CAMPO62F
              THRU 280-CAMPO62F-END.
       EX-CAMPO-62F.
      *
      *CAMPO-64.
      *    COMPUTE SAL-71 = SAL-71 - ISBIMPMA
      *    IF SAL-71 < 0 THEN
      *       MOVE 'D'       TO SGN-71
      *    ELSE
      *       MOVE 'C'       TO SGN-71.
      *    MOVE SPACES TO RIGA-SW.
      *    MOVE 3 TO RIGA-1.
      *    MOVE ':' TO RIGA-2.
      *    MOVE 64 TO RIGA-3.
      *    MOVE ':' TO RIGA-4.
      *    MOVE 'SALDO LIQUIDO' TO RIGA-6.
      *    MOVE SGN-71              TO SLD-71.
      *    MOVE P-DATA              TO SLD-72.
      *    MOVE DIVISA              TO SLD-73.
      *    MOVE SAL-71              TO COM-IMPORTO.
      *    MOVE 0 TO K.
      *    PERFORM ROUT-IMP THRU END-ROUT-IMP.
      *    MOVE COM-IMPORTO-1       TO SLD-74.
      *    MOVE SLD-70              TO RIGA-7.
      *    PERFORM 2200-STAMPA7
      *       THRU 2200-STAMPA7-END.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 15-05-97 - INIZIO -            *
      *    SCRIVE IL TAG ANCHE NEL DMSGO                              *
      *---------------------------------------------------------------*
      *    PERFORM 290-CAMPO64
      *       THRU 290-CAMPO64-END.
      *EX-CAMPO-64.
       EX-DATI-02-SWI.
           EXIT.
      *
       LEGGI-INVENTARIO.
           DISPLAY 'SONO IN INVENTARIO '.
           READ ZMUN0563 AT END
                MOVE HIGH-VALUE TO RAP-INV-X
                GO TO EX-LEGGI-INVENTARIO.
      *
              DISPLAY 'LEGGI INV ' CAMPO-ISTITUTO.
              DISPLAY ' CIST-T  '  CIST-T OF ZMRK0563.
              DISPLAY ' CSTC-T = ' CSTC-T OF ZMRK0563 '<'.
              DISPLAY ' CISO-T = ' CISO-T OF ZMRK0563 '<'.
      *
           IF CAMPO-ISTITUTO NOT = CIST-T OF ZMRK0563
              PERFORM READ-PARAMETRO THRU EX-READ-PARAMETRO
              PERFORM AZZERA-TABELLA THRU EX-AZZERA-TABELLA
              PERFORM READ-TABELLA THRU EX-READ-TABELLA
              MOVE CIST-T OF ZMRK0563 TO CAMPO-ISTITUTO.
      *
           MOVE DATIANAG   OF ZMRK0563 TO ZMODD025.
           MOVE SCADENZA   OF ZMRK0563 TO ZMODD021.
      *
           MOVE ANAGRAFICO OF ZMRK0563 TO ZMOCD011.
           IF TNDGSET OF ZMOCD011 = 1
              GO TO LEGGI-INVENTARIO.
      *
           MOVE ZMODD025 TO DATIANAG OF ZMRK0563.
           MOVE CIST-T     OF ZMRK0563  TO CIST     OF RAP-INV.
           MOVE CTIPSTC-T  OF ZMRK0563  TO CTIPSTC  OF RAP-INV.
           MOVE CSTC-T     OF ZMRK0563  TO CSTC     OF RAP-INV.
           MOVE CISO-T     OF ZMRK0563  TO CISO     OF RAP-INV.
           MOVE NNDG-T     OF ZMRK0563  TO NNDGSET  OF RAP-INV.
           MOVE NSUFABT-T  OF ZMRK0563  TO NSUFABT  OF RAP-INV.
           MOVE DPZMTT-T   OF ZMRK0563  TO DPZMTT   OF RAP-INV.
      *
       EX-LEGGI-INVENTARIO.
           EXIT.
      *
       LEGGI-MOVIMENTI.
           READ ZMUN0562 AT END
                MOVE HIGH-VALUE TO RAP-MOV-X
                GO TO EX-LEGGI-MOVIMENTI.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE13.
           MOVE OPERAZIONE  OF ZMRK0562  TO ZMOFD011.
           MOVE MOVIMENTO   OF ZMRK0562  TO ZMOFD021.
           MOVE CIST-T      OF ZMRK0562  TO CIST     OF RAP-MOV.
           MOVE CTIPSTC     OF ZMOFD021  TO CTIPSTC  OF RAP-MOV.
           MOVE CSTC        OF ZMOFD021  TO CSTC     OF RAP-MOV.
           MOVE CISO        OF ZMOFD021  TO CISO     OF RAP-MOV.
           MOVE NNDGSET     OF ZMOFD021  TO NNDGSET  OF RAP-MOV.
           MOVE NSUFABT     OF ZMOFD021  TO NSUFABT  OF RAP-MOV.
           MOVE CDPZ        OF ZMOFD021  TO DPZMTT   OF RAP-MOV.
       EX-LEGGI-MOVIMENTI.
           EXIT.
      *
       RICERCA-UTE.
      *******************************************
      * RICERCA UTENTE NELLA TABELLA IN MEMORIA *
      *******************************************
           MOVE 0 TO INDICE-UTE.
       LBL0-UTE.
           ADD 1 TO INDICE-UTE.
      ***--------------------- INIZIO - 00005 -----------------------***
      *    IF INDICE-UTE > 1500 THEN
           IF INDICE-UTE > WN-DIM-UTEN THEN
      ***---------------------  FINE  - 00005 -----------------------***
              GO TO ERRORE2.
           IF SSA-UTE > ESCAD021 OF UTE (INDICE-UTE) THEN
                                           GO TO LBL0-UTE.
           IF SSA-UTE = ESCAD021 OF UTE (INDICE-UTE) THEN
                                           GO TO EX-RICERCA-UTE.
           MOVE 999 TO INDICE-UTE.
       EX-RICERCA-UTE.
           EXIT.
      *
       EJECT
       AZZ-REC-TESTATA.
           MOVE SPACES TO SALVA-TESTATA.
           MOVE ZERO TO CIST       OF SALVA-TESTATA
                        CTIPSTC    OF SALVA-TESTATA
                        CSTC       OF SALVA-TESTATA
                        NNDGSET    OF SALVA-TESTATA
                        CISO       OF SALVA-TESTATA
                        NSUFABT    OF SALVA-TESTATA
                        DPZMTT     OF SALVA-TESTATA
                        DULTESTR   OF SALVA-TESTATA
                        NUM-ESTR   OF SALVA-TESTATA
                        SALDO-ESTR OF SALVA-TESTATA.
       EX-AZZ-REC-TESTATA.
           EXIT.
      *
       ROUT-IMP.
           MOVE SPACES TO COM-IMPORTO-1.
           IF ELE-IMP (17) = '0'
              MOVE SPACE TO ELE-IMP (17)
              IF ELE-IMP (16) = '0'
                 MOVE SPACE TO ELE-IMP (16)
                 IF ELE-IMP (15) = '0'
                    MOVE SPACE TO ELE-IMP (15).
           PERFORM ROUT-IMP-1 VARYING L FROM 1 BY 1 UNTIL L > 17.
           GO TO END-ROUT-IMP.
       ROUT-IMP-1.
           IF ELE-IMP (L) NOT EQUAL ' '
              ADD 1 TO K
              MOVE ELE-IMP (L) TO ELE-IMP-1 (K).
       END-ROUT-IMP.
           EXIT.
      *
       R-IMP-1.
           MOVE SPACES TO SALX50.
           IF DIVISA = 'ITL' THEN
              MOVE SAL-50 TO SALI50
           ELSE
              MOVE SAL-50 TO SALV50.
       END-R-IMP-1.
           EXIT.
      *
       R-IMP-2.
           MOVE SPACES TO MOVX50.
           IF DIVISA = 'ITL' THEN
              MOVE IMOV-50 TO MOVI50
           ELSE
              MOVE IMOV-50 TO MOVV50.
       END-R-IMP-2.
           EXIT.
      *
       R-IMP-3.
           MOVE SPACES TO SALX51.
           IF DIVISA = 'ITL' THEN
              MOVE SAL-51 TO SALI51
           ELSE
              MOVE SAL-51 TO SALV51.
       END-R-IMP-3.
           EXIT.
      *
       R-IMP-LIQ.
           MOVE SPACES TO SALX51-A.
           IF DIVISA = 'ITL' THEN
              MOVE SAL-51 TO SALI51-A
           ELSE
              MOVE SAL-51 TO SALV51-A.
       END-R-IMP-LIQ.
           EXIT.
      *
       R-IMP-4.
           MOVE SPACES TO SALX60.
           IF DIVISA = 'ITL' THEN
              MOVE SAL-60 TO SALI60
           ELSE
              MOVE SAL-60 TO SALV60.
       END-R-IMP-4.
           EXIT.
      *
       R-IMP-5.
           MOVE SPACES TO MOVX60.
           IF DIVISA = 'ITL' THEN
              MOVE IMOV-60 TO MOVI60
           ELSE
              MOVE IMOV-60 TO MOVV60.
       END-R-IMP-5.
           EXIT.
      *
       R-IMP-6.
           MOVE SPACES TO SALX61.
           IF DIVISA = 'ITL' THEN
              MOVE SAL-61 TO SALI61
           ELSE
              MOVE SAL-61 TO SALV61.
       END-R-IMP-6.
           EXIT.
       REC-TESTATA.
           MOVE IST-COMODO         TO CIST       OF SALVA-TESTATA.
           MOVE CONTATORE          TO NUM-ESTR   OF SALVA-TESTATA.
           MOVE SALVA-TESTATA      TO ZMRK0568.
      *
           IF AA-OGGI NOT = AA-DOMANI THEN
              MOVE 0 TO NUM-ESTR OF ZMRK0568.
      *
           WRITE ZMRK0568.
           IF  I-O-TEST NOT = '00'
               GO TO ERRORE16.
       EX-REC-TESTATA.
           EXIT.
       ERRORE1.
           DISPLAY 'ZMPDC056 - ERRORE APPARIGLIAMENTO FILE  '
           MOVE 999 TO RETURN-CODE
           GO TO FINE.
       ERRORE2.
           MOVE 999 TO RETURN-CODE
           DISPLAY 'ZMPDC056 - ERRORE RICERCA ELEMENTO IN TABELLA'.
           GO TO FINE.
       ERRORE3.
           MOVE 999 TO RETURN-CODE
           DISPLAY 'ZMPDC056 - ERRORE LETTURA FILE  PARAMETRO    '.
           GO TO FINE.
       ERRORE4.
           MOVE 999 TO RETURN-CODE
           DISPLAY 'ZMPDC056 - ERRORE LETTURA TABELLA'.
           GO TO FINE.
       ERRORE01.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE OPEN FILE ZMUN0561'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE02.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE OPEN FILE ZMUN0562'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE03.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE OPEN FILE ZMUN0563'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE04.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE OPEN FILE ZMUN0564'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE05.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE OPEN FILE ZMUN0569'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE06.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE OPEN FILE ZMUN0568'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE07.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE OPEN FILE ZMUN056A'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE08.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE READ FILE ZMUN0561'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE09.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE READ FILE ZMUN0561'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE10.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE READ FILE ZMUN0569'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE11.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE READ FILE ZMUN0564'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE12.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE READ FILE ZMUN0563'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE13.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE READ FILE ZMUN0562'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE14.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE WRITE FILE ZMUN0568'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE15.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE WRITE FILE ZMUN056A'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
       ERRORE16.
           MOVE 999 TO RETURN-CODE.
           DISPLAY 'ZMPDC056 - ERRORE WRITE FILE ZMUN0568'.
           DISPLAY 'ZMPDC056 - CODICE VSAM : ' I-O-TEST.
           GO TO FINE.
      *
      ***----------------------- INIZIO - 00005 --------------------***
      *
       ERRORE-DIM.
           DISPLAY 'ZMPDC056 - TABELLA '  WX-NOMTAB  ' TROPPO PICCOLA.'.
           MOVE 999 TO RETURN-CODE.
           GO TO FINE.
      *
      ***----------------------- FINE - 00005 ----------------------***
      *
       WRITE-FINE.
           MOVE 0 TO RETURN-CODE.
           IF IND-DMSGO GREATER ZEROS
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              PERFORM 110-SCRIVI-ASPOOL
                 THRU 110-SCRIVI-ASPOOL-END
           END-IF.
           DISPLAY 'ZMPDC056 - ESTRATTI VIA LETTERA : ' CONTA-LTT
                              '  ESTRATTI VIA SWIFT : ' CONTA-SWI.
           DISPLAY 'ZMPDC056 - CHIUDE BENE'.
       FINE.
           IF RETURN-CODE NOT = 0
              DISPLAY 'RETURN CODE' RETURN-CODE
              GO TO 999-ABEND.
           CLOSE ZMUN0561 ZMUN0562 ZMUN0563 ZMUN0564
                 ZMUS0565 ZMUS0566 ZMUS0567 ZMUN0568 ZMUN0569 ZMUN056A.
           COPY SYWCI006.
           STOP RUN.
      *
           COPY ZMWCI092.

      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 - INIZIO -            *
      *****************************************************************
      *---------------------------------------------------------------*
      *          INSERIMENTO AGGIORNAMENTO TABELLA ZM.TBADMSG         *
      *---------------------------------------------------------------*
       100-SCRIVI-ADMSG.

           IF IND-DMSGO GREATER ZEROS
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              PERFORM 110-SCRIVI-ASPOOL
                 THRU 110-SCRIVI-ASPOOL-END
              MOVE  ZEROS              TO  W-NPRGRIGA
           END-IF.
           MOVE  CIST-T   OF ZMRK0563  TO  DMSG-CIST.
           MOVE  1                     TO  DMSG-CLIN.
           MOVE  SPACES                TO  DMSG-CSIGTLX.
           MOVE  DLAV-P                TO  DMSG-DGENAVV.
           MOVE  DPZMTT-T OF ZMRK0563  TO  DMSG-DIPOPE.
           MOVE  ZEROS                 TO  DMSG-MATRANN.
           MOVE  0                     TO  DMSG-NMTRAULV1.
           MOVE  0                     TO  DMSG-NMTRAULV2.
           MOVE  NNDG-T   OF ZMRK0563  TO  DMSG-NNDGSET.
           MOVE  90                    TO  COMODO-PREF.
      *----------------------------------------------------------------
      * IL CONTATORE VIENE PRESO DA TUTENO E MOSSO NEL CAMPO
      * "CONTATORE" QUANDO IL VECCHIO PROGRAMMA FACEVA LA ADD.
      * QUESTO PER VALORIZZARE CORRETTAMENTE ANCHE I CAMPI DI STAMPA
      *--MODIFICA  ----------------------------------------------------
      *    MOVE  CONTATORE             TO  COMODO-CONT.
      *    MOVE  NUMOPE-NUMERICO       TO  DMSG-NUMOPE.
           MOVE  CONTATORE             TO  DMSG-NUMOPE.
           DISPLAY 'CONTATORE' CONTATORE.
           MOVE  5                     TO  DMSG-STATUS.
           MOVE  ZINDSWF  OF ZMODD025  TO  COMODO-ZINDSWF.
           MOVE  COMODO-SWFBCH         TO  DMSG-SWFBCH.
           MOVE  COMODO-SWFNDG         TO  DMSG-SWFNDG.
           MOVE  COMODO-SWFPAE         TO  DMSG-SWFPAE.
           MOVE  COMODO-SWFREG         TO  DMSG-SWFREG.
           MOVE  TAVVERGI OF ZMODD025  TO  DMSG-TAVV.
           IF TNDGSET OF ZMOCD011 = 1 AND
              ZINDSWF OF ZMODD025 NOT = SPACES
              MOVE  940                TO  DMSG-TTCLIC
           ELSE
              MOVE  950                TO  DMSG-TTCLIC.
           MOVE  ZEROS                 TO  DMSG-TTCPCSF.
           MOVE 'SW'                   TO  DMSG-TTFORMAT.
           MOVE  1                     TO  DMSG-TTSUBCLI.
           MOVE  ZCTA    OF ZMOCD011   TO  DMSG-ZCTA.
           MOVE  ZIND    OF ZMOCD011   TO  DMSG-ZIND.
           MOVE  ZPAE    OF ZMOCD011   TO  DMSG-ZPAE.
           MOVE  ZRAGSOC OF ZMOCD011   TO  DMSG-ZRAGSOC.
      *** FORZATURA
           MOVE ZEROES TO DMSG-NORDSTM.
      *** FORZATURA
           EXEC  SQL INCLUDE ZMV12101 END-EXEC.
           IF NOT W-SQL-OK
      ***------------------ INIZIO 00028 -----------------------***
      *       MOVE 9999 TO RETURN-CODE
      ***------------------  FINE  00028 -----------------------***
              DISPLAY 'ERRORE INSERIMENTO SU TAB. ZM.TBADMSG'
              DISPLAY 'INCLUDE ZMV12101'
DPS   *** DISPLAY DI PROVA ***
DPS           DISPLAY 'CHIAVE DI INSERT'
DPS           DISPLAY 'CIST.......: ' DMSG-CIST
DPS           DISPLAY 'DIPOPE.....: ' DMSG-DIPOPE
DPS           DISPLAY 'NNDGSET....: ' DMSG-NNDGSET
DPS           DISPLAY 'NUMOPE.....: ' DMSG-NUMOPE
DPS   *** DISPLAY DI PROVA ***
      *       DISPLAY 'SQL CODE = ' W-SQLCODE
              MOVE W-SQLCODE TO W-SQLCODE-X
              DISPLAY 'SQL CODE = ' W-SQLCODE-X
              MOVE SQLERRML  TO WN-SQLCODE
              DISPLAY 'SQLERRML: ' WN-SQLCODE
      ***------------------ INIZIO 00028 -----------------------***
              GO TO 999-ABEND.
      *       GO TO FINE.
      ***------------------  FINE  00028 -----------------------***
      ***---------------------- INIZIO - 00023 ---------------------***
      *    ADD 1                       TO  CONT-UPDATE.
      *    IF  CONT-UPDATE  >  500
      *    THEN
      *        EXEC SQL COMMIT END-EXEC
      *        MOVE 1                  TO  CONT-UPDATE.
      ***---------------------- FINE   - 00023 ---------------------***
      *                              **** SCRITTURA OPERAZIONE FITTIZIA
           INITIALIZE DCLTBAOPE.
           MOVE  DMSG-CIST             TO  OPE-CIST.
           MOVE  DMSG-DIPOPE           TO  OPE-DIPOPE.
VIRGI      MOVE  W-NUM-OPE             TO  OPE-NUMOPE.
VIRGI *    MOVE  DMSG-NUMOPE           TO  OPE-NUMOPE.
           MOVE  70                    TO  OPE-CPCS.
           MOVE  3                     TO  OPE-FELIOPE.
           MOVE  4                     TO  OPE-FTIPOPE.
           MOVE 'N'                    TO  OPE-FOPSTNATA.
           DISPLAY '-------------------'.
           DISPLAY 'CIST      ' OPE-CIST.
           DISPLAY 'DIP       ' OPE-DIPOPE.
           DISPLAY 'OPE       ' OPE-NUMOPE.
VIRGI      DISPLAY 'W-NUM-OPE ' W-NUM-OPE.
           DISPLAY '-------------------'.
           EXEC  SQL INCLUDE ZMV11501 END-EXEC.
           DISPLAY 'SQL CODE = ' W-SQLCODE.
           IF NOT W-SQL-OK
      ***---------------------- INIZIO - 00028 ---------------------***
      *       MOVE 9999 TO RETURN-CODE
      ***---------------------- FINE   - 00028 ---------------------***
              DISPLAY 'ERRORE INSERIMENTO SU TAB. ZM.TBAOPE'
              DISPLAY 'INCLUDE ZMV11501'
              DISPLAY 'SQL CODE = ' W-SQLCODE
      ***---------------------- INIZIO - 00028 ---------------------***
              GO TO 999-ABEND.
      ***---------------------- FINE   - 00028 ---------------------***
      ***---------------------- INIZIO - 00023 ---------------------***
      *    ADD 1                       TO  CONT-UPDATE.
      *    IF  CONT-UPDATE  >  500
      *    THEN
      *        EXEC SQL COMMIT END-EXEC
      *        MOVE 1                  TO  CONT-UPDATE.
      ***---------------------- FINE   - 00023 ---------------------***
       100-SCRIVI-ADMSG-END.
           EXIT.

      *---------------------------------------------------------------*
      *             --- GENERAZIONE STAMPA SU ASPOOL ---              *
      *---------------------------------------------------------------*
       110-SCRIVI-ASPOOL.
           DISPLAY '110-SCRIVI-ASPOOL ROUTINE'.
           MOVE  DMSG-CIST             TO L50-COMMAREA-CIST.
           MOVE  DMSG-NUMOPE           TO L50-COMMAREA-NUMOPE.
           MOVE  DMSG-DIPOPE           TO L50-COMMAREA-CDPZ.
           MOVE  DMSG-TTCLIC           TO L50-COMMAREA-TTCLIC.
           MOVE  DMSG-TTSUBCLI         TO L50-COMMAREA-TTSUBCLI.
           MOVE  DMSG-TTFORMAT         TO L50-COMMAREA-TTFORMAT.
           DISPLAY 'DMSG-CIST' DMSG-CIST
           DISPLAY 'DMSG-NUMO' DMSG-NUMOPE.
           DISPLAY 'DMSG-DIPO' DMSG-DIPOPE
      *** MODIFICA DI PROVA - INIZIO  (ZMBGESW0)
      *    MOVE 'ZMBGESW0'             TO WCM-CHIAMATO
      * === INIZIO - 0089A === *
LILLA      MOVE 'ZMBGESW1'             TO WCM-CHIAMATO
LILLA *    MOVE 'ZMBGESW0'             TO WCM-CHIAMATO
      * ===  FINE  - 0089A === *
      *** MODIFICA DI PROVA - FINE    (ZMBGESW0)
           EXEC  SQL INCLUDE ZMYCALLB END-EXEC
           IF L50-FLAG-ERR GREATER SPACES
           DISPLAY 'DMSG-TTCLIC' DMSG-TTCLIC
              DISPLAY L50-ZRETCOD
              DISPLAY L50-NOME-TABELLA
              DISPLAY L50-CODICE-SQL
              DISPLAY L50-MODULO
              DISPLAY L50-SUB-MODULO
      ***---------------------- FINE   - 00028 ---------------------***
      * === INIZIO - 0089A === *
LILLA         DISPLAY 'ERRORE ZMBGESW1       '
LILLA *       DISPLAY 'ERRORE ZMBGESW0       '
      * ===  FINE  - 0089A === *
              GO TO 999-ABEND.
      ***---------------------- INIZIO - 00028 ---------------------***
      ***     GO TO   FINE.
      ***

       110-SCRIVI-ASPOOL-END.
           EXIT.

      *---------------------------------------------------------------*
      *          INSERIMENTO AGGIORNAMENTO TABELLA ZM.TBADMSGO        *
      *---------------------------------------------------------------*
       200-SCRIVI-ADMSGO.
           MOVE  DMSG-CIST             TO  DMSGO-CIST.
           MOVE  DMSG-DIPOPE           TO  DMSGO-DIPOPE.
           MOVE  DMSG-NUMOPE           TO  DMSGO-NUMOPE.
           MOVE  DMSG-TTCLIC           TO  DMSGO-TTCLIC.
           MOVE  DMSG-TTFORMAT         TO  DMSGO-TTFORMAT.
           MOVE  DMSG-TTSUBCLI         TO  DMSGO-TTSUBCLI.
           ADD   1                     TO  W-NPRGRIGA.
           MOVE  W-NPRGRIGA            TO  DMSGO-NPRGRIGA.
           MOVE  W-TAB-DMSGO           TO  DMSGO-WTABMSGO-TEXT.
           EXEC SQL INCLUDE ZMV12201   END-EXEC.
           IF NOT W-SQL-OK
      ***---------------------- INIZIO - 00028 ---------------------***
      *       MOVE 9999 TO RETURN-CODE
      ***----------------------  FINE  - 00028 ---------------------***
              DISPLAY 'ERRORE INSERIMENTO SU TAB. ZM.TBADMSGO'
              DISPLAY 'INCLUDE ZMV12201'
              DISPLAY 'SQL CODE = ' W-SQLCODE
      ***---------------------- INIZIO - 00028 ---------------------***
              GO TO 999-ABEND.
      *       GO TO FINE.
      ***----------------------  FINE  - 00028 ---------------------***
           MOVE  SPACES                TO  W-TAB-DMSGO.
           MOVE  ZEROS                 TO  IND-DMSGO.
      ***---------------------- INIZIO - 00023 ---------------------***
      *    ADD   1                     TO  CONT-UPDATE.
      *    IF  CONT-UPDATE  >  500
      *    THEN
      *        EXEC SQL COMMIT END-EXEC
      *        MOVE 1                  TO  CONT-UPDATE.
      ***---------------------- FINE   - 00023 ---------------------***
       200-SCRIVI-ADMSGO-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 20       *
      *---------------------------------------------------------------*
       210-CAMPO20.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  1                     TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE '20'                   TO  WPRMGO-TTTAG (IND-DMSGO).
           MOVE  RIGA-7                TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
       210-CAMPO20-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 25       *
      *---------------------------------------------------------------*
       220-CAMPO25.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  1                     TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE '25'                   TO  WPRMGO-TTTAG (IND-DMSGO).
           MOVE  RIGA-7                TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
       220-CAMPO25-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 28       *
      *---------------------------------------------------------------*
       230-CAMPO28.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  1                     TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE '28C'                  TO  WPRMGO-TTTAG (IND-DMSGO).
           MOVE  RIGA-7                TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
       230-CAMPO28-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 60F      *
      *---------------------------------------------------------------*
       240-CAMPO60F.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  1                     TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE '60F'                  TO  WPRMGO-TTTAG (IND-DMSGO).
           MOVE  RIGA-7                TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
       240-CAMPO60F-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 62M      *
      *---------------------------------------------------------------*
       250-CAMPO62M.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  1                     TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE '62M'                  TO  WPRMGO-TTTAG (IND-DMSGO).
           MOVE  RIGA-7                TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
       250-CAMPO62M-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 60M      *
      *---------------------------------------------------------------*
       260-CAMPO60M.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  1                     TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE '60M'                  TO  WPRMGO-TTTAG (IND-DMSGO).
           MOVE  RIGA-7                TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
       260-CAMPO60M-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 61       *
      *---------------------------------------------------------------*
       270-CAMPO61.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  WRK-NR-PRG            TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE WRK-IND5               TO
                                        WPRMGO-TTPRGTAG(IND-DMSGO)(3:1)
           MOVE '61'                   TO  WPRMGO-TTTAG (IND-DMSGO).
      *----------------------INIZIO 00044--------------------------*
      *    MOVE RIGA-7(WRK-BYTE-DA:35) TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE RIGA-7(WRK-BYTE-DA:LIMITE)
                                 TO  WPRMGO-TTVALTAG (IND-DMSGO).
      *----------------------FINE   00044--------------------------*
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
           ADD  35                     TO  WRK-BYTE-DA.
      *----------------------INIZIO 00044--------------------------*
           IF WRK-BYTE-DA > 99
              GO TO 270-CAMPO61-END.
           COMPUTE APPO = WRK-BYTE-DA + 35.
           IF APPO  > 99
              COMPUTE LIMITE = 99 - WRK-BYTE-DA
           ELSE
              MOVE 35 TO LIMITE
           END-IF.
      *----------------------FINE   00044--------------------------*
       270-CAMPO61-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 62F      *
      *---------------------------------------------------------------*
       280-CAMPO62F.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  1                     TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE '62F'                  TO  WPRMGO-TTTAG (IND-DMSGO).
           MOVE  RIGA-7                TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
       280-CAMPO62F-END.
           EXIT.
      *---------------------------------------------------------------*
      *     PREPARA LA SCRITTURA DI ZM.TBADMSGO PER IL CAMPO 64       *
      *---------------------------------------------------------------*
       290-CAMPO64.
           ADD   1                     TO  IND-DMSGO.
           IF IND-DMSGO GREATER MAX-DMSGO
              PERFORM 200-SCRIVI-ADMSGO
                 THRU 200-SCRIVI-ADMSGO-END
              MOVE    1                TO  IND-DMSGO
           END-IF.
           MOVE  SPACES                TO  WPRMGO-TTSEQ (IND-DMSGO).
           MOVE  1                     TO  WPRMGO-TTPRGTAG (IND-DMSGO).
           MOVE '64'                   TO  WPRMGO-TTTAG (IND-DMSGO).
           MOVE  RIGA-7                TO  WPRMGO-TTVALTAG (IND-DMSGO).
           MOVE  SPACES                TO  WPRMGO-TTPSW (IND-DMSGO).
       290-CAMPO64-END.
           EXIT.
      *****************************************************************
      *            MODIFICA SISEB3 DEL 17-11-95 -  FINE  -            *
      *****************************************************************

       300-PRENOTA-CONTATORE.
      ***---------------- INIZIO - A0003 --------------------------***
           MOVE 70               TO APROC-CPCS.

           EXEC SQL INCLUDE ZMS20301 END-EXEC.

           MOVE W-SQLCODE TO WN-SQLCODE.

           IF W-SQLCODE NOT = ZEROES
              DISPLAY '*****  ZMPDC056  *****'
              DISPLAY 'TABELLA TBTAPROC  '
              DISPLAY 'ERRORE DB2 IN LETTURA'
              DISPLAY 'SQL CODE: ' W-SQLCODE
              GO TO 999-ABEND.

           EXEC SQL INCLUDE ZMS30901 END-EXEC.

           MOVE W-SQLCODE TO WN-SQLCODE.

           IF W-SQLCODE NOT = ZEROES
              DISPLAY '*****  ZMPDC056  *****'
              DISPLAY 'TABELLA TBWCONFG   '
              DISPLAY 'ERRORE DB2 IN LETTURA'
              DISPLAY 'SQL CODE: ' W-SQLCODE
              GO TO 999-ABEND.

           MOVE CONFG-ALTRIFLAG TO ZMWCONFG.
      ***- DISPLAY DI PROVA - DISPLAY DI PROVA - DISPLAY DI PROVA -***
      *    INITIALIZE DISP-UTENO-CCTRUTE,
      *               DISP-UTENO-CTROP,
      *               DISP-UTENO-CTROPE7.
      *
      *    MOVE DPZMTT-T OF ZMRK0563 TO UTENO-CUTE.
      *    IF CONFG-GESTNOPE = '0'
      *       EXEC SQL
      *             SELECT UTENO_CCTRUTE
      *                  , UTENO_CTROP
      *                  , UTENO_CTROPE7
      *             INTO :DISP-UTENO-CCTRUTE
      *                 ,:DISP-UTENO-CTROP
      *                 ,:DISP-UTENO-CTROPE7
      *             FROM TBTUTENO
      *             WHERE UTENO_CCTRUTE = 83
      *               AND UTENO_CUTE = :UTENO-CUTE
      *       END-EXEC
      *    ELSE
      *       EXEC SQL
      *             SELECT UTENO_CCTRUTE
      *                  , UTENO_CTROP
      *                  , UTENO_CTROPE7
      *             INTO :DISP-UTENO-CCTRUTE
      *                 ,:DISP-UTENO-CTROP
      *                 ,:DISP-UTENO-CTROPE7
      *             FROM TBTUTENO
      *             WHERE UTENO_CCTRUTE = 1
      *               AND UTENO_CUTE = :UTENO-CUTE
      *       END-EXEC
      *    END-IF.
      *
      *    DISPLAY '*****************************************'.
      *    DISPLAY '*** SELECT SU TUTENO PRIMA DI PRENOTA ***'.
      *    DISPLAY '*****************************************'.
      *    DISPLAY '** CUTE             : ' DPZMTT-T OF ZMRK0563.
      *    DISPLAY '** FASCIA (CCTRUTE) : ' DISP-UTENO-CCTRUTE.
      *    DISPLAY '** CONTATORE A 5+2 (CTROP) : ' DISP-UTENO-CTROP.
      *    DISPLAY '** CONTATORE A 7 (CTROPE7) : ' DISP-UTENO-CTROPE7.
      *    DISPLAY '*****************************************'.
      *    DISPLAY '*********** FINE DELLA SELECT ***********'.
      *    DISPLAY ' '.
      *    DISPLAY ' '.
      ***- FINE       PROVA - FINE       PROVA - FINE       PROVA -***


           MOVE    CIST-T   OF ZMRK0563    TO   NO-CIST.
           MOVE    DPZMTT-T OF ZMRK0563    TO   NO-CUTE.
           MOVE    APROC-CCTRPCS           TO   NO-CCTRUTE.
           MOVE    APROC-CPCS              TO   NO-CPCS.
           MOVE    CONFG-GESTNOPE          TO   NO-GESTNOPE.
           MOVE    DLAV-P   OF ZMRK0569    TO   NO-DATA-OGGI.

           MOVE 'ZMBNOPE1' TO WCM-CHIAMATO
           CALL WCM-CHIAMATO USING NO-COMU.

           IF NO-RC = 8 OR 2
              DISPLAY '**********************'
              DISPLAY '*****  ZMPDC056  *****'
              DISPLAY 'CHIAMATA ZMBNOPE1  '
              DISPLAY 'RET.CODE: ' NO-RC
CRM           DISPLAY 'COD.ERR.: ' NO-COD-ERR
CRM           DISPLAY 'TABELLA : ' NO-TABELLA
CRM           DISPLAY 'SQLCODE : ' NO-SQLCODE
CRM           DISPLAY 'SUB-MOD.: ' NO-SUB-MODULO
CRM           DISPLAY '**********************'
              GO TO 999-ABEND.
           MOVE NO-NUMOPE       TO W-NUM-OPE.
      ***- DISPLAY DI PROVA - DISPLAY DI PROVA - DISPLAY DI PROVA -***
      *    INITIALIZE DISP-UTENO-CCTRUTE,
      *               DISP-UTENO-CTROP,
      *               DISP-UTENO-CTROPE7.
      *
      *    IF CONFG-GESTNOPE = '0'
      *       EXEC SQL
      *             SELECT UTENO_CCTRUTE
      *                  , UTENO_CTROP
      *                  , UTENO_CTROPE7
      *             INTO :DISP-UTENO-CCTRUTE
      *                 ,:DISP-UTENO-CTROP
      *                 ,:DISP-UTENO-CTROPE7
      *             FROM TBTUTENO
      *             WHERE UTENO_CCTRUTE = 83
      *               AND UTENO_CUTE = :UTENO-CUTE
      *       END-EXEC
      *    ELSE
      *       EXEC SQL
      *             SELECT UTENO_CCTRUTE
      *                  , UTENO_CTROP
      *                  , UTENO_CTROPE7
      *             INTO :DISP-UTENO-CCTRUTE
      *                 ,:DISP-UTENO-CTROP
      *                 ,:DISP-UTENO-CTROPE7
      *             FROM TBTUTENO
      *             WHERE UTENO_CCTRUTE = 1
      *               AND UTENO_CUTE = :UTENO-CUTE
      *       END-EXEC
      *    END-IF.
      *
      *    DISPLAY '*****************************************'.
      *    DISPLAY '*** SELECT SU TUTENO DOPO  DI PRENOTA ***'.
      *    DISPLAY '*****************************************'.
      *    DISPLAY '** CUTE             : ' DPZMTT-T OF ZMRK0563.
      *    DISPLAY '** FASCIA (CCTRUTE) : ' DISP-UTENO-CCTRUTE.
     **    DISPLAY '** CONTATORE A 5+2 (CTROP) : ' DISP-UTENO-CTROP.
     **    DISPLAY '** CONTATORE A 7 (CTROPE7) : ' DISP-UTENO-CTROPE7.
      *    DISPLAY '*****************************************'.
      *    DISPLAY '*********** FINE DELLA SELECT ***********'.
      *    DISPLAY ' '.
      *    DISPLAY ' '.
      *
      ***- FINE       PROVA - FINE       PROVA - FINE       PROVA -***
      ***---------------- FINE   - A0003 --------------------------***

      ***---------------- INIZIO - A0003 --------------------------***
DPS   *    DISPLAY 'STO PRENDENDO IL CONTATORE 300-PRENOTA'.
DPS   *    MOVE    CIST-T   OF ZMRK0563 TO   UTENO-CIST.
DPS   *    MOVE    DPZMTT-T OF ZMRK0563 TO   UTENO-CUTE.
DPS  **    MOVE    90                   TO   UTENO-CCTRUTE.
DPS   *    MOVE    1                    TO   UTENO-CCTRUTE.
DPS   *    DISPLAY  '-----------------------------'
DPS   *    DISPLAY  'UTENO CIST  ' UTENO-CIST.
DPS   *    DISPLAY  'UTENO CUTE  ' UTENO-CUTE.
DPS   *    DISPLAY  'UTENO TRUTE ' UTENO-CCTRUTE.
DPS   *
DPS   *    EXEC SQL INCLUDE ZMS22501 END-EXEC.
DPS   *
DPS   *    MOVE W-SQLCODE TO WN-SQLCODE.
DPS   *    DISPLAY 'SQLCODE: ' WN-SQLCODE
DPS   *    MOVE SQLERRML  TO WN-SQLCODE
DPS   *    DISPLAY 'SQLERRML: ' WN-SQLCODE
DPS   *    DISPLAY  '-----------------------------'
DPS   *
DPS   *    IF W-SQL-NON-TROVATO
DPS   *       PERFORM 310-INSERT-TUTENO
DPS   *          THRU 310-INSERT-TUTENO-END
DPS   *    ELSE
DPS   *       IF W-SQL-OK
DPS  **          ADD     1            TO   UTENO-CTROP
DPS  **          COMPUTE W-NUM-OPE = UTENO-CCTRUTE * 100000
DPS  **                            + UTENO-CTROP
DPS   *          ADD     1             TO   UTENO-CTROPE7
DPS   *          MOVE    UTENO-CTROPE7 TO   W-NUM-OPE
DPS   *          DISPLAY  'UTENO OPE7 ' UTENO-CTROPE7
DPS   *          PERFORM 320-UPDATE-TUTENO
DPS   *             THRU 320-UPDATE-TUTENO-END
DPS   *       ELSE
DPS  ****----------------------- INIZIO - 00028 --------------------***
DPS  **          MOVE 9999 TO RETURN-CODE
DPS  ****-----------------------  FINE  - 00028 --------------------***
DPS   *          DISPLAY '*****  ZMPDC056  *****'
DPS   *          DISPLAY 'TABELLA ZM.TBTUTENO'
DPS   *          DISPLAY 'ERRORE DB2 IN LETTURA'
DPS   *          DISPLAY 'SQL CODE: ' W-SQLCODE
DPS  ****----------------------- INIZIO - 00028 --------------------***
DPS   *          GO TO 999-ABEND
DPS  **          GO TO FINE
DPS  ****-----------------------  FINE  - 00028 --------------------***
DPS   *       END-IF
DPS   *    END-IF.
DPS  **---- VERIFICA OPERAZIONE
DPS        INITIALIZE DCLTBAOPE.
DPS        MOVE    CIST-T   OF ZMRK0563 TO   OPE-CIST.
DPS        MOVE    DPZMTT-T OF ZMRK0563 TO   OPE-DIPOPE.
DPS        MOVE  W-NUM-OPE             TO  OPE-NUMOPE.
DPS        EXEC  SQL INCLUDE ZMS11501 END-EXEC.
DPS        DISPLAY 'SQL CODE = ' W-SQLCODE.
DPS        IF W-SQLCODE = ZEROES
DPS           GO TO 300-PRENOTA-CONTATORE
DPS        ELSE
DPS        IF W-SQLCODE NOT = 100
DPS           DISPLAY '*****  ZMPDC056  *****'
DPS           DISPLAY 'TABELLA ZM.TBAOPE  '
DPS           DISPLAY 'ERRORE DB2 IN LETTURA'
DPS           DISPLAY 'SQL CODE: ' W-SQLCODE
DPS           GO TO 999-ABEND.
DPS
DPS    300-PRENOTA-CONTATORE-END.
DPS        EXIT.
DPS   *
DPS   *310-INSERT-TUTENO.
DPS  **    MOVE 1                                TO UTENO-CTROP.
DPS  ****----------------------- INIZIO - 00022 --------------------***
DPS   *    MOVE 1                                TO UTENO-CTROPE7.
DPS  ****----------------------- FINE   - 00022 --------------------***
DPS   *    EXEC SQL INCLUDE ZMV22501 END-EXEC.
DPS   *    IF NOT W-SQL-OK
DPS  ****----------------------- INIZIO - 00028 --------------------***
DPS  **       MOVE 9999 TO RETURN-CODE
DPS  ****-----------------------  FINE  - 00028 --------------------***
DPS   *       DISPLAY '*****  ZMPDC056  *****'
DPS   *       DISPLAY 'TABELLA ZM.TBTUTENO'
DPS   *       DISPLAY 'ERRORE DB2 SU INSERT'
DPS  **       DISPLAY 'SQL CODE: ' W-SQLCODE
DPS   *       MOVE W-SQLCODE TO W-SQLCODE-X
DPS   *       DISPLAY 'SQL CODE: ' W-SQLCODE-X
DPS  ****----------------------- INIZIO - 00028 --------------------***
DPS   *       GO TO 999-ABEND
DPS  **       GO TO FINE
DPS  ****-----------------------  FINE  - 00028 --------------------***
DPS   *    END-IF.
DPS   *
DPS   *310-INSERT-TUTENO-END.
DPS   *    EXIT.
DPS   *
DPS   *320-UPDATE-TUTENO.
DPS   *    EXEC SQL INCLUDE ZMU22502 END-EXEC.
DPS   *    IF NOT W-SQL-OK
DPS  ****----------------------- INIZIO - 00028 --------------------***
DPS  **       MOVE 9999 TO RETURN-CODE
DPS  ****-----------------------  FINE  - 00028 --------------------***
DPS   *       DISPLAY '*****  ZMPDC056  *****'
DPS   *       DISPLAY 'TABELLA ZM.TBTUTENO'
DPS   *       DISPLAY 'ERRORE DB2 SU UPDATE'
DPS   *       DISPLAY 'SQL CODE: ' W-SQLCODE
DPS  ****----------------------- INIZIO - 00028 --------------------***
DPS   *       GO TO 999-ABEND
DPS  **       GO TO FINE
DPS  ****-----------------------  FINE  - 00028 --------------------***
DPS   *    END-IF.
DPS   *320-UPDATE-TUTENO-END.
DPS   *    EXIT.
      ***---------------- FINE   - A0003 --------------------------***

       400-FOOT5.
           MOVE  DEC-51            TO  S-DEC-51.
           MOVE  DEC-52            TO  S-DEC-52.
           MOVE  DEC-54            TO  S-DEC-54.
           MOVE  SALX51            TO  S-SALX51.
           MOVE  SGN-51            TO  S-SGN-51.
           WRITE ZMR0565         FROM  RIGA-BIANCA.
           WRITE ZMR0565         FROM  FOOT5-1.
           MOVE  DEC-51-A          TO  S-DEC-51-A.
           MOVE  DEC-52-A          TO  S-DEC-52-A.
           MOVE  SALX51-A          TO  S-SALX51-A.
           MOVE  SGN-51-A          TO  S-SGN-51-A.
           WRITE ZMR0565         FROM  RIGA-BIANCA.
           WRITE ZMR0565         FROM  FOOT5-2.
           MOVE  98                TO  CTR-RIG-5.

       400-FOOT5-END.
           EXIT.

       410-FOOT6.
           PERFORM VARYING CTR-RIG-6 FROM CTR-RIG-6 BY 1
             UNTIL CTR-RIG-6 = 55
              WRITE ZMR0566      FROM  RIGA-BIANCA
           END-PERFORM.
           MOVE  FRASE-08          TO  S-FRASE-08.
           MOVE  SALX61            TO  S-SALX61.
           MOVE  FRASE-13          TO  S-FRASE-13.
           WRITE ZMR0566         FROM  FOOT6-56.
           MOVE  98                TO  CTR-RIG-6.

       410-FOOT6-END.
           EXIT.

       2000-STAMPA5.
           IF CONTR-50 NOT = COM-CONTR-50
              IF CTR-PAG-5 NOT = ZEROS
                 PERFORM 400-FOOT5
                    THRU 400-FOOT5-END
              END-IF
              MOVE  CONTR-50             TO  COM-CONTR-50
           END-IF.
           ADD      1                    TO  CTR-RIG-5.
           IF CTR-RIG-5 GREATER 50
              ADD   1                    TO  CTR-PAG-5
              MOVE  CIST-P               TO  S-CIST-P-1
      *----------------------- INIZIO 00029 --------------------------*
              MOVE  DPZCPZ-T OF ZMRK0563 TO  S-DPZCPZ-T-A
              MOVE  DPZCPZ-T OF ZMRK0563 TO  S-DPZCPZ-T
      *-----------------------  FINE  00029 --------------------------*
              MOVE  DLAV-P OF ZMRK0569   TO  S-DLAV-P
              MOVE  CIST-P               TO  S-CIST-P-2
              MOVE  DES-IST              TO  S-DES-IST
              WRITE ZMR0565            FROM  INTEST5-2
              MOVE  FIL-50-LM            TO  S-FIL-50-LM
              MOVE  DEC-FIL-50           TO  S-DEC-FIL-50
              MOVE  CTR-PAG-5            TO  S-PAGE-COUNTER
              WRITE ZMR0565            FROM  INTEST5-3
              WRITE ZMR0565            FROM  RIGA-BIANCA
              WRITE ZMR0565            FROM  RIGA-BIANCA
              MOVE  NCON                 TO  S-NCON-1
              MOVE  CISO-T               TO  S-CISO-T-1
              MOVE  ZRAGSOC OF ZMOCD011  TO  S-ZRAGSOC
              MOVE  ZCTACOR OF ZMODD025  TO  S-ZCTACOR
              MOVE  CONTATORE            TO  S-CONTATORE-1
              WRITE ZMR0565            FROM  INTEST5-6
              MOVE  ESTR-5               TO  S-ESTR-5
              MOVE  KONT-50              TO  S-KONT-50
              MOVE  TAVVERGI OF ZMODD025 TO  S-TAVVERGI
              WRITE ZMR0565            FROM  INTEST5-7
              MOVE  DEC-50               TO  S-DEC-50
              MOVE  SALX50               TO  S-SALX50
              MOVE  SGN-50               TO  S-SGN-50
              WRITE ZMR0565            FROM  RIGA-BIANCA
              WRITE ZMR0565            FROM  INTEST5-9
              WRITE ZMR0565            FROM  RIGA-BIANCA
              WRITE ZMR0565            FROM  INTEST5-11
              WRITE ZMR0565            FROM  RIGA-BIANCA
              MOVE  13                   TO  CTR-RIG-5
           END-IF.
           MOVE  DATAY-50                TO  S-DATAY-50.
           MOVE  CDPZRIF                 TO  S-CDPZRIF-1.
           MOVE  NOPERIF                 TO  S-NOPERIF-1.
           MOVE  NMTRUTE OF ZMOFD011     TO  S-NMTRUTE.
           MOVE  DPZMTT-T OF ZMRK0562    TO  S-DPZMTT-T-1.
           MOVE  NPRGOPE-T OF ZMRK0562   TO  S-NPRGOPE-T.
           MOVE  LORORIF                 TO  S-LORORIF-1.
           MOVE  DATAX-51                TO  S-DATAX-51.
           MOVE  MOVX50                  TO  S-MOVX50.
           MOVE  DEC-53                  TO  S-DEC-53.
           MOVE  DESCRIF                 TO  S-DESCRIF-1.
           WRITE ZMR0565               FROM  DE-5.
       2000-STAMPA5-END.
           EXIT.
       2100-STAMPA6.
           IF CONTR-60 NOT = COM-CONTR-60
              IF CTR-PAG-6 NOT = ZEROS
                 PERFORM 410-FOOT6
                    THRU 410-FOOT6-END
              END-IF
              MOVE  CONTR-60             TO  COM-CONTR-60
           END-IF.
           IF CONTR-61 NOT = COM-CONTR-61
              IF CTR-PAG-6 NOT = ZEROS
                 PERFORM VARYING CTR-RIG-6 FROM 57 BY 1
                   UNTIL CTR-RIG-6 = 62
                    WRITE ZMR0566         FROM  RIGA-BIANCA
                 END-PERFORM
                 MOVE  ZRAGSOC-L         TO  S-ZRAGSOC-L
                 WRITE ZMR0566         FROM  FOOT6-63
                 MOVE  ZIND-L            TO  S-ZIND-L
                 WRITE ZMR0566         FROM  FOOT6-64
                 MOVE  ZCTA-L            TO  S-ZCTA-L
                 WRITE ZMR0566         FROM  FOOT6-65
                 MOVE  FIL-PRIMA         TO  S-FIL-PRIMA
                 MOVE  ZPAE-L            TO  S-ZPAE-L
                 WRITE ZMR0566         FROM  FOOT6-66
                 WRITE ZMR0566         FROM  RIGA-BIANCA
                 WRITE ZMR0566         FROM  RIGA-BIANCA
                 MOVE  FRASE-09          TO  S-FRASE-09
                 MOVE  FRASE-10          TO  S-FRASE-10
                 WRITE ZMR0566         FROM  FOOT6-69
                 MOVE  FRASE-11          TO  S-FRASE-11
                 WRITE ZMR0566         FROM  FOOT6-70
                 MOVE  98                TO  CTR-RIG-6
              END-IF
              MOVE  CONTR-61             TO  COM-CONTR-61
           END-IF.
           ADD      1                    TO  CTR-RIG-6.
           IF CTR-RIG-6 GREATER 54
              ADD   1                    TO  CTR-PAG-6
              WRITE ZMR0566            FROM  INTEST6-1
              WRITE ZMR0566            FROM  RIGA-BIANCA
              WRITE ZMR0566            FROM  RIGA-BIANCA
              WRITE ZMR0566            FROM  INTEST6-4
              WRITE ZMR0566            FROM  RIGA-BIANCA
              WRITE ZMR0566            FROM  RIGA-BIANCA
              WRITE ZMR0566            FROM  RIGA-BIANCA
              WRITE ZMR0566            FROM  RIGA-BIANCA
              MOVE  FRASE-01             TO  S-FRASE-01
              MOVE  NCON                 TO  S-NCON-2
              MOVE  FRASE-02             TO  S-FRASE-02
              MOVE  CISO-T               TO  S-CISO-T-2
              MOVE  FR-021               TO  S-FR-021
              MOVE  CONTATORE            TO  S-CONTATORE-2
              MOVE  CSTC-T               TO  S-CSTC-T
              MOVE  CISO-T               TO  S-CISO-T-3
              MOVE  NNDG-T               TO  S-NNDG-T
              MOVE  NSUFABT-T            TO  S-NSUFABT-T
              MOVE  DPZMTT-T OF ZMRK0563 TO  S-DPZMTT-T-2
              WRITE ZMR0566            FROM  INTEST6-9
              MOVE  FRASE-03             TO  S-FRASE-03
              MOVE  ESTR-6               TO  S-ESTR-6
              MOVE  FRASE-04             TO  S-FRASE-04
              MOVE  KONT-60              TO  S-KONT-60
              WRITE ZMR0566            FROM  INTEST6-10
              WRITE ZMR0566            FROM  RIGA-BIANCA
              MOVE  DEC-60               TO  S-DEC-60
              MOVE  SALX60               TO  S-SALX60
              MOVE  FRASE-12             TO  S-FRASE-12
              WRITE ZMR0566            FROM  INTEST6-12
              WRITE ZMR0566            FROM  RIGA-BIANCA
              MOVE  FRASE-05             TO  S-FRASE-05
              MOVE  FRASE-06             TO  S-FRASE-06
              MOVE  FRASE-07             TO  S-FRASE-07
              WRITE ZMR0566            FROM  INTEST6-14
              WRITE ZMR0566            FROM  RIGA-BIANCA
              MOVE  15                   TO  CTR-RIG-6
           END-IF.
           MOVE  DATAY-60                TO  S-DATAY-60.
           MOVE  CDPZRIF                 TO  S-CDPZRIF-2.
           MOVE  NOPERIF                 TO  S-NOPERIF-2.
           MOVE  LORORIF                 TO  S-LORORIF-2.
           MOVE  DATAX-61                TO  S-DATAX-61.
           MOVE  MOVX60                  TO  S-MOVX60.
           MOVE  DEC-61                  TO  S-DEC-61.
           WRITE ZMR0566               FROM  DE-6.
           MOVE  DESCRIF                 TO  S-DESCRIF-2.
           WRITE ZMR0566               FROM  DE-6B.
       2100-STAMPA6-END.
           EXIT.
       2200-STAMPA7.
           MOVE  RIGA-SW                 TO  S-RIGA-SW.
           WRITE ZMR0567               FROM  DE-7.
       2200-STAMPA7-END.
           EXIT.
       999-ABEND.
           MOVE      5                   TO  COMP-CODE.
           DISPLAY  'PROGRAMMA ZMPDC056 TERMINATO CON ABEND'.
           CALL ILBOABN0 USING COMP-CODE.
