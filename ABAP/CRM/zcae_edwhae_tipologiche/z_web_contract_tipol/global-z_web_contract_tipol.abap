FUNCTION-POOL zcc_ret_gest_cont_01.         "MESSAGE-ID ..

CONSTANTS:  gc_e          TYPE bapiret2-type         VALUE 'E',
            gc_i          TYPE c                     VALUE 'I',
            gc_1          TYPE c                     VALUE '1',
            gc_0          TYPE c                     VALUE '2',
            gc_eq(2)      TYPE c                     VALUE 'EQ',
            gc_x          TYPE c                     VALUE 'X',
            gc_u          TYPE c                     VALUE 'U',
            gc_w          TYPE c                     VALUE 'W',
*            gc_r          TYPE c                     VALUE 'R',
            gc_a          TYPE c                     VALUE 'A',
            gc_p          TYPE c                     VALUE 'P',
            gc_d          TYPE c                     VALUE 'D',
            gc_tsks       TYPE zgroup_ext            VALUE 'TSKS',
            gc_zca_an     TYPE symsgv                VALUE 'ZCA_ANPRODOTTO',
            gc_zcar2_evol TYPE bapiret2-id           VALUE 'ZCAR2_EVOL',
            gc_comm_p     TYPE symsgv                VALUE 'COMM_PRODUCT',
            gc_485        TYPE bapiret2-number       VALUE '485'.


