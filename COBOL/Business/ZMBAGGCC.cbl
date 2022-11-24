      *---------------------------------------------------------------*
      * RIPRESA DA PRODUZIONE PER RICOMPILARLA IN COLLAUDO -----------*
      *---------------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZMBAGGCC.
      *****************************************************************
      *VERSIONE DI COLLAUDO AL 21 08 2015           *******************
      *RIPRESA DA PRODUZIONE                        *******************
      *SALVATA SULLA AFIFIAS1.ESTE.SNPO.DOL         *******************
      *****************************************************************
      *                                                               *
      *  FUNZIONI : CHIAMA LA ROUTINE DI PRENOTAZ/ANNULL              *
      *  BPO087                                                       *
      *  MODIFICHE:  LABEL      DATA     DESCRIZIONE                  *
      *  BPO118      PER I PROCESSI 1006 1005 1604   NON DEVE         *
      *              AGGIORNARE I C/C                                 *
      *---------------------------------------------------------------*
      *  BPO138      NUOVA TABELLA RACCORDO CAUSALI OPERATIVE         *
      *              SISEB3 CON QUELLE BANCO PT X(10)                 *
      *  BPO158      PER L-MODULO = 'STNRIV' DRIVER STORNO OPERAZIONI *
      *              NON RIVALORIZZATE, NON DEVE EFFETTUARE ELABORAZ. *
      *  BPO168      NEL CASO IN CUI HO SOLO SPESE OUR E NON MOVIMENTO*
      *              UN CONTO CORRENTE DEVO COMUNQUE AGGIORNARE IL    *
      *              CONTO DI SERVIZIO                                *
      *  BPO199      LETTURA DEL TIPO SPESA(B,O,S) PER VALORIZZAZIONE *
      *              CAUSALE SPESE BEN                                *
      *  BPO288      NON AGGIORNA SPESE OUR PER PROCESSO 1607         *
      *  BPO304      AGGIUNTO CAMPO VARCHAR PER SALVARE I CODOPE      *
      *  BPO411      NUOVA CAUSALE DI STORNO PER SPESE BEN (ST8)      *
      *  BPO407      PER TIPO PROCESSO 76 (REGISTRAZ. BUSTA) LEGGE    *
      *              IL FLUSSO 1504                                   *
      *  BPO413      PER STRONO PROCESSI 1620, 1005, 1006 NON DEVE    *
      *              AGGIORNARE I C/C                                 *
      *  BPO444      ERRATA SEGNALAZIONE CAUSALE C/C PER SPESE BEN    *
      *              IN CASO DI REJECT CON ZVR160301 = 'O'            *
      *  BPO640      LA DESCRIZIONE PASSATA A C/C ERA ERRATA NEGLI    *
      *              ULTIMI 5 BYTE                                    *
      *  BPO660      ERRATI COODOPE PER TARGET2                       *
      *  BPO668      ANOMALIA PRENOTATAZIONE PER BONIFICI IN ARRIVO   *
      *              IMP ORD < SOMMA SPESE                            *
      *  BPO676      PER IL 1005 E TIPO STC 400 DEVE AGGIORNARE I C/C *
      *              MA NON IL CONTO DI SERVIZIO  PERCHE' IN REALTA'  *
      *              LA RENDITA E' FITTIZIA IN QUANTO POSO HA  GIA'   *
      *              RECLAMATO I SOLDI                                *
      *  BPO679      PER IL 1005 MODIFICA DESCRIZIONE SPESE PER       *
      *              INQUIRY MOVIMENTI C/C METTENDO DIPOPE E NUMOPE   *
      *              DELL'OPERAZIONE ORIGINARIA                       *
      *  BPO730      IL CANALE DOCB (CBI) CONSIDERATO COME DOCO
      *  BPO742      ANOMALIA OPERAZIONE DI STORNO RIVALORIZZATA
      *              NON AGGIORNAVA CONTO DI SERVIZIO
      *  BPO745      RECUPERO SPESE OPERAZIONE
      *  BPO751      PER OPERAZIONE DI RECALL CON PCS 2276 PASSATI
      *              I RIFERIMENTI DELL'OPERAZIONE ORIGINARIA
      *              DAL FLUSSO 1502 TAG 540, 541
      *  BPO770      ERRORE RIVALORIZZAZIONE QUANDO CON I CAMBI NUOVI
      *              SI ASPETTA UNA PRENOTAZIONE SPESE MAGG BONIFICO
      *              CHE PRIMA NON E' AVVENUTA
      *  BPO896      IN FASE DI ANNULLO STORNO OPERAZIONI SOSPESE
      *              ACSOS, ADSOS, ESSOS NON DEVE ADD/ACC CONTI CORRENTI
      *  BPO905      IN FASE DI STORNO   DI OPERAZIONI SOSPESE
      *              ACSOS, ADSOS, ESSOS  DEVE ADD/ACC CONTI CORRENTI
      *  BPO888      IL CANALE DOTE (TENT) CONSIDERATO COME DOCB
      *  BPO893      INSERIMENTO PRENOTAZIONE IN DARE I N CASO DI CPCS
      *              131 ACCREDITO CON PRENOTATA (PER ANTITERRORISMO)
      * BPO912       IN PERFORM 'R0050-INSERISCI-PRENOTATA' NON
      *              APPLICARE LA PERCENTUALE DI PRENOTAZIONE FONDI
      *              (ISTI-PSCAPRF) SE SI TRATTA DI PROCESSO 1620
      *              E LA DIVISA DEL CONTO DARE = 'EUR'
      * BPO947       VARIATA MODALITA' PER PRENOTATA PER ANTITERRORISMO
      *              DA NESSUNA FORZATURA ('04') A FORZA BLOCCHI E
      *              SCONFINO ('03') IN GEPP-MODALITA
      * BPO950       VARIATA CASUALE ANTITERRORISMO DA '48E' A 'VTR'
      * MCN002       MODIFICHE PER MULTICANALITA'
      * APE001       MODIFICHE PER NUOVA CHIAVE IN TBTACABP
      * BPO999       ANOMALIA SE IMPORTO BON. ARR. MINORE  DELLE SPESE
      *              SE IN RIVALORIZZAZIONE DIVENTA MAGGIORE E
      *              RECORD SU AMOVCC GIë PRESENTE PER IMPRE
      *              ANNULLIAMO LA PRENOTAZIONE
      *---------------------------------------------------------------*
      * BPOA04       MODIFICA PERFORM R0060-ANNULLA-PRENOTATA (NON    *
      *              EFFETTUA IL TEST SU PROCESSO 2131)               *
      *              INSERIMENTO PERFORM R0060-ANNULLA-PREN-EURO PER  *
      *              PER ANNULLO PRENOTATA PER OPERAZIONI IN EURO     *
      *              O STORNO DI OPERAZIONE CON PRENOTATA PER ANTIT.  *
      *              ASTERISCATA FASE DI ANNULLO PRENOTAZIONE ANTITER.*
      *              PER OPERAZIONE NON RIVALORIZZATA                 *
      *              INSERITA PERFORM DI INSERIMENTO PRENOTATA PERCHE'*
      *              IN CASO DI PRENOTATA PER SPESE > IMP. NON        *
      *              INSERIVA LA PRENOTATA SU MOV 23 DEL PROCESSO 2131*
      *---------------------------------------------------------------*
      * APE004       PROCESSO EURO CERTO PER CARTA 2120               *
      *              (MODIFICA EFFETTUATA PER CONTO DI SERVIZIO, IN   *
      *               CASO DI CARTA COMUNQUE EFFETTUA L'AGGIORNAMENTO *
      *               DEL CONTO DI SERVIZIO SU ZMBAGGCC)              *
      *---------------------------------------------------------------*
      *---------------------------------------------------------------*
      * 06-07-2018 | IM0006 | BIC | GESTIONE CONTO DI SERVIZIO PER    *
      *            |        |     | IMEL ON                           *
      *---------------------------------------------------------------*
      *---------------------------------------------------------------*
      * 14-03-2019 | IM0026 | BIC | GESTIONE CANALE SU TBTACABP       *
      * 19-04-2019 | IM0026 | BIC | GESTIONE CODOPE SU TBTACABP       *
      *---------------------------------------------------------------*
      * 02-07-2019 | IM0031 | BIC | GESTIONE FLG-GEST-2 PER PSD2      *
      *---------------------------------------------------------------*
      * 05-08-2019 | IM0032 | BIC | MODIFICA BUSINESS - GESTIONE CAUS.*
      *---------------------------------------------------------------*
      * 20-11-2019 | IM0032 | BIC | MODIFICA PER CONTO DI SERVIZIO   .*
      *---------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *---------------------------> AREA DI PASSAGGIO PER ROUTINE BP
           COPY PPTCGEPP.
      *----> AREA DI PASSAGGIO ROUTINE CONTROLLO ESISTENZA CONTO ----
           COPY PPTCINCC.
       01  AREA-SV2P.
           COPY CSVCSV2P.
      *
IM0006*----> DEFINIZIONE AREA ALTRI FLAG                         ----*
IM0006     COPY ZMWCONFG.
IM0006 01  W-DATA-IMEL             PIC X(06).
IM0006 01  W-DATA-IMEL-N REDEFINES W-DATA-IMEL
IM0006                                 PIC 9(06).
IM0006 01  W-DATA-IMEL-08          PIC X(08).
IM0006 01  W-DATA-IMEL-08-N REDEFINES W-DATA-IMEL-08
IM0006                                 PIC 9(08).
IM0006 01  WRK-DATAS.
IM0006     05 WRK-DATAS-ANNO          PIC 9(04).
IM0006     05 WRK-DATAS-MM            PIC 9(02).
IM0006     05 WRK-DATAS-GG            PIC 9(02).
IM0006 01  WRK-DATA-SISTEMA REDEFINES WRK-DATAS
IM0006                                PIC 9(08).
           COPY ZMWCONFC.
      *----------------------------------------- AREA DI COMODO DMSGO
           COPY ZMWPRMGO.
BPO304*----------------------------------------- AREA DI COMODO MOVCC
BPO304     COPY ZMWMOVCC.
BPO676*----  AREA DI WORKING PER CONTROLLI NUMERICI
BPO676     COPY ZMWCTRNM.
      *----------------------------------> CAMPI DI COMODO
MCN002*----------------- AREA PER: FXRCAN01
MCN002 01 WRK-TIPO-CANALE   PIC X(1) VALUE SPACES.
IM0026 01 WRK-FLG-GEST-1    PIC X(01) VALUE SPACES.                     00011700
IM0026 01 WRK-FLG-GEST-5    PIC X(06) VALUE SPACES.                     00011700
IM0031 01 WRK-FLG-GEST-2    PIC X(01) VALUE SPACES.                     00011700
MCN002 01 WRK-CANALE-CAN01  PIC X(06) VALUE SPACES.                     00011700
MCN002 01 WRK-CALL-CAN01    PIC X(08) VALUE 'FXRCAN01'.                 00011700
MCN002     COPY FXWCAN01.                                               00011700
MCN002*                                                                 00011700
       01  WRK-GEPP-LEN             PIC S9(03) COMP     VALUE +500.
BPO676 01  WRK-DEC3                 PIC 99999999999999,999.
BPO676 01  WRK-COM-CIMP1            PIC S9(15)V9(03) VALUE ZEROES.
       01  WRK-SV2P-LEN             PIC S9(05) COMP     VALUE +7000.
       01   WRK-MAX-IND-TAB-DMSGO  PIC 9(04) VALUE 88.
       01   FINE-TBADMSGO      PIC X(2) VALUE SPACES.
       01  CAMPI-COMODO.
BPO770     02  WRK-SALTA-GEPP   PIC  X(02)      VALUE SPACES.
           02  WRK-ZRAGSOCO     PIC  X(35)      VALUE SPACES.
           02  WRK-ZINDO        PIC  X(35)      VALUE SPACES.
           02  WRK-ZRAGSOCO-110 PIC  X(35)      VALUE SPACES.
           02  WRK-ZINDO-120    PIC  X(35)      VALUE SPACES.
BPO751     02  WRK-DIPOPERIF    PIC  9(05)      VALUE ZEROES.
BPO751     02  WRK-NUMOPERIF    PIC  9(07)      VALUE ZEROES.
BPO199     02  WRK-TIPOSPS-255  PIC  X(01)      VALUE SPACES.
BPO676     02  WRK-CDPZ-OPECOLL PIC  9(05)      VALUE ZEROES.
BPO679     02  WRK-NUMOPE-OPECOLL PIC  9(07)    VALUE ZEROES.
BPO676     02  WRK-FLAG-OPECOLL PIC  X(01)      VALUE SPACES.
BPO676     02  WRK-OPE-FITOEBS  PIC  X(01)      VALUE SPACES.
           02  WRK-INCC-CATRAPP PIC  X(12)      VALUE SPACES.
           02  WRK-INCC-FILIALE PIC  X(05)      VALUE SPACES.
           02  WRK-TERMIMM      PIC  X(08)      VALUE SPACES.
           02  WRK-AGGIORNA-CC  PIC  X(01)      VALUE SPACES.
           02  WRK-COPERIM      PIC  X(08)      VALUE SPACES.
           02  WRK-DIPEIMM      PIC  X(08)      VALUE SPACES.
           02  WRK-FLAG-PRE     PIC  X(01)      VALUE SPACES.
           02  WRK-FLAG-ANNPRE  PIC  X(01)      VALUE SPACES.
           02  WRK-TROVATO      PIC  X(01)      VALUE SPACES.
           02  WRK-TROVATO-MOVE PIC  X(01)      VALUE SPACES.
           02  WRK-TIP-OPER     PIC  X(04)      VALUE SPACES.
           02  WRK-TRAN-ANN     PIC  X(04)      VALUE SPACES.
           02  WRK-ELABORA      PIC  X(01)      VALUE SPACES.
           02  WRK-ELABORA-1    PIC  X(01)      VALUE SPACES.
           02  WRK-NUMOPE       PIC  9(07)      VALUE ZEROES.
           02  WRK-NUMPRECC     PIC  9(15)      VALUE ZEROES.
           02  WRK-FTIPOPE      PIC  9(01)      VALUE ZEROES.
           02  WRK-INDRIC       PIC  9(02)      VALUE ZEROES.
           02  WRK-VALORE       PIC  X(35)      VALUE SPACES.
           02  WRK-NORMALE      PIC  X(35)      VALUE SPACES.
           02  WRK-CODOPE-CC    PIC  X(08)      VALUE SPACES.
           02  WRK-CIRCUITO     PIC  X(03)      VALUE SPACES.
           02  WRK-DATA-VALUTA  PIC  9(08)      VALUE ZEROES.
           02  WRK-DATA-VALUTA-X REDEFINES WRK-DATA-VALUTA.
               03  WRK-DATA-AA1    PIC  9(02).
               03  WRK-DATA-AA2    PIC  9(02).
               03  WRK-DATA-MM     PIC  9(02).
               03  WRK-DATA-GG     PIC  9(02).
           02  WRK-DATAN               PIC 9(08) VALUE ZEROS.
           02  WRK-DATA2 REDEFINES WRK-DATAN.
               05  WRK-ANNO            PIC 9(04).
               05  WRK-MESE            PIC 9(02).
               05  WRK-GIORNO          PIC 9(02).
           02  WRK-DATAG               PIC 9(08) VALUE ZEROS.
           02  WRK-DATA3 REDEFINES WRK-DATAG.
               05  WRK-GIORNO          PIC 9(02).
               05  WRK-MESE            PIC 9(02).
               05  WRK-ANNO            PIC 9(04).
           02  WRK-SOMMA-SPESE  PIC  S9(15)V9(03) VALUE ZEROES.
           02  WRK-SOMMA-SPESE2 PIC  S9(15)V9(02) VALUE ZEROES.
           02  WRK-SPESA-CC     PIC  S9(15)V9(03) VALUE ZEROES.
           02  WRK-APP-3DEC     PIC   9(15)V9(03) VALUE ZEROES.
           02  WRK-APP-2DEC     PIC   9(15)V9(02) VALUE ZEROES.
           02  WRK-APP-DIF      PIC   9(01)V9(03) VALUE ZEROES.
      *--- INIZIO
           02  WRK-IMPORTO     PIC  S9(18)      VALUE ZEROES.
           02  WRK-IMPORTO-E          REDEFINES
               WRK-IMPORTO            PIC S9(15)V999.
           02  WRK-IMPORTO-ITL PIC  S9(18)      VALUE ZEROES.
           02  WRK-IMPORTO-EUR PIC  S9(15)V9(3) VALUE ZEROES.
      *--- TERMINE
           02  WRK-IMPORTO-ASS PIC   9(18)      VALUE ZEROES.
      *--- INIZIO
           02  WRK-IMPORTO-ASS-E      REDEFINES
               WRK-IMPORTO-ASS        PIC  9(15)V999.
           02  WRK-TIMESTAMP-X.
               04  WRK-TIMES-ANNO-X      PIC X(04).
               04  F                     PIC X(01).
               04  WRK-TIMES-MESE-X      PIC X(02).
               04  F                     PIC X(01).
               04  WRK-TIMES-GIOR-X      PIC X(02).
               04  F                     PIC X(01).
               04  WRK-TIMES-ORA-X       PIC X(02).
               04  F                     PIC X(01).
               04  WRK-TIMES-MIN-X       PIC X(02).
               04  F                     PIC X(01).
               04  WRK-TIMES-SEC-X       PIC X(02).
               04  F                     PIC X(07).
           02  WRK-TIMESTAMP  REDEFINES WRK-TIMESTAMP-X.
               04  WRK-TIMES-ANNO        PIC 9(04).
               04  F                     PIC X(01).
               04  WRK-TIMES-MESE        PIC 9(02).
               04  F                     PIC X(01).
               04  WRK-TIMES-GIOR        PIC 9(02).
               04  F                     PIC X(01).
               04  WRK-TIMES-ORA         PIC 9(02).
               04  F                     PIC X(01).
               04  WRK-TIMES-MIN         PIC 9(02).
               04  F                     PIC X(01).
               04  WRK-TIMES-SEC         PIC 9(02).
               04  F                     PIC X(07).
           02  WRK-TIMES-F.
               04  WRK-TIMES-ORA-F       PIC 9(02).
               04  WRK-TIMES-MIN-F       PIC 9(02).
               04  WRK-TIMES-SEC-F       PIC 9(02).
           02  WRK-TIMES-FN  REDEFINES  WRK-TIMES-F PIC 9(06).
       01  NUM-ELETTRONICO.
           02  FILL1           PIC  X(02)      VALUE SPACES.
           02  OPER            PIC S9(02) COMP VALUE ZEROES.
           02  PROC            PIC  9(02)      VALUE ZEROES.
           02  FILL2           PIC  X(04)      VALUE SPACES.
      *----------------  INIZIO 00001 -------------------------------*
       01  WRK-CAUSALE-X.
           03 WRK-CAUSALE            PIC 9(2).
       01  INDRIC                    PIC 9(02)            VALUE ZEROES.
       01  NUMZERI                   PIC 9(03)            VALUE ZEROES.
       01  LEN-CMP                   PIC 9(03)            VALUE ZEROES.
       01  IND1-1                    PIC 9(02) VALUE ZEROES.            00230300
       01  IND1-2                    PIC 9(02) VALUE ZEROES.            00230300
       01  IND2-1                    PIC 9(02) VALUE ZEROES.            00230300
       01  IND2-2                    PIC 9(02) VALUE ZEROES.            00230300
       01  MAX-IND1-1                PIC 9(02) VALUE 10.                00230300
       01  MAX-IND1-2                PIC 9(02) VALUE 10.                00230300
BPO168 01  MAX-IND2-1                PIC 9(02) VALUE 10.                00230300
       01  MAX-IND2-2                PIC 9(02) VALUE 10.                00230300
       01  WRK-MOVE                  PIC X(01) VALUE SPACES.            00230300
       01  WRK-SOUR-CSERV            PIC X(01) VALUE SPACES.
BPO668 01  WRK-IMPMOVP               PIC S9(15)V9(3) COMP-3.            00780000
BPO893 01  WRK-IMPMOVP-131           PIC S9(15)V9(3) COMP-3.            00780000
BPO168 01  WRK-DCLTBTABSC            PIC X(330) VALUE SPACES.
BPO187 01  WRK-DCLTBAMOVP            PIC X(560) VALUE SPACES.
       01  W-DESCRIZIONE-APP         PIC X(060).
       01  W-DESCRIZIONE1            PIC X(065).
       01  R-W-DESCRIZIONE1   REDEFINES W-DESCRIZIONE1.
           02 DESCR-MOV        PIC X(12).
           02 DESCR-CDPZ       PIC 9(05).
           02 DESCR-X          PIC X(01).
           02 DESCR-NUMOPE     PIC 9(07).
           02 FILLER           PIC X(01).
           02 VAL-ORDINANTE    PIC X(04).
           02 DESCR-ORDINANTE1 PIC X(35).
BPO679 01  R-W-DESCRIZIONE1-1 REDEFINES W-DESCRIZIONE1.
BPO679     02 DESCR-SPESE-BON  PIC X(41).
BPO679     02 DESCR-CDPZ-1     PIC 9(05).
BPO679     02 DESCR-X-1        PIC X(01).
BPO679     02 DESCR-NUMOPE-1   PIC 9(07).
BPO679     02 FILLER           PIC X(11).
       01  W-DESCRIZIONE2            PIC X(060).
       01  R-W-DESCRIZIONE2   REDEFINES W-DESCRIZIONE2.
           02 DESCR-ORDINANTE2 PIC X(35).
           02 FILLER           PIC X(25).

      *----- TABELLA PER C/C --------*                                  00660000
       01  TABELLA-CONTOC1.                                             00670000
           02  ELEMENTO-CONTOC1 OCCURS 10.                              00680000
               05 KEY1-CONTOC-MOV.                                      00690000
                  07  KEY1-MOVP-NCCO    PIC 9(12).                      00710000
                  07  KEY1-MOVP-CDPZ    PIC 9(05).                      00720000
               05  KEY1-MOVP-CIST       PIC 9(4).                       00750000
               05  KEY1-MOVP-CSTC       PIC 9(5).                       00760000
               05  KEY1-MOVP-CISO       PIC X(3).                       00770000
               05  KEY1-MOVP-DIPOPE     PIC 9(5).                       00820000
               05  KEY1-MOVP-NUMOPE     PIC 9(7).                       00830000
               05  KEY1-MOVP-NPRGMOVP   PIC 9(4).                       00830000
               05  KEY1-MOVP-NSUBMOVP   PIC 9(1).                       00830000
               05  KEY1-MOVP-CODOPE     PIC X(08).                      00780000
BPO138*        05  KEY1-MOVP-CCAUNOP    PIC X(03).                      00780000
BPO138         05  KEY1-MOVP-CCAUNOP    PIC X(10).                      00780000
               05  KEY1-MOVP-DVAL       PIC 9(8).                       00830000
               05  KEY1-MOVP-DCON       PIC 9(8).                       00830000
               05  KEY1-MOVP-TMOV       PIC 9(01).
               05  KEY1-MOVP-FSPESE     PIC X(01).
               05  KEY1-MOVP-MOVIMENTI  OCCURS 10 TIMES.
                   07  KEY1-MOVP-FLAGDA     PIC X(1).                   00770000
                   07  KEY1-MOVP-ICTVLIS    PIC 9(15)V9(3) COMP-3.      00780000
                   07  KEY1-MOVP-CAUSALE    PIC X(10).                  00780000
BPO304             07  KEY1-MOVP-CAUSALES   PIC X(03).                  00780000
BPO304             07  KEY1-MOVP-CSTCS      PIC X(10).                  00780000
      *----- TABELLA PER C/DI SERVIZIO*                                 00660000
       01  TABELLA-CONTOC2.                                             00670000
           02  ELEMENTO-CONTOC2 OCCURS 10.                              00680000
               05 KEY2-CONTOC-MOV.                                      00690000
                  07  KEY2-MOVP-NCCO    PIC 9(12).                      00710000
               05  KEY2-MOVP-DIPOPE     PIC 9(5).                       00820000
               05  KEY2-MOVP-NUMOPE     PIC 9(7).                       00830000
               05  KEY2-MOVP-TMOV       PIC 9(1).                       00830000
               05  KEY2-MOVP-NPRGMOVP   PIC 9(4).                       00830000
               05  KEY2-MOVP-NSUBMOVP   PIC 9(1).                       00830000
               05  KEY2-MOVP-CODOPE     PIC X(08).                      00780000
               05  KEY2-MOVP-DCON       PIC 9(8).                       00830000
               05  KEY2-MOVP-CISO       PIC X(3).                       00830000
               05  KEY2-MOVP-MOVIMENTI  OCCURS 10 TIMES.
                   07  KEY2-MOVP-FLAGDA     PIC X(1).                   00770000
                   07  KEY2-MOVP-IMOV       PIC 9(15)V9(3) COMP-3.      00780000
                   07  KEY2-MOVP-ICTVLIS     PIC 9(15)V9(3) COMP-3.     00780000
                   07  KEY2-MOVP-CAUSALE    PIC X(10).                  00780000
BPO304             07  KEY2-MOVP-CAUSALES   PIC X(03).                  00780000
IM0006             07  KEY2-MOVP-FLGCARTA   PIC X(01).                  00780000
BPO304             07  KEY2-MOVP-CSTCS      PIC X(10).                  00780000
      *----------------   FINE  00001 -------------------------------*
      *----> AREA DI WORKING COMUNE A TUTTI I PROGRAMMI          ----
           COPY ZMWCOMUN.
      *----> AREA DI WORKING PER ERRORI SQL                      ----
           COPY ZMWSQLRC.
      *--------------------------------------------------------------
      *----  DECLARE DB2  -------------------------------------------
      *--------------------------------------------------------------
      *------   SQLCA   ---------------------------------------------
           EXEC SQL INCLUDE SQLCA     END-EXEC.
      *
      *------   AREA COMUNI DB2 -------------------------------------*
           EXEC SQL   INCLUDE ZMICOMUN    END-EXEC.
      *
      *------   TABELLA TBAMOVCC(473) ------------------------------*
           EXEC SQL INCLUDE ZMGMOVCC  END-EXEC.
      *
      *------   TABELLA TBTISTI(204) ------------------------------*
           EXEC SQL INCLUDE ZMGISTI   END-EXEC.
      *
IM0006*------   TABELLA TBWCONFG       ------------------------------*
IM0006     EXEC SQL INCLUDE ZMGCONFG  END-EXEC.
      *
      *------   TABELLA TBWCONFC(611) ------------------------------*
           EXEC SQL INCLUDE ZMGCONFC  END-EXEC.
      *
      *------   TABELLA TBWPRPCS(315) ------------------------------*
           EXEC SQL INCLUDE ZMGPRPCS  END-EXEC.
      *------   TABELLA TBAOPE  (115) ------------------------------*
           EXEC SQL INCLUDE ZMGOPE    END-EXEC.
      *
      *------   TABELLA TBAMOVP (116) ------------------------------*
           EXEC SQL INCLUDE ZMGMOVP   END-EXEC.
      *
      *------   TABELLA TBAMOVP (119) ------------------------------*
           EXEC SQL INCLUDE ZMGMOVE   END-EXEC.
      *
      *------   TABELLA TBTABSC (214) ------------------------------*
           EXEC SQL INCLUDE ZMGABSC   END-EXEC.
      *
      *------   TABELLA TBTTRERR(222) ------------------------------*
           EXEC SQL INCLUDE ZMGTRERR  END-EXEC.
BPO407*----------------  DEFINIZIONE TABELLA         TAPROC    (203)
BPO407     EXEC SQL INCLUDE ZMGAPROC  END-EXEC.

      *------   DEFINIZIONE TABELLA DI ZM.TBADMSGO        -------------*
           EXEC SQL INCLUDE ZMGDMSGO END-EXEC.
BPO138*------   DEFINIZIONE TABELLA DI ZM.TBTACABP(708)   -------------*
BPO138     EXEC SQL INCLUDE ZMGACABP END-EXEC.
BPO187*------   DEFINIZIONE TABELLA DI ZM.TBTBFA  (669)   -------------*
BPO187     EXEC SQL INCLUDE ZMGBFA END-EXEC.
BPO676*------   DEFINIZIONE TABELLA DI ZM.TBTABCEC(205)   -------------*
BPO676     EXEC SQL INCLUDE ZMGABCEC END-EXEC.
      *
      *------   DECLARE CUR1 SU AMOVP ------------------------------*   02380000
           EXEC SQL INCLUDE ZMC11601  END-EXEC.                         02390000
      *------   DECLARE CUR2 SU AMOVP ------------------------------*   02380000
           EXEC SQL INCLUDE ZMC11902  END-EXEC.                         02390000
      *--------------- DEFINIZIONE CURSORE 7 TABELLA ZM.TBADMSGO (122)
           EXEC SQL INCLUDE ZMC12202 END-EXEC.
      *                                                                 02M00000
       LINKAGE SECTION.
       01 DFHCOMMAREA.
          COPY ZMWLINKA.

      * ----> INCLUDE PER PROCEDURE DIVISION <----
           EXEC SQL INCLUDE ZMYPROCE  END-EXEC.

TEST00*    DISPLAY 'ZMBAGGCC - PROVA BUSINESS'
           IF L-WCICTRA NOT = '2'                                       03990000
              GO TO FINE                                                04000000
           END-IF.                                                      04010000
      *-> PRELEVO IL CODICE ISTITUTO                                    04050000
           MOVE L-CIST                   TO W-CIST.                     04060000
                                                                        04070000
      *-> PRELEVO IL CODICE DIPENDENZA                                  04080000
           MOVE L-DPZOPE                 TO WCM-CDPZ.                   04081000
                                                                        04082000
      *-> PRELEVO IL NUMERO OPERAZIONE                                  04086000
                                                                        04087000
           MOVE L-NUMOPE                 TO WRK-NUMOPE.                 04088000
                                                                        04089000
           MOVE W-CIST                   TO OPE-CIST                    04090000
                                            MOVP-CIST                   04100000
                                            ABSC-CIST                   04110000
                                            TRERR-CIST                  04120000
                                            MOVCC-CIST.                 04120000
                                                                        04130000
           MOVE WCM-CDPZ                  TO OPE-DIPOPE                 04140000
                                             MOVP-DIPOPE                04150000
                                             MOVCC-DIPOPE               04150000

           MOVE WRK-NUMOPE                TO OPE-NUMOPE                 04160000
                                             MOVCC-NUMOPE               04170000
                                             MOVP-NUMOPE.               04170000
      *
      *PRELEVA IL TIME STAMP
      *
           INITIALIZE DCLTBTISTI.
           MOVE W-CIST                    TO ISTI-CIST
           PERFORM R0005-PRELEVA-TIMESTAMP
              THRU R0005-PRELEVA-TIMESTAMP-END
           IF W-SQL-OK
              MOVE  WCM-WTIME              TO WRK-TIMESTAMP-X
           END-IF.
           MOVE WRK-TIMES-ORA              TO WRK-TIMES-ORA-F
           MOVE WRK-TIMES-MIN              TO WRK-TIMES-MIN-F
           MOVE WRK-TIMES-SEC              TO WRK-TIMES-SEC-F
           MOVE WRK-TIMES-FN               TO WCM-ORA-SIS.
      *
IM0006     MOVE WCM-WTIME (1:4)    TO WRK-DATAS-ANNO
IM0006     MOVE WCM-WTIME (6:2)    TO WRK-DATAS-MM
IM0006     MOVE WCM-WTIME (9:2)    TO WRK-DATAS-GG
IM0006     PERFORM TP136-LEGGI-CONFG
IM0006        THRU TP136-LEGGI-CONFG-END

           MOVE L-AREA-IST                TO DCLTBTISTI.
BPO407     MOVE L-AREA-APROC              TO DCLTBTAPROC.
      *                                                                 04170010
                                                                        04170400
           PERFORM R0010-LEGGI-TBAOPE                                   04180000
              THRU R0010-LEGGI-TBAOPE-END.                              04190000
           IF W-SQL-OK
BPO676*BPO118        IF OPE-CPCS = 1604 OR 1005 OR 1006
BPO676        IF OPE-CPCS = 1604 OR 1006
BPO118           GO TO FINE
BPO118        END-IF
BPO413        IF (OPE-CPCS = 1011 AND
BPO676*BPO413           (OPE-CPCSORI =1604 OR 1005 OR 1006)
BPO676           (OPE-CPCSORI = 1604 OR 1006)) OR
BPO676           (OPE-CPCS = 1010 AND
BPO676           (OPE-CPCSORI = 1604 OR 1006))
BPO413           GO TO FINE
BPO413        END-IF
              MOVE OPE-DESCOPE  TO WCM-DATA-SIS
      *       MOVE OPE-OESCOPE  TO WCM-ORA-SIS
              MOVE OPE-CTER     TO WCM-TERMIN
              MOVE OPE-NMTRUTE  TO WCM-NMTRUTE
           END-IF

MCN002     IF OPE-CANTRASM NOT = SPACES
MCN002        INITIALIZE AREA-FXWCAN01
MCN002        MOVE 'B'                  TO FXWCAN01-TCALL
MCN002        MOVE OPE-CANTRASM         TO FXWCAN01-NOME-CANALE
MCN002        MOVE SPACES               TO WRK-TIPO-CANALE
MCN002        CALL WRK-CALL-CAN01    USING AREA-FXWCAN01
MCN002        EVALUATE FXWCAN01-ESITO
MCN002          WHEN SPACES
MCN002            MOVE FXWCAN01-TIPO-CANALE TO WRK-TIPO-CANALE
IM0026            MOVE FXWCAN01-FLG-GEST-1  TO WRK-FLG-GEST-1
IM0026            MOVE FXWCAN01-FLG-GEST-5  TO WRK-FLG-GEST-5
IM0031            MOVE FXWCAN01-FLG-GEST-2  TO WRK-FLG-GEST-2
MCN002          WHEN OTHER
MCN002            IF FXWCAN01-COD-ERR = 'C02'
MCN002              MOVE SPACES             TO WRK-TIPO-CANALE
IM0026              MOVE SPACES             TO WRK-FLG-GEST-1
IM0026              MOVE SPACES             TO WRK-FLG-GEST-5
IM0031              MOVE SPACES             TO WRK-FLG-GEST-2
MCN002            ELSE
MCN002              MOVE 8                      TO W-FLAG-ERR           06260000
MCN002              MOVE FXWCAN01-COD-ERR       TO W-COD-ERR            0000
MCN002              MOVE 'FXRCAN01'             TO L-MODULO             0000
MCN002              MOVE FXWCAN01-DESCR-ERR     TO L-SUB-MODULO         0000
MCN002              MOVE FXWCAN01-ESITO         TO L-NOME-TABELLA       0000
MCN002              PERFORM 9999-GESTIONE-ERRORE                        0000
MCN002                 THRU 9999-GESTIONE-ERRORE-END                    0000
MCN002              GO TO FINE                                          0000
MCN002            END-IF
MCN002        END-EVALUATE
MCN002     ELSE
MCN002        MOVE SPACES               TO WRK-TIPO-CANALE
IM0026        MOVE SPACES               TO WRK-FLG-GEST-1
IM0026        MOVE SPACES               TO WRK-FLG-GEST-5
IM0031        MOVE SPACES               TO WRK-FLG-GEST-2
MCN002     END-IF

      *SIA PER LA PRENOTAZIONE CHE PER L'AGGIORNAMENTO SI DEVE SCRIVERE
      *LA DESCRIZIONE DELL'ORDINANTE/BENEFICIARIO CHE SI PRELEVA DAL
      *FLUSSO 1502
BPO407* PER IL PROCESSO DI REGISTRAZIONE BUSTA EUROGIRO(TPCS = 76)
BPO407* LEGGE IL FLUSSO 1504-
BPO407*    PERFORM PREPARA-DES-FL1502
BPO407*       THRU PREPARA-DES-FL1502-END
           PERFORM PREPARA-DES-FLUSSO
              THRU PREPARA-DES-FLUSSO-END
           INITIALIZE DCLTBWCONFC.
           MOVE W-CIST         TO CONFC-CIST.
           PERFORM R0010-LEGGI-TBWCONFC                                 04180000
              THRU R0010-LEGGI-TBWCONFC-END.                            04190000
           IF W-SQL-OK
              MOVE CONFC-AREACONFC TO  ZMWCONFC
IM0006        MOVE CONFC-AREACONF2 TO  ZMWCONFC2
           END-IF
      *                                                                 04200000
      *                                                                 04280000
      *-------------------> SCORRE I MOVIMENTI                          04350100
           PERFORM R0020-APERTURA-CURSORE1                              04350200
              THRU R0020-APERTURA-CURSORE1-END.                         04350300
           MOVE ZEROES TO IND1-1.
           MOVE ZEROES TO IND1-2.
           MOVE ZEROES TO IND2-1.
           MOVE ZEROES TO IND2-2.
           MOVE SPACES TO WRK-SOUR-CSERV.
      *                                                                 04360000
           PERFORM R6070-FETCH-TBAMOVP                                  04370000
              THRU R6070-FETCH-TBAMOVP-END                              04380000
             UNTIL WRK-TROVATO = 'N'.                                   04390000
                                                                        04400000
           PERFORM R0040-CHIUSURA-CURSORE1                              04451500
              THRU R0040-CHIUSURA-CURSORE1-END.                         04451600

