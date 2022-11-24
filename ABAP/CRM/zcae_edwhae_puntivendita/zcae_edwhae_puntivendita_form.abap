*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_PUNTIVENDITA_FORM
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_ACTIVITY_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING p_logic TYPE filename-fileintern
                         p_param TYPE c
                CHANGING p_fname TYPE c.


  DATA: lv_file  TYPE string,
        lv_file2 TYPE string,
        lv_len   TYPE i,
        lv_len2  TYPE i.

* 105900: inizio modifica del 29.09.2016 - eng
  DATA: lv_file_temp TYPE string.
* 105900: fine   modifica del 29.09.2016 - eng

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
* 105900: inizio modifica del 29.09.2016 - eng
* gestione nome temporaneo del file
  lv_file_temp = lv_file.

  SPLIT  lv_file_temp AT '.' INTO  va_fileout_temp  ext_temp.

  CONCATENATE va_fileout_temp c_temp INTO va_fileout_temp SEPARATED BY '_'.

  CONCATENATE va_fileout_temp ext_temp INTO va_fileout_temp SEPARATED BY '.'.
* 105900: inizio modifica del 29.09.2016 - eng
ENDFORM.                    " recupera_file
*&---------------------------------------------------------------------*
*&      Form  apri_file
*&---------------------------------------------------------------------*
*       Apre i file da generare
*----------------------------------------------------------------------*
FORM apri_file.
* 105900: ENG - INIZIO MODIFICA DEL 29.09.2016
*  OPEN DATASET va_fileout FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  OPEN DATASET va_fileout_temp FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
* 105900: ENG - FINE  MODIFICA DEL 29.09.2016
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.

  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    CLOSE DATASET va_fileout.
    MESSAGE e208(00) WITH text-e05.
  ENDIF.

  OPEN DATASET va_filetemp FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e26.
  ENDIF.

ENDFORM.                    " apri_file
*&---------------------------------------------------------------------*
*&      Form  chiudi_file
*&---------------------------------------------------------------------*
*       Chiude i file generati
*----------------------------------------------------------------------*
FORM chiudi_file .
* 105900: inizio modifica 29.09.2016 - eng
*  CLOSE DATASET: va_fileout, va_filelog.
  CLOSE DATASET: va_filelog.

  CLOSE DATASET va_fileout_temp.

  IF sy-subrc IS INITIAL.
    file_completo = c_true.
  ENDIF.



* 105900: fine modifica 29.09.2016 - eng

ENDFORM.                    " chiudi_file
*&---------------------------------------------------------------------*
*&      Form  estrazioni
*&---------------------------------------------------------------------*
*       Estrae i record dal DB
*----------------------------------------------------------------------*
FORM estrazioni.

  DATA: lv_guid32 TYPE sysuuid-c,
        lv_cont   TYPE i,
        lw_guid   LIKE LINE OF i_guid.

  CASE ca_x.
*   -- Estrazioni FULL
    WHEN r_full.
      PERFORM select_full.

*   -- Estrazioni DELTA
    WHEN r_delta.
      PERFORM select_delta.

    WHEN OTHERS.
  ENDCASE.

  CLOSE DATASET va_filetemp.

  OPEN DATASET va_filetemp FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    MESSAGE e208(00) WITH text-e27.
  ENDIF.

  REFRESH i_guid.
  lv_cont = 0.
  DO.

    READ DATASET va_filetemp INTO lv_guid32.
    IF NOT sy-subrc IS INITIAL.
      EXIT.
    ENDIF.

    CLEAR lw_guid.
    lw_guid-guid = lv_guid32.
*    APPEND lw_guid TO i_guid.
    " modifica per eliminare i guid duplicati
    COLLECT lw_guid INTO i_guid.
    " fine modo
    ADD 1 TO lv_cont.

    IF lv_cont EQ p_psize.

      PERFORM call_bapi_getdetailmul.
      PERFORM elabora.
      PERFORM nettoyer_tout.

      CLEAR lv_cont.
      REFRESH i_guid.

    ENDIF.

  ENDDO.

  CLOSE DATASET va_filetemp.
  DELETE DATASET va_filetemp.

  IF NOT i_guid[] IS INITIAL.
    PERFORM call_bapi_getdetailmul.
    PERFORM elabora.
  ENDIF.

ENDFORM.                    " estrazioni
*&---------------------------------------------------------------------*
*&      Form  get_param
*&---------------------------------------------------------------------*
*       Recupero dei parametri da utilizzare per le estrazioni
*----------------------------------------------------------------------*
FORM get_param.

  DATA: lv_val_par TYPE zca_param-z_val_par,
        lt_return  TYPE bapiret2_t.      "ADD MA 27.10.2010


  "Inizio modifiche - GC 23.07.2009 17:13:57
  DATA: lr_stah_line LIKE LINE OF gr_stah,
        lr_stai_line LIKE LINE OF gr_stai,
        lr_note_line LIKE LINE OF gr_note.

  FIELD-SYMBOLS: <fs_param> TYPE zca_param.
  "Fine   modifiche - GC 23.07.2009 17:13:57

*  PERFORM read_group_param USING ca_edwc ca_z_appl CHANGING gt_edwc.
  PERFORM read_group_param USING ca_edwc ca_z_appl_pv CHANGING gt_edwc.
  PERFORM read_group_param USING ca_cnop ca_z_appl CHANGING gt_cnop.

  "Inizio modifiche - GC 23.07.2009 12:12:46
  PERFORM read_group_param USING ca_objt ca_z_appl CHANGING gt_objt.
  PERFORM read_group_param USING ca_note ca_z_appl CHANGING gt_note.
  PERFORM read_group_param USING ca_stah ca_z_appl CHANGING gt_stah.
  PERFORM read_group_param USING ca_stai ca_z_appl CHANGING gt_stai.


*Inizio modifica RS 26/10/2011
  PERFORM read_group_param USING ca_acp ca_z_appl CHANGING lt_acp.
*Fine modifica RS 26/10/2011

  "ADD MA 27.10.2010 Estrazione datti contratti PTB
  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = ca_can_erogaz
      i_z_appl = ca_z_appl
    TABLES
      param    = gt_can_erogaz
      return   = lt_return.
  "END ADD MA 27.10.2010 Estrazione datti contratti PTB

  CLEAR lr_stah_line.
  UNASSIGN <fs_param>.
  LOOP AT gt_stah ASSIGNING <fs_param>.
    lr_stah_line-sign   = ca_i.
    lr_stah_line-option = ca_eq.
    lr_stah_line-low    = <fs_param>-z_val_par.
    APPEND lr_stah_line TO gr_stah.
  ENDLOOP.

  CLEAR lr_note_line.
  UNASSIGN <fs_param>.
  LOOP AT gt_note ASSIGNING <fs_param>.
    lr_note_line-sign   = ca_i.
    lr_note_line-option = ca_eq.
    lr_note_line-low    = <fs_param>-z_val_par.
    APPEND lr_note_line TO gr_note.
  ENDLOOP.

  CLEAR lr_stai_line.
  UNASSIGN <fs_param>.
  LOOP AT gt_stai ASSIGNING <fs_param>.
    lr_stai_line-sign   = ca_i.
    lr_stai_line-option = ca_eq.
    lr_stai_line-low    = <fs_param>-z_val_par.
    APPEND lr_stai_line TO gr_stai.
  ENDLOOP.
  "Fine   modifiche - GC 23.07.2009 12:12:46

  "Inizio modifiche - GC 27.07.2009 09:38:18
  CLEAR: gv_contratti, lv_val_par.
  PERFORM read_param USING ca_contratti ca_z_appl CHANGING lv_val_par.
  gv_contratti = lv_val_par.
  "Fine   modifiche - GC 27.07.2009 09:38:18


* -- Recupero dei singoli parametri
  CLEAR: gv_object_type, lv_val_par.
  PERFORM read_param USING ca_object_type ca_z_appl CHANGING lv_val_par.
  gv_object_type = lv_val_par.



  CLEAR: gv_edw_note, lv_val_par.
  PERFORM read_param USING ca_edw_note ca_z_appl CHANGING lv_val_par.
  gv_edw_note = lv_val_par.


  " Inizio AS 15.05.2012
*----------------------
* ANAG_03
*----------------------                  appl
  CLEAR: gv_pft_cliente,
         gv_pft_cointestat.
  REFRESH: gt_type,
           gt_prov,
           gt_inte,
           gt_coin,
           gt_priv,
           gt_tab1,
           gt_tab2,
           gt_ods,
           gt_param_item,
           gt_cont,
           gt_cond.

  PERFORM read_group_param USING ca_type          ca_crmi_ewdh  CHANGING gt_type.
  PERFORM read_group_param USING ca_prov          ca_crmi_ewdh  CHANGING gt_prov.
  PERFORM read_group_param USING ca_inte          ca_edwh_int   CHANGING gt_inte.
  PERFORM read_group_param USING ca_coin          ca_edwh_coint CHANGING gt_coin.
  PERFORM read_group_param USING ca_priv          ca_z_appl     CHANGING gt_priv.
  PERFORM read_group_param USING ca_tab1          ca_z_appl     CHANGING gt_tab1.
  PERFORM read_group_param USING ca_tab2          ca_z_appl     CHANGING gt_tab2.
  PERFORM read_group_param USING ca_ods           ca_z_appl     CHANGING gt_ods.
  PERFORM read_group_param USING ca_cont          ca_z_appl     CHANGING gt_cont.
  PERFORM read_param       USING ca_pft_cliente   ca_nor_conf   CHANGING gv_pft_cliente.
  PERFORM read_param       USING ca_pft_cointest  ca_nor_conf   CHANGING gv_pft_cointestat.
  PERFORM read_group_param USING ca_cond          ca_z_appl     CHANGING gt_cond.
  PERFORM read_group_param USING ca_item          ca_z_appl     CHANGING gt_param_item.


  " Fine   AS 15.05.2012


