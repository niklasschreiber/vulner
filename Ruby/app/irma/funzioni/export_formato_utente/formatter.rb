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
    class ExportFormatoUtente
      #
      module Formatter
        def self.with(type, opts, &block)
          formatter = nil
          formatter = class_eval(type.to_s.capitalize).new(**opts)
          formatter.inizia(&block)
          formatter
        ensure
          formatter.termina if formatter
        end

        #
        class Base
          attr_reader :out_dir, :logger, :log_prefix, :suffisso_nome_file, :stat

          def initialize(out_dir:, **opts)
            raise "#{self} inizialize: output directory '#{out_dir}' non esistente" unless File.directory?(out_dir)
            @out_dir = out_dir
            @logger = opts[:logger] || Irma.logger
            @log_prefix = opts[:log_prefix]
            @suffisso_nome_file = opts[:suffisso_nome_file]
            @solo_header = opts[:solo_header]
            @indice_etichette = opts[:indice_etichette]
            @info_etichette = []
            reset(full: true)
          end

          def reset(full: true); end

          def inizia(&_block)
            raise "#{self}#processa non implementato"
          end

          def termina(&_block)
            raise "#{self}#termina non implementato"
          end

          def nuova_meta_entita(*)
            raise "#{self}#nuova_meta_entita non implementato"
          end

          def nuovi_parametri(_parametri)
            raise "#{self}#nuovi_parametri non implementato"
          end

          def aggiorna_info_etichette(info)
            @info_etichette = info
          end
        end

        #
        class Txt < Base
          attr_reader :fd

          def inizia(&_block)
            yield(self)
          end

          def reset(full: true)
            @fd.close if @fd
            @stat = { num_files: 0, num_records: 0 } if full
            @fd = nil
          end

          def termina
            reset(full: false)
          end

          def nuova_meta_entita(meta_entita:, header:, **_opts) # rubocop:disable Metrics/AbcSize
            @fd.close if @fd
            @fd = File.open(nome_file = nome_file_export_meta_entita(meta_entita), 'a')
            numero_file_creati = 0
            if File.size(nome_file).zero?
              @fd.puts header.join(TEXT_HEADER_ROW_SEP)
              stat[:num_files] += 1
              logger.info("#{log_prefix}: creazione nuovo file #{nome_file} (#{stat})")
              numero_file_creati = 1
            else
              logger.info("#{log_prefix}: apertura file già creato #{nome_file} (#{stat})")
            end
            numero_file_creati
          end

          def nuovi_parametri(parametri)
            numero_record = 0
            if @fd
              stat[:num_records] += 1
              @fd.puts parametri.join(TEXT_DATA_ROW_SEP)
              numero_record = 1
            end
            numero_record
          end

          # private

          def nome_file_export_meta_entita(meta_entita)
            File.join(out_dir, [meta_entita.nome, @suffisso_nome_file, meta_entita.id].compact.join('_') + '.txt')
          end
        end

        #
        class Xls < Base # rubocop:disable Metrics/ClassLength
          require 'irma/poi'
          include Irma::PoiUtil
          attr_reader :book, :style, :sheet, :rows, :riga, :sheet_info, :stat
          # opzioni
          AUTOSIZE = false
          REORDER_SHEETS = true
          INDEX_SHEET = true

          def reset(full: true)
            @book = @style = @sheet = @rows = @riga = nil
            @stat = { num_sheets: 0, num_rows: 0 } if full
            @sheet_info = {}
          end

          def inizia(&_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
            reset
            logger.info("#{log_prefix}: creazione nuovo file #{nome_file} (#{stat})")
            Irma.export_xls(nome_file) do |xls_book|
              @book = xls_book
              @style = crea_stili(@book)
              yield(self)
              post_processing_sheet if @sheet && @riga

              sheet_index_e = nil
              sheet_index_p = nil
              sheet_index_l = nil

              if INDEX_SHEET
                logger.info("#{log_prefix}: inserimento dati terminato, creazione del foglio indice di #{nome_file} (#{stat})")
                sheet_index_e = crea_foglio_indice_entita(@book, @sheet_info, @style, autosize: AUTOSIZE)
                @book.set_sheet_order(sheet_index_e.name, 0)
                sheet_index_p = crea_foglio_indice_parametri(@book, @sheet_info, @style, autosize: AUTOSIZE)
                @book.set_sheet_order(sheet_index_p.name, 1)
                if @indice_etichette
                  sheet_index_l = crea_foglio_indice_label(@book, @info_etichette, @style, autosize: AUTOSIZE)
                  @book.set_sheet_order(sheet_index_l.name, 2)
                end
              end

              if REORDER_SHEETS
                logger.info("#{log_prefix}: inserimento dati terminato, riordinamento alfabetico degli sheet di #{nome_file} (#{stat})")
                nomi_fogli_indice = []
                [sheet_index_e, sheet_index_p, sheet_index_l].each { |xxx| nomi_fogli_indice << xxx.name if xxx }
                # @sheet_info.keys.sort.each_with_index do |sheet_name, idx|
                (@book.worksheets.map(&:name) - nomi_fogli_indice).sort.each_with_index do |sheet_name, idx|
                  @book.set_sheet_order(sheet_name, idx + (sheet_index_e ? 1 : 0) + (sheet_index_p ? 1 : 0) + (sheet_index_l ? 1 : 0))
                end
              end

              # per evitare fogli 'grouped'
              @book.worksheets.each do |s|
                s.worksheet.java_send(:setSelected, [Java.boolean], false)
              end
              @book.set_active_sheet(0) if @book.worksheets.count > 0

              if AUTOSIZE && @book.autosize_available?
                logger.info("#{log_prefix}: inserimento dati terminato, autosizing delle colonne degli sheet di #{nome_file} (#{stat})")
                @book.worksheets.each do |s|
                  @sheet_info[s.name][:header].each_with_index do |_val, idx|
                    s.worksheet.java_send(:autoSizeColumn, [Java.int], idx)
                  end
                end
              end
              sheet_index_e = nil
              sheet_index_p = nil
              sheet_index_l = nil
            end
          end

          EXCEL_SHEET_NAME_INDICE_INFO_ETICHETTE = EXCEL_SHEET_NAME_INDICE + '_Etichette'
          def crea_foglio_indice_label(ws_book, info, ws_style, opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
            sheet_info_etichette = ws_book.worksheets[EXCEL_SHEET_NAME_INDICE_INFO_ETICHETTE]
            sheet_info_etichette.worksheet.java_send(:trackAllColumnsForAutoSizing) if opts[:autosize]
            columns = %w(Entita Parametro Etichetta)
            rows = sheet_info_etichette.rows
            row = rows[0]
            columns.each.with_index do |col, idx|
              row[idx].style = ws_style[:header]
              row[idx].value = col
            end
            num_row = 0
            info.each do |dn, info_dn|
              info_dn.each do |label, param_list|
                param_list.each do |param|
                  num_row += 1
                  row = rows[num_row]
                  row[0].value = dn || ''
                  row[1].value = param || ''
                  row[2].value = label || ''
                end
              end
            end
            sheet_info_etichette.worksheet.java_send(:autoSizeColumn, [Java.int], 0) if opts[:autosize]
            sheet_info_etichette
          end

          def termina
            reset(full: false)
          end

          def post_processing_sheet
            num_righe = (@riga + 1) - num_righe_header
            @sheet_info[base_sheet_name(@sheet.name)][:numero_righe] += num_righe
          end

          def num_righe_header
            1 # @solo_header ? 1 : 3
          end

          # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          def nuova_meta_entita(meta_entita:, header:, header_campi_param:, contatori:)
            post_processing_sheet if @sheet && @riga
            numero_sheet = 0
            nome_sheet = nil
            begin
              contatori ||= {}
              nome_sheet_full = nome_sheet_meta_entita(meta_entita)
              nome_sheet = nome_sheet(nome_sheet_full)
              if @book && @sheet_info[nome_sheet].nil?
                @me_level = meta_entita.livello
                nuovo_sheet(nome_sheet: nome_sheet)

                hhh = []
                fissi = header.count - header_campi_param.count
                header_campi_param.each_with_index do |nome_ppp, iii|
                  hhh << [contatori[nome_ppp] || '', nome_ppp, "R#{num_righe_header}C#{fissi + iii + 1}"]
                end
                @sheet_info[@sheet.name] = { naming_path: meta_entita.naming_path,
                                             info_header: hhh,
                                             numero_righe: 0,
                                             full_name: nome_sheet_full }
                @header_val = header
                scrivi_header

                stat[:num_sheets] += 1
                logger.info("#{log_prefix}: creazione nuovo sheet #{nome_sheet} (#{stat})")
                numero_sheet = 1
              else
                logger.info("#{log_prefix}: riutilizzato lo sheet per #{nome_sheet} (#{stat})")
              end
            rescue => e
              logger.error("#{log_prefix}: creazione nuovo sheet #{nome_sheet} fallita: #{e}, #{e.backtrace}")
              raise e
            end
            numero_sheet
          end

          def nuovo_sheet(nome_sheet:)
            @sheet = @book.worksheets[nome_sheet]
            @sheet.worksheet.java_send(:trackAllColumnsForAutoSizing) if AUTOSIZE && @book.autosize_available?
            # freeze the first columns related with meta_entita elements...
            @sheet.worksheet.java_send(:createFreezePane, [Java.int, Java.int], @me_level || 0, num_righe_header)
            # size colonna 0 sufficiente a mostrare per intero i link ai fogli indice
            @sheet.worksheet.java_send(:setColumnWidth, [Java.int, Java.int], 0, 4500)
            @riga = 0
          end

          def scrivi_header
            row = @sheet.new_row(@riga)
            @header_val.each_with_index do |v, idx|
              row[idx].value = string_for_cell(v.to_s)
              row[idx].style = style[:header]
            end
          end

          def nuova_riga_parametri(parametri)
            if @riga + 1 >= EXCEL_LIMIT_ROWS
              post_processing_sheet
              nuovo_sheet(nome_sheet: next_sheet_name_extra_limit(@sheet.name))
              scrivi_header
            end
            @riga += 1
            row = @sheet.new_row(@riga)
            parametri.each_with_index do |v, idx|
              row[idx].value = string_for_cell(v.to_s)
            end
          end

          def nuovi_parametri(parametri)
            numero_record = 0
            if @riga
              nuova_riga_parametri(parametri)
              stat[:num_rows] += 1
              numero_record = 1
            end
            numero_record
          end

          # private

          def nome_file
            File.join(out_dir, suffisso_nome_file + '.xlsx')
          end

          def nome_sheet_meta_entita(meta_entita)
            [meta_entita.nome, meta_entita.id].compact.join('_')
          end
        end
      end
    end
  end
end
