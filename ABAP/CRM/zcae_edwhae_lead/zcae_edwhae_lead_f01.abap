*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_LEAD_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING    p_logic TYPE filename-fileintern
                            p_param TYPE c
                   CHANGING p_fname TYPE c.

  DATA: lv_file TYPE string,
        lv_len  TYPE i,
        lv_len2 TYPE i.

  CLEAR p_fname.
  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_logic
      parameter_1      = p_param
      parameter_2      = p_ind
    IMPORTING
      file_name        = lv_file
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e02 p_logic text-e03 space.
  ENDIF.


  IF p_ind IS INITIAL.

    lv_len = strlen( lv_file ).
    lv_len = lv_len - 5.
    lv_len2 = lv_len + 1.

    CONCATENATE lv_file(lv_len) lv_file+lv_len2 INTO p_fname.

  ELSE.

    p_fname = lv_file.

  ENDIF.

ENDFORM.                    " recupera_file
*&---------------------------------------------------------------------*
*&      Form  get_param
*&---------------------------------------------------------------------*
*       Recupero dei parametri da utilizzare per le estrazioni
*----------------------------------------------------------------------*
FORM get_param .
* Recupera il valore dei parametri dei gruppi EDWA e EDWN
  PERFORM read_group_param:
    USING ca_lead ca_appl CHANGING r_lead,
    USING ca_note ca_appl CHANGING gr_tdid. "ADD MA 22.04.2015

* Recupero dei singoli parametri
  PERFORM read_param:
    USING ca_edw_leadcl   ca_appl CHANGING va_edw_leadcl,
    USING ca_edw_leaddip  ca_appl CHANGING va_edw_leaddip,
*    USING ca_lead_note    ca_appl CHANGING va_lead_note, "DEL MA 22.04.2015
    USING ca_edw_leadvis  ca_appl CHANGING va_edw_leadvis,
    USING ca_edw_leadsta  ca_appl CHANGING va_edw_leadsta,
    USING ca_edw_leadend  ca_appl CHANGING va_edw_leadend,
    USING ca_lead_objtype ca_appl CHANGING va_lead_objtype,
    USING ca_camp_objtype ca_appl CHANGING va_camp_objtype.

