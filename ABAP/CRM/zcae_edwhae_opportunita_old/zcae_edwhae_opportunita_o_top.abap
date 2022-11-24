*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_OPPORTUNITA_TOP
*&---------------------------------------------------------------------*
TYPES : BEGIN OF ty_guid,
        guid TYPE crmd_customer_h-guid,
        END OF ty_guid.
*STRUCTURE DECLARATIONS FOR HEADER
TYPES : BEGIN OF ty_header,
          header_opp(2)         TYPE  c,
          cod_opp_crm(10)       TYPE  c,
          description(40)       TYPE  c,
          dip_responsabile(10)  TYPE  c,
          divisione(4)          TYPE  c,
          cod_cliente_crm(10)   TYPE  c,
          data_apertura         TYPE  dats,
          data_chiusura         TYPE  dats ,
          data_mod_stato        TYPE  dats ,
          stato(5)              TYPE  c,
          prob_riuscita(3)      TYPE  n,
          perc_competenza(3)    TYPE  n,
          note(255)             TYPE  c,
          motivazione(14)       TYPE  c,
          valore_stimato(16)    TYPE  c,
          id_univoco(32)        TYPE  c,
          data_creazione(14)    TYPE c, "ADD CP 18/05/2009
          data_mod(14)          TYPE c, "ADD CP 18/05/2009
          zz_denom(41)          TYPE c,
          zz_tip_opp_biz(4)     TYPE c,
          flag_archiviazione(1) TYPE c,
          cod_app_crm(10)       TYPE c,"DOC_FLOW change on 25.11.2013
        END OF ty_header.

*STRUCTURE DECLARATIONS FOR LINEITEM
TYPES: BEGIN OF ty_lineitem,
          pos_prod(2)           TYPE c,
          cod_opp_crm(10)       TYPE c,
          prodotto_bic(40)      TYPE c,
          quantita(20)          TYPE c,
          stato_prodotto(1)     TYPE c,
          tot_previsto(20)      TYPE c,
          valore_incr(20)        TYPE c,
          numero_anni(3)       TYPE c,
       END OF ty_lineitem.


TYPES : BEGIN OF ty_val_par ,
        va_val_par(4) TYPE c,
       END OF ty_val_par.
*STRUCTURE DECLARATIONS FOR LOGFILE
TYPES: BEGIN OF ty_logfile,
          opportunita(12)       TYPE c,
          msg(255)            TYPE c,
       END OF ty_logfile.

*STRUCTURE DELTA
TYPES : BEGIN OF ty_delta,
           sdlstrtdt TYPE tbtco-sdlstrtdt,
           sdlstrttm TYPE tbtco-sdlstrttm,
        END OF ty_delta.

*STRUCTURE CRMD_CUSTOMER_H
TYPES : BEGIN OF ty_crmd_customer_h,
          guid             TYPE crmd_customer_h-guid,
          zz_prob_comp_1   TYPE crmd_customer_h-zz_prob_comp_1,
          zz_denom         TYPE crmd_customer_h-zz_denom,
          zz_idunivoco     TYPE crmd_customer_h-zz_idunivoco,
          zz_tip_opp_biz   TYPE crmd_customer_h-zz_tip_opp_biz,
  " -- Begin CP 13.05.2010
          zzcustomer_h1501 TYPE crmd_customer_h-zzcustomer_h1501,
          zz_catmot_s      TYPE crmd_customer_h-zz_catmot_s,
  " -- End CP 13.05.2010
        END OF ty_crmd_customer_h.

*STRUCTURE ZCA_ANPRODOTTO
TYPES : BEGIN OF ty_zca_anprodotto,
          product_guid    TYPE   zca_anprodotto-product_guid,
          zz0010          TYPE   zca_anprodotto-zz0010,
        END OF ty_zca_anprodotto.

*STRUCTURE CRMD_CUSTOMER_I
TYPES : BEGIN OF ty_crmd_customer_i,
          guid              TYPE crmd_customer_i-guid,
          zzcustomer_i0301  TYPE crmd_customer_i-zzcustomer_i0301,
          zzcustomer_i0302  TYPE crmd_customer_i-zzcustomer_i0302,
          zzcustomer_i0304  TYPE crmd_customer_i-zzcustomer_i0304,
        END OF ty_crmd_customer_i.

*STRUCTURE CRMD_CUSTOMER_I
TYPES : BEGIN OF ty_val,
         v_val TYPE zca_param-z_val_par,
        END OF ty_val.
