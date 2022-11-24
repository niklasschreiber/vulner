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
    config.define EXPORT_FORMATO_UTENTE_LOCK_EXPIRE = :export_formato_utente_lock_expire, 1800,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di export_formato_utente',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'
    method_option :account_id,       type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,         type: :string,  banner: "Archivio di riferimento delle entita'"
    method_option :out_dir_root,     type: :string,  banner: 'Cartella per cartelle file di export'
    method_option :dir_name_no_date, type: :boolean, banner: 'Cartella con o senza data di generazione nel nome', default: false
    method_option :sistemi,          type: :string,  banner: "Sistemi per cui effettuare l'export" # stringa di numeri divisi da virgola "n,n,n"
    method_option :lock_expire,      type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{EXPORT_FORMATO_UTENTE_LOCK_EXPIRE})"
    method_option :omc_fisico,       type: :boolean, banner: 'Attivazione export entità per Omc Fisco', default: false
    method_option :formato,          type: :string,  banner: 'Formato file generato', default: 'txt', enum: Funzioni::ExportFormatoUtente::FORMATTERS
    method_option :con_version,      type: :boolean, banner: 'Export del campo version dell\'entita', default: false
    method_option :filtro_metamodello, type: :string, banner: 'Filtro su meta_entita e relativi parametri'
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'
    method_option :etichette_nette, type: :numeric, banner: '1: solo etichette nette, 2: solo etichette non nette, 3: tutte'
    method_option :etichette_eccezioni, type: :string, banner: 'Lista etichette da considerare' # array di labels (stringhe)
    method_option :indice_etichette, type: :boolean, banner: 'Creazione foglio indice etichette', default: false
    common_options 'export_formato_utente', "Esegue l'export entità in formato utente per i sistemi specificati"
    def export_formato_utente
      @tmp_dir_root = nil
      Db.init(env: options[:env], logger: logger, load_models: true)

      # CONTROLLI
      # Check account
      @account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      # Check out_dir_root
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_export_fu')
      @tmp_dir_root = Irma.tmp_sub_dir('temp_export_fu')

      @archivio = options[:archivio]

      export_opts = {
        attivita_id:         options[:attivita_id],
        expire:              options[:lock_expire] || config[EXPORT_FORMATO_UTENTE_LOCK_EXPIRE],
        formato:             options[:formato],
        solo_header:         false,
        con_version:         options[:con_version],
        # filtro_metamodello:  options[:filtro_metamodello].to_s.empty? ? nil : JSON.parse(options[:filtro_metamodello]),
        etichette_eccezioni: options[:etichette_eccezioni].to_s.empty? ? [] : JSON.parse(options[:etichette_eccezioni]),
        etichette_nette:     options[:etichette_nette],
        indice_etichette:    options[:indice_etichette],
        logger:              logger
      }

      @sistemi = options[:sistemi]

      res = { artifacts: [] }
      gli_omc = check_lista_omc(options[:omc_fisico], res)
      meta_modello = {}
      # Ogni omc viene esportato in un file(xls)/directory(txt) distinto
      gli_omc.each do |oaa|
        omc_obj = oaa.sistema
        nome_out_dir = dir_name_export_formato_utente('export_fu', omc_obj.str_descr, options[:dir_name_no_date])
        tmp_out_dir = FileUtils.mkdir_p(File.join(@tmp_dir_root, nome_out_dir)).first
        export_opts[:out_dir] = tmp_out_dir
        if options[:omc_fisico]
          export_opts[:metamodello] = omc_obj.metamodello
        else
          meta_modello[omc_obj.vendor_release_id] ||= omc_obj.metamodello
          export_opts[:metamodello] = meta_modello[omc_obj.vendor_release_id]
        end
        export_opts[:log_prefix] = "Export formato utente per l'Omc #{options[:omc_fisico] ? 'Fisico' : 'Logico'} #{omc_obj.full_descr} (id=#{omc_obj.id}), account=#{@account.full_descr}"
        export_opts[:filtro_metamodello] = determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file],
                                                               filtro_mm:      options[:filtro_metamodello])
        res[omc_obj.full_descr] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: export_opts[:log_prefix]) { oaa.export_formato_utente(export_opts) }
        comprimi_e_sposta_file_export_formato_utente(options[:formato], tmp_out_dir, @out_dir_root, res)
      end
      res[RESULT_KEY_FILTRO_MM_FILE] = options[:filtro_metamodello_file] if options[:filtro_metamodello_file]
      res
    ensure
      FileUtils.rm_rf(@tmp_dir_root) if @tmp_dir_root
    end

    private

    def pre_export_formato_utente
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def check_lista_omc(omc_fisico, res)
      omc_ignorati = {} # omc_non_presenti: [], omc_non_di_competenza: [], omc_senza_dati: [] }
      lista_omc = []
      (@sistemi || '').split(',').each do |sss|
        sssid = sss.to_i
        sistema = (omc_fisico ? Db::OmcFisico : Db::Sistema).find(id: sssid)
        if sistema.nil?
          logger.warn("Omc #{omc_fisico ? 'Fisico' : 'Logico'} '#{sssid}' non valido per export formato utente")
          (omc_ignorati[:omc_non_presenti] ||= []) << "id: #{sssid}"
          next
        end
        unless omc_fisico ? @account.omc_fisici_di_competenza.include?(sssid) : @account.sistemi_di_competenza.include?(sssid)
          logger.warn("Omc #{omc_fisico ? 'Fisico' : 'Logico'} #{sistema.full_descr} (#{sssid}) non è di competenza dell'account #{@account.id}")
          (omc_ignorati[:omc_non_di_competenza] ||= []) << "#{sistema.full_descr} (id: #{sssid})"
          next
        end
        oaa = Db.saa_instance(omc_fisico: omc_fisico, id: sssid, account: @account, archivio: @archivio)
        if oaa.dataset.count == 0
          (omc_ignorati[:omc_archivio_vuoto] ||= []) << "#{sistema.full_descr} (id: #{sssid})"
          logger.warn("Nessun dato per l'omc #{sistema.full_descr} nell'archivio #{@archivio} (ambiente #{@account.ambiente})")
          next
        end
        lista_omc << oaa
      end
      if omc_ignorati.values.flatten.count > 0
        # trucco per forzare simbolo di warning su esecuzione attivita
        res[TERMINATA_WARNING] = omc_ignorati
        logger.warn("Nessun omc valido per eseguire export formato utente (omc id: '#{@sistemi}')")
      end
      lista_omc
    end
  end
end
