*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_OPPORTUNITA_FORM
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  clear_var
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_var .

*REFRESHING THE INTERNAL TABLE
  REFRESH:i_guid,
          i_guid1,
          i_lineitem_file,
          i_crmd_customer_h,
          i_zca_anprodotto,
          i_crmd_customer_i,
          i_header,
          i_activity,
          i_partner ,
          i_text,
          i_service_os,
          i_status,
          i_item,
          i_oppurtunity,
          i_pricing_item,
          i_customer_item,
          i_schedul,
          i_cumulated_h,
          i_guid_item,
          i_return .

*CLEARING THE WORK AREA'S
  CLEAR: wa_guid_item,
         wa_header_file,
         wa_lineitem_file,
         wa_err_log,
         wa_suc_log,
         wa_guid,
         wa_guid1,
         wa_delta.

*CLEARING THE VARIABLE
  CLEAR: va_to,
         va_from,
         va_from1,
         va_filename,
         va_filelog,
         va_prdv,
         va_prnv,
         va_stprod,
         va_note,
         va_notes,
         va_header,
         va_lineitem,
         va_date_from,
         va_date_to,
         va_time_from,
         va_time_to.

ENDFORM.                    " clear_var

*&---------------------------------------------------------------------*
*&      Form  OPEN_FILES
*&---------------------------------------------------------------------*
*   OPENING THE FILE                                                   *
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM open_files .
  PERFORM get_file_name USING c_temp_file
                      CHANGING va_tempfile.

  PERFORM get_file_name USING p_file
                        CHANGING va_filename.

  PERFORM get_file_name USING p_filog
                        CHANGING va_filelog.

  OPEN DATASET va_tempfile  FOR OUTPUT IN TEXT MODE
                            ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE c_e.
  ENDIF.

  OPEN DATASET va_filename FOR OUTPUT IN TEXT MODE
                           ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE c_e.
  ENDIF.

  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE
                          ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE c_e.
  ENDIF.
ENDFORM.                    " OPEN_FILES
*&---------------------------------------------------------------------*
*&      Form  get_file_name
*&---------------------------------------------------------------------*
*      PROCESSING THE FILE                                             *
*----------------------------------------------------------------------*
*      -->P_va_file  text
*      <--P_VA_FILENAME  text
*----------------------------------------------------------------------*
FORM get_file_name  USING    p_va_file TYPE filename-fileintern
                    CHANGING p_va_filename TYPE string.
*CALLING THE FUNCTION MODULE 'FILE_GET_NAME' TO PROCESS THE FILE


  DATA: lv_file TYPE string,
        lv_file2 TYPE string,
        lv_len  TYPE i,
        lv_len2 TYPE i.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      client           = sy-mandt
      logical_filename = p_va_file
      operating_system = sy-opsys
      parameter_1      = sy-datum
      parameter_2      = p_ind
    IMPORTING
      file_name        = lv_file "p_va_filename
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
*   File Logico Errato
    MESSAGE text-006 TYPE c_e.
  ENDIF.

  IF p_ind IS INITIAL.

    lv_len = strlen( lv_file ).
    lv_len = lv_len - 5.
    lv_len2 = lv_len + 1.

    CONCATENATE lv_file(lv_len) lv_file+lv_len2 INTO p_va_filename.

*    p_va_filename = lv_file+0(lv_len).
*    p_va_filename = lv_file+lv_len2.

  ELSE.

    p_va_filename = lv_file.

  ENDIF.

ENDFORM.                    " get_file_name
*&---------------------------------------------------------------------*
*&      Form  FETCH_ZCA_PARAM
*&---------------------------------------------------------------------*
*    FETCHING TH TABLE ZCA_PARAM                                       *
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fetch_zca_param .
* Value For EDW_PRDV
  PERFORM call_bapi_val USING c_prdv c_program_name1
                        CHANGING va_prdv.
* Value For EDW_PRNV
  PERFORM call_bapi_val USING c_prnv c_program_name1
                        CHANGING va_prnv.
* Value For EDW_STPROD
  PERFORM call_bapi_val USING c_stprod c_program_name1
                        CHANGING va_stprod.
* Value For EDW_NOTE
  PERFORM call_bapi_val USING c_note c_program_name
                        CHANGING va_note.
* Value For ZBP_FCTCL
  PERFORM call_bapi_val USING c_zbp_fctcl c_program_name1
                        CHANGING va_zbp_fctcl.
