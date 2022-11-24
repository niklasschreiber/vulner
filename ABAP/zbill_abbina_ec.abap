REPORT zbill_abbina_ec.

INCLUDE lbtchdef.
INCLUDE <cntn01>.
include zbill_abb_bonifici_top_2.
include zbill_abb_bonifici_sel_2.
include zbill_abb_bonifici_f01_2.
include zbill_abb_bonifici_f02_2.
include zbill_abb_bonifici_f03_2.
include zbill_abb_bonifici_soff_2.

START-OF-SELECTION.

   
   
*  IF p_bukrs IS NOT INITIAL.
*    AUTHORITY-CHECK OBJECT 'M_TC_BUKRS'
*            ID 'BUKRS' FIELD p_bukrs
*            ID 'ACTVT' FIELD '01'
*            ID 'ACTVT' FIELD '02'
*            ID 'ACTVT' FIELD '03'.
*  ELSEIF p_bukrsb IS NOT INITIAL.
*    AUTHORITY-CHECK OBJECT 'M_TC_BUKRS'
*            ID 'BUKRS' FIELD p_bukrsb
*            ID 'ACTVT' FIELD '01'
*            ID 'ACTVT' FIELD '02'
*            ID 'ACTVT' FIELD '03'.
*  ENDIF.
*
*  IF sy-subrc <> 0.
**    MESSAGE ID 'AD' TYPE 'E' NUMBER 10 WITH 'Error: No authorization'.
*    MESSAGE 'Utente non autorizzato' TYPE 'E'.
*
*  ELSE.

   
   
  IF rb1 = 'X'.
    IF p_file IS NOT INITIAL.
      PERFORM controlli_bonifici.
      IF p_bukrs = 'PPAY'. "IF p_bukrs = 'CLP'.
        PERFORM bonifici_ppay.
      ELSE. " tutte le altre società
        PERFORM bonifici_clp.
      ENDIF.
    ELSE.
      MESSAGE 'Inserire nome file locale' TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ELSEIF rb2 = 'X'.
    IF p_fileb IS NOT INITIAL.
      PERFORM controlli_bollettini.
      PERFORM bollettini.
    ELSE.
      MESSAGE 'Inserire nome file locale' TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.
   
   
*  ELSE.
*    IF rb1 = 'X'.
*      PERFORM controlli_bonifici.
*    ELSEIF rb2 = 'X'.
*      PERFORM controlli_bollettini.
*    ENDIF.
*  ENDIF.

*GUI Texts
*----------------------------------------------------------
* 100 --> &
* 200 --> &
* 300 --> Modifica settore contabile


*Messages
*----------------------------------------------------------
*
* Message class: DB
*000   & & & &
*
* Message class: Hard coded
*   La Società non è presente nei Range
            
          
        
      
      
      
   
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2019. Sap Release 740
   



