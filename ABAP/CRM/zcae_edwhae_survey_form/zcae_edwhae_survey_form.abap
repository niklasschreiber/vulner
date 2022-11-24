*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_SURVEY_FORM
*&---------------------------------------------------------------------*
FORM f_clear_var .

*REFRESHING THE INTERNAL TABLE
  REFRESH:i_delta,
          i_crmd_survey,
          i_crmd_link,
          i_valueguid1,
          i_crmd_orderadm_h,
          i_crm_svy_db_sv,
          i_crm_svy_re_quest,
          i_crm_svy_re_answ.

*Clearing the work areas.
  CLEAR : wa_delta,
          wa_valueguid_old.

*CLEARING THE VARIABLE
  CLEAR: va_to,
         va_from,
         va_header,
         va_survey,
         va_quest,
         va_answ,
         va_file_header ,
         va_file_survey ,
         va_file_quest ,
         va_file_answ ,
         va_log_head ,
         va_log_quest,
         va_log_answ,
         va_edw_surv1,
         va_edw_surv2,
         va_header_error_log,
         va_survey_success,
         va_question_success,
         va_answer_success,
         va_log_survey,
         va_header_success.
ENDFORM.                    " clear_var

*&---------------------------------------------------------------------*
*&      Form  OPEN_FILES
*&---------------------------------------------------------------------*

FORM f_open_files .

*perform to get the header file
  PERFORM f_get_file_name USING p_head
                      CHANGING va_file_header.

*perform to get the survey file
  PERFORM f_get_file_name USING p_file
                      CHANGING va_file_survey.

*perform to get the auestion file
  PERFORM f_get_file_name USING p_quest
                      CHANGING va_file_quest.

*perform to get the answer file
  PERFORM f_get_file_name USING p_answ
                      CHANGING va_file_answ.

*perform to get the header log file
  PERFORM f_get_file_name USING p_log1
                      CHANGING  va_log_head.

**perform to get the survey log file
  PERFORM f_get_file_name USING p_log2
                      CHANGING va_log_survey.

*perform to get the question log file
  PERFORM f_get_file_name USING p_log3
                      CHANGING va_log_quest.

*perform to get the answe log file
  PERFORM f_get_file_name USING p_log4
                      CHANGING va_log_answ.

*opening the header file in output mode and displaying an error message if,not opened successfully.
  OPEN DATASET va_file_header  FOR OUTPUT IN TEXT MODE
                               ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE ca_e.
  ENDIF.


*opening the survey file in output mode and displaying an error message if,not opened successfully.
  OPEN DATASET va_file_survey FOR OUTPUT IN TEXT MODE
                              ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE ca_e.
  ENDIF.



*opening the question file in output mode and displaying an error message if,not opened successfully.
  OPEN DATASET va_file_quest  FOR OUTPUT IN TEXT MODE
                             ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE ca_e.
  ENDIF.



*opening the answer file in output mode and displaying an error message if,not opened successfully.
  OPEN DATASET va_file_answ  FOR OUTPUT IN TEXT MODE
                             ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE ca_e.
  ENDIF.

*opening the header log file  (file va_log1) in output mode and displaying an error message if,not opened successfully.
  OPEN DATASET va_log_head  FOR OUTPUT IN TEXT MODE
                               ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE ca_e.
  ENDIF.


*opening the survey log file (file va_log2) in output mode and displaying an error message if,not opened successfully.
  OPEN DATASET va_log_survey  FOR OUTPUT IN TEXT MODE
                               ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE ca_e.
  ENDIF.


*opening the question log file (file va_log3) in output mode and displaying an error message if,not opened successfully.
  OPEN DATASET va_log_quest  FOR OUTPUT IN TEXT MODE
                                 ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE ca_e.
  ENDIF.


*opening the answer log file (file va_log3) in output mode and displaying an error message if,not opened successfully.
  OPEN DATASET va_log_answ  FOR OUTPUT IN TEXT MODE
                               ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    "ERROR MESSAGE  'Impossibile aprire il file in scrittura'.
    MESSAGE text-005 TYPE ca_e.
  ENDIF.


