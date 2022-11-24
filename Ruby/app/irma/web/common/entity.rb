# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170428
#
require 'irma/filtro_entita_util'

module Irma
  module Web
    # rubocop:disable Metrics/ModuleLength
    module Common
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def dynamic_grid_header(fields:, values: {}, sort: true, header_wrap: true, auto_width: 10)
        f = fields
        f = f.sort_by { |x| x.split('_').map { |el| el.to_i.to_s == el ? format('%010d', el) : el } } if sort
        f = f.map do |x|
          is_a_struct = x.index('.')
          wrap = (header_wrap && (is_a_struct || (x.size > 10))) ? true : false
          label_pieces = if wrap
                           is_a_struct ? x.split('.') : x.chars.each_slice((x.size / 2.0).ceil).map(&:join)
                         else
                           [x]
                         end
          {
            name:       x,
            label:      label_pieces.join("#{is_a_struct ? '.' : ''}<br>"),
            sortType:   (values && values[x] && values[x].to_s.to_i.to_s == values[x]) ? 'asInt' : 'asText',
            width:      auto_width ? (x.size * auto_width) / label_pieces.size : 100
          }
        end
        yield(f) if block_given?
        f.each do |field|
          [field, field[:columns]].compact.flatten.each do |x|
            x[:dataIndex] = x[:name] if x[:name]
            x[:header] = x[:label] || x[:name]
          end
        end
      end

      def aggiungi_entity_record(rec:, fields:, result:, limite:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        result[:total] += 1
        next if limite > 0 && (result[:total] > limite)
        row = {}
        filters = opts[:filters] || {}
        row[:version] = rec[:version]
        row[:m_entita] = rec[:meta_entita]
        row[:valore_entita] = rec[:valore_entita]
        row[opts[:extra_field]] = opts[:extra_field_value] if opts[:extra_field] && opts[:extra_field_value]
        row[:dist_name] = rec[:dist_name].dup
        row[:dist_name] << " #{rec[:extra_name]}" if rec[:extra_name]
        parametri = rec[:parametri] || {}
        entity_with_label = false
        fields.each do |p|
          pn = p[:name]
          pn_key = (idx = pn.index(TEXT_STRUCT_NAME_SEP)) ? pn[0..idx] : pn
          filters[pn] ||= { id: pn, name: pn, type: p[:type], multi: p[:multi], multistruct: p[:multistruct] }
          next unless parametri[pn]
          if opts[:etichetta] && !opts[:lista_etichette][_build_label_key(rec[:dist_name], pn_key)]
            row[pn] = TEXT_PARAMETRO_IGNORATO
          else
            row[pn] = parametri[pn]
            entity_with_label = true
          end
          row[pn] = MetaModello.parametro_to_s(row[pn], false)
        end
        result[:data] << row if !opts[:etichetta] || entity_with_label
      end

      def aggiungi_entity_fields(fields:, result:, extra_field: nil)
        result[:fields] = dynamic_grid_header(fields: fields, values: result[:data].first) do |f|
          f.unshift(name: 'dist_name', label: 'DistName', width: 500, locked: true)
          f.unshift(name: extra_field, width: 120, locked: true) if extra_field
          f.unshift(name: 'valore_entita', label: 'Valore Entità', width: 100, locked: true)
          f.unshift(name: 'm_entita', label: 'Meta Entità', width: 100, locked: true)
          f.unshift(name: 'version', label: 'Version', width: 60, locked: true)
        end
      end

      def _query_meta_parametri_per_naming_path_me(naming_path, omc_fisico: false)
        metamodello = MetaModello.keywords_fisico_logico(omc_fisico)
        query = metamodello.classe_meta_parametro.join(metamodello.classe_meta_entita.table_name, id: metamodello.field_me_id.to_sym).where(naming_path: naming_path)
        query.select(:full_name, :naming_path, Sequel.qualify(metamodello.classe_meta_entita.table_name, :nome).as('men'),
                     Sequel.qualify(metamodello.classe_meta_parametro.table_name, :tipo).as('type'), :is_multivalue, :is_multistruct)
      end

      include FiltroEntitaUtil
      def entity_records(klass:, filtro_id:, extra_field:, entita: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        result = { total: 0, fields: [], data: [] }
        fmm = filtro[:filtro_metamodello] || {}
        if (sess = logged_in)
          np = filtro[:meta_entita_naming_path]
          lista_etichette = JSON.parse(filtro[:etichette]) if filtro[:etichette]
          if np
            fields = (filtro[:filtro_metamodello] && filtro[:filtro_metamodello][np] && filtro[:filtro_metamodello][np][FILTRO_MM_PARAMETRI]) || []
            any_field = fields.first == META_PARAMETRO_ANY
            fields = filtro[:project_param_selected] if filtro[:project_param_selected] && !filtro[:project_param_selected].empty?
            filters = {}
            archivio = filtro[:archivio]
            ambiente = sess.ambiente
            sistemi = filtro[filtro_id] || []
            sistemi = id_sistemi_di_competenza_filtrati if sistemi.empty?
            limite = request.params['max'].to_i
            fields_to_render = []
            field_etichette = !lista_etichette.nil? && archivio == ARCHIVIO_ECCEZIONI
            mm_labels = {}
            klass.where(id: sistemi).each do |sistema|
              omc_fisico = filtro[:omc_fisico]
              metamodello_kwrds = MetaModello.keywords_fisico_logico(omc_fisico)
              q_fields = _query_meta_parametri_per_naming_path_me(np, omc_fisico: omc_fisico)
              q_fields = q_fields.where(Sequel.qualify(metamodello_kwrds.classe_meta_parametro.table_name, metamodello_kwrds.field_vr_id.to_sym) => sistema[metamodello_kwrds.field_vr_id.to_sym])
              q_fields = q_fields.where(full_name: fields) unless any_field && filtro[:project_param_selected] && filtro[:project_param_selected].empty?
              # Arricchisco i fields con le informazioni di tipo e multivalore
              rich_fields_x_sistema = q_fields.map { |record| { name: record[:full_name], type: record[:type], multi: record[:is_multivalue], multistruct: record[:is_multistruct] } }
              fields_to_render |= rich_fields_x_sistema.map { |f| f[:name] }
              extra_field_value = sistemi.size > 1 ? sistema.descr : nil
              mm_labels = get_etichette_eccezioni(sistema: sistema, lista_etichette: lista_etichette, naming_path: np) if field_etichette
              ent = entita || sistema.entita(ambiente: ambiente, archivio: archivio).first
              ent.db.transaction do
                feu_info = feu_query_per_naming_path(naming_path: np, dataset: ent.dataset, filtro_np: fmm[np] || {}, nome_tabella: ent.table_name)
                query = feu_info[:feu_query_np]
                filtro_wi = feu_info[:feu_filtro_wi]
                query = add_entity_value_condition(query: query, entity_filter: filtro[:valore_entita_filtered]) if filtro[:valore_entita_filtered] && !filtro[:valore_entita_filtered].empty?
                query = add_param_value_condition(query: query, param_filter: filtro[:project_param_filtered]) if filtro[:project_param_filtered] && !filtro[:project_param_filtered].empty?
                query.each do |rec|
                  next if !filtro_wi.empty? && !feu_tengo?(rec[:dist_name], filtro_wi)
                  # -> arricchisco il parametro filters con le info di tipo, multiValore e multiStruct e
                  # -> popolo il record di dati
                  opts = { extra_field: extra_field, extra_field_value: extra_field_value, etichetta: field_etichette, lista_etichette: mm_labels }
                  aggiungi_entity_record(rec: rec, result: result, limite: limite, fields: rich_fields_x_sistema, filters: filters, **opts)
                end
              end
            end
            aggiungi_entity_fields(fields: fields_to_render, result: result, extra_field: (sistemi.size > 1) ? extra_field : nil)
            result[:filter] = filters.empty? ? fields_to_render.map { |f| { id: f, name: f, type: 'char' } } : filters.values
          end
        end
        result[:total] = 0 if result[:data].empty?
        result
      end

      def get_etichette_eccezioni(lista_etichette:, sistema:, naming_path:)
        res = {}
        sistema.entita(archivio: ARCHIVIO_LABEL).first.dataset.select(:dist_name, :meta_parametro, :label).where(label: lista_etichette, naming_path: naming_path).each do |rec|
          res[_build_label_key(rec[:dist_name], rec[:meta_parametro])] = rec[:label] || ''
        end
        res
      end

      def _build_label_key(dn, mp)
        "#{dn}, #{mp}"
      end

      def full_name_metaentita(nome_metaentita, naming_path_metaentita, vendor_release_descr, rete)
        fma_name = nome_metaentita.to_s
        fma_name += " | #{naming_path_metaentita}" unless naming_path_metaentita.nil?
        if rete && vendor_release_descr
          fma_name += " | #{rete} - #{vendor_release_descr}"
        elsif vendor_release_descr
          fma_name += " | #{vendor_release_descr}"
        end
        fma_name
      end

      def grid_matching_param_value_filter(params:, filter: nil)
        f = filter.downcase unless filter.nil?
        regex = f ? Regexp.new("(#{f.gsub('*', '.*').tr(',', '|')})") : nil
        params.sort.map do |x|
          p = x.downcase
          (regex.nil? || p.match(regex)) ? { id: x, name: x } : nil
        end.compact
      end

      def grid_column_filter
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        meta_entita_naming_path = filtro[:meta_entita_naming_path]
        meta_parametri_selected = filtro[:meta_parametri_selected]
        raise 'Nessun meta_entita_naming_path specificato' unless meta_entita_naming_path
        grid_matching_param_value_filter(params: meta_parametri_selected, filter: filtro[:nome_parametro])
      end

      def filter_condition_param_value(param: nil, operator:, value:, type: nil, field:, entity: false) # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
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
        unless entity
          pre = case type
                when 'integer', 'float'
                  "to_number((#{field}::jsonb->>'#{param}')::jsonb->>0, '99999999')"
                else
                  "(#{field}::jsonb->>'#{param}')::text"
                end
        end
        "(#{entity ? field : pre} #{op} '#{val}')"
      end

      def add_param_value_condition(query:, param_filter:, field: :parametri)
        cond = param_filter.map { |fp| filter_condition_param_value(param: fp['param'], operator: fp['operator'], value: fp['value'], type: fp['type'], field: field) }
        cond.empty? ? query : query.where(cond.join('AND'))
      end

      def add_entity_value_condition(query:, entity_filter:)
        cond = entity_filter.map { |fp| filter_condition_param_value(field: fp['field'], operator: fp['operator'], value: fp['value'], entity: true) }
        cond.empty? ? query : query.where(cond.join('AND'))
      end
    end
  end
end
