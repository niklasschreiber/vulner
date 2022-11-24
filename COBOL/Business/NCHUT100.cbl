       IDENTIFICATION DIVISION.
       PROGRAM-ID.    NCHUT100.
      *================================================================*
      *                                                                *
      *      NNN     NNN         CCCCCCCC        HHH   HHH             *
      *      NNNNN   NNN        CCCCCCCCC        HHH   HHH             *
      *      NNNNNN  NNN        CCC              HHHHHHHHH             *
      *      NNN NNNNNNN        CCC              HHHHHHHHH             *
      *      NNN   NNNNN  ...   CCCCCCCCC ...    HHH   HHH  ...        *
      *      NNN     NNN  ...    CCCCCCCC ...    HHH   HHH  ...        *
      *                                                                *
      *----------------------------------------------------------------*
      *      NETWORK            COMPUTER         HOUSE     - BOLOGNA - *
      *----------------------------------------------------------------*
      *                                                                *
      *                  CONVERSAZIONE  CON  CONFERMA                  *
      *                                                                *
      *  CONVERSAZIONE T.P. : GARI         PROGRAMMA: NCHUT100         *
      *  VERSIONE 01.01 DEL : 27/05/88 --- ULTIMA MODIFICA : XX/XX/XX  *
      *================================================================*
      *          INSERIMENTO MESSAGGI IN FORMATO A.U.M.                *
      *================================================================*
      * MG0394 *  INSERIMENTO DEI TIMBRI SUL TRACCIATO AUM.            *
      *================================================================*
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
           03  FILLER        PIC X(14) VALUE 'INIZIO-WORKING'.
           03  WK-MAINPTR    PIC S9(8) COMP SYNC VALUE ZERO.
           03  WK-LEN1       PIC S9(4) COMP SYNC VALUE ZERO.
           03  WK-LNGMSG        PIC S9(4) COMP SYNC VALUE +50.
           03  WK-IND-PRIM    PIC S9(4) COMP SYNC VALUE ZERO.
           03  WK-IND-SEC     PIC S9(4) COMP SYNC VALUE ZERO.
           03  WK-IND         PIC S9(4) COMP SYNC VALUE ZERO.
           03  WK-IND1        PIC S9(4) COMP SYNC VALUE ZERO.
           03  WK-PRIMI-TRE   PIC X(3) OCCURS 50.
           03  PRIMI          PIC X(3).
           03  INDICE         PIC S9(4) COMP SYNC VALUE ZERO.
           03  WK-PRIMI       PIC X(3) VALUE SPACES.
           03  WK-IND-COM   PIC S9(4)   COMP SYNC VALUE ZERO.
           03  WK-INCREM        PIC S9(4) COMP SYNC VALUE ZERO.
           03  WK-I             PIC S9(4) COMP SYNC VALUE ZERO.
           03  WK-TOT-IMP-DIGIT PIC 9(15) VALUE ZERO.
           03  WK-TOT-IMP-CALC  PIC 9(15) VALUE ZERO.
           03  WK-TOT-TIMP-DIGIT PIC 9(02) VALUE ZERO.
           03  WK-TOT-TIMP-CALC  PIC 9(02) VALUE ZERO.
           03  SW-TOT           PIC 9(02) VALUE ZERO.
           03  ERRORE           PIC 9  VALUE ZERO.
           03  WK-COM2.
               05  WK-COM21     PIC X     VALUE SPACE.
               05  WK-COM22     PIC X     VALUE SPACE.
           03  WK-DATE          PIC 9(6)  VALUE ZERO.
           03  FILLER REDEFINES WK-DATE.
               05 WK-AA         PIC X(2).
               05 WK-MM         PIC X(2).
               05 WK-GG         PIC X(2).
           03  CAMPO-DI-COMODO  PIC X(2).
           03  CAMPO            PIC 9.
           03  CAMPO1           PIC 9.
           03  WK-SWFILE        PIC X.
               88 TROVATO                 VALUE 'T'.
               88 NON-TROVATO             VALUE 'N'.
           03  WK-STATUS        PIC X     VALUE SPACES.
               88 NOTFND                  VALUE 'N'.
           03  WK-STATUS-KEY    PIC X     VALUE SPACES.
               88 KEY-NOTFND              VALUE 'N'.
           03  WK-STATUS-ABD    PIC X     VALUE SPACES.
               88 ABD-NOTFND              VALUE 'N'.
           03  UNICO            PIC X(2)  VALUE SPACES.
           03  LEN-ZERO         PIC S9(4) COMP SYNC VALUE +0.
           03  LUNGHEZZA        PIC S9(4) COMP SYNC VALUE +0.
           03  WK-RICPAG        PIC X     VALUE SPACES.
           03  WK-DATNUM        PIC 9(5)  VALUE ZERO.
           03  WK-TIME          PIC 9(6)  VALUE ZERO.
           03  NUM-5            PIC 9(5).
           03  NUM-2            PIC 9(2).
           03  WK-NMFIL.
               05 WK-NOMFIL     PIC X(8).
               05 WK-SUFFISSO   PIC X(2).
      *-----------------------
           03  WK-LNGMSG     PIC S9(4) COMP SYNC VALUE +50.
      *----
           03  AA               PIC 9(02) COMP VALUE 21.
           03  FILLER REDEFINES  AA.
               05  FILLER       PIC X.
               05  VAL-ESAD     PIC X.
      *------- AREA EDIT CAMPI NUMERICI --------*
           03  WK-NUMERICO-5    PIC ZZZZZ.
           03  WK-NUMERICO-11   PIC ZZZZZZZZZZZ.
           03  WK-NUMERICO-15   PIC ZZZ.ZZZ.ZZZ.ZZZ.ZZZ.
           03  WK-NUMERICO-8    PIC 999999.
      *-----------------------------------------*
           03  WK-RIGA-ELE.
              05  WK-RIGA-REC   PIC X OCCURS 76.
      *-----------------------------------------*
           03  WK-ENDMSG     PIC X(50)
           VALUE '--------->  F I N E  P R O C E D U R A  <---------'.
           03  WK-ERRMSG     PIC X(50)
           VALUE '----->   PROGRAMMA CHIAMATO DIRETTAMENTE    <-----'.
      *----------------------- CAMPO DI COMODO PER SCOMPORRE
      *----                    IL PERCORSO
           03  WK-PERCORSO-1       PIC 9(10)   VALUE ZERO.
           03  FILLER REDEFINES    WK-PERCORSO-1.
               05  WK-PERCORSO     PIC 9(02) OCCURS 5.
      *-----------------------
      *
      *---- CAMPI PER CODA DI T.S.
      *
           03  WK-VAR.
               05 FILLER         OCCURS 10.
                  07 WK-RIGA     PIC X(76).
      *--------------
      *---- AREA PER AGGIORNAMENTO RECORD
      *
       01  WK-RECOUT.
           03  WK-REC         PIC X  OCCURS 2000
                                   DEPENDING ON LEN-2000.
      *
       01  WK-RICOUT.
           03  WK-RIC         PIC X  OCCURS 2364
                                   DEPENDING ON LEN-RIC.
      *
