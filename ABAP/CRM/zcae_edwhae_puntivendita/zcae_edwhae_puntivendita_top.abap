*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_PUNTIVENDITA_TOP
*&---------------------------------------------------------------------*


TABLES crmd_orderadm_h.
* -- Parametri di input
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta  RADIOBUTTON GROUP gr1             DEFAULT 'X',
           r_full   RADIOBUTTON GROUP gr1,
           p_date_f TYPE crmd_orderadm_h-created_at,
           p_fout   TYPE filename-fileintern          DEFAULT 'ZCRMOUT001_EDWHAEPUNTIVENDITA' OBLIGATORY,
           p_flog   TYPE filename-fileintern          DEFAULT 'ZCRMLOG001_EDWHAEPUNTIVENDITA' OBLIGATORY,
           p_psize  TYPE i                            DEFAULT 150 OBLIGATORY,
           p_ind(8) TYPE c.

SELECT-OPTIONS: s_ptype FOR crmd_orderadm_h-process_type.

* Begin AG 25.06.2012
SELECT-OPTIONS: s_object FOR crmd_orderadm_h-object_id .
* End   AG 25.06.2012

SELECTION-SCREEN END OF BLOCK b1.

* -- Dichiarazione Tipi
TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         sdlstrttm TYPE tbtco-sdlstrttm,
         status    TYPE tbtco-status,
       END OF t_tbtco.

TYPES: BEGIN OF t_customer_h,
         guid             TYPE crmd_customer_h-guid,
         zzcustomer_h0901 TYPE crmd_customer_h-zzcustomer_h0901,
         zzcustomer_h0902 TYPE crmd_customer_h-zzcustomer_h0902,
         zz_opzione       TYPE crmd_customer_h-zz_opzione,
         zz_operazione    TYPE crmd_customer_h-zz_operazione,
         zz_numero_cc     TYPE crmd_customer_h-zz_numero_cc,
         zz_idunivoco     TYPE crmd_customer_h-zz_idunivoco,
         zz_motivazione   TYPE crmd_customer_h-zz_motivazione,
         zz_raccomandata  TYPE crmd_customer_h-zz_raccomandata, "ADD GC 23/07/09
         zz_distinta      TYPE crmd_customer_h-zz_distinta,     "ADD GC 23/07/09
         zz_cod_conv      TYPE crmd_customer_h-zz_cod_conv,     "ADD GC 23/07/09
         zz_tipo_conto    TYPE crmd_customer_h-zz_tipo_conto,
         zz_intest_conto  TYPE crmd_customer_h-zz_intest_conto,
         zz_promo         TYPE crmd_customer_h-zz_promo,
         zz_provenienza   TYPE crmd_customer_h-zz_provenienza, " Add AS 16.03.2012
         zz_firma         TYPE crmd_customer_h-zz_firma,
         zz_bonifica      TYPE crmd_customer_h-zz_bonifica,
* ADD MA 27.09.2010 Gestione campi contratti PTB
         zz_mod_pagamento TYPE crmd_customer_h-zz_mod_pagamento,
         zz_codice_deroga TYPE crmd_customer_h-zz_codice_deroga,
         zz_iban          TYPE crmd_customer_h-zz_iban,
         zz_mezzo_pagam   TYPE crmd_customer_h-zz_mezzo_pagam,
         zz_inter_mora    TYPE crmd_customer_h-zz_inter_mora,
         zz_termini_pag   TYPE crmd_customer_h-zz_termini_pag,
         zz_invio_fattura TYPE crmd_customer_h-zz_invio_fattura,
         zz_ind_fatt      TYPE crmd_customer_h-zz_ind_fatt,      "  Iniziativa 106592 - Nuovi campi MAAF
         zz_pick_up       TYPE crmd_customer_h-zz_pick_up,
         zz_aggr_fattura  TYPE crmd_customer_h-zz_aggr_fattura,
         zz_cod_ccontratt TYPE crmd_customer_h-zz_cod_ccontratt, "Modifica RS 26.10.2011 (Campo ACP)
         zz_period_fatt   TYPE crmd_customer_h-zz_period_fatt,
         zz_dur_cons_sost TYPE crmd_customer_h-zz_dur_cons_sost,
         zz_can_erogaz    TYPE crmd_customer_h-zz_can_erogaz,
         zz_period_sett   TYPE crmd_customer_h-zz_period_sett,
         zz_altra_period  TYPE crmd_customer_h-zz_altra_period,
         zz_totale_lavor  TYPE crmd_customer_h-zz_totale_lavor,
* END ADD MA 27.09.2010 Gestione campi contratti PTB
* ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
         zzcustomer_h2301 TYPE crmd_customer_h-zzcustomer_h2301,
         zzcustomer_h2302 TYPE crmd_customer_h-zzcustomer_h2302,
         zzcustomer_h2304 TYPE crmd_customer_h-zzcustomer_h2304,
         zzcustomer_h2306 TYPE crmd_customer_h-zzcustomer_h2306,
         zzcustomer_h2303 TYPE crmd_customer_h-zzcustomer_h2303,
         zzcustomer_h2305 TYPE crmd_customer_h-zzcustomer_h2305,
* END ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
* Begin AG 22.03.2011 18:05:38
         zzdata_scadenza  TYPE crmd_customer_h-zzdata_scadenza,
* End   AG 22.03.2011 18:05:38
* INIZIO MODIFICA AS DEL 11.05.2011 14:58:25
         zz_regio_resid   TYPE crmd_customer_h-zz_regio_resid,
         zzcustomer_h2307 TYPE crmd_customer_h-zzcustomer_h2307,
         zzid_modulo      TYPE crmd_customer_h-zzid_modulo,
* FINE MODIFICA AS DEL 11.05.2011 14:58:25
         " Inizio AS 15.05.2012
         zz_tel_mise      TYPE crmd_customer_h-zz_tel_mise,
         zz_tipo_conto_s  TYPE crmd_customer_h-zz_tipo_conto_s,
         zzlink_object_id TYPE crmd_customer_h-zzlink_object_id,
         " Fine   AS 15.05.2012
         zzmodalita       TYPE crmd_customer_h-zzmodalita, "VPM-26.04.2012 GEC
         zznickname       TYPE crmd_customer_h-zznickname, " Add AS 15.05.2012
*      PLP-01 - Insert - Start
         zz_tipo_carta_cr TYPE crmd_customer_h-zz_tipo_carta_cr,
         zz_ruolo         TYPE crmd_customer_h-zz_ruolo,
*      PLP-01 - Insert - End
*         zz_sede_lav     TYPE crmd_customer_h-zz_sede_lav, "ADD CL - 03.06.2013 - Delete CL 13.06.2013
         zz_codice_uff    TYPE crmd_customer_h-zz_codice_uff , "  Iniziativa 106592 - Nuovi campi MAAF
         "Inizio mferrara NOP_014 - 10/08/2015
         zz_totale_prezzo TYPE crmd_customer_h-zz_totale_prezzo,
         zz_durata_anni   TYPE crmd_customer_h-zz_durata_anni,
         "Fine mferrara NOP_014 - 10/08/2015

         zz_tipologia     TYPE crmd_customer_h-zz_tipologia,  "TP 21.04.2016
       END OF t_customer_h.

TYPES: BEGIN OF t_crm_jcds,
         objnr TYPE crm_jcds-objnr,
         stat  TYPE crm_jcds-stat,
         udate TYPE crm_jcds-udate,
         utime TYPE crm_jcds-utime,
         usnam TYPE crm_jcds-usnam,
       END OF t_crm_jcds.

