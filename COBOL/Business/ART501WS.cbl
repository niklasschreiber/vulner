       IDENTIFICATION DIVISION.
       PROGRAM-ID. ART501WS.
      ******************************************************************
      * INTERFACCIA CHIAMATA DA F.E. PER COLLOQUIO CON PGM ART501      *
      *                    TRX   SN51
WSDL  * OCCHIO WSDL
EIBCAL* INSERITA EIBCAL X CONTROLLO LUNGHEZZA COMMAREA
LOGFIN* INSERIMENTO CHIAMATA ROUTINE X LOG FWEBRLOG
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       DATA DIVISION.
      *
       WORKING-STORAGE SECTION.
      ******************************************************************
      *      VARIABILI DI COMODO                                       *
      ******************************************************************
       01  WS-PROGRAM                PIC X(8) VALUE SPACES.
      ******************************************************************
       01  WS-TIMESTAMP              PIC X(26).
       01  WS-TIMESTAMP-RED.
           05  DATA-SIST-AMG.
             10  ANNO-SIST           PIC X(04).
             10  FILLER              PIC X(01).
             10  MESE-SIST           PIC X(02).
             10  FILLER              PIC X(01).
             10  GIORNO-SIST         PIC X(02).
           05  FILLER                PIC X(16).

      *-------------------------------------------------------*
      * COPY PER COLLOQUIO CON WSDL INPUT                     *
      *-------------------------------------------------------*
WSDL  *-**  DCNENDE1.COLLD.SNPO.WSCPY   ----------------------*
      *-------------------------------------------------------*
       01 WSDL-SN51-INPUT.
           COPY AR501I01.
      *-------------------------------------------------------*
      * COPY PER COLLOQUIO CON WSDL OUTPUT                    *
      *-------------------------------------------------------*
WSDL  *-**  DCNENDE1.COLLD.SNPO.WSCPY   ----------------------*
      *-------------------------------------------------------*
       01 WSDL-SN51-OUTPUT.
           COPY AR501O01.
      *---------------------------------------------------------------*
      * COPY PER COLLOQUIO CON ART501.
      *---------------------------------------------------------------*
           COPY ARC501.
      *-------------------------------------------------------*
       01  DATI-ERR.
           03  DATI-ERR-PGM         PIC X(8)    VALUE SPACES.
           03  DATI-ERR-ABEND       PIC X(4)    VALUE SPACES.
           03  DATI-ERR-TIPOTERM    PIC X(1)    VALUE SPACES.
           03  DATI-ERR-EIB         PIC X(100)  VALUE SPACES.
           03  DATI-ERR-MES1        PIC X(60)   VALUE SPACES.
           03  DATI-ERR-MES2        PIC X(60)   VALUE SPACES.
           03  DATI-ERR-DES1        PIC X(10)   VALUE SPACES.
           03  DATI-ERR-DES2        PIC X(10)   VALUE SPACES.
           03  FILLER               PIC X(47)   VALUE SPACES.
      *
LOGFIN   COPY FWEBALOG.
LOGFIN*
           EXEC SQL INCLUDE SQLCA     END-EXEC.
      *
EIBCAL 01  WS-EIBCALEN     PIC S9(8)    VALUE +0.
EIBCAL******  INSERIRE VALUE UGUALE ALL PIC DI DFHCOMMAREA  ******
EIBCAL 01  WS-EIBCALEN-OK  PIC S9(8)    VALUE +572.
       LINKAGE SECTION.
WSDL  *************************INPUT  572   ****************************
WSDL  *************************OUTPUT 086   ****************************
WSDL   01  DFHCOMMAREA                  PIC X(572).
      ******************************************************************
      *
      ******************************************************************
      *             P R O C E D U R E     D I V I S I O N              *
      ******************************************************************
       PROCEDURE DIVISION USING DFHCOMMAREA.
      *
EIBCAL     MOVE EIBCALEN  TO WS-EIBCALEN.
EIBCAL     IF WS-EIBCALEN NOT =  WS-EIBCALEN-OK
EIBCAL        MOVE '9'              TO AR501XRETXCODE
EIBCAL        STRING 'ART501WS-COMMAREA DISALLINEATA : '
EIBCAL                WS-EIBCALEN
EIBCAL        DELIMITED BY SIZE   INTO AR501XMSGXERR
EIBCAL        PERFORM  PROGRAM-FINE THRU EX-PROGRAM-FINE
EIBCAL     END-IF.
      *
           EXEC CICS HANDLE         CONDITION
                                    ERROR  (ERRORE-GENER)
                                    END-EXEC.

           EXEC CICS HANDLE         ABEND
                                    LABEL  (ERRORE-GENER)
                                    END-EXEC.

      ******************************************************************
           MOVE DFHCOMMAREA      TO WSDL-SN51-INPUT.
      *