MG0394*---------------------     AREA DI COMODO PER IMPOSTAZIONE TIBRI
MG0394*---------------------     PRESENTI SUL TRACCIATO AUM.
MG0394 01  WK-TIMBRO-COMMAREA.
MG0394     03  WK-TIMBRO-COMMDAY2     PIC 9(6).
MG0394     03  WK-TIMBRO-COMMTIME     PIC 9(6).
           EJECT
      *---------------------
           COPY RBAW004.
      *---------------------
           COPY RBAW005.
      *---------------------
           COPY RBAW006.
      *---------------------
           COPY RBAW017.
      *---------------------
           COPY RBAW018.
      *--------------------------------------------------------------*
      *    AREA GESTIONE TOTALI
      *--------------------------------------------------------------*
           COPY RBAW030.
      *---------------------
           COPY RBAW033.
      *==============================================================*
      *       W O R K I N G     S T O R A G E    S T A N D A R D     *
      *==============================================================*
       01  WKSTORAGE-STANDARD.
           03  FILLER          PIC X(16) VALUE 'INIZ-WK-STANDARD'.
      *
           03  WKPGRMID        PIC X(08) VALUE 'NCHUT100'.
      *                              NOME PROGRAMMA
           03  WKTRANID        PIC X(08) VALUE '        '.
      *                              NOME TRANSAZIONE
           03  WKMAPPID        PIC X(08) VALUE 'RBMUT10'.
      *                              NOME MAPPA
           03  WKMAPSET        PIC X(08) VALUE 'RBSUT10'.
      *                              NOME MAPSET
           03  WKCURSOR        PIC X(01) VALUE '1'.
               88 WKCURSNO               VALUE '0'.
               88 WKCURSSI               VALUE '1'.
      *                              POSIZIONAMENTO CURSORE
           03  WKSEND          PIC X(01) VALUE ' '.
      *                              INVIO MAPPA + DATI
           03  WKPGMRIT        PIC X(08) VALUE 'RBC0002 '.
      *                              PGM DI RITORNO
           03  WKPGMRITN       PIC X(08) VALUE '        '.
      *                              TRX DI RITORNO
           03  WKMENRIT        PIC X(08) VALUE 'RBC0002 '.
      *                              MENU' DI RITORNO
           03  WKMENRITN       PIC X(08) VALUE '        '.
      *                              TRX-MENU' DI RITORNO
           03  WKPGMSUC        PIC X(08) VALUE 'NCHUT100'.
      *                              PGM SUCCESSIVO
           03  WKPGMSCH        PIC X(08) VALUE '        '.
      *                              PGM DA SCHEDULARE
           03  WKTASSCH        PIC X(08) VALUE '        '.
      *                              TRX  DA SCHEDULARE
           03  WKTERMID        PIC X(08) VALUE '        '.
      *                              TERMINALE DA SCHEDULARE
           03  WKCODTS         PIC X(08) VALUE '        '.
      *                              TERMINALE DA SCHEDULARE
           03  WKMODDAT        PIC X(01).
      *                              MODIFICA DATI
               88 WKMODDTN               VALUE '0'.
      *                              DATI NON MODIFICATI
               88 WKMODDTS               VALUE '1'.
      *                              DATI MODIFICATI
           03  WKPOSAGG        PIC X(01).
      *                              POSSIBILITA' AGGIORNAMENTO
               88 WKAGGPOS               VALUE '1'.
      *                              AGGIORNAMENTO POSSIBILE
               88 WKAGGIMP               VALUE '0'.
      *                              AGGIORNAMENTO IMPOSSIBILE
           03  WKFINE          PIC X(01).
      *                              INDICATORE FINE CODA DI TRANS.
               88 WKENDTR                VALUE 'Y'.
      *                              FINE CODA DI TRANSAZIONE
      *------------------ TIPI OPZIONE -----------------------------*
           03  WKENTERK        PIC X(02).
      *                              INVIO DATI
           03  WKHELPRQ        PIC X(02).
      *                              HELP TRANSAZIONE
           03  WKRIINIZ        PIC X(02).
      *                              RIINIZIO CONVERSAZIONE
           03  WKRETURN        PIC X(02).
      *                              RITORNO
           03  WKRICINT        PIC X(02).
      *                              RICHIESTA INTERRUZIONE
           03  WKHELPER        PIC X(02).
      *                              HELP ERRORI
           03  WKPRTVID        PIC X(02).
      *                              STAMPA VIDEO
           03  WKPAGIND        PIC X(02).
      *                              PAGINAZIONE INDIETRO
           03  WKPAGAVA        PIC X(02).
      *                              PAGINAZIONE AVANTI
           03  WKCONFER        PIC X(02).
      *                              CONFERMA OPERAZIONE.
      *--------------------------------------------------------------*
           03  WKLENRIC        PIC S9(4) COMP SYNC VALUE ZERO.
      *                              LUNGHEZZA COMMAREA RICEVUTA
           03  WKLENFIS        PIC S9(4) COMP SYNC VALUE ZERO.
      *                              LUNGHEZZA COMMAREA FISSA
           03  WKLENCOM        PIC S9(4) COMP SYNC VALUE ZERO.
      *                              LUNGHEZZA COMMAREA TOTALE
           03  WKLENMAP        PIC S9(4) COMP SYNC VALUE ZERO.
      *                              LUNGHEZZA MAPPA.
           03  WKLENIODB       PIC S9(4) COMP SYNC VALUE ZERO.
      *                              LUNGHEZZA AREA I/O D.B.
           03  WKLENIODC       PIC S9(4) COMP SYNC VALUE ZERO.
      *                              LUNGHEZZA AREA I/O D.C.
           03  WKLN9028        PIC S9(4) COMP SYNC VALUE +2235.
      *                              LUNGHEZZA COMMAREA DI RBC9028
           03  WKLN9024        PIC S9(4) COMP SYNC VALUE +88  .
      *                              LUNGHEZZA COMMAREA DI RBC9024
      *==============================================================*
      *    1 - COMMUNICATION AREA (C.A.) DEL PROGRAMMA               *
      *==============================================================*
       01  COMMAREA.
      *---------------------- COMMAREA STANDARD ---------------------*
           COPY RBAW180.
      *--------------------------------------------------------------*
      *==============================================================*
      *       ZONA UTENTE DELLA COMMAREA PER PGM SUCCESSIVO          *
      *==============================================================*
           COPY RBAW190.
      *==============================================================*
      *       AREA PER DATI IN FORMATO ORIGINE                       *
      *==============================================================*
           02  COMMUTOR.
               03 COMMFILOR      PIC X(8)  VALUE 'COMMUTOR'.
               03 ORPRIO         PIC 9(1).
               03 ORMAX          PIC 9(3).
      *==============================================================*
      *       AREA PER DATI IN FORMATO MAPPA                         *
      *==============================================================*
           02  COMMUTED.
               03 COMMFILED      PIC X(8)   VALUE 'COMMUTED'.
               03 EDFILE         PIC X(08).
               03 EDPRIO         PIC X(01).
               03 EDCAPP         PIC X(04).
               03 EDTABEL.
                  05 EDRIGA      PIC X(76) OCCURS 10.
      *==============================================================*
      *       AREA PER IMMAGINE ARCHIVI ALL'INIZIO CONVERSAZIONE     *
      *==============================================================*
           02  COMMIMAG.
               03 COMMXXX         PIC 9(3).
      *==============================================================*
      *       AREA PER SALVATAGGIO VECCHIA MAPPA                     *
      *==============================================================*
           02  COMMDSMV.
               03 FILLER          PIC X     OCCURS 3840
                                            DEPENDING ON WKLENMAP.
      *==============================================================*
      *    2 - COMUNICATION AREE PER TABELLE E/O PGM DI UTILITA'     *
      *==============================================================*
      *==============================================================*
      *    WORK AREA PER ROUTINE M062  - CONTROLLO NUMERICITA'       *
           COPY RBAW062 .
      *==============================================================*
      *    WORK AREA PER ROUTINE M063  - CONTROLLO DATA              *
           COPY RBAW063 .
      *==============================================================*
      *    WORK AREA PER ROUTINE M065  - CONVERSIONE DA ESADECIMALE  *
      *                                  A ZONED                     *
      *    COPY RBAW065 .
      *==============================================================*
      *    WORK AREA PER ROUTINE M066  - CONTROLLO ORA               *
      *==============================================================*
           COPY RBAW066 .
      *==============================================================*
      *    WORK AREA PER ROUTINE M067  - CONVERSIONE DA ZONED A      *
      *                                  ESADECIMALE                 *
      *    COPY RBAW067 .
      *==============================================================*
      *    WORK AREA PER ROUTINE M070  - TRASFORMAZIONE DATA         *
      *    COPY RBAW070 .
      *==============================================================*
      *    WORK AREA PER ROUTINE M071  - TRASFORMAZIONE DATA         *
           COPY RBAW071 .
      *==============================================================*
      *    WORK AREA PER ROUTINE M080  - CENTRATURA TESTO            *
           COPY RBAW080 .
      *==============================================================*
      *    3 - COPY STANDARD PER GESTIONE TASTI FUNZIONALI           *
      *        ED ATTRIBUTI DA MODIFICARE SULLA DSECT OUTPUT         *
      *==============================================================*
           COPY DFHAID   .
           COPY DFHBMSCA .
           COPY RBAWOSCA .
      *==============================================================*
      *    4 - COPY DELLA DSECT RELATIVA AL MAPSET DEL PGM           *
      *==============================================================*
           COPY RBSUT10.
       01      FILLER REDEFINES RBMUT10O.
           COPY RBMUT10.
      *----------------------------- FINE MAPPA
       01  FINE-MAPPA     PIC X.
      *==============================================================*
      *    5 - COPY DELLE DSECT ARCHIVI                              *
      *==============================================================*
           COPY RBAR002     .
           COPY RBAR005     .
           COPY RBAR013     .
           COPY RBAR071     .
           COPY RBAR070     .
      *
