       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZMP00020.
      ***************************************************************
      * DATAMAT SPA - AREA PRODOTTI BANCARI -                      **
      ***************************************************************
      ***************************************************************
      * PROGETTO         : SISEB III                               **
      * SOTTOPROGETTO    : FUNZIONI COMUNI TP                      **
      * CODICE PROGRAMMA : ZMP00020                                **
      * DESCRIZIONE      : PROGRAMMA HELP                          **
      * DATA STESURA     : 9 OTTOBRE 1995                          **
      ***************************************************************
      * REVISIONE NUM.   : 000397                                  **
      *           DATA   : 30/10/2000                              **
      *           MOTIVO : ANOMALIA GESTIONE TRASCODIFICA          **
      *------------------------------------------------------------**
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       77  WRK-USCITA                 PIC X(02) VALUE SPACES.
       77  WRK-MAX-RIGHE              PIC 9(02) VALUE 17.
       77  WRK-MAX-HELP               PIC 9(02) VALUE 17.
       77  WRK-MAX-TASTI              PIC 9(02) VALUE 24.
260496 77  WRK-MAX-PFK                PIC 9(02) VALUE 12.
       77  WRK-MAX-TAB                PIC 9(02) VALUE 24.
       77  WRK-MAX-ERRORE             PIC 9(02) VALUE 15.
       77  WRK-MAX-DESCRIZIONE        PIC 9(02) VALUE 17.
       01  WRK-TASTI.
           03  WRK-DESCRIZIONE-TASTI.
               05                     PIC X(09) VALUE 'HHELP    '.
               05                     PIC X(09) VALUE 'ECLEAR   '.
               05                     PIC X(09) VALUE 'RRITORNO '.
               05                     PIC X(09) VALUE 'IINDIETRO'.
               05                     PIC X(09) VALUE 'AAVANTI  '.
               05                     PIC X(09) VALUE 'WINSERIM '.
               05                     PIC X(09) VALUE 'CAGGIORNA'.
               05                     PIC X(09) VALUE 'DANNULLAM'.
               05                     PIC X(09) VALUE 'SAUTORIZ '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
               05                     PIC X(09) VALUE '         '.
           03  WRK-TABELLA-TASTI REDEFINES WRK-DESCRIZIONE-TASTI.
               05  WRK-ELE-TASTI OCCURS 24.
                   07  WRK-LETTERA-TASTI    PIC X(01).
                   07  WRK-FUNZIONE-TASTI   PIC X(08).

       01  WRK-CAMPO-FUNZIONE.
           03                           PIC X(01) VALUE 'F'.
           03  WRK-TASTO                PIC 9(02).
           03                           PIC X(01).
           03  WRK-FUNZIONE             PIC X(08).

       01  WRK-RIGA-ERRORI.
           03                           PIC X(33) VALUE ALL'-'.
           03                           PIC X(10) VALUE ' MESSAGGI '.
           03                           PIC X(34) VALUE ALL'-'.

       01  WRK-CAMPI-COMODO.
           03  WRK-TAB-PFK-PRPCS.
               05  WRK-ELE-PFK-PRPCS  OCCURS 24.
                   07  WRK-PFK-PRPCS           PIC X(01).
           03  WRK-TAB-PFK-CONFG.
               05  WRK-ELE-PFK-CONFG  OCCURS 24.
                   07  WRK-PFK-CONFG           PIC X(01).
           03  WRK-TABELLA-MESSAGGIO.
               05  WRK-ELE-MESSAGGIO  OCCURS 17.
                   07  WRK-MESSAGGIO           PIC X(77).
           03  WRK-TABELLA-ERRORE.
               05  WRK-ELE-ERRORE     OCCURS 15.
                   07  WRK-CODICE-ERRORE       PIC X(04).
                   07                          PIC X(01).
                   07  WRK-DESCRIZIONE-ERRORE  PIC X(72).
           03  WRK-TABELLA-DESCRIZIONE.
               05  WRK-ELE-DESCRIZIONE   OCCURS 17.
                   07  WRK-DESCRIZIONE         PIC X(77).
           03  WRK-TAB-CODERR1.
               05  WRK-ELE-CODERR1   OCCURS 15 PIC X(04).
           03  WRK-TAB-CODERR2.
               05  WRK-ELE-CODERR2   OCCURS 15 PIC X(04).
           03  WRK-INDICE-ERRORE                PIC 9(02) VALUE ZEROES.
           03  WRK-INDICE-DESCRIZIONE           PIC 9(02) VALUE ZEROES.
           03  WRK-IND1-LEN                     PIC 9(02) VALUE ZEROES.
           03  WRK-TERMIN                       PIC X(08) VALUE SPACES.
           03  WRK-COD-ERR                      PIC X(04) VALUE SPACES.
           03  WRK-SCELTA                       PIC X(01) VALUE SPACES.
           03  WRK-CPCS                         PIC 9(04) VALUE ZEROES.
           03  WRK-CDPZ1                        PIC 9(05) VALUE ZEROES.
           03  WRK-CUTERIF                      PIC 9(05) VALUE ZEROES.
           03  WRK-NSUBMOVP                     PIC 9(01) VALUE ZEROES.
           03  WRK-COMO-DESC1                   PIC X(30) VALUE SPACES.
           03  WRK-COMO-DESC2                   PIC X(30) VALUE SPACES.
           03  WRK-TROVATO                      PIC X(02) VALUE SPACES.
           03  WRK-TROVATO-TASTO                PIC X(02) VALUE SPACES.
           03  WRK-FLAGN2                       PIC 9(02) VALUE ZEROES.
           03  WRK-FLAG-OPERAZ                  PIC X(01) VALUE SPACES.
           03  COMODO-IDECR-OUT                 PIC X(8)  VALUE SPACES.
           03  COMODO-IDECR-CTRAN               PIC X(8)  VALUE SPACES.
           03  WRK-IND3-LEN                     PIC 9(2)  VALUE ZEROS.
           03 WRK-TAB-ERRORE.
              05 WRK-COD-ERRORE OCCURS 15 PIC X(004).
           03 WRK-TAB-ERRORE-1.
              05 WRK-COD-ERRORE-1 OCCURS 15 PIC X(004).
      *--------  DEFINIZIONE CAMPI COMUNI A TUTTI I PROGRAMMI  ------*
           COPY ZMWCOMUN.
      *------   AREA DI WORKING PER CHIAMATE DL/I (IMS)--------------*
           COPY ZMWDLIFU.
      *--------  AREA DI WORKING PER  ERRORI SQL  --------------------*
           COPY ZMWSQLRC.
      *----  AREA DI WORKING PER CONTROLLI NUMERICI ------------------*
           COPY ZMWCTRNM.
      *----  AREA DI WORKING PER CHIAMATA ROUTINE ZMBSGSCA  ----------*
           COPY ZMWSGSCA.
      *------   AREA DI WORKING PER ABEND GENERICI -------------------*
       01 ZMWM9999.
           COPY ZMWM9999.
      *------   AREA DI WORKING PER ABEND CICS     -------------------*
           COPY ZMWM9997.
      *------   AREA DI WORKING PER CONVERSIONI DATE -----------------*
           COPY ZMWCTRDT.
      *----  AREA DI WORKING PER ATTRIBUTI --------------------------*
           COPY ZMWATTRB.
      *----  AREA DI WORKING PER ABILITAZIONE PFKEYS  ---------------*
       01  TAB-PFK.
           03   PFK                 PIC X     OCCURS 24.
      *--------------------------------------------------------------*
      *----  DEFINIZIONE AREA  PER TP MONITOR -----------------------*
      *--------------------------------------------------------------*
      *----  RICERCA CODICE TRANSAZIONE -----------------------------*
           COPY ZMWIDECR.
       01  CMTER-DATI.
           03                            PIC X(004).
           03  CMTER-DATI-TRAN.
               05  CMTER-DATI-AREA       PIC X(200).
           03  CMTER-TABELLA-RITORNO.
               05  CMTER-WORK OCCURS 10.
                   07  CMTER-CPCS-PREC  PIC 9(004).
                   07  CMTER-AREA-RIT   PIC X(200).
