# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180117
#

module Irma
  #
  module Funzioni
    #
    class ExportProgettoRadio
      #
      module Formatter
        def self.get_formatter(type, opts, &block)
          formatter = nil
          formatter = class_eval(type.to_s.camelize + 'Formatter').new(out_file: opts[:out_file], **opts)
          formatter.inizia(&block)
          formatter
        ensure
          formatter.termina if formatter
        end

        #
        class BaseFormatter
          attr_reader :out_file, :logger, :log_prefix, :stat

          def initialize(out_file:, **opts)
            @out_file = out_file
            @logger = opts[:logger] || Irma.logger
            @log_prefix = opts[:log_prefix]
            reset(full: true)
          end

          def reset(full: true); end

          def inizia(&_block)
            raise "#{self}#processa non implementato"
          end

          def termina(&_block)
            raise "#{self}#termina non implementato"
          end

          def scrivi_linea(_campi_linea:, _stile:)
            raise "#{self}#scrivi_linea non implementato"
          end

          def scrivi_header(**_opts)
            raise "#{self}#scrivi_header non implementato"
          end
        end

        #-------------------------------------------------------------------------------------------
        #
        class XlsFormatter < BaseFormatter
          require 'irma/poi'
          include Irma::PoiUtil

          attr_reader :book, :sheet, :rows, :riga

          def reset(full: true)
            return unless full
            @book  = nil
            @sheet = nil
            @riga  = 0
            @stat = {}
          end

          def inizia(&_block)
            reset
            Irma.export_xls(out_file) do |xls_book|
              @book = xls_book
              @style = crea_stili(@book)
              yield(self)
            end
          end

          def termina
            reset(full: false)
          end

          def scrivi_linea(campi_linea:, stile: nil)
            row = @sheet.new_row(@riga)
            @riga += 1
            campi_linea.each.with_index do |xxx, idx_row|
              row[idx_row].value = string_for_cell(xxx)
              row[idx_row].style = stile if stile
            end
          end

          def scrivi_header(campi_linea:, nome_foglio: nil)
            @sheet = @book.worksheets[nome_foglio || 'Foglio 1']
            @riga  = 0
            scrivi_linea(campi_linea: campi_linea, stile: @style[:header])
            @sheet.worksheet.java_send(:createFreezePane, [Java.int, Java.int], 0, 1)
          end
        end
        #-------------------------------------------------------------------------------------------
        #
        class TxtFormatter < BaseFormatter
          attr_reader :fd

          def reset(full: true)
            @fd.close if @fd
            return unless full
            @fd = nil
            @stat = {}
          end

          def inizia(&_block)
            reset
            @fd ||= File.open(out_file, 'a')
            yield(self)
          end

          def termina
            reset(full: false)
          end

          def scrivi_linea(campi_linea:, _stile: nil)
            @fd.puts campi_linea.join(TEXT_DATA_ROW_SEP)
          end

          def scrivi_header(**opts)
            campi_linea = opts[:campi_linea] || []
            @fd.puts campi_linea.join(TEXT_HEADER_ROW_SEP)
          end
        end
        #-------------------------------------------------------------------------------------------
      end
    end
  end
end