ENDFORM.                    " OPEN_FILES
*&---------------------------------------------------------------------*
*&      Form  get_file_name
*&---------------------------------------------------------------------*

FORM f_get_file_name  USING    p_va_file TYPE filename-fileintern
                    CHANGING   p_va_filename TYPE string.
*CALLING THE FUNCTION MODULE 'FILE_GET_NAME' TO PROCESS THE FILE
  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      client           = sy-mandt
      logical_filename = p_va_file
      operating_system = sy-opsys
      parameter_1      = sy-datum
    IMPORTING
      file_name        = p_va_filename
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
*   File Logico Errato
    MESSAGE text-006 TYPE ca_e.
  ENDIF.
ENDFORM.                    " get_file_name
*&---------------------------------------------------------------------*
*&      Form  FETCH_ZCA_PARAM
*&---------------------------------------------------------------------*

FORM f_fetch_zca_param .

*perform to get the value of EDW_SURV1
  PERFORM call_bapi_read_para USING ca_edw_surv1 ca_appl
                        CHANGING va_edw_surv1.

*perform to get the value of EDW_SURV2
  PERFORM call_bapi_read_para USING ca_edw_surv2 ca_appl
                        CHANGING va_edw_surv2.

ENDFORM.                    " FETCH_ZCA_PARAM
*&---------------------------------------------------------------------*
*&      Form  CALL_BAPI_VAL
*&---------------------------------------------------------------------*

FORM call_bapi_read_para  USING    uv_name TYPE zca_param-z_nome_par
                             uv_appl TYPE zca_param-z_appl
                    CHANGING uv_val TYPE zca_param-z_val_par.

  DATA : lt_ret TYPE TABLE OF bapiret2.
  REFRESH lt_ret[].
  CLEAR : uv_val.
  CALL FUNCTION 'Z_CA_READ_PARAM'
    EXPORTING
      z_name_par = uv_name
      z_appl     = uv_appl
    IMPORTING
      z_val_par  = uv_val
    TABLES
      return     = lt_ret[].

  IF NOT lt_ret[] IS INITIAL.
    MESSAGE text-028 TYPE ca_e.
  ENDIF.

ENDFORM.                    " CALL_BAPI_VAL

*&---------------------------------------------------------------------*
*&      Form  Final_process
*&---------------------------------------------------------------------*

FORM f_final_process .
*perform to fetch the records for the header

  PERFORM f_fetch_crmd_survey_header.

*perform to fetch the record for the survey

  PERFORM f_fetch_crm_svy_db_sv_survey.


*perform to send the header,server and question file to the presentation server
  PERFORM f_send_header_data.


ENDFORM.                    " Final_process


*&---------------------------------------------------------------------*
*&      Form  fill_data
*&---------------------------------------------------------------------*
*  FILLING THE DATA INTO THE FINAL INTERNAL TABLE                      *
*----------------------------------------------------------------------*
FORM f_send_header_data .

  DATA: l_created_at TYPE string,
        l_modified_at TYPE string,
        lv_tabix     TYPE sy-tabix.

  SORT i_valueguid1      BY valueguid valueversion.
  SORT i_crmd_orderadm_h BY guid.
  SORT i_crmd_link       BY guid_set.
  SORT i_crm_svy_db_sv   BY valueguid." valueversion.

  LOOP AT i_valueguid1 ASSIGNING <fs_crm_svy_db_svs2>.

    CLEAR:
      va_header,
      va_header_success.

    READ TABLE i_crmd_survey ASSIGNING <fs_crmd_surevey>
                            WITH KEY valueguid  = <fs_crm_svy_db_svs2>-valueguid BINARY SEARCH.

    IF sy-subrc IS NOT INITIAL.
      PERFORM f_send_error_log.
      CONTINUE.
    ENDIF.
    READ TABLE i_crmd_link ASSIGNING <fs_crmd_link>
                           WITH KEY guid_set = <fs_crmd_surevey>-set_guid
                           BINARY SEARCH.
    IF sy-subrc IS NOT INITIAL.
      PERFORM f_send_error_log.
      CONTINUE.
    ENDIF.
    READ TABLE i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>
                                 WITH KEY guid =  <fs_crmd_link>-guid_hi
                                 BINARY SEARCH.
    IF sy-subrc IS NOT INITIAL.
      PERFORM f_send_error_log.
      CONTINUE.
    ENDIF.

    CLEAR lv_tabix.
    READ TABLE i_crm_svy_db_sv WITH KEY  valueguid      = <fs_crm_svy_db_svs2>-valueguid
