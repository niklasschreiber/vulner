REPORT zbill_invoicing_massivo NO STANDARD PAGE HEADING
                          LINE-SIZE 180
                          LINE-COUNT 45.
TYPE-POOLS: rsds.
   
   
*---------------------------------------------------------------------*
*                         DATA DECLARATION                            *
*---------------------------------------------------------------------*

   
   
CONSTANTS: c_repo TYPE varid-report VALUE 'RFKKINV01',
           c_vari TYPE varid-variant VALUE 'MODELLO'.

DATA: lv_fikey     TYPE fikey_kk,
      lv_fikey_max TYPE fikey_kk.
DATA: lv_prog(5) TYPE n.
DATA: i_resob TYPE  resob_kk VALUE '023',
      i_resky TYPE  resky_kk.
DATA: fikey_created TYPE varid-report.
DATA: lv_bldat(10).
DATA: lv_data_fine LIKE sy-datum VALUE '99991231'.
DATA: lv_rttime(8).
DATA: lt_rsdynbrepi TYPE TABLE OF rsdynbrepi.
DATA: lt_rsseldyn TYPE TABLE OF rsseldyn.

DATA: lt_twhere TYPE rsds_twhere,
      lt_range  TYPE rsds_trange,
      ls_range  LIKE LINE OF lt_range,
      ls_frange LIKE LINE OF ls_range-frange_t,
      ls_selopt LIKE LINE OF ls_frange-selopt_t,
      ls_where  TYPE rsds_where.

DATA: v_repname TYPE varid-report,
      v_vari    TYPE varid-variant.

DATA: v_repo TYPE raldb_repo,
      v_vart TYPE raldb_vari.

DATA: i_varid  TYPE STANDARD TABLE OF varid,
      wa_varid TYPE varid.

DATA: i_valtab  TYPE STANDARD TABLE OF rsparams,
      wa_valtab TYPE rsparams.

DATA: number           TYPE tbtcjob-jobcount,
      name             TYPE tbtcjob-jobname,
      print_parameters TYPE pri_params,
      arc_parameters   TYPE arc_params,
      l_valid          TYPE c.

SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-001.

PARAMETERS:
  p_bukrs TYPE bukrs,
  p_proc  TYPE zde_tpproc,
  p_name  TYPE tbtcjob-jobname OBLIGATORY,
  p_tst   TYPE char1 AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN: END OF BLOCK blk1.

   
   
*---------------------------------------------------------------------*
*                    INITIALIZATION                                   *
*---------------------------------------------------------------------*

   
   
INITIALIZATION.
  MOVE 'Z_INV_MASS' TO p_name.

   
   
*---------------------------------------------------------------------*
*                    AT SELECTION-SCREEN                              *
*---------------------------------------------------------------------*
   
   
AT SELECTION-SCREEN.
  IF p_proc IS NOT INITIAL
    AND p_bukrs IS NOT INITIAL.
    CONCATENATE 'Z_INV_MASS_' p_bukrs '_' p_proc '_' sy-datum
        INTO p_name.
  ENDIF.

   
   
*---------------------------------------------------------------------*
*                    START OF SELECTION                               *
*---------------------------------------------------------------------*

   
   
START-OF-SELECTION.

  IF p_tst IS INITIAL.
    IF p_proc EQ 'DI'.
      CLEAR fikey_created.
      PERFORM check_and_create_fikey CHANGING fikey_created.
      IF fikey_created IS INITIAL.
        MESSAGE e398(00) WITH 'Chiave di riconciliazione non creata'.
        EXIT.
      ENDIF.
    ENDIF.
   
   
* --- Get the report variants as per selection criteria

   
   
    SELECT * FROM varid
           INTO TABLE i_varid
           WHERE report EQ c_repo
           AND variant EQ c_vari.

    CHECK i_varid[] IS NOT INITIAL.

    IF sy-subrc NE 0.
   
   
*-- Please Put your message here
   
   
    ENDIF.


    READ TABLE i_varid INTO wa_varid INDEX 1.

   
   
