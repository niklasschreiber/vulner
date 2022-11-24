       IDENTIFICATION DIVISION.
       PROGRAM-ID.    ACZ019CX.
      *----------------------------------------------------------------*
      *  ATTIVATORE DI ROUTINE ATTIVATORE CONTI O TRASFERIMENTO CONTI  *
      *----------------------------------------------------------------*
      * FB0108 - ADEGUAMENTO DELLA LUNGHEZZA DELLA COMMAREA IN         *
      *          LINKAGE SECTION PER PREVENIRE PROBLEMI DI             *
      *          STORAGE VIOLATION.                                    *
      *----------------------------------------------------------------*
      * AG0115 - GENNAIO 2015 - CODICE INIZIATIVA: 102739              *
      *                                                                *
      * LIBRETTI 2610 AI MINORI - CONTROLLO COLLEGAMENTO GENITORE (151)*
      * O, IN ALTERNATIVA, TUTORE (104)                                *
      *                                                                *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *----------------------------------------------------------------*
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *----------------------------------------------------------------*
       DATA DIVISION.
      *----------------------------------------------------------------*
      *       W O R K I N G     S T O R A G E                          *
      *----------------------------------------------------------------*
       WORKING-STORAGE SECTION.
       77  PROGRAMMA                   PIC X(08) VALUE 'ACZ019CX'.
       01  FILLER                      PIC X(14) VALUE 'INIZIO-WORKING'.
      *--------------------------------------------------------------*
      *       W O R K I N G     S T O R A G E     U T E N T E        *
      *--------------------------------------------------------------*
      * COPY X TRASCODIFICA DEL CODICE ANOMALIA DEL ACUT03
      *--------------------------------------------------------------*
           COPY ACZ019A.
AG0115*
AG0115*--------------------------------------------------------------*
AG0115*       COPY PER LA CHIAMATA ROUTINE ANAGRAFE ACS108           *
AG0115*--------------------------------------------------------------*
AG0115 01  FILLER                 PIC X(16) VALUE '*****ACS108*****'.
AG0115 01  ACS108-AREA.
AG0115     COPY ACS108A.
AG0115*
      *--------------------------------------------------------------*
      *       CAMPI DI APPOGGIO E CONTATORI                          *
      *--------------------------------------------------------------*
      *
       01  W-TROVATO                        PIC 9.
          88  TROVATO                                VALUE  0.
          88  NON-TROVATO                            VALUE  1.
      *
       01  TAB-CATEGORIE.
           02  FILLER         PIC X(04)  VALUE '2010'.
AG0115     02  FILLER         PIC X(04)  VALUE '2610'.
           02  FILLER         PIC X(04)  VALUE '    '.
           02  FILLER         PIC X(04)  VALUE '    '.
           02  FILLER         PIC X(04)  VALUE '    '.
           02  FILLER         PIC X(04)  VALUE '    '.
           02  FILLER         PIC X(04)  VALUE '    '.
           02  FILLER         PIC X(04)  VALUE '    '.
           02  FILLER         PIC X(04)  VALUE '    '.
           02  FILLER         PIC X(04)  VALUE '    '.
       01 TAB-CATEGORIA-R REDEFINES TAB-CATEGORIE.
           03 ELE-CAT     OCCURS 10 INDEXED BY IND.
              05 CATEGORIA           PIC X(04).
      *
AG0115*
AG0115 01  WS-DATA-APPO.
AG0115     05  WS-ANNO-APPO         PIC 9(04).
AG0115     05  WS-MESE-APPO         PIC 9(02).
AG0115     05  WS-GIORNO-APPO       PIC 9(02).
AG0115
AG0115 01  WS-TEMPO                    PIC S9(9) COMP VALUE 0.
AG0115 01  WS-DATA.
AG0115    03  W-SYS-SEC              PIC 9(02).
AG0115    03  W-SYS-DATA.
AG0115        05  W-SYS-AA           PIC 9(02).
AG0115        05  W-SYS-MM           PIC 9(02).
AG0115        05  W-SYS-GG           PIC 9(02).
AG0115
AG0115 01  WS-DESCR-TOT.
AG0115    05 WS-DESCR-1                    PIC X(6).
AG0115    05 WS-DESCR-2                    PIC X(02).
AG0115*
AG0115 01  FLG-ETA                         PIC 9(1).
AG0115     88  MINORE-ETA                  VALUE 1.
AG0115     88  MAGGIORE-ETA                VALUE 0.
      *---------------------------------------------------------------*
       LINKAGE SECTION.
      *---------------------------------------------------------------*
