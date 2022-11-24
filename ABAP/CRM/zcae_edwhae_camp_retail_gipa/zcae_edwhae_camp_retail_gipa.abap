*&---------------------------------------------------------------------*
*& Report  Z_CAMP_FILE_CSV
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_camp_retail_gipa.


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
      lt_project_oth  TYPE TABLE OF cgpl_project WITH HEADER LINE,
      ls_project_oth  TYPE cgpl_project,
      lt_task     TYPE TABLE OF cgpl_task,
      ls_task     TYPE cgpl_task,
      ls_chinc    TYPE crmd_mktpl_chinc,
      wa_project_guid TYPE cgpl_guid16,
      wa_task_guid TYPE cgpl_guid16.

DATA :n_lin       TYPE i,
      wa_guid16   TYPE cgpl_guid16,
      wa_guid     TYPE cgpl_guid16,
      wa_tasknull TYPE cgpl_guid16,
      string_line TYPE string,
      lt_string_line TYPE STANDARD TABLE OF string,
      subrc       TYPE sy-subrc,
      wa_string   TYPE string.

DATA: BEGIN OF lt_status OCCURS 0,
    udate TYPE crm_jcds-udate,
    utime TYPE crm_jcds-utime,
    stat TYPE crm_jcds-stat,
  END OF lt_status .

DATA: ls_status   LIKE lt_status.
DATA: l_format TYPE tztf_format VALUE ' X  '.
DATA: BEGIN OF t_record_csv OCCURS 0,
      guid              TYPE cgpl_project-guid,
      external_id       TYPE cgpl_project-external_id,
      project_guid      TYPE cgpl_project-project_guid,
      text1             TYPE cgpl_text-text1,
      object_type       TYPE cgpl_project-object_type,
      time_actuals      TYPE string,
      time_actualf      TYPE string,
      time_plans        TYPE string,
      time_planf        TYPE string,
      stat              TYPE tj02t-txt30,
      zzup_crmo         TYPE crmd_mktpl_chinc-zzup_crmo   ,
      zzup_area_pr      TYPE crmd_mktpl_chinc-zzup_area_pr,
      zzup_area_fi      TYPE crmd_mktpl_chinc-zzup_area_fi,
      zzup_pt_busi      TYPE crmd_mktpl_chinc-zzup_pt_busi,
      zzup_multica      TYPE crmd_mktpl_chinc-zzup_multica,
      zzup_sportel      TYPE crmd_mktpl_chinc-zzup_sportel,
      zzcontact_ce      TYPE crmd_mktpl_chinc-zzcontact_ce,
      zzdirect_mil      TYPE crmd_mktpl_chinc-zzdirect_mil,
      zze_mailing       TYPE crmd_mktpl_chinc-zze_mailing ,
      zzsms             TYPE crmd_mktpl_chinc-zzsms       ,
      zzleads_spor      TYPE crmd_mktpl_chinc-zzleads_spor,
      zzup_senza_c      TYPE crmd_mktpl_chinc-zzup_senza_c,
      zzgrupporesp      TYPE crmd_mktpl_bdinc-zzgrupporesp,
      padre             TYPE cgpl_extid,
      up                TYPE cgpl_extid,
      x_camp_elem       TYPE xfeld,
      numer             TYPE crmd_mktpl_bdinc-zznumerosita0002,
END OF t_record_csv.

*DATA: p_file(128) TYPE c.
*DATA: p_file_can(128) TYPE c.

DATA:   ls_bdinc TYPE crmd_mktpl_bdinc,
        tabix TYPE sy-tabix.

****** parte vecchio flusso****

DATA :va_id            TYPE zca_param-z_val_par,
      va_langu         TYPE zca_param-z_val_par,
      va_object        TYPE zca_param-z_val_par,
      va_tipo          TYPE zca_param-z_val_par,
      va_tipoel        TYPE zca_param-z_val_par,
      va_up            TYPE zca_param-z_val_par,
      va_cc            TYPE zca_param-z_val_par,
      va_z001          TYPE zca_param-z_val_par,
      va_z002          TYPE zca_param-z_val_par,
      va_cpg          TYPE zca_param-z_val_par,
      va_from1           TYPE cgpl_project-created_on,
      va_to1v          TYPE cgpl_project-created_on,
      va_fileinput       TYPE string,
      cod_cpg(24)        TYPE c,
      desc_cpg(40)       TYPE c,
      lt_tipo_cpg(4)        TYPE c,
      tipo_cpg(2)        TYPE c,
      obiettivo(3)       TYPE c,
      dtinizio(15)       TYPE c,
      dtfine(15)         TYPE c,
      note(255)          TYPE c,
      ls_file(455)       TYPE c,
      lt_file LIKE TABLE OF ls_file,
      guid_cpg           TYPE bapi_marketingelement_guid-mktelement_guid,
      ltva_id            TYPE thead-tdid,
      ltva_langu         TYPE thead-tdspras,
      ltva_object        TYPE thead-tdobject,
      guidnote           TYPE thead-tdname.