* Value For ZBP_FCTDIP
  PERFORM call_bapi_val USING c_zbp_fctdip c_program_name
                        CHANGING va_zbp_fctdip.


  " -- Begin CP 13.05.2010
  CLEAR va_type_ops.
  PERFORM call_bapi_val USING c_opp_soho c_appl_date
                      CHANGING va_type_ops.
  " -- End CP 13.05.2010

* VALUE For Group EDWO
  PERFORM call_bapi_grp USING c_edwo c_program_name1.



  " -- Begin CP 09.10.2013
  PERFORM call_bapi_grp_pfoe USING 'PFOE' c_program_name1.
  " -- End CP 09.10.2013



ENDFORM.                    " FETCH_ZCA_PARAM
*&---------------------------------------------------------------------*
*&      Form  CALL_BAPI_VAL
*&---------------------------------------------------------------------*
*       CALLING THE BAPI " CALL_BAPI_VAL"
*----------------------------------------------------------------------*
*      -->P_C_PRDV  text
*      <--P_va_prdv  text
*----------------------------------------------------------------------*
FORM call_bapi_val  USING    uv_name TYPE zca_param-z_nome_par
                             uv_appl TYPE zca_param-z_appl
                    CHANGING uv_val TYPE zca_param-z_val_par.

  DATA : i_ret TYPE TABLE OF bapiret2.
  REFRESH i_ret[].
  CALL FUNCTION 'Z_CA_READ_PARAM'
    EXPORTING
      z_name_par = uv_name
      z_appl     = uv_appl
    IMPORTING
      z_val_par  = uv_val
    TABLES
      return     = i_ret[].

  IF NOT i_ret[] IS INITIAL.
    MESSAGE text-021 TYPE c_e.
  ENDIF.

ENDFORM.                    " CALL_BAPI_VAL

*&---------------------------------------------------------------------*
*&      Form  call_bapi_grp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_C_EDWO  text
*----------------------------------------------------------------------*
FORM call_bapi_grp  USING uv_edwo TYPE zca_param-z_group
                          uv_appl TYPE zca_param-z_appl.
  DATA : i_ret_grp TYPE TABLE OF bapiret2.
  REFRESH i_ret_grp[].

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = uv_edwo
      i_z_appl = uv_appl
    TABLES
      param    = i_grp
      return   = i_ret_grp[].

  IF NOT i_ret_grp[] IS INITIAL.
    MESSAGE text-021 TYPE c_e.
  ELSE.

    LOOP AT i_grp INTO wa_grp.
      wa_val_par-sign   = c_i.
      wa_val_par-option = c_eq.
      wa_val_par-low = wa_grp-z_val_par.
      APPEND wa_val_par TO r_val_par.
      CLEAR wa_val_par.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " call_bapi_grp
*&---------------------------------------------------------------------*
*&      Form  call_bapi_grp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM call_bapi_grp_pfoe  USING uv_edwo TYPE zca_param-z_group
                               uv_appl TYPE zca_param-z_appl.

  DATA : i_ret_grp TYPE TABLE OF bapiret2.
  REFRESH i_ret_grp[].

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = uv_edwo
      i_z_appl = uv_appl
    TABLES
      param    = i_grp
      return   = i_ret_grp[].

  IF NOT i_ret_grp[] IS INITIAL.
    MESSAGE text-021 TYPE c_e.
  ELSE.

    LOOP AT i_grp INTO wa_grp.
      wa_partner_fct-sign   = c_i.
      wa_partner_fct-option = c_eq.
      wa_partner_fct-low = wa_grp-z_val_par.
      APPEND wa_partner_fct TO r_partner_fct.
      CLEAR wa_partner_fct.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " call_bapi_grp
*&---------------------------------------------------------------------*
*&      Form  fetch_zca_anprodotto
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fetch_zca_anprodotto .
*SELECT FROM zca_anprodotto
  SELECT product_guid
         zz0010
         FROM zca_anprodotto
         INTO TABLE i_zca_anprodotto.
  IF sy-subrc IS INITIAL.
    SORT i_zca_anprodotto  BY product_guid.
  ENDIF.

ENDFORM.                    " fetch_zca_anprodotto

*&---------------------------------------------------------------------*
*&      Form  Final_process
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM final_process.

  REFRESH : i_guid , i_guid1.
