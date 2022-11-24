      ******************************************************************
      *
      *           RECUPERO VARIAZIONI ANAGRAFICHE
      *
      ******************************************************************
      * 251000 ===> AGGIUNTA VALORIZZAZIONE DEL CAMPO TTAF-DT-VAL-A    *
      *             PER SELECT SU TABELLA DEGLI AFFIDATI               *
      * 150101 ===> AGGIUNTA ROTUINE DI CALCOLO DELLA DATA.A PARTIRE   *
      *             DALLA DATA BATCH VIENE CALCOLATA UNA DATA CON GIOR-*
      *             NO = GIORNO DELLA DATA BATCH - 1.                  *
      *             AGGIUNTA VALORIZZAZIONE A SPACE DEL CAMPO TRIC-ESITO
      *             PER AGGIORNAMENTO SU TABELLA SCTBTRIC.
      * 280602 ===> AGGIUNTO IL CONTROLLO CHE ESCLUDE DALL'ELABORAZIONE*
      *             I RECORD CON IL TIPO ATTIVITA' = "RR", "R3", "E3", *
      *             "70", "80" E "RC"                                  *
      * 010301: AGGIUNTA VALORIZZAZIONE A SPACES ANCHE PER TANG_CAP_RES
      *         E TANG_PROV_RES SU AGGIORNAMENTO SCTBTANG.
      * 300902 ===> MODIFICA TALE DA EVITARE L'INVIO ALL'ENTE DI VARIA-*
      *             ZIONI SU RICHIESTE CON TIPO ATTIVITA' = "D3" E "DF"*
      *             NON ANCORA CONSOLIDATE                             *
      * 171002 ===> MODIFICHE RIGUARDANTI IL CALCOLO DELLA DATA INIZIO *
      *             RANGE PER LA RICERCA DELLA VARIAZIONE ANAGRAFICA   *
      *             E RIGUARDANTI L'AGGIUNTA DI CAMPI ANAGRAFICI DA    *
      *             TESTARE DI INTERESSE PER DEUTSCHE BANK             *
      * 211102 ===> MODIFICHE RIGUARDANTI LA GESTIONE DEI TIPI ATTIVITA*
      *             "DD", "DR" E "DC"                                  *
      * 101203: APPLICATO IL CRITERIO CON CUI IN CASO DI UNA VARIAZIONE
      *         ANAGRAFICA, IL CONTO SIA PRESENTE IN TRIC IN KO OR KR
      *         LA VARIAZIONE NON SARA' PERMESSA
      * 040504: EVITATA LA VARIAZIONE ANAGRAFICA PER 'A3' A STATO-RIC 2
      ******************************************************************
      * 090402: GESTIONE RINUNCIA CLIENTE                              *
      * 181103: EVITATA LA STORICIZZAZIONE E LA VARIAZIONE ANAGRAFICA  *
      *         PER I 'KR'                                             *
      * 301203: ELIMITATI I DISPLAY                                    *
      ******************************************************************
      * AUB018: EVITA DOPPIO INVIO DELLE PRATICHE V2/OK                *
      ******************************************************************
      *
       IDENTIFICATION DIVISION.
      *
       PROGRAM-ID.   ARRAB060
       AUTHOR. BANKSIEL.
      *
       ENVIRONMENT DIVISION.
      *
       CONFIGURATION SECTION.
      *
          SPECIAL-NAMES.
              DECIMAL-POINT IS COMMA.
      *
       INPUT-OUTPUT SECTION.
      *
       FILE-CONTROL.
      *
       DATA DIVISION.
      *
       FILE SECTION.
      *
       WORKING-STORAGE SECTION.
      *****************************************************************
      *    COPY DI WORKING PER LA ROUTINE GENERALIZZATA DI CONTROLLO  *
      *    DATA                                                       *
      *****************************************************************