TYPES: BEGIN OF t_prec_doc,
         guid        TYPE crmd_orderadm_h-guid,
         object_id   TYPE crmd_orderadm_h-object_id,
         object_type TYPE crmd_orderadm_h-object_type,
       END OF t_prec_doc.

TYPES: BEGIN OF t_guid16,
         guid TYPE crmd_orderadm_h-guid,
       END OF t_guid16.
TYPES: t_guid16_tab TYPE STANDARD TABLE OF t_guid16.

" inizio modifica mf 16/09/2011
TYPES: BEGIN OF t_bdm_contract,
         id_preventivo                TYPE zca_bdm_contract-id_preventivo,
         data_apertura_cc             TYPE zca_bdm_contract-dataaperturacc,
         correntista_bp               TYPE zca_bdm_contract-correntista,
         finalita_fin1                TYPE zca_bdm_contract-id_finalita1,
         finalita_fin2                TYPE zca_bdm_contract-id_finalita2,
         finalita_fin3                TYPE zca_bdm_contract-id_finalita3,
         debito_res                   TYPE zca_bdm_contract-debres,
         mod_erogazione               TYPE zca_bdm_contract-mod_erogazione,
         mod_rimborso                 TYPE zca_bdm_contract-mod_rimborso,
         garanzia_fideiussoria        TYPE zca_bdm_contract-flag_fideiussion,
         tipo_garanzia_richiesta      TYPE zca_bdm_contract-id_garanzia,
         importo_garanzia_richiesta   TYPE zca_bdm_contract-importo_garanzia,
         data_delibera                TYPE zca_bdm_contract-data_delibera,
         importo_deliberato           TYPE zca_bdm_contract-imp_deliberato,
         dur_finanziamento_deliberato TYPE zca_bdm_contract-durfindel,
         periodicita_rata_deliberata  TYPE zca_bdm_contract-perratadel,
         tipo_garanzia_deliberata1    TYPE zca_bdm_contract-tipo_gar_del_1,
         importo_garanzia_deliberata1 TYPE zca_bdm_contract-imp_delibera_1,
         denominazione_garante1       TYPE zca_bdm_contract-denom_gar1,
         tipo_garanzia_deliberata2    TYPE zca_bdm_contract-tipo_gar_del_2,
         importo_garanzia_deliberata2 TYPE zca_bdm_contract-imp_delibera_2,
         denominazione_garante2       TYPE zca_bdm_contract-denom_gar2,
         tipo_garanzia_deliberata3    TYPE zca_bdm_contract-tipo_gar_del_3,
         importo_garanzia_deliberata3 TYPE zca_bdm_contract-imp_delibera_3,
         denominazione_garante3       TYPE zca_bdm_contract-denom_gar3,
         data_stipula_contratto       TYPE zca_bdm_contract-data_stip_contr,
         data_erogazione              TYPE zca_bdm_contract-data_erogazione,
         importo_erogato              TYPE zca_bdm_contract-imp_cpi_erog,
         tasso_erogato                TYPE zca_bdm_contract-tipo_tasso_erog,
         spread_erogato               TYPE zca_bdm_contract-spreadappl,
         taeg_erogato                 TYPE zca_bdm_contract-taeg,
         importo_premio_cpi_erogato   TYPE zca_bdm_contract-imp_cpi_erog,
         imp_scoppio_incendio_erogato TYPE zca_bdm_contract-imp_pr_scop_inc,
         spese_istruttoria            TYPE zca_bdm_contract-spese_istruttori,
         costo_garanzia               TYPE zca_bdm_contract-costo_garanzia,
         tipo_tasso_erogato           TYPE zca_bdm_contract-tipo_tasso_erog,
         data_scadenza_finanziamento  TYPE zca_bdm_contract-data_scad_fin,
         contract_guid                TYPE zca_bdm_contract-contract_guid,
         id_contratto_glm             TYPE zca_bdm_contract-id_contratto_glm,
         prodotto                     TYPE zca_bdm_contract-prodotto,
         importo_richiesto            TYPE zca_bdm_contract-importo_rich,
         data_richiesta               TYPE zca_bdm_contract-data_richiesta, "add VPM 06.02.2012
         data_sottoscrizi             TYPE zca_bdm_contract-data_sottoscrizi, "VPM 21.03.2012
*        polizza_scop_inc                 TYPE zca_bdm_contract-polizza_scop_inc, "add mf 30/11/2011
*        presenza_cpi                     TYPE zca_bdm_contract-presenza_cpi, "add mf 30/11/2011
*        importo_cpi                      TYPE zca_bdm_contract-importo_cpi, "add VPM 24.01.2012
*        imp_pr_scop_inc                  TYPE zca_bdm_contract-imp_pr_scop_inc, "add VPM 24.01.2012
       END OF t_bdm_contract.

TYPES: BEGIN OF t_bdm_prev_bp,
         id_preventivo TYPE zca_bdm_prev_bp-id_preventivo,
         id_contratto  TYPE zca_bdm_prev_bp-id_contratto,
       END OF t_bdm_prev_bp.

TYPES: BEGIN OF t_leggi_prev,
         tipo_tasso_richiesto TYPE zca_bdm_contract-tipologia_tasso,
         convenzione          TYPE zca_bdm_contract-convenzione,
         durata_fin_ric       TYPE zca_bdm_contract-durata_fin_ric,
         periodicita_ric      TYPE zca_bdm_contract-periodicita_ric,
         n_rate_ric           TYPE zca_bdm_contract-n_rate_ric,
         tipo_piano_amm       TYPE zca_bdm_contract-tipo_piano_amm,
         presenza_cpi         TYPE zca_bdm_contract-presenza_cpi,
         importo_cpi          TYPE zca_bdm_contract-importo_cpi,
         polizza_scop_inc     TYPE zca_bdm_contract-polizza_scop_inc,
         imp_pr_scop_inc      TYPE zca_bdm_contract-imp_pr_scop_inc,
         id_preventivo        TYPE zca_bdm_contract-id_preventivo,
       END OF  t_leggi_prev.

TYPES: BEGIN OF t_bdm_crif,
         guid_contratto   TYPE zca_bdm_crif_1-guid_contratto,
         codice_crif      TYPE zca_bdm_crif_1-codice_crif, "VPM-21.02.2012
         esito_pre_screen TYPE zca_bdm_crif_1-esito_pre_screen,
         codice_esito_sco TYPE zca_bdm_crif_1-codice_esito_sco,
         desc_esito_score TYPE zca_bdm_crif_1-desc_esito_score,
         probabilita_defa TYPE zca_bdm_crif_1-probabilita_defa,
         classe           TYPE zca_bdm_crif_1-classe,
       END OF t_bdm_crif.


" fine modifica mf 16/09/2011

"Inizio modifiche - GC 24.07.2009 10:01:41
TYPES: BEGIN OF t_customer_i,
         guid             TYPE crmd_customer_i-guid,
         zz_motivaz_nor_i TYPE crmd_customer_i-zz_motivaz_nor_i,
         zz_cat_motivaz_i TYPE crmd_customer_i-zz_cat_motivaz_i,
         zz_descr_lavor_i TYPE crmd_customer_i-zz_descr_lavor_i,
         zz_lavorazione_i TYPE crmd_customer_i-zz_lavorazione_i,
         zz_cod_promo     TYPE crmd_customer_i-zz_cod_promo,
