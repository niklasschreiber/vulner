*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_CAMPAGNE_TOP
*&---------------------------------------------------------------------*

TABLES cgpl_project.


* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X',
           r_full  RADIOBUTTON GROUP gr1,

           p_date_f TYPE cgpl_project-created_on,

           p_fout TYPE filename-fileintern
             DEFAULT 'ZCRMOUT001_CAMPAIGNR3' OBLIGATORY,
*           p_flog TYPE filename-fileintern
*             DEFAULT 'ZCRMLOG001_EDWHAE_ACTIVITY' OBLIGATORY,

           p_ind(9) TYPE c  ."OBLIGATORY. " MOD SC 19/12/2008

SELECTION-SCREEN END OF BLOCK b1.

* TIPI
TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         status    TYPE tbtco-status,
       END OF t_tbtco.

TYPES t_range TYPE RANGE OF zval_par.

DATA: BEGIN OF t_cgpl_project occurs 0,
         guid             TYPE cgpl_project-guid,
         created_on       TYPE cgpl_project-created_on,
         changed_on       TYPE cgpl_project-changed_on,
       END OF t_cgpl_project.

* COSTANTI
CONSTANTS: ca_a(1)        TYPE c                    VALUE 'A',
           ca_e(1)        TYPE c                    VALUE 'E',
           ca_i(1)        TYPE c                    VALUE 'I',
           ca_x(1)        TYPE c                    VALUE 'X',
           ca_sep(1)      TYPE c                    VALUE '|',
           gc_trattino    TYPE c                    VALUE '-',
           ca_eq(2)       TYPE c                    VALUE 'EQ',
           ca_jobname     TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_CAMPAGNE',
           ca_f           TYPE tbtco-status         VALUE 'F',
           ca_r           TYPE tbtco-status         VALUE 'R',

           ca_edwa        TYPE zca_param-z_group    VALUE 'EDWA',
           ca_edwn        TYPE zca_param-z_group    VALUE 'EDWN',
           ca_z_appl      TYPE zca_param-z_appl     VALUE 'ZCAE_EDWHAE_ACTIVITY',

           ca_edw_type    TYPE zca_param-z_nome_par VALUE 'EDW_TYPE',
           ca_edw_type_ac TYPE zca_param-z_nome_par VALUE 'EDW_TYPE_AC',
           ca_edw_fctcl   TYPE zca_param-z_nome_par VALUE 'EDW_FCTCL',
        ca_edw_fctdip  TYPE zca_param-z_nome_par VALUE 'EDW_FCTDIP'.

*COSTANTI
CONSTANTS :
c_program_name1     TYPE zca_param-z_appl VALUE 'ZCA_ESTRAI_CAMPAGNE',
ca_id               TYPE ZCA_PARAM-Z_APPL VALUE 'NOTE',
ca_langu            TYPE ZCA_PARAM-Z_APPL VALUE 'IT',
ca_object           TYPE ZCA_PARAM-Z_APPL VALUE 'CGPL_TEXT',
p_appl              TYPE ZCA_PARAM-Z_APPL VALUE 'ESTRAICMP',
ca_tipo             TYPE ZCA_PARAM-Z_APPL VALUE 'TIPO_RECORD',
ca_tipoel           TYPE ZCA_PARAM-Z_APPL VALUE 'TIPO_EL',
ca_up               TYPE ZCA_PARAM-Z_APPL VALUE 'UP',
ca_cpg              TYPE ZCA_PARAM-Z_APPL VALUE 'CPG',
ca_cc               TYPE ZCA_PARAM-Z_APPL VALUE 'CC',
ca_Z001             TYPE ZCA_PARAM-Z_APPL VALUE 'Z001',
ca_Z002             TYPE ZCA_PARAM-Z_APPL VALUE 'Z002',
c_e(1)                 TYPE C VALUE 'E',
c_f(1)                 TYPE C VALUE 'F',
c_r(1)                 TYPE C VALUE 'R'.


*DECLARATION FOR VARIABLES
DATA :va_id            TYPE zca_param-z_val_par,
      va_langu         TYPE zca_param-z_val_par,
      va_object        TYPE zca_param-z_val_par,
      va_tipo          TYPE zca_param-z_val_par,
      va_tipoel        TYPE zca_param-z_val_par,
      va_up            TYPE zca_param-z_val_par,
      va_cc            TYPE zca_param-z_val_par,
      va_Z001          TYPE zca_param-z_val_par,
      va_Z002          TYPE zca_param-z_val_par,
      va_cpg          TYPE zca_param-z_val_par,
      va_from1           TYPE cgpl_project-created_on,
      va_to1v          TYPE cgpl_project-created_on,
      va_fileinput       TYPE string,
      cod_cpg(24)        TYPE C,
      desc_cpg(40)       TYPE C,
      lt_tipo_cpg(4)        TYPE C,
      tipo_cpg(2)        TYPE C,
      obiettivo(3)       TYPE C,
      dtinizio(15)       TYPE C,
      dtfine(15)         TYPE C,
      note(255)          TYPE C,
      lt_file(455)       TYPE C,
      guid_cpg           TYPE BAPI_MARKETINGELEMENT_GUID-MKTELEMENT_GUID,
      ltva_id            TYPE THEAD-TDID,
      ltva_langu         TYPE THEAD-TDSPRAS,
      ltva_object        TYPE THEAD-TDOBJECT,
      guidnote           TYPE THEAD-TDNAME.

DATA: lt_return  TYPE STANDARD TABLE OF bapiret2.
DATA: lt_attributi TYPE STANDARD TABLE OF CRM_MKTPL_MKTELEMENT WITH HEADER LINE.
DATA: lt_note TYPE STANDARD TABLE OF THEAD WITH HEADER LINE.
DATA: lt_line TYPE STANDARD TABLE OF TLINE WITH HEADER LINE.
* VARIABILI
DATA: va_ts(8)        TYPE c,
      va_fileout(455) TYPE c,
      va_filelog(255) TYPE c,
      va_date_t       TYPE cgpl_project-created_on,

      va_edw_type     TYPE zca_param-z_val_par,
      va_edw_type_ac  TYPE zca_param-z_val_par,
      va_edw_fctcl    TYPE zca_param-z_nome_par,
      va_edw_fctdip   TYPE zca_param-z_nome_par.

* RANGES
DATA: r_edwa TYPE t_range,
      r_edwn TYPE t_range.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
