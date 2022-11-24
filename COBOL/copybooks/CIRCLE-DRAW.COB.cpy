000010 IDENTIFICATION DIVISION.
000020 PROGRAM-ID. CIRCLE-DRAW.
000030 ENVIRONMENT DIVISION.
000040 DATA DIVISION.
000050 LINKAGE SECTION.
000060   01  THIS.
000070       COPY "SHAPE-COPY.COB".
000080       COPY "CIRCLE-COPY.COB".
000090 PROCEDURE DIVISION USING THIS.
000100     DISPLAY "Drawing a Circle at:(", X, ",", Y, "), Radius ", RADIUS
000110     EXIT PROGRAM.
000120 END PROGRAM CIRCLE-DRAW.