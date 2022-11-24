       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZMP00000.
      ***************************************************************
      * DATAMAT SPA - AREA PRODOTTI BANCARI                        **
      ***************************************************************
      ***************************************************************
      * PROGETTO         : SISEB III                               **
      * SOTTOPROGETTO    : FUNZIONI COMUNI TP                      **
      * CODICE PROGRAMMA : ZMP00000                                **
      * DESCRIZIONE      : ACCESSO ALLA PROCEDURA                  **
      *                  : VERSIONE CON SICUREZZA BANCO POSTA      **
      *                  : VIENE FORZATO L'ISTITUTO 7601           **
      * DATA STESURA     : FEBBRAIO 2004                           **
      *------------------------------------------------------------**
      * REVISIONE NUM.   : BPO104                                  **
      *           DATA   : 12/12/2004                              **
      *           MOTIVO : GESTIONE FILIALE DIVERSA DA 311         **
      *------------------------------------------------------------**
      * REVISIONE NUM.   : BPO134                                  **
      *           DATA   : 10/02/2005                              **
      *           MOTIVO : PER IL PROFILO TESORERIA 'ESTEROUT'     **
      *                    E PER IL CENTRO CAMBI 'ESTEROUC' E' PER **
      *                    NUOVO PROFILO TESORERIA ESTERTES'       **
      *                    NECESSARIO FORZARE LA FILIALE 77222     **
      * BPO305 I-28112005 CONTROLLO TRA TERMINALE ED UTENZA        *
      * FAB01  I-21022010 RICOMPILATO                              *
      * BPO942 I-03062013 GESTIONE ALFANUMERICA                    *
      * BPO962 I-03062013 GESTIONE PROFILO RECETITO DIPENDENZA     *
      *                   ALFANUMERICA                             *
      * BPO968 I-04032014 GESTIONE PROFILO MONIFROD E DIP  02C3Z   *
      *                   VALIDA ANCHE PER RECETITO                *
      * BPO966 I-04032014 GESTIONE PARAMETRICA PROFILI             *
      * BPO975 I-22012015 INTERFACCIA DEPOSITI ASTERISCATA         *
      *                   ATTENZIONE !!!!!!!BPO975 ASTERISCATA
      *              CHIAMATA DISATTIVATA PER ATTIVARLA DISASTERICARE
      * BPOA07 I-VERIFICA FILIALI ACCORPANTI ACCORPATA
      *          SOLO PER LE FILIALI ALFANUMERICHE
      * BPOA12 I-AGGIUNTO TEST CODICE RITORNO NEGATIVO
      *          DIVERSO DA ERRORE DI SISTEMA
      * BPOA15 I-11102016 ASTERISCATA INTERFACCIA DEPOSITI TERRIT
      * BPOA15 VALORIZATO I W-TIME PRIMA DELLA CHIAMATA AL PGM
      *        CHE FORZA LA FILIALE
      * IM0001 MODIFICHE PER ISTITUTO FISSO
      ***************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       77  I1                     PIC 9999     VALUE ZEROES.
       77  I2                     PIC 9999     VALUE ZEROES.
BPO942 77  WRK-FILALFNUM          PIC 9(5)     VALUE 0.
BPO975*77  WRK-ZFILDEP            PIC X(25)    VALUE SPACES.
BPO966 77  WK-CUTE                PIC S9(5) COMP-3 VALUE 0.
       77  WRK-COMODO-MATR        PIC X(8)     VALUE SPACES.
       77  WRK-FOUND-ABILITA      PIC X(2)     VALUE SPACES.
000081 77  WRK-DCLTBTABUTE        PIC X(216)   VALUE SPACES.
       77  WRK-ERRORI             PIC XX       VALUE 'NO'.
           88  WRK-ERRORE-NO                   VALUE 'NO'.
           88  WRK-ERRORE-SI                   VALUE 'SI'.
       01  WRK-DIPENDENZA         PIC 9(5).
       01  WRK-UTENTE             PIC X(8).
       01  WRK-TERMINALE          PIC X(8).
       01  WRK-PROFILO            PIC X(8).
       01  WORK-PSW.
           03  ELE-PSW            PIC X        OCCURS 8.
       01  CRIPT-PSW.
           03  C-ELE-PSW          PIC X        OCCURS 8.
       01  NOMECOGN.
           03  COGNOME            PIC X(15).
           03  NOME               PIC X(10).
      *--------------------------------------------------------------*
      * AREA UTILIZZATA DAL PROGRAMMA DI ACCESSO CON SICUREZZA       *
      * ESTERNA PER AGGANCIARE LA ROUTINE SIPRACF                    *
      *--------------------------------------------------------------*
           COPY SIPRACFA.
BPOA15*    COPY ZMWCASV1.
BPOA07     COPY CAM10FI.

NEW    01  AREA-TP-TSS.
      *------------  AREA PER GESTIONE SICUREZZA ESTERNA ------------*
            03  TSS-LL         PIC  S9(4) COMP.
            03  TSS-ZZ         PIC  S9(4) COMP.
            03  TSS-CTRAN      PIC  X(08).
            03                 PIC  X(01).
            03  TSS-CPROFILO   PIC  X(08).
            03  TSS-FILIALE    PIC  9(04).
            03                 PIC  X(140).

      *------   AREA DI WORKING PER CHIAMATE DL/I (IMS)--------------*
           COPY ZMWDLIFU.
      *------   AREA DI WORKING COMUNE ------------------------------*
           COPY ZMWCOMUN.
      *--------  AREA DI WORKING PER  ERRORI SQL  --------------------*
           COPY ZMWSQLRC.
      *----  AREA DI WORKING PER CONTROLLI NUMERICI ------------------*
           COPY ZMWCTRNM.
      *------   AREA DI WORKING PER ABEND DB2      -------------------*
       01 ZMWM9999.
           COPY ZMWM9999.
      *------   AREA DI WORKING PER ABEND CICS     -------------------*
           COPY ZMWM9997.
      *------   AREA DI WORKING PER CONVERSIONI DATE -----------------*
           COPY ZMWCTRDT.
      *----  AREA DI WORKING PER ATTRIBUTI --------------------------*
           COPY ZMWATTRB.
      *----  AREA DI WORKING PER TRASCODIFICA PASSWORD --------------*
           COPY ZMWTRPSW.
      *----  AREA DA PASSARE A ZMP00000 SE VIENE STARTATO DA --------*
      *----  UN MENU' DI PRESENTAZIONE (VALE PER IL CICS) -----------*
       01  WRK-LENGHT               PIC S9(4) COMP.
       01  WRK-AREA                 PIC X(10).
      *----  DEFINIZIONE TABELLA ABILITAZIONE PFKEYS  ---------------*
       01  TAB-PFK.
           03   PFK                 PIC X     OCCURS 24.
      *--------------------------------------------------------------*
      *----  DEFINIZIONE AREA PER TP MONITOR  -----------------------*
      *--------------------------------------------------------------*
      *----  RICERCA CODICE TRANSAZIONE E IDENTIFICATORE ------------*
           COPY ZMWIDECR.
      *----  AREA DATI TRANSITO A DISPOSIZIONE ----------------------*
       01  CMTER-DATI.
           03                              PIC X(004).
           03  CMTER-DATI-TRAN.
               05  CMTER-NEWPSW            PIC X(008).
               05  CMTER-PASSWORD          PIC X(008).
               05  CMTER-MATRICOLA         PIC X(008).
BPOA07         05  CMTER-DIPOPEXFO         PIC X(005).
BPOA07         05  CMTER-DIPOPEXPR         PIC X(005).
BPOA07         05  CMTER-RESTO             PIC X(166).
BPOA07*        05  CMTER-RESTO             PIC X(176).
           03  CMTER-TABELLA-RITORNO.
               05  CMTER-WORK OCCURS 10.
                   07  CMTER-CPCS-PREC     PIC X(004).
                   07  CMTER-AREA-RIT      PIC X(200).
           03                              PIC X(135).
           03  CMTER-TAB-COD-ERR           PIC X(060).
           03  CMTER-TAB-COD-ERR-1         PIC X(060).
           03  CMTER-FASE-LAVORO           PIC X(001).
      *--- FINE VARIAZIONE DEL 25/10/95 ---***--- BARBARA

      *----  COPY AREA DI COMUNICAZIONE PER PASSAGGIO DATI ----------*
           COPY ZMWCOM02.
BPOA07     COPY ZMWCB440.

IM0001     COPY ZMWN2042.
      *----  AREA COMUNE STANDARD MAPPE TP MONITOR ------------------*
           COPY ZMXMPSTD.
      *-- RIDEFINIZIONE SPECIFICA MESSAGGIO DI INPUT E DI OUTPUT  ---*
           COPY ZMM00000.
      *--------------------------------------------------------------*
      *----  DECLARE DB2  -------------------------------------------*
      *--------------------------------------------------------------*
      *------   SQLCA   ---------------------------------------------*
           EXEC SQL   INCLUDE   SQLCA     END-EXEC.
      *------   AREA COMUNI DB2 -------------------------------------*
           EXEC SQL   INCLUDE ZMICOMUN    END-EXEC.
      *------   TERMINALI...................: ZM.TBTTERMI (221)------*
           EXEC SQL INCLUDE ZMGTERMI END-EXEC.
      *------   COMMAREA PROCESSI...........: ZM.TBWCMTER (311) -----*
           EXEC SQL INCLUDE ZMGCMTER END-EXEC.
      *------                                 ZM.TBTSTPAS   ---------*
      *    EXEC SQL INCLUDE ZMGSTPAS END-EXEC.
      *------   PROCESSI .................. : ZM.WPRCPS (315) -------*
      *------            ...................: ZM.WPRMEN (316) -------*
           EXEC SQL INCLUDE ZMGPRPCS END-EXEC.
           EXEC SQL INCLUDE ZMGPRMEN END-EXEC.
      *------   SALVATAGGIO INPUT  PER HELP : ZM.TPWHLINP (313) -----*
      *------               OUTPUT PER HELP : ZM.TPWHLOUT (314) -----*
           EXEC SQL INCLUDE ZMGHLINP END-EXEC.
           EXEC SQL INCLUDE ZMGHLOUT END-EXEC.
      *------   ISTITUTI....................: ZM.TBTISTI  (304) -----*
           EXEC SQL INCLUDE ZMGISTI  END-EXEC.
      *------   OPERATIVITA' FILIALE........: ZM.TBTOPEFL (308) -----*
           EXEC SQL INCLUDE ZMGOPEFL END-EXEC.
      *------   OPERATIVITA' PER ISTITUTO...: ZM.TBTOPEIS (231) -----*
           EXEC SQL INCLUDE ZMGOPEIS END-EXEC.
      *------   PAGINE PER BROWSE...........: ZM.TBWPRBRW (312) -----*
           EXEC SQL INCLUDE ZMGPRBRW END-EXEC.
      *------   MATRICOLE...................: ZM.TBTABUMA (217) -----*
           EXEC SQL INCLUDE ZMGABUMA END-EXEC.
      *------   PROFILI.....................: ZM.TBTPROFI (223)------*
           EXEC SQL INCLUDE ZMGPROFI END-EXEC.
      *------   ABILITAZIONI ...............: ZM.TBWAUTOR (310) ------*
           EXEC SQL INCLUDE ZMGAUTOR END-EXEC.
      *------   CONFIGURAZIONE .............: ZM.TBWCONFG (309) ------*
           EXEC SQL INCLUDE ZMGCONFG END-EXEC.
      *------   UTENTI FILIALI..............: ZM.TBTABUTE (220) ------*
           EXEC SQL INCLUDE ZMGABUTE END-EXEC.
      *------   ERRORI TECNICI..............: ZM.TBTTRERR (222) ------*
           EXEC SQL INCLUDE ZMGTRERR END-EXEC.
      *------   ERRORI FUNZIONALI...........: ZM.TBTABERR (224) ------*
           EXEC SQL INCLUDE ZMGABERR END-EXEC.
      *------   TIPI FILIALI................: ZM.TBTABLTU (232) -----*
           EXEC SQL INCLUDE ZMGABLTU END-EXEC.
      *------   TABELLA     ................: ZM.TBWINPHE (301) -----*
           EXEC SQL INCLUDE ZMGINPHE END-EXEC.
BPO966*NUOVA TABELLA TBASCUTE (957)  --------------------------------*
BPO966     EXEC SQL INCLUDE ZMGSCUTE END-EXEC.
BPOA07*NUOVA TABELLA TBTLOGFF (961)  --------------------------------*
BPOA07     EXEC SQL INCLUDE ZMGLOGFF END-EXEC.
BPOA07*NUOVA TABELLA TBTCONCV          ------------------------------*
BPOA07     EXEC SQL INCLUDE ZMGCONCV END-EXEC.
      *--------------------------------------------------------------*
      *----  AREA LOG     -------------------------------------------*
      *--------------------------------------------------------------*
           EXEC SQL INCLUDE ZMWLOG01 END-EXEC.
       LINKAGE SECTION.
      *------  DEFINIZIONE IOPCB (SOLO PER IMS)         --------------
      *    COPY ZMXPCBIO.
      *------  DEFINIZIONE ALTPCB (SOLO PER IMS)        --------------
      *    COPY ZMXPCBAL.
       PROCEDURE DIVISION.
       MAIN SECTION.
      *------ GESTIONE ABEND CICS ------------------------------------
           EXEC SQL INCLUDE ZMYHANDL END-EXEC.
      *------  INIZIALIZZAZIONE VARIABILI   --------------------------
           EXEC SQL INCLUDE ZMYINIZW END-EXEC.
      *---------------------------------------------------------------
      * DECODIFICA IDENTIFICATIVO
      *---------------------------------------------------------------
