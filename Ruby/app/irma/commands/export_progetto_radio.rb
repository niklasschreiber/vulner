# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180116
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define EXPORT_PROGETTO_RADIO_LOCK_EXPIRE = :export_progetto_radio_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di export progetto radio',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :sistemi,              type: :string,  banner: "Sistemi per cui effettuare l'export" # stringa di numeri divisi da virgola "n,n,n"
    method_option :export_totale,        type: :boolean, banner: 'Export di tutti i sistemi', default: false
    method_option :account_id,           type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,             type: :string,  banner: "Archivio di riferimento delle entita'", default: ARCHIVIO_RETE
    method_option :formato,              type: :string,  banner: 'Formato file generato', enum: Constant.values(:formato_export)
    method_option :data_aggiornamento,   type: :boolean, banner: 'Inclusione data aggiornamento', default: false
    method_option :out_dir_root,         type: :string,  banner: 'Cartella per file di Progetto Radio modificato'
    method_option :file_unico,           type: :boolean, banner: 'Dati esportati in un unico file', default: false
    method_option :lock_expire,          type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{EXPORT_PROGETTO_RADIO_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    common_options 'export_progetto_radio', "Esegue l'export progetto radio per i sistemi specificati"
    def export_progetto_radio
      Db.init(env: options[:env], logger: logger, load_models: true)
      
      # Check account
      @account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      # out_dir_root
      out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_export_prn')
      tmp_out_dir = Irma.tmp_sub_dir('temp_export_prn')
      res = { artifacts: [] }

      # Quali sistemi
      sistemi_ids = options[:export_totale] ? Db::Sistema.select_map(:id).join(',') : options[:sistemi]
      i_sistemi = sistemi_per_progetti_radio(sistemi: sistemi_ids) 
      raise "Nessun sistema valido per eseguire export progetto radio '#{sistemi_ids}'" if i_sistemi.empty?
      sistemi_descr = i_sistemi.map { |sss_id| Db::Sistema.first(id: sss_id).full_descr } 

      # Per il formato txt, file_unico non e' applicabile
      file_unico = (options[:formato] == FORMATO_EXPORT_TXT) ? false : options[:file_unico]

      export_opts = { 
        attivita_id:        options[:attivita_id],
        account_id:         options[:account_id],
        expire:             options[:lock_expire] || config[EXPORT_PROGETTO_RADIO_LOCK_EXPIRE],
        formato:            options[:formato],
        file_unico:         file_unico,
        data_aggiornamento: options[:data_aggiornamento],
        out_file:           nil
      }

      # Export prn
      export_opts[:sistemi] = i_sistemi 
      export_opts[:out_dir] = tmp_out_dir
      export_opts[:log_prefix] = "Export progetto radio per i sistemi #{sistemi_descr.join(',')} (id=(#{sistemi_ids})), account=#{@account.full_descr}"

      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: export_opts[:log_prefix]) do
        res[:export] = Irma::Funzioni::ExportProgettoRadio.new(export_opts).esegui(export_opts)
      end
      res[:artifacts] = sposta_file_export_prn(tmp_out_dir, out_dir_root)
      res
    ensure
      FileUtils.rm_rf(tmp_out_dir) if tmp_out_dir # pulizia file temporanei
    end

    private

    def pre_export_progetto_radio
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def sistemi_per_progetti_radio(sistemi:, check_competenza: false)
      sistemi_res = []
      # Check sistemi
      (sistemi || '').split(',').each do |sss|
        sssid = sss.to_i
        sistema = Db::Sistema.find(id: sssid)
        if sistema.nil?
          logger.warn("Sistema '#{sssid}' non valido per export progetto radio")
          next
        end
        if check_competenza && !@account.sistemi_di_competenza.include?(sssid)
          logger.warn("Il sistema #{sistema.full_descr} (#{sssid}) non è di competenza dell'account #{@account.id}")
          next
        end
        #pr = Db::ProgettoRadio.where(sistema_id: sssid)
        pr = Db::ProgettoRadio.where_sistema_id(sssid)
        (sistemi_res).push(sssid) if pr
      end
      sistemi_res
    end

    def sposta_file_export_prn(tmp_dir, out_dir)
      artifacts = nil
      out_files = Dir["#{tmp_dir}/*"]
      out_files.each do |out_file|
        next unless File.exist?(out_file)
        artifact = out_file
        target_path = File.join(out_dir, File.basename(artifact))
        # move artifact into out_dir if absolute, otherwise on shared
        Pathname.new(out_dir).relative? ? shared_post_file(artifact, target_path) : FileUtils.mv(artifact, target_path)
        (artifacts ||= []) << [target_path, 'export_prn']
      end
      artifacts
    ensure
      FileUtils.rm_rf(tmp_dir) if tmp_dir
    end
  end
end
 