*                                         valueversion  = <fs_crm_svy_db_svs2>-valueversion
                                         BINARY SEARCH
                                         TRANSPORTING NO FIELDS.

    IF NOT sy-subrc IS INITIAL.
      PERFORM f_send_error_log.
      CONTINUE.
    ENDIF.

    lv_tabix = sy-tabix.

    CLEAR: l_created_at, l_modified_at.
    MOVE <fs_crm_svy_db_svs2>-created_at  TO l_created_at.
    MOVE <fs_crm_svy_db_svs2>-modified_at TO l_modified_at.

*concatenate all the fields of the header into va_haeder and transfer this to the presentation server file
    CONCATENATE <fs_crmd_orderadm_h>-object_id
                <fs_crmd_orderadm_h>-process_type  " G.Mele 12/11/2008
                 <fs_crm_svy_db_svs2>-valueguid
                 <fs_crm_svy_db_svs2>-valueversion
                 <fs_crm_svy_db_svs2>-status
                 <fs_crm_svy_db_svs2>-surveyid
                 <fs_crm_svy_db_svs2>-surveyversion
                  l_created_at
                 <fs_crm_svy_db_svs2>-created_by
                  l_modified_at
                 <fs_crm_svy_db_svs2>-modified_by
    INTO va_header
    SEPARATED BY ca_pipe.

*transfering the contents to the presentation server file
    TRANSFER va_header TO va_file_header.
    CONCATENATE <fs_crmd_orderadm_h>-object_id
                 text-021
                 INTO va_header_success
                 SEPARATED BY ca_pipe.

    TRANSFER    va_header_success TO va_log_head.

    LOOP AT  i_crm_svy_db_sv ASSIGNING <fs_crm_svy_db_sv>
                                         FROM lv_tabix.

      IF    <fs_crm_svy_db_sv>-valueguid       NE <fs_crm_svy_db_svs2>-valueguid.
        EXIT.
      ENDIF.

      CLEAR:
        va_survey_success,
        va_survey.

*concatenate all the fields of the server into va_survey and transfer this to the presentation server
      CONCATENATE <fs_crm_svy_db_sv>-valueguid
                 <fs_crm_svy_db_svs2>-valueversion
                 <fs_crm_svy_db_svs2>-surveyid
                 <fs_crm_svy_db_sv>-name
                 <fs_crm_svy_db_sv>-value
                 INTO va_survey
                 SEPARATED BY ca_pipe.
      TRANSFER va_survey TO va_file_survey.
      CONCATENATE <fs_crm_svy_db_sv>-valueguid
                  text-019
                  INTO va_survey_success
                  SEPARATED BY ca_pipe.
      TRANSFER va_survey_success TO va_log_survey.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " fill_data

*&---------------------------------------------------------------------*
*&      Form  fetch_valueguid
*&---------------------------------------------------------------------*
FORM f_fetch_crmd_survey_header .

  IF i_valueguid1[] IS NOT INITIAL.
    SORT i_valueguid1 BY valueguid.
    SELECT