151295*    03                           PIC X(256).
151295     03                           PIC X(135).
151295     03  CMTER-TAB-COD-ERR        PIC X(060).
151295     03  CMTER-TAB-COD-ERR-1      PIC X(060).
151295     03                           PIC X(001).

      *----  COPY AREA DI COMUNICAZIONE            ------------------*
           COPY ZMWCOM02.
           COPY ZMWCOM10.

      *----  AREA COMUNE STANDARD MAPPE TP MONITOR ------------------*
           COPY ZMXMPSTD.
      *-- RIDEFINIZIONE SPECIFICA MESSAGGIO DI INPUT E DI OUTPUT  ---*
           COPY ZMM00002.
      *--------------------------------------------------------------*
      *----  DECLARE DB2  -------------------------------------------*
      *--------------------------------------------------------------*
      *------   SQLCA   ---------------------------------------------*
           EXEC SQL   INCLUDE   SQLCA     END-EXEC.
      *------   SALVATAGGIO INPUT  PER HELP : ZM.TPWHLINP -----------*
      *------               OUTPUT PER HELP : ZM.TPWHLOUT -----------*
           EXEC SQL INCLUDE ZMGHLINP END-EXEC.
           EXEC SQL INCLUDE ZMGHLOUT END-EXEC.
      *------   COMMAREA PROCESSI : ZM.TBWCMTER ---------------------*
           EXEC SQL INCLUDE ZMGCMTER END-EXEC.
      *------   AREA COMUNI PER DB2  --------------------------------*
           EXEC SQL   INCLUDE ZMICOMUN    END-EXEC.
      *------   TERMINALI: ZM.TBTTERMI     --------------------------*
      *------              ZM.TBTSTPAS     --------------------------*
           EXEC SQL INCLUDE ZMGTERMI END-EXEC.
      *    EXEC SQL INCLUDE ZMGSTPAS END-EXEC.
      *------   PROCESSI : ZM.WPRCPS (315) --------------------------*
      *------              ZM.WPRMEN (316) --------------------------*
           EXEC SQL INCLUDE ZMGPRPCS END-EXEC.
           EXEC SQL INCLUDE ZMGPRMEN END-EXEC.
      *------   TABELLA ANAGRAFICA POSIZIONI : ZM.TBANAPOS -----*
           EXEC SQL INCLUDE ZMGNAPOS END-EXEC.
      *------   ISTITUTI          : ZM.TBTISTI  ---------------------*
           EXEC SQL INCLUDE ZMGISTI  END-EXEC.
      *------   OPERATIVITA' PER ISTITUTO...: ZM.TBTOPEIS (231) -----*
           EXEC SQL INCLUDE ZMGOPEIS END-EXEC.
      *------   PAGINE PER BROWSE : ZM.TBWPRBRW (312) ---------------*
           EXEC SQL INCLUDE ZMGPRBRW END-EXEC.
      *------   PROFILI           : ZM.TBTPROFI (223) ---------------*
           EXEC SQL INCLUDE ZMGPROFI END-EXEC.
      *------   ABILITAZIONI      : ZM.TBWAUTOR (310) ---------------*
           EXEC SQL INCLUDE ZMGAUTOR END-EXEC.
      *------   ERRORI TECNICI    : ZM.TBTTRERR (222) ---------------*
           EXEC SQL INCLUDE ZMGTRERR END-EXEC.
      *------   ERRORI FUNZIONALI : ZM.TBTABERR (224) ---------------*
           EXEC SQL INCLUDE ZMGABERR END-EXEC.
      *------   CONFIGURAZIONE    : ZM.TBTCONFG (309) ---------------*
           EXEC SQL INCLUDE ZMGCONFG END-EXEC.
      *------   TABELLA MATRICOLE : ZM.TBTABUMA (217) ---------------*
           EXEC SQL INCLUDE ZMGABUMA END-EXEC.
      *------   TABELLA FILIALI   : ZM.TBTABUTE (220) ---------------*
           EXEC SQL INCLUDE ZMGABUTE END-EXEC.
      *------   TABELLA PROCESSO  : ZM.TBTAPROC (   ) ---------------*
           EXEC SQL INCLUDE ZMGAPROC END-EXEC.
      *------   TABELLA           : ZM.TBWINPHE (   ) ---------------*
           EXEC SQL INCLUDE ZMGINPHE END-EXEC.