150101     COPY XSADAT.
      *
       COPY DYNACALL.
      * INTERFACCIA ANAGRAFE
       01 COPY-ANAG.
       COPY AMG108A.
      *
       01  ANAG                    PIC X(7) VALUE 'AMG108B'.
       01  APPO.
           03  APPO-RIC OCCURS 10.
           10 TAPP-NDG-PF          PIC X(12).
           10 TAPP-SERVIZIO        PIC X(3).
           10 TAPP-CATEGORIA       PIC X(4).
           10 TAPP-FILIALE         PIC X(5).
           10 TAPP-NUMERO          PIC S9(12)V USAGE COMP-3.
           10 TAPP-NDG-COI         PIC X(12).
           10 TAPP-TIP-ATTIV       PIC X(2).
           10 TAPP-STATO-RICH      PIC S9(1)V USAGE COMP-3.
           10 TAPP-LIM-FIDO        PIC S9(13)V9(2) USAGE COMP-3.
           10 TAPP-DIV-FIDO        PIC X(3).
           10 TAPP-COD-ANOM        PIC X(30).
           10 TAPP-SETT-PROD       PIC X(2).
           10 TAPP-COD-AFF         PIC X(2).
           10 TAPP-ESITO           PIC X(2).
           10 TAPP-NUM-PROT        PIC X(1).
           10 TAPP-TIPO-PROT       PIC X(1).
           10 TAPP-BAD-CUST        PIC X(1).
           10 TAPP-ACCR-STIP       PIC X(1).
           10 TAPP-IMP-STIP        PIC S9(13)V9(2) USAGE COMP-3.
           10 TAPP-DIV-STIP        PIC X(3).
           10 TAPP-DT-INV-ENT      PIC S9(8)V USAGE COMP-3.
           10 TAPP-DT-RIS-ENT      PIC S9(8)V USAGE COMP-3.
           10 TAPP-DT-RIC-ATT      PIC S9(8)V USAGE COMP-3.
           10 TAPP-DT-ATT-VF       PIC S9(8)V USAGE COMP-3.
           10 TAPP-DT-ATT-ESTINZ   PIC S9(8)V USAGE COMP-3.
           10 TAPP-DT-VAL-A        PIC S9(8)V USAGE COMP-3.
           10 TAPP-DT-STAMPA-AVV   PIC S9(8)V USAGE COMP-3.
           10 TAPP-COD-OPER        PIC X(8).
           10 TAPP-TERM-RICH       PIC X(5).
           10 TAPP-FIL-RICH        PIC X(5).
      *
       01  J                       PIC 9(2).
       01  W-TANA.
           10 TANA-BANCA           PIC X(5).
           10 TANA-NDG             PIC S9(12)V USAGE COMP-3.
           10 TANA-COGNOME         PIC X(30).
           10 TANA-NOME            PIC X(30).
           10 TANA-NOME-ALTER      PIC X(30).
           10 TANA-PATERNITA       PIC X(30).
           10 TANA-COGNOME-ACQUI   PIC X(30).
           10 TANA-SESSO           PIC X(1).
           10 TANA-STATO-CIVILE    PIC X(1).
           10 TANA-TITOLO-ONOR     PIC X(2).
           10 TANA-TITOLO-ACCAD    PIC X(2).
           10 TANA-DATA-NASC-COS   PIC S9(8)V USAGE COMP-3.
           10 TANA-LUOGO-NASCITA   PIC X(30).
           10 TANA-PROV-NASCITA    PIC X(2).
           10 TANA-NAZ-NASCITA     PIC X(4).
           10 TANA-NAT-GIURIDICA   PIC X(3).
           10 TANA-REG-PATR        PIC X(1).
           10 TANA-IND-SEDE-LEG    PIC X(35).
           10 TANA-CAP-SEDE-LEG    PIC X(5).
           10 TANA-LOC-SEDE-LEG    PIC X(30).
           10 TANA-PROV-SEDE-LEG   PIC X(2).
           10 TANA-NAZ-SEDE-LEG    PIC X(4).
           10 TANA-PROV-BANKIT     PIC X(3).
           10 TANA-COM-BKT-CAB     PIC X(5).
           10 TANA-CIN-CAB         PIC X(1).
           10 TANA-TIPO-SPED-SL    PIC X(1).
           10 TANA-TIPO-CLIENTE    PIC X(1).
           10 TANA-FILIALE-PRINC   PIC X(5).
           10 TANA-GUE             PIC S9(4)V USAGE COMP-3.
           10 TANA-RAE             PIC S9(4)V USAGE COMP-3.
           10 TANA-CIAE            PIC S9(4)V USAGE COMP-3.
           10 TANA-NUOVO-GUE       PIC S9(4)V USAGE COMP-3.
           10 TANA-NUOVO-RAE       PIC S9(4)V USAGE COMP-3.
           10 TANA-SETTORE-INT     PIC S9(4)V USAGE COMP-3.
           10 TANA-SOTTOSETT       PIC S9(4)V USAGE COMP-3.
           10 TANA-ATTIV-ECON      PIC X(40).
           10 TANA-COD-FISCALE     PIC X(16).
           10 TANA-PARTITA-IVA     PIC X(11).
           10 TANA-CENTR-RISCHI    PIC X(11).
           10 TANA-DATA-SEGN-CR    PIC S9(8)V USAGE COMP-3.
           10 TANA-TIPO-SEGN-CR    PIC X(1).
           10 TANA-INT-RIDOTTA     PIC X(35).
           10 TANA-INT-POSTALE1    PIC X(35).
           10 TANA-INT-POSTALE2    PIC X(35).
           10 TANA-IND-POSTALE     PIC X(35).
           10 TANA-CAP-POSTALE     PIC X(5).
           10 TANA-LOC-POSTALE     PIC X(30).
           10 TANA-PROV-POSTALE    PIC X(2).
           10 TANA-NAZ-POSTALE     PIC X(4).
           10 TANA-TIPO-SPED-P     PIC X(1).
           10 TANA-DATA-PREACC     PIC S9(8)V USAGE COMP-3.
           10 TANA-DATA-ESTINZ     PIC S9(8)V USAGE COMP-3.
           10 TANA-FLAG-STATO      PIC X(1).
           10 TANA-FLAG-DECESSO    PIC X(1).
           10 TANA-RAGSOC-1        PIC X(40).
           10 TANA-RAGSOC-2        PIC X(40).
           10 TANA-RAGSOC-3        PIC X(40).
           10 TANA-ACRONIMO        PIC X(20).
           10 TANA-DATA-CCIAA      PIC S9(8)V USAGE COMP-3.
           10 TANA-PROV-CCIAA      PIC X(2).
           10 TANA-NUM-CCIAA       PIC S9(10)V USAGE COMP-3.
           10 TANA-DATA-TRIB       PIC S9(8)V USAGE COMP-3.
           10 TANA-PROV-TRIB       PIC X(2).
           10 TANA-NUM-TRIB        PIC S9(10)V USAGE COMP-3.
           10 TANA-DATA-ARTIG      PIC S9(8)V USAGE COMP-3.
           10 TANA-NUM-ARTIG       PIC S9(10)V USAGE COMP-3.
           10 TANA-MECC-ESTERO     PIC X(8).
           10 TANA-UIC             PIC X(9).
           10 TANA-COD-ABI         PIC S9(5)V USAGE COMP-3.
           10 TANA-TIPO-DOC        PIC X(3).
           10 TANA-ENTE-RIL        PIC X(30).
           10 TANA-COD-DOC         PIC X(12).
           10 TANA-DT-RIL-DOC      PIC S9(8)V USAGE COMP-3.
           10 TANA-DT-SCAD-DOC     PIC S9(8)V USAGE COMP-3.
           10 TANA-DATA-VAL-DA     PIC S9(8)V USAGE COMP-3.
           10 TANA-DATA-VAL-A      PIC S9(8)V USAGE COMP-3.
           10 TANA-OPERATORE       PIC X(8).
           10 TANA-TERMINALE       PIC X(4).
           10 TANA-FIL-OPERANTE    PIC X(5).
           10 TANA-FILUFF          PIC X(2).
           10 TANA-DATA-ORA        PIC S9(14)V USAGE COMP-3.
           10 TANA-PROV-BKT-NEW    PIC X(3).
           10 TANA-CR-CIN          PIC X(2).
           10 TANA-RAGSOC-4        PIC X(40).
           10 TANA-SPECGIUR        PIC X(4).
       01  W-TSAN.
           10 TSAN-BANCA           PIC X(5).
           10 TSAN-NDG             PIC S9(12)V USAGE COMP-3.
           10 TSAN-COGNOME         PIC X(30).
           10 TSAN-NOME            PIC X(30).
           10 TSAN-NOME-ALTER      PIC X(30).
           10 TSAN-PATERNITA       PIC X(30).
           10 TSAN-COGNOME-ACQUI   PIC X(30).
           10 TSAN-SESSO           PIC X(1).
           10 TSAN-STATO-CIVILE    PIC X(1).
           10 TSAN-TITOLO-ONOR     PIC X(2).
           10 TSAN-TITOLO-ACCAD    PIC X(2).
           10 TSAN-DATA-NASC-COS   PIC S9(8)V USAGE COMP-3.
           10 TSAN-LUOGO-NASCITA   PIC X(30).
           10 TSAN-PROV-NASCITA    PIC X(2).
           10 TSAN-NAZ-NASCITA     PIC X(4).
           10 TSAN-NAT-GIURIDICA   PIC X(3).
           10 TSAN-REG-PATR        PIC X(1).
           10 TSAN-IND-SEDE-LEG    PIC X(35).
           10 TSAN-CAP-SEDE-LEG    PIC X(5).
           10 TSAN-LOC-SEDE-LEG    PIC X(30).
           10 TSAN-PROV-SEDE-LEG   PIC X(2).
           10 TSAN-NAZ-SEDE-LEG    PIC X(4).
           10 TSAN-PROV-BANKIT     PIC X(3).
           10 TSAN-COM-BKT-CAB     PIC X(5).
           10 TSAN-CIN-CAB         PIC X(1).
           10 TSAN-TIPO-SPED-SL    PIC X(1).
           10 TSAN-TIPO-CLIENTE    PIC X(1).
           10 TSAN-FILIALE-PRINC   PIC X(5).
           10 TSAN-GUE             PIC S9(4)V USAGE COMP-3.
           10 TSAN-RAE             PIC S9(4)V USAGE COMP-3.
           10 TSAN-CIAE            PIC S9(4)V USAGE COMP-3.
           10 TSAN-NUOVO-GUE       PIC S9(4)V USAGE COMP-3.
           10 TSAN-NUOVO-RAE       PIC S9(4)V USAGE COMP-3.
           10 TSAN-SETTORE-INT     PIC S9(4)V USAGE COMP-3.
           10 TSAN-SOTTOSETT       PIC S9(4)V USAGE COMP-3.
           10 TSAN-ATTIV-ECON      PIC X(40).
           10 TSAN-COD-FISCALE     PIC X(16).
           10 TSAN-PARTITA-IVA     PIC X(11).
           10 TSAN-CENTR-RISCHI    PIC X(11).
           10 TSAN-DATA-SEGN-CR    PIC S9(8)V USAGE COMP-3.
           10 TSAN-TIPO-SEGN-CR    PIC X(1).
           10 TSAN-INT-RIDOTTA     PIC X(35).
           10 TSAN-INT-POSTALE1    PIC X(35).
           10 TSAN-INT-POSTALE2    PIC X(35).
           10 TSAN-IND-POSTALE     PIC X(35).
           10 TSAN-CAP-POSTALE     PIC X(5).
           10 TSAN-LOC-POSTALE     PIC X(30).
           10 TSAN-PROV-POSTALE    PIC X(2).
           10 TSAN-NAZ-POSTALE     PIC X(4).
           10 TSAN-TIPO-SPED-P     PIC X(1).
           10 TSAN-DATA-PREACC     PIC S9(8)V USAGE COMP-3.
           10 TSAN-DATA-ESTINZ     PIC S9(8)V USAGE COMP-3.
           10 TSAN-FLAG-STATO      PIC X(1).
           10 TSAN-FLAG-DECESSO    PIC X(1).
           10 TSAN-RAGSOC-1        PIC X(40).
           10 TSAN-RAGSOC-2        PIC X(40).
           10 TSAN-RAGSOC-3        PIC X(40).
           10 TSAN-ACRONIMO        PIC X(20).
           10 TSAN-DATA-CCIAA      PIC S9(8)V USAGE COMP-3.
           10 TSAN-PROV-CCIAA      PIC X(2).
           10 TSAN-NUM-CCIAA       PIC S9(10)V USAGE COMP-3.
           10 TSAN-DATA-TRIB       PIC S9(8)V USAGE COMP-3.
           10 TSAN-PROV-TRIB       PIC X(2).
           10 TSAN-NUM-TRIB        PIC S9(10)V USAGE COMP-3.
           10 TSAN-DATA-ARTIG      PIC S9(8)V USAGE COMP-3.
           10 TSAN-NUM-ARTIG       PIC S9(10)V USAGE COMP-3.
           10 TSAN-MECC-ESTERO     PIC X(8).
           10 TSAN-UIC             PIC X(9).
           10 TSAN-COD-ABI         PIC S9(5)V USAGE COMP-3.
           10 TSAN-TIPO-DOC        PIC X(3).
           10 TSAN-ENTE-RIL        PIC X(30).
           10 TSAN-COD-DOC         PIC X(12).
           10 TSAN-DT-RIL-DOC      PIC S9(8)V USAGE COMP-3.
           10 TSAN-DT-SCAD-DOC     PIC S9(8)V USAGE COMP-3.
           10 TSAN-DATA-VAL-DA     PIC S9(8)V USAGE COMP-3.
           10 TSAN-DATA-VAL-A      PIC S9(8)V USAGE COMP-3.
           10 TSAN-OPERATORE       PIC X(8).
           10 TSAN-TERMINALE       PIC X(4).
           10 TSAN-FIL-OPERANTE    PIC X(5).
           10 TSAN-FILUFF          PIC X(2).
           10 TSAN-DATA-ORA        PIC S9(14)V USAGE COMP-3.
           10 TSAN-PROV-BKT-NEW    PIC X(3).
           10 TSAN-CR-CIN          PIC X(2).
           10 TSAN-RAGSOC-4        PIC X(40).
           10 TSAN-SPECGIUR        PIC X(4).
      *****************************************************************
      * CONTATORI DI LETTURA E SCRITTURA                              *
      *****************************************************************
       01  W-NDG-APPO               PIC 9(12) VALUE ZERO.
       01  W-FINE-CICLO             PIC X(1) VALUE SPACE.
       01  VAR-DA-INOLTRARE         PIC X(2) VALUE SPACE.
       01  W-CTR-ANAG-OK            PIC 9(9) VALUE ZERO.
       01  W-CTR-LETTI              PIC 9(9) VALUE ZERO.
       01  W-CTR-SCRITTI            PIC 9(9) VALUE ZERO.
       01  W-CTR-SCR-RS             PIC 9(9) VALUE ZERO.
       01  W-CTR-SCR-V2             PIC 9(9) VALUE ZERO.
      *****************************************************************
       01  W-STATO1                 PIC X(02) VALUE SPACES.
      *****************************************************************
      *  VARIABILI PER L' ACCETTAZIONE DI DATA E ORA DI SISTEMA       *
      *****************************************************************
       01  WS-DATA-ODIERNA.
           02 WS-AA                    PIC 99.
           02 WS-MM                    PIC 99.
           02 WS-GG                    PIC 99.
       01  WS-DATA-SIS.
           02 WS-SEC                   PIC 99 VALUE 20.
           02 WS-AA                    PIC 99.
           02 WS-MM                    PIC 99.
           02 WS-GG                    PIC 99.
       01  WS-DATA-SIS-RED REDEFINES WS-DATA-SIS PIC 9(8).
      *****************************************************************
      *      VARIABILE DATA DI APPOGGIO PER LA DATA BATCH DI TABELLA  *
      *****************************************************************
