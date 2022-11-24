# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20151121
#
# Definizione di tutte le costanti
#
# ATTENZIONE: non indentare automaticamente !!!!
#

# ============================================================
TERMINATA_WARNING = :terminata_warning
PLANTUML_DEFAULT_OPTIONS = "\nskinparam defaultFontName Arial\nskinparam defaultFontSize 12\n".freeze

NOT_AVAILABLE_STR = 'N/A'.freeze

COMPETENZA_TUTTO = '*'.freeze
SHORTCUT_TUTTO   = '*'.freeze

NUM_FITTIZIO_NESSUNO = -1
MSG_TUTTI = 'Tutti'.freeze

LABEL_SISTEMI = 'Sistemi'.freeze
LABEL_OMC_FISICI = 'OMC Fisici'.freeze

# Spostare nel catalogo
MSG_COMPETENZA_NESSUN_VALORE = '-- NESSUN VALORE --'.freeze
MSG_COMPETENZA_TUTTI_I_VALORI = '-- TUTTI I VALORI --'.freeze
MSG_SENZA_ETICHETTA = '-- Senza Etichetta --'.freeze
IRMA_SESSION_ID = '_irma_session_id'.freeze
ALIVE = 'alive'.freeze

COMPLETA_ENODEB_FILE_OUT_SUFFIX = '_ENODEB_COMPLETED'.freeze
COMPLETA_CGI_FILE_OUT_SUFFIX = '_CGI_COMPLETED'.freeze

MAX_CI = 65_535
TUTTI_I_CI = Array.new(MAX_CI) { |idx| format('%05d', idx + 1) }.freeze
SEP_FILE_CGI = ','.freeze
CGI_SEP = '-'.freeze

RITARDO_LOCK_EXPIRE_PER_SCHEDULER = 60

DATE_REPORT_FORMAT = '%d/%m/%Y'.freeze

DATE_TIME_REGEXPR = '^(?=\d)(?:(?:31(?!.(?:0?[2469]|11))|(?:30|29)(?!.0?2)|29(?=.0?2.(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00)))(?:\x20|$))
                    |(?:2[0-8]|1\d|0?[1-9]))([/])(?:1[012]|0[1-9])\1(?:[1|2]\d\d\d)(?:(?=\x20\d)\x20|$))(([01]\d|2[0-3])(:[0-5]\d){1,2})$'.freeze

def competenza_to_s(v)
  if (v || []).empty?
    MSG_COMPETENZA_NESSUN_VALORE
  elsif [v].flatten == [COMPETENZA_TUTTO]
    MSG_COMPETENZA_TUTTI_I_VALORI
  else
    v.join(',')
  end
end

COMPETENZA_SU_TUTTI_I_SISTEMI = { 'vendors' => COMPETENZA_TUTTO, 'reti' => COMPETENZA_TUTTO, 'omc_fisici' => COMPETENZA_TUTTO, 'sistemi' => COMPETENZA_TUTTO }.freeze

HTTP_CODES = [
  HTTP_CODE_OK                   = 200,
  HTTP_CODE_NOT_FOUND            = 404,
  HTTP_CODE_SERVER_ERROR         = 500,
  HTTP_CODE_CUSTOM_SESSION_ERROR = 598
].freeze

