# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20190528
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define EXPORT_ADRN_SU_FILE_LOCK_EXPIRE = :export_adrn_su_file_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di export adrn su file',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :account_id,          type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :vendor_release_id,   type: :numeric, banner: 'Identificativo vendor_release', default: nil
    method_option :campi_m_entita,      type: :string,  banner: 'Campi di meta_entita da esportare'
    method_option :campi_m_parametro,   type: :string,  banner: 'Campi di meta_parametro da esportare'
    method_option :filtro_metamodello,  type: :string,  banner: 'Filtro su meta_entita e relativi parametri'
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'
    method_option :out_dir_root,        type: :string,  banner: 'Cartella per cartelle file di export'
    method_option :formato,             type: :string,  banner: 'Formato file generato', enum: Constant.values(:formato_export)
    method_option :lock_expire,         type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{EXPORT_ADRN_SU_FILE_LOCK_EXPIRE})"
    method_option :env, aliases: '-e',  type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)

    common_options 'export_adrn_su_file', "Export adrn su file"
    def export_adrn_su_file
      res = {}

      # Account
      account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless account

      # Vendor Release
      vr = Db::VendorRelease.first(id: options[:vendor_release_id] || -1)
      raise "Non esiste vendor release #{options[:omc_fisico] ? 'fisico' : ''} con id '#{options[:vendor_release_id]}'" unless vr

      # Check out_dir_root
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_export_adrn_file')
      @tmp_dir_root = Irma.tmp_sub_dir('temp_export_adrn')

      function_opts = { 
        attivita_id:    options[:attivita_id],
        account:        account,
        vendor_release: vr,
        out_dir:        @tmp_dir_root,
        formato:        options[:formato],
        expire:         options[:lock_expire] || config[EXPORT_ADRN_SU_FILE_LOCK_EXPIRE]
      }

      # Filtri campi metamodello
      function_opts[:campi_m_entita] = options[:campi_m_entita].to_s.empty? ? nil : JSON.parse(options[:campi_m_entita])
      function_opts[:campi_m_parametro] = options[:campi_m_parametro].to_s.empty? ? nil : JSON.parse(options[:campi_m_parametro])

      # Filtro metamodello
      fm_temp = determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file],
                                    filtro_mm: options[:filtro_metamodello])
      fm_x = if fm_temp.nil? || fm_temp.empty?
               nil
             else
               fm_temp
             end
      function_opts[:filtro_metamodello] = fm_x

      lp = "Export adrn,"
      lp += " per vendor release #{vr.full_descr}"
      lp += " expire=#{function_opts[:expire]}"
      function_opts[:log_prefix] = lp

      res = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: function_opts[:log_prefix]) do
        Funzioni::ExportAdrnSuFile.new(function_opts).esegui(function_opts)
      end
      sposta_file_export_adrn_su_file(@tmp_dir_root, @out_dir_root, res)
      res[RESULT_KEY_FILTRO_MM_FILE] = options[:filtro_metamodello_file] if options[:filtro_metamodello_file]
      res
    ensure
      FileUtils.rm_rf(@tmp_dir_root) if @tmp_dir_root
    end

    private

    def pre_export_adrn_su_file
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def sposta_file_export_adrn_su_file(tmp_dir, out_dir, res)
      artifact = nil
      out_file = Dir["#{tmp_dir}/*"].first
      if out_file && File.exist?(out_file)
        artifact = out_file
        target_path = File.join(out_dir, File.basename(artifact))
        Pathname.new(out_dir).relative? ? shared_post_file(artifact, target_path) : FileUtils.mv(artifact, target_path)
        (res[:artifacts] ||= []) << [target_path, 'export_adrn_su_file']
      end
      artifact
    ensure
      FileUtils.rm_rf(tmp_dir) if tmp_dir
    end
  end
end
