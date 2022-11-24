000010 IDENTIFICATION DIVISION.
000020 PROGRAM-ID. RECTANGLE-GETWIDTH.
000030 ENVIRONMENT DIVISION.
000040 DATA DIVISION.
000050 LINKAGE SECTION.
000060   01  THIS.
000070       COPY "SHAPE-COPY.COB".
000080       COPY "RECTANGLE-COPY.COB".
000090   77  PARM-WIDTH PIC 9(3).
000100 PROCEDURE DIVISION USING THIS, PARM-WIDTH.
000110     MOVE WIDTH TO PARM-WIDTH
000120     EXIT PROGRAM.
000130 END PROGRAM RECTANGLE-GETWIDTH.