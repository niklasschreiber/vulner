*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_LEAD_TOP
*&---------------------------------------------------------------------*

TABLES crmd_orderadm_h.

* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X',
           r_full  RADIOBUTTON GROUP gr1,

           p_date_f TYPE crmd_orderadm_h-created_at,

           p_fout TYPE filename-fileintern
             DEFAULT 'ZCRMOUT001_EDWHAE_LEAD' OBLIGATORY,
           p_flog TYPE filename-fileintern
             DEFAULT 'ZCRMLOG001_EDWHAE_LEAD' OBLIGATORY,

           p_psize TYPE i DEFAULT 150 OBLIGATORY,
           p_ind(9) TYPE c.

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

TYPES t_lead TYPE RANGE OF crmd_orderadm_h-process_type.
TYPES t_tdid TYPE RANGE OF bapibus20001_text_dis-tdid.  "ADD MA 22.04.2015

TYPES: BEGIN OF t_crmd_orderadm_h,
         guid      TYPE crmd_orderadm_h-guid,
         object_id TYPE crmd_orderadm_h-object_id,
       END OF t_crmd_orderadm_h.

TYPES: BEGIN OF t_guid16,
        ref_guid TYPE bapibus20001_doc_flow_dis-ref_guid,
        guid     TYPE cgpl_project-guid,
      END OF t_guid16.

TYPES: BEGIN OF t_cgpl_project,
        guid         TYPE cgpl_project-guid,
        external_id  TYPE cgpl_project-external_id,
      END OF t_cgpl_project.

TYPES: BEGIN OF t_anprod,
        product_guid TYPE zca_anprodotto-product_guid,
        zz0010       TYPE zca_anprodotto-zz0010,
      END OF t_anprod.

TYPES: BEGIN OF t_item,
        guid   TYPE bapibus20001_item_dis-guid,
        header TYPE bapibus20001_item_dis-header,
        guid16 TYPE zca_anprodotto-product_guid,
      END OF t_item.


DATA: BEGIN OF wa_file_header,
        header_lead(2)        TYPE c,
        cod_lead_crm(10)      TYPE c,
        descrizione(40)       TYPE c,
        dip_responsabile(10)  TYPE c,
        divisione(4)          TYPE c,
        cod_cliente_crm(10)   TYPE c,
        data_inizio_lead(8)   TYPE c,
        data_chiusura_lead(8) TYPE c,
        data_pianif_lead(8)   TYPE c,
        stato(5)              TYPE c,
        note(255)             TYPE c,
        motivazione(14)       TYPE c,
        campagna(24)          TYPE c,
        data_creazione(14)    TYPE c,
        data_ult_mod(14)      TYPE c,
      END OF wa_file_header.

DATA: BEGIN OF wa_file_item,
        pos_prod(2)           TYPE c,
        cod_lead_crm(10)      TYPE c,
        prodotto_bic(40)      TYPE c,
        quantita(20)          TYPE c,
      END OF wa_file_item.

* VARIABILI
DATA: va_ts(8)        TYPE c,
      va_fileout(255) TYPE c,
      va_filelog(255) TYPE c,
      va_filetmp(255) TYPE c,
      va_acapo_0a     TYPE string,
      va_acapo_0d     TYPE string,
      va_date_t       TYPE crmd_orderadm_h-created_at,
      va_edw_leadcl   TYPE zca_param-z_val_par,
      va_edw_leaddip  TYPE zca_param-z_val_par,
      va_lead_note    TYPE zca_param-z_val_par,
      va_edw_leadvis  TYPE zca_param-z_val_par,
      va_edw_leadsta  TYPE zca_param-z_val_par,
      va_edw_leadend  TYPE zca_param-z_val_par,
      va_lead_objtype TYPE zca_param-z_val_par,
      va_camp_objtype TYPE zca_param-z_val_par,
* RANGE
      r_lead          TYPE t_lead,
      gr_tdid         type t_tdid,  "ADD MA 22.04.2015
* TABELLE
      i_crmd_orderadm_h TYPE STANDARD TABLE OF t_crmd_orderadm_h,