IM0001     PERFORM RECUPERA-CODICE-ABI
IM0001        THRU RECUPERA-CODICE-ABI-END
IM0001     IF WN204-RETC NOT = SPACES
IM0001        MOVE 'TENTATIVO DI ACCESSO ERRATO'   TO TPRIF
IM0001        MOVE 'ZMP00000'                      TO TPPRG
IM0001        MOVE 'SICUREZZA ESTERNA 1'           TO TPSTM
IM0001        MOVE SPACES                          TO TPRETC
IM0001        MOVE 'UTENTE NON ABILITATO (INQ)  '  TO TPARCH
IM0001        PERFORM TP999-ABEND
IM0001           THRU TP999-ABEND-END
IM0001     END-IF.
IM0001*    MOVE 7601           TO WCM-CIST.
TEST00     DISPLAY 'ZMRN2042 WN204-OUT-DCLTBTISTI '
TEST00                       WN204-OUT-DCLTBTISTI
TEST00     DISPLAY 'ZMRN2042 OUT-ISTI-CIST        '
TEST00                       OUT-ISTI-CIST
IM0001     MOVE OUT-ISTI-CIST  TO WCM-CIST.
           DISPLAY 'ZMRN2042 WCM-CIST ' WCM-CIST
           MOVE 0              TO IDECR-CIST.
           MOVE '1'            TO IDECR-TIPRICE.
           MOVE 0000           TO TP-ID
                                  IDECR-VALORE.
           PERFORM TP020-DECOD-ID
              THRU TP020-DECOD-ID-END.
           MOVE IDECR-M-OUTPUT TO  WCM-MAPPA-1.
           MOVE IDECR-FIR-MAP  TO  WCM-MAPPA-2.

      *---------------------------------------------------------------
      * CHIAMA ROUTINE ESTERNA SIPRACF PER PRELEVARE:
      *    - DIPENDENZA, MATRICOLA, CODICE PROFILO, CODICE TERMINALE
      *---------------------------------------------------------------
           MOVE 'SIPRACF'          TO WCM-CHIAMATO
           EXEC CICS LINK
               PROGRAM (WCM-CHIAMATO)
               COMMAREA (SIPRACF-AREA)
           END-EXEC.
           IF SIPRACF-ESITO = ZEROES
BPO966*SOSTITUITE LE IF CON LA NUOVA TABELLA TBASCUTE
BPO966*ENTRATA CON POSIZ-LIV E PROFILO
BPO966*            POSIZ-LIV E PROFILO A SPAZI
BPO966           PERFORM CERCA-DEFAULT
BPO966              THRU CERCA-DEFAULT-END
BPO966              IF W-SQL-OK
BPO966                  MOVE WK-CUTE TO WRK-DIPENDENZA
BPO966              ELSE
BPO966*BPO966 IF SIPRACF-DIP-LIV-USERID = 'DIREZ'
BPO731*BPO966 OR SIPRACF-DIP-LIV-USERID = '25C3Z'
BPO731*BPO966 OR SIPRACF-DIP-LIV-USERID = '63C3Z'
BPO968*BPO966 OR SIPRACF-DIP-LIV-USERID = '02C3Z'
BPO134*BPO966    IF SIPRACF-PROFILO = 'ESTEROUT' OR 'ESTEROUC' OR
BPO134*BPO966                         'ESTERTES'
BPO726*BPO966                         OR 'ESTERTUT'
BPO750*BPO966                         OR 'CONTROL'
BPO134*BPO966       MOVE 77222 TO WRK-DIPENDENZA
BPO134*BPO966    ELSE
BPO731*BPO966       IF SIPRACF-PROFILO = 'ACCERT03' OR 'OPERCUA3'
BPO731*BPO966                         OR 'OPERCUA4' OR 'CONTABSE'
BPO968*BPO966                         OR 'MONIFROD'
BPO731*BPO966           MOVE 55111 TO WRK-DIPENDENZA
BPO731*BPO966       ELSE
      *BPO966           MOVE 00311 TO WRK-DIPENDENZA
BPO731*BPO966       END-IF
BPO134*BPO966    END-IF
BPO104**BPO966ELSE
BPO954*         IF SIPRACF-DIP-LIV-USERID = 'MI100'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'AO000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'BA000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'BR000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'CA000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'CH000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'FG000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'FI100'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'FIA00'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'GR000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'IS000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'LE000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'LU000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'MT000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'PD000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'PE000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'PGA00'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'PI000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'PN000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'PO000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'RM300'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'RM500'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'RO000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'SI000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'SV000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'TA000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'TO000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'TR000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'TS000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'TV000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'UD000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'VE000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'VIA00'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'VR000'
BPO954*         OR SIPRACF-DIP-LIV-USERID = 'VRA00'
BPO954*BPO966   IF (SIPRACF-POSIZ-LIV-USERID = 7
BPO962*BPO966   OR SIPRACF-POSIZ-LIV-USERID = 10) AND
BPO962*BPO966      SIPRACF-PROFILO = 'GIANOS'
BPO954*         OR SIPRACF-POSIZ-LIV-USERID = 10
BPO954*            IF SIPRACF-PROFILO = 'GIANOS'
BPO954*BPO966         MOVE 00311 TO WRK-DIPENDENZA
BPO962*BPO966   ELSE
BPO992*BPO966      IF SIPRACF-POSIZ-LIV-USERID = 5 AND
BPO962*BPO966          SIPRACF-PROFILO = 'RICETITO'
BPO962*BPO966          MOVE 00311 TO WRK-DIPENDENZA
BPO954*BPO966      ELSE
BPO104                MOVE 0        TO WRK-FILALFNUM
BPO104                MOVE SIPRACF-DIP-LIV-USERID TO NM-INPUT
BPO104                MOVE 05                     TO NM-LUNI
BPO104                MOVE ZEROES                 TO NM-LUND
BPO104                MOVE 'N'                    TO NM-MILL
BPO104                PERFORM 9000-CTR-NUM
BPO104                THRU 9000-CTR-NUM-END
BPO104                IF NM-RC NOT = '00'
BPO942                   MOVE SIPRACF-DIP-LIV-USERID TO ABUTE-ZBRCSWF
BPO942                   PERFORM  LEGGI-TABUTE
BPO942                      THRU  LEGGI-TABUTE-END
BPO942                   IF W-SQL-OK
BPOA07*VERIFICA FILIALI ACCORPANTI ACCORPATA
BPOA07*SOLO PER LE FILIALI ALFANUMERICHE
BPOA07*POSIZ-LIV = 07
BPOA07                    IF SIPRACF-POSIZ-LIV-USERID = 7
BPOA07                     PERFORM  LEGGI-FORZA-FIL
BPOA07                        THRU  LEGGI-FORZA-FIL-END
BPOA07
BPOA07                      MOVE ABUTE-CUTE TO WRK-DIPENDENZA
BPOA07                      MOVE ABUTE-CUTE TO WRK-FILALFNUM
BPOA07                    END-IF
BPO975*ATTENZIONE !!!!!!!BPO942 ASTERISCATA
BPO975*CHIAMATA DISATTIVATA PER ATTIVARLA DISASTERICARE
BPO975*DISASTERISCARE      PERFORM  LEGGI-DEPOSITO-TER
BPO975*DISASTERISCARE         THRU  LEGGI-DEPOSITO-TER-END
BPO942                      MOVE ABUTE-CUTE TO WRK-DIPENDENZA
BPO942                      MOVE ABUTE-CUTE TO WRK-FILALFNUM
BPO942                   ELSE
BPO104                     MOVE 'FILIALE NON NUMERICA '         TO TPRIF
BPO942                     MOVE  ABUTE-ZBRCSWF            TO TPRIF(23:5)
BPO104                     MOVE 'ZMP00000'                      TO TPPRG
BPO104                     MOVE 'SICUREZZA ESTERNA'             TO TPSTM
BPO104                     MOVE SPACES                        TO TPRETC
BPO104                     MOVE 'UTENTE NON ABILITATO (INQ)  ' TO TPARCH
BPO966                     MOVE 'LIV.'
BPO966                                                   TO TPARCH(22:4)
BPO966                     MOVE SIPRACF-POSIZ-LIV-USERID TO TPARCH(26:2)
BPO104                     PERFORM TP999-ABEND
BPO104                        THRU TP999-ABEND-END
BPO942                   END-IF
BPO104                ELSE
BPO104                   MOVE SIPRACF-DIP-LIV-USERID TO WRK-DIPENDENZA
BPO104                END-IF
BPO954*BPO966      END-IF
BPO954*BPO966       END-IF
BUTTA         END-IF

              MOVE SIPRACF-USERID         TO WRK-UTENTE
              MOVE SIPRACF-PROFILO        TO WRK-PROFILO
              MOVE SIPRACF-TERMINALE      TO WRK-TERMINALE
              INITIALIZE SIPRACF-AREA
BPO305*       PERFORM VERIFICA-INPHE
BPO305*          THRU VERIFICA-INPHE-END
           ELSE
              MOVE 'TENTATIVO DI ACCESSO ERRATO'   TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'SICUREZZA ESTERNA 2'           TO TPSTM
              MOVE SPACES                          TO TPRETC
              MOVE 'UTENTE NON ABILITATO (INQ)  '  TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
           END-IF.
      *---------------------------------------------------------------
      * RICEZIONE MESSAGGIO (CICS)
      * IN QUESTA COPY VIENE RICHIAMATA LA ROUTINE GESTIONE-INP-OUT
      * PRESENTE NELLA COPY ZMYINOUT
      *---------------------------------------------------------------
      * EX COPY ZMYRICAC (ACCESSO AL SISTEMA)
      *---------------------------------------------------------------
           .
       PARTENZA-NORMALE.
      *    MOVE EIBTRMID         TO  ABL-TER-CODICE.
GIA   *    MOVE ABL-TER-CODICE   TO  WCM-TERMIN.
           MOVE WRK-TERMINALE    TO  WCM-TERMIN.
 "    *----------------------------------------------- COPY ZMYINOUT
 "         PERFORM GESTIONE-INP-OUT
GIA           THRU GESTIONE-INP-OUT-END.

      *---------------------------------------------------------------
      * INIZIALIZZAZIONE VARIABILI DEL PROGRAMMA SPECIFICO
      *---------------------------------------------------------------
           MOVE ZEROES           TO WCM-FLAG-ERRORE-GEN.
           MOVE ZEROES           TO CMTER-WULTMAP
                                    CMTER-WCPCSIN.
           MOVE SPACES           TO WCM-FUNZ
                                    WCM-FLAG-ERRORE.

      *---------------------------------------------------------------
      * LEGGE TERMINALE
      * SE OK ESEGUE UPDATE CON I DATI BPEL
      * SE NON LO TROVA LO INSERISCE CON I DATI BPEL
      * ALTRIMENTI VA IN ABEND GESTITO
      *---------------------------------------------------------------
           PERFORM TP010-LEGGI-TERMINALE
              THRU TP010-LEGGI-TERMINALE-END.

      *---------------------------------------------------------------
      * LEGGE ISTITUTI
      *---------------------------------------------------------------
           PERFORM TP030-READ-IST
              THRU TP030-READ-IST-END.

      *---------------------------------------------------------------
      * LEGGE CONFIGURAZIONE TECNICA
      *---------------------------------------------------------------
           PERFORM TP040-READ-CONFIG
              THRU TP040-READ-CONFIG-END.
TEST  *    MOVE 'N'   TO CONFG-WSICUREZ.
      *---------------------------------------------------------------
      * PULIZIA CAMPI INPHE-WPROC-INP / INPHE-WDATI-INP
      * UTILIZZATI DA SSUSI-SMAPS-SIDIBA PER CHIAMARE SISEB3
      *---------------------------------------------------------------
           PERFORM TP173-UPD-TBWINPHE-SMSU
              THRU TP173-UPD-TBWINPHE-SMSU-END.
      *---------------------------------------------------------------
      * DECODIFICA DESCRIZIONE FILIALE
      *---------------------------------------------------------------
             MOVE TERMI-CIST     TO ABUTE-CIST
BPO942     IF WRK-FILALFNUM = 0
             MOVE TERMI-CUTE     TO ABUTE-CUTE
BPO942     ELSE
BPO942       MOVE WRK-FILALFNUM  TO ABUTE-CUTE
BPO942     END-IF
            PERFORM TP015-READ-TBTABUTE
               THRU TP015-READ-TBTABUTE-END
BPO975*    IF WRK-ZFILDEP  > ' '
BPO975*      MOVE WRK-ZFILDEP    TO ABUTE-ZFIL
BPO975*    END-IF
220496     MOVE DCLTBTABUTE    TO CMTER-TABUTE
                                  WRK-DCLTBTABUTE.
           COPY ZMZFILIA.
           MOVE WCM-DFIL       TO TP-DFIL.
           MOVE TERMI-CUTE     TO WCM-CDPZ.
      *---------------------------------------------------------------
      * CONTROLLO OPERATIVITA' FILIALE
      *---------------------------------------------------------------
