# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini, G. Cristelli
#
# Creation date: 20160401
#

require_relative 'segnalazioni_per_funzione'
require_relative 'export_report_comparativo/formatter'
require 'irma/filtro_entita_util'

module Irma
  #
  module Funzioni
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
    #
    class ExportReportComparativo # rubocop:disable Metrics/ClassLength
      include SegnalazioniPerFunzione
      include FiltroEntitaUtil

      FORMATTERS = Formatter::Base.descendants.map { |k| k.to_s.split(':').last.downcase }
      RECORD_FONTE_1 = RECORD_FIELDS_FONTE[0]
      RECORD_FONTE_2 = RECORD_FIELDS_FONTE[1]

      attr_reader :logger, :report_comparativo, :metamodello, :filtro_cc_parametri, :filtro_metamodello, :tipo_export, :log_prefix
      attr_reader :data_riferimento, :solo_prioritari
      attr_reader :flag_presente, :con_version, :dist_assente_vuoto, :only_to_export_param, :nascondi_assente_f1, :nascondi_assente_f2

      def initialize(report_comparativo:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        raise ArgumentError, "Parametro report_comparativo '#{report_comparativo}' non valido" unless report_comparativo.is_a?(Db::ReportComparativo)
        @report_comparativo = report_comparativo
        @flag_presente = (report_comparativo.info || {})['flag_presente']
        @account_id = opts[:account_id] || report_comparativo.account_id
        @tipo_export = opts[:tipo_export]
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Export report comparativo totale (#{sistema_ambiente_archivio.full_descr})"
        @metamodello = opts[:metamodello]
        @filtro_metamodello = opts[:filtro_metamodello]
        @filtro_version = opts[:filtro_version] || {}
        @filtro_cc_parametri = opts[:filtro_cc_parametri] || {}
        @only_to_export_param = opts[:only_to_export_param]
        @con_version = opts[:con_version]
        @dist_assente_vuoto = opts[:dist_assente_vuoto]
        @nascondi_assente_f1 = opts[:nascondi_assente_f1]
        @nascondi_assente_f2 = opts[:nascondi_assente_f2]
        @classe_export = nil
        @np_da_considerare = nil
        @query_per_np = {}
        @solo_counters = opts[:solo_counters]
        @np_alberatura = opts[:np_alberatura] # nil oppure array di naming_path
        @solo_calcolabili = opts[:solo_calcolabili]
        @solo_prioritari = opts[:solo_prioritari]

        @data_riferimento = opts[:data_riferimento]
      end

      #
      class ExportRcBase  # rubocop:disable Metrics/ClassLength
        attr_accessor :fd_cnt_alb
        attr_reader :contatori, :metamodello, :filtro_metamodello, :filtro_cc_parametri, :solo_prioritari
        attr_reader :flag_presente, :only_to_export_param, :con_version, :dist_assente_vuoto, :nascondi_assente_f1, :nascondi_assente_f2

        SPLIT_REGEXPR = /[#{TEXT_SUB_ARRAY_ELEM_SEP},#{TEXT_ARRAY_ELEM_SEP}]/
        CHECK_ASSENTE_VUOTO = [
          [[TEXT_NO_VAL], [TEXT_PARAMETRO_ASSENTE]],
          [[''], [TEXT_PARAMETRO_ASSENTE]]
        ].freeze

        def initialize(opts)
          @contatori = {}
          @meta_parametri_info = {}

          @metamodello = opts[:metamodello]
          @filtro_metamodello = opts[:filtro_metamodello]
          @filtro_cc_parametri = opts[:filtro_cc_parametri]
          @only_to_export_param = opts[:only_to_export_param]
          @con_version = opts[:con_version]
          @flag_presente = opts[:flag_presente]
          @dist_assente_vuoto = opts[:dist_assente_vuoto]
          @nascondi_assente_f1 = opts[:nascondi_assente_f1]
          @nascondi_assente_f2 = opts[:nascondi_assente_f2]
          @solo_calcolabili = opts[:solo_calcolabili]
          @solo_prioritari = opts[:solo_prioritari]
        end

        # ---
        def parametro_da_scartare?(param, filtro)
          !filtro.member?(param) && filtro.select { |xxx| param.start_with?(xxx.split(TEXT_STRUCT_NAME_SEP).first + TEXT_STRUCT_NAME_SEP) }.empty?
        end

        # in caso di parametri strutturati, return true se almeno uno is_to_export=true
        def parametro_to_export?(naming_path, array_param)
          ret = false
          array_param.each do |vvv|
            return true if metamodello.meta_parametri[naming_path][vvv] && metamodello.meta_parametri[naming_path][vvv].is_to_export
          end
          ret
        end

        # in caso di parametri strutturati, return true se almeno uno is_prioritario=true
        def parametro_prioritario?(naming_path, array_param)
          ret = false
          array_param.each do |vvv|
            return true if metamodello.meta_parametri[naming_path][vvv] && metamodello.meta_parametri[naming_path][vvv].is_prioritario
          end
          ret
        end

        # ritorna in :parametri:
        # param_x => { hdr: param_x, meta_p: [param_x] } per parametri non strutturati
        # struct => { hdr: struct.p1&...&struct.pn, meta_p: [struct.p1,...struct.pn]} per parametri strutturati
        def meta_parametri_info(naming_path) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          # :flatten_keys, :parametri
          return @meta_parametri_info[naming_path] if @meta_parametri_info[naming_path]
          @meta_parametri_info[naming_path] = {}
          ret = {}
          flatten = []
          mps = metamodello.meta_parametri_fu[naming_path]
          if mps
            fm = filtro_metamodello && filtro_metamodello[naming_path] && filtro_metamodello[naming_path][FILTRO_MM_PARAMETRI]
            fm_cc = filtro_cc_parametri && filtro_cc_parametri[naming_path] && filtro_cc_parametri[naming_path][FILTRO_MM_PARAMETRI]
            mps.each do |k, v|
              next if fm && parametro_da_scartare?(k, fm)
              next if fm_cc && !parametro_da_scartare?(k, fm_cc)
              next if only_to_export_param && !parametro_to_export?(naming_path, v)
              next if solo_prioritari && !parametro_prioritario?(naming_path, v)
              ret[k.split('.'.freeze)[0]] = { hdr: k, meta_p: v }
              flatten += v
            end
          end
          @meta_parametri_info[naming_path][:parametri] = ret
          @meta_parametri_info[naming_path][:flatten_keys] = flatten.uniq
          @meta_parametri_info[naming_path]
        end

        # --- CONTATORI
        #---------------------------------
        # CONTATORI
        # @contatori = { 'naming_path' => {
        #                                   +++ TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE +++
        #                                   da_ignorare: true/false,
        #                                   num_entita: <numero entita presenti/assenti, presenti/presenti>,
        #                                   num_entita_diff: <numero entita differenti>,
        #                                   parametri: {
        #                                                    'version' => <numero di version da scrivere...>,
        #                                                    'paramX' => <numero di parametri paramX da scrivere...>,
        #                                                    'paramY' => <numero di parametri paramY da scrivere...>,
        #                                                    'structA.paramB' => <numero di parametri structA.paramB da scrivere...>,
        #                                                    'structA.paramC' => <numero di parametri structA.paramC da scrivere...>,
        #                                                  }
        #                                   +++ TIPO_EXPORT_REPORT_COMPARATIVO_FU +++
        #                                   da_ignorare: true/false,
        #                                   num_entita: { 'fonte1' => <numero entita su fonte1>,
        #                                                 'fonte2' => <numero entita su fonte2> }
        #                                   num_entita_diff: { 'fonte1' => <numero entita differenti su fonte1>,
        #                                                      'fonte2' => <numero entita differenti su fonte2> }
        #                                   parametri: { 'fonte_1' => {
        #                                                    'version' => <numero di version da scrivere...>,
        #                                                    'paramX' => <numero di parametri paramX da scrivere...>,
        #                                                    'structA.paramB&structA.paramC' => <numero di parametri structA.paramB&structA.paramC da scrivere...>,
        #                                                             },
        #                                                'fonte_2' => {
        #                                                    'version' => <numero di version da scrivere...>,
        #                                                    'paramX' => <numero di parametri paramX da scrivere...>,
        #                                                    'structA.paramB&structA.paramC' => <numero di parametri structA.paramB&structA.paramC da scrivere...>,
        #                                                             }
        #                                              }
        #                                 }
        #              }

        def reset_contatori
          @contatori = {}
        end

        def elabora_record(*)
          raise 'Metodo aggiorna_contatori da ridefinire nella sottoclasse specifica'
        end

        def parametri_entita(_record)
          raise 'Metodo parametri_entita da ridefinire nella sottoclasse specifica'
        end

        def inizializza_contatori(_naming_path)
          raise 'Metodo inizializza_contatori da ridefinire nella sottoclasse specifica'
        end

        def entita_da_scrivere(_record)
          raise 'Metodo entita_da_scrivere da ridefinire nella sottoclasse specifica'
        end

        def version_da_scrivere(record, solo_diversi = true)
          # raise 'Metodo version_da_scrivere da ridefinire nella sottoclasse specifica'
          v1 = record[RECORD_FONTE_1][RECORD_FIELD_VERSION] || TEXT_PARAMETRO_ASSENTE
          v2 = record[RECORD_FONTE_2][RECORD_FIELD_VERSION] || TEXT_PARAMETRO_ASSENTE
          if solo_diversi
            return nil if v1 == v2 # aggiungere eventuali altri casi di valori da escludere...(es: '', '<>'...???)
            return nil if nascondi_assente_f2 && parametro_assente(v2)
            return nil if nascondi_assente_f1 && parametro_assente(v1)
            return nil if  dist_assente_vuoto == false && CHECK_ASSENTE_VUOTO.include?([[v1], [v2]].sort)
          end
          [v1, v2]
        end

        def parametro_assente(val)
          # val.to_s.split(/[#{TEXT_SUB_ARRAY_ELEM_SEP},#{TEXT_ARRAY_ELEM_SEP}]/).uniq == TEXT_PARAMETRO_ASSENTE
          val.to_s == TEXT_PARAMETRO_ASSENTE
        end

        def parametro_da_scrivere(valori)
          # puts "XXXXXXXXXXX parametro_da_scrivere - valori: #{valori}"
          val1, val2 = valori
          return false if val1 == val2
          return false if nascondi_assente_f2 && parametro_assente(val2)
          return false if nascondi_assente_f1 && parametro_assente(val1)
          return true if dist_assente_vuoto
          valori_modify = []
          valori.each { |val| valori_modify << val.split(SPLIT_REGEXPR).uniq }
          xxx = valori_modify.sort
          # puts "CCCCCCCCCCC #{valori}, #{xxx}"
          return false if CHECK_ASSENTE_VUOTO.include?(xxx)
          true
        end
      end
      #
      class ExportRcFu < ExportRcBase # rubocop:disable Metrics/ClassLength
        # TIPO_EXPORT_REPORT_COMPARATIVO_FU

        def campo_parametro(mps, param)
          pezzi = mps.map do |ppp|
            param[ppp] ? MetaModello.parametro_to_s(param[ppp]) : nil
          end
          return nil if pezzi.compact.empty?
          return TEXT_PARAMETRO_ASSENTE if pezzi.uniq == [TEXT_PARAMETRO_ASSENTE]
          pezzi.join(TEXT_STRUCT_SEP)
        end

        def parametri_entita(record)
          # ritorna:
          # { nome => { hdr: nome_hdr, valori: [val 1, val 2] },...}
          # nome = nome_param_semplice/nome_struttura per parametri strutturati
          # nome_hdr = nome_param_semplice / s.p1&s.p2&... in caso di parametro strutturato
          # in ret ho solo chiave/info per i parametri che devono venire scritti su almeno una fonte
          # puts "YYYYYYYYYY entita: #{record[:dist_name]}"
          ret = {}
          naming_path = record[:naming_path]
          return ret unless record[RECORD_FONTE_1][RECORD_FIELD_PARAMETRI]
          return ret unless meta_parametri_info(naming_path)[:parametri]
          meta_parametri_info(naming_path)[:parametri].each do |key, ppp|
            # puts "XXXXXXXXXXXXXX #{key}, #{ppp}"
            valori = []
            RECORD_FIELDS_FONTE.each_with_index do |f, idx|
              val = campo_parametro(ppp[:meta_p], record[f][RECORD_FIELD_PARAMETRI])
              # puts "XXXXXXXXXXXXX #{ppp[:meta_p]}, #{record[f][RECORD_FIELD_PARAMETRI]}, #{val}"
              valori[idx] = val # (val == TEXT_PARAMETRO_ASSENTE) ? nil : val
            end
            # puts "XXXXXXXXXXXXXX parametri_entita: #{valori} --- #{parametro_da_scrivere(valori)}"
            ret[key] = { hdr: ppp[:hdr], valori: valori } if parametro_da_scrivere(valori)
          end
          ret
        end

        def inizializza_contatori(naming_path) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          return if @contatori[naming_path]
          @contatori[naming_path] = {}
          mpi = meta_parametri_info(naming_path)
          @contatori[naming_path][:num_entita] = {}
          @contatori[naming_path][:num_entita_diff] = {}
          RECORD_FIELDS_FONTE.each do |fonte|
            @contatori[naming_path][:num_entita][fonte] = 0
            @contatori[naming_path][:num_entita_diff][fonte] = 0
          end
          @contatori[naming_path][:parametri] = {}
          RECORD_FIELDS_FONTE.each { |fonte| @contatori[naming_path][:parametri][fonte] = {} }

          mpi[:parametri].map { |xxx| xxx[1][:hdr] }.each do |param|
            RECORD_FIELDS_FONTE.each { |fonte| @contatori[naming_path][:parametri][fonte][param] = 0 }
          end
          RECORD_FIELDS_FONTE.each { |fonte| @contatori[naming_path][:parametri][fonte][RECORD_FIELD_VERSION] = 0 }
          @contatori[naming_path]
        end

        def naming_path_da_ignorare(naming_path)
          return true unless @contatori[naming_path]
          return @contatori[naming_path][:da_ignorare] if @contatori[naming_path][:da_ignorare]
          cond1 = @contatori[naming_path][:num_entita][RECORD_FONTE_1] == 0 && @contatori[naming_path][:num_entita][RECORD_FONTE_2] == 0
          cond2 = @contatori[naming_path][:num_entita_diff][RECORD_FONTE_1] == 0 && @contatori[naming_path][:num_entita_diff][RECORD_FONTE_2] == 0
          @contatori[naming_path][:da_ignorare] = cond1 && cond2
        end

        def elabora_record(record:, aggiorna_contatori: nil) # rubocop:disable Metrics/MethodLength
          ret = { entita_da_scrivere: { RECORD_FONTE_1 => false, RECORD_FONTE_2 => false },
                  differenze_da_scrivere: { RECORD_FONTE_1 => false, RECORD_FONTE_2 => false },
                  parametri: { RECORD_FONTE_1 => {}, RECORD_FONTE_2 => {} } }

          # --- entita'
          x = entita_da_scrivere(record)
          RECORD_FIELDS_FONTE.each do |fonte|
            if x[fonte]
              ret[:entita_da_scrivere][fonte] = true
              @contatori[record[:naming_path]][:num_entita][fonte] += 1 if aggiorna_contatori == CNT_AGGIORNA
            end
          end

          return ret unless record[:esito_diff] == REP_COMP_ESITO_DIFFERENZE
          # --- parametri
          # { nome => { hdr: nome_hdr, valori: [val 1, val 2] },...}
          # nome = nome_param_semplice/nome_struttura per parametri strutturati
          # nome_hdr = nome_param_semplice / s.p1&s.p2&... in caso di parametro strutturato
          pe = parametri_entita(record)
          pe.each do |_param_nome, param_info|
            RECORD_FIELDS_FONTE.each.with_index do |fonte, idx|
              if param_info[:valori][idx]
                ret[:parametri][fonte][param_info[:hdr]] = param_info[:valori][idx]
                @contatori[record[:naming_path]][:parametri][fonte][param_info[:hdr]] += 1 if aggiorna_contatori == CNT_AGGIORNA
              end
            end
          end

          # --- version
          if con_version
            version_vals = version_da_scrivere(record, false)
            RECORD_FIELDS_FONTE.each.with_index do |fonte, idx|
              if ret[:parametri][fonte].keys.count > 0
                ret[:parametri][fonte][RECORD_FIELD_VERSION] = version_vals[idx]
                @contatori[record[:naming_path]][:parametri][fonte][RECORD_FIELD_VERSION] += 1 if aggiorna_contatori == CNT_AGGIORNA
              end
            end
          end
          # ------------------------------------------------------------------
          # se una entita' ha differenze, ma nessuna di queste e' da_scrivere
          # allora va inserita/conteggiata nel file entita'
          # altrimenti, nel file parametri.
          # --------------------------------------
          # 2018-01-09: cambia la logica precedente.
          #    se una entita' ha differenze e
          #           - almeno una e' "da scrivere", allora va scritta/conteggiata nel file parametri
          #           - nessuna e' "da scrivere", allora NON va scritta/conteggiata ne' nel file parametri (differenti), ne' nel file entita (presenti/assenti)
          # 2018-03-28: modifica alla logica attuale:
          #           - se nessuna e' "da scrivere", allora va trattata come un'entita' UGUALE, quindi:
          #                se nel comparativo sono incluse le entita' uguali (flag_presente: true),
          #                va scritta nel file entita', altrimenti no.
          RECORD_FIELDS_FONTE.each do |fonte|
            kkk = ret[:parametri][fonte].keys
            # if kkk.empty? || kkk == [RECORD_FIELD_VERSION]
            #   ret[:entita_da_scrivere][fonte] = true
            #   @contatori[record[:naming_path]][:num_entita][fonte] += 1 if aggiorna_contatori == CNT_AGGIORNA
            # else
            #   ret[:differenze_da_scrivere][fonte] = true
            #   @contatori[record[:naming_path]][:num_entita_diff][fonte] += 1 if aggiorna_contatori == CNT_AGGIORNA
            # end
            # --------------------------------------
            # unless kkk.empty? || kkk == [RECORD_FIELD_VERSION]
            #  ret[:differenze_da_scrivere][fonte] = true
            #  @contatori[record[:naming_path]][:num_entita_diff][fonte] += 1 if aggiorna_contatori == CNT_AGGIORNA
            # end
            # ------------------------------------------------------------------
            if kkk.empty? || kkk == [RECORD_FIELD_VERSION]
              if flag_presente
                ret[:entita_da_scrivere][fonte] = true
                @contatori[record[:naming_path]][:num_entita][fonte] += 1 if aggiorna_contatori == CNT_AGGIORNA
              end
            else
              ret[:differenze_da_scrivere][fonte] = true
              @contatori[record[:naming_path]][:num_entita_diff][fonte] += 1 if aggiorna_contatori == CNT_AGGIORNA
            end
            # ------------------------------------------------------------------
          end
          ret
        end

        def entita_da_scrivere(record)
          ret = { RECORD_FONTE_1 => false, RECORD_FONTE_2 => false }
          if record[:esito_diff] == REP_COMP_ESITO_ASSENTE_2
            ret[RECORD_FONTE_1] = true
          elsif record[:esito_diff] == REP_COMP_ESITO_ASSENTE_1
            ret[RECORD_FONTE_2] = true
          end
          ret
        end

        # FU
        def parametro_assente(val)
          val.to_s.split(TEXT_STRUCT_SEP).uniq == [TEXT_PARAMETRO_ASSENTE]
        end

        def parametro_da_scrivere(valori)
          # puts " -- FU --------- #{valori}"
          val1, val2 = valori
          return false if val1 == val2
          return false if nascondi_assente_f2 && parametro_assente(val2)
          return false if nascondi_assente_f1 && parametro_assente(val1)
          return true if dist_assente_vuoto

          valori_struct = valori.map { |vvv| vvv.split(TEXT_STRUCT_SEP) }
          res = []
          xxx = [valori_struct[0].count, valori_struct[1].count].max
          xxx.times do |idx|
            res[idx] = super([valori_struct[0][idx] || TEXT_PARAMETRO_ASSENTE, valori_struct[1][idx] || TEXT_PARAMETRO_ASSENTE])
          end
          # puts "YYYYYYYY parametro_da_scrivere_FU - res: #{res}"
          return false if res.uniq == [false]
          true
        end
      end
      #
      class ExportRcTotale < ExportRcBase # rubocop:disable Metrics/ClassLength
        # TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE

        def parametri_entita(record)
          # ritorna:
          # { nome => [val 1, val 2],...} nome = nome_param_semplice/s.p.. per parametri strutturati
          # contiene chiave-valore solo per i parametri da scrivere !!!
          ret = {}
          return ret unless record[RECORD_FONTE_1][RECORD_FIELD_PARAMETRI]
          naming_path = record[:naming_path]
          meta_parametri_info(naming_path)[:flatten_keys].each do |key|
            valori = []
            RECORD_FIELDS_FONTE.each_with_index do |f, idx|
              val = record[f][RECORD_FIELD_PARAMETRI][key]
              valori[idx] = (val == REP_COMP_KEY_ASSENTE) ? nil : MetaModello.parametro_to_s(val)
            end
            # se uno solo dei due parametri e' nil, allora va sostituito con la stringa 'ASSENTE'
            [0, 1].each do |k|
              valori[k] = TEXT_PARAMETRO_ASSENTE if valori[k].nil? && valori[1 - k]
            end
            ret[key] = valori if parametro_da_scrivere(valori)
          end
          ret
        end

        def dn_ancestor(naming_path_ancestor:, dist_name:)
          level = naming_path_ancestor.to_s.split(NAMING_PATH_SEP).count
          dist_name.to_s.split(DIST_NAME_SEP)[0..(level - 1)].join(DIST_NAME_SEP)
        end

        def scrivi_contatori_alberatura
          np = @actual_np_root_alberatura
          return unless @fd_cnt_alb && @contatori[np]
          @contatori[np].each do |rrr, ccc|
            h = ccc.merge('np' => np, 'dn' => rrr)
            pzs = []
            CAMPI_FILE_CONTEGGIO_ALBERATURA_RC.each { |k| pzs << h[k] }
            @fd_cnt_alb.puts(pzs.join(SEP_FILE_CONTEGGIO_ALBERATURA_RC))
            # @fd_cnt_alb.puts([np, rrr, ccc['en'], ccc['tot'], ccc['prio']].join(','))
          end
        end

        def aggiorna_contatori_alb(naming_path:, dist_name:, prio: false)
          dn_root = if naming_path == @actual_np_root_alberatura
                      dist_name
                    else
                      dn_ancestor(naming_path_ancestor: @actual_np_root_alberatura, dist_name: dist_name)
                    end
          @contatori[@actual_np_root_alberatura][dn_root] ||= { 'tot' => 0, 'prio' => 0 }
          @contatori[@actual_np_root_alberatura][dn_root]['tot'] += 1
          @contatori[@actual_np_root_alberatura][dn_root]['prio'] += 1 if prio
        end

        def inizializza_contatori_alberatura(naming_path)
          @actual_np_root_alberatura = naming_path
          @contatori[naming_path] ||= {}
        end

        def aggiorna_contatori_parametro(naming_path:, parametro:, prio: false)
          @contatori[naming_path][:parametri][parametro] += 1
          @contatori[naming_path][:parametri_prioritari] += 1 if prio
        end

        def inizializza_contatori(naming_path)
          return if @contatori[naming_path]
          @contatori[naming_path] = {}
          mpi = meta_parametri_info(naming_path)
          @contatori[naming_path][:num_entita] = 0
          @contatori[naming_path][:num_entita_diff] = 0
          @contatori[naming_path][:parametri] = {}
          @contatori[naming_path][:parametri][RECORD_FIELD_VERSION] = 0
          @contatori[naming_path][:parametri_prioritari] = 0
          mpi[:flatten_keys].each do |param|
            @contatori[naming_path][:parametri][param] = 0
          end
          @contatori[naming_path]
        end

        def naming_path_da_ignorare(naming_path)
          return true unless @contatori[naming_path]
          @contatori[naming_path][:da_ignorare] ||= (@contatori[naming_path][:num_entita] == 0 && @contatori[naming_path][:num_entita_diff] == 0)
        end

        def elabora_record(record:, aggiorna_contatori: nil) # rubocop:disable Metrics/MethodLength
          ret = { entita_da_scrivere: false, differenze_da_scrivere: false, parametri: {} }
          #
          # --- entita'
          if entita_da_scrivere(record)
            ret[:entita_da_scrivere] = true
            @contatori[record[:naming_path]][:num_entita] += 1 if aggiorna_contatori == CNT_AGGIORNA
          end

          return ret unless record[:esito_diff] == REP_COMP_ESITO_DIFFERENZE
          # --- parametri
          # { nome => [val 1, val 2],...} nome = nome_param_semplice/s.p.. per parametri strutturati
          # contiene chiave-valore solo per i parametri da scrivere !!!
          pe = parametri_entita(record)
          (pe.keys || []).each do |param|
            ret[:parametri][param] = pe[param]
            prio = parametro_prioritario?(record[:naming_path], [param])
            aggiorna_contatori_parametro(naming_path: record[:naming_path], parametro: param, prio: prio) if aggiorna_contatori == CNT_AGGIORNA
            aggiorna_contatori_alb(naming_path: record[:naming_path], dist_name: record[:dist_name], prio: prio) if aggiorna_contatori == CNT_ALBERATURA_AGGIORNA
          end

          # --- version
          if con_version && (version_vals = version_da_scrivere(record))
            ret[:parametri][RECORD_FIELD_VERSION] = version_vals
            # @contatori[record[:naming_path]][:parametri][RECORD_FIELD_VERSION] += 1 if aggiorna_contatori == CNT_AGGIORNA
            aggiorna_contatori_parametro(naming_path: record[:naming_path], parametro: RECORD_FIELD_VERSION) if aggiorna_contatori == CNT_AGGIORNA
            aggiorna_contatori_alb(naming_path: record[:naming_path], dist_name: record[:dist_name]) if aggiorna_contatori == CNT_ALBERATURA_AGGIORNA
          end
          # ------------------------------------------------------------------
          # se una entita' ha differenze, ma nessuna di queste e' da_scrivere
          # allora va inserita/conteggiata nel file entita'
          # altrimenti, nel file parametri.
          # if ret[:parametri].keys.empty?
          #   ret[:entita_da_scrivere] = true
          #   @contatori[record[:naming_path]][:num_entita] += 1 if aggiorna_contatori == CNT_AGGIORNA
          # else
          #   ret[:differenze_da_scrivere] = true
          #   @contatori[record[:naming_path]][:num_entita_diff] += 1 if aggiorna_contatori == CNT_AGGIORNA
          # end
          # ----------------------
          # 2018-01-09: cambia la logica precedente.
          #    se una entita' ha differenze e
          #           - almeno una e' "da scrivere", allora va scritta/conteggiata nel file parametri
          #           - nessuna e' "da scrivere", allora NON va scritta/conteggiata ne' nel file parametri (differenti), ne' nel file entita (presenti/assenti)
          # unless ret[:parametri].keys.empty?
          #   ret[:differenze_da_scrivere] = true
          #   @contatori[record[:naming_path]][:num_entita_diff] += 1 if aggiorna_contatori == CNT_AGGIORNA
          # end
          # 2018-03-28: modifica alla logica attuale:
          #           - se nessuna e' "da scrivere", allora va trattata come un'entita' UGUALE, quindi:
          #                se nel comparativo sono incluse le entita' uguali (flag_presente: true),
          #                va scritta nel file entita', altrimenti no.
          if ret[:parametri].keys.empty?
            if flag_presente
              ret[:entita_da_scrivere] = true
              @contatori[record[:naming_path]][:num_entita] += 1 if aggiorna_contatori == CNT_AGGIORNA
            end
          else
            ret[:differenze_da_scrivere] = true
            @contatori[record[:naming_path]][:num_entita_diff] += 1 if aggiorna_contatori == CNT_AGGIORNA
          end
          # ------------------------------------------------------------------
          ret
        end

        def entita_da_scrivere(record)
          if record[:esito_diff] == REP_COMP_ESITO_ASSENTE_2
            [REP_COMP_KEY_PRESENTE, REP_COMP_KEY_ASSENTE]
          elsif record[:esito_diff] == REP_COMP_ESITO_ASSENTE_1
            [REP_COMP_KEY_ASSENTE, REP_COMP_KEY_PRESENTE]
          elsif record[:esito_diff] == REP_COMP_ESITO_UGUALE
            [REP_COMP_KEY_PRESENTE, REP_COMP_KEY_PRESENTE]
            # else
            #  nil # non e' da scrivere...
          end
        end
      end

      # --------------------------------------------------------------------------
      def dataset
        @dataset ||= report_comparativo.entita.dataset
      end

      def table_name
        report_comparativo.entita.table_name
      end

      def con_formatter(type:, type_export:, out_dir:, data_riferimento:, &block)
        Formatter.with(type, type_export, out_dir: out_dir, data_riferimento: data_riferimento, logger: logger, log_prefix: log_prefix, &block)
      end

      def determina_funzione(opts)
        x = if opts[:tipo_export] == TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE
              opts[:omc_fisico] ? FUNZIONE_EXPORT_REPORT_COMPARATIVO_TOTALE_OMC_FISICO : FUNZIONE_EXPORT_REPORT_COMPARATIVO_TOTALE
            else
              opts[:omc_fisico] ? FUNZIONE_EXPORT_REPORT_COMPARATIVO_FU_OMC_FISICO : FUNZIONE_EXPORT_REPORT_COMPARATIVO_FU
            end
        Db::Funzione.get_by_pk(x)
      end

      def np_da_considerare
        @np_da_considerare ||= if filtro_metamodello
                                 (@solo_calcolabili ? metamodello.meta_entita_progettazione : metamodello.meta_entita.keys) & filtro_metamodello.keys
                               else
                                 @solo_calcolabili ? metamodello.meta_entita_progettazione : metamodello.meta_entita.keys
                               end
      end

      def query_per_np(np)
        @query_per_np[np] ||= feu_query_per_naming_path(naming_path: np, dataset: dataset,
                                                        filtro_np: (filtro_metamodello || {})[np],
                                                        nome_tabella: table_name, use_pid: false)
      end

      def cc_diff(i_contatori)
        n_diff = 0
        n_diff_prio = 0
        i_contatori.each do |_np, cntrs|
          n_diff_prio += cntrs[:parametri_prioritari]
          next if cntrs[:num_entita_diff] == 0
          n_diff += (cntrs[:parametri] || {}).values.reduce(0, :+)
        end
        { 'tot' => n_diff, 'prio' => n_diff_prio }
      end

      UTILIZZO_CONTATORI = [
        CNT_AGGIORNA = :aggiorna_contatori,
        CNT_ALBERATURA_AGGIORNA = :aggiorna_contatori_alberatura
      ].freeze

      PREFIX_FILE_CNT_ALB = 'cnt_alberatura'.freeze
      def nome_file_cnt_alb(out_dir:)
        File.join(out_dir, "#{PREFIX_FILE_CNT_ALB}_#{@data_riferimento.strftime('%Y%m%d%H%M')}.csv")
      end

      def esegui(out_dir:, step_info: 10_000, **opts) # rubocop:disable Metrics/MethodLength
        res = { meta_entita: 0, entita: 0, msg: '' }
        progress = opts[:step_progresso] || 100_000
        funz = determina_funzione(opts)
        opts_classe_export = { metamodello: metamodello,
                               only_to_export_param: only_to_export_param,
                               solo_prioritari: solo_prioritari,
                               con_version: con_version,
                               flag_presente: flag_presente,
                               dist_assente_vuoto: dist_assente_vuoto,
                               nascondi_assente_f1: nascondi_assente_f1,
                               nascondi_assente_f2: nascondi_assente_f2,
                               filtro_metamodello: filtro_metamodello,
                               filtro_cc_parametri: filtro_cc_parametri }
        @classe_export = (opts[:tipo_export] == TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE ? ExportRcTotale : ExportRcFu).new(opts_classe_export)

        report_comparativo.entita.con_lock(funzione: funz.nome, account_id: @account_id, enable: opts.fetch(:lock, true), logger: logger, log_prefix: log_prefix, **opts) do |locks|
          con_segnalazioni(funzione: funz,
                           account: Db::Account.first(id: @account_id),
                           filtro: report_comparativo.filtro_segnalazioni,
                           attivita_id: opts[:attivita_id],
                           chiavi_risultato_da_ignorare_nel_dettaglio: [:counters],
                           enable: !@np_alberatura && !@solo_counters) do
            # controlli
            raise "MetaModello non valido per export report_comparativo #{report_comparativo.full_descr}" unless metamodello
            if opts[:tipo_export] == TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE && opts[:formato] != Constant.value(:formato_export, :xls)
              raise "Per #{TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE} e' previsto solo il formato excel"
            end

            if @np_alberatura
              raise 'Conteggio alberatura previsto solo per ExportTotale' if opts[:tipo_export] != TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE

              File.open(nome_file_cnt_alb(out_dir: out_dir), 'w') do |fd|
                @classe_export.fd_cnt_alb = fd
                @np_alberatura.each do |np_root|
                  @classe_export.scrivi_contatori_alberatura # scrive contatori precedente np_root
                  next unless metamodello.meta_entita.keys.include?(np_root)
                  @classe_export.inizializza_contatori_alberatura(np_root)
                  np_descendants = metamodello.naming_path_alberatura(np_root)
                  report_comparativo.db.transaction do
                    (([np_root] + np_descendants) & np_da_considerare).each do |np|
                      meta_entita = metamodello.meta_entita[np]
                      next unless meta_entita
                      feu_info = query_per_np(np)
                      query = feu_info[:feu_query_np]
                      filtro_wi = feu_info[:feu_filtro_wi]
                      query.each do |record|
                        # puts "AAAA record descendants: #{record[:dist_name]}"
                        next if !filtro_wi.empty? && !feu_tengo?(record[:dist_name], filtro_wi)
                        next if Db::ReportComparativo.ignora_per_filtro_version(record, @filtro_version)
                        @classe_export.elabora_record(record: record, aggiorna_contatori: CNT_ALBERATURA_AGGIORNA)
                      end
                    end
                  end
                end
                @classe_export.scrivi_contatori_alberatura # scrive contatori ultimo np_root
              end
              # puts "AAAA #{@classe_export.contatori}"
              # res[CONTEGGIO_ALBERATURA_RC_KEYWORD] = @classe_export.contatori
            else
              report_comparativo.db.transaction do
                np_da_considerare.each do |np|
                  meta_entita = metamodello.meta_entita[np]
                  next unless meta_entita
                  @classe_export.inizializza_contatori(np)
                  feu_info = query_per_np(np)
                  query = feu_info[:feu_query_np]
                  filtro_wi = feu_info[:feu_filtro_wi]
                  query.each do |record|
                    next if !filtro_wi.empty? && !feu_tengo?(record[:dist_name], filtro_wi)
                    next if Db::ReportComparativo.ignora_per_filtro_version(record, @filtro_version)
                    @classe_export.elabora_record(record: record, aggiorna_contatori: CNT_AGGIORNA)
                  end
                end
              end
              if @solo_counters
                res[:counters] = @classe_export.contatori
                res[:cc_diff] = cc_diff(@classe_export.contatori)
              else
                # begin
                con_formatter(type: opts[:formato], type_export: opts[:tipo_export], out_dir: out_dir, data_riferimento: data_riferimento) do |formatter|
                  logger.info("#{log_prefix}, inizio esecuzione con formatter #{formatter}")
                  segnalazione_esecuzione_in_corso("(generazione file in formato #{opts[:formato]})")
                  res[:locks] = locks
                  Irma.gc
                  report_comparativo.db.transaction do
                    InfoProgresso.start(logger: logger, log_prefix: log_prefix, step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
                      np_da_considerare.each do |np|
                        meta_entita = metamodello.meta_entita[np]
                        next unless meta_entita
                        next if @classe_export.naming_path_da_ignorare(np)
                        res[:meta_entita] += 1
                        formatter.nuova_meta_entita(meta_entita: meta_entita, contatori: @classe_export.contatori[np], con_version: con_version)
                        feu_info = query_per_np(np)
                        query = feu_info[:feu_query_np]
                        filtro_wi = feu_info[:feu_filtro_wi]
                        query.each do |record|
                          ip.incr
                          next if !filtro_wi.empty? && !feu_tengo?(record[:dist_name], filtro_wi)
                          next if Db::ReportComparativo.ignora_per_filtro_version(record, @filtro_version)
                          formatter.scrivi_entita(record: record,
                                                  record_info: @classe_export.elabora_record(record: record, aggiorna_contatori: nil),
                                                  con_version: con_version)
                          res[:entita] += 1
                          if progress > 0 && ((res[:entita] % progress) == 0)
                            segnalazione_esecuzione_in_corso("(processate #{res[:entita]} entita' di report comparativo e #{res[:meta_entita]} meta entita')")
                          end
                        end
                      end # np_da_considerare
                    end # InfoProgresso
                    logger.info("#{log_prefix}, nessun dato da esportare") if res[:entita].zero?
                  end # db.transaction
                end # con_formatter
              end
            end
            res
          end # con_segnalazioni
        end # con_lock
      end
    end
  end
end
