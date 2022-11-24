FUNCTION z_web_contract_tipol.
*"----------------------------------------------------------------------
*"*"Interfaccia locale:
*"  IMPORTING
*"     VALUE(I_APPLICAZIONE) TYPE  ZAPPL OPTIONAL
*"     VALUE(I_TIPO_CONTO) TYPE  ZCA_TIPO_CONTO
*"     VALUE(I_MOD_CONTO) TYPE  ZCA_ID OPTIONAL
*"     VALUE(I_TIPO_CLIENTE) TYPE  CHAR10 OPTIONAL
*"  EXPORTING
*"     VALUE(ES_NAZIONE) TYPE  ZCA_NAZIONE_S
*"     VALUE(ES_PROVINCIA) TYPE  ZCA_PROV_S
*"     VALUE(ES_WORKSSIONE) TYPE  ZCA_WORK_S
*"     VALUE(ES_TITOLO_STUDIO) TYPE  ZCA_TIT_STUDIO_S
*"     VALUE(ES_TIPO_ABITAZIONE) TYPE  ZCA_TIP_ABIT_S
*"     VALUE(ES_STATO_CIVILE) TYPE  ZCA_STAT_CIVILE_S
*"     VALUE(ES_ATTIVITA) TYPE  ZCA_ATTIVITA_S
*"     VALUE(ES_SETTORE) TYPE  ZCA_SETTORE_S
*"     VALUE(ES_NUM_DIPENDENTI) TYPE  ZCA_NUM_DIP_S
*"     VALUE(ES_QUALIFICA) TYPE  ZCA_QUALIFICA_S
*"     VALUE(ES_GRADO_PARENTELA) TYPE  ZCA_GRAD_PARENT_S
*"     VALUE(ES_TIPO_DOCUMENTO) TYPE  ZCA_TIPO_DOC_S
*"     VALUE(ES_ENTE_DOCUMENTO) TYPE  ZCA_TIPO_ENTE_S
*"     VALUE(ES_PROFESSIONE_CRM) TYPE  ZST_PROFESSIONE_CRM
*"     VALUE(ES_ENTE_DOCUMENTO_CRM) TYPE  ZST_ENTE_DOCUMENTO_CRM
*"     VALUE(ES_TIPO_DOCUMENTO_CRM) TYPE  ZST_TIPO_DOCUMENTO_CRM
*"     VALUE(ES_SCOPOCARTA) TYPE  ZCA_SCOPOCARTA_S
*"     VALUE(ES_SCOPO_BP) TYPE  ZCA_SCOPOBP_S
*"     VALUE(ES_TIPO_STATO) TYPE  ZCA_TIP_STATO_S
*"     VALUE(ES_TIP_IMPORTO) TYPE  ZCA_TIP_IMPORTO_S
*"     VALUE(ES_TIP_SCOPO_RAPPORTO) TYPE  ZCA_SCOPO_RAPPORTO_S
*"     VALUE(ES_TIP_TIPO_FIDO) TYPE  ZCA_TIPO_FIDO_S
*"     VALUE(ES_TIP_MOTIVO_FIDO) TYPE  ZCA_MOTIVO_FIDO_S
*"     VALUE(ES_TIP_ORIGINEFONDI) TYPE  ZCA_ORIGINEFONDI_S
*"     VALUE(ES_NATURA_RC) TYPE  ZCA_NATURA_RC_S
*"     VALUE(ES_TIPO_LEGAME) TYPE  ZCA_TIPO_LEGAME_S
*"     VALUE(ES_PROF_DELEGATO) TYPE  ZCA_PROF_DEL_S
*"     VALUE(ES_FREQUENZA_DELEGA) TYPE  ZCA_FREQUENZA_DE_S
*"     VALUE(ES_MOTIVO_DELEGA) TYPE  ZCA_MOTIVO_DEL_S
*"     VALUE(ES_NOME_ALTRA_CARTA) TYPE  ZCA_NOME_ALTRA_CARTA_S
*"     VALUE(ES_STATO_CIVILE_AMEXV) TYPE  ZCA_STCIVAMEXV_S
*"     VALUE(ES_ATTIVITA_AMEXV) TYPE  ZCA_CATEGORIA_S
*"     VALUE(ES_SETTORE_AMEXV) TYPE  ZCA_SETTORE_AMEX_S
*"     VALUE(ES_SCOPO_CARTA_AMEXV) TYPE  ZCA_SCO_CARTA_AV_S
*"     VALUE(ES_TIPO_ABITAZIONE_AMEXV) TYPE  ZCA_ABITA_AV_S
*"     VALUE(ES_IDN_TITOLARE) TYPE  ZCA_IDN_TIT_S
*"     VALUE(ES_HOLDING) TYPE  ZCA_GECHOLDING_S
*"     VALUE(ES_TIPCONT_CARPUB) TYPE  ZCA_TPCNT_CARPUB_S
*"     VALUE(ES_TIPCONT_NUMADD) TYPE  ZCA_TPCNT_NUMADD_S
*"     VALUE(ES_TIPCONT_RELINTER) TYPE  ZCA_TPCNT_RELINT_S
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
*--------------------------------------------------------------------------*
* - Autore: Maria Ferrara
* - Data:   23.09.2011
* - ID:     CC_RET_Gestione_Contratti_01
* - Descr:  Recupero Tipologiche del contratto
* --------------------------------------------------------------------------*
  DATA: ls_work               TYPE zca_work_s,
        ls_tip_abit           TYPE zca_tip_abit_s,
        ls_stat_civ           TYPE zca_stat_civile_s,
        ls_attivita           TYPE zca_attivita_s,
        ls_settore            TYPE zca_settore_s,
        ls_num_dipendenti     TYPE zca_num_dip_s,
        ls_qualifica          TYPE zca_qualifica_s,
        ls_grado_parentela    TYPE zca_grad_parent_s,
        ls_tipo_documento     TYPE zca_tipo_doc_s,
        ls_ente_documento     TYPE zca_tipo_ente_s,
        ls_tipo_documento_crm TYPE zst_tipo_documento_crm,
        ls_professione_crm    TYPE zst_professione_crm,
        ls_ente_documento_crm TYPE zst_ente_documento_crm,
        ls_scopocarta         TYPE zca_scopocarta_s, "add mf 05/12/2011
        ls_scopo_bp           TYPE zca_scopobp_s,    "add mf 05/12/2011
        ls_tipo_stato         TYPE zca_tip_stato_s,  "add mf 05/12/2011
