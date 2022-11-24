# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170425
#

module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def _attivita_schedulata_pi_export_formato_utente(parametri, opts = {})
        lista_id = (parametri['lista_progetti_irma']).to_s.split(',').map { |sss| [sss.to_i] }
        opts.update(lista_pi: lista_id, out_dir_root: DIR_ATTIVITA_TAG, formato: parametri['formato'], con_version: (parametri['con_version'] == 'true'))
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_PI_EXPORT_FORMATO_UTENTE, opts)
      end

      def _attivita_schedulata_pi_export_formato_utente_parziale(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        raise 'Filtro sul metamodello non specificato' unless parametri['filtro_metamodello']
        lista_id = (parametri['lista_progetti_irma']).to_s.split(',').map { |sss| [sss.to_i] }
        f_mm = scrivi_filtro_mm_file(prefix_nome: 'pi_exportFu',
                                     filtro_mm: parametri['filtro_metamodello'],
                                     dir: opts[:attivita_schedulata_dir])
        opts.update(lista_pi: lista_id, out_dir_root: DIR_ATTIVITA_TAG, formato: parametri['formato'],
                    # filtro_metamodello: JSON.parse(parametri['filtro_metamodello']),
                    filtro_metamodello_file: f_mm,
                    con_version: (parametri['con_version'] == 'true'))
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_PI_EXPORT_FORMATO_UTENTE_PARZIALE, opts)
      end

      def _attivita_schedulata_calcolo_pi(parametri, opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        # sistema/omc_fisico_id
        sistema_id = parametri['sistema_id']
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non specificato" if sistema_id.nil? || sistema_id.empty?
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: sistema_id) : Db::Sistema.first(id: sistema_id)
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{sistema_id})" unless sistema # TODO: verificare le competenze sui sistemi
        # nome_progetto_irma:
        nome_pi = parametri['nome_progetto_irma']
        raise 'Nome Progetto Irma non specificato' if nome_pi.nil? || nome_pi.empty?
        pi = Db::ProgettoIrma.first(nome: nome_pi, account_id: opts[:account_id])
        raise "Progetto Irma '#{pi.nome}' già esistente" if pi

        # opts comuni
        opts.update(archivio: ARCHIVIO_RETE, nome: nome_pi, nome_progetto_irma: nome_pi) # TODO: verificare la duplicazione

        # file_pi_import_fu:
        locfile = parametri['formatoUtente']
        input_file = locfile && !locfile.empty? ? post_locfile_to_shared_fs(locfile: locfile, dir: opts[:attivita_schedulata_dir]) : nil

        celle = parametri['celle_id'] unless parametri['celle_id'].nil? || parametri['celle_id'].empty?
        if celle
          opts.update(lista_celle: celle, omc_id: sistema.id, celle_adiacenti: parametri['celle_adiacenti'] == 'true')
          opts.update(no_eccezioni: (parametri['no_eccezioni'] == 'true'))
        end
        opts.update(flag_update: (parametri['solo_update'] == 'true'), lista_sistemi: [[sistema.id, input_file]], out_dir_root: DIR_ATTIVITA_TAG) if input_file
        opts.update(tipo_sorgente: parametri['tipo_sorgente'] || CALCOLO_SORGENTE_OMCLOGICO)
        unless (parametri['filtro_metamodello'] || '').empty?
          f_mm = scrivi_filtro_mm_file(prefix_nome: 'pi_importFu',
                                       filtro_mm: parametri['filtro_metamodello'],
                                       dir: opts[:attivita_schedulata_dir])
          opts.update(filtro_metamodello_file: f_mm)
          # opts.update(filtro_metamodello: JSON.parse(parametri['filtro_metamodello']))
        end
        opts.update(sorgente_pi_id: parametri['sorgente_pi_id'])

        #--------------------------------------------------------------------------------
        # calcolo + importFU
        if celle && input_file
          # FUTURE: al momento non viene gestita l'opzione :omc_fisico
          return Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_CALCOLO_PI_IMPORT_FU_OMC_LOGICO, opts)
        end
        # solo calcolo
        return Db::TipoAttivita.crea_attivita_schedulata(opts[:omc_fisico] ? TIPO_ATTIVITA_CALCOLO_PI_OMC_FISICO : TIPO_ATTIVITA_CALCOLO_PI_OMC_LOGICO, opts) if celle
        # solo import
        return Db::TipoAttivita.crea_attivita_schedulata(opts[:omc_fisico] ? TIPO_ATTIVITA_PI_IMPORT_FORMATO_UTENTE_OMC_FISICO : TIPO_ATTIVITA_PI_IMPORT_FORMATO_UTENTE_OMC_LOGICO, opts) if input_file
        raise 'Selezione Celle o Input File non specificati'
      end

      def _attivita_schedulata_aggiorna_calcolo_pi(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        pi = Db::ProgettoIrma.first(id: parametri['pi_id'])
        raise "Progetto Irma non valido (#{parametri['pi_id']})" unless pi
        # sistema/omc_fisico_id
        sistema_id = pi[:omc_fisico_id] ? pi.parametri_input['sistema_id'] : pi.sistema_id
        sistema = Db::Sistema.first(id: sistema_id)
        raise "Sistema non valido #{sistema_id}" unless sistema # TODO: verificare le competenze sui sistemi
        flag_radio = parametri['radioFiles']
        input_file = post_locfile_to_shared_fs(locfile: parametri[flag_radio], dir: opts[:attivita_schedulata_dir])
        opts.update(nome_progetto_irma: pi.nome, archivio: pi.archivio, lista_sistemi: [[sistema.id, input_file]], out_dir_root: DIR_ATTIVITA_TAG)
        if flag_radio.eql?('delete')
          opts.update(flag_cancellazione: true)
        else
          opts.update(flag_cancellazione: false, flag_update: (parametri['solo_update'] == 'true'))
        end
        Db::TipoAttivita.crea_attivita_schedulata(opts[:omc_fisico] ? TIPO_ATTIVITA_PI_IMPORT_FORMATO_UTENTE_OMC_FISICO : TIPO_ATTIVITA_PI_IMPORT_FORMATO_UTENTE_OMC_LOGICO, opts)
      end

      def _attivita_schedulata_pi_copia(parametri, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(parametri['filtro'] || '{}').symbolize_keys
        query = []
        query = Db::ProgettoIrma.where(nome: filtro[:nome_copia_pi]) if filtro[:nome_copia_pi]
        raise "Esiste già un Progetto Irma con nome: #{filtro[:nome_copia_pi]}" unless query.empty?
        pi_to_copy = Db::ProgettoIrma.get_by_pk(filtro[:hidden_pi_id]) if filtro[:hidden_pi_id]
        raise 'Non è possibile recuperare il Progetto Irma selezionato per la copia.' unless pi_to_copy
        omc_id = pi_to_copy.omc_fisico_id ? pi_to_copy.omc_fisico_id : pi_to_copy.sistema_id
        opts.update(nome_progetto_irma: filtro[:nome_copia_pi], id_pi_sorgente: filtro[:hidden_pi_id], nome_pi_src: pi_to_copy.nome, archivio: pi_to_copy.archivio, omc_id: omc_id,
                    omc_fisico: pi_to_copy.omc_fisico_id ? true : false)
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_CALCOLO_PI_COPIA, opts)
      end

      def _aggiungi_info_list_pi(query) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        query.reverse_order(:updated_at).map do |record|
          begin
            omc_fisico_id = record[:omc_fisico_id]
            sistema_id = record[:sistema_id]
            sof = sistema_o_omc_fisico(record)
            vrid, sistemi, vr_klass, vr_rc = if omc_fisico_id
                                               vr_rc = Db::Sistema.get_by_pk(record[:parametri_input]['sistema_id']).vendor_release_id
                                               of = Db::OmcFisico.get_by_pk(omc_fisico_id)
                                               [of.vendor_release_fisico_id, of.sistemi.map { |s| s[:id] }, Db::VendorReleaseFisico, vr_rc]
                                             else
                                               v_id = Db::Sistema.get_by_pk(sistema_id).vendor_release_id
                                               [v_id, [sistema_id], Db::VendorRelease, v_id]
                                             end
            vr = { id: vrid, descr: vr_klass.get_by_pk(vrid).descr }
            vr_filtro_rc = { vr_id: vr_rc, vr_descr: Db::VendorRelease.get_by_pk(vr_rc).descr }
          rescue => e
            Irma.logger.warn("Errore nel reperire informazioni per il ProgettoIrma #{record[:nome]} che verra' ignorato, eccezione: #{e}")
            next
          end
          {
            created_at:     timestamp_to_string(record[:created_at]),
            updated_at:     ts = timestamp_to_string(record[:updated_at]),
            id:             record[:id],
            label:          sof.is_a?(Db::Sistema) ? 'Sistema' : 'Omc Fisico',
            nome:           record[:nome],
            descr:          "#{record[:nome]} (#{record[:count_entita]} records, ultimo aggiornamento il #{ts})",
            count_entita:   record[:count_entita],
            full_descr:     sof ? sof.full_descr : '',
            sorgente_descr: "#{record[:nome]} (aggiornato il #{ts})",
            omc_logico_id:  sistema_id,
            omc_fisico_id:  omc_fisico_id,
            vendor_release: vr,
            sistemi:        sistemi,
            vr_filtro_rc:   vr_filtro_rc
          }
        end.compact
      end

      def list_pi # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        sessione = logged_in

        query = if filtro[:id_omc_fisico]
                  Db::ProgettoIrma.where(omc_fisico_id: filtro[:id_omc_fisico])
                elsif filtro[:id_sistema]
                  Db::ProgettoIrma.where(sistema_id: filtro[:id_sistema])
                else
                  sdcf = id_sistemi_di_competenza_filtrati
                  ofdcf = id_omc_fisici_di_competenza_filtrati
                  Db::ProgettoIrma.where(Sequel.or(sistema_id: sdcf) | Sequel.or(omc_fisico_id: ofdcf))
                end

        query = query.where(ambiente: filtro[:ambiente]) if filtro[:ambiente] && (!filtro[:ambiente].eql? format_msg(:STORE_TUTTI_GLI_AMBIENTI))

        query = if filtro[:visualizza] && filtro[:matricola]
                  applica_filtro_tipo_account_matricola(query, filtro[:visualizza], filtro[:matricola])
                else
                  query.where(account_id: sessione.account_id)
                end
        _aggiungi_info_list_pi(query)
      end

      def list_pi_solo_sistemi # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        sessione = logged_in
        query = Db::ProgettoIrma.where("(parametri_input::jsonb ->> 'sistema_id' = '#{filtro[:sistema_id]}')")
        query = query.where(account_id: sessione.account_id)
        query = query.where(ambiente: filtro[:ambiente]) if filtro[:ambiente] && (!filtro[:ambiente].eql? format_msg(:STORE_TUTTI_GLI_AMBIENTI))
        _aggiungi_info_list_pi(query)
      end

      def grid_pi_entity_records # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        filtro_sof = filtro[:omc_fisici] || []
        pi = (pi_id = filtro[:pi_id]) && Db::ProgettoIrma.first(id: pi_id)
        raise "Nessun sistema/omc_fisico trovato con filtro '#{pi_id}'" unless pi
        sof = if filtro_sof.empty?
                filtro_sof = filtro[:sistemi] || []
                raise 'Nessun sistema o omc_fisico specificato' if filtro_sof.empty?
                Db::Sistema.get_by_pk(filtro_sof)
              else
                Db::OmcFisico.get_by_pk(filtro_sof)
              end
        raise "Nessun sistema/omc_fisico trovato con filtro #{filtro_sof} (omc_fisici: #{filtro[:omc_fisici]}, sistemi: #{filtro[:sistemi]})" unless sof

        entity_records(klass: sof.class, filtro_id: (sof.is_a?(Db::Sistema) ? :sistemi : :omc_fisici), extra_field: nil, entita: pi.entita)
      end

      def grid_pi # rubocop:disable Metrics/AbcSize
        sessione = logged_in
        query = Db::ProgettoIrma.where(account_id: sessione.account_id)
        query.where(Sequel.or(sistema_id: filtro_sistemi) | Sequel.or(omc_fisico_id: filtro_omc_fisico)).reverse_order(:id).map do |record|
          sistema = record.sistema_id ? Db::Sistema.get_by_pk(record[:sistema_id]) : Db::OmcFisico.get_by_pk(record[:omc_fisico_id])
          record.values.merge(
            sistema:    sistema.full_descr,
            updated_at: timestamp_to_string(record[:updated_at]),
            created_at: timestamp_to_string(record[:created_at])
          )
        end
      end

      def grid_pi_competenze_entita # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys

        query = Db::ProgettoIrma

        query = if filtro[:visualizza] || filtro[:matricola]
                  applica_filtro_tipo_account_matricola(query, filtro[:visualizza], filtro[:matricola])
                else
                  sessione = logged_in
                  query.where(account_id: sessione.account_id)
                end

        cond = []
        cond << "updated_at >= '#{Time.at(filtro[:data_filter_da] / 1000)}'" if filtro[:data_filter_da]
        cond << "updated_at <= '#{Time.at(filtro[:data_filter_a] / 1000)}'" if filtro[:data_filter_a]
        query = query.where(cond.join(' AND ')) unless cond.empty?

        query = query.where { count_entita > 0 }

        query = if filtro[:sof] && (filtro[:sof]['sistema_id'] || filtro[:sof]['omc_fisico_id'])
                  filtro[:sof]['sistema_id'] ? query.where(sistema_id: filtro[:sof]['sistema_id']) : query.where(omc_fisico_id: filtro[:sof]['omc_fisico_id'])
                else
                  query.where(Sequel.or(sistema_id: filtro_sistemi) | Sequel.or(omc_fisico_id: filtro_omc_fisico))
                end

        query.reverse_order(:id).map do |record|
          sistema = record.sistema_id ? Db::Sistema.get_by_pk(record[:sistema_id]) : Db::OmcFisico.get_by_pk(record[:omc_fisico_id])
          user = Db::Utente.get_by_pk(Db::Account.get_by_pk(record[:account_id]).utente_id)
          profile = Db::Profilo.get_by_pk(Db::Account.get_by_pk(record[:account_id]).profilo_id)
          record.values.merge(
            sistema:    sistema.full_descr,
            updated_at: timestamp_to_string(record[:updated_at]),
            created_at: timestamp_to_string(record[:created_at]),
            utente:     "[#{user[:matricola]}] #{user[:nome]} #{user[:cognome]}",
            profilo:    profile.nome
          )
        end
      end
    end

    App.route('progetti_irma') do |r|
      r.post('aggiorna_calcolo_per_omc_logico/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          _attivita_schedulata_aggiorna_calcolo_pi(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('aggiorna_calcolo_per_omc_fisico/schedula') do # NOGUI: PREVISTO MA NON USATO NELLA GUI
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          _attivita_schedulata_aggiorna_calcolo_pi(parametri, opzioni_attivita_schedulata.merge(omc_fisico: true))
        end
      end
      r.post('calcolo_per_omc_logico/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          _attivita_schedulata_calcolo_pi(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('calcolo_per_omc_fisico/schedula') do # NOGUI: PREVISTO MA NON USATO NELLA GUI
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          _attivita_schedulata_calcolo_pi(parametri, opzioni_attivita_schedulata.merge(omc_fisico: true))
        end
      end
      r.post('elimina') do
        handle_request(error_msg_key: :ELIMINAZIONE_PROGETTO_IRMA_FALLITA) do
          selected_ids = JSON.parse(request.params['id_progetti_selezionati'] || '[]')
          n = 0
          Db::ProgettoIrma.where(id: selected_ids).each do |pi|
            pi.entita.con_lock(mode: LOCK_MODE_WRITE) do |_locks|
              pi.destroy
              n += 1
            end
          end
          format_msg(n == 1 ? :PROGETTO_IRMA_ELIMINATO : :PROGETTI_IRMA_ELIMINATI, n: n)
        end
      end
      r.post('entity/grid') do
        handle_request { grid_pi_entity_records }
      end
      r.post('export_formato_utente/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          _attivita_schedulata_pi_export_formato_utente(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('export_formato_utente_parziale/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          _attivita_schedulata_pi_export_formato_utente_parziale(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('grid') do
        handle_request { grid_pi }
      end
      r.get('list') do
        handle_request { list_pi }
      end
      r.get('sistemi/list') do
        handle_request { list_pi_solo_sistemi }
      end
      r.post('column_filter/grid') do
        handle_request { grid_column_filter }
      end
      r.post('competenze_entita/grid') do
        handle_request { grid_pi_competenze_entita }
      end
      r.post('copia/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          _attivita_schedulata_pi_copia(parametri, opzioni_attivita_schedulata)
        end
      end
    end
  end
end
