# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160520
#

require 'singleton'
require 'concurrent'

module Irma
  #
  class ManagerSegnalazioni
    include Singleton

    DEFAULT_SLEEP_TIME = 1

    attr_writer :sleep_time

    def started?
      @thread ? true : false
    end

    def sleep_time
      @sleep_time || DEFAULT_SLEEP_TIME
    end

    def start # rubocop:disable Metrics/MethodLength
      return self if @thread
      @stop = false
      @segnalazioni_in_coda = Concurrent::Array.new
      @thread = Thread.new do
        Irma.logger.info('ManagerSegnalazioni, attivata la thread di processazione delle segnalazioni')
        until @stop
          sleep(sleep_time)
          while (segnalazione = @segnalazioni_in_coda.shift)
            begin
              crea_segnalazione(segnalazione)
            rescue => e
              Irma.logger.error("ManagerSegnalazioni, segnalazione non creata (#{segnalazione}): #{e}")
            end
          end
        end
        @thread = nil
      end
      self
    end

    def stop(stop_sleep_time: 1)
      @stop = true
      if @thread
        Irma.logger.info('ManagerSegnalazioni, terminazione della thread di processazione delle segnalazioni')
        sleep(stop_sleep_time)
        @thread.kill if @thread
        @thread = nil
      end
      self
    end

    def nuova_segnalazione(tipo_segnalazione, opts = {})
      segnalazione = [tipo_segnalazione, opts.dup]
      started? ? (@segnalazioni_in_coda << segnalazione) : crea_segnalazione(segnalazione)
      self
    end

    # private
    def crea_segnalazione(segnalazione)
      Db::Segnalazione.crea(*segnalazione)
    end
  end

  # rubocop:disable Metrics/LineLength
  module SegnalazioniPerFunzione
    def filtro_segnalazioni
      @filtro_segnalazioni || raise("Filtro segnalazioni non impostato per l'istanza #{self}")
    end

    def opzioni_segnalazioni
      filtro_segnalazioni.merge(account_desc: @account.full_descr, utente_id: @account.utente_id, account_id: @account.id, profilo_id: @account.profilo_id, attivita_id: @attivita_id)
    end

    def rimuovi_segnalazioni
      Db::Segnalazione.where(filtro_segnalazioni).delete
    end

    def conta_segnalazioni
      res = { totale: 0, ripartizione: {} }
      (@cs || {}).to_a.sort.reverse.each do |gravita, count|
        res[:totale] += count
        res[:ripartizione][Constant.label(:segnalazione, gravita, :gravita)] = count
      end
      res
    end

    def con_segnalazioni(funzione:, account:, filtro: nil, enable: true, rimuovi_precedenti: false, **opts, &_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/ParameterLists
      logger = opts[:logger] || Db::Segnalazione.logger
      @log_prefix ||= opts[:log_prefix] || self.class.to_s
      if enable
        @funzione = funzione.is_a?(Db::Funzione) ? funzione : Db::Funzione.get_by_pk(funzione)
        raise ArgumentError, "L'account per le segnalazioni non è valido (#{account})" unless account.is_a?(Db::Account) || (account.respond_to?(:id) && account.respond_to?(:full_descr))
        @account = account
        @filtro_segnalazioni = { funzione_id: @funzione.id }.merge(filtro || {})
        @data_inizio_segnalazioni = Time.now
        @attivita_id = opts[:attivita_id]
        @cs = Concurrent::Hash.new(0)
        if rimuovi_precedenti
          n = rimuovi_segnalazioni
          logger.info("#{@log_prefix}, rimosse #{n} segnalazioni precedenti")
        end
        nuova_segnalazione(TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_INIZIATA, progress: true)
        res = yield
        dettaglio = if opts[:chiavi_risultato_da_ignorare_nel_dettaglio] && res.is_a?(Hash)
                      res.reject { |k, _v| opts[:chiavi_risultato_da_ignorare_nel_dettaglio].include?(k) }.to_s
                    else
                      res.to_s
                    end
        nuova_segnalazione(TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_COMPLETATA, summary: (res.is_a?(Hash) && res[:summary]) ? " (#{res[:summary]})" : '', progress: true, dettaglio: dettaglio)
        res
      else
        res = yield
      end
    rescue => e
      logger.error("#{@log_prefix}, esecuzione terminata con eccezione (#{e})")
      nuova_segnalazione(e.is_a?(EsecuzioneScaduta) ? TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_TERMINATA_PER_TIMEOUT : TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_TERMINATA_CON_ERRORE, progress: true, dettaglio: e.to_s)
      raise
    ensure
      if enable && @filtro_segnalazioni
        cs = conta_segnalazioni
        res[:segnalazioni] = cs if res.is_a?(Hash)
        logger.info("#{@log_prefix}, generate #{cs[:totale]} segnalazioni (#{cs.to_json})")
      end
    end

    def nuova_segnalazione(tipo_segnalazione, opts = {}) # rubocop:disable Metrics/AbcSize
      return unless @filtro_segnalazioni
      @data_inizio_segnalazioni ||= Time.now
      ts = Db::TipoSegnalazione.get_by_pk(tipo_segnalazione)
      @cs ||= Concurrent::Hash.new(0)
      @cs[ts[:gravita]] += 1
      ManagerSegnalazioni.instance.nuova_segnalazione(tipo_segnalazione, opzioni_segnalazioni.merge(secondi_da_inizio_esecuzione: (Time.now - @data_inizio_segnalazioni).round(0).to_i).merge(opts))
    end

    def segnalazione_esecuzione_in_corso(progress, opts = {})
      nuova_segnalazione(TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_IN_CORSO, opts.merge(progress: progress))
    end
  end
end
