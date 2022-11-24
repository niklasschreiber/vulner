# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20161114
#
require_relative 'segnalazioni_per_funzione'
require 'irma/poi'
require 'irma/conteggio_eccezioni_util'

# rubocop:disable Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
module Irma
  #
  module Funzioni
    class ConteggioAlberature
      include Irma::PoiUtil
      include SegnalazioniPerFunzione
      include ConteggioEccezioniUtil

      attr_reader :logger, :log_prefix, :stats
      attr_reader :cache_conteggi, :cache_eccezioni, :cache_sistemi, :cache_rc
      attr_reader :filtro_metamodello

      def initialize(**opts)
        @stats              = nil
        @logger             = opts[:logger] || Irma.logger
        @log_prefix         = opts[:log_prefix] || 'Conteggio alberature'
        @np_alberatura      = opts[:np_alberatura]
        @filtro_metamodello = opts[:filtro_metamodello]
        @lista_rc_id        = opts[:lista_rc_id]
        # output
        @out_file           = opts[:out_file]
        @out_file_filtro    = opts[:out_file_filtro]
        # strutture d'appoggio
        @conteggi_alberatura_rc = nil
        @cache_conteggi  = {}
        @cache_eccezioni = {}
        @labels_eccezioni = {}
        @cache_sistemi   = {}
        @cache_rc        = {}
      end

      #--------------------------------------------------------
      def reset_cache
        @cache_eccezioni = {}
        @labels_eccezioni = {}
        @cache_conteggi  = {}
        @cache_sistemi   = {}
        @cache_rc        = {}
      end

      def prepara_lista_report_comparativi(lista_rc_id)
        reset_cache
        rc_id_inesistenti = []
        rc_id_no_omc_logico = []

        (lista_rc_id || []).each do |rc_id|
          rc_id = rc_id.to_i
          rc_obj = Db::ReportComparativo.first(id: rc_id)
          unless rc_obj
            rc_id_inesistenti << rc_id
            next
          end
          s_id = rc_obj.sistema_id || (rc_obj.info && rc_obj.info['pi_sistema_id'])
          s_obj = Db::Sistema.first(id: s_id) if s_id
          unless s_obj
            rc_id_no_omc_logico << rc_id
            next
          end
          s_obj = Db::Sistema.first(id: s_id)
          @cache_sistemi[s_id] = s_obj
          @cache_rc[rc_id] = { obj: rc_obj, sistema: s_obj }
        end
        nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_DATI_RC_INESISTENTI, lista_rc: rc_id_inesistenti.join(',')) unless rc_id_inesistenti.empty?
        nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_DATI_RC_NO_OMC_LOGICO, lista_rc: rc_id_no_omc_logico.join(',')) unless rc_id_no_omc_logico.empty?
        nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_DATI_NO_RC_OK, lista_rc: (lista_rc_id || []).join(',')) if @cache_rc.empty?
      end

      def conteggio_alberatura_rc(report_comparativo)
        result_attivita_conteggio_rc if @conteggi_alberatura_rc.nil?
        @conteggi_alberatura_rc[report_comparativo.nome]
      end

      include SharedFs::Util
      def result_attivita_conteggio_rc
        @conteggi_alberatura_rc = {}
        contenitore_id = Db::Attivita.first(id: @attivita_id).pid
        return @conteggi_alberatura_rc unless contenitore_id
        Db::Attivita.where(pid: contenitore_id).order(:id).each do |att|
          # next unless (file_conteggi = att.risultato && att.risultato['result'] && att.risultato['result'][CONTEGGIO_ALBERATURA_RC_KEYWORD])
          next unless (file_conteggi = att.risultato && att.risultato[CONTEGGIO_ALBERATURA_RC_KEYWORD])
          rc_nome = (att.info_comando && (idx = att.info_comando.index('--report_comparativo_nome')) && att.info_comando[idx + 1].to_s)
          next unless rc_nome
          conteggi = {}
          file_ccc = absolute_file_path(file_conteggi || '')
          if File.exist?(file_ccc)
            Irma.processa_file_per_linea(file_ccc, suffix: 'parse_csv') do |line, _n|
              line.chomp!
              pzs = Hash[CAMPI_FILE_CONTEGGIO_ALBERATURA_RC.zip(line.split(SEP_FILE_CONTEGGIO_ALBERATURA_RC))]
              conteggi[pzs['np']] ||= {}
              conteggi[pzs['np']][pzs['dn']] = { 'tot' => pzs['tot'].to_i, 'prio' => pzs['prio'].to_i }
            end
          end
          @conteggi_alberatura_rc[rc_nome] = conteggi
        end
      end

      def aggiorna_cache_conteggio_rc(rc_id:, counters_rc:)
        sistema = @cache_sistemi[@cache_rc[rc_id][:sistema].id]
        key_rv = sistema.sigla_retevendor
        @cache_conteggi[key_rv] ||= {}
        @cache_eccezioni[sistema.id] ||= {}
        @labels_eccezioni[key_rv] ||= {}
        counters_rc.each do |np, cntrs|
          @cache_conteggi[key_rv][np] ||= {}
          @cache_eccezioni[sistema.id][np] ||= {}
          @labels_eccezioni[key_rv][np] ||= []
          cntrs.each do |dn_entita, disall|
            @cache_conteggi[key_rv][np][dn_entita] ||= []
            @cache_conteggi[key_rv][np][dn_entita] << { rc_id: rc_id, tot: disall['tot'], prio: disall['prio'] }
            @cache_eccezioni[sistema.id][np][dn_entita] = {}
          end
        end
      end

      def aggiorna_cache_conteggio_eccez(sistema_id:, counters_eccez:)
        # counters_eccez = { np => { dn1 => {'label1' => 10, 'label2' => 79, ...}, dn1 => {'label1' => 16,...} }, ...}
        return if (@cache_eccezioni[sistema_id] || {}).empty?
        key_rv = @cache_sistemi[sistema_id].sigla_retevendor
        @cache_eccezioni[sistema_id].each do |np, np_info|
          np_info.keys.each do |dn|
            @cache_eccezioni[sistema_id][np][dn] = if counters_eccez.nil?
                                                     # c'e' stato un errore in conteggio_eccezioni
                                                     nil
                                                   elsif counters_eccez[np] && counters_eccez[np][dn]
                                                     # conteggio_eccezioni eseguito correttamente e ho un counter per dn
                                                     @labels_eccezioni[key_rv][np] |= counters_eccez[np][dn].keys
                                                     counters_eccez[np][dn]
                                                   else
                                                     # conteggio_eccezioni eseguito correttamente nessuna eccezione presente per dn
                                                     {}
                                                   end
          end
        end
      end

      def add_row(style:, fields_keys:, values: {}, header: false)
        if @riga + 1 >= EXCEL_LIMIT_ROWS
          sn = @sheet.name
          nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_DATI_SUPERATO_EXCEL_LIMIT_ROWS, book_name: File.basename(@book.filename), sheet_name: sn) unless sn.index(EXCEL_LIMIT_KEYWORD)
          @sheet = @book.worksheets[next_sheet_name_extra_limit(sn)]
          @riga = -1
        end
        @riga += 1
        row = @sheet.new_row(@riga)
        (fields_keys || []).each_with_index do |c, idx|
          row[idx].value = values[c] || ''
          row[idx].style = if header
                             style[:header]
                           elsif c == CAMPO_DATA_RC
                             style[:date]
                           else
                             style[values[c].to_s.numeric? ? :right : :left]
                           end
        end
      end

      def valore_na(val)
        (val.nil? || val == -1) ? NOT_AVAILABLE_STR : val
      end

      def nome_foglio_me(me_nome, rete_vendor, used)
        used ||= {}
        nome = "#{rete_vendor}-#{me_nome}"
        ret = if used[nome].nil?
                used[nome] = 0
                nome
              else
                "#{nome}-#{used[nome]}"
              end
        used[nome] += 1
        ret
      end

      def load_extra_name_from_rc(naming_path)
        res = {}
        @cache_rc.each do |rc_id, rc|
          rc_obj = rc[:obj]
          rc_obj.entita.dataset.where(naming_path: naming_path).where('extra_name is not null').select_map([:dist_name, :extra_name]).each do |record|
            res[rc_id] ||= {}
            res[rc_id][record[0]] = record[1]
          end
        end
        res
      end

      CAMPI_CONTEGGIO = {
        CAMPO_DATA_RC              = :campo_data_rc              => 'Data Generazione Report'.freeze,
        CAMPO_SISTEMA              = :campo_sistema              => 'Sistema'.freeze,
        CAMPO_NAME                 = :campo_name                 => 'Nome'.freeze,
        CAMPO_EXTRA_NAME           = :campo_extra_name           => 'Nome Extra'.freeze,
        CAMPO_DISALLINEAMENTI      = :campo_disallineamenti      => 'Disallineamenti'.freeze,
        CAMPO_DISALLINEAMENTI_PRIO = :campo_disallineamenti_prio => 'Disallineamenti prioritari'.freeze,
        CAMPO_ECCEZIONI            = :campo_eccezioni            => 'Eccezioni'.freeze,
        CAMPO_ECCEZIONI_NETTE      = :campo_eccezioni_nette      => 'Eccezioni nette'.freeze,
        CAMPO_RC                   = :campo_rc                   => 'Report Comparativo'.freeze,
        CAMPO_SEPARATORE_ECCEZIONI = :campo_separatore_eccezioni => VALORE_CAMPO_SEPARATORE,
        CAMPO_SEPARATORE_NP        = :campo_separatore_np        => VALORE_CAMPO_SEPARATORE
      }.freeze

      def scrivi_file_conteggio(file:)
        Irma.export_xls(file) do |xls_book|
          nomi_meta_entita = {}
          @book = xls_book
          stili = crea_stili(@book)
          @cache_conteggi.each do |rete_vendor, dati_np|
            dati_np.each do |np, dati_dn|
              # nuovo sheet rete:vendor:naming_path
              meta_entita = np.split(NAMING_PATH_SEP).last
              @sheet = @book.worksheets[nome_sheet(nome_foglio_me(meta_entita, rete_vendor, nomi_meta_entita))]
              # @sheet.worksheet.java_send(:trackAllColumnsForAutoSizing)
              @riga = -1
              extra_names = load_extra_name_from_rc(np)

              campi_labels_eccezioni = [NO_LABEL] + @labels_eccezioni[rete_vendor][np].sort
              campi_pezzi_np = np.split(NAMING_PATH_SEP)

              hash_hdr = {}
              CAMPI_CONTEGGIO.each do |k, titolo|
                hash_hdr[k] = titolo
                if k == CAMPO_SEPARATORE_ECCEZIONI
                  campi_labels_eccezioni.each { |label| hash_hdr["#{PREFIX_ECCEZ}_#{label}"] = label }
                elsif k == CAMPO_SEPARATORE_NP
                  campi_pezzi_np.each.with_index { |v, idx| hash_hdr["#{PREFIX_NP}_#{idx}"] = v }
                end
              end
              add_row(style: stili, fields_keys: hash_hdr.keys, values: hash_hdr, header: true)

              righe_da_scrivere = []
              dati_dn.each do |dn, array_info|
                array_info.each do |info|
                  rc      = @cache_rc[info[:rc_id]][:obj]
                  sistema = @cache_rc[info[:rc_id]][:sistema]
                  eccez = (ces = @cache_eccezioni[sistema.id]) && ces[np] && ces[np][dn]
                  valori_hash = {
                    CAMPO_EXTRA_NAME       => valore_na((extra_names[rc.id] || {})[dn]),
                    CAMPO_NAME             => dn.split(DIST_NAME_VALUE_SEP).last,
                    CAMPO_SISTEMA          => sistema.full_descr,
                    CAMPO_DISALLINEAMENTI  => valore_na(info[:tot]),
                    CAMPO_DISALLINEAMENTI_PRIO => valore_na(info[:prio]),
                    CAMPO_DATA_RC          => rc.created_at.strftime(DATE_REPORT_FORMAT),
                    CAMPO_RC               => rc.nome,
                    CAMPO_ECCEZIONI        => (eccez && eccezioni_totali(conters_per_etichetta: eccez)) || 0,
                    CAMPO_ECCEZIONI_NETTE  => (eccez && eccezioni_nette(conters_per_etichetta: eccez, labels_nette: @labels_nette)) || 0,
                    CAMPO_SEPARATORE_ECCEZIONI => '',
                    CAMPO_SEPARATORE_NP => ''
                  }
                  campi_labels_eccezioni.each do |label|
                    valori_hash["#{PREFIX_ECCEZ}_#{label}"] = (eccez && eccez[label]) || 0
                  end
                  pezzi_dn = dn.split(DIST_NAME_SEP).map { |el| el.split(DIST_NAME_VALUE_SEP).fetch(1) }
                  campi_pezzi_np.each.with_index do |_v, idx|
                    valori_hash["#{PREFIX_NP}_#{idx}"] = pezzi_dn[idx]
                  end
                  righe_da_scrivere << valori_hash
                end
              end
              righe_da_scrivere.sort_by { |x| x[CAMPO_DISALLINEAMENTI] }.reverse_each do |vals_hash|
                add_row(style: stili, fields_keys: hash_hdr.keys, values: vals_hash)
              end
              # hash_hdr.keys.size.times { |idx| @sheet.worksheet.java_send(:autoSizeColumn, [Java.int], idx) }
              @cache_conteggi[rete_vendor][np] = nil unless @out_file_filtro # per liberare memoria....
            end
          end
        end
      end

      def scrivi_file_filtro(file:)
        Irma.export_xls(file) do |xls_book|
          nomi_meta_entita = {}
          @book = xls_book
          stili = crea_stili(@book)
          @cache_conteggi.each do |rete_vendor, dati_np|
            dati_np.each do |np, dati_dn|
              next if (dati_dn || {}).empty? # non creo sheet se non c'e' nessuna entita da scrivere
              # nuovo sheet rete:vendor:naming_path
              pezzi_np = np.split(NAMING_PATH_SEP)
              meta_entita = pezzi_np.last
              @sheet = @book.worksheets[nome_sheet(nome_foglio_me(meta_entita, rete_vendor, nomi_meta_entita))]
              # @sheet.worksheet.java_send(:trackAllColumnsForAutoSizing)
              @riga = -1
              hash_hdr = {}
              pezzi_np.each.with_index { |v, idx| hash_hdr["#{PREFIX_NP}_#{idx}"] = v }
              add_row(style: stili, fields_keys: hash_hdr.keys, values: hash_hdr, header: true)
              dati_dn.keys.each do |dn|
                pezzi_dn = dn.split(DIST_NAME_SEP).map { |el| el.split(DIST_NAME_VALUE_SEP).fetch(1) }
                vals = {}
                pezzi_np.each.with_index do |_v, idx|
                  vals["#{PREFIX_NP}_#{idx}"] = pezzi_dn[idx]
                end
                add_row(style: stili, fields_keys: hash_hdr.keys, values: vals)
              end
              # pezzi_np.size.times { |idx| @sheet.worksheet.java_send(:autoSizeColumn, [Java.int], idx) }
            end
          end
        end
      end

      def conteggio_eccezioni(sistema:)
        entita_per_np = @cache_eccezioni[sistema.id]
        res = {}
        entita_per_np.each do |np, np_info|
          res[np] = conteggio_eccezioni_per_etichetta(sistema: sistema, dist_name: np_info.keys, filtro_metamodello: filtro_metamodello, np_root: np)
        end
        res
      end

      def esegui_conteggi_rc(res)
        tot_rows = 0
        @cache_rc.each do |rc_id, rc|
          rc_obj = rc[:obj]
          res[rc_obj.nome] = { num_entita_root_per_np: {} }
          cnt_alb = conteggio_alberatura_rc(rc_obj)
          unless cnt_alb
            nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_DATI_ERRORE_CONTEGGIO_RC, nome_rc: rc_obj.nome)
            next
          end
          cnt_alb.each do |k, v|
            tot_rows += v.size
            res[rc_obj.nome][:num_entita_root_per_np][k] = v.size
          end
          aggiorna_cache_conteggio_rc(rc_id: rc_id, counters_rc: cnt_alb)
        end
        tot_rows
      end

      def esegui_conteggi_eccezioni
        # Eccezioni
        @labels_nette = Db::EtichettaEccezioni.load_hash_labels_nette
        @cache_sistemi.each do |s_id, s_obj|
          begin
            cnt_eccez = conteggio_eccezioni(sistema: s_obj)
          rescue => e
            cnt_eccez = nil
            nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_DATI_ERRORE_CONTEGGIO_ECCEZ, sistema: s_obj.full_descr, msg: e.message)
          end
          next unless cnt_eccez
          aggiorna_cache_conteggio_eccez(sistema_id: s_id, counters_eccez: cnt_eccez)
        end
      end
      #--------------------------------------------------------

      def esegui(**opts)
        res = {}
        funzione = Db::Funzione.get_by_pk(FUNZIONE_CONTEGGIO_ALBERATURE)
        @account = Db::Account.first(id: opts[:account_id])
        @attivita_id = opts[:attivita_id]

        con_segnalazioni(funzione: funzione, account: @account, attivita_id: opts[:attivita_id]) do
          reset_cache
          prepara_lista_report_comparativi(@lista_rc_id)
          next res if (@cache_rc || {}).empty?
          res[:report_comparativi_analizzati] = @cache_rc.size
          res_c_rc = esegui_conteggi_rc(res)
          next res if res_c_rc < 0
          esegui_conteggi_eccezioni
          scrivi_file_conteggio(file: @out_file)
          scrivi_file_filtro(file: @out_file_filtro) if @out_file_filtro
          res
        end # con_segnalazioni
        res
      end
    end
  end
end
