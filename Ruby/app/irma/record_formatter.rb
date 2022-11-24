# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170126
#

require 'tmpdir'
require 'irma/poi'

#
module Irma
  module RecordFormatter
    class Base
      attr_reader :format, :suffix, :opts

      def initialize(format:, suffix: 'file_formatter', **opts)
        @format = format
        @suffix = suffix
        @opts = opts
      end

      def estensione
        @format
      end

      def make_tmpname
        Dir::Tmpname.make_tmpname(Irma.export_dir + '/', "#{suffix}.#{estensione}")
      end

      def add_record_values(_r, _v)
        raise "add_record_values not implemented for class #{self.class}"
      end

      # ritorna il nome del file creato
      def create_temp_file(**_hash)
        raise "create_temp_file not implemented for class #{self.class}"
      end
    end

    class Array < Base
      def initialize(suffix: 'json_file_formatter', **opts)
        super(format: 'json', suffix: suffix, **opts)
      end

      def add_record_values(_r, v)
        @records << v
        self
      end

      def create_array
        @records = []
        yield(self)
        @records
      end
    end

    class Txt < Base
      def initialize(suffix: 'txt_file_formatter', **opts)
        super(format: 'txt', suffix: suffix, **opts)
      end

      def header
        nil
      end

      def add_line(line)
        @fd.puts(line.to_s)
        self
      end

      def create_temp_file(**hash)
        tmp_name = make_tmpname
        File.open(tmp_name, 'w') do |file_descriptor|
          @fd = file_descriptor
          @fd.puts(header) if header
          yield(self, { fd: @fd, tmp_name: tmp_name })
        end
        tmp_name
      rescue
        FileUtils.rm_f(tmp_name) if hash.fetch(:remove_file_on_error, true)
        raise
      ensure
        @fd = nil
      end
    end

    class Xls < Base
      EXCEL_CELL_MAX_LENGTH = (2 << 14) - 1
      CELL_VALUE_DOT = '...'.freeze

      # opts[:export_columns] = [{nome_hdr: nome_colonna, width: size, record_key: xxx...}, {...}, ...]
      # opts[:export_columns] = [{text: nome_colonna, width: size, data_index: xxx...}, {...}, ...]
      EXPORT_COLUMN_TEXT = 'text'.freeze # nome_hdr
      EXPORT_COLUMN_WITH = 'width'.freeze
      EXPORT_COLUMN_DATA_INDEX = 'data_index'.freeze # record_key

      attr_reader :book, :style, :sheet, :rows, :riga, :sheet_info, :stat, :colonne
      def initialize(suffix: 'xls_file_formatter', **opts)
        super(format: 'xls', suffix: suffix, **opts)
        @colonne = (opts[:export_columns] && !opts[:export_columns].empty?) ? opts[:export_columns] : []
        reset
      end

      def estensione
        'xlsx'
      end

      def reset(full: true)
        @book = @style = @sheet = @rows = @riga = nil
        @stat = { num_header: 0, num_record_rows: 0 } if full
        @sheet_info = {}
      end

      def header # rubocop:disable Metrics/AbcSize
        @riga = 0
        row = @sheet.new_row(@riga)
        @stat[:num_header] = 1
        colonne.each.with_index do |column, idx|
          column_chars = [(column[EXPORT_COLUMN_WITH] / 6), 255].min
          sheet.set_column_width(idx, column_chars * 256) unless column_chars == 0
          row[idx].value = string_for_cell(column[EXPORT_COLUMN_TEXT])
          row[idx].style = style[:header]
        end
      end

      # /app/dev/repo/Trunk/qubo/as/lib/qubo_as/gridfilter.rb su qubo01

      def create_temp_file(**_hash) # rubocop:disable Metrics/AbcSize
        require 'irma/poi'
        tmp_name = make_tmpname
        Irma.export_xls(tmp_name) do |xls_book|
          @book = xls_book
          @sheet = @book.worksheets[opts[:sheet_name] || 'Foglio 1']
          @sheet.worksheet.java_send(:trackAllColumnsForAutoSizing) if colonne.empty? && opts[:autosize] == true && @book.autosize_available?
          crea_stili
          header unless colonne.empty?
          yield(self)
        end
        tmp_name
      end

      def prepara_row(row, val)
        # if (val.is_a?(String) || val.is_a?(Integer) || val.is_a?(BigDecimal)) && val.to_i.to_s == val.to_s
        if val.to_s.numeric?
          row.cell_type = POI::Cell::CELL_TYPE_NUMERIC
          row.value = val.is_a?(BigDecimal) ? val.to_f : val
          row.style = style[:right]
        else
          row.cell_type = POI::Cell::CELL_TYPE_STRING
          row.value = string_for_cell(val)
          row.style = style[:left]
        end
        row
      end

      # _r record dal db (obj di model), _v hash con attributi del record _r piu' eventuali altre coppie chiave valore...
      # e' chiamato per ogni riga da aggiungere al file excel....
      def add_record_values(record, values) # rubocop:disable Metrics/AbcSize
        if @stat[:num_header] == 0
          # non ho export_columns, quindi non ho creato un header, lo faccio ora con tutti i campi del record
          @colonne = record.values.keys.sort.map { |k| { EXPORT_COLUMN_TEXT => k.to_s.upcase, EXPORT_COLUMN_DATA_INDEX => k.to_s } } if colonne.empty?
          header
        end
        @riga += 1
        row = @sheet.new_row(@riga)
        colonne.each.with_index do |column, idx|
          prepara_row(row[idx], sistema_valore(values[column[EXPORT_COLUMN_DATA_INDEX].to_sym]))
        end
        stat[:num_record_rows] += 1
        self
      end

      # util....
      def sistema_valore(val)
        if val.nil? || val.is_a?(Array) || [true, false].include?(val)
          val.to_s
        else
          val
        end
      end

      def string_for_cell(input_value)
        input_value.to_s.size > EXCEL_CELL_MAX_LENGTH ? (input_value.to_s[0..EXCEL_CELL_MAX_LENGTH - CELL_VALUE_DOT.size - 1] + CELL_VALUE_DOT) : input_value.to_s
      end

      def crea_stili
        @style = {}
        basic_style_opts = { font_height_in_points: 10 }
        @style[:header] = @book.create_style basic_style_opts.merge(color: :black, fill_foreground_color: :sky_blue,
                                                                    fill_pattern: :solid_foreground,
                                                                    alignment: :align_center, vertical_alignment: :vertical_center)
        @style[:left]  = @book.create_style basic_style_opts.merge(alignment: :align_left)
        @style[:right] = @book.create_style basic_style_opts.merge(alignment: :align_right)
        @style[:center] = @book.create_style basic_style_opts.merge(alignment: :align_center)
        @style[:hyperlink] = @book.create_style basic_style_opts.merge(color: :blue, font_height_in_points: 12)
        @style
      end
    end
  end
end
