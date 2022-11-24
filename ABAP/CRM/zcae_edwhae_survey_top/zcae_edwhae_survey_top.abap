*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_SURVEY_TOP
*&---------------------------------------------------------------------*
*STRUCTURE DECLARATIONS FOR LOGFILE

*STRUCTURE DELTA
TYPES : BEGIN OF ty_delta,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         sdlstrttm TYPE tbtco-sdlstrttm,
        END OF ty_delta.


TYPES : BEGIN OF ty_valueguid,
         valueguid     TYPE crm_svy_db_sv_guid,       "CRM Surveys: Survey Values GUID
         valueversion  TYPE crm_svy_db_sv_vers,       "CRM Surveys: Survey Values Version
  END OF ty_valueguid.

*STRUCTURE DECLARED FOR THE EXTRACTION OF HEADER FILE
TYPES:  BEGIN OF ty_svy_db_svs,
        cod_op_crm    TYPE   crmt_object_id_db,     "Transaction Number
        tipo_op       TYPE   crmt_process_type_db,  "Tipologia operazione  G.Mele 12/11/2008
        valueguid     TYPE   crm_svy_db_sv_guid,    "CRM Surveys: Survey Values GUID
        valueversion  TYPE   crm_svy_db_sv_vers,    "CRM Surveys: Survey Values Version
        status        TYPE   crm_svy_db_svs_status, "CRM Surveys: Survey Values Status
        surveyid      TYPE   crm_svy_db_sid,        "CRM Surveys: Survey ID
        surveyversion TYPE   crm_svy_db_svers,      "CRM Surveys: Survey Version
        created_at    TYPE   crm_svy_db_crtstamp,   "CRM Surveys: Creation Date
        created_by    TYPE   stat_fuser,            "Created By
        modified_at   TYPE   crm_svy_db_modtstamp,  "CRM Surveys: Change Date
        modified_by   TYPE   stat_luser,            "Changed by
 END OF ty_svy_db_svs.

*STRUCTURE DECLARED FOR THE EXTRACTION OF SURVEY FILE
TYPES : BEGIN OF ty_crmd_survey,
        set_guid      TYPE  crmt_object_guid,        "GUID of a CRM Order Object
        valueguid     TYPE  crm_svy_db_sv_guid,      "CRM Surveys: Survey Values GUID
    END OF ty_crmd_survey.

*STRUCTURE DECLARED FOR THE EXTRACTION OF LINK

TYPES : BEGIN OF ty_crmd_link,
        guid_hi      TYPE  crmt_object_guid,        "GUID of a CRM Order Object
        guid_set     TYPE  crmt_object_guid,        "GUID of a CRM Order Object
     END OF ty_crmd_link.

TYPES : BEGIN OF ty_crmd_orderadm_h,
        guid         TYPE  crmt_object_guid,         "GUID of a CRM Order Object
        object_id    TYPE  crmt_object_id_db,        "CRMT_OBJECT_ID_DB
        process_type TYPE  crmt_process_type_db,     "Tipologia operazione "G.Mele 12/11/2008
     END OF ty_crmd_orderadm_h.

*STRUCTURE DECLARED FOR THE EXTRACTION OF HEADER FILE

TYPES : BEGIN OF ty_svy_db_svs1,
        valueguid     TYPE   crm_svy_db_sv_guid,    "CRM Surveys: Survey Values GUID
        valueversion  TYPE   crm_svy_db_sv_vers,    "CRM Surveys: Survey Values Version
        status        TYPE   crm_svy_db_svs_status, "CRM Surveys: Survey Values Status
        surveyid      TYPE   crm_svy_db_sid,        "CRM Surveys: Survey ID
        surveyversion TYPE   crm_svy_db_svers,      "CRM Surveys: Survey Version
        created_at    TYPE   crm_svy_db_crtstamp,   "CRM Surveys: Creation Date
        created_by    TYPE   stat_fuser,            "Created By
        modified_at   TYPE   crm_svy_db_modtstamp,  "CRM Surveys: Change Date
        modified_by   TYPE   stat_luser,            "Changed by
   END OF ty_svy_db_svs1.

**STRUCTURE DECLARED FOR THE crm_svy_db_sv

TYPES: BEGIN OF ty_crm_svy_db_sv,
       valueguid     TYPE   crm_svy_db_sv_guid,    "CRM Surveys: Survey Values GUID
*       valueversion  TYPE   crm_svy_db_sv_vers,    "Surveys CRM: versione valori survey
       name          TYPE   crm_svy_db_sv_name,    "Surveys CRM: valore survey chiave attributo
       value         TYPE   crm_svy_db_sv_value,   "CRM Surveys: Survey Value Attribute
END OF ty_crm_svy_db_sv.

***STRUCTURE DECLARED FOR CRM_SVY_RE_QUEST

TYPES : BEGIN OF ty_crm_svy_re_quest,
        quest          TYPE crm_svy_re_bw_quest,           "Question
        txtlg          TYPE crm_svy_re_txtlg,             "CRM Survey: Long Description
        survey_id      TYPE crm_svy_db_sid,            "CRM Surveys: Survey ID
        survey_version TYPE crm_svy_db_svers,     "CRM Surveys: Survey Version
        quest_id       TYPE crm_svy_re_quest_id,        "CRM Survey: Question ID
   END OF ty_crm_svy_re_quest.

*STRUCTURE DECLARED FOR crm_svy_re_answ