FB0108*01  DFHCOMMAREA                 PIC X(400) VALUE SPACES.
FB0108 01  DFHCOMMAREA                 PIC X(347) VALUE SPACES.
      *----------------------------------------------------------------*
      *       P R O C E D U R E     D I V I S I O N                    *
      *----------------------------------------------------------------*
       PROCEDURE DIVISION USING DFHCOMMAREA.
      *--------------------------------------------------------------*
      *-   MAIN PROGRAMMA
      *--------------------------------------------------------------*
       MAIN SECTION.
      *----
           MOVE DFHCOMMAREA  TO ACZ019A.
AG0115*
AG0115     MOVE 0            TO FLG-ETA
AG0115     INITIALIZE  ACS108-AREA
AG0115                 ACZ019-ESITO
AG0115*
      *----
           PERFORM CERCA-CATEGORIA  THRU CERCA-CATEGORIA-EX
      *
AG0115* SI CHIAMA L'ANAGRAFE PER DETERMINARE LA NATURA GIURIDICA
AG0115* SOLO SE LA CATEGORIA E' 2010 O 2610 (IN TAL CASO FLAG TROVATO
AG0115* E' VERO) ED IN TAL CASO SI ESEGUONO I RELATIVI CONTROLLI
AG0115
AG0115     IF TROVATO
AG0115        PERFORM CALL-ANAG THRU CALL-ANAG-EX
AG0115        IF ACZ019-ESITO      = ZERO
AG0115           PERFORM CNTRL-DATI-INPUT THRU CNTRL-DATI-INPUT-EX
AG0115        END-IF
AG0115     END-IF.
      *
AG0115     IF ACZ019-ESITO      = ZERO
AG0115        IF TROVATO                    AND
AG0115           MINORE-ETA                 AND
AG0115           L-ACS108-NAT-GIURIDICA = 'PF '
AG0115           EXEC CICS LINK PROGRAM('ACZ021CX')
AG0115                     COMMAREA(ACZ019A)
AG0115                     LENGTH  (LENGTH OF ACZ019A)
FB0108*                    LENGTH  (400)
AG0115           END-EXEC
AG0115        ELSE
AG0115           EXEC CICS LINK PROGRAM('ACZ020CX')
AG0115                    COMMAREA(ACZ019A)
FB0108                    LENGTH  (LENGTH OF ACZ019A)
FB0108*                   LENGTH  (400)
                 END-EXEC
AG0115        END-IF
           END-IF.
      *
      *----
       FINE.
      *----
           MOVE ACZ019A         TO  DFHCOMMAREA.
      *----
           GOBACK.
      *----
       CERCA-CATEGORIA.
           SET IND     TO 1
           SEARCH ELE-CAT     VARYING IND
                 AT END
                     MOVE 1 TO W-TROVATO
           WHEN CATEGORIA(IND) = ACZ019-CATEGORIA
                MOVE 0 TO W-TROVATO.

       CERCA-CATEGORIA-EX.
           EXIT.
      *
