# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20190709
#
require_relative '../segnalazioni_per_funzione'

module Irma
  #
  module Funzioni
    # # rubocop:disable Metrics/ClassLength
    class ImportCostruttore
      #
      module VerificheImportCostruttore # rubocop:disable Metrics/ModuleLength
        include SegnalazioniPerFunzione
        include ModConfigEnable

        attr_reader :counter_segnalazioni

        config.define SOGLIA_SEGNALAZIONI = :soglia_segnalazioni, 5_000,
                      descr: 'Limite massimo numero segnalazioni per Import Costruttore',
                      widget_info: 'Gui.widget.positiveInteger({minValue:1,maxValue:100000})',
                      profili: PROFILI_PER_PARAMETRO_DI_RPN

        tipo_segnalazione_per_parametro = {}
        Constant.constants(:meta_parametro, :genere).each do |c|
          tipo_segnalazione_per_parametro[c.info[:value]] = [Kernel.const_get("TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_METAMODELLO_META_PARAMETRO_#{c.label.tr(' ', '_')}_MANCANTE"), c.label]
        end
        TIPO_SEGNALAZIONE_PER_PARAMETRO = tipo_segnalazione_per_parametro.freeze

        def initialize(**opts)
          super(**opts)
          @counter_segnalazioni = 0
        end

        # override del metodo config per evitare problemi con l'inclusione del modulo in classi derivate
        CLASSE_PER_CONFIG = self
        def config
          CLASSE_PER_CONFIG.config
        end

        def soglia_segnalazioni
          config[SOGLIA_SEGNALAZIONI].to_i
        end

        def nuova_segnalazione(tipo_segnalazione, opts = {})
          tipo_segnalazione += 1 if @omc_fisico && !TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
          @counter_segnalazioni += 1 unless TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
          super(tipo_segnalazione, opts)
          verifica_soglia_segnalazioni
        end

        def verifica_soglia_segnalazioni
          return if @counter_segnalazioni <= soglia_segnalazioni
          raise "Superata la soglia di #{soglia_segnalazioni} segnalazioni"
        end

        def nuova_segnalazione_validazione(**opts)
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_ERRORE_VALIDAZIONE_XSD, **opts)
        end

        def nuova_segnalazione_validazione_progress(**opts)
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_VALIDAZIONE_XSD, progress: true, **opts)
        end

        def nuova_segnalazione_parametro(tipo_segnalazione, entita, meta_param, opts = {})
          linea_file = entita.info_parametri[meta_param].is_a?(Array) ? entita.info_parametri[meta_param][0] : entita.info_parametri[meta_param]
          ts_opts = { meta_entita: entita.meta_entita, naming_path: entita.naming_path, meta_parametro: meta_param, naming_path_con_id: entita.dist_name_orig, linea_file: linea_file }
          nuova_segnalazione(tipo_segnalazione, ts_opts.merge(opts))
        end

        # ritorna true se l'eventuale nodo associato all'entita e' definito
        # ritorna false se e' associato un nodo mancante (l'entita va scartata)
        def verifica_nodo?(entita, nodo_naming_path: nil, **opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
          entita.nodo = false
          return true unless nodo_naming_path
          return false if import_cache[:entita_scartate][entita.dist_name]
          ok = true
          entita.nodo = nodo_naming_path.include?(entita.naming_path) # nodo_naming_path e' un array
          if entita.nodo # caso entita nodo
            # reset cache
            import_cache[:entita_trovate] = import_cache[:entita_trovate_fino_al_nodo].dup
            ne = import_cache[:nodi_esterni][entita.dist_name]
            if ne
              nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_NODO_SU_ALTRO_SISTEMA,
                                 dist_name: entita.dist_name, riferimento_sistema: ne[:riferimento_sistema], **opts)
              raise "Nodo #{entita.dist_name} associato a #{ne[:riferimento_sistema]}" if opts[:node_exit]
            end
          else
            nodo_np = nodo_naming_path.detect { |np| entita.naming_path.index(np) == 0 }
            return true if nodo_np.nil?
            # caso entita figlia di nodo
            dist_name_nodo = entita.dist_name.split(DIST_NAME_SEP).take(nodo_np.count(NAMING_PATH_SEP) + 1).join(DIST_NAME_SEP)
            nodo_id = import_cache[:entita_trovate_fino_al_nodo][dist_name_nodo]
            if nodo_id
              entita.nodo_id = nodo_id
            else # caso che non dovrebbe mai accadere perche' intercettato prima dalla controllo sulla mancanza dei padri
              ok = false
              # creo una segnalazione solo per la prima volta
              unless import_cache[:entita_scartate][dist_name_nodo]
                import_cache[:entita_scartate][dist_name_nodo] = true
                nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_ENTITA_SCARTATA_PER_MANCANZA_DI_NODO, dist_name: entita.dist_name, **opts)
              end
              # inserisco sempre in entita scartate per scartare poi eventuali figli
              import_cache[:entita_scartate][entita.dist_name] = true
            end
          end
          ok
        end

        def verifica_entita_version(entita:, **opts) # rubocop:disable Metrics/AbcSize
          return if entita.version.nil? || entita.version.empty? || saa.sistema.release_di_nodo.nil?
          return if saa.sistema.release_di_nodo.include?(entita.version)
          return if import_cache[:version_assente].include? entita.version
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_VERSION_ASSENTE, dist_name: entita.dist_name, version: entita.version, **opts)
          import_cache[:version_assente] << entita.version
        end

        def verifica_metamodello?(entita, **opts) # rubocop:disable Metrics/AbcSize
          me = nil
          unless import_cache[:meta_entita_mancante][entita.naming_path] || (me = opts[:metamodello].verifica_entita(entita.naming_path))
            import_cache[:meta_entita_mancante][entita.naming_path] = entita.naming_path
            nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_METAMODELLO_META_ENTITA_MANCANTE,
                               meta_entita: entita.meta_entita, naming_path: entita.naming_path,
                               naming_path_con_id: entita.dist_name_orig, linea_file: entita.linea_file, **opts)
          end
          entita.extra_name = Db::MetaEntita.calcola_extra_name(me_extra_name: me.extra_name, parametri: entita.parametri) if me && me.extra_name
          verifica_parametro(entita, **opts)
          import_cache[:meta_entita_mancante][entita.naming_path] ? false : true
        end

        def verifica_parametro(entita, **opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          # 1.2 controllo su tutti i meta_parametri- la chiave nella cache deve essere naming_path.meta_parametro / naming_path.struttura.meta_parametro
          meta_parametri = opts[:metamodello] && opts[:metamodello].meta_parametri[entita.naming_path]
          return unless entita.parametri
          chiavi_da_rimuovere = []
          entita.parametri.each do |meta_param, valori|
            m_param_to_check = "#{entita.naming_path}.#{meta_param}"

            # puts "m_param_to_check #{m_param_to_check}"
            # 1: controllo che non sia gia' presente nella cache dei parametri mancanti
            if import_cache[:meta_parametro_mancante][m_param_to_check]
              # il parametro e' gia' stato tracciato, se la meta_entita esiste va rimosso dalla lista dei parametri
              chiavi_da_rimuovere << meta_param unless import_cache[:meta_entita_mancante][entita.naming_path]
              next
            end
            # 2: controllo se il parametro esiste nel metamodello
            input_genere_param = ricava_genere_da_valori(meta_param, valori)
            meta_genere_param = meta_parametri ? (mp = meta_parametri[meta_param]) && mp[:genere] : nil
            if meta_genere_param.nil?
              # il parametro non esiste, aggiungo il parametro alla cache dei parametri mancanti e traccio la segnalazione
              import_cache[:meta_parametro_mancante][m_param_to_check] = m_param_to_check
              nuova_segnalazione_parametro(TIPO_SEGNALAZIONE_PER_PARAMETRO[input_genere_param.to_i][0], entita, meta_param, opts)
              # se la meta_entita esiste, va rimosso il meta_parametro dalla lista dei parametri. Salviamo in un array temporaneo e cancelliamo alla fine
              chiavi_da_rimuovere << meta_param unless import_cache[:meta_entita_mancante][entita.naming_path]
              next
            end
            # 3. controllo che il parametro abbia lo stesso genere di quello del metamodello (tornato dal metodo verifica_esistenza_parametro)
            # 3.1 lo strutturato semplice e' un caso particolare di multi strutturato semplice con una singola ripetizione, in questo caso non segnalo nulla
            # 3.2 lo strutturato multivalore e' un caso particolare di multi strutturato mulitvalore con una singola ripetizione, in questo caso non segnalo nulla
            next if meta_genere_param == input_genere_param ||
                    (meta_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE && input_genere_param == META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE) ||
                    (meta_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE && input_genere_param == META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE)
            # 3.3 in caso di formato 3GPP,  parametro semplice e multivalore non hanno differenza di sintassi: il semplice puo' essere un multivalore a singola ripetizione
            if entita.is_a?(TreGpp::ManagedObject) && (
              (meta_genere_param == META_PARAMETRO_GENERE_MULTIVALORE && input_genere_param == META_PARAMETRO_GENERE_SEMPLICE) ||
              (meta_genere_param == META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE && input_genere_param == META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE) ||
              (meta_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE && input_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE))
              # si trasforma il valore semplice in multivalore a singola istanza
              entita.parametri[meta_param] = [valori]
              next
            end
            unless import_cache[:meta_parametro_inconsistente].include?(m_param_to_check)
              # i messaggi sono differenziati sulla base del genere in input mentre i valori dei parametri vengono adattati sulla base del genere del metamodello
              nuova_segnalazione_parametro(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_METAMODELLO_PARAMETRO_INCONSISTENTE, entita, meta_param,
                                           opts.merge(genere_input: TIPO_SEGNALAZIONE_PER_PARAMETRO[input_genere_param.to_i][1].to_s.downcase,
                                                      genere_metamodello: TIPO_SEGNALAZIONE_PER_PARAMETRO[meta_genere_param.to_i][1].to_s.downcase
                                                     )
                                          )
              import_cache[:meta_parametro_inconsistente] << m_param_to_check
            end
            case meta_genere_param
            when META_PARAMETRO_GENERE_SEMPLICE
              # si trasforma il multitvalore in valore singolo sulla prima istanza
              entita.parametri[meta_param] = valori[0] if input_genere_param == META_PARAMETRO_GENERE_MULTIVALORE
            when META_PARAMETRO_GENERE_MULTIVALORE
              # si trasforma il valore semplice in multivalore a singola istanza... da vedere se funziona!!!
              entita.parametri[meta_param] = [valori] if input_genere_param == META_PARAMETRO_GENERE_SEMPLICE
            when META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE
              # in input posso avere [multi] strutturato multivalore o multistrutturato semplice
              entita.parametri[meta_param] = [valori[0]] if input_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE
              entita.parametri[meta_param] = [valori[0][0]] if input_genere_param == META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE ||
                                                               input_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE
            when META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE
              # in input posso avere strutturato semplice, e non faccio nulla, oppure multivalore, multi strutturato o no
              entita.parametri[meta_param] = [valori[0][0]] if input_genere_param == META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE ||
                                                               input_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE
            when META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE
              # in input posso avere strutturato semplice (multi o no) o multi strutturato multivalore
              entita.parametri[meta_param] = [valori] if input_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE || input_genere_param == META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE
              entita_parametri[meta_param] = [valori[0]] if input_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE
            when META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE
              # in input posso avere strutturato multivalore, e non faccio nulla, oppure strutturato semplice, multi strutturato o no
              entita.parametri[meta_param] = [valori] if input_genere_param == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE || input_genere_param == META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE
            end
          end
          entita.rimuovi_parametri(chiavi_da_rimuovere) unless chiavi_da_rimuovere.empty?
        end

        def ricava_genere_da_valori(meta_param, valori)
          return (valori.is_a?(Array) ? META_PARAMETRO_GENERE_MULTIVALORE : META_PARAMETRO_GENERE_SEMPLICE) unless meta_param.index('.')
          return (valori[0].is_a?(Array) ? META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE : META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE) if valori.count == 1
          valori[0].is_a?(Array) ? META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE : META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE
        end

        def entita_duplicata?(entita, **opts) # rubocop:disable Metrics/AbcSize
          if entita.dist_name_valid? && import_cache[:entita_trovate][entita.dist_name]
            # segnalazione se: entita a livello > 1 OPPURE  entita root letta dal file
            entita_root_letta_da_file = (vendor_instance.root_entita(formato_audit).nil? || (vendor_instance.root_entita(formato_audit).dist_name != entita.dist_name))
            if (entita.livello > 1) || entita_root_letta_da_file
              nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_ENTITA_DUPLICATA, dist_name: entita.dist_name_orig, linea_file: entita.linea_file, **opts)
            end
            return true
          end
          false
        end
      end
    end
  end
end