GIOVY *------ TABELLA PROCESSI    : ZM.TBTOPEFL (258) ---------------*
GIOVY      EXEC SQL INCLUDE ZMGOPEFL END-EXEC.

       LINKAGE SECTION.

      *------  DEFINIZIONE IOPCB (SOLO PER IMS)         --------------*
      *    COPY ZMXPCBIO.
      *------  DEFINIZIONE ALTPCB (SOLO PER IMS)        --------------*
      *    COPY ZMXPCBAL.

       PROCEDURE DIVISION.
       MAIN-SECTION.
           INITIALIZE WRK-CAMPI-COMODO
                      WCM-AREA-VARIABILE.
      *------ GESTIONE ABEND CICS ------------------------------------
           EXEC SQL INCLUDE ZMYHANDL END-EXEC.
      *---------------------------------------------------------------*
           COPY ZMYENTR1.
      *------  ENTRY (IMS) PER IO-PCB E ALT-PCB ----------------------*
           COPY ZMYENTR2.
      *------ GET UNIQUE  (SOLO PER IMS) -----------------------------
           COPY ZMYGETUN.
      *------  INIZIALIZZAZIONE VARIABILI ----------------------------*
           EXEC SQL INCLUDE ZMYINIZW END-EXEC.

      *---------------------------------------------------------------
      * LETTURA TABELLA TERMINALI ZM.TBTTERMI
      *                           ZM.TBTSTPAS
      *---------------------------------------------------------------
           MOVE CMTER-TTERMI     TO DCLTBTTERMI.
           MOVE TERMI-CIST       TO WCM-CIST.
           MOVE TERMI-CTERASC    TO WCM-PRINTER.
      *---------------------------------------------------------------
      * LEGGE CONFIGURAZIONE TECNICA
      *---------------------------------------------------------------
           MOVE CMTER-WCONFG     TO DCLTBWCONFG.
      *---------------------------------------------------------------
      * DECODIFICA DESCRIZIONE FILIALE
      *---------------------------------------------------------------
           MOVE CMTER-TABUTE     TO DCLTBTABUTE.
           COPY ZMZFILIA.
           MOVE WCM-DFIL       TO TP-DFIL.
           MOVE ABUTE-CUTE     TO WCM-CDPZ.
           MOVE ABUTE-CUTERIF  TO WRK-CUTERIF.
           MOVE SPACES         TO WRK-FLAG-OPERAZ.
      *---------------------------------------------------------------
      * RICEZIONE MESSAGGIO (CICS)
      * IN QUESTA COPY VENGONO ESEGUITE :
      * LETTURA COMMAREA , IMPOSTAZIONE PROCESSO E RECEIVE MAPPA
      *---------------------------------------------------------------
      * RICEZIONE MESSAGGIO (IMS)
      * IN QUESTA COPY VIENE ESEGUITA :
      * L'IMPOSTAZIONE PROCESSO
      *---------------------------------------------------------------

           COPY ZMYRICE2.

      *--------------------------------------------------------------*
      *                   IMPOSTA FUNZIONE                           *
      *--------------------------------------------------------------*
           MOVE M0002-FUNZIONE                TO WCM-FUNZ.
           MOVE CMTER-DATI-TRAN               TO CMTER-DATI-ZMP00020.
      *--------------------------------------------------------------*
      *    LETTURA AUTORIZZAZIONI E ABILITAZIONI UTENTI              *
      *--------------------------------------------------------------*
           IF CMTER-WFASE NOT = 'M'
              IF CMTER-00020-CPCS NOT = ZEROES
                 MOVE CMTER-WAUTOR   TO DCLTBWAUTOR
                 MOVE CMTER-TABUMA   TO DCLTBTABUMA
                 MOVE AUTOR-NMTRUTE  TO WCM-NMTRUTE.
      *--------------------------------------------------------------*
      *                   LETTURA TABELLA ISTITUTO                   *
      *--------------------------------------------------------------*
           PERFORM TP030-READ-IST
              THRU TP030-READ-IST-END.
      *---------------------------------------------------------------
      * GESTIONE CICLI DI ELABORAZIONE
      *---------------------------------------------------------------
       SCEGLI-CICLO.

           PERFORM TP050-CICLO-PGM
              THRU TP050-CICLO-PGM-END.

           IF WCM-INVIO-MAPPA = 'S'
              GO TO TP900-INVIO-MAPPA.

      *---------------------------------------------------------------
      * CONTROLLO TASTI FUNZIONALI
      *---------------------------------------------------------------
           MOVE PRPCS-WMPPFK TO TAB-PFK.

           IF WCM-PFK GREATER ZEROES
              MOVE WCM-PFK    TO WCM-PFK-IND
              IF PFK (WCM-PFK-IND) = 'N'
      *-------- WA01 ==> TASTO FUNZIONALE ERRATO
                 MOVE 'WA01'    TO WCM-COD-ERR(1)
                 MOVE ATT-CURS         TO M0002-FUNZIONEL
                 PERFORM TP998-ERRORE
                    THRU TP998-ERRORE-END
                 PERFORM TP110-CICLO-UNO
                    THRU TP110-CICLO-UNO-END
                 GO TO TP900-INVIO-MAPPA
              END-IF
              IF PFK (WCM-PFK-IND) NOT GREATER SPACES
                 MOVE CONFG-WMPPFK TO TAB-PFK
                 IF PFK (WCM-PFK-IND) = 'N' OR NOT GREATER SPACES
      *-------- WA01 ==> TASTO FUNZIONALE ERRATO
                    MOVE 'WA01'    TO WCM-COD-ERR(1)
                    MOVE ATT-CURS  TO M0002-FUNZIONEL
                    PERFORM TP998-ERRORE
                       THRU TP998-ERRORE-END
                    PERFORM TP110-CICLO-UNO
                       THRU TP110-CICLO-UNO-END
                    GO TO TP900-INVIO-MAPPA
                 END-IF
              END-IF
              EVALUATE PFK (WCM-PFK-IND)
                 WHEN 'R'
                    PERFORM GESTIONE-FUNZIONE-R
                       THRU GESTIONE-FUNZIONE-R-END
                 WHEN OTHER
      *-------- WA02 ==> FUNZIONE NON CONSENTITA DAL PGM
                    MOVE 'WA02'    TO WCM-COD-ERR(1)
                    MOVE ATT-CURS  TO M0002-FUNZIONEL
                    PERFORM TP998-ERRORE
                       THRU TP998-ERRORE-END
                    PERFORM TP110-CICLO-UNO
                       THRU TP110-CICLO-UNO-END
                    GO TO TP900-INVIO-MAPPA
              END-EVALUATE.

      *--------------------------------------------------------------*
      *            RITORNO AL MENU PER RICHIESTA FUNZIONE            *
      *--------------------------------------------------------------*

           IF WCM-PFK NOT GREATER ZEROES AND
              WCM-FUNZ GREATER SPACES
              PERFORM TP195-GESFUN
                 THRU TP195-GESFUN-END
              IF WCM-ERRORE = 'SI'
                 GO TO TP900-INVIO-MAPPA.

      *---------------------------------------------------------------
      *      ESECUZIONE PRIMO CICLO PER TASTO DI INVIO
      *---------------------------------------------------------------

           IF WCM-PFK NOT GREATER ZEROES
              PERFORM TP110-CICLO-UNO
                 THRU TP110-CICLO-UNO-END
           END-IF.

           IF CMTER-WFASE = '1' AND
              WCM-PFK NOT GREATER ZEROES
              PERFORM TP130-CONTROLLA-SCELTA
                 THRU TP130-CONTROLLA-SCELTA-END
              VARYING IND2 FROM 1 BY 1
                UNTIL IND2 > WRK-MAX-RIGHE
              IF WRK-TROVATO = 'SI'
                 MOVE IDECR-PGM            TO  CMTER-WPRG
                 MOVE SPACES               TO  IDECR-CAMPI-INPUT
                 MOVE '1'                  TO  IDECR-TIPRICE
                 MOVE WCM-CIST             TO  IDECR-CIST
                 PERFORM TP200-TABELLA-CMTER-A
                    THRU TP200-TABELLA-CMTER-A-END
                 INITIALIZE                    CMTER-DATI-ZMP00100
                 MOVE WRK-COD-ERR          TO  CMTER-00100-CODERR
                 MOVE CMTER-DATI-ZMP00100  TO  CMTER-DATI-TRAN
                 MOVE  0002                TO  CMTER-WCPCSIN
                 MOVE '0010'               TO  IDECR-VALORE
                 MOVE  0010                TO  CMTER-CPCS
                 MOVE  0                   TO  CMTER-WFASE
                 MOVE  'H'                 TO  CMTER-WHELP
      *---------------------------------------------- COPY ZMYIDECR
                 PERFORM TP020-DECOD-ID
                    THRU TP020-DECOD-ID-END
                 PERFORM TP700-START-PGM
                    THRU TP700-START-PGM-END
              END-IF
           END-IF.

       TP900-INVIO-MAPPA.
      *--------------------------------------------------------------
           PERFORM VARYING IND1 FROM 1 BY 1
                 UNTIL IND1 > WRK-MAX-RIGHE
                       IF  M0002-MSG(IND1) > SPACES
                           MOVE ATT-UANY  TO  M0002-SELA(IND1)
                       ELSE
                           MOVE ATT-PNNY  TO  M0002-SELA(IND1)
                       END-IF
                       MOVE ATT-PNNY  TO  M0002-MSGA(IND1)
           END-PERFORM.

