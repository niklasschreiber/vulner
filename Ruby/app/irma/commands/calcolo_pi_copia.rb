# vim: set fileencoding=utf-8
#
# Author       : R. Arcaro
#
# Creation date: 20180117
#

# calcolo_pi_copia
require 'irma/db' #

module Irma
  #
  class Command < Thor
    config.define CALCOLO_PI_COPIA_LOCK_EXPIRE = :calcolo_pi_copia_lock_expire, 1800,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di calcolo_pi_copia',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :env,            type: :string,  banner: 'Environment', aliases: '-e', default: Db.env, enum: %w(production development test)
    method_option :nome_pi_target, type: :string,  banner: 'Nome del progetto irma da creare'
    method_option :nome_pi_src,    type: :string,  banner: 'Nome del progetto irma sorgente da copiare'
    method_option :id_pi_sorgente, type: :numeric, banner: 'Id del progetto irma sorgente da copiare'
    method_option :account_id,     type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'

    method_option :omc_id,         type: :numeric, banner: 'Sistema/OmcFisico per cui effettuare il calcolo' # (id)
    method_option :omc_fisico,     type: :boolean, banner: 'Attivazione calcolo per Omc Fisico', default: false
    method_option :archivio,       type: :string,  banner: 'Archivio di riferimento delle entità'

    common_options 'calcolo_pi_copia', 'Esegue la copia del progetto irma sorgente'
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def calcolo_pi_copia
      Db.init(env: options[:env], logger: logger, load_models: true)

      @id_pi_sorgente = options[:id_pi_sorgente]
      @account = options[:account_id].to_i == -1 ? Db::Account.qualsiasi : Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      opts_funzione = {
        attivita_id:    options[:attivita_id],
        account_id:     options[:account_id],
        account:        @account,
        expire:         options[:lock_expire] || config[CALCOLO_PI_COPIA_LOCK_EXPIRE],
        logger:         logger,
        log_prefix:     'Copia progetto irma:',
        id_pi_sorgente: @id_pi_sorgente,
        omc_id:         options[:omc_id],
        archivio:       options[:archivio],
        nome_pi_target: options[:nome_pi_target],
        nome_pi_src:    options[:nome_pi_src]
      }
      res = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: opts_funzione[:log_prefix]) { Funzioni::CalcoloPiCopia.new(opts_funzione).esegui(opts_funzione) }
      res
    end

    private

    def pre_calcolo_pi_copia
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    #------------------------------------------------
  end
end