* ADD MA 27.09.2010 Gestione campi contratti PTB
         zz_id_prod_ext   TYPE crmd_customer_i-zz_id_prod_ext,
         zz_codice_promoz TYPE crmd_customer_i-zz_codice_promoz,
         zz_ytd_quantity  TYPE crmd_customer_i-zz_ytd_quantity,
         zz_net_pr_unit   TYPE crmd_customer_i-zz_net_pr_unit,
         zz_total_value   TYPE crmd_customer_i-zz_total_value,
         zz_qmax_perorder TYPE crmd_customer_i-zz_qmax_perorder,
         zz_shipping_freq TYPE crmd_customer_i-zz_shipping_freq,
* END ADD MA 27.09.2010 Gestione campi contratti PTB
*Inizio modifica RS 26.10.2001 (Campi ACP)
         zz_qta_effettiva TYPE zptb_actual_quantity,
         zz_imp_eff_liva  TYPE zptb_gross_actual_value,
         zz_imp_eff_niva  TYPE zptb_net_actual_value,
*Fine modifica RS 26.10.2011
* Begin AG 22.03.2011 18:08:45
         zz_code_resp     TYPE crmd_customer_i-zz_code_resp,
         zz_code_chall    TYPE crmd_customer_i-zz_code_chall,
         zz_code_sms_otp  TYPE crmd_customer_i-zz_code_sms_otp,
         zz_cell_fdr      TYPE crmd_customer_i-zz_cell_fdr,
* End   AG 22.03.2011 18:08:45
         " Inizio AS 15.05.2012
         zz_cod_promo_web TYPE crmd_customer_i-zz_cod_promo_web,
         " Fine   AS 15.05.2012
       END OF t_customer_i.
TYPES: t_customer_i_tab TYPE STANDARD TABLE OF t_customer_i.
"Fine   modifiche - GC 24.07.2009 10:01:41

* 105900: strutture per il recupero dei dati relativi ai punti vendita e ai terminali. - inizio - tm
TYPES: BEGIN OF ls_puntivendita,
         record_id        TYPE zpuntivendita-record_id,
         parent_id        TYPE zpuntivendita-parent_id,
         object_id        TYPE zpuntivendita-object_id,
         zzzshop_id       TYPE zpuntivendita-zzzshop_id,
         zzzshop_insegna  TYPE zpuntivendita-zzzshop_insegna,
         zzznr_pospi_std  TYPE zpuntivendita-zzznr_pospi_std,
         zzznr_pospi_adsl TYPE zpuntivendita-zzznr_pospi_adsl,
         zzznr_pospi_cord TYPE zpuntivendita-zzznr_pospi_cord,
         zzznr_pospi_ppad TYPE zpuntivendita-zzznr_pospi_ppad,
         zzznr_pospi_gprs TYPE zpuntivendita-zzznr_pospi_gprs,
         zzznr_pospi_altr TYPE zpuntivendita-zzznr_pospi_altr,
         zzznr_postr_std  TYPE zpuntivendita-zzznr_postr_std,
         zzznr_postr_adsl TYPE zpuntivendita-zzznr_postr_adsl,
         zzznr_postr_cord TYPE zpuntivendita-zzznr_postr_cord,
         zzznr_postr_ppad TYPE zpuntivendita-zzznr_postr_ppad,
         zzznr_postr_gprs TYPE zpuntivendita-zzznr_postr_gprs,
         zzznr_postr_altr TYPE zpuntivendita-zzznr_postr_altr,
         zznr_pp_std_old  TYPE zpuntivendita-zznr_pp_std_old,
         zznr_pp_adsl_old TYPE zpuntivendita-zznr_pp_adsl_old,
         zznr_pp_cord_old TYPE zpuntivendita-zznr_pp_cord_old,
         zznr_pp_ppad_old TYPE zpuntivendita-zznr_pp_ppad_old,
         zznr_pp_gprs_old TYPE zpuntivendita-zznr_pp_gprs_old,
         zznr_pp_altr_old TYPE zpuntivendita-zznr_pp_altr_old,
         zznr_pt_std_old  TYPE zpuntivendita-zznr_pt_std_old,
         zznr_pt_adsl_old TYPE zpuntivendita-zznr_pt_adsl_old,
         zznr_pt_cord_old TYPE zpuntivendita-zznr_pt_cord_old,
         zznr_pt_ppad_old TYPE zpuntivendita-zznr_pt_ppad_old,
         zznr_pt_gprs_old TYPE zpuntivendita-zznr_pt_gprs_old,
         zznr_pt_altr_old TYPE zpuntivendita-zznr_pt_altr_old,
         zznr_pt_self_old TYPE zpuntivendita-zznr_pt_self_old,
         zznr_pospi_ptop  TYPE zpuntivendita-zznr_pospi_ptop,
         zznr_postr_ptop  TYPE zpuntivendita-zznr_postr_ptop,
         zznr_pp_ptop_old TYPE zpuntivendita-zznr_pp_ptop_old,
         zznr_pt_ptop_old TYPE zpuntivendita-zznr_pt_ptop_old,
         zzzzateco        TYPE zpuntivendita-zzzzateco,
         zzz_iban_acc     TYPE zpuntivendita-zzz_iban_acc,
         zz_iban_add      TYPE zpuntivendita-zz_iban_add,
         zznr_postr_self  TYPE zpuntivendita-zznr_postr_self,
         zzznr_mpos       TYPE zpuntivendita-zzznr_mpos,
         zzznr_pospi_virt TYPE zpuntivendita-zzznr_pospi_virt,
         zzznr_postr_virt TYPE zpuntivendita-zzznr_postr_virt,    "da aggiungere solo in 18.07
         zzz_str_reg_add  TYPE zpuntivendita-zzz_str_reg_add,
         zzz_str_reg_acc  TYPE zpuntivendita-zzz_str_reg_acc,
         zzz_vp_gest_term TYPE zpuntivendita-zzz_vp_gest_term,
         zzzpostepay      TYPE zpuntivendita-zzzpostepay,
         zzz_cc_internaz  TYPE zpuntivendita-zzz_cc_internaz,
         zzz_masterpass   TYPE zpuntivendita-zzz_masterpass,
         zzz_recurring    TYPE zpuntivendita-zzz_recurring,
         zzz_cardonfile   TYPE zpuntivendita-zzz_cardonfile,
         zzz_moto         TYPE zpuntivendita-zzz_moto,
         zzz_config_ecomm TYPE zpuntivendita-zzz_config_ecomm,
       END OF ls_puntivendita.
DATA: lt_puntivendita TYPE STANDARD TABLE OF ls_puntivendita.

TYPES: BEGIN OF ls_terminali,
         record_id     TYPE zca_terminal-record_id,
         parent_id     TYPE zca_terminal-parent_id,
         object_id     TYPE zca_terminal-object_id,
         zzorder_id    TYPE zca_terminal-zzorder_id,
         zzterminal_id TYPE zca_terminal-zzterminal_id,
         zzcreate_at   TYPE zca_terminal-zzcreate_at,
         zzzstato      TYPE zca_terminal-zzzstato,
         zzowner       TYPE zca_terminal-zzowner,
         zzdevice_type TYPE zca_terminal-zzdevice_type,
       END OF ls_terminali.
DATA: lt_terminali TYPE STANDARD TABLE OF ls_terminali.
* 105900: strutture per il recupero dei dati relativi ai punti vendita e ai terminali. - fine   - tm
*** Inizio TP 21.04.2016
TYPES: BEGIN OF t_zca_spid_prod,
         id_pratica TYPE zca_spid_prod-id_pratica,
         prodotto   TYPE zca_spid_prod-prodotto,
         stato      TYPE zca_spid_prod-stato,
       END OF t_zca_spid_prod.