DATA: lt_note TYPE STANDARD TABLE OF thead WITH HEADER LINE.
DATA: lt_line TYPE STANDARD TABLE OF tline WITH HEADER LINE.

CONSTANTS :
c_program_name1     TYPE zca_param-z_appl VALUE 'ZCA_ESTRAI_CAMPAGNE',
ca_jobname     TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_CAMP_RETAIL_GIPA',
ca_r           TYPE tbtco-status         VALUE 'R',
ca_id               TYPE zca_param-z_appl VALUE 'NOTE',
ca_langu            TYPE zca_param-z_appl VALUE 'IT',
ca_object           TYPE zca_param-z_appl VALUE 'CGPL_TEXT',
p_appl              TYPE zca_param-z_appl VALUE 'ESTRAICMP',
ca_tipo             TYPE zca_param-z_appl VALUE 'TIPO_RECORD',
ca_tipoel           TYPE zca_param-z_appl VALUE 'TIPO_EL',
ca_up               TYPE zca_param-z_appl VALUE 'UP',
ca_cpg              TYPE zca_param-z_appl VALUE 'CPG',
ca_cc               TYPE zca_param-z_appl VALUE 'CC',
ca_z001             TYPE zca_param-z_appl VALUE 'Z001',
ca_z002             TYPE zca_param-z_appl VALUE 'Z002',
c_e(1)                 TYPE c VALUE 'E',
c_f(1)                 TYPE c VALUE 'F',
c_r(1)                 TYPE c VALUE 'R'.

CONSTANTS: ca_a(1)        TYPE c                    VALUE 'A',
           ca_e(1)        TYPE c                    VALUE 'E',
           ca_sep(1)      TYPE c                    VALUE '|'.

****** parte vecchio flusso****

TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         status    TYPE tbtco-status,
       END OF t_tbtco.

DATA: lw_tbtco_t TYPE t_tbtco ,
      sy_date TYPE d.

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
      lv_shift  TYPE i.

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
    full_path = lv_path
  IMPORTING
    file_name = lv_filename.
SEARCH lv_path FOR lv_filename.

lv_shift = sy-fdpos.

lv_file = lv_path(lv_shift).


CONCATENATE lv_file 'ZCRMOUT001_CAMPAIGNBP_' sy_date  '.csv' INTO file.


*CONCATENATE '/IFR/CRM/outbound/inv/ASC/' 'ZCRMOUT001_CAMPAIGNBP_' sy-datum '.csv' INTO p_file.
*CONCATENATE '/tmp/file_can' sy-datum '.csv' INTO p_file_can.

*CAMPAGNA
IF ( r_delta EQ 'X' ).

  IF p_date_f IS INITIAL.

    p_date_f = sy_date.

  ENDIF.

  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_project
    FROM cgpl_project
    WHERE object_type = 'CPG'
     AND ( ( ( changed_on   GE p_date_f ) AND ( changed_on  LE sy_date ) ) OR ( ( created_on   GE p_date_f ) AND ( created_on  LE sy_date ) ) ).


ELSE.

  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_project
   FROM cgpl_project
   WHERE object_type = 'CPG'.


ENDIF.


LOOP AT lt_project INTO ls_project.

*Filtro gruppo responsabili BP e MP
  tabix = sy-tabix.
  CLEAR ls_bdinc.
  SELECT SINGLE * FROM crmd_mktpl_bdinc INTO ls_bdinc
    WHERE project_guid = ls_project-guid
      AND task_guid = wa_tasknull
      AND ( zzgrupporesp = 'BP' OR zzgrupporesp = 'MP' ).
  IF sy-subrc <> 0.
    DELETE lt_project INDEX tabix.
    APPEND ls_project TO lt_project_oth.
    CONTINUE.
  ENDIF.


  CLEAR: t_record_csv,n_lin,ls_status,wa_guid16,ls_chinc,wa_project_guid,wa_guid.
  FREE lt_status.
  MOVE-CORRESPONDING ls_project TO t_record_csv.

  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
    EXPORTING
      input          = ls_project-external_id
*     IM_APPLICATION =
    IMPORTING
      output         = wa_project_guid.

  CLEAR wa_task_guid.
  SELECT SINGLE * INTO ls_chinc FROM crmd_mktpl_chinc WHERE project_guid = wa_project_guid
                                                        AND task_guid    = wa_task_guid.

  DATA: lv_string TYPE tztf_io_field.
  IF ls_project-actualstart IS NOT INITIAL.
    CLEAR wa_string.
    CLEAR lv_string.
    CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
      EXPORTING
        is_format   = l_format
        if_time     = ls_project-actualstart
        if_timezone = sy-zonlo
      IMPORTING
        ef_io_field = lv_string.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_string
      IMPORTING
        date_internal = wa_string.

