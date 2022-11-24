# vim: set fileencoding=utf-8
#
# Author       : R. Arcaro
#
# Creation date: 20180117
#

require_relative 'segnalazioni_per_funzione'

module Irma
  #
  module Funzioni
    #
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    #
    class CalcoloPiCopia
      include SegnalazioniPerFunzione

      attr_reader :logger, :log_prefix

      def initialize(**opts) # def initialize(sistema_ambiente_archivio, **opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'Copia progetto irma'
      end

      def esegui(**opts)
        id_pi_sorgente = opts[:id_pi_sorgente]
        nome_pi_src = opts[:nome_pi_src]
        nome_pi_target = opts[:nome_pi_target]
        res = {}
        funzione = Db::Funzione.get_by_pk(FUNZIONE_PI_CALCOLO_COPIA)
        account = Db::Account.first(id: opts[:account_id])
        pi_to_copy = Db::ProgettoIrma.get_by_pk(id_pi_sorgente)
        pi_to_copy.entita.con_lock(**opts) do |_locks|
          con_segnalazioni(funzione: funzione, account: account, attivita_id: opts[:attivita_id]) do
            logger.info "Inizio copia progetto irma sorgente #{nome_pi_src}"
            begin
              pi_copy = pi_to_copy.copia(nome: nome_pi_target, account_id: account.id)
              res[:nome_pi_creato] = pi_copy.nome
            rescue => e
              res[:eccezione] = "#{e}: #{e.message}"
              logger.error("#{@log_prefix} catturata eccezione (#{res})")
              raise
            end
            logger.info "Terminata copia progetto irma target #{nome_pi_target}"
            res
          end # con_segnalazioni
        end # con_lock
        res
      end
      #------------------------------------------------
    end
  end
end
