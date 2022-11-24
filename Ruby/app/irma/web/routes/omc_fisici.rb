# vim: set fileencoding=utf-8
#
# Author       : G. Pisa, G. Cristelli
#
# Creation date: 20161004
#

module Irma
  #
  module Web
    class App < Roda
      def records_omc_fisici_competenza(filtrati: true, allow_blank: false) # rubocop:disable Metrics/AbcSize
        ofdcf = id_omc_fisici_di_competenza_filtrati
        res = allow_blank ? [{ id: 0, full_descr: format_msg(:STORE_TUTTI_GLI_OMC_FISICI) }] : []
        records_competenza(request, :omc_fisici).sort_by { |x| x[:full_descr] }.select do |record|
          next if filtrati && !ofdcf.include?(record[:id])
          omc_fisico = Db::OmcFisico.get_by_pk(record[:id])
          vendor_release_id = omc_fisico.vendor_release_id || []
          record[:sistemi] = omc_fisico.sistemi.map { |s| s[:id] }
          record[:vendor_release] = vendor_release_id.map { |vrid| { id: vrid, descr: Db::VendorRelease.get_by_pk(vrid).descr } }
          vendor_release_fisico_id = omc_fisico.vendor_release_fisico_id
          record[:vendor_release_fisico_id] = vendor_release_fisico_id
          record[:vendor_release_fisico] = Db::VendorReleaseFisico.get_by_pk(vendor_release_fisico_id).descr
          res << record
        end
        res
      end

      def grid_omc_fisici # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        query = Db::OmcFisico
        query = query.where(id: Db::Sistema.where(id: filtro_sistemi).distinct.select_map(:omc_fisico_id)) unless funzione_abilitata?(FUNZIONE_GESTIONE_ANAGRAFICA)
        records_with_export(filtro, 'filename' => 'export_omc_fisici_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.each do |record|
            sistemi = record.sistemi
            rec_val = record.values.merge(vendor: Constant.label(:vendor, record[:vendor_id]), omc_logici: sistemi.map(&:descr).sort.join(', '),
                                          formato_audit: record.formato_audit, sistemi_collegati: sistemi.count, created_at: timestamp_to_string(record[:created_at]),
                                          updated_at: timestamp_to_string(record[:updated_at])
                                         )
            formatter.add_record_values(record, rec_val)
          end
        end
      end

      def grid_omc_fisici_entity_records
        entity_records(klass: Db::OmcFisico, filtro_id: :omc_fisici, extra_field: 'OmcFisico')
      end

      def list_omc_fisici # rubocop:disable Metrics/AbcSize
        query = Db::OmcFisico
        v_id = Db::VendorRelease.get_by_pk(request.params['vendor_release_id']).vendor_id if request.params['vendor_release_id']
        query = query.where(vendor_id: v_id || request.params['vendor_id']) if v_id || request.params['vendor_id']
        query.select(:id, :nome).order(:nome).map do |record|
          { id: record[:id], descr: d = record[:nome], full_descr: d }
        end
      end
    end

    App.route('omc_fisici') do |r|
      r.get('competenza/list') do
        handle_request { records_omc_fisici_competenza }
      end
      r.post('elimina') do
        handle_request(error_msg_key: :ELIMINAZIONE_OMC_FISICO_FALLITA) do
          row_id = JSON.parse(request.params['id'] || '[]')
          Db::OmcFisico.where(id: row_id).destroy
          format_msg(:OMC_FISICO_ELIMINATO)
        end
      end
      r.post('entity/grid') do
        handle_request { grid_omc_fisici_entity_records }
      end
      r.post('export_formato_utente/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_formato_utente(parametri, opzioni_attivita_schedulata.merge(omc_fisico: true))
        end
      end
      r.post('export_formato_utente_parziale/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_formato_utente_parziale(parametri, opzioni_attivita_schedulata.merge(omc_fisico: true))
        end
      end
      r.post('grid') do
        handle_request { grid_omc_fisici }
      end
      r.post('import_costruttore/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_import_costruttore(parametri, opzioni_attivita_schedulata.merge(omc_fisico: true))
        end
      end
      r.post('import_formato_utente/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_import_formato_utente(parametri, opzioni_attivita_schedulata.merge(omc_fisico: true))
        end
      end
      r.get('list') do
        handle_request { list_omc_fisici }
      end
      r.post('salva') do
        record = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        handle_request(error_msg_key: record[:id].to_s.empty? ? :INSERIMENTO_OMC_FISICO_FALLITO : :AGGIORNAMENTO_OMC_FISICO_FALLITO) do
          record[:formato_audit] = record[:formato_audit].to_json if record[:formato_audit]
          if record[:id]
            of = Db::OmcFisico.get_by_pk(record[:id])
            of.nome_file_audit = record[:nome_file_audit]
            of.formato_audit = record[:formato_audit]
          else
            query = Db::OmcFisico.where(nome: record[:nome])
            raise "Esiste già un Omc Fisico con nome #{record[:nome]}." unless query.empty?
            of = Db::OmcFisico.new(record)
          end
          of.save
          format_msg(record[:id].to_s.empty? ? :OMC_FISICO_INSERITO : :OMC_FISICO_AGGIORNATO)
        end
      end
      r.post('column_filter/grid') do
        handle_request { grid_column_filter }
      end
    end
  end
end
