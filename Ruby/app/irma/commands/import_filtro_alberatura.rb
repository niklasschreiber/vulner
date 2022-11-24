# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180926
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define IMPORT_FILTRO_ALBERATURA_LOCK_EXPIRE = :import_filtro_alberatura_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di import filtro alberatura',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :input_file, type: :string,  banner: 'Nome file zip di input'
    method_option :filtro_me_mp, type: :string, banner: 'Filtro su meta_entita e relativi parametri'
    method_option :sistema_id, type: :string,  banner: "Sistemi per cui effettuare l'export" # stringa di numeri divisi da virgola "n,n,n"
    method_option :vendor_release_id, type: :string,  banner: "VendorRelease id"
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando', default: -1
    method_option :omc_fisico,  type: :boolean, banner: 'Attivazione export entità per Omc Fisco', default: false
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{IMPORT_FILTRO_ALBERATURA_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)

    common_options 'import_filtro_alberatura', "Legge file filtro alberatura in input"
    def import_filtro_alberatura
      import_opts = { 
        attivita_id: options[:attivita_id],
        solo_header: true,
        expire:      options[:lock_expire] || config[IMPORT_FILTRO_ALBERATURA_LOCK_EXPIRE],
      }
      import_opts[:log_prefix] = "Import filtro alberatura, expire=#{import_opts[:expire]}"        

      account = options[:account_id].to_i == -1 ? Db::Account.qualsiasi : Db::Account.find(id: options[:account_id])
      raise "Impossibile identificare account" unless account

      # --- Identificazione lista di vendor_release per metamodello_merged
      is_fisico = options[:omc_fisico] ? true : false
      sistemi_id = if options[:sistema_id]
                     sistemi_id = (options[:sistema_id] || '').split(',')
                   elsif options[:vendor_release_id]
                     [(Db::Sistema.first(vendor_release_id: options[:vendor_release_id].to_i) || {})[:id]]
                   end
      raise "Impossibile identificare sistema con id in (#{options[:sistema_id]}) o con vendor_release_id #{options[:vendor_release_id]}" unless sistemi_id || sistemi_id.compact.empty?
      vr_list = vendor_releases_id_from_omc_list(sistemi_id, is_fisico)

      import_opts[:metamodello] = MetaModello.meta_modello_merged(vendor_release_id_list: vr_list.flatten.uniq, is_fisico: is_fisico)
      # ---

      import_opts.update(check_input_file_for_import(options[:input_file]))

      import_opts[:log_prefix] = "Import filtro alberatura, expire=#{import_opts[:expire]}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) do
        import_result = Funzioni::ImportFiltroAlberatura.new(import_opts).esegui(import_opts)
        filtro_me_mp = options[:filtro_me_mp].to_s.empty? ? nil : JSON.parse(options[:filtro_me_mp])
        if filtro_me_mp
          # filtro su meta_entita
          import_result[:header_per_filtro].delete_if { |k, _v| !filtro_me_mp.keys.include?(k) }
          # filtro su meta_parametri
          import_result[:header_per_filtro].keys.each do |k|
            (import_result[:header_per_filtro][k] || {})[FILTRO_MM_PARAMETRI] = (filtro_me_mp[k] || {})[FILTRO_MM_PARAMETRI] || [META_PARAMETRO_ANY]
          end
        end
        import_result
      end
    ensure
      cleanup_temp_files
    end

    private

    def pre_import_filtro_alberatura
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
