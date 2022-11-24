*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_CAMPAGNE_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING p_logic TYPE filename-fileintern
                         p_param TYPE c
                   CHANGING p_fname TYPE c.

  DATA: lv_file TYPE string,
        lv_file2 TYPE string,
        lv_len  TYPE i,
        lv_len2 TYPE i.

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

    lv_len = STRLEN( lv_file ).
    lv_len = lv_len - 5.
    lv_len2 = lv_len + 1.

    CONCATENATE lv_file(lv_len) lv_file+lv_len2 INTO p_fname.

  ELSE.

    p_fname = lv_file.

  ENDIF.

ENDFORM.                    " recupera_file

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

ENDFORM.                    " apri_file

*&---------------------------------------------------------------------*
*&      Form  chiudi_file
*&---------------------------------------------------------------------*
*       Chiude i file generati
*----------------------------------------------------------------------*
FORM chiudi_file .
  CLOSE DATASET: va_fileout.
ENDFORM.                    " chiudi_file

*&---------------------------------------------------------------------*
*&      Form  estrazioni
*&---------------------------------------------------------------------*
*       Estrae i record dal DB
*----------------------------------------------------------------------*
FORM estrazioni .

  CASE ca_x.
*   Estrazioni FULL
    WHEN r_full.
      PERFORM select_full.

*   Estrazioni DELTA
    WHEN r_delta.
      PERFORM select_delta.

    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " estrazioni

*&---------------------------------------------------------------------*
*&      Form  select_delta
*&---------------------------------------------------------------------*
*       Estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_delta .
  PERFORM get_date_time_to.
  PERFORM get_date_time_from.
*  PERFORM get_param.
  PERFORM select_cgpl_project.
ENDFORM.                    " select_delta

*&---------------------------------------------------------------------*
*&      Form  get_date_time_to
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_TO
*----------------------------------------------------------------------*
FORM get_date_time_to .
  DATA lw_tbtco_t TYPE t_tbtco.

* Il record esiste solo se il programma è stato lanciato in batch
  SELECT jobname jobcount sdlstrtdt
         status FROM tbtco UP TO 1 ROWS
    INTO lw_tbtco_t
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e06 text-e07 text-e08 space.
  ELSE.
    va_date_t = lw_tbtco_t-sdlstrtdt.
*    PERFORM trascod_data USING lw_tbtco_t-sdlstrtdt
*                         CHANGING va_date_t.
  ENDIF.
ENDFORM.                    " get_date_time_to

*&---------------------------------------------------------------------*
*&      Form  trascod_data
*&---------------------------------------------------------------------*
*       Trascodifica due campi DATA e ORA in un campo TIMESTAMP
*----------------------------------------------------------------------*
FORM trascod_data USING p_datum TYPE sy-datum
                  CHANGING p_ts TYPE cgpl_project-created_on.

  DATA: lv_input(8)  TYPE c.

  CLEAR p_ts.
  WRITE: p_datum TO lv_input.

  p_ts = lv_input.
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

  SELECT jobname jobcount sdlstrtdt
         status FROM tbtco
    INTO TABLE lt_tbtco_f
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_f.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e09 text-e10 text-e11 space.
  ENDIF.

  SORT lt_tbtco_f BY sdlstrtdt DESCENDING.
  READ TABLE lt_tbtco_f INTO lw_tbtco_f INDEX 1.

  p_date_f = lw_tbtco_f-sdlstrtdt.
*  PERFORM trascod_data USING lw_tbtco_f-sdlstrtdt lw_tbtco_f-sdlstrttm
*                       CHANGING p_date_f.

ENDFORM.                    " get_date_time_from

*&---------------------------------------------------------------------*
*&      Form  get_param
*&---------------------------------------------------------------------*
*       Recupero dei parametri da utilizzare per le estrazioni
*----------------------------------------------------------------------*
FORM get_param .
* Recupera il valore dei parametri dei gruppi EDWA e EDWN
  PERFORM read_group_param:
    USING ca_edwa ca_z_appl CHANGING r_edwa,
    USING ca_edwn ca_z_appl CHANGING r_edwn.

* Recupero dei singoli parametri
  PERFORM read_param:
    USING ca_edw_type    ca_z_appl CHANGING va_edw_type,
    USING ca_edw_type_ac ca_z_appl CHANGING va_edw_type_ac,
    USING ca_edw_fctcl   ca_z_appl CHANGING va_edw_fctcl,
    USING ca_edw_fctdip  ca_z_appl CHANGING va_edw_fctdip.
ENDFORM.                    " get_param

*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_GROUP_PARAM, e costruisce un range con
*       i valori estratti
*----------------------------------------------------------------------*
FORM read_group_param USING p_gruppo TYPE zca_param-z_group
                            p_z_appl TYPE zca_param-z_appl
                      CHANGING r_range TYPE t_range.

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
*&      Form  select_cgpl_project
*&---------------------------------------------------------------------*
*       Selezione della cgpl_project per estrazione DELTA
*----------------------------------------------------------------------*
FORM select_cgpl_project.

  SELECT guid created_on changed_on
    FROM cgpl_project
     INTO table t_cgpl_project
    WHERE object_type = va_cpg AND
      ( ( created_on GE p_date_f AND created_on LE va_date_t ) OR
        ( changed_on GE p_date_f AND changed_on LE va_date_t ) ).


  PERFORM call_BAPI_MKT_ELEMENT_READ.

ENDFORM.                    "select_orderadm_h

