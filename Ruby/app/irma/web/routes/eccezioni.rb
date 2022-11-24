# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20181001
#

module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def _applica_condizioni_filtro(query:, filtro:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # filtro nome
        f = filtro.delete(:nome).to_s
        query = add_like_conditions(query: query, field: :nome, pattern: f) unless f.empty?
        # filtro lac
        f = filtro.delete(:descr).to_s
        query = add_like_conditions(query: query, field: :descr, pattern: f) unless f.empty?
        # filtro tipo
        f = filtro.delete(:tipo) || []
        query = query.where(tipo: f) unless f.empty?
        # filtro eccezioni_nette
        unless (filtro[:eccezioni_nette] || '').empty?
          f = filtro.delete(:eccezioni_nette) || []
          query = query.where(eccezioni_nette: f)
        end
        # filtro utente_ultima_modifica
        f = filtro.delete(:matricola).to_s
        query = add_like_conditions(query: query, field: :matricola, pattern: f, extra_field: :utente_descr) unless f.empty?
        # filtro utente creatore
        f = filtro.delete(:utente_creazione).to_s
        query = add_like_conditions(query: query, field: :matricola_creatore, pattern: f, extra_field: :utente_creatore_descr) unless f.empty?
        # si puo filtrare anche tramite la colonna variazioni usando gli operatori jsonb come riportato nel commento sotto
        # query = add_like_conditions(query: query, field: Sequel.lit("variazioni::json#>>'{0,utente_descr}'"), extra_field: Sequel.lit("variazioni::json#>>'{0,matricola}'"), pattern: f)
        # filtro created_at
        { da: '>=', a: '<=' }.each do |suffix, oper|
          query = aggiungi_filtro_data(query, filtro.delete("created_at_#{suffix}".to_sym), 'created_at', oper)
        end
        # filtro updated_at
        { da: '>=', a: '<=' }.each do |suffix, oper|
          query = aggiungi_filtro_data(query, filtro.delete("updated_at_#{suffix}".to_sym), 'updated_at', oper)
        end
        # filtro data_ultimo_import
        { da: '>=', a: '<=' }.each do |suffix, oper|
          query = aggiungi_filtro_data(query, filtro.delete("data_ultimo_import_#{suffix}".to_sym), 'data_ultimo_import', oper)
        end
        query
      end

      def grid_etichette # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        query = Db::EtichettaEccezioni
        query = _applica_condizioni_filtro(query: query, filtro: filtro) unless (filtro || {}).empty?
        records_with_export(filtro, 'filename' => 'export_etichette_@FULL_DATE@@ESTENSIONE@', 'export' => filtro['export_format']) do |formatter|
          query.order(:nome).each do |record|
            rec_val = record.values.merge(data_ultimo_import:     timestamp_to_string(record[:data_ultimo_import]),
                                          created_at:             timestamp_to_string(record[:created_at]),
                                          updated_at:             timestamp_to_string(record[:updated_at]),
                                          utente_ultima_modifica: Irma.descrizione_utente_per_gui(matricola: record[:matricola], fullname: record[:utente_descr]),
                                          utente_creazione:       Irma.descrizione_utente_per_gui(matricola: record[:matricola_creatore], fullname: record[:utente_creatore_descr]),
                                          tipo:                   Constant.label(:etichetta_eccezioni, record[:tipo], :tipo).camelize)
            formatter.add_record_values(record, rec_val)
          end
        end
      end

      def attivita_schedulata_export_fu_eccezioni(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        raise 'Sistema non specificato' unless parametri['sistemi']
        raise 'Filtro sul metamodello non specificato' unless parametri['filtro_metamodello']
        lista_id = (parametri['sistema_id'] || parametri['sistemi']).to_s.split(',').map { |sss| [sss.to_i] }
        lista_id = Db::Account.first(id: opts[:account_id]).sistemi_di_competenza_filtrati.map { |x| [x] } if lista_id.empty?
        opts.update(lista_sistemi: lista_id, out_dir_root: DIR_ATTIVITA_TAG, formato: parametri['formato'],
                    # filtro_metamodello: JSON.parse(parametri['filtro_metamodello']),
                    check_ca: parametri['check_export_ca'],
                    np_alberatura: JSON.parse(parametri['np_alberatura']),
                    indice_etichette: (parametri['indice_etichette'] == 'true'),
                    etichette_nette: parametri['eccezioni_nette'].to_i,
                    etichette_eccezioni: parametri['etichette'])
        opts[:filtro_metamodello_file] = scrivi_filtro_mm_file(prefix_nome: 'exportFuEccezioni',
                                                               filtro_mm: parametri['filtro_metamodello'],
                                                               dir: opts[:attivita_schedulata_dir])

        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_EXPORT_FORMATO_UTENTE_PARZIALE_OMC_LOGICO, opts)
      end

      def attivita_schedulata_import_eccezioni(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        raise "Sistema non valido (#{parametri['sistema_id']})" unless (sistema = Db::Sistema.first(id: parametri['sistema_id']))
        flag_radio = parametri['radioFilesEcc']
        raise 'File di import non specificato' unless parametri[flag_radio]
        input_file = post_locfile_to_shared_fs(locfile: parametri[flag_radio], dir: opts[:attivita_schedulata_dir])
        if flag_radio.eql?('deleteEcc')
          opts.update(lista_sistemi: [[sistema.id, input_file]], flag_cancellazione: true)
        else
          raise 'Etichetta non specificata' unless parametri['etichetta']
          opts.update(label_eccezioni: parametri['etichetta'], lista_sistemi: [[sistema.id, input_file]], flag_cancellazione: false)
        end
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_IMPORT_FORMATO_UTENTE_OMC_LOGICO, opts)
      end

      def attivita_schedulata_cancella_eccezioni(parametri, opts = {})
        raise 'Sistema non specificato' unless parametri['sistemi']
        raise 'Indicare almeno un\'etichetta' unless parametri['etichette']
        opts.update(lista_sistemi: parametri['sistemi'].to_s.split(',').map { |sss| [sss.to_i] }, etichette: JSON.parse(parametri['etichette']))
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA, opts)
      end

      def eccezioni_entity_records
        entity_records(klass: Db::Sistema, filtro_id: :sistemi, extra_field: 'Sistema')
      end

      def list_tag_etichette
        res = [{ id: LABEL_NC_DB, descr: d = MSG_SENZA_ETICHETTA, full_descr: d }]
        Db::EtichettaEccezioni.select(:id, :nome, :eccezioni_nette).order(:nome).map do |record|
          res << { id: record[:nome], descr: d = record[:nome], full_descr: d, eccezioni_nette: record[:eccezioni_nette] }
        end
        res
      end

      def salva_etichetta # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        record = filtro.dup.merge(account_id: logged_in.account_id)
        if record[:id]
          handle_request(error_msg_key: :AGGIORNAMENTO_ETICHETTA_FALLITO) do
            etichetta = Db::EtichettaEccezioni.first(id: record[:id])
            raise "Non esiste nessuna etichetta con id '#{record[:id]}'" unless etichetta
            record.delete(:id)
            record.each { |key, value| etichetta[key] = value }
            etichetta.save
            format_msg(:ETICHETTA_AGGIORNATA)
          end
        else
          handle_request(error_msg_key: :INSERIMENTO_ETICHETTA_FALLITO) do
            raise "Etichetta con nome '#{record[:nome]}' già esistente" if Db::EtichettaEccezioni.where(nome: record[:nome]).first
            Db::EtichettaEccezioni.new(record).save
            format_msg(:ETICHETTA_INSERITA)
          end
        end
      end
    end

    App.route('eccezioni') do |r|
      r.post('export_formato_utente_parziale/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_fu_eccezioni(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('import_fu_eccezioni/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_import_eccezioni(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('cancella_eccezioni/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_cancella_eccezioni(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('entity/grid') do
        handle_request { eccezioni_entity_records }
      end
      r.post('etichette/grid') do
        handle_request { grid_etichette }
      end
      r.get('etichette/list') do
        handle_request { list_tag_etichette }
      end
      r.get('etichette/tag') do
        handle_request { list_tag_etichette }
      end
      r.post('etichette/salva') do
        salva_etichetta
      end
      r.post('etichette/elimina') do
        handle_request(error_msg_key: :ELIMINAZIONE_ETICHETTA_FALLITA) do
          id = JSON.parse(request.params['id'] || '[]')
          etichetta = Db::EtichettaEccezioni.first(id: id)
          raise "Non esiste nessuna etichetta con id '#{id}'" unless etichetta
          etichetta.destroy
          format_msg(:ETICHETTA_ELIMINATA)
        end
      end
    end
  end
end
