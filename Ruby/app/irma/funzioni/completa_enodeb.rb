# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20161114
#
require_relative 'segnalazioni_per_funzione'
require_relative 'completa_enodeb/formatter'
require_relative 'completa_enodeb/importer'

require 'set'

# rubocop:disable Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
module Irma
  #
  module Funzioni
    class CompletaEnodeb
      include SegnalazioniPerFunzione

      attr_reader :logger, :sistema_ambiente_archivio, :log_prefix, :out_file, :stats
      attr_accessor :header_arr, :hdr_posizioni
      alias saa sistema_ambiente_archivio

      def initialize(sistema_ambiente_archivio:, **opts)
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @sistema_ambiente_archivio = sistema_ambiente_archivio
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Completa ENODEB(#{sistema_ambiente_archivio.full_descr})"
        @stats = nil
        @hdr_posizioni = {}
        @out_file = File.join(opts[:out_dir], opts[:out_file_name])
      end

      def carica_anagrafica_enodeb
        @province_per_saa = saa.sistema.province
        aree_territoriali_per_saa = []
        @province_per_saa.each { |ppp| aree_territoriali_per_saa |= AnagraficaTerritoriale.at_di_provincia(ppp) }
        @anagrafica_enodeb = {}
        aree_territoriali_per_saa.each do |at|
          @anagrafica_enodeb[at] = {}
          @anagrafica_enodeb[at][:id_liberi] = Db::AnagraficaEnodeb.free_ids(at)
          @anagrafica_enodeb[at][:dati] = {}
          Db::AnagraficaEnodeb.where(area_territoriale: at).all.each do |aaa|
            @anagrafica_enodeb[at][:dati][aaa.enodeb_name] = aaa.enodeb_id
          end
        end
      end

      def nuova_segnalazione(tipo_segnalazione, opts = {})
        tipo_segnalazione += 1 if saa.pi && !TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
        super(tipo_segnalazione, opts)
      end

      def con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_ANAGRAFICA_ENODEB, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def con_formatter(type_export:, out_file:, &block)
        Formatter.get_formatter(type_export, out_file: out_file, logger: logger, log_prefix: log_prefix, &block)
      end

      def con_parser(type_export:, file_da_processare:, **opts, &block)
        Importer.get_importer(type_export, file_da_processare: file_da_processare, **opts, &block)
      end

      PR_ENODEB_CAMPI_OBBLIGATORI = [
        ENODEBID_FIELD     = 'ENODEBID'.freeze,
        ENODEBNAME_FIELD   = 'E_NODEB_NAME'.freeze,
        SISTEMA_ID_FIELD   = Irma::Vendor::PR_SISTEMA,
        OMCFISICO_ID_FIELD = Irma::Vendor::PR_OMC_FISICO
      ].freeze

      def analizza_header(linea_hdr)
        pezzi = linea_hdr.upcase.split(PR_SEP, -1)
        unless controllo_campi_obbligatori(pezzi)
          raise 'Campi obbligatori non presenti nell\'intestazione'
        end
        pezzi
      end

      def controllo_campi_obbligatori(hdr_array)
        PR_ENODEB_CAMPI_OBBLIGATORI.each do |campo|
          unless hdr_array.include?(campo)
            nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_CAMPI_OBBLIGATORI_HEAD, campo: campo)
            return false
          end
          @hdr_posizioni[campo] = hdr_array.index(campo)
        end
      end

      AZIONI = [
        SCARTO_LINEA     = 'linee_scartate'.freeze,
        LINEA_OK         = 'linee_non_modificate'.freeze,
        LINEA_MODIFICATA = 'linee_modificate'.freeze,
        NUOVO_ENODEBID   = 'enodeb_creati'.freeze
      ].freeze
      # linea_input = stringa con campi concatenati con separatore PR_SEP
      def processa_linea_input(linea_input:, linea_num:)
        result = { azioni: [], campi_da_scrivere: nil }
        linea_array = linea_input.split(PR_SEP, -1)
        # check coerenza sistema/omc_fisico
        sf = linea_array[@hdr_posizioni[SISTEMA_ID_FIELD]]
        sc = saa.sistema.descr
        if sf != sc
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_COMPETENZA_OMC,
                             linea_file: linea_num, tipo_omc: 'Logico', omc_file: sf, omc_comp: sc)
          logger.warn("#{@log_prefix} Sistema non corrispondente: atteso #{sc}, trovato #{sf}")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end
        of = linea_array[@hdr_posizioni[OMCFISICO_ID_FIELD]]
        oc = saa.sistema.omc_fisico.nome
        if of != oc
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_COMPETENZA_OMC,
                             linea_file: linea_num, tipo_omc: 'Fisico', omc_file: of, omc_comp: oc)
          logger.warn("#{@log_prefix} Omc non corrispondente: atteso #{oc}, trovato #{of}")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end

        # verifiche enodeb
        m_enodebid   = linea_array[@hdr_posizioni[ENODEBID_FIELD]].to_s
        m_enodebname = linea_array[@hdr_posizioni[ENODEBNAME_FIELD]].to_s.upcase

        unless m_enodebname.match(Db::AnagraficaEnodeb.config[Db::AnagraficaEnodeb::REG_EXPR_NOME_ENODEB])
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_ENODEBNAME_ERRATO,
                             linea_file: linea_num, nome_nodo: m_enodebname)
          logger.warn("#{@log_prefix} Il campo E_NODEB_NAME '#{m_enodebname}' non e' avvalorato correttamente.")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end

        m_provincia = AnagraficaTerritoriale.provincia_da_nome_cella(m_enodebname)
        unless m_provincia
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_ENODEBNAME_NO_PROVINCIA,
                             linea_file: linea_num, nome_nodo: m_enodebname)
          logger.warn("#{@log_prefix} Al campo E_NODEB_NAME '#{m_enodebname}' non corrisponde nessuna provincia.")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end

        m_at = AnagraficaTerritoriale.at_di_provincia(m_provincia).first
        unless m_at
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_ENODEBNAME_NO_AT,
                             linea_file: linea_num, nome_nodo: m_enodebname)
          logger.warn("#{@log_prefix} Al campo E_NODEB_NAME '#{m_enodebname}' non corrisponde nessuna area territoriale.")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end

        unless @province_per_saa.include?(m_provincia)
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_COMPETENZA_PROVINCE,
                             linea_file: linea_num, enodebname: m_enodebname,
                             provincia: m_provincia, province_comp: @province_per_saa.join(','))
          logger.warn("#{@log_prefix} La provincia #{m_provincia} (enodeb_name: #{m_enodebname}) non e' tra quelle di competenza (#{@province_per_saa})")
          result[:azioni] = [SCARTO_LINEA]
          return result
        end

        id_in_anagrafica = @anagrafica_enodeb[m_at][:dati][m_enodebname]

        result[:campi_da_scrivere] = linea_array
        if id_in_anagrafica
          if id_in_anagrafica == m_enodebid
            result[:azioni] = [LINEA_OK]
          else
            nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_MODIFICA_FILE,
                               linea_file: linea_num, nome_nodo: m_enodebname, old_id: m_enodebid, new_id: id_in_anagrafica)
            result[:campi_da_scrivere][@hdr_posizioni[ENODEBID_FIELD]] = id_in_anagrafica
            result[:azioni] = [LINEA_MODIFICATA]
          end
        else
          new_id = (@anagrafica_enodeb[m_at][:id_liberi].delete(m_enodebid) || @anagrafica_enodeb[m_at][:id_liberi].shift)
          unless new_id
            nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_NO_NEW_ID,
                               linea_file: linea_num, area_terr: m_at)
            raise "#{@log_prefix} Impossibile ottenere un nuovo enodebid per l'area territoriale #{m_at}"
            # result[:azioni] = [SCARTO_LINEA]
            # return result
          end
          Db::AnagraficaEnodeb.create(enodeb_name: m_enodebname,
                                      enodeb_id: new_id,
                                      area_territoriale: m_at)
          nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_NUOVO_ENODEBID,
                             linea_file: linea_num, nome_nodo: m_enodebname, enodebid: new_id)
          @anagrafica_enodeb[m_at][:dati][m_enodebname] = new_id
          result[:azioni] << NUOVO_ENODEBID
          if new_id != m_enodebid
            nuova_segnalazione(TIPO_SEGNALAZIONE_COMPLETA_ENODEBID_DATI_MODIFICA_FILE,
                               linea_file: linea_num, nome_nodo: m_enodebname, old_id: m_enodebid, new_id: new_id)
            result[:campi_da_scrivere][@hdr_posizioni[ENODEBID_FIELD]] = new_id
            result[:azioni] << LINEA_MODIFICATA
          end
        end
        result
      end

      #--------------------------------------------------------

      def esegui(file_da_processare:, step_info: 1_000, **opts)
        res = { totale: 0, linee_input_elaborate: 0, linee_scritte: 0,
                dettaglio: {}
        }
        AZIONI.each { |aaa| res[:dettaglio][aaa] = 0 }

        step_progresso = opts[:step_progresso] || 1_000
        funzione = Db::Funzione.get_by_pk(FUNZIONE_COMPLETA_ENODEBID)
        con_lock(funzione: funzione.nome, account_id: saa.account_id, mode: LOCK_MODE_WRITE, **opts) do # |locks|
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: saa.filtro_segnalazioni, attivita_id: opts[:attivita_id]) do
            #-------------------------------------------------------------------------------------
            con_formatter(type_export: opts[:formato], out_file: out_file) do |formatter|
              Irma.gc
              carica_anagrafica_enodeb
              con_parser(type_export: opts[:formato], file_da_processare: file_da_processare, **opts) do |parser|
                InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
                  begin
                    Db::AnagraficaEnodeb.db.transaction do
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
      def completa_enodeb(file_da_processare:, **opts)
        Funzioni::CompletaEnodeb.new(sistema_ambiente_archivio: self, **opts).esegui(file_da_processare: file_da_processare, **opts)
      end
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      def completa_enodeb(file_da_processare:, **opts)
        Funzioni::CompletaEnodeb.new(sistema_ambiente_archivio: self, **opts).esegui(file_da_processare: file_da_processare, **opts)
      end
    end
  end
end