COB II    01 RBARRIC-RECORD-ZERO.
      *
          03 RBARRIC-LL-ZERO                     PIC S9(4) COMP.
      *                                           LUNGH. RECORD
      *
          03 RBARRIC-KEY-ZERO.
      *
             05 RBARRIC-DATA-ZERO                PIC 9(6).
      *                                           DATA-RICEZIONE AAMMGG
             05 RBARRIC-PRO-ZERO                 PIC 9(5).
      *                                           PROG. NELL'AMBITO
      *                                           DELLA DATA
      *
          03 RBARRIC-DATI-ZERO.
      *
             05 RBARRIC-DATA-ULT                 PIC 9(6).
      *                                           DATA-RICEZIONE AAMMGG
             05 RBARRIC-PRO-ULT                  PIC 9(5).
      *                                           PROG. NELL'AMBITO
      *                                           DELLA DATA
      *
      *================================================================*
      *
          01 RBARRIC-RECORD.
      *
          03 RBARRIC-LL                          PIC S9(4) COMP.
      *                                           LUNGH. RECORD
      *
          03 RBARRIC-KEY.
      *
             05 RBARRIC-DATA                     PIC 9(6).
      *                                           DATA-RICEZIONE AAMMGG
             05 RBARRIC-PRO                      PIC 9(5).
      *                                           PROG. NELL'AMBITO
      *                                           DELLA DATA
      *
          03 RBARRIC-PASSATO                     PIC X(27).
      *
          03 RBARRIC-PLICO.
      *                                           PLICO
             05 RBARRIC-BUSTA.
      *                                           BUSTA DI SPEDIZIONE
      *
                07 RBARRIC-TIPRECB               PIC 9(3).
      *                                           TIPO RECORD : 011
      *
                07 RBARRIC-IDAUMITB              PIC X(12).
      *                                           IDENTIFICATORE AU
      *                                           MITTENTE
      *
                07 RBARRIC-NSESB                 PIC 9(5).
      *                                           N. SESSIONE AU-STP
      *
                07 RBARRIC-NSEQB                 PIC 9(8).
      *                                           N. SEQUENZA AU-STP
      *
                07 RBARRIC-ACTAZB                PIC 9(12).
      *                                           TIMBRO ACCETTAZIONE
      *
                07 RBARRIC-IDAUDESB              PIC X(12).
      *                                           IDENTIFICATORE AU
      *                                           DESTINATARIO
      *
                07 RBARRIC-RCPB                  PIC 9(12).
      *                                           TIMBRO DI RECAPITO
      *
                07 RBARRIC-MDSERB.
      *                                           MODALITA SERVIZIO
                   09 RBARRIC-PRTVB              PIC 9.
      *                                           PRIORITA PLICO
                   09 RBARRIC-TIPB               PIC 9.
      *                                           TIPO SERVIZIO
                   09 RBARRIC-TRFB               PIC X(3).
      *                                           MODALITA TARIFFAZIONE
      *
                07 RBARRIC-CONFB                 PIC X(2).
      *                                           RICHIESTE CONFERME
      *                                           LOGICHE
      *
                07 RBARRIC-IDPAUB                PIC X(8).
      *                                           IDENTIFICATORE PAU
      *
                07 RBARRIC-CTGCTB                PIC X.
      *                                           CATEGORIA CONTENUTO
      *
                07 RBARRIC-IDAUCTB               PIC X(16).
      *                                           IDENTIFICATORE AU
      *                                           DEL CONTENUTO
      *
                07 RBARRIC-LLMAB                 PIC S9(8) COMP.
      *                                           LUNGHEZZA MAU
      *
             05 RBARRIC-MAU.
      *
                07 RBARRIC-TIPRECM               PIC 9(3).
      *                                           TIPO RECORD = 008
      *
                07 RBARRIC-TRAATTM.
      *                                           TESTATA TRASFERIMENTO
      *                                           ATTUALE
      *
                   09 RBARRIC-IDAUMITM           PIC X(12).
      *                                           IDENTIFICATORE AU
      *                                           MITTENTE
      *
                   09 RBARRIC-IDAURICM           PIC X(12).
      *                                           IDENTIFICATORE AU
      *                                           DESTINATARIO
                   09 RBARRIC-REFERM.
      *                                           TRANS. REFERENCE
      *
                      11 RBARRIC-DATAM           PIC X(6).
      *                                           DATA
      *
                      11 RBARRIC-NSESM           PIC 9(5).
      *                                           N. SESS. AU-AU
      *
                      11 RBARRIC-NSEQM           PIC 9(8).
      *                                           N. SEQUENZA AU-AU
      *
                      11 RBARRIC-ORAM            PIC 9(4).
      *                                           ORA
      *
                   09 RBARRIC-AUTM               PIC X(4).
      *                                           AUTENTICATORE
      *
                07 RBARRIC-TRAINIM.
      *                                           TESTATA TRASFERIMENTO
      *                                           INIZIALE
      *
                   09 RBARRIC-IDAUMITIM          PIC X(12).
      *                                           IDENTIFICATORE AU
      *                                           MITTENTE
      *
                   09 RBARRIC-IDAURICIM          PIC X(12).
      *                                           IDENTIFICATORE AU
      *                                           DESTINATARIO
                   09 RBARRIC-REFERIM.
      *                                           TRANS. REFERENCE
      *
                      11 RBARRIC-DATAIM          PIC X(6).
      *                                           DATA
      *
                      11 RBARRIC-NSESIM          PIC 9(5).
      *                                           N. SESS. AU-AU
      *
                      11 RBARRIC-NSEQIM          PIC 9(8).
      *                                           N. SEQUENZA AU-AU
      *
                      11 RBARRIC-ORAIM           PIC 9(4).
      *                                           ORA
      *
                   09 RBARRIC-AUTIM              PIC X(4).
      *                                           AUTENTICATORE
      *
                07 RBARRIC-DESERM.
      *                                           DESCRIZIONE SERVIZIO
      *
                   09 RBARRIC-IDABMITM           PIC X(12).
      *                                           IDENTIFICATORE AB
      *                                           MITTENTE
                   09 FILLER REDEFINES RBARRIC-IDABMITM.
                      11 FILLER                  PIC X(5).
                      11 RE01-MT                 PIC X(5).
                      11 FILLER                  PIC X(2).
      *
                   09 RBARRIC-IDABRICIM          PIC X(12).
      *                                           IDENTIFICATORE AB
      *                                           RICEVENTE
      *
                   09 RBARRIC-ICCTGAPM           PIC X(4).
      *                                           CATEGORIA APPLICATIVA
      *
                   09 RBARRIC-TURM               PIC X(16).
      *                                           TUR
      *
                   09 RBARRIC-PRIYM              PIC 9.
      *                                           PRIORITA MESSAGGIO
      *
                   09 RBARRIC-CONFM              PIC 9.
      *                                           CONFERME DI RICEZIONE
      *
                07 RBARRIC-LLMABB                PIC S9(8) COMP.
      *                                           LUNGHEZZA MAB
      *
                07 RBARRIC-MAB                   PIC X(2000).
      *                                           MSG. APPL. BANCARIO
      *==============================================================*
      *    6 - FUNZIONI NECESSARIE ALLE OPERAZIONI DI I/O DATI       *
      *==============================================================*
      *----------------------------- AREA PASSAGGIO DATI PER I/O DC
           COPY RBAWIODC .
      *----------------------------- AREA PASSAGGIO DATI PER I/O DB
           COPY RBAWIODB .
      *----------------------------- CODICE FUNZIONE PER I/O DB
           COPY RBAWIOFN .
      *----------------------------- CODICE FUNZIONE PER I/O DC
           COPY RBAWDLIF .
      *----------------------------- STATUS CODE PER I/O DB
           COPY RBAWSCDS .
      *==============================================================*
      *    7 - AREA PER ERRORI                                       *
      *==============================================================*
      *----------------------------- AREA GESTIONE ERRORI APPLICATIVI
           COPY RBAW182 .
      *----------------------------- AREA PASSAGGIO DATI PER
      *---                           VISUALIZZAZIONE ERRORI
           COPY RBAW195 .
      *==============================================================*
      *    8 - AREA PER GESTIONE CODE TS                             *
      *==============================================================*
       01  AREA-TS.
           03  TSITEM             PIC S9(4) COMP.
           03  TSLENG             PIC S9(4) COMP.
           03  TSQUEUE.
               05 TSTRANSID       PIC X(4).
               05 TSTERMID        PIC X(4).
               EJECT
      *==============================================================*
       LINKAGE SECTION.
      *--------------
       01  DFHCOMMAREA.
           03 COMM-RICE.
              05 FILLER           PIC X  OCCURS 4096
                                  DEPENDING ON WKLENRIC.
      *                           AREA TOTALE SPA DA MAIN
      *==============================================================*
           EJECT
       PROCEDURE DIVISION  USING DFHCOMMAREA.
VVVVVV*       READY TRACE.
VVVVVV*       DISPLAY 'INIZIO ---> NCHUT100'.
      *==============================================================*
      *                                                              *
      *          -------   M A I N   L I N E    -----------          *
      *                                                              *
      *==============================================================*
      *-------------------------  INTERCETTA ERRORI NON GESTITI
      *----                       (SOLO CICS)
           COPY RBAP005.
      *-------------------------  ROUTINE INIZIALIZZAZIONE
           PERFORM MM010 THRU F-MM010.
      *-------------------------  ACQUISIZIONE DATI
           PERFORM MM000 THRU F-MM000.
      *-------------------------  TEST PRIMA VOLTA O REINIZIO
           IF COMMSIPR OR
              COMMOPTI = WKRIINIZ
           THEN PERFORM MM020 THRU F-MM020
                GO TO END-PROGRAM.
      *-------------------------  TEST RICHIESTA INTERRUZIONE
           IF COMMOPTI = WKRICINT OR WKRETURN
           THEN MOVE SPACE TO COMMERXX
                PERFORM MM030 THRU F-MM030
                GO TO END-PROGRAM.
      *-------------------------  ACQUISIZIONE DATI
           PERFORM MM050 THRU F-MM050.
      *-------------------------  TEST RICHIESTA PAGINAZIONE
           IF COMMOPTI = WKPAGAVA OR WKPAGIND
           THEN PERFORM MM040 THRU F-MM040
                GO TO END-PROGRAM.
      *-------------------------  SE DATI MODIFICATI, VALIDAZIONE
           IF WKMODDTS
VVVVVV*    DISPLAY 'PREV COMMUTED=' COMMUTED
VVVVVV*    DISPLAY 'PREV COMMUTOR=' COMMUTOR
           THEN  PERFORM RR050 THRU F-RR050.
VVVVVV*    DISPLAY 'NEXT COMMUTED=' COMMUTED.
VVVVVV*    DISPLAY 'NEXT COMMUTOR=' COMMUTOR.
      *-------------------------  TEST SU TIPO OPZIONE
           IF COMMOPTI = WKENTERK OR
                         WKHELPRQ OR
                         WKHELPER OR
                         WKCONFER
      *---- NO ---->  OR WKPRTVID
           THEN  NEXT SENTENCE
           ELSE  MOVE '1' TO COMMFLG2
                 MOVE 'OPZIONE NON PREVISTA' TO COMMER24.
      *-------------------------  ANALISI ERRORI
           PERFORM RR060 THRU F-RR060.
      *-------------------------  SCELTA ROUTINE
           IF COMMOPTI = WKHELPRQ
           THEN  PERFORM MM060 THRU F-MM060
           ELSE
               IF COMMOPTI = WKHELPER
               THEN  PERFORM MM060 THRU F-MM060
               ELSE
      *-- NO ->IF COMMOPTI = WKPRTVID
      *-- NO ->THEN  PERFORM MM070 THRU F-MM070
      *-- NO ->ELSE
                       PERFORM MM080 THRU F-MM080.
           GO TO END-PROGRAM.
      *-------------------------  RITORNO AL MENU' PRINCIPALE
      *----                       CON SEGNALAZIONE DI ERRORE
       MAINERR.
          COPY RBAP180.
       MAINERX.
      *-------------------------  CESSIONE DEL CONTROLLO
      *-------------------------  SE PROGRAMMA INIZIALE
      *---                           AL SISTEMA
           IF WKPGRMID = WKPGMRIT
              MOVE SPACES    TO COMMPGPR
              MOVE SPACES    TO COMMPGSU
              MOVE SPACES    TO COMMPGAT
              MOVE SPACES    TO COMMTRSU
           ELSE
      *-------------------------  SE ALTRO PROGRAMMA
      *----                          AL PROGRAMMA INIZIALE
              MOVE 1         TO COMMLMEN
              MOVE ZERO      TO COMMITER
              MOVE '1'       TO COMMTCTR
              MOVE WKPGMRIT  TO COMMPGSU.
              MOVE WKTRANID  TO COMMTRSU.
      *--- ENDIF.
      *-------------------------  END MAIN LINE
       END-PROGRAM.
           MOVE WKLENCOM      TO WKLENRIC.
           MOVE COMMAREA      TO COMM-RICE.
VVVVVV*       DISPLAY 'COMMAREA=' COMMAREA.
VVVVVV*       DISPLAY 'FINE ---> NCHUT100'.
      *-------------------------  CESSIONE DEL CONTROLLO AL PROGRAMMA
      *---                        DI MAIN (SOLO C.I.C.S )
           COPY RBAP182.
           GOBACK.
      *-------------------------  CESSIONE DEL CONTROLLO AL PROGRAMMA
      *---                        DI GESTIONE DEGLI ERRORI C.I.C.S
           COPY RBAP191.
           EJECT
      *==============================================================*
      *    MM000 - ROUTINE DI ACQUISIZIONE DATI                      *
      *==============================================================*
       MM000.
      *-------------------------  INIZIALIZZAZIONE DELL'AREA MAPPA
           MOVE LOW-VALUE    TO RBMUT10I.
      *-------------------------  AQUISIZIONE MESSAGGIO (SOLO IMS)
      *---                       CALCOLO LUNGHEZZA MAPPA
           CALL 'RBPT982' USING RBMUT10I FINE-MAPPA WKLENMAP.
      *---                       CALCOLO INDIRIZZO MAPPA
           MOVE SPACE              TO STCWIODC
           CALL 'RBPT911' USING RBMUT10I STCWIODC-ADRIOAREA.
           COPY RBAP110.
