# vim: set fileencoding=utf-8
#
# Author       : C. Pinali, S. Campestrini
#
# Creation date: 20171009
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define CREAZIONE_FDC_LOCK_EXPIRE = :creazione_fdc_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di creazione file di configurazione',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :account_id,         type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :out_dir_root,       type: :string,  banner: 'Cartella per cartelle file di configurazione'
    method_option :modalita_creazione, type: :string,  banner: 'Modalita\' creazione file di configurazione'
    method_option :formato_fdc,        type: :string,  banner: "Formato dati file di configurazione (default: #{FORMATO_AUDIT_IDL})", default: FORMATO_AUDIT_IDL
    method_option :label_nome_fdc,     type: :string,  banner: 'Label da utilizzare nei nome dei file FdC da produrre'
    #
    method_option :pi_id,              type: :numeric, banner: 'Identificativo Progetto Irma di riferimento per la creazione FdC'
    #
    method_option :input_file_canc,    type: :string,  banner: 'Nome file zip di input per cancellazione', default: nil
    method_option :flag_del_crt,       type: :boolean, banner: 'entita\' da cancellare e da modificare, vanno cancellate e ricreate', default: false
    method_option :canc_rel_adj,       type: :string, banner: 'Indicazioni su cancellazione relazioni di adiacenza'
    method_option :lock_expire,        type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{CREAZIONE_FDC_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    common_options 'creazione_fdc', "Crea file di configurazione"
    def creazione_fdc
      res = { artifacts: [] }

      # Fonti master e riferimento
      pi = Db::ProgettoIrma.first(id: options[:pi_id])
      raise "Progetto Irma (id: #{options[:pi_id]}) non valido" unless pi

      solo_delete = (pi.count_entita == 0)

      #in caso di solo_delete su PI_EMPTY_OMCFISICO, non posso determinare il sistema_id, quindi metamodello e vendor_instance puntano a quelli di Omc Fisico anzichè Sistema
      sis, metamodello, vendor_instance = nil
      if solo_delete && pi.omc_fisico_id
        sis = Db::OmcFisico.first(id: pi.omc_fisico_id)
        metamodello = sis.metamodello(per_fdc: true, per_export: false)
        vendor_instance = Vendor.instance(vendor: sis.vendor.nome, rete: nil)
      else
        sis_id = pi[:parametri_input]['sistema_id'] || pi.sistema_id
        sis = Db::Sistema.first(id: sis_id) if sis_id
        raise "Impossibile determinare il sistema logico da utilizzare per metamodello e vendor_release (sistema id: '#{sis_id}')" unless sis

        # metamodello
        metamodello = sis.metamodello(per_fdc: true, per_export: false)
        # come per il metamodello, la vendor_instance puo' e deve rimanere quella del sistema fintanto che il calcolo non sara' multi rete
        vendor_instance = Vendor.instance(vendor: sis.vendor.nome, rete: sis.rete_id)
      end

      @saa_master = pi.saa(account_id: pi.account_id || options[:account_id])
      raise "Progetto Irma (id: #{options[:pi_id]}). Impossibile eseguire creazione fdc perche' #{options[:formato_fdc]} non supportato" unless @saa_master.formati_audit.include?(options[:formato_fdc])

      tipo_sorgente = pi[:parametri_input]['tipo_sorgente']
      saa_rif = case tipo_sorgente
                when CALCOLO_SORGENTE_OMCLOGICO
                  Db::SistemaAmbienteArchivio.new(sistema: @saa_master.sistema.id, archivio: ARCHIVIO_RETE, account: options[:account_id])
                when CALCOLO_SORGENTE_OMCFISICO
                  x_id = @saa_master.is_a?(Db::SistemaAmbienteArchivio) ? @saa_master.sistema.omc_fisico_id : @saa_master.omc_fisico_id
                  Db::OmcFisicoAmbienteArchivio.new(omc_fisico: x_id, archivio: ARCHIVIO_RETE, account: options[:account_id])
                when CALCOLO_SORGENTE_PI
                  x = pi[:parametri_input]['sorgente']
                  raise "Sorgente Progetto Irma #{pi.nome} non identificabile (sorgente: #{x})" unless x && iidd = x.split(Db::EntitaPi::TABLE_NAME_SEP)[1]  
                  pi_sorgente = Db::ProgettoIrma.first(id: iidd.to_i)
                  raise "Sorgente Progetto Irma #{pi.nome} non esistente (sorgente pi.id: #{iidd})" unless pi_sorgente
                  pi_sorgente.saa
                else
                  raise "Tipo sorgente ProgettoIrma #{pi.nome} non corretta (tipo_sorgente: #{tipo_sorgente})"
                end

      # File di cancellazione
      # info_file_canc = { file_canc: nil, formato_file_canc: nil }
      info_file_canc = {}
      info_file_canc = check_input_file_canc(options[:input_file_canc]) if options[:input_file_canc]

      lista_fc = info_file_canc[:lista_file_canc]
      raise 'Nessuna operazione di creazione_fdc da eseguire' if (lista_fc.nil? || lista_fc.empty?) && solo_delete

      # Dir output
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_fdc')
      @tmp_dir_root = Irma.tmp_sub_dir('temp_fdc')

      # Modalita' creazione fdc
      # modo = options[:modalita_creazione] || vendor_instance.modalita_creazione_fdc || MODO_CREAZIONE_FDC_TUTTO_SEPARATO
      modo = options[:modalita_creazione] || MODO_CREAZIONE_FDC_TUTTO_SEPARATO

      # Label files
      @label_nome_file = options[:label_nome_fdc] || @saa_master.pi.nome

      fdc_opts = { 
        attivita_id:        options[:attivita_id],
        stats:              true,
        expire:             options[:lock_expire] || config[CREAZIONE_FDC_LOCK_EXPIRE],
        canc_rel_adj:       options[:canc_rel_adj].to_s.empty? ? nil : JSON.parse(options[:canc_rel_adj]),
        out_dir:            @tmp_dir_root,
        label_nome_file:    @label_nome_file,
        modo_creazione_fdc: modo,
        metamodello:        metamodello,
        formato_fdc:        options[:formato_fdc],
        flag_del_crt:       options[:flag_del_crt],
        saa_rif:            saa_rif,
        vendor_instance:    vendor_instance,
        solo_delete:        solo_delete
      }
      fdc_opts.update(info_file_canc) if options[:input_file_canc]

      lp = "Creazione FdC per #{@saa_master.full_descr},"
      lp += " fonte riferimento #{saa_rif.full_descr}"
      lp += " file cancellazione #{info_file_canc[:file_canc]}" if info_file_canc[:file_canc]
      lp += " account=#{@saa_master.account.full_descr} expire=#{fdc_opts[:expire]}"
      fdc_opts[:log_prefix] = lp

      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: fdc_opts[:log_prefix]) do
        res[:elaborazione] = @saa_master.esegui_creazione_fdc(fdc_opts)
      end
      comprimi_e_sposta_file_fdc(@tmp_dir_root, @out_dir_root, res)
      res
    end

    private

    def pre_creazione_fdc
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def comprimi_e_sposta_file_fdc(tmp_dir, out_dir, res)
      out_files = Dir["#{tmp_dir}/*"]
      nome_file_zip = "FDC-#{@label_nome_file}.zip"
      return nil unless out_files.count > 0
      `cd "#{tmp_dir}" && zip "#{nome_file_zip}" * 2>&1`
      err = $CHILD_STATUS.exitstatus
      raise "Errore nella compressione della directory #{tmp_dir} (#{err})" unless err.zero?

      artifact = File.join(tmp_dir, nome_file_zip)
      target_path = File.join(out_dir, nome_file_zip)
      Pathname.new(out_dir).relative? ? shared_post_file(artifact, target_path) : FileUtils.mv(artifact, target_path)
      (res[:artifacts] ||= []) << [target_path, 'export_fdc']
      artifact
    ensure
      FileUtils.rm_rf(tmp_dir) if tmp_dir
    end

    def check_input_file_canc(filename, suffix: 'import_fileconf_canc') # TODO: chiedere per suffisso...
      res = { lista_file_canc: [], formato_file_canc: nil }
      input_file = absolute_file_path(filename)
      raise "Input file '#{input_file}' non trovato per l'import (#{filename})" unless File.exist?(input_file)

      # input_file deve esistere ed essere un file '.zip' o '.xls'
      case File.extname(input_file)
      when /\.xls/i
        res[:lista_file_canc] << input_file
        res[:formato_file_canc] = :xls
      when /\.txt/i
        res[:lista_file_canc] << input_file
        res[:formato_file_canc] = :text
      when /(\.gz|\.zip)/i
        unzip_dir = Irma.estrai_archivio(input_file, suffix: 'import_fc')
        raise "Input file '#{input_file}' non e' un file corretto" unless unzip_dir
        res[:lista_file_canc]        = Dir["#{unzip_dir}/**/*.*"].select { |x| File.file?(x) }
        res[:formato_file_canc] = :text
      else
        raise "Input file '#{input_file}' non ha l'estensione corretta"
      end
      res
    end
  end
end
