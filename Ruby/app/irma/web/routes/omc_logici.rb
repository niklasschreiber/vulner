# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170422
#

module Irma
  #
  module Web
    class App < Roda
      def records_omc_logici_competenza(filtrati: true, allow_blank: false)
        sdcf = id_sistemi_di_competenza_filtrati
        res = allow_blank ? [{ id: 0, full_descr: format_msg(:STORE_TUTTI_I_SISTEMI) }] : []
        records_competenza(request, :sistemi).sort_by { |x| x[:full_descr] }.select do |record|
          res << record unless filtrati && !sdcf.include?(record[:id])
        end
        res
      end

      def _omc_logico_record_values(record) # rubocop:disable Metrics/AbcSize
        record.values.merge(
          full_descr:     record.full_descr,
          rete:           Constant.label(:rete, record[:rete_id]),
          vendor_release: Db::VendorRelease.get_by_pk(record[:vendor_release_id]).descr,
          omc_fisico:     Db::OmcFisico.get_by_pk(record[:omc_fisico_id]).nome,
          vendor_id:      Db::VendorRelease.get_by_pk(record[:vendor_release_id]).vendor.id,
          created_at:     timestamp_to_string(record[:created_at]),
          updated_at:     timestamp_to_string(record[:updated_at])
        )
      end

      def grid_omc_logici(filtrati: true) # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        query = Db::Sistema
        query = query.where(id: filtro_sistemi) if filtrati && !funzione_abilitata?(FUNZIONE_GESTIONE_ANAGRAFICA)
        records_with_export(filtro, 'filename' => 'export_omc_logici_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.order(:descr, :rete_id).each do |record|
            formatter.add_record_values(record, _omc_logico_record_values(record))
          end
        end
      end

      def list_omc_logici(filtrati: true) # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        query = Db::Sistema
        query = query.where(id: filtro_sistemi) if filtrati && !funzione_abilitata?(FUNZIONE_GESTIONE_ANAGRAFICA)
        query = query.where(omc_fisico_id: filtro[:omc_fisico_id]) if filtro[:omc_fisico_id] && !filtro[:omc_fisico_id].empty?
        ret = query.map { |record| _omc_logico_record_values(record) }
        ret.sort_by { |x| x[:full_descr] }
      end

      def grid_omc_logici_entity_records
        entity_records(klass: Db::Sistema, filtro_id: :sistemi, extra_field: 'Sistema')
      end

      def grid_omc_logici_entity_types # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        query = Db::MetaEntita
        vquery = nil
        if filtro[:vendor_releases]
          vquery = Db::VendorRelease.where(id: filtro[:vendor_releases]).select(:id)
          vquery = vquery.where(rete_id: filtro[:reti]) if filtro[:reti]
        else
          fs = ((filtro[:sistemi] ||= filtro_sistemi) || [])
          unless fs.empty?
            vquery = Db::Sistema.where(id: fs).select(:vendor_release_id)
            vquery = vquery.where(rete_id: filtro[:reti]) if filtro[:reti]
          end
        end
        query = query.where(vendor_release_id: vquery) if vquery
        query = add_like_conditions(query: query, field: :nome,        pattern: filtro[:meta_entita])
        query = add_like_conditions(query: query, field: :naming_path, pattern: filtro[:naming_path])

        query = query.select(:nome, :naming_path, :vendor_release_id, :id)
        res = []
        last_naming_path = nil
        query.order(:nome, :naming_path).each do |record|
          naming_path = record[:naming_path]
          next unless last_naming_path != naming_path
          vr = Db::VendorRelease.get_by_pk(record[:vendor_release_id])
          rete = Constant.label(:rete, vr.rete_id)
          full_name = full_name_metaentita(record[:nome], record[:naming_path], vr.descr, rete)
          res << { id: record[:id], rete: rete, vendor_release: vr.descr, m_entita: record[:nome], naming_path: record[:naming_path], full_name: full_name }
          last_naming_path = naming_path
        end
        res
      end
    end

    App.route('omc_logici') do |r|
      r.get('competenza/list') do
        handle_request { records_omc_logici_competenza }
      end
      r.post('competenza_non_filtrati/grid') do
        handle_request { records_omc_logici_competenza(filtrati: false) }
      end
      r.post('elimina') do
        handle_request(error_msg_key: :ELIMINAZIONE_OMC_LOGICO_FALLITA) do
          row_id = JSON.parse(request.params['id'] || '[]')
          Db::Sistema.where(id: row_id).destroy
          format_msg(:OMC_LOGICO_ELIMINATO)
        end
      end
      r.post('entity/grid') do
        handle_request { grid_omc_logici_entity_records }
      end
      r.post('entity_types/grid') do
        handle_request { grid_omc_logici_entity_types }
      end
      r.post('export_formato_utente/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_formato_utente(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('export_formato_utente_parziale/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_formato_utente_parziale(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('grid') do
        handle_request { grid_omc_logici }
      end
      r.post('import_costruttore/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_import_costruttore(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('import_formato_utente/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_import_formato_utente(parametri, opzioni_attivita_schedulata)
        end
      end
      r.get('non_filtrati/list') do
        handle_request { list_omc_logici(filtrati: false) }
      end
      r.post('salva') do
        params = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        handle_request(error_msg_key: params[:id].to_s.empty? ? :INSERIMENTO_OMC_LOGICO_FALLITO : :AGGIORNAMENTO_OMC_LOGICO_FALLITO) do
          record = { area_sistema: params[:area_sistema], omc_fisico_id: params[:of], vendor_release_id: params[:vendor_release_rete],
                     rete_id: Db::VendorRelease.get_by_pk(params[:vendor_release_rete]).rete_id, nome_file_audit: params[:nome_file_audit] }
          record[:id] = params[:id] if params[:id]
          record[:descr] = params[:descr] if params[:descr]
          if record[:id]
            ol = Db::Sistema.first(id: record[:id])
            ol.nome_file_audit = record[:nome_file_audit]
            ol.rete_id = record[:rete_id]
            ol.area_sistema = record[:area_sistema]
            ol.omc_fisico_id = record[:omc_fisico_id]
            ol.header_pr = {} unless ol.header_pr
            ol.vendor_release_id = record[:vendor_release_id]
            ol.azzera_dati_ade(azzera: params[:azzera_dati_ade])
          else
            query = Db::Sistema.where(descr: record[:descr], vendor_release_id: record[:vendor_release_id])
            vr_ref = Db::VendorRelease.get_by_pk(record[:vendor_release_id])
            raise "Esiste già un Omc Logico con nome #{record[:descr]}, associato alla vendor release #{vr_ref.full_descr}." unless query.empty?
            query = Db::Sistema.where(descr: record[:descr], area_sistema: record[:area_sistema], rete_id: record[:rete_id])
            unless query.empty?
              raise "Esiste già un Omc Logico con nome #{record[:descr]}, associato all\' area sistema #{record[:area_sistema]} ed alla rete #{Constant.label(:rete, record[:rete_id])}."
            end
            ol = Db::Sistema.new(record)
          end
          ol.save_changes
          format_msg(record[:id].to_s.empty? ? :OMC_LOGICO_INSERITO : :OMC_LOGICO_AGGIORNATO)
        end
      end
      r.post('column_filter/grid') do
        handle_request { grid_column_filter }
      end
    end
  end
end