150101 01 REC-DATA.
150101     02  ANNO                        PIC 9(4).
150101     02  MESE                        PIC 9(2).
150101     02  GIORNO                      PIC 9(2).
150101 01  WS-DATA-RED REDEFINES REC-DATA  PIC 9(8).
      *
       01  WS-DATA-RIF         PIC 9(8).
       01  WS-DATA-INIZ        PIC  9(8).
       01  WS-DATA-APPO        PIC  9(8).
       01  WS-TIPO-CICLO       PIC  X(1).
211102 01  WS-SQLCODE          PIC ----.
       01  DT-INIZ             PIC S9(8) COMP-3.
       01  DT-FIN              PIC S9(8) COMP-3.
      *****************************************************************
      *****************************************************************
      *     CAMPI    DI   WORKING   PER    GESTIONE    ABEND          *
      *****************************************************************
      *
       77  COMP-CODE                PIC S9(04) COMP VALUE +5555.
      *
       01  W-PROGRAM                PIC X(08)  VALUE SPACES.
      *****************************************************************
      *      INCLUDE  TABELLE  DB2                                    *
      *****************************************************************
      *
           EXEC  SQL  INCLUDE  SQLCA     END-EXEC.
           EXEC  SQL  INCLUDE  SCTBTRIC  END-EXEC.
           EXEC  SQL  INCLUDE  SCTBTDAT  END-EXEC.
           EXEC  SQL  INCLUDE  SCTBTSTO  END-EXEC.
           EXEC  SQL  INCLUDE  SCTBTTAF  END-EXEC.
           EXEC  SQL  INCLUDE  SCTBTANG  END-EXEC.

      *****************************************************************
       PROCEDURE DIVISION.
      *
           DISPLAY '**************************************************'.
           DISPLAY '*            INIZIO  PGM ARRAB060                *'.
           DISPLAY '**************************************************'.
           PERFORM ACQUISISCI-DATA THRU  ACQUISISCI-DATA-EX.
      *
           PERFORM INIZIO-PGM  THRU INIZIO-PGM-EX.
      *
           MOVE 1   TO WS-TIPO-CICLO.
           MOVE '0' TO W-FINE-CICLO.
           PERFORM CICLO-FETCH1 THRU CICLO-FETCH1-EX
                UNTIL  W-FINE-CICLO NOT EQUAL '0'.
      *
           MOVE 2 TO WS-TIPO-CICLO.
           MOVE '0' TO W-FINE-CICLO.
           PERFORM CICLO-FETCH2 THRU CICLO-FETCH2-EX
                UNTIL  W-FINE-CICLO NOT EQUAL '0'.
      *
           PERFORM FINE-PGM    THRU  FINE-PGM-EX.
      *
           STOP RUN.

      *****************************************************************
      * ROUTINE DI ACQUISIZIONE DELLA DATA DI SISTEMA E DI RIFERIMENTO
      *****************************************************************
       ACQUISISCI-DATA.
           ACCEPT WS-DATA-ODIERNA FROM DATE.
           MOVE CORRESPONDING WS-DATA-ODIERNA TO WS-DATA-SIS.
      * ACCESSO TABELLA DATE PER ACQUISIRE LA DATA DI ELABORAZIONE
           EXEC SQL INCLUDE DATA01SL END-EXEC.
           IF SQLCODE NOT EQUAL 0
              DISPLAY 'LABEL ACQUISISCI-DATA'
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           ELSE
              IF TDAT-RICHIESTA = ZERO