VVVVVV*    DISPLAY 'GN-MAPPA=' RBMUT10I
      *-------------------------  IMPOSTAZIONE VALORI TASTI FUNZIONALI
           COPY RBAPFUNZ.
      *-------------------------  LOAD TIPO OPZIONE IN COMMOPTI
           MOVE EIBAID   TO COMMOPTI.
       F-MM000.
           EXIT.
           EJECT
      *==============================================================*
      *    MM010 - ROUTINE DI INIZIALIZZAZIONE                       *
      *==============================================================*
       MM010.
      *------------------------- CALCOLO LUNGHEZZA AREA I/O D.C.
           CALL 'RBPT982' USING STCWIODC STCWIODC-FINE WKLENIODC.
      *------------------------- CALCOLO LUNGHEZZA AREA I/O D.B.
           CALL 'RBPT982' USING STCWIODB STCWIODB-FINE WKLENIODB.
      *------------------------- CALCOLO LUNGHEZZA COMMAREA FISSA
           CALL 'RBPT982' USING COMMFISS COMMFINE   WKLENFIS.
      *------------------------- CALCOLO LUNGHEZZA MAPPA
           CALL 'RBPT982' USING RBMUT10I FINE-MAPPA WKLENMAP.
      *------------------------- CALCOLO LUNGHEZZA COMMAREA TOTALE
           CALL 'RBPT982' USING COMMAREA COMMDSMV   WK-LEN1.
           COMPUTE WKLENCOM = WKLENMAP + WK-LEN1.
      *-------------------------  AQUISIZIONE COMMAREA
           COPY RBAP190.
           MOVE COMM-RICE     TO COMMAREA.
      *-------------------------  TEST SE PRIMA VOLTA
VVVVVV*    DISPLAY 'COMMAREA=' COMMAREA.
           IF COMMSIPR
           THEN MOVE '1'      TO COMMERRO
                MOVE WKMAPSET TO COMMMPST
                MOVE WKMAPPID TO COMMMPPA
                COMPUTE COMMMPAD = WKLENCOM - WKLENMAP + 1.
      *-------------------------  NO OPZIONI ERRATE
           MOVE '0' TO COMMFLG2.
      *-------------------------  IMPOSTAZIONE CODICE TRANSAZIONE
           MOVE COMMSPATR  TO WKTRANID.
       F-MM010.
           EXIT.
           EJECT
      *==============================================================*
      *    MM020 - EMISSIONE PRIMA VOLTA                             *
      *==============================================================*
       MM020.
      *-------------------------  IMPOSTA IL CURSORE
           MOVE WKCURSOR  TO COMMFLG1.
      *-------------------------  FLAG DATI MAI MODIFICATI = NO
           MOVE '0' TO COMMFLG3.
      *-------------------------- AZZERAMENTO ERRORI PER REINIZIO
           IF COMMOPTI = WKRIINIZ
           THEN MOVE SPACE TO COMMERXX
                              COMMER23
                              COMMER24.
      *-------------------------  OPERAZIONI INIZIALI/IMPOSTAZIONE EDIT
           PERFORM RR030 THRU F-RR030.
      *-------------------------  SCRITTURA LOG
           IF COMMSILAR
              MOVE    WK-NMFIL TO RBAR013-ARCHIVIO
              MOVE    'INIT' TO   RBAR013-FUNZIONE
              MOVE    SPACE  TO   RBAR013-CHIAVE-ARC
              PERFORM RR900  THRU F-RR900.
      *-------------------------  SCRITTURA LOG
           IF COMMSILST
              MOVE    WK-NMFIL TO RBARLOG-ARCHIVIO
              MOVE    'INIT' TO   RBARLOG-FUNZIONE
              MOVE    SPACE  TO   RBARLOG-CHIAVE-ARC
              PERFORM RR910  THRU F-RR910.
      *-------------------------  IMPOSTAZIONE EDIT DA DB DI TS
           PERFORM RR350 THRU F-RR350.
      *-------------------------  SALVA DATI INIZIALI
           PERFORM RR040 THRU F-RR040.
VVVVVV*    DISPLAY 'COMMUTOR=' COMMUTOR
VVVVVV*    DISPLAY 'COMMUTED=' COMMUTED
      *-------------------------  ANALISI ERRORI
           PERFORM RR060 THRU F-RR060.
      *-------------------------  FORZA ERRORE PER TEST ROUTINE MM080
           MOVE '1' TO COMMERRO.
      *-------------------------  SETUP MAPPA
           PERFORM RR310 THRU F-RR310.
      *-------------------------  INVIO MAPPA
           PERFORM RR070 THRU F-RR070.
      *-------------------------  RISCHEDULAZIONE
           PERFORM RR320 THRU F-RR320.
       F-MM020.
           EXIT.
           EJECT
      *==============================================================*
      *    MM030 - INTERRUZIONE CONVERSAZIONE                        *
      *==============================================================*
       MM030.
      *-------------------------  SCRITTURA LOG
           IF COMMSILAR
              MOVE    WK-NMFIL TO RBAR013-ARCHIVIO
              MOVE    'FINE' TO   RBAR013-FUNZIONE
              MOVE    SPACE  TO   RBAR013-CHIAVE-ARC
              PERFORM RR900  THRU F-RR900.
      *-------------------------  SCRITTURA LOG
           IF COMMSILST
              MOVE    WK-NMFIL TO RBARLOG-ARCHIVIO
              MOVE    'FINE' TO   RBARLOG-FUNZIONE
              MOVE    SPACE  TO   RBARLOG-CHIAVE-ARC
              PERFORM RR910  THRU F-RR910.
      *-------------------------  OPERAZIONI FINALI
           PERFORM RR280 THRU F-RR280.
           MOVE '1' TO COMMTCTR.
      *-------------------------  IMPOSTO PGM DI RITORNO
           IF COMMOPTI = WKRETURN
           THEN PERFORM MM030-RETURN   THRU F-MM030-RETURN
                MOVE SPACES    TO COMMPGAT
                MOVE WKMENRIT  TO COMMPGSU
      *         MOVE WKMENRITN TO COMMTRSU
           ELSE
                PERFORM MM030-CLEAR    THRU F-MM030-CLEAR
                MOVE SPACES    TO COMMPGAT
                MOVE WKPGMRIT  TO COMMPGSU.
      *         MOVE WKPGMRITN TO COMMTRSU.
       F-MM030.
           EXIT.
      *-------------------------  IMPOSTA PROGRAMMA DA RICHIAMARE
       MM030-RETURN.
      *-------------------------  IMPOSTO CAMPI DI COMMAREA
           MOVE 'RBC0002 ' TO WKMENRIT
           COMPUTE COMMLMEN = COMMLMEN - 1.
           MOVE COMMITER        TO WK-PERCORSO-1
           MOVE ZERO            TO WK-PERCORSO(COMMLMEN)
           MOVE WK-PERCORSO-1   TO COMMITER.
       F-MM030-RETURN.
           EXIT.
      *-------------------------  IMPOSTA PROGRAMMA DA RICHIAMARE
       MM030-CLEAR.
      *-------------------------  IMPOSTO CAMPI DI COMMAREA
           MOVE 1                   TO COMMLMEN
           MOVE ZERO                TO COMMITER.
       F-MM030-CLEAR.
           EXIT.
           EJECT
      *==============================================================*
      *    MM040 - PAGINAZIONE AVANTI/INDIETRO                       *
      *            INTRODURRE LE ISTRUZIONI DI PAGINAZIONE           *
      *            AGGIORNARE CONTATORE PAG. CORRENTE IN C.A.        *
      *==============================================================*
       MM040.
           MOVE 'Y'          TO WK-RICPAG.
           IF COMMOPTI = WKPAGAVA
               PERFORM MM040-PAGAVA  THRU F-MM040-PAGAVA
           ELSE
               PERFORM MM040-PAGIND  THRU F-MM040-PAGIND.
      *-------------------------  IMPOSTO CURSORE
           MOVE  CURSOR      TO WKRIGAL(1).
      *-------------------------  VALIDAZIONE/DECODIFICA
           PERFORM RR050 THRU F-RR050.
      *-------------------------  ANALISI ERRORI
           PERFORM RR060 THRU F-RR060.
      *-------------------------  IMPOSTAZIONE EDIT DA CODE TS
           PERFORM RR350 THRU F-RR350.
      *-------------------------  SETUP MAPPA
           PERFORM RR310 THRU F-RR310.
      *-------------------------  INVIO MAPPA
           PERFORM RR070 THRU F-RR070.
      *-------------------------  RISCHEDULAZIONE
           PERFORM RR320 THRU F-RR320.
       F-MM040.
           EXIT.
           SKIP3
       MM040-PAGAVA.
           IF COMMPAGCOR EQUAL COMMPAGTOT
              MOVE 'ULTIMA PAGINA' TO COMMER24
COB II           GO TO F-MM040-PAGAVA.
      *-------------------------  IMPOSTA CHIAVE CODA T.S.
           MOVE +1      TO WK-INCREM.
       F-MM040-PAGAVA.
           EXIT.
           SKIP3
       MM040-PAGIND.
           IF COMMPAGCOR  =  1
           THEN  MOVE 'PRIMA PAGINA' TO COMMER24
                 GO TO F-MM040-PAGIND.
      *-------------------------  IMPOSTA CHIAVE CODA T.S.
           MOVE -1      TO WK-INCREM.
       F-MM040-PAGIND.
           EXIT.
           SKIP3
      *==============================================================*
      *    MM050 - ACQUISIZIONE DATI                                 *
      *==============================================================*
       MM050.
      *-------------------------  RICEZIONE DELLA MAPPA
           PERFORM RR130 THRU F-RR130.
      *-------------------------  ANALISI MODIFICA DATI
           PERFORM RR140 THRU F-RR140.
      *-------------------------  MERGE COMMAREA
           PERFORM RR150 THRU F-RR150.
       F-MM050.
           EXIT.
           SKIP3
      *==============================================================*
      *    MM060 - RICHIESTA SPIEGAZIONI (OPZIONI ESTERNE)           *
      *==============================================================*
       MM060.
      *-------------------------  SE DATI MODIFICATI - SETUP MAPPA
           IF WKMODDTS
           THEN PERFORM RR350 THRU F-RR350
                PERFORM RR310 THRU F-RR310.
      *-------------------------  IMPOSTAZIONE PGM. SUCCESSIVO
           IF COMMOPTI = WKHELPRQ OR
                         WKHELPER
           THEN  MOVE RBAW005-PGMERR  TO COMMPGSU.
      *-------------------------  SCHEDULAZIONE ALTRE CONVERSAZIONI
           PERFORM RR120 THRU F-RR120.
       F-MM060.
           EXIT.
           SKIP3
      *==============================================================*
      *    MM070 - RICHIESTA STAMPA VIDEO (OPZIONI INTERNE)          *
      *==============================================================*
       MM070.
      *
      *    IF COMMOPTI NOT = WKPRTVID
      *    THEN
      *         GO TO F-MM070.
      *------------------------   SE DATI MODIFICATI ......
      *    IF WKMODDTS
      *         PERFORM RR350 THRU F-RR350
      *         PERFORM RR310 THRU F-RR310
      *         MOVE WKLENCOM TO COMMLENGTH
