*&----------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_CONTRATTI
*&
*&----------------------------------------------------------------------*
*& -- ID:           NOP_014
*& -- Autore:       Raffaele Frattini
*& -- Data:         13/01/2009
*& -- Descrizione:  Nuova Offerta PMI - Interfaccia EDWAE Contratti
*&----------------------------------------------------------------------*
*& -- Modifiche:    Raffaele Frattini RF
*& -- Data:         13/02/2009
*& -- Descrizione:  Modifica estrazione campo Risultato
*&----------------------------------------------------------------------*
*& -- Modifiche:    Gennaro Carullo GC
*& -- Data:         23/07/2009
*& -- Descrizione:  Modifica tracciati record + aggiunta nuovo tracciato
*&----------------------------------------------------------------------*
*& -- Modifiche:    Raffaele Frattini   RF
*& -- Data:         01/12/2009
*& -- Descrizione:  Aggiunta campi a tracciato di output
*&----------------------------------------------------------------------*
*& -- Modifiche:    Raffaele Frattini   RF
*& -- Data:         14/12/2009
*& -- Descrizione:  Eliminazione Campo USER_ID dal tracciato di Output
*&----------------------------------------------------------------------*
*& -- Modifiche:    Aurora Galeone      AG
*& -- Data:         16/12/2009
*& -- Descrizione:  Modifica logica di estrazione dello stato
*&----------------------------------------------------------------------*
*& -- Modifiche:    Mariassunta Addesse MA
*& -- Data:         27/09/2010
*& -- Descrizione:  Aggiunta campi a tracciato di output (Header e
*& --               Prodotti) per estrazione contratti PTB
*& --               Modifica formata data per invio stringa blank quando
*& --               non valorizzata
*& -- Data:         18/01/2011
*& -- Descrizione:  Aggiunta campi a tracciato di output (Header) per
*& --               estrazione contratti Riconoscimento Forte
*& -- CR SAP:       CWDK915771
*&----------------------------------------------------------------------*
*& -- Modifiche:    Antonio Silvestro AS
*& -- Data:         20/04/2011
*& -- Descrizione:  Modifica campi File
*&----------------------------------------------------------------------*
*& -- Modifiche:    Antonio Silvestro AS
*& -- Data:         11/05/2011
*& -- Descrizione:  Modifica campi File:  REGIONE_RESID
*                                         FRAZIONARIO
*                                         ID_MODULO_MISE
*&----------------------------------------------------------------------*
*& -- Modifiche:    Maria Ferrara
*& -- Data:         16/09/2011
*& -- Descrizione:  Modifica campi File in header
*&----------------------------------------------------------------------*
*& -- Modifiche:    Antonio Silvestro AS
*& -- Data:         15/05/2012
*& -- Descrizione:  Modifica campi File:  nickname(100)
*                                         id_contratto_web(10)
*                                         tipo_conto_origine(4)
*                                         telefono_contatto(30)
*                                         classe_click
*                                         promozione_web
*                   E Valorizzazione di due nuovi file di output:
*                       ATTRIBUTI-DIMENSIONI
*                       CONSENSI PRIVACY CONTRATTI
*&----------------------------------------------------------------------*
*&----------------------------------------------------------------------*
*& -- Modifiche:    Pier Luigi Pontone PLP-01
*& -- Data:         30/12/2012
*& -- Descrizione:  CARTA ROMA CAPITALE
*                   Inserimento nel tipo record HH dei seguenti campi
*                    TIPO_CARTA
*                    RUOLO
*&----------------------------------------------------------------------*
*& -- Modifiche:    Claudia Lariccia CL
*& -- Data:         03/06/2013
*& -- Descrizione:  Integrazione del tracciato per invio info
*&                  Sede di Lavoro per pratiche create
*&                  dal profilo del promotore finanziario
*&----------------------------------------------------------------------*
*&----------------------------------------------------------------------*
*& -- Modifiche:    Manuela Taccoli
*& -- Data:         23/08/2016
*& -- Descrizione:  Inserimento nel tipo record HH di nuovi campi
*&                  CARTE_CREDITO
*&                  CARTE_PAGOBANCOMAT
*&                  CARTE_POSTAMAT
*&                  RICH_FORMAT_CART
*&                  MOD_ACCREDITO
*&                  PRIMO_CONVENZIONAMENTO
*&                  GIA_CONVENZIONATO
*&                  TIPO_ESERCENTE
*&                  STAGIONALE
*&                  PERIODO_APERTURA
*&
*& -- cod. iniziativa: 105900
*&----------------------------------------------------------------------*
*&----------------------------------------------------------------------*
*& -- Modifiche:    Giulio D'Attilio
*& -- Data:         31/03/2017
*& -- Descrizione:  Inserimento nel tipo record HH di nuovi campi per full acquiring e mapping id_univoco con object_id per ZFAC
*& -- cod. iniziativa: 105900
*&----------------------------------------------------------------------*

REPORT  zcae_edwhae_contratti.

TABLES crmd_orderadm_h.
* -- Parametri di input
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta  RADIOBUTTON GROUP gr1             DEFAULT 'X',
           r_full   RADIOBUTTON GROUP gr1,
           p_date_f TYPE crmd_orderadm_h-created_at,
           p_fout   TYPE filename-fileintern          DEFAULT 'ZCRMOUT001_EDWHAECONTRATTI' OBLIGATORY,
           p_flog   TYPE filename-fileintern          DEFAULT 'ZCRMLOG001_EDWHAECONTRATTI' OBLIGATORY,
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
         zz_provenienza	  TYPE crmd_customer_h-zz_provenienza, " Add AS 16.03.2012
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
         zz_codice_uff    TYPE crmd_customer_h-zz_codice_uff , "  Iniziativa 106592 - Nuovi campi MAAF
         zz_sede_lav      TYPE crmd_customer_h-zz_sede_lav, "ADD CL - 03.06.2013 - Delete CL 13.06.2013 "Ripristino 21/11
         "Inizio mferrara NOP_014 - 10/08/2015
         zz_totale_prezzo TYPE crmd_customer_h-zz_totale_prezzo,
         zz_durata_anni   TYPE crmd_customer_h-zz_durata_anni,
         "Fine mferrara NOP_014 - 10/08/2015

         zz_tipologia     TYPE crmd_customer_h-zz_tipologia,  "TP 21.04.2016
       END OF t_customer_h.

* 105900 : Inizio modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file
TYPES: BEGIN OF t_dati_agg_fa,
         parent_id        TYPE zca_dati_agg_acq-parent_id,
         zz_mod_pag       TYPE zca_dati_agg_acq-zz_mod_pag,
         zz_visa_maestro  TYPE zca_dati_agg_acq-zz_visa_maestro,
         zz_pagobancomat  TYPE zca_dati_agg_acq-zz_pagobancomat,
         zz_postamat      TYPE zca_dati_agg_acq-zz_postamat,
         zz_rend_cart     TYPE zca_dati_agg_acq-zz_rend_cart,
         zz_strum_regolam TYPE zca_dati_agg_acq-zz_strum_regolam,
         zz_liv_acc_add   TYPE zca_dati_agg_acq-zz_liv_acc_add,
         zz_iban_acc      TYPE zca_dati_agg_acq-zz_iban_acc,
         zz_grande_eserc  TYPE zca_dati_agg_acq-zz_grande_eserc,
         zz_mot_reinoltro TYPE zca_dati_agg_acq-zz_mot_reinoltro, "RU 13.09.2019 11:27:29

* 105900: ASTERISCATO IN ATTESA DEL PASSAGGIO DI FA FASE 2 - INIZIO
*         zz_bus_eserc_con TYPE zca_dati_agg_acq-zz_bus_eserc_con,
*         zz_bus_eserc_tip TYPE zca_dati_agg_acq-zz_bus_eserc_tip,
*         zz_bus_eserc_sta TYPE zca_dati_agg_acq-zz_bus_eserc_sta,
*         zz_bus_eserc_per TYPE zca_dati_agg_acq-zz_bus_eserc_per,
* 105900: ASTERISCATO IN ATTESA DEL PASSAGGIO DI FA FASE 2 - FINE
       END OF t_dati_agg_fa.
* 105900 : Fine   modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file



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

* Iniziativa 106592 - Estrazione campi MAAF - Start
         maaf_mail_fatt(241)              TYPE c, " Indir. e-mail (di fatturazione)
*         maaf_cod_uff(6)                  TYPE c, " Codice Ufficio " Comm. MN - 29.10.18
         maaf_cod_uff(7)                  TYPE c, " Codice Ufficio  " Mod. MN - 29.10.18
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
* 105900 : Inizio modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file
         carte_credito(1)                 TYPE c,
         carte_pagobancomat(1)            TYPE c,
         carte_postamat(1)                TYPE c,
         rich_format_cart(1)              TYPE c,
         mod_accredito(1)                 TYPE c,
         primo_convenzionamento(1)        TYPE c,
         gia_convenzionato(1)             TYPE c,
         tipo_esercente(1)                TYPE c,
         stagionale(1)                    TYPE c,
         periodo_apertura(1)              TYPE c,
* 105900 : Fine   modifica del 23.08.2016 -  TM
         zz_strum_regolam(2)              TYPE c, "Strumento di regolamento Full Acquiring
         zz_liv_acc_add(2)                TYPE c, "Livello accredito/addebito Full Acquiring
         zz_iban_acc(27)                  TYPE c, "IBAN accredito Full Acquiring
         sede_lav(2)                      TYPE c, "ADD CL - 03.06.2013 - Delete CL - 13.06.2013 "Ripristino 21.11.2017 (campo spostato in coda al record Header)
       END OF t_header.

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
" Begin CP 22.02.2017
TYPES: BEGIN OF t_idunivoco_crono,
         guid      TYPE crmd_orderadm_h-guid,
         object_id TYPE crmd_orderadm_h-object_id,
       END OF t_idunivoco_crono,
       t_idunivoco_crono_t TYPE STANDARD TABLE OF t_idunivoco_crono.

" End CP 22.02.2017
* Begin AG 04.11.2011
CONSTANTS: gc_tipo_tasso  TYPE zbdm_cod_attrib VALUE 'TIPO_TASSO',
           gc_durata      TYPE zbdm_cod_attrib VALUE 'DURATA',
           gc_periodicita TYPE zbdm_cod_attrib VALUE 'PERIODICITA_RATA'. " Mod AG 21.11.2011
* End   AG 04.11.2011


*105900 ENG INIZIO MODIFICA DEL 29.09.2016
DATA:      va_fileout_temp(255),
           ext_temp             TYPE string.
DATA: lv_parameters TYPE sxpgcolist-parameters,
      lv_file_new   TYPE string.

DATA lv_line TYPE i.


DATA: file_completo TYPE boolean.
CONSTANTS: c_temp  TYPE string VALUE 'TEMP',
           c_true  TYPE boolean VALUE 'X',
           c_false TYPE boolean VALUE space.

*105900 ENG FINE   MODIFICA DEL 29.09.2016


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
           ca_fp(2)        TYPE c                                      VALUE 'FP',
           ca_ms(2)        TYPE c                                      VALUE 'MS',
           ca_mp(2)        TYPE c                                      VALUE 'MP',
           ca_r            TYPE tbtco-status                           VALUE 'R',
           ca_f            TYPE tbtco-status                           VALUE 'F',
           ca_z_appl       TYPE zca_param-z_appl                       VALUE 'ZCAE_EDWHAE_CONTRATTI',
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
           ca_coin         TYPE zgroup                                 VALUE 'COIN',                " Add AS 15.05.2012
           ca_pft_cliente  TYPE znome_par                              VALUE 'PFT_CLIENTE',         " Add AS 15.05.2012
           ca_pft_cointest TYPE znome_par                              VALUE 'PFT_COINTESTAT',      " Add AS 15.05.2012
           ca_file_temp    TYPE filename-fileintern                    VALUE 'ZCRMTEMP001_EDWHAECONTRATTI',
           ca_jobname      TYPE tbtco-jobname                          VALUE 'ZCAE_EDWHAE_CONTRATTI',
           ca_edwc         TYPE zca_param-z_group                      VALUE 'EDWC',
           ca_cnop         TYPE zca_param-z_group                      VALUE 'CNOP',
           ca_objt         TYPE zca_param-z_group                      VALUE 'OBJT', "ADD GC 23/07/09
           ca_stah         TYPE zca_param-z_group                      VALUE 'STAH', "ADD GC 23/07/09
           ca_stai         TYPE zca_param-z_group                      VALUE 'STAI', "ADD GC 23/07/09
           ca_note         TYPE zca_param-z_group                      VALUE 'NOTE', "ADD GC 23/07/09
* 105900: inizio modifica del 05.09.2016 - tm
           ca_zfac         TYPE zca_param-z_group                      VALUE 'ZFAC',
* 105900: fine   modifica del 05.09.2016 - tm
           ca_object_type  TYPE zca_param-z_nome_par                   VALUE 'OBJECT_TYPE',
           ca_acp          TYPE zgroup                                 VALUE 'ACP',
           ca_stato_h      TYPE zca_param-z_nome_par                   VALUE 'STATO_H',
           ca_stato_i      TYPE zca_param-z_nome_par                   VALUE 'STATO_I',
           ca_edw_note     TYPE zca_param-z_nome_par                   VALUE 'EDW_NOTE',
           ca_contratti    TYPE zca_param-z_nome_par                   VALUE 'CONTRATTI',
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
DATA: va_ts(8)           TYPE c,
      va_filetemp(255)   TYPE c,
      va_fileout(255)    TYPE c,
      va_filelog(255)    TYPE c,
      gv_object_type     TYPE crmd_orderadm_h-object_type,
*      gv_stato_h       TYPE bapibus20001_status_dis-user_stat_proc,    " DEL SC 04/03/2009
*      gv_stato_i       TYPE bapibus20001_status_dis-user_stat_proc,    " DEL SC 04/03/2009
      gv_edw_note        TYPE bapibus20001_text_dis-tdid,
      gv_contratti       TYPE swo_objtyp, " ADD GC 27/07/2009
      va_date_t          TYPE crmd_orderadm_h-created_at,
      gw_tbtco_t         TYPE t_tbtco,
      gw_tbtco_f         TYPE t_tbtco,
      usereid            TYPE usrefus-bname,
      bpartner           TYPE bapibus1006_head-bpartner,

* -- Tabelle Interne
      gt_cronomapping    TYPE t_cronomapping_t,  " ADD MN - 03.11.2015
      gt_idunivoco_crono TYPE t_idunivoco_crono_t, " Add CP 22.02.2017
      gt_cod_contr       TYPE STANDARD TABLE OF zca_ptb_cocontr, "ADD MA 27.09.2010
      gt_can_erogaz      TYPE zca_param_t, "ADD MA 27.09.2010
      gt_edwc            TYPE zca_param_t,
      gt_cnop            TYPE zca_param_t,
      gt_objt            TYPE zca_param_t, "ADD GC 23/07/09
      gt_stah            TYPE zca_param_t, "ADD GC 23/07/09
      gt_stai            TYPE zca_param_t, "ADD GC 23/07/09
      gt_note            TYPE zca_param_t, "ADD GC 23/07/09
      lt_acp             TYPE zca_param_t, "Modifica RS 26/10/2011
      " Inizio AS 15.05.2012
      gt_type            TYPE zca_param_t,
      gt_prov            TYPE zca_param_t,
      gt_inte            TYPE zca_param_t,
      gt_coin            TYPE zca_param_t,
      gt_priv            TYPE zca_param_t,
      gt_param_item      TYPE zca_param_t,
      gt_tab1            TYPE zca_param_t,
      gt_tab2            TYPE zca_param_t,
      gt_ods             TYPE zca_param_t,
      gt_cont            TYPE zca_param_t,
      gt_cond            TYPE zca_param_t,
* 105900: inizio modifica del 05.09.2016 - tm
      gt_zfac            TYPE zca_param_t,
* 105900: fine   modifica del 05.09.2016 - tm
      gv_pft_cliente     TYPE zval_par,
      gv_pft_cointestat  TYPE zval_par,
      " Fine   AS 15.05.2012
      gt_customer_i      TYPE STANDARD TABLE OF t_customer_i, "ADD GC 23/07/09
      gt_crm_jcds        TYPE STANDARD TABLE OF crm_jcds,     "ADD GC 23/07/09
      gt_nop_motivo      TYPE STANDARD TABLE OF zca_nop_motivo,
      gt_privacy_tab1    TYPE STANDARD TABLE OF zca_privacy,  " Add AS 17.05.2012
      gt_privacy_tab2    TYPE STANDARD TABLE OF zca_privacy,  " Add AS 17.05.2012
      gt_zmp_addon_prod  TYPE STANDARD TABLE OF zmp_addon_prod,  " Add AS 17.05.2012
      gt_addon_order     TYPE STANDARD TABLE OF zca_addon_order, " Add AS 18.05.2012
      gt_dati_maaf       TYPE STANDARD TABLE OF zca_dati_maaf,
      i_guid             TYPE STANDARD TABLE OF bapibus20001_guid_dis,
      i_appointment      TYPE STANDARD TABLE OF bapibus20001_appointment_dis,
      i_partner          TYPE STANDARD TABLE OF bapibus20001_partner_dis,
      i_header           TYPE STANDARD TABLE OF bapibus20001_header_dis,
      i_status           TYPE STANDARD TABLE OF bapibus20001_status_dis,
      i_text             TYPE STANDARD TABLE OF bapibus20001_text_dis,
      i_item             TYPE STANDARD TABLE OF bapibus20001_item_dis,
      i_schedule_item    TYPE STANDARD TABLE OF bapibus20001_schedlin_item_dis,
      i_product_list     TYPE STANDARD TABLE OF bapibus20001_product_list_dis,
      i_doc_flow         TYPE STANDARD TABLE OF bapibus20001_doc_flow_dis,
      i_products         TYPE STANDARD TABLE OF bapibus20001_products_dis, " Add AS 29.05.2012
      i_prec_doc         TYPE STANDARD TABLE OF t_prec_doc,
      i_customer_h       TYPE STANDARD TABLE OF t_customer_h,
      i_crm_jcds         TYPE STANDARD TABLE OF t_crm_jcds,
      i_bdm_prev_bp      TYPE STANDARD TABLE OF t_bdm_prev_bp, " add mf 16/09/2011
      i_bdm_contract     TYPE STANDARD TABLE OF t_bdm_contract, " add mf 16/09/2011
      i_leggi_prev_app   TYPE STANDARD TABLE OF t_leggi_prev, "add mf 16/09/2011
      i_leggi_prev       TYPE STANDARD TABLE OF zca_bdm_prev_out, "add mf 12/10/2011
      i_bdm_crif         TYPE STANDARD TABLE OF t_bdm_crif,  "add mf 12/10/2011
      i_order_index      TYPE STANDARD TABLE OF t_index, "add mferrara 10/08/2015
      i_zca_spid_prod    TYPE STANDARD TABLE OF t_zca_spid_prod, "TP 21.04.2016
*  105900 : Inizio modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file
      i_dati_agg_fa      TYPE STANDARD TABLE OF t_dati_agg_fa,
*  105900 : Fine modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file

* -- Range
      gr_proc_type       TYPE RANGE OF crmd_orderadm_h-process_type,
      gr_objt            TYPE RANGE OF crmd_orderadm_h-object_type,
      gr_inte            TYPE RANGE OF zmp_addon_prod-field, " Add AS 17.05.2012
      gr_coin            TYPE RANGE OF zmp_addon_prod-field, " Add AS 17.05.2012
      gr_tab1            TYPE RANGE OF zca_privacy-tabella, " Add AS 17.05.2012
      gr_tab2            TYPE RANGE OF zca_privacy-tabella, " Add AS 17.05.2012
      gr_stah            TYPE RANGE OF crm_j_stsma, "ADD GC 23/07/09
      gr_stai            TYPE RANGE OF crm_j_stsma, "ADD GC 23/07/09
      gr_note            TYPE RANGE OF tdid.        "ADD GC 23/07/09

* 105900 : inizio modifica del 05.09.2016 - tm
DATA: gr_zfac TYPE RANGE OF crmt_product_id,
      l_zfac  LIKE LINE OF gr_zfac.
* 105900:  fine   modifica del 05.09.2016 - tm

* Begin AG 06.02.2014
* BUNDLE_09
DATA: gt_prmh             TYPE zca_param_t,
      gt_prmi             TYPE zca_param_t,
      gt_ztipo_promo_bun  TYPE STANDARD TABLE OF ztipo_promo_bun,
      gt_zca_cod_promo_bu TYPE STANDARD TABLE OF zca_cod_promo_bu.

CONSTANTS: gc_prmh TYPE zgroup VALUE 'PRMH',
           gc_prmi TYPE zgroup VALUE 'PRMI',
           gc_appl TYPE zappl  VALUE 'ZCAE_EDWHAE_CONTRATTI'.

DATA: BEGIN OF gs_guid_header,
        guid32 TYPE sysuuid-c,
        guid16 TYPE sysuuid-x,
      END OF gs_guid_header.
DATA gt_guid_header LIKE STANDARD TABLE OF gs_guid_header.
* End   AG 06.02.2014
" Inizio Mod. MN - Gestione temp. codice ufficio - 22.11.2018
TYPES: BEGIN OF t_but000,
         partner TYPE but000-partner,
         bpkind  TYPE but000-bpkind,
       END OF t_but000,
       t_but000_t  TYPE STANDARD TABLE OF t_but000,
       t_partner_t TYPE STANDARD TABLE OF bapibus20001_partner_dis.
DATA gt_bpkind TYPE STANDARD TABLE OF t_but000.
" Fine Mod. MN - Gestione temp. codice ufficio - 22.11.2018

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

START-OF-SELECTION.

* -- Estrazione Parametri da ZCA_PARAM
  PERFORM get_param.

* -- SET Global Range
  PERFORM f_set_range.

* -- Estrazione Tipologiche
  PERFORM f_estrai_tipologiche.

* Estrazione da GT_PRIVACY
  PERFORM f_estrai_privacy.

* -- Inizializza il timestamp da utilizzare per la creazione dei file
  va_ts = sy-datum.

* -- Recupero file di output
  PERFORM recupera_file USING p_fout va_ts
                        CHANGING va_fileout.

* -- Recupero file di log
  PERFORM recupera_file USING p_flog va_ts
                        CHANGING va_filelog.

* -- Recupero file di Appoggio
  PERFORM recupera_file USING ca_file_temp va_ts
                        CHANGING va_filetemp.

* -- Apre i file di output e log
  PERFORM apri_file.

* -- Elaborazioni dal DB
  PERFORM estrazioni.

* -- Chiude i file di output e log
  PERFORM chiudi_file.


* 105900: inizio modifica del 29.09.2016 - eng
  DESCRIBE TABLE i_guid LINES lv_line.

  " Rinomino il file in caso di scrittura teminata correttamente
  IF file_completo IS NOT INITIAL.
    IF lv_line NE 0.
      PERFORM f_rinomina_file.
    ENDIF.
  ENDIF.
*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_ACTIVITY_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING p_logic TYPE filename-fileintern
                         p_param TYPE c
                CHANGING p_fname TYPE c.


  DATA: lv_file  TYPE string,
        lv_file2 TYPE string,
        lv_len   TYPE i,
        lv_len2  TYPE i.
* 105900: inizio modifica del 29.09.2016 - eng
  DATA: lv_file_temp TYPE string.
* 105900: fine   modifica del 29.09.2016 - eng

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_logic
      parameter_1      = p_param
      parameter_2      = p_ind
    IMPORTING
      file_name        = lv_file
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e02 p_logic text-e03 space.
  ENDIF.


  IF p_ind IS INITIAL.

    lv_len = strlen( lv_file ).
    lv_len = lv_len - 5.
    lv_len2 = lv_len + 1.

    CONCATENATE lv_file(lv_len) lv_file+lv_len2 INTO p_fname.

  ELSE.

    p_fname = lv_file.

  ENDIF.


* 105900: inizio modifica del 29.09.2016 - eng
* gestione nome temporaneo del file
  lv_file_temp = lv_file.

  SPLIT  lv_file_temp AT '.' INTO  va_fileout_temp  ext_temp.

  CONCATENATE va_fileout_temp c_temp INTO va_fileout_temp SEPARATED BY '_'.

  CONCATENATE va_fileout_temp ext_temp INTO va_fileout_temp SEPARATED BY '.'.
* 105900: inizio modifica del 29.09.2016 - eng
ENDFORM.                    " recupera_file
*&---------------------------------------------------------------------*
*&      Form  apri_file
*&---------------------------------------------------------------------*
*       Apre i file da generare
*----------------------------------------------------------------------*
FORM apri_file.
* 105900: inizio modifica del 29.09.2016 - eng
*  OPEN DATASET va_fileout FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  OPEN DATASET va_fileout_temp FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
* 105900: fine modifica del 29.09.2016 - eng
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.


  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    CLOSE DATASET va_fileout.
    MESSAGE e208(00) WITH text-e05.
  ENDIF.

  OPEN DATASET va_filetemp FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e26.
  ENDIF.

ENDFORM.                    " apri_file
*&---------------------------------------------------------------------*
*&      Form  chiudi_file
*&---------------------------------------------------------------------*
*       Chiude i file generati
*----------------------------------------------------------------------*
FORM chiudi_file .

