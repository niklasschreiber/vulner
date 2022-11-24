# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170508
#

module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def _grid_metaparametri_with_flag(query:, filtro:, filename:) # rubocop:disable Metrics/AbcSize
        vr = Db::VendorRelease.get_by_pk(filtro[:vendor_release_id]) if filtro[:vendor_release_id] && !filtro[:export_format]
        if vr
          query = query.where(rete_id: vr.rete_id, vendor_id: vr.vendor_id)
          query = query.where(Sequel.or(vendor_releases: nil) | Sequel.lit("vendor_releases::jsonb ? '#{vr.descr}'"))
        end
        records_with_export(filtro, 'filename' => "#{filename}_@FULL_DATE@@ESTENSIONE@", 'export' => filtro['export_format']) do |formatter|
          query.order(:vendor_id, :full_name).each do |record|
            rec_val = record.values.merge(rete: Constant.label(:rete, record.rete_id), vendor: Constant.label(:vendor, record[:vendor_id]))
            rec_val.update(vendor_releases: record.vendor_releases.join(',')) if record.vendor_releases
            formatter.add_record_values(record, rec_val)
          end
        end
      end

      def _import_metaparametri_with_flag(file:, command:)
        raise 'Nessun file specificato' if (file || {}).empty?
        file_path = file[:tempfile].path
        res = nil
        if file_path
          opts = [Constant.info(:comando, command)[:command],
                  '--account_id', logged_in.account_id, '--input_file', file_path]
          res = Command.process(opts, logger: Command.logger)
        end
        (res && res[:result]) ? { success: true, messaggio: 'Metaparametri caricati correttamente' } : { success: false, messaggio: 'Metaparametri non caricati' }
      end

      def grid_meta_parametri # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(false)
        query = Db::MetaParametro.from_self(alias: :mp)
        filtro_metamodello = filtro[:filtro_metamodello] || {}
        naming_paths = filtro_metamodello.keys || []
        klass_me = Db::MetaEntita
        meta_entita_id = if filtro[:meta_entita_selected_id]
                           filtro[:meta_entita_selected_id]
                         elsif !naming_paths.empty?
                           q = klass_me.where(naming_path: naming_paths)
                           q = q.where(vendor_release_id: filtro[:vendor_release_id]) if filtro[:vendor_release_id]
                           q.select_map(:id)
                         end
        query = query.join(klass_me.table_name, id: :meta_entita_id).select_all(:mp)
        query = query.select_more(Sequel.qualify(:meta_entita, :nome).as('meta_entita'), Sequel.qualify(:meta_entita, :naming_path).as('naming_path'))
        query = query.where(Sequel.qualify(:mp, :meta_entita_id) => meta_entita_id) if meta_entita_id
        # filtro_metamodello = {"me1" => {"parametri" => ["mp1","mp2",...]}...}
        w_cond = nil
        filtro_metamodello.each do |naming_path, valore|
          p = valore[FILTRO_MM_PARAMETRI] || []
          next if p.empty?
          np_cond = Sequel.or(Sequel.qualify('meta_entita', :naming_path) => naming_path)
          np_cond &= Sequel.or(Sequel.qualify(:mp, :full_name) => p) unless p.first == META_PARAMETRO_ANY
          w_cond = w_cond ? (w_cond | np_cond) : np_cond
        end
        query = query.where(w_cond) if w_cond

        query.order(:nome).map do |record|
          vr = Db::VendorRelease.get_by_pk(record[:vendor_release_id])
          record.values.merge(vendor_release: vr.descr, created_at: timestamp_to_string(record[:created_at]), updated_at: timestamp_to_string(record[:updated_at]),
                              regole_calcolo: JSON.generate(record[:regole_calcolo]),
                              regole_calcolo_ae: JSON.generate(record[:regole_calcolo_ae]), rete: Constant.label(:rete, vr.rete_id))
        end
      end

      def grid_mm_meta_parametri # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(false)
        query = Db::MetaParametro.from_self(alias: :mp).select(:id, :nome, :vendor_release_id)
        filtro_metamodello = filtro[:filtro_metamodello] || {}
        naming_paths = filtro_metamodello.keys || []
        klass_me = Db::MetaEntita
        meta_entita_id = if filtro[:meta_entita_selected_id]
                           filtro[:meta_entita_selected_id]
                         elsif !naming_paths.empty?
                           q = klass_me.where(naming_path: naming_paths)
                           q = q.where(vendor_release_id: filtro[:vendor_releases]) if filtro[:vendor_releases]
                           q.select_map(:id)
                         end
        query = query.join(klass_me.table_name, id: :meta_entita_id).select_all(:mp)
        query = query.select_more(Sequel.qualify(:meta_entita, :nome).as('meta_entita'), Sequel.qualify(:meta_entita, :naming_path).as('naming_path'))
        query = query.where(Sequel.qualify(:mp, :meta_entita_id) => meta_entita_id) if meta_entita_id
        # filtro_metamodello = {"me1" => {"parametri" => ["mp1","mp2",...]}...}
        w_cond = nil
        filtro_metamodello.each do |naming_path, valore|
          p = valore[FILTRO_MM_PARAMETRI] || []
          next if p.empty?
          np_cond = Sequel.or(Sequel.qualify('meta_entita', :naming_path) => naming_path)
          np_cond &= Sequel.or(Sequel.qualify(:mp, :full_name) => p) unless p.first == META_PARAMETRO_ANY
          w_cond = w_cond ? (w_cond | np_cond) : np_cond
        end
        query = query.where(w_cond) if w_cond

        query.order(:nome).map do |record|
          vr = Db::VendorRelease.get_by_pk(record[:vendor_release_id])
          record.values.merge(vendor_release: vr.descr,
                              created_at: timestamp_to_string(record[:created_at]),
                              updated_at: timestamp_to_string(record[:updated_at]),
                              type: 'P')
        end
      end

      def grid_metaparametri_update_on_create
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(false)
        _grid_metaparametri_with_flag(query: Db::MetaparametroUpdateOnCreate, filtro: filtro, filename: 'export_mp_update_on_create')
      end

      def grid_metaparametri_secondari
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(false)
        _grid_metaparametri_with_flag(query: Db::MetaparametroSecondario, filtro: filtro, filename: 'export_mp_secondari')
      end

      def import_metaparametri_update_on_create
        _import_metaparametri_with_flag(file: request.params['file_import_metaparametri'], command: COMANDO_IMPORT_METAP_UPD_ON_CRT)
      end

      def import_metaparametri_secondari
        _import_metaparametri_with_flag(file: request.params['file_import_metaparametri'], command: COMANDO_IMPORT_METAPARAMETRI_SECONDARI)
      end

      def meta_parametri_modifica # rubocop:disable Metrics/AbcSize
        handle_request(error_msg_key: :AGGIORNAMENTO_METAMODELLO_FALLITO) do
          filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
          id = filtro.delete(:id)
          rete_adj_id = filtro.delete(:rete_adj_id)
          filtro[:rete_adj] = (rete_adj_id.nil? || rete_adj_id == '') ? nil : Constant.label(:rete, rete_adj_id)
          Db::MetaParametro.where(id: id).each do |mp|
            mp.update(filtro)
          end
          format_msg(:AGGIORNAMENTO_METAMODELLO_ESEGUITO)
        end
      end

      def meta_parametri_elimina
        handle_request(error_msg_key: :ELIMINAZIONE_METAPARAMETRO_FALLITA) do
          filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
          mp = Db::MetaParametro.first(id: filtro[:id])
          mp.destroy_with_audit
          format_msg(:ELIMINAZIONE_METAPARAMETRO_ESEGUITA)
        end
      end

      def meta_parametri_aggiungi
        handle_request(error_msg_key: :INSERIMENTO_METAPARAMETRO_FALLITO) do
          filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
          meta_entita_id = filtro.delete(:pid)
          rete_adj_id = filtro.delete(:rete_adj_id)
          filtro[:meta_entita_id] = meta_entita_id
          filtro[:rete_adj] = (rete_adj_id.nil? || rete_adj_id == '') ? nil : Constant.label(:rete, rete_adj_id)
          Db::MetaParametro.create_with_audit(audit_extra_info: nil, attributes: filtro)
          format_msg(:INSERIMENTO_METAPARAMETRO_ESEGUITO)
        end
      end

      def list_columns_meta_parametro
        me = Db::MetaParametro
        me.mapped_columns_per_file_adrn.sort.map do |record|
          {
            descr: record
          }
        end
      end
    end

    App.route('meta_parametri') do |r|
      r.post('grid') do
        handle_request { grid_meta_parametri }
      end
      r.post('mm/grid') do
        handle_request { grid_mm_meta_parametri }
      end
      r.post('modifica') do
        handle_request { meta_parametri_modifica }
      end
      r.post('elimina') do
        handle_request { meta_parametri_elimina }
      end
      r.post('aggiungi') do
        handle_request { meta_parametri_aggiungi }
      end
      r.post('update_on_create/grid') do
        handle_request { grid_metaparametri_update_on_create }
      end
      r.post('update_on_create/import') do
        handle_request { import_metaparametri_update_on_create }
      end
      r.post('metaparametri_secondari/grid') do
        handle_request { grid_metaparametri_secondari }
      end
      r.post('metaparametri_secondari/import') do
        handle_request { import_metaparametri_secondari }
      end
      r.post('aggiorna') do
        handle_request(error_msg_key: :AGGIORNAMENTO_METAMODELLO_FALLITO) do
          update_info = JSON.parse(request.params['updateInfo'] || '{}').symbolize_keys
          meta_parametro = Db::MetaParametro.get_by_pk(update_info[:meta_parametro_id] || update_info[:id])
          regole = JSON.parse(update_info[:regole_calcolo]) if update_info[:regole_calcolo]
          regole_ae = JSON.parse(update_info[:regole_calcolo_ae]) if update_info[:regole_calcolo_ae]
          meta_parametro[:regole_calcolo] = regole if regole
          meta_parametro[:regole_calcolo_ae] = regole_ae if regole_ae
          meta_parametro.save
          format_msg(:AGGIORNAMENTO_METAMODELLO_ESEGUITO)
        end
      end
      r.post('columns/list') do
        handle_request { list_columns_meta_parametro }
      end
    end
  end
end