======*==>      CALL RBPT053 USING COMMAREA
      *         PERFORM RR070 THRU F-RR070
      *-----------------------    ALTRIMENTI ......
      *    ELSE
      *         MOVE WKLENCOM TO COMMLENGTH
======*==>      CALL RBPT053 USING COMMAREA
      *         PERFORM RR300 THRU F-RR300
      *         PERFORM RR070 THRU F-RR070.
      *-------------------------  RISCHEDULAZIONE
      *    PERFORM RR320 THRU F-RR320.
      *
       F-MM070.
           EXIT.
           EJECT
      *==============================================================*
      *    MM080 - ELABORAZIONE DATI - TRANSAZIONE  CON  CONFERMA    *
      *==============================================================*
       MM080.
      *-------------------------  SE DATI MODIFICATI ...
      *                              IMPOSTA EDIT DA TS
      *                              SETUP MAPPA
      *                              INVIO MAPPA
      *                              RISCHEDULAZIONE
           IF  WKMODDTS
           THEN PERFORM RR350 THRU F-RR350
                PERFORM RR310 THRU F-RR310
                PERFORM RR070 THRU F-RR070
                PERFORM RR320 THRU F-RR320
                GO TO F-MM080.
      * ------------------------  SE OPZIONI ERRATE
      *                              INVIO VECCHIA MAPPA
      *                              RISCHEDULAZIONE
           IF  COMMFLG2  = '1'
           THEN PERFORM RR300 THRU F-RR300
                PERFORM RR070 THRU F-RR070
                PERFORM RR320 THRU F-RR320
                GO TO F-MM080.
      *-------------------------  SE DATI GIA' MODIFICATI E
      *                            ULTERIORI MODIFICHE
           IF  COMMFLG3  = '1' AND
               WKMODDTN       AND
               COMMFLG10 = '0'
           THEN PERFORM RR310 THRU F-RR310
                PERFORM RR070 THRU F-RR070
                PERFORM RR320 THRU F-RR320
                GO TO F-MM080.
      * ------------------------  SE DATI MAI MODIFICATI O ERRORI O
      *                           OPZIONI ERRATE ... E NON CANCELLAZ.
      *                              INVIO VECCHIA MAPPA
      *                              RISCHEDULAZIONE
           IF (COMMFLG3  = '0'        OR
               COMMSIER)              AND
               COMMFLG10 = '0'
           THEN PERFORM RR300 THRU F-RR300
COB II          PERFORM RR070 THRU F-RR070
                PERFORM RR320 THRU F-RR320
                GO TO F-MM080.
      *-------------------------  SE CONFERMA NO DIGITATA
           IF (RBMCONFI  NOT EQUAL 'OK')
           AND COMMFLG10 = '1'
           THEN MOVE 'I02'    TO WKERRNUM
                PERFORM RR998 THRU F-RR998
                PERFORM RR060 THRU F-RR060
                PERFORM RR050 THRU F-RR050
                PERFORM RR310 THRU F-RR310
                PERFORM RR070 THRU F-RR070
                PERFORM RR320 THRU F-RR320
                GO TO F-MM080.
      *-------------------------
      *    MOVE '0' TO COMMFLG3.
      *-------------------------  CONTROLLO AGGIORNAMENTO
           PERFORM RR230 THRU F-RR230.
           IF WKAGGIMP
           THEN PERFORM RR060 THRU F-RR060
                PERFORM MM020 THRU F-MM020
                GO TO F-MM080.
      *-------------------------  AGGIORNAMENTO
           PERFORM RR250 THRU F-RR250.
      *-------------------------  ANALISI ERRORI
           PERFORM RR060 THRU F-RR060.
      *-------------------------  PASSAGGIO DATI
           PERFORM RR260 THRU F-RR260.
      *-------------------------  SCRITTURA LOG
           IF COMMSILAR
              MOVE    WK-NMFIL TO RBAR013-ARCHIVIO
              MOVE    'FINE' TO   RBAR013-FUNZIONE
              MOVE    SPACE  TO   RBAR013-CHIAVE-ARC
              PERFORM RR900  THRU F-RR900.
      *-------------------------  SCRITTURA LOG
           IF COMMSILST
              MOVE    WK-NMFIL TO RBARLOG-ARCHIVIO
              MOVE    'FINE' TO   RBARLOG-FUNZIONE
              MOVE    SPACE  TO   RBARLOG-CHIAVE-ARC
              PERFORM RR910  THRU F-RR910.
      *-------------------------  ATTIVAZIONE ALTRI TASK
           PERFORM RR270 THRU F-RR270.
      *-------------------------  OPERAZIONI FINALI
           PERFORM RR280 THRU F-RR280.
      *-------------------------  SCHEDULAZIONE FINALE
           PERFORM RR290 THRU F-RR290.
       F-MM080.
           EXIT.
           EJECT
      *==============================================================*
      *    RR030 - OPERAZIONI INIZIALI/IMPOSTAZIONE EDIT             *
      *==============================================================*
       RR030.
      *-------------------------  PULISCI TABELLA ERRORI
NEWNAT     IF COMMPGPR EQUAL 'NCHUT100'
NEWNAT        MOVE 1     TO COMMPAGCOR
NEWNEW        MOVE 10    TO COMMPAGTOT
NEWNEW        MOVE 100   TO ORMAX
NEWNAT        GO TO F-RR030.
           MOVE SPACE TO COMMUTED
                         WK-VAR.
           MOVE ZERO  TO COMMUTOR.
           MOVE 1     TO COMMPAGCOR.
NEWNEW     MOVE 10    TO COMMPAGTOT.
NEWNEW     MOVE 100   TO ORMAX.
      *-------------------------  CANCELLAZIONE CODA T.S.
      *---                        SE RIMASTA IMPOSTATA
           MOVE SPACE             TO STCWIODB.
           MOVE TSQUEUE-NAME      TO STCWIODB-SEGMENTO.
           MOVE '01'              TO STCWIODB-RIFERIMENTO.
           MOVE WKCODTS           TO STCWIODB-TSTRANSID-KEY.
           MOVE COMMCTRM          TO STCWIODB-TSTERMID-KEY.
           MOVE DELETETS          TO STCWIODB-FUNZ.
           MOVE WK-QIDERR         TO STCWIODB-RC-OK (1).
           PERFORM M901 THRU F-M901.
      *-------------------------------  IMPOSTO PARAMETRI CODA T.S.
       CONT-RR030.
           PERFORM RR030-CREA-TS THRU F-RR030-CREA-TS
                   VARYING TSITEM FROM 1 BY 1
NEWNAT             UNTIL TSITEM GREATER 10.
       F-RR030.
           EXIT.
           EJECT
      *================================================================*
       RR030-CREA-TS.
           MOVE SPACE          TO WK-VAR.
           PERFORM RR030-WRTTS THRU F-RR030-WRTTS.
       F-RR030-CREA-TS.
           EXIT.
      *================================================================*
      *    SCRITTURA CODA DI T.S. CON MAPPA SALVATA                    *
      *================================================================*
       RR030-WRTTS.
           MOVE 760                TO TSLENG.
      *-------------------------  SCRITTURA DEL RECORD DI CODA T.S.
           MOVE SPACE              TO STCWIODB
           MOVE TSITEM-NAME        TO STCWIODB-SEGMENTO
           MOVE '03'               TO STCWIODB-RIFERIMENTO
           MOVE WRITETS            TO STCWIODB-FUNZ
           MOVE WKCODTS            TO STCWIODB-TSTRANSID-KEY.
           MOVE COMMCTRM           TO STCWIODB-TSTERMID-KEY.
           MOVE TSITEM             TO STCWIODB-TSITEM-KEY.
           MOVE WK-VAR             TO STCWIODB-AREAIO.
           MOVE TSLENG             TO STCWIODB-RECLEN.
           PERFORM M901 THRU F-M901.
       F-RR030-WRTTS.
           EXIT.
      *==============================================================*
      *    RR040 - SALVA DATI INIZIALI                               *
      *                  DATI MAPPA FISSI                            *
      *                  DATI MAPPA VARIABILI                        *
      *                  DATI MAPPA DECODIFICA                       *
      *                  DATI PER VALIDAZIONI                        *
      *                  DATI DELL'IMMAGINE SEGMENTI                 *
      *==============================================================*
       RR040.
           MOVE COMMITER               TO WK-PERCORSO-1.
           MOVE 1                      TO WK-PERCORSO (COMMLMEN).
      *-------------------------  IMPOSTO CURSORE
           MOVE CURSOR                 TO RBMFILEL.
      *------
       F-RR040.
           EXIT.
           SKIP3
      *==============================================================*
      *    RR050 - ANALISI FORMALE DATI EDIT                         *
      *            PERSONALIZZATA DA UTENTE                          *
      *==============================================================*
       RR050.
      *-------------------------  PULISCE TABELLA ERRORI
           MOVE SPACE TO COMMERXX
           MOVE ZERO  TO WKERRNUM
      *-------------------------  ANALISI FORMALE DATI
      *-------------------------  CONTROLLO PRIORITA' MESSAGGIO
           IF EDPRIO NOT EQUAL '0' AND '1' AND '2'
              MOVE '107'      TO WKERRNUM
              PERFORM RR998 THRU F-RR998
              MOVE CURSOR     TO RBMPRIOL
              MOVE NCHAUABM   TO RBMPRIOA
           ELSE
              MOVE NCHAUANM   TO RBMPRIOA
              MOVE EDPRIO     TO ORPRIO.
      *---------------------------AGGIORNO CODA DI TS
           PERFORM RR355 THRU F-RR355.
           IF COMMERXX NOT EQUAL SPACES
              GO TO  F-RR050.
           COMPUTE COMMPAGCOR = COMMPAGCOR + WK-INCREM.
      *-------------------------  SE TUTTO O.K. MEMORIZZAZIONE DATI
       F-RR050.
           EXIT.
      *==============================================================*
           EJECT
      *==============================================================*
      *    RR060 - ANALISI ERRORI                                    *
      *            METTE SU RIGA-23 DEL VIDEO GLI ERRORI             *
      *==============================================================*
       RR060.
           COPY RBAP183.
           EJECT
      *==============================================================*
      *    RR070 - INVIO MAPPA NUOVA                                 *
      *==============================================================*
       RR070.
           MOVE LOW-VALUE          TO COMMER23
                                      COMMER24.