TYPES:BEGIN OF ty_order_h,
        guid   TYPE crmt_object_guid,
        object_id	 TYPE crmt_object_id_db,
      END OF ty_order_h,
      BEGIN OF ty_guid_c,
        guid   TYPE crmt_object_guid,
        guid_c TYPE char32,
      END OF ty_guid_c.
* DECLARATION FOR THE INTERNAL TABLES
DATA: i_guid1               TYPE STANDARD TABLE OF bapibus20001_guid_dis,
      i_delta               TYPE STANDARD TABLE OF ty_delta,
      i_guid                TYPE STANDARD TABLE OF ty_guid,
      i_guid_item           TYPE STANDARD TABLE OF ty_guid,
      i_err_log             TYPE STANDARD TABLE OF ty_logfile,
      i_suc_log             TYPE STANDARD TABLE OF ty_logfile,
      i_lineitem_file       TYPE STANDARD TABLE OF ty_lineitem,
      i_crmd_customer_h     TYPE STANDARD TABLE OF ty_crmd_customer_h,
      i_zca_anprodotto      TYPE STANDARD TABLE OF ty_zca_anprodotto,
      i_crmd_customer_i     TYPE STANDARD TABLE OF ty_crmd_customer_i,
      i_header              TYPE STANDARD TABLE OF bapibus20001_header_dis,
      i_activity            TYPE STANDARD TABLE OF bapibus20001_activity_dis,
      i_partner             TYPE STANDARD TABLE OF bapibus20001_partner_dis ,
      i_partner_filter      TYPE STANDARD TABLE OF bapibus20001_partner_dis ,  "-- ADD CP 09.10.2013
      i_text                TYPE STANDARD TABLE OF bapibus20001_text_dis,
      i_service_os          TYPE STANDARD TABLE OF bapibus20001_service_os_dis,
      i_status              TYPE STANDARD TABLE OF bapibus20001_status_dis,
      i_item                TYPE STANDARD TABLE OF bapibus20001_item_dis,
      i_oppurtunity         TYPE STANDARD TABLE OF bapibus20001_opportunity_dis,
      i_pricing_item        TYPE STANDARD TABLE OF bapibus20001_pricing_item_dis,
      i_customer_item       TYPE STANDARD TABLE OF bapibus20001_customer_i_dis,
      i_schedul             TYPE STANDARD TABLE OF bapibus20001_schedlin_dis,
      i_cumulated_h         TYPE STANDARD TABLE OF bapibus20001_cumulated_h_dis,
      i_doc_flow            TYPE STANDARD TABLE OF bapibus20001_doc_flow_dis,
      i_return              TYPE STANDARD TABLE OF bapiret2,
      i_grp                 TYPE STANDARD TABLE OF zca_param.

*         DECLARATION FOR RANGES
DATA: r_val_par TYPE RANGE OF crmd_orderadm_h-process_type,
      wa_val_par LIKE LINE OF r_val_par.

" -- Begin CP 09.10.2013
DATA: r_partner_fct  TYPE RANGE OF crmt_partner_fct,
      wa_partner_fct LIKE LINE OF r_partner_fct.
" -- End CP 09.10.2013


*DECLARATION FOR THE WORK AREA
DATA: wa_guid1               TYPE  bapibus20001_guid_dis,
      wa_guid_doc            TYPE  bapibus20001_guid_dis-guid,
      wa_item                TYPE  bapibus20001_item_dis,
      wa_grp                 TYPE  zca_param,
      wa_guid                TYPE  ty_guid,
      wa_guid_item           TYPE  ty_guid,
      wa_err_log             TYPE ty_logfile,
      wa_lineitem_file       TYPE ty_lineitem,
      wa_suc_log             TYPE ty_logfile,
      wa_header_file         TYPE ty_header,
      wa_delta               TYPE ty_delta.

*DECLARATION FOR THE Field Symbols
FIELD-SYMBOLS: <fs_err_log>           TYPE ty_logfile,
               <fs_suc_log>           TYPE ty_logfile,
               <fs_lineitem_file>     TYPE ty_lineitem,
               <fs_crmd_customer_h>   TYPE ty_crmd_customer_h,
               <fs_zca_anprodotto>    TYPE ty_zca_anprodotto,
               <fs_crmd_customer_i>   TYPE ty_crmd_customer_i,
               <fs_header>            TYPE bapibus20001_header_dis,
               <fs_partner>           TYPE bapibus20001_partner_dis,
               <fs_text>              TYPE bapibus20001_text_dis,
               <fs_service_os>        TYPE bapibus20001_service_os_dis,
               <fs_status>            TYPE bapibus20001_status_dis,
               <fs_item>              TYPE bapibus20001_item_dis,
               <fs_oppurtunity>       TYPE bapibus20001_opportunity_dis,
               <fs_pricing_item>      TYPE bapibus20001_pricing_item_dis,
               <fs_schedul>           TYPE bapibus20001_schedlin_dis,
               <fs_cumulated_h>       TYPE bapibus20001_cumulated_h_dis,
               <fs_doc_flow>          TYPE bapibus20001_doc_flow_dis,
               <fs_del_opp>           TYPE zca_del_opp-object_id.

