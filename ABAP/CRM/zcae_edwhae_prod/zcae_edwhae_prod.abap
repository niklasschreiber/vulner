*&---------------------------------------------------------------------*
*& Report  Z_PROD_FILE_CSV
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_prod.

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

DATA: lt_project  TYPE TABLE OF cgpl_project,
      ls_project  TYPE cgpl_project,
      ls_project2 TYPE cgpl_project,
      lt_prod     TYPE TABLE OF crmd_mktpl_prod,
      ls_prod     TYPE crmd_mktpl_prod.

DATA: BEGIN OF t_record_csv OCCURS 0,
      external_id       TYPE cgpl_project-external_id,
      short_text        TYPE comm_prshtext-short_text,
END OF t_record_csv.

DATA: BEGIN OF st_campagne OCCURS 0,
        guid             TYPE cgpl_project-guid,
        external_id      TYPE cgpl_project-external_id,
        object_type      TYPE cgpl_project-object_type,
        stat             TYPE crm_jest-stat,
END OF st_campagne.

DATA: ls_campagne LIKE LINE OF st_campagne.

DATA: p_file(128) TYPE c,
      string_line TYPE string,
      subrc       TYPE sy-subrc,
      wa_id       TYPE cgpl_guid16.

DATA:   ls_bdinc TYPE crmd_mktpl_bdinc,
        tabix TYPE sy-tabix,
        wa_tasknull TYPE cgpl_guid16.

CONSTANTS: ca_jobname     TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_CAMP_RETAIL_GIPA',
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


CONCATENATE lv_file 'ZCRMOUT001_CAMPAIGNPD_' sy-datum '.csv' INTO file.

IF ( r_delta EQ 'X' ).

    IF p_date_f IS INITIAL.

        p_date_f = SY-DATUM.

    ENDIF.

    SELECT z2~guid z2~external_id z2~object_type zs~stat INTO CORRESPONDING FIELDS OF TABLE st_campagne
    FROM crmd_mktpl_bdinc   AS z1
    INNER JOIN cgpl_project AS z2 ON z2~guid = z1~project_guid
    INNER JOIN crm_jest     AS zs ON zs~objnr = z2~guid
    WHERE ( z1~zzgrupporesp = 'BP' OR z1~zzgrupporesp = 'MP' )
      AND z1~task_guid = '' " se il task guid è iniziale
      AND z2~object_type = 'CPG'
      AND ( zs~stat EQ 'I1122' AND zs~inact EQ '' )
      AND ( ( ( changed_on   GE p_date_f ) AND ( changed_on  LE SY-DATUM ) ) OR ( ( created_on   GE p_date_f ) AND ( created_on  LE SY-DATUM ) ) ).

ELSE.

  SELECT z2~guid z2~external_id z2~object_type zs~stat INTO CORRESPONDING FIELDS OF TABLE st_campagne
    FROM crmd_mktpl_bdinc   AS z1
    INNER JOIN cgpl_project AS z2 ON z2~guid = z1~project_guid
    INNER JOIN crm_jest     AS zs ON zs~objnr = z2~guid
    WHERE ( z1~zzgrupporesp = 'BP' OR z1~zzgrupporesp = 'MP' )
      AND z1~task_guid = '' " se il task guid è iniziale
      AND z2~object_type = 'CPG'
      AND ( zs~stat EQ 'I1122' AND zs~inact EQ '' ).

ENDIF.




LOOP AT st_campagne INTO ls_campagne.

  MOVE-CORRESPONDING ls_campagne TO t_record_csv.

  CLEAR wa_id.
  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
    EXPORTING
      input                = t_record_csv-external_id
*     IM_APPLICATION       =
   IMPORTING
     output               = wa_id
            .

  SELECT * INTO TABLE lt_prod FROM crmd_mktpl_prod WHERE project_guid = wa_id AND task_guid EQ ' ' .

  LOOP AT lt_prod INTO ls_prod.

      SELECT SINGLE short_text INTO t_record_csv-short_text FROM comm_prshtext  WHERE product_guid = ls_prod-product_guid.
      APPEND t_record_csv.

  ENDLOOP.

ENDLOOP.

REFRESH st_campagne.


IF ( r_delta EQ 'X' ).

    IF p_date_f IS INITIAL.

        p_date_f = SY-DATUM.

    ENDIF.

    SELECT z2~guid z2~external_id z2~object_type zs~stat
      APPENDING CORRESPONDING FIELDS OF TABLE
      st_campagne
      FROM crmd_mktpl_bdinc   AS z1
      INNER JOIN cgpl_task    AS z2 ON z2~guid = z1~task_guid AND z2~project_guid = z1~project_guid
      INNER JOIN crm_jest     AS zs ON zs~objnr = z2~guid
      WHERE ( z1~zzgrupporesp = 'BP' OR z1~zzgrupporesp = 'MP' )
        AND z1~task_guid <> '' "se il task guid è valorizzato
        AND z2~object_type = 'CPT'
        AND ( zs~stat EQ 'I1122' AND zs~inact EQ '' )
        AND ( ( ( z2~changed_on   GE p_date_f ) AND ( z2~changed_on  LE SY-DATUM ) ) OR ( ( z2~created_on   GE p_date_f ) AND ( z2~created_on  LE SY-DATUM ) ) ).