VVVVVV*    DISPLAY 'MAPPID =' WKMAPPID '  ---->  MAPSET=' WKMAPSET
VVVVVV*    DISPLAY 'ISRT MAPPA=' RBMUT10O
      *------------------------- SPEDIZIONE DELLA MAPPA
           MOVE SPACE                   TO STCWIODC
           MOVE WKSEND                  TO STCWIODC-SWSEND
           CALL 'RBPT911' USING RBMUT10O STCWIODC-ADRIOAREA.
           MOVE WKMAPPID                TO STCWIODC-MAP
           MOVE WKMAPSET                TO STCWIODC-MAPSET
           MOVE 'XS'                    TO STCWIODC-RIFERIMENTO
           MOVE SENDMAP                 TO STCWIODC-FUNZ
           MOVE WKLENMAP                TO STCWIODC-LEN.
           PERFORM M902 THRU F-M902.
       F-RR070.
           EXIT.
           EJECT
      *==============================================================*
      *    RR120 - SCHEDULAZIONE ALTRE CONVERSAZIONI                 *
      *==============================================================*
       RR120.
           MOVE LOW-VALUE TO COMMER23
                             COMMER24.
           MOVE '1'       TO COMMTCTR.
           MOVE WKPGRMID  TO COMMPGPR.
      *    MOVE WKTRANID  TO COMMTRSU.
           MOVE WKLENCOM  TO COMMLENGTH.
       F-RR120.
           EXIT.
           EJECT
      *==============================================================*
      *    RR130 - RECEIVE MAPPA (SOLO CICS)                         *
      *==============================================================*
       RR130.
      *------------------------- CALCOLO INDIRIZZO MAPPA
           MOVE SPACE              TO STCWIODC
           CALL 'RBPT911' USING RBMUT10I STCWIODC-ADRIOAREA.
           COPY RBAP170.
       F-RR130.
           EXIT.
      *==============================================================*
      *    RR140 - ANALISI MODIFICA DATI                             *
      *            SE NESSUN DATO E' STATO DIGITATO IMPOSTARE IL     *
      *            CAMPO WKMODDAT A '0'  ALTRIMENTI AD '1'           *
      *==============================================================*
       RR140.
           IF RBMFILEI = EDFILE AND
              RBMPRIOI = EDPRIO AND
              RBMCAPPI = EDCAPP
              MOVE '0'         TO WKMODDAT
           ELSE
              MOVE '1'         TO WKMODDAT
                                  COMMFLG3.
           PERFORM RR140-L THRU F-RR140-L
                   VARYING WK-IND FROM 1 BY 1
                   UNTIL WK-IND GREATER 10.
       F-RR140.
           EXIT.
       RR140-L.
           IF WKRIGA(WK-IND) = EDRIGA (WK-IND)
              NEXT SENTENCE
           ELSE
              MOVE '1'         TO WKMODDAT
                                  COMMFLG3.
       F-RR140-L.
           EXIT.
           SKIP3
      *==============================================================*
      *    RR150 - MERGE COMMAREA                                    *
      *            SE UN DATO SUL VIDEO E' MODIFICATO, QUESTI E'     *
      *            TRASFERITO NEL CORRISPONDENTE CAMPO IN FORMATO    *
      *            EDIT DELLA COMMAREA.                              *
      *==============================================================*
       RR150.
           IF RBMFILEI NOT = EDFILE
               IF  RBMFILEI = LOW-VALUE
                    MOVE SPACE    TO EDFILE
                ELSE
                    MOVE RBMFILEI TO EDFILE.
           IF RBMPRIOI NOT = EDPRIO
               IF  RBMPRIOI = LOW-VALUE
                    MOVE SPACE    TO EDPRIO
                ELSE
                    MOVE RBMPRIOI TO EDPRIO.
           IF RBMCAPPI NOT = EDCAPP
               IF  RBMCAPPI = LOW-VALUE
                    MOVE SPACE    TO EDCAPP
                ELSE
                    MOVE RBMCAPPI TO EDCAPP.
           PERFORM RR150-CICLO THRU F-RR150-CICLO
                   VARYING WK-IND1 FROM 1 BY 1
                   UNTIL WK-IND1 GREATER 10.
       F-RR150.
           EXIT.
       RR150-CICLO.
           IF WKRIGA(WK-IND1) NOT EQUAL EDRIGA(WK-IND1)
               IF  WKRIGA(WK-IND1) = LOW-VALUE
                    MOVE SPACE               TO EDRIGA(WK-IND1)
                ELSE
                    MOVE WKRIGA(WK-IND1)     TO EDRIGA(WK-IND1).
       F-RR150-CICLO.
           EXIT.
           EJECT
      *==============================================================*
      *    RR230 - CONTROLLO AGGIORNAMENTO.                          *
      *            ESEMPIO DI VERIFICA CHE I DATI DA AGGIORNARE NON  *
      *            SIANO STATI ALTERATI DA ALTRE CONVERSAZIONI  CON- *
      *            CORRENTI.                                         *
      *==============================================================*
       RR230.
      *-------------------------  PRELEVO PROGRESSIVO MESSAGGIO
           MOVE ZERO           TO RBARRIC-DATA-ZERO
                                  RBARRIC-PRO-ZERO.
           MOVE SPACE          TO WK-STATUS-KEY.
           MOVE EDFILE         TO WK-NMFIL.
      *---
           PERFORM READ-FILE-UPD THRU F-READ-FILE-UPD.
      *---
           IF KEY-NOTFND
              MOVE '117'      TO WKERRNUM
              PERFORM RR998 THRU F-RR998
              MOVE  CURSOR    TO RBMFILEL
              MOVE  '0'       TO WKPOSAGG
              GO TO F-RR230.
G2A000*    IF COMMDAY2 LESS RBARRIC-DATA-ULT
G2A000*       MOVE '044' TO WKERRNUM
G2A000*       PERFORM RR998 THRU F-RR998
G2A000*       MOVE  CURSOR    TO RBMFILEL
G2A000*       MOVE  '0'       TO WKPOSAGG
G2A000*       GO TO F-RR230
G2A000*     ELSE
              IF COMMDAY2 EQUAL RBARRIC-DATA-ULT
                 COMPUTE COMMPROG = RBARRIC-PRO-ULT + 1
                 MOVE  RBARRIC-DATA-ULT    TO COMMDAT
              ELSE
G2A000*          IF COMMDAY2 GREATER RBARRIC-DATA-ULT
                    MOVE    1              TO COMMPROG
                    MOVE  COMMDAY2         TO COMMDAT.
      *-------------------------  RISCRIVO PILOTA CON PROGR. MESSAGGIO
                MOVE COMMDAT     TO RBARRIC-DATA-ULT
                MOVE COMMPROG    TO RBARRIC-PRO-ULT
      *-----
           MOVE RBARRIC-RECORD-ZERO   TO WK-RICOUT
      *-------------------------  RISCRITTURA MESSAGGIO
           MOVE SPACES              TO STCWIODB.
           MOVE EDFILE              TO STCWIODB-SEGMENTO.
           MOVE '04'                TO STCWIODB-RIFERIMENTO.
           MOVE REWRITER            TO STCWIODB-FUNZ.
           MOVE LEN-ZERO            TO STCWIODB-RECLEN.
           MOVE WK-RICOUT           TO STCWIODB-AREAIO.
           MOVE RBARRIC-KEY-ZERO    TO STCWIODB-CHIAVE1.
           MOVE WK-INVREQ           TO STCWIODB-RC-OK (1)
           MOVE WK-LENGERR          TO STCWIODB-RC-OK (2)
           PERFORM M901 THRU F-M901.
      *----
           IF STCWIODB-RC  = WK-INVREQ OR WK-LENGERR
              GO TO ERRORE-PILOTA.
      *----
      *-----
           MOVE SPACES            TO COMMERXX.
           MOVE '1'     TO WKPOSAGG.
           MOVE 'IOK'   TO WKERRNUM.
           PERFORM RR998  THRU  F-RR998.
           GO TO F-RR230.
       ERRORE-PILOTA.
           MOVE SPACES  TO COMMERXX.
           MOVE '0'     TO WKPOSAGG.
           MOVE '001'   TO WKERRNUM.
           PERFORM RR998  THRU  F-RR998.
      *-------------------------  FASE DI SBLOCCO DEL RECORD
      *----
           MOVE SPACE                 TO STCWIODB
           MOVE EDFILE                TO STCWIODB-SEGMENTO
           MOVE '05'                  TO STCWIODB-RIFERIMENTO
           MOVE UNLOCK                TO STCWIODB-FUNZ
           PERFORM M901 THRU F-M901.
      *----
       F-RR230.
           EXIT.
           SKIP3
      *--------------------------------------------------------------*
       READ-FILE-UPD.
           MOVE LEN-RIC               TO LEN-ZERO.
      *-------------------------  LETTURA DIRETTA DEL RECORD
      *----                       CON CHIAVE PRIMARIA
           MOVE SPACE                 TO STCWIODB
           MOVE LEN-ZERO              TO STCWIODB-RECLEN.
           MOVE EDFILE                TO STCWIODB-SEGMENTO
           MOVE '06'                  TO STCWIODB-RIFERIMENTO
           MOVE READUPD               TO STCWIODB-FUNZ
           MOVE 'EQ'                  TO STCWIODB-OPERATORE
           MOVE RBARRIC-KEY-ZERO      TO STCWIODB-CHIAVE1
           MOVE WK-NOTFND             TO STCWIODB-RC-OK (1)
           PERFORM M901 THRU F-M901.
      *----
           IF STCWIODB-RC  = WK-NOTFND
              GO TO NOTFND-PILOTA-UPD.
      *----
           MOVE STCWIODB-AREAIO    TO RBARRIC-RECORD-ZERO.
           MOVE STCWIODB-RECLEN    TO LEN-ZERO.
           GO TO F-READ-FILE-UPD.
       NOTFND-PILOTA-UPD.
           MOVE 'N' TO WK-STATUS.
       F-READ-FILE-UPD.
           EXIT.
           SKIP3
      *================================================================*
      *    RR250 - AGGIORNAMENTO                                     *
      *==============================================================*
       RR250.
      *==============================================================*
       IMPO-REC.
      *-------------------------  IMPOSTO CAMPI NEL RECORD X CONTROLLI
           MOVE SPACES    TO RBARRIC-RECORD.
           MOVE ZERO      TO RBARRIC-LL
                             RBARRIC-TIPRECB
                             RBARRIC-NSESB
                             RBARRIC-NSEQB
