*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_PROD_ACTIVITY_F01
*&---------------------------------------------------------------------*


*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING p_logic   TYPE filename-fileintern
                         p_param_1 TYPE c
                         p_param_2 TYPE c
                CHANGING p_fname   TYPE string.

  DATA: lv_file     TYPE string,
        lv_len      TYPE i,
        lv_len2     TYPE i.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_logic
      parameter_1      = p_param_1
      parameter_2      = p_param_2
    IMPORTING
      file_name        = lv_file
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e02 p_logic text-e03 space.
  ENDIF.

  IF p_ind IS INITIAL.
    lv_len  = strlen( lv_file ).
    lv_len  = lv_len - 5.
    lv_len2 = lv_len + 1.
    CONCATENATE lv_file(lv_len) lv_file+lv_len2 INTO p_fname.
  ELSE.
    p_fname = lv_file.
  ENDIF.

ENDFORM.                    " recupera_file
*&---------------------------------------------------------------------*
*&      Form  GET_FILES
*&---------------------------------------------------------------------*
*       Recupero dei files
*----------------------------------------------------------------------*
FORM get_files .
  DATA: lv_data(8)  TYPE c.

  lv_data = sy-datum.

  " Recupero file fisico a partire dal file logico per il file di output
  CLEAR gv_fileout.
  PERFORM recupera_file USING p_fout lv_data p_ind
                        CHANGING gv_fileout.

  " Recupero file fisico a partire dal file logico per il file di log
  CLEAR gv_filelog.
  PERFORM recupera_file USING p_flog lv_data p_ind
                        CHANGING gv_filelog.

ENDFORM.                    " GET_FILES
*&---------------------------------------------------------------------*
*&      Form  OPEN_FILES
*&---------------------------------------------------------------------*
*       Apertura dei file
*----------------------------------------------------------------------*
FORM open_files .

  " Apertura del file di output
  OPEN DATASET gv_fileout FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.

  " Apertura del file di log
  OPEN DATASET gv_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    CLOSE DATASET gv_fileout.
    MESSAGE e208(00) WITH text-e05.
  ENDIF.

ENDFORM.                    " OPEN_FILES
*&---------------------------------------------------------------------*
*&      Form  ESTR_ELAB
*&---------------------------------------------------------------------*
*       Estrazioni ed Elaborazione
*----------------------------------------------------------------------*
FORM estr_elab .


  IF r_delta IS NOT INITIAL.
    " Recupero le date
    PERFORM get_dates.

    " Apre i file di output e log
    PERFORM open_files.

    " Elaborazione Pacchettizzata
    PERFORM elab_delta.

  ELSE.

    " Apre i file di output e log
    PERFORM open_files.

    " Elaborazione Pacchettizzata
    PERFORM elab_full.

  ENDIF.

ENDFORM.                    " ESTR_ELAB
*&---------------------------------------------------------------------*
*&      Form  CLOSE_FILES
*&---------------------------------------------------------------------*
*       Chiusura dei file di out e di log
*----------------------------------------------------------------------*
FORM close_files .
  CLOSE DATASET: gv_fileout, gv_filelog.
ENDFORM.                    " CLOSE_FILES
*&---------------------------------------------------------------------*
*&      Form  GET_DATES
*&---------------------------------------------------------------------*
*       Recupero le date per il lancio Delta
*----------------------------------------------------------------------*
FORM get_dates .

  DATA: lr_status  TYPE RANGE OF tbtco-status,
        ls_stat_r  LIKE LINE  OF lr_status,
        lt_tbtco   TYPE STANDARD TABLE OF t_tbtco.

  FIELD-SYMBOLS <fs_tbtco> TYPE t_tbtco.

  ls_stat_r-option = gc_eq.
  ls_stat_r-sign   = gc_i.

  ls_stat_r-low    = gc_f.
  APPEND ls_stat_r TO lr_status.
  CLEAR ls_stat_r-low.

  ls_stat_r-low    = gc_r.
  APPEND ls_stat_r TO lr_status.
  CLEAR ls_stat_r-low.