* Opening a temporary file for output
  OPEN DATASET va_tempfile  FOR INPUT IN TEXT MODE   "OPEN DATASET
                               ENCODING DEFAULT.
  IF sy-subrc EQ 0.
    CLEAR va_cnt.
    DO.

      READ DATASET va_tempfile INTO va_guid.         "READ DATASET
      IF sy-subrc NE 0.
        EXIT.
      ENDIF.
      MOVE va_guid TO wa_guid1-guid.
      MOVE va_guid TO wa_guid-guid.
      APPEND wa_guid1 TO i_guid1.
      APPEND wa_guid TO i_guid.
      va_cnt = va_cnt + c_1.

      IF va_cnt GE p_pack.
        CLEAR va_cnt.
        PERFORM fetch_crmd.
        PERFORM execute_bapi.
        PERFORM fill_data.
        REFRESH : i_guid1, i_guid.
      ENDIF.

    ENDDO.
*   For the last set of data
    IF NOT i_guid1 IS INITIAL.
      PERFORM fetch_crmd.
      PERFORM execute_bapi.
      PERFORM fill_data.
      REFRESH: i_guid1 , i_guid.
    ENDIF.
  ELSE.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-024 TYPE c_e.
  ENDIF.

  CLOSE DATASET  va_tempfile.
  DELETE DATASET va_tempfile.

ENDFORM.                    " Final_process

*&---------------------------------------------------------------------*
*&      Form  execute_bapi
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM execute_bapi .

  DATA : lv_guid_item(32) TYPE c.

  REFRESH : i_header,
            i_activity,
            i_partner,
            i_text,
            i_guid_item,
            i_service_os,
            i_status,
            i_item,
            i_oppurtunity,
            i_pricing_item,
            i_customer_item,
            i_schedul,
            i_cumulated_h,
            i_doc_flow,
            i_return,
            i_crmd_customer_i,
            i_partner_filter.   "-- ADD CP 09.10.2013

* FETCHING DATA THROUGH THE CALL FUNCTIONS
  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
    TABLES
      guid          = i_guid1
      header        = i_header
      activity      = i_activity
      partner       = i_partner
      text          = i_text
      service_os    = i_service_os
      status        = i_status
      item          = i_item
      opportunity   = i_oppurtunity
      pricing_item  = i_pricing_item
      customer_item = i_customer_item
      schedule      = i_schedul
      cumulated_h   = i_cumulated_h
      doc_flow      = i_doc_flow
      return        = i_return.

  DELETE i_text WHERE tdid NE va_note
                  OR tdspras NE c_it.

  SORT i_text BY ref_guid.

  IF NOT i_item[] IS INITIAL.
    LOOP AT i_item INTO wa_item.
      CLEAR lv_guid_item.
      MOVE wa_item-guid TO lv_guid_item.
      MOVE lv_guid_item TO wa_guid_item-guid.
      APPEND wa_guid_item TO i_guid_item.
      CLEAR wa_guid_item.
    ENDLOOP.
* SELECT FROM crmd_customer_i
    SELECT guid
           zzcustomer_i0301
           zzcustomer_i0302
           zzcustomer_i0304
           FROM crmd_customer_i
           INTO TABLE i_crmd_customer_i
           FOR ALL ENTRIES IN i_guid_item
           WHERE guid EQ i_guid_item-guid.
    IF sy-subrc IS INITIAL.
      SORT i_crmd_customer_i  BY guid.
    ENDIF.
  ENDIF.


  " -- Begin CP 09.10.2013
  IF NOT r_partner_fct[] IS INITIAL.
    i_partner_filter[] = i_partner[].
    DELETE i_partner_filter WHERE partner_fct NOT IN r_partner_fct.
    SORT i_partner_filter.
  ENDIF.
  " -- End CP 09.10.2013


ENDFORM.                    " execute_bapi
*&---------------------------------------------------------------------*
*&      Form  fill_data
*&---------------------------------------------------------------------*
*  FILLING THE DATA INTO THE FINAL INTERNAL TABLE                      *
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_data .
  DATA:lt_order  TYPE STANDARD TABLE OF ty_order_h,
       ls_order  TYPE ty_order_h,
       ls_guid   TYPE ty_guid_c,
       lt_guid   TYPE STANDARD TABLE OF ty_guid_c.


  " -- Begin CP 25.02.2014
  DATA: lv_guid_att TYPE crmt_object_guid,
        lt_doc      TYPE crmt_doc_flow_db_wrkt,
        ls_doc      TYPE crmt_doc_flow_db_wrk.
  " -- End CP 25.02.2014

  REFRESH: i_err_log ,
           i_suc_log.

  SORT: i_guid            BY guid,
        i_guid1           BY guid,
        i_oppurtunity     BY guid,
        i_status          BY guid,
        i_crmd_customer_h BY guid,
        i_crmd_customer_i BY guid,
        i_cumulated_h     BY guid,
        i_pricing_item    BY guid,
        i_activity        BY guid,
        i_header          BY guid.
  SORT: i_item            BY header.
  SORT: i_service_os      BY ref_guid.
  SORT: i_partner         BY ref_guid ref_partner_fct mainpartner.
  SORT: i_zca_anprodotto  BY product_guid.
  SORT: i_schedul         BY item_guid.

  CLEAR: wa_guid,wa_guid1,wa_lineitem_file,wa_header_file,va_err_flag,lt_order[],ls_order,lt_guid[],ls_guid.

