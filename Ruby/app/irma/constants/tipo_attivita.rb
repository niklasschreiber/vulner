# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20170831
#
# ATTENZIONE: non indentare automaticamente !!!!
#

# rubocop:disable Metrics/LineLength, Metrics/ModuleLength, Style/IndentHash, Style/ClosingParenthesisIndentation, Style/AlignParameters
module Irma
  ATTIVITA_ROOT_KEY                = 'root'.freeze
  DIR_ATTIVITA_TAG                 = '__DIR_ATTIVITA__'.freeze
  PREFIX_CODA_ATTIVITA_ASSEGNATE   = 'attivita_assegnate_a_'.freeze
  PREFIX_REDIS_KEY_SCHEDULER_SLAVE = 'scheduler_slave:'.freeze
  REDIS_KEY_SCHEDULER_MASTER       = 'scheduler_master'.freeze

  Constant.define(:tipo_attivita, {
    attivo:  'attivo',
    sospeso: 'sospeso'
  }, :stato)

  Constant.define(:tipo_periodicita,
    periodica:     'Periodica',
    non_periodica: 'Non periodica'
  )

  Constant.define(:attivita_schedulata, {
    attiva:     'attiva',
    sospesa:    'sospesa',
    obsoleta:   'obsoleta',
    completata: 'completata'
  }, :stato)

  Constant.define(:attivita_schedulata, {
    in_attesa:              'in_attesa',
    schedulata:             'schedulata',
    in_esecuzione:          'in_esecuzione',
    terminata:              'terminata',
    annullata:              'annullata'
  }, :stato_operativo)

  Constant.define(:attivita, STATI_ATTIVITA = {
    pendente:                     'pendente',
    assegnata:                    'assegnata',
    presa_in_carico:              'presa_in_carico',
    in_esecuzione:                'in_esecuzione',
    in_corso:                     'in_corso',
    in_corso_con_errore:          'in_corso_con_errore',
    terminata_con_successo:       'terminata_con_successo',
    terminata_con_errore:         'terminata_con_errore',
    terminata_con_segnalazione:   'terminata_con_segnalazione',
    terminata_per_timeout:        'terminata_per_timeout',
    abortita:                     'abortita',
    non_eseguibile:               'non_eseguibile',
    eliminata:                    'eliminata'
  }.freeze, :stato)

  Constant.define(:attivita_foglia,
                  STATI_ATTIVITA.select { |x| %i(pendente assegnata presa_in_carico in_esecuzione terminata_con_errore terminata_con_successo terminata_con_segnalazione abortita non_eseguibile eliminata).include?(x) }, :stato)

  Constant.define(:attivita_contenitore,
                  STATI_ATTIVITA.select { |x| %i(pendente in_corso in_corso_con_errore terminata_con_errore terminata_con_successo terminata_con_segnalazione terminata_per_timeout eliminata non_eseguibile).include?(x) }, :stato)

  PESO_BASE_ATTIVITA = [
    PESO_BASE_IMPORT_OMC_LOGICO          = 1,
    PESO_BASE_EXPORT_FU                  = 1,
    PESO_BASE_EXPORT_FU_MULTI            = 1,
    PESO_BASE_RIMOZIONE_SESSIONI_SCADUTE = 1,
    PESO_BASE_VERIFICA_STATO_SERVER      = 1,
    PESO_BASE_RIMOZIONE_FILE_OBSOLETI    = 1
  ].freeze

  DEFAULT_RETENTION_CRONOLOGIA_SO = 7
  DEFAULT_RETENTION = 7
  tipo_attivita = {}
  # import_costruttore => { value: 1, kind:, nome:, descr:, stato:}
  class <<tipo_attivita
    def add(id, key, opts = {}) # rubocop:disable Metrics/AbcSize
      info = opts.merge(value: id)
      info[:kind]                    = "Irma::Db::TipoAttivita#{key.camelize}"
      info[:nome]                    = opts[:nome] || key.upcase.tr('_', ' ')
      info[:descr]                   = opts[:descr] || info[:nome]
      info[:stato]                   = opts[:stato] || TIPO_ATTIVITA_STATO_ATTIVO
      info[:create_dir_attivita]     = opts.fetch(:create_dir_attivita, true)
      info[:retention_cronologia_so] = opts[:retention_cronologia_so] || DEFAULT_RETENTION_CRONOLOGIA_SO
      info[:retention]               = opts[:retention] || DEFAULT_RETENTION
      self[key] = info
    end
  end
  tipo_attivita.add   1, 'import_costruttore_omc_logico',             descr:     'Esegue l\'import costruttore per uno o piu\' OMC logici'
  tipo_attivita.add   2, 'import_costruttore_omc_fisico',             descr:     'Esegue l\'import costruttore per uno o piu\' OMC fisici'
  tipo_attivita.add   3, 'export_formato_utente_omc_logico',          descr:     'Esegue l\'export formato utente per uno o piu\' OMC logici'
  tipo_attivita.add   4, 'export_formato_utente_omc_fisico',          descr:     'Esegue l\'export formato utente per uno o piu\' OMC fisici'
  tipo_attivita.add   5, 'import_formato_utente_omc_logico',          descr:     'Esegue l\'import formato utente per un OMC logico'
  tipo_attivita.add   6, 'export_formato_utente_multi_omc_logico',    descr:     'Esegue l\'export formato utente per uno o piu\' OMC logici, accorpando i dati in un unico set di file' # 20180226 OBSOLETA
  tipo_attivita.add   7, 'export_formato_utente_multi_omc_fisico',    descr:     'Esegue l\'export formato utente per uno o piu\' OMC fisici, accorpando i dati in un unico set di file' # 20180226 OBSOLETA
  tipo_attivita.add   8, 'import_costr_export_fu_omc_logico',         descr:     'Esegue l\'import costruttore seguito dall\'export formato utente per uno o piu\' OMC logici'
  tipo_attivita.add   9, 'import_costr_export_fu_multi_omc_logico',   descr:     'Esegue l\'import costruttore seguito dall\'export formato utente per uno o piu\' OMC logici, accorpando i dati di export' # 20180226 OBSOLETA
  tipo_attivita.add  10, 'import_costr_export_fu_omc_fisico',         descr:     'Esegue l\'import costruttore seguito dall\'export formato utente per uno o piu\' OMC fisici'
  tipo_attivita.add  11, 'import_costruttore_totale_omc_logico',      descr:     'Esegue l\'import costruttore per tutti gli OMC logici',
                                                                      retention:  3 # , singleton: true, periodo: '0 30 7 * * *'
  tipo_attivita.add  12, 'import_costruttore_totale_omc_fisico',      descr:     'Esegue l\'import costruttore per tutti gli OMC fisici',
                                                                      retention:  6,
                                                                      singleton:  true,
                                                                      periodo:    '0 01 5 * * *',
                                                                      check_data: false,
                                                                      archivio:   ARCHIVIO_RETE,
                                                                      competenze: { TIPO_COMPETENZA_OMCFISICO => COMPETENZA_TUTTO }
  tipo_attivita.add  13, 'calcolo_pi_omc_logico',                     descr:     'Esegue il calcolo del progetto irma per gli OMC logici'
  tipo_attivita.add  14, 'calcolo_pi_omc_fisico',                     descr:     'Esegue il calcolo del progetto irma per gli OMC fisici'
  tipo_attivita.add  15, 'pi_import_formato_utente_omc_logico',       descr:     'Esegue l\'import formato utente su un Progetto Irma di OMC logico'
  tipo_attivita.add  16, 'pi_import_formato_utente_omc_fisico',       descr:     'Esegue l\'import formato utente su un Progetto Irma di OMC fisico'
  tipo_attivita.add  17, 'export_formato_utente_parziale_omc_logico', descr:     'Esegue l\'export formato utente per uno o piu\' OMC logici con filtro su meta_modello'
  tipo_attivita.add  18, 'export_formato_utente_parziale_omc_fisico', descr:     'Esegue l\'export formato utente per uno o piu\' OMC fisici con filtro su meta_modello'
  tipo_attivita.add  19, 'pi_export_formato_utente',                  descr:     'Esegue l\'export formato utente per uno o piu\' Progetti Irma'
  tipo_attivita.add  20, 'pi_export_formato_utente_parziale',         descr:     'Esegue l\'export formato utente per uno o piu\' Progetti Irma con filtro su meta_modello'
  tipo_attivita.add  21, 'import_progetto_radio',                     descr:     'Esegue l\'import dei dati di Progetto Radio'
  tipo_attivita.add  22, 'report_comparativo_omc_logico',             descr:     'Esegue il Report Comparativo tra due Archivi di entita per OMC Logico'
  tipo_attivita.add  23, 'report_comparativo_omc_fisico',             descr:     'Esegue il Report Comparativo tra due Archivi di entita per OMC Fisico'
  tipo_attivita.add  24, 'calcolo_pi_import_fu_omc_logico',           descr:     'Esegue il calcolo del progetto irma per OMC logico seguito da un import formato utente'
  tipo_attivita.add  25, 'export_report_comparativo_totale',          descr:     'Esegue l\'export per uno o piu\' Report Comparativi'
  tipo_attivita.add  26, 'export_report_comparativo_fu',              descr:     'Esegue l\'export formato utente per uno o piu\' Report Comparativi'
  tipo_attivita.add  27, 'import_adrn',                               descr:     'Esegue l\'import del Meta Modello per Vendor Release'
  tipo_attivita.add  28, 'export_adrn',                               descr:     'Esegue l\'export del Meta Modello per Vendor Release'
  tipo_attivita.add  29, 'completa_enodeb',                           descr:     'Esegue il completamento dell\' ENODEBID tramite file di Progetto Radio'
  tipo_attivita.add  30, 'completa_enodeb_import_progetto_radio',     descr:     'Esegue il completamento dell\'ENODEBID seguito dall\' import dei dati di Progetto Radio'
  tipo_attivita.add  31, 'nuovo_enodebid',                            descr:     'Esegue l\'inserimento di uno o più eNodeB id'
  tipo_attivita.add  32, 'creazione_fdc_omc_logico',                  descr:     'Esegue la creazione dei file di configurazione per OMC logico'
  tipo_attivita.add  33, 'report_calcolo_pi_da_prn_omc_logico',       descr:     'Esegue l\'import costruttore, il calcolo PI, l\'import FU sul PI, il Report Comparativo ed il suo export per OMC logico'
  tipo_attivita.add  34, 'export_report_comparativo_multiplo',        descr:     'Esegue l\'export totale ed in formato utente per uno o piu\' Report Comparativi'
  tipo_attivita.add  35, 'creazione_fdc_omc_fisico',                  descr:     'Esegue la creazione dei file di configurazione per OMC fisico'
  tipo_attivita.add  36, 'calcolo_pi_copia',                          descr:     'Esegue il calcolo del progetto irma effettuando una copia del progetto irma sorgente'
  tipo_attivita.add  37, 'export_prn_omc_logico',                     descr:     'Esegue l\'export del Progetto Radio per uno o piu\' OMC logici'
  tipo_attivita.add  38, 'consistency_check',                         descr:     'Esegue il calcolo del Progetto Irma e conseguentemente il Report Comparativo',
                                                                      retention: 3
  tipo_attivita.add  39, 'consistency_check_totale',                  descr:     'Esegue il calcolo del Progetto Irma e conseguentemente il Report Comparativo per una lista di OMC logici',
                                                                      retention:  6,
                                                                      singleton:  true,
                                                                      competenze: { TIPO_COMPETENZA_SISTEMA => COMPETENZA_TUTTO },
                                                                      archivio:   ARCHIVIO_RETE,
                                                                      periodo:    '0 0 7 * * 6'
  tipo_attivita.add  40, 'import_formato_utente_omc_fisico',          descr:      'Esegue l\'import formato utente per un OMC fisico'
  tipo_attivita.add  41, 'elimina_celle_da_prn_omc_logico',           descr:      'Esegue l\'eliminazione di una lista di celle da PRN per un OMC logico'
  tipo_attivita.add  42, 'ricerca_incongruenze_metamodello_fisico',   descr:      'Esegue la ricerca delle incongruenze per il memodello fisico data una Vendor Release'
  tipo_attivita.add  43, 'completa_cgi',                              descr:      'Esegue il completamento del CGI tramite file di Progetto Radio'
  tipo_attivita.add  44, 'completa_cgi_import_progetto_radio',        descr:      'Esegue il completamento del CGI seguito dall\' import dei dati di Progetto Radio'
  tipo_attivita.add  45, 'nuovo_cgi',                                 descr:      'Esegue l\'inserimento di uno o più CGI'
  tipo_attivita.add  46, 'export_report_comparativi',                 descr:      'Esegue l\'export totale, formato utente, conteggio alberature e combinazioni delle tre attivita, per uno o piu\' Report Comparativi'
  tipo_attivita.add  47, 'cancellazione_eccezioni_per_etichetta',     descr:      'Esegue la cancellazione delle eccezioni su base etichetta'
  tipo_attivita.add  48, 'import_costruttore_e_consistency_check_totale', descr:    'Esegue import costruttore totale per omc fisico e, a seguire, consistency check totale',
                                                                          singleton:  true,
                                                                          archivio:   ARCHIVIO_RETE,
                                                                          periodo:    '0 0 5 * * *',
                                                                          competenze: { TIPO_COMPETENZA_OMCFISICO => COMPETENZA_TUTTO }
  tipo_attivita.add  49, 'nuovo_gnodebid',                            descr:     'Esegue l\'inserimento di uno o più gNodeB id'
  tipo_attivita.add  50, 'aggiorna_adrn_da_file',                     descr:     'Esegue l\'aggiornamento del Meta Modello per Vendor Releasei da file adrn'
  tipo_attivita.add  51, 'export_adrn_su_file',                       descr:     'Esegue l\'export del Meta Modello per Vendor Release su file adrn'

  tipo_attivita.add 101, 'rimozione_sessioni_scadute', descr:                  'Rimuove sessioni scadute',
                                                       singleton:               true,
                                                       retention_cronologia_so: 1.0 / 24,
                                                       create_dir_attivita:     false,
                                                       retention:               1,
                                                       stato_as:                ATTIVITA_SCHEDULATA_STATO_ATTIVA,
                                                       periodo:                 '10 */5 * * * *' # ogni cinque minuti al secondo 10
  tipo_attivita.add 102, 'cleanup_db',                 descr:                   'Eliminazione record DB fuori retention',
                                                       singleton:               true,
                                                       retention:               30,
                                                       create_dir_attivita:     false,
                                                       stato_as:                ATTIVITA_SCHEDULATA_STATO_ATTIVA,
                                                       periodo:                 '30 5 1 * * *' # tutti i giorni alle 01:05:30
  tipo_attivita.add 103, 'verifica_accounts',          descr:                   'Controlla gli accounts del sistema (allineamento LDAP, scadenza, ...)',
                                                       singleton:               true,
                                                       retention:               30,
                                                       create_dir_attivita:     false,
                                                       periodo:                 '30 35 1 * * *' # tutti i giorni alle 01:35:30
  tipo_attivita.add 104, 'export_db',                  descr:                   'Export delle principali tabelle del DB',
                                                       singleton:               true,
                                                       retention:               30,
                                                       create_dir_attivita:     false,
                                                       periodo:                 '30 05 4 * * *' # tutti i giorni alle 04:05:30
  # tipo_attivita.add 105, 'verifica_stato_server', descr: 'Aggiorna stato dei server nel DB', singleton: true
  Constant.define(:tipo_attivita, tipo_attivita)
end