BPO168*QUESTA ELABORAZIONE VIENE ESEGUITA SOLO NEL CASO IN CUI
BPO168*L'OPERAZIONE NON MOVIMENTA UN TIPO STC = 400 MA CI SONO
BPO168*COMUNQUE SPESE DA RICONOSCERE O DA ADDEBITARE ALLA BANCA
BPO168*IN QUESTO CASO DEVE ESSERE COMUNQUE AGGIORNATO IL CONTO DI
BPO168*SERVIZIO- SUL CONTO DI SERVIZIO NON VENGONO FATTE PRENOTATE
BPO168*MA SOLO AGGIORNAMENTI. IN FASE DI VERIFICA SONO STATE FATTI
BPO168*PER CONTROLLI DI CAPIENZA
BPO168     IF WRK-ELABORA-1 NOT = 'S' AND                               04456000
BPO168        WRK-SOUR-CSERV = 'S'
BPO168        PERFORM VARYING IND2-1 FROM 1 BY 1                        04880000
BPO168          UNTIL IND2-1  > MAX-IND2-1
BPO168             OR KEY2-MOVP-NCCO(IND2-1) NOT GREATER ZEROES         04890000
BPO168        IF OPE-TCAB = 'L'                                         30000
BPO168           EVALUATE L-MODULO(1:6)
BPO168****FASE DI ANNULLO PRIMA DI RIVALORIZZAZIONE
BPO168           WHEN 'ANNULL'
BPO168             GO TO FINE
BPO168****FASE DI DRIVER DI STORNO OPERAZIONI NON RIVALORIZZATE PER LE
BPO168****QUALI LA CONTI CORRENTI E' STATA AGGIORNATA IN BATCH
BPO168           WHEN 'STNRIV'
BPO168             GO TO FINE
BPO168****FASE DI RIVALORIZZAZIONE
BPO168           WHEN 'RIVALO'
BPO168             IF OPE-BCKFTIPOPE = 1
BPO168                IF OPE-DIPOPE = 311
BPO168                   MOVE 'DIREZ'    TO WRK-DIPEIMM
BPO168                ELSE
BPO168                   MOVE '00000'          TO WRK-DIPEIMM
BPO168                   MOVE OPE-DIPOPE       TO WRK-VALORE
BPO168                   PERFORM NORMALIZZA-CDPZ
BPO168                      THRU NORMALIZZA-CDPZ-END
BPO168                   MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
BPO168                END-IF
BPO168*---CANALE DI TRASMISSIONE NON VALORIZZATO
BPO168                IF OPE-CANTRASM NOT GREATER SPACES
BPO168                   MOVE 'ESTE'    TO WRK-TERMIMM
BPO168                   MOVE OPE-NMTRUTE TO WRK-COPERIM
BPO168                ELSE
BPO168*---CANALE DI TRASMISSIONE VALORIZZATO ES. BPIOL BPOL DORE ETC
BPO168                   MOVE SPACES       TO WRK-COPERIM
MCN002***                IF OPE-CANTRASM = 'DORE'
MCN002                   IF WRK-TIPO-CANALE = 'R'
BPO168                      MOVE 'BPOL' TO WRK-TERMIMM
IM0031                      IF WRK-FLG-GEST-2 = 'P'
IM0031                         MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                      END-IF
IM0031                   ELSE
MCN002***                   IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                      IF WRK-TIPO-CANALE = 'C'
BPO168                         MOVE 'BPIO' TO WRK-TERMIMM
BPO168                      ELSE
BPO168                         MOVE OPE-CANTRASM TO WRK-TERMIMM
BPO168                      END-IF
BPO168                   END-IF
BPO168                END-IF
BPO676                IF OPE-CPCS = 1005  OR
BPO676                 (OPE-CPCS = 1011 AND OPE-CPCSORI = 1005) OR
BPO676                 (OPE-CPCS = 1010 AND OPE-CPCSORI = 1005)
BPO676                  NEXT SENTENCE
BPO676                ELSE
BPO168                   PERFORM R0070-AGGIORNA-CSERV
BPO168                      THRU R0070-AGGIORNA-CSERV-END
BPO168                   IF SV2P-RETCODE EQUAL SPACES
BPO168                      INITIALIZE DCLTBAMOVCC
BPO304                      INITIALIZE W-TAB-MOVCC
BPO168                      MOVE W-CIST        TO MOVCC-CIST
BPO168                     MOVE KEY2-MOVP-DIPOPE(IND2-1) TO MOVCC-DIPOPE
BPO168                     MOVE KEY2-MOVP-NUMOPE(IND2-1) TO MOVCC-NUMOPE
BPO168                      IF IND2-1 GREATER 1
BPO168                         COMPUTE MOVCC-NPRGMOVP =  99 - IND2-1
BPO168                      ELSE
BPO168                         MOVE 99     TO MOVCC-NPRGMOVP
BPO168                      END-IF
BPO168                      MOVE ZEROES   TO MOVCC-NSUBMOVP
BPO168                      MOVE SV2P-NUMMOVI    TO MOVCC-NUMOPECC
BPO168                     MOVE KEY2-MOVP-CODOPE(IND2-1) TO MOVCC-CODOPE
BPO168                     MOVE WRK-INCC-CATRAPP      TO MOVCC-CATRAPP
BPO304*****SALVO LE CAUSALI
BPO304                      PERFORM VARYING IND2-2 FROM 1 BY 1          04880000
BPO304                        UNTIL IND2-2  > MAX-IND2-2
BPO304                        OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)       04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                        MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                  TO W-MOVCC-CCAUBP(IND2-2)
BPO304                        MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                  TO W-MOVCC-CCAUOP(IND2-2)
BPO304                        MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                      END-PERFORM                                 04890000
BPO304                      MOVE W-TAB-MOVCC  TO MOVCC-WTABCOPE
BPO304*                     MOVE W-TAB-MOVCC  TO MOVCC-WTABCOPE-TEXT

BPO168                      PERFORM R0055-INSERT-AMOVCC
BPO168                         THRU R0055-INSERT-AMOVCC-END
BPO168                  END-IF
BPO676                END-IF
BPO168             ELSE
BPO168*ERRORE, NON PUº ESSERE TIPOPE DIVERSO DA 1
BPO168                MOVE 8                      TO W-FLAG-ERR         06260000
BPO168                MOVE '9999'                 TO W-COD-ERR          0000
BPO168                MOVE 'ZMBAGGCC'             TO L-MODULO           0000
BPO168                MOVE 'TIPOPE DIVERSO DA 1'  TO L-SUB-MODULO       0000
BPO168                MOVE 'RIVALO  '             TO L-NOME-TABELLA     0000
BPO168                PERFORM 9999-GESTIONE-ERRORE                      0000
BPO168                   THRU 9999-GESTIONE-ERRORE-END                  0000
BPO168                GO TO FINE                                        0000
BPO168             END-IF
BPO168****FASE DI ANNULLO PER BONIFICI IN USCITA NON RIVALORIZZATI
BPO168           WHEN 'ANNUBU'
BPO168             GO TO FINE
BPO168****ANNUBE ANNULLA BONIFICI IN ENTRATA CHE NON CHIUDONO C/ATTESA
BPO168           WHEN 'ANNUBE'
BPO168             GO TO FINE
BPO168****ANNUES ANNULLA BONIFICI IN ENTRATA CHE CHIUDONO C/ATTESA
BPO168           WHEN 'ANNUES'
BPO168             GO TO FINE
BPO168*****COMPRENDE ANCHE IL MODULO A SPAZI
BPO168           WHEN OTHER
BPO168             IF OPE-BCKFTIPOPE = 2
BPO168*ANNULLO DI OPERAZIONE NON RIVALORIZZATA NEXT SENTENCE
BPO168*SE RIVALORIZZATA AGGIORNO IL CONTO DI SERVIZIO
BPO168                INITIALIZE DCLTBAMOVCC
BPO168                MOVE W-CIST        TO MOVCC-CIST
BPO168                MOVE KEY2-MOVP-DIPOPE(IND2-1)  TO MOVCC-DIPOPE
BPO168                MOVE KEY2-MOVP-NUMOPE(IND2-1)  TO MOVCC-NUMOPE
BPO168                IF IND2-1 GREATER 1
BPO168                   COMPUTE MOVCC-NPRGMOVP =  99 - IND2-1
BPO168                ELSE
BPO168                   MOVE 99     TO MOVCC-NPRGMOVP
BPO168                END-IF
BPO168                PERFORM R0057-SELECT-AMOVCC
BPO168                   THRU R0057-SELECT-AMOVCC-END
BPO168                IF W-SQL-OK
BPO168                   IF MOVCC-NUMPRECC = ZEROES AND
BPO168                      MOVCC-NUMOPECC GREATER SPACES
BPO168                      MOVE 'S' TO WRK-AGGIORNA-CC
BPO168                   ELSE
BPO168                      MOVE 'N' TO WRK-AGGIORNA-CC
BPO168                   END-IF
BPO168                END-IF
BPO168*****ANNULLO OPERAZIONE DI ADDEBITO/ACCREDITO RIVALORIZZATA
BPO168                IF WRK-AGGIORNA-CC = 'S'
BPO168                   IF OPE-DIPOPE = 311
BPO168                      MOVE 'DIREZ'    TO WRK-DIPEIMM
BPO168                   ELSE
BPO168                      MOVE '00000'  TO WRK-DIPEIMM
BPO168                      MOVE OPE-DIPOPE  TO WRK-VALORE
BPO168                      PERFORM NORMALIZZA-CDPZ
BPO168                         THRU NORMALIZZA-CDPZ-END
BPO168                      MOVE WRK-NORMALE(1:5)   TO WRK-DIPEIMM
BPO168                   END-IF
BPO168*--CANALE DI TRASMISSIONE NON VALORZZATO
BPO168                    IF OPE-CANTRASM NOT GREATER SPACES
BPO168                        MOVE 'ESTE'    TO WRK-TERMIMM
BPO168                        IF OPE-FLUSSOPRV = 'MOSAIC'
BPO168                           MOVE SPACES     TO WRK-COPERIM
BPO168                        ELSE
BPO168                          MOVE OPE-NMTRUTE TO WRK-COPERIM
BPO168                        END-IF
BPO168                    ELSE
BPO168*--CANALE DI TRASMISSIONE VALORZZATO ES BPIOL BPOL DORE ETC
BPO168                        MOVE SPACES    TO WRK-COPERIM
MCN002***                     IF OPE-CANTRASM = 'DORE'
MCN002                        IF WRK-TIPO-CANALE = 'R'
BPO168                           MOVE 'BPOL' TO WRK-TERMIMM
IM0031                           IF WRK-FLG-GEST-2 = 'P'
IM0031                              MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                           END-IF
BPO168                        ELSE
MCN002***                        IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                           IF WRK-TIPO-CANALE = 'C'
BPO168                              MOVE 'BPIO' TO WRK-TERMIMM
BPO168                           ELSE
BPO168                              MOVE OPE-CANTRASM
BPO168                                          TO WRK-TERMIMM
BPO168                           END-IF
BPO168                        END-IF
BPO168                    END-IF
BPO676                    IF OPE-CPCS  = 1005 OR
BPO676                      (OPE-CPCS = 1011 AND OPE-CPCSORI = 1005) OR
BPO676                      (OPE-CPCS = 1010 AND OPE-CPCSORI = 1005)
BPO676                      NEXT SENTENCE
BPO676                    ELSE
BPO168                       PERFORM R0070-AGGIORNA-CSERV
BPO168                          THRU R0070-AGGIORNA-CSERV-END
BPO168                       IF SV2P-RETCODE EQUAL SPACES
BPO168                          INITIALIZE DCLTBAMOVCC
BPO304                          INITIALIZE W-TAB-MOVCC
BPO168                          MOVE W-CIST  TO MOVCC-CIST
BPO168                          MOVE KEY2-MOVP-DIPOPE(IND2-1)
BPO168                                               TO MOVCC-DIPOPE
BPO168                          MOVE KEY2-MOVP-NUMOPE(IND2-1)
BPO168                                               TO MOVCC-NUMOPE
BPO168                          IF IND2-1 GREATER 1
BPO168                             COMPUTE MOVCC-NPRGMOVP =  99 - IND2-1
BPO168                          ELSE
BPO168                             MOVE 99  TO MOVCC-NPRGMOVP
BPO168                          END-IF
BPO168                          MOVE ZEROES        TO MOVCC-NSUBMOVP
BPO168                          MOVE ZEROES        TO MOVCC-NUMOPECC
BPO304*****SALVO LE CAUSALI
BPO304                          PERFORM VARYING IND2-2 FROM 1 BY 1      04880000
BPO304                          UNTIL IND2-2  > MAX-IND2-2
BPO304                             OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)  04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE  KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                    TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                          END-PERFORM                             04890000
BPO304                          MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE
BPO304*                         MOVE W-TAB-MOVCC TO MOVCC-WTABCOPE-TEXT
BPO168                          PERFORM R0080-UPDATE-AMOVCC
BPO168                             THRU R0080-UPDATE-AMOVCC-END
BPO168                        END-IF
BPO676                     END-IF
BPO168                END-IF
BPO168             ELSE
BPO893**********************************************************
BPO893****STORNO DI OPERAZIONE RIVALORIZZATA CON PRENOTATA
BPO893*** ANNULLAMENTO DI AMOVCC IN CASO DI STORNO CPCS 131    *
BPO893**********************************************************
APE001**     DA QUI    *****************************************
BPOA04**********************************************************
BPOA04****ASTERISCATA PERCHE' NON CI PASSA MAI                 *
BPOA04**********************************************************
BPOA04*BPO893                IF OPE-BCKFTIPOPE = 3  AND
BPOA04*BPO893                   OPE-CPCSORI  = 0131
BPOA04*BPO893                   MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPOA04*BPO893                   MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPOA04*BPO893                   PERFORM R0060-ANNULLA-PRENOTATA
BPOA04*BPO893                      THRU R0060-ANNULLA-PRENOTATA-END
BPOA04*BPO893                   IF GEPP-RETCODE = 'OK'
BPOA04*BPO893                      INITIALIZE DCLTBAMOVCC
BPOA04*BPO893                      MOVE W-CIST    TO MOVCC-CIST
BPOA04*BPO893                      MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPOA04*BPO893                      MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPOA04*BPO893                      MOVE 23        TO MOVCC-NPRGMOVP
BPOA04*BPO893                      MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPOA04*BPO893                                    TO MOVCC-NSUBMOVP
BPOA04*BPO893                      MOVE ZEROES    TO MOVCC-NUMOPECC
BPOA04*BPO893                      MOVE ZEROES    TO MOVCC-NUMPRECC
BPOA04*BPO893                      MOVE ZEROES    TO MOVCC-IMPPRE
BPOA04*BPO893                      PERFORM R0080-UPDATE-AMOVCC
BPOA04*BPO893                         THRU R0080-UPDATE-AMOVCC-END
BPOA04*BPO893                  END-IF
BPOA04*BPO893                END-IF
BPOA04*APE001*--------------------------------------------------------*
BPO168****STORNO DI OPERAZIONE RIVALORIZZATA
BPO168                IF OPE-BCKFTIPOPE = 3
BPO905                   INITIALIZE DCLTBAMOVCC
BPO905                   MOVE W-CIST        TO MOVCC-CIST
BPO905                   MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO905                   MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPO905*                  MOVE KEY2-MOVP-DIPOPE(IND2-1)  TO MOVCC-DIPOPE
BPO905*                  MOVE KEY2-MOVP-NUMOPE(IND2-1)  TO MOVCC-NUMOPE
BPO905                   IF IND2-1 GREATER 1
BPO905                      COMPUTE MOVCC-NPRGMOVP =  99 - IND2-1
BPO905                   ELSE
BPO905                      MOVE 99     TO MOVCC-NPRGMOVP
BPO905                   END-IF
BPO905                   PERFORM R0057-SELECT-AMOVCC
BPO905                      THRU R0057-SELECT-AMOVCC-END
BPO905                   IF W-SQL-OK
BPO905                      IF MOVCC-NUMPRECC = ZEROES AND
BPO905                         MOVCC-NUMOPECC GREATER SPACES
BPO905                         MOVE 'S' TO WRK-AGGIORNA-CC
BPO905                      ELSE
BPO905                         MOVE 'N' TO WRK-AGGIORNA-CC
BPO905                      END-IF
BPO905                   END-IF
BPO905*****ANNULLO OPERAZIONE DI ADDEBITO/ACCREDITO RIVALORIZZATA
BPO905                   IF WRK-AGGIORNA-CC = 'S'
BPO168                      IF OPE-DIPOPE = 311
BPO168                         MOVE 'DIREZ'    TO WRK-DIPEIMM
BPO168                      ELSE
BPO168                         MOVE '00000'  TO WRK-DIPEIMM
BPO168                         MOVE OPE-DIPOPE  TO WRK-VALORE
BPO168                         PERFORM NORMALIZZA-CDPZ
BPO168                            THRU NORMALIZZA-CDPZ-END
BPO168                         MOVE WRK-NORMALE(1:5)   TO WRK-DIPEIMM
BPO168                      END-IF
BPO168*--CANALE DI TRASMISSIONE NON VALORZZATO
BPO168                       IF OPE-CANTRASM NOT GREATER SPACES
BPO168                         MOVE 'ESTE'    TO WRK-TERMIMM
BPO168                         IF OPE-FLUSSOPRV = 'MOSAIC'
BPO168                            MOVE SPACES     TO WRK-COPERIM
BPO168                         ELSE
BPO168                           MOVE OPE-NMTRUTE TO WRK-COPERIM
BPO168                         END-IF
BPO168                     ELSE
BPO168*--CANALE DI TRASMISSIONE VALORZZATO ES BPIOL BPOL DORE ETC
BPO168                         MOVE SPACES    TO WRK-COPERIM
MCN002***                      IF OPE-CANTRASM = 'DORE'
MCN002                         IF WRK-TIPO-CANALE = 'R'
BPO168                            MOVE 'BPOL' TO WRK-TERMIMM
IM0031                           IF WRK-FLG-GEST-2 = 'P'
IM0031                              MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                           END-IF
BPO168                         ELSE
MCN002***                         IF OPE-CANTRASM = 'DOCO'
MCN002***                          OR 'DOCA'  OR 'DOCP'
MCN002***                          OR 'DOCM'
MCN002***                          OR 'DOTE'
MCN002                            IF WRK-TIPO-CANALE = 'C'
BPO168                               MOVE 'BPIO' TO WRK-TERMIMM
BPO168                            ELSE
BPO168                               MOVE OPE-CANTRASM
BPO168                                           TO WRK-TERMIMM
BPO168                            END-IF
BPO168                         END-IF
BPO168                    END-IF
BPO676                     IF OPE-CPCS = 1005 OR
BPO676                      (OPE-CPCS = 1011 AND OPE-CPCSORI = 1005) OR
BPO676                      (OPE-CPCS = 1010 AND OPE-CPCSORI = 1005)
BPO676                       NEXT SENTENCE
BPO676                     ELSE
BPO168                        PERFORM R0070-AGGIORNA-CSERV
BPO168                           THRU R0070-AGGIORNA-CSERV-END
BPO168                        IF SV2P-RETCODE EQUAL SPACES
BPO168                           INITIALIZE DCLTBAMOVCC
BPO304                           INITIALIZE W-TAB-MOVCC
BPO168                           MOVE W-CIST  TO MOVCC-CIST
BPO168                           MOVE KEY2-MOVP-DIPOPE(IND2-1)
BPO168                                                TO MOVCC-DIPOPE
BPO168                           MOVE KEY2-MOVP-NUMOPE(IND2-1)
BPO168                                                TO MOVCC-NUMOPE
BPO168                           IF IND2-1 GREATER 1
BPO168                             COMPUTE MOVCC-NPRGMOVP =  99 - IND2-1
BPO168                           ELSE
BPO168                              MOVE 99  TO MOVCC-NPRGMOVP
BPO168                           END-IF
BPO168                           MOVE ZEROES TO    MOVCC-NSUBMOVP
BPO168                           MOVE SV2P-NUMMOVI   TO MOVCC-NUMOPECC
BPO168                           MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                                  TO MOVCC-CODOPE
BPO168                           MOVE WRK-INCC-CATRAPP  TO MOVCC-CATRAPP
BPO304*****SALVO LE CAUSALI
BPO304                           PERFORM VARYING IND2-2 FROM 1 BY 1     04880000
BPO304                              UNTIL IND2-2  > MAX-IND2-2
BPO304                               OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)04890000
BPO304                                               NOT GREATER ZEROES 04890000
BPO304                             MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                      TO W-MOVCC-CCAUOP(IND2-2)
BPO304                             MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                    TO W-MOVCC-CSTC(IND2-2)
BPO304                           END-PERFORM                            04890000
BPO304                          MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE
BPO304*                         MOVE W-TAB-MOVCC  TO MOVCC-WTABCOPE-TEXT
BPO168                          PERFORM R0055-INSERT-AMOVCC
BPO168                             THRU R0055-INSERT-AMOVCC-END
BPO168                       END-IF
BPO676                     END-IF
BPO905                   END-IF
BPO168                END-IF
BPO168             END-IF
BPO168           END-EVALUATE
BPO168        ELSE
BPO168*****OPERAZIONE NON SOSPESA, TUTTE LE DIVISE MOVIMENTATE PARI
BPO168*****A EURO
BPO168           EVALUATE L-MODULO(1:6)
BPO168****FASE DI ANNULLO PRIMA DI RIVALORIZZAZIONE
BPO168           WHEN 'ANNULL'
BPO168             GO TO FINE
BPO168****FASE DI DRIVER DI STORNO OPERAZIONI NON RIVALORIZZATE PER LE
BPO168****QUALI LA CONTI CORRENTI E' STATA AGGIORNATA IN BATCH
BPO168           WHEN 'STNRIV'
BPO168             GO TO FINE
BPO168****FASE DI RIVALORIZZAZIONE
BPO168           WHEN 'RIVALO'
BPO168             MOVE 8                   TO W-FLAG-ERR               06260000
BPO168             MOVE '9999'              TO W-COD-ERR                06270000
BPO168             MOVE 'ZMBAGGCC'          TO L-MODULO                 06300000
BPO168             MOVE 'NON AMMESSO PER CAMBIO L'                      06310000
BPO168                                       TO L-SUB-MODULO            06310000
BPO168             MOVE 'RIVALO  '    TO L-NOME-TABELLA                 06310000
BPO168             PERFORM 9999-GESTIONE-ERRORE                         06320000
BPO168                THRU 9999-GESTIONE-ERRORE-END                     06330000
BPO168             GO TO FINE                                           06340000
BPO168****FASE DI ANNULLO PER BONIFICI IN USCITA NON RIVALORIZZATI
BPO168           WHEN 'ANNUBU'
BPO168              MOVE 8                   TO W-FLAG-ERR              06260000
BPO168              MOVE '9999'              TO W-COD-ERR               06270000
BPO168              MOVE 'ZMBAGGCC'          TO L-MODULO                06300000
BPO168              MOVE 'NON AMMESSO PER CAMBIO <> L'                  06310000
BPO168                                       TO L-SUB-MODULO            06310000
BPO168              MOVE 'ANNUBU  '    TO L-NOME-TABELLA                06310000
BPO168              PERFORM 9999-GESTIONE-ERRORE                        06320000
BPO168                 THRU 9999-GESTIONE-ERRORE-END                    06330000
BPO168                 GO TO FINE                                       06340000
BPO168           WHEN 'ANNUES'
BPO168              MOVE 8                   TO W-FLAG-ERR              06260000
BPO168              MOVE '9999'              TO W-COD-ERR               06270000
BPO168              MOVE 'ZMBAGGCC'          TO L-MODULO                06300000
BPO168              MOVE 'NON AMMESSO PER CAMBIO <> L'                  06310000
BPO168                                       TO L-SUB-MODULO            06310000
BPO168              MOVE 'ANNUES  '    TO L-NOME-TABELLA                06310000
BPO168              PERFORM 9999-GESTIONE-ERRORE                        06320000
BPO168                 THRU 9999-GESTIONE-ERRORE-END                    06330000
BPO168              GO TO FINE                                          06340000
BPO168           WHEN 'ANNUBE'
BPO168              MOVE 8                   TO W-FLAG-ERR              06260000
BPO168              MOVE '9999'              TO W-COD-ERR               06270000
BPO168              MOVE 'ZMBAGGCC'          TO L-MODULO                06300000
BPO168              MOVE 'NON AMMESSO PER CAMBIO L'                     06310000
BPO168                                       TO L-SUB-MODULO            06310000
BPO168              MOVE 'ANNUBE  '    TO L-NOME-TABELLA                06310000
BPO168              PERFORM 9999-GESTIONE-ERRORE                        06320000
BPO168                 THRU 9999-GESTIONE-ERRORE-END                    06330000
BPO168              GO TO FINE                                          06340000
BPO168           WHEN OTHER
BPO168****COMPRENDE ANCHE IL MODULO A SPAZI
BPO168              IF OPE-DIPOPE = 311
BPO168                 MOVE 'DIREZ'    TO WRK-DIPEIMM
BPO168              ELSE
BPO168                 MOVE '00000'  TO WRK-DIPEIMM
BPO168                 MOVE OPE-DIPOPE  TO WRK-VALORE
BPO168                 PERFORM NORMALIZZA-CDPZ
BPO168                    THRU NORMALIZZA-CDPZ-END
BPO168                 MOVE WRK-NORMALE(1:5)  TO WRK-DIPEIMM
BPO168              END-IF
BPO168*----CANALE DI TRASMISSIONE NON VALORIZZATO
BPO168              IF OPE-CANTRASM NOT GREATER SPACES
BPO168                 MOVE 'ESTE'    TO WRK-TERMIMM
BPO168                 IF OPE-FLUSSOPRV = 'MOSAIC'
BPO168                    MOVE SPACES     TO WRK-COPERIM
BPO168                 ELSE
BPO168                    MOVE OPE-NMTRUTE TO WRK-COPERIM
BPO168                 END-IF
BPO168              ELSE
BPO168*----CANALE DI TRASMISSIONE VALORIZZATO ES. BPIOL BPOL DORE ETC
BPO168                 MOVE SPACES    TO WRK-COPERIM
MCN002***              IF OPE-CANTRASM = 'DORE'
MCN002                 IF WRK-TIPO-CANALE = 'R'
BPO168                    MOVE 'BPOL' TO WRK-TERMIMM
IM0031                    IF WRK-FLG-GEST-2 = 'P'
IM0031                       MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                    END-IF
BPO168                 ELSE
MCN002***                 IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                    IF WRK-TIPO-CANALE = 'C'
BPO168                       MOVE 'BPIO' TO WRK-TERMIMM
BPO168                    ELSE
BPO168                       MOVE OPE-CANTRASM    TO WRK-TERMIMM
BPO168                    END-IF
BPO168                 END-IF
BPO168              END-IF
BPO676              IF OPE-CPCS = 1005 OR
BPO676                 (OPE-CPCS = 1011 AND OPE-CPCSORI = 1005) OR
BPO676                 (OPE-CPCS = 1010 AND OPE-CPCSORI = 1005)
BPO676                  NEXT SENTENCE
BPO676              ELSE
BPO168                 PERFORM R0070-AGGIORNA-CSERV
BPO168                    THRU R0070-AGGIORNA-CSERV-END
BPO168                 IF SV2P-RETCODE EQUAL SPACES
BPO168                    INITIALIZE DCLTBAMOVCC
BPO304                    INITIALIZE W-TAB-MOVCC
BPO168                    MOVE W-CIST  TO MOVCC-CIST
BPO168                    MOVE KEY2-MOVP-DIPOPE(IND2-1)  TO MOVCC-DIPOPE
BPO168                    MOVE KEY2-MOVP-NUMOPE(IND2-1)  TO MOVCC-NUMOPE
BPO168                    IF IND2-1 GREATER 1
BPO168                       COMPUTE MOVCC-NPRGMOVP =  99 - IND2-1
BPO168                    ELSE
BPO168                       MOVE 99  TO MOVCC-NPRGMOVP
BPO168                    END-IF
BPO304*****SALVO LE CAUSALI
BPO304                    PERFORM VARYING IND2-2 FROM 1 BY 1            04880000
BPO304                       UNTIL IND2-2  > MAX-IND2-2
BPO304                          OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)     04890000
BPO304                                          NOT GREATER ZEROES      04890000
BPO304                          MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                    TO W-MOVCC-CCAUBP(IND2-2)
BPO304                          MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                          MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                    END-PERFORM                                   04890000
BPO304                    MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE
BPO304*                   MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE-TEXT
BPO168                    IF OPE-BCKFTIPOPE = 1 OR 3
BPO168                       MOVE ZEROES TO    MOVCC-NSUBMOVP
BPO168                       MOVE SV2P-NUMMOVI TO MOVCC-NUMOPECC
BPO168                       MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                       MOVE WRK-INCC-CATRAPP  TO MOVCC-CATRAPP
BPO168                       PERFORM R0055-INSERT-AMOVCC
BPO168                          THRU R0055-INSERT-AMOVCC-END
BPO168                    ELSE
BPO168                       MOVE ZEROES        TO MOVCC-NSUBMOVP
BPO168                       MOVE ZEROES        TO MOVCC-NUMOPECC
BPO168                       PERFORM R0080-UPDATE-AMOVCC
BPO168                          THRU R0080-UPDATE-AMOVCC-END
BPO168                    END-IF
BPO168                 END-IF
BPO676               END-IF
BPO168           END-EVALUATE
BPO168        END-IF
BPO168        END-PERFORM
BPO168     END-IF                                                       04456000
      *                                                                 04451700
BPO168*QUESTO TIPO DI ELABORAZIONE VIENE ESEGUITA OGNI QUALVOLTA
BPO168*NELL'OPERAZIONE E' MOVIMENTATO UN CONTO DI TIPO 400
BPO168*L'AGGIORNAMENTO DEL CONTO DI SERVIZIO PER LA PARTE DELLE SPESE
BPO168*VIENE ESEGUITA SUBITO DOPO L'AGGIORNAMENTO DEL CONTO DEL CLIENTE
           IF WRK-ELABORA-1 = 'S'                                       04456000
              PERFORM VARYING IND1-1 FROM 1 BY 1                        04880000
                UNTIL IND1-1  > MAX-IND1-1
                   OR KEY1-MOVP-NCCO(IND1-1) NOT GREATER ZEROES         04890000
                 MOVE SPACES               TO WRK-FLAG-PRE
      *******SE TIPO CAMBIO L, OPERAZIONE SOSPESA CIOE' ALMENO
      *******UNA DELLE DIVISE MOVIMENTATE E' VALUTA
                 IF OPE-TCAB = 'L'                                      30000
                    EVALUATE L-MODULO(1:6)
      ****FASE DI ANNULLO PRIMA DI RIVALORIZZAZIONE
                    WHEN 'ANNULL'
                      GO TO FINE
      ****FASE DI DRIVER DI STORNO OPERAZIONI NON RIVALORIZZATE PER LE
      ****QUALI LA CONTI CORRENTI E' STATA AGGIORNATA IN BATCH
BPO158              WHEN 'STNRIV'
BPO158                GO TO FINE
      ****FASE DI RIVALORIZZAZIONE
                    WHEN 'RIVALO'
                    IF KEY1-MOVP-TMOV(IND1-1) = 1
                    OR (KEY1-MOVP-TMOV(IND1-1) = 2      AND
                        KEY1-MOVP-FSPESE(IND1-1) = 'S')
      *****OPERAZIONE DI ADDEBITO DEL C/C
                       IF OPE-BCKFTIPOPE = 1
                          IF OPE-DIPOPE = 311
                             MOVE 'DIREZ'    TO WRK-DIPEIMM
                          ELSE
                             MOVE '00000'          TO WRK-DIPEIMM
                             MOVE OPE-DIPOPE       TO WRK-VALORE
                             PERFORM NORMALIZZA-CDPZ
                                THRU NORMALIZZA-CDPZ-END
                             MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
                          END-IF
      *---CANALE DI TRASMISSIONE NON VALORIZZATO
                          IF OPE-CANTRASM NOT GREATER SPACES
                             MOVE 'ESTE'    TO WRK-TERMIMM
      *                      IF OPE-FLUSSOPRV = 'MOSAIC'
      *                         MOVE SPACES     TO WRK-COPERIM
      *                      ELSE
                                MOVE OPE-NMTRUTE TO WRK-COPERIM
      *                      END-IF
                          ELSE
      *---CANALE DI TRASMISSIONE VALORIZZATO ES. BPIOL BPOL DORE ETC
                             MOVE SPACES       TO WRK-COPERIM
MCN002***                    IF OPE-CANTRASM = 'DORE'
MCN002                       IF WRK-TIPO-CANALE = 'R'
                                MOVE 'BPOL' TO WRK-TERMIMM
IM0031                          IF WRK-FLG-GEST-2 = 'P'
IM0031                             MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                          END-IF
                             ELSE
MCN002***                       IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                          IF WRK-TIPO-CANALE = 'C'
                                   MOVE 'BPIO' TO WRK-TERMIMM
                                ELSE
                                   MOVE OPE-CANTRASM TO WRK-TERMIMM
                                END-IF
                             END-IF
                          END-IF
                          PERFORM R0060-ANNULLA-PRENOTATA               50000
                             THRU R0060-ANNULLA-PRENOTATA-END           50000
DOL999                    IF GEPP-RETCODE = 'OK'
                             PERFORM R0070-AGGIORNA-CC                  50000
                                THRU R0070-AGGIORNA-CC-END              50000
                             IF SV2P-RETCODE EQUAL SPACES
                                INITIALIZE DCLTBAMOVCC
BPO304                          INITIALIZE W-TAB-MOVCC
                                MOVE W-CIST        TO MOVCC-CIST
                                MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                   TO MOVCC-DIPOPE
                                MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                   TO MOVCC-NUMOPE
                                MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                   TO MOVCC-NPRGMOVP
                                MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                   TO MOVCC-NSUBMOVP
                                MOVE SV2P-NUMMOVI  TO MOVCC-NUMOPECC
                                MOVE ZEROES        TO MOVCC-NUMPRECC
                                MOVE ZEROES        TO MOVCC-IMPPRE
BPO168                          MOVE WRK-INCC-CATRAPP  TO MOVCC-CATRAPP
BPO168                          MOVE KEY1-MOVP-CODOPE(IND1-1)
BPO168                                                 TO MOVCC-CODOPE
BPO304*****SALVO LE CAUSALI
BPO304                          PERFORM VARYING IND1-2 FROM 1 BY 1      04880000
BPO304                            UNTIL IND1-2  > MAX-IND1-2
BPO304                              OR KEY1-MOVP-CAUSALE(IND1-1,IND1-2) 04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY1-MOVP-CAUSALE(IND1-1,IND1-2)
BPO304                                  TO W-MOVCC-CCAUBP(IND1-2)
BPO304                            MOVE KEY1-MOVP-CAUSALES(IND1-1,IND1-2)
BPO304                                  TO W-MOVCC-CCAUOP(IND1-2)
BPO304                            MOVE KEY1-MOVP-CSTCS(IND1-1,IND1-2)
BPO304                                  TO W-MOVCC-CSTC(IND1-2)
BPO304                          END-PERFORM                             04890000
BPO304                          MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE
BPO304*                         MOVE W-TAB-MOVCC TO MOVCC-WTABCOPE-TEXT
BPO770                          IF WRK-SALTA-GEPP NOT = 'SI'
                                 PERFORM R0080-UPDATE-AMOVCC
                                    THRU R0080-UPDATE-AMOVCC-END
BPO770                          END-IF
                                IF IND2-1 GREATER ZEROES
BPO676                            IF OPE-CPCS = 1005 OR
BPO676                               (OPE-CPCS = 1011 AND
BPO676                                OPE-CPCSORI = 1005) OR
BPO676                               (OPE-CPCS = 1010 AND
BPO676                                OPE-CPCSORI = 1005)
BPO676                               NEXT SENTENCE
BPO676                            ELSE
                                   PERFORM R0070-AGGIORNA-CSERV            50000
                                      THRU R0070-AGGIORNA-CSERV-END        50000
                                   IF SV2P-RETCODE EQUAL SPACES
                                      INITIALIZE DCLTBAMOVCC
