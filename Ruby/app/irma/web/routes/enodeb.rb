# vim: set fileencoding=utf-8
#
# Author       : R. Arcaro
#
# Creation date: 20170908
#

module Irma
  #
  module Web
    #
    class App < Roda
      def salva_enodeb # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        if request.params['radioFields'] == 'stringa_nome'
          handle_request(error_msg_key: :INSERIMENTO_ENODEB_FALLITO) do
            raise 'Specificare un nome per il nodo' if (request.params['stringa_nome'] || '').empty?
            id = request.params['id_enodeb'].strip || '' if request.params['id_enodeb']
            at = AnagraficaTerritoriale.at_di_provincia(AnagraficaTerritoriale.provincia_da_nome_cella(request.params['stringa_nome'].upcase)).first
            msg = if !id.empty? && !(id.numeric? && Db::AnagraficaEnodeb.range_totale(at).include?(id))
                    :ENODEB_ID_ERRATO
                  elsif Db::AnagraficaEnodeb.first(enodeb_id: id)
                    :ENODEB_ID_ESISTENTE
                  else
                    :ENODEB_INSERITO
                  end
            nuovo_nodo = Db::AnagraficaEnodeb.nuovo_nodo(nome_nodo: request.params['stringa_nome'], id_nodo: id)
            format_msg(msg, enodeb_name: nuovo_nodo.enodeb_name, new_enodebid: nuovo_nodo.enodeb_id)
          end
        else
          schedula_attivita do |parametri, opts_as|
            (opts_as || {}).update(input_file: post_locfile_to_shared_fs(locfile: parametri['file_lista_enodeb'], dir: opts_as[:attivita_schedulata_dir]))
            Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_NUOVO_ENODEBID, opts_as)
          end
        end
      end

      def grid_enodeb # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)

        query = Db::AnagraficaEnodeb

        filtro.delete(:area_territoriale) if filtro[:area_territoriale].eql? format_msg(:STORE_TUTTE_LE_AREE_TERRITORIALI)

        # filtro enodeb_id
        f = filtro.delete(:enodeb_id).to_s
        query = add_like_conditions(query: query, field: :enodeb_id, pattern: f) unless f.empty?
        # filtro enodeb_name
        f = filtro.delete(:enodeb_name).to_s
        query = add_like_conditions(query: query, field: :enodeb_name, pattern: f) unless f.empty?
        # filtro area_territoriale
        f = filtro.delete(:area_territoriale).to_s
        query = query.where(area_territoriale: f) unless f.empty?
        # filtro data_aggiornamento
        { da: '>=', a: '<=' }.each do |suffix, oper|
          query = aggiungi_filtro_data(query, filtro.delete("data_aggiornamento_#{suffix}".to_sym), 'updated_at', oper)
        end

        records_with_export(filtro, 'filename' => 'export_enodeb_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.order(:enodeb_name).each do |record|
            rec_val = record.values.merge(
              updated_at: timestamp_to_string(record[:updated_at])
            )
            formatter.add_record_values(record, rec_val)
          end
        end
      end

      App.route('enodeb') do |r|
        r.post('salva') do
          salva_enodeb
        end
        r.post('grid') do
          handle_request { grid_enodeb }
        end
        r.post('elimina') do
          handle_request(error_msg_key: :ELIMINAZIONE_ENODEB_FALLITA) do
            row_id = JSON.parse(request.params['id'] || '[]')
            res = Db::AnagraficaEnodeb.elimina_nodo(id: row_id)
            raise "Impossibile cancellare il nodo con id #{row_id}" if res.empty?
            format_msg(:ENODEB_ELIMINATO)
          end
        end
      end
    end
  end
end
