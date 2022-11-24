# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190405
#

module Irma
  module Db
    #
    module NodoNodeb
      extends_host_with :ClassMethods
      #
      module ClassMethods
        def cleanup(_hash = {})
          cleanup_only_rebuild_indexes
        end

        def nodeb_rete
          raise NotImplementedError, "nodeb_rete non ancora implementato nella classe #{self.class}"
        end

        def nodeb_field_id
          raise NotImplementedError, "nodeb_field_id non ancora implementato nella classe #{self.class}"
        end

        def nodeb_field_name
          raise NotImplementedError, "nodeb_field_name non ancora implementato nella classe #{self.class}"
        end

        def nuovo_nodo(_nome_nodo:, _id_nodo: nil, _lock: true)
          raise NotImplementedError, "nuovo_nodo non ancora implementato nella classe #{self.class}"
        end

        def range_totale(area_terr)
          range = nil
          begin
            range = Irma::Constant.info(:area_territoriale, area_terr)[:range][nodeb_rete]
          rescue => _e
            return nil
          end
          range_tot = []
          (range || []).each { |rr| range_tot << (rr[0]..rr[1]).to_a.map(&:to_s) unless rr.empty? }
          range_tot.flatten
        end

        def free_ids(area_terr)
          totale = range_totale(area_terr)
          return [] unless totale
          id_occupati = where(area_territoriale: area_terr).select_map(nodeb_field_id)
          totale - id_occupati
        end

        def new_id_anagrafica(area_terr:, id_nodo:)
          ids = free_ids(area_terr).map(&:to_i)
          new_id = ids.empty? ? nil : ids.min.to_s
          id_nodo && id_nodo.numeric? && ids.include?(id_nodo.to_i) ? id_nodo : new_id
        end

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists
        def crea_nuovo_nodo(nome:, id_nodeb:, funzione_obj:, area_territoriale:, tipo_segnalazione_no_at:, tipo_segnalazione_id_anagrafato:)
          nome_nodo = nome.upcase
          nodo_per_id = first(nodeb_field_id => id_nodeb)
          nodo = nuovo_nodo(nome_nodo: nome_nodo, id_nodo: id_nodeb, lock: false)
          log_prefix = (funzione_obj && funzione_obj.log_prefix) || "Crea nuovo nodo #{nodeb_field_name}"
          id_nodeb ||= ''
          if !id_nodeb.empty? && !(id_nodeb.numeric? && range_totale(area_territoriale).include?(id_nodeb))
            funzione_obj && funzione_obj.nuova_segnalazione(tipo_segnalazione_no_at, nodeb_id: id_nodeb, area_territoriale: area_territoriale, nodeb_name: nome_nodo,
                                                                                     new_nodeb_id: nodo[nodeb_field_id])
            logger.warn("#{log_prefix} Id '#{id_nodeb}' non corretto per l'area territoriale '#{area_territoriale}'. Al nodo '#{nome_nodo}' viene assegnato l'id '#{nodo[nodeb_field_id]}'.")
          elsif nodo_per_id
            funzione_obj && funzione_obj.nuova_segnalazione(tipo_segnalazione_id_anagrafato, new_nodeb_id: nodo[nodeb_field_id], old_nodeb_id: nodo_per_id[nodeb_field_id],
                                                                                             new_nodeb_name: nodo[nodeb_field_name], old_nodeb_name: nodo_per_id[nodeb_field_name])
            msg = "#{log_prefix} L'id '#{id_nodeb}' è già presente in anagrafica associato al nodo #{nodo_per_id[nodeb_field_name]}."
            msg << "Al nodo '#{nome_nodo}' viene assegnato l'id '#{nodo[nodeb_field_id]}'."
            logger.info(msg)
          end
          nodo
        end

        def elimina_nodo(hash)
          # hash = { id: 72637, enodeb_name/gnodeb_name: 'CHxxx', enodeb_id/gnodeb_id: '111111'}
          raise "Condizioni di cancellazione #{nodeb_field_id} non valide (#{hash})" if ((hash || {}).keys & [:id, nodeb_field_name, nodeb_field_id]).empty?
          con_lock(logger: logger) do
            x = where(hash)
            x.map(&:destroy) if x
          end
        end
      end
    end
  end
end