* 105900: inizio modifica del 29.09.2016 - eng.
*  CLOSE DATASET: va_fileout, va_filelog.
  CLOSE DATASET:  va_filelog.

  CLOSE DATASET va_fileout_temp.

  IF sy-subrc IS INITIAL.
    file_completo = c_true.
  ENDIF.
* 105900: fine modifica del 29.09.2016 - eng
ENDFORM.                    " chiudi_file
*&---------------------------------------------------------------------*
*&      Form  estrazioni
*&---------------------------------------------------------------------*
*       Estrae i record dal DB
*----------------------------------------------------------------------*
FORM estrazioni.

  DATA: lv_guid32 TYPE sysuuid-c,
        lv_cont   TYPE i,
        lw_guid   LIKE LINE OF i_guid.

  CASE ca_x.
*   -- Estrazioni FULL
    WHEN r_full.
      PERFORM select_full.

*   -- Estrazioni DELTA
    WHEN r_delta.
      PERFORM select_delta.

    WHEN OTHERS.
  ENDCASE.

  CLOSE DATASET va_filetemp.

  OPEN DATASET va_filetemp FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    MESSAGE e208(00) WITH text-e27.
  ENDIF.

  REFRESH i_guid.
  lv_cont = 0.
  DO.

    READ DATASET va_filetemp INTO lv_guid32.
    IF NOT sy-subrc IS INITIAL.
      EXIT.
    ENDIF.

    CLEAR lw_guid.
    lw_guid-guid = lv_guid32.
    APPEND lw_guid TO i_guid.
    ADD 1 TO lv_cont.

    IF lv_cont EQ p_psize.

      PERFORM call_bapi_getdetailmul.
      PERFORM estrai_dati_preventivo.
      PERFORM elabora.
      PERFORM nettoyer_tout.

      CLEAR lv_cont.
      REFRESH i_guid.

    ENDIF.

  ENDDO.

  CLOSE DATASET va_filetemp.
  DELETE DATASET va_filetemp.

  IF NOT i_guid[] IS INITIAL.
    PERFORM call_bapi_getdetailmul.
    PERFORM estrai_dati_preventivo.
    PERFORM elabora.
  ENDIF.

ENDFORM.                    " estrazioni
*&---------------------------------------------------------------------*
*&      Form  get_param
*&---------------------------------------------------------------------*
*       Recupero dei parametri da utilizzare per le estrazioni
*----------------------------------------------------------------------*
FORM get_param.

  DATA: lv_val_par TYPE zca_param-z_val_par,
        lt_return  TYPE bapiret2_t.      "ADD MA 27.10.2010


  "Inizio modifiche - GC 23.07.2009 17:13:57
  DATA: lr_stah_line LIKE LINE OF gr_stah,
        lr_stai_line LIKE LINE OF gr_stai,
        lr_note_line LIKE LINE OF gr_note.

  FIELD-SYMBOLS: <fs_param> TYPE zca_param.
  "Fine   modifiche - GC 23.07.2009 17:13:57

  PERFORM read_group_param USING ca_edwc ca_z_appl CHANGING gt_edwc.
  PERFORM read_group_param USING ca_cnop ca_z_appl CHANGING gt_cnop.

  "Inizio modifiche - GC 23.07.2009 12:12:46
  PERFORM read_group_param USING ca_objt ca_z_appl CHANGING gt_objt.
  PERFORM read_group_param USING ca_note ca_z_appl CHANGING gt_note.
  PERFORM read_group_param USING ca_stah ca_z_appl CHANGING gt_stah.
  PERFORM read_group_param USING ca_stai ca_z_appl CHANGING gt_stai.

*Inizio modifica RS 26/10/2011
  PERFORM read_group_param USING ca_acp ca_z_appl CHANGING lt_acp.
*Fine modifica RS 26/10/2011

  "ADD MA 27.10.2010 Estrazione datti contratti PTB
  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = ca_can_erogaz
      i_z_appl = ca_z_appl
    TABLES
      param    = gt_can_erogaz
      return   = lt_return.
  "END ADD MA 27.10.2010 Estrazione datti contratti PTB

  CLEAR lr_stah_line.
  UNASSIGN <fs_param>.
  LOOP AT gt_stah ASSIGNING <fs_param>.
    lr_stah_line-sign   = ca_i.
    lr_stah_line-option = ca_eq.
    lr_stah_line-low    = <fs_param>-z_val_par.
    APPEND lr_stah_line TO gr_stah.
  ENDLOOP.

  CLEAR lr_note_line.
  UNASSIGN <fs_param>.
  LOOP AT gt_note ASSIGNING <fs_param>.
    lr_note_line-sign   = ca_i.
    lr_note_line-option = ca_eq.
    lr_note_line-low    = <fs_param>-z_val_par.
    APPEND lr_note_line TO gr_note.
  ENDLOOP.

  CLEAR lr_stai_line.
  UNASSIGN <fs_param>.
  LOOP AT gt_stai ASSIGNING <fs_param>.
    lr_stai_line-sign   = ca_i.
    lr_stai_line-option = ca_eq.
    lr_stai_line-low    = <fs_param>-z_val_par.
    APPEND lr_stai_line TO gr_stai.
  ENDLOOP.
  "Fine   modifiche - GC 23.07.2009 12:12:46

  "Inizio modifiche - GC 27.07.2009 09:38:18
  CLEAR: gv_contratti, lv_val_par.
  PERFORM read_param USING ca_contratti ca_z_appl CHANGING lv_val_par.
  gv_contratti = lv_val_par.
  "Fine   modifiche - GC 27.07.2009 09:38:18


* -- Recupero dei singoli parametri
  CLEAR: gv_object_type, lv_val_par.
  PERFORM read_param USING ca_object_type ca_z_appl CHANGING lv_val_par.
  gv_object_type = lv_val_par.

  " DEL SC 04/03/2009 Inizio

*  CLEAR: gv_stato_h, lv_val_par.
*  PERFORM read_param USING ca_stato_h ca_z_appl CHANGING lv_val_par.
*  gv_stato_h = lv_val_par.
*
*  CLEAR: gv_stato_i, lv_val_par.
*  PERFORM read_param USING ca_stato_i ca_z_appl CHANGING lv_val_par.
*  gv_stato_i = lv_val_par.

  " DEL SC 04/03/2009 Fine

  CLEAR: gv_edw_note, lv_val_par.
  PERFORM read_param USING ca_edw_note ca_z_appl CHANGING lv_val_par.
  gv_edw_note = lv_val_par.


  " Inizio AS 15.05.2012
*----------------------
* ANAG_03
*----------------------                  appl
  CLEAR: gv_pft_cliente,
         gv_pft_cointestat.
  REFRESH: gt_type,
           gt_prov,
           gt_inte,
           gt_coin,
           gt_priv,
           gt_tab1,
           gt_tab2,
           gt_ods,
           gt_param_item,
           gt_cont,
           gt_cond.

  PERFORM read_group_param USING ca_type          ca_crmi_ewdh  CHANGING gt_type.
  PERFORM read_group_param USING ca_prov          ca_crmi_ewdh  CHANGING gt_prov.
  PERFORM read_group_param USING ca_inte          ca_edwh_int   CHANGING gt_inte.
  PERFORM read_group_param USING ca_coin          ca_edwh_coint CHANGING gt_coin.
  PERFORM read_group_param USING ca_priv          ca_z_appl     CHANGING gt_priv.
  PERFORM read_group_param USING ca_tab1          ca_z_appl     CHANGING gt_tab1.
  PERFORM read_group_param USING ca_tab2          ca_z_appl     CHANGING gt_tab2.
  PERFORM read_group_param USING ca_ods           ca_z_appl     CHANGING gt_ods.
  PERFORM read_group_param USING ca_cont          ca_z_appl     CHANGING gt_cont.
  PERFORM read_param       USING ca_pft_cliente   ca_nor_conf   CHANGING gv_pft_cliente.
  PERFORM read_param       USING ca_pft_cointest  ca_nor_conf   CHANGING gv_pft_cointestat.
  PERFORM read_group_param USING ca_cond          ca_z_appl     CHANGING gt_cond.
  PERFORM read_group_param USING ca_item          ca_z_appl     CHANGING gt_param_item.


  " Fine   AS 15.05.2012


* Begin AG 06.02.2014
* BUNDLE_09
  REFRESH: gt_prmh[], gt_prmi[].
  PERFORM read_group_param_no_err USING gc_prmh gc_appl CHANGING gt_prmh.
  PERFORM read_group_param_no_err USING gc_prmi gc_appl CHANGING gt_prmi.
* End   AG 06.02.2014


* 105900: inizio modifica del 05.09.2016 - tm
  PERFORM read_group_param USING ca_zfac ca_z_appl CHANGING gt_zfac.

