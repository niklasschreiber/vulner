# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180219
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define IMPORT_FILTRO_FORMATO_UTENTE_LOCK_EXPIRE = :import_filtro_formato_utente_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di import formato utente',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :input_file, type: :string,  banner: 'Nome file zip di input'
    method_option :sistema_id, type: :string,  banner: "Sistemi per cui effettuare l'export" # stringa di numeri divisi da virgola "n,n,n"
    method_option :vendor_release_id, type: :string,  banner: "VendorRelease id"
    method_option :extra_filtro_me, type: :string,  banner: "Naming_path da considerare separati da #{ARRAY_VAL_SEP}", default: ''
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando', default: -1
    method_option :omc_fisico,  type: :boolean, banner: 'Attivazione export entità per Omc Fisco', default: false
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{IMPORT_FILTRO_FORMATO_UTENTE_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)

    common_options 'import_filtro_formato_utente', "Legge Esegue l'aggiornamento dell'archivio utilizzando i file in input"
    def import_filtro_formato_utente
      import_opts = { 
        attivita_id: options[:attivita_id],
        solo_header: true,
        expire:      options[:lock_expire] || config[IMPORT_FILTRO_FORMATO_UTENTE_LOCK_EXPIRE],
      }
      import_opts[:log_prefix] = "Import filtro formato utente, expire=#{import_opts[:expire]}"        

      is_fisico = options[:omc_fisico] ? true : false

      account = options[:account_id].to_i == -1 ? Db::Account.qualsiasi : Db::Account.find(id: options[:account_id])
      raise "Impossibile identificare account" unless account

      sistemi_id = if options[:sistema_id]
                     sistemi_id = (options[:sistema_id] || '').split(',')
                   elsif options[:vendor_release_id]
                     [(Db::Sistema.first(vendor_release_id: options[:vendor_release_id].to_i) || {})[:id]]
                   end
      raise "Impossibile identificare sistema con id in (#{options[:sistema_id]}) o con vendor_release_id #{options[:vendor_release_id]}" unless sistemi_id || sistemi_id.compact.empty?
      vr_list = vendor_releases_id_from_omc_list(sistemi_id, is_fisico)
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: sistemi_id.first.to_i, account: account.id, archivio: ARCHIVIO_RETE)

      import_opts[:metamodello] = MetaModello.meta_modello_merged(vendor_release_id_list: vr_list.flatten.uniq, is_fisico: is_fisico)
      import_opts.update(check_input_file_for_import(options[:input_file]))

      import_opts[:log_prefix] = "Import filtro formato utente, expire=#{import_opts[:expire]}"
      # Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) { saa.import_formato_utente(import_opts) }
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) do
        import_result = saa.import_formato_utente(import_opts)
        extra_filtro_me = options[:extra_filtro_me].to_s.split(ARRAY_VAL_SEP)
        import_result[:header_per_filtro].delete_if { |k, _v| !extra_filtro_me.include?(k) } unless extra_filtro_me.empty?
        import_result
      end
    ensure
      cleanup_temp_files
    end

    private

    def pre_import_filtro_formato_utente
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