130597     MOVE WCM-CIST       TO OPEFL-CIST.
130597     MOVE WCM-CDPZ       TO OPEFL-CUTE.
130597     PERFORM TP870-LEGGI-TBTOPEFL
130597        THRU TP870-LEGGI-TBTOPEFL-END.
130597     IF OPEFL-FCHI = 1 AND
130597       (OPEFL-FFOPE = 0 OR 2)
130597        MOVE 1 TO OPEFL-FFOPE
130597        PERFORM TP880-AGGIORNA-TBTOPEFL
130597           THRU TP880-AGGIORNA-TBTOPEFL-END
130597     END-IF.
BPEL       IF OPEFL-FCHI = 0
BPO942     AND WRK-FILALFNUM = 0
BPEL          MOVE 'FILIALE NON ABILITATA'         TO TPRIF
BPEL          MOVE 'ZMP00000'                      TO TPPRG
BPEL          MOVE 'OPEFL-FCHI = 0'                TO TPSTM
BPEL          MOVE SPACES                          TO TPRETC
BPEL          MOVE 'TBTOPEFL'                      TO TPARCH
BPEL          PERFORM TP999-ABEND
BPEL             THRU TP999-ABEND-END
BPEL       END-IF.
      *---------------------------------------------------------------
      * SE ACCESSO ESTERNO   E NON E' RITORNO DA MENU'
      * INIZIALIZZA CAMPI PER AREA COMUNE (COMMAREA O SPA)
      *---------------------------------------------------------------
           IF CONFG-WSICUREZ = 'N'
              IF CMTER-WFASE NOT = 'M'
                 MOVE SPACES      TO CMTER-WCMDATI-TEXT
                 MOVE SPACES      TO CMTER-DATI
                 MOVE ZEROES      TO CMTER-WCURSOR
                 MOVE 0           TO CMTER-CPCS
                 MOVE WCM-TERMIN  TO CMTER-CTER
                 MOVE '0'         TO CMTER-WFASE.
      *---------------------------------------------------------------
      * GESTIONE CICLI DI ELABORAZIONE
      *---------------------------------------------------------------
           PERFORM TP050-CICLO-PGM
              THRU TP050-CICLO-PGM-END.
           IF WCM-INVIO-MAPPA = 'S'
              GO TO TP900-INVIO-MAPPA.
      *---------------------------------------------------------------
      * CONTROLLO TASTI FUNZIONALI
      *---------------------------------------------------------------
      *------------------------------ LETTURA TABELLA PROCESSI
           MOVE TP-ID        TO PRPCS-CPCS.
           PERFORM LEGGI-TBWPRPCS
              THRU LEGGI-TBWPRPCS-END.
           MOVE PRPCS-WMPPFK TO TAB-PFK.
           IF WCM-PFK GREATER ZEROES
              MOVE WCM-PFK    TO WCM-PFK-IND
              IF PFK (WCM-PFK-IND) = 'N'
      *-------- WA01 ==> TASTO FUNZIONALE ERRATO
                 MOVE 'WA01'    TO WCM-COD-ERR(1)
                 MOVE ATT-CURS  TO M0000-MATRICOLAL
                 PERFORM TP998-ERRORE
                    THRU TP998-ERRORE-END
                 GO TO TP900-INVIO-MAPPA
              END-IF
              IF PFK (WCM-PFK-IND) NOT GREATER SPACES
                 MOVE CONFG-WMPPFK TO TAB-PFK
                 IF PFK (WCM-PFK-IND) = 'N' OR NOT GREATER SPACES
      *-------- WA01 ==> TASTO FUNZIONALE ERRATO
                    MOVE 'WA01'    TO WCM-COD-ERR(1)
                    MOVE ATT-CURS  TO M0000-MATRICOLAL
                    PERFORM TP998-ERRORE
                       THRU TP998-ERRORE-END
                    GO TO TP900-INVIO-MAPPA
                 END-IF
              END-IF
              EVALUATE PFK (WCM-PFK-IND)
                 WHEN 'R'
                    PERFORM M950-END
                 WHEN OTHER
      *-------- WA02 ==> FUNZIONE NON CONSENTITA DAL PGM
                    MOVE 'WA02'    TO WCM-COD-ERR(1)
                    MOVE ATT-CURS  TO M0000-MATRICOLAL
                    PERFORM TP998-ERRORE
                       THRU TP998-ERRORE-END
                    GO TO TP900-INVIO-MAPPA
              END-EVALUATE
           END-IF.
      *---------------------------------------------------------------
      *      RITORNO AL MENU PER RICHIESTA FUNZIONE
      *---------------------------------------------------------------
           IF WCM-PFK NOT GREATER ZEROES AND
              WCM-FUNZ GREATER SPACES
              PERFORM TP300-FUNZIONE
                 THRU TP300-FUNZIONE-END.
      *---------------------------------------------------------------
      *      ESECUZIONE PRIMO CICLO PER TASTO DI INVIO
      *---------------------------------------------------------------
           IF CMTER-WFASE = '1' AND
              WCM-PFK NOT GREATER ZEROES
              PERFORM TP110-CICLO-UNO
                 THRU TP110-CICLO-UNO-END
           ELSE
      *---------------------------------------------------------------
      *      ESECUZIONE SECONDO CICLO PER TASTO DI INVIO
      *---------------------------------------------------------------
              IF CMTER-WFASE = '2' AND
                 WCM-PFK NOT GREATER ZEROES
                 PERFORM TP120-CICLO-DUE
                    THRU TP120-CICLO-DUE-END.
           IF CMTER-NEWPSW NOT GREATER SPACES
              PERFORM TP400-ELABORA-PROFILO
                 THRU TP400-ELABORA-PROFILO-END
              IF WCM-ERRORE = 'SI'
                 NEXT SENTENCE
              ELSE
      *--------------------------------- LEGGE TABELLA ZM.TABUTE
                 PERFORM TP420-LEGGI-TBTABUTE
                    THRU TP420-LEGGI-TBTABUTE-END
                 PERFORM TP450-AUTORIZZA
                    THRU TP450-AUTORIZZA-END
                 PERFORM TP500-MENU
                    THRU TP500-MENU-END.
       TP900-INVIO-MAPPA.
      *---------------------------------- SELEZIONA CURRENT TIMESTAMP
           PERFORM TP104-PRELEVA-TIMESTAMP
              THRU TP104-PRELEVA-TIMESTAMP-END.
      *-------------------- SALVA IL TIME PER LE SUCCESSIVE OPERAZIONI
           MOVE  WCM-WTIME        TO  CMTER-WTIME.
           MOVE DCLTBWAUTOR       TO  CMTER-WAUTOR.
      *----------------------------- SCRIVE COMMAREA : COPY ZMYUPCOM
           PERFORM TP600-SCRIVI-COMMAREA
              THRU TP600-SCRIVI-COMMAREA-END.
           MOVE 'SISEB III - ACCESSO AL SISTEMA'
             TO TP-DFUN.
      *---------------------------------------------------------------
      * VALORIZZAZIONE AREA MESSAGGI (RIGA 24)
      *---------------------------------------------------------------
           COPY ZMZERMSG.
011295     MOVE WCM-TAB-ERR       TO CMTER-TAB-COD-ERR
011295     MOVE WCM-TAB-ERR-1     TO CMTER-TAB-COD-ERR-1
           MOVE WCM-MSG-ERR       TO TP-MSG
      *---------------------------------------------------------------
      * INVIO MAPPA
      *---------------------------------------------------------------
           MOVE IDECR-M-OUTPUT   TO WCM-MAPPA-1
           MOVE ZEROES           TO WCM-MAPPA-2
           EXEC SQL INCLUDE ZMYINVIO  END-EXEC.
       M950-END.
           MOVE WCM-TERMIN     TO   AUTOR-CTER.
           MOVE WCM-CIST       TO   AUTOR-CIST.
           EXEC SQL   INCLUDE   ZMU31001  END-EXEC.
           IF W-SQL-OK          OR
              W-SQL-NON-TROVATO
                NEXT SENTENCE
           ELSE
              MOVE 'UPDATE AUTORIZZAZIONI(DELETE)' TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMU31001'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'AUTORIZZAZIONI'                TO TPARCH
                PERFORM TP999-ABEND
                   THRU TP999-ABEND-END.
           EXEC SQL INCLUDE ZMYCLEAR  END-EXEC.
       M999-GOBACK.
           GOBACK.
       SVILUPPO-ROUTINE SECTION.
      *---------------------------------------------------------------
BPO305 VERIFICA-INPHE.
BPO305     MOVE  WCM-CIST     TO CONFG-CIST.
BPO305     MOVE  ZEROES       TO W-SQLCODE.
BPO305     MOVE WRK-TERMINALE TO INPHE-KEYCTER.
BPO305     MOVE 'V'           TO INPHE-KEYTTER.
BPO305     EXEC SQL   INCLUDE   ZMS30101  END-EXEC.
BPO305     IF NOT W-SQL-OK AND
BPO305        NOT W-SQL-NON-TROVATO
BPO305        MOVE 'ERRORE LETTURA INPHE         ' TO TPRIF
BPO305        MOVE 'ZMP00000'                      TO TPPRG
BPO305        MOVE 'INCLUDE ZMS30101'              TO TPSTM
BPO305        MOVE W-SQLCODE                       TO TPRETC
BPO305        MOVE 'TBWINPHE      '                TO TPARCH
BPO305        PERFORM TP999-ABEND
BPO305           THRU TP999-ABEND-END
BPO305     ELSE
BPO305        IF W-SQL-NON-TROVATO
BPO305*---------------------------------- SELEZIONA CURRENT TIMESTAMP
BPO305           PERFORM TP104-PRELEVA-TIMESTAMP
BPO305              THRU TP104-PRELEVA-TIMESTAMP-END
BPO305*---------------------------------  SCRIVE TABELLA ZM.TBWINPHE
BPO305           PERFORM TP105-WRITE-TBWINPHE
BPO305              THRU TP105-WRITE-TBWINPHE-END
BPO305        ELSE
BPO305           IF W-SQL-OK
BPO305*------------ VERIFICA CHE PER IL TERMINALE LA MATRICOLA SIA
BPO305*------------ UGUALE A QUELLA UTILIZZATA PRECEDENTEMENTE
BPO305              IF INPHE-NMTRUTE = 'FLUSSO'
BPO305                 NEXT SENTENCE
BPO305              ELSE
BPO305                 IF INPHE-NMTRUTE NOT = WRK-UTENTE
BPO305                    MOVE 'MATRICOLA DIVERSA DA TPX'  TO TPRIF
BPO305                    MOVE 'ZMP00000'                  TO TPPRG
BPO305                    MOVE 'RICOLLEGARSI    '          TO TPSTM
BPO305                    MOVE '          '                TO TPARCH
BPO305                    PERFORM TP999-ABEND
BPO305                       THRU TP999-ABEND-END
BPO305                 END-IF
BPO305              END-IF
BPO305           END-IF
BPO305        END-IF
BPO305     END-IF.
BPO305 VERIFICA-INPHE-END.
BPO305     EXIT.
BPO305 TP105-WRITE-TBWINPHE.
BPO305     INITIALIZE DCLTBWINPHE.
BPO305     MOVE SPACES         TO INPHE-WPROC-INP.
BPO305     MOVE SPACES         TO INPHE-WDATI-INP.
BPO305     MOVE WCM-WTIME      TO INPHE-WTIME.
BPO305     MOVE 'V'            TO INPHE-KEYTTER.
BPO305     MOVE CMTER-CTER     TO INPHE-KEYCTER.
BPO305     MOVE ZEROES         TO INPHE-WNBODY
BPO305     MOVE WCM-CIST       TO INPHE-CIST.
BPO305     MOVE ZEROES         TO INPHE-CPCS.
BPO305     MOVE WRK-UTENTE     TO INPHE-NMTRUTE.
BPO305     MOVE WRK-DIPENDENZA TO INPHE-CDPZ.
BPO305     MOVE ZEROES         TO INPHE-WRETCOD.
BPO305     MOVE CMTER-CTER     TO INPHE-CTER.
BPO305     MOVE ZEROES         TO W-SQLCODE.
BPO305     EXEC SQL INCLUDE ZMV30101 END-EXEC.
BPO305     IF NOT W-SQL-OK
BPO305        MOVE 'INSERT TABELLA HEADER '    TO TPRIF
BPO305        MOVE 'ZMP00000'                  TO TPPRG
BPO305        MOVE 'INCLUDE ZMV30101'          TO TPSTM
BPO305        MOVE W-SQLCODE                   TO TPRETC
BPO305        MOVE 'ZM.TBWINPHE'               TO TPARCH
BPO305        PERFORM TP999-ABEND
BPO305           THRU TP999-ABEND-END.
BPO305 TP105-WRITE-TBWINPHE-END.
BPO305     EXIT.
      *---------------------------------------------------------------
       TP040-READ-CONFIG.
           MOVE  WCM-CIST     TO  CONFG-CIST.
           MOVE  ZEROES       TO  W-SQLCODE.
           EXEC SQL   INCLUDE   ZMS30901  END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA CONFIGURAZIONE' TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMS30901'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'CONFIGURAZIONE'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
220496     ELSE
220496        MOVE DCLTBWCONFG TO CMTER-WCONFG.
       TP040-READ-CONFIG-END.
           EXIT.
      *--------------------------------------------------------------*
      * AGGIORNA ZM.TBWINPHE                                         *
      *--------------------------------------------------------------*
       TP173-UPD-TBWINPHE-SMSU.
           MOVE WCM-CIST         TO INPHE-CIST.
           MOVE 'V'              TO INPHE-KEYTTER.
           MOVE WCM-TERMIN       TO INPHE-KEYCTER.
           MOVE SPACES           TO INPHE-WPROC-INP.
           MOVE SPACES           TO INPHE-WDATI-INP.
           MOVE ZEROES           TO W-SQLCODE.
           EXEC SQL INCLUDE ZMU30104 END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'ERRORE UPDATE ZM.TBWINPHE    ' TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMU30104'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'ZM.TBWINPHE'                   TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP173-UPD-TBWINPHE-SMSU-END.
           EXIT.
      *--------------------------------------------------------------*
      *     RICERCA MAPPA                                            *
      *--------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYIDECR END-EXEC.
      *---------------------------------------------------------------
      * > SPA-FASE = '0' E SPA-FMT-ID = 'END' : IL PROGRAMMA CANCELLA
      *   LE TABELLE SPA E PAGINE E RITORNA IL CONTROLLO AL CICS (SO-
      *   LO VERSIONE CICS).
      * > SPA-FASE = '0' :       IL PROGRAMMA DEVE FARE LA SEND DELLA
      *   PROPRIA MAPPA, DOPO AVER IMPOSTATO I CAMPI OPPORTUNI.
      * > SPA-FASE = 'R' :       IL PROGRAMMA DEVE FARE LA SEND DELLA
      *   PROPRIA MAPPA, DOPO AVER IMPOSTATO I CAMPI OPPORTUNI.
      * > SPA-FASE = 'M' :       IN CASO DI ENTRATA CON CODICE TRANS.
      *   NON CORRETTO (DIVERSO DAL MENU INIZIALE) IL PGM FA LA SEND
      *   DELLA MAPPA VUOTA DEL PGM DI GESTIONE MENU.
      * > SPA-HELP = 'H' :       IL PROGRAMMA DEVE RICHIAMARE IL PRO-
      *   GRAMMA DI HELP
      * > SPA-HELP = 'R' :       IL PROGRAMMA RIENTRA DAL PROGRAMMA DI
      *   HELP E DEVE VISUALIZZARE I DATI CHE ERANO STATI IMPOSTATI A
      *   VIDEO PRIMA DELLA RICHIESTA DELL'HELP STESSO.
      * > SPA-STAMPA= 'S' : IL PROGRAMMA ESEGUE LA LETTURA DELLA
      *   TABELLA DI ASSOCIAZIONE INDIRIZZI TERMINALE/STAMPANTE.
      *---------------------------------------------------------------
       TP050-CICLO-PGM.
           COPY ZMZHELP.
           IF CMTER-WFASE = '0' AND
              CMTER-CPCS = 9998
              PERFORM M950-END.
           IF CMTER-WFASE = '0' OR
              CMTER-WFASE = 'R' OR
              CMTER-WFASE = 'M'
              PERFORM TP100-CICLO-ZERO
                 THRU TP100-CICLO-ZERO-END
              MOVE 'S'         TO WCM-INVIO-MAPPA.
       TP050-CICLO-PGM-END.
           EXIT.
      *------------------------------------------------------------*
       LEGGI-TBWPRPCS.
           MOVE ZEROES         TO W-SQLCODE.
           EXEC SQL INCLUDE ZMS31501 END-EXEC.
           IF W-SQL-NON-TROVATO
              PERFORM TP055-LEGGI-TBWPRMEN
                 THRU TP055-LEGGI-TBWPRMEN-END
           ELSE
              IF NOT W-SQL-OK
                 MOVE 'LEGGI TABELLA PROCESSI'    TO TPRIF
                 MOVE 'ZMP00000'                  TO TPPRG
                 MOVE 'INCLUDE ZMS31501'          TO TPSTM
                 MOVE W-SQLCODE                   TO TPRETC
                 MOVE 'ZM.TBWPRPCS'               TO TPARCH
                 PERFORM TP999-ABEND
                    THRU TP999-ABEND-END.
       LEGGI-TBWPRPCS-END.
           EXIT.
      *------------------------------------------------------------*
       TP055-LEGGI-TBWPRMEN.
           MOVE WCM-CIST            TO PRMEN-CIST.
           MOVE TP-ID               TO PRMEN-WCPCS.
           MOVE ZEROES              TO W-SQLCODE.
           EXEC SQL INCLUDE ZMS31601 END-EXEC.
           IF W-SQL-NON-TROVATO OR
              NOT W-SQL-OK
              MOVE 'LEGGI TABELLA MENU''  '    TO TPRIF
              MOVE 'ZMP00000'                  TO TPPRG
              MOVE 'INCLUDE ZMS31601'          TO TPSTM
              MOVE W-SQLCODE                   TO TPRETC
              MOVE 'ZM.TBWPRMEN'               TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
           ELSE
              MOVE PRMEN-CPCS  TO PRPCS-CPCS
              PERFORM LEGGI-TBWPRPCS
                 THRU LEGGI-TBWPRPCS-END.
       TP055-LEGGI-TBWPRMEN-END.
           EXIT.
      *---------------------------------------------------------------*
       TP500-MENU.
           MOVE '1'              TO IDECR-TIPRICE.
           MOVE '0'              TO CMTER-WFASE.
           MOVE SPACES           TO CMTER-WFUNZ.
           MOVE WCM-CIST         TO IDECR-CIST
           MOVE  0001            TO CMTER-CPCS
                                    IDECR-VALORE.
           PERFORM TP020-DECOD-ID
              THRU TP020-DECOD-ID-END.
           PERFORM TP700-START-PGM
              THRU TP700-START-PGM-END.
       TP500-MENU-END.
           EXIT.
      *---------------------------------------------------------------
       TP015-READ-TBTABUTE.
           MOVE ZEROES TO W-SQLCODE.
           EXEC SQL INCLUDE ZMS22001 END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA FILIALE '       TO TPRIF
              MOVE  ABUTE-CUTE                     TO TPRIF(23:5)
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMS22001'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'TBTABUTE'                      TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP015-READ-TBTABUTE-END.
              EXIT.
