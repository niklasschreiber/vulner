# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20161025
#

module Irma
  #
  module Funzioni
    #
    class CompletaEnodeb
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
            @sheet_name = opts[:sheet_name]
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

          def scrivi_linea(_campi_linea:)
            raise "#{self}#scrivi_linea non implementato"
          end

          def scrivi_header(_campi_linea:)
            raise "#{self}#scrivi_header non implementato"
          end
        end

        #-------------------------------------------------------------------------------------------
        #
        class XlsFormatter < BaseFormatter
          # Excel limits
          EXCEL_CELL_MAX_LENGTH = (2 << 14) - 1
          CELL_VALUE_DOT = '...'.freeze

          def string_for_cell(input_value)
            input_value.to_s.size > EXCEL_CELL_MAX_LENGTH ? (input_value.to_s[0..EXCEL_CELL_MAX_LENGTH - CELL_VALUE_DOT.size - 1] + CELL_VALUE_DOT) : input_value.to_s
          end

          attr_reader :book, :sheet, :rows, :riga

          def reset(full: true)
            return unless full
            @book  = nil
            @sheet = nil
            @riga  = 0
            @rows = 0
            @stat = {}
          end

          def inizia(&_block)
            require 'irma/poi'
            reset
            Irma.export_xls(out_file) do |xls_book|
              @book = xls_book
              @sheet = @book.worksheets[@sheet_name || 'Foglio 1']
              yield(self)
            end
          end

          def termina
            reset(full: false)
          end

          def scrivi_linea(campi_linea:)
            row = @sheet.new_row(@riga)
            @riga += 1
            campi_linea.each.with_index do |xxx, idx_row|
              row[idx_row].value = string_for_cell(xxx)
            end
          end

          def scrivi_header(campi_linea:)
            scrivi_linea(campi_linea: campi_linea)
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
            yield(self)
          end

          def termina
            reset(full: false)
          end

          def scrivi_linea(campi_linea:)
            @fd.puts((campi_linea || []).join(PR_SEP))
          end

          def scrivi_header(campi_linea:)
            @fd ||= File.open(out_file, 'a')
            scrivi_linea(campi_linea: campi_linea)
          end
        end
        #-------------------------------------------------------------------------------------------
      end
    end
  end
end
