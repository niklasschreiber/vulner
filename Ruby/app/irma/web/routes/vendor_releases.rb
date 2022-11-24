# vim: set fileencoding=utf-8
#
# Author       : G. Pisa, G. Cristelli
#
# Creation date: 20161004
#

module Irma
  # rubocop:disable Metrics/ModuleLength,
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def _populate_vr_formato_audit(record)
        (record.formato_audit.nil? || record.formato_audit.to_s == '') ? record.default_formati_audit : record.formato_audit
      end

      def _populate_vr_cella_naming_path(record)
        (record.cella_naming_path.nil? || record.cella_naming_path == '') ? record.default_cella_naming_path : record.cella_naming_path
      end

      def _populate_vr_nodo_naming_path(record)
        (record.nodo_naming_path.nil? || record.nodo_naming_path == '') ? record.default_nodo_naming_path : record.nodo_naming_path
      end

      def grid_vendor_releases # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        query = Db::VendorRelease
        query = query.where(id: Db::Sistema.where(id: filtro_sistemi).distinct.select_map(:vendor_release_id)) unless funzione_abilitata?(FUNZIONE_GESTIONE_ANAGRAFICA)
        records_with_export(filtro, 'filename' => 'export_vendor_releases_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.order(:id).each do |record|
            rec_val = record.values.merge(rete:                Constant.label(:rete, record[:rete_id]),
                                          vendor:              Constant.label(:vendor, record[:vendor_id]),
                                          release_di_nodo:     record.release_di_nodo,
                                          cella_naming_path:   _populate_vr_cella_naming_path(record),
                                          nodo_naming_path:    _populate_vr_nodo_naming_path(record),
                                          formato_audit:       _populate_vr_formato_audit(record).to_json,
                                          sistemi_collegati:   record.sistemi.count,
                                          created_at:          timestamp_to_string(record[:created_at]),
                                          updated_at:          timestamp_to_string(record[:updated_at]),
                                          cc_filtro_parametri: record[:cc_filtro_parametri] ? true : false
                                         )
            formatter.add_record_values(record, rec_val)
          end
        end
      end

      def _condition_query_np_di_report_comparativo(rc_id)
        q = nil
        [rc_id].flatten.compact.each do |id|
          rc = Irma::Db::ReportComparativo.first(id: id)
          next unless rc
          rc_query = Sequel.or(naming_path: rc.entita.dataset.distinct.select(:naming_path))
          q = q ? (q | rc_query) : rc_query
        end
        q
      end

      def _tree_metamodello # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        root_node = { nome: 'root', expanded: true, children: [] }
        return root_node unless filtro && (filtro_vr = filtro[:vendor_release_id])
        solo_meta_entita = filtro[:only_meta_entita] || false
        # solo_calcolabili ||= filtro[:me_progettazione]
        solo_calcolabili = filtro[:me_progettazione]
        omc_fisico = filtro[:omc_fisico] || false
        metamodello_keywords = MetaModello.keywords_fisico_logico(omc_fisico)
        report_comparativo_id = filtro[:rc_id] # Solo nel caso di report comparativo
        deep_tree = filtro[:deep_tree] || false
        params_container = filtro[:params_container] || false
        rete = nil
        vendor_release = nil
        if filtro_vr.is_a?(Integer) || (filtro_vr.is_a?(Array) && filtro_vr.length == 1)
          vendor_release = metamodello_keywords.classe_vendor_release.get_by_pk(filtro_vr)
          rete = Constant.label(:rete, vendor_release.rete_id) if !omc_fisico && (filtro[:pi_id] || report_comparativo_id)
        end
        query = metamodello_keywords.classe_meta_entita
        query = query.left_outer_join(metamodello_keywords.classe_meta_parametro.table_name, metamodello_keywords.field_me_id.to_sym => :id) unless solo_meta_entita
        if report_comparativo_id && !report_comparativo_id.nil?
          pi_sistema_id = _pi_sistema_id(query: Db::ReportComparativo, id: report_comparativo_id, params: 'info', param_in_params: 'pi_sistema_id') if omc_fisico
          condition_query_np_rc = _condition_query_np_di_report_comparativo(report_comparativo_id)
          query = query.where(condition_query_np_rc) if condition_query_np_rc
        end
        query = query.where(Sequel.qualify(metamodello_keywords.classe_meta_entita.table_name, metamodello_keywords.field_vr_id.to_sym) => filtro_vr)
        pi_sistema_id = _pi_sistema_id(query: Db::ProgettoIrma, id: filtro[:pi_id], params: 'parametri_input', param_in_params: 'sistema_id') if omc_fisico && !filtro[:pi_id].nil?
        if pi_sistema_id
          reti_per_omc_fisico = Db::Sistema.where(id: pi_sistema_id).select_map(:rete_id).uniq
          reti_condition = []
          (reti_per_omc_fisico || []).each do |r|
            reti_condition << "#{metamodello_keywords.classe_meta_entita.table_name}.reti::jsonb @> '[#{r}]'"
          end
          query = query.where(reti_condition.join(' OR ')) unless reti_condition.empty?
        end
        query = add_like_conditions(query: query, field: Sequel.qualify(metamodello_keywords.classe_meta_entita.table_name,    :nome),           pattern: filtro[:meta_entita])
        query = add_like_conditions(query: query, field: Sequel.qualify(metamodello_keywords.classe_meta_entita.table_name,    :naming_path),    pattern: filtro[:naming_path])
        unless solo_meta_entita
          query = add_like_conditions(query: query, field: Sequel.qualify(metamodello_keywords.classe_meta_parametro.table_name, :nome),           pattern: filtro[:name])
          query = add_like_conditions(query: query, field: Sequel.qualify(metamodello_keywords.classe_meta_parametro.table_name, :nome_struttura), pattern: filtro[:nome_struttura])
        end
        if solo_calcolabili
          query = if omc_fisico && !(pi_sistema_id || []).empty?
                    subquery = Db::MetaEntita.where(vendor_release_id: Db::Sistema.where(id: pi_sistema_id).select_map(:vendor_release_id)).exclude(fase_di_calcolo: nil).select(:naming_path)
                    query.where(Sequel.qualify(metamodello_keywords.classe_meta_entita.table_name, :naming_path) => subquery)
                  else
                    query.exclude(fase_di_calcolo: nil)
                  end
        end

        select_fields = [
          Sequel.qualify(metamodello_keywords.classe_meta_entita.table_name,    :id).as('me_id'),
          Sequel.qualify(metamodello_keywords.classe_meta_entita.table_name,    metamodello_keywords.field_vr_id.to_sym).as('vr_id'),
          Sequel.lit("#{metamodello_keywords.classe_meta_entita.table_name}.naming_path COLLATE \"C\"").as('me_naming_path'),
          Sequel.qualify(metamodello_keywords.classe_meta_entita.table_name,    :nome).as('me_nome'),
          Sequel.qualify(metamodello_keywords.classe_meta_entita.table_name,    :tipo_adiacenza).as('me_adj')
        ]

        select_fields << Sequel.qualify(metamodello_keywords.classe_meta_parametro.table_name, :full_name).as('mp_full_name') unless solo_meta_entita
        select_fields << Sequel.qualify(metamodello_keywords.classe_meta_parametro.table_name, :id).as('mp_id') unless solo_meta_entita
        select_fields << Sequel.qualify(metamodello_keywords.classe_meta_parametro.table_name,  :is_predefinito).as('mp_read_only') unless solo_meta_entita

        order_fields = [Sequel.asc(:me_naming_path)]
        order_fields.unshift(Sequel.asc(:me_nome)) unless deep_tree
        order_fields << Sequel.asc(:mp_full_name) unless solo_meta_entita

        # root_node = { nome: 'root', expanded: true, children: [] }
        last_level_node = [root_node]
        query.select(*select_fields).distinct.order(*order_fields).each do |record|
          # yield(solo_meta_entita,metamodello_keywords,vendor_release,rete,record,last_level_node)
          yield(record, { solo_meta_entita: solo_meta_entita, metamodello_keywords: metamodello_keywords,
                          vendor_release: vendor_release, rete: rete, last_level_node: last_level_node,
                          deep_tree: deep_tree, params_container: params_container })
        end
        root_node
      end

      # rubocop:disable Metrics/AbcSize, Metrics/ParameterLists, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def _tree_node_meta_entita(record:, vendor_release:, rete:, solo_meta_entita: false, deep_tree: false, extra_attrs: {})
        naming_path = record[:me_naming_path]
        type = extra_attrs[:type] || 'E'
        adj_esterna = (record[:me_adj].to_i & 2) > 0
        node = {
          id:                   naming_path + '_' + type,
          nome:                 record[:me_nome],
          me_id:                record[:me_id],
          naming_path:          naming_path,
          full_naming_path:     naming_path,
          full_name:            full_name_metaentita(record[:me_nome], naming_path, vendor_release.descr, rete),
          leaf:                 (solo_meta_entita && !deep_tree) ? true : false,
          iconCls:              'hiddenIcon', # 'fa-tree'
          checked:              false,
          me_name:              record[:me_nome],
          children:             []
        }.merge(extra_attrs)
        node[:rete_id] = vendor_release.rete_id if rete
        # node[:cls] = (adj_esterna && type == 'E') ? 'treeExternalEntity' : '' if deep_tree
        node[:cls] = (adj_esterna && type == 'E') ? 'treeExternalEntity' : ''
        node[:flat_tree_node_name] = record[:me_nome] + ' [' + naming_path + ']' unless deep_tree
        node
      end

      def _tree_node_meta_parametro(record:, vendor_release:, rete:, deep_tree: false, extra_attrs: {}) # rubocop:disable  Metrics/MethodLength
        naming_path = record[:me_naming_path]
        mp_full_name = record[:mp_full_name]
        full_naming_path = naming_path + NAMING_PATH_SEP + mp_full_name
        type = extra_attrs[:type] || 'P'
        node = {
          id:                   full_naming_path + '_' + type,
          nome:                 mp_full_name,
          mp_id:                record[:mp_id],
          naming_path:          naming_path,
          full_naming_path:     full_naming_path,
          full_name:            full_name_metaentita(full_naming_path, naming_path, vendor_release.descr, rete),
          leaf:                 true,
          iconCls:              'hiddenIcon', # 'fa-leaf'
          checked:              false
        }.merge(extra_attrs)
        # node[:cls] = record[:mp_read_only] ? 'treeReadOnlyParam' : '' if deep_tree
        node[:cls] = record[:mp_read_only] ? 'treeReadOnlyParam' : ''
        node[:flat_tree_node_name] = record[:mp_full_name] + ' [' + naming_path + ']' unless deep_tree
        node
      end

      def tree_metamodello_per_vendor_releases # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        node = nil
        container_params_node = nil
        last_naming_path = nil
        last_mp_full_name = nil
        _tree_metamodello do |record, opts|
          naming_path = record[:me_naming_path]
          vr = opts[:vendor_release] || opts[:metamodello_keywords].classe_vendor_release.get_by_pk(record[:vr_id])
          if opts[:deep_tree]
            if last_naming_path != naming_path
              node = _tree_node_meta_entita(record: record, vendor_release: vr, rete: opts[:rete], solo_meta_entita: opts[:solo_meta_entita], deep_tree: opts[:deep_tree], extra_attrs:
              {
                type: 'E',
                iconCls:  'entity_icon',
                checked: false
              })
              if !opts[:solo_meta_entita] && opts[:params_container]
                container_params_node = _tree_node_meta_entita(record: record, vendor_release: vr, rete: opts[:rete], solo_meta_entita: opts[:solo_meta_entita],
                                                               deep_tree: opts[:deep_tree], extra_attrs: {
                                                                 nome: 'Parametri',
                                                                 type: 'C',
                                                                 # iconCls: "cartel_parameter_icon",
                                                                 iconCls: 'params_container_icon',
                                                                 checked: false
                                                               })
                node[:children] << container_params_node
              end
              level_node = (naming_path.count NAMING_PATH_SEP) + 1
              opts[:last_level_node][level_node - 1][:children] << node
              opts[:last_level_node][level_node] = node
              opts[:last_level_node] = opts[:last_level_node].slice(0, level_node + 1)
              last_naming_path = naming_path
            end
            next if opts[:solo_meta_entita] || !(mp_full_name = record[:mp_full_name])

            full_naming_path = naming_path + NAMING_PATH_SEP + mp_full_name
            next if last_mp_full_name == full_naming_path
            child_container = opts[:params_container] ? container_params_node[:children] : node[:children]
            # node[:children] << _tree_node_meta_parametro(record: record, vendor_release: vr, rete: opts[:rete], extra_attrs: {
            # container_params_node[:children] << _tree_node_meta_parametro(record: record, vendor_release: vr, rete: opts[:rete], extra_attrs: {
            child_container << _tree_node_meta_parametro(record: record, vendor_release: vr, rete: opts[:rete], deep_tree: opts[:deep_tree], extra_attrs:
            {
              type: 'P',
              iconCls:  'parameter_icon',
              checked: false
            })
            # last_mp_full_name = full_naming_path
          else
            if last_naming_path != naming_path
              node = _tree_node_meta_entita(record: record, vendor_release: vr, rete: opts[:rete], solo_meta_entita: opts[:solo_meta_entita], extra_attrs: { type: 'E' })
              opts[:last_level_node][0][:children] << node
              last_naming_path = naming_path
            end
            next if opts[:solo_meta_entita] || !(mp_full_name = record[:mp_full_name])

            full_naming_path = naming_path + NAMING_PATH_SEP + mp_full_name
            next if last_mp_full_name == full_naming_path
            node[:children] << _tree_node_meta_parametro(record: record, vendor_release: vr, rete: opts[:rete], deep_tree: opts[:deep_tree], extra_attrs: { type: 'P' })

            # last_mp_full_name = full_naming_path
          end
          last_mp_full_name = full_naming_path
        end
      end

      def _pi_sistema_id(query:, id:, params:, param_in_params:)
        p = [id].flatten.compact.map do |id_elm|
          obj = query.first(id: id_elm)
          obj && obj[params.to_sym] && obj[params.to_sym][param_in_params]
        end
        p.compact.uniq
      end

      def export_tree_metamodello_vendor_releases # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        extra_msg = ''
        json_tree_filter = request.params['tree_filter'] || '{}'
        raise 'Nessuna vendor release per l\'export di metamodello' unless request.params['selezione_vendor_release']
        selezione_vendor_release = JSON.parse(request.params['selezione_vendor_release'])
        sessione = logged_in
        omc_fisico = request.params['omc_fisico'] || 'false'
        opts = [Constant.info(:comando, COMANDO_EXPORT_FILTRO_FU)[:command], # 'export_filtro_formato_utente',
                '--account_id', sessione.account_id]
        opts += ['--formato', 'xls', '--omc_fisico', omc_fisico, '--filtro_metamodello', json_tree_filter]
        id_sistema = _id_sistemi_selezionati_per_vendor_release(selezione_vendor_release, omc_fisico: omc_fisico == 'true')
        if id_sistema && !id_sistema.empty?
          opts += ['--sistemi', id_sistema]
          res = Command.process(opts, logger: Command.logger)
          file_obj = res[:artifacts][0] if res[:artifacts]
        else
          extra_msg = "Nessun sistema selezionato per la vendor release con id #{selezione_vendor_release}"
          file_obj = nil
        end
        if file_obj
          file_path = file_obj[0]
          invia_file(file_path, filename: File.basename(file_path))
        else
          "Nessun file con il filtro generato (#{extra_msg})"
        end
      end

      def import_tree_metamodello_vendor_releases # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        extra_msg = ''
        filter_file = request.params['file_import_tree_filter']
        filter_file_path = filter_file && filter_file[:tempfile] && filter_file[:tempfile].path
        raise "Nessuna vendor release per l'import di metamodello" unless request.params['selezione_vendor_release']
        selezione_vendor_release = JSON.parse(request.params['selezione_vendor_release'])
        omc_fisico = request.params['omc_fisico'] || 'false'
        metamodello_keywords = MetaModello.keywords_fisico_logico(omc_fisico == 'true')
        sessione = logged_in
        res = nil
        if filter_file_path
          opts = [Constant.info(:comando, COMANDO_IMPORT_FILTRO_FU)[:command], # 'import_filtro_formato_utente',
                  '--account_id', sessione.account_id, '--input_file', filter_file_path, '--omc_fisico', omc_fisico]
          # opts 'extra_filtro_me'
          if (rc_id = request.params['rc_id'])
            condition_query_np_rc = _condition_query_np_di_report_comparativo(rc_id)
            extra_filtro_me = (condition_query_np_rc && metamodello_keywords.classe_meta_entita.where(condition_query_np_rc).select_map(:naming_path)) || []
            opts += ['--extra_filtro_me', extra_filtro_me.join(ARRAY_VAL_SEP)]
          end
          # opts 'sistema_id'
          id_sistema = _id_sistemi_selezionati_per_vendor_release(selezione_vendor_release, omc_fisico: omc_fisico == 'true')
          if id_sistema && !id_sistema.empty?
            opts += ['--sistema_id', id_sistema]
            res = Command.process(opts, logger: Command.logger)
          else
            extra_msg = "Nessun sistema selezionato per la vendor release con id #{selezione_vendor_release}"
          end
        end
        if res && res[:result] && res[:result][:header_per_filtro]
          { success: true, filtro: res[:result][:header_per_filtro] }
        else
          { success: false, messaggio: "Filtro non caricato (#{extra_msg})" }
        end
      end

      def import_alberatura_metamodello_vendor_releases # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        filter_file = request.params['input_file']
        filter_file_path = filter_file && filter_file[:tempfile] && filter_file[:tempfile].path
        raise "Nessuna vendor release per l'import alberatura" unless request.params['selezione_vendor_release']
        selezione_vendor_release = JSON.parse(request.params['selezione_vendor_release'])
        filtro_me_mp = request.params['filtro_me_mp']
        omc_fisico = request.params['omc_fisico'] || 'false'
        sessione = logged_in
        res = nil
        extra_msg = nil
        if filter_file_path
          opts = [Constant.info(:comando, COMANDO_IMPORT_FILTRO_ALBERATURA)[:command], # 'import_filtro_alberatura',
                  '--account_id', sessione.account_id, '--input_file', filter_file_path, '--omc_fisico', omc_fisico]
          opts += ['--filtro_me_mp', filtro_me_mp] if filtro_me_mp
          # opts 'sistema_id'
          id_sistema = _id_sistemi_selezionati_per_vendor_release(selezione_vendor_release, omc_fisico: omc_fisico == 'true')
          if id_sistema && !id_sistema.empty?
            opts += ['--sistema_id', id_sistema]
            res = Command.process(opts, logger: Command.logger)
          else
            extra_msg = "Nessun sistema selezionato per la vendor release con id #{selezione_vendor_release}"
          end
        end
        if res && res[:result] && !res[:result][:header_per_filtro].empty?
          error_msg = res[:result][:error_msg]
          error_msg = error_msg.empty? ? nil : "Parziale errore in caricamento file di filtro (#{error_msg})"
          { success: true, filtro: res[:result][:header_per_filtro], messaggio: error_msg }
        else
          error_msg = (res && res[:result] && res[:result][:error_msg])
          error_msg = error_msg.to_s.empty? ? (extra_msg || format_msg(:FILTRO_VUOTO)) : error_msg.to_s
          { success: false, messaggio: "Errore in caricamento file di filtro (#{error_msg})" }
        end
      end

      def aggiorna_info_consistency_check # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        raise 'Nessuna Vendor Release selezionata' unless request.params['id']
        vr = Db::VendorRelease.first(id: request.params['id'].to_i)
        raise "Non esiste nessuna Vendor Release con id: #{request.params['id']}" unless vr
        data_to_update = {}
        unless request.params['radio_group_filtro_release'] == 'no_modifica'
          r = nil
          r = request.params['cc_filtro_release'].split(',') if request.params['radio_group_filtro_release'] == 'con_filtro' && request.params['cc_filtro_release']
          data_to_update[:cc_filtro_release] = r
        end
        unless (rgfp = request.params['radio_group_filtro_parametri']) == 'no_modifica'
          p = nil
          cc_fp = request.params['cc_filtro_parametri']
          if rgfp == 'con_filtro' && cc_fp && !cc_fp.empty?
            raise 'Parametro cc_filtro_parametri non specificato correttamente (file temporaneo)' unless cc_fp && cc_fp[:tempfile] && cc_fp[:tempfile].path
            p = Marshal.dump(File.read(cc_fp[:tempfile].path))
          end
          data_to_update[:cc_filtro_parametri] = p
        end
        vr.update(data_to_update) unless data_to_update.empty?
        format_msg(:VENDOR_RELEASE_AGGIORNATA)
      end

      def _id_sistemi_selezionati_per_vendor_release(vendor_release_id, omc_fisico: false) # rubocop:disable Metrics/AbcSize
        ids_array = []
        vrid_array = [vendor_release_id].flatten
        omc = omc_fisico == true ? logged_in.data[:valori_competenza][:omc_fisici] : logged_in.data[:valori_competenza][:sistemi]
        omc.each do |s|
          if vrid_array.include? s[:vendor_release_id]
            ids_array.push(s[:id].to_s)
          end
        end
        ids_array.join(',')
      end

      def list_vendor_releases
        vr_id = request.params['vendor_releases_compatibili_id']
        query = Db::VendorRelease
        unless vr_id.to_s.empty?
          vr = Db::VendorRelease.get_by_pk(vr_id)
          query = query.where(rete_id: vr.rete_id, vendor_id: vr.vendor_id)
        end
        query.order(:descr).map do |record|
          { full_descr: d = record.full_descr, descr: d, id: record[:id] }
        end
      end

      def list_competenza_vendor_releases # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        fs = id_sistemi_di_competenza_filtrati
        # TODO: togliere il filter_sistemi_id non piu usato
        fs &= JSON.parse(request.params['filter_sistemi_id']).map(&:to_i) if request.params['filter_sistemi_id']
        vr_sistemi_filtrati = []
        vr_sistemi = []
        Db::Sistema.all_using_cache.values.map do |record|
          vr_sistemi_filtrati << record[:vendor_release_id] if fs.include?(record[:id])
          vr_sistemi << record[:vendor_release_id]
        end
        vr_sistemi_filtrati.uniq!
        vr_sistemi.uniq!
        sess = logged_in
        reti = sess.data[:valori_competenza][:reti].map { |v| v[:id] }
        vendors = sess.data[:valori_competenza][:vendors].map { |v| v[:id] }
        res = []
        Db::VendorRelease.all_using_cache.values.map do |record|
          next unless vr_sistemi_filtrati.include?(record.id) ||
                      (!request.params['filter_sistemi_id'] && funzione_abilitata?(FUNZIONE_GESTIONE_ANAGRAFICA) &&
                      !vr_sistemi.include?(record.id) && reti.include?(record.rete_id) && vendors.include?(record.vendor_id))
          res << { full_descr: record.full_descr, id: record.id, descr: record.descr }
        end
        res.sort_by { |k| k[:full_descr] }
      end

      def list_versions
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        vrid_array = filtro[:vendor_release] || []
        Db::VendorRelease.where(id: vrid_array).select_map(:release_di_nodo).flatten.uniq.sort.map { |rn| { id: rn, full_descr: rn } }
      end

      def json_entity_flags # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        me = Db::MetaEntita.first(id: request.params['id'])
        return { success: false, messaggio: "Nessuna Meta Entità definita con id #{request.params['id']}" } unless me
        res = { success: true, messaggio: '', data: {} }
        res[:data] = me.attributes.merge(
          vendor_release:     Db::VendorRelease.get_by_pk(me[:vendor_release_id]).compact_descr,
          rete_adj_id:        me[:rete_adj] ? Constant.value(:rete, me[:rete_adj]) : '',
          created_at:         timestamp_to_string(me[:created_at]),
          updated_at:         timestamp_to_string(me[:updated_at]),
          adj_esterna:        ((me[:tipo_adiacenza].to_i & 2) > 0)
        )
        regole_data_common = {
          vendor_release_id:  me.vendor_release_id,
          meta_entita_id:     me.id,
          meta_parametro_id:  nil
        }
        res[:data][:regole_calcolo] = regole_data_common.merge(jsonRegole: me.regole_calcolo)
        res[:data][:regole_calcolo_ae] = regole_data_common.merge(jsonRegole: me.regole_calcolo_ae)
        res
      end

      def json_param_flags # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        mp = Db::MetaParametro.first(id: request.params['id'])
        return { success: false, messaggio: "Nessuna Meta Parametro definito con id #{request.params['id']}" } unless mp
        res = { success: true, messaggio: '', data: {} }
        res[:data] = mp.attributes.merge(
          vendor_release:     Db::VendorRelease.get_by_pk(mp[:vendor_release_id]).compact_descr,
          rete_adj_id:        mp[:rete_adj] ? Constant.value(:rete, mp[:rete_adj]) : '',
          meta_entita:        mp.meta_entita_nome,
          naming_path:        mp.naming_path,
          created_at:         timestamp_to_string(mp[:created_at]),
          updated_at:         timestamp_to_string(mp[:updated_at]),
          adj_esterna:        ((mp.tipo_adiacenza.to_i & 2) > 0)
        )
        regole_data_common = {
          vendor_release_id:  mp.vendor_release_id,
          meta_entita_id:     mp.meta_entita_id,
          meta_parametro_id:  mp.id
        }
        res[:data][:regole_calcolo] = regole_data_common.merge(is_multivalue: mp.is_multivalue, jsonRegole: mp.regole_calcolo)
        res[:data][:regole_calcolo_ae] = regole_data_common.merge(is_multivalue: mp.is_multivalue, jsonRegole: mp.regole_calcolo_ae)
        res
      end

      def salva_tree_metamodello_per_vendor_releases # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        handle_request(error_msg_key: :SALVATAGGIO_METAMODELLO_FALLITO) do
          sessione = logged_in
          filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
          source_mp = (filtro[:source] || {})['mp'] || []    # array id di mp da copiare/spostare
          source_me = (filtro[:source] || {})['me'] || []    # array id di me da copiare/spostare
          dest_me   = filtro[:destination] || []             # array id di me destinazione
          ricorsiva   = filtro[:type] == 'RICORSIVA'
          operazione  = filtro[:action] || 'C'
          audit_extra_info = { account_id: sessione.account_id }
          Db::MetaEntita.transaction do
            dest_me.each do |me_dest_id|
              # azione sulle meta_entita...
              source_me.each do |me_source_id|
                if operazione == 'C'
                  Db::MetaEntita.copia(id_sorgente: me_source_id, id_destinazione: me_dest_id, ricorsivo: ricorsiva, audit_extra_info: audit_extra_info)
                else
                  Db::MetaEntita.sposta(id_sorgente: me_source_id, id_destinazione: me_dest_id, audit_extra_info: audit_extra_info)
                end
              end
              # azione su meta_parametri...
              source_mp.each do |mp_source_id|
                if operazione == 'C'
                  Db::MetaEntita.copia_meta_parametro(id_mp_sorgente: mp_source_id, id_destinazione: me_dest_id, audit_extra_info: audit_extra_info)
                else
                  Db::MetaEntita.sposta_meta_parametro(id_mp_sorgente: mp_source_id, id_destinazione: me_dest_id, audit_extra_info: audit_extra_info)
                end
              end
            end
          end
          format_msg(:SALVATAGGIO_METAMODELLO_ESEGUITO)
        end
      end

      def attivita_schedulata_aggiorna_adrn_da_file(parametri, opts = {})
        filter_file = parametri['input_file']
        vendor_release = parametri['vendor_release_id']
        operazione = parametri['operazione']
        opts.update(input_file:        post_locfile_to_shared_fs(locfile: filter_file, dir: opts[:attivita_schedulata_dir]),
                    vendor_release_id: vendor_release,
                    operazione:        operazione)
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_AGGIORNA_ADRN_DA_FILE, opts)
      end

      def attivita_schedulata_export_adrn_su_file(parametri, opts = {})
        vendor_release = parametri['vendor_release_id']
        formato = parametri['formato']
        campi_m_entita = parametri['campi_m_entita']
        campi_m_parametro = parametri['campi_m_parametro']
        opts.update(vendor_release_id:  vendor_release,
                    formato:            formato,
                    campi_m_entita:     campi_m_entita,
                    campi_m_parametro:  campi_m_parametro,
                    out_dir_root: DIR_ATTIVITA_TAG)
        if parametri['filtro_metamodello']
          opts['filtro_metamodello_file'] = scrivi_filtro_mm_file(prefix_nome: 'nuovoAdrn',
                                                                  filtro_mm: parametri['filtro_metamodello'],
                                                                  dir: opts[:attivita_schedulata_dir])
        end
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_EXPORT_ADRN_SU_FILE, opts)
      end
    end

    App.route('vendor_releases') do |r|
      r.get('competenza/list') do
        handle_request { list_competenza_vendor_releases }
      end
      r.post('elimina') do
        handle_request(error_msg_key: :ELIMINAZIONE_VENDOR_RELEASE_FALLITA) do
          row_id = JSON.parse(request.params['id'] || '[]')
          Db::VendorRelease.where(id: row_id).destroy
          format_msg(:VENDOR_RELEASE_ELIMINATA)
        end
      end
      r.post('grid') do
        handle_request { grid_vendor_releases }
      end
      r.get('list') do
        handle_request { list_vendor_releases }
      end
      r.post('cc_filtro_parametri/export') do
        handle_request do
          raise 'Specificare una vendor release' if (request.params['id'] || '').empty?
          vr = Db::VendorRelease.where(id: request.params['id']).first
          raise "Non esiste nessuna vendor release con id '#{request.params['id']}'" unless vr
          nome_file = File.join(Irma.tmp_dir, 'filtro_parametri-' + vr.descr + '-' + Constant.label(:vendor, vr[:vendor_id]) + '-' + Constant.label(:rete, vr[:rete_id]) + '.xlsx')
          raise "La vendor release con id '#{request.params['id']}' non ha avvalorato il campo 'cc filtro parametri'" unless vr.cc_filtro_parametri
          File.open(nome_file, 'wb') { |fd| fd.write(Marshal.restore(vr.cc_filtro_parametri)) }
          invia_file(nome_file, filename: File.basename(nome_file))
        end
      end
      r.post('metamodello/tree') do
        handle_request { tree_metamodello_per_vendor_releases }
      end
      r.post('metamodello/tree/salva') do
        handle_request { salva_tree_metamodello_per_vendor_releases }
      end
      r.post('metamodello/tree/export') do
        handle_request { export_tree_metamodello_vendor_releases }
      end
      r.post('metamodello/tree/import') do
        handle_request { import_tree_metamodello_vendor_releases }
      end
      r.post('metamodello/alberatura/import') do
        handle_request { import_alberatura_metamodello_vendor_releases }
      end
      r.post('info_consistency_check/salva') do
        handle_request(error_msg_key: :AGGIORNAMENTO_VENDOR_RELEASE_FALLITO) do
          aggiorna_info_consistency_check
        end
      end
      r.post('salva') do
        record = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        id_vr_src = record[:id]
        parametri_validi = id_vr_src || (record[:descr] && record[:vendor_id] && record[:rete_id])
        record.delete(:id) if record[:id]
        handle_request(error_msg_key: id_vr_src.to_s.empty? ? :INSERIMENTO_VENDOR_RELEASE_FALLITO : :AGGIORNAMENTO_VENDOR_RELEASE_FALLITO) do
          raise "Indicare una Vendor Release da aggiornare oppure i campi 'Descrizione', 'Rete' e 'Vendor' per creare una vendor release" unless parametri_validi
          record[:release_di_nodo] = record[:release_di_nodo].split(',') if record[:release_di_nodo]
          if id_vr_src
            vr = Db::VendorRelease.get_by_pk(id_vr_src)
            vr.release_di_nodo = record[:release_di_nodo]
            vr.formato_audit = (record[:formato_audit] != vr.default_formati_audit.to_json) ? record[:formato_audit] : nil
          else
            unless Db::VendorRelease.where(descr: record[:descr], vendor_id: record[:vendor_id], rete_id: record[:rete_id]).empty?
              raise "Esiste gia' una Vendor Release con nome #{record[:descr]}, associata alla rete #{Constant.label(:rete, record[:rete_id])} " \
                    "ed al vendor #{Constant.label(:vendor, record[:vendor_id])}."
            end
            vr = Db::VendorRelease.new(record)
          end
          vr.nodo_naming_path = (record[:nodo_naming_path] != vr.default_nodo_naming_path) ? record[:nodo_naming_path] : nil
          vr.cella_naming_path = (record[:cella_naming_path] != vr.default_cella_naming_path) ? record[:cella_naming_path] : nil
          vr.save
          format_msg(id_vr_src.to_s.empty? ? :VENDOR_RELEASE_INSERITA : :VENDOR_RELEASE_AGGIORNATA)
        end
      end
      r.post('copia') do
        record = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        handle_request(error_msg_key: :COPIA_VENDOR_RELEASE_FALLITA) do
          raise 'Indicare il nome della nuova vendor release' unless record[:descr]
          vr_src = Db::VendorRelease.get_by_pk(record[:id])
          unless Db::VendorRelease.where(descr: record[:descr], vendor_id: vr_src[:vendor_id], rete_id: vr_src[:rete_id]).empty?
            raise "Esiste gia' una Vendor Release con nome #{record[:descr]}, associata alla rete #{Constant.label(:rete, vr_src[:rete_id])} " \
                  "ed al vendor #{Constant.label(:vendor, vr_src[:vendor_id])}."
          end
          record[:copy_meta_modello] = record[:copy_meta_modello] || false
          record.delete(:id)
          vr_src.copia(record)
          format_msg(:VENDOR_RELEASE_COPIATA)
        end
      end
      r.get('version/list') do
        handle_request { list_versions }
      end
      r.post('meta_entita/json') do
        handle_request { json_entity_flags }
      end
      r.post('meta_parametro/json') do
        handle_request { json_param_flags }
      end
      r.post('metamodello/aggiorna_da_file/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_aggiorna_adrn_da_file(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('metamodello/export_su_file/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_adrn_su_file(parametri, opzioni_attivita_schedulata)
        end
      end
    end
  end
end