BPO942 LEGGI-TABUTE.
BPO942     MOVE ZEROES TO W-SQLCODE.
BPO942     EXEC SQL INCLUDE ZMS22021 END-EXEC.
BPO942     IF NOT W-SQL-OK AND NOT
BPO942            W-SQL-NON-TROVATO
BPO942        MOVE 'ERRORE LETTURA FILIALE '       TO TPRIF
BPO942        MOVE  ABUTE-ZBRCSWF                  TO TPRIF(23:5)
BPO942        MOVE 'ZMP00000'                      TO TPPRG
BPO942        MOVE 'INCLUDE ZMS22001'              TO TPSTM
BPO942        MOVE W-SQLCODE                       TO TPRETC
BPO942        MOVE 'TBTABUTE'                      TO TPARCH
BPO942        PERFORM TP999-ABEND
BPO942           THRU TP999-ABEND-END.
BPO942 LEGGI-TABUTE-END.
BPO942        EXIT.
BPO975*CHIAMA-ZMBCASV1.
BPO975*     MOVE ZEROES TO W-SQLCODE
BPO975*     INITIALIZE ZMWCASV1
BPO975*     MOVE SIPRACF-DIP-LIV-USERID  TO CASV-DIPOPEX
BPO975*     EXEC SQL INCLUDE ZMYCASV1 END-EXEC.
BPO975*       IF CASV-RC = '99'
BPO975*       MOVE CASV-DESCERR                    TO TPRIF
BPO975*       MOVE  ABUTE-ZBRCSWF                  TO TPRIF(23:5)
BPO975*       MOVE 'ZMP00000'                      TO TPPRG
BPO975*       MOVE 'INCLUDE ZMS22001'              TO TPSTM
BPO975*       MOVE W-SQLCODE                       TO TPRETC
BPO975*       MOVE 'ZMBCASV1'                      TO TPARCH
BPO975*       PERFORM TP999-ABEND
BPO975*          THRU TP999-ABEND-END.
BPO975*CHIAMA-ZMBCASV1-END.
BPO975*       EXIT.
BPO975*SE ATTIVA INTERFACCIA DEPOSITI TERRITORIALI
BPO975*VERIFICA SE FORZARE CON IL DEPOSITO TERRITORIALE LA
BPO975*FILIALE OPERANTE IN QUANDO DEPOSITO TERRITORIALE RIGUARDA
BPO975*IL PROFILO
BPO975*LEGGI-DEPOSITO-TER.
BPO975*      MOVE SPACES TO WRK-ZFILDEP
BPO975*      PERFORM CHIAMA-ZMBCASV1
BPO975*         THRU CHIAMA-ZMBCASV1-END
BPO975*     IF  CASV-RC = '00'
BPO975*       IF CASV-TIP-FIL-DEP = 'DP'
BPO975*          MOVE CASV-ZDEP TO ABUTE-ZFIL
BPO975*                            WRK-ZFILDEP
BPO975*          GO TO LEGGI-DEPOSITO-TER-END
BPO975*       END-IF
BPO975*       IF CASV-TIP-FIL-DEP = 'FI'
BPO975*          AND CASV-DEP-FIL-LIV > ' '
BPO975*          MOVE CASV-DEP-FIL-LIV  TO  ABUTE-ZBRCSWF
BPO975*
BPO975*          PERFORM LEGGI-TABUTE
BPO975*             THRU LEGGI-TABUTE-END
BPO975*          MOVE CASV-ZDEP TO ABUTE-ZFIL
BPO975*                            WRK-ZFILDEP
BPO975*       END-IF
BPO975*     END-IF
BPO975*     IF  CASV-RC = '01'
BPO975*          GO TO LEGGI-DEPOSITO-TER-END
BPO975*     END-IF
BPO975*     IF  CASV-RC = '02'
BPO975*       IF CASV-SQLCODE = +100
BPO975*          GO TO LEGGI-DEPOSITO-TER-END
BPO975*       ELSE
BPO975*     WA07 ==> ERRORE
BPO975*       MOVE 'WA07'    TO WCM-COD-ERR(1)
BPO975*       MOVE ATT-CURS  TO M0000-NEWPSWL
BPO975*       MOVE CASV-DESCERR TO WCM-DES-ERR(1)
BPO975*       PERFORM TP998-ERRORE
BPO975*          THRU TP998-ERRORE-END
BPO975*       GO TO TP900-INVIO-MAPPA
BPO975*       END-IF
BPO975*     END-IF.
BPO975*     IF WRK-ZFILDEP(1:17) = 'DEP. TERRITORIALE'
BPO975*        MOVE 'DEP.TERRITOR.' TO WRK-ZFILDEP(1:13)
BPO975*        MOVE CASV-ZDEP(18:)  TO WRK-ZFILDEP(14:).
BPO975*LEGGI-DEPOSITO-TER-END.
BPO975*       EXIT.
BPOA07*SE ATTIVA INTERFACCIA DEPOSITI TERRITORIALI
BPOA07*VERIFICA SE FORZARE LA FILIALE OPERANTE CON UNA DELLE
BPOA07*FILIALI ACCORPATE O ACCORPANTE
BPOA07 LEGGI-FORZA-FIL.
BPOA07      INITIALIZE DCLTBWCONCV
BPOA07*     MOVE WCM-CIST TO CONCV-CIST
BPOA07      PERFORM LEGGI-TBWCONCV
BPOA07         THRU LEGGI-TBWCONCV-END
BPOA07      IF  CONCV-FORFILI NOT = 'S'
BPOA07          GO TO LEGGI-FORZA-FIL-END
BPOA07      END-IF
BPOA07*RITORNO DAL PROGRAMMA FORZA FILIALE
BPOA07*SE DIPOPEXPR > SPAZI FORZATURA FILIALE
BPOA07*INSERIRE NELLA TABELLA DEI LOG
BPOA07      IF CMTER-WFASE     = 'R'   AND
BPOA07         CMTER-WCPCSIN   = 2740  AND
BPOA07         CMTER-DIPOPEXPR =  SIPRACF-DIP-LIV-USERID
BPOA07         IF   CMTER-DIPOPEXFO > ' '
BPOA07             MOVE CMTER-DIPOPEXFO TO ABUTE-ZBRCSWF
BPOA07           PERFORM LEGGI-TABUTE
BPOA07              THRU LEGGI-TABUTE-END
BPOA15            IF W-SQL-NON-TROVATO
BPOA15              MOVE 'ERRORE FILIALE FORZATA '     TO TPRIF
BPOA15              MOVE  ABUTE-ZBRCSWF                TO TPRIF(23:5)
BPOA15              MOVE 'ZMP00000'                    TO TPPRG
BPOA15              MOVE 'INCLUDE ZMS22001'            TO TPSTM
BPOA15              MOVE W-SQLCODE                     TO TPRETC
BPOA15              MOVE 'TBTABUTE'                    TO TPARCH
BPOA15              PERFORM TP999-ABEND
BPOA15                 THRU TP999-ABEND-END
BPOA15            END-IF
BPOA07         END-IF
BPOA07         PERFORM INSERISCI-LOG
BPOA07            THRU INSERISCI-LOG-END
BPOA07      ELSE
BPOA07*CONTROLLO FILIALE ALFANUMERICA
BPOA07       PERFORM CHIAMA-M10CX
BPOA07          THRU CHIAMA-M10CX-END
BPOA07        IF  CA-M10-FIL-ACC  > ' '
BPOA07        AND CA-M10-FIL1     > ' '
BPOA07        AND CA-M10-STATUS   = 0
BPOA07          PERFORM CHIAMA-ZMP0B440
BPOA07             THRU CHIAMA-ZMP0B440-END
BPOA07        END-IF.
BPOA07 LEGGI-FORZA-FIL-END.
BPOA07        EXIT.
BPOA07 LEGGI-TBWCONCV.
BPOA07     EXEC SQL INCLUDE ZMS95605 END-EXEC.
BPOA07     IF NOT W-SQL-OK  AND NOT
BPOA07            W-SQL-NON-TROVATO
BPOA07        MOVE 'ERRORE LETTURA CONFIGURAZIONE' TO TPRIF
BPOA07        MOVE  ABUTE-ZBRCSWF                  TO TPRIF(23:5)
BPOA07        MOVE 'ZMP00000'                      TO TPPRG
BPOA07        MOVE 'INCLUDE ZMS95605'              TO TPSTM
BPOA07        MOVE W-SQLCODE                       TO TPRETC
BPOA07        MOVE 'TBWCONCV '                     TO TPARCH
BPOA07        PERFORM TP999-ABEND
BPOA07           THRU TP999-ABEND-END.
BPOA07 LEGGI-TBWCONCV-END.
BPOA07        EXIT.
BPOA07 CHIAMA-M10CX.
BPOA07     INITIALIZE CA-M10-FIELDS.
BPOA07     MOVE  '00000'                 TO CA-M10-BANCA
BPOA07     MOVE  'SIC'                   TO CA-M10-MOD-ORGANIZZATIVO
BPOA07*    MOVE SIPRACF-POSIZ-LIV-USERID TO CA-M10-POSIZIONE-LIVELLO
BPOA07     MOVE SIPRACF-DIP-LIV-USERID   TO CA-M10-ID-LIVELLO(1:5)
BPOA07     MOVE '00'                     TO CA-M10-ID-LIVELLO(6:2)
BPOA07*    MOVE SIPRACF-DESCR-LIV-USERID TO CA-M10-DESCRIZIONE-LIVELLO
BPOA07     MOVE 'M10CX'                  TO WCM-CHIAMATO
BPOA07     EXEC CICS LINK
BPOA07         PROGRAM (WCM-CHIAMATO)
BPOA07         COMMAREA (CA-M10-FIELDS)
BPOA07     END-EXEC.
BPOA07*    IF CA-M10-STATUS     = 100
BPOA12     IF CA-M10-STATUS     NOT = 0
BPOA07        MOVE 'TENTATIVO DI ACCESSO ERRATO'   TO TPRIF
BPOA07        MOVE 'ZMP00000'                      TO TPPRG
BPOA07        MOVE 'SICUREZZA ESTERNA 3'           TO TPSTM
BPOA07        MOVE SPACES                          TO TPRETC
BPOA07        MOVE 'M10CX'    TO TPARCH(1:5)
BPOA07        MOVE 'COD-ERR ' TO TPARCH(7:7)
BPOA07        MOVE CA-M10-STATUS  TO TPARCH(12:)
BPOA07        PERFORM TP999-ABEND
BPOA07           THRU TP999-ABEND-END
BPOA07     END-IF.
BPOA07 CHIAMA-M10CX-END.
BPOA07        EXIT.
BPOA07 CHIAMA-ZMP0B440.
BPOA07      INITIALIZE CMTER-DATI-ZMP0B440
BPOA07      MOVE SIPRACF-DIP-LIV-USERID TO CMTER-0B440-DIPOPEXPR
BPOA07      MOVE CA-M10-FIL-ACC(1:5)    TO CMTER-0B440-FILACC
BPOA07      MOVE CA-M10-FIL1(1:5)       TO CMTER-0B440-FIL1
BPOA07      MOVE CA-M10-FIL2(1:5)       TO CMTER-0B440-FIL2
BPOA07      MOVE CA-M10-FIL3(1:5)       TO CMTER-0B440-FIL3
BPOA07      MOVE CA-M10-FIL4(1:5)       TO CMTER-0B440-FIL4
BPOA07*     MOVE ABUMA-CPROFILO         TO CMTER-0B440-CPROFILO
BPOA07      MOVE SIPRACF-PROFILO        TO CMTER-0B440-CPROFILO
BPOA07      MOVE SIPRACF-DIP-LIV-USERID TO CMTER-DIPOPEXPR
BPOA07      MOVE IDECR-PGM              TO CMTER-WPRG
BPOA07      MOVE SPACES                 TO IDECR-CAMPI-INPUT
BPOA07      MOVE '1'                    TO IDECR-TIPRICE
BPOA07      MOVE WCM-CIST               TO IDECR-CIST
BPOA07      MOVE 'ZMP00000'             TO CMTER-0B440-PGMCHIAM
BPOA07*     MOVE CMTER-DATI-ZMP00000    TO CMTER-DATI-TRAN
BPOA07      MOVE CMTER-DATI-ZMP0B440    TO CMTER-DATI-TRAN
BPOA12      MOVE SIPRACF-TERMINALE      TO WRK-TERMINALE
BPOA07      PERFORM AREA-COMUNE
BPOA07         THRU AREA-COMUNE-END
BPOA07*     PERFORM TP200-TABELLA-CMTER-A
BPOA07*        THRU TP200-TABELLA-CMTER-A-END
BPOA07      MOVE 0                    TO  CMTER-WFASE
BPOA07      MOVE '0000'               TO  CMTER-WCPCSIN
BPOA07      MOVE '2740'               TO  IDECR-VALORE
BPOA07      MOVE '2740'               TO  CMTER-CPCS
BPOA07      MOVE '2740'               TO  CMTER-CPCS
BPOA07      MOVE IDECR-PGM             TO CMTER-WPRG
BPOA07      PERFORM TP020-DECOD-ID
BPOA07         THRU TP020-DECOD-ID-END
BPOA15*---------------------------------- SELEZIONA CURRENT TIMESTAMP
BPOA15      PERFORM TP104-PRELEVA-TIMESTAMP
BPOA15         THRU TP104-PRELEVA-TIMESTAMP-END.
BPOA15*-------------------- SALVA IL TIME PER LE SUCCESSIVE OPERAZIONI
BPOA15      MOVE  WCM-WTIME        TO  CMTER-WTIME.
BPOA15      MOVE DCLTBWAUTOR       TO  CMTER-WAUTOR.
BPOA07       PERFORM TP700-START-PGM
BPOA07          THRU TP700-START-PGM-END.
BPOA07 CHIAMA-ZMP0B440-END.
BPOA07        EXIT.
BPO966*DOPPIA LETTURA ANCHE CON IL PROFILO A SPAZI
BPO966 CERCA-DEFAULT.
BPO966     MOVE ZEROES TO W-SQLCODE.
BPO966     INITIALIZE DCLTBASCUTE
BPO966     MOVE WCM-CIST                 TO SCUTE-CIST
BPO966     MOVE SIPRACF-POSIZ-LIV-USERID TO SCUTE-LIVELLO
BPO966     MOVE SIPRACF-PROFILO          TO SCUTE-CPROFILO
BPO966     PERFORM LEGGI-TBASCUTE-PROF
BPO966        THRU LEGGI-TBASCUTE-PROF-END
BPO966     IF  W-SQL-OK
BPO966             MOVE SCUTE-CUTE TO WK-CUTE
BPO966     ELSE
BPO966       IF  W-SQL-NON-TROVATO
BPO966           INITIALIZE DCLTBASCUTE
BPO966           MOVE 0                        TO W-SQLCODE
BPO966           MOVE WCM-CIST                 TO SCUTE-CIST
BPO966           MOVE SIPRACF-POSIZ-LIV-USERID TO SCUTE-LIVELLO
BPO966           PERFORM LEGGI-TBASCUTE-LIV
BPO966              THRU LEGGI-TBASCUTE-LIV-END
BPO966     END-IF.
BPO966 CERCA-DEFAULT-END.
BPO966*       EXIT.
BPO966 LEGGI-TBASCUTE-PROF.
BPO966     EXEC SQL INCLUDE ZMS95701 END-EXEC.
BPO966     IF NOT W-SQL-OK  AND NOT
BPO966            W-SQL-NON-TROVATO
BPO966        MOVE 'ERRORE LETTURA PROFILO '       TO TPRIF
BPO966        MOVE  SCUTE-CPROFILO                 TO TPRIF(23:5)
BPO966        MOVE 'ZMP00000'                      TO TPPRG
BPO966        MOVE 'INCLUDE ZMS95701'              TO TPSTM
BPO966        MOVE W-SQLCODE                       TO TPRETC
BPO966        MOVE 'TBTASCUTE'                     TO TPARCH
BPO966        PERFORM TP999-ABEND
BPO966           THRU TP999-ABEND-END.
BPO966 LEGGI-TBASCUTE-PROF-END.
BPO966        EXIT.
BPO966 LEGGI-TBASCUTE-LIV.
BPO966        EXEC SQL INCLUDE ZMS95702 END-EXEC.
BPO966        IF NOT W-SQL-OK  AND NOT
BPO966               W-SQL-NON-TROVATO
BPO966            MOVE 'ERRORE LETTURA PROF-LIV'       TO TPRIF
BPO966            MOVE  SCUTE-LIVELLO                  TO TPRIF(23:5)
BPO966            MOVE 'ZMP00000'                      TO TPPRG
BPO966            MOVE 'INCLUDE ZMS95702'              TO TPSTM
BPO966            MOVE W-SQLCODE                       TO TPRETC
BPO966            MOVE 'TBASCUTE'                      TO TPARCH
BPO966            PERFORM TP999-ABEND
BPO966               THRU TP999-ABEND-END.
BPO966 LEGGI-TBASCUTE-LIV-END.
BPO966        EXIT.
      *------------------------------------------------------------*
       TP030-READ-IST.
           MOVE ZEROES TO W-SQLCODE.
           DISPLAY 'ZMRN2042 WCM-CIST 2 ' WCM-CIST
           MOVE WCM-CIST              TO ISTI-CIST.
           EXEC SQL INCLUDE ZMS20401 END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA ISTITUTO'       TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMS20401'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'ISTITUTI'                      TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
              GO TO TP030-READ-IST-END
