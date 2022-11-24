# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170425
#

module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def attivita_schedulata_import_progetto_radio(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: parametri['sistema_id']) : Db::Sistema.first(id: parametri['sistema_id'])
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{parametri['sistema_id']})" unless sistema # TODO: verificare le competenze sui sistemi
        input_file = post_locfile_to_shared_fs(locfile: parametri['impUploadFile'], dir: opts[:attivita_schedulata_dir])
        opts.update(lista_sistemi: [[sistema.id, input_file]],
                    out_dir_root: DIR_ATTIVITA_TAG,
                    flag_cancellazione: (parametri['elimina_celle_prn'] == 'true'))
        opts[:ctrl_nv_adj_inesistenti] = JSON.parse(parametri['ctrl_nv_adj_inesistenti']) unless parametri['ctrl_nv_adj_inesistenti'].nil?
        opts[:ctrl_nv_reciprocita_adj] = JSON.parse(parametri['ctrl_nv_reciprocita_adj']) unless parametri['ctrl_nv_reciprocita_adj'].nil?
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_IMPORT_PROGETTO_RADIO, opts)
      end

      def attivita_schedulata_export_progetto_radio(parametri, opts = {})
        lista_id = (parametri['lista_sistemi_id']).to_s.split(',').map { |sss| [sss.to_i] }
        opts.update(lista_sistemi_id: lista_id, data_aggiornamento: (parametri['data_aggiornamento'] == 'true'),
                    export_totale: (parametri['export_totale'] == 'true'),
                    file_unico: (parametri['file_unico'] == 'true'),
                    out_dir_root: DIR_ATTIVITA_TAG, formato: parametri['export_format'])
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_EXPORT_PRN_OMC_LOGICO, opts)
      end

      def attivita_schedulata_calcola_enodebid(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: parametri['sistema_id']) : Db::Sistema.first(id: parametri['sistema_id'])
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{parametri['sistema_id']})" unless sistema # TODO: verificare le competenze sui sistemi
        input_file = post_locfile_to_shared_fs(locfile: parametri['impUploadFile'], dir: opts[:attivita_schedulata_dir])
        opts.update(lista_sistemi: [[sistema.id, input_file]], out_dir_root: DIR_ATTIVITA_TAG, flag_pr: (parametri['import_progetto_radio_a_seguire'] == 'true'))
        if opts[:flag_pr]
          Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_COMPLETA_ENODEB_IMPORT_PROGETTO_RADIO, opts)
        else
          Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_COMPLETA_ENODEB, opts)
        end
      end

      def attivita_schedulata_calcola_cgi(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: parametri['sistema_id']) : Db::Sistema.first(id: parametri['sistema_id'])
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{parametri['sistema_id']})" unless sistema # TODO: verificare le competenze sui sistemi
        input_file = post_locfile_to_shared_fs(locfile: parametri['impUploadFile'], dir: opts[:attivita_schedulata_dir])
        opts.update(lista_sistemi: [[sistema.id, input_file]], out_dir_root: DIR_ATTIVITA_TAG, flag_pr: (parametri['import_progetto_radio_a_seguire'] == 'true'))
        if opts[:flag_pr]
          Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_COMPLETA_CGI_IMPORT_PROGETTO_RADIO, opts)
        else
          Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_COMPLETA_CGI, opts)
        end
      end

      def attivita_schedulata_elimina_celle(parametri, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        sistema_id = parametri['sistema_id']
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non specificato" if sistema_id.nil? || sistema_id.empty?
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: sistema_id) : Db::Sistema.first(id: sistema_id)
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{sistema_id})" unless sistema
        celle = parametri['lista_celle'] unless parametri['lista_celle'].nil? || parametri['lista_celle'].empty?
        opts.update(lista_celle: celle, sistema_id: sistema.id) if celle
        # FUTURE: al momento non viene gestita l'opzione :omc_fisico
        return Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_ELIMINA_CELLE_DA_PRN_OMC_LOGICO, opts) if celle
        raise 'Selezione Celle non specificata'
      end

      def _add_filtro_data_ultimo_pr(query, sistema_id:, delta: 60)
        max_updated_at = Db::ProgettoRadio.where_sistema_id(sistema_id).max(:updated_at)
        query = query.where { updated_at >= max_updated_at - delta } if max_updated_at
        query
      end

      def list_nodi_progetti_radio # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        sistema_id = request.params['sistema_id'] || filtro[:sistema_id] || []
        query = Db::ProgettoRadio.where_sistema_id(sistema_id)
        query = _add_filtro_data_ultimo_pr(query, sistema_id: sistema_id) if filtro[:ultimo_import_pr]
        query.select(:nome_nodo).order(:nome_nodo).distinct.map { |record| { id: nn = record[:nome_nodo], full_descr: nn } }
      end

      def grid_celle_progetti_radio # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        query = Db::ProgettoRadio
        sistema_id = request.params['sistema_id'] || filtro[:sistema_id]
        if sistema_id
          query = query.where_sistema_id(sistema_id)
          query = _add_filtro_data_ultimo_pr(query, sistema_id: sistema_id) if filtro[:ultimo_import_pr]
        end
        query = add_like_conditions(query: query, field: :nome_nodo, pattern: filtro[:nome_nodo]) unless filtro[:nome_nodo].to_s.empty?
        query = add_like_conditions(query: query, field: :nome_cella, pattern: filtro[:nome_cella]) unless filtro[:nome_cella].to_s.empty?
        query.select(:id, :nome_cella, :nome_nodo).order(:nome_cella).map(&:values)
      end

      def _aggiungi_progetti_radio_record(opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        rec = opts[:rec]
        valori = opts[:valori]
        fields = opts[:fields]
        result = opts[:result]
        limite = opts[:limite]
        filters = opts[:filters]
        result[:total] += 1
        next if limite > 0 && (result[:total] > limite)
        row = {}
        row[:updated_at] = timestamp_to_string(rec[:updated_at])
        fields.each do |p|
          next unless valori[p]
          row[p] = valori[p][0]
          row[p] = row[p].join(TEXT_ARRAY_ELEM_SEP) if row[p].is_a?(Array)
          filters[p] ||= { id: p, name: p, type: (valori[p][2] || 'char') }
        end
        result[:data] << row
      end

      def _progetti_radio_filter_condition(param:, operator:, value:, type:)
        op, val = case operator
                  when OPERATORI_INIZIA_CON
                    ['like', value + '%']
                  when OPERATORI_FINISCE_CON
                    ['like', '%' + value]
                  when OPERATORI_CONTIENE
                    ['like', '%' + value + '%']
                  else
                    [operator, value]
                  end
        pre = (type == 'integer' && !val.empty?) ? "to_number((valori::jsonb->>'#{param}')::jsonb->>0, '99999999')" : "(valori::jsonb->>'#{param}')::jsonb->>0"
        "(#{pre} #{op} '#{val}')"
      end

      def grid_progetti_radio # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        result = { total: 0, fields: [], data: [], filter: [] }
        limite = request.params['max'].to_i
        selected_fields = filtro[:project_param_selected]
        all_fields = Db::Sistema.get_by_pk(filtro[:sistema_id_selected]).header_pr || {}
        filters = {}
        q = Db::ProgettoRadio.where_sistema_id(filtro[:sistema_id_selected])
        # usare add_param_value_condition al posto delle prossime 2 righe
        cond = filtro[:project_param_filtered].map { |fp| _progetti_radio_filter_condition(param: fp['param'], operator: fp['operator'], value: fp['value'], type: fp['type']) }
        q = q.where(cond.join('AND')) unless cond.empty?
        Db::ProgettoRadio.transaction do
          q.select(:header, :valori, :updated_at).each do |progetto_radio|
            fields = selected_fields.empty? ? (progetto_radio[:header] || []) : selected_fields
            opts = { rec: progetto_radio, valori: progetto_radio[:valori] || {}, fields: fields, result: result, limite: limite, filters: filters }
            _aggiungi_progetti_radio_record(opts)
          end
        end
        result[:fields] = dynamic_grid_header(fields: (selected_fields.empty? ? all_fields.keys : selected_fields), sort: false, values: result[:data].first) do |ff|
          # ff.unshift(name: 'updated_at',  label: 'Data aggiornamento', width: 200, locked: true)
          ff.push(name: 'updated_at',  label: 'Data aggiornamento', width: 200, locked: false)
        end
        result[:filter] = filters.empty? ? selected_fields.map { |f| { id: f, name: f, type: 'char' } } : filters.values
        result
      end

      # PAOLO: usare quello in entity.rb (grid_column_filter)
      def grid_parametri_header_progetti_radio
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        sistema = filtro[:sistema_id_selected]
        raise 'Nessun sistema specificato' unless sistema
        merge_header = Db::Sistema.get_by_pk(sistema).header_pr || {}
        grid_matching_param_value_filter(params: merge_header.keys, filter: filtro[:nome_parametro])
      end
    end

    App.route('progetti_radio') do |r|
      r.post('celle/grid') do
        handle_request { grid_celle_progetti_radio }
      end
      r.post('grid') do
        handle_request { grid_progetti_radio }
      end
      r.post('import/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_import_progetto_radio(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('export/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_progetto_radio(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('completa/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_calcola_enodebid(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('completa_cgi/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_calcola_cgi(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('elimina_celle/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_elimina_celle(parametri, opzioni_attivita_schedulata)
        end
      end
      r.get('nodi/list') do
        handle_request { list_nodi_progetti_radio }
      end
      r.post('parametri_header/grid') do
        handle_request { grid_parametri_header_progetti_radio }
      end
    end
  end
end
