000010 IDENTIFICATION DIVISION.
000020 PROGRAM-ID. RECTANGLE-INIT.
000030 ENVIRONMENT DIVISION.
000040 DATA DIVISION.
000050 LINKAGE SECTION.
000060   01  THIS.
000070       COPY "SHAPE-COPY.COB".
000080       COPY "RECTANGLE-COPY.COB".
000090   77  PARM-X PIC 999.
000100   77  PARM-Y PIC 999.
000110   77  PARM-WIDTH PIC 999.
000120   77  PARM-HEIGHT PIC 999.
000130 PROCEDURE DIVISION USING THIS, PARM-X, PARM-Y, PARM-WIDTH, PARM-HEIGHT.
000140     MOVE "RECTANGLE-DRAW" TO SHAPE-DRAW
000150     CALL "SHAPE-INIT" USING THIS, PARM-X, PARM-Y
000160     CALL "RECTANGLE-SETWIDTH" USING THIS, PARM-WIDTH
000170     CALL "RECTANGLE-SETHEIGHT" USING THIS, PARM-HEIGHT
000180     EXIT PROGRAM.
000190 END PROGRAM RECTANGLE-INIT.