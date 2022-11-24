# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180925
#
require_relative 'segnalazioni_per_funzione'
require_relative 'basic_importer'

require 'set'

module Irma
  #
  module Funzioni
    class ImportFiltroAlberatura
      include SegnalazioniPerFunzione
      include Irma::Funzioni::BasicImporter

      attr_reader :logger, :log_prefix, :metamodello, :stats
      attr_reader :actual_np_root, :actual_np_root_level, :actual_lista_entita
      attr_reader :cache_filtro, :error_msg
      attr_reader :num_linea_header

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'Import Filtro Alberatura'
        @metamodello = opts[:metamodello]
        @num_linea_header = opts[:num_linea_header] || 1
        @error_msg = {}
        @cache_filtro = {}
        @stats = nil

        @map_nproot_nomesheet = {}
      end

      def con_parser(type_export:, file_da_processare:, **opts, &block)
        BasicImporter.get_importer(type_export, file_da_processare: file_da_processare, **opts, &block)
      end

      #-----------------------------------------------------------------------------------------------
      def aggiorna_cache_filtro # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        return unless @actual_np_root

        # TODO: Aggiungere controlli...
        # Se si e' verificato un errore nella lettura di qualche riga, ignoro i dati letti per l'intero sheet/naming_path
        return unless (@error_msg[@map_nproot_nomesheet[@actual_np_root]] || []).empty?

        # Se non ho letto nessuna riga entita buona
        if @actual_lista_entita.empty?
          (@error_msg[@map_nproot_nomesheet[@actual_np_root]] ||= []) << format_msg(:FILTRO_ALBERATURA_NESSUNA_ENTITA, naming_path_root: @actual_np_root)
          return
        end
        np_descendants = metamodello.naming_path_alberatura(@actual_np_root)
        (np_descendants + [@actual_np_root]).each do |x_np|
          cache_filtro[x_np] ||= { FILTRO_MM_PARAMETRI => [META_PARAMETRO_ANY],
                                   FILTRO_MM_ENTITA => [] }
          pezzi_x_np = x_np.split(NAMING_PATH_SEP)
          pezzi_extra = Array.new(pezzi_x_np.size - @actual_np_root_level, NOME_ENTITA_ANY)

          @actual_lista_entita.each do |pezzi_entita|
            dist_name = (pezzi_x_np.zip(pezzi_entita + pezzi_extra).map { |x| x.join(DIST_NAME_VALUE_SEP) }).join(DIST_NAME_SEP)
            cache_filtro[x_np][FILTRO_MM_ENTITA] << dist_name
          end
        end
      end

      def elabora_header(values, sheet_name)
        res = {}
        reset_info
        np = (values || []).join(NAMING_PATH_SEP)
        unless metamodello.meta_entita.keys.include?(np)
          res[:error] = format_msg(:FILTRO_ALBERATURA_METAENTITA_INESISTENTE, naming_path: np)
          return res
        end
        @actual_np_root = np
        @actual_np_root_level = values.size
        @map_nproot_nomesheet[@actual_np_root] = sheet_name
        res
      end

      def elabora_linea_entita(values)
        res = {}
        if values.nil? || values.size < @actual_np_root_level || values.map(&:to_s).include?('')
          res[:error] = format_msg(:FILTRO_ALBERATURA_LINEA_ENTITA_ERRATA, values: values, naming_path: @actual_np_root)
          return res
        end
        @actual_lista_entita << values
        res
      end

      def reset_info(anche_cache = false)
        @cache_filtro = {} if anche_cache
        @map_nproot_nomesheet = {} if anche_cache

        @actual_np_root = nil
        @actual_np_root_level = nil
        @actual_lista_entita = []
      end
      #--------------------------------------------------------

      def processa_linea_input(linea_input, linea_num, sheet_name, res) # rubocop:disable Metrics/AbcSize
        if linea_num == @num_linea_header
          aggiorna_cache_filtro
          result = elabora_header(linea_input, sheet_name)
          res[result[:error] ? :linee_header_scartate : :linee_header_ok] += 1
        else
          result = elabora_linea_entita(linea_input)
          res[result[:error] ? :linee_entita_scartate : :linee_entita_ok] += 1
        end
        (@error_msg[sheet_name] ||= []) << result[:error] if result[:error]
        result[:error].nil?
      end

      def esegui(lista_file:, **opts) # rubocop:disable Metrics/MethodLength
        res = { linee_header_ok: 0, linee_header_scartate: 0, linee_entita_ok: 0, linee_entita_scartate: 0 }
        reset_info(true)
        lista_file.each_with_index do |file_da_processare, idx|
          con_parser(type_export: opts[:formato], file_da_processare: file_da_processare, **opts) do |parser|
            begin
              res[:"parser_#{idx}"] = parser.parse do |linea_input, linea_num, sheet_name|
                processa_linea_input(linea_input, linea_num, sheet_name, res)
              end # parse
              aggiorna_cache_filtro
            rescue => e
              res[:eccezione] = "#{e}: #{e.message} - nella rescue di begin"
              logger.error("#{@log_prefix} catturata eccezione (#{res})")
              raise
            end # begin
          end # con_parser
        end # lista_file
        res[:header_per_filtro] = cache_filtro
        res[:error_msg] = @error_msg
        res
      end
    end
  end
end
