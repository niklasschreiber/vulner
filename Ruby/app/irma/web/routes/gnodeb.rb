# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190401
#

module Irma
  #
  module Web
    #
    class App < Roda
      def salva_gnodeb # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        if request.params['radioFields'] == 'stringa_nome'
          handle_request(error_msg_key: :INSERIMENTO_GNODEB_FALLITO) do
            raise 'Specificare un nome per il nodo' if (request.params['stringa_nome'] || '').empty?
            id = request.params['id_gnodeb'].strip || '' if request.params['id_gnodeb']
            at = AnagraficaTerritoriale.at_di_provincia(AnagraficaTerritoriale.provincia_da_nome_cella(request.params['stringa_nome'].upcase)).first
            msg = if !id.empty? && !(id.numeric? && Db::AnagraficaGnodeb.range_totale(at).include?(id))
                    :GNODEB_ID_ERRATO
                  elsif Db::AnagraficaGnodeb.first(gnodeb_id: id)
                    :GNODEB_ID_ESISTENTE
                  else
                    :GNODEB_INSERITO
                  end
            nuovo_nodo = Db::AnagraficaGnodeb.nuovo_nodo(nome_nodo: request.params['stringa_nome'], id_nodo: id)
            format_msg(msg, gnodeb_name: nuovo_nodo.gnodeb_name, gnodeb_id: nuovo_nodo.gnodeb_id)
          end
        else
          schedula_attivita do |parametri, opts_as|
            (opts_as || {}).update(input_file: post_locfile_to_shared_fs(locfile: parametri['file_gnodeb'], dir: opts_as[:attivita_schedulata_dir]))
            Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_NUOVO_GNODEBID, opts_as)
          end
        end
      end

      def grid_gnodeb # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        query = Db::AnagraficaGnodeb
        filtro.delete(:area_territoriale) if filtro[:area_territoriale].eql? format_msg(:STORE_TUTTE_LE_AREE_TERRITORIALI)

        # filtro enodeb_id
        f = filtro.delete(:gnodeb_id).to_s
        query = add_like_conditions(query: query, field: :gnodeb_id, pattern: f) unless f.empty?
        # filtro enodeb_name
        f = filtro.delete(:gnodeb_name).to_s
        query = add_like_conditions(query: query, field: :gnodeb_name, pattern: f) unless f.empty?
        # filtro area_territoriale
        f = filtro.delete(:area_territoriale).to_s
        query = query.where(area_territoriale: f) unless f.empty?
        # filtro data_aggiornamento
        { da: '>=', a: '<=' }.each { |suffix, oper| query = aggiungi_filtro_data(query, filtro.delete("data_aggiornamento_#{suffix}".to_sym), 'updated_at', oper) }

        records_with_export(filtro, 'filename' => 'export_gnodeb_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.order(:gnodeb_name).each do |record|
            rec_val = record.values.merge(updated_at: timestamp_to_string(record[:updated_at]))
            formatter.add_record_values(record, rec_val)
          end
        end
      end

      App.route('gnodeb') do |r|
        r.post('salva') do
          salva_gnodeb
        end
        r.post('grid') do
          handle_request { grid_gnodeb }
        end
        r.post('elimina') do
          handle_request(error_msg_key: :ELIMINAZIONE_GNODEB_FALLITA) do
            row_id = JSON.parse(request.params['id'] || '[]')
            res = Db::AnagraficaGnodeb.elimina_nodo(id: row_id)
            raise "Impossibile cancellare il nodo con id #{row_id}" if res.empty?
            format_msg(:GNODEB_ELIMINATO)
          end
        end
      end
    end
  end
end
