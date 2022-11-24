# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151116
#

# rubocop:disable Style/SpaceInsideArrayPercentLiteral
module Irma
  # rubocop:disable Metrics/ModuleLength
  module Vendor
    definisci_classe_vendor(vendor: VENDOR_ERICSSON) do
      default_formato_audit_of DEFAULT_FORMATO_AUDIT_IDL.merge(FORMATO_AUDIT_CNA => { 'validate' => true })
      # Da sostituire per abilitazione 3GPP:
      # default_formato_audit_of DEFAULT_FORMATO_AUDIT_IDL.merge(FORMATO_AUDIT_CNA => { 'validate' => true }, FORMATO_AUDIT_TREGPP => { 'validate' => false, 'xsd' => [] })
      def self.calcolo_vs_data?(_v = nil)
        true
      end

      definisci_classe_rete(rete: RETE_GSM) do
        default_cella_naming_path              'NW;MSC;BSC;SITE;CELL'
        default_formato_audit                  FORMATO_AUDIT_CNA => { 'validate' => true }
        default_nodo_naming_path               'NW;MSC;BSC'
        meta_entita_adiacenza                  RETE_GSM  => ['NW;FCELL'],
                                               RETE_UMTS => ['NW;RNC', 'NW;RNC;UCELL']
        meta_entita_relazioni_adiacenza_prefix RETE_GSM  => { 'NW;MSC;BSC;SITE;CELL;n_cell_' => [] },
                                               RETE_UMTS => { 'NW;MSC;BSC;SITE;CELL;un_cell_' => [] }
        mera = [RETE_GSM, RETE_UMTS].each_with_object({}) do |rete, res|
          res[rete] = begin
                        tmp = {}
                        (0..63).each { |idx| tmp[meta_entita_relazioni_adiacenza_prefix[rete].keys.first + idx.to_s] = [] }
                        tmp
                      end
        end
        meta_entita_relazioni_adiacenza mera
        pr_campi_adiacenza              %w(ADJ UADJ)
        pr_nome_nodo                   'BSC_NODE_NAME'
        pr_nome_release_nodo           'BSC_REL'

        def self.comportamento_result_calcolo_entita(_v = nil)
          @comportamento_result_calcolo_entita ||= begin
                                                     v = Marshal.load(Marshal.dump(super))
                                                     ece = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                                                  tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_VALORE_VUOTO)
                                                     v[REGOLA_CALCOLO_NON_MULTI][ESITO_CALCOLO_VALORE_VUOTO][FASE_CALCOLO_ADJ] = ece
                                                     v
                                                   end
        end

        def self.comportamento_assenza_regole_calcolo_entita(_v = nil)
          @comportamento_assenza_regole_calcolo_entita ||= begin
                                                             v = Marshal.load(Marshal.dump(super))
                                                             v[FASE_CALCOLO_ADJ] = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                                                                          tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_REGOLE_CALCOLO_ASSENTI)
                                                             v
                                                           end
        end

        def self.comportamento_errore_totale_multi(_v = nil)
          @comportamento_errore_totale_multi ||= begin
                                                   v = Marshal.load(Marshal.dump(super))
                                                   v[FASE_CALCOLO_ADJ] = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                                                                tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_MULTI_ERRORE_TOTALE)
                                                   v
                                                 end
        end

        def estrai_cs_ca_da_relazione(entita)
          # data un' entita di relazione adiacenza, ne estrae la cella sorgente e la cella adiacente
          # il nome della cella adiacente corrisponde al nome della relazione, il nome della sorgente e' il nome dell'oggetto padre
          cella_a = entita.valore_entita
          cella_s = entita.dist_name[0, entita.dist_name.index(DIST_NAME_SEP, entita.dist_name.index(meta_entita_cella(RETE_GSM)) + meta_entita_cella(RETE_GSM).length + 1)]
          [cella_s, cella_a]
        end

        ADJ_INDEX_SEP = '_'.freeze

        def calcolo_adj_da_scartare?(np:, me:, hdr:, **_opts) # rubocop:disable Metrics/AbcSize
          return false if (meta_entita_adiacenza[RETE_GSM] + meta_entita_adiacenza[RETE_UMTS]).include?(np)
          @meta_entita_relazioni_adiacenza_values_keys ||= meta_entita_relazioni_adiacenza.map { |_r, v| v.keys }.flatten
          (@meta_entita_relazioni_adiacenza_values_keys.include?(np) && (me.nome.split(ADJ_INDEX_SEP).last == hdr.split(ADJ_INDEX_SEP).last)) ? false : true
        end

        #
        # variabili_speciali_per_calcolatore
        #
        UMFI_IDLE_FIELDS = {
          'ERI' => %w(UARFCNDL       PRIMARYSCRAMBLINGCODE),
          'HUA' => %w(UARFCNDOWNLINK PSCRAMBCODE),
          'NOK' => %w(UARFCNDL       PRISCRCODE)
        }.freeze

        UADJ_PREFIX            = 'UADJ'.freeze
        VENDOR_SIGLA           = 'vendor_sigla'.freeze

        VAR_INFO = {
          n_bcchno:      { first_index: 1, last_index: 32, uniq: true,  sort: true, tipo_valore: TIPO_VALORE_INTEGER, prefix: 'N_BCCHNO'.freeze,   format: 'N_BCCHNO_N%02d'.freeze },
          umfi_idle:     { first_index: 0, last_index: 63, uniq: false, sort: true, tipo_valore: TIPO_VALORE_CHAR,    prefix: nil,                 format: 'UMFI_IDLE_%02d'.freeze },
          ord_n_tch_ul:  { first_index: 1, last_index: 10, uniq: false, sort: true, tipo_valore: TIPO_VALORE_INTEGER, prefix: 'N_TCH_UL_'.freeze,  format: 'ORD_N_TCH_UL_%02d'.freeze },
          ord_n_tch_ule: { first_index: 1, last_index: 10, uniq: false, sort: true, tipo_valore: TIPO_VALORE_INTEGER, prefix: 'N_TCH_ULE_'.freeze, format: 'ORD_N_TCH_ULE_%02d'.freeze }
        }.freeze

        def prefissi_variabili_speciali_per_calcolatore
          @prefissi_variabili_speciali_per_calcolatore ||= VAR_INFO.values.map { |v| v[:prefix] }.compact + UMFI_IDLE_FIELDS.values.flatten
        end

        def variabili_speciali_per_calcolatore(pr:, nome_cella:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          res = {}
          cella = pr[nome_cella]
          if cella
            #
            # N_TCH_UL_Y, N_TCH_ULE_Y, N_BCCHNO_XX, UMFI_IDLE_XX
            #
            values = VAR_INFO.keys.each_with_object({}) { |k, ret| ret[k] = [] }
            cella.each do |k, v|
              # N_TCH_UL_Y, N_TCH_ULE_Y
              if k.start_with?(VAR_INFO[:ord_n_tch_ul][:prefix])
                values[:ord_n_tch_ul] << v.first.to_i if v && v.first && v.first != ''
                next
              elsif k.start_with?(VAR_INFO[:ord_n_tch_ule][:prefix])
                values[:ord_n_tch_ule] << v.first.to_i if v && v.first && v.first != ''
                next
              end
            end
            (cella[CAMPO_CELLA_PR_ADJS] || []).each_slice(2).each do |k, v|
              cella_adj = pr[v]
              next unless cella_adj

              # N_BCCHNO
              n_bcchno = cella_adj[VAR_INFO[:n_bcchno][:prefix]]
              values[:n_bcchno] << n_bcchno.first.to_i if n_bcchno && n_bcchno.first && n_bcchno.first != ''

              # UMFI_IDLE
              next unless k.start_with?(UADJ_PREFIX)
              umfi_fields = UMFI_IDLE_FIELDS[cella_adj[CAMPO_CELLA_PR_VENDOR_SIGLA]]
              next unless umfi_fields
              vals = []
              umfi_fields.each do |f|
                val = (cella_adj[f] || []).first.to_s.strip
                vals << val unless val.empty?
              end
              next unless vals.size == umfi_fields.size
              values[:umfi_idle] << (vals.join('-') << '-NODIV')
            end

            VAR_INFO.each do |k, info|
              last_idx = info[:first_index] - 1
              vals = values[k]
              vals.uniq! if info[:uniq]
              vals.sort! if info[:sort]
              vals.each do |v|
                last_idx += 1
                res[format(info[:format], last_idx)] = [v, info[:tipo_valore]]
              end
              # fill remaining values with nill
              res[format(info[:format], last_idx)] = [nil] while (last_idx += 1) <= info[:last_index]
            end
          end
          res
        end
      end

      definisci_classe_rete(rete: RETE_UMTS) do
        default_cella_naming_path       'SubNetwork;SubNetwork;MeContext;ManagedElement;RncFunction;UtranCell'
        default_formato_audit           DEFAULT_FORMATO_AUDIT_IDL.merge(FORMATO_AUDIT_XML => { 'validate' => false, 'xsd' => [] })
        default_nodo_naming_path        'SubNetwork;SubNetwork;MeContext'
        meta_entita_adiacenza           RETE_GSM => ['SubNetwork;ExternalGsmCell'],
                                        RETE_UMTS => ['SubNetwork;ExternalUtranCell'],
                                        RETE_LTE => ['SubNetwork;vsDataFreqManagement;vsDataExternalEutranFrequency']
        meta_entita_relazioni_adiacenza RETE_GSM  => { 'SubNetwork;SubNetwork;MeContext;ManagedElement;RncFunction;UtranCell;GsmRelation' => [] },
                                        RETE_UMTS => { 'SubNetwork;SubNetwork;MeContext;ManagedElement;RncFunction;UtranCell;UtranRelation' => [] },
                                        RETE_LTE  => { 'SubNetwork;SubNetwork;MeContext;ManagedElement;RncFunction;UtranCell;vsDataEutranFreqRelation' => [] }
        pr_campi_adiacenza              %w(ADJ GADJ LADJ)
        pr_nome_nodo                    'RNC_NODE_NAME'
        pr_nome_release_nodo            'RNC_REL'

        def self.calcolo_alias?(_v = nil)
          true
        end

        NAMING_PATHS = [
          NAMING_PATH_DA_SALVARE_PER_PARAMETRI = 'SubNetwork;SubNetwork;MeContext;ManagedElement;RncFunction;UtranCell'.freeze,
          NAMING_PATH_VS_DATA_AREAS            = 'SubNetwork;vsDataAreas'.freeze,
          NAMING_PATH_RNC_FUNCTION_UTRAN_CELL  = 'SubNetwork;SubNetwork;MeContext;ManagedElement;RncFunction;UtranCell'.freeze
        ].freeze

        def salva_parametri_entita?(naming_path:)
          naming_path == NAMING_PATH_DA_SALVARE_PER_PARAMETRI
        end

        def calcolo_fase_pi_extra?(meta_entita:, sorgente:, cache_entita:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          return @calcolo_fase_pi_extra[meta_entita.id] if @calcolo_fase_pi_extra && !@calcolo_fase_pi_extra[meta_entita.id].nil?

          @calcolo_fase_pi_extra ||= {}
          cond = false
          # -------- 'SubNetwork;vsDataAreas' e discendenti...
          np_root = NAMING_PATH_VS_DATA_AREAS
          if meta_entita.naming_path.start_with?(np_root)
            uc_np = NAMING_PATH_RNC_FUNCTION_UTRAN_CELL
            uc_sorgente = sorgente.dataset.where(naming_path: uc_np).first
            if uc_sorgente
              uc_calcolata = (cache_entita[:entita_per_namingpath][uc_np] || [])[0]
              if uc_calcolata
                parametri = cache_entita[:entita_create][uc_calcolata][3] || {}
                cond = !parametri['lac'].nil? && !parametri['sac'].nil? && !parametri['rac']
              else
                cond = true
              end
            end
            id_discendenti = Db::MetaEntita.where(vendor_release_id: meta_entita.vendor_release_id).where("naming_path like '#{np_root}%'").select_map(:id)
            id_discendenti.each { |id_me| @calcolo_fase_pi_extra[id_me] = cond }
          end
          # --------
          @calcolo_fase_pi_extra[meta_entita.id] ||= cond
        end

        def self.comportamento_result_calcolo_entita(_v = nil)
          @comportamento_result_calcolo_entita ||= begin
                                                     v = Marshal.load(Marshal.dump(super))
                                                     ece = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                                                  tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_VALORE_VUOTO)
                                                     v[REGOLA_CALCOLO_NON_MULTI][ESITO_CALCOLO_VALORE_VUOTO][FASE_CALCOLO_ADJ] = ece
                                                     v
                                                   end
        end

        def self.comportamento_assenza_regole_calcolo_entita(_v = nil)
          @comportamento_assenza_regole_calcolo_entita ||= begin
                                                             v = Marshal.load(Marshal.dump(super))
                                                             v[FASE_CALCOLO_ADJ] = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                                                                          tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_REGOLE_CALCOLO_ASSENTI)
                                                             v
                                                           end
        end

        def self.comportamento_errore_totale_multi(_v = nil)
          @comportamento_errore_totale_multi ||= begin
                                                   v = Marshal.load(Marshal.dump(super))
                                                   v[FASE_CALCOLO_ADJ] = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                                                                tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_MULTI_ERRORE_TOTALE)
                                                   v
                                                 end
        end

        def estrai_cs_ca_da_relazione(entita) # rubocop:disable Metrics/AbcSize
          # data un' entita di relazione adiacenza, ne estrae la cella sorgente e la cella adiacente
          # per le relazioni U2U e U2G il valore dell'entita e' composto dalla concatenazione delle due celle
          # per la relazione U2L, il nome della cella adiacente corrisponde al nome della relazione, il nome della sorgente e' il nome dell'oggetto padre
          cella_a = if get_rete_from_meta_entita_rel_adj(entita.naming_path) == RETE_LTE
                      entita.valore_entita
                    else
                      entita.valore_entita.split('-')[1]
                    end
          cella_s = entita.dist_name[0, entita.dist_name.index(DIST_NAME_SEP, entita.dist_name.index(meta_entita_cella(RETE_UMTS)) + meta_entita_cella(RETE_UMTS).length + 1)]
          [cella_s, cella_a]
        end

        # -------------------------------------------------
        # reparenting
        def cella_reparented(dist_name, dataset)
          nome = dist_name.split(DIST_NAME_VALUE_SEP).last
          dataset.where(naming_path: naming_path_cella, valore_entita: nome).select(:dist_name, :naming_path, :valore_entita, :parametri, :id).first
        end

        def entita_per_reparenting(options, &_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          celle_in_reparenting = options[:celle_in_reparenting] # [ [cella_old, cella_new],...]
          dataset_m = options[:dataset_master]
          dataset_r = options[:dataset_rif]
          return unless celle_in_reparenting && !celle_in_reparenting.empty? && dataset_m && dataset_r
          valore_ent_celle_old = celle_in_reparenting.map { |xxx| (xxx[0] || {})[:valore_entita] }.compact
          # Vanno cancellate la vecchia cella riparentata e tutte le entita figlie presenti nell'archivio di riferimento
          celle_in_reparenting.map { |xxx| xxx[0] }.each do |cella_old|
            eee = { operazione: MANAGED_OBJECT_OPERATION_DELETE,
                    dist_name: cella_old[:dist_name],
                    naming_path: cella_old[:naming_path] }
            yield eee
          end

          # where_condition_list = []
          # where_condition = ''
          # dn_celle_old= celle_in_reparenting.map { |xxx| (xxx[0] || {})[:dist_name] }.compact
          # dn_celle_old.each.with_index do |dn_old, idx|
          #   if (idx % 1_000_000) == 0
          #     where_condition_list << where_condition unless where_condition.empty?
          #     where_condition = "dist_name like '#{dn_old}#{DIST_NAME_SEP}%'"
          #   else
          #     where_condition += " OR dist_name like '#{dn_old}#{DIST_NAME_SEP}%'"
          #   end
          # end
          # where_condition_list << where_condition unless where_condition.empty?
          # puts "TTTT Prima: #{Time.now} - memoria: #{memory_used}"
          # tot = 0
          # where_condition_list.each.with_index do |where_c, num_query|
          #   puts "TTTT Query n. #{num_query}. Prima: #{Time.now} - memoria: #{memory_used}"
          #   iii = 0
          #   dataset_r.where(where_c).select(:dist_name, :naming_path).all.each do |eee_info|
          #     tot += 1
          #     iii += 1
          #     eee = { operazione: MANAGED_OBJECT_OPERATION_DELETE, dist_name: eee_info[:dist_name], naming_path: eee_info[:naming_path] }
          #     yield eee
          #     puts "TTTTTTTT #{Time.now}. Elaborati #{iii} oggetti - memoria: #{memory_used}" if (iii % 1000) == 0
          #   end
          #   puts "TTTT Query n. #{num_query}. Dopo: #{Time.now} - memoria: #{memory_used}"
          # end
          # puts "TTTT Dopo: #{Time.now} - memoria: #{memory_used}"
          # puts "TTTT Entita totali: #{tot} - memoria: #{memory_used}"
          # ----------------------------------
          livello_cella = naming_path_cella.to_s.split(NAMING_PATH_SEP).size
          livello_max = dataset_r.max(:livello).to_s.to_i
          id_celle_old = celle_in_reparenting.map { |xxx| (xxx[0] || {})[:id] }.compact

          tot_entita = 0
          tot_entita_per_query = 0

          id_list_successiva = []
          id_list = id_celle_old
          livello = livello_cella + 1
          while livello <= livello_max
            tot_entita_per_query = 0
            # puts "PPPPP Start query per livello: #{livello}. #{Time.now}"
            dataset_r.where(pid: id_list, livello: livello).select(:dist_name, :naming_path, :id).each do |eee_info|
              tot_entita_per_query += 1
              tot_entita += 1
              id_list_successiva << eee_info[:id]
              eee = { operazione: MANAGED_OBJECT_OPERATION_DELETE,
                      dist_name: eee_info[:dist_name],
                      naming_path: eee_info[:naming_path] }
              yield eee
            end
            # puts "PPPPP End query per livello #{livello}. #{Time.now} (Trovate #{tot_entita_per_query} entita)"
            id_list = id_list_successiva
            livello += 1
          end
          # puts "PPPPP ENtita totali: #{tot_entita}"
          # ----------------------------------
          # Vanno in delete + create:
          # --- 1. Entita di relazione_adiacenza in archivio di riferimento, che hanno come cella_adiacente la cella riparentata
          dn_crt = []
          np_rel_adj = meta_entita_relazioni_adiacenza.values.map(&:keys).flatten
          dataset_r.where(naming_path: np_rel_adj, cella_adiacente: valore_ent_celle_old).each do |eee_rel_adj|
            eee_del = { operazione: MANAGED_OBJECT_OPERATION_DELETE,
                        dist_name: eee_rel_adj[:dist_name],
                        naming_path: eee_rel_adj[:naming_path] }
            yield eee_del
            # puts "mmmm DEL per relazioni_adj: #{eee_del[:dist_name]}"
            dn_crt << eee_rel_adj[:dist_name]
          end
          #------------
          dataset_m.where(dist_name: dn_crt).select(:dist_name, :naming_path, :version, :parametri).each do |eee|
            eee_crt = { operazione: MANAGED_OBJECT_OPERATION_CREATE,
                        dist_name: eee[:dist_name],
                        naming_path: eee[:naming_path],
                        version: eee[:version], parametri: eee[:parametri] }
            # puts "mmmm CRT per relazioni_adj: #{eee_crt[:dist_name]}"
            yield eee_crt
          end
          #------------
          # --- 2. Entita vsDataServiceArea in archivio di riferimento t.c.
          #           valore_entita = parametro 'sac' della cella riparentata in sorgente rif
          #           valore_entita_padre = parametro 'lac' della cella riparentata in sorgente rif
          np_sac = 'SubNetwork;vsDataAreas;vsDataPlmn;vsDataLocationArea;vsDataServiceArea'
          np_lac = 'SubNetwork;vsDataAreas;vsDataPlmn;vsDataLocationArea'
          lacsac_old = {} # { lac_n => [sac_n1, sac_n2,...], lac_m => [...], ...}
          sac_new_list = {}
          celle_in_reparenting.each do |xxx|
            cella_old = xxx[0]
            cella_new = xxx[1]
            lac_old = (cella_old[:parametri] || {})['lac']
            sac_old = (cella_old[:parametri] || {})['sac']
            unless lac_old.to_s.empty? || sac_old.to_s.empty?
              lacsac_old[lac_old] ||= []
              lacsac_old[lac_old] << sac_old
            end
            # ---
            sac_new = (cella_new[:parametri] || {})['sac']
            sac_new_list[sac_new] = true unless sac_new.to_s.empty?
          end

          entita_del_lacsac = {} # { val_entita => dist_name } per ogni entita cancellata per lacsac...
          dataset_r.where(naming_path: np_lac, valore_entita: lacsac_old.keys).select(:dist_name, :valore_entita).each do |eee|
            dn_del_list = lacsac_old[eee[:valore_entita]].map { |sac| "#{eee[:dist_name]}#{DIST_NAME_SEP}vsDataServiceArea#{DIST_NAME_VALUE_SEP}#{sac}" }
            dataset_r.where(dist_name: dn_del_list).select(:dist_name, :valore_entita).each do |eee_d|
              eee_del = { operazione: MANAGED_OBJECT_OPERATION_DELETE,
                          dist_name: eee_d[:dist_name],
                          naming_path: np_sac }
              yield eee_del
              # puts "mmmm DEL per lacsac: #{eee_del}"
              entita_del_lacsac[eee_d[:valore_entita]] = eee_d[:dist_name]
            end
          end
          dn_crt_list = entita_del_lacsac.select { |ve, _dn| sac_new_list.keys.include?(ve) }.values
          dataset_m.where(dist_name: dn_crt_list).select(:dist_name, :version, :parametri).each do |eee|
            eee_crt = { operazione: MANAGED_OBJECT_OPERATION_CREATE, dist_name: eee[:dist_name], naming_path: np_sac,
                        version: eee[:version], parametri: eee[:parametri] }
            yield eee_crt
            # puts "mmmm CRT per lacsac: #{eee_crt}"
          end
        end
        # -------------------------------------------------

        def fdc_priority
          @fdc_priority ||= {
            # figli di SubNetwork
            'vsDataAreas'    => 100,
            'SubNetwork'     => 200
          }
        end

        def meta_entita_relazioni_adj_fdc
          (super || []) << 'SubNetwork;SubNetwork;MeContext;ManagedElement;RncFunction;UtranCell;vsDataCoverageRelation'
        end
      end
      #
      definisci_classe_rete(rete: RETE_LTE) do
        NAMING_PATH_COMP_SISTEMA = 'SubNetwork;SubNetwork'.freeze
        mera = { RETE_GSM  => { 'SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataENodeBFunction;vsDataEUtranCellFDD;vsDataGeranFreqGroupRelation;vsDataGeranCellRelation' => ['adjacentCell'] },
                 RETE_UMTS => { 'SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataENodeBFunction;vsDataEUtranCellFDD;vsDataUtranFreqRelation;vsDataUtranCellRelation' => ['adjacentCell'] },
                 RETE_LTE  => { 'SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataENodeBFunction;vsDataEUtranCellFDD;vsDataEUtranFreqRelation;vsDataEUtranCellRelation' => ['adjacentCell'] } }
        default_cella_naming_path       'SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataENodeBFunction;vsDataEUtranCellFDD'
        default_formato_audit           DEFAULT_FORMATO_AUDIT_IDL
        default_nodo_naming_path        'SubNetwork;SubNetwork;MeContext'
        meta_entita_adiacenza           RETE_GSM => %w(SubNetwork;ExternalGsmCell),
                                        RETE_UMTS => %w(SubNetwork;ExternalUtranCell),
                                        RETE_LTE => %w(SubNetwork;vsDataExternalEUtranPlmn;vsDataExternalENodeBFunction;vsDataExternalEUtranCellFDD)
        meta_entita_relazioni_adiacenza mera
        pr_campi_adiacenza              %w(ADJ UADJ GADJ)
        pr_campi_per_controlli          %w(EARFCNUL)
        pr_nome_id_nodo                 'ENODEBID'
        pr_nome_nodo                    'E_NODEB_NAME'
        pr_nome_release_nodo            'ENODEB_REL'

        def competenza_base_sistema?(mo, saa)
          # il dist_name va controllato se e\' del tipo SubNetwork=xxx;SubNetwork=LTE_<nome_sistema>
          return false if mo.naming_path.eql?(NAMING_PATH_COMP_SISTEMA) && mo.valore_entita.index('LTE_') && !mo.valore_entita.eql?('LTE_' + saa.sistema.descr)
          true
        end

        self::NAMING_PATH_COMPORTAMENTO_CALCOLO_NO_ABORT = ['SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataENodeBFunction;vsDataEUtranCellFDD;vsDataEUtranFreqRelation'].freeze
        def determina_comportamento_result_calcolo_entita(info_calcolo:, tipo_errore:) # rubocop:disable Metrics/AbcSize
          # Per 'vsDataEUtranFreqRelation' in caso di errore in calcolo entita si vuole evitare l'ABORT del calcolo
          c1 = self.class::NAMING_PATH_COMPORTAMENTO_CALCOLO_NO_ABORT.include?(info_calcolo.naming_path)
          c2 = info_calcolo.fase == FASE_CALCOLO_PI
          ece_default = comportamento_result_calcolo_entita[info_calcolo.multi][tipo_errore][info_calcolo.fase]
          if c1 && c2 && ece_default.abort?
            segn = ece_default.tipo_segnalazione ? TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA_NON_BLOCCANTE : nil
            return EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP, tipo_segnalazione: segn)
          end
          ece_default
        end

        def determina_comportamento_errore_totale_multi(info_calcolo:)
          # Per 'vsDataEUtranFreqRelation', fase PI, si vuole evitare l'ABORT del calcolo
          if self.class::NAMING_PATH_COMPORTAMENTO_CALCOLO_NO_ABORT.include?(info_calcolo.naming_path) && info_calcolo.fase == FASE_CALCOLO_PI
            EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                   tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_MULTI_ERRORE_TOTALE_NON_BLOCCANTE)
          else
            comportamento_errore_totale_multi[info_calcolo.fase]
          end
        end

        def self.comportamento_nessun_padre(_v = nil)
          @comportamento_nessun_padre ||= begin
                                            v = Marshal.load(Marshal.dump(super))
                                            v[FASE_CALCOLO_ADJ] = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP, tipo_segnalazione: nil)
                                            v
                                          end
        end

        def estrai_cs_ca_da_relazione(entita) # rubocop:disable Metrics/AbcSize
          # data un' una entita di relazione adiacenza, ne estrae la cella sorgente e la cella adiacente
          # nel caso Ericsson 4G il nome della cella sorgente e' nel nome dell'oggetto cella, il nome della adiacente e' contenuto nel parametro adjacentCell
          rete = get_rete_from_meta_entita_rel_adj(entita.naming_path)
          path_a = entita.parametri[meta_entita_relazioni_adiacenza[rete][entita.naming_path][0]]
          cella_a = (path_a ? path_a[path_a.rindex(DIST_NAME_VALUE_SEP) + 1, path_a.length] : nil)
          # cella_s = entita.dist_name[idx = entita.dist_name.index(meta_entita_cella(RETE_LTE)) + meta_entita_cella(RETE_LTE).length + 1, entita.dist_name.index(DIST_NAME_SEP, idx) - idx]
          cella_s = entita.dist_name[0, entita.dist_name.index(DIST_NAME_SEP, entita.dist_name.index(meta_entita_cella(RETE_LTE)) + meta_entita_cella(RETE_LTE).length + 1)]
          [cella_s, cella_a]
        end

        def fdc_priority
          @fdc_priority ||= {
            # figli di SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataENodeBFunction;vsDataGeraNetwork
            'vsDataGeranFreqGroup'    => 100,
            'vsDataGeranFrequency'    => 200,
            'vsDataExternalGeranCell' => 300,
            # figli di SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataENodeBFunction
            'vsDataEUtraNetwork'      => 100,
            'vsDataGeraNetwork'       => 200,
            'vsDataSectorCarrier'     => 300,
            'vsDataUtraNetwork'       => 400,
            'vsDataEUtranCellFDD'     => 500
          }
        end
      end
      #
      definisci_classe_rete(rete: RETE_5G) do
        mera = { RETE_GSM  => {},
                 RETE_UMTS => {},
                 RETE_LTE  => {} } # TODO
        default_cella_naming_path       'SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataGNBCUCPFunction;vsDataNRCellCU'
        default_formato_audit           DEFAULT_FORMATO_AUDIT_IDL
        # Da sostituire per abilitazione 3GPP:
        # default_formato_audit           DEFAULT_FORMATO_AUDIT_IDL.merge(FORMATO_AUDIT_TREGPP => { 'validate' => false, 'xsd' => [] })
        default_nodo_naming_path        'SubNetwork;SubNetwork;MeContext'
        meta_entita_adiacenza           RETE_GSM =>  [],
                                        RETE_UMTS => [],
                                        RETE_LTE =>  [] # TODO
        meta_entita_relazioni_adiacenza mera
        pr_campi_adiacenza              %w(ADJ UADJ GADJ LADJ)
        # pr_campi_per_controlli          %w(EARFCNUL)
        pr_nome_id_nodo                 'GNODEBID'
        pr_nome_nodo                    'GNODEB_NAME'
        pr_nome_release_nodo            'GNODEB_REL'

        def self.comportamento_nessun_padre(_v = nil) # in assenza di informazioni, impostazione come per LTE
          @comportamento_nessun_padre ||= begin
                                            v = Marshal.load(Marshal.dump(super))
                                            v[FASE_CALCOLO_ADJ] = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP, tipo_segnalazione: nil)
                                            v
                                          end
        end

        # TODO: def estrai_cs_ca_da_relazione(entita) # rubocop:disable Metrics/AbcSize
        #   # data un' una entita di relazione adiacenza, ne estrae la cella sorgente e la cella adiacente
        #   [cella_s, cella_a]
        # end
      end
    end
  end
end
