# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180627
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define IMPORT_METAPARAMETRI_UPDATE_ON_CREATE_LOCK_EXPIRE = :import_metaparametri_update_on_create_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di import metaparametri update on create',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :input_file,  type: :string,  banner: 'Nome file di input'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{IMPORT_METAPARAMETRI_UPDATE_ON_CREATE_LOCK_EXPIRE})"
    common_options 'import_metaparametri_update_on_create', "Esegue l'import dei metaparametri update on create utilizzando il file in input"
    
    def import_metaparametri_update_on_create
      expire = options[:lock_expire] || config[IMPORT_METAPARAMETRI_UPDATE_ON_CREATE_LOCK_EXPIRE],
      log_prefix = "Import metaparametri update on create, expire=#{expire}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: log_prefix) do 
        raise 'File per impostazione parametri update_on_create non trovato' unless File.exist?(options[:input_file])
        import_table_metaparametri_with_flag(options: options, table_mp: Db::MetaparametroUpdateOnCreate)
      end
    ensure
      cleanup_temp_files
    end

    private

    def pre_import_metaparametri_update_on_create
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