*     Dichiarazione tabelle per BAPI
      i_appointment     TYPE STANDARD TABLE OF bapibus20001_appointment_dis,
      i_guid            TYPE STANDARD TABLE OF bapibus20001_guid_dis,
      i_guid16          TYPE STANDARD TABLE OF t_guid16,
      i_cgpl_project    TYPE STANDARD TABLE OF t_cgpl_project,
      i_anprod          TYPE STANDARD TABLE OF t_anprod,
      i_header          TYPE STANDARD TABLE OF bapibus20001_header_dis,
      i_partner         TYPE STANDARD TABLE OF bapibus20001_partner_dis,
      i_service_os      TYPE STANDARD TABLE OF bapibus20001_service_os_dis,
      i_status          TYPE STANDARD TABLE OF bapibus20001_status_dis,
      i_text            TYPE STANDARD TABLE OF bapibus20001_text_dis,
      i_doc_flow        TYPE STANDARD TABLE OF bapibus20001_doc_flow_dis,
      i_item            TYPE STANDARD TABLE OF bapibus20001_item_dis,
      i_item2           TYPE STANDARD TABLE OF t_item,
      i_schedule        TYPE STANDARD TABLE OF bapibus20001_schedlin_dis,
      i_file_item       LIKE STANDARD TABLE OF wa_file_item.

* FIELD-SYMBOLS
FIELD-SYMBOLS: <fs_appointment>     LIKE LINE OF i_appointment,
               <fs_crmd_orderadm_h> LIKE LINE OF i_crmd_orderadm_h,
               <fs_guid>            LIKE LINE OF i_guid,
               <fs_header>          LIKE LINE OF i_header,
               <fs_partner>         LIKE LINE OF i_partner,
               <fs_service_os>      LIKE LINE OF i_service_os,
               <fs_status>          LIKE LINE OF i_status,
               <fs_doc_flow>        LIKE LINE OF i_doc_flow,
               <fs_item>            LIKE LINE OF i_item,
               <fs_item2>           LIKE LINE OF i_item2,
               <fs_anprod>          LIKE LINE OF i_anprod,
               <fs_schedule>        LIKE LINE OF i_schedule,
               <fs_text>            LIKE LINE OF i_text,
               <fs_cgpl_project>    LIKE LINE OF i_cgpl_project,
               <fs_guid16>          LIKE LINE OF i_guid16.

CONSTANTS:
           ca_a(1)        TYPE c                    VALUE 'A',
           ca_e(1)        TYPE c                    VALUE 'E',
           ca_i(1)        TYPE c                    VALUE 'I',
           ca_x(1)        TYPE c                    VALUE 'X',
           ca_sep(1)      TYPE c                    VALUE '|',
           ca_eq(2)       TYPE c                    VALUE 'EQ',
           ca_jobname     TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_LEAD',
           ca_f           TYPE tbtco-status         VALUE 'F',
           ca_r           TYPE tbtco-status         VALUE 'R',

           ca_appl         TYPE zca_param-z_appl     VALUE 'ZCAE_EDWHAE_LEAD',
           ca_edw_leadcl   TYPE zca_param-z_nome_par VALUE 'EDW_LEADCL',
           ca_edw_leaddip  TYPE zca_param-z_nome_par VALUE 'EDW_LEADDIP',
*           ca_lead_note    TYPE zca_param-z_nome_par VALUE 'LEAD_NOTE',  "DEL MA 22.04.2015
           ca_edw_leadvis  TYPE zca_param-z_nome_par VALUE 'EDW_LEADVIS',
           ca_edw_leadsta  TYPE zca_param-z_nome_par VALUE 'EDW_LEADSTA',
           ca_edw_leadend  TYPE zca_param-z_nome_par VALUE 'EDW_LEADEND',
           ca_lead_objtype TYPE zca_param-z_nome_par VALUE 'LEAD_OBJTYPE',
           ca_camp_objtype TYPE zca_param-z_nome_par VALUE 'CAMP_OBJTYPE',
           ca_lead         TYPE zca_param-z_group    VALUE 'LEAD',
           ca_note         TYPE zca_param-z_group    VALUE 'NOTE',  "ADD MA 22.04.2015
           ca_file_temp    TYPE filename-fileintern  VALUE 'ZCRMTEMP001_EDWHAE_LEAD'.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