* Begin AG 06.02.2014
* BUNDLE_09
  REFRESH: gt_prmh[], gt_prmi[].
  PERFORM read_group_param_no_err USING gc_prmh gc_appl CHANGING gt_prmh.
  PERFORM read_group_param_no_err USING gc_prmi gc_appl CHANGING gt_prmi.
* End   AG 06.02.2014

* 105900: gestione range tipo POS
  PERFORM read_group_param USING c_famp c_fa CHANGING gt_tpos.

  IF NOT gt_tpos[] IS INITIAL.
    UNASSIGN <fs_param>.
    CLEAR w_tipo_pos.
    LOOP AT gt_tpos ASSIGNING <fs_param>.
      w_tipo_pos-tipo_pos = <fs_param>-z_val_par.
      w_tipo_pos-descrizione = <fs_param>-z_label.
      APPEND w_tipo_pos TO lt_tipo_pos.
      CLEAR  w_tipo_pos.
    ENDLOOP.
  ENDIF.
* 105900: gestione range tipo POS



* 105900: INIZIO MODIFICA del 22.09.2016
  PERFORM read_group_param USING c_scst ca_z_appl_pv CHANGING gt_stati_pos.

  IF NOT gt_stati_pos[] IS INITIAL.
    UNASSIGN <fs_param>.
    LOOP AT gt_stati_pos ASSIGNING <fs_param>.
*    gr_stati_e
      l_schema_pos-sign   = ca_i.
      l_schema_pos-option = ca_eq.
      l_schema_pos-low = <fs_param>-z_val_par.
      APPEND l_schema_pos TO gr_schema_pos.
    ENDLOOP.
  ENDIF.
* 105900: FINE   MODIFICA del 22.09.2016