**DOC_FLOW changes start on 25.11.2013
**get object Id for doc flow
  IF  i_doc_flow[] IS NOT INITIAL.
    LOOP AT i_doc_flow ASSIGNING <fs_doc_flow>.
      CLEAR ls_guid.
**Covert 32 char guid into 16char
      PERFORM convert_32_16 USING <fs_doc_flow>-objkey_a
                            CHANGING ls_guid-guid.
      ls_guid-guid_c = <fs_doc_flow>-objkey_a.
      APPEND ls_guid TO lt_guid.
    ENDLOOP.
    SORT lt_guid BY guid_c .
    IF lt_guid[] IS NOT INITIAL.
      SELECT guid
             object_id FROM crmd_orderadm_h
             INTO TABLE lt_order
             FOR ALL ENTRIES IN lt_guid
             WHERE guid = lt_guid-guid .
      IF sy-subrc = 0.
        SORT lt_order BY guid.
      ENDIF.
    ENDIF.
  ENDIF.
**DOC_FLOW changes end on 25.11.2013

  LOOP AT i_guid1 INTO wa_guid1.
    REFRESH : i_lineitem_file .
    CLEAR wa_header_file.

*#  Fill Header File
*   Table I_HEADER-file
    READ TABLE i_header ASSIGNING <fs_header> WITH KEY guid = wa_guid1-guid BINARY SEARCH.
    CHECK sy-subrc IS INITIAL.

    IF sy-subrc IS INITIAL. "P.A. 28.08.09

      MOVE:  c_ho                     TO   wa_header_file-header_opp ,                "HO
            <fs_header>-process_type  TO   wa_header_file-divisione ,
            <fs_header>-object_id     TO   wa_header_file-cod_opp_crm,
            <fs_header>-description   TO   wa_header_file-description.

      PERFORM f_convert_tmstmp USING <fs_header>-created_at
                               CHANGING wa_header_file-data_creazione.   "ADD CP 15/05/2009

      PERFORM f_convert_tmstmp USING <fs_header>-changed_at
                               CHANGING wa_header_file-data_mod.          "ADD CP 15/05/2009

    ENDIF. "P.A. 28.08.09

*     Table I_OPPRTUNITY
    READ TABLE i_oppurtunity ASSIGNING <fs_oppurtunity> WITH KEY guid = wa_guid1-guid BINARY SEARCH.

    IF sy-subrc IS INITIAL. "P.A. 28.08.09

      MOVE:    <fs_oppurtunity>-startdate    TO wa_header_file-data_apertura,
               <fs_oppurtunity>-expect_end   TO wa_header_file-data_chiusura,
               <fs_oppurtunity>-status_since TO wa_header_file-data_mod_stato,
               <fs_oppurtunity>-probability  TO wa_header_file-prob_riuscita.

    ENDIF. "P.A. 28.08.09

* Table I_PARTNER
    READ  TABLE i_partner  ASSIGNING <fs_partner>  WITH KEY  ref_guid = wa_guid1-guid
                                                             ref_partner_fct = va_zbp_fctcl
                                                             mainpartner = c_x BINARY SEARCH. "#EC *

    IF sy-subrc IS INITIAL. "P.A. 28.08.2009

      MOVE:<fs_partner>-ref_partner_no TO wa_header_file-cod_cliente_crm.

    ENDIF. "P.A. 28.08.2009

    READ TABLE i_partner ASSIGNING <fs_partner> WITH KEY ref_guid = wa_guid1-guid "#EC *
                                                         ref_partner_fct = va_zbp_fctdip
                                                         mainpartner = c_x  BINARY SEARCH."'ZBP_FCTDIP'."#EC *

    IF sy-subrc IS INITIAL. "P.A. 28.08.2009

      MOVE: <fs_partner>-ref_partner_no TO wa_header_file-dip_responsabile .

    ENDIF. "P.A. 28.08.2009

