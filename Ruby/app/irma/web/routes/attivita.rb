# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170428
#

module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def _profilo_ga?
        logged_in && (logged_in.data[:id_profilo_corrente] == PROFILO_GA)
      end

      # chiavi in result attivita da non mostrare in gui di dettaglio
      DELETE_FROM_RESULT_KEYWORDS = [
        CONTEGGIO_ALBERATURA_RC_KEYWORD
      ].freeze

      def _columns_attivita_for_query
        @columns_attivita_for_query ||= Db::Attivita.columns - [:cronologia_stato, :info_comando]
      end

      def _attivita_records(query) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        records_with_export(filtro, 'filename' => 'export_storico_attivita_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          records_attivita_from_query(query.select(*_columns_attivita_for_query)) do |ret|
            if ret[:risultato].is_a?(Sequel::Postgres::JSONHash) && ret[:risultato]['result'].is_a?(Hash)
              DELETE_FROM_RESULT_KEYWORDS.each do |kkk|
                ret[:risultato]['result'].delete(kkk)
              end
            end
            ret[:artifacts] = (ret[:artifacts] || []).map { |file, what| [file, File.basename(file), what] }
            ret[:ambiente] = ret[:ambiente] || ''
            ret[:archivio] = ret[:archivio] || ''
            ret[:foglie_eseguite] = (ret[:foglie_stato_finale] || {}).values.inject(0, :+)
            ret[:progress] = ret[:foglie_totali] == 0 ? 0 : 1.0 * ret[:foglie_eseguite] / ret[:foglie_totali]
            formatter.add_record_values(ret, ret)
            block_given? ? yield(ret) : ret
          end
        end
      end

      def _condizioni_filtro_query_attivita(base_query, filtro_competenze: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = _imposta_parametri_filtro
        filtro.delete(:stato_attivita) if filtro[:stato_attivita].eql? format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA)

        cond = _imposta_condizioni(filtro)
        cond << "stato = '#{filtro[:stato_attivita]}'" if filtro[:stato_attivita] && !filtro[:stato_attivita].empty?
        cond << "created_at >= '#{Time.at(filtro[:data_filter_da] / 1000)}'" if filtro[:data_filter_da]
        cond << "created_at <= '#{Time.at(filtro[:data_filter_a] / 1000)}'" if filtro[:data_filter_a]

        query = base_query

        if filtro_competenze
          # filtri competenza e sof: come gestire il ritorno di account_cond ?
          account_cond = []
          cond = calcolo_condizioni_filtri_competenze_attivita(filtro_sof: filtro[:sistema_omcFisico], filtro_competenze: :tutte, cond: cond, account_cond: account_cond)
        end
        query = query.where(cond.join(' AND '))

        # filtro accounts
        query = applica_filtro_tipo_account_matricola(query, filtro[:visualizza], filtro[:matricola])
        # query = _applica_filtro_ambiente_secondo_profilo(query)
        # filtro tipo attivita
        query = query.where(descr: filtro[:tipo_attivita]) if filtro[:tipo_attivita] && !filtro[:tipo_attivita].empty?
        query
      end

      def _imposta_parametri_filtro # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        filtro.delete(:archivio) if filtro[:archivio].eql? format_msg(:STORE_TUTTI_GLI_ARCHIVI)
        filtro.delete(:ambiente) if filtro[:ambiente].eql? format_msg(:STORE_TUTTI_GLI_AMBIENTI)
        filtro[:sistema_omcFisico] = filtro[:sof][:id] if filtro[:sof] && filtro[:sof][:id]
        filtro
      end

      def _imposta_condizioni(filtro)
        cond = ['pid IS NULL']
        unless filtro[:ambiente].to_s.empty?
          cond << (filtro[:ambiente] == PROFILO_AMBIENTE_NODEF ? 'ambiente IS NULL' : "ambiente = '#{filtro[:ambiente]}'")
        end
        unless filtro[:archivio].to_s.empty?
          cond << (filtro[:archivio] == ATTIVITA_ARCHIVIO_NODEF ? 'archivio IS NULL' : "archivio = '#{filtro[:archivio]}'")
        end
        cond
      end

      def _applica_filtro_ambiente_secondo_profilo(query)
        sessione = logged_in
        if sessione.profilo == Constant.constant(:profilo, :rp).info[:nome]
          query = query.exclude(ambiente: PROFILO_AMBIENTE_QUAL)
        end
        if sessione.profilo == Constant.constant(:profilo, :rq).info[:nome]
          query = query.exclude(ambiente: PROFILO_AMBIENTE_PROG)
        end
        query
      end

      def grid_storico_attivita
        query = _condizioni_filtro_query_attivita(Db::Attivita, filtro_competenze: !_profilo_ga?)
        _attivita_records(query.reverse_order(:updated_at))
      end

      def grid_attivita(account_corrente: true, ultimo_giorno: true, filtro_competenze: nil) # rubocop:disable Metrics/AbcSize
        cond = ['pid IS NULL']
        sessione = logged_in
        cond << "created_at >= '#{Time.now - 86_400}'" if ultimo_giorno

        # HOOK per evitare problemi al profilo GGU
        account_cond = if sessione.account.profilo_id == PROFILO_GGU
                         ["(account_id = #{sessione.account_id})"]
                       else
                         cds = ["(coalesce(account_id, 0) #{account_corrente ? '=' : '!='} #{sessione.account_id})", # sessione.ambiente ? "ambiente = '#{sessione.ambiente}'" : nil
                         ].compact.join(' AND ')
                         [cds]
                       end

        aggiorna_condizioni_per_filtro_competenze(filtro_competenze: filtro_competenze, cond: cond, account_cond: account_cond) if filtro_competenze
        cond << "(#{account_cond.join(' OR ')})"
        _attivita_records(Db::Attivita.where(cond.join(' AND ')).reverse_order(:updated_at))
      end

      def tree_attivita_per_attivita_schedulata
        att_schedulata_id = request.params['id'].to_i
        query = Db::Attivita.where(attivita_schedulata_id: att_schedulata_id).order(:id)
        res = tree_root_attivita(query)
        res[:id] = att_schedulata_id
        res
      end

      def tree_root_attivita(query = nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        records = {}
        roots = []
        query ||= Db::Attivita.query_tree(request.params['id'])
        _attivita_records(query) do |ret|
          roots << ret unless ret[:pid]
          ret[:leaf] = true
          ret[:iconCls] = "tree_attivita_stato_#{ret[:stato]}"
          records[ret[:id]] = ret
          if ret[:pid]
            (records[ret[:pid]][:children] ||= []) << ret
            records[ret[:pid]][:leaf] = false
          end
        end
        records.each do |_k, r|
          r[:iconCls] = "tree_attivita_contenitore_stato_#{r[:stato]}" unless r[:leaf]
        end
        roots.each { |root| root[:expanded] = (roots.size == 1) }
        { text: 'root', expanded: true, children: roots }
      end

      def grid_segnalazioni_per_attivita
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        filtro[:attivita_id] = request.params['id'] || filtro[:id]
        records_segnalazioni_from_query(query: Db::Segnalazione.where(attivita_id: Db::Attivita.query_tree(filtro[:attivita_id]).select(:id)), filtro: filtro)
      end

      def list_stati_attivita_con_count
        query = _condizioni_filtro_query_attivita(Db::Attivita.group_and_count(:stato), filtro_competenze: !_profilo_ga?)
        ret = query.map do |att|
          { id: att[:stato], descr: "#{Constant.label(:attivita, att[:stato], :stato)} (#{att[:count]})" }
        end
        ret.unshift(descr: format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA), id: format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA))
        ret
      end

      def list_tipi_attivita_filtrati # rubocop:disable Metrics/AbcSize
        filtro = _imposta_parametri_filtro
        cond = _imposta_condizioni(filtro)
        query = Db::Attivita.select(:descr)

        unless _profilo_ga?
          # filtri competenza e sof: come gestire il ritorno di account_cond ?
          account_cond = []
          cond = calcolo_condizioni_filtri_competenze_attivita(filtro_sof: filtro[:sistema_omcFisico], cond: cond, account_cond: account_cond)
        end
        query = query.where(cond.join(' AND '))

        # filtro accounts
        query = applica_filtro_tipo_account_matricola(query, filtro[:visualizza], filtro[:matricola])
        # query = _applica_filtro_ambiente_secondo_profilo(query)
        query = query.distinct.order(:descr).map { |att| { id: att[:descr], descr: d = att[:descr], full_descr: d } }
        query
      end
    end

    App.route('attivita') do |r|
      r.post('altri_utenti_ultimo_giorno_filtrate/grid') do
        handle_request(rinnova_sessione: false) { grid_attivita(account_corrente: false, filtro_competenze: :preferenze) }
      end
      r.post('altri_utenti_ultimo_giorno/grid') do
        handle_request(rinnova_sessione: false) { grid_attivita(account_corrente: false, filtro_competenze: :tutte) }
      end
      r.post('personali_ultimo_giorno_filtrate/grid') do
        handle_request(rinnova_sessione: false) { grid_attivita(filtro_competenze: :preferenze) }
      end
      r.post('personali_ultimo_giorno/grid') do
        handle_request(rinnova_sessione: false) { grid_attivita }
      end
      r.get('per_attivita_schedulata/tree') do
        handle_request { tree_attivita_per_attivita_schedulata }
      end
      r.get('tipi_attivita_root/list') do
        handle_request { list_tipi_attivita_filtrati }
      end
      r.get('root/tree') do
        handle_request(rinnova_sessione: false) { tree_root_attivita }
      end
      r.post('segnalazioni/grid') do
        handle_request(rinnova_sessione: false) { grid_segnalazioni_per_attivita }
      end
      r.get('stati_con_count/list') do
        handle_request { list_stati_attivita_con_count }
      end
      r.post('storico/grid') do
        handle_request { grid_storico_attivita }
      end
    end
  end
end
