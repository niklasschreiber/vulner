# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160210
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define IMPORT_COSTRUTTORE_LOCK_EXPIRE = :import_costruttore_lock_expire, 3600,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di import costruttore',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :input_file,  type: :string,  banner: 'Nome del file di input'
    method_option :sistema_id,  type: :numeric, banner: 'Identificativo del sistema'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,    type: :string,  banner: "Archivio di riferimento delle entita'"
    method_option :ambiente,    type: :string,  banner: "Ambiente di riferimento delle entita'", default: nil
    method_option :nodo_naming_path, type: :boolean, banner: 'Controllo del nodo con naming_path', default: true
    method_option :check_data,  type: :boolean, banner: 'Controllo che la data nel file corrisponda alla data odierna', default: false
    # method_option :delta,       type: :boolean, banner: 'Prova l\'import per delta se ci sono le condizioni', default: false
    method_option :usa_files_temporanei, type: :boolean, banner: 'Usa i files temporanei nell\'import totale', default: true
    method_option :metamodello, type: :boolean, banner: 'Controllo del metamodello', default: true
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{IMPORT_COSTRUTTORE_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :omc_fisico, type: :boolean, banner: 'Attivazione Import Costruttore per Omc Fisco', default: false

    common_options 'import_costruttore', "Esegue l'import costruttore utilizzando il file di input specificato"
    def import_costruttore
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: options[:sistema_id], account: options[:account_id], archivio: options[:archivio])

      @input_file = absolute_file_path(options[:input_file] || Irma.shared_relative_audit_file(saa.sistema.nome_file_audit))
      raise "Input file '#{@input_file}' non trovato per l'import" unless File.exist?(@input_file)

      import_opts = { 
        attivita_id:          options[:attivita_id],
        file:                 @input_file,
        delta:                false,
        stats:                true,
        node_exit:            false,
        check_data:           options[:check_data],
        usa_files_temporanei: options[:usa_files_temporanei],
        metamodello:          options[:metamodello] ? saa.sistema.metamodello : nil,
        nodo_naming_path:     options[:nodo_naming_path] ? saa.sistema.nodo_naming_path : nil,
        expire:               options[:lock_expire] || config[IMPORT_COSTRUTTORE_LOCK_EXPIRE]
      }
      import_opts[:log_prefix] = "Import costruttore per #{options[:omc_fisico] ? 'omc fisico' : 'sistema'} #{saa.full_descr} (id=#{saa.sistema_id})," +
        " file=#{@input_file}, account=#{saa.account.full_descr}" +
        " #{import_opts[:delta] ? 'delta' : 'totale'}" +
        "#{options[:nodo_naming_path] ? " con nodo_naming_path #{import_opts[:nodo_naming_path]}" : ''}" +
        " expire=#{import_opts[:expire]}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) { saa.import_costruttore(import_opts) }
    ensure
      cleanup_temp_files
    end
    
    private

    def pre_import_costruttore
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