*DECLARATION FOR VARIABLES
DATA :va_to(14)          TYPE c,
      va_to1             TYPE crmd_orderadm_h-created_at,
      va_guid(32)        TYPE c,
      va_guid3(32)       TYPE c,
      va_cnt             TYPE i,
      va_from(16)        TYPE c,
      va_date_from       TYPE zca_del_opp-del_date,
      va_date_to         TYPE zca_del_opp-del_date,
      va_time_from       TYPE zca_del_opp-del_time,
      va_time_to         TYPE zca_del_opp-del_time,
      gt_del_opp         TYPE STANDARD TABLE OF zca_del_opp-object_id,
      va_from1           TYPE crmd_orderadm_h-created_at,
      va_filename        TYPE string,
      va_filelog         TYPE string,
      va_prdv            TYPE zca_param-z_val_par,
      va_prnv            TYPE zca_param-z_val_par,
      va_stprod          TYPE zca_param-z_val_par,
      va_note            TYPE zca_param-z_val_par,
      va_notes           TYPE string,
      va_zbp_fctdip      TYPE zca_param-z_val_par,
      va_zbp_fctcl       TYPE zca_param-z_val_par,
      " -- Begin CP 13.05.2010 17:04:19
      va_type_ops        TYPE zca_param-z_val_par,
      " -- End CP 13.05.2010 17:04:19
      va_header(1000)    TYPE c,
      va_lineitem(1000)  TYPE c,
      va_log(300)        TYPE c,
      va_tempfile        TYPE string,
      va_amount          TYPE p DECIMALS 2 ,
      va_err_flag        TYPE c.

*DECLARATION FOR CONSTANTS
CONSTANTS : c_prdv              TYPE zca_param-z_nome_par VALUE 'EDW_PRDV',
            c_prnv              TYPE zca_param-z_nome_par VALUE 'EDW_PRNV',
            c_stprod            TYPE zca_param-z_nome_par VALUE 'EDW_STPROD',
            c_note              TYPE zca_param-z_nome_par VALUE 'EDW_NOTE',
            c_zbp_fctcl         TYPE zca_param-z_nome_par VALUE 'EDW_CLPT',
            c_zbp_fctdip        TYPE zca_param-z_nome_par VALUE 'EDW_FCTDIP',
            c_program_name      TYPE zca_param-z_appl VALUE 'ZCAE_EDWHAE_ACTIVITY',
            c_program_name1     TYPE zca_param-z_appl VALUE 'ZCAE_EDWHAE_OPPORTUNITA',
            c_temp_file TYPE filename-fileintern VALUE 'ZCRMTEMP_EDWHAE_OPPORT',
            " -- Begin CP 13.05.2010
            c_appl_date         TYPE zca_param-z_appl     VALUE 'DATE',
            c_opp_soho          TYPE zca_param-z_nome_par VALUE 'Z_OPP_SOHO',
            " -- End CP 13.05.2010
            c_1                 TYPE c VALUE '1',
            c_0                 TYPE c VALUE '0',
            c_r                 TYPE c VALUE 'R',
            c_i                 TYPE c VALUE 'I',
            c_eq(2)             TYPE c VALUE 'EQ',
            c_x                 TYPE c VALUE 'X',
            c_e                 TYPE c VALUE 'E',
            c_f                 TYPE c VALUE 'F',
            c_ho(2)             TYPE c VALUE 'HO',
            c_pp(2)             TYPE c VALUE 'PP',
            c_pipe              TYPE c VALUE '|',
            ca_sep(1)           TYPE c VALUE '|',
            gc_trattino         TYPE c VALUE '-',
            c_zo01              TYPE zca_param-z_val_par VALUE 'ZO01', "#EC NEEDED
            c_zo02              TYPE zca_param-z_val_par VALUE 'ZO02', "#EC NEEDED
            c_zo03              TYPE zca_param-z_val_par VALUE 'ZO03', "#EC NEEDED
            c_zo04              TYPE zca_param-z_val_par VALUE 'ZO04', "#EC NEEDED
            c_it                TYPE c VALUE 'I',
            c_edwo              TYPE zca_param-z_group VALUE 'EDWO'.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
