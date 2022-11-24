# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170425
#

module Irma
  module Web
    module Common
      def attivita_schedulata_export_formato_utente_parziale(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        raise 'Filtro sul metamodello non specificato' unless parametri['filtro_metamodello']
        lista_id = (parametri['sistema_id'] || parametri['sistemi']).to_s.split(',').map { |sss| [sss.to_i] }
        if lista_id.empty?
          account = Db::Account.first(id: opts[:account_id])
          lista_id = (opts[:omc_fisico] ? account.omc_fisici_di_competenza_filtrati : account.sistemi_di_competenza_filtrati).map { |x| [x] }
        end

        opts.update(lista_sistemi: lista_id, out_dir_root: DIR_ATTIVITA_TAG, formato: parametri['formato'],
                    # filtro_metamodello: JSON.parse(parametri['filtro_metamodello']),
                    con_version: (parametri['con_version'] == 'true'))
        opts[:filtro_metamodello_file] = scrivi_filtro_mm_file(prefix_nome: 'exportFu',
                                                               filtro_mm: parametri['filtro_metamodello'],
                                                               dir: opts[:attivita_schedulata_dir])

        Db::TipoAttivita.crea_attivita_schedulata(opts[:omc_fisico] ? TIPO_ATTIVITA_EXPORT_FORMATO_UTENTE_PARZIALE_OMC_FISICO : TIPO_ATTIVITA_EXPORT_FORMATO_UTENTE_PARZIALE_OMC_LOGICO, opts)
      end

      def attivita_schedulata_export_formato_utente(parametri, opts = {})
        lista_id = (parametri['sistema_id'] || parametri['sistemi']).to_s.split(',').map { |sss| [sss.to_i] }
        opts.update(lista_sistemi: lista_id, out_dir_root: DIR_ATTIVITA_TAG, formato: parametri['formato'], con_version: (parametri['con_version'] == 'true'))
        Db::TipoAttivita.crea_attivita_schedulata(opts[:omc_fisico] ? TIPO_ATTIVITA_EXPORT_FORMATO_UTENTE_OMC_FISICO : TIPO_ATTIVITA_EXPORT_FORMATO_UTENTE_OMC_LOGICO, opts)
      end

      def input_file_from_parametri(sistema, parametri, opts = {})
        if parametri['fileLocation'] == 'locale'
          input_file = post_locfile_to_shared_fs(locfile: parametri['importFile'], dir: opts[:attivita_schedulata_dir])
        else
          remote_file = Irma.shared_relative_audit_file(sistema.nome_file_audit)
          begin
            shared_copy_file(remote_file, input_file = Irma.replace_date_tags(File.join(opts[:attivita_schedulata_dir], sistema.nome_file_audit)))
          rescue => e
            raise "Errore di put sul shared_fs server del file di audit #{remote_file}: #{e}"
          end
        end
        input_file
      end

      def attivita_schedulata_import_costruttore(parametri, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: parametri['sistema_id']) : Db::Sistema.first(id: parametri['sistema_id'])
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{parametri['sistema_id']})" unless sistema # TODO: verificare le competenze sui sistemi
        input_file = input_file_from_parametri(sistema, parametri, opts)
        opts.update(lista_sistemi: [[sistema.id, input_file]], out_dir_root: DIR_ATTIVITA_TAG, con_version: (parametri['con_version'] == 'true'), check_data: (parametri['check_data'] == 'true'))
        opts[:formato] = parametri['export'] unless parametri['export'].to_s.empty? || parametri['export'] == FORMATO_EXPORT_ESTESO_NO
        if opts[:omc_fisico]
          Db::TipoAttivita.crea_attivita_schedulata(opts[:formato] ? TIPO_ATTIVITA_IMPORT_COSTR_EXPORT_FU_OMC_FISICO : TIPO_ATTIVITA_IMPORT_COSTRUTTORE_OMC_FISICO, opts)
        else
          Db::TipoAttivita.crea_attivita_schedulata(opts[:formato] ? TIPO_ATTIVITA_IMPORT_COSTR_EXPORT_FU_OMC_LOGICO : TIPO_ATTIVITA_IMPORT_COSTRUTTORE_OMC_LOGICO, opts)
        end
      end

      def attivita_schedulata_import_formato_utente(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        sistema = opts[:omc_fisico] ? Db::OmcFisico.first(id: parametri['sistema_id']) : Db::Sistema.first(id: parametri['sistema_id'])
        raise "#{opts[:omc_fisico] ? 'Omc Fisico' : 'Sistema'} non valido (#{parametri['sistema_id']})" unless sistema # TODO: verificare le competenze sui sistemi
        flag_radio = parametri['radioFiles']
        input_file = post_locfile_to_shared_fs(locfile: parametri[flag_radio], dir: opts[:attivita_schedulata_dir])
        opts.update(lista_sistemi: [[sistema.id, input_file]], flag_cancellazione: flag_radio.eql?('delete'))
        Db::TipoAttivita.crea_attivita_schedulata(opts[:omc_fisico] ? TIPO_ATTIVITA_IMPORT_FORMATO_UTENTE_OMC_FISICO : TIPO_ATTIVITA_IMPORT_FORMATO_UTENTE_OMC_LOGICO, opts)
      end
    end
  end
end
