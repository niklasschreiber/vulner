# vim: set fileencoding=utf-8
#
# Author       : M. Cutillo
#
# Creation date: 20170822
#

module Irma
  #
  module Web
    class App < Roda
      def _impostazioni_base_filtro_eventi
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys(true)
        filtro.delete(:ambiente) if filtro[:ambiente].eql? format_msg(:STORE_TUTTI_GLI_AMBIENTI)
        filtro.delete(:profilo) if filtro[:profilo].eql? format_msg(:STORE_TUTTI_I_PROFILI)
        filtro
      end

      def _query_eventi # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        columns = Db::Evento.columns.dup
        columns.delete(:id)
        columns.delete(:nome)
        columns.delete(:descr)
        columns.delete(:matricola)
        columns.delete(:dettaglio)
        columns.delete(:profilo)
        columns.delete(:created_at)
        columns.delete(:updated_at)
        qlf_evento_cols = [Sequel.qualify(:eventi, :id), Sequel.qualify(:eventi, :nome).as(:nome_evento), Sequel.qualify(:eventi, :descr)]
        qlf_evento_date_cols = [Sequel.qualify(:eventi, :created_at).as(:data_creazione_evento), Sequel.qualify(:eventi, :updated_at)]
        qlf_cols = [Sequel.qualify(:eventi, :profilo).as(:profilo_evento), Sequel.qualify(:utenti, :nome).as(:nome_utente), Sequel.qualify(:utenti, :matricola).as(:matricola_utente)]
        #
        query = Db::Evento
        query = query.select(*(columns + qlf_evento_cols + qlf_evento_date_cols + qlf_cols))
        query = query.left_outer_join(Db::Account.table_name, id: :account_id).left_outer_join(Db::Utente.table_name, id: :utente_id)
        query
      end

      def _query_eventi_record(formatter, record)
        rec_val = record.values.merge(
          utente_full_descr: record[:matricola_utente] ? "[#{record[:matricola_utente]}] #{record.utente_descr}" : '',
          nome:              record[:nome_evento],
          profilo:           record[:profilo_evento],
          created_at:        timestamp_to_string(record[:data_creazione_evento]),
          updated_at:        timestamp_to_string(record[:updated_at])
        )
        formatter.add_record_values(record, rec_val)
      end

      def grid_eventi # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = _impostazioni_base_filtro_eventi
        query = _query_eventi
        query = query.where(Sequel.qualify(:eventi, :nome) => filtro[:nome_evento]) if filtro[:nome_evento]
        query = query.where(categoria: filtro[:categoria_evento]) if filtro[:categoria_evento]
        query = query.where(Sequel.qualify(:eventi, :profilo) => filtro[:profilo]) if filtro[:profilo]
        query = query.where(Sequel.qualify(:eventi, :ambiente) => filtro[:ambiente]) if filtro[:ambiente]
        # filtri utente
        f = filtro.delete(:filtro_cognome).to_s
        query = add_like_conditions(query: query, field: :cognome, pattern: f) unless f.empty?
        f = filtro.delete(:filtro_nome).to_s
        query = add_like_conditions(query: query, field: Sequel.qualify(:utenti, :nome), pattern: f) unless f.empty?
        f = filtro.delete(:matricola).to_s
        query = add_like_conditions(query: query, field: Sequel.qualify(:utenti, :matricola), pattern: f) unless f.empty?
        # filtro host
        f = filtro.delete(:host).to_s
        query = add_like_conditions(query: query, field: :host, pattern: f) unless f.empty?
        # filtro data_creazione_evento
        { da: '>=', a: '<=' }.each do |suffix, oper|
          query = aggiungi_filtro_data(query, filtro.delete("data_creazione_evento_#{suffix}".to_sym), 'created_at', oper, table: Db::Evento.table_name)
        end

        query = query.reverse_order(:id)
        records_with_export(filtro, 'filename' => 'export_eventi_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.each { |record| _query_eventi_record(formatter, record) }
        end
      end

      def grid_eventi_per_attivita # rubocop:disable Metrics/AbcSize
        filtro = _impostazioni_base_filtro_eventi
        records_with_export(filtro, 'filename' => 'export_eventi_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          sub_query = Db::Attivita.where(Sequel.or(id: request.params['attivita_id']) | Sequel.or(root_id: request.params['attivita_id'])).select(:id)
          _query_eventi.where(attivita_id: sub_query).reverse_order(:id).each { |record| _query_eventi_record(formatter, record) }
        end
      end

      def list_eventi_nomi_filtrati
        Db::Evento.select(:nome).distinct.order(:nome).map { |event| { id: event[:nome], descr: d = event[:nome], full_descr: d } }
      end

      def list_eventi_categorie_filtrate
        Db::Evento.select(:categoria).distinct.order(:categoria).map { |event| { id: event[:categoria], descr: d = event[:categoria], full_descr: d } }
      end
    end

    App.route('eventi') do |r|
      r.get('categorie_filtrate/list') do
        handle_request { list_eventi_categorie_filtrate }
      end
      r.post('grid') do
        handle_request { grid_eventi }
      end
      r.get('nomi_filtrati/list') do
        handle_request { list_eventi_nomi_filtrati }
      end
      r.post('per_attivita/grid') do
        handle_request { grid_eventi_per_attivita }
      end
    end
  end
end