CONSTANTS:  gc_cf       TYPE ze_nome_field VALUE 'CF',
            gc_cog      TYPE ze_nome_field VALUE 'COG',
            gc_datnas   TYPE ze_nome_field VALUE 'DATNAS',
            gc_decap    TYPE ze_nome_field VALUE 'DECAP',
            gc_delciv   TYPE ze_nome_field VALUE 'DELCIV',
            gc_deind    TYPE ze_nome_field VALUE 'DEIND',
            gc_deloc    TYPE ze_nome_field VALUE 'DELOC',
            gc_deprov   TYPE ze_nome_field VALUE 'DEPROV',
            gc_dest     TYPE ze_nome_field VALUE 'DEST',
            gc_dcap     TYPE ze_nome_field VALUE 'DCAP',
            gc_domciv   TYPE ze_nome_field VALUE 'DOMCIV',
            gc_dind     TYPE ze_nome_field VALUE 'DIND',
            gc_dloc     TYPE ze_nome_field VALUE 'DLOC',
            gc_dprov    TYPE ze_nome_field VALUE 'DPROV',
            gc_dst      TYPE ze_nome_field VALUE 'DST',
            gc_frz      TYPE ze_nome_field VALUE 'FRZ',
            gc_ind1     TYPE ze_nome_field VALUE 'IND1',
            gc_ind2     TYPE ze_nome_field VALUE 'IND2',
            gc_loc1     TYPE ze_nome_field VALUE 'LOC1',
            gc_loc2     TYPE ze_nome_field VALUE 'LOC2',
            gc_lunas    TYPE ze_nome_field VALUE 'LUNAS',
            gc_mail     TYPE ze_nome_field VALUE 'MAIL',
            gc_nome     TYPE ze_nome_field VALUE 'NOME',
            gc_nent     TYPE ze_nome_field VALUE 'NENT',
            gc_nmdoc    TYPE ze_nome_field VALUE 'NMDOC',
            gc_piva     TYPE ze_nome_field VALUE 'PIVA',
            gc_prof     TYPE ze_nome_field VALUE 'PROF',
            gc_prov1    TYPE ze_nome_field VALUE 'PROV1',
            gc_prov2    TYPE ze_nome_field VALUE 'PROV2',
            gc_pronas   TYPE ze_nome_field VALUE 'PRONAS',
            gc_rldat    TYPE ze_nome_field VALUE 'RLDAT',
            gc_rllg     TYPE ze_nome_field VALUE 'RLLG',
            gc_ss       TYPE ze_nome_field VALUE 'SS',
            gc_st1      TYPE ze_nome_field VALUE 'ST1',
            gc_st2      TYPE ze_nome_field VALUE 'ST2',
            gc_stnas    TYPE ze_nome_field VALUE 'STNAS',
            gc_telc     TYPE ze_nome_field VALUE 'TELC',
            gc_tpdoc    TYPE ze_nome_field VALUE 'TPDOC',
            gc_tent     TYPE ze_nome_field VALUE 'TENT',
            gc_tt1      TYPE ze_nome_field VALUE 'TT1',
            gc_tt2      TYPE ze_nome_field VALUE 'TT2',
            gc_tt3      TYPE ze_nome_field VALUE 'TT3',

            gc_indirizzi1           TYPE ze_nome_field VALUE 'INDIRIZZI1',
            gc_indirizzi2           TYPE ze_nome_field VALUE 'INDIRIZZI2',
            gc_indirizzi3           TYPE ze_nome_field VALUE 'INDIRIZZI3',
            gc_indirizzi4           TYPE ze_nome_field VALUE 'INDIRIZZI4',
            gc_cap                  TYPE ze_nome_field VALUE 'CAP',
            gc_cap_soc              TYPE ze_nome_field VALUE 'CAP_SOC',
            gc_cod_cciaa            TYPE ze_nome_field VALUE 'COD_CCIAA',
            gc_cod_ciae             TYPE ze_nome_field VALUE 'COD_CIAE',
            gc_data_iniz_val_ptb    TYPE ze_nome_field VALUE 'DATA_INIZ_VAL_PTB',
            gc_data_ril_doc_id      TYPE ze_nome_field VALUE 'DATA_RIL_DOC_ID',
            gc_data_costituzione    TYPE ze_nome_field VALUE 'DATA_COSTITUZIONE',
            gc_des_segmento         TYPE ze_nome_field VALUE 'DES_SEGMENTO',
            gc_luogo_rilascio       TYPE ze_nome_field VALUE 'LUOGO_RILASCIO',
            gc_fatt                 TYPE ze_nome_field VALUE 'FATT',
            gc_fax1                 TYPE ze_nome_field VALUE 'FAX1',
            gc_flasg_asscat         TYPE ze_nome_field VALUE 'FLASG_ASSCAT',
            gc_flasg_cat_neg        TYPE ze_nome_field VALUE 'FLASG_CAT_NEG',
            gc_flag_franch          TYPE ze_nome_field VALUE 'FLAG_FRANCH',
            gc_flag_multisede       TYPE ze_nome_field VALUE 'FLAG_MULTISEDE',
            gc_flag_constrat        TYPE ze_nome_field VALUE 'FLAG_CONSTRAT',
            gc_flag_inizcomm        TYPE ze_nome_field VALUE 'FLAG_INIZCOMM',
            gc_flag_vendterzi       TYPE ze_nome_field VALUE 'FLAG_VENDTERZI',
            gc_for_giuri            TYPE ze_nome_field VALUE 'FOR_GIURI',
            gc_indirizzo            TYPE ze_nome_field VALUE 'INDIRIZZO',
            gc_iniz_comm            TYPE ze_nome_field VALUE 'INIZ_COMM',
            gc_localita             TYPE ze_nome_field VALUE 'LOCALITA',
            gc_nat_giuris           TYPE ze_nome_field VALUE 'NAT_GIURIS',
            gc_nazione              TYPE ze_nome_field VALUE 'NAZIONE',
            gc_numero               TYPE ze_nome_field VALUE 'NUMERO',
            gc_num_doc_identita     TYPE ze_nome_field VALUE 'NUM_DOC_IDENTITA',
            gc_num_sedi             TYPE ze_nome_field VALUE 'NUM_SEDI',
            gc_num_dip              TYPE ze_nome_field VALUE 'NUM_DIP',
            gc_part_iva             TYPE ze_nome_field VALUE 'PART_IVA',
            gc_provincia            TYPE ze_nome_field VALUE 'PROVINCIA',
            gc_ptb_card             TYPE ze_nome_field VALUE 'PTB_CARD',
            gc_rag_soc              TYPE ze_nome_field VALUE 'RAG_SOC',
            gc_cod_rea              TYPE ze_nome_field VALUE 'COD_REA',
            gc_rilasciato_da        TYPE ze_nome_field VALUE 'RILASCIATO_DA',
            gc_settore_attiv        TYPE ze_nome_field VALUE 'SETTORE_ATTIV',
            gc_tel1                 TYPE ze_nome_field VALUE 'TEL1',
            gc_tipo_document        TYPE ze_nome_field VALUE 'TIPO_DOCUMENT',
            gc_tt_dati              TYPE ze_nome_field VALUE 'TT_DATI',
            gc_vend_terzi           TYPE ze_nome_field VALUE 'VEND_TERZI',
            gc_zcs1                 TYPE crmd_orderadm_h-process_type VALUE 'ZCS1',
            gc_nop_configurazione   TYPE zappl         VALUE 'NOP_CONFIGURAZIONE',
            gc_pmi                  TYPE zca_tsc_products-channel VALUE 'PMI',
            gc_nor_configurazione   TYPE zappl         VALUE 'NOR_CONFIGURAZIONE'.


