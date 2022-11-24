# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20181007
#

module Irma
  # rubocop:disable ModuleLength
  module ConteggioEccezioniUtil
    include FiltroEntitaUtil
    NO_LABEL = 'Eccezioni_NC'.freeze

    def eccezioni_totali(conters_per_etichetta:)
      conters_per_etichetta.nil? ? nil : conters_per_etichetta.values.inject(:+)
    end

    def eccezioni_nette(conters_per_etichetta:, labels_nette: nil)
      return nil if conters_per_etichetta.nil?
      labels_nette ||= Db::EtichettaEccezioni.load_hash_labels_nette
      tot_nette = 0
      (conters_per_etichetta || {}).each do |label, cnt|
        tot_nette += cnt if label == NO_LABEL || labels_nette[label]
      end
      tot_nette
    end

    def filtro_parametri_np(naming_path, filtro_metamodello)
      xxx = filtro_metamodello && filtro_metamodello[naming_path] && filtro_metamodello[naming_path][FILTRO_MM_PARAMETRI]
      xxx == [META_PARAMETRO_ANY] ? nil : xxx
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def conteggio_eccezioni_per_etichetta_totale(sistema:, filtro_etichette: nil)
      res = {}
      return res if filtro_etichette && filtro_etichette.empty?
      dataset_el = Db::EntitaLabel.new(archivio: ARCHIVIO_LABEL,
                                       vendor: sistema.vendor_id, rete: sistema.rete_id,
                                       omc_logico: sistema.descr, omc_logico_id: sistema.id).dataset
      dataset = (filtro_etichette.nil? ? dataset_el : dataset_el.where(label: filtro_etichette))
      dataset.db.transaction do
        res = { NO_LABEL => 0 }
        query = dataset
        query = query.group_and_count(:label)
        query.each do |record|
          res[record[:label] == LABEL_NC_DB ? NO_LABEL : record[:label]] = record[:count]
        end
      end
      res
    end

    def conteggio_eccezioni_per_etichetta(sistema:, dist_name: nil, np_root: nil, filtro_etichette: nil, filtro_metamodello: nil)
      res = {}
      return res if filtro_etichette && filtro_etichette.empty?

      el = Db::EntitaLabel.new(archivio: ARCHIVIO_LABEL,
                               vendor: sistema.vendor_id, rete: sistema.rete_id,
                               omc_logico: sistema.descr, omc_logico_id: sistema.id)
      table_name_el = el.table_name
      dataset_el = el.dataset
      dataset = (filtro_etichette.nil? ? dataset_el : dataset_el.where(label: filtro_etichette)) # *** FILTRO_ETICHETTA
      level_root = np_root.to_s.split(NAMING_PATH_SEP).count if np_root

      dataset.db.transaction do
        if filtro_metamodello
          metamodello = sistema.metamodello
          np_da_considerare = filtro_metamodello ? (metamodello.meta_entita.keys & filtro_metamodello.keys) : metamodello.meta_entita.keys
          np_descendants = metamodello.naming_path_alberatura(np_root)

          (([np_root] + np_descendants) & np_da_considerare).each do |np|
            meta_entita = metamodello.meta_entita[np]
            next unless meta_entita
            filtro_parametri = filtro_parametri_np(np, filtro_metamodello)
            feu_info = feu_query_per_naming_path(naming_path: np, dataset: dataset,
                                                 filtro_np: (filtro_metamodello || {})[np],
                                                 nome_tabella: table_name_el, use_pid: false)
            query = feu_info[:feu_query_np]
            filtro_wi = feu_info[:feu_filtro_wi]
            query.each do |record|
              next if !filtro_wi.empty? && !feu_tengo?(record[:dist_name], filtro_wi) # ignorato per FILTRO_ENTITA
              next if filtro_parametri && !filtro_parametri.include?(record[:meta_parametro]) # ignorato per FILTRO_PARAMETRO
              dn_root = determina_dn_root(nil, level_root, record[:dist_name])
              next unless dn_root
              res[dn_root] ||= { NO_LABEL => 0 }
              lbl = record[:label] == LABEL_NC_DB ? NO_LABEL : record[:label]
              res[dn_root][lbl] ||= 0
              res[dn_root][lbl] += 1
            end
          end
        else
          query = dataset
          np_root_where_condition = "naming_path = '#{np_root}' OR naming_path like '#{np_root};%'"
          query = query.where(np_root_where_condition) unless np_root.nil?
          query = query.order(:dist_name)
          actual_dist_name = nil
          actual_dn_root = nil
          query.each do |record|
            dn_root = actual_dist_name == record[:dist_name] ? actual_dn_root : determina_dn_root(dist_name, level_root, record[:dist_name])
            actual_dist_name = record[:dist_name]
            actual_dn_root = dn_root
            next unless dn_root
            res[dn_root] ||= { NO_LABEL => 0 }
            lbl = record[:label] == LABEL_NC_DB ? NO_LABEL : record[:label]
            res[dn_root][lbl] ||= 0
            res[dn_root][lbl] += 1
          end
        end
      end
      res
    end

    def determina_dn_root(dist_name_list, level, dist_name)
      dn_root = nil
      if dist_name_list
        dist_name_list.each do |dn|
          if dist_name.start_with?(dn)
            dn_root = dn
            break
          end
        end
      else
        dn_root = dist_name.to_s.split(DIST_NAME_SEP)[0..(level - 1)].join(DIST_NAME_SEP)
      end
      dn_root
    end
    #---------------------------------------------------------------------------------
  end
end
