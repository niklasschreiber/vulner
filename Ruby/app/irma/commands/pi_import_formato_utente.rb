# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20161010
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define CALCOLO_PI_LOCK_EXPIRE = :calcolo_pi_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di calcolo progetto irma',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :nome, type: :string,  banner: 'Nome del Progetto Irma'
    method_option :sistema_id,  type: :numeric, banner: 'Identificativo del sistema'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,    type: :string,  banner: "Archivio di riferimento'", default: ARCHIVIO_RETE
    method_option :tipo_sorgente,  type: :numeric,  banner: 'Tipologia sorgente per parametri predefiniti'
    method_option :sorgente_pi_id,       type: :numeric,  banner: 'Id di ProgettoIrma da usare per parametri predefiniti' # (id)
    method_option :nodo_naming_path, type: :boolean, banner: 'Controllo del nodo con naming_path', default: true
    method_option :usa_files_temporanei, type: :boolean, banner: 'Usa i files temporanei nell\'import totale', default: true
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{CALCOLO_PI_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :omc_fisico, type: :boolean, banner: 'Attivazione Calcolo Progetto IRMA per Omc Fisco', default: false
    method_option :input_file, type: :string,  banner: 'Nome del file archivio in input'
    method_option :flag_cancellazione, type: :boolean, banner: 'File di cancellazione', default: false
    method_option :flag_update, type: :boolean, banner: "Importo solo in modalita' update", default: false

    common_options 'pi_import_formato_utente', "Crea/Aggiorna un Progetto IRMA tramite i file in formato utente"
    def pi_import_formato_utente
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: options[:sistema_id], account: options[:account_id], archivio: options[:archivio])

      import_opts = { 
        attivita_id:          options[:attivita_id],
        stats:                true,
        node_exit:            true,
        usa_files_temporanei: options[:usa_files_temporanei],
        use_pi:               true,
        nodo_naming_path:     options[:nodo_naming_path] ? saa.sistema.nodo_naming_path : nil,
        flag_cancellazione:   options[:flag_cancellazione],
        flag_update:          options[:flag_update],
        expire:               options[:lock_expire] || config[CALCOLO_PI_LOCK_EXPIRE]
      }

      import_opts.update(check_input_file_for_import(options[:input_file]))

      # Sorgente
      sorgente = nil
      per_omcfisico = false
      per_omcfisico_id = nil
      tabella_sorgente = nil
      label_sorgente = nil
      
      tipo_sorgente = options[:tipo_sorgente] || CALCOLO_SORGENTE_OMCLOGICO
      case tipo_sorgente
      when CALCOLO_SORGENTE_OMCLOGICO
        sorgente = Db::SistemaAmbienteArchivio.new(sistema: options[:sistema_id], archivio: ARCHIVIO_RETE, account: options[:account_id])
        tabella_sorgente = sorgente.entita.table_name
      when CALCOLO_SORGENTE_OMCFISICO
        x_id = options[:omc_fisico] ? options[:sistema_id] : Db::Sistema.first(id: options[:sistema_id]).omc_fisico_id
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
      label_sorgente ||= "Archivio Rete #{Constant.label(:calcolo_sorgente, tipo_sorgente)}"

      parametri_input = { 'tipo_sorgente' => tipo_sorgente, 'sorgente' => tabella_sorgente,
                          'per_omcfisico' => per_omcfisico_id, 'descr_sorgente' => label_sorgente,
                          'sistema_id' => saa.sistema_id }

      
      # AmbienteArchivio di riferimento su cui va agganciato il PI
      saa_rif = if per_omcfisico_id
                  Db::OmcFisicoAmbienteArchivio.new(omc_fisico: per_omcfisico_id, archivio: ARCHIVIO_RETE, account: options[:account_id])
                else
                  saa
                end

      saa_rif.crea_o_associa_progetto_irma(nome: options[:nome], parametri_input: parametri_input)
      import_opts[:saa_riferimento] = saa_rif

      import_opts[:log_prefix] = "Import Formato Utente su Progetto Irma #{options[:nome]} per #{options[:omc_fisico] ? 'omc fisico' : 'sistema'} #{saa.full_descr} (id=#{saa.sistema_id})," +
      " tipo_sorgente #{tipo_sorgente}#{per_omcfisico ? ', per omc fisico' : ''}, numero file=#{import_opts[:lista_file].size}, account=#{saa.account.full_descr}" +
        "#{options[:nodo_naming_path] ? " con nodo_naming_path #{import_opts[:nodo_naming_path]}" : ''}" +
        " expire=#{import_opts[:expire]}"

      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) { saa.import_formato_utente(import_opts) }
    ensure
      cleanup_temp_files
    end

    private

    def pre_pi_import_formato_utente
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
