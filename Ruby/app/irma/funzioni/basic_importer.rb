# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20190524
#
require 'irma/poi'

module Irma
  #
  module Funzioni
    #
    module BasicImporter
      def self.get_importer(type, opts, &_block)
        importer = class_eval(type.to_s.camelize + 'Importer').new(**opts)
        yield(importer)
      end

      #
      class BaseImporter
        attr_reader :logger, :log_prefix, :stat

        def initialize(file_da_processare:, **opts)
          @stats = { lines: 0 }
          @file = file_da_processare
          @logger = opts[:logger] || Irma.logger
          @log_prefix = opts[:log_prefix]
        end

        def parse(&_block)
          raise 'Il metodo parse va ridefinito nella classe specifica'
        end
      end

      class TxtImporter < BaseImporter
        def pre_processing_linea(line:, **_hash)
          line
        end

        def parse(&_block)
          last_line_processed = -1
          file_name = File.basename(@file)
          Irma.processa_file_per_linea(@file, suffix: 'parse_txt') do |line, n|
            line.chomp!
            last_line_processed = n + 1
            @stats[:lines] += 1 if @stats
            next if line.empty?
            yield pre_processing_linea(line: line, line_number: last_line_processed), last_line_processed, file_name
          end
          @stats
        rescue EsecuzioneScaduta
          raise
        rescue => e
          logger.error("#{@log_prefix} catturata eccezione nella processazione della riga #{last_line_processed}: #{e}, backtrace: #{e.backtrace}")
          raise "Linea #{last_line_processed} non corretta: #{e}"
        end
      end

      class XlsImporter < BaseImporter
        def parse(&_block) # rubocop:disable Metrics/MethodLength
          sheet_da_skippare = nil
          last_line_processed = 0
          Irma.read_xls(@file) do |sheet_name, row_idx, record|
            next if sheet_name == sheet_da_skippare
            sheet_da_skippare = nil
            num_linea_sheet = row_idx + 1
            last_line_processed += 1
            @stats[:lines] += 1 if @stats
            res_analizza = yield record, num_linea_sheet, sheet_name
            sheet_da_skippare = sheet_name unless res_analizza
            res_analizza
          end
          @stats
        rescue EsecuzioneScaduta
          raise
        rescue => e
          logger.error("#{@log_prefix} catturata eccezione nella processazione della riga #{last_line_processed}: #{e}, backtrace: #{e.backtrace}")
          raise "Linea #{last_line_processed} non corretta: #{e}"
        end
      end
    end
  end
end
