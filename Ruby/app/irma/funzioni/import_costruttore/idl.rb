# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli, C. Pinali
#
# Creation date: 20151116
#
require 'htmlentities'
require 'digest/md5'
require 'zlib'
require 'irma/idl_util'
require_relative 'verifiche_import_costruttore'

#
module Irma
  #
  module Funzioni
    # # rubocop:disable Metrics/ClassLength
    class ImportCostruttore
      #
      class Idl < self
        include IdlUtil
        include VerificheImportCostruttore

        # -------------------------------------------------------------------------------------------
        def formato_audit_info
          saa.formato_audit_info(formato_audit)
        end

        def con_parser(file:, **opts)
          yield(Parser.new(file, validate_proc: formato_audit_info['validate'] ? method(:validazione_file_audit?) : nil, **opts))
        end

        # # rubocop:disable Metrics/MethodLength
        def analizza_entita_parser(entita_parser:, **opts)
          case entita_parser
          when ManagedObject
            analizza_managed_object_idl(entita_parser, opts)
          when Log
            # il controllo va fatto se abilitato il flag e in caso di controllo negativo l'Import si interrompe
            verifica_data_idl(entita_parser, opts)
          when CmData
            # va verificato <cmData type="actual"> in quanto un valore diverso significa che non e' un file di audit completo e l'import si interrompe
            verifica_cm_data_idl(entita_parser, opts)
          when NilClass
            raise 'Classe IDL non valida'
          end
        end

        # __________________________________________________________________________________________

        def verifica_data_idl(log_idl, hash = {})
          # <log action="create" appInfo="ActualExporter" dateTime="2017-09-25T14:11:21"/>
          # verifica se la data contenuta nel file e' la stessa dalla data odierna
          if hash[:check_data] && Time.parse(log_idl.date_time).strftime(f = '%Y%m%d') != Time.now.strftime(f)
            nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_DATETIME_ERRATO, data_file: log_idl.date_time)
            return ESITO_ANALISI_ENTITA_DATETIME_ERRATO
          end
          ESITO_ANALISI_ENTITA_DA_IGNORARE
        end

        def verifica_cm_data_idl(cmdata_idl, **opts)
          return ESITO_ANALISI_ENTITA_DA_IGNORARE if cmdata_idl.type == 'actual'
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_CMDATA_ERRATO, stringa_type: cmdata_idl.type, **opts)
          ESITO_ANALISI_ENTITA_CMDATA_ERRATO
        end

        def analizza_managed_object_idl(entita, **opts) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          # return ESITO_ANALISI_ENTITA_DIST_NAME_NON_VALIDO unless entita.dist_name_valid?
          unless entita.dist_name_valid?
            nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_IDENTIFICATIVO_ENTITA_NON_VALIDO, meta_entita: entita.meta_entita, naming_path: entita.naming_path, **opts)
            return ESITO_ANALISI_ENTITA_DIST_NAME_NON_VALIDO
          end
          return ESITO_ANALISI_ENTITA_DUPLICATA if entita_duplicata?(entita, **opts)
          return ESITO_ANALISI_ENTITA_METAMODELLO_NON_VALIDO unless opts[:metamodello].nil? || verifica_metamodello?(entita, **opts)
          return ESITO_ANALISI_ENTITA_SENZA_PADRE unless verifica_presenza_padri?(entita, **opts)
          return ESITO_ANALISI_ENTITA_NON_COMPETENTE unless verifica_competenza_base_sistema?(entita, **opts)
          return ESITO_ANALISI_ENTITA_NODO_NON_VALIDO unless verifica_nodo?(entita, **opts)
          verifica_entita_version(entita: entita, **opts)
          ESITO_ANALISI_ENTITA_OK
        end

        def validazione_file_audit?(file)
          return true unless formato_audit_info && formato_audit_info['validate']
          file_idl_valido?(file: file, xsd: formato_audit_info['xsd'].first,
                           nuova_segnalazione_proc: method(:nuova_segnalazione_validazione), nuova_segnalazione_progress_proc: method(:nuova_segnalazione_validazione_progress))
        end

        def verifica_competenza_base_sistema?(entita, **opts)
          return true if vendor_instance.competenza_base_sistema?(entita, saa)
          # inserisco nelle entita scartate e traccio la segnalazione
          import_cache[:entita_scartate][entita.dist_name] = true
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_COMPETENZA_SISTEMA, dist_name: entita.dist_name, linea_file: entita.linea_file, **opts)
          false
        end

        def verifica_presenza_padri?(entita, **opts) # rubocop:disable Metrics/AbcSize
          pid = import_cache[:entita_trovate][entita.dist_name_padre]
          entita.pid = pid if pid
          return true if pid || entita.livello == 1

          # se entita.pid non e' avvalorato, devo creare segnalazione opportuna se non esiste nella hash padre_mancante e la si aggiunge
          unless import_cache[:entita_scartate][entita.dist_name_padre]
            nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_PADRE_NON_TROVATO,
                               naming_path_padre_atteso: entita.dist_name_orig_padre, nome_entita: entita.dist_name_orig,
                               linea_file: entita.linea_file, **opts)
            import_cache[:entita_scartate][entita.dist_name_padre] = true
          end
          # in tutti i casi metto come entita_scartate anche il dist_name di entita per scartare poi i figli
          import_cache[:entita_scartate][entita.dist_name] = true
          false
        end
      end
    end
  end
end