TYPES: t_zca_spid_prod_tab TYPE STANDARD TABLE OF t_zca_spid_prod.

TYPES: BEGIN OF t_attr_acc,
         tipo_record(2)  TYPE c,
         codice_crm(10)  TYPE c,
         attributo_1(40) TYPE c,
         attributo_2(40) TYPE c,
         attributo_3(40) TYPE c,
       END OF t_attr_acc.
TYPES: t_attr_acc_tab TYPE STANDARD TABLE OF t_attr_acc.
*** Fine TP 21.04.2016

* -- Tracciato Record di Testata
TYPES: BEGIN OF t_header,
         tipo_record(2)                   TYPE c,
         codice_crm(10)                   TYPE c,
         descrizione(40)                  TYPE c,
         tipo_contratto(4)                TYPE c,
         data_apertura(8)                 TYPE c,
         data_chiusura(8)                 TYPE c,
         stato(13)                        TYPE c,
         risultato(14)                    TYPE c,
         numero_conto(20)                 TYPE c,
         operazione(2)                    TYPE c,
         area(10)                         TYPE c,
         canale(3)                        TYPE c,
         note(255)                        TYPE c,
         doc_precedente(10)               TYPE c,
         tipo_doc_prec(10)                TYPE c,
         crdate(8)                        TYPE c,
         crtime(6)                        TYPE c,
         chdate(8)                        TYPE c,
         chtime(6)                        TYPE c,
         id_univoco(32)                   TYPE c,
         classe_documento(10)             TYPE c,
         id_distinta(10)                  TYPE c, "ADD GC 23/07/09
         no_raccomandata(12)              TYPE c, "ADD GC 23/07/09
         cod_convenzione(10)              TYPE c, "ADD GC 23/07/09
         data_richiesta(8)                TYPE c, "ADD GC 23/07/09
         ora_richiesta(6)                 TYPE c,
         data_invio_pratica(8)            TYPE c,
         ora_invio_pratica(6)             TYPE c,
         data_arrivo_pratica(8)           TYPE c, "ADD GC 23/07/09
         ora_arrivo_pratica(6)            TYPE c,
         data_inizio_lavorazione(8)       TYPE c, "ADD GC 23/07/09
         ora_inizio_lavorazione(6)        TYPE c,
         data_fine_lavorazione(8)         TYPE c, "ADD GC 23/07/09
         ora_fine_lavorazione(6)          TYPE c,
         intest_part_rapporto(70)         TYPE c,
         prod_in_promoz(1)                TYPE c,
         tipo_firma(1)                    TYPE c,
         contratto_bonificato(1)          TYPE c,
         zz_tipo_conto(4)                 TYPE c,
* ADD MA 27.09.2010 Gestione campi contratti PTB
         conto_contrattuale(20)           TYPE c,
         mod_pagamento(4)                 TYPE c,
         deroga(4)                        TYPE c,
         iban(27)                         TYPE c,
         mezzo_pagamento(4)               TYPE c,
         interessi_mora(4)                TYPE c,
         termini_pagamento(4)             TYPE c,
         zzinvio_fatt(1)                  TYPE c,
         pick_up(1)                       TYPE c,
         aggregazione(1)                  TYPE c,
         per_fatturazione(4)              TYPE c,
         durata_cons_sostit(12)           TYPE c,
         canale_erogazione(3)             TYPE c,
         per_servizio(7)                  TYPE c,
         altra_per_servizio(50)           TYPE c,
         totale_lavorazioni(12)           TYPE c,
* END ADD MA 27.09.2010 Gestione campi contratti PTB
* ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
         tipo_doc(3)                      TYPE c,
         numero_doc(30)                   TYPE c,
         data_val(8)                      TYPE c,
         rilasc_doc(60)                   TYPE c,
         ente_rilas(30)                   TYPE c,
         ente_spec(50)                    TYPE c,
* END ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
* Begin AG 22.03.2011 18:13:32
         data_scadenza(8)                 TYPE c,
* End   AG 22.03.2011 18:13:32
* INIZIO MODIFICA AS DEL 11.05.2011 15:06:05
         regione_resid(3)                 TYPE c,
         frazionario(10)                  TYPE c,
         id_modulo_mise(16)               TYPE c,
* FINE MODIFICA AS DEL 11.05.2011 15:06:05
* Inizio Modifica MF 16.09.2011
         finalita_fin1(3)                 TYPE c,
         finalita_fin2(3)                 TYPE c,
         finalita_fin3(3)                 TYPE c,
         debito_res(13)                   TYPE c,
         mod_erogazione(3)                TYPE c,
         mod_rimborso(3)                  TYPE c,
         tipo_tasso_richiesto(40)         TYPE c,
         garanzia_fideiussoria(1)         TYPE c,
         tipo_garanzia_richiesta(30)      TYPE c,
         importo_garanzia_richiesta(13)   TYPE c,
         polizza_cpi(1)                   TYPE c,
         importo_premio_cpi(13)           TYPE c,
         polizza_scoppio_incendio(1)      TYPE c,
         imp_premio_scoppio_incendio(13)  TYPE c,
         data_delibera(8)                 TYPE c,
         importo_deliberato(13)           TYPE c,
         dur_finanziamento_deliberato(5)  TYPE c,
         periodicita_rata_deliberata(30)  TYPE c,
         tipo_garanzia_deliberata1(30)    TYPE c,
         importo_garanzia_deliberata1(13) TYPE c,
         denominazione_garante1(30)       TYPE c,
         tipo_garanzia_deliberata2(30)    TYPE c,
         importo_garanzia_deliberata2(13) TYPE c,
         denominazione_garante2(30)       TYPE c,
         tipo_garanzia_deliberata3(30)    TYPE c,
         importo_garanzia_deliberata3(13) TYPE c,
         denominazione_garante3(30)       TYPE c,
         data_stipula_contratto(8)        TYPE c,
         data_erogazione(8)               TYPE c,
         importo_erogato(13)              TYPE c,
         tasso_erogato(13)                TYPE c,
         spread_erogato(13)               TYPE c,
         taeg_erogato(13)                 TYPE c,
         importo_premio_cpi_erogato(13)   TYPE c,
         imp_scoppio_incendio_erogato(13) TYPE c,
         spese_istruttoria(13)            TYPE c,
         costo_garanzia(13)               TYPE c,
         tipo_tasso_erogato(30)           TYPE c,
         data_scadenza_finanziamento(8)   TYPE c,
         id_preventivo(10)                TYPE c,
         data_apertura_cc(8)              TYPE c,
         correntista_bp(1)                TYPE c,
         id_contratto_glm(18)             TYPE c,
         id_preventivo_glm(10)            TYPE c,
         esito_pre_screening              TYPE c,
         codice_esito_sco(12)             TYPE c,
         desc_esito_score(100)            TYPE c,
         probabilita_defa(7)              TYPE c,
         classe(3)                        TYPE c,
         tipo_tasso_richiesto_des         TYPE char40,
         durata_finanziamento_del_des     TYPE char40,
         periodicita_rata_del_des         TYPE char40,
         tipo_tasso_erogato_des           TYPE char40,
* Fine Modifica MF 16.09.2011
         canale_provenienza(5)            TYPE c, " Add AS 16.03.2012
         codice_crif(10)                  TYPE c, "VPM-21.03.2012
         data_sottoscrizi(8)              TYPE c, "VPM-21.03.2012
         modalita(1)                      TYPE c, "VPM-26.04.2012 GEC
         " Inizio AS 15.05.2012
         nickname(100)                    TYPE c,
         id_contratto_web(10)             TYPE c,
         tipo_conto_origine(4)            TYPE c,
         telefono_contatto(30)            TYPE c,
         " Fine   AS 15.05.2012
