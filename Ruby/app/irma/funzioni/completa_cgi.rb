# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180911
#
require_relative 'segnalazioni_per_funzione'
require_relative 'completa_cgi/formatter'
require_relative 'completa_cgi/importer'

require 'set'

# rubocop:disable Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
module Irma
  #
  module Funzioni
    class CompletaCgi
      include SegnalazioniPerFunzione

      attr_reader :logger, :sistema_ambiente_archivio, :log_prefix, :out_file, :stats
      attr_reader :anagrafica_cgi
      attr_accessor :header_arr, :hdr_posizioni
      alias saa sistema_ambiente_archivio

      def initialize(sistema_ambiente_archivio:, **opts)
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @sistema_ambiente_archivio = sistema_ambiente_archivio
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Completa CGI(#{sistema_ambiente_archivio.full_descr})"
        @stats = nil
        @hdr_posizioni = {}
        @out_file = File.join(opts[:out_dir], opts[:out_file_name])
      end

      def carica_anagrafica_cgi
        @anagrafica_cgi = {}
        Db::AnagraficaCgi.where(rete_id: saa.rete_id).each do |aaa|
          @anagrafica_cgi[aaa.nome_cella] = { ci: aaa.ci, lac: aaa.lac }
        end
      end

      def nuova_segnalazione(tipo_segnalazione, opts = {})
        tipo_segnalazione += 1 if saa.pi && !TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
        super(tipo_segnalazione, opts)
      end

      def con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_ANAGRAFICA_CGI, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def con_formatter(type_export:, out_file:, &block)
        Formatter.get_formatter(type_export, out_file: out_file, logger: logger, log_prefix: log_prefix, &block)
      end

      def con_parser(type_export:, file_da_processare:, **opts, &block)
        Importer.get_importer(type_export, file_da_processare: file_da_processare, **opts, &block)
      end

      PR_CGI_CAMPI_OBBLIGATORI = [
        SISTEMA_ID_FIELD   = Irma::Vendor::PR_SISTEMA,
        OMCFISICO_ID_FIELD = Irma::Vendor::PR_OMC_FISICO,
        CELLA_FIELD        = Irma::Vendor::PR_CELLA,
        CGI_FIELD          = Irma::Vendor::PR_CGI
      ].freeze

      def analizza_header(linea_hdr)
        pezzi = linea_hdr.upcase.split(PR_SEP, -1)
        unless controllo_campi_obbligatori(pezzi)
          raise 'Campi obbligatori non presenti nell\'intestazione'
        end
        pezzi
      end

      def controllo_campi_obbligatori(hdr_array)
        PR_CGI_CAMPI_OBBLIGATORI.each do |campo|
          unless hdr_array.include?(campo)
            nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_CGI_DATI_CAMPI_OBBLIGATORI_HEAD, campo: campo)
            return false
          end
          @hdr_posizioni[campo] = hdr_array.index(campo)
        end
      end

      AZIONI = [
        SCARTO_LINEA        = 'linee_scartate'.freeze,
        LINEA_OK            = 'linee_no_modifiche'.freeze,
        LINEA_MODIFICA_FILE = 'linee_modificate'.freeze,
        LINEA_MODIFICA_ANAG = 'cgi_anagrafica_modificati'.freeze,
        LINEA_NUOVO_CGI     = 'cgi_anagrafica_creati'.freeze
      ].freeze

      #-----------------------------------------------------------------------------------------------
      def nuovo_cgi(nome_cella:, lac:, ci: nil, result: {}, linea_num:)
        ci_anag = nil
        begin
          ci_anag = Db::AnagraficaCgi.nuova_cella(nome_cella: nome_cella, lac: lac, ci: ci, enable_lock: false)
        rescue => _e
          ci_anag = Db::AnagraficaCgi.nuova_cella(nome_cella: nome_cella, lac: lac, ci: nil, enable_lock: false) if ci_anag.nil? && ci
          unless ci_anag
            nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_CGI_DATI_NO_NEW_CI,
                               linea_file: linea_num, nome_cella: nome_cella)
            raise "#{@log_prefix} Impossibile ottenere un nuovo ci per la cella '#{nome_cella}'"
          end
        end
        @anagrafica_cgi[nome_cella] = { ci: ci_anag, lac: lac }
        (result[:azioni] || []) << LINEA_NUOVO_CGI
      end

      def aggiorna_file(nome_cella:, new_cgi_pzs:, old_cgi_pzs:, result:, linea_num:)
        nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_CGI_DATI_MODIFICA_FILE,
                           linea_file: linea_num, nome_cella: nome_cella,
                           old_cgi: old_cgi_pzs.join(CGI_SEP),
                           new_cgi: new_cgi = new_cgi_pzs.join(CGI_SEP))
        result[:campi_da_scrivere][@hdr_posizioni[CGI_FIELD]] = new_cgi
        (result[:azioni] || []) << LINEA_MODIFICA_FILE
      end

      def aggiorna_anagrafica(nome_cella:, new_cgi_pzs:, old_cgi_pzs:, result:, linea_num:)
        new_lac = new_cgi_pzs[2]
        Db::AnagraficaCgi.first(nome_cella: nome_cella, rete_id: saa.rete_id).update(lac: new_lac)
        @anagrafica_cgi[nome_cella][:lac] = new_lac
        (result[:azioni] || []) << LINEA_MODIFICA_ANAG
        nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_CGI_DATI_MODIFICA_CGI,
                           linea_file: linea_num, nome_cella: nome_cella,
                           old_cgi: old_cgi_pzs.join(CGI_SEP),
                           new_cgi: new_cgi_pzs.join(CGI_SEP))
      end

      # linea_input = stringa con campi concatenati con separatore PR_SEP
      def processa_linea_input(linea_input:, linea_num:)
        result = { azioni: [], campi_da_scrivere: nil }
        linea_array = linea_input.split(PR_SEP, -1)

        # verifiche nome_cella
        m_cella = linea_array[@hdr_posizioni[CELLA_FIELD]].to_s.upcase

        unless Db::AnagraficaCgi.cella_ok?(m_cella)
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_CGI_DATI_NOME_CELLA_ERRATO,
                             linea_file: linea_num, nome_cella: m_cella)
          logger.warn("#{@log_prefix} Il campo CELLA '#{m_cella}' non e' avvalorato correttamente.")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end

        # check coerenza sistema/omc_fisico
        sf = linea_array[@hdr_posizioni[SISTEMA_ID_FIELD]]
        sc = saa.sistema.descr
        if sf != sc
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_CGI_DATI_COMPETENZA_OMC,
                             linea_file: linea_num, tipo_omc: 'Logico', omc_file: sf, omc_comp: sc)
          logger.warn("#{@log_prefix} Sistema non corrispondente: atteso #{sc}, trovato #{sf}")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end
        of = linea_array[@hdr_posizioni[OMCFISICO_ID_FIELD]]
        oc = saa.sistema.omc_fisico_completo.nome
        if of != oc
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_CGI_DATI_COMPETENZA_OMC,
                             linea_file: linea_num, tipo_omc: 'Fisico', omc_file: of, omc_comp: oc)
          logger.warn("#{@log_prefix} Omc non corrispondente: atteso #{oc}, trovato #{of}")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end

        # verifiche stringa 'cgi'
        m_cgi = linea_array[@hdr_posizioni[CGI_FIELD]].to_s
        m_mcc, m_mnc, m_lac, m_ci = m_cgi.split(CGI_SEP)

        # verifica valore lac nel file; se non corretto scarto riga con segnalazione di warning
        unless Db::AnagraficaCgi.lac_ok(m_lac)
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_CGI_DATI_LAC_ERRATO,
                             linea_file: linea_num, lac: m_lac)
          logger.warn("#{@log_prefix} Il valore LAC '#{m_lac}' nel campo CGI '#{m_cgi}' non e' corretto.")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end

        cella_anag = @anagrafica_cgi[m_cella]
        result[:campi_da_scrivere] = linea_array

        if m_ci
          # CGI completo
          # ---> Se la cella non e' presente in anagrafica la inserisco con lac_file e ci_file (se libero)
          nuovo_cgi(nome_cella: m_cella, lac: m_lac, ci: m_ci, result: result, linea_num: linea_num) unless cella_anag

          # ---> Se 'lac' diverso, aggiorno anagrafica
          if (old_lac = @anagrafica_cgi[m_cella][:lac]) != m_lac
            aggiorna_anagrafica(nome_cella: m_cella,
                                new_cgi_pzs: [m_mcc, m_mnc, m_lac, @anagrafica_cgi[m_cella][:ci]],
                                old_cgi_pzs: [m_mcc, m_mnc, old_lac, @anagrafica_cgi[m_cella][:ci]],
                                result: result, linea_num: linea_num)
          end
          # ---> Se 'ci' diverso, aggiorno file
          if (ci_anag = @anagrafica_cgi[m_cella][:ci]) != m_ci
            aggiorna_file(nome_cella: m_cella,
                          new_cgi_pzs: [m_mcc, m_mnc, m_lac, ci_anag],
                          old_cgi_pzs: [m_mcc, m_mnc, m_lac, m_ci],
                          result: result, linea_num: linea_num)
          end
        else
          # CGI NON completo
          # ---> Se la cella non e' presente in anagrafica la inserisco con m_lac
          nuovo_cgi(nome_cella: m_cella, lac: m_lac, result: result, linea_num: linea_num) unless cella_anag

          # ---> Riga nel file di output va aggiornato con il nuovo_ci (preso dall'anagrafica)
          aggiorna_file(nome_cella: m_cella,
                        new_cgi_pzs: [m_mcc, m_mnc, m_lac, @anagrafica_cgi[m_cella][:ci]],
                        old_cgi_pzs: [m_mcc, m_mnc, m_lac],
                        result: result, linea_num: linea_num)

          # ---> Se il lac in anagrafica risulta diverso da quello del file, va aggiornata l'anagrafica
          if (old_lac = @anagrafica_cgi[m_cella][:lac]) != m_lac
            aggiorna_anagrafica(nome_cella: m_cella,
                                new_cgi_pzs: [m_mcc, m_mnc, m_lac, @anagrafica_cgi[m_cella][:ci]],
                                old_cgi_pzs: [m_mcc, m_mnc, old_lac, @anagrafica_cgi[m_cella][:ci]],
                                result: result, linea_num: linea_num)
          end
        end
        result[:azioni] << LINEA_OK if result[:azioni].empty?
        result
      end

      #--------------------------------------------------------

      def esegui(file_da_processare:, step_info: 1_000, **opts)
        res = { totale: 0, linee_input_elaborate: 0, linee_scritte: 0,
                dettaglio: {}
        }
        AZIONI.each { |aaa| res[:dettaglio][aaa] = 0 }

        step_progresso = opts[:step_progresso] || 1_000
        funzione = Db::Funzione.get_by_pk(FUNZIONE_COMPLETA_CGI)
        con_lock(funzione: funzione.nome, account_id: saa.account_id, mode: LOCK_MODE_WRITE, **opts) do # |locks|
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: saa.filtro_segnalazioni, attivita_id: opts[:attivita_id]) do
            #-------------------------------------------------------------------------------------
            con_formatter(type_export: opts[:formato], out_file: out_file) do |formatter|
              Irma.gc
              carica_anagrafica_cgi
              con_parser(type_export: opts[:formato], file_da_processare: file_da_processare, **opts) do |parser|
                InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
                  begin
                    Db::AnagraficaCgi.db.transaction do
                      res[:parser] = parser.parse do |linea_input, linea_num|
                        if @hdr_posizioni.empty?
                          formatter.scrivi_header(campi_linea: analizza_header(linea_input))
                          next
                        end
                        ip.incr
                        # result = { azioni: [], campi_da_scrivere: [...]/nil }
                        result = processa_linea_input(linea_input: linea_input, linea_num: linea_num)
                        res[:linee_input_elaborate] += 1
                        result[:azioni].each { |aaa| res[:dettaglio][aaa] += 1 }
                        unless result[:azioni] == [SCARTO_LINEA]
                          res[:linee_scritte] += 1
                          formatter.scrivi_linea(campi_linea: result[:campi_da_scrivere])
                        end
                        res[:totale] += 1
                        segnalazione_esecuzione_in_corso("(elaborate #{res[:totale]} linee)") if step_progresso > 0 && ((res[:totale] % step_progresso) == 0)
                      end # parser
                    end # transaction
                  rescue => e
                    res[:eccezione] = "#{e}: #{e.message} - nella rescue di begin"
                    logger.error("#{@log_prefix} catturata eccezione (#{res})")
                    raise
                  end # begin
                end # InfoProgresso
              end # con_parser
            end # con_formatter
            segnalazione_esecuzione_in_corso("(elaborate #{res[:totale]} linee)")
            res
          end # con_segnalazioni
        end # saa_con_lock
        res
      end
    end
  end
  #
  module Db
    # extend class
    class SistemaAmbienteArchivio
      def completa_cgi(file_da_processare:, **opts)
        Funzioni::CompletaCgi.new(sistema_ambiente_archivio: self, **opts).esegui(file_da_processare: file_da_processare, **opts)
      end
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      def completa_cgi(file_da_processare:, **opts)
        Funzioni::CompletaCgi.new(sistema_ambiente_archivio: self, **opts).esegui(file_da_processare: file_da_processare, **opts)
      end
    end
  end
end
