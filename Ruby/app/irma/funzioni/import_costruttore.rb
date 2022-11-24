# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151116
#
require 'irma/cache'
# require_relative 'segnalazioni_per_funzione'

module Irma
  #
  module Funzioni
    # rubocop:disable Metrics/ClassLength
    class ImportCostruttore
      #
      class <<self
        attr_reader :import_classes

        def inherited(klass)
          (@import_classes ||= []) << klass
        end

        def formato_audit
          raise NotImplementedError, "formato_audit non implementata per la classe #{self}"
        end

        def formato_file_compatibile?
          raise NotImplementedError, "formato_file_compatibile? non implementata per la classe #{self}"
        end
      end

      attr_reader :logger, :sistema_ambiente_archivio, :metamodello, :log_prefix, :vendor_instance
      alias saa sistema_ambiente_archivio

      def initialize(sistema_ambiente_archivio:, **opts)
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @omc_fisico = sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
        @sistema_ambiente_archivio = sistema_ambiente_archivio
        @metamodello = opts[:metamodello]
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Import costruttore (#{sistema_ambiente_archivio.full_descr})"
        @vendor_instance = saa.vendor_instance(opts)
        # @counter_segnalazioni = 0
      end

      def formato_audit
        self.class.formato_audit
      end

      def import_cache(hash = {})
        @import_cache ||= {
          meta_entita_mancante:         {},
          meta_parametro_inconsistente: [],
          meta_parametro_mancante:      {},
          entita_scartate:              Cache.instance(key: saa.import_cache_prefix(hash) + 'entita_scartate', type: :map_db),
          entita_trovate:               {},
          entita_trovate_fino_al_nodo:  {},
          nodi_esterni:                 saa.carica_nodi_esterni(hash.merge(log_prefix: log_prefix)),
          meta_modello_header:          {},
          version_assente:              []
        }
      end

      def reset_import_cache
        return nil unless @import_cache
        @import_cache[:entita_scartate].remove
        @import_cache = nil
      end

      def con_import_cache(opts, &_block)
        import_cache(opts)
        yield(import_cache)
      ensure
        reset_import_cache
      end

      def nuova_entita_per_loader(loader, entita)
        loader << entita
        import_cache[:entita_trovate][entita.dist_name] = entita.id
        import_cache[:entita_trovate_fino_al_nodo][entita.dist_name] = entita.id unless entita.nodo_id
        entita
      end

      def con_parser(_file:, **_opts)
        raise NotImplementedError, "con_parser non implementata per la classe #{self.class}"
      end

      def analizza_entita_parser(_entita_parser:, **_opts)
        raise NotImplementedError, "analizza_entita_parser non implementata per la classe #{self.class}"
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def esegui(file:, delta: true, step_info: 100_000, **opts)
        res = { formato_audit: formato_audit, entita: Hash.new(0) }
        # funzione = Db::Funzione.get_by_pk(FUNZIONE_IMPORT_OMC_LOGICO)
        funzione = Db::Funzione.get_by_pk(opts[:funzione])
        saa.con_lock(funzione: funzione.nome, account_id: saa.account_id, mode: LOCK_MODE_WRITE, **opts) do # |locks|
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: saa.filtro_segnalazioni, attivita_id: opts[:attivita_id]) do
            Irma.gc
            con_parser(file: file, **opts) do |parser|
              res[:loader] = saa.con_loader_entita(funzione: funzione.nome, account_id: saa.account_id, delta: delta, lock: false, **opts) do |loader|
                con_import_cache(loader.lock_info) do
                  nuova_entita_per_loader(loader, vendor_instance.root_entita(formato_audit)) if vendor_instance.root_entita(formato_audit)
                  InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
                    res[:parser] = parser.parse do |entita_parser|
                      ret = analizza_entita_parser(entita_parser: entita_parser, **opts)
                      res[:entita][ret] += 1
                      case ret
                      when ESITO_ANALISI_ENTITA_OK
                        entita_parser.avvalora_campi_adiacenza(vendor_instance)
                        nuova_entita_per_loader(loader, entita_parser)
                      when ESITO_ANALISI_ENTITA_DA_IGNORARE
                        # nothing to do
                      when ESITO_ANALISI_ENTITA_DATETIME_ERRATO, ESITO_ANALISI_ENTITA_CMDATA_ERRATO
                        raise 'Intestazione file non valida'
                      else
                        logger.warn("#{opts[:log_prefix]}, scartata entita (#{ret}), info=#{entita_parser.info}")
                      end
                      ip.incr do
                        segnalazione_esecuzione_in_corso("(#{ip.total} entità identificate, #{ip.rate.round(0)} entità/s)")
                      end
                    end
                    segnalazione_esecuzione_in_corso("(#{ip.total} entità identificate, #{ip.rate.round(0)} entità/s, inizio caricamento db)")
                    res[:parser]
                  end
                end
              end
              res
            end
          end
        end
      end
    end
  end

  #
  module Db
    # extend class
    class SistemaAmbienteArchivio
      def import_costruttore(file:, delta:, **opts)
        ic = (Funzioni::ImportCostruttore.import_classes || []).map { |klass| klass.formato_file_compatibile?(file) ? klass : nil }.compact

        msg_params = { file: file, sistema: sistema.full_descr }

        raise format_msg(:FORMATO_FILE_AUDIT_NON_RICONOSCIUTO, **msg_params) if ic.empty?
        raise format_msg(:FORMATO_FILE_AUDIT_SUPPORTATO_DA_PIU_IMPORTER, importer: ic.map(&:formato_audit), **msg_params) if ic.size > 1

        import_class = ic.first

        raise format_msg(:FORMATO_FILE_AUDIT_NON_SUPPORTATO, formato_audit: import_class.formato_audit, **msg_params) unless formati_audit.include?(import_class.formato_audit)
        opts.update(funzione: FUNZIONE_IMPORT_OMC_LOGICO)

        import_class.new(sistema_ambiente_archivio: self, **opts).esegui(file: file, delta: delta, **opts)
      end
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      def import_costruttore(file:, delta:, **opts)
        ic = (Funzioni::ImportCostruttore.import_classes || []).map { |klass| klass.formato_file_compatibile?(file) ? klass : nil }.compact

        msg_params = { file: file, sistema: omc_fisico.full_descr }

        raise format_msg(:FORMATO_FILE_AUDIT_NON_RICONOSCIUTO, **msg_params) if ic.empty?
        raise format_msg(:FORMATO_FILE_AUDIT_SUPPORTATO_DA_PIU_IMPORTER, importer: ic.map(&:formato_audit), **msg_params) if ic.size > 1

        import_class = ic.first

        raise format_msg(:FORMATO_FILE_AUDIT_NON_SUPPORTATO, formato_audit: import_class.formato_audit, **msg_params) unless formati_audit.include?(import_class.formato_audit)

        opts.update(funzione: FUNZIONE_IMPORT_OMC_FISICO)
        import_class.new(sistema_ambiente_archivio: self, **opts).esegui(file: file, delta: delta, **opts)
      end
    end
  end
end

require_relative 'import_costruttore/idl'
require_relative 'import_costruttore/cna'
require_relative 'import_costruttore/tre_gpp'
