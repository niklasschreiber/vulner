000010 IDENTIFICATION DIVISION.
000020 PROGRAM-ID. CIRCLE-INIT.
000030 ENVIRONMENT DIVISION.
000040 DATA DIVISION.
000050 LINKAGE SECTION.
000060   01  THIS.
000070       COPY "SHAPE-COPY.COB".
000080       COPY "CIRCLE-COPY.COB".
000090   77  PARM-X PIC 9(3).
000100   77  PARM-Y PIC 9(3).
000110   77  PARM-RADIUS PIC 999.
000120 PROCEDURE DIVISION USING THIS, PARM-X, PARM-Y, PARM-RADIUS.
000130     MOVE "CIRCLE-DRAW" TO SHAPE-DRAW
000140     CALL "SHAPE-INIT" USING THIS, PARM-X, PARM-Y
000150     CALL "CIRCLE-SETRADIUS" USING THIS, PARM-RADIUS
000160     EXIT PROGRAM.
000170 END PROGRAM CIRCLE-INIT.