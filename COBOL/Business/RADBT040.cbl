      *================================================================*
FM0318* ESCLUSI DALLA ELABORAZIONE I RAPPORTI CON COPERI = 'BATCH4'    *
FM0318* QUESTI RAPPORTI SARANNO ELABORATI NEL RADBT066 CHE GESTISCE    *
FM0318* LA RIPETIZIONE DELLE ESTINZIONI                                *
      *================================================================*
      *================================================================*
      *    D E S C R I Z I O N E   E L A B O R A Z I O N E             *
      *================================================================*
      * ESTINZIONE DORMIENTI - RICHIESTE ESTINZIONI DA TP AI PARTITARI *
      *================================================================*
      *    S E Q U E N Z I A L I  (INPUT)                              *
      *================================================================*
      * IFILREST : DESCRIZIONE : TABELLA RICHIESTE DI ESTINZIONE       *
      *            LUNGHEZZA   : 159                                   *
      *            WORKING     : RADFDRES                              *
      *                                                                *
      * IFILRADO : DESCRIZIONE : TABELLA RAPPORTI DORMIENTI            *
      *            LUNGHEZZA   : 326                                   *
      *            WORKING     : RADFDRAD                              *
      *                                                                *
      *================================================================*
      *    S E Q U E N Z I A L I  (OUTPUT)                             *
      *================================================================*
      * OFILRADO : DESCRIZIONE : FLUSSO RAPPORTI DORMIENTI             *
      *            LUNGHEZZA   : 326                                   *
      *            WORKING     : RADFDRAD                              *
      *                                                                *
      * OFILLOGA : DESCRIZIONE : LOG ANOMALIE LOGICHE                  *
      *            LUNGHEZZA   : 150                                   *
      *            WORKING     : RADCLOGA                              *
      *                                                                *
      * OFILREST : DESCRIZIONE : TABELLA RICHIESE ESTINZIONI DORMIENTI *
      *            LUNGHEZZA   : 159                                   *
      *            WORKING     : RADFDRES                              *
      *                                                                *
      * OFILRICC : DESCRIZIONE : RICHIESTE DI ESTINZ. AL PARTITARIO CC *
      *            LUNGHEZZA   : 080                                   *
      *            WORKING     : RADCRICC                              *
      *                                                                *
      * OFILRIDR : DESCRIZIONE : RICHIESTE DI ESTINZ. AL PARTITARIO DR *
      *            LUNGHEZZA   : 030                                   *
      *            WORKING     : RADCRIDR                              *
      *                                                                *
      * OFILRIDT : DESCRIZIONE : RICHIESTE DI ESTINZ. AL PARTITARIO DT *
      *            LUNGHEZZA   : 030                                   *
      *            WORKING     : RADCRIDT                              *
      *================================================================*
      *    I D E N T I F I C A T I O N   D I V I S I O N               *
      *================================================================*
       IDENTIFICATION DIVISION.
      *================================================================*
       PROGRAM-ID. RADBT040.
       AUTHOR.
      *================================================================*
      *    E N V I R O N M E N T   D I V I S I O N                     *
      *================================================================*
       ENVIRONMENT DIVISION.
      *================================================================*
      *    C O N F I G U R A T I O N   S E C T I O N                   *
      *================================================================*
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *================================================================*
      *    I N P U T - O U T P U T   S E C T I O N                     *
      *================================================================*
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *
           SELECT  IFILREST       ASSIGN    TO IFILREST
                                  FILE STATUS IS FS-IFILREST.
      *
           SELECT  IFILRADO       ASSIGN    TO IFILRADO
                                  FILE STATUS IS FS-IFILRADO.
      *
           SELECT  OFILRADO       ASSIGN    TO OFILRADO
                                  FILE STATUS IS FS-OFILRADO.
      *
           SELECT  OFILREST       ASSIGN    TO OFILREST
                                  FILE STATUS IS FS-OFILREST.
      *
           SELECT  OFILRICC       ASSIGN    TO OFILRICC
                                  FILE STATUS IS FS-OFILRICC.
      *
           SELECT  OFILRIDR       ASSIGN    TO OFILRIDR
                                  FILE STATUS IS FS-OFILRIDR.
      *
           SELECT  OFILRIDT       ASSIGN    TO OFILRIDT
                                  FILE STATUS IS FS-OFILRIDT.
      *
           SELECT  OFILLOGA       ASSIGN    TO OFILLOGA
                                  FILE STATUS IS FS-OFILLOGA.
      *================================================================*
      *    D A T A   D I V I S I O N                                   *
      *================================================================*
       DATA DIVISION.
      *================================================================*
      *    F I L E   S E C T I O N                                     *
      *================================================================*
       FILE SECTION.
      *
       FD  IFILRADO
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-IFILRADO                  PIC  X(0326).
      *
       FD  IFILREST
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-IFILREST                  PIC  X(0159).
      *
       FD  OFILRADO
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILRADO                  PIC  X(0326).
      *
       FD  OFILREST
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILREST                  PIC  X(0159).
      *
       FD  OFILRICC
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILRICC                  PIC  X(0080).
      *
       FD  OFILRIDR
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILRIDR                  PIC  X(0030).
      *
       FD  OFILRIDT
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILRIDT                  PIC  X(0030).
      *
       FD  OFILLOGA
           LABEL RECORD STANDARD BLOCK 0 RECORDS RECORDING MODE IS F.
       01  REC-OFILLOGA                  PIC  X(0150).
      *================================================================*
      *    W O R K I N G - S T O R A G E   S E C T I O N               *
      *================================================================*
       WORKING-STORAGE SECTION.
      *================================================================*
      *    AREA DI COMODO PER ELABORAZIONE PROGRAMMA                   *
      *================================================================*
       01  SW-TROVATO-REST               PIC X(02) VALUE SPACES.
       01  SW-TROVATO-RADO               PIC X(02) VALUE SPACES.
       01  SW-RICERCA-REST               PIC 9(01) VALUE ZEROES.
       01  SW-LOGA                       PIC X(02) VALUE SPACES.
       01  SW-AGG-RADO                   PIC X(02) VALUE SPACES.


       01  CAMPI-COMODO.
           05  SWITCH.
               10  FINE-ELABORA          PIC  X(0002).
                   88  FINE-ELABORA-SI                 VALUE 'SI'.
           05  CONTATORI.
               10  TOT-RICHIESTE-RIPET           PIC S9(0018)  COMP-3.
               10  TOT-RICHIESTE-TP-TOTALI       PIC S9(0018)  COMP-3.
               10  TOT-RICHIESTE-TP-UTENTE       PIC S9(0018)  COMP-3.
               10  TOT-RICHIESTE-TP-RIE          PIC S9(0018)  COMP-3.
               10  TOT-NON-TROVATI-RADREST       PIC S9(0018)  COMP-3.
               10  TOT-RED-IFILRADO              PIC S9(0018)  COMP-3.
               10  TOT-AGG-IFILRADO              PIC S9(0018)  COMP-3.
               10  TOT-AGG-IFILREST              PIC S9(0018)  COMP-3.
               10  TOT-RED-IFILREST              PIC S9(0018)  COMP-3.
               10  TOT-WRT-OFILRADO              PIC S9(0018)  COMP-3.
               10  TOT-WRT-OFILREST              PIC S9(0018)  COMP-3.
               10  TOT-WRT-OFILLOGA              PIC S9(0018)  COMP-3.
               10  TOT-WRT-OFILRICC              PIC S9(0018)  COMP-3.
               10  TOT-WRT-OFILRIDR              PIC S9(0018)  COMP-3.
               10  TOT-WRT-OFILRIDT              PIC S9(0018)  COMP-3.
           05  WS-PIC04-9                PIC  9(04).
           05  WS-PIC04-X       REDEFINES
               WS-PIC04-9                PIC  X(04).
           05  WS-PIC12-9                PIC  9(12).
           05  WS-PIC12-X       REDEFINES
               WS-PIC12-9                PIC  X(12).
           05  WK-SYSIN-DATA             PIC  9(08).
           05  WK-SYSIN-DATA-R  REDEFINES
               WK-SYSIN-DATA             PIC  X(08).
           05  NOMEPGM                   PIC  X(8)  VALUE SPACES.

           05  WK-DATASYS.
             07  DATASYS-SEC        PIC 9(2)  VALUE ZERO.
             07  DATASYS-AAMMGG.
               10  DATASYS-AA       PIC 9(2)  VALUE ZERO.
               10  DATASYS-MM       PIC 9(2)  VALUE ZERO.
               10  DATASYS-GG       PIC 9(2)  VALUE ZERO.
           05  WK-ORASYS.
             07  ORASYS-HH          PIC 9(2)  VALUE ZERO.
             07  ORASYS-MM          PIC 9(2)  VALUE ZERO.
             07  ORASYS-SS          PIC 9(2)  VALUE ZERO.

           05  CAMPI-EDIT             OCCURS  30.
               10  NUM-EDIT              PIC  ---.---.---.--9.
           05  CAMPI-TIMEDATE.
               10  WKS-DATE-SIS.
                   15  WKS-AA            PIC  9(0002).
                   15  WKS-MM            PIC  9(0002).
                   15  WKS-GG            PIC  9(0002).
               10  WKS-TIME-SIS.
                   15  WKS-ORA           PIC  9(0002).
                   15  WKS-MIN           PIC  9(0002).
                   15  WKS-SEC           PIC  9(0002).
               10  DIS-DATE.
                   15  DIS-GG            PIC  9(0002).
                   15  FILL-DT1          PIC  X(0001).
                   15  DIS-MM            PIC  9(0002).
                   15  FILL-DT2          PIC  X(0001).
                   15  DIS-AA.
                       20  DIS-AA-1      PIC  9(0002).
                       20  DIS-AA-2      PIC  9(0002).
               10  DIS-TIME.
                   15  DIS-ORA           PIC  9(0002).
                   15  FILL-TM1          PIC  X(0001).
                   15  DIS-MIN           PIC  9(0002).
                   15  FILL-TM2          PIC  X(0001).
                   15  DIS-SEC           PIC  9(0002).
               10  DIS-DATE-INI          PIC  X(0010).
               10  DIS-TIME-INI          PIC  X(0008).
           05  CAMPI-ERRORE.
               10  ERR-PROGRAMMA         PIC  X(0008).
               10  ERR-PUNTO             PIC  X(0004).
               10  ERR-DESCRIZIONE       PIC  X(0080).
               10  ERR-CODICE-X          PIC  X(0006).
               10  ERR-CODICE-Z          PIC  -----9.
               10  ERR-DATI              PIC  X(0030).
               10  ERR-GRAVE             PIC  X(0002).
      *================================================================*
      *    AREE DI COMODO PER GESTIONE STATUS DEI FILE                 *
      *================================================================*
       01  STATUS-FILE.
      *
           05  STATUS-IFILRADO.
               10  FS-IFILRADO           PIC  X(0002).
                   88  FS-IFILRADO-OK                  VALUE '00'.
                   88  FS-IFILRADO-FF                  VALUE '10'.
               10  EF-IFILRADO           PIC  X(0002).
                   88  EF-IFILRADO-SI                  VALUE 'SI'.
                   88  EF-IFILRADO-NO                  VALUE 'NO'.
      *
           05  STATUS-IFILREST.
               10  FS-IFILREST           PIC  X(0002).
                   88  FS-IFILREST-OK                  VALUE '00'.
                   88  FS-IFILREST-FF                  VALUE '10'.
               10  EF-IFILREST           PIC  X(0002).
                   88  EF-IFILREST-SI                  VALUE 'SI'.
                   88  EF-IFILREST-NO                  VALUE 'NO'.
      *
           05  STATUS-OFILRADO.
               10  FS-OFILRADO           PIC  X(0002).
                   88  FS-OFILRADO-OK                  VALUE '00'.
      *
           05  STATUS-OFILLOGA.
               10  FS-OFILLOGA           PIC  X(0002).
                   88  FS-OFILLOGA-OK                  VALUE '00'.
      *
           05  STATUS-OFILREST.
               10  FS-OFILREST           PIC  X(0002).
                   88  FS-OFILREST-OK                  VALUE '00'.
      *
           05  STATUS-OFILRICC.
               10  FS-OFILRICC           PIC  X(0002).
                   88  FS-OFILRICC-OK                  VALUE '00'.
      *
           05  STATUS-OFILRIDR.
               10  FS-OFILRIDR           PIC  X(0002).
                   88  FS-OFILRIDR-OK                  VALUE '00'.
      *
           05  STATUS-OFILRIDT.
               10  FS-OFILRIDT           PIC  X(0002).
                   88  FS-OFILRIDT-OK                  VALUE '00'.
      *
       01  WKS-DATACALC.
           05 WKS-DATCAL                 PIC  9(0008).
      *
       01  WKS-DATAOPC.
           05 WKS-DATOPC                 PIC  9(0008).

       01  WKS-DATFINE                   PIC  9(0008).
      *
       01  WKS-APPO-DATASYS              PIC X(08).
       01  WKS-APPO-DATASYS-R            REDEFINES
           WKS-APPO-DATASYS              PIC 9(08).

       01  WKS-DESC-LOGA                 PIC X(50).
       01  WKS-RAPPORT-APPO              PIC 9(12).
      *================================================================*
      *    AREE DI COMODO PER GESTIONE RAPPORTI DORMIENTI              *
      *================================================================*
       01  WKS-RADOKEY.
           05 WKS-TIPSERV-RADO           PIC  X(0002).
           05 WKS-RAPPORT-RADO           PIC  9(0012).
      *================================================================*
      *    AREE DI COMODO PER GESTIONE DELLE RACCOMANDATE              *
      *================================================================*
       01  WKS-RESTKEY.
           05 WKS-TIPSERV-REST           PIC  X(0002).
           05 WKS-RAPPORT-REST           PIC  9(0012).
      *================================================================*
      *    AREE DI COMODO PER GESTIONE IFILCEPO                        *
      *================================================================*
           COPY RADFDRES.
           COPY RADFDRAD.
           COPY RADCLOGA.
           COPY RADCRICC.
           COPY RADCRIDR.
           COPY RADCRIDT.
      *================================================================*
      * AREE PER ROUTINE ANAGRAFICA
      *================================================================*
       01  ACS108BT                 PIC X(08) VALUE 'ACS108BT'.
       01  L-ACS108-01.
           COPY ACS108A.
      *================================================================*
      *    AREE DI COMODO PER GESTIONE                                 *
      *================================================================*
       01  WKS-OUT-RADO                 PIC X(0326).
       01  WKS-OUT-LOGA                 PIC X(0150).
       01  WKS-OUT-REST                 PIC X(0159).
       01  WKS-OUT-RICE                 PIC X(0056).
      *================================================================*
      *    L I N K A G E   S E C T I O N                               *
      *================================================================*
       LINKAGE SECTION.
      *================================================================*
      *    P R O C E D U R E   D I V I S I O N                         *
      *================================================================*
       PROCEDURE DIVISION.
      *================================================================*
      *    M A I N                                                     *
      *================================================================*
       INIZIO-MAIN.

           PERFORM INIZIO                     THRU INIZIO-EX.

           PERFORM ELABORA                    THRU ELABORA-EX
                   UNTIL EF-IFILRADO-SI.

           PERFORM GESTIONE-FINE-REST        THRU GESTIONE-FINE-REST-EX
                   UNTIL EF-IFILREST-SI.

           PERFORM FINE                       THRU FINE-EX.

       FINE-MAIN.
           STOP RUN.
      *================================================================*
      *                                                                *
      *    E L A B O R A Z I O N E   P R I N C I P A L E               *
      *                                                                *
      *================================================================*
       ELABORA.
      *================================================================*

           MOVE    'NO'                 TO   SW-TROVATO-REST
           MOVE    'NO'                 TO   SW-TROVATO-RADO.
           MOVE    'NO'                 TO   SW-LOGA.
           MOVE    'SI'                 TO   SW-AGG-RADO.
           MOVE      0                  TO   SW-RICERCA-REST.
           MOVE    SPACES               TO   WKS-DESC-LOGA.

           PERFORM TRATTA-RICHIESTE-DATP    THRU
                   TRATTA-RICHIESTE-DATP-EX

           PERFORM SCRIVI-OFILRADO            THRU SCRIVI-OFILRADO-EX
           PERFORM READ-IFILRADO              THRU READ-IFILRADO-EX
           .

       ELABORA-EX.
           EXIT.
      *================================================================*
      *   INIZIALIZZAZIONE AREE E ACCEPT DEI DATI DI SISTEMA E DATA OPC
      *================================================================*
       INIZIO.

           PERFORM INIZIALIZZA                THRU INIZIALIZZA-EX.
           MOVE 'RADBT040'                      TO NOMEPGM.
           PERFORM ACCEPT-TIMEDATE            THRU ACCEPT-TIMEDATE-EX.
           MOVE DIS-DATE                        TO DIS-DATE-INI.
           MOVE DIS-TIME                        TO DIS-TIME-INI.

           PERFORM OPEN-IFILRADO              THRU OPEN-IFILRADO-EX.
           PERFORM OPEN-IFILREST              THRU OPEN-IFILREST-EX.
           PERFORM OPEN-OFILRADO              THRU OPEN-OFILRADO-EX.
           PERFORM OPEN-OFILREST              THRU OPEN-OFILREST-EX.
           PERFORM OPEN-OFILLOGA              THRU OPEN-OFILLOGA-EX.
           PERFORM OPEN-OFILRICC              THRU OPEN-OFILRICC-EX.
           PERFORM OPEN-OFILRIDR              THRU OPEN-OFILRIDR-EX.
           PERFORM OPEN-OFILRIDT              THRU OPEN-OFILRIDT-EX.

           PERFORM READ-IFILRADO              THRU READ-IFILRADO-EX.
           PERFORM READ-IFILREST              THRU READ-IFILREST-EX.

       INIZIO-EX.
           EXIT.
      *================================================================*
      * GESTIONE RICHIESTE ESTINZIONI DA SIRADO TP
      *================================================================*
       TRATTA-RICHIESTE-DATP.

           IF  RADRADO-STRAPPO    = '08'    AND
               RADRADO-DTRICES    = ZEROES