*    MOVE ls_project-actualstart      TO wa_string.
    CONCATENATE wa_string(8) '' INTO t_record_csv-time_actuals.
  ENDIF.

  IF ls_project-actualfinish IS NOT INITIAL.
    CLEAR wa_string.
    CLEAR lv_string.
    CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
      EXPORTING
        is_format   = l_format
        if_time     = ls_project-actualfinish
        if_timezone = sy-zonlo
      IMPORTING
        ef_io_field = lv_string.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_string
      IMPORTING
        date_internal = wa_string.

*    MOVE ls_project-actualfinish     TO wa_string.
    CONCATENATE wa_string(8) '' INTO t_record_csv-time_actualf.
  ENDIF.

  IF ls_project-planstart IS NOT INITIAL.
    CLEAR wa_string.
    CLEAR lv_string.
    CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
      EXPORTING
        is_format   = l_format
        if_time     = ls_project-planstart
        if_timezone = sy-zonlo
      IMPORTING
        ef_io_field = lv_string.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_string
      IMPORTING
        date_internal = wa_string.


*    MOVE ls_project-planstart        TO wa_string.
    CONCATENATE wa_string(8) '' INTO t_record_csv-time_plans  .
  ENDIF.

  IF ls_project-planfinish IS NOT INITIAL.
    CLEAR wa_string.
    CLEAR lv_string.
    CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
      EXPORTING
        is_format   = l_format
        if_time     = ls_project-planfinish
        if_timezone = sy-zonlo
      IMPORTING
        ef_io_field = lv_string.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_string
      IMPORTING
        date_internal = wa_string.

*    MOVE ls_project-planfinish       TO wa_string.
    CONCATENATE wa_string(8) '' INTO t_record_csv-time_planf  .
  ENDIF.

  MOVE:   ls_chinc-zzup_crmo     TO t_record_csv-zzup_crmo   ,
          ls_chinc-zzup_area_pr  TO t_record_csv-zzup_area_pr,
          ls_chinc-zzup_area_fi  TO t_record_csv-zzup_area_fi,
          ls_chinc-zzup_pt_busi  TO t_record_csv-zzup_pt_busi,
          ls_chinc-zzup_multica  TO t_record_csv-zzup_multica,
          ls_chinc-zzup_sportel  TO t_record_csv-zzup_sportel,
          ls_chinc-zzcontact_ce  TO t_record_csv-zzcontact_ce,
          ls_chinc-zzdirect_mil  TO t_record_csv-zzdirect_mil,
          ls_chinc-zze_mailing   TO t_record_csv-zze_mailing ,
          ls_chinc-zzsms         TO t_record_csv-zzsms       ,
          ls_chinc-zzleads_spor  TO t_record_csv-zzleads_spor,
          ls_chinc-zzup_senza_c  TO t_record_csv-zzup_senza_c.



  SELECT SINGLE text1 INTO t_record_csv-text1 FROM cgpl_text WHERE guid = t_record_csv-guid
                                                                AND langu = 'I'.

*->2010-07-26 MZ
  CLEAR lt_status.
  REFRESH lt_status[].
*<-2010-07-26 MZ
  SELECT * FROM  crm_jcds INTO CORRESPONDING FIELDS OF TABLE lt_status
         WHERE  objnr  = t_record_csv-guid
         AND    inact  <> 'X'.


* Inizio AG 24.11.2014


**->2010-07-26 MZ modifica per estrarre sempre l'ultimo stato
**  SORT lt_status BY udate DESCENDING.
*  SORT lt_status BY udate DESCENDING utime DESCENDING.
**<-2010-07-26 MZ
*  READ TABLE lt_status INDEX 1 INTO ls_status.
**->2010-07-26 MZ modifica per estrarre sempre l'ultimo stato
**  DELETE lt_status WHERE udate <> ls_status-udate.
**  SORT lt_status BY udate utime DESCENDING.
**  READ TABLE lt_status INDEX 1 INTO ls_status.
**<-2010-07-26 MZ
  SORT lt_status BY udate DESCENDING utime DESCENDING.
  IF NOT r_delta IS INITIAL.
    LOOP AT lt_status INTO ls_status
       WHERE stat EQ 'I1121' OR
             stat EQ 'I1122' OR
             stat EQ 'I1124' OR
             stat EQ 'I1008'.
      EXIT.
    ENDLOOP.
  ELSE.
    READ TABLE lt_status INTO ls_status
      INDEX 1.
  ENDIF.
* Fine   AG 24.11.2014

  IF sy-subrc = 0.
    SELECT SINGLE txt30 FROM tj02t INTO t_record_csv-stat WHERE istat = ls_status-stat
                                                            AND spras = 'I'.
  ENDIF.

*Filtro per stato - deve essere inviata solo la campagna dallo stato approvato in poi
*no stato creato - rilasciato etc...


*->2010-07-26 MZ controllo sullo stato solo se si estrae in modo DELTA
  IF NOT r_delta IS INITIAL.
    IF ls_status-stat <> 'I1121' AND ls_status-stat <> 'I1122'
                AND ls_status-stat <> 'I1124' AND ls_status-stat <> 'I1008'.
      CONTINUE.
    ENDIF.
  ENDIF.
