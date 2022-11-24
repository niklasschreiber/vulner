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
    class NuovoEnodebid
      include SegnalazioniPerFunzione

      attr_reader :logger, :log_prefix

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'NuovoEnodeb: '
        @tmp_dir = opts[:tmp_dir]
      end

      def con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_ANAGRAFICA_ENODEB, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def processa_nuova_linea(nome, id_nodeb, res)
        begin
          at = AnagraficaTerritoriale.at_di_provincia(AnagraficaTerritoriale.provincia_da_nome_cella(nome)).first
          nodo = Db::AnagraficaEnodeb.crea_nuovo_nodo(nome: nome, id_nodeb: id_nodeb, funzione_obj: self, area_territoriale: at,
                                                      tipo_segnalazione_no_at: TIPO_SEGNALAZIONE_NUOVO_ENODEBID_DATI_ENODEB_ID_NO_AT,
                                                      tipo_segnalazione_id_anagrafato: TIPO_SEGNALAZIONE_NUOVO_ENODEBID_DATI_ENODEB_ID_GIA_ANAGRAFATO)
          res[:enodeb_inseriti] += 1
        rescue EnodebGiaAnagrafato
          nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_ENODEBID_DATI_ENODEB_GIA_ANAGRAFATO, enodeb_name: nome)
          logger.info("#{@log_prefix} Il nodo '#{nome}' e' gia' anagrafato")
          res[:enodeb_gia_presenti] += 1
        rescue EnodebNameNonCorretto
          nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_ENODEBID_DATI_ENODEB_ERRATO, enodeb_name: nome)
          logger.warn("#{@log_prefix} Il nome nodo '#{nome}' non e' corretto.")
          res[:enodeb_errati] += 1
        rescue EnodebNameNoProvincia
          nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_ENODEBID_DATI_ENODEB_NO_PROVINCIA, enodeb_name: nome)
          logger.warn("#{@log_prefix} Al nome nodo '#{nome}' non corrisponde nessuna provincia.")
          res[:enodeb_errati] += 1
        rescue EnodebNameNoAreaTerritoriale
          nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_ENODEBID_DATI_ENODEB_NO_AT, enodeb_name: nome)
          logger.warn("#{@log_prefix} Al nome nodo '#{nome}' non corrisponde nessuna area territoriale.")
          res[:enodeb_errati] += 1
        rescue EnodebNoIdLiberi
          nuova_segnalazione(TIPO_SEGNALAZIONE_NUOVO_ENODEBID_DATI_ENODEB_NO_ID_LIBERI, area_territoriale: at)
          logger.warn("#{@log_prefix} Nessun identificativo libero per l'area territoriale '#{at}'.")
          res[:enodeb_errati] += 1
        end
        nodo
      end

      def esegui(**opts)
        in_file = opts[:input_file]
        res = { enodeb_inseriti: 0, enodeb_gia_presenti: 0, enodeb_errati: 0 }
        funzione = Db::Funzione.get_by_pk(FUNZIONE_NUOVO_ENODEBID)
        account = Db::Account.first(id: opts[:account_id])
        con_lock(funzione: funzione.nome, account_id: opts[:account_id], enable: opts.fetch(:lock, true), logger: logger, log_prefix: log_prefix, **opts) do |_locks|
          con_segnalazioni(funzione: funzione, account: account, attivita_id: opts[:attivita_id]) do
            logger.info "Inizio inserimento in anagrafica di nuovi enodeb da file #{in_file}"
            Db::AnagraficaEnodeb.db.transaction do
              begin
                last_line_processed = 0
                Irma.processa_file_per_linea(in_file, suffix: 'parse_txt') do |line, n|
                  array_line = line.split.map { |el| el.gsub('\n', '') }
                  next if array_line.empty?
                  last_line_processed = n + 1
                  processa_nuova_linea(array_line[0].upcase, array_line[1] ? array_line[1] : nil, res)
                end
              rescue EsecuzioneScaduta
                raise
              rescue => e
                res[:eccezione] = "#{@log_prefix} catturata eccezione nella processazione della riga #{last_line_processed}: #{e}"
                logger.error("#{@log_prefix} catturata eccezione (#{res})")
                raise
              end # begin
            end # transaction
            logger.info "Terminato inserimento in anagrafica di nuovi enodeb dal file #{in_file}"
            res
          end # con_segnalazioni
        end # con_lock
        res
      end
      #------------------------------------------------
    end
  end
end
