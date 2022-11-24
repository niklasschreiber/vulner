# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli, S. Campestrini
#
# Creation date: 20170210
#

#
module Irma
  # rubocop:disable Metrics/ClassLength
  class Command < Thor
    config.define CALCOLO_PR_LOCK_EXPIRE = :calcolo_pr_lock_expire, 1800,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di calcolo_da_progetto_radio',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'
    config.define CALCOLO_PR_MIN_CELLE_PER_PRECARICAMENTO = :calcolo_pr_min_celle_per_precaricamento, 100,
                  descr:         'Numero minimo di celle per eseguire il precaricamento dei parametri predefiniti',
                  widget_info:   'Gui.widget.positiveInteger({minValue:1,maxValue:100000})',
                  profili:       PROFILI_PER_PARAMETRO_DI_RPN
    config.define CALCOLO_PR_PRECALCOLO_REGOLE = :calcolo_pr_precalcolo_regole, 1,
                  descr:         'Flag per precalcolare le regole di metamodello che sono valutabili prima di eseguire il calcolo',
                  widget_info:   'Gui.widget.booleanInteger()',
                  profili:       PROFILI_PER_PARAMETRO_DI_RPN

    method_option :account_id,           type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,             type: :string,  banner: "Archivio di riferimento delle entita'"
    method_option :omc_id,               type: :numeric,  banner: 'Sistema/OmcFisico per cui effettuare il calcolo' # (id)
    method_option :lock_expire,          type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{CALCOLO_PR_LOCK_EXPIRE})"
    method_option :min_celle_precar,     type: :numeric, banner: "Minimo numero celle per precaricamento (default valore di configurazione #{CALCOLO_PR_MIN_CELLE_PER_PRECARICAMENTO})"
    method_option :precalcolo_regole,    type: :numeric, banner: "Precalcolo regole (default valore di configurazione #{CALCOLO_PR_PRECALCOLO_REGOLE})"
    method_option :filtro_metamodello,   type: :string, banner: 'Filtro su meta_entita e relativi parametri'
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'
    method_option :usa_files_temporanei, type: :boolean, banner: 'Usa i files temporanei nell\'import', default: true
    method_option :lista_celle,          type: :string, banner: 'Celle di ProgettoRadio per cui effettuare il calcolo' # Stringa di nome_cella divisi da ','
    method_option :nome_progetto_irma,   type: :string, banner: 'Nome per il ProgettoIrma da creare'

    method_option :tipo_sorgente,        type: :numeric,  banner: 'Tipologia sorgente per parametri predefiniti'
    method_option :sorgente_pi_id,       type: :numeric,  banner: 'Id di ProgettoIrma da usare per parametri predefiniti' # (id)
    method_option :omc_fisico,           type: :boolean, banner: 'Attivazione calcolo per Omc Fisico', default: false
    method_option :celle_adiacenti,      type: :boolean, banner: 'Include nel calcolo tutte le celle adiacenti di quelle indicate dello stesso sistema', default: false
    method_option :no_eccezioni,         type: :boolean, banner: 'Attivazione calcolo senza prelievo da archivio delle eccezioni', default: false

    common_options 'calcolo_da_progetto_radio', 'Esegue il calcolo per celle di Progetto Radio'
    def calcolo_da_progetto_radio # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # Check flag omc_fisico
      raise "Il calcolo non puo' attualmente essere effettuato per un OmcFisico" if options[:omc_fisico]

      # Sistema(AmbienteArchivio) di riferimento per il recupero delle celle e per il metamodello
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: options[:omc_id], account: options[:account_id], archivio: options[:archivio])

      # Check lista_celle
      # q = Db::ProgettoRadio.where(sistema_id: options[:omc_id])
      q = Db::ProgettoRadio.where_sistema_id(options[:omc_id])
      lista_celle = options[:lista_celle].to_s == ALL_PRN_CELLS ? q.select_map(:nome_cella) : options[:lista_celle].to_s.split(',')
      raise "Non e' stata specificata nessuna cella di ProgettoRadio per il calcolo" if lista_celle.empty?

      # Sorgente
      sorgente = nil
      per_omcfisico = false
      per_omcfisico_id = nil
      tabella_sorgente = nil

      # Tipologia sorgente per parametri predefiniti: OmcLogico(#{CALCOLO_SORGENTE_OMCLOGICO}), OmcFisico(#{CALCOLO_SORGENTE_OMCFISICO}), ProgettoIrma(#{CALCOLO_SORGENTE_PI}) (default: OmcLogico)
      tipo_sorgente = options[:tipo_sorgente] || CALCOLO_SORGENTE_OMCLOGICO
      label_sorgente = nil
      case tipo_sorgente
      when CALCOLO_SORGENTE_OMCLOGICO
        sorgente = Db::SistemaAmbienteArchivio.new(sistema: options[:omc_id], archivio: ARCHIVIO_RETE, account: options[:account_id])
        tabella_sorgente = sorgente.entita.table_name
      when CALCOLO_SORGENTE_OMCFISICO
        x_id = options[:omc_fisico] ? options[:omc_id] : Db::Sistema.first(id: options[:omc_id]).omc_fisico_id
        sorgente = Db::OmcFisicoAmbienteArchivio.new(omc_fisico: x_id, archivio: ARCHIVIO_RETE, account: options[:account_id])
        per_omcfisico = true
        per_omcfisico_id = x_id
        tabella_sorgente = sorgente.entita.table_name
      when CALCOLO_SORGENTE_PI
        pi = Db::ProgettoIrma.first(id: options[:sorgente_pi_id])
        per_omcfisico_id = pi.per_omcfisico
        if per_omcfisico_id # pi.sistema_id
          sorgente = Db::OmcFisicoAmbienteArchivio.new(omc_fisico: per_omcfisico_id, archivio: pi.archivio, account: options[:account_id])
          per_omcfisico = true
        else
          sorgente = Db::SistemaAmbienteArchivio.new(sistema: pi.sistema_id, archivio: pi.archivio, account: options[:account_id])
        end
        tabella_sorgente = pi.entita.table_name
        sorgente.associa_progetto_irma(nome: pi.nome)
        label_sorgente = "#{Constant.label(:calcolo_sorgente, tipo_sorgente)} #{pi.nome}"
      end

      raise "Impossibile determinare la sorgente per avvalorare parametri predefiniti. tipo_sorgente: #{tipo_sorgente}, sorgente_pi_id: #{options[:sorgente_pi_id]}" unless sorgente

      # AmbienteArchivio di riferimento su cui va agganciato il PI
      saa_rif = if per_omcfisico_id
                  Db::OmcFisicoAmbienteArchivio.new(omc_fisico: per_omcfisico_id, archivio: ARCHIVIO_RETE, account: options[:account_id])
                else
                  saa
                end

      function_opts = {
        attivita_id:                             options[:attivita_id],
        expire:                                  options[:lock_expire] || config[CALCOLO_PR_LOCK_EXPIRE],
        precaricamento:                          options[:min_celle_precar] || config[CALCOLO_PR_MIN_CELLE_PER_PRECARICAMENTO],
        use_pi:                                  true,
        delta:                                   false,
        lista_celle:                             lista_celle,
        aggiungi_celle_adiacenti_per_il_calcolo: options[:celle_adiacenti],
        # filtro_metamodello:                      options[:filtro_metamodello].to_s.empty? ? nil : JSON.parse(options[:filtro_metamodello]),
        filtro_metamodello:                      determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file], filtro_mm: options[:filtro_metamodello]),
        sorgente:                                sorgente,
        label_sorgente:                          label_sorgente || "Archivio Rete #{Constant.label(:calcolo_sorgente, tipo_sorgente)}",
        usa_files_temporanei:                    options[:usa_files_temporanei],
        per_omcfisico:                           per_omcfisico,
        saa_riferimento:                         saa_rif,
        precalcolo_regole:                       (options[:precalcolo_regole] || config[CALCOLO_PR_PRECALCOLO_REGOLE]).to_i == 1 ? true : false,
        logger:                                  logger,
        no_eccezioni:                            options[:no_eccezioni]
      }
      function_opts[:log_prefix] = "Calcolo da ProgettoRadio Omc #{options[:omc_fisico] ? 'Fisico' : 'Logico'} #{saa.full_descr}" \
                                   " (#{lista_celle.size} celle#{options[:celle_adiacenti] ? ' e relative adiacenze' : ''}," \
                                   " tipo_sorgente #{tipo_sorgente}#{per_omcfisico ? ', per omc fisico' : ''}#{function_opts[:precalcolo_regole] ? ', precalcolo regole' : ''})"

      begin
        parametri_input = { 'tipo_sorgente' => tipo_sorgente, 'sorgente' => tabella_sorgente,
                            'per_omcfisico' => per_omcfisico_id, 'descr_sorgente' => function_opts[:label_sorgente],
                            'sistema_id' => saa.sistema_id }
        saa_rif.crea_progetto_irma(nome: options[:nome_progetto_irma], account_id: options[:account_id], parametri_input: parametri_input)
        saa_rif.associa_progetto_irma(nome: options[:nome_progetto_irma])
      rescue => e
        raise "Creazione di nuovo ProgettoIrma #{options[:nome_progetto_irma]} fallita. #{e}"
      end

      res = { nome_progetto_irma: options[:nome_progetto_irma] }
      res.update(Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: function_opts[:log_prefix]) { _profile_calcolo_da_progetto_radio { saa.calcolo_da_progetto_radio(function_opts) } })
      res[RESULT_KEY_FILTRO_MM_FILE] = options[:filtro_metamodello_file] if options[:filtro_metamodello_file]
      res
    end

    private

    def _profile_calcolo_da_progetto_radio(&_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      ret = nil
      if ENV['PROFILE_CALCOLO']
        require 'jruby/profiler'
        profile_data = JRuby::Profiler.profile { ret = yield }
        ret[:profiling] = true
        [JRuby::Profiler::FlatProfilePrinter, JRuby::Profiler::GraphProfilePrinter].each do |profile_printer|
          STDOUT.puts "*************************************************** #{profile_printer} **********************************"
          printer = profile_printer.new(profile_data)
          ps = java.io.PrintStream.new(STDOUT.to_outputstream)
          printer.printHeader(ps)
          printer.printProfile(ps)
          printer.printFooter(ps)
          STDOUT.puts '_________________________________________________________________________________________________________'
        end
      else
        ret = yield
      end
      ret
    end

    def pre_calcolo_da_progetto_irma
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