*           survey_guid                        "CRM Survey,
           set_guid                           "GUID of a   CRM Order Object
           valueguid                          "Survey Values GUID
           FROM  crmd_survey
           INTO  TABLE i_crmd_survey
           FOR ALL ENTRIES IN i_valueguid1
           WHERE valueguid = i_valueguid1-valueguid.

    IF i_crmd_survey[] IS NOT INITIAL.
      SORT i_crmd_survey BY set_guid.
      SELECT  guid_hi                           "GUID of a CRM Order Object
              guid_set                          "GUID of a CRM Order Object
*              objtype_hi                        "Object Type
*              objtype_set                       "Object Type
     FROM  crmd_link
     INTO TABLE i_crmd_link
     FOR ALL ENTRIES IN i_crmd_survey
     WHERE    guid_set    = i_crmd_survey-set_guid
          AND objtype_hi  = va_edw_surv1
          AND objtype_set = va_edw_surv2.
    ENDIF.

    IF i_crmd_link[] IS NOT INITIAL.
      SORT i_crmd_link BY guid_hi.
      SELECT  guid                             "GUID of a CRM Order Object
              object_id                        "Transaction Number
              process_type                     "Tipologia operazione
      FROM  crmd_orderadm_h
      INTO  TABLE i_crmd_orderadm_h
      FOR ALL ENTRIES IN i_crmd_link
      WHERE guid = i_crmd_link-guid_hi.
    ENDIF.
  ENDIF.
ENDFORM.                    " fetch_valueguid

*&---------------------------------------------------------------------*
*&      Form  fetch_CRM_SVY_DB_SV_survey
*&---------------------------------------------------------------------*

FORM f_fetch_crm_svy_db_sv_survey .
  IF i_valueguid1[] IS NOT INITIAL.
    SELECT valueguid                       "CRM Surveys: Survey Values GUID
*           valueversion                    "CRM Surveys: Survey Values Version
           name                            "CRM Surveys: Survey Value Key Attribute
           value                           "CRM Surveys: Survey Value Attribute
    FROM  crm_svy_db_sv
    INTO TABLE i_crm_svy_db_sv
    FOR ALL ENTRIES IN i_valueguid1[]
              WHERE valueguid    = i_valueguid1-valueguid
              AND   valueversion = i_valueguid1-valueversion
              AND  name NE ca_scenario.         "SCENARIO"
  ENDIF.

ENDFORM.                    " fetch_CRM_SVY_DB_SV_survey
*&---------------------------------------------------------------------*
*&      Form  fetch_crm_svy_re_quest
*&---------------------------------------------------------------------*
FORM f_fetch_crm_svy_re_quest .

  SELECT
         quest
         txtlg
         survey_id
         survey_version
         quest_id
   FROM  crm_svy_re_quest
   INTO  TABLE  i_crm_svy_re_quest
   PACKAGE SIZE p_pack.

*perform to send the question data to the presentation server and to the log file
    PERFORM f_send_question_data.

*perform to clear the variables, for the next packet size.
    PERFORM f_clear_question_data.

  ENDSELECT.


ENDFORM.                    " fetch_crm_svy_re_quest

*&---------------------------------------------------------------------*
*&      Form  fetch_crm_svy_re_answ
*&---------------------------------------------------------------------*
FORM f_fetch_crm_svy_re_answ .


  SELECT
        quest                          "Question
        txtlg                          "CRM Survey: Long Description
        survey_id                      "CRM Surveys: Survey Version
        survey_version                 "CRM Surveys: Survey Version
        quest_id                       "CRM Survey: Question ID
        answer_id                      "CRM Survey: Answer ID
        main_answer                    "CRM Survey: Answer ID
 FROM  crm_svy_re_answ
 INTO TABLE i_crm_svy_re_answ
 PACKAGE SIZE  p_pack.

*PERFORM TO SEND THE ANSWER DATA TO THE APPLICATION FILE AND THE LOG.
    PERFORM f_send_answer_data .

*PERFORM TO CLEAR THE VARIABLES FOR THE NEXT PACKAGE SELECTION.
    PERFORM f_clear_answer_data.
  ENDSELECT.