220496     ELSE
220496        MOVE DCLTBTISTI  TO CMTER-TISTI.
           MOVE ISTI-ZIST              TO TP-DIST.
           MOVE ZEROES TO W-SQLCODE.
           MOVE WCM-CIST              TO OPEIS-CIST.
           EXEC SQL INCLUDE ZMS23101 END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA OPE. ISTIT.'    TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMS23101'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'ZM.TBTOPEIS'                   TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
220496     ELSE
220496        MOVE DCLTBTOPEIS TO CMTER-TOPEIS.
           MOVE OPEIS-DOGG                 TO WCM-DATA-SIS.
           MOVE CORRESPONDING WCM-SIS-DATA TO WCM-DATA-CORRENTE.
       TP030-READ-IST-END.
              EXIT.
      *--------------------------------------------------------------*
      * EFFETTUA LA SELEZIONE DEL CURRENT TIMESTAMP                  *
      *--------------------------------------------------------------*
       TP104-PRELEVA-TIMESTAMP.
           MOVE WCM-CIST    TO  ISTI-CIST
           EXEC SQL INCLUDE ZMS20402 END-EXEC
           IF NOT W-SQL-OK
              MOVE 'SELECT CURRENT TIMESTAMP'  TO TPRIF
              MOVE 'ZMP00000'                  TO TPPRG
              MOVE 'INCLUDE ZMS20402'          TO TPSTM
              MOVE W-SQLCODE                   TO TPRETC
              MOVE 'ZM.TBTISTI'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP104-PRELEVA-TIMESTAMP-END.
           EXIT.
      *---------------------------------------------------------------
       TP100-CICLO-ZERO.
           IF CONFG-WSICUREZ = 'S'
              MOVE '1'            TO CMTER-WFASE
              MOVE SPACES         TO CMTER-WCMDATI-TEXT
              MOVE SPACES         TO CMTER-DATI
           ELSE
              IF CMTER-WFASE NOT = 'M'
                 PERFORM TP800-NOACC-ESTERNA
                    THRU TP800-NOACC-ESTERNA-END.
       TP100-CICLO-ZERO-END.
           EXIT.
      *------------------------------------------------------------*
       TP110-CICLO-UNO.
           PERFORM TP650-CTR-MATR
              THRU TP650-CTR-MATR-END.
           MOVE M0000-PSW       TO CMTER-PASSWORD.
           MOVE M0000-MATRICOLA TO CMTER-MATRICOLA.
       TP110-CICLO-UNO-END.
           EXIT.
      *---------------------------------------------------------------
       TP115-CICLO-UNO-RIP-ATTR.
       TP115-CICLO-UNO-RIP-ATTR-END.
           EXIT.
      *------------------------------------------------------------*
       TP120-CICLO-DUE.
           IF CMTER-PASSWORD  NOT = M0000-PSW
           OR CMTER-MATRICOLA NOT = M0000-MATRICOLA
           OR M0000-NEWPSW NOT GREATER SPACES
              MOVE '1'    TO CMTER-WFASE
              PERFORM TP110-CICLO-UNO
                 THRU TP110-CICLO-UNO-END.
      *------------------------------------------- LETTURA MATRICOLA
           PERFORM TP655-LEGGI-MATRICOLA
              THRU TP655-LEGGI-MATRICOLA-END.
           MOVE ABUMA-NMTRUTE  TO WCM-NMTRUTE.
      *---------------------------------------------- NUOVA PASSWORD
           PERFORM TP670-UPD-PSW
              THRU TP670-UPD-PSW-END.
           IF WRK-ERRORE-SI
      *---- WA09 ==> NUOVA PASSWORD ERRATA
              MOVE 'WA09'    TO WCM-COD-ERR(1)
              MOVE ATT-CURS  TO M0000-NEWPSWL
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA.
           MOVE SPACES           TO CMTER-DATI.
           MOVE SPACES           TO CMTER-WCMDATI-TEXT.
       TP120-CICLO-DUE-END.
           EXIT.
       TP125-CICLO-DUE-RIP-ATTR.
       TP125-CICLO-DUE-RIP-ATTR-END.
           EXIT.
       TP200-TABELLA-CMTER-A.
           MOVE CMTER-TABELLA-RITORNO(1:WRK-LC) TO
                WRK-APPOGGIO-RITORNO.
           MOVE WRK-APPOGGIO-RITORNO TO
                CMTER-TABELLA-RITORNO(WRK-LB:WRK-LC).
           MOVE CMTER-WCPCSIN   TO CMTER-CPCS-PREC(1).
           MOVE CMTER-DATI-TRAN TO CMTER-AREA-RIT(1).
       TP200-TABELLA-CMTER-A-END.
           EXIT.
       TP200-TABELLA-CMTER-I.
           MOVE CMTER-TABELLA-RITORNO(WRK-LB:WRK-LC) TO
                CMTER-TABELLA-RITORNO(1:WRK-LC).
       TP200-TABELLA-CMTER-I-END.
           EXIT.
      *------------------------------------------------------------*
       TP650-CTR-MATR.
      *-- CONTROLLO MATRICOLA
           IF M0000-MATRICOLA NOT GREATER SPACES
      *-------- WA03 ==> CODICE MATRICOLA OBBLIGATORIO
              MOVE 'WA03'    TO WCM-COD-ERR(1)
              MOVE ATT-CURS  TO M0000-MATRICOLAL
              MOVE ATT-UAHY  TO M0000-MATRICOLAA
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA
           ELSE
              MOVE M0000-MATRICOLA  TO CMTER-MATRICOLA
           END-IF.
      *-- LETTURA MATRICOLA
           PERFORM TP655-LEGGI-MATRICOLA
              THRU TP655-LEGGI-MATRICOLA-END.
      *-- ESISTENZA MATRICOLA
           IF W-SQL-NON-TROVATO
      *-------- WA05 ==> MATRICOLA NON CENSITA
              MOVE 'WA05'    TO WCM-COD-ERR(1)
              MOVE ATT-CURS  TO M0000-MATRICOLAL
              MOVE ATT-UAHY  TO M0000-MATRICOLAA
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA.
           MOVE ABUMA-NMTRUTE  TO WCM-NMTRUTE.
           IF CONFG-WSICUREZ = 'S'
              PERFORM TP660-CTR-PSW
                 THRU TP660-CTR-PSW-END
              PERFORM TP665-CTR-NEWPSW
                 THRU TP665-CTR-NEWPSW-END.
       TP650-CTR-MATR-END.
           EXIT.
      *------------------------------------------------------------*
       TP655-LEGGI-MATRICOLA.
           MOVE TERMI-CIST          TO ABUMA-CIST.
           MOVE CMTER-MATRICOLA     TO ABUMA-NMTRUTE
           MOVE ZEROES              TO W-SQLCODE.
           EXEC SQL INCLUDE ZMS21701 END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'LEGGI MATRICOLA'               TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMS21701'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'MATRICOLE'                     TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