MG0394*                      RBARRIC-ACTAZB
MG0394*                      RBARRIC-RCPB
                             RBARRIC-PRTVB
                             RBARRIC-TIPB
                             RBARRIC-LLMAB
                             RBARRIC-TIPRECM
                             RBARRIC-DATAM
                             RBARRIC-NSESM
                             RBARRIC-NSEQM
                             RBARRIC-ORAM
                             RBARRIC-NSESIM
                             RBARRIC-NSEQIM
                             RBARRIC-ORAIM
                             RBARRIC-CONFM.
           MOVE RBARRIC-DATI-ZERO    TO RBARRIC-KEY.
           MOVE EDCAPP               TO RBARRIC-ICCTGAPM.
           MOVE '12345678901     '   TO RBARRIC-TURM.
           MOVE '12928MIP0301'       TO RBARRIC-IDAUMITB.
           MOVE '01000RMP0101'       TO RBARRIC-IDAUDESB.
           MOVE ORPRIO               TO RBARRIC-PRIYM.
MG0394     MOVE COMMDAY2             TO WK-TIMBRO-COMMDAY2.
MG0394     MOVE COMMTIME             TO WK-TIMBRO-COMMTIME.
MG0394     MOVE WK-TIMBRO-COMMAREA   TO RBARRIC-ACTAZB
MG0394                                  RBARRIC-RCPB.
           MOVE 1         TO WK-IND.
           MOVE 11        TO WK-IND1.
      *-------------------------------  IMPOSTO ITEM CODA T.S.
           MOVE 1                  TO TSITEM.
       IMPO-CICLO-RR250.
           IF WK-IND GREATER ORMAX
                 GO TO  F-IMPO-CICLO-RR250.
           IF WK-IND1   GREATER 10
           THEN MOVE SPACES              TO WK-VAR
                MOVE SPACES              TO WK-STATUS-KEY
      *-------------------------------  LETTURA CODA DI T.S.
                PERFORM RR350-READTS THRU F-RR350-READTS
MMMMMM*         DISPLAY 'AREA LETTA CON TSITEM ' TSITEM
MMMMMM*         DISPLAY WK-VAR
                ADD    1                 TO TSITEM
                MOVE   1                 TO WK-IND1.
      *
NEWNEW     IF   WK-IND GREATER 100
                GO TO F-IMPO-CICLO-RR250.
           IF   WK-RIGA (WK-IND1) NOT EQUAL SPACE AND LOW-VALUE
                MOVE WK-RIGA (WK-IND1) TO WK-RIGA-ELE
                PERFORM RICERCA THRU F-RICERCA
                ADD 1            TO WK-IND
                                    WK-IND1
                GO TO IMPO-CICLO-RR250
           ELSE
                GO TO F-IMPO-CICLO-RR250.
       F-IMPO-CICLO-RR250.
      *---
           MOVE WK-IND-PRIM      TO RBARRIC-LLMABB.
           MOVE WK-RECOUT        TO RBARRIC-MAB.
           MOVE RBARRIC-RECORD   TO WK-RICOUT.
           COMPUTE LUNGHEZZA = WK-IND-PRIM + 295.
           EXEC CICS ENTER TRACEID (3) FROM(LUNGHEZZA) END-EXEC.
      *-------------------------  SCRITTURA MESSAGGIO
           MOVE SPACES              TO STCWIODB.
           MOVE EDFILE              TO STCWIODB-SEGMENTO.
           MOVE '08'                TO STCWIODB-RIFERIMENTO.
           MOVE WRITER              TO STCWIODB-FUNZ.
           MOVE LUNGHEZZA           TO STCWIODB-RECLEN.
           MOVE WK-RICOUT           TO STCWIODB-AREAIO.
           MOVE RBARRIC-KEY         TO STCWIODB-CHIAVE1.
      *----
           PERFORM M901 THRU F-M901.
       F-RR250.
            EXIT.
           SKIP3
      *==============================================================*
       RICERCA.
           PERFORM NULLA THRU F-NULLA
               VARYING WK-IND-SEC FROM 76 BY -1
                    UNTIL WK-RIGA-REC (WK-IND-SEC)
                        NOT EQUAL SPACES AND LOW-VALUE.
           ADD 1 TO WK-IND-PRIM.
           MOVE 1 TO WK-I.
       A.
           IF WK-I NOT GREATER WK-IND-SEC
              MOVE WK-RIGA-REC (WK-I) TO WK-REC (WK-IND-PRIM)
              ADD 1 TO WK-I  WK-IND-PRIM
              GO TO A
           ELSE
              MOVE VAL-ESAD  TO WK-REC(WK-IND-PRIM).
       F-RICERCA.
      *==============================================================*
      *    RR260 - PASSAGGIO DATI AL PGM SUCCESSIVO                  *
      *            PREPARAZIONE DATI COMMAREA DA TRASMETTERE         *
      *==============================================================*
       RR260.
      *-------------------------  IMPOSTAZIONE COMMAREA
           MOVE  'SONO QUI'        TO COMMFILL.
           MOVE  'COMMUTOR'        TO COMMFILOR.
           MOVE  'COMMUTED'        TO COMMFILED.
       F-RR260.
           EXIT.
           EJECT
      *==============================================================*
      *    RR270 - SCHEDULAZIONE ALTRE TRANSAZIONI                   *
      *            PER ELABORAZIONI ASINCRONE                        *
      *==============================================================*
       RR270.
      *-------------------------  VERIFICA TRANSAZIONE DA SCHEDULARE
      *-------------------------  DI AUTORIZZAZIONE MASSIVA
           IF WKTASSCH = SPACES
              GO TO F-RR270.
      *-------------------------  SCHEDULA TRANSAZIONE
      *    COPY RBAP120.
       F-RR270.
           EXIT.
           EJECT
      *==============================================================*
      *    RR280 - OPERAZIONI FINALI                                 *
      *==============================================================*
       RR280.
NEWNAT     IF COMMOPTI NOT EQUAL WKRICINT AND NOT EQUAL WKRETURN
NEWNAT        GO TO F-RR280.
      *-------------------------  IMPOSTA CHIAVE CODA DI T.S.
      *    MOVE WKCODTS          TO TSTRANSID.
           MOVE COMMCTRM         TO TSTERMID.
      *-------------------------  CANCELLAZIONE DELLA CODA DI T.S.
      *                           SE E' RIMASTA IMPOSTATA
           MOVE SPACE             TO STCWIODB.
           MOVE TSQUEUE-NAME      TO STCWIODB-SEGMENTO.
           MOVE '09'              TO STCWIODB-RIFERIMENTO.
           MOVE WKCODTS           TO STCWIODB-TSTRANSID-KEY.
           MOVE COMMCTRM          TO STCWIODB-TSTERMID-KEY.
           MOVE DELETETS          TO STCWIODB-FUNZ.
           MOVE WK-QIDERR         TO STCWIODB-RC-OK (1).
           PERFORM M901 THRU F-M901.
      *---
       F-RR280.
           EXIT.
           EJECT
      *==============================================================*
      *    RR290 - SCHEDULAZIONE FINALE                              *
      *==============================================================*
       RR290.
           MOVE SPACES    TO COMMNMAT.
      *    MOVE WKTRANID  TO COMMTRSU.
           MOVE WKLENCOM  TO COMMLENGTH.
           MOVE '1'       TO COMMTCTR.
      *=================================================================
      *    DA UTILIZZARE IN ALTERNATIVA  L'UNA ALL'ALTRA
      *=================================================================
      *-------------------------  PER TRANSAZIONI CHE RICICLANO