" Inizio AS 25.05.2012
        ls_tip_importo        TYPE zca_tip_importo_s,
        ls_tip_scopo_rapporto TYPE zca_scopo_rapporto_s,
        ls_tip_tipo_fido      TYPE zca_tipo_fido_s,
        ls_tip_motivo_fido    TYPE zca_motivo_fido_s,
        ls_tip_originefondi   TYPE zca_originefondi_s,
  " Fine   AS 25.05.2012
        ls_natura_rc          TYPE zca_natura_rc_s, "add md 18/06/2012
* Begin AG 06.09.2012
        ls_tipo_legame        TYPE  zca_tipo_legame_s,
        ls_prof_delegato      TYPE  zca_prof_del_s,
        ls_frequenza_delega   TYPE  zca_frequenza_de_s,
        ls_motivo_delega      TYPE  zca_motivo_del_s,
* End   AG 06.09.2012

  " Inizio AS 23.09.2013
        ls_stato_civile_amexv     TYPE  zca_stcivamexv_s,
        ls_attivita_amexv         TYPE  zca_categoria_s,
        ls_settore_amexv          TYPE  zca_settore_amex_s,
        ls_scopo_carta_amexv      TYPE  zca_sco_carta_av_s,
        ls_tipo_abitazione_amexv  TYPE  zca_abita_av_s,
  " Fine AS 23.09.2013

  " Inizio AL 19.02.2014
        ls_idn_titolare     TYPE  zca_idn_tit_s,
        ls_holding         TYPE  zca_gecholding_s,
  " Fine AL 19.02.2014

        ls_nome_altra_carta   TYPE  zca_nome_altra_carta_s,  "Add CNT 15.02.2013
* Begin MS 24.06.2014 10:02:23
        ls_tipcont_carpub     type zca_tpcnt_carpub_s,
        ls_tipcont_numadd     type zca_tpcnt_numadd_s,
        ls_tipcont_relinter   type zca_tpcnt_relint_s.
* End MS 24.06.2014 10:02:23
  REFRESH: gt_tipol, et_return.
  PERFORM f_pulizia CHANGING es_nazione
                             es_provincia
                             es_workssione
                             es_titolo_studio
                             es_tipo_abitazione
                             es_stato_civile
                             es_attivita
                             es_settore
                             es_num_dipendenti
                             es_qualifica
                             es_grado_parentela
                             es_tipo_documento
                             es_ente_documento
                             es_scopocarta "add mf 05/12/2011
                             es_scopo_bp"add mf 05/12/2011
                             es_tipo_stato"add mf 05/12/2011
