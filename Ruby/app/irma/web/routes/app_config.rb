# vim: set fileencoding=utf-8
#
# Author       : M. Cutillo, G. Cristelli
#
# Creation date: 20161003
#

module Irma
  #
  module Web
    #
    class App < Roda
      def _app_config_filtro(field, valore)
        q = nil
        if field
          x = "*#{valore}*".tr('*', '%')
          q = Sequel.ilike(field, x)
        end
        q
      end

      def grid_app_config # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        sessione = logged_in
        query = Db::AppConfig.where(ambito: [APP_CONFIG_AMBITO_GUI, APP_CONFIG_AMBITO_GUI_NON_MODIFICABILE])
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys

        # applica filtro profilo
        id_profilo = sessione.data[:id_profilo_corrente]
        query = query.where("profili::jsonb ?| array['#{id_profilo}']") if id_profilo
        # applica filtri
        %i(modulo nome valore valore_di_default).each do |k|
          query = query.where(_app_config_filtro(k, filtro[k])) if filtro[k]
        end
        records_with_export(filtro, 'filename' => 'export_parametri_sistema_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.order(:modulo, :nome).each do |record|
            rec_val = record.values.merge(
              valore:            record.valore,
              valore_di_default: record.valore_di_default,
              created_at:        timestamp_to_string(record[:created_at]),
              updated_at:        timestamp_to_string(record[:updated_at])
            )
            formatter.add_record_values(record, rec_val)
          end
        end
      end
    end

    App.route('app_config') do |r|
      r.post('grid') do
        handle_request { grid_app_config }
      end
      r.post('salva') do
        handle_request(error_msg_key: :AGGIORNAMENTO_APP_CONFIG_FALLITO) do
          update_record = JSON.parse(request.params['record'] || '{}').symbolize_keys
          ac = Db::AppConfig.first(id: update_record[:id])
          ac.update(valore: update_record[:valore]) if ac
          format_msg(:AGGIORNAMENTO_APP_CONFIG_ESEGUITO)
        end
      end
    end
  end
end