150101*          MOVE TDAT-BATCH TO WS-DATA-RIF
150101           MOVE TDAT-BATCH TO WS-DATA-RED
              ELSE
150101*          MOVE TDAT-RICHIESTA TO WS-DATA-RIF
150101           MOVE TDAT-RICHIESTA TO WS-DATA-RED
                 PERFORM AGGIORNA-DATA THRU AGGIORNA-DATA-EX
              END-IF
150101        PERFORM 00200-CALCOLA-DATA THRU 00200-EX
           END-IF.
       ACQUISISCI-DATA-EX.
           EXIT.
       AGGIORNA-DATA.
      *
           MOVE ZERO TO TDAT-RICHIESTA.
           EXEC SQL INCLUDE DATA02UP END-EXEC.
           IF SQLCODE NOT EQUAL 0
              DISPLAY 'LABEL AGGIORNA-DATA'
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.
      *
       AGGIORNA-DATA-EX.
           EXIT.
      *****************************************************************
       INIZIO-PGM.
      *
           EXEC SQL INCLUDE RIC008CD END-EXEC.
           EXEC SQL INCLUDE RIC013CD END-EXEC.
           EXEC SQL INCLUDE RIC014CD END-EXEC.
      *
           PERFORM APRI-CURSORI THRU APRI-CURSORI-EX.
      *
       INIZIO-PGM-EX.
           EXIT.
      *****************************************************************
      *      ROUTINE DI APERTURA CURSORE                              *
      *****************************************************************
       APRI-CURSORI.
      *
170630     DISPLAY ' WS-DATA-RIF     : ' WS-DATA-RIF.
      *
           MOVE WS-DATA-RIF TO TRIC-DT-RIS-ENT.
           EXEC SQL INCLUDE RIC013CO   END-EXEC.
      *
           IF SQLCODE NOT EQUAL 0
              DISPLAY 'LABEL APRI-CURSORE'
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.
      *
           MOVE WS-DATA-RIF TO TRIC-DT-ATT-VF.
           EXEC SQL INCLUDE RIC014CO   END-EXEC.
      *
           IF SQLCODE NOT EQUAL 0
              DISPLAY 'LABEL APRI-CURSORE'
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.
       APRI-CURSORI-EX.
           EXIT.
      *****************************************************************
      *   ROUTINE DI LETTURA DB RICHIESTE                             *
      *****************************************************************
       CICLO-FETCH1.
           PERFORM  INIZIAL-APPO-RIC THRU INIZIAL-APPO-RIC-EX.
           EXEC SQL INCLUDE RIC013CF END-EXEC.
      *
           EVALUATE SQLCODE
           WHEN 0
              ADD 1 TO W-CTR-LETTI
      *
280602        IF TRIC-TIP-ATTIV NOT = 'RR' AND 'R3' AND 'E3' AND
090402                                '70' AND '80' AND 'RC'

181103           IF TRIC-TIP-ATTIV   = 'RS' AND  TRIC-STATO-RICH  = 2
181103              NEXT SENTENCE
181103           ELSE
AUB018            IF (TRIC-TIP-ATTIV  = 'V2' AND TRIC-ESITO  = 'OK' )
AUB018               DISPLAY 'V2/OK  TRIC-NDG-PF: '  TRIC-NDG-PF
AUB018            ELSE
                    MOVE DCLSCTBTRIC        TO  APPO-RIC(1)
211102              IF TRIC-TIP-ATTIV = 'DD' OR 'DR' OR 'DC'
211102                 PERFORM SELECT-TSTO THRU SELECT-TSTO-EX
211102                 MOVE TSTO-DT-RIS-ENT    TO  WS-DATA-INIZ
211102              ELSE
                    MOVE TAPP-DT-INV-ENT(1) TO  WS-DATA-INIZ
211102              END-IF
                    PERFORM TRATTA-RICH THRU TRATTA-RICH-EX
