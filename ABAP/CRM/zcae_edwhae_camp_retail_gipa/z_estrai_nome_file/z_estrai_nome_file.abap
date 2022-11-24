FUNCTION Z_ESTRAI_NOME_FILE.
*"----------------------------------------------------------------------
*"*"Interfaccia locale:
*"  IMPORTING
*"     REFERENCE(FULL_PATH) TYPE  STRING
*"  EXPORTING
*"     REFERENCE(FILE_NAME) TYPE  STRING
*"----------------------------------------------------------------------

DATA: FILENAME TYPE string.


 DATA: SHIFTN  TYPE I,
        DEL_SLASH(1)   VALUE '/',
        DEL_BACK_SLASH VALUE '\',
        DEL_POINT(1) VALUE '.'.


FILE_NAME = FULL_PATH.

* Delete the path-part
* search for '/'
   DO.
    SEARCH FILE_NAME FOR DEL_SLASH.
    IF SY-SUBRC > 0.
      EXIT.
    ENDIF.
    SHIFTN = SY-FDPOS + 1.
    SHIFT FILE_NAME BY SHIFTN PLACES LEFT.
  ENDDO.
* search for '\'
  DO.
    SEARCH FILE_NAME FOR DEL_BACK_SLASH.
    IF SY-SUBRC > 0.
      EXIT.
    ENDIF.
    SHIFTN = SY-FDPOS + 1.
    SHIFT FILE_NAME BY SHIFTN PLACES LEFT.
  ENDDO.



ENDFUNCTION.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