" Inizio AS 25.05.2012
                             es_tip_importo
                             es_tip_scopo_rapporto
                             es_tip_tipo_fido
                             es_tip_motivo_fido
                             es_tip_originefondi
  " Fine   AS 25.05.2012
                             es_natura_rc"add mf 18/06/2012
* Begin AG 06.09.2012
                             es_tipo_legame
                             es_prof_delegato
                             es_frequenza_delega
                             es_motivo_delega
* End   AG 06.09.2012
                             es_nome_altra_carta  "Add CNT 15.02.2013
" Inizio AS 23.09.2013
                             es_stato_civile_amexv
                             es_attivita_amexv
                             es_settore_amexv
                             es_scopo_carta_amexv
                             es_tipo_abitazione_amexv
  " Fine AS 23.09.2013

" Inizio AL 19.02.2014
                             es_idn_titolare
                             es_holding
* Begin MS 24.06.2014 09:40:40
                             es_tipcont_carpub
                             es_tipcont_numadd
                             es_tipcont_relinter.
* End MS 24.06.2014 09:40:40
  " Fine AL 19.02.2014




  PERFORM f_extract_from_tipolog USING  i_tipo_conto
                                        i_mod_conto
                                        i_tipo_cliente
                               CHANGING et_return[].

  CHECK et_return[] IS INITIAL .

  PERFORM f_estrazioni     USING i_tipo_conto
                        CHANGING ls_work
                                 ls_tip_abit
                                 ls_stat_civ
                                 ls_attivita
                                 ls_settore
                                 ls_num_dipendenti
                                 ls_qualifica
                                 ls_grado_parentela
                                 ls_tipo_documento
                                 ls_ente_documento
                                 ls_tipo_documento_crm
                                 ls_professione_crm
                                 ls_ente_documento_crm
                                 ls_scopocarta  "add mf 05/12/2011
                                 ls_scopo_bp    "add mf 05/12/2011
                                 ls_tipo_stato  "add mf 05/12/2011.
" Inizio AS 25.05.2012
                                 ls_tip_importo
                                 ls_tip_scopo_rapporto
                                 ls_tip_tipo_fido
                                 ls_tip_motivo_fido
                                 ls_tip_originefondi
  " Fine   AS 25.05.2012
                                 ls_natura_rc  "add mf 18/06/2012
* Begin AG 06.09.2012
                                 ls_tipo_legame
                                 ls_prof_delegato
                                 ls_frequenza_delega
                                 ls_motivo_delega
* End   AG 06.09.2012
                                 ls_nome_altra_carta "add CNT 15.02.2013
  " Inizio AS 23.09.2013
                                 ls_stato_civile_amexv
                                 ls_attivita_amexv
                                 ls_settore_amexv
                                 ls_scopo_carta_amexv
                                 ls_tipo_abitazione_amexv
  " Fine AS 23.09.2013

" Inizio AL 19.02.2014
                                 ls_idn_titolare
                                 ls_holding
* Begin MS 24.06.2014 09:40:40
                                 ls_tipcont_carpub
                                 ls_tipcont_numadd
                                 ls_tipcont_relinter.
* End MS 24.06.2014 09:40:40.
  " Fine AS 19.02.2014


  PERFORM f_set_et_contract_tipol CHANGING ls_work
                                           ls_tip_abit
                                           ls_stat_civ
                                           ls_attivita
                                           ls_settore
                                           ls_num_dipendenti
                                           ls_qualifica
                                           ls_grado_parentela
                                           ls_tipo_documento
                                           ls_ente_documento
                                           ls_tipo_documento_crm
                                           ls_professione_crm
                                           ls_ente_documento_crm
                                           ls_scopocarta"add mf 05/12/2011
                                           ls_scopo_bp "add mf 05/12/2011
                                           ls_tipo_stato  "add mf 05/12/2011
" Inizio AS 25.05.2012
                                           ls_tip_importo
                                           ls_tip_scopo_rapporto
                                           ls_tip_tipo_fido
                                           ls_tip_motivo_fido
                                           ls_tip_originefondi
" Fine   AS 25.05.2012
                                           ls_natura_rc "add mf 18/06/2012
