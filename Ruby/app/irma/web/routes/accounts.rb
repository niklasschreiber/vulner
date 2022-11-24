# Author       : M. Cutillo, G. Cristelli
#
# Creation date: 20161115
#
require 'irma/ds_ti'

module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def _query_accounts # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        columns = Db::Account.columns.dup
        columns.delete(:id)
        columns.delete(:descr)
        columns.delete(:created_at)
        columns.delete(:updated_at)
        qualify_accounts_cols = [Sequel.qualify(:accounts, :id), Sequel.qualify(:accounts, :descr)]
        qualify_cols = [Sequel.qualify(:utenti, :dipartimento), Sequel.qualify(:utenti, :matricola), Sequel.qualify(:utenti, :cognome), Sequel.qualify(:utenti, :email),
                        Sequel.qualify(:utenti, :nome).as('nome_utente')]
        qualify_cols << Sequel.qualify(:profili, :nome).as('profilo')
        competence_cols = [Sequel.lit("((competenze::jsonb->>'sistema')::jsonb->>'reti') AS competenze_reti")]
        competence_cols << Sequel.lit("((competenze::jsonb->>'sistema')::jsonb->>'vendors') AS competenze_vendors")
        competence_cols << Sequel.lit("((competenze::jsonb->>'sistema')::jsonb->>'omc_fisici') AS competenze_omc_fisici")
        competence_cols << Sequel.lit("((competenze::jsonb->>'sistema')::jsonb->>'sistemi') AS competenze_sistemi")
        Db::Account.join(Db::Utente.table_name, id: :utente_id)
                   .join(Db::Profilo.table_name, id: Sequel.qualify(:accounts, :profilo_id))
                   .select(*(qualify_accounts_cols + qualify_cols + columns + competence_cols))
      end

      def _filtri_selezione_accounts(query) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys

        f = filtro.delete(:matricola).to_s
        query = add_like_conditions(query: query, field: :matricola, pattern: f) unless f.empty?

        f = filtro.delete(:filtro_cognome).to_s
        query = add_like_conditions(query: query, field: :cognome, pattern: f) unless f.empty?

        f = filtro.delete(:filtro_nome).to_s
        query = add_like_conditions(query: query, field: Sequel.qualify(:utenti, :nome), pattern: f) unless f.empty?

        # filtro profilo
        filtro.delete(:profilo) if filtro[:profilo].eql? format_msg(:STORE_TUTTI_I_PROFILI)
        query = query.where(profilo_id: filtro[:profilo]) if filtro[:profilo]

        # filtro stato_account
        filtro.delete(:stato_account) if filtro[:stato_account].eql? format_msg(:STORE_TUTTI_GLI_STATI_ACCOUNT)
        query = query.where(stato: filtro[:stato_account]) if filtro[:stato_account]

        # filtro data_scadenza
        { da: '>=', a: '<=' }.each do |suffix, oper|
          query = aggiungi_filtro_data(query, filtro.delete("data_scadenza_#{suffix}".to_sym), 'data_scadenza', oper)
        end

        query
      end

      def grid_accounts # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        query = _query_accounts
        profili_accessibili = Constant.constants(:profilo).select { |c| c.info[:assegnabile_da_gui] }.map(&:value)
        query = query.where(profilo_id: profili_accessibili) if profili_accessibili
        query = _filtri_selezione_accounts(query)
        query = query.order(:matricola, :profilo)
        tutti = { sistemi: {}, omc_fisici: {} }
        %w(sistemi omc_fisici).each do |s|
          tab = s == 'sistemi' ? Db::Sistema : Db::OmcFisico
          tab.each { |d| tutti[:"#{s}"][d.id] = d }
        end
        records_with_export(filtro, 'filename' => 'export_accounts_@FULL_DATE@@ESTENSIONE@', 'export' => filtro[:export_format]) do |formatter|
          query.each do |record|
            record_dup = record.dup
            next_condition = false
            %w(sistemi omc_fisici).each do |s|
              record = _add_record_columns(filtro, s, record, record_dup, tutti[:"#{s}"])
              next_condition ||= (filtro[:"#{s}"] && (!record[:"result_#{s}"] || (record[:"result_#{s}"] & filtro[:"#{s}"]).empty?))
            end
            next if next_condition
            values = record.values.merge(nome: record[:nome_utente], department: record[:dipartimento])
            %i(data_scadenza data_ultimo_login data_ultima_attivazione data_ultima_sospensione data_ultima_disattivazione).each do |k|
              values[k] = timestamp_to_string(record[k])
            end
            formatter.add_record_values(record, values)
          end
        end
      end

      def _add_record_columns(filtro, name, record, record_dup, tutti) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        next unless name
        record[:"num_#{name}"] = NUM_FITTIZIO_NESSUNO
        result_columns = nil
        record[:"result_#{name}"] = result_columns
        num_tutti_sistemi = name == 'sistemi' ? tutti.size : Db::Sistema.count
        cond_sistemi      = record_dup[:competenze_sistemi] &&
                            record_dup[:competenze_sistemi] != COMPETENZA_TUTTO &&
                            (JSON.parse(record_dup[:competenze_sistemi]).length < num_tutti_sistemi)
        unless record_dup[:"competenze_#{name}"].nil? || record_dup[:"competenze_#{name}"] == COMPETENZA_TUTTO
          result_columns = JSON.parse(record_dup[:"competenze_#{name}"])
          if name == 'omc_fisici'
            result_columns &= Db::Sistema.where(id: JSON.parse(record_dup[:competenze_sistemi])).select_map(:omc_fisico_id) if cond_sistemi
          end
        end
        if record_dup[:"competenze_#{name}"] == COMPETENZA_TUTTO
          num_reti_tutti          = Db::Rete.count
          num_vendors_tutti       = Db::Vendor.count
          num_omc_fisici_tutti    = name == 'omc_fisici' ? tutti.size : Db::OmcFisico.count
          cond_reti               = record_dup[:competenze_reti] &&
                                    record_dup[:competenze_reti] != COMPETENZA_TUTTO &&
                                    (JSON.parse(record_dup[:competenze_reti]).length < num_reti_tutti)
          cond_vendors            = record_dup[:competenze_vendors] &&
                                    record_dup[:competenze_vendors] != COMPETENZA_TUTTO &&
                                    (JSON.parse(record_dup[:competenze_vendors]).length < num_vendors_tutti)
          cond_omc_fisici         = record_dup[:competenze_omc_fisici] &&
                                    record_dup[:competenze_omc_fisici] != COMPETENZA_TUTTO &&
                                    (JSON.parse(record_dup[:competenze_omc_fisici]).length < num_omc_fisici_tutti)
          json_competenze_vendors = JSON.parse(record_dup[:competenze_vendors]) if cond_vendors
          update_result_columns   = false
          if name == 'sistemi'
            sub_query = Db::Sistema
            sub_query = sub_query.join(Db::VendorRelease.table_name, id: :vendor_release_id).where(Sequel.qualify(:vendor_releases, :vendor_id) => json_competenze_vendors) if cond_vendors
            sub_query = sub_query.where(Sequel.qualify(:sistemi, :rete_id) => JSON.parse(record_dup[:competenze_reti])) if cond_reti
            sub_query = sub_query.where(Sequel.qualify(:sistemi, :omc_fisico_id) => JSON.parse(record_dup[:competenze_omc_fisici])) if cond_omc_fisici
            update_result_columns = cond_reti || cond_vendors || cond_omc_fisici
          else
            sub_query = Db::OmcFisico
            sub_query = sub_query.join(Db::Sistema.table_name, omc_fisico_id: :id).where(Sequel.qualify(:sistemi, :id) => JSON.parse(record_dup[:competenze_sistemi])) if cond_sistemi
            sub_query = sub_query.where(Sequel.qualify(:omc_fisici, :vendor_id) => json_competenze_vendors) if cond_vendors
            update_result_columns = cond_vendors || cond_sistemi
          end
          if update_result_columns
            result_columns = sub_query.select_map(Sequel.qualify(:"#{name}", :id))
          else
            record[:"competenze_#{name}"] = MSG_TUTTI
            record[:"num_#{name}"] = num_tutti_sistemi
            result_columns = tutti.keys
          end
        end
        if result_columns && record[:"competenze_#{name}"] != MSG_TUTTI
          result_columns &= tutti.keys
          record[:"num_#{name}"] = result_columns.length
          record[:"competenze_#{name}"] = if filtro[:export_format]
                                            result_columns.map { |id| tutti[id].full_descr }.sort.join(" \n ")
                                          else
                                            _sistemi_come_lista(result_columns, tutti, name)
                                          end
        end
        record[:"result_#{name}"] = result_columns
        record
      end

      def _sistemi_come_lista(col, tis, name)
        next unless col
        name_label = name == 'sistemi' ? LABEL_SISTEMI : LABEL_OMC_FISICI
        sistemi = '<select class="inCellGridSelect"><option>' + "#{col.length} #{name_label}</option>"
        option = col.map do |id|
          next unless (s = tis[id])
          '<option disabled>' + s.full_descr + '</option>'
        end
        sistemi = sistemi + option.sort.join('') + '</select>'
        sistemi
      end

      def ldap_info_per_matricola
        matricola = request.params['matricola']
        matricola = matricola.upcase if matricola
        ldap_result = Ds_ti.get_user_info(matricola, %w(uid cn sn givenname tigemployeetype company department mail))
        ldap_result['email'] = ldap_result['mail']
        { success: ldap_result ? true : false, ldap_result: ldap_result }
      rescue => e
        Irma.logger.warn("Validazione Ldap fallita: #{e}")
        { success: false, messaggio: e.to_s }
      end

      def list_vendors_filtrati # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        vendor_selezionati = filtro[:vendors_id_filtro] || []
        Constant.constants(:vendor).select { |c| vendor_selezionati.empty? || vendor_selezionati.include?(c.value) }.map { |c| { id: c.value, descr: c.label } }.sort_by { |a| a[:descr] }
      end

      def list_reti_filtrate # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        reti_selezionate = filtro[:reti_id_filtro] || []
        Constant.constants(:rete).select { |c| reti_selezionate.empty? || reti_selezionate.include?(c.value) }.map { |c| { id: c.value, descr: c.label } }.sort_by { |a| a[:descr] }
      end

      def list_profili_nuovo_account # rubocop:disable Metrics/AbcSize
        matricola = request.params['matricola']
        profilo_selezionato = request.params['profilo_selezionato'] && !request.params['profilo_selezionato'].empty?
        return [] unless matricola
        profili_associati = matricola && !profilo_selezionato ? Db::Account.join(Db::Utente.table_name, id: :utente_id).where(matricola: matricola).select_map(:profilo_id) : []
        Constant.constants(:profilo).select { |c| c.info[:assegnabile_da_gui] && !profili_associati.include?(c.value) }.map { |c| { id: c.value, descr: c.label } }.sort_by { |a| a[:descr] }
      end

      def _query_omc_logici_competenza # rubocop:disable Metrics/AbcSize
        columns = Db::Sistema.columns.dup
        columns.delete(:id)
        columns.delete(:descr)
        columns.delete(:rete_id)
        columns.delete(:vendor_id)
        columns.delete(:header_pr)
        columns.delete(:created_at)
        columns.delete(:updated_at)
        qualify_sys_cols = [Sequel.qualify(:sistemi, :id), Sequel.qualify(:sistemi, :descr), Sequel.qualify(:sistemi, :rete_id).as('rete_sis_id')]
        qualify_cols = [Sequel.qualify(:vendor_releases, :vendor_id), Sequel.qualify(:vendor_releases, :rete_id)]
        Db::Sistema.join(Db::VendorRelease.table_name, id: :vendor_release_id).select(*(qualify_sys_cols + qualify_cols + columns))
      end

      def grid_omc_logici_account
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        grid_omc_logici_account_dato_filtro(filtro)
      end

      def grid_omc_logici_account_dato_filtro(filtro) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity,  Metrics/MethodLength
        query = _query_omc_logici_competenza
        # filtro dell'insieme di reti e vendors competenti selezionate
        query = query.where(Sequel.qualify(:sistemi, :rete_id) => filtro[:reti_id]) if filtro[:reti_id] && !filtro[:reti_id].empty?
        query = query.where(Sequel.qualify(:vendor_releases, :rete_id) => filtro[:reti_id]) if filtro[:reti_id] && !filtro[:reti_id].empty?
        query = query.where(Sequel.qualify(:vendor_releases, :vendor_id) => filtro[:vendors_id]) if filtro[:vendors_id] && !filtro[:vendors_id].empty?
        # filtro applicato dalle opzioni reti e vendors di ricerca selezionate
        query = query.where(Sequel.qualify(:sistemi, :rete_id) => filtro[:reti_id_filtro]) if filtro[:reti_id_filtro] && !filtro[:reti_id_filtro].empty?
        query = query.where(Sequel.qualify(:vendor_releases, :rete_id) => filtro[:reti_id_filtro]) if filtro[:reti_id_filtro] && !filtro[:reti_id_filtro].empty?
        query = query.where(Sequel.qualify(:vendor_releases, :vendor_id) => filtro[:vendors_id_filtro]) if filtro[:vendors_id_filtro] && !filtro[:vendors_id_filtro].empty?
        omcf_selected = filtro[:omc_fisici_selected]
        query = query.where(Sequel.qualify(:sistemi, :omc_fisico_id) => omcf_selected) if omcf_selected && !omcf_selected.empty? && omcf_selected != COMPETENZA_TUTTO
        query.order(:descr).map do |record|
          record.values.merge(
            rete:           Constant.label(:rete, record[:rete_sis_id]),
            vendor:         Constant.label(:vendor, record[:vendor_id]),
            vendor_release: Db::VendorRelease.get_by_pk(record[:vendor_release_id]).descr,
            omc_fisico:     Db::OmcFisico.get_by_pk(record[:omc_fisico_id]).nome
          )
        end
      end

      def grid_omc_fisici_account
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        grid_omc_fisici_account_dato_filtro(filtro)
      end

      def grid_omc_fisici_account_dato_filtro(filtro)
        query = Db::OmcFisico
        query = query.where(vendor_id: filtro[:vendors_id]) if filtro[:vendors_id]
        query = query.where(vendor_id: filtro[:vendors_id_filtro]) if filtro[:vendors_id_filtro]
        query.order(:nome).map do |record|
          record.values.merge(
            vendor:        Constant.label(:vendor, record[:vendor_id]),
            formato_audit: record.formato_audit
          )
        end
      end

      def _build_field_competenze(record) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        competenze = {}
        profilo = Constant.constant(:profilo, record[:profilo])
        if profilo && profilo.info[:con_competenze]
          competenze = { 'sistema' => { 'vendors' => '*', 'reti' => '*', 'omc_fisici' => '*', 'sistemi' => '*' } }.symbolize_keys
          if record[:reti_id] && !record[:reti_id].empty? && record[:reti_id].length != Constant.constants(:rete).count
            competenze[:sistema][:reti] = record[:reti_id]
          end
          if record[:vendors_id] && !record[:vendors_id].empty? && record[:vendors_id].length != Constant.constants(:vendor).count
            competenze[:sistema][:vendors] = record[:vendors_id]
          end
          if record[:omc_fisici_selected] && !record[:omc_fisici_selected].empty?
            if record[:omc_fisici_selected].length != grid_omc_fisici_account_dato_filtro(record).length
              competenze[:sistema][:omc_fisici] = record[:omc_fisici_selected]
            end
          end
          if record[:omc_logici_selected] && !record[:omc_logici_selected].empty?
            if record[:omc_logici_selected].length != grid_omc_logici_account_dato_filtro(record).length
              competenze[:sistema][:sistemi] = record[:omc_logici_selected]
            end
          end
        end
        competenze
      end

      def _account_selezionato
        @account_selezionato ||= begin
                                   id_account = request.params['id_account_selezionato']
                                   raise 'Nessun account selezionato' unless id_account
                                   acc = Db::Account.get_by_pk(id_account)
                                   raise "Account con id #{id_account} non trovato" unless acc
                                   acc
                                 end
      end

      def _aggiorna_preferenze
        handle_request(error_msg_key: :AGGIORNAMENTO_PREFERENZE_FALLITO, rinnova_sessione: false) do |wsr|
          account = wsr.sessione.account
          yield(wsr.sessione, account)
          account.save
          renew_session(force: true, data: wsr.sessione.data)
          { runtime: wsr.sessione.runtime }
        end
      end
    end

    App.route('accounts') do |r|
      r.post('attiva') do
        handle_request(error_msg_key: :ACCOUNT_ATTIVATO_CON_ERRORE) do |wsr|
          _account_selezionato.attiva!
          _account_selezionato.update(descr: format_msg(:ACCOUNT_ATTIVATO_MANUALMENTE, utente_descr: wsr.sessione.utente_descr, matricola: wsr.sessione.matricola, profilo: wsr.sessione.profilo))
          format_msg(:ACCOUNT_ATTIVATO)
        end
      end
      r.post('disattiva') do
        handle_request(error_msg_key: :ACCOUNT_DISATTIVATO_CON_ERRORE) do |wsr|
          _account_selezionato.disattiva!
          _account_selezionato.update(descr: format_msg(:ACCOUNT_DISATTIVATO_MANUALMENTE, utente_descr: wsr.sessione.utente_descr, matricola: wsr.sessione.matricola, profilo: wsr.sessione.profilo))
          format_msg(:ACCOUNT_DISATTIVATO)
        end
      end
      r.post('grid') do
        handle_request { grid_accounts }
      end
      r.get('ldap_info_per_matricola') do
        handle_request { ldap_info_per_matricola }
      end
      r.post('omc_logici_account/grid') do
        handle_request { grid_omc_logici_account }
      end
      r.post('omc_fisici_account/grid') do
        handle_request { grid_omc_fisici_account }
      end
      r.post('preferenze/azzera') do
        _aggiorna_preferenze do |sessione, account|
          account.preferenze = {}
          sessione.data = sessione.data.update(preferenze: account.preferenze_per_sessione)
        end
      end
      r.post('preferenze/salva') do
        _aggiorna_preferenze do |sessione, account|
          nuove_preferenze = JSON.parse(request.params['state'] || '{}')
          account.preferenze = (account.preferenze || {}).update(nuove_preferenze)
          sessione.data = sessione.data.update(preferenze: account.preferenze_per_sessione)
        end
      end
      r.get('profili_nuovo_account/list') do
        handle_request { list_profili_nuovo_account }
      end
      r.get('reti_filtrate/list') do
        handle_request { list_reti_filtrate }
      end
      r.post('salva') do
        record = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        handle_request(error_msg_key: record[:id].to_s.empty? ? :ACCOUNT_INSERITO_CON_ERRORE : :ACCOUNT_AGGIORNATO_CON_ERRORE) do
          Db::Account.define(record[:matricola], record[:profilo],
                             nome:          record[:nome],
                             cognome:       record[:cognome],
                             dipartimento:  record[:department],
                             email:         record[:email],
                             profilo_id:    record[:profilo],
                             descr:         record[:descr],
                             data_scadenza: record[:data_scadenza] && !record[:data_scadenza].to_s.empty? ? Time.at(record[:data_scadenza] / 1000) : nil,
                             stato:         ACCOUNT_STATO_ATTIVO,
                             competenze:    JSON.parse(_build_field_competenze(record).to_json)
                            )
          format_msg(record[:id].to_s.empty? ? :ACCOUNT_INSERITO : :ACCOUNT_AGGIORNATO)
        end
      end
      r.post('sospendi') do
        handle_request(error_msg_key: :ACCOUNT_SOSPESO_CON_ERRORE) do |wsr|
          _account_selezionato.sospendi!
          _account_selezionato.update(descr: format_msg(:ACCOUNT_SOSPESO_MANUALMENTE, utente_descr: wsr.sessione.utente_descr, matricola: wsr.sessione.matricola, profilo: wsr.sessione.profilo))
          format_msg(:ACCOUNT_SOSPESO)
        end
      end
      r.get('stati/list') do
        handle_request { list_values_for_constants(scope: :account, prefix: :stato, allow_blank: true, allow_blank_msg: format_msg(:STORE_TUTTI_GLI_STATI_ACCOUNT)) }
      end
      r.get('vendors_filtrati/list') do
        handle_request { list_vendors_filtrati }
      end
    end
  end
end