FM0319*        RADRADO-COPERI NOT = 'BATCH4'
FM0319         ADD   1    TO   TOT-RICHIESTE-TP-TOTALI
               MOVE   'SI'   TO   SW-TROVATO-RADO
           END-IF.

           IF  SW-TROVATO-RADO  = 'SI'

               PERFORM CERCA-REST           THRU CERCA-REST-EX
                       UNTIL  WKS-RESTKEY > WKS-RADOKEY OR
                       EF-IFILREST-SI

               IF  SW-TROVATO-REST  = 'NO'
                   ADD   1           TO   TOT-NON-TROVATI-RADREST
                   MOVE  'RAPPORTO DA VERIFICARE IN ELABORAZIONE RIE'
                                     TO WKS-DESC-LOGA
                   PERFORM AGGIOR-DATI-LOGA THRU AGGIOR-DATI-LOGA-EX
                   PERFORM SCRIVI-OFILLOGA  THRU SCRIVI-OFILLOGA
               END-IF
           END-IF
           .

       TRATTA-RICHIESTE-DATP-EX.
           EXIT.
      *================================================================*
      * CHIUSURA DEI FILE DI INPUT«OUTPUT
      *================================================================*
       FINE.

           PERFORM CLOSE-IFILRADO            THRU CLOSE-IFILRADO-EX.
           PERFORM CLOSE-IFILREST            THRU CLOSE-IFILREST-EX.
           PERFORM CLOSE-OFILRADO            THRU CLOSE-OFILRADO-EX.
           PERFORM CLOSE-OFILLOGA            THRU CLOSE-OFILLOGA-EX.
           PERFORM CLOSE-OFILREST            THRU CLOSE-OFILREST-EX.
           PERFORM CLOSE-OFILRICC            THRU CLOSE-OFILRICC-EX.
           PERFORM CLOSE-OFILRIDR            THRU CLOSE-OFILRIDR-EX.
           PERFORM CLOSE-OFILRIDT            THRU CLOSE-OFILRIDT-EX.

           PERFORM ACCEPT-TIMEDATE           THRU ACCEPT-TIMEDATE-EX.
           PERFORM STATISTICHE               THRU STATISTICHE-EX.

       FINE-EX.
           EXIT.
      ******************************************************************
      * AGGIORNAMENTO DEGLI ARCHIVI RADREST IN CASO DI ESTINZIONE
      ******************************************************************
       CERCA-REST.