*      PLP-01 - Insert - Start
         tipo_carta(10)                   TYPE c,
         ruolo(100)                       TYPE c,
*      PLP-01 - Insert - End
*       sede_lav(2)                           TYPE c, "ADD CL - 03.06.2013 - Delete CL - 13.06.2013

* Iniziativa 106592 - Estrazione campi MAAF - Start
         maaf_mail_fatt(241)              TYPE c, " Indir. e-mail (di fatturazione)
         maaf_cod_uff(6)                  TYPE c, " Codice Ufficio
         maaf_cod_ipa(16)                 TYPE c, " Codice IPA
         maaf_matri(60)                   TYPE c, " Matricola
         maaf_zzima(60)                   TYPE c, " Codice ZZIMA
         maaf_via(60)                     TYPE c, " Via
         maaf_civico(60)                  TYPE c, " Civico
         maaf_citta(60)                   TYPE c, " Città
         maaf_provincia(2)                TYPE c, " Provincia
         maaf_cap(5)                      TYPE c, " Cap
         maaf_affr_propri(1)              TYPE c, " Affrancatura Propri Invii Postali
         maaf_affr_terzi(1)               TYPE c, " Affrancatura invii postali di terzi
* Iniziativa 106592 - Estrazione campi MAAF - End
         "Inizio mferrara - NOP_014 - 10/08/2015
         maaf_imp_affidato(16)            TYPE c,
         maaf_durata_plafond(2)           TYPE c,
         maaf_scad_plafond(8)             TYPE c,
         "Fine mferrara - NOP_014 - 10/08/2015

         zz_tipologia(20)                 TYPE c, "TP 21.04.2016

       END OF t_header.

* 105900: tracciato record Punti vendita - Inizio
TYPES: BEGIN OF t_puntivendita,
         tipo_record(2)      TYPE c,
         codice_crm(10)      TYPE c,
         id_pos(10)          TYPE c,
         shop_id(15)         TYPE c,
         shop_insegna(40)    TYPE c,
         tip_pos(30)         TYPE c,
         numero_pos(3)       TYPE c,
* 105900: inizio modifica del 22.09.2016 - inizio
         stato(5)            TYPE c,
* 105900: fine modifica del 22.09.2016 - fine
         zzzzateco(10)       TYPE c,
         zzz_iban_acc(27)    TYPE c,
         zz_iban_add(27)     TYPE c,
* modifiche introduzione VPOS
         zzz_str_reg_add(2)  TYPE c,
         zzz_str_reg_acc(2)  TYPE c,
         zzz_vp_gest_term(3) TYPE c,
         zzzpostepay(1)      TYPE c,
         zzz_cc_internaz(1)  TYPE c,
         zzz_masterpass(1)   TYPE c,
* iniziativa E-Commerce 19.10
         zzz_recurring(1)    TYPE c,
         zzz_cardonfile(1)   TYPE c,
         zzz_moto(1)         TYPE c,
         zzz_config_ecomm(2) TYPE c,
       END OF t_puntivendita.
TYPES: t_puntivendita_tab TYPE STANDARD TABLE OF t_puntivendita.

* 105900: tracciato record Punti vendita - fine
* 105900: tracciato record terminali  - inizio
TYPES: BEGIN OF t_terminali,
         tipo_record(2)   TYPE c,
         codice_crm(10)   TYPE c,
         zzorder_id(10)   TYPE c,
         shop_id(15)      TYPE c,
         terminal_id(15)  TYPE c,
         zzcreate_at(15)  TYPE c,
         zzowner(15)      TYPE c,
         zzdevice_type(3) TYPE c,
         zzzstato(5)      TYPE c,
       END OF t_terminali.
TYPES: t_terminali_tab TYPE STANDARD TABLE OF t_terminali.
* 105900: tracciato record terminali  - fine

* -- Tracciato Record Prodotti
TYPES: BEGIN OF t_prodotti,
         tipo_record(2)                     TYPE c,
         codice_crm(10)                     TYPE c,
         tipo_posizione(4)                  TYPE c,
         id_pos(10)                         TYPE c,
         id_pos_padre(10)                   TYPE c,
         prodotto_bic(40)                   TYPE c,
         quantita(17)                       TYPE c,
         stato_prodotto(13)                 TYPE c,
         descrizione_lavorazione(30)        TYPE c, "ADD GC 23/07/09
         tipo_lavorazione(20)               TYPE c, "ADD GC 23/07/09
         categoria_motivazione(30)          TYPE c, "ADD GC 23/07/09
         motivazione(20)                    TYPE c, "ADD GC 23/07/09
         codice_promozione(10)              TYPE c,
* ADD MA 27.09.2010 Gestione campi contratti PTB
         id_prodotto_esterno(8)             TYPE c,
         promozione(4)                      TYPE c,
         quantita_annua(13)                 TYPE c,
         prezzo_per_unita(16)               TYPE c,   "13 unità, 2 decimali separati da '.'
         importo_totale(16)                 TYPE c,   "13 unità, 2 decimali separati da '.'
         quantita_max_per_ord(13)           TYPE c,
         frequenza_invio(10)                TYPE c,
* END ADD MA 27.09.2010 Gestione campi contratti PTB

* INIZIO MODIFICA AS DEL 20.04.2011

** Begin AG 22.03.2011 18:15:37
*        zz_code_resp(15)            TYPE c,
*        zz_code_chall(15)           TYPE c,
*        zz_code_sms_otp(15)         TYPE c,
*        zz_cell_fdr(20)             TYPE c,
** End   AG 22.03.2011 18:15:37
         zz_cell_fdr(20)                    TYPE c,
         flag_pcr(1)                        TYPE c,
         flag_sms_otp(1)                    TYPE c,
         flag_up(1)                         TYPE c,
* FINE MODIFICA AS DEL 20.04.2011
         "inizio modifica mf 03/10/2011
*        importo_richiesto(13)                TYPE c, "cancel VPM24.12.2012
         convenzione(2)                     TYPE c,
         durata_finanziamento_richiesto(40) TYPE c,
         periodicita_richiesta(40)          TYPE c,
         numero_rate_richieste(40)          TYPE c,
         piano_ammortamento(30)             TYPE c,
         "fine modifica mf 03/10/2011
         promozione_web(50)                 TYPE c, " Add AS 15.05.2012
       END OF t_prodotti.
TYPES: t_prodotti_tab TYPE STANDARD TABLE OF t_prodotti.

* -- Tracciato Record funzioni Partner
TYPES: BEGIN OF t_partner,
         tipo_record(2)      TYPE c,
         codice_crm(10)      TYPE c,
         funzione_partner(8) TYPE c,
         partner(10)         TYPE c,
         main_partner(1)     TYPE c,
         no_type(2)          TYPE c,
         classe_click(5)     TYPE c, " Add AS 15.05.2012
       END OF t_partner.
TYPES: t_partner_tab TYPE STANDARD TABLE OF t_partner.

* -- Tracciato Record Modifica di Stato: testata
TYPES: BEGIN OF t_mod_stato,
         tipo_record(2) TYPE c,
         codice_crm(10) TYPE c,
         stato(13)      TYPE c,
         udate(8)       TYPE c,
         utime(6)       TYPE c,
         user_id(12)    TYPE c,
       END OF t_mod_stato.
TYPES: t_mod_stato_tab TYPE STANDARD TABLE OF t_mod_stato.

