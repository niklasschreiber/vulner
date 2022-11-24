# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20170725
#

module Irma
  #
  module Web
    class App < Roda
      def grid_template_progetto_radio # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
        results = []
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        if filtro[:vendor_releases]
          query = Db::VendorRelease.where(id: filtro[:vendor_releases]).order(:descr)
          regexp = filtro[:nome_campo] ? add_regexp_conditions(input: filtro[:nome_campo]) : nil
          query.map do |record|
            posizione = 1
            next unless record[:header_pr]
            record[:header_pr].each do |key, value|
              if !regexp || regexp =~ key
                result = {
                  id:         "#{record[:id]} - #{posizione}",
                  descr:      record[:descr],
                  full_descr: record.full_descr,
                  nome_campo: key,
                  tipo:       value['tipo'],
                  posizione:  posizione,
                  vr_id:      record[:id]
                }
                results << result
              end
              posizione += 1
            end
          end
        end
        results
      end

      def elimina_parametro_pr # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        handle_request(error_msg_key: :ELIMINAZIONE_PARAMETRO_PR_FALLITA) do
          raise "Non esiste nessuna Vendor Release con id '#{filtro[:vr_id]}'" unless (vr = Db::VendorRelease.first(id: filtro[:vr_id].to_i))
          [Db::Sistema.where(vendor_release_id: vr.id).all, vr].flatten.each do |obj|
            header_pr = (obj[:header_pr] || {}).dup
            is_p_found = false
            if header_pr[filtro[:param]]
              header_pr.delete(filtro[:param])
              is_p_found = true
            end
            next unless is_p_found
            obj.update(header_pr: header_pr)
          end
          format_msg(:ELIMINAZIONE_PARAMETRO_PR_ESEGUITA)
        end
      end
    end

    App.route('template_progetto_radio') do |r|
      r.post('grid') do
        handle_request { grid_template_progetto_radio }
      end
      r.post('salva') do
        handle_request(error_msg_key: :AGGIORNAMENTO_TEMPLATE_PR_FALLITO) do
          update_record = JSON.parse(request.params['record'] || '{}').symbolize_keys
          vr = Db::VendorRelease.first(id: update_record[:id].to_i)
          vr[:header_pr][update_record[:nome_campo]] = { 'tipo' => update_record[:tipo] }
          vr.save
          vr.propaga_header_pr
          format_msg(:AGGIORNAMENTO_TEMPLATE_PR_ESEGUITO)
        end
      end
      r.post('elimina') do
        elimina_parametro_pr
      end
    end
  end
end
