# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20180413
#

require 'irma/conteggio_eccezioni_util'

module Irma
  #
  # CODE
  #
  CONSISTENCY_CHECK_SINTESI_KEYWORD = 'sintesi'.freeze
  CONSISTENCY_CHECK_NOT_AVAILABLE   = 'N/A'.freeze

  class SintesiConsistencyCheck # rubocop:disable Metrics/ClassLength
    include ConteggioEccezioniUtil

    # l'ordine dei campi viene mantenuto nell'output nel formato xlsx
    CAMPI = [
      CAMPO_DATA_REPORT     = 'Data Report'.freeze,
      CAMPO_NOA             = 'NOA'.freeze,
      CAMPO_REGIONE         = 'Regione'.freeze,
      CAMPO_SISTEMA         = 'Sistema'.freeze,
      CAMPO_VENDOR          = 'Vendor'.freeze,
      CAMPO_OMC             = 'OMC/VendorRelease'.freeze,
      CAMPO_CELLE           = 'Celle'.freeze,
      CAMPO_CELLE_FILTRATE  = 'Celle filtrate'.freeze,
      CAMPO_SEGNALAZIONI    = 'Segnalazioni'.freeze,
      CAMPO_DISALLINEAMENTI = 'Disallineamenti'.freeze,
      CAMPO_DISALLINEAMENTI_PRIORITARI = 'Disallineamenti Prioritari'.freeze,
      CAMPO_ECCEZIONI       = 'Eccezioni'.freeze,
      CAMPO_ECCEZIONI_NETTE = 'Eccezioni Nette'.freeze
    ].freeze

    CAMPO_ECCEZIONI_PER_LABEL  = 'eccezioni_per_label'.freeze
    CAMPO_SEPARATORE_ECCEZIONI = '    '.freeze
    CAMPO_EXTRA_FILTRO_RELEASE = 'Filtro Release'.freeze

    # DATE_REPORT_FORMAT = '%d/%m/%Y'.freeze

    attr_reader :attivita, :attivita_root

    def initialize(attivita_id:)
      @attivita_id = attivita_id
      @attivita = Db::Attivita.first(id: @attivita_id) || raise("Nessuna attività definita con id '#{@attivita_id}'")
      @attivita_root = Db::Attivita.first(id: attivita.root_id, pid: nil) || raise("Nessuna attività root con id '#{attivita.root_id}' definita per l'attività con id '#{@attivita_id}'")
      @book = nil
    end

    def sistema_id
      @sistema_id ||= attivita.info_comando && (idx = attivita.info_comando.index('--omc_id')) && attivita.info_comando[idx + 1].to_i
    end

    # il metamodello che serve e' una versione ridotta contiene solo i parametri con flag is_to_export
    #  naming_path_1 => { mp_1_1 => true, mp_1_2 => true, ... }, naming_path_2 => { mp_2_1 => true, ... }
    def metamodello
      @metamodello ||= begin
                         s = Db::Sistema.get_by_pk(sistema_id)
                         raise "Nessun sistema definito con id #{sistema_id}" unless s
                         mp = {}
                         s.metamodello.meta_parametri.each do |naming_path, parametri|
                           mp[naming_path] = {}
                           parametri.each { |name, v| mp[naming_path][name] = true if v.is_to_export }
                         end
                         mp
                       end
    end

    def valore_per_confronto(v)
      if v.is_a?(Array)
        vals = v.map { |x| x.to_s.empty? ? nil : x }
        uv = vals.compact.uniq
        (uv.size <= 1 && uv.first.to_s.empty?) ? REP_COMP_KEY_ASSENTE : vals
      else
        v.to_s.empty? ? REP_COMP_KEY_ASSENTE : v
      end
    end

    def disallineamenti_export_rc(nome_report_comparativo)
      xxx = Command.process([Constant.info(:comando, COMANDO_EXPORT_RC_TOT)[:command],
                             '--account_id', @attivita.account_id || -1,
                             '--attivita_id', @attivita.id,
                             '--tipo_export', TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE,
                             '--cc_mode', 'true',
                             '--solo_counters', 'true',
                             '--solo_prioritari', 'false',
                             '--report_comparativo_nome', nome_report_comparativo], logger: Command.logger)
      return CONSISTENCY_CHECK_NOT_AVAILABLE unless xxx && xxx[:result] && xxx[:result][:cc_diff]
      xxx[:result][:cc_diff]
    end

    def disallineamenti(nome_report_comparativo) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
      rc = Db::ReportComparativo.first(nome: nome_report_comparativo)
      return CONSISTENCY_CHECK_NOT_AVAILABLE unless rc

      n_diff = 0
      rc.transaction do
        rc.entita.dataset.where(esito_diff: REP_COMP_ESITO_DIFFERENZE).select(:naming_path, :fonte_1, :fonte_2).each do |record|
          mm_np = metamodello[record[:naming_path]]
          p_fonte_1 = record[:fonte_1]['parametri'] || {}
          (record[:fonte_2]['parametri'] || {}).each do |mp_nome, value|
            next unless mm_np[mp_nome]
            v1 = valore_per_confronto(p_fonte_1[mp_nome])
            v2 = valore_per_confronto(value)
            n_diff += 1 if (v2 != REP_COMP_KEY_ASSENTE) && (v2 != v1)
          end
        end
      end
      n_diff
    end

    # ritorna l'hash dei CAMPI avvalorato con i valori del risultato di un consistency check
    def genera_sintesi(pi_res:, rc_res:, date: Time.now) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      ccr_pi = (pi_res || {}).stringify_keys(true)
      pi_stats = (ccr_pi['result'] && ccr_pi['result']['stats']) || {}
      ccr_rc = (rc_res || {}).stringify_keys(true)
      nome_report_comparativo = ccr_rc['nome_report_comparativo']
      sistema = Db::Sistema.get_by_pk(sistema_id)
      disall = disallineamenti_export_rc(nome_report_comparativo)
      res = {
        CAMPO_DATA_REPORT     => date.strftime(DATE_REPORT_FORMAT),
        CAMPO_ECCEZIONI       => eccezioni_totali(conters_per_etichetta: pi_stats['eccezioni_parametri_per_sintesi']) || 0,
        CAMPO_ECCEZIONI_NETTE => eccezioni_nette(conters_per_etichetta: pi_stats['eccezioni_parametri_per_sintesi']) || 0,
        CAMPO_ECCEZIONI_PER_LABEL => pi_stats['eccezioni_parametri_per_sintesi'],
        CAMPO_CELLE           => pi_stats['celle_da_calcolare'] || 0,
        CAMPO_SEGNALAZIONI    => Db::Segnalazione.where(attivita_id: attivita.id).exclude(tipo_segnalazione_id: TIPO_SEGNALAZIONE_GENERICA).count,
        CAMPO_NOA             => sistema && sistema.noa.first,
        CAMPO_SISTEMA         => sistema && sistema.rete.nome, # anche se il campo sembra essere il sistema, si ritorna la rete
        CAMPO_VENDOR          => sistema && sistema.vendor.nome.capitalize,
        CAMPO_OMC             => sistema && sistema.full_descr,
        CAMPO_DISALLINEAMENTI => disall['tot'].nil? ? NOT_AVAILABLE_STR : disall['tot'],
        CAMPO_DISALLINEAMENTI_PRIORITARI => disall['prio'].nil? ? NOT_AVAILABLE_STR : disall['prio'],
        CAMPO_CELLE_FILTRATE => pi_stats['celle_filtrate'] || 0
      }
      res[CAMPO_REGIONE] = sistema && (sistema.regioni || []).map do |regione|
        AnagraficaTerritoriale.info_regione(regione)[:label_scc] || regione
      end.sort.join('-')

      res[CAMPO_EXTRA_FILTRO_RELEASE] = sistema && sistema.vendor_release.cc_filtro_release
      res
    end

    # genera il file xls con i record avvalorati dai valori del risultato[CONSISTENCY_CHECK_SINTESI_KEYWORD] di ciascuna attivita' figlia della root
    def crea_xlsx(file:, sheet_name: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      Irma.export_xls(file) do |xls_book|
        sintesi_results = []
        Db::Attivita.where(root_id: attivita_root.id).order(:id).each do |att|
          next unless (sintesi = att.risultato && att.risultato['result'] && att.risultato['result'][CONSISTENCY_CHECK_SINTESI_KEYWORD])
          sintesi_results << sintesi
        end
        colonne_labels_eccezioni = []
        sintesi_results.each { |sss| colonne_labels_eccezioni |= (sss[CAMPO_ECCEZIONI_PER_LABEL] || {}).keys }

        header = CAMPI + [CAMPO_SEPARATORE_ECCEZIONI] + colonne_labels_eccezioni

        @book = xls_book
        @sheet = @book.worksheets[sheet_name || Time.now.strftime('%d-%m-%Y')]
        @sheet.worksheet.java_send(:trackAllColumnsForAutoSizing)
        crea_stili_xlsx
        @riga = -1
        add_row(campi: header, header: true)
        filtri_release = {}

        sintesi_results.each do |result|
          valori = result.select { |k, _v| CAMPI.include?(k) }
          valori[CAMPO_SEPARATORE_ECCEZIONI] = CAMPO_SEPARATORE_ECCEZIONI
          colonne_labels_eccezioni.each { |lbl| valori[lbl] = result[CAMPO_ECCEZIONI_PER_LABEL][lbl] || 0 }

          add_row(campi: header, values: valori)
          filtri_release[result[CAMPO_OMC]] = result[CAMPO_EXTRA_FILTRO_RELEASE]
        end

        header.size.times { |idx| @sheet.worksheet.java_send(:autoSizeColumn, [Java.int], idx) }

        # sheet per version_da_escludere
        aggiungi_foglio_con_filtro_release(filtri_release)
      end
    end

    def file_cc_filtro_parametri(out_dir: nil) # rubocop:disable Metrics/AbcSize
      res_file = []
      sistemi = []
      Db::Attivita.where(root_id: attivita_root.id).order(:id).each do |att|
        sistemi << (att.info_comando && (idx = att.info_comando.index('--omc_id')) && att.info_comando[idx + 1].to_i)
      end
      sistemi.compact.each do |s_id|
        sistema = Db::Sistema.get_by_pk(s_id)
        res_file << sistema.vendor_release.extract_file_cc_filtro_parametri(out_dir: out_dir)
      end
      res_file.compact
    end

    def aggiungi_foglio_con_filtro_release(filtro_release) # rubocop:disable Metrics/AbcSize
      @sheet = @book.worksheets["#{CAMPO_EXTRA_FILTRO_RELEASE} #{Time.now.strftime('%d-%m-%Y')}"]
      @riga = -1
      (filtro_release || {}).each do |omc, releases|
        @riga += 1
        row = @sheet.new_row(@riga)
        row[0].value = omc
        (releases || []).each_with_index do |c, idx|
          row[idx + 1].value = c
          row[idx + 1].style = @style[:right]
        end
      end
    end

    def crea_stili_xlsx # rubocop:disable Metrics/AbcSize
      @style = {}
      basic_style_opts = { font_height_in_points: 10 }
      @style[:header] = @book.create_style basic_style_opts.merge(color: :black, fill_foreground_color: :sky_blue,
                                                                  fill_pattern: :solid_foreground,
                                                                  alignment: :align_center, vertical_alignment: :vertical_center)
      @style[:left]  = @book.create_style basic_style_opts.merge(alignment: :align_left)
      @style[:right] = @book.create_style basic_style_opts.merge(alignment: :align_right)
      @style[:center] = @book.create_style basic_style_opts.merge(alignment: :align_center)
      @style[:hyperlink] = @book.create_style basic_style_opts.merge(color: :blue, font_height_in_points: 12)
      @style[:date] = @book.create_style(basic_style_opts)
      @style[:date].set_data_format(@book.get_creation_helper.create_data_format.getFormat('dd/MM/yyyy').to_java(:short))
    end

    def add_row(campi:, values: {}, header: false)
      @riga += 1
      row = @sheet.new_row(@riga)
      campi.each_with_index do |c, idx|
        row[idx].value = header ? c : (v = values[c])
        row[idx].style = if header
                           @style[:header]
                         elsif c == CAMPO_DATA_REPORT
                           @style[:date]
                         else
                           @style[(v.to_i.to_s == v.to_s) ? :right : :left]
                         end
      end
    end
  end
end