AUB018            END-IF
181103           END-IF
280602        END-IF
      *
           WHEN 100
              MOVE '1' TO  W-FINE-CICLO
      *
           WHEN OTHER
              DISPLAY ' LABEL CICLO-FETCH          '
              DISPLAY ' LETTURA DB TRIC - ANAGRAFE SCOPERTO C/C'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-EVALUATE.
       CICLO-FETCH1-EX.
           EXIT.
      *****************************************************************
      *   ROUTINE DI LETTURA DB RICHIESTE                             *
      *****************************************************************
       CICLO-FETCH2.
           PERFORM INIZIAL-APPO-RIC THRU INIZIAL-APPO-RIC-EX.
           EXEC SQL  INCLUDE RIC014CF    END-EXEC.
      *
           EVALUATE SQLCODE
           WHEN 0
              ADD 1 TO W-CTR-LETTI
      *
              MOVE DCLSCTBTRIC         TO  APPO-RIC(1)
300902        IF TAPP-TIP-ATTIV(1) = 'DF'
                 MOVE TAPP-DT-RIS-ENT(1)  TO  WS-DATA-INIZ
300902        ELSE
300902           MOVE TAPP-DT-INV-ENT(1)  TO  WS-DATA-INIZ
300902        END-IF
              PERFORM TRATTA-RICH THRU TRATTA-RICH-EX
      *
           WHEN 100
              MOVE '1' TO  W-FINE-CICLO
      *
           WHEN OTHER
              DISPLAY ' LABEL CICLO-FETCH          '
              DISPLAY ' LETTURA DB TRIC- ANAGRAFE SCOPERTO C/C'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-EVALUATE.
       CICLO-FETCH2-EX.
           EXIT.
       FINE-PGM.
           EXEC SQL  INCLUDE RIC013CC   END-EXEC.
           IF SQLCODE NOT = 0
              DISPLAY ' LABEL FINE-PGM          '
              DISPLAY ' CLOSE CURSORE TRIC '
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF
      *
           EXEC SQL  INCLUDE RIC014CC   END-EXEC.
           IF SQLCODE NOT = 0
              DISPLAY ' LABEL FINE-PGM          '
              DISPLAY ' CLOSE CURSORE TRIC '
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF
      *
           DISPLAY '**************************************************'.
           DISPLAY '*               FINE PGM ARRAB060                *'.
           DISPLAY '**************************************************'.
           DISPLAY '*RECORD LETTI SU SCTBTRIC CHE HANNO RICEVUTO     *'.
           DISPLAY '*ESITO DB IN DATA______________: ' W-CTR-LETTI
      -            '       *'.
           DISPLAY '*TOT. POSIZIONI CHE HANNO SUBITO VARIAZIONI      *'.
           DISPLAY '*ANAGRAFICHE___________________: ' W-CTR-ANAG-OK
      -            '       *'.
           DISPLAY '*RECORD DA INVIARE ALL''ENTE____: ' W-CTR-SCRITTI
      -            '       *'.
           DISPLAY '*DI CUI :                                        *'.
           DISPLAY '*-RICHIESTE DA REINVIARE_______: ' W-CTR-SCR-RS
      -            '       *'.
           DISPLAY '*-VARIAZIONI ANAGRAFICHE_______: ' W-CTR-SCR-V2
      -            '       *'.
           DISPLAY '**************************************************'.
       FINE-PGM-EX.
           EXIT.
      *****************************************************************
       TRATTA-RICH.
           MOVE TAPP-NDG-PF(1) TO W-NDG-APPO.
           MOVE W-NDG-APPO     TO REC-NDG.
           MOVE WS-DATA-RIF    TO REC-DATA-FINE.
171002*    MOVE WS-DATA-INIZ   TO REC-DATA-INIZIO.
171002*    IF TAPP-TIP-ATTIV(1) ='RS' OR 'V2'
211102     IF (TAPP-TIP-ATTIV(1) = 'RS' OR 'V2')
211102     OR (TAPP-TIP-ATTIV(1) = 'DD'
211102     AND TSTO-TIP-ATTIV = 'V2')
171002        MOVE WS-DATA-INIZ   TO REC-DATA-INIZIO
171002     ELSE
171002        PERFORM CALCOLA-DATA THRU CALCOLA-DATA
171002        MOVE UTDATA-DATA-2  TO REC-DATA-INIZIO
171002     END-IF.
170630     DISPLAY ' REC-NDG         : ' REC-NDG
170630     DISPLAY ' REC-DATA-INIZIO : ' REC-DATA-INIZIO
170630     DISPLAY ' REC-DATA-FINE   : ' REC-DATA-FINE

           CALL ANAG USING  AMG108IN-OUT.

           EVALUATE COD-RIT
            WHEN '00'
             ADD 1 TO W-CTR-ANAG-OK
             MOVE REC-TANA TO W-TANA
             MOVE REC-TSAN TO W-TSAN
             PERFORM ANALIZZA-VARIAZIONE THRU ANALIZZA-VARIAZIONE-EX
            WHEN '06'
301203*      DISPLAY ' NON ESISTONO VAR IN ANAGRAFE GENERALE PER:'
301203*      DISPLAY ' NDG ' REC-NDG 'NEL PERIODO ' REC-DATA-INIZIO '-'
301203*                                             REC-DATA-FINE
             PERFORM VERIFICA-SETTORIALE THRU VERIFICA-SETTORIALE-EX
            WHEN OTHER
             DISPLAY ' LABEL TRATTA-RICH          '
             DISPLAY ' ERRORE INTERFACCIA ANAGRAFE AMG108 '
             DISPLAY ' CODICE DI RITORNO ' COD-RIT
             PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-EVALUATE.
       TRATTA-RICH-EX.
           EXIT.

