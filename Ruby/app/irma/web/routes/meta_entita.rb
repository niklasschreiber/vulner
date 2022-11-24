# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170508
#

module Irma
  #
  module Web
    #
    class App < Roda
      def grid_meta_entita # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        query = Db::MetaEntita
        query = query.where(nome: filtro[:meta_entita_selected]) if filtro[:meta_entita_selected]
        query = query.where(vendor_release_id: filtro[:vendor_releases]) if filtro[:vendor_releases]
        query.order(:nome).map do |record|
          fase_calcolo = Constant.label(:fase_calcolo, record[:fase_di_calcolo]) if record[:fase_di_calcolo]
          vr = Db::VendorRelease.get_by_pk(record[:vendor_release_id])
          record.values.merge(vendor_release_full_descr: vr.full_descr, vendor_release: vr.descr,
                              created_at: timestamp_to_string(record[:created_at]), updated_at: timestamp_to_string(record[:updated_at]),
                              fase_di_calcolo: fase_calcolo, regole_calcolo: JSON.generate(record[:regole_calcolo]),
                              regole_calcolo_ae: JSON.generate(record[:regole_calcolo_ae]), rete: Constant.label(:rete, vr.rete_id))
        end
      end

      def grid_mm_meta_entita # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        query = Db::MetaEntita.select(:id, :naming_path, :nome, :vendor_release_id)
        query = query.where(naming_path: filtro[:meta_entita_selected]) if filtro[:meta_entita_selected]
        query = query.where(vendor_release_id: filtro[:vendor_releases]) if filtro[:vendor_releases]
        query.order(:nome).map do |record|
          vr = Db::VendorRelease.get_by_pk(record[:vendor_release_id])
          record.values.merge(vendor_release: vr.descr,
                              created_at: timestamp_to_string(record[:created_at]),
                              updated_at: timestamp_to_string(record[:updated_at]),
                              type: 'E')
        end
      end

      def list_meta_entita # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        return [] unless filtro[:filtro_metamodello]
        filtro_metamodello = filtro[:filtro_metamodello] || {}
        naming_paths = filtro_metamodello.keys.uniq
        omc_fisico = filtro[:omc_fisico]
        keywords_metamodello = MetaModello.keywords_fisico_logico(omc_fisico)
        query = keywords_metamodello.classe_meta_entita
        query = query.where(naming_path: naming_paths)
        query = query.where(keywords_metamodello.field_vr_id.to_sym => filtro[:vendor_releases]) if filtro[:vendor_releases]
        query.order(:nome).all.map do |record|
          vr = keywords_metamodello.classe_vendor_release.get_by_pk(record[keywords_metamodello.field_vr_id.to_sym])
          rete_id = Constant.label(:rete, vr.rete_id) unless omc_fisico
          {
            naming_path: record[:naming_path],
            full_name: full_name_metaentita(record[:nome], record[:naming_path], vr.descr, (rete_id || nil))
          }
        end
      end

      def meta_entita_modifica # rubocop:disable Metrics/AbcSize
        handle_request(error_msg_key: :AGGIORNAMENTO_METAMODELLO_FALLITO) do
          filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
          id = filtro.delete(:id)
          rete_adj_id = filtro.delete(:rete_adj_id)
          filtro[:rete_adj] = (rete_adj_id.nil? || rete_adj_id == '') ? nil : Constant.label(:rete, rete_adj_id)
          Db::MetaEntita.where(id: id).each do |me|
            me.update(filtro)
          end
          format_msg(:AGGIORNAMENTO_METAMODELLO_ESEGUITO)
        end
      end

      def meta_entita_elimina
        handle_request(error_msg_key: :ELIMINAZIONE_METAENTITA_FALLITA) do
          filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
          me = Db::MetaEntita.first(id: filtro[:id])
          if filtro[:type] == 'RICORSIVA'
            me.destroy_con_gerarchia(audit_extra_info: nil)
          else
            me.destroy_con_shift_gerarchia(audit_extra_info: nil)
          end
          format_msg(:ELIMINAZIONE_METAENTITA_ESEGUITA)
        end
      end

      def meta_entita_aggiungi # rubocop:disable Metrics/AbcSize
        handle_request(error_msg_key: :INSERIMENTO_METAENTITA_FALLITO) do
          filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
          rete_adj_id = filtro.delete(:rete_adj_id)
          filtro[:naming_path] = filtro[:nome] if filtro[:pid].nil?
          filtro[:rete_adj] = (rete_adj_id.nil? || rete_adj_id == '') ? nil : Constant.label(:rete, rete_adj_id)
          Db::MetaEntita.create_with_audit(audit_extra_info: nil, attributes: filtro)
          format_msg(:INSERIMENTO_METAENTITA_ESEGUITO)
        end
      end

      def list_meta_entita_riferimento
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        return [] unless filtro[:vendor_release_id]
        me = Db::MetaEntita
        query = me.where(vendor_release_id: filtro[:vendor_release_id], fase_di_calcolo: FASE_CALCOLO_PI)
        query.select([:naming_path]).order(:naming_path).all.map do |record|
          {
            id: record[:naming_path],
            descr: record[:naming_path]
          }
        end
      end

      def list_columns_meta_entita
        me = Db::MetaEntita
        me.mapped_columns_per_file_adrn.sort.map do |record|
          {
            descr: record
          }
        end
      end
    end

    App.route('meta_entita') do |r|
      r.post('grid') do
        handle_request { grid_meta_entita }
      end
      r.post('mm/grid') do
        handle_request { grid_mm_meta_entita }
      end
      r.post('modifica') do
        handle_request { meta_entita_modifica }
      end
      r.post('elimina') do
        handle_request { meta_entita_elimina }
      end
      r.post('aggiungi') do
        handle_request { meta_entita_aggiungi }
      end
      r.post('aggiorna') do
        handle_request(error_msg_key: :AGGIORNAMENTO_METAMODELLO_FALLITO) do
          update_info = JSON.parse(request.params['updateInfo'] || '{}').symbolize_keys
          meta_entita = Db::MetaEntita.get_by_pk(update_info[:meta_entita_id] || update_info[:id])
          regole = JSON.parse(update_info[:regole_calcolo]) if update_info[:regole_calcolo]
          regole_ae = JSON.parse(update_info[:regole_calcolo_ae]) if update_info[:regole_calcolo_ae]
          meta_entita[:regole_calcolo] = regole if regole
          meta_entita[:regole_calcolo_ae] = regole_ae if regole_ae
          meta_entita.save
          format_msg(:AGGIORNAMENTO_METAMODELLO_ESEGUITO)
        end
      end
      r.post('list') do
        handle_request { list_meta_entita }
      end
      r.post('riferimento/list') do
        handle_request { list_meta_entita_riferimento }
      end
      r.post('columns/list') do
        handle_request { list_columns_meta_entita }
      end
    end
  end
end
