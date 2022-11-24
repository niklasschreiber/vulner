       IDENTIFICATION DIVISION.
       PROGRAM-ID.     YZTCA70.
      *================================================================*
      *                                                                *
      *      NNN     NNN         CCCCCCC        HHH   HHH              *
      *      NNNNN   NNN        CCCCCCCC        HHH   HHH              *
      *      NNNNNN  NNN        CCC             HHHHHHHHH              *
      *      NNN NNNNNNN        CCC             HHHHHHHHH              *
      *      NNN   NNNNN  ...   CCCCCCCC  ...   HHH   HHH  ...         *
      *      NNN     NNN  ...    CCCCCCC  ...   HHH   HHH  ...         *
      *                                                                *
      *----------------------------------------------------------------*
      *      NETWORK            COMPUTER        HOUSE      - BOLOGNA - *
      *----------------------------------------------------------------*
      *                                                                *
      *                                    PROGRAMMA: YZTCA70          *
      *  VERSIONE 01.01 DEL : 18/05/90 --- ULTIMA MODIFICA : XX/XX/XX  *
      *================================================================*
      *  GESTIONE DEL MESSAGGIO A70. FUNZIONI ESEGUITE:                *
      *                                                                *
      *================================================================*
POSTE *  MODIFICA DEL 06/07/1999 EFFETTUATA DA CLAUDIO BALDUCCI:       *
POSTE *  PERSONALIZZAZIONE PER POSTE ITALIANE S.P.A.: PRENOTAZIONE DEL-*
POSTE * L'IMPORTO OPERAZIONE DISPONIBILE SUL C/C.                      *
      *================================================================*
XP1307* 27/06/2013 - Nuova Gestione Autorizzante POSTE                 *
XP1307*================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *==============================================================*
      *       W O R K I N G     S T O R A G E     U T E N T E        *
      *==============================================================*
       01  WKSTORAGE-UTENTE.
         02  FILLER.
           03  FILLER           PIC  X(14) VALUE 'INIZIO-WORKING'.
DEBUGG     03  WK-DEBUGG1       PIC  X(20) VALUE 'PRIMA DI RIEMPI'.
DEBUGG     03  WK-DEBUGG2       PIC  X(20) VALUE 'DOPO     RIEMPI'.
DEBUGG     03  WK-DEBUGG3       PIC  X(20) VALUE 'LEGGI TAB INA  '.
DEBUGG     03  WK-DEBUGG4       PIC  X(20) VALUE 'TAB INA MAPPE  '.
DEBUGG     03  WK-DEBUGG5       PIC  X(20) VALUE 'SOVRAPPOSIZIONE'.
DEBUGG     03  WK-DEBUGG6       PIC  X(20) VALUE 'ESAME          '.
DEBUGG     03  WK-DBG           PIC  X(70) VALUE SPACES.
           03  WK-RISCRITTURA   PIC  X(02) VALUE 'SI'.
           03  WK-PTR-COMODO    PIC  S9(8) COMP SYNC.
           03  WK-INDIR-AREA-YZCRANA PIC   S9(8) COMP.
RDIS       03  WZ-SQL-CODE           PIC  ---9.
           03  SW-ERRORE        PIC  X.
OLCA1      03  WK-IND-TAB-OLTE       PIC  9(03).
OLCA1      03  WK-SW-OLCA            PIC  X(02).
OLCA1          88 WK-ATM-IN-OLCA     VALUE 'SI'.
OLCA1          88 WK-ATM-NON-IN-OLCA VALUE 'NO'.
OLCA2      03  WK-PKC-DA-INVIARE     PIC  X(02).
OLCA2          88 PKC-DA-INVIARE     VALUE 'SI'.
OLCA2          88 PKC-DA-NON-INVIARE VALUE 'NO'.
           03  WK-NUMOPER       PIC  9(05).
           03  WK-LUNGH-A71     PIC  9(05).
           03  WK-ABI-05        PIC  9(05).
           03  IND-RAPP         PIC  9(03).
           03  IND-MESS         PIC  9(03).
R06606     03  IND-OPE          PIC  9(03).
           03  WK-MESS-CLIENTE-92.
             05  WK-MESS-CLIENTE-90.
               07  WK-MESS-CLIENTE-62 PIC X(62).
               07  WK-MESS-CLIENTE-28 PIC X(28).
               07  WK-MESS-CLIENTE-XX PIC X(02).
           03  WK-SALDO-E-DATA.
             05  WK-SALDO-12.
               07  WK-SALDO-11   PIC 9(11).
SA0096         07  WK-SALDO-11-E REDEFINES
SA0096             WK-SALDO-11   PIC 9(9)V9(2).
               07  WK-SEGNO      PIC X(01).
             05  WK-DATA-SALDO   PIC X(6).
PREPA1     03  WK-SALDO-S        PIC S9(9)V9(2).
           03  WK-SERVIZI        PIC X(10)    VALUE ALL 'F'.
           03  F REDEFINES WK-SERVIZI.
             05  EL-WK-SERVIZI   PIC X(01).
             05  FILLER          PIC X(09).
131191     03  MSG-VAR3          PIC  X(50)
131191     VALUE 'CARTA RINNOVATA - RITIRARLA'.
SA0197*DISASTERISCATA LA PRECEDENTE
SA0197*ASTERISCATA LA SUCCESSIVA
131191*    VALUE 'REINTRODURRE LA CARTA...+....3....+....4....+....5'.
           03  WK-AAMMGG-A      PIC 9(6).
           03  F REDEFINES WK-AAMMGG-A.
               05  WK-AA-A      PIC 9(2).
               05  WK-MM-A      PIC 9(2).
               05  WK-GG-A      PIC 9(2).
           03  WK-AAMMGG-B      PIC 9(6).
           03  F REDEFINES WK-AAMMGG-B.
               05  WK-AA-B      PIC 9(2).
               05  WK-MM-B      PIC 9(2).
               05  WK-GG-B      PIC 9(2).
           03  WK-GGMMAA-C      PIC 9(6).
           03  F REDEFINES WK-GGMMAA-C.
               05  WK-GG-C      PIC 9(2).
               05  WK-MM-C      PIC 9(2).
               05  WK-AA-C      PIC 9(2).
SI0143*----------------------------------------------------------
SI0143     03  WK-A-SSAA        PIC 9(04).
SI0143     03  WK-B-SSAA        PIC 9(04).
SI0143     03  WK-C-SSAA        PIC 9(04).
200694*----------------------------------------------------------
200694     03  WK-SSAAMMGG.
200694         05  WK-SSAAMMGG-SS         PIC 9(02).
200694         05  WK-SSAAMMGG-AAMMGG     PIC 9(06).
200694     03  FILLER REDEFINES WK-SSAAMMGG.
200694         05  WK-SSAAMMGG-SSAAMM     PIC 9(06).
200694         05  WK-SSAAMMGG-GG         PIC 9(02).
200694*
200694     03  WK-SCAD-SSAAMM             PIC 9(06).
200694     03  FILLER  REDEFINES  WK-SCAD-SSAAMM.
200694         05  WK-SCAD-SSAAMM-SS      PIC 9(02).
200694         05  WK-SCAD-SSAAMM-AAMM.
200694             07  WK-SCAD-SSAAMM-AA  PIC 9(02).
200694             07  WK-SCAD-SSAAMM-MM  PIC 9(02).
200694*
R12303     03  WK-COMMDAY2                PIC 9(08).
           03  F PIC X(08) VALUE 'YZCWTRK3'.
               COPY YZCWTRK3.

           03 WK-AREA-MESS-RIC        PIC X(4096).
              COPY YZCRMESS.
COBOL2        COPY YZCWYZ31.
MPSINF     03 WK-AREA-INA.
MPSINF        05 EL-WK-AREA-INA       PIC X   OCCURS 99.
MPSINF*==============================================================*
MPSINF     03 WK-IND-SOVRAPP          PIC 9(3).
MPSINF     03 WK-AREA-INA-ALTA.
MPSINF        05 EL-WK-AREA-INA-ALTA  PIC X   OCCURS 99.
MPSINF     03 WK-AREA-INA-BASSA.
MPSINF        05 EL-WK-AREA-INA-BASSA PIC X   OCCURS 99.
MPSINF     03 WK-AREA-INA-RISUL.
MPSINF        05 EL-WK-AREA-INA-RISUL PIC X   OCCURS 99.
MPSINF     03 WK-EL.
MPSINF        05 WK-EL-1 PIC X.
MPSINF        05 WK-EL-2 PIC X.
MPSINF     03 WK-IND-ESAME            PIC 9(3).
MPSINF     03 SW-STG-NON-OK           PIC X(1).
R20404     03 WK-DATA-SCAD            PIC 9(8).
R20404     03 WK-DATA-OGGI            PIC 9(8).
R20404     03 WK-FLAG-TERM            PIC X(1) VALUE SPACE.
      *--------------
VALNCR     03 WK-SW-TIPO-TERM         PIC X(003).
VALNCR        88 TERM-VALNCR          VALUE '008'.
      *--------------
VALNCR     03 WK-TIPO-VALUTA          PIC 9(02).
161093*----PER VALNCR
161093     COPY YZCWYZ39.
SI0491     03 WK-STATO-UTENZE         PIC X(01).
SI0491        88 STATO-UTENZE-KO                 VALUE '0'.
SI0601*--->
SI0601     COPY Z3CLGE88 REPLACING 'Z3CLGE88' BY Z3CLGE88.
SI0601     COPY Z3CWDCOM REPLACING 'Z3CWDCOM' BY Z3CWDCOM.
SA0714 01  WK-ABI-SI-CIN                    PIC  9(05)     VALUE ZEROES.
SA0714 01  WK-ABI-NO-CIN                    PIC  9(05)     VALUE ZEROES.
SA0714 01  WK-IMPORTO-PREP                  PIC ZZ.ZZZ,99.
SA0714*---->
SA0714 01  COMMAREA-YZCCGEPP.
SA0714     COPY YZCCGEPP.
SA0714*---->
R18506*---->
R18506 01  WK-ABI                           PIC  9(05).
R18506 01  WK-AGENZIA                       PIC  9(05).
R18506 01  FILLER                           REDEFINES  WK-AGENZIA.
R18506     05  WK-SEDE                      PIC  9(02).
R18506     05  WK-DIP                       PIC  9(03).
R18506 01  WK-LL                            PIC  9(02).
R16507 01  WS-DISP-PP                       PIC  9(15).
SI1077*COPY Z3CLGE90.
ILCARD*-- ASTERISCATA LA PRECEDENTE; DA Z3CLGE90 A Z8CLGE90
ILCARD COPY Z8CLGE90.
SI1077     COPY YZCRDUAL
SI1077          REPLACING =='YZCRDUAL'== BY ==YZCRDUAL==.

      *==============================================================*
      *       W O R K I N G     S T O R A G E    S T A N D A R D     *
      *==============================================================*
       01  WORKING-STORAGE-STANDARD.
           COPY YYCWKSTD.
           COPY YYCWOPZI.
      *==============================================================*
      *    1 - COMUNICATION AREA (C.A.) DEL PROGRAMMA                *
      *==============================================================*
      *--------------------- COMMAREA STANDARD ----------------------*
       01  COMMAREA.
           05 FILLER           PIC X OCCURS 6000.
       01  FILLER              REDEFINES COMMAREA.
           COPY YYCW0180.
      *    COPY YZCWCOMT.
           COPY YZCWCOUN.
      *==============================================================*
      *    6 - FUNZIONI NECESSARIE ALLE OPERAZIONI DI I/O DATI       *
      *==============================================================*
      *----------------------------- TABELLA GENERALIZZATA
           COPY YYCRTGEN.
SI0491*----------------------------- TABELLA STATO UTENZE
SI0491     COPY YZCW064.
      *----------------------------- LUNGHEZZE   ARCHIVI
           COPY YYCW0004.
           COPY YZCWYZ04.
      *-----------------------       COPY DI INSTALLAZIONE
           COPY YYCW0005.
      *----------------------------- NOMI        ARCHIVI
           COPY YYCW0006.
           COPY YZCWYZ06.
      *----------------------------- DESCRIZIONE ARCHIVI
SP0006*    COPY YYCWARK.
      *==============================================================*
      *    6 - AREA PER COLLOQUIO CON MODULI IODB                    *
      *==============================================================*
      *----------------------------- AREA PASSAGGIO DATI PER I/O DC
           COPY YYCWIODC.
      *----------------------------- AREA PASSAGGIO DATI PER I/O DB
           COPY YYCWIODB.
      *----------------------------- CODICE FUNZIONE PER I/O DB
           COPY YYCWIOFN.
      *----------------------------- CODICE FUNZIONE PER I/O DC
           COPY YYCWDLIF.
      *----------------------------- STATUS CODE PER I/O DB
           COPY YYCWSCDS.
      *==============================================================*
      *    7 - AREA PER ERRORI                                       *
      *==============================================================*
      *----------------------------- AREA ERRORI DB/DC
      *    COPY YYCW0181.
      *----------------------------- AREA GESTIONE ERRORI APPLICATIVI
           COPY YYCW0182.
      *----------------------------- AREA PASSAGGIO DATI PER
      *---                           VISUALIZZAZIONE ERRORI
           COPY YYCW0195.
      *----------------------------- AREA PASSAGGIO DATI PER
      *---                           SCRITTURA LOG ERRORI
           COPY YYCW0196.
      *==============================================================*
      *    WORK AREA PER ROUTINE M061  - CONTROLLO DATA CON SECOLO   *
      *                                                              *
      *==============================================================*
           COPY YYCW0061.
      *==============================================================*
      *    WORK AREA PER ROUTINE M063  - CONTROLLO DATA              *
      *                                                              *
      *==============================================================*
           COPY YYCW0063.
      *==============================================================*
      *    WORK AREA PER ROUTINE M065  - CONVERSIONE DA ESADECIMALE  *
      *                                                              *
      *==============================================================*
           COPY YYCW0065.
      *==============================================================*
      *    WORK AREA PER ROUTINE M071  - TRASFORMAZIONE DATA         *
      *                                                              *
      *==============================================================*
           COPY YYCW0071.
YOUNG      COPY YYCWUTDA.
      *==============================================================*
      *    AREA PER LINK AD ALTRI PROGRAMMI                          *
      *==============================================================*
           COPY YZCWLINK.

      *==============================================================*
      *    DUMMY SECTIONS MESSAGGI I-O                               *
      *==============================================================*
SP0006     COPY YZCWEXIT REPLACING 'YZCWEXIT' BY YZCWEXIT.
SP0006     COPY YZCWEXIT REPLACING 'YZCWEXIT' BY YZTCA70-01.
SP0006     COPY YYCW0080.
SP0006 01  WK-NOME PIC X(40).
           COPY YZCWYZ05.
OLCA2      COPY YZCWXWK.
OLCA1      COPY YZCWOLWK.
OLCA1      COPY YZCROLTE.
SI0010*----
SI0010     COPY YZCWX71.
SI0010*----
SI0822     COPY YZCVNR02 REPLACING 'YZCTKABD' BY YZCTKABD
SI0822                                'TKABD' BY    TKABD.
SI0822     COPY YZCR2TRX.
SI0822     COPY YZCRERII.
SI0822 01   WK-COMODO-FLAG           PIC X.
R17206     COPY XYCTXCRM.
SI0822 01   WK-COMODO-TRACCIA        PIC X(40).
SI0905 01  WK-SAVE-FLAG-AGGIORNA    PIC X(1).
SI0831 01   WK-QUALE-TRACCIA        PIC X(1).
SI0831     COPY YZCW831A.
           COPY YZCRA70.
XP1307     COPY YZCRA20.
XP1307     COPY YZCRJ20.
           COPY YZCRA71.
           COPY YZCRFIT.
021091     COPY YZCRFITL.
131191     COPY YZCRSER.
YOUNG      COPY YZCTKOPE REPLACING 'YZCTKOPE' BY YZCTKOPE
YOUNG                                 'TKOPE' BY    TKOPE.
051291*    COPY YZCWYZ10.
051291*    COPY YZCWABD.
SI0092*    COPY YZCWRCP.
SI0092*    03  WK-IND           PIC S9(04) COMP SYNC VALUE ZERO.
SI0179*ASTERISCATE LE PRECEDENTI 3
SI0179 01  WK-IND               PIC S9(04) COMP SYNC VALUE ZERO.
051291     COPY YZCWANO.
MSGCLI*----------------------------------------------------------------*
MSGCLI*    COPY YZCWMCL.
MSGCLI*----------------------------------------------------------------*
           COPY YZCWYZ20.
           COPY YZCWYZ21.
           COPY YZCWUTDA.
R20404     COPY YYCRTPI.

190293 01  WK-AREA-YZCRANA.
           COPY YZCRANA.
RVS   *    COPY YZCWYZ11.
RVS   *    COPY YZCWYZ12.
MPSINF     COPY YZCWINA.
MPSINF     COPY YZCWSTG.
SI1221     COPY YZCWRKLC.
SI1221     COPY YZCWPKEP.
SI1221 01  YZCCPKEP.
SI1221     COPY YZCCPKEP REPLACING 'YZCCPKEP' BY YZCCPKEP
SI1221                                 'PKEP' BY     PKEP.
SI1221 01  CC-ARKL.
SI1221     COPY XKCCARKL.

      *==============================================================*
      *    AREA DI TEMPORARY STORAGE                                 *
      *==============================================================*
       01  AREA-TS.
           03  TSITEM          PIC S9(4) COMP SYNC VALUE ZERO.
           03  TSLENG          PIC S9(4) COMP SYNC VALUE ZERO.
           03  TSQUEUE.
               05  TSTRANSID   PIC X(4).
               05  TSTERMID    PIC X(4).
SI0143*---
SI0143*--- AREA DI COMUNICAZIONE CON MODULO YYUCTTMB UTILITY DATE
SI0143*---
SI0143 COPY YYCWTTMB.
SI1020*---->
SI1020     COPY YZCWXCRM.
SI1020 01  YZCCACRM.
SI1020     COPY YZCCACRM.
R18506     COPY XYCRXCRM.
SI1020     COPY YZCRLCRM REPLACING 'YZCRLCRM' BY YZCRLCRM
SI1020                                'RLCRM' BY    RLCRM.
XI0703*================================================================*
XI0703* COMMAREA x call modulo YZTCYZEN (scrittura info x ALERT)       *
XI0703*================================================================*
XI0703     COPY S1CWS1EN.
XI0703     COPY YZCWK004.
XI0703     COPY YZCWK006.
XI0703     COPY S1LKS1EN REPLACING 'S1LKS1EN' BY S1LKS1EN.
XI0703     COPY YZCRKRAC REPLACING 'YZCRKRAC' BY YZCRKRAC
XI0703                                'RKRAC' BY    RKRAC.
SI1020*---->
SI0800*-->
SI0800*--> AREE PER AUTORIZZAZIONI AZIENDALI SINCRONE CON OS390
SI0800*-->
SI0800 COPY YZCWIBMX.
SI0800 COPY YZLK002T.
BLDX99*---  Asteriscata la precedente
BLDX99*COPY YZLK005T.
SI0800 COPY YZLK003T.
SI0800 COPY YZCWOL55.
SI0800 COPY YZCRXCAR.
SI0800 COPY YZCRXAK.
SI0800 COPY YZCWX004.
SI0800 COPY YZCWX006.
SI0800 COPY YZCWTOL2.
SI0800 COPY YZCRXTRK REPLACING 'YZCRXTRK' BY YZCRXTRK.
SI0800 COPY YZCTOS39 REPLACING 'YZCTOS39' BY YZCTOS39.
SI0800 01  WS-ABI-OPERANTE.
SI0800     03  F               PIC X(1).
SI0800     03  WS-ABI-OPER-2-4 PIC X(4).
SI0861 COPY YZLK999T.
SI0861 01  WK-XDAT-FUNZIONE        PIC X(01).
SI0861 01  WK-XDAT-LEN-ESPANSA     PIC S9(8) COMP.
SI0861*01  WK-XDAT-ESPANSA         PIC X(16).
SA0953* Asteriscata la precedente
SA0953 01  WK-XDAT-ESPANSA         PIC X(128).
SI0861 01  WK-XDAT-LEN-COMPATTATA  PIC S9(8) COMP.
SI0861*01  WK-XDAT-COMPATTATA      PIC X(08).
SA0953* Asteriscata la precedente
SA0953 01  WK-XDAT-COMPATTATA      PIC X(64).

SI0921 COPY YZCWNSIC.
SI0921*---> COMMAREA PER GESTIONE PKC PROTETTA 3-DES
SI0921 COPY YZCTNSAT REPLACING 'YZCTNSAT' BY YZCTNSAT
SI0921                            'TNSAT' BY    TNSAT.
SI0921*---> COMMAREA PER GESTIONE PKC PROTETTA 3-DES
SI0921 COPY YZLK005T.
POSTE * ASTERISCATA LA PRECEDENTE XCHE' GIA' INSERITA PRIMA
SI0921*--->
SI0921 COPY XKCCSEMM REPLACING 'XKCCSEMM' BY XKCCSEMM
SI0921                            'CSEMM' BY    CSEMM.
SI0921*--->
SI0921 COPY XKCCTEST REPLACING 'XKCCTEST' BY XKCCTEST
SI0921                            'CTEST' BY    CTEST.
SI0921*--->
SI0921 COPY XKCCEXHE REPLACING 'XKCCEXHE' BY XKCCEXHE
SI0921                            'CEXHE' BY    CEXHE.
SI0921*--->
SI0921 COPY XKCCPRIM REPLACING 'XKCCPRIM' BY XKCCPRIM
SI0921                            'CPRIM' BY    CPRIM.
SI0921*--->
SI0921 COPY XKCCXNCH REPLACING 'XKCCXNCH' BY XKCCXNCH
SI0921                            'CXNCH' BY    CXNCH.
SI0921*---> Aree per la rilocazione dati se msg A71 con flag = 8
SI0921*
SI0921 01  WK-RILOCAZIONE.
SI0921     03 WK-POS-IN                     PIC S9(8) COMP VALUE +0.
SI0921     03 WK-POS-OUT                    PIC S9(8) COMP VALUE +0.
SI0921     03 WK-LEN                        PIC S9(4) COMP VALUE +0.
SI0921     03 WK-LEN-FISSA-A71              PIC S9(4) COMP VALUE +77.
SI0921     03 WK-LEN-FISSA-S71              PIC S9(4) COMP VALUE +49.
SI0921     03 WK-LEN-NR                     PIC S9(4) COMP VALUE +6.
SI0921     03 WK-LEN-MAX-INT                PIC S9(4) COMP VALUE +16.
SI0921     03 WK-LEN-FISSA                  PIC S9(4) COMP VALUE +0.
SI0921     03 WK-LEN-VAR                    PIC S9(4) COMP VALUE +0.
SI0921     03 WK-POS-IN-MAX-INT             PIC S9(4) COMP VALUE +0.
SI0921     03 WK-POS-OUT-MAX-INT            PIC S9(4) COMP VALUE +0.
SI0921     03 WK-POS-IN-VAR                 PIC S9(4) COMP VALUE +0.
SI0921     03 WK-POS-OUT-VAR                PIC S9(4) COMP VALUE +0.
SI0948*--->
SI0948 01  XKCCLKKM-AREA.
SI0948     COPY XKCCLKKM REPLACING 'XKCCLKKM' BY XKCCLKKM
SI0948                                 'LKKM' BY   CCLKKM.
SI0948*--->
SI0948     COPY YZCRNSTD.
SI0948*--->
SI0948 01  WK-MASTER-IST-PROT-PKC           PIC X(064).
XP1307*=*
XP1307*=* Aree per Nuovo Autorizzante POSTE
XP1307*=*
XP1307     COPY YZCWSVXX.
XP1307
POSTE>*=*
POSTE>     COPY YZCRKUTE REPLACING 'YZCRKUTE' BY YZCRKUTE
POSTE>                                'RKUTE'    BY RKUTE.
POSTE>
      *==============================================================*
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           03 COMM-RICE.
              05 FILLER           PIC X OCCURS 6000
                                        DEPENDING ON WKLENRIC.

COBOL2         COPY YZCWBLLS.
SI1030         COPY YZCWBLL1.

       01      LINK-MESSAGGIO         PIC X(4096).
               COPY YZCRYZ01.
       01      LINK-RISPOSTA.
            03 LINK-RISPOSTA-LUNG     PIC S9(4) COMP.
            03 LINK-RISPOSTA-DATI     PIC X(4094).
               COPY YZCRPOSI.
               COPY YZCRCIRC.
               COPY YZCREVID.
       01      LINK-CR-ANA     PIC    X(6500).
SI0179     COPY YZCTKABD REPLACING 'YZCTKABD' BY YZCTKABD
SI0179                                'TKABD' BY    TKABD.
SI0179     COPY YZCTKABD REPLACING 'YZCTKABD' BY YZCWYZ10-ABD
SI0179                                'TKABD' BY    WYZ10-ABD.
SI0179     COPY YZCWRCP.
SI1030*---
SI1030     COPY YZCRPOCA    REPLACING 'YZCRPOCA' BY YZCRPOCA
SI1030                                    'POCA' BY     POCA.


      *==============================================================*
       PROCEDURE DIVISION USING DFHCOMMAREA.
DBG==>     DISPLAY 'YZTCA70 -- Inizio pgm                '

           PERFORM                 FASE-COMUNE-INIZIALE
                            THRU F-FASE-COMUNE-INIZIALE.

      *------------------------- CALCOLO LUNGHEZZA AREA I/O D.C.
           CALL 'YYUA0982' USING STCWIODB STCWIODB-FINE WKLENIODB.

           MOVE COMMADRARK          TO YZCRANA-PTR.
201192     MOVE COMMADRPCB          TO YZCRANA-ADRPCB.
      *------------------------------------------------------------


           MOVE LINK-MESSAGGIO        TO YZCRMESS.
           MOVE YZCRMESS-DATI-MSG     TO YZCRA70.
           MOVE ZERO                  TO YZCRFIT.
021091     MOVE ZERO                  TO YZCRFITL.
           MOVE +77                   TO WK-LUNGH-A71.
OLCA2 *    COPY YZCPOL19.

OLCA1      COPY YZCPOL06.
           MOVE YZCRA70-ABI          TO WK-ABI-05.

           PERFORM                 ABI-PARTICOLARI
                            THRU F-ABI-PARTICOLARI.

XP1307*=*
XP1307*=*  Scelta dell'AUTORIZZANTE
XP1307*=*  Se autorizzazione via DSP innesca Network Manager ed esce
XP1307*=*  altrimenti prosegue normalmente
XP1307*=*
XP1307     COPY YZCPSVX1 Replacing 'YZCRXXX' By YZCRA70.
XP1307*=*

SI0179*    PERFORM                 LETTURA-TABELLA-ABI
SI0179*                     THRU F-LETTURA-TABELLA-ABI.
SI0179*
SI0179     PERFORM DETERMINA-AZI-ORI-CIR
SI0179     THRU  F-DETERMINA-AZI-ORI-CIR
SI0179     .
      *----
      *----
           PERFORM                 ELABORA-MESSAGGIO
                            THRU F-ELABORA-MESSAGGIO.
SI0921*    SET RYZ01-NUOVA-SICUREZZA-NO     TO TRUE
SA0953* asteriscata la predcedente

OLCA1      COPY YZCPOL01.
OLCA1      COPY YZCPOL03.

