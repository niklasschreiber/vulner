# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160210
#

#
# rubocop:disable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
module Irma
  #
  class Command < Thor
    config.define EXPORT_REPORT_COMPARATIVO_LOCK_EXPIRE = :export_report_comparativo_lock_expire, 1800,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di export_report_comparativo',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'
    method_option :account_id,              type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,                type: :string,  banner: "Archivio di riferimento delle entita'"
    method_option :out_dir_root,            type: :string,  banner: 'Cartella per cartelle file di export'
    method_option :report_comparativo_nome, type: :string,  banner: "Report Comparativo nome per cui effettuare l'export"
    method_option :report_comparativo_id,   type: :numeric, banner: "Report Comparativo id per cui effettuare l'export"
    method_option :lock_expire,             type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{EXPORT_REPORT_COMPARATIVO_LOCK_EXPIRE})"
    method_option :formato,                 type: :string,  banner: 'Formato file generato', default: FORMATO_EXPORT_XLS, enum: Constant.values(:formato_export)
    method_option :tipo_export,             type: :string,  banner: 'Tipologia di export', default: TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE, enum: TIPI_EXPORT_REPORT_COMPARATIVO
    method_option :filtro_metamodello,      type: :string,  banner: 'Filtro su meta_entita e relativi parametri'
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'
    method_option :np_alberatura,           type: :string,  banner: 'Lista naming_path per conteggio alberatura'
    method_option :solo_calcolabili,        type: :boolean, banner: 'Vengono esportate solo entita di progettazione', default: false
    # -- flags...
    method_option :only_to_export_param,    type: :boolean, banner: 'Vengono esportati solo i parametri con is_to_export = true', default: true
    method_option :con_version,             type: :boolean, banner: 'Vanno esportate anche le differenze di version. Default: false', default: false
    method_option :dist_assente_vuoto,      type: :boolean, banner: 'Export di tutte le differenze tra valori dei parametri, anche quelle non significative', default: false
    method_option :nascondi_assente_f1,     type: :boolean, banner: 'Nascondi differenze quando parametro ASSENTE su fonte 1', default: false
    method_option :nascondi_assente_f2,     type: :boolean, banner: 'Nascondi differenze quando parametro ASSENTE su fonte 2', default: false
    method_option :filtro_version,          type: :string,  banner: 'Lista di valori version (divisi da virgola) le cui entita vanno ignorate', default: ''
    method_option :cc_mode,                 type: :boolean, banner: 'Vengono utilizzati i settaggi flag di consistency check', default: false
    method_option :solo_counters,           type: :boolean, banner: 'Non viene prodotto nessun file di export, ma solo restituiti i contatori dei parametri da scrivere', default: false
    method_option :solo_prioritari,         type: :boolean, banner: 'Vengono esportati solo i parametri con is_prioritario = true', default: false

    common_options 'export_report_comparativo', "Esegue l'export di un report comparativo"
    def export_report_comparativo
      @tmp_dir_root = nil
      Db.init(env: options[:env], logger: logger, load_models: true)

      export_opts = {
        attivita_id:           options[:attivita_id],
        expire:                options[:lock_expire] || config[EXPORT_REPORT_COMPARATIVO_LOCK_EXPIRE],
        solo_counters:         options[:solo_counters],
        np_alberatura:         options[:np_alberatura].to_s.empty? ? nil : JSON.parse(options[:np_alberatura]),
        solo_calcolabili:      options[:solo_calcolabili],
        solo_prioritari:       options[:solo_prioritari],
        logger:                logger
      }

      # ------
      # Check Account
      @account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      export_opts[:account_id] = options[:account_id]

      # ------
      # -- Check tipo export
      raise "La tipologia di export richiesta (#{options[:tipo_export]}) non e' tra quelle gestite" unless TIPI_EXPORT_REPORT_COMPARATIVO.include?(options[:tipo_export])
      export_opts[:tipo_export] = options[:tipo_export]

      # ------
      # Identifica ReportComparativo
      if options[:report_comparativo_id]
        @report_comparativo = Db::ReportComparativo.find(id: options[:report_comparativo_id])
      elsif options[:report_comparativo_nome]
        @report_comparativo = Db::ReportComparativo.find(nome: options[:report_comparativo_nome])
      else
        raise 'Specificare una delle opzioni report_comparativo_id, report_comparativo_nome'
      end
      # 20180126: In caso di report_comparativo vuoto si procede con l'export producendo dei file/directory vuoti
      # raise "Nessun dato per il report comparativo #{@report_comparativo.full_descr}" unless @report_comparativo.entita && @report_comparativo.entita.dataset.count > 0

      # ------
      # Identifica sistema/omc_fisico
      sist_id = @report_comparativo.sistema_id || (@report_comparativo.info && @report_comparativo.info['pi_sistema_id'])
      if sist_id
        @sistema = Db::Sistema.first(id: sist_id)
        export_opts[:omc_fisico] = false
      elsif @report_comparativo.omc_fisico_id
        @sistema = Db::OmcFisico.first(id: @report_comparativo.omc_fisico_id)
        export_opts[:omc_fisico] = true
      end
      tipo_omc = export_opts[:omc_fisico] ? 'omc_fisico' : 'sistema'
      tipo_omc_con_articolo = export_opts[:omc_fisico] ? 'l\'omc_fisico' : 'il sistema'
      msg_id = (@report_comparativo.sistema_id || @report_comparativo.omc_fisico_id).to_s
      raise "Il ReportComparativo con id '#{options[:report_comparativo]}' e' relativo ad un #{tipo_omc} (id #{msg_id}) inesistente" unless @sistema

      # Check competenza account <--> @sistema
      method = "#{export_opts[:omc_fisico] ? 'omc_fisici' : 'sistemi'}_di_competenza"
      unless @account.send(method).include?(@sistema.id)
        logger.warn("#{tipo_omc_con_articolo.camelize} #{@sistema.full_descr} (#{@sistema.id}) non è di competenza dell'account #{@account.id}")
      end

      @metamod = @sistema.metamodello
      export_opts[:metamodello] = @metamod
      export_opts[:log_prefix] = "Export report comparativo per #{tipo_omc_con_articolo} #{@sistema.full_descr} (id=#{@sistema.id}), account=#{@account.full_descr}"

      # ------
      # flags...
      if options[:cc_mode]
        raise "La modalita' consistency_check non e' consentita per report_comparativi di omc_fisico (#{@report_comparativo.full_descr})" if export_opts[:omc_fisico]
      end
      export_opts.merge!(export_rc_flags(cc_mode: options[:cc_mode], sistema: @sistema, vals: options))

      # ------
      # Determina filtro_metamodello

      # fm_temp_temp = if options[:filtro_metamodello_file]
      #                  fm_file = absolute_file_path(options[:filtro_metamodello_file])
      #                  raise "File '#{fm_file}' non trovato" unless File.exist?(fm_file)
      #                  ll = File.open(fm_file, 'r').gets
      #                  ll.chomp if ll
      #                else
      #                  options[:filtro_metamodello]
      #                end
      # fm_temp = (fm_temp_temp.to_s.empty? ? nil : JSON.parse(fm_temp_temp))
      # fm_temp = options[:filtro_metamodello].to_s.empty? ? nil : JSON.parse(options[:filtro_metamodello])
      # fm_temp = determina_filtro_mm(options[:filtro_metamodello_file], options[:filtro_metamodello])
      fm_temp = determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file],
                                    filtro_mm: options[:filtro_metamodello])
      fm_x = if fm_temp.nil? || fm_temp.empty?
               nil
             else
               fm_x = {}
               fm_temp.each do |me, mps|
                 fm_x[me] = {}
                 mps_e = (mps || {})[FILTRO_MM_ENTITA]
                 mps_p = (mps || {})[FILTRO_MM_PARAMETRI]
                 fm_x[me][FILTRO_MM_ENTITA] = mps_e if mps_e
                 fm_x[me][FILTRO_MM_PARAMETRI] = if mps_p == [META_PARAMETRO_ANY]
                                                   (@metamod.meta_parametri[me] || {}).keys
                                                 else
                                                   mps_p || []
                                                 end
               end
               fm_x
             end
      export_opts[:filtro_metamodello] = fm_x
      # ------
      # Determina out_dir_root
      unless export_opts[:solo_counters]
        @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_export_rc')
        @tmp_dir_root = Irma.tmp_sub_dir('temp_export_rc')

        # data_riferimento = Time.now
        data_riferimento = @report_comparativo.created_at
        data_rif_ymd = data_riferimento.strftime('%Y%m%d')

        nome_out_dir = dir_name_export_rc(sist_or_vend: @report_comparativo.nome.tr(' ', '_'), data_rif: data_riferimento)
        tmp_out_dir = FileUtils.mkdir_p(File.join(@tmp_dir_root, nome_out_dir)).first
        if options[:tipo_export] == TIPO_EXPORT_REPORT_COMPARATIVO_FU && export_opts[:formato] == FORMATO_EXPORT_TXT
          [1, 2].each do |idx|
            FileUtils.mkdir_p(File.join(tmp_out_dir, "#{NOME_SUBDIR_FONTE}#{idx}_#{data_rif_ymd}"))
            FileUtils.mkdir_p(File.join(tmp_out_dir, "#{NOME_SUBDIR_FONTE}#{idx}_#{data_rif_ymd}", "#{NOME_SUB_DIR_ENTITA}_#{data_rif_ymd}"))
            FileUtils.mkdir_p(File.join(tmp_out_dir, "#{NOME_SUBDIR_FONTE}#{idx}_#{data_rif_ymd}", "#{NOME_SUB_DIR_PARAMETRI}_#{data_rif_ymd}"))
          end
        end

        export_opts[:data_riferimento] = data_riferimento
        export_opts[:out_dir] = tmp_out_dir
      end
      res = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: export_opts[:log_prefix]) do
        xx = Funzioni::ExportReportComparativo.new(report_comparativo: @report_comparativo, **export_opts)
        xx.esegui(out_dir: export_opts[:out_dir], **export_opts)
      end
      comprimi_e_sposta_file_export_rc(export_opts[:formato], tmp_out_dir, @out_dir_root, res) unless export_opts[:solo_counters] || export_opts[:np_alberatura]
      sposta_file_cnt_alb(tmp_out_dir, @out_dir_root, res) if export_opts[:np_alberatura]
      res[RESULT_KEY_FILTRO_MM_FILE] = options[:filtro_metamodello_file] if options[:filtro_metamodello_file]
      res
    ensure
      FileUtils.rm_rf(@tmp_dir_root) if @tmp_dir_root
    end

    private

    def pre_export_report_comparativo
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def export_rc_flags(cc_mode:, sistema:, vals:)
      res = {}
      if cc_mode
        # res[:formato] = FORMATO_EXPORT_XLS
        res[:formato] = vals[:formato]
        #
        filtri_cc = sistema.filtri_consistency_check
        res[:con_version]          = false
        res[:dist_assente_vuoto]   = false
        res[:nascondi_assente_f1]  = false
        res[:nascondi_assente_f2]  = true
        res[:only_to_export_param] = true
        res[:filtro_version]       = (filtri_cc[:cc_filtro_release] || []).join(ARRAY_VAL_SEP).split_to_true_hash
        res[:filtro_cc_parametri]  = sistema_filtro_cc_parametri(filtri_cc[:cc_filtro_parametri], @sistema.metamodello)
      else
        [:formato, :con_version, :dist_assente_vuoto, :nascondi_assente_f1, :nascondi_assente_f2, :only_to_export_param].each do |ppp|
          res[ppp] = vals[ppp]
        end
        res[:filtro_version]       = vals[:filtro_version].to_s.split_to_true_hash
        res[:filtro_cc_parametri]  = {}
      end
      res
    end

    def sistema_filtro_cc_parametri(filtro_in, metamodello)
      fm_x = {}
      (filtro_in || {}).each do |me, mps|
        fm_x[me] = {}
        mps_p = (mps || {})[FILTRO_MM_PARAMETRI]
        fm_x[me][FILTRO_MM_PARAMETRI] = if mps_p == [META_PARAMETRO_ANY]
                                          (metamodello.meta_parametri[me] || {}).keys
                                        else
                                          mps_p || []
                                        end
      end
      fm_x
    end

    # comprime la dir tmp_out_dir e sposta lo zip in out_dir
    def comprimi_e_sposta_file_export_rc(formato, tmp_out_dir, out_dir, res)
      out_files = Dir["#{tmp_out_dir}/*"]
      tmp_zip_dir = nil
      if out_files.count > 0
        artifacts = if formato == FORMATO_EXPORT_TXT || formato == FORMATO_EXPORT_XLS
                      tmp_zip_dir = Irma.tmp_sub_dir('temp_export_rc_zip')
                      zip_file = "#{File.join(tmp_zip_dir, File.basename(tmp_out_dir))}.zip"
                      `cd "#{File.dirname(tmp_out_dir)}" && zip -r "#{zip_file}" #{File.basename(tmp_out_dir)} 2>&1`
                      err = $CHILD_STATUS.exitstatus
                      raise "Errore nella compressione della directory #{tmp_out_dir} (#{err})" unless err.zero?
                      FileUtils.rm_rf(tmp_out_dir)
                      [zip_file]
                    else
                      aaa = []
                      out_files.each do |of|
                        nuovo_nome_file = File.join(tmp_out_dir, File.basename(tmp_out_dir) + '_' + File.basename(of))
                        FileUtils.mv(of, nuovo_nome_file)
                        aaa << nuovo_nome_file
                      end
                      aaa
                    end
        artifacts.each do |artifact|
          target_path = File.join(out_dir, File.basename(artifact))
          Pathname.new(out_dir).relative? ? shared_post_file(artifact, target_path) : FileUtils.mv(artifact, target_path)
          (res[:artifacts] ||= []) << [target_path, 'export_rc']
        end
      end
      artifacts
    ensure
      FileUtils.rm_rf(tmp_zip_dir) if tmp_zip_dir
    end

    def sposta_file_cnt_alb(tmp_out_dir, out_dir, res)
      out_file = Dir["#{tmp_out_dir}/*"][0]
      return unless out_file
      nuovo_nome_file = File.join(tmp_out_dir, File.basename(tmp_out_dir) + '_' + File.basename(out_file))
      FileUtils.mv(out_file, nuovo_nome_file)
      target_path = File.join(out_dir, File.basename(nuovo_nome_file))
      Pathname.new(out_dir).relative? ? shared_post_file(nuovo_nome_file, target_path) : FileUtils.mv(nuovo_nome_file, target_path)
      res[CONTEGGIO_ALBERATURA_RC_KEYWORD] = target_path
      target_path
    end

    def dir_name_export_rc(sist_or_vend:, data_rif:)
      pp = ['export_rc']
      pp << (data_rif || Time.now).strftime('%Y%m%d%H%M')
      pp << sist_or_vend.to_s if sist_or_vend
      pp << 'FU' if  options[:tipo_export] == TIPO_EXPORT_REPORT_COMPARATIVO_FU
      pp.join('_')
    end
  end
end