*<-2010-07-26 MZ


  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
    EXPORTING
      input  = t_record_csv-external_id
    IMPORTING
      output = wa_guid16.

  SELECT SINGLE up FROM cgpl_hierarchy INTO wa_guid WHERE guid = wa_guid16.

  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_OUTPUT'
    EXPORTING
      input  = wa_guid
    IMPORTING
      output = t_record_csv-up.


  SELECT SINGLE zznumerosita0002 zzgrupporesp  FROM crmd_mktpl_bdinc INTO (t_record_csv-numer , t_record_csv-zzgrupporesp) WHERE project_guid = wa_guid16
                                                                                  AND task_guid = wa_tasknull.

  APPEND t_record_csv .
ENDLOOP.

*PERFORM OLD_JOB.
PERFORM old_job_2.



*ELEMENTO CAMPAGNA

IF ( r_delta EQ 'X' ).

  IF p_date_f IS INITIAL.

    p_date_f = sy_date.

  ENDIF.

  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_task
    FROM cgpl_task
    WHERE object_type = 'CPT'
     AND ( ( ( changed_on   GE p_date_f ) AND ( changed_on  LE sy-datum ) ) OR ( ( created_on   GE p_date_f ) AND ( created_on  LE sy-datum ) ) ).

ELSE.

  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_task
    FROM cgpl_task
    WHERE object_type = 'CPT'.


ENDIF.

LOOP AT lt_task INTO ls_task.

*Filtro gruppo responsabili BP e MP
  tabix = sy-tabix.
  CLEAR ls_bdinc.
  SELECT SINGLE * FROM crmd_mktpl_bdinc INTO ls_bdinc
    WHERE task_guid = ls_task-guid
      AND project_guid  = ls_task-project_guid
      AND ( zzgrupporesp = 'BP' OR zzgrupporesp = 'MP' ).
  IF sy-subrc <> 0.
    DELETE lt_task INDEX tabix.
    CONTINUE.
  ENDIF.


  CLEAR: t_record_csv,lt_status[],n_lin,ls_status,wa_guid16,ls_chinc,wa_project_guid,wa_guid.
  FREE lt_status.
  MOVE-CORRESPONDING ls_task TO t_record_csv.

  IF ls_task-actualstart IS NOT INITIAL.
    CLEAR wa_string.
    CLEAR lv_string.
    CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
      EXPORTING
        is_format   = l_format
        if_time     = ls_task-actualstart
        if_timezone = sy-zonlo
      IMPORTING
        ef_io_field = lv_string.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_string
      IMPORTING
        date_internal = wa_string.
*    MOVE ls_task-actualstart      TO wa_string.
    CONCATENATE wa_string(8) '' INTO t_record_csv-time_actuals.
  ENDIF.

  IF ls_task-actualfinish IS NOT INITIAL.
    CLEAR wa_string.
    CLEAR lv_string.
    CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
      EXPORTING
        is_format   = l_format
        if_time     = ls_task-actualfinish
        if_timezone = sy-zonlo
      IMPORTING
        ef_io_field = lv_string.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_string
      IMPORTING
        date_internal = wa_string.
*    MOVE ls_task-actualfinish     TO wa_string.
    CONCATENATE wa_string(8) '' INTO t_record_csv-time_actualf.
  ENDIF.

  IF ls_task-planstart IS NOT INITIAL.
    CLEAR wa_string.
    CLEAR lv_string.
    CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
      EXPORTING
        is_format   = l_format
        if_time     = ls_task-planstart
        if_timezone = sy-zonlo
      IMPORTING
        ef_io_field = lv_string.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_string
      IMPORTING
        date_internal = wa_string.
*    MOVE ls_task-planstart        TO wa_string.
    CONCATENATE wa_string(8) '' INTO t_record_csv-time_plans  .
  ENDIF.

  IF ls_task-planfinish IS NOT INITIAL.
    CLEAR wa_string.
    CLEAR lv_string.
    CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
      EXPORTING
        is_format   = l_format
        if_time     = ls_task-planfinish
        if_timezone = sy-zonlo
      IMPORTING
        ef_io_field = lv_string.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_string
      IMPORTING
        date_internal = wa_string.
*    MOVE ls_task-planfinish       TO wa_string.
    CONCATENATE wa_string(8) '' INTO t_record_csv-time_planf  .
  ENDIF.

  t_record_csv-x_camp_elem = 'X'.

  SELECT SINGLE text1 INTO t_record_csv-text1 FROM cgpl_text WHERE guid = t_record_csv-guid
                                                               AND langu = 'I'.

  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
    EXPORTING
      input          = ls_task-external_id