ELSE.

  SELECT z2~guid z2~external_id z2~object_type zs~stat
    APPENDING CORRESPONDING FIELDS OF TABLE
    st_campagne
    FROM crmd_mktpl_bdinc   AS z1
    INNER JOIN cgpl_task    AS z2 ON z2~guid = z1~task_guid AND z2~project_guid = z1~project_guid
    INNER JOIN crm_jest     AS zs ON zs~objnr = z2~guid
    WHERE ( z1~zzgrupporesp = 'BP' OR z1~zzgrupporesp = 'MP' )
      AND z1~task_guid <> '' "se il task guid è valorizzato
      AND z2~object_type = 'CPT'
      AND ( zs~stat EQ 'I1122' AND zs~inact EQ '' ).

ENDIF.



LOOP AT st_campagne INTO ls_campagne.

  MOVE-CORRESPONDING ls_campagne TO t_record_csv.

  CLEAR wa_id.
  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
    EXPORTING
      input                = t_record_csv-external_id
*     IM_APPLICATION       =
   IMPORTING
     output               = wa_id
            .

  SELECT * INTO TABLE lt_prod FROM crmd_mktpl_prod WHERE task_guid = wa_id.

  LOOP AT lt_prod INTO ls_prod.

      SELECT SINGLE short_text INTO t_record_csv-short_text FROM comm_prshtext  WHERE product_guid = ls_prod-product_guid..
    APPEND t_record_csv.

  ENDLOOP.

ENDLOOP.


*CAMPAGNA
*SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_project
*  FROM cgpl_project
*  WHERE  object_type = 'CPG'
*    AND ( changed_on = sy-datum
*     OR created_on = sy-datum ).


*LOOP AT lt_project INTO ls_project.
*
**Filtro gruppo responsabili BP e MP
*      tabix = sy-tabix.
*      CLEAR ls_bdinc.
*      SELECT SINGLE * FROM crmd_mktpl_bdinc INTO ls_bdinc
*        WHERE project_guid = ls_project-guid
*          AND task_guid = wa_tasknull
*          AND ( zzgrupporesp = 'BP' OR zzgrupporesp = 'MP' ).
*      IF sy-subrc <> 0.
*        DELETE lt_project INDEX tabix.
*        CONTINUE.
*      ENDIF.
*
*
*  MOVE-CORRESPONDING ls_project TO t_record_csv.
*
*  CLEAR wa_id.
*  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
*    EXPORTING
*      input                = t_record_csv-external_id
**     IM_APPLICATION       =
*   IMPORTING
*     output               = wa_id
*            .
*
*  SELECT * INTO TABLE lt_prod FROM crmd_mktpl_prod WHERE project_guid = wa_id.
*
*  LOOP AT lt_prod INTO ls_prod.
*
*    t_record_csv-product_guid = ls_prod-product_guid.
*
*    SELECT SINGLE short_text INTO t_record_csv-short_text FROM comm_prshtext  WHERE product_guid = t_record_csv-product_guid.
*    APPEND t_record_csv.
*
*  ENDLOOP.
*ENDLOOP.

IF t_record_csv[] IS NOT INITIAL.

  OPEN DATASET file FOR OUTPUT IN TEXT MODE
                               ENCODING DEFAULT.

  IF sy-subrc EQ 0.

    LOOP AT t_record_csv.
      CLEAR: string_line.
      CONCATENATE
      t_record_csv-external_id
      t_record_csv-short_text

      INTO string_line SEPARATED BY '|'.

      TRANSFER string_line TO file.
      IF sy-subrc <> 0.
        subrc = sy-subrc.
      ENDIF.

    ENDLOOP.

    IF subrc EQ 0.
      WRITE : / 'Download prodotti eseguito correttamente sul file:', file.
    ELSE.
      WRITE : / 'Download prodotti in errore sul file:', file.
    ENDIF.
    CLOSE DATASET file.

  ELSE.
    WRITE : / 'Impossibile aprire il path prodotti: ', file.
  ENDIF.

ELSE.
  OPEN DATASET file FOR OUTPUT IN TEXT MODE  ENCODING DEFAULT.
  CLOSE DATASET file.
  WRITE : / 'Non ci sono dati da elaborare'.
ENDIF.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