***********************************
    DELETE i_status WHERE user_stat_proc IS INITIAL.
***********************************

* Table I_STATUS
    READ TABLE  i_status ASSIGNING <fs_status> WITH KEY guid = wa_guid1-guid BINARY SEARCH .

    IF sy-subrc IS INITIAL. "P.A. 28.08.2009

      IF <fs_status>-user_stat_proc IS NOT INITIAL  AND  <fs_status>-user_stat_proc  NE va_stprod.

        MOVE: <fs_status>-status   TO   wa_header_file-stato .
      ENDIF.

    ENDIF. "P.A. 28.08.2009

* Table I_SERVICE_OS
    READ TABLE i_service_os ASSIGNING <fs_service_os> WITH KEY ref_guid = wa_guid1-guid BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      CONCATENATE <fs_service_os>-cat_type  <fs_service_os>-code_group <fs_service_os>-code INTO wa_header_file-motivazione.
    ENDIF.

*Table I_CUMULATED
    READ TABLE i_cumulated_h  ASSIGNING <fs_cumulated_h> WITH KEY guid = wa_guid1-guid BINARY SEARCH.

    IF sy-subrc IS INITIAL . "P.A. 28.08.2009

      MOVE:<fs_cumulated_h>-net_value_man TO va_amount.
      MOVE:va_amount TO wa_header_file-valore_stimato.

    ENDIF.

*Table I_DOC_FLOW
    CLEAR wa_header_file-id_univoco.
    CLEAR lv_guid_att. "-- ADD CP 25.02.2014
*   READ TABLE i_doc_flow ASSIGNING <fs_doc_flow> WITH KEY REF_GUID = wa_guid1-guid BINARY SEARCH.
    LOOP AT i_doc_flow ASSIGNING <fs_doc_flow>.

      IF <fs_doc_flow>-objtype_a = 'BUS2000108' AND <fs_doc_flow>-ref_guid = wa_guid1-guid.
*    IF sy-subrc IS INITIAL . "P.A. 28.08.2009
        MOVE <fs_doc_flow>-objkey_a TO wa_guid_doc.
        SELECT SINGLE * FROM crmd_orderadm_h WHERE guid = wa_guid_doc.
        IF sy-subrc IS INITIAL.
          MOVE crmd_orderadm_h-object_id TO wa_header_file-id_univoco.
        ENDIF.
        CLEAR wa_guid_doc.
      ENDIF.
***DOC_FLOW changes start on 25.11.2013
      IF <fs_doc_flow>-objtype_a = 'BUS2000126' AND
         <fs_doc_flow>-ref_guid = wa_guid1-guid.
        CLEAR ls_guid.
        READ TABLE lt_guid INTO ls_guid WITH KEY guid_c  = <fs_doc_flow>-objkey_a BINARY SEARCH.
        IF sy-subrc = 0.
          CLEAR ls_order.
          READ TABLE lt_order INTO ls_order WITH KEY guid = ls_guid-guid BINARY SEARCH .
          IF sy-subrc = 0.
            wa_header_file-cod_app_crm = ls_order-object_id.
            lv_guid_att = ls_guid-guid.    "-- ADD CP 25.02.2014
          ENDIF.
        ENDIF.

      ENDIF.
***DOC_FLOW changes end on 25.11.2013
    ENDLOOP.


*Table I_TEXT
    CLEAR:  va_notes.
    READ TABLE i_text WITH  KEY ref_guid = wa_guid1-guid TRANSPORTING NO FIELDS BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      LOOP AT i_text ASSIGNING <fs_text> FROM sy-tabix.
        IF <fs_text>-ref_guid NE wa_guid1-guid.
          EXIT.
        ELSE.
          CONCATENATE va_notes <fs_text>-tdline INTO va_notes.
        ENDIF.
      ENDLOOP.
      MOVE va_notes TO wa_header_file-note.

    ENDIF.