BPO304                                INITIALIZE W-TAB-MOVCC
                                      MOVE W-CIST        TO MOVCC-CIST
                                      MOVE KEY2-MOVP-DIPOPE(IND2-1)
                                                        TO MOVCC-DIPOPE
                                      MOVE KEY2-MOVP-NUMOPE(IND2-1)
                                                        TO MOVCC-NUMOPE
                                      IF IND2-1 GREATER 1
                                         COMPUTE MOVCC-NPRGMOVP =
                                                            99 - IND2-1
                                      ELSE
                                          MOVE 99     TO MOVCC-NPRGMOVP
                                      END-IF
                                      MOVE ZEROES   TO MOVCC-NSUBMOVP
                                      MOVE SV2P-NUMMOVI
                                                       TO MOVCC-NUMOPECC
BPO168                                MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                                MOVE WRK-INCC-CATRAPP
BPO168                                                 TO MOVCC-CATRAPP
BPO304                                PERFORM VARYING IND2-2 FROM 1 BY 104880000
BPO304                                  UNTIL IND2-2  > MAX-IND2-2
BPO304                               OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)04890000
BPO304                                          NOT GREATER ZEROES      04890000
BPO304                             MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                                END-PERFORM                       04890000
                                      PERFORM R0055-INSERT-AMOVCC
                                         THRU R0055-INSERT-AMOVCC-END
                                   END-IF                               60000
BPO676                            END-IF                                60000
                                END-IF                                  60000
BPOA04*---------------------------------------------------------------
BPOA04*--- INSERISCO PRENOTATA PER ANTITERROSMO IN CASO DI------------
BPOA04*--- PRENOTATA SUL MOV 24 PER SPESE > IMP ----------------------
BPOA04*---------------------------------------------------------------
BPOA04                          IF OPE-CPCS = 0131
BPOA04                            PERFORM R0050-INSERISCI-PRENOTATA
BPOA04                               THRU R0050-INSERISCI-PRENOTATA-END
BPOA04                             IF GEPP-RETCODE = 'OK'
BPOA04                                INITIALIZE DCLTBAMOVCC
BPOA04                                MOVE W-CIST  TO MOVCC-CIST
BPOA04                                MOVE KEY1-MOVP-DIPOPE(IND1-1)
BPOA04                                             TO MOVCC-DIPOPE
BPOA04                                MOVE KEY1-MOVP-NUMOPE(IND1-1)
BPOA04                                             TO MOVCC-NUMOPE
BPOA04                                MOVE 23      TO MOVCC-NPRGMOVP
BPOA04                                MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPOA04                                             TO MOVCC-NSUBMOVP
BPOA04                                MOVE WRK-NUMPRECC
BPOA04                                          TO MOVCC-NUMPRECC
BPOA04                                MOVE WRK-SOMMA-SPESE2
BPOA04                                             TO MOVCC-IMPPRE
BPOA04                                MOVE ZEROES TO MOVCC-NUMOPECC
BPOA04                                PERFORM R0055-INSERT-AMOVCC
BPOA04                                   THRU R0055-INSERT-AMOVCC-END
BPOA04                            END-IF
BPOA04                          END-IF
                             END-IF                                     60000
                          END-IF                                        60000
                       ELSE
      *ERRORE, NON PUº ESSERE TIPOPE DIVERSO DA 1
                          MOVE 8                   TO W-FLAG-ERR        06260000
                          MOVE '9999'              TO W-COD-ERR         06270000
                          MOVE 'ZMBAGGCC'          TO L-MODULO          06300000
                          MOVE 'TIPOPE DIVERSO DA 1'                    06310000
                                               TO L-SUB-MODULO          06310000
                          MOVE 'RIVALO  '          TO L-NOME-TABELLA    06310000
                          PERFORM 9999-GESTIONE-ERRORE                  06320000
                             THRU 9999-GESTIONE-ERRORE-END              06330000
                          GO TO FINE                                    06340000
                       END-IF
                    ELSE                                                60000
      ****ACCREDITO CONTO CORRENTE
BPO999*SE IMP BONIFICO INFERIORE IMP SPESE E IN FASE DI RIVALORIZZ
BPO999*DIVENTA SUPERIORE RIMANE LA PRENOTATA SU AMOVCC
BPO999*BISOGNA MODIFICARE AMOVCC INVECE DI INSERIRE E ANNULLARE LA PREN
      *
                       IF OPE-DIPOPE = 311
                           MOVE 'DIREZ'    TO WRK-DIPEIMM
                       ELSE
                           MOVE '00000'          TO WRK-DIPEIMM
                           MOVE OPE-DIPOPE       TO WRK-VALORE
                           PERFORM NORMALIZZA-CDPZ
                              THRU NORMALIZZA-CDPZ-END
                           MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
                       END-IF
      *---CANALE DI TRASMISSIONE NON VALORIZZATO
                       IF OPE-CANTRASM NOT GREATER SPACES
                           MOVE 'ESTE'    TO WRK-TERMIMM
                           IF OPE-FLUSSOPRV = 'MOSAIC'
                              MOVE SPACES     TO WRK-COPERIM
                           ELSE
                              MOVE OPE-NMTRUTE TO WRK-COPERIM
                           END-IF
                       ELSE
      *---CANALE DI TRASMISSIONE VALORIZZATO ES BPIOL BPOL DORE ETC.
                           MOVE SPACES    TO WRK-COPERIM
MCN002***                  IF OPE-CANTRASM = 'DORE'
MCN002                     IF WRK-TIPO-CANALE = 'R'
                               MOVE 'BPOL' TO WRK-TERMIMM
IM0031                          IF WRK-FLG-GEST-2 = 'P'
IM0031                             MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                          END-IF
                           ELSE
MCN002***                      IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                         IF WRK-TIPO-CANALE = 'C'
                                  MOVE 'BPIO' TO WRK-TERMIMM
                               ELSE
                                  MOVE OPE-CANTRASM TO WRK-TERMIMM
                               END-IF
                           END-IF
                       END-IF
BPO893**********************************************************
BPO893*** INSERIMENTO DI AMOVCC VIENE EFFETTUATA CON IL    *****
BPO893*** NUMERO MOVIMENTO 23 (DARE) ANCHE SE IL MOVIMENTO *****
BPO893*** CHE STO TRATTANDO E' CON TIPO MOVIMENTO = 2      *****
BPO893*** CIOE' MOVIMENTO IN  AVERE (24)                   *****
BPO893*** QUESTO PER CREARE LA PRENOTATA IN DARE SU CPCS   *****
BPO893*** 131 ACCREDITO CON PRENOTATA PER ANTITERRORISMO   *****
BPO893**********************************************************
APE001*    DA QUI **********************************************
BPO893                 IF OPE-CPCS = 0131
BPO893                    IF KEY1-MOVP-TMOV (IND1-1) = 2
BPO893                       IF OPE-BCKFTIPOPE = 1
BPO893                          PERFORM R0050-INSERISCI-PRENOTATA
BPO893                             THRU R0050-INSERISCI-PRENOTATA-END
BPO893                          IF GEPP-RETCODE = 'OK'
BPO893                            INITIALIZE DCLTBAMOVCC
BPO893                            MOVE W-CIST        TO MOVCC-CIST
BPO893                            MOVE KEY1-MOVP-DIPOPE(IND1-1)
BPO893                                              TO MOVCC-DIPOPE
BPO893                            MOVE KEY1-MOVP-NUMOPE(IND1-1)
BPO893                                               TO MOVCC-NUMOPE
BPO893*                           MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
BPO893*                                            TO MOVCC-NPRGMOVP
BPO893                            MOVE 23          TO MOVCC-NPRGMOVP
BPO893                            MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO893                                            TO MOVCC-NSUBMOVP
BPO893                            MOVE WRK-NUMPRECC  TO MOVCC-NUMPRECC
BPO893                            MOVE WRK-SOMMA-SPESE2 TO MOVCC-IMPPRE
BPO893                            MOVE ZEROES        TO MOVCC-NUMOPECC
BPO893                            PERFORM R0055-INSERT-AMOVCC
BPO893                               THRU R0055-INSERT-AMOVCC-END
BPO893                         END-IF
BPO893                       ELSE
BPO893                         IF OPE-BCKFTIPOPE = 2
BPO893                            PERFORM R0060-ANNULLA-PRENOTATA
BPO893                               THRU R0060-ANNULLA-PRENOTATA-END
BPO893                            IF GEPP-RETCODE = 'OK'
BPO893                               INITIALIZE DCLTBAMOVCC
BPO893                               MOVE W-CIST    TO MOVCC-CIST
BPO893                               MOVE KEY1-MOVP-DIPOPE(IND1-1)
BPO893                                              TO MOVCC-DIPOPE
BPO893                               MOVE KEY1-MOVP-NUMOPE(IND1-1)
BPO893                                              TO MOVCC-NUMOPE
BPO893*                              MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
BPO893*                                             TO MOVCC-NPRGMOVP
BPO893                               MOVE 23        TO MOVCC-NPRGMOVP
BPO893                               MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO893                                              TO MOVCC-NSUBMOVP
BPO893                               MOVE ZEROES    TO MOVCC-NUMOPECC
BPO893                               MOVE ZEROES    TO MOVCC-NUMPRECC
BPO893                               MOVE ZEROES    TO MOVCC-IMPPRE
BPO893                               PERFORM R0080-UPDATE-AMOVCC
BPO893                                  THRU R0080-UPDATE-AMOVCC-END
BPO893                            END-IF
BPO893                         END-IF
BPO893                       END-IF
BPO893                    END-IF
BPO893                 END-IF
BPO893**********************************************************
BPO893*** ANNULLAMENTO DI AMOVCC IN CASO DI STORNO CPCS 131*****
BPO893**********************************************************
BPO893                 IF OPE-BCKFTIPOPE = 3  AND
BPO893                    OPE-CPCSORI  = 0131
BPO893                    MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO893                    MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPOA04*BPO893                    PERFORM R0060-ANNULLA-PRENOTATA
BPOA04*BPO893                       THRU R0060-ANNULLA-PRENOTATA-END
BPO893                    PERFORM R0060-ANNULLA-PREN-EURO
BPO893                       THRU R0060-ANNULLA-PREN-EURO-END
BPO893                    IF GEPP-RETCODE = 'OK'
BPO893                       INITIALIZE DCLTBAMOVCC
BPO893                       MOVE W-CIST    TO MOVCC-CIST
BPO893                       MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO893                       MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPO893                       MOVE 23        TO MOVCC-NPRGMOVP
BPO893                       MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO893                                     TO MOVCC-NSUBMOVP
BPO893                       MOVE ZEROES    TO MOVCC-NUMOPECC
BPO893                       MOVE ZEROES    TO MOVCC-NUMPRECC
BPO893                       MOVE ZEROES    TO MOVCC-IMPPRE
BPO893                       PERFORM R0080-UPDATE-AMOVCC
BPO893                          THRU R0080-UPDATE-AMOVCC-END
BPO893                   END-IF
BPO893                 END-IF
APE001*--- FINE SPOSTAMENTO ------------------------
                       PERFORM R0070-AGGIORNA-CC                           50000
                          THRU R0070-AGGIORNA-CC-END                       50000
                       IF SV2P-RETCODE EQUAL SPACES
                          INITIALIZE DCLTBAMOVCC
BPO304                    INITIALIZE W-TAB-MOVCC
                          MOVE W-CIST        TO MOVCC-CIST
                          MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                   TO MOVCC-DIPOPE
                          MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                   TO MOVCC-NUMOPE
                          MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                   TO MOVCC-NPRGMOVP
                          MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                   TO MOVCC-NSUBMOVP
                          MOVE SV2P-NUMMOVI  TO MOVCC-NUMOPECC
                          MOVE ZEROES        TO MOVCC-NUMPRECC
BPO168                    MOVE WRK-INCC-CATRAPP  TO MOVCC-CATRAPP
BPO168                    MOVE KEY1-MOVP-CODOPE(IND1-1)
BPO168                                                 TO MOVCC-CODOPE
BPO304*****SALVO LE CAUSALI
BPO304                    PERFORM VARYING IND1-2 FROM 1 BY 1            04880000
BPO304                      UNTIL IND1-2  > MAX-IND1-2
BPO304                         OR KEY1-MOVP-CAUSALE(IND1-1,IND1-2)      04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                         MOVE KEY1-MOVP-CAUSALE(IND1-1,IND1-2)
BPO304                                  TO W-MOVCC-CCAUBP(IND1-2)
BPO304                         MOVE KEY1-MOVP-CAUSALES(IND1-1,IND1-2)
BPO304                                  TO W-MOVCC-CCAUOP(IND1-2)
BPO304                         MOVE KEY1-MOVP-CSTCS(IND1-1,IND1-2)
BPO304                                  TO W-MOVCC-CSTC(IND1-2)
BPO304                    END-PERFORM                                   04890000
BPO304                    MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE
BPO304*                   MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE-TEXT
BPO999*ANOMALIA SE IMPORTO BON. ARR. MINORE  DELLE SPESE
BPO999*SE IN RIVALORIZZAZIONE DIVENTA MAGGIORE
BPO999*RECORD SU AMOVCC GIë PRESENTE PER IM PRENOTATO
BPO999*                   PERFORM R0055-INSERT-AMOVCC
BPO999*                      THRU R0055-INSERT-AMOVCC-END
BPO999                    PERFORM R0055-IN-UPD-AMOVCC
BPO999                       THRU R0055-IN-UPD-AMOVCC-END
                          IF IND2-1 GREATER ZEROES
BPO676                      IF OPE-CPCS = 1005 OR
BPO676                         (OPE-CPCS = 1011 AND
BPO676                          OPE-CPCSORI = 1005) OR
BPO676                         (OPE-CPCS = 1010 AND
BPO676                          OPE-CPCSORI = 1005)
BPO676                          NEXT SENTENCE
BPO676                      ELSE
                             PERFORM R0070-AGGIORNA-CSERV                  50000
                                THRU R0070-AGGIORNA-CSERV-END              50000
                             IF SV2P-RETCODE EQUAL SPACES
                                INITIALIZE DCLTBAMOVCC
BPO304                          INITIALIZE W-TAB-MOVCC
                                MOVE W-CIST        TO MOVCC-CIST
                                MOVE KEY2-MOVP-DIPOPE(IND2-1)
                                                        TO MOVCC-DIPOPE
                                MOVE KEY2-MOVP-NUMOPE(IND2-1)
                                                        TO MOVCC-NUMOPE
                                IF IND2-1 GREATER 1
                                   COMPUTE MOVCC-NPRGMOVP =
                                                        99 - IND2-1
                                ELSE
                                   MOVE 99     TO MOVCC-NPRGMOVP
                                END-IF
                                MOVE ZEROES        TO MOVCC-NSUBMOVP
                                MOVE SV2P-NUMMOVI  TO MOVCC-NUMOPECC
BPO168                          MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                          MOVE WRK-INCC-CATRAPP  TO MOVCC-CATRAPP
BPO304                          PERFORM VARYING IND2-2 FROM 1 BY 1      04880000
BPO304                            UNTIL IND2-2  > MAX-IND2-2
BPO304                               OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)04890000
BPO304                                         NOT GREATER ZEROES       04890000
BPO304                            MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                    TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                          END-PERFORM                             04890000
BPO304                          MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE
BPO304*                         MOVE W-TAB-MOVCC  TO MOVCC-WTABCOPE-TEXT
                                PERFORM R0055-INSERT-AMOVCC
                                   THRU R0055-INSERT-AMOVCC-END
                             END-IF                                     60000
BPO676                      END-IF                                      60000
                          END-IF                                        60000
                       END-IF                                                600
APE001*- A QUI -------------------------------------
                    END-IF                                              60000
      ****FASE DI ANNULLO PER BONIFICI IN USCITA NON RIVALORIZZATI
                    WHEN 'ANNUBU'
                       IF OPE-DIPOPE = 311
                          MOVE 'DIREZ'    TO WRK-DIPEIMM
                       ELSE
                          MOVE '00000'          TO WRK-DIPEIMM
                          MOVE OPE-DIPOPE       TO WRK-VALORE
                          PERFORM NORMALIZZA-CDPZ
                             THRU NORMALIZZA-CDPZ-END
                          MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
                       END-IF
      *--CANALE DI TRASMISSIONE NON VALORIZZATO
                       IF OPE-CANTRASM NOT GREATER SPACES
                          MOVE 'ESTE'    TO WRK-TERMIMM
      *                   IF OPE-FLUSSOPRV = 'MOSAIC'
      *                      MOVE SPACES     TO WRK-COPERIM
      *                   ELSE
                             MOVE OPE-NMTRUTE TO WRK-COPERIM
      *                   END-IF
                       ELSE
      *--CANALE DI TRASMISSIONE VALORIZZATO ES BIOL BPOL DORE ETC.
                          MOVE SPACES       TO WRK-COPERIM
MCN002***                 IF OPE-CANTRASM = 'DORE'
MCN002                    IF WRK-TIPO-CANALE = 'R'
                             MOVE 'BPOL' TO WRK-TERMIMM
IM0031                       IF WRK-FLG-GEST-2 = 'P'
IM0031                          MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                       END-IF
                          ELSE
MCN002***                    IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                       IF WRK-TIPO-CANALE = 'C'
                                MOVE 'BPIO' TO WRK-TERMIMM
                             ELSE
                                MOVE OPE-CANTRASM TO WRK-TERMIMM
                             END-IF
                          END-IF
                       END-IF
                       PERFORM R0060-ANNULLA-PRENOTATA                    50000
                          THRU R0060-ANNULLA-PRENOTATA-END                50000
                       IF GEPP-RETCODE = 'OK'
                          INITIALIZE DCLTBAMOVCC
                          MOVE W-CIST        TO MOVCC-CIST
                          MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                             TO MOVCC-DIPOPE
                          MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                             TO MOVCC-NUMOPE
                          MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                             TO MOVCC-NPRGMOVP
                          MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                             TO MOVCC-NSUBMOVP
                          MOVE ZEROES        TO MOVCC-NUMOPECC
                          MOVE ZEROES        TO MOVCC-NUMPRECC
                          MOVE ZEROES        TO MOVCC-IMPPRE
                          PERFORM R0080-UPDATE-AMOVCC
                             THRU R0080-UPDATE-AMOVCC-END
                       END-IF
      ****ANNUBE ANNULLA BONIFICI IN ENTRATA CHE NON CHIUDONO C/ATTESA
                    WHEN 'ANNUBE'
                       INITIALIZE DCLTBAMOVCC
                       MOVE W-CIST        TO MOVCC-CIST
                       MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                              TO MOVCC-DIPOPE
                       MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                              TO MOVCC-NUMOPE
                       MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                              TO MOVCC-NPRGMOVP
                       MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                              TO MOVCC-NSUBMOVP
                       PERFORM R0057-SELECT-AMOVCC
                          THRU R0057-SELECT-AMOVCC-END
                       IF W-SQL-OK
                          MOVE 'S' TO WRK-AGGIORNA-CC
                       ELSE
                          MOVE 'N' TO WRK-AGGIORNA-CC
                       END-IF
                       IF WRK-AGGIORNA-CC = 'S'
                          IF OPE-DIPOPE = 311
                             MOVE 'DIREZ'    TO WRK-DIPEIMM
                          ELSE
                             MOVE '00000'          TO WRK-DIPEIMM
                             MOVE OPE-DIPOPE       TO WRK-VALORE
                             PERFORM NORMALIZZA-CDPZ
                                THRU NORMALIZZA-CDPZ-END
                             MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
                          END-IF
      *--CANALE DI TRASMISSIONE NON VALORIZZATO
                          IF OPE-CANTRASM NOT GREATER SPACES
                              MOVE 'ESTE'    TO WRK-TERMIMM
      *                       IF OPE-FLUSSOPRV = 'MOSAIC'
      *                          MOVE SPACES     TO WRK-COPERIM
      *                       ELSE
                                 MOVE OPE-NMTRUTE TO WRK-COPERIM
      *                       END-IF
                          ELSE
      *--CANALE DI TRASMISSIONE VALORIZZATO ES BIOL BPOL DORE ETC.
                              MOVE SPACES       TO WRK-COPERIM
MCN002***                     IF OPE-CANTRASM = 'DORE'
MCN002                        IF WRK-TIPO-CANALE = 'R'
                                 MOVE 'BPOL' TO WRK-TERMIMM
IM0031                           IF WRK-FLG-GEST-2 = 'P'
IM0031                              MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                           END-IF
                              ELSE
MCN002***                        IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                           IF WRK-TIPO-CANALE = 'C'
                                    MOVE 'BPIO' TO WRK-TERMIMM
                                 ELSE
                                    MOVE OPE-CANTRASM TO WRK-TERMIMM
                                 END-IF
                              END-IF
                          END-IF
                          PERFORM R0060-ANNULLA-PRENOTATA                 50000
                             THRU R0060-ANNULLA-PRENOTATA-END             50000
                          IF GEPP-RETCODE = 'OK'
                             INITIALIZE DCLTBAMOVCC
                             MOVE W-CIST        TO MOVCC-CIST
                             MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                TO MOVCC-DIPOPE
                             MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                TO MOVCC-NUMOPE
                             MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                TO MOVCC-NPRGMOVP
                             MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                TO MOVCC-NSUBMOVP
                             MOVE ZEROES        TO MOVCC-NUMOPECC
                             MOVE ZEROES        TO MOVCC-NUMPRECC
                             MOVE ZEROES        TO MOVCC-IMPPRE
                             PERFORM R0080-UPDATE-AMOVCC
                                THRU R0080-UPDATE-AMOVCC-END
                          END-IF
                       END-IF
      ****ANNUES ANNULLA BONIFICI IN ENTRATA CHE CHIUDONO C/ATTESA
                    WHEN 'ANNUES'
                       INITIALIZE DCLTBAMOVCC
                       MOVE W-CIST        TO MOVCC-CIST
                       MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                              TO MOVCC-DIPOPE
                       MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                              TO MOVCC-NUMOPE
                       MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                              TO MOVCC-NPRGMOVP
                       MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                              TO MOVCC-NSUBMOVP
                       PERFORM R0057-SELECT-AMOVCC
                          THRU R0057-SELECT-AMOVCC-END
                       IF W-SQL-OK
                          MOVE 'S' TO WRK-AGGIORNA-CC
                       ELSE
                          MOVE 'N' TO WRK-AGGIORNA-CC
                       END-IF
                       IF WRK-AGGIORNA-CC = 'S'
                          IF OPE-DIPOPE = 311
                             MOVE 'DIREZ'    TO WRK-DIPEIMM
                          ELSE
                             MOVE '00000'          TO WRK-DIPEIMM
                             MOVE OPE-DIPOPE       TO WRK-VALORE
                             PERFORM NORMALIZZA-CDPZ
                                THRU NORMALIZZA-CDPZ-END
                             MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
                          END-IF
      *--CANALE DI TRASMISSIONE NON VALORIZZATO
                          IF OPE-CANTRASM NOT GREATER SPACES
                              MOVE 'ESTE'    TO WRK-TERMIMM
      *                       IF OPE-FLUSSOPRV = 'MOSAIC'
      *                          MOVE SPACES     TO WRK-COPERIM
      *                       ELSE
                                 MOVE OPE-NMTRUTE TO WRK-COPERIM
      *                       END-IF
                          ELSE
      *--CANALE DI TRASMISSIONE VALORIZZATO ES BIOL BPOL DORE ETC.
                              MOVE SPACES       TO WRK-COPERIM
MCN002***                     IF OPE-CANTRASM = 'DORE'
MCN002                        IF WRK-TIPO-CANALE = 'R'
                                 MOVE 'BPOL' TO WRK-TERMIMM
IM0031                           IF WRK-FLG-GEST-2 = 'P'
IM0031                              MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                           END-IF
                              ELSE
MCN002***                        IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                           IF WRK-TIPO-CANALE = 'C'
                                    MOVE 'BPIO' TO WRK-TERMIMM
                                 ELSE
                                    MOVE OPE-CANTRASM TO WRK-TERMIMM
                                 END-IF
                              END-IF
                          END-IF
                          PERFORM R0060-ANNULLA-PRENOTATA                 50000
                             THRU R0060-ANNULLA-PRENOTATA-END             50000
                          IF GEPP-RETCODE = 'OK'
                             INITIALIZE DCLTBAMOVCC
                             MOVE W-CIST        TO MOVCC-CIST
                             MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                TO MOVCC-DIPOPE
                             MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                TO MOVCC-NUMOPE
                             MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                TO MOVCC-NPRGMOVP
                             MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                TO MOVCC-NSUBMOVP
                             MOVE ZEROES        TO MOVCC-NUMOPECC
                             MOVE ZEROES        TO MOVCC-NUMPRECC
                             MOVE ZEROES        TO MOVCC-IMPPRE
                             PERFORM R0080-UPDATE-AMOVCC
                                THRU R0080-UPDATE-AMOVCC-END
                          END-IF
                       END-IF
                    WHEN OTHER
      *****COMPRENDE ANCHE IL MODULO A SPAZI
                       IF KEY1-MOVP-TMOV(IND1-1) = 1
                          OR  (KEY1-MOVP-TMOV(IND1-1) = 2      AND
                               KEY1-MOVP-FSPESE(IND1-1) = 'S')
      *****OPERAZIONE DI ADDEBITO DEL C/C
                          IF OPE-BCKFTIPOPE = 1
                             IF OPE-DIPOPE = 311
                                MOVE 'DIREZ'    TO WRK-DIPEIMM
                             ELSE
                                MOVE '00000'          TO WRK-DIPEIMM
                                MOVE OPE-DIPOPE       TO WRK-VALORE
                                PERFORM NORMALIZZA-CDPZ
                                   THRU NORMALIZZA-CDPZ-END
                                MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
                             END-IF
      *---CANALE DI TRASMISSIONE NON VALORIZZATO
                             IF OPE-CANTRASM NOT GREATER SPACES
                                 MOVE 'ESTE'    TO WRK-TERMIMM
      *                          IF OPE-FLUSSOPRV = 'MOSAIC'
      *                            MOVE SPACES     TO WRK-COPERIM
      *                          ELSE
                                   MOVE OPE-NMTRUTE TO WRK-COPERIM
      *                          END-IF
                             ELSE
      *---CANALE DI TRASMISSIONE VALORIZZATO ES. BPIOL, BPOL, DORE ETC.
                                 MOVE SPACES       TO WRK-COPERIM
MCN002***                        IF OPE-CANTRASM = 'DORE'
MCN002                           IF WRK-TIPO-CANALE = 'R'
                                    MOVE 'BPOL' TO WRK-TERMIMM
IM0031                              IF WRK-FLG-GEST-2 = 'P'
IM0031                                 MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                              END-IF
                                 ELSE
MCN002***                           IF OPE-CANTRASM = 'DOCO'
MCN002***                              OR 'DOCA'  OR 'DOCP'
MCN002***                              OR 'DOCM'
MCN002***                              OR 'DOTE'
MCN002                              IF WRK-TIPO-CANALE = 'C'
                                       MOVE 'BPIO' TO WRK-TERMIMM
                                    ELSE
                                       MOVE OPE-CANTRASM TO WRK-TERMIMM
                                    END-IF
                                 END-IF
                             END-IF
                             PERFORM R0050-INSERISCI-PRENOTATA          50000
                                THRU R0050-INSERISCI-PRENOTATA-END      50000
                             IF GEPP-RETCODE = 'OK'
                                INITIALIZE DCLTBAMOVCC
                                MOVE W-CIST        TO MOVCC-CIST
                                MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                   TO MOVCC-DIPOPE
                                MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                   TO MOVCC-NUMOPE
                                MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                   TO MOVCC-NPRGMOVP
                                MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                   TO MOVCC-NSUBMOVP
                                MOVE WRK-NUMPRECC  TO MOVCC-NUMPRECC
                                MOVE WRK-SOMMA-SPESE2 TO MOVCC-IMPPRE
                                MOVE ZEROES        TO MOVCC-NUMOPECC
                                PERFORM R0055-INSERT-AMOVCC
                                   THRU R0055-INSERT-AMOVCC-END
                             END-IF
                          ELSE                                          60000
      *****SE OPERAZIONE DI ANNULLO, SE NON E' RIVALORIZZAZ SI ANNULLA
      *****LA PRENOTAZIONE
                             IF OPE-BCKFTIPOPE = 2
      *SE ANNULLO DI OPERAZIONE NON RIVALORIZZATA ALLORA ANNULLO PRENOTA
      *ZIONE - SE ANNULLO DI OPE RIVALORIZZ AGGIORNAO I C/C
                                INITIALIZE DCLTBAMOVCC
                                MOVE W-CIST        TO MOVCC-CIST
                                MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                       TO MOVCC-DIPOPE
                                MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                       TO MOVCC-NUMOPE
                                MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                       TO MOVCC-NPRGMOVP
                                MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                       TO MOVCC-NSUBMOVP
                                PERFORM R0057-SELECT-AMOVCC
                                   THRU R0057-SELECT-AMOVCC-END
                                IF W-SQL-OK
                                   IF MOVCC-NUMPRECC = ZEROES AND
                                      MOVCC-NUMOPECC GREATER SPACES
                                      MOVE 'S' TO WRK-AGGIORNA-CC
                                   ELSE
                                      MOVE 'N' TO WRK-AGGIORNA-CC
                                   END-IF
                                END-IF
      *****ANNULLO DI OPERAZIONE DI ADDEBITO  NON RIVALORIZZATA
                                IF WRK-AGGIORNA-CC = 'N'
                                   IF OPE-DIPOPE = 311
                                      MOVE 'DIREZ'    TO WRK-DIPEIMM
                                   ELSE
                                    MOVE '00000'  TO WRK-DIPEIMM
                                    MOVE OPE-DIPOPE  TO WRK-VALORE
                                    PERFORM NORMALIZZA-CDPZ
                                       THRU NORMALIZZA-CDPZ-END
                                    MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
                                   END-IF
      *---CANALE DI TRASMISSIONE NON VALORIZZATO
                                   IF OPE-CANTRASM NOT GREATER SPACES
                                       MOVE 'ESTE'    TO WRK-TERMIMM
      *                                IF OPE-FLUSSOPRV = 'MOSAIC'
      *                                   MOVE SPACES     TO WRK-COPERIM
      *                                ELSE
                                         MOVE OPE-NMTRUTE TO WRK-COPERIM
      *                                END-IF
                                   ELSE
      *---CANALE DI TRASMISSIONE VALORIZZATO  ES. BPIOL BPOL DORE ETC
                                       MOVE SPACES       TO WRK-COPERIM
MCN002***                              IF OPE-CANTRASM = 'DORE'
MCN002                                 IF WRK-TIPO-CANALE = 'R'
                                          MOVE 'BPOL' TO WRK-TERMIMM
IM0031                                    IF WRK-FLG-GEST-2 = 'P'
IM0031                                     MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                                    END-IF
                                       ELSE
MCN002***                                 IF OPE-CANTRASM = 'DOCO'
MCN002***                                    OR 'DOCA'  OR 'DOCP'
MCN002***                                    OR 'DOCM'
MCN002***                                    OR 'DOTE'
MCN002                                    IF WRK-TIPO-CANALE = 'C'
                                             MOVE 'BPIO' TO WRK-TERMIMM
                                          ELSE
                                             MOVE OPE-CANTRASM
                                                         TO WRK-TERMIMM
                                          END-IF
                                       END-IF
                                    END-IF
                                   PERFORM R0060-ANNULLA-PRENOTATA      50000
                                      THRU R0060-ANNULLA-PRENOTATA-END  50000
                                   IF GEPP-RETCODE = 'OK'
                                      INITIALIZE DCLTBAMOVCC
                                      MOVE W-CIST        TO MOVCC-CIST
                                      MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                       TO MOVCC-DIPOPE
                                      MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                       TO MOVCC-NUMOPE
                                      MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                       TO MOVCC-NPRGMOVP
                                      MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                       TO MOVCC-NSUBMOVP
                                      MOVE ZEROES  TO MOVCC-NUMOPECC
                                      MOVE ZEROES   TO MOVCC-NUMPRECC
                                      MOVE ZEROES   TO MOVCC-IMPPRE
                                      PERFORM R0080-UPDATE-AMOVCC
                                         THRU R0080-UPDATE-AMOVCC-END
                                   END-IF
                                ELSE
      *****ANNULLO OPERAZIONE DI ADDEBITO RIVALORIZZATA
                                   IF OPE-DIPOPE = 311
                                      MOVE 'DIREZ'    TO WRK-DIPEIMM
                                   ELSE
                                      MOVE '00000'  TO WRK-DIPEIMM
                                      MOVE OPE-DIPOPE  TO WRK-VALORE
                                      PERFORM NORMALIZZA-CDPZ
                                         THRU NORMALIZZA-CDPZ-END
                                      MOVE WRK-NORMALE(1:5)
                                                        TO WRK-DIPEIMM
                                   END-IF
      *--CANALE DI TRASMISSIONE NON VALORZZATO
                                   IF OPE-CANTRASM NOT GREATER SPACES
                                       MOVE 'ESTE'    TO WRK-TERMIMM
                                       IF OPE-FLUSSOPRV = 'MOSAIC'
                                          MOVE SPACES     TO WRK-COPERIM
                                       ELSE
                                         MOVE OPE-NMTRUTE TO WRK-COPERIM
                                       END-IF
                                   ELSE
      *--CANALE DI TRASMISSIONE VALORZZATO ES BPIOL BPOL DORE ETC
                                       MOVE SPACES    TO WRK-COPERIM
MCN002***                              IF OPE-CANTRASM = 'DORE'
MCN002                                 IF WRK-TIPO-CANALE = 'R'
                                          MOVE 'BPOL' TO WRK-TERMIMM
IM0031                                    IF WRK-FLG-GEST-2 = 'P'
IM0031                                     MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                                    END-IF
                                       ELSE
MCN002***                                 IF OPE-CANTRASM = 'DOCO'
MCN002***                                    OR 'DOCA'  OR 'DOCP'
MCN002***                                    OR 'DOCM'
MCN002***                                    OR 'DOTE'
MCN002                                    IF WRK-TIPO-CANALE = 'C'
                                             MOVE 'BPIO' TO WRK-TERMIMM
                                          ELSE
                                             MOVE OPE-CANTRASM
                                                         TO WRK-TERMIMM
                                          END-IF
                                       END-IF
                                   END-IF
                                   PERFORM R0070-AGGIORNA-CC               50000
                                      THRU R0070-AGGIORNA-CC-END           50000
                                   IF SV2P-RETCODE EQUAL SPACES
                                      INITIALIZE DCLTBAMOVCC
BPO304                                INITIALIZE W-TAB-MOVCC
                                      MOVE W-CIST        TO MOVCC-CIST
                                      MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                      TO MOVCC-DIPOPE
                                      MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                      TO MOVCC-NUMOPE
                                      MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                      TO MOVCC-NPRGMOVP
                                      MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                      TO MOVCC-NSUBMOVP
BPO168                                MOVE KEY1-MOVP-CODOPE(IND1-1)
BPO168                                                TO MOVCC-CODOPE
                                      MOVE SV2P-NUMMOVI TO
                                                         MOVCC-NUMOPECC
BPO168                                MOVE WRK-INCC-CATRAPP
BPO168                                                  TO MOVCC-CATRAPP
BPO304*****SALVO LE CAUSALI
BPO304                            PERFORM VARYING IND2-2 FROM 1 BY 1    04880000
BPO304                                   UNTIL IND2-2  > MAX-IND2-2
BPO304                            OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)   04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                            END-PERFORM                           04890000
BPO304                                MOVE W-TAB-MOVCC
BPO304                                                TO MOVCC-WTABCOPE
BPO304*                                          TO MOVCC-WTABCOPE-TEXT
                                      MOVE ZEROES  TO MOVCC-NUMPRECC
                                      MOVE ZEROES  TO MOVCC-IMPPRE
                                      PERFORM R0080-UPDATE-AMOVCC
                                         THRU R0080-UPDATE-AMOVCC-END
                                      IF IND2-1 GREATER ZEROES
BPO676                                  IF OPE-CPCS = 1005 OR
BPO676                                    (OPE-CPCS = 1011 AND
BPO676                                     OPE-CPCSORI = 1005) OR
BPO676                                    (OPE-CPCS = 1010 AND
BPO676                                     OPE-CPCSORI = 1005)
BPO676                                     NEXT SENTENCE
BPO676                                  ELSE
                                         PERFORM R0070-AGGIORNA-CSERV      50000
                                           THRU R0070-AGGIORNA-CSERV-END   50000
                                         IF SV2P-RETCODE EQUAL SPACES
                                            INITIALIZE DCLTBAMOVCC
BPO304                                      INITIALIZE W-TAB-MOVCC
                                            MOVE W-CIST  TO MOVCC-CIST
                                           MOVE KEY2-MOVP-DIPOPE(IND2-1)
                                                        TO MOVCC-DIPOPE
                                           MOVE KEY2-MOVP-NUMOPE(IND2-1)
                                                        TO MOVCC-NUMOPE
                                            IF IND2-1 GREATER 1
                                               COMPUTE MOVCC-NPRGMOVP =
                                                            99 - IND2-1
                                            ELSE
                                              MOVE 99  TO MOVCC-NPRGMOVP
                                            END-IF
                                            MOVE ZEROES TO
                                                          MOVCC-NSUBMOVP
                                            MOVE SV2P-NUMMOVI
                                                      TO MOVCC-NUMOPECC