LOGFIN*
LOGFIN*    IMPOST.PROGRAMMA DA LOGGARE DOPO LA MOVE DELLA DFHCOMMAREA
LOGFIN*
LOGFIN     MOVE 'DA POSID'                 TO FWEBALOG-SERVIZIO.
LOGFIN     MOVE SPACES                     TO FWEBALOG-REQ-ID.
LOGFIN     MOVE AR501XNUMRAPXINP           TO VLOG-CONTO.
LOGFIN     STRING VLOG-CONTO-INT
LOGFIN            VLOG-CONTO
LOGFIN     DELIMITED BY SIZE   INTO FWEBALOG-DATO-RICH.
LOGFIN     MOVE 'ART501WS'                 TO FWEBALOG-NOME-PGM.
LOGFIN     MOVE SPACES                     TO FWEBALOG-RETC-PGM.
LOGFIN     MOVE 'ART501WS'                 TO FWEBALOG-PRGM-LEVEL1.
LOGFIN     MOVE '        '                 TO FWEBALOG-PRGM-LEVEL2.
LOGFIN     MOVE '        '                 TO FWEBALOG-PRGM-LEVEL3.
LOGFIN     MOVE 'AR501I01'                 TO FWEBALOG-NOME-COPY.
LOGFIN     MOVE LENGTH OF WSDL-SN51-INPUT  TO FWEBALOG-LENG-COPY.
LOGFIN     MOVE WSDL-SN51-INPUT            TO FWEBALOG-DETT-COPY.
LOGFIN     PERFORM FWEB-CHIAMA-VLOGFIN  THRU FWEB-CHIAMA-VLOGFIN-EX.
LOGFIN*
           EXEC SQL
                SET :WS-TIMESTAMP = CURRENT TIMESTAMP
           END-EXEC.
      *
           PERFORM VALORIZZA-AREA-ARC501
              THRU EX-VALORIZZA-AREA-ARC501

           INITIALIZE ARC501-DATI-OUTPUT.
      *
           PERFORM CALL-ART501
              THRU EX-CALL-ART501

           PERFORM VALORIZZA-OUTPUT
              THRU EX-VALORIZZA-OUTPUT
      *
           PERFORM  PROGRAM-FINE THRU EX-PROGRAM-FINE.
      *
           GOBACK.

       VALORIZZA-AREA-ARC501.

           INITIALIZE ARC501-DATI.
           MOVE AR501XDATIXINPUT   TO ARC501-DATI-INPUT.

       EX-VALORIZZA-AREA-ARC501.
           EXIT.

       CALL-ART501.

           MOVE 'ART501'          TO WS-PROGRAM.

           EXEC  CICS LINK
               PROGRAM  (WS-PROGRAM)
               COMMAREA (ARC501-DATI)
               LENGTH   (LENGTH OF ARC501-DATI)
           END-EXEC.

       EX-CALL-ART501.
           EXIT.

       VALORIZZA-OUTPUT.

           EVALUATE ARC501-RET-CODE
             WHEN '0'
               MOVE ARC501-RET-CODE         TO AR501XRETXCODE
               MOVE ARC501-MSG-ERR         TO AR501XMSGXERR
               MOVE ARC501-RICH            TO AR501XRICH
               MOVE ARC501-STATO           TO AR501XSTATO
               MOVE ARC501-ESITO           TO AR501XESITO
            WHEN OTHER
               MOVE ARC501-RET-CODE        TO AR501XRETXCODE
               MOVE ARC501-MSG-ERR         TO AR501XMSGXERR
              PERFORM  PROGRAM-FINE THRU EX-PROGRAM-FINE
           END-EVALUATE.

       EX-VALORIZZA-OUTPUT.
           EXIT.

       PROGRAM-FINE.

           MOVE WSDL-SN51-OUTPUT TO DFHCOMMAREA.

LOGFIN*
LOGFIN*    IMPOST.PROGRAMMA DA LOGGARE PRIMA DI USCIRE
LOGFIN*
LOGFIN     MOVE 'A  POSID'                 TO FWEBALOG-SERVIZIO.
LOGFIN     MOVE SPACES                     TO FWEBALOG-REQ-ID.
LOGFIN     MOVE AR501XNUMRAPXINP           TO VLOG-CONTO.
LOGFIN     STRING VLOG-CONTO-INT
LOGFIN            VLOG-CONTO
LOGFIN     DELIMITED BY SIZE   INTO FWEBALOG-DATO-RICH.
LOGFIN     MOVE 'ART501WS'                 TO FWEBALOG-NOME-PGM.
LOGFIN     MOVE AR501XRETXCODE             TO FWEBALOG-RETC-PGM.
LOGFIN     MOVE 'ART501WS'                 TO FWEBALOG-PRGM-LEVEL1.
LOGFIN     MOVE '        '                 TO FWEBALOG-PRGM-LEVEL2.
LOGFIN     MOVE '        '                 TO FWEBALOG-PRGM-LEVEL3.
LOGFIN     MOVE 'AR501O01'                 TO FWEBALOG-NOME-COPY.
LOGFIN     MOVE LENGTH OF WSDL-SN51-OUTPUT TO FWEBALOG-LENG-COPY.
LOGFIN     MOVE WSDL-SN51-OUTPUT           TO FWEBALOG-DETT-COPY.
LOGFIN     PERFORM FWEB-CHIAMA-VLOGFIN  THRU FWEB-CHIAMA-VLOGFIN-EX.
LOGFIN*
           EXEC CICS
                RETURN
           END-EXEC.

       EX-PROGRAM-FINE.
           EXIT.
LOGFIN*
LOGFIN     COPY FWEBPLOG.
LOGFIN*
      *------------------*
       ERRORE-GENER.
      *------------------*

           MOVE  DFHEIBLK           TO DATI-ERR-EIB.
           MOVE 'ART501WS'          TO DATI-ERR-PGM.

           EXEC CICS ASSIGN         ABCODE   (DATI-ERR-ABEND)
                                    END-EXEC.

           EXEC CICS HANDLE         ABEND
                                    CANCEL
                                    END-EXEC.

           EXEC CICS HANDLE         CONDITION
                                    ERROR
                                    END-EXEC.


           MOVE '9'                             TO AR501XRETXCODE
           MOVE 'ART501 - ERRORE GENERICO CICS'  TO AR501XMSGXERR

           PERFORM  PROGRAM-FINE THRU EX-PROGRAM-FINE.

       EX-ERRORE-GENER.
           EXIT.