FM0319* A PARITA DI CHIAVE ANALIZZA SOLO LE NUOVE RICHIESTE (DTRICES 0)
FM0319* LE RICHIESTE DA UTENTE (<> BATCH4) VENGONO ELABORATE
FM0319* LE RICHIESTE DA RIPETIZIONE (= BATCH4) VENGONO SCARTATE
           IF WKS-RADOKEY     =  WKS-RESTKEY AND
FM0319        RADREST-DTRICES = 0
FM0319        IF RADREST-COPERI NOT = 'BATCH4'
                 IF  SW-TROVATO-REST =  'NO'
FM0319               ADD   1    TO   TOT-RICHIESTE-TP-UTENTE
                     MOVE  'SI'                 TO   SW-TROVATO-REST
                     PERFORM AGGIOR-DATI-RADO THRU AGGIOR-DATI-RADO-EX
                     PERFORM AGGIOR-DATI-REST THRU AGGIOR-DATI-REST-EX
                     EVALUATE RADRADO-TIPSERV
                       WHEN 'CC'
                         PERFORM IMPOSTA-DATI-RICC
                            THRU IMPOSTA-DATI-RICC-EX
                         PERFORM SCRIVI-OFILRICC
                            THRU SCRIVI-OFILRICC-EX
                       WHEN 'DR'
                         PERFORM IMPOSTA-DATI-RIDR
                            THRU IMPOSTA-DATI-RIDR-EX
                         PERFORM SCRIVI-OFILRIDR
                            THRU SCRIVI-OFILRIDR-EX
                       WHEN 'DT'
                         PERFORM IMPOSTA-DATI-RIDT
                            THRU IMPOSTA-DATI-RIDT-EX
                         PERFORM SCRIVI-OFILRIDT
                            THRU SCRIVI-OFILRIDT-EX
                     END-EVALUATE
                 END-IF
              ELSE
