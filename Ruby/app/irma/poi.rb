# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20161024
#
require 'poi'

%w(slf4j-api-1.7.21.jar slf4j-nop-1.7.21.jar xlsx-streamer-1.0.1.jar).each { |f| load File.join(__dir__, 'poi_jars', f) }

java.lang.System.set_property('java.io.tmpdir', Irma.tmp_dir)

# PATCH to obtain reference to workbook
module POI
  #
  class Workbook
    attr_reader :workbook
    # override initialize to add streamin as default
    def initialize(filename, io_stream, options = {}) # rubocop:disable Metrics/AbcSize
      @filename = filename
      @workbook = if io_stream
                    org.apache.poi.ss.usermodel.WorkbookFactory.create(io_stream)
                  elsif options[:format] == :hssf
                    org.apache.poi.hssf.usermodel.HSSFWorkbook.new
                  elsif options[:format] == :xssf
                    org.apache.poi.xssf.usermodel.XSSFWorkbook.new
                  else
                    org.apache.poi.xssf.streaming.SXSSFWorkbook.new(org.apache.poi.xssf.usermodel.XSSFWorkbook.new,
                                                                    options.fetch(:row_access_window_size, 1),
                                                                    options.fetch(:compress_tmp_files, false),
                                                                    options.fetch(:use_shared_strings_table, false)
                                                                   )
                  end
    end

    def cleanup
      workbook.dispose if workbook && workbook.respond_to?(:dispose)
    end

    def autosize_available?
      @workbook.instance_of?(org.apache.poi.xssf.streaming.SXSSFWorkbook) ? false : true
    end
  end
  #
  class Worksheet
    attr_reader :worksheet

    # create a new row with index, NO check if the row has been already created
    def new_row(index)
      Row.new(poi_worksheet.create_row(index), self)
    end
  end
end