260496     PERFORM VARYING IND1 FROM 1 BY 1
"             UNTIL IND1 > WRK-MAX-PFK
"                MOVE ATT-PANY  TO  M0002-PFKA(IND1)
260496     END-PERFORM.
      *-------------------------------------------- COPY ZMYUPCOM
           MOVE CMTER-DATI-ZMP00020 TO CMTER-DATI-TRAN.
           PERFORM TP600-SCRIVI-COMMAREA
              THRU TP600-SCRIVI-COMMAREA-END.
      *---------------------------------------------------------------
      * VALORIZZAZIONE AREA MESSAGGI (RIGA 24)
      *---------------------------------------------------------------
           COPY ZMZERMSG.
           MOVE WCM-MSG-ERR      TO TP-MSG.
      *---------------------------------------------------------------
      * INVIO MAPPA
      *---------------------------------------------------------------
           MOVE 1920             TO WCM-MSG-LENGHT
           MOVE IDECR-M-OUTPUT   TO WCM-MAPPA-1
           MOVE CMTER-WULTMAP    TO WCM-MAPPA-2
      *    MOVE CONFG-WZPFHLP    TO TP-HELP
           EXEC SQL INCLUDE ZMYINVIO  END-EXEC.
       TP950-END.
           EXEC SQL INCLUDE ZMYCLEAR  END-EXEC.
       M999-GOBACK.
           GOBACK.
      *---------------------------------------------------------------
      *---------------------------------------------------------------
       SVILUPPO-ROUTINE SECTION.
      *---------------------------------------------------------------
      *---------------------------------------------------------------
      *----  LEGGE LA TABELLA DEGLI ISTITUTI
      *---------------------------------------------------------------
       TP030-READ-IST.
           MOVE CMTER-TISTI    TO DCLTBTISTI.
      *------ PRELEVA LA DESCRIZIONE DELLA TRANSAZIONE CHIAMANTE ----*

           MOVE CMTER-00020-CPCS TO PRPCS-CPCS

           PERFORM LEGGI-TBWPRPCS
              THRU LEGGI-TBWPRPCS-END.

           MOVE PRPCS-WFDESC    TO TP-DIST.

      *------ PRELEVA LA DESCRIZIONE DELLA FUNZIONE CHIAMATA  ----*

           MOVE CMTER-CPCS   TO PRPCS-CPCS.

           PERFORM LEGGI-TBWPRPCS
              THRU LEGGI-TBWPRPCS-END.

           MOVE PRPCS-WFDESC           TO TP-DFUN.
           MOVE TP-DFUN                TO WRK-DESCR01
           MOVE 30                     TO WRK-IND-DESCR1
           MOVE 15                     TO WRK-CENTRO

           PERFORM TP415-FORM-DESCR
              THRU TP415-FORM-DESCR-END.

           MOVE WRK-DESCR02            TO TP-DFUN.

           MOVE CMTER-TOPEIS   TO DCLTBTOPEIS.
           MOVE OPEIS-DOGG                 TO WCM-DATA-SIS.
           MOVE CORRESPONDING WCM-SIS-DATA TO WCM-DATA-CORRENTE.

       TP030-READ-IST-END.
              EXIT.

       TP050-CICLO-PGM.

           IF CMTER-WFASE = '0'
              PERFORM TP110-CICLO-UNO
                 THRU TP110-CICLO-UNO-END
              MOVE 'S'   TO WCM-INVIO-MAPPA.

           IF CMTER-WFASE = 'M'
              PERFORM TP060-START-MENU
                 THRU TP060-START-MENU-END
              PERFORM TP700-START-PGM
                 THRU TP700-START-PGM-END.

       TP050-CICLO-PGM-END.
           EXIT.
      *---------------------------------------------------------------*
       TP060-START-MENU.

           MOVE SPACES       TO IDECR-CAMPI-INPUT.
           MOVE '1'          TO IDECR-TIPRICE.
           MOVE WCM-CIST     TO IDECR-CIST
           MOVE CMTER-CPCS   TO IDECR-VALORE.
      *---------------------------------------------- COPY ZMYIDECR
           PERFORM TP020-DECOD-ID
              THRU TP020-DECOD-ID-END.

           MOVE '0'              TO CMTER-WFASE.
           MOVE SPACES           TO CMTER-WHELP.
           MOVE 'N'              TO CMTER-WSTAMPA.
           MOVE SPACES           TO CMTER-WFUNZ.
           MOVE IDECR-PGM        TO CMTER-WPRG.
           MOVE SPACES           TO CMTER-WCMDATI-TEXT.

       TP060-START-MENU-END.
           EXIT.

       LEGGI-TBWPRPCS.
           MOVE ZEROES              TO W-SQLCODE.

           EXEC SQL INCLUDE ZMS31501 END-EXEC.

           IF NOT W-SQL-OK
              MOVE 'LEGGI TABELLA PROCESSI'    TO TPRIF
              MOVE 'ZMP00020'                  TO TPPRG
              MOVE 'INCLUDE ZMS31501'          TO TPSTM
              MOVE W-SQLCODE                   TO TPRETC
              MOVE 'ZM.TBWPRPCS'               TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.

       LEGGI-TBWPRPCS-END.
           EXIT.
       TP700-START-PGM.
      *-------------------------------------------- COPY ZMYUPCOM