*  Table CRMD_CUSTOMER_H
    READ TABLE i_crmd_customer_h ASSIGNING <fs_crmd_customer_h> WITH KEY guid = wa_guid1-guid BINARY SEARCH. "#EC *

    IF sy-subrc IS INITIAL. "P.A. 28.08.2009

      " -- Begin CP 13.05.2010
      IF <fs_header>-process_type EQ va_type_ops.
        CONCATENATE c_i <fs_crmd_customer_h>-zzcustomer_h1501 INTO wa_header_file-zz_tip_opp_biz.
        CONCATENATE c_i <fs_crmd_customer_h>-zz_catmot_s      INTO wa_header_file-zz_denom.
        " -- Begin CP 25.02.2014
        " Valorizzazione ID Univoco con Object id dek Lead Predecessore
        IF <fs_crmd_customer_h>-zzcustomer_h1501 EQ '003' AND " Tipo Opportunità = Piano di Azione
            wa_header_file-cod_app_crm IS NOT INITIAL.       " Il predecessore è un'attività
          " Recupero i documenti precedenti all'Attività
          CALL FUNCTION 'CRM_DOC_FLOW_READ_DB'
            EXPORTING
              iv_header_guid = lv_guid_att
            IMPORTING
              et_doc_links   = lt_doc
            EXCEPTIONS
              error_occurred = 1
              OTHERS         = 2.
          " Verifico che ci siano Lead
          READ TABLE lt_doc INTO ls_doc WITH KEY objtype_a = 'BUS2000108'.
          IF sy-subrc IS INITIAL.
            CLEAR lv_guid_att.
            CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
              EXPORTING
                i_guid32 = ls_doc-objkey_a(32)
              IMPORTING
                e_guid16 = lv_guid_att.

            " Recupero L'object id
            SELECT SINGLE object_id
              FROM crmd_orderadm_h
              INTO wa_header_file-id_univoco
              WHERE guid EQ lv_guid_att.

          ENDIF.
        ENDIF.
        " -- End CP 25.02.2014
      ELSE.
        " -- End CP 13.05.2010
        MOVE: <fs_crmd_customer_h>-zz_denom TO wa_header_file-zz_denom.
        MOVE: <fs_crmd_customer_h>-zz_tip_opp_biz TO wa_header_file-zz_tip_opp_biz.
      ENDIF. " -- ADD CP 13.05.2010
      MOVE: <fs_crmd_customer_h>-zz_prob_comp_1 TO wa_header_file-perc_competenza.
*      MOVE: <fs_crmd_customer_h>-zz_idunivoco TO wa_header_file-id_univoco.

*#  END OF Fill Header File

    ENDIF. "P.A. 28.08.2009

*Fill ITEM File
    READ TABLE i_item ASSIGNING <fs_item> WITH KEY header = wa_guid1-guid BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      LOOP AT i_item ASSIGNING <fs_item> FROM sy-tabix.
        IF <fs_item>-header NE wa_guid1-guid.               "#EC *
          EXIT.
        ENDIF.
        READ TABLE i_zca_anprodotto ASSIGNING <fs_zca_anprodotto> WITH KEY product_guid = <fs_item>-product BINARY SEARCH. "#EC *
        IF sy-subrc IS NOT INITIAL.
          CLEAR wa_err_log.
          PERFORM populate_err_log USING <fs_header>-object_id text-l07.
          va_err_flag = c_x.
          EXIT.
        ELSE.

          IF <fs_zca_anprodotto>-zz0010 IS INITIAL.

            CLEAR wa_err_log.
            PERFORM populate_err_log USING <fs_header>-object_id text-l07.
            va_err_flag = c_x.
            EXIT.
          ELSE.

            MOVE: <fs_zca_anprodotto>-zz0010 TO wa_lineitem_file-prodotto_bic,
                  <fs_header>-object_id      TO wa_lineitem_file-cod_opp_crm  ,
                   c_pp                      TO wa_lineitem_file-pos_prod.                       "PP
          ENDIF.

        ENDIF.

*Table I_SCHEDULE
        READ TABLE i_schedul ASSIGNING <fs_schedul> WITH KEY item_guid = <fs_item>-guid BINARY SEARCH.

        IF sy-subrc IS INITIAL. "PA 28.08.2009

          MOVE: <fs_schedul>-quantity TO wa_lineitem_file-quantita.

        ENDIF. "P.A. 28.08.2009

*Table I_PRICING_ITEM
        READ TABLE i_pricing_item ASSIGNING <fs_pricing_item>  WITH KEY guid = <fs_item>-guid BINARY SEARCH.

        IF sy-subrc IS INITIAL."P.A. 28.08.2009

          MOVE:  <fs_pricing_item>-net_value_man TO wa_lineitem_file-tot_previsto. "#EC *

        ENDIF.

