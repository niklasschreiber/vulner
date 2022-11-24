# vim: set fileencoding=utf-8
#
# Author       : P.Cortona
#
# Creation date: 20180802
#

module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def salva_cgi # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        if filtro[:radioFields] == 'manual_fields'
          manual_fields = filtro[:manual_fields]
          nome_cella = manual_fields['nome_cella']
          lac = manual_fields['lac']
          handle_request(error_msg_key: :INSERIMENTO_CGI_FALLITO) do
            raise 'Nome Cella o LAC non avvalorati!' if nome_cella.nil? || lac.nil?
            ci = Db::AnagraficaCgi.nuova_cella(nome_cella: nome_cella, lac: lac)
            _create_message_with_button(nome_cella: nome_cella, msg: format_msg(:CGI_INSERITO, nome_cella: nome_cella, lac: lac, ci: ci)) || ''
          end
        else
          schedula_attivita do |parametri, opts_as|
            (opts_as || {}).update(input_file: post_locfile_to_shared_fs(locfile: parametri['anagrafica_cgi_modal_form_filter_file_lista_cgi'], dir: opts_as[:attivita_schedulata_dir]))
            Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_NUOVO_CGI, opts_as)
          end
        end
      end

      def grid_cgi # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        query = Db::AnagraficaCgi

        # filtro regioni
        f = filtro.delete(:regioni) || []
        query = query.where(regione: f) unless f.empty?
        # filtro lac
        f = filtro.delete(:lac).to_s
        query = add_like_conditions(query: query, field: :lac, pattern: f) unless f.empty?
        # filtro ci
        f = filtro.delete(:ci).to_s
        query = add_like_conditions(query: query, field: :ci, pattern: f) unless f.empty?
        # filtro rete_id
        f = filtro.delete(:rete_id) || []
        query = query.where(rete_id: f) unless f.empty?
        # filtro tipoCelle
        tipocelle = filtro.delete(:tipoCelle).to_s
        tipocelle = nil if tipocelle == 'all'
        if tipocelle
          query = query.left_outer_join(Db::ProgettoRadio.table_name, nome_cella: :nome_cella).select_all(Db::AnagraficaCgi.table_name)
          query = query.send((tipocelle == 'prn') ? :exclude : :where, Sequel.qualify(Db::ProgettoRadio.table_name, :nome_cella) => nil)
        end
        # filtro nome_cella
        f = filtro.delete(:nome_cella).to_s
        query = add_like_conditions(query: query, field: Sequel.qualify(Db::AnagraficaCgi.table_name, :nome_cella), pattern: f) unless f.empty?

        # filtro data_aggiornamento
        { da: '>=', a: '<=' }.each do |suffix, oper|
          query = aggiungi_filtro_data(query, filtro.delete("data_aggiornamento_#{suffix}".to_sym), 'updated_at', oper, table: Db::AnagraficaCgi.table_name)
        end

        records_with_export(filtro, 'filename' => 'export_cgi_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.order(:nome_cella).each do |record|
            formatter.add_record_values(record,
                                        id:         record[:id],
                                        nome_cella: record[:nome_cella],
                                        regione:    record[:regione],
                                        ci:         record[:ci],
                                        lac:        record[:lac],
                                        rete_id:    record[:rete_id],
                                        updated_at: timestamp_to_string(record[:updated_at])
                                       )
          end
        end
      end

      def grid_ci_liberi # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        filtro_regioni = filtro[:regioni].to_s.empty? ? nil : filtro[:regioni].map { |r| "'#{r.gsub("'", "''")}'" }.join(',')
        query = Irma::Db.connection.fetch("
              select ci_regione_gsm.regione,
                     ci_regione_gsm.free as num_free_gsm,
                     ci_regione_umts.free as num_free_umts
                from (select regione, rete_id, count(*) as free from ci_regioni where busy=#{CI_REGIONE_BUSY_NO} and rete_id=1 group by regione, rete_id) ci_regione_gsm,
                     (select regione, rete_id, count(*) as free from ci_regioni where busy=#{CI_REGIONE_BUSY_NO} and rete_id=2 group by regione, rete_id) ci_regione_umts
               where ci_regione_gsm.regione = ci_regione_umts.regione
                     #{filtro_regioni ? "and ci_regione_gsm.regione in (#{filtro_regioni})" : ''}
            order by ci_regione_gsm.regione".tr("\n", ''))

        records_with_export(filtro, 'filename' => 'export_ci_liberi_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.each do |record|
            record[:free_gsm]             = Db::CiRegione.percentuale_ci_liberi(record[:num_free_gsm])
            record[:free_umts]            = Db::CiRegione.percentuale_ci_liberi(record[:num_free_umts])
            record[:allarme_soglia_gsm]   = Db::CiRegione.soglia_ci_liberi_superata?(record[:free_gsm])
            record[:allarme_soglia_umts]  = Db::CiRegione.soglia_ci_liberi_superata?(record[:free_umts])
            formatter.add_record_values(record, record)
          end
        end
      end

      def _create_message_with_button(opts = {})
        nome_cella = opts[:nome_cella]
        messaggio = ''
        if nome_cella
          regione = AnagraficaTerritoriale.regione_da_nome_cella(nome_cella)
          confinanti = AnagraficaTerritoriale.confinanti_di_regione(regione)
          confinanti_json = confinanti.to_json.gsub('"', '&quot;')
          messaggio = <<-EOS
            <div>#{opts[:msg]}</div>
            <hr noshade>
            <span>#{format_msg(:CI_LIBERI_REGIONE_E_CONFINANTI, regione: regione)}</span>
            <button class='visualizzaCi' onclick="Irma.visualizzaCiLiberi({'regione': &quot;#{regione}&quot;, 'confinanti': #{confinanti_json}})">CI Liberi</button>
          EOS
        end
        messaggio
      end

      App.route('cgi') do |r|
        r.post('ci_liberi/grid') do
          handle_request { grid_ci_liberi }
        end
        r.post('elimina') do
          handle_request(error_msg_key: :ELIMINAZIONE_CGI_FALLITA) do
            row_id = JSON.parse(request.params['id'] || '[]')
            nome_cella = Db::AnagraficaCgi.where(id: row_id[0]).select_map(:nome_cella).first
            res = Db::AnagraficaCgi.elimina_cella(id: row_id)
            raise "Impossibile cancellare la cella con id #{row_id}"  unless res
            _create_message_with_button(nome_cella: nome_cella, msg: format_msg(:CGI_ELIMINATO)) || ''
          end
        end
        r.post('grid') do
          handle_request { grid_cgi }
        end
        r.post('salva') do
          salva_cgi
        end
      end
    end
  end
end
