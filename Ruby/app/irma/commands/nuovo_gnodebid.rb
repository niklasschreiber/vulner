# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190402
#

module Irma
  #
  class Command < Thor
    config.define NUOVO_GNODEBID_LOCK_EXPIRE = :nuovo_gnodebid_lock_expire, 900,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di nuovo_gnodebid',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :input_file,  type: :string,  banner: 'File, full path o relative, contenente la lista dei gnodeb_name da inserire in anagrafica'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{NUOVO_GNODEBID_LOCK_EXPIRE})"
    common_options 'nuovo_gnodebid', "Esegue l'inserimento in anagrafica di tutti i gnodeb presenti nel file di input"

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def nuovo_gnodebid
      res = {}
      account = options[:account_id].to_i == -1 ? Db::Account.qualsiasi : Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless account

      input_file = absolute_file_path(options[:input_file] || '')
      raise "Input file '#{input_file}' non trovato (#{options[:input_file]})" unless File.exist?(input_file)

      opts_funzione = {
        attivita_id: options[:attivita_id],
        account_id:  account.id,
        account:     account,
        expire:      (expire = options[:lock_expire] || config[NUOVO_GNODEBID_LOCK_EXPIRE]),
        logger:      logger,
        log_prefix:  "Inserimento nuovi gnodeb (expire=#{expire}):",
        input_file:  input_file
      }
      res[:elaborazione] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: opts_funzione[:log_prefix]) { Funzioni::NuovoGnodebid.new(opts_funzione).esegui(opts_funzione) }
      res
    ensure
      cleanup_temp_files
    end

    private

    def pre_nuovo_gnodebid
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