*  ENDIF.

ENDFORM.                    " fetch_crm_svy_re_answ
*&---------------------------------------------------------------------*
*&      Form  send_answer_data
*&---------------------------------------------------------------------*
FORM f_send_answer_data .
*concatenate all the fields for the answer file anr transfer the file to the presentation server

  LOOP AT i_crm_svy_re_answ ASSIGNING <fs_crm_svy_re_answ>.
    CLEAR:
       va_answ,
       va_answer_success.

    CONCATENATE <fs_crm_svy_re_answ>-quest
                <fs_crm_svy_re_answ>-txtlg
                <fs_crm_svy_re_answ>-survey_id
                <fs_crm_svy_re_answ>-survey_version
                <fs_crm_svy_re_answ>-answer_id
                <fs_crm_svy_re_answ>-quest_id
                <fs_crm_svy_re_answ>-main_answer
                INTO va_answ
                SEPARATED BY ca_pipe.

    TRANSFER va_answ TO va_file_answ.

    CONCATENATE <fs_crm_svy_re_answ>-answer_id
                text-025
                INTO va_answer_success
                SEPARATED BY ca_pipe.

    TRANSFER va_answer_success TO va_log_answ.
  ENDLOOP.
ENDFORM.                    " send_answer_data
*&---------------------------------------------------------------------*
*&      Form  SELECTION_DELTA
*&---------------------------------------------------------------------*

FORM f_selection_delta .

* Get to date for the selection crieteria for the table crm_svy_db_svs
  PERFORM f_get_to_date.

* Get from date for the selection crieteria for the table crm_svy_db_svs
  PERFORM f_get_from_date.

  SELECT valueguid                       "CRM Surveys: Survey Values GUID
         valueversion              "CRM Surveys: Survey Values Version
         status                          "CRM Surveys: Survey Values Status
         surveyid                        "CRM Surveys: Survey ID
         surveyversion                   "CRM Surveys: Survey Version
         created_at                      "CRM Surveys: Creation Date
         created_by                      "Created By
         modified_at                     "CRM Surveys: Change Date
         modified_by                     "Changed by
         FROM  crm_svy_db_svs
         INTO  TABLE i_valueguid1
         PACKAGE SIZE p_pack
         WHERE   ( created_at GE va_from1 AND created_at LE va_to1 ) OR
                ( modified_at GE va_from1 AND modified_at LE va_to1 ) .

*Delete records with version that is not maximum version at the end of internal table .
*selected due to the package size specified.
    PERFORM f_del_version_not_maximum.

*perform to populate the records(heasder,servey,question,answer) and send to the presentation server.
    PERFORM f_final_process.

*perform to claer the variables for the next packet size.
    PERFORM f_clear_variables.

  ENDSELECT.

ENDFORM.                    " SELECTION_DELTA
*&---------------------------------------------------------------------*
*&      Form  GET_TO_DATE
*&---------------------------------------------------------------------*

FORM f_get_to_date .

* SELECTION FROM TBTCO FOR SELECTION TYPE DELTA
  CLEAR wa_delta.
  SELECT sdlstrtdt                                      "Planned Start Date for Background Job
         sdlstrttm                                      "Planned start time for background Job
  FROM   tbtco
  INTO   wa_delta
  UP TO 1 ROWS
  WHERE jobname = ca_program_name                           "ZCAE_EDWHAE_SURVEY"
    AND status  = ca_status_r.                              "R".
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.

    MESSAGE e398(00) WITH text-016 text-017 text-018 space.
  ELSE.
    PERFORM trascod_data USING wa_delta-sdlstrtdt wa_delta-sdlstrttm
                         CHANGING va_to1.
  ENDIF.