*&---------------------------------------------------------------------*
*&      Form  call_BAPI_MKT_ELEMENT_READ
*&---------------------------------------------------------------------*
*       Richiama la BAPI BAPI_MKT_ELEMENT_READ
*----------------------------------------------------------------------*
FORM call_BAPI_MKT_ELEMENT_READ .
* start m.boccali: adeguamenti upgrade 06.06.2012
  DATA: lr_mktpl_appl type ref to cl_crm_mktpl_appl_base,
        lv_guid16 type sysuuid-x.

  CALL METHOD cl_crm_mktpl_appl_base=>get_instance
    RECEIVING
      re_instance = lr_mktpl_appl
    EXCEPTIONS
      failed      = 1
      others      = 2.
* end m.boccali

  LOOP AT t_cgpl_project.
    clear guid_cpg.
    guid_cpg = t_cgpl_project-guid.
    CLEAR: cod_cpg, desc_cpg, lt_tipo_cpg, obiettivo, dtinizio, dtfine, note, tipo_cpg.
    REFRESH: lt_attributi, lt_attributi, lt_note, lt_line.

* start m.boccali: adeguamento upgrade 06.06.2012
    CLEAR lv_guid16.

    CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
      EXPORTING
        i_guid32 = guid_cpg
      IMPORTING
        e_guid16 = lv_guid16.

*    CALL FUNCTION 'BAPI_MKT_ELEMENT_READ'
*      EXPORTING
*        marketingelement = guid_cpg
*      IMPORTING
*        ex_attributes    = lt_attributi
*      TABLES
*        return           = lt_return.

    CALL METHOD lr_mktpl_appl->element_read
      EXPORTING
        im_mktelement_guid = lv_guid16
      IMPORTING
        ex_attributes      = lt_attributi
      EXCEPTIONS
        not_found          = 1
        others             = 2.
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
* end m.boccali

    ltva_id = va_id.
    ltva_langu = va_langu.
    ltva_object = va_object.
    guidnote = guid_cpg.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
*       CLIENT         = SY-MANDT
        id             = ltva_id
        language       = ltva_langu
        name           = guidnote
        object         = ltva_object
*       ARCHIVE_HANDLE = 0
*       LOCAL_CAT      = ' '
      IMPORTING
        header         = lt_note
      TABLES
        lines          = lt_line
      EXCEPTIONS
*       ID             = 1
*       LANGUAGE       = 2
*       NAME           = 3
        not_found      = 4.
*   OBJECT                        = 5
*   REFERENCE_CHECK               = 6
*   WRONG_ACCESS_TO_ARCHIVE       = 7
*   OTHERS                        = 8


    cod_cpg = lt_attributi-external_id.
    desc_cpg = lt_attributi-text1.
    lt_tipo_cpg = lt_attributi-camp_type.
    obiettivo = lt_attributi-completion.
    dtinizio = lt_attributi-planstart.
    dtfine = lt_attributi-planfinish.

    LOOP AT lt_line.
      CONCATENATE note lt_line-tdline INTO note SEPARATED BY space.
    ENDLOOP.

    IF lt_tipo_cpg = va_z001.
      tipo_cpg = va_up.
    ELSE.
      IF lt_tipo_cpg = va_z002.
        tipo_cpg = va_cc.
      ENDIF.
    ENDIF.
    dtinizio = dtinizio(8).
    dtfine = dtfine(8).


    data: TIPO_ELAB(1) type c,
          zobiett(2)  TYPE c.

    if r_delta is INITIAL.
      TIPO_ELAB = va_tipoel.
    else.
      if t_cgpl_project-changed_on is initial.
        TIPO_ELAB = va_tipoel.
      else.
        TIPO_ELAB = 'M'.
      endif.
    endif.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        INPUT  = obiettivo
      IMPORTING
        OUTPUT = zobiett.
    CONCATENATE va_tipo TIPO_ELAB cod_cpg desc_cpg tipo_cpg zobiett dtinizio dtfine note INTO lt_file SEPARATED BY ca_sep.
    TRANSFER lt_file TO va_fileout.
    clear TIPO_ELAB.
    CLEAR zobiett.
  ENDLOOP.

ENDFORM.                    " call_bapi_getdetailmul


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
    MESSAGE e398(00) WITH text-e13 p_name_par space space.
  ENDIF.

ENDFORM.                    " read_param

*&---------------------------------------------------------------------*
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full .

  SELECT guid created_on changed_on
    FROM cgpl_project
    INTO TABLE t_cgpl_project
    WHERE object_type = va_cpg.

*    PERFORM valorizza_guid.
  PERFORM call_BAPI_MKT_ELEMENT_READ.

ENDFORM.                    " select_full
*&---------------------------------------------------------------------*
*&      Form  recupera_parametri
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM recupera_parametri .

  PERFORM read_param :
    USING ca_id        p_appl  CHANGING va_id,
    USING ca_langu     p_appl  CHANGING va_langu,
    USING ca_object    p_appl  CHANGING va_object,
    USING ca_tipo      p_appl  CHANGING va_tipo,
    USING ca_tipoel    p_appl  CHANGING va_tipoel,
    USING ca_up        p_appl  CHANGING va_up,
    USING ca_cc        p_appl  CHANGING va_cc,
    USING ca_z001      p_appl  CHANGING va_z001,
    USING ca_cpg       p_appl  CHANGING va_cpg,
    USING ca_z002      p_appl  CHANGING va_z002.

ENDFORM.                    " recupera_parametri


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
