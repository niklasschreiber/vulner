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
      def grid_segnalazioni # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        sessione = logged_in
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        # filtro.delete(:ambiente) if filtro[:ambiente].eql? format_msg(:STORE_TUTTI_GLI_AMBIENTI)
        filtro.delete(:visualizza) if filtro[:visualizza].eql? FILTRO_SEGNALAZIONI_UTENTE_ALL

        ambiente = filtro[:ambiente]
        query = (ambiente != format_msg(:STORE_TUTTI_GLI_AMBIENTI) && ambiente) ? Db::Segnalazione.where(ambiente: ambiente) : Db::Segnalazione

        case filtro[:riferimento_segnalazioni]
        when RIFERIMENTO_SEGNALAZIONI_SISTEMA, RIFERIMENTO_SEGNALAZIONI_PROGETTO_RADIO
          filtro[:sistema_omcFisico] = { sistema_id: filtro[:id_sistema] || id_sistemi_di_competenza_filtrati }
        when RIFERIMENTO_SEGNALAZIONI_OMC_FISICO
          filtro[:sistema_omcFisico] = { omc_fisico_id: filtro[:id_omc_fisico] || id_omc_fisici_di_competenza_filtrati }
        when RIFERIMENTO_SEGNALAZIONI_PROGETTO_IRMA, RIFERIMENTO_SEGNALAZIONI_REPORT_COMPARATIVO
          filtro[:sistema_omcFisico] = { sistema_id: filtro[:id_sistema] } if filtro[:id_sistema]
          filtro[:sistema_omcFisico] = { omc_fisico_id: filtro[:id_omc_fisico] } if filtro[:id_omc_fisico]
          query = query.where(progetto_irma_id: filtro[:pi_id]) if filtro[:pi_id]
          query = query.where(report_comparativo_id: filtro[:rc_id]) if filtro[:rc_id]
        when RIFERIMENTO_SEGNALAZIONI_ADRN
          query = query.where(vendor_release_id: filtro[:id_vendor_release]) if filtro[:id_vendor_release]
        end

        funzioni = records_funzioni(filtro: filtro).flat_map { |f| f[:value] }.compact

        query = query.where(funzione_id: funzioni)
        query = query.exclude(tipo_segnalazione_id: TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_IN_CORSO) unless filtro[:flag_segnalazioni_progresso]
        query = query.where(to_update_adrn: filtro[:to_update_adrn]) unless filtro[:to_update_adrn].to_s.empty?

        # valori ammessi per filtro[:sistema_omcFisico]
        #  - nil
        #  - { }
        #  - { sistema_id: 1 }
        #  - { omc_fisico_id: 1 }
        #
        fq_fnp = ((Sequel.or(sistema_id: nil) | Sequel.or(sistema_id: filtro_sistemi || [])) & (Sequel.or(omc_fisico_id: nil) | Sequel.or(omc_fisico_id: filtro_omc_fisico || [])))
        fq = (filtro[:sistema_omcFisico]) ? { sistema_id: nil, omc_fisico_id: nil }.merge(filtro[:sistema_omcFisico]) : fq_fnp

        query = query.where(fq) if fq
        query = query.where(archivio: filtro[:archivio]) if filtro[:archivio]
        query = query.send(filtro[:visualizza] == FILTRO_SEGNALAZIONI_UTENTE_MINE ? :where : :exclude, account_id: sessione.account_id) if filtro[:visualizza]

        query = query.where(tipo_segnalazione_id: filtro[:tipo_segnalazione_id]) if filtro[:tipo_segnalazione_id]
        # filtro data_creazione_segnalazione
        { da: '>=', a: '<=' }.each do |suffix, oper|
          query = aggiungi_filtro_data(query, filtro.delete("data_creazione_segnalazione_#{suffix}".to_sym), 'created_at', oper, table: Db::Segnalazione.table_name)
        end
        records_segnalazioni_from_query(query: query, filtro: filtro)
      end

      def list_tipi_segnalazioni # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        ts_id_list = records_funzioni(filtro: filtro).flat_map { |f| f[:tipi_segnalazioni] || [] } + TIPO_SEGNALAZIONE_GENERICA
        ts_id_list -= [TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_IN_CORSO] unless filtro[:flag_segnalazioni_progresso]
        ret = ts_id_list.map do |ts_id|
          c = Constant.constant(:tipo_segnalazione, ts_id)
          f_part = c.info[:funzione_id] ? '[' + Constant.constant(:funzione, c.info[:funzione_id]).info[:nome] + ']' : ''
          ts_part = c.info[:categoria].upcase + '_' + c.info[:nome].upcase
          { id: c.value, identificativo_messaggio: f_part + ' ' + ts_part }
        end
        ret.sort_by { |h| h[:identificativo_messaggio] }
      end
    end

    App.route('segnalazioni') do |r|
      r.post('grid') do
        handle_request { grid_segnalazioni }
      end
      r.get('tipi/list') do
        handle_request { list_tipi_segnalazioni }
      end
    end
  end
end
