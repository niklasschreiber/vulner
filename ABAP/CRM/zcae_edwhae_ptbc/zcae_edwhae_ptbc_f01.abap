*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_PTBC_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING p_logic TYPE filename-fileintern
                         p_param TYPE c
                   CHANGING p_fname TYPE c.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_logic
      parameter_1      = p_param
    IMPORTING
      file_name        = p_fname
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e02 p_logic text-e03 space.
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

  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    CLOSE DATASET va_fileout.
    MESSAGE e208(00) WITH text-e05.
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
  PERFORM get_date_to.
  PERFORM get_date_from.
  PERFORM select_zca_ptbc.
ENDFORM.                    " select_delta

*&---------------------------------------------------------------------*
*&      Form  get_date_to
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_TO
*----------------------------------------------------------------------*
FORM get_date_to .
* Il record esiste solo se il programma è stato lanciato in batch
  CLEAR st_tbtco_t.
  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco UP TO 1 ROWS
    INTO st_tbtco_t
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e06 text-e07 text-e08 space.
  ENDIF.
ENDFORM.                    " get_date_to

*&---------------------------------------------------------------------*
*&      Form  get_date_from
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_FROM
*----------------------------------------------------------------------*
FORM get_date_from .
  CHECK p_date_f IS INITIAL.

  CLEAR st_tbtco_f.
  REFRESH i_tbtco.
  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco
    INTO TABLE i_tbtco
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_f.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e09 text-e10 text-e11 space.
  ENDIF.

  SORT i_tbtco BY sdlstrtdt DESCENDING
                  sdlstrttm DESCENDING.
  READ TABLE i_tbtco INTO st_tbtco_f INDEX 1.
  p_date_f = st_tbtco_f-sdlstrtdt.
ENDFORM.                    " get_date_from

*&---------------------------------------------------------------------*
*&      Form  select_zca_ptbc
*&---------------------------------------------------------------------*
*       Selezione della ZCA_PTBC per estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_zca_ptbc .
  DATA lv_initdate TYPE zca_ptbc-z_data_mod.

  SELECT z_ptb_card z_type_card z_bp z_date_i z_date_f
         z_date_request z_date_sent z_date_req_sent
         z_attiva z_data_crea z_data_mod FROM zca_ptbc
    INTO TABLE i_zca_ptbc
    PACKAGE SIZE p_psize
    WHERE ( z_data_mod GE p_date_f AND z_data_mod LE st_tbtco_t-sdlstrtdt )

       OR ( z_data_mod  EQ lv_initdate AND "Z_DATA_MOD IS INITIAL
            z_data_crea GE p_date_f AND z_data_crea LE st_tbtco_t-sdlstrtdt )."#EC CI_NOFIELD

*   Trasferisce su file i record estratti
    PERFORM elabora.

  ENDSELECT.
ENDFORM.                    " select_zca_ptbc

*&---------------------------------------------------------------------*
*&      Form  elabora
*&---------------------------------------------------------------------*
*       Trasferisce su file i record estratti
*----------------------------------------------------------------------*
FORM elabora .
  DATA: va_recout TYPE string,
        va_reclog TYPE string.

  LOOP AT i_zca_ptbc ASSIGNING <fs_zca_ptbc>.
*   Trasferimento al file di out
    CLEAR va_recout.
    CONCATENATE <fs_zca_ptbc>-z_ptb_card
                <fs_zca_ptbc>-z_type_card
                <fs_zca_ptbc>-z_bp
                <fs_zca_ptbc>-z_date_i
                <fs_zca_ptbc>-z_date_f
                <fs_zca_ptbc>-z_date_request
                <fs_zca_ptbc>-z_date_sent
                <fs_zca_ptbc>-z_date_req_sent
                <fs_zca_ptbc>-z_attiva
                INTO va_recout SEPARATED BY ca_sep.
    TRANSFER va_recout TO va_fileout.

*   Trasferimento al file di log
    CLEAR va_reclog.
    CONCATENATE <fs_zca_ptbc>-z_ptb_card
                text-l01
                INTO va_reclog SEPARATED BY ca_sep.
    TRANSFER va_reclog TO va_filelog.
  ENDLOOP.
ENDFORM.                    " elabora

*&---------------------------------------------------------------------*
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Selezione della ZCA_PTBC per estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full .

  SELECT z_ptb_card z_type_card z_bp z_date_i z_date_f
         z_date_request z_date_sent z_date_req_sent
         z_attiva z_data_crea z_data_mod FROM zca_ptbc
    INTO TABLE i_zca_ptbc
    PACKAGE SIZE p_psize.                               "#EC CI_NOWHERE

*   Trasferisce su file i record estratti
    PERFORM elabora.

  ENDSELECT.

ENDFORM.                    " select_full

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