BPO168                                     MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                                     MOVE WRK-INCC-CATRAPP
BPO168                                                 TO MOVCC-CATRAPP
BPO304***SALVO LE CAUSALI
BPO304                            PERFORM VARYING IND2-2                04880000
BPO304                                                FROM 1 BY 1       04880000
BPO304                                       UNTIL IND2-2  > MAX-IND2-2
BPO304                            OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)   04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                    TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                                      END-PERFORM                 04890000
BPO304****FINE PERFORM
BPO304                                    MOVE W-TAB-MOVCC
BPO304                                                TO MOVCC-WTABCOPE
BPO304*                                          TO MOVCC-WTABCOPE-TEXT
                                            PERFORM R0080-UPDATE-AMOVCC
                                            THRU R0080-UPDATE-AMOVCC-END
                                         END-IF                         60000
BPO676                                  END-IF                          60000
                                      END-IF                            60000
                                   END-IF                                    600
                               END-IF
                             ELSE
BPO893*SE STORNO DI OPERAZIONE RIVALORIZZATA STORNO ANCHE PRENOTATA
BPO893                           IF OPE-BCKFTIPOPE = 3  AND
BPO893                              OPE-CPCSORI  = 0131
BPO893                              PERFORM ANNULLA-PREN-ANT
BPO893                                 THRU ANNULLA-PREN-ANT-END
BPO893                           END-IF
      *SE STORNO DI OPERAZIONE RIVALORIZZATA ADDEBITO DIRETTAMENTE I C/C
                                 IF OPE-DIPOPE = 311
                                    MOVE 'DIREZ'    TO WRK-DIPEIMM
                                 ELSE
                                    MOVE '00000'  TO WRK-DIPEIMM
                                    MOVE OPE-DIPOPE  TO WRK-VALORE
                                    PERFORM NORMALIZZA-CDPZ
                                      THRU NORMALIZZA-CDPZ-END
                                   MOVE WRK-NORMALE(1:5)
                                                        TO WRK-DIPEIMM
                                END-IF
      *---CANALE DI TRASMISSIONE NON VALORIZZATO
                                IF OPE-CANTRASM NOT GREATER SPACES
                                    MOVE 'ESTE'    TO WRK-TERMIMM
                                    IF OPE-FLUSSOPRV = 'MOSAIC'
                                       MOVE SPACES     TO WRK-COPERIM
                                    ELSE
                                      MOVE OPE-NMTRUTE TO WRK-COPERIM
                                    END-IF
                                ELSE
      *---CANALE DI TRASMISSIONE VALORIZZATO ES BPIOL BPOL DORE ETC
                                    MOVE SPACES    TO WRK-COPERIM
MCN002***                           IF OPE-CANTRASM = 'DORE'
MCN002                              IF WRK-TIPO-CANALE = 'R'
                                       MOVE 'BPOL' TO WRK-TERMIMM
IM0031                                 IF WRK-FLG-GEST-2 = 'P'
IM0031                                    MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                                 END-IF
                                    ELSE
MCN002***                              IF OPE-CANTRASM = 'DOCO'
MCN002***                                 OR 'DOCA'  OR 'DOCP'
MCN002***                                 OR 'DOCM'
MCN002***                                 OR 'DOTE'
MCN002                                 IF WRK-TIPO-CANALE = 'C'
                                          MOVE 'BPIO' TO WRK-TERMIMM
                                       ELSE
                                          MOVE OPE-CANTRASM
                                                         TO WRK-TERMIMM
                                       END-IF
                                    END-IF
                                END-IF
                                PERFORM R0070-AGGIORNA-CC                  50000
                                   THRU R0070-AGGIORNA-CC-END              50000
                                IF SV2P-RETCODE EQUAL SPACES
                                   INITIALIZE DCLTBAMOVCC
BPO304                             INITIALIZE W-TAB-MOVCC
                                   MOVE W-CIST  TO MOVCC-CIST
                                   MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                      TO MOVCC-DIPOPE
                                   MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                      TO MOVCC-NUMOPE
                                   MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                      TO MOVCC-NPRGMOVP
                                   MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                      TO MOVCC-NSUBMOVP
                                   MOVE SV2P-NUMMOVI  TO MOVCC-NUMOPECC
                                   MOVE ZEROES        TO MOVCC-NUMPRECC
BPO168                             MOVE KEY1-MOVP-CODOPE(IND1-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                             MOVE WRK-INCC-CATRAPP
BPO168                                                  TO MOVCC-CATRAPP
BPO304*****SALVO LE CAUSALI
BPO304                             PERFORM VARYING IND1-2 FROM 1 BY 1   04880000
BPO304                               UNTIL IND1-2  > MAX-IND1-2
BPO304                               OR KEY1-MOVP-CAUSALE(IND1-1,IND1-2)04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY1-MOVP-CAUSALE(IND1-1,IND1-2)
BPO304                                     TO W-MOVCC-CCAUBP(IND1-2)
BPO304                            MOVE KEY1-MOVP-CAUSALES(IND1-1,IND1-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND1-2)
BPO304                            MOVE KEY1-MOVP-CSTCS(IND1-1,IND1-2)
BPO304                                  TO W-MOVCC-CSTC(IND1-2)
BPO304                             END-PERFORM                          04890000
BPO304                             MOVE W-TAB-MOVCC
BPO304                                                TO MOVCC-WTABCOPE
BPO304*                                         TO MOVCC-WTABCOPE-TEXT
                                   PERFORM R0055-INSERT-AMOVCC
                                      THRU R0055-INSERT-AMOVCC-END
                                   IF IND2-1 GREATER ZEROES
BPO676                               IF OPE-CPCS = 1005  OR
BPO676                                 (OPE-CPCS = 1011 AND
BPO676                                  OPE-CPCSORI = 1005) OR
BPO676                                 (OPE-CPCS = 1010 AND
BPO676                                  OPE-CPCSORI = 1005)
BPO676                                  NEXT SENTENCE
BPO676                               ELSE
                                      PERFORM R0070-AGGIORNA-CSERV         50000
                                         THRU R0070-AGGIORNA-CSERV-END     50000
                                      IF SV2P-RETCODE EQUAL SPACES
                                         INITIALIZE DCLTBAMOVCC
BPO304                                   INITIALIZE W-TAB-MOVCC
                                         MOVE W-CIST  TO MOVCC-CIST
                                         MOVE KEY2-MOVP-DIPOPE(IND2-1)
                                                        TO MOVCC-DIPOPE
                                         MOVE KEY2-MOVP-NUMOPE(IND2-1)
                                                        TO MOVCC-NUMOPE
                                         IF IND2-1 GREATER 1
                                            COMPUTE MOVCC-NPRGMOVP =
                                                            99 - IND2-1
                                         ELSE
                                            MOVE 99  TO MOVCC-NPRGMOVP
                                         END-IF
                                         MOVE ZEROES  TO MOVCC-NSUBMOVP
                                         MOVE SV2P-NUMMOVI
                                                      TO MOVCC-NUMOPECC
BPO168                                   MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                                   MOVE WRK-INCC-CATRAPP
BPO168                                                 TO MOVCC-CATRAPP
BPO304***SALVO LE CAUSALI
BPO304                            PERFORM VARYING IND2-2                04880000
BPO304                                                FROM 1 BY 1       04880000
BPO304                            UNTIL IND2-2  > MAX-IND2-2
BPO304                            OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)   04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                    TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                            END-PERFORM                           04890000
BPO304****FINE PERFORM
BPO304                                   MOVE W-TAB-MOVCC
BPO304                                                TO MOVCC-WTABCOPE
BPO304*                                        TO MOVCC-WTABCOPE-TEXT
                                         PERFORM R0055-INSERT-AMOVCC
                                            THRU R0055-INSERT-AMOVCC-END
                                      END-IF                            60000
BPO676                               END-IF                             60000
                                   END-IF                               60000
                                END-IF                                       600
                             END-IF
                          END-IF                                        60000
                       ELSE                                             60000
      * OPERAZIONE DI STORNO RIVALORIZZATA ACCREDITO
      *DIRETTMENTE IL C/C
                          IF OPE-BCKFTIPOPE = 3
BPO905                       INITIALIZE DCLTBAMOVCC
BPO905                       MOVE W-CIST        TO MOVCC-CIST
BPO905                       MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO905                       MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPO905*                      MOVE KEY1-MOVP-DIPOPE(IND1-1)
BPO905*                                             TO MOVCC-DIPOPE
BPO905*                      MOVE KEY1-MOVP-NUMOPE(IND1-1)
BPO905*                                             TO MOVCC-NUMOPE
BPO905                       MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
BPO905                                              TO MOVCC-NPRGMOVP
BPO905                       MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO905                                              TO MOVCC-NSUBMOVP
BPO905                       PERFORM R0057-SELECT-AMOVCC
BPO905                          THRU R0057-SELECT-AMOVCC-END
BPO905                       IF W-SQL-OK
BPO905                          IF MOVCC-NUMPRECC = ZEROES AND
BPO905                             MOVCC-NUMOPECC GREATER SPACES
BPO905                             MOVE 'S' TO WRK-AGGIORNA-CC
BPO905                          ELSE
BPO905                             MOVE 'N' TO WRK-AGGIORNA-CC
BPO905                          END-IF
BPO905                       END-IF
BPO905*****ANNULLO DI OPERAZIONE DI ADDEBITO  NON RIVALORIZZATA
BPO905                       IF WRK-AGGIORNA-CC = 'N'
BPO905                          IF OPE-DIPOPE = 311
BPO905                             MOVE 'DIREZ'    TO WRK-DIPEIMM
BPO905                          ELSE
BPO905                             MOVE '00000'  TO WRK-DIPEIMM
BPO905                             MOVE OPE-DIPOPE  TO WRK-VALORE
BPO905                             PERFORM NORMALIZZA-CDPZ
BPO905                                THRU NORMALIZZA-CDPZ-END
BPO905                             MOVE WRK-NORMALE(1:5) TO WRK-DIPEIMM
BPO905                          END-IF
BPO905*---CANALE DI TRASMISSIONE NON VALORIZZATO
BPO905                          IF OPE-CANTRASM NOT GREATER SPACES
BPO905                                 MOVE 'ESTE'    TO WRK-TERMIMM
BPO905                                 MOVE OPE-NMTRUTE TO WRK-COPERIM
BPO905                          ELSE
BPO905*---CANALE DI TRASMISSIONE VALORIZZATO  ES. BPIOL BPOL DORE ETC
BPO905                              MOVE SPACES       TO WRK-COPERIM
MCN002***                           IF OPE-CANTRASM = 'DORE'
MCN002                              IF WRK-TIPO-CANALE = 'R'
BPO905                                 MOVE 'BPOL' TO WRK-TERMIMM
IM0031                                 IF WRK-FLG-GEST-2 = 'P'
IM0031                                    MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                                 END-IF
BPO905                              ELSE
MCN002***                              IF OPE-CANTRASM = 'DOCO'
MCN002***                                 OR 'DOCA'  OR 'DOCP'
MCN002***                                    OR 'DOCM'
MCN002***                                    OR 'DOTE'
MCN002                                 IF WRK-TIPO-CANALE = 'C'
BPO905                                    MOVE 'BPIO' TO WRK-TERMIMM
BPO905                                 ELSE
BPO905                                    MOVE OPE-CANTRASM
BPO905                                                TO WRK-TERMIMM
BPO905                                 END-IF
BPO905                              END-IF
BPO905                           END-IF
BPO905                           PERFORM R0060-ANNULLA-PRENOTATA        50000
BPO905                                THRU R0060-ANNULLA-PRENOTATA-END  50000
BPO905                           IF GEPP-RETCODE = 'OK'
BPO905                              INITIALIZE DCLTBAMOVCC
BPO905                              MOVE W-CIST        TO MOVCC-CIST
BPO905                              MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO905                              MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPO905*                             MOVE KEY1-MOVP-DIPOPE(IND1-1)
BPO905*                                              TO MOVCC-DIPOPE
BPO905*                             MOVE KEY1-MOVP-NUMOPE(IND1-1)
BPO905*                                              TO MOVCC-NUMOPE
BPO905                              MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
BPO905                                               TO MOVCC-NPRGMOVP
BPO905                              MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO905                                               TO MOVCC-NSUBMOVP
BPO905                              MOVE ZEROES  TO MOVCC-NUMOPECC
BPO905                              MOVE ZEROES   TO MOVCC-NUMPRECC
BPO905                              MOVE ZEROES   TO MOVCC-IMPPRE
BPO905                              PERFORM R0080-UPDATE-AMOVCC
BPO905                                 THRU R0080-UPDATE-AMOVCC-END
BPO905                           END-IF
BPO905                       ELSE
                             IF OPE-DIPOPE = 311
                                MOVE 'DIREZ'    TO WRK-DIPEIMM
                             ELSE
                                MOVE '00000'  TO WRK-DIPEIMM
                                MOVE OPE-DIPOPE  TO WRK-VALORE
                                PERFORM NORMALIZZA-CDPZ
                                   THRU NORMALIZZA-CDPZ-END
                               MOVE WRK-NORMALE(1:5)   TO WRK-DIPEIMM
                             END-IF
      *--CANALE DI TRASMISSIONE NON VALORIZZATO
                             IF OPE-CANTRASM NOT GREATER SPACES
                                 MOVE 'ESTE'    TO WRK-TERMIMM
      *                          IF OPE-FLUSSOPRV = 'MOSAIC'
      *                             MOVE SPACES     TO WRK-COPERIM
      *                          ELSE
                                    MOVE OPE-NMTRUTE TO WRK-COPERIM
      *                          END-IF
                             ELSE
      *--CANALE DI TRASMISSIONE VALORIZZATO ES BPIOL BPOL DORE ETC
                                 MOVE SPACES    TO WRK-COPERIM
MCN002***                        IF OPE-CANTRASM = 'DORE'
MCN002                           IF WRK-TIPO-CANALE = 'R'
                                    MOVE 'BPOL' TO WRK-TERMIMM
IM0031                              IF WRK-FLG-GEST-2 = 'P'
IM0031                                 MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                              END-IF
                                 ELSE
MCN002***                           IF OPE-CANTRASM = 'DOCO'
MCN002***                              OR 'DOCA'  OR 'DOCP'
MCN002***                              OR 'DOCM'
MCN002***                              OR 'DOTE'
MCN002                              IF WRK-TIPO-CANALE = 'C'
                                       MOVE 'BPIO' TO WRK-TERMIMM
                                    ELSE
                                       MOVE OPE-CANTRASM
                                                        TO WRK-TERMIMM
                                    END-IF
                                 END-IF
                             END-IF
                             PERFORM R0070-AGGIORNA-CC                     50000
                                THRU R0070-AGGIORNA-CC-END                 50000
                             IF SV2P-RETCODE EQUAL SPACES
                                INITIALIZE DCLTBAMOVCC
BPO340                          INITIALIZE W-TAB-MOVCC
                                MOVE W-CIST  TO MOVCC-CIST
                                MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                      TO MOVCC-DIPOPE
                                MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                      TO MOVCC-NUMOPE
                                MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                     TO MOVCC-NPRGMOVP
                                MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                      TO MOVCC-NSUBMOVP
                                MOVE SV2P-NUMMOVI  TO MOVCC-NUMOPECC
                                MOVE ZEROES        TO MOVCC-NUMPRECC
BPO168                          MOVE KEY1-MOVP-CODOPE(IND1-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                          MOVE WRK-INCC-CATRAPP   TO MOVCC-CATRAPP
BPO304                          PERFORM VARYING IND1-2 FROM 1 BY 1      04880000
BPO304                            UNTIL IND1-2  > MAX-IND1-2
BPO304                           OR KEY1-MOVP-CAUSALE(IND1-1,IND1-2)    04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                           MOVE KEY1-MOVP-CAUSALE(IND1-1,IND1-2)
BPO304                                     TO W-MOVCC-CCAUBP(IND1-2)
BPO304                           MOVE KEY1-MOVP-CAUSALES(IND1-1,IND1-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND1-2)
BPO304                           MOVE KEY1-MOVP-CSTCS(IND1-1,IND1-2)
BPO304                                  TO W-MOVCC-CSTC(IND1-2)
BPO304                          END-PERFORM                             04890000
BPO304                          MOVE W-TAB-MOVCC
BPO304                                                TO MOVCC-WTABCOPE
BPO304*                                         TO MOVCC-WTABCOPE-TEXT
                                PERFORM R0055-INSERT-AMOVCC
                                   THRU R0055-INSERT-AMOVCC-END
                                IF IND2-1 GREATER ZEROES
BPO742*BPO676                     IF OPE-CPCS NOT = 1005 OR
BPO742                            IF OPE-CPCS = 1005 OR
BPO676                              (OPE-CPCS = 1011 AND
BPO676                               OPE-CPCSORI = 1005) OR
BPO676                              (OPE-CPCS = 1010 AND
BPO676                               OPE-CPCSORI = 1005)
BPO676                               NEXT SENTENCE
BPO676                            ELSE
                                   PERFORM R0070-AGGIORNA-CSERV            50000
                                      THRU R0070-AGGIORNA-CSERV-END        50000
                                   IF SV2P-RETCODE EQUAL SPACES
                                      INITIALIZE DCLTBAMOVCC
BPO304                                INITIALIZE W-TAB-MOVCC
                                      MOVE W-CIST  TO MOVCC-CIST
                                      MOVE KEY2-MOVP-DIPOPE(IND2-1)
                                                        TO MOVCC-DIPOPE
                                      MOVE KEY2-MOVP-NUMOPE(IND2-1)
                                                        TO MOVCC-NUMOPE
                                      IF IND2-1 GREATER 1
                                            COMPUTE MOVCC-NPRGMOVP =
                                                            99 - IND2-1
                                      ELSE
                                            MOVE 99  TO MOVCC-NPRGMOVP
                                      END-IF
                                      MOVE ZEROES  TO MOVCC-NSUBMOVP
                                      MOVE SV2P-NUMMOVI
                                                      TO MOVCC-NUMOPECC
BPO168                                MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                                MOVE WRK-INCC-CATRAPP
BPO168                                                 TO MOVCC-CATRAPP
BPO304***SALVO LE CAUSALI
BPO304                            PERFORM VARYING IND2-2                04880000
BPO304                                                FROM 1 BY 1       04880000
BPO304                                   UNTIL IND2-2  > MAX-IND2-2 OR
BPO304                                  KEY1-MOVP-CAUSALE(IND2-1,IND2-2)04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                    TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                            END-PERFORM                           04890000
BPO304****FINE PERFORM
BPO304                                MOVE W-TAB-MOVCC
BPO304                                                TO MOVCC-WTABCOPE
BPO304*                                         TO MOVCC-WTABCOPE-TEXT
                                      PERFORM R0055-INSERT-AMOVCC
                                         THRU R0055-INSERT-AMOVCC-END
                                   END-IF                               60000
BPO676                            END-IF                                60000
                                END-IF                                  60000
                             END-IF                                          600
                          ELSE
BPOA04*BPO893                      IF OPE-BCKFTIPOPE = 2  AND
BPOA04*BPO893*                         OPE-CPCS = 131
BPOA04*BPO893                          IF OPE-DIPOPE = 311
BPOA04*BPO893                         MOVE 'DIREZ'    TO WRK-DIPEIMM
BPOA04*BPO893                          ELSE
BPOA04*BPO893                             MOVE '00000'  TO WRK-DIPEIMM
BPOA04*BPO893                            MOVE OPE-DIPOPE  TO WRK-VALORE
BPOA04*BPO893                             PERFORM NORMALIZZA-CDPZ
BPOA04*BPO893                                THRU NORMALIZZA-CDPZ-END
BPOA04*BPO893                    MOVE WRK-NORMALE(1:5)  TO WRK-DIPEIMM
BPOA04*BPO893                          END-IF
BPOA04*BPO893*----CANALE DI TRASMISSIONE NON VALORIZZATO
BPOA04*BPO893                        IF OPE-CANTRASM NOT GREATER SPACES
BPOA04*BPO893                             MOVE 'ESTE'    TO WRK-TERMIMM
BPOA04*BPO893                             IF OPE-FLUSSOPRV = 'MOSAIC'
BPOA04*BPO893                           MOVE SPACES     TO WRK-COPERIM
BPOA04*BPO893                             ELSE
BPOA04*BPO893                            MOVE OPE-NMTRUTE TO WRK-COPERIM
BPOA04*BPO893                            END-IF
BPOA04*BPO893                          ELSE
BPOA04*BPO893*----CANALE DI TRASM VALORIZZATO ES. BPIOL BPOL DORE ETC
BPOA04*BPO893                             MOVE SPACES    TO WRK-COPERIM
BPOA04*MCN002***                          IF OPE-CANTRASM = 'DORE'
BPOA04*MCN002                             IF WRK-TIPO-CANALE = 'R'
BPOA04*BPO893                                MOVE 'BPOL' TO WRK-TERMIMM
BPOA04*BPO893                             ELSE
BPOA04*MCN002***                            IF OPE-CANTRASM = 'DOCO'
BPOA04*MCN002***                                  OR 'DOCA'  OR 'DOCP'
BPOA04*MCN002***                                  OR 'DOCM'
BPOA04*MCN002***                                 OR 'DOTE'
BPOA04*MCN002                               IF WRK-TIPO-CANALE = 'C'
BPOA04*BPO893                            MOVE 'BPIO' TO WRK-TERMIMM
BPOA04*BPO893                               ELSE
BPOA04*BPO893                    MOVE OPE-CANTRASM TO WRK-TERMIMM
BPOA04*BPO893                               END-IF
BPOA04*BPO893                             END-IF
BPOA04*BPO893                          END-IF
BPOA04*BPO893                          PERFORM R0060-ANNULLA-PRENOTATA
BPOA04*BPO893                        THRU R0060-ANNULLA-PRENOTATA-END
BPOA04*BPO893                          IF GEPP-RETCODE = 'OK'
BPOA04*BPO893                             INITIALIZE DCLTBAMOVCC
BPOA04*BPO893                             MOVE W-CIST    TO MOVCC-CIST
BPOA04*BPO893                             MOVE KEY1-MOVP-DIPOPE(IND1-1)
BPOA04*BPO893                                            TO MOVCC-DIPOPE
BPOA04*BPO893                             MOVE KEY1-MOVP-NUMOPE(IND1-1)
BPOA04*BPO893                                            TO MOVCC-NUMOPE
BPOA04*BPO893*                         MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
BPOA04*BPO893*                                         TO MOVCC-NPRGMOVP
BPOA04*BPO893                        MOVE 23        TO MOVCC-NPRGMOVP
BPOA04*BPO893                         MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPOA04*BPO893                                      TO MOVCC-NSUBMOVP
BPOA04*BPO893                         MOVE ZEROES    TO MOVCC-NUMOPECC
BPOA04*BPO893                         MOVE ZEROES    TO MOVCC-NUMPRECC
BPOA04*BPO893                         MOVE ZEROES    TO MOVCC-IMPPRE
BPOA04*BPO893                         PERFORM R0080-UPDATE-AMOVCC
BPOA04*BPO893                             THRU R0080-UPDATE-AMOVCC-END
BPOA04*BPO893                          END-IF
BPOA04*BPO893                      END-IF
                             IF OPE-BCKFTIPOPE = 2
      *ANNULLO OPERAZIONE ACCREDITO SOSPESA - SE NON RIVALORIZZATA
      *NEXT SENTENCE - SE RIVALORIZZATA ACCREDITO DIRETTAMENTE C/C
                                INITIALIZE DCLTBAMOVCC
                                MOVE W-CIST        TO MOVCC-CIST
                                MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                       TO MOVCC-DIPOPE
                                MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                       TO MOVCC-NUMOPE
                                MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                       TO MOVCC-NPRGMOVP
                                MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                       TO MOVCC-NSUBMOVP
                                PERFORM R0057-SELECT-AMOVCC
                                   THRU R0057-SELECT-AMOVCC-END
                                IF W-SQL-OK
                                   IF MOVCC-NUMPRECC = ZEROES AND
                                      MOVCC-NUMOPECC GREATER SPACES
                                      MOVE 'S' TO WRK-AGGIORNA-CC
                                   ELSE
                                      MOVE 'N' TO WRK-AGGIORNA-CC
                                   END-IF
                                ELSE
                                   MOVE 'N' TO WRK-AGGIORNA-CC
                                END-IF
                             END-IF
                             IF OPE-BCKFTIPOPE = 2
                                AND WRK-AGGIORNA-CC = 'S'
      ***********ANNULLO OPERAZIONE DI ACCREDITO RIVALORIZZATA
                                IF OPE-DIPOPE = 311
                                   MOVE 'DIREZ'    TO WRK-DIPEIMM
                                ELSE
                                   MOVE '00000'  TO WRK-DIPEIMM
                                   MOVE OPE-DIPOPE  TO WRK-VALORE
                                   PERFORM NORMALIZZA-CDPZ
                                      THRU NORMALIZZA-CDPZ-END
                                   MOVE WRK-NORMALE(1:5)
                                                        TO WRK-DIPEIMM
                                END-IF
      *--CANALE DI TRASMISSIONE NON VALORIZZATO
                                IF OPE-CANTRASM NOT GREATER SPACES
                                    MOVE 'ESTE'    TO WRK-TERMIMM
                                    IF OPE-FLUSSOPRV = 'MOSAIC'
                                       MOVE SPACES     TO WRK-COPERIM
                                    ELSE
                                       MOVE OPE-NMTRUTE TO WRK-COPERIM
                                    END-IF
                                ELSE
      *--CANALE DI TRASMISSIONE VALORIZZATO CON BPIOL BPOL DURE ETC
                                    MOVE SPACES    TO WRK-COPERIM
MCN002***                           IF OPE-CANTRASM = 'DORE'
MCN002                              IF WRK-TIPO-CANALE = 'R'
                                       MOVE 'BPOL' TO WRK-TERMIMM
IM0031                                 IF WRK-FLG-GEST-2 = 'P'
IM0031                                    MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                                 END-IF
                                    ELSE
MCN002***                              IF OPE-CANTRASM = 'DOCO'
MCN002***                                 OR 'DOCA'  OR 'DOCP'
MCN002***                                 OR 'DOCM'
MCN002***                                 OR 'DOTE'
MCN002                                 IF WRK-TIPO-CANALE = 'C'
                                          MOVE 'BPIO' TO WRK-TERMIMM
                                       ELSE
                                          MOVE OPE-CANTRASM
                                                        TO WRK-TERMIMM
                                       END-IF
                                    END-IF
                                END-IF
TEST1
                                PERFORM R0070-AGGIORNA-CC               50000
                                   THRU R0070-AGGIORNA-CC-END           50000
                                IF SV2P-RETCODE EQUAL SPACES
                                   INITIALIZE DCLTBAMOVCC
BPO304                             INITIALIZE W-TAB-MOVCC
                                   MOVE W-CIST  TO MOVCC-CIST
                                   MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                   TO MOVCC-DIPOPE
                                   MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                   TO MOVCC-NUMOPE
                                   MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                   TO MOVCC-NPRGMOVP
                                   MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                   TO MOVCC-NSUBMOVP
                                   MOVE SV2P-NUMMOVI TO
                                                      MOVCC-NUMOPECC
BPO168                             MOVE KEY1-MOVP-CODOPE(IND1-1)
BPO168                                                TO MOVCC-CODOPE
BPO168                             MOVE WRK-INCC-CATRAPP
BPO168                                                  TO MOVCC-CATRAPP
                                   MOVE ZEROES  TO MOVCC-NUMPRECC
                                   MOVE ZEROES  TO MOVCC-IMPPRE
BPO304                            PERFORM VARYING IND1-2 FROM 1 BY 1    04880000
BPO304                               UNTIL IND1-2  > MAX-IND1-2
BPO304                            OR KEY1-MOVP-CAUSALE(IND1-1,IND1-2)   04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY1-MOVP-CAUSALE(IND1-1,IND1-2)
BPO304                                     TO W-MOVCC-CCAUBP(IND1-2)
BPO304                            MOVE KEY1-MOVP-CAUSALES(IND1-1,IND1-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND1-2)
BPO304                            MOVE KEY1-MOVP-CSTCS(IND1-1,IND1-2)
BPO304                                   TO W-MOVCC-CSTC(IND1-2)
BPO304                             END-PERFORM                          04890000
BPO304                             MOVE W-TAB-MOVCC
BPO304                                                TO MOVCC-WTABCOPE
BPO304*                                         TO MOVCC-WTABCOPE-TEXT
                                   PERFORM R0080-UPDATE-AMOVCC
                                      THRU R0080-UPDATE-AMOVCC-END
                                   IF IND2-1 GREATER ZEROES
BPO676                               IF OPE-CPCS = 1005 OR
BPO676                                 (OPE-CPCS = 1011 AND
BPO676                                  OPE-CPCSORI = 1005) OR
BPO676                                 (OPE-CPCS = 1010 AND
BPO676                                  OPE-CPCSORI = 1005)
BPO676                                  NEXT SENTENCE
BPO676                               ELSE
                                      PERFORM R0070-AGGIORNA-CSERV      50000
                                        THRU R0070-AGGIORNA-CSERV-END   50000
                                      IF SV2P-RETCODE EQUAL SPACES
                                         INITIALIZE DCLTBAMOVCC
BPO304                                   INITIALIZE W-TAB-MOVCC
                                         MOVE W-CIST  TO MOVCC-CIST
                                         MOVE KEY2-MOVP-DIPOPE(IND2-1)
                                                        TO MOVCC-DIPOPE
                                         MOVE KEY2-MOVP-NUMOPE(IND2-1)
                                                     TO MOVCC-NUMOPE
BPO168                                   MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                               TO MOVCC-CODOPE
                                         IF IND2-1 GREATER 1
                                            COMPUTE MOVCC-NPRGMOVP =
                                                         99 - IND2-1
                                         ELSE
                                           MOVE 99  TO MOVCC-NPRGMOVP
                                         END-IF
                                         MOVE ZEROES TO
                                                       MOVCC-NSUBMOVP
                                         MOVE SV2P-NUMMOVI
                                                   TO MOVCC-NUMOPECC
BPO168                                   MOVE WRK-INCC-CATRAPP
BPO168                                                 TO MOVCC-CATRAPP
BPO304***SALVO LE CAUSALI
BPO304                            PERFORM VARYING IND2-2                04880000
BPO304                                                FROM 1 BY 1       04880000
BPO304                            UNTIL IND2-2  > MAX-IND2-2
BPO304                              OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2) 04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                    TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                            END-PERFORM                           04890000
BPO304                                   MOVE W-TAB-MOVCC
BPO304                                                TO MOVCC-WTABCOPE
BPO304*                                          TO MOVCC-WTABCOPE-TEXT
                                         PERFORM R0080-UPDATE-AMOVCC
                                            THRU R0080-UPDATE-AMOVCC-END
                                      END-IF                            00
BPO676                               END-IF                             00
                                   END-IF                               00
                                END-IF                                    600
                             END-IF                                       600
QUA                       END-IF
                       END-IF                                           60000
                    END-EVALUATE                                        04930000
                 ELSE                                                   70000
      *****OPERAZIONE NON SOSPESA, TUTTE LE DIVISE MOVIMENTATE PARI
      *****A EURO
                    EVALUATE L-MODULO(1:6)
      ****FASE DI ANNULLO PRIMA DI RIVALORIZZAZIONE
                    WHEN 'ANNULL'
                      GO TO FINE
      ****FASE DI DRIVER DI STORNO OPERAZIONI NON RIVALORIZZATE PER LE
      ****QUALI LA CONTI CORRENTI E' STATA AGGIORNATA IN BATCH
BPO158              WHEN 'STNRIV'
BPO158                GO TO FINE
      ****FASE DI RIVALORIZZAZIONE
                    WHEN 'RIVALO'
      ****SEGNALARE ERRORE
                      MOVE 8                   TO W-FLAG-ERR            06260000
                      MOVE '9999'              TO W-COD-ERR             06270000
                      MOVE 'ZMBAGGCC'          TO L-MODULO              06300000
                      MOVE 'PER CAMBIO L NO RIVALORIZ'                  06310000
                                               TO L-SUB-MODULO          06310000
                      MOVE 'RIVALO  '          TO L-NOME-TABELLA        06310000
                      PERFORM 9999-GESTIONE-ERRORE                      06320000
                         THRU 9999-GESTIONE-ERRORE-END                  06330000
                      GO TO FINE                                        06340000
      ****FASE DI ANNULLO PER BONIFICI IN USCITA NON RIVALORIZZATI
                    WHEN 'ANNUBU'
                       MOVE 8                   TO W-FLAG-ERR           06260000
                       MOVE '9999'              TO W-COD-ERR            06270000
                       MOVE 'ZMBAGGCC'          TO L-MODULO             06300000
                       MOVE 'NON AMMESSO PER CAMBIO <> L'               06310000
                                                TO L-SUB-MODULO         06310000
                       MOVE 'ANNUBU  '    TO L-NOME-TABELLA             06310000
                       PERFORM 9999-GESTIONE-ERRORE                     06320000
                          THRU 9999-GESTIONE-ERRORE-END                 06330000
                       GO TO FINE                                       06340000
                    WHEN 'ANNUES'
                       MOVE 8                   TO W-FLAG-ERR           06260000
                       MOVE '9999'              TO W-COD-ERR            06270000
                       MOVE 'ZMBAGGCC'          TO L-MODULO             06300000
                       MOVE 'NON AMMESSO PER CAMBIO <> L'               06310000
                                                TO L-SUB-MODULO         06310000
                       MOVE 'ANNUES  '    TO L-NOME-TABELLA             06310000
                       PERFORM 9999-GESTIONE-ERRORE                     06320000
                          THRU 9999-GESTIONE-ERRORE-END                 06330000
                       GO TO FINE                                       06340000
                    WHEN 'ANNUBE'
                       MOVE 8                   TO W-FLAG-ERR           06260000
                       MOVE '9999'              TO W-COD-ERR            06270000
                       MOVE 'ZMBAGGCC'          TO L-MODULO             06300000
                       MOVE 'NON AMMESSO PER CAMBIO L'                  06310000
                                                TO L-SUB-MODULO         06310000
                       MOVE 'ANNUBE  '    TO L-NOME-TABELLA             06310000
                       PERFORM 9999-GESTIONE-ERRORE                     06320000
                          THRU 9999-GESTIONE-ERRORE-END                 06330000
                       GO TO FINE                                       06340000
                    WHEN OTHER
      ****COMPRENDE ANCHE IL MODULO A SPAZI
                       IF OPE-DIPOPE = 311
                          MOVE 'DIREZ'    TO WRK-DIPEIMM
                       ELSE
                          MOVE '00000'  TO WRK-DIPEIMM
                          MOVE OPE-DIPOPE  TO WRK-VALORE
                          PERFORM NORMALIZZA-CDPZ
                             THRU NORMALIZZA-CDPZ-END
                          MOVE WRK-NORMALE(1:5)  TO WRK-DIPEIMM
                       END-IF
      *----CANALE DI TRASMISSIONE NON VALORIZZATO
                       IF OPE-CANTRASM NOT GREATER SPACES
                           MOVE 'ESTE'    TO WRK-TERMIMM
                           IF OPE-FLUSSOPRV = 'MOSAIC'
                              MOVE SPACES     TO WRK-COPERIM
                           ELSE
                              MOVE OPE-NMTRUTE TO WRK-COPERIM
                           END-IF
                       ELSE
      *----CANALE DI TRASMISSIONE VALORIZZATO ES. BPIOL BPOL DORE ETC
                           MOVE SPACES    TO WRK-COPERIM
MCN002***                  IF OPE-CANTRASM = 'DORE'
MCN002                     IF WRK-TIPO-CANALE = 'R'
                               MOVE 'BPOL' TO WRK-TERMIMM
IM0031                         IF WRK-FLG-GEST-2 = 'P'
IM0031                            MOVE 'PSD2'  TO WRK-TERMIMM
IM0031                         END-IF
                           ELSE
MCN002***                      IF OPE-CANTRASM = 'DOCO'
MCN002***                         OR 'DOCA'  OR 'DOCP'
MCN002***                         OR 'DOCM'
MCN002***                         OR 'DOTE'
MCN002                         IF WRK-TIPO-CANALE = 'C'
                                  MOVE 'BPIO' TO WRK-TERMIMM
                               ELSE
                                  MOVE OPE-CANTRASM    TO WRK-TERMIMM
                               END-IF
                           END-IF
                       END-IF