220496     ELSE
220496        MOVE DCLTBTABUMA TO CMTER-TABUMA.
       TP655-LEGGI-MATRICOLA-END.
           EXIT.
      *------------------------------------------------------------*
       TP660-CTR-PSW.
      *-- CONTROLLO PASSWORD
           IF M0000-PSW NOT GREATER SPACES
      *-------- WA04 ==> PASSWORD OBBLIGATORIA
              MOVE 'WA04'    TO WCM-COD-ERR(1)
              MOVE ATT-CURS  TO M0000-PSWL
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA.
           MOVE M0000-PSW              TO WORK-PSW.
           PERFORM TP680-CRIPTA
              THRU TP680-CRIPTA-END
                   VARYING I1 FROM 1 BY 1
                     UNTIL I1 GREATER   8.
      *-- CONTROLLO PASSWORD CRIPTATA
           IF CRIPT-PSW NOT = ABUMA-CPSW
      *-------- WA06 ==> PASSWORD ERRATA ***'-----------------------*
              MOVE 'WA06'    TO WCM-COD-ERR(1)
              MOVE LOW-VALUE TO M0000-PSW
              MOVE ATT-CURS  TO M0000-PSWL
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA.
      *-- CONTROLLO SCADENZA PASSWORD
           IF M0000-NEWPSW NOT GREATER SPACES
              PERFORM TP690-CTR-SCADENZA
                 THRU TP690-CTR-SCADENZA-END.
       TP660-CTR-PSW-END.
           EXIT.
       TP690-CTR-SCADENZA.
           IF  ABUMA-FPSW GREATER ZEROES
              IF  ABUMA-DSCAPSW     LESS   WCM-DATA-SIS
      *---- WA07 ==> PASSWORD SCADUTA
                 MOVE 'WA07'    TO WCM-COD-ERR(1)
                 MOVE ATT-CURS  TO M0000-MATRICOLAL
                 PERFORM TP998-ERRORE
                    THRU TP998-ERRORE-END
                 GO TO TP690-CTR-SCADENZA-END
              END-IF
           ELSE
              IF  ABUMA-FPSW GREATER ZEROES
                 IF  ABUMA-DSCAPSW     LESS   WCM-DATA-SIS
      *---- WA07 ==> PASSWORD SCADUTA
                    MOVE 'WA07'    TO WCM-COD-ERR(1)
                    MOVE ATT-CURS  TO M0000-MATRICOLAL
                    PERFORM TP998-ERRORE
                       THRU TP998-ERRORE-END
                 END-IF
              END-IF
           END-IF.
       TP690-CTR-SCADENZA-END.
           EXIT.
      *------------------------------------------------------------*
       TP665-CTR-NEWPSW.
      *-- CONTROLLA LA PAROLA CHIAVE SOSTITUTIVA
      *-- CHIEDENDONE LA RIDIGITAZIONE PER CONFERMA
           IF M0000-NEWPSW NOT GREATER SPACES
              MOVE SPACES TO M0000-NEWPSW.
           MOVE M0000-PSW       TO CMTER-PASSWORD.
           MOVE M0000-MATRICOLA TO CMTER-MATRICOLA.
           IF M0000-NEWPSW      NOT EQUAL  SPACES
              MOVE '2'                  TO  CMTER-WFASE
              MOVE M0000-NEWPSW         TO  CMTER-NEWPSW
              MOVE SPACES               TO  M0000-NEWPSW
      *---- WA08 *** DIGITARE NUOVA PASSWORD PER CONFERMA ***'-------*
              MOVE 'WA08'    TO WCM-COD-ERR(1)
              MOVE ATT-CURS  TO M0000-NEWPSWL
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA.
       TP665-CTR-NEWPSW-END.
           EXIT.
       TP670-UPD-PSW.
      *-- CONTROLLO NUOVA PAROLA CHIAVE AGGIORNANDO LA TABELLA
      *-- SE QUESTA CORRISPONDE A QUELLA PRECEDENTEMENTE DIGITATA
           MOVE 'NO'                    TO  WRK-ERRORI.
           IF M0000-NEWPSW NOT GREATER SPACES
              MOVE SPACES TO M0000-NEWPSW.
           IF M0000-NEWPSW      NOT EQUAL  CMTER-NEWPSW
              MOVE 'SI'                 TO  WRK-ERRORI
              GO TO TP670-UPD-PSW-END.
           MOVE M0000-NEWPSW           TO  WORK-PSW.
           PERFORM TP680-CRIPTA
              THRU TP680-CRIPTA-END
                   VARYING I1 FROM 1 BY 1
                     UNTIL I1 GREATER   8.
           MOVE ZEROES                  TO  W-SQLCODE.
           MOVE TERMI-CIST              TO ABUMA-CIST.
           MOVE CMTER-MATRICOLA         TO  ABUMA-NMTRUTE.
           MOVE CRIPT-PSW               TO  ABUMA-CPSW.
           EXEC SQL INCLUDE ZMU21701    END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'UPDATE MATRICOLA PER PASSWORD' TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMU21701'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'MATRICOLE'                     TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP670-UPD-PSW-END.
           EXIT.
      *------------------------------------------------------------*
       TP300-FUNZIONE.
           MOVE 'R'           TO CMTER-WFASE.
           PERFORM TP700-START-PGM
              THRU TP700-START-PGM-END.
       TP300-FUNZIONE-END.
           EXIT.
      *
       TP311-INCLUDE.
           EXEC SQL INCLUDE ZMS31101 END-EXEC.
           .
       TP311-INCLUDE-END.
           EXIT.
      *
       TP311-INCLUDEV.
           EXEC SQL INCLUDE ZMV31101 END-EXEC.
           .
       TP311-INCLUDEV-END.
           EXIT.
      *--------------------------------------------------------------*
      * RICHIAMATA NELLA COPY ZMYUPCOM                               *
      *--------------------------------------------------------------*
       TP311-INCLUDEU.
           EXEC SQL INCLUDE ZMU31102 END-EXEC
           .
       TP311-INCLUDEU-END.
           EXIT.
      *
      *---------------------------------------------------------------
       TP700-START-PGM.
      *----------------------------- SCRIVE COMMAREA : COPY ZMYUPCOM
           PERFORM TP600-SCRIVI-COMMAREA
              THRU TP600-SCRIVI-COMMAREA-END.
           COPY ZMZSTART.
       TP700-START-PGM-END.
           EXIT.
      *------------------------------------------------------------*
       TP450-AUTORIZZA.
           MOVE SPACES         TO   WRK-FOUND-ABILITA.
           MOVE ZEROES         TO   W-SQLCODE.
           MOVE WCM-TERMIN     TO   AUTOR-CTER.
           MOVE WCM-CIST       TO   AUTOR-CIST.
           EXEC SQL   INCLUDE   ZMS31001  END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'LETTURA AUTORIZZAZIONI'        TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMS31001'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'AUTORIZZAZIONI'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
           IF W-SQL-NON-TROVATO
              GO TO TP450-INSERT-AUTORIZZA
           ELSE
              MOVE 'SI' TO WRK-FOUND-ABILITA.
           EXEC SQL   INCLUDE   ZMU31001  END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'UPDATE AUTORIZZAZIONI(DELETE)' TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMU31001'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'AUTORIZZAZIONI'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP450-INSERT-AUTORIZZA.
           MOVE ZEROES TO W-SQLCODE.
           MOVE WCM-CIST       TO   AUTOR-CIST.
           MOVE WCM-CPROFILO1    TO AUTOR-CPROFILO.
           MOVE WCM-CPROFILO2    TO AUTOR-CPROFOP.
           MOVE WCM-TERMIN       TO AUTOR-CTER.
           MOVE ABUMA-NMTRUTE    TO AUTOR-NMTRUTE.
220496     MOVE DCLTBWAUTOR      TO CMTER-WAUTOR.
           EXEC SQL   INCLUDE   ZMS31002  END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'LETTURA AUTORIZZAZIONI'        TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMS31002'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'AUTORIZZAZIONI'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
           IF W-SQL-OK
      *---- WA20 ==> MATRICOLA OPERANTE SU ALTRO TERMINALE
              MOVE 'WA20'    TO WCM-COD-ERR(1)
              MOVE ATT-CURS  TO M0000-MATRICOLAL
              MOVE ATT-UAHY  TO M0000-MATRICOLAA
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA.
           MOVE ZEROES         TO   W-SQLCODE.
           IF WRK-FOUND-ABILITA = 'SI'
              EXEC SQL   INCLUDE   ZMU31002  END-EXEC
              IF NOT W-SQL-OK
                 MOVE 'UPDATE AUTORIZZAZIONI'         TO TPRIF
                 MOVE 'ZMP00000'                      TO TPPRG
                 MOVE 'INCLUDE ZMU31002'              TO TPSTM
                 MOVE W-SQLCODE                       TO TPRETC
                 MOVE 'AUTORIZZAZIONI'                TO TPARCH
                 PERFORM TP999-ABEND
                    THRU TP999-ABEND-END
              ELSE
                 GO TO TP450-AUTORIZZA-END.
           EXEC SQL   INCLUDE   ZMV31001  END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'INSERT AUTORIZZAZIONI'         TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMV31001'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'AUTORIZZAZIONI'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP450-AUTORIZZA-END.
           EXIT.
       TP680-CRIPTA.
           PERFORM TP685-TRADUCI
              THRU TP685-TRADUCI-END
                   VARYING I2 FROM 1 BY 1
                     UNTIL I2 GREATER   37.
       TP680-CRIPTA-END.
           EXIT.
       TP870-LEGGI-TBTOPEFL.
           EXEC SQL INCLUDE ZMS25801 END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA TOPEFL'   TO   TPRIF
              MOVE 'ZMP00000'                TO   TPPRG
              MOVE 'INCLUDE ZMS25801'        TO   TPSTM
              MOVE W-SQLCODE                 TO   TPRETC
              MOVE 'ZM.TBTOPEFL'             TO   TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
           END-IF.
       TP870-LEGGI-TBTOPEFL-END.
           EXIT.
       TP880-AGGIORNA-TBTOPEFL.
           EXEC SQL INCLUDE ZMU25803 END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE UPDATE  TOPEFL'   TO   TPRIF
              MOVE 'ZMP00000'                TO   TPPRG
              MOVE 'INCLUDE ZMU25803'        TO   TPSTM
              MOVE W-SQLCODE                 TO   TPRETC
              MOVE 'ZM.TBTOPEFL'             TO   TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
           END-IF.
       TP880-AGGIORNA-TBTOPEFL-END.
           EXIT.
       TP685-TRADUCI.
           IF BYTE-ORI (I2)      EQUAL ELE-PSW (I1)
              MOVE BYTE-CRI (I2)    TO C-ELE-PSW (I1)
              MOVE 50                  TO I2.
       TP685-TRADUCI-END.
           EXIT.
       TP400-ELABORA-PROFILO.
           IF ABUMA-CPROFILO = SPACES
      *---------------------------------- LETTURA FILIALE UTENTE
              IF ABUMA-CUTE NOT = TERMI-CUTE
                 MOVE TERMI-CIST     TO  ABUTE-CIST
                 MOVE ABUMA-CUTE     TO  ABUTE-CUTE
                 PERFORM TP015-READ-TBTABUTE
                    THRU TP015-READ-TBTABUTE-END
              END-IF
              IF ABUTE-CPROFILO = SPACES
                 MOVE TERMI-CIST     TO  ABLTU-CIST
                 MOVE ABUTE-TUTE     TO  ABLTU-TUTE
                 PERFORM TP402-READ-TBTABLTU
                    THRU TP402-READ-TBTABLTU-END
                 IF ABLTU-CPROFILO = SPACES
                    MOVE 'PROFILO MATRIC. ASSENTE'  TO TPRIF
                    MOVE 'ZMP00000'              TO TPPRG
                    MOVE 'TP400-ELABORA-PROFILO' TO TPSTM
                    MOVE W-SQLCODE               TO TPRETC
                    MOVE 'ZM.TBTABLTU'           TO TPARCH
                    PERFORM TP999-ABEND
                       THRU TP999-ABEND-END
                 ELSE
                    MOVE ABLTU-CPROFILO      TO WCM-CPROFILO1
                 END-IF
              ELSE
                 MOVE ABUTE-CPROFILO        TO WCM-CPROFILO1
              END-IF
           ELSE
              MOVE ABUMA-CPROFILO           TO WCM-CPROFILO1
           END-IF.
           MOVE WRK-DCLTBTABUTE             TO DCLTBTABUTE.
           IF ABUMA-CUTE = TERMI-CUTE
              MOVE WCM-CPROFILO1            TO WCM-CPROFILO2
           ELSE
              IF ABUTE-CPROFILO = SPACES
                 MOVE TERMI-CIST     TO  ABLTU-CIST
                 MOVE ABUTE-TUTE     TO  ABLTU-TUTE
                 PERFORM TP402-READ-TBTABLTU
                    THRU TP402-READ-TBTABLTU-END
                 IF ABLTU-CPROFILO = SPACES
                    MOVE 'PROFILO OPERANTE ASSENTE'  TO TPRIF
                    MOVE 'ZMP00000'              TO TPPRG
                    MOVE 'TP400-ELABORA-PROFILO' TO TPSTM
                    MOVE W-SQLCODE               TO TPRETC
                    MOVE 'ZM.TBTABLTU'           TO TPARCH
                    PERFORM TP999-ABEND
                       THRU TP999-ABEND-END
                 ELSE
                    MOVE ABLTU-CPROFILO      TO WCM-CPROFILO2
                 END-IF
              ELSE
                 MOVE ABUTE-CPROFILO        TO WCM-CPROFILO2
              END-IF
           END-IF.
           PERFORM TP404-LEGGI-PROFILO
              THRU TP404-LEGGI-PROFILO-END.
       TP400-ELABORA-PROFILO-END.
           EXIT.
       TP402-READ-TBTABLTU.
           EXEC SQL   INCLUDE   ZMS23201  END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'LETTURA TIPI FILIALI'          TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'ZMS23201'                      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'ZM.TBTABLTU'                   TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP402-READ-TBTABLTU-END.
           EXIT.
       TP404-LEGGI-PROFILO.
           MOVE  WCM-CIST     TO  PROFI-CIST.
           MOVE  'N'          TO  PROFI-AUTORIZ.
           EXEC SQL   INCLUDE   ZMS22306  END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO AND
              NOT W-SQL-PIU-RIGHE
              MOVE 'COUNT SU TABELLA PROFILI'      TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'ZMS22306'                      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'PROFILI'                       TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
