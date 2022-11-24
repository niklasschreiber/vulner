# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20171121
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define AGGIORNA_ADRN_LOCK_EXPIRE = :aggiorna_adrn_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di aggiornamento adrn da segnalazioni',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :account_id,          type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :sistema_id,          type: :numeric, banner: 'Identificativo del sistema/omc_fisico a cui sono legate le segnalazioni da considerare'
    method_option :omc_fisico,          type: :boolean, banner: 'Segnalazioni per omc_fisico', default: nil
    method_option :vendor_release_id,   type: :numeric, banner: 'Identificativo vendor_release destinazione degli aggiornamenti adrn', default: nil
    method_option :out_dir_root,        type: :string,  banner: 'Cartella per cartelle file di result'
    method_option :filtro_segnalazioni, type: :string,  banner: 'Ulteriori filtri su segnalazioni da considerare ai fini dell\'aggiornamento adrn'
    method_option :lock_expire,         type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{AGGIORNA_ADRN_LOCK_EXPIRE})"
    method_option :env, aliases: '-e',  type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)

    common_options 'aggiorna_adrn', "Aggiorna adrn da segnalazioni"
    def aggiorna_adrn
      res = { artifacts: [] }

      # sistema / omc_fisico
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico] || false, id: options[:sistema_id], account: options[:account_id], archivio: ARCHIVIO_RETE)

      # Vendor Release
      vr = (options[:omc_fisico] ? Db::VendorReleaseFisico : Db::VendorRelease).first(id: vr_id = options[:vendor_release_id] || saa.vendor_release.id)
      raise "Non esiste vendor release #{options[:omc_fisico] ? 'fisico' : ''} con id '#{vr_id}'" unless vr

      # Dir output
      @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('output_aggiorna_adrn')
      @tmp_dir_root = Irma.tmp_sub_dir('temp_aggiorna_adrn')

      # Check filtro_segnalazioni
      filtro_opts = options[:filtro_segnalazioni].to_s.empty? ? {} : JSON.parse(options[:filtro_segnalazioni])
      filtro = filtro_opts.select { |k, _v| Db::Segnalazione.columns.include?(k) }

      function_opts = { 
        attivita_id:         options[:attivita_id],
        expire:              options[:lock_expire] || config[AGGIORNA_ADRN_LOCK_EXPIRE],
        filtro_segnalazioni: filtro,
        out_dir:             @tmp_dir_root,
        metamodello:         saa.sistema.metamodello,
        omc_fisico:          options[:omc_fisico],
        vendor_release:      vr
      }

      lp = "Aggiornamento adrn relativamente a segnalazioni di #{saa.sistema.full_descr},"
      lp += " su vendor release #{vr.full_descr}"
      lp += " expire=#{function_opts[:expire]}"
      function_opts[:log_prefix] = lp

      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: function_opts[:log_prefix]) do
        res[:elaborazione] = saa.esegui_aggiorna_adrn(function_opts)
      end
      sposta_file_result(@tmp_dir_root, @out_dir_root, res)
      res
    end

    private

    def pre_aggiorna_adrn
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def sposta_file_result(tmp_dir, out_dir, res)
      out_files = Dir["#{tmp_dir}/*"]
      return nil unless out_files.count > 0
      out_files.each do |il_file|
        il_file_basename = File.basename(il_file)
        artifact = File.join(tmp_dir, il_file_basename)
        target_path = File.join(out_dir, il_file_basename)
        Pathname.new(out_dir).relative? ? shared_post_file(artifact, target_path) : FileUtils.mv(artifact, target_path)
        (res[:artifacts] ||= []) << [target_path, 'export_aggiorna_adrn']
      end
      res[:artifacts]
    end
  end
end