TYPES : BEGIN OF ty_crm_svy_re_answ,
        quest          TYPE crm_svy_re_bw_quest,          "Question
        txtlg          TYPE crm_svy_re_txtlg,            "CRM Survey: Long Description
        survey_id      TYPE crm_svy_db_sid,           "CRM Surveys: Survey ID
        survey_version TYPE crm_svy_db_svers,    "CRM Surveys: Survey Version
        quest_id       TYPE crm_svy_re_quest_id,
        answer_id      TYPE crm_svy_re_answer_id,     "CRM Survey: Answer ID
        main_answer    TYPE crm_svy_re_answer_id,   "CRM Survey: Answer ID
  END OF ty_crm_svy_re_answ.

****************************************************************************************************
*DECLARATION FOR THE INTERNAL TABLES
****************************************************************************************************

DATA :i_delta                 TYPE STANDARD TABLE OF ty_delta,
      i_valueguid1            TYPE STANDARD TABLE OF ty_svy_db_svs1,
      i_crmd_survey           TYPE STANDARD TABLE OF ty_crmd_survey,
      i_crmd_link             TYPE STANDARD TABLE OF ty_crmd_link,
      i_crmd_orderadm_h       TYPE STANDARD TABLE OF ty_crmd_orderadm_h,
      i_crm_svy_db_sv         TYPE STANDARD TABLE OF ty_crm_svy_db_sv,
      i_crm_svy_re_quest      TYPE STANDARD TABLE OF ty_crm_svy_re_quest,
      i_crm_svy_re_answ       TYPE STANDARD TABLE OF ty_crm_svy_re_answ.
*****************************************************************************************************
*DECLARATION FOR THE WORK AREA
*****************************************************************************************************

DATA: wa_delta                TYPE  ty_delta,
      wa_valueguid_old        TYPE  ty_svy_db_svs1.

*********************************************************************************************************
*DECLARATION FOR VARIABLES
*********************************************************************************************************

DATA :va_to(14)                 TYPE c,
      va_to1                    TYPE crmd_orderadm_h-created_at,
      va_from(14)               TYPE c,
      va_from1                  TYPE crmd_orderadm_h-created_at,
      va_header                 TYPE string,
      va_header_error_log       TYPE string,
      va_header_success         TYPE string,
      va_survey                 TYPE string,
      va_survey_success         TYPE string,
      va_question_success       TYPE string,
      va_answer_success         TYPE string,
      va_quest                  TYPE string,
      va_answ                   TYPE string,
      va_file_header            TYPE string,
      va_file_survey            TYPE string,
      va_file_quest             TYPE string,
      va_file_answ              TYPE string,
      va_log_survey             TYPE string,
      va_log_head               TYPE string,
      va_log_quest              TYPE string,
      va_log_answ               TYPE string,
      va_edw_surv1              TYPE zca_param-z_val_par,
      va_edw_surv2              TYPE zca_param-z_val_par.
**********************************************************************************************************
*DECLARATION FOR CONSTANTS
**********************************************************************************************************

CONSTANTS : ca_edw_surv1         TYPE zca_param-z_nome_par VALUE 'EDW_SURV1',
            ca_edw_surv2         TYPE zca_param-z_nome_par VALUE 'EDW_SURV2',
            ca_appl              TYPE zca_param-z_appl     VALUE 'ZCAE_EDWHAE_SURVEY',
            ca_program_name      TYPE zca_param-z_appl     VALUE 'ZCAE_EDWHAE_SURVEY',
            ca_file_head         TYPE filename-fileintern  VALUE 'ZCRMOUT001_EDWHAESVYHEAD',
            ca_file_quest        TYPE filename-fileintern  VALUE 'ZCRMOUT001_EDWHAESVYQUEST',
            ca_file_answ         TYPE filename-fileintern  VALUE 'ZCRMOUT001_EDWHAESVYANSW',
            ca_file_log_head     TYPE filename-fileintern  VALUE  'ZCRMLOG001_EDWHAESVYHEAD',
            ca_file_log_quest    TYPE filename-fileintern  VALUE  'ZCRMLOG001_EDWHAESVYQUEST',
            ca_file_log_answ     TYPE filename-fileintern  VALUE  'ZCRMLOG001_EDWHAESVYANSW',
            ca_status_r          TYPE c                    VALUE  'R',
            ca_e                 TYPE c                    VALUE  'E',
            ca_status_f          TYPE c                    VALUE  'F',
            ca_pipe              TYPE c                    VALUE  '|',
            ca_scenario          TYPE crm_svy_db_sv_name   VALUE  'SCENARIO',
            ca_file_survey       TYPE filename-fileintern  VALUE   'ZCRMOUT001_EDWHAE_SURVEY',
            ca_file_log_survey          TYPE filename-fileintern  VALUE   'ZCRMLOG001_EDWHAE_SURVEY'.

**************************************************************************************************************
*DECLARATION FOR THE Field Symbols
**************************************************************************************************************
FIELD-SYMBOLS:
               <fs_crm_svy_db_svs2>  TYPE ty_svy_db_svs1,
               <fs_crmd_surevey>     TYPE ty_crmd_survey,
               <fs_crmd_link>        TYPE ty_crmd_link,
               <fs_crmd_orderadm_h>  TYPE ty_crmd_orderadm_h,
               <fs_crm_svy_db_sv>    TYPE ty_crm_svy_db_sv,
               <fs_crm_svy_re_quest> TYPE ty_crm_svy_re_quest,
               <fs_crm_svy_re_answ>  TYPE ty_crm_svy_re_answ.
*************************************************************************************************************
* END OF DATA DECLARATIONS
*************************************************************************************************************

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