*  IF sy-subrc IS INITIAL.
*    CONCATENATE wa_delta-sdlstrtdt wa_delta-sdlstrttm INTO va_to.      "To Date
*  ELSE.
*    MESSAGE e398(00) WITH text-016 text-017 text-018 space.
*    "'E' " error message: #impossibile determinare la data attuale.eseguire il programma in background" in un job chiamato zcae_edwhae_opportunita#.
*  ENDIF.
ENDFORM.                    " GET_TO_DATE
*&---------------------------------------------------------------------*
*&      Form  GET_FROM_DATE
*&---------------------------------------------------------------------*

FORM f_get_from_date .


* IF TIMESTAMP FIELDS IS INITIAL
  IF  p_tstp IS INITIAL.
    SELECT  sdlstrtdt                                "Planned Start Date for Background Job
            sdlstrttm                                "Planned start time for background Job
            FROM tbtco
            INTO TABLE i_delta
            WHERE jobname = ca_program_name           "ZCAE_EDWHAE_SURVEY'
            AND status    = ca_status_f.              "F
    IF sy-subrc IS INITIAL.

      SORT i_delta BY sdlstrtdt DESCENDING
                      sdlstrttm DESCENDING.            "To fetch MAX values of both fields
      CLEAR wa_delta.
      READ TABLE i_delta INTO wa_delta INDEX 1.


      PERFORM trascod_data USING wa_delta-sdlstrtdt wa_delta-sdlstrttm
                        CHANGING va_from1.

*      CONCATENATE wa_delta-sdlstrtdt  wa_delta-sdlstrttm INTO va_from. "From Date
    ELSE.
      MESSAGE  text-023 TYPE ca_e.
      "Impossibile determinare la data iniziale. Eseguire il programma in modalità full oppure specificare una data iniziale#;
    ENDIF.
* IF TIMESTAMP IS NOT INITIAL
  ELSE.
    MOVE p_tstp TO va_from1." From Date
  ENDIF.
*    endif.
ENDFORM.                    " GET_FROM_DATE
*&---------------------------------------------------------------------*
*&      Form  SELECTION_FULL
*&---------------------------------------------------------------------*

FORM f_selection_full .

  SELECT valueguid                       "CRM Surveys: Survey Values GUID
         valueversion                    "CRM Surveys: Survey Values Version
         status                          "CRM Surveys: Survey Values Status
         surveyid                        "CRM Surveys: Survey ID
         surveyversion                   "CRM Surveys: Survey Version
         created_at                      "CRM Surveys: Creation Date
         created_by                      "Created By
         modified_at                     "CRM Surveys: Change Date
         modified_by                     "Changed by
         FROM  crm_svy_db_svs
         INTO TABLE i_valueguid1
         PACKAGE SIZE p_pack.

*Delete records with version that is not maximum version at the end of internal table .
* selected due to the package size specified.
    PERFORM f_del_version_not_maximum.

*perform to populate the records(heasder,servey,question,answer) and send to the presentation server.
    PERFORM f_final_process.

*Perform to clear the variables for the next package size.
    PERFORM f_clear_variables.

  ENDSELECT.


ENDFORM.                    " SELECTION_FULL
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
*&      Form  send_question_data
*&---------------------------------------------------------------------*
FORM f_send_question_data .

  LOOP AT i_crm_svy_re_quest ASSIGNING <fs_crm_svy_re_quest>.
    CLEAR:
      va_quest,
      va_question_success.

*concatenate all the fields of the question into va_quest and transfer this to the presentation server file
    CONCATENATE <fs_crm_svy_re_quest>-quest
                <fs_crm_svy_re_quest>-txtlg
                <fs_crm_svy_re_quest>-survey_id
                <fs_crm_svy_re_quest>-survey_version
                <fs_crm_svy_re_quest>-quest_id
    INTO va_quest SEPARATED BY ca_pipe.
    TRANSFER va_quest TO va_file_quest.

    CONCATENATE <fs_crm_svy_re_quest>-quest
                text-020
                INTO va_question_success
                SEPARATED BY ca_pipe.

    TRANSFER va_question_success TO va_log_quest.
  ENDLOOP.
