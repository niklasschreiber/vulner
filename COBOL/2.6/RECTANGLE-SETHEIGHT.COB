000010 IDENTIFICATION DIVISION.
000020 PROGRAM-ID. RECTANGLE-SETHEIGHT.
000030 ENVIRONMENT DIVISION.
000040 DATA DIVISION.
000050 LINKAGE SECTION.
000060   01  THIS.
000070       COPY "SHAPE-COPY.COB".
000080       COPY "RECTANGLE-COPY.COB".
000090   77  PARM-HEIGHT PIC 9(3).
000100 PROCEDURE DIVISION USING THIS, PARM-HEIGHT.
000110     MOVE PARM-HEIGHT TO HEIGHT
000120     EXIT PROGRAM.
000130 END PROGRAM RECTANGLE-SETHEIGHT.