*Database Table CRMD_CUSTOMER_I
        READ TABLE i_crmd_customer_i ASSIGNING <fs_crmd_customer_i> WITH KEY  guid = <fs_item>-guid BINARY SEARCH. "#EC *
        IF sy-subrc IS INITIAL.
          MOVE: <fs_crmd_customer_i>-zzcustomer_i0302 TO wa_lineitem_file-valore_incr,
                <fs_crmd_customer_i>-zzcustomer_i0301 TO wa_lineitem_file-numero_anni .

          IF  <fs_crmd_customer_i>-zzcustomer_i0304 EQ va_prdv .
            MOVE: c_1 TO wa_lineitem_file-stato_prodotto .
          ELSEIF <fs_crmd_customer_i>-zzcustomer_i0304 EQ  va_prnv.
            MOVE : c_0 TO   wa_lineitem_file-stato_prodotto .
          ENDIF.
        ENDIF.
        APPEND: wa_lineitem_file TO i_lineitem_file.
        CLEAR: <fs_item>, wa_lineitem_file.
      ENDLOOP.

      IF va_err_flag IS INITIAL.
        PERFORM upload_input_file.
      ENDIF.
      REFRESH : i_lineitem_file.
      CLEAR:va_err_flag.
      " -- Begin CP 25.02.2014
    ELSE.   " Se non ha posizioni
      PERFORM upload_input_file.
      " -- End CP 25.02.2014
    ENDIF.
    CLEAR:  wa_guid1.
  ENDLOOP.
  PERFORM upload_log_file.
ENDFORM.                    " fill_data

*&---------------------------------------------------------------------*
*&      Form  UPLOAD_INPUT_FILE
*&---------------------------------------------------------------------*
*     UPLOADIND THE DATA INTO THE                                      *
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_input_file .

  DATA:   lv_acapo_0a            TYPE string,
          lv_acapo_0d            TYPE string.

  CLEAR: lv_acapo_0a, lv_acapo_0d.

  CALL FUNCTION 'CRM_SVY_DB_CONVERT_HEX2STRING'
    EXPORTING
      x = '0A'
    IMPORTING
      s = lv_acapo_0a.

  CALL FUNCTION 'CRM_SVY_DB_CONVERT_HEX2STRING'
    EXPORTING
      x = '0D'
    IMPORTING
      s = lv_acapo_0d.

  PERFORM populate_suc_log USING wa_header_file-cod_opp_crm text-019.
*  A. UPLOAD LOG FILE
  PERFORM upload_log_file.

  CONDENSE :
             wa_header_file-valore_stimato NO-GAPS.

* -- Eliminazione caratteri pipe da campo descrizione e note
  REPLACE ALL OCCURRENCES OF ca_sep IN wa_header_file-description WITH gc_trattino.
  REPLACE ALL OCCURRENCES OF ca_sep IN wa_header_file-note WITH gc_trattino.

*  B.  Upload header  (output ) file
  CONCATENATE  wa_header_file-header_opp
               wa_header_file-cod_opp_crm
               wa_header_file-description
               wa_header_file-dip_responsabile
               wa_header_file-divisione
               wa_header_file-cod_cliente_crm
               wa_header_file-data_apertura
               wa_header_file-data_chiusura
               wa_header_file-data_mod_stato
               wa_header_file-stato
               wa_header_file-prob_riuscita
               wa_header_file-perc_competenza
               wa_header_file-note
               wa_header_file-motivazione
               wa_header_file-valore_stimato
               wa_header_file-id_univoco
               wa_header_file-data_creazione  "ADD CP 18/05/2009
               wa_header_file-data_mod        "ADD CP 18/05/2009
               wa_header_file-zz_denom
               wa_header_file-zz_tip_opp_biz
               wa_header_file-flag_archiviazione
               wa_header_file-cod_app_crm  " DOC_FLOW change on 25.11.2013
                       INTO va_header    SEPARATED BY c_pipe." RESPECTING BLANKS.

* eliminazione caratteri sporchi
  REPLACE ALL OCCURRENCES OF lv_acapo_0d IN va_header WITH space.
  REPLACE ALL OCCURRENCES OF lv_acapo_0a IN va_header WITH space.

  TRANSFER va_header TO va_filename.
