  REPORT zfi_ca_send_fatt_elet.

  include zfi_ca_send_fatt_elet_top.
  include zfi_ca_send_fatt_elet_sel.
  include zfi_ca_send_fatt_elet_f01.

  AT SELECTION-SCREEN ON VALUE-REQUEST FOR so_fpath.

    CALL METHOD cl_gui_frontend_services=>directory_browse
      EXPORTING
        window_title    = gw_string
        initial_folder  = gw_string1
      CHANGING
        selected_folder = gw_string2.
    so_fpath = gw_string2.

  START-OF-SELECTION.
    PERFORM refresh.
    PERFORM pulizia_temp.
    PERFORM controllo_invii2.
    PERFORM find_record.

  END-OF-SELECTION.
    PERFORM somm_importi.
    PERFORM determina_competenza.
    PERFORM crea_records.
    PERFORM crea_t_file.
    IF NOT t_01_pa[] IS INITIAL
    OR NOT t_01_pr[] IS INITIAL
    OR NOT t_01_el[] IS INITIAL.
   
   
*****    IF NOT t_out[] IS INITIAL. " M.R. 15/02
   
   
      IF sy-batch IS INITIAL.

        PERFORM download_file_pc TABLES t_01_pa
                                 USING  '\FATPA_'.
        PERFORM download_file_pc TABLES t_01_pr
                                USING  '\FATPR_'.
        IF t_01_pa[] IS NOT INITIAL.
          PERFORM creazione_file_zip TABLES t_01_pa
                                     USING  'FATPA_' text-t02.
        ENDIF.
        IF t_01_pr[] IS NOT INITIAL.
          PERFORM creazione_file_zip TABLES t_01_pr
                                     USING  'FATPR_' text-t03.
        ENDIF.
        IF t_01_el[] IS NOT INITIAL.
          PERFORM creazione_file_zip TABLES t_01_el " 'ZFICA_ELE'
                                     USING  'FATELE_' text-t04.
        ENDIF.
        PERFORM mod_zfica_log.
      ELSE.
        IF t_01_pa[] IS NOT INITIAL.
          PERFORM creazione_file_zip TABLES t_01_pa
                                     USING  'FATPA_' text-t02.
        ENDIF.
        IF t_01_pr[] IS NOT INITIAL.
          PERFORM creazione_file_zip TABLES t_01_pr
                                     USING  'FATPR_' text-t03.
        ENDIF.
        IF t_01_el[] IS NOT INITIAL.
          PERFORM creazione_file_zip TABLES t_01_el " 'ZFICA_ELE'
                                     USING  'FATELE_' text-t04.
        ENDIF.
        PERFORM mod_zfica_log.
      ENDIF.
    ELSE.
      IF gv_flusso     = 'PA'.
      PERFORM creazione_file_zip TABLES t_01_pa
                                 USING  'FATPA_' text-t02.
      ELSEIF gv_flusso = 'PR'.
      PERFORM creazione_file_zip TABLES t_01_pa
                                 USING  'FATPR_' text-t02.
      ELSEIF gv_flusso = 'EL'.
      PERFORM creazione_file_zip TABLES t_01_pa
                                 USING  'FATELE_' text-t02.
      ENDIF.
    ENDIF.

   
   
*Text elements
*----------------------------------------------------------
* 001 Poste Italiane S.p.A. - Società
* 002 Poste Italiane S.p.A. - Società con socio unico - Patrimonio BancoPosta
* 003 DM-17-GIU-2014
* 004 versamento diretto dell'IVA  verso l'Erario a carico del committente
* 005 Poste Italiane S.p.A. - Società con socio unico
* 006 Poste Italiane S.p.A. - Società - Patrimonio BancoPosta
* 007 - Patrimonio BancoPosta
* 008 Lettera d'intenti
* 009 valida da
* 010 a
* T01 Parametri di selezione
* T02 File fatture FATPA
* T03 File fatture FATPR
* T04 File fatture FATELE
* TB2 Modalità di invio


*Selection texts
*----------------------------------------------------------
* P_INVIO         Modalità di invio
* RB_ALL         Invio tutte le modalità
* RB_NOSDI         Invio senza utilizzare SdI
* RB_SDI         Invio tramite SdI
* SO_FPATH D       .
* S_BUDAT D       .
* S_BUKRS D       .
* S_EXBEL D       .


*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &
            
          
        
      
      
      
   
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2019. Sap Release 740
   