"Inizio modifiche - GC 23.07.2009 12:09:05
* -- Tracciato Record Modifica di Stato: posizione
TYPES: BEGIN OF t_mod_stato_pos,
         tipo_record(2) TYPE c,
         codice_crm(10) TYPE c,
         stato(13)      TYPE c,
         id_pos(10)     TYPE c,
         udate(8)       TYPE c,
         utime(6)       TYPE c,
         user_id(12)    TYPE c,
       END OF t_mod_stato_pos.

TYPES: t_mod_stato_pos_tab TYPE STANDARD TABLE OF t_mod_stato_pos.
TYPES: lt_crm_jcds_tab TYPE STANDARD TABLE OF crm_jcds.

"Fine   modifiche - GC 23.07.2009 12:09:05

" Inizio AS 17.05.2012
" Tracciato CONSENSI PRIVACY CONTRATTI
TYPES: BEGIN OF t_cons_priv_contr,
         tipo_record(2) TYPE c,
         codice_crm(10) TYPE c,
         bp(10)         TYPE c,
         id_pos(10)     TYPE c,
         tipologia(10)  TYPE c,
         valore(10)     TYPE c,
       END OF t_cons_priv_contr.
TYPES: t_cons_priv_contr_tab TYPE STANDARD TABLE OF t_cons_priv_contr.

" Tracciato ATTRIBUTI-DIMENSIONI
TYPES: BEGIN OF t_attr_dimens,
         tipo_record(2) TYPE c,
         codice_crm(10) TYPE c,
         id_pos(10)     TYPE c,
         attributo(10)  TYPE c,
         dimensione(10) TYPE c,
       END OF t_attr_dimens.
TYPES: t_attr_dimens_tab TYPE STANDARD TABLE OF t_attr_dimens.

" Fine   AS 17.05.2012

"Inizio mferrara 10/08/2015
TYPES: BEGIN OF t_index,
         header TYPE crmd_order_index-header,
         date_3 TYPE crmd_order_index-date_3,
       END OF t_index.
"Fine mferrara 10/08/2015

* Begin MN - 03.11.2015
TYPES: BEGIN OF t_cronomapping,
         guid_testata TYPE zca_cronomapping-guid_testata,
         id_ermes     TYPE zca_cronomapping-id_ermes,
         guid_padre   TYPE zca_cronomapping-guid_padre,
       END OF t_cronomapping.
TYPES: t_cronomapping_t TYPE STANDARD TABLE OF t_cronomapping.
* End MN - 03.11.2015

* Begin AG 04.11.2011
CONSTANTS: gc_tipo_tasso  TYPE zbdm_cod_attrib VALUE 'TIPO_TASSO',
           gc_durata      TYPE zbdm_cod_attrib VALUE 'DURATA',
           gc_periodicita TYPE zbdm_cod_attrib VALUE 'PERIODICITA_RATA'. " Mod AG 21.11.2011
* End   AG 04.11.2011

* 105900: gestione dei tipo POS - inizio
TYPES: BEGIN OF ls_tipo_pos,
         tipo_pos    TYPE string,
         descrizione TYPE string,
       END OF ls_tipo_pos.
TYPES: t_tipo_pos TYPE STANDARD TABLE OF ls_tipo_pos.


DATA: lt_tipo_pos TYPE t_tipo_pos, w_tipo_pos TYPE ls_tipo_pos.

DATA: num_pos   TYPE i, descr_pos TYPE string.

CONSTANTS: c_ca6  TYPE zca_param-z_val_par VALUE 'CA6', " PIN PAD TOP
           c_ca1  TYPE zca_param-z_val_par VALUE 'CA1', " POS fisso
           c_ca2  TYPE zca_param-z_val_par VALUE 'CA2', " POS fisso ADSL / Ethernet
           c_ca3  TYPE zca_param-z_val_par VALUE 'CA3', " POS Cordless / WIFI
           c_ca4  TYPE zca_param-z_val_par VALUE 'CA4', " POS GPRS
           c_ca5  TYPE zca_param-z_val_par VALUE 'CA5', " PIN PAD
           c_alt  TYPE zca_param-z_val_par VALUE 'ALT', " Altro
           c_mop  TYPE zca_param-z_val_par VALUE 'MOP', " MobilePOS
           c_unt  TYPE zca_param-z_val_par VALUE 'UNT', " Unattended/Self
           c_ca7  TYPE zca_param-z_val_par VALUE 'CA7', " Virtual POS
           c_fa   TYPE zappl  VALUE 'FULL_ACQ_TERM',
           c_famp TYPE zca_param-z_group VALUE 'FAMP'.

* 105900: gestione dei tipo POS - inizio
DATA: p_term_f TYPE tbtco-sdlstrtdt,
      p_term_t TYPE tbtco-sdlstrtdt.
* 105900: gestione dei tipo POS - fine

* 105900: inizio modifica del 22.09.2016 - tm
CONSTANTS: c_scst TYPE zgroup VALUE 'SCST'.

* 105900: fine  modifica del 22.09.2016 - tm


* -- Dichiarazione Costanti
CONSTANTS: ca_x(1)         TYPE c                                      VALUE 'X',
           ca_a(1)         TYPE c                                      VALUE 'A',
           ca_e(1)         TYPE c                                      VALUE 'E',
           ca_b(1)         TYPE c                                      VALUE 'B',
           ca_i(1)         TYPE c                                      VALUE 'I',
           ca_pipe(1)      TYPE c                                      VALUE '|',
           ca_eq(2)        TYPE c                                      VALUE 'EQ',
           ca_hh(2)        TYPE c                                      VALUE 'HH',
           ca_pp(2)        TYPE c                                      VALUE 'PP',
* 105900: inizio modifica  - TM
           ca_pt(2)        TYPE c                                      VALUE 'PT',
* 105900: inizio modifica  - TM
           ca_fp(2)        TYPE c                                      VALUE 'FP',
           ca_ms(2)        TYPE c                                      VALUE 'MS',
           ca_mp(2)        TYPE c                                      VALUE 'MP',
           ca_r            TYPE tbtco-status                           VALUE 'R',
           ca_f            TYPE tbtco-status                           VALUE 'F',
           ca_z_appl       TYPE zca_param-z_appl                       VALUE 'ZCAE_EDWHAE_CONTRATTI',
           ca_z_appl_pv    TYPE zca_param-z_appl                       VALUE 'ZCAE_EDWHAE_PUNTIVENDITA',
           ca_crmi_ewdh    TYPE zappl                                  VALUE 'CRMI_EDWH',           " Add AS 15.05.2012
           ca_nor_conf     TYPE zappl                                  VALUE 'NOR_CONFIGURAZIONE',  " Add AS 15.05.2012
           ca_edwh_int     TYPE zappl                                  VALUE 'CRMI_EDWH_INT',       " Add AS 15.05.2012
           ca_edwh_coint   TYPE zappl                                  VALUE 'CRMI_EDWH_COINT',     " Add AS 15.05.2012
           ca_type         TYPE zgroup                                 VALUE 'TYPE',                " Add AS 15.05.2012
           ca_tab1         TYPE zgroup                                 VALUE 'TAB1',                " Add AS 15.05.2012
           ca_tab2         TYPE zgroup                                 VALUE 'TAB2',                " Add AS 15.05.2012
           ca_ods          TYPE zgroup                                 VALUE 'ODS',                 " Add AS 15.05.2012
           ca_cont         TYPE zgroup                                 VALUE 'CONT',                " Add AS 15.05.2012
           ca_cond         TYPE zgroup                                 VALUE 'COND',                " Add AS 15.06.2012
           ca_item         TYPE zgroup                                 VALUE 'ITEM', " Add AS 15.06.2012
           ca_priv         TYPE zgroup                                 VALUE 'PRIV',                " Add AS 15.05.2012
           ca_prov         TYPE zgroup                                 VALUE 'PROV',                " Add AS 15.05.2012
           ca_inte         TYPE zgroup                                 VALUE 'INTE',                " Add AS 15.05.2012
           ca_coin         TYPE zgroup                                 VALUE 'COIN',
