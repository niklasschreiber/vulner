# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170425
#
require 'irma/filtro_entita_util'

module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def attivita_schedulata_esecuzione_report_comparativo(parametri, opts = {})  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        rc = Db::ReportComparativo.first(nome: parametri['nome_report'], account_id: opts[:account_id])
        raise "Report Comparativo con nome '#{rc.nome}' già esistente" if rc
        opts.update(nome: parametri['nome_report'])
        # al momento la GUI passa solo sistema_id o omc_fisico_id perche' non ancora previsto il caso di confronto tra archivi di sistemi differenti,
        f = {}
        [1, 2].each do |idx|
          f = {
            'sistema_id'    => Db::Sistema.first(id: parametri["sistema_id_#{idx}"]),
            'omc_fisico_id' => Db::OmcFisico.first(id: parametri["omc_fisico_id_#{idx}"])
          }
          f.delete_if { |_k, v| v.nil? }
          raise "Sistema/Omc Fisico di fonte #{idx} non valido: (#{parametri["sistema_id_#{idx}"]} e #{parametri["omc_fisico_#{idx}"]})" unless f.size == 1
          opts['omc_id'] = f.values[0].id if idx == 1 # imposto l'id sistema/omc_fisico master

          # nel comando devo impostare origine_1 con omc_fisico_id o sistema_id o pi_id e valore_1 l'id corrispondente, stessa cosa per origine_2 e valore_2
          if parametri["archivio_#{idx}"] == 'pi'
            opts["origine_#{idx}"] = 'pi_id'
            opts["valore_#{idx}"] =  parametri["pi_id_#{idx}"]
          else
            opts["origine_#{idx}"] = f.keys[0]
            opts["valore_#{idx}"] =  f.values[0].id
          end
          opts["archivio_#{idx}"] = parametri["archivio_#{idx}"]
        end
        opts['flag_presente'] = (parametri['includi_entita_uguali'] == 'true')
        opts['filtro_metamodello_file'] = scrivi_filtro_mm_file(prefix_nome: 'nuovoRC',
                                                                filtro_mm: parametri['filtro_metamodello'],
                                                                dir: opts[:attivita_schedulata_dir])

        Db::TipoAttivita.crea_attivita_schedulata(parametri['omc_fisico_id_1'] ? TIPO_ATTIVITA_REPORT_COMPARATIVO_OMC_FISICO : TIPO_ATTIVITA_REPORT_COMPARATIVO_OMC_LOGICO, opts)
      end

      # -----------------------------------------------------------------------------------
      def attivita_schedulata_export_report_comparativo(parametri, opts = {}) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
        raise 'Nessun tipo export di report comparativo specificato' if parametri['check_export'] != 'on' && parametri['check_export_fu'] != 'on' && parametri['check_export_ca'] != 'on'
        lista_id = (parametri['lista_report_comparativi']).to_s.split(',').map { |sss| [sss.to_i] }

        opts.update(lista_rc_id: lista_id, out_dir_root: DIR_ATTIVITA_TAG)
        # ---
        opts[:filtro_metamodello_file] = scrivi_filtro_mm_file(prefix_nome: 'exportRC',
                                                               filtro_mm: parametri['filtro_metamodello'],
                                                               dir: opts[:attivita_schedulata_dir])
        # ---
        opts[:filtro_version] = parametri['filtro_version'] || ''
        opts.update(formato:                  parametri['formato'],
                    cc_mode:                 (parametri['cc_mode'] == 'true'),
                    solo_prioritari:         (parametri['solo_prioritari'] == 'true'),
                    solo_calcolabili:        (parametri['me_progettazione'] == 'true'))
        if parametri['check_export'] == 'on'
          opts.update(check_export:         true,
                      con_version:          (parametri['con_version'] == 'true'),
                      only_to_export_param: (parametri['only_to_export_param'] == 'true'),
                      nascondi_assente_f1:  (parametri['nascondi_f1'] == 'true'),
                      nascondi_assente_f2:  (parametri['nascondi_f2'] == 'true'),
                      dist_assente_vuoto:   (parametri['dist_assente_vuoto'] == 'true'))
        end
        if parametri['check_export_fu'] == 'on'
          opts.update(check_export_fu:        true,
                      con_version_fu:          (parametri['con_version_fu'] == 'true'),
                      only_to_export_param_fu: (parametri['only_to_export_param_fu'] == 'true'),
                      nascondi_assente_f1_fu:  (parametri['nascondi_f1_fu'] == 'true'),
                      nascondi_assente_f2_fu:  (parametri['nascondi_f2_fu'] == 'true'),
                      dist_assente_vuoto_fu:   (parametri['dist_assente_vuoto_fu'] == 'true'))
        end
        if parametri['check_export_ca'] == 'on'
          opts.update(check_export_ca:          true,
                      np_alberatura:            JSON.parse(parametri['np_alberatura']),
                      genera_file_filtro:       (parametri['genera_filtro_alberatura'] == 'true'),
                      con_version_ca:           (parametri['con_version_ca'] == 'true'),
                      only_to_export_param_ca:  (parametri['only_to_export_param_ca'] == 'true'),
                      nascondi_assente_f1_ca:   (parametri['nascondi_f1_ca'] == 'true'),
                      nascondi_assente_f2_ca:   (parametri['nascondi_f2_ca'] == 'true'),
                      dist_assente_vuoto_ca:    (parametri['dist_assente_vuoto_ca'] == 'true'))
        end
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_EXPORT_REPORT_COMPARATIVI, opts)
      end
      # -----------------------------------------------------------------------------------

      def list_report_comparativi # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        sessione = logged_in

        sistema_cond = if filtro[:id_omc_fisico]
                         { omc_fisico_id: filtro[:id_omc_fisico] }
                       elsif filtro[:id_sistema]
                         { sistema_id: filtro[:id_sistema] }
                       else
                         sdcf = id_sistemi_di_competenza_filtrati
                         ofdcf = id_omc_fisici_di_competenza_filtrati
                         Sequel.or(sistema_id: sdcf) | Sequel.or(omc_fisico_id: ofdcf)
                       end
        query = Db::ReportComparativo.where(sistema_cond)
        query = query.where(ambiente: filtro[:ambiente]) if filtro[:ambiente] && (!filtro[:ambiente].eql? format_msg(:STORE_TUTTI_GLI_AMBIENTI))
        query = if filtro[:visualizza] && filtro[:matricola]
                  applica_filtro_tipo_account_matricola(query, filtro[:visualizza], filtro[:matricola])
                elsif filtro[:rc_account_cc] && !filtro[:rc_account_cc].to_s.empty?
                  _aggiungi_filtro_rc_consistency_check(query: query, input: filtro[:rc_account_cc])
                else
                  query.where(account_id: sessione.account_id)
                end
        query.reverse_order(:updated_at).map do |record|
          begin
            omc_fisico_id = record[:omc_fisico_id]
            omc_logico_id = record[:sistema_id]
            sof = sistema_o_omc_fisico(record)
            vrid, vrid_sistema, sistemi, vr_klass = if omc_fisico_id
                                                      vid = Db::OmcFisico.get_by_pk(omc_fisico_id).vendor_release_fisico_id
                                                      vid_sistema = (sid = record.info && record.info['pi_sistema_id']) && (s = Db::Sistema.get_by_pk(sid)) && s.vendor_release_id
                                                      vid_sistema ||= Db::OmcFisico.get_by_pk(omc_fisico_id).vendor_release_id
                                                      [vid, vid_sistema, Db::OmcFisico.get_by_pk(omc_fisico_id).sistemi.map { |si| si[:id] }, Db::VendorReleaseFisico]
                                                    else
                                                      vid = Db::Sistema.get_by_pk(omc_logico_id).vendor_release_id
                                                      [vid, vid, [omc_logico_id], Db::VendorRelease]
                                                    end
            vr = { id: vrid, di_sistema: vrid_sistema, descr: vr_klass.get_by_pk(vrid).descr }
          rescue => e
            Irma.logger.warn("Errore nel reperire informazioni per il ReportComparativo #{record[:nome]} che verra' ignorato, eccezione: #{e}")
            next
          end
          row = {
            created_at:               ts = timestamp_to_string(record[:created_at]),
            id:                       record[:id],
            label:                    sof.is_a?(Db::Sistema) ? 'Sistema' : 'Omc Fisico',
            nome:                     record[:nome],
            descr:                    "#{record[:nome]} (#{record[:count_entita]} records, eseguito in data #{ts})",
            count_entita:             record[:count_entita],
            full_descr:               sof ? sof.full_descr : '',
            omc_logico_id:            omc_logico_id,
            omc_fisico_id:            omc_fisico_id,
            vendor_release:           vr,
            sistemi:                  sistemi
          }
          {
            f1: record[:archivio_1].to_hash,
            f2: record[:archivio_2].to_hash
          }.each do |fonte, valori|
            row.update(
              "#{fonte}_nome"     => fonte,
              "#{fonte}_ambiente" => valori['ambiente'],
              "#{fonte}_n_entita" => valori['n_entita'],
              "#{fonte}_sorgente" => valori['nome_progetto_irma'] || valori['archivio']
            )
          end
          row
        end.compact
      end

      def grid_report_comparativi # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        sessione = logged_in

        omc_fisico = filtro[:omc_fisico]
        solo_omc_logici_competenza = filtro[:solo_competenza]
        sdcf = id_sistemi_di_competenza_filtrati
        ofdcf = id_omc_fisici_di_competenza_filtrati
        # Gestione filtro omc_fisico
        sistema_cond =  if omc_fisico.nil?
                          Sequel.or(sistema_id: sdcf) | Sequel.or(omc_fisico_id: ofdcf)
                        else
                          omcf_cond = omc_fisico ? { omc_fisico_id: ofdcf } : { sistema_id: sdcf }
                          somclc_cond = Sequel.or(omc_fisico_id: ofdcf) & Sequel.lit("json_build_array(info::jsonb->>'pi_sistema_id')::jsonb ?| array['#{sdcf.join("','")}']")
                          (solo_omc_logici_competenza && omc_fisico) ? somclc_cond : omcf_cond
                        end
        query = Db::ReportComparativo.where(sistema_cond)
        # Gestione filtro nome_rc
        query = add_like_conditions(query: query, field: :nome, pattern: filtro[:nome_rc]) if filtro[:nome_rc]
        # Gestione data_filter_da/data_filter_a
        cond = []
        cond << "updated_at >= '#{Time.at(filtro[:data_filter_da] / 1000)}'" if filtro[:data_filter_da]
        cond << "updated_at <= '#{Time.at(filtro[:data_filter_a] / 1000)}'" if filtro[:data_filter_a]
        query = query.where(cond.join(' AND ')) unless cond.empty?

        query = if filtro[:rc_account_cc] && !filtro[:rc_account_cc].to_s.empty?
                  _aggiungi_filtro_rc_consistency_check(query: query, input: filtro[:rc_account_cc])
                else
                  query.where(account_id: sessione.account_id)
                end
        query.reverse_order(:updated_at).map do |record|
          omc_fisico_id = record[:omc_fisico_id]
          omc_logico_id = record[:sistema_id]
          sof = sistema_o_omc_fisico(record)
          user = Db::Utente.get_by_pk(Db::Account.get_by_pk(record[:account_id]).utente_id)
          vrid, vrid_sistema, sistemi, vr_klass = if omc_fisico_id
                                                    vid = Db::OmcFisico.get_by_pk(omc_fisico_id).vendor_release_fisico_id
                                                    vid_sistema = (sid = record.info && record.info['pi_sistema_id']) && (s = Db::Sistema.get_by_pk(sid)) && s.vendor_release_id
                                                    vid_sistema ||= Db::OmcFisico.get_by_pk(omc_fisico_id).vendor_release_id
                                                    [vid, vid_sistema, Db::OmcFisico.get_by_pk(omc_fisico_id).sistemi.map { |si| si[:id] }, Db::VendorReleaseFisico]
                                                  else
                                                    vid = Db::Sistema.get_by_pk(omc_logico_id).vendor_release_id
                                                    [vid, vid, [omc_logico_id], Db::VendorRelease]
                                                  end
          vr = { id: vrid, di_sistema: vrid_sistema, descr: vr_klass.get_by_pk(vrid).descr }
          sistema_descr = if record[:sistema_id]
                            sof.full_descr
                          elsif record.info && record.info['pi_sistema_id']
                            Db::Sistema.get_by_pk(record.info['pi_sistema_id']).full_descr
                          end
          {
            created_at:               ts = timestamp_to_string(record[:created_at]),
            id:                       record[:id],
            label:                    sof.is_a?(Db::Sistema) ? 'Sistema' : 'Omc Fisico',
            nome:                     record[:nome],
            descr:                    "#{record[:nome]} (#{record[:count_entita]} records, eseguito in data #{ts})",
            count_entita:             record[:count_entita],
            full_descr:               sof ? sof.full_descr : '',
            omc_logico_id:            omc_logico_id,
            omc_fisico_id:            omc_fisico_id,
            vendor_release:           vr,
            vendor_release_descr:     vr[:descr],
            sistemi:                  sistemi,
            sistema_descr:            sistema_descr,
            omc_fisico_descr:         record[:omc_fisico_id] ? sof.full_descr : nil,
            utente:                   user.nome + ' ' + user.cognome
          }
        end
      end

      def grid_delete_report_comparativi # rubocop:disable Metrics/AbcSize
        Db::ReportComparativo.where(account_id: @sess.account_id).reverse_order(:updated_at).map do |record|
          sof = sistema_o_omc_fisico(record)
          {
            nome:           record[:nome],
            sistema:        record[:sistema_id] ? sof.full_descr : nil,
            omc_fisico:     record[:omc_fisico_id] ? sof.full_descr : nil,
            id:             record[:id],
            archivio_1:     record[:archivio_1].to_s,
            archivio_2:     record[:archivio_2].to_s,
            count_entita:   record[:count_entita],
            created_at:     timestamp_to_string(record[:created_at]),
            durata:         (record[:updated_at] - record[:created_at]).round(0)
          }
        end
      end

      def elimina_report_comparativi
        selected_ids = JSON.parse(request.params['id_report_selezionati'] || '[]')
        n = Db::ReportComparativo.where(id: selected_ids).destroy
        format_msg(n == 1 ? :REPORT_COMPARATIVO_ELIMINATO : :REPORT_COMPARATIVI_ELIMINATI, n: n)
      end

      def _aggiungi_rc_entity_record(rec:, result:, # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/ParameterLists,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
                                     fields:, filtro:, pth:, limite:)
        next if limite > 0 && (result[:total] >= limite)
        row_filter = filtro[:project_param_filtered] || []
        filtri_parametro = row_filter.each_with_object({}) { |elem, res| (res[elem['param']] ||= []) << elem }
        row = {}
        ok = true
        row[:m_entita] = rec[:meta_entita]
        row[:valore_entita] = rec[:valore_entita]
        row[:dist_name] = rec[:dist_name]
        row[:dist_name] << " #{rec[:extra_name]}" if rec[:extra_name]
        row[:esito_diff] = Irma::Constant.label(:rep_comp_esito, rec[:esito_diff])
        (fields & CUSTOM_COLUMNS).each do |p|
          parametri = { fonte_1: rec[:fonte_1], fonte_2: rec[:fonte_2] }
          ok &&= _check_param_analize?(p: p, tipo_val: 'char', filtri_parametro: filtri_parametro, result: result, parametri: parametri, row: row)
          break unless ok
        end

        if ok
          (fields - CUSTOM_COLUMNS).each do |p|
            parametri = { fonte_1: rec[:fonte_1]['parametri'], fonte_2: rec[:fonte_2]['parametri'] }
            ok &&= _check_param_analize?(p: p, tipo_val: pth[p.to_s], filtri_parametro: filtri_parametro, result: result, parametri: parametri, row: row)
            break unless ok
          end
        end
        return unless ok
        result[:total] += 1
        result[:data] << row
      end

      def _check_param_condition?(p:, v:, filtri_parametro:)
        res = true
        filtri_parametro ||= []
        filtri_parametro[p].each do |fp|
          t = fp['type']
          op = OPERATOR_MAPPING[fp['operator']] || fp['operator']
          # val_filtro = fp['value']
          # res &&= v.send(CAST_METHOD[t]).send(op, (val_filtro == '' ? REP_COMP_KEY_ASSENTE : val_filtro).send(CAST_METHOD[t]))
          res &&= v.send(CAST_METHOD[t]).send(op, fp['value'].send(CAST_METHOD[t]))
        end
        res
      end

      def _check_param_analize?(p:, tipo_val:, # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/ParameterLists
                                filtri_parametro:, result:, parametri:, row:)
        local_ok = 0
        if parametri[:fonte_1] && parametri[:fonte_2] && (parametri[:fonte_1][p] != parametri[:fonte_2][p])
          FONTE_MAPPING.each do |k, v|
            # pf = parametri[k] && parametri[k][p]
            pf = parametri[k]
            local_ok += 1 if pf && _check_local_ok?(p: p, p_val: pf[p], fonte: v, tipo_val: tipo_val, filtri_parametro: filtri_parametro, result: result, row: row)
          end
        else
          local_ok = 1 unless filtri_parametro[p]
        end
        local_ok > 0
      end

      def _check_local_ok?(p:, p_val:, fonte:, tipo_val:, filtri_parametro:, result:, row:) # rubocop:disable Metrics/ParameterLists
        res = true
        if p_val
          result[:parametri_non_vuoti][p] ||= true
          pv = MetaModello.parametro_to_s(p_val) # p_val.is_a?(Array) ? p_val.join(TEXT_ARRAY_ELEM_SEP) : p_val
          row["#{p}_#{fonte}"] = pv
          result[:filter] |= [{ id: p, name: p, type: tipo_val }]
          res = _check_param_condition?(p: p, v: pv, filtri_parametro: filtri_parametro) if filtri_parametro[p]
        elsif filtri_parametro[p]
          res = _check_param_condition?(p: p, v: p_val, filtri_parametro: filtri_parametro)
        end
        res
      end

      def _aggiungi_report_comparativi_entity_fields(fields:, result:) # rubocop:disable Metrics/AbcSize
        pnv_num = result[:parametri_non_vuoti].size
        result[:fields] = dynamic_grid_header(fields: (fields - CUSTOM_COLUMNS).select { |f| result[:parametri_non_vuoti][f] }, values: result[:data].first, header_wrap: false) do |ff|
          ff.each do |f|
            f_name = f.delete(:name)
            f.clear
            f.update(label: f_name, columns: FONTE_MAPPING.values.map { |v| { name: "#{f_name}_#{v}", label: v } })
          end
          ff.unshift(label: 'version', columns: FONTE_MAPPING.values.map { |v| { name: "version_#{v}",  label: v, width: 60, locked: (pnv_num > 0) } }) if result[:parametri_non_vuoti]['version']
          ff.unshift(name: 'dist_name',  label: 'DistName', width: 500, locked: (pnv_num > 0))
          ff.unshift(name: 'valore_entita',   label: 'Valore Entità', width: 100, locked: (pnv_num > 0))
          ff.unshift(name: 'm_entita',   label: 'Meta Entità', width: 100, locked: (pnv_num > 0))
          ff.unshift(name: 'esito_diff', label: 'Esito comparazione', width: 120, locked: (pnv_num > 0))
        end
      end

      include FiltroEntitaUtil
      def grid_report_comparativi_entity_records # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        result = { total: 0, fields: [], data: [], parametri_non_vuoti: {}, filter: [] }
        np = filtro[:meta_entita_naming_path]
        fmm = filtro[:filtro_metamodello] || {}
        if np
          # fields = ((filtro[:meta_parametri_selected] && filtro[:meta_parametri_selected][np]) || [])
          fields = ((filtro[:filtro_metamodello] && filtro[:filtro_metamodello][np] && filtro[:filtro_metamodello][np][FILTRO_MM_PARAMETRI]) || [])
          any_field = fields.first == META_PARAMETRO_ANY
          fields = filtro[:project_param_selected] unless filtro[:project_param_selected] && filtro[:project_param_selected].empty?
          param_type_hash = {}
          rc_id = filtro[:rc_id] || []
          rc = Db::ReportComparativo.get_by_pk(rc_id)
          vr = rc.sistema_id ? Db::Sistema.get_by_pk(rc.sistema_id).vendor_release_id : Db::OmcFisico.get_by_pk(rc.omc_fisico_id).vendor_release_fisico_id
          fields_to_render = []
          fields_to_render += CUSTOM_COLUMNS if filtro[:project_param_selected] && (filtro[:project_param_selected].empty? || filtro[:project_param_selected].include?('version'))
          omc_fisico = filtro[:omc_fisico] ? filtro[:omc_fisico] : false
          metamodello = MetaModello.keywords_fisico_logico(omc_fisico)
          q = metamodello.classe_meta_parametro.join(metamodello.classe_meta_entita.table_name, id: metamodello.field_me_id.to_sym)
          q = q.where(naming_path: np, Sequel.qualify(metamodello.classe_meta_entita.table_name, metamodello.field_vr_id.to_sym) => vr)
          q = q.where(Sequel.qualify(metamodello.classe_meta_parametro.table_name, :full_name) => fields) unless any_field && filtro[:project_param_selected] && filtro[:project_param_selected].empty?
          rich_fields_x_sistema = q.map do |record|
            fn = record[:full_name]
            t = record[:imv] || record[:ims] ? 'char' : record[:tipo]
            param_type_hash[fn] ||= t
            { name: record[:full_name], type: record[:type], multi: record[:is_multivalue] }
          end
          fields_to_render |= rich_fields_x_sistema.map { |f| f[:name] }
          limite = request.params['max'].to_i
          filtro_v = (filtro[:filtro_version] || '').to_s.split_to_true_hash
          rc.entita.db.transaction do
            feu_info = feu_query_per_naming_path(naming_path: np, dataset: rc.entita.dataset, filtro_np: fmm[np] || {}, nome_tabella: rc.entita.table_name, use_pid: false)
            query = feu_info[:feu_query_np]
            filtro_wi = feu_info[:feu_filtro_wi]
            query = add_entity_value_condition(query: query, entity_filter: filtro[:valore_entita_filtered]) if filtro[:valore_entita_filtered] && !filtro[:valore_entita_filtered].empty?
            query.each do |rec|
              next if !filtro_wi.empty? && !feu_tengo?(rec[:dist_name], filtro_wi)
              next if Db::ReportComparativo.ignora_per_filtro_version(rec, filtro_v)
              _aggiungi_rc_entity_record(rec: rec, result: result, fields: fields_to_render, filtro: filtro, pth: param_type_hash, limite: limite)
            end
          end
          if filtro[:project_param_filtered] && !filtro[:project_param_filtered].empty?
            fields_to_render.each do |p|
              result[:parametri_non_vuoti][p] ||= true
              result[:filter] |= [{ id: p, name: p, type: param_type_hash[p.to_s] || 'char' }]
            end
          end
          # _aggiungi_report_comparativi_entity_fields(fields: fields, result: result)
          _aggiungi_report_comparativi_entity_fields(fields: fields_to_render, result: result)
        end
        result.delete(:parametri_non_vuoti)
        result
      end

      def grid_parametri_header_report_comparativo
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        meta_entita_naming_path = filtro[:meta_entita_naming_path]
        meta_parametri_selected = filtro[:meta_parametri_selected]
        raise 'Nessun meta_entita_naming_path specificato' unless meta_entita_naming_path
        meta_parametri_selected += CUSTOM_COLUMNS unless filtro[:add_version] == false
        # grid_parametri_progetto_radio_matching_filter(params: meta_parametri_selected, filter: filtro[:nome_parametro])
        grid_matching_param_value_filter(params: meta_parametri_selected, filter: filtro[:nome_parametro])
      end

      def _aggiungi_filtro_rc_consistency_check(query:, input:)
        sessione = logged_in
        case input
        when FILTRO_RC_ACCOUNT_CONSISTENCY_CHECK_UTENTE_MINE
          query = query.where(account_id: sessione.account_id).exclude(Sequel.ilike(:nome, "%#{RC_CONSISTENCY_CHECK_PATTERN}%"))
        when FILTRO_RC_ACCOUNT_CONSISTENCY_CHECK_UTENTE_CONSISTENCY_CHECK
          query = add_like_conditions(query: query, field: :nome, pattern: RC_CONSISTENCY_CHECK_PATTERN)
        when FILTRO_RC_ACCOUNT_CONSISTENCY_CHECK_UTENTE_OTHER
          query = query.exclude(account_id: sessione.account_id).exclude(Sequel.ilike(:nome, "%#{RC_CONSISTENCY_CHECK_PATTERN}%"))
        else
          query
        end
        query
      end
    end

    App.route('report_comparativi') do |r|
      r.post('elimina') do
        handle_request { elimina_report_comparativi }
      end
      r.post('entity/grid') do
        handle_request { grid_report_comparativi_entity_records }
      end
      r.post('esecuzione/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_esecuzione_report_comparativo(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('export/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_report_comparativo(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('grid') do
        handle_request { grid_report_comparativi }
      end
      r.post('delete/grid') do
        handle_request { grid_delete_report_comparativi }
      end
      r.get('list') do
        handle_request { list_report_comparativi }
      end
      r.post('column_filter/grid') do
        handle_request { grid_parametri_header_report_comparativo }
      end
    end
  end
end