NEWNAT     MOVE SPACES    TO COMMPGSU.
NEWNAT     MOVE WKPGRMID  TO COMMPGAT.
NEWNAT     MOVE WKPGRMID  TO COMMPGPR.
NEWNAT     PERFORM MM020 THRU F-MM020.
NEWNAT     GO TO F-RR290.
      *=================================================================
      *-------------------------  PER TRANSAZIONI CHE NON RICICLANO
      *---                        CESSIONE CONTROLLO (SOLO CICS)
           MOVE WKPGRMID  TO COMMPGPR.
           MOVE SPACES    TO COMMPGAT.
           MOVE WKPGMSUC  TO COMMPGSU.
      *=================================================================
       F-RR290.
           EXIT.
           EJECT
      *==============================================================*
      *    RR300 - SEND OLD MAPPA                                    *
      *==============================================================*
       RR300.
      *-------------------------  IMPOSTA VECCHIA MAPPA
           MOVE WKLENMAP TO WKLENMAP.
           MOVE COMMDSMV TO RBMUT10O.
      *-------------------------  IMPOSTA NUOVI COMMENTI
           MOVE COMMER23 TO MPERR23I
           MOVE COMMER24 TO MPERR24I.
      *-------------------------  IMPOSTA NUOVI COMMENTI
           MOVE COMMFLG1 TO WKCURSOR.
       F-RR300.
           EXIT.
      *==============================================================*
      *    RR310 - SETUP MAPPA                                       *
      *==============================================================*
       RR310.
           MOVE SPACE           TO RBMDCONO
           MOVE SPACE           TO RBMCONFO
           MOVE NCHAPSD         TO RBMCONFA
           MOVE WK-INIT-L       TO RBMCONFL
           MOVE NCHAPSD         TO RBMDCONA
           MOVE WK-INIT-L       TO RBMDCONL
      *-----
           IF COMMSIER
           OR COMMSIPR
           OR WK-RICPAG EQUAL 'Y'
           OR (COMMFLG3 EQUAL '0' AND WKMODDTN)
      *-----
              MOVE '0'          TO COMMFLG10
           ELSE
              MOVE 'OK - PER CONFERMA '          TO RBMDCONO
              MOVE NCHAPSB      TO RBMDCONA
              MOVE SPACE        TO RBMCONFO
              MOVE NCHAUANM     TO RBMCONFA
              MOVE CURSOR       TO RBMCONFL
              MOVE '1'          TO COMMFLG10.
      *-------------------------  MOVE DA EDIT A CAMPI MAPPA
           MOVE EDFILE          TO RBMFILEO.
           MOVE EDPRIO          TO RBMPRIOO.
           MOVE EDCAPP          TO RBMCAPPO.
           MOVE COMMPAGCOR      TO RBMPAGIO.
           MOVE  1              TO WK-IND.
           PERFORM RR310-CICLO THRU F-RR310-CICLO
                   VARYING WK-IND FROM 1 BY 1
                   UNTIL WK-IND  GREATER 10.
      *-------------------------  RIGA 23 E 24 SU MAPPA
           MOVE COMMER23   TO MPERR23I.
           MOVE COMMER24   TO MPERR24I.
      *-------------------------  POSIZIONE CURSORE
           MOVE WKCURSOR   TO COMMFLG1.
      *-------------------------  SALVO VECCHIA MAPPA
           MOVE WKLENMAP TO WKLENMAP.
           MOVE RBMUT10O TO COMMDSMV.
      *---
           MOVE SPACES   TO WK-RICPAG.
           MOVE SPACES   TO COMMER23.
           MOVE SPACES   TO COMMER24.
       F-RR310.
           EXIT.
       RR310-CICLO.
           IF   EDRIGA (WK-IND)      NOT = SPACE
              MOVE EDRIGA (WK-IND)    TO WKRIGA(WK-IND)
           ELSE
              MOVE SPACE              TO WKRIGA(WK-IND).
       F-RR310-CICLO.
           EXIT.
           EJECT
      *==============================================================*
      *    RR320 - RISCHEDULAZIONE                                   *
      *==============================================================*
       RR320.
      *-------------------------  SETUP NO PRIMA VOLTA
           MOVE '2'        TO COMMTCTR.
           MOVE WKLENCOM   TO COMMLENGTH.
       F-RR320.
           EXIT.
           EJECT
      *==============================================================*
      *    RR350 - IMPOSTA ZONA EDIT DA T.S. PER                     *
      *            PAGINAZIONE VIDEO                                 *
      *==============================================================*
       RR350.
      *-------------------------------  IMPOSTO PARAMETRI CODA T.S.
           MOVE COMMPAGCOR         TO TSITEM.
           MOVE SPACES             TO WK-STATUS-KEY.
           MOVE SPACES             TO EDTABEL.
      *-------------------------------  LETTURA CODA DI T.S.
           PERFORM RR350-READTS THRU F-RR350-READTS.
           IF KEY-NOTFND
              GO TO  F-RR350.
           PERFORM CICLO-VIDEATA THRU F-CICLO-VIDEATA
                   VARYING WK-IND FROM 1 BY 1
                   UNTIL WK-IND  GREATER 10.
       F-RR350.
           EXIT.
       CICLO-VIDEATA.
           MOVE WK-RIGA(WK-IND)        TO EDRIGA(WK-IND).
       F-CICLO-VIDEATA.
           EXIT.
           EJECT
      *================================================================*
      *    LETTURA   CODA DI T.S. CON MAPPA SALVATA                    *
      *================================================================*
       RR350-READTS.
           MOVE 760                TO TSLENG.
           MOVE SPACE              TO STCWIODB.
           MOVE TSITEM-NAME        TO STCWIODB-SEGMENTO.
           MOVE '10'               TO STCWIODB-RIFERIMENTO.
           MOVE WKCODTS            TO STCWIODB-TSTRANSID-KEY.
           MOVE COMMCTRM           TO STCWIODB-TSTERMID-KEY.
           MOVE READTS             TO STCWIODB-FUNZ.
           MOVE TSITEM             TO STCWIODB-TSITEM-KEY.
           MOVE WK-ITEMERR         TO STCWIODB-RC-OK (1).
           MOVE WK-QIDERR          TO STCWIODB-RC-OK (2).
           MOVE WK-VAR             TO STCWIODB-AREAIO.
           MOVE TSLENG             TO STCWIODB-RECLEN.
           PERFORM M901 THRU F-M901.
           IF STCWIODB-RC  =  WK-ITEMERR
              GO TO READTS-ERR.
      *--
           MOVE STCWIODB-AREAIO    TO WK-VAR.
           GO TO F-RR350-READTS.
       READTS-ERR.
           MOVE 'N'             TO WK-STATUS-KEY.
       F-RR350-READTS.
           EXIT.
           SKIP3
      *==============================================================*
      *    RR355 - IMPOSTA CODA DI T.S. CON NUOVI VALORI             *
      *==============================================================*
       RR355.
      *-------------------------  IMPOSTO DATI PER UPDATE T.S.
           MOVE 760                TO TSLENG.
           MOVE SPACE              TO STCWIODB.
           MOVE TSITEM-NAME        TO STCWIODB-SEGMENTO.
           MOVE '11'               TO STCWIODB-RIFERIMENTO.
           MOVE WKCODTS            TO STCWIODB-TSTRANSID-KEY.
           MOVE COMMCTRM           TO STCWIODB-TSTERMID-KEY.
           MOVE READTS             TO STCWIODB-FUNZ.
           MOVE COMMPAGCOR         TO STCWIODB-TSITEM-KEY.
           MOVE WK-NOTFND          TO STCWIODB-RC-OK (1).
           MOVE WK-QIDERR          TO STCWIODB-RC-OK (2).
           MOVE WK-VAR             TO STCWIODB-AREAIO.
           MOVE TSLENG             TO STCWIODB-RECLEN.
           PERFORM M901 THRU F-M901.
           IF STCWIODB-RC  = WK-NOTFND
              GO TO F-RR355.
      *--
           MOVE SPACES          TO WK-VAR.
           PERFORM RR355-A     THRU F-RR355-A
                   VARYING WK-IND FROM 1 BY 1
                   UNTIL   WK-IND GREATER 10.
      *-------------------------  SCRITTURA DEL RECORD DI CODA T.S.
           MOVE SPACE              TO STCWIODB
           MOVE COMMPAGCOR         TO TSITEM
           MOVE TSITEM-NAME        TO STCWIODB-SEGMENTO
           MOVE '12'               TO STCWIODB-RIFERIMENTO
           MOVE REWRITETS          TO STCWIODB-FUNZ
           MOVE WKCODTS            TO STCWIODB-TSTRANSID-KEY.
           MOVE COMMCTRM           TO STCWIODB-TSTERMID-KEY.
           MOVE TSITEM             TO STCWIODB-TSITEM-KEY.
           MOVE WK-VAR             TO STCWIODB-AREAIO.
           MOVE TSLENG             TO STCWIODB-RECLEN.
           PERFORM M901 THRU F-M901.
       F-RR355.
           EXIT.
       RR355-A.
           MOVE EDRIGA (WK-IND)       TO WK-RIGA (WK-IND).
       F-RR355-A.
           EXIT.
           EJECT
      *==============================================================*
      *    RR900 - SCRITTURA LOG                                     *
      *==============================================================*
       RR900.
           COPY RBAP008.
      *==============================================================*
      *    RR910 - STAMPA    LOG                                     *
      *==============================================================*
       RR910.
           COPY RBAP010.
      *==============================================================*
      *    RR998 - IMPOSTA CODICI ERRORI IN TABELLA COMMERXX         *
      *==============================================================*
       RR998.
           COPY  RBAP184 .
      *==============================================================*
      *    M062  - ROUTINE DI CONTROLLO NUMERICITA'                  *
      *==============================================================*
       M062.
           COPY  RBAP062 .
      *==============================================================*
      *    M063  - ROUTINE DI CONTROLLO E TRASFORMAZIONE DATA        *
      *==============================================================*
       M063.
           COPY  RBAP063 .
      *==============================================================*
      *    M065  - ROUTINE DI CONVERSIONE DA ESADECIMALE A           *
      *            ZONED                                             *
      *==============================================================*
       M065.
      *    COPY  RBAP065 .
      *==============================================================*
      *    M066  - ROUTINE DI CONTROLLO DELL'ORA                     *
      *==============================================================*
       M066.
           COPY  RBAP066 .
      *==============================================================*
      *    M067  - ROUTINE DI TRASFORMAZIONE DA ZONED A ESADECIMALE  *
      *==============================================================*
       M067.
      *    COPY  RBAP067 .
      *==============================================================*
      *    M070  - ROUTINE DI TRASFORMAZIONE DATA                    *
      *            DA AAMMGG A GGGGG                                 *
      *==============================================================*
       M070.
      *    COPY  RBAP070 .
      *==============================================================*
      *    M071  - ROUTINE DI TRASFORMAZIONE DATA                    *
      *            DA AAMMGG A AAGGG E VICEVERSA                     *
      *==============================================================*
       M071.
           COPY  RBAP071 .
      *==============================================================*
      *    M080  - ROUTINE DI CENTRATURA TESTO                       *
      *==============================================================*
       M080.
           COPY  RBAP080 .
      *==============================================================*
      *    M901  - ROUTINE DI RICHIAMO MODULO I-O D.B.
      *==============================================================*
       M901.
           COPY RBAP901 .
      *==============================================================*
      *    M902  - ROUTINE DI RICHIAMO MODULO I-O D.C.
      *==============================================================*
       M902.
           COPY RBAP902 .
      *==============================================================*
      *    MLINK - ROUTINE DI RICHIAMO PER LINK AD ALTRI PGM.
      *==============================================================*
       MLINK.
      *    BISOGNA AVER IMPOSTATO I SEGUENTI CAMPI:
      *                             LINKPGM
      *                             LINKAREA
      *                             LINKLEN
      *    COPY RBAP903 .
           EJECT
      *==============================================================*
      *    MLINK1 - ROUTINE DI RICHIAMO PER LINK AD ALTRI PGM.
      *==============================================================*
       MLINK1.
      *    BISOGNA AVER IMPOSTATO I SEGUENTI CAMPI:
      *                             LINKPGM
      *                             LINKAREA
      *                             LINKLEN
      *    COPY RBAP904 .
      *===============================================================*
      *    LNK9100 - ROUTINE DI RICHIAMO PGM PER AGGIORNAMENTO TOTALI
      *              PRIMA DI RICHIAMARE QUESTA COPY RICORDARSI DI
      *              IMPOSTARE L'AREA RBAW030 IN MANIERA OPPORTUNA
      *===============================================================*
       LNK9100.
      *    CALL 'RBPT982'  USING  RBAW030 RBAW030-FINE RBAW030-LEN.
      *    MOVE RBAW030-LEN       TO LINKLEN.
      *    MOVE RBAW030-PGM       TO LINKPGM.
      *    MOVE RBAW030           TO LINKAREA.
      *    PERFORM MLINK1 THRU F-MLINK1.
      *    MOVE LINKAREA          TO RBAW030.
      *    IF RBAW030-RC = '*'
      *    THEN GO TO MAINERX.
       F-LNK9100.
           EXIT.
      *==============================================================*
       NULLA.
       F-NULLA.
           EXIT.
      *==============================================================*
      *    -----------  E N D   O F   P R O G R A M  -----------     *
      *==============================================================*
