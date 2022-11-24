# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20170831
#
# ATTENZIONE: non indentare automaticamente !!!!
#

# rubocop:disable Metrics/LineLength, Metrics/ModuleLength, Style/ClosingParenthesisIndentation, Style/AlignParameters
module Irma
  Constant.define(:tipo_competenza,
    nessuna:         { descr: 'nessuna',       value: (1 << -1) },
    sistema:         { descr: 'sistema',       value: (1 << 0) },
    omcfisico:       { descr: 'omcfisico',     value: (1 << 1) },
    vendorrelease:   { descr: 'vendorrelease', value: (1 << 2) },
    admin:           { descr: 'admin',         value: (1 << 3) }
  )

  Constant.define(:riferimento_segnalazioni,
    omc_fisico:           'omc_fisico',
    progetto_irma:        'progetto_irma',
    progetto_radio:       'progetto_radio',
    report_comparativo:   'report_comparativo',
    sistema:              'sistema',
    adrn:                 'adrn'
  )

  def self.tutte_le_funzioni(*funzioni)
    [funzioni].flatten.map { |p| ([p] + (Constant.info(:funzione, p)[:dipendenze] || []).map { |dp| tutte_le_funzioni(dp) }) }.flatten.sort.uniq
  end

  def self.tutte_le_funzioni_richieste_da(*funzioni)
    [funzioni].flatten.map { |p| ([p] + (Constant.info(:funzione, p)[:richiesta_da] || []).map { |dp| tutte_le_funzioni_richieste_da(dp) }) }.flatten.sort.uniq
  end

  Constant.define(:funzione,
    # Read
    lista_attivita:                 { value:   1, nome: 'LISTA_ATTIVITA',                 descr: 'Funzione visualizzazione lista attivita',             tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    lista_sessioni:                 { value:   2, nome: 'LISTA_SESSIONI',                 descr: 'Funzione visualizzazione lista sessioni',             tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    lista_accounts:                 { value:   3, nome: 'LISTA_ACCOUNTS',                 descr: 'Funzione visualizzazione lista accounts',             tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    lista_allarmi:                  { value:   4, nome: 'LISTA_ALLARMI',                  descr: 'Funzione visualizzazione lista allarmi',              tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    lista_eventi:                   { value:   5, nome: 'LISTA_EVENTI',                   descr: 'Funzione visualizzazione lista eventi',               tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    lista_app_config:               { value:   6, nome: 'LISTA_APP_CONFIG',               descr: 'Funzione visualizzazione lista parametri di sistema', tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    lista_segnalazioni:             { value:   7, nome: 'LISTA_SEGNALAZIONI',             descr: 'Funzione visualizzazione lista segnalazioni',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA | TIPO_COMPETENZA_OMCFISICO | TIPO_COMPETENZA_VENDORRELEASE },
    lista_anagrafica:               { value:   8, nome: 'LISTA_ANAGRAFICA',               descr: 'Funzione visualizzazione lista anagrafica',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA | TIPO_COMPETENZA_OMCFISICO | TIPO_COMPETENZA_VENDORRELEASE },
    lista_meta_modello:             { value:   9, nome: 'LISTA_META_MODELLO',             descr: 'Funzione visualizzazione lista meta modello',         tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE },
    lista_attivita_schedulate:      { value:  10, nome: 'LISTA_ATTIVITA_SCHEDULATE',      descr: 'Funzione visualizzazione attivita schedulate',        tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    lista_storico_attivita:         { value:  11, nome: 'LISTA_STORICO_ATTIVITA',         descr: 'Funzione visualizzazione storico attivita',           tipo_competenza: TIPO_COMPETENZA_NESSUNA },

    # Write
    gestione_accounts:              { value:  51, nome: 'GESTIONE_ACCOUNTS',              descr: 'Funzione gestione accounts',                          tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    gestione_allarmi:               { value:  52, nome: 'GESTIONE_ALLARMI',               descr: 'Funzione gestione allarmi',                           tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    gestione_eventi:                { value:  53, nome: 'GESTIONE_EVENTI',                descr: 'Funzione gestione eventi',                            tipo_competenza: TIPO_COMPETENZA_NESSUNA },
    gestione_app_config:            { value:  54, nome: 'GESTIONE_APP_CONFIG',            descr: 'Funzione gestione parametri di sistema',              tipo_competenza: TIPO_COMPETENZA_ADMIN },
    gestione_segnalazioni:          { value:  55, nome: 'GESTIONE_SEGNALAZIONI',          descr: 'Funzione gestione delle segnalazioni',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA | TIPO_COMPETENZA_OMCFISICO | TIPO_COMPETENZA_VENDORRELEASE },
    gestione_anagrafica:            { value:  56, nome: 'GESTIONE_ANAGRAFICA',            descr: 'Funzione gestione dell\'anagrafica',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA | TIPO_COMPETENZA_OMCFISICO | TIPO_COMPETENZA_VENDORRELEASE },
    gestione_meta_modello:          { value:  57, nome: 'GESTIONE_META_MODELLO',          descr: 'Funzione gestione del meta modello',                  tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE },
    gestione_attivita_schedulate:   { value:  58, nome: 'GESTIONE_ATTIVITA_SCHEDULATE',   descr: 'Funzione gestione attivita schedulate',               tipo_competenza: TIPO_COMPETENZA_NESSUNA },

    gestione_esecuzioni_composte:   { value:  59, nome: 'GESTIONE_ESECUZIONI_COMPOSTE',   descr: 'Funzione gestione esecuzioni composte',               tipo_competenza: TIPO_COMPETENZA_SISTEMA },

    # OMC: 100 - 199
    import_omc_logico:              { value: 100, nome: 'IMPORT_OMC_LOGICO',              descr: 'Funzione Import Omc Logico',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    import_omc_fisico:              { value: 101, nome: 'IMPORT_OMC_FISICO',              descr: 'Funzione Import Omc Fisico',
                                      tipo_competenza: TIPO_COMPETENZA_OMCFISICO,         riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_OMC_FISICO },
    import_formato_utente:          { value: 102, nome: 'IMPORT_FORMATO_UTENTE',          descr: 'Funzione Import Formato Utente',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    export_formato_utente:          { value: 103, nome: 'EXPORT_FORMATO_UTENTE',          descr: 'Funzione Export Formato Utente',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    export_fu_omc_fisico:           { value: 104, nome: 'EXPORT_FU_OMC_FISICO',           descr: 'Funzione Export Formato Utente Omc Fisico',
                                      tipo_competenza: TIPO_COMPETENZA_OMCFISICO,         riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_OMC_FISICO },
    export_formato_utente_parziale: { value: 105, nome: 'EXPORT_FORMATO_UTENTE_PARZIALE', descr: 'Funzione Export Formato Utente Parziale',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    export_fu_omc_fisico_parziale:  { value: 106, nome: 'EXPORT_FU_OMC_FISICO_PARZIALE',  descr: 'Funzione Export Formato Utente Parziale per Omc Fisico',
                                      tipo_competenza: TIPO_COMPETENZA_OMCFISICO,         riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_OMC_FISICO },
    creazione_fdc_omc_logico:       { value: 107, nome: 'CREAZIONE_FDC_OMC_LOGICO',       descr: 'Funzione Creazione FdC Omc Logico',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_IRMA },
    creazione_fdc_omc_fisico:       { value: 108, nome: 'CREAZIONE_FDC_OMC_FISICO',       descr: 'Funzione Creazione FdC Omc Fisico',
                                      tipo_competenza: TIPO_COMPETENZA_OMCFISICO,         riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_IRMA },
    import_fu_omc_fisico:           { value: 109, nome: 'IMPORT_FU_OMC_FISICO',           descr: 'Funzione Import Formato Utente Omc Fisico',
                                      tipo_competenza: TIPO_COMPETENZA_OMCFISICO,         riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_OMC_FISICO },
    creazione_fdc_cna_logico:       { value: 110, nome: 'CREAZIONE_FDC_CNA_LOGICO',       descr: 'Funzione Creazione FdC Cna Omc Logico',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_IRMA },
    creazione_fdc_cna_fisico:       { value: 111, nome: 'CREAZIONE_FDC_CNA_FISICO',       descr: 'Funzione Creazione FdC Cna Omc Fisico',
                                      tipo_competenza: TIPO_COMPETENZA_OMCFISICO,         riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_IRMA },
    visualizza_eccezioni:           { value: 112, nome: 'VISUALIZZA_ECCEZIONI',           descr: 'Funzione visualizzazione Eccezioni',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    aggiorna_eccezioni:             { value: 113, nome: 'AGGIORNA_ECCEZIONI',             descr: 'Funzione Aggiornamento Eccezioni',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    elimina_eccezioni:              { value: 114, nome: 'ELIMINA_ECCEZIONI',              descr: 'Funzione Eliminazione Eccezioni per Etichetta',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    conteggio_alberature_ade:       { value: 115, nome: 'CONTEGGIO_ALBERATURE_ADE',       descr: 'Conteggio Alberature su AdE',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },

    # PI: 200 - 249
    pi_calcolo:                     { value: 200, nome: 'PI_CALCOLO',                     descr: 'Funzione Calcolo PI',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_IRMA },
    pi_visualizza:                  { value: 201, nome: 'PI_VISUALIZZA',                  descr: 'Funzione Visualizza PI',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA },
    pi_import_formato_utente:       { value: 202, nome: 'PI_IMPORT_FORMATO_UTENTE',       descr: 'Funzione Import Formato Utente su PI',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_IRMA },
    pi_calcolo_copia:               { value: 203, nome: 'PI_CALCOLO_COPIA',               descr: 'Funzione Copia PI',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_IRMA },
    pi_export_fu_totale:            { value: 204, nome: 'PI_EXPORT_FU_TOTALE',            descr: 'Funzione Export Formato Utente Totale su PI',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA },
    # PRN: 250 - 299
    import_progetto_radio:          { value: 250, nome: 'IMPORT_PROGETTO_RADIO',          descr: 'Funzione Import PRN',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_RADIO },
    visualizza_prn:                 { value: 251, nome: 'VISUALIZZA_PRN',                 descr: 'Funzione Visualizza PRN',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA },
    completa_enodebid:              { value: 252, nome: 'COMPLETA_ENODEBID',              descr: 'Funzione Completa ENODEBID',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_RADIO },
    export_progetto_radio:          { value: 253, nome: 'EXPORT_PROGETTO_RADIO',          descr: 'Funzione Export Progetto Radio',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_RADIO },
    elimina_celle_da_prn:           { value: 254, nome: 'ELIMINA_CELLE_DA_PRN',           descr: 'Funzione Elimina_celle_da_prn',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_RADIO },
    completa_cgi:                   { value: 255, nome: 'COMPLETA_CGI',                   descr: 'Funzione Completa CGI',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_PROGETTO_RADIO },

    # REPORT COMPARATIVO: 300 - 349
    report_comparativo:                          { value: 300, nome: 'REPORT_COMPARATIVO',                          descr: 'Funzione Report Comparativo',
                                                   tipo_competenza: TIPO_COMPETENZA_SISTEMA,                        riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_REPORT_COMPARATIVO },
    report_comparativo_omc_fisico:               { value: 301, nome: 'REPORT_COMPARATIVO_OMC_FISICO',               descr: 'Funzione Report Comparativo per Omc Fisico',
                                                   tipo_competenza: TIPO_COMPETENZA_OMCFISICO,                      riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_REPORT_COMPARATIVO },
    visualizza_report_comparativo:               { value: 302, nome: 'VISUALIZZA_REPORT_COMPARATIVO',               descr: 'Funzione Visualizza Report Comparativo',
                                                   tipo_competenza: TIPO_COMPETENZA_SISTEMA },
    export_report_comparativo_totale:            { value: 303, nome: 'EXPORT_REPORT_COMPARATIVO_TOTALE',            descr: 'Funzione Export Report Comparativo Totale',
                                                   tipo_competenza: TIPO_COMPETENZA_SISTEMA,                        riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_REPORT_COMPARATIVO },
    export_report_comparativo_totale_omc_fisico: { value: 304, nome: 'EXPORT_REPORT_COMPARATIVO_TOTALE_OMC_FISICO', descr: 'Funzione Export Report Comparativo Totale per Omc Fisico',
                                                   tipo_competenza: TIPO_COMPETENZA_OMCFISICO,                      riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_REPORT_COMPARATIVO },
    export_report_comparativo_fu:                { value: 305, nome: 'EXPORT_REPORT_COMPARATIVO_FU',                descr: 'Funzione Export Report Comparativo Formato Utente',
                                                   tipo_competenza: TIPO_COMPETENZA_SISTEMA,                        riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_REPORT_COMPARATIVO },
    export_report_comparativo_fu_omc_fisico:     { value: 306, nome: 'EXPORT_REPORT_COMPARATIVO_FU_OMC_FISICO',     descr: 'Funzione Export Report Comparativo Formato Utente per Omc Fisico',
                                                   tipo_competenza: TIPO_COMPETENZA_OMCFISICO,                      riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_REPORT_COMPARATIVO },
    conteggio_alberature:                        { value: 307, nome: 'CONTEGGIO_ALBERATURE',                        descr: 'Conteggio Alberature su Report Comparativi',
                                                   tipo_competenza: TIPO_COMPETENZA_SISTEMA,                        riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_REPORT_COMPARATIVO },

    # ADRN: 350 - 399
    export_adrn:                     { value: 351, nome: 'EXPORT_ADRN',                     descr: 'Funzione export meta_modello adrn per vendor_release',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE,       riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_ADRN },
    import_adrn:                     { value: 352, nome: 'IMPORT_ADRN',                     descr: 'Funzione import meta_modello adrn per vendor_release',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE,       riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_ADRN },
    lista_template_pr:               { value: 353, nome: 'LISTA_TEMPLATE_PR',               descr: 'Funzione di gestione dei template di Progetto Radio',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE },
    prova_dettaglio_regole_calcolo:  { value: 354, nome: 'DETTAGLIO_REGOLE_CALCOLO',        descr: 'Funzione di gestione dei template di Progetto Radio',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE },
    aggiorna_adrn_omc_logico:        { value: 355, nome: 'AGGIORNA_ADRN_OMC_LOGICO',        descr: 'Aggiorna Adrn da Segnalazioni di Omc Logico',
                                       tipo_competenza: TIPO_COMPETENZA_SISTEMA,             riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_ADRN },
    aggiorna_adrn_omc_fisico:        { value: 356, nome: 'AGGIORNA_ADRN_OMC_FISICO',        descr: 'Funzione Aggiorna Adrn da Segnalazioni di Omc Fisico',
                                       tipo_competenza: TIPO_COMPETENZA_OMCFISICO,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_ADRN },
    aggiorna_metamodello_fisico:     { value: 357, nome: 'AGGIORNA_METAMODELLO_FISICO',     descr: 'Funzione di aggiornamento metamodello fisico da metamodello logico per vendor_release_fisico',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE,       riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_ADRN },
    # incongruenze metamodello temporaneamente impostato con competenza a OMCFISICO, diventera TIPO_COMPETENZA_VENDORRELEASEFISICO
    export_incongruenze_metamodello: { value: 358, nome: 'EXPORT_INCONGRUENZE_METAMODELLO', descr: 'Funzione di export delle incongruenze di metamodello fisico rispetto agli archivi di rete di omc fisico',
                                       tipo_competenza: TIPO_COMPETENZA_OMCFISICO,          riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_ADRN },
    flag_update_on_create:           { value: 359, nome: 'FLAG_UPDATE_ON_CREATE',           descr: 'Funzione di visualizzazione/gestione dei metaparametri update_on_create',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE },
    metaparametri_secondari:         { value: 360, nome: 'METAPARAMETRI_SECONDARI',         descr: 'Funzione di visualizzazione/gestione dei metaparametri secondari',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE },
    aggiorna_adrn_da_file:           { value: 361, nome: 'AGGIORNA_ADRN_DA_FILE',           descr: 'Aggiorna Adrn da File',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE,      riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_ADRN },
    export_adrn_su_file:             { value: 362, nome: 'EXPORT_ADRN_SU_FILE',             descr: 'Export Adrn su File',
                                       tipo_competenza: TIPO_COMPETENZA_VENDORRELEASE,      riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_ADRN },

    # ENODEB: 400 - 449
    nuovo_enodebid:                 { value: 401, nome: 'NUOVO_ENODEBID',                 descr: 'Funzione di inserimento nuovo/i enodebid',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    inserimento_enodeb:             { value: 402, nome: 'INSERIMENTO_ENODEB',             descr: 'Funzione di inserimento enodeb',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    cancellazione_enodeb:           { value: 403, nome: 'CANCELLAZIONE_ENODEB',           descr: 'Funzione di cancellazione enodeb',
                                      tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },

    # ESECUZIONI COMPOSTE: 450 - 500
    report_calcolo_pi_da_prn_omc_logico: { value: 450, nome: 'REPORT_CALCOLO_PI_DA_PRN_OMC_LOGICO', descr: 'Esecuzione composta Report Calcolo PI da PRN per Omc Logico',
                                           tipo_competenza: TIPO_COMPETENZA_SISTEMA },
    consistency_check:                   { value: 451, nome: 'CONSISTENCY_CHECK', descr: 'Esecuzione composta Calcolo PI e Report Comparativo per Omc Logico',
                                           tipo_competenza: TIPO_COMPETENZA_SISTEMA },

    # BROWSING: 501 - 550
    browsing: { value: 501, nome: 'BROWSING', descr: 'Funzione di visualizzazione dei file',
                tipo_competenza: TIPO_COMPETENZA_SISTEMA },

    # CGI: 551 - 600
    nuovo_cgi:                 { value: 551, nome: 'NUOVO_CGI',                   descr: 'Funzione di inserimento nuovo/i cgi',
                                 tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    inserimento_cgi:           { value: 552, nome: 'INSERIMENTO_CGI',             descr: 'Funzione di inserimento cgi',
                                 tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    cancellazione_cgi:         { value: 553, nome: 'CANCELLAZIONE_CGI',           descr: 'Funzione di cancellazione cgi',
                                 tipo_competenza: TIPO_COMPETENZA_SISTEMA,           riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },

    # GNODEB 601 - 649
    nuovo_gnodebid:            { value: 601, nome: 'NUOVO_GNODEBID',              descr: 'Funzione di inserimento nuovo/i gnodebid',
                                 tipo_competenza: TIPO_COMPETENZA_SISTEMA,        riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    inserimento_gnodeb:        { value: 602, nome: 'INSERIMENTO_GNODEB',          descr: 'Funzione di inserimento gnodeb',
                                 tipo_competenza: TIPO_COMPETENZA_SISTEMA,        riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA },
    cancellazione_gnodeb:      { value: 603, nome: 'CANCELLAZIONE_GNODEB',        descr: 'Funzione di cancellazione gnodeb',
                                 tipo_competenza: TIPO_COMPETENZA_SISTEMA,        riferimento_segnalazioni: RIFERIMENTO_SEGNALAZIONI_SISTEMA }
  )

  {
    #  FUNZIONE_X                           => [FUNZIONE_Y],
    FUNZIONE_AGGIORNA_ADRN_DA_FILE          => [FUNZIONE_EXPORT_ADRN_SU_FILE],
    FUNZIONE_AGGIORNA_ECCEZIONI             => [FUNZIONE_VISUALIZZA_ECCEZIONI],
    FUNZIONE_CANCELLAZIONE_CGI              => [FUNZIONE_INSERIMENTO_CGI],
    FUNZIONE_CANCELLAZIONE_ENODEB           => [FUNZIONE_INSERIMENTO_ENODEB],
    FUNZIONE_CANCELLAZIONE_GNODEB           => [FUNZIONE_INSERIMENTO_GNODEB],
    FUNZIONE_ELIMINA_ECCEZIONI              => [FUNZIONE_VISUALIZZA_ECCEZIONI],
    FUNZIONE_EXPORT_ADRN                    => [FUNZIONE_EXPORT_ADRN_SU_FILE],
    FUNZIONE_GESTIONE_ACCOUNTS              => [FUNZIONE_LISTA_ACCOUNTS],
    FUNZIONE_GESTIONE_ANAGRAFICA            => [FUNZIONE_LISTA_ANAGRAFICA],
    FUNZIONE_GESTIONE_ALLARMI               => [FUNZIONE_LISTA_ALLARMI],
    FUNZIONE_GESTIONE_APP_CONFIG            => [FUNZIONE_LISTA_APP_CONFIG],
    FUNZIONE_GESTIONE_ATTIVITA_SCHEDULATE   => [FUNZIONE_LISTA_ATTIVITA_SCHEDULATE],
    FUNZIONE_GESTIONE_EVENTI                => [FUNZIONE_LISTA_EVENTI],
    FUNZIONE_GESTIONE_META_MODELLO          => [FUNZIONE_LISTA_META_MODELLO],
    FUNZIONE_GESTIONE_SEGNALAZIONI          => [FUNZIONE_LISTA_SEGNALAZIONI],
    FUNZIONE_IMPORT_ADRN                    => [FUNZIONE_EXPORT_ADRN, FUNZIONE_AGGIORNA_ADRN_DA_FILE],
    FUNZIONE_IMPORT_PROGETTO_RADIO          => [FUNZIONE_VISUALIZZA_PRN]
  }.each do |funz, dipendenze|
    Constant.info(:funzione, funz)[:dipendenze] = dipendenze
    dipendenze.each do |dip|
      c = Constant.info(:funzione, dip)
      c[:richiesta_da] ||= []
      c[:richiesta_da] << funz
    end
  end
end
