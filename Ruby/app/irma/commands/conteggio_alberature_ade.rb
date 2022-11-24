# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20190205
#

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
module Irma
  class Command < Thor
    config.define CONTEGGIO_ALBERATURE_ADE_LOCK_EXPIRE = :conteggio_alberature_ade_lock_expire, 1800,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di conteggio_alberature_ade',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'
    method_option :account_id,          type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :sistemi_id,          type: :string,  banner: 'Sistemi per cui effettuare l\'export AdE' # stringa di numeri divisi da virgola "n,n,n"
    method_option :np_alberatura,       type: :string,  banner: 'Lista naming_path per conteggio alberature'
    method_option :filtro_metamodello, type: :string, banner: 'Filtro su meta_entita e relativi parametri'
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'
    # option per output
    method_option :out_dir_root,        type: :string,  banner: 'Cartella per il file di conteggio alberature'
    method_option :out_file_conteggi,   type: :string,  banner: 'Nome del file di conteggio alberatura'
    method_option :etichette_nette,     type: :numeric, banner: '1: solo etichette nette, 2: solo etichette non nette, 3: tutte'
    method_option :etichette_eccezioni, type: :string,  banner: 'Lista etichette da considerare' # array di labels (stringhe)

    common_options 'conteggio_alberature_ade', 'Genera il file xlsx di conteggio alberature AdE'
    def conteggio_alberature_ade
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
      options[:sistemi_id].to_s.split(',').each do |s_id|
        ss = Db::Sistema.find(id: s_id)
        ids << ss.id.to_s if ss
      end
      raise "Lista sistemi non valida #{options[:lista_rc_id]}" if ids.empty? || ids.map(&:numeric?).uniq != [true]

      funzione_opts = {
        account_id:          account.id,
        attivita_id:         options[:attivita_id],
        logger:              logger,
        expire:              options[:lock_expire] || config[CONTEGGIO_ALBERATURE_ADE_LOCK_EXPIRE],
        lista_sistemi_id:    ids,
        np_alberatura:       np_alberatura,
        # filtro_metamodello:  options[:filtro_metamodello].to_s.empty? ? nil : JSON.parse(options[:filtro_metamodello]),
        etichette_nette:     options[:etichette_nette],
        etichette_eccezioni: options[:etichette_eccezioni].to_s.empty? ? [] : JSON.parse(options[:etichette_eccezioni])
      }

      funzione_opts[:filtro_metamodello] = determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file],
                                                               filtro_mm: options[:filtro_metamodello])

      artifacts = []
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('conteggio_alberature_ade')
      tmp_out_dir = Irma.tmp_sub_dir('temp_conteggio_alberature_ade')

      # File di conteggio
      ref_date = Time.now.strftime('%Y%m%d-%H%M')
      @out_file = File.join(tmp_out_dir, options[:out_file] || "Conteggio_alberature_ade_#{matricola}_#{ref_date}.xlsx")
      funzione_opts[:out_file] = @out_file
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: "Conteggio alberature per AdE dei sistemi #{options[:lista_sistemi_id]}") do
        res[:elaborazione] = Irma::Funzioni::ConteggioAlberatureAde.new(funzione_opts).esegui(funzione_opts)
      end

      [@out_file].compact.each do |o_file|
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

    def pre_conteggio_alberature_ade
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
