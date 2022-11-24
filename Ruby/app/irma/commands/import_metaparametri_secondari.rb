# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20181026
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define IMPORT_METAPARAMETRI_SECONDARI = :import_metaparametri_secondari_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di import metaparametri secondari',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :input_file,  type: :string,  banner: 'Nome file di input'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{IMPORT_METAPARAMETRI_UPDATE_ON_CREATE_LOCK_EXPIRE})"
    common_options 'import_metaparametri_secondari', "Esegue l'import dei metaparametri secondari utilizzando il file in input"
    
    def import_metaparametri_secondari
      expire = options[:lock_expire] || config[IMPORT_METAPARAMETRI_SECONDARI],
      log_prefix = "Import metaparametri secondari, expire=#{expire}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: log_prefix) do 
        raise 'File per impostazione metaparametri secondari non trovato' unless File.exist?(options[:input_file])
        import_table_metaparametri_with_flag(options: options, table_mp: Db::MetaparametroSecondario)
      end
    ensure
      cleanup_temp_files
    end

    private

    def pre_import_metaparametri_secondari
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
 