AG0115 CALL-ANAG.
      *
      *    EXEC CICS ENTER TRACEID (1) FROM  (ACUT03-NDG)
      *    END-EXEC.
      *
           PERFORM ASK-CURRENT-DATE THRU ASK-CURRENT-DATE-EX

           INITIALIZE                      L-ACS108-ARG.
           MOVE  ACZ019-NDG            TO  L-ACS108-I-NDG.
           MOVE  00000                 TO  L-ACS108-I-BANCA.
           MOVE  'A'                   TO  L-ACS108-I-TIPO-RICH.
      *
           EXEC CICS LINK PROGRAM('ACS108CX')
                          COMMAREA(L-ACS108-ARG)
                          LENGTH  (LENGTH OF L-ACS108-ARG)
           END-EXEC.
      *
           PERFORM CNTR-108      THRU CNTR-108-EX.
      *
       CALL-ANAG-EX.
           EXIT.
       CNTR-108.
      *
           EVALUATE L-ACS108-RET-CODE
           WHEN 0
              CONTINUE
           WHEN OTHER
              MOVE 'ACS108'          TO WS-DESCR-1
              MOVE L-ACS108-RET-CODE TO WS-DESCR-2
              MOVE WS-DESCR-TOT      TO ACZ019-COD-ANOM
              STRING WS-DESCR-TOT ' ERRORE ANAGRAFE'
              DELIMITED BY SIZE       INTO   ACZ019-DESCR-ERRORE
              MOVE 9 TO ACZ019-ESITO
           END-EVALUATE.
      *
       CNTR-108-EX.
           EXIT.
      *
       CNTRL-SE-MINORE.
      *
           MOVE L-ACS108-DATA-NASC-COS TO WS-DATA-APPO.
           ADD 18 TO WS-ANNO-APPO.
      *
      *    EXEC CICS ENTER TRACEID (91) FROM (L-ACS108-DATA-NASC-COS)
      *    END-EXEC.
      *    EXEC CICS ENTER TRACEID (92) FROM (WS-DATA)
      *    END-EXEC.
      *    EXEC CICS ENTER TRACEID (93) FROM (WS-DATA-APPO)
      *    END-EXEC.
      *
           IF WS-DATA-APPO > WS-DATA
      *                           --> MINORENNE
              MOVE 1 TO FLG-ETA
           ELSE
      *                           --> MAGGIORENNE
              MOVE 0 TO FLG-ETA
           END-IF.
      *
       CNTRL-SE-MINORE-EX.
           EXIT.
       ASK-CURRENT-DATE.

           EXEC CICS ASKTIME
               ABSTIME (WS-TEMPO)
           END-EXEC.
           EXEC CICS FORMATTIME
                ABSTIME  (WS-TEMPO)
                YYYYMMDD (WS-DATA)
           END-EXEC.

       ASK-CURRENT-DATE-EX.
           EXIT.
       CNTRL-DATI-INPUT.

      * SE SI TRATTA DI UNA PF E LA CATEGORIA E' 2010 O 2610 (SE FLAG
      * TROVATO E' VERO) SI CONTROLLA SE MINORENNE O MAGGIORENNE
      * SE SI TRATTA DI MAGGIORENNE E LA CATEGORIA E' 2010 SI DA'
      * UN ERRORE.
      * SE SI TRATTA DI MAGGIORENNE E LA CATEGORIA E' 2610 SI PROSEGUE
      * IN QUANTO IL 2610 PUO' ESSERE APERTO ANCHE DA MAGGIORENNI
      *
      * SE SI TRATTA DI UNA NATURA GIURIDICA DIVERSA DA PF
      * E LA CATEGORIA E' 2010  SI INVIA UN ERRORE IN QUANTO
      * LA CATEGORIA E' INCOMPATIBILE CON NATURE GIURIDICHE DIFFERENTI
      * DA PF
      *
           IF L-ACS108-NAT-GIURIDICA = 'PF '
              PERFORM CNTRL-SE-MINORE THRU CNTRL-SE-MINORE-EX
              IF ACZ019-CATEGORIA  = '2010'
              AND MAGGIORE-ETA
                 MOVE 1                          TO ACZ019-ESITO
                 MOVE 'INTESTATARIO MAGGIORENNE' TO
                                                ACZ019-DESCR-ERRORE
              END-IF
           ELSE
              IF ACZ019-CATEGORIA  = '2010'
                 MOVE 1 TO ACZ019-ESITO
                 MOVE
                 'CATEGORIA DR NON COMPATIBILE CON NAT. GIUR'
                                       TO ACZ019-DESCR-ERRORE
              END-IF
           END-IF.

       CNTRL-DATI-INPUT-EX.
           EXIT.
AG0115
