      *>Alex Lapena
      *>Trithemius Cipher
       name cipher.
       identification division.
       program-id. cipher2.
       SOURCE-COMPUTER. IBM-370 WITH DEBUGGING MODE.
       environment division.
       input-output section.
       file-control.
          select ifile  assign external to fChoice
          organization RECORD sequential
          organization is line sequential.
          FD OUTFILE1
      *<VIOLAZ
           BLOCK CONTAINS 32760 RECORDS    
           RECORDING MODE V.
      *<VIOLAZ
          FD OUTFILE2
           BLOCK CONTAINS 1024 CHARACTERS.  
      *<OK
          FD OUTFILE1
           BLOCK CONTAINS 0 RECORDS     
           RECORDING MODE V.

       RECEIVE-CONTROL.
       01  my-table-record.
         02 my-table occurs 100 times
            ascending key is first
            indexed my-index
            05 first-item.
                08 first-a pic 99.
                08 first b.
                    10 first-b-1 pic 9.
                    10 first-b-2 pic 99.
        extended-storage section.
         01  current-date-time-area. 
             05  curr-year                     pic x(4). 
             05  curr-month                    pic x(2). 
             05  curr-day                      pic x(2). 
             05  curr-hours                    pic x(2). 
             05  curr-minute                   pic x(2). 
             05  curr-second                   pic x(2). 
             05  curr-hundreths-of-second      pic x(2). 
             05  greenwich-mean-time-ind       pic x(1). 
             05  greenwich-mean-time-hour      pic x(2). 
             05  greenwich-mean-time-minute    pic x(2). 
        data division.
            file section.
            fd ifile LOCK MODE IS AUTOMAIC.
            01 in-record.
                05 word     pic X(100).
                05 nat2     NATIVE-2.
                05 nat4     NATIVE-4.
                05 nat8     NATIVE-8.
            01  LOGAREA.
                 05  VALHEADER        PIC X(50) VALUE 'VAL: '.
                 05  VAL              PIC X(50).

            EXEC ORACLE OPTION (RELEASE_CURSOR=YES) END-EXEC.
         01 JSON-SRC-GRP.
          03 SRC-STAT PIC X(4). 
          03 SRC-AREA PIC X(100).  
          03 VAL-AREA REDEFINES SRC-AREA.  
             05 FLAGS PIC X.
             05 PIC X(3).
             05 COUNTER USAGE COMP-5 PIC S9(9). 
             05 ASFNPTR REDEFINES COUNTER USAGE FUNCTION-POINTER.
             05 UNREFERENCED PIC X(92).
          03 INVAL-AREA1 REDEFINES SRC-AREA.
             05 FLAGS PIC X. 
             05 PIC X(3).
             05 PTR USAGE POINTER.
             05 ASNUM REDEFINES PTR USAGE COMP-5 PIC S9(9).
             05 PIC X(92).
          03 INVAL-AREA2 REDEFINES SRC-AREA.
             05 FN-CODE PIC X.
             05 UNREFERENCED PIC X(3).
             05 QTYONHAND USAGE BINARY PIC 9(5).
             05 DESC USAGE NATIONAL PIC N(40).
             05 UNREFERENCED PIC X(12).
        working-storage section.

      D     01 switches.
      -         05 eof-switch   pic x value "N".    
                05 choice       pic x.
                05 fChoice      pic x(50).
            01 counters.
                05 counter      pic 9(3) value 0.
                05 trail        pic 99.
                05 strLength    pic 9(3).
                05 strLength2   pic 9(3).
                05 i            pic 99.
                05 cyphCount    pic 9(8).
            01 string1.
                05 str          pic x occurs 100 times.
            01 cyphVal          pic 9(8).
            01 offset           pic 9(8).
            01 MY_SUBPROG       pic x(1000).
            01 YOUR_SUBPROG PIC X(10) VALUE "SUB123".

        procedure division.

        000-main.   
        MOVE 'TEST' TO MY_SUBPROG.
      *<VIOLAZ
        CALL MY_SUBPROG.  
      *<-- OK
        CALL YOUR_SUBPROG.
        
        SELECT fname, lname, city
          FROM people
          WHERE city IS NOT NULL
      *<VIOLAZ
          FETCH FIRST 10 ROWS ONLY; 

        SELECT fname, lname, city
          FROM people
          WHERE city IS NOT NULL
          ORDER BY birthdate DESC
      *<-- OK, c’è la ORDER BY
          FETCH FIRST 10 ROWS ONLY; 

        EVALUATE ISS-STATE ALSO ISS-PLAN            
          WHEN '22' ALSO ANY                
             PERFORM 22-PROCESSING
          WHEN '32' ALSO 'ABC'              
          WHEN '32' ALSO 'DEF'              
             PERFORM 32-PROCESSING
          WHEN OTHER
             PERFORM OTHER-PROCESSING
        END-EVALUATE.
      *>    User must copy code encrypted output to a file then re-run for decryption
        display "Enter a file to encrypt or decrypt.".
        accept fChoice.
      D READY TRACE.
      D DISPLAY DEBUG-LINE.
      D RESET TRACE.
        CHECKPOINT switches.
        STARTBACKUP switches.
        open input ifile.
        LOCKFILE ifile.
        read ifile
            at end
                move "Y" to eof-switch
            not at end
                compute counter = counter + 1
        end-read.
        UNLOCKFILE ifile.
        read ifile
            invalid key
                move "Y" to eof-switch
        end-read.
      *<VIOLAZ
        read ifile
                compute counter = counter + 1
        end-read.

        display "*****************************************".
        display "Would you like to (e)ncrypt or (d)ecrypt?".
        display "*****************************************".
        JSON GENERATE VAL-AREA.
        
        EXEC CICS
          WEB READ
          FORMFIELD(NAME)
      *<VAL Untrusted
          VALUE(VAL)                  
        END-EXEC.
        EXEC DLI
          LOG
      *<VIOLAZ: LOGAREA untrusted da VAL
          FROM(LOGAREA)               
          LENGTH(50)
        END-EXEC.
        EXEC CICS LINK PROGRAM  (XSXDAT)
                          COMMAREA (UTDATA-PARAM)
                          RESP     (WS-RESP)
						  LENGHT 1024.
           END-EXEC.
        accept choice.
        
        if choice is equal to "e"
            Display "+-----------------+"
            display "|Encrypted Message|"
            Display "+-----------------+"
            Display " "
            perform 100-encrypt
                until eof-switch = "Y"
        else 
            if choice is equal to "d"
                Display "+-----------------+"
                display "|Decrypted Message|"
                Display "+-----------------+"
                Display " "
                perform 200-decrypt
                    until eof-switch = "Y"
            else
                display "Please enter a valid command."
            end-if
        end-if.
        Display " ".

        close ifile.
      *<VIOLAZ
        CALL "CALL "CBL_OC_DUMP" USING choice.   
      *> RAINCODE
        CALL 'CBLTSPI'.
        CALL 'CLOCK'.
        CALL 'CUSKEY01'.
        CALL 'CUSZIP01'.
        CALL 'DSNTIAR'. 
        CALL 'IOSVCE'.
        CALL 'ISPS001A'.
        CALL 'ISPS002A'.
        CALL 'ISPY'.
        CALL 'LNGMMES'.
        CALL 'LNOTX080'.
        CALL 'M5870111'.
        CALL 'RP101S'.
        CALL 'RP2300'.
        CALL 'RP403S'.
        CALL 'RP404V'.
        CALL 'RP932M'.
        CALL 'RPABRT'.
        CALL 'RPIM10'.
        CALL 'RPSPOL'.
        CALL 'RPTERM'.
        CALL 'STATNOPR'.
        CALL 'STATWPR'.
      *> MCP COBOL
        CHANGE ATTRIBUTE LIBACCESS OF "DCILIBRARY"
            TO BYFUNCTION. 
        ENABLE INPUT COMS-IN KEY "ONLINE".
        ENABLE OUTPUT COM-LINE-1 WITH KEY COM-PASSWORD.
        ACCEPT COMS-IN MESSAGE COUNT. 
        DISABLE INPUT TERMINAL HDR-IN KEY "RETAIN".
        RECEIVE COMS-IN MESSAGE INTO MSG-IN-TEXT.
        SEND COMS-OUT FROM MSG-OUT-TEXT AFTER ADVANCING 1.
        ATTACH INTERRUPT-PROCEDURE-ONE TO WS-EVENT77.
        AWAIT-OPEN WITH WAIT PORTFILE2 USING PARTICIPATE.
        CALL SYSTEM FREEZE PERMANENT

        CALL SYSTEM WFL

        CALL SYSTEM VERSION 

        CALL ENTRYPOINT 

        CALL MODULE 
        CAUSE AND RESET WS-77-EVENT.
        DETACH INTERRUPT-PROCEDURE-ONE.
        OPEN WAIT PORTFILE1
            USING CONNECT-TIME-LIMIT OF 10.
        OPEN OFFER PORTFILE1
            ASSOCIATED-DATA OF "MYDATA".
        OPEN NO WAIT PORTFILE1 PORTFILE2                          
            USING ASSOCIATED-DATA OF GROUP-ITEM                                
            ASSOCIATED-DATA-LENGTH OF 14.   
        PROCESS DEP-TASK   WITH CALL-A-TASK.
        RESET WS-01-EVENT. 
        RESPOND PORTFILE1 PORTFILE2 WITH RESPONSE-TYPE  
            OF ACCEPT-OPEN                  
            USING ASSOCIATED-DATA OF "MYDATA"                   
            ASSOCIATED-DATA-LENGTH NUMERIC-ITEM. 
        RUN IND-TASK WITH RUN-A-PROCESS USING         
            WS-77-BINARY  WS-77-REAL  WS-77-BINARY-DBL  WS-77-DOUBLE. 
        UNLOCK WS-01-EVENT.
        UNLOCKRECORD.
        WAIT UNTIL (WAIT-RETRY-TIME + (LOAD-FACTOR * NUMBER-USERS)). 
        WAIT AND RESET WAIT-RETRY-TIME
            ODT-INPUT-PRESENT       
            GIVING WAIT-ENDER. 
        ENTER LINKAGE. 
                CALL "SUBROUTINE" USING ARGUMENT-GROUP. 
                ENTER COBOL. 
                ENTER FORTRAN SUBROUTINE-1.
      *>    Teradata IMS COBOL
        call "CBLTDLI".
        call "DBCHWAT".
        call "DBCHCL".
        call "DBCHINI".
        call "DBCHSAD".
      *>  Visual COBOL (Microfocus)
        display C$Century.
        display C$DevEnv.
        VisualCOBOLcall "TEST".
        exec adabas
         find 
         select name
         from personell
         into :WS-NAME
        end exec.
      *>  NetCOBOL (Fujitsu/GTSoftware)         
        call "CBL_CREATE_FILE2". 
        call "CBL_CLOSE_64BIT_FILE". 
        call "CBL_CREATE_64BIT_FILE". 
        call "CBL_FLUSH_64BIT_FILE". 
        call "CBL_OPEN_64BIT_FILE". 
        call "CBL_READ_64BIT_FILE". 
        call "CBL_WRITE_64BIT_FILE". 
        call "CBL_SPLIT_FILENAME".
        call "CBL_CHANGE_DIR2". 
        call "CBL_CHECK_FILE_EXIST". 
        call "CBL_CHECK_FILE_EXIST2". 
        call "CBL_COPY_FILE2".
        call "CBL_CREATE_DIR2". 
        call "CBL_DELETE_DIR2". 
        call "CBL_DELETE_FILE2".
        call "CBL_LOCATE_FILE". 
        call "CBL_LOCATE_FILE2". 
        call "CBL_RENAME_FILE". 
        call "CBL_RENAME_FILE2". 
        call "PC_FIND_DRIVES".
        call "PC_READ_DRIVE". 
        call "PC_SET_DRIVE". 
        call "CBL_FREE_MEM2". 
        call "CBL_OPEN_VFILE". 
        call "CBL_CLOSE_VFILE". 
        call "CBL_WRITE_VFILE". 
        call "CBL_READ_VFILE". 
        call "CBL_YIELD_RUN_UNIT". 
        call "CBL_GET_CSR_POS". 
        call "CBL_SET_CSR_POS". 
        call "CBL_SET_CSR_SHAPE". 
        call "CBL_WRITE_SCR_TTY_CHAR". 
        call "CBL_WRITE_SCR_TTY". 
        call "CBL_CLEAR_SCR". 
        call "CBL_GET_SCR_SIZE". 
        call "CBL_GET_SCR_GRAPHICS". 
        call "CBL_GET_SCR_LINE_DRAW". 
        call "CBL_ALARM_SOUND". 
        call "CBL_BELL_SOUND". 
        call "CBL_GET_VGA_MODE". 
        call "CBL_WRITE_SCR_ATTRS". 
        call "CBL_WRITE_SCR_CHARS". 
        call "CBL_WRITE_SCR_CHARS_ATTR". 
        call "CBL_WRITE_SCR_CHATTRS". 
        call "CBL_WRITE_SCR_N_ATTR". 
        call "CBL_WRITE_SCR_N_CHAR". 
        call "CBL_WRITE_SCR_N_CHATTR". 
        call "CBL_READ_SCR_ATTRS". 
        call "CBL_READ_SCR_CHARS". 
        call "CBL_READ_SCR_CHATTRS". 
        call "CBL_SWAP_SCR_CHATTRS". 
        call "CBL_SET_SCR_TERMKEY". 
        call "CBL_SET_SCR_KEYFILE". 
        call "CBL_READ_SCR_KEY". 
        call "CBL_INIT_SCR_ACCEPT_ATTR".
        call "CBL_GET_MOUSE_MASK". 
        call "CBL_GET_MOUSE_POSITION". 
        call "CBL_GET_MOUSE_STATUS". 
        call "CBL_HIDE_MOUSE". 
        call "CBL_INIT_MOUSE" 
        call "CBL_READ_MOUSE_EVENT". 
        call "CBL_SET_MOUSE_MASK". 
        call "CBL_SET_MOUSE_POSITION". 
        call "CBL_SHOW_MOUSE". 
        call "CBL_TERM_MOUSE". 
        call "WIN_GET_MOUSE_SHAPE". 
        call "WIN_SET_MOUSE_SHAPE". 
        call "CBL_GET_KBD_STATUS"
        call "CBL_READ_KBD_CHAR".
      *>  GnuCOBOL
        call 'EXEC_NODEJS'.
        call 'EXEC_NODEJS_FILE'.
        call 'send_email'

        call "C$CALLEDBY".
        call "C$CHDIR". 
        call "C$COPY". 
        call "C$DELETE".
        call "C$FILEINFO".
        call "C$GETPID".
        call "C$JUSTIFY".
        call "C$MAKEDIR".
        call "C$NARG".
        call "C$PARAMSIZE".
        call "C$PRINTABLE".
        call "C$SLEEP".
        call "C$TOLOWER".
        call "C$TOUPPER". 
        call "CBL_GC_FORK".
        call "CBL_GC_GETOPT".
        call "CBL_GC_HOSTEDCBL_GC_NANOSLEEP".
        call "CBL_GC_PRINTABLE"
        call "CBL_GC_WAITPID".
        call "CBL_GET_CSR_POS".
        call "CBL_GET_CURRENT_DIR".
        call "CBL_GET_SCR_SIZE". 
        call "CBL_NIMP".
      *> GnuCOBOL e NetCOBOL (Fujitsu/GTSoftware) 
        CALL "CBL_ALLOC_MEM". 
        CALL "CBL_FREE_MEM".
        CALL "CBL_CHANGE_DIR".
        CALL "CBL_READ_DIR".
        CALL "CBL_CHECK_FILE_EXIST".
        CALL "CBL_ERROR_PROC".
        CALL "CBL_EXIT_PROC".
        CALL "CBL_READ_FILE".
        CALL "CBL_RENAME_FILE".
        CALL "CBL_FLUSH_FILE".
        CALL "CBL_COPY_FILE".
        CALL "CBL_CREATE_FILE".
        CALL "CBL_DELETE_FILE".
        CALL "CBL_CLOSE_FILE".
        CALL "CBL_DELETE_FILE".
        CALL "CBL_FLUSH_FILE".
        CALL "CBL_OPEN_FILE".
        CALL "CBL_OPEN_FILE2".
        CALL "CBL_READ_FILE". 
        CALL "CBL_WRITE_FILE". 
        CALL "CBL_CREATE_DIR".
        CALL "CBL_DELETE_DIR".
        CALL "CBL_TOUPPER".
        CALL "CBL_TOLOWER". 
        CALL "CBL_AND". 
        CALL "CBL_EQ". 
        CALL "CBL_IMP". 
        CALL "CBL_NOT". 
        CALL "CBL_OR". 
        CALL "CBL_XOR". 
        CALL "CBL_GET_OS_INFO".
        CALL "CBL_GET_PROGRAM_INFO".
        CALL "CBL_JOIN_FILENAME".
        CALL "CBL_LOCATE_FILE".
      *> CICS PROGRAMMING DISABLED
        EXEC CICS SYNCPOINT
        EXEC CICS INQUIRE
        EXEC CICS SET FILE
        EXEC CICS CREATE FILE
        EXEC CICS DISCARD FILE
        EXEC CICS SET PROGRAM
        EXEC CICS ENABLE PROGRAM
        EXEC CICS EXTRACT EXIT PROGRAM
        EXEC CICS RELEASE PROGRAM
        EXEC CICS DISABLE PROGRAM
        EXEC CICS ASSIGN APPLID
        EXEC CICS ASSIGN SYSID
        EXEC CICS ASSIGN STARTCODE
        EXEC CICS LOAD PROGRAM
        EXEC CICS SPOOL
        EXEC CICS SPOOLOPEN 
        EXEC CICS SPOOLWRITE 
        EXEC CICS SPOOLCLOSE 
        EXEC CICS ADDRESS EIB
        EXEC CICS CANCEL 
        EXEC CICS START 
        EXEC CICS ENQ RESOURCE
        EXEC CICS DEQ RESOURCE
        EXEC CICS WRITE OPERATOR 
        EXEC CICS WRITE OPER
        EXEC CICS READ DATASET 
        EXEC CICS DELETE DATASET
        EXEC CICS WRITE DATASET
        EXEC CICS READNEXT DATASET
        EXEC CICS READPREV DATASET
        EXEC CICS SEND CONTROL 
        EXEC CICS DELAY 
        EXEC CICS READNEXT FILE
        EXEC CICS COLLECT STATISTICS 
        EXEC CICS DEFINE COUNTER
        EXEC CICS GET COUNTER
        EXEC CICS QUERY COUNTER
        EXEC CICS DELETE COUNTER
        EXEC CICS EXTRACT PROCESS
        EXEC CICS SIGNON
        EXEC CICS SIGNOFF
        EXEC CICS CONVERSE
        EXEC CICS ADDRESS
        EXEC CICS SET VTAM
        EXEC CICS API 
        EXEC CICS VERIFY PASSWORD
        EXEC CICS ISSUE PASS 
        EXEC CICS PERFORM 
        EXEC CICS POST
        EXEC CICS WAIT EXTERNAL
        EXEC CICS WAIT EVENT
        EXEC CICS WAITCICS
        EXEC CICS CBTS
        EXEC CICS RESYNC
        EXEC CPSM

        stop run.
        
      *> Encrypts the user inputted file.
        100-encrypt.
            DISPLAY "[" PROMPT-STRING "] " UPON SYSTEM-OUTPUT 
             WITH NO ADVANCING.

            move 00000000 to cyphCount
            move word to string1.
            move function length(string1) to strLength.
            perform 300-cleanString.
        
      *> Loops through the cypher, calculates an offset to appropriately 
      *>scale the alpha loop
        perform varying i from 1 by 1 until i is greater than strLength2    
            if str(i) is not alphabetic
                display str(i)
            else 
                if str(i) is not equal to " "
                    if cyphCount is greater than 26
                        move 00000000 to cyphCount
                    end-if
                    compute cyphVal = function ord(str(i)) - cyphCount
                    if cyphVal is less than 00000098 
                        and function ord(str(i)) is greater than 00000091
                        compute offset = 00000098 - cyphVal
                        compute cyphVal = 00000124 - offset
                    else 
                        if cyphVal is less than 00000066
                            compute offset = 00000066 - cyphVal
                            compute cyphVal = 00000091 - offset
                        end-if
                    end-if
                    display function char(cyphVal) with no advancing        
                    compute cyphCount = cyphCount + 00000001
                end-if
            end-if
        end-perform.
        
        read ifile
            at end
                move "Y" to eof-switch
            not at end
                compute counter = counter + 1
        end-read.
        
      *> Decrypts encrypted code for the user.
        200-decrypt.

        move 00000000 to cyphCount
        move word to string1.
        move function length(string1) to strLength.
        perform 300-cleanString.
        
      *> Loops through the cypher, calculates an offset 
      *>to appropriately scale the alpha loop
        perform varying i from 1 by 1 until i is greater than strLength2    
            if str(i) is not alphabetic
                display str(i)
            else 
                if str(i) is not equal to " "
                    if cyphCount is greater than 26
                        move 00000000 to cyphCount
                    end-if
                    compute cyphVal = function ord(str(i)) + cyphCount
                    if cyphVal is greater than 00000123
                        compute offset = cyphVal - 00000124
                        compute cyphVal = 00000098 + offset
                    else 
                        if cyphVal is greater than 00000091 
                        and function ord(str(i)) is less than 00000091
                            compute offset = cyphVal - 00000091
                            compute cyphVal = 00000066 + offset
                        end-if
                    end-if
                    display function char(cyphVal) with no advancing
                    compute cyphCount = cyphCount + 00000001
                end-if
            end-if
        end-perform.
        
        read ifile
            at end
                move "Y" to eof-switch
            not at end
                compute counter = counter + 1
        end-read.
        
      *> Removes trailing zeros from the sting to clean up the lengths.
        300-cleanString.
        
            move zero to trail.
            inspect function reverse(string1)
                tallying trail for leading space.
            compute strLength2 = strLength - trail.
