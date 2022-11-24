# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20161025
#

module Irma
  #
  module XlsUtil
    # opzioni
    AUTOSIZE = false
    REORDER_SHEETS = true
    INDEX_SHEET = true

    FONTI = [FONTE_1 = '1'.freeze, FONTE_2 = '2'.freeze].freeze
    TIPI_BOOK = [TIPO_BOOK_ENTITA = 'entita'.freeze, TIPO_BOOK_PARAMETRI = 'parametri'.freeze].freeze
  end

  #
  module Funzioni
    #
    class ExportReportComparativo
      #
      # rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      module Formatter
        def self.with(type, type_export, opts, &block)
          formatter = nil
          formatter = class_eval(type_export.to_s.camelize + type.to_s.capitalize).new(**opts)
          formatter.inizia(&block)
          formatter
        ensure
          formatter.termina if formatter
        end

        #
        class Base
          attr_reader :out_dir, :data_rif_ymd, :logger, :log_prefix, :stat

          def initialize(out_dir:, data_riferimento:, **opts)
            raise "#{self} inizialize: output directory '#{out_dir}' non esistente" unless File.directory?(out_dir)
            @out_dir = out_dir
            @data_rif_ymd = (data_riferimento || Time.now).strftime('%Y%m%d')
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

          def nuova_meta_entita(_hash)
            raise "#{self}#nuova_meta_entita non implementato"
          end

          def scrivi_entita(_hash)
            raise "#{self}#scrivi_entita non implementato"
          end

          def nome_file_export_rc(meta_entita, parametro = nil)
            [meta_entita.nome, meta_entita.id, parametro].compact.join('_')
          end

          # comuni a formatter per Export FU
          def hdr_meta_entita(meta_entita:, parametro: nil, con_version: false)
            x = meta_entita.naming_path.split(NAMING_PATH_SEP)
            if parametro
              x << TEXT_VERSION_ENTITA if con_version
              x << parametro
            end
            x
          end

          def campi_entita(dist_name)
            dist_name.split(DIST_NAME_SEP).map { |p| p.split(DIST_NAME_VALUE_SEP)[1] }
          end
        end

        #-------------------------------------------------------------------------------------------
        #
        class ExportRcTotaleXls < Base
          require 'irma/poi'
          include Irma::PoiUtil
          include XlsUtil

          HDR_CAMPI_ENTITA = [:esito_diff, :meta_entita, :valore_entita, :extra_name, :dist_name].freeze

          attr_reader :books, :filtro_parametri, :meta_entita

          def reset_per_meta_entita(hash = {})
            TIPI_BOOK.each do |tipo|
              @books[tipo][:x_sheet] = nil
              @books[tipo][:x_riga] = nil
              @books[tipo][:x_rows] = nil
            end
            @meta_entita = hash[:meta_entita]
            @contatori = hash[:contatori]
          end

          def reset(full: true)
            if full
              @books = {}
              @stat = {}
              TIPI_BOOK.each do |tipo|
                @stat[tipo] = { num_meta_entita: 0, num_rows: 0 } # ???
                @books[tipo] = { x_book: nil, x_nome_file: nil, x_style: {},
                                 x_sheet_info: {}, x_sheet: nil, x_riga: nil, x_header: nil }
                @books[tipo][:x_nome_file] = File.join(out_dir, "#{tipo.camelize}_#{data_rif_ymd}.xlsx")
              end
            end
            reset_per_meta_entita
          end

          def post_processing_sheet
            # aggiorno numero_righe a sheet_info
            TIPI_BOOK.each do |tipo|
              next if @books[tipo][:x_sheet_info].nil? || @books[tipo][:x_sheet].nil? || @books[tipo][:x_sheet_info][@books[tipo][:x_sheet].name].nil?
              righe_hdr = tipo == TIPO_BOOK_PARAMETRI ? 3 : 1
              @books[tipo][:x_sheet_info][@books[tipo][:x_sheet].name][:numero_righe] = @books[tipo][:x_riga] - righe_hdr

              fissi = @books[tipo][:x_header][:campi_fissi].count
              @books[tipo][:x_sheet_info][@books[tipo][:x_sheet].name][:info_header] = []
              @books[tipo][:x_header][:campi_param].each_with_index do |nome_param, idx|
                # next if nome_param == RECORD_FIELD_VERSION
                xxx = [@books[tipo][:x_header][:contatori_parametri][nome_param], # counter parametro
                       nome_param,                                                # nome parametro
                       "R1C#{fissi + idx * 2 + 1}"]                               # coordinate cella per hyperlink
                @books[tipo][:x_sheet_info][@books[tipo][:x_sheet].name][:info_header] << xxx
              end
            end
          end

          def calcola_header(tipo)
            campi_fissi = if tipo == TIPO_BOOK_ENTITA
                            HDR_CAMPI_ENTITA.dup + RECORD_FIELDS_FONTE.map(&:to_sym)
                          else
                            HDR_CAMPI_ENTITA.dup[1..-1]
                          end
            @books[tipo][:x_header] = { campi_fissi: campi_fissi, campi_param: [], contatori_parametri: {} }
            return if tipo == TIPO_BOOK_ENTITA

            version   = @contatori[:parametri][RECORD_FIELD_VERSION].to_i
            parametri = @contatori[:parametri].select { |k, v| v > 0 && k != RECORD_FIELD_VERSION }
            counter = {}
            hhh = version > 0 ? [RECORD_FIELD_VERSION] : []
            counter[RECORD_FIELD_VERSION] = version if version > 0
            parametri.each do |param, cnt|
              next if cnt == 0
              hhh << param
              counter[param] = cnt
            end
            @books[tipo][:x_header][:campi_param] = hhh
            @books[tipo][:x_header][:contatori_parametri] = counter
          end

          def scrivi_header(tipo)
            if tipo == TIPO_BOOK_ENTITA
              scrivi_header_presenti_assenti
            else
              scrivi_header_differenti
            end
          end

          def scrivi_header_presenti_assenti
            tipo = TIPO_BOOK_ENTITA
            row = @books[tipo][:x_sheet].new_row(@books[tipo][:x_riga])
            @books[tipo][:x_riga] += 1
            @books[tipo][:x_header][:campi_fissi].each.with_index do |h_elem, idx|
              row[idx].value = string_for_cell(h_elem.to_s)
              row[idx].style = @books[tipo][:x_style][:header]
            end
            # freezePanel
            @books[tipo][:x_sheet].worksheet.java_send(:createFreezePane, [Java.int, Java.int], @books[tipo][:x_header][:campi_fissi].count, 1)
          end

          def scrivi_header_differenti
            tipo = TIPO_BOOK_PARAMETRI
            create_helper = @books[tipo][:x_book].workbook.get_creation_helper

            # campi fissi
            row = @books[tipo][:x_sheet].new_row(@books[tipo][:x_riga])
            idx = 0
            @books[tipo][:x_header][:campi_fissi].each_with_index do |_h_elem, iii|
              if iii == 0 # prima colonna hyperlink a 'Indice Entita'
                link = create_helper.create_hyperlink(org.apache.poi.common.usermodel.Hyperlink.LINK_DOCUMENT)
                link.set_address("'#{EXCEL_SHEET_NAME_INDICE_ENTITA}'!A1")
                row[idx].value = EXCEL_SHEET_NAME_INDICE_ENTITA
                row[idx].poi_cell.set_hyperlink(link)
                row[idx].style = @books[tipo][:x_style][:hyperlink_header]
              else
                row[idx].style = @books[tipo][:x_style][:header]
              end
              idx += 1
            end
            @books[tipo][:x_header][:campi_param].each do |h_elem|
              row[idx].value = string_for_cell(h_elem.to_s)
              row[idx].style = @books[tipo][:x_style][:header]
              @books[tipo][:x_sheet].add_merged_region(org.apache.poi.ss.util.CellRangeAddress.new(@books[tipo][:x_riga], @books[tipo][:x_riga], idx, idx + 1))
              idx += 2
            end
            @books[tipo][:x_riga] += 1

            # riga header con counters
            row = @books[tipo][:x_sheet].new_row(@books[tipo][:x_riga])
            @books[tipo][:x_riga] += 1
            idx = 0
            @books[tipo][:x_header][:campi_fissi].each_with_index do |_h_elem, iii|
              if iii == 0 # prima colonna hyperlink a 'Indice Parametri'
                link = create_helper.create_hyperlink(org.apache.poi.common.usermodel.Hyperlink.LINK_DOCUMENT)
                link.set_address("'#{EXCEL_SHEET_NAME_INDICE_PARAMETRI}'!A1")
                row[idx].value = EXCEL_SHEET_NAME_INDICE_PARAMETRI
                row[idx].poi_cell.set_hyperlink(link)
                row[idx].style = @books[tipo][:x_style][:hyperlink_header]
              else
                row[idx].style = @books[tipo][:x_style][:header]
              end
              idx += 1
            end
            @books[tipo][:x_header][:campi_param].each do |h_elem|
              row[idx].value = string_for_cell("(#{@books[tipo][:x_header][:contatori_parametri][h_elem]})")
              row[idx].style = @books[tipo][:x_style][:header]
              @books[tipo][:x_sheet].add_merged_region(org.apache.poi.ss.util.CellRangeAddress.new(@books[tipo][:x_riga] - 1, @books[tipo][:x_riga] - 1, idx, idx + 1))
              idx += 2
            end

            # riga header con fonte1 e fonte2
            row = @books[tipo][:x_sheet].new_row(@books[tipo][:x_riga])
            @books[tipo][:x_riga] += 1
            idx = 0
            @books[tipo][:x_header][:campi_fissi].each do |h_elem|
              row[idx].value = string_for_cell(h_elem.to_s)
              row[idx].style = @books[tipo][:x_style][:header]
              idx += 1
            end
            @books[tipo][:x_header][:campi_param].each do |_h_elem|
              2.times do |tt|
                row[idx + tt].value = string_for_cell(RECORD_FIELDS_FONTE[tt])
                row[idx + tt].style = @books[tipo][:x_style][:header]
              end
              idx += 2
            end
            # freezePane
            @books[tipo][:x_sheet].worksheet.java_send(:createFreezePane, [Java.int, Java.int], @books[tipo][:x_header][:campi_fissi].count, 3)
            # size colonna 0 sufficiente a mostrare per intero i link ai fogli indice
            @books[tipo][:x_sheet].worksheet.java_send(:setColumnWidth, [Java.int, Java.int], 0, 4500)
          end

          def nuova_meta_entita_crea_sheet?(tipo)
            if tipo == TIPO_BOOK_ENTITA
              @contatori[:num_entita] > 0
            else
              @contatori[:parametri].values.max.to_i > 0
            end
          end

          def nuova_meta_entita(hash = {})
            post_processing_sheet
            reset_per_meta_entita(hash)
            nome_sheet_full = nome_file_export_rc(@meta_entita)
            nome_s = nome_sheet(nome_sheet_full)
            TIPI_BOOK.each do |tipo|
              next unless nuova_meta_entita_crea_sheet?(tipo)
              @books[tipo][:x_sheet] = @books[tipo][:x_book].worksheets[nome_s]
              @books[tipo][:x_sheet].worksheet.java_send(:trackAllColumnsForAutoSizing) if AUTOSIZE # && @book.autosize_available?
              @books[tipo][:x_riga] = 0
              # header
              @books[tipo][:x_header] = nil
              calcola_header(tipo)

              @books[tipo][:x_sheet_info][nome_s] = {
                naming_path: @meta_entita.naming_path,
                numero_colonne: @books[tipo][:x_header][:campi_fissi].count + @books[tipo][:x_header][:campi_param].count * 2,
                numero_righe: 0,
                info_header: {},
                full_name: nome_sheet_full
              }
              scrivi_header(tipo)
              @stat[tipo][:num_meta_entita] += 1
            end
            logger.info("#{log_prefix}: creazione nuovi sheets #{nome_s}")
          end

          def determina_fonte_1(esito)
            # [REP_COMP_ESITO_ASSENTE_2, REP_COMP_ESITO_UGUALE].include?(esito) ? REP_COMP_KEY_PRESENTE : REP_COMP_KEY_ASSENTE
            esito == REP_COMP_ESITO_ASSENTE_1 ? REP_COMP_KEY_ASSENTE : REP_COMP_KEY_PRESENTE
          end

          def determina_fonte_2(esito)
            # [REP_COMP_ESITO_ASSENTE_1, REP_COMP_ESITO_UGUALE].include?(esito) ? REP_COMP_KEY_PRESENTE : REP_COMP_KEY_ASSENTE
            esito == REP_COMP_ESITO_ASSENTE_2 ? REP_COMP_KEY_ASSENTE : REP_COMP_KEY_PRESENTE
          end

          def scrivi_entita(hash)
            record = hash[:record]
            record_info = hash[:record_info]
            tipo = if record_info[:entita_da_scrivere]
                     TIPO_BOOK_ENTITA
                   elsif record_info[:differenze_da_scrivere]
                     TIPO_BOOK_PARAMETRI
                   end
            return unless tipo

            row = @books[tipo][:x_sheet].new_row(@books[tipo][:x_riga])
            @books[tipo][:x_riga] += 1
            idx = 0
            @books[tipo][:x_header][:campi_fissi].each do |h_elem|
              vvv = h_elem == :esito_diff ? Constant.label(:rep_comp_esito, record[h_elem.to_sym]) : record[h_elem.to_sym]
              vvv = determina_fonte_1(record[:esito_diff]) if h_elem == RECORD_FIELDS_FONTE[0].to_sym
              vvv = determina_fonte_2(record[:esito_diff]) if h_elem == RECORD_FIELDS_FONTE[1].to_sym
              row[idx].value = string_for_cell(vvv)
              idx += 1
            end

            if tipo == TIPO_BOOK_PARAMETRI
              @books[tipo][:x_header][:campi_param].each do |h_elem|
                f = record_info[:parametri][h_elem] || [nil, nil]
                diff = (f[0] != f[1])
                2.times do |tt|
                  row[idx + tt].value = string_for_cell((diff ? f[tt] : ''))
                end
                idx += 2
              end
            end
            @stat[tipo][:num_rows] += 1
          end

          def inizia(&_block)
            reset
            nomi_file = []
            TIPI_BOOK.each do |tipo|
              nomi_file << @books[tipo][:x_nome_file]
            end
            logger.info("#{log_prefix}: creazione nuovi file #{nomi_file.join(',')}")
            Irma.export_xls_multi(nomi_file) do |xls_books|
              idx = 0
              TIPI_BOOK.each do |tipo|
                @books[tipo][:x_book] = xls_books[idx]
                idx += 1
                @books[tipo][:x_style] = crea_stili(@books[tipo][:x_book])
              end
              yield(self)
              post_processing_sheet

              sheet_index_e = nil
              sheet_index_p = nil
              if INDEX_SHEET
                TIPI_BOOK.each do |tipo|
                  logger.info("#{log_prefix}: inserimento dati terminato, creazione fogli indice di #{@books[tipo][:x_nome_file]} (#{@stat[tipo]})")
                  sheet_index_e = crea_foglio_indice_entita(@books[tipo][:x_book], @books[tipo][:x_sheet_info], @books[tipo][:x_style], data_riferimento: data_rif_ymd)
                  @books[tipo][:x_book].set_sheet_order(sheet_index_e.name, 0)
                  if tipo == TIPO_BOOK_PARAMETRI
                    sheet_index_p = crea_foglio_indice_parametri(@books[tipo][:x_book], @books[tipo][:x_sheet_info], @books[tipo][:x_style], data_riferimento: data_rif_ymd)
                    @books[tipo][:x_book].set_sheet_order(sheet_index_p.name, 1)
                  end
                end
              end

              if REORDER_SHEETS
                TIPI_BOOK.each do |tipo|
                  logger.info("#{log_prefix}: inserimento dati terminato, riordinamento alfabetico degli sheet di #{@books[tipo][:x_nome_file]} (#{@stat[tipo]})")
                  shift_idx = if tipo == TIPO_BOOK_PARAMETRI
                                (sheet_index_e ? 1 : 0) + (sheet_index_p ? 1 : 0)
                              else
                                (sheet_index_e ? 1 : 0)
                              end
                  @books[tipo][:x_sheet_info].keys.sort.each.with_index do |sheet_name, iii|
                    @books[tipo][:x_book].set_sheet_order(sheet_name, iii + shift_idx)
                  end
                end
              end
              if AUTOSIZE # && @book.autosize_available?
                TIPI_BOOK.each do |tipo|
                  logger.info("#{log_prefix}: inserimento dati terminato, autosizing delle colonne degli sheet di #{@books[tipo][:x_nome_file]} (#{@stat[tipo]})")
                  @books[tipo][:x_sheet_info].each do |s_name, s_info|
                    s = @books[tipo][:x_book].get_sheet(s_name)
                    next unless s
                    s_info[:numero_colonne].to_i.times do |iii|
                      s.java_send(:autoSizeColumn, [Java.int, Java.boolean], iii, true)
                    end
                  end
                end
              end

              TIPI_BOOK.each do |tipo|
                # per evitare fogli 'grouped'
                @books[tipo][:x_book].worksheets.each do |s|
                  s.worksheet.java_send(:setSelected, [Java.boolean], false)
                end
                @books[tipo][:x_book].set_active_sheet(0) if @books[tipo][:x_book].worksheets.count > 0
              end
              sheet_index_e = nil
              sheet_index_p = nil
            end
          end

          def termina
            reset(full: false)
          end
        end
        #-------------------------------------------------------------------------------------------
        #
        class ExportRcFormatoUtenteTxt < Base
          attr_reader :entita_fd
          attr_reader :fd

          def inizia(&_block)
            reset
            yield(self)
          end

          def reset_per_meta_entita
            RECORD_FIELDS_FONTE.each do |fonte|
              @entita_fd[fonte].close if @entita_fd[fonte]
              @entita_fd[fonte] = nil
              @fd[fonte].each { |_k, v| v.close if v }
              @entita_fd[fonte] = nil
              @fd[fonte] = {}
            end
          end

          def reset(full: true)
            if full
              @entita_fd = {}
              @fd = {}
              @stat = {}
              RECORD_FIELDS_FONTE.each do |fonte|
                @stat[fonte] = { num_files_entita: 0, num_files_param: 0 }
                @fd[fonte] = {}
                @entita_fd[fonte] = nil
              end
            end
            reset_per_meta_entita
          end

          def termina
            reset(full: false)
          end

          def nuova_meta_entita(hash = {})
            contatori = hash[:contatori]
            meta_entita = hash[:meta_entita]
            reset_per_meta_entita
            RECORD_FIELDS_FONTE.each.with_index do |fonte, idx|
              @entita_fd[fonte] ||= open_file_export(meta_entita, idx + 1) if contatori[:num_entita][fonte] > 0
              # version = contatori[:parametri][fonte][RECORD_FIELD_VERSION] > 0
              version = hash[:con_version]
              contatori[:parametri][fonte].each do |param, cnt|
                next if cnt == 0 || param == RECORD_FIELD_VERSION
                nome_param = param.split('.').first
                @fd[fonte][param] ||= open_file_export(meta_entita, idx + 1, con_version: version, nome: nome_param, hdr: param)
              end
            end
          end

          def nome_file_export_entita(meta_entita, idx, parametro = nil)
            sub_dir_tipologia = parametro.nil? ? NOME_SUB_DIR_ENTITA : NOME_SUB_DIR_PARAMETRI
            File.join(out_dir, "#{NOME_SUBDIR_FONTE}#{idx}_#{data_rif_ymd}", "#{sub_dir_tipologia}_#{data_rif_ymd}", "#{nome_file_export_rc(meta_entita, parametro)}.txt")
          end

          def open_file_export(meta_entita, idx, parametro = {})
            fd_ret = File.open(nome_file_export_entita(meta_entita, idx, parametro[:nome]), 'a')
            fd_ret.puts hdr_meta_entita(meta_entita: meta_entita, con_version: parametro[:con_version], parametro: parametro[:hdr]).join(TEXT_HEADER_ROW_SEP)
            @stat[RECORD_FIELDS_FONTE[idx - 1]][parametro.empty? ? :num_files_param : :num_files_entita] += 1
            fd_ret
          end

          def scrivi_entita(hash)
            record = hash[:record]
            record_info = hash[:record_info]
            con_version = hash[:con_version]

            entita = campi_entita(record[:dist_name])
            RECORD_FIELDS_FONTE.each do |fonte|
              next unless record_info[:entita_da_scrivere][fonte] || record_info[:differenze_da_scrivere][fonte]
              if record_info[:entita_da_scrivere][fonte]
                @entita_fd[fonte].puts entita.join(TEXT_DATA_ROW_SEP)
              end
              version   = record_info[:parametri][fonte][RECORD_FIELD_VERSION]
              parametri = record_info[:parametri][fonte].select { |k, _v| k != RECORD_FIELD_VERSION }
              @fd[fonte].each do |param, fd|
                val = parametri[param]
                next unless val
                xx = entita.dup
                xx << (version || '') if con_version
                xx << val.to_s
                fd.puts xx.join(TEXT_DATA_ROW_SEP)
              end
            end # end fonte
          end
        end
        #-------------------------------------------------------------------------------------------
        #
        class ExportRcFormatoUtenteXls < Base
          require 'irma/poi'
          include Irma::PoiUtil
          include XlsUtil

          def scrivi_riga(fonte:, tipo:, valori:, stile: nil)
            row = @books[fonte][tipo][:x_sheet].new_row(@books[fonte][tipo][:x_riga])
            @books[fonte][tipo][:x_riga] += 1
            valori.each.with_index do |xxx, idx_row|
              row[idx_row].value = string_for_cell(xxx)
              row[idx_row].style = stile if stile
            end
          end

          def calcola_header(fonte, tipo, con_version) # filtro_parametri: [p_a, p_b,...,s.p1&s.p2&...&s.pn,...]
            @books[fonte][tipo][:x_header] = { campi_fissi: hdr_meta_entita(meta_entita: @meta_entita), campi_param: [], contatori_parametri: {} }
            field_fonte = RECORD_FIELDS_FONTE[fonte.to_i - 1]
            if tipo == TIPO_BOOK_PARAMETRI
              version   = @contatori[:parametri][field_fonte][RECORD_FIELD_VERSION].to_i
              parametri = @contatori[:parametri][field_fonte].select { |k, v| v > 0 && k != RECORD_FIELD_VERSION }
              counter = {}
              # hhh = version > 0 ? [RECORD_FIELD_VERSION] : []
              hhh = con_version ? [RECORD_FIELD_VERSION] : []
              counter[RECORD_FIELD_VERSION] = version # if version > 0
              parametri.each do |param, cnt|
                next if cnt == 0
                hhh << param
                counter[param] = cnt
              end
              @books[fonte][tipo][:x_header][:campi_param] = hhh
              @books[fonte][tipo][:x_header][:contatori_parametri] = counter
            end
            @books[fonte][tipo][:x_header]
          end

          def nuova_meta_entita_crea_sheet?(fonte, tipo)
            if tipo == TIPO_BOOK_ENTITA
              @contatori[:num_entita][fonte] > 0
            else
              @contatori[:parametri][fonte].values.max.to_i > 0
            end
          end

          def nuova_meta_entita(hash = {})
            con_version = hash[:con_version]
            post_processing_sheet
            reset_per_meta_entita(hash)
            FONTI.each do |fonte|
              TIPI_BOOK.each do |tipo|
                next unless nuova_meta_entita_crea_sheet?(RECORD_FIELDS_FONTE[fonte.to_i - 1], tipo)
                nome_full = nome_file_export_rc(@meta_entita)
                nome = nome_sheet(nome_full)
                @books[fonte][tipo][:x_sheet] = @books[fonte][tipo][:x_book].worksheets[nome]
                @books[fonte][tipo][:x_riga] = 0

                @books[fonte][tipo][:x_sheet_info][nome] = { naming_path: @meta_entita.naming_path,
                                                             numero_righe: 0,
                                                             info_header: {},
                                                             full_name: nome_full }
                @books[fonte][tipo][:x_sheet].java_send(:trackAllColumnsForAutoSizing) if AUTOSIZE && @books[fonte][tipo][:x_book].autosize_available?
                hdr = calcola_header(fonte, tipo, con_version)
                labels_hdr = hdr[:campi_param].dup
                labels_hdr[0] = TEXT_VERSION_ENTITA if labels_hdr[0] == RECORD_FIELD_VERSION
                # scrivi_header_fu(fonte: fonte, tipo: tipo, valori: hdr[:campi_fissi] + labels_hdr)
                scrivi_riga(fonte: fonte, tipo: tipo, valori: hdr[:campi_fissi] + labels_hdr, stile: @books[fonte][tipo][:x_style][:header])
                # freezePanel
                @books[fonte][tipo][:x_sheet].worksheet.java_send(:createFreezePane, [Java.int, Java.int], hdr[:campi_fissi].count, 1)
              end
            end
          end

          def _scrivi_header_fu(fonte:, tipo:, valori:)
            # -- if tipo == TIPO_BOOK_PARAMETRI
            create_helper = @books[fonte][tipo][:x_book].workbook.get_creation_helper
            [EXCEL_SHEET_NAME_INDICE_ENTITA, EXCEL_SHEET_NAME_INDICE_PARAMETRI].each do |indice|
              row = @books[fonte][tipo][:x_sheet].new_row(@books[fonte][tipo][:x_riga])
              @books[fonte][tipo][:x_riga] += 1
              valori.each.with_index do |_xxx, idx_row|
                if idx_row == 0 && (tipo == TIPO_BOOK_PARAMETRI || (tipo == TIPO_BOOK_ENTITA && indice == EXCEL_SHEET_NAME_INDICE_ENTITA))
                  link = create_helper.create_hyperlink(org.apache.poi.common.usermodel.Hyperlink.LINK_DOCUMENT)
                  link.set_address("'#{indice}'!A1")
                  row[idx_row].value = indice
                  row[idx_row].poi_cell.set_hyperlink(link)
                  row[idx_row].style = @books[fonte][tipo][:x_style][:hyperlink_header]
                else
                  row[idx_row].style = @books[fonte][tipo][:x_style][:header]
                end
              end
            end
            # -- end
            scrivi_riga(fonte: fonte, tipo: tipo, valori: valori, stile: @books[fonte][tipo][:x_style][:header])
            # size colonna 0 sufficiente a mostrare per intero i link ai fogli indice
            @books[fonte][tipo][:x_sheet].worksheet.java_send(:setColumnWidth, [Java.int, Java.int], 0, 4500) # if tipo == TIPO_BOOK_PARAMETRI
            # freezePanel
            @books[fonte][tipo][:x_sheet].worksheet.java_send(:createFreezePane, [Java.int, Java.int], 0, 3)
          end

          def scrivi_entita(hash)
            record = hash[:record]
            record_info = hash[:record_info]
            FONTI.each do |fonte|
              field_fonte = RECORD_FIELDS_FONTE[fonte.to_i - 1]
              tipo = if record_info[:entita_da_scrivere][field_fonte]
                       TIPO_BOOK_ENTITA
                     elsif record_info[:differenze_da_scrivere][field_fonte]
                       TIPO_BOOK_PARAMETRI
                     end
              next unless tipo
              valori = campi_entita(record[:dist_name])
              if tipo == TIPO_BOOK_PARAMETRI
                @books[fonte][tipo][:x_header][:campi_param].each do |h_elem|
                  valori << record_info[:parametri][field_fonte][h_elem] || '' # TODO: Controllare questa stringa vuota !!!
                end
              end
              scrivi_riga(fonte: fonte, tipo: tipo, valori: valori)
              @stat[fonte][:num_entita] += 1
            end # end fonte
          end

          def reset_per_meta_entita(hash = {})
            FONTI.each do |fonte|
              TIPI_BOOK.each do |tipo|
                @books[fonte][tipo][:x_sheet] = nil
                @books[fonte][tipo][:x_riga] = nil
                @books[fonte][tipo][:x_rows] = nil
              end
            end
            @meta_entita = hash[:meta_entita]
            @contatori = hash[:contatori]
            @campi_param = []
          end

          def reset(full: true)
            if full
              @books = {}
              @stat = {}
              FONTI.each do |fonte|
                @stat[fonte] = { num_entita: 0 }
                @books[fonte] = {}
                TIPI_BOOK.each { |tipo| @books[fonte][tipo] = { x_book: nil, x_nome_file: nil, x_style: {}, x_sheet_info: {}, x_sheet: nil, x_riga: nil, x_header: nil } }
              end
              FONTI.each do |fonte|
                TIPI_BOOK.each do |tipo|
                  @books[fonte][tipo][:x_nome_file] = File.join(out_dir, "#{NOME_SUBDIR_FONTE}#{fonte}_#{tipo.camelize}_#{data_rif_ymd}.xlsx")
                end
              end
            end
            reset_per_meta_entita
          end

          def inizia(&_block)
            reset

            nomi_file = []
            FONTI.each do |fonte|
              TIPI_BOOK.each do |tipo|
                nomi_file << @books[fonte][tipo][:x_nome_file]
              end
            end
            logger.info("#{log_prefix}: creazione nuovi file #{nomi_file.join(',')} (#{stat})")
            Irma.export_xls_multi(nomi_file) do |xls_books|
              idx = 0
              FONTI.each do |fonte|
                TIPI_BOOK.each do |tipo|
                  @books[fonte][tipo][:x_book] = xls_books[idx]
                  idx += 1
                  @books[fonte][tipo][:x_style] = crea_stili(@books[fonte][tipo][:x_book])
                end
              end
              yield(self)
              post_processing_sheet
              sheet_index_e = nil
              sheet_index_p = nil
              if INDEX_SHEET
                FONTI.each do |fonte|
                  TIPI_BOOK.each do |tipo|
                    logger.info("#{log_prefix}: inserimento dati terminato, creazione del foglio indice di #{@books[fonte][tipo][:x_nome_file]}")
                    sheet_index_e = crea_foglio_indice_entita(@books[fonte][tipo][:x_book], @books[fonte][tipo][:x_sheet_info], @books[fonte][tipo][:x_style], data_riferimento: data_rif_ymd)
                    @books[fonte][tipo][:x_book].set_sheet_order(sheet_index_e.name, 0)
                    # per evitare fogli 'grouped'
                    @books[fonte][tipo][:x_book].worksheets.each do |s|
                      s.worksheet.java_send(:setSelected, [Java.boolean], false)
                    end
                    @books[fonte][tipo][:x_book].set_active_sheet(0)  if @books[fonte][tipo][:x_book].worksheets.count > 0
                    if tipo == TIPO_BOOK_PARAMETRI
                      sheet_index_p = crea_foglio_indice_parametri(@books[fonte][tipo][:x_book], @books[fonte][tipo][:x_sheet_info], @books[fonte][tipo][:x_style], data_riferimento: data_rif_ymd)
                      @books[fonte][tipo][:x_book].set_sheet_order(sheet_index_p.name, 1)
                    end
                  end
                end
              end
            end
          end

          def post_processing_sheet
            # aggiorno numero_righe a sheet_info
            FONTI.each do |fonte|
              TIPI_BOOK.each do |tipo|
                next if @books[fonte][tipo][:x_sheet_info].nil? || @books[fonte][tipo][:x_sheet].nil? || @books[fonte][tipo][:x_sheet_info][@books[fonte][tipo][:x_sheet].name].nil?
                righe_hdr = 1 # tipo == TIPO_BOOK_PARAMETRI ? 3 : 1
                @books[fonte][tipo][:x_sheet_info][@books[fonte][tipo][:x_sheet].name][:numero_righe] = @books[fonte][tipo][:x_riga] - righe_hdr
                @books[fonte][tipo][:x_sheet_info][@books[fonte][tipo][:x_sheet].name][:info_header] = []
                fissi = @books[fonte][tipo][:x_header][:campi_fissi].count
                @books[fonte][tipo][:x_header][:campi_param].each_with_index do |nome_param, idx|
                  next if nome_param == RECORD_FIELD_VERSION
                  xxx = [@books[fonte][tipo][:x_header][:contatori_parametri][nome_param], # counter parametro
                         nome_param,                                                       # nome parametro
                         "R#{righe_hdr}C#{fissi + idx + 1}"]                               # coordinate cella per hyperlink
                  @books[fonte][tipo][:x_sheet_info][@books[fonte][tipo][:x_sheet].name][:info_header] << xxx
                end
              end
            end
          end

          def termina
            reset(full: false)
          end
        end
        #-------------------------------------------------------------------------------------------
      end
    end
  end
end
