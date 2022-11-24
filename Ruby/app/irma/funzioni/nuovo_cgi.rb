# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20170921
#

require_relative 'segnalazioni_per_funzione'

module Irma
  #
  module Funzioni
    #
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    #
    class NuovoCgi
      include SegnalazioniPerFunzione

      attr_reader :logger, :log_prefix

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'NuovoCgi: '
        @tmp_dir = opts[:tmp_dir]
      end

      def con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_ANAGRAFICA_CGI, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def processa_nuova_linea(linea_in, res)
        nome_cella, lac = linea_in.to_s.split(SEP_FILE_CGI)
        if nome_cella.to_s.empty? || lac.to_s.empty?
          nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_CGI_DATI_LINEA_INPUT_ERRATA, linea_input: linea_in)
          logger.info("#{@log_prefix} La riga input ('nome_cella,lac') '#{linea_in}' non e' corretta")
          res[:linee_input_errate] += 1
          return
        end
        x = Db::AnagraficaCgi.nuova_cella(nome_cella: nome_cella.to_s.upcase, lac: lac, enable_lock: false)
        res[:celle_inserite] += 1 if x
      rescue CellaGiaAnagrafataCgi
        nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_CGI_DATI_CELLA_GIA_ANAGRAFATA, nome_cella: nome_cella, lac: lac)
        logger.info("#{@log_prefix} La cella '#{nome_cella}' (lac '#{lac}') e' gia' anagrafata")
        res[:celle_gia_anagrafate] += 1
      rescue NomeCellaNonCorretto
        nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_CGI_DATI_NOME_CELLA_ERRATO, nome_cella: nome_cella)
        logger.warn("#{@log_prefix} Il nome cella '#{nome_cella}' non e' corretto.")
        res[:nomi_cella_errati] += 1
      rescue NomeCellaNoRegione
        nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_CGI_DATI_NOME_CELLA_NO_REGIONE, nome_cella: nome_cella)
        logger.warn("#{@log_prefix} Impossibile identificare la regione dal nome cella '#{nome_cella}'.")
        res[:nomi_cella_errati] += 1
      rescue ValoreLacNonCorretto
        nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_CGI_DATI_LAC_ERRATO, lac: lac)
        logger.warn("#{@log_prefix} Valore lac specificato ('#{lac}') non e' valido.")
        res[:lac_errati] += 1
      rescue => e
        nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_CGI_DATI_ERRORE_INSERIMENTO, lac: lac)
        logger.warn("#{@log_prefix} Errore nell'anagrafare la cella #{nome_cella}. #{e}")
        res[:errori] += 1
      end

      def esegui(**opts)
        in_file = opts[:input_file]
        res = { errori: 0, lac_errati: 0, linee_input_errate: 0, celle_inserite: 0, celle_gia_anagrafate: 0, nomi_cella_errati: 0 }
        funzione = Db::Funzione.get_by_pk(FUNZIONE_NUOVO_CGI)
        account = Db::Account.first(id: opts[:account_id])
        con_lock(funzione: funzione.nome, account_id: opts[:account_id], enable: opts.fetch(:lock, true), logger: logger, log_prefix: log_prefix, **opts) do |_locks|
          con_segnalazioni(funzione: funzione, account: account, attivita_id: opts[:attivita_id]) do
            logger.info "Inizio inserimento in anagrafica cgi di nuove celle da file #{in_file}"
            Db::AnagraficaCgi.db.transaction do
              begin
                last_line_processed = 0
                Irma.processa_file_per_linea(in_file, suffix: 'parse_txt') do |line, n|
                  line.chomp!
                  next if line.nil?
                  last_line_processed = n + 1
                  processa_nuova_linea(line, res)
                end
              rescue EsecuzioneScaduta
                raise
              rescue => e
                res[:eccezione] = "#{@log_prefix} catturata eccezione nella processazione della riga #{last_line_processed}: #{e}"
                logger.error("#{@log_prefix} catturata eccezione (#{res})")
                raise
              end # begin
            end # transaction
            logger.info "Terminato inserimento in anagrafica cgi di nuove celle dal file #{in_file}"
            res
          end # con_segnalazioni
        end # con_lock
        res
      end
      #------------------------------------------------
    end
  end
end
