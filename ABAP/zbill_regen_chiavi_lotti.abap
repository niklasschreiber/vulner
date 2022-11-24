REPORT zbill_regen_chiavi_lotti.
include zbill_regen_chiavi_lotti_top.
include zbill_regen_chiavi_lotti_sel.
include zbill_regen_chiavi_lotti_elab.

START-OF-SELECTION.
  PERFORM estrazione_tabelle.
  PERFORM lavorazione_dati.
  PERFORM statistiche.
  PERFORM creazione_alv.
            
          
        
      
      
      
   
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2019. Sap Release 740
   



