# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20171019
#
module Irma
  #
  module Web
    # rubocop:disable Metrics/ClassLength
    class App < Roda
      def _ec_opts_import_costruttore(sistema, parametri, opts)
        input_file = input_file_from_parametri(sistema, parametri, opts)
        opts.update(lista_sistemi: [[sistema.id, input_file]], check_data: (parametri['check_data'] == 'true'))
      end

      def _ec_opts_calcolo_pi(parametri, opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        nome_pi = parametri['nome_progetto_irma']
        raise 'Nome Progetto Irma non specificato' if nome_pi.nil? || nome_pi.empty?
        pi = Db::ProgettoIrma.first(nome: nome_pi, account_id: opts[:account_id])
        raise "Progetto Irma '#{pi.nome}' già esistente" if pi
        opts.update(celle_adiacenti: parametri['celle_adiacenti'] == 'true') if parametri['celle_id_prn']
        opts.update(nome:                  nome_pi,
                    nome_progetto_irma:    nome_pi,
                    lista_celle:           parametri['celle_id_prn'] || ALL_PRN_CELLS,
                    tipo_sorgente:         parametri['tipo_sorgente'] || CALCOLO_SORGENTE_OMCLOGICO,
                    # filtro_metamodello_pi: parametri['filtro_metamodello_pi'] ? JSON.parse(parametri['filtro_metamodello_pi']) : {}),
                    sorgente_pi_id:        parametri['sorgente_pi_id'])
        f_mm = scrivi_filtro_mm_file(prefix_nome: 'calcoloPI',
                                     filtro_mm: parametri['filtro_metamodello_pi'],
                                     dir: opts[:attivita_schedulata_dir])
        opts.update(filtro_metamodello_file_pi: f_mm)
        opts.update(no_eccezioni: (parametri['no_eccezioni'] == 'true'))
      end

      def _ec_opts_aggiorna_pi(sistema, parametri, opts)
        flag_radio = parametri['radioFiles']
        input_file_update_pi = post_locfile_to_shared_fs(locfile: parametri[flag_radio], dir: opts[:attivita_schedulata_dir])
        opts.update(lista_sistemi_update_pi: [[sistema.id, input_file_update_pi]])
        if flag_radio.eql?('delete')
          opts.update(flag_cancellazione: true)
        else
          opts.update(flag_cancellazione: false, flag_update: (parametri['solo_update'] == 'true'))
        end
        opts
      end

      def _ec_opts_report_comparativo(sistema, parametri, opts) # rubocop:disable Metrics/AbcSize
        rc = Db::ReportComparativo.first(nome: parametri['nome_report'], account_id: opts[:account_id])
        raise "Report Comparativo con nome '#{rc.nome}' già esistente" if rc
        opts.update(nome_report: parametri['nome_report'], flag_presente: (parametri['includi_entita_uguali'] == 'true'))
        # fonte_2 per comparativo: il PI creato dal calcolo (step precedente)
        opts.update(archivio_2: 'pi', origine_2: 'pi_nome') # , valore_2: opts[:nome_progetto_irma])
        # fonte_1 per comparativo: la sorgente utilizzata per il calcolo (step precedente)
        archivio1, origine1, valore1 = case opts[:tipo_sorgente]
                                       when CALCOLO_SORGENTE_OMCLOGICO.to_s
                                         [ARCHIVIO_RETE, 'sistema_id', sistema.id]
                                       when CALCOLO_SORGENTE_OMCFISICO.to_s
                                         [ARCHIVIO_RETE, 'omc_fisico_id', sistema.omc_fisico_id]
                                       else
                                         ['pi', 'pi_id', opts[:sorgente_pi_id]]
                                       end
        opts.update(archivio_1: archivio1, origine_1: origine1, valore_1: valore1)
      end

      def _ec_opts_visualizza_rc(parametri, opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        opts.update(cc_mode:                 (parametri['cc_mode'] == 'true'),
                    # filtro_metamodello_rc:   parametri['filtro_metamodello_rc'] ? JSON.parse(parametri['filtro_metamodello_rc']) : {},
                    solo_calcolabili:        (parametri['me_progettazione'] == 'true'),
                    solo_prioritari:         (parametri['solo_prioritari'] == 'true'),
                    con_version:             (parametri['con_version'] == 'true'),
                    only_to_export_param:    (parametri['only_to_export_param'] == 'true'),
                    dist_assente_vuoto:      (parametri['dist_assente_vuoto'] == 'true'),
                    nascondi_assente_f1:     (parametri['nascondi_f1'] == 'true'),
                    nascondi_assente_f2:     (parametri['nascondi_f2'] == 'true'),
                    con_version_fu:          (parametri['con_version_fu'] == 'true'),
                    only_to_export_param_fu: (parametri['only_to_export_param_fu'] == 'true'),
                    dist_assente_vuoto_fu:   (parametri['dist_assente_vuoto_fu'] == 'true'),
                    nascondi_assente_f1_fu:  (parametri['nascondi_f1_fu'] == 'true'),
                    nascondi_assente_f2_fu:  (parametri['nascondi_f2_fu'] == 'true'),
                    formato_fu:              (parametri['formato']),
                    filtro_version:          (parametri['filtro_version'] || ''),
                    export_parziale_fu:      (parametri['check_export_fu'] == 'on'),
                    export_totale:           (parametri['check_export'] == 'on'),
                    #
                    conteggio_alberature:    (parametri['check_export_ca'] == 'on'),
                    np_alberatura:           JSON.parse(parametri['np_alberatura']),
                    genera_file_filtro:      (parametri['genera_filtro_alberatura'] == 'true'),
                    con_version_ca:          (parametri['con_version_ca'] == 'true'),
                    only_to_export_param_ca: (parametri['only_to_export_param_ca'] == 'true'),
                    dist_assente_vuoto_ca:   (parametri['dist_assente_vuoto_ca'] == 'true'),
                    nascondi_assente_f1_ca:  (parametri['nascondi_f1_ca'] == 'true'),
                    nascondi_assente_f2_ca:  (parametri['nascondi_f2_ca'] == 'true'))
        f_mm = scrivi_filtro_mm_file(prefix_nome: 'visualizzaRC',
                                     filtro_mm: parametri['filtro_metamodello_rc'],
                                     dir: opts[:attivita_schedulata_dir])
        opts.update(filtro_metamodello_file_rc: f_mm)
      end

      def attivita_schedulata_esecuzione_report_calcolo_pi_da_prn(parametri, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        sistema_id = parametri['sistema_id']
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non specificato" if sistema_id.nil? || sistema_id.empty?
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: sistema_id) : Db::Sistema.first(id: sistema_id)
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{sistema_id})" unless sistema
        opts.update(lista_sistemi: [[sistema.id]], out_dir_root: DIR_ATTIVITA_TAG, archivio: ARCHIVIO_RETE)
        opts.update(aggiorna_pi: (parametri['check_aggiorna_PI_da_file'] == 'true'))
        opts.update(import_costruttore: (parametri['check_opzioni_IC'] == 'on'))
        opts.update(periodo: parametri['periodo'].to_s)
        # import costruttore
        opts = _ec_opts_import_costruttore(sistema, parametri, opts) if parametri['check_opzioni_IC'] == 'on'
        # calcolo pi
        opts = _ec_opts_calcolo_pi(parametri, opts)
        # aggiorna pi
        opts = _ec_opts_aggiorna_pi(sistema, parametri, opts) if parametri['check_aggiorna_PI_da_file'] == 'true'
        # report comparativo
        opts = _ec_opts_report_comparativo(sistema, parametri, opts)
        # export RC
        opts = _ec_opts_visualizza_rc(parametri, opts)
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_REPORT_CALCOLO_PI_DA_PRN_OMC_LOGICO, opts)
      end

      def attivita_schedulata_esecuzione_consistency_check(parametri, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        sistema_id = parametri['sistema_id']
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non specificato" if sistema_id.nil? || sistema_id.empty?
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: sistema_id) : Db::Sistema.first(id: sistema_id)
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{sistema_id})" unless sistema
        opts.update(lista_sistemi:           [[sistema.id]],
                    out_dir_root:            DIR_ATTIVITA_TAG,
                    nome_progetto_irma:      parametri['nome_pi'],
                    nome_report_comparativo: parametri['nome_rc'],
                    archivio:                ARCHIVIO_RETE,
                    periodo:                 parametri['periodo'].to_s,
                    account_id:              opts[:account_id])
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_CONSISTENCY_CHECK, opts)
      end
    end

    App.route('esecuzioni_composte') do |r|
      r.post('report_calcolo_pi_da_prn/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_esecuzione_report_calcolo_pi_da_prn(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('consistency_check/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_esecuzione_consistency_check(parametri, opzioni_attivita_schedulata)
        end
      end
    end
  end
end