*     IM_APPLICATION =
    IMPORTING
      output         = wa_project_guid.

  SELECT SINGLE * INTO ls_chinc FROM crmd_mktpl_chinc WHERE project_guid  = t_record_csv-project_guid
                                                        AND task_guid     = wa_project_guid.

  MOVE:   ls_chinc-zzup_crmo     TO t_record_csv-zzup_crmo   ,
          ls_chinc-zzup_area_pr  TO t_record_csv-zzup_area_pr,
          ls_chinc-zzup_area_fi  TO t_record_csv-zzup_area_fi,
          ls_chinc-zzup_pt_busi  TO t_record_csv-zzup_pt_busi,
          ls_chinc-zzup_multica  TO t_record_csv-zzup_multica,
          ls_chinc-zzup_sportel  TO t_record_csv-zzup_sportel,
          ls_chinc-zzcontact_ce  TO t_record_csv-zzcontact_ce,
          ls_chinc-zzdirect_mil  TO t_record_csv-zzdirect_mil,
          ls_chinc-zze_mailing   TO t_record_csv-zze_mailing ,
          ls_chinc-zzsms         TO t_record_csv-zzsms       ,
          ls_chinc-zzleads_spor  TO t_record_csv-zzleads_spor,
          ls_chinc-zzup_senza_c  TO t_record_csv-zzup_senza_c.

*->2010-07-26 MZ
  CLEAR lt_status.
  REFRESH lt_status[].
*<-2010-07-26 MZ
  SELECT * FROM  crm_jcds INTO CORRESPONDING FIELDS OF TABLE lt_status
         WHERE  objnr  = t_record_csv-guid
         AND    inact  <> 'X'.

  DESCRIBE TABLE lt_status LINES n_lin.
* Inizio   AG 24.11.2014
**->2010-07-26 MZ modifica per estrarre sempre l'ultimo stato
**  SORT lt_status BY udate DESCENDING.
*  SORT lt_status BY udate DESCENDING utime DESCENDING.
**<-2010-07-26 MZ
*  READ TABLE lt_status INDEX 1 INTO ls_status.
**->2010-07-26 MZ modifica per estrarre sempre l'ultimo stato
**  DELETE lt_status WHERE udate <> ls_status-udate.
**  SORT lt_status BY udate utime DESCENDING.
**  READ TABLE lt_status INDEX 1 INTO ls_status.
**<-2010-07-26 MZ
  SORT lt_status BY udate DESCENDING utime DESCENDING.
  IF NOT r_delta IS INITIAL.
    LOOP AT lt_status INTO ls_status
       WHERE stat EQ 'I1121' OR
             stat EQ 'I1122' OR
             stat EQ 'I1124' OR
             stat EQ 'I1008'.
      EXIT.
    ENDLOOP.
  ELSE.
    READ TABLE lt_status INTO ls_status
      INDEX 1.
  ENDIF.
* Fine   AG 24.11.2014

  IF sy-subrc = 0.
    SELECT SINGLE txt30 FROM tj02t INTO t_record_csv-stat WHERE istat = ls_status-stat
                                                            AND spras = 'I'.

  ENDIF.

*Filtro per stato
*->2010-07-26 MZ controllo sullo stato solo se si estrae in modo DELTA
  IF NOT r_delta IS INITIAL.
    IF ls_status-stat <> 'I1121' AND ls_status-stat <> 'I1122'
              AND ls_status-stat <> 'I1124' AND ls_status-stat <> 'I1008'.
      CONTINUE.
    ENDIF.
  ENDIF.
*<-2010-07-26 MZ

  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
    EXPORTING
      input  = t_record_csv-external_id
    IMPORTING
      output = wa_guid16.

  SELECT SINGLE up FROM cgpl_hierarchy INTO wa_guid WHERE guid = wa_guid16.

  SELECT SINGLE up FROM cgpl_hierarchy INTO wa_guid WHERE guid = wa_guid.

  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_OUTPUT'
    EXPORTING
      input  = wa_guid
    IMPORTING
      output = t_record_csv-up.

  SELECT SINGLE zznumerosita0002 zzgrupporesp FROM crmd_mktpl_bdinc INTO (t_record_csv-numer,t_record_csv-zzgrupporesp) WHERE project_guid = t_record_csv-project_guid
                                                                                 AND task_guid = t_record_csv-guid.


  SELECT SINGLE external_id FROM cgpl_project INTO t_record_csv-padre WHERE guid = ls_task-project_guid.

  APPEND t_record_csv .
ENDLOOP.

***IF t_record_csv[] IS NOT INITIAL.
***  OPEN DATASET p_file FOR OUTPUT IN TEXT MODE
***                               ENCODING DEFAULT.
***
***  IF sy-subrc EQ 0.
***
***    LOOP AT t_record_csv .
***      CLEAR: string_line.
***      CONCATENATE
****    t_record_csv-guid
***      t_record_csv-external_id
***      t_record_csv-text1
***      t_record_csv-object_type
***      t_record_csv-time_actuals
***      t_record_csv-time_actualf
***      t_record_csv-time_plans
***      t_record_csv-time_planf
***      t_record_csv-stat
***      t_record_csv-zzgrupporesp
***      t_record_csv-x_camp_elem
***      t_record_csv-padre
***      t_record_csv-up
***      t_record_csv-numer
***      INTO string_line SEPARATED BY '|'.
***
***      TRANSFER string_line TO p_file.
***      IF sy-subrc <> 0.
***        subrc = sy-subrc.
***      ENDIF.
***
***    ENDLOOP.
***
***    IF subrc EQ 0.
***      WRITE : / 'Download file campagne eseguito correttamente sul file:', p_file.
***    ELSE.
***      WRITE : / 'Download file campagne in errore sul file:', p_file.
***    ENDIF.
***    CLOSE DATASET p_file.
***
***
***  ELSE.
***    WRITE : / 'Impossibile aprire il path campagne: ', p_file.
***  ENDIF.