211102*****************************************************************
211102*  ACCESSO ALLA TABELLA DB2 DELLE POSIZIONI STORICIZZATE        *
211102*****************************************************************
211102 SELECT-TSTO.
211102*
211102     MOVE TAPP-CATEGORIA(1)        TO TSTO-CATEGORIA.
211102     MOVE TAPP-FILIALE(1)          TO TSTO-FILIALE.
211102     MOVE TAPP-NUMERO(1)           TO TSTO-NUMERO.
211102     MOVE TAPP-NDG-PF(1)           TO TSTO-NDG-PF.
211102     MOVE 99999999                 TO TSTO-DT-VAL-A.
211102*
211102     EXEC SQL INCLUDE STO007SL END-EXEC.
211102*
211102     IF SQLCODE NOT EQUAL 0
211102        MOVE SQLCODE  TO WS-SQLCODE
211102        DISPLAY 'LABEL SELECT-TSTO'
211102        DISPLAY 'ERRORE SQL CODICE DI RITORNO ' WS-SQLCODE
211102        PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
211102     ELSE
211102        IF  TAPP-TIP-ATTIV(1) = 'DR'
211102        AND TSTO-TIP-ATTIV NOT = 'RR'
211102        DISPLAY '**********************************************'
211102        DISPLAY '*  S E G N A L A Z I O N E  A N O M A L I A  *'
211102        DISPLAY '**********************************************'
211102        DISPLAY '* TROVATA INCONGRUENZA TRA TABELLA SCTBTRIC  *'
211102        DISPLAY '* E TABELLA SCTBTSTO: LA POSIZIONE STORICIZ- *'
211102        DISPLAY '* ZATA PRECEDENTEMENTE ALLA DISATTIVAZIONE   *'
211102        DISPLAY '* DELLA REVOCA NON RISULTA UNA REVOCA        *'
211102        DISPLAY '**********************************************'
211102        DISPLAY '* ------------------------------------------  '
211102        DISPLAY '* TSTO-TIP-ATTIV : ' TSTO-TIP-ATTIV
211102        DISPLAY '* TRIC-TIP-ATTIV : ' TAPP-TIP-ATTIV(1)
211102        DISPLAY '* ------------------------------------------  '
211102        DISPLAY '**********************************************'
211102        END-IF
211102        IF  TAPP-TIP-ATTIV(1) = 'DC'
211102        AND TSTO-TIP-ATTIV NOT = 'RC'
211102        DISPLAY '**********************************************'
211102        DISPLAY '*  S E G N A L A Z I O N E  A N O M A L I A  *'
211102        DISPLAY '**********************************************'
211102        DISPLAY '* TROVATA INCONGRUENZA TRA TABELLA SCTBTRIC  *'
211102        DISPLAY '* E TABELLA SCTBTSTO: LA POSIZIONE STORICIZ- *'
211102        DISPLAY '* ZATA PRECEDENTEMENTE ALLA DISATTIVAZIONE   *'
211102        DISPLAY '* DELLA RINUNCIA CLIENTE NON RISULTA UNA     *'
211102        DISPLAY '* RINUNCIA CLIENTE                           *'
211102        DISPLAY '**********************************************'
211102        DISPLAY '* ------------------------------------------  '
211102        DISPLAY '* TSTO-TIP-ATTIV : ' TSTO-TIP-ATTIV
211102        DISPLAY '* TRIC-TIP-ATTIV : ' TAPP-TIP-ATTIV(1)
211102        DISPLAY '* ------------------------------------------  '
211102        DISPLAY '**********************************************'
211102        END-IF
211102     END-IF.
211102*
211102 SELECT-TSTO-EX.
211102     EXIT.

171002*****************************************************************
171002*  ROUTINE DI CALCOLO DATA TRAMITE ROUTINE XSCDAT               *
171002*****************************************************************
171002 CALCOLA-DATA.
171002     INITIALIZE UTDATA-PARAM.
171002     MOVE  4                 TO UTDATA-FUNZIONE.
171002     MOVE  1                 TO UTDATA-GIORNI.
171002     MOVE  WS-DATA-INIZ      TO UTDATA-DATA-1.
171002*
171002     MOVE 'XSCDAT'        TO DYNACALL.
171002     CALL DYNACALL USING UTDATA-PARAM.
171002*
171002     IF UTDATA-ERRORE NOT = ZERO
171002        DISPLAY 'LABEL CALCOLA-DATA'
171002        DISPLAY 'CALCOLO DATA NON RIUSCITO'
171002        DISPLAY 'UTDATA-ERRORE.:' UTDATA-ERRORE
171002        DISPLAY 'NDG...........:' REC-NDG
171002        DISPLAY 'DATA INIZIO...:' WS-DATA-INIZ
171002        DISPLAY 'DATA FINE.....:' REC-DATA-FINE
171002        PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
171002     END-IF.
171002 CALCOLA-DATA-EX.
171002     EXIT.

       ANALIZZA-VARIAZIONE.
           IF TANA-NDG NOT = TSAN-NDG
             DISPLAY ' LABEL ANALIZZA-VARIAZIONE  '
             DISPLAY ' DISALLINEAMENTO INTERFACCIA ANAGRAFE '
             PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.
      * VIENE CONTROLLATO SE Û CAMBIATO IL COMUNE DI RESIDENZA, E IN
      * CASO POSITIVO INIZIALIZZATO SULLA TABELLA ANAGRAFE SETTORIALE
           IF   TANA-LOC-SEDE-LEG    NOT = TSAN-LOC-SEDE-LEG
              PERFORM ABBLENCA-COMUNE THRU ABBLENCA-COMUNE-EX
           END-IF.
           IF   TANA-COGNOME         NOT = TSAN-COGNOME
             OR TANA-NOME            NOT = TSAN-NOME
171002       OR TANA-RAGSOC-1        NOT = TSAN-RAGSOC-1
      * +    OR TANA-RAGSOC-2        NOT = TSAN-RAGSOC-2
171002       OR TANA-RAGSOC-2(1:30)  NOT = TSAN-RAGSOC-2(1:30)
      * +    OR TANA-RAGSOC-3        NOT = TSAN-RAGSOC-3
      * +    OR TANA-RAGSOC-4        NOT = TSAN-RAGSOC-4
             OR TANA-COD-FISCALE     NOT = TSAN-COD-FISCALE
             OR TANA-IND-SEDE-LEG    NOT = TSAN-IND-SEDE-LEG
             OR TANA-LOC-SEDE-LEG    NOT = TSAN-LOC-SEDE-LEG
             OR TANA-PROV-SEDE-LEG   NOT = TSAN-PROV-SEDE-LEG
             OR TANA-CAP-SEDE-LEG    NOT = TSAN-CAP-SEDE-LEG
             OR TANA-NAZ-SEDE-LEG    NOT = TSAN-NAZ-SEDE-LEG
             OR TANA-TIPO-DOC        NOT = TSAN-TIPO-DOC
             OR TANA-COD-DOC         NOT = TSAN-COD-DOC
             OR TANA-DT-RIL-DOC      NOT = TSAN-DT-RIL-DOC
171002       OR TANA-SESSO           NOT = TSAN-SESSO
171002       OR TANA-LUOGO-NASCITA   NOT = TSAN-LUOGO-NASCITA
171002       OR TANA-PROV-NASCITA    NOT = TSAN-PROV-NASCITA
171002       OR TANA-NAZ-NASCITA     NOT = TSAN-NAZ-NASCITA
171002       OR TANA-ENTE-RIL        NOT = TSAN-ENTE-RIL
      * +    OR TANA-NUOVO-GUE       NOT = TANA-NUOVO-GUE
      * +    OR TANA-NUOVO-RAE       NOT = TANA-NUOVO-RAE
           THEN
             PERFORM CONTROLLO-COI THRU CONTROLLO-COI-EX
           ELSE