BPO893**********************************************************
BPO893*** INSERIMENTO DI AMOVCC VIENE EFFETTUATA CON IL    *****
BPO893*** NUMERO MOVIMENTO 23 (DARE) ANCHE SE IL MOVIMENTO *****
BPO893*** CHE STO TRATTANDO E' CON TIPO MOVIMENTO = 2      *****
BPO893*** CIOE' MOVIMENTO IN  AVERE (24)                   *****
BPO893*** QUESTO PER CREARE LA PRENOTATA IN DARE SU CPCS   *****
BPO893*** 131 ACCREDITO CON PRENOTATA PER ANTITERRORISMO   *****
BPO893**********************************************************
APE001*-- DA QUI -----------------------------------------------
BPO893                 IF OPE-CPCS = 0131
BPO893                    IF KEY1-MOVP-TMOV (IND1-1) = 2
BPO893                       IF OPE-BCKFTIPOPE = 1
BPO893                          PERFORM R0050-INSERISCI-PRENOTATA
BPO893                             THRU R0050-INSERISCI-PRENOTATA-END
BPO893                          IF GEPP-RETCODE = 'OK'
BPO893                            INITIALIZE DCLTBAMOVCC
BPO893                            MOVE W-CIST        TO MOVCC-CIST
BPO893                            MOVE KEY1-MOVP-DIPOPE(IND1-1)
BPO893                                              TO MOVCC-DIPOPE
BPO893                            MOVE KEY1-MOVP-NUMOPE(IND1-1)
BPO893                                               TO MOVCC-NUMOPE
BPO893*                           MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
BPO893*                                            TO MOVCC-NPRGMOVP
BPO893                            MOVE 23          TO MOVCC-NPRGMOVP
BPO893                            MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO893                                            TO MOVCC-NSUBMOVP
BPO893                            MOVE WRK-NUMPRECC  TO MOVCC-NUMPRECC
BPO893                            MOVE WRK-SOMMA-SPESE2 TO MOVCC-IMPPRE
BPO893                            MOVE ZEROES        TO MOVCC-NUMOPECC
BPO893                            PERFORM R0055-INSERT-AMOVCC
BPO893                               THRU R0055-INSERT-AMOVCC-END
BPO893                         END-IF
BPO893                       ELSE
BPO893                         IF OPE-BCKFTIPOPE = 2
BPOA04*BPO893                      PERFORM R0060-ANNULLA-PRENOTATA
BPOA04*BPO893                         THRU R0060-ANNULLA-PRENOTATA-END
BPOA04                            PERFORM R0060-ANNULLA-PREN-EURO
BPOA04                               THRU R0060-ANNULLA-PREN-EURO-END
BPO893                            IF GEPP-RETCODE = 'OK'
BPO893                               INITIALIZE DCLTBAMOVCC
BPO893                               MOVE W-CIST    TO MOVCC-CIST
BPO893                               MOVE KEY1-MOVP-DIPOPE(IND1-1)
BPO893                                              TO MOVCC-DIPOPE
BPO893                               MOVE KEY1-MOVP-NUMOPE(IND1-1)
BPO893                                              TO MOVCC-NUMOPE
BPO893*                              MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
BPO893*                                             TO MOVCC-NPRGMOVP
BPO893                               MOVE 23        TO MOVCC-NPRGMOVP
BPO893                               MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO893                                              TO MOVCC-NSUBMOVP
BPO893                               MOVE ZEROES    TO MOVCC-NUMOPECC
BPO893                               MOVE ZEROES    TO MOVCC-NUMPRECC
BPO893                               MOVE ZEROES    TO MOVCC-IMPPRE
BPO893                               PERFORM R0080-UPDATE-AMOVCC
BPO893                                  THRU R0080-UPDATE-AMOVCC-END
BPO893                            END-IF
BPO893                         END-IF
BPO893                       END-IF
BPO893                    END-IF
BPO893                 END-IF
BPO893**********************************************************
BPO893*** ANNULLAMENTO DI AMOVCC IN CASO DI STORNO CPCS 131*****
BPO893**********************************************************
BPO893                 IF OPE-BCKFTIPOPE = 3  AND
BPO893                    OPE-CPCSORI  = 0131
BPO893                    MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO893                    MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPOA04*BPO893                    PERFORM R0060-ANNULLA-PRENOTATA
BPOA04*BPO893                       THRU R0060-ANNULLA-PRENOTATA-END
BPOA04                    PERFORM R0060-ANNULLA-PREN-EURO
BPOA04                       THRU R0060-ANNULLA-PREN-EURO-END
BPO893                    IF GEPP-RETCODE = 'OK'
BPO893                       INITIALIZE DCLTBAMOVCC
BPO893                       MOVE W-CIST    TO MOVCC-CIST
BPO893                       MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO893                       MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPO893                       MOVE 23        TO MOVCC-NPRGMOVP
BPO893                       MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO893                                     TO MOVCC-NSUBMOVP
BPO893                       MOVE ZEROES    TO MOVCC-NUMOPECC
BPO893                       MOVE ZEROES    TO MOVCC-NUMPRECC
BPO893                       MOVE ZEROES    TO MOVCC-IMPPRE
BPO893                       PERFORM R0080-UPDATE-AMOVCC
BPO893                          THRU R0080-UPDATE-AMOVCC-END
BPO893                   END-IF
BPO893                 END-IF
APE001*--  FINE SPOSTAMENTO --------------------------------------------
                       PERFORM R0070-AGGIORNA-CC                           50000
                          THRU R0070-AGGIORNA-CC-END                       50000
                       IF SV2P-RETCODE EQUAL SPACES
                          INITIALIZE DCLTBAMOVCC
BPO304                    INITIALIZE W-TAB-MOVCC
BPO304                    PERFORM VARYING IND1-2 FROM 1 BY 1            04880000
BPO304                      UNTIL IND1-2  > MAX-IND1-2
BPO304                         OR KEY1-MOVP-CAUSALE(IND1-1,IND1-2)      04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                         MOVE KEY1-MOVP-CAUSALE(IND1-1,IND1-2)
BPO304                                     TO W-MOVCC-CCAUBP(IND1-2)
BPO304                         MOVE KEY1-MOVP-CAUSALES(IND1-1,IND1-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND1-2)
BPO304                         MOVE KEY1-MOVP-CSTCS(IND1-1,IND1-2)
BPO304                                   TO W-MOVCC-CSTC(IND1-2)
BPO304                    END-PERFORM                                   04890000
BPO304                    MOVE W-TAB-MOVCC            TO MOVCC-WTABCOPE
BPO304*                   MOVE W-TAB-MOVCC    TO MOVCC-WTABCOPE-TEXT
                          IF OPE-BCKFTIPOPE = 1 OR 3
                             MOVE W-CIST  TO MOVCC-CIST
                             MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                   TO MOVCC-DIPOPE
                             MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                   TO MOVCC-NUMOPE
                             MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                   TO MOVCC-NPRGMOVP
                             MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                   TO MOVCC-NSUBMOVP
                             MOVE SV2P-NUMMOVI  TO MOVCC-NUMOPECC
BPO168                       MOVE KEY1-MOVP-CODOPE(IND1-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                       MOVE WRK-INCC-CATRAPP
BPO168                                                  TO MOVCC-CATRAPP
                             PERFORM R0055-INSERT-AMOVCC
                                THRU R0055-INSERT-AMOVCC-END
                          ELSE
                             MOVE W-CIST  TO MOVCC-CIST
                             MOVE KEY1-MOVP-DIPOPE(IND1-1)
                                                   TO MOVCC-DIPOPE
                             MOVE KEY1-MOVP-NUMOPE(IND1-1)
                                                   TO MOVCC-NUMOPE
                             MOVE KEY1-MOVP-NPRGMOVP(IND1-1)
                                                   TO MOVCC-NPRGMOVP
                             MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
                                                   TO MOVCC-NSUBMOVP
                             MOVE ZEROES        TO MOVCC-NUMOPECC
                             PERFORM R0080-UPDATE-AMOVCC
                                THRU R0080-UPDATE-AMOVCC-END
                          END-IF
                          IF IND2-1 GREATER ZEROES
BPO676                      IF OPE-CPCS = 1005  OR
BPO676                        (OPE-CPCS = 1011 AND
BPO676                         OPE-CPCSORI = 1005) OR
BPO676                        (OPE-CPCS = 1010 AND
BPO676                         OPE-CPCSORI = 1005)
BPO676                         NEXT SENTENCE
BPO676                      ELSE
                             PERFORM R0070-AGGIORNA-CSERV                  50000
                                THRU R0070-AGGIORNA-CSERV-END              50000
                             INITIALIZE DCLTBAMOVCC
BPO304                       INITIALIZE W-TAB-MOVCC
                             MOVE W-CIST  TO MOVCC-CIST
                             MOVE KEY2-MOVP-DIPOPE(IND2-1)
                                                       TO MOVCC-DIPOPE
                             MOVE KEY2-MOVP-NUMOPE(IND2-1)
                                                       TO MOVCC-NUMOPE
                             IF SV2P-RETCODE EQUAL SPACES
                                INITIALIZE DCLTBAMOVCC
                                MOVE W-CIST  TO MOVCC-CIST
                                MOVE KEY2-MOVP-DIPOPE(IND2-1)
                                                       TO MOVCC-DIPOPE
                                MOVE KEY2-MOVP-NUMOPE(IND2-1)
                                                        TO MOVCC-NUMOPE
BPO304***SALVO LE CAUSALI
BPO304                          PERFORM VARYING IND2-2  FROM 1 BY 1     04880000
BPO304                             UNTIL IND2-2  > MAX-IND2-2
BPO304                           OR KEY2-MOVP-CAUSALE(IND2-1,IND2-2)    04890000
BPO304                                              NOT GREATER ZEROES  04890000
BPO304                            MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUBP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CAUSALES(IND2-1,IND2-2)
BPO304                                     TO W-MOVCC-CCAUOP(IND2-2)
BPO304                            MOVE KEY2-MOVP-CSTCS(IND2-1,IND2-2)
BPO304                                   TO W-MOVCC-CSTC(IND2-2)
BPO304                          END-PERFORM                             04890000
BPO304                          MOVE W-TAB-MOVCC      TO MOVCC-WTABCOPE
BPO304*                        MOVE W-TAB-MOVCC  TO MOVCC-WTABCOPE-TEXT
                                IF OPE-BCKFTIPOPE = 1 OR 3
                                   IF IND2-1 NOT EQUAL 1
                                       COMPUTE MOVCC-NPRGMOVP =
                                                            99 - IND2-1
                                   ELSE
                                     MOVE 99     TO MOVCC-NPRGMOVP
                                   END-IF
                                   MOVE ZEROES        TO MOVCC-NSUBMOVP
                                   MOVE SV2P-NUMMOVI  TO MOVCC-NUMOPECC
BPO168                             MOVE KEY2-MOVP-CODOPE(IND2-1)
BPO168                                                 TO MOVCC-CODOPE
BPO168                             MOVE WRK-INCC-CATRAPP
BPO168                                                 TO MOVCC-CATRAPP
                                   PERFORM R0055-INSERT-AMOVCC
                                      THRU R0055-INSERT-AMOVCC-END
                                ELSE
                                  IF IND2-1 NOT EQUAL 1
                                     COMPUTE MOVCC-NPRGMOVP =
                                                           99 - IND2-1
                                  ELSE
                                     MOVE 99     TO MOVCC-NPRGMOVP
                                  END-IF
                                  MOVE ZEROES        TO MOVCC-NSUBMOVP
                                  MOVE ZEROES        TO MOVCC-NUMOPECC
                                  PERFORM R0080-UPDATE-AMOVCC
                                     THRU R0080-UPDATE-AMOVCC-END
                                END-IF
                             END-IF
BPO676                      END-IF
                          END-IF
                       END-IF
APE001*---- A QUI -------------
                    END-EVALUATE                                        04930000
                 END-IF                                                    70000
              END-PERFORM                                               04930000
           END-IF.                                                      04270000

       FINE.
           EXEC SQL INCLUDE ZMYGOBAK  END-EXEC.
      *--------------------------------------------------------------   06200000
       R0005-PRELEVA-TIMESTAMP.
      *------------
           MOVE ZEROES              TO W-SQLCODE.
           EXEC SQL INCLUDE ZMS20402 END-EXEC.
           IF NOT W-SQL-OK
              MOVE 8                   TO W-FLAG-ERR                    06260000
              MOVE '9999'              TO W-COD-ERR                     06270000
              MOVE 'TBTISTI '          TO L-NOME-TABELLA                06280000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  06290000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      06300000
              MOVE 'ZMS20402'          TO L-SUB-MODULO                  06310000
              PERFORM 9999-GESTIONE-ERRORE                              06320000
                 THRU 9999-GESTIONE-ERRORE-END                          06330000
              GO TO FINE                                                06340000
           END-IF.
       R0005-PRELEVA-TIMESTAMP-END.
           EXIT.
       R0010-LEGGI-TBAOPE.                                              06210000
                                                                        06220000
           EXEC SQL INCLUDE ZMS11501  END-EXEC.                         06230000
                                                                        06240000
           IF NOT W-SQL-OK                                              06250000
              MOVE 8                   TO W-FLAG-ERR                    06260000
              MOVE '9999'              TO W-COD-ERR                     06270000
              MOVE 'TBAOPE  '          TO L-NOME-TABELLA                06280000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  06290000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      06300000
              MOVE 'ZMS11501'          TO L-SUB-MODULO                  06310000
              PERFORM 9999-GESTIONE-ERRORE                              06320000
                 THRU 9999-GESTIONE-ERRORE-END                          06330000
              GO TO FINE                                                06340000
           END-IF.                                                      06350000
                                                                        06360000
       R0010-LEGGI-TBAOPE-END.                                          06370000
           EXIT.                                                        06380000
      *--------------------------------------------------------------   06200000
       R0010-LEGGI-TBWCONFC.                                            06210000
                                                                        06220000
           EXEC SQL INCLUDE ZMS61101  END-EXEC.                         06230000
                                                                        06240000
           IF NOT W-SQL-OK                                              06250000
              MOVE 8                   TO W-FLAG-ERR                    06260000
              MOVE '9999'              TO W-COD-ERR                     06270000
              MOVE 'TBAOPE  '          TO L-NOME-TABELLA                06280000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  06290000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      06300000
              MOVE 'ZMS61101'          TO L-SUB-MODULO                  06310000
              PERFORM 9999-GESTIONE-ERRORE                              06320000
                 THRU 9999-GESTIONE-ERRORE-END                          06330000
              GO TO FINE                                                06340000
           END-IF.                                                      06350000
                                                                        06360000
       R0010-LEGGI-TBWCONFC-END.                                        06370000
           EXIT.                                                        06380000
      *--------------------------------------------------------------   06390000
       R0020-APERTURA-CURSORE1.                                         06400000
                                                                        06410000
           EXEC SQL INCLUDE ZMLOPE01  END-EXEC.                         06420000
                                                                        06430000
           IF NOT W-SQL-OK                                              06440000
              MOVE 8                   TO W-FLAG-ERR                    06450000
              MOVE '9999'              TO W-COD-ERR                     06460000
              MOVE 'TBAMOVP '          TO L-NOME-TABELLA                06470000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  06480000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      06490000
              MOVE 'ZMLOPE01'          TO L-SUB-MODULO                  06500000
              PERFORM 9999-GESTIONE-ERRORE                              06510000
                 THRU 9999-GESTIONE-ERRORE-END                          06520000
              GO TO FINE                                                06530000
           END-IF.                                                      06540000
                                                                        06550000
       R0020-APERTURA-CURSORE1-END.                                     06560000
           EXIT.                                                        06570000
      *--------------------------------------------------------------   07100000
       R6070-FETCH-TBAMOVP.                                             07110000
                                                                        07120000
           EXEC SQL INCLUDE ZMF11601  END-EXEC.                         07130000
                                                                        07140000
           IF NOT W-SQL-OK                                              07150000
              AND NOT W-SQL-NON-TROVATO                                 07160000
              MOVE 8                   TO W-FLAG-ERR                    07170000
              MOVE '9999'              TO W-COD-ERR                     07180000
              MOVE 'TBAMOVP '          TO L-NOME-TABELLA                07190000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  07200000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      07210000
              MOVE 'ZMF11601'          TO L-SUB-MODULO                  07220000
              PERFORM 9999-GESTIONE-ERRORE                              07230000
                 THRU 9999-GESTIONE-ERRORE-END                          07240000
              GO TO FINE                                                07250000
           END-IF.                                                      07260000
           IF W-SQL-NON-TROVATO                                         07270000
              MOVE 'N'          TO WRK-TROVATO                          07280000
           ELSE                                                         07281000
              MOVE MOVP-CSTC    TO ABSC-CSTC                            07282000
              MOVE MOVP-CIST    TO ABSC-CIST                            07283000
              PERFORM R0050-LEGGI-TBTABSC                               07284000
                 THRU R0050-LEGGI-TBTABSC-END                           07285000
              IF W-SQL-NON-TROVATO                                      07286000
                 MOVE 'N'          TO WRK-TROVATO                       07287000
              ELSE                                                      07288000
                 MOVE 'S'          TO WRK-TROVATO                       07289000
                 MOVE ZEROES TO WRK-SOMMA-SPESE
                 EVALUATE ABSC-CTIPSTC                                  07289100
                 WHEN 400                                               07289200
      *PER SOTTOCONTI 94 95 97 98 NON AGGIORNARE I CONTI CORRENTI
                    IF ABSC-CSTC = 94 OR 95 OR 97 OR 98
                       GO TO R6070-FETCH-TBAMOVP-END
                    END-IF
BPO905*BPO896              IF OPE-TCAB  = 'L'
BPO905*BPO896             AND (OPE-BCKFTIPOPE = 2 OR 3)
BPO905*BOP896              AND L-MODULO(1:6) NOT = 'RIVALO  '
BPO905*BPO896                 INITIALIZE DCLTBABFA
BPO905*BPO896                 IF OPE-BCKFTIPOPE = 2
BPO905*BPO896                    MOVE OPE-DIPOPE     TO BFA-DIPOPE
BPO905*BPO896                    MOVE OPE-NUMOPE     TO BFA-NUMOPE
BPO905*BPO896                 ELSE
BPO905*BPO896                    MOVE OPE-CDPZOPEST  TO BFA-DIPOPE
BPO905*BPP896                    MOVE OPE-NOPEST     TO BFA-NUMOPE
BPO905*BPO896                 END-IF
BPO905*BPO896                 PERFORM R0051-LEGGI-BFA-STPART            07284000
BPO905*BPO896                    THRU R0051-LEGGI-BFA-STPART            07285000
BPO905*BPO896                 IF W-SQL-OK
BPO905*BPO896                    IF  (BFA-STPARTIT = 'ACSOS'
BPO905*BPO896                    OR  BFA-STPARTIT = 'ADSOS'
BPO905*BPO896                    OR  BFA-STPARTIT = 'ESSOS' )
BPO905*BPO896                        GO TO R6070-FETCH-TBAMOVP-END
BPO905*BPO896                    END-IF
BPO905*BPO896                 END-IF
BPO905*BPO896              END-IF
                    IF IND1-1 EQUAL ZEROES
                       PERFORM INTABELLA-CC THRU INTABELLA-CC-END       07290200
                    ELSE
      *SE TIPO STC 400 E LA TABELLA C/C HA GIA' UNA RIGA E IL NUMERO
      *DI CONTO E' DIVERSO  DAL PRECEDENTE ALLORA SI HA UN SOTTOCONTO
      *ADDEBITO SPESE  DIVERSO DA QUELLO DEL MOVIMENTO PRINCIPALE
                       IF MOVP-NCCO13 NOT =
                          KEY1-MOVP-NCCO(IND1-1)
                          PERFORM INTABELLA-CC THRU INTABELLA-CC-END    07290200
                          MOVE ZEROES TO IND1-2                         07291400
                       ELSE
                          MOVE 'S' TO  KEY1-MOVP-FSPESE(IND1-1)
                       END-IF
                    END-IF
                    MOVE SPACES TO WRK-MOVE
                    MOVE MOVP-DIPOPE              TO MOVE-DIPOPE
                    MOVE MOVP-NUMOPE              TO MOVE-NUMOPE
                    MOVE MOVP-NPRGMOVP            TO MOVE-NPRGMOVP
                    MOVE 'S'                      TO WRK-TROVATO-MOVE
                    PERFORM R0020-APERTURA-CURSORE5                     04350200
                       THRU R0020-APERTURA-CURSORE5-END                 04350300
      *                                                                 04360000
                    PERFORM R6070-FETCH-TBAMOVE                         04370000
                       THRU R6070-FETCH-TBAMOVE-END                     04380000
                      UNTIL WRK-TROVATO-MOVE = 'N'                      04390000
                                                                        04400000
                    PERFORM R0040-CHIUSURA-CURSORE5                     04451500
                       THRU R0040-CHIUSURA-CURSORE5-END                 04451600
      *------------------> PER OGNI PATRIMONIALE CERCA I MOV ECONOMICI  04350100
                    IF  WRK-TROVATO-MOVE = 'N' AND
                        WRK-MOVE NOT = 'S'
                       PERFORM INTABELLA-CC-NO-SP                       07290200
                          THRU INTABELLA-CC-NO-SP-END                   07290200
                    ELSE
                       IF WRK-MOVE = 'S'
      *****SE HO SOLO IL MOVIMENTO DI SPESA NON DEVO SCRIVERE
      *****IL PATRIMONIALE MA SOLO LE SPESE
                       AND KEY1-MOVP-FSPESE(IND1-1) NOT = 'S'
                          PERFORM INTABELLA-CC-MOVP                     07290200
                             THRU INTABELLA-CC-MOVP-END                 07290200
                       END-IF
                    END-IF
                    MOVE 'S'        TO WRK-ELABORA-1                    07289300
      *             ADD 1 TO IND1-1
                 WHEN OTHER                                             07289500
BPO676*PER CONTO BANCA E 1005 CONTINUA A NON AGGIORNARE I C/C
BPO676              IF OPE-CPCS = 1005  OR
BPO676                 (OPE-CPCS = 1011 AND OPE-CPCSORI = 1005) OR
BPO676                 (OPE-CPCS = 1010 AND OPE-CPCSORI = 1005)
BPO676                 GO TO R6070-FETCH-TBAMOVP-END
BPO676              END-IF
      *SE TIPO STC DIVERSO DA 400 BISOGNA VERIFICARE SE CI SIANO SPESE
      *OUR O BEN PER INSERIRLE NEL CONTO SERVIZIO
                    MOVE MOVP-DIPOPE              TO MOVE-DIPOPE
                    MOVE MOVP-NUMOPE              TO MOVE-NUMOPE
                    MOVE MOVP-NPRGMOVP            TO MOVE-NPRGMOVP
                    MOVE 'S'                      TO WRK-TROVATO-MOVE
                    PERFORM R0020-APERTURA-CURSORE5                     04350200
                       THRU R0020-APERTURA-CURSORE5-END                 04350300
      *                                                                 04360000
                    PERFORM R6070-FETCH-TBAMOVE                         04370000
                       THRU R6070-FETCH-TBAMOVE-END                     04380000
                      UNTIL WRK-TROVATO-MOVE = 'N'                      04390000
                                                                        04400000
                    PERFORM R0040-CHIUSURA-CURSORE5                     04451500
                       THRU R0040-CHIUSURA-CURSORE5-END                 04451600
                 END-EVALUATE                                           07289700
              END-IF                                                    07290800
           END-IF.                                                      07290900
                                                                        07291000
       R6070-FETCH-TBAMOVP-END.                                         07291100
           EXIT.                                                        07291200
      *--------------------------------------------------------------   07350000
       R0040-CHIUSURA-CURSORE1.                                         07360000
                                                                        07370000
           EXEC SQL INCLUDE ZMLCLO01  END-EXEC.                         07380000
                                                                        07390000
           IF NOT W-SQL-OK                                              07400000
              MOVE 8                   TO W-FLAG-ERR                    07410000
              MOVE '9999'              TO W-COD-ERR                     07420000
              MOVE 'TBAMOVP '          TO L-NOME-TABELLA                07430000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  07440000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      07450000
              MOVE 'ZMLCLO01'          TO L-SUB-MODULO                  07460000
              PERFORM 9999-GESTIONE-ERRORE                              07470000
                 THRU 9999-GESTIONE-ERRORE-END                          07480000
              GO TO FINE                                                07490000
           END-IF.                                                      07500000
                                                                        07510000
       R0040-CHIUSURA-CURSORE1-END.                                     07520000
           EXIT.                                                        07530000
      *--------------------------------------------------------------   06390000
       R0020-APERTURA-CURSORE5.                                         06400000
                                                                        06410000
           EXEC SQL INCLUDE ZMLOPE05  END-EXEC.                         06420000
                                                                        06430000
           IF NOT W-SQL-OK                                              06440000
              MOVE 8                   TO W-FLAG-ERR                    06450000
              MOVE '9999'              TO W-COD-ERR                     06460000
              MOVE 'TBAMOVE '          TO L-NOME-TABELLA                06470000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  06480000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      06490000
              MOVE 'ZMLOPE05'          TO L-SUB-MODULO                  06500000
              PERFORM 9999-GESTIONE-ERRORE                              06510000
                 THRU 9999-GESTIONE-ERRORE-END                          06520000
              GO TO FINE                                                06530000
           END-IF.                                                      06540000
                                                                        06550000
       R0020-APERTURA-CURSORE5-END.                                     06560000
           EXIT.                                                        06570000
      *--------------------------------------------------------------   07100000
       R6070-FETCH-TBAMOVE.                                             07110000
                                                                        07120000
           EXEC SQL INCLUDE ZMF11902  END-EXEC.                         07130000
                                                                        07140000
           IF NOT W-SQL-OK                                              07150000
              AND NOT W-SQL-NON-TROVATO                                 07160000
              MOVE 8                   TO W-FLAG-ERR                    07170000
              MOVE '9999'              TO W-COD-ERR                     07180000
              MOVE 'TBAMOVE '          TO L-NOME-TABELLA                07190000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  07200000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      07210000
              MOVE 'ZMF11902'          TO L-SUB-MODULO                  07220000
              PERFORM 9999-GESTIONE-ERRORE                              07230000
                 THRU 9999-GESTIONE-ERRORE-END                          07240000
              GO TO FINE                                                07250000
           END-IF.                                                      07260000
           IF W-SQL-NON-TROVATO                                         07270000
              MOVE 'N'          TO WRK-TROVATO-MOVE                     07280000
           ELSE                                                         07281000
              IF IND2-1 EQUAL ZEROES
                 PERFORM INTABELLA-CSERV                                07290200
                    THRU INTABELLA-CSERV-END                            07290200
              END-IF
              PERFORM INTABELLA-CSERV-SP                                07290200
                 THRU INTABELLA-CSERV-SP-END                            07290200
              IF ABSC-CTIPSTC = 400
                 MOVE 'S'          TO WRK-MOVE
                 PERFORM INTABELLA-CC-SP                                07290200
                    THRU INTABELLA-CC-SP-END                            07290200
              END-IF
           END-IF.                                                      07290900
                                                                        07291000
       R6070-FETCH-TBAMOVE-END.                                         07291100
           EXIT.                                                        07291200
      *--------------------------------------------------------------   07350000
       R0040-CHIUSURA-CURSORE5.                                         07360000
                                                                        07370000
           EXEC SQL INCLUDE ZMLCLO05  END-EXEC.                         07380000
                                                                        07390000
           IF NOT W-SQL-OK                                              07400000
              MOVE 8                   TO W-FLAG-ERR                    07410000
              MOVE '9999'              TO W-COD-ERR                     07420000
              MOVE 'TBAMOVE '          TO L-NOME-TABELLA                07430000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  07440000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      07450000
              MOVE 'ZMLCLO05'          TO L-SUB-MODULO                  07460000
              PERFORM 9999-GESTIONE-ERRORE                              07470000
                 THRU 9999-GESTIONE-ERRORE-END                          07480000
              GO TO FINE                                                07490000
           END-IF.                                                      07500000
                                                                        07510000
       R0040-CHIUSURA-CURSORE5-END.                                     07520000
           EXIT.                                                        07530000
       INTABELLA-CC.                                                    07291300
           ADD 1 TO IND1-1.                                             07291400
           MOVE MOVP-NCCO13     TO KEY1-MOVP-NCCO   (IND1-1).           07291700
           MOVE MOVP-CDPZ       TO KEY1-MOVP-CDPZ   (IND1-1).           07291800
           MOVE MOVP-CIST       TO KEY1-MOVP-CIST   (IND1-1).           07291900
           MOVE MOVP-CSTC       TO KEY1-MOVP-CSTC   (IND1-1).           07292000
           MOVE MOVP-DVAL       TO KEY1-MOVP-DVAL  (IND1-1).            07293000
           MOVE MOVP-DCON       TO KEY1-MOVP-DCON  (IND1-1).            07293000
           MOVE MOVP-DIPOPE     TO KEY1-MOVP-DIPOPE (IND1-1).           07293100
           MOVE MOVP-NUMOPE     TO KEY1-MOVP-NUMOPE (IND1-1).           07293200
           MOVE MOVP-NPRGMOVP   TO KEY1-MOVP-NPRGMOVP(IND1-1).          07293200
           MOVE MOVP-NSUBMOVP   TO KEY1-MOVP-NSUBMOVP(IND1-1).          07293200
           MOVE 'EUR'           TO KEY1-MOVP-CISO   (IND1-1).           07293400
           MOVE MOVP-TMOV       TO KEY1-MOVP-TMOV   (IND1-1).           07293400
BPO138*------------------------------ PRELEVA LA CAUSALE DA PASSARE     07320000
BPO138     MOVE MOVP-CIST       TO ACABP-CIST.
BPO168     IF OPE-BCKFTIPOPE NOT = 3
BPO138        MOVE MOVP-CCAUNOP    TO ACABP-CCAUOP
BPO168     ELSE
BPO168        IF OPE-FITOEBS = 'I'
BPO138           MOVE 'STE'           TO ACABP-CCAUOP
BPO168        ELSE
BPO138           MOVE 'STU'           TO ACABP-CCAUOP
BPO168        END-IF
BPO168     END-IF
IM0026*-----------------------------------------------------------
IM0026*--- PERFORM SPOSTATA PERCHE' VALORIZZA ANCHE CIRCUITO   ---
IM0026*-----------------------------------------------------------
IM0026     PERFORM IMPOSTA-CODOPE-CIRCUITO
IM0026        THRU IMPOSTA-CODOPE-CIRCUITO-END
IM0026     IF WRK-FLG-GEST-1 GREATER SPACES
IM0026         MOVE WRK-CIRCUITO  TO ACABP-CIRCUITO
IM0026     ELSE
IM0026         MOVE SPACES        TO ACABP-CIRCUITO
IM0026     END-IF
APE001     MOVE SPACES TO ACABP-FLG-CARTA.
APE001*    MOVE SPACES TO ACABP-CIRCUITO.
IM0026     MOVE WRK-FLG-GEST-5 TO ACABP-CANALE.
BPO138     PERFORM LEGGI-TBTACABP
BPO138        THRU LEGGI-TBTACABP-END.
BPO138*    MOVE MOVP-CCAUNOP    TO KEY1-MOVP-CCAUNOP(IND1-1).
BPO138     MOVE ACABP-CCAUBP    TO KEY1-MOVP-CCAUNOP(IND1-1).
BPO168*    MOVE 'BIBOABES'      TO KEY1-MOVP-CODOPE (IND1-1).           07293400
IM0026*BPO168     PERFORM IMPOSTA-CODOPE-CIRCUITO
IM0026*BPO168        THRU IMPOSTA-CODOPE-CIRCUITO-END
IM0026*-- SE WRK-FLG-GEST-1 > SPAZIO RICOPRO WRK-CODOPE-CA
IM0026*-- VALORIZZATO DALLA PERFORM IMPOSTA-CODOPE-CIRCUITO
IM0026*-- CON ACABP-CODOPE DI TBTACABP
IM0026     IF WRK-FLG-GEST-1 GREATER SPACES
IM0026        MOVE ACABP-CODOPE  TO WRK-CODOPE-CC
IM0026     END-IF.
BPO168     MOVE WRK-CODOPE-CC   TO KEY1-MOVP-CODOPE (IND1-1).           07293400
      *--------------------------------------------------------------   07320000
       INTABELLA-CC-END.                                                07330000
           EXIT.                                                        07340000
       INTABELLA-CSERV.                                                 07291300
           ADD 1 TO IND2-1.                                             07291400
BPO168     IF OPE-BCKFTIPOPE  = 3
BPO168        MOVE CONFC-NCCOSERTS   TO KEY2-MOVP-NCCO   (IND2-1)       07291700
BPO168     ELSE
              MOVE CONFC-NCCOSERUB   TO KEY2-MOVP-NCCO   (IND2-1)       07291700
BPO168     END-IF
           MOVE MOVP-DIPOPE       TO KEY2-MOVP-DIPOPE (IND2-1).         07293100
           MOVE MOVP-NUMOPE       TO KEY2-MOVP-NUMOPE (IND2-1).         07293200
           MOVE MOVP-TMOV         TO KEY2-MOVP-TMOV (IND2-1).           07293200
           MOVE MOVP-DCON         TO KEY2-MOVP-DCON   (IND2-1).         07293200
           MOVE 'EUR'             TO KEY2-MOVP-CISO   (IND2-1).         07293400
BPO168*    MOVE 'BIBOCBES'        TO KEY2-MOVP-CODOPE (IND2-1).         07293400
BPO168*    MOVE 'ESTC'            TO KEY2-MOVP-CODOPE (IND2-1).         07293400
BPO168     IF WRK-CODOPE-CC GREATER SPACES
BPO168        MOVE WRK-CODOPE-CC  TO KEY2-MOVP-CODOPE (IND2-1)          07293400
BPO168     ELSE
BPO268*BPO168        IF ABSC-CTIPSTC = 101 OR  111 OR  112 OR
BPO268*BPO168                        102 OR  116 OR  103 OR
BPO268        IF ABSC-CTIPSTC NOT = 400
BPO168*SI TRATTA DI SPESE OUR IN UN BONIFICO IN ARRIVO
BPO168           IF (ABSC-CTIPSTC = 112
BPO168              AND ABSC-FTPGEST = 6)
BPO660              OR ABSC-CSTC = 143
BPO168              MOVE 'ESTA'         TO KEY2-MOVP-CODOPE (IND2-1)    07293400
BPO168           ELSE
BPO168              MOVE 'ESTB'         TO KEY2-MOVP-CODOPE (IND2-1)    07293400
BPO168           END-IF
BPO168        END-IF
BPO168     END-IF.
      *--------------------------------------------------------------   07320000
       INTABELLA-CSERV-END.                                             07330000
           EXIT.                                                        07340000
      *
       INTABELLA-CC-SP.                                                 07291300
           ADD 1 TO IND1-2.                                             07291400
           MOVE MOVE-ICTVLISPS                                          07293300
                    TO KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)                 07293300
           IF MOVE-ISPSVAL    > ZEROES                                  07293300
              MOVE 'D'  TO KEY1-MOVP-FLAGDA(IND1-1,IND1-2)              07293600
              MOVE MOVE-ICTVLISPS TO WRK-SPESA-CC
           ELSE                                                         07293300
              MOVE 'A'  TO KEY1-MOVP-FLAGDA(IND1-1,IND1-2)              07293600
              COMPUTE WRK-SPESA-CC = MOVE-ICTVLISPS * -1
           END-IF.                                                      07293300
           ADD WRK-SPESA-CC TO WRK-SOMMA-SPESE.
BPO168     PERFORM IMPOSTA-CAUSALE-ECON
BPO168        THRU IMPOSTA-CAUSALE-ECON-END.
BPO138     MOVE ACABP-CCAUBP    TO KEY1-MOVP-CAUSALE(IND1-1,IND1-2).
BPO304     MOVE ACABP-CCAUOP    TO KEY1-MOVP-CAUSALES(IND1-1,IND1-2).
BPO304     MOVE MOVE-CCEC       TO KEY1-MOVP-CSTCS(IND1-1,IND1-2).
      *--------------------------------------------------------------   07320000
       INTABELLA-CC-SP-END.                                             07330000
           EXIT.                                                        07340000
       INTABELLA-CC-NO-SP.                                              07291300
           ADD 1 TO IND1-2.                                             07291400
           MOVE MOVP-ICTVLIS                                            07293300
                    TO KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)                 07293300
           IF MOVP-ICTVLIS    > ZEROES                                  07293300
              MOVE 'A'  TO KEY1-MOVP-FLAGDA(IND1-1,IND1-2)              07293600
           ELSE                                                         07293300
              MOVE 'D'  TO KEY1-MOVP-FLAGDA(IND1-1,IND1-2)              07293600
           END-IF.                                                      07293300