FM0319* AGGIORNA CONTATORE RICHIESTE RIPETIZIONE ESTINZIONE
FM0319* LE RICHIESTE RIE VENGONO LAVORATE NELLA RADO600G
FM0319           ADD   1    TO   TOT-RICHIESTE-TP-RIE
              END-IF
           END-IF.

           PERFORM SCRIVI-OFILREST   THRU SCRIVI-OFILREST-EX
           PERFORM READ-IFILREST     THRU READ-IFILREST-EX
           .

       CERCA-REST-EX.
             EXIT.
      ******************************************************************
      * AGGIORNAMENTO ARCHIVIO RADRADO                                 *
      ******************************************************************
       AGGIOR-DATI-RADO.

           ADD   1                  TO    TOT-AGG-IFILRADO
           MOVE  WK-SYSIN-DATA      TO    RADRADO-DTRICES
           .

       AGGIOR-DATI-RADO-EX.
           EXIT.
      ******************************************************************
      * AGGIORNAMENTO ARCHIVIO RADREST                                 *
      ******************************************************************
       AGGIOR-DATI-REST.

           ADD   1                  TO     TOT-AGG-IFILREST
           MOVE  WK-SYSIN-DATA      TO     RADREST-DTRICES
           .

       AGGIOR-DATI-REST-EX.
           EXIT.
      *================================================================*
      * AGGIORNAMENTO ARCHIVIO LOG ANOMALIE                            *
      *================================================================*
       AGGIOR-DATI-LOGA.

           MOVE  WKS-RADOKEY        TO    LOGA-KEY
           MOVE  WK-SYSIN-DATA      TO    LOGA-DATAELAB

           MOVE 'RICHIESTE ESTINZIONI TP'  TO LOGA-FASE

           MOVE NOMEPGM             TO    LOGA-PROGRAMMA

           MOVE WKS-DESC-LOGA       TO   LOGA-DESCANOM

           .

       AGGIOR-DATI-LOGA-EX.
           EXIT.
      *================================================================*
      * AGGIORNAMENTO FLUSSO RICHIESTE DI ESTINZIONE CC                *
      *================================================================*
       IMPOSTA-DATI-RICC.
           MOVE RADRADO-FILIALE     TO RICC-FILIALE.
           MOVE RADRADO-RAPPORT     TO WS-PIC12-9.
           MOVE WS-PIC12-X          TO RICC-RAPPORT.
           MOVE RADRADO-CATRAPP     TO RICC-CATRAPP.
           MOVE 'ST'                TO RICC-GRCOND.
           MOVE 'S'                 TO RICC-ANA
                                       RICC-TIT
                                       RICC-POV
                                       RICC-CSA
                                       RICC-RAPP
                                       RICC-CARTE
                                       RICC-BOLLI
                                       RICC-SCO
                                       RICC-FONDI
                                       RICC-POD
                                       RICC-BUO
                                       RICC-FATEL
                                       RICC-DOGE.
           MOVE 'N'      TO            RICC-AGOS
           PERFORM CHIAMA-ANAG      THRU CHIAMA-ANAG-EX.
           MOVE L-ACS108-CIAE       TO WS-PIC04-9.
           MOVE WS-PIC04-X          TO RICC-CIAE.
           MOVE 'SIRADO'            TO RICC-SERV.
           MOVE '03'                TO RICC-TIPOELAB.
       IMPOSTA-DATI-RICC-EX.
           EXIT.
      *================================================================*
      * CHIAMA ROUTINEANAGRAFICA
      *================================================================*
       CHIAMA-ANAG.
           INITIALIZE L-ACS108-ARG.
           MOVE ' '                      TO L-ACS108-I-TIPO-RICH.
           MOVE RADRADO-TIPSERV          TO L-ACS108-I-SERVIZIO.
           MOVE RADRADO-FILIALE          TO L-ACS108-I-FILIALE.
           MOVE RADRADO-RAPPORT          TO L-ACS108-I-NUMERO.
           MOVE RADRADO-CATRAPP          TO L-ACS108-I-CATEGORIA.
           CALL ACS108BT USING L-ACS108-01.
           IF L-ACS108-RET-CODE = ZEROES
              CONTINUE
           ELSE
              INITIALIZE CAMPI-ERRORE
              IF (L-ACS108-RET-CODE = 2 OR 5)
                 MOVE '0010'             TO ERR-PUNTO
                 STRING 'RAPPORTO INESISTENTE IN ANAGRAFE: '
                        L-ACS108-I-NUMERO
                   DELIMITED BY SIZE   INTO ERR-DESCRIZIONE
              ELSE
                 MOVE '0011'             TO ERR-PUNTO
                 MOVE 'ERRORE ROUTINE ACS108BT ACCESSO ANAGRAFE'
                                         TO ERR-DESCRIZIONE
              END-IF
              MOVE L-ACS108-RET-CODE     TO ERR-CODICE-Z
              MOVE SPACES                TO ERR-DATI
              PERFORM ERRORE           THRU ERRORE-EX
              PERFORM CHIUSURA-FORZATA
           END-IF.
       CHIAMA-ANAG-EX.
           EXIT.
      *================================================================*
      * AGGIORNAMENTO FLUSSO RICHIESTE DI ESTINZIONE DR                *
      *================================================================*
       IMPOSTA-DATI-RIDR.
           MOVE '01'                TO RIDR-ISTITUT.
           MOVE RADRADO-TIPSERV     TO RIDR-TIPSERV.
           MOVE RADRADO-FILIALE     TO RIDR-FILIALE.
           MOVE RADRADO-RAPPORT     TO WS-PIC12-9.
           MOVE WS-PIC12-X          TO RIDR-RAPPORT.
           MOVE RADRADO-CATRAPP     TO RIDR-CATRAPP.
           MOVE SPACES              TO RIDR-FILLER.
       IMPOSTA-DATI-RIDR-EX.
           EXIT.
      *================================================================*
      * AGGIORNAMENTO FLUSSO RICHIESTE DI ESTINZIONE DT                *
      *================================================================*
       IMPOSTA-DATI-RIDT.
           MOVE '01'                TO RIDT-ISTITUT.
           MOVE RADRADO-TIPSERV     TO RIDT-TIPSERV.
           MOVE RADRADO-FILIALE     TO RIDT-FILIALE.
           MOVE RADRADO-RAPPORT     TO WS-PIC12-9.
           MOVE WS-PIC12-X          TO RIDT-RAPPORT.
           MOVE RADRADO-CATRAPP     TO RIDT-CATRAPP.
           MOVE SPACES              TO RIDT-FILLER.
       IMPOSTA-DATI-RIDT-EX.
           EXIT.
      ******************************************************************
      * GESTIONE FINE FILE RAPPORTI ESTINTI                            *
      ******************************************************************
       GESTIONE-FINE-REST.

           PERFORM SCRIVI-OFILREST   THRU SCRIVI-OFILREST-EX.
           PERFORM READ-IFILREST     THRU READ-IFILREST-EX.

       GESTIONE-FINE-REST-EX.
           EXIT.
      *================================================================*
      * SCRITTURA DELL'ARCHIVIO RADRADO                                *
      *================================================================*
       SCRIVI-OFILRADO.

           MOVE RADRADO-RECF            TO REC-OFILRADO
           PERFORM WRITE-OFILRADO     THRU WRITE-OFILRADO-EX
           .

       SCRIVI-OFILRADO-EX.
           EXIT.
      *================================================================*
      * SCRITTURA DELL'ARCHIVIO RADRADO                                *
      *================================================================*
       SCRIVI-OFILLOGA.

           MOVE RADSLOGA-REC             TO REC-OFILLOGA
           PERFORM WRITE-OFILLOGA     THRU WRITE-OFILLOGA-EX
           .

       SCRIVI-OFILLOGA-EX.
           EXIT.
      *================================================================*
      * SCRITTURA DELL'ARCHIVIO RADREST                                *
      *================================================================*
       SCRIVI-OFILREST.

           MOVE RADREST-RECF            TO REC-OFILREST
           PERFORM WRITE-OFILREST     THRU WRITE-OFILREST-EX
           .

       SCRIVI-OFILREST-EX.
           EXIT.
      *================================================================*
      * SCRITTURA FLUSSO RICHIESTE DI ESTINZIONE PER PARTITARIO CC     *
      *================================================================*
       SCRIVI-OFILRICC.
           MOVE RADCRICC-REC            TO REC-OFILRICC.
           PERFORM WRITE-OFILRICC     THRU WRITE-OFILRICC-EX.
       SCRIVI-OFILRICC-EX.
           EXIT.
      *================================================================*
      * SCRITTURA FLUSSO RICHIESTE DI ESTINZIONE PER PARTITARIO DR     *
      *================================================================*
       SCRIVI-OFILRIDR.
           MOVE RADCRIDR-REC            TO REC-OFILRIDR.
           PERFORM WRITE-OFILRIDR     THRU WRITE-OFILRIDR-EX.
       SCRIVI-OFILRIDR-EX.
           EXIT.
      *================================================================*
      * SCRITTURA FLUSSO RICHIESTE DI ESTINZIONE PER PARTITARIO DT     *
      *================================================================*
       SCRIVI-OFILRIDT.
           MOVE RADCRIDT-REC            TO REC-OFILRIDT.
           PERFORM WRITE-OFILRIDT     THRU WRITE-OFILRIDT-EX.
       SCRIVI-OFILRIDT-EX.
           EXIT.
      *================================================================*
       INIZIALIZZA.
      *================================================================*
           INITIALIZE                              CAMPI-COMODO.
           INITIALIZE                              CAMPI-ERRORE.
           INITIALIZE                              STATUS-FILE.
      *
           MOVE 'NO'                            TO EF-IFILRADO.
           MOVE 'NO'                            TO EF-IFILREST.
           MOVE 'NO'                            TO FINE-ELABORA.
      *
           MOVE 'RADBT040'                      TO ERR-PROGRAMMA.

       INIZIALIZZA-EX.
           EXIT.
      *================================================================*
       ACCEPT-TIMEDATE.
      *================================================================*
           ACCEPT WKS-TIME-SIS FROM TIME.
           MOVE WKS-ORA                         TO DIS-ORA