IF ( t_record_csv[] IS NOT INITIAL ).
*IF ( t_record_csv[] IS NOT INITIAL ) OR ( lt_file[] IS NOT INITIAL ).
  OPEN DATASET file FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.

  IF sy-subrc EQ 0.

*  IF lt_file[] IS NOT INITIAL.
*
*   LOOP AT lt_file INTO ls_file.
*     TRANSFER ls_file TO file.
*      IF sy-subrc <> 0.
*          subrc = sy-subrc.
*      ENDIF.
*   ENDLOOP.
*
*   ENDIF.



    LOOP AT t_record_csv .
      CLEAR: string_line,lt_string_line.

      IF  t_record_csv-zzup_crmo     IS INITIAL AND
          t_record_csv-zzup_area_pr  IS INITIAL AND
          t_record_csv-zzup_area_fi  IS INITIAL AND
          t_record_csv-zzup_pt_busi  IS INITIAL AND
          t_record_csv-zzup_multica  IS INITIAL AND
          t_record_csv-zzup_sportel  IS INITIAL AND
          t_record_csv-zzcontact_ce  IS INITIAL AND
          t_record_csv-zzdirect_mil  IS INITIAL AND
          t_record_csv-zze_mailing   IS INITIAL AND
          t_record_csv-zzsms         IS INITIAL AND
          t_record_csv-zzleads_spor  IS INITIAL AND
          t_record_csv-zzup_senza_c  IS INITIAL.

        CLEAR: string_line.
        CONCATENATE
      t_record_csv-external_id
      t_record_csv-text1
      'CM'
      t_record_csv-time_plans
      t_record_csv-time_planf
      t_record_csv-time_actuals
      t_record_csv-time_actualf
      t_record_csv-stat
      ''
      t_record_csv-zzgrupporesp
      t_record_csv-x_camp_elem
      t_record_csv-padre
      t_record_csv-up
      t_record_csv-numer
      INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
* in questo caso non faccio l'append perchè se entra qui non entra dalle altre parti
        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
        CONTINUE.
      ENDIF.

      IF t_record_csv-zzup_crmo IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
      t_record_csv-external_id
      t_record_csv-text1
      'CM'
      t_record_csv-time_plans
      t_record_csv-time_planf
      t_record_csv-time_actuals
      t_record_csv-time_actualf
      t_record_csv-stat
      'UPCR'
      t_record_csv-zzgrupporesp
      t_record_csv-x_camp_elem
      t_record_csv-padre
      t_record_csv-up
      t_record_csv-numer
      INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzup_area_pr IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'UPAP'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzup_area_fi IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'UPAF'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzup_pt_busi IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'UPPI'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzup_multica IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'UPMT'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzup_sportel IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'UPSP'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzcontact_ce IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'COCE'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzdirect_mil IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'DRML'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zze_mailing IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'EMAI'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzsms IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'SMSS'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzleads_spor IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'LDSP'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      IF t_record_csv-zzup_senza_c IS NOT INITIAL.
        CLEAR: string_line.
        CONCATENATE
        t_record_csv-external_id
        t_record_csv-text1
        'CM'
        t_record_csv-time_plans
        t_record_csv-time_planf
        t_record_csv-time_actuals
        t_record_csv-time_actualf
        t_record_csv-stat
        'UPSC'
        t_record_csv-zzgrupporesp
        t_record_csv-x_camp_elem
        t_record_csv-padre
        t_record_csv-up
        t_record_csv-numer
        INTO string_line SEPARATED BY '|'.
        CONDENSE string_line.
*        CONDENSE string_line NO-GAPS.
        APPEND string_line TO lt_string_line.
*        TRANSFER string_line TO file.
        IF sy-subrc <> 0.
          subrc = sy-subrc.
        ENDIF.
      ENDIF.

      CLEAR string_line.
      LOOP AT lt_string_line INTO string_line.
        TRANSFER string_line TO file.
      ENDLOOP.


    ENDLOOP.


    IF subrc EQ 0.
      WRITE : / 'Download file eseguito correttamente in :', file.
    ELSE.
      WRITE : / 'Download file in errore:'.
    ENDIF.
    CLOSE DATASET file.

  ELSE.
    WRITE : / 'Impossibile aprire il path campagne: ', file.
  ENDIF.

ELSE.
  OPEN DATASET file FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  CLOSE DATASET file.
  WRITE : / 'Non ci sono dati da elaborare'.