ROU   *    IF W-SQL-NON-TROVATO
ROU   *       IF CONFG-WSICUREZ = 'S'
ROU   *-- WA12 ==> NESSUN PROCESSO AUTORIZZATO
ROU   *          MOVE 'WA12'    TO WCM-COD-ERR(1)
ROU   *          MOVE ATT-CURS  TO M0000-MATRICOLAL
ROU   *          PERFORM TP998-ERRORE
ROU   *             THRU TP998-ERRORE-END
ROU   *          GO TO TP900-INVIO-MAPPA
ROU   *       ELSE
ROU   *          MOVE 'CONTROLLO PROFILI'             TO TPRIF
ROU   *          MOVE 'ZMP00000'                      TO TPPRG
ROU   *          MOVE 'ZMS22306'                      TO TPSTM
ROU   *          MOVE W-SQLCODE                       TO TPRETC
ROU   *          MOVE 'PROFILI'                       TO TPARCH
ROU   *          PERFORM TP999-ABEND
ROU   *             THRU TP999-ABEND-END.
       TP404-LEGGI-PROFILO-END.
           EXIT.
       TP410-CANCELLA-COMMAREA.
           MOVE ZEROES TO W-SQLCODE.
           MOVE WCM-TERMIN      TO CMTER-CTER.
           EXEC SQL   INCLUDE   ZMU31101  END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'UPDATE COMMAREA (DELETE)'      TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'ZMU31101'                      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'COMMAREA'                      TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP410-CANCELLA-COMMAREA-END.
           EXIT.
       TP420-LEGGI-TBTABUTE.
           MOVE WCM-CIST    TO ABUTE-CIST.
           MOVE TERMI-CUTE  TO ABUTE-CUTE.
           MOVE ZEROES      TO W-SQLCODE.
           EXEC SQL INCLUDE ZMS22001 END-EXEC.
           IF W-SQL-NON-TROVATO OR
              NOT W-SQL-OK
              MOVE 'LEGGI TABELLA FILIALI '    TO TPRIF
              MOVE 'ZMP00000'                  TO TPPRG
              MOVE 'INCLUDE ZMS22001'          TO TPSTM
              MOVE W-SQLCODE                   TO TPRETC
              MOVE 'ZM.TBTABUTE'               TO TPARCH
              PERFORM TP999-ABEND
            THRU TP999-ABEND-END.
       TP420-LEGGI-TBTABUTE-END.
           EXIT.
      *
       TP222-INCLUDE.
           EXEC SQL INCLUDE ZMS22201 END-EXEC
           .
       TP222-INCLUDE-END.
           EXIT.
      *
       TP224-INCLUDE.
           EXEC SQL INCLUDE ZMS22401 END-EXEC
           .
       TP224-INCLUDE-END.
           EXIT.
      *
       TP220-CANCELLA-BROWSE.
       TP220-CANCELLA-BROWSE-END.
           EXIT.
       TP230-CANCELLA-HELP-OUT.
           MOVE 'µ'             TO  HELP-DA.
           MOVE LOW-VALUE       TO  HELP-A.
           MOVE HLOUT-WHLAREA-TEXT  TO  HELP.
           PERFORM TP235-R-HELP
              THRU TP235-R-HELP-END.
           MOVE HELP            TO  HLOUT-WHLAREA-TEXT.
       TP230-CANCELLA-HELP-OUT-END.
           EXIT.
      * AGGIORNAMENTO COMMAREA : ROUTINE TP600-SCRIVI-COMMAREA
           EXEC SQL INCLUDE ZMYUPCOM END-EXEC.
      *--------------------------------------------------------------*
      *   FORMATTAZIONE DESCRIZIONI ROUTINE TP415-FORM-DESCR
      *--------------------------------------------------------------*
           COPY ZMZDESCR.
      *-------------------------------------------------------------*
      *   LETTURA TABELLA ZM.TBWHLINP                               *
      *   (SALVATAGGIO FORMATO DI INPUT PER HELP)                   *
      *-------------------------------------------------------------*
       TP215-LEGGI-TBWHLINP.
           MOVE ZEROES TO W-SQLCODE.
           EXEC SQL   INCLUDE   ZMS31301  END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA TBWHLINP'       TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'ZMS31301'                      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'ZM.TBWHLINP'                   TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP215-LEGGI-TBWHLINP-END.
           EXIT.
      *-------------------------------------------------------------*
      *   LETTURA TABELLA ZM.TBWHLOUT                               *
      *   (SALVATAGGIO FORMATO DI OUTPUT PER HELP)                  *
      *-------------------------------------------------------------*
       TP217-LEGGI-TBWHLOUT.
           MOVE ZEROES TO W-SQLCODE.
           EXEC SQL   INCLUDE   ZMS31401  END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA TBWHLOUT'       TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'ZMS31401'                      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'ZM.TBWHLOUT'                   TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP217-LEGGI-TBWHLOUT-END.
           EXIT.
      *-----------------------------------------------------------*
      *   INCLUDE DELLE ROUTINE DI LETTURA MESSAGGIO DI INPUT     *
      *   ZMYINOU0 - VERSIONE CICS IMS SENZA SICUREZZA            *
      *   ZMYINOUS - VERSIONE IMS SICUREZZA AZIENDALE             *
      *-----------------------------------------------------------*
      *    EXEC SQL   INCLUDE   ZMYINOUS  END-EXEC.
           EXEC SQL   INCLUDE   ZMYINOU0  END-EXEC.
      *-----------------------------------------------------------*
      *                    SCRITTURA MESSAGGIO DI OUTPUT          *
      *-----------------------------------------------------------*
           EXEC SQL   INCLUDE   ZMYMSOUT  END-EXEC.
      *-----------------------------------------------------------*
      *                        ATTIVAZIONE DI PROGRAMMI           *
      *-----------------------------------------------------------*
           EXEC SQL   INCLUDE   ZMYATTIV  END-EXEC.
      *-----------------------------------------------------------*
      *   ROUTINE STANDARD PER GESTIONE ERRORE                    *
      *-----------------------------------------------------------*
           EXEC SQL   INCLUDE   ZMIERROR  END-EXEC.
      *------------------------------------------------------------*
      *   LETTURA COMMAREA                                         *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYRDCOM END-EXEC.
      *------------------------------------------------------------*
      *    LINK AL PGM DI GESTIONE ACCESSO ESTERNO                 *
      *------------------------------------------------------------*
      *------------------------------------------------------------*
      *   ROUTINE STANDARD PER GESTIONE ABEND DB2                  *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYABEND  END-EXEC.
      *------------------------------------------------------------*
      *   ROUTINE STANDARD PER GESTIONE ABEND CICS                 *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYABECX  END-EXEC.
      *------------------------------------------------------------*
      *   CHIAMATA PER LOG APPLICATIVO                             *
      *------------------------------------------------------------*
      *
      *------------------------------------------------------------*
      * ROUTINE PER EFFETTUARE LA TRASFORMAZIONE DEI CARATTERI     *
      *------------------------------------------------------------*
           COPY  ZMZTRASF.
      *------------------------------------------------------------*
      * PREPARA LA MAPPA PER RITORNO DA HELP TP210-FORMATTA-MAPPA  *
      *------------------------------------------------------------*
           COPY  ZMZRHELP.
      *------------------------------------------------------------*
      * CONTROLLO DI NUMERICITA                                    *
      *------------------------------------------------------------*
           COPY  ZMZCTRNM.
      *------------------------------------------------------------*
      * CONTROLLO DATA                                             *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYCTRDT END-EXEC.
      *------------------------------------------------------------*
      *   CONTIENE AGGIORNAMENTI DELLE TABELLE CMTER,HLOUT,HLINP   *
      *                                        AUTOR,PRBRW         *
      *   PER LA COPY ZMYINOUT                                     *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMIINOUT  END-EXEC.

      *------------------------------------------------------------*
      *   CONTIENE AGGIORNAMENTI DELLE TABELLE CMTER,HLOUT,HLINP   *
      *                                        AUTOR,PRBRW         *
      *   PER LA COPY ZMYMSOUT                                     *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMIMSOUT  END-EXEC.

      *------------------------------------------------------------*
      *  SERIE DI PERFORM PER LA GESTIONE DELLA SICUREZZA INTERNA  *
      *  DELL' AZIENDA                                             *
      *------------------------------------------------------------*
      *    EXEC SQL INCLUDE ZMYSICUR END-EXEC.
      *-------------------------------------------------------------*
      *  GESTIONE SICUREZZA AZIENDALE                               *
      *  1) AGGIORNA TTERMI (PER STAMPANTE)                         *
      *  2) CANCELLA WAUTOR                                         *
      *  3) CANCELLA MATRICOLA                                      *
      *  4) INSERISCE MATRICOLA                                     *
      *  5) ELABORA PROFILO (INTERSEZIONE FRA PROCESSI MATRICOLA E  *
      *                      TERMINALE)                             *
      *  6) INSERISCE WAUTOR                                        *
      *-------------------------------------------------------------*

       TP800-NOACC-ESTERNA.
           IF CMTER-WFASE = 'M'
              MOVE 'ACCESSO NON CORRETTO'          TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'GESTIONE ACCESSO ESTERNO'      TO TPSTM
              MOVE SPACES                          TO TPRETC
              MOVE SPACES                          TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
      *    IF ABL-TER-STAMPANTE GREATER SPACES
      *       MOVE ABL-TER-STAMPANTE    TO TERMI-CTER
      *       PERFORM TP822-AGG-STAMPANTE
      *          THRU TP822-AGG-STAMPANTE-END
      *    END-IF.
      *    IF ABL-TER-STAM132 GREATER SPACES
      *       MOVE ABL-TER-STAM132      TO TERMI-CTER
      *       PERFORM TP822-AGG-STAMPANTE
      *          THRU TP822-AGG-STAMPANTE-END
      *    END-IF.
           MOVE WRK-UTENTE    TO WRK-COMODO-MATR.
           PERFORM TP460-CANCELLA-AUTORIZ
              THRU TP460-CANCELLA-AUTORIZ-END.
           PERFORM TP670-CANCELLA-MATR
              THRU TP670-CANCELLA-MATR-END.
           PERFORM TP675-INSERISCI-MATR
              THRU TP675-INSERISCI-MATR-END.
           PERFORM TP400-ELABORA-PROFILO
              THRU TP400-ELABORA-PROFILO-END.
           PERFORM TP470-INSERISCI-AUTORIZ
              THRU TP470-INSERISCI-AUTORIZ-END.
      *---------------------------------- SELEZIONA CURRENT TIMESTAMP
           PERFORM TP104-PRELEVA-TIMESTAMP
              THRU TP104-PRELEVA-TIMESTAMP-END.
      *-------------------- SALVA IL TIME PER LE SUCCESSIVE OPERAZIONI
           MOVE  WCM-WTIME        TO  CMTER-WTIME.
           MOVE DCLTBWAUTOR       TO  CMTER-WAUTOR.
      *----------------------------- SCRIVE COMMAREA : COPY ZMYUPCOM
           PERFORM TP500-MENU
              THRU TP500-MENU-END.
       TP800-NOACC-ESTERNA-END.
           EXIT.

       TP010-LEGGI-TERMINALE.
           MOVE ZEROES               TO W-SQLCODE.
           MOVE WRK-TERMINALE        TO TERMI-CTER.
           EXEC SQL INCLUDE ZMS22101 END-EXEC.
           IF W-SQL-OK
              PERFORM TP820-AGG-TERMINALE
                 THRU TP820-AGG-TERMINALE-END
           ELSE
              IF W-SQL-NON-TROVATO
                 PERFORM TP821-INS-TERMINALE
                    THRU TP821-INS-TERMINALE-END
              ELSE
                 MOVE 'ERRORE LETTURA TERMINALE'      TO TPRIF
                 MOVE 'ZMP00000'                      TO TPPRG
                 MOVE 'ZMS22101'                      TO TPSTM
                 MOVE W-SQLCODE                       TO TPRETC
                 MOVE 'TBTTERMI   '                   TO TPARCH
                 PERFORM TP999-ABEND
                    THRU TP999-ABEND-END
           END-IF.

           MOVE DCLTBTTERMI          TO CMTER-TTERMI.

       TP010-LEGGI-TERMINALE-END.
              EXIT.

       TP820-AGG-TERMINALE.
           MOVE ZEROES               TO W-SQLCODE.
           MOVE WRK-TERMINALE        TO TERMI-CTER.
           MOVE WCM-CIST             TO TERMI-CIST.
           MOVE SPACES               TO TERMI-CTERASC.
           MOVE WRK-DIPENDENZA       TO TERMI-CUTE.
           MOVE 'V'                  TO TERMI-TTER.
           MOVE SPACES               TO TERMI-CUFFICIO.

           EXEC SQL UPDATE TBTTERMI
                SET TERMI_CIST       = :TERMI-CIST,
                    TERMI_CTERASC    = :TERMI-CTERASC,
                    TERMI_CUTE       = :TERMI-CUTE,
                    TERMI_TTER       = :TERMI-TTER,
                    TERMI_CTERASC5   = :TERMI-CTERASC5,
                    TERMI_CUFFICIO   = :TERMI-CUFFICIO
                    WHERE
                          TERMI_CTER = :TERMI-CTER
           END-EXEC
           MOVE SQLCODE    TO  W-SQLCODE
           IF NOT W-SQL-OK
              MOVE 'ERRORE AGGIORNAMENTO TERMINALE' TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'EXEC SQL UPDATE TBTTERMI'      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'TBTTERMI '                     TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.

       TP820-AGG-TERMINALE-END.
              EXIT.

       TP821-INS-TERMINALE.
           MOVE ZEROES               TO W-SQLCODE.
           MOVE WCM-CIST             TO TERMI-CIST.
           MOVE WRK-TERMINALE        TO TERMI-CTER.
           MOVE WRK-DIPENDENZA       TO TERMI-CUTE.
           MOVE 'V'                  TO TERMI-TTER.
           MOVE SPACES               TO TERMI-CTERASC.
           MOVE SPACES               TO TERMI-CTERBCK
                                        TERMI-CTERASC3
                                        TERMI-CTERASC4
                                        TERMI-CTERASC5.
           MOVE SPACES               TO TERMI-CUFFICIO.

           EXEC SQL INCLUDE ZMV22101 END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE INSERIMENTO TERMINALE'  TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMV22101'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'TBTTERMI '                     TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.

       TP821-INS-TERMINALE-END.
              EXIT.