FF1008                                             ORASYS-HH.
           MOVE WKS-MIN                         TO DIS-MIN
FF1008                                             ORASYS-MM.
           MOVE WKS-SEC                         TO DIS-SEC
FF1008                                             ORASYS-SS.
           MOVE ':'                             TO FILL-TM1.
           MOVE ':'                             TO FILL-TM2.
      *
           ACCEPT WKS-DATE-SIS FROM DATE.
           MOVE 20                              TO DIS-AA-1
FF1008                                             DATASYS-SEC.
           MOVE WKS-AA                          TO DIS-AA-2
                                                   DATASYS-AA.
           MOVE WKS-MM                          TO DIS-MM
                                                   DATASYS-MM.
           MOVE WKS-GG                          TO DIS-GG
                                                   DATASYS-GG.
           MOVE '-'                             TO FILL-DT1.
           MOVE '-'                             TO FILL-DT2.

           ACCEPT  WK-SYSIN-DATA              FROM SYSIN.

       ACCEPT-TIMEDATE-EX.
           EXIT.
      *================================================================*
       STATISTICHE.
      *================================================================*
           MOVE TOT-RED-IFILRADO                     TO NUM-EDIT(01).
           MOVE TOT-RICHIESTE-TP-TOTALI              TO NUM-EDIT(02).
           MOVE TOT-RICHIESTE-TP-UTENTE              TO NUM-EDIT(14).
           MOVE TOT-RICHIESTE-TP-RIE                 TO NUM-EDIT(15).
           MOVE TOT-RED-IFILREST                     TO NUM-EDIT(03).
           MOVE TOT-AGG-IFILREST                     TO NUM-EDIT(04).
           MOVE TOT-NON-TROVATI-RADREST              TO NUM-EDIT(05).
           MOVE TOT-AGG-IFILRADO                     TO NUM-EDIT(06).
           MOVE TOT-AGG-IFILREST                     TO NUM-EDIT(07).
           MOVE TOT-WRT-OFILRICC                     TO NUM-EDIT(08).
           MOVE TOT-WRT-OFILRIDR                     TO NUM-EDIT(09).
           MOVE TOT-WRT-OFILRIDT                     TO NUM-EDIT(10).
           MOVE TOT-WRT-OFILRADO                     TO NUM-EDIT(11).
           MOVE TOT-WRT-OFILREST                     TO NUM-EDIT(12).
           MOVE TOT-WRT-OFILLOGA                     TO NUM-EDIT(13).
      *


           DISPLAY
           '*======================================================*'.
           DISPLAY
           '*====        INIZIO ELABORAZIONE PROGRAMMA         ====*'.
           DISPLAY
           '*====   ' DIS-DATE-INI  '                      '
                                            DIS-TIME-INI   '   ====*'.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====        FINE   ELABORAZIONE PROGRAMMA         ====*'.
           DISPLAY
           '*====   ' DIS-DATE      '                      '
                                            DIS-TIME       '   ====*'.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY ' LETTI TABELLA RAPPORTI DORMIENTI..: ' NUM-EDIT(01).
           DISPLAY '   RICHIESTE DI NUOVE ESTINZIONI TP: ' NUM-EDIT(02).
           DISPLAY '             DA UTENTE (DRUPD).....: ' NUM-EDIT(14).
           DISPLAY '             DA RIE    (BATCH4)....: ' NUM-EDIT(15).
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY ' LETTI TABELLA RICHIESTE DI ESTINZ.: ' NUM-EDIT(03).
           DISPLAY '       DI CUI RICHIESTE DRUPD......: ' NUM-EDIT(04).
           DISPLAY '       DI CUI RICHIESTE BATCH4.....: ' NUM-EDIT(05).
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY ' RECORD AGGIORNATI RADRADO.........: ' NUM-EDIT(06).
           DISPLAY ' RECORD AGGIORNATI RADREST.........: ' NUM-EDIT(07).
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY ' TOT. SCRITTI RICHIESTE PARTIT. CC.: ' NUM-EDIT(08).
           DISPLAY ' TOT. SCRITTI RICHIESTE PARTIT. DR.: ' NUM-EDIT(09).
           DISPLAY ' TOT. SCRITTI RICHIESTE PARTIT. DT.: ' NUM-EDIT(10).
           DISPLAY ' TOT. SCRITTI TABELLA RADO.........: ' NUM-EDIT(11).
           DISPLAY ' TOT. SCRITTI TABELLA REST.........: ' NUM-EDIT(12).
           DISPLAY ' TOT. SCRITTI LOG ANOMALIE.........: ' NUM-EDIT(13).
           DISPLAY
           '*====----------------------------------------------====*'.
       STATISTICHE-EX.
           EXIT.
      *================================================================*
       OPEN-IFILRADO.
      *================================================================*
           OPEN INPUT  IFILRADO.
           IF   FS-IFILRADO-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0021'                     TO ERR-PUNTO
                MOVE 'OPEN IFILRADO   '         TO ERR-DESCRIZIONE
                MOVE FS-IFILRADO                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       OPEN-IFILRADO-EX.
           EXIT.
      *================================================================*
       OPEN-IFILREST.
      *================================================================*
           OPEN INPUT  IFILREST.
           IF   FS-IFILREST-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0022'                     TO ERR-PUNTO
                MOVE 'OPEN IFILREST   '         TO ERR-DESCRIZIONE
                MOVE FS-IFILREST                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       OPEN-IFILREST-EX.
           EXIT.
      *================================================================*
       OPEN-OFILRADO.
      *================================================================*
           OPEN OUTPUT OFILRADO.
           IF   FS-OFILRADO-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0023'                     TO ERR-PUNTO
                MOVE 'OPEN OFILRADO   '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRADO                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       OPEN-OFILRADO-EX.
           EXIT.
      *================================================================*
       OPEN-OFILLOGA.
      *================================================================*
           OPEN OUTPUT OFILLOGA.
           IF   FS-OFILLOGA-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0024'                     TO ERR-PUNTO
                MOVE 'OPEN OFILLOGA   '         TO ERR-DESCRIZIONE
                MOVE FS-OFILLOGA                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       OPEN-OFILLOGA-EX.
           EXIT.
      *================================================================*
       OPEN-OFILREST.
      *================================================================*
           OPEN OUTPUT OFILREST.
           IF   FS-OFILREST-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0025'                     TO ERR-PUNTO
                MOVE 'OPEN OFILREST   '         TO ERR-DESCRIZIONE
                MOVE FS-OFILREST                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       OPEN-OFILREST-EX.
           EXIT.
      *================================================================*
       OPEN-OFILRICC.
      *================================================================*
           OPEN OUTPUT OFILRICC.
           IF   FS-OFILRICC-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0026'                     TO ERR-PUNTO
                MOVE 'OPEN OFILRICC   '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRICC                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       OPEN-OFILRICC-EX.
           EXIT.
      *================================================================*
       OPEN-OFILRIDR.
      *================================================================*
           OPEN OUTPUT OFILRIDR.
           IF   FS-OFILRIDR-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0027'                     TO ERR-PUNTO
                MOVE 'OPEN OFILRIDR   '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRIDR                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       OPEN-OFILRIDR-EX.
           EXIT.
      *================================================================*
       OPEN-OFILRIDT.
      *================================================================*
           OPEN OUTPUT OFILRIDT.
           IF   FS-OFILRIDT-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0028'                     TO ERR-PUNTO
                MOVE 'OPEN OFILRIDT   '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRIDT                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       OPEN-OFILRIDT-EX.
           EXIT.
      *================================================================*
       CLOSE-IFILRADO.
      *================================================================*
           CLOSE       IFILRADO.
           IF   FS-IFILRADO-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0041'                     TO ERR-PUNTO
                MOVE 'CLOSE IFILRADO  '         TO ERR-DESCRIZIONE
                MOVE FS-IFILRADO                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       CLOSE-IFILRADO-EX.
           EXIT.
      *================================================================*
       CLOSE-IFILREST.
      *================================================================*
           CLOSE       IFILREST.
           IF   FS-IFILREST-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0042'                     TO ERR-PUNTO
                MOVE 'CLOSE IFILREST  '         TO ERR-DESCRIZIONE
                MOVE FS-IFILREST                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.

       CLOSE-IFILREST-EX.
           EXIT.
      *================================================================*
       CLOSE-OFILRADO.
      *================================================================*
           CLOSE       OFILRADO.
           IF   FS-OFILRADO-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0043'                     TO ERR-PUNTO
                MOVE 'CLOSE OFILRADO  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRADO                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       CLOSE-OFILRADO-EX.
           EXIT.
      *================================================================*
       CLOSE-OFILLOGA.
      *================================================================*
           CLOSE       OFILLOGA.
           IF   FS-OFILLOGA-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0044'                     TO ERR-PUNTO
                MOVE 'CLOSE OFILLOGA  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILLOGA                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       CLOSE-OFILLOGA-EX.
           EXIT.
      *================================================================*
       CLOSE-OFILREST.
      *================================================================*
           CLOSE       OFILREST.
           IF   FS-OFILREST-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0045'                     TO ERR-PUNTO
                MOVE 'CLOSE OFILREST  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILREST                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       CLOSE-OFILREST-EX.
           EXIT.
      *================================================================*
       CLOSE-OFILRICC.
      *================================================================*
           CLOSE       OFILRICC.
           IF   FS-OFILRICC-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0046'                     TO ERR-PUNTO
                MOVE 'CLOSE OFILRICC  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRICC                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       CLOSE-OFILRICC-EX.
           EXIT.
      *================================================================*
       CLOSE-OFILRIDR.
      *================================================================*
           CLOSE       OFILRIDR.
           IF   FS-OFILRIDR-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0047'                     TO ERR-PUNTO
                MOVE 'CLOSE OFILRIDR  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRIDR                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       CLOSE-OFILRIDR-EX.
           EXIT.
      *================================================================*
       CLOSE-OFILRIDT.
      *================================================================*
           CLOSE       OFILRIDT.
           IF   FS-OFILRIDT-OK
           THEN NEXT SENTENCE
           ELSE
                MOVE '0048'                     TO ERR-PUNTO
                MOVE 'CLOSE OFILRIDT  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRIDT                TO ERR-CODICE-X
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       CLOSE-OFILRIDT-EX.
           EXIT.
      *================================================================*
       READ-IFILRADO.
      *================================================================*
           READ IFILRADO.
           EVALUATE TRUE
              WHEN FS-IFILRADO-OK
                   ADD 1                     TO TOT-RED-IFILRADO
                   INITIALIZE                   RADRADO-RECF
                   INITIALIZE                   WKS-RADOKEY
                   MOVE REC-IFILRADO         TO RADRADO-RECF
                   MOVE RADRADO-TIPSERV      TO WKS-TIPSERV-RADO
                   MOVE RADRADO-RAPPORT      TO WKS-RAPPORT-RADO

              WHEN FS-IFILRADO-FF
                   MOVE 'SI'                    TO EF-IFILRADO
                   MOVE HIGH-VALUE              TO WKS-RADOKEY

              WHEN OTHER
                   MOVE '0060'                  TO ERR-PUNTO
                   MOVE 'LETTURA IFILRADO'      TO ERR-DESCRIZIONE
                   MOVE FS-IFILRADO             TO ERR-CODICE-X
                   PERFORM ERRORE             THRU ERRORE-EX
                   PERFORM CHIUSURA-FORZATA
           END-EVALUATE.

       READ-IFILRADO-EX.
           EXIT.
      *================================================================*
       READ-IFILREST.
      *================================================================*
           READ IFILREST.
           EVALUATE TRUE
              WHEN FS-IFILREST-OK
                   ADD 1                     TO TOT-RED-IFILREST
                   INITIALIZE                   RADREST-RECF
                   INITIALIZE                   WKS-RESTKEY
                   MOVE REC-IFILREST         TO RADREST-RECF
                   MOVE RADREST-TIPSERV      TO WKS-TIPSERV-REST
                   MOVE RADREST-RAPPORT      TO WKS-RAPPORT-REST

              WHEN FS-IFILREST-FF
                   MOVE 'SI'                    TO EF-IFILREST
                   MOVE HIGH-VALUE              TO WKS-RESTKEY

              WHEN OTHER
                   MOVE '0061'                  TO ERR-PUNTO
                   MOVE 'LETTURA IFILREST'      TO ERR-DESCRIZIONE
                   MOVE FS-IFILREST             TO ERR-CODICE-X
                   PERFORM ERRORE             THRU ERRORE-EX
                   PERFORM CHIUSURA-FORZATA
           END-EVALUATE.

       READ-IFILREST-EX.
           EXIT.
      *================================================================*
       WRITE-OFILREST.
      *================================================================*
           WRITE REC-OFILREST.
           IF   FS-OFILREST-OK
           THEN
                ADD 1                           TO TOT-WRT-OFILREST
           ELSE
                INITIALIZE                         CAMPI-ERRORE
                MOVE '0062'                     TO ERR-PUNTO
                MOVE 'WRITE OFILREST  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILREST                TO ERR-CODICE-X
                MOVE REC-OFILREST               TO ERR-DATI
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       WRITE-OFILREST-EX.
           EXIT.
      *================================================================*
       WRITE-OFILRADO.
      *================================================================*
           WRITE REC-OFILRADO.
           IF   FS-OFILRADO-OK
           THEN
                ADD 1                           TO TOT-WRT-OFILRADO
           ELSE
                INITIALIZE                         CAMPI-ERRORE
                MOVE '0063'                     TO ERR-PUNTO
                MOVE 'WRITE OFILRADO  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRADO                TO ERR-CODICE-X
                MOVE REC-OFILRADO               TO ERR-DATI
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       WRITE-OFILRADO-EX.
           EXIT.
      *================================================================*
       WRITE-OFILLOGA.
      *================================================================*
           WRITE REC-OFILLOGA.
           IF   FS-OFILLOGA-OK
           THEN
                ADD 1                           TO TOT-WRT-OFILLOGA
           ELSE
                INITIALIZE                         CAMPI-ERRORE
                MOVE '0064'                     TO ERR-PUNTO
                MOVE 'WRITE OFILLOGA  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILLOGA                TO ERR-CODICE-X
                MOVE REC-OFILLOGA               TO ERR-DATI
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       WRITE-OFILLOGA-EX.
           EXIT.
      *================================================================*
       WRITE-OFILRICC.
      *================================================================*
           WRITE REC-OFILRICC.
           IF   FS-OFILRICC-OK
           THEN
                ADD 1                           TO TOT-WRT-OFILRICC
           ELSE
                INITIALIZE                         CAMPI-ERRORE
                MOVE '0065'                     TO ERR-PUNTO
                MOVE 'WRITE OFILRICC  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRICC                TO ERR-CODICE-X
                MOVE REC-OFILRICC               TO ERR-DATI
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       WRITE-OFILRICC-EX.
           EXIT.
      *================================================================*
       WRITE-OFILRIDR.
      *================================================================*
           WRITE REC-OFILRIDR.
           IF   FS-OFILRIDR-OK
           THEN
                ADD 1                           TO TOT-WRT-OFILRIDR
           ELSE
                INITIALIZE                         CAMPI-ERRORE
                MOVE '0066'                     TO ERR-PUNTO
                MOVE 'WRITE OFILRIDR  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRIDR                TO ERR-CODICE-X
                MOVE REC-OFILRIDR               TO ERR-DATI
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       WRITE-OFILRIDR-EX.
           EXIT.
      *================================================================*
       WRITE-OFILRIDT.
      *================================================================*
           WRITE REC-OFILRIDT.
           IF   FS-OFILRIDT-OK
           THEN
                ADD 1                           TO TOT-WRT-OFILRIDT
           ELSE
                INITIALIZE                         CAMPI-ERRORE
                MOVE '0067'                     TO ERR-PUNTO
                MOVE 'WRITE OFILRIDT  '         TO ERR-DESCRIZIONE
                MOVE FS-OFILRIDT                TO ERR-CODICE-X
                MOVE REC-OFILRIDT               TO ERR-DATI
                PERFORM ERRORE                THRU ERRORE-EX
                PERFORM CHIUSURA-FORZATA
           END-IF.
       WRITE-OFILRIDT-EX.
           EXIT.
      *================================================================*
       ERRORE.
      *================================================================*
           DISPLAY
           '*======================================================*'.
           DISPLAY
           '*====                 ERRORE GRAVE                 ====*'.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====   PROGRAMMA    : ' ERR-PROGRAMMA.
           DISPLAY
           '*====   PUNTO        : ' ERR-PUNTO.
           DISPLAY
           '*====   DESCRIZIONE  : ' ERR-DESCRIZIONE.
           DISPLAY
           '*====   CODICE-X     : ' ERR-CODICE-X.
           DISPLAY
           '*====   CODICE-9     : ' ERR-CODICE-Z.
           DISPLAY
           '*====   DATI         : ' ERR-DATI.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====                 ERRORE GRAVE                 ====*'.
           DISPLAY
           '*======================================================*'.

           MOVE 12                              TO RETURN-CODE.
       ERRORE-EX.
           EXIT.
      *================================================================*
       ANOMALIA.
      *================================================================*
           DISPLAY
           '*======================================================*'.
           DISPLAY
           '*====             ELABORAZIONE ANOMALA             ====*'.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====   PUNTO        : ' ERR-PUNTO.
           DISPLAY
           '*====   DESCRIZIONE  : ' ERR-DESCRIZIONE.
           DISPLAY
           '*====   CODICE-X     : ' ERR-CODICE-X.
           DISPLAY
           '*====   CODICE-9     : ' ERR-CODICE-Z.
           DISPLAY
           '*====----------------------------------------------====*'.
           DISPLAY
           '*====             ELABORAZIONE ANOMALA             ====*'.
           DISPLAY
           '*======================================================*'.
       ANOMALIA-EX.
           EXIT.
      *================================================================*
       CHIUSURA-FORZATA.
      *================================================================*
           STOP RUN.
