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
    config.define COMPLETA_ENODEB_LOCK_EXPIRE = :completa_enodeb_lock_expire, 600,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di completa enodeb',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:1800})'

    method_option :input_file,   type: :string,  banner: 'Nome file di input (txt o xls)'
    method_option :sistema_id,   type: :numeric, banner: 'Identificativo del sistema'
    method_option :omc_fisico,   type: :boolean, banner: 'Attivazione comando per Omc Fisco', default: false
    method_option :account_id,   type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,     type: :string,  banner: "Archivio di riferimento delle entita'", default: ARCHIVIO_RETE
    method_option :out_dir_root, type: :string,  banner: 'Cartella per file di Progetto Radio mofificato'
    method_option :lock_expire,  type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{COMPLETA_ENODEB_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)

    common_options 'completa_enodeb', "Dato un file Progetto Radio, aggiorna coerentemente anagrafica enodeb e il file stesso"
    def completa_enodeb
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: options[:sistema_id], account: options[:account_id], archivio: options[:archivio])

      # sistema_id deve essere LTE (se omc_fisico non ha senso il controllo)
      raise "Il sistema #{saa.sistema.full_descr} non e' un sistema LTE" if options[:omc_fisico] == false && saa.rete.nome != 'LTE'

      # out_dir_root
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_completa_enodeb')
      @tmp_out_dir = Irma.tmp_sub_dir('temp_completa_enodeb')
      res = { artifacts: [] }

      import_opts = { 
        attivita_id:          options[:attivita_id],
        stats:                true,
        expire:               options[:lock_expire] || config[COMPLETA_ENODEB_LOCK_EXPIRE],
        file_da_processare:   nil,
        out_file:             nil
      }

      # input_file deve esistere ed essere un file '.zip'
      @input_file = absolute_file_path(options[:input_file] || '')
      raise "Input file '#{@input_file}' non trovato per l'import" unless File.exist?(@input_file)

      import_opts[:out_file_name] = File.add_str_nome_file(File.basename(options[:input_file]), COMPLETA_ENODEB_FILE_OUT_SUFFIX)

      case File.extname(@input_file)
      when /\.xls/i
        import_opts[:file_da_processare] = @input_file
        import_opts[:formato] = FORMATO_EXPORT_XLS # :xls_cella
      when /\.txt/i
        import_opts[:file_da_processare] = @input_file
        import_opts[:formato] = FORMATO_EXPORT_TXT # :text_cella
      when /(\.gz|\.zip)/i
        @unzip_dir = Irma.estrai_archivio(@input_file, suffix: 'input_enodeb_pr')
        raise "Input file '#{@input_file}' non e' un file corretto" unless @unzip_dir
        lista_file = Dir["#{@unzip_dir}/**/*"].select { |x| File.file?(x) }
        raise "Il file di input #{@unzip_dir} deve essere un solo file e non uno zip di di piu' file." if lista_file.count != 1 
        import_opts[:file_da_processare] = lista_file[0]
        import_opts[:formato] = FORMATO_EXPORT_TXT # :text_cella
        import_opts[:out_file_name] = if File.extname(@input_file).match(/\.zip/i)
                                        File.add_str_nome_file(File.basename(import_opts[:file_da_processare]), COMPLETA_ENODEB_FILE_OUT_SUFFIX)
                                      else
                                        File.add_str_nome_file(File.basename(options[:input_file]).gsub(/.gz$/i, ''), COMPLETA_ENODEB_FILE_OUT_SUFFIX)
                                      end
      else
        raise "Input file '#{@input_file}' non ha l'estensione corretta"
      end
      import_opts[:out_dir] = @tmp_out_dir
      # --------------------------------------------------

      import_opts[:log_prefix] = "Completa_enodeb per #{options[:omc_fisico] ? 'omc fisico' : 'sistema'} #{saa.full_descr} (id=#{saa.sistema_id})," +
      " numero file=#{import_opts[:file_da_processare].size}, account=#{saa.account.full_descr} expire=#{import_opts[:expire]}"
      res[:elaborazione] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) { saa.completa_enodeb(import_opts) }
      sposta_file_prodotto_per_completa_enodeb(import_opts[:out_file_name], @tmp_out_dir, @out_dir_root, res)
      res
    ensure
      FileUtils.rm_rf(@tmp_out_dir) if @tmp_out_dir # pulizia file input temporanei
      cleanup_temp_files                            # pulizia file output temporanei
    end

    private

    def pre_completa_enodeb
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def sposta_file_prodotto_per_completa_enodeb(out_file_n, tmp_out_dir, out_dir, res)
      artifact = nil
      case File.extname(options[:input_file])
      when /(\.gz|\.zip)/i
        o_f = File.add_str_nome_file(File.basename(options[:input_file]), COMPLETA_ENODEB_FILE_OUT_SUFFIX).gsub(/.gz$/i, '.zip')
        `cd "#{tmp_out_dir}" && zip "#{o_f}" #{out_file_n} 2>&1`
        err = $CHILD_STATUS.exitstatus
        raise "Errore nella compressione del file #{out_file_n} (#{err})" unless err.zero?
        out_file = File.join(tmp_out_dir, o_f)
      else
        out_file = File.join(tmp_out_dir, out_file_n)
      end
      if File.exist?(out_file)
        artifact = out_file
        target_path = File.join(out_dir, File.basename(artifact))
        # move artifact into out_dir if absolute, otherwise on shared
        Pathname.new(out_dir).relative? ? shared_post_file(artifact, target_path) : FileUtils.mv(artifact, target_path)
        res[:artifacts] << [target_path, 'export_pr_enodeb']
      end
      artifact
    ensure
      FileUtils.rm_rf(tmp_out_dir) if tmp_out_dir
    end
  end
end