*--- Read the variant contents
   
   
    CALL FUNCTION 'RS_VARIANT_CONTENTS'
      EXPORTING
        report               = c_repo
        variant              = c_vari
      TABLES
        valutab              = i_valtab
   
   
*       free_selections_desc = lt_rsdynbrepi
*       free_selections_value = lt_rsseldyn
   
   
      EXCEPTIONS
        variant_non_existent = 1
        variant_obsolete     = 2
        OTHERS               = 3.
    IF sy-subrc <> 0.
   
   
*    Capture Messages here
   
   
    ENDIF.

    LOOP AT i_valtab INTO wa_valtab.

      IF p_proc = 'DI'.
        IF wa_valtab-selname = 'FIKEY'.
          lv_fikey = wa_valtab-low.
          wa_valtab-low = lv_fikey_max.
          MODIFY i_valtab FROM wa_valtab.
        ENDIF.
      ENDIF.

      IF wa_valtab-selname = 'BLDAT'
        OR wa_valtab-selname = 'BUDAT'
        OR wa_valtab-selname = 'RTDATE'.
        lv_bldat = wa_valtab-low.
        MOVE sy-datum TO wa_valtab-low.
        MODIFY i_valtab FROM wa_valtab.
      ENDIF.

      IF wa_valtab-selname = 'FAED_SEL'.
        lv_bldat = wa_valtab-low.
        MOVE lv_data_fine TO wa_valtab-low.
        MODIFY i_valtab FROM wa_valtab.
      ENDIF.

      IF wa_valtab-selname = 'RTTIME'.
        lv_rttime = wa_valtab-low.
        MOVE sy-uzeit TO wa_valtab-low.
        MODIFY i_valtab FROM wa_valtab.
      ENDIF.

    ENDLOOP.

   
   
*    REFRESH lt_range.
*    PERFORM create_field_ranges.


*    CALL FUNCTION 'GET_PRINT_PARAMETERS'
*      EXPORTING
*        report                 = sy-cprog
*        mode                   = 'BATCH'
*      IMPORTING
*        out_parameters         = print_parameters
*        out_archive_parameters = arc_parameters
*        valid                  = l_valid.

   
   
    name = p_name.

    CALL FUNCTION 'JOB_OPEN'
      EXPORTING
        jobname          = name
      IMPORTING
        jobcount         = number
      EXCEPTIONS
        cant_create_job  = 1
        invalid_job_data = 2
        jobname_missing  = 3
        OTHERS           = 4.
    IF sy-subrc = 0.

      SUBMIT rfkkinv01
        VIA JOB name NUMBER number TO SAP-SPOOL
   
   
*        SPOOL PARAMETERS   print_parameters
*        ARCHIVE PARAMETERS arc_parameters
   
   
        WITHOUT SPOOL DYNPRO
        WITH SELECTION-TABLE i_valtab[]
        WITH where = ls_where
        AND RETURN.


    SUBMIT rfkkinv01
      VIA SELECTION-SCREEN
      USING SELECTION-SET 'DIFFERITE'
      VIA JOB name NUMBER number TO SAP-SPOOL
   
   
*        SPOOL PARAMETERS   print_parameters
*        ARCHIVE PARAMETERS arc_parameters
   
   
      WITHOUT SPOOL DYNPRO
      WITH SELECTION-TABLE i_valtab[]
   
   
*      WITH where = ls_where
   
   
      AND RETURN.

      IF sy-subrc = 0.
        CALL FUNCTION 'JOB_CLOSE'
          EXPORTING
            jobcount             = number
            jobname              = name
            strtimmed            = 'X'
          EXCEPTIONS
            cant_start_immediate = 1
            invalid_startdate    = 2
            jobname_missing      = 3
            job_close_failed     = 4
            job_nosteps          = 5
            job_notex            = 6
            lock_failed          = 7
            OTHERS               = 8.
        IF sy-subrc <> 0.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.


   
   