*B.  Upload line item (output ) file

  LOOP AT i_lineitem_file ASSIGNING <fs_lineitem_file>.

    CONDENSE :
                <fs_lineitem_file>-tot_previsto NO-GAPS,
                <fs_lineitem_file>-quantita NO-GAPS,
                <fs_lineitem_file>-valore_incr NO-GAPS.

    CONCATENATE <fs_lineitem_file>-pos_prod
                <fs_lineitem_file>-cod_opp_crm
                <fs_lineitem_file>-prodotto_bic
                <fs_lineitem_file>-quantita
                <fs_lineitem_file>-stato_prodotto
                <fs_lineitem_file>-tot_previsto
                <fs_lineitem_file>-valore_incr
                <fs_lineitem_file>-numero_anni
                      INTO va_lineitem SEPARATED BY c_pipe." RESPECTING BLANKS.

    TRANSFER va_lineitem TO va_filename.
    CLEAR va_lineitem.
  ENDLOOP.

  " -- Begin CP 09.10.2013

  READ TABLE i_partner_filter TRANSPORTING NO FIELDS
     WITH KEY ref_guid = wa_guid1-guid BINARY SEARCH.
  CHECK sy-subrc IS INITIAL.
  LOOP AT i_partner_filter ASSIGNING <fs_partner> FROM sy-tabix.

    IF <fs_partner>-ref_guid NE wa_guid1-guid.
      EXIT.
    ENDIF.

    CONCATENATE 'PF'
                wa_header_file-cod_opp_crm
                <fs_partner>-partner_fct
                <fs_partner>-partner_no
           INTO va_lineitem SEPARATED BY c_pipe.

    TRANSFER va_lineitem TO va_filename.
    CLEAR va_lineitem.

  ENDLOOP.
  " -- End CP 09.10.2013





ENDFORM.                    " UPLOAD_INPUT_FILE
*&---------------------------------------------------------------------*
*&      Form  upload_log_file
*&---------------------------------------------------------------------*
*      UPLOADING THE LOGFILE                                           8
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_log_file .

  IF NOT i_suc_log[] IS INITIAL.
    LOOP AT i_suc_log ASSIGNING <fs_suc_log>.
      CONCATENATE <fs_suc_log>-opportunita
                  <fs_suc_log>-msg
                  INTO va_log SEPARATED BY c_pipe .
      TRANSFER va_log TO va_filelog.
    ENDLOOP.
  ENDIF.

  IF NOT i_err_log[] IS INITIAL.
    LOOP AT i_err_log ASSIGNING <fs_err_log>.

      CONCATENATE <fs_err_log>-opportunita
                 <fs_err_log>-msg
                 INTO va_log SEPARATED BY c_pipe .
      TRANSFER va_log TO va_filelog.
    ENDLOOP.
  ENDIF.
  REFRESH: i_err_log ,
           i_suc_log.
ENDFORM.                    " upload_log_file
*&---------------------------------------------------------------------*
*&      Form  Fetch_crmd
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fetch_crmd .

  REFRESH i_crmd_customer_h.

* SELECT FROM crmd_customer_h
  SELECT  guid
          zz_prob_comp_1
          zz_denom
          zz_idunivoco
          zz_tip_opp_biz
    " -- Begin CP 13.05.2010
          zzcustomer_h1501
          zz_catmot_s
    " -- End CP 13.05.2010
          FROM crmd_customer_h
          INTO TABLE i_crmd_customer_h
          FOR ALL ENTRIES IN i_guid
          WHERE guid EQ i_guid-guid.
  IF sy-subrc IS INITIAL.
    SORT i_crmd_customer_h  BY guid.
  ENDIF.

ENDFORM.                    " Fetch_crmd
*&---------------------------------------------------------------------*
*&      Form  populate_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_va_guid2  text
*      -->P_TEXT_019  text
*----------------------------------------------------------------------*
FORM populate_suc_log  USING  uv_guid TYPE c
                              uv_text TYPE string.

  wa_suc_log-opportunita = uv_guid.
  wa_suc_log-msg = uv_text.
  APPEND wa_suc_log TO i_suc_log.


ENDFORM.                    " populate_log

*&---------------------------------------------------------------------*
*&      Form  populate_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_va_guid2  text
*      -->P_TEXT_019  text
*----------------------------------------------------------------------*
FORM populate_err_log  USING  uv_guid TYPE c
                              uv_text TYPE string.

  wa_err_log-opportunita = uv_guid.
  wa_err_log-msg = uv_text.
  APPEND wa_err_log TO i_err_log.

ENDFORM.                    " populate_log
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
*&      Form  CONVERT_32_16
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

FORM convert_32_16  USING    p_objkey_a  TYPE crmt_doc_flow_id
                    CHANGING p_guid      TYPE crmt_object_guid.
  CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
    EXPORTING
      i_guid32 = p_objkey_a
    IMPORTING
      e_guid16 = p_guid.
ENDFORM.                    " CONVERT_32_16

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
