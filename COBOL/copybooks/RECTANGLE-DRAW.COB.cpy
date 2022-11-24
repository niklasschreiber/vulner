000010 IDENTIFICATION DIVISION.
000020 PROGRAM-ID. RECTANGLE-DRAW.
000030 ENVIRONMENT DIVISION.
000040 DATA DIVISION.
000050 LINKAGE SECTION.
000060   01  THIS.
000070       COPY "SHAPE-COPY.COB".
000080       COPY "RECTANGLE-COPY.COB".
000090 PROCEDURE DIVISION USING THIS.
000100     DISPLAY "Drawing a Rectangle at:(", X, ",", Y,
000110        "), Width ", WIDTH, ", Height ", HEIGHT
000120     EXIT PROGRAM.
000130 END PROGRAM RECTANGLE-DRAW.