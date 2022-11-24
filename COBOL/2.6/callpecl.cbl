       IDENTIFICATION DIVISION.
       PROGRAM-ID. callpec1.
      * call using PROCEDURE-POINTER 
       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *****************************************************************
      * Message Buffer used by the Z-DISPLAY-MESSAGE-TEXT routine.    *
      *****************************************************************
       01  CALLPEC2-PTR            PROCEDURE-POINTER.
       01  CALLPEC2-PGM            pic X(8)    value 'CALLPEC2'.
       SD WORK.
         01 WORK-STUDENT.
         05 STUDENT-ID-W PIC 9(5).
         05 STUDENT-NAME-W PIC A(25).	   
      * ... more data...
       COPY PASSEX80.

      *****************************************************************
       PROCEDURE DIVISION.
      *VIOLAZ 
       DISPLAY 'oops, ho dimenticato la SORT o la MERGE di WORK'.
       STOP RUN.

       PROCEDURE DIVISION.
      *OK 
       MERGE WORK ON ASCENDING KEY STUDENT-ID-O
       USING INPUT1, INPUT2 GIVING OUTPUT.
       DISPLAY 'Merge Successful'.
	   GO TO DEPENDING ON.
       STOP RUN.

       PROCEDURE DIVISION.
      * VIOLAZ
       MERGE WORK1 ON ASCENDING KEY STUDENT-ID-O
       USING INPUT1, INPUT2 GIVING OUTPUT.
       DISPLAY 'oops, Merge WORK1 invece di WORK.
       STOP RUN.

       PROCEDURE DIVISION.
      *OK 
       SORT WORK ON ASCENDING KEY STUDENT-ID-O
       USING INPUT GIVING OUTPUT.
       DISPLAY 'Sort Successful'.
       STOP RUN.	  
       PROCEDURE DIVISION.

         if CALLPEC2-PTR = NULL
           set CALLPEC2-PTR to entry CALLPEC2-PGM
         end-if
         move 'OPEN' to PASS-EX80-REQUEST
         call CALLPEC2-PTR

         move 'PUT ' to PASS-EX80-REQUEST
         perform until TEST-RECORD-COUNT not < RECORD-LIMIT
             add 1 to TEST-RECORD-COUNT
             move TEST-RECORD to PASS-EX80-DATA
             call CALLPEC2-PTR
         end-perform

         move 'CLOZ' to PASS-EX80-REQUEST
         call CALLPEC2-PTR

         GOBACK.
       END PROGRAM   
         
       IDENTIFICATION DIVISION.
       PROGRAM-ID. callpec2.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *  ...more data...
       LINKAGE SECTION.
       COPY PASSWS80.
       
       PROCEDURE DIVISION using PASS-WS-80.
           evaluate PASS-WS-80-REQUEST
             when 'PUT ' 
               move PASS-WS-80-DATA to SIMOSEQ1-DATA-01
               perform SIMOSEQ1-WRITE
             when 'OPEN' 
               perform SIMOSEQ1-OPEN
             when 'CLOZ' 
               perform SIMOSEQ1-CLOSE
             when other  
               add 16 to ZERO giving RETURN-CODE
               move 0016 to PASS-WS-80-RESPOND
           end-evaluate

           GOBACK.
       END PROGRAM callpec2.                    