SA0953     IF OLCA-CIRC-A71
SA0953        IF RYZ01-NUOVA-SICUREZZA-SI
SA0959* ---
SA0959           MOVE YZCRMESS-DATI-MSG     TO YZCRA71
SA0959           MOVE YZCRA71-RESTO         TO COMM-MESSAGGIO
SA0959           MOVE YZCRA71-ANOM          TO COMM-MESS-ANOM
SA0959           IF YZCRYZ01-SECONDA-TRC = SPACES OR
SA0959              YZCRYZ01-SECONDA-TRC = ZEROES
SA0959              MOVE SPACES             TO YZCRA70-FLAG-AGGIORNA
SA0959           END-IF
SA0959* ---
SA0953           MOVE YZCRYZ01-NEW3D-NR     TO COMM-NR
SA0953     .
SA0953     SET RYZ01-NUOVA-SICUREZZA-NO     TO TRUE
SI0921*
SI0921*---> Se errore da elaborazione/autorizzazione
SI0921*--->    non effettuo le gestioni legate alla sicurezza
SI0921*--->    imposto la gestione sincrona o asincrona a vecchio
SI0921*--->    e vado direttamente a preparare la risposta
SI0921*
SI0921     IF COMM-ESITO-RICH NOT = 'OK'
SI0921        SET WK-TIPO-ELAB-OLD          TO TRUE
SI0921        GO TO SALTA-GESTIONE-CRYPTO-DEVICE
SI0921     .
SI0921*---> Se operazione non in aziendale oppure aziendale ma con OLA
SI0921*--->    non effettuo adesso le operazioni legate alla sicurezza
SI0921*--->    in quanto la PKC la invia il C.A.
SI0921*--->    imposto la gestione sincrona o asincrona a vecchio
SI0921*--->    e vado direttamente alla gestione dell'invio del msg rete
SI0921*
SI0921     IF COMM-ABI-CARTA NOT = COMM-ABI-TERM
SI0921        SET WK-TIPO-ELAB-OLD          TO TRUE
SI0921        GO TO SALTA-GESTIONE-CRYPTO-DEVICE
SI0921     .
SI0921     IF COMM-ABI-CARTA = COMM-ABI-TERM
SI0921        IF (WYZ10-ABD-B70-AZI-SI-CHIP AND RPOSI-CHIP-SI) OR
SI0921            WYZ10-ABD-B70-AZI-SI-TUTTE
SI0921           SET WK-TIPO-ELAB-OLD       TO TRUE
SI0921           GO TO SALTA-GESTIONE-CRYPTO-DEVICE
SI0921     .
SI0921*---> Se il cripto device da utilizzare e quello vecchio
SI0921*--->    (SSM o scheda - e PKC protetta da ZMKP1)
SI0921*--->    imposto la gestione sincrona o asincrona a vecchio
SI0921*--->    salto la nuova gestione
SI0921*
SI0921     IF YZCWYZ20-GEN-NSIC-DATA-DUAL > COMMDAY2
SI0921        IF WYZ20-GEN-3DES-CD-OLD
SI0921           MOVE '0'                   TO WK-TIPO-CRYPTO
SI0921           SET WK-TIPO-ELAB-OLD       TO TRUE
SI0921           GO TO VERIFICA-SE-CON-PKC-OLD
SI0921     .
SI0921*---> Forzo OK a inizio elaborazione
SI0921*
SI0921     SET WK-E-TMK-PKC-OS390-OK        TO TRUE
SI0921     .
SI0921*---> Solo se ancora in periodo di duality
SI0921*--->    Verifica dei paraetri decisionali a livello generale e di
SI0921*--->    istituto per determinare se la nuova modalit{ E-(lmk,pkc)
SI0921*---> altrimenti
SI0921*--->    posso utilizzare solo la nuova modalit{
SI0921*
SI0921     IF YZCWYZ20-GEN-NSIC-DATA-DUAL > COMMDAY2
SI0921
SI0921        PERFORM VERIFICA-SE-USO-3DES
SI0921        THRU  F-VERIFICA-SE-USO-3DES
SI0921
SI0921        IF WK-AUTORIZZO-VIA-OS390-NO
SI0921           GO TO VERIFICA-SE-CON-PKC-OLD
SI0921        END-IF
SA0950*       IF COMM-E-3DES-PKC = ZEROES OR
SA0950*          COMM-E-3DES-PKC = SPACES OR
SA0950*          COMM-E-3DES-PKC = LOW-VALUE
SA0953* ASTERISCATE LE 3 PRECEDENTI
SA0953        IF COMM-E-3DES-PKC(1:16) = ZEROES OR
SA0953           COMM-E-3DES-PKC(1:16) = SPACES OR
SA0953           COMM-E-3DES-PKC(1:16) = LOW-VALUE
SA0950           MOVE SPACES                   TO STCW196-MSG
SA0950           MOVE 'xPKC'                   TO STCW196-RIFERIMENTO
SA0950           STRING 'YZTCA70 - PKC 3DES non '
SA0950                  'valorizzata| Pan '
SA0950                  COMM-PAN-RICH
SA0950                  ' forzato utilizzo old CD '
SA0950           DELIMITED BY SIZE INTO STCW196-MSG
SA0950           PERFORM SCRIVI-LOG-ERRORI
SA0950           THRU  F-SCRIVI-LOG-ERRORI
SA0950           SET WK-AUTORIZZO-VIA-OS390-NO TO TRUE
SA0950           GO TO VERIFICA-SE-CON-PKC-OLD
SA0950        END-IF
SI0921     ELSE
SA0950*       IF COMM-E-3DES-PKC = ZEROES OR
SA0950*          COMM-E-3DES-PKC = SPACES OR
SA0950*          COMM-E-3DES-PKC = LOW-VALUE
SA0953* ASTERISCATE LE 3 PRECEDENTI
SA0953        IF COMM-E-3DES-PKC(1:16) = ZEROES OR
SA0953           COMM-E-3DES-PKC(1:16) = SPACES OR
SA0953           COMM-E-3DES-PKC(1:16) = LOW-VALUE
SA0950           SET WK-AUTORIZZO-VIA-OS390-SImaKO TO TRUE
SA0950           SET WYZ20-GEN-OS390-BCM-SSM-NO TO TRUE
SA0950           SET WK-TIPO-ELAB-SYNC          TO TRUE
SA0950           MOVE SPACES                    TO STCW196-MSG
SA0950           MOVE 'KPKC'                    TO STCW196-RIFERIMENTO
SA0950           STRING 'YZTCA70 - Fine duality con SSM e PKC 3DES non '
SA0950                  'valorizzata| Pan '
SA0950                  COMM-PAN-RICH
SA0950           DELIMITED BY SIZE INTO STCW196-MSG
SA0950           PERFORM SCRIVI-LOG-ERRORI
SA0950           THRU  F-SCRIVI-LOG-ERRORI
SA0950           GO TO SALTA-GESTIONE-CRYPTO-DEVICE
SA0950        END-IF
SI0921        SET WK-AUTORIZZO-VIA-OS390-SI    TO TRUE
SI0921        SET WYZ20-GEN-OS390-BCM-SSM-NO   TO TRUE
SI0921     .
SI0921*---> Riporto in working l'informazione di quale tipo di crypto
SI0921*---> device devo utilizzare partendo dalla geb/gen o geb/abd
SI0921*
SI1221*--- se nuova gestione del RKL la determinazione del CD in uso
SI1221*--- } a carico della sicuerzza
SI1221     IF  RYZ01-ATM-CON-SOFT-3DES-RKM
SI1221         CONTINUE
SI1221     ELSE
SI0921     PERFORM MERGE-DECISIONALI
SI0921     THRU  F-MERGE-DECISIONALI
SI0921     .
SI0921     PERFORM GESTIONE-PKC-CON-3DES
SI0921     THRU  F-GESTIONE-PKC-CON-3DES
SI0921     .
SI0921*---> Se periodo di duality
SI0921*--->    Se elaborazione non eseguita con la nuova modalitä
SI0921*--->       o errore
SI0921*--->          Vado a verificare se possibile l'utilizzo old CD
SI0921*--->    altrimenti
SI0921*--->          proseguo con l'elaborazione della rich di autor
SI0921*---> altrimenti
SI0921*--->    Se elaborazione non eseguita con la nuova modalitä
SI0921*--->       o errore
SI0921*--->          imposto il flag utilizzato dalla vecchia gestione
SI0921*--->          per:
SI0921*--->          1 - deterinare il KO in autorizzazione
SI0921*--->          2 - per non permettere il backup su SSM
SI0921*--->          vado alla preparazione del messaggio di risposta
SI0921*--->          con errore
SI0921*--->    altrimenti
SI0921*--->          proseguo con l'elaborazione della rich di autor
SI0921*
SI0921     IF YZCWYZ20-GEN-NSIC-DATA-DUAL > COMMDAY2
SI0921        IF WK-AUTORIZZO-VIA-OS390-NO OR
SI0921           WK-E-TMK-PKC-OS390-KO
SI0921           SET WK-TIPO-ELAB-OLD              TO TRUE
SI0921           GO TO VERIFICA-SE-CON-PKC-OLD
SI0921        ELSE
SI0921           GO TO SALTA-GESTIONE-CRYPTO-DEVICE
SI0921     ELSE
SI0921        IF WK-AUTORIZZO-VIA-OS390-NO     OR
SI0921           WK-E-TMK-PKC-OS390-KO
SI0921           SET WK-AUTORIZZO-VIA-OS390-SImaKO TO TRUE
SI0921           SET WYZ20-GEN-OS390-BCM-SSM-NO    TO TRUE
SI0921           SET WK-TIPO-ELAB-SYNC             TO TRUE
SI0921           GO TO SALTA-GESTIONE-CRYPTO-DEVICE
SI0921        ELSE
SI0921           GO TO SALTA-GESTIONE-CRYPTO-DEVICE
SI0921     .
SI0921 VERIFICA-SE-CON-PKC-OLD.
SI0800*-------------------------------> VERIFICO SE ABI/ATM AUTORIZZA
SI0800*-------------------------------> IN MANIERA SINCRONA LE CARTE
SI0800*-------------------------------> AZIENDALI
SI0800     PERFORM CHECK-UTILIZZO-OS390
SI0800     THRU  F-CHECK-UTILIZZO-OS390.
SI0800
SI0800*-----------------------------------------------------------------
SI0800*---------------------------------- CHIAMATA A SCHEDA PER CALCOLO
SI0800*---------------------------------- E(TMK, PKC)
SI0800*-----------------------------------------------------------------
SI0800     PERFORM GESTIONE-E-TMK-PKC-VIA-OS390
SI0800     THRU  F-GESTIONE-E-TMK-PKC-VIA-OS390.
SI0800
SI0921 SALTA-GESTIONE-CRYPTO-DEVICE.
      *----
OLCA1 *----------------------------------------------------------------
OLCA1 * ATTENZIONE LA LETTURA DI TABELLA FIT DEVE ESSERE
OLCA1 * EFFETTUATA SOLO SE NON SI VERIFICANO I CASI SUCCESSIVI
OLCA1 * VERIFICARE CHE NELLA VERSIONE DI YZTCA70 PRESENTE I TESTS SIANO
OLCA1 * EFFETTIVAMENTE IMPOSTATI IN QUESTO MODO
OLCA1 *----------------------------------------------------------------
OLCA1      IF NON-OLCA OR OLCA-CIRC-A71 OR SOSPESO-X-TO OR INATTIVO
SI0800     OR WK-AUTORIZZO-VIA-OS390-SI
250292     IF  COMM-ESITO-RICH    =     'KO'
250292     OR  COMM-ESITO-RICH    =     'NP'
250292     OR  COMM-ESITO-RICH    =     'RE'
250292     OR  COMM-ESITO-RICH    =     'CA'
250292         NEXT SENTENCE
250292     ELSE

130395       IF YZCRA70-STATO  =  ZERO
SI0800*      AND WK-AUTORIZZO-VIA-OS390-NO
SA0874* asteriscata la precedente (deve essere garantita la rimagn.)

               PERFORM                 LETTURA-FIT
                                THRU F-LETTURA-FIT
131191*        ESTRAZIONE EVENTUALE III TRACCIA DA INVIARE
010894        IF  COMM-ABI-TERM  =  COMM-ABI-CARTA
010894        AND YZCRA70-STATO  =  ZERO
131191         PERFORM CERCA-TERZA-TRACCIA THRU F-CERCA-TERZA-TRACCIA.
      *----
OLCA1      IF NON-OLCA OR OLCA-CIRC-A71 OR SOSPESO-X-TO OR INATTIVO
SI0800     OR WK-AUTORIZZO-VIA-OS390-SI
           PERFORM                 PREPARA-RISPOSTA
                            THRU F-PREPARA-RISPOSTA.
      *----
SI0143     PERFORM  IMPOSTA-DIVISA-X-DISP-SALDO
SI0143        THRU  F-IMPOSTA-DIVISA-X-DISP-SALDO
SI0143     .
SI0143*----
BALDAX*    IF YZCRA71-DISP-X NOT = ZERO
PTEURO*---  ASTERISCATA LA PRECEDENTE
PTEURO     IF YZCRA71-DISP-X(2:) NOT = ZERO
SP0211     AND YZCRA70-TIPORAP NOT = '9' AND
SP0211         YZCRA70-RESTROP NOT = '8'
BALDAX        PERFORM PRENOTA-DISPONIBILITA
BALDAX         THRU F-PRENOTA-DISPONIBILITA
BALDAX     .
SA0856*--> SE PREPAGATA NON FACCIO ENTRARE IN GIOCO LA OS390 PER
SA0856*--> L'AUTORIZZAZIONE AZIENDALE.
SA0874*--> solo pero se la prepagata e in ola
SA0856     IF YZCRA70-TIPORAP = '9' AND
SA0856        YZCRA70-RESTROP = '8'
SA0874     AND WYZ10-ABD-AUT-PREP-OLA
SA0856        CONTINUE
SA0856     ELSE
SI0800     IF WK-AUTORIZZO-VIA-OS390-SI
SI0800        IF WK-AUTORIZZO-VIA-OS390-SImaKO
SI0800           IF WYZ20-GEN-OS390-BCM-SSM-NO
SI0800              PERFORM RICOSTRUISCI-X71-X-ANOMALIA
SI0800              THRU  F-RICOSTRUISCI-X71-X-ANOMALIA
SI0800              GO TO SKIP-SIM
SI0800           END-IF
SI0800        ELSE
SI0800           GO TO SKIP-SIM
SI0800        END-IF
SI0800     END-IF
SI0800     .
OLCA2      COPY YZCPOL49.
SI0800
SI0800*________*
SI0800 SKIP-SIM.
SI0800
SA0874*--->
SA0874*---> AGGIORNO SUBITO I DATI SUL FILE TERINALI, ALCUNI SERVONO
SA0874*---> NELLA ROUTINE SCRITTURA-MESSAGGIO-RISPOSTA E
SA0874*---> RISPONDI-A-TERINALE
SA0874*--->
SA0874     PERFORM IMP-DATI-SU-TERM
SA0874     THRU  F-IMP-DATI-SU-TERM
SA0874     .
SI0800*-->
SI0800*--> SE AUTORIZZO VIA OS390 VERIFICO SE ATM VIRTUALE PER
SI0800*--> STARTARE UI02 PIUTTOSTO CHE RISPONDERE ALL'ATM
SI0800*-->
SI0800*    IF WK-AUTORIZZO-VIA-OS390-SI
SI0800*       PERFORM SET-DESTINATARIO-RISPOSTA
SI0800*       THRU  F-SET-DESTINATARIO-RISPOSTA
SI0800*       IF RISPONDO-A-INTERNET-SI
SI0800*          PERFORM STARTA-UI02
SI0800*          THRU  F-STARTA-UI02
SI0800*          GO TO AGGIORNAMENTI-FINALI
SI0800*       END-IF
SI0800*    END-IF.
SA0874* asteriscate le 9 precedenti (non esite A70 da atm virtuale)
SI0800*
SI0921*--->
SI0921*---> Se la modalita di chiamata al nuovo cd e asincrona
SI0921*--->    chiamo il crypto device
SI0921*--->    se errore da crypto device
SI0921*--->       costruzione messaggio A71 con errore
SI0921*--->       la routine riconverte la modalita in syncrono
SI0921*--->       per permettere la risposta all ATM
SI0921*--->
SI0921     IF WK-TIPO-ELAB-ASYNC
SI0921        PERFORM ELABORA-CHIAMATA-HSM-ASYNC
SI0921        THRU  F-ELABORA-CHIAMATA-HSM-ASYNC
SI0921        IF WK-E-TMK-PKC-OS390-KO
SI0921           PERFORM RICOSTRUISCI-X71-X-ANOMALIA
SI0921           THRU  F-RICOSTRUISCI-X71-X-ANOMALIA
SI0921     .
OLCA1      IF NON-OLCA OR OLCA-CIRC-A71 OR SOSPESO-X-TO OR INATTIVO
SI0800     OR WK-AUTORIZZO-VIA-OS390-SI
SI0921     IF NOT WK-TIPO-ELAB-ASYNC
           PERFORM                 SCRITTURA-MESSAGGIO-RISPOSTA
                            THRU F-SCRITTURA-MESSAGGIO-RISPOSTA.
      *----
OLCA1      IF NON-OLCA OR OLCA-CIRC-A71 OR SOSPESO-X-TO OR INATTIVO
SI0800     OR WK-AUTORIZZO-VIA-OS390-SI
SI0921     IF NOT WK-TIPO-ELAB-ASYNC
           PERFORM                 RISPONDI-A-TERMINALE
                            THRU F-RISPONDI-A-TERMINALE.
      *----
OLCA1 *-------------------------------------------------------------
OLCA1 *    SE SIAMO IN OLCA E IL MESSAGGIO E' A70 CHIAMIAMO
OLCA1 *    IL PROGRAMMA DI GESTIONE OLCA
OLCA1 *-------------------------------------------------------------
OLCA1      IF SOSPESO-X-TO OR INATTIVO
OLCA1         NEXT SENTENCE
OLCA1      ELSE
OLCA1         IF OLCA-CIRC-A70
ICCRI            IF YZCWYZ20-GEN-RETE-APPARTENENZA NOT = '3'
OLCA1               MOVE WK-YZTCOLLA       TO WKPGMSUC
OLCA1               PERFORM                 CHIAMA-ALTRO-PROGRAMMA
OLCA1                                THRU F-CHIAMA-ALTRO-PROGRAMMA
ICCRI            ELSE
ICCRI               MOVE WK-YZTCB70        TO WKPGMSUC
ICCRI               PERFORM                 CHIAMA-ALTRO-PROGRAMMA
ICCRI                                THRU F-CHIAMA-ALTRO-PROGRAMMA.
OLCA1
OLCA2  AGGIORNAMENTI-FINALI.
      *----
           PERFORM                 AGGIORNA-FILE-TERMINALI
                            THRU F-AGGIORNA-FILE-TERMINALI.
      *----
           IF  WK-RISCRITTURA    NOT = 'NO'
200592       IF YZCRA70-STATO = ZERO
               PERFORM                 RISCRIVI-POS-STORI
                                THRU F-RISCRIVI-POS-STORI.

           MOVE   'OK'      TO COMM-ESITO-GENERALE.

       FINE.
OLCA2      COPY YZCPENDP.

XI0703*-->
XI0703*--> Verifico ed eventualmente invio un ALERT al cliente
XI0703*-->
XI0703     IF COMM-ESITO-RICH = 'KO'
XI0703     OR COMM-ESITO-RICH = 'NP'
XI0703     OR COMM-ESITO-RICH = 'RE'
XI0703     OR COMM-ESITO-RICH = 'CA'
XI0703        PERFORM VERIFICA-E-INVIA-ALERT
XI0703        THRU  F-VERIFICA-E-INVIA-ALERT
XI0703     END-IF.
XI0703
           MOVE COMMAREA        TO DFHCOMMAREA.
           COPY YYCP0182.
           GOBACK.

      *-------------------------  ERRORI NON PERVISTI
       MAINERR.
           COPY YYCP0180.
      *-------------------------
       MAINERX.
           MOVE   'KO' TO COMM-ESITO-GENERALE.
           GO     TO FINE.
       END-PROGRAM.
           GOBACK.
      *==============================================================*

       ELABORA-MESSAGGIO.

      *----  ATTUALIZZA L'AREA PER IL POSITIVO DELLA CARTA
      *----  E DELLO STORICO CHE POTRANNO ESSERE
      *----  RIEMPITE DAI PROGRAMMA YZTCGB04/GB05

COBOL2     COPY YZCPYZ31.
XP1307* ---
XP1307     IF (YZ01-AUTORIZZANTE-ISO OR
XP1307         YZ01-AUTORIZZANTE2-ISO)                AND
XP1307*         YZCRYZ01-UTE-DISPON IS NUMERIC        AND
XP1307*         YZCRYZ01-UTE-DISPON > ZEROES          AND
XP1307          YZCRYZ01-RRN-MSG-ISO IS NUMERIC       AND
XP1307          YZCRYZ01-RRN-MSG-ISO > ZEROES
XP1307        PERFORM INOLTRO-STORNO-A-DSP
XP1307        THRU  F-INOLTRO-STORNO-A-DSP
XP1307     .

R01912*--->Segnalazione eventuale prenotata in sospeso
R01912     IF  YZCRYZ01-ULT-NUMMOVI-CC NOT = SPACES
R01912     AND YZCRYZ01-ULT-NUMMOVI-CC NOT = LOW-VALUE
R01912     AND YZCRYZ01-ULT-NUMMOVI-CC NOT = '00000000000000000000'
R01912        IF YZCRYZ01-IMPORTO-PREP NOT NUMERIC OR
R01912           YZCRYZ01-IMPORTO-PREP = ZEROES
R01912            PERFORM SEGNALA-PRENOTATA-IN-SOSP
R01912            THRU  F-SEGNALA-PRENOTATA-IN-SOSP
R01912        END-IF
R01912     END-IF
SI0601*--->
SI0601*--->
SI0601*--->
SI0601     IF YZCRYZ01-IMPORTO-PREP NOT NUMERIC OR
SI0601        YZCRYZ01-IMPORTO-PREP = ZEROES
SI0601        CONTINUE
SI0601     ELSE
SI0601        PERFORM SEGNALA-PREP-IN-SOSP
SI0601        THRU  F-SEGNALA-PREP-IN-SOSP
SA0714        PERFORM CHIUDI-PER-PREPAGATE-PREC
SA0714        THRU  F-CHIUDI-PER-PREPAGATE-PREC
SI0601        MOVE ZEROES                   TO YZCRYZ01-IMPORTO-PREP
SI0601     .
           MOVE ZERO                  TO COMM-RICHIESTE.
           MOVE YZCRA70-PAN           TO COMM-PAN-RICH.
SI0905     MOVE YZCRA70-FLAG-AGGIORNA TO WK-SAVE-FLAG-AGGIORNA
OLCA1 *OLCA2    IF OLCA1 OR OLCA2
ICCRI *OLCA2       OR YZCWYZ20-GEN-RETE-APPARTENENZA = '3'
OLCA1         MOVE YZCRMESS-CODMES TO WK-MESSAGGIO-PER-TEST
OLCA1         IF  WK-MESSAGGIO-TIPO-A71
OLCA1             GO TO F-ELABORA-MESSAGGIO.

SI0666*----------------------------------------------------------------*
SI0666*----------------------------------------------------------------*
SI0666*----------------------------------------------------------------*
SI0666     IF YZCRA70-ANOM = 'M9'
SI0666        MOVE ZEROES                   TO YZCRA70-ANOM
SI0666        MOVE 'M9'                     TO STCW196-RIFERIMENTO
SI0666        MOVE SPACES                   TO STCW196-MSG
SI0666        STRING 'ATM '
SI0666               YZCRYZ01-CODABI
SI0666               ' / '
SI0666               YZCRYZ01-CODATM
SI0666               ' INCONGRUENZA CAMPO 19 TERZA TRACCIA/APPL.'
SI0666               ' PRESENTE SU CHIP'
SI0666               DELIMITED BY SIZE INTO STCW196-MSG
SI0666        PERFORM SCRIVI-LOG-ERRORI
SI0666        THRU  F-SCRIVI-LOG-ERRORI
SI0666     .
SI0417*----------------------------------------------------------------*
SI0417* CONTROLLO ANOMALIE REGISTRATE NEL MESSAGGIO DI INPUT           *
SI0417* RELATIVE AL MICROCIRCUITO                                      *
SI0417* VENGONO SOLO SEGNALATE SUL LOG ERRORI LE ANOMALIE              *
SI0417* FB - "FALL BACK" IN CASO DI FUORI SERVIZIO DEL LETTORE CHIP    *
SI0417*      OPPURE IN CASO DI ERRORE IN LETTURA DEI DAI MICROCIRCUITO *
SI0417*----------------------------------------------------------------*
SI0417     IF YZCRA70-ANOM = 'FB'
SI0417        MOVE ZEROES                   TO YZCRA70-ANOM
R10112      IF YZCRYZ01-DATI-TER-VERS-SW(1:1) < '5'
SI0417        MOVE 'FB'                     TO STCW196-RIFERIMENTO
SI0417        MOVE SPACES                   TO STCW196-MSG
SI0417        MOVE 'ABI/ATM '               TO STCW196-MSG(01:08)
SI0417        MOVE YZCRYZ01-CODABI          TO STCW196-MSG(09:04)
SI0417        MOVE '/'                      TO STCW196-MSG(13:01)
SI0417        MOVE YZCRYZ01-CODATM          TO STCW196-MSG(14:04)
SI0417        MOVE ' PAN '                  TO STCW196-MSG(18:05)
SI0417        MOVE YZCRA70-PAN              TO STCW196-MSG(23:17)
SI0417        MOVE ' ATTIVATA PROCEDURA DI FALL BACK '
SI0417                                      TO STCW196-MSG(40:40)
SI0417        PERFORM SCRIVI-LOG-ERRORI
SI0417        THRU  F-SCRIVI-LOG-ERRORI
SI0417     .
      *----------------------------------------------------------------*
      * CONTROLLO ANOMALIE REGISTRATE NEL MESSAGGIO DI INPUT     (1)   *
      *----------------------------------------------------------------*

           IF   YZCRA70-ANOM NOT EQUAL ZERO
                MOVE 00001             TO YZCWYZ05-RIFERIMENTO
                MOVE YZCRA70-ANOM      TO COMM-ANOMA-RICH
                GO TO ERRORE-TERMINALI.

      *----------------------------------------------------------------*
      * CONTROLLI FUORI SERVIZIO                                 (2)   *
      *----------------------------------------------------------------*

R14304*---  DISASTERISCATO IL CONTROLLO SUCCESSIVO
R14304     IF   YZCRYZ01-SERVUTE NOT = ZERO
R14304          MOVE 00002             TO YZCWYZ05-RIFERIMENTO
R14304          MOVE 40                TO COMM-ANOMA-RICH
R14304          GO TO ERRORE-TERMINALI.

      *----------------------------------------------------------------*
      * CONTROLLI PER RECORD ARRIVATI OFFLINE                    (3)   *
      *----------------------------------------------------------------*
SI0821     IF   YZCRA70-STATO NOT = '0' AND '1'
SI0821          MOVE 00065             TO YZCWYZ05-RIFERIMENTO
SI0821          GO TO ERRORE-TERMINALI.

           IF   YZCRA70-STATO = ZERO
               MOVE ZERO TO YZCRYZ01-A70-S70-OFFLINE
030792         MOVE ZERO TO YZCRYZ01-SERVUTE
           ELSE
               MOVE '1'  TO YZCRYZ01-A70-S70-OFFLINE.
SI1241*---
SI1241*---  Nel caso stia lavorando un Chiosco definito precedentemente
SI1241*--- l'avvento della scheda SI1241, imposto il TIPO-TERM in modo
SI1241*--- congruente con il terminale cosi' da aggiornare il parco mac-
SI1241*--- chine automaticamente con la nuova modalita'
SI1241     IF YZCRYZ01-TIPO-TERM = 2  AND
SI1241        YZCRYZ01-CHIOSCO = 'S'
SI1241        MOVE 30                    TO YZCRYZ01-TIPO-TERM
SI1241     .
R20404*
R20404*---  CONTROLLO CHE LA RELEASE SW NON SIA SCADUTA.
R20404     PERFORM CNTL-REL-SW          THRU F-CNTL-REL-SW
R20404     .
R20404     IF  WK-FLAG-TERM = '1'
R20404          MOVE 00090             TO YZCWYZ05-RIFERIMENTO
R20404          MOVE 40                TO COMM-ANOMA-RICH
R20404          GO TO ERRORE-TERMINALI
R20404     .
R42304*---  Controllo della profilatura del terminale
R42304     PERFORM CNTL-PROF-UTE        THRU F-CNTL-PROF-UTE
R42304     .
200592     IF YZCRA70-STATO = '1'
200592         GO TO F-ELABORA-MESSAGGIO.

R06606*---  Leggo la tabella dell'operativita' ATM per verificare se ci
R06606*--- sono restrizioni operative sull'applicazione
R06606     PERFORM LEGGI-TKOPE-ATM   THRU F-LEGGI-TKOPE-ATM
R06606     .
R06606     IF TKOPE-OPE-ATM-ATTIVO
R06606        PERFORM
R06606        VARYING IND-OPE           FROM 1 BY 1
R06606          UNTIL IND-OPE > 25
R06606             OR YZCTKOPE-ATM-CODATM(IND-OPE) = YZCRYZ01-CODATM
R06606        END-PERFORM
R06606        IF IND-OPE > 25
R06606           MOVE '15'               TO COMM-ANOMA-RICH
R06606           MOVE 'KO'               TO COMM-ESITO-RICH
R06606           MOVE 'NO'               TO WK-RISCRITTURA
R06606           MOVE 1                  TO SW-ERRORE
R06606           GO TO F-ELABORA-MESSAGGIO
R06606        END-IF
R06606     ELSE
R06606        MOVE ZEROES                TO YZCTKOPE
R06606     .
      *----------------------------------------------------------------*
      * CEDO IL CONTROLLO AL PROGRAMMA YZTCGB07 PER:                   *
      * A - VERIFICARE CHE LA CARTA NON SIA SULLE EVIDENZE             *
      * B - CHE LA BANCA SIA IN CIRCOLARITA'                           *
      * C - CHE LA DATA EMISSIONE DELLA CARTA SIA COMPRESA NEL PERIODO *
      *     DI VALIDITA' DELL' ISTITUTO                                *
      *----------------------------------------------------------------*

           MOVE YZCRA70-EMISS             TO COMM-DATA-EMISS.
           MOVE 'YZTCGB07'                TO WKPGMSUC.
           PERFORM CHIAMA-ALTRO-PROGRAMMA THRU F-CHIAMA-ALTRO-PROGRAMMA.

           IF  COMM-ESITO-RICH    =     'KO'
210292     OR  COMM-ESITO-RICH    =     'RE'
210292     OR  COMM-ESITO-RICH    =     'CA'
               MOVE 'NO'        TO   WK-RISCRITTURA
               GO TO F-ELABORA-MESSAGGIO.

      *----------------------------------------------------------------*
      * CONTROLLO LA VALIDITA' DEI DATI DI TERZA TRACCIA         (7)   *
      *----------------------------------------------------------------*
110593
110593     IF YZCRA70-PAN-CONTO NOT NUMERIC
110593     OR YZCRA70-PAN-CONTO = ZERO
110593        MOVE 00053             TO YZCWYZ05-RIFERIMENTO
110593        GO TO DATI-TRACCIA-NON-VALIDI.

           IF YZCRA70-TIPODATI NOT = 1
              MOVE 00003             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

           IF YZCRA70-TIPOPER NOT = 80 AND NOT = 83
              MOVE 00004             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

      *--- IN WK-AAMMGG-A  E' IMPOSTATA LA DATA DEL SISTEMA  ------*
           MOVE COMM-AAMMGG-CONT          TO WK-AAMMGG-A

           MOVE  YZCRA70-INIZPER          TO WK-GGMMAA-C
           MOVE WK-GG-C                   TO WK-GG-B
           MOVE WK-MM-C                   TO WK-MM-B
           MOVE WK-AA-C                   TO WK-AA-B
SI0143*---
SI0143     MOVE WK-AAMMGG-A                TO T12-0-IN-19-DATA
SI0143     MOVE WK-AAMMGG-B                TO T12-0-IN-29-DATA
SI0143     COPY YYCPAAMM.
SI0143*---

SI0143*    IF WK-AAMMGG-A        <      WK-AAMMGG-B
SI0143     IF ERR-RICH = 'S'
              MOVE 00005             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

291293* VEROLI PER EVITARE L'ELABORAZIONE SE DATA INIZPER
291293* NON VIENE CORRETTAMENTE NORMALIZZATA DALL'ATM
SI0143**ASTERISCATE LE 4 RIGHE SUCCESSIVE
291293*    COMPUTE WK-AA-C = WK-AA-A - WK-AA-B
291293*    IF WK-AA-C > 8
291293*       MOVE  00054            TO YZCWYZ05-RIFERIMENTO
291293*       GO TO DATI-TRACCIA-NON-VALIDI.
SI0143
SI0143     IF  WK-AA-A  > 80
SI0143         COMPUTE WK-A-SSAA = 1900 + WK-AA-A
SI0143     ELSE
SI0143         COMPUTE WK-A-SSAA = 2000 + WK-AA-A
SI0143     .
SI0143     IF  WK-AA-B  > 80
SI0143         COMPUTE WK-B-SSAA = 1900 + WK-AA-B
SI0143     ELSE
SI0143         COMPUTE WK-B-SSAA = 2000 + WK-AA-B
SI0143     .
SI0143     COMPUTE WK-C-SSAA  =  WK-A-SSAA - WK-B-SSAA
SI0143     IF  WK-C-SSAA  >  8
SI0143        MOVE  00054            TO YZCWYZ05-RIFERIMENTO
SI0143        GO TO DATI-TRACCIA-NON-VALIDI
SI0143     .

           IF YZCRA70-TIPOPER = 80 AND YZCRA70-DISPER > 500
              MOVE 00006             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

           IF YZCRA70-RESPER > YZCRA70-DISPER
              MOVE 00007             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

      *--- IN WK-AAMMGG-A  E' IMPOSTATA LA DATA DEL SISTEMA  ------*
           MOVE YZCRA70-DATAOP            TO WK-GGMMAA-C.
           MOVE WK-GG-C                   TO WK-GG-B
           MOVE WK-MM-C                   TO WK-MM-B
           MOVE WK-AA-C                   TO WK-AA-B
SI0143*---
SI0143     MOVE WK-AAMMGG-A                TO T12-0-IN-19-DATA
SI0143     MOVE WK-AAMMGG-B                TO T12-0-IN-29-DATA
SI0143     COPY YYCPAAMM.
SI0143*---

SI0143*    IF WK-AAMMGG-B        > WK-AAMMGG-A
SI0143     IF ERR-RICH = 'S'
R00604*     IF  YZCRYZ01-DATI-TER-VERS-SW NOT > '3000311'
R00604*     AND YZCRA70-INIZPER               = 010103
R00604*     AND YZCRA70-DATAOP(3:4)           = 0104
R00604*       MOVE 0103 TO YZCRA70-DATAOP(3:4)
R00604*      ELSE
R01604*       IF  YZCRYZ01-DATI-TER-VERS-SW NOT > '3000311'
R01604*       AND YZCRA70-INIZPER               = 010102
R01604*       AND YZCRA70-DATAOP(3:4)           = 0104
R01604*         MOVE 0102 TO YZCRA70-DATAOP(3:4)
R01604*       ELSE
R04304*---  ASTERISCATE LE 10 RIGHE PRECEDENTI.
R00305        IF  YZCRYZ01-DATI-TER-VERS-SW NOT > '3000411'
R00305        AND YZCRA70-INIZPER               = 010104
R00305        AND YZCRA70-DATAOP(3:4)           = 0105
R00305           MOVE 0104               TO YZCRA70-DATAOP(3:4)
R00305        ELSE
              MOVE 00008             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

           IF YZCRA70-DISTPER > YZCRA70-DISPER
              MOVE 00009             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

           IF YZCRA70-RESTPER > YZCRA70-DISTPER
              MOVE 00010             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

           IF YZCRA70-RESTPER > YZCRA70-RESPER
              MOVE 00011             TO YZCWYZ05-RIFERIMENTO
              GO TO DATI-TRACCIA-NON-VALIDI.

           MOVE YZCRA70-EMISS             TO WK-GGMMAA-C.
           MOVE WK-GG-C                   TO WK-GG-B
           MOVE WK-MM-C                   TO WK-MM-B
           MOVE WK-AA-C                   TO WK-AA-B

      *--- IN WK-AAMMGG-A  E' IMPOSTATA LA DATA DEL SISTEMA  ------*

           IF WK-AAMMGG-B        NOT = ZERO
SI0143        MOVE WK-AAMMGG-A                TO T12-0-IN-19-DATA
SI0143        MOVE WK-AAMMGG-B                TO T12-0-IN-29-DATA
SI0143        COPY YYCPAAMM.
SI0143*       IF WK-AAMMGG-A        < WK-AAMMGG-B
SI0143        IF ERR-RICH = 'S'
                 MOVE 00012             TO YZCWYZ05-RIFERIMENTO
                 GO TO DATI-TRACCIA-NON-VALIDI
              ELSE
200694           PERFORM  IMPOSTA-DATA-CON-SECOLO
200694            THRU  F-IMPOSTA-DATA-CON-SECOLO
                 IF  YZCRA70-SCAD NOT = ZERO AND
120392*              WK-AAMMGG-A / 100 NOT < YZCRA70-SCAD
200694*120392        WK-AAMMGG-A / 100     > YZCRA70-SCAD
200694               WK-SSAAMMGG-SSAAMM    > WK-SCAD-SSAAMM
                     MOVE 00013       TO YZCWYZ05-RIFERIMENTO
                     GO TO DATI-TRACCIA-NON-VALIDI
                 ELSE
                     NEXT SENTENCE
           ELSE
              IF YZCRA70-SCAD = ZERO
                 MOVE 00014             TO YZCWYZ05-RIFERIMENTO
                 GO TO DATI-TRACCIA-NON-VALIDI.
BLDX03*---
BLDX03*---  SE L'OPERAZIONE E' DELLE 23.58 O 23.59 NON LA RENDO POSSIBI-
BLDX03*--- LE PER FARE IN MODO DI NON SPUTTANARE LE CARTE A CAVALLO DEL-
BLDX03*--- LA MEZZANOTTE CON LA DATA ULTIMA OPERAZIONE SULLA CARTA.
BLDX03*---  QUESTA MODIFICA E' NECESSARIA AFFINCHE' I TERMINALI NON FA-
BLDX03*--- RANNO L'ALLINEAMENTO DELL'ORARIO SUL MSG A71
BLDX03     IF YZCRA70-ORAMES = 2358 OR 2359
BLDX03        MOVE '15'                  TO COMM-ANOMA-RICH
BLDX03        MOVE 'KO'                  TO COMM-ESITO-RICH
BLDX03        MOVE 'NO'                  TO WK-RISCRITTURA
BLDX03        MOVE 1                     TO SW-ERRORE
BLDX03        GO TO F-ELABORA-MESSAGGIO
BLDX03     .
R11903*---  NON FACCIO OPERARE TUTTE LE CARTE CHE SI PRESENTANO DALLA
R11903*--- MEZZANOTTE ALL'UNA SUGLI ATM CHE HANNO IL SW AURIGA
R12603*--- COMPRESO TRA LA VERSIONE 3000000 E LA VERSIONE 3000310
R11903     IF YZCRYZ01-DATI-TER-VERS-SW NOT < '3000000'
R12603     AND YZCRYZ01-DATI-TER-VERS-SW NOT > '3000310'
R11903        IF YZCRA70-ORAMES < 0101
R11903           MOVE '15'               TO COMM-ANOMA-RICH
R11903           MOVE 'KO'               TO COMM-ESITO-RICH
R11903           MOVE 'NO'               TO WK-RISCRITTURA
R11903           MOVE 1                  TO SW-ERRORE
R11903           GO TO F-ELABORA-MESSAGGIO
R11903        END-IF
R11903     .
            GO TO FINE-CONTROLLI-FORMALI.
      *----------------------------------------------------------------*
      * SEGNALAZIONI PER DATI TRACCIA NON VALIDI                       *
      *----------------------------------------------------------------*
       DATI-TRACCIA-NON-VALIDI.
           MOVE 13                TO COMM-ANOMA-RICH
           MOVE 15                TO STCW196-RIFERIMENTO
           PERFORM SEGNALA-ERRORI THRU F-SEGNALA-ERRORI
           PERFORM INFORMA THRU INFORMA-EX.
           MOVE  1                TO SW-ERRORE.
           MOVE 'NO'              TO   WK-RISCRITTURA
           MOVE  'KO'             TO COMM-ESITO-RICH.
           GO TO F-ELABORA-MESSAGGIO.

      *----------------------------------------------------------------*
      * SEGNALAZIONI PER TERMINALE FUORI SERVIZIO                      *
      *----------------------------------------------------------------*
       ERRORE-TERMINALI.
           MOVE 40                TO COMM-ANOMA-RICH
           MOVE 16                TO STCW196-RIFERIMENTO
           PERFORM SEGNALA-ERRORI THRU F-SEGNALA-ERRORI
           MOVE  1                TO SW-ERRORE
           MOVE 'NO'              TO   WK-RISCRITTURA
           MOVE  'KO'             TO COMM-ESITO-RICH.
           GO TO F-ELABORA-MESSAGGIO.

      *----------------------------------------------------------------*
       FINE-CONTROLLI-FORMALI.
      *----------------------------------------------------------------*
SI0905     IF NOT WYZ20-GEN-NR-II-ATTIVO
SI0905        GO TO SALTA-GEST-NR-II
SI0905     .
R03905*---  Se NR II pista Û nello stato SPERIMENTALE, controllo che la
R03905*--- carta che sta operando sia una di quelle abilitate; in tal
R03905*--- caso imposto ad ATTIVO lo stato, altrimenti a NON ATTIVO.
R03905     IF TKABD-NRII-STATO-SPERIMENTALE
R03905     AND YZCRA70-FLAG-AGGIORNA > SPACES
R03905        PERFORM CNTL-PAN-NR-II-SPERIM
R03905         THRU F-CNTL-PAN-NR-II-SPERIM
R03905     .
R03905*---  Reimposto l'area eventualmente modificata per farla viaggia-
R03905*--- re attraverso i programmi che verranno richiamati
R03905     MOVE YZCTKABD-YZCVNR02        TO YZCTKABD-AREA-YZCVNR02
R03905     .
SI0822*--->
SI0822*--->  Se NR II Pista attivo e l'ATM ha il SW per la gestione
SI0822*---> del NR II Pista
SI0822*--->
SI0822     MOVE ZEROES                   TO YZCRYZ01-AGGTO-II-TRACCIA
SI0822     .
SI0822     IF TKABD-NRII-STATO-ATTIVO
SI0822     AND YZCRA70-FLAG-AGGIORNA > SPACES
SI0905*---  Devo leggere il Positivo per controllare se la carta e'
SI0905*--- multifunzione.
SI0905        IF COMM-ABI-TERM = COMM-ABI-CARTA
SI0905           MOVE 'A70'              TO COMM-TIPO-RICH
SI0905           MOVE 3                  TO COMM-FUNZ-RICH
SI0905           MOVE YZCRA70-PAN        TO COMM-PAN-RICH
SI0905           MOVE ZERO               TO COMM-ESITO-RICH
SI0905           MOVE 'YZTCGB04'         TO WKPGMSUC
SI0905           PERFORM CHIAMA-ALTRO-PROGRAMMA
SI0905           THRU  F-CHIAMA-ALTRO-PROGRAMMA
SI0905*---  Se lettura positivo KO
SI0905           IF COMM-ESITO-RICH NOT = 'OK'
SI0905              MOVE 'NO'            TO WK-RISCRITTURA
SI0905*             GO TO F-ELABORA-MESSAGGIO
SA1111*---  Asteriscata la precedente
SA1111              GO TO SALTA-GEST-NR-II
SI0905           END-IF
SI0905        END-IF
SI0905*---  Se la carta non e' dell'Istituto o non e' multifunzione
SI0905*--- non eseguo i controlli del NR II Pista
SI0822        IF COMM-ABI-TERM NOT = COMM-ABI-CARTA
SI0905        OR YZCRPOSI-MULTIFUNZIONE = '00'  OR  '01'
SI0822*          NEXT SENTENCE
SI0905*---  Asteriscata la precedente
SI0905           MOVE 'N'                TO YZCRA70-FLAG-AGGIORNA
SI0905           MOVE YZCRA70            TO YZCRMESS-DATI-MSG
SI0905           MOVE YZCRMESS           TO LINK-MESSAGGIO
SI0905           MOVE SPACES             TO COMM-NR-II
SI0822        ELSE
SI0822           MOVE 'A70'              TO COMM-TIPO-RICH
SI0822           MOVE 1                  TO COMM-FUNZ-RICH
SI0822           MOVE ZERO               TO COMM-ESITO-RICH
SI0822           MOVE YZCRA70            TO COMM-MESSAGGIO
SI0822           MOVE 'YZTCGBII'         TO WKPGMSUC
SI0822           PERFORM CHIAMA-ALTRO-PROGRAMMA
SI0822           THRU  F-CHIAMA-ALTRO-PROGRAMMA
SI0822*---  Se autorizzazione negata esco
SI0822           IF COMM-ESITO-RICH = 'NP' OR
SI0822              COMM-ESITO-RICH = 'KO' OR
SI0822              COMM-ESITO-RICH = 'RE' OR
SI0822              COMM-ESITO-RICH = 'CA'
SI0822              MOVE 'NO'            TO WK-RISCRITTURA
SI0822              GO TO F-ELABORA-MESSAGGIO
SI0822           ELSE
SI0905*---  Se autorizzazione non negata, ma controlli non ok, faccio in
SI0905*--- modo di non aggiornare la II Pista
SI0822              IF COMM-ESITO-RICH NOT = '00'
SI0822*                MOVE '0'  TO  YZCRA70-FLAG-AGGIORNA
SI0905*---  Asteriscata la precedente
SI0905                 MOVE 'N'  TO  YZCRA70-FLAG-AGGIORNA
SI0822                 MOVE YZCRA70      TO YZCRMESS-DATI-MSG
SI0822                 MOVE YZCRMESS     TO LINK-MESSAGGIO
SI0822                 MOVE  SPACES      TO COMM-NR-II
SI0822              ELSE
SI0822*---  Altrimenti chiedo di aggiornare il NR II Pista
SI0822                 MOVE YZCRYZ01-SECONDA-TRC  TO YZCR2TRX-REC
SI0822                 MOVE YZCR2TRX-NUM-RANDOM   TO COMM-NR-II
SI0822              END-IF
SI0822              MOVE 'OK'            TO COMM-ESITO-RICH
SI0822           END-IF
SI0822        END-IF
SI0822     .
SI0905 SALTA-GEST-NR-II.

      *----------------------------------------------------------------*
      * SEGUE VIE DIVERSE A SECONDA ATI DI TERZA TRACCIA         (7)   *
      *----------------------------------------------------------------*

      *---- RICHIEDO FUNZIONE DI AUTORIZZAZIONE AD OPERARE ------------*

           MOVE 'A70'                TO COMM-TIPO-RICH.
           MOVE 1                    TO COMM-FUNZ-RICH.
           MOVE ZERO                 TO COMM-ESITO-RICH.
           MOVE ZERO                 TO COMM-IMPORTO-AUTOR-1
           MOVE ZERO                 TO COMM-IMPORTO-AUTOR-2
           MOVE ZERO                 TO COMM-IMPORTO-AUTOR-3
120692     MOVE YZCRA70              TO COMM-MESSAGGIO.

           IF COMM-ABI-TERM  NOT = COMM-ABI-CARTA
                  MOVE 'YZTCGB05'    TO WKPGMSUC
           ELSE
                  MOVE 'YZTCGB04'    TO WKPGMSUC.

           PERFORM CHIAMA-ALTRO-PROGRAMMA THRU F-CHIAMA-ALTRO-PROGRAMMA.

           IF COMM-ESITO-RICH = 'NP'
130592     OR  COMM-ESITO-RICH    =     'KO'
130592     OR  COMM-ESITO-RICH    =     'RE'
130592     OR  COMM-ESITO-RICH    =     'CA'
           THEN
               MOVE 'NO' TO WK-RISCRITTURA
YOUNGA         GO TO F-ELABORA-MESSAGGIO
           ELSE
COBOL2         COPY YZCPYZ32.
COBOL2*
COBOL2*        IF COMM-ABI-TERM  NOT = COMM-ABI-CARTA
COBOL2*            MOVE WK-AREA-CIRCOL     TO YZCRCIRC
COBOL2*        ELSE
COBOL2*            MOVE WK-AREA-POSITIVO     TO YZCRPOSI.
R00806*---  Modifica per Ca.Ris.Ma.:
R00806*---  Aggiorno il nuovo NR di III traccia sulla traccia del msg
R00806*--- per rinfrescarla sull'archivio terminali.
R00806     MOVE COMM-NR                  TO YZCRA70-NR
R00806     MOVE YZCRA70-3TRANOR          TO YZCRYZ01-TERZA-TRACCIA
R00806     .
SI1020*---
SI1020*--- Chiamata allo Scudo Autorizzativo di Ca.Ris.Ma.
SI1020     PERFORM CHIAMA-SCUDO-CARISMA THRU F-CHIAMA-SCUDO-CARISMA
SI1020     .
SI1020     IF WYZ20-GEN-SYS-SCUDO-ATTIVO
SI1020*---  Se la START dello Scudo non e' andata a buon fine o non c'e'
SI1020*--- stata risposta non faccio nulla
SI1020        IF YZCRLCRM-ESITO NOT NUMERIC
SI1020           CONTINUE
SI1020        ELSE
SI1020           IF RLCRM-ESITO-KO
SI1020              MOVE '21'            TO COMM-ANOMA-RICH
SI1020              MOVE 'KO'            TO COMM-ESITO-RICH
SI1020              MOVE 'NO'            TO WK-RISCRITTURA
SI1020              MOVE 1               TO SW-ERRORE
SI1020              GO TO F-ELABORA-MESSAGGIO
SI1020           END-IF
SI1020        END-IF
SI1020     .
YOUNG *---
YOUNG *---  LEGGO LA TABELLA DELL'OPERATIVITA' PER ABI E TIPO CARTA PER
YOUNG *--- VERIFICARE QUANDO LA CARTA PUO' OPERARE
YOUNG      PERFORM LEGGI-TKOPE       THRU F-LEGGI-TKOPE
YOUNG      .
YOUNG      IF YZCTKOPE = ZEROES
YOUNG         NEXT SENTENCE
YOUNG      ELSE
YOUNG         PERFORM CNTL-TKOPE        THRU F-CNTL-TKOPE
YOUNG         IF COMM-ANOMA-RICH NOT = ZERO
YOUNG            MOVE 'KO'               TO COMM-ESITO-RICH
YOUNG            MOVE 'NO'               TO WK-RISCRITTURA
YOUNG            MOVE 1                  TO SW-ERRORE
YOUNG            GO TO F-ELABORA-MESSAGGIO
YOUNG        END-IF
YOUNG      .

       F-ELABORA-MESSAGGIO.
           EXIT.
YOUNG *==============================================================*
YOUNG *  LETTURA DELLA TABELLA OPERATIVITA' PER SINGOLA TIPOLOGIA DI *
YOUNG * CARTA                                                        *
YOUNG *==============================================================*
YOUNG  LEGGI-TKOPE.
      *
           MOVE SPACE                    TO YZCTKOPE
           MOVE 'GEB'                    TO YZCTKOPE-PROC
           MOVE 'OPE'                    TO YZCTKOPE-COD
           MOVE COMM-ABI-CARTA           TO YZCTKOPE-ABI
           MOVE YZCRPOSI-TIPO-CARTA      TO YZCTKOPE-TIPO-CARTA
           .
           MOVE SPACE                    TO STCWIODB
           MOVE DSTABINQ                 TO STCWIODB-SEGMENTO
           MOVE '10'                     TO STCWIODB-RIFERIMENTO
           MOVE READONLY                 TO STCWIODB-FUNZ
           MOVE LEN-TAB-VAR              TO STCWIODB-RECLEN
           MOVE 'EQ'                     TO STCWIODB-OPERATORE
           MOVE YZCTKOPE-KEY             TO STCWIODB-CHIAVE1
           MOVE WK-NOTFND                TO STCWIODB-RC-OK (1)
           .
           PERFORM MIODB                THRU F-MIODB
           .
           IF STCWIODB-RC = WK-NOTFND
              MOVE ZEROES              TO YZCTKOPE
           ELSE
              MOVE STCWIODB-AREAIO     TO YZCTKOPE
           .
YOUNG  F-LEGGI-TKOPE.
YOUNG      EXIT.
YOUNG *==============================================================*
YOUNG *  CONTROLLA CHE LA CARTA POSSA OPERARE                        *
YOUNG *==============================================================*
YOUNG  CNTL-TKOPE.
      *
           MOVE SPACES                   TO YYCWUTDA
           MOVE YZCRA70-DATAMES          TO YYCWUTDA-DATA-CORRENTE(6)
           MOVE '6'                      TO YYCWUTDA-FLAG-SCELTA
           .
           PERFORM MUTDAT               THRU F-MUTDAT
           .
           IF YZCTKOPE-GIORNO(YYCWUTDA-FLAG-GG-CORR) = '1'
              IF YZCRA70-ORAMES < YZCTKOPE-ORA-DA(YYCWUTDA-FLAG-GG-CORR)
              OR YZCRA70-ORAMES > YZCTKOPE-ORA-A(YYCWUTDA-FLAG-GG-CORR)
      *---  ORARIO NON ABILITATO ALL'OPERATIVITA'
                 MOVE '15'               TO COMM-ANOMA-RICH
              END-IF
           ELSE
      *---  GIORNO NON ABILITATO ALL'OPERATIVITA'
              MOVE '15'                  TO COMM-ANOMA-RICH
           .
YOUNG  F-CNTL-TKOPE.
YOUNG      EXIT.
R06606*==============================================================*
R06606*  LETTURA DELLA TABELLA OPERATIVITA' ATM                      *
R06606*==============================================================*
R06606 LEGGI-TKOPE-ATM.
      *
           MOVE SPACE                    TO YZCTKOPE
           MOVE 'GEB'                    TO YZCTKOPE-PROC
           MOVE 'OPE'                    TO YZCTKOPE-COD
           MOVE YZCRYZ01-CODABI          TO YZCTKOPE-ABI
           MOVE 'ATM'                    TO YZCTKOPE-ATM
           .
           MOVE SPACE                    TO STCWIODB
           MOVE DSTABINQ                 TO STCWIODB-SEGMENTO
           MOVE '1A'                     TO STCWIODB-RIFERIMENTO
           MOVE READONLY                 TO STCWIODB-FUNZ
           MOVE LEN-TAB-VAR              TO STCWIODB-RECLEN
           MOVE 'EQ'                     TO STCWIODB-OPERATORE
           MOVE YZCTKOPE-KEY-ATM         TO STCWIODB-CHIAVE1
           MOVE WK-NOTFND                TO STCWIODB-RC-OK (1)
           .
           PERFORM MIODB                THRU F-MIODB
           .
           IF STCWIODB-RC = WK-NOTFND
              MOVE ZEROES              TO YZCTKOPE
           ELSE
              MOVE STCWIODB-AREAIO     TO YZCTKOPE
           .
R06606 F-LEGGI-TKOPE-ATM.
R06606     EXIT.
      *----
       PREPARA-RISPOSTA.
OLCA2
OLCA2 *-------------------------------------------------------------
OLCA2 *    SE SIAMO IN OLCA 2 FASE A E NON TUTTI GLI ATM SONO IN
OLCA2 *       OLCA 2 FASE A CONTROLLIAMO SE ATM E' SU TABELLA OLTE
OLCA2 *       SE NON PRESENTE CI METTIAMO IN OLCA1
OLCA2 *    SE SIAMO IN OLCA 2 FASE B E NON TUTTI GLI ATM SONO IN
OLCA2 *       OLCA 2 FASE B CONTROLLIAMO SE ATM E' SU TABELLA OLTE
OLCA2 *       SE NON PRESENTE CI METTIAMO IN OLCA 2 FASE A
OLCA2 *-------------------------------------------------------------
OLCA2
OLCA2          COPY YZCPOL70.
OLCA2
OLCA1
OLCA1      IF  OLCA-CIRC-A71
OLCA2          COPY YZCPOL48.
OLCA1          MOVE YZCRFIT-EPINKEY   TO YZCRA71-EPINK
OLCA1          PERFORM COMPLETA-MESS  THRU F-COMPLETA-MESS
OLCA1          PERFORM VERIFICA-RESTROP THRU F-VERIFICA-RESTROP
OLCA1          GO TO PREPARA-RISPOSTA-PARZIALE.

      *    SE RIMAGNETIZZIAMO LA CARTA ESEGUIAMO UNA ROUTINE A PARTE.
           IF YZCWYZ20-GEN-RIMAG-CARTA = 1
               IF WS-FIMA-LUNGHEZZA NOT = ZERO
                   PERFORM PREPARA-INVIO-III-TRACCIA THRU
                         F-PREPARA-INVIO-III-TRACCIA
SA0197*-INIZIO--->
SA0197*----------> L'ALLINEAMENTO SOLO ALLA CONFERMA DI AVVENUTA
SA0197*----------> RIMAGNETIZZAZIONE (X20/32 SUCCESSIVA) PERTANTO
SA0197*----------> LA ROUTINE DEVE ESSERE DEFINITIVAMENTE ASTERISCATA
RVS   *     L'INVIO TERZA TRACCIA PER IL MOMENTO E' SOLO PER RVS BOLZANO
RVS   *     - ABBIAMO ASTERISCATO LA ROUTINE PER NON IMPEGNARE MEMORIA
RVS   *            PERFORM INVIA-ALLINEAMENTO THRU
RVS   *                  F-INVIA-ALLINEAMENTO
SA0197*----------> L'ALLINEAMENTO SOLO ALLA CONFERMA DI AVVENUTA
SA0197*----------> RIMAGNETIZZAZIONE (X20/32 SUCCESSIVA) PERTANTO
SA0197*----------> LA ROUTINE DEVE ESSERE DEFINITIVAMENTE ASTERISCATA
SA0197*-FINE----->
                   GO TO F-PREPARA-RISPOSTA.

           MOVE ZERO                 TO YZCRA71.
           MOVE 'A71'                TO YZCRA71-CODMES.
           MOVE YZCRA70-CODATM       TO YZCRA71-CODATM.
           MOVE YZCRA70-NUMMES       TO YZCRA71-NUMMES.
           MOVE YZCRA70-DATAMES      TO YZCRA71-DATAMES
           MOVE YZCRA70-ORAMES       TO YZCRA71-ORAMES.
R12303*    IF YZCRYZ01-DATI-TER-VERS-SW > '3000310'
R12303*--> AGGIUNTA RIGA SUCCESSIVA PER ALLINEARE ORARIO SOLO SU MSG
R12303*--> ON-LINE
R12303*    AND YZCRA70-STATO = '0'
R12303*       MOVE COMMDAY2              TO WK-COMMDAY2
R12303*       STRING WK-COMMDAY2(7:2) WK-COMMDAY2(5:2) WK-COMMDAY2(3:2)
R12303*              DELIMITED BY SIZE  INTO YZCRA71-DATAMES
R12303*       MOVE COMMTIME(1:4)         TO YZCRA71-ORAMES
R12303*    .
R09509*--> ASTERISCATE LE 7 PRECEDENTI
200592     IF YZCRA70-STATO = '1'
200592         GO TO PREPARA-RISPOSTA-PARZIALE.
           MOVE COMM-IMPORTO-AUTOR-1 TO YZCRA71-DISP
           IF COMM-ANOMA-RICH NOT = ZERO
              PERFORM VERIFICA-AZIONE THRU F-VERIFICA-AZIONE
              PERFORM RIEMPI-A71-AZIONE-PER-ANOM THRU
                                        F-RIEMPI-A71-AZIONE-PER-ANOM
           ELSE
              IF   COMM-ESITO-RICH    =  'OK'
OLCA2              COPY YZCPOL51.
                   MOVE YZCRFIT-EPINKEY   TO YZCRA71-EPINK
                   PERFORM COMPLETA-MESS  THRU F-COMPLETA-MESS
021192             PERFORM VERIFICA-RESTROP THRU F-VERIFICA-RESTROP
                   IF   COMM-IMPORTO-AUTOR-1 = ZERO
                        MOVE ZERO         TO YZCRA71-AZIONE
                   ELSE
                        MOVE COMM-IMPORTO-AUTOR-1 TO YZCRA71-DISP
                        MOVE 1            TO YZCRA71-AZIONE.

           MOVE COMM-ANOMA-RICH      TO YZCRA71-ANOM.
INPS  *---  NEL CASO LA CARTA NON HA DISPONIBILITA' DISABILITO IL PRE-
INPS  *--- LIEVO, SOLO SE HA ALMENO UN'ALTRO FLAG ALZATO (ES.: SALDO)
INPS       IF YZCRA71-DISP(2:) = ZERO
INPS          MOVE ZERO         TO YZCRA71-PR01
INPS          IF YZCRA71-PROF = ZERO
INPS             MOVE 1         TO YZCRA71-PR01
INPS          END-IF
INPS       .
OLCA1 *----------------------------------------------------------------
OLCA1 * VERIFICARE CHE SIA PRESENTE LA LABEL SEGUENTE
OLCA1 *----------------------------------------------------------------
200592 PREPARA-RISPOSTA-PARZIALE.
SI1077*-- Imposto fissa la divisa nella disponibilita'
SI1077     MOVE 'E'                  TO YZCRA71-DISP-X(1:1).
SI1077*
           MOVE    WK-LUNGH-A71      TO LINK-RISPOSTA-LUNG.
           MOVE YZCRA71              TO LINK-RISPOSTA-DATI.
090693     MOVE YZCRA71-AZIONE       TO YZCRYZ01-AZIONE.
       F-PREPARA-RISPOSTA.
           EXIT.
OLCA1 *----------------------------------------------------------------
OLCA1 * VERIFICARE CHE SIA PRESENTE LA ROUTINE SEGUENTE
OLCA1 *----------------------------------------------------------------
021192 VERIFICA-RESTROP.
R07207*
R07207     PERFORM CNTL-SERVIZI-ABILITATI
R07207      THRU F-CNTL-SERVIZI-ABILITATI
R07207     .
021192     IF YZCRYZ01-RESTROP = 1 OR = 3
021192        MOVE ZERO TO YZCRA71-PR01.
021192     IF YZCRYZ01-RESTROP = 2
021192        MOVE ZERO TO YZCRA71-PR02.
R42304*---  Nel caso il terminale debba essere battezzato, non abilito
R42304*--- il pagamento utenze per non creare eventuali disservizi
R42304     IF YZCRYZ01-PUTE-DATA-BATTESIMO = '333333'
R42304        MOVE ZERO                  TO YZCRA71-PR05
R42304     .
SP0359*
SP0359*---  Nel caso la carta non abbia un saldo positivo non abilito ne
SP0359*--- il prelievo ne i pagamenti
XP0807     IF RPOSI-RISCHIO-CARTA-SI  AND
XP0807*---  Solo per carta Prepagata
XP0807        YZCRPOSI-TIPORAP = 9    AND
XP0807        YZCRPOSI-RESTROP = 8
XP0807*---  Se importo autorizzato e' zero non abilito il prelievo
XP0807        IF COMM-IMPORTO-AUTOR-1 = ZERO
XP0807           MOVE ZERO               TO YZCRA71-PR01
XP0807        END-IF
XP0807*---  Solo se l'importo autorizzato e' zero non abilito il paga-
XP0807*--- mento, anche se il Monte Moneta risulta vuoto.
XP0807        IF YZCRPOCA-MONTE-MONETA-S NOT = '+'
XP0807        OR YZCRPOCA-MONTE-MONETA-V = ZEROES
XP0807           IF WS-DISP-PP = ZEROES
XP0807              MOVE ZERO            TO YZCRA71-PR05
XP0807           END-IF
XP0807        END-IF
XP0807     ELSE
SP0359     IF YZCRPOSI-SD = ZERO
SP0359     OR RPOSI-SALDO-NEGATIVO
SP0359*---  In caso di Prepagata non posso testare il saldo del Positivo
SP0359*--- xche' e' stato decurtato della disponibilita' del prelievo
SP0359*--- quindi verifico se e' impostata la disponibilita'
SP0359        IF YZCRPOSI-TIPORAP = 9 AND
SP0359*          YZCRPOSI-RESTROP = 8 AND
SP0359*          COMM-IMPORTO-AUTOR-1 > ZERO
SP0359*          CONTINUE
R16507*---  Asteriscate le 3 righe precedenti
R16507           YZCRPOSI-RESTROP = 8
R16507           IF COMM-IMPORTO-AUTOR-1 = ZERO
R16507              MOVE ZERO               TO YZCRA71-PR01
R16507           END-IF
R16507           IF WS-DISP-PP           = ZERO
R16507              MOVE ZERO               TO YZCRA71-PR05
R16507           END-IF
SP0359        ELSE
SP0359           MOVE ZERO                  TO YZCRA71-PR01
SP0359           MOVE ZERO                  TO YZCRA71-PR05
SP0359        END-IF
SP0359     .
CONTE * ---- 14/05/2002 P.C.
CONTE * ---- DISABILITO SULL'A71 IL BONIFICO ANCHE SE ABILITATO
CONTE * ---- SUL POSITIVO CARTA. QUESTO PER GESTIRLO SU SPORTELLO.
CONTE      MOVE ZERO TO YZCRA71-PR06.
SP0359*---  Tutte le altre restrizioni all'operativita' DEVONO essere
SP0359*--- inserite prima della label seguente.
SP0359 VERIFICA-RESTROP-CC.
SP0359*---  Nel caso la carta sia abilitata al versamento, invio all'ATM
SP0359*--- l'abilitazione piô restrittiva tra la carta e l'ATM stesso.
SP0359     IF YZCRA71-PR02 > ZERO
SP0359*--- verifico che l'ATM sia abilitato ad accettarle
SP0359        EVALUATE YZCRA71-PR02
SP0359*---  Carta abilitata solo al versamento di banconote
SP0359          WHEN 1
SP0359*---  Se CASH-IN non OK, spegno il bottone del versamento
SP0359            IF YZCRYZ01-CASH-IN NOT = ZERO
SP0359               MOVE ZERO           TO YZCRA71-PR02
SP0359            END-IF
SP0359*---  Se i C/C hanno il blocco del versamento banconote, spengo
SP0359*--- il bottone del versamento
SP0359            IF YZCRANA-RC-RISPOSTA = 'C'  OR  'D'
SP0359               MOVE ZERO           TO YZCRA71-PR02
SP0359            END-IF
SP0359*---  Carta abilitata solo al versamento di assegni
SP0359          WHEN 2
SP0359*---  Se CHEQUE-IN non OK, spegno il bottone del versamento
SP0359            IF YZCRYZ01-CHEQUE-IN NOT = ZERO
SP0359               MOVE ZERO           TO YZCRA71-PR02
SP0359            END-IF
SP0359*---  Se i C/C hanno il blocco del versamento assegni, spengo
SP0359*--- il bottone del versamento
SP0359            IF YZCRANA-RC-RISPOSTA = 'A'  OR  'B'
SP0359               MOVE ZERO           TO YZCRA71-PR02
SP0359            END-IF
SP0359*---  Carta abilitata sia al versamento di assegni che banconote
SP0359          WHEN 3
SP0359*---  Se CASH-IN e CHEQUE-IN non OK o i C/C ci danno il blocco
SP0350*--- AVERE, spengo il bottone del versamento
SP0359            IF (YZCRYZ01-CHEQUE-IN NOT = ZERO  AND
SP0359                YZCRYZ01-CASH-IN   NOT = ZERO)
SP0359            OR YZCRANA-RC-RISPOSTA = '5'  OR  '8'
SP0359               MOVE ZERO           TO YZCRA71-PR02
SP0359            ELSE
SP0359*---  Se CHEQUE-IN non OK o i C/C ci danno il blocco versamento
SP0359*--- assegni, abilito solo il CASH-IN
SP0359               IF YZCRYZ01-CHEQUE-IN NOT = ZERO
SP0359               OR YZCRANA-RC-RISPOSTA = 'A'  OR  'B'
SP0359                  MOVE 1           TO YZCRA71-PR02
SP0359               ELSE
SP0359*---  Se CASH-IN non OK o i C/C ci danno il blocco versamento con-
SP0359*--- tanti, abilito solo il CHEQUE-IN
SP0359                  IF YZCRYZ01-CASH-IN NOT = ZERO
SP0359                  OR YZCRANA-RC-RISPOSTA = 'C'  OR  'D'
SP0359                     MOVE 2        TO YZCRA71-PR02
SP0359                  END-IF
SP0359               END-IF
SP0359            END-IF
SP0359*---  Carta abilitata solo al versamento di monete
SP0359          WHEN 4
SP0359*---  Attualmente gli ATM non hanno questa funzionalita' quindi
SP0359*--- spengo il bottone del versamento
SP0359            MOVE ZERO              TO YZCRA71-PR02
SP0359*---  Carta abilitata sia al versamento di monete che di banconote
SP0359          WHEN 5
SP0359*---  Attualmente gli ATM non hanno il versamento monete quindi
SP0359*--- se CASH-IN non OK o i C/C ci danno il blocco versamento con-
SP0359*--- tanti, spengo il bottone del versamento
SP0359            IF YZCRYZ01-CASH-IN   NOT = ZERO
SP0359            OR YZCRANA-RC-RISPOSTA = 'C'  OR  'D'
SP0359               MOVE ZERO           TO YZCRA71-PR02
SP0359*---  altrimenti abilito al versamento delle sole banconote
SP0359            ELSE
SP0359               MOVE 1              TO YZCRA71-PR02
SP0359            END-IF
SP0359*---  Carta abilitata sia al versamento di monete che di assegni
SP0359          WHEN 6
SP0359*---  Attualmente gli ATM non hanno il versamento monete quindi
SP0359*--- se CHEQUE-IN non OK o i C/C ci danno il blocco versamento
SP0359*--- assegni, spengo il bottone del versamento
SP0359            IF YZCRYZ01-CHEQUE-IN NOT = ZERO
SP0359            OR YZCRANA-RC-RISPOSTA = 'A'  OR  'B'
SP0359               MOVE ZERO           TO YZCRA71-PR02
SP0359*---  altrimenti abilito al versamento dei soli assegni
SP0359            ELSE
SP0359               MOVE 2              TO YZCRA71-PR02
SP0359            END-IF
SP0359*---  Carta abilitata sia al versamento di monete che di assegni
SP0359*--- che di banconote
SP0359          WHEN 7
SP0359*---  Attualmente gli ATM non hanno il versamento monete quindi
SP0359*--- se CASH-IN e CHEQUE-IN non OK o i C/C ci danno il blocco
SP0350*--- AVERE, spengo il bottone del versamento
SP0359            IF (YZCRYZ01-CHEQUE-IN NOT = ZERO  AND
SP0359                YZCRYZ01-CASH-IN   NOT = ZERO)
SP0359            OR YZCRANA-RC-RISPOSTA = '5'  OR  '8'
SP0359               MOVE ZERO           TO YZCRA71-PR02
SP0359            ELSE
SP0359*--- altrimenti se CASH-IN e CHEQUE-IN sono OK ed i C/C non ci
SP0359*--- danno blocchi sul versamento assegni e contanti, abilito
SP0359*--- entrambi
SP0359               IF YZCRYZ01-CHEQUE-IN = ZERO  AND
SP0359                  YZCRYZ01-CASH-IN   = ZERO  AND
SP0359                  YZCRANA-RC-RISPOSTA NOT = 'A'  AND  'C'
SP0359                                      AND   'B'  AND  'D'
SP0359                  MOVE 3           TO YZCRA71-PR02
SP0359               ELSE
SP0359*---  Se CHEQUE-IN non OK o i C/C ci danno il blocco versamento
SP0359*--- assegni, abilito il CASH-IN
SP0359                  IF YZCRYZ01-CHEQUE-IN NOT = ZERO
SP0359                  OR YZCRANA-RC-RISPOSTA = 'A'  OR  'B'
SP0359                     MOVE 1        TO YZCRA71-PR02
SP0359                  ELSE
SP0359*---  Se CASH-IN non OK o i C/C ci danno il blocco versamento
SP0359*--- contanti, abilito il CHEQUE-IN
SP0359                     IF YZCRYZ01-CASH-IN NOT = ZERO
SP0359                     OR YZCRANA-RC-RISPOSTA = 'C'  OR  'D'
SP0359                        MOVE 2        TO YZCRA71-PR02
SP0359                     ELSE
SP0359*--- altrimenti non abilito nulla perche' mi sono perso .....
SP0359                        MOVE ZERO     TO YZCRA71-PR02
SP0359                     END-IF
SP0359                  END-IF
SP0359               END-IF
SP0359            END-IF
SP0359*---  Tutti altri casi sono sconosciuti, quindi non abilito il
SP0359*--- versamento
SP0359          WHEN OTHER
SP0359            MOVE ZERO              TO YZCRA71-PR02
SP0359        END-EVALUATE
SP0359     .
SP0359*---  Flag Inquiry C/C acceso, disabilito Saldo e Lista Movimenti
R16104     IF YZCRANA-RC-RISPOSTA = 4
SP0359     OR YZCRANA-RC-RISPOSTA = '8'  OR  'B'  OR  'D'
R16104         MOVE ZERO                 TO YZCRA71-PR03
R16104         MOVE ZERO                 TO YZCRA71-PR04
SP0359     ELSE
SP0359*---  Blocco dare C/C, disabilito Prelievo e Pagamenti
SP0359     IF YZCRANA-RC-RISPOSTA = 6
SP0359        MOVE ZERO                  TO YZCRA71-PR01
SP0359        MOVE ZERO                  TO YZCRA71-PR05
SP0359     ELSE
SP0359*---  Blocco dare/avere C/C, disabilito Prelievo, Versamento e Pa-
SP0359*--- gamenti
SP0359     IF YZCRANA-RC-RISPOSTA = 7
SP0359        MOVE ZERO                  TO YZCRA71-PR01
SP0359        MOVE ZERO                  TO YZCRA71-PR02
SP0359        MOVE ZERO                  TO YZCRA71-PR05
R16104     .
021192 F-VERIFICA-RESTROP.
021192     EXIT.
      *==============================================================*
      *---- LETTURA DELLE TABELLE PER SAPERE CHE AZIONE SI   -------
      *---- DEVE INTRAPRENDERE A FRONTE DI ANOMALIE          -------
      *==============================================================*
       VERIFICA-AZIONE.
      *----
           COPY YZCPYZ01.
      *----
       F-VERIFICA-AZIONE.
           EXIT.

      *==============================================================*
      *---- CHIAMA YZTCGB02 PER SCRIVERE IL LOG DEI MESSAGGI -------
      *==============================================================*

       SCRITTURA-MESSAGGIO-RISPOSTA.
SI0831*
SI0831     IF  WYZ20-GEN-TR2-SENSIB-SI
SI0831         PERFORM PROT-831-DATI
SI0831          THRU F-PROT-831-DATI
SI0831     .
SI0010*----
SI0010     COPY YZCPN7AN.
SI0010*----
SA0891     IF WK-RISCRITTURA NOT = 'NO'
SA0891        STRING YZCRPOSI-TIPO-CARTA
SA0891               YZCRPOSI-CARTA
SA0891               DELIMITED BY SIZE
SA0891          INTO LINK-RISPOSTA-DATI(LINK-RISPOSTA-LUNG + 1 : 10)
SA0891     ELSE
SA0891        MOVE ZERO
SA0891          TO LINK-RISPOSTA-DATI(LINK-RISPOSTA-LUNG + 1 : 10)
SA0891     .
SA0891     COMPUTE LINK-RISPOSTA-LUNG = LINK-RISPOSTA-LUNG + 10
SA0891     .
SI1020     IF WYZ20-GEN-SYS-SCUDO-ATTIVO
SI1020        MOVE YZCRLCRM-KEY-TMSTP
SI1020          TO LINK-RISPOSTA-DATI(LINK-RISPOSTA-LUNG + 1 :
SI1020             LENGTH OF YZCRLCRM-KEY-TMSTP)
SI1020        ADD  LENGTH OF YZCRLCRM-KEY-TMSTP
SI1020          TO LINK-RISPOSTA-LUNG
SI1020     .
SI0921     PERFORM RILOCAZIONE-DATI
SI0921     THRU  F-RILOCAZIONE-DATI
SI0921     .
      *----
           MOVE 'YZTCGB02'      TO WKPGMSUC.
      *----
           PERFORM                 CHIAMA-ALTRO-PROGRAMMA
                            THRU F-CHIAMA-ALTRO-PROGRAMMA.
SA0891*
SI1020     IF WYZ20-GEN-SYS-SCUDO-ATTIVO
SI1020        SUBTRACT LENGTH OF YZCRLCRM-KEY-TMSTP
SI1020            FROM LINK-RISPOSTA-LUNG
SI1020        MOVE LOW-VALUE
SI1020          TO LINK-RISPOSTA-DATI(LINK-RISPOSTA-LUNG + 1 :
SI1020             LENGTH OF YZCRLCRM-KEY-TMSTP)
SI1020     .
SA0891     COMPUTE LINK-RISPOSTA-LUNG = LINK-RISPOSTA-LUNG - 10
SA0891     .
SA0891     MOVE LOW-VALUE
SA0891       TO LINK-RISPOSTA-DATI(LINK-RISPOSTA-LUNG + 1 : 10)
SA0891     .
SI0831*
SI0831     IF  WYZ20-GEN-TR2-SENSIB-SI
SI0831         PERFORM RECU-831-DATI
SI0831          THRU F-RECU-831-DATI
SI0831     .
SI0010*----
SI0010     COPY YZCPN7AO.
SI0010*----
       F-SCRITTURA-MESSAGGIO-RISPOSTA.
           EXIT.

      *=============================================================
      *---- CHIAMA YZTCGB01 PER RISPONDERE AL TERMINALE ------------
      *=============================================================
       RISPONDI-A-TERMINALE.
SI0010*----
SI0010     COPY YZCPN7AN.
SI0010*----
SI0921     PERFORM RILOCAZIONE-DATI
SI0921     THRU  F-RILOCAZIONE-DATI
SI0921     .
      *----
           MOVE 'YZTCGB01'      TO WKPGMSUC.
      *----
           PERFORM                 CHIAMA-ALTRO-PROGRAMMA
                            THRU F-CHIAMA-ALTRO-PROGRAMMA.
SI0010*----
SI0010     COPY YZCPN7AO.
SI0010*----
       F-RISPONDI-A-TERMINALE.
           EXIT.

      *==============================================================*
      *---- CHIAMA YZTCGB03 PER RISCRIVERE IL FILE TERMINALI  -------
      *==============================================================*
       AGGIORNA-FILE-TERMINALI.
      *----
SI0822*---->
SI0822* VALORIZZO IL NUOVO CAMPO DELL'ARCHIVIO TERMINALI UTILIZZATO
SI0822* PER LE LISTE 3270
SI0822*----> ATM ha il software NR2 ma l'hardware non scrive
SI0822*    IF YZCRA70-FLAG-AGGIORNA = '0'
SI0905*---  Asteriscata la precedente
SI0905     IF WK-SAVE-FLAG-AGGIORNA = '0'
SI0822        MOVE '1'
SI0822        TO YZCRYZ01-UPGRADE-ATM-NRII
SI0822     ELSE
SI0822*----> ATM ha il software NR2 e l'hardware scrive
SI0822*    IF YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscata la precedente
SI0905     IF WK-SAVE-FLAG-AGGIORNA = '1'
SI0822        MOVE '2'
SI0822        TO YZCRYZ01-UPGRADE-ATM-NRII
SI0822     ELSE
SI0822*----> ATM non ha il software NR2
SI0822        MOVE '0'
SI0822        TO YZCRYZ01-UPGRADE-ATM-NRII
SI0822     .
OLCA1 *    VERIFICARE CHE SIANO PRESENTI LE DUE ISTRUZIONI SUCCESSIVE
100892     IF   YZCRA70-PAN     IS NUMERIC
100892         MOVE YZCRA70-PAN     TO YZCRYZ01-PANPRE.
SI0010*----
SI0010     COPY YZCPNR70.
SI0010*----
SI0082     IF YZCRYZ01-AZIONE NOT = 8
SI0082     OR COMM-RES-GIOR   NOT NUMERIC
SI0082     OR COMM-RES-MENS   NOT NUMERIC
SI0082        MOVE ZEROES           TO YZCRYZ01-RES-GIOR
SI0082        MOVE ZEROES           TO YZCRYZ01-RES-MENS
SI0082     ELSE
SI0116      IF WYZ20-A71-MAX-INT-IN-CODA
SI0116        MOVE COMM-RES-GIOR    TO YZCRYZ01-RES-MENS
SI0116        MOVE COMM-RES-MENS    TO YZCRYZ01-RES-GIOR
SI0116      ELSE
SI0082        MOVE COMM-RES-GIOR    TO YZCRYZ01-RES-GIOR
SI0082        MOVE COMM-RES-MENS    TO YZCRYZ01-RES-MENS
SI0082        .
SI0187     IF WK-RISCRITTURA NOT = 'NO'
SI0187        MOVE YZCRPOSI-TIPO-CARTA TO YZCRYZ01-TIPO-CARTA
SI0187        MOVE YZCRPOSI-CARTA      TO YZCRYZ01-NUM-CARTA
SI0187     ELSE
SI0187        MOVE ZEROES              TO YZCRYZ01-TIPO-CARTA
SI0187        MOVE ZEROES              TO YZCRYZ01-NUM-CARTA
SI0187        .
XI0705     MOVE 'A70'                    TO YZCRYZ01-MESPRE1
SI1020     MOVE COMM-TIMBRO-GMT          TO YZCRYZ01-TIMBRO-GMT
SI1020     .
           MOVE 'YZTCGB03'      TO WKPGMSUC.
      *----
           PERFORM                 CHIAMA-ALTRO-PROGRAMMA
                            THRU F-CHIAMA-ALTRO-PROGRAMMA.
       F-AGGIORNA-FILE-TERMINALI.
           EXIT.

SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 RILOCAZIONE-DATI.
SI0921*---> se disponibilita' con massimali integrati posizionati
SI0921*--->    in coda al msg o prima del msg pubblicitario
SI0921*--->    Elaborazione
SI0921*---> altrimenti
SI0921*--->    esce senza far nulla
SI0921*
SI0921     IF YZCRA71-AZIONE = 8 AND
SI0921       (WYZ20-A71-MAX-INT-PRIMA-DI-MSG OR
SI0921        WYZ20-A71-MAX-INT-IN-CODA )
SI0921        CONTINUE
SI0921     ELSE
SI0921        GO TO F-RILOCAZIONE-DATI
SI0921     .
SI0921*---> Determino la len della zona fissa
SI0921*
SI0921     MOVE WK-LEN-FISSA-A71            TO WK-LEN-FISSA
SI0921     .
SI0921     IF RYZ01-NR-ATM-MIGRATO
SI0921        ADD WK-LEN-NR                 TO WK-LEN-FISSA
SI0921     .
SI0921*---> Determino la len della zona variabile
SI0921*
SI0921     COMPUTE WK-LEN-VAR             =
SI0921             LINK-RISPOSTA-LUNG -
SI0921             WK-LEN-FISSA       -
SI0921             WK-LEN-MAX-INT     -
SI0921             YZCRYZ01-LEN-MSG
SI0921     .
SI0921     IF WYZ20-A71-MAX-INT-IN-CODA
SI0921        ADD YZCRYZ01-LEN-MSG          TO WK-LEN-VAR
SI0921     .
SI0921*---> Determino l'offset della zona massimali (campo di partenza)
SI0921*
SI0921     COMPUTE WK-POS-IN-MAX-INT =
SI0921             WK-LEN-FISSA      + 1
SI0921     .
SI0921*---> Determino l'offset della zona massimali (campo di arrivo)
SI0921*
SI0921     COMPUTE WK-POS-OUT-MAX-INT =
SI0921             WK-LEN-FISSA       +
SI0921             WK-LEN-VAR         + 1
SI0921     .
SI0921*---> Determino l'offset della zona variabile (campo di partenza)
SI0921*
SI0921     COMPUTE WK-POS-IN-VAR      =
SI0921             WK-LEN-FISSA       +
SI0921             WK-LEN-MAX-INT     + 1
SI0921     .
SI0921*---> Determino l'offset della zona variabile (campo di arrivo)
SI0921*
SI0921     COMPUTE WK-POS-OUT-VAR =
SI0921             WK-LEN-FISSA   + 1
SI0921     .
SI0921*---> Rilocazione zona variabile
SI0921*
SI0921     MOVE WK-POS-IN-VAR               TO WK-POS-IN
SI0921     MOVE WK-POS-OUT-VAR              TO WK-POS-OUT
SI0921     MOVE WK-LEN-VAR                  TO WK-LEN
SI0921     .
SI0921     PERFORM CHIAMA-YYUA0914
SI0921     THRU  F-CHIAMA-YYUA0914
SI0921     .
SI0921*---> rilocazione zona massimali
SI0921*
SI0921     MOVE WK-POS-IN-MAX-INT           TO WK-POS-IN
SI0921     MOVE WK-POS-OUT-MAX-INT          TO WK-POS-OUT
SI0921     MOVE WK-LEN-MAX-INT              TO WK-LEN
SI0921     .
SI0921     PERFORM CHIAMA-YYUA0914
SI0921     THRU  F-CHIAMA-YYUA0914
SI0921     .
SI0921     MOVE YZCWX71                   TO LINK-RISPOSTA-DATI
SI0921     .
SI0921 F-RILOCAZIONE-DATI.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 CHIAMA-YYUA0914.
SI0921     CALL 'YYUA0914' USING LINK-RISPOSTA-DATI
SI0921                           WK-POS-IN
SI0921                           YZCWX71
SI0921                           WK-POS-OUT
SI0921                           WK-LEN
SI0921     .
SI0921 F-CHIAMA-YYUA0914.
SI0921     EXIT.
      *-------------------------------------------------------------
      *  MODIFICA A.B. PER SEGNALAZIONE CATTURE SU STAMPA  - INIZIO
      *-------------------------------------------------------------
       INFORMA.
      *    MOVE EIBDATE                     TO MSG-DATE.
      *    MOVE EIBTIME                     TO MSG-TIME.
      *    MOVE EIBTRMID                    TO MSG-TERMID.
      *    MOVE COMM-PAN-RICH               TO MSG-PAN.
      *    MOVE BOATWW-RIFPRO               TO MSG-RF.
      *    MOVE SPACE                       TO MSG-TIPO.
      *    EXEC CICS WRITEQ TD QUEUE (CODA-MESSAGGI)
      *                        FROM  (MESSAGGIO-ERRORE)
      *                        LENGTH (CODA-MESSAGGI-LL)
      *    END-EXEC.
       INFORMA-EX.
           EXIT.
      *----
       RISCRIVI-POS-STORI.
           MOVE ZERO                 TO COMM-TIPO-RICH.
           MOVE 4                    TO COMM-FUNZ-RICH.
           MOVE ZERO                 TO COMM-ESITO-RICH.

           PERFORM AGGIORNA-RESIDUI  THRU F-AGGIORNA-RESIDUI.

           IF COMM-ABI-TERM  NOT = COMM-ABI-CARTA
      *           MOVE YZCRCIRC      TO LINK-CIRCOL
                  MOVE 'YZTCGB05'    TO WKPGMSUC
           ELSE
      *           MOVE YZCRPOSI      TO LINK-POSITIVO
                  MOVE 'YZTCGB04'    TO WKPGMSUC.

           PERFORM CHIAMA-ALTRO-PROGRAMMA THRU F-CHIAMA-ALTRO-PROGRAMMA.

       F-RISCRIVI-POS-STORI.
           EXIT.
      *
       LETTURA-FIT.
OLCA2      IF OLCA-CIRC-A71
OLCA2      IF YZCRA71-EPINK NOT = ZERO
OLCA2         GO TO F-LETTURA-FIT.
OLCA2 *140395-INIZIO
OLCA2      IF OLCA2-A-AZI-CON-PKC
OLCA2         GO TO F-LETTURA-FIT.
OLCA2 *140395-FINE
           MOVE ZERO                  TO YZCRFIT.
           MOVE ZERO                  TO YZCRFITL.


      *    IMPOSTAZIONE DELLA CHIAVE: NEL COD. ABI DELLA BANCA PAGATRICE
      *    IMPOSTIAMO L'ABI DEL TERM A MENO CHE NON SIA STATO FORZATO
      *    (PER I "POOL"), NEL QUAL CASO IMPOSTIAMO IL VERO CODICE ABI
           MOVE COMM-ABI-TERM         TO YZCRFIT-CODABIK.
           MOVE COMM-ABI-TERM         TO YZCRFITL-CODABIK.
           IF COMM-SW-FALSO-AZIENDALE = 1
               MOVE COMM-SV-ABI-ORIGINALE      TO YZCRFIT-CODABIK
               MOVE COMM-SV-ABI-ORIGINALE      TO YZCRFITL-CODABIK.
           MOVE COMM-ABI-CARTA        TO YZCRFIT-CODABI.
           MOVE COMM-ABI-CARTA        TO YZCRFITL-CODABI.

021091     IF YZCWYZ20-GEN-MULTIFIT        = ZERO
021091        GO TO LETTURA-FIT-CORTA.
021091 LETTURA-FIT-LUNGA.
021091
021091     MOVE YZCRYZ01-NUMERO-FIT   TO YZCRFITL-NUMERO-FIT.
021091     MOVE SPACE                 TO STCWIODB.
021091     MOVE YZ0FITL               TO STCWIODB-SEGMENTO.
021091     MOVE '17'                  TO STCWIODB-RIFERIMENTO.
021091     MOVE READONLY              TO STCWIODB-FUNZ.
021091     MOVE YZCRFITL-CHIAVE       TO STCWIODB-CHIAVE1.
021091     MOVE LEN-FITL              TO STCWIODB-RECLEN.
021091     MOVE 'EQ'                  TO STCWIODB-OPERATORE.
021091
021091     PERFORM MIODB THRU F-MIODB.
021091
021091     IF STCWIODB-RC = WK-NOTFND
021091         GO TO ERRORE-LETTURA-FIT.
021091
021091     MOVE STCWIODB-AREAIO       TO YZCRFITL.
021091     MOVE YZCRFITL-EPINKEY      TO YZCRFIT-EPINKEY.
021091     GO TO F-LETTURA-FIT.
021091 LETTURA-FIT-CORTA.
           MOVE SPACE                 TO STCWIODB.
           MOVE YZ0FIT                TO STCWIODB-SEGMENTO.
           MOVE '17'                  TO STCWIODB-RIFERIMENTO.
           MOVE READONLY              TO STCWIODB-FUNZ.
           MOVE YZCRFIT-CHIAVE        TO STCWIODB-CHIAVE1.
           MOVE LEN-FIT               TO STCWIODB-RECLEN.
           MOVE 'EQ'                  TO STCWIODB-OPERATORE.

           PERFORM MIODB THRU F-MIODB.

           IF STCWIODB-RC = WK-NOTFND
               GO TO ERRORE-LETTURA-FIT.

           MOVE STCWIODB-AREAIO       TO YZCRFIT.
           GO TO F-LETTURA-FIT.

      *----------------------------------------------------------------*
       ERRORE-LETTURA-FIT.
           MOVE 21                TO COMM-ANOMA-RICH
           MOVE 17                TO STCW196-RIFERIMENTO
           MOVE 00017             TO YZCWYZ05-RIFERIMENTO
           PERFORM SEGNALA-ERRORI THRU F-SEGNALA-ERRORI
           MOVE  1                TO SW-ERRORE
           MOVE  'KO'             TO COMM-ESITO-RICH.
           GO TO F-LETTURA-FIT.

       F-LETTURA-FIT.
           EXIT.
      *----------------------------------------------------------------*
      *=============================================================
      *---- FASE COMUNE INIZIALE                    ----------------
      *=============================================================

       FASE-COMUNE-INIZIALE.
           COPY YYCP0005.
           COPY YYCPU010.
           COPY YYCP0190.
           COPY YZCPYZ15.
SI0179     COPY YZCPKZ15.
SI1030* ---
SI1030     SET ADDRESS OF LINK-NEW-LIST TO LINK-PTR-PTR-NEW-LIST
SI1030     SET ADDRESS OF LINK-NEW-LIST     TO LINK-PTR-PTR-NEW-LIST
SI1030     SET ADDRESS OF YZCRPOCA      TO LINK-PTR-PTR-YZCRPOCA.
SI1030* ---
SI0417     MOVE COMMSPATR         TO STCW196-TRXNAME.
           MOVE 'YZTCA70 '        TO WKPGRMID.
           MOVE 'YZTCA70 '        TO YZCWYZ05-PROGRAMMA.
           MOVE 'KO'              TO COMM-ESITO-GENERALE.
281093     MOVE    'SI'  TO WK-RISCRITTURA.
OLCA2      MOVE    'NO'  TO WK-PKC-DA-INVIARE.


           MOVE SPACE             TO WK-MESS-CLIENTE-62
                                     WK-MESS-CLIENTE-28
                                     WK-SEGNO
                                     WK-DATA-SALDO.

           MOVE ZERO              TO WK-PTR-COMODO
                                     WK-INDIR-AREA-YZCRANA
                                     WK-NUMOPER
                                     WK-LUNGH-A71
                                     IND-RAPP
                                     IND-MESS
                                     WK-MESS-CLIENTE-XX
                                     WK-SALDO-11
                                     WK-IND-SOVRAPP
                                     WK-IND-ESAME
                                     SW-STG-NON-OK.
SA0959     IF COMMSPATR NOT EQUAL YZCWYZ20-OLCA-TRN-PER-RISP
SA0693     MOVE ZEROES                 TO COMM-RES-GIOR.
SA0959     IF COMMSPATR NOT EQUAL YZCWYZ20-OLCA-TRN-PER-RISP
SA0693     MOVE ZEROES                 TO COMM-RES-MENS.

SI0822     MOVE YZCTKABD-AREA-YZCVNR02 TO YZCTKABD-YZCVNR02.
SI0831     MOVE SPACES                 TO WK-QUALE-TRACCIA.
SI1221     MOVE '0'                    TO WK-PKEP-ABI-5(1:1)
SI1221     MOVE YZCRYZ01-CODABI        TO WK-PKEP-ABI-5(2:4)
SP0006*----------->
SP0006     MOVE YZCRYZ01-CODABI        TO YZCWEXIT-ABI-MITT
SP0006     MOVE ZEROES                 TO YZCWEXIT-ABI-ORD
SP0006     MOVE '01'                   TO YZCWEXIT-PGM-PASSO
SP0006*----------->
SP0006     PERFORM EL-PASSO-DEC        THRU F-EL-PASSO-DEC.
SP0006*----------->
       F-FASE-COMUNE-INIZIALE.
           EXIT.
      *=============================================================
      *---- SEGNALAZIONE DEGLI ERRORI               ----------------
      *=============================================================
       SEGNALA-ERRORI.
           COPY YZCPYZ12.
      *=============================================================
      *---- FASE COMUNE INIZIALE                    ----------------
      *=============================================================
       M061.
           COPY  YYCP0061.
       M063.
           COPY  YYCP0063.
      *==============================================================*
      *    M065  - ROUTINE DI CONVERSIONE DA ESADECIMALE A           *
      *            ZONED                                             *
      *==============================================================*
       M065.
           COPY  YYCP0065.
       M071.
           COPY  YYCP0071.
YOUNG  MUTDAT.
YOUNG      COPY  YYCPUTDA.
      *==============================================================*
      *          - ROUTINE DI START DELLA TRANSAZIONE CHE SEGNALA    *
      *            GLI ERRORI SUL RELATIVO LOG                       *
      *==============================================================*

SA0076*    COPY YYCPG191.
SA0076     COPY YYCPU191.
      *==============================================================*
      *    MIODB - ROUTINE DI RICHIAMO MODULO I-O D.B.
      *==============================================================*
       MIODB.
           COPY YYCPUIDB.
      *==============================================================*
      *    MIODC - ROUTINE DI RICHIAMO MODULO I-O D.C.
      *==============================================================*
       MIODC.
           COPY YYCPGIDC.
      *=============================================================
      *--------------  LINK A PGM DESIDERATO   ---------------------
      *=============================================================
       CHIAMA-ALTRO-PROGRAMMA.
      *------
           COPY YZCPYZ92.
      *------
       F-CHIAMA-ALTRO-PROGRAMMA.
           EXIT.
       MLINK.
      *
           COPY   YYCP0903.
      *==============================================================*
       RIEMPI-A71-AZIONE-PER-ANOM.
      *    SE C'E' UNA ANOMALIA,IL CAMPO A71-AZIONE VIENE VALORIZZATO A
      *    2 O 3 A SECONDA CHE LA CARTA SIA DA CATTURARE O MENO.

           IF COMM-ANOMA-RICH NOT = ZERO
SA0416        MOVE 'E'      TO YZCRA71-DISP-X (1:1)
               IF COMM-ESITO-RICH = 'CA' OR 'NP'
                   MOVE '2' TO YZCRA71-AZIONE
270694*            ADD   1  TO YZCRYZ01-NUMCAT
SA0446*---  ASTERISCATO LA PRECEDENTE
               ELSE
                   MOVE '3' TO YZCRA71-AZIONE.
       F-RIEMPI-A71-AZIONE-PER-ANOM.
           EXIT.
      *==============================================================*
       AGGIORNA-RESIDUI.
           IF COMM-ABI-TERM  NOT = COMM-ABI-CARTA
               PERFORM AGGIORNA-RESIDUI-CIRC THRU
                     F-AGGIORNA-RESIDUI-CIRC
           ELSE
               PERFORM AGGIORNA-RESIDUI-POSI THRU
                     F-AGGIORNA-RESIDUI-POSI.
       F-AGGIORNA-RESIDUI.
           EXIT.
      *==============================================================*
       AGGIORNA-RESIDUI-POSI.

           MOVE  YZCRA70-DATAOP            TO YZCRPOSI-DATAOP.
           MOVE  YZCRYZ01-CODABI           TO YZCRPOSI-CODABIU.
           MOVE  YZCRYZ01-CODATM           TO YZCRPOSI-CODATMU.
           MOVE  YZCRA70-DATAMES           TO YZCRPOSI-ULTVAR.
           MOVE  YZCRA70-INIZPER           TO YZCRPOSI-INIZPER.
           MOVE  YZCRA70-RESPER            TO YZCRPOSI-RESPER.
021091     MOVE  YZCRA70-RESTPER           TO YZCRPOSI-RESTPER.
021091     MOVE  YZCRA70-CONTPIN           TO YZCRPOSI-CONTPIN.
021091     MOVE  YZCRA70-ORAMES            TO YZCRPOSI-ORAOP.

       F-AGGIORNA-RESIDUI-POSI.
           EXIT.
      *==============================================================*
       AGGIORNA-RESIDUI-CIRC.

           MOVE  YZCRA70-DATAOP            TO YZCRCIRC-DATAOP.
           MOVE  YZCRYZ01-CODABI           TO YZCRCIRC-CODABIU.
           MOVE  YZCRYZ01-CODATM           TO YZCRCIRC-CODATMU.
           MOVE  YZCRA70-DATAMES           TO YZCRCIRC-ULTVAR.
           MOVE  YZCRA70-INIZPER           TO YZCRCIRC-INIZPER.
           MOVE  YZCRA70-RESPER            TO YZCRCIRC-RESPER.
           MOVE  YZCRA70-RESTPER           TO YZCRCIRC-RESTPER.
021091     MOVE  YZCRA70-RESTPER           TO YZCRCIRC-RESTPER.
021091     MOVE  YZCRA70-CONTPIN           TO YZCRCIRC-CONTPIN.
021091     MOVE  YZCRA70-ORAMES            TO YZCRCIRC-ORAOP.

       F-AGGIORNA-RESIDUI-CIRC.
           EXIT.
      *==============================================================*
       ERRORE-DATA.
           MOVE 40                TO COMM-ANOMA-RICH.
           MOVE 21                TO STCW196-RIFERIMENTO.
           PERFORM SEGNALA-ERRORI THRU F-SEGNALA-ERRORI.
           MOVE  1                TO SW-ERRORE.
           MOVE  'KO'             TO COMM-ESITO-RICH.
       F-ERRORE-DATA.
           EXIT.
      *==============================================================*
       COMPLETA-MESS.
SI0800     IF WK-AUTORIZZO-VIA-OS390-SI
SI0800        IF WK-AUTORIZZO-VIA-OS390-SIMAKO
SI0800           MOVE ZEROES         TO YZCRA71-EPINK
SI0800        ELSE
SI0800           MOVE WK-EPINK-OS390 TO YZCRA71-EPINK
SI0800        END-IF
SI0800     END-IF.
SI0822*    IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*       YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905     IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822        PERFORM ACCODAMENTO-SECONDA-TRACCIA
SI0822        THRU  F-ACCODAMENTO-SECONDA-TRACCIA
SI0822     .
MSGCLI*----------------------------------------------------------------*
MSGCLI*    SE SI DISASTERISCA IN QUESTO PUNTO LA PERFORM
MSGCLI*    SEGUENTE LA SI DEVE ASTERISCARE PIU' AVANTI
MSGCLI*----------------------------------------------------------------*
MSGCLI*    PERFORM TEST-SE-MSG-CLIENTE THRU F-TEST-SE-MSG-CLIENTE.
MSGCLI*----------------------------------------------------------------*
           IF COMM-ABI-TERM  NOT = COMM-ABI-CARTA
               MOVE '1000000000' TO YZCRA71-PROF
MPSINF         PERFORM RIEMPI-PR09-CIR  THRU F-RIEMPI-PR09-CIR
               GO TO F-COMPLETA-MESS.

      *    PROSEGUIAMO SOLO SE SI TRATTA DI CARTA AZIENDALE
      *    O POOL

           MOVE YZCRPOSI-SERVIZI TO YZCRA71-PROF.

MPSINF     PERFORM RIEMPI-PR09-AZI  THRU F-RIEMPI-PR09-AZI.

SI0196     PERFORM TEST-PER-VERSAMENTO-EURO
SI0196     THRU  F-TEST-PER-VERSAMENTO-EURO
SI0196     .
SI0601     IF COMM-ABI-CARTA = COMM-ABI-TERM AND
SI0601        YZCRA70-TIPORAP = '9'          AND
SI0601        YZCRA70-RESTROP = '8'          AND
SI0601        WYZ10-ABD-AUT-PREP-OLI
SI0601        CONTINUE
SI0601     ELSE
           PERFORM CERCA-SALDO         THRU F-CERCA-SALDO.
SI0088
SI0601     IF COMM-ABI-CARTA = COMM-ABI-TERM AND
SI0601        YZCRA70-TIPORAP = '9'          AND
SI0601        YZCRA70-RESTROP = '8'          AND
SI0601        WYZ10-ABD-AUT-PREP-OLI
SI0601        MOVE SPACES                   TO YZCRANA-SEGNO-SALDO-PREL
SI0601        MOVE ZEROES                   TO YZCRANA-SALDO-PREL
SI0601        MOVE ZEROES                   TO YZCRANA-DATA-SALDO-PREL
SI0601        PERFORM GESTIONE-MAX-INT
SI0601        THRU  F-GESTIONE-MAX-INT
SI0601     ELSE
R16104        IF SW-ERRORE = '1'
SP0359        OR YZCRA71-PR01 = ZERO
R16104           MOVE ZERO               TO COMM-IMPORTO-AUTOR-1
R16104        ELSE
SI0088     PERFORM GESTIONE-MAX-INT    THRU F-GESTIONE-MAX-INT
SI0601     END-IF
SI0601     .
SI0601*--->
SI0601     IF COMM-ABI-CARTA = COMM-ABI-TERM AND
SI0601        YZCRA70-TIPORAP = '9'          AND
SI0601        YZCRA70-RESTROP = '8'          AND
SI0601        WYZ10-ABD-AUT-PREP-OLI
SI1030* ---
SI1030       IF RPOSI-RISCHIO-CARTA-SI
SI1030        MOVE YZCRPOCA-MONTE-MONETA-DATA(7:2) TO YZCRA71-DATA(1:2)
SI1030        MOVE YZCRPOCA-MONTE-MONETA-DATA(5:2) TO YZCRA71-DATA(3:2)
SI1030        MOVE YZCRPOCA-MONTE-MONETA-DATA(3:2) TO YZCRA71-DATA(5:2)
SI1030        MOVE YZCRPOCA-MONTE-MONETA-V    TO WK-SALDO-11-E
PREPA1        MOVE YZCRPOCA-MONTE-MONETA-S    TO WK-SEGNO
SI1030       ELSE
SI0601        MOVE YZCRPOSI-MONTE-MONETA-DATA TO YZCRA71-DATA
SI0601        MOVE YZCRPOSI-MONTE-MONETA      TO WK-SALDO-11-E
PREPA1        MOVE YZCRPOSI-MONTE-MONETA-S    TO WK-SEGNO
SI1030       END-IF
SI0601*--->
SI0601        PERFORM CONTA-LE-PRENOTATE
SI0601        THRU  F-CONTA-LE-PRENOTATE
SI0601*--->
SI1030*      IF RPOSI-RISCHIO-CARTA-SI
SI1030*       MOVE YZCRPOCA-MONTE-MONETA-S    TO WK-SEGNO
SI1030*      ELSE
SI0601*       MOVE YZCRPOSI-MONTE-MONETA-S    TO WK-SEGNO
SI1030*      END-IF
PREPA1*--> Asteriscate le 5 righe precedenti
SI0601        MOVE 'E'                        TO WK-SALDO-12(01:01)
SI0601        MOVE WK-SALDO-12                TO YZCRA71-SALDO
SI0601     .

BALDAX*---  ASTERISCATO LE SUCCESSIVE 4 RIGHE PER SPOSTARLE DOPO LA
BALDAX*--- GESTIONE DELLA DIVISA DEL SALDO E DELLA DISPONIBILITA'
POSTE *    IF COMM-IMPORTO-AUTOR-1 > ZERO
POSTE *       PERFORM PRENOTA-DISPONIBILITA
POSTE *        THRU F-PRENOTA-DISPONIBILITA
POSTE *    .
VALNCR     IF YZCRYZ01-TIPO-TERM = 8
VALNCR        PERFORM CERCA-CAMBI      THRU F-CERCA-CAMBI
VALNCR*       ADD  +63   TO WK-LUNGH-A71.
SP0006*ASTERISCATA LA PRECEDENTE
SP0006        PERFORM GESTIONE-CAMBI   THRU F-GESTIONE-CAMBI
SP0006        .
SP0006*----------->
SP0006     PERFORM GESTIONE-NOME       THRU F-GESTIONE-NOME
SP0006*----------->
SP0006     PERFORM GESTIONE-PROFILO    THRU F-GESTIONE-PROFILO
SP0006*----------->
SI0245     PERFORM CONTROLLA-CASSETTI-ATM
SI0245      THRU F-CONTROLLA-CASSETTI-ATM
SI0245     .
SI1077     PERFORM CONTROLLA-AID
SI1077      THRU F-CONTROLLA-AID
SI1077     .
SI0336*-----------> IN ATTESA DI UNA GESTIONE DINAMICA DEL TERZO
SI0336*-----------> BYTE DEL PROFILO (RT05) LA GESTIONE SEGUENTE
SI0336*-----------> E' ATTIVA SOLO PER POSTE ITALIANE
SI0336     IF YZCRA71-PR03 NOT = ZEROES
SI0336        MOVE 4                   TO YZCRA71-PR03
SI0336     .

R16104     IF SW-ERRORE NOT = '1'
030792     PERFORM TEST-SE-MSG-CLIENTE THRU F-TEST-SE-MSG-CLIENTE.

           GO                    TO F-COMPLETA-MESS.
       F-COMPLETA-MESS.
           EXIT.

      *-----------------------------------------------------------------
      * CHIAMATA AL MODULO YZTCANA  CHE A SUA VOLTA GESTIRA' LA CHIAMATA
      * ALLE ROUTINES DELL'ISTITUTO O ANDRA' A LEGGERE ALCUNI FILES
      * IN QUESTO CASO ANDREMO A LEGGERE IL FILE BOAISER.
      * (SERVE PER GLI ATM DISP. STANDARD CHE ANCORA HANNO IL SALDO
      *        CONTENUTO NELL'ULTIMA ZONA DI BOAISER)
      *-----------------------------------------------------------------
ATM
ATM    CERCA-SALDO.
ATM
ATM        MOVE YZCRYZ01-TIPO-TERM    TO   YZCRANA-TIPOSA.
ATM        MOVE YZCRA70-CODMES        TO   YZCRANA-COD-MESSAGGIO.
YOUNG      IF YZCRPOSI-TIPORAP = 1
YOUNG         MOVE 'DR'               TO   YZCRANA-SERVIZIO
YOUNG      ELSE
ATM        MOVE 'CC'                  TO   YZCRANA-SERVIZIO.
ATM        MOVE ZERO                  TO   YZCRANA-ZONA-SOTTOFUNZIONI.
ATM        MOVE 99                    TO   YZCRANA-SOTTOFUNZ(10).
ATM        MOVE ZERO                  TO   YZCRANA-LIVELLO-MENU.
ATM        MOVE ZERO                  TO   YZCRANA-RC.
ATM        MOVE ZERO                  TO   YZCRANA-ANOM.
ATM        MOVE ZERO                  TO   YZCRANA-RC-RISPOSTA.
ATM        MOVE ZERO                  TO   YZCRANA-ANOM-RISPOSTA.
ATM        MOVE YZCRA70-NUMMES        TO   YZCRANA-NTRANS.
ATM   *    MOVE YZCRYZ01-DIPEND       TO   YZCRANA-FILIALE-SA.
POSTE *---  ASTERISCATA LA PRECEDENTE
POSTE      MOVE YZCRYZ01-SEDE-INSTAL(4:2)
POSTE                                 TO YZCRANA-FILIALE-SA(1:2)
POSTE      MOVE YZCRYZ01-DIPEND(2:3)  TO YZCRANA-FILIALE-SA(3:3)
ATM        MOVE YZCRA70-CODATM        TO   YZCRANA-NSA.
ATM        MOVE YZCRYZ01-TERMCICS     TO   YZCRANA-TERMID.
ATM        MOVE YZCRA70-DATAMES       TO   YZCRANA-DATARICH.
ATM        MOVE YZCRA70-ORAMES        TO   YZCRANA-ORARICH-HHMM.
ATM        MOVE ZERO                  TO   YZCRANA-ORARICH-SS.
ATM        MOVE YZCRYZ01-IND-CHIAM-ANAG TO YZCRANA-PROG-CHIAMATA.
BPVMOD     MOVE YZCRYZ01-MARCA        TO   YZCRANA-MARCA
BPVMOD     MOVE YZCRPOSI-CARTA        TO   YZCRANA-NUMERO-CARTA
ATM        MOVE YZCRA70-PAN           TO   YZCRANA-PAN.
ATM        MOVE ZERO                  TO   YZCRANA-TOT-MSG.
ATM        MOVE ZERO                  TO   YZCRANA-PROGR-MSG.
SA0076     MOVE YZCRPOSI-COD-DIV-CONTO TO  YZCRANA-COD-DIV-SALDO-PREL
ATM        MOVE YZCRPOSI-SALDO-S      TO   YZCRANA-SALDO-POSI.
ATM        MOVE YZCRPOSI-DATASD       TO   YZCRANA-DATASD-POSI.
ATM        MOVE YZCRA70               TO   YZCRANA-TRANS-CHIAM.
080293     MOVE YZCRPOSI-AGENZIA      TO   YZCRANA-CARTA-FILIALE.
080293     MOVE YZCRPOSI-CONTO        TO   YZCRANA-CARTA-CONTO.
SP0006     MOVE YZCRYZ01-CODABI       TO   YZCRANA-CODABI-TERM.
SI0511     MOVE YZCRYZ01-COD-DIVISA-OPER TO YZCRANA-COD-DIV-OPER-ATM
SI0511     .
ATM   *----
ATM        MOVE +6500         TO LINKLEN.
ATM        MOVE YZCRANA       TO LINKAREA.
ATM        MOVE 'YZTCANA'     TO LINKPGM.
ATM   *----
ATM
ATM        PERFORM MLINK THRU F-MLINK.
ATM        MOVE LINKAREA      TO YZCRANA.
ATM
ATM        IF YZCRANA-RC-RISPOSTA NOT = ZERO
R16104     AND YZCRANA-RC-RISPOSTA NOT = 3
R16104     AND YZCRANA-RC-RISPOSTA NOT = 4
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 5
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 6
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 7
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 8
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 'A'
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 'B'
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 'C'
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 'D'
ATM            MOVE ZERO TO YZCRA71-SALDO
ATM            MOVE ZERO TO YZCRA71-DATA
SI0117         MOVE ZERO TO YZCRANA-SALDO-PREL
SI0117         MOVE ZERO TO YZCRANA-DATA-SALDO-PREL
BLDX02         MOVE ZERO TO YZCRA71-PR02
ATM            MOVE ZERO TO YZCRA71-PR03
300192         MOVE ZERO TO YZCRA71-PR04
BLDX02         MOVE ZERO TO YZCRA71-PR05
BLDX02         MOVE ZERO TO YZCRA71-PR06
BLDX02         MOVE ZERO TO YZCRA71-PR07
BLDX02         MOVE ZERO TO YZCRA71-PR08
BLDX02         MOVE ZERO TO YZCRA71-PR09
BLDX02         MOVE ZERO TO YZCRA71-PR10
POSTE          MOVE 'RS'                 TO STCW196-RIFERIMENTO
POSTE          PERFORM SEGNALA-ERRORE-TCANA
POSTE           THRU F-SEGNALA-ERRORE-TCANA
ATM        ELSE
R16104       IF YZCRANA-RC-RISPOSTA = 3
R16104         MOVE '15'                 TO COMM-ANOMA-RICH
R16104         MOVE 'KO'                 TO COMM-ESITO-RICH
R16104         MOVE 'NO'                 TO WK-RISCRITTURA
R16104         MOVE 1                    TO SW-ERRORE
R16104       ELSE
SI0143         MOVE YZCRANA-COD-DIV-SALDO-PREL
SI0143                              TO YZCRPOSI-COD-DIV-CONTO
ATM            MOVE YZCRANA-RIGA(1) TO WK-SALDO-E-DATA
ATM            MOVE WK-SALDO-12     TO YZCRA71-SALDO
ATM            MOVE WK-DATA-SALDO   TO YZCRA71-DATA.
SA0429
SA0429     MOVE 'E'                 TO YZCRPOSI-COD-DIV-CONTO.
ATM
ATM    F-CERCA-SALDO.
ATM        EXIT.
VALNCR*=================================================================
VALNCR* CHIAMATA AL MODULO YZTCANA  CHE A SUA VOLTA GESTIRA' LA CHIAMATA
VALNCR* ALLE ROUTINES DELL'ISTITUTO PER CARICARE I CAMBI VALUTA
VALNCR* PER CAMBIA VALUTE NCR
VALNCR*=================================================================
VALNCR*CERCA-CAMBI.
VALNCR     COPY YZCPYZ39.
VALNCR*F-CERCA-CAMBI.
VALNCR*    EXIT.
      *=============================================================
       ABI-PARTICOLARI.
           COPY YZCPYZ18.
       F-ABI-PARTICOLARI.
           EXIT.
      *==============================================================*
SI0179*LETTURA-TABELLA-ABI.
SI0179*    COPY YZCPYZ08.
SI0179*F-LETTURA-TABELLA-ABI.
SI0179*    EXIT.
SI0179*==============================================================*
SI0179*    DETERMINA TIPO TRANSAZIONE (AZI/ORI/CIR)                  *
SI0179*==============================================================*
SI0179 DETERMINA-AZI-ORI-CIR.
SI0179     COPY YZCPKZ08.

      *==============================================================*
      * CERCA TERZA TRACCIA                                          *
      *==============================================================*
SA0197 CERCA-TERZA-TRACCIA.
SA0197     MOVE YZCRA70-INIZPER TO WS-YZCRX70-INIZPER
SA0197     MOVE YZCRA70-DATAOP  TO WS-YZCRX70-DATAOP
SA0197     MOVE YZCRA70-RESPER  TO WS-YZCRX70-RESPER
SA0197     MOVE YZCRA70-RESTPER TO WS-YZCRX70-RESTPER
SA0197     .
131191     COPY YZCPYZ22.
      *==============================================================*
      * COMPATTAZIONE TERZA TRACCIA NEI DUE FORMATI: (CON E SENZA SCAD)
      *==============================================================*
SA0197*ASTERISCATA LA SUCCESSIVA
131191*    COPY YZCPYZ23.
      *==============================================================*
      * INVIO  DEL MESSAGGIO A71 PER RIMAGNETIZZAZIONE III TRACCIA
      *==============================================================*
131191 PREPARA-INVIO-III-TRACCIA.
131191     MOVE ZERO                 TO YZCRA71.
131191     MOVE 'A71'                TO YZCRA71-CODMES.
131191     MOVE YZCRA70-CODATM       TO YZCRA71-CODATM.
131191     MOVE YZCRA70-NUMMES       TO YZCRA71-NUMMES.
131191     MOVE YZCRA70-DATAMES      TO YZCRA71-DATAMES
131191     MOVE YZCRA70-ORAMES       TO YZCRA71-ORAMES.
131191     MOVE 1                    TO YZCRA71-FLT3.
131191     MOVE 3                    TO YZCRA71-AZIONE.
131191     MOVE 'FF'                 TO YZCRA71-ANOM.
131191*    MOVE YZCRSER-3TRACCIA     TO YZCRA71-T3A.
SA0197*ASTERISCATA LA PRECEDENTE
SA0197     MOVE WS-FIMA-COMPLETA     TO YZCRA71-T3A.
131191     MOVE MSG-VAR3             TO YZCRA71-MES-ATM.
131191
131191     MOVE +274                 TO LINK-RISPOSTA-LUNG.
131191     MOVE YZCRA71              TO LINK-RISPOSTA-DATI.
131191 F-PREPARA-INVIO-III-TRACCIA.
131191     EXIT.
SA0197*-INIZIO--->
SA0197*----------> L'ALLINEAMENTO SOLO ALLA CONFERMA DI AVVENUTA
SA0197*----------> RIMAGNETIZZAZIONE (X20/32 SUCCESSIVA) PERTANTO
SA0197*----------> LA ROUTINE DEVE ESSERE DEFINITIVAMENTE ASTERISCATA
RVS   *INVIA-ALLINEAMENTO.
SP0021*----------------> PERSONALIZZAZIONE PER RAIFFEISEN
SP0021*----------------> NON INVIO IL MESSAGGIO 200 IN QUANTO GIA
SP0021*----------------> INVIATO DA GECA NELLA FUNZIONE DI ANNULLAMENTO
SP0021*----------------> FUNZIONALITA BANCOMAT (PGM : ZYGCA530)
SP0021*----------------> IMPOSTIAMO LO STATO DI ESTINZIONE IN QUESTO
SP0021*----------------> MOMENTO PERCHE' GECA LASCIA LA CARTA IN ESSERE
SP0021*----------------> PER PERMETTERE LA RIMAGNETIZZAZIONE DELLA CARTA
SP0021*    IF  YZCRSER-3TRACCIA(4:100) = ZERO
SP0021*        MOVE  6        TO YZCRPOSI-CATTURA
SP0021*        GO TO F-INVIA-ALLINEAMENTO.
RVS   *    COPY YZCPYZ19.
RVS   *F-INVIA-ALLINEAMENTO.
RVS   *    EXIT.
SA0197*----------> L'ALLINEAMENTO SOLO ALLA CONFERMA DI AVVENUTA
SA0197*----------> RIMAGNETIZZAZIONE (X20/32 SUCCESSIVA) PERTANTO
SA0197*----------> LA ROUTINE DEVE ESSERE DEFINITIVAMENTE ASTERISCATA
SA0197*-FINE----->
030792 TEST-SE-MSG-CLIENTE.
030792     MOVE 'A70'         TO COMM-TIPO-RICH.
030792     MOVE 6             TO COMM-FUNZ-RICH.
030792     MOVE ZERO          TO COMM-DATI-RAPPORTO.
SP0006
SP0006     IF NOT YZTCA70-01-PGM-PASSO-NF
SP0006        IF YZTCA70-01-MSG-LUNGO-SI
SP0006           MOVE 10      TO COMM-FUNZ-RICH
YOUNG            MOVE YZCRANA-COD-MSG-DIN   TO COMM-TIPO-MSG-PUBBL
SP0006           .
030792     MOVE 'YZTCGB0B'    TO WKPGMSUC.
030792     PERFORM CHIAMA-ALTRO-PROGRAMMA THRU
030792           F-CHIAMA-ALTRO-PROGRAMMA.
030792*    MOVE COMM-MESSAGGIO TO WK-MESS-CLIENTE-92.
SP0006*ASTERISCATA LA PRECEDENTE
MSGCLI*----------------------------------------------------------------*
MSGCLI*    COPY YZCPMCL1.
MSGCLI*----------------------------------------------------------------*
030792     IF (COMM-MESSAGGIO = SPACES) OR
030792        (COMM-MESSAGGIO = LOW-VALUE) OR
030792        (YZCRA71-ANOM NOT = ZERO)
SI0116        MOVE ZEROES      TO YZCRYZ01-LEN-MSG
SI0822*       IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*          YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905        IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822           MOVE WK-COMODO-FLAG    TO YZCRA71-FLAG-NR-3
SI0822           MOVE WK-COMODO-TRACCIA TO YZCRA71-IITRACCIA-3
SI0831           MOVE '3'               TO WK-QUALE-TRACCIA
SI0822*          ADD  40                TO WK-LUNGH-A71
SA0889*---  Asteriscata la precedente
SA0889           ADD  41                TO WK-LUNGH-A71
SI0822           ADD  41                TO LINK-RISPOSTA-LUNG
SI0822        END-IF
030792        GO TO F-TEST-SE-MSG-CLIENTE.
SP0006*
SP0006     IF NOT YZTCA70-01-PGM-PASSO-NF
SP0006        IF YZTCA70-01-MSG-LUNGO-SI
SP0006           PERFORM GESTIONE-MESSAGGIO THRU F-GESTIONE-MESSAGGIO
SP0006           GO TO F-TEST-SE-MSG-CLIENTE.
SP0006*
SP0006     MOVE COMM-MESSAGGIO TO WK-MESS-CLIENTE-92.

210793     IF YZCRYZ01-TIPO-TERM = 8
210793     AND YZCRA71-PR01 > 1
SP0006       IF  NOT YZTCA70-01-PGM-PASSO-NF
SP0006       AND YZTCA70-01-NOME-A71-SI
SI0822*        IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*           YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905         IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822            MOVE WK-COMODO-FLAG     TO YZCRA71-FLAG-NR-4
SI0822            MOVE WK-COMODO-TRACCIA  TO YZCRA71-IITRACCIA-4
SI0831            MOVE '4'                TO WK-QUALE-TRACCIA
SI0822            MOVE WK-MESS-CLIENTE-90 TO YZCRA71-AREA-ATM4-MSG-NR
SI0822         ELSE
SP0006         MOVE WK-MESS-CLIENTE-90 TO YZCRA71-AREA-ATM4-MSG
SI0822         END-IF
SP0006       ELSE
SI0822*        IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*           YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905         IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822            MOVE WK-COMODO-FLAG     TO YZCRA71-FLAG-NR-2
SI0822            MOVE WK-COMODO-TRACCIA  TO YZCRA71-IITRACCIA-2
SI0831            MOVE '2'                TO WK-QUALE-TRACCIA
SI0822            MOVE WK-MESS-CLIENTE-90 TO YZCRA71-AREA-ATM2-MSG-1-NR
SI0822         ELSE
210793         MOVE WK-MESS-CLIENTE-90 TO YZCRA71-VAL-MES-ATM
SI0822         END-IF
210793     ELSE
SP0006       IF  NOT YZTCA70-01-PGM-PASSO-NF
SP0006       AND YZTCA70-01-NOME-A71-SI
SI0822*        IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*           YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905         IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822            MOVE WK-COMODO-FLAG     TO YZCRA71-FLAG-NR-5
SI0822            MOVE WK-COMODO-TRACCIA  TO YZCRA71-IITRACCIA-5
SI0831            MOVE '5'                TO WK-QUALE-TRACCIA
SI0822            MOVE WK-MESS-CLIENTE-90 TO YZCRA71-AREA-ATM5-MSG-NR
SI0822         ELSE
SP0006         MOVE WK-MESS-CLIENTE-90 TO YZCRA71-AREA-ATM5-MSG
SI0822         END-IF
SP0006       ELSE
SI0822*        IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*           YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905         IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822            MOVE WK-COMODO-FLAG     TO YZCRA71-FLAG-NR-3
SI0822            MOVE WK-COMODO-TRACCIA  TO YZCRA71-IITRACCIA-3
SI0831            MOVE '3'                TO WK-QUALE-TRACCIA
SI0822            MOVE WK-MESS-CLIENTE-90 TO YZCRA71-AREA-ATM3-MSG-1-NR
SI0822         ELSE
210793         MOVE WK-MESS-CLIENTE-90 TO YZCRA71-SOLO-MES-ATM.

030792     MOVE WK-MESS-CLIENTE-XX TO COMM-ANOMA-RICH.
030792     ADD  +90  TO WK-LUNGH-A71.
SI0116     MOVE +90  TO YZCRYZ01-LEN-MSG.
030792
SI0822*    IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*       YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905     IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822*       ADD  40                    TO WK-LUNGH-A71
SA0889*---  Asteriscata la precedente
SA0889        ADD  41                    TO WK-LUNGH-A71
SI0822        ADD  41                    TO YZCRYZ01-LEN-MSG
SI0822        ADD  41                    TO LINK-RISPOSTA-LUNG
SI0822     .
030792 F-TEST-SE-MSG-CLIENTE.
030792     EXIT.
MSGCLI*----------------------------------------------------------------*
MSGCLI*    COPY YZCPMCL3.
MSGCLI*----------------------------------------------------------------*

MPSINF RIEMPI-PR09-CIR.
           IF YZCRYZ01-TIPO-TERM NOT = 3
OLCA1 *OLCA2    OR OLCA1 OR OLCA2
OLCA1           OR OLCA-CIRC-A71
              GO TO F-RIEMPI-PR09-CIR.
MPSINF     PERFORM LEGGI-TAB-STG         THRU F-LEGGI-TAB-STG.
MPSINF     IF SW-STG-NON-OK = '1'
MPSINF         MOVE ALL 'D' TO WK-AREA-INA-RISUL
MPSINF     ELSE
MPSINF         PERFORM LEGGI-TAB-INA         THRU F-LEGGI-TAB-INA
MPSINF         PERFORM LEGGI-TAB-INA-MAPPE   THRU F-LEGGI-TAB-INA-MAPPE
MPSINF         PERFORM SOVRAPPOSIZIONE       THRU F-SOVRAPPOSIZIONE.
MPSINF     PERFORM ESAME-ABIL-INFORM-CIR THRU F-ESAME-ABIL-INFORM-CIR
MPSINF         VARYING WK-IND-ESAME FROM 1 BY 1 UNTIL
MPSINF                 WK-IND-ESAME > 99.
MPSINF F-RIEMPI-PR09-CIR.
MPSINF     EXIT.
MPSINF RIEMPI-PR09-AZI.
           IF YZCRYZ01-TIPO-TERM NOT = 3
              GO TO F-RIEMPI-PR09-AZI.
CRT==>*
CRT==>*DISABILITIAMO INFORMAT SE CARTA CARDI
CRT==>*MISSANA - SETTEMBRE 1994
CRT==>*    IF  YZCRPOSI-MULTIFUNZIONE = '2'
CRT==>*        MOVE '2' TO YZCRA71-PR09
CRT==>*        GO TO F-RIEMPI-PR09-AZI.
CRT==>*
MPSINF     PERFORM LEGGI-TAB-STG         THRU F-LEGGI-TAB-STG.
MPSINF     IF SW-STG-NON-OK = '1'
MPSINF         MOVE ALL 'D' TO WK-AREA-INA-RISUL
MPSINF     ELSE
MPSINF         PERFORM LEGGI-TAB-INA         THRU F-LEGGI-TAB-INA
MPSINF         PERFORM LEGGI-TAB-INA-MAPPE   THRU F-LEGGI-TAB-INA-MAPPE
MPSINF         PERFORM SOVRAPPOSIZIONE       THRU F-SOVRAPPOSIZIONE.
MPSINF     PERFORM ESAME-ABIL-INFORM-AZI THRU F-ESAME-ABIL-INFORM-AZI
MPSINF         VARYING WK-IND-ESAME FROM 1 BY 1 UNTIL
MPSINF                 WK-IND-ESAME > 99.
CRT==>*
CRT==>*SE ATM GESTISCE INFORMAT
CRT==>*   SE CARTA DI CASSA CHE NON LO GESTISCE SUI PROPRI ATM
CRT==>*      DISABILITO INFORMAT E ABILITO SALDO ED ESTRATTO CONTO
CRT==>*   ALTRIMENTI
CRT==>*      ABILITO INFORMAT E DISABILITO SALDO ED ESTRATTO CONTO
CRT==>*MISSANA - MARZO 1995
CRT==>*    IF   YZCRA71-PR09 = '1'
CRT==>*      IF   COMM-ABI-CARTA = 6320
CRT==>*      OR   COMM-ABI-CARTA = XXXX
CRT==>*      OR   COMM-ABI-CARTA = YYYY
CRT==>*           MOVE ZERO              TO YZCRA71-PR03
CRT==>*           MOVE ZERO              TO YZCRA71-PR04
CRT==>*      ELSE
CRT==>*           MOVE ZERO              TO YZCRA71-PR09.
CRT==>*
MPSINF F-RIEMPI-PR09-AZI.
MPSINF     EXIT.
MPSINF*==============================================================*
MPSINF* LETTURA DELLA TABELLA ABILITAZIONI INFORMATIVE "ALTA"        *
MPSINF* (CIOE' VALIDA PER TUTTO IL SISTEMA)                          *
MPSINF*==============================================================*
MPSINF LEGGI-TAB-INA.
MPSINF     MOVE SPACE                 TO YZCWYZ10-INA.
MPSINF     MOVE 'GEB'                 TO YZCWYZ10-INA-PROC.
MPSINF     MOVE 'INA'                 TO YZCWYZ10-INA-COD.
MPSINF     MOVE YZCRYZ01-CODABI       TO YZCWYZ10-INA-ABI.
MPSINF     MOVE YZCRYZ01-TIPO-TERM    TO YZCWYZ10-INA-TERM.
MPSINF     MOVE '00'                  TO YZCWYZ10-INA-LIVELLO.
MPSINF     MOVE SPACE                 TO STCWIODB
MPSINF     MOVE DSTABINQ              TO STCWIODB-SEGMENTO
MPSINF     MOVE '1'                   TO STCWIODB-RIFERIMENTO
MPSINF     MOVE READONLY              TO STCWIODB-FUNZ
MPSINF     MOVE LEN-TAB-VAR           TO STCWIODB-RECLEN
MPSINF     MOVE 'EQ'                  TO STCWIODB-OPERATORE
MPSINF     MOVE YZCWYZ10-INA-KEY      TO STCWIODB-CHIAVE1
MPSINF     MOVE WK-NOTFND             TO STCWIODB-RC-OK (1)
MPSINF     PERFORM MIODB THRU F-MIODB.
MPSINF*----
MPSINF     IF STCWIODB-RC = WK-NOTFND
MPSINF        MOVE ALL 'D'             TO WK-AREA-INA
MPSINF     ELSE
MPSINF        MOVE STCWIODB-AREAIO     TO YZCWYZ10-INA
MPSINF        MOVE YZCWYZ10-INA-AREA-SWITCH TO WK-AREA-INA.
MPSINF
MPSINF     MOVE WK-AREA-INA         TO WK-AREA-INA-ALTA.
MPSINF*-------------------------
MPSINF F-LEGGI-TAB-INA.
MPSINF     EXIT.
MPSINF*==============================================================*
MPSINF* LETTURA DELLA TABELLA ABILITAZIONI INFORMATIVE "BASSA"       *
MPSINF* (CIOE' VALIDA PER IL MENU' INFORMATIVO DEL TERMINALE)        *
MPSINF*==============================================================*
MPSINF LEGGI-TAB-INA-MAPPE.
MPSINF     MOVE SPACE                 TO YZCWYZ10-INA.
MPSINF     MOVE 'GEB'                 TO YZCWYZ10-INA-PROC.
MPSINF     MOVE 'INA'                 TO YZCWYZ10-INA-COD.
MPSINF     MOVE YZCRYZ01-CODABI       TO YZCWYZ10-INA-ABI.
MPSINF     MOVE YZCRYZ01-TIPO-TERM    TO YZCWYZ10-INA-TERM.
MPSINF     MOVE '01'                  TO YZCWYZ10-INA-LIVELLO.
MPSINF     MOVE YZCRYZ01-PROF-MAPPE-COD
MPSINF                                TO YZCWYZ10-INA-MENU-INFO.
MPSINF     MOVE SPACE                 TO STCWIODB
MPSINF     MOVE DSTABINQ              TO STCWIODB-SEGMENTO
MPSINF     MOVE '1'                   TO STCWIODB-RIFERIMENTO
MPSINF     MOVE READONLY              TO STCWIODB-FUNZ
MPSINF     MOVE LEN-TAB-VAR           TO STCWIODB-RECLEN
MPSINF     MOVE 'EQ'                  TO STCWIODB-OPERATORE
MPSINF     MOVE YZCWYZ10-INA-KEY      TO STCWIODB-CHIAVE1
MPSINF     MOVE WK-NOTFND             TO STCWIODB-RC-OK (1)
MPSINF     PERFORM MIODB THRU F-MIODB.
MPSINF*----
MPSINF     IF STCWIODB-RC = WK-NOTFND
MPSINF        MOVE ALL 'D'             TO WK-AREA-INA
MPSINF     ELSE
MPSINF        MOVE STCWIODB-AREAIO     TO YZCWYZ10-INA
MPSINF        MOVE YZCWYZ10-INA-AREA-SWITCH TO WK-AREA-INA.
MPSINF
MPSINF     MOVE WK-AREA-INA         TO WK-AREA-INA-BASSA.
MPSINF*-------------------------
MPSINF F-LEGGI-TAB-INA-MAPPE.
MPSINF     EXIT.
MPSINF*==============================================================*
MPSINF* ROUTINE  TRAMITE LA QUALE SI SOVRAPPONGONO L'AREA ABILITAZIONI
MPSINF* VALIDE PER TUTTA LA BANCA CON QUELLE DEL SINGOLO TERMINALE E SI
MPSINF* CREA UNA AREA RISULTANTE DA MANDARE AL TERM. PER IL BATTESIMO.
MPSINF*==============================================================*
MPSINF* VENGONO "SOVRAPPOSTI" LOGICAMENTE I 2 LIVELLI DI ABILITAZIONI
MPSINF* INFORMATIVI PER OTTENERE IL RISULTATO.  QUEST'ULTIMO ESPRIME
MPSINF* LE INFORMATIVE CHE SONO ABILITATE SIA PER IL SISTEMA CHE PER
MPSINF* IL TERMINALE.
MPSINF*==============================================================*
MPSINF SOVRAPPOSIZIONE.
MPSINF     PERFORM SOVRAPPONI          THRU F-SOVRAPPONI
MPSINF             VARYING WK-IND-SOVRAPP FROM 1 BY 1 UNTIL
MPSINF             WK-IND-SOVRAPP > 99.
MPSINF     MOVE WK-AREA-INA-RISUL      TO WK-AREA-INA.
MPSINF F-SOVRAPPOSIZIONE.
MPSINF     EXIT.
MPSINF*==============================================================*
MPSINF*SE UNA FUNZIONE INFORMATIVA E' DISABILITATA PER TUTTA LA BANCA
MPSINF*(PARTE "ALTA") LA SI DISABILITA ANCHE PER IL SINGOLO TERMINALE|
MPSINF*==============================================================*
MPSINF SOVRAPPONI.
MPSINF     MOVE EL-WK-AREA-INA-ALTA (WK-IND-SOVRAPP) TO WK-EL-1.
MPSINF     MOVE EL-WK-AREA-INA-BASSA(WK-IND-SOVRAPP) TO WK-EL-2.
MPSINF     IF WK-EL-1 NOT = 'A' AND
MPSINF        WK-EL-1 NOT = 'D' AND
MPSINF        WK-EL-1 NOT = 'I' AND
MPSINF        WK-EL-1 NOT = 'M' AND
MPSINF        WK-EL-1 NOT = 'T' AND
MPSINF        WK-EL-1 NOT = 'P' AND
MPSINF        WK-EL-1 NOT = 'C'
MPSINF        MOVE 'D' TO WK-EL-1.
MPSINF     IF WK-EL-2 NOT = 'A' AND
MPSINF        WK-EL-2 NOT = 'D'
MPSINF        MOVE 'D' TO WK-EL-2.
MPSINF
MPSINF     IF WK-EL-1 = 'D'
MPSINF         MOVE WK-EL-1 TO EL-WK-AREA-INA-RISUL(WK-IND-SOVRAPP)
MPSINF     ELSE
MPSINF        IF WK-EL-2 = 'D'
MPSINF          MOVE WK-EL-2 TO EL-WK-AREA-INA-RISUL(WK-IND-SOVRAPP)
MPSINF        ELSE
MPSINF          MOVE WK-EL-1 TO EL-WK-AREA-INA-RISUL(WK-IND-SOVRAPP).
MPSINF
MPSINF F-SOVRAPPONI.
MPSINF     EXIT.
MPSINF
MPSINF ESAME-ABIL-INFORM-AZI.
MPSINF     IF  EL-WK-AREA-INA-RISUL (WK-IND-ESAME) NOT = 'D' AND
MPSINF         EL-WK-AREA-INA-RISUL (WK-IND-ESAME) NOT = 'C'
MPSINF         MOVE '1' TO YZCRA71-PR09
MPSINF         MOVE 100 TO WK-IND-ESAME.
MPSINF F-ESAME-ABIL-INFORM-AZI.
MPSINF     EXIT.
MPSINF ESAME-ABIL-INFORM-CIR.
MPSINF     IF  EL-WK-AREA-INA-RISUL (WK-IND-ESAME) NOT = 'D' AND
MPSINF         EL-WK-AREA-INA-RISUL (WK-IND-ESAME) NOT = 'I' AND
MPSINF         EL-WK-AREA-INA-RISUL (WK-IND-ESAME) NOT = 'M' AND
MPSINF         EL-WK-AREA-INA-RISUL (WK-IND-ESAME) NOT = 'T' AND
MPSINF         EL-WK-AREA-INA-RISUL (WK-IND-ESAME) NOT = 'P'
MPSINF         MOVE '1' TO YZCRA71-PR09
CRT==>*==> ADORNI NCR 10/06/93
CRT==>*        MOVE '2' TO YZCRA71-PR09
CRT==>*==> ADORNI NCR 10/06/93
MPSINF         MOVE 100 TO WK-IND-ESAME.
MPSINF F-ESAME-ABIL-INFORM-CIR.
MPSINF     EXIT.
      *-----------------------------------------------------------------
      * LETTURA DEL RECORD CONTENETE LO STATO GENERALE DELLE INFORMATIVE
      * - IN CASO SIA DISABILITATO O IN CASO L'ORA DELL'OPERAZIONE NON
      * SIA COMPRESA NEL "RANGE" STABILITO DISABILITIAMO IL PROF. 9
      *-----------------------------------------------------------------
       LEGGI-TAB-STG.
           MOVE ZERO                  TO SW-STG-NON-OK.
           MOVE SPACE                 TO YZCWYZ10-STG.
           MOVE 'GEB'                 TO YZCWYZ10-STG-PROC.
           MOVE 'STG'                 TO YZCWYZ10-STG-COD.
           MOVE YZCRYZ01-TIPO-TERM    TO YZCWYZ10-STG-TIPO.
           MOVE ZERO                  TO YZCWYZ10-STG-CODICE-FUN.
           MOVE SPACE                 TO STCWIODB
           MOVE DSTABINQ              TO STCWIODB-SEGMENTO
           MOVE 'ST'                  TO STCWIODB-RIFERIMENTO
           MOVE READONLY              TO STCWIODB-FUNZ
           MOVE LEN-TAB-VAR           TO STCWIODB-RECLEN
           MOVE 'EQ'                  TO STCWIODB-OPERATORE
           MOVE YZCWYZ10-STG-KEY      TO STCWIODB-CHIAVE1
           MOVE WK-NOTFND             TO STCWIODB-RC-OK (1)
           PERFORM MIODB THRU F-MIODB.
      *----
           IF STCWIODB-RC = WK-NOTFND
              MOVE '1'     TO SW-STG-NON-OK
              PERFORM ERRORE-LETTURA-TAB-STG THRU
                      F-ERRORE-LETTURA-TAB-STG
              GO TO F-LEGGI-TAB-STG.

           MOVE STCWIODB-AREAIO          TO YZCWYZ10-STG.
           IF YZCWYZ10-STG-STATO NOT = '1'
              MOVE '1'     TO SW-STG-NON-OK
              GO TO F-LEGGI-TAB-STG.
           IF YZCWYZ10-STG-ORADA  > COMMTIME-HHMM OR
              YZCWYZ10-STG-ORAA   < COMMTIME-HHMM
              MOVE '1' TO SW-STG-NON-OK
              GO TO F-LEGGI-TAB-STG.
       F-LEGGI-TAB-STG.
           EXIT.
       ERRORE-LETTURA-TAB-STG.
           MOVE 23                TO STCW196-RIFERIMENTO
           MOVE 00023             TO YZCWYZ05-RIFERIMENTO
           PERFORM SEGNALA-ERRORI THRU F-SEGNALA-ERRORI.
       F-ERRORE-LETTURA-TAB-STG.
           EXIT.
OLCA1 *==============================================================*
OLCA1 *   VERIFICA DELLA PRESENZA DEL TERMINALE SULLA TABELLA OLTE   *
OLCA1 *==============================================================*
OLCA1      COPY YZCPOL14.
200694
200694 IMPOSTA-DATA-CON-SECOLO.
200694
200694     MOVE  WK-AAMMGG-A       TO  WK-SSAAMMGG-AAMMGG.
200694     IF    WK-AA-A           <   80
200694           MOVE   20         TO  WK-SSAAMMGG-SS
200694     ELSE
200694           MOVE   19         TO  WK-SSAAMMGG-SS.
200694
200694     MOVE  YZCRA70-SCAD      TO  WK-SCAD-SSAAMM-AAMM
200694     IF    WK-SCAD-SSAAMM-AA <   80
200694           MOVE   20         TO  WK-SCAD-SSAAMM-SS
200694     ELSE
200694           MOVE   19         TO  WK-SCAD-SSAAMM-SS.
200694
200694 F-IMPOSTA-DATA-CON-SECOLO.
200694     EXIT.
OLCA2  RICOSTRUISCI-X71-X-ANOMALIA.
OLCA2      COPY YZCPOL56.
SP0006*================================================================*
SP0006 GESTIONE-CAMBI.
SP0006     IF YZCRA71-PR01 > 1
SP0006        IF NOT YZTCA70-01-PGM-PASSO-NF
SP0006           ADD YZTCA70-01-LEN-VAL-A71      TO WK-LUNGH-A71
SP0006        ELSE
SP0006           ADD +63                         TO WK-LUNGH-A71
SP0006           .
SP0006 F-GESTIONE-CAMBI.
SP0006     EXIT.
SP0006*================================================================*
SP0006 GESTIONE-PROFILO.
SP0006     IF YZCRYZ01-TIPO-TERM NOT = 8
SP0006        IF NOT YZTCA70-01-PGM-PASSO-NF
SP0006           IF YZTCA70-01-PR01-DA-RICOPRIRE
SA0053            IF YZCRA71-PR01 > YZTCA70-01-PR01
SP0006              MOVE YZTCA70-01-PR01         TO YZCRA71-PR01
SP0006              .
SP0006     IF NOT YZTCA70-01-PGM-PASSO-NF
SP0006        IF YZTCA70-01-CNTL-ENELTEL-SI
SP0006           IF WYZ20-ABIL-ENELTEL-NO
SP0006              MOVE ZEROES                  TO YZCRA71-PR05
SP0006              .
SI0092*----------------------> SE AUTORIZZAZIONE IN POOL
SI0092*----------------------> SE RECIPROCITA' SELETTIVA TRA ISTITUTI
SI0092     IF COMM-SW-FALSO-AZIENDALE = 1
SI0092        IF WYZ20-RECIPROCITA
SI0092           PERFORM GESTIONE-PROFILO-LOOP
SI0092           THRU  F-GESTIONE-PROFILO-LOOP
SI0092           VARYING WK-IND FROM 1 BY 1
SI0092           UNTIL   WK-IND > 10
SI0092     .
SI0179*----------------------> SE AUTORIZZAZIONE IN POOL
SI0179*----------------------> SE RECIPROCITA' SELETTIVA TRA ISTITUTI
SI0179*----------------------> SE FUORI ORARIO
SI0179     IF COMM-SW-FALSO-AZIENDALE = 1
SI0179        IF WYZ20-RECIPROCITA
SI0179           IF COMMTIME-HHMM < YZCWYZ10-RCP-POOL-ORA-DA-PREL
SI0179           OR COMMTIME-HHMM > YZCWYZ10-RCP-POOL-ORA-A-PREL
SI0179              MOVE ZEROES                  TO YZCRA71-PR01
SI0179     .
POSTE1     IF YZCWYZ20-STATO-OLCA NOT = '1'
POSTE1        MOVE ZEROES                TO YZCRA71-PR05
POSTE1     .
SI0491*---  CONTROLLO DELLO STATO GENERALE DEL SISTEMA PAGAMENTO UTENZE
SI0491     PERFORM CNTL-TAB-STATO-UTENZE
SI0491      THRU F-CNTL-TAB-STATO-UTENZE
SI0491     .
SI0491     IF STATO-UTENZE-KO
SI0491        MOVE ZEROES                TO YZCRA71-PR05
SI0491     .
SP0006 F-GESTIONE-PROFILO.
SP0006     EXIT.
SI0092*================================================================*
SI0092 GESTIONE-PROFILO-LOOP.
SI0092     IF YZCRA71-PRXX (WK-IND) > YZCWYZ10-RCP-POOL-PRXX (WK-IND)
SI0092        MOVE YZCWYZ10-RCP-POOL-PRXX (WK-IND)
SI0092          TO YZCRA71-PRXX (WK-IND)
SI0092     .
SI0092 F-GESTIONE-PROFILO-LOOP.
SI0092     EXIT.
SP0006*================================================================*
SP0006 GESTIONE-NOME.
SP0006     IF YZTCA70-01-PGM-PASSO-NF
SP0006     OR NOT YZTCA70-01-NOME-A71-SI
SP0006        GO TO F-GESTIONE-NOME
SP0006        .
SP0006     ADD  YZTCA70-01-LEN-NOME-A71        TO WK-LUNGH-A71
SP0006     MOVE YZTCA70-01-ANOM-NOME-A71       TO COMM-ANOMA-RICH
SP0006     .
SP0006     IF YZTCA70-01-NOME-A71-CENTR-SI
SP0006        MOVE YZTCA70-01-LEN-NOME-A71     TO WK080LNG
SP0006        MOVE YZCRPOSI-NOME               TO WK080INP
SP0006        PERFORM M080                     THRU F-M080
SP0006        MOVE WK080OUT                    TO WK-NOME
SP0006     ELSE
SP0006        MOVE YZCRPOSI-NOME               TO WK-NOME
SP0006        .
SP0006     IF YZCRYZ01-TIPO-TERM NOT = 8
SP0006        MOVE WK-NOME                     TO YZCRA71-AREA-ATM5-NOME
SP0006     ELSE
SP0006        IF YZCRA71-PR01 > 1
SP0006           MOVE WK-NOME                  TO YZCRA71-AREA-ATM4-NOME
SP0006        ELSE
SP0006           MOVE WK-NOME                  TO YZCRA71-AREA-ATM5-NOME
SP0006           .
SP0006 F-GESTIONE-NOME.
SP0006     EXIT.
SP0006*================================================================*
SP0006 M080.
SP0006     COPY  YYCP0080.
SP0006*================================================================*
SP0006 EL-PASSO-DEC.
SP0006     COPY YZCPEXIT.
SP0006*
SI0175*---------> MODIFICA PER LEGGERE UN RECORD GENERICO SULLA TABELLA
SI0175*---------> EXIT (DA INSERIRE SE VI E' LA NECESSITA ANCHE SULLE
SI0175*---------> GESTIONI DELLA TABELLA EXIT EFFETTUATE IN ALTRI PGM)
SI0175     IF STCWIODB-RC = WK-NOTFND
SI0175        MOVE SPACE              TO YZCWEXIT-ABI-MITT-X
SI0175     COPY YZCPEXIT.
SI0175     .
SP0006     IF STCWIODB-RC = WK-NOTFND
SP0006        MOVE 'NF'                        TO YZTCA70-01-PGM-PASSO
SP0006     ELSE
SP0006        IF YZCWEXIT-PGM-PASSO-01
SP0006           MOVE STCWIODB-AREAIO          TO YZTCA70-01
SP0006           .
SP0006 F-EL-PASSO-DEC.
SP0006     EXIT.
SP0006*================================================================*
SP0006 GESTIONE-MESSAGGIO.
SP0006     IF  YZCRYZ01-TIPO-TERM = 8
SP0006     AND YZCRA71-PR01 > 1
SP0006         IF YZTCA70-01-NOME-A71-SI
SI0822*           IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*              YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905            IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822               MOVE WK-COMODO-FLAG    TO YZCRA71-FLAG-NR-4
SI0822               MOVE WK-COMODO-TRACCIA TO YZCRA71-IITRACCIA-4
SI0831               MOVE '4'               TO WK-QUALE-TRACCIA
SI0822               MOVE COMM-MESSAGGIO   TO YZCRA71-AREA-ATM4-MSG-1-NR
SI0822               MOVE COMM-MESSAGGIO-2 TO YZCRA71-AREA-ATM4-MSG-2-NR
SI0822            ELSE
SP0006            MOVE COMM-MESSAGGIO   TO YZCRA71-AREA-ATM4-MSG-1
SP0006            MOVE COMM-MESSAGGIO-2 TO YZCRA71-AREA-ATM4-MSG-2
SI0822            END-IF
SP0006         ELSE
SI0822*           IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*              YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905            IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822               MOVE WK-COMODO-FLAG    TO YZCRA71-FLAG-NR-2
SI0822               MOVE WK-COMODO-TRACCIA TO YZCRA71-IITRACCIA-2
SI0831               MOVE '2'               TO WK-QUALE-TRACCIA
SI0822               MOVE COMM-MESSAGGIO   TO YZCRA71-AREA-ATM2-MSG-1-NR
SI0822               MOVE COMM-MESSAGGIO-2 TO YZCRA71-AREA-ATM2-MSG-2-NR
SI0822            ELSE
SP0006*           MOVE COMM-MESSAGGIO   TO YZCRA71-VAL-MES-ATM
POSTE *---  ASTERISCATO LA PRECEDENTE
POSTE             MOVE COMM-MESSAGGIO   TO YZCRA71-AREA-ATM2-MSG-1
POSTE             MOVE COMM-MESSAGGIO-2 TO YZCRA71-AREA-ATM2-MSG-2
SI0822            END-IF
SP0006     ELSE
SP0006         IF YZTCA70-01-NOME-A71-SI
SI0822*           IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*              YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905            IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822               MOVE WK-COMODO-FLAG    TO YZCRA71-FLAG-NR-5
SI0822               MOVE WK-COMODO-TRACCIA TO YZCRA71-IITRACCIA-5
SI0831               MOVE '5'               TO WK-QUALE-TRACCIA
SI0822               MOVE COMM-MESSAGGIO   TO YZCRA71-AREA-ATM5-MSG-1-NR
SI0822               MOVE COMM-MESSAGGIO-2 TO YZCRA71-AREA-ATM5-MSG-2-NR
SI0822            ELSE
SP0006            MOVE COMM-MESSAGGIO   TO YZCRA71-AREA-ATM5-MSG-1
SP0006            MOVE COMM-MESSAGGIO-2 TO YZCRA71-AREA-ATM5-MSG-2
SI0822            END-IF
SP0006         ELSE
SI0822*           IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*              YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905            IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822               MOVE WK-COMODO-FLAG     TO YZCRA71-FLAG-NR-3
SI0822               MOVE WK-COMODO-TRACCIA  TO YZCRA71-IITRACCIA-3
SI0831               MOVE '3'               TO WK-QUALE-TRACCIA
SI0822               MOVE COMM-MESSAGGIO   TO YZCRA71-AREA-ATM3-MSG-1-NR
SI0822               MOVE COMM-MESSAGGIO-2 TO YZCRA71-AREA-ATM3-MSG-2-NR
SI0822            ELSE
SP0006*           MOVE COMM-MESSAGGIO   TO YZCRA71-SOLO-MES-ATM
POSTE *---  ASTERISCATO LA PRECEDENTE
POSTE             MOVE COMM-MESSAGGIO   TO YZCRA71-AREA-ATM3-MSG-1
POSTE             MOVE COMM-MESSAGGIO-2 TO YZCRA71-AREA-ATM3-MSG-2
SI0822            END-IF
SP0006            .
SP0006     MOVE COMM-MESS-ANOM          TO COMM-ANOMA-RICH
SP0006     .
SP0006     ADD  YZTCA70-01-LEN-MSG-A71  TO WK-LUNGH-A71
SI0116     MOVE YZTCA70-01-LEN-MSG-A71  TO YZCRYZ01-LEN-MSG
SP0006     .
SI0822*    IF YZCRA70-FLAG-AGGIORNA = '0' OR
SI0822*       YZCRA70-FLAG-AGGIORNA = '1'
SI0905*---  Asteriscato le due righe precedenti
SI0905     IF YZCRA70-FLAG-AGGIORNA > SPACES
SI0822*       ADD  40                    TO WK-LUNGH-A71
SA0889*---  Asteriscata la precedente
SA0889        ADD  41                    TO WK-LUNGH-A71
SI0822        ADD  41                    TO YZCRYZ01-LEN-MSG
SI0822        ADD  41                    TO LINK-RISPOSTA-LUNG
SI0822     .
SP0006 F-GESTIONE-MESSAGGIO.
SP0006     EXIT.
SI0088*================================================================*
SI0088 GESTIONE-MAX-INT.
SI0092*----------------------> SE AUTORIZZAZIONE IN POOL
SI0092*----------------------> SE RECIPROCITA' SELETTIVA TRA ISTITUTI
SI0092*    IF COMM-SW-FALSO-AZIENDALE = 1
SI0092*       IF WYZ20-RECIPROCITA
SI0092*          IF WYZ10-RCP-POOL-MAX-INT-NO
SI0092*             GO TO F-GESTIONE-MAX-INT
SI0092*    .
SI0179*ASTERISCATE LE PRECEDENTI 5
SI0088*----------------------> SE DISPONIBILITA' CARTA
SI0417*----------------------> E NON MASSIMALI UNICI BANDA + CHIP
SI0601*----------------------> E NON PREPAGATA CON SISTEMA IN OLI
SI0088*----------------------> ESCE SENZA FAR NULLA
SI0601     IF COMM-ABI-CARTA  =  COMM-ABI-TERM AND
SI0601        YZCRA70-TIPORAP = '9'            AND
SI0601        YZCRA70-RESTROP = '8'            AND
SI0601        WYZ10-ABD-AUT-PREP-OLI
SI0601        CONTINUE
SI0601     ELSE
SI0417     IF WYZ10-ABD-MAX-BANDA-CHIP-SI AND RPOSI-CHIP-SI
SI0417        CONTINUE
SI0417     ELSE
SI0088     IF   YZCRPOSI-DISPON = ZEROES
SI0088          GO TO F-GESTIONE-MAX-INT
SI0088          .
SI0088*    MOVE YZCRA71-SALDO           TO COMM-SALDO-S
SI0088*    MOVE YZCRA71-DATA            TO COMM-DATASD
SI0117*ASTERISCATE LE PRECEDENTI 2
SI0117     MOVE YZCRANA-SEGNO-SALDO-PREL TO COMM-SEGNO
SI0117     MOVE YZCRANA-SALDO-PREL       TO COMM-SD
SI0117     MOVE YZCRANA-DATA-SALDO-PREL  TO COMM-DATASD
SI0088     .
SI0601     IF COMM-ABI-CARTA  =  COMM-ABI-TERM AND
SI0601        YZCRA70-TIPORAP = '9'            AND
SI0601        YZCRA70-RESTROP = '8'            AND
SI0601        WYZ10-ABD-AUT-PREP-OLI
SI0601        MOVE 'A70'                TO COMM-TIPO-RICH
SI0601        MOVE 202                  TO COMM-FUNZ-RICH
SI0601     .
SI0417     IF WYZ10-ABD-MAX-BANDA-CHIP-SI AND RPOSI-CHIP-SI
SI0417        MOVE 'A70'                TO COMM-TIPO-RICH
SI0417        MOVE 102                  TO COMM-FUNZ-RICH
SI0417     .
SI0088     MOVE 'YZTCGB06'              TO WKPGMSUC
SI0088     .
SI0088     PERFORM CHIAMA-ALTRO-PROGRAMMA
SI0088     THRU  F-CHIAMA-ALTRO-PROGRAMMA
SI0088     .
SI0088*----------------------> ATTUALIZZA AREA PER UTILIZZO
SI0088*----------------------> SUCCESSIVO
SI0088     MOVE COMM-IMPORTO-AUTOR-2    TO COMM-IMPORTO-AUTOR-1
R16507                                     WS-DISP-PP
SI0088     .
SI0143     IF  NOT  YZCRPOSI-COD-DIV-CONTO-EURO
SI0088     IF   COMM-IMPORTO-AUTOR-1 (11:5) < 50000
SI0088          MOVE ZEROES             TO COMM-IMPORTO-AUTOR-1 (11:5)
SI0088     ELSE
SI0088          MOVE 50000              TO COMM-IMPORTO-AUTOR-1 (11:5)
SI0088          .
SI0143     IF  YZCRPOSI-COD-DIV-CONTO-EURO
SI0143*        IF   COMM-IMPORTO-AUTOR-1 (13:2) < 20
SA0131* ASTERISCATA LA PRECEDENTE
SA0131         IF   COMM-IMPORTO-AUTOR-1 (14:2) < 20
SA0398* ASTERISCATA LA PRECEDENTE
SA0398         IF   COMM-IMPORTO-AUTOR-1 (14:2) < 10
SI0143*             MOVE ZEROES        TO COMM-IMPORTO-AUTOR-1 (13:2)
SA0147* ASTERISCATA LA PRECEDENTE
SA0147              MOVE ZEROES        TO COMM-IMPORTO-AUTOR-1 (14:2)
SI0143          .
SI0179*----------------------> SE AUTORIZZAZIONE IN POOL
SI0179*----------------------> SE RECIPROCITA' SELETTIVA TRA ISTITUTI
SI0695     IF WYZ10-ABD-MAX-BANDA-CHIP-SI AND RPOSI-CHIP-SI
SI0695        NEXT SENTENCE
SI0695     ELSE
SI0179     IF COMM-SW-FALSO-AZIENDALE = 1
SI0179        IF WYZ20-RECIPROCITA
SI0179*----------------------> SE NON ABILITATO IN RECIPROCITA'
SI0179           IF WYZ10-RCP-POOL-MAX-INT-NO
SI0179*---------------------->  O
SI0179*----------------------> SE ABILITATO IN RECIPROCITA'
SI0179*---------------------->  E CARTA ABILITATA MAX INTEGRATI
SI0179*---------------------->  E ATM NON ABILITATO MAX INTEGRATI
SI0179*---------------------->   (VEDI ANCHE YZCPOL51)
SI0179           OR (YZCRPOSI-DISPON = 5
SI0179           AND TKABD-SW-ATM-FLAG-8-NO)
SI0179           OR (YZCRPOSI-DISPON = 6
SI0179           AND TKABD-SW-ATM-FLAG-8-NO)
SI0179              MOVE ZEROES        TO COMM-IMPORTO-AUTOR-1
SI0179           ELSE
SI0179           IF YZCRPOSI-COD-DIV-CONTO-EURO
SI0179              IF COMM-IMPORTO-AUTOR-1 > 250
SI0179                 MOVE 250        TO COMM-IMPORTO-AUTOR-1
SI0179              END-IF
SI0179           ELSE
SI0179              IF COMM-IMPORTO-AUTOR-1 > 500000
SI0179                 MOVE 500000     TO COMM-IMPORTO-AUTOR-1
SI0179              END-IF
SI0179     .
SI0088 F-GESTIONE-MAX-INT.
SI0088     EXIT.
POSTE *================================================================*
POSTE *  PRENOTA L'IMPORTO DELLA DISPONIBILITA' SUL CONTO CORRENTE PER *
POSTE * FARE IN MODO DI NON ANDARE SOTTO SUL CONTO NEL CASO DI PRELIE- *
POSTE * VI SIMULTANEI DI PIU' CARTE SULLO STESSO CONTO.                *
POSTE *================================================================*
POSTE  PRENOTA-DISPONIBILITA.
POSTE
POSTE      MOVE YZCRYZ01-TIPO-TERM       TO YZCRANA-TIPOSA
POSTE      MOVE 'END'                    TO YZCRANA-COD-MESSAGGIO
YOUNG      IF YZCRPOSI-TIPORAP = 1
YOUNG         MOVE 'DR'                  TO YZCRANA-SERVIZIO
YOUNG      ELSE
POSTE      MOVE 'CC'                     TO YZCRANA-SERVIZIO
YOUNG      .
POSTE      MOVE ZERO                     TO YZCRANA-ZONA-SOTTOFUNZIONI
POSTE      MOVE ZERO                     TO YZCRANA-SOTTOFUNZ(10)
POSTE      MOVE ZERO                     TO YZCRANA-LIVELLO-MENU
POSTE      MOVE ZERO                     TO YZCRANA-RC
POSTE      MOVE ZERO                     TO YZCRANA-ANOM
POSTE      MOVE ZERO                     TO YZCRANA-RC-RISPOSTA
POSTE      MOVE ZERO                     TO YZCRANA-ANOM-RISPOSTA
POSTE      MOVE YZCRA71-NUMMES           TO YZCRANA-NTRANS
POSTE      MOVE YZCRYZ01-SEDE-INSTAL(4:2)
POSTE                                    TO YZCRANA-FILIALE-SA(1:2)
POSTE      MOVE YZCRYZ01-DIPEND(2:3)     TO YZCRANA-FILIALE-SA(3:3)
POSTE      MOVE YZCRA71-CODATM           TO YZCRANA-NSA
POSTE      MOVE YZCRYZ01-TERMCICS        TO YZCRANA-TERMID
POSTE      MOVE YZCRA71-DATAMES          TO YZCRANA-DATARICH
POSTE      MOVE YZCRA71-ORAMES           TO YZCRANA-ORARICH-HHMM
POSTE      MOVE ZERO                     TO YZCRANA-ORARICH-SS
POSTE      MOVE YZCRYZ01-MARCA           TO YZCRANA-MARCA
POSTE      MOVE YZCRPOSI-CARTA           TO YZCRANA-NUMERO-CARTA
POSTE      MOVE YZCRA70-PAN              TO YZCRANA-PAN
POSTE      MOVE ZERO                     TO YZCRANA-TOT-MSG
POSTE      MOVE ZERO                     TO YZCRANA-PROGR-MSG
POSTE      MOVE YZCRPOSI-COD-DIV-CONTO   TO YZCRANA-COD-DIV-SALDO-PREL
POSTE      MOVE YZCRPOSI-SALDO-S         TO YZCRANA-SALDO-POSI
POSTE      MOVE YZCRPOSI-DATASD          TO YZCRANA-DATASD-POSI
POSTE *    MOVE COMM-IMPORTO-AUTOR-1     TO YZCRA71-DISP
BALDAX*---  ASTERISCATO LA PRECEDENTE
POSTE      MOVE YZCRA71                  TO YZCRANA-TRANS-CHIAM
POSTE      MOVE YZCRPOSI-AGENZIA         TO YZCRANA-CARTA-FILIALE
POSTE      MOVE YZCRPOSI-CONTO           TO YZCRANA-CARTA-CONTO
POSTE      MOVE YZCRYZ01-CODABI          TO YZCRANA-CODABI-TERM
POSTE *----
POSTE      MOVE +6500                    TO LINKLEN
POSTE      MOVE YZCRANA                  TO LINKAREA
POSTE      MOVE 'YZTCANA'                TO LINKPGM
POSTE *----
POSTE      PERFORM MLINK                 THRU F-MLINK.
POSTE
POSTE      MOVE LINKAREA                 TO YZCRANA.
POSTE
POSTE      IF YZCRANA-RC-RISPOSTA NOT = ZERO
R16104     AND YZCRANA-RC-RISPOSTA NOT = 3
R16104     AND YZCRANA-RC-RISPOSTA NOT = 4
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 5
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 6
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 7
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 'A'
SP0359     AND YZCRANA-RC-RISPOSTA NOT = 'C'
POSTE         MOVE ZERO                  TO COMM-IMPORTO-AUTOR-1
POSTE         MOVE ZERO                  TO YZCRA71-DISP
SP0359        MOVE SPACES                TO YZCRYZ01-ULT-NUMMOVI-CC
POSTE         MOVE ZERO                  TO YZCRA71-PR01
POSTE         MOVE YZCRA71               TO LINK-RISPOSTA-DATI
POSTE         MOVE 'PD'                  TO STCW196-RIFERIMENTO
POSTE         PERFORM SEGNALA-ERRORE-TCANA
POSTE          THRU F-SEGNALA-ERRORE-TCANA
POSTE         GO TO F-PRENOTA-DISPONIBILITA
POSTE      .
R16104     IF YZCRANA-RC-RISPOSTA = 3
R16104        MOVE  '15'                 TO YZCRA71-ANOM
R16104        MOVE ZERO                  TO YZCRA71-DISP
SP0359        MOVE SPACES                TO YZCRYZ01-ULT-NUMMOVI-CC
R16104        MOVE 3                     TO YZCRA71-AZIONE
R16104        MOVE YZCRA71               TO LINK-RISPOSTA-DATI
R16104        MOVE 'NO'                  TO WK-PKC-DA-INVIARE
R16104        MOVE 'KO'                  TO COMM-ESITO-RICH
R16104        MOVE 'NO'                  TO WK-RISCRITTURA
R16104        MOVE 1                     TO SW-ERRORE
R16104        GO TO F-PRENOTA-DISPONIBILITA
R16104     .
R16104*    IF YZCRANA-RC-RISPOSTA = 4
R16104*       MOVE ZERO                  TO YZCRA71-PR03
R16104*       MOVE ZERO                  TO YZCRA71-PR04
R16104*       MOVE YZCRA71               TO LINK-RISPOSTA-DATI
R16104*    .
SP0359*---  Asteriscate le cinque righe precedenti
SP0359     PERFORM VERIFICA-RESTROP-CC  THRU F-VERIFICA-RESTROP
SP0359     .
SP0359     MOVE YZCRA71                  TO LINK-RISPOSTA-DATI
SP0359     .
POSTE      MOVE YZCRANA-NUMMOVI-CC       TO YZCRYZ01-ULT-NUMMOVI-CC
POSTE      .
POSTE  F-PRENOTA-DISPONIBILITA.
POSTE      EXIT.
SI0143*================================================================*
SI0143*--  SE CODICE DIVISA DEL CONTO CARTA E' IN EURO SI IMPOSTA IL
SI0143*--  PRIMO BYTE DELLA DISPONIBILITA' HOST E DEL SALDO A 'E'
SI0143*================================================================*
SI0143 IMPOSTA-DIVISA-X-DISP-SALDO.
SI0143*    IF  NOT  YZCRPOSI-COD-DIV-CONTO-EURO
SI0143*     OR NOT  PKC-DA-INVIARE
SI0143*        GO TO  F-IMPOSTA-DIVISA-X-DISP-SALDO
SI0143*    .
SA0076* ASTERISCATE LE 4 PRECEDENTI
SA0076     IF COMM-ABI-CARTA NOT = COMM-ABI-TERM OR
SA0076        YZCRA70-STATO  NOT = ZEROES
SA0076        GO TO F-IMPOSTA-DIVISA-X-DISP-SALDO
SA0076     .
SA0076     IF YZCRPOSI-COD-DIV-CONTO-EURO
SA0076        IF YZCRYZ01-SW-COMPATIBILE-EURO   AND
SA0076           YZCWYZ20-GEN-E2-DATA-INIZ-DUAL NOT > COMMDAY2
SA0076           NEXT SENTENCE
SA0076        ELSE
SA0076           COMPUTE YZCRA71-DISP  =
SA0076                   YZCRA71-DISP  * YZCWYZ20-GEN-E2-TASSO-CONV
SA0076           COMPUTE COMM-RES-MENS =
SA0076                   COMM-RES-MENS * YZCWYZ20-GEN-E2-TASSO-CONV
SA0076           COMPUTE COMM-RES-GIOR =
SA0076                   COMM-RES-GIOR * YZCWYZ20-GEN-E2-TASSO-CONV
SA0076           MOVE YZCRA71-SALDO            TO WK-SALDO-12
SA0076           COMPUTE WK-SALDO-11   =
SA0096*--- ASTERISCATA LA SUCCESSIVA
SA0076*                  WK-SALDO-11   * YZCWYZ20-GEN-E2-TASSO-CONV
SA0096                   WK-SALDO-11-E * YZCWYZ20-GEN-E2-TASSO-CONVR
SA0076           MOVE WK-SALDO-12              TO YZCRA71-SALDO
SA0076           MOVE YZCRA71                  TO LINK-RISPOSTA-DATI
SA0076           GO TO F-IMPOSTA-DIVISA-X-DISP-SALDO
SA0076     ELSE
SA0076        GO TO F-IMPOSTA-DIVISA-X-DISP-SALDO
SA0076     .
SI0821     MOVE YZCRA71-DISP-X(2:6) TO  YZCRYZ01-DISPON-A71
SI0143     MOVE 'E'                 TO  YZCRA71-DISP-X (1:1)
SI0143     MOVE 'E'                 TO  YZCRA71-SALDO  (1:1)
SI0143     .
SA0076     MOVE YZCRA71              TO LINK-RISPOSTA-DATI.
SI0143
SI0143 F-IMPOSTA-DIVISA-X-DISP-SALDO.
SI0143     EXIT.
SI0196*==============================================================*
SI0196*==============================================================*
SI0196*==============================================================*
SI0196 TEST-PER-VERSAMENTO-EURO.
SI0196*---
SI0196*--- SE ATM NON EURO COMPATIBILE
SI0196*---    SE LA CARTA A VERSAMENTO IN SOLO-EURO / LIRE-EURO
SI0196*---       ABBASSO L'ABILITAZIONE A SOLO-LIRE
SI0196*---       PERCHE' L'ATM NON CAPIREBBE IL FLAG-VERS A '2' O '3'
SI0196*---
SI0196     IF YZCRYZ01-SW-COMPATIBILE-EURO
SI0196        CONTINUE
SI0196     ELSE
SI0196        IF RPOSI-VERSAM-SI-EUR
SI0196        OR RPOSI-VERSAM-SI-LIT-EUR
SI0196           MOVE '1'                   TO YZCRA71-PR02
SI0196        END-IF
SI0196        GO TO F-TEST-PER-VERSAMENTO-EURO
SI0196     END-IF
SI0196*---
SI0196*--- ATM EURO COMPATIBILE
SI0196*---
SI0196*--- SE LA CARTA A VERSAMENTO A 'NO'
SI0196*---    ESCO DALLA ROUTINE
SI0196*---
SI0196     IF RPOSI-VERSAM-NO
SI0196        GO TO F-TEST-PER-VERSAMENTO-EURO
SI0196     END-IF
SI0196*---
SI0196*--- SE LA CARTA A VERSAMENTO IN SOLO-EURO
SI0196*---    ESCO DALLA ROUTINE
SI0196*---
SI0196     IF RPOSI-VERSAM-SI-EUR
SI0196        GO TO F-TEST-PER-VERSAMENTO-EURO
SI0196     END-IF
SI0196*---
SI0196*--- SE LA CARTA A VERSAMENTO IN SOLO-LIRE
SI0196*---    ALZO L'ABILITAZIONE A LIRE-EURO
SI0196*---
SI0196     IF RPOSI-VERSAM-SI-LIT
SI0196        MOVE '2'                      TO YZCRA71-PR02
SI0196*       MOVE '2'                      TO YZCRPOSI-VERSAM-X
SI0196     END-IF
SI0196*---
SI0196*--- SE LA CARTA A VERSAMENTO IN LIRE-EURO
SI0196*---    SE LA DATA SISTEMA MAGGIORE DELLA DATA DI FINE LIRE
SI0196*---       ALZO L'ABILITAZIONE A SOLO-EURO
SI0196*---
SI0196     IF RPOSI-VERSAM-SI-LIT-EUR
SI0196        IF COMMDAY2 > YZCWYZ20-GEN-E2-DATA-FINE-LIRE
SI0196           MOVE '3'                   TO YZCRA71-PR02
SI0196*          MOVE '3'                   TO YZCRPOSI-VERSAM-X
SI0196        END-IF
SI0196     END-IF
SI0196     .
SI0196 F-TEST-PER-VERSAMENTO-EURO.
SI0196     EXIT.
POSTE *==============================================================*
POSTE *  SCRIVE IL LOG ERRORI CON IL MESSAGGIO PASSATO DA YZTCANA    *
POSTE *==============================================================*
POSTE  SEGNALA-ERRORE-TCANA.
POSTE *
POSTE      IF YZCRANA-RC-RISPOSTA = 2
R16104     OR YZCRANA-RC-RISPOSTA = 3
POSTE         MOVE 'NCAB'             TO STCW196-PGABCODE
POSTE      ELSE
POSTE         MOVE SPACES             TO STCW196-PGABCODE
POSTE      .
POSTE      MOVE SPACES                TO YZCWYZ05-CHIARO
POSTE      MOVE 'YZTCANA'             TO YZCWYZ05-C-PROGRAMMA
POSTE      MOVE '99999'               TO YZCWYZ05-C-RIFERIMENTO
POSTE      MOVE YZCRANA-RIGA(1)       TO YZCWYZ05-C-DESCRIZIONE
POSTE      MOVE YZCWYZ05-CHIARO       TO STCW196-MSG
POSTE      .
POSTE      PERFORM SCRIVI-LOG-ERRORI  THRU F-SCRIVI-LOG-ERRORI
POSTE      .
POSTE  F-SEGNALA-ERRORE-TCANA.
POSTE      EXIT.
SI0245*----------------------------------------------------------------*
SI0245*  CONTROLLO STATO CASSETTI ATM (SU ARCHIVIO TERMINALI)
SI0245*  SE RISULTA CHE NESSUN CASSETTO HA BANCONOTE CARICATE O CHE
SI0245*  ALMENO UN CASSETTO HA BANCONOTE CARICATE MINORE DI BANCONOTE
SI0245*  EROGATE NON ABILITO IL FLAG DI PRELIEVO.
SI0245*----------------------------------------------------------------*
SI0245 CONTROLLA-CASSETTI-ATM.
SI0245
SI0245     IF  YZCRYZ01-BANCAR1 = ZERO
SI0245     AND YZCRYZ01-BANCAR2 = ZERO
SI0245     AND YZCRYZ01-BANCAR3 = ZERO
SI0245     AND YZCRYZ01-BANCAR4 = ZERO
SI0245     AND YZCRYZ01-BANCAR5 = ZERO
SI0245     AND YZCRYZ01-BANCAR6 = ZERO
SI0245         MOVE ZERO TO YZCRA71-PR01
SI0245         GO TO F-CONTROLLA-CASSETTI-ATM
SI0245         .
SI0245
SI0245     IF  (YZCRYZ01-BANCAR1 < YZCRYZ01-BANEROG1)
SI0245     OR  (YZCRYZ01-BANCAR2 < YZCRYZ01-BANEROG2)
SI0245     OR  (YZCRYZ01-BANCAR3 < YZCRYZ01-BANEROG3)
SI0245     OR  (YZCRYZ01-BANCAR4 < YZCRYZ01-BANEROG4)
SI0245     OR  (YZCRYZ01-BANCAR5 < YZCRYZ01-BANEROG5)
SI0245     OR  (YZCRYZ01-BANCAR6 < YZCRYZ01-BANEROG6)
SI0245         MOVE ZERO TO YZCRA71-PR01
SI0245         GO TO F-CONTROLLA-CASSETTI-ATM
SI0245         .
SI0245
SI0245 F-CONTROLLA-CASSETTI-ATM.
SI0245     EXIT.
SI0491*================================================================*
SI0491* LETTURA TABELLA STATO GENERALE DEL SISTEMA UTENZE              *
SI0491*================================================================*
SI0491 CNTL-TAB-STATO-UTENZE.
SI0491*
SI0491     MOVE SPACE                    TO WK-STATO-UTENZE
SI0491     .
SI0491     MOVE SPACE                    TO YZCWYZ10-064
SI0491     MOVE 'GEB'                    TO YZCWYZ10-064-PROC
SI0491     MOVE '064'                    TO YZCWYZ10-064-COD
SI0491     MOVE 'UTENZE'                 TO YZCWYZ10-064-UTENZE
SI0491     .
SI0491     MOVE SPACE                    TO STCWIODB
SI0491     MOVE DSTABINQ                 TO STCWIODB-SEGMENTO
SI0491     MOVE '02'                     TO STCWIODB-RIFERIMENTO
SI0491     MOVE READONLY                 TO STCWIODB-FUNZ
SI0491     MOVE LEN-TAB-VAR              TO STCWIODB-RECLEN
SI0491     MOVE 'EQ'                     TO STCWIODB-OPERATORE
SI0491     MOVE YZCWYZ10-064-KEY         TO STCWIODB-CHIAVE1
SI0491     MOVE WK-NOTFND                TO STCWIODB-RC-OK (1)
SI0491     .
SI0491     PERFORM MIODB                THRU F-MIODB
SI0491     .
SI0491     IF STCWIODB-RC = WK-NOTFND
SI0491        MOVE ZERO                  TO WK-STATO-UTENZE
SI0491        MOVE 06                    TO STCW196-RIFERIMENTO
SI0491        MOVE 'TABELLA STATO UTENZE NON TROVATA '
SI0491                                   TO STCW196-MSG
SI0491        PERFORM SCRIVI-LOG-ERRORI
SI0491         THRU F-SCRIVI-LOG-ERRORI
SI0491        GO TO F-CNTL-TAB-STATO-UTENZE
SI0491     .
SI0491     MOVE STCWIODB-AREAIO          TO YZCWYZ10-064
SI0491     .
SI0491     IF YZCWYZ10-064-STATO NOT = 'SI'
BLDX01     AND YZCRA71-PR05      NOT = ZERO
SI0491        MOVE ZERO                  TO WK-STATO-UTENZE
SI0491*       MOVE 07                    TO STCW196-RIFERIMENTO
SI0491*       MOVE 'SELF SERVICE UTENZE DISATTIVATO '
SI0491*                                  TO STCW196-MSG
SI0491*       PERFORM SCRIVI-LOG-ERRORI
SI0491*        THRU F-SCRIVI-LOG-ERRORI
R03604*---  ASTERISCATE LE 5 RIGHE PRECEDENTI
SI0491        GO TO F-CNTL-TAB-STATO-UTENZE
SI0491     .
SI0491 F-CNTL-TAB-STATO-UTENZE.
SI0491     EXIT.
SI0601*================================================================*
SI0601*================================================================*
SI0601*================================================================*
SI0601 SEGNALA-PREP-IN-SOSP.
SI0601     MOVE 'PP'                        TO STCW196-RIFERIMENTO
SI0601     MOVE SPACES                      TO STCW196-MSG
SI0601     STRING
SI0601            'ATM '
SI0601             YZCRYZ01-CODABI
SI0601            '/'
SI0601             YZCRYZ01-CODATM
SI0601            'OPERAZ. PREP. IN SOSP. CARTA '
SI0601             YZCRYZ01-TERZA-TRACCIA(02:17)
SI0601            ' IMP. '
SI0601             YZCRYZ01-IMPORTO-PREP(01:05)
SI0601            ','
SI0601             YZCRYZ01-IMPORTO-PREP(06:02)
SI0601               DELIMITED BY SIZE      INTO STCW196-MSG
SI0601     PERFORM SCRIVI-LOG-ERRORI
SI0601     THRU  F-SCRIVI-LOG-ERRORI
SI0601     .
SI0601 F-SEGNALA-PREP-IN-SOSP.
SI0601     EXIT.
R01912
R01912*================================================================*
R01912*================================================================*
R01912 SEGNALA-PRENOTATA-IN-SOSP.
R01912     MOVE 'PR'                        TO STCW196-RIFERIMENTO
R01912     MOVE SPACES                      TO STCW196-MSG
R01912     STRING
R01912            'ATM '
R01912             YZCRYZ01-CODABI
R01912            '/'
R01912             YZCRYZ01-CODATM
R01912            ' PER CARTA:'
R01912             YZCRYZ01-TERZA-TRACCIA(02:17)
R01912            ' PRENOT.SOSP:'
R01912             YZCRYZ01-NUMERO-PRENOTATA
R01912               DELIMITED BY SIZE      INTO STCW196-MSG
R01912     PERFORM SCRIVI-LOG-ERRORI
R01912     THRU  F-SCRIVI-LOG-ERRORI
R01912     .
R01912 F-SEGNALA-PRENOTATA-IN-SOSP.
R01912     EXIT.
SI0601*================================================================*
SI0601*................................................................*
SI0601*================================================================*
SI0601 CONTA-LE-PRENOTATE.
SI0601*--->
SI0601*---> CHIAMATA AL MODULO DI CARD PER ACCESSO ALLA TABELLE DELLE
SI0601*---> PRENOTATE
SI0601*--->
SI0601     MOVE ZEROES                      TO Z3CLGE88
SI0601     MOVE ZEROES                      TO Z3CWDCOM-DATI-COMUNI
SI0601     .
SI0601     MOVE 'SPR'                       TO Z3CWDCOM-FUNZIONE
SI0601     MOVE '0000000'                   TO Z3CWDCOM-COD-GRUPPO
SI0601     MOVE COMM-ABI-CARTA              TO Z3CWDCOM-COD-ABI-ISTIT
SI0601     MOVE Z3CWDCOM-DATI-COMUNI        TO Z3CLGE88-DATI-INIZIALI
SI0601     .
SI0601     MOVE YZCRPOSI-PAN                TO Z3CLGE88-INP-PAN
SI0601     .
SI0601     MOVE LENGTH OF Z3CLGE88          TO LINKLEN
SI0601     MOVE Z3CLGE88                    TO LINKAREA
SI0601     MOVE 'Z3UCGE88'                  TO LINKPGM
SI0601     .
SI0601     PERFORM MLINK
SI0601     THRU  F-MLINK
SI0601     .
SI0601     MOVE LINKAREA                    TO Z3CLGE88
SI0601     MOVE Z3CLGE88-DATI-INIZIALI      TO Z3CWDCOM-DATI-COMUNI
SI0601     .
SI0601     IF NOT Z3CWDCOM-OK
SI0601        MOVE 'P4'                     TO STCW196-RIFERIMENTO
SI0601        MOVE  SPACES                  TO STCW196-MSG
SI0601        STRING 'ERRORE "'
SI0601               Z3CWDCOM-RET-CODE
SI0601*              '" IN INSERIMENTO PRENOTATA PAN '
R12303*---  ASTERISCATO LA PRECEDENTE
R12303               '" IN CONTA PRENOTATE PAN '
SI0601               YZCRPOSI-PAN
SI0601               DELIMITED BY SIZE    INTO STCW196-MSG
SI0601        PERFORM SCRIVI-LOG-ERRORI
SI0601        THRU  F-SCRIVI-LOG-ERRORI
SI0601        GO TO MAINERX
SI0601     .
SI0601*--->
SI0601*---> PORTO IN POSITIVO L'IMPORTO DELLE PRENOTATE PER POTERLO
SI0601*---> SOMMARE AL SALDO
SI0601*--->
SI0601*    COMPUTE Z3CLGE88-SALDO-PRENOTATE =
SI0601*            Z3CLGE88-SALDO-PRENOTATE * -1
SI0601*    .
PREPA0*---  ASTERISCATE LE TRE RIGHE PRECEDENTI
SI0601*    ADD Z3CLGE88-SALDO-PRENOTATE     TO WK-SALDO-11-E
PREPA1*---  ASTERISCATA LA PRECEDENTE
PREPA1     IF WK-SEGNO = '+'
PREPA1        MOVE WK-SALDO-11-E         TO WK-SALDO-S
PREPA1     ELSE
PREPA1        COMPUTE WK-SALDO-S = WK-SALDO-11-E * (-1)
PREPA1     .
PREPA1     ADD Z3CLGE88-SALDO-PRENOTATE     TO WK-SALDO-S
PREPA1     .
PREPA1     IF WK-SALDO-S < ZERO
PREPA1        MOVE '-'                   TO WK-SEGNO
PREPA1     ELSE
PREPA1        MOVE '+'                   TO WK-SEGNO
PREPA1     .
PREPA1     MOVE WK-SALDO-S               TO WK-SALDO-11-E
SI0601     .
SI0601 F-CONTA-LE-PRENOTATE.
SI0601     EXIT.
SA0714*================================================================*
SA0714*................................................................*
SA0714*================================================================*
SA0714 CHIUDI-PER-PREPAGATE-PREC.
R26404*
R26404*---  Solo nel caso siano inpostati sia l'importo della prenota-
R26404*--- zione che il numero della prenotata effettuo la chiusura
R26404     IF YZCRYZ01-NUMERO-PRENOTATA = SPACES
R26404        GO TO F-CHIUDI-PER-PREPAGATE-PREC
R26404     .
SA0714     PERFORM RIPRISTINA-MONTE-MONETA
SA0714     THRU  F-RIPRISTINA-MONTE-MONETA
SA0714     .
SA0714     PERFORM CANCELLA-PRENOTATA
SA0714     THRU  F-CANCELLA-PRENOTATA
SA0714     .
SA0714 F-CHIUDI-PER-PREPAGATE-PREC.
SA0714     EXIT.
SA0714*================================================================*
SA0714*................................................................*
SA0714*================================================================*
SA0714 RIPRISTINA-MONTE-MONETA.
SA0714
SA0714     MOVE ZEROES                         TO COMM-RICHIESTE.
SA0714     MOVE YZCRYZ01-TERZA-TRACCIA(02:17)  TO COMM-PAN-RICH.
SA0714     MOVE 8                              TO COMM-FUNZ-RICH.
SA0714     MOVE ZEROES                         TO COMM-ESITO-RICH.
SA0714
SA0714*---> CHIAMATA A YZTCGB04 PER LEGGERE IL RECORD PER UPDATE
SA0714
SA0714     MOVE 'YZTCGB04'                     TO WKPGMSUC.
SA0714     PERFORM CHIAMA-ALTRO-PROGRAMMA
SA0714     THRU  F-CHIAMA-ALTRO-PROGRAMMA
SA0714     .
SA0714*--->
SA0714*---> CHIAMO ROUTINE DI GESTIONE DEI MASSIMALI PREPAGATI PER IL
SA0714*---> RIPRISTINO SUL MONTE MONETA DELLA DISPONIBILITA CONCESSA
SA0714*---> IN FASE DI AUTORIZZAZIONE
SA0714*--->
SA0714     MOVE ZEROES                      TO YZCCGEPP.
SA0714     MOVE LINK-PTR-YZCRPOSI           TO YZCCGEPP-ADR-POSI.
SI1030     MOVE LINK-PTR-YZCRPOCA           TO YZCCGEPP-ADR-POCA.
SA0714     SET GEPP-RC-OK                   TO TRUE
SA0714     SET GEPP--STORNO                 TO TRUE
SA0714     SET GEPP--ATM-BCM                TO TRUE
SA0714     MOVE YZCRYZ01-IMPORTO-PREP       TO YZCCGEPP-IMPORTO
SA0714     MOVE YZCRYZ01-IMPORTO-PREP       TO WK-IMPORTO-PREP
SA0714     .
SA0714     CALL 'YZRCMIPP' USING COMMAREA-YZCCGEPP
SA0714     .
SA0714     IF GEPP-RC-OK
SA0714        MOVE ZEROES                   TO YZCRYZ01-IMPORTO-PREP
SA0714     ELSE
SA0714        MOVE 'P1'                     TO STCW196-RIFERIMENTO
SA0714        MOVE SPACES                   TO STCW196-MSG
SA0714        STRING 'YZRCMIPP RC = '
SA0714                 YZCCGEPP-RC
SA0714               ' PAN '
SA0714                YZCRPOSI-PAN
SA0714               ' ATM '
SA0714                YZCRYZ01-CODABI
SA0714               ' / '
SA0714                YZCRYZ01-CODATM
SA0714               ' FUNZ. '
SA0714                 YZCCGEPP-FUNZIONE
SA0714               ' CANALE '
SA0714                 YZCCGEPP-CANALE
SA0714               ' IMP . '
SA0714                WK-IMPORTO-PREP
SA0714               DELIMITED BY SIZE      INTO STCW196-MSG
SA0714        PERFORM SCRIVI-LOG-ERRORI
SA0714        THRU  F-SCRIVI-LOG-ERRORI
SA0714        GO TO MAINERX
SA0714     .
SA0714*---> CHIAMATA A YZTCGB04 PER RISCRIVERE IL RECORD
SA0714
SA0714     MOVE ZEROES                         TO COMM-RICHIESTE.
SA0714     MOVE YZCRYZ01-TERZA-TRACCIA(02:17)  TO COMM-PAN-RICH.
SA0714     MOVE 4                              TO COMM-FUNZ-RICH.
SA0714     MOVE ZEROES                         TO COMM-ESITO-RICH.
SA0714     MOVE 'YZTCGB04'                     TO WKPGMSUC
SA0714     PERFORM CHIAMA-ALTRO-PROGRAMMA
SA0714     THRU  F-CHIAMA-ALTRO-PROGRAMMA
SA0714     .
SA0714 F-RIPRISTINA-MONTE-MONETA.
SA0714     EXIT.
SA0714*================================================================*
SA0714*................................................................*
SA0714*================================================================*
SA0714 CANCELLA-PRENOTATA.
SA0714*--->
SA0714*---> CHIAMATA AL MODULO DI CARD PER ACCESSO ALLA TABELLE DELLE
SA0714*---> PRENOTATE
SA0714*--->
SA0714     MOVE ZEROES                      TO Z3CLGE88
SA0714     MOVE ZEROES                      TO Z3CWDCOM-DATI-COMUNI
SA0714     .
SA0714     MOVE 'DP1'                       TO Z3CWDCOM-FUNZIONE
SA0714     MOVE '0000000'                   TO Z3CWDCOM-COD-GRUPPO
SA0714     MOVE YZCRYZ01-TERZA-TRACCIA(2:5) TO WK-ABI-SI-CIN
SA0714     COPY YZCPYZ18 REPLACING WK-ABI-05      BY WK-ABI-SI-CIN
SA0714                             COMM-ABI-CARTA BY WK-ABI-NO-CIN
SA0714     .
SA0714     MOVE WK-ABI-NO-CIN               TO Z3CWDCOM-COD-ABI-ISTIT
SA0714     MOVE Z3CWDCOM-DATI-COMUNI        TO Z3CLGE88-DATI-INIZIALI
SA0714     MOVE YZCRPOSI-PAN                TO Z3CLGE88-INP-PAN
SA0714     MOVE YZCRYZ01-NUMERO-PREN-DATA   TO Z3CLGE88-INP-DATA-OPERAZ
SA0714     MOVE YZCRYZ01-NUMERO-PREN-ORA    TO Z3CLGE88-INP-ORA-OPERAZ
SA0714     .
SA0714     MOVE LENGTH OF Z3CLGE88          TO LINKLEN
SA0714     MOVE Z3CLGE88                    TO LINKAREA
SA0714     MOVE 'Z3UCGE88'                  TO LINKPGM
SA0714     .
SA0714     PERFORM MLINK
SA0714     THRU  F-MLINK
SA0714     .
SA0714     MOVE LINKAREA                    TO Z3CLGE88
SA0714     MOVE Z3CLGE88-DATI-INIZIALI      TO Z3CWDCOM-DATI-COMUNI
SA0714     .
SA0714*--->
SA0714*---> LA PRENOTATA POTREBBE ESSERE STATA CANCELLATA DA ALTRE
SA0714*---> ELABORAZIONI
SA0714*--->
SA0714*    IF NOT Z3CWDCOM-OK AND
SA0714*       NOT Z3CWDCOM-NT
R26404*---  Asteriscato le due precedenti
R26404     IF NOT Z3CWDCOM-OK
SA0714        MOVE 'P2'                     TO STCW196-RIFERIMENTO
SA0714        MOVE  SPACES                  TO STCW196-MSG
SA0714        STRING 'ERRORE "'
SA0714               Z3CWDCOM-RET-CODE
SA0714               '" IN CANCELLAZIONE PRENOTATA. PAN '
SA0714               YZCRPOSI-PAN
SA0714               DELIMITED BY SIZE    INTO STCW196-MSG
SA0714        PERFORM SCRIVI-LOG-ERRORI
SA0714        THRU  F-SCRIVI-LOG-ERRORI
SA0714        GO TO MAINERX
SA0714     .
SA0714 F-CANCELLA-PRENOTATA.
SA0714     EXIT.
R20404*=============================================================
R20404*--------------  CONTROLLO RELEASE SOFTWARE -----------------
R20404*=============================================================
R20404 CNTL-REL-SW.
      *
           MOVE SPACE                    TO YYCRTPI
           MOVE 'PI '                    TO YYCRTPI-COD
           MOVE 'REL'                    TO YYCRTPI-COD-VAR
R02208     IF YZCRYZ01-DATI-TER-VERS-SW(1:1) = '4'
R02208        MOVE 'ATMXP'                  TO YYCRTPI-PROGR
R02208     ELSE
           MOVE 'ATM  '                  TO YYCRTPI-PROGR
R02208     END-IF
           MOVE SPACES                   TO YYCRTPI-RESTO-KEY
           .
           MOVE SPACE                    TO STCWIODB
           MOVE DSTABINQ                 TO STCWIODB-SEGMENTO
           MOVE '01'                     TO STCWIODB-RIFERIMENTO
           MOVE READONLY                 TO STCWIODB-FUNZ
           MOVE LEN-TAB-VAR              TO STCWIODB-RECLEN
           MOVE 'EQ'                     TO STCWIODB-OPERATORE
           MOVE YYCRTPI-KEY              TO STCWIODB-CHIAVE1
           .
           PERFORM MIODB                THRU  F-MIODB
           .
           MOVE STCWIODB-AREAIO          TO YYCRTPI
           .
           STRING YYCRTPI-REL-DATA-SCAD(1:4)
                  YYCRTPI-REL-DATA-SCAD(6:2)
                  YYCRTPI-REL-DATA-SCAD(9:2)
                  DELIMITED BY SIZE    INTO WK-DATA-SCAD
           .
           STRING COMMDAY1(7:4)
                  COMMDAY1(4:2)
                  COMMDAY1(1:2)
                  DELIMITED BY SIZE    INTO WK-DATA-OGGI
           .
R02208     IF YZCRYZ01-DATI-TER-VERS-SW(1:1) = '4'
R02208        IF YZCRYZ01-DATI-TER-VERS-SW(5:3) < YYCRTPI-REL-SW(5:3)
R02208           MOVE 'KO' TO COMM-ESITO-RICH
R02208           MOVE '1'  TO WK-FLAG-TERM
R02208           GO TO F-CNTL-REL-SW
R02208        END-IF
R02208        IF YZCRYZ01-DATI-TER-VERS-SW(5:3) = YYCRTPI-REL-SW(5:3)
R02208        AND WK-DATA-OGGI > WK-DATA-SCAD
R02208           MOVE 'KO'                  TO COMM-ESITO-RICH
R02208           MOVE '1'                   TO WK-FLAG-TERM
R02208           GO TO F-CNTL-REL-SW
R02208        END-IF
R02208     ELSE
R45104*    IF WK-DATA-OGGI >= WK-DATA-SCAD
R45104*       IF YZCRYZ01-DATI-TER-VERS-SW < YYCRTPI-REL-SW
R45104     IF YZCRYZ01-DATI-TER-VERS-SW < YYCRTPI-REL-SW
              MOVE 'KO' TO COMM-ESITO-RICH
              MOVE '1'  TO WK-FLAG-TERM
R45104        GO TO F-CNTL-REL-SW
R02208*    .
R02208     END-IF
R45104     IF YZCRYZ01-DATI-TER-VERS-SW = YYCRTPI-REL-SW  AND
R45104        WK-DATA-OGGI > WK-DATA-SCAD
R45104        MOVE 'KO'                  TO COMM-ESITO-RICH
R45104        MOVE '1'                   TO WK-FLAG-TERM
R45104        GO TO F-CNTL-REL-SW
R02208     END-IF
R45104     .
R20404 F-CNTL-REL-SW.
R20404     EXIT.
SI0800*================================================================*
SI0800* LETTURA DEL CARD KEY PER AUTORIZZAZIONI SINCRONE CON OS390     *
SI0800*================================================================*
SI0800 LEGGI-CARD-KEYS.
SI0800     COPY YZCPOL55.
SI0800*================================================================*
SI0800* SEGNALAZIONE DI ERRORE NELLA RICERCA DELLA PKC                 *
SI0800* (NON DEVE ANDARE A MAINERR)                                    *
SI0800*================================================================*
SI0800 ERRORI-XCAR.
SI0800
SI0800     MOVE 'PK'                     TO STCW196-RIFERIMENTO.
SI0800     MOVE  SPACES                  TO STCW196-MSG.
SI0800     STRING 'ERRORE NELLA RICERCA DELLA PKC PER PAN ('
SI0800            WK-YZCRXCAR-KEY-PAN                    ')'
SI0800            DELIMITED BY SIZE    INTO STCW196-MSG.
SI0800
SI0800     PERFORM SCRIVI-LOG-ERRORI
SI0800     THRU  F-SCRIVI-LOG-ERRORI.
SI0800
SI0800 F-ERRORI-XCAR.
SI0800     EXIT.
SI0800*================================================================*
SI0800* VERIFICO SE DEVO UTILIZZARE LA SCHEDA OS390                    *
SI0800*================================================================*
SI0800*CHECK-UTILIZZO-OS390.
SI0800     COPY YZCPIBM6.
SI0800*================================================================*
SI0800* LETTURA DELLA TMK    PER AUTORIZZAZIONI SINCRONE CON OS390     *
SI0800* LETTURA DELLA ZMKP1  PER AUTORIZZAZIONI SINCRONE CON OS390     *
SI0800* LETTURA DEL CARD KEY PER AUTORIZZAZIONI SINCRONE CON OS390     *
SI0800*================================================================*
SI0800*GESTIONE-E-TMK-PKC-VIA-OS390.
SI0800     COPY YZCPIBM2 REPLACING 'YZCRX70' BY YZCRA70.
SA0874*================================================================*
SA0874*................................................................*
SA0874*================================================================*
SA0874 IMP-DATI-SU-TERM.
SA0874*---->
SA0874* VALORIZZO IL NUOVO CAMPO DELL'ARCHIVIO TERMINALI UTILIZZATO
SA0874* PER LE LISTE 3270
SA0874*----> ATM HA IL SOFTWARE NR2 MA L'ARDWARE NON SCRIVE
SA0874     IF YZCRA70-FLAG-AGGIORNA = '0'
SA0874        MOVE '1'                   TO YZCRYZ01-UPGRADE-ATM-NRII
SA0874     ELSE
SA0874*----> ATM HA IL SOFTWARE NR2 E L'ARDWARE SCRIVE
SA0874     IF YZCRA70-FLAG-AGGIORNA = '1'
SA0874        MOVE '2'                   TO YZCRYZ01-UPGRADE-ATM-NRII
SA0874     ELSE
SA0874*----> ATM NON HA IL SOFTWARE NR2
SA0874        MOVE '0'                   TO YZCRYZ01-UPGRADE-ATM-NRII
SA0874     .
SA0874*----
SA0874     IF YZCRA70-PAN IS NUMERIC
SA0874        MOVE YZCRA70-PAN           TO YZCRYZ01-PANPRE
SA0874     .
SA0874     IF YZCRYZ01-AZIONE NOT = 8
SA0874     OR COMM-RES-GIOR   NOT NUMERIC
SA0874     OR COMM-RES-MENS   NOT NUMERIC
SA0874        MOVE ZEROES              TO YZCRYZ01-RES-GIOR
SA0874        MOVE ZEROES              TO YZCRYZ01-RES-MENS
SA0874     ELSE
SA0874      IF WYZ20-A71-MAX-INT-IN-CODA
SA0874        MOVE COMM-RES-GIOR       TO YZCRYZ01-RES-MENS
SA0874        MOVE COMM-RES-MENS       TO YZCRYZ01-RES-GIOR
SA0874      ELSE
SA0874        MOVE COMM-RES-GIOR       TO YZCRYZ01-RES-GIOR
SA0874        MOVE COMM-RES-MENS       TO YZCRYZ01-RES-MENS
SA0874     .
SA0874     IF WK-RISCRITTURA NOT = 'NO'
SA0874        MOVE YZCRPOSI-TIPO-CARTA TO YZCRYZ01-TIPO-CARTA
SA0874        MOVE YZCRPOSI-CARTA      TO YZCRYZ01-NUM-CARTA
SA0874     ELSE
SA0874        MOVE ZEROES              TO YZCRYZ01-TIPO-CARTA
SA0874        MOVE ZEROES              TO YZCRYZ01-NUM-CARTA
SA0874     .
SA0874*--->
SA0874*---> PER OLI IMPOSTO SU FILE TERMINALI IL TIPO AUTORIZZAZIONE
SA0874*--->
SA0874     SET YZCRYZ01-OLI-TIPO-AUT-SLF    TO TRUE.
SA0874*--->
SA0874 F-IMP-DATI-SU-TERM.
SA0874     EXIT.
SI0822*==============================================================*
SI0822* ACCODO I CAMPI PER AGGIORNAMENTO II TRACCIA                  *
SI0822*==============================================================*
SI0822 ACCODAMENTO-SECONDA-TRACCIA.
SI0822*
SI0822     MOVE YZCRYZ01-SECONDA-TRC        TO YZCR2TRX-REC
SI0822     MOVE YZCRYZ01-AGGTO-II-TRACCIA   TO WK-COMODO-FLAG
SI0822     IF  YZCRYZ01-AGGTO-II-TRACCIA = '0'  OR '3'
SI0822         MOVE '2'                     TO WK-COMODO-FLAG
SI0822     .
SI0822     IF YZCRYZ01-AGGTO-II-TRACCIA = '1'
SI0822        MOVE COMM-NR-II               TO YZCR2TRX-NUM-RANDOM
SI0822        MOVE YZCR2TRX-REC             TO WK-COMODO-TRACCIA
SI0822     ELSE
SI0822        MOVE SPACES                   TO WK-COMODO-TRACCIA
SI0831        MOVE ' '                      TO WK-QUALE-TRACCIA
SI0822     .
SI0822 F-ACCODAMENTO-SECONDA-TRACCIA.
SI0822     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 VERIFICA-SE-USO-3DES.
SI0921*--->
SI0921*---> SE I PARAMETRI SONO A LIVELLO DI ISTITUTO
SI0921*--->    VERIFICA DATI SU TABELLA ANAGRAFICA ISTITUTI
SI0921*--->
SI0921     SET WK-AUTORIZZO-VIA-OS390-NO    TO TRUE
SI0921     .
SI0921     IF WYZ20-GEN-3DES-CD-SU-ABD
SI0921        PERFORM VERIFICA-SE-USO-3DES-ABD
SI0921        THRU  F-VERIFICA-SE-USO-3DES-ABD
SI0921        GO TO F-VERIFICA-SE-USO-3DES
SI0921     .
SI0921*--->
SI0921*---> SE LA MODALITA TRIPLO DES NON E ABILITATA ESCO
SI0921*--->
SI0921     IF WYZ20-GEN-3DES-AZ-BCM-ST-SI
SI0921        CONTINUE
SI0921     ELSE
SI0921        GO TO F-VERIFICA-SE-USO-3DES
SI0921     .
SI0921*--->
SI0921*---> SE LA MODALITA TRIPLO DES ABILITATA PER TUTTI GLI ATM
SI0921*--->    IMPOSTO OK ED ESCO
SI0921*--->
SI0921     IF WYZ20-GEN-3DES-AZ-BCM-TUTTI
SI0921        SET WK-AUTORIZZO-VIA-OS390-SI TO TRUE
SI0921        GO TO F-VERIFICA-SE-USO-3DES
SI0921     .
SI0921*--->
SI0921*---> LA MODALITA TRIPLO DES ABILITATA PER ALCUNI ATM
SI0921*--->    VERIFICA TABELLA ATM ABILITATI
SI0921*--->
SI0921     MOVE SPACES                      TO YZCTNSAT
SI0921     MOVE 'GEB'                       TO YZCTNSAT-PROC
SI0921     MOVE 'NSATM'                     TO YZCTNSAT-COD
SI0921     MOVE 9999                        TO YZCTNSAT-ABI
SI0921     .
SI0921     PERFORM CERCA-ATM-IN-TAB-ATM-3DES
SI0921     THRU  F-CERCA-ATM-IN-TAB-ATM-3DES
SI0921     .
SI0921 F-VERIFICA-SE-USO-3DES.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 VERIFICA-SE-USO-3DES-ABD.
SI0921*--->
SI0921*---> Se la modalita triplo des non e abilitata esco
SI0921*--->
SI0921     IF TKABD-3DES-CD-OLD
SI0921        GO TO F-VERIFICA-SE-USO-3DES-ABD
SI0921     .
SI0921*--->
SI0921*---> Se la modalita triplo des non e abilitata per la funz esco
SI0921*--->
SI0921     IF TKABD-3DES-AZ-BCM-ST-SI
SI0921        CONTINUE
SI0921     ELSE
SI0921        GO TO F-VERIFICA-SE-USO-3DES-ABD
SI0921     .
SI0921*--->
SI0921*---> SE LA MODALITA TRIPLO DES ABILITATA PER TUTTI GLI ATM
SI0921*--->    IMPOSTO OK ED ESCO
SI0921*--->
SI0921     IF TKABD-3DES-AZ-BCM-TUTTI
SI0921        SET WK-AUTORIZZO-VIA-OS390-SI TO TRUE
SI0921        GO TO F-VERIFICA-SE-USO-3DES-ABD
SI0921     .
SI0921*--->
SI0921*---> SE LA MODALITA TRIPLO DES ABILITATA PER ALCUNI ATM
SI0921*--->    VERIFICA TABELLA ATM ABILITATI
SI0921*--->
SI0921     MOVE SPACES                      TO YZCTNSAT
SI0921     MOVE 'GEB'                       TO YZCTNSAT-PROC
SI0921     MOVE 'NSATM'                     TO YZCTNSAT-COD
SI0921     MOVE YZCRYZ01-CODABI             TO YZCTNSAT-ABI
SI0921     .
SI0921     PERFORM CERCA-ATM-IN-TAB-ATM-3DES
SI0921     THRU  F-CERCA-ATM-IN-TAB-ATM-3DES
SI0921     .
SI0921 F-VERIFICA-SE-USO-3DES-ABD.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921*CERCA-ATM-IN-TAB-ATM-3DES.
SI0921*LEGGI-TAB-ATM-3DES.
SI0921     COPY YZCPNSAT REPLACING 'YZCTNSAT'   BY YZCTNSAT
SI0921                                'TNSAT'   BY    TNSAT
SI0921                             'YZFUNZIONE' BY    TNSAT-BCM-AZI-SI.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 MERGE-DECISIONALI.
SI0921     IF WYZ20-GEN-3DES-CD-SU-ABD
SI0921        IF TKABD-3DES-CD-OS390
SI0921           SET WK-TIPO-CRYPTO-SCHEDA     TO TRUE
SI0921        END-IF
SI0921        IF TKABD-3DES-CD-HSM
SI0921           SET WK-TIPO-CRYPTO-HSM        TO TRUE
SI0921        END-IF
SI0921        GO TO F-MERGE-DECISIONALI
SI0921     .
SI0921     IF WYZ20-GEN-3DES-CD-OS390
SI0921        SET WK-TIPO-CRYPTO-SCHEDA     TO TRUE
SI0921     .
SI0921     IF WYZ20-GEN-3DES-CD-HSM
SI0921        SET WK-TIPO-CRYPTO-HSM        TO TRUE
SI0921     .
SI0921 F-MERGE-DECISIONALI.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 GESTIONE-PKC-CON-3DES.
SI0921
SI0921*--->
SI0921*---> Se non ò previsto l'utilizzo della nuova modalitä (3des)
SI0921*--->    esco
SI0921*
SI0921     IF WK-AUTORIZZO-VIA-OS390-NO
SI0921        GO TO F-GESTIONE-PKC-CON-3DES
SI0921     .
SI0921     SET WK-E-TMK-PKC-OS390-OK  TO TRUE
SI0921     MOVE SPACES                TO YZCRXTRK
SI0921     MOVE SPACES                TO YZCRXAK
SI0921     MOVE 'S'                   TO WK-NEWSIC
SI0921     .
SI0921*--->
SI0921*---> Cerco la TMK nel file YZDXAK o YZDXTK
SI0921*--->
SI1221     IF  RYZ01-ATM-CON-SOFT-3DES-RKM
SI1221         MOVE 'A70'                       TO WK-PKEP-TIPO-CHIAMATA
SI1221         IF NOT WYZ20-GEN-KEY-UNDER-HMK-SI
SI1221            MOVE '304'                    TO WK-PKEP-TKEY-TYPE-H
SI1221            MOVE 'OKEYXLAT'               TO WK-PKEP-TKEY-TYPE-S
SI1221         ELSE
SI1221            MOVE '002'                    TO WK-PKEP-TKEY-TYPE-H
SI1221            MOVE 'EXPORTER'               TO WK-PKEP-TKEY-TYPE-S
SI1221         END-IF
SI1221         PERFORM CHIAMA-SICUREZZA-FUNZ-CC001
SI1221         THRU  F-CHIAMA-SICUREZZA-FUNZ-CC001
SI1221         IF  ARKL-RET-CODE = 0
SI1221             SET WK-E-TMK-PKC-OS390-OK     TO TRUE
SI1221             IF NOT WYZ20-GEN-KEY-UNDER-HMK-SI
SI1221                MOVE ARKL-TKEY-DERIVATA    TO  WK-CURRENT-TMK-OKEY
SI1221             ELSE
SI1221                MOVE ARKL-TKEY-DERIVATA    TO  WK-CURRENT-TMK-EXP
SI1221             END-IF
SI1221         ELSE
SI1221             MOVE SPACES                   TO WK-CURRENT-TMK
SI1221             MOVE SPACES                   TO WK-CURRENT-TMK-EXP
SI1221             MOVE SPACES                   TO WK-CURRENT-TMK-OKEY
SI1221             SET WK-E-TMK-PKC-OS390-KO     TO TRUE
SI1221         END-IF
SI1221     ELSE
SI0921     PERFORM LEGGI-TMK-OS390
SI0921     THRU  F-LEGGI-TMK-OS390
SI0921     .
SI0921     MOVE 'N'                   TO WK-NEWSIC
SI0921     .
SI0921*-->
SI0921*--> Se Errore precedente vado a fine routine
SI0921*-->
SI0921     IF WK-E-TMK-PKC-OS390-KO
SI0921        GO TO F-GESTIONE-PKC-CON-3DES
SI0921     .
SI0948*---> Seil cripto device e la scheda OS390
SI0948*--->   Se Attiva la gestione delle chiavi master specifiche
SI0948*--->      chiamo DBKM o banca per la lettura delle medesime
SI0948*
SI0921     IF WK-TIPO-CRYPTO-SCHEDA
SI0948        IF NOT WYZ20-GEN-KEY-UNDER-HMK-SI
POSTE         OR     WYZ20-GEN-KEY-UNDER-HMK-POSTE
SI0948           IF WYZ20-GEN-MSG-H2X-NCH-SI
SI0948              PERFORM CHIAMA-DBKM-PER-MASTER-IST
SI0948              THRU  F-CHIAMA-DBKM-PER-MASTER-IST
SI0948           ELSE
SI0948              PERFORM CHIAMA-BANCA-PER-MASTER-IST
SI0948              THRU  F-CHIAMA-BANCA-PER-MASTER-IST
SA0959           END-IF
SI0948        END-IF
SI0948
SI0948        IF WK-E-TMK-PKC-OS390-KO
SI0948           GO TO F-GESTIONE-PKC-CON-3DES
SI0948     .
SI0921*-->
SI0921*--> Se crypto device da utilizzare e la scheda os390
SI0921*-->
SI0921     IF WK-TIPO-CRYPTO-SCHEDA
SI0921        PERFORM ELABORA-CHIAMATA-SCHEDA
SI0921        THRU  F-ELABORA-CHIAMATA-SCHEDA
SI0921     ELSE
SI0921        IF WK-TIPO-CRYPTO-HSM
SI0921           PERFORM ELABORA-CHIAMATA-HSM
SI0921           THRU  F-ELABORA-CHIAMATA-HSM
SI0921        ELSE
SI0921           SET WK-E-TMK-PKC-OS390-KO  TO TRUE
SI0921           MOVE SPACES                TO STCW196-MSG
SI0921           MOVE 'KOCD'                TO STCW196-RIFERIMENTO
SI0921           STRING ' ATM '
SI0921                  YZCRYZ01-CODABI
SI0921                  '-'
SI0921                  YZCRYZ01-CODATM
SI0921                  ' Errore - tipo CD da utilizzare non definito -'
SI0921                  ' ' WK-TIPO-CRYPTO
SI0921           DELIMITED BY SIZE INTO STCW196-MSG
SI0921           PERFORM SCRIVI-LOG-ERRORI
SI0921           THRU  F-SCRIVI-LOG-ERRORI
SI0921        END-IF
SI0921     END-IF.
SI0921 F-GESTIONE-PKC-CON-3DES.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 ELABORA-CHIAMATA-SCHEDA.
SI0921*-->
SI0921*--> La SCHEDA e un Crypto Device sincrono
SI0921*-->
SI0921     SET WK-TIPO-ELAB-SYNC            TO TRUE
SI0921*-->
SI0921*--> Chiamo il modulo di cifratura OS390 per calcolo E(TMK, PKC)
SI0921*-->      o il modulo di cifratura OS390 della BANCA
SI0921*-->
SI0921     IF YZCWYZ20-GEN-OS390-NAME NOT = SPACES AND
SI0921        WYZ20-GEN-OS390-TCAL-OK
SI0948        MOVE 'AZIENDA'                   TO XKCCXNCH-TMB-IDENT (1)
SI0948        MOVE 'YZTCA70 '                  TO XKCCXNCH-TMB-PGM   (1)
SI0948        MOVE 'BANCA   '                  TO XKCCXNCH-TMB-FASE  (1)
SI0948        CALL 'YYRATM20'               USING XKCCXNCH-TMB-TIMBRO(1)
SI0921        PERFORM ELAB-SCHEDA-NEWSIC-BANCA
SI0921        THRU  F-ELAB-SCHEDA-NEWSIC-BANCA
SI0948        MOVE 'AZIENDA'                   TO XKCCXNCH-TMB-IDENT (2)
SI0948        MOVE 'YZTCA70 '                  TO XKCCXNCH-TMB-PGM   (2)
SI0948        MOVE 'BANCA   '                  TO XKCCXNCH-TMB-FASE  (2)
SI0948        CALL 'YYRATM20'               USING XKCCXNCH-TMB-TIMBRO(2)
SI0948        COPY YZCPNSSB.
SI0921     ELSE
SI0921        PERFORM ELAB-SCHEDA-NEWSIC-NCH
SI0921        THRU  F-ELAB-SCHEDA-NEWSIC-NCH
SI0921     .
SI0921 F-ELABORA-CHIAMATA-SCHEDA.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 ELABORA-CHIAMATA-HSM.
SI0921*--->
SI0921*---> Se la gestione del CD HSM e gestito in modalitä sincrona
SI0921*--->    utilizzando il protocollo TCP o UDP o altro ancora
SI0921*--->    Imposto le aree per la chiamata al modulo SEMM
SI0921*--->    chiamo il modulo SEMM
SI0921*--->    imposto i dati in risposta
SI0921*---> Altrimenti
SI0921*--->    imposto i flag
SI0921*--->    - Elaborazione asincrona, il programma preparerä il msg
SI0921*--->      A71 ma non lo inviera al terminale ma verra chiamato il
SI0921*--->      gestore della HSM passandogli anche il MSG A71 che a
SI0921*--->      fronte della risposta OK lo integrerä con la PKC per
SI0921*--->      poi rispondere al terminale ATM
SI0921*--->    - Elaborazione OK
SI0921*--->
SI0921*--->
SI0921     IF WYZ20-GEN-HSM-ASYNC
SI0921        SET WK-TIPO-ELAB-ASYNC           TO TRUE
SI0921        SET WK-E-TMK-PKC-OS390-OK        TO TRUE
SI0921        GO TO F-ELABORA-CHIAMATA-HSM
SI0921     .
SI0921*--->
SI0921*---> Imposto le aree comuni per la chiamata al SEMM
SI0921*--->
SI0921     MOVE 50                             TO LINK-RISPOSTA-LUNG
SI0921     MOVE 'DATI FINTI PER HMS SINCRONA ' TO LINK-RISPOSTA-DATI
SI0921*--->
SI0921*---> Imposto le aree comuni per la chiamata al SEMM
SI0921*--->
SI0921     PERFORM IMPOSTA-AREE-PER-SEMM
SI0921     THRU  F-IMPOSTA-AREE-PER-SEMM
SI0921     .
SI0921     SET WK-TIPO-ELAB-SYNC               TO TRUE
SI0921     .
SI0921     IF WYZ10-ABD-ATTIVA-SEM-CON-LK-R
SI0921        PERFORM INNESCA-MODULO-SEMM-XKCCSEMM
SI0921        THRU  F-INNESCA-MODULO-SEMM-XKCCSEMM
SI0921     ELSE
SI0921        PERFORM INNESCA-MODULO-SEMM
SI0921        THRU  F-INNESCA-MODULO-SEMM
SI0921     .
SI0921*--->
SI0921*---> Verifica del risultato dell'elaborazione del SEMM
SI0921*--->
SI0921     PERFORM GESTIONE-RISPOSTA-SEMM
SI0921     THRU  F-GESTIONE-RISPOSTA-SEMM
SI0921     .
SI0921 F-ELABORA-CHIAMATA-HSM.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 ELABORA-CHIAMATA-HSM-ASYNC.
SI0921*--->
SI0921*---> Iposto le aree comuni per la chiamata al SEMM
SI0921*--->
SI0921     PERFORM IMPOSTA-AREE-PER-SEMM
SI0921     THRU  F-IMPOSTA-AREE-PER-SEMM
SI0921     .
SI0921     SET WK-TIPO-ELAB-ASYNC           TO TRUE
SI0921     .
SI0921     IF WYZ10-ABD-ATTIVA-SEM-CON-START
SI0921        PERFORM INNESCA-TRX-SEMM
SI0921        THRU  F-INNESCA-TRX-SEMM
SI0921     ELSE
SI0921     IF WYZ10-ABD-ATTIVA-SEM-CON-LK-R
SI0921        PERFORM INNESCA-MODULO-SEMM-XKCCSEMM
SI0921        THRU  F-INNESCA-MODULO-SEMM-XKCCSEMM
SI0921     ELSE
SI0921        PERFORM INNESCA-MODULO-SEMM
SI0921        THRU  F-INNESCA-MODULO-SEMM
SI0921     .
SI0921*--->
SI0921*---> Verifica del risultato dell'elaborazione del SEMM
SI0921*--->
SI0921     PERFORM GESTIONE-RISPOSTA-SEMM
SI0921     THRU  F-GESTIONE-RISPOSTA-SEMM
SI0921     .
SI0921 F-ELABORA-CHIAMATA-HSM-ASYNC.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 ELAB-SCHEDA-NEWSIC-NCH.
SI0948     MOVE 'AZIENDA'                   TO XKCCXNCH-TMB-IDENT (1)
SI0948     MOVE 'YZTCA70 '                  TO XKCCXNCH-TMB-PGM   (1)
SI0948     MOVE 'TRAPKCAZ'                  TO XKCCXNCH-TMB-FASE  (1)
SI0948     CALL 'YYRATM20'               USING XKCCXNCH-TMB-TIMBRO(1)
SI0921*-->
SI0921*--> Chiamo la scheda per ottenere la E(TMK, PKC)
SI0921*-->
SI0921*--->
SI0921*---> Il campo COMM-E-3DES-PKC e valorizzato dal gb04 (nella copy
SI0921*--->  yzcpnrau) da un campo della commarea di colloquio con il
SI0921*--->  modulo edl numero random yzucnrge
SI0921*
SI0921     MOVE SPACES                        TO YZRC005T-AREA
SI0948     MOVE 'S'                           TO YZRC005T-FLAG-STAT
SI0948     IF NOT WYZ20-GEN-KEY-UNDER-HMK-SI
POSTE      OR     WYZ20-GEN-KEY-UNDER-HMK-POSTE
SI0948        MOVE V005T-FUN-TR-E-3DES-PKC-TO-TMK TO YZRC005T-FUNZIONE
SI0948     ELSE
SI0948        MOVE V005T-FUN-TR-E-HMK-PKC-TO-TMK  TO YZRC005T-FUNZIONE
SI0948     .
SI0921*    MOVE V005T-FUN-TR-E-HMK-PKC-TO-TMK TO YZRC005T-FUNZIONE
SI0921*    MOVE SPACES                        TO YZRC005T-KEY-PKC-IN
SI0948* ASTERISCATE LE 2 PRECEDENTI
SI0948     MOVE SPACES                      TO YZRC005T-MASTER-KEY-MRPKC
SI0948     MOVE WK-MASTER-IST-PROT-PKC      TO YZRC005T-KEY-PKC-IN
SI0921     MOVE COMM-E-3DES-PKC               TO YZRC005T-E-PKC
SI0948     IF NOT WYZ20-GEN-KEY-UNDER-HMK-SI
POSTE      OR     WYZ20-GEN-KEY-UNDER-HMK-POSTE
SI0948        MOVE WK-CURRENT-TMK-OKEY        TO YZRC005T-KEY-PKC-OUT
SI0948     ELSE
SI0921     MOVE WK-CURRENT-TMK-EXP            TO YZRC005T-KEY-PKC-OUT
SI0948     .
SI0921     MOVE ZEROES                        TO YZRC005T-RRN-CRO
SI0921     .
SI0921     MOVE YZCWYZ20-GEN-OS390-HARD       TO YZRC005T-HARDWARE-OS390
SI0921     MOVE YZCWYZ20-GEN-OS390-FIRM       TO YZRC005T-FIRMWARE-OS390
SI0921     MOVE YZCWYZ20-GEN-OS390-REL        TO YZRC005T-RELEASE-OS390
SI0921     MOVE YZCWYZ20-GEN-OS390-PRF        TO YZRC005T-PREFIX-NAME
SI0921     .
SI0921     MOVE ZEROES                        TO YZRC005T-RET-CODE
SI0921     MOVE ZEROES                        TO YZRC005T-RES-CODE
SI0921     MOVE ALL '*'                       TO YZRC005T-OPERATION
SI0921     MOVE SPACES                        TO YZRC005T-E-PKC-OUT
SI0921     .
SI0921*-----------------------------------------------------------------
SI0921     IF WYZ20-GEN-3DES-DBG-ALL OR
SI0921       (WYZ20-GEN-3DES-DBG-PGM AND
SI0921        YZCWYZ20-GEN-3DES-PGM = WKPGRMID)
SI0921        MOVE SPACES                 TO  STCW196-MSG
SI0921        MOVE 'Zmkp'                 TO  STCW196-RIFERIMENTO
SI0921        STRING 'Debug 1-'
SI0921                YZCRXTRK-HMK-OS390-ZMKP1-ZI '-'
SI0921                DELIMITED BY SIZE INTO STCW196-MSG
SI0921        PERFORM SCRIVI-LOG-ERRORI
SI0921        THRU  F-SCRIVI-LOG-ERRORI
SI0921        MOVE SPACES                 TO  STCW196-MSG
SI0921        MOVE 'PkcI'                 TO  STCW196-RIFERIMENTO
SI0921        STRING 'Debug 2-'
SI0921                COMM-E-3DES-PKC             '-'
SI0921                DELIMITED BY SIZE INTO STCW196-MSG
SI0921        PERFORM SCRIVI-LOG-ERRORI
SI0921        THRU  F-SCRIVI-LOG-ERRORI
SI0921        MOVE SPACES                 TO  STCW196-MSG
SI0921        MOVE 'Tmk '                 TO  STCW196-RIFERIMENTO
SI0921        STRING 'Debug 3-'
SI0921                WK-CURRENT-TMK-EXP          '-'
SI0921                DELIMITED BY SIZE INTO STCW196-MSG
SI0921        PERFORM SCRIVI-LOG-ERRORI
SI0921        THRU  F-SCRIVI-LOG-ERRORI
SI0948        MOVE SPACES                 TO  STCW196-MSG
SI0948        MOVE 'Tmk '                 TO  STCW196-RIFERIMENTO
SI0948        STRING 'Debug 4-'
SI0948                WK-CURRENT-TMK-OKEY         '-'
SI0948                DELIMITED BY SIZE INTO STCW196-MSG
SI0948        PERFORM SCRIVI-LOG-ERRORI
SI0948        THRU  F-SCRIVI-LOG-ERRORI
SI0921     .
SI0921*-----------------------------------------------------------------
SI0921
SI0921     CALL WK-YZUC005T USING DFHEIBLK
SI0921                            AREA-PIC01
SI0921                            YZRC005T-AREA
SI0921     .
SI0948     MOVE 'AZIENDA'                   TO XKCCXNCH-TMB-IDENT (2)
SI0948     MOVE 'YZTCA70 '                  TO XKCCXNCH-TMB-PGM   (2)
SI0948     MOVE 'TRAPKCAZ'                  TO XKCCXNCH-TMB-FASE  (2)
SI0948     CALL 'YYRATM20'               USING XKCCXNCH-TMB-TIMBRO(2)
SI0948*--->
SI0948     COPY YZCPNSSS REPLACING
SI0948                   'YZRCXXXX' BY YZRC005T
SI0948                    XXFUNZXX  BY YZRC005T-FUNZIONE.
SI0948     .
SI0948*--->
SI0921     IF YZRC005T-RET-CODE = ZEROES
SI0921        MOVE YZRC005T-E-PKC-OUT        TO WK-EPINK-OS390
SI0921*-----------------------------------------------------------------
SI0921        IF WYZ20-GEN-3DES-DBG-ALL OR
SI0921          (WYZ20-GEN-3DES-DBG-PGM AND
SI0921           YZCWYZ20-GEN-3DES-PGM = WKPGRMID)
SI0921           MOVE SPACES                 TO STCW196-MSG
SI0921           MOVE 'Pkc '                 TO STCW196-RIFERIMENTO
SI0921           STRING 'OK call YZUC005T: E(TMK, PKC) -'
SI0921                   YZRC005T-E-PKC-OUT           '-'
SI0921                   ' <= valore da OS390'
SI0921                   DELIMITED BY SIZE INTO STCW196-MSG
SI0921           PERFORM SCRIVI-LOG-ERRORI
SI0921           THRU  F-SCRIVI-LOG-ERRORI
SI0921        END-IF
SI0921*-----------------------------------------------------------------
SI0921     ELSE
SI0921        SET WK-E-TMK-PKC-OS390-KO   TO  TRUE
SI0921        MOVE SPACES                 TO  STCW196-MSG
SI0921        MOVE 'PkcE'                 TO  STCW196-RIFERIMENTO
SI0921        STRING 'KO call YZUC005T: Op/RetC/ResC -'
SI0921                YZRC005T-OPERATION     '/'
SI0921                YZRC005T-RET-CODE(1:8) '/'
SI0921                YZRC005T-RES-CODE(1:8)
SI0921                DELIMITED BY SIZE INTO STCW196-MSG
SI0921        PERFORM SCRIVI-LOG-ERRORI
SI0921        THRU  F-SCRIVI-LOG-ERRORI
SI0921     END-IF
SI0921     .
SI0921 F-ELAB-SCHEDA-NEWSIC-NCH.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 ELAB-SCHEDA-NEWSIC-BANCA.
SI0921 F-ELAB-SCHEDA-NEWSIC-BANCA.
SI0921     EXIT.
SI0921*================================================================*
SI0921*................................................................*
SI0921*================================================================*
SI0921 IMPOSTA-AREE-PER-SEMM.
SI0921*--->
SI0921*---> Imposto la lunghezza globale dell'area da passare al SEMM
SI0921*--->
SI0921     COMPUTE XKCCSEMM-LL = 16                              +
SI0921                           LENGTH OF XKCCTEST              +
SI0921                           LENGTH OF XKCCEXHE              +
SI0921                                     LINK-RISPOSTA-LUNG    +
SI0921                           LENGTH OF XKCCPRIM-PRM-TRAPKC   +
SI0921                           LENGTH OF XKCCXNCH              +
SI0921                           1
SI0921     .
SI0921*--->
SI0921*---> Imposto le lunghezze delle singole aree che compongono la
SI0921*---> commarea da passare al SEMM
SI0921*--->
SI0921     MOVE LENGTH OF XKCCTEST         TO XKCCSEMM-LEN-TESTATA
SI0921     MOVE LENGTH OF XKCCEXHE         TO XKCCSEMM-LEN-EXTRA-HEADER
SI0921     MOVE LINK-RISPOSTA-LUNG         TO XKCCSEMM-LEN-DATI-APPL
SI0921     .
SI0921     MOVE LENGTH OF XKCCPRIM-PRM-TRAPKC
SI0921                                     TO XKCCSEMM-LEN-PRIMITIVA
SI0921     MOVE LENGTH OF XKCCXNCH         TO XKCCSEMM-LEN-RISERVATO-NCH
SI0921     MOVE 1                          TO XKCCSEMM-LEN-LIBERA
SI0921     .
SI0921     MOVE 'ZZ'                        TO XKCCSEMM-ZZ
SI0921     .
SI0921     PERFORM IMPOSTA-TESTATA
SI0921     THRU  F-IMPOSTA-TESTATA
SI0921     .
SI0921     PERFORM IMPOSTA-EXTRA-HEADER
SI0921     THRU  F-IMPOSTA-EXTRA-HEADER
SI0921     .
SI0921     PERFORM IMPOSTA-PRIMITIVA
SI0921     THRU  F-IMPOSTA-PRIMITIVA
SI0921     .
SI0921     PERFORM IMPOSTA-XKCCXNCH
SI0921     THRU  F-IMPOSTA-XKCCXNCH
SI0921     .
SI0921     MOVE XKCCTEST                   TO XKCCSEMM-TESTATA
SI0921     MOVE XKCCEXHE                   TO XKCCSEMM-EXTRA-HEADER
SI0921     MOVE LINK-RISPOSTA-DATI         TO XKCCSEMM-DATI-APPL
SI0921     MOVE XKCCPRIM                   TO XKCCSEMM-PRIMITIVA
SI0921     MOVE XKCCXNCH                   TO XKCCSEMM-RISERVATO-NCH
SI0921     MOVE SPACES                     TO XKCCSEMM-LIBERA
SI0921     .
SI0921 F-IMPOSTA-AREE-PER-SEMM.
SI0921     EXIT.
SI0921*==============================================================*
SI0921*..............................................................*
SI0921*==============================================================*
SI0921 GESTIONE-RISPOSTA-SEMM.
SI0921
SI0921     MOVE XKCCSEMM-TESTATA            TO XKCCTEST
SI0921     MOVE XKCCSEMM-EXTRA-HEADER       TO XKCCEXHE
SI0921     MOVE XKCCSEMM-PRIMITIVA          TO XKCCPRIM
SI0921     MOVE XKCCSEMM-RISERVATO-NCH      TO XKCCXNCH
SI0921     .
SI0921     MOVE 'AZIENDA'                   TO XKCCXNCH-TMB-IDENT (2)
SI0921     MOVE 'YZTCA70 '                  TO XKCCXNCH-TMB-PGM   (2)
SI0921     MOVE 'TRAPKCAZ'                  TO XKCCXNCH-TMB-FASE  (2)
SI0921     CALL 'YYRATM20'               USING XKCCXNCH-TMB-TIMBRO(2)
SI0921     .
SI0948*--->
SI0948     COPY YZCPNSSH REPLACING
SI0948                   XXFUNZXX BY XKCCPRIM-TRAPKC-FUNZIONE.
SI0948*--->
SI0921     IF XKCCTEST-RC NOT = 'OK'
SI0921        SET WK-E-TMK-PKC-OS390-KO   TO TRUE
SI0921        SET WK-TIPO-ELAB-SYNC       TO TRUE
SI0921        MOVE SPACES                 TO STCW196-MSG
SI0921        MOVE 'HMS-'                 TO STCW196-RIFERIMENTO
SI0921        STRING 'KO da XKUCSEMM Rc/CdEr/Ap/tip/prim -'
SI0921                XKCCTEST-RC             '/'
SI0921                XKCCTEST-CODERR         '/'
SI0921                XKCCTEST-APPLICAZIONE   '/'
SI0921                XKCCTEST-TIPO-RICHIESTA '/'
SI0921                XKCCTEST-PRIMITIVA
SI0921                DELIMITED BY SIZE INTO STCW196-MSG
SI0921        PERFORM SCRIVI-LOG-ERRORI
SI0921        THRU  F-SCRIVI-LOG-ERRORI
SI0921        GO TO F-GESTIONE-RISPOSTA-SEMM
SI0921     .
SI0921     MOVE XKCCPRIM-TRAPKC-E-PKC-OUT   TO WK-EPINK-OS390
SI0921     .
SI0921*--->  Imposta in working la modalitä con cui ha elaborato il SEMM
SI0921*
SI0921     IF XKCCTEST-ASINCRONA
SI0921        SET WK-TIPO-ELAB-ASYNC           TO TRUE
SI0921     ELSE
SI0921        SET WK-TIPO-ELAB-SYNC            TO TRUE
SI0921     .
SI0921 F-GESTIONE-RISPOSTA-SEMM.
SI0921     EXIT.
SI0921*==============================================================*
SI0921*..............................................................*
SI0921*==============================================================*
SI0921 IMPOSTA-TESTATA.
SI0921     MOVE 'GEBA'                    TO XKCCTEST-APPLICAZIONE
SI0921     MOVE '020'                     TO XKCCTEST-TIPO-RICHIESTA
SI0921     MOVE SPACES                    TO XKCCTEST-PRIMITIVA
SI0921     MOVE ZEROES                    TO XKCCTEST-CONSORZIO
SI0921     MOVE COMM-ABI-CARTA            TO XKCCTEST-CODICE-ABI
SI0921     MOVE SPACES                    TO XKCCTEST-AID
SI0921     MOVE SPACES                    TO XKCCTEST-CRYPTO-DEVICE
SI0921     MOVE SPACES                    TO XKCCTEST-TIPO-CRYPTO-DEVICE
SI0921     MOVE SPACES                    TO XKCCTEST-MODALITA-CHIAMATA
SI0921     MOVE 'OK'                      TO XKCCTEST-RC
SI0921     MOVE SPACES                    TO XKCCTEST-CODERR
SI0921     MOVE ZEROES                    TO XKCCTEST-EXEC-LEVEL
SI0921     MOVE SPACES                    TO XKCCTEST-TRAN-RESP
SI0921     MOVE SPACES                    TO XKCCTEST-PGM-RESP
SI0921     MOVE SPACES                    TO XKCCTEST-TIPO-RESP
SI0921     MOVE COMMCTRM                  TO XKCCTEST-LTERM-RESP
SI0921     MOVE SPACES                    TO XKCCTEST-TIMBRO-RICHIESTA
SI0921     MOVE SPACES                    TO XKCCTEST-TIMBRO-RISPOSTA
SI0921     .
SI0921 F-IMPOSTA-TESTATA.
SI0921     EXIT.
SI0921*==============================================================*
SI0921*..............................................................*
SI0921*==============================================================*
SI0921 IMPOSTA-EXTRA-HEADER.
SI0921     INITIALIZE                        XKCCEXHE
SI0921     CALL 'YYRATM20' USING XKCCEXHE-TIMBRO
SI0921     .
SI0921     SET XKCCEXHE-RICHIESTA         TO TRUE
SI0921     .
SI0921 F-IMPOSTA-EXTRA-HEADER.
SI0921     EXIT.
SI0921*==============================================================*
SI0921*..............................................................*
SI0921*==============================================================*
SI0921 IMPOSTA-XKCCXNCH.
SI0921     MOVE 'AZIENDA'                   TO XKCCXNCH-TMB-IDENT (1)
SI0921     MOVE 'YZTCA70 '                  TO XKCCXNCH-TMB-PGM   (1)
SI0921     MOVE 'TRAPKCAZ'                  TO XKCCXNCH-TMB-FASE  (1)
SI0921     CALL 'YYRATM20'               USING XKCCXNCH-TMB-TIMBRO(1)
SI0921     .
SI0921 F-IMPOSTA-XKCCXNCH.
SI0921     EXIT.
SI0921*==============================================================*
SI0921*..............................................................*
SI0921*==============================================================*
SI0921 IMPOSTA-PRIMITIVA.
SI0921     .
SI0921     MOVE SPACES                        TO XKCCPRIM-PRM-TRAPKC
SI0921     .
SI0921*--->
SI0921*---> Il campo COMM-E-3DES-PKC e valorizzato dal gb04 (nella copy
SI0921*--->  yzcpnrau) da un campo della commarea di colloquio con il
SI0921*--->  modulo edl numero random yzucnrge
SI0921*
SI0948*---> Se le PKC risiedono protette da HMK
SI0921*---> non imposto volutamente le aree per permettere al SEMM
SI0921*---> di chiamare il DBKM in quanto in aziendale non mi serve la
SI0921*---> master pkc
SI0921*--->
SI0921     MOVE ZEROES                    TO XKCCPRIM-TRAPKC-ABI
SI0921     MOVE ZEROES                    TO XKCCPRIM-TRAPKC-ABI-CONTROP
SI0921     MOVE ZEROES                    TO XKCCPRIM-TRAPKC-DATA
SI0921     MOVE ZEROES                    TO XKCCPRIM-TRAPKC-ORA
SI0921     MOVE SPACES                    TO XKCCPRIM-TRAPKC-TIPO-QDS-1
SI0921     .
SI0948*---> Se le PKC risiedono protette da MASTER istituto
SI0948*--->    imposto le aree per permettere al SEMM di chiamare il
SI0948*--->    DBKM per la lettura delle medesime
SI0948     IF NOT WYZ20-GEN-KEY-UNDER-HMK-SI
POSTE      OR     WYZ20-GEN-KEY-UNDER-HMK-POSTE
SI0948        IF NOT WYZ10-ABD-NEW3D-ABI-IIK-NO
SI0948           MOVE YZCWYZ10-ABD-NEW3D-ABI-IIK
SI0948                                    TO XKCCPRIM-TRAPKC-ABI
SI0948        ELSE
SI0948           MOVE YZCWYZ10-ABD-ABI    TO XKCCPRIM-TRAPKC-ABI
SI0948        END-IF
SI0948        MOVE ZEROES                 TO XKCCPRIM-TRAPKC-ABI-CONTROP
SI0948
SI0948        MOVE COMMDAY2               TO XKCCPRIM-TRAPKC-DATA
SI0948        MOVE COMMTIME-HHMM          TO XKCCPRIM-TRAPKC-ORA(01:04)
SI0948
SI0948        MOVE '1'                    TO XKCCPRIM-TRAPKC-SI-MI
SI0948        MOVE 'MI-PRO-PKC  '         TO XKCCPRIM-TRAPKC-INT-QDS-1
SI0948     .
SI0921*-->
SI0921*--> Preparazione dell'area della primitiva per il SEMM
SI0921*-->
SI0948     IF NOT WYZ20-GEN-KEY-UNDER-HMK-SI
POSTE      OR     WYZ20-GEN-KEY-UNDER-HMK-POSTE
SI0948        MOVE V005T-FUN-TR-E-3DES-PKC-TO-TMK
SI0948                                    TO XKCCPRIM-TRAPKC-FUNZIONE
SI0948     ELSE
SI0921     MOVE V005T-FUN-TR-E-HMK-PKC-TO-TMK
SI0921                                    TO XKCCPRIM-TRAPKC-FUNZIONE
SI0948     .
SI0921     MOVE SPACES                    TO XKCCPRIM-TRAPKC-KEY-PKC-IN
SI0921     MOVE COMM-E-3DES-PKC           TO XKCCPRIM-TRAPKC-E-PKC
SI0948     IF NOT WYZ20-GEN-KEY-UNDER-HMK-SI
POSTE      OR     WYZ20-GEN-KEY-UNDER-HMK-POSTE
SI0948        MOVE WK-CURRENT-TMK-OKEY    TO XKCCPRIM-TRAPKC-KEY-PKC-OUT
SI0948     ELSE
SI0921     MOVE WK-CURRENT-TMK-EXP        TO XKCCPRIM-TRAPKC-KEY-PKC-OUT
SI0948     .
SI0921     MOVE ZEROES                    TO XKCCPRIM-TRAPKC-RRN-CRO
SI0921     .
SI0921     MOVE ZEROES                    TO XKCCPRIM-TRAPKC-RET-CODE
SI0921     MOVE ZEROES                    TO XKCCPRIM-TRAPKC-RES-CODE
SI0921     MOVE ALL '*'                   TO XKCCPRIM-TRAPKC-OPERATION
SI0921     MOVE SPACES                    TO XKCCPRIM-TRAPKC-E-PKC-OUT
SI0921     .
SI0921*-----------------------------------------------------------------
SI0921     IF WYZ20-GEN-3DES-DBG-ALL OR
SI0921       (WYZ20-GEN-3DES-DBG-PGM AND
SI0921        YZCWYZ20-GEN-3DES-PGM = WKPGRMID)
SI0921        MOVE SPACES                 TO  STCW196-MSG
SI0921        MOVE 'Epkc'                 TO  STCW196-RIFERIMENTO
SI0921        STRING 'Pin Key Carta - da card-key "'
SI0921                COMM-E-3DES-PKC        '"'
SI0921                DELIMITED BY SIZE INTO STCW196-MSG
SI0921        PERFORM SCRIVI-LOG-ERRORI
SI0921        THRU  F-SCRIVI-LOG-ERRORI
SI0921        MOVE SPACES                 TO  STCW196-MSG
SI0921        MOVE 'TMK '                 TO  STCW196-RIFERIMENTO
SI0921        STRING 'Terminal Master Key EXP   - "'
SI0921               WK-CURRENT-TMK-EXP  '"'
SI0921                DELIMITED BY SIZE INTO STCW196-MSG
SI0921        PERFORM SCRIVI-LOG-ERRORI
SI0921        THRU  F-SCRIVI-LOG-ERRORI
SI0948        MOVE SPACES                 TO  STCW196-MSG
SI0948        MOVE 'TMK '                 TO  STCW196-RIFERIMENTO
SI0948        STRING 'Terminal Master Key OKEYX - "'
SI0948               WK-CURRENT-TMK-OKEY  '"'
SI0948                DELIMITED BY SIZE INTO STCW196-MSG
SI0948        PERFORM SCRIVI-LOG-ERRORI
SI0948        THRU  F-SCRIVI-LOG-ERRORI
SI0921     .
SI0921 F-IMPOSTA-PRIMITIVA.
SI0921     EXIT.
SI0921*==============================================================*
SI0921*..............................................................*
SI0921*==============================================================*
SI0921 INNESCA-MODULO-SEMM.
SI0921     CALL 'YYUA0911' USING XKCCSEMM COMMPTRAPPL
SI0921     .
SI0921     MOVE 'XKUCSEMM'                 TO LINKPGM
SI0921     .
SI0921     MOVE 1200                       TO LINKLEN
SI0921     MOVE COMMFISS                   TO LINKAREA
SI0921     .
SI0921     PERFORM MLINK
SI0921     THRU  F-MLINK
SI0921     .
SI0921 F-INNESCA-MODULO-SEMM.
SI0921     EXIT.
SI0921*==============================================================*
SI0921*..............................................................*
SI0921*==============================================================*
SI0921 INNESCA-MODULO-SEMM-XKCCSEMM.
SI0921
SI0921     MOVE 'XKTCSEM1'                 TO LINKPGM
SI0921     .
SI0921     MOVE LENGTH OF XKCCSEMM         TO LINKLEN
SI0921     MOVE XKCCSEMM                   TO LINKAREA
SI0921     .
SI0921     PERFORM MLINK
SI0921     THRU  F-MLINK
SI0921     .
SI0921     MOVE LINKAREA                   TO XKCCSEMM
SI0921     .
SI0921 F-INNESCA-MODULO-SEMM-XKCCSEMM.
SI0921     EXIT.
SI0921*==============================================================*
SI0921*..............................................................*
SI0921*==============================================================*
SI0921 INNESCA-TRX-SEMM.
SI0921     MOVE SPACES                      TO STCWIODC
SI0921     CALL 'YYUA0911' USING XKCCSEMM STCWIODC-ADRIOAREA
SI0921     MOVE XKCCSEMM-LL                 TO STCWIODC-LEN
SI0921     MOVE 'XKIN    '                  TO STCWIODC-SECTRX
SI0921     MOVE '01'                        TO STCWIODC-RIFERIMENTO
SI0921     MOVE STARTTRX                    TO STCWIODC-FUNZ
SI0921     MOVE WK-SYSIDERR                 TO STCWIODC-RC-OK (1)
SI0921
SI0921     PERFORM MIODC
SI0921     THRU  F-MIODC
SI0921     .
SI0921     IF STCWIODC-RC NOT = SPACES
SI0921        MOVE 'KO'                   TO XKCCTEST-RC
SI0921        SET WK-E-TMK-PKC-OS390-KO   TO TRUE
SI0921        MOVE XKCCTEST               TO XKCCSEMM-TESTATA
SI0921        STRING 'ERRORE='
SI0921                STCWIODC-RC
SI0921               ' IN INNESCO TRX SEMM='
SI0921               STCWIODC-SECTRX
SI0921               DELIMITED BY SIZE
SI0921        INTO   STCW196-MSG
SI0921        PERFORM SCRIVI-LOG-ERRORI
SI0921        THRU  F-SCRIVI-LOG-ERRORI
SI0921     .
SI0921 F-INNESCA-TRX-SEMM.
SI0921     EXIT.
SI0948*================================================================*
SI0948* La PKC risiede sugli archivi protetta dalla MiPKC              *
SI0948* La MiPKC risiede sugli archivi protetta dalla HMK              *
SI0948* chiamo il DBKM per la lettura delle seguenti chiavi            *
SI0948* La MiPKC risiede sugli archivi protetta dalla HMK              *
SI0948*================================================================*
SI0948 CHIAMA-DBKM-PER-MASTER-IST.
SI0948
SI0948     INITIALIZE XKCCLKKM-AREA REPLACING
SI0948                              NUMERIC DATA BY ZEROES.
SI0948     INITIALIZE XKCCLKKM-AREA REPLACING
SI0948                              ALPHANUMERIC DATA BY SPACES.
SI0948
SI0948     MOVE ZEROES                      TO XKCCLKKM-CONSORZIO
SI0948     .
SI0948     IF NOT WYZ10-ABD-NEW3D-ABI-IIK-NO
SI0948        MOVE YZCWYZ10-ABD-NEW3D-ABI-IIK
SI0948                                      TO XKCCLKKM-ABI
SI0948     ELSE
SI0948        MOVE YZCWYZ10-ABD-ABI         TO XKCCLKKM-ABI
SI0948     .
SI0948     MOVE ZEROES                      TO XKCCLKKM-ABI-CONTROP
SI0948     .
SI0948     MOVE COMMDAY2                    TO XKCCLKKM-DATA
SI0948     MOVE ZEROES                      TO XKCCLKKM-ORA
SI0948     MOVE COMMTIME-HHMM               TO XKCCLKKM-ORA(01:04)
SI0948     MOVE 'MI-PRO-PKC  '              TO XKCCLKKM-KEY-TIPO-QDS(1)
SI0948     .
SI0948*--->
SI0948*---> Link al modulo di gestione delle chiavi (DBKM)
SI0948*--->
SI0948     MOVE 'XKUCLKKM'                  TO LINKPGM
SI0948     MOVE LENGTH OF XKCCLKKM-AREA     TO LINKLEN
SI0948     MOVE XKCCLKKM-AREA               TO LINKAREA
SI0948     .
SI0948     PERFORM MLINK
SI0948     THRU  F-MLINK
SI0948     .
SI0948     MOVE LINKAREA                    TO XKCCLKKM-AREA
SI0948     .
SI0948*--> Se errore dal modulo DBKM
SI0948*-->    Segnalazione dell'errore e invio a fine programma
SI0948*--> Altrimenti
SI0948*-->    estrazione chiavi e lunghezza dalla commarea e
SI0948*-->    compattazione per poterle utilizzare
SI0948
SI0948     IF XKCCLKKM-RETURN-CODE NOT = ZERO
SI0948        MOVE 'RDIS'                   TO STCW196-RIFERIMENTO
SI0948        MOVE SPACES                   TO STCW196-MSG
RDIS          MOVE XKCCLKKM-SQL-CODE        TO WZ-SQL-CODE
SI0948        STRING 'YZTCA70 - Errore da DBKM in read Master IST - '
SI0948                XKCCLKKM-REASON-CODE
RDIS                  ' - '
SI0948*               XKCCLKKM-SQL-CODE
RDIS  *---  Asteriscata la precedente
RDIS                  WZ-SQL-CODE ' - '
SI0948                XKCCLKKM-TABELLA
RDIS                  ' - '
SI0948                XKCCLKKM-FUNZIONE-KO
SI0948                DELIMITED BY SIZE INTO STCW196-MSG
SI0948        PERFORM SCRIVI-LOG-ERRORI
SI0948        THRU  F-SCRIVI-LOG-ERRORI
SI0948        SET WK-E-TMK-PKC-OS390-KO     TO TRUE
SI0948        GO TO F-CHIAMA-DBKM-PER-MASTER-IST
SI0948     ELSE
SI0948
SA0959        MOVE SPACES                   TO WK-XDAT-COMPATTATA
SI0948        MOVE XKCCLKKM-KEY-IMP-TEXT(1) TO WK-XDAT-ESPANSA
SI0948        MOVE XKCCLKKM-KEY-IMP-LEN (1) TO WK-XDAT-LEN-ESPANSA
SI0948
SI0948        PERFORM COMPATTA-DATI
SI0948        THRU  F-COMPATTA-DATI
SI0948
SI0948        MOVE WK-XDAT-COMPATTATA       TO WK-MASTER-IST-PROT-PKC
SI0948     .
SI0948 F-CHIAMA-DBKM-PER-MASTER-IST.
SI0948     EXIT.
SI0948*================================================================*
SI0948*................................................................*
SI0948*================================================================*
SI0948 CHIAMA-BANCA-PER-MASTER-IST.
SI0948     SET WK-E-TMK-PKC-OS390-OK        TO TRUE.
SI0948 F-CHIAMA-BANCA-PER-MASTER-IST.
SI0948     EXIT.
SI0948*================================================================*
SI0948*    ROUTINE DI COMPATTAMENTO DATI
SI0948*================================================================*
SI0948 COMPATTA-DATI.
SI0948
SI0948     MOVE '1'                         TO WK-XDAT-FUNZIONE
SI0948     .
SI0948     CALL 'YYUAXDAT'              USING WK-XDAT-FUNZIONE
SI0948                                        WK-XDAT-LEN-ESPANSA
SI0948                                        WK-XDAT-ESPANSA
SI0948                                        WK-XDAT-LEN-COMPATTATA
SI0948                                        WK-XDAT-COMPATTATA
SI0948     .
SI0948     IF WK-XDAT-FUNZIONE NOT NUMERIC
SI0948        MOVE 'DEKO'                   TO STCW196-RIFERIMENTO
SI0948        MOVE SPACES                   TO STCW196-MSG
SI0948        STRING 'YZTCA70 - Errore durante la compressione '
SI0948               'della master PKC'
SI0948                DELIMITED BY SIZE INTO STCW196-MSG
SI0948        PERFORM SCRIVI-LOG-ERRORI
SI0948        THRU  F-SCRIVI-LOG-ERRORI
SI0948        SET WK-E-TMK-PKC-OS390-KO     TO TRUE
SI0948     .
SI0948 F-COMPATTA-DATI.
SI0948     EXIT.
R42304*=============================================================*
R42304*  CONTROLLO L'EVENTUALE CAMBIO DI PROFILO UTENZE NEL CASO LO
R42304* RICHIEDA LA NUOVA RELEASE SW DELL'ATM.
R42304*=============================================================*
R42304 CNTL-PROF-UTE.
      *
           IF YZCRYZ01-PUTE-PROFILO NOT < 900
              GO TO F-CNTL-PROF-UTE
           .
           MOVE SPACE                    TO YYCRTPI
           MOVE 'PI '                    TO YYCRTPI-COD
           MOVE 'EVR'                    TO YYCRTPI-COD-VAR
           MOVE YZCRYZ01-DATI-TER-VERS-SW
                                         TO YYCRTPI-KEY-TAB
XI0705     IF YZCRYZ01-CHIOSCO-SI
XI0705*       MOVE 'CH'                  TO YYCRTPI-KEY-TAB(08:02)
SI1241*---  Asteriscata la precedente
SI1241        MOVE YZCRYZ01-TIPO-TERM    TO YYCRTPI-KEY-TAB(08:03)
           .
           MOVE SPACE                    TO STCWIODB
           MOVE DSTABINQ                 TO STCWIODB-SEGMENTO
           MOVE '91'                     TO STCWIODB-RIFERIMENTO
           MOVE READONLY                 TO STCWIODB-FUNZ
           MOVE LEN-TAB-VAR              TO STCWIODB-RECLEN
           MOVE 'EQ'                     TO STCWIODB-OPERATORE
           MOVE YYCRTPI-KEY              TO STCWIODB-CHIAVE1
           MOVE WK-NOTFND                TO STCWIODB-RC-OK (1)
           .
           PERFORM MIODB                THRU  F-MIODB
           .
           IF STCWIODB-RC = WK-NOTFND
              GO TO F-CNTL-PROF-UTE
           .
           MOVE STCWIODB-AREAIO          TO YYCRTPI
           .
           IF YYCRTPI-EVR-PROF IS NOT NUMERIC
              GO TO F-CNTL-PROF-UTE
           .
           IF YYCRTPI-EVR-PROF = YZCRYZ01-PUTE-PROFILO
              GO TO F-CNTL-PROF-UTE
           .
           MOVE YYCRTPI-EVR-PROF         TO YZCRYZ01-PUTE-PROFILO
           MOVE '333333'                 TO YZCRYZ01-PUTE-DATA-BATTESIMO
      *---  Ho impostato a '333333' perche' quando avviene il cambio di
      *--- release e' obbligatorio evadere il battesimo prima di una e-
      *--- ventuale autorizzazione.
           .
R42304 F-CNTL-PROF-UTE.
R42304     EXIT.
R03905*===============================================================*
R03905*  CONTROLLO CHE IL PAN SIA CENSITO NELLA TABELLA DI QUELLI ABI-
R03905* LITATI ALLA SPERIMENTAZIONE DEL NR II TRACCIA
R03905*===============================================================*
R03905 CNTL-PAN-NR-II-SPERIM.
      *
           MOVE SPACE                    TO YYCRTPI
           MOVE 'PI '                    TO YYCRTPI-COD
           MOVE 'NR2'                    TO YYCRTPI-COD-VAR
           .
           MOVE SPACE                    TO STCWIODB
           MOVE DSTABINQ                 TO STCWIODB-SEGMENTO
           MOVE '92'                     TO STCWIODB-RIFERIMENTO
           MOVE READONLY                 TO STCWIODB-FUNZ
           MOVE LEN-TAB-VAR              TO STCWIODB-RECLEN
           MOVE 'EQ'                     TO STCWIODB-OPERATORE
           MOVE YYCRTPI-KEY              TO STCWIODB-CHIAVE1
           MOVE WK-NOTFND                TO STCWIODB-RC-OK (1)
           .
           PERFORM MIODB                THRU  F-MIODB
           .
           IF STCWIODB-RC = WK-NOTFND
              SET  TKABD-NRII-STATO-NON-ATTIVO
                                         TO TRUE
              GO TO F-CNTL-PAN-NR-II-SPERIM
           .
           MOVE STCWIODB-AREAIO          TO YYCRTPI
           .
           PERFORM
           VARYING WK-IND               FROM 1 BY 1
             UNTIL WK-IND > 27
                OR YYCRTPI-NR2-PAN(WK-IND) = YZCRA70-PAN
           END-PERFORM
           .
           IF YYCRTPI-NR2-PAN(WK-IND) = YZCRA70-PAN
              SET  TKABD-NRII-STATO-ATTIVO
                                         TO TRUE
           ELSE
              SET  TKABD-NRII-STATO-NON-ATTIVO
                                         TO TRUE
           .
R03905 F-CNTL-PAN-NR-II-SPERIM.
R03905     EXIT.
SI0831*==============================================================*
SI0831*                                                              *
SI0831*==============================================================*
SI0831 PROT-831-DATI.
SI0831*
SI0831     IF  WK-QUALE-TRACCIA = SPACES
SI0831         GO TO F-PROT-831-DATI.
SI0831     IF  WK-QUALE-TRACCIA  = '2'
SI0831         MOVE YZCRA71-IITRACCIA-2
SI0831           TO WS-W831-TR2-INP
SI0831         PERFORM PROT-831-TR2
SI0831          THRU F-PROT-831-TR2
SI0831         MOVE WS-W831-TR2-OUT
SI0831           TO YZCRA71-IITRACCIA-2
SI0831     .
SI0831     IF  WK-QUALE-TRACCIA  = '3'
SI0831         MOVE YZCRA71-IITRACCIA-3
SI0831           TO WS-W831-TR2-INP
SI0831         PERFORM PROT-831-TR2
SI0831          THRU F-PROT-831-TR2
SI0831         MOVE WS-W831-TR2-OUT
SI0831           TO YZCRA71-IITRACCIA-3
SI0831     .
SI0831     IF  WK-QUALE-TRACCIA  = '4'
SI0831         MOVE YZCRA71-IITRACCIA-4
SI0831           TO WS-W831-TR2-INP
SI0831         PERFORM PROT-831-TR2
SI0831          THRU F-PROT-831-TR2
SI0831         MOVE WS-W831-TR2-OUT
SI0831           TO YZCRA71-IITRACCIA-4
SI0831     .
SI0831     IF  WK-QUALE-TRACCIA  = '5'
SI0831         MOVE YZCRA71-IITRACCIA-5
SI0831           TO WS-W831-TR2-INP
SI0831         PERFORM PROT-831-TR2
SI0831          THRU F-PROT-831-TR2
SI0831         MOVE WS-W831-TR2-OUT
SI0831           TO YZCRA71-IITRACCIA-5
SI0831     .
SI0831     MOVE YZCRA71                  TO LINK-RISPOSTA-DATI
SI0831     .
SI0831 F-PROT-831-DATI.
SI0831     EXIT.
SI0831*==============================================================*
SI0831 RECU-831-DATI.
SI0831*
SI0831     IF  WK-QUALE-TRACCIA = SPACES
SI0831         GO TO F-RECU-831-DATI.
SI0831     IF  WK-QUALE-TRACCIA  = '2'
SI0831         MOVE WS-W831-TR2-INP
SI0831           TO YZCRA71-IITRACCIA-2
SI0831     .
SI0831     IF  WK-QUALE-TRACCIA  = '3'
SI0831         MOVE WS-W831-TR2-INP
SI0831           TO YZCRA71-IITRACCIA-3
SI0831     .
SI0831     IF  WK-QUALE-TRACCIA  = '4'
SI0831         MOVE WS-W831-TR2-INP
SI0831           TO YZCRA71-IITRACCIA-4
SI0831     .
SI0831     IF  WK-QUALE-TRACCIA  = '5'
SI0831         MOVE WS-W831-TR2-INP
SI0831           TO YZCRA71-IITRACCIA-5
SI0831     .
SI0831     MOVE YZCRA71                  TO LINK-RISPOSTA-DATI
SI0831     .
SI0831 F-RECU-831-DATI.
SI0831     EXIT.
SI0831*==============================================================*
SI0831*PROT-831-TR2.
SI0831     COPY YZCP831A.
SI1020*==============================================================*
SI1020*CHIAMA-SCUDO-CARISMA.
SI1020     COPY YZCPSCRM.
XI0703*==============================================================*
XI0703*= Verifico se il messaggio } candidato ad essere segnalato   =*
XI0703*= al cliente tramite un ALERT (SMS, eMail, altro)            =*
XI0703*==============================================================*
XI0703 VERIFICA-E-INVIA-ALERT.
XI0703     MOVE ZEROES                       TO WORK-CPXSMS-IMPORTO.
XI0703     COMPUTE WORK-CPXSMS-MONTE-MONETA =
XI0703             YZCRYZ01-DISPON-A71 * 100
XI0703     SET  WORK-CPXSMS-AUTH-NEGATA      TO TRUE.
XI0703     SET  WORK-CPXSMS-AUTH-BCM         TO TRUE.
XI0703     COPY YZCPSMS0 REPLACING 'YZCRXXX' BY YZCRA70.
R07207*===============================================================*
R07207*  CONTROLLO I SERVIZI CHE L'ISTITUTO A DECISO DI ABILITARE     *
R07207*===============================================================*
R07207 CNTL-SERVIZI-ABILITATI.
      *
           MOVE SPACE                    TO YYCRTPI
           MOVE 'PI '                    TO YYCRTPI-COD
           MOVE 'ABL'                    TO YYCRTPI-COD-VAR
           .
           MOVE SPACE                    TO STCWIODB
           MOVE DSTABINQ                 TO STCWIODB-SEGMENTO
           MOVE '93'                     TO STCWIODB-RIFERIMENTO
           MOVE READONLY                 TO STCWIODB-FUNZ
           MOVE LEN-TAB-VAR              TO STCWIODB-RECLEN
           MOVE 'EQ'                     TO STCWIODB-OPERATORE
           MOVE YYCRTPI-KEY              TO STCWIODB-CHIAVE1
           MOVE WK-NOTFND                TO STCWIODB-RC-OK (1)
           .
           PERFORM MIODB                THRU  F-MIODB
           .
           IF STCWIODB-RC = WK-NOTFND
              GO TO F-CNTL-SERVIZI-ABILITATI
           .
           MOVE STCWIODB-AREAIO          TO YYCRTPI
           .
           PERFORM
           VARYING WK-IND               FROM 1 BY 1
             UNTIL WK-IND > 10
                   IF YYCRTPI-ABL-SERV(WK-IND) = ZERO
                      MOVE ZERO          TO YZCRA71-PRXX(WK-IND)
                   END-IF
           END-PERFORM
           .
R07207 F-CNTL-SERVIZI-ABILITATI.
R07207     EXIT.
SI1077*================================================================*
SI1077* CONTROLLO CHE SE GLI AID PRIVATIVI SULLA CARTA SIANO PRESENTI  *
SI1077* ANCHE SUI PROFILI ABILITATI                                    *
SI1077*================================================================*
SI1077 CONTROLLA-AID.
      *-- SE L'ATM HA LA RELEASE DI "MIGRATO",
      *-- E AL CARTA HA IL CHIP,
      *-- SE L'ATM E' STATO BATTEZZATO CON L'AID PRIVATIVO
      *-- DI COMPETENZA E NON COINCIDE CON QUELLO PRESENTE SULLA CARTA,
      *--    DISABILITO IL PRELIEVO
      *--
           IF YZCRYZ01-DATI-TER-VERS-SW > '5001001'
      *-- LEGGO TABELLA DUALITY
              PERFORM LEGGI-DUALITY
              THRU  F-LEGGI-DUALITY
      *-- SE SONO FUORI DAL PERIODO DI DUALITY, VADO A FINE PERFORM
              IF  YZCRDUAL-DATA-DA > YZCRA70-DATAMES
              AND YZCRDUAL-DATA-A  < YZCRA70-DATAMES
                  GO TO F-CONTROLLA-AID
              END-IF
              IF  RPOSI-CHIP-SI
                 PERFORM TROVA-AID-CARTA
                 THRU  F-TROVA-AID-CARTA
                 IF  Z8CLGE90-AID = 'A0000003660001'
                 AND ( YZCRYZ01-CHIP-PARAM-AID-PM OR
                       YZCRYZ01-CHIP-PARAM-AID-P-MP)
                     MOVE ZERO         TO YZCRA71-PR01
                 END-IF
                 IF  Z8CLGE90-AID = 'A0000003660002'
                 AND ( YZCRYZ01-CHIP-PARAM-AID-PP OR
                       YZCRYZ01-CHIP-PARAM-AID-P-MP)
                     MOVE ZERO         TO YZCRA71-PR01
                 END-IF
              END-IF
           END-IF
           .
SI1077 F-CONTROLLA-AID.
SI1077     EXIT.
SI1077 TROVA-AID-CARTA.
           MOVE SPACES                   TO Z8CLGE90
           MOVE 'AI1'                    TO Z8CLGE90-FUNZ
           MOVE YZCRA70-PAN              TO Z8CLGE90-ID-GENERICO(1:17)
           MOVE 'AT'                     TO Z8CLGE90-CANALE
      *
ILCARD*    MOVE 'Z3UCGE90'                  TO LINKPGM
ILCARD*--  DA Z3UCGE90 A Z8UCGE90
ILCARD     MOVE 'Z8UCGE90'                  TO LINKPGM
           MOVE LENGTH OF Z8CLGE90          TO LINKLEN
           MOVE Z8CLGE90                    TO LINKAREA
           .
           PERFORM MLINK
           THRU  F-MLINK
           .
           MOVE LINKAREA                    TO Z8CLGE90
           .
           IF Z8CLGE90-OK
              GO TO F-TROVA-AID-CARTA
           .
      *    MOVE '31'                     TO COMM-ANOMA-RICH.
      *    MOVE 'KO'                     TO COMM-ESITO-RICH.
           MOVE 'AID'                    TO STCW196-RIFERIMENTO.
           MOVE SPACES                   TO STCW196-MSG.
           STRING 'ERRORE ROUTINE Z8UCGE90: RC = '
                   Z8CLGE90-SQLCODE
                  DELIMITED BY SIZE  INTO STCW196-MSG.
           PERFORM SCRIVI-LOG-ERRORI
           THRU  F-SCRIVI-LOG-ERRORI
           .
SI1077 F-TROVA-AID-CARTA.
SI1077     EXIT.
SI1077*================================================================*
SI1077* LEGGO TABELLA DUALITY PER PERIODO DI RIFERIMENTO TEST          *
SI1077*================================================================*
SI1077 LEGGI-DUALITY.
      *
           MOVE SPACES                 TO YZCRDUAL
           MOVE 'GEB'                  TO YZCRDUAL-PROC
           MOVE 'DUAL'                 TO YZCRDUAL-COD
           MOVE WKPGRMID               TO YZCRDUAL-PGM
           MOVE 1                      TO YZCRDUAL-PAG
           MOVE 'A70 '                 TO YZCRDUAL-MSG
           MOVE SPACE                  TO YZCRDUAL-TIPO-MSG
           .
           MOVE SPACE                    TO STCWIODB
           MOVE DSTABINQ                 TO STCWIODB-SEGMENTO
           MOVE '10'                     TO STCWIODB-RIFERIMENTO
           MOVE READONLY                 TO STCWIODB-FUNZ
           MOVE LEN-TAB-VAR              TO STCWIODB-RECLEN
           MOVE 'EQ'                     TO STCWIODB-OPERATORE
           MOVE YZCRDUAL-KEY             TO STCWIODB-CHIAVE1
           MOVE WK-NOTFND                TO STCWIODB-RC-OK (1)
           .
           PERFORM MIODB                THRU F-MIODB
           .
           IF STCWIODB-RC = WK-NOTFND
              MOVE ZEROES              TO YZCRDUAL
           ELSE
              MOVE STCWIODB-AREAIO     TO YZCRDUAL
           .
SI1077 F-LEGGI-DUALITY.
SI1077     EXIT.
SI1221*================================================================*
SI1221*CHIAMA-SICUREZZA-FUNZ-CC001.
SI1221     COPY YZCPCC01.
XP1307*===============================================================*
XP1307*= Impostazione Processing Code & Function Code                =*
XP1307*= Innesco del Network Manager                                 =*
XP1307*= Preparazione e START del Timeout                            =*
XP1307*===============================================================*
XP1307*ATTIVA-DSP.
XP1307     COPY YZCPSVX8 REPLACING 'YZCRXX0' By YZCRA70
XP1307                             'YZCRU20' By YZCRU20-DUMMY.
XP1307*===============================================================*
XP1307*= Exec CICS Start TimeOut                                     =*
XP1307*===============================================================*
XP1307*EXEC-CICS-START-TO.
XP1307     COPY YZCPSVX9.
XP1307*F-EXEC-CICS-START-TO.
XP1307*    EXIT.
XP1307*===============================================================*
XP1307*= Impostazione Processing Code & Function Code                =*
XP1307*===============================================================*
XP1307 IMPOSTA-PROC-FUNC-CODE.
XP1307
XP1307     MOVE YZCRYZ01-RRN-MSG-ISO(7:6) TO YZCRYZ01-APPROVAL-CODE
XP1307     MOVE YZCRYZ01-APPROVAL-CODE    TO WK-DSP-EXX-APPROVAL
XP1307     MOVE X'60C020'                 TO WK-DSP-EXX-TERMCAP
XP1307     MOVE '306100'                  TO WK-DSP-EXX-PROC-CODE
XP1307     MOVE '169'                     TO WK-DSP-EXX-FUNC-CODE
XP1307     MOVE '1100'                    TO WK-DSP-EXX-MSG-ISO
XP1307     .
XP1307 F-IMPOSTA-PROC-FUNC-CODE.
XP1307     EXIT.
XP1307*================================================================*
XP1307*================================================================*
XP1307*================================================================*
XP1307 PREPARA-MSG-KO-X-TO.
XP1307
XP1307     MOVE SPACES                      TO YZCRA71
XP1307     MOVE 'A71'                       TO YZCRA71-CODMES
XP1307     MOVE YZCRA70-CODATM              TO YZCRA71-CODATM
XP1307     MOVE YZCRA70-NUMMES              TO YZCRA71-NUMMES
XP1307     MOVE YZCRA70-DATAMES             TO YZCRA71-DATAMES
XP1307     MOVE YZCRA70-ORAMES              TO YZCRA71-ORAMES
XP1307     MOVE 'E'                         TO YZCRA71-DISP(1:1)
XP1307     MOVE '0'                         TO YZCRA71-FLT3
XP1307     MOVE '31'                        TO YZCRA71-ANOM
XP1307     MOVE ZEROES                      TO YZCRA71-EPINK
XP1307     MOVE ZEROES                      TO YZCRA71-PROF
XP1307     MOVE '1'                         TO YZCRA71-PR01
XP1307     MOVE ZEROES                      TO YZCRA71-SALDO
XP1307*    MOVE 'E'                         TO YZCRA71-SALDO(1:1)
XP1307     MOVE ZEROES                      TO YZCRA71-DATA
XP1307     .
XP1307     MOVE '3'                         TO YZCRA71-AZIONE
XP1307     MOVE ZEROES                      TO YZCRA71-DISP(2:6)
XP1307     .
XP1307     MOVE ZEROES                      TO YZCRA71-RESTO
XP1307     .
XP1307     MOVE YZCRA71                     TO WK-DSP-AREA-START(5:)
XP1307     MOVE 83                          TO WK-DSP-LUNG-START
XP1307     MOVE YZCRA71                     TO YZCWTCP2-MESSAGGIO
XP1307     .
XP1307 F-PREPARA-MSG-KO-X-TO.
XP1307     EXIT.
XP1307*================================================================*
XP1307*================================================================*
XP1307*================================================================*
XP1307 INOLTRO-STORNO-A-DSP.
XP1307
XP1307     IF YZCRYZ01-EMV-TIPO-TRACCIA = ' '
XP1307        MOVE ZEROES                     TO YZCRA20
XP1307        MOVE 'A20'                      TO YZCRA20-CODMES
XP1307        MOVE YZCRA70-CODATM             TO YZCRA20-CODATM
XP1307        MOVE YZCRA70-NUMMES             TO YZCRA20-NUMMES
XP1307        MOVE YZCRA70-DATAMES            TO YZCRA20-DATAMES
XP1307        MOVE YZCRA70-ORAMES             TO YZCRA20-ORAMES
XP1307        MOVE '0'                        TO YZCRA20-STATO
XP1307        MOVE '54'                       TO YZCRA20-ANOM
XP1307        MOVE SPACES                     TO YZCRA20-ANOMHARD
XP1307        MOVE ZEROES                     TO YZCRA20-FLAG-TRANS
XP1307        MOVE YZCRYZ01-TERZA-TRACCIA     TO YZCRA20-3TRANOR
XP1307        MOVE YZCRA20                    TO YZCRMESS-DATI-MSG
XP1307        MOVE LENGTH OF YZCRA20          TO YZCRMESS-LUNG
XP1307     ELSE
XP1307        MOVE ZEROES                     TO YZCRJ20
XP1307        MOVE 'J20'                      TO YZCRJ20-CODMES
XP1307        MOVE YZCRA70-CODATM             TO YZCRJ20-CODATM
XP1307        MOVE YZCRA70-NUMMES             TO YZCRJ20-NUMMES
XP1307        MOVE YZCRA70-DATAMES            TO YZCRJ20-DATAMES
XP1307        MOVE YZCRA70-ORAMES             TO YZCRJ20-ORAMES
XP1307        MOVE YZCRYZ01-EMV-TIPO-TRACCIA  TO YZCRJ20-TIPO-TRACCIA
XP1307        MOVE '0'                        TO YZCRJ20-STATO
XP1307        MOVE '54'                       TO YZCRJ20-ANOM
XP1307        MOVE SPACES                     TO YZCRJ20-ANOMHARD
XP1307        MOVE SPACES                     TO YZCRJ20-TIPO-ANOM
XP1307
XP1307        IF RJ20-TIPO-TRACCIA-2 OR
XP1307           RJ20-TIPO-TRACCIA-CHIP-INT
XP1307           MOVE YZCRYZ01-SECONDA-TRC    TO YZCRJ20-II-TRACCIA
XP1307        END-IF
XP1307        IF RJ20-TIPO-TRACCIA-3
XP1307           MOVE YZCRYZ01-TERZA-TRACCIA  TO YZCRJ20-TRK-NORM
XP1307        END-IF
XP1307        IF RJ20-TIPO-TRACCIA-CHIP-DOM
XP1307           MOVE YZCRYZ01-PANPRE         TO YZCRJ20-CHIP-DOM-PAN
XP1307        END-IF
XP1307        MOVE YZCRYZ01-IND-UTE-A86-O     TO YZCRJ20-IND-FUNZ-ESA
XP1307        MOVE HIGH-VALUE                 TO YZCRJ20-ICC-REL-DATA
XP1307        IF RJ20-TIPO-TRACCIA-CHIP-INT
XP1307           MOVE YZCRYZ01-AID-PRIVATIVO  TO YZCRJ20-ICC-REL-DATA
XP1307                                           (09:16)
XP1307        END-IF
XP1307        MOVE YZCRJ20                    TO YZCRMESS-DATI-MSG
XP1307        MOVE LENGTH OF YZCRJ20          TO YZCRMESS-LUNG
XP1307     .
XP1307     INITIALIZE                         CAB01-RED-DATI-NCH-SISTEMA
XP1307     INITIALIZE                         CAB01-PMIN
XP1307     MOVE YZCRMESS                   TO CAB01-PMIN-APPLDATI
XP1307*---
XP1307     MOVE YZCRYZ01-CAB               TO CAB01-PMIN-CAP
XP1307     MOVE YZCRYZ01-ATM-IN-TCP-SNA    TO CAB01-PMIN-ATM-TCP-SNA
XP1307     MOVE YZCRMESS-CODMES            TO CAB01-EXX-TIPO-MSG
XP1307     MOVE YZCRMESS-CODATM            TO CAB01-EXX-CODATM
XP1307     MOVE YZCRYZ01-AID-PRIVATIVO     TO CAB01-EXX-AID
XP1307
XP1307     MOVE YZCRMESS-GG                TO CAB01-EXX-DATA-MESS(5:2)
XP1307     MOVE YZCRMESS-MM                TO CAB01-EXX-DATA-MESS(3:2)
XP1307     MOVE YZCRMESS-AA                TO CAB01-EXX-DATA-MESS(1:2)
XP1307     MOVE ZEROES                     TO CAB01-EXX-ORA-MESS
XP1307     MOVE YZCRMESS-ORAMES            TO CAB01-EXX-ORA-MESS(1:4)
XP1307
XP1307     MOVE YZCRYZ01-RRN-MSG-ISO       TO CAB01-EXX-RRN
XP1307     MOVE YZCRYZ01-012-DATA-ORIG     TO CAB01-EXX-DATA-ORIG
XP1307     MOVE YZCRYZ01-012-ORA-ORIG      TO CAB01-EXX-ORA-ORIG
XP1307     MOVE YZCRYZ01-011-NUMMES        TO CAB01-EXX-NUMMES
XP1307     MOVE YZCRYZ01-UTE-DISPON        TO CAB01-EXX-IMPORTO
XP1307     .
XP1307* ---  Impostazione Proc Code & Func Code
XP1307* ---
XP1307     MOVE YZCRYZ01-COD-MSG-ISO       TO CAB01-EXX-MSG-ISO
XP1307     MOVE SPACES                     TO CAB01-EXX-MOD-PAG
XP1307     MOVE X'60C020'                  TO CAB01-EXX-TERMCAP
XP1307     MOVE '306100'                   TO CAB01-EXX-PROC-CODE
XP1307     IF YZCRYZ01-ISO-DOPPIO-AUTOR = 'S'
XP1307        MOVE '800'                   TO CAB01-EXX-FUNC-CODE
XP1307     ELSE
XP1307        MOVE '400'                   TO CAB01-EXX-FUNC-CODE
XP1307     .
XP1307     IF YZCRYZ01-APPROVAL-CODE = SPACES OR
XP1307        YZCRYZ01-APPROVAL-CODE = ZEROES OR
XP1307        YZCRYZ01-APPROVAL-CODE = LOW-VALUE
XP1307        MOVE ZEROES                  TO CAB01-EXX-APPROVAL
XP1307     ELSE
XP1307        MOVE YZCRYZ01-APPROVAL-CODE  TO CAB01-EXX-APPROVAL
XP1307     .
XP1307     MOVE SPACES                     TO CAB01-EXX-LTH-UTENTE
XP1307     MOVE CAB01-EXX-PROC-CODE        TO YZCRYZ01-003-PROC-CODE
XP1307     MOVE CAB01-EXX-FUNC-CODE        TO YZCRYZ01-024-FUNC-CODE
XP1307     .
XP1307     MOVE 'XYTCYZUN'                 TO LINKPGM
XP1307     MOVE LENGTH OF XYCCAB01         TO LINKLEN
XP1307     MOVE XYCCAB01                   TO LINKAREA
XP1307     .
XP1307*--- Impostazione TRX fittizia per accesso tabelle
XP1307*---
XP1307     IF YZCRYZ01-EMV-TIPO-TRACCIA = ' '
XP1307        MOVE 'YZJM'                  TO EIBTRNID
XP1307     .
XP1307     IF YZCRYZ01-EMV-TIPO-TRACCIA = '0' OR
XP1307        YZCRYZ01-EMV-TIPO-TRACCIA = '2'
XP1307        MOVE 'YZJD'                  TO EIBTRNID
XP1307     .
XP1307     IF YZCRYZ01-EMV-TIPO-TRACCIA = '1' OR
XP1307        YZCRYZ01-EMV-TIPO-TRACCIA = '3'
XP1307        MOVE 'YZJI'                  TO EIBTRNID
XP1307     .
XP1307     PERFORM MLINK
XP1307     THRU  F-MLINK
XP1307     .
XP1307     MOVE LINKAREA                   TO XYCCAB01
XP1307     .
XP1307     MOVE SPACES                     TO YZCRYZ01-EMV-TIPO-TRACCIA
XP1307     MOVE ZEROES                     TO YZCRYZ01-APPROVAL-CODE
XP1307     MOVE SPACES                     TO YZCRYZ01-ULT-NUMMOVI-CC
XP1307     .
XP1307     MOVE LINK-MESSAGGIO             TO YZCRMESS
XP1307     MOVE YZCRMESS-DATI-MSG          TO YZCRA70
XP1307     .
XP1307     PERFORM INIT-XP1037-TERM
XP1307     THRU  F-INIT-XP1037-TERM
XP1307     .
XP1307 F-INOLTRO-STORNO-A-DSP.
XP1307     EXIT.
      *==============================================================*
      *    -----------  E N D   O F   P R O G R A M  -----------     *
      *==============================================================*