* Begin AG 06.09.2012
                                           ls_tipo_legame
                                           ls_prof_delegato
                                           ls_frequenza_delega
                                           ls_motivo_delega
* End   AG 06.09.2012
                                           ls_nome_altra_carta  "add CNT 15.02.2013
  " Inizio AS 23.09.2013
                                           ls_stato_civile_amexv
                                           ls_attivita_amexv
                                           ls_settore_amexv
                                           ls_scopo_carta_amexv
                                           ls_tipo_abitazione_amexv
  " Fine AS 23.09.2013
  " Inizio AL 19.02.2014
                                           ls_idn_titolare
                                           ls_holding
* Begin MS 24.06.2014 10:12:04

                                           ls_tipcont_carpub
                                           ls_tipcont_numadd
                                           ls_tipcont_relinter
* End MS 24.06.2014 10:12:04
  " Fine AL 19.02.2014
                                           es_nazione
                                           es_provincia
                                           es_workssione
                                           es_titolo_studio
                                           es_tipo_abitazione
                                           es_stato_civile
                                           es_attivita
                                           es_settore
                                           es_num_dipendenti
                                           es_qualifica
                                           es_grado_parentela
                                           es_tipo_documento
                                           es_ente_documento
                                           es_professione_crm
                                           es_ente_documento_crm
                                           es_tipo_documento_crm
                                           es_scopocarta "add mf 05/12/2011
                                           es_scopo_bp"add mf 05/12/2011
                                           es_tipo_stato"add mf 05/12/2011
" Inizio AS 25.05.2012
                                           es_tip_importo
                                           es_tip_scopo_rapporto
                                           es_tip_tipo_fido
                                           es_tip_motivo_fido
                                           es_tip_originefondi
  " Fine   AS 25.05.2012
                                           es_natura_rc"add mf 18/06/2012
* Begin AG 06.09.2012
                                           es_tipo_legame
                                           es_prof_delegato
                                           es_frequenza_delega
                                           es_motivo_delega
* End   AG 06.09.2012
                                           es_nome_altra_carta  "Add CNT 15.02.2013
" Inizio AS 23.09.2013
                                           es_stato_civile_amexv
                                           es_attivita_amexv
                                           es_settore_amexv
                                           es_scopo_carta_amexv
                                           es_tipo_abitazione_amexv
  " Fine AS 23.09.2013
  " Inizio AL 19.02.2014
                                           es_idn_titolare
                                           es_holding
* Begin MS 24.06.2014 09:40:40
                                           es_tipcont_carpub
                                           es_tipcont_numadd
                                           es_tipcont_relinter
* End MS 24.06.2014 09:40:40
  " Fine AL 19.02.2014
                                           et_return[].

  IF et_return[] IS NOT INITIAL.

    PERFORM f_pulizia CHANGING es_nazione
                              es_provincia
                              es_workssione
                              es_titolo_studio
                              es_tipo_abitazione
                              es_stato_civile
                              es_attivita
                              es_settore
                              es_num_dipendenti
                              es_qualifica
                              es_grado_parentela
                              es_tipo_documento
                              es_ente_documento
                              es_scopocarta "add mf 05/12/2011
                              es_scopo_bp   "add mf 05/12/2011
                              es_tipo_stato "add mf 05/12/2011
" Inizio AS 25.05.2012
                              es_tip_importo
                              es_tip_scopo_rapporto
                              es_tip_tipo_fido
                              es_tip_motivo_fido
                              es_tip_originefondi
    " Fine   AS 25.05.2012
                              es_natura_rc "add mf 18/06/2012
* Begin AG 06.09.2012
                              es_tipo_legame
                              es_prof_delegato
                              es_frequenza_delega
                              es_motivo_delega
* End   AG 06.09.2012
                              es_nome_altra_carta "Add CNT 15.02.2013
" Inizio AS 23.09.2013
                             es_stato_civile_amexv
                             es_attivita_amexv
                             es_settore_amexv
                             es_scopo_carta_amexv
                             es_tipo_abitazione_amexv
    " Fine AS 23.09.2013

" Inizio AL 19.02.2014
                             es_idn_titolare
                             es_holding
* Begin MS 24.06.2014 09:40:40
                             es_tipcont_carpub
                             es_tipcont_numadd
                             es_tipcont_relinter.
* End MS 24.06.2014 09:40:40
    " Fine AL 19.02.2014
  ENDIF.

ENDFUNCTION.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