# rubocop:disable Metrics/ModuleLength, Style/IndentHash, Style/ClosingParenthesisIndentation, Style/AlignParameters
module Irma
  class NonImplementato < IrmaException; end
  class EsecuzioneAbortita < IrmaException; end

  FILTRO_MM_ENTITA = 'entita'.freeze
  FILTRO_MM_PARAMETRI = 'parametri'.freeze

  RESULT_KEY_FILTRO_MM_FILE = :filtro_metamodello

  NOME_ENTITA_ANY = '*'.freeze

  # Costante db per eccezioni senza etichetta
  LABEL_NC_DB = '-NC-'.freeze

  # Conteggio Alberature
  PREFIX_ECCEZ = 'eccezione'.freeze
  PREFIX_NP = 'pezzo_np'.freeze
  VALORE_CAMPO_SEPARATORE = '     '.freeze

  CONTEGGIO_ALBERATURA_RC_KEYWORD = 'counters_alberatura'.freeze
  CAMPI_FILE_CONTEGGIO_ALBERATURA_RC = %w(np dn tot prio).freeze
  SEP_FILE_CONTEGGIO_ALBERATURA_RC = ','.freeze
  # ---

  WEB_KEY = 'irma.session'.freeze
  WEB_SECRET = (ENV['SECRET'] || 'abcdefghijklmnopqrstuvxyz')

  TEXT_SEP = [
    TEXT_STRUCT_NAME_SEP = '.'.freeze,
    TEXT_STRUCT_SEP = '&'.freeze,
    TEXT_ARRAY_ELEM_SEP = '|'.freeze,
    TEXT_SUB_ARRAY_ELEM_SEP = '!'.freeze,
    TEXT_HEADER_ROW_SEP = "\t".freeze,
    TEXT_DATA_ROW_SEP = TEXT_HEADER_ROW_SEP,
    TEXT_PARAMETRO_ASSENTE = 'ASSENTE'.freeze,
    TEXT_PARAMETRO_ASSENTE_IN_PI = 'ASSENTE_PI'.freeze,
    TEXT_PARAMETRO_IGNORATO = '--'.freeze,
    TEXT_KEY_ASSENTE = 'DA_CANCELLARE'.freeze,
    TEXT_NO_VAL = '<>'.freeze,
    PR_SEP = "\t".freeze,
    TEXT_NO_MOD = 'NON_MODIFICARE'.freeze
  ].freeze
  TEXT_VERSION_ENTITA = 'VERSION_ENTITA'.freeze

  REP_COMP = [
    REP_COMP_KEY_ASSENTE = 'ASSENTE'.freeze,
    REP_COMP_KEY_PRESENTE = 'PRESENTE'.freeze
  ].freeze

  NAME_SEP = [
    NAMING_PATH_SEP = ';'.freeze,
    DIST_NAME_SEP = '/'.freeze,
    DIST_NAME_VALUE_SEP = '='.freeze
  ].freeze

  META_ENTITA_REF_SEP = ','.freeze
  EXTRA_NAME_SEP = ' '.freeze
  META_PARAMETRO_ANY = '*'.freeze
  ARRAY_VAL_SEP = ','.freeze

  VALORE_NON_UTILIZZATO = '-- NON UTILIZZATO --'.freeze
  BASE_DATA_DIR = "@#{ENV_VAR_PREFIX}_HOME@/data".freeze
  BASE_DATA_ARCHIVIO_DIR = BASE_DATA_DIR + '/archivio'.freeze

  TIPI_ESITO_CALCOLO = [
    ESITO_CALCOLO_OK                 = 'esito_calcolo_entita_ok'.freeze, # nessun errore calcolatore, stringa non vuota
    ESITO_CALCOLO_ERRORE_CALCOLATORE = 'esito_calcolo_entita_errore_calcolatore'.freeze, # errore calcolatore
    ESITO_CALCOLO_ERRORE_TIPO        = 'esito_calcolo_entita_errore_tipo'.freeze, # il tipo non corrisponde
    ESITO_CALCOLO_VALORE_VUOTO       = 'esito_calcolo_entita_valore_vuoto'.freeze, # il valore calcolato e' una stringa vuota
    ESITO_CALCOLO_NULL_NO_SAVE       = 'esito_calcolo_entita_null_no_save'.freeze  # il valore calcolato e' un null da ignorare
  ].freeze

  REGOLA_CALCOLO_MULTI = 'multi'.freeze
  REGOLA_CALCOLO_NON_MULTI = 'non_multi'.freeze
  ALL_PRN_CELLS = 'PRN'.freeze

  ADJ_RELATION = [
    NO_ADJ = 0,
    ADJ_INTERNA = 1,
    ADJ_ESTERNA = 2
  ].freeze

  PREFISSI_ADIACENZA = %w(ADJ GADJ_ LADJ_ UADJ_).freeze

  SEP_VR_TERNA = '-'.freeze

  # ===  creazione_fdc
  MANAGED_OBJECT_OPERATIONS = [
    MANAGED_OBJECT_OPERATION_CREATE = :create,
    MANAGED_OBJECT_OPERATION_DELETE = :delete,
    MANAGED_OBJECT_OPERATION_UPDATE = :update
  ].freeze

  AMBITI_FDC = [
    AMBITO_FDC_ADJ   = :adj,
    AMBITO_FDC_NOADJ = :noadj
  ].freeze

  PI_EMPTY_OMCLOGICO = 'PI-EMPTY-RETE-OmcLogico'.freeze
  PI_EMPTY_OMCFISICO = 'PI-EMPTY-RETE-OmcFisico'.freeze

  # === export/import meta_modello
  SEP_DIR_ZIP = '-'.freeze
  NOME_FILE_EXPORT_ME = 'meta_entita_export.loader'.freeze
  NOME_FILE_EXPORT_MP = 'meta_parametri_export.loader'.freeze
  TAG_VENDOR_RELEASE = 'tag_id_vr'.freeze
  TAG_FIRST_ME_ID = 'tag_id_me_0'.freeze

  PR_COLUMNS_ENTITA = [:vendor_release_id, :nome, :naming_path, :descr, :tipo, :versione, :extra_name, :fase_di_calcolo,
                       :meta_entita_ref, :regole_calcolo,
                       :regole_calcolo_ae, :rete_adj, :tipo_adiacenza, :operazioni_ammesse].freeze
  PR_COLUMNS_ENTITA_NEW = [:vendor_release_id, :nome, :naming_path, :descr, :tipo, :versione,
                           :extra_name, :fase_di_calcolo, :meta_entita_ref, :regole_calcolo,
                           :regole_calcolo_ae, :rete_adj, :tipo_adiacenza, :operazioni_ammesse,
                           :updated_at, :created_at].freeze
  PR_COLUMNS_ENTITA_JSON = [:regole_calcolo, :regole_calcolo_ae].freeze
  PR_COLUMNS_PARAMETRI = [:descr, :meta_entita_id, :nome, :nome_struttura, :is_multivalue, :is_multistruct,
                          :genere, :tipo, :vendor_release_id, :is_predefinito, :rete_adj, :tags, :full_name,
                          :regole_calcolo, :regole_calcolo_ae, :is_to_export, :is_obbligatorio, :is_restricted, :is_forced].freeze
  PR_COLUMNS_PARAMETRI_NEW = [:descr, :meta_entita_id, :nome, :nome_struttura, :is_multivalue, :is_multistruct,
                              :genere, :tipo, :vendor_release_id, :is_predefinito, :rete_adj, :tags, :full_name,
                              :regole_calcolo, :regole_calcolo_ae, :is_to_export, :is_obbligatorio, :is_restricted, :is_forced,
                              :updated_at, :created_at].freeze
  PR_COLUMNS_PARAMETRI_JSON = [:regole_calcolo, :regole_calcolo_ae, :tags].freeze

  PR_METAMODELLO_FIELD_SEP = "\t".freeze
  PR_METAMODELLO_OPTIONS = "format text, header false,  delimiter E'\t', null ''".freeze

  PR_COLUMNS_CI_REGIONE = [:ci, :regione, :rete_id, :busy, :updated_at, :created_at].freeze
  PR_COLUMNS_ANAGRAFICA_CGI = [:nome_cella, :lac, :ci, :rete_id, :regione, :updated_at, :created_at].freeze
  PR_COLUMNS_CI_REGIONE_JSON = [].freeze
  PR_COLUMNS_ANAGRAFICA_CGI_JSON = [].freeze
  PR_CGI_FIELD_SEP = "\t".freeze
  PR_CGI_OPTIONS = "format text, header false,  delimiter E'\t', null ''".freeze
  NOME_FILE_EXPORT_CI_REGIONE = 'ci_regione.loader'.freeze
  NOME_FILE_EXPORT_INIT_CI_REGIONE = 'init_ci_regione.loader'.freeze
  NOME_FILE_EXPORT_ANAGRAFICA_CGI = 'anagrafica_cgi.loader'.freeze

  DEFAULT_KEY = 'default'.freeze
  ALIAS_KEY = 'alias'.freeze
  RC_CONSISTENCY_CHECK_PATTERN = '_consistency_check_'.freeze
  RC_DEFAULT_GRP_KEY = 'rc_default'.freeze
  RC_RELNODO_GRP_KEY = 'rc_release_nodo'.freeze
  RC_VENDOR_GRP_KEY = 'rc_vendor'.freeze
  RC_VENDORREL_GRP_KEY = 'rc_vendor_release'.freeze
  MULTIVALORE = 'MULTIVALUE'.freeze
  CLASSE_MP = 'Segment Level'.freeze

  # ===

  TIPI_EXPORT_REPORT_COMPARATIVO = [
    TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE = 'export_rc_totale'.freeze,
    TIPO_EXPORT_REPORT_COMPARATIVO_FU = 'export_rc_formato_utente'.freeze
  ].freeze

  NOME_SUBDIR_FONTE = 'Export_F'.freeze
  NOME_SUB_DIR_ENTITA = 'Entita'.freeze
  NOME_SUB_DIR_PARAMETRI = 'Parametri'.freeze
  RECORD_FIELDS_FONTE = %i(fonte_1 fonte_2).freeze
  RECORD_FIELD_PARAMETRI = 'parametri'.freeze
  RECORD_FIELD_VERSION = 'version'.freeze

  CAMPI_CELLA_PR = [
    CAMPO_CELLA_PR_NOME_CELLA                    = 'nome_cella'.freeze,
    CAMPO_CELLA_PR_RETE                          = 'rete'.freeze,
    CAMPO_CELLA_PR_VENDOR_RELEASE_COMPACT_DESCR  = 'vendor_release_compact_descr'.freeze,
    CAMPO_CELLA_PR_VENDOR_SIGLA                  = 'vendor_sigla'.freeze,
    CAMPO_CELLA_PR_VENDOR_NOME                   = 'vendor_nome'.freeze,
    CAMPO_CELLA_PR_NOME_NODO                     = 'nome_nodo'.freeze,
    CAMPO_CELLA_PR_RELEASE_NODO                  = 'release_nodo'.freeze,
    CAMPO_CELLA_PR_OMC_FISICO_ID                 = 'omc_fisico_completo_id'.freeze,
    CAMPO_CELLA_PR_SISTEMA_ID                    = 'sistema_id'.freeze,
    CAMPO_CELLA_PR_ADJS                          = 'adjs'.freeze
  ].freeze

  #
  # main class for constants
  #
  class Constant < ConstantManager; end

  # ===  creazione_fdc
  Constant.define(:modo_creazione_fdc,
    tutto_separato: { value: 1, descr: 'tutto separato' },
    file_unico:     { value: 2, descr: 'file unico' },
    per_operazione: { value: 3, descr: 'entita divise per operazione UPD, CRE, DEL' },
    per_ambito:     { value: 4, descr: 'entita divise per ambito ADJ, NO_ADJ' }
  )

  Constant.define(:etichetta_eccezioni, {
    nota:     { value: 1, descr: 'Nota', prefix: 'Nota_' },
    generica: { value: 2, descr: 'Generica' }
  }, :tipo)

  Constant.define(:filtro_labels,
    nette:     { value: 0, label: 'Si' },
    non_nette: { value: 1, label: 'No' },
    tutte:     { value: 2, label: 'Tutte' }
  )

  Constant.define(:fase_calcolo, FASE_CALCOLO = {
    pi:       { value: 0, label: 'PI' },
    ref:      { value: 1, label: 'REF' },
    adj:      { value: 2, label: 'ADJ' },
    pi_alias: { value: 3, label: 'PI ALIAS' }
  }.freeze)

  Constant.define(:calcolo_sorgente, CALCOLO_TIPO_SORGENTE = {
    omclogico: { value: 0 },
    omcfisico: { value: 1 },
    pi:        { value: 2 }
  }.freeze)

  Constant.define(:tipo_adiacenza,
    nessuna:   { descr: 'nessuna', value: (1 << -1) },
    interna:   { descr: 'interna', value: tai = (1 << 0) },
    esterna:   { descr: 'esterna', value: tae = (1 << 1) },
    int_est:   { descr: 'interna ed esterna', value: tai + tae }
  )

  Constant.define(:operazioni_ammesse,
    nessuna:  { descr: 'nessuna', value: (1 << -1) },
    create:   { descr: 'create', value: (1 << 0) },
    update:   { descr: 'update', value: (1 << 1) },
    delete:   { descr: 'delete', value: (1 << 2) }
  )

  Constant.define(:stato_sessione,
    ok:         { value: 'ok' },
    scaduta:    { value: 'scaduta' },
    non_valida: { value: 'non_valida' }
  )

  Constant.define(:db_init,
    none:          1,
    with_cache:    2,
    without_cache: 3
  )

  Constant.define(:account, {
    attivo:    'attivo',
    sospeso:   'sospeso',
    disattivo: 'disattivo'
  }, :stato)

  Constant.define(:tipo_utente,
    non_avvalorato: '',
    sconosciuto:    'U',
    interno:        'I',
    esterno:        'E',
    sistema:        'S'
  )

  Constant.define(:app_config, {
    interno:              0,
    gui_non_modificabile: 1,
    gui:                  2
  }, :ambito)

  Constant.define(:esito_ricerca_matricola_utente,
    inesistente:     { value: 'none' },
    trovato_account: { value: 'modify' },
    trovato_in_ldap: { value: 'add' },
    errore:          { value: 'errore' }
  )

  Constant.define(:autenticazione,
    adam: { value: 1, descr: 'Autenticazione AD/AM' },
    auto: { value: 2, descr: "Per l'autenticazione deve essere fornita come password la matricola" }
  )

  Constant.define(:email_template,
    account_attivato:    1,
    account_sospeso:     2,
    account_disattivato: 3,
    account_modificato:  4
  )

  Constant.define(:server, {
    attivo:     'attivo',
    non_attivo: 'non_attivo'
  }, :stato)

  Constant.define(:server, {
    as:           { value: 1, descr: 'Application Server' }
  }, :tipo)

  Constant.define(:ambiente, TIPI_AMBIENTE = {
    prog: { value: 'prog', descr: 'Ambiente di progettazione' },
    qual: { value: 'qual', descr: 'Ambiente di qualità' }
  }.freeze)

  Constant.define(:archivio_rete_conf, TIPI_ARCHIVIO = {
    rete: { value: 'rete', descr: 'Archivio di rete' },
    conf: { value: 'conf', descr: 'Archivio di configurazione' }
  }.freeze)

  Constant.define(:archivio, TUTTI_GLI_ARCHIVI = TIPI_ARCHIVIO.merge(
    eccezioni: { value: 'eccezioni', descr: 'Archivio delle eccezioni' },
    label: { value: 'label', descr: 'Archivio delle eccezioni con label' }
  ).freeze)

  Constant.define(:attivita_archivio, TUTTI_GLI_ARCHIVI.merge(nodef: { value: 'nodef', descr: 'Archivio non definito' }))

  Constant.define(:filtro_sistemi_omc_fisici,
    all:            { value: 'Tutti' },
    nothing:        { value: 'Nessun Valore' },
    progetto_irma:  { value: 'Progetto Irma' },
    progetto_radio: { value: 'Progetto Radio' }
  )

  Constant.define(:formato_export, FORMATO_EXPORT = {
    xls:  { value: 'xls', label: 'Excel', descr: 'Excel' },
    txt:  { value: 'txt', label: 'Text',  descr: 'Text' }
  }.freeze)

  Constant.define(:formato_export_esteso, {
    no:   { value: 'none', descr: 'No' }
  }.merge(FORMATO_EXPORT))

  Constant.define(:rep_comp_esito,
    uguale:      { value: 0, label: 'uguale' },
    assente_1:   { value: 1, label: 'assente su fonte 1' },
    assente_2:   { value: 2, label: 'assente su fonte 2' },
    differenze:  { value: 3, label: 'differente' }
  )

  Constant.define(:meta_entita, TIPI_VALORE_META = {
    char:    { value: 'char' },
    integer: { value: 'integer' },
    float:   { value: 'float' }
  }.freeze, :tipo)

  Constant.define(:tipo_valore, TIPI_VALORE_META)

  Constant.define(:meta_parametro, TIPI_VALORE_META, :tipo)

  # ===  cgi
  Constant.define(:ci_regione, {
    no:         { value: 0 },
    si:         { value: 1 },
    confinante: { value: 2 }
  }, :busy)

  #
  LOCK_KEY_PREFIX = 'lock$'.freeze

  Constant.define(:lock_key,
                  ambiente_archivio_sistema:   { patterns: [LOCK_KEY_PREFIX + '%{ambiente}$%{archivio}$%{vendor}$%{rete}$%{omc_logico}'] },
                  ambiente_sistema:            { patterns: Constant.values(:archivio).map { |archivio| LOCK_KEY_PREFIX + "%{ambiente}$#{archivio}$%{vendor}$%{rete}$%{omc_logico}" } },
                  archivio_omcfisico:          { patterns: [LOCK_KEY_PREFIX + '%{archivio}$%{vendor}$%{omc_fisico}'] },
                  archivio_eccezioni:          { patterns: [LOCK_KEY_PREFIX + '%{archivio}$%{vendor}$%{rete}$%{omc_logico}'] },
                  archivio_label:              { patterns: [LOCK_KEY_PREFIX + '%{archivio}$%{vendor}$%{rete}$%{omc_logico}'] },
                  progetto_irma:               { patterns: [LOCK_KEY_PREFIX + 'progetto_irma$%{id}'] },
                  report_comparativo:          { patterns: [LOCK_KEY_PREFIX + 'report_comparativo$%{id}'] },
                  progetto_radio_omc_logico:   { patterns: [LOCK_KEY_PREFIX + 'progetto_radio$%{omc_logico}$%{rete}'] },
                  progetto_radio_omc_fisico:   { patterns: [LOCK_KEY_PREFIX + 'progetto_radio$%{omc_fisico}'] },
                  meta_modello:                { patterns: [LOCK_KEY_PREFIX + 'meta_modello'] },
                  meta_modello_fisico:         { patterns: [LOCK_KEY_PREFIX + 'meta_modello_fisico'] },
                  anagrafica_enodeb:           { patterns: [LOCK_KEY_PREFIX + 'anagrafica_enodeb'] },
                  anagrafica_cgi:              { patterns: [LOCK_KEY_PREFIX + 'anagrafica_cgi'] },
                  anagrafica_gnodeb:           { patterns: [LOCK_KEY_PREFIX + 'anagrafica_gnodeb'] },
                  ci_regione:                  { patterns: [LOCK_KEY_PREFIX + 'ci_regione'] },
                  etichetta_eccezioni:         { patterns: [LOCK_KEY_PREFIX + 'etichetta_eccezioni'] },
                  scheduler_master:            { patterns: ['scheduler:master'] }
                 )
  Constant.define(:lock_mode,
                  read:  { value: 'read', descr: 'Modalità di lock in scrittura' },
                  write: { value: 'write', descr: 'Modalità di lock in lettura' }
                 )

  #
  Constant.define(:esito_analisi_entita,
                  ok:                     { descr: 'entita\'correttamente analizzata e validata' },
                  da_ignorare:            { descr: 'entita\' da ignorare' },
                  dist_name_non_valido:   { descr: 'entita\' con un dist_name che non e\' valido' },
                  metamodello_non_valido: { descr: 'entita\' che non ha passato il controllo con il metamodello' },
                  senza_padre:            { descr: 'entita\' il cui padre non e\' presente nella gerarchia o e\' stato scartato' },
                  nodo_non_valido:        { descr: 'entita\' che risulta essere un nodo non valido per il sistema corrente' },
                  duplicata:              { descr: 'entita\' che risulta essere duplicata' },
                  cmdata_errato:          { descr: 'type del tag cmData non valorizzato ad actual' },
                  datetime_errato:        { descr: 'dataTime del tag log non valorizzato con il giorno corrente' },
                  non_competente:         { descr: 'entita\' SubNetwork di secondo livello contenente il nome di un sistema non di competenza' },
                  riga_non_valida:        { descr: 'riga che non ha superato uno dei controlli obbligatori previsti' }
                 )

  Constant.define(:pub,
                  alive:                  { value: 'alive',               descr: 'messaggio di segnalazione che la coda è viva' },
                  attivita_schedulata:    { value: 'attivita_schedulata', descr: 'coda di pubblicazione eventi di creazione/aggiornamento attivita_schedulata' },
                  attivita:               { value: 'attivita',            descr: 'coda di pubblicazione eventi di creazione/aggiornamento attivita' },
                  app_config:             { value: 'app_config',          descr: 'coda di pubblicazione eventi di modifica app_config' },
                  cache:                  { value: 'cache',               descr: 'coda di pubblicazione eventi di modifica di model che vengono memorizzati nella cache' },
                  sessioni:               { value: 'sessioni',            descr: 'coda di pubblicazione eventi di modifica sessioni' }
                 )

  Constant.define(:filtro_segnalazioni, {
    all:        { value: 'all',         label: 'Tutti' },
    mine:       { value: 'mine',        label: 'Proprio' },
    mineother:  { value: 'mineother',   label: 'Propri altri account' },
    other:      { value: 'other',       label: 'Altri account' }
  }, :utente)

  Constant.define(:filtro_segnalazioni, {
    all:   { value: 'all',   label: 'Tutte' },
    yes:   { value: 'true',  label: 'Si' },
    no:    { value: 'false', label: 'No' }
  }, :importabile)

  Constant.define(:operatori,
    inizia_con:   { value: 'inizia con' },
    finisce_con:  { value: 'finisce con' },
    contiene:     { value: 'contiene' }
  )

  Constant.define(:renderer,
    nome_param_suffix:    { value: '_rendered' }
  )

  Constant.define(:flag_cancellazione,
    nessuna: { value: 0, label: 'Nessuna' },
    intra:   { value: fc_intra = 1 << 0, label: 'Intrafrequenza' },
    inter:   { value: fc_inter = 1 << 1, label: 'Interfrequenza' },
    all:     { value: (fc_intra | fc_inter), label: 'Tutte' }
  )

  Constant.define(:filtro_rc_account_consistency_check, {
    mine:               { value: 'mine',                label: 'Proprio' },
    consistency_check:  { value: 'consistency_check',   label: 'Consistency Check' },
    other:              { value: 'other',               label: 'Altri' }
  }, :utente)

  Constant.define(:gestione_spazio,
    nessuna:              { value: 'nessuna' },
    lista_esatta:         { value: 'lista esatta' },
    virgola:              { value: 'virgola' }
  )

  # --- operazioni ammesse su oggetto model
  MODEL_OBJECT_OPERATIONS = [
    MODEL_OBJECT_OPERATION_CREATE = :create,
    MODEL_OBJECT_OPERATION_DELETE = :delete,
    MODEL_OBJECT_OPERATION_UPDATE = :update
  ].freeze

  AUDIT_OPERAZIONE = {
    create: { value: 0 },
    update: { value: 1 },
    delete: { value: 2 }
  }.freeze
  Constant.define(:audit_operazione, AUDIT_OPERAZIONE)
  Constant.define(:audit_meta_entita, AUDIT_OPERAZIONE, :operazione)
  Constant.define(:audit_meta_parametro, AUDIT_OPERAZIONE, :operazione)

  AUDIT_SORGENTE = {
    gui:            { value: 0 },
    file:           { value: 1 },
    copia_adrn:     { value: 2 },
    import_loader:  { value: 3 }
  }.freeze
  Constant.define(:audit_sorgente, AUDIT_SORGENTE)
  Constant.define(:audit_meta_entita, AUDIT_SORGENTE, :sorgente)
  Constant.define(:audit_meta_parametro, AUDIT_SORGENTE, :sorgente)

  # AGGIORNA_ADRN_OPERATIONS = [
  # AGGIORNA_ADRN_OPERATION_INSERT = 'insert'.freeze,
  # AGGIORNA_ADRN_OPERATION_INSERT_OR_UPDATE = 'insert_or_update'.freeze,
  # AGGIORNA_ADRN_OPERATION_DELETE = 'delete'.freeze
  # ].freeze

  Constant.define(:aggiorna_adrn_operation,
    insert:           { value: 'insert' },
    insert_or_update: { value: 'insert_or_update' },
    delete:           { value: 'delete' }
  )

  Constant.define(:tipo_obj_mm, TIPI_OBJ_MM = {
    entita: { value: '0' },
    parametro: { value: '1' }
  }.freeze)
  #
  require_relative 'constants/tipo_allarme'
  require_relative 'constants/tipo_evento'
  require_relative 'constants/funzione'
  require_relative 'constants/profilo'
  require_relative 'constants/tipo_segnalazione'
  require_relative 'constants/tipo_attivita'
  require_relative 'constants/comando'
  require_relative 'constants/rete_vendor'
  require_relative 'constants/anagrafica_territoriale'
end