* 105900: INIZIO MODIFICA DEL 15.09.2016
           ca_stap         TYPE zgroup                                 VALUE 'STAP',
* 105900: FINE MODIFICA DEL 15.09.2016
           ca_pft_cliente  TYPE znome_par                              VALUE 'PFT_CLIENTE',         " Add AS 15.05.2012
           ca_pft_cointest TYPE znome_par                              VALUE 'PFT_COINTESTAT',      " Add AS 15.05.2012
*           ca_file_temp    TYPE filename-fileintern                    VALUE 'ZCRMTEMP001_EDWHAECONTRATTI',
*           ca_jobname      TYPE tbtco-jobname                          VALUE 'ZCAE_EDWHAE_CONTRATTI',
           ca_file_temp    TYPE filename-fileintern                    VALUE 'ZCRMTEMP001_EDWHAEPUNTIVENDITA',
           ca_jobname      TYPE tbtco-jobname                          VALUE 'ZCAE_EDWHAE_PUNTIVENDITA',

           ca_edwc         TYPE zca_param-z_group                      VALUE 'EDWC',
           ca_cnop         TYPE zca_param-z_group                      VALUE 'CNOP',
           ca_objt         TYPE zca_param-z_group                      VALUE 'OBJT', "ADD GC 23/07/09
           ca_stah         TYPE zca_param-z_group                      VALUE 'STAH', "ADD GC 23/07/09
           ca_stai         TYPE zca_param-z_group                      VALUE 'STAI', "ADD GC 23/07/09
           ca_note         TYPE zca_param-z_group                      VALUE 'NOTE', "ADD GC 23/07/09
           ca_object_type  TYPE zca_param-z_nome_par                   VALUE 'OBJECT_TYPE',
           ca_acp          TYPE zgroup                                 VALUE 'ACP',
           ca_stato_h      TYPE zca_param-z_nome_par                   VALUE 'STATO_H',
           ca_stato_i      TYPE zca_param-z_nome_par                   VALUE 'STATO_I',
           ca_edw_note     TYPE zca_param-z_nome_par                   VALUE 'EDW_NOTE',
           ca_contratti    TYPE zca_param-z_nome_par                   VALUE 'CONTRATTI',
           ca_puntivendita TYPE zca_param-z_nome_par                   VALUE 'PUNTIVENDITA',
           ca_contstart    TYPE bapibus20001_appointment_dis-appt_type VALUE 'CONTSTART',
           ca_contend      TYPE bapibus20001_appointment_dis-appt_type VALUE 'CONTEND',
           ca_z_data_rich  TYPE bapibus20001_appointment_dis-appt_type VALUE 'Z_DATA_RICH', "ADD GC 24/07/2009
           ca_z_data_prat  TYPE bapibus20001_appointment_dis-appt_type VALUE 'Z_DATA_PRAT', "ADD GC 24/07/2009
           ca_z_data_invio TYPE bapibus20001_appointment_dis-appt_type VALUE 'Z_DATA_INVIO',
           ca_z_start_lav  TYPE bapibus20001_appointment_dis-appt_type VALUE 'Z_START_LAV', "ADD GC 24/07/2009
           ca_z_end_lav    TYPE bapibus20001_appointment_dis-appt_type VALUE 'Z_END_LAV', "ADD GC 24/07/2009
           ca_z_scad_pl    TYPE bapibus20001_appointment_dis-appt_type VALUE 'ZSCAD_PLAFON', "ADD mf 13/08/2015
           ca_can_erogaz   TYPE zca_param-z_group                      VALUE 'CNER'.   "ADD MA 27.09.2010

* Begin AG 04.11.2011
DATA gi_zca_bdm_pddlb TYPE STANDARD TABLE OF zca_bdm_pddlb.
* End   AG 04.11.2011

* -- Dichiarazione Strutture Dati
DATA: va_ts(8)             TYPE c,
      va_filetemp(255)     TYPE c,
      va_fileout(255)      TYPE c,
*105900 ENG INIZIO MODIFICA DEL 29.09.2016
      va_fileout_temp(255),
      ext_temp             TYPE string,
*105900 ENG FINE   MODIFICA DEL 29.09.2016
      va_filelog(255)      TYPE c,
      gv_object_type       TYPE crmd_orderadm_h-object_type,
*      gv_stato_h       TYPE bapibus20001_status_dis-user_stat_proc,    " DEL SC 04/03/2009
*      gv_stato_i       TYPE bapibus20001_status_dis-user_stat_proc,    " DEL SC 04/03/2009
      gv_edw_note          TYPE bapibus20001_text_dis-tdid,
      gv_contratti         TYPE swo_objtyp, " ADD GC 27/07/2009
      va_date_t            TYPE crmd_orderadm_h-created_at,
      gw_tbtco_t           TYPE t_tbtco,
      gw_tbtco_f           TYPE t_tbtco,
      usereid              TYPE usrefus-bname,
      bpartner             TYPE bapibus1006_head-bpartner,

* -- Tabelle Interne
      gt_cronomapping      TYPE t_cronomapping_t,  " ADD MN - 03.11.2015
      gt_cod_contr         TYPE STANDARD TABLE OF zca_ptb_cocontr, "ADD MA 27.09.2010
      gt_can_erogaz        TYPE zca_param_t, "ADD MA 27.09.2010
      gt_edwc              TYPE zca_param_t,
      gt_cnop              TYPE zca_param_t,
      gt_objt              TYPE zca_param_t, "ADD GC 23/07/09
      gt_stah              TYPE zca_param_t, "ADD GC 23/07/09
      gt_stai              TYPE zca_param_t, "ADD GC 23/07/09
* 105900 : gestione dei tipi pos
      gt_tpos              TYPE zca_param_t,
* 105900 : gestione dei tipi pos
* 105900 : INIZIO MODIFICA
      gt_stap              TYPE zca_param_t,
* 105900 : FINE   MODIFICA
* 105900: inizio modifica del 22.09.2016 - tm
      gt_stati_pos         TYPE zca_param_t,