ENDFORM.                    " get_param
*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_GROUP_PARAM, e costruisce un range con
*       i valori estratti
*----------------------------------------------------------------------*
FORM read_group_param USING p_gruppo TYPE zca_param-z_group
                            p_z_appl TYPE zca_param-z_appl
                   CHANGING pt_param TYPE zca_param_t.

  DATA lt_return TYPE bapiret2_t.
  REFRESH: pt_param,
           lt_return.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_gruppo
      i_z_appl = p_z_appl
    TABLES
      param    = pt_param
      return   = lt_return.

  DELETE lt_return WHERE type NE ca_a AND
                         type NE ca_e.
  IF lt_return[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e12 p_gruppo space space.
  ENDIF.

ENDFORM.                    " read_group_param

*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_GROUP_PARAM, e costruisce un range con
*       i valori estratti
*----------------------------------------------------------------------*
FORM read_group_param_no_err USING p_gruppo TYPE zca_param-z_group
                                   p_z_appl TYPE zca_param-z_appl
                          CHANGING pt_param TYPE zca_param_t.

  DATA lt_return TYPE bapiret2_t.
  REFRESH: pt_param,
           lt_return.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_gruppo
      i_z_appl = p_z_appl
    TABLES
      param    = pt_param
      return   = lt_return.

ENDFORM.                    " read_group_param

*&---------------------------------------------------------------------*
*&      Form  read_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_PARAM
*----------------------------------------------------------------------*
FORM read_param USING p_name_par  TYPE zca_param-z_nome_par
                      p_z_appl    TYPE zca_param-z_appl
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
*&      Form  f_inizializza
*&---------------------------------------------------------------------*
*    Inizializza Strutture Dati
*----------------------------------------------------------------------*
FORM f_inizializza.

  CLEAR: va_ts,
         va_fileout,
         va_filelog,
         va_filetemp,
         gv_object_type,
         gv_edw_note,
         va_date_t,
         gw_tbtco_t,
         gw_tbtco_f.

  REFRESH: gt_edwc,
           gt_cnop,
           i_guid,
           i_appointment,
           i_partner,
           i_status,
           i_text,
           i_item,
           i_schedule_item,
           i_product_list,
           i_doc_flow,
           i_prec_doc,
           i_header,
           i_crm_jcds,
           i_order_index,
           gr_proc_type,
           gt_nop_motivo,
           gt_can_erogaz.

ENDFORM.                    " f_inizializza
*&---------------------------------------------------------------------*
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full.

  DATA: lt_guid TYPE STANDARD TABLE OF t_guid16,
        lv_line TYPE sysuuid-c.
  FIELD-SYMBOLS: <fs_guid> TYPE t_guid16.

* -- Valorizzazione Range per Tipi Documento
  DATA: lr_ptype_line LIKE LINE OF gr_proc_type,
        lr_objt_line  LIKE LINE OF gr_objt.
  FIELD-SYMBOLS: <fs_param> TYPE zca_param.

  IF s_ptype[] IS INITIAL.
    CLEAR lr_ptype_line.
    LOOP AT gt_edwc ASSIGNING <fs_param>.
      lr_ptype_line-sign   = ca_i.
      lr_ptype_line-option = ca_eq.
      lr_ptype_line-low    = <fs_param>-z_val_par.
      APPEND lr_ptype_line TO gr_proc_type.
    ENDLOOP.
  ELSE.
    gr_proc_type[] = s_ptype[].
  ENDIF.


  "Inizio modifiche - GC 23.07.2009 12:17:09
  CLEAR lr_objt_line.
  LOOP AT gt_objt ASSIGNING <fs_param>.
    lr_objt_line-sign   = ca_i.
    lr_objt_line-option = ca_eq.
    lr_objt_line-low    = <fs_param>-z_val_par.
    APPEND lr_objt_line TO gr_objt.
  ENDLOOP.
  "Fine   modifiche - GC 23.07.2009 12:17:09


  SELECT guid FROM crmd_orderadm_h
    INTO TABLE lt_guid
    PACKAGE SIZE p_psize
    WHERE object_id    IN s_object " Mod AG 25.06.2012
      AND process_type IN gr_proc_type
*      AND process_type EQ 'ZFAC'
      AND object_type  IN gr_objt.     "ADD GC 27/07/2009

    CLEAR lv_line.
    LOOP AT lt_guid ASSIGNING <fs_guid>.
      PERFORM trascod_guid_16_32 USING <fs_guid>-guid
                              CHANGING lv_line.
      TRANSFER lv_line TO va_filetemp.
    ENDLOOP.

  ENDSELECT.

ENDFORM.                    " select_full
*&---------------------------------------------------------------------*
*&      Form  select_delta
*&---------------------------------------------------------------------*
*       Estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_delta.

  DATA: lt_guid TYPE STANDARD TABLE OF t_guid16,
        lv_line TYPE sysuuid-c.


* 105900: INIZIO MODIFICA DEL 15.09.2016 - TM
  DATA: lt_object_id TYPE STANDARD TABLE OF t_guid16,
        ls_object_id TYPE t_guid16.

* 105900: FINE   MODIFICA DEL 15.09.2016 - TM

  FIELD-SYMBOLS: <fs_guid> TYPE t_guid16.

  DATA: lr_ptype_line LIKE LINE OF gr_proc_type,
        lr_objt_line  LIKE LINE OF gr_objt.


  FIELD-SYMBOLS: <fs_param> TYPE zca_param.

  PERFORM get_date_time_to.
  PERFORM get_date_time_from.

* -- Valorizzazione Range con Tipi Documento
  CLEAR lr_ptype_line.
  LOOP AT gt_edwc ASSIGNING <fs_param>.
    lr_ptype_line-sign   = ca_i.
    lr_ptype_line-option = ca_eq.
    lr_ptype_line-low    = <fs_param>-z_val_par.
    APPEND lr_ptype_line TO gr_proc_type.
  ENDLOOP.

  "Inizio modifiche - GC 23.07.2009 12:17:09
  CLEAR lr_objt_line.
  LOOP AT gt_objt ASSIGNING <fs_param>.
    lr_objt_line-sign   = ca_i.
    lr_objt_line-option = ca_eq.
    lr_objt_line-low    = <fs_param>-z_val_par.
    APPEND lr_objt_line TO gr_objt.
  ENDLOOP.
  "Fine   modifiche - GC 23.07.2009 12:17:09

  SELECT guid FROM crmd_orderadm_h
    INTO TABLE lt_guid
    PACKAGE SIZE p_psize
    WHERE process_type IN gr_proc_type
*    WHERE process_type EQ 'ZFAC'
       AND ( ( created_at GE p_date_f AND created_at LE va_date_t )
          OR ( changed_at GE p_date_f AND changed_at LE va_date_t ) )
       AND object_type  IN gr_objt.         "ADD GC 23/07/09
*      AND object_type  EQ gv_object_type.  "DEL GC 23/07/09


* INIZIO MODIFICA DEL 15.09.2016 - TM
    SELECT object_id FROM zca_terminal
      INTO TABLE lt_object_id
       PACKAGE SIZE p_psize
      WHERE ( ( zzcreate_at GE p_date_f AND zzcreate_at LE va_date_t )
           OR ( zzactiv_date GE p_term_f AND zzactiv_date LE p_term_t )
           OR ( zzinstall_date GE p_term_f AND zzinstall_date LE p_term_t )
           OR  ( zzmod_date GE p_term_f AND zzmod_date LE p_term_t )
           OR ( zzcess_date GE p_term_f AND zzcess_date LE p_term_t ) ) .

    ENDSELECT.
* FINE   MODIFICA DEL 15.09.2016 - TM

    LOOP AT lt_object_id INTO ls_object_id.
      APPEND ls_object_id TO lt_guid.
      CLEAR ls_object_id.
    ENDLOOP.


    SORT lt_guid.
    DELETE ADJACENT DUPLICATES FROM lt_guid.

    CLEAR lv_line.
    LOOP AT lt_guid ASSIGNING <fs_guid>.
      PERFORM trascod_guid_16_32 USING <fs_guid>-guid
                              CHANGING lv_line.
      TRANSFER lv_line TO va_filetemp.
    ENDLOOP.

  ENDSELECT.


ENDFORM.                    " select_delta
*&---------------------------------------------------------------------*
*&      Form  get_date_time_to
*&---------------------------------------------------------------------*
*      Recupera il campo DATE_TO
*----------------------------------------------------------------------*
FORM get_date_time_to.

* -- Il record esiste solo se il programma è stato lanciato in batch
  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco UP TO 1 ROWS
    INTO gw_tbtco_t
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e06 text-e07 text-e08 space.
  ELSE.
    PERFORM trascod_data USING gw_tbtco_t-sdlstrtdt gw_tbtco_t-sdlstrttm
                         CHANGING va_date_t.
    p_term_t = gw_tbtco_t-sdlstrtdt.

  ENDIF.

ENDFORM.                    " get_date_time_to
*&---------------------------------------------------------------------*
*&      Form  trascod_data
*&---------------------------------------------------------------------*
*       Trascodifica due campi DATA e ORA in un campo TIMESTAMP
*----------------------------------------------------------------------*
FORM trascod_data USING p_datum TYPE sy-datum
                        p_uzeit TYPE sy-uzeit
               CHANGING p_ts    TYPE crmd_orderadm_h-created_at.
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
  DATA: lt_tbtco_f LIKE STANDARD TABLE OF gw_tbtco_f.

  IF p_date_f IS INITIAL.

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
    READ TABLE lt_tbtco_f INTO gw_tbtco_f INDEX 1.


    PERFORM trascod_data USING gw_tbtco_f-sdlstrtdt gw_tbtco_f-sdlstrttm
                         CHANGING p_date_f.
    p_term_f = gw_tbtco_f-sdlstrtdt.

  ELSE.
    DATA lv_app TYPE char14.
    lv_app = p_date_f.
    gw_tbtco_f-sdlstrtdt = lv_app(8).
    gw_tbtco_f-sdlstrttm = lv_app+8(6).
  ENDIF.

ENDFORM.                    " get_date_time_from
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
FORM call_bapi_getdetailmul.

  DATA: lt_guid         LIKE i_guid,
        lt_doc_flow_app TYPE STANDARD TABLE OF bapibus20001_doc_flow_dis,
        ls_guid16       TYPE t_guid16,
        lt_guid16       TYPE t_guid16_tab.

  DATA: lv_ge        TYPE zz_grande_eserc,
        lv_id_padre  TYPE crmt_object_id_db,
        lv_id_figlio TYPE crmt_object_id_db,
        ls_guid_f    TYPE ts_pratiche_figlio_guid.

  FIELD-SYMBOLS: <fs_doc_flow> TYPE bapibus20001_doc_flow_dis,
                 <fs_guid>     LIKE LINE OF lt_guid.

  REFRESH: i_appointment,
           i_partner,
           i_status,
           i_text,
           i_item,
           i_schedule_item,
           i_product_list,
           i_doc_flow,
           i_prec_doc,
           lt_doc_flow_app,
           i_header,
           i_order_index,
           i_crm_jcds.

* Utilizza una tabella d'appoggio perchè la tabella i_guid non deve
* essere modificata
  lt_guid[] = i_guid[].

  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
    TABLES
      guid          = lt_guid
      header        = i_header
      partner       = i_partner
      appointment   = i_appointment
      text          = i_text
      status        = i_status
      item          = i_item
      schedule_item = i_schedule_item
      product_list  = i_product_list
      doc_flow      = i_doc_flow
      products      = i_products. " Add AS 29.05.2012


  DELETE i_status WHERE status(1) NE ca_e. " ADD SC 05/03/2009

* 105900: inizio modifica del 22.09.2016 - tm
  i_status_pos[] = i_status[].

  DELETE i_status_pos WHERE NOT user_stat_proc IN gr_schema_pos.
* 105900: fine   modifica del 22.09.2016 - tm
  REFRESH lt_guid16.
  LOOP AT lt_guid ASSIGNING <fs_guid>.
    PERFORM trascod_guid_32_16 USING <fs_guid>-guid
                            CHANGING ls_guid16-guid.

* INIZIO RU 16/10/2018 logiche per pratiche padre e figlio grandi esercenti
    CLEAR lv_ge.
    SELECT SINGLE zz_grande_eserc
     FROM zca_dati_agg_acq
     INTO lv_ge
    WHERE object_id = ls_guid16-guid.

    IF lv_ge NE '2'.
      APPEND ls_guid16 TO lt_guid16.
    ENDIF.

    IF lv_ge EQ '1'.
      REFRESH: lt_pratiche_figlio,
               lt_guid_figli.

      SELECT SINGLE object_id
      FROM crmd_orderadm_h
      INTO lv_id_padre
      WHERE guid = ls_guid16-guid.

      SELECT DISTINCT figlio
        FROM zrelazioni_fa
        INTO TABLE lt_pratiche_figlio
        WHERE padre = lv_id_padre.

      IF lt_pratiche_figlio[] IS NOT INITIAL.
        SELECT guid INTO TABLE lt_guid_figli
          FROM crmd_orderadm_h
          FOR ALL ENTRIES IN lt_pratiche_figlio
          WHERE object_id = lt_pratiche_figlio-ob_id.
      ENDIF.

      LOOP AT lt_guid_figli INTO ls_guid_f.
        APPEND ls_guid_f TO lt_guid16.
      ENDLOOP.
* FINE RU 16/10/2018 logiche per pratiche padre e figlio grandi esercenti

    ENDIF.

    "    APPEND ls_guid16 TO lt_guid16.
  ENDLOOP.


* -- Estrazione -------------------------------------------------------------------

  PERFORM estrai_dati_puntivendita  USING lt_guid16.
  PERFORM estrai_dati_terminali     USING lt_guid16.

  CHECK NOT i_doc_flow[] IS INITIAL.

* -- Estrazione Dati Documenti Precedenti
  lt_doc_flow_app[] = i_doc_flow[].
  SORT lt_doc_flow_app BY objkey_a.
  DELETE ADJACENT DUPLICATES FROM lt_doc_flow_app COMPARING objkey_a.

  REFRESH lt_guid16.
  LOOP AT lt_doc_flow_app ASSIGNING <fs_doc_flow>.
    PERFORM trascod_guid_32_16 USING <fs_doc_flow>-objkey_a
                               CHANGING ls_guid16-guid.
    APPEND ls_guid16 TO lt_guid16.
  ENDLOOP.

  SELECT guid object_id object_type FROM crmd_orderadm_h
    INTO TABLE i_prec_doc
    FOR ALL ENTRIES IN lt_guid16
    WHERE guid EQ lt_guid16-guid.


ENDFORM.                    " call_bapi_getdetailmul
*&---------------------------------------------------------------------*
*&      Form  elabora
*&---------------------------------------------------------------------*
*        Trasferisce su file i record estratti
*----------------------------------------------------------------------*
FORM elabora.

  DATA: ls_header          TYPE t_header,
        tb_puntivendita    TYPE t_puntivendita_tab,
        tb_terminali       TYPE t_terminali_tab,
        lt_prodotti        TYPE t_prodotti_tab,
        lt_partner         TYPE t_partner_tab,
        lt_mod_stato       TYPE t_mod_stato_tab,
        lt_attr_dimens     TYPE t_attr_dimens_tab, " Add AS 18.05.2012
        lt_cons_priv_contr TYPE t_cons_priv_contr_tab, " Add AS 17.05.2012
        lt_mod_stato_pos   TYPE t_mod_stato_pos_tab, "ADD GC 23/07/09
        lt_attr_acc        TYPE t_attr_acc_tab,          "TP 21.04.2016
        fl_error           TYPE c.

  FIELD-SYMBOLS: <fs_guid> LIKE LINE OF i_guid,
                 <fs_item> LIKE LINE OF i_item.

  "Inizio modifiche - GC 24.07.2009 12:25:05
  DATA: BEGIN OF ls_guid_tmp,
          guid TYPE crmd_customer_i-guid,
        END OF ls_guid_tmp.

  DATA:  lt_guid_tmp     LIKE STANDARD TABLE OF ls_guid_tmp.

  "Fine   modifiche - GC 24.07.2009 12:25:05

  SORT i_appointment   BY ref_guid appt_type.
  SORT i_status        BY guid kind status active.
  SORT i_text          BY ref_guid.
  SORT i_item          BY header.
  SORT i_product_list  BY guid.
  SORT i_schedule_item BY guid.
  SORT i_partner       BY ref_guid.
  SORT i_prec_doc      BY guid.
  SORT i_doc_flow      BY ref_guid.
  SORT i_header        BY guid.
*  SORT i_customer_h    BY guid.
  SORT i_crm_jcds      BY objnr udate utime.
  SORT i_order_index   BY header. "add mferrara 10/08/20158ì
  SORT i_zca_spid_prod BY id_pratica. "TP 21.04.2016

  "Inizio modifiche - GC 24.07.2009 09:47:55
  UNASSIGN <fs_item>.
  LOOP AT i_item ASSIGNING <fs_item>.
    CLEAR ls_guid_tmp.
    CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
      EXPORTING
        i_guid32 = <fs_item>-guid
      IMPORTING
        e_guid16 = ls_guid_tmp-guid.

    APPEND ls_guid_tmp TO lt_guid_tmp.
  ENDLOOP.

*105900: inizio modifica del 13.09.2016 - tm
*  IF NOT lt_guid_tmp[] IS INITIAL.
*    SELECT guid
*           zz_motivaz_nor_i
*           zz_cat_motivaz_i
*           zz_descr_lavor_i
*           zz_lavorazione_i
*           zz_cod_promo
** ADD MA 27.09.2010 Gestione campi contratti PTB
*           zz_id_prod_ext
*           zz_codice_promoz
*           zz_ytd_quantity
*           zz_net_pr_unit
*           zz_total_value
*           zz_qmax_perorder
*           zz_shipping_freq
**Inizio modifica RS 26.10.2011
*           zz_qta_effettiva
*           zz_imp_eff_liva
*           zz_imp_eff_niva
**Fine modifica RS 26.10.2011
** END ADD MA 27.09.2010 Gestione campi contratti PTB
** Begin AG 22.03.2011 18:08:20
*           zz_code_resp
*           zz_code_chall
*           zz_code_sms_otp
*           zz_cell_fdr
** End   AG 22.03.2011 18:08:20
*           zz_cod_promo_web " Add AS 15.05.2012
*     FROM crmd_customer_i
*     INTO TABLE gt_customer_i
*     FOR ALL ENTRIES IN lt_guid_tmp
*     WHERE guid EQ lt_guid_tmp-guid.
*
**--- Se viene lanciato in delta applico un filtro sull'estrazione.
*    IF r_delta EQ ca_x.

*      SELECT *
*        FROM crm_jcds
*        INTO TABLE gt_crm_jcds
*        FOR ALL ENTRIES IN lt_guid_tmp
*        WHERE objnr EQ lt_guid_tmp-guid
*        AND (
*              ( udate EQ gw_tbtco_f-sdlstrtdt AND udate NE gw_tbtco_t-sdlstrtdt AND utime GE gw_tbtco_f-sdlstrttm )
*           OR ( udate EQ gw_tbtco_f-sdlstrtdt AND udate EQ gw_tbtco_t-sdlstrtdt AND utime GE gw_tbtco_f-sdlstrttm AND utime LT gw_tbtco_t-sdlstrttm )
*           OR ( udate EQ gw_tbtco_t-sdlstrtdt AND udate NE gw_tbtco_f-sdlstrtdt AND utime LT gw_tbtco_t-sdlstrttm )
*           OR ( udate GT gw_tbtco_f-sdlstrtdt AND udate LT gw_tbtco_t-sdlstrtdt )
*             )
*          AND stat LIKE 'E%'
*          AND inact EQ space.
*    ELSE.
*      SELECT *
*      FROM crm_jcds
*      INTO TABLE gt_crm_jcds
*      FOR ALL ENTRIES IN lt_guid_tmp
*      WHERE objnr EQ lt_guid_tmp-guid
*        AND stat LIKE 'E%'
*        AND inact EQ space.
*    ENDIF.
*
*  ENDIF.
* 105900: fine modifica del 13.09.2016 - tm
  "Fine   modifiche - GC 24.07.2009 09:47:55

  DATA: lv_tmp_guid  TYPE crmt_object_guid,
        lv_ge        TYPE zz_grande_eserc,
        lv_id_padre  TYPE crmt_object_id_db,
        lv_id_figlio TYPE crmt_object_id_db.


  REFRESH gt_guid_header[].
  LOOP AT i_guid ASSIGNING <fs_guid>.
    CLEAR gs_guid_header.
    gs_guid_header-guid32 = <fs_guid>-guid.

    CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
      EXPORTING
        i_guid32 = gs_guid_header-guid32
      IMPORTING
        e_guid16 = gs_guid_header-guid16.
    APPEND gs_guid_header TO gt_guid_header.
  ENDLOOP.




  LOOP AT i_guid ASSIGNING <fs_guid>.
    CLEAR: lv_tmp_guid,
           lv_ge,
           lv_id_figlio,
           lv_id_padre.

    REFRESH: lt_pratiche_figlio,
             lt_guid_figli,
             lt_relazioni.

    lv_tmp_guid = <fs_guid>-guid.

* INIZIO RU 16/10/2018 grandi esercenti
    SELECT SINGLE zz_grande_eserc
      FROM zca_dati_agg_acq
      INTO lv_ge
     WHERE object_id = lv_tmp_guid.

    IF lv_ge EQ '1'.     " se è una pratica padre devo estrarre tutti i pv dalle pratiche figlio

      SELECT SINGLE object_id
        FROM crmd_orderadm_h
        INTO lv_id_padre
        WHERE guid = lv_tmp_guid.

      SELECT guid_pv progressivo_item figlio
        FROM zrelazioni_fa
        INTO TABLE lt_relazioni
        WHERE padre = lv_id_padre
          AND punto_vendita NE ''.

    ENDIF.

*   -- Prepara Record di testata
    IF lv_ge NE '2'.    " non eseguire operazioni se è una pratica figlio

* FINE RU 16/10/2018 grandi esercenti

      CLEAR: fl_error.
      PERFORM f_prepara_header USING <fs_guid>
                            CHANGING ls_header
                                     fl_error.

      CHECK fl_error IS INITIAL.


*     -- Prepara Record Punti Vendita.
      PERFORM f_prepara_puntivendita USING <fs_guid>
                                        ls_header
                                        lt_relazioni   "RU 16/10/2018
                                CHANGING tb_puntivendita
                                         fl_error.

      CHECK fl_error IS INITIAL.
*    -- prepara record terminali.
      PERFORM f_prepara_terminali USING <fs_guid>
                                ls_header
                                tb_puntivendita
                                lt_relazioni  "RU 16/10/2018
                        CHANGING tb_terminali
                                 fl_error.

      CHECK fl_error IS INITIAL.

*      -- Scrivi Record Contratto
      PERFORM f_scrivi_record USING ls_header
                                    tb_puntivendita
                                    tb_terminali
                                    lv_id_padre.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " elabora
*&---------------------------------------------------------------------*
*&      Form  f_prepara_header
*&---------------------------------------------------------------------*
*   Prepara il record di testata
*----------------------------------------------------------------------*
FORM f_prepara_header  USING    ps_guid         TYPE bapibus20001_guid_dis
                       CHANGING ps_header       TYPE t_header
                                pf_error        TYPE c.

  CONSTANTS: lc_can_erog(9)   VALUE 'CAN_EROG_'.

  DATA: lv_count        TYPE i,
        lv_codice       TYPE string,
        lv_timestamp    TYPE tzonref-tstamps,
        lv_datlo        TYPE sy-datlo,
        lv_timlo        TYPE sy-timlo,
        ls_customer_h   TYPE t_customer_h,
        ls_cod_contr    TYPE zca_ptb_cocontr,
        lv_parametro    TYPE zca_param-z_nome_par,
        ls_can_erogaz   TYPE zca_param,
        lv_date_3       TYPE sy-datum,
        lv_data_maaf    TYPE int2,
        ls_header       TYPE bapibus20001_header_dis,
        lv_guid16       TYPE sysuuid-x,
        ls_cronomapping TYPE t_cronomapping.

  FIELD-SYMBOLS:   <fs_appointment>    TYPE bapibus20001_appointment_dis,
                   <fs_status>         TYPE bapibus20001_status_dis,
                   <fs_text>           TYPE bapibus20001_text_dis,
                   <fs_doc_flow>       TYPE bapibus20001_doc_flow_dis,
                   <fs_header>         TYPE bapibus20001_header_dis,
                   <fs_prec_doc>       TYPE t_prec_doc,
                   <fs_nop_motivo>     TYPE zca_nop_motivo,
                   <fs_prev_bp>        TYPE t_bdm_prev_bp,
                   <fs_bdm_contract>   TYPE t_bdm_contract,
                   <fs_leggi_prev_app> TYPE t_leggi_prev,
                   <fs_bdm_crif>       TYPE t_bdm_crif,
                   <fs_zca_bdm_pddlb>  TYPE zca_bdm_pddlb,
                   <fs_index>          TYPE t_index.



  CLEAR ps_header.

  READ TABLE i_header ASSIGNING <fs_header> WITH KEY guid = ps_guid-guid
                                                     BINARY SEARCH.
  IF NOT sy-subrc IS INITIAL
    OR <fs_header>-object_id IS INITIAL.
*   -- Scrittura Record di Log
    CLEAR lv_codice.
    lv_codice = ps_guid-guid.
    PERFORM f_scrivi_error USING lv_codice
                                 text-e01.
    pf_error = ca_x.
    RETURN.
  ENDIF.

  ps_header-tipo_record      = ca_hh.
  ps_header-codice_crm       = <fs_header>-object_id.



ENDFORM.                    " f_prepara_header
*&---------------------------------------------------------------------*
*&      Form  f_scrivi_record
*&---------------------------------------------------------------------*
*   Scrittura Record su File
*----------------------------------------------------------------------*
FORM f_scrivi_record  USING    ps_header          TYPE t_header
                               pt_puntivendita    TYPE t_puntivendita_tab
                               pt_terminali       TYPE t_terminali_tab
                               pv_id_padre        TYPE crmt_object_id_db.

  DATA: lv_line TYPE string.

  FIELD-SYMBOLS:  <fs_puntivendita> TYPE t_puntivendita,
                  <fs_terminali>    TYPE t_terminali.

* -- Scrittura Record di testata
  CLEAR lv_line.

  CONCATENATE  ps_header-tipo_record
               ps_header-codice_crm
              INTO lv_line
              SEPARATED BY ca_pipe.
*    105900: ENG INIZIO MODIFICA DEL 29.09.2016
*     TRANSFER lv_line TO va_fileout.
  TRANSFER lv_line TO va_fileout_temp.
* 105900: ENG FINE MODIFICA DEL 29.09.2016

* -- Scrittura Record di Punti Vendita
  LOOP AT pt_puntivendita ASSIGNING <fs_puntivendita>.

    CLEAR lv_line.
    CONCATENATE <fs_puntivendita>-tipo_record
                <fs_puntivendita>-codice_crm
                <fs_puntivendita>-id_pos
                <fs_puntivendita>-shop_id
                <fs_puntivendita>-shop_insegna
                <fs_puntivendita>-tip_pos
                <fs_puntivendita>-numero_pos
* 105900: inizio modifica del 22.09.2016 - tm
                <fs_puntivendita>-stato
* 105900: fine   modifica del 22.09.2016 - tm
                <fs_puntivendita>-zzzzateco
                <fs_puntivendita>-zzz_iban_acc
                <fs_puntivendita>-zz_iban_add
* introduzione campi VPOS
                <fs_puntivendita>-zzz_str_reg_add
                <fs_puntivendita>-zzz_str_reg_acc
                <fs_puntivendita>-zzz_vp_gest_term
                <fs_puntivendita>-zzzpostepay
                <fs_puntivendita>-zzz_cc_internaz
                <fs_puntivendita>-zzz_masterpass
"RU 20.09.2019 12:11:24 iniziativa E-COMMERCE 19.10
                <fs_puntivendita>-zzz_recurring
                <fs_puntivendita>-zzz_cardonfile
                <fs_puntivendita>-zzz_moto
                <fs_puntivendita>-zzz_config_ecomm
                INTO lv_line
                SEPARATED BY ca_pipe.
* 105900: eng - inizio modifica del 29.09.2016 - tm
*    TRANSFER lv_line TO va_fileout.
    TRANSFER lv_line TO va_fileout_temp.
* 105900: eng - fine modifica del 29.09.2016 - tm
  ENDLOOP.

* -- Scrittura Record di Punti Vendita
  LOOP AT pt_terminali ASSIGNING <fs_terminali>.

    CLEAR lv_line.
    CONCATENATE <fs_terminali>-tipo_record
                <fs_terminali>-codice_crm
                <fs_terminali>-zzorder_id
                <fs_terminali>-shop_id
                <fs_terminali>-terminal_id
                <fs_terminali>-zzcreate_at
                <fs_terminali>-zzowner
                <fs_terminali>-zzdevice_type
                <fs_terminali>-zzzstato
                INTO lv_line
                SEPARATED BY ca_pipe.
* 105900: inizio modifica del 29.09.2016 - eng
*    TRANSFER lv_line TO va_fileout.
    TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng

  ENDLOOP.
* -- Scrittura Record di Log
  PERFORM f_scrivi_log USING ps_header-codice_crm
                             text-l01.

ENDFORM.                    " f_scrivi_record
*&---------------------------------------------------------------------*
*&      Form  f_scrivi_log
*&---------------------------------------------------------------------*
*     Scrittura File di log
*----------------------------------------------------------------------*
FORM f_scrivi_log  USING    pv_object_id TYPE t_header-codice_crm
                            pv_msg       TYPE string.

  DATA: lv_line TYPE string.
  CLEAR lv_line.

  CONCATENATE pv_object_id
              pv_msg
              INTO lv_line
              SEPARATED BY ca_pipe.

  TRANSFER lv_line TO va_filelog.

ENDFORM.                    " f_scrivi_log
*&---------------------------------------------------------------------*
*&      Form  f_scrivi_error
*&---------------------------------------------------------------------*
*     Scrittura Errore in File di log
*----------------------------------------------------------------------*
FORM f_scrivi_error  USING pv_codice  TYPE string
                           pv_campo   TYPE string.

  DATA: lv_line TYPE string.
  CLEAR lv_line.

  CONCATENATE text-e14 pv_campo text-e15 INTO lv_line SEPARATED BY space.

  CONCATENATE pv_codice
              lv_line
              INTO lv_line
              SEPARATED BY ca_pipe.

  TRANSFER lv_line TO va_filelog.

ENDFORM.                    " f_scrivi_error
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
ENDFORM.                    " trascod_guid_16_32


*&---------------------------------------------------------------------*
*&      Form  f_estrai_tipologiche
*&---------------------------------------------------------------------*
*    Estrazione Tipologiche
*----------------------------------------------------------------------*
FORM f_estrai_tipologiche.

  REFRESH gt_nop_motivo.
  SELECT * FROM zca_nop_motivo INTO TABLE gt_nop_motivo.
  SORT gt_nop_motivo BY motivo.

ENDFORM.                    " f_estrai_tipologiche
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
  CALL FUNCTION 'CRM_LINK_INIT_OW'.


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

*
*&---------------------------------------------------------------------*
*&      Form  set_classe_click
*&---------------------------------------------------------------------*
*       Valorizzazione campo classe_click per file PF
*----------------------------------------------------------------------*
FORM set_classe_click  USING    p_tipo_contratto     TYPE crmd_orderadm_h-process_type
                                p_canale_provenienza TYPE crmd_customer_h-zz_provenienza
                                p_object_id          TYPE crmd_orderadm_h-object_id
                                p_funzione_partner   TYPE char8
                       CHANGING p_classe_click       TYPE char05.

  DATA: lr_field      TYPE RANGE OF zmp_addon_prod-field,
        lv_flag_inte  TYPE flag,
        lt_addon_prod TYPE STANDARD TABLE OF zmp_addon_prod,
        ls_addon_prod TYPE zmp_addon_prod,
        ls_field      LIKE LINE OF lr_field.

  FIELD-SYMBOLS: <fs_param> TYPE zca_param.

  CHECK p_object_id IS NOT INITIAL.

  " Controllo che il process_type deve essere presente nel gruppo
  READ TABLE gt_type TRANSPORTING NO FIELDS
    WITH KEY z_val_par = p_tipo_contratto.
  CHECK sy-subrc IS INITIAL.

  " Controllo che il CRMD_CUSTOMER_H-ZZ_PROVENIENZA deve essere presente nel gruppo
  READ TABLE gt_prov TRANSPORTING NO FIELDS
    WITH KEY z_val_par = p_canale_provenienza.
  CHECK sy-subrc IS INITIAL.

  REFRESH lt_addon_prod.
  lt_addon_prod[] = gt_zmp_addon_prod[].

  IF p_funzione_partner EQ gv_pft_cliente. " Intestatario
    CHECK gr_inte[] IS NOT INITIAL.
    DELETE lt_addon_prod WHERE object_id NE p_object_id AND NOT field IN gr_inte.
  ELSEIF p_funzione_partner EQ gv_pft_cointestat. " Cointestatario
    CHECK gr_coin[] IS NOT INITIAL.
    DELETE lt_addon_prod WHERE object_id NE p_object_id AND NOT field IN gr_coin.
  ENDIF.

  READ TABLE lt_addon_prod INTO ls_addon_prod INDEX 1.

  CHECK sy-subrc IS INITIAL.

  " Recupero il valore dallo Z_NOME_PAR
  UNASSIGN <fs_param>.
  IF p_funzione_partner EQ gv_pft_cliente. " Intestatario
    READ TABLE gt_inte ASSIGNING <fs_param>
      WITH KEY z_val_par = ls_addon_prod-field.
  ELSEIF p_funzione_partner EQ gv_pft_cointestat. " Cointestatario
    READ TABLE gt_coin ASSIGNING <fs_param>
      WITH KEY z_val_par = ls_addon_prod-field.
  ENDIF.

  CHECK <fs_param> IS ASSIGNED.

  p_classe_click = <fs_param>-z_nome_par.

ENDFORM.                    " set_classe_click
*&---------------------------------------------------------------------*
*&      Form  f_estrai_privacy
*&---------------------------------------------------------------------*
*       Estrazione Massiva ZCA_PRIVACY
*----------------------------------------------------------------------*
FORM f_estrai_privacy .

  DATA: lt_privacy TYPE STANDARD TABLE OF zca_privacy.

  REFRESH: gt_privacy_tab1,gt_privacy_tab2.

  SELECT * FROM zca_privacy INTO TABLE lt_privacy.

  gt_privacy_tab1[] = lt_privacy[].
  DELETE gt_privacy_tab1[] WHERE tabella         NOT IN gr_tab1.

  gt_privacy_tab2[] = lt_privacy[].
  DELETE gt_privacy_tab2[] WHERE tabella         NOT IN gr_tab2.

  SORT: gt_privacy_tab1 BY tabella campo_chiave,
        gt_privacy_tab2 BY tabella campo_chiave.

ENDFORM.                    " f_estrai_privacy


*&---------------------------------------------------------------------*
*&      Form  f_set_range
*&---------------------------------------------------------------------*
*       Set range
*----------------------------------------------------------------------*
FORM f_set_range .

  DATA:  ls_range  LIKE LINE OF gr_inte,
         ls_range1 LIKE LINE OF gr_tab1.

  FIELD-SYMBOLS <fs_param> TYPE zca_param.

  ls_range-sign   = ca_i.
  ls_range-option = ca_eq.

  LOOP AT gt_inte ASSIGNING <fs_param>.
    ls_range-low = <fs_param>-z_val_par.
    APPEND ls_range TO gr_inte.
    CLEAR ls_range-low.
  ENDLOOP.

  LOOP AT gt_coin ASSIGNING <fs_param>.
    ls_range-low = <fs_param>-z_val_par.
    APPEND ls_range TO gr_coin.
    CLEAR ls_range-low.
  ENDLOOP.


  ls_range1-sign   = ca_i.
  ls_range1-option = ca_eq.
  LOOP AT gt_tab1 ASSIGNING <fs_param>.

    ls_range-low = <fs_param>-z_val_par.
    APPEND ls_range TO gr_tab1.
    CLEAR ls_range-low.
  ENDLOOP.

  LOOP AT gt_tab2 ASSIGNING <fs_param>.
    ls_range1-low = <fs_param>-z_val_par.
    APPEND ls_range1 TO gr_tab2.
    CLEAR ls_range1-low.
  ENDLOOP.

ENDFORM.                    " f_set_range
*&---------------------------------------------------------------------*
*&      Form  f_check_cons_pf
*&---------------------------------------------------------------------*
FORM f_check_cons_pf  USING    p_nome_cons    TYPE string
                               p_partner_prod TYPE crmt_item_descr_partner
                      CHANGING p_flag         TYPE flag.


  CONSTANTS:   lc_coro01(12)     TYPE c VALUE 'CORO01-RADIO',
               lc_coro02(12)     TYPE c VALUE 'CORO02-RADIO',
               lc_coro03(12)     TYPE c VALUE 'CORO03-RADIO',
               lc_coro04(12)     TYPE c VALUE 'CORO04-RADIO',
               lc_coro01_ai(15)  TYPE c VALUE 'CORO01_AI-RADIO',
               lc_coro02_ai(15)  TYPE c VALUE 'CORO02_AI-RADIO',
               lc_coro03_ai(15)  TYPE c VALUE 'CORO03_AI-RADIO',
               lc_coro04_ai(15)  TYPE c VALUE 'CORO04_AI-RADIO',
               lc_cpiuric(13)    TYPE c VALUE 'CPIURIC-RADIO',
               lc_cpiutcag(14)   TYPE c VALUE 'CPIUTCAG-RADIO',
               lc_cpiuricai(15)  TYPE c VALUE 'CPIURICAI-RADIO',
               lc_cpiutcagai(16) TYPE c VALUE 'CPIUTCAGAI-RADIO',
               lc_fido06(12)     TYPE c VALUE 'FIDO06-RADIO',
               lc_fido07(12)     TYPE c VALUE 'FIDO07-RADIO',
               lc_fido08(12)     TYPE c VALUE 'FIDO08-RADIO',
               lc_fido09(12)     TYPE c VALUE 'FIDO09-RADIO',
               lc_00000001(8)    TYPE c VALUE '00000001',
               lc_ztsc0316(8)    TYPE c VALUE 'ZTSC0316',
               lc_ztsc0303(8)    TYPE c VALUE 'ZTSC0303',
               lc_ztsc0317(8)    TYPE c VALUE 'ZTSC0317',
               lc_ztsc0318(8)    TYPE c VALUE 'ZTSC0318',
               lc_ztsc0319(8)    TYPE c VALUE 'ZTSC0319'.

  DATA lv_entrato TYPE flag.

  FIELD-SYMBOLS: <fs_partner>  LIKE LINE OF i_partner.

  CLEAR p_flag.

  READ TABLE gt_cond TRANSPORTING NO FIELDS
     WITH KEY z_val_par = p_nome_cons.
  IF sy-subrc IS INITIAL.
    READ TABLE i_partner ASSIGNING <fs_partner>
      WITH KEY partner_no = p_partner_prod.
    CHECK sy-subrc IS INITIAL.

    READ TABLE gt_cond TRANSPORTING NO FIELDS
       WITH KEY z_val_par = p_nome_cons
                z_label   = <fs_partner>-partner_fct.
    CHECK sy-subrc IS INITIAL.
    p_flag = ca_x.
  ELSE.
    p_flag = ca_x.
  ENDIF.

ENDFORM.                    " f_check_cons_pf



*&---------------------------------------------------------------------*
*&      Form  ESTRAI_DATI_PUNTIVENDITA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM estrai_dati_puntivendita USING   lt_guid TYPE t_guid16_tab.

  SELECT
         record_id
         parent_id
         object_id
         zzzshop_id
         zzzshop_insegna
         zzznr_pospi_std
         zzznr_pospi_adsl
         zzznr_pospi_cord
         zzznr_pospi_ppad
         zzznr_pospi_gprs
         zzznr_pospi_altr
         zzznr_postr_std
         zzznr_postr_adsl
         zzznr_postr_cord
         zzznr_postr_ppad
         zzznr_postr_gprs
         zzznr_postr_altr
         zznr_pp_std_old
         zznr_pp_adsl_old
         zznr_pp_cord_old
         zznr_pp_ppad_old
         zznr_pp_gprs_old
         zznr_pp_altr_old
         zznr_pt_std_old
         zznr_pt_adsl_old
         zznr_pt_cord_old
         zznr_pt_ppad_old
         zznr_pt_gprs_old
         zznr_pt_altr_old
         zznr_pt_self_old
         zznr_pospi_ptop
         zznr_postr_ptop
         zznr_pp_ptop_old
         zznr_pt_ptop_old
         zzzzateco
         zzz_iban_acc
         zz_iban_add
         zznr_postr_self
         zzznr_mpos
         zzznr_pospi_virt
         zzznr_postr_virt       "da portare solo in 18.07
* modifiche introduzione VPOS
         zzz_str_reg_add
         zzz_str_reg_acc
         zzz_vp_gest_term
         zzzpostepay
         zzz_cc_internaz
         zzz_masterpass
"RU 20.09.2019 12:13:08
         zzz_recurring
         zzz_cardonfile
         zzz_moto
         zzz_config_ecomm
    FROM zpuntivendita
    INTO TABLE lt_puntivendita
    FOR ALL ENTRIES IN lt_guid
    WHERE object_id = lt_guid-guid.


* 105900: inizio modifica del 22.09.2016 - tm

  DELETE lt_puntivendita WHERE zzzshop_id IS INITIAL.

* 105900: fine modifica del 22.09.2016 - tm
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ESTRAI_DATI_TERMINALI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_GUID16  text
*----------------------------------------------------------------------*
FORM estrai_dati_terminali  USING    lt_guid TYPE t_guid16_tab.
  SELECT
       record_id
         parent_id
         object_id
         zzorder_id
         zzterminal_id
         zzcreate_at
         zzzstato
         zzowner
         zzdevice_type
    FROM zca_terminal
    INTO TABLE lt_terminali
    FOR ALL ENTRIES IN lt_guid
    WHERE object_id = lt_guid-guid.


* 105900: inizio modifica del 22.09.2016 - tm

  DELETE lt_terminali WHERE zzterminal_id IS INITIAL.

* 105900: fine modifica del 22.09.2016 - tm

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F_PREPARA_PUNTIVENDITA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<FS_GUID>  text
*      -->P_LS_HEADER  text
*      <--P_TB_PUNTIVENDITA  text
*      <--P_FL_ERROR  text
*----------------------------------------------------------------------*
FORM f_prepara_puntivendita  USING    ps_guid   TYPE bapibus20001_guid_dis
                                      ls_header TYPE t_header
                                      pt_relazioni   TYPE tt_relazioni
                             CHANGING tb_puntivendita TYPE t_puntivendita_tab
                                      pf_error TYPE c.

  DATA: l_puntivendita TYPE t_puntivendita.
  DATA: lv_cod_ateco   TYPE zca_ateco_mcc-cod_ateco.
  DATA: w_puntivendita TYPE ls_puntivendita.
  DATA: lt_rel_pv      TYPE ts_relazioni.

  FIELD-SYMBOLS: <ls_tipo_pos> TYPE ls_tipo_pos.
  FIELD-SYMBOLS: <fs_item>          TYPE bapibus20001_item_dis.

  REFRESH: tb_puntivendita[].

  READ TABLE i_item TRANSPORTING NO FIELDS WITH KEY header = ps_guid-guid.
  LOOP AT i_item ASSIGNING <fs_item> FROM sy-tabix.
    CLEAR l_puntivendita.
    IF <fs_item>-header NE ps_guid-guid.
      EXIT.
    ENDIF.

    l_puntivendita-tipo_record     = ca_pp.
    l_puntivendita-codice_crm      = ls_header-codice_crm.

* INIZIO RU 16/10/2018 grandi esercenti
    IF pt_relazioni[] IS NOT INITIAL.
      CLEAR lt_rel_pv.
      LOOP AT pt_relazioni INTO lt_rel_pv.
        CLEAR w_puntivendita.
        READ TABLE lt_puntivendita INTO w_puntivendita WITH KEY record_id = lt_rel_pv-guid_pv.
        IF sy-subrc IS INITIAL.

          l_puntivendita-id_pos = lt_rel_pv-progressivo_item.

          SELECT SINGLE stat
            FROM crm_jest
            INTO l_puntivendita-stato
           WHERE inact = '' AND
                 stat LIKE 'E%' AND
                 objnr = w_puntivendita-parent_id.

          CLEAR: l_puntivendita-shop_id, l_puntivendita-shop_insegna,
              l_puntivendita-tip_pos, l_puntivendita-numero_pos, l_puntivendita-zzzzateco,
              l_puntivendita-zzz_iban_acc, l_puntivendita-zz_iban_add,
              "introduzione campi VPOS
              l_puntivendita-zzz_str_reg_add, l_puntivendita-zzz_str_reg_acc,
              l_puntivendita-zzz_vp_gest_term, l_puntivendita-zzzpostepay,
              l_puntivendita-zzz_cc_internaz, l_puntivendita-zzz_masterpass,
              "RU 20.09.2019 12:13:59 e-commerce
              l_puntivendita-zzz_recurring, l_puntivendita-zzz_cardonfile,
              l_puntivendita-zzz_moto, l_puntivendita-zzz_config_ecomm.

*     modifica valorizzazione del codice ateco
          SELECT SINGLE cod_ateco
            INTO lv_cod_ateco
            FROM zca_ateco_mcc
            WHERE id_ateco = w_puntivendita-zzzzateco.

          IF sy-subrc IS NOT INITIAL.
            lv_cod_ateco = space.
          ENDIF.

          l_puntivendita-shop_id      = w_puntivendita-zzzshop_id.
          l_puntivendita-shop_insegna = w_puntivendita-zzzshop_insegna.
          l_puntivendita-zzzzateco    = lv_cod_ateco.
          l_puntivendita-zzz_iban_acc = w_puntivendita-zzz_iban_acc.
          l_puntivendita-zz_iban_add  = w_puntivendita-zz_iban_add.
*     introduzione campi VPOS
          l_puntivendita-zzz_str_reg_add  = w_puntivendita-zzz_str_reg_add.
          l_puntivendita-zzz_str_reg_acc  = w_puntivendita-zzz_str_reg_acc.
          l_puntivendita-zzz_vp_gest_term = w_puntivendita-zzz_vp_gest_term.
          l_puntivendita-zzzpostepay      = w_puntivendita-zzzpostepay.
          l_puntivendita-zzz_cc_internaz  = w_puntivendita-zzz_cc_internaz.
          l_puntivendita-zzz_masterpass   = w_puntivendita-zzz_masterpass.
          "RU 20.09.2019 12:15:19 e-commerce
          l_puntivendita-zzz_recurring    = w_puntivendita-zzz_recurring.
          l_puntivendita-zzz_cardonfile   = w_puntivendita-zzz_cardonfile.
          l_puntivendita-zzz_moto         = w_puntivendita-zzz_moto.
          l_puntivendita-zzz_config_ecomm = w_puntivendita-zzz_config_ecomm.

*    Fisso Standard --> TIPO POS CA1

          CLEAR: num_pos, descr_pos.
          IF NOT w_puntivendita-zzznr_pospi_std IS INITIAL OR
             NOT w_puntivendita-zzznr_postr_std IS INITIAL.
            num_pos = w_puntivendita-zzznr_pospi_std + w_puntivendita-zzznr_postr_std.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca1.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.


*     Fisso ADSL/Ethernet --> TIPO POS CA2.
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zzznr_pospi_adsl IS INITIAL OR
             NOT w_puntivendita-zzznr_postr_adsl IS INITIAL.
            num_pos = w_puntivendita-zzznr_pospi_adsl + w_puntivendita-zzznr_postr_adsl.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca2.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.

*     CORDLESS --> TIPO POS CA3
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zzznr_pospi_cord IS INITIAL OR
             NOT w_puntivendita-zzznr_postr_cord IS INITIAL.
            num_pos = w_puntivendita-zzznr_pospi_cord + w_puntivendita-zzznr_postr_cord.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca3.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.

*     GPRS con SIM Integrata --> CA4
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zzznr_pospi_gprs IS INITIAL OR
             NOT w_puntivendita-zzznr_postr_gprs IS INITIAL.
            num_pos = w_puntivendita-zzznr_pospi_gprs + w_puntivendita-zzznr_postr_gprs.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca4.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.

*     PIN PAD Base --> CA5
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zzznr_pospi_ppad IS INITIAL OR
             NOT w_puntivendita-zzznr_postr_ppad IS INITIAL.
            num_pos = w_puntivendita-zzznr_pospi_ppad + w_puntivendita-zzznr_postr_ppad.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca5.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.

*     PIN PAD Top --> CA6
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zznr_pospi_ptop IS INITIAL OR
             NOT w_puntivendita-zznr_postr_ptop IS INITIAL.
            num_pos = w_puntivendita-zznr_pospi_ptop + w_puntivendita-zznr_postr_ptop.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca6.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.

*     altro --> ALT
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zzznr_pospi_altr IS INITIAL OR
             NOT w_puntivendita-zzznr_postr_altr IS INITIAL.
            num_pos = w_puntivendita-zzznr_pospi_altr + w_puntivendita-zzznr_postr_altr.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_alt.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.

*     MobilePOS --> MOP
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zzznr_mpos IS INITIAL.
            num_pos = w_puntivendita-zzznr_mpos.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_mop.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.

*     Self-Unattended --> UNT
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zznr_postr_self IS INITIAL.
            num_pos = w_puntivendita-zznr_postr_self.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_unt.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.

*     VIRTUAL POS --> CA7
          CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
          IF NOT w_puntivendita-zzznr_pospi_virt IS INITIAL
             OR NOT w_puntivendita-zzznr_postr_virt IS INITIAL.    "da inserire solo con la 18.07
            num_pos = w_puntivendita-zzznr_pospi_virt + w_puntivendita-zzznr_postr_virt.
            READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca7.
            IF sy-subrc EQ 0.
*              descr_pos = <ls_tipo_pos>-descrizione.
              descr_pos = <ls_tipo_pos>-tipo_pos.
            ENDIF.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.


          READ TABLE tb_puntivendita WITH KEY shop_id = l_puntivendita-shop_id TRANSPORTING NO FIELDS.

          IF NOT sy-subrc IS INITIAL AND l_puntivendita-shop_id IS NOT INITIAL.
            l_puntivendita-tip_pos = descr_pos.
            l_puntivendita-numero_pos = num_pos.
            APPEND l_puntivendita TO tb_puntivendita.
          ENDIF.
        ENDIF.


      ENDLOOP.
    ELSE.
* FINE  RU 16/10/2018 grandi esercenti

      l_puntivendita-id_pos          = <fs_item>-number_int.
* 105900: inizio modifica del 22.09.2016
      READ TABLE i_status_pos INTO l_status_pos WITH KEY guid = <fs_item>-guid.
      IF sy-subrc EQ 0.
        l_puntivendita-stato = l_status_pos-status.
      ENDIF.

*   105900: fine modifica del 22.09.2016
      LOOP AT lt_puntivendita INTO w_puntivendita WHERE parent_id EQ <fs_item>-guid
                                                    AND object_id EQ <fs_item>-header.

        CLEAR: l_puntivendita-shop_id, l_puntivendita-shop_insegna,
               l_puntivendita-tip_pos, l_puntivendita-numero_pos, l_puntivendita-zzzzateco,
               l_puntivendita-zzz_iban_acc, l_puntivendita-zz_iban_add,
               "introduzione campi VPOS
               l_puntivendita-zzz_str_reg_add, l_puntivendita-zzz_str_reg_acc,
               l_puntivendita-zzz_vp_gest_term, l_puntivendita-zzzpostepay,
               l_puntivendita-zzz_cc_internaz, l_puntivendita-zzz_masterpass,
               "RU 20.09.2019 12:13:59 e-commerce
               l_puntivendita-zzz_recurring, l_puntivendita-zzz_cardonfile,
               l_puntivendita-zzz_moto, l_puntivendita-zzz_config_ecomm.

*   modifica valorizzazione del codice ateco
        SELECT SINGLE cod_ateco
          INTO lv_cod_ateco
          FROM zca_ateco_mcc
          WHERE id_ateco = w_puntivendita-zzzzateco.

        IF sy-subrc IS NOT INITIAL.
          lv_cod_ateco = space.
        ENDIF.

        l_puntivendita-shop_id      = w_puntivendita-zzzshop_id.
        l_puntivendita-shop_insegna = w_puntivendita-zzzshop_insegna.
        l_puntivendita-zzzzateco    = lv_cod_ateco.
        l_puntivendita-zzz_iban_acc = w_puntivendita-zzz_iban_acc.
        l_puntivendita-zz_iban_add  = w_puntivendita-zz_iban_add.
*   introduzione campi VPOS
        l_puntivendita-zzz_str_reg_add  = w_puntivendita-zzz_str_reg_add.
        l_puntivendita-zzz_str_reg_acc  = w_puntivendita-zzz_str_reg_acc.
        l_puntivendita-zzz_vp_gest_term = w_puntivendita-zzz_vp_gest_term.
        l_puntivendita-zzzpostepay      = w_puntivendita-zzzpostepay.
        l_puntivendita-zzz_cc_internaz  = w_puntivendita-zzz_cc_internaz.
        l_puntivendita-zzz_masterpass   = w_puntivendita-zzz_masterpass.
     "RU 20.09.2019 12:15:19 e-commerce
        l_puntivendita-zzz_recurring    = w_puntivendita-zzz_recurring.
        l_puntivendita-zzz_cardonfile   = w_puntivendita-zzz_cardonfile.
        l_puntivendita-zzz_moto         = w_puntivendita-zzz_moto.
        l_puntivendita-zzz_config_ecomm = w_puntivendita-zzz_config_ecomm.

*  Fisso Standard --> TIPO POS CA1

        CLEAR: num_pos, descr_pos.
        IF NOT w_puntivendita-zzznr_pospi_std IS INITIAL OR
           NOT w_puntivendita-zzznr_postr_std IS INITIAL.
          num_pos = w_puntivendita-zzznr_pospi_std + w_puntivendita-zzznr_postr_std.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca1.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.


*   Fisso ADSL/Ethernet --> TIPO POS CA2.
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zzznr_pospi_adsl IS INITIAL OR
           NOT w_puntivendita-zzznr_postr_adsl IS INITIAL.
          num_pos = w_puntivendita-zzznr_pospi_adsl + w_puntivendita-zzznr_postr_adsl.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca2.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.

*   CORDLESS --> TIPO POS CA3
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zzznr_pospi_cord IS INITIAL OR
           NOT w_puntivendita-zzznr_postr_cord IS INITIAL.
          num_pos = w_puntivendita-zzznr_pospi_cord + w_puntivendita-zzznr_postr_cord.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca3.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.

*   GPRS con SIM Integrata --> CA4
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zzznr_pospi_gprs IS INITIAL OR
           NOT w_puntivendita-zzznr_postr_gprs IS INITIAL.
          num_pos = w_puntivendita-zzznr_pospi_gprs + w_puntivendita-zzznr_postr_gprs.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca4.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.

*   PIN PAD Base --> CA5
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zzznr_pospi_ppad IS INITIAL OR
           NOT w_puntivendita-zzznr_postr_ppad IS INITIAL.
          num_pos = w_puntivendita-zzznr_pospi_ppad + w_puntivendita-zzznr_postr_ppad.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca5.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.

*   PIN PAD Top --> CA6
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zznr_pospi_ptop IS INITIAL OR
           NOT w_puntivendita-zznr_postr_ptop IS INITIAL.
          num_pos = w_puntivendita-zznr_pospi_ptop + w_puntivendita-zznr_postr_ptop.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca6.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.

*   altro --> ALT
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zzznr_pospi_altr IS INITIAL OR
           NOT w_puntivendita-zzznr_postr_altr IS INITIAL.
          num_pos = w_puntivendita-zzznr_pospi_altr + w_puntivendita-zzznr_postr_altr.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_alt.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.

*   MobilePOS --> MOP
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zzznr_mpos IS INITIAL.
          num_pos = w_puntivendita-zzznr_mpos.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_mop.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.

*   Self-Unattended --> UNT
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zznr_postr_self IS INITIAL.
          num_pos = w_puntivendita-zznr_postr_self.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_unt.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.

*   VIRTUAL POS --> CA7
        CLEAR: num_pos, descr_pos, l_puntivendita-tip_pos, l_puntivendita-numero_pos.
        IF NOT w_puntivendita-zzznr_pospi_virt IS INITIAL
           OR NOT w_puntivendita-zzznr_postr_virt IS INITIAL.    "da inserire solo con la 18.07
          num_pos = w_puntivendita-zzznr_pospi_virt + w_puntivendita-zzznr_postr_virt.
          READ TABLE lt_tipo_pos ASSIGNING <ls_tipo_pos> WITH KEY tipo_pos = c_ca7.
          IF sy-subrc EQ 0.
*            descr_pos = <ls_tipo_pos>-descrizione.
            descr_pos = <ls_tipo_pos>-tipo_pos.
          ENDIF.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.


        READ TABLE tb_puntivendita WITH KEY shop_id = l_puntivendita-shop_id TRANSPORTING NO FIELDS.

        IF NOT sy-subrc IS INITIAL AND l_puntivendita-shop_id IS NOT INITIAL.
          l_puntivendita-tip_pos = descr_pos.
          l_puntivendita-numero_pos = num_pos.
          APPEND l_puntivendita TO tb_puntivendita.
        ENDIF.


      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F_PREPARA_TERMINALI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<FS_GUID>  text
*      -->P_LS_HEADER  text
*      <--P_TB_TERMINALI  text
*      <--P_FL_ERROR  text
*----------------------------------------------------------------------*
FORM f_prepara_terminali  USING     ps_guid   TYPE bapibus20001_guid_dis
                                    ls_header TYPE t_header
                                    tb_puntivendita TYPE t_puntivendita_tab
                                    pt_relazioni    TYPE tt_relazioni
                          CHANGING  tb_terminali TYPE t_terminali_tab
                                    fl_error TYPE c.

  DATA: l_terminali    TYPE t_terminali,
        l_puntivendita TYPE t_puntivendita,
        w_terminali    TYPE ls_terminali,
        lt_rel_pv      TYPE ts_relazioni,
        lv_guid_f      TYPE crmt_object_guid.

  FIELD-SYMBOLS: <fs_item>          TYPE bapibus20001_item_dis.

  REFRESH: tb_terminali[].

  READ TABLE i_item TRANSPORTING NO FIELDS WITH KEY header = ps_guid-guid.
  LOOP AT i_item ASSIGNING <fs_item> FROM sy-tabix.
    CLEAR l_terminali.
    IF <fs_item>-header NE ps_guid-guid.
      EXIT.
    ENDIF.

    l_terminali-tipo_record     = ca_pt.
    l_terminali-codice_crm      = ls_header-codice_crm.

* INIZIO RU 16/10/2018 grandi esercenti
    IF pt_relazioni[] IS NOT INITIAL.
      CLEAR lt_rel_pv.
      LOOP AT pt_relazioni INTO lt_rel_pv.
        CLEAR: w_terminali,
               lv_guid_f.

        SELECT SINGLE guid
          FROM crmd_orderadm_h
          INTO lv_guid_f
         WHERE object_id EQ lt_rel_pv-figlio.
        IF sy-subrc IS INITIAL.

          LOOP AT lt_terminali INTO w_terminali WHERE  object_id = lv_guid_f AND
                                                       zzorder_id EQ lt_rel_pv-progressivo_item.

            l_terminali-zzorder_id = w_terminali-zzorder_id.
            l_terminali-shop_id    = lt_rel_pv-punto_vendita.
            l_terminali-terminal_id = w_terminali-zzterminal_id.
            l_terminali-zzcreate_at = w_terminali-zzcreate_at.
            l_terminali-zzowner     = w_terminali-zzowner.
            l_terminali-zzdevice_type = w_terminali-zzdevice_type.
            l_terminali-zzzstato      = w_terminali-zzzstato.
            APPEND l_terminali TO tb_terminali.

          ENDLOOP.
        ENDIF.
      ENDLOOP.
    ELSE.
* FINE RU 16/10/2018 grandi esercenti

      LOOP AT lt_terminali INTO w_terminali WHERE object_id = <fs_item>-header
                                               AND zzorder_id EQ <fs_item>-number_int.

        l_terminali-zzorder_id = w_terminali-zzorder_id.
        READ TABLE tb_puntivendita INTO l_puntivendita WITH KEY id_pos = <fs_item>-number_int.
        IF sy-subrc EQ 0.
          l_terminali-shop_id = l_puntivendita-shop_id.
        ENDIF.
        l_terminali-terminal_id = w_terminali-zzterminal_id.
        l_terminali-zzcreate_at = w_terminali-zzcreate_at.
        l_terminali-zzowner     = w_terminali-zzowner.
        l_terminali-zzdevice_type = w_terminali-zzdevice_type.
        l_terminali-zzzstato      = w_terminali-zzzstato.
        APPEND l_terminali TO tb_terminali.
      ENDLOOP.
    ENDIF.

  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F_RINOMINA_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_rinomina_file .



  CLEAR lv_parameters.
  CONCATENATE va_fileout_temp va_fileout INTO lv_parameters SEPARATED BY space.


  CALL FUNCTION 'SXPG_COMMAND_EXECUTE'
    EXPORTING
      commandname                   = 'Z_MV_FLUSSI'
      additional_parameters         = lv_parameters
    EXCEPTIONS
      no_permission                 = 1
      command_not_found             = 2
      parameters_too_long           = 3
      security_risk                 = 4
      wrong_check_call_interface    = 5
      program_start_error           = 6
      program_termination_error     = 7
      x_error                       = 8
      parameter_expected            = 9
      too_many_parameters           = 10
      illegal_command               = 11
      wrong_asynchronous_parameters = 12
      cant_enq_tbtco_entry          = 13
      jobcount_generation_error     = 14
      OTHERS                        = 15.
  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-010. " Errore durante la ridenominazione del file.
  ENDIF.

ENDFORM.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