* Il record esiste solo se il programma è stato lanciato in batch
  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status
    FROM tbtco
    INTO TABLE lt_tbtco
   WHERE jobname EQ gc_jobname
    AND  status  IN lr_status.

  " Recuoero della date_to
  READ TABLE lt_tbtco ASSIGNING <fs_tbtco> WITH KEY status = gc_r.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e06 text-e07 text-e08 space.
  ELSE.
    PERFORM trascod_data USING <fs_tbtco>-sdlstrtdt <fs_tbtco>-sdlstrttm
                         CHANGING gv_date_to.
  ENDIF.

  " Recupero della date_from
  IF p_date_f IS  NOT INITIAL.
    RETURN.
  ENDIF.

  DELETE lt_tbtco  WHERE status EQ gc_r.

  IF lt_tbtco[] IS INITIAL.
    MESSAGE e398(00) WITH text-e09 text-e10 text-e11 space.
  ENDIF.

  SORT lt_tbtco BY sdlstrtdt DESCENDING
                   sdlstrttm DESCENDING.

  READ TABLE lt_tbtco ASSIGNING <fs_tbtco> INDEX 1.
  IF sy-subrc IS INITIAL.
    PERFORM trascod_data USING <fs_tbtco>-sdlstrtdt <fs_tbtco>-sdlstrttm
                      CHANGING p_date_f.
  ENDIF.

ENDFORM.                    " GET_DATES
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
*&      Form  GET_PARAM
*&---------------------------------------------------------------------*
*       letture da PARAM
*----------------------------------------------------------------------*
FORM get_param.

  DATA: lt_return    TYPE bapiret2_t,
        lt_param     TYPE STANDARD TABLE OF zca_param,
        ls_proctype  LIKE LINE OF s_proct.

  FIELD-SYMBOLS: <fs_param> TYPE zca_param.

  " Se non sono presenti process_type in input li recupero da PARAM
  IF s_proct IS INITIAL.

    PERFORM read_group_param USING gc_edwa
                                   gc_appl
                          CHANGING lt_param[]
                                   lt_return[].

    ls_proctype-option = gc_eq.
    ls_proctype-sign   = gc_i.
    LOOP AT lt_param ASSIGNING <fs_param>.
      ls_proctype-low = <fs_param>-z_val_par.
      APPEND ls_proctype TO s_proct.
      CLEAR ls_proctype-low.
    ENDLOOP.

  ENDIF.


ENDFORM.                    " GET_PARAM

*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiamo FM Z_CA_READ_GROUP_PARAM
*----------------------------------------------------------------------*
FORM read_group_param USING p_gruppo    TYPE zgroup
                            p_appl      TYPE zappl
                   CHANGING pt_param    TYPE zca_param_t
                            pt_return   TYPE bapiret2_t.

  REFRESH: pt_param,
           pt_return.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_gruppo
      i_z_appl = p_appl
    TABLES
      param    = pt_param[]
      return   = pt_return[].

ENDFORM.                    "read_group_param
*&---------------------------------------------------------------------*
*&      Form  ELAB_DELTA
*&---------------------------------------------------------------------*
FORM elab_delta .

  SELECT guid
         object_id
         process_type
         description
    FROM crmd_orderadm_h
    INTO TABLE gt_orderadm_h
    PACKAGE SIZE p_psize
    WHERE process_type IN s_proct
      AND ( ( created_at GE p_date_f AND created_at LE gv_date_to )
       OR (   changed_at GE p_date_f AND changed_at LE gv_date_to ) ).

    " Recupero i dati
    PERFORM get_dati.

    " Elaborazione e scrittura dei file di output
    PERFORM elabora.

    REFRESH gt_orderadm_h.

  ENDSELECT.

ENDFORM.                    " ELAB_DELTA
*&---------------------------------------------------------------------*
*&      Form  ELAB_FULL
*&---------------------------------------------------------------------*
FORM elab_full .

  SELECT guid
         object_id
         process_type
    FROM crmd_orderadm_h
    INTO TABLE gt_orderadm_h
    PACKAGE SIZE p_psize
    WHERE process_type IN s_proct.

    " Recupero i dati
    PERFORM get_dati.

    " Elaborazione e scrittura dei file di output
    PERFORM elabora.

    REFRESH gt_orderadm_h.

  ENDSELECT.

