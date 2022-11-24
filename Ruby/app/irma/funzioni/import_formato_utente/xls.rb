# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20161113
#
require 'irma/poi'
require_relative 'text'

module Irma
  #
  module Funzioni
    #
    class ImportFormatoUtente
      #
      class Xls < Text
        def parse(&block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          sheet_da_skippare = nil
          num_linea_hdr = 1 # @solo_header ? 1 : 3
          last_line_processed = 0
          Irma.read_xls(@file) do |sheet_name, row_idx, record|
            next if sheet_name == sheet_da_skippare
            sheet_da_skippare = nil
            num_linea_sheet = row_idx + 1
            line = record.join(num_linea_sheet == num_linea_hdr ? TEXT_HEADER_ROW_SEP : TEXT_DATA_ROW_SEP)
            last_line_processed += 1
            @stats[:lines] += 1 if @stats
            next if line.empty?
            # next if @solo_header && num_linea_sheet > num_linea_hdr
            # passo la riga intera come stringa, lo split lo faccio dentro i metodi di LineaText per gestire bene gli strutturati
            @nome_file_per_segnalazioni = sheet_name
            y = LineaText.new(linea: line, linea_file: num_linea_sheet, importer: self)
            res_analizza = y.analizza(linea_hdr: num_linea_hdr, &block)
            # raise "Foglio #{sheet_name}, riga #{num_linea_sheet} non corretta (#{last_line_processed})" unless res_analizza
            unless res_analizza
              raise "Foglio #{sheet_name}, riga #{num_linea_sheet} non corretta (#{last_line_processed})" unless @solo_header
              sheet_da_skippare = sheet_name
            end
          end
          @stats
        rescue EsecuzioneScaduta
          raise
        rescue => e
          Irma.logger.error("Errore nel parsing del file excel #{@file}: #{e}, backtrace: #{e.backtrace}")
          raise "Errore nel parsing del file excel #{@file}, linea #{last_line_processed}: #{e}"
        end
      end
    end
  end
end
