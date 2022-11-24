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
    config.define IMPORT_PROGETTO_RADIO_LOCK_EXPIRE = :import_progetto_radio_lock_expire, 600,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di import progetto radio',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:1800})'

    method_option :input_file,  type: :string,  banner: 'Nome file di input (txt o xls)'
    method_option :sistema_id,  type: :numeric, banner: 'Identificativo del sistema'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,    type: :string,  banner: "Archivio di riferimento delle entita'", default: ARCHIVIO_RETE
    method_option :usa_files_temporanei, type: :boolean, banner: 'Usa i files temporanei nell\'import totale', default: true
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{IMPORT_PROGETTO_RADIO_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :omc_fisico, type: :boolean, banner: 'Attivazione import di Progetto Radio per Omc Fisco', default: false
    method_option :flag_cancellazione, type: :boolean, banner: 'File di cancellazione delle celle non importate', default: false
    method_option :ctrl_nv_adj_inesistenti, type: :string, banner: 'Indicazioni su controllo non vincolante adiacenze inesistenti', default: '[]'
    method_option :ctrl_nv_reciprocita_adj, type: :string, banner: 'Indicazioni su controllo non vincolante reciprocita adiacenze', default: '[]'
    # TODO: aggiungere flag per attivazione controlli non vincolanti

    common_options 'import_progetto_radio', "Esegue l'aggiornamento dell'archivio di Progetto Radio Nazionale con i dati contenuti nel file in input"
    def import_progetto_radio
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: options[:sistema_id], account: options[:account_id], archivio: options[:archivio])

      import_opts = { 
        attivita_id:          options[:attivita_id],
        stats:                true,
        node_exit:            true,
        usa_files_temporanei: options[:usa_files_temporanei],
        expire:               options[:lock_expire] || config[IMPORT_PROGETTO_RADIO_LOCK_EXPIRE],
        delete_no_prog:       options[:flag_cancellazione],
        lista_file:           []
      }

      # controlli_non_vincolanti
      ctrl_nv = {}
      ctrl_nv[:ctrl_nv_adj_inesistenti] = JSON.parse(options[:ctrl_nv_adj_inesistenti] || '[]')
      ctrl_nv[:ctrl_nv_reciprocita_adj] = JSON.parse(options[:ctrl_nv_reciprocita_adj] || '[]')
      import_opts[:controlli_non_vincolanti] = ctrl_nv

      # input_file deve esistere ed essere un file '.zip'
      @input_file = absolute_file_path(options[:input_file] || '')
      raise "Input file '#{@input_file}' non trovato per l'import" unless File.exist?(@input_file)

      case File.extname(@input_file)
      when /\.xls/i
        import_opts[:lista_file] << @input_file
        import_opts[:formato] = :xls_cella
      when /\.txt/i
        import_opts[:lista_file] << @input_file
        import_opts[:formato] = :text_cella
      when /(\.gz|\.zip)/i
        @unzip_dir = Irma.estrai_archivio(@input_file, suffix: 'import_pr')
        raise "Input file '#{@input_file}' non e' un file corretto" unless @unzip_dir
        import_opts[:lista_file] = Dir["#{@unzip_dir}/**/*.*"].select { |x| File.file?(x) }
        import_opts[:formato] = :text_cella
      else
        raise "Input file '#{@input_file}' non ha l'estensione corretta"
      end
      # --------------------------------------------------

      import_opts[:log_prefix] = "Import Progetto Radio per #{options[:omc_fisico] ? 'omc fisico' : 'sistema'} #{saa.full_descr} (id=#{saa.sistema_id})," +
      " numero file=#{import_opts[:lista_file].size}, account=#{saa.account.full_descr} expire=#{import_opts[:expire]}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) { saa.import_progetto_radio(import_opts) }
    ensure
      cleanup_temp_files
    end

    private

    def pre_import_progetto_radio
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
