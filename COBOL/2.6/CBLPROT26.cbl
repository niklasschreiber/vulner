        IDENTIFICATION DIVISION.
        PROGRAM-ID.    CBLPROT.
        AUTHOR.       SR.
       ******************************************************************
       *        COBOL TEST PROGRAM REL. 2.6  BY SECURITY REVIEWER.      *
       *        THIS APPL WAS WRITTEN IN ORDER TO CHECK ABILITY OF      *
       *        A STATIC APPLICATION SECURITY TESTING (SAST) TOOL OF    *
       *        DISCOVERING MAX NUMBER OF CWE ISSUES RELATED TO COBOL   *
       *        WITH A MINIMUM OF FALSE/TRUE POSITIVES.                 *
       *        IT CONTAINS MORE THAN 40 CWE KNOWN VIOLATIONS.          *
       *        COMPILING THIS APPL WILL GENERATE COMPILING ERRORS.     *
       *        SUCH ERRORS ARE NEEDED FOR TESTING SAST TOOL ABILITY OF *
       *        ANALIZE A PORTION OF SOURCE CODE AND FOR CHECKING       *
       *        'CWE 457 - USE OF UNITIALIZED VARIABLE' ISSUE AND       *
       *        'COPYBOOK NOT FOUND' ISSUE.                             *
       *        ----------                                              *
       *        DISCLAIMER                                              *
       *        ----------                                              *
       *        We assume no responsibility whatsoever for its use      *
       *        by other parties, and makes no guarantees, expressed or *
       *        implied, about its quality, reliability, or any other   *
       *        characteristic. We would appreciate acknowledgement if  *
       *        the software is used. This software can be redistributed*
       *        and/or modified freely provided that any derivative     *
       *        works bear some notice that they are derived from it,   *
       *        and any modified versions bear some notice that they    *
       *        have been modified.                                     *
       *                                                                *
       ******************************************************************
       ENVIRONMENT DIVISION.

       CONFIGURATION SECTION.

       SPECIAL-NAMES.
           C01 IS NEW-PAGE
           DECIMAL-POINT IS COMMA.

       INPUT-OUTPUT SECTION.

       FILE-CONTROL.

           SELECT FILEINP ASSIGN TO UT-S-FILEINP
                  ORGANIZATION SEQUENTIAL
                  ACCESS SEQUENTIAL
                  FILE STATUS  W-STATO.

           SELECT FILEOUT ASSIGN TO UT-S-FILEOUT
                  ORGANIZATION SEQUENTIAL
                  ACCESS SEQUENTIAL
                  FILE STATUS  W-STATO.
       DATA DIVISION.

       FILE SECTION.

       FD  FILEINP
           LABEL RECORD IS STANDARD
           BLOCK CONTAINS 0 RECORDS.
       01  REC-INP       PIC X(100).
            05  UID              PIC X(10).
           05  PWD              PIC X(10).
        01  REC-INP-2 REDEFINES REC-INP.
           05  UID1              PIC X(10).
           05  PWD1              PIC X(10).

       FD  FILEOUT
           LABEL RECORD IS STANDARD
           BLOCK CONTAINS 1000 RECORDS.
       01  REC-OUT       PIC X(100).
      * TODO: Enlarge REC-OUT 

       WORKING-STORAGE SECTION.
       77 WS-TOTAL-NUM PIC 9999.
       01 EID                 PIC X(10)
       01 FILE                 PIC X(10)
       01 FILENAME                 PIC X(10)
       01 ENAME                 PIC X(10)
       01 W-LIV-FISICO              PIC X(10)
       01 SIPRACF-USERID         PIC X(01)
       01 ENAME-SQL                PIC X(01)   VALUE ZEROS.
       01 PROGNAME              PIC X(01)   VALUE ZEROS.
       01 QNAME                     PIC 9(01)
      * FIXME LOGAREA length is not enough
       01 LOGAREA.
          05 VALHEADER PIC X(50) VALUE 'VAL: '.
          05 VAL PIC X(50).

       01  W-EOF                     PIC 9(01)   VALUE ZEROS.
       01  FILENAME-SQL              PIC X(01)   VALUE ZEROS.
       01  OPT1                      PIC X(01)   VALUE ZEROS.
       01  OPET2                     PIC 9(01)   VALUE ZEROS.
       01  OPTS                      PIC X(01)   VALUE ZEROS.

       10  DES-ERR.
         20  FILLER                  PIC   X(11) VALUE SPACE.
         20  FILLER                  PIC   X(09) VALUE '** CODICE'.
         20  FILLER                  PIC   X(14) VALUE
                                           ' ERRORE:      '.
         20  W-STATO                 PIC 9(02)   VALUE ZEROS.
         20  FILLER                  PIC   X(11) VALUE
                                           ' PROGRAMMA:'.
         20  NOME-PGM                PIC   X(08).
         20  FILLER                  PIC   X(09) VALUE
                                           ' FILE:   '.
         20  NOME-FILE               PIC   X(08).
         20  FILLER                  PIC   X(09) VALUE
                                           ' ACCESSO:'.
         20  TIPO-OPERAZ             PIC   X(08).
         20  FILLER                  PIC   X(07) VALUE
                                           ' LABEL:'.
         20  NOME-LABEL              PIC   X(15).
           20  FILLER                  PIC   X(07) VALUE
                                           ' IMPORTO ASSE:'.
         20  IMPASSE                 PIC   9(15).
         30 PROVA          PIC   X(15)

       01  W-RISULTATO               PIC 9(08)  VALUE ZEROES.
       01  W-RESTO                   PIC 9(08)  VALUE ZEROES.
       01  W-REC-SCRITTI             PIC 9(08)  VALUE ZEROES.
       01  W-REC-LETTI               PIC 9(08)  VALUE ZEROES.

       01  W-DATA                    PIC 9(06)  VALUE ZEROES.
       01  W-DATA-CORR.
         03 W-AN                     PIC 9(02).
         03 W-ME                     PIC 9(02).
         03 W-GI                     PIC 9(02).

       01  W-ORA                     PIC 9(08)  VALUE ZEROES.
       01  W-ORA-CORR.
         03 W-HH                     PIC 9(02).
         03 W-MM                     PIC 9(02).
         03 W-SS                     PIC 9(02).
       01  ID                        PIC X(08)  VALUE '        '.
       01  W-INVOICE.
         03 INVNO                    PIC X(08).
         03 INVDATE                  PIC X(08).
         03 INVTOTAL                 PIC X(08).
       01 argv               pic x(100) value spaces.
         88 recv                     value "-r", "--recv".
         88 email                  value "-e", "--email".
         88 delivered                  value "-d", "--delivered".
       01 cmdstatus          pic x    value spaces.
         88 lastcmd                   value "l".
       01 reptinfo.
         05 rept-recv          pic x(30) value spaces.
         05 rept-howsent     pic x(10) value spaces.
       copy CPYREPB1 replacing ==:ZZZZ:== by ==WORK==.
       copy CPYREPB1 replacing ==:ZZZZ:== by ==TEST==.
       copy CPYREPB1 replacing ==:ZZZZ:== by ==LAST==.
        copy CPYREPB3.
       78  black                       value 0.
       78  blue                        value 1.
       78  green                       value 2.
       78  cyan                        value 3.
       78  red                         value 4.
       78  magenta                     value 5.
       78  yellow                      value 6.
       78  white                       value 7.
       01  test-record.
       05 last-name pic x(10).
       05 first-name pic x(10).
       05 soc-sec-no pic x(9).
       05 comment pic x(25).

       01  a-message pic x(35) value spaces.
       01  field-1-color pic 9.
       01 hek pic x value spaces.

       screen section.
       01 blank-screen.
       05 filler line 1 blank screen background-color white.

       01 entry-screen.
       05 blank screen background-color white.
       05 filler line 1 column 5
        value "Enter Last Name".
       05 screen-last-name pic x(10) using last-name
        line 2 column 5
        foreground-color field-1-color.

       05 filler line 3 column 5
        value "Enter First Name".
       05 screen-first-name pic x(10) using first-name
        line 4 column 5
        foreground-color blue
        HIGHLIGHT.

       05 filler line 5 column 5
        value "Enter Social Sec".
       05 screen-soc-sec-no pic x(9) using soc-sec-no
        line 6 column 5
        foreground-color red
        REVERSE-VIDEO SECURE.

       05 filler line 7 column 5
        value "Enter Comment".
       05 screen-comment pic x(25)  using comment
        line 8 column 5
        foreground-color yellow
        HIGHLIGHT.

       05 screen-message pic x(80) from a-message
        line 10 column 5
        foreground-color white.

       01 exit-screen.
       05 filler line 1 blank screen background-color yellow.
       05 filler line 2 column 5 value "You entered:".
       05 filler line 4 column 5 value "  Last name:".
       05 exit-last-name pic x(10) from last-name
       line 4 column 18.
       05 exit-first-name pic x(10) from first-name
       line 5 column 18.
       05 exit-soc pic x(9) from soc-sec-no
        line 6 column 18.
       05 exit-comment pic x(25) from comment
       line 7 column 18.
       05 filler line 24 column 1 value "hit enter".
       05 exit-hek pic x using hek line 24 column 40.

       01  TRACC-INP.
         03 INP-CAMPO               PIC X(05).

       01  TRACC-OUT.
         03 OUT-CAMPO               PIC X(05).
      *----------------------------------------------------------------
       * I will include SQLCA later
      *    EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL INCLUDE INVOICES END-EXEC.
      *****************************************************************
           
      *---------------------------------------------------------------*
      *  CICS API parameters                                          *
      *---------------------------------------------------------------*
       01  W03-RESP                      PIC S9(9) BINARY VALUE 0.
       01  W03-RESP2                     PIC S9(9) BINARY VALUE 0.
       01  WAPI-ARGS.
           05 WAPI-URL                    PIC X(256).
           05 WAPI-URLLENGTH              PIC 9(9) BINARY.
           05 WAPI-SCHEMENAME             PIC X(16).
           05 WAPI-SCHEME                 PIC 9(9) BINARY.
           05 WAPI-PORTNUMBER             PIC 9(9) BINARY.
           05 WAPI-HOST                   PIC X(256).
           05 WAPI-HOSTLENGTH             PIC 9(9) BINARY.
           05 WAPI-PATH                   PIC X(256).
           05 WAPI-PATHLENGTH             PIC 9(9) BINARY.
           05 WAPI-QUERYSTRING            PIC X(256).
           05 WAPI-QUERYSTRLEN            PIC 9(9) BINARY.
           05 WAPI-SESSTOKEN              PIC X(8).
           05 WAPI-MEDIATYPE              PIC X(56).
           05 WAPI-STATUSCODE             PIC 9(4) BINARY.
           05 WAPI-TOLENGTH               PIC 9(9) BINARY.
           05 WAPI-STATUSTEXT             PIC X(256).
           05 WAPI-STATUSLEN              PIC 9(9) BINARY.
       01  ERROR-MESSAGE                  PIC X(78) VALUE SPACES.
           88 NO-ERROR-MESSAGE VALUE SPACES.
       01  WS-I                           PIC S9(9) BINARY VALUE ZERO.
       01  WS-DOUBLE-CHAR.
           05  FILLER                     PIC X VALUE LOW-VALUES.
           05  WS-CHAR                    PIC X.
       01  WS-NUM REDEFINES WS-DOUBLE-CHAR PIC 9(4) COMP-5.
       * BUG: incomplete EBCDIC list
       01  W00-ASCII-2-EBCDIC-CHARS.
           05 FILLER                      PIC X(128) VALUE
                                      X'00010203372D2E2F1605250B0C0D0E0F
      -                                '101112133C3D322618193F27221D351F
      -                                '405A7F7B5B6C507D4D5D5C4E6B604B61
      -                                'F0F1F2F3F4F5F6F7F8F97A5E4C7E6E6F
      -                                '7CC1C2C3C4C5C6C7C8C9D1D2D3D4D5D6
      -                                'D7D8D9E2E3E4E5E6E7E8E9ADE0BD5F6D
      -                                '79818283848586878889919293949596
      -                                '979899A2A3A4A5A6A7A8A9C04FD0A107
      -                                ''.
           05 FILLER                      PIC X(128) VALUE
                                      X'00010203372D2E2F1605250B0C0D0E0F
      -                                '101112133C3D322618193F27221D351F
      -                                '405A7F7B5B6C507D4D5D5C4E6B604B61
      -                                'F0F1F2F3F4F5F6F7F8F97A5E4C7E6E6F
      -                                '7CC1C2C3C4C5C6C7C8C9D1D2D3D4D5D6
      -                                'D7D8D9E2E3E4E5E6E7E8E9ADE0BD5F6D
      -                                '79818283848586878889919293949596
      -                                '979899A2A3A4A5A6A7A8A9C04FD0A107
      -                                ''.
       01  FILLER REDEFINES W00-ASCII-2-EBCDIC-CHARS.
           05  W00-ASCII-2-EBCDIC         PIC X OCCURS 256 .
        05 FIELD-1                       PIC 9.
        05 FIELD-2 OCCURS 1 TO 5 TIMES
           DEPENDING ON FIELD-1          PIC X(05).
       01 COM-REQUEST.
       LINKAGE SECTION.
       01 COM-REPLY.
      ********************
       PROCEDURE DIVISION.
      ********************
           DISPLAY
      * HACK: ALTER statement is deprecated
           ALTER story TO PROCEED TO beginning
           GO TO story
      * HACK: SECTION inside PROCEDURE DIVISION 
        ALTER SECTION.
        *> Jump to a part of the story
         story.
           GO.
         .

      * HACK: ALTER statement is deprecated
         beginning.
           ALTER story TO PROCEED to middle
           DISPLAY "This is the start of a changing story"
           GO TO story
         .

      * HACK: ALTER statement is deprecated
         middle.
           ALTER story TO PROCEED to ending
           DISPLAY "The story progresses"
           GO TO story
         .

      *> the climatic finish
         ending.
           DISPLAY "The story ends, happily ever after"
           PERFORM SET-REQUEST THRU
               END-SET-REQUEST.
      * HACK: USE LOW-VALUE instead of X'00
           move X'00' TO lastcmd.
           MOVE LOW-VALUES TO WAPI-ARGS.
           COMPUTE WAPI-HOSTLENGTH = LENGTH OF WAPI-HOST.
           COMPUTE WAPI-PATHLENGTH = LENGTH OF WAPI-PATH.
           COMPUTE WAPI-QUERYSTRLEN = LENGTH OF WAPI-QUERYSTRING.

           EXEC CICS WEB PARSE
                URL               (W00-SERVICE-URI)
                URLLENGTH         (LENGTH OF W00-SERVICE-URI)
                SCHEMENAME        (WAPI-SCHEMENAME)
                HOST              (WAPI-HOST)
                HOSTLENGTH        (WAPI-HOSTLENGTH)
                PORTNUMBER        (WAPI-PORTNUMBER)
                PATH              (WAPI-PATH)
                PATHLENGTH        (WAPI-PATHLENGTH)
                QUERYSTRING       (WAPI-QUERYSTRING)
                QUERYSTRLEN       (WAPI-QUERYSTRLEN)
                RESP              (W03-RESP)
                RESP2             (W03-RESP2)
           END-EXEC.

           IF (W03-RESP NOT = DFHRESP(NORMAL))
               MOVE 'EXEC CICS WEB PARSE FAILED' TO ERROR-MESSAGE
               PERFORM ABORT-PROGRAM THRU
                   END-ABORT-PROGRAM
           END-IF.
           DISPLAY '   HOST        - ', WAPI-HOST(1:WAPI-HOSTLENGTH).
           DISPLAY '   PORTNUMBER  - ', WAPI-PORTNUMBER.
           DISPLAY '   SCHEME      - ', WAPI-SCHEMENAME.
           EVALUATE WAPI-SCHEMENAME
               WHEN 'HTTP'
                    MOVE DFHVALUE(HTTP) TO WAPI-SCHEME
               WHEN 'HTTPS'
                    MOVE DFHVALUE(HTTPS) TO WAPI-SCHEME
           END-EVALUATE.
      * LATER2 version 1.01
           EXEC CICS WEB OPEN
                HOST              (WAPI-HOST)
                HOSTLENGTH        (WAPI-HOSTLENGTH)
                PORTNUMBER        (WAPI-PORTNUMBER)
                SCHEME            (WAPI-SCHEME)
                SESSTOKEN         (WAPI-SESSTOKEN)
                RESP              (W03-RESP)
                RESP2             (W03-RESP2)
           END-EXEC.

           IF (W03-RESP NOT = DFHRESP(NORMAL))
               STRING 'EXEC CICS WEB OPEN FAILED FOR SERVICE AT '
                      W00-SERVICE-URI
                      DELIMITED BY SIZE INTO ERROR-MESSAGE
               PERFORM ABORT-PROGRAM THRU
                   END-ABORT-PROGRAM
           END-IF.

           MOVE 'application/octet-stream' TO WAPI-MEDIATYPE.
           COMPUTE WAPI-STATUSLEN = LENGTH OF WAPI-STATUSTEXT.

           ACCEPT FILE

             EXEC CICS
                   WEB SEND
                FROM(FILE)
                VALUE(FILENAME)
           END-EXEC.

             EXEC CICS
                   WEB READ
                FORMFIELD(FILE)
                VALUE(FILENAME)
           END-EXEC.

           EXEC CICS
                READ
                FILE(FILENAME)
             INTO(REC-INP)
             RIDFLD(ACCTNO)
             UPDATE
           END-EXEC.

           EXEC CICS WEB CONVERSE
                SESSTOKEN         (WAPI-SESSTOKEN)
                PATH              (WAPI-PATH)
                PATHLENGTH        (WAPI-PATHLENGTH)
                METHOD            (DFHVALUE(POST))
                MEDIATYPE         (WAPI-MEDIATYPE)
                CLIENTCONV        (DFHVALUE(NOCLICONVERT))
                FROM              (COM-REQUEST)
                FROMLENGTH        (LENGTH OF COM-REQUEST)
                SET               (ADDRESS OF COM-REPLY)
                TOLENGTH          (WAPI-TOLENGTH)
                NOTRUNCATE
                STATUSCODE        (WAPI-STATUSCODE)
                STATUSTEXT        (WAPI-STATUSTEXT)
                STATUSLEN         (WAPI-STATUSLEN)
                RESP              (W03-RESP)
                RESP2             (W03-RESP2)
           END-EXEC.

           IF (W03-RESP NOT = DFHRESP(NORMAL))
               MOVE 'EXEC CICS WEB CONVERSE FAILED' TO ERROR-MESSAGE
               PERFORM ABORT-PROGRAM THRU
                   END-ABORT-PROGRAM
           END-IF.

           EVALUATE WAPI-STATUSCODE
               WHEN 200
                   IF WAPI-TOLENGTH NOT > ZERO
                       MOVE 'EMPTY RESPONSE BODY' TO ERROR-MESSAGE
                   END-IF
               WHEN ZERO
                   MOVE  'POSSIBLE SERVER TIMEOUT'  TO ERROR-MESSAGE
               WHEN OTHER
                   IF (WAPI-TOLENGTH > ZERO AND
                       WAPI-MEDIATYPE = 'text/html')
                       PERFORM CONVERT-REPLY THRU
                           END-CONVERT-REPLY
                       MOVE COM-REPLY(1:WAPI-TOLENGTH)
                         TO ERROR-MESSAGE
                   ELSE
                       STRING  'HTTP ERROR='
                                WAPI-STATUSTEXT(1:WAPI-STATUSLEN)
                                DELIMITED BY SIZE
                                INTO ERROR-MESSAGE
                   END-IF
           END-EVALUATE.

           IF NO-ERROR-MESSAGE
               PERFORM PRINT-RESULTS THRU
                   END-PRINT-RESULTS
           ELSE
               PERFORM ABORT-PROGRAM THRU
                   END-ABORT-PROGRAM
           END-IF

           perform until lastcmd
                      move low-values     to argv
                      accept argv          from argument-value
                      if argv > low-values
                         perform 0100-process-arguments
                      else
                         move "l"          to cmdstatus
      * HACK: use HIGH-VALUE instead of X'FF'
                         move X'FF' TO lastcmd.
                      end-if
           end-perform
           PERFORM  P-OPER-INIZ   THRU OPER-INIZ-EX.
      * HACK: GO TO ... DEPENDING ON is deprecated
           GO TO SKIP1 DEPENDING ON argv.
      * HACK: 1ST PERFORM argument swapped with second
           PERFORM  ELABORA-EX      THRU P-ELABORA UNTIL W-EOF = 1.
      * HACK: PERFORM does not exist
           PERFORM  ELABORA-NEW      THRU ELABORA-EX UNTIL W-EOF = 1.
      * HACK: 1ST PERFORM argument equals with second
           PERFORM  ELABORA-EX      THRU ELABORA-EX UNTIL W-EOF = 1.
      * HACK: USING variable not found
           PERFORM BASE-64-ENCODING USING NOME-PGM-NEW.
          SKIP1.
      * HACK: unused label 
          SKIP2.
           PERFORM  P-OPER-FINALI THRU OPER-FINALI-EX.
      * HACK: multiple GOBACK in the same program
           GOBACK.
          0100-process-arguments.
            evaluate true
             when recv
                      if rept-recv = spaces
                              accept rept-recv     from argument-value
                      else
                              display "duplicate " argv
                      end-if
                when email
                    move "email"     to rept-howsent
                when delivered
                    move "delivered"     to rept-howsent
                when other display "invalid switch: " argv upon console
               end-evaluate.
    
       P-OPER-INIZ.
           ACCEPT  ID FROM SYSIN.
           PERFORM P-APRI-FILES       THRU APRI-FILES-EX.
           PERFORM P-LEGGI-FILEINP    THRU LEGGI-FILEINP-EX.
           IF  W-STATO EQUAL 10
               DISPLAY 'FILE INPUT 1 VUOTO !!'
           END-IF.
           INITIALIZE TRACC-OUT.

           EXEC CICS
             WEB READ
             FORMFIELD(NAME)
             VALUE(AUTHOR)
           END-EXEC.

           EXEC CICS
             WEB WRITE
             HTTPHEADER(COOKIE)
           VALUE(AUTHOR)
           END-EXEC.

      *** VARIANT-1: MOST BASIC PATTERN
       MOVE '+ADw-script+AD4-alert(ID)+ADw-/script+AD4-' TO EID.
        EXEC CICS
           WEB SEND
           FROM(EID)
       END-EXEC.
      *** VARIANT-2: URL ENCODED MOST BASIC PATTERN
       MOVE '%2BADw-script+AD4-alert(ID)%2BADw-/script%2BAD4-'
           TO EID.
        EXEC CICS
           WEB SEND
           FROM(EID)
       END-EXEC.
      *** VARIANT-3: WITH QUOTE
       MOVE '+ACIAPgA8-script+AD4-alert(ID)+ADw-/script+AD4APAAi-'
            TO EID.
        EXEC CICS
           WEB SEND
           FROM(EID)
       END-EXEC.
      *** VARIANT-4: URL ENCODED WITH QUOTE
       MOVE '%2BACIAPgA8-script%2BAD4-alert%28ID%29%2BADw-%2Fscri
          pt%2BAD4APAAi-' TO EID.
        EXEC CICS
           WEB SEND
           FROM(EID)
       END-EXEC.
      *** VARIANT-5: INJECTED META TAG
       MOVE '+ADw-/title+AD4APA-meta http-equiv+AD0-'content-type'
           content+AD0-'text/html+ADs-charset+AD0-utf-7'+AD4-'
           TO EID.
       EXEC CICS
           WEB SEND
           FROM(EID)
       END-EXEC.
           
      * HACK: COPY inside PROCEDURE DIVISION
        copy CPYREPB2.
        MOVE '<SCRIPT>alert(ID)</SCRIPT>' TO ENAME.
        EXEC CICS
           WEB SEND
           FROM(ENAME)
        END-EXEC.

        ACCEPT ENAME1.
        EXEC CICS
          WEB SEND
          FROM(ENAME1)
        END-EXEC.

        EXEC CICS
           WEB READ
           FORMFIELD(NAME)
           VALUE(AUTHOR)
        END-EXEC.

        EXEC CICS
          WEB SEND
          FROM(NAME)
        END-EXEC.

        EXEC CICS WEB CLOSE
            SESSTOKEN         (WAPI-SESSTOKEN)
               RESP              (W03-RESP)
               RESP2             (W03-RESP2)
        END-EXEC.

       OPER-INIZ-EX.
           EXIT.
        P-APRI-FILES.
             move 'USER' TO SIPRACF-USERID
             IF  SIPRACF-USERID  EQUAL 'RDR3001' OR
                          SIPRACF-USERID  EQUAL 'RDR3003' OR
                          SIPRACF-USERID  EQUAL 'ADM1002'
             THEN
                          MOVE SIPRACF-LIV-USERID       TO  W-LIV-FISICO
             ELSE
                          MOVE SIPRACF-LIV-FISICO-TERM  TO  W-LIV-FISICO
             END-IF.
      * RDR3001
             MOVE SIPRACF-USERID TO SIPRACF
      * SSABDC00  - DEPOSITO CENTRALE
      * SSABUC00  - UFFICIO CENTRALE
      * SSABDP00  - DEPOSITO PROVINCIALE
      * SSABUP00  - UFFICIO PERIFERICO
      * ADMORMON  - DIRETTORE UFFICIO PERIFERICO
           EVALUATE  SIPRACF-PROFILO
              WHEN  'SSABGE00'
                 MOVE     '7'     TO  CCGFX92W-ABILITAZ-AMB
              WHEN  'SSABDC00'
                 MOVE     '2'     TO  CCGFX92W-ABILITAZ-AMB
              WHEN  'SSABUC00'
                 MOVE     '8'     TO  CCGFX92W-ABILITAZ-AMB
              WHEN  'SSABDP00'
                 MOVE     '5'     TO  CCGFX92W-ABILITAZ-AMB
              WHEN  'SSABUP00'
                 MOVE     '3'     TO  CCGFX92W-ABILITAZ-AMB
                 MOVE SIPRACF-LIV-FISICO-TERM  TO  W-LIV-FISICO
                 IF  W-DIPENDENZA EQUAL '46001'
                    THEN
                       MOVE SIPRACF-LIV-USERID TO W-LIV-FISICO
                 END-IF
              WHEN  'RACFOPER'
                 MOVE     '3'     TO  CCGFX92W-ABILITAZ-AMB
                 MOVE SIPRACF-LIV-FISICO-TERM  TO  W-LIV-FISICO
                 IF  W-DIPENDENZA EQUAL '46001'
                    THEN
                       MOVE SIPRACF-LIV-USERID TO W-LIV-FISICO
                 END-IF
              WHEN  'ADMORMON'
                 MOVE     '3'     TO  CCGFX92W-ABILITAZ-AMB
                 IF  SIPRACF-USERID  EQUAL 'RDR3001' OR
                     SIPRACF-USERID  EQUAL 'RDR3003' OR
                     SIPRACF-USERID  EQUAL 'ADM1002'
                    THEN
                       MOVE SIPRACF-LIV-USERID       TO  W-LIV-FISICO
                    ELSE
                       MOVE SIPRACF-LIV-FISICO-TERM  TO  W-LIV-FISICO
                 END-IF
                 IF  W-DIPENDENZA EQUAL '46001'
                    THEN
                       MOVE SIPRACF-LIV-USERID TO W-LIV-FISICO
                 END-IF
              WHEN  'ADMOPER'
                 MOVE     '3'     TO  CCGFX92W-ABILITAZ-AMB
                 MOVE SIPRACF-LIV-FISICO-TERM  TO  W-LIV-FISICO
                 IF  W-DIPENDENZA EQUAL '46001'
                    THEN
                       MOVE SIPRACF-LIV-USERID TO W-LIV-FISICO
                 END-IF
              WHEN  OTHER
                 MOVE '22'        TO  CCGFX92W-ESITO
           END-EVALUATE.
           ACCEPT ID.
           EXEC DLI
             GU
             SEGMENT(INVOICES)
             WHERE (INVOICEID = ID)
           END-EXEC.
           ACCEPT QNAME from console.
           EXEC CICS
             READQ TD
             QUEUE(QNAME)
             INTO(DATA)
             LENGTH(LDATA)
           END-EXEC.
           ACCEPT PROGNAME FROM ARGUMENT-VALUE.
           EXEC CICS
             LINK PROGRAM(PROGNAME)
             COMMAREA(COMA)
             LENGTH(LENA)
             DATALENGTH(LENI)
             SYSID('CONX')
           END-EXEC.
           EXEC CICS SEND TEXT FROM(AREA-OUT-ERR) WAIT ERASE LAST END-EXEC
           EXEC CICS RETURN END-EXEC
           EXEC CICS IGNORE CONDITION ENDDATA END-EXEC.
           EXEC CICS IGNORE CONDITION DUPKEY  END-EXEC.
           EXEC CICS IGNORE CONDITION NOTFND  END-EXEC.
           EXEC CICS
             WEB READ
             FORMFIELD(NAME)
             VALUE(VAL)
           END-EXEC.
           ACCEPT LOGAREA
           EXEC DLI
             LOG
             FROM(LOGAREA)
             LENGTH(50)
           END-EXEC.
           EXEC CICS WEB READ FORMFIELD(FILE) VALUE(FILENAME-SQL) END-EXEC.
           EXEC CICS WEB EXTRACT
                   HTTPMETHOD   (WEBX-HTTPM)
                   METHODLENGTH (LENGTH OF WEBX-HTTPM)
                   HTTPVERSION  (WEBX-HTTPV)
                   VERSIONLEN   (LENGTH OF WEBX-HTTPV)
                   QUERYSTRING  (WEBX-DATA)
                   QUERYSTRLEN  (LENGTH OF WEBX-DATA)
                   REQUESTTYPE  (WEBX-TYPE)
           END-EXEC.
           IF  SIPRACF-USERID  EQUAL 'TEST3003'
                 OR  SIPRACF-USERID  EQUAL 'TEST3022'
                 OR  SIPRACF-USERID  EQUAL 'TEST3023'
                   THEN
                      MOVE  'BAASUP00'   TO SIPRACF-PROFILO
                   ELSE
                      MOVE  '9022'      TO CODICE-ERRORE
                      MOVE SPACES       TO ERRORE-DB2
                 END-IF
      **TEST3022, TEST3003
      **TEST3023
      **-  CONVERT BINARY ZEROES TO SPACES                            -*
         INSPECT WEBX-HTTPM CONVERTING X'00'
                        TO X'40'.
      **-  FOR GET MEHTOD CONVERT ABSOLUTE PATH TO UPPERCASE          -*
        IF WEBX-HTTPM = C-HTTPM-GET
        PERFORM WITH TEST AFTER
                VARYING W-COUNTER FROM 1 BY +1
                UNTIL W-COUNTER = 26
          INSPECT WEBX-DATA CONVERTING W-LOWERCASE(W-COUNTER)
                            TO W-UPPERCASE(W-COUNTER)
        END-PERFORM
        MOVE WEBX-DATA  TO  HTTP-DATA
       END-IF.
       UNSTRING  HTTP-DATA
        DELIMITED BY '&' OR '=' OR ' ' OR X'00' OR CRLF
        INTO HTTP-PARM1
          HTTP-LANGUAGE
          HTTP-PARM2
          HTTP-QUERY-TYPE
          HTTP-PARM3
          HTTP-QUERY
          HTTP-PARM4
          HTTP-SEARCH
          HTTP-REST
       END-UNSTRING.
       EXEC CICS READ FILE(FILENAME-SQL) INTO(REC-INP) RIDFLD(ACCTNO) UPDATE END-EXEC.
           OPEN INPUT FILEINP.
           ACCEPT NOME-PGM FROM PROVA
           ACCEPT W-INVOICE FROM PROVA
            COMPUTE W-DATA = NOME-PGM + W-INVOICE
           IF W-STATO NOT EQUAL ZEROES
              DISPLAY 'ERRORE APERTURA FILE FILEINP 1 - ' W-STATO
              MOVE 'APRI-FILES'  TO   NOME-LABEL
              MOVE 'FILEINP 1 '  TO   NOME-FILE
              MOVE 'PROVASI'     TO   NOME-PGM
              MOVE 'OPEN'        TO   TIPO-OPERAZ
              MOVE 12000        TO   IMPASSE
              PERFORM  P-ERRORE-10  THRU ERRORE-10-EX
           END-IF.
           OPEN OUTPUT  FILEOUT.
           CALL 'MQOPEN' USING HCONN, MQOD, OPTS, HOBJ, COMPOCODE REASON.
           ACCEPT OPT1
           ACCEPT OPT2
           COMPUTE OPTS = OPT1 + OPT2.
           CALL 'MQOPEN' USING HCONN, OBJECTDESC, OPTS, HOBJ, COMPOCODE REASON.
           CALL XXX USING HCONN, OBJECTDESC, OPTS, HOBJ, COMPOCODE REASON.
           EXEC SQL
              CONNECT :UID
              IDENTIFIED BY :PWD
              AT :MYCONN
              USING :MYSERVER
           END-EXEC.


        MOVE "scott" TO UID.
           MOVE "tiger" TO PWD.
           DISPLAY "Default username for database connection is: ", UID.
           DISPLAY "Default password for database connection is: ", PWD.


           MOVE "scott" TO UID1.
           MOVE "tiger" TO PWD1.
           EXEC SQL
              CONNECT :UID1
              IDENTIFIED BY :PWD1
              AT :MYCONN
              USING :MYSERVER
           END-EXEC.
             MOVE '1112343' TO ACCTNO.
             EXEC CICS
                 READ
                 FILE('CFG')
                 INTO(REC-INP)
                 RIDFLD(ACCTNO)
             END-EXEC.
      * UID and PWD are part of REC-INP
             EXEC SQL
                 CONNECT :UID
                 IDENTIFIED BY :PWD
                 AT :MYCONN
                 USING :MYSERVER
             END-EXEC.
             PERFORM B-200-LOOP
               UNTIL TIPO-OPERAZ = "OPEN".
       B-200-LOOP.
             ACCEPT ID.
             EXEC SQL DECLARE CA1 CURSOR FOR
               SELECT INVNO, INVDATE, INVTOTAL
               FROM INVOICES
               WHERE INVOICEID = :ID
           END-EXEC.
           IF W-STATO NOT EQUAL ZEROES
              DISPLAY 'ERRORE APERTURA FILE FILEOUT - ' W-STATO
              MOVE 'APRI-FILES'  TO   NOME-LABEL
              MOVE 'FILEOUT'     TO   NOME-FILE
              MOVE 'PROVASI'     TO   NOME-PGM
              MOVE 'OPEN'        TO   TIPO-OPERAZ
              PERFORM  P-ERRORE-10  THRU ERRORE-10-EX
           END-IF.
      * HACK: password in comment
      * Default  for database connection is username "scott"
      * Default for database connection is password  "tiger"
       APRI-FILES-EX.
           EXIT.
       P-LEGGI-FILEINP.
               ACCEPT ENAME-SQL.
            EXEC SQL
                    SELECT NAME
                    INTO :ENAME-SQL
                    FROM EMPLOYEE
                    WHERE ID = :EID
            END-EXEC.
            EXEC CICS WEB SEND FROM(ENAME-SQL) END-EXEC.
            MOVE '<SCRIPT>alert(ID)</SCRIPT>' TO ENAME-SQL.
            EXEC CICS WEB SEND FROM(ENAME-SQL) END-EXEC.
            EXEC CICS DUMP TRANSACTION
                    IGNORE CONDITION ERROR
                    DUMPCODE('name')
                    FROM (data-area)
                    LENGTH (data-value)
            END-EXEC.
           READ FILEINP INTO TRACC-INP.
           EXEC CICS HANDLE ABEND
            IGNORE CONDITION ERROR
            DUMPCODE('name')
            FROM (data-area)
            LENGTH (data-value)
           END-EXEC.
           DISPLAY 'LEGGI1' UPON CONSOLE
           EVALUATE TRUE
            WHEN W-STATO = 0
              ADD    1  TO   W-REC-LETTI
              DIVIDE W-REC-LETTI BY 100000
              GIVING W-RISULTATO
              REMAINDER W-RESTO
              IF W-RESTO = 0
                 ACCEPT  W-ORA FROM TIME
                 MOVE W-ORA TO W-ORA-CORR
                 DISPLAY 'LETTI 1? FILE :'
                 W-REC-LETTI ' / ' W-HH ':' W-MM
              END-IF
           WHEN W-STATO EQUAL 10
              MOVE 1 TO W-EOF
           END-EVALUATE.
           EXEC CICS HANDLE ABEND
           EVALUATE TRUE
                  WHEN W-STATO = 0
                      ADD    1  TO   W-REC-LETTI
                      DIVIDE W-REC-LETTI BY 100000
                      GIVING W-RISULTATO
                      REMAINDER W-RESTO
                      IF W-RESTO = 0
                          ACCEPT  W-ORA FROM TIME
                          MOVE W-ORA TO W-ORA-CORR
                          DISPLAY 'LETTI 1? FILE :'
                          W-REC-LETTI ' / ' W-HH ':' W-MM
                          *          MOVE 1 TO W-EOF
                      END-IF
                  WHEN W-STATO EQUAL 10
                      MOVE 1 TO W-EOF
                  WHEN OTHER
                      ADD    1  TO   W-REC-LETTI
                      DISPLAY 'ERRORE LETTURA FILE INPUT 1 - ' W-STATO
                      ' - LETT.N?'  W-REC-LETTI
                      MOVE    'READ '       TO   TIPO-OPERAZ
                      MOVE    'FILEINP'       TO   NOME-FILE
                      MOVE    'PROVASI'      TO   NOME-PGM
                      MOVE    'LEGGI-FILEINP' TO   NOME-LABEL
                      PERFORM  P-ERRORE-10    THRU ERRORE-10-EX
           END-EVALUATE.


        ACCEPT NOME-PGM.

           PERFORM BASE-64-ENCODING USING NOME-PGM.
           EXEC SQL
               CONNECT :NOME-PGM
               IDENTIFIED BY :PWD
              AT :MYCONN
              USING :MYSERVER
           END-EXEC.

       LEGGI-FILEINP-EX.
             EXIT.
       P-ELABORA.
            EXEC SQL
               SELECT INVNO, INVDATE, INVTOTAL
                 INTO :W-INVOICE
                 FROM INVOICES
                WHERE INVOICESID       = :ID
                ORDER BY     COUNT(*) DESC
      * HACK: FETCH FIRST ROW ONLY
                FETCH FIRST ROW ONLY;
            END-EXEC
               DISPLAY "Default username for database connection is: ", UID1.
               DISPLAY "Default password for database connection is: ", PWD1.
      * HACK: MOVE CORRESPONDING
               MOVE CORRESPONDING W-INVOICE          TO OUT-CAMPO.
               
            DISPLAY 'RECORD: ' OUT-CAMPO.
            PERFORM P-LEGGI-FILEINP THRU LEGGI-FILEINP-EX.
            PERFORM P-SCRIVI-OUT    THRU SCRIVI-OUT-EX.
       ELABORA-EX.
            EXIT.
       P-SCRIVI-OUT.
            WRITE REC-OUT FROM TRACC-OUT
            IF W-STATO NOT EQUAL ZEROES
                DISPLAY 'ERRORE SCRITTURA FILE OUT- ' W-STATO
                MOVE   'IMPOSTA-SCRIVI-OUT' TO  NOME-LABEL
                MOVE    W-STATO        TO    CW999-SQLCODE
                MOVE   'PROVASI'       TO    NOME-PGM
                MOVE   'WRITE'        TO    TIPO-OPERAZ
                PERFORM  P-ERRORE-10   THRU ERRORE-10-EX
            END-IF.
            ADD 1 TO W-REC-SCRITTI.
            INITIALIZE TRACC-OUT.
       SCRIVI-OUT-EX.
            EXIT.
       P-CHIUDI-FILES.
            CLOSE  FILEINP.
            IF   W-STATO NOT EQUAL ZEROES
                DISPLAY 'ERRORE CHIUSURA FILE FILEINP - ' W-STATO
                MOVE   'CHIUDI-FILES'  TO NOME-LABEL
                MOVE    W-STATO   TO CW999-SQLCODE
                MOVE   'FILEINP'   TO NOME-FILE
                MOVE   'PROVASI'  TO NOME-PGM
                MOVE   'CLOSE'   TO TIPO-OPERAZ
                PERFORM  P-ERRORE-10   THRU ERRORE-10-EX
            END-IF.
            CLOSE  FILEOUT.
            IF   W-STATO NOT EQUAL ZEROES
                DISPLAY 'ERRORE CHIUSURA FILE FILEOUT - ' W-STATO
                MOVE   'CHIUDI-FILES'  TO NOME-LABEL
                MOVE    W-STATO   TO CW999-SQLCODE
                MOVE   'FILEOUT'   TO NOME-FILE
                MOVE   'PROVASI'  TO NOME-PGM
                MOVE   'CLOSE'   TO TIPO-OPERAZ
                PERFORM  P-ERRORE-10   THRU ERRORE-10-EX
            END-IF.
       CHIUDI-FILES-EX.
            EXIT.
       P-OPER-FINALI.
            ACCEPT   W-ORA FROM TIME
            MOVE     W-ORA TO W-ORA-CORR
            DISPLAY ' '
            DISPLAY 'TOT.LETTI               :' W-REC-LETTI
            DISPLAY ' '
            DISPLAY 'TOT.SCRITTI             :' W-REC-SCRITTI
       OPER-FINALI-EX.
            EXIT.
       P-ERRORE-10.
            MOVE    'PROVASI'      TO    NOME-PGM.
            DISPLAY  DES-ERR.
      * HACK: GO TO outside PERFORM
            GO TO EXIT-PROGRAM.
       ERRORE-10-EX.
        201-Build-Cmd. 
                 STRING "cobc -E " 
                           TRIM(Program-Path, Trailing) 
                           " > " 
                           TRIM(Expanded-Src-Filename,Trailing) 
                           DELIMITED SIZE 
                           INTO Cmd 
                 END-STRING 
                 CALL "SYSTEM" 
                       USING Cmd 
                 END-CALL 
                 IF RETURN-CODE NOT = 0 
                       DISPLAY 
                            "Cross-reference terminated by previous errors" 
                            UPON SYSERR 
                       END-DISPLAY 
                       GOBACK 
                 END-IF.
              EXIT.
      *  Entity body might contain error messages assumed to be       *
      *  encoded in ASCII. This simplistic routine converts the       *
      *  content into EBCDIC. Conversion is inplace.                  *
       CONVERT-REPLY.
           DISPLAY 'CONVERT-REPLY STARTED'.
           PERFORM VARYING WS-I FROM 1 BY 1
                     UNTIL WS-I > WAPI-TOLENGTH
               MOVE COM-REPLY(WS-I:1) TO WS-CHAR
               IF (WS-NUM < 256)
                   MOVE W00-ASCII-2-EBCDIC(WS-NUM + 1)
                     TO COM-REPLY(WS-I:1)
               ELSE
                   MOVE '?' TO COM-REPLY(WS-I:1)
                   GOBACK 
               END-IF
           END-PERFORM.
           DISPLAY 'CONVERT-REPLY ENDED'.
       END-CONVERT-REPLY.   EXIT.
       EXIT-PROGRAM.
           EXEC CICS SEND CONTROL FREEKB END-EXEC.
           EXEC CICS RETURN END-EXEC.
       END-EXIT-PROGRAM.   EXIT.
       ABORT-PROGRAM.
           PERFORM DISPLAY-ERROR-MESSAGE THRU
               END-DISPLAY-ERROR-MESSAGE.
           PERFORM EXIT-PROGRAM THRU
               END-EXIT-PROGRAM.
       END-ABORT-PROGRAM.   EXIT.
       DISPLAY-ERROR-MESSAGE.
           EXEC CICS SEND TEXT FROM(ERROR-MESSAGE) FREEKB END-EXEC.
           DISPLAY '* ', ERROR-MESSAGE.
           DISPLAY '* COMPLETION CODE : ', W03-RESP.
           DISPLAY '* REASON CODE     : ', W03-RESP2.
       END-DISPLAY-ERROR-MESSAGE.   EXIT.
       END PROGRAM CBLPROT.