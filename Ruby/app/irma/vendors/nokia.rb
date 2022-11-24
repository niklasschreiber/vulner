# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151116
#

module Irma
  # rubocop:disable Metrics/ModuleLength
  module Vendor
    definisci_classe_vendor(vendor: VENDOR_NOKIA) do
      default_formato_audit_of DEFAULT_FORMATO_AUDIT_IDL
      ROOT_ENTITA = 'PLMN-PLMN'.freeze
      def root_entita(formato)
        case formato
        when FORMATO_AUDIT_IDL
          @root_entita ||= {}
          @root_entita[formato] ||= Funzioni::ImportCostruttore::Idl::ManagedObject.new(dist_name_orig: ROOT_ENTITA, parametri: {})
        end
      end

      def _estrai_cs_ca_da_relazione(entita) # rubocop:disable Metrics/AbcSize
        # data un' entita di relazione adiacenza, ne estrae la cella sorgente e la cella adiacente
        # per Nokia la cella adiacente viene identificata con il dist_name contenuto nel parametro targetCellDN, mentre la cella sorgente mettiamo il path della cella
        rete = get_rete_from_meta_entita_rel_adj(entita.naming_path)
        # puts " estrai_cs_da_relazione --> me = #{entita.meta_entita} - rete = #{rete} - parametro = #{meta_entita_relazioni_adiacenza[rete][entita.meta_entita][0]}"
        cella_a = entita.parametri[meta_entita_relazioni_adiacenza[rete][entita.naming_path][0]]
        cella_s = entita.dist_name[0, entita.dist_name.rindex(DIST_NAME_SEP)]
        [cella_s, (cella_a.nil? ? nil : cella_a.gsub('-', DIST_NAME_VALUE_SEP))]
      end

      def query_relazioni_adj_da_cancellare(flag_cell_adj:, dist_name_sorg:, dataset:)
        return dataset.where(cella_adiacente: dist_name_sorg) if [FLAG_CELL, FLAG_ADJ_EXT].include?(flag_cell_adj)
        return dataset.where(Sequel.like(:cella_adiacente, "#{dist_name_sorg}#{DIST_NAME_SEP}%")) if [FLAG_CELL_PARENT, FLAG_ADJ_EXT_PARENT].include?(flag_cell_adj)
      end

      definisci_classe_rete(rete: RETE_GSM) do
        default_cella_naming_path       'PLMN;BSC;BCF;BTS'
        default_formato_audit           DEFAULT_FORMATO_AUDIT_IDL
        default_nodo_naming_path        'PLMN;BSC'
        meta_entita_adiacenza           RETE_GSM  => %w(PLMN;EXCCG;EXGCE),
                                        RETE_UMTS => %w(PLMN;EXCCU;EXUCE)
        meta_entita_relazioni_adiacenza RETE_GSM  => { 'PLMN;BSC;BCF;BTS;ADCE' => %w(targetCellDN) },
                                        RETE_UMTS => { 'PLMN;BSC;BCF;BTS;ADJW' => %w(targetCellDN) },
                                        RETE_LTE  => { 'PLMN;BSC;BCF;BTS;ADJL' => %w(targetCellDN) }
        pr_campi_adiacenza              %w(ADJ UADJ LADJ)
        pr_campi_per_controlli          %w(BCFIDMASTER)
        pr_nome_nodo                    'BSC_NODE_NAME'
        pr_nome_release_nodo            'BSC_REL'

        def estrai_cs_ca_da_relazione(entita)
          _estrai_cs_ca_da_relazione(entita)
        end
      end
      #
      definisci_classe_rete(rete: RETE_UMTS) do
        default_cella_naming_path             'PLMN;RNC;WBTS;WCEL'
        default_formato_audit                 DEFAULT_FORMATO_AUDIT_IDL
        default_nodo_naming_path              'PLMN;RNC'
        meta_entita_adiacenza                 RETE_GSM  => %w(PLMN;EXCCG;EXGCE),
                                              RETE_UMTS => %w(PLMN;EXCCU;EXUCE)
        meta_entita_relazioni_adiacenza_inter 'PLMN;RNC;WBTS;WCEL;ADJI' => %w(TargetCellDN)
        meta_entita_relazioni_adiacenza_intra 'PLMN;RNC;WBTS;WCEL;ADJS' => %w(TargetCellDN)
        meta_entita_relazioni_adiacenza       RETE_GSM  => { 'PLMN;RNC;WBTS;WCEL;ADJG' => %w(TargetCellDN) },
                                              RETE_UMTS => meta_entita_relazioni_adiacenza_intra.merge(meta_entita_relazioni_adiacenza_inter),
                                              RETE_LTE  => { 'PLMN;RNC;WBTS;WCEL;ADJL' => %w(TargetCellDN) }
        pr_campi_adiacenza                    %w(ADJI ADJS GADJ LADJ)
        pr_campi_per_controlli                %w(RNC_NODE_NAME LCRID)
        pr_nome_nodo                          'RNC_NODE_NAME'
        pr_nome_release_nodo                  'RNC_REL'

        def estrai_cs_ca_da_relazione(entita)
          _estrai_cs_ca_da_relazione(entita)
        end

        # -------------------------------------------------
        # reparenting
        WBTS_NAMING_PATH = 'PLMN;RNC;WBTS'.freeze
        def wbts_cache(dataset, reset = false)
          return @wbts_cache if !reset && @wbts_cache
          @wbts_cache = {}
          dataset.where(naming_path: WBTS_NAMING_PATH).select(:dist_name, :naming_path, :valore_entita, :id).each do |xxx|
            rnc = xxx[:dist_name].split(DIST_NAME_SEP)[1].split(DIST_NAME_VALUE_SEP)[1]
            @wbts_cache[xxx[:valore_entita]] = { rnc: rnc, obj: xxx }
          end
          @wbts_cache
        end

        def cella_reparented(dist_name, dataset)
          @wbts_cache ||= wbts_cache(dataset)
          values = dist_name.split(DIST_NAME_SEP).map { |xxx| xxx.split(DIST_NAME_VALUE_SEP)[1] }
          wbts = values[2]
          rnc = values[1]
          # puts "xxxx #{wbts} - #{rnc}" if @wbts_cache.keys.include?(wbts)
          @wbts_cache[wbts] && @wbts_cache[wbts][:rnc] != rnc ? @wbts_cache[wbts][:obj] : nil
        end

        def entita_per_reparenting(options, &_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
          celle_in_reparenting = options[:celle_in_reparenting] # [ [cella_old, cella_new],...]
          dataset_r = options[:dataset_rif]
          return unless celle_in_reparenting && !celle_in_reparenting.empty? && dataset_r
          wbts_in_reparenting = {}
          celle_in_reparenting.each do |xxx|
            wbts_in_reparenting[xxx[0][:dist_name]] ||= xxx[0]
          end
          # puts "XXX Reparenting: celle_in_reparenting: #{celle_in_reparenting.map { |ccc| ccc[0] }}"
          # puts "XXX Reparenting: WBTS riparentati: #{wbts_in_reparenting}"

          # Vanno in delete:
          # --- 1. le WBTS riparentate e tutte le entita figlie presenti nell'archivio di riferimento
          wbts_in_reparenting.keys.each do |xxx|
            # puts "---- DEL di figlie di #{xxx}"
            eee = { operazione: MANAGED_OBJECT_OPERATION_DELETE,
                    dist_name: xxx,
                    naming_path: WBTS_NAMING_PATH }
            yield eee
          end

          lista_celle_delete = []
          livello_wbts = WBTS_NAMING_PATH.to_s.split(NAMING_PATH_SEP).size
          livello_max = dataset_r.max(:livello).to_s.to_i
          id_wbts_old = wbts_in_reparenting.values.map { |xxx| xxx[:id] }

          tot_entita = 0
          tot_entita_per_query = 0

          id_list_successiva = []
          id_list = id_wbts_old
          livello = livello_wbts + 1
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
              lista_celle_delete << eee_info[:dist_name] if eee_info[:naming_path] == naming_path_cella
            end
            # puts "PPPPP End query per livello #{livello}. #{Time.now} (Trovate #{tot_entita_per_query} entita)"
            id_list = id_list_successiva
            livello += 1
          end

          # --- 2. Entita di relazione_adiacenza in archivio di riferimento, che hanno come cella_adiacente la cella riparentata
          dn_wbts_old = wbts_in_reparenting.values.map { |xxx| xxx[:dist_name] }
          np_rel_adj = meta_entita_relazioni_adiacenza[RETE_UMTS].keys
          # puts "---- DEL di relazioni_adiacenza np in #{np_rel_adj}, cella_adiacente in #{lista_celle_delete}"
          dataset_r.where(naming_path: np_rel_adj, cella_adiacente: lista_celle_delete).each do |eee_rel_adj|
            # va in delete solo se non e' figlia di qualche WBTS riparentato (altrimenti e' in delete per il giro precedente)
            next if eee_rel_adj[:dist_name].start_with?(*dn_wbts_old) # TODO: Provare in alternativa NOT IN lista_rel_adj_cancellate_tra_le_figlie nella query...
            eee_del = { operazione: MANAGED_OBJECT_OPERATION_DELETE,
                        dist_name: eee_rel_adj[:dist_name],
                        naming_path: eee_rel_adj[:naming_path] }
            yield eee_del
          end
        end
      end
      #
      definisci_classe_rete(rete: RETE_LTE) do
        default_cella_naming_path       'PLMN;MRBTS;LNBTS;LNCEL'
        default_formato_audit           DEFAULT_FORMATO_AUDIT_IDL
        default_nodo_naming_path        'PLMN;MRBTS'
        meta_entita_adiacenza           RETE_GSM  => %w(PLMN;EXCCG;EXGCE),
                                        RETE_UMTS => %w(PLMN;EXCCU;EXUCE),
                                        RETE_LTE  => %w(PLMN;EXCENBF;EXENBF)
        meta_entita_relazioni_adiacenza RETE_GSM  => { 'PLMN;MRBTS;LNBTS;LNADJG' => %w(targetCellDn) },
                                        RETE_UMTS => { 'PLMN;MRBTS;LNBTS;LNADJW' => %w(targetCellDn) },
                                        RETE_LTE  => { 'PLMN;MRBTS;LNBTS;LNADJ' => %w(targetBtsDn) }
        pr_campi_adiacenza              %w(ADJ UADJ GADJ)
        pr_campi_per_controlli          %w(PCI EARFCNUL)
        pr_nome_id_nodo                 'ENODEBID'
        pr_nome_nodo                    'E_NODEB_NAME'
        pr_nome_release_nodo            'ENODEB_REL'

        def naming_path_del_rel_adj
          'PLMN;MRBTS;LNBTS'
        end

        def _query_rel_adj(table_name:, naming_path_list:, **opts)
          lista_padri = (opts[:celle] || []).map { |ccc| ccc.split(DIST_NAME_SEP)[0..-2].join(DIST_NAME_SEP) }
          query = "select dist_name, naming_path from #{table_name}"
          query += " where naming_path in (#{naming_path_list.map { |np| "'#{np}'" }.join(',')})"
          query += " and cella_sorgente in (#{lista_padri.map { |pp| "'#{pp}'" }.join(',')})"
          query
        end

        def estrai_cs_ca_da_relazione(entita)
          _estrai_cs_ca_da_relazione(entita)
        end
      end
      #
      definisci_classe_rete(rete: RETE_5G) do
        default_cella_naming_path       'PLMN;MRBTS;NRBTS;NRCELL'
        default_formato_audit           DEFAULT_FORMATO_AUDIT_IDL
        default_nodo_naming_path        'PLMN;MRBTS'
        meta_entita_adiacenza           RETE_GSM  => [],
                                        RETE_UMTS => [],
                                        RETE_LTE  => [] # TODO
        meta_entita_relazioni_adiacenza RETE_GSM  => {},
                                        RETE_UMTS => {},
                                        RETE_LTE  => { 'PLMN;MRBTS;NRBTS;NRCELL;NRRELLTE' => [] },
                                        RETE_5G   => { 'PLMN;MRBTS;NRBTS;NRCELL;NRREL' => %w(targetCellDN) }

        pr_campi_adiacenza              %w(ADJ GADJ UADJ LADJ)
        # pr_campi_per_controlli          %w(PCI EARFCNUL)
        pr_nome_id_nodo                 'GNODEBID'
        pr_nome_nodo                    'GNODEB_NAME'
        pr_nome_release_nodo            'GNODEB_REL'

        def estrai_cs_ca_da_relazione(entita)
          _estrai_cs_ca_da_relazione(entita)
        end
      end
    end
  end
end
