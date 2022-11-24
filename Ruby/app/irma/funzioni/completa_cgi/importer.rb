# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180911
#

module Irma
  #
  module Funzioni
    #
    class CompletaCgi
      #
      module Importer
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
          def parse(&_block)
            last_line_processed = -1
            Irma.processa_file_per_linea(@file, suffix: 'parse_txt') do |line, n|
              line.chomp!
              last_line_processed = n + 1
              @stats[:lines] += 1 if @stats
              next if line.empty?
              yield line, last_line_processed
            end
          rescue EsecuzioneScaduta
            raise
          rescue => e
            logger.error("#{@log_prefix} catturata eccezione nella processazione della riga #{last_line_processed}: #{e}, backtrace: #{e.backtrace}")
            raise "Linea #{last_line_processed} non corretta: #{e}"
          end
        end

        class XlsImporter < BaseImporter
          def parse(&_block) # # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
            last_line_processed = 0
            Irma.read_xls(@file) do |sheet_name, _row_idx, record|
              line = record.join(PR_SEP) # row_idx.zero? ? TEXT_HEADER_ROW_SEP : TEXT_DATA_ROW_SEP)
              last_line_processed += 1
              @stats[:lines] += 1 if @stats
              next if line.empty?
              @nome_file_per_segnalazioni = sheet_name
              yield line, last_line_processed
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
end
