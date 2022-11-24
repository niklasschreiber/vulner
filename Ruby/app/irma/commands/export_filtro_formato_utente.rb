# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180220
#

#
# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
module Irma
  #
  class Command < Thor
    config.define EXPORT_FILTRO_FORMATO_UTENTE_LOCK_EXPIRE = :export_filtro_formato_utente_lock_expire, 1800,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di export_formato_utente',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'
    method_option :account_id,       type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :out_dir_root,     type: :string,  banner: 'Cartella per cartelle file di export'
    method_option :dir_name_no_date, type: :boolean, banner: 'Cartella con o senza data di generazione nel nome', default: false
    method_option :sistemi,          type: :string,  banner: "Sistemi per cui effettuare l'export" # stringa di numeri divisi da virgola "n,n,n"
    method_option :lock_expire,      type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{EXPORT_FORMATO_UTENTE_LOCK_EXPIRE})"
    method_option :omc_fisico,       type: :boolean, banner: 'Attivazione export filtro per Omc Fisico', default: false
    method_option :formato,          type: :string,  banner: 'Formato file generato', default: 'txt', enum: Funzioni::ExportFormatoUtente::FORMATTERS
    method_option :filtro_metamodello, type: :string, banner: 'Filtro su meta_entita e relativi parametri'
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'
    common_options 'export_filtro_formato_utente', "Esegue l'export filtro in formato utente"
    def export_filtro_formato_utente
      @tmp_dir_root = nil
      Db.init(env: options[:env], logger: logger, load_models: true)

      # CONTROLLI
      # Check account
      @account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      # Check out_dir_root
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_export_fu')
      @tmp_dir_root = Irma.tmp_sub_dir('temp_export_fu')

      export_opts = {
        attivita_id:        options[:attivita_id],
        expire:             options[:lock_expire] || config[EXPORT_FILTRO_FORMATO_UTENTE_LOCK_EXPIRE],
        formato:            options[:formato],
        solo_header:        true,
        con_version:        false,
        # filtro_metamodello: options[:filtro_metamodello].to_s.empty? ? nil : JSON.parse(options[:filtro_metamodello]),
        log_prefix:         'Export formato utente per caricamento filtro',
        logger:             logger
      }

      is_fisico = options[:omc_fisico] ? true : false
      res = { artifacts: [] }
      sistemi_id = (options[:sistemi] || '').split(',')
      vr_list = vendor_releases_id_from_omc_list(sistemi_id, is_fisico)
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: sistemi_id.first.to_i, account: options[:account_id], archivio: ARCHIVIO_RETE)
      export_opts[:metamodello] = MetaModello.meta_modello_merged(vendor_release_id_list: vr_list.flatten.uniq, is_fisico: is_fisico)

      export_opts[:filtro_metamodello] = determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file],
                                                             filtro_mm: options[:filtro_metamodello])
      nome_out_dir = dir_name_export_formato_utente('export_filtro_metamodello', nil, options[:dir_name_no_date])
      tmp_out_dir = FileUtils.mkdir_p(File.join(@tmp_dir_root, nome_out_dir)).first
      export_opts[:out_dir] = tmp_out_dir

      res['filtro'] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: export_opts[:log_prefix]) { saa.export_formato_utente(export_opts) }
      comprimi_e_sposta_file_export_formato_utente(options[:formato], tmp_out_dir, @out_dir_root, res)
      res[RESULT_KEY_FILTRO_MM_FILE] = options[:filtro_metamodello_file] if options[:filtro_metamodello_file]
      res
    ensure
      FileUtils.rm_rf(@tmp_dir_root) if @tmp_dir_root
    end

    private

    def pre_export_filtro_formato_utente
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
