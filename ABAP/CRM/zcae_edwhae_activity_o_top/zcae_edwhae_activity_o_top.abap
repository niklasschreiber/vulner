*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_ACTIVITY_TOP
*&---------------------------------------------------------------------*

TABLES: crmd_orderadm_h, but000.

* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X',
           r_full  RADIOBUTTON GROUP gr1,

           p_date_f TYPE crmd_orderadm_h-created_at,

           p_fout TYPE filename-fileintern
             DEFAULT 'ZCRMOUT001_EDWHAE_ACTIVITY' OBLIGATORY,
           p_flog TYPE filename-fileintern
             DEFAULT 'ZCRMLOG001_EDWHAE_ACTIVITY' OBLIGATORY,

           p_psize TYPE i DEFAULT 150 OBLIGATORY,
           p_ind(9) TYPE c  ."OBLIGATORY. " MOD SC 19/12/2008

SELECT-OPTIONS: s_objid FOR crmd_orderadm_h-object_id.

SELECTION-SCREEN END OF BLOCK b1.

* TIPI
TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         sdlstrttm TYPE tbtco-sdlstrttm,
         status    TYPE tbtco-status,
       END OF t_tbtco.

TYPES t_range TYPE RANGE OF zval_par.

TYPES: BEGIN OF t_crmd_orderadm_h,
         guid             TYPE crmd_orderadm_h-guid,
         process_type     TYPE crmd_orderadm_h-process_type,
         created_at       TYPE crmd_orderadm_h-created_at,
         changed_at       TYPE crmd_orderadm_h-changed_at,
         zzcustomer_h0801 TYPE crmd_customer_h-zzcustomer_h0801,
         zz_idunivoco     TYPE crmd_customer_h-zz_idunivoco,
         zz_provenienza   TYPE crmd_customer_h-zz_provenienza,  " ADD CP 23.11.2011
*         zz_sede_lav      TYPE crmd_customer_h-zz_sede_lav,     "ADD CL - 03.06.2013 - Delete CL - 13.06.2013
       END OF t_crmd_orderadm_h.

* COSTANTI
CONSTANTS: ca_a(1)        TYPE c                    VALUE 'A',
           ca_e(1)        TYPE c                    VALUE 'E',
           ca_i(1)        TYPE c                    VALUE 'I',
           ca_x(1)        TYPE c                    VALUE 'X',
           ca_sep(1)      TYPE c                    VALUE '|',
           gc_trattino    TYPE c                    VALUE '-',
           ca_eq(2)       TYPE c                    VALUE 'EQ',
           ca_jobname     TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_ACTIVITY',
           ca_f           TYPE tbtco-status         VALUE 'F',
           ca_r           TYPE tbtco-status         VALUE 'R',

           ca_edwa        TYPE zca_param-z_group    VALUE 'EDWA',
           ca_edwn        TYPE zca_param-z_group    VALUE 'EDWN',
           ca_z_appl      TYPE zca_param-z_appl     VALUE 'ZCAE_EDWHAE_ACTIVITY',

           ca_edw_type    TYPE zca_param-z_nome_par VALUE 'EDW_TYPE',
           ca_bp_dummy    TYPE zca_param-z_nome_par VALUE 'PRIMO_CONTATTO',    "-- Add CP 17.02.2011
           ca_edw_type_ac TYPE zca_param-z_nome_par VALUE 'EDW_TYPE_AC',
           ca_edw_fctcl   TYPE zca_param-z_nome_par VALUE 'EDW_FCTCL',
           ca_edw_fctdip  TYPE zca_param-z_nome_par VALUE 'EDW_FCTDIP',
           lc_user_migr1  TYPE zca_param-z_group      VALUE 'MIG1',
           ca_edw_motivo  TYPE zca_param-z_nome_par VALUE 'COD_MOTIVO',    " ADD CP 23.11.2011
           ca_edw_risult  TYPE zca_param-z_nome_par VALUE 'COD_RISULTATO', " ADD CP 23.11.2011
           ca_edw_fctup   TYPE zca_param-z_nome_par VALUE 'EDW_FCTUP', "ADD CP 15/05/2009
           ca_edw_fctref  TYPE zca_param-z_nome_par VALUE 'EDW_FCTREF'. "ADD CL 01.07.2013


* VARIABILI
DATA: va_ts(8)        TYPE c,
      va_fileout(255) TYPE c,
      va_filelog(255) TYPE c,
      va_date_t       TYPE crmd_orderadm_h-created_at,

      va_edw_type      TYPE zca_param-z_val_par,
      va_edw_type_ac   TYPE zca_param-z_val_par,
      va_edw_fctcl     TYPE zca_param-z_nome_par,
      va_edw_fctdip    TYPE zca_param-z_nome_par,
      va_edw_motivo    TYPE zca_param-z_nome_par, " ADD CP 23.11.2011
      va_edw_risult    TYPE zca_param-z_nome_par, " ADD CP 23.11.2011
      va_bp_dummy      TYPE zca_param-z_nome_par, "-- Add CP 17.02.2011
      va_edw_fctup     TYPE zca_param-z_nome_par, "ADD CP 15/05/2009
      va_edw_fctref    TYPE zca_param-z_nome_par, "ADD CL 01.07.2013
      gv_referente(10) TYPE c,    "ADD CL 01.07.2013
      gv_ruolo_ref(3)  TYPE c.    "ADD CL 01.07.2013

* RANGES
DATA: r_edwa TYPE t_range,
      gr_chusr TYPE t_range,
      r_edwn TYPE t_range.

* TABELLE
DATA: i_crmd_orderadm_h TYPE STANDARD TABLE OF t_crmd_orderadm_h,

*     Dichiarazione tabelle per BAPI
      i_activity        TYPE STANDARD TABLE OF bapibus20001_activity_dis,
      i_appointment     TYPE STANDARD TABLE OF bapibus20001_appointment_dis,
      i_guid            TYPE STANDARD TABLE OF bapibus20001_guid_dis,
      i_header          TYPE STANDARD TABLE OF bapibus20001_header_dis,
      i_partner         TYPE STANDARD TABLE OF bapibus20001_partner_dis,
      i_service_os      TYPE STANDARD TABLE OF bapibus20001_service_os_dis,
      i_status          TYPE STANDARD TABLE OF bapibus20001_status_dis,
      i_text            TYPE STANDARD TABLE OF bapibus20001_text_dis,
      i_doc_flow        TYPE STANDARD TABLE OF bapibus20001_doc_flow_dis.  " DOC_FLOW change on 25.11.2013

* FIELD-SYMBOLS
FIELD-SYMBOLS: <fs_activity>        LIKE LINE OF i_activity,
               <fs_appointment>     LIKE LINE OF i_appointment,
               <fs_crmd_orderadm_h> LIKE LINE OF i_crmd_orderadm_h,
               <fs_guid>            LIKE LINE OF i_guid,
               <fs_header>          LIKE LINE OF i_header,
               <fs_partner_cl>      LIKE LINE OF i_partner,
               <fs_partner_op>      LIKE LINE OF i_partner,
               <fs_partner_up>      LIKE LINE OF i_partner,     "ADD CP 15/05/2009
               <fs_service_os>      LIKE LINE OF i_service_os,
               <fs_service_os_mot>  LIKE LINE OF i_service_os,  " ADD CP 23.11.2011
               <fs_status>          LIKE LINE OF i_status,
               <fs_text>            LIKE LINE OF i_text,
               <fs_partner_ref>     LIKE LINE OF i_partner.   "ADD CL 01.07.2013

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