* 105900: fine   modifica del 22.09.2016 - tm
      gt_note              TYPE zca_param_t, "ADD GC 23/07/09
      lt_acp               TYPE zca_param_t, "Modifica RS 26/10/2011
      " Inizio AS 15.05.2012
      gt_type              TYPE zca_param_t,
      gt_prov              TYPE zca_param_t,
      gt_inte              TYPE zca_param_t,
      gt_coin              TYPE zca_param_t,
      gt_priv              TYPE zca_param_t,
      gt_param_item        TYPE zca_param_t,
      gt_tab1              TYPE zca_param_t,
      gt_tab2              TYPE zca_param_t,
      gt_ods               TYPE zca_param_t,
      gt_cont              TYPE zca_param_t,
      gt_cond              TYPE zca_param_t,
      gv_pft_cliente       TYPE zval_par,
      gv_pft_cointestat    TYPE zval_par,
      " Fine   AS 15.05.2012
      gt_customer_i        TYPE STANDARD TABLE OF t_customer_i, "ADD GC 23/07/09
      gt_crm_jcds          TYPE STANDARD TABLE OF crm_jcds,     "ADD GC 23/07/09
      gt_nop_motivo        TYPE STANDARD TABLE OF zca_nop_motivo,
      gt_privacy_tab1      TYPE STANDARD TABLE OF zca_privacy,  " Add AS 17.05.2012
      gt_privacy_tab2      TYPE STANDARD TABLE OF zca_privacy,  " Add AS 17.05.2012
      gt_zmp_addon_prod    TYPE STANDARD TABLE OF zmp_addon_prod,  " Add AS 17.05.2012
      gt_addon_order       TYPE STANDARD TABLE OF zca_addon_order, " Add AS 18.05.2012
      gt_dati_maaf         TYPE STANDARD TABLE OF zca_dati_maaf,
      i_guid               TYPE STANDARD TABLE OF bapibus20001_guid_dis,
      i_appointment        TYPE STANDARD TABLE OF bapibus20001_appointment_dis,
      i_partner            TYPE STANDARD TABLE OF bapibus20001_partner_dis,
      i_header             TYPE STANDARD TABLE OF bapibus20001_header_dis,
      i_status             TYPE STANDARD TABLE OF bapibus20001_status_dis,
* 105900: inizio modifica del 22.09.2016
      i_status_pos         TYPE STANDARD TABLE OF bapibus20001_status_dis,
      l_status_pos         TYPE  bapibus20001_status_dis,
* 105900: fine   modifica del 22.09.2016
      i_text               TYPE STANDARD TABLE OF bapibus20001_text_dis,
      i_item               TYPE STANDARD TABLE OF bapibus20001_item_dis,
      i_schedule_item      TYPE STANDARD TABLE OF bapibus20001_schedlin_item_dis,
      i_product_list       TYPE STANDARD TABLE OF bapibus20001_product_list_dis,
      i_doc_flow           TYPE STANDARD TABLE OF bapibus20001_doc_flow_dis,
      i_products           TYPE STANDARD TABLE OF bapibus20001_products_dis, " Add AS 29.05.2012
      i_prec_doc           TYPE STANDARD TABLE OF t_prec_doc,
*      i_customer_h      TYPE STANDARD TABLE OF t_customer_h,
      i_crm_jcds           TYPE STANDARD TABLE OF t_crm_jcds,
      i_bdm_prev_bp        TYPE STANDARD TABLE OF t_bdm_prev_bp, " add mf 16/09/2011
      i_bdm_contract       TYPE STANDARD TABLE OF t_bdm_contract, " add mf 16/09/2011
      i_leggi_prev_app     TYPE STANDARD TABLE OF t_leggi_prev, "add mf 16/09/2011
      i_leggi_prev         TYPE STANDARD TABLE OF zca_bdm_prev_out, "add mf 12/10/2011
      i_bdm_crif           TYPE STANDARD TABLE OF t_bdm_crif,  "add mf 12/10/2011
      i_order_index        TYPE STANDARD TABLE OF t_index, "add mferrara 10/08/2015
      i_zca_spid_prod      TYPE STANDARD TABLE OF t_zca_spid_prod, "TP 21.04.2016
* 105900 : INIZIO MODIFICA
      gr_stati_e           TYPE RANGE OF crm_jest-stat,
      l_stati_e            TYPE crm_jest-stat,
* 105900 : FINE   MODIFICA
* 105900: inizio modifica del 22.09.2016 - tm
      gr_schema_pos        TYPE RANGE OF tj30-stsma,
      l_schema_pos         LIKE LINE OF gr_schema_pos,
* 105900: fine   modifica del 22.09.2016 - tm
* -- Range
      gr_proc_type         TYPE RANGE OF crmd_orderadm_h-process_type,
      gr_objt              TYPE RANGE OF crmd_orderadm_h-object_type,
      gr_inte              TYPE RANGE OF zmp_addon_prod-field, " Add AS 17.05.2012
      gr_coin              TYPE RANGE OF zmp_addon_prod-field, " Add AS 17.05.2012
      gr_tab1              TYPE RANGE OF zca_privacy-tabella, " Add AS 17.05.2012
      gr_tab2              TYPE RANGE OF zca_privacy-tabella, " Add AS 17.05.2012
      gr_stah              TYPE RANGE OF crm_j_stsma, "ADD GC 23/07/09
      gr_stai              TYPE RANGE OF crm_j_stsma, "ADD GC 23/07/09
      gr_note              TYPE RANGE OF tdid.        "ADD GC 23/07/09

* Begin AG 06.02.2014
* BUNDLE_09
DATA: gt_prmh             TYPE zca_param_t,
      gt_prmi             TYPE zca_param_t,
      gt_ztipo_promo_bun  TYPE STANDARD TABLE OF ztipo_promo_bun,
      gt_zca_cod_promo_bu TYPE STANDARD TABLE OF zca_cod_promo_bu.

CONSTANTS: gc_prmh TYPE zgroup VALUE 'PRMH',
           gc_prmi TYPE zgroup VALUE 'PRMI',
           gc_appl TYPE zappl  VALUE 'ZCAE_EDWHAE_CONTRATTI'.
*           gc_appl TYPE zappl  VALUE 'ZCAE_EDWHAE_PUNTIVENDITA'.

DATA: BEGIN OF gs_guid_header,
        guid32 TYPE sysuuid-c,
        guid16 TYPE sysuuid-x,
      END OF gs_guid_header.
DATA gt_guid_header LIKE STANDARD TABLE OF gs_guid_header.
* End   AG 06.02.2014

* 105900: inizio modifica del 29.09.2016 - eng
DATA: lv_parameters TYPE sxpgcolist-parameters,
      lv_file_new   TYPE string.

DATA lv_line TYPE i.


DATA: file_completo TYPE boolean.
CONSTANTS: c_temp  TYPE string VALUE 'TEMP',
           c_true  TYPE boolean VALUE 'X',
           c_false TYPE boolean VALUE space.
* 105900: fine   modifica del 29.09.2016 - eng

* INIZIO RU 16/10/2018 grandi esercenti
TYPES: BEGIN OF ts_pratiche_figlio,
         ob_id TYPE crmt_object_id_db,
       END OF ts_pratiche_figlio.

TYPES: BEGIN OF ts_pratiche_figlio_guid,
         guid TYPE crmt_object_guid,
       END OF ts_pratiche_figlio_guid.

TYPES: BEGIN OF ts_relazioni,
         guid_pv          TYPE axt_record_id,
         progressivo_item TYPE crmt_item_no,
         figlio           TYPE crmt_object_id_db,
         punto_vendita    TYPE zshop_id,
       END OF ts_relazioni.

TYPES tt_relazioni            TYPE TABLE OF ts_relazioni.
TYPES tt_pratiche_figlio_guid TYPE TABLE OF ts_pratiche_figlio_guid.

DATA: lt_pratiche_figlio TYPE STANDARD TABLE OF ts_pratiche_figlio,
      lt_guid_figli      TYPE STANDARD TABLE OF ts_pratiche_figlio_guid,
      lt_relazioni       TYPE STANDARD TABLE OF ts_relazioni.

* FINE RU 16/10/2018 grandi esercenti

INITIALIZATION.

  PERFORM f_inizializza.

* Begin AG 25.06.2012
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'S_OBJECT-LOW' OR 'S_OBJECT-HIGH'.
        IF r_full IS INITIAL.
          REFRESH s_object[].
          CLEAR s_object.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
* End   AG 25.06.2012

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