301203*      DISPLAY
301203*     ' VAR ANAGRAFICHE NON DI INTERESSE PER DEUTSCHE BANK: '
301203*      DISPLAY ' NDG ' REC-NDG 'NEL PERIODO ' REC-DATA-INIZIO '-'
301203*                                             REC-DATA-FINE
             PERFORM VERIFICA-SETTORIALE THRU VERIFICA-SETTORIALE-EX
           END-IF.
       ANALIZZA-VARIAZIONE-EX.
           EXIT.
       CONTROLLO-COI.
           IF TAPP-NDG-COI(1) NOT = SPACE
              PERFORM COI THRU COI-EX
           ELSE
      * NON E' UN CASO DI COINTESTAZIONE
              MOVE 'OK' TO VAR-DA-INOLTRARE
           END-IF.
           IF VAR-DA-INOLTRARE = 'OK'
              PERFORM INSERISCE-NUOVA-RIC
                 THRU INSERISCE-NUOVA-RIC-EX
           END-IF.
       CONTROLLO-COI-EX.
           EXIT.
       COI.
           EXEC SQL INCLUDE RIC008CO END-EXEC.
           IF SQLCODE NOT = ZERO
              DISPLAY ' LABEL COI '
              DISPLAY ' OPEN CURSORE SU TAB SCTBTRIC'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.

           MOVE 'OK' TO VAR-DA-INOLTRARE
           PERFORM FETCH-COI THRU FETCH-COI-EX
                   VARYING J FROM 2 BY 1
                   UNTIL SQLCODE = +100 OR VAR-DA-INOLTRARE = 'KO'.

           EXEC SQL INCLUDE RIC008CC END-EXEC.
           IF SQLCODE NOT = ZERO
              DISPLAY ' LABEL COI '
              DISPLAY ' OPEN CURSORE SU TAB SCTBTRIC'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.
       COI-EX.
           EXIT.
      ****************************************************************
       FETCH-COI.
           EXEC SQL INCLUDE RIC008CF END-EXEC.

           IF SQLCODE = ZERO
              IF DCLSCTBTRIC NOT =  APPO-RIC(1)
                 MOVE DCLSCTBTRIC TO APPO-RIC(J)
              ELSE
                 SUBTRACT 1 FROM J
              END-IF
              PERFORM APPLICA-CRITERI THRU APPLICA-CRITERI-EX
           END-IF.

           IF SQLCODE NOT = ZERO AND NOT = +100
              DISPLAY ' LABEL FETCH-COI '
              DISPLAY ' FETCH SU TAB SCTBTRIC'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.
       FETCH-COI-EX.
           EXIT.
       APPLICA-CRITERI.
           MOVE 'OK' TO  VAR-DA-INOLTRARE.

      *  NON VENGONO INVIATE VARIAZIONI SE LO STATO NON E' OMOGENEO
      *  ALL'INTERNO DELLA COINTESTAZIONE

      *1 RICH. DI VARIAZIONI ANAGRAFICHE O DI FIDO
           IF WS-TIPO-CICLO = 1
300902*       IF (TRIC-TIP-ATTIV = 'V1' OR 'V2' OR 'RS') AND
300902        IF (TRIC-TIP-ATTIV = 'V1' OR 'V2' OR 'RS' OR 'A3') AND
                  TRIC-STATO-RICH NOT > 1
                  MOVE 'KO' TO  VAR-DA-INOLTRARE
              END-IF

040504        IF TRIC-TIP-ATTIV = 'A3'  AND
040504            TRIC-STATO-RICH NOT > 2
040504            MOVE 'KO' TO  VAR-DA-INOLTRARE
040504        END-IF

101203        IF TRIC-ESITO= 'KR'  OR 'KO' AND
101203           TRIC-TIP-ATTIV NOT = 'V2'
101203           MOVE 'KO' TO  VAR-DA-INOLTRARE
101203        END-IF
           END-IF.


      *2 RICH. DI AUMENTO, DIMINUZIONE FIDO
           IF WS-TIPO-CICLO = 2
300902*       IF (TRIC-TIP-ATTIV = 'A3' OR 'D3' OR 'DF') AND
300902        IF (TRIC-TIP-ATTIV = 'D3' OR 'DF') AND
                  TRIC-STATO-RICH NOT > 2
                  MOVE 'KO' TO  VAR-DA-INOLTRARE
              END-IF
101203        IF TRIC-ESITO= 'KR' OR 'KO' AND
101203           TRIC-TIP-ATTIV NOT = 'V2'
101203           MOVE 'KO' TO  VAR-DA-INOLTRARE
101203        END-IF
           END-IF.

       APPLICA-CRITERI-EX.
           EXIT.
       INSERISCE-NUOVA-RIC.

      * STORICIZZA LA RICHIESTA CORRENTE
160101*    MOVE   APPO-RIC(1) TO  DCLSCTBTSTO.
160101*    PERFORM STOR THRU STOR-EX.

      * VERIFICA ESISTENZA FIDO E STABILISCE SE PREDISPORRE UNA "RS"
      * OPPURE UNA "V2"
           PERFORM VERIFICA-FIDO THRU VERIFICA-FIDO-EX.

      * AGGIORNA L'ARCHIVIO RICHIESTE PER INOLTRARE UNA NUOVA RICHIESTA
           PERFORM AGGIORNA-RIC THRU AGGIORNA-RIC-EX.
       INSERISCE-NUOVA-RIC-EX.
           EXIT.
       VERIFICA-FIDO.
      * VERIFICA ESISTENZA FIDO
           IF ( TAPP-NDG-COI(1) = SPACE OR
                TAPP-NDG-COI(1) = TAPP-NDG-PF(1) )
               MOVE  TAPP-NDG-PF(1)  TO TTAF-NDG
           ELSE
               MOVE  TAPP-NDG-COI(1) TO TTAF-NDG
           END-IF.

           MOVE TAPP-NUMERO(1) TO  TTAF-NUMERO.
251000     MOVE 99999999       TO  TTAF-DT-VAL-A.

           EXEC SQL INCLUDE AFF003SL END-EXEC.

      * SOLO NEL CASO IN CUI NON ESISTA ANCORA UN FIDO VIENE INVIATA
      * DI NUOVO LA PROPOSTA CON TIPO ATTIVITA' VALORIZZATA A RS

           IF SQLCODE = 100
160101        IF TRIC-ESITO = 'OK'
160101           MOVE   APPO-RIC(1) TO  DCLSCTBTSTO
160101           PERFORM STOR THRU STOR-EX
160101        END-IF
              MOVE 'RS' TO TRIC-TIP-ATTIV
           ELSE
160101        MOVE   APPO-RIC(1) TO  DCLSCTBTSTO
160101        PERFORM STOR THRU STOR-EX
              MOVE 'V2' TO TRIC-TIP-ATTIV
              IF SQLCODE NOT = 0
                 DISPLAY ' LABEL VERIFICA-FIDO        '
                 DISPLAY ' LETTURA DB TTAF - SQLCODE ' SQLCODE
                 PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
              END-IF
           END-IF.
       VERIFICA-FIDO-EX.
           EXIT.
       AGGIORNA-RIC.

           MOVE ZERO              TO TRIC-STATO-RICH