BPO138*------------------------------ PRELEVA LA CAUSALE DA PASSARE     07320000
BPO138     MOVE MOVP-CIST       TO ACABP-CIST.
BPO168     IF OPE-BCKFTIPOPE NOT = 3
BPO138        MOVE MOVP-CCAUNOP    TO ACABP-CCAUOP
BPO168     ELSE
BPO168        IF OPE-FITOEBS = 'I'
BPO138           MOVE 'STE'           TO ACABP-CCAUOP
BPO168        ELSE
BPO138           MOVE 'STU'           TO ACABP-CCAUOP
BPO168        END-IF
BPO168     END-IF
APE001     MOVE SPACES TO ACABP-FLG-CARTA.
IM0026     IF WRK-FLG-GEST-1 GREATER SPACES
IM0026         MOVE WRK-CIRCUITO  TO ACABP-CIRCUITO
IM0026     ELSE
IM0026         MOVE SPACES        TO ACABP-CIRCUITO
IM0026     END-IF
APE001*    MOVE SPACES TO ACABP-CIRCUITO.
IM0026     MOVE WRK-FLG-GEST-5 TO ACABP-CANALE.
BPO138     PERFORM LEGGI-TBTACABP
BPO138        THRU LEGGI-TBTACABP-END.
BPO138*    MOVE MOVP-CCAUNOP    TO KEY1-MOVP-CAUSALE(IND1-1,IND1-2).
BPO138     MOVE ACABP-CCAUBP    TO KEY1-MOVP-CAUSALE(IND1-1,IND1-2).
BPO304     MOVE ACABP-CCAUOP    TO KEY1-MOVP-CAUSALES(IND1-1,IND1-2).
BPO304     MOVE MOVP-CSTC       TO WRK-VALORE
BPO304     PERFORM NORMALIZZA-CSTC
BPO304        THRU NORMALIZZA-CSTC-END
BPO304     MOVE WRK-NORMALE(1:16)   TO KEY1-MOVP-CSTCS(IND1-1,IND1-2).
      *--------------------------------------------------------------   07320000
       INTABELLA-CC-NO-SP-END.                                          07330000
           EXIT.                                                        07340000
       INTABELLA-CC-MOVP.                                               07291300
           ADD 1 TO IND1-2.                                             07291400
           IF OPE-FTIPOPE = 3
              COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE  * -1
           END-IF
           COMPUTE WRK-SOMMA-SPESE = MOVP-ICTVLIS + WRK-SOMMA-SPESE
           MOVE WRK-SOMMA-SPESE                                         07293300
                    TO KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)                 07293300
           IF WRK-SOMMA-SPESE > ZEROES                                  07293300
              MOVE 'A'  TO KEY1-MOVP-FLAGDA(IND1-1,IND1-2)              07293600
           ELSE                                                         07293300
              MOVE 'D'  TO KEY1-MOVP-FLAGDA(IND1-1,IND1-2)              07293600
           END-IF.                                                      07293300
BPO138*------------------------------ PRELEVA LA CAUSALE DA PASSARE     07320000
BPO138     MOVE MOVP-CIST       TO ACABP-CIST.
BPO168     IF OPE-BCKFTIPOPE NOT = 3
BPO138        MOVE MOVP-CCAUNOP    TO ACABP-CCAUOP
BPO168     ELSE
BPO168        IF OPE-FITOEBS = 'I'
BPO138           MOVE 'STE'           TO ACABP-CCAUOP
BPO168        ELSE
BPO138           MOVE 'STU'           TO ACABP-CCAUOP
BPO168        END-IF
BPO168     END-IF
APE001     MOVE SPACES TO ACABP-FLG-CARTA.
IM0026     IF WRK-FLG-GEST-1 GREATER SPACES
IM0026         MOVE WRK-CIRCUITO  TO ACABP-CIRCUITO
IM0026     ELSE
IM0026         MOVE SPACES        TO ACABP-CIRCUITO
IM0026     END-IF
APE001*    MOVE SPACES TO ACABP-CIRCUITO.
IM0026     MOVE WRK-FLG-GEST-5 TO ACABP-CANALE.
BPO138     PERFORM LEGGI-TBTACABP
BPO138        THRU LEGGI-TBTACABP-END.
BPO138*    MOVE MOVP-CCAUNOP    TO KEY1-MOVP-CAUSALE(IND1-1,IND1-2).
BPO138     MOVE ACABP-CCAUBP    TO KEY1-MOVP-CAUSALE(IND1-1,IND1-2).
BPO304     MOVE ACABP-CCAUOP    TO KEY1-MOVP-CAUSALES(IND1-1,IND1-2).
BPO304     MOVE MOVP-CSTC       TO WRK-VALORE
BPO304     PERFORM NORMALIZZA-CSTC
BPO304        THRU NORMALIZZA-CSTC-END
BPO304     MOVE WRK-NORMALE(1:16)   TO KEY1-MOVP-CSTCS(IND1-1,IND1-2).
       INTABELLA-CC-MOVP-END.                                           07330000
           EXIT.                                                        07340000
       INTABELLA-CSERV-SP.                                              07291300
           ADD 1 TO IND2-2.                                             07291400
           MOVE MOVE-ICTVLISPS                                          07293300
                    TO KEY2-MOVP-ICTVLIS(IND2-1,IND2-2)                 07293300
           IF MOVE-ISPSVAL    < ZEROES                                  07293300
              MOVE 'D'  TO KEY2-MOVP-FLAGDA(IND2-1,IND2-2)              07293600
           ELSE                                                         07293300
              MOVE 'A'  TO KEY2-MOVP-FLAGDA(IND2-1,IND2-2)              07293600
           END-IF.                                                      07293300
TAE   *APE001     PERFORM IMPOSTA-CODOPE-CIRCUITO
TAE   *APE001        THRU IMPOSTA-CODOPE-CIRCUITO-END
BPO168     PERFORM IMPOSTA-CAUSALE-ECON
BPO168        THRU IMPOSTA-CAUSALE-ECON-END.
BPO168     MOVE ACABP-CCAUBP TO KEY2-MOVP-CAUSALE(IND2-1,IND2-2).
BPO304     MOVE ACABP-CCAUOP TO KEY2-MOVP-CAUSALES(IND2-1,IND2-2).
IM0006     MOVE ACABP-FLG-CARTA TO KEY2-MOVP-FLGCARTA(IND2-1,IND2-2).
BPO304     MOVE MOVE-CCEC    TO KEY2-MOVP-CSTCS(IND2-1,IND2-2).
       INTABELLA-CSERV-SP-END.                                          07330000
           EXIT.                                                        07340000
       IMPOSTA-CAUSALE-ECON.                                            07330000
BPO168     IF ABSC-CTIPSTC = 400
BPO168        MOVE MOVE-CIST       TO ACABP-CIST
BPO676        MOVE OPE-FITOEBS     TO WRK-OPE-FITOEBS
BPO676***PER IL PROCESSO 1005 IMPOSTO LE CAUSALI IN MODO DIVERSO
BPO676        IF OPE-CPCS = 1005
BPO676*          IF WRK-FLAG-OPECOLL = 'N' OR
BPO676*             (WRK-FLAG-OPECOLL = 'S' AND
BPO676*              WRK-CDPZ-OPECOLL = 55111)
BPO676           INITIALIZE DCLTBTABCEC
BPO676           MOVE MOVE-CCEC    TO ABCEC-CCEC
BPO676           PERFORM LEGGI-TBTABCEC
BPO676              THRU LEGGI-TBTABCEC-END
BPO676           IF OPE-BCKFTIPOPE NOT = 3
BPO676              IF ABCEC-TCEC = 1
BPO676                 MOVE 'SEE'        TO ACABP-CCAUOP
BPO676              END-IF
BPO676              IF ABCEC-TCEC = 2 OR 3
BPO676                 MOVE 'SEV'        TO ACABP-CCAUOP
BPO676              END-IF
BPO676              IF ABCEC-CCEC = '529'
BPO676                 MOVE 'CES'        TO ACABP-CCAUOP
BPO676              END-IF
BPO676           ELSE
BPO676              IF MOVE-TCEC = 1
BPO676                 MOVE 'ST6'        TO ACABP-CCAUOP
BPO676              END-IF
BPO676              IF MOVE-TCEC = 2 OR 3
BPO676                 MOVE 'ST5'        TO ACABP-CCAUOP
BPO676              END-IF
BPO676              IF ABCEC-CCEC =  '529'
BPO676                 MOVE 'ST7'        TO ACABP-CCAUOP
BPO676              END-IF
BPO676          END-IF
BPO676        ELSE
BPO168           IF OPE-BCKFTIPOPE NOT = 3
BPO168              IF OPE-FITOEBS = 'I'
BPO168                 IF MOVE-TCEC = 1
BPO168                    MOVE 'SPE'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-TCEC = 2
BPO168                    MOVE 'SPV'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-TCEC = 3
BPO168                    MOVE 'COM'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-CCEC  =  '529'
BPO168                    MOVE 'CVS'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168              ELSE
BPO168                 IF MOVE-TCEC = 1
BPO168                    MOVE 'SEE'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-TCEC = 2
BPO168                    MOVE 'SEV'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-TCEC = 3
BPO168                    MOVE 'CEM'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-CCEC  =  '529'
BPO168                    MOVE 'CES'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168              END-IF
BPO168          ELSE
BPO168              IF OPE-FITOEBS = 'I'
BPO168                 IF MOVE-TCEC = 1
BPO168                    MOVE 'ST3'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-TCEC = 2
BPO168                    MOVE 'SPV'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-TCEC = 3
BPO168                    MOVE 'ST2'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-CCEC  =  '529'
BPO168                    MOVE 'ST4'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168              ELSE
BPO168                 IF MOVE-TCEC = 1
BPO168                    MOVE 'ST6'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-TCEC = 2
BPO168                    MOVE 'SEV'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-TCEC = 3
BPO168                    MOVE 'ST5'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168                 IF MOVE-CCEC  =  '529'
BPO168                    MOVE 'ST7'        TO ACABP-CCAUOP
BPO168                 END-IF
BPO168              END-IF
BPO168           END-IF
BPO676        END-IF
APE001*-----------------------------------------------------------
APE001*- QUESTA MODIFICA E' STATA FATTA PER FAR PRENDERE LE ------
APE001*- NUOVE CONDIZIONI QUANDO SI TRATTA C/ATTESA CON SPESE OUR-
APE001*- CON CPROD = 'CE' O 'CR' MA LE STESSE CONDIZIONI VALGONO -
APE001*- ANCHE PER IL PROCESSO 104 CON CPROD = 'CR' IN QUESTO CASO
APE001*- DEVE PRENDERE LE CAUSALI DI CONTO CORRENTE PER CUI E' ---
APE001*- STATO NECESSARIO METTERE LA CONDIZIONE SUL PROCESSO   ---
APE001*-----------------------------------------------------------
IM0032*APE001        IF (OPE-TPCOLL NOT  = 'O' AND
IM0032*       IF ((OPE-TPCOLL NOT  = 'O' AND NOT = 'B') AND
IM0032        IF ((OPE-TPCOLL = 'O' OR = 'B') AND
APE001           (OPE-TPRDRV  = 'CE' OR
APE001            OPE-TPRDRV  = 'CU' OR
APE001            OPE-TPRDRV  = 'CR') AND
APE001            OPE-CPCS NOT = 104)
APE001           MOVE 'S'            TO ACABP-FLG-CARTA
IM0032           IF OPE-TPCOLL = 'B'
IM0032               MOVE 'B'        TO ACABP-FLG-CARTA
IM0032           END-IF
APE001           MOVE 'TGT'          TO ACABP-CIRCUITO
APE001        ELSE
APE001           MOVE SPACES TO ACABP-FLG-CARTA
IM0026           IF WRK-FLG-GEST-1 GREATER SPACES
IM0026              MOVE WRK-CIRCUITO  TO ACABP-CIRCUITO
IM0026           ELSE
IM0026              MOVE SPACES        TO ACABP-CIRCUITO
IM0026           END-IF
IM0026*APE001           MOVE SPACES TO ACABP-CIRCUITO
APE001        END-IF
IM0026*-----------------------------------------------------------
APE001*       MOVE SPACES TO ACABP-FLG-CARTA
APE001*       MOVE SPACES TO ACABP-CIRCUITO
IM0026        MOVE WRK-FLG-GEST-5 TO ACABP-CANALE
BPO168        PERFORM LEGGI-TBTACABP
BPO168           THRU LEGGI-TBTACABP-END
BPO168     END-IF
BPO288*BPO168     IF ABSC-CTIPSTC = 101 OR  111 OR  112 OR
BPO288*BPO168                102 OR  116 OR  103
BPO288     IF ABSC-CTIPSTC NOT = 400
BPO168        MOVE MOVE-CIST       TO ACABP-CIST
BPO199        IF WRK-TIPOSPS-255 = 'O'
BPO444*QUESTA MODIFICA SERVE PER DISTINGUERE LE SPESE BEN DALLE
BPO444*SPESE OUR NEL CASO DI RIFIUTO AUTOMATICO IN CUI SONO PRESENTI
BPO444*ENTRAMBI - L'IDEA Û CHE LE SPESE OUR SONO INDICATE NEL MOV 24
BPO444*E LE BEN NEL 23 SE SONO PRESENTI ENTRAMBI I MOVIMENTI
BPO444*ALTRIMENTI SE E' PRESENTE SOLO IL 23 TESTO IL FLAG MODALITA'
BPO444*SPESA - SE 'A' ALLORA SPESE BEN
BPO168           IF OPE-BCKFTIPOPE NOT = 3
BPO444              IF MOVE-NPRGMOVP = 24
BPO444                 MOVE 'BEN'        TO ACABP-CCAUOP
BPO444              ELSE
BPO444                IF MOVE-FMDDSPS NOT GREATER SPACES
BPO444                   MOVE 'OUR'        TO ACABP-CCAUOP
BPO444                ELSE
BPO444                   MOVE 'BEN'        TO ACABP-CCAUOP
BPO444                END-IF
BPO444              END-IF
BPO168           ELSE
BPO444              IF MOVE-NPRGMOVP = 24
BPO444                 MOVE 'ST8'        TO ACABP-CCAUOP
BPO444              ELSE
BPO444                IF MOVE-FMDDSPS NOT GREATER SPACES
BPO444                   MOVE 'ST1'        TO ACABP-CCAUOP
BPO444                ELSE
BPO444                   MOVE 'ST8'        TO ACABP-CCAUOP
BPO444                END-IF
BPO444              END-IF
BPO168           END-IF
BPO199        ELSE
BPO199           IF WRK-TIPOSPS-255 = 'B'
BPO199              IF OPE-BCKFTIPOPE NOT = 3
BPO199                 MOVE 'BEN'           TO ACABP-CCAUOP
BPO199              ELSE
BPO411*BPO199          MOVE 'ST1'           TO ACABP-CCAUOP
BPO411                 MOVE 'ST8'           TO ACABP-CCAUOP
BPO199              END-IF
BPO199           END-IF
BPO199        END-IF
APE001*-----------------------------------------------------------
APE001*- QUESTA MODIFICA E' STATA FATTA PER FAR PRENDERE LE ------
APE001*- NUOVE CONDIZIONI QUANDO SI TRATTA C/ATTESA CON SPESE OUR-
APE001*- CON CPROD = 'CE' O 'CR' MA LE STESSE CONDIZIONI VALGONO -
APE001*- ANCHE PER IL PROCESSO 104 CON CPROD = 'CR' IN QUESTO CASO
APE001*- DEVE PRENDERE LE CAUSALI DI CONTO CORRENTE PER CUI E' ---
APE001*- STATO NECESSARIO METTERE LA CONDIZIONE SUL PROCESSO   ---
APE001*-----------------------------------------------------------
IM0032*APE001        IF (OPE-TPCOLL NOT  = 'O' AND
IM0032*       IF ((OPE-TPCOLL NOT  = 'O' AND NOT = 'B') AND
IM0032        IF ((OPE-TPCOLL = 'O' OR = 'B') AND
APE001           (OPE-TPRDRV  = 'CE' OR
APE001            OPE-TPRDRV  = 'CU' OR
APE001            OPE-TPRDRV  = 'CR') AND
APE001            OPE-CPCS NOT = 104)
APE001           MOVE 'S'            TO ACABP-FLG-CARTA
IM0032           IF OPE-TPCOLL = 'B'
IM0032               MOVE 'B'        TO ACABP-FLG-CARTA
IM0032           END-IF
APE001           MOVE 'TGT'          TO ACABP-CIRCUITO
APE001        ELSE
APE001           MOVE SPACES TO ACABP-FLG-CARTA
IM0026           IF WRK-FLG-GEST-1 GREATER SPACES
IM0026              MOVE WRK-CIRCUITO  TO ACABP-CIRCUITO
IM0026           ELSE
IM0026              MOVE SPACES        TO ACABP-CIRCUITO
IM0026           END-IF
IM0026*APE001           MOVE SPACES TO ACABP-CIRCUITO
APE001        END-IF
APE001*       MOVE SPACES TO ACABP-FLG-CARTA
APE001*       MOVE SPACES TO ACABP-CIRCUITO
IM0026        MOVE WRK-FLG-GEST-5 TO ACABP-CANALE
BPO168        PERFORM LEGGI-TBTACABP
BPO168           THRU LEGGI-TBTACABP-END
BPO168        MOVE 'S'             TO WRK-SOUR-CSERV
           END-IF.
       IMPOSTA-CAUSALE-ECON-END.                                        07330000
           EXIT.                                                        07340000
      *
       R0050-INSERISCI-PRENOTATA.                                       04250000
           MOVE '00001'                     TO GEPP-ISTITUT.
           MOVE 'IN'                        TO GEPP-TIPORIC.
      *NESSUNA FORZATURA?
           MOVE '04'                        TO GEPP-MODALITA.
           MOVE KEY1-MOVP-NCCO   (IND1-1) TO GEPP-RAPPORT.
           MOVE KEY1-MOVP-CCAUNOP(IND1-1) TO GEPP-CAUSALE.
           MOVE KEY1-MOVP-CISO   (IND1-1) TO GEPP-DIVISA.
           MOVE SPACES                    TO W-DESCRIZIONE1.
           MOVE 'NRO OPERAZ.='            TO DESCR-MOV.
      *    MOVE 'ORD='                    TO VAL-ORDINANTE.
           MOVE '-'                       TO DESCR-X.
           MOVE KEY1-MOVP-DIPOPE (IND1-1) TO DESCR-CDPZ.
           MOVE KEY1-MOVP-NUMOPE (IND1-1) TO DESCR-NUMOPE.
      *----------------------------- GIRI TRA BANCHE IN EURO
           IF OPE-CPCS = 0932
              IF KEY1-MOVP-TMOV (IND1-1) = 2
                 MOVE WRK-ZRAGSOCO        TO DESCR-ORDINANTE1
                 MOVE WRK-ZINDO           TO DESCR-ORDINANTE2
                 MOVE 'ORD='              TO VAL-ORDINANTE
              END-IF
              IF KEY1-MOVP-TMOV (IND1-1) = 1
                 MOVE WRK-ZRAGSOCO-110    TO DESCR-ORDINANTE1
                 MOVE WRK-ZINDO-120       TO DESCR-ORDINANTE2
                 MOVE 'BEN='              TO VAL-ORDINANTE
              END-IF
           ELSE
              MOVE WRK-ZRAGSOCO-110       TO DESCR-ORDINANTE1
              MOVE WRK-ZINDO-120          TO DESCR-ORDINANTE2
              IF KEY1-MOVP-TMOV (IND1-1) = 2
                 MOVE 'ORD='              TO VAL-ORDINANTE
              END-IF
              IF KEY1-MOVP-TMOV (IND1-1) = 1
                 MOVE 'BEN='              TO VAL-ORDINANTE
              END-IF
           END-IF
BPO679*PER 1005 IMPOSTO DESCRIZIONI E DIPOPE E NUMOPE OPERAZIONE
BPO679*ORIGINARIA SE OPERAZIONE E' COLLEGATA
BPO679     IF OPE-CPCS = 1005
BPO679        IF  WRK-FLAG-OPECOLL = 'N'
BPO679            MOVE SPACES            TO W-DESCRIZIONE1
BPO679            MOVE 'SPESE BONIFICO ESTERO '
BPO679             TO  DESCR-SPESE-BON
BPO679        ELSE
BPO679            IF WRK-CDPZ-OPECOLL  = 55111
BPO679               MOVE SPACES               TO W-DESCRIZIONE1
BPO679               MOVE '-'                  TO DESCR-X-1
BPO679               MOVE WRK-CDPZ-OPECOLL     TO DESCR-CDPZ-1
BPO679               MOVE WRK-NUMOPE-OPECOLL   TO DESCR-NUMOPE-1
BPO745               IF OPE-FLUSSOPRV = 'SPESE'
BPO745                  MOVE 'NRO OPERAZ. = ' TO DESCR-SPESE-BON
BPO745               ELSE
BPO679                 MOVE 'SPESE RECLAMATE DA BANCA ESTERA BONIFICO'
BPO679                     TO  DESCR-SPESE-BON
BPO745               END-IF
BPO679            ELSE
BPO679               IF WRK-CDPZ-OPECOLL  = 311
BPO679                  MOVE SPACES              TO W-DESCRIZIONE1
BPO679                  MOVE '-'                 TO DESCR-X-1
BPO679                  MOVE WRK-CDPZ-OPECOLL    TO DESCR-CDPZ-1
BPO679                  MOVE WRK-NUMOPE-OPECOLL  TO DESCR-NUMOPE-1
BPO679                  MOVE 'SPESE BONIFICO ESTERO '
BPO679                        TO  DESCR-SPESE-BON
BPO679              END-IF
BPO679            END-IF
BPO679        END-IF
BPO679     END-IF
           MOVE W-DESCRIZIONE1            TO GEPP-DESCRIZ(1:34)
           MOVE W-DESCRIZIONE2            TO GEPP-DESCRIZ(66:)
BPO893*----------------------------- ACCREDITO CON PRENOTATA
BPO893     IF OPE-CPCS = 0131
BPO893        MOVE SPACES              TO W-DESCRIZIONE1
BPO893        MOVE SPACES              TO W-DESCRIZIONE2
BPO893        MOVE 'IMPORTO NON DISPONIBILE SU RICHIES'
BPO893                                 TO  W-DESCRIZIONE1 (1:34)
BPO893        MOVE 'TA SERVIZIO TRASFERIMENTO FONDI'
BPO893                                 TO  W-DESCRIZIONE1 (35:)
BPO893        MOVE W-DESCRIZIONE1      TO GEPP-DESCRIZ
BPO893     END-IF.
           MOVE ZEROES                        TO WRK-SOMMA-SPESE
           PERFORM VARYING IND1-2 FROM 1 BY 1                           04880000
             UNTIL IND1-2 > MAX-IND1-2
             OR KEY1-MOVP-ICTVLIS(IND1-1,IND1-2) NOT GREATER ZEROES     04890000
BPO668       IF WRK-SOMMA-SPESE EQUAL ZEROES
BPO668          AND KEY1-MOVP-TMOV (IND1-1) = 2
BPO668          MOVE KEY1-MOVP-ICTVLIS(IND1-1,IND1-2) TO WRK-IMPMOVP
BPO668       END-IF
             IF KEY1-MOVP-FLAGDA(IND1-1,IND1-2) = 'A'
                COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE +
                              KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)
             ELSE
                COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE -
                              KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)
             END-IF
           END-PERFORM
BPO893     MOVE WRK-SOMMA-SPESE TO WRK-IMPMOVP-131
BPO668     IF KEY1-MOVP-TMOV (IND1-1) = 1
BPO912*------------- BONIFICO IN EURO CERTO E DIVISA = EUR NON DEVE
BPO912*------------- APPLICARE LA PERCENTUALE DI PRENOTAZIONE FONDI
BPO912*       IF (OPE-CPCS = 1620
BPO912*           AND KEY1-MOVP-CISO (IND1-1) = 'EUR')
BPO912*          COMPUTE WRK-SOMMA-SPESE =
BPO912*                  WRK-SOMMA-SPESE * (10 ** 3)
BPO912*       ELSE
      ****PER OPERAZIONE SOSPESA DEVO MAGGIORARE L'IMPORTO DA PRENOTARE
      ****DI UNA PERCENTUALE STABILITA A LIVELLOD DI CONFIGURAZIONE
APE004*BPO912        IF OPE-CPCS NOT = 1620
APE004        IF OPE-CPCS NOT = 1620 AND 2120
                 COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE +
                                  (WRK-SOMMA-SPESE * ISTI-PSCAPRF/100)
BPO912        END-IF
BPO668     ELSE
BPO668**IN CASO DI ACCREDITO CON IMPORTO SPESE  > IMPORTO ORDINE
BPO668**PER CALCOLARE LA SOMMA DA PRENOTARE A WRK-SOMMA-SPESE
BPO668**SI TOGLIE L'IMPORTO DEL MOVIMENTO PRINCIPALE IN MODO DA
BPO668**OTENERE LA SOMMA DELLE SPESE SI CALCOLA E AGGINGE LA PERCENTUALE
BPO668**DI SCARTO E POI SI RIAGGIUNGE L'IMPORTO PRINCIPALE
BPO668        COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE - WRK-IMPMOVP
BPO893*------------- BONIFICO IN EURO IN ACCREDITO CON PRENOTATA
BPO893*------------- PROCESSO 131 E DIVISA = EUR PER NON
BPO893*------------- APPLICARE LA PERCENTUALE DI PRENOTAZIONE FONDI
BPO893*------------- SALVARE L'IMPORTO IN WRK-IMPMOVP-131
BPO893*       MOVE WRK-SOMMA-SPESE TO WRK-IMPMOVP-131
BPO893*---------------
BPO668        COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE +
BPO668                              (WRK-SOMMA-SPESE * ISTI-PSCAPRF/100)
BPO668        COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE + WRK-IMPMOVP
BPO893*       IF OPE-CPCS = 0131 AND
BPO893*          KEY1-MOVP-CISO (IND1-1) = 'EUR'
BPO893*          MOVE WRK-IMPMOVP-131  TO WRK-SOMMA-SPESE
BPO893*       END-IF
BPO668     END-IF
BPO893     IF OPE-CPCS = 0131 AND
BPO893        KEY1-MOVP-CISO (IND1-1) = 'EUR'
BPO893        MOVE WRK-IMPMOVP-131  TO WRK-SOMMA-SPESE
BPO893     END-IF
           PERFORM R0052-ARR-IMPPRE
              THRU R0052-ARR-IMPPRE-END
           MOVE WRK-SOMMA-SPESE2            TO GEPP-IMPOPER
           IF WRK-SOMMA-SPESE < ZEROES
              MOVE 'D'                      TO GEPP-FLAGDA
           ELSE
              MOVE 'A'                      TO GEPP-FLAGDA
           END-IF
BPO893     IF OPE-CPCS = 0131
BPO893        MOVE 'D'                      TO GEPP-FLAGDA
BPO947*FORZATURA '03' - FORZA SIA BLOCCHI CHE SCONFINO
BPO950*CAUSALE PER ANTITERRORISMO VARIATA DA '48E' A 'VTR' (FISSA)
BPO947* IN CASO DI ACCREDITO CON PRENOTAZIONE
BPO950        MOVE 'VTR'                    TO GEPP-CAUSALE
BPO947        MOVE '03'                     TO GEPP-MODALITA
BPO893     END-IF.
      *CAMPI CHE SERVONO PER PRENOTATE IN CASO DI ASSEGNO
           MOVE SPACES                      TO GEPP-TIPORIF.
           MOVE ZEROES                      TO GEPP-NUMRIF.
           MOVE ZEROES                      TO GEPP-DATRIFE.
      *
           MOVE WCM-DATA-SIS                TO GEPP-DATAIMM
           MOVE WCM-ORA-SIS                 TO GEPP-ORAIMM
           MOVE WRK-TERMIMM                 TO GEPP-TERMIMM
           MOVE WRK-DIPEIMM                 TO GEPP-DIPEIMM
           MOVE OPE-NMTRUTE                 TO GEPP-COPERIM
           MOVE SPACES                      TO GEPP-FLAG-STOR
           MOVE ZEROES                      TO GEPP-NUMOPE-INP
           MOVE 'S'                         TO WRK-FLAG-PRE
           PERFORM CHIAMA-PPTOGEPP
              THRU CHIAMA-PPTOGEPP-END.
      *
       R0050-INSERISCI-PRENOTATA-END.                                   04250000
           EXIT.                                                        07340000
      *--------------------------------------------------------------   07350000
       R0052-ARR-IMPPRE.                                                07360000
           MOVE WRK-SOMMA-SPESE       TO WRK-APP-3DEC
           MOVE WRK-SOMMA-SPESE       TO WRK-APP-2DEC
           COMPUTE WRK-APP-DIF = WRK-APP-3DEC - WRK-APP-2DEC
           IF WRK-APP-DIF > 0,005
              IF WRK-SOMMA-SPESE < 0
                 COMPUTE WRK-SOMMA-SPESE2 = WRK-SOMMA-SPESE - 0,01
              ELSE
                 COMPUTE WRK-SOMMA-SPESE2 = WRK-SOMMA-SPESE + 0,01
              END-IF
           ELSE
              MOVE WRK-SOMMA-SPESE       TO WRK-SOMMA-SPESE2
           END-IF.
       R0052-ARR-IMPPRE-END.                                            04250000
           EXIT.                                                        07340000
      *--------------------------------------------------------------   07350000
       R0055-INSERT-AMOVCC.                                             07360000
                                                                        07370000
           EXEC SQL INCLUDE ZMV47301  END-EXEC.                         07380000
                                                                        07390000
           IF NOT W-SQL-OK                                              07400000
              MOVE 8                   TO W-FLAG-ERR                    07410000
              MOVE '9999'              TO W-COD-ERR                     07420000
              MOVE 'TBAMOVCC'          TO L-NOME-TABELLA                07430000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  07440000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      07450000
              MOVE 'ZMV47301'          TO L-SUB-MODULO                  07460000
              PERFORM 9999-GESTIONE-ERRORE                              07470000
                 THRU 9999-GESTIONE-ERRORE-END                          07480000
              GO TO FINE                                                07490000
           END-IF.                                                      07500000
                                                                        07510000
       R0055-INSERT-AMOVCC-END.                                         07520000
           EXIT.                                                        07530000
      *--------------------------------------------------------------   07350000
BPO999 R0055-IN-UPD-AMOVCC.                                             07360000
BPO999                                                                  07370000
BPO999     EXEC SQL INCLUDE ZMV47301  END-EXEC.                         07380000
BPO999     IF W-SQL-DOPPIO                                              07390000
BPO999                                                                  07390000
BPO999      PERFORM R0057-SELECT-AMOVCC-NUMP
BPO999         THRU R0057-SELECT-AMOVCC-NUMP-END
BPO999
BPO999      IF MOVCC-NUMPRECC > 0
BPO999
BPO999         MOVE MOVCC-NUMPRECC    TO GEPP-NUMOPE-INP
BPO999
BPO999         PERFORM R0060B-ANNULLA-PRENOTATA                         07390000
BPO999            THRU R0060B-ANNULLA-PRENOTATA-END                     07390000
BPO999            MOVE 0              TO MOVCC-IMPPRE
BPO999            MOVE 0              TO MOVCC-NUMPRECC
BPO999            EXEC SQL INCLUDE ZMU47301  END-EXEC.                  07380000
BPO999            IF NOT W-SQL-OK                                       07400000
BPO999             MOVE 8                   TO W-FLAG-ERR               07410000
BPO999             MOVE '9999'              TO W-COD-ERR                07420000
BPO999             MOVE 'TBAMOVCC'          TO L-NOME-TABELLA           07430000
BPO999             MOVE W-SQLCODE           TO L-CODICE-SQL             07440000
BPO999             MOVE 'ZMBAGGCC'          TO L-MODULO                 07450000
BPO999             MOVE 'ZMU47301'          TO L-SUB-MODULO             07460000
BPO999             PERFORM 9999-GESTIONE-ERRORE                         07470000
BPO999                THRU 9999-GESTIONE-ERRORE-END                     07480000
BPO999             GO TO FINE                                           07490000
BPO999            END-IF                                                07380000
BPO999            GO TO R0055-IN-UPD-AMOVCC-END                         07380000
BPO999      ELSE                                                        07410000
BPO999         MOVE 8                   TO W-FLAG-ERR                   07410000
BPO999         MOVE '9999'              TO W-COD-ERR                    07420000
BPO999         MOVE 'TBAMOVCC'          TO L-NOME-TABELLA               07430000
BPO999         MOVE W-SQLCODE           TO L-CODICE-SQL                 07440000
BPO999         MOVE 'ZMBAGGCC'          TO L-MODULO                     07450000
BPO999         MOVE 'ZMV47301'          TO L-SUB-MODULO                 07460000
BPO999         PERFORM 9999-GESTIONE-ERRORE                             07470000
BPO999            THRU 9999-GESTIONE-ERRORE-END                         07480000
BPO999            GO TO FINE                                            07490000
BPO999      END-IF                                                      07380000
BPO999     ELSE                                                         07400000
BPO999        IF NOT W-SQL-OK                                           07410000
BPO999         MOVE 8                   TO W-FLAG-ERR                   07410000
BPO999         MOVE '9999'              TO W-COD-ERR                    07420000
BPO999         MOVE 'TBAMOVCC'          TO L-NOME-TABELLA               07430000
BPO999         MOVE W-SQLCODE           TO L-CODICE-SQL                 07440000
BPO999         MOVE 'ZMBAGGCC'          TO L-MODULO                     07450000
BPO999         MOVE 'ZMV47301'          TO L-SUB-MODULO                 07460000
BPO999         PERFORM 9999-GESTIONE-ERRORE                             07470000
BPO999            THRU 9999-GESTIONE-ERRORE-END                         07480000
BPO999         GO TO FINE                                               07490000
BPO999     END-IF.                                                      07500000
BPO999                                                                  07510000
BPO999 R0055-IN-UPD-AMOVCC-END.                                         07520000
BPO999     EXIT.                                                        07530000
      *--------------------------------------------------------------   07350000
       R0057-SELECT-AMOVCC.                                             07360000
                                                                        07370000
           EXEC SQL INCLUDE ZMS47301  END-EXEC.                         07380000
                                                                        07390000
           IF NOT W-SQL-OK                                              07400000
              AND NOT W-SQL-NON-TROVATO
              MOVE 8                   TO W-FLAG-ERR                    07410000
              MOVE '9999'              TO W-COD-ERR                     07420000
              MOVE 'TBAMOVCC'          TO L-NOME-TABELLA                07430000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  07440000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      07450000
              MOVE 'ZMS47301'          TO L-SUB-MODULO                  07460000
              PERFORM 9999-GESTIONE-ERRORE                              07470000
                 THRU 9999-GESTIONE-ERRORE-END                          07480000
              GO TO FINE                                                07490000
           END-IF.                                                      07500000
                                                                        07510000
       R0057-SELECT-AMOVCC-END.                                         07520000
           EXIT.                                                        07530000
      *
BPO999 R0057-SELECT-AMOVCC-NUMP.                                        07360000
BPO999                                                                  07370000
BPO999     EXEC SQL INCLUDE ZMS47305  END-EXEC.                         07380000
BPO999                                                                  07390000
BPO999     IF NOT W-SQL-OK                                              07400000
BPO999        AND NOT W-SQL-NON-TROVATO
BPO999        MOVE 8                   TO W-FLAG-ERR                    07410000
BPO999        MOVE '9999'              TO W-COD-ERR                     07420000
BPO999        MOVE 'TBAMOVCC'          TO L-NOME-TABELLA                07430000
BPO999        MOVE W-SQLCODE           TO L-CODICE-SQL                  07440000
BPO999        MOVE 'ZMBAGGCC'          TO L-MODULO                      07450000
BPO999        MOVE 'ZMS47305'          TO L-SUB-MODULO                  07460000
BPO999        PERFORM 9999-GESTIONE-ERRORE                              07470000
BPO999           THRU 9999-GESTIONE-ERRORE-END                          07480000
BPO999        GO TO FINE                                                07490000
BPO999     END-IF.                                                      07500000
BPO999                                                                  07510000
BPO999 R0057-SELECT-AMOVCC-NUMP-END.                                    07520000
BPO999     EXIT.                                                        07530000
      *
BPOA04 R0060-ANNULLA-PREN-EURO.                                         04250000
BPOA04
BPOA04     MOVE KEY1-MOVP-NPRGMOVP(IND1-1)      TO MOVCC-NPRGMOVP.
BPOA04     MOVE KEY1-MOVP-NSUBMOVP(IND1-1)       TO MOVCC-NSUBMOVP.
BPOA04*---------------------------------------------------------*
BPOA04*- IN CASO DI ANNULLO E STORNO DEL CPCS 131 --------------*
BPOA04*- (ACCREDITO CON PRENOTATA IN DARE PER ANTITERRORISMO)---*
BPOA04*- SI MUOVE 23 NEL NUMERO PROGRESSIVO DEL MOVIMENTO    ---*
BPOA04*---------------------------------------------------------*
BPOA04     IF OPE-CPCS = 0131 OR
BPOA04      (OPE-BCKFTIPOPE = 3 AND OPE-CPCSORI = 131)
BPOA04       MOVE 23    TO MOVCC-NPRGMOVP
BPOA04     END-IF
BPOA04
BPOA04     PERFORM R0057-SELECT-AMOVCC
BPOA04        THRU R0057-SELECT-AMOVCC-END
BPOA04
BPOA04     IF W-SQL-OK
BPOA04        MOVE MOVCC-NUMPRECC           TO GEPP-NUMOPE-INP
BPOA04     END-IF.
BPOA04*NON TROVA LA PRENOTAZIONE IN FASE DI RIVALORIZZAZIONE
BPO770*PERCHE IL CAMBIO PRECEDENTE NON LA RENDEVA NECESSARIA
BPOA04*E NON E STATA INSERITA
BPOA04     IF W-SQL-NON-TROVATO
BPOA04     AND L-MODULO(1:6) = 'RIVALO'
BPOA04       MOVE 'SI'  TO WRK-SALTA-GEPP
BPOA04       GO TO R0060-ANNULLA-PREN-EURO-END
BPOA04     END-IF
BPOA04     IF GEPP-NUMOPE-INP GREATER ZEROES
BPOA04        MOVE '00001'                     TO GEPP-ISTITUT
BPOA04        MOVE 'AN'                        TO GEPP-TIPORIC
BPOA04        MOVE SPACES                      TO GEPP-MODALITA
BPOA04        MOVE KEY1-MOVP-NCCO (IND1-1) TO GEPP-RAPPORT
BPOA04        MOVE KEY1-MOVP-CISO (IND1-1) TO GEPP-DIVISA
BPOA04        MOVE WCM-DATA-SIS                TO GEPP-DATAIMM
BPOA04        MOVE WCM-ORA-SIS                 TO GEPP-ORAIMM
BPOA04        MOVE WRK-TERMIMM                 TO GEPP-TERMIMM
BPOA04        MOVE WRK-DIPEIMM                 TO GEPP-DIPEIMM
BPOA04        MOVE OPE-NMTRUTE                 TO GEPP-COPERIM
BPOA04*CAMPI CHE SERVONO PER PRENOTATE IN CASO DI ASSEGNO
BPOA04        MOVE SPACES                      TO GEPP-TIPORIF
BPOA04        MOVE ZEROES                      TO GEPP-NUMRIF
BPOA04        MOVE ZEROES                      TO GEPP-DATRIFE
BPOA04        MOVE 'A'                         TO WRK-FLAG-PRE
BPOA04     ELSE
BPOA04        MOVE '00001'                       TO GEPP-ISTITUT
BPOA04        MOVE 'AN'                          TO GEPP-TIPORIC
BPOA04        MOVE SPACES                        TO GEPP-MODALITA
BPOA04        MOVE KEY1-MOVP-CCAUNOP(IND1-1) TO GEPP-CAUSALE
BPOA04        MOVE KEY1-MOVP-NCCO   (IND1-1) TO GEPP-RAPPORT
BPOA04        MOVE KEY1-MOVP-CISO   (IND1-1) TO GEPP-DIVISA
BPOA04        PERFORM VARYING IND1-2 FROM 1 BY 1                        04880000
BPOA04          UNTIL IND1-2 > MAX-IND1-2
BPOA04          OR KEY1-MOVP-ICTVLIS(IND1-1,IND1-2) NOT GREATER ZEROES  04890000
BPOA04          IF KEY1-MOVP-FLAGDA(IND1-1,IND1-2)= 'A'
BPOA04             COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE +
BPOA04                        KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)
BPOA04          ELSE
BPOA04             COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE -
BPOA04                        KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)
BPOA04          END-IF
BPOA04        END-PERFORM
BPOA04****PER OPERAZIONE SOSPESA DEVO MAGGIORARE L'IMPORTO DA PRENOTARE
BPOA04****DI UNA PERCENTUALE STABILITA A LIVELLOD DI CONFIGURAZIONE
BPOA04        COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE +
BPOA04                              (WRK-SOMMA-SPESE * ISTI-PSCAPRF/100)
BPOA04        MOVE WRK-SOMMA-SPESE             TO GEPP-IMPOPER
BPOA04        IF WRK-SOMMA-SPESE < ZEROES
BPOA04           MOVE 'D'                      TO GEPP-FLAGDA
BPOA04        ELSE
BPOA04           MOVE 'A'                      TO GEPP-FLAGDA
BPOA04        END-IF
BPOA04        MOVE WCM-DATA-SIS                TO GEPP-DATAIMM
BPOA04        MOVE WCM-ORA-SIS                 TO GEPP-ORAIMM
BPOA04        MOVE WRK-TERMIMM                 TO GEPP-TERMIMM
BPOA04        MOVE WRK-DIPEIMM                 TO GEPP-DIPEIMM
BPOA04        MOVE OPE-NMTRUTE                 TO GEPP-COPERIM
BPOA04*CAMPI CHE SERVONO PER PRENOTATE IN CASO DI ASSEGNO
BPOA04        MOVE SPACES                      TO GEPP-TIPORIF
BPOA04        MOVE ZEROES                      TO GEPP-NUMRIF
BPOA04        MOVE ZEROES                      TO GEPP-DATRIFE
BPOA04        MOVE 'A'                         TO WRK-FLAG-PRE
BPOA04     END-IF
BPOA04     PERFORM CHIAMA-PPTOGEPP
BPOA04        THRU CHIAMA-PPTOGEPP-END.
BPOA04*    IF GEPP-RETCODE = 'OK'
BPOA04*       MOVE 'S'                         TO WRK-FLAG-ANNPRE
BPOA04*    END-IF.
BPOA04*
BPOA04 R0060-ANNULLA-PREN-EURO-END.                                     04250000
BPOA04     EXIT.                                                        07340000
       R0060-ANNULLA-PRENOTATA.                                         04250000

           MOVE KEY1-MOVP-NPRGMOVP(IND1-1)      TO MOVCC-NPRGMOVP.
           MOVE KEY1-MOVP-NSUBMOVP(IND1-1)       TO MOVCC-NSUBMOVP.
