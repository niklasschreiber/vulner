# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20161113
#
require 'irma/poi'
require_relative 'text_cella'

module Irma
  #
  module Funzioni
    #
    class ImportProgettoRadio
      #
      class XlsCella < TextCella
        def parse(&block) # # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
          last_line_processed = 0
          Irma.read_xls(@file) do |sheet_name, row_idx, record|
            # puts " *** parse xls: size record: #{record.size}"
            line = record.join(row_idx.zero? ? TEXT_HEADER_ROW_SEP : TEXT_DATA_ROW_SEP)
            last_line_processed += 1
            @stats[:lines] += 1 if @stats
            next if line.empty?
            @nome_file_per_segnalazioni = sheet_name
            LineaCella.new(line: line, linea_file: last_line_processed, importer: self).analizza(&block)
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