300996     MOVE IDECR-PGM TO PRPCS-WMPPRG
           PERFORM TP600-SCRIVI-COMMAREA
              THRU TP600-SCRIVI-COMMAREA-END.
           COPY ZMZSTART.
       TP700-START-PGM-END.
           EXIT.
       TP410-CANCELLA-COMMAREA.
           MOVE ZEROES TO W-SQLCODE.
           MOVE WCM-TERMIN      TO CMTER-CTER.
           EXEC SQL   INCLUDE   ZMU31101  END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'UPDATE COMMAREA (DELETE)'      TO TPRIF
              MOVE 'ZMP00020'                      TO TPPRG
              MOVE 'ZMU31101'                      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'COMMAREA'                      TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP410-CANCELLA-COMMAREA-END.
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
       TP220-CANCELLA-BROWSE.
           .
       TP220-CANCELLA-BROWSE-END.
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
      *-----------------------------------------------------------*
      *   INSERIMENTO O AGGIORNAMENTO COMMAREA                    *
      *   ROUTINE : TP600-SCRIVI-COMMAREA                         *
      *-----------------------------------------------------------*
           EXEC SQL INCLUDE ZMYUPCOM END-EXEC.
      *-------------------------------------------------------------*
      *   LETTURA TABELLA ZM.TBWHLINP                               *
      *   (SALVATAGGIO FORMATO DI INPUT PER HELP)                   *
      *-------------------------------------------------------------*
       TP215-LEGGI-TBWHLINP.
           MOVE ZEROES TO W-SQLCODE.
           EXEC SQL   INCLUDE   ZMS31301  END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA TBWHLINP'       TO TPRIF
              MOVE 'ZMP00020'                      TO TPPRG
              MOVE 'ZMS31301'                      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'ZM.TBWHLINP'                   TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP215-LEGGI-TBWHLINP-END.
           EXIT.
      *-------------------------------------------------------------*
       TP217-LEGGI-TBWHLOUT.
           MOVE ZEROES TO W-SQLCODE.
           EXEC SQL   INCLUDE   ZMS31401  END-EXEC.
           IF NOT W-SQL-OK
              MOVE 'ERRORE LETTURA TBWHLOUT'       TO TPRIF
              MOVE 'ZMP00020'                      TO TPPRG
              MOVE 'ZMS31301'                      TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'ZM.TBWHLOUT'                   TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
       TP217-LEGGI-TBWHLOUT-END.
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
      *
       TP311-INCLUDEU.
           EXEC SQL INCLUDE ZMU31102 END-EXEC
           .
       TP311-INCLUDEU-END.
           EXIT.

      *---------------------------------------------------------------*
      *    GESTIONE TASTO DI USCITA                                   *
      *---------------------------------------------------------------*
       GESTIONE-FUNZIONE-R.
           MOVE 'R'              TO CMTER-WFASE.
           MOVE 'R'              TO CMTER-WHELP.
           MOVE SPACES           TO IDECR-CAMPI-INPUT.
           MOVE '1'              TO IDECR-TIPRICE.
           MOVE WCM-CIST         TO IDECR-CIST.

           MOVE CMTER-WCPCSIN TO IDECR-VALORE
                                  CMTER-CPCS

           MOVE CMTER-CPCS-PREC(1) TO CMTER-WCPCSIN
           MOVE CMTER-AREA-RIT (1) TO CMTER-DATI-TRAN
           PERFORM TP200-TABELLA-CMTER-I
              THRU TP200-TABELLA-CMTER-I-END.
      *---------------------------------------------- COPY ZMYIDECR
           PERFORM TP020-DECOD-ID
              THRU TP020-DECOD-ID-END.

           MOVE CMTER-00020-WULTMAP  TO CMTER-WULTMAP.

           PERFORM TP700-START-PGM
              THRU TP700-START-PGM-END.

       GESTIONE-FUNZIONE-R-END.
           EXIT.

       INIZIALIZZA-MAPPA.
           MOVE LOW-VALUE TO AREA-BODY.
      *    MOVE ATT-CURS  TO M0002-CDPZL.
       INIZIALIZZA-MAPPA-END.
           EXIT.
      *--------------------------------------------------------------*
      *  PREDISPONE LA MAPPA IN BASE AL PGM CHIAMANTE                *
      *--------------------------------------------------------------*

       LEGGI-TBWPRMEN.
           MOVE ZEROES              TO W-SQLCODE.
           EXEC SQL INCLUDE ZMS31602 END-EXEC.

           IF NOT W-SQL-OK
              MOVE 'LEGGI TABELLA PRMEN'       TO TPRIF
              MOVE 'ZMP00020'                  TO TPPRG
              MOVE 'INCLUDE ZMS31602'          TO TPSTM
              MOVE W-SQLCODE                   TO TPRETC
              MOVE 'ZM.TBWPRMEN'               TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.

       LEGGI-TBWPRMEN-END.
           EXIT.

      *-------------------------------------------------------------*
       TP110-CICLO-UNO.
      *-------------------------- CONTROLLA I CAMPI CHIAVE DIGITATI-*

           MOVE CMTER-00020-CPCS    TO  WRK-CPCS

           PERFORM TP111-TASTI-PROCESSO
              THRU TP111-TASTI-PROCESSO-END.

           PERFORM TP112-ERRORI-PROCESSO
              THRU TP112-ERRORI-PROCESSO-END.

           PERFORM TP113-DESCRIZIONE-PROCESSO
              THRU TP113-DESCRIZIONE-PROCESSO-END.

           MOVE SPACES  TO  WRK-USCITA.

           PERFORM TP117-RIEMPI-MAPPA
              THRU TP117-RIEMPI-MAPPA-END.

           ADD 1 TO IND1.

           PERFORM
           VARYING IND1 FROM IND1 BY 1
             UNTIL IND1 > WRK-MAX-RIGHE
                     MOVE ATT-PNNY   TO   M0002-SELA(IND1)
                     MOVE SPACES     TO   M0002-SEL(IND1)
                     MOVE ATT-PNNY   TO   M0002-MSGA(IND1)
                     MOVE SPACES     TO   M0002-MSG(IND1)
           END-PERFORM.

           MOVE  '1'               TO  CMTER-WFASE.
           MOVE  IDECR-FIR-MAP     TO  CMTER-WULTMAP.

       TP110-CICLO-UNO-END.
           EXIT.

       TP111-TASTI-PROCESSO.

           MOVE WRK-CPCS     TO     PRPCS-CPCS

           PERFORM LEGGI-TBWPRPCS
              THRU LEGGI-TBWPRPCS-END.

           MOVE PRPCS-WMPPFK   TO   WRK-TAB-PFK-PRPCS.
           MOVE CONFG-WMPPFK   TO   WRK-TAB-PFK-CONFG.

           PERFORM
           VARYING IND1 FROM 1 BY 1
              UNTIL IND1 > WRK-MAX-TASTI
              IF WRK-PFK-PRPCS(IND1) > SPACES
                 MOVE SPACES  TO  WRK-FUNZIONE
                 MOVE SPACES  TO  WRK-TROVATO-TASTO
                 PERFORM
                 VARYING IND2 FROM 1 BY 1 UNTIL IND2 > WRK-MAX-TAB
                      OR WRK-LETTERA-TASTI(IND2) = SPACES
                      OR WRK-TROVATO-TASTO = 'SI'
                         IF WRK-LETTERA-TASTI(IND2) =
                                                 WRK-ELE-PFK-PRPCS(IND1)
                            MOVE 'SI'   TO  WRK-TROVATO-TASTO
