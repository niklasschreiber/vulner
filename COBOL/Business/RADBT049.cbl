      *================================================================*
      *   CODICE ATTIVITA:  105439                                     *
      *                                                                *
      *   PROCEDURA : SIRADO CONTI DORMIENTI. ESTRAZIONE SIRADO        *
      *                                                                *
      *   FUNZIONE  : CODA DELL'ATTIVITA DI PUBBLICAZIONI E RACCOMANDATE
      *               AGGIORNA STATO TABELLA RICHIESTE CMM ESITO 'OK'  *
      *               AGGIORNA STATO TABELLA CALENDARIO CON STATO 'EC' *
      *   PROGRAMMA : RADBT049                                         *
      *                                                                *
      *   SCHEDULE  : GIORNALIERA                                      *
      *                                                                *
      *================================================================*
      *  TABELLE GESTITE                                               *
      *               RADBRIC                                          *
      *               RADCALE                                          *
      *               RADCALES                                         *
      *================================================================*
       IDENTIFICATION DIVISION.
      *================================================================*
       PROGRAM-ID. RADBT049.
       AUTHOR.
      *================================================================*
      *   E N V I R O N M E N T   D I V I S I O N                      *
      *================================================================*
       ENVIRONMENT DIVISION.
      *================================================================*
      **                                                               *
      *================================================================*
      *   C O N F I G U R A T I O N   S E C T I O N                    *
      *================================================================*
       CONFIGURATION SECTION.
      *================================================================*
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *================================================================*
      *   I N P U T - O U T P U T   S E C T I O N                      *
      *================================================================*
       INPUT-OUTPUT SECTION.
      *================================================================*
       FILE-CONTROL.
      *                                                                *
      *================================================================*
      *   D A T A   D I V I S I O N                                    *
      *================================================================*
       DATA DIVISION.
      *================================================================*
      *                                                                *
      *================================================================*
      *   F I L E   S E C T I O N                                      *
      *================================================================*
       FILE SECTION.
      *================================================================*
      *                                                                *
      *================================================================*
      *   W O R K I N G - S T O R A G E   S E C T I O N                *
      *================================================================*
       WORKING-STORAGE SECTION.
      *================================================================*
      *   COPY DI INTERFACCIA PER MODULI TABELLE
      *================================================================*
       COPY RADCDCAL.
       COPY RADCDCAS.
       COPY RADCDBRI.

      *================================================================*
      *    AREA DI COMODO PER ELABORAZIONE PROGRAMMA                   *
      *================================================================*
       01  WK-COSTANTI-FLAG.
           05 WK-RADBT049                PIC X(08) VALUE 'RADBT049'.
           05 WS-CURRENT-OPCD            PIC 9(08) .
           05 WS-CURRENT-DATE            PIC 9(08) .
           05 WS-CURRENT-TIME            PIC 9(08) .
           05 WS-DATA-ESTR               PIC 9(08) .
           05 WS-DATA-SBLOCCO            PIC 9(08) .
           05 WS-DATA-RICH               PIC 9(08) .
           05 WS-ESITO-ELAB              PIC X(02) .
           05 WS-STATO-CALE              PIC X(02) .
           05 WS-STATO-BRIC              PIC X     .
           05 WS-ID-CALE                 PIC S9(04) .
           05 WS-PROGR-CALES             PIC S9(03) .
       01  SAVE-AREAS.
           05 SAVE-RADCDBRI-REC          PIC X(1000) .
           05 SAVE-RADCDCAL-REC          PIC X(1000) .
      *
      *================================================================*
      *  AREA DI PASSAGGIO                                             *
      *================================================================*
       01  AREA-ARCHIVIO.
           03  ARCHIVIO-SW          PIC X(02).
           03  ARCHIVIO-TRAC        PIC X(04).
           03  ARCHIVIO-FUNZ        PIC X(03).
           03  ARCHIVIO-PGM         PIC X(08).
           03  ARCHIVIO-DATA        PIC X(08).
           03  ARCHIVIO-ORA         PIC X(06).
           03  ARCHIVIO-TIPOMOD     PIC X(01).
           03  ARCHIVIO-RETCODE     PIC X(06).
           03  ARCHIVIO-FILLER      PIC X(71).
           03  ARCHIVIO-REC         PIC X(01000).
      *================================================================*
      *  AREE DI COMODO PER GESTIONE ERRORE                            *
      *================================================================*
       01    CAMPI-ERRORE.
               10 ERR-PROGRAMMA          PIC X(08).
               10 ERR-PUNTO              PIC X(04).
               10 ERR-DESCRIZIONE        PIC X(80).
               10 ERR-CODICE-X           PIC X(06).
               10 ERR-CODICE-Z           PIC -----9.
               10 ERR-DATI               PIC X(80).
               10 ERR-GRAVE              PIC X(02).
      *
      *================================================================*
      *   L I N K A G E   S E C T I O N                                *
      *================================================================*
       LINKAGE SECTION.
       01 APPL-REC.
           05 APPL-SIZE          PIC S9(4) COMP.
           05 APPL-NAME          PIC X(4).
      *================================================================*
      *                                                                *
      *================================================================*
      *   P R O C E D U R E   D I V I S I O N                          *
      *================================================================*
       PROCEDURE DIVISION     USING APPL-REC.
      *================================================================*
      *   M A I N                                                      *
      *================================================================*
       INIZIO-MAIN.
           PERFORM INIZIO                      THRU INIZIO-EX.
           PERFORM ELABORA                     THRU ELABORA-EX.
           PERFORM FINE                        THRU FINE-EX.
       FINE-MAIN.
      *----------------------------------------------------------------*
       INIZIO.
           DISPLAY '*==============================================*'.
           DISPLAY '*====       INIZIO PROGRAMMA RADBT049      ====*'.
           DISPLAY '*====      START/STOP ESTRAZIONE  SIRADO   ====*'.
           DISPLAY '*==============================================*'.
      *
           INITIALIZE                             CAMPI-ERRORE.
           MOVE "RADBT049"               TO ERR-PROGRAMMA.
      *
           INITIALIZE         WS-CURRENT-OPCD
           ACCEPT WS-CURRENT-OPCD FROM SYSIN.
           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD.
           ACCEPT WS-CURRENT-TIME FROM TIME.

       INIZIO-EX.
           EXIT.
      *----------------------------------------------------------------*
       ELABORA.
           INITIALIZE    AREA-ARCHIVIO   RADCDBRI-REC
           MOVE   '0008'          TO     ARCHIVIO-TRAC
           MOVE   'SI'            TO     ARCHIVIO-SW.
           MOVE   'RED'           TO     ARCHIVIO-FUNZ.
           MOVE   WS-CURRENT-OPCD TO     BRIC-DATA-RICH
           MOVE   'A'             TO     BRIC-STATO
           MOVE   'RAC'           TO     BRIC-TIPO-FUNZ
           PERFORM LEGGI-RICHIESTA     THRU LEGGI-RICHIESTA-EX

           PERFORM SALVA-DATI-RICH     THRU SALVA-DATI-RICH-EX

           PERFORM AGGIORNA-RICHIESTA THRU AGGIORNA-RICHIESTA-EX

           PERFORM LEGGI-CALENDARIO   THRU LEGGI-CALENDARIO-EX

           PERFORM SALVA-DATI-CALEND  THRU SALVA-DATI-CALEND-EX

           PERFORM CURR-PROGR-CALES   THRU CURR-PROGR-CALES-EX.

           PERFORM NEW-PROGR-CALES    THRU NEW-PROGR-CALES-EX.

           PERFORM INS-CALES          THRU INS-CALES-EX.

           PERFORM UPD-CALE           THRU UPD-CALE-EX.

       ELABORA-EX.
           EXIT.
      *----------------------------------------------------------------*
      *
      *----------------------------------------------------------------*
       LEGGI-RICHIESTA.
           MOVE   RADCDBRI-REC    TO     ARCHIVIO-REC
           CALL 'RADYDBRI'  USING   AREA-ARCHIVIO.
           IF  ARCHIVIO-SW NOT= 'SI'
              MOVE '0002'                   TO ERR-PUNTO
              MOVE SPACES                   TO ERR-DESCRIZIONE
              MOVE 'ERRORE RADYDBRI'        TO ERR-DESCRIZIONE
              MOVE ARCHIVIO-RETCODE         TO ERR-CODICE-X
              MOVE 'SI'                     TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
           END-IF.
       LEGGI-RICHIESTA-EX.
           EXIT.
      *
       SALVA-DATI-RICH.
           INITIALIZE SAVE-RADCDBRI-REC
           MOVE  ARCHIVIO-REC    TO  RADCDBRI-REC
           MOVE  RADCDBRI-REC    TO  SAVE-RADCDBRI-REC.
           MOVE  BRIC-ESITO-ELAB TO  WS-ESITO-ELAB.
           MOVE  BRIC-STATO      TO  WS-STATO-BRIC.
           MOVE  BRIC-DATA-RICH  TO  WS-DATA-RICH.
       SALVA-DATI-RICH-EX.
           EXIT.

      *
       AGGIORNA-RICHIESTA.
           INITIALIZE   AREA-ARCHIVIO  RADCDBRI-REC
           MOVE SAVE-RADCDBRI-REC    TO  RADCDBRI-REC
           MOVE    'E'               TO  BRIC-STATO
           MOVE    'OK'              TO  BRIC-ESITO-ELAB
           MOVE WS-CURRENT-DATE      TO  BRIC-DATAANN
           MOVE WS-CURRENT-TIME(1:6) TO  BRIC-ORAANN
           MOVE  'SIRADO'            TO  BRIC-TERMANN
           MOVE  'BATCH'             TO  BRIC-COPERAN
           MOVE  '55974'             TO  BRIC-DIPEANN
           MOVE  RADCDBRI-REC        TO  ARCHIVIO-REC
           MOVE   'SI'               TO  ARCHIVIO-SW.
           MOVE   '0001'             TO  ARCHIVIO-TRAC.
           MOVE   'UPD'              TO  ARCHIVIO-FUNZ.
           CALL 'RADYDBRI'    USING AREA-ARCHIVIO.
           IF ARCHIVIO-SW NOT= 'SI'
              MOVE '0004'                   TO ERR-PUNTO
              MOVE SPACES                   TO ERR-DESCRIZIONE
              MOVE 'ERRORE RADYDBRI'        TO ERR-DESCRIZIONE
              MOVE ARCHIVIO-RETCODE         TO ERR-CODICE-X
              MOVE 'SI'                     TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
           END-IF.
       AGGIORNA-RICHIESTA-EX.
           EXIT.

      *----------------------------------------------------------------*
       LEGGI-CALENDARIO.
           INITIALIZE    AREA-ARCHIVIO    RADCDCAL-REC
           MOVE   'SI'               TO     ARCHIVIO-SW.
           MOVE   '0001'             TO     ARCHIVIO-TRAC.
           MOVE   'RED'              TO     ARCHIVIO-FUNZ.
           MOVE BRIC-PB02-ANNORIF    TO     CALE-ID-CALE
           MOVE BRIC-PB02-DATA-ESTR  TO     CALE-DATA-ESTR
           MOVE RADCDCAL-REC         TO    ARCHIVIO-REC
           CALL 'RADYDCAL'    USING AREA-ARCHIVIO.

           DISPLAY '----------------------------------'
           DISPLAY 'DATA DI RICERCA IN TABELLA RADCALE'
           DISPLAY 'ID-CALE '   CALE-ID-CALE
           DISPLAY 'DATA-ESTR ' CALE-DATA-ESTR
           DISPLAY '----------------------------------'
           DISPLAY '                                  '
           DISPLAY 'RETURN CODE ' ARCHIVIO-RETCODE
           DISPLAY '----------------------------------'


           IF ARCHIVIO-SW NOT= 'SI'
              MOVE '0001'                   TO ERR-PUNTO
              MOVE SPACES                   TO ERR-DESCRIZIONE
              MOVE 'ERRORE RADYDCAL'        TO ERR-DESCRIZIONE
              MOVE ARCHIVIO-RETCODE         TO ERR-CODICE-X
              MOVE 'SI'                     TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
           END-IF.
       LEGGI-CALENDARIO-EX.
           EXIT.
      *
       SALVA-DATI-CALEND.

           MOVE  ARCHIVIO-REC    TO  RADCDCAL-REC
           MOVE  RADCDCAL-REC    TO  SAVE-RADCDCAL-REC.

       SALVA-DATI-CALEND-EX.
           EXIT.

       CURR-PROGR-CALES.
           INITIALIZE AREA-ARCHIVIO   RADCDCAS-REC
           MOVE   'SI'         TO     ARCHIVIO-SW.
           MOVE   '0002'       TO     ARCHIVIO-TRAC.
           MOVE   'MAX'        TO     ARCHIVIO-FUNZ.
           MOVE CALE-ID-CALE   TO     CALES-ID-CALE
           MOVE CALE-DATA-ESTR TO     CALES-DATA-ESTR
           MOVE RADCDCAS-REC   TO     ARCHIVIO-REC.
           CALL 'RADYDCAS'    USING   AREA-ARCHIVIO.
           IF ARCHIVIO-SW NOT= 'SI'
              MOVE '0008'                   TO ERR-PUNTO
              MOVE SPACES                   TO ERR-DESCRIZIONE
              MOVE 'ERRORE RADYDCAS'        TO ERR-DESCRIZIONE
              MOVE ARCHIVIO-RETCODE         TO ERR-CODICE-X
              MOVE 'SI'                     TO ERR-GRAVE
              MOVE ARCHIVIO-RETCODE         TO ERR-CODICE-X
              MOVE 'SI'                     TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
           END-IF.
       CURR-PROGR-CALES-EX.
           EXIT.
      *
       NEW-PROGR-CALES.
           MOVE  ARCHIVIO-REC    TO  RADCDCAS-REC
           INITIALIZE WS-PROGR-CALES
           MOVE  CALES-PROGR   TO   WS-PROGR-CALES
           ADD  1   TO  WS-PROGR-CALES.
       NEW-PROGR-CALES-EX.
           EXIT.
      *
       INS-CALES.
           INITIALIZE   AREA-ARCHIVIO RADCDCAS-REC

           MOVE   CALE-ID-CALE       TO  CALES-ID-CALE
           MOVE   CALE-DATA-ESTR     TO  CALES-DATA-ESTR
           MOVE   CALE-STATO         TO  CALES-STATO
           MOVE   CALE-DATAIMM       TO  CALES-DATAIMM
           MOVE   CALE-ORAIMM        TO  CALES-ORAIMM
           MOVE   CALE-TERMIMM       TO  CALES-TERMIMM
           MOVE   CALE-COPERIM       TO  CALES-COPERIM
           MOVE   CALE-AUTORIM       TO  CALES-AUTORIM
           MOVE   CALE-DIPEIMM       TO  CALES-DIPEIMM
           MOVE   CALE-DATAANN       TO  CALES-DATAANN
           MOVE   CALE-ORAANN        TO  CALES-ORAANN
           MOVE   CALE-TERMANN       TO  CALES-TERMANN
           MOVE   CALE-COPERAN       TO  CALES-COPERAN
           MOVE   CALE-AUTORAN       TO  CALES-AUTORAN
           MOVE   CALE-DIPEANN       TO  CALES-DIPEANN

           MOVE WS-PROGR-CALES       TO  CALES-PROGR
           MOVE WS-CURRENT-DATE      TO  CALES-DATAANN
           MOVE WS-CURRENT-TIME(1:6) TO  CALES-ORAANN
           MOVE  'SIRADO'            TO  CALES-TERMANN
           MOVE  'BATCH'             TO  CALES-COPERAN
           MOVE  '55974'             TO  CALES-DIPEANN
           MOVE   'SI'               TO  ARCHIVIO-SW.
           MOVE   'WRT'              TO  ARCHIVIO-FUNZ.

           MOVE  RADCDCAS-REC        TO  ARCHIVIO-REC
           CALL 'RADYDCAS'    USING AREA-ARCHIVIO.
           IF ARCHIVIO-SW NOT= 'SI'
              MOVE '0005'                   TO ERR-PUNTO
              MOVE SPACES                   TO ERR-DESCRIZIONE
              MOVE 'ERRORE RADYDCAS'        TO ERR-DESCRIZIONE
              MOVE ARCHIVIO-RETCODE         TO ERR-CODICE-X
              MOVE 'SI'                     TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
           END-IF.
       INS-CALES-EX.
           EXIT.

       UPD-CALE.
           INITIALIZE   AREA-ARCHIVIO
           MOVE    SAVE-RADCDCAL-REC   TO    RADCDCAL-REC
           EVALUATE APPL-NAME   ALSO CALE-STATO
              WHEN 'INFO'  ALSO  'IR'      MOVE  'IC'   TO  CALE-STATO
              WHEN 'DISP'  ALSO  'DR'      MOVE  'DC'   TO  CALE-STATO
              WHEN OTHER
                   MOVE '0007'                   TO ERR-PUNTO
                   MOVE SPACES                   TO ERR-DESCRIZIONE
                   MOVE 'INCOERENZA CALENDARIO'  TO ERR-DESCRIZIONE
                   MOVE ARCHIVIO-RETCODE         TO ERR-CODICE-X
                   MOVE 'SI'                     TO ERR-GRAVE
                   PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
           END-EVALUATE
           MOVE WS-CURRENT-DATE      TO  CALE-DATAIMM
           MOVE WS-CURRENT-TIME(1:6) TO  CALE-ORAIMM
           MOVE  'SIRADO'            TO  CALE-TERMIMM
           MOVE  'BATCH'             TO  CALE-COPERIM
           MOVE  '55974'             TO  CALE-DIPEIMM
           MOVE  RADCDCAL-REC        TO  ARCHIVIO-REC
           MOVE   'SI'               TO  ARCHIVIO-SW.
           MOVE   '0001'             TO  ARCHIVIO-TRAC.
           MOVE   'UPD'              TO  ARCHIVIO-FUNZ.
           CALL 'RADYDCAL'    USING AREA-ARCHIVIO.
           IF ARCHIVIO-SW NOT= 'SI'
              MOVE '0009'                   TO ERR-PUNTO
              MOVE SPACES                   TO ERR-DESCRIZIONE
              MOVE 'ERRORE RADYDCAL'        TO ERR-DESCRIZIONE
              MOVE ARCHIVIO-RETCODE         TO ERR-CODICE-X
              MOVE 'SI'                     TO ERR-GRAVE
              PERFORM GESTIONE-ERRORE     THRU GESTIONE-ERRORE-EX
           END-IF.
       UPD-CALE-EX.
           EXIT.
      *
      *
       FINE.
           STOP RUN.
       FINE-EX.
           EXIT.
      *
      *================================================================*
       GESTIONE-ERRORE.
      *================================================================*
           DISPLAY '*==============================================*'.
           DISPLAY '*====             ERRORE GRAVE             ====*'
           DISPLAY '*====--------------------------------------====*'.
           DISPLAY '*====   PUNTO        : ' ERR-PUNTO.
           DISPLAY '*====   DESCRIZIONE  : ' ERR-DESCRIZIONE.
           DISPLAY '*====   CODICE X     : ' ERR-CODICE-X.
           DISPLAY '*====   CODICE 9     : ' ERR-CODICE-Z.
           DISPLAY '*====--------------------------------------====*'.
           DISPLAY '*====             ERRORE GRAVE             ====*'
           DISPLAY '*==============================================*'.
           CALL 'RADYROLL'
           MOVE 12 TO RETURN-CODE.
           STOP RUN.
       GESTIONE-ERRORE-EX.
           EXIT.