ENDFORM.                    " send_question_data

*&---------------------------------------------------------------------*
*&      Form  send_error_log
*&---------------------------------------------------------------------*
FORM f_send_error_log .
  CLEAR: va_header_error_log.
  CONCATENATE  <fs_crm_svy_db_svs2>-valueguid
                    text-015
                    INTO va_header_error_log
                    SEPARATED BY ca_pipe.

  TRANSFER va_header_error_log TO va_log_head.
ENDFORM.                    " send_error_log
*&---------------------------------------------------------------------*
*&      Form  clear_variables
*&---------------------------------------------------------------------*
FORM f_clear_variables .
  REFRESH:
          i_delta,
          i_crmd_survey,
          i_crmd_link,
          i_crmd_orderadm_h,
          i_valueguid1,
          i_crm_svy_db_sv.


*clearing the work area.
  CLEAR wa_delta.

*CLEARING THE VARIABLE
  CLEAR: va_header_success ,
          va_survey_success,
          va_header_error_log.
ENDFORM.                    " clear_variables
*&---------------------------------------------------------------------*
*&      Form  del_version_not_maximum
*&---------------------------------------------------------------------*

FORM f_del_version_not_maximum .

*if value exists in the work area append it into the internal table and then process.
  IF NOT wa_valueguid_old IS INITIAL.
    APPEND wa_valueguid_old TO i_valueguid1.
  ENDIF.

*sort the table valueguid based on valueguid and   valueversion,
  SORT i_valueguid1 BY valueguid DESCENDING valueversion DESCENDING.

*and delete the adjacent duplicates from the table so    that       maximum
*valueversion corresponding to the valueguid exists in the i_valueguid table
  DELETE ADJACENT DUPLICATES FROM i_valueguid1 COMPARING valueguid.

*readt the maximum entry of the valueguid from the table and store it in the wiorkarea.
  CLEAR wa_valueguid_old.
  READ TABLE i_valueguid1 INTO wa_valueguid_old INDEX 1.
  IF sy-subrc IS INITIAL.
*dont process the first entry of the table i_valueguid.
    DELETE i_valueguid1 INDEX 1.
  ENDIF.

ENDFORM.                    " del_version_not_maximum

*&---------------------------------------------------------------------*
*&      Form  f_close_files
*&---------------------------------------------------------------------*
FORM f_close_files .
  CLOSE DATASET va_file_header.
  CLOSE DATASET va_file_survey.
  CLOSE DATASET va_file_quest.
  CLOSE DATASET va_file_answ.
  CLOSE DATASET va_log_head.
  CLOSE DATASET va_log_survey.
  CLOSE DATASET va_log_quest.
  CLOSE DATASET va_log_answ.
ENDFORM.                    " f_close_files
*&---------------------------------------------------------------------*
*&      Form  f_clear_answer_data
*&---------------------------------------------------------------------*
FORM f_clear_answer_data .
  CLEAR : va_answer_success,
          va_answ,
          i_crm_svy_re_answ.

ENDFORM.                    " f_clear_answer_data
*&---------------------------------------------------------------------*
*&      Form  f_clear_quetion_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_clear_question_data .

*clearing the internal table
  REFRESH : i_crm_svy_re_quest.

*clearing the variables
  CLEAR : va_quest,
          va_question_success.

ENDFORM.                    " f_clear_quetion_data
*&---------------------------------------------------------------------*
*&      Form  f_elabora_last_record
*&---------------------------------------------------------------------*
*    Elaborazione ultimo record
*----------------------------------------------------------------------*
FORM f_elabora_last_record .

  CHECK NOT wa_valueguid_old IS INITIAL.

  APPEND wa_valueguid_old TO i_valueguid1.

*perform to populate the records(heasder,servey,question,answer) and send to the presentation server.
  PERFORM f_final_process.

ENDFORM.                    " f_elabora_last_record


*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