* 105900: fine   modifica del 05.09.2016 - tm
ENDFORM.                    " get_param
*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_GROUP_PARAM, e costruisce un range con
*       i valori estratti
*----------------------------------------------------------------------*
FORM read_group_param USING p_gruppo TYPE zca_param-z_group
                            p_z_appl TYPE zca_param-z_appl
                   CHANGING pt_param TYPE zca_param_t.

  DATA lt_return TYPE bapiret2_t.
  REFRESH: pt_param,
           lt_return.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_gruppo
      i_z_appl = p_z_appl
    TABLES
      param    = pt_param
      return   = lt_return.

  DELETE lt_return WHERE type NE ca_a AND
                         type NE ca_e.
  IF lt_return[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e12 p_gruppo space space.
  ENDIF.

ENDFORM.                    " read_group_param

*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_GROUP_PARAM, e costruisce un range con
*       i valori estratti
*----------------------------------------------------------------------*
FORM read_group_param_no_err USING p_gruppo TYPE zca_param-z_group
                                   p_z_appl TYPE zca_param-z_appl
                          CHANGING pt_param TYPE zca_param_t.

  DATA lt_return TYPE bapiret2_t.
  REFRESH: pt_param,
           lt_return.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_gruppo
      i_z_appl = p_z_appl
    TABLES
      param    = pt_param
      return   = lt_return.

ENDFORM.                    " read_group_param

*&---------------------------------------------------------------------*
*&      Form  read_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_PARAM
*----------------------------------------------------------------------*
FORM read_param USING p_name_par  TYPE zca_param-z_nome_par
                      p_z_appl    TYPE zca_param-z_appl
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

ENDFORM.                    " read_param
*&---------------------------------------------------------------------*
*&      Form  f_inizializza
*&---------------------------------------------------------------------*
*    Inizializza Strutture Dati
*----------------------------------------------------------------------*
FORM f_inizializza.

  CLEAR: va_ts,
         va_fileout,
         va_filelog,
         va_filetemp,
         gv_object_type,
         "gv_stato_h,       " DEL SC 04/03/2009
         "gv_stato_i,       " DEL SC 04/03/2009
         gv_edw_note,
         va_date_t,
         gw_tbtco_t,
         gw_tbtco_f.

  REFRESH: gt_edwc,
           gt_cnop,
           i_guid,
           i_appointment,
           i_partner,
           i_status,
           i_text,
           i_item,
           i_schedule_item,
           i_product_list,
           i_doc_flow,
           i_prec_doc,
           i_header,
           i_customer_h,
           i_crm_jcds,
           i_order_index,"add mferrara 10/08/2015
           gr_proc_type,
           gt_nop_motivo,     " RF ADD 13/02/2009
           gt_can_erogaz.     " ADD MA 27.10.2010

ENDFORM.                    " f_inizializza
*&---------------------------------------------------------------------*
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full.

  DATA: lt_guid TYPE STANDARD TABLE OF t_guid16,
        lv_line TYPE sysuuid-c.
  FIELD-SYMBOLS: <fs_guid> TYPE t_guid16.

* -- Valorizzazione Range per Tipi Documento
  DATA: lr_ptype_line LIKE LINE OF gr_proc_type,
        lr_objt_line  LIKE LINE OF gr_objt.
  FIELD-SYMBOLS: <fs_param> TYPE zca_param.

  IF s_ptype[] IS INITIAL.
    CLEAR lr_ptype_line.
    LOOP AT gt_edwc ASSIGNING <fs_param>.
      lr_ptype_line-sign   = ca_i.
      lr_ptype_line-option = ca_eq.
      lr_ptype_line-low    = <fs_param>-z_val_par.
      APPEND lr_ptype_line TO gr_proc_type.
    ENDLOOP.
  ELSE.
    gr_proc_type[] = s_ptype[].
  ENDIF.


  "Inizio modifiche - GC 23.07.2009 12:17:09
  CLEAR lr_objt_line.
  LOOP AT gt_objt ASSIGNING <fs_param>.
    lr_objt_line-sign   = ca_i.
    lr_objt_line-option = ca_eq.
    lr_objt_line-low    = <fs_param>-z_val_par.
    APPEND lr_objt_line TO gr_objt.
  ENDLOOP.
  "Fine   modifiche - GC 23.07.2009 12:17:09


  SELECT guid FROM crmd_orderadm_h
    INTO TABLE lt_guid
    PACKAGE SIZE p_psize
    WHERE object_id    IN s_object " Mod AG 25.06.2012
      AND process_type IN gr_proc_type
      AND object_type  IN gr_objt.     "ADD GC 27/07/2009

    CLEAR lv_line.
    LOOP AT lt_guid ASSIGNING <fs_guid>.
      PERFORM trascod_guid_16_32 USING <fs_guid>-guid
                              CHANGING lv_line.
      TRANSFER lv_line TO va_filetemp.
    ENDLOOP.

  ENDSELECT.

ENDFORM.                    " select_full
*&---------------------------------------------------------------------*
*&      Form  select_delta
*&---------------------------------------------------------------------*
*       Estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_delta.

  DATA: lt_guid TYPE STANDARD TABLE OF t_guid16,
        lv_line TYPE sysuuid-c.

  FIELD-SYMBOLS: <fs_guid> TYPE t_guid16.

  DATA: lr_ptype_line LIKE LINE OF gr_proc_type,
        lr_objt_line  LIKE LINE OF gr_objt.


  FIELD-SYMBOLS: <fs_param> TYPE zca_param.

  PERFORM get_date_time_to.
  PERFORM get_date_time_from.

* -- Valorizzazione Range con Tipi Documento
  CLEAR lr_ptype_line.
  LOOP AT gt_edwc ASSIGNING <fs_param>.
    lr_ptype_line-sign   = ca_i.
    lr_ptype_line-option = ca_eq.
    lr_ptype_line-low    = <fs_param>-z_val_par.
    APPEND lr_ptype_line TO gr_proc_type.
  ENDLOOP.

  "Inizio modifiche - GC 23.07.2009 12:17:09
  CLEAR lr_objt_line.
  LOOP AT gt_objt ASSIGNING <fs_param>.
    lr_objt_line-sign   = ca_i.
    lr_objt_line-option = ca_eq.
    lr_objt_line-low    = <fs_param>-z_val_par.
    APPEND lr_objt_line TO gr_objt.
  ENDLOOP.
  "Fine   modifiche - GC 23.07.2009 12:17:09

  SELECT guid FROM crmd_orderadm_h
    INTO TABLE lt_guid
    PACKAGE SIZE p_psize
    WHERE process_type IN gr_proc_type
       AND ( ( created_at GE p_date_f AND created_at LE va_date_t )
          OR ( changed_at GE p_date_f AND changed_at LE va_date_t ) )
       AND object_type  IN gr_objt.         "ADD GC 23/07/09
*      AND object_type  EQ gv_object_type.  "DEL GC 23/07/09

    CLEAR lv_line.
    LOOP AT lt_guid ASSIGNING <fs_guid>.
      PERFORM trascod_guid_16_32 USING <fs_guid>-guid
                              CHANGING lv_line.
      TRANSFER lv_line TO va_filetemp.
    ENDLOOP.

  ENDSELECT.

ENDFORM.                    " select_delta
*&---------------------------------------------------------------------*
*&      Form  get_date_time_to
*&---------------------------------------------------------------------*
*      Recupera il campo DATE_TO
*----------------------------------------------------------------------*
FORM get_date_time_to.

* -- Il record esiste solo se il programma è stato lanciato in batch
  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco UP TO 1 ROWS
    INTO gw_tbtco_t
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e06 text-e07 text-e08 space.
  ELSE.
    PERFORM trascod_data USING gw_tbtco_t-sdlstrtdt gw_tbtco_t-sdlstrttm
                         CHANGING va_date_t.
  ENDIF.

ENDFORM.                    " get_date_time_to
*&---------------------------------------------------------------------*
*&      Form  trascod_data
*&---------------------------------------------------------------------*
*       Trascodifica due campi DATA e ORA in un campo TIMESTAMP
*----------------------------------------------------------------------*
FORM trascod_data USING p_datum TYPE sy-datum
                        p_uzeit TYPE sy-uzeit
               CHANGING p_ts    TYPE crmd_orderadm_h-created_at.
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
*&      Form  get_date_time_from
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_FROM
*----------------------------------------------------------------------*
FORM get_date_time_from .
  DATA: lt_tbtco_f LIKE STANDARD TABLE OF gw_tbtco_f.

  IF p_date_f IS INITIAL.

    SELECT jobname jobcount sdlstrtdt sdlstrttm
           status FROM tbtco
      INTO TABLE lt_tbtco_f
      WHERE jobname EQ ca_jobname AND
            status  EQ ca_f.

    IF sy-subrc IS NOT INITIAL.
      PERFORM chiudi_file.
      MESSAGE e398(00) WITH text-e09 text-e10 text-e11 space.
    ENDIF.

    SORT lt_tbtco_f BY sdlstrtdt DESCENDING
                       sdlstrttm DESCENDING.
    READ TABLE lt_tbtco_f INTO gw_tbtco_f INDEX 1.

    PERFORM trascod_data USING gw_tbtco_f-sdlstrtdt gw_tbtco_f-sdlstrttm
                         CHANGING p_date_f.

  ELSE.
    DATA lv_app TYPE char14.
    lv_app = p_date_f.
    gw_tbtco_f-sdlstrtdt = lv_app(8).
    gw_tbtco_f-sdlstrttm = lv_app+8(6).
  ENDIF.

ENDFORM.                    " get_date_time_from
*&---------------------------------------------------------------------*
*&      Form  trascod_guid_16_32
*&---------------------------------------------------------------------*
*       Trascodifica un GUID da RAW16 a CHAR32
*----------------------------------------------------------------------*
FORM trascod_guid_16_32 USING    p_guid16 TYPE sysuuid-x
                        CHANGING p_guid32 TYPE sysuuid-c.
  CLEAR p_guid32.
  CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_16_32'
    EXPORTING
      i_guid16 = p_guid16
    IMPORTING
      e_guid32 = p_guid32.
ENDFORM.                    " trascod_guid_16_32
*&---------------------------------------------------------------------*
*&      Form  call_bapi_getdetailmul
*&---------------------------------------------------------------------*
*       Richiama la BAPI BAPI_BUSPROCESSND_GETDETAILMUL
*----------------------------------------------------------------------*
FORM call_bapi_getdetailmul.

  DATA: lt_guid         LIKE i_guid,
        lt_doc_flow_app TYPE STANDARD TABLE OF bapibus20001_doc_flow_dis,
        ls_guid16       TYPE t_guid16,
        lt_guid16       TYPE t_guid16_tab.

  FIELD-SYMBOLS: <fs_doc_flow> TYPE bapibus20001_doc_flow_dis,
                 <fs_guid>     LIKE LINE OF lt_guid.

  REFRESH: i_appointment,
           i_partner,
           i_status,
           i_text,
           i_item,
           i_schedule_item,
           i_product_list,
           i_doc_flow,
           i_prec_doc,
           lt_doc_flow_app,
           i_header,
           i_customer_h,
           i_order_index,"add mferrara 10/08/2015
           i_crm_jcds.

* Utilizza una tabella d'appoggio perchè la tabella i_guid non deve
* essere modificata
  lt_guid[] = i_guid[].

  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
    TABLES
      guid          = lt_guid
      header        = i_header
      partner       = i_partner
      appointment   = i_appointment
      text          = i_text
      status        = i_status
      item          = i_item
      schedule_item = i_schedule_item
      product_list  = i_product_list
      doc_flow      = i_doc_flow
      products      = i_products. " Add AS 29.05.2012

  DELETE i_status WHERE status(1) NE ca_e. " ADD SC 05/03/2009

  REFRESH lt_guid16.
  LOOP AT lt_guid ASSIGNING <fs_guid>.
    PERFORM trascod_guid_32_16 USING <fs_guid>-guid
                            CHANGING ls_guid16-guid.
    APPEND ls_guid16 TO lt_guid16.
  ENDLOOP.

  SELECT guid
         zzcustomer_h0901
         zzcustomer_h0902
         zz_opzione
         zz_operazione
         zz_numero_cc
         zz_idunivoco
         zz_motivazione
         zz_raccomandata  "ADD GC 23/07/09
         zz_distinta      "ADD GC 23/07/09
         zz_cod_conv      "ADD GC 23/07/09
         zz_tipo_conto
         zz_intest_conto
         zz_promo
         zz_provenienza " Add AS 16.03.2012
         zz_firma
         zz_bonifica
* ADD MA 27.09.2010 Gestione campi contratti PTB
         zz_mod_pagamento
         zz_codice_deroga
         zz_iban
         zz_mezzo_pagam
         zz_inter_mora
         zz_termini_pag
         zz_invio_fattura
         zz_ind_fatt      " Iniziativa 106592 - Nuovi campi MAAF
         zz_pick_up
         zz_aggr_fattura
         zz_cod_ccontratt "Modifica RS 26.10.2011
         zz_period_fatt
         zz_dur_cons_sost
         zz_can_erogaz
         zz_period_sett
         zz_altra_period
         zz_totale_lavor
* END ADD MA 27.09.2010 Gestione campi contratti PTB
* ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
         zzcustomer_h2301
         zzcustomer_h2302
         zzcustomer_h2304
         zzcustomer_h2306
         zzcustomer_h2303
         zzcustomer_h2305
* Begin AG 22.03.2011 18:05:20
         zzdata_scadenza
* End   AG 22.03.2011 18:05:20
* INIZIO MODIFICA AS DEL 11.05.2011 15:02:52
         zz_regio_resid
         zzcustomer_h2307
         zzid_modulo
* FINE MODIFICA AS DEL 11.05.2011 15:02:52
" Inizio AS 15.05.2012
         zz_tel_mise
         zz_tipo_conto_s
         zzlink_object_id
" Fine   AS 15.05.2012
* END ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
         zzmodalita   "VPM-26.04.2012 GEC
         zznickname   " Add AS 15.05.2012
*      PLP-01 - Insert - Start
         zz_tipo_carta_cr
         zz_ruolo
*      PLP-01 - Insert - End
          zz_codice_uff " " Iniziativa 106592 - Nuovi campi MAAF
          zz_sede_lav   "ADD CL - 03.06.2013 - Delete CL - 13.06.2013 "Ripristino 21.11.2017
    "Inizio mferrara NOP_014 - 10/08/2015
          zz_totale_prezzo
          zz_durata_anni
    "Fine mferrara NOP_014 - 10/08/2015

          zz_tipologia  "TP 21.04.2016
   FROM crmd_customer_h INTO TABLE i_customer_h
   FOR ALL ENTRIES IN lt_guid16
   WHERE guid EQ lt_guid16-guid.

  " Il codice ufficio va filtrato per segmento privato
  PERFORM f_get_bpkind USING i_partner CHANGING gt_bpkind.  " Mod. MN - Gestione temp. codice ufficio - 22.11.2018

*  105900 : Inizio modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file
  PERFORM f_estrai_dati_aggiuntivi USING lt_guid16.
*  105900 : Fine modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file


  "Inizio mferrara 10/08/2015 - NOP_014
*  PERFORM f_estrai_order_index USING lt_guid16.
  "Fine mferrara 10/08/2015 - NOP_014

* ADD MA 27.09.2010 Gestione campi contratti PTB
  PERFORM f_estrai_cod_contrattuale USING lt_guid16.
* END ADD MA 27.09.2010 Gestione campi contratti PTB

* Begin MN - 03.11.2015
  PERFORM f_estrai_id_univoco_crono.
* End MN - 03.11.2015

  DELETE i_text WHERE tdid    NE gv_edw_note OR
                      tdspras NE ca_i.

* -- Estrazione Modifiche Stato
  PERFORM f_estrai_mod_stato USING lt_guid16.

* -- Estrazione -------------------------------------------------------------------
  " Inizio AS 17.05.2012
  PERFORM f_estrai_zmp_addon_prod.

  PERFORM f_estrai_zca_addon_order.
  " Fine   AS 17.05.2012

  PERFORM f_estrai_zca_dati_maaf. " Iniziativa 106592 - Nuovi campi MAAF

  CHECK NOT i_doc_flow[] IS INITIAL.

* -- Estrazione Dati Documenti Precedenti
  lt_doc_flow_app[] = i_doc_flow[].
  SORT lt_doc_flow_app BY objkey_a.
  DELETE ADJACENT DUPLICATES FROM lt_doc_flow_app COMPARING objkey_a.

  REFRESH lt_guid16.
  LOOP AT lt_doc_flow_app ASSIGNING <fs_doc_flow>.
    PERFORM trascod_guid_32_16 USING <fs_doc_flow>-objkey_a
                               CHANGING ls_guid16-guid.
    APPEND ls_guid16 TO lt_guid16.
  ENDLOOP.

  SELECT guid object_id object_type FROM crmd_orderadm_h
    INTO TABLE i_prec_doc
    FOR ALL ENTRIES IN lt_guid16
    WHERE guid EQ lt_guid16-guid.

ENDFORM.                    " call_bapi_getdetailmul
*&---------------------------------------------------------------------*
*&      Form  elabora
*&---------------------------------------------------------------------*
*        Trasferisce su file i record estratti
*----------------------------------------------------------------------*
FORM elabora.

  DATA: ls_header          TYPE t_header,
        lt_prodotti        TYPE t_prodotti_tab,
        lt_partner         TYPE t_partner_tab,
        lt_mod_stato       TYPE t_mod_stato_tab,
        lt_attr_dimens     TYPE t_attr_dimens_tab, " Add AS 18.05.2012
        lt_cons_priv_contr TYPE t_cons_priv_contr_tab, " Add AS 17.05.2012
        lt_mod_stato_pos   TYPE t_mod_stato_pos_tab, "ADD GC 23/07/09
        lt_attr_acc        TYPE t_attr_acc_tab,          "TP 21.04.2016
        fl_error           TYPE c.

  FIELD-SYMBOLS: <fs_guid> LIKE LINE OF i_guid,
                 <fs_item> LIKE LINE OF i_item.

  "Inizio modifiche - GC 24.07.2009 12:25:05
  DATA: BEGIN OF ls_guid_tmp,
          guid TYPE crmd_customer_i-guid,
        END OF ls_guid_tmp.

  DATA:  lt_guid_tmp     LIKE STANDARD TABLE OF ls_guid_tmp.

  "Fine   modifiche - GC 24.07.2009 12:25:05

  SORT i_appointment   BY ref_guid appt_type.
  SORT i_status        BY guid kind status active.
  SORT i_text          BY ref_guid.
  SORT i_item          BY header.
  SORT i_product_list  BY guid.
  SORT i_schedule_item BY guid.
  SORT i_partner       BY ref_guid.
  SORT i_prec_doc      BY guid.
  SORT i_doc_flow      BY ref_guid.
  SORT i_header        BY guid.
  SORT i_customer_h    BY guid.
  SORT i_crm_jcds      BY objnr udate utime.
  SORT i_order_index   BY header. "add mferrara 10/08/20158ì
  SORT i_zca_spid_prod BY id_pratica. "TP 21.04.2016

  "Inizio modifiche - GC 24.07.2009 09:47:55
  UNASSIGN <fs_item>.
  LOOP AT i_item ASSIGNING <fs_item>.
    CLEAR ls_guid_tmp.
    CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
      EXPORTING
        i_guid32 = <fs_item>-guid
      IMPORTING
        e_guid16 = ls_guid_tmp-guid.

    APPEND ls_guid_tmp TO lt_guid_tmp.
  ENDLOOP.

  IF NOT lt_guid_tmp[] IS INITIAL.
    SELECT guid
           zz_motivaz_nor_i
           zz_cat_motivaz_i
           zz_descr_lavor_i
           zz_lavorazione_i
           zz_cod_promo
* ADD MA 27.09.2010 Gestione campi contratti PTB
           zz_id_prod_ext
           zz_codice_promoz
           zz_ytd_quantity
           zz_net_pr_unit
           zz_total_value
           zz_qmax_perorder
           zz_shipping_freq
*Inizio modifica RS 26.10.2011
           zz_qta_effettiva
           zz_imp_eff_liva
           zz_imp_eff_niva
*Fine modifica RS 26.10.2011
* END ADD MA 27.09.2010 Gestione campi contratti PTB
* Begin AG 22.03.2011 18:08:20
           zz_code_resp
           zz_code_chall
           zz_code_sms_otp
           zz_cell_fdr
* End   AG 22.03.2011 18:08:20
           zz_cod_promo_web " Add AS 15.05.2012
     FROM crmd_customer_i
     INTO TABLE gt_customer_i
     FOR ALL ENTRIES IN lt_guid_tmp
     WHERE guid EQ lt_guid_tmp-guid.

*--- Se viene lanciato in delta applico un filtro sull'estrazione.
    IF r_delta EQ ca_x.

      SELECT *
        FROM crm_jcds
        INTO TABLE gt_crm_jcds
        FOR ALL ENTRIES IN lt_guid_tmp
        WHERE objnr EQ lt_guid_tmp-guid
        AND (
              ( udate EQ gw_tbtco_f-sdlstrtdt AND udate NE gw_tbtco_t-sdlstrtdt AND utime GE gw_tbtco_f-sdlstrttm )
           OR ( udate EQ gw_tbtco_f-sdlstrtdt AND udate EQ gw_tbtco_t-sdlstrtdt AND utime GE gw_tbtco_f-sdlstrttm AND utime LT gw_tbtco_t-sdlstrttm )
           OR ( udate EQ gw_tbtco_t-sdlstrtdt AND udate NE gw_tbtco_f-sdlstrtdt AND utime LT gw_tbtco_t-sdlstrttm )
           OR ( udate GT gw_tbtco_f-sdlstrtdt AND udate LT gw_tbtco_t-sdlstrtdt )
*               ( udate GT gw_tbtco_f-sdlstrtdt AND udate LT gw_tbtco_t-sdlstrtdt )
*            OR ( udate EQ gw_tbtco_f-sdlstrtdt AND utime GE gw_tbtco_f-sdlstrttm )
*            OR ( udate EQ gw_tbtco_t-sdlstrtdt AND utime LE gw_tbtco_t-sdlstrttm )
            )
          AND stat LIKE 'E%'
          AND inact EQ space.
    ELSE.
      SELECT *
      FROM crm_jcds
      INTO TABLE gt_crm_jcds
      FOR ALL ENTRIES IN lt_guid_tmp
      WHERE objnr EQ lt_guid_tmp-guid
        AND stat LIKE 'E%'
        AND inact EQ space.
    ENDIF.

  ENDIF.

  "Fine   modifiche - GC 24.07.2009 09:47:55

  DATA: lv_tmp_guid TYPE crmt_object_guid.

* Begin AG 07.02.2014
* BUNDLE_09 - estrazioni
  REFRESH gt_ztipo_promo_bun[].
  SELECT *
    FROM ztipo_promo_bun
    INTO TABLE gt_ztipo_promo_bun.

  REFRESH gt_guid_header[].
  LOOP AT i_guid ASSIGNING <fs_guid>.
    CLEAR gs_guid_header.
    gs_guid_header-guid32 = <fs_guid>-guid.

    CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
      EXPORTING
        i_guid32 = gs_guid_header-guid32
      IMPORTING
        e_guid16 = gs_guid_header-guid16.
    APPEND gs_guid_header TO gt_guid_header.
  ENDLOOP.

  REFRESH gt_zca_cod_promo_bu[].

  IF gt_guid_header[] IS NOT INITIAL.
    SELECT *
      FROM zca_cod_promo_bu
      INTO TABLE gt_zca_cod_promo_bu
      FOR ALL ENTRIES IN gt_guid_header
      WHERE guid        EQ gt_guid_header-guid16.
  ENDIF.
* End   AG 07.02.2014


  LOOP AT i_guid ASSIGNING <fs_guid>.
    CLEAR lv_tmp_guid.
    lv_tmp_guid = <fs_guid>-guid.

    CLEAR: fl_error.

*   -- Prepara Record di testata
    PERFORM f_prepara_header USING <fs_guid>
                          CHANGING ls_header
                                   fl_error.

    CHECK fl_error IS INITIAL.

*   -- Prepara Record Prodotti
    PERFORM f_prepara_prodotti USING <fs_guid>
                                     ls_header
                            CHANGING lt_prodotti
                                     gt_customer_i    "ADD GC 23/07/09
                                     lt_mod_stato_pos "ADD GC 23/07/09
                                     fl_error.
    CHECK fl_error IS INITIAL.

*   -- Prepara Record Prodotti
    PERFORM f_prepara_partner USING <fs_guid>
                                    ls_header
                           CHANGING lt_partner
                                    fl_error.

    CHECK fl_error IS INITIAL.

*   -- Prepara Record Modifiche di Stato
    PERFORM f_prepara_mod_stato USING <fs_guid>
                                      ls_header
                             CHANGING lt_mod_stato
                                      fl_error.

    CHECK fl_error IS INITIAL.
    " Inizio AS 17.05.2012
*   -- Prepara Record Modifiche di Stato
    PERFORM f_prepara_cons_priv_contr  USING <fs_guid>
                                             ls_header
                                    CHANGING lt_cons_priv_contr
                                             fl_error.

    CHECK fl_error IS INITIAL.

*   -- Prepara Record Modifiche di Stato
    PERFORM f_prepara_attributi_dimensioni  USING <fs_guid>
                                                  ls_header
                                         CHANGING lt_attr_dimens
                                                  fl_error.

    CHECK fl_error IS INITIAL.
    " Fine   AS 17.05.2012

*** Inizio TP 21.04.2016
    PERFORM f_prepara_attributi_accessori USING ls_header
                                          CHANGING lt_attr_acc
                                                   fl_error.
    CHECK fl_error IS INITIAL.
*** Fine TP 21.04.2016

*   -- Scrivi Record Contratto
    PERFORM f_scrivi_record USING ls_header
                                  lt_prodotti
                                  lt_partner
                                  lt_mod_stato
                                  lt_mod_stato_pos   "ADD GC 23/07/09
                                  lt_cons_priv_contr " Add AS 29.05.2012
                                  lt_attr_dimens     " Add AS 18.05.2012
                                  lt_attr_acc.       " TP 21.04.2016
  ENDLOOP.

ENDFORM.                    " elabora
*&---------------------------------------------------------------------*
*&      Form  f_prepara_header
*&---------------------------------------------------------------------*
*   Prepara il record di testata
*----------------------------------------------------------------------*
FORM f_prepara_header  USING    ps_guid         TYPE bapibus20001_guid_dis
                       CHANGING ps_header       TYPE t_header
                                pf_error        TYPE c.

  CONSTANTS: lc_can_erog(9)   VALUE 'CAN_EROG_'.

  DATA: lv_count        TYPE i,
        lv_codice       TYPE string,
        lv_timestamp    TYPE tzonref-tstamps,
        lv_datlo        TYPE sy-datlo,
        lv_timlo        TYPE sy-timlo,
        ls_customer_h   TYPE t_customer_h,
        ls_cod_contr    TYPE zca_ptb_cocontr,
        lv_parametro    TYPE zca_param-z_nome_par,
        ls_can_erogaz   TYPE zca_param,
        lv_date_3       TYPE sy-datum,
        lv_data_maaf    TYPE int2,
        ls_header       TYPE bapibus20001_header_dis, " ADD MN - 03.11.2015
        lv_guid16       TYPE sysuuid-x,               " ADD MN - 03.11.2015
        ls_cronomapping TYPE t_cronomapping,          " ADD MN - 03.11.2015
        ls_iduniv_crono TYPE t_idunivoco_crono.       " Add CP 22.02.2017

  FIELD-SYMBOLS:   <fs_appointment>    TYPE bapibus20001_appointment_dis,
                   <fs_status>         TYPE bapibus20001_status_dis,
                   <fs_text>           TYPE bapibus20001_text_dis,
                   <fs_doc_flow>       TYPE bapibus20001_doc_flow_dis,
                   <fs_header>         TYPE bapibus20001_header_dis,
                   <fs_prec_doc>       TYPE t_prec_doc,
                   <fs_nop_motivo>     TYPE zca_nop_motivo,
                   <fs_prev_bp>        TYPE t_bdm_prev_bp, " add mf 16/09/2011
                   <fs_bdm_contract>   TYPE t_bdm_contract, "add mf 16/09/2011
                   <fs_leggi_prev_app> TYPE t_leggi_prev,
                   <fs_bdm_crif>       TYPE t_bdm_crif,
                   <fs_zca_bdm_pddlb>  TYPE zca_bdm_pddlb,
                   <fs_index>          TYPE t_index, "add mferrara 10/08/2015
* 105900 : Inizio modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file
                   <fs_dati_agg_fa>    TYPE t_dati_agg_fa.
* 105900 : Inizio modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file

* Begin AG 06.02.2014
* BUNDLE_09
  DATA: gs_zca_cod_promo_bu TYPE zca_cod_promo_bu,
        ls_cod_promo        TYPE ztipo_promo_bun.
* End   AG 06.02.2014
*  DATA lv_committente TYPE bu_partner. "  Mod. MN - Gestione temp. codice ufficio - 22.11.2018


  CLEAR ps_header.

  CLEAR ls_customer_h.
  READ TABLE i_customer_h INTO ls_customer_h WITH KEY guid = ps_guid-guid
                                                      BINARY SEARCH.

  READ TABLE i_header ASSIGNING <fs_header> WITH KEY guid = ps_guid-guid
                                                     BINARY SEARCH.
  IF NOT sy-subrc IS INITIAL
    OR <fs_header>-object_id IS INITIAL.
*   -- Scrittura Record di Log
    CLEAR lv_codice.
    lv_codice = ps_guid-guid.
    PERFORM f_scrivi_error USING lv_codice
                                 text-e01.
    pf_error = ca_x.
    RETURN.
  ENDIF.

  ps_header-tipo_record      = ca_hh.
  ps_header-codice_crm       = <fs_header>-object_id.
  ps_header-descrizione      = <fs_header>-description.
  ps_header-classe_documento = <fs_header>-object_type.


* PLP-01 - Insert - Start
  ps_header-tipo_carta = ls_customer_h-zz_tipo_carta_cr.
  ps_header-ruolo      = ls_customer_h-zz_ruolo.
* PLP-01 - Insert - End


  READ TABLE gt_cnop TRANSPORTING NO FIELDS WITH KEY z_val_par = <fs_header>-process_type.
  IF sy-subrc IS INITIAL.
    ps_header-tipo_contratto  = ls_customer_h-zz_opzione.
  ELSE.
    ps_header-tipo_contratto  = <fs_header>-process_type.
  ENDIF.

*  IF ps_header-tipo_contratto IS INITIAL.
**   -- Scrittura Record di Log
*    CLEAR lv_codice.
*    lv_codice = ps_header-codice_crm.
*    PERFORM f_scrivi_error USING lv_codice
*                                 text-e16.
*    pf_error = ca_x.
*    RETURN.
*  ENDIF.


  READ TABLE i_appointment
  ASSIGNING <fs_appointment> WITH KEY ref_guid  = ps_guid-guid
                                      appt_type = ca_contstart
                                      BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    IF <fs_appointment>-date_from <> '00000000'.    "ADD MA 27.09.2010
      ps_header-data_apertura   = <fs_appointment>-date_from.
    ENDIF.
  ENDIF.

*  IF ps_header-data_apertura IS INITIAL.
**   -- Scrittura Record di Log
*    CLEAR lv_codice.
*    lv_codice = ps_header-codice_crm.
*    PERFORM f_scrivi_error USING lv_codice
*                                 text-e17.
*    pf_error = ca_x.
*    RETURN.
*  ENDIF.

  READ TABLE i_appointment
  ASSIGNING <fs_appointment> WITH KEY ref_guid  = ps_guid-guid
                                      appt_type = ca_contend
                                      BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    IF <fs_appointment>-date_from <> '00000000'.    "ADD MA 27.09.2010
      ps_header-data_chiusura   = <fs_appointment>-date_from.
    ENDIF.
  ENDIF.

*  IF ps_header-data_chiusura IS INITIAL.
**   -- Scrittura Record di Log
*    CLEAR lv_codice.
*    lv_codice = ps_header-codice_crm.
*    PERFORM f_scrivi_error USING lv_codice
*                                 text-e18.
*    pf_error = ca_x.
*    RETURN.
*  ENDIF.

  "Inizio modifiche - GC 24.07.2009 12:07:08

*--- Data richiesta ---*
  READ TABLE i_appointment
  ASSIGNING <fs_appointment> WITH KEY ref_guid  = ps_guid-guid
                                      appt_type = ca_z_data_rich
                                      BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    IF <fs_appointment>-date_from <> '00000000'.    "ADD MA 27.09.2010
      ps_header-data_richiesta  = <fs_appointment>-date_from.
    ENDIF.
    ps_header-ora_richiesta   = <fs_appointment>-time_from.
  ENDIF.

*  IF ps_header-data_richiesta IS INITIAL.
**   -- Scrittura Record di Log
*    CLEAR lv_codice.
*    lv_codice = ps_header-codice_crm.
*    PERFORM f_scrivi_error USING lv_codice
*                                 text-e28.
*    pf_error = ca_x.
*    RETURN.
*  ENDIF.

*--- Data/Ora Invio pratica ---*
  READ TABLE i_appointment
  ASSIGNING <fs_appointment> WITH KEY ref_guid  = ps_guid-guid
                                      appt_type = ca_z_data_invio
                                      BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    IF <fs_appointment>-date_from <> '00000000'.    "ADD MA 27.09.2010
      ps_header-data_invio_pratica  = <fs_appointment>-date_from.
    ENDIF.
    ps_header-ora_invio_pratica   = <fs_appointment>-time_from.
  ENDIF.

*--- Data arrivo pratica ---*
  READ TABLE i_appointment
  ASSIGNING <fs_appointment> WITH KEY ref_guid  = ps_guid-guid
                                      appt_type = ca_z_data_prat
                                      BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    IF <fs_appointment>-date_from <> '00000000'.    "ADD MA 27.09.2010
      ps_header-data_arrivo_pratica  = <fs_appointment>-date_from.
    ENDIF.
    ps_header-ora_arrivo_pratica   = <fs_appointment>-time_from.
  ENDIF.

*  IF ps_header-data_arrivo_pratica IS INITIAL.
**   -- Scrittura Record di Log
*    CLEAR lv_codice.
*    lv_codice = ps_header-codice_crm.
*    PERFORM f_scrivi_error USING lv_codice
*                                 text-e29.
*    pf_error = ca_x.
*    RETURN.
*  ENDIF.

*--- Data inizio lavorazione ---*
  READ TABLE i_appointment
  ASSIGNING <fs_appointment> WITH KEY ref_guid  = ps_guid-guid
                                      appt_type = ca_z_start_lav
                                      BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    IF <fs_appointment>-date_from <> '00000000'.    "ADD MA 27.09.2010
      ps_header-data_inizio_lavorazione  = <fs_appointment>-date_from.
    ENDIF.
    ps_header-ora_inizio_lavorazione   = <fs_appointment>-time_from.
  ENDIF.

*  IF ps_header-data_inizio_lavorazione IS INITIAL.
**   -- Scrittura Record di Log
*    CLEAR lv_codice.
*    lv_codice = ps_header-codice_crm.
*    PERFORM f_scrivi_error USING lv_codice
*                                 text-e30.
*    pf_error = ca_x.
*    RETURN.
*  ENDIF.

*--- Data fine lavorazione ---*
  READ TABLE i_appointment
  ASSIGNING <fs_appointment> WITH KEY ref_guid  = ps_guid-guid
                                      appt_type = ca_z_end_lav
                                      BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    IF <fs_appointment>-date_from <> '00000000'.    "ADD MA 27.09.2010
      ps_header-data_fine_lavorazione = <fs_appointment>-date_from.
    ENDIF.
    ps_header-ora_fine_lavorazione  = <fs_appointment>-time_from.
  ENDIF.

*  IF ps_header-data_fine_lavorazione IS INITIAL.
**   -- Scrittura Record di Log
*    CLEAR lv_codice.
*    lv_codice = ps_header-codice_crm.
*    PERFORM f_scrivi_error USING lv_codice
*                                 text-e31.
*    pf_error = ca_x.
*    RETURN.
*  ENDIF.

  "Fine   modifiche - GC 24.07.2009 12:07:08
  READ TABLE i_status ASSIGNING <fs_status> WITH KEY guid           = ps_guid-guid
                                                     kind           = ca_a " Modifica AG - 16.12.2009 17:45:21
                                                     status(1)      = ca_e " Modifica AG - 16.12.2009 17:45:24
                                                     active         = ca_x
                                                     BINARY SEARCH.
  IF sy-subrc IS INITIAL.
* Inizio Modifica AG 16.12.2009 17:45:36
*    "Inizio modifiche - GC 23.07.2009 17:21:29
*    IF <fs_status>-user_stat_proc IN gr_stah.
    CONCATENATE <fs_status>-user_stat_proc
                <fs_status>-status
           INTO ps_header-stato.
*    ENDIF.
*    "Fine   modifiche - GC 23.07.2009 17:21:29
* Fine   Modifica AG 16.12.2009 17:45:36
  ENDIF.

*  IF ps_header-stato IS INITIAL.
**   -- Scrittura Record di Log
*    CLEAR lv_codice.
*    lv_codice = ps_header-codice_crm.
*    PERFORM f_scrivi_error USING lv_codice
*                                 text-e19.
*    pf_error = ca_x.
*    RETURN.
*  ENDIF.

  ps_header-numero_conto    = ls_customer_h-zz_numero_cc.
  ps_header-operazione      = ls_customer_h-zz_operazione.
  ps_header-area            = ls_customer_h-zzcustomer_h0901.
  ps_header-canale          = ls_customer_h-zzcustomer_h0902.
  ps_header-id_univoco      = ls_customer_h-zz_idunivoco.

* Begin MN - 03.11.2015
  " in caso di contratto CRONO sovrascrivo l'ID_UNIVOCO per i contratti figli (ID_ERMES = blank)
  READ TABLE i_header INTO ls_header WITH KEY guid = ps_guid.
  IF sy-subrc IS INITIAL.
    IF ls_header-process_type EQ 'ZCRN'.
      CLEAR lv_guid16.
      PERFORM trascod_guid_32_16 USING ls_header-guid
                              CHANGING lv_guid16.
      READ TABLE gt_cronomapping INTO ls_cronomapping WITH KEY guid_testata = lv_guid16.
      IF sy-subrc IS INITIAL.
        IF ls_cronomapping-id_ermes IS INITIAL.
          " Begin CP 22.02.2017
          READ TABLE gt_idunivoco_crono INTO ls_iduniv_crono WITH KEY guid = ls_cronomapping-guid_padre.
          IF sy-subrc IS INITIAL.
            ps_header-id_univoco = ls_iduniv_crono-object_id.
          ENDIF.
          " End CP 22.02.2017
*          ps_header-id_univoco = ls_cronomapping-guid_padre. " Del CP 22.02.2017
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
* End MN - 03.11.2015

  "Inizio modifiche - GC 23.07.2009 17:48:57
  ps_header-no_raccomandata = ls_customer_h-zz_raccomandata.
  ps_header-id_distinta     = ls_customer_h-zz_distinta.

  ps_header-cod_convenzione = ls_customer_h-zz_cod_conv.


* Begin AG 06.02.2014
* BUNDLE_09
* nel caso di contratti Selezione Impresa accedere alla ZCA_PARAM
* con gruppo parametri PRMH e applicazione ZCAE_EDWHAE_CONTRATTI:
* Verificare se il valore del process type della pratica è contenuto nel gruppo...
  READ TABLE gt_prmh TRANSPORTING NO FIELDS
    WITH KEY z_val_par = <fs_header>-process_type.
  IF sy-subrc IS INITIAL.
    CLEAR ps_header-cod_convenzione.
* ...se presente, accedere alla tabella ZCA_COD_PROMO_BU con
* GUID = CRMD_ORDERADM_H-GUID e PRODUCT_ID = blank.
* prendere solo il primo record
    CLEAR gs_guid_header.
    READ TABLE gt_guid_header INTO gs_guid_header
      WITH KEY guid32 = ps_guid-guid.
    IF gs_guid_header-guid16 IS NOT INITIAL.
      CLEAR gs_zca_cod_promo_bu.
      READ TABLE gt_zca_cod_promo_bu INTO gs_zca_cod_promo_bu
        WITH KEY guid       = gs_guid_header-guid16
                 product_id = space.
      IF sy-subrc IS INITIAL.
* accedere alla tabella ZTIPO_PROMO_BUN con TIPO_PROMO = ZCA_COD_PROMO_BU-TIPO_PROMO
* e valorizzare il campo COD_CONVENZIONE con il valore del campo COD_PROMO_EDWH. Se
* almeno una delle estrazione non restituisce alcun record lasciare il campo vuoto.
        CLEAR ls_cod_promo.
        READ TABLE gt_ztipo_promo_bun INTO ls_cod_promo
          WITH KEY tipo_promo = gs_zca_cod_promo_bu-tipo_promo.
        IF sy-subrc IS INITIAL.
          ps_header-cod_convenzione = ls_cod_promo-cod_promo_edwh.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
* End   AG 06.02.2014

  "Fine   modifiche - GC 23.07.2009 17:48:57
  ps_header-intest_part_rapporto  = ls_customer_h-zz_intest_conto.
  ps_header-prod_in_promoz        = ls_customer_h-zz_promo.
  ps_header-tipo_firma            = ls_customer_h-zz_firma.
  ps_header-contratto_bonificato  = ls_customer_h-zz_bonifica.
  ps_header-zz_tipo_conto         = ls_customer_h-zz_tipo_conto.

  ps_header-canale_provenienza    = ls_customer_h-zz_provenienza. " Add AS 16.03.2012


* Begin AG 22.03.2011 18:13:20
* INIZIO MODIFICA AS DEL 25.05.2011 11:33:45
  IF ls_customer_h-zzdata_scadenza IS INITIAL.
    ps_header-data_scadenza = space.
  ELSE.
    ps_header-data_scadenza = ls_customer_h-zzdata_scadenza.
  ENDIF.
*  ps_header-data_scadenza = ls_customer_h-zzdata_scadenza.
* FINE MODIFICA AS DEL 25.05.2011 11:33:45
* End   AG 22.03.2011 18:13:20
* INIZIO MODIFICA AS DEL 11.05.2011 15:10:08
  ps_header-regione_resid   = ls_customer_h-zz_regio_resid.
  ps_header-frazionario     = ls_customer_h-zzcustomer_h2307.
  ps_header-id_modulo_mise  = ls_customer_h-zzid_modulo.

*inizio modifica campi GEC - VPM 26.04.2012
  ps_header-modalita  = ls_customer_h-zzmodalita.
*inizio modifica campi GEC - VPM 26.04.2012

  " Inizio AS 15.05.2012
  ps_header-nickname             = ls_customer_h-zznickname.
  ps_header-id_contratto_web     = ls_customer_h-zzlink_object_id.
  ps_header-tipo_conto_origine   = ls_customer_h-zz_tipo_conto_s.
  ps_header-telefono_contatto    = ls_customer_h-zz_tel_mise.
  " Fine   AS 15.05.2012

*  inizio modifica mf 16/09/2011

  READ TABLE i_bdm_contract ASSIGNING <fs_bdm_contract> WITH KEY contract_guid = ps_guid-guid.
  IF sy-subrc IS INITIAL.
    IF <fs_bdm_contract>-data_apertura_cc IS NOT INITIAL."add mf 25/11/2011
      ps_header-data_apertura_cc               = <fs_bdm_contract>-data_apertura_cc.
    ENDIF. "add mf 25/11/2011

    ps_header-data_richiesta                 = <fs_bdm_contract>-data_richiesta. "fix data richiesta
    ps_header-correntista_bp                 = <fs_bdm_contract>-correntista_bp.
    ps_header-finalita_fin1                  = <fs_bdm_contract>-finalita_fin1.
    ps_header-finalita_fin2                  = <fs_bdm_contract>-finalita_fin2.
    ps_header-finalita_fin3                  = <fs_bdm_contract>-finalita_fin3.
    ps_header-debito_res                     = <fs_bdm_contract>-debito_res.
    ps_header-mod_erogazione                 = <fs_bdm_contract>-mod_erogazione.
    ps_header-mod_rimborso                   = <fs_bdm_contract>-mod_rimborso.
    ps_header-garanzia_fideiussoria          = <fs_bdm_contract>-garanzia_fideiussoria.
    ps_header-tipo_garanzia_richiesta        = <fs_bdm_contract>-tipo_garanzia_richiesta.
    ps_header-importo_garanzia_richiesta     = <fs_bdm_contract>-importo_garanzia_richiesta.
    "inzio mf 25/11/2011
    CONDENSE ps_header-importo_garanzia_richiesta NO-GAPS.
    IF <fs_bdm_contract>-data_delibera IS NOT INITIAL.
      ps_header-data_delibera                  = <fs_bdm_contract>-data_delibera.
    ENDIF.
    "fine mf 25/11/2011
    ps_header-importo_deliberato             = <fs_bdm_contract>-importo_deliberato.
    "inzio mf 25/11/2011
    CONDENSE ps_header-importo_deliberato NO-GAPS.
    "fine mf 25/11/2011
    ps_header-dur_finanziamento_deliberato   = <fs_bdm_contract>-dur_finanziamento_deliberato.
    ps_header-periodicita_rata_deliberata    = <fs_bdm_contract>-periodicita_rata_deliberata.
    ps_header-tipo_garanzia_deliberata1      = <fs_bdm_contract>-tipo_garanzia_deliberata1.
    ps_header-importo_garanzia_deliberata1   = <fs_bdm_contract>-importo_garanzia_deliberata1.
    "inzio mf 25/11/2011
    CONDENSE ps_header-importo_garanzia_deliberata1 NO-GAPS.
    "fine mf 25/11/2011
    ps_header-denominazione_garante1         = <fs_bdm_contract>-denominazione_garante1.
    ps_header-tipo_garanzia_deliberata2      = <fs_bdm_contract>-tipo_garanzia_deliberata2.
    ps_header-importo_garanzia_deliberata2   = <fs_bdm_contract>-importo_garanzia_deliberata2.
    "inzio mf 25/11/2011
    CONDENSE ps_header-importo_garanzia_deliberata2 NO-GAPS.
    "fine mf 25/11/2011
    ps_header-denominazione_garante2         = <fs_bdm_contract>-denominazione_garante2.
    ps_header-tipo_garanzia_deliberata3      = <fs_bdm_contract>-tipo_garanzia_deliberata3.
    ps_header-importo_garanzia_deliberata3   = <fs_bdm_contract>-importo_garanzia_deliberata3.
    "inzio mf 25/11/2011
    CONDENSE ps_header-importo_garanzia_deliberata3  NO-GAPS.
    "fine mf 25/11/2011
    ps_header-denominazione_garante3         = <fs_bdm_contract>-denominazione_garante3.
    IF <fs_bdm_contract>-data_stipula_contratto IS NOT INITIAL."add mf 25/11/2011
      ps_header-data_stipula_contratto         = <fs_bdm_contract>-data_stipula_contratto.
    ENDIF."add mf 25/11/2011
    IF <fs_bdm_contract>-data_sottoscrizi IS NOT INITIAL."add mf 25/11/2011
      ps_header-data_sottoscrizi                = <fs_bdm_contract>-data_sottoscrizi.
    ENDIF."add mf 25/11/2011
    ps_header-importo_erogato                = <fs_bdm_contract>-importo_erogato.
    IF <fs_bdm_contract>-data_erogazione IS NOT INITIAL."add VPM-21.03.2012
      ps_header-data_erogazione                = <fs_bdm_contract>-data_erogazione.
    ENDIF."add VPM-21.03.2012
    "inzio mf 25/11/2011
    CONDENSE ps_header-importo_erogato  NO-GAPS.
    "fine mf 25/11/2011
    ps_header-tasso_erogato                  = <fs_bdm_contract>-tipo_tasso_erogato.
    ps_header-spread_erogato                 = <fs_bdm_contract>-spread_erogato.
    "inzio mf 29/11/2011
    CONDENSE ps_header-spread_erogato  NO-GAPS.
    "fine mf 29/11/2011
    ps_header-taeg_erogato                   = <fs_bdm_contract>-taeg_erogato.
    "inzio mf 29/11/2011
    CONDENSE ps_header-taeg_erogato  NO-GAPS.
    "fine mf 29/11/2011
    ps_header-importo_premio_cpi_erogato     = <fs_bdm_contract>-importo_premio_cpi_erogato.
    "inzio mf 25/11/2011
    CONDENSE ps_header-importo_premio_cpi_erogato  NO-GAPS.
    "fine mf 25/11/2011
    ps_header-imp_scoppio_incendio_erogato   = <fs_bdm_contract>-imp_scoppio_incendio_erogato.
    "inzio mf 25/11/2011
    CONDENSE ps_header-imp_scoppio_incendio_erogato  NO-GAPS.
    "fine mf 25/11/2011
    ps_header-spese_istruttoria              = <fs_bdm_contract>-spese_istruttoria.
    "inzio mf 29/11/2011
    CONDENSE ps_header-spese_istruttoria  NO-GAPS.
    "fine mf 29/11/2011
    ps_header-costo_garanzia                 = <fs_bdm_contract>-costo_garanzia.
    "inzio mf 29/11/2011
    CONDENSE ps_header-costo_garanzia  NO-GAPS.
    "fine mf 29/11/2011
    ps_header-tipo_tasso_erogato             = <fs_bdm_contract>-tipo_tasso_erogato.
    IF <fs_bdm_contract>-data_scadenza_finanziamento IS NOT INITIAL."add mf 25/11/2011
      ps_header-data_scadenza_finanziamento    = <fs_bdm_contract>-data_scadenza_finanziamento.
    ENDIF."add mf 25/11/201
    ps_header-id_contratto_glm               = <fs_bdm_contract>-id_contratto_glm.
    ps_header-id_preventivo_glm              = <fs_bdm_contract>-id_preventivo.
    ps_header-id_preventivo                  = <fs_bdm_contract>-id_preventivo.
*    ps_header-polizza_scoppio_incendio       = <fs_bdm_contract>-polizza_scop_inc."add mf 30/11/2011
*    ps_header-polizza_cpi                    = <fs_bdm_contract>-presenza_cpi."add mf 30/11/2011
* VPM 24.01.2012 inizio
*    ps_header-importo_premio_cpi             = <fs_bdm_contract>-importo_cpi.
*    ps_header-imp_premio_scoppio_incendio    = <fs_bdm_contract>-imp_pr_scop_inc.
    CONDENSE ps_header-importo_premio_cpi  NO-GAPS.
    CONDENSE ps_header-imp_premio_scoppio_incendio  NO-GAPS.
* VPM 24.01.2012 fine

    READ TABLE i_leggi_prev_app WITH KEY id_preventivo = <fs_bdm_contract>-id_preventivo  ASSIGNING <fs_leggi_prev_app>.
    IF sy-subrc IS INITIAL.
      ps_header-tipo_tasso_richiesto           = <fs_leggi_prev_app>-tipo_tasso_richiesto.
      ps_header-polizza_cpi                    = <fs_leggi_prev_app>-presenza_cpi.
* VPM 24.01.2012 inizio
      ps_header-importo_premio_cpi             = <fs_leggi_prev_app>-importo_cpi.
* VPM 24.01.2012 fine
      "inzio mf 25/11/2011

      "fine mf 25/11/2011
      ps_header-polizza_scoppio_incendio       = <fs_leggi_prev_app>-polizza_scop_inc.
* VPM 24.01.2012 inizio
      ps_header-imp_premio_scoppio_incendio    = <fs_leggi_prev_app>-imp_pr_scop_inc.
* VPM 24.01.2012 fine
      "inzio mf 25/11/2011

      "fine mf 25/11/2011
    ENDIF.


* Begin AG 04.11.2011
* Lettura descrizioni
* VPM 24.01.2012 inizio
    CONSTANTS: lc_applicazione TYPE zappl VALUE 'BDM_CONFIGURAZIONE2'.
    DATA: prod            TYPE comt_product_id,
          lt_return       TYPE bapiret2 OCCURS 0,
          lt_ptb_products TYPE zts_ptb_products OCCURS 0,
          lw_ptb_products LIKE LINE OF lt_ptb_products,
          lv_prod         TYPE zts_ptb_products-product_id_edwh.

    prod = <fs_bdm_contract>-prodotto.

    CALL FUNCTION 'Z_CA_BDM_GET_PRODUCTS'
      EXPORTING
        i_applicazione = lc_applicazione
*       I_PRODS_LAVS   =
*       I_PRODUCT_GUID =
        i_product_id   = prod
*       I_PRODUCT_ID_EDWH =
      TABLES
        return         = lt_return
        ptb_products   = lt_ptb_products.

    READ TABLE lt_ptb_products INTO lw_ptb_products INDEX 1.
    lv_prod = lw_ptb_products-product_id_edwh.
* VPM 24.01.2012 fine
    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY product_id = lv_prod
               code  = gc_tipo_tasso
               value = ps_header-tipo_tasso_richiesto
      BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ps_header-tipo_tasso_richiesto_des = <fs_zca_bdm_pddlb>-description.
    ELSE.
      ps_header-tipo_tasso_richiesto_des =  ps_header-tipo_tasso_richiesto.
    ENDIF.

    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY product_id = lv_prod
               code  = gc_durata
               value = ps_header-dur_finanziamento_deliberato
      BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ps_header-durata_finanziamento_del_des = <fs_zca_bdm_pddlb>-description.
    ELSE.
      ps_header-durata_finanziamento_del_des = ps_header-dur_finanziamento_deliberato.
    ENDIF.

    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY product_id = lv_prod
               code  = gc_periodicita
               value = ps_header-periodicita_rata_deliberata
      BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ps_header-periodicita_rata_del_des = <fs_zca_bdm_pddlb>-description.
    ELSE.
      ps_header-periodicita_rata_del_des = ps_header-periodicita_rata_deliberata.
    ENDIF.

    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY product_id = lv_prod
               code  = gc_tipo_tasso
               value = ps_header-tipo_tasso_erogato
      BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ps_header-tipo_tasso_erogato_des = <fs_zca_bdm_pddlb>-description.
    ELSE.
      ps_header-tipo_tasso_erogato_des = ps_header-tipo_tasso_erogato.
    ENDIF.

* End   AG 04.11.2011
  ENDIF.

  READ TABLE i_bdm_crif WITH KEY guid_contratto = ps_guid-guid ASSIGNING <fs_bdm_crif>.
  IF sy-subrc IS INITIAL.
    ps_header-codice_crif           = <fs_bdm_crif>-codice_crif. "VPM-21.03.2012
    ps_header-esito_pre_screening   = <fs_bdm_crif>-esito_pre_screen.
    ps_header-codice_esito_sco      = <fs_bdm_crif>-codice_esito_sco.
    ps_header-desc_esito_score      = <fs_bdm_crif>-desc_esito_score.
    ps_header-probabilita_defa      = <fs_bdm_crif>-probabilita_defa.
    ps_header-classe                = <fs_bdm_crif>-classe.
  ENDIF.

*  fine modifica mf 16/09/2011


* FINE MODIFICA AS DEL 11.05.2011 15:10:08
  IF NOT ls_customer_h-zz_motivazione IS INITIAL.

    READ TABLE gt_nop_motivo ASSIGNING <fs_nop_motivo>
    BINARY SEARCH WITH KEY motivo = ls_customer_h-zz_motivazione.

    IF sy-subrc IS INITIAL.
      CONCATENATE <fs_nop_motivo>-katalogart
                  <fs_nop_motivo>-codegruppe
                  <fs_nop_motivo>-code
                  INTO ps_header-risultato.
    ENDIF.

  ENDIF.

  lv_count = 1.
  READ TABLE i_text TRANSPORTING NO FIELDS WITH KEY ref_guid = ps_guid-guid
                                                    BINARY SEARCH.
  LOOP AT i_text ASSIGNING <fs_text> FROM sy-tabix.
    IF <fs_text>-ref_guid NE ps_guid-guid
      OR lv_count = 3.
      EXIT.
    ENDIF.

    "Inizio modifiche - GC 23.07.2009 17:22:43
*    CONCATENATE  ps_header-note <fs_text>-tdline
*           INTO  ps_header-note
*    SEPARATED BY space.
*    ADD 1 TO lv_count.

    IF <fs_text>-tdid IN gr_note.
      CONCATENATE  ps_header-note <fs_text>-tdline
         INTO  ps_header-note
      SEPARATED BY space.
      ADD 1 TO lv_count.
    ENDIF.
    "Fine   modifiche - GC 23.07.2009 17:22:43
  ENDLOOP.

  CLEAR: lv_timestamp, lv_datlo, lv_timlo.
  lv_timestamp = <fs_header>-created_at.
  CALL FUNCTION 'IB_CONVERT_FROM_TIMESTAMP'
    EXPORTING
      i_timestamp = lv_timestamp
    IMPORTING
      e_datlo     = lv_datlo
      e_timlo     = lv_timlo.

  ps_header-crdate = lv_datlo.
  ps_header-crtime = lv_timlo.

  CLEAR: lv_timestamp, lv_datlo, lv_timlo.
  lv_timestamp = <fs_header>-changed_at.
  CALL FUNCTION 'IB_CONVERT_FROM_TIMESTAMP'
    EXPORTING
      i_timestamp = lv_timestamp
    IMPORTING
      e_datlo     = lv_datlo
      e_timlo     = lv_timlo.

  ps_header-chdate = lv_datlo.
  ps_header-chtime = lv_timlo.

  READ TABLE i_doc_flow ASSIGNING <fs_doc_flow> WITH KEY ref_guid = ps_guid-guid
                                                         BINARY SEARCH.
  IF sy-subrc IS INITIAL.

    READ TABLE i_prec_doc ASSIGNING <fs_prec_doc> WITH KEY guid = <fs_doc_flow>-objkey_a
                                                           BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ps_header-doc_precedente  = <fs_prec_doc>-object_id.
      ps_header-tipo_doc_prec   = <fs_prec_doc>-object_type.
    ENDIF.

  ENDIF.


* ADD MA 27.09.2010 Gestione campi contratti PTB

  CLEAR ls_cod_contr.
  READ TABLE gt_cod_contr WITH KEY guid = ps_guid INTO ls_cod_contr.
  IF sy-subrc = 0.
    ps_header-conto_contrattuale  = ls_cod_contr-cod_contr.
  ENDIF.

*Inizio modifica RS 26.10.2011
  READ TABLE lt_acp WITH KEY z_val_par = ps_header-tipo_contratto
                    TRANSPORTING NO FIELDS.

  IF sy-subrc = 0.
    ps_header-conto_contrattuale  = ls_customer_h-zz_cod_ccontratt.
  ENDIF.
*Fine modifica RS 26.10.2011

  ps_header-mod_pagamento       = ls_customer_h-zz_mod_pagamento.
  ps_header-deroga              = ls_customer_h-zz_codice_deroga.
  ps_header-iban                = ls_customer_h-zz_iban.
  ps_header-mezzo_pagamento     = ls_customer_h-zz_mezzo_pagam.
  ps_header-interessi_mora      = ls_customer_h-zz_inter_mora.
  ps_header-termini_pagamento   = ls_customer_h-zz_termini_pag.
  ps_header-zzinvio_fatt        = ls_customer_h-zz_invio_fattura.
  ps_header-pick_up             = ls_customer_h-zz_pick_up.
  ps_header-aggregazione        = ls_customer_h-zz_aggr_fattura.
  ps_header-per_fatturazione    = ls_customer_h-zz_period_fatt.
  ps_header-durata_cons_sostit  = ls_customer_h-zz_dur_cons_sost.


  IF ls_customer_h-zz_can_erogaz IS INITIAL.
    CLEAR: lv_parametro, ls_can_erogaz.
    CONCATENATE lc_can_erog ps_header-tipo_contratto INTO lv_parametro.
    READ TABLE gt_can_erogaz WITH KEY z_nome_par = lv_parametro INTO ls_can_erogaz.
    IF sy-subrc = 0.
      ps_header-canale_erogazione = ls_can_erogaz-z_val_par.
    ENDIF.
  ELSE.
    ps_header-canale_erogazione   = ls_customer_h-zz_can_erogaz.
  ENDIF.

  ps_header-per_servizio        = ls_customer_h-zz_period_sett.
  ps_header-altra_per_servizio  = ls_customer_h-zz_altra_period.
  ps_header-totale_lavorazioni  = ls_customer_h-zz_totale_lavor.
* END ADD MA 27.09.2010 Gestione campi contratti PTB
* ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
  ps_header-tipo_doc            = ls_customer_h-zzcustomer_h2301.
  ps_header-numero_doc          = ls_customer_h-zzcustomer_h2302.

  IF ls_customer_h-zzcustomer_h2304 <> '00000000'.
    ps_header-data_val            = ls_customer_h-zzcustomer_h2304.
  ENDIF.

  ps_header-rilasc_doc          = ls_customer_h-zzcustomer_h2306.
  ps_header-ente_rilas          = ls_customer_h-zzcustomer_h2303.
  ps_header-ente_spec           = ls_customer_h-zzcustomer_h2305.
* END ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte

  ps_header-zz_tipologia      = ls_customer_h-zz_tipologia.  "TP 21.04.2016

  ps_header-sede_lav          = ls_customer_h-zz_sede_lav.  "ADD CL - 03.06.2013 - Delete CL - 13.06.2013 "Ripristino 21.11.2017


* Iniziativa 106592 - Nuovi campi MAAF - Start
  DATA: ls_partner TYPE bapibus20001_partner_dis,
        lv_partner TYPE bu_partner.

  IF <fs_header>-process_type EQ 'ZMAF'.


    "Inizio mferrara - NOP_014 - 10/08/2015
    IF ls_customer_h-zz_totale_prezzo IS NOT INITIAL.
      ps_header-maaf_imp_affidato   = ls_customer_h-zz_totale_prezzo.
    ENDIF.

    CLEAR lv_data_maaf.

    IF ls_customer_h-zz_durata_anni IS NOT INITIAL.
      lv_data_maaf = ls_customer_h-zz_durata_anni.
      ps_header-maaf_durata_plafond = lv_data_maaf.
    ENDIF.

    READ TABLE i_appointment
    ASSIGNING <fs_appointment> WITH KEY ref_guid  = ps_guid-guid
                                        appt_type = ca_z_scad_pl
                                        BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      IF <fs_appointment>-date_from <> '00000000'.    "ADD MA 27.09.2010
        ps_header-maaf_scad_plafond = <fs_appointment>-date_from.
      ENDIF.
    ENDIF.

    "Inizio mferrara 10/08/2015 - NOP_014
*    CLEAR lv_date_3.
*    READ TABLE i_order_index ASSIGNING <fs_index> WITH KEY header = ps_guid-guid BINARY SEARCH.
*    IF sy-subrc IS INITIAL.
*      CONVERT TIME STAMP <fs_index>-date_3 TIME ZONE sy-zonlo INTO DATE lv_date_3.
*      ps_header-maaf_scad_plafond = lv_date_3.
*    ENDIF.
    "Fine mferrara 10/08/2015 - NOP_014

    CLEAR ps_header-maaf_mail_fatt.
    IF NOT ls_customer_h-zz_ind_fatt IS INITIAL.
      SELECT SINGLE smtp_addr INTO ps_header-maaf_mail_fatt
        FROM adr6
       WHERE addrnumber EQ ls_customer_h-zz_ind_fatt.
    ENDIF.

    CLEAR: ls_partner,
           lv_partner,
           ps_header-maaf_cod_ipa.
    READ TABLE i_partner INTO ls_partner WITH KEY ref_guid    = <fs_header>-guid
                                                  partner_fct = '00000001'.
    IF sy-subrc IS INITIAL.
      MOVE ls_partner-partner_no TO lv_partner.

      "Inizio Adeguamento Codice IPA GV 07.12.2015
      "Inizio COMM GV 07.12.2015
*      SELECT SINGLE zzfld000017 INTO ps_header-maaf_cod_ipa
*        FROM but000
*       WHERE partner     EQ lv_partner
*         AND zzfld000017 NE space.
      "Fine COMM GV 07.12.2015

      SELECT SINGLE idnumber
        FROM but0id
        INTO ps_header-maaf_cod_ipa
        WHERE partner EQ lv_partner
        AND type = 'ZIPA'.
      "Fine Adeguamento Codice IPA GV 07.12.2015
      " Inizio Mod. MN - Gestione temp. codice ufficio - 22.11.2018
      READ TABLE gt_bpkind ASSIGNING FIELD-SYMBOL(<bpkind>) WITH KEY partner = lv_partner.
      IF sy-subrc IS INITIAL.
        CASE <bpkind>-bpkind.
          WHEN 'ZPRI'.
            " Sbianco sempre il codice ufficio per segmenti privati
            CLEAR ls_customer_h-zz_codice_uff.
          WHEN OTHERS.
            " Per altri segmenti sbianco il codice ufficio se maggiore di 6
            CONDENSE ls_customer_h-zz_codice_uff NO-GAPS.
            IF strlen( ls_customer_h-zz_codice_uff ) GT 6.
              CLEAR ls_customer_h-zz_codice_uff.
            ENDIF.
        ENDCASE.
      ENDIF.
      " Fine Mod. MN - Gestione temp. codice ufficio - 22.11.2018

    ENDIF.

    " Inizio Mod. MN - Gestione temp. codice ufficio - 22.11.2018
*    READ TABLE i_partner ASSIGNING FIELD-SYMBOL(<partner>) WITH KEY ref_guid    = ps_guid-guid
*                                                                    partner_fct = '00000001'.
*    IF sy-subrc IS INITIAL.
*      MOVE <partner>-partner_no TO lv_committente.
*
*      READ TABLE gt_bpkind ASSIGNING FIELD-SYMBOL(<bpkind>) WITH KEY partner = lv_committente.
*      IF sy-subrc IS INITIAL.
*        CASE <bpkind>-bpkind.
*          WHEN 'ZPRI'.
*            " Sbianco sempre il codice ufficio per segmenti privati
*            CLEAR ls_customer_h-zz_codice_uff.
*          WHEN OTHERS.
*            " Per altri segmenti sbianco il codice ufficio se maggiore di 6
*            CONDENSE ls_customer_h-zz_codice_uff NO-GAPS.
*            IF strlen( ls_customer_h-zz_codice_uff ) GT 6.
*              CLEAR ls_customer_h-zz_codice_uff.
*            ENDIF.
*        ENDCASE.
*      ENDIF.
*    ENDIF.
    " Fine Mod. MN - Gestione temp. codice ufficio - 22.11.2018

    MOVE: ls_customer_h-zz_codice_uff TO ps_header-maaf_cod_uff.

    PERFORM: maaf_field    USING <fs_header>-object_id
                                 'MATRI'
                        CHANGING ps_header-maaf_matri,

             maaf_field    USING <fs_header>-object_id
                                 'ZZIMA'
                        CHANGING ps_header-maaf_zzima,


             maaf_field    USING <fs_header>-object_id
                                 'VIA'
                        CHANGING ps_header-maaf_via,

             maaf_field    USING <fs_header>-object_id
                                 'NUM'
                        CHANGING ps_header-maaf_civico,

             maaf_field    USING <fs_header>-object_id
                                 'CITY'
                        CHANGING ps_header-maaf_citta,

             maaf_field    USING <fs_header>-object_id
                                 'PROV'
                        CHANGING ps_header-maaf_provincia,

             maaf_field    USING <fs_header>-object_id
                                 'CAP'
                        CHANGING ps_header-maaf_cap,

             maaf_field    USING <fs_header>-object_id
                                 'MY_SEND'
                        CHANGING ps_header-maaf_affr_propri,

             maaf_field    USING <fs_header>-object_id
                                 'TERZI_SEND'
                        CHANGING ps_header-maaf_affr_terzi.

*  ENDIF.
* Iniziativa 106592 - Nuovi campi MAAF - End
"Inizio RU 18.11.2019 18:36:25  gestione campi per zprocess diverso da ZMAF.
  ELSE.
    ps_header-maaf_imp_affidato   = ls_customer_h-zz_totale_prezzo.

    "quanto segue per estrarre la mail di fatturazione
*    CLEAR ps_header-maaf_mail_fatt.
*    IF NOT ls_customer_h-zz_ind_fatt IS INITIAL.
*      SELECT SINGLE smtp_addr INTO ps_header-maaf_mail_fatt
*        FROM adr6
*       WHERE addrnumber EQ ls_customer_h-zz_ind_fatt.
*    ENDIF.
  ENDIF.
"Fine RU 18.11.2019 18:36:30


* 105900 : Inizio modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file
  READ TABLE i_dati_agg_fa ASSIGNING <fs_dati_agg_fa> WITH KEY  parent_id = ps_guid-guid.
  IF sy-subrc EQ 0.
    ps_header-carte_credito      = <fs_dati_agg_fa>-zz_visa_maestro.
    ps_header-carte_pagobancomat = <fs_dati_agg_fa>-zz_pagobancomat.
    ps_header-carte_postamat     = <fs_dati_agg_fa>-zz_postamat.
    ps_header-mod_accredito      = <fs_dati_agg_fa>-zz_mod_pag.
    ps_header-rich_format_cart   = <fs_dati_agg_fa>-zz_rend_cart.
    ps_header-zz_strum_regolam   = <fs_dati_agg_fa>-zz_strum_regolam.
    ps_header-zz_liv_acc_add     = <fs_dati_agg_fa>-zz_liv_acc_add.
    ps_header-zz_iban_acc        = <fs_dati_agg_fa>-zz_iban_acc.
    ps_header-classe             = <fs_dati_agg_fa>-zz_mot_reinoltro.

* 105900: ASTERISCATO IN ATTESA DEL PASSAGGIO DI FA FASE 2 - INIZIO
*    IF <fs_dati_agg_fa>-zz_bus_eserc_con EQ 'P'.
**    ps_header-primo_convenzionamento = <fs_dati_agg_fa>-zz_bus_eserc_con.
*      ps_header-primo_convenzionamento = 'X'.
*    ENDIF.
*    IF <fs_dati_agg_fa>-zz_bus_eserc_con EQ 'N'.
**    ps_header-gia_convenzionato      = <fs_dati_agg_fa>-zz_bus_eserc_con.
*      ps_header-gia_convenzionato = 'X'.
*    ENDIF.
*    ps_header-tipo_esercente         = <fs_dati_agg_fa>-zz_bus_eserc_tip.
*    ps_header-stagionale             = <fs_dati_agg_fa>-zz_bus_eserc_sta.
*    ps_header-periodo_apertura       = <fs_dati_agg_fa>-zz_bus_eserc_per.
* 105900: ASTERISCATO IN ATTESA DEL PASSAGGIO DI FA FASE 2 - FINE.
  ENDIF.
* 105900 : fine   modifica del 23.08.2016 -  TM - aggiunti campi nel tracciato file


ENDFORM.                    " f_prepara_header
*&---------------------------------------------------------------------*
*&      Form  f_prepara_prodotti
*&---------------------------------------------------------------------*
*   Prepara i record Prodotti
*----------------------------------------------------------------------*
FORM f_prepara_prodotti  USING    ps_guid          TYPE bapibus20001_guid_dis
                                  ps_header        TYPE t_header
                         CHANGING pt_prodotti      TYPE t_prodotti_tab
                                  pt_customer_i    TYPE t_customer_i_tab    "ADD GC 23/07/09
                                  pt_mod_stato_pos TYPE t_mod_stato_pos_tab "ADD GC 23/07/09
                                  pf_error         TYPE c.

  DATA: ls_prodotti TYPE t_prodotti,
        lv_codice   TYPE string,
        lv_guid     TYPE sysuuid-x.

  FIELD-SYMBOLS: <fs_item>          TYPE bapibus20001_item_dis,
                 <fs_product_list>  TYPE bapibus20001_product_list_dis,
                 <fs_status>        TYPE bapibus20001_status_dis,
                 <fs_schedule_item> TYPE bapibus20001_schedlin_item_dis,
                 <fs_customer_i>    LIKE LINE OF pt_customer_i, "ADD GC 23/07/09
                 <fs_leggi_prev>    TYPE t_leggi_prev, "add mf 04/10/2011
                 <fs_bdm_contract>  TYPE t_bdm_contract.


  "Inizio modifiche - GC 24.07.2009 14:50:30
  DATA: ls_mod_stato_pos  TYPE t_mod_stato_pos.

  FIELD-SYMBOLS: <fs_mod_stato> LIKE LINE OF gt_crm_jcds.
  "Fine   modifiche - GC 24.07.2009 14:50:30

* Begin AG 06.02.2014
* BUNDLE_09
  DATA: gs_zca_cod_promo_bu TYPE zca_cod_promo_bu.


  DATA: ls_header TYPE bapibus20001_header_dis.

  READ TABLE i_header INTO ls_header WITH KEY guid = ps_guid-guid
                                                     BINARY SEARCH.
* End   AG 06.02.2014


  REFRESH: pt_prodotti[], pt_mod_stato_pos[].
  READ TABLE i_item TRANSPORTING NO FIELDS WITH KEY header = ps_guid-guid.

  LOOP AT i_item ASSIGNING <fs_item> FROM sy-tabix.

    CLEAR ls_prodotti.
    IF <fs_item>-header NE ps_guid-guid.
      EXIT.
    ENDIF.

* 105900: inizio modifica del 05.09.2016 - tm
    IF NOT <fs_item>-description_uc IN gr_zfac.

      ls_prodotti-tipo_record     = ca_pp.
      ls_prodotti-codice_crm      = ps_header-codice_crm.
      ls_prodotti-tipo_posizione  = <fs_item>-itm_type.

*    IF ls_prodotti-tipo_posizione IS INITIAL.
**     -- Scrittura Record di Log
*      CLEAR lv_codice.
*      lv_codice = ps_header-codice_crm.
*      PERFORM f_scrivi_error USING lv_codice
*                                   text-e20.
*      pf_error = ca_x.
*      EXIT.
*    ENDIF.

      ls_prodotti-id_pos          = <fs_item>-number_int.

      IF ls_prodotti-id_pos IS INITIAL.
*     -- Scrittura Record di Log
        CLEAR lv_codice.
        lv_codice = ps_header-codice_crm.
        PERFORM f_scrivi_error USING lv_codice
                                     text-e21.
        pf_error = ca_x.
        EXIT.
      ENDIF.

      ls_prodotti-id_pos_padre    = <fs_item>-number_parent.
      "Inizio modifiche - GC 27.07.2009 09:43:22

      IF ps_header-classe_documento EQ gv_contratti.
        READ TABLE i_product_list ASSIGNING <fs_product_list> WITH KEY guid = <fs_item>-guid
                                                                       BINARY SEARCH.
        IF sy-subrc IS INITIAL.
          ls_prodotti-prodotto_bic = <fs_product_list>-product_id.
        ENDIF.
      ELSE.
        ls_prodotti-prodotto_bic = <fs_item>-description.
      ENDIF.
      "Fine   modifiche - GC 27.07.2009 09:43:22

*    IF ls_prodotti-prodotto_bic IS INITIAL.
**     -- Scrittura Record di Log
*      CLEAR lv_codice.
*      lv_codice = ps_header-codice_crm.
*      PERFORM f_scrivi_error USING lv_codice
*                                   text-e22.
*      pf_error = ca_x.
*      EXIT.
*    ENDIF.

      READ TABLE i_schedule_item ASSIGNING <fs_schedule_item> WITH KEY guid = <fs_item>-guid
                                                                       BINARY SEARCH.
      IF sy-subrc IS INITIAL.
        ls_prodotti-quantita = <fs_schedule_item>-order_qty.
      ENDIF.

      READ TABLE i_status ASSIGNING <fs_status> WITH KEY guid         = <fs_item>-guid
                                                       kind           = ca_b " Modifica AG - 16.12.2009 17:43:59
                                                       status(1)      = ca_e " Modifica AG - 16.12.2009 17:44:10
                                                       active         = ca_x
                                                       BINARY SEARCH.

      IF sy-subrc IS INITIAL AND <fs_status>-user_stat_proc IN gr_stai.
*      ls_prodotti-stato_prodotto = <fs_status>-status.
        CONCATENATE <fs_status>-user_stat_proc <fs_status>-status INTO ls_prodotti-stato_prodotto.
      ENDIF.

*    IF ls_prodotti-stato_prodotto IS INITIAL.
**     -- Scrittura Record di Log
*      CLEAR lv_codice.
*      lv_codice = ps_header-codice_crm.
*      PERFORM f_scrivi_error USING lv_codice
*                                   text-e23.
*      pf_error = ca_x.
*      EXIT.
*    ENDIF.

      "Inizio modifiche - GC 24.07.2009 10:22:20
      CLEAR lv_guid.
      CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
        EXPORTING
          i_guid32 = <fs_item>-guid
        IMPORTING
          e_guid16 = lv_guid.

      READ TABLE pt_customer_i ASSIGNING <fs_customer_i>
      WITH KEY guid = lv_guid.
      IF sy-subrc EQ 0.
        ls_prodotti-descrizione_lavorazione = <fs_customer_i>-zz_descr_lavor_i.
        ls_prodotti-tipo_lavorazione        = <fs_customer_i>-zz_lavorazione_i.
        ls_prodotti-categoria_motivazione   = <fs_customer_i>-zz_cat_motivaz_i.
        ls_prodotti-motivazione             = <fs_customer_i>-zz_motivaz_nor_i.
        ls_prodotti-codice_promozione       = <fs_customer_i>-zz_cod_promo.

* Begin AG 06.02.2014
* BUNDLE_09
* nel caso di contratto Selezione Impresa e prodotto in promozione accedere alla
* ZCA_PARAM con gruppo parametri 'PRMI' e applicazione ZCAE_EDWHAE_CONTRATTI:
* Verificare se il valore del process type della pratica (CRMD_ORDERADM_H-PROC_TYPE)
* è contenuto nel gruppo parametri....
        READ TABLE gt_prmi TRANSPORTING NO FIELDS
          WITH KEY z_val_par = ls_header-process_type.
        IF sy-subrc IS INITIAL.
          CLEAR ls_prodotti-codice_promozione.
* ...se presente, accedere alla tabella ZCA_COD_PROMO_BU con
* GUID = CRMD_ORDERADM_H-GUID,
* PRODUCT_ID = PRODOTTO_BIC (precedentemente estratto),
* ATTIVATO = X
          CLEAR gs_guid_header.
          READ TABLE gt_guid_header INTO gs_guid_header
            WITH KEY guid32 = ps_guid-guid.
          IF gs_guid_header-guid16 IS NOT INITIAL.
            CLEAR gs_zca_cod_promo_bu.
            READ TABLE gt_zca_cod_promo_bu INTO gs_zca_cod_promo_bu
              WITH KEY product_id = ls_prodotti-prodotto_bic
                       guid       = gs_guid_header-guid16
                       attivato   = ca_x.
            IF sy-subrc IS INITIAL.
              ls_prodotti-codice_promozione = gs_zca_cod_promo_bu-codice_promo.
            ENDIF.
          ENDIF.
        ENDIF.
* End   AG 06.02.2014


* ADD MA 27.09.2010 Gestione campi contratti PTB
        ls_prodotti-id_prodotto_esterno     = <fs_customer_i>-zz_id_prod_ext.
        ls_prodotti-promozione              = <fs_customer_i>-zz_codice_promoz.
*      ls_prodotti-quantita_annua          = <fs_customer_i>-zz_ytd_quantity. "Modifica RS 26.10.2011
        ls_prodotti-prezzo_per_unita        = <fs_customer_i>-zz_net_pr_unit.
*      ls_prodotti-importo_totale          = <fs_customer_i>-zz_total_value. "Modifica RS 26.10.2011
        ls_prodotti-quantita_max_per_ord    = <fs_customer_i>-zz_qmax_perorder.
        ls_prodotti-frequenza_invio         = <fs_customer_i>-zz_shipping_freq.
* END ADD MA 27.09.2010 Gestione campi contratti PTB

* INIZIO MODIFICA AS DEL 20.04.2011
* Begin AG 22.03.2011 18:17:18
*      ls_prodotti-zz_cell_fdr             = <fs_customer_i>-zz_cell_fdr.
*      ls_prodotti-zz_code_resp            = <fs_customer_i>-zz_code_resp.
*      ls_prodotti-zz_code_chall           = <fs_customer_i>-zz_code_chall.
*      ls_prodotti-zz_code_sms_otp         = <fs_customer_i>-zz_code_sms_otp.
* End   AG 22.03.2011 18:17:18


*Inizio modifica RS 26.10.2011
        READ TABLE lt_acp WITH KEY z_val_par = ps_header-tipo_contratto
                          TRANSPORTING NO FIELDS.

        IF sy-subrc = 0.
          ls_prodotti-quantita_annua          = <fs_customer_i>-zz_qta_effettiva.

          IF NOT <fs_customer_i>-zz_imp_eff_niva IS INITIAL.
            ls_prodotti-importo_totale          = <fs_customer_i>-zz_imp_eff_niva.
          ELSEIF NOT <fs_customer_i>-zz_imp_eff_liva IS INITIAL.
            ls_prodotti-importo_totale          = <fs_customer_i>-zz_imp_eff_liva.
          ENDIF.

        ELSE.
          ls_prodotti-quantita_annua          = <fs_customer_i>-zz_ytd_quantity.
          ls_prodotti-importo_totale          = <fs_customer_i>-zz_total_value.
        ENDIF.
*Fine modifica RS 26.10.2011


        ls_prodotti-zz_cell_fdr             = <fs_customer_i>-zz_cell_fdr.

        IF     <fs_customer_i>-zz_code_resp  IS NOT INITIAL
           AND <fs_customer_i>-zz_code_chall IS NOT INITIAL.
          ls_prodotti-flag_pcr = ca_x.
        ENDIF.

        IF <fs_customer_i>-zz_code_sms_otp  IS NOT INITIAL.
          ls_prodotti-flag_sms_otp = ca_x.
        ENDIF.

        IF     <fs_customer_i>-zz_code_resp    IS INITIAL
           AND <fs_customer_i>-zz_code_chall   IS INITIAL
           AND <fs_customer_i>-zz_code_sms_otp IS INITIAL.
          ls_prodotti-flag_up = ca_x.
        ENDIF.
* FINE MODIFICA AS DEL 20.04.2011

        ls_prodotti-promozione_web = <fs_customer_i>-zz_cod_promo_web." Add AS 15.05.2012

      ELSE.
        ls_prodotti-flag_up = ca_x.
      ENDIF.
      "Fine   modifiche - GC 24.07.2009 10:22:20

      "inizio mf  04/10/2011
      READ TABLE i_bdm_contract ASSIGNING <fs_bdm_contract> WITH KEY contract_guid = ps_guid-guid.
      IF sy-subrc IS INITIAL.
* inizio VPM 24.01.2012
*      ls_prodotti-importo_richiesto = <fs_bdm_contract>-importo_richiesto.
        "inzio mf 25/11/2011
*      CONDENSE ls_prodotti-importo_richiesto  NO-GAPS.
        "fine mf 25/11/2011
        ls_prodotti-importo_totale = <fs_bdm_contract>-importo_richiesto.
        CONDENSE ls_prodotti-importo_totale  NO-GAPS.
* fine VPM 24.01.2012
        READ TABLE i_leggi_prev_app ASSIGNING <fs_leggi_prev> WITH KEY id_preventivo = <fs_bdm_contract>-id_preventivo.
        IF sy-subrc IS INITIAL.
          ls_prodotti-convenzione = <fs_leggi_prev>-convenzione.
          ls_prodotti-durata_finanziamento_richiesto = <fs_leggi_prev>-durata_fin_ric.
          ls_prodotti-periodicita_richiesta = <fs_leggi_prev>-periodicita_ric.
          ls_prodotti-numero_rate_richieste = <fs_leggi_prev>-n_rate_ric.
          ls_prodotti-piano_ammortamento    = <fs_leggi_prev>-tipo_piano_amm.
        ENDIF.
      ENDIF.
      "fine mf 04/10/2011

      APPEND ls_prodotti TO pt_prodotti.

      "Inizio modifiche - GC 24.07.2009 14:49:27
* ============================================*
*             Posizioni mod stato             *
* ============================================*

*    REFRESH pt_mod_stato_pos.

      READ TABLE gt_crm_jcds TRANSPORTING NO FIELDS WITH KEY objnr = lv_guid.

      LOOP AT gt_crm_jcds ASSIGNING <fs_mod_stato> FROM sy-tabix.

        CLEAR ls_mod_stato_pos.
        IF <fs_mod_stato>-objnr NE lv_guid.
          EXIT.
        ENDIF.

        ls_mod_stato_pos-tipo_record  = ca_mp.
        ls_mod_stato_pos-codice_crm   = ps_header-codice_crm.
        ls_mod_stato_pos-id_pos       = <fs_item>-number_int.

        IF ls_mod_stato_pos-id_pos IS INITIAL.
*       -- Scrittura Record di Log
          CLEAR lv_codice.
          lv_codice = ps_header-codice_crm.
          PERFORM f_scrivi_error USING lv_codice
                                       text-e21.
          pf_error = ca_x.
          EXIT.
        ENDIF.

*      ls_mod_stato_pos-stato        = <fs_mod_stato>-stat.
        CONCATENATE <fs_status>-user_stat_proc <fs_mod_stato>-stat INTO ls_mod_stato_pos-stato.

        IF ls_mod_stato_pos-stato IS INITIAL.
*       -- Scrittura Record di Log
          CLEAR lv_codice.
          lv_codice = ps_header-codice_crm.
          PERFORM f_scrivi_error USING lv_codice
                                       text-e19.
          pf_error = ca_x.
          EXIT.
        ENDIF.

        ls_mod_stato_pos-udate        = <fs_mod_stato>-udate.

        IF ls_mod_stato_pos-udate IS INITIAL.
*       -- Scrittura Record di Log
          CLEAR lv_codice.
          lv_codice = ps_header-codice_crm.
          PERFORM f_scrivi_error USING lv_codice
                                       text-e32.
          pf_error = ca_x.
          EXIT.
        ENDIF.

        ls_mod_stato_pos-utime        = <fs_mod_stato>-utime.

        IF ls_mod_stato_pos-utime IS INITIAL.
*       -- Scrittura Record di Log
          CLEAR lv_codice.
          lv_codice = ps_header-codice_crm.
          PERFORM f_scrivi_error USING lv_codice
                                       text-e33.
          pf_error = ca_x.
          EXIT.
        ENDIF.

        ls_mod_stato_pos-user_id     = <fs_mod_stato>-usnam.

        APPEND ls_mod_stato_pos TO pt_mod_stato_pos.

      ENDLOOP.
      "Fine   modifiche - GC 24.07.2009 14:49:27
    ENDIF.
* 105900: fine modifica del 05.09.2016 - tm
  ENDLOOP.

ENDFORM.                    " f_prepara_prodotti
*&---------------------------------------------------------------------*
*&      Form  f_prepara_partner
*&---------------------------------------------------------------------*
*    Prepara i record Partner
*----------------------------------------------------------------------*
FORM f_prepara_partner  USING ps_guid    TYPE bapibus20001_guid_dis
                              ps_header  TYPE t_header
                     CHANGING pt_partner TYPE t_partner_tab
                              pf_error   TYPE c.

  DATA: ls_partner TYPE t_partner,
        lv_codice  TYPE string.

  FIELD-SYMBOLS: <fs_partner> TYPE bapibus20001_partner_dis.
  REFRESH pt_partner.

  READ TABLE i_partner TRANSPORTING NO FIELDS WITH KEY ref_guid = ps_guid-guid.

  LOOP AT i_partner ASSIGNING <fs_partner> FROM sy-tabix.

    CLEAR ls_partner.
    IF <fs_partner>-ref_guid NE ps_guid-guid.
      EXIT.
    ENDIF.

    ls_partner-tipo_record      = ca_fp.
    ls_partner-codice_crm       = ps_header-codice_crm.
    ls_partner-funzione_partner = <fs_partner>-partner_fct.

    IF ls_partner-funzione_partner IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e24.
      pf_error = ca_x.
      EXIT.
    ENDIF.

    ls_partner-partner          = <fs_partner>-partner_no.

    " Inizio AS 17.05.2012
    PERFORM set_classe_click USING ps_header-tipo_contratto
                                   ps_header-canale_provenienza
                                   ps_header-codice_crm
                                   ls_partner-funzione_partner
                          CHANGING ls_partner-classe_click.
    " Fine   AS 17.05.2012

    IF ls_partner-partner IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e25.
      pf_error = ca_x.
      EXIT.
    ENDIF.

    ls_partner-main_partner     = <fs_partner>-mainpartner.
    ls_partner-no_type     = <fs_partner>-no_type.

    APPEND ls_partner TO pt_partner.

  ENDLOOP.

ENDFORM.                    " f_prepara_partner
*&---------------------------------------------------------------------*
*&      Form  f_scrivi_record
*&---------------------------------------------------------------------*
*   Scrittura Record su File
*----------------------------------------------------------------------*
FORM f_scrivi_record  USING    ps_header          TYPE t_header
                               pt_prodotti        TYPE t_prodotti_tab
                               pt_partner         TYPE t_partner_tab
                               pt_mod_stato       TYPE t_mod_stato_tab
                               pt_mod_stato_pos   TYPE t_mod_stato_pos_tab "ADD GC 23/07/09
                               pt_cons_priv_contr TYPE t_cons_priv_contr_tab " Add AS 17.05.2012
                               pt_attr_dimens     TYPE t_attr_dimens_tab " Add AS 18.05.2012
                               pt_attr_acc        TYPE t_attr_acc_tab.   " TP 21.04.2016
  DATA: lv_line TYPE string.

  FIELD-SYMBOLS: <fs_partner>         TYPE t_partner,
                 <fs_prodotti>        TYPE t_prodotti,
                 <fs_mod_stato>       TYPE t_mod_stato,
                 <fs_attr_dimens>     TYPE t_attr_dimens, " Add AS 18.05.2012
                 <fs_cons_priv_contr> TYPE t_cons_priv_contr, " Add AS 29.05.2012
                 <fs_mod_stato_pos>   TYPE t_mod_stato_pos, "ADD GC 23/07/09
                 <fs_attr_acc>        TYPE t_attr_acc.      "TP 21.04.2016

* -- Scrittura Record di testata
  CLEAR lv_line.
  CONCATENATE  ps_header-tipo_record
               ps_header-codice_crm
               ps_header-descrizione
               ps_header-tipo_contratto
               ps_header-data_apertura
               ps_header-data_chiusura
               ps_header-stato
               ps_header-risultato
               ps_header-numero_conto
               ps_header-operazione
               ps_header-area
               ps_header-canale
               ps_header-note
               ps_header-doc_precedente
               ps_header-tipo_doc_prec
               ps_header-crdate
               ps_header-crtime
               ps_header-chdate
               ps_header-chtime
               ps_header-id_univoco
               ps_header-classe_documento
* Inizio modifiche - GC 23.07.2009 17:53:08
               ps_header-id_distinta
               ps_header-no_raccomandata
               ps_header-cod_convenzione
               ps_header-data_richiesta
               ps_header-ora_richiesta
               ps_header-data_invio_pratica
               ps_header-ora_invio_pratica
               ps_header-data_arrivo_pratica
               ps_header-ora_arrivo_pratica
               ps_header-data_inizio_lavorazione
               ps_header-ora_inizio_lavorazione
               ps_header-data_fine_lavorazione
               ps_header-ora_fine_lavorazione
* Fine modifiche - GC 23.07.2009 17:53:08
               ps_header-intest_part_rapporto
               ps_header-prod_in_promoz
               ps_header-tipo_firma
               ps_header-contratto_bonificato
               ps_header-zz_tipo_conto
* ADD MA 27.09.2010 Gestione campi contratti PTB
               ps_header-conto_contrattuale
               ps_header-mod_pagamento
               ps_header-deroga
               ps_header-iban
               ps_header-mezzo_pagamento
               ps_header-interessi_mora
               ps_header-termini_pagamento
               ps_header-zzinvio_fatt
               ps_header-pick_up
               ps_header-aggregazione
               ps_header-per_fatturazione
               ps_header-durata_cons_sostit
               ps_header-canale_erogazione
               ps_header-per_servizio
               ps_header-altra_per_servizio
               ps_header-totale_lavorazioni
* END ADD MA 27.09.2010 Gestione campi contratti PTB
* ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
               ps_header-tipo_doc
               ps_header-numero_doc
               ps_header-data_val
               ps_header-rilasc_doc
               ps_header-ente_rilas
               ps_header-ente_spec
* END ADD MA 18.01.2011 Gestione campi contratti Riconoscimento Forte
* Begin AG 22.03.2011 18:18:33
               ps_header-data_scadenza
* End   AG 22.03.2011 18:18:33
* INIZIO MODIFICA AS DEL 11.05.2011 15:08:13
              ps_header-regione_resid
              ps_header-frazionario
              ps_header-id_modulo_mise
* FINE MODIFICA AS DEL 11.05.2011 15:08:13
"INIZIO MF 03/10/2011
              ps_header-finalita_fin1
              ps_header-finalita_fin2
              ps_header-finalita_fin3
              ps_header-debito_res
              ps_header-mod_erogazione
              ps_header-mod_rimborso
              ps_header-tipo_tasso_richiesto_des
              ps_header-garanzia_fideiussoria
              ps_header-tipo_garanzia_richiesta
              ps_header-importo_garanzia_richiesta
              ps_header-polizza_cpi
              ps_header-importo_premio_cpi
              ps_header-polizza_scoppio_incendio
              ps_header-imp_premio_scoppio_incendio
              ps_header-data_delibera
              ps_header-importo_deliberato
              ps_header-durata_finanziamento_del_des
              ps_header-periodicita_rata_del_des
              ps_header-tipo_garanzia_deliberata1
              ps_header-importo_garanzia_deliberata1
              ps_header-denominazione_garante1
              ps_header-tipo_garanzia_deliberata2
              ps_header-importo_garanzia_deliberata2
              ps_header-denominazione_garante2
              ps_header-tipo_garanzia_deliberata3
              ps_header-importo_garanzia_deliberata3
              ps_header-denominazione_garante3
              ps_header-data_stipula_contratto
              ps_header-data_erogazione
              ps_header-importo_erogato
              ps_header-tasso_erogato
              ps_header-spread_erogato
              ps_header-taeg_erogato
              ps_header-importo_premio_cpi_erogato
              ps_header-imp_scoppio_incendio_erogato
              ps_header-spese_istruttoria
              ps_header-costo_garanzia
              ps_header-tipo_tasso_erogato_des
              ps_header-data_scadenza_finanziamento
              ps_header-id_preventivo
              ps_header-data_apertura_cc
              ps_header-correntista_bp
              ps_header-id_contratto_glm
              ps_header-id_preventivo_glm
              ps_header-esito_pre_screening
              ps_header-codice_esito_sco
              ps_header-desc_esito_score
              ps_header-probabilita_defa
              ps_header-classe
"FINE MF 03/10/2011
              ps_header-canale_provenienza " Add AS 16.03.2012
              ps_header-codice_crif "VPM-21.03.2012
              ps_header-data_sottoscrizi "VPM-21.03.2012
              ps_header-modalita "VPM-26.04.2012 GEC
" Inizio AS 15.05.2012
              ps_header-nickname
              ps_header-id_contratto_web
              ps_header-telefono_contatto
              ps_header-tipo_conto_origine
" Fine   AS 15.05.2012
* PLP-01 - Insert - Start
              ps_header-tipo_carta
              ps_header-ruolo
* PLP-01 - Insert - End


* Iniziativa 106592 - Nuovi campi MAAF - Start
              ps_header-maaf_mail_fatt
              ps_header-maaf_cod_uff
              ps_header-maaf_cod_ipa
              ps_header-maaf_matri
              ps_header-maaf_zzima
              ps_header-maaf_via
              ps_header-maaf_civico
              ps_header-maaf_citta
              ps_header-maaf_provincia
              ps_header-maaf_cap
              ps_header-maaf_affr_propri
              ps_header-maaf_affr_terzi
* Iniziativa 106592 - Nuovi campi MAAF - End
"iNIZIO mferrarA NOP_014 - 10/08/2015
              ps_header-maaf_imp_affidato
              ps_header-maaf_durata_plafond
              ps_header-maaf_scad_plafond
"Fine mferrarA NOP_014 - 10/08/2015

              ps_header-zz_tipologia "TP 21.04.2016
* 105900: inizio modifica del 23.08.2016  aggiunti nuovi campi
              ps_header-carte_credito
              ps_header-carte_pagobancomat
              ps_header-carte_postamat
              ps_header-rich_format_cart
              ps_header-mod_accredito
              ps_header-primo_convenzionamento
              ps_header-gia_convenzionato
              ps_header-tipo_esercente
              ps_header-stagionale
              ps_header-periodo_apertura
              ps_header-zz_strum_regolam
              ps_header-zz_liv_acc_add
              ps_header-zz_iban_acc
              ps_header-sede_lav "ADD CL 03.06.2013 - Delete CL - 13.06.2013 - Ripristino 21.11.2017
* 105900: inizio modifica del 23.08.2016

              INTO lv_line
              SEPARATED BY ca_pipe.
* 105900: inizio modifica del 29.09.2016 - eng
*  TRANSFER lv_line TO va_fileout.
  TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng
* -- Scrittura Record di Prodotti
  LOOP AT pt_prodotti ASSIGNING <fs_prodotti>.

    CLEAR lv_line.
    CONCATENATE <fs_prodotti>-tipo_record
                <fs_prodotti>-codice_crm
                <fs_prodotti>-tipo_posizione
                <fs_prodotti>-id_pos
                <fs_prodotti>-id_pos_padre
                <fs_prodotti>-prodotto_bic
                <fs_prodotti>-quantita
                <fs_prodotti>-stato_prodotto
"Inizio modifiche - GC 23.07.2009 17:59:28
                <fs_prodotti>-descrizione_lavorazione
                <fs_prodotti>-tipo_lavorazione
                <fs_prodotti>-categoria_motivazione
                <fs_prodotti>-motivazione
"Fine   modifiche - GC 23.07.2009 17:59:28
                <fs_prodotti>-codice_promozione
* ADD MA 27.09.2010 Gestione campi contratti PTB
                <fs_prodotti>-id_prodotto_esterno
                <fs_prodotti>-promozione
                <fs_prodotti>-quantita_annua
                <fs_prodotti>-prezzo_per_unita
                <fs_prodotti>-importo_totale
                <fs_prodotti>-quantita_max_per_ord
                <fs_prodotti>-frequenza_invio
* END ADD MA 27.09.2010 Gestione campi contratti PTB
* Begin AG 22.03.2011 18:19:00
* INIZIO MODIFICA AS DEL 20.04.2011

*                <fs_prodotti>-zz_code_chall
*                <fs_prodotti>-zz_code_resp
*                <fs_prodotti>-zz_code_sms_otp
*                <fs_prodotti>-zz_cell_fdr
* End   AG 22.03.2011 18:19:00
                <fs_prodotti>-zz_cell_fdr
                <fs_prodotti>-flag_pcr
                <fs_prodotti>-flag_sms_otp
                <fs_prodotti>-flag_up
* FINE MODIFICA AS DEL 20.04.2011

* Begin AG 02.11.2011
*        <fs_prodotti>-importo_richiesto "cancel VPM 24.01.2012
        <fs_prodotti>-convenzione
        <fs_prodotti>-durata_finanziamento_richiesto
        <fs_prodotti>-periodicita_richiesta
        <fs_prodotti>-numero_rate_richieste
        <fs_prodotti>-piano_ammortamento
* End   AG 02.11.2011
        <fs_prodotti>-promozione_web      " Add AS 15.05.2012
                INTO lv_line
                SEPARATED BY ca_pipe.
* 105900: inizio modifica del 29.09.2016 - eng
*    TRANSFER lv_line TO va_fileout.
    TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng

  ENDLOOP.

* -- Scrittura Record Partner
  LOOP AT pt_partner ASSIGNING <fs_partner>.

    IF <fs_partner>-no_type = 'US'.

      CLEAR bpartner.
      CLEAR usereid.

      usereid  = <fs_partner>-partner.

      CALL FUNCTION 'CRM_ICSS_BPARTNER_FROM_USER'
        EXPORTING
          userid   = usereid
        IMPORTING
          bpartner = bpartner.
      <fs_partner>-partner = bpartner.

    ENDIF.

    CLEAR lv_line.
    IF <fs_partner>-partner IS NOT INITIAL.
      CONCATENATE <fs_partner>-tipo_record
                  <fs_partner>-codice_crm
                  <fs_partner>-funzione_partner
                  <fs_partner>-partner
                  <fs_partner>-main_partner
                  <fs_partner>-classe_click " Add AS 17.05.2012
                  INTO lv_line
                  SEPARATED BY ca_pipe.
* 105900: inizio modifica del 29.09.2016 - eng
*      TRANSFER lv_line TO va_fileout.
      TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng
    ENDIF.
  ENDLOOP.

* -- Scrittura Record Modifiche di Stato
  LOOP AT pt_mod_stato ASSIGNING <fs_mod_stato>.

    CLEAR lv_line.
    CONCATENATE <fs_mod_stato>-tipo_record
                <fs_mod_stato>-codice_crm
                <fs_mod_stato>-stato
                <fs_mod_stato>-udate
                <fs_mod_stato>-utime
                <fs_mod_stato>-user_id
                INTO lv_line
                SEPARATED BY ca_pipe.
* 105900: inizio modifica del 29.09.2016 - eng
*    TRANSFER lv_line TO va_fileout.
    TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng
  ENDLOOP.

  "Inizio modifiche - GC 23.07.2009 17:54:39
* -- Scrittura Record Modifiche di Stato: posizione
  LOOP AT pt_mod_stato_pos ASSIGNING <fs_mod_stato_pos>.

    CLEAR lv_line.
    CONCATENATE <fs_mod_stato_pos>-tipo_record
                <fs_mod_stato_pos>-codice_crm
                <fs_mod_stato_pos>-id_pos
                <fs_mod_stato_pos>-stato
                <fs_mod_stato_pos>-udate
                <fs_mod_stato_pos>-utime
                <fs_mod_stato_pos>-user_id
                INTO lv_line
                SEPARATED BY ca_pipe.
* 105900: inizio modifica del 29.09.2016 - eng
*    TRANSFER lv_line TO va_fileout.
    TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng
  ENDLOOP.
  "Fine   modifiche - GC 23.07.2009 17:54:39

  " Inizio AS 18.05.2012 11:06:02

  LOOP AT pt_attr_dimens ASSIGNING <fs_attr_dimens>.

    CLEAR lv_line.

    CONCATENATE <fs_attr_dimens>-tipo_record
                <fs_attr_dimens>-codice_crm
                <fs_attr_dimens>-id_pos
                <fs_attr_dimens>-attributo
                <fs_attr_dimens>-dimensione
           INTO lv_line
   SEPARATED BY ca_pipe.

* 105900: inizio modifica del 29.09.2016 - eng
*    TRANSFER lv_line TO va_fileout.
    TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng
  ENDLOOP.


  LOOP AT pt_cons_priv_contr ASSIGNING <fs_cons_priv_contr>.

    CLEAR lv_line.

    CONCATENATE <fs_cons_priv_contr>-tipo_record
                <fs_cons_priv_contr>-codice_crm
                <fs_cons_priv_contr>-bp
                <fs_cons_priv_contr>-id_pos
                <fs_cons_priv_contr>-tipologia
                <fs_cons_priv_contr>-valore
           INTO lv_line
   SEPARATED BY ca_pipe.

* 105900: inizio modifica del 29.09.2016 - eng
*    TRANSFER lv_line TO va_fileout.
    TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng
  ENDLOOP.
  " Fine   AS 18.05.2012 11:06:02


*** Inizio TP 21.04.2016
  LOOP AT pt_attr_acc ASSIGNING <fs_attr_acc>.
    CLEAR lv_line.

    CONCATENATE <fs_attr_acc>-tipo_record
                <fs_attr_acc>-codice_crm
                <fs_attr_acc>-attributo_1
                <fs_attr_acc>-attributo_2
                <fs_attr_acc>-attributo_3
           INTO lv_line
   SEPARATED BY ca_pipe.

* 105900: inizio modifica del 29.09.2016 - eng
*    TRANSFER lv_line TO va_fileout.
    TRANSFER lv_line TO va_fileout_temp.
* 105900: fine modifica del 29.09.2016 - eng
  ENDLOOP.
*** Fine TP 21.04.2016

* -- Scrittura Record di Log
  PERFORM f_scrivi_log USING ps_header-codice_crm
                             text-l01.

ENDFORM.                    " f_scrivi_record
*&---------------------------------------------------------------------*
*&      Form  f_scrivi_log
*&---------------------------------------------------------------------*
*     Scrittura File di log
*----------------------------------------------------------------------*
FORM f_scrivi_log  USING    pv_object_id TYPE t_header-codice_crm
                            pv_msg       TYPE string.

  DATA: lv_line TYPE string.
  CLEAR lv_line.

  CONCATENATE pv_object_id
              pv_msg
              INTO lv_line
              SEPARATED BY ca_pipe.

  TRANSFER lv_line TO va_filelog.

ENDFORM.                    " f_scrivi_log
*&---------------------------------------------------------------------*
*&      Form  f_scrivi_error
*&---------------------------------------------------------------------*
*     Scrittura Errore in File di log
*----------------------------------------------------------------------*
FORM f_scrivi_error  USING pv_codice  TYPE string
                           pv_campo   TYPE string.

  DATA: lv_line TYPE string.
  CLEAR lv_line.

  CONCATENATE text-e14 pv_campo text-e15 INTO lv_line SEPARATED BY space.

  CONCATENATE pv_codice
              lv_line
              INTO lv_line
              SEPARATED BY ca_pipe.

  TRANSFER lv_line TO va_filelog.

ENDFORM.                    " f_scrivi_error
*&---------------------------------------------------------------------*
*&      Form  trascod_guid_32_16
*&---------------------------------------------------------------------*
*       Trascodifica un GUID da CHAR32 a RAW16
*----------------------------------------------------------------------*
FORM trascod_guid_32_16 USING    p_guid32 TYPE sysuuid-c
                        CHANGING p_guid16 TYPE sysuuid-x.
  CLEAR p_guid16.
  CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
    EXPORTING
      i_guid32 = p_guid32
    IMPORTING
      e_guid16 = p_guid16.
ENDFORM.                    " trascod_guid_16_32
*&---------------------------------------------------------------------*
*&      Form  f_estrai_mod_stato
*&---------------------------------------------------------------------*
*       Estrazione Modifiche Stato
*----------------------------------------------------------------------*
FORM f_estrai_mod_stato USING pt_guid16 TYPE t_guid16_tab.

  CASE ca_x.
    WHEN r_full.

      SELECT  objnr
              stat
              udate
              utime
              usnam
        FROM crm_jcds INTO TABLE i_crm_jcds
        FOR ALL ENTRIES IN pt_guid16
        WHERE objnr EQ pt_guid16-guid
          AND stat LIKE 'E%'
          AND inact NE ca_x.

    WHEN r_delta.

      SELECT  objnr
          stat
          udate
          utime
          usnam
    FROM crm_jcds INTO TABLE i_crm_jcds
    FOR ALL ENTRIES IN pt_guid16
    WHERE objnr EQ pt_guid16-guid
      AND (
             ( udate GT gw_tbtco_f-sdlstrtdt AND udate LT gw_tbtco_t-sdlstrtdt )
          OR ( udate EQ gw_tbtco_f-sdlstrtdt AND utime GE gw_tbtco_f-sdlstrttm )
          OR ( udate EQ gw_tbtco_t-sdlstrtdt AND utime LE gw_tbtco_t-sdlstrttm )
          )
      AND stat LIKE 'E%'
      AND inact NE ca_x.

    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " f_estrai_mod_stato
*&---------------------------------------------------------------------*
*&      Form  f_prepara_mod_stato
*&---------------------------------------------------------------------*
*   Prepara Record Modifiche di Stato
*----------------------------------------------------------------------*
FORM f_prepara_mod_stato  USING    ps_guid      TYPE bapibus20001_guid_dis
                                   ps_header    TYPE t_header
                          CHANGING pt_mod_stato TYPE t_mod_stato_tab
                                   pf_error     TYPE c.

  DATA: ls_mod_stato TYPE t_mod_stato,
        lv_codice    TYPE string.

  FIELD-SYMBOLS:   <fs_mod_stato> TYPE t_crm_jcds,
                   <fs_status>    TYPE bapibus20001_status_dis.

  REFRESH pt_mod_stato.

  READ TABLE i_crm_jcds TRANSPORTING NO FIELDS WITH KEY objnr = ps_guid-guid.

  LOOP AT i_crm_jcds ASSIGNING <fs_mod_stato> FROM sy-tabix.

    CLEAR ls_mod_stato.
    IF <fs_mod_stato>-objnr NE ps_guid-guid.
      EXIT.
    ENDIF.

    ls_mod_stato-tipo_record  = ca_ms.
    ls_mod_stato-codice_crm   = ps_header-codice_crm.

* Inizio Modifica AG 16.12.2009 17:53:17
    READ TABLE i_status ASSIGNING <fs_status>
      WITH KEY guid           = ps_guid-guid
               kind           = ca_a
               status(1)      = ca_e
               active         = ca_x
               BINARY SEARCH.
    IF <fs_status> IS ASSIGNED.

      CONCATENATE <fs_status>-user_stat_proc
                  <fs_mod_stato>-stat
             INTO ls_mod_stato-stato.

    ENDIF.
*    ls_mod_stato-stato = <fs_mod_stato>-stat.
* Fine   Modifica AG 16.12.2009 17:53:17



    IF ls_mod_stato-stato IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e19.
      pf_error = ca_x.
      EXIT.
    ENDIF.

    ls_mod_stato-udate        = <fs_mod_stato>-udate.

    IF ls_mod_stato-udate IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e32.
      pf_error = ca_x.
      EXIT.
    ENDIF.

    ls_mod_stato-utime        = <fs_mod_stato>-utime.

    IF ls_mod_stato-utime IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e33.
      pf_error = ca_x.
      EXIT.
    ENDIF.

    ls_mod_stato-user_id      = <fs_mod_stato>-usnam.

    APPEND ls_mod_stato TO pt_mod_stato.

  ENDLOOP.

ENDFORM.                    " f_prepara_mod_stato
*&---------------------------------------------------------------------*
*&      Form  f_estrai_tipologiche
*&---------------------------------------------------------------------*
*    Estrazione Tipologiche
*----------------------------------------------------------------------*
FORM f_estrai_tipologiche.

  REFRESH gt_nop_motivo.
  SELECT * FROM zca_nop_motivo INTO TABLE gt_nop_motivo.
  SORT gt_nop_motivo BY motivo.

ENDFORM.                    " f_estrai_tipologiche
*&---------------------------------------------------------------------*
*&      Form  nettoyer_tout
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM nettoyer_tout .

  DATA: lv_object_name   TYPE crmt_object_name,
        lv_event_exetime TYPE crmt_event_exetime,
        lv_event         TYPE crmt_event,
        lv_header_guid   TYPE crmt_object_guid.

* Clean-up transactional data
  CALL FUNCTION 'CRM_ORDER_INITIALIZE'
    EXPORTING
      iv_initialize_whole_buffer = 'X'.

  CALL FUNCTION 'CRM_ACTIVITY_H_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up BP data
  CALL FUNCTION 'CRM_PARTNER_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up appointment data and time
  CALL FUNCTION 'CRM_DATES_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up links
  CALL FUNCTION 'CRM_LINK_INIT_OW'.


* Clean-up text memory
  CALL FUNCTION 'FREE_TEXT_MEMORY'
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " nettoyer_tout
*&---------------------------------------------------------------------*
*&      Form  f_estrai_cod_contrattuale
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_GUID16  text
*----------------------------------------------------------------------*
FORM f_estrai_cod_contrattuale  USING pt_guid16 TYPE t_guid16_tab.

  CONSTANTS lc_01 TYPE zca_ptb_cocontr-val VALUE '01'.

  SELECT *
    FROM zca_ptb_cocontr
    INTO TABLE gt_cod_contr
    FOR ALL ENTRIES IN pt_guid16
    WHERE guid = pt_guid16-guid
    AND val = lc_01.

ENDFORM.                    " f_estrai_cod_contrattuale
*&---------------------------------------------------------------------*
*&      Form  estrai_dati_preventivo
*&---------------------------------------------------------------------*
*       Estrazione dati relativi al preventivo
*----------------------------------------------------------------------*
FORM  estrai_dati_preventivo.

  CONSTANTS: lc_applicazione TYPE zappl VALUE 'BDM_CONFIGURAZIONE2'.
  DATA: ls_leggi_prev_app TYPE t_leggi_prev,
        ls_leggi_prev     TYPE zca_bdm_prev_out,
        lv_prev           TYPE zbdm_prev_id.


  FIELD-SYMBOLS: <fs_prev>         TYPE t_bdm_prev_bp,
                 <fs_bdm_contract> TYPE t_bdm_contract,
                 <fs_bdm_prev_bp>  TYPE t_bdm_prev_bp.

* Begin AG 03.11.2011
  DATA: BEGIN OF ls_guid,
          contract_guid TYPE zca_bdm_contract-contract_guid,
        END OF ls_guid.
  DATA: li_guid LIKE STANDARD TABLE OF ls_guid.
  FIELD-SYMBOLS <fs_guid> LIKE LINE OF i_header.

  DATA li_bdm_contract LIKE i_bdm_contract.

  LOOP AT i_header ASSIGNING <fs_guid>.

    PERFORM trascod_guid_32_16 USING <fs_guid>-guid
                             CHANGING ls_guid-contract_guid.

    APPEND ls_guid TO li_guid.
  ENDLOOP.
* End   AG 03.11.2011

* Begin AG 03.11.2011
*  CHECK i_prec_doc[] IS NOT INITIAL.
  CHECK i_header[] IS NOT INITIAL.
* End   AG 03.11.2011


  SELECT id_preventivo
    FROM zca_bdm_prev_bp
    INTO TABLE  i_bdm_prev_bp
    FOR ALL ENTRIES IN i_header "i_prec_doc " Mod AG 03.11.2011
    WHERE id_contratto = i_header-object_id.


*** Inizio TP 21.04.2016
  REFRESH i_zca_spid_prod.
  SELECT id_pratica prodotto  stato
    FROM zca_spid_prod
    INTO TABLE  i_zca_spid_prod
        FOR ALL ENTRIES IN i_header
      WHERE id_pratica = i_header-object_id.
*** Fine TP 21.04.2016

  IF li_guid[] IS NOT INITIAL.


    SELECT id_preventivo
           dataaperturacc
           correntista
           id_finalita1
           id_finalita2
           id_finalita3
           debres
           mod_erogazione
           mod_rimborso
           flag_fideiussion
           id_garanzia
           importo_garanzia
           data_delibera
*           imp_deliberato "VPM21.02.2012
           importo_delib "VPM21.02.2012
           durfindel
           perratadel
           tipo_gar_del_1
           imp_delibera_1
           denom_gar1
           tipo_gar_del_2
           imp_delibera_2
           denom_gar2
           tipo_gar_del_3
           imp_delibera_3
           denom_gar3
           data_stip_contr
           data_erogazione
*           importo_cpi "VPM21.02.2012
           imp_erogato "VPM21.02.2012
           tipo_tasso_erog
           spreadappl
           taeg
           imp_cpi_erog
           imp_pr_scop_inc
           spese_istruttori
           costo_garanzia
           tipo_tasso_erog
           data_scad_fin
           contract_guid
           id_contratto_glm
           prodotto
           importo_rich
           data_richiesta
           data_sottoscrizi "VPM-21.03.2012
*           polizza_scop_inc "add mf 30/11/2011
*           presenza_cpi "add mf 30/11/2011
*           importo_cpi "add VPM 24/01/2012
*           imp_pr_scop_inc "add VPM 24/01/2012
      FROM zca_bdm_contract
      INTO TABLE i_bdm_contract
      FOR ALL ENTRIES IN li_guid "i_prec_doc " Mod AG 03.11.2011
      WHERE contract_guid = li_guid-contract_guid.

  ENDIF.

  LOOP AT i_bdm_prev_bp ASSIGNING <fs_bdm_prev_bp>.

    CALL FUNCTION 'Z_CA_BDM_LEGGI_PREVENTIVO'
      EXPORTING
        i_applicazione     = lc_applicazione
        i_preventivo       = <fs_bdm_prev_bp>-id_preventivo
      IMPORTING
        et_dati_preventivo = i_leggi_prev.

    ls_leggi_prev_app-id_preventivo = <fs_bdm_prev_bp>-id_preventivo.

    LOOP AT i_leggi_prev INTO ls_leggi_prev.

      IF ls_leggi_prev-code EQ 'TIPO_TASSO'.
        ls_leggi_prev_app-tipo_tasso_richiesto = ls_leggi_prev-value.
      ENDIF.

      IF ls_leggi_prev-code EQ 'CONVENZIONE'.
        ls_leggi_prev_app-convenzione = ls_leggi_prev-value.
      ENDIF.

      IF ls_leggi_prev-code EQ 'DURATA'.
        ls_leggi_prev_app-durata_fin_ric  = ls_leggi_prev-value.
      ENDIF.

*inizio VPM 24.01.2012
      IF ls_leggi_prev-code EQ 'PERIODICITA_RATA'.
        ls_leggi_prev_app-periodicita_ric  = ls_leggi_prev-value.
      ENDIF.
*fine VPM 24.01.2012

      IF ls_leggi_prev-code EQ 'NUMERO_TOTALE_RATA'.
        ls_leggi_prev_app-n_rate_ric  = ls_leggi_prev-value.
      ENDIF.

      IF ls_leggi_prev-code EQ 'TIPO_PIANO_AMMORTAMENTO'.
        ls_leggi_prev_app-tipo_piano_amm  = ls_leggi_prev-value.
      ENDIF.

      "inizio mf 30/11/2011
      IF ls_leggi_prev-code EQ 'PRESENZA_CPI'.
        ls_leggi_prev_app-presenza_cpi  = ls_leggi_prev-value.
      ENDIF.
      "fine mf 30/11/2011
      IF ls_leggi_prev-code EQ 'IMPORTO_CPI'.
        ls_leggi_prev_app-importo_cpi  = ls_leggi_prev-value_decimal.
      ENDIF.
*inizio VPM 06/02/2012
      IF ls_leggi_prev-code EQ 'POLIZZA_SCOP_INC'.
        ls_leggi_prev_app-polizza_scop_inc  = ls_leggi_prev-value.
      ENDIF.
*fine VPM 06/02/2012
      IF ls_leggi_prev-code EQ 'IMPORTO_POLIZZA_INCENDIO'.
        ls_leggi_prev_app-imp_pr_scop_inc  = ls_leggi_prev-value_decimal.
      ENDIF.

    ENDLOOP.
    APPEND ls_leggi_prev_app TO i_leggi_prev_app.
    CLEAR ls_leggi_prev_app.

  ENDLOOP.

  IF li_guid[] IS NOT INITIAL.
    SELECT guid_contratto
           codice_crif "VPM-21.03.2012
           esito_pre_screen
           codice_esito_sco
           desc_esito_score
           probabilita_defa
           classe
      FROM zca_bdm_crif_1
      INTO TABLE i_bdm_crif
      FOR ALL ENTRIES IN li_guid "i_prec_doc " Mod AG 03.11.2011
      WHERE guid_contratto = li_guid-contract_guid.
  ENDIF.


  li_bdm_contract[] = i_bdm_contract[].
  SORT li_bdm_contract[] BY prodotto.
  DELETE ADJACENT DUPLICATES FROM li_bdm_contract[] COMPARING prodotto.
*inizio VPM 24.01.2012
  REFRESH gi_zca_bdm_pddlb[].
*  SELECT *
*    FROM zca_bdm_pddlb
*    INTO TABLE gi_zca_bdm_pddlb
*    FOR ALL ENTRIES IN li_bdm_contract
*    WHERE appl       EQ 'BDM_CONFIGURAZIONE2'
*      AND product_id EQ li_bdm_contract-prodotto
*      AND ( code EQ gc_tipo_tasso OR code EQ gc_durata OR code EQ gc_periodicita ).
  SELECT *
      FROM zca_bdm_pddlb
      INTO TABLE gi_zca_bdm_pddlb
      WHERE appl       EQ 'BDM_CONFIGURAZIONE2'.
*fine VPM 24.01.2012

  SORT gi_zca_bdm_pddlb BY product_id code value.

ENDFORM.                    " estrai_dati_preventivo
*&---------------------------------------------------------------------*
*&      Form  set_classe_click
*&---------------------------------------------------------------------*
*       Valorizzazione campo classe_click per file PF
*----------------------------------------------------------------------*
FORM set_classe_click  USING    p_tipo_contratto     TYPE crmd_orderadm_h-process_type
                                p_canale_provenienza TYPE crmd_customer_h-zz_provenienza
                                p_object_id          TYPE crmd_orderadm_h-object_id
                                p_funzione_partner   TYPE char8
                       CHANGING p_classe_click       TYPE char05.

  DATA: lr_field      TYPE RANGE OF zmp_addon_prod-field,
        lv_flag_inte  TYPE flag,
        lt_addon_prod TYPE STANDARD TABLE OF zmp_addon_prod,
        ls_addon_prod TYPE zmp_addon_prod,
        ls_field      LIKE LINE OF lr_field.

  FIELD-SYMBOLS: <fs_param> TYPE zca_param.

  CHECK p_object_id IS NOT INITIAL.

  " Controllo che il process_type deve essere presente nel gruppo
  READ TABLE gt_type TRANSPORTING NO FIELDS
    WITH KEY z_val_par = p_tipo_contratto.
  CHECK sy-subrc IS INITIAL.

  " Controllo che il CRMD_CUSTOMER_H-ZZ_PROVENIENZA deve essere presente nel gruppo
  READ TABLE gt_prov TRANSPORTING NO FIELDS
    WITH KEY z_val_par = p_canale_provenienza.
  CHECK sy-subrc IS INITIAL.

  REFRESH lt_addon_prod.
  lt_addon_prod[] = gt_zmp_addon_prod[].

  IF p_funzione_partner EQ gv_pft_cliente. " Intestatario
    CHECK gr_inte[] IS NOT INITIAL.
    DELETE lt_addon_prod WHERE object_id NE p_object_id AND NOT field IN gr_inte.
  ELSEIF p_funzione_partner EQ gv_pft_cointestat. " Cointestatario
    CHECK gr_coin[] IS NOT INITIAL.
    DELETE lt_addon_prod WHERE object_id NE p_object_id AND NOT field IN gr_coin.
  ENDIF.

  READ TABLE lt_addon_prod INTO ls_addon_prod INDEX 1.

  CHECK sy-subrc IS INITIAL.

  " Recupero il valore dallo Z_NOME_PAR
  UNASSIGN <fs_param>.
  IF p_funzione_partner EQ gv_pft_cliente. " Intestatario
    READ TABLE gt_inte ASSIGNING <fs_param>
      WITH KEY z_val_par = ls_addon_prod-field.
  ELSEIF p_funzione_partner EQ gv_pft_cointestat. " Cointestatario
    READ TABLE gt_coin ASSIGNING <fs_param>
      WITH KEY z_val_par = ls_addon_prod-field.
  ENDIF.

  CHECK <fs_param> IS ASSIGNED.

  p_classe_click = <fs_param>-z_nome_par.

ENDFORM.                    " set_classe_click
*&---------------------------------------------------------------------*
*&      Form  f_estrai_privacy
*&---------------------------------------------------------------------*
*       Estrazione Massiva ZCA_PRIVACY
*----------------------------------------------------------------------*
FORM f_estrai_privacy .

  DATA: lt_privacy TYPE STANDARD TABLE OF zca_privacy.

  REFRESH: gt_privacy_tab1,gt_privacy_tab2.

  SELECT * FROM zca_privacy INTO TABLE lt_privacy.

  gt_privacy_tab1[] = lt_privacy[].
  DELETE gt_privacy_tab1[] WHERE tabella         NOT IN gr_tab1.

  gt_privacy_tab2[] = lt_privacy[].
  DELETE gt_privacy_tab2[] WHERE tabella         NOT IN gr_tab2.

  SORT: gt_privacy_tab1 BY tabella campo_chiave,
        gt_privacy_tab2 BY tabella campo_chiave.

ENDFORM.                    " f_estrai_privacy
*&---------------------------------------------------------------------*
*&      Form  f_estrai_zmp_addon_prod
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_estrai_zmp_addon_prod .

  CHECK i_header[] IS NOT INITIAL.

  REFRESH gt_zmp_addon_prod.

  SELECT *
    FROM zmp_addon_prod
    INTO TABLE gt_zmp_addon_prod
    FOR ALL ENTRIES IN i_header
   WHERE object_id EQ i_header-object_id
     AND value     EQ ca_x.

  SORT gt_zmp_addon_prod BY object_id.

ENDFORM.                    " f_estrai_zmp_addon_prod

*&---------------------------------------------------------------------*
*&      Form  f_estrai_zca_dati_maaf
*&---------------------------------------------------------------------*
*        Iniziativa 106592 - Nuovi campi MAAF
*----------------------------------------------------------------------*
FORM f_estrai_zca_dati_maaf .

  DATA: lt_header TYPE STANDARD TABLE OF bapibus20001_header_dis,
        ls_header TYPE bapibus20001_header_dis.

  REFRESH lt_header.
  CLEAR ls_header.
  LOOP AT i_header INTO ls_header WHERE process_type EQ 'ZMAF' .
    APPEND ls_header TO lt_header.
    CLEAR ls_header.
  ENDLOOP.

  CHECK lt_header[] IS NOT INITIAL.

  REFRESH gt_dati_maaf.

  SELECT *
    FROM zca_dati_maaf
    INTO TABLE gt_dati_maaf
    FOR ALL ENTRIES IN lt_header
   WHERE object_id EQ lt_header-object_id.

  SORT gt_dati_maaf BY object_id.

ENDFORM.                    " f_estrai_zmp_addon_prod
*&---------------------------------------------------------------------*
*&      Form  f_set_range
*&---------------------------------------------------------------------*
*       Set range
*----------------------------------------------------------------------*
FORM f_set_range .

  DATA:  ls_range  LIKE LINE OF gr_inte,
         ls_range1 LIKE LINE OF gr_tab1.

  FIELD-SYMBOLS <fs_param> TYPE zca_param.

  ls_range-sign   = ca_i.
  ls_range-option = ca_eq.

  LOOP AT gt_inte ASSIGNING <fs_param>.
    ls_range-low = <fs_param>-z_val_par.
    APPEND ls_range TO gr_inte.
    CLEAR ls_range-low.
  ENDLOOP.

  LOOP AT gt_coin ASSIGNING <fs_param>.
    ls_range-low = <fs_param>-z_val_par.
    APPEND ls_range TO gr_coin.
    CLEAR ls_range-low.
  ENDLOOP.


  ls_range1-sign   = ca_i.
  ls_range1-option = ca_eq.
  LOOP AT gt_tab1 ASSIGNING <fs_param>.

    ls_range-low = <fs_param>-z_val_par.
    APPEND ls_range TO gr_tab1.
    CLEAR ls_range-low.
  ENDLOOP.

  LOOP AT gt_tab2 ASSIGNING <fs_param>.
    ls_range1-low = <fs_param>-z_val_par.
    APPEND ls_range1 TO gr_tab2.
    CLEAR ls_range1-low.
  ENDLOOP.


* 105900: inizio modifica del 05.09.2016 - tm
  UNASSIGN <fs_param>.

  LOOP AT gt_zfac ASSIGNING <fs_param>.
    l_zfac-sign   = ca_i.
    l_zfac-option = ca_eq.
    l_zfac-low = <fs_param>-z_val_par.
    APPEND  l_zfac TO gr_zfac.
    CLEAR  l_zfac-low.
  ENDLOOP.
* 105900: fine   modifica del 05.09.2016 - tm

ENDFORM.                    " f_set_range
*&---------------------------------------------------------------------*
*&      Form  f_prepara_cons_priv_contr
*&---------------------------------------------------------------------*
*       Preparazione file
*----------------------------------------------------------------------*
FORM f_prepara_cons_priv_contr  USING    ps_guid            TYPE bapibus20001_guid_dis
                                         ps_header          TYPE t_header
                                CHANGING pt_cons_priv_contr TYPE t_cons_priv_contr_tab
                                         p_fl_error         TYPE flag.

  CONSTANTS: lc_tipo_record(2) TYPE c VALUE 'CN',
             lc_contract_id(9) TYPE c VALUE 'OBJECT_ID',
             lc_product_id(10) TYPE c VALUE 'PRODUCT_ID',
             lc_value(5)       TYPE c VALUE 'VALUE',
             lc_trat(1)        TYPE c VALUE '-',
             lc_uguale(1)      TYPE c VALUE '=',
             lc_field(5)       TYPE c VALUE 'FIELD',
             lc_and(3)         TYPE c VALUE 'AND'.

  DATA: lt_priv_tab1       TYPE STANDARD TABLE OF zca_privacy,
        lt_priv_tab2       TYPE STANDARD TABLE OF zca_privacy,
        lt_priv_app        TYPE STANDARD TABLE OF zca_privacy,
        ls_cons_priv_contr TYPE t_cons_priv_contr,
        lv_guid_16         TYPE crmd_customer_h-guid,
        lv_where           TYPE string,
        lv_flag            TYPE flag,
        lv_flag_item       TYPE flag,
        lv_nome_cons       TYPE string,
        lv_timest(15)      TYPE c,
        lv_data_char(8)    TYPE c,
        lv_data            TYPE dats,
        lv_campo           TYPE REF TO data,
        lv_tab             TYPE REF TO data,
        ls_struct_dyn      TYPE REF TO data,
        lv_tipo            TYPE string.


  FIELD-SYMBOLS: <fs_priv_tab> TYPE zca_privacy,
                 <fs_priv_app> TYPE zca_privacy,
                 <fs_param>    TYPE zca_param,
                 <l_line>      TYPE any,
                 <fs_header>   TYPE bapibus20001_header_dis,
                 <any>         TYPE any,
                 <field>       TYPE any,
                 <product_id>  TYPE any,
                 <value>       TYPE any,
                 <fs_products> LIKE LINE OF i_products,
                 <fs_item>     LIKE LINE OF i_item,
                 <any_table>   TYPE ANY TABLE.

  REFRESH: lt_priv_tab1,lt_priv_tab2, pt_cons_priv_contr.

  CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
    EXPORTING
      i_guid32 = ps_guid-guid
    IMPORTING
      e_guid16 = lv_guid_16.

  READ TABLE i_header ASSIGNING <fs_header> WITH KEY guid = ps_guid-guid
                                                     BINARY SEARCH.
  CHECK sy-subrc IS INITIAL.


  " Inizio AS 16.06.2012
  lv_timest    = <fs_header>-created_at.
  lv_data_char = lv_timest(8).
  lv_data      = lv_data_char.
  " Fine AS 16.06.2012
  " Filtro per process_type

  lt_priv_tab1[] = gt_privacy_tab1[].
  DELETE lt_priv_tab1[] WHERE process_type    NE ps_header-tipo_contratto.
*  DELETE lt_priv_tab1[] WHERE NOT ( data_inizio_val LE <fs_header>-posting_date
*                          AND data_fine_val   GE <fs_header>-posting_date ).

  DELETE lt_priv_tab1[] WHERE NOT ( data_inizio_val LE lv_data
                          AND data_fine_val   GE lv_data ).

  " Filtro per process_type
  lt_priv_tab2[] = gt_privacy_tab2[].
  DELETE lt_priv_tab2[] WHERE process_type    NE ps_header-tipo_contratto.
*  DELETE lt_priv_tab2[] WHERE NOT ( data_inizio_val LE <fs_header>-posting_date
*                          AND data_fine_val   GE <fs_header>-posting_date ).

  DELETE lt_priv_tab2[] WHERE NOT ( data_inizio_val LE lv_data
                             AND data_fine_val   GE lv_data ).
  CLEAR lv_flag_item.
  READ TABLE gt_param_item TRANSPORTING NO FIELDS
    WITH KEY z_val_par = ps_header-tipo_contratto.
  IF sy-subrc IS INITIAL.
    lv_flag_item = ca_x.
  ENDIF.

  " -- Begin CP 27.02.2014
  CLEAR lv_flag_item.
  READ TABLE gt_cont TRANSPORTING NO FIELDS
  WITH KEY z_val_par = ps_header-tipo_contratto.
  IF sy-subrc IS NOT INITIAL.
    lv_flag_item = ca_x.
  ENDIF.
  " -- End CP 27.02.2014



  LOOP AT lt_priv_tab1 ASSIGNING <fs_priv_tab>.

    APPEND <fs_priv_tab> TO lt_priv_app.

    AT END OF tabella.

      TRY .
          CREATE DATA ls_struct_dyn TYPE (<fs_priv_tab>-tabella).
          ASSIGN ls_struct_dyn->* TO <l_line>.
        CATCH cx_sy_create_data_error.
          CONTINUE.
      ENDTRY.

      SELECT * UP TO 1 ROWS
      FROM (<fs_priv_tab>-tabella)
        INTO <l_line>
      WHERE guid = lv_guid_16.
      ENDSELECT.

      LOOP AT lt_priv_app ASSIGNING <fs_priv_app>.
        UNASSIGN <any>.
        ASSIGN COMPONENT <fs_priv_app>-campo_chiave OF STRUCTURE <l_line> TO <any>.
        IF <any> IS ASSIGNED.
          " valorizza la tabella

          ls_cons_priv_contr-tipo_record = lc_tipo_record.
          ls_cons_priv_contr-codice_crm  = ps_header-codice_crm.
          IF <fs_priv_app>-product_id IS NOT INITIAL.
            READ TABLE gt_cont TRANSPORTING NO FIELDS
              WITH KEY z_val_par = ps_header-tipo_contratto.
            IF sy-subrc IS INITIAL.
              READ TABLE i_products ASSIGNING <fs_products>
              WITH KEY product_id = <fs_priv_app>-product_id.
              IF sy-subrc IS INITIAL.
                ls_cons_priv_contr-id_pos      = <fs_products>-hierarchy_id.
              ENDIF.
            ELSE.
              READ TABLE i_item ASSIGNING <fs_item>
              WITH KEY description_uc = <fs_priv_app>-product_id.
              IF sy-subrc IS INITIAL.
                ls_cons_priv_contr-id_pos = <fs_item>-number_int.
              ENDIF.
            ENDIF.
          ENDIF.

          CONCATENATE <fs_priv_app>-process_type <fs_priv_app>-id_consenso INTO ls_cons_priv_contr-tipologia.

*****************************************************************
*                                                               *
* GOTO 105370 - Adeguamento estrattore per consensi FEA - Start *
*                                                               *
*****************************************************************
          DATA: lt_nfex_addonbp TYPE STANDARD TABLE OF zca_nfex_addonbp.

*          IF ps_header-tipo_contratto EQ 'ZFEA'.

          IF <fs_priv_tab>-tabella         EQ 'ZCA_NFEX_ADDONBP' AND
             <fs_priv_app>-campo_chiave(3) EQ 'FEA'.

            IF NOT <any> IS INITIAL. " Salvare il consenso FEA solo se valorizzato

              CASE <any>.
                WHEN 'SI'.
                  MOVE '1' TO ls_cons_priv_contr-valore.

                WHEN 'NO'.
                  MOVE '2' TO ls_cons_priv_contr-valore.

              ENDCASE.

              UNASSIGN <any>.
              ASSIGN COMPONENT 'BP' OF STRUCTURE <l_line> TO <any>.
              MOVE <any> TO ls_cons_priv_contr-bp.

              APPEND ls_cons_priv_contr TO pt_cons_priv_contr.

            ENDIF.

* Verificare eventuali altri intestatari della pratica di cui interessa il consenso FEA
            REFRESH lt_nfex_addonbp.
            UNASSIGN <any>.
            ASSIGN COMPONENT 'BP' OF STRUCTURE <l_line> TO <any>.
            SELECT * INTO TABLE lt_nfex_addonbp
              FROM (<fs_priv_tab>-tabella)
             WHERE guid EQ lv_guid_16
               AND bp   NE <any>.

            IF sy-subrc IS INITIAL.
              UNASSIGN  <l_line>.
              LOOP AT lt_nfex_addonbp ASSIGNING <l_line>.
                UNASSIGN <any>.
                ASSIGN COMPONENT <fs_priv_app>-campo_chiave OF STRUCTURE <l_line> TO <any>.

                CASE <any>.

                  WHEN 'SI'.
                    MOVE '1' TO ls_cons_priv_contr-valore.

                  WHEN 'NO'.
                    MOVE '2' TO ls_cons_priv_contr-valore.

                ENDCASE.

                UNASSIGN <any>.
                ASSIGN COMPONENT 'BP' OF STRUCTURE <l_line> TO <any>.
                MOVE <any> TO ls_cons_priv_contr-bp.
                APPEND ls_cons_priv_contr TO pt_cons_priv_contr.

              ENDLOOP.

            ENDIF.

            CLEAR ls_cons_priv_contr.

          ELSE.
*****************************************************************
*                                                               *
* GOTO 105370 - Adeguamento estrattore per consensi FEA - End   *
*                                                               *
*****************************************************************

            READ TABLE gt_priv ASSIGNING <fs_param>
              WITH KEY z_val_par = <any>.
            IF sy-subrc IS INITIAL.
              ls_cons_priv_contr-valore = <fs_param>-z_label.
            ENDIF.

            APPEND ls_cons_priv_contr TO pt_cons_priv_contr.
            CLEAR ls_cons_priv_contr .
          ENDIF.
        ENDIF.
      ENDLOOP.

      REFRESH lt_priv_app.
    ENDAT.

  ENDLOOP.

  UNASSIGN <any>.
  REFRESH lt_priv_app.
  LOOP AT lt_priv_tab2 ASSIGNING <fs_priv_tab>.

    " costruisco la WHERE

    lv_where = lc_contract_id.

    CHECK ps_header-codice_crm IS NOT INITIAL.

    CONCATENATE lv_where lc_uguale ps_header-codice_crm INTO lv_where SEPARATED BY space.

    IF <fs_priv_tab>-campo_chiave IS NOT INITIAL.
      CONCATENATE lv_where lc_and <fs_priv_tab>-campo_chiave INTO lv_where SEPARATED BY space.
    ENDIF.

    IF <fs_priv_tab>-campo_chiave2 IS NOT INITIAL.
      CONCATENATE lv_where lc_and <fs_priv_tab>-campo_chiave2 INTO lv_where SEPARATED BY space.
    ENDIF.

    IF <fs_priv_tab>-campo_chiave3 IS NOT INITIAL.
      CONCATENATE lv_where lc_and <fs_priv_tab>-campo_chiave3 INTO lv_where SEPARATED BY space.
    ENDIF.

    " Creo la tabella in cui salvare i dati dell'estrazione
    CREATE DATA lv_tab TYPE STANDARD TABLE OF (<fs_priv_tab>-tabella).
    ASSIGN lv_tab->* TO <any_table>.
    REFRESH <any_table>.
    SELECT *
      FROM (<fs_priv_tab>-tabella)
      INTO TABLE <any_table>
    WHERE (lv_where).

    CREATE DATA ls_struct_dyn TYPE (<fs_priv_tab>-tabella).
    ASSIGN ls_struct_dyn->* TO <l_line>.

    LOOP AT <any_table> ASSIGNING <l_line>.
      CLEAR ls_cons_priv_contr.
      ASSIGN COMPONENT lc_value OF STRUCTURE <l_line> TO <value>.
      CHECK <value> IS ASSIGNED.

      IF <fs_priv_tab>-product_id IS NOT INITIAL.

        IF lv_flag_item = ca_x.

          READ TABLE i_item ASSIGNING <fs_item>
            WITH KEY header         = ps_guid-guid
                     description_uc = <fs_priv_tab>-product_id.
          CHECK sy-subrc IS INITIAL.

          ls_cons_priv_contr-id_pos = <fs_item>-number_int.

        ELSE.

          READ TABLE i_item TRANSPORTING NO FIELDS
            WITH KEY header = ps_guid-guid BINARY SEARCH.

          LOOP AT i_item ASSIGNING <fs_item> FROM sy-tabix.
            IF <fs_item>-header NE ps_guid-guid.
              EXIT.
            ENDIF.
            READ TABLE i_products ASSIGNING <fs_products>
              WITH KEY guid  = <fs_item>-guid
                       product_id = <fs_priv_tab>-product_id.
            CHECK sy-subrc IS INITIAL.
            ls_cons_priv_contr-id_pos = <fs_item>-number_int.
          ENDLOOP.
        ENDIF.
        CHECK ls_cons_priv_contr-id_pos IS NOT INITIAL.
      ENDIF.


      ls_cons_priv_contr-tipo_record = lc_tipo_record.
      ls_cons_priv_contr-codice_crm  = ps_header-codice_crm.
      CONCATENATE <fs_priv_tab>-process_type <fs_priv_tab>-id_consenso INTO ls_cons_priv_contr-tipologia.

      READ TABLE gt_priv ASSIGNING <fs_param>
        WITH KEY z_val_par = <value>.
      IF sy-subrc IS INITIAL.
        ls_cons_priv_contr-valore = <fs_param>-z_label.
      ENDIF.
      APPEND ls_cons_priv_contr TO pt_cons_priv_contr.
      CLEAR ls_cons_priv_contr .

    ENDLOOP.
  ENDLOOP.

*****************************************************************
*                                                               *
* GOTO 105370 - Adeguamento estrattore per consensi FEA - Start *
*                                                               *
*****************************************************************
*
*
*  DATA: lt_nfex_addonbp TYPE STANDARD TABLE OF zca_nfex_addonbp,
*        ls_nfex_addonbp TYPE zca_nfex_addonbp.
*
*  IF ps_header-tipo_contratto EQ 'ZFEA'.
*
*    REFRESH lt_nfex_addonbp.
*    CLEAR ls_nfex_addonbp.
*
*    SELECT * INTO TABLE lt_nfex_addonbp
*      FROM zca_nfex_addonbp
*     WHERE guid      EQ ps_guid
*       AND object_id EQ ps_header-codice_crm.
*
*    LOOP AT lt_nfex_addonbp INTO ls_nfex_addonbp.
*
*      MOVE: lc_tipo_record        TO ls_cons_priv_contr-tipo_record,
*            ps_header-codice_crm  TO ls_cons_priv_contr-codice_crm,
*            ls_nfex_addonbp-bp    TO ls_cons_priv_contr-bp,
*            'ZFEAFEA1'            TO ls_cons_priv_contr-tipologia,
*            ls_nfex_addonbp-fea1  TO ls_cons_priv_contr-valore.
*
*      APPEND ls_cons_priv_contr TO pt_cons_priv_contr.
*      CLEAR ls_cons_priv_contr.
*    ENDLOOP.
*
*  ENDIF.
*****************************************************************
*                                                               *
* GOTO 105370 - Adeguamento estrattore per consensi FEA - End   *
*                                                               *
*****************************************************************

*    READ TABLE gt_cont TRANSPORTING NO FIELDS
*      WITH KEY z_val_par = ps_header-tipo_contratto.
*    IF sy-subrc IS INITIAL.
*
*      LOOP AT i_products ASSIGNING <fs_products>. ci vuole la condizione per recuperare quelli relativi al contratto
*
*        READ TABLE i_item ASSIGNING <fs_item>
*          WITH KEY guid = <fs_products>-guid.
*
*        CHECK sy-subrc IS INITIAL.
*
*        LOOP AT <any_table> ASSIGNING <l_line>.
*          ASSIGN COMPONENT lc_value OF STRUCTURE <l_line> TO <value>.
*          CHECK <value> IS ASSIGNED.
*          ASSIGN COMPONENT lc_product_id OF STRUCTURE <l_line> TO <product_id>.
*          CHECK <product_id> IS ASSIGNED.
*          ASSIGN COMPONENT lc_field OF STRUCTURE <l_line> TO <field>.
*          CHECK <field> IS ASSIGNED.
*          CLEAR lv_nome_cons.
*          CONCATENATE <product_id> <field> INTO lv_nome_cons SEPARATED BY lc_trat.
*
*          PERFORM f_check_cons_pf USING lv_nome_cons
*                                        <fs_item>-partner_prod
*                               CHANGING lv_flag.
*
*          CHECK lv_flag IS NOT INITIAL.
*          " Prepara la tabella per la scrittura nel file
*          ls_cons_priv_contr-tipo_record = lc_tipo_record.
*          ls_cons_priv_contr-codice_crm  = ps_header-codice_crm.
*          ls_cons_priv_contr-id_pos      = <fs_products>-hierarchy_id.
*          CONCATENATE <fs_priv_tab>-process_type <fs_priv_tab>-id_consenso INTO ls_cons_priv_contr-tipologia.
*          ls_cons_priv_contr-valore      = <value>.
*
*          APPEND ls_cons_priv_contr TO pt_cons_priv_contr.
*          CLEAR ls_cons_priv_contr .
*
*        ENDLOOP.
*      ENDLOOP.
*    ELSE.
*      READ TABLE gt_ods TRANSPORTING NO FIELDS
*        WITH KEY z_val_par = ps_header-tipo_contratto.
*      CHECK sy-subrc IS INITIAL.
*
*      LOOP AT i_item ASSIGNING <fs_item>.
*
*        LOOP AT <any_table> ASSIGNING <l_line>.
*          ASSIGN COMPONENT lc_value OF STRUCTURE <l_line> TO <value>.
*          CHECK <value> IS ASSIGNED.
*          ASSIGN COMPONENT lc_product_id OF STRUCTURE <l_line> TO <product_id>.
*          CHECK <product_id> IS ASSIGNED.
*          ASSIGN COMPONENT lc_field OF STRUCTURE <l_line> TO <field>.
*          CHECK <field> IS ASSIGNED.
*          CLEAR lv_nome_cons.
*          CONCATENATE <product_id> <field> INTO lv_nome_cons SEPARATED BY lc_trat.
*          PERFORM f_check_cons_pf USING lv_nome_cons
*                                        <fs_item>-partner_prod
*                               CHANGING lv_flag.
*
*          CHECK lv_flag IS NOT INITIAL.
*
*          " Prepara la tabella per la scrittura nel file
*          ls_cons_priv_contr-tipo_record = lc_tipo_record.
*          ls_cons_priv_contr-codice_crm  = ps_header-codice_crm.
*          ls_cons_priv_contr-id_pos      = <fs_item>-number_int.
*          CONCATENATE <fs_priv_tab>-process_type <fs_priv_tab>-id_consenso INTO ls_cons_priv_contr-tipologia.
*          ls_cons_priv_contr-valore      = <value>.
*
*          APPEND ls_cons_priv_contr TO pt_cons_priv_contr.
*          CLEAR ls_cons_priv_contr .
*        ENDLOOP.
*      ENDLOOP.
*    ENDIF.



ENDFORM.                    " f_prepara_cons_priv_contr
*&---------------------------------------------------------------------*
*&      Form  f_prepara_attributi-dimensioni
*&---------------------------------------------------------------------*
FORM f_prepara_attributi_dimensioni  USING    ps_guid          TYPE bapibus20001_guid_dis
                                              ps_header        TYPE t_header
                                     CHANGING pt_attr_dimens   TYPE t_attr_dimens_tab
                                              p_fl_error       TYPE flag.

  CONSTANTS: lc_tipo_record(2) TYPE c VALUE 'AT'.
  DATA: ls_attr_dimens TYPE t_attr_dimens,
        lv_codice      TYPE string.
  FIELD-SYMBOLS <fs_addon_order> TYPE zca_addon_order.

  REFRESH pt_attr_dimens.

  READ TABLE gt_addon_order TRANSPORTING NO FIELDS
    WITH KEY id_contratto = ps_header-codice_crm BINARY SEARCH.

  LOOP AT gt_addon_order ASSIGNING <fs_addon_order> FROM sy-tabix.
    IF <fs_addon_order>-id_contratto NE ps_header-codice_crm.
      EXIT.
    ENDIF.

    ls_attr_dimens-tipo_record  = lc_tipo_record.

    IF <fs_addon_order>-id_contratto IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e34.
      p_fl_error = ca_x.
      EXIT.
    ENDIF.

    ls_attr_dimens-codice_crm   = <fs_addon_order>-id_contratto.

    IF <fs_addon_order>-id_posizione IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e35.
      p_fl_error = ca_x.
      EXIT.
    ENDIF.

    ls_attr_dimens-id_pos       = <fs_addon_order>-id_posizione.

    IF <fs_addon_order>-id_attributo IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e36.
      p_fl_error = ca_x.
      EXIT.
    ENDIF.

    ls_attr_dimens-attributo    = <fs_addon_order>-id_attributo.

    IF <fs_addon_order>-id_dimensione IS INITIAL.
*     -- Scrittura Record di Log
      CLEAR lv_codice.
      lv_codice = ps_header-codice_crm.
      PERFORM f_scrivi_error USING lv_codice
                                   text-e37.
      p_fl_error = ca_x.
      EXIT.
    ENDIF.

    ls_attr_dimens-dimensione   = <fs_addon_order>-id_dimensione.

    APPEND ls_attr_dimens TO pt_attr_dimens.
    CLEAR ls_attr_dimens.
  ENDLOOP.

ENDFORM.                    " f_prepara_attributi-dimensioni
*&---------------------------------------------------------------------*
*&      Form  f_estrai_ZCA_ADDON_ORDER
*&---------------------------------------------------------------------*
*         ESTRAZIOMNE DALLA TAB ZCA_ADDON_ORDER
*----------------------------------------------------------------------*
FORM f_estrai_zca_addon_order.

  CHECK i_header[] IS NOT INITIAL.

  REFRESH gt_addon_order.

  SELECT *
    FROM zca_addon_order
    INTO TABLE gt_addon_order
    FOR ALL ENTRIES IN i_header
   WHERE id_contratto EQ i_header-object_id.

  SORT gt_addon_order BY id_contratto.

ENDFORM.                    " f_estrai_ZCA_ADDON_ORDER
*&---------------------------------------------------------------------*
*&      Form  f_check_cons_pf
*&---------------------------------------------------------------------*
FORM f_check_cons_pf  USING    p_nome_cons    TYPE string
                               p_partner_prod TYPE crmt_item_descr_partner
                      CHANGING p_flag         TYPE flag.


  CONSTANTS:   lc_coro01(12)     TYPE c VALUE 'CORO01-RADIO',
               lc_coro02(12)     TYPE c VALUE 'CORO02-RADIO',
               lc_coro03(12)     TYPE c VALUE 'CORO03-RADIO',
               lc_coro04(12)     TYPE c VALUE 'CORO04-RADIO',
               lc_coro01_ai(15)  TYPE c VALUE 'CORO01_AI-RADIO',
               lc_coro02_ai(15)  TYPE c VALUE 'CORO02_AI-RADIO',
               lc_coro03_ai(15)  TYPE c VALUE 'CORO03_AI-RADIO',
               lc_coro04_ai(15)  TYPE c VALUE 'CORO04_AI-RADIO',
               lc_cpiuric(13)    TYPE c VALUE 'CPIURIC-RADIO',
               lc_cpiutcag(14)   TYPE c VALUE 'CPIUTCAG-RADIO',
               lc_cpiuricai(15)  TYPE c VALUE 'CPIURICAI-RADIO',
               lc_cpiutcagai(16) TYPE c VALUE 'CPIUTCAGAI-RADIO',
               lc_fido06(12)     TYPE c VALUE 'FIDO06-RADIO',
               lc_fido07(12)     TYPE c VALUE 'FIDO07-RADIO',
               lc_fido08(12)     TYPE c VALUE 'FIDO08-RADIO',
               lc_fido09(12)     TYPE c VALUE 'FIDO09-RADIO',
               lc_00000001(8)    TYPE c VALUE '00000001',
               lc_ztsc0316(8)    TYPE c VALUE 'ZTSC0316',
               lc_ztsc0303(8)    TYPE c VALUE 'ZTSC0303',
               lc_ztsc0317(8)    TYPE c VALUE 'ZTSC0317',
               lc_ztsc0318(8)    TYPE c VALUE 'ZTSC0318',
               lc_ztsc0319(8)    TYPE c VALUE 'ZTSC0319'.

  DATA lv_entrato TYPE flag.

  FIELD-SYMBOLS: <fs_partner>  LIKE LINE OF i_partner.

  CLEAR p_flag.

  READ TABLE gt_cond TRANSPORTING NO FIELDS
     WITH KEY z_val_par = p_nome_cons.
  IF sy-subrc IS INITIAL.
    READ TABLE i_partner ASSIGNING <fs_partner>
      WITH KEY partner_no = p_partner_prod.
    CHECK sy-subrc IS INITIAL.

    READ TABLE gt_cond TRANSPORTING NO FIELDS
       WITH KEY z_val_par = p_nome_cons
                z_label   = <fs_partner>-partner_fct.
    CHECK sy-subrc IS INITIAL.
    p_flag = ca_x.
  ELSE.
    p_flag = ca_x.
  ENDIF.

*  CASE p_nome_cons.
*    WHEN lc_coro01 OR lc_coro02 OR lc_coro03 OR lc_coro04.
*      READ TABLE i_partner ASSIGNING <fs_partner>
*        WITH KEY partner_no = p_partner_prod.
*      CHECK sy-subrc IS INITIAL AND ( <fs_partner>-partner_fct EQ lc_00000001 OR <fs_partner>-partner_fct EQ lc_ztsc0316 ).
*      lv_entrato = ca_x.
*    WHEN lc_coro01_ai OR lc_coro02_ai OR lc_coro03_ai OR lc_coro04_ai.
*      READ TABLE i_partner ASSIGNING <fs_partner>
*        WITH KEY partner_no = p_partner_prod.
*      CHECK sy-subrc IS INITIAL AND ( <fs_partner>-partner_fct EQ lc_00000001 OR <fs_partner>-partner_fct EQ lc_ztsc0317 ).
*      lv_entrato = ca_x.
*    WHEN lc_cpiuric.
*      READ TABLE i_partner ASSIGNING <fs_partner>
*        WITH KEY partner_no = p_partner_prod.
*      CHECK sy-subrc IS INITIAL AND ( <fs_partner>-partner_fct EQ lc_00000001 ).
*      lv_entrato = ca_x.
*    WHEN lc_cpiutcag.
*      READ TABLE i_partner ASSIGNING <fs_partner>
*        WITH KEY partner_no = p_partner_prod.
*      CHECK sy-subrc IS INITIAL AND ( <fs_partner>-partner_fct EQ lc_ztsc0318 ).
*      lv_entrato = ca_x.
*    WHEN lc_cpiuricai.
*      READ TABLE i_partner ASSIGNING <fs_partner>
*        WITH KEY partner_no = p_partner_prod.
*      CHECK sy-subrc IS INITIAL AND ( <fs_partner>-partner_fct EQ lc_ztsc0303 ).
*      lv_entrato = ca_x.
*    WHEN lc_cpiutcagai.
*      READ TABLE i_partner ASSIGNING <fs_partner>
*        WITH KEY partner_no = p_partner_prod.
*      CHECK sy-subrc IS INITIAL AND ( <fs_partner>-partner_fct EQ lc_ztsc0319 ).
*      lv_entrato = ca_x.
*    WHEN OTHERS.
*      " niente
*      lv_entrato = ca_x.
*  ENDCASE.
*
*  CHECK lv_entrato = ca_x.



ENDFORM.                    " f_check_cons_pf


*&---------------------------------------------------------------------*
*&      Form  maaf_field
*&---------------------------------------------------------------------*
*       Iniziativa 106592 - Nuovi campi MAAF - Valorizzazione
*----------------------------------------------------------------------*
*      -->P_OBJECT_ID     ID Pratica
*      -->P_CODICE_CAMPO  Valore cercato
*      -->P_VALORE_CAMPO  Campo di output
*----------------------------------------------------------------------*
FORM maaf_field  USING    p_object_id   TYPE crmt_object_id_db
                          p_codice_campo
                 CHANGING p_valore_campo.

  DATA ls_dati_maaf TYPE zca_dati_maaf.
  CLEAR p_valore_campo.
  READ TABLE gt_dati_maaf INTO ls_dati_maaf WITH KEY object_id    = p_object_id
                                                     codice_campo = p_codice_campo.

  IF sy-subrc IS INITIAL AND NOT ls_dati_maaf-valore_campo IS INITIAL.
    MOVE ls_dati_maaf-valore_campo TO p_valore_campo.
  ENDIF.

ENDFORM.                    " MAAF_FIELD

*&---------------------------------------------------------------------*
*&      Form  F_ESTRAI_ORDER_INDEX
*&---------------------------------------------------------------------*
*     Estrazione data3 order_index
*----------------------------------------------------------------------*
FORM f_estrai_order_index USING pt_guid16 TYPE t_guid16_tab.


  DATA: lt_header TYPE STANDARD TABLE OF bapibus20001_header_dis,
        ls_header TYPE bapibus20001_header_dis,
        ls_guid16 TYPE LINE OF t_guid16_tab,
        lt_guid16 TYPE t_guid16_tab.

  REFRESH lt_header.
  CLEAR ls_header.
  LOOP AT i_header INTO ls_header WHERE process_type EQ 'ZMAF' .
    PERFORM trascod_guid_32_16 USING ls_header-guid
                            CHANGING ls_guid16-guid.

    APPEND ls_guid16 TO lt_guid16.
    CLEAR ls_guid16.
  ENDLOOP.

  CHECK lt_guid16[] IS NOT INITIAL.


  SELECT header date_3
   FROM crmd_order_index
   INTO TABLE i_order_index
   FOR ALL ENTRIES IN lt_guid16"pt_guid16
    WHERE header EQ lt_guid16-guid "pt_guid16-guid
      AND pft_1  EQ 'X'.


ENDFORM.                    " F_ESTRAI_ORDER_INDEX

*&---------------------------------------------------------------------*
*&      Form  F_ESTRAI_ID_UNIVOCO_CRONO
*&---------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
FORM f_estrai_id_univoco_crono.

  DATA: ls_header       TYPE bapibus20001_header_dis,
        ls_guid16       TYPE LINE OF t_guid16_tab,
        lt_guid16       TYPE t_guid16_tab,
        ls_cronomapping TYPE zca_cronomapping.

  REFRESH gt_idunivoco_crono.


  " recupero dei soli guid relativi ai contratti CRONO
  LOOP AT i_header INTO ls_header WHERE process_type EQ 'ZCRN'.

    " converto i guid in RAW16
    PERFORM trascod_guid_32_16 USING ls_header-guid
                            CHANGING ls_guid16-guid.

    APPEND ls_guid16 TO lt_guid16.
    CLEAR ls_guid16.
  ENDLOOP.

  CHECK lt_guid16[] IS NOT INITIAL.
  " estrazione dalla ZCA_CRONOMAPPING
  SELECT guid_testata
         id_ermes
         guid_padre
    FROM zca_cronomapping
    INTO TABLE gt_cronomapping
    FOR ALL ENTRIES IN lt_guid16
    WHERE guid_testata = lt_guid16-guid.
  " Begin CP 22.02.2017
  CHECK sy-subrc IS INITIAL.

  SELECT guid object_id
    FROM crmd_orderadm_h
    INTO TABLE gt_idunivoco_crono
    FOR ALL ENTRIES IN gt_cronomapping
    WHERE guid EQ gt_cronomapping-guid_padre.
  " End CP 22.02.2017

ENDFORM.                    " F_ESTRAI_ID_UNIVOCO_CRONO
*&---------------------------------------------------------------------*
*&      Form  F_PREPARA_ATTRIBUTI_ACCESSORI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_HEADER  text
*      <--P_LT_ATTR_ACC  text
*      <--P_FL_ERROR  text
*----------------------------------------------------------------------*
FORM f_prepara_attributi_accessori  USING    ps_header        TYPE t_header
                                    CHANGING pt_attr_acc      TYPE t_attr_acc_tab
                                             p_fl_error       TYPE flag.

  CONSTANTS: lc_tipo_record(2) TYPE c VALUE 'AC'.
  DATA: ls_attr_acc TYPE t_attr_acc,
        lv_codice   TYPE string.
  FIELD-SYMBOLS <fs_zca_spid_prod> TYPE t_zca_spid_prod .

  REFRESH pt_attr_acc.

  READ TABLE i_zca_spid_prod  TRANSPORTING NO FIELDS
    WITH KEY id_pratica = ps_header-codice_crm BINARY SEARCH.

  LOOP AT i_zca_spid_prod  ASSIGNING <fs_zca_spid_prod> FROM sy-tabix.
    IF <fs_zca_spid_prod>-id_pratica NE ps_header-codice_crm.
      EXIT.
    ENDIF.
    ls_attr_acc-tipo_record   = lc_tipo_record.
    ls_attr_acc-codice_crm    = <fs_zca_spid_prod>-id_pratica.
    ls_attr_acc-attributo_1   = <fs_zca_spid_prod>-prodotto.

    APPEND ls_attr_acc TO pt_attr_acc.
    CLEAR ls_attr_acc.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F_ESTRAI_DATI_AGGIUNTIVI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_GUID16  text
*----------------------------------------------------------------------*
FORM f_estrai_dati_aggiuntivi  USING    lt_guid16 TYPE t_guid16_tab.
  SELECT parent_id
         zz_mod_pag
         zz_visa_maestro
         zz_pagobancomat
         zz_postamat
         zz_rend_cart
         zz_strum_regolam
         zz_liv_acc_add
         zz_iban_acc
         zz_grande_eserc    " RU 11/10/2018
         zz_mot_reinoltro "RU 13.09.2019 11:28:40
* 105900: ASTERISCATO IN ATTESA DEL PASSAGGIO DI FA FASE 2 - INIZIO.
*         zz_bus_eserc_con
*         zz_bus_eserc_tip
*         zz_bus_eserc_sta
*         zz_bus_eserc_per
* 105900: ASTERISCATO IN ATTESA DEL PASSAGGIO DI FA FASE 2 - FINE
   FROM zca_dati_agg_acq INTO TABLE i_dati_agg_fa
   FOR ALL ENTRIES IN lt_guid16
   WHERE parent_id EQ lt_guid16-guid
     AND zz_grande_eserc NE '2'.   " RU 11/10/2018 esclusione contratti figlio

* 18.06-18.07 modifiche provvisorie per estrazione strumento regolamento
*             se liv accredito = 02 allora il dato viene prelevato dalla tab Punti di vendita
  DATA: s_dati_agg_fa  TYPE t_dati_agg_fa,
        lv_padre       TYPE crmt_object_id_db,
        lv_figlio      TYPE crmt_object_id_db,
        lv_guid_figlio TYPE crmt_object_guid.

  LOOP AT i_dati_agg_fa INTO s_dati_agg_fa.

    IF s_dati_agg_fa-zz_strum_regolam IS INITIAL AND
       s_dati_agg_fa-zz_liv_acc_add   EQ '02'.

      IF s_dati_agg_fa-zz_grande_eserc IS INITIAL.

        SELECT SINGLE zzz_str_reg_add
          FROM zpuntivendita INTO s_dati_agg_fa-zz_strum_regolam
          WHERE zzz_str_reg_add NE space
            AND object_id       EQ s_dati_agg_fa-parent_id.

        MODIFY i_dati_agg_fa FROM s_dati_agg_fa.

      ELSEIF s_dati_agg_fa-zz_grande_eserc = '1'.  "RU 11/10/2018 estrazioni da tabella relazioni per recupero dei contratti figlio

        SELECT SINGLE object_id
          FROM crmd_orderadm_h
          INTO lv_padre
          WHERE guid = s_dati_agg_fa-parent_id.

        SELECT SINGLE figlio
          FROM zrelazioni_fa
          INTO lv_figlio
          WHERE padre = lv_padre.

        SELECT SINGLE guid
          FROM crmd_orderadm_h
          INTO lv_guid_figlio
          WHERE object_id = lv_figlio.

        SELECT SINGLE zzz_str_reg_add
          FROM zpuntivendita INTO s_dati_agg_fa-zz_strum_regolam
          WHERE zzz_str_reg_add NE space
            AND object_id       EQ lv_guid_figlio.

        MODIFY i_dati_agg_fa FROM s_dati_agg_fa.

      ENDIF.

    ENDIF.

  ENDLOOP.





ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F_RINOMINA_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_rinomina_file .
  CLEAR lv_parameters.
  CONCATENATE va_fileout_temp va_fileout INTO lv_parameters SEPARATED BY space.


  CALL FUNCTION 'SXPG_COMMAND_EXECUTE'
    EXPORTING
      commandname                   = 'Z_MV_FLUSSI'
      additional_parameters         = lv_parameters
    EXCEPTIONS
      no_permission                 = 1
      command_not_found             = 2
      parameters_too_long           = 3
      security_risk                 = 4
      wrong_check_call_interface    = 5
      program_start_error           = 6
      program_termination_error     = 7
      x_error                       = 8
      parameter_expected            = 9
      too_many_parameters           = 10
      illegal_command               = 11
      wrong_asynchronous_parameters = 12
      cant_enq_tbtco_entry          = 13
      jobcount_generation_error     = 14
      OTHERS                        = 15.
  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-010. " Errore durante la ridenominazione del file.
  ENDIF.

ENDFORM.
* Inizio Mod. MN - Gestione temp. codice ufficio - 22.11.2018
*&---------------------------------------------------------------------*
*&      Form  F_GET_BPKIND -->  Recupero bpkind committenti privati
*&                              o non definiti
*&---------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
FORM f_get_bpkind  USING    p_partner TYPE t_partner_t
                   CHANGING pt_bpkind TYPE t_but000_t.

  DATA: lt_committenti TYPE t_but000_t,
        ls_committenti TYPE t_but000.
*        lr_range       TYPE RANGE OF but000-bpkind,
*        ls_range       LIKE LINE OF lr_range.

  LOOP AT p_partner ASSIGNING FIELD-SYMBOL(<partner>) WHERE partner_fct EQ '00000001'.
    ls_committenti-partner = <partner>-partner_no.
    APPEND ls_committenti TO lt_committenti.
  ENDLOOP.

  CHECK lt_committenti[] IS NOT INITIAL.

*  " BPKIND ZPRI o space
*  ls_range-option = 'EQ'.
*  ls_range-sign   = 'I'.
*  APPEND ls_range TO lr_range.
*  ls_range-low    = 'ZPRI'.
*  APPEND ls_range TO lr_range.
  SELECT partner bpkind
    FROM but000
    INTO TABLE pt_bpkind
    FOR ALL ENTRIES IN lt_committenti
    WHERE partner EQ lt_committenti-partner.
*    AND   bpkind  IN lr_range.

ENDFORM.
* Fine Mod. MN - Gestione temp. codice ufficio - 22.11.2018


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
