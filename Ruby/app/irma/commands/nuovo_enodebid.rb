# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20170921
#

# import_adrn
require 'irma/db'

module Irma
  #
  class Command < Thor
    config.define NUOVO_ENODEBID_LOCK_EXPIRE = :nuovo_enodebid_lock_expire, 900,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di nuovo_enodebid',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :input_file,  type: :string, banner: 'File, full path o relative, contenente la lista degli enodeb_name da inserire in anagrafica'
    method_option :account_id,         type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'

    common_options 'nuovo_enodebid', "Esegue l'inserimento in anagrafica di tutti gli enodeb presenti nel file di input"
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def nuovo_enodebid
      start_time = Time.now
      Db.init(env: options[:env], logger: logger, load_models: true)

      res = {}

      @account = options[:account_id].to_i == -1 ? Db::Account.qualsiasi : Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      @input_file = absolute_file_path(options[:input_file] || '')
      raise "Input file '#{@input_file}' non trovato (#{options[:input_file]})" unless File.exist?(@input_file)

      opts_funzione = {
        attivita_id: options[:attivita_id],
        account_id:  @account.id,
        account:     @account,
        expire:      options[:lock_expire] || config[NUOVO_ENODEBID_LOCK_EXPIRE],
        logger:      logger,
        log_prefix:  'Inserimento nuovi enodeb:',
        input_file:  @input_file
      }
      res[:elaborazione] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: opts_funzione[:log_prefix]) { Funzioni::NuovoEnodebid.new(opts_funzione).esegui(opts_funzione) }
      res[:durata] = (Time.now - start_time).round(1)
      res
    ensure
      cleanup_temp_files
    end

    private

    def pre_nuovo_enodebid
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    #------------------------------------------------
  end
end
