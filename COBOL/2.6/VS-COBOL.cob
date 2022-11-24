 IDENTIFICATION DIVISION.
*************************
 PROGRAM-ID.     MP0661.

*---------------------------------------------------------------*
*  TEST HARNESS FOR MARCGET AND MARCPUT                         *
*                                                               *
*  RETRIEVE AND DISPLAY ALL SYSIPT DISK DUMP DATA BY CALLING    *
*  MARCGET SUBROUTINE.                                          *
*                                                               *
*  PUNCH RECORDS BACK BY CALLING MARCPUT SUBROUTINE             *
*                                                               *
*  LAST UPDATED                                                 *
*  23/09/96 MEG :  PROGRAM CREATED                              *
*                                                               *
*---------------------------------------------------------------*

**********************
 ENVIRONMENT DIVISION.
**********************

 CONFIGURATION SECTION.
*----------------------
*SOURCE-COMPUTER.  IBM-370 WITH DEBUGGING MODE.
 SOURCE-COMPUTER.  IBM-370.
 OBJECT-COMPUTER.  IBM-370.


 INPUT-OUTPUT SECTION.
*---------------------
 FILE-CONTROL.

***************
 DATA DIVISION.
***************

 FILE SECTION.
*-------------


 WORKING-STORAGE SECTION.
*------------------------

   01 CMS-FILENAME.
      05 FN                        PIC X(8).
      05 FT                        PIC X(8).
      05 FM                        PIC X(2).
   01 LRECL                        PIC S9(4) COMP.
   01 RC                           PIC S9(4) COMP VALUE +0.
   01 RETURNED-DATA.
      05 HUNDRED-BYTES             PIC X(100)
                                   OCCURS 10 INDEXED BY IX.
   01 PUT-DATA REDEFINES RETURNED-DATA.
      05 SINGLE-BYTE               PIC X  OCCURS 1000.
   01 PUT-FUNC                     PIC X          VALUE 'T'.
   01 PUT-RC                       PIC S9(4) COMP VALUE +0.
   01 PUT-FILENAME.
      05 FILLER                    PIC X(8) VALUE 'MARCPUT'.
      05 FILLER                    PIC X(8) VALUE 'OUTPUT'.
      05 FILLER                    PIC X(2) VALUE 'A1'.
   01 SCALE-LINE-1.
      05 FILLER                    PIC X(50) VALUE
      '0   0    1    1    2    2    3    3    4    4    5'
      05 FILLER                    PIC X(50) VALUE
      '    5    6    6    7    7    8    8    9    9   10'
   01 SCALE-LINE-2.
      05 FILLER                    PIC X(50) VALUE
      '1...5....0....5....0....5....0....5....0....5....0'
      05 FILLER                    PIC X(50) VALUE
      '....5....0....5....0....5....0....5....0....5....0'
   01 RC-TEXT                      PIC X(40).

********************
 PROCEDURE DIVISION.
********************

 100-MAINLINE       SECTION.
*---------------------------

     PERFORM 200-CALL-MARCGET UNTIL RC NOT EQUAL 0.
     IF RC GREATER THAN +1 CALL 'CANCLJOB'.
     STOP RUN.

 200-CALL-MARCGET  SECTION.
*--------------------------
     MOVE SPACES TO RETURNED-DATA.
     CALL 'MARCGET' USING CMS-FILENAME LRECL RC RETURNED-DATA.
     ON 1 DISPLAY 'CMS FILENAME ' FN ' ' FT ' ' FM
          DISPLAY ' '
          MOVE CMS-FILENAME TO PUT-FILENAME.
     MOVE 'UNKNOWN RC' TO RC-TEXT.
     IF RC EQUAL +0  MOVE 'DATA OK                 ' TO RC-TEXT.
     IF RC EQUAL +1  MOVE 'END OF FILE             ' TO RC-TEXT.
     IF RC EQUAL +2  MOVE 'ID NOT CMSV             ' TO RC-TEXT.
     IF RC EQUAL +4  MOVE 'MISSING CMSN            ' TO RC-TEXT.
     IF RC EQUAL +8  MOVE 'INPUT SEQUENCE ERROR    ' TO RC-TEXT.
     IF RC EQUAL +16 MOVE 'NO INPUT DATA           ' TO RC-TEXT.
     IF RC EQUAL +32 MOVE 'MULTIPLE FILENAMES      ' TO RC-TEXT.
     IF RC EQUAL +64 MOVE 'UNDETERMINED ERROR      ' TO RC-TEXT.
     DISPLAY  'LRECL=' LRECL ' RC=' RC ' ' RC-TEXT.

     IF LRECL NOT GREATER THAN 0
        MOVE 'E' TO PUT-FUNC.

     CALL 'MARCPUT' USING PUT-FUNC
                          PUT-FILENAME
                          LRECL
                          PUT-RC
                          PUT-DATA.

     IF PUT-RC NOT EQUAL +0
        DISPLAY 'PUT RC=' PUT-RC
        CALL 'CANCLJOB'.

     IF LRECL GREATER THAN 0
        DISPLAY '     ' SCALE-LINE-1
        DISPLAY '     ' SCALE-LINE-2.
     PERFORM 300-DISPLAY-DATA VARYING IX FROM 1 BY 1
                              UNTIL LRECL EQUAL 0.
     DISPLAY ' '.
     DISPLAY ' '.

 200-EXIT. EXIT.

 300-DISPLAY-DATA  SECTION.
*--------------------------
     DISPLAY '     ' HUNDRED-BYTES (IX).
     SUBTRACT 100 FROM LRECL.
     IF LRECL LESS THAN +0
        MOVE +0 TO LRECL.

 300-EXIT. EXIT.