ENDFORM.                    " get_param
*&---------------------------------------------------------------------*
*&      Form  read_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_PARAM
*----------------------------------------------------------------------*
FORM read_param USING p_name_par TYPE zca_param-z_nome_par
                      p_z_appl   TYPE zca_param-z_appl
                CHANGING p_z_val_par TYPE zca_param-z_val_par.
  DATA lt_return TYPE STANDARD TABLE OF bapiret2.

  CLEAR p_z_val_par.
  CALL FUNCTION 'Z_CA_READ_PARAM'
    EXPORTING
      z_name_par = p_name_par
      z_appl     = p_z_appl
    IMPORTING
      z_val_par  = p_z_val_par
    TABLES
      return     = lt_return.

  DELETE lt_return WHERE type NE ca_a AND
                         type NE ca_e.
  IF lt_return[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e01 p_name_par space space.
  ENDIF.

ENDFORM.                    " read_param*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_GROUP_PARAM, e costruisce un range con
*       i valori estratti
*----------------------------------------------------------------------*
FORM read_group_param USING p_gruppo TYPE zca_param-z_group
                            p_z_appl TYPE zca_param-z_appl
                      CHANGING r_range TYPE t_lead.

  DATA: lw_range  LIKE LINE OF r_range,
        lt_param  TYPE STANDARD TABLE OF zca_param,
        lt_return TYPE STANDARD TABLE OF bapiret2.
  FIELD-SYMBOLS <lf_param> LIKE LINE OF lt_param.

  REFRESH r_range.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_gruppo
      i_z_appl = p_z_appl
    TABLES
      param    = lt_param
      return   = lt_return.

  DELETE lt_return WHERE type NE ca_a AND
                         type NE ca_e.
  IF lt_return[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e12 p_gruppo space space.
  ENDIF.

  lw_range-sign   = ca_i.
  lw_range-option = ca_eq.
  LOOP AT lt_param ASSIGNING <lf_param>.
    lw_range-low = <lf_param>-z_val_par.
    APPEND lw_range TO r_range.
  ENDLOOP.

ENDFORM.                    " read_group_param
*&---------------------------------------------------------------------*
*&      Form  apri_file
*&---------------------------------------------------------------------*
*       Apre i file da generare
*----------------------------------------------------------------------*
FORM apri_file .

  OPEN DATASET va_fileout FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.

  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    CLOSE DATASET va_fileout.
    MESSAGE e208(00) WITH text-e05.
  ENDIF.

  OPEN DATASET va_filetmp FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    MESSAGE e208(00) WITH text-e21.
  ENDIF.

ENDFORM.                    " apri_file

*&---------------------------------------------------------------------*
*&      Form  chiudi_file
*&---------------------------------------------------------------------*
*       Chiude i file generati
*----------------------------------------------------------------------*
FORM chiudi_file .
  CLOSE DATASET: va_fileout, va_filelog.
ENDFORM.                    " chiudi_file
*&---------------------------------------------------------------------*
*&      Form  estrazioni
*&---------------------------------------------------------------------*
*       Estrae i record dal DB
*----------------------------------------------------------------------*
FORM estrazioni .

  DATA: lv_guid32 TYPE sysuuid-c,
        lv_cont   TYPE i,
        lw_guid   LIKE LINE OF i_guid.

  CASE ca_x.
*   Estrazioni FULL
    WHEN r_full.
      PERFORM select_full.

*   Estrazioni DELTA
    WHEN r_delta.
      PERFORM select_delta.

    WHEN OTHERS.
  ENDCASE.

  CLOSE DATASET va_filetmp.

  OPEN DATASET va_filetmp FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    MESSAGE e208(00) WITH text-e21.
  ENDIF.

  REFRESH i_guid.
  lv_cont = 0.
  DO.

    READ DATASET va_filetmp INTO lv_guid32.
    IF NOT sy-subrc IS INITIAL.
      EXIT.
    ENDIF.

    CLEAR lw_guid.
    lw_guid-guid = lv_guid32.
    APPEND lw_guid TO i_guid.
    ADD 1 TO lv_cont.

    IF lv_cont EQ p_psize.

      PERFORM call_bapi_getdetailmul.
      PERFORM estrazione_cgpl_project.
      PERFORM estrazione_anprodotto.
      PERFORM elabora.
      PERFORM nettoyer_tout.

      CLEAR lv_cont.
      REFRESH i_guid.

    ENDIF.

  ENDDO.

  CLOSE DATASET va_filetmp.
  DELETE DATASET va_filetmp.

  IF NOT i_guid[] IS INITIAL.
    PERFORM call_bapi_getdetailmul.
    PERFORM estrazione_cgpl_project.
    PERFORM estrazione_anprodotto.
    PERFORM elabora.
    PERFORM nettoyer_tout.
  ENDIF.


ENDFORM.                    " estrazioni
*&---------------------------------------------------------------------*
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full .

  SELECT guid object_id
    FROM crmd_orderadm_h
    INTO TABLE i_crmd_orderadm_h
    PACKAGE SIZE p_psize
    WHERE object_id    IN s_objid
      AND process_type IN r_lead.

    PERFORM valorizza_guid.
  ENDSELECT.

ENDFORM.                    " select_full
*&---------------------------------------------------------------------*
*&      Form  select_delta
*&---------------------------------------------------------------------*
*       Estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_delta .
  PERFORM get_date_time_to.
  PERFORM get_date_time_from.

  PERFORM select_orderadm_h.
ENDFORM.                    " select_delta

*&---------------------------------------------------------------------*
*&      Form  get_date_time_to
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_TO
*----------------------------------------------------------------------*
FORM get_date_time_to .
  DATA lw_tbtco_t TYPE t_tbtco.

* Il record esiste solo se il programma è stato lanciato in batch
  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco UP TO 1 ROWS
    INTO lw_tbtco_t
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e06 text-e07 text-e08 space.
  ELSE.
    PERFORM trascod_data USING lw_tbtco_t-sdlstrtdt lw_tbtco_t-sdlstrttm
                         CHANGING va_date_t.
  ENDIF.
ENDFORM.                    " get_date_time_to
*&---------------------------------------------------------------------*
*&      Form  trascod_data
*&---------------------------------------------------------------------*
*       Trascodifica due campi DATA e ORA in un campo TIMESTAMP
*----------------------------------------------------------------------*
FORM trascod_data USING p_datum TYPE sy-datum
                        p_uzeit TYPE sy-uzeit
                  CHANGING p_ts TYPE crmd_orderadm_h-created_at.
  DATA: lv_input(19)  TYPE c,
        lv_output(15) TYPE c.

  CLEAR p_ts.
  WRITE: p_datum TO lv_input,
         p_uzeit TO lv_input+11.
  CALL FUNCTION 'CONVERSION_EXIT_TSTLC_INPUT'
    EXPORTING
      input  = lv_input
    IMPORTING
      output = lv_output.

  p_ts = lv_output.
ENDFORM.                    " trascod_data

*&---------------------------------------------------------------------*
*&      Form  get_date_time_from
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_FROM
*----------------------------------------------------------------------*
FORM get_date_time_from .
  DATA: lw_tbtco_f TYPE t_tbtco,
        lt_tbtco_f LIKE STANDARD TABLE OF lw_tbtco_f.

  CHECK p_date_f IS INITIAL.

  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco
    INTO TABLE lt_tbtco_f
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_f.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e09 text-e10 text-e11 space.
  ENDIF.

  SORT lt_tbtco_f BY sdlstrtdt DESCENDING
                     sdlstrttm DESCENDING.
  READ TABLE lt_tbtco_f INTO lw_tbtco_f INDEX 1.

  PERFORM trascod_data USING lw_tbtco_f-sdlstrtdt lw_tbtco_f-sdlstrttm
                       CHANGING p_date_f.

ENDFORM.                    " get_date_time_from
*&---------------------------------------------------------------------*
*&      Form  valorizza_guid
*&---------------------------------------------------------------------*
*       Valorizza la tabella GUID per la chiamata della BAPI
*----------------------------------------------------------------------*
FORM valorizza_guid .
  DATA lv_guid TYPE bapibus20001_guid_dis-guid.

  LOOP AT i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>.
    PERFORM trascod_guid_16_32 USING <fs_crmd_orderadm_h>-guid
                               CHANGING lv_guid.
    TRANSFER lv_guid TO va_filetmp.
  ENDLOOP.
ENDFORM.                    " valorizza_guid
*&---------------------------------------------------------------------*
*&      Form  trascod_guid_16_32
*&---------------------------------------------------------------------*
*       Trascodifica un GUID da RAW16 a CHAR32
*----------------------------------------------------------------------*
FORM trascod_guid_16_32 USING    p_guid16 TYPE sysuuid-x
                        CHANGING p_guid32 TYPE sysuuid-c.
  CLEAR p_guid32.
  CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_16_32'
    EXPORTING
      i_guid16 = p_guid16
    IMPORTING
      e_guid32 = p_guid32.
ENDFORM.                    " trascod_guid_16_32
*&---------------------------------------------------------------------*
*&      Form  call_bapi_getdetailmul
*&---------------------------------------------------------------------*
*       Richiama la BAPI BAPI_BUSPROCESSND_GETDETAILMUL
*----------------------------------------------------------------------*
FORM call_bapi_getdetailmul .
  DATA lt_guid LIKE i_guid.
  REFRESH: i_appointment, i_header, i_partner, i_service_os,
           i_status, i_text, i_item, i_schedule, i_doc_flow.

* Utilizza una tabella d'appoggio perchè la tabella i_guid non deve
* essere modificata
  lt_guid[] = i_guid[].

  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
    TABLES
      guid        = lt_guid
      header      = i_header
      partner     = i_partner
      appointment = i_appointment
      text        = i_text
      service_os  = i_service_os
      status      = i_status
      item        = i_item
      schedule    = i_schedule
      doc_flow    = i_doc_flow.

ENDFORM.                    " call_bapi_getdetailmul
*&---------------------------------------------------------------------*
*&      Form  elabora
*&---------------------------------------------------------------------*
*       Trasferisce su file i record estratti
*----------------------------------------------------------------------*
FORM elabora .

  CONSTANTS lc_hl(2) TYPE c VALUE 'HL'.

  DATA: fl_error TYPE flag.
  "lv_tdid  TYPE bapibus20001_text_dis-tdid.  "MOD MA 22.04.2015


  SORT: i_appointment     BY ref_guid appt_type,
        i_header          BY guid,
        i_partner         BY ref_guid ref_partner_fct,
        i_service_os      BY ref_guid,
        i_status          BY guid,
        i_text            BY ref_guid,
        i_crmd_orderadm_h BY guid,
        i_guid16          BY ref_guid,
        i_cgpl_project    BY guid,
        i_item2           BY header,
        i_anprod          BY product_guid,
        i_schedule        BY guid.

  "MOD MA 22.04.2015
  "lv_tdid  = va_lead_note.
  DELETE i_text WHERE tdid NOT IN gr_tdid OR "tdid    NE lv_tdid  OR
                      tdspras NE ca_i.
  "END MOD MA 22.04.2015

  LOOP AT i_guid ASSIGNING <fs_guid>.
    CLEAR: wa_file_header, fl_error.
    REFRESH i_file_item.

    wa_file_header-header_lead = lc_hl.
    PERFORM read_table CHANGING fl_error.
    CHECK fl_error IS INITIAL.
    PERFORM read_table_item CHANGING fl_error.
    CHECK fl_error IS INITIAL.
*   Estrazione LEAD avvenuta con successo
    PERFORM write_log USING wa_file_header-cod_lead_crm text-s01.
*   Scrittura record di testata nel file di output
    PERFORM write_header.
*   Scrittura records di posizione nel file di output
    PERFORM write_itme.
  ENDLOOP.

ENDFORM.                    " elabora
*&---------------------------------------------------------------------*
*&      Form  read_table
*&---------------------------------------------------------------------*
*       Lettura dei dati estratti per il caricamento del file
*----------------------------------------------------------------------*
FORM read_table         CHANGING p_error TYPE flag.

  DATA: lv_guid_16     TYPE crmd_orderadm_h-guid,
        lv_appt_type   TYPE bapibus20001_appointment_dis-appt_type,
        lv_partner_fct TYPE bapibus20001_partner_dis-ref_partner_fct,
        lv_note        TYPE char255.

* Trascodifica il GUID per leggere dalla tabella I_CRMD_ORDERADM_H
  PERFORM trascod_guid_32_16 USING <fs_guid>-guid
                             CHANGING lv_guid_16.

* Lettura record dalla tabella HEADER
  READ TABLE i_header ASSIGNING <fs_header>
    WITH KEY guid = <fs_guid>-guid BINARY SEARCH.
  IF NOT sy-subrc IS INITIAL.
*   Eccezione rilevata :  COD_LEAD_CRM mancante
    p_error = ca_x.
    PERFORM write_log USING wa_file_header-cod_lead_crm text-e13.
    EXIT.
  ENDIF.
  wa_file_header-cod_lead_crm = <fs_header>-object_id.
  wa_file_header-divisione = <fs_header>-process_type.
  IF wa_file_header-divisione IS INITIAL.
* Eccezione rilevata :  DIVISIONE mancante
    p_error = ca_x.
    PERFORM write_log USING wa_file_header-cod_lead_crm text-e15.
    EXIT.
  ENDIF.
  wa_file_header-descrizione = <fs_header>-description.
  PERFORM f_convert_tmstmp USING <fs_header>-created_at
                           CHANGING wa_file_header-data_creazione.
  PERFORM f_convert_tmstmp USING <fs_header>-changed_at
                           CHANGING wa_file_header-data_ult_mod.
* Lettura record dalla tabella APPOINTMENT --DATA_INIZIO_LEAD
  CLEAR lv_appt_type.
  lv_appt_type = va_edw_leadsta.
  READ TABLE i_appointment ASSIGNING <fs_appointment>
    WITH KEY ref_guid  = <fs_guid>-guid
             appt_type = lv_appt_type BINARY SEARCH.
  IF NOT sy-subrc IS INITIAL OR <fs_appointment>-date_from IS INITIAL.
*   Eccezione rilevata :  DATA_INIZIO_LEAD mancante
    p_error = ca_x.
    PERFORM write_log USING wa_file_header-cod_lead_crm text-e17.
    EXIT.
  ENDIF.
  wa_file_header-data_inizio_lead = <fs_appointment>-date_from.

* Lettura record dalla tabella APPOINTMENT -- DATA_CHIUSURA_LEAD
  CLEAR lv_appt_type.
  lv_appt_type = va_edw_leadend.
  READ TABLE i_appointment ASSIGNING <fs_appointment>
    WITH KEY ref_guid  = <fs_guid>-guid
             appt_type = lv_appt_type BINARY SEARCH.
*  IF NOT sy-subrc IS INITIAL OR <fs_appointment>-date_from IS INITIAL.
**   Eccezione rilevata :  DATA_CHIUSURA_LEAD mancante
*    p_error = ca_x.
*    PERFORM write_log USING wa_file_header-cod_lead_crm text-e18.
*    EXIT.
*  ENDIF.
  IF sy-subrc IS INITIAL.
    wa_file_header-data_chiusura_lead = <fs_appointment>-date_from.
  ENDIF.
* Lettura record dalla tabella APPOINTMENT -- DATA_CHIUSURA_LEAD
  CLEAR lv_appt_type.
  lv_appt_type = va_edw_leadvis.
  READ TABLE i_appointment ASSIGNING <fs_appointment>
    WITH KEY ref_guid  = <fs_guid>-guid
             appt_type = lv_appt_type BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    wa_file_header-data_pianif_lead = <fs_appointment>-date_from.
  ENDIF.

* Lettura record dalla tabella PARTNER -- COD_CLIENTE_CRM
  CLEAR lv_partner_fct.
  lv_partner_fct = va_edw_leadcl.
  READ TABLE i_partner ASSIGNING <fs_partner>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = lv_partner_fct BINARY SEARCH.
  IF NOT sy-subrc IS INITIAL OR <fs_partner>-partner_no IS INITIAL.
*   Eccezione rilevata :  COD_CLIENTE_CRM mancante
    p_error = ca_x.
    PERFORM write_log USING wa_file_header-cod_lead_crm text-e16.
    EXIT.
  ENDIF.
* Trascodifica Partner Function
  PERFORM trascodicfica_fct USING <fs_partner>-partner_no <fs_partner>-display_type
                            CHANGING wa_file_header-cod_cliente_crm p_error.
  CHECK p_error IS INITIAL.
* Lettura record dalla tabella PARTNER -- DIP_RESPONSABILE
  CLEAR lv_partner_fct.
  lv_partner_fct = va_edw_leaddip.
  READ TABLE i_partner ASSIGNING <fs_partner>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = lv_partner_fct BINARY SEARCH.
  IF NOT sy-subrc IS INITIAL OR <fs_partner>-partner_no IS INITIAL.
*   Eccezione rilevata :  DIP_RESPONSABILE mancante
    p_error = ca_x.
    PERFORM write_log USING wa_file_header-cod_lead_crm text-e14.
    EXIT.
  ENDIF.
* Trascodifica Partner Function
  PERFORM trascodicfica_fct USING <fs_partner>-partner_no <fs_partner>-display_type
                            CHANGING wa_file_header-dip_responsabile p_error.
  CHECK p_error IS INITIAL.
* Lettura record dalla tabella SERVICE_OS
  READ TABLE i_service_os ASSIGNING <fs_service_os>
    WITH KEY ref_guid = <fs_guid>-guid BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    CONCATENATE <fs_service_os>-cat_type
                <fs_service_os>-code_group
                <fs_service_os>-code
           INTO wa_file_header-motivazione.
  ENDIF.

* Lettura record dalla tabella STATUS
  READ TABLE i_status TRANSPORTING NO FIELDS
  WITH KEY guid = <fs_guid>-guid BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    LOOP AT i_status ASSIGNING <fs_status> FROM sy-tabix.
      IF <fs_status>-guid NE <fs_guid>-guid.
        EXIT.
      ENDIF.
      IF <fs_status>-user_stat_proc IS NOT INITIAL.
        wa_file_header-stato = <fs_status>-status.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF wa_file_header-stato IS INITIAL.
*   Eccezione rilevata :  STATO mancante
    p_error = ca_x.
    PERFORM write_log USING wa_file_header-cod_lead_crm text-e19.
    EXIT.
  ENDIF.


* Concatenazione delle note
  READ TABLE i_text TRANSPORTING NO FIELDS
    WITH KEY ref_guid = <fs_guid>-guid BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    LOOP AT i_text ASSIGNING <fs_text> FROM sy-tabix.
      IF <fs_text>-ref_guid NE <fs_guid>-guid. EXIT. ENDIF.

      CONCATENATE  lv_note <fs_text>-tdline
             INTO  lv_note
      SEPARATED BY space.

    ENDLOOP.
    wa_file_header-note = lv_note.
  ENDIF.

* Valorizzazione Campagna
  READ TABLE i_guid16 ASSIGNING <fs_guid16>
       WITH KEY ref_guid = <fs_guid>-guid BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    READ TABLE i_cgpl_project ASSIGNING <fs_cgpl_project>
       WITH KEY guid = <fs_guid16>-guid BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      wa_file_header-campagna = <fs_cgpl_project>-external_id.
    ENDIF.
  ENDIF.


ENDFORM.                    " read_table
*&---------------------------------------------------------------------*
*&      Form  trascod_guid_32_16
*&---------------------------------------------------------------------*
*       Trascodifica un GUID da CHAR32 a RAW16
*----------------------------------------------------------------------*
FORM trascod_guid_32_16 USING    p_guid32 TYPE sysuuid-c
                        CHANGING p_guid16 TYPE sysuuid-x.
  CLEAR p_guid16.
  CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
    EXPORTING
      i_guid32 = p_guid32
    IMPORTING
      e_guid16 = p_guid16.
ENDFORM.                    "trascod_guid_32_16
*&---------------------------------------------------------------------*
*&      Form  select_orderadm_h
*&---------------------------------------------------------------------*
*       Selezione della CRMD_ORDERADM_H per estrazione DELTA
*----------------------------------------------------------------------*
FORM select_orderadm_h .
  SELECT guid object_id
    FROM crmd_orderadm_h
    INTO TABLE i_crmd_orderadm_h
    PACKAGE SIZE p_psize
    WHERE object_id    IN s_objid
      AND process_type IN r_lead   AND
      ( ( created_at GE p_date_f AND created_at LE va_date_t ) OR
        ( changed_at GE p_date_f AND changed_at LE va_date_t ) ).

    PERFORM valorizza_guid.

  ENDSELECT.
ENDFORM.                    " select_orderadm_h
*&---------------------------------------------------------------------*
*&      Form  write_log
*&---------------------------------------------------------------------*
*       Scrittura file di log
*----------------------------------------------------------------------*
FORM write_log  USING    p_cod_lead_crm TYPE char10
                         p_mess         TYPE string.

  DATA lv_log TYPE string.

  CONCATENATE p_cod_lead_crm
              p_mess
             INTO lv_log SEPARATED BY ca_sep.

  REPLACE ALL OCCURRENCES OF va_acapo_0d IN lv_log WITH space.
  REPLACE ALL OCCURRENCES OF va_acapo_0a IN lv_log WITH space.

  TRANSFER lv_log TO va_filelog.

ENDFORM.                    " write_log
*&---------------------------------------------------------------------*
*&      Form  f_convert_tmstmp
*&---------------------------------------------------------------------*
*       Conversione timestamp in ora locale
*----------------------------------------------------------------------*
FORM f_convert_tmstmp  USING    p_timestamp TYPE comt_created_at_usr
                       CHANGING p_data      TYPE char14.

  DATA: lv_datlo  TYPE  sy-datlo,
        lv_timlo  TYPE  sy-timlo.
  CLEAR p_data.
  CALL FUNCTION 'IB_CONVERT_FROM_TIMESTAMP'
    EXPORTING
      i_timestamp = p_timestamp
    IMPORTING
      e_datlo     = lv_datlo
      e_timlo     = lv_timlo.

  CONCATENATE lv_datlo lv_timlo INTO p_data.

ENDFORM.                    " f_convert_tmstmp
*&---------------------------------------------------------------------*
*&      Form  estrazione_cgpl_project
*&---------------------------------------------------------------------*
*       Estrazione Campagna
*----------------------------------------------------------------------*
FORM estrazione_cgpl_project .
  DATA: lv_objtype_a TYPE bapibus20001_doc_flow_dis-objtype_a,
        lv_objtype_b TYPE bapibus20001_doc_flow_dis-objtype_b.

  lv_objtype_a = va_lead_objtype.
  lv_objtype_b = va_camp_objtype.

  DELETE i_doc_flow WHERE objtype_a  NE lv_objtype_a AND
                          objtype_b  NE lv_objtype_b.

  REFRESH: i_cgpl_project, i_guid16.
  CHECK NOT i_doc_flow[] IS INITIAL.

  PERFORM valorizza_guid16.

  SELECT guid external_id
    FROM cgpl_project
    INTO TABLE i_cgpl_project
    FOR ALL ENTRIES IN i_guid16
     WHERE guid EQ i_guid16-guid.

ENDFORM.                    " estrazione_cgpl_project
*&---------------------------------------------------------------------*
*&      Form  valorizza_guid16
*&---------------------------------------------------------------------*
*       Valorizzazione GUID per l'estrazione dalla tabella CGPL_PROJECT
*----------------------------------------------------------------------*
FORM valorizza_guid16.
  DATA lw_guid LIKE LINE OF i_guid16.

  LOOP AT i_doc_flow ASSIGNING <fs_doc_flow>.
    PERFORM trascod_guid_32_16 USING <fs_doc_flow>-objkey_a
                               CHANGING lw_guid-guid.
    lw_guid-ref_guid = <fs_doc_flow>-ref_guid.
    APPEND lw_guid TO i_guid16.
  ENDLOOP.

ENDFORM.                    " valorizza_guid16
*&---------------------------------------------------------------------*
*&      Form  read_table_item
*&---------------------------------------------------------------------*
*       Lettura e valorizzazione campi prodotto
*----------------------------------------------------------------------*
FORM read_table_item  CHANGING p_error TYPE flag.

  CONSTANTS lc_pp(2) TYPE c VALUE 'PP'.

  READ TABLE i_item2 TRANSPORTING NO FIELDS
    WITH KEY header = <fs_guid>-guid BINARY SEARCH.
  CHECK sy-subrc IS INITIAL.
  LOOP AT i_item2 ASSIGNING <fs_item2> FROM sy-tabix.
    CLEAR wa_file_item.
    wa_file_item-pos_prod = lc_pp.
    wa_file_item-cod_lead_crm = wa_file_header-cod_lead_crm.
    IF <fs_item2>-header NE <fs_guid>-guid. EXIT. ENDIF.
    READ TABLE i_anprod ASSIGNING <fs_anprod>
         WITH KEY product_guid = <fs_item2>-guid16 BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      wa_file_item-prodotto_bic = <fs_anprod>-zz0010.
    ELSE.
*   Eccezione rilevata :   PRODOTTO_BIC mancante
      p_error = ca_x.
      PERFORM write_log USING wa_file_header-cod_lead_crm text-e20.
      EXIT.
    ENDIF.

    READ TABLE i_schedule ASSIGNING <fs_schedule>
         WITH KEY item_guid = <fs_item2>-guid BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      wa_file_item-quantita     = <fs_schedule>-quantity.
    ENDIF.
    APPEND wa_file_item TO i_file_item.
  ENDLOOP.


ENDFORM.                    " read_table_item
*&---------------------------------------------------------------------*
*&      Form  estrazione_anprodotto
*&---------------------------------------------------------------------*
*       Estrazione PRODOTTO_BIC
*----------------------------------------------------------------------*
FORM estrazione_anprodotto .

  REFRESH: i_item2, i_anprod.

  CHECK NOT i_item[] IS INITIAL.

  PERFORM valorizza_guid_item.
  SELECT product_guid zz0010
    FROM zca_anprodotto
    INTO TABLE i_anprod
    FOR ALL ENTRIES IN i_item2
    WHERE product_guid EQ i_item2-guid16.

ENDFORM.                    " estrazione_anprodotto
*&---------------------------------------------------------------------*
*&      Form  valorizza_guid_item
*&---------------------------------------------------------------------*
*       Valorizzazione GUID per estrazione dalla tabella ZCA_ANPRODOTTO
*----------------------------------------------------------------------*
FORM valorizza_guid_item .

  DATA lw_guid LIKE LINE OF i_item2.

  LOOP AT i_item ASSIGNING <fs_item>.
    PERFORM trascod_guid_32_16 USING <fs_item>-product
                               CHANGING lw_guid-guid16.
    lw_guid-guid = <fs_item>-guid.
    lw_guid-header = <fs_item>-header.
    APPEND lw_guid TO i_item2.
  ENDLOOP.


ENDFORM.                    " valorizza_guid_item
*&---------------------------------------------------------------------*
*&      Form  write_header
*&---------------------------------------------------------------------*
*       Scrittura record di testata nel file di output
*----------------------------------------------------------------------*
FORM write_header .

  CONSTANTS: lc_trattino TYPE c VALUE '-'.
  DATA lv_line TYPE string.

  REPLACE ALL OCCURRENCES OF ca_sep IN wa_file_header-descrizione WITH lc_trattino.
  REPLACE ALL OCCURRENCES OF ca_sep IN wa_file_header-note WITH lc_trattino.

  CONCATENATE
        wa_file_header-header_lead
        wa_file_header-cod_lead_crm
        wa_file_header-descrizione
        wa_file_header-dip_responsabile
        wa_file_header-divisione
        wa_file_header-cod_cliente_crm
        wa_file_header-data_inizio_lead
        wa_file_header-data_chiusura_lead
        wa_file_header-data_pianif_lead
        wa_file_header-stato
        wa_file_header-note
        wa_file_header-motivazione
        wa_file_header-campagna
        wa_file_header-data_creazione
        wa_file_header-data_ult_mod
        INTO lv_line SEPARATED BY ca_sep.

  REPLACE ALL OCCURRENCES OF va_acapo_0d IN lv_line WITH space.
  REPLACE ALL OCCURRENCES OF va_acapo_0a IN lv_line WITH space.

  TRANSFER lv_line TO va_fileout.


ENDFORM.                    " write_header
*&---------------------------------------------------------------------*
*&      Form  write_itme
*&---------------------------------------------------------------------*
*       Scrittura records di posizione nel file di output
*----------------------------------------------------------------------*
FORM write_itme .

  FIELD-SYMBOLS <fs_file> LIKE LINE OF i_file_item.
  DATA lv_line TYPE string.

  LOOP AT i_file_item ASSIGNING <fs_file>.
    CONDENSE <fs_file>-quantita NO-GAPS.
    CONCATENATE
          <fs_file>-pos_prod
          <fs_file>-cod_lead_crm
          <fs_file>-prodotto_bic
          <fs_file>-quantita
          INTO lv_line SEPARATED BY ca_sep.

    REPLACE ALL OCCURRENCES OF va_acapo_0d IN lv_line WITH space.
    REPLACE ALL OCCURRENCES OF va_acapo_0a IN lv_line WITH space.

    TRANSFER lv_line TO va_fileout.
  ENDLOOP.


ENDFORM.                    " write_itme
*&---------------------------------------------------------------------*
*&      Form  convert_string
*&---------------------------------------------------------------------*
*       Concersione Caratteri speciali
*----------------------------------------------------------------------*
FORM convert_string .


  CALL FUNCTION 'CRM_SVY_DB_CONVERT_HEX2STRING'
    EXPORTING
      x = '0A'
    IMPORTING
      s = va_acapo_0a.

  CALL FUNCTION 'CRM_SVY_DB_CONVERT_HEX2STRING'
    EXPORTING
      x = '0D'
    IMPORTING
      s = va_acapo_0d.

ENDFORM.                    " convert_string
*&---------------------------------------------------------------------*
*&      Form  trascodicfica_fct
*&---------------------------------------------------------------------*
*       Trascodifica Partner Function
*----------------------------------------------------------------------*
FORM trascodicfica_fct  USING    p_partner_no   TYPE bapibus20001_partner_dis-partner_no
                                 p_display_type TYPE bapibus20001_partner_dis-display_type
                        CHANGING p_bp           TYPE char10
                                 p_error        TYPE flag.

  CONSTANTS: lc_bp TYPE bapibus20001_partner_dis-display_type VALUE 'BP',
             lc_us TYPE bapibus20001_partner_dis-display_type VALUE 'US'.

  DATA: lv_user TYPE syst-uname,
        lt_return TYPE bapiret2_t.
  CASE p_display_type.
    WHEN lc_bp."Numero business partner
      p_bp = p_partner_no.
    WHEN lc_us."Utente sistema (nome utente)
      lv_user = p_partner_no.
      CALL FUNCTION 'Z_CA_COD_EMPLOYEE_FROM_USER'
        EXPORTING
          utente      = lv_user
        IMPORTING
          cod_cliente = p_bp
        TABLES
          return      = lt_return.
      IF NOT lt_return[] IS INITIAL.
        p_error = ca_x.
        PERFORM write_log USING wa_file_header-cod_lead_crm text-e22.
      ENDIF.
    WHEN OTHERS.
      p_error = ca_x.
      PERFORM write_log USING wa_file_header-cod_lead_crm text-e22.
  ENDCASE.

ENDFORM.                    " trascodicfica_fct
*&---------------------------------------------------------------------*
*&      Form  nettoyer_tout
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM nettoyer_tout .

  DATA: lv_object_name   TYPE crmt_object_name,
          lv_event_exetime TYPE crmt_event_exetime,
          lv_event         TYPE crmt_event,
          lv_header_guid   TYPE crmt_object_guid.

* Clean-up transactional data
  CALL FUNCTION 'CRM_ORDER_INITIALIZE'
    EXPORTING
      iv_initialize_whole_buffer = 'X'.

  CALL FUNCTION 'CRM_ACTIVITY_H_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up BP data
  CALL FUNCTION 'CRM_PARTNER_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up appointment data and time
  CALL FUNCTION 'CRM_DATES_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up links
  CALL FUNCTION 'CRM_LINK_INIT_OW'
    .


* Clean-up text memory
  CALL FUNCTION 'FREE_TEXT_MEMORY'
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    " nettoyer_tout

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