ENDFORM.                    " ELAB_FULL
*&---------------------------------------------------------------------*
*&      Form  CALL_BAPI_GETDETAILMUL
*&---------------------------------------------------------------------*
FORM get_dati.

  IF gt_orderadm_h[] IS NOT INITIAL.

    REFRESH: gt_item.

    SELECT header
           description
      FROM crmd_orderadm_i
      INTO TABLE gt_item
      FOR ALL ENTRIES IN gt_orderadm_h
      WHERE header EQ gt_orderadm_h-guid.

    SORT gt_item   BY header.

  ENDIF.

ENDFORM.                    " GET_DATI
*&---------------------------------------------------------------------*
*&      Form  ELABORA
*&---------------------------------------------------------------------*
FORM elabora .

  DATA: lv_recout              TYPE string,
        lv_reclog              TYPE string,
        lv_tipo_contatto(4)    TYPE c,
        lv_cod_attivita(10)    TYPE c,
        lv_descrizione(40)     TYPE c,
        lv_descr_prod(40)      TYPE c.

  FIELD-SYMBOLS: <fs_orderadm_h>   TYPE t_orderadm_h,
                 <fs_item>         TYPE t_item.

  LOOP AT gt_orderadm_h ASSIGNING <fs_orderadm_h>.

    CLEAR: lv_tipo_contatto, lv_cod_attivita, lv_descrizione.

    lv_tipo_contatto = <fs_orderadm_h>-process_type.
    lv_cod_attivita  = <fs_orderadm_h>-object_id.
    lv_descrizione   = <fs_orderadm_h>-description.

    READ TABLE gt_item TRANSPORTING NO FIELDS WITH KEY header = <fs_orderadm_h>-guid BINARY SEARCH.
    LOOP AT gt_item ASSIGNING <fs_item> FROM sy-tabix.
      IF <fs_item>-header NE <fs_orderadm_h>-guid.
        EXIT.
      ENDIF.

      CLEAR lv_descr_prod.
      lv_descr_prod = <fs_item>-description.

      " Trasferimento al file di out
      CLEAR lv_recout.
      CONCATENATE lv_tipo_contatto
                  lv_cod_attivita
                  "lv_descrizione
                  lv_descr_prod
      INTO lv_recout SEPARATED BY gc_sep.

      TRANSFER lv_recout TO gv_fileout.

    ENDLOOP.

    " Trasferimento al file di log
    CLEAR lv_reclog.
    CONCATENATE lv_cod_attivita text-l01 INTO lv_reclog SEPARATED BY gc_sep.

    TRANSFER lv_reclog TO gv_filelog.

  ENDLOOP.

ENDFORM.                    " ELABORA
*&---------------------------------------------------------------------*
*&      Form  REFRESH
*&---------------------------------------------------------------------*
FORM refresh .

  REFRESH: gt_orderadm_h,
           gt_item.

  CLEAR: gv_date_to,
         gv_filelog,
         gv_fileout.

ENDFORM.                    " REFRESH
*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT
*&---------------------------------------------------------------------*
FORM check_input_from .

  IF p_date_f IS NOT INITIAL.

    DATA lv_timestamp TYPE  ad_tstamp.

    lv_timestamp = p_date_f.
    CALL FUNCTION 'ADDR_TIMESTAMP_IS_VALID'
      EXPORTING
        iv_timestamp      = lv_timestamp
      EXCEPTIONS
        zero_timestamp    = 1
        illegal_timestamp = 2
        OTHERS            = 3.

    IF sy-subrc <> 0.
      MESSAGE s208(00) DISPLAY LIKE 'E' WITH text-e12.
      STOP.
      LEAVE LIST-PROCESSING.
    ENDIF.

  ENDIF.

ENDFORM.                    " CHECK_INPUT_FROM
*&---------------------------------------------------------------------*
*&      Form  LOOP_AT_SCREEN
*&---------------------------------------------------------------------*
FORM loop_at_screen .

  LOOP AT SCREEN .
    IF r_delta = space.
      IF screen-group1 = 'ABC'.
        screen-input = '0'.
        CLEAR p_date_f.
      ENDIF.
    ELSE.
      IF screen-group1 = 'ABC'.
        screen-input = '1'.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

ENDFORM.                    " LOOP_AT_SCREEN


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
