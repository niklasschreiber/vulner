# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170430
#

module Irma
  #
  module Web
    #
    class App < Roda
      def list_tipi_attivita_schedulata
        query = Db::AttivitaSchedulata.select(:tipo_attivita_id).distinct
        ret = query.map do |att|
          { id: att[:tipo_attivita_id], descr: Db::TipoAttivita.get_by_pk(att[:tipo_attivita_id]).nome }
        end
        ret.sort_by { |x| x[:descr] }
      end

      def list_stati_attivita_schedulate
        query = Db::AttivitaSchedulata.select(:stato).distinct
        ret = query.map do |att|
          { descr: att[:stato].upcase, id: att[:stato] }
        end
        ret.unshift(descr: format_msg(:STATO_ATTIVA), id: format_msg(:STATO_ATTIVA))
        ret.unshift(descr: format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA), id: format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA))
        ret
      end

      def list_stati_operativi_attivita_schedulate
        query = Db::AttivitaSchedulata.select(:stato_operativo).distinct
        ret = query.map do |att|
          { descr: att[:stato_operativo].upcase, id: att[:stato_operativo] }
        end
        ret.unshift(descr: format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA), id: format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA))
        ret
      end

      def grid_attivita_schedulate # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        filtro.delete(:archivio) if filtro[:archivio].eql? format_msg(:STORE_TUTTI_GLI_ARCHIVI)
        filtro.delete(:ambiente) if filtro[:ambiente].eql? format_msg(:STORE_TUTTI_GLI_AMBIENTI)
        filtro.delete(:stato) if filtro[:stato].eql? format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA)
        filtro.delete(:stato_operativo) if filtro[:stato_operativo].eql? format_msg(:STORE_TUTTI_GLI_STATI_ATTIVITA)
        filtro.delete(:tipo_periodicita) if filtro[:tipo_periodicita].eql? format_msg(:STORE_TUTTI_TIPI_PERIODICITA)

        cond = []
        unless filtro[:ambiente].to_s.empty?
          cond << (filtro[:ambiente] == PROFILO_AMBIENTE_NODEF ? 'ambiente IS NULL' : "ambiente = '#{filtro[:ambiente]}'")
        end
        unless filtro[:archivio].to_s.empty?
          cond << (filtro[:archivio] == ATTIVITA_ARCHIVIO_NODEF ? 'archivio IS NULL' : "archivio = '#{filtro[:archivio]}'")
        end
        cond << "stato = '#{filtro[:stato]}'" if filtro[:stato]
        cond << "stato_operativo = '#{filtro[:stato_operativo]}'" if filtro[:stato_operativo]
        cond << "inizio_validita >= '#{Time.at(filtro[:data_inizio_da] / 1000)}'" if filtro[:data_inizio_da]
        cond << "inizio_validita <= '#{Time.at(filtro[:data_inizio_a] / 1000)}'" if filtro[:data_inizio_a]
        # TODO: come gestire il ritorno di account_cond con la query per il filtro accounts ^
        account_cond = []
        cond = calcolo_condizioni_filtri_competenze_attivita(cond: cond, account_cond: account_cond)

        query = Db::AttivitaSchedulata.where(cond.empty? ? nil : cond.join(' AND '))
        # filtro accounts
        query = applica_filtro_tipo_account_matricola(query, filtro[:visualizza], filtro[:matricola])
        # filtro tipo attivita
        query = query.where(tipo_attivita_id: filtro[:tipo_attivita]) if filtro[:tipo_attivita] && !filtro[:tipo_attivita].empty?

        records_with_export(filtro, 'filename' => 'export_attivita_schedulate_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          records_attivita_from_query(query.reverse_order(:updated_at)) do |ret|
            ret[:tipo_attivita] = Db::TipoAttivita.get_by_pk(ret[:tipo_attivita_id]).nome
            periodo_split_length = ret[:periodo].split(' ').length
            add_record = filtro[:tipo_periodicita] == TIPO_PERIODICITA_PERIODICA ? (periodo_split_length >= 4) : (periodo_split_length < 4)
            if !filtro[:tipo_periodicita] || add_record
              formatter.add_record_values(ret, ret)
            end
          end
        end
      end

      def json_date_prossime_schedulazioni # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        rs = Rufus::Scheduler.parse(filtro[:cron_expression])
        schedulazioni = []
        filtro[:number_of_next_dates].to_i.times { schedulazioni << rs.next_time(schedulazioni.last || Time.now) }
        { success: true, messaggio: '', data: schedulazioni.map { |t| t.strftime('%d/%m/%Y %H:%M:%S') } }
      end
    end

    App.route('attivita_schedulate') do |r|
      r.post('grid') do
        handle_request { grid_attivita_schedulate }
      end
      r.get('tipi/list') do
        handle_request { list_tipi_attivita_schedulata }
      end
      r.get('stati/list') do
        handle_request { list_stati_attivita_schedulate }
      end
      r.get('stati_operativi/list') do
        handle_request { list_stati_operativi_attivita_schedulate }
      end
      r.post('salva') do
        handle_request(error_msg_key: :AGGIORNAMENTO_ATTIVITA_SCHEDULATA_FALLITO) do
          update_record = JSON.parse(request.params['record'] || '{}').symbolize_keys
          ok = begin
            Db::AttivitaSchedulata.cron?(update_record[:periodo]) || Db::AttivitaSchedulata.datetime?(update_record[:periodo]) || update_record[:periodo].empty?
          rescue
            false
          end
          if ok
            as = Db::AttivitaSchedulata.first(id: update_record[:id])
            as.update(update_record) if as
            format_msg(:AGGIORNAMENTO_ATTIVITA_SCHEDULATA_ESEGUITO)
          else
            { success: false, messaggio: format_msg(:AGGIORNAMENTO_ATTIVITA_SCHEDULATA_FALLITO_PER_PERIODO_NON_CRON) }
          end
        end
      end
      r.post('date_prossime_schedulazioni/json') do
        handle_request { json_date_prossime_schedulazioni }
      end
    end
  end
end