000397                      MOVE IND1              TO WRK-TASTO
                            MOVE WRK-FUNZIONE-TASTI(IND2)
                                                      TO WRK-FUNZIONE
                         END-IF
                 END-PERFORM
                 IF WRK-TROVATO-TASTO = 'SI'
                    ADD   1   TO     IND3
                    MOVE WRK-CAMPO-FUNZIONE   TO  M0002-PFK(IND3)
                 END-IF
              ELSE
                 IF WRK-PFK-CONFG(IND1) > SPACES
                    MOVE SPACES  TO  WRK-FUNZIONE
                    MOVE SPACES  TO  WRK-TROVATO-TASTO
                    PERFORM
                    VARYING IND2 FROM 1 BY 1 UNTIL IND2 > WRK-MAX-TAB
                         OR WRK-LETTERA-TASTI(IND2) = SPACES
                         OR WRK-TROVATO-TASTO = 'SI'
                            IF WRK-LETTERA-TASTI(IND2) =
                                                 WRK-ELE-PFK-CONFG(IND1)
                               MOVE 'SI'   TO  WRK-TROVATO-TASTO
                               MOVE IND1              TO WRK-TASTO
                               MOVE WRK-FUNZIONE-TASTI(IND2)
                                                      TO WRK-FUNZIONE
                            END-IF
                    END-PERFORM
                    IF WRK-TROVATO-TASTO = 'SI'
                       ADD   1   TO     IND3
                       MOVE WRK-CAMPO-FUNZIONE   TO  M0002-PFK(IND3)
                    END-IF
                 END-IF
              END-IF
           END-PERFORM.

       TP111-TASTI-PROCESSO-END.
           EXIT.

       TP112-ERRORI-PROCESSO.

      *- ELABORA GLI ERRORI RELATIVI AL PROCESSO CHIAMANTE

           INITIALIZE   WRK-TABELLA-ERRORE.

           MOVE ZEROES           TO   IND2.

           MOVE CMTER-TAB-COD-ERR   TO   WRK-TAB-ERRORE.
           MOVE CMTER-TAB-COD-ERR-1 TO   WRK-TAB-ERRORE-1.

           MOVE ALL ' '          TO   WRK-TAB-CODERR1.
           MOVE ALL ' '          TO   WRK-TAB-CODERR2.

           MOVE WRK-TAB-ERRORE   TO   WRK-TAB-CODERR1.

      *--- TOGLIE DALLA TABELLA ERRORE I CODICI ERRORI UGUALI

           PERFORM
           VARYING IND1 FROM 1 BY 1
             UNTIL IND1 > WRK-MAX-ERRORE
                OR WRK-ELE-CODERR1(IND1) = SPACES
                   MOVE SPACES   TO  WRK-USCITA
                   PERFORM
                   VARYING IND3 FROM 1 BY 1
                     UNTIL IND3 > WRK-MAX-ERRORE
                        OR WRK-USCITA  = 'SI'
                        IF WRK-ELE-CODERR1(IND1) = WRK-ELE-CODERR2(IND3)
                           MOVE 'SI' TO WRK-USCITA
                        END-IF
                        IF WRK-ELE-CODERR2(IND3) = SPACES
                           MOVE WRK-ELE-CODERR1(IND1)
                                              TO WRK-ELE-CODERR2(IND3)
                           MOVE 'SI'          TO WRK-USCITA
                        END-IF
                   END-PERFORM
           END-PERFORM.

           MOVE WRK-TAB-CODERR2  TO   WRK-TAB-ERRORE.

           MOVE ALL ' '          TO   WRK-TAB-CODERR1.
           MOVE ALL ' '          TO   WRK-TAB-CODERR2.

           MOVE WRK-TAB-ERRORE-1 TO   WRK-TAB-CODERR1.

           PERFORM
           VARYING IND1 FROM 1 BY 1
             UNTIL IND1 > WRK-MAX-ERRORE
                OR WRK-ELE-CODERR1(IND1) = SPACES
                   MOVE SPACES   TO  WRK-USCITA
                   PERFORM
                   VARYING IND3 FROM 1 BY 1
                     UNTIL IND3 > WRK-MAX-ERRORE
                        OR WRK-USCITA  = 'SI'
                        IF WRK-ELE-CODERR1(IND1) = WRK-ELE-CODERR2(IND3)
                           MOVE 'SI' TO WRK-USCITA
                        END-IF
                        IF WRK-ELE-CODERR2(IND3) = SPACES
                           MOVE WRK-ELE-CODERR1(IND1)
                                              TO WRK-ELE-CODERR2(IND3)
                           MOVE 'SI'          TO WRK-USCITA
                        END-IF
                   END-PERFORM
           END-PERFORM.

           MOVE WRK-TAB-CODERR2  TO   WRK-TAB-ERRORE-1.

           PERFORM
           VARYING IND1 FROM 1 BY 1
             UNTIL IND1 > WRK-MAX-ERRORE
                   IF WRK-COD-ERRORE(IND1) > SPACES
                      MOVE WCM-CIST          TO TRERR-CIST
                      MOVE WRK-COD-ERRORE(IND1) TO TRERR-CODERRTCN
                      PERFORM TP115-LEGGI-TBTTRERR
                         THRU TP115-LEGGI-TBTTRERR-END
                      IF W-SQL-OK
                         ADD  1              TO IND2
                         MOVE WRK-COD-ERRORE(IND1)
                                             TO WRK-CODICE-ERRORE(IND2)
                         MOVE TRERR-CODERR   TO ABERR-CODERR
                         MOVE WCM-CIST       TO ABERR-CIST
                         PERFORM TP116-LEGGI-TBTABERR
                            THRU TP116-LEGGI-TBTABERR-END
                         IF W-SQL-OK
                            MOVE ABERR-ZERREST TO
                                           WRK-DESCRIZIONE-ERRORE(IND2)
                         ELSE
                            MOVE ALL '*'       TO
                                           WRK-DESCRIZIONE-ERRORE(IND2)
                         END-IF
                      END-IF
                   ELSE
                      IF WRK-COD-ERRORE-1(IND1) > SPACES
                         ADD 1 TO IND2
                         MOVE WRK-COD-ERRORE-1(IND1) TO
                                                WRK-CODICE-ERRORE(IND2)
                         MOVE WCM-CIST            TO ABERR-CIST
                         MOVE WRK-COD-ERRORE-1(IND1) TO ABERR-CODERR
                         PERFORM TP116-LEGGI-TBTABERR
                            THRU TP116-LEGGI-TBTABERR-END
                         IF W-SQL-OK
                            MOVE ABERR-ZERREST
                                         TO WRK-DESCRIZIONE-ERRORE(IND2)
                          ELSE
                            MOVE ALL '*' TO WRK-DESCRIZIONE-ERRORE(IND2)
                          END-IF
                       END-IF
                    END-IF
           END-PERFORM.

           MOVE IND2    TO   WRK-INDICE-ERRORE.

       TP112-ERRORI-PROCESSO-END.
           EXIT.

       TP113-DESCRIZIONE-PROCESSO.

      *- ELABORA LA DESCRIZIONE RELATIVA AL PROCESSO CHIAMANTE

           INITIALIZE   WRK-TABELLA-DESCRIZIONE.

           MOVE WRK-CPCS      TO     APROC-CPCS.

           PERFORM TP115-LEGGI-TBTAPROC
              THRU TP115-LEGGI-TBTAPROC-END.

           IF W-SQL-NON-TROVATO
              GO TO TP113-DESCRIZIONE-PROCESSO-END
           END-IF.

           MOVE ZEROES  TO  IND2.

           ADD 1 TO IND2.
           MOVE APROC-ZDCFPCS   TO   WRK-DESCRIZIONE(IND2).

           MOVE IND2    TO   WRK-INDICE-DESCRIZIONE.

       TP113-DESCRIZIONE-PROCESSO-END.
           EXIT.

       TP115-LEGGI-TBTTRERR.

      *- LEGGE LA TABELLA TBTTRERR

           EXEC SQL INCLUDE ZMS22201  END-EXEC.

           IF  NOT W-SQL-OK
           AND NOT W-SQL-NON-TROVATO
              MOVE 'LEGGI TABELLA TBTTRERR'    TO TPRIF
              MOVE 'ZMP00020'                  TO TPPRG
              MOVE 'INCLUDE ZMS22201'          TO TPSTM
              MOVE W-SQLCODE                   TO TPRETC
              MOVE 'ZM.TBTTRERR'               TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
           END-IF.

       TP115-LEGGI-TBTTRERR-END.
           EXIT.

       TP116-LEGGI-TBTABERR.

      *- LEGGE LA TABELLA TBTABERR

           EXEC SQL INCLUDE ZMS22401  END-EXEC.

           IF  NOT W-SQL-OK
           AND NOT W-SQL-NON-TROVATO
              MOVE 'LEGGI TABELLA TBTABERR'    TO TPRIF
              MOVE 'ZMP00020'                  TO TPPRG
              MOVE 'INCLUDE ZMS22401'          TO TPSTM
              MOVE W-SQLCODE                   TO TPRETC
              MOVE 'ZM.TBTABERR'               TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
           END-IF.

       TP116-LEGGI-TBTABERR-END.
           EXIT.

       TP115-LEGGI-TBTAPROC.

      *- LEGGE LA TABELLA TBTAPROC

           EXEC SQL INCLUDE ZMS20301  END-EXEC.

           IF  NOT W-SQL-OK
           AND NOT W-SQL-NON-TROVATO
              MOVE 'LEGGI TABELLA TBTAPROC'    TO TPRIF
              MOVE 'ZMP00020'                  TO TPPRG
              MOVE 'INCLUDE ZMS20301'          TO TPSTM
              MOVE W-SQLCODE                   TO TPRETC
              MOVE 'ZM.TBTAPROC'               TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END
           END-IF.

       TP115-LEGGI-TBTAPROC-END.
           EXIT.


       TP117-RIEMPI-MAPPA.
      ***---- RIEMPI GLI ELEMENTI TABELLARI DELLA MAPPA

           MOVE ZEROES  TO IND1.
           COMPUTE IND3 = WRK-MAX-RIGHE - (WRK-INDICE-ERRORE + 1).

           PERFORM
           VARYING IND2 FROM 1 BY 1
             UNTIL IND2 > IND3
                OR WRK-USCITA = 'SI'
                   IF WRK-DESCRIZIONE(IND2) = SPACES
                      MOVE 'SI'   TO   WRK-USCITA
                   ELSE
                      ADD 1  TO  IND1
                      MOVE WRK-DESCRIZIONE(IND2)  TO  M0002-MSG(IND1)
                      MOVE ATT-PNNY               TO  M0002-MSGA(IND1)
                      MOVE ' '                    TO  M0002-SEL(IND1)
                   END-IF
           END-PERFORM.

           IF WRK-INDICE-ERRORE NOT = ZEROES
              ADD 1 TO IND1
              MOVE WRK-RIGA-ERRORI  TO   M0002-MSG(IND1)
              MOVE ATT-PNNY         TO   M0002-MSGA(IND1)
              MOVE ' '              TO   M0002-SEL(IND1)
           ELSE
              MOVE ATT-CURS    TO  M0002-FUNZIONEL
           END-IF.

      *--- SCRIVE GLI ERRORI NELLA MAPPA

           PERFORM
           VARYING IND2 FROM 1 BY 1
             UNTIL IND2 > WRK-INDICE-ERRORE
                OR IND1 > WRK-MAX-RIGHE
                   ADD 1 TO IND1
                   MOVE WRK-ELE-ERRORE(IND2)  TO  M0002-MSG(IND1)
                   MOVE ATT-PNNY              TO  M0002-MSGA(IND1)
                   IF IND2 = 1
                      MOVE ATT-CURS         TO  M0002-SELL(IND1)
                   END-IF
                   IF M0002-SEL(IND1) NOT > SPACES
                      MOVE '_'              TO  M0002-SEL(IND1)
                   END-IF
           END-PERFORM.

       TP117-RIEMPI-MAPPA-END.
           EXIT.


       TP130-CONTROLLA-SCELTA.

           IF M0002-SEL(IND2) = 'S'
              IF WRK-TROVATO = 'SI'
                 MOVE 'WA24'    TO WCM-COD-ERR(1)
                 MOVE ATT-CURS  TO M0002-SELL(IND2)
                 PERFORM TP998-ERRORE
                    THRU TP998-ERRORE-END
                 GO TO TP900-INVIO-MAPPA
              END-IF
              MOVE M0002-MSG(IND2)(1:4)         TO WRK-COD-ERR
              MOVE M0002-SEL(IND2)              TO WRK-SCELTA
              MOVE 'SI'                         TO WRK-TROVATO
           ELSE
              IF M0002-SEL(IND2) NOT = SPACES AND LOW-VALUE AND '_'
                 MOVE 'WA23'    TO WCM-COD-ERR(1)
                 MOVE ATT-UAHY  TO M0002-SELA(IND2)
                 MOVE ATT-CURS  TO M0002-SELL(IND2)
                 PERFORM TP998-ERRORE
                    THRU TP998-ERRORE-END
                 GO TO TP900-INVIO-MAPPA
              END-IF
           END-IF.

       TP130-CONTROLLA-SCELTA-END.
              EXIT.
      *--------------------------------------------------------------*
      *  GESTIONE FUNZIONE                                           *
      *--------------------------------------------------------------*
       TP195-GESFUN.
           PERFORM TP310-VERIFICA-SE-FUNZ
              THRU TP310-VERIFICA-SE-FUNZ-END.
           MOVE IDECR-M-OUTPUT   TO COMODO-IDECR-OUT.
           MOVE IDECR-CTRAN      TO COMODO-IDECR-CTRAN.
           IF WCM-FLAG-FUNZ-OK = 'S'
