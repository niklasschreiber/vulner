# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160210
#

#
# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
module Irma
  #
  class Command < Thor
    config.define PI_EXPORT_FORMATO_UTENTE_LOCK_EXPIRE = :pi_export_formato_utente_lock_expire, 1800,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di export_formato_utente',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'
    method_option :account_id,       type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,         type: :string,  banner: "Archivio di riferimento delle entita'"
    method_option :con_version,      type: :boolean, banner: 'Export del campo version dell\'entita', default: false
    method_option :out_dir_root,     type: :string,  banner: 'Cartella per cartelle file di export'
    method_option :dir_name_no_date, type: :boolean, banner: 'Cartella con o senza data di generazione nel nome', default: false
    method_option :lock_expire,      type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{EXPORT_FORMATO_UTENTE_LOCK_EXPIRE})"
    method_option :omc_fisico,       type: :boolean, banner: 'Attivazione export entità per Omc Fisco', default: false
    method_option :formato,          type: :string,  banner: 'Formato file generato', default: 'txt', enum: Funzioni::ExportFormatoUtente::FORMATTERS
    method_option :filtro_metamodello, type: :string, banner: 'Filtro su meta_entita e relativi parametri'
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'

    method_option :progetti_irma,      type: :string,  banner: "id di ProgettiIrma per cui effettuare l'export" # stringa di numeri divisi da virgola "n,n,n"

    common_options 'pi_export_formato_utente', "Esegue l'export entità in formato utente per i progetti irma specificati"
    def pi_export_formato_utente
      @tmp_dir_root = nil
      Db.init(env: options[:env], logger: logger, load_models: true)

      # CONTROLLI
      # Check account
      @account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      # Check out_dir_root
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_pi_export_fu')
      @tmp_dir_root = Irma.tmp_sub_dir('temp_pi_export_fu')

      @progetti_irma = options[:progetti_irma]

      res = { artifacts: [] }
      # 20180220: Viene esportato un solo ProgettoIrma.
      sss = (options[:progetti_irma] || '').split(',').first
      raise "Progetto Irma id='#{sss}' non valido per export formato utente" unless sss
      sssid = sss.to_i
      @progetto_irma = Db::ProgettoIrma.find(id: sssid)
      raise "Progetto Irma id='#{sssid}' non valido per export formato utente" if @progetto_irma.nil?
      "Il proggetto irma #{progetto_irma.nome} (#{sssid}) non e' di competenza dell'account #{@account.id}" unless @progetto_irma.account_id == @account.id
      @saa = @progetto_irma.saa
      raise "Nessun dato per il progetto irma #{@progetto_irma.nome} nell'archivio #{options[:archivio]} (ambiente #{@account.ambiente})" if @saa.dataset(use_pi: true).count == 0

      export_opts = {
        attivita_id:        options[:attivita_id],
        expire:             options[:lock_expire] || config[EXPORT_FORMATO_UTENTE_LOCK_EXPIRE],
        formato:            options[:formato],
        con_version:        options[:con_version],
        # filtro_metamodello: options[:filtro_metamodello].to_s.empty? ? nil : JSON.parse(options[:filtro_metamodello]),
        filtro_metamodello: determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file], filtro_mm: options[:filtro_metamodello]),
        logger:             logger,
        use_pi:             true
      }
      nome_out_dir = dir_name_export_formato_utente('export_fu', @progetto_irma.nome, options[:dir_name_no_date])
      tmp_out_dir = FileUtils.mkdir_p(File.join(@tmp_dir_root, nome_out_dir)).first
      export_opts[:metamodello] = @progetto_irma.metamodello(load_mp_solo_nome: true)

      export_opts[:log_prefix] = "Export formato utente per il progetto irma #{@progetto_irma.nome} (id=#{@progetto_irma.id}), account=#{@account.full_descr}"
      export_opts[:out_dir] = tmp_out_dir

      res[@progetto_irma.nome] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: export_opts[:log_prefix]) { @saa.export_formato_utente(export_opts) }
      comprimi_e_sposta_file_export_formato_utente(options[:formato], tmp_out_dir, @out_dir_root, res)
      res[RESULT_KEY_FILTRO_MM_FILE] = options[:filtro_metamodello_file] if options[:filtro_metamodello_file]
      res
    ensure
      FileUtils.rm_rf(@tmp_dir_root) if @tmp_dir_root
    end

    private

    def pre_pi_export_formato_utente
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