*&---------------------------------------------------------------------*
*&      Form  CHECK_AND_CREATE_FIKEY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM check_and_create_fikey CHANGING p_fikey_created.

  CLEAR: lv_prog, lv_fikey, lv_fikey_max.

  CONCATENATE 'Z' sy-datum+2(6) '%' INTO lv_fikey.

  SELECT MAX( fikey ) FROM dfkksumc INTO lv_fikey_max WHERE fikey LIKE lv_fikey.
  IF lv_fikey_max IS INITIAL.
    lv_prog = 1.
    CONCATENATE 'Z' sy-datum+2(6) lv_prog INTO lv_fikey_max.
  ELSE.
    lv_prog = lv_fikey_max+7(5).
    lv_prog = lv_prog + 1.
    CONCATENATE 'Z' sy-datum+2(6) lv_prog INTO lv_fikey_max.
  ENDIF.

  CALL FUNCTION 'FKK_FIKEY_RESERVE'
    EXPORTING
      i_fikey       = lv_fikey_max
    EXCEPTIONS
      error_message = 1.
  CHECK sy-subrc = 0.

  CALL FUNCTION 'FKK_INV_FIKEY_OPEN_CHECK'
    EXPORTING
      i_fikey       = lv_fikey_max
    EXCEPTIONS
      error_message = 1.
  CHECK sy-subrc = 0.

  CALL FUNCTION 'FKK_FIKEY_OPEN'
    EXPORTING
      i_fikey       = lv_fikey_max
      i_resob       = i_resob
      i_resky       = i_resky
    EXCEPTIONS
      error_message = 1.

  IF sy-subrc EQ 0.


    CALL FUNCTION 'DEQUEUE_EFKKFIKEY'
      EXPORTING
        fikey  = lv_fikey_max
        _scope = 1.

    COMMIT WORK.

    p_fikey_created = 'X'.
  ENDIF.
ENDFORM.
   
   
*&---------------------------------------------------------------------*
*&      Form  CREATE_FIELD_RANGES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM create_field_ranges .
   
   
**
   
   
  FREE: ls_range, ls_frange, ls_selopt.

  ls_range-tablename  = 'DFKKINV_TRIG'.
  ls_frange-fieldname = 'SRCDOCCAT'.

  ls_selopt-option = 'EQ'.
  ls_selopt-sign   = 'I'.
  ls_selopt-low    = 'INVBI'.
  APPEND ls_selopt TO ls_frange-selopt_t.

  APPEND ls_frange TO ls_range-frange_t.
  APPEND ls_range  TO lt_range.
   
   
**
   
   
  FREE: ls_range, ls_frange, ls_selopt.
  ls_range-tablename  = 'DFKKINV_TRIG'.
  ls_frange-fieldname = 'SRCDOCTYPE'.

  ls_selopt-option = 'EQ'.
  ls_selopt-sign   = 'I'.
  ls_selopt-low    = '001'.
  APPEND ls_selopt TO ls_frange-selopt_t.

  APPEND ls_frange TO ls_range-frange_t.
  APPEND ls_range  TO lt_range.
   
   
**
   
   
  FREE: ls_range, ls_frange, ls_selopt.
  ls_range-tablename  = 'DFKKINV_TRIG'.
  ls_frange-fieldname = 'ZZFLOW'.

  ls_selopt-option = 'BT'.
  ls_selopt-sign   = 'I'.

  IF p_proc EQ 'DI'.
    ls_selopt-low    = '*DI'.
  ELSE.
    ls_selopt-low    = p_bukrs.
  ENDIF.

  APPEND ls_selopt TO ls_frange-selopt_t.

  APPEND ls_frange TO ls_range-frange_t.
  APPEND ls_range  TO lt_range.
   
   
**

   
   
  FREE: lt_twhere.
  CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE'
    EXPORTING
      field_ranges  = lt_range
    IMPORTING
      where_clauses = lt_twhere.

  CLEAR ls_where.
  READ TABLE lt_twhere INTO ls_where INDEX 1.

ENDFORM.


   
   
*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &
            
          
        
      
      
      
   
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2019. Sap Release 740
   