#
module Irma
  EXCEL_SHEET_NAME_INDICE = 'Indice'.freeze
  #
  # rubocop:disable Metrics/ModuleLength
  module PoiUtil
    def string_for_cell(input_value)
      input_value.to_s.size > EXCEL_CELL_MAX_LENGTH ? (input_value.to_s[0..EXCEL_CELL_MAX_LENGTH - CELL_VALUE_DOT.size - 1] + CELL_VALUE_DOT) : input_value.to_s
    end

    def nome_sheet(nome)
      nome_s = nome
      if nome.size > EXCEL_SHEET_NAME_MAX_LENGTH
        nome_s = nome[0..(EXCEL_SHEET_NAME_MAX_LENGTH_MIDDLE - 1)] + SHEET_NAME_DOT + nome[-(EXCEL_SHEET_NAME_MAX_LENGTH_MIDDLE - SHEET_NAME_DOT.size)..-1]
      end
      nome_s
    end

    # Excel limits
    EXCEL_SHEET_NAME_MAX_LENGTH = 31
    EXCEL_SHEET_NAME_MAX_LENGTH_MIDDLE = EXCEL_SHEET_NAME_MAX_LENGTH / 2
    SHEET_NAME_DOT = '...'.freeze
    EXCEL_CELL_MAX_LENGTH = (2 << 14) - 1
    CELL_VALUE_DOT = '...'.freeze

    EXCEL_LIMIT_ROWS = (ENV['IRMA2_EXCEL_LIMIT_ROWS'] || 1_048_576).to_i
    EXCEL_LIMIT_COLUMNS = 16_384
    EXCEL_LIMIT_KEYWORD = '_#'.freeze

    EXCEL_SHEET_NAME_INDICE_ENTITA = EXCEL_SHEET_NAME_INDICE + '_Entita'
    EXCEL_SHEET_NAME_INDICE_PARAMETRI = EXCEL_SHEET_NAME_INDICE + '_Parametri'

    # restituisce il nome sheet senza l'eventuale suffisso _#n
    def base_sheet_name(nome_sheet)
      return nil unless nome_sheet
      iii = nome_sheet.index(EXCEL_LIMIT_KEYWORD)
      nome_sheet[0..iii.to_i - 1]
    end

    # restituisce il numero n dopo l'eventuale suffisso _#n, 0 altrimenti
    def sheet_name_extra_limit_index(nome_sheet)
      return 0 unless nome_sheet
      iii = nome_sheet.index(EXCEL_LIMIT_KEYWORD)
      (iii ? nome_sheet[(iii + EXCEL_LIMIT_KEYWORD.length)..-1].to_i : 0)
    end

    def next_sheet_name_extra_limit(actual_sheet_name)
      "#{base_sheet_name(actual_sheet_name)}#{EXCEL_LIMIT_KEYWORD}#{sheet_name_extra_limit_index(actual_sheet_name) + 1}"
    end

    def crea_stili(book)
      style = {}
      basic_style_opts = { font_height_in_points: 10 }
      style[:header] = book.create_style basic_style_opts.merge(color: :black, fill_foreground_color: :sky_blue, # :grey_50_percent,
                                                                fill_pattern: :solid_foreground, alignment: :align_center, vertical_alignment: :vertical_center)
      style[:left]  = book.create_style basic_style_opts.merge(alignment: :align_left)
      style[:right] = book.create_style basic_style_opts.merge(alignment: :align_right)
      style[:center] = book.create_style basic_style_opts.merge(alignment: :align_center)
      style[:hyperlink] = book.create_style basic_style_opts.merge(color: :blue, font_height_in_points: 12)
      style[:hyperlink_header] = book.create_style basic_style_opts.merge(fill_foreground_color: :sky_blue,
                                                                          fill_pattern: :solid_foreground,
                                                                          alignment: :align_center,
                                                                          vertical_alignment: :vertical_center,
                                                                          color: :blue, font_height_in_points: 12)
      style
    end

    def crea_foglio_indice_entita(ws_book, ws_sheets, ws_style, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      sheet_entita = ws_book.worksheets[EXCEL_SHEET_NAME_INDICE_ENTITA]
      sheet_entita.worksheet.java_send(:trackAllColumnsForAutoSizing) if opts[:autosize]
      create_helper = ws_book.workbook.get_creation_helper
      data_riferimento = opts[:data_riferimento]
      columns = []
      columns << 'date' if data_riferimento
      columns += %w(numero_righe full_name naming_path)
      rows = sheet_entita.rows
      ws_sheets.keys.sort.each_with_index do |sheet_name, idx|
        s_info = ws_sheets[sheet_name]
        row = rows[idx]
        # row[0].value = s_info[:numero_righe] || ''
        # row[1].value = s_info[:full_name] || ''
        # row[2].value = s_info[:naming_path] || ''
        # [1, 2].each do |xx|
        row[columns.index('date')].value         = data_riferimento if data_riferimento
        row[columns.index('numero_righe')].value = s_info[:numero_righe] || ''
        row[columns.index('full_name')].value    = s_info[:full_name] || ''
        row[columns.index('naming_path')].value  = s_info[:naming_path] || ''
        [columns.index('full_name'), columns.index('naming_path')].each do |xx|
          link = create_helper.create_hyperlink(org.apache.poi.common.usermodel.Hyperlink.LINK_DOCUMENT)
          link.set_address("'#{sheet_name}'!A1")
          row[xx].poi_cell.set_hyperlink(link)
          row[xx].style = ws_style[:hyperlink]
        end
      end
      sheet_entita.worksheet.java_send(:autoSizeColumn, [Java.int], 0) if opts[:autosize]
      sheet_entita
    end

    def crea_foglio_indice_parametri(ws_book, ws_sheets, ws_style, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      sheet_parametri = ws_book.worksheets[EXCEL_SHEET_NAME_INDICE_PARAMETRI]
      sheet_parametri.worksheet.java_send(:trackAllColumnsForAutoSizing) if opts[:autosize]
      create_helper = ws_book.workbook.get_creation_helper

      rows_info = {} # nome_param => [ [infoparam, sheet_name, naming_path], ...]
      ws_sheets.keys.sort.each do |sheet_name|
        s_info = ws_sheets[sheet_name]
        s_info[:info_header].each do |infoparam| # infoparam = [counter, nome_p, reference per hyperlink]
          rows_info[infoparam[1]] ||= []
          rows_info[infoparam[1]] << [infoparam, sheet_name, s_info[:naming_path]]
        end
      end

      data_riferimento = opts[:data_riferimento]
      columns = []
      columns << 'date' if data_riferimento
      columns += %w(counter nome_parametro sheet_name naming_path)
      rows = sheet_parametri.rows
      idx_row = 0
      rows_info.sort_by_key.each do |_nome_p, xxx|
        xxx.each do |info|
          row = rows[idx_row]
          row[columns.index('date')].value = data_riferimento if data_riferimento
          # row[0].value = info[0][0] || '' # counter
          # row[1].value = info[0][1] || '' # nome_parametro
          # row[2].value = info[1] || ''    # sheet_name
          # row[3].value = info[2] || ''    # naming_path
          # [1, 2].each do |xx|
          row[columns.index('counter')].value        = info[0][0] || '' # counter
          row[columns.index('nome_parametro')].value = info[0][1] || '' # nome_parametro
          row[columns.index('sheet_name')].value     = info[1] || ''    # sheet_name
          row[columns.index('naming_path')].value    = info[2] || ''    # naming_path
          [columns.index('nome_parametro'), columns.index('sheet_name')].each do |xx|
            link = create_helper.create_hyperlink(org.apache.poi.common.usermodel.Hyperlink.LINK_DOCUMENT)
            link.set_address("'#{info[1]}'!#{info[0][2]}") # nome param, riferimenti hyperlink
            row[xx].poi_cell.set_hyperlink(link)
            row[xx].style = ws_style[:hyperlink]
          end
          idx_row += 1
        end
      end
      sheet_parametri.worksheet.java_send(:autoSizeColumn, [Java.int], 0) if opts[:autosize]
      sheet_parametri
    end

    def add_comment(book:, sheet:, cell_row_idx:, cell_col_idx:, comment_info:) # rubocop:disable Metrics/AbcSize
      # comment_info = { text:, row2:, col2: }
      factory = book.workbook.get_creation_helper
      anchor = factory.create_client_anchor
      cell = sheet.get_row(cell_row_idx).get_cell(cell_col_idx)
      anchor.set_col1(cell.get_column_index)
      anchor.set_col2(cell.get_column_index + comment_info[:col2].to_i)
      anchor.set_row1(cell_row_idx)
      anchor.set_row2(cell_row_idx + comment_info[:row2].to_i)
      drawing = sheet.create_drawing_patriarch
      comment = drawing.createCellComment(anchor)
      comment.set_string(factory.createRichTextString(comment_info[:text]))
      cell.set_cell_comment(comment)
    end
  end

  # crea out_file oppure un file excel temporaneo e esegue lo yield con il book
  # rubocop:disable Style/ZeroLengthPredicate
  def self.export_xls(out_file = nil, &_block) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
    wb = nil
    tmp_file = out_file ? nil : Tempfile.new('export_xls')
    out_file_path = out_file || tmp_file.path
    begin
      wb = POI::Workbook.create(out_file_path)
      yield(wb)
      # un file vuoto risulta 'corrotto' in apertura, quindi creao un flglio vuoto.
      wb.create_sheet if wb.worksheets.size == 0
      wb.save
      tmp_file ? File.read(out_file_path) : true
    ensure
      wb.cleanup if wb
      if tmp_file
        tmp_file.close
        tmp_file.unlink
      end
    end
  end

  def self.export_xls_multi(out_files = [nil], &_block)  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
    return unless out_files.is_a?(Array)
    files = []
    begin
      out_files.each do |out_file|
        tmp_file = out_file ? nil : Tempfile.new('export_xls')
        out_file_path = out_file || tmp_file.path
        files << { wb: POI::Workbook.create(out_file_path), tmp_file: tmp_file, out_file_path: out_file_path }
      end
      yield(files.map { |xxx| xxx[:wb] })
      files.each do |xxx|
        xxx[:wb].save
        xxx[:tmp_file] ? File.read(xxx[:out_file_path]) : true
      end
    ensure
      files.each do |xxx|
        xxx[:wb].cleanup if xxx[:wb]
        tf = xxx[:tmp_file]
        if tf
          tf.close
          tf.unlink
        end
      end
    end
  end

  def self.read_xls(f, opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    options = { row_cache: 100, buffer: 4096, ignored_sheets: [EXCEL_SHEET_NAME_INDICE] }.merge(opts)
    is = workbook = nil
    is = java.io.FileInputStream.new(f)
    workbook = com.monitorjbl.xlsx.StreamingReader.builder.rowCacheSize(options[:row_cache]).bufferSize(options[:buffer]).open(is)
    workbook.iterator.each do |sheet|
      sheet_name = sheet.get_sheet_name
      # next if options[:ignored_sheets].include?(sheet_name)
      next if sheet_name.start_with?(*options[:ignored_sheets])
      header_size = nil
      sheet.iterator.each_with_index do |row, row_idx|
        record = Array.new(header_size.to_i)
        row.get_cell_map.each do |pos, cell|
          record[pos] = cell.get_string_cell_value
        end
        header_size ||= record.size
        yield(sheet_name, row_idx, record)
      end
    end
    true
  ensure
    workbook.close if workbook
    is.close if is
  end
end