BPO893*---------------------------------------------------------*
BPO893*- IN CASO DI ANNULLO E STORNO DEL CPCS 131 --------------*
BPO893*- (ACCREDITO CON PRENOTATA IN DARE PER ANTITERRORISMO)---*
BPO893*- SI MUOVE 23 NEL NUMERO PROGRESSIVO DEL MOVIMENTO    ---*
BPO893*---------------------------------------------------------*
BPOA04*BPO893     IF OPE-CPCS = 0131 OR
BPOA04*BPO893       (OPE-BCKFTIPOPE = 3 AND OPE-CPCSORI = 131)
BPOA04*BPO893        MOVE 23    TO MOVCC-NPRGMOVP
BPOA04*BPO893     END-IF

           PERFORM R0057-SELECT-AMOVCC
              THRU R0057-SELECT-AMOVCC-END

           IF W-SQL-OK
              MOVE MOVCC-NUMPRECC           TO GEPP-NUMOPE-INP
           END-IF.
BPO770*NON TROVA LA PRENOTAZIONE IN FASE DI RIVALORIZZAZIONE
BPO770*PERCHE IL CAMBIO PRECEDENTE NON LA RENDEVA NECESSARIA
BPO770*E NON E STATA INSERITA
BPO770     IF W-SQL-NON-TROVATO
BPO770     AND L-MODULO(1:6) = 'RIVALO'
BPO770       MOVE 'SI'  TO WRK-SALTA-GEPP
BPO770       GO TO R0060-ANNULLA-PRENOTATA-END
BPO770     END-IF
           IF GEPP-NUMOPE-INP GREATER ZEROES
              MOVE '00001'                     TO GEPP-ISTITUT
              MOVE 'AN'                        TO GEPP-TIPORIC
              MOVE SPACES                      TO GEPP-MODALITA
              MOVE KEY1-MOVP-NCCO (IND1-1) TO GEPP-RAPPORT
              MOVE KEY1-MOVP-CISO (IND1-1) TO GEPP-DIVISA
              MOVE WCM-DATA-SIS                TO GEPP-DATAIMM
              MOVE WCM-ORA-SIS                 TO GEPP-ORAIMM
              MOVE WRK-TERMIMM                 TO GEPP-TERMIMM
              MOVE WRK-DIPEIMM                 TO GEPP-DIPEIMM
              MOVE OPE-NMTRUTE                 TO GEPP-COPERIM
      *CAMPI CHE SERVONO PER PRENOTATE IN CASO DI ASSEGNO
              MOVE SPACES                      TO GEPP-TIPORIF
              MOVE ZEROES                      TO GEPP-NUMRIF
              MOVE ZEROES                      TO GEPP-DATRIFE
              MOVE 'A'                         TO WRK-FLAG-PRE
           ELSE
              MOVE '00001'                       TO GEPP-ISTITUT
              MOVE 'AN'                          TO GEPP-TIPORIC
              MOVE SPACES                        TO GEPP-MODALITA
              MOVE KEY1-MOVP-CCAUNOP(IND1-1) TO GEPP-CAUSALE
              MOVE KEY1-MOVP-NCCO   (IND1-1) TO GEPP-RAPPORT
              MOVE KEY1-MOVP-CISO   (IND1-1) TO GEPP-DIVISA
              PERFORM VARYING IND1-2 FROM 1 BY 1                        04880000
                UNTIL IND1-2 > MAX-IND1-2
                OR KEY1-MOVP-ICTVLIS(IND1-1,IND1-2) NOT GREATER ZEROES  04890000
                IF KEY1-MOVP-FLAGDA(IND1-1,IND1-2)= 'A'
                   COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE +
                              KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)
                ELSE
                   COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE -
                              KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)
                END-IF
              END-PERFORM
      ****PER OPERAZIONE SOSPESA DEVO MAGGIORARE L'IMPORTO DA PRENOTARE
      ****DI UNA PERCENTUALE STABILITA A LIVELLOD DI CONFIGURAZIONE
              COMPUTE WRK-SOMMA-SPESE = WRK-SOMMA-SPESE +
                                    (WRK-SOMMA-SPESE * ISTI-PSCAPRF/100)
              MOVE WRK-SOMMA-SPESE             TO GEPP-IMPOPER
              IF WRK-SOMMA-SPESE < ZEROES
                 MOVE 'D'                      TO GEPP-FLAGDA
              ELSE
                 MOVE 'A'                      TO GEPP-FLAGDA
              END-IF
              MOVE WCM-DATA-SIS                TO GEPP-DATAIMM
              MOVE WCM-ORA-SIS                 TO GEPP-ORAIMM
              MOVE WRK-TERMIMM                 TO GEPP-TERMIMM
              MOVE WRK-DIPEIMM                 TO GEPP-DIPEIMM
              MOVE OPE-NMTRUTE                 TO GEPP-COPERIM
      *CAMPI CHE SERVONO PER PRENOTATE IN CASO DI ASSEGNO
              MOVE SPACES                      TO GEPP-TIPORIF
              MOVE ZEROES                      TO GEPP-NUMRIF
              MOVE ZEROES                      TO GEPP-DATRIFE
              MOVE 'A'                         TO WRK-FLAG-PRE
           END-IF
           PERFORM CHIAMA-PPTOGEPP
              THRU CHIAMA-PPTOGEPP-END.
      *    IF GEPP-RETCODE = 'OK'
      *       MOVE 'S'                         TO WRK-FLAG-ANNPRE
      *    END-IF.
      *
       R0060-ANNULLA-PRENOTATA-END.                                     04250000
           EXIT.                                                        07340000
BPO999 R0060B-ANNULLA-PRENOTATA.                                        04250000
BPO999*VALE SOLO PER ANNULLAMENTO PRENOTATA BONIFICI IN ARRIVO
BPO999*NEL CASO IN FASE DI RIVALORIZZAZIONE IMP BONIFICO MAGGIORE
BPO999*SPESE MENTRE ERA STATA FATTA LA PRENOTAZIONE
BPO999     MOVE KEY1-MOVP-NPRGMOVP(IND1-1)      TO MOVCC-NPRGMOVP.
BPO999     MOVE KEY1-MOVP-NSUBMOVP(IND1-1)      TO MOVCC-NSUBMOVP.
BPO999     MOVE MOVCC-NUMPRECC TO GEPP-NUMOPE-INP
BPO999     MOVE '00001'                     TO GEPP-ISTITUT
BPO999     MOVE 'AN'                        TO GEPP-TIPORIC
BPO999     MOVE SPACES                      TO GEPP-MODALITA
BPO999     MOVE KEY1-MOVP-NCCO (IND1-1) TO GEPP-RAPPORT
BPO999     MOVE KEY1-MOVP-CISO (IND1-1) TO GEPP-DIVISA
BPO999     MOVE WCM-DATA-SIS                TO GEPP-DATAIMM
BPO999     MOVE WCM-ORA-SIS                 TO GEPP-ORAIMM
BPO999     MOVE WRK-TERMIMM                 TO GEPP-TERMIMM
BPO999     MOVE WRK-DIPEIMM                 TO GEPP-DIPEIMM
BPO999     MOVE OPE-NMTRUTE                 TO GEPP-COPERIM
BPO999*CAMPI CHE SERVONO PER PRENOTATE IN CASO DI ASSEGNO
BPO999     MOVE SPACES                      TO GEPP-TIPORIF
BPO999     MOVE ZEROES                      TO GEPP-NUMRIF
BPO999     MOVE ZEROES                      TO GEPP-DATRIFE
BPO999     MOVE 'A'                         TO WRK-FLAG-PRE
BPO999     PERFORM CHIAMA-PPTOGEPP
BPO999        THRU CHIAMA-PPTOGEPP-END.
BPO999 R0060B-ANNULLA-PRENOTATA-END.                                    04250000
BPO999     EXIT.                                                        07340000
      *
       R0070-AGGIORNA-CC.                                               04250000
           INITIALIZE AREA-SV2P.
           MOVE '00001'                     TO SV2P-ISTITUT.
           IF OPE-BCKFTIPOPE = 1 OR 3
              MOVE '01'                     TO SV2P-TIPORIC
           ELSE
              IF OPE-BCKFTIPOPE = 2
                 MOVE '02'                  TO SV2P-TIPORIC
              END-IF
           END-IF
           MOVE KEY1-MOVP-CODOPE(IND1-1) TO SV2P-CODOPE.
           MOVE WCM-DATA-SIS                 TO SV2P-DATAIMM
           MOVE WCM-ORA-SIS                  TO SV2P-ORAIMM
           MOVE WRK-TERMIMM                  TO SV2P-TERMIMM
           MOVE WRK-DIPEIMM                  TO SV2P-DIPEIMM
           MOVE WRK-COPERIM                  TO SV2P-COPERIM
           MOVE KEY1-MOVP-DCON(IND1-1)       TO SV2P-DATCONT
           MOVE SPACES                       TO W-DESCRIZIONE1.
           MOVE 'NRO OPERAZ.='               TO DESCR-MOV.
           MOVE '-'                          TO DESCR-X.
      *    MOVE 'ORD='                       TO VAL-ORDINANTE.
           MOVE KEY1-MOVP-DIPOPE (IND1-1)    TO DESCR-CDPZ.
           MOVE KEY1-MOVP-NUMOPE (IND1-1)    TO DESCR-NUMOPE.
      *----------------------------- GIRI TRA BANCHE IN EURO
           IF OPE-CPCS = 0932
              IF KEY1-MOVP-TMOV (IND1-1) = 2
                 MOVE WRK-ZRAGSOCO        TO DESCR-ORDINANTE1
                 MOVE WRK-ZINDO           TO DESCR-ORDINANTE2
                 MOVE 'ORD='              TO VAL-ORDINANTE
              END-IF
              IF KEY1-MOVP-TMOV (IND1-1) = 1
                 MOVE WRK-ZRAGSOCO-110    TO DESCR-ORDINANTE1
                 MOVE WRK-ZINDO-120       TO DESCR-ORDINANTE2
                 MOVE 'BEN='              TO VAL-ORDINANTE
              END-IF
           ELSE
              MOVE WRK-ZRAGSOCO-110       TO DESCR-ORDINANTE1
              MOVE WRK-ZINDO-120          TO DESCR-ORDINANTE2
              IF KEY1-MOVP-TMOV (IND1-1) = 2
                 MOVE 'ORD='              TO VAL-ORDINANTE
              END-IF
              IF KEY1-MOVP-TMOV (IND1-1) = 1
                 MOVE 'BEN='              TO VAL-ORDINANTE
              END-IF
           END-IF
BPO679*PER 1005 IMPOSTO DESCRIZIONI E DIPOPE E NUMOPE OPERAZIONE
BPO679*ORIGINARIA SE OPERAZIONE E' COLLEGATA
BPO679     IF OPE-CPCS = 1005
BPO679        IF  WRK-FLAG-OPECOLL = 'N'
BPO679            MOVE SPACES            TO W-DESCRIZIONE1
BPO679            MOVE 'SPESE BONIFICO ESTERO '
BPO679             TO  DESCR-SPESE-BON
BPO679        ELSE
BPO679            IF WRK-CDPZ-OPECOLL  = 55111
BPO679               MOVE SPACES               TO W-DESCRIZIONE1
BPO679               MOVE '-'                  TO DESCR-X-1
BPO679               MOVE WRK-CDPZ-OPECOLL     TO DESCR-CDPZ-1
BPO679               MOVE WRK-NUMOPE-OPECOLL   TO DESCR-NUMOPE-1
BPO745               IF OPE-FLUSSOPRV = 'SPESE'
BPO745                  MOVE 'NRO OPERAZ. = ' TO DESCR-SPESE-BON
BPO745               ELSE
BPO679                 MOVE 'SPESE RECLAMATE DA BANCA ESTERA BONIFICO'
BPO679                     TO  DESCR-SPESE-BON
BPO745               END-IF
BPO679            ELSE
BPO679               IF WRK-CDPZ-OPECOLL  = 311
BPO679                  MOVE SPACES              TO W-DESCRIZIONE1
BPO679                  MOVE '-'                 TO DESCR-X-1
BPO679                  MOVE WRK-CDPZ-OPECOLL    TO DESCR-CDPZ-1
BPO679                  MOVE WRK-NUMOPE-OPECOLL  TO DESCR-NUMOPE-1
BPO679                  MOVE 'SPESE BONIFICO ESTERO '
BPO679                        TO  DESCR-SPESE-BON
BPO679              END-IF
BPO679            END-IF
BPO679        END-IF
BPO679     END-IF
BPO751*PER 2276 PER OPERAZIONE DI RECALL DEVE ESSERE PASSATO IL
BPO751*RIFERIMENTO ALL'OPERAZIONE ORGINARIA OPE-CDPZOPEST, OPE-NOPEST
BPO751     IF OPE-CPCS = 2276
BPO751        MOVE SPACES              TO W-DESCRIZIONE1
BPO751        MOVE '-'                 TO DESCR-X-1
BPO751        MOVE WRK-DIPOPERIF       TO DESCR-CDPZ-1
BPO751        MOVE WRK-NUMOPERIF       TO DESCR-NUMOPE-1
BPO751        MOVE 'RECALL DI BONIFICO ESTERO'
BPO751                                 TO  DESCR-SPESE-BON
BPO751     END-IF
           PERFORM VARYING IND1-2 FROM 1 BY 1 UNTIL                     04880000
                      IND1-2 > MAX-IND1-2                               04890000
                OR KEY1-MOVP-ICTVLIS(IND1-1,IND1-2) NOT > ZEROES
              IF SV2P-TIPORIC = '02'
                 MOVE KEY1-MOVP-DIPOPE(IND1-1)      TO MOVCC-DIPOPE
                 MOVE KEY1-MOVP-NUMOPE(IND1-1)      TO MOVCC-NUMOPE
                 MOVE KEY1-MOVP-NPRGMOVP(IND1-1)    TO MOVCC-NPRGMOVP
                 MOVE KEY1-MOVP-NSUBMOVP(IND1-1)    TO MOVCC-NSUBMOVP

                 PERFORM R0057-SELECT-AMOVCC
                    THRU R0057-SELECT-AMOVCC-END
                 IF W-SQL-OK
                    MOVE MOVCC-NUMOPECC        TO SV2P-NUMMOVI
                 END-IF
                 MOVE SPACES              TO SV2P-CAUSALE(IND1-2)
                 MOVE 0                   TO SV2P-VALLIQU(IND1-2)
                 MOVE 0                   TO SV2P-VALDISP(IND1-2)
              ELSE
                 MOVE SPACES                        TO SV2P-NUMMOVI
                 MOVE KEY1-MOVP-CAUSALE(IND1-1,IND1-2)
                                           TO SV2P-CAUSALE(IND1-2)
                 MOVE KEY1-MOVP-DVAL(IND1-1)
                                             TO SV2P-VALLIQU(IND1-2)
                 MOVE KEY1-MOVP-DCON(IND1-1) TO SV2P-VALDISP(IND1-2)
              END-IF
              MOVE 'CC'                    TO SV2P-TIPSERV(IND1-2)
              MOVE KEY1-MOVP-NCCO(IND1-1)  TO SV2P-RAPPORT(IND1-2)
              MOVE KEY1-MOVP-NCCO(IND1-1)  TO INCC-CV20-RAPPORT
              PERFORM CHIAMA-CRVXD228
                 THRU CHIAMA-CRVXD228-END
              MOVE WRK-INCC-CATRAPP         TO SV2P-CATRAPP(IND1-2)
              MOVE WRK-INCC-FILIALE         TO SV2P-FILIALE(IND1-2)
              MOVE KEY1-MOVP-CISO(IND1-1)
                                           TO SV2P-DIVISA(IND1-2)
              IF KEY1-MOVP-FLAGDA(IND1-1,IND1-2) = 'A'
                 MOVE KEY1-MOVP-ICTVLIS(IND1-1,IND1-2)
                                           TO SV2P-IMPOPER(IND1-2)
              ELSE
                 COMPUTE SV2P-IMPOPER(IND1-2) =
                       KEY1-MOVP-ICTVLIS(IND1-1,IND1-2) * -1
              END-IF
              MOVE SPACES                    TO SV2P-DESCMOV-01(IND1-2)
              MOVE SPACES                    TO SV2P-DESCMOV-02(IND1-2)
              MOVE W-DESCRIZIONE1            TO SV2P-DESCMOV-01(IND1-2)
BPO640*       MOVE W-DESCRIZIONE1(65:)       TO W-DESCRIZIONE-APP(1:5)
BPO640        MOVE W-DESCRIZIONE1(60:)       TO W-DESCRIZIONE-APP(1:5)
              MOVE W-DESCRIZIONE2            TO W-DESCRIZIONE-APP(6:)
              MOVE W-DESCRIZIONE-APP         TO SV2P-DESCMOV-02(IND1-2)
           END-PERFORM.
      *
      *    DISPLAY 'SV2P-DESCMOV-01(IND1-2)=' SV2P-DESCMOV-02(IND1-2)
      *    DISPLAY 'SV2P-DESCMOV-01(IND1-2)=' SV2P-DESCMOV-02(IND1-2)
      *    EXEC CICS DELAY REQID ('CC') END-EXEC.
           PERFORM CHIAMA-CSVO6400
              THRU CHIAMA-CSVO6400-END.
      *    EXEC CICS DELAY REQID ('CC-1') END-EXEC.
      *
      *
       R0070-AGGIORNA-CC-END.                                           04250000
           EXIT.                                                        07340000
      *
       R0070-AGGIORNA-CSERV.                                            04250000
           INITIALIZE AREA-SV2P.
           MOVE '00001'                      TO SV2P-ISTITUT.
           IF OPE-BCKFTIPOPE = 1 OR 3
              MOVE '01'                      TO SV2P-TIPORIC
           ELSE
              IF OPE-BCKFTIPOPE = 2
                 MOVE '02'                   TO SV2P-TIPORIC
              END-IF
           END-IF
           MOVE KEY2-MOVP-CODOPE(IND2-1)     TO SV2P-CODOPE.
           MOVE WCM-DATA-SIS                 TO SV2P-DATAIMM
           MOVE WCM-ORA-SIS                  TO SV2P-ORAIMM
           MOVE WRK-TERMIMM                  TO SV2P-TERMIMM
           MOVE WRK-DIPEIMM                  TO SV2P-DIPEIMM
           MOVE WRK-COPERIM                  TO SV2P-COPERIM
           MOVE KEY2-MOVP-DCON(IND2-1)       TO SV2P-DATCONT
           MOVE SPACES                       TO W-DESCRIZIONE1
           MOVE 'NRO OPERAZ.='               TO DESCR-MOV
           MOVE '-'                          TO DESCR-X
      *    MOVE 'ORD='                       TO VAL-ORDINANTE
           MOVE KEY2-MOVP-DIPOPE (IND2-1)    TO DESCR-CDPZ
           MOVE KEY2-MOVP-NUMOPE (IND2-1)    TO DESCR-NUMOPE
      *----------------------------- GIRI TRA BANCHE IN EURO
           IF OPE-CPCS = 0932
              IF KEY2-MOVP-TMOV (IND1-1) = 2
                 MOVE WRK-ZRAGSOCO        TO DESCR-ORDINANTE1
                 MOVE WRK-ZINDO           TO DESCR-ORDINANTE2
                 MOVE 'ORD='              TO VAL-ORDINANTE
              END-IF
              IF KEY2-MOVP-TMOV (IND1-1) = 1
                 MOVE WRK-ZRAGSOCO-110    TO DESCR-ORDINANTE1
                 MOVE WRK-ZINDO-120       TO DESCR-ORDINANTE2
                 MOVE 'BEN='              TO VAL-ORDINANTE
              END-IF
           ELSE
              MOVE WRK-ZRAGSOCO-110       TO DESCR-ORDINANTE1
              MOVE WRK-ZINDO-120          TO DESCR-ORDINANTE2
              IF KEY2-MOVP-TMOV (IND1-1) = 2
                 MOVE 'ORD='              TO VAL-ORDINANTE
              END-IF
              IF KEY2-MOVP-TMOV (IND1-1) = 1
                 MOVE 'BEN='              TO VAL-ORDINANTE
           END-IF
           PERFORM VARYING IND2-2 FROM 1 BY 1 UNTIL                     04880000
                      IND2-2 > MAX-IND2-2                               04890000
                 OR KEY2-MOVP-ICTVLIS(IND2-1,IND2-2) NOT > ZEROES
              IF SV2P-TIPORIC = '02'
                 MOVE KEY2-MOVP-DIPOPE(IND2-1) TO MOVCC-DIPOPE
                 MOVE KEY2-MOVP-NUMOPE(IND2-1) TO MOVCC-NUMOPE
                 IF IND2-1 GREATER 1
                    COMPUTE MOVCC-NPRGMOVP =  99 - IND2-1
                 ELSE
                    MOVE 99                    TO MOVCC-NPRGMOVP
                 END-IF
                 MOVE ZEROES                   TO MOVCC-NSUBMOVP

                 PERFORM R0057-SELECT-AMOVCC
                    THRU R0057-SELECT-AMOVCC-END
                 IF W-SQL-OK
                    MOVE MOVCC-NUMOPECC        TO SV2P-NUMMOVI
                 END-IF
                 MOVE SPACES              TO SV2P-CAUSALE(IND2-2)
                 MOVE 0                   TO SV2P-VALLIQU(IND2-2)
                 MOVE 0                   TO SV2P-VALDISP(IND2-2)
              ELSE
                 MOVE SPACES                        TO SV2P-NUMMOVI
                 MOVE KEY2-MOVP-CAUSALE(IND2-1,IND2-2)
                                           TO SV2P-CAUSALE(IND2-2)
      *          MOVE 0                    TO SV2P-VALDISP(IND2-2)
                 MOVE KEY2-MOVP-DCON(IND2-1)
                                           TO SV2P-VALLIQU(IND2-2)
              END-IF
      *
      *
IM0006*--- IN REGIME DI IMEL ON E IN CASO DI FLAG CARTA = 'S'
IM0006*--- DEVE PRENDERE I CONTI NUOVI
IM0006*--- ALTRIMENTI LASCIA QUELLI CHE HA ATTRIBUITO NELLA PERFORM
IM0006*--- INTABELLA-CSERV
TEST00*       DISPLAY 'WRK-DATA-SISTEMA = ' WRK-DATA-SISTEMA
TEST00*       DISPLAY 'W-DATA-IMEL-08-N = ' W-DATA-IMEL-08-N
TEST00*       DISPLAY 'KEY2-MOVP-NCCO(IND2-1)=' KEY2-MOVP-NCCO(IND2-1)
TEST00*       DISPLAY 'FLGCARTA DI MOVP = '
TEST00*               KEY2-MOVP-FLGCARTA(IND2-1,IND2-2)
IM0006        IF WRK-DATA-SISTEMA NOT LESS  W-DATA-IMEL-08-N
IM0032*IM0006           AND KEY2-MOVP-FLGCARTA(IND2-1,IND2-2) = 'S'
IM0032           AND (KEY2-MOVP-FLGCARTA(IND2-1,IND2-2) = 'S' OR
IM0032                KEY2-MOVP-FLGCARTA(IND2-1,IND2-2) = 'B')
IM0006           IF OPE-BCKFTIPOPE  = 3
IM0006              MOVE CONFC-NCCASERTS TO KEY2-MOVP-NCCO (IND2-1)     07291700
IM0006           ELSE
IM0006              MOVE CONFC-NCCASERUB TO KEY2-MOVP-NCCO (IND2-1)     07291700
IM0006           END-IF
IM0006        END-IF

TEST00*       DISPLAY 'DOPO '
TEST00*       DISPLAY 'KEY2-MOVP-NCCO(IND2-1)=' KEY2-MOVP-NCCO(IND2-1)
              MOVE KEY2-MOVP-NCCO(IND2-1) TO SV2P-RAPPORT(IND2-2)
              MOVE KEY2-MOVP-NCCO(IND2-1) TO  INCC-CV20-RAPPORT
              PERFORM CHIAMA-CRVXD228
                 THRU CHIAMA-CRVXD228-END
      *
              MOVE WRK-INCC-CATRAPP        TO SV2P-CATRAPP(IND2-2)
              MOVE WRK-INCC-FILIALE        TO SV2P-FILIALE(IND2-2)
              MOVE 'CC'                    TO SV2P-TIPSERV(IND2-2)
      *       MOVE SPACES                  TO SV2P-FILIALE(IND2-2)
              MOVE KEY2-MOVP-CISO(IND2-1)
                                           TO SV2P-DIVISA(IND2-2)
              IF KEY2-MOVP-FLAGDA(IND2-1,IND2-2) = 'A'
                 MOVE KEY2-MOVP-ICTVLIS(IND2-1,IND2-2)
                                             TO SV2P-IMPOPER(IND2-2)
              ELSE
                 COMPUTE SV2P-IMPOPER(IND2-2) =
                        KEY2-MOVP-ICTVLIS(IND2-1,IND2-2) * -1
              END-IF
              MOVE SPACES                    TO SV2P-DESCMOV-01(IND2-2)
              MOVE SPACES                    TO SV2P-DESCMOV-02(IND2-2)
              MOVE W-DESCRIZIONE1            TO SV2P-DESCMOV-01(IND2-2)
              MOVE W-DESCRIZIONE1(65:)       TO W-DESCRIZIONE-APP(1:5)
              MOVE W-DESCRIZIONE2            TO W-DESCRIZIONE-APP(6:)
              MOVE W-DESCRIZIONE-APP         TO SV2P-DESCMOV-02(IND2-2)
           END-PERFORM.
      *
      *    EXEC CICS DELAY REQID ('CSERV') END-EXEC.
           PERFORM CHIAMA-CSVO6400
              THRU CHIAMA-CSVO6400-END.
      *    EXEC CICS DELAY REQID ('CSERV-1') END-EXEC.
      *
      *
       R0070-AGGIORNA-CSERV-END.                                        04250000
           EXIT.                                                        07340000
      *
       NORMALIZZA-CDPZ.
           MOVE SPACES TO WRK-NORMALE.
           PERFORM VARYING WRK-INDRIC FROM 1 BY 1
             UNTIL WRK-INDRIC  > 5
                OR WRK-VALORE(WRK-INDRIC:1) > ZEROES
           END-PERFORM.

           MOVE WRK-VALORE(WRK-INDRIC:) TO WRK-NORMALE(1:).

       NORMALIZZA-CDPZ-END.
           EXIT.
       NORMALIZZA-NCCO.
           MOVE SPACES TO WRK-NORMALE.
           PERFORM VARYING WRK-INDRIC FROM 1 BY 1
             UNTIL WRK-INDRIC  > 12
                OR WRK-VALORE(WRK-INDRIC:1) > ZEROES
           END-PERFORM.

           MOVE WRK-VALORE(WRK-INDRIC:) TO WRK-NORMALE(1:).

       NORMALIZZA-NCCO-END.
           EXIT.
       CHIAMA-PPTOGEPP.

      *-----> CHIAMATA ROUTINE INSERIMENTO/ANNULLO PRENOTAZIONE
           EXEC CICS LINK PROGRAM('PPTOGEPP')
                          COMMAREA(GEPP)
                          LENGTH(WRK-GEPP-LEN)
           END-EXEC.

      ****************************************************
      ** GEPP-RETCODE =  'OK'  -> OK                     *
      **                 'KO'  -> ERRORE ELABORAZIONE    *
      ****************************************************

           IF GEPP-RETCODE NOT = 'OK'
              MOVE 8                      TO W-FLAG-ERR                 10390000
              MOVE 'AG01'                 TO W-COD-ERR                  10400000
              MOVE 'PPTOGEPP'             TO L-NOME-TABELLA             10410000
              MOVE ZEROES                 TO L-CODICE-SQL               10420000
              MOVE 'ZMBAGGCC'             TO L-MODULO                   10430000
              MOVE GEPP-RETCODE           TO L-SUB-MODULO(1:2)          10450000
              MOVE GEPP-DESCERR           TO L-SUB-MODULO(3:)           10450000
              PERFORM 9999-GESTIONE-ERRORE                              10460000
                 THRU 9999-GESTIONE-ERRORE-END                          10470000
              GO TO FINE                                                10480000
           ELSE                                                         10490000
              IF WRK-FLAG-PRE = 'S'
                 MOVE GEPP-NUMOPE-OUT        TO WRK-NUMPRECC
              END-IF
           END-IF.
       CHIAMA-PPTOGEPP-END.
           EXIT.
      *
       CHIAMA-CSVO6400.

      *-----> CHIAMATA ROUTINE AGGIORNAMENTO C/C
           EXEC CICS LINK PROGRAM('CSVO6400')
                          COMMAREA(AREA-SV2P)
                          LENGTH(WRK-SV2P-LEN)
           END-EXEC.

      ****************************************************
      ** SV2P-RETCODE =  '  '  -> OK                     *
      **                 > ' ' -> ERRORE ELABORAZIONE    *
      ****************************************************

TEST00*    DISPLAY 'AREA-SV2P = ' AREA-SV2P
           IF SV2P  EQUAL ALL HIGH-VALUE
              MOVE 8                      TO W-FLAG-ERR
              MOVE 'AG01'                 TO W-COD-ERR
              MOVE 'CSVO6400'             TO L-NOME-TABELLA
              MOVE ZEROES                 TO L-CODICE-SQL
              MOVE 'ZMBAGGCC'             TO L-MODULO
              MOVE SV2P-RETCODE
                                      TO L-SUB-MODULO(1:3)
              MOVE 'AREA CSVCSV2P-ERRORE DB2 ROUTINE CSVO6400'
                                      TO L-SUB-MODULO(5:)
              PERFORM 9999-GESTIONE-ERRORE
                 THRU 9999-GESTIONE-ERRORE-END
              GO TO FINE
           END-IF.
           IF SV2P-RETCODE GREATER SPACES
              MOVE 8                      TO W-FLAG-ERR
              MOVE 'AG01'                 TO W-COD-ERR
              MOVE 'CSVO6400'             TO L-NOME-TABELLA
              MOVE ZEROES                 TO L-CODICE-SQL
              MOVE 'ZMBAGGCC'             TO L-MODULO
              MOVE SV2P-RETCODE
                                      TO L-SUB-MODULO(1:3)
              MOVE SV2P-MESS
                                      TO L-SUB-MODULO(5:)
