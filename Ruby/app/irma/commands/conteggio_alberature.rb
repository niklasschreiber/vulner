# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20181003
#

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
module Irma
  class Command < Thor
    config.define CONTEGGIO_ALBERATURE_LOCK_EXPIRE = :conteggio_alberature_lock_expire, 1800,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di conteggio_alberature',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'
    method_option :account_id,              type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :lista_rc_id,             type: :string,  banner: 'Id di ReportComparativi da analizzare' # stringa di numeri divisi da virgola "n,n,n"
    method_option :lista_rc_nome,           type: :string,  banner: 'Nomi di ReportComparativi da analizzare' # stringa di nomi report divisi da virgola
    method_option :np_alberatura,           type: :string,  banner: 'Lista naming_path per conteggio alberature'
    method_option :filtro_metamodello, type: :string, banner: 'Filtro su meta_entita e relativi parametri'
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'

    # option per output
    method_option :out_dir_root,            type: :string,  banner: 'Cartella per il file di conteggio alberature'
    method_option :out_file_conteggi,       type: :string,  banner: 'Nome del file di conteggio alberatura'
    method_option :genera_file_filtro,      type: :boolean, banner: 'Viene generato anche il file di filtro alberature', default: false
    method_option :out_file_filtro,         type: :string,  banner: 'Nome del file di conteggio alberature'
    common_options 'conteggio_alberature', 'Genera il file xlsx di conteggio alberature '
    def conteggio_alberature
      res = {}
      # Check account
      account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless account
      matricola = account.utente.matricola

      # Check np_alberatura
      np_alberatura = options[:np_alberatura].to_s.empty? ? nil : JSON.parse(options[:np_alberatura])
      raise 'Nessuna meta_entita specificata come root di alberatura' if np_alberatura.nil? || np_alberatura.empty?

      # Check (minimale) lista_rc_id
      ids = []
      if options[:lista_rc_id]
        ids = options[:lista_rc_id].to_s.split(',')
      elsif options[:lista_rc_nome]
        nomi = options[:lista_rc_nome].to_s.split(',')
        nomi.each do |nome|
          rc = Db::ReportComparativo.find(nome: nome)
          ids << rc.id.to_s if rc
        end
      else
        raise 'Specificare una delle opzioni lista_rc_id, lista_rc_nome'
      end

      raise "Lista report comparativi non valida #{options[:lista_rc_id]}" if ids.empty? || ids.map(&:numeric?).uniq != [true]

      funzione_opts = {
        attivita_id:           options[:attivita_id],
        logger:                logger,
        expire:                options[:lock_expire] || config[CONTEGGIO_ALBERATURE_LOCK_EXPIRE],
        lista_rc_id:           ids,
        np_alberatura:         np_alberatura,
        account_id:            account.id
      }

      fm_temp = determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file],
                                    filtro_mm: options[:filtro_metamodello])
      fm_x = if fm_temp.nil? || fm_temp.empty?
               nil
             else
               fm_temp
             end
      funzione_opts[:filtro_metamodello] = fm_x

      artifacts = []
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('conteggio_alberature')
      tmp_out_dir = Irma.tmp_sub_dir('temp_conteggio_alberature')

      # File di conteggio
      ref_date = Time.now.strftime('%Y%m%d-%H%M')
      @out_file = File.join(tmp_out_dir, options[:out_file] || "Conteggio_alberature_#{matricola}_#{ref_date}.xlsx")
      funzione_opts[:out_file] = @out_file
      if options[:genera_file_filtro]
        @out_file_filtro = File.join(tmp_out_dir, options[:out_file_filtro] || "Filtro_alberature_#{matricola}_#{ref_date}.xlsx")
        funzione_opts[:out_file_filtro] = @out_file_filtro
      end
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: "Conteggio alberature per report_comparativi #{options[:lista_rc_id]}") do
        res[:elaborazione] = Irma::Funzioni::ConteggioAlberature.new(funzione_opts).esegui(funzione_opts)
      end

      [@out_file, @out_file_filtro].compact.each do |o_file|
        next unless File.exist?(o_file)
        target_path = File.join(@out_dir_root, File.basename(o_file))
        Pathname.new(@out_dir_root).relative? ? shared_post_file(o_file, target_path) : FileUtils.mv(o_file, target_path)
        artifacts << [target_path, 'export_alberature']
      end

      res[:artifacts] = artifacts
      res[RESULT_KEY_FILTRO_MM_FILE] = options[:filtro_metamodello_file] if options[:filtro_metamodello_file]
      res
    ensure
      FileUtils.rm_rf(tmp_out_dir) if tmp_out_dir
    end

    private

    def pre_conteggio_alberature
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
