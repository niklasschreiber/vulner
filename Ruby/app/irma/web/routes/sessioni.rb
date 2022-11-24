# vim: set fileencoding=utf-8
#
# Author       : G. Pisa
#
# Creation date: 20161004
#

module Irma
  #
  module Web
    #
    class App < Roda
      def _sessioni_filtro # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        filtro.delete(:ambiente) if filtro[:ambiente].eql? format_msg(:STORE_TUTTI_GLI_AMBIENTI)
        filtro.delete(:profilo)  if filtro[:profilo].eql? format_msg(:STORE_TUTTI_I_PROFILI)
        if filtro[:profilo]
          profilo = Constant.info(:profilo, filtro[:profilo])
          filtro[:profilo] = profilo[:nome]
        end
        filtro
      end

      def _filtro_parametri_export(filtro)
        filtro_export_params = { export_format: filtro[:export_format], export_selection: filtro[:export_selection], export_columns: filtro[:export_columns], sheet_name: filtro[:sheet_name] }

        filtro.delete(:export_format)
        filtro.delete(:export_selection)
        filtro.delete(:export_columns)
        filtro.delete(:sheet_name)

        filtro_export_params
      end

      def grid_sessioni_attive # rubocop:disable Metrics/AbcSize
        filtro = _sessioni_filtro

        filtro_export_params = _filtro_parametri_export(filtro)

        query = Db::Sessione

        f = filtro.delete(:matricola).to_s
        query = add_like_conditions(query: query, field: :matricola, pattern: f, extra_field: :utente_descr) unless f.empty?

        records_with_export(filtro_export_params, 'filename' => 'export_sessioni_attive_@FULL_DATE@@ESTENSIONE@', 'export' => filtro_export_params['export_format']) do |formatter|
          query.where(filtro).reverse_order(:updated_at).each do |record|
            rec_val = record.values.merge(
              durata:     (record[:updated_at] - record[:created_at]).round,
              created_at: timestamp_to_string(record[:created_at])
            )
            rec_val.delete(:data)
            formatter.add_record_values(record, rec_val)
          end
        end
      end

      def grid_sessioni_chiuse # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        filtro = _sessioni_filtro

        filtro_export_params = _filtro_parametri_export(filtro)

        query = Db::SessioneChiusa

        f = filtro.delete(:matricola).to_s
        query = add_like_conditions(query: query, field: :matricola, pattern: f, extra_field: :utente_descr) unless f.empty?

        f = filtro.delete(:host).to_s
        query = add_like_conditions(query: query, field: :host, pattern: f) unless f.empty?
        { data_login: :created_at, data_logout: :created_at }.each do |prefix, field|
          { da: '>=', a: '<=' }.each do |suffix, oper|
            query = aggiungi_filtro_data(query, filtro.delete("#{prefix}_#{suffix}".to_sym), field, oper)
          end
        end
        records_with_export(filtro_export_params, 'filename' => 'export_sessioni_chiuse_@FULL_DATE@@ESTENSIONE@', 'export' => filtro_export_params['export_format']) do |formatter|
          query.where(filtro).reverse_order(:ended_at).each do |record|
            rec_val = record.values.merge(
              durata:     (record[:updated_at] - record[:created_at]).round,
              created_at: timestamp_to_string(record[:created_at]),
              ended_at:   timestamp_to_string(record[:ended_at])
            )
            rec_val.delete(:data)
            formatter.add_record_values(record, rec_val)
          end
        end
      end
    end

    App.route('sessioni') do |r|
      r.post('attive/grid') do
        handle_request { grid_sessioni_attive }
      end
      r.post('chiuse/grid') do
        handle_request { grid_sessioni_chiuse }
      end
    end
  end
end