BPOA07 INSERISCI-LOG.
BPOA07     MOVE ZEROES                 TO  W-SQLCODE.
BPOA07     MOVE WCM-CIST               TO  LOGFF-CIST
BPOA07     MOVE SIPRACF-USERID         TO  LOGFF-MATRICOLA
BPOA07     MOVE SIPRACF-PROFILO        TO  LOGFF-CPROFILO
BPOA07     MOVE SIPRACF-TERMINALE      TO  LOGFF-TERMINALE
BPOA07     MOVE SIPRACF-DIP-LIV-USERID TO  LOGFF-DIPOPEX-PR
BPOA07     MOVE CMTER-DIPOPEXFO        TO  LOGFF-DIPOPEX-FO
BPOA07     MOVE SPACES                 TO  LOGFF-DATI.
BPOA07     EXEC SQL INCLUDE ZMV96101 END-EXEC.
BPOA07     IF NOT W-SQL-OK
BPOA07        MOVE 'ERRORE INSERIMENTO LOGFF    '  TO TPRIF
BPOA07        MOVE 'ZMP00000'                      TO TPPRG
BPOA07        MOVE 'INCLUDE ZMV96101'              TO TPSTM
BPOA07        MOVE W-SQLCODE                       TO TPRETC
BPOA07        MOVE 'TBTLOGFF '                     TO TPARCH
BPOA07        PERFORM TP999-ABEND
BPOA07           THRU TP999-ABEND-END.
BPOA07
BPOA07 INSERISCI-LOG-END.
BPOA07        EXIT.

       TP822-AGG-STAMPANTE.
           MOVE ZEROES               TO W-SQLCODE.
           MOVE WCM-CIST             TO TERMI-CIST.
           MOVE 'S'                  TO TERMI-TTER.
           MOVE WRK-DIPENDENZA       TO TERMI-CUTE.
           MOVE SPACES               TO TERMI-CTERASC.
           MOVE SPACES               TO TERMI-CTERBCK.
           MOVE SPACES               TO TERMI-CTERASC3.
           MOVE SPACES               TO TERMI-CTERASC4.
           MOVE SPACES               TO TERMI-CTERASC5.
           MOVE SPACES               TO TERMI-CUFFICIO.

           EXEC SQL UPDATE TBTTERMI
                SET TERMI_CIST       = :TERMI-CIST,
                    TERMI_TTER       = :TERMI-TTER,
                    TERMI_CTER       = :TERMI-CTER,
                    TERMI_CUTE       = :TERMI-CUTE,
                    TERMI_CTERASC    = :TERMI-CTERASC,
                    TERMI_CTERBCK    = :TERMI-CTERBCK,
                    TERMI_CTERASC3   = :TERMI-CTERASC3,
                    TERMI_CTERASC4   = :TERMI-CTERASC4,
                    TERMI_CTERASC5   = :TERMI-CTERASC5,
                    TERMI_CUFFICIO   = :TERMI-CUFFICIO
                    WHERE
CIST  *                   TERMI_CIST = :TERMI-CIST  AND
                          TERMI_CTER = :TERMI-CTER
           END-EXEC
           MOVE SQLCODE    TO  W-SQLCODE
           IF W-SQL-NON-TROVATO
              PERFORM TP823-INS-STAMPANTE
                 THRU TP823-INS-STAMPANTE-END
           ELSE
              IF NOT W-SQL-OK
                 MOVE 'ERRORE UPDATE STAMPANTE' TO TPRIF
                 MOVE 'ZMP00000'                TO TPPRG
                 MOVE  TERMI-CTER               TO TPSTM
                 MOVE  W-SQLCODE                TO TPRETC
                 MOVE 'TBTTERMI '               TO TPARCH
                 PERFORM TP999-ABEND
                    THRU TP999-ABEND-END.

           MOVE CMTER-TTERMI        TO DCLTBTTERMI.

       TP822-AGG-STAMPANTE-END.
              EXIT.

       TP823-INS-STAMPANTE.
           MOVE ZEROES               TO W-SQLCODE.
      *    EXEC SQL INCLUDE ZMV22101 END-EXEC.
           EXEC SQL INSERT INTO TBTTERMI
                          (TERMI_CIST,
                           TERMI_CTER,
                           TERMI_CTERASC,
                           TERMI_CUTE,
                           TERMI_TTER,
                           TERMI_CTERBCK,
                           TERMI_CTERASC3,
                           TERMI_CTERASC4,
                           TERMI_CTERASC5,
                           TERMI_CUFFICIO)
                   VALUES (:TERMI-CIST,
                           :TERMI-CTER,
                           :TERMI-CTERASC,
                           :TERMI-CUTE,
                           :TERMI-TTER,
                           :TERMI-CTERBCK,
                           :TERMI-CTERASC3,
                           :TERMI-CTERASC4,
                           :TERMI-CTERASC5,
                           :TERMI-CUFFICIO)
           END-EXEC
           MOVE SQLCODE  TO W-SQLCODE
           IF NOT W-SQL-OK
              MOVE 'ERRORE INSERT STAMPANTE'  TO TPRIF
              MOVE 'ZMP00000'                 TO TPPRG
              MOVE 'INSERT SU TERMINALI'      TO TPSTM
              MOVE  TERMI-CTER                TO TPRETC
              MOVE 'TBTTERMI '                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.

       TP823-INS-STAMPANTE-END.
              EXIT.

       TP460-CANCELLA-AUTORIZ.
           MOVE WRK-COMODO-MATR        TO AUTOR-NMTRUTE.
           MOVE WCM-TERMIN             TO AUTOR-CTER.
           MOVE WCM-CIST       TO   AUTOR-CIST.
      *    EXEC SQL   INCLUDE   ZMU31001  END-EXEC.
           EXEC SQL UPDATE TBWAUTOR
                   SET  AUTOR_CPROFILO  = ' ',
                        AUTOR_CPROFOP   = ' ',
                        AUTOR_NMTRUTE   = ' '
                   WHERE
                         AUTOR_CTER  = :AUTOR-CTER
           END-EXEC
           MOVE SQLCODE           TO W-SQLCODE
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'UPDATE AUTORIZZAZIONI(DELETE)' TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMU31001'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'AUTORIZZAZIONI'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
           IF W-SQL-NON-TROVATO
              MOVE 'NO' TO WRK-FOUND-ABILITA
           ELSE
              MOVE 'SI' TO WRK-FOUND-ABILITA.
      *    EXEC SQL   INCLUDE   ZMU31003  END-EXEC.
           EXEC SQL UPDATE TBWAUTOR
                   SET  AUTOR_CPROFILO  = ' ',
                        AUTOR_CPROFOP   = ' '
                   WHERE
                         AUTOR_NMTRUTE  = :AUTOR-NMTRUTE
           END-EXEC
           MOVE SQLCODE           TO W-SQLCODE
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'UPDATE AUTORIZZAZIONI(DELETE)' TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMU31003'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'AUTORIZZAZIONI'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP460-CANCELLA-AUTORIZ-END.
           EXIT.
       TP470-INSERISCI-AUTORIZ.
           MOVE ZEROES TO W-SQLCODE.
           MOVE WCM-CIST         TO AUTOR-CIST.
           MOVE WCM-CPROFILO1    TO AUTOR-CPROFILO.
           MOVE WCM-CPROFILO2    TO AUTOR-CPROFOP.
           MOVE WCM-TERMIN       TO AUTOR-CTER.
           MOVE WRK-COMODO-MATR  TO AUTOR-NMTRUTE.
220496     MOVE DCLTBWAUTOR      TO CMTER-WAUTOR.
           IF WRK-FOUND-ABILITA = 'SI'
      *       EXEC SQL   INCLUDE   ZMU31002  END-EXEC
           EXEC SQL UPDATE TBWAUTOR
                   SET  AUTOR_CPROFILO  = :AUTOR-CPROFILO,
                        AUTOR_CPROFOP   = :AUTOR-CPROFOP,
                        AUTOR_NMTRUTE   = :AUTOR-NMTRUTE
                   WHERE
                         AUTOR_CTER  = :AUTOR-CTER
           END-EXEC
           MOVE SQLCODE           TO W-SQLCODE
              IF NOT W-SQL-OK
                 MOVE 'UPDATE AUTORIZZAZIONI'         TO TPRIF
                 MOVE 'ZMP00000'                      TO TPPRG
                 MOVE 'INCLUDE ZMU31002'              TO TPSTM
                 MOVE W-SQLCODE                       TO TPRETC
                 MOVE 'AUTORIZZAZIONI'                TO TPARCH
                 PERFORM TP999-ABEND
                    THRU TP999-ABEND-END
              ELSE
                 GO TO TP470-INSERISCI-AUTORIZ-END.
      *    EXEC SQL   INCLUDE   ZMV31001  END-EXEC.
           EXEC SQL
            INSERT INTO TBWAUTOR
             (AUTOR_CPROFILO,
              AUTOR_CPROFOP,
              AUTOR_CTER,
              AUTOR_NMTRUTE,
              AUTOR_CIST)
            VALUES
             (:AUTOR-CPROFILO,
              :AUTOR-CPROFOP,
              :AUTOR-CTER,
              :AUTOR-NMTRUTE,
              :AUTOR-CIST)
           END-EXEC
           MOVE SQLCODE           TO W-SQLCODE
           IF NOT W-SQL-OK
              MOVE 'INSERT AUTORIZZAZIONI'         TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMV31001'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'AUTORIZZAZIONI'                TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP470-INSERISCI-AUTORIZ-END.
           EXIT.
      *------------------------------------------------------------*
       TP670-CANCELLA-MATR.
           MOVE TERMI-CIST          TO ABUMA-CIST.
           MOVE WRK-COMODO-MATR     TO ABUMA-NMTRUTE.
           MOVE ZEROES              TO W-SQLCODE.
      *    EXEC SQL INCLUDE ZMD21701 END-EXEC.
           EXEC SQL
               DELETE  FROM TBTABUMA
                WHERE
CIST  *                ABUMA_CIST    = :ABUMA-CIST  AND
                       ABUMA_NMTRUTE = :ABUMA-NMTRUTE
           END-EXEC.
           MOVE SQLCODE       TO W-SQLCODE.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'CANCELLA MATRICOLA'            TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMD21701'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'MATRICOLE'                     TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP670-CANCELLA-MATR-END.
           EXIT.
      *------------------------------------------------------------*
       TP675-INSERISCI-MATR.
           MOVE ZEROES              TO W-SQLCODE.
           MOVE ZEROES              TO ABUMA-CASSA.
           MOVE SPACES              TO ABUMA-CASSIERE.
           MOVE WCM-CIST            TO ABUMA-CIST.
           MOVE WRK-PROFILO         TO ABUMA-CPROFILO.
           MOVE SPACES              TO ABUMA-CPSW.
           MOVE SPACES              TO ABUMA-CSIGUTE.
           MOVE WRK-DIPENDENZA      TO ABUMA-CUTE.
           MOVE 99999999            TO ABUMA-DSCAPSW.
           MOVE ZEROES              TO ABUMA-FPSW.
           MOVE WRK-COMODO-MATR     TO ABUMA-NMTRUTE.
      *    EXEC SQL INCLUDE ZMV21701 END-EXEC.
           EXEC SQL
               INSERT INTO TBTABUMA
                      (ABUMA_CASSA,
                       ABUMA_CASSIERE,
                       ABUMA_CIST,
                       ABUMA_CPROFILO,
                       ABUMA_CPSW,
                       ABUMA_CSIGUTE,
                       ABUMA_CUTE,
                       ABUMA_DSCAPSW,
                       ABUMA_FPSW,
                       ABUMA_NMTRUTE)
               VALUES (:ABUMA-CASSA,
                       :ABUMA-CASSIERE,
                       :ABUMA-CIST,
                       :ABUMA-CPROFILO,
                       :ABUMA-CPSW,
                       :ABUMA-CSIGUTE,
                       :ABUMA-CUTE,
                       :ABUMA-DSCAPSW,
                       :ABUMA-FPSW,
                       :ABUMA-NMTRUTE)
           END-EXEC
           MOVE SQLCODE        TO W-SQLCODE
           IF NOT W-SQL-OK
              MOVE 'INSERISCI MATRICOLA'           TO TPRIF
              MOVE 'ZMP00000'                      TO TPPRG
              MOVE 'INCLUDE ZMV21701'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'MATRICOLE'                     TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP675-INSERISCI-MATR-END.
           EXIT.
BPOA07*PRIMA DI CHIAMARE IL PROGRAMMA INIZIAIZZARE AREA COMUNE
BPOA07 AREA-COMUNE.
BPOA07     MOVE ABUTE-CUTE TO WRK-DIPENDENZA
BPOA07     PERFORM TP010-LEGGI-TERMINALE
BPOA07        THRU TP010-LEGGI-TERMINALE-END.
BPOA07
BPOA07*---------------------------------------------------------------
BPOA07* LEGGE ISTITUTI
BPOA07*---------------------------------------------------------------
BPOA07     PERFORM TP030-READ-IST
BPOA07        THRU TP030-READ-IST-END.
BPOA07
BPOA07*---------------------------------------------------------------
BPOA07* LEGGE CONFIGURAZIONE TECNICA
BPOA07*---------------------------------------------------------------
BPOA07     PERFORM TP040-READ-CONFIG
BPOA07        THRU TP040-READ-CONFIG-END.
BPOA07*---------------------------------------------------------------
BPOA07* PULIZIA CAMPI INPHE-WPROC-INP / INPHE-WDATI-INP
BPOA07* UTILIZZATI DA SSUSI-SMAPS-SIDIBA PER CHIAMARE SISEB3
BPOA07*---------------------------------------------------------------
BPOA07*---------------------------------------------------------------
BPOA07* DECODIFICA DESCRIZIONE FILIALE
BPOA07*---------------------------------------------------------------
BPOA07       MOVE TERMI-CIST     TO ABUTE-CIST
BPOA07     IF WRK-FILALFNUM = 0
BPOA07       MOVE TERMI-CUTE     TO ABUTE-CUTE
BPOA07     ELSE
BPOA07       MOVE WRK-FILALFNUM  TO ABUTE-CUTE
BPOA07     END-IF
BPOA07      PERFORM TP015-READ-TBTABUTE
BPOA07         THRU TP015-READ-TBTABUTE-END
BPOA07     COPY ZMZFILIA.
BPOA07     MOVE WCM-DFIL       TO TP-DFIL.
BPOA07     MOVE TERMI-CUTE     TO WCM-CDPZ.
BPOA07 AREA-COMUNE-END.
BPOA07     EXIT.

IM0001 RECUPERA-CODICE-ABI.
IM0001*---------------------------------------------------------------
IM0001* CHIAMA ROUTINE ESTERNA PER PRELEVARE:
IM0001*     CIST
IM0001*---------------------------------------------------------------
IM0001     INITIALIZE ZMWN2042
IM0001     MOVE 'S' TO WN204-COD-AZIONE.
IM0001     MOVE '3' TO WN204-COD-RICHIESTA.
IM0001
IM0001     MOVE 'ZMRN2042'         TO WCM-CHIAMATO
TEST0      DISPLAY 'ZMP00000 WN204-COD-AZIONE    ' WN204-COD-AZIONE
TEST0      DISPLAY 'ZMP00000 WN204-COD-RICHIESTA ' WN204-COD-RICHIESTA
IM0001     CALL WCM-CHIAMATO USING ZMWN2042
IM0001*    EXEC CICS LINK
IM0001*        PROGRAM (WCM-CHIAMATO)
IM0001*        COMMAREA (ZMWN2042)
IM0001*        LENGTH   (LENGTH OF ZMWN2042)
IM0001*    END-EXEC.
IM0001     .
IM0001 RECUPERA-CODICE-ABI-END.
IM0001     EXIT.