MIMNEW        MOVE SPACES         TO IDECR-CAMPI-INPUT
              MOVE WCM-FUNZ       TO IDECR-VALORE
              MOVE '2'            TO IDECR-TIPRICE
              MOVE WCM-CIST       TO IDECR-CIST
              PERFORM TP020-DECOD-ID
                 THRU TP020-DECOD-ID-END
              IF IDECR-RETC GREATER SPACES
                 MOVE COMODO-IDECR-OUT   TO IDECR-M-OUTPUT
                 MOVE COMODO-IDECR-CTRAN TO IDECR-CTRAN
      * -----------> WA13 FUNZIONE INESISTENTE
                 MOVE 'WA13'    TO WCM-COD-ERR(1)
                 MOVE ATT-CURS  TO M0002-FUNZIONEL
                 MOVE SPACES    TO M0002-FUNZIONE
                 PERFORM TP998-ERRORE
                    THRU TP998-ERRORE-END
                 GO TO TP900-INVIO-MAPPA
MIMNEW        END-IF
              MOVE WCM-FUNZ       TO WCM-WFUNZ
           ELSE
              MOVE SPACES            TO IDECR-CAMPI-INPUT
              MOVE '3'               TO IDECR-TIPRICE
              MOVE WCM-CIST          TO IDECR-CIST
              MOVE WCM-TABELLA-INPUT TO IDECR-VALORE
              PERFORM TP020-DECOD-ID
                 THRU TP020-DECOD-ID-END
              IF IDECR-RETC = '1'
                 MOVE COMODO-IDECR-OUT   TO IDECR-M-OUTPUT
                 MOVE COMODO-IDECR-CTRAN TO IDECR-CTRAN
      * -----------> WA13 FUNZIONE INESISTENTE
                 MOVE 'WA13'    TO WCM-COD-ERR(1)
                 MOVE ATT-CURS  TO M0002-FUNZIONEL
                 MOVE SPACES    TO M0002-FUNZIONE
                 PERFORM TP998-ERRORE
                    THRU TP998-ERRORE-END
                 GO TO TP900-INVIO-MAPPA
              END-IF
              MOVE IDECR-NAVIG TO WCM-WFUNZ
           END-IF.
           MOVE SPACES         TO IDECR-CAMPI-INPUT.
           MOVE '2'            TO IDECR-TIPRICE.
           MOVE WCM-WFUNZ      TO IDECR-VALORE.
           MOVE WCM-CIST       TO IDECR-CIST.
           PERFORM TP020-DECOD-ID
              THRU TP020-DECOD-ID-END
           IF IDECR-RETC GREATER SPACES
              MOVE COMODO-IDECR-OUT   TO IDECR-M-OUTPUT
              MOVE COMODO-IDECR-CTRAN TO IDECR-CTRAN
      * -----------> WA13 FUNZIONE INESISTENTE
              MOVE 'WA13'    TO WCM-COD-ERR(1)
              MOVE ATT-CURS  TO M0002-FUNZIONEL
              MOVE SPACES    TO M0002-FUNZIONE
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA
           END-IF.

           PERFORM TP197-LEGGI-TBTPROFI
              THRU TP197-LEGGI-TBTPROFI-END

           IF PROFI-AUTORIZ = 'N'
              MOVE COMODO-IDECR-OUT   TO IDECR-M-OUTPUT
              MOVE COMODO-IDECR-CTRAN TO IDECR-CTRAN
      * -----------> WA13 FUNZIONE INESISTENTE
              MOVE 'WA13'    TO WCM-COD-ERR(1)
              MOVE ATT-CURS  TO M0002-FUNZIONEL
              MOVE SPACES    TO M0002-FUNZIONE
              PERFORM TP998-ERRORE
                 THRU TP998-ERRORE-END
              GO TO TP900-INVIO-MAPPA
           END-IF.

      *-------------------------------- CONTROLLO DIPENDENZA OPERANTE
GIOVY      PERFORM TP850-CNTL-DIPENDENZA
GIOVY         THRU TP850-CNTL-DIPENDENZA-END.
           MOVE WCM-WFUNZ TO CMTER-WFUNZ.

           INITIALIZE CMTER-DATI.

           MOVE 0001          TO CMTER-CPCS.
           MOVE '0'           TO CMTER-WFASE.
           MOVE SPACES        TO CMTER-WCMDATI-TEXT.
           MOVE SPACES         TO IDECR-CAMPI-INPUT
           MOVE '1'            TO IDECR-TIPRICE
           MOVE 0001           TO IDECR-VALORE
           MOVE WCM-CIST       TO IDECR-CIST

           PERFORM TP020-DECOD-ID
              THRU TP020-DECOD-ID-END

