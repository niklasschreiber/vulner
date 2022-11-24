REPORT  zbill_ageing.
include zbill_ageing_top.
include zblll_check_form.
include zbill_logic_form.
include zbill_alv_form.

INITIALIZATION.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'P_TESTO' OR screen-name = 'P_TESTOB'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
  PERFORM numero_massimo_pb.

START-OF-SELECTION.
  AUTHORITY-CHECK OBJECT 'J_B_BUKRS'
       ID 'BUKRS' FIELD p_bukrs.
  IF sy-subrc <> 0.
    MESSAGE e398(00) WITH 'Utente non autorizzato'.
    STOP.
  ELSE.
    PERFORM check_field.
    PERFORM fill_range.
    PERFORM estract_dfkkop.
    PERFORM interval_filtr.
    PERFORM rolling_e_saldo_determinate. "manca
    PERFORM scaduto_totale.
    PERFORM link_all_data.
    PERFORM aggiunta_campi_but.
    PERFORM build_alv.
    PERFORM download_csv_in_background.
  ENDIF.


   
   
*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &
*
* Message class: Hard coded
*   Alimentare almeno il primo intervallo
            
          
        
      
      
      
   
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2019. Sap Release 740
   



