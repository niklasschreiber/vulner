*&---------------------------------------------------------------------*
*& Report  Z_PROD_FILE_CSV
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_tgru.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X',
           r_full  RADIOBUTTON GROUP gr1,
           p_date_f TYPE cgpl_project-created_on,
           p_fout TYPE filename-fileintern DEFAULT 'ZCRMOUT001_CAMPAIGNR3' OBLIGATORY.
*           p_flog TYPE filename-fileintern
*             DEFAULT 'ZCRMLOG001_EDWHAE_ACTIVITY' OBLIGATORY,
*           p_ind(9) TYPE c  ."OBLIGATORY. " MOD SC 19/12/2008

SELECTION-SCREEN END OF BLOCK b1.

DATA file TYPE c LENGTH 120.

DATA: lt_tg  TYPE TABLE OF zcrm_tgroup,
      ls_tg  TYPE zcrm_tgroup.

DATA: BEGIN OF t_record_csv OCCURS 0,
      tg_guid        TYPE zcrm_tgroup-tg_guid,
      id_target_group TYPE zcrm_tgroup-id_target_group,
      descr_tg       TYPE zcrm_tgroup-descr_tg,
      nome_doc       TYPE zcrm_tgroup-nome_doc,
      stato_doc      TYPE zcrm_tgroup-stato_doc,
      id_campagna    TYPE zcrm_tgroup-id_campagna,
      data_last_mod  TYPE zcrm_tgroup-data_last_mod,
END OF t_record_csv.

DATA: p_file(128) TYPE c,
      p_file2(128) TYPE c,
      string_line TYPE string,
      subrc       TYPE sy-subrc,
      wa_id       TYPE cgpl_guid16.

CONSTANTS: ca_jobname     TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_TGRU',
           ca_r           TYPE tbtco-status         VALUE 'R'.

TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         status    TYPE tbtco-status,
       END OF t_tbtco.

DATA: lw_tbtco_t TYPE t_tbtco ,
      sy_date TYPE D.

* Il record esiste solo se il programma è stato lanciato in batch
  SELECT jobname jobcount sdlstrtdt
         status FROM tbtco UP TO 1 ROWS
    INTO lw_tbtco_t
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.
    sy_date = sy-datum.
  ELSE.
    sy_date = lw_tbtco_t-sdlstrtdt.
  ENDIF.


DATA: lv_file TYPE string,
      lv_path TYPE string,
      lv_filename TYPE string,
      lv_shift  TYPE I.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_fout
    IMPORTING
      file_name        = lv_path
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
  ENDIF.

CALL FUNCTION 'Z_ESTRAI_NOME_FILE'
  EXPORTING
    full_path       = lv_path
 IMPORTING
   FILE_NAME       =  lv_filename
          .
SEARCH lv_path FOR lv_filename.

lv_shift = SY-FDPOS.

lv_file = lv_path(lv_shift).


CONCATENATE lv_file 'ZCRMOUT001_CAMPAIGNTG_' sy_date '.csv' INTO file.


IF ( r_delta EQ 'X' ).

    IF p_date_f IS INITIAL.

        p_date_f = sy_date.

    ENDIF.

    SELECT * INTO TABLE lt_tg FROM zcrm_tgroup WHERE ( ( data_aggiunta_do  GE p_date_f ) AND ( data_aggiunta_do LE sy_date ) )
                                              OR ( ( data_approvazion  GE p_date_f ) AND ( data_approvazion LE sy_date ) )
                                              OR ( ( data_associazion  GE p_date_f ) AND ( data_associazion LE sy_date ) )
                                              OR  ( ( data_last_mod  GE p_date_f ) AND ( data_last_mod LE sy_date ) ).
ELSE.

  SELECT * INTO TABLE lt_tg FROM zcrm_tgroup.

ENDIF.

*CONCATENATE '/tmp/' 'ZCRMOUT001_CAMPAIGNTG_' sy-datum '.csv' INTO p_file.

*SELEZIONO TARGET GROUP DA TABELLA

SORT lt_tg BY ID_TARGET_GROUP ASCENDING CONTATORE DESCENDING.
DELETE ADJACENT DUPLICATES FROM  lt_tg COMPARING ID_TARGET_GROUP.


LOOP AT lt_tg INTO ls_tg.
  MOVE-CORRESPONDING ls_tg TO t_record_csv.
  APPEND t_record_csv.
ENDLOOP.

IF t_record_csv[] IS NOT INITIAL.

  OPEN DATASET file FOR OUTPUT IN TEXT MODE
                               ENCODING DEFAULT.

  IF sy-subrc EQ 0.

    LOOP AT t_record_csv .
      CLEAR: string_line.
      CONCATENATE t_record_csv-id_target_group
                  t_record_csv-descr_tg
                  t_record_csv-nome_doc
                  t_record_csv-stato_doc
                  t_record_csv-id_campagna
                  t_record_csv-data_last_mod
      INTO string_line SEPARATED BY '|'.

      TRANSFER string_line TO file.
      IF sy-subrc <> 0.
        subrc = sy-subrc.
      ENDIF.

    ENDLOOP.

    IF subrc EQ 0.
      WRITE : / 'Download target group eseguito correttamente sul file:', file.
    ELSE.
      WRITE : / 'Download target group in errore sul file:', file.
    ENDIF.
    CLOSE DATASET file.

  ELSE.
    WRITE : / 'Impossibile aprire il path target group: ', file.
  ENDIF.
ELSE.
  OPEN DATASET file FOR OUTPUT IN TEXT MODE   ENCODING DEFAULT.
  CLOSE DATASET file.
  WRITE : / 'Non ci sono record da elaborare'.
ENDIF.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