ENDIF.
*&---------------------------------------------------------------------*
*&      Form  OLD_JOB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM old_job .

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


  LOOP AT lt_project_oth INTO ls_project_oth.
    CLEAR guid_cpg.
    guid_cpg = ls_project_oth-guid.
    CLEAR: cod_cpg, desc_cpg, lt_tipo_cpg, obiettivo, dtinizio, dtfine, note, tipo_cpg.
    REFRESH:  lt_note, lt_line.

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
*       OBJECT                        = 5
*       REFERENCE_CHECK               = 6
*       WRONG_ACCESS_TO_ARCHIVE       = 7
*       OTHERS                        = 8

    LOOP AT lt_line.
      CONCATENATE note lt_line-tdline INTO note SEPARATED BY space.
    ENDLOOP.

    SELECT SINGLE text1 INTO desc_cpg FROM cgpl_text WHERE guid = guid_cpg AND langu = ltva_langu.

    DATA: ls_attr TYPE  crm_mktpl_attr.

*SELECT SINGLE * FROM CRM_MKTPL_ATTR INTO  tab  WHERE GUID EQ ID_CAMP.

    SELECT SINGLE * FROM crm_mktpl_attr INTO  ls_attr  WHERE guid EQ guid_cpg.

    cod_cpg = ls_project_oth-external_id.
    dtinizio = ls_project_oth-planstart.
    dtfine = ls_project_oth-planfinish.
    obiettivo = ls_project_oth-completion.
    lt_tipo_cpg =  ls_attr-camp_type.

    IF lt_tipo_cpg = va_z001.
      tipo_cpg = va_up.
    ELSE.
      IF lt_tipo_cpg = va_z002.
        tipo_cpg = va_cc.
      ENDIF.
    ENDIF.

    dtinizio = dtinizio(8).
    dtfine = dtfine(8).


    DATA: tipo_elab(1) TYPE c,
          zobiett(2)  TYPE c.

    IF r_delta IS INITIAL.
      tipo_elab = va_tipoel.
    ELSE.
      IF ls_project_oth-changed_on IS INITIAL.
        tipo_elab = va_tipoel.
      ELSE.
        tipo_elab = 'M'.
      ENDIF.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = obiettivo
      IMPORTING
        output = zobiett.

*    lt_tipo_cpg = lt_attributi-camp_type.

    CONCATENATE va_tipo tipo_elab cod_cpg desc_cpg tipo_cpg zobiett dtinizio dtfine note INTO ls_file SEPARATED BY ca_sep.
    APPEND ls_file TO lt_file.


  ENDLOOP.

ENDFORM.                    " OLD_JOB
*&---------------------------------------------------------------------*
*&      Form  read_param
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CA_ID  text
*      -->P_P_APPL  text
*      <--P_VA_ID  text
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

ENDFORM.                               " read_param
*&---------------------------------------------------------------------*
*&      Form  OLD_JOB_2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM old_job_2 .



  LOOP AT lt_project_oth.

    CLEAR: t_record_csv,n_lin,ls_status,wa_guid16,ls_chinc,wa_project_guid,wa_guid.
    FREE lt_status.
    MOVE-CORRESPONDING lt_project_oth TO t_record_csv.

    CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
      EXPORTING
        input          = lt_project_oth-external_id
*       IM_APPLICATION =
      IMPORTING
        output         = wa_project_guid.

    CLEAR wa_task_guid.
    SELECT SINGLE * INTO ls_chinc FROM crmd_mktpl_chinc WHERE project_guid = wa_project_guid
                                                          AND task_guid    = wa_task_guid.

    DATA: lv_string TYPE tztf_io_field.
    IF lt_project_oth-actualstart IS NOT INITIAL.
      CLEAR wa_string.
      CLEAR lv_string.
      CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
        EXPORTING
          is_format   = l_format
          if_time     = lt_project_oth-actualstart
          if_timezone = sy-zonlo
        IMPORTING
          ef_io_field = lv_string.
      CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
        EXPORTING
          date_external = lv_string
        IMPORTING
          date_internal = wa_string.

*    MOVE ls_project-actualstart      TO wa_string.
      CONCATENATE wa_string(8) '' INTO t_record_csv-time_actuals.
    ENDIF.

    IF lt_project_oth-actualfinish IS NOT INITIAL.
      CLEAR wa_string.
      CLEAR lv_string.
      CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
        EXPORTING
          is_format   = l_format
          if_time     = lt_project_oth-actualfinish
          if_timezone = sy-zonlo
        IMPORTING
          ef_io_field = lv_string.
      CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
        EXPORTING
          date_external = lv_string
        IMPORTING
          date_internal = wa_string.

*    MOVE ls_project-actualfinish     TO wa_string.
      CONCATENATE wa_string(8) '' INTO t_record_csv-time_actualf.
    ENDIF.

    IF lt_project_oth-planstart IS NOT INITIAL.
      CLEAR wa_string.
      CLEAR lv_string.
      CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
        EXPORTING
          is_format   = l_format
          if_time     = lt_project_oth-planstart
          if_timezone = sy-zonlo
        IMPORTING
          ef_io_field = lv_string.
      CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
        EXPORTING
          date_external = lv_string
        IMPORTING
          date_internal = wa_string.


