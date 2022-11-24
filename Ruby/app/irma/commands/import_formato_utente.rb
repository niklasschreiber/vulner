# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20160816
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define IMPORT_FORMATO_UTENTE_LOCK_EXPIRE = :import_formato_utente_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di import formato utente',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :input_file, type: :string,  banner: 'Nome file zip di input'
    method_option :sistema_id,  type: :numeric, banner: 'Identificativo del sistema'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,    type: :string,  banner: "Archivio di riferimento delle entita'"
    method_option :nodo_naming_path, type: :boolean, banner: 'Controllo del nodo con naming_path', default: true
    method_option :usa_files_temporanei, type: :boolean, banner: 'Usa i files temporanei nell\'import totale', default: true
    method_option :metamodello, type: :boolean, banner: 'Controllo del metamodello', default: true
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{IMPORT_FORMATO_UTENTE_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :omc_fisico, type: :boolean, banner: 'Attivazione Import Costruttore per Omc Fisco', default: false
    method_option :flag_cancellazione, type: :boolean, banner: 'File di cancellazione', default: false
    method_option :label_eccezioni, type: :string, banner: 'Etichetta per le eccezioni', default: nil

    common_options 'import_formato_utente', "Esegue l'aggiornamento dell'archivio utilizzando i file in input"
    def import_formato_utente
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: options[:sistema_id], account: options[:account_id], archivio: options[:archivio])

      import_opts = { 
        attivita_id:          options[:attivita_id],
        stats:                true,
        node_exit:            false,
        solo_header:          false,
        usa_files_temporanei: options[:usa_files_temporanei],
        flag_cancellazione:   options[:flag_cancellazione],
        nodo_naming_path:     options[:nodo_naming_path] ? saa.sistema.nodo_naming_path : nil,
        label_eccezioni:      options[:label_eccezioni],
        expire:               options[:lock_expire] || config[IMPORT_FORMATO_UTENTE_LOCK_EXPIRE]
      }

      import_opts.update(check_input_file_for_import(options[:input_file]))

      import_opts[:log_prefix] = "Import formato utente per #{options[:omc_fisico] ? 'omc fisico' : 'sistema'} #{saa.full_descr} (id=#{saa.sistema_id})," +
        " numero file=#{import_opts[:lista_file].size}, account=#{saa.account.full_descr}" +
        " #{import_opts[:delta] ? 'delta' : 'totale'}" +
        "#{options[:nodo_naming_path] ? " con nodo_naming_path #{import_opts[:nodo_naming_path]}" : ''}" +
        " expire=#{import_opts[:expire]}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) { saa.import_formato_utente(import_opts) }
    ensure
      cleanup_temp_files
    end

    private

    def pre_import_formato_utente
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
