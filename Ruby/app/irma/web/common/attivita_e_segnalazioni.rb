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
      def _decode_competenza(klass:, comp:, all_label:, single_label:, multi_label:)
        if comp == COMPETENZA_TUTTO
          all_label
        else
          comp.size == 1 ? klass.get_by_pk(comp.first).full_descr : "#{comp.size} #{multi_label}"
        end
      rescue
        "#{single_label} con id #{comp.first} non esistente"
      end

      def records_attivita_from_query(query) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        query.map do |record|
          competenze = record[:competenze] || {}
          descr = if (c = competenze[TIPO_COMPETENZA_SISTEMA.to_s])
                    _decode_competenza(klass: Db::Sistema, comp: c, all_label: 'tutti i sistemi', single_label: 'sistema', multi_label: 'sistemi')
                  elsif (c = competenze[TIPO_COMPETENZA_OMCFISICO.to_s])
                    _decode_competenza(klass: Db::OmcFisico, comp: c, all_label: 'tutti gli omc fisici', single_label: 'omc fisico', multi_label: 'omc fisici')
                  elsif (c = competenze[TIPO_COMPETENZA_VENDORRELEASE.to_s])
                    _decode_competenza(klass: Db::VendorRelease, comp: c, all_label: 'tutti le vendor releases', single_label: 'vendor release', multi_label: 'vendor releases')
                  else
                    ''
                  end
          ret = record.values.merge(
            oggetto_attivita:   descr,
            created_at:         timestamp_to_string(record[:created_at]),
            updated_at:         timestamp_to_string(record[:updated_at]),
            utente:             descrizione_utente_per_gui(record[:utente_id])
          )
          ret[:profilo] = Constant.label(:profilo, ret[:profilo_id]) if record[:profilo_id]
          block_given? ? yield(ret) : ret
        end
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def aggiorna_condizioni_per_filtro_competenze(filtro_competenze: :preferenze, cond:, account_cond:)
        sessione = logged_in
        fc = []

        sdcf = filtro_competenze == :preferenze ? id_sistemi_di_competenza_filtrati : (sessione.data[:sistemi_di_competenza] || [])
        tcs = "(competenze::jsonb ->> '#{TIPO_COMPETENZA_SISTEMA}')"
        fc << "((#{tcs} = '#{COMPETENZA_TUTTO}') OR (#{tcs}::jsonb ?| array['#{sdcf.join("','")}']))" unless sdcf.empty?
        ofdcf = filtro_competenze == :preferenze ? id_omc_fisici_di_competenza_filtrati : (sessione.data[:omc_fisici_di_competenza] || [])
        tco = "(competenze::jsonb ->> '#{TIPO_COMPETENZA_OMCFISICO}')"
        fc << "((#{tco} = '#{COMPETENZA_TUTTO}') OR (#{tco}::jsonb ?| array['#{ofdcf.join("','")}']))" unless ofdcf.empty?
        # HOOK per evitare problemi con le attivita' sulle vendor release in prova
        vrdcf = filtro_competenze == :preferenze ? id_vendor_releases_di_competenza_filtrati : (sessione.data[:vendor_releases_di_competenza] || [])
        tcv = "(competenze::jsonb ->> '#{TIPO_COMPETENZA_VENDORRELEASE}')"
        if [PROFILO_RPN, PROFILO_SUPERUSER_PROG].include?(sessione.account.profilo_id) && (filtro_competenze != :preferenze)
          fc << "(#{tcv} IS NOT NULL)" unless vrdcf.empty?
        else
          fc << "(#{tcv}::jsonb ?| array['#{vrdcf.join("','")}'])" unless vrdcf.empty?
        end

        # aggiunta competenze di tipo ADMIN
        comp_admin_descr = Constant.constant(:tipo_competenza, TIPO_COMPETENZA_ADMIN).info[:descr]
        # HOOK per evitare problemi al profilo RPN con attivita' senza account tipo rimozione sessioni scadute
        if sessione.account.profilo.tipi_competenze.index(comp_admin_descr)
          if sessione.account.profilo_id != PROFILO_RPN
            fc << "(competenze::jsonb ->> '#{TIPO_COMPETENZA_ADMIN}' = '#{COMPETENZA_TUTTO}')"
            account_cond << '(account_id IS NULL)'
          end
        end
        cond << "(#{fc.join(' OR ')})" unless fc.empty?
        cond
      end
      # rubocop:enable all

      def calcolo_condizioni_filtri_competenze_attivita(filtro_sof: nil, cond:, account_cond:, filtro_competenze: :preferenze)
        aggiorna_condizioni_per_filtro_competenze(filtro_competenze: filtro_competenze, cond: cond, account_cond: account_cond)

        # filtro sistema - omc fisico
        if filtro_sof
          f_omcl = filtro_sof[:sistema_id]
          f_omcf = filtro_sof[:omc_fisico_id]
          cond << "(((competenze::jsonb ->> '#{TIPO_COMPETENZA_SISTEMA}') = '#{COMPETENZA_TUTTO}') OR (competenze::jsonb ->> '#{TIPO_COMPETENZA_SISTEMA}')::jsonb ?| array['#{f_omcl}'])" if f_omcl
          cond << "(((competenze::jsonb ->> '#{TIPO_COMPETENZA_OMCFISICO}') = '#{COMPETENZA_TUTTO}') OR (competenze::jsonb ->> '#{TIPO_COMPETENZA_OMCFISICO}')::jsonb ?| array['#{f_omcf}'])" if f_omcf
        end
        cond
      end

      def records_segnalazioni_from_query(query:, # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
                                          order: [Sequel.desc(:id)], filtro: {})
        sessione = logged_in
        filtro[:matricola] = sessione.matricola  if filtro[:visualizza] == FILTRO_SEGNALAZIONI_UTENTE_MINEOTHER
        if filtro[:matricola]
          f = filtro.delete(:matricola).to_s
          subquery = add_like_conditions(query: Db::Utente, field: :matricola, pattern: f,
                                         extra_field: Sequel.function(:concat, Sequel.qualify(:utenti, :nome), ' ', :cognome))
          query = query.where(utente_id: subquery.select(:id))
        end
        query = query.where(id: filtro[:export_selection]) if filtro[:export_format] && filtro[:export_selection] && !filtro[:export_selection].empty?
        nome_utente = {}
        Db::Utente.all_using_cache.each { |k, u| nome_utente[k.to_s] = u.formato_per_gui }
        attivita_suffix = filtro[:attivita_id] ? "attivita_#{filtro[:attivita_id]}_" : ''
        filename = "export_segnalazioni_#{attivita_suffix}@FULL_DATE@@ESTENSIONE@"
        records_with_export(filtro, 'filename' => filename, 'txt' => Db::Segnalazione::RecordFormatterTxt) do |formatter|
          query = query.limit(filtro[:limit] || request.params['limit']).offset(filtro[:start] || request.params['start'])
          query = if formatter.is_a?(Db::Segnalazione::RecordFormatterTxt)
                    query.order(Sequel.lit('naming_path COLLATE "C"'), Sequel.asc(:meta_parametro, nulls: :first))
                  else
                    order ? query.order(*order) : query
                  end
          query.each do |record|
            sofvr = sistema_o_omc_fisico_o_vendor_release(record)
            values = record.values.merge(
              funzione:             record[:funzione_id] ? Db::Funzione.get_by_pk(record[:funzione_id]).nome : '',
              tipo_segnalazione:    record[:tipo_segnalazione_id] ? Db::TipoSegnalazione.get_by_pk(record[:tipo_segnalazione_id]).full_nome : '',
              oggetto_segnalazione: sofvr ? sofvr.full_descr : '',
              created_at:           timestamp_to_string(record[:created_at]),
              utente:               nome_utente[record[:utente_id].to_s] || '',
              profilo:              record[:profilo_id] ? Constant.label(:profilo, record[:profilo_id]) : ''
            )
            formatter.add_record_values(record, values)
          end
        end
      end

      def records_funzioni(filtro: {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        ff = filtro[:funzione_id] ? [filtro[:funzione_id]].flatten.compact : nil
        fv = (filtro[:visualizza] == FILTRO_SEGNALAZIONI_UTENTE_MINE) && (sessione = logged_in) && (sessione.data[:funzioni_abilitate] || [])
        res = Constant.constants(:funzione).map do |c|
          next unless c.info.key?(:tipi_segnalazioni)
          next if ff && !ff.include?(c.value)
          next if filtro[:riferimento_segnalazioni] && c.info[:riferimento_segnalazioni] != filtro[:riferimento_segnalazioni]
          next if fv && !fv.include?(c.value)
          c.info
        end.compact
        res.sort_by { |x| x[:nome] }
      end
    end
  end
end