DATA: BEGIN OF gs_but000_dom,
          partner       TYPE but000-partner,
          bu_group      TYPE but000-bu_group,
          bu_sort1      TYPE but000-bu_sort1,
          zztipo_codic  TYPE but000-zztipo_codic,
          name_org1     TYPE but000-name_org1,
          name_org2     TYPE but000-name_org2,
          name_org3     TYPE but000-name_org3,
          name_org4     TYPE but000-name_org4,
          mc_name1      TYPE but000-mc_name1,
        END OF gs_but000_dom.

DATA:  gt_but000_dom   LIKE STANDARD TABLE OF gs_but000_dom,
       gt_text         TYPE STANDARD TABLE OF ztb0000cuqdmqt.

DATA: gr_gruppi       TYPE RANGE OF zca_param-z_val_par,
      gr_gruppi_line  LIKE LINE OF gr_gruppi,
      gr_partner      TYPE RANGE OF but000-partner,
      gr_partner_line LIKE LINE OF gr_partner,
      gr_cod_sia      TYPE RANGE OF but000-bu_sort1,
      gr_cod_sia_line LIKE LINE OF gr_cod_sia,
      gr_desc         TYPE RANGE OF but000-mc_name1,
      gr_desc_line    LIKE LINE OF gr_desc.

TYPES: BEGIN OF t_tipol,
       contratto     TYPE zca_tipol_contr-contratto,
       operazione    TYPE zca_tipol_contr-operazione,
       id_tipologica TYPE zca_tipol_contr-id_tipologica,
       cliente       TYPE zca_tipol_contr-cliente,
    END OF  t_tipol.

TYPES: BEGIN OF t_zca_tsc_products,
        application  TYPE zca_tsc_products-application,
        channel      TYPE zca_tsc_products-channel,
        process_type TYPE zca_tsc_products-process_type,
        product_id   TYPE zca_tsc_products-product_id,
        cont_pers_pf TYPE zca_tsc_products-cont_pers_pf,
       END OF t_zca_tsc_products.

TYPES: tp_contact_person  TYPE STANDARD TABLE OF zca_contact,
       tp_dati_aggiuntivi TYPE STANDARD TABLE OF zca_dati_aggiunt,
       tp_products_item   TYPE STANDARD TABLE OF zca_products_item,
       tp_addon_prod      TYPE STANDARD TABLE OF zmp_addon_prod,
       tp_pers            TYPE STANDARD TABLE OF zca_contact_pers,
       tp_data            TYPE STANDARD TABLE OF crmxif_bustrans,
       tp_text            TYPE STANDARD TABLE OF zca_text,
       tp_partner         TYPE STANDARD TABLE OF bapibus20001_partner_dis,
       tp_prod_list       TYPE STANDARD TABLE OF bapibus20001_product_list_dis,
       tp_item            TYPE STANDARD TABLE OF bapibus20001_item_dis,
       but000_dom_t       LIKE STANDARD TABLE OF gs_but000_dom,
       ztb0000cuqdmqt_t   TYPE STANDARD TABLE OF ztb0000cuqdmqt,
       zca_societa_t      TYPE STANDARD TABLE OF zca_societa,
       tp_zst_web_search_registry_res TYPE STANDARD TABLE OF zst_web_search_registry_res.

TYPES: BEGIN OF t_web_log_cont,
        guid TYPE zca_web_log_cont-guid,
       END OF t_web_log_cont.

TYPES: BEGIN OF t_crm_jest,
        objnr TYPE crm_jest-objnr,
       END OF t_crm_jest.

TYPES: BEGIN OF t_crmd_orderadm_h,
        guid          TYPE crmd_orderadm_h-guid,
        object_id     TYPE crmd_orderadm_h-object_id,
        process_type  TYPE crmd_orderadm_h-process_type,
       END OF t_crmd_orderadm_h.


DATA: gt_tipol TYPE STANDARD TABLE OF t_tipol.

DATA: va_stato      TYPE crm_j_status,
      va_schema     TYPE crm_j_stsma.
DATA  g_commit.

* Begin AG 08.05.2012
DATA: gt_promo TYPE STANDARD TABLE OF zst_promo_web.
FIELD-SYMBOLS <fs_promo> TYPE zst_promo_web.
* End   AG 08.05.2012

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
