# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20170831
#
# ATTENZIONE: non indentare automaticamente !!!!
#

# rubocop:disable Metrics/LineLength, Metrics/ModuleLength, Style/IndentHash
module Irma
  Constant.define(:meta_parametro, TIPI_META_PARAM = {
                  semplice:                       { value: 1, multivalore: false, multistrutturato: false, strutturato: false },
                  multivalore:                    { value: 2, multivalore: true,  multistrutturato: false, strutturato: false },
                  strutturato_semplice:           { value: 3, multivalore: false, multistrutturato: false, strutturato: true },
                  strutturato_multivalore:        { value: 4, multivalore: true,  multistrutturato: false, strutturato: true },
                  multi_strutturato_semplice:     { value: 5, multivalore: false, multistrutturato: true,  strutturato: true },
                  multi_strutturato_multivalore:  { value: 6, multivalore: true,  multistrutturato: true,  strutturato: true }
  }.freeze, :genere)

  f2g = {}
  g2f = {}
  Constant.constants(:meta_parametro, :genere).each do |ccc|
    terna = [ccc.info[:multivalore], ccc.info[:multistrutturato], ccc.info[:strutturato]]
    val = ccc.value
    f2g[terna] = val
    g2f[val] = terna
  end
  META_PARAMETRO_FLAGS_TO_GENERE = f2g.freeze
  META_PARAMETRO_GENERE_TO_FLAGS = g2f.freeze

  def self.meta_parametro_flags_to_genere(multi_valore:, multi_struct:, is_struct:)
    FLAGS_TO_GENERE[[multi_valore, multi_struct, is_struct]]
  end

  Constant.define(:tipo_meta_parametro, TIPI_META_PARAM)

  Constant.define(:tipo_segnalazione, GRAVITA_SEGNALAZIONE = {
    info:      { value: 1, descr: 'Informazione' },
    warning:   { value: 2, descr: 'Warning' },
    error:     { value: 3, descr: 'Errore' }
  }.freeze, :gravita)

  Constant.define(:tipo_segnalazione, {
    esecuzione_funzione: 'esecuzione_funzione',
    metamodello: 'metamodello',
    dati: 'dati',
    calcolo: 'calcolo'
  }, :categoria)

  Constant.define(:segnalazione, GRAVITA_SEGNALAZIONE, :gravita)

  ts = {}
  class <<ts
    def _add(id, funzione_id, categoria, nome, opts = {}) # rubocop:disable Metrics/AbcSize
      funzioni = [funzione_id].flatten
      f = funzioni.shift
      info = { value: id, funzione_id: f, categoria: categoria, nome: nome, gravita: TIPO_SEGNALAZIONE_GRAVITA_INFO, to_update_adrn: false }.merge(opts)
      idm = f ? "#{Constant.info(:funzione, f)[:nome]}_" : ''
      idm += "#{info[:categoria]}_#{info[:nome]}"
      info[:identificativo_messaggio] = idm.tr(' ', '_').upcase
      self[info[:identificativo_messaggio].downcase.to_sym] = info
      funzioni.each_with_index do |altra_f, idx|
        duplica(id, id + idx + 1, altra_f)
      end
      info
    end

    def info(id, funzione_id, categoria, nome, opts = {})
      _add(id, funzione_id, categoria, nome, opts.merge(gravita: TIPO_SEGNALAZIONE_GRAVITA_INFO))
    end

    def warning(id, funzione_id, categoria, nome, opts = {})
      _add(id, funzione_id, categoria, nome, opts.merge(gravita: TIPO_SEGNALAZIONE_GRAVITA_WARNING))
    end

    def error(id, funzione_id, categoria, nome, opts = {})
      _add(id, funzione_id, categoria, nome, opts.merge(gravita: TIPO_SEGNALAZIONE_GRAVITA_ERROR))
    end

    def duplica(id_orig, id_dest, funzione_id_dest, opts = {})
      _k, info_orig = find { |_k, v| v[:value] == id_orig }
      info_dup = info_orig.dup
      info_dup.delete(:funzione_id)
      info_dup.delete(:value)
      _add(id_dest, funzione_id_dest, info_orig[:categoria], info_orig[:nome], info_dup.merge(opts))
    end
  end

  ts.info       1, nil, TIPO_SEGNALAZIONE_CATEGORIA_ESECUZIONE_FUNZIONE, 'iniziata',              descr: 'Inizio esecuzione funzionalità'
  ts.info       2, nil, TIPO_SEGNALAZIONE_CATEGORIA_ESECUZIONE_FUNZIONE, 'completata',            descr: 'Fine esecuzione funzionalità con successo'
  ts.error      3, nil, TIPO_SEGNALAZIONE_CATEGORIA_ESECUZIONE_FUNZIONE, 'terminata_con_errore',  descr: 'Fine esecuzione funzionalità con errore'
  ts.info       4, nil, TIPO_SEGNALAZIONE_CATEGORIA_ESECUZIONE_FUNZIONE, 'in_corso',              descr: 'Esecuzione funzionalità in corso'
  ts.error      5, nil, TIPO_SEGNALAZIONE_CATEGORIA_ESECUZIONE_FUNZIONE, 'terminata_per_timeout', descr: 'Fine esecuzione funzionalità per timeout'

  # 1000
  f = [FUNZIONE_IMPORT_OMC_LOGICO, FUNZIONE_IMPORT_OMC_FISICO]
  ts.warning 1000, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'meta_entita_mancante',                                  descr: 'Meta Entità mancante nel metamodello', to_update_adrn: true
  ts.warning 1002, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'meta_parametro_semplice_mancante',                      descr: 'Meta Parametro mancante nel metamodello',
                                                                                                                           to_update_adrn: true, genere_per_update: META_PARAMETRO_GENERE_SEMPLICE
  ts.warning 1004, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'meta_parametro_multivalore_mancante',                   descr: 'Meta Parametro multivalore mancante nel metamodello',
                                                                                                                           to_update_adrn: true, genere_per_update: META_PARAMETRO_GENERE_MULTIVALORE
  ts.warning 1006, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'meta_parametro_strutturato_semplice_mancante',          descr: 'Meta Parametro strutturato mancante nel metamodello',
                                                                                                                           to_update_adrn: true, genere_per_update: META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE
  ts.warning 1008, f, *(ienv = [TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'identificativo_entita_non_valido',                      descr: 'Entità con identificativo non valido'])
  ts.warning 1010, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'padre_non_trovato',                                     descr: 'Padre non trovato'
  ts.warning 1012, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'nodo_su_altro_sistema',                                 descr: 'Nodo associato ad un OMC Logico differente'
  ts.warning 1014, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'entita_scartata_per_mancanza_di_nodo',                  descr: 'Entita figlia di nodo non presente'
  ts.warning 1016, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'entita_duplicata',                                      descr: 'Entita duplicata'
  ts.warning 1018, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'meta_parametro_strutturato_multivalore_mancante',       descr: 'Meta Parametro strutturato multivalore mancante nel metamodello',
                                                                                                                           to_update_adrn: true, genere_per_update: META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE
  ts.warning 1020, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'meta_parametro_multi_strutturato_semplice_mancante',    descr: 'Meta Parametro strutturato multivalore mancante nel metamodello',
                                                                                                                           to_update_adrn: true, genere_per_update: META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE
  ts.warning 1022, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'meta_parametro_multi_strutturato_multivalore_mancante', descr: 'Meta Parametro strutturato multivalore mancante nel metamodello',
                                                                                                                           to_update_adrn: true, genere_per_update: META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE
  ts.error   1024, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'cmdata_errato',                                         descr: 'Attributo type del tag cmData non vale actual'
  ts.warning 1026, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'parametro_inconsistente',                               descr: 'Parametro inconsistente rispetto al metamodello'
  ts.error   1028, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO,    'meta_entita_obbl_mancante',                             descr: 'Meta Entita obbligatoria assente nel file'
  ts.warning 1030, f, *(nc = [TIPO_SEGNALAZIONE_CATEGORIA_DATI,   'numero_campi',                                          descr: 'Numero campi differente tra intestazione e dati'])
  ts.warning 1032, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'padre_null',                                            descr: 'entità con padre null'
  ts.warning 1034, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'competenza_sistema',                                    descr: 'SubNetwork non di competenza'
  ts.error   1036, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'errore_validazione_xsd',                                descr: 'Errore di validazione con xsd'
  ts.info    1038, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'validazione_xsd',                                       descr: 'validazione con xsd ok'
  ts.warning 1040, f, *(va = [TIPO_SEGNALAZIONE_CATEGORIA_DATI,   'version_assente',                                       descr: 'version non presente tra le release di nodo del vendor'])
  ts.error   1042, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,           'datetime_errato',                                       descr: 'Attributo dataTime del tag log non corrispondente alla data attuale'

  # 1100-1109
  f = [FUNZIONE_EXPORT_FORMATO_UTENTE, FUNZIONE_EXPORT_FORMATO_UTENTE_PARZIALE]
  ts.warning 1100, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,        'non_presenti',              descr: 'Non sono presenti dati per il sistema di cui si richiede l\'export'

  # 1110-1119
  f = [FUNZIONE_EXPORT_FU_OMC_FISICO, FUNZIONE_EXPORT_FU_OMC_FISICO_PARZIALE]
  ts.warning 1110, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,        'non_presenti',              descr: 'Non sono presenti dati per l\'omc_fisico di cui si richiede l\'export'

  # 1150
  ts.error   1150, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'campi_obbligatori_head', descr: 'Mancano campi obbligatori nell\'intestazione'
  ts.error   1151, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'numero_campi', descr: 'Il numero di campi sulla linea non corrisponde a quelli nell\'intestazione'
  ts.error   1152, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'competenza_omc', descr: 'L\'OMC Logico o Fisico impostato sulla colonna SISTEMA o OMC_FISICO non e\' corretto'
  ts.warning 1153, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'release_nodo_mancante', descr: 'Release Nodo non avvalorata nel campo di Progetto Radio'
  ts.error   1154, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'release_nodo_errata', descr: 'Release Nodo non corrispondente a quelle ammesse per la VendorRelease'
  ts.warning 1155, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'campi_adiacenza_head', descr: 'Mancano campi di adiacenza nell\'intestazione'
  ts.warning 1156, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'cella_servente', descr: 'Cella servente presente tra le sue adiacenti'
  ts.info    1157, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'celle_cancellate', descr: 'Sono state cancellate celle non riprogettate'
  ts.warning 1158, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'adiacenze_ripetute', descr: 'Adiacenze ripetute nella lista delle adiacenti'
  ts.warning 1159, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'adiacenze_consecutive', descr: 'Adiacenti non consecutive nella lista delle adiacenti'
  ts.warning 1160, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'adiacenze_mancanti', descr: 'Adiacenti non presenti nel PRN'
  ts.warning 1161, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'reciprocita_adiacenze', descr: 'Adiacenti senza reciprocita'
  ts.warning 1162, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'pci_mancante', descr: 'Valori di PCI o EARFCNUL assenti'
  ts.warning 1163, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'pci_1', descr: 'Cella e adiacente con PCI e LAYER uguali'
  ts.warning 1164, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'pci_2', descr: 'Adiacenti con PCI e LAYER uguali'
  ts.warning 1165, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_mancante', descr: 'eNodeb non anagrafato'
  ts.warning 1166, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_differente', descr: 'eNodebID differente da quello anagrafato'
  ts.warning 1167, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nome_cella_non_conforme', descr: 'cella con nome non conforme'
  ts.warning 1168, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nome_adiacente_non_conforme', descr: 'cella adiacente con nome non conforme'
  ts.error   1169, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'cella_non_anagrafata_cgi', descr: 'cella non presente in anagrafica cgi'
  ts.error   1170, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'cgi_non_corrispondente', descr: 'cgi (ci) cella non corriponde al valore presente in anagrafica cgi'
  ts.warning 1171, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'cgi_lac_non_corrispondente', descr: 'cgi lac della cella non corriponde al valore presente in anagrafica cgi'
  ts.info    1172, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'celle_cancellate_nessuna', descr: 'Non sono presenti celle non riprogettate'
  ts.error   1173, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'campi_obbligatori_non_valorizzati', descr: 'Campi obbligatori non valorizzati'
  ts.info    1174, FUNZIONE_ELIMINA_CELLE_DA_PRN,  TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'info', descr: 'Sono state eliminate dal PRN le celle in input'
  ts.warning 1175, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'lac_aggiornato', descr: 'lac della cella aggiornato in anagrafica cgu col valore presente nel file'
  ts.warning 1176, FUNZIONE_IMPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'lac_errato', descr: 'Valore lac non corretto'
  ts.warning 1177, FUNZIONE_EXPORT_PROGETTO_RADIO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'sistema_non_corretto', descr: 'Errore nell\'export prn di un sistema'

  # 1200-1239
  f = [FUNZIONE_IMPORT_FORMATO_UTENTE, FUNZIONE_PI_IMPORT_FORMATO_UTENTE]
  ts.error   1200, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,        'posizione_header',          descr: 'Oggetto posizionato non correttamente nell\'header'
  ts.warning 1202, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO, 'oggetto_inesistente',       descr: 'Oggetto non presente nel metamodello'
  ts.warning 1204, f, *ienv
  ts.warning 1206, f, *nc
  ts.warning 1208, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,        'nodo_su_altro_sistema',     descr: 'Nodo attestato su altro sistema'
  ts.warning 1210, f, *va

  # 1240-1279 (nel caso servisse pi_import_fu_omc_fisico)
  f = [FUNZIONE_IMPORT_FU_OMC_FISICO]
  ts.error   1240, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,        'posizione_header',          descr: 'Oggetto posizionato non correttamente nell\'header'
  ts.warning 1242, f, TIPO_SEGNALAZIONE_CATEGORIA_METAMODELLO, 'oggetto_inesistente',       descr: 'Oggetto non presente nel metamodello'
  ts.warning 1244, f, *ienv
  ts.warning 1246, f, *nc
  ts.error   1248, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,        'nodo_su_altro_sistema',     descr: 'Nodo attestato su altro sistema'
  ts.warning 1250, f, *va

  # 1300 calcolo
  f = [FUNZIONE_PI_CALCOLO]
  ts.error   1300, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'errore_calcolo_entita',    descr: 'Entita non calcolata correttamente'
  ts.warning 1302, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'entita_tipo_errato',       descr: 'Valore entita calcolata e\' di tipo non conforme'
  ts.error   1304, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'entita_valore_vuoto',      descr: 'Valore entita calcolata e\' vuoto'
  ts.error   1306, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'errore_calcolo_parametro', descr: 'Parametro non calcolato correttamente'
  ts.error   1308, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'regole_calcolo_assenti',   descr: 'Non e\' definita nessuna regola di calcolo'
  ts.error   1310, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'cella_inesistente',        descr: 'Richiesto calcolo per cella non presente in PR'
  ts.error   1312, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'entita_multi_errore_totale', descr: 'Calcolo di entita\' multistanziata fallito per ogni istanza'
  ts.warning 1314, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'errore_calcolo_param',     descr: 'Parametro non calcolato correttamente'
  ts.warning 1316, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'param_tipo_errato',        descr: 'Valore parametro calcolato e\' di tipo non conforme'
  ts.warning 1318, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'adiacente_inesistente',    descr: 'Cella adiacente non presente nel PRN'
  ts.warning 1320, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'errore_param_strutturato', descr: 'Errore in calcolo parametro strutturato'
  ts.warning 1322, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'errore_calcolo_entita_non_bloccante',    descr: 'Entita non calcolata correttamente'
  ts.warning 1324, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'entita_multi_errore_totale_non_bloccante', descr: 'Calcolo di entita\' multistanziata fallito per ogni istanza'
  ts.warning 1326, f, TIPO_SEGNALAZIONE_CATEGORIA_CALCOLO,        'nessuna_cella', descr: 'Nessuna Cella calcolabile'

  # 1350
  f = [FUNZIONE_REPORT_COMPARATIVO_OMC_FISICO, FUNZIONE_REPORT_COMPARATIVO]
  ts.warning 1350, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI,        'non_presenti',              descr: 'Non sono presenti dati per l\'archivio di cui si richiede l\'export'

  # 1400 adrn
  ts.error   1400, FUNZIONE_EXPORT_ADRN, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'export_vr_fallito', descr: 'Fallito export adrn per VendorRelease'
  ts.error   1401, FUNZIONE_IMPORT_ADRN, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'import_vr_fallito', descr: 'Fallito import adrn per VendorRelease'
  ts.error   1402, FUNZIONE_EXPORT_INCONGRUENZE_METAMODELLO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'fallito', descr: 'Fallito export incongruenze metamodello'
  ts.error   1403, FUNZIONE_EXPORT_INCONGRUENZE_METAMODELLO, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'archivi_vuoti', descr: 'Archivi vuoti'
  ts.warning 1404, FUNZIONE_AGGIORNA_ADRN_DA_FILE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'errore_aggiornamento_db', descr: 'Errore in aggiornamento database'
  ts.warning 1405, FUNZIONE_AGGIORNA_ADRN_DA_FILE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nessun_aggiornamento', descr: 'Nessun aggiornamento da effettuare'
  ts.warning 1406, FUNZIONE_AGGIORNA_ADRN_DA_FILE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'linea_file_non_corretta', descr: 'Linea file non corretta'
  ts.warning 1407, FUNZIONE_AGGIORNA_ADRN_DA_FILE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'header_file_non_corretto', descr: 'Header file non corretto'
  ts.warning 1408, FUNZIONE_AGGIORNA_ADRN_DA_FILE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'valore_errato', descr: 'Valore non compatibile'
  ts.warning 1409, FUNZIONE_AGGIORNA_ADRN_DA_FILE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'regola_calcolo_non_corretta', descr: 'Regola di calcolo non corretta'

  # 1450 enodebid
  ts.warning 1450, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'competenza_omc', descr: 'L\'OMC Logico o Fisico impostato sulla colonna SISTEMA o OMC_FISICO non e\' corretto'
  ts.warning 1451, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodebname_errato', descr: 'Campo ENODEB_NAME non avvalorato correttamente'
  ts.warning 1452, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'competenza_province', descr: 'La provincia dedotta dall\'ENODEBN_NAME  non e\' tra quelle di competenza del sistema'
  ts.error   1453, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'no_new_id', descr: 'Impossibile ottenere un nuovo identificativo'
  ts.warning 1454, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'modifica_file', descr: 'Aggiornato ENODEB_ID nel file'
  ts.info    1455, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nuovo_enodebid', descr: 'Inserito in anagrafica enodeb un nuovo nodo'
  ts.warning 1456, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodebname_no_provincia', descr: 'Al campo ENODEB_NAME non corriponde nessuna provincia'
  ts.warning 1457, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'campi_obbligatori_head', descr: 'I record del file non contiene tutti i campi necessari all\'elaborazione'
  ts.warning 1458, FUNZIONE_COMPLETA_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodebname_no_at', descr: 'Al campo ENODEB_NAME non corriponde nessuna area territoriale'
  ts.warning 1460, FUNZIONE_NUOVO_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_gia_anagrafato', descr: 'Nodo gia\' anagrafato'
  ts.warning 1461, FUNZIONE_NUOVO_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_errato', descr: 'Nome nodo non corretto'
  ts.warning 1462, FUNZIONE_NUOVO_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_no_provincia', descr: 'Nome nodo a cui non corrisponde nessuna provincia'
  ts.warning 1463, FUNZIONE_NUOVO_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_no_at', descr: 'Nome nodo a cui non corriponde nessuna area territoriale'
  ts.warning 1464, FUNZIONE_NUOVO_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_id_no_at',          descr: 'Id nodo non corretto per l\'area territoriale. Assegnazione id automatica'
  ts.warning 1465, FUNZIONE_NUOVO_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_id_gia_anagrafato', descr: 'Id nodo gia\' anagrafato. Assegnazione id automatica'
  ts.warning 1466, FUNZIONE_NUOVO_ENODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'enodeb_no_id_liberi', descr: 'Nessun identificativo libero per l\'area territoriale'

  # 1500 fdc
  f = [FUNZIONE_CREAZIONE_FDC_OMC_LOGICO, FUNZIONE_CREAZIONE_FDC_OMC_FISICO]
  ts.warning 1500, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nodelete_op_non_ammessa', descr: 'Operazione DELETE non ammessa'
  ts.warning 1502, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'noupdate_op_non_ammessa', descr: 'Operazione UPDATE non ammessa'
  ts.warning 1504, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nocreate_op_non_ammessa', descr: 'Operazione CREATE non ammessa'
  ts.warning 1506, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nodelete_in_createupdate', descr: 'Entita\' non cancellabile perche\' da creare o aggiornare'
  ts.warning 1508, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nocreate_param_obblig', descr: 'Entita\' in create con parametro obbligatorio non avvalorato'
  ts.warning 1510, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'update_param_restricted', descr: 'Richiesto update di parametro is_restricted'
  ts.warning 1512, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nodelete_in_master', descr: 'Entita\' non cancellabile perche\' presente in fonte master'
  ts.warning 1514, f, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'strutturato_non_completo', descr: 'Entita\' con parametro strutturato non completo'

  # 1550 CGI
  ts.warning 1550, FUNZIONE_NUOVO_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'cella_gia_anagrafata', descr: 'Cella gia\' anagrafato'
  ts.warning 1551, FUNZIONE_NUOVO_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nome_cella_errato', descr: 'Nome cella non corretto'
  ts.warning 1552, FUNZIONE_NUOVO_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nome_cella_no_regione', descr: 'Nome cella a cui non corrisponde nessuna regione'
  ts.warning 1553, FUNZIONE_NUOVO_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'lac_errato', descr: 'Valore lac non corretto'
  ts.warning 1554, FUNZIONE_NUOVO_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'linea_input_errata', descr: 'Linea input inserimento cgi non corretta'
  ts.warning 1555, FUNZIONE_NUOVO_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'errore_inserimento', descr: 'Inserimento anagrafica cgi fallito'
  ts.warning 1556, FUNZIONE_COMPLETA_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'competenza_omc', descr: 'L\'OMC Logico o Fisico impostato sulla colonna SISTEMA o OMC_FISICO non e\' corretto'
  ts.warning 1557, FUNZIONE_COMPLETA_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nome_cella_errato', descr: 'Campo CELLA non avvalorato correttamente'
  ts.error   1558, FUNZIONE_COMPLETA_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'no_new_ci', descr: 'Impossibile ottenere un nuovo ci'
  ts.warning 1559, FUNZIONE_COMPLETA_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'modifica_file', descr: 'Aggiornato CGI nel file'
  ts.warning 1560, FUNZIONE_COMPLETA_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'modifica_cgi', descr: 'Aggiornato CGI in anagrafica'
  ts.info    1561, FUNZIONE_COMPLETA_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'nuova_cella', descr: 'Inserito in anagrafica cgi una nuova cella'
  ts.warning 1562, FUNZIONE_COMPLETA_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'campi_obbligatori_head', descr: 'I record del file non contiene tutti i campi necessari all\'elaborazione'
  ts.warning 1563, FUNZIONE_COMPLETA_CGI, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'lac_errato', descr: 'Valore lac non corretto'
  # 1600 CONTEGGIO_ALBERATURE e CONTEGGIO_ALBERATURE_ADE
  ts.warning 1600, FUNZIONE_CONTEGGIO_ALBERATURE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'rc_inesistenti', descr: 'Report Comparativi inesistenti tra quelli indicati per il conteggio'
  ts.warning 1601, FUNZIONE_CONTEGGIO_ALBERATURE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'rc_no_omc_logico', descr: 'Report Comparativi non associabili ad un omc_logico, tra quelli indicati per il conteggio'
  ts.error 1602, FUNZIONE_CONTEGGIO_ALBERATURE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'no_rc_ok', descr: 'Nessun Report Comparativo corretto, tra quelli indicati'
  ts.warning 1603, FUNZIONE_CONTEGGIO_ALBERATURE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'errore_conteggio_rc', descr: 'Errore nell\'effettuare il conteggio per un report comparativo'
  ts.warning 1604, FUNZIONE_CONTEGGIO_ALBERATURE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'errore_conteggio_eccez', descr: 'Errore nell\'effettuare il conteggio eccezioni per un sistema'
  ts.info 1605, FUNZIONE_CONTEGGIO_ALBERATURE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'superato_excel_limit_rows', descr: 'Superato nel file di conteggio, il limite massimo di righe per un file excel'
  ts.warning 1606, FUNZIONE_CONTEGGIO_ALBERATURE_ADE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'sistemi_inesistenti', descr: 'Sistemi inesistenti tra quelli indicati per il conteggio'
  ts.error 1607, FUNZIONE_CONTEGGIO_ALBERATURE_ADE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'no_sistemi_ok', descr: 'Nessun Sistema corretto, tra quelli indicati'
  ts.warning 1608, FUNZIONE_CONTEGGIO_ALBERATURE_ADE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'errore_conteggio_eccez', descr: 'Errore nell\'effettuare il conteggio eccezioni per un sistema'
  ts.info 1609, FUNZIONE_CONTEGGIO_ALBERATURE_ADE, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'superato_excel_limit_rows', descr: 'Superato nel file di conteggio, il limite massimo di righe per un file excel'

  # 1650 gnodebid
  ts.warning 1650, FUNZIONE_NUOVO_GNODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'gnodeb_gia_anagrafato',    descr: 'Nodo gia\' anagrafato'
  ts.warning 1651, FUNZIONE_NUOVO_GNODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'gnodeb_errato',            descr: 'Nome nodo non corretto'
  ts.warning 1652, FUNZIONE_NUOVO_GNODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'gnodeb_no_provincia',      descr: 'Nome nodo a cui non corrisponde nessuna provincia'
  ts.warning 1653, FUNZIONE_NUOVO_GNODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'gnodeb_no_at',             descr: 'Nome nodo a cui non corriponde nessuna area territoriale'
  ts.warning 1654, FUNZIONE_NUOVO_GNODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'gnodeb_id_no_at',          descr: 'Id nodo non corretto per l\'area territoriale. Assegnazione id automatica'
  ts.warning 1655, FUNZIONE_NUOVO_GNODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'gnodeb_id_gia_anagrafato', descr: 'Id nodo gia\' anagrafato. Assegnazione id automatica'
  ts.warning 1656, FUNZIONE_NUOVO_GNODEBID, TIPO_SEGNALAZIONE_CATEGORIA_DATI, 'gnodeb_no_id_liberi',      descr: 'Nessun identificativo libero per l\'area territoriale'

  Constant.define(:tipo_segnalazione, TIPI_SEGNALAZIONE = ts.freeze)

  # aggiungiamo alle funzioni tutte le segnalazioni collegate
  Constant.constants(:tipo_segnalazione).each do |c|
    next unless c.info[:funzione_id]
    f_info = Constant.info(:funzione, c.info[:funzione_id])
    f_info[:tipi_segnalazioni] ||= []
    f_info[:tipi_segnalazioni] << c.value
  end

  TIPO_SEGNALAZIONE_GENERICA = [TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_INIZIATA,
                                TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_COMPLETATA,
                                TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_TERMINATA_CON_ERRORE,
                                TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_TERMINATA_PER_TIMEOUT,
                                TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_IN_CORSO].freeze
end
