************************************************************************************
* PROGRAM ID           : ZCAE_EDWHAE_OPPORTUNITA                                   *
* PROGRAM TITLE        : POSTE_CRMC_3_010_AT_EDW_007_Opportunità_Eng               *
* AUTHOR               : Cheenangshuk das                                          *
* SUPPLIER             : Accenture Services Pvt. Ltd.                              *
* DATE                 : 17/09/2008                                                *
* DEVELOPMENT ID       : EDW_007                                                   *
* CHANGE REQUEST (CTS) : CWDK907885                                                *
* DESCRIPTION          : This interface extracts the data inherent to the          *
*                        Opportunita (Opportunity) present in the SAP CRM system.  *
*                        The interface considered must not create or delete        *
*                        Opportunity on the system but rather must exclusively     *
*                        populate an output file that will then be used by EDWH    *
*                        to update its DB.                                         *
*==================================================================================*
* COPIED FROM         : (N/A)                                                      *
* TITLE               : (N/A)                                                      *
* OTHER RELATED OBJ   : (N/A)                                                      *
*==================================================================================*
* CHANGE HISTORY LOG                                                               *
*----------------------------------------------------------------------------------*
* MOD. NO.|  DATE    | NAME           | CORRECTION NUMBER  | CHANGE REFERENCE #    *
*----------------------------------------------------------------------------------*
* XXXXXXX |17/09/2008|CHEENANGSHUK DAS|  XXXXXXXXXXX       | Initial Version       *
************************************************************************************
* AUTHOR               : Raffaele Frattini     RF                                  *
* DATE                 : 15/12/2008                                                *
* DESCRIPTION          : Aggiunta Range numerazione per parallelizzare             *
*==================================================================================*
*& Modifiche:   Concetta Pastore CP
*& Data:        18/05/2009
*& Descrizione: Aggiunta campi al tracciato di output
*&---------------------------------------------------------------------*
*& Modifiche:   Raffaele Frattini RF
*& Data:        06/11/2009
*& Descrizione: Aggiunta record per Opportunità Cancellate
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_opportunita_old .

***********************************************************************************
*          INCLUDES                                                               *
***********************************************************************************
* Includes for report ZCAE_EDWHAE_OPPORTUNITA
INCLUDE :zcae_edwhae_opportunita_o_top,
         zcae_edwhae_opportunita_o_sc,
         zcae_edwhae_opportunita_o_form.

***********************************************************************************
*          INITIALIZATION                                                         *
***********************************************************************************
INITIALIZATION.
* Clear and Refresh All Work Areas, Internal Tables and Variables.
  PERFORM clear_var.

***********************************************************************************
*          AT SELECTION SCREEN                                                    *
***********************************************************************************
AT SELECTION-SCREEN.

  IF NOT p_full IS INITIAL AND r_objid IS INITIAL.
    MESSAGE e208(00) WITH text-001.
  ENDIF.

**********************************************************************************
*          START-OF-SELECTION                                                     *
***********************************************************************************
START-OF-SELECTION.

  PERFORM fetch_zca_param.
  PERFORM open_files.
  PERFORM fetch_zca_anprodotto.


* IF DELTA RADIO BUTTON IS SELECTED
  IF NOT p_delta IS INITIAL.

* SELECTION FROM TBTCO FOR SELECTION TYPE DELTA
    SELECT sdlstrtdt
           sdlstrttm
           FROM tbtco
           INTO wa_delta
           UP TO 1 ROWS
           WHERE jobname = c_program_name1                           "'ZCAE_EDWHAE_OPPORTUNITA'
           AND status =  c_r.                                       "'R'.
    ENDSELECT.

    IF sy-subrc IS INITIAL.
      va_date_to = wa_delta-sdlstrtdt.
      va_time_to = wa_delta-sdlstrttm.

      PERFORM trascod_data USING wa_delta-sdlstrtdt wa_delta-sdlstrttm
                           CHANGING va_to1.

    ELSE.
      MESSAGE e398(00) WITH text-016 text-017 text-018 space.
*        "'E' " error message: #impossibile determinare la data attuale.eseguire il programma in background" in un job chiamato zcae_edwhae_opportunita#.
    ENDIF.

* IF TIMESTAMP FIELDS IS INITIAL
    IF  p_tstp IS INITIAL.
      SELECT  sdlstrtdt
              sdlstrttm
              FROM tbtco
              INTO TABLE i_delta
              WHERE jobname = c_program_name1                        "'ZCAE_EDWHAE_OPPORTUNITA'
              AND status = c_f .                                    "'F'.

      SORT i_delta BY sdlstrtdt DESCENDING
                      sdlstrttm DESCENDING.               " To fetch MAX values of both fields
      READ TABLE i_delta INTO wa_delta INDEX 1.

      IF sy-subrc IS INITIAL.
        va_date_from = wa_delta-sdlstrtdt.
        va_time_from = wa_delta-sdlstrttm.

        PERFORM trascod_data USING wa_delta-sdlstrtdt wa_delta-sdlstrttm
                             CHANGING va_from1.

      ELSE.
        MESSAGE  text-023 TYPE c_e.
