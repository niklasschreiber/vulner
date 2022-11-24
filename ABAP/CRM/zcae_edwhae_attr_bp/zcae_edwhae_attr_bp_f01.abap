*----------------------------------------------------------------------*
***INCLUDE ZCAE_EDWHAE_ATTR_BP_F01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  check_date
*&---------------------------------------------------------------------*
*       Controlla che l'inserimento delle date in input sia corretto
*----------------------------------------------------------------------*
FORM check_date .
*--------------Inizio   MOD KLP 24/09/08--------------------
*  IF ( p_date_f IS NOT INITIAL AND p_time_f EQ space ) OR
*     ( p_date_f IS INITIAL AND p_time_f NE space ).
*    MESSAGE e208(00) WITH text-e01.
*  ENDIF.

  IF ( p_date_f IS NOT INITIAL AND p_time_f IS INITIAL ) OR
    ( p_date_f IS INITIAL AND p_time_f IS NOT INITIAL ).
    MESSAGE e208(00) WITH text-e01.
  ENDIF.
*----------------Fine   MOD KLP 24/09/08---------------------
ENDFORM.                    " check_date

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
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full .

* Select pacchettizzata
  SELECT partner trattamentodati1 trattamentodati2
         trattamentodati3 revoca_consenso data_revoca pot_comm datum uzeit FROM zca_addonbp
    INTO TABLE i_zca_addonbp
    PACKAGE SIZE p_psize.                               "#EC CI_NOWHERE

*   Trasferisce su file i record estratti
    PERFORM elabora.

    REFRESH i_zca_addonbp.

  ENDSELECT.

ENDFORM.                    " select_full

*&---------------------------------------------------------------------*
*&      Form  elabora
*&---------------------------------------------------------------------*
*       Trasferisce su file i record estratti
*----------------------------------------------------------------------*
FORM elabora .
  tables: zca_addonbp_web.
  DATA: va_recout TYPE string,
        va_reclog TYPE string,
        consenso1 type zca_addonbp_web-consenso1,
        consenso2 type zca_addonbp_web-consenso2,
        consenso3 type zca_addonbp_web-consenso3.


  LOOP AT i_zca_addonbp ASSIGNING <fs_zca_addonbp>.
*   Trasferimento al file di out
    CLEAR va_recout.
    if <fs_zca_addonbp>-DATA_REVOCA eq '00000000'.
      replace <fs_zca_addonbp>-DATA_REVOCA WITH space into <fs_zca_addonbp>-DATA_REVOCA.
    endif.
    select single * from zca_addonbp_web where partner = <fs_zca_addonbp>-partner.
      if sy-subrc is initial.
        consenso1 = zca_addonbp_web-consenso1.
        consenso2 = zca_addonbp_web-consenso2.
        consenso3 = zca_addonbp_web-consenso3.
        endif.
    CONCATENATE <fs_zca_addonbp>-partner
                <fs_zca_addonbp>-trattamentodati1
                <fs_zca_addonbp>-trattamentodati2
                <fs_zca_addonbp>-trattamentodati3
                <fs_zca_addonbp>-pot_comm
                <fs_zca_addonbp>-REVOCA_CONSENSO
                <fs_zca_addonbp>-DATA_REVOCA
                consenso1
                consenso3
                consenso2
                INTO va_recout SEPARATED BY ca_sep.
    TRANSFER va_recout TO va_fileout.

*   Trasferimento al file di log
    CLEAR va_reclog.
    CONCATENATE <fs_zca_addonbp>-partner
                text-l01
                INTO va_reclog SEPARATED BY ca_sep.
    TRANSFER va_reclog TO va_filelog.

clear:
consenso1,
consenso2,
consenso3.

  ENDLOOP.

ENDFORM.                    " elabora

*&---------------------------------------------------------------------*
*&      Form  select_delta
*&---------------------------------------------------------------------*
*       Estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_delta .
  PERFORM get_date_time_to.
  PERFORM get_date_time_from.
  PERFORM select_zca_addonbp.
ENDFORM.                    " select_delta

*&---------------------------------------------------------------------*
*&      Form  get_date_time_to
*&---------------------------------------------------------------------*
*       Recupera i campi DATE_TO e TIME_TO
*----------------------------------------------------------------------*
FORM get_date_time_to .

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
ENDFORM.                    " get_date_time_to

*&---------------------------------------------------------------------*
*&      Form  get_date_time_from
*&---------------------------------------------------------------------*
*       Recupera i campi DATE_FROM e TIME_FROM
*----------------------------------------------------------------------*
FORM get_date_time_from .
  CHECK p_date_f IS INITIAL AND p_time_f IS INITIAL.

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
  p_time_f = st_tbtco_f-sdlstrttm.
ENDFORM.                    " get_date_time_from

*&---------------------------------------------------------------------*
*&      Form  select_zca_addonbp
*&---------------------------------------------------------------------*
*       Selezione della ZCA_ADDONBP per estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_zca_addonbp .

  SELECT partner trattamentodati1 trattamentodati2
         trattamentodati3 revoca_consenso data_revoca pot_comm datum uzeit FROM zca_addonbp
      INTO TABLE i_zca_addonbp
      PACKAGE SIZE p_psize
      WHERE datum GE p_date_f AND
            datum LE st_tbtco_t-sdlstrtdt.              "#EC CI_NOFIELD

*   Per i record con data agli estremi dell'intervallo, filtrare
*   sull'ora
    DELETE i_zca_addonbp WHERE datum EQ p_date_f AND
                               uzeit LT p_time_f.

    DELETE i_zca_addonbp WHERE datum EQ st_tbtco_t-sdlstrtdt AND
                               uzeit GT st_tbtco_t-sdlstrttm.

    IF i_zca_addonbp[] IS NOT INITIAL.
*     Trasferisce su file i record estratti
      PERFORM elabora.
    ENDIF.

    REFRESH i_zca_addonbp.

  ENDSELECT.

ENDFORM.                    " select_zca_addonbp

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