TEST00*       DISPLAY 'SV2P-MESS  = ' SV2P-MESS
              PERFORM 9999-GESTIONE-ERRORE
                 THRU 9999-GESTIONE-ERRORE-END
              GO TO FINE
           END-IF.


       CHIAMA-CSVO6400-END.
           EXIT.
      *
       CHIAMA-CRVXD228.

      *-----> CHIAMATA ROUTINE VERIFICA C/C PER VALORIZZARE CATEGORIA
           EXEC CICS LINK PROGRAM('CRVXD228')
                          COMMAREA(PPTCINCC)
                          LENGTH(INCC-LEN)
           END-EXEC.

      ****************************************************
      ** INCC-RETCODE =  '  '  -> OK                     *
      ** INCC-RETCODE =  'NF'  -> CONTO INESISTENTE      *
      ****************************************************

           IF PPTCINCC EQUAL ALL HIGH-VALUE
              MOVE 8                      TO W-FLAG-ERR
              MOVE 'AG01'                 TO W-COD-ERR
              MOVE 'CRVXD228'             TO L-NOME-TABELLA
              MOVE ZEROES                 TO L-CODICE-SQL
              MOVE 'ZMBAGGCC'             TO L-MODULO
              MOVE INCC-RETCODE
                                      TO L-SUB-MODULO(1:3)
              MOVE 'AREA PPTCINCC-ERRORE DB2 ROUTINE CRVXD228'
                                      TO L-SUB-MODULO(5:)
              PERFORM 9999-GESTIONE-ERRORE
                 THRU 9999-GESTIONE-ERRORE-END
              GO TO FINE
           END-IF.
           IF INCC-RETCODE = 'SI'
              MOVE INCC-CV20-CATRAPP  TO WRK-INCC-CATRAPP
              MOVE INCC-CV20-FILIALE  TO WRK-INCC-FILIALE
           ELSE
              MOVE 8                      TO W-FLAG-ERR
              MOVE 'AG01'                 TO W-COD-ERR
              MOVE 'CRVXD228'             TO L-NOME-TABELLA
              MOVE ZEROES                 TO L-CODICE-SQL
              MOVE 'ZMBAGGCC'             TO L-MODULO
              MOVE INCC-RETCODE
                                         TO L-SUB-MODULO(1:3)
              IF INCC-RETCODE = 'NO'
                 MOVE 'ERRORE DB2 ROUTINE VERIFICA ESISTENZA C/C'
                                             TO L-SUB-MODULO(5:)
              ELSE
                 MOVE 'ERRORE ROUTINE VERIFICA ESISTENZA C/C'
                                             TO L-SUB-MODULO(5:)
              END-IF
              PERFORM 9999-GESTIONE-ERRORE
                 THRU 9999-GESTIONE-ERRORE-END
              GO TO FINE
           END-IF.

       CHIAMA-CRVXD228-END.
           EXIT.
      *--------------------------------------------------------------   07350000
       R0080-UPDATE-AMOVCC.                                             07360000
                                                                        07370000
           EXEC SQL INCLUDE ZMU47301  END-EXEC.                         07380000
                                                                        07390000
           IF NOT W-SQL-OK                                              07400000
              MOVE 8                   TO W-FLAG-ERR                    07410000
              MOVE '9999'              TO W-COD-ERR                     07420000
              MOVE 'TBAMOVCC'          TO L-NOME-TABELLA                07430000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  07440000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      07450000
              MOVE 'ZMU47301'          TO L-SUB-MODULO                  07460000
              PERFORM 9999-GESTIONE-ERRORE                              07470000
                 THRU 9999-GESTIONE-ERRORE-END                          07480000
              GO TO FINE                                                07490000
           END-IF.                                                      07500000
                                                                        07510000
       R0080-UPDATE-AMOVCC-END.                                         07520000
           EXIT.                                                        07530000
      *--------------------------------------------------------------   07540000
       R0050-LEGGI-TBTABSC.                                             07550000
                                                                        07570000
           EXEC SQL INCLUDE ZMS21401  END-EXEC.                         07580000
                                                                        07590000
           IF NOT W-SQL-OK                                              07600000
              MOVE 8                   TO W-FLAG-ERR                    07610000
              MOVE '9999'              TO W-COD-ERR                     07620000
              MOVE 'TBTABSC '          TO L-NOME-TABELLA                07630000
              MOVE W-SQLCODE           TO L-CODICE-SQL                  07640000
              MOVE 'ZMBAGGCC'          TO L-MODULO                      07650000
              MOVE 'ZMS21400'          TO L-SUB-MODULO                  07660000
              PERFORM 9999-GESTIONE-ERRORE                              07670000
                 THRU 9999-GESTIONE-ERRORE-END                          07680000
              GO TO FINE                                                07690000
           END-IF.                                                      07700000
                                                                        07710000
       R0050-LEGGI-TBTABSC-END.                                         07720000
           EXIT.                                                        07730000
      *--------------------------------------------------------------
      * PRELEVA LA DESCRIZIONE DELL'ORDINANTE/BENEFICIARI   SU ADMSGO
      *--------------------------------------------------------------
BPO407*PREPARA-DES-FL1502.
BPO407 PREPARA-DES-FLUSSO.
            MOVE OPE-CIST      TO DMSGO-CIST.
            IF OPE-BCKFTIPOPE = 3
               MOVE OPE-CDPZOPEST  TO DMSGO-DIPOPE
               MOVE OPE-NOPEST     TO DMSGO-NUMOPE
            ELSE
               MOVE OPE-DIPOPE  TO DMSGO-DIPOPE
               MOVE OPE-NUMOPE  TO DMSGO-NUMOPE
            END-IF
BPO407      IF APROC-TPCS = 76
BPO407         MOVE 1504          TO DMSGO-TTCLIC
BPO407      ELSE
               MOVE 1502          TO DMSGO-TTCLIC
BPO407      END-IF.
            MOVE 'FL'          TO DMSGO-TTFORMAT.
            MOVE 1             TO DMSGO-TTSUBCLI.
            PERFORM 0115-APERTURA-CURSORE7
               THRU 0115-APERTURA-CURSORE7-END.
            IF L-ERR-ERR
BPO407*        GO TO PREPARA-DES-FL1502-END.
BPO407         GO TO PREPARA-DES-FLUSSO-END.
            MOVE 'NO'          TO FINE-TBADMSGO.
            PERFORM 0116-LEGGI-TBADMSGO
               THRU 0116-LEGGI-TBADMSGO-END
                    UNTIL FINE-TBADMSGO = 'SI' OR
                             L-ERR-ERR.
            IF L-ERR-ERR
BPO407*        GO TO PREPARA-DES-FL1502-END.
BPO407         GO TO PREPARA-DES-FLUSSO-END.
            PERFORM 0125-CHIUSURA-CURSORE7
               THRU 0125-CHIUSURA-CURSORE7-END.
BPO407*PREPARA-DES-FL1502-END.
BPO407 PREPARA-DES-FLUSSO-END.
            EXIT.
BPO168 IMPOSTA-CODOPE-CIRCUITO.
BPO676*PER PROCESSI 932 E 1005 IMPOSTO CODOPE DIVERSI
APE001*  (ANCHE PROCESSO 2105)
BPO676*PER IL PROCESSO 1005 SONO VALORIZZATI I SEGUENTI CAMPI
BPO676*FLAG OPERAZIONE COLLEGATA (S/N) E DIPENDENZA OPERAZIONE
BPO676*COLLEGATA.IN BASE A TALI CAMPI SI STABILISCE SE OPERAZIONE
BPO676*DI RECUPERO SPESE LEGATA AD UNA USCITA (CODOPE ESTE)
BPO676*OPPURE AD UNA ENTRATA (CODOPE ESTB)
BPO168      IF OPE-CPCS = 932
BPO676         OR OPE-CPCS = 1005
APE001         OR OPE-CPCS = 2105
BPO676         IF OPE-CPCS = 932
BPO168            MOVE 'ESTF'               TO WRK-CODOPE-CC
BPO676         ELSE
BPO676           IF WRK-FLAG-OPECOLL = 'N'
BPO676*SE L'OPERAZIONE NON E'COLLEGATA ALLORA PER DEFAULT IMPOSTO
BPO676*UN CODOPE RELATIVO AD UN'OPERAZIONE FIN IN USCITA
BPO676              MOVE 'ESTE'              TO WRK-CODOPE-CC
BPO676           ELSE
BPO676*SE L'OPERAZIONE E' COLLEGATA SE CDPZ = 55111 CONSIDERO CODOPE
BPO676*USCITA ALTRIMENTI CODOPE ENTRATA (FIN)
BPO676              IF WRK-CDPZ-OPECOLL = 55111
BPO676                 MOVE 'ESTE'              TO WRK-CODOPE-CC
BPO676              ELSE
BPO676                 MOVE 'ESTB'              TO WRK-CODOPE-CC
BPO676              END-IF
BPO676           END-IF
BPO676         END-IF
BPO168      ELSE
BPO168         IF OPE-CDIVORD NOT = ISTI-CSIGDBASE
BPO168            IF OPE-FITOEBS = 'E'
BPO168               MOVE 'ESTE'         TO WRK-CODOPE-CC
BPO168            ELSE
BPO168               MOVE 'ESTB'         TO WRK-CODOPE-CC
BPO168            END-IF
BPO168         ELSE
BPO168*POICHE RILEGGO LA TABSC SALVO IL CONTENUTO DELLA DCLGEN
BPO168*PER POI RIVALORIZZARLO ALLA FINE DELLA PERFORM
BPO168            MOVE DCLTBTABSC      TO WRK-DCLTBTABSC
BPO168            MOVE W-CIST            TO ABSC-CIST
BPO168            MOVE MOVP-CSTCCTP      TO ABSC-CSTC
BPO168            PERFORM R0050-LEGGI-TBTABSC                           07284000
BPO168               THRU R0050-LEGGI-TBTABSC-END                       07285000
BPO168            IF W-SQL-OK
BPO168               IF (ABSC-CTIPSTC = 112 AND
BPO168                  ABSC-FTPGEST  = 6)
IM0032*BPO660                  OR ABSC-CSTC = 143
IM0032                  OR MOVP-CSTC = 143
BPO751                  IF OPE-CPCS NOT = 2276
BPO168                     IF OPE-FITOEBS = 'E'
BPO168                        MOVE 'ESTD'         TO WRK-CODOPE-CC
BPO168                     ELSE
BPO168                        MOVE 'ESTA'         TO WRK-CODOPE-CC
BPO751                     END-IF
BPO751                  ELSE
BPO751                     MOVE 'ESTA'            TO WRK-CODOPE-CC
BPO168                  END-IF
BPO168               ELSE
BPO187                  IF ABSC-CTIPSTC = 213
BPO187                     PERFORM CIRCUITO-CATTESA
BPO187                        THRU CIRCUITO-CATTESA-END
BPO187                  ELSE
BPO168                     IF OPE-FITOEBS = 'E'
BPO168                        MOVE 'ESTE'         TO WRK-CODOPE-CC
BPO168                     ELSE
BPO168                        MOVE 'ESTB'         TO WRK-CODOPE-CC
BPO168                     END-IF
BPO187                  END-IF
BPO168               END-IF
BPO168            END-IF
BPO168*RIPRISTINO LE DCLGEN PRECEDENTEMENTE SALVATA
BPO168            MOVE WRK-DCLTBTABSC       TO DCLTBTABSC
BPO168         END-IF
BPO168      END-IF.
APE001*---------------------------------------------------
APE001      IF WRK-CODOPE-CC = 'ESTA' OR
APE001         WRK-CODOPE-CC = 'ESTD'
APE001         MOVE 'TGT'     TO WRK-CIRCUITO
APE001      END-IF
APE001      IF WRK-CODOPE-CC = 'ESTE' OR
APE001         WRK-CODOPE-CC = 'ESTB'
APE001         MOVE 'FIN'     TO WRK-CIRCUITO
APE001      END-IF.
BPO168 IMPOSTA-CODOPE-CIRCUITO-END.
BPO168      EXIT.
BPO187 CIRCUITO-CATTESA.
BPO187
BPO187      MOVE DCLTBAMOVP     TO WRK-DCLTBAMOVP
BPO187      MOVE MOVP-CSTCCTP TO MOVP-CSTC.
BPO187      PERFORM R0051-LEGGI-AMOVP-CTP                               07284000
BPO187         THRU R0051-LEGGI-AMOVP-CTP-END                           07285000
BPO187      IF W-SQL-OK
BPO187         MOVE MOVP-CDPZ      TO BFA-DIPOPE
BPO187         MOVE MOVP-NPRGOPE   TO BFA-NUMOPE
BPO187         PERFORM R0051-LEGGI-BFA-CTP                              07284000
BPO187            THRU R0051-LEGGI-BFA-CTP-END                          07285000
BPO187         IF W-SQL-OK
BPO187            IF BFA-CIRCUITO = 'FIN'
BPO187               MOVE 'ESTB'         TO WRK-CODOPE-CC
BPO187            ELSE
BPO187               MOVE 'ESTA'         TO WRK-CODOPE-CC
BPO187            END-IF
BPO187         END-IF
BPO187      END-IF.
BPO187*RIPRISTINO LA DCLGEN DI AMOVP SALVATA
BPO187      MOVE WRK-DCLTBAMOVP TO DCLTBAMOVP.
BPO187 CIRCUITO-CATTESA-END.
BPO187      EXIT.
BPO187 R0051-LEGGI-AMOVP-CTP.                                           06210000
BPO187                                                                  06220000
BPO187     EXEC SQL INCLUDE ZMS11633  END-EXEC.                         06230000
BPO187                                                                  06240000
BPO187     IF NOT W-SQL-OK                                              06250000
BPO187        MOVE 8                   TO W-FLAG-ERR                    06260000
BPO187        MOVE '9999'              TO W-COD-ERR                     06270000
BPO187        MOVE 'TBAMOVP '          TO L-NOME-TABELLA                06280000
BPO187        MOVE W-SQLCODE           TO L-CODICE-SQL                  06290000
BPO187        MOVE 'ZMBAGGCC'          TO L-MODULO                      06300000
BPO187        MOVE 'ZMS11633'          TO L-SUB-MODULO                  06310000
BPO187        PERFORM 9999-GESTIONE-ERRORE                              06320000
BPO187           THRU 9999-GESTIONE-ERRORE-END                          06330000
BPO187        GO TO FINE                                                06340000
BPO187     END-IF.                                                      06350000
BPO187                                                                  06360000
BPO187 R0051-LEGGI-AMOVP-CTP-END.                                       06370000
BPO187     EXIT.                                                        06380000
BPO187 R0051-LEGGI-BFA-CTP.                                             06210000
BPO187                                                                  06220000
BPO187     EXEC SQL INCLUDE ZMS66901  END-EXEC.                         06230000
BPO187                                                                  06240000
BPO187     IF NOT W-SQL-OK                                              06250000
BPO187        MOVE 8                   TO W-FLAG-ERR                    06260000
BPO187        MOVE '9999'              TO W-COD-ERR                     06270000
BPO187        MOVE 'TBAMOVP '          TO L-NOME-TABELLA                06280000
BPO187        MOVE W-SQLCODE           TO L-CODICE-SQL                  06290000
BPO187        MOVE 'ZMBAGGCC'          TO L-MODULO                      06300000
BPO187        MOVE 'ZMS66901'          TO L-SUB-MODULO                  06310000
BPO187        PERFORM 9999-GESTIONE-ERRORE                              06320000
BPO187           THRU 9999-GESTIONE-ERRORE-END                          06330000
BPO187        GO TO FINE                                                06340000
BPO187     END-IF.                                                      06350000
BPO187                                                                  06360000
BPO187 R0051-LEGGI-BFA-CTP-END.                                         06370000
BPO187     EXIT.                                                        06380000
BPO896 R0051-LEGGI-BFA-STPART.                                          06210000
BPO896                                                                  06220000
BPO896     EXEC SQL INCLUDE ZMS66901  END-EXEC.                         06230000

BPO896     IF W-SQL-NON-TROVATO                                         06250000
BPO896        INITIALIZE DCLTBABFA
BPO896        IF OPE-BCKFTIPOPE = 2
BPO896           MOVE OPE-DIPOPE     TO BFA-CDPZESTINZ
BPO896           MOVE OPE-NUMOPE     TO BFA-NUMESTINZ
BPO896        ELSE
BPO896           MOVE OPE-CDPZOPEST  TO BFA-CDPZESTINZ
BPO896           MOVE OPE-NOPEST     TO BFA-NUMESTINZ
BPO896        END-IF
BPO896        EXEC SQL INCLUDE ZMS66922  END-EXEC.                      06230000
BPO896                                                                  06240000
BPO896        IF NOT W-SQL-OK                                           06250000
BPO896           MOVE 8                   TO W-FLAG-ERR                 06260000
BPO896           MOVE '9999'              TO W-COD-ERR                  06270000
BPO896           MOVE 'TBABFA  '          TO L-NOME-TABELLA             06280000
BPO896           MOVE W-SQLCODE           TO L-CODICE-SQL               06290000
BPO896           MOVE 'ZMBAGGCC'          TO L-MODULO                   06300000
BPO896           MOVE 'ZMS66901'          TO L-SUB-MODULO               06310000
BPO896           PERFORM 9999-GESTIONE-ERRORE                           06320000
BPO896              THRU 9999-GESTIONE-ERRORE-END                       06330000
BPO896           GO TO FINE                                             06340000
BPO896        END-IF                                                    06350000
BPO896     END-IF.                                                      06250000
BPO896                                                                  06240000
BPO896     IF NOT W-SQL-OK                                              06250000
BPO896        AND NOT W-SQL-NON-TROVATO
BPO896        MOVE 8                   TO W-FLAG-ERR                    06260000
BPO896        MOVE '9999'              TO W-COD-ERR                     06270000
BPO896        MOVE 'TBABFA  '          TO L-NOME-TABELLA                06280000
BPO896        MOVE W-SQLCODE           TO L-CODICE-SQL                  06290000
BPO896        MOVE 'ZMBAGGCC'          TO L-MODULO                      06300000
BPO896        MOVE 'ZMS66901'          TO L-SUB-MODULO                  06310000
BPO896        PERFORM 9999-GESTIONE-ERRORE                              06320000
BPO896           THRU 9999-GESTIONE-ERRORE-END                          06330000
BPO896        GO TO FINE                                                06340000
BPO896     END-IF.                                                      06350000
BPO896                                                                  06360000
BPO896 R0051-LEGGI-BFA-STPART-END.                                      06370000
BPO896     EXIT.                                                        06380000
      *--------------------------------------------------------------*
      * APERTURA DEL CURSORE CUR7                                     *
      *--------------------------------------------------------------*
       0115-APERTURA-CURSORE7.
            EXEC SQL INCLUDE ZMLOPE07 END-EXEC.
            IF NOT W-SQL-OK
               MOVE '8'                      TO  W-FLAG-ERR
               MOVE 'ERR. DB2 NON GESTITO '  TO L-ZRETCOD1
               MOVE SPACES                   TO L-ZRETCOD2
               MOVE SPACES                   TO L-NOME-TABELLA
               MOVE W-SQLCODE                TO L-CODICE-SQL
               MOVE 'ZMBAGGCC'               TO L-MODULO
               MOVE '0115-APERTURA-CURSORE7' TO L-SUB-MODULO
               PERFORM 9999-GESTIONE-ERRORE
                  THRU 9999-GESTIONE-ERRORE-END.
       0115-APERTURA-CURSORE7-END.
            EXIT.
      *-------------------------------------------------------------*
      * EFFETTUA LA FETCH SULLA TABELLA TBADMSGO (122)               *
      * UTILIZZANDO IL CURSORE CUR7                                  *
      *-------------------------------------------------------------*
       0116-LEGGI-TBADMSGO.
            EXEC SQL INCLUDE ZMF12202 END-EXEC.
            IF W-SQL-NON-TROVATO
               MOVE 'SI' TO FINE-TBADMSGO
            ELSE
               IF NOT W-SQL-OK
                   MOVE '8'                    TO W-FLAG-ERR
                   MOVE 'ERR. DB2 NON GESTITO' TO L-ZRETCOD1
                   MOVE SPACES                 TO L-ZRETCOD2
                   MOVE 'TBADMSGO'             TO L-NOME-TABELLA
                   MOVE W-SQLCODE              TO L-CODICE-SQL
                   MOVE 'ZMBAGGCC'             TO L-MODULO
                   MOVE '0116-LEGGI-TBADMSGO'  TO L-SUB-MODULO
                   PERFORM 9999-GESTIONE-ERRORE
                      THRU 9999-GESTIONE-ERRORE-END
                ELSE
                   MOVE DMSGO-WTABMSGO-TEXT    TO W-TAB-DMSGO
BPO407             IF APROC-TPCS = 76
BPO407                PERFORM 0118-ELABORA-1504
BPO407                   THRU 0118-ELABORA-1504-END
BPO407                      VARYING IND4 FROM 1 BY 1
BPO407                        UNTIL IND4 > WRK-MAX-IND-TAB-DMSGO
BPO407                           OR WPRMGO-TTTAG(IND4) NOT > SPACES
BPO407             ELSE
                      PERFORM 0118-ELABORA-TBADMSGO
                         THRU 0118-ELABORA-TBADMSGO-END
                            VARYING IND4 FROM 1 BY 1
                              UNTIL IND4 > WRK-MAX-IND-TAB-DMSGO
                                 OR WPRMGO-TTTAG(IND4) NOT > SPACES
BPO407             END-IF
                END-IF
             END-IF.
       0116-LEGGI-TBADMSGO-END.
            EXIT.
      *-------------------------------------------------------------*
      * ELABORA LE RICORRENZE PRESENTI NELLA TABELLA ZM.TBADMSGO     *
      *-------------------------------------------------------------*
       0118-ELABORA-TBADMSGO.
             EVALUATE WPRMGO-TTTAG(IND4)
                WHEN '75'
                      MOVE WPRMGO-TTVALTAG(IND4) TO WRK-ZRAGSOCO
                WHEN '80'
                      MOVE WPRMGO-TTVALTAG(IND4) TO WRK-ZINDO
                WHEN '110'
                      MOVE WPRMGO-TTVALTAG(IND4) TO WRK-ZRAGSOCO-110
                WHEN '120'
                      MOVE WPRMGO-TTVALTAG(IND4) TO WRK-ZINDO-120
BPO199          WHEN '255'
BPO199                MOVE WPRMGO-TTVALTAG(IND4) TO WRK-TIPOSPS-255
BPO751          WHEN '540'
BPO751               MOVE WPRMGO-TTVALTAG(IND4) TO NM-INPUT
BPO751               MOVE 7                     TO NM-LUNI
BPO751               MOVE 0                     TO NM-LUND
BPO751               MOVE 'N'                   TO NM-MILL
BPO751               PERFORM 9000-CTR-NUM
BPO751                  THRU 9000-CTR-NUM-END
BPO751               IF NM-RC = '00'
BPO751                  COMPUTE WRK-DEC3 = NM-OUTPUT / NM-CMPD
BPO751                  MOVE WRK-DEC3           TO WRK-COM-CIMP1
BPO751                  IF WRK-COM-CIMP1 NOT = ZEROES
BPO751                     MOVE WRK-COM-CIMP1 TO WRK-DIPOPERIF
BPO751                  END-IF
BPO751               END-IF
BPO751          WHEN '541'
BPO751               MOVE WPRMGO-TTVALTAG(IND4) TO NM-INPUT
BPO751               MOVE 7                     TO NM-LUNI
BPO751               MOVE 0                     TO NM-LUND
BPO751               MOVE 'N'                   TO NM-MILL
BPO751               PERFORM 9000-CTR-NUM
BPO751                  THRU 9000-CTR-NUM-END
BPO751               IF NM-RC = '00'
BPO751                  COMPUTE WRK-DEC3 = NM-OUTPUT / NM-CMPD
BPO751                  MOVE WRK-DEC3           TO WRK-COM-CIMP1
BPO751                  IF WRK-COM-CIMP1 NOT = ZEROES
BPO751                     MOVE WRK-COM-CIMP1 TO WRK-NUMOPERIF
BPO751                  END-IF
BPO751               END-IF
BPO676          WHEN '546'
BPO676               MOVE WPRMGO-TTVALTAG(IND4) TO NM-INPUT
BPO676               MOVE 5                     TO NM-LUNI
BPO676               MOVE 0                     TO NM-LUND
BPO676               MOVE 'N'                   TO NM-MILL
BPO676               PERFORM 9000-CTR-NUM
BPO676                  THRU 9000-CTR-NUM-END
BPO676               IF NM-RC = '00'
BPO676                  COMPUTE WRK-DEC3 = NM-OUTPUT / NM-CMPD
BPO676                  MOVE WRK-DEC3           TO WRK-COM-CIMP1
BPO676                  IF WRK-COM-CIMP1 NOT = ZEROES
BPO676                     MOVE WRK-COM-CIMP1   TO WRK-CDPZ-OPECOLL
BPO676                  END-IF
BPO676               END-IF
BPO676          WHEN '547'
BPO676                MOVE WPRMGO-TTVALTAG(IND4) TO WRK-FLAG-OPECOLL
BPO679          WHEN '548'
BPO679               MOVE WPRMGO-TTVALTAG(IND4) TO NM-INPUT
BPO679               MOVE 7                     TO NM-LUNI
BPO679               MOVE 0                     TO NM-LUND
BPO679               MOVE 'N'                   TO NM-MILL
BPO679               PERFORM 9000-CTR-NUM
BPO679                  THRU 9000-CTR-NUM-END
BPO679               IF NM-RC = '00'
BPO679                  COMPUTE WRK-DEC3 = NM-OUTPUT / NM-CMPD
BPO679                  MOVE WRK-DEC3           TO WRK-COM-CIMP1
BPO679                  IF WRK-COM-CIMP1 NOT = ZEROES
BPO679                     MOVE WRK-COM-CIMP1 TO WRK-NUMOPE-OPECOLL
BPO679                  END-IF
BPO679               END-IF
             END-EVALUATE.
       0118-ELABORA-TBADMSGO-END.
            EXIT.

BPO407*-------------------------------------------------------------*
BPO407* ELABORA LE RICORRENZE PRESENTI NELLA TABELLA ZM.TBADMSGO     *
BPO407*-------------------------------------------------------------*
BPO407 0118-ELABORA-1504.
BPO407       EVALUATE WPRMGO-TTTAG(IND4)
BPO407          WHEN '40'
BPO407                MOVE WPRMGO-TTVALTAG(IND4) TO WRK-ZRAGSOCO-110
BPO407          WHEN '45'
BPO407                MOVE WPRMGO-TTVALTAG(IND4) TO WRK-ZINDO-120
BPO407          WHEN '160'
BPO407                MOVE WPRMGO-TTVALTAG(IND4) TO WRK-TIPOSPS-255
BPO407       END-EVALUATE.
BPO407 0118-ELABORA-1504-END.
BPO407      EXIT.
      *--------------------------------------------------------------*
      * CHIUSURA DEL CURSORE CUR7                                     *
      *--------------------------------------------------------------*
       0125-CHIUSURA-CURSORE7.
            EXEC SQL INCLUDE ZMLCLO07 END-EXEC.
            IF NOT W-SQL-OK
               MOVE '8'                      TO W-FLAG-ERR
               MOVE 'ERR. DB2 NON GESTITO'   TO L-ZRETCOD1
               MOVE SPACES                   TO L-ZRETCOD2
               MOVE SPACES                   TO L-NOME-TABELLA
               MOVE W-SQLCODE                TO L-CODICE-SQL
               MOVE 'ZMBAGGCC'               TO L-MODULO
               MOVE '0125-CHIUSURA-CURSORE7' TO L-SUB-MODULO
               PERFORM 9999-GESTIONE-ERRORE
                  THRU 9999-GESTIONE-ERRORE-END.
       0125-CHIUSURA-CURSORE7-END.
            EXIT.
BPO138 LEGGI-TBTACABP.                                                  06210000
TEST00*    DISPLAY 'LEGGI-TBTACABP  '
TEST00*    DISPLAY 'ACABP-CCAUOP    '   ACABP-CCAUOP
TEST00*    DISPLAY 'ACABP-FLG-CARTA '   ACABP-FLG-CARTA
TEST00*    DISPLAY 'ACABP-CIRCUITO  '   ACABP-CIRCUITO
TEST00*    DISPLAY 'ACABP-CANALE    '   ACABP-CANALE
BPO138     MOVE ZEROES TO W-SQLCODE.
BPO138     EXEC SQL INCLUDE ZMS70801  END-EXEC.                         06230000
BPO138     IF NOT W-SQL-OK                                              06250000
BPO138        MOVE 8                   TO W-FLAG-ERR                    06260000
BPO138        MOVE '9999'              TO W-COD-ERR                     06270000
BPO138        MOVE 'TBTACABP'          TO L-NOME-TABELLA                06280000
BPO138        MOVE W-SQLCODE           TO L-CODICE-SQL                  06290000
BPO138        MOVE 'ZMBAGGCC'          TO L-MODULO                      06300000
BPO138        MOVE 'ZMS70801'          TO L-SUB-MODULO                  06310000
BPO138        MOVE 'ERR.LETT.CAUSALE C/C  ' TO L-SUB-MODULO(10:)
BPO138        PERFORM 9999-GESTIONE-ERRORE                              06320000
BPO138           THRU 9999-GESTIONE-ERRORE-END                          06330000
BPO138        GO TO FINE                                                06340000
BPO138     END-IF.                                                      06350000
BPO138 LEGGI-TBTACABP-END.                                              06370000
BPO138     EXIT.                                                        06380000
BPO676 LEGGI-TBTABCEC.                                                  06210000
BPO676     MOVE ZEROES TO W-SQLCODE.
BPO676     EXEC SQL INCLUDE ZMS20501  END-EXEC.                         06230000
BPO676     IF NOT W-SQL-OK                                              06250000
BPO676        MOVE 8                   TO W-FLAG-ERR                    06260000
BPO676        MOVE '9999'              TO W-COD-ERR                     06270000
BPO676        MOVE 'TBTABCEC'          TO L-NOME-TABELLA                06280000
BPO676        MOVE W-SQLCODE           TO L-CODICE-SQL                  06290000
BPO676        MOVE 'ZMBAGGCC'          TO L-MODULO                      06300000
BPO676        MOVE 'ZMS20501'          TO L-SUB-MODULO                  06310000
BPO676        MOVE 'ERR.LETT.TABCEC'   TO L-SUB-MODULO(10:)
BPO676        PERFORM 9999-GESTIONE-ERRORE                              06320000
BPO676           THRU 9999-GESTIONE-ERRORE-END                          06330000
BPO676        GO TO FINE                                                06340000
BPO676     END-IF.                                                      06350000
BPO676 LEGGI-TBTABCEC-END.                                              06370000
BPO676     EXIT.                                                        06380000
BPO304
BPO304 NORMALIZZA-CSTC.
BPO304     MOVE SPACES TO WRK-NORMALE.
BPO304     PERFORM VARYING INDRIC FROM 1 BY 1
BPO304       UNTIL INDRIC  > 10
BPO304          OR WRK-VALORE(INDRIC:1) > ZEROES
BPO304     END-PERFORM.
BPO304
BPO304     MOVE WRK-VALORE(INDRIC:) TO WRK-NORMALE(1:).
BPO304
BPO304 NORMALIZZA-CSTC-END.
BPO304     EXIT.
BPO893**********************************************************
BPO893****STORNO DI OPERAZIONE RIVALORIZZATA CON PRENOTATA
BPO893*** ANNULLAMENTO DI AMOVCC IN CASO DI STORNO CPCS 131    *
BPO893**********************************************************
BPO893 ANNULLA-PREN-ANT.
BPO893     IF OPE-DIPOPE = 311
BPO893        MOVE 'DIREZ'    TO WRK-DIPEIMM
BPO893     ELSE
BPO893        MOVE '00000'  TO WRK-DIPEIMM
BPO893        MOVE OPE-DIPOPE  TO WRK-VALORE
BPO893        PERFORM NORMALIZZA-CDPZ
BPO893        THRU NORMALIZZA-CDPZ-END
BPO893        MOVE WRK-NORMALE(1:5)  TO WRK-DIPEIMM
BPO893     END-IF
BPO893*----CANALE DI TRASMISSIONE NON VALORIZZATO
BPO893     IF OPE-CANTRASM NOT GREATER SPACES
BPO893        MOVE 'ESTE'    TO WRK-TERMIMM
BPO893        IF OPE-FLUSSOPRV = 'MOSAIC'
BPO893           MOVE SPACES     TO WRK-COPERIM
BPO893        ELSE
BPO893           MOVE OPE-NMTRUTE TO WRK-COPERIM
BPO893        END-IF
BPO893     ELSE
BPO893*----CANALE DI TRASMISSIONE VALORIZZATO ES. BPIOL BPOL DORE ETC
BPO893        MOVE SPACES    TO WRK-COPERIM
MCN002***     IF OPE-CANTRASM = 'DORE'
MCN002        IF WRK-TIPO-CANALE = 'R'
BPO893           MOVE 'BPOL' TO WRK-TERMIMM
IM0031           IF WRK-FLG-GEST-2 = 'P'
IM0031              MOVE 'PSD2'  TO WRK-TERMIMM
IM0031           END-IF
BPO893        ELSE
MCN002***        IF OPE-CANTRASM = 'DOCO'  OR 'DOCA'  OR 'DOCP'
MCN002***           OR 'DOCM'  OR 'DOTE'
MCN002           IF WRK-TIPO-CANALE = 'C'
BPO893              MOVE 'BPIO' TO WRK-TERMIMM
BPO893           ELSE
BPO893              MOVE OPE-CANTRASM TO WRK-TERMIMM
BPO893           END-IF
BPO893        END-IF
BPO893     END-IF
BPO893     MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO893     MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPO893     PERFORM R0060-ANNULLA-PRENOTATA
BPO893        THRU R0060-ANNULLA-PRENOTATA-END
BPO893     IF GEPP-RETCODE = 'OK'
BPO893        INITIALIZE DCLTBAMOVCC
BPO893        MOVE W-CIST    TO MOVCC-CIST
BPO893        MOVE OPE-CDPZOPEST TO MOVCC-DIPOPE
BPO893        MOVE OPE-NOPEST    TO MOVCC-NUMOPE
BPO893        MOVE 23        TO MOVCC-NPRGMOVP
BPO893        MOVE KEY1-MOVP-NSUBMOVP(IND1-1)
BPO893                       TO MOVCC-NSUBMOVP
BPO893        MOVE ZEROES    TO MOVCC-NUMOPECC
BPO893        MOVE ZEROES    TO MOVCC-NUMPRECC
BPO893        MOVE ZEROES    TO MOVCC-IMPPRE
BPO893        PERFORM R0080-UPDATE-AMOVCC
BPO893           THRU R0080-UPDATE-AMOVCC-END
BPO893     END-IF.
BPO893 ANNULLA-PREN-ANT-END.
BPO893     EXIT.
IM0006 TP136-LEGGI-CONFG.
IM0006     MOVE L-CIST            TO CONFG-CIST.
IM0006     MOVE ZEROES            TO W-SQLCODE.
IM0006*    EXEC SQL INCLUDE ZMS30902 END-EXEC.
IM0006     EXEC SQL INCLUDE ZMS30901 END-EXEC.
IM0006     IF NOT W-SQL-OK
IM0006*       AND NOT W-SQL-NON-TROVATO
IM0006        MOVE 8                   TO W-FLAG-ERR
IM0006        MOVE '9999'              TO W-COD-ERR
IM0006        MOVE 'TBWCONFG'          TO L-NOME-TABELLA
IM0006        MOVE W-SQLCODE           TO L-CODICE-SQL
IM0006        MOVE 'ZMBAGGCC'          TO L-MODULO
IM0006        MOVE 'ZMS30902'          TO L-SUB-MODULO
IM0006        PERFORM 9999-GESTIONE-ERRORE
IM0006           THRU 9999-GESTIONE-ERRORE-END
IM0006        GO TO FINE
IM0006     ELSE
IM0006        MOVE CONFG-ALTRIFLAG3           TO WCONFG-ALTRIFLAG3
IM0006        MOVE CONFG-DATA-IMEL (1:2) TO W-DATA-IMEL(5:2)
IM0006        MOVE CONFG-DATA-IMEL (3:2) TO W-DATA-IMEL(3:2)
IM0006        MOVE CONFG-DATA-IMEL (5:2) TO W-DATA-IMEL(1:2)
IM0006        MOVE '20'                  TO W-DATA-IMEL-08 (1:2)
IM0006        MOVE W-DATA-IMEL           TO W-DATA-IMEL-08 (3:6)
IM0006     END-IF
IM0006     .
IM0006 TP136-LEGGI-CONFG-END.
IM0006     EXIT.
      *--------------------------------------------------------------   12250000
       TP222-INCLUDE.                                                   12260000
           EXEC SQL INCLUDE ZMS22201 END-EXEC                           12270000
           .                                                            12280000
       TP222-INCLUDE-END.                                               12290000
           EXIT.                                                        12300000
      *------------------------------ ROUTINE COMUNE GESTIONE ERRORE    12310000
           EXEC SQL INCLUDE ZMIERRO1  END-EXEC.                         12320000
BPO676*------------------------------------------------------------*
BPO676*   ROUTINE STANDARD PER CONTROLLO CAMPI NUMERICI            *
BPO676*------------------------------------------------------------*
BPO676     COPY ZMZCTRNM.