150101     MOVE SPACES            TO TRIC-ESITO
           MOVE ZERO              TO TRIC-DT-INV-ENT
           MOVE ZERO              TO TRIC-DT-RIS-ENT
           MOVE ZERO              TO TRIC-DT-ATT-VF
           MOVE WS-DATA-RIF       TO TRIC-DT-RIC-ATT
           MOVE 'ARRAB060'        TO TRIC-COD-OPER
           MOVE TAPP-NDG-PF(1)    TO TRIC-NDG-PF
           MOVE TAPP-NDG-COI(1)   TO TRIC-NDG-COI
           MOVE TAPP-SERVIZIO(1)  TO TRIC-SERVIZIO
           MOVE TAPP-CATEGORIA(1) TO TRIC-CATEGORIA
           MOVE TAPP-FILIALE(1)   TO TRIC-FILIALE
           MOVE TAPP-NUMERO(1)    TO TRIC-NUMERO
           EXEC SQL INCLUDE RIC009UP END-EXEC.
           ADD 1 TO W-CTR-SCRITTI.
           IF TRIC-TIP-ATTIV = 'RS'
              ADD 1 TO W-CTR-SCR-RS
           END-IF.
           IF TRIC-TIP-ATTIV = 'V2'
              ADD 1 TO W-CTR-SCR-V2
           END-IF.
           IF SQLCODE NOT = ZERO
              DISPLAY ' LABEL AGGIORNA-RIC'
              DISPLAY ' UPDATE SU TAB SCTBTRIC'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.

      * IN CASO DI COINTESTAZIONE E TIPO INVIO = "RS"
      * VIENE RIAGGIORNATO STATO  TIPO INVIO PER TUTTI I REC DELLA COI
      * E VENGONO STORICIZZATE LE ALTRE 2 OCCORRENZE
           IF TRIC-TIP-ATTIV = 'RS' AND
              TRIC-NDG-COI NOT = SPACE
              MOVE ZERO           TO TRIC-STATO-RICH
160101        MOVE SPACES         TO TRIC-ESITO
              MOVE ZERO           TO TRIC-DT-INV-ENT
              MOVE ZERO           TO TRIC-DT-RIS-ENT
              MOVE WS-DATA-RIF    TO TRIC-DT-RIC-ATT
              MOVE 'ARRAB060'     TO TRIC-COD-OPER
              EXEC SQL INCLUDE RIC010UP END-EXEC
              IF SQLCODE NOT = ZERO
                 DISPLAY ' LABEL INSERISCE-STO'
                 DISPLAY ' INSERT SU TAB SCTBTSTO'
                 DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
                 PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
              END-IF
      *  STORICIZZAZIONE DELLA 2µ
              MOVE   APPO-RIC(2) TO  DCLSCTBTSTO
              PERFORM STOR THRU STOR-EX
      *  STORICIZZAZIONE DELLA 3µ
              MOVE   APPO-RIC(3) TO  DCLSCTBTSTO
              PERFORM STOR THRU STOR-EX
           END-IF.
       AGGIORNA-RIC-EX.
           EXIT.
      *****************************************************************
      *****************************************************************
       INIZIAL-APPO-RIC.
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > 10
                   INITIALIZE  APPO-RIC(J)
           END-PERFORM.
       INIZIAL-APPO-RIC-EX.
           EXIT.
       STOR.
           MOVE WS-DATA-RIF TO TSTO-DT-VAL-A.
           MOVE 'ARRAB060' TO TSTO-COD-OPER.
           EXEC SQL INCLUDE STO001IN END-EXEC
           IF SQLCODE NOT = ZERO
              DISPLAY ' INSERISCE-NUOVA-RIC'
              DISPLAY ' INSERT SU TAB SCTBTSTO'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.
       STOR-EX.
           EXIT.
       VERIFICA-SETTORIALE.
           MOVE 'OK' TO  VAR-DA-INOLTRARE.

           MOVE TAPP-DT-RIS-ENT(1) TO DT-FIN.
           MOVE TAPP-DT-INV-ENT(1) TO DT-INIZ.
           MOVE TAPP-NDG-PF(1)     TO TANG-NDG.
           EXEC SQL INCLUDE ANG002SL END-EXEC
           EVALUATE SQLCODE
            WHEN  ZERO
              PERFORM CONTROLLO-COI THRU CONTROLLO-COI-EX

            WHEN  +100
               CONTINUE
301203*      DISPLAY ' NON ESISTONO VAR IN ANAGRAFE SETTORIALE PER:'
301203*      DISPLAY ' NDG ' REC-NDG 'NEL PERIODO ' REC-DATA-INIZIO '-'
301203*                                             REC-DATA-FINE
            WHEN  OTHER
              DISPLAY ' P R O G R A M M A  A R R A B 0 6 0 '
              DISPLAY ' NDG:' TANG-NDG
              DISPLAY ' VERIFICA SETTORIALE'
              DISPLAY ' SELECT SU TAB SCTBTANG'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-EVALUATE.
       VERIFICA-SETTORIALE-EX.
           EXIT.
       ABBLENCA-COMUNE.
            MOVE TANA-NDG    TO W-NDG-APPO.
            MOVE W-NDG-APPO  TO TANG-NDG.
            MOVE SPACE       TO TANG-LOC-RES
010301                          TANG-CAP-RES
010301                          TANG-PROV-RES.
            EXEC SQL INCLUDE ANG001UP END-EXEC.
            IF SQLCODE NOT = ZERO
              DISPLAY ' P R O G R A M M A  A R R A B 0 6 0 '
              DISPLAY 'NDG:' TANG-NDG
              DISPLAY ' LABEL ABBLENCA-COMUNE '
              DISPLAY ' UPDATE SU TAB SCTBTANG'
              DISPLAY ' ERRORE SQL CODICE DI RITORNO ' SQLCODE
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
            END-IF.
       ABBLENCA-COMUNE-EX.
            EXIT.
      *****************************************************************
      *     ROUTINE DI GESTIONE ERRORE                               *
      *****************************************************************
       99999-GEST-ABEND.

            MOVE 'ILBOABN0'  TO  W-PROGRAM.

            CALL W-PROGRAM  USING  COMP-CODE.

       99999-GEST-ABEND-EX.
           EXIT.
      *****************************************************************
      *  ROUTINE DI CALCOLO DELLA DATA                                *
      *****************************************************************
150101 00200-CALCOLA-DATA.
           INITIALIZE UTDATA-PARAM.
           MOVE  9              TO    UTDATA-FUNZIONE.
           MOVE  6              TO    UTDATA-FUNZIONE-2.
           MOVE  1              TO    UTDATA-GIORNI.
           MOVE REC-DATA        TO    UTDATA-DATA-1.
      *
           MOVE 'XSCDAT'        TO DYNACALL.
           CALL DYNACALL USING UTDATA-PARAM.
      *
           IF UTDATA-ERRORE = ZERO
              MOVE UTDATA-SEC-ANNO-2 TO ANNO
              MOVE UTDATA-MESE-2     TO MESE
              MOVE UTDATA-GIORNO-2   TO GIORNO
              MOVE WS-DATA-RED TO WS-DATA-RIF
              GO TO 00200-EX
           ELSE
              DISPLAY 'LABEL 00200-CALCOLA-DATA'
              DISPLAY 'CALCOLO NON AVVENUTO'
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX
           END-IF.
150101 00200-EX.
150101     EXIT.