*    MOVE ls_project-planstart        TO wa_string.
      CONCATENATE wa_string(8) '' INTO t_record_csv-time_plans  .
    ENDIF.

    IF lt_project_oth-planfinish IS NOT INITIAL.
      CLEAR wa_string.
      CLEAR lv_string.
      CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
        EXPORTING
          is_format   = l_format
          if_time     = lt_project_oth-planfinish
          if_timezone = sy-zonlo
        IMPORTING
          ef_io_field = lv_string.
      CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
        EXPORTING
          date_external = lv_string
        IMPORTING
          date_internal = wa_string.

*    MOVE ls_project-planfinish       TO wa_string.
      CONCATENATE wa_string(8) '' INTO t_record_csv-time_planf  .
    ENDIF.

    MOVE:   ls_chinc-zzup_crmo     TO t_record_csv-zzup_crmo   ,
            ls_chinc-zzup_area_pr  TO t_record_csv-zzup_area_pr,
            ls_chinc-zzup_area_fi  TO t_record_csv-zzup_area_fi,
            ls_chinc-zzup_pt_busi  TO t_record_csv-zzup_pt_busi,
            ls_chinc-zzup_multica  TO t_record_csv-zzup_multica,
            ls_chinc-zzup_sportel  TO t_record_csv-zzup_sportel,
            ls_chinc-zzcontact_ce  TO t_record_csv-zzcontact_ce,
            ls_chinc-zzdirect_mil  TO t_record_csv-zzdirect_mil,
            ls_chinc-zze_mailing   TO t_record_csv-zze_mailing ,
            ls_chinc-zzsms         TO t_record_csv-zzsms       ,
            ls_chinc-zzleads_spor  TO t_record_csv-zzleads_spor,
            ls_chinc-zzup_senza_c  TO t_record_csv-zzup_senza_c.



    SELECT SINGLE text1 INTO t_record_csv-text1 FROM cgpl_text WHERE guid = t_record_csv-guid
                                                                  AND langu = 'I'.

*->2010-07-26 MZ
    CLEAR lt_status.
    REFRESH lt_status[].
*<-2010-07-26 MZ
    SELECT * FROM  crm_jcds INTO CORRESPONDING FIELDS OF TABLE lt_status
           WHERE  objnr  = t_record_csv-guid
           AND    inact  <> 'X'.


*->2010-07-26 MZ modifica per estrarre sempre l'ultimo stato
*  SORT lt_status BY udate DESCENDING.
    SORT lt_status BY udate DESCENDING utime DESCENDING.
*<-2010-07-26 MZ
    READ TABLE lt_status INDEX 1 INTO ls_status.
*->2010-07-26 MZ modifica per estrarre sempre l'ultimo stato
*  DELETE lt_status WHERE udate <> ls_status-udate.
*  SORT lt_status BY udate utime DESCENDING.
*  READ TABLE lt_status INDEX 1 INTO ls_status.
*<-2010-07-26 MZ

    IF sy-subrc = 0.
      SELECT SINGLE txt30 FROM tj02t INTO t_record_csv-stat WHERE istat = ls_status-stat
                                                              AND spras = 'I'.
    ENDIF.

*Filtro per stato - deve essere inviata solo la campagna dallo stato approvato in poi
*no stato creato - rilasciato etc...
*  IF ls_status-stat <> 'I1121' AND ls_status-stat <> 'I1122' AND ls_status-stat <> 'I1124' AND ls_status-stat <> 'I1008'.
*    CONTINUE.
*  ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
      EXPORTING
        input  = t_record_csv-external_id
      IMPORTING
        output = wa_guid16.

    SELECT SINGLE up FROM cgpl_hierarchy INTO wa_guid WHERE guid = wa_guid16.

    CALL FUNCTION 'CONVERSION_EXIT_CGPLP_OUTPUT'
      EXPORTING
        input  = wa_guid
      IMPORTING
        output = t_record_csv-up.


    SELECT SINGLE zznumerosita0002 zzgrupporesp  FROM crmd_mktpl_bdinc INTO (t_record_csv-numer , t_record_csv-zzgrupporesp) WHERE project_guid = wa_guid16
                                                                                    AND task_guid = wa_tasknull.

    DATA: ls_attr TYPE  crm_mktpl_attr.

    SELECT SINGLE * FROM crm_mktpl_attr INTO  ls_attr  WHERE guid EQ wa_guid16.

    IF   ls_attr-camp_type EQ 'Z001' AND t_record_csv-zzup_crmo IS INITIAL.

      t_record_csv-zzup_crmo = 'X' .

    ENDIF.

    APPEND t_record_csv .


  ENDLOOP.


ENDFORM.                                                    " OLD_JOB_2


*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
