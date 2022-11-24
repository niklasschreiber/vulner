      *----------------------------------------------------------------*
      * PROGETTO_______: TRASPARENZA BANCARIA - F.I.                   *
      * DESC. PROGETTO_: GESTIONE CALCOLATE                            *
      * CLIENTE________: BANCO POSTE                                   *
      * AUTORE_________: ALMAVIVA FINANCE S.P.A.                       *
      * SOCIET{________: ALMAVIVA FINANCE S.P.A.                       *
      * DATA___________: FEBBRAIO 2016                                 *
      *                                                                *
      * IL PROGRAMMA CONFRONTA LO SCARICO DELLE CONDIZIONI CON IL      *
      * FLUSSO DELLA STRUTTURA DELLE CONDIZIONI CALCOLATE.             *
      * FORNISCE IN OUTPUT:                                            *
      * FILEOU1 - FLUSSO DELLE CONDIZIONI CHE APPARTENGONO A CALCOLATE *
      *           AD UNA COMPONENTE                                    *
      * FILEOU2 - FLUSSO DELLE CONDIZIONI CHE APPARTENGONO A CALCOLATE *
      *           CON PI` DI UNA COMPONENTE.                           *
      *                                                                *
AC1805*----------------------------------------------------------------*
AC1805* AC1805: INTERVENTO DEL 25 MAGGIO 2018 PER PORTARE LA CHIAVE  --*
AC1805*         DELLE CALCOLATE A 5 CARATTERI                          *
AC1805*----------------------------------------------------------------*
      *----------------------------------------------------------------*
      *-- PARMS: AAAA/MM/GG DA OPC VIA SCHEDA SYSIN                  --*
      *----------------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WTDPCAF5.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       SPECIAL-NAMES. DECIMAL-POINT IS COMMA.

      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      *--  INP1 -- FILEINP ---------------------------------------------
           SELECT FILEINP  ASSIGN       TO FILEINP
                           ORGANIZATION IS SEQUENTIAL
                           ACCESS MODE  IS SEQUENTIAL
                           FILE STATUS  IS FS-FILEINP.

      *--  INP1 -- FILECDZ ---------------------------------------------
           SELECT FILECDZ  ASSIGN       TO FILECDZ
                           ORGANIZATION IS SEQUENTIAL
                           ACCESS MODE  IS SEQUENTIAL
                           FILE STATUS  IS FS-FILECDZ.

      *--  OUT1 -- FILEOU1 ---------------------------------------------
           SELECT FILEOU1  ASSIGN       TO FILEOU1
                           ORGANIZATION IS SEQUENTIAL
                           ACCESS MODE  IS SEQUENTIAL
                           FILE STATUS  IS FS-FILEOU1.

      *--  OUT1 -- FILEOU2 ---------------------------------------------
           SELECT FILEOU2  ASSIGN       TO FILEOU2
                           ORGANIZATION IS SEQUENTIAL
                           ACCESS MODE  IS SEQUENTIAL
                           FILE STATUS  IS FS-FILEOU2.

      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       DATA DIVISION.
       FILE SECTION.

      *--  FLUSSO STRUTTURA CALCOLATE  ---------------------------------
       FD  FILEINP
           LABEL RECORD IS STANDARD
           BLOCK CONTAINS 0 RECORDS.
       01  FILEINP-REC.
           COPY CTDP5XE REPLACING ==:WS-FILE:== BY ==INP==.

      *--  FLUSSO CONDIZIONI E VALORI PER LISTINO-----------------------
       FD  FILECDZ
           LABEL RECORD IS STANDARD
           BLOCK CONTAINS 0 RECORDS.
       01  FILECDZ-REC.
           05  FCDZ-I-DSVAL1       PIC  X(12).
           05  FCDZ-I-DSVAL2       PIC  X(12).
           05  FCDZ-I-DSVAL3       PIC  X(12).
           05  FCDZ-I-DSVAL4       PIC  X(12).
           05  FCDZ-I-DSVAL5       PIC  X(12).
           05  FCDZ-I-DSVAL6       PIC  X(12).
           05  FCDZ-I-DSVAL7       PIC  X(12).
           05  FCDZ-I-DSVAL8       PIC  X(12).
           05  FCDZ-I-DSVAL9       PIC  X(12).
           05  FCDZ-I-DSVAL10      PIC  X(12).
           05  FCDZ-I-CDCNVEST     PIC  X(30).
           05  FCDZ-I-CONDIZIONE   PIC X(08).
           05  FCDZ-I-QUALIFICATORE PIC X(05).
           05  FCDZ-I-CDSRV0       PIC X(05).
           05  FCDZ-I-CDCLA0       PIC 9(02).
           05  FCDZ-I-CDCDZ0       PIC 9(03).
           05  FCDZ-I-CDOPE0       PIC X(05).
           05  FCDZ-I-TIPO         PIC X(07).
           05  FCDZ-I-VRTAS0       PIC 9(3)V9(6).
           05  FCDZ-I-VRIMP4       PIC 9(12)V999999.
           05  FCDZ-I-IDLIN0       PIC S9(2)V USAGE COMP-3.
           05  FCDZ-I-IDLDC0       PIC S9(2)V USAGE COMP-3.
           05  FCDZ-I-CDFORVAL     PIC X(1).
REVDTE     05  FCDZ-I-DTINIZIO     PIC X(10).
REVDTE     05  FCDZ-I-DTFINE       PIC X(10).

      *--  FLUSSO DATI DI OUTPUT ---------------------------------------
       FD  FILEOU1
           LABEL RECORD IS STANDARD
           BLOCK CONTAINS 0 RECORDS.
       01  FILEOU1-REC.
AC1805*    05  FCDZ-O1-CDCALCOLATA PIC  X(03).
AC1805     05  FCDZ-O1-CDCALCOLATA PIC  X(05).
           05  FCDZ-O1-NECALCOLATA PIC  9(02).
           05  FCDZ-O1-DSVAL1      PIC  X(12).
           05  FCDZ-O1-DSVAL2      PIC  X(12).
           05  FCDZ-O1-DSVAL3      PIC  X(12).
           05  FCDZ-O1-DSVAL4      PIC  X(12).
           05  FCDZ-O1-DSVAL5      PIC  X(12).
           05  FCDZ-O1-DSVAL6      PIC  X(12).
           05  FCDZ-O1-DSVAL7      PIC  X(12).
           05  FCDZ-O1-DSVAL8      PIC  X(12).
           05  FCDZ-O1-DSVAL9      PIC  X(12).
           05  FCDZ-O1-DSVAL10     PIC  X(12).
           05  FCDZ-O1-CDCNVEST    PIC  X(30).
           05  FCDZ-O1-CONDIZIONE  PIC X(08).
           05  FCDZ-O1-QUALIFICATORE PIC X(05).
           05  FCDZ-O1-CDSRV0      PIC X(05).
           05  FCDZ-O1-CDCLA0      PIC 9(02).
           05  FCDZ-O1-CDCDZ0      PIC 9(03).
           05  FCDZ-O1-CDOPE0      PIC X(05).
           05  FCDZ-O1-TIPO        PIC X(07).
           05  FCDZ-O1-VRTAS0      PIC 9(3)V9(6).
           05  FCDZ-O1-VRIMP4      PIC 9(12)V999999.
           05  FCDZ-O1-IDLIN0      PIC S9(2)V USAGE COMP-3.
           05  FCDZ-O1-IDLDC0      PIC S9(2)V USAGE COMP-3.
           05  FCDZ-O1-CDFORVAL    PIC X(1).
REVDTE     05  FCDZ-O1-DTINIZIO    PIC X(10).
REVDTE     05  FCDZ-O1-DTFINE      PIC X(10).

      *--  FLUSSO DATI DI OUTPUT ---------------------------------------
       FD  FILEOU2
           LABEL RECORD IS STANDARD
           BLOCK CONTAINS 0 RECORDS.
       01  FILEOU2-REC.
AC1805*    05  FCDZ-O2-CDCALCOLATA PIC  X(03).
AC1805     05  FCDZ-O2-CDCALCOLATA PIC  X(05).
           05  FCDZ-O2-NECALCOLATA PIC  9(02).
           05  FCDZ-O2-DSVAL1      PIC  X(12).
           05  FCDZ-O2-DSVAL2      PIC  X(12).
           05  FCDZ-O2-DSVAL3      PIC  X(12).
           05  FCDZ-O2-DSVAL4      PIC  X(12).
           05  FCDZ-O2-DSVAL5      PIC  X(12).
           05  FCDZ-O2-DSVAL6      PIC  X(12).
           05  FCDZ-O2-DSVAL7      PIC  X(12).
           05  FCDZ-O2-DSVAL8      PIC  X(12).
           05  FCDZ-O2-DSVAL9      PIC  X(12).
           05  FCDZ-O2-DSVAL10     PIC  X(12).
           05  FCDZ-O2-CDCNVEST    PIC  X(30).
           05  FCDZ-O2-CONDIZIONE  PIC X(08).
           05  FCDZ-O2-QUALIFICATORE PIC X(05).
           05  FCDZ-O2-CDSRV0      PIC X(05).
           05  FCDZ-O2-CDCLA0      PIC 9(02).
           05  FCDZ-O2-CDCDZ0      PIC 9(03).
           05  FCDZ-O2-CDOPE0      PIC X(05).
           05  FCDZ-O2-TIPO        PIC X(07).
           05  FCDZ-O2-VRTAS0      PIC 9(3)V9(6).
           05  FCDZ-O2-VRIMP4      PIC 9(12)V999999.
           05  FCDZ-O2-IDLIN0      PIC S9(2)V USAGE COMP-3.
           05  FCDZ-O2-IDLDC0      PIC S9(2)V USAGE COMP-3.
           05  FCDZ-O2-CDFORVAL    PIC X(1).
REVDTE     05  FCDZ-O2-DTINIZIO    PIC X(10).
REVDTE     05  FCDZ-O2-DTFINE      PIC X(10).


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       WORKING-STORAGE SECTION.

      *--  DICHIARAZIONI FILE STATUS -----------------------------------
       01 FS-FILEINP                     PIC X(02).
       01 FS-FILECDZ                     PIC X(02).
       01 FS-FILEOU1                     PIC X(02).
       01 FS-FILEOU2                     PIC X(02).
       01 WD-EOF-INP                     PIC 9(01) VALUE ZEROES.

      *--  DICHIARAZIONI VARIABILI DI APPOGGIO PER SQL -----------------
       01 WB-EOF-CURCD02                 PIC 9(01).
          88 EOF-CURCD02-SI                        VALUE 0.
          88 EOF-CURCD02-NO                        VALUE 1.

       01 WB-TROVATO                     PIC 9(01).
          88 WB-TROVATO-SI                         VALUE 0.
          88 WB-TROVATO-NO                         VALUE 1.

      *--  DICHIARAZIONI VARIABILI DI APPOGGIO -------------------------
       01 IX                             PIC 9(03) VALUE ZEROES.
       01 IY                             PIC 9(03) VALUE ZEROES.
       01 WS-CTR-LETTI                   PIC 9(09) VALUE ZEROES.
       01 WS-CTR-LETTI-CD02              PIC 9(09) VALUE ZEROES.
       01 WS-CTR-SCRITTI-OU1             PIC 9(09) VALUE ZEROES.
       01 WS-CTR-SCRITTI-OU2             PIC 9(09) VALUE ZEROES.
       01 WS-DISPLAY                     PIC +++.+++.++9,999.
       01 WD-MESSAGE                     PIC X(80).
       01 WS-PGMNAME                     PIC X(08) VALUE 'WTDPCAF5'.
       01 WS-TEST-CDZ-BUCA               PIC X(02).

      **********************************************************        CDB263
      * STRUTTURA TABELLA CALCOLATE                           **        CDB263
      **********************************************************        CDB263
       01 WS-TAB-CALCOLATE.
          02 WS-TAB-ARPRIVATA.
              05 WS-TAB-INPUT.
                 07 WS-TAB-K-CALC-OLD-NEW               PIC X.
                 07 WS-TAB-COD-RAGGRUPP                 PIC X(15).
                 07 WS-TAB-NCONDIZ-INPUT                PIC 99.
                 07 WS-TAB-CONDIZIONE-INPUT-TAB.
                    08 WS-TAB-CONDIZIONE-INPUT OCCURS 10.
                       09 WS-TAB-COND-ORIGINARIA.
                          11 WS-TAB-CI-CONDIZIONE       PIC X(08).
                          11 WS-TAB-CI-QUALIFICATORE PIC X(05).
                       09 WS-TAB-COND-NORMALIZZATA.
                          11 WS-TAB-CI-CDSRV0           PIC X(05).
                          11 WS-TAB-CI-CDCLA0           PIC 9(02).
                          11 WS-TAB-CI-CDCDZ0           PIC 9(03).
                          11 WS-TAB-CI-CDOPE0           PIC X(05).
                       09 WS-TAB-COND-ATTRIBUTO.
                          11 WS-TAB-CI-TIPO             PIC X(07).
                       09 WS-TAB-CI-VRTAS0              PIC 9(3)V9(6).
                       09 WS-TAB-CI-VRIMP4             PIC 9(12)V999999.


       01 SKEDA-SYSIN.
          03 SYSIN-CURRENT-DATE          PIC 9(10) VALUE ZEROES.
          03 SYSIN-DATA-FINE             PIC 9(10) VALUE ZEROES.

       01 WS-DSVAL-ALL.
          03 WS-DSVAL1                   PIC X(12).
          03 WS-DSVAL2                   PIC X(12).
          03 WS-DSVAL3                   PIC X(12).
          03 WS-DSVAL4                   PIC X(12).
          03 WS-DSVAL5                   PIC X(12).
          03 WS-DSVAL6                   PIC X(12).
          03 WS-DSVAL7                   PIC X(12).
          03 WS-DSVAL8                   PIC X(12).
          03 WS-DSVAL9                   PIC X(12).
          03 WS-DSVAL10                  PIC X(12).

      *--  LITERALS ----------------------------------------------------
       01 LC-CDSEREST                    PIC X(03) VALUE 'CC '.
       01 LC-DTFVC0                      PIC X(10) VALUE '9999-12-31'.
       01 LC-TPINFO                      PIC X(01) VALUE 'C'.
       01 LC-CDZSCRIB                    PIC X(50) VALUE SPACES.
       01 LC-DATA-MAX                    PIC 9(08) VALUE 99991231.
       01 LC-C6SP01AB                    PIC X(08) VALUE 'C6SP01AB'.
       01 LC-VALORE                      PIC X(08) VALUE 'VALORE  '.
       01 LC-LISDEF                      PIC X(01) VALUE 'S'.

       01 LC-CDSRV0                      PIC X(05).
       01 LC-CDCLA0                      PIC S9(02)V COMP-3.
       01 LC-CDCDZ0                      PIC S9(03)V COMP-3.
       01 LC-CDOPE0                      PIC X(05).
       01 LC-TIPO                        PIC X(07).

       01 SEL-CDSRV0                     PIC X(05).
       01 SEL-CDCLA0                     PIC S9(02)V COMP-3.
       01 SEL-CDCDZ0                     PIC S9(03)V COMP-3.
       01 SEL-CDOPE0                     PIC X(05).
       01 SEL-TIPO                       PIC X(07).
       01 W-APPO-TIPO                    PIC X(01).

       01  SEL-DSVAL1                    PIC  X(12).
       01  SEL-DSVAL2                    PIC  X(12).
       01  SEL-DSVAL3                    PIC  X(12).
       01  SEL-DSVAL4                    PIC  X(12).
       01  SEL-DSVAL5                    PIC  X(12).
       01  SEL-CDCNVEST                  PIC  X(30).
       01  SEL-DTINIZIO                  PIC  X(10).
       01  SEL-DTFINE                    PIC  X(10).

      *--  FAB.PRODOTTI: VARIABILI STANDARD DI WORKING STORAGE ---------
       01 WS-GEN-PGMNOME                 PIC X(8) VALUE 'WTDPCAF5'.
           COPY WYKGENW.

      *--  AREE PER DATA/ORA -------------------------------------------
       01 WD-AAAAMMGG.
          03 WD-AAAA.
             05 WD-SS                    PIC 9(02).
             05 WD-AA                    PIC 9(02).
          03 WD-MM                       PIC 9(02).
          03 WD-GG                       PIC 9(02).

       01 WS-DATA-INIZIO.
          03 WS-AAAA-I                   PIC 9(04).
          03 FILLER                      PIC X(01) VALUE '-'.
          03 WS-MM-I                     PIC 9(02).
          03 FILLER                      PIC X(01) VALUE '-'.
          03 WS-GG-I                     PIC 9(02).

       01 WS-DATA-FINE.
          03 WS-AAAA-F                   PIC 9(04).
          03 FILLER                      PIC X(01) VALUE '-'.
          03 WS-MM-F                     PIC 9(02).
          03 FILLER                      PIC X(01) VALUE '-'.
          03 WS-GG-F                     PIC 9(02).

       01 SYS-HHMMSS.
          05 SYS-HH                      PIC 9(02).
          05 SYS-MIN                     PIC 9(02).
          05 SYS-SS                      PIC 9(02).
          05 SYS-CC                      PIC 9(02).

      *-- AREE ROUTINE ESTERNE -----------------------------------------
       01 AREA-C6AP01AS.
           COPY C6AP01AS.

010800*--  COPY PER LA GESTIONE DI ERRORI DB2 E VSAM -------------------
010900     COPY ARCCW999.
020100*--  VARIABILI PER GESTIONE ABEND --------------------------------
020200 01  ABEND-CODE                    PIC S9(04) COMP.
020300 01  ILBOABN0                      PIC X(08) VALUE 'ILBOABN0'.
020400
011000
025800*--  VARIABILI DB2 -----------------------------------------------
025900 01  APPO-SQLCODE                  PIC -(07)9.
026000 01  SQL-TIPOTMPL                  PIC X(04).
026100
026600*--  DCLGEN DELLA TABELLA SESSION.TEMPCDZV -----------------------
026700 01  DCLTEMPCDZV.
           05  TEMPCDZV-DSVAL1               PIC  X(12).
           05  TEMPCDZV-DSVAL2               PIC  X(12).
           05  TEMPCDZV-DSVAL3               PIC  X(12).
           05  TEMPCDZV-DSVAL4               PIC  X(12).
           05  TEMPCDZV-DSVAL5               PIC  X(12).
           05  TEMPCDZV-DSVAL6               PIC  X(12).
           05  TEMPCDZV-DSVAL7               PIC  X(12).
           05  TEMPCDZV-DSVAL8               PIC  X(12).
           05  TEMPCDZV-DSVAL9               PIC  X(12).
           05  TEMPCDZV-DSVAL10              PIC  X(12).
           05  TEMPCDZV-CDCNVEST             PIC  X(30).
           05  TEMPCDZV-CONDIZIONE           PIC X(08).
           05  TEMPCDZV-QUALIFICATORE        PIC X(05).
           05  TEMPCDZV-CDSRV0               PIC X(05).
           05  TEMPCDZV-CDCLA0               PIC S9(02)V COMP-3.
           05  TEMPCDZV-CDCDZ0               PIC S9(03)V COMP-3.
           05  TEMPCDZV-CDOPE0               PIC X(05).
           05  TEMPCDZV-TIPO                 PIC X(07).
           05  TEMPCDZV-VRTAS0               PIC S9(3)V9(6) COMP-3.
           05  TEMPCDZV-VRIMP4               PIC S9(12)V999999 COMP-3.
           05  TEMPCDZV-IDLIN0               PIC S9(02)V COMP-3.
           05  TEMPCDZV-IDLDC0               PIC S9(02)V COMP-3.
           05  TEMPCDZV-CDFORVAL             PIC X(01).
REVDTE     05  TEMPCDZV-DTINIZIO             PIC X(10).
REVDTE     05  TEMPCDZV-DTFINE               PIC X(10).
027300
026600*--  DCLGEN DELLA TABELLA SESSION.TEMPCDZV -----------------------
026700 01  DCLSELECDZV.
           05  SELECDZV-DSVAL1               PIC  X(12).
           05  SELECDZV-DSVAL2               PIC  X(12).
           05  SELECDZV-DSVAL3               PIC  X(12).
           05  SELECDZV-DSVAL4               PIC  X(12).
           05  SELECDZV-DSVAL5               PIC  X(12).
           05  SELECDZV-DSVAL6               PIC  X(12).
           05  SELECDZV-DSVAL7               PIC  X(12).
           05  SELECDZV-DSVAL8               PIC  X(12).
           05  SELECDZV-DSVAL9               PIC  X(12).
           05  SELECDZV-DSVAL10              PIC  X(12).
           05  SELECDZV-CDCNVEST             PIC  X(30).
           05  SELECDZV-CONDIZIONE           PIC X(08).
           05  SELECDZV-QUALIFICATORE        PIC X(05).
           05  SELECDZV-CDSRV0               PIC X(05).
           05  SELECDZV-CDCLA0               PIC S9(02)V COMP-3.
           05  SELECDZV-CDCDZ0               PIC S9(03)V COMP-3.
           05  SELECDZV-CDOPE0               PIC X(05).
           05  SELECDZV-TIPO                 PIC X(07).
           05  SELECDZV-VRTAS0               PIC S9(3)V9(6) COMP-3.
           05  SELECDZV-VRIMP4               PIC S9(12)V999999 COMP-3.
           05  SELECDZV-IDLIN0               PIC S9(02)V COMP-3.
           05  SELECDZV-IDLDC0               PIC S9(02)V COMP-3.
           05  SELECDZV-CDFORVAL             PIC X(01).
REVDTE     05  SELECDZV-DTINIZIO             PIC X(10).
REVDTE     05  SELECDZV-DTFINE               PIC X(10).
027300
028800*--  AREE DB2 ----------------------------------------------------
028900     EXEC SQL INCLUDE SQLCA        END-EXEC.
029000*
      *-- VARIABILI DB2 ------------------------------------------------
       01 SQL-CDSRV0                     PIC X(05).
       01 SQL-CDOPE0                     PIC X(05).

      *--  CURSORE CD02 SU  TABELLA SESSION.TEMPCDZV
           EXEC SQL DECLARE CD02 CURSOR FOR
            SELECT
               TEMPCDZV_DSVAL1
              ,TEMPCDZV_DSVAL2
              ,TEMPCDZV_DSVAL3
              ,TEMPCDZV_DSVAL4
              ,TEMPCDZV_DSVAL5
              ,TEMPCDZV_CDCNVEST
              ,TEMPCDZV_CONDIZIONE
              ,TEMPCDZV_QUALIFICATORE
              ,TEMPCDZV_CDSRV0
              ,TEMPCDZV_CDCLA0
              ,TEMPCDZV_CDCDZ0
              ,TEMPCDZV_CDOPE0
              ,TEMPCDZV_TIPO
              ,TEMPCDZV_VRTAS0
              ,TEMPCDZV_VRIMP4
              ,TEMPCDZV_IDLIN0
              ,TEMPCDZV_IDLDC0
              ,TEMPCDZV_CDFORVAL
              ,TEMPCDZV_DTINIZIO
              ,TEMPCDZV_DTFINE
              FROM SESSION.TEMPCDZV

            WHERE TEMPCDZV_CDSRV0 = :LC-CDSRV0
              AND TEMPCDZV_CDCLA0 = :LC-CDCLA0
              AND TEMPCDZV_CDCDZ0 = :LC-CDCDZ0
              AND TEMPCDZV_CDOPE0 = :LC-CDOPE0
              AND TEMPCDZV_TIPO   = :LC-TIPO
      *
            ORDER BY 1,2,3
      *
               WITH UR
           END-EXEC.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       LINKAGE SECTION.

       01  DFHCOMMAREA                   PIC X.
      *-- AREE COMUNI GLOBALI DI FABBRICA PRODOTTI (WY) ----------------
          COPY WYKALLG.
      * VARIABILI STANDARD DI FABBRICA PRODOTTI (WY) -------------------
          COPY WYKCALL.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       PROCEDURE DIVISION USING LK-CAL-ARG1, LK-CAL-ARG2.

       MAIN-STD SECTION.
      *-- RICEZIONE AREE COMUNI DI FABBRICA PRODOTTI (WY) --------------
          COPY WYKCALR.
      *-- RISOLUZIONE INDIRIZZAMENTO AREE CONDIVISE --------------------
          COPY WYKGENR.
      *-- TRATTAMENTI COMUNI DI FABBRICA PRODOTTI (WY) -----------------
          COPY WYKGENP.

       MAIN-APPL.
      *    OPERAZIONI INIZIALI -----------------------------------------
           PERFORM OPER-INIZIALI THRU
                   OPER-INIZIALI-EXIT

034600*    INTAB. IL FILE CONDIZIONI IN UNA TABLE SESSION -----
034700     PERFORM INTAB-FILECDZ THRU
034800             INTAB-FILECDZ-EXIT
034900             UNTIL FS-FILECDZ NOT = '00'
035000
      *    TRATTAMENTO FILE MATRICE CLCOLATE ---------------------------
           PERFORM ELABORAZIONE THRU
                   ELABORAZIONE-EXIT
                   UNTIL WD-EOF-INP = 1.

      *    OPERAZIONI FINALI -------------------------------------------
           PERFORM OPER-FINALI THRU
                   OPER-FINALI-EXIT.

       Z9999-RITORNO.
      *    ORA DI FINE -------------------------------------------------
           DISPLAY ' '
           ACCEPT SYS-HHMMSS FROM TIME
           DISPLAY WS-GEN-PGMNOME ' (I) - FINE ELABORAZIONE ORE '
                   SYS-HH ':' SYS-MIN ':' SYS-SS '.' SYS-CC.

           GOBACK.


      ******************************************************************
      **============= ROUTINES RICHIAMATE DA MAINLINE ================**
      ******************************************************************

      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       OPER-INIZIALI.
      *
TRC        SET GL-TRC-LEVEL3             TO TRUE
TRC        MOVE '*** OPER-INIZIALI ***'  TO GL-TRC-MSG
TRC        COPY WYKTRCP.

      *    INIZIALIZZO VARIABILI UTENTE --------------------------------
           MOVE ZEROES                   TO WS-CTR-LETTI
           MOVE ZEROES                   TO WS-CTR-LETTI-CD02
           MOVE ZEROES                   TO WS-CTR-SCRITTI-OU1
           MOVE ZEROES                   TO WS-CTR-SCRITTI-OU2

      *    ACQUISIZIONE E CONTROLLO SCHEDA PARAMETRI -------------------
           PERFORM CTRL-JCLPARMS THRU
                   CTRL-JCLPARMS-EXIT

           MOVE SYSIN-CURRENT-DATE   TO WS-DATA-INIZIO
           MOVE SYSIN-DATA-FINE      TO WS-DATA-FINE

      *    OPEN INPUT FILE FILEINP -------------------------------------
           PERFORM OPEN-INPUT-FILEINP THRU
                   OPEN-INPUT-FILEINP-EXIT

      *    OPEN INPUT FILE FILECDZ -------------------------------------
           PERFORM OPEN-INPUT-FILECDZ THRU
                   OPEN-INPUT-FILECDZ-EXIT

      *    OPEN OUTPUT FILE FILEOU1 ------------------------------------
           PERFORM OPEN-OUTPUT-FILEOU1 THRU
                   OPEN-OUTPUT-FILEOU1-EXIT.

      *    OPEN OUTPUT FILE FILEOU2 ------------------------------------
           PERFORM OPEN-OUTPUT-FILEOU2 THRU
                   OPEN-OUTPUT-FILEOU2-EXIT.

      *    LETTURA FUORI CICLO -----------------------------------------
           PERFORM READ-FILEINP THRU
                   READ-FILEINP-EXIT.
      *
       OPER-INIZIALI-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       CTRL-JCLPARMS.
      *
TRC        SET GL-TRC-LEVEL3             TO TRUE
TRC        MOVE '*** CTRL-JCLPARMS ***'  TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
      *--  LA SYSIN-CURRENT-DATE VIENE PASSATA DALL'OPC E DEVE ESSERE
      *--  IN FORMATO AAAAMMGG. NON VIENE CONTROLLATA PERCHE LA FONTE
      *--  DI PROVENIENZA OPC } SICURA.
           INITIALIZE SKEDA-SYSIN.
           ACCEPT SKEDA-SYSIN FROM SYSIN.
      *
       CTRL-JCLPARMS-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       OPEN-INPUT-FILEINP.
      *
TRC        SET GL-TRC-LEVEL3                 TO TRUE
TRC        MOVE '*** OPEN-INPUT-FILEINP ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           OPEN INPUT FILEINP.
           IF FS-FILEINP NOT = '00'
              SET GL-ERR-CDERRCAU-APPLIC TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'OPEI'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILEINP            TO GL-ERR-DSERDATA
              MOVE 'OPEN INPUT FILE FILEINP'
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE OPEN FILE FILEINP'
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
       OPEN-INPUT-FILEINP-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       OPEN-INPUT-FILECDZ.
      *
TRC        SET GL-TRC-LEVEL3                 TO TRUE
TRC        MOVE '*** OPEN-INPUT-FILECDZ ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           OPEN INPUT FILECDZ.
           IF FS-FILECDZ NOT = '00'
              SET GL-ERR-CDERRCAU-APPLIC TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'OPEI'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILECDZ            TO GL-ERR-DSERDATA
              MOVE 'OPEN INPUT FILE FILECDZ'
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE OPEN FILE FILECDZ'
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
       OPEN-INPUT-FILECDZ-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       OPEN-OUTPUT-FILEOU1.
      *
TRC        SET GL-TRC-LEVEL3                  TO TRUE
TRC        MOVE '*** OPEN-OUTPUT-FILEOU1 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           OPEN OUTPUT FILEOU1.
           IF FS-FILEOU1 NOT = '00'
              SET GL-ERR-CDERRCAU-APPLIC TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'OPEO'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILEOU1            TO GL-ERR-DSERDATA
              MOVE 'OPEN OUTPUT FILE FILEOU1'
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE OPEN FILE FILEOU1'
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
       OPEN-OUTPUT-FILEOU1-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       OPEN-OUTPUT-FILEOU2.
      *
TRC        SET GL-TRC-LEVEL3                  TO TRUE
TRC        MOVE '*** OPEN-OUTPUT-FILEOU2 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           OPEN OUTPUT FILEOU2.
           IF FS-FILEOU2 NOT = '00'
              SET GL-ERR-CDERRCAU-APPLIC TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'OPEO'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILEOU2            TO GL-ERR-DSERDATA
              MOVE 'OPEN OUTPUT FILE FILEOU2'
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE OPEN FILE FILEOU2'
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
       OPEN-OUTPUT-FILEOU2-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       READ-FILEINP.
      *
TRC        SET GL-TRC-LEVEL3             TO TRUE
TRC        MOVE '*** READ-FILEINP ***'   TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           READ FILEINP
           END-READ.

           EVALUATE FS-FILEINP
               WHEN '00'
                    ADD +1                     TO WS-CTR-LETTI
               WHEN '10'
                    MOVE 1                     TO WD-EOF-INP
               WHEN OTHER
                    SET GL-ERR-CDERRCAU-LOGICA TO TRUE
                    MOVE 'M6'                  TO GL-ERR-CDPROCED
                    MOVE 'E999'                TO GL-ERR-CDERRKEY
                    MOVE 'READ'                TO GL-ERR-CDRESTYP
                    MOVE 'STATUS'              TO GL-ERR-CDRESNAM
                    MOVE FS-FILEINP            TO GL-ERR-DSERDATA
                    MOVE 'ERR. READ FILE FILEINP'
                                              TO GL-ERR-DSERTEXT-INTERNO
                    MOVE 'ERRORE LETTURA FILE FILEINP'
                                              TO GL-ERR-DSERTEXT-ESTERNO
                    PERFORM ERRORE-CATTURABILE

           END-EVALUATE.
      *
       READ-FILEINP-EXIT.
           EXIT.


      *-----------------------------------------------------------------
       ELABORAZIONE.
      *
TRC        SET GL-TRC-LEVEL3             TO TRUE
TRC        MOVE '*** ELABORAZIONE ***'   TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
DEBUGG*    DISPLAY 'ELABORAZIONE'
DEBUGG*    DISPLAY 'TRATTO CALCOLATA = ' INP-COD-RAGGRUPP
      *
              SET EOF-CURCD02-NO         TO TRUE

      *--        RECUPERO TUTTI I VALORI DELLE CDZ LEGATE ALLA K -------
              PERFORM VARYING IX FROM 1 BY 1
                      UNTIL IX > INP-NCONDIZ-INPUT
                      OR INP-CI-CONDIZIONE(IX) = SPACES

                 IF INP-CI-CONDIZIONE(IX) NOT = '********'
      *--              CHIAMATA AL MONDO CONDIZIONI --------------------
                    PERFORM RECUPERA-VALORE-CDZ THRU
                               RECUPERA-VALORE-CDZ-EXIT

                 END-IF

              END-PERFORM

      *--  PROSSIMA LETTURA FILEINP ------------------------------------
           PERFORM READ-FILEINP THRU
                   READ-FILEINP-EXIT.
      *
       ELABORAZIONE-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       RECUPERA-VALORE-CDZ.
      *
TRC        SET GL-TRC-LEVEL3                  TO TRUE
TRC        MOVE '*** RECUPERA-VALORE-CDZ ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
      *       APERTURA CURSORE CD02 ------------------------------------
           MOVE INP-CI-CDSRV0(IX) TO LC-CDSRV0
           MOVE INP-CI-CDCLA0(IX) TO LC-CDCLA0
           MOVE INP-CI-CDCDZ0(IX) TO LC-CDCDZ0
           MOVE INP-CI-CDOPE0(IX) TO LC-CDOPE0
           MOVE INP-CI-TIPO(IX)      TO W-APPO-TIPO
           MOVE W-APPO-TIPO          TO LC-TIPO
      *
DEBUGG*    DISPLAY 'CERCO = '
DEBUGG*                      LC-CDSRV0 '/'
DEBUGG*                      LC-CDCLA0 '/'
DEBUGG*                      LC-CDCDZ0 '/'
DEBUGG*                      LC-CDOPE0 '/'
DEBUGG*                      LC-TIPO.
      *
           PERFORM OPEN-CURSOR-CD02 THRU
                      OPEN-CURSOR-CD02-EXIT
              SET EOF-CURCD02-NO         TO TRUE

      *       PRIMA LETTURA CURSORE CD02 -------------------------------
           PERFORM FETCH-CURSOR-CD02 THRU
                      FETCH-CURSOR-CD02-EXIT

           PERFORM UNTIL EOF-CURCD02-SI

DEBUGG*    DISPLAY 'TROVO DA FETCH= '
DEBUGG*         TEMPCDZV-DTINIZIO '/'
DEBUGG*         TEMPCDZV-DTFINE   '/'
DEBUGG*         TEMPCDZV-DSVAL1   '/'
DEBUGG*         TEMPCDZV-DSVAL2   '/'
DEBUGG*         TEMPCDZV-DSVAL3   '/'
DEBUGG*         TEMPCDZV-CDCNVEST '/'
DEBUGG*         TEMPCDZV-VRTAS0   '/'
DEBUGG*         TEMPCDZV-VRIMP4   '*'

                 IF INP-NCONDIZ-INPUT = 1
      *--              ARRICCHISCE FILEOU1 -----------------------------
                    PERFORM ARRICCHISCE-FILEOU1 THRU
                            ARRICCHISCE-FILEOU1-EXIT

      *--        SCRIVO FILEOU1 ----------------------------------------
                    PERFORM WRITE-FILEOU1 THRU
                            WRITE-FILEOU1-EXIT
                 ELSE
                    PERFORM ARRICCHISCE-FILEOU2 THRU
                            ARRICCHISCE-FILEOU2-EXIT

      *--        SCRIVO FILEOU2 ----------------------------------------
                    PERFORM WRITE-FILEOU2 THRU
                            WRITE-FILEOU2-EXIT

                 END-IF

                 PERFORM FETCH-CURSOR-CD02 THRU
                         FETCH-CURSOR-CD02-EXIT

              END-PERFORM

      *--     CHIUSURA DEL CURSORE -------------------------------------
              PERFORM CLOSE-CURSOR-CD02 THRU
                      CLOSE-CURSOR-CD02-EXIT

           .
      *
       RECUPERA-VALORE-CDZ-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       ARRICCHISCE-FILEOU1.
      *
TRC        SET GL-TRC-LEVEL3                  TO TRUE
TRC        MOVE '*** ARRICCHISCE-FILEOU1 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           INITIALIZE FILEOU1-REC.
      *
           MOVE INP-COD-RAGGRUPP       TO  FCDZ-O1-CDCALCOLATA
           MOVE INP-NCONDIZ-INPUT      TO  FCDZ-O1-NECALCOLATA
           MOVE TEMPCDZV-DSVAL1        TO  FCDZ-O1-DSVAL1
           MOVE TEMPCDZV-DSVAL2        TO  FCDZ-O1-DSVAL2
           MOVE TEMPCDZV-DSVAL3        TO  FCDZ-O1-DSVAL3
           MOVE TEMPCDZV-DSVAL4        TO  FCDZ-O1-DSVAL4
           MOVE TEMPCDZV-DSVAL5        TO  FCDZ-O1-DSVAL5
           MOVE TEMPCDZV-CDCNVEST      TO  FCDZ-O1-CDCNVEST
           MOVE TEMPCDZV-CONDIZIONE    TO  FCDZ-O1-CONDIZIONE
           MOVE TEMPCDZV-QUALIFICATORE TO  FCDZ-O1-QUALIFICATORE
           MOVE TEMPCDZV-CDSRV0        TO  FCDZ-O1-CDSRV0
           MOVE TEMPCDZV-CDCLA0        TO  FCDZ-O1-CDCLA0
           MOVE TEMPCDZV-CDCDZ0        TO  FCDZ-O1-CDCDZ0
           MOVE TEMPCDZV-CDOPE0        TO  FCDZ-O1-CDOPE0
           MOVE TEMPCDZV-TIPO          TO  FCDZ-O1-TIPO
           MOVE TEMPCDZV-VRTAS0        TO  FCDZ-O1-VRTAS0
           MOVE TEMPCDZV-VRIMP4        TO  FCDZ-O1-VRIMP4
           MOVE TEMPCDZV-IDLIN0        TO  FCDZ-O1-IDLIN0
           MOVE TEMPCDZV-IDLDC0        TO  FCDZ-O1-IDLDC0
           MOVE TEMPCDZV-CDFORVAL      TO  FCDZ-O1-CDFORVAL
REVDTE     MOVE TEMPCDZV-DTINIZIO      TO  FCDZ-O1-DTINIZIO
REVDTE     MOVE TEMPCDZV-DTFINE        TO  FCDZ-O1-DTFINE
      *
           .
       ARRICCHISCE-FILEOU1-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       ARRICCHISCE-FILEOU2.
      *
TRC        SET GL-TRC-LEVEL3                  TO TRUE
TRC        MOVE '*** ARRICCHISCE-FILEOU2 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           INITIALIZE FILEOU2-REC.
      *
           MOVE INP-COD-RAGGRUPP       TO  FCDZ-O2-CDCALCOLATA
           MOVE INP-NCONDIZ-INPUT      TO  FCDZ-O2-NECALCOLATA
           MOVE TEMPCDZV-DSVAL1        TO  FCDZ-O2-DSVAL1
           MOVE TEMPCDZV-DSVAL2        TO  FCDZ-O2-DSVAL2
           MOVE TEMPCDZV-DSVAL3        TO  FCDZ-O2-DSVAL3
           MOVE TEMPCDZV-DSVAL4        TO  FCDZ-O2-DSVAL4
           MOVE TEMPCDZV-DSVAL5        TO  FCDZ-O2-DSVAL5
           MOVE TEMPCDZV-CDCNVEST      TO  FCDZ-O2-CDCNVEST
           MOVE TEMPCDZV-CONDIZIONE    TO  FCDZ-O2-CONDIZIONE
           MOVE TEMPCDZV-QUALIFICATORE TO  FCDZ-O2-QUALIFICATORE
           MOVE TEMPCDZV-CDSRV0        TO  FCDZ-O2-CDSRV0
           MOVE TEMPCDZV-CDCLA0        TO  FCDZ-O2-CDCLA0
           MOVE TEMPCDZV-CDCDZ0        TO  FCDZ-O2-CDCDZ0
           MOVE TEMPCDZV-CDOPE0        TO  FCDZ-O2-CDOPE0
           MOVE TEMPCDZV-TIPO          TO  FCDZ-O2-TIPO
           MOVE TEMPCDZV-VRTAS0        TO  FCDZ-O2-VRTAS0
           MOVE TEMPCDZV-VRIMP4        TO  FCDZ-O2-VRIMP4
           MOVE TEMPCDZV-IDLIN0        TO  FCDZ-O2-IDLIN0
           MOVE TEMPCDZV-IDLDC0        TO  FCDZ-O2-IDLDC0
           MOVE TEMPCDZV-CDFORVAL      TO  FCDZ-O2-CDFORVAL
REVDTE     MOVE TEMPCDZV-DTINIZIO      TO  FCDZ-O2-DTINIZIO
REVDTE     MOVE TEMPCDZV-DTFINE        TO  FCDZ-O2-DTFINE
      *
           .
       ARRICCHISCE-FILEOU2-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       ARRICCHISCE-FILEOU2-ALTRA.
      *
TRC        SET GL-TRC-LEVEL3                  TO TRUE
TRC        MOVE '*** ARRICCHISCE-FILEOU2-ALTRA ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           INITIALIZE FILEOU2-REC.
      *
           MOVE INP-COD-RAGGRUPP       TO  FCDZ-O2-CDCALCOLATA
           MOVE INP-NCONDIZ-INPUT      TO  FCDZ-O2-NECALCOLATA
           MOVE SELECDZV-DSVAL1        TO  FCDZ-O2-DSVAL1
           MOVE SELECDZV-DSVAL2        TO  FCDZ-O2-DSVAL2
           MOVE SELECDZV-DSVAL3        TO  FCDZ-O2-DSVAL3
           MOVE SELECDZV-DSVAL4        TO  FCDZ-O2-DSVAL4
           MOVE SELECDZV-DSVAL5        TO  FCDZ-O2-DSVAL5
           MOVE SELECDZV-CDCNVEST      TO  FCDZ-O2-CDCNVEST
           MOVE SELECDZV-CONDIZIONE    TO  FCDZ-O2-CONDIZIONE
           MOVE SELECDZV-QUALIFICATORE TO  FCDZ-O2-QUALIFICATORE
           MOVE SELECDZV-CDSRV0        TO  FCDZ-O2-CDSRV0
           MOVE SELECDZV-CDCLA0        TO  FCDZ-O2-CDCLA0
           MOVE SELECDZV-CDCDZ0        TO  FCDZ-O2-CDCDZ0
           MOVE SELECDZV-CDOPE0        TO  FCDZ-O2-CDOPE0
           MOVE SELECDZV-TIPO          TO  FCDZ-O2-TIPO
           MOVE SELECDZV-VRTAS0        TO  FCDZ-O2-VRTAS0
           MOVE SELECDZV-VRIMP4        TO  FCDZ-O2-VRIMP4
           MOVE SELECDZV-IDLIN0        TO  FCDZ-O2-IDLIN0
           MOVE SELECDZV-IDLDC0        TO  FCDZ-O2-IDLDC0
           MOVE SELECDZV-CDFORVAL      TO  FCDZ-O2-CDFORVAL
REVDTE     MOVE SEL-DTINIZIO           TO  FCDZ-O2-DTINIZIO
REVDTE     MOVE SEL-DTFINE             TO  FCDZ-O2-DTFINE
      *
           .
       ARRICCHISCE-FILEOU2-ALTRA-EXIT.
           EXIT.

      *-----------------------------------------------------------------
       ARRICCHISCE-FILEOU2-DATE.
      *
TRC        SET GL-TRC-LEVEL3                  TO TRUE
TRC        MOVE '*** ARRICCHISCE-FILEOU2-DATE  ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           INITIALIZE FILEOU2-REC.
      *
           MOVE INP-COD-RAGGRUPP       TO  FCDZ-O2-CDCALCOLATA
           MOVE INP-NCONDIZ-INPUT      TO  FCDZ-O2-NECALCOLATA
           MOVE SELECDZV-DSVAL1        TO  FCDZ-O2-DSVAL1
           MOVE SELECDZV-DSVAL2        TO  FCDZ-O2-DSVAL2
           MOVE SELECDZV-DSVAL3        TO  FCDZ-O2-DSVAL3
           MOVE SELECDZV-DSVAL4        TO  FCDZ-O2-DSVAL4
           MOVE SELECDZV-DSVAL5        TO  FCDZ-O2-DSVAL5
           MOVE SELECDZV-CDCNVEST      TO  FCDZ-O2-CDCNVEST
           MOVE SELECDZV-CONDIZIONE    TO  FCDZ-O2-CONDIZIONE
           MOVE SELECDZV-QUALIFICATORE TO  FCDZ-O2-QUALIFICATORE
           MOVE SELECDZV-CDSRV0        TO  FCDZ-O2-CDSRV0
           MOVE SELECDZV-CDCLA0        TO  FCDZ-O2-CDCLA0
           MOVE SELECDZV-CDCDZ0        TO  FCDZ-O2-CDCDZ0
           MOVE SELECDZV-CDOPE0        TO  FCDZ-O2-CDOPE0
           MOVE SELECDZV-TIPO          TO  FCDZ-O2-TIPO
           MOVE SELECDZV-VRTAS0        TO  FCDZ-O2-VRTAS0
           MOVE SELECDZV-VRIMP4        TO  FCDZ-O2-VRIMP4
           MOVE SELECDZV-IDLIN0        TO  FCDZ-O2-IDLIN0
           MOVE SELECDZV-IDLDC0        TO  FCDZ-O2-IDLDC0
           MOVE SELECDZV-CDFORVAL      TO  FCDZ-O2-CDFORVAL
REVDTE     MOVE TEMPCDZV-DTINIZIO      TO  FCDZ-O2-DTINIZIO
REVDTE     MOVE TEMPCDZV-DTFINE        TO  FCDZ-O2-DTFINE
      *
DEBUGG*    DISPLAY 'SCRIVO CONDIZIONE/DATA '
DEBUGG*
DEBUGG*                       SELECDZV-CDSRV0    '/'
DEBUGG*                       SELECDZV-CDCLA0    '/'
DEBUGG*                       SELECDZV-CDCDZ0    '/'
DEBUGG*                       SELECDZV-CDOPE0    '/'
DEBUGG*                       SELECDZV-VRTAS0    '/'
DEBUGG*                       SELECDZV-VRIMP4    '/'
REVDTE*                       TEMPCDZV-DTINIZIO  '/'
REVDTE*                       TEMPCDZV-DTFINE
           .
           .
       ARRICCHISCE-FILEOU2-DATE-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       WRITE-FILEOU1.
      *
TRC        SET GL-TRC-LEVEL3             TO TRUE
TRC        MOVE '*** WRITE-FILEOU1 ***'  TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           WRITE FILEOU1-REC
           END-WRITE.
      *
           IF FS-FILEOU1 NOT = '00'
              SET GL-ERR-CDERRCAU-LOGICA TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'WRIT'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILEOU1            TO GL-ERR-DSERDATA
              MOVE 'ERRORE WRITE FILE OUTPUT   '
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE WRITE FILE OUTPUT   '
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
           ADD +1                        TO WS-CTR-SCRITTI-OU1.
      *
       WRITE-FILEOU1-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       WRITE-FILEOU2.
      *
TRC        SET GL-TRC-LEVEL3             TO TRUE
TRC        MOVE '*** WRITE-FILEOU2 ***'  TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
DEBUGG*    DISPLAY  'SCRIVO = ' FILEOU2-REC.
      *
           WRITE FILEOU2-REC
           END-WRITE.
      *
           IF FS-FILEOU2 NOT = '00'
              SET GL-ERR-CDERRCAU-LOGICA TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'WRIT'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILEOU2            TO GL-ERR-DSERDATA
              MOVE 'ERRORE WRITE FILE OUTPUT   '
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE WRITE FILE OUTPUT   '
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
           ADD +1                        TO WS-CTR-SCRITTI-OU2.
      *
       WRITE-FILEOU2-EXIT.
           EXIT.


      *-----------------------------------------------------------------
       OPEN-CURSOR-CD02.
      *
TRC        SET GL-TRC-LEVEL3               TO TRUE
TRC        MOVE '*** OPEN-CURSOR-CD02 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           EXEC SQL
                OPEN CD02
           END-EXEC.
      *
           EVALUATE SQLCODE
               WHEN ZEROES
                    CONTINUE

               WHEN OTHER
                    SET GL-ERR-CDERRCAU-APPLIC
                                         TO TRUE
                    MOVE 'M6'            TO GL-ERR-CDPROCED
                    MOVE 'E999'          TO GL-ERR-CDERRKEY
                    MOVE 'TAB '          TO GL-ERR-CDRESTYP
                    MOVE 'CURCD02'       TO GL-ERR-CDRESNAM
                    MOVE SQLCODE         TO GL-ERR-DSERDATA
                    MOVE 'ERR. DB2 OPEN CURCD02      '
                                         TO GL-ERR-DSERTEXT-INTERNO
                    MOVE SPACES          TO GL-ERR-DSERTEXT-ESTERNO
                    PERFORM ERRORE-CATTURABILE
           END-EVALUATE.
      *
       OPEN-CURSOR-CD02-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       FETCH-CURSOR-CD02.
      *
TRC        SET GL-TRC-LEVEL3                TO TRUE
TRC        MOVE '*** FETCH-CURSOR-CD02 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           EXEC SQL FETCH CD02
               INTO  :TEMPCDZV-DSVAL1
                    ,:TEMPCDZV-DSVAL2
                    ,:TEMPCDZV-DSVAL3
                    ,:TEMPCDZV-DSVAL4
                    ,:TEMPCDZV-DSVAL5
                    ,:TEMPCDZV-CDCNVEST
                    ,:TEMPCDZV-CONDIZIONE
                    ,:TEMPCDZV-QUALIFICATORE
                    ,:TEMPCDZV-CDSRV0
                    ,:TEMPCDZV-CDCLA0
                    ,:TEMPCDZV-CDCDZ0
                    ,:TEMPCDZV-CDOPE0
                    ,:TEMPCDZV-TIPO
                    ,:TEMPCDZV-VRTAS0
                    ,:TEMPCDZV-VRIMP4
                    ,:TEMPCDZV-IDLIN0
                    ,:TEMPCDZV-IDLDC0
                    ,:TEMPCDZV-CDFORVAL
                    ,:TEMPCDZV-DTINIZIO
                    ,:TEMPCDZV-DTFINE
           END-EXEC.
      *
           EVALUATE SQLCODE
               WHEN ZEROES
                    ADD +1               TO WS-CTR-LETTI-CD02

               WHEN +100
                    SET EOF-CURCD02-SI   TO TRUE

               WHEN OTHER
                    SET GL-ERR-CDERRCAU-APPLIC
                                         TO TRUE
                    MOVE 'M6'            TO GL-ERR-CDPROCED
                    MOVE 'E999'          TO GL-ERR-CDERRKEY
                    MOVE 'CUR '          TO GL-ERR-CDRESTYP
                    MOVE 'FETCH'         TO GL-ERR-CDRESNAM
                    MOVE SQLCODE         TO GL-ERR-DSERDATA
                    MOVE 'ERR. DB2 FETCH CURCD02     '
                                         TO GL-ERR-DSERTEXT-INTERNO
                    MOVE SPACES          TO GL-ERR-DSERTEXT-ESTERNO
                    PERFORM ERRORE-CATTURABILE
           END-EVALUATE.
      *
       FETCH-CURSOR-CD02-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       CLOSE-CURSOR-CD02.
      *
TRC        SET GL-TRC-LEVEL3                TO TRUE
TRC        MOVE '*** CLOSE-CURSOR-CD02 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           EXEC SQL
                CLOSE CD02
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN ZEROES
                    CONTINUE

               WHEN OTHER
                    SET GL-ERR-CDERRCAU-APPLIC
                                         TO TRUE
                    MOVE 'M6'            TO GL-ERR-CDPROCED
                    MOVE 'E999'          TO GL-ERR-CDERRKEY
                    MOVE 'CUR '          TO GL-ERR-CDRESTYP
                    MOVE 'CLOSE  '       TO GL-ERR-CDRESNAM
                    MOVE SQLCODE         TO GL-ERR-DSERDATA
                    MOVE 'ERR. DB2 CLOSE CURCD02     '
                                         TO GL-ERR-DSERTEXT-INTERNO
                    MOVE SPACES          TO GL-ERR-DSERTEXT-ESTERNO
                    PERFORM ERRORE-CATTURABILE
           END-EVALUATE.
      *
       CLOSE-CURSOR-CD02-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       OPER-FINALI.
      *
TRC        SET GL-TRC-LEVEL3             TO TRUE
TRC        MOVE '*** OPER-FINALI ***'    TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
      *    CHIUSURA FILE DI INPUT --------------------------------------
           PERFORM CLOSE-FILE-FILEINP THRU
                   CLOSE-FILE-FILEINP-EXIT

      *    CHIUSURA FILE CONDIZIONI ------------------------------------
           PERFORM CLOSE-FILE-FILECDZ THRU
                   CLOSE-FILE-FILECDZ-EXIT

      *    CHIUSURA FILE DI OUTPUT -------------------------------------
           PERFORM CLOSE-FILE-FILEOU1 THRU
                   CLOSE-FILE-FILEOU1-EXIT

           PERFORM CLOSE-FILE-FILEOU2 THRU
                   CLOSE-FILE-FILEOU2-EXIT

      *    INVIO STATISTICHE A SYSOUT ----------------------------------
           PERFORM STATISTICA-SYSOUT  THRU
                   STATISTICA-SYSOUT-EXIT.
      *
048400     PERFORM DROP-TEMPORARY-TABLE THRU
048500             DROP-TEMPORARY-TABLE-EXIT
048600
048700     PERFORM DROP-INDEX THRU
048800             DROP-INDEX-EXIT
048900
           .
       OPER-FINALI-EXIT.
           EXIT.


      *-----------------------------------------------------------------
047700*----------------------------------------------------------------*
047800 INTAB-FILECDZ.
047900*
048000     MOVE 'INTAB-FILECDZ'          TO WD-MESSAGE.
DEBUGG*    DISPLAY 'WTDPCAF5 ' WD-MESSAGE.
048300*
048400     PERFORM CREATE-TEMPORARY-TABLE THRU
048500             CREATE-TEMPORARY-TABLE-EXIT
048600
048700     PERFORM CREATE-INDEX THRU
048800             CREATE-INDEX-EXIT
048900
049000     PERFORM READ-FILECDZ THRU
049100             READ-FILECDZ-EXIT
049200
049300     IF FS-FILECDZ = "10" THEN
049400        DISPLAY WS-PGMNAME ' FILE CONDIZIONI VUOTO'
049500        MOVE SQLCODE               TO CW999-SQLCODE
049600        MOVE 'READ  '              TO CW999-TIPO-ACCESSO
049700        MOVE 'FILECDZ '            TO CW999-NOME-TABELLA
049800        MOVE 'INTAB-FILECDZ'       TO CW999-NOME-LABEL
049900        PERFORM ERRORE-10        THRU ERRORE-10-EXIT
050000     END-IF
050100
050200     PERFORM INSERT-FILECDZ-TABLE THRU
050300             INSERT-FILECDZ-TABLE-EXIT
050400       UNTIL FS-FILECDZ NOT = "00".
050500
050600 INTAB-FILECDZ-EXIT.
050700     EXIT.
050800
050900
051000*----------------------------------------------------------------*
051200 CREATE-TEMPORARY-TABLE.
051300*
051400     MOVE 'CREATE-TEMPORARY-TABLE' TO WD-MESSAGE.
DEBUGG*    DISPLAY 'WTDPCAF5 ' WD-MESSAGE.
051700*
051800     EXEC SQL
051900          DECLARE GLOBAL TEMPORARY TABLE SESSION.TEMPCDZV
052000          (
                 TEMPCDZV_DSVAL1        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL2        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL3        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL4        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL5        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL6        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL7        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL8        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL9        CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DSVAL10       CHAR(12)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_CDCNVEST      CHAR(30)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_CONDIZIONE    CHAR(08)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_QUALIFICATORE CHAR(05)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_CDSRV0        CHAR(05)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_CDCLA0        DECIMAL(2,0)
                                                  NOT NULL WITH DEFAULT,
                 TEMPCDZV_CDCDZ0        DECIMAL(3,0)
                                                  NOT NULL WITH DEFAULT,
                 TEMPCDZV_CDOPE0        CHAR(05)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_TIPO          CHAR(07)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_VRTAS0        DECIMAL(9,6)
                                                  NOT NULL WITH DEFAULT,
                 TEMPCDZV_VRIMP4        DECIMAL(18,6)
                                                  NOT NULL WITH DEFAULT,
                 TEMPCDZV_IDLIN0        DECIMAL(2,0)
                                                  NOT NULL WITH DEFAULT,
                 TEMPCDZV_IDLDC0        DECIMAL(2,0)
                                                  NOT NULL WITH DEFAULT,
                 TEMPCDZV_CDFORVAL      CHAR(01)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DTINIZIO      CHAR(10)  NOT NULL WITH DEFAULT,
                 TEMPCDZV_DTFINE        CHAR(10)  NOT NULL WITH DEFAULT
052400          )
052500          ON COMMIT PRESERVE ROWS
052600     END-EXEC.
052700
052800     EVALUATE SQLCODE
052900         WHEN ZERO
053000              CONTINUE
053100
053200         WHEN OTHER
053300              DISPLAY WS-PGMNAME ' ERRORE CREAZ.TAB. TEMPCDZ'     V'
053400              MOVE SQLCODE         TO CW999-SQLCODE
053500              MOVE 'CREATE'        TO CW999-TIPO-ACCESSO
053600              MOVE 'TEMPCDZV'      TO CW999-NOME-TABELLA
053700              MOVE 'CREATE-TEMPORARY-TABLE'
053800                TO CW999-NOME-LABEL
053900              PERFORM ERRORE-10  THRU ERRORE-10-EXIT
054000     END-EVALUATE.
054100
054200 CREATE-TEMPORARY-TABLE-EXIT.
054300     EXIT.
054400
054500
054600*----------------------------------------------------------------*
054700*----------------------------------------------------------------*
054800 CREATE-INDEX.
054900*
055000     MOVE 'CREATE-INDEX'           TO WD-MESSAGE.
DEBUGG*    DISPLAY 'WTDPCAF5 ' WD-MESSAGE.
055300*
055400     EXEC SQL
055500         CREATE UNIQUE INDEX SESSION.IDX0
055600         ON SESSION.TEMPCDZV
052000          (
                 TEMPCDZV_CDSRV0 ASC,
                 TEMPCDZV_CDCLA0 ASC,
                 TEMPCDZV_CDCDZ0 ASC,
                 TEMPCDZV_CDOPE0 ASC,
                 TEMPCDZV_TIPO   ASC,
                 TEMPCDZV_DSVAL1 ASC,
                 TEMPCDZV_DSVAL2 ASC,
                 TEMPCDZV_DSVAL3 ASC,
                 TEMPCDZV_DSVAL4 ASC,
                 TEMPCDZV_DSVAL5 ASC,
MR1512           TEMPCDZV_CDCNVEST ASC,
REVDTE           TEMPCDZV_DTINIZIO ASC,
REVDTE           TEMPCDZV_DTFINE ASC
052400          )
055700          CLUSTER
055800          BUFFERPOOL BP2
055900          CLOSE NO
056000          COPY NO
056100     END-EXEC.
056200
056300     EVALUATE SQLCODE
056400         WHEN ZERO
056500              CONTINUE
056600
056700         WHEN OTHER
056800              DISPLAY WS-PGMNAME ' ERRORE CREAZIONE INDEX'
056900              DISPLAY WS-PGMNAME ' SQLERRMC: ' SQLERRMC
057000              MOVE SQLCODE         TO CW999-SQLCODE
057100              MOVE 'CREATE'        TO CW999-TIPO-ACCESSO
057200              MOVE 'IDX0'          TO CW999-NOME-TABELLA
057300              MOVE 'CREATE-INDEX' TO CW999-NOME-LABEL
057400              PERFORM ERRORE-10  THRU ERRORE-10-EXIT
057500     END-EVALUATE.
057600*
057700 CREATE-INDEX-EXIT.
057800     EXIT.
057900
059600*----------------------------------------------------------------*
059700*----------------------------------------------------------------*
059800 READ-FILECDZ.
059900*
060000     MOVE 'READ-FILECDZ'           TO WD-MESSAGE.
DEBUGG*    DISPLAY 'WTDPCAF5 ' WD-MESSAGE.
060300*
060400     READ FILECDZ
060500     END-READ.
060600*
060700 READ-FILECDZ-EXIT.
060800     EXIT.
060900
061000
061100*----------------------------------------------------------------*
061200*----------------------------------------------------------------*
061300 INSERT-FILECDZ-TABLE.
061400*
061500     MOVE 'INSERT-FILECDZ-TABLE'   TO WD-MESSAGE.
DEBUGG*    DISPLAY 'WTDPCAF5 ' WD-MESSAGE.
061800*
           MOVE SPACES TO TEMPCDZV-DSVAL1
                          TEMPCDZV-DSVAL2
                          TEMPCDZV-DSVAL3
                          TEMPCDZV-DSVAL4
                          TEMPCDZV-DSVAL5
                          TEMPCDZV-DSVAL6
                          TEMPCDZV-DSVAL7
                          TEMPCDZV-DSVAL8
                          TEMPCDZV-DSVAL9
                          TEMPCDZV-DSVAL10
                          TEMPCDZV-CDCNVEST
                          TEMPCDZV-CONDIZIONE
                          TEMPCDZV-QUALIFICATORE
                          TEMPCDZV-CDSRV0
                          TEMPCDZV-CDOPE0
                          TEMPCDZV-TIPO
                          TEMPCDZV-CDFORVAL
REVDTE                    TEMPCDZV-DTINIZIO
REVDTE                    TEMPCDZV-DTFINE
062500*
           MOVE ZERO   TO TEMPCDZV-CDCLA0
                          TEMPCDZV-CDCDZ0
                          TEMPCDZV-VRTAS0
                          TEMPCDZV-VRIMP4
                          TEMPCDZV-IDLIN0
                          TEMPCDZV-IDLDC0.

           MOVE FCDZ-I-DSVAL1            TO  TEMPCDZV-DSVAL1
           MOVE FCDZ-I-DSVAL2            TO  TEMPCDZV-DSVAL2
           MOVE FCDZ-I-DSVAL3            TO  TEMPCDZV-DSVAL3
           MOVE FCDZ-I-DSVAL4            TO  TEMPCDZV-DSVAL4
           MOVE FCDZ-I-DSVAL5            TO  TEMPCDZV-DSVAL5
           MOVE FCDZ-I-DSVAL6            TO  TEMPCDZV-DSVAL6
           MOVE FCDZ-I-DSVAL7            TO  TEMPCDZV-DSVAL7
           MOVE FCDZ-I-DSVAL8            TO  TEMPCDZV-DSVAL8
           MOVE FCDZ-I-DSVAL9            TO  TEMPCDZV-DSVAL9
           MOVE FCDZ-I-DSVAL10           TO  TEMPCDZV-DSVAL10
           MOVE FCDZ-I-CDCNVEST          TO  TEMPCDZV-CDCNVEST
           MOVE FCDZ-I-CONDIZIONE        TO  TEMPCDZV-CONDIZIONE
           MOVE FCDZ-I-QUALIFICATORE     TO  TEMPCDZV-QUALIFICATORE
           MOVE FCDZ-I-CDSRV0            TO  TEMPCDZV-CDSRV0
           MOVE FCDZ-I-CDCLA0            TO  TEMPCDZV-CDCLA0
           MOVE FCDZ-I-CDCDZ0            TO  TEMPCDZV-CDCDZ0
           MOVE FCDZ-I-CDOPE0            TO  TEMPCDZV-CDOPE0
           MOVE FCDZ-I-TIPO              TO  TEMPCDZV-TIPO
           MOVE FCDZ-I-VRTAS0            TO  TEMPCDZV-VRTAS0
           MOVE FCDZ-I-VRIMP4            TO  TEMPCDZV-VRIMP4
           MOVE FCDZ-I-CDFORVAL          TO  TEMPCDZV-CDFORVAL
REVDTE     MOVE FCDZ-I-DTINIZIO          TO  TEMPCDZV-DTINIZIO
REVDTE     MOVE FCDZ-I-DTFINE            TO  TEMPCDZV-DTFINE
           MOVE FCDZ-I-IDLIN0            TO  TEMPCDZV-IDLIN0
           MOVE FCDZ-I-IDLDC0            TO  TEMPCDZV-IDLDC0

062600     EXEC SQL
062700         INSERT INTO SESSION.TEMPCDZV
               ( TEMPCDZV_DSVAL1,
                 TEMPCDZV_DSVAL2,
                 TEMPCDZV_DSVAL3,
                 TEMPCDZV_DSVAL4,
                 TEMPCDZV_DSVAL5,
                 TEMPCDZV_DSVAL6,
                 TEMPCDZV_DSVAL7,
                 TEMPCDZV_DSVAL8,
                 TEMPCDZV_DSVAL9,
                 TEMPCDZV_DSVAL10,
                 TEMPCDZV_CDCNVEST,
                 TEMPCDZV_CONDIZIONE,
                 TEMPCDZV_QUALIFICATORE,
                 TEMPCDZV_CDSRV0,
                 TEMPCDZV_CDCLA0,
                 TEMPCDZV_CDCDZ0,
                 TEMPCDZV_CDOPE0,
                 TEMPCDZV_TIPO,
                 TEMPCDZV_VRTAS0,
                 TEMPCDZV_VRIMP4,
                 TEMPCDZV_IDLIN0,
                 TEMPCDZV_IDLDC0,
                 TEMPCDZV_CDFORVAL,
                 TEMPCDZV_DTINIZIO,
                 TEMPCDZV_DTFINE)
062900         VALUES
               (:TEMPCDZV-DSVAL1,
                :TEMPCDZV-DSVAL2,
                :TEMPCDZV-DSVAL3,
                :TEMPCDZV-DSVAL4,
                :TEMPCDZV-DSVAL5,
                :TEMPCDZV-DSVAL6,
                :TEMPCDZV-DSVAL7,
                :TEMPCDZV-DSVAL8,
                :TEMPCDZV-DSVAL9,
                :TEMPCDZV-DSVAL10,
                :TEMPCDZV-CDCNVEST,
                :TEMPCDZV-CONDIZIONE,
                :TEMPCDZV-QUALIFICATORE,
                :TEMPCDZV-CDSRV0,
                :TEMPCDZV-CDCLA0,
                :TEMPCDZV-CDCDZ0,
                :TEMPCDZV-CDOPE0,
                :TEMPCDZV-TIPO,
                :TEMPCDZV-VRTAS0,
                :TEMPCDZV-VRIMP4,
                :TEMPCDZV-IDLIN0,
                :TEMPCDZV-IDLDC0,
                :TEMPCDZV-CDFORVAL,
                :TEMPCDZV-DTINIZIO,
                :TEMPCDZV-DTFINE)
063400     END-EXEC.
063500
063600     EVALUATE SQLCODE
063700         WHEN ZERO
                    CONTINUE
DEBUGG*             DISPLAY 'CARICATO'
DEBUGG*             TEMPCDZV-DSVAL1        '/'
DEBUGG*             TEMPCDZV-DSVAL2        '/'
DEBUGG*             TEMPCDZV-DSVAL3        '/'
DEBUGG*             TEMPCDZV-CONDIZIONE    '/'
DEBUGG*             TEMPCDZV-QUALIFICATORE '/'
DEBUGG*             TEMPCDZV-CDSRV0        '/'
DEBUGG*             TEMPCDZV-CDCLA0        '/'
DEBUGG*             TEMPCDZV-CDCDZ0        '/'
DEBUGG*             TEMPCDZV-CDOPE0        '/'
DEBUGG*             TEMPCDZV-TIPO          '/'
DEBUGG*             TEMPCDZV-VRTAS0        '/'
DEBUGG*             TEMPCDZV-VRIMP4 '/'
DEBUGG*             TEMPCDZV-DTINIZIO      '/'
DEBUGG*             TEMPCDZV-DTFINE
063900         WHEN OTHER
                    DISPLAY 'ERRORE CARICAMENTO '
                    TEMPCDZV-DSVAL1        '/'
                    TEMPCDZV-DSVAL2        '/'
                    TEMPCDZV-DSVAL3        '/'
                    TEMPCDZV-CONDIZIONE    '/'
                    TEMPCDZV-QUALIFICATORE '/'
                    TEMPCDZV-CDSRV0        '/'
                    TEMPCDZV-CDCLA0        '/'
                    TEMPCDZV-CDCDZ0        '/'
                    TEMPCDZV-CDOPE0        '/'
                    TEMPCDZV-TIPO          '/'
                    TEMPCDZV-VRTAS0        '/'
                    TEMPCDZV-VRIMP4 '/'
                    TEMPCDZV-DTINIZIO      '/'
                    TEMPCDZV-DTFINE
DEBUGG              DISPLAY FILECDZ-REC
064000              DISPLAY WS-PGMNAME ' ERRORE INSERT TEMPCDZV'
064100              MOVE SQLCODE         TO CW999-SQLCODE
064200              MOVE 'INSERT'        TO CW999-TIPO-ACCESSO
064300              MOVE 'TEMPCDZV'      TO CW999-NOME-TABELLA
064400              MOVE 'INSERT-FILECDZ-TABLE'
064500                                   TO CW999-NOME-LABEL
064600              PERFORM ERRORE-10  THRU ERRORE-10-EXIT
064700     END-EVALUATE.
064800*
064900     PERFORM READ-FILECDZ THRU
065000             READ-FILECDZ-EXIT.
065100
065200 INSERT-FILECDZ-TABLE-EXIT.
065300     EXIT.
065400
051200 DROP-TEMPORARY-TABLE.
051300*
051400     MOVE 'DROP-TEMPORARY-TABLE' TO WD-MESSAGE.
DEBUGG*    DISPLAY 'WTDPCAF5 ' WD-MESSAGE.
051700*
051800*    EXEC SQL
051900*         DELETE  TEMPORARY TABLE SESSION.TEMPCDZV
052500*         ON COMMIT PRESERVE ROWS
052600*    END-EXEC.
052700
052800     EVALUATE SQLCODE
052900         WHEN ZERO
053000              CONTINUE
053100
053200         WHEN OTHER
053300              DISPLAY WS-PGMNAME ' ERRORE DROP  TAB. TEMPCDZ'     V'
053400              MOVE SQLCODE         TO CW999-SQLCODE
053500              MOVE 'DROP  '        TO CW999-TIPO-ACCESSO
053600              MOVE 'TEMPCDZV'      TO CW999-NOME-TABELLA
053700              MOVE 'DROP-TEMPORARY-TABLE'
053800                TO CW999-NOME-LABEL
053900              PERFORM ERRORE-10  THRU ERRORE-10-EXIT
054000     END-EVALUATE.
054100
054200 DROP-TEMPORARY-TABLE-EXIT.
054300     EXIT.
054400
054500
054600*----------------------------------------------------------------*
054700*----------------------------------------------------------------*
054800 DROP-INDEX.
054900*
055000     MOVE 'DROP-INDEX'             TO WD-MESSAGE.
DEBUGG*    DISPLAY 'WTDPCAF5 ' WD-MESSAGE.
055300*
055400*    EXEC SQL
055500*        DROP INDEX SESSION.IDX0
055600*        ON SESSION.TEMPCDZV
056100*    END-EXEC.
056200
056300     EVALUATE SQLCODE
056400         WHEN ZERO
056500              CONTINUE
056600
056700         WHEN OTHER
056800              DISPLAY WS-PGMNAME ' ERRORE DROP INDEX'
056900              DISPLAY WS-PGMNAME ' SQLERRMC: ' SQLERRMC
057000              MOVE SQLCODE         TO CW999-SQLCODE
057100              MOVE 'DROP'          TO CW999-TIPO-ACCESSO
057200              MOVE 'IDX0'          TO CW999-NOME-TABELLA
057300              MOVE 'DROP-INDEX' TO CW999-NOME-LABEL
057400              PERFORM ERRORE-10  THRU ERRORE-10-EXIT
057500     END-EVALUATE.
057600*
057700 DROP-INDEX-EXIT.
057800     EXIT.
057900
      *-----------------------------------------------------------------
       CLOSE-FILE-FILEINP.
      *
TRC        SET GL-TRC-LEVEL3                 TO TRUE
TRC        MOVE '*** CLOSE-FILE-FILEINP ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           CLOSE FILEINP.
           IF FS-FILEINP NOT = '00'
              SET GL-ERR-CDERRCAU-LOGICA TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'CLOS'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILEINP            TO GL-ERR-DSERDATA
              MOVE 'ERRORE CHIUSURA FILE OUTPUT'
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE CHIUSURA FILE OUTPUT'
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
       CLOSE-FILE-FILEINP-EXIT.
           EXIT.


057900
      *-----------------------------------------------------------------
       CLOSE-FILE-FILECDZ.
      *
TRC        SET GL-TRC-LEVEL3                 TO TRUE
TRC        MOVE '*** CLOSE-FILE-FILECDZ ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           CLOSE FILECDZ.
           IF FS-FILECDZ NOT = '00'
              SET GL-ERR-CDERRCAU-LOGICA TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'CLOS'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILECDZ            TO GL-ERR-DSERDATA
              MOVE 'ERRORE CHIUSURA FILE OUTPUT'
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE CHIUSURA FILE OUTPUT'
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
       CLOSE-FILE-FILECDZ-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       CLOSE-FILE-FILEOU1.
      *
TRC        SET GL-TRC-LEVEL3                 TO TRUE
TRC        MOVE '*** CLOSE-FILE-FILEOU1 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           CLOSE FILEOU1.
           IF FS-FILEOU1 NOT = '00'
              SET GL-ERR-CDERRCAU-LOGICA TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'CLOS'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILEOU1            TO GL-ERR-DSERDATA
              MOVE 'ERRORE CHIUSURA FILE OUTPUT'
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE CHIUSURA FILE OUTPUT'
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
       CLOSE-FILE-FILEOU1-EXIT.
           EXIT.



      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       CLOSE-FILE-FILEOU2.
      *
TRC        SET GL-TRC-LEVEL3                 TO TRUE
TRC        MOVE '*** CLOSE-FILE-FILEOU2 ***' TO GL-TRC-MSG
TRC        COPY WYKTRCP.
      *
           CLOSE FILEOU2.
           IF FS-FILEOU2 NOT = '00'
              SET GL-ERR-CDERRCAU-LOGICA TO TRUE
              MOVE 'M6'                  TO GL-ERR-CDPROCED
              MOVE 'E999'                TO GL-ERR-CDERRKEY
              MOVE 'CLOS'                TO GL-ERR-CDRESTYP
              MOVE 'STATUS'              TO GL-ERR-CDRESNAM
              MOVE FS-FILEOU2            TO GL-ERR-DSERDATA
              MOVE 'ERRORE CHIUSURA FILE OUTPUT'
                                         TO GL-ERR-DSERTEXT-INTERNO
              MOVE 'ERRORE CHIUSURA FILE OUTPUT'
                                         TO GL-ERR-DSERTEXT-ESTERNO
              PERFORM ERRORE-CATTURABILE
           END-IF.
      *
       CLOSE-FILE-FILEOU2-EXIT.
           EXIT.


      *-----------------------------------------------------------------
      *-----------------------------------------------------------------
       STATISTICA-SYSOUT.
      *
           SET  GL-TRC-LEVEL3               TO TRUE
           MOVE '*** STATISTICA-SYSOUT ***' TO GL-TRC-MSG.
           COPY WYKTRCP.
      *
           DISPLAY '******************** WTDPCAF5 ********************' '
           DISPLAY '************ STATISTICHE ELABORAZIONE ************'
           DISPLAY '**************************************************'
           DISPLAY ' '
           DISPLAY '* ELABORAZIONE CONDIZIONI DAL ' WS-DATA-INIZIO
           DISPLAY '*                          AL ' WS-DATA-FINE
           DISPLAY ' '
           MOVE WS-CTR-LETTI                        TO WS-DISPLAY
           DISPLAY '* TOTALE RECORD LETTI DA INP____:' WS-DISPLAY
           DISPLAY ' '
           MOVE WS-CTR-LETTI-CD02                   TO WS-DISPLAY
           DISPLAY '* TOTALE RECORD LETTI DA CDZ____:' WS-DISPLAY
           DISPLAY ' '
           MOVE WS-CTR-SCRITTI-OU1                  TO WS-DISPLAY
           DISPLAY '* TOTALE RECORD SCRITTI CDZ S___:' WS-DISPLAY
           MOVE WS-CTR-SCRITTI-OU2                  TO WS-DISPLAY
           DISPLAY '* TOTALE RECORD SCRITTI CDZ N___:' WS-DISPLAY
           DISPLAY ' '
           DISPLAY '**************************************************'
           DISPLAY '**************** FINE STATISTICHE ****************'
           DISPLAY '**************************************************'.
      *
       STATISTICA-SYSOUT-EXIT.
           EXIT.
179000*-----------------------------------------------------------------
179100*-----------------------------------------------------------------
179200 ERRORE-10.
179300*
179400     MOVE 'ERRORE-10'              TO WD-MESSAGE.
DEBUGG*    DISPLAY 'WTDPCAF5 ' WD-MESSAGE.
179700*
179800     MOVE WS-PGMNAME               TO CW999-NOME-PGM.
179900     DISPLAY CW999RIGA-MSG-ERR.
180000     MOVE 3599                     TO ABEND-CODE.
180100     CALL ILBOABN0 USING ABEND-CODE.
180200*
180300 ERRORE-10-EXIT.
180400     EXIT.
180500
      *
       NEST SECTION. CONTINUE.
          COPY WYKPGMN.
       END PROGRAM WTDPCAF5.
      *