300996     MOVE IDECR-PGM TO PRPCS-WMPPRG

           PERFORM TP700-START-PGM
              THRU TP700-START-PGM-END.

       TP195-GESFUN-END.
           EXIT.

       TP197-LEGGI-TBTPROFI.
           MOVE  WCM-CIST        TO  PROFI-CIST.
           MOVE  AUTOR-CPROFILO  TO  WCM-CPROFILO1.
           MOVE  AUTOR-CPROFOP   TO  WCM-CPROFILO2.
           MOVE  'N'             TO  PROFI-AUTORIZ.
           MOVE  IDECR-WCPCS     TO  PROFI-WCPCS.
           EXEC SQL INCLUDE ZMS22302 END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'ERRORE LETTURA PROFILO'        TO TPRIF
              MOVE 'ZMP00020'                      TO TPPRG
              MOVE 'INCLUDE ZMS22302'              TO TPSTM
              MOVE W-SQLCODE                       TO TPRETC
              MOVE 'PROFILO'                       TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
           IF W-SQL-NON-TROVATO OR
              PROFI-AUTORIZ = 'N'
              MOVE 'N'         TO PROFI-AUTORIZ.
       TP197-LEGGI-TBTPROFI-END.
           EXIT.
GIOVY *--------------------------------------------------------------*
      * CONTROLLA TIPOLOGIA PROCESSO CHIAMATO, SE CONTABILE CONTROLLA*
      * LA DIPENDENZA SE OPERANTE                                    *
      *--------------------------------------------------------------*
       TP850-CNTL-DIPENDENZA.
           MOVE IDECR-CPCS TO APROC-CPCS.
           PERFORM 0310-LEGGI-TBTAPROC
              THRU 0310-LEGGI-TBTAPROC-END.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'ERRORE LETTURA PROCESSI ' TO TPRIF
              MOVE 'ZMP00020'                 TO TPPRG
              MOVE 'INCLUDE ZMS20301'         TO TPSTM
              MOVE W-SQLCODE                  TO TPRETC
              MOVE 'ZM.TBTAPROC'              TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
           IF W-SQL-NON-TROVATO
              GO TO TP850-CNTL-DIPENDENZA-END
           ELSE
              IF W-SQL-OK
                 IF APROC-FTIPOPE = 1 OR 2 OR 3
                    MOVE WCM-CIST  TO OPEFL-CIST
                    MOVE WCM-CDPZ  TO OPEFL-CUTE
                    PERFORM TP870-LEGGI-TBTOPEFL
                       THRU TP870-LEGGI-TBTOPEFL-END
                    IF W-SQL-OK
                       IF OPEFL-FFOPE = ZEROES OR 2
                          MOVE COMODO-IDECR-OUT   TO IDECR-M-OUTPUT
                          MOVE COMODO-IDECR-CTRAN TO IDECR-CTRAN
      * -----------> WA45 DIPENDENZA NON OPERANTE
                          MOVE 'WA45'    TO WCM-COD-ERR(1)
                          MOVE ATT-CURS  TO M0002-FUNZIONEL
                          PERFORM TP998-ERRORE
                             THRU TP998-ERRORE-END
                          GO TO TP900-INVIO-MAPPA.
GIOVY  TP850-CNTL-DIPENDENZA-END.
           EXIT.
      *--------------------------------------------------------------*
GIOVY  TP870-LEGGI-TBTOPEFL.
           EXEC SQL INCLUDE ZMS25801 END-EXEC.
           IF NOT W-SQL-OK AND
              NOT W-SQL-NON-TROVATO
              MOVE 'ERRORE LETTURA TOPEFL   ' TO TPRIF
              MOVE 'ZMP00020'                 TO TPPRG
              MOVE 'INCLUDE ZMS25801'         TO TPSTM
              MOVE W-SQLCODE                  TO TPRETC
              MOVE 'ZM.TBTOPEFL'              TO TPARCH
              PERFORM TP999-ABEND
                 THRU TP999-ABEND-END.
GIOVY  TP870-LEGGI-TBTOPEFL-END.
           EXIT.
      *--------------------------------------------------------------*
       0310-LEGGI-TBTAPROC.
           EXEC SQL INCLUDE ZMS20301 END-EXEC.
           .
       0310-LEGGI-TBTAPROC-END.
           EXIT.

      *---------------------------ROUTINE TP310-VERIFICA-SE-FUNZ
           COPY ZMZCTRFU.
      *-----------------------------------------------------------*
      *     FORMATTA DESCRIZIONE : ROUTINE TP415-FORM-DESCR       *
      *-----------------------------------------------------------*
            COPY ZMZDESCR.
      *-----------------------------------------------------------*
      *   INCLUDE DELLE ROUTINE DI LETTURA MESSAGGIO DI INPUT     *
      *-----------------------------------------------------------*
           EXEC SQL   INCLUDE   ZMYINOU2  END-EXEC.
      *-----------------------------------------------------------*
      *                    SCRITTURA MESSAGGIO DI OUTPUT          *
      *-----------------------------------------------------------*
           EXEC SQL   INCLUDE   ZMYMSOU1  END-EXEC.
      *-----------------------------------------------------------*
      *                        ATTIVAZIONE DI PROGRAMMI           *
      *-----------------------------------------------------------*
           EXEC SQL   INCLUDE   ZMYATTIV  END-EXEC.
      *-----------------------------------------------------------*
      *   ATTIVAZIONE DI PROGRAMMI CON TERMID                     *
      *-----------------------------------------------------------*
????  *    EXEC SQL   INCLUDE   ZMYATTI1  END-EXEC.
      *-----------------------------------------------------------*
      *   ROUTINE STANDARD PER GESTIONE ERRORE                    *
      *-----------------------------------------------------------*
           EXEC SQL   INCLUDE   ZMIERROR  END-EXEC.
      *------------------------------------------------------------*
      *   LETTURA COMMAREA                                         *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYRDCOM END-EXEC.
      *------------------------------------------------------------*
      *   ROUTINE STANDARD PER GESTIONE ABEND                      *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYABEND  END-EXEC.
      *------------------------------------------------------------*
      * ROUTINE PER EFFETTUARE LA TRASFORMAZIONE DEI CARATTERI     *
      *------------------------------------------------------------*
           COPY  ZMZTRASF.
      *------------------------------------------------------------*
      * CONTROLLO DATA : ROUTINE 9010-CTR-DAT
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYCTRDT END-EXEC.
      *------------------------------------------------------------*
      * PREPARA MAPPA PER RITORNO DA HELP : TP210-FORMATTA-MAPPA   *
      *------------------------------------------------------------*
           COPY ZMZRHELP.
      *--RICERCA MAPPA : ROUTINE TP020-DECOD-ID                    *
           EXEC SQL INCLUDE ZMYIDECR END-EXEC.
      *------------------------------------------------------------*
      *   ROUTINE STANDARD PER GESTIONE ABEND CICS                 *
      *------------------------------------------------------------*
           EXEC SQL INCLUDE ZMYABECX  END-EXEC.
      *------------------------------------------------------------*
      *   ROUTINE STANDARD PER CONTROLLO CAMPI NUMERICI            *
      *------------------------------------------------------------*
           COPY ZMZCTRNM.
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