*        "Impossibile determinare la data iniziale. Eseguire il programma in modalità full oppure specificare una data iniziale#;
      ENDIF.

* IF TIMESTAMP IS NOT INITIAL
    ELSE.
      MOVE p_tstp TO va_from1." From Date

      CONVERT TIME STAMP p_tstp TIME ZONE sy-zonlo INTO DATE va_date_from TIME va_time_from.
    ENDIF.
*   SELECT FROM crmd_orderadm_h
    SELECT guid
           FROM  crmd_orderadm_h
           INTO TABLE i_guid
           PACKAGE SIZE p_pack
           WHERE process_type IN r_val_par
        AND ( ( created_at GE va_from1 AND created_at LE va_to1 ) OR
        ( changed_at GE va_from1 AND changed_at LE va_to1 ) ).


      CLEAR wa_guid.
      LOOP AT i_guid INTO wa_guid.
        MOVE wa_guid-guid TO va_guid3.
        TRANSFER va_guid3 TO va_tempfile.
        CLEAR wa_guid.
      ENDLOOP.
    ENDSELECT.
    CLOSE DATASET va_tempfile.

* -- Estrazione Record Opportunità Cancellate
* -----------------------------------------------------------
    REFRESH: gt_del_opp, i_lineitem_file.
    SELECT object_id FROM zca_del_opp INTO TABLE gt_del_opp
      PACKAGE SIZE p_pack
      WHERE ( del_date GT va_date_from AND del_date LT va_date_to ) OR
            ( del_date EQ va_date_from AND del_date NE va_date_to AND del_time GE va_time_from ) OR
            ( del_date EQ va_date_from AND del_date EQ va_date_to AND del_time GE va_time_from AND del_time LE va_time_to ) OR
            ( del_date EQ va_date_to AND del_date NE va_date_from AND del_time LE va_time_to ).

      LOOP AT gt_del_opp ASSIGNING <fs_del_opp>.
        CLEAR: wa_header_file.

        wa_header_file-header_opp = c_ho.
        wa_header_file-cod_opp_crm = <fs_del_opp>.
        wa_header_file-flag_archiviazione = c_x.
        PERFORM upload_input_file.
      ENDLOOP.

      REFRESH gt_del_opp.
    ENDSELECT.
* -----------------------------------------------------------

*   If Radio Button FULL is selected.
*   SELECT FROM crmd_orderadm_h
  ELSE.
    SELECT guid
            FROM  crmd_orderadm_h
            INTO TABLE i_guid
            PACKAGE SIZE p_pack            " selection screen field
            WHERE object_id    IN r_objid
              AND process_type IN r_val_par.

      CLEAR wa_guid.
      LOOP AT i_guid INTO wa_guid.
        MOVE wa_guid-guid TO va_guid3.
        TRANSFER va_guid3 TO va_tempfile.
        CLEAR wa_guid.
      ENDLOOP.

    ENDSELECT.
    CLOSE DATASET va_tempfile.
  ENDIF. " Radio Button Selection

*FOR THE FINAL FILE PROCESSING
  PERFORM final_process.

* -- Chiusura File
  CLOSE DATASET va_filename.
  CLOSE DATASET va_filelog.

*Text elements
*----------------------------------------------------------
* 005 Impossibile aprire il file in scrittura
* 006 File Logico Errato
* 016 Impossibile determinare la data attuale.
* 017 Eseguire il programma in background
* 018 in un job chiamato ZCAE_EDWHAE_OPPORTUNITA
* 019 estrazione OPPORTUNITÀ avvenuta con successo
* 020 eccezione rilevata
* 021 Errore durante l'estrazione dei parametri
* 023 Impossibile determinare la data iniziale. Eseguire il programma in modalità full oppure specificare una data iniziale
* 024 Impossibile leggere il file di appoggio
* L01 Eccezione rilevata : Descrizione mancante
* L02 Eccezione rilevata : Date non valorizzate
* L03 Eccezione rilevata : COD_CLIENTE_CRM mancante
* L04 Eccezione rilevata : DIP_RESPONSABILE mancante
* L05 Eccezione rilevata : Stato mancante
* L06 Eccezione rilevata : Valore stimato mancante
* L07 Eccezione rilevata : Prodotto Bic mancante
* L08 Eccezione rilevata : Quantità mancante
* L09 Eccezione rilevata : Totale previsto mancante
* S01 Selection Screen For OPPORTUNITA
* S03 File Input OPPORTUNITA
* S04 File Log   OPPORTUNITA
* S05 Selection Type
* S06 Delta
* S07 Full
* S08 Package
* S11 File Names
* S12 Others
* S14 Timestamp


*Selection texts
*----------------------------------------------------------
* P_FILE         Input File
* P_FILOG         Log File
* P_FULL
* P_PACK         Package Size


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
