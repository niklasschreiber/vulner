# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151116
#
require 'irma/cache'
require_relative 'segnalazioni_per_funzione'

module Irma
  #
  module Funzioni
    # rubocop:disable Metrics/ModuleLength
    module RelazioniAdj
      # rubocop:disable Metrics/BlockNesting
      def cancella_relazioni_adj_da_sorgente(entita_sorgente:, **opts)  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        saa = opts[:saa]
        vendor_instance = opts[:vendor_instance]
        dataset = opts[:dataset]
        flag_cell_adj = opts[:flag_cell_adj]
        esegui_delete = opts[:esegui_delete].nil? ? true : opts[:esegui_delete]

        entita_sorgente.elabora_dist_name
        db_query_relations = dataset.where('1 = 2')

        if flag_cell_adj == Vendor::NO_FLAG
          return esegui_delete ? 0 : []
        end

        # date le entita' sorgenti (lista celle o lista adiacenti esterne) cancella gli oggetti relazione in cui compare la sorgente come adiacenza
        # a seconda del vendor/rete ho comportamenti differenti...
        case saa.vendor_id
        when VENDOR_NOKIA
          # vendor Nokia: nel campo entita.cella_adiacente della relazione di adiacenza ho il dist_name della sorgente
          if [Vendor::FLAG_CELL, Vendor::FLAG_ADJ_EXT].include?(flag_cell_adj)
            db_query_relations = dataset.where(cella_adiacente: entita_sorgente.dist_name)
          end
          if [Vendor::FLAG_CELL_PARENT, Vendor::FLAG_ADJ_EXT_PARENT].include?(flag_cell_adj)
            db_query_relations = dataset.where(Sequel.like(:cella_adiacente, "#{entita_sorgente.dist_name}#{DIST_NAME_SEP}%"))
          end
        when VENDOR_ERICSSON
          if [RETE_UMTS, RETE_LTE].include?(saa.rete_id) || saa.rete_id.nil?
            # vendor Ericsson UMTS e LTE: nel campo cella_adiacente ho lo stesso valore_entita della cella sorgente
            case flag_cell_adj
            when Vendor::FLAG_CELL
              me_rel_adj = (saa.rete_id ? vendor_instance.meta_entita_relazioni_adiacenza[saa.rete_id].keys : vendor_instance.meta_entita_relazioni_adiacenza.map { |_r, l_adj| l_adj.keys }.flatten)
              db_query_relations = dataset.where(naming_path: me_rel_adj, cella_adiacente: entita_sorgente.valore_entita)
            when Vendor::FLAG_ADJ_EXT
              rete = vendor_instance.get_rete_from_meta_entita_adj(entita_sorgente.naming_path)
              db_query_relations = dataset.where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete].keys, cella_adiacente: entita_sorgente.valore_entita)
            when Vendor::FLAG_CELL_PARENT
              np_cella = (saa.rete_id ? Vendor::Ericsson.default_cella_naming_path_rete[saa.rete_id] : Vendor::Ericsson.default_cella_naming_path_rete.values)
              db_cells = dataset.select(:valore_entita).where(Sequel.like(:dist_name, "#{entita_sorgente.dist_name}#{DIST_NAME_SEP}%")).where(naming_path: np_cella).all
              lista_valori = db_cells.map { |rec| rec[:valore_entita] }
              me_rel_adj = (saa.rete_id ? vendor_instance.meta_entita_relazioni_adiacenza[saa.rete_id].keys : vendor_instance.meta_entita_relazioni_adiacenza.map { |_r, l_adj| l_adj.keys }.flatten)
              db_query_relations = dataset.where(naming_path: me_rel_adj, cella_adiacente: lista_valori)
            when Vendor::FLAG_ADJ_EXT_PARENT
              db_adj = dataset.select(:naming_path, :valore_entita)
                              .where(Sequel.like(:dist_name, "#{entita_sorgente.dist_name}#{DIST_NAME_SEP}%"))
                              .where(naming_path: vendor_instance.meta_entita_adiacenza.values.flatten).all
              db_adj.each do |rec|
                rete = vendor_instance.get_rete_from_meta_entita_adj(rec[:naming_path])
                db_query_relations = dataset.where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete].keys, cella_adiacente: rec[:valore_entita])
              end
            end
            # TODO: elsif saa_rete_ID == RETE_GSM
          end
        when VENDOR_HUAWEI
          # vendor Huawei: identifico la prima parte di dist_name fino all'entita Radio, che e' prefisso per tutte le query
          # in caso di OmcFisico cerco di determinare la rete dell'entita sorgente
          rete_sorgente = (saa.is_a?(Db::OmcFisicoAmbienteArchivio) ? vendor_instance.get_rete_from_np(entita_sorgente.naming_path) : saa.rete_id)
          return (esegui_delete ? 0 : []) unless rete_sorgente
          me_radio = Vendor.instance(vendor: vendor_instance.vendor, rete: rete_sorgente).meta_entita_radio
          idx_r = entita_sorgente.dist_name.index(me_radio)
          path_radio = entita_sorgente.dist_name[0, entita_sorgente.dist_name.index(DIST_NAME_SEP, idx_r)] unless entita_sorgente.dist_name.end_with?(me_radio) || idx_r.nil?
          path_radio = entita_sorgente.dist_name if entita_sorgente.dist_name.end_with?(me_radio)
          rete_adj = (flag_cell_adj == Vendor::FLAG_ADJ_EXT) ? vendor_instance.get_rete_from_meta_entita_adj(entita_sorgente.naming_path) : 0
          if rete_sorgente == RETE_GSM
            # - nel caso cella o adiacente ho valore_entita, devo agganciare il pezzo di dist_name fino a Radio + meta_entita_cella/meta_entita_adiacente
            # - nel caso di padre di cella o adiacente GSM, devo recuperare i valori delle entita figlie altrimenti non riesco
            case flag_cell_adj
            when Vendor::FLAG_CELL
              db_query_relations = dataset.where(Sequel.like(:dist_name, "#{path_radio}#{DIST_NAME_SEP}%"))
                                          .where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete_sorgente].keys, cella_adiacente: entita_sorgente.valore_entita)
            when Vendor::FLAG_ADJ_EXT
              db_query_relations = dataset.where(Sequel.like(:dist_name, "#{path_radio}#{DIST_NAME_SEP}%"))
                                          .where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete_adj].keys, cella_adiacente: entita_sorgente.valore_entita)
            when Vendor::FLAG_CELL_PARENT
              db_cells = dataset.select(:valore_entita).where(Sequel.like(:dist_name, "#{entita_sorgente.dist_name}#{DIST_NAME_SEP}%"))
                                .where(naming_path: Vendor::Huawei.default_cella_naming_path_rete[RETE_GSM]).all
              lista_valori = db_cells.map { |rec| rec[:valore_entita] }
              db_query_relations = dataset.where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete_sorgente].keys, cella_adiacente: lista_valori)
            end
            # in tutti gli altri casi di flag (flag_adj_ext_parent e flag_generic_parent) la cancellazione avviene automaticamente dalla cancellazione del padre
          elsif rete_sorgente == RETE_UMTS
            # devo prelevare i parametri dall'oggetto
            case flag_cell_adj
            when Vendor::FLAG_CELL
              db_query_relations = dataset.where(Sequel.like(:dist_name, "#{path_radio}#{DIST_NAME_SEP}%"))
                                          .where(Sequel.like(:cella_adiacente, "#{entita_sorgente.valore_entita}+%"))
                                          .where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete_sorgente].keys)
              # TODO: l'oggetto CELL non ha il parametro RNCID
            when Vendor::FLAG_ADJ_EXT
              db_cells = dataset.select(:parametri).where(dist_name: entita_sorgente.dist_name).all
              lista_valori = db_cells.map { |rec| [rec[:parametri]['CELLID'], rec[:parametri]['NRNCID']].join('+') } if rete_adj == RETE_UMTS
              lista_valori = db_cells.map { |rec| rec[:parametri]['GSMCELLINDEX'] } if rete_adj == RETE_GSM
              lista_valori = db_cells.map { |rec| rec[:parametri]['LTECELLINDEX'] } if rete_adj == RETE_LTE
              db_query_relations = dataset.where(Sequel.like(:dist_name, "#{path_radio}#{DIST_NAME_SEP}%"))
                                          .where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete_adj].keys, cella_adiacente: lista_valori)
            when Vendor::FLAG_CELL_PARENT
              # TODO: l'oggetto CELL non ha il parametro RNCID
              db_cells = dataset.select(:valore_entita)
                                .where(Sequel.like(:dist_name, "#{entita_sorgente.dist_name}#{DIST_NAME_SEP}%"))
                                .where(naming_path: Vendor::Huawei.default_cella_naming_path_rete[RETE_UMTS]).all
              lista_valori = db_cells.map { |rec| "#{rec[:valore_entita]}+%" }.join
              db_query_relations = dataset.where(Sequel.like(:dist_name, "#{path_radio}#{DIST_NAME_SEP}%"))
                                          .where(Sequel.like(:cella_adiacente, lista_valori))
                                          .where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete_sorgente].keys)
            when Vendor::FLAG_ADJ_EXT_PARENT # ha senso solo per le U2U che sono figlie di UNRNC, le altre adiacenti esterne sono figlie dell'oggetto Radio
              db_cells = dataset.select(:parametri).where(Sequel.like(:dist_name, "#{entita_sorgente.dist_name}#{DIST_NAME_SEP}%"))
                                .where(naming_path: vendor_instance.meta_entita_adiacenza.values.flatten).all
              lista_valori = db_cells.map { |rec| [rec[:parametri]['CELLID'], rec[:parametri]['NRNCID'], rec[:parametri]['GSMCELLINDEX'], rec[:parametri]['LTECELLINDEX']].compact.join('+') }
              db_query_relations = dataset.where(Sequel.like(:dist_name, "#{path_radio}#{DIST_NAME_SEP}%"))
                                          .where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza.map { |_r, v|  v.keys }.flatten, cella_adiacente: lista_valori)
            end
            # in caso di flag_generic_parent, la cancellazione del parent cancella tutte le celle/adiacenze e le relative relazioni
          elsif rete_sorgente == RETE_LTE
            # il valore_entita dell'adiacente esterna o cella corrisponde al campo cella_adiacente della relazione
            case flag_cell_adj
            when Vendor::FLAG_CELL
              # prelevo il parametro NEIGHBOURCELLNAME e CELLID dalla cella
              db_params = dataset.select(:parametri).where(dist_name: entita_sorgente.dist_name).first
              if db_params
                lista_valori = "#{db_params[:parametri]['CELLNAME']}+#{db_params[:parametri]['CELLID']}"
                db_query_relations = dataset.where(Sequel.like(:dist_name, "#{path_radio}#{DIST_NAME_SEP}%"))
                                            .where(Sequel.like(:cella_adiacente, "#{lista_valori}+%"))
                                            .where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete_sorgente].keys)
              end
            when Vendor::FLAG_ADJ_EXT
              db_query_relations = dataset.where(Sequel.like(:dist_name, "#{path_radio}#{DIST_NAME_SEP}%"))
                                          .where(naming_path: vendor_instance.meta_entita_relazioni_adiacenza[rete_adj].keys, cella_adiacente: entita_sorgente.valore_entita)
            end
            # nei casi di cancellazione di un parent, cancello in automatico tutte le celle/adiacenze e relative relazioni
          end
        end
        esegui_delete ? db_query_relations.delete : db_query_relations.order(:dist_name).select_map([:dist_name, :naming_path, :version])
      end
    end

    # rubocop:disable Metrics/ClassLength
    class ImportFormatoUtente
      include SegnalazioniPerFunzione
      include RelazioniAdj

      attr_reader :logger, :sistema_ambiente_archivio, :metamodello, :log_prefix, :vendor_instance, :saa_riferimento
      attr_reader :solo_header, :cache_per_filtro, :actual_cache_per_filtro, :label_eccezioni, :lista_label_ecc_del
      attr_accessor :with_version, :flag_cell_adj
      alias saa sistema_ambiente_archivio

      OPERAZIONE = [
        TEXT_INSERT = 1,
        TEXT_UPDATE = 2,
        TEXT_DELETE = 3,
        TEXT_UPDATE_VER = 4,
        TEXT_UPDATE_LABEL = 5
      ].freeze

      class <<self
        attr_reader :import_classes

        def inherited(klass)
          (@import_classes ||= []) << klass
        end
      end

      def initialize(sistema_ambiente_archivio:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @sistema_ambiente_archivio = sistema_ambiente_archivio
        @metamodello = opts[:metamodello] || sistema_ambiente_archivio.sistema.metamodello
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Import fomato utente(#{sistema_ambiente_archivio.full_descr})"
        @vendor_instance = saa.vendor_instance(opts)
        @use_pi = opts[:use_pi] || false
        @with_version = false
        @cache_per_filtro = {}
        @actual_cache_per_filtro = {}
        @solo_header = opts[:solo_header]
        @flag_cell_adj = Vendor::NO_FLAG
        @saa_riferimento = opts[:saa_riferimento] || sistema_ambiente_archivio
        @label_eccezioni = opts[:label_eccezioni] || LABEL_NC_DB
        if saa.archivio == ARCHIVIO_ECCEZIONI && !opts[:flag_cancellazione] # controllo che l'etichetta esista in anagrafica
          unless @label_eccezioni == LABEL_NC_DB
            raise  ArgumentError, "Parametro etichetta '#{@label_eccezioni}' non valido" if Db::EtichettaEccezioni.first(nome: @label_eccezioni).nil?
          end
        end
        @max_id_label = dataset_label_eccezioni.max(:id) || 0 if saa.archivio == ARCHIVIO_ECCEZIONI
        @lista_label_ecc_del = [] # lista delle etichette eccezioni impattate dall'operazione di delete sull'entita
      end

      def dataset
        @dataset ||= saa_riferimento.dataset(use_pi: @use_pi)
      end

      def dataset_label_eccezioni
        @dataset_label_eccezioni ||= (saa.archivio == ARCHIVIO_ECCEZIONI ? saa.entita_label.dataset : nil)
      end

      def with_version?
        @with_version
      end

      def formato_audit
        self.class.formato_audit
      end

      def import_cache(hash = {})
        @import_cache ||= {
          lista_entita:         {},
          nodi_esterni:         @solo_header ? {} : saa.carica_nodi_esterni(hash.merge(log_prefix: log_prefix)),
          meta_modello_header:  {},
          version_assente:      []
        }
      end

      def popola_cache_per_filtro(in_dist_name = nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        return if naming_path.nil? || naming_path.empty?
        if in_dist_name
          return unless actual_cache_per_filtro[naming_path]
          actual_cache_per_filtro[naming_path][FILTRO_MM_ENTITA] ||= []
          actual_cache_per_filtro[naming_path][FILTRO_MM_ENTITA] << in_dist_name if analizza_entita_filtro(naming_path, in_dist_name)
        else
          save_actual_cache_per_filtro
          reset_actual_cache_per_filtro
          return unless metamodello.meta_entita.keys.include?(naming_path)
          actual_cache_per_filtro[naming_path] = {}
          (import_cache[:meta_modello_header].keys[livello_entita - 1..-1] || []).each do |elem|
            unless import_cache[:meta_modello_header][elem][:entita_col_num].nil?
              (actual_cache_per_filtro[naming_path][FILTRO_MM_PARAMETRI] ||= []) << import_cache[:meta_modello_header][elem][:name]
            end
          end
        end
      end

      def reset_actual_cache_per_filtro
        @actual_cache_per_filtro = {}
      end

      def save_actual_cache_per_filtro # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        return if actual_cache_per_filtro.nil? || actual_cache_per_filtro.empty?
        np = actual_cache_per_filtro.keys[0]
        unless cache_per_filtro[np] && cache_per_filtro[np][FILTRO_MM_PARAMETRI] && (actual_cache_per_filtro[np][FILTRO_MM_PARAMETRI] || []).empty?
          cache_per_filtro[np] ||= {}
          cache_per_filtro[np][FILTRO_MM_PARAMETRI] = actual_cache_per_filtro[np][FILTRO_MM_PARAMETRI].dup if actual_cache_per_filtro[np][FILTRO_MM_PARAMETRI]

          cache_per_filtro[np][FILTRO_MM_ENTITA] = actual_cache_per_filtro[np][FILTRO_MM_ENTITA].dup if actual_cache_per_filtro[np][FILTRO_MM_ENTITA]
        end
        reset_actual_cache_per_filtro
      end

      def analizza_entita_filtro(naming_path, dist_name) # rubocop:disable Metrics/AbcSize
        len_np = naming_path.to_s.split(NAMING_PATH_SEP).count
        pezzi_dn = dist_name.to_s.split(DIST_NAME_SEP).map { |el| (el.split(DIST_NAME_VALUE_SEP) || [])[1] }
        check1 = pezzi_dn.count != len_np
        check2 = pezzi_dn.index('')
        check3 = pezzi_dn.index(nil)
        check4 = pezzi_dn.index(TEXT_NO_MOD)
        # check5 = (first_w = pezzi_dn.index(NOME_ENTITA_ANY)) && (pezzi_dn[first_w, pezzi_dn.count - first_w].uniq != [NOME_ENTITA_ANY])
        return false if check1 || check2 || check3 || check4 # || check5
        true
      end

      def reset_import_cache
        return nil unless @import_cache
        @import_cache = nil
      end

      def con_import_cache(opts, &_block)
        import_cache(opts)
        res = yield(import_cache)
        res
      ensure
        reset_import_cache
      end

      def con_parser(_file:, **_opts)
        raise NotImplementedError, "con_parser non implementata per la classe #{self.class}"
      end

      def analizza_entita_parser(_entita_parser:, **_opts)
        raise NotImplementedError, "analizza_entita_parser non implementata per la classe #{self.class}"
      end

      def aggiorna_database(ent, res) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
        # scorre lista_entita e per ogni entita effettua l'operazione necessaria sul db
        case ent.operazione
        when TEXT_DELETE
          # res[:del] += cancella_relazioni_adj_da_sorgente(ent) unless flag_cell_adj == Vendor::NO_FLAG
          cancella_relazioni_opts = {
            saa: saa, vendor_instance: vendor_instance,
            dataset: dataset, flag_cell_adj: flag_cell_adj
          }
          res[:del] += cancella_relazioni_adj_da_sorgente(entita_sorgente: ent, **cancella_relazioni_opts) unless flag_cell_adj == Vendor::NO_FLAG || ent.livello == 1
          res[:del] += dataset.where(dist_name: ent.dist_name).delete # cancellazione oggetto e figli tramite constraint
        when TEXT_INSERT
          ent.avvalora_campi_adiacenza(vendor_instance)
          dataset.insert(*ent.for_insert)
          res[:ins] += 1
        when TEXT_UPDATE
          ent.avvalora_campi_adiacenza(vendor_instance)
          res[:upd] += dataset.where(dist_name: ent.dist_name).update(parametri: ent.parametri.to_json, extra_name: ent.extra_name, version: ent.version, checksum: ent.checksum,
                                                                      cella_sorgente: ent.cella_sorgente, cella_adiacente: ent.cella_adiacente, updated_at: Time.now.to_s)
        when TEXT_UPDATE_VER
          res[:upd] += dataset.where(dist_name: ent.dist_name).update(version: ent.version, checksum: ent.checksum, updated_at: Time.now.to_s)
        else
          res[:nop] += 1
        end
      end

      def aggiorna_label_eccezioni(ent, res) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        return unless dataset_label_eccezioni
        # puts "in analizza_label_eccezioni: - dn: #{ent.dist_name} - operazione: #{ent.operazione} - #{ent.parametri_label}"
        case ent.operazione
        when TEXT_DELETE
          # TODO: da verificare per le entita cancellate automaticamente (relazioni di adiacenza & co)
          # in caso di import_fu di delete, vanno ricavate le label impattate per poi aggiornare la data_ultimo_import in EtichetteEccezioni
          @lista_label_ecc_del |= dataset_label_eccezioni.where("dist_name = '#{ent.dist_name}' OR dist_name like '#{ent.dist_name}#{DIST_NAME_SEP}%'").select_map(:label).uniq
          res[:del_label] += dataset_label_eccezioni.where("dist_name = '#{ent.dist_name}' OR dist_name like '#{ent.dist_name}#{DIST_NAME_SEP}%'").delete
        when TEXT_INSERT
          (ent.parametri_label[:parametri_tot] || []).each do |mp|
            ent_label = Db::EntitaLabel::Record.new(id: @max_id_label += 1, dist_name: ent.dist_name, meta_entita: ent.meta_entita, naming_path: ent.naming_path, meta_parametro: mp,
                                                    label: @label_eccezioni)
            dataset_label_eccezioni.insert(*ent_label.for_insert)
            res[:ins_label] += 1
          end
        when TEXT_UPDATE, TEXT_UPDATE_VER, TEXT_UPDATE_LABEL
          (ent.parametri_label[:parametri_fu] || []).each do |mp|
            db_ent_label = dataset_label_eccezioni.first(dist_name: ent.dist_name, meta_parametro: mp)
            if db_ent_label.nil?
              ent_label = Db::EntitaLabel::Record.new(id: @max_id_label += 1, dist_name: ent.dist_name, meta_entita: ent.meta_entita, naming_path: ent.naming_path, meta_parametro: mp,
                                                      label: @label_eccezioni)
              dataset_label_eccezioni.insert(*ent_label.for_insert)
              res[:ins_label] += 1
            else
              dataset_label_eccezioni.where(dist_name: ent.dist_name, meta_parametro: mp).update(label: @label_eccezioni, updated_at: Time.now.to_s)
              res[:upd_label] += 1
            end
          end
          unless (ent.parametri_label[:parametri_rimossi] || []).empty?
            res[:del_label] += dataset_label_eccezioni.where(dist_name: ent.dist_name, meta_parametro: ent.parametri_label[:parametri_rimossi]).delete
          end
        end
        res
      end

      def aggiorna_data_ultimo_import_etichette(flag_cancellazione: false)
        return if saa.archivio != ARCHIVIO_ECCEZIONI
        Irma::Db::EtichettaEccezioni.where(nome: @label_eccezioni).update(data_ultimo_import: Time.now.to_s) if @label_eccezioni != LABEL_NC_DB
        Irma::Db::EtichettaEccezioni.where(nome: @lista_label_ecc_del - [LABEL_NC_DB]).update(data_ultimo_import: Time.now.to_s) if flag_cancellazione
      end

      def verifica_entita_version(entita:, **opts) # rubocop:disable Metrics/AbcSize
        return if entita.version.nil? || entita.version.empty? || saa.sistema.release_di_nodo.nil?
        return if saa.sistema.release_di_nodo.include?(entita.version)
        return if import_cache[:version_assente].include? entita.version
        nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_FORMATO_UTENTE_DATI_VERSION_ASSENTE, dist_name: entita.dist_name, version: entita.version, **opts)
        import_cache[:version_assente] << entita.version
      end

      # torna true se l'eventuale nodo non e' definito su altri sistemi
      # effettua segnalazione se il nodo e' associato ad un altro sistema
      def verifica_nodo?(entita, nodo_naming_path: nil, **opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        entita.nodo = false
        return true unless nodo_naming_path
        entita.nodo = nodo_naming_path.include?(entita.naming_path) # nodo_naming_path e' un array
        unless entita.nodo
          nodo_np = nodo_naming_path.detect { |np| entita.naming_path.index(np) == 0 }
          return true if nodo_np.nil?
        end
        dist_name_nodo = entita.nodo ? entita.dist_name : entita.dist_name.split(DIST_NAME_SEP).take(nodo_np.count(NAMING_PATH_SEP) + 1).join(DIST_NAME_SEP)
        nodo_id = @import_cache[:lista_entita][dist_name_nodo]
        entita.nodo_id = nodo_id unless entita.nodo # imposto il nodo_id per le entita figlie di nodo
        ne = import_cache[:nodi_esterni][dist_name_nodo]
        return true if ne.nil?
        nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_FORMATO_UTENTE_DATI_NODO_SU_ALTRO_SISTEMA,
                           dist_name: entita.dist_name, dist_name_nodo: dist_name_nodo, riferimento_sistema: ne[:riferimento_sistema], **opts)
        raise "Nodo #{dist_name_nodo} associato a #{ne[:riferimento_sistema]}" if opts[:node_exit]
        true
      end

      def nome_file_per_segnalazioni
        @nome_file_per_segnalazioni || File.basename(@file.to_s)
      end

      def nuova_segnalazione(tipo_segnalazione, opts = {})
        return nil if @solo_header
        unless TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
          case funzione.id
          when FUNZIONE_PI_IMPORT_FORMATO_UTENTE
            tipo_segnalazione += 1
          when FUNZIONE_IMPORT_FU_OMC_FISICO
            tipo_segnalazione += 40 # tenere allineato con il tipo_segnalazione
          end
        end
        super(tipo_segnalazione, opts.merge(file: nome_file_per_segnalazioni))
      end

      def funzione
        @funzione ||= Db::Funzione.get_by_pk(if saa.is_a?(Db::SistemaAmbienteArchivio)
                                               saa_riferimento.pi ? FUNZIONE_PI_IMPORT_FORMATO_UTENTE : FUNZIONE_IMPORT_FORMATO_UTENTE
                                             else
                                               saa_riferimento.pi ? FUNZIONE_PI_IMPORT_FORMATO_UTENTE : FUNZIONE_IMPORT_FU_OMC_FISICO
                                             end
                                            )
      end

      def esegui(lista_file:, step_info: 10_000, **opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
        res = { entita: Hash.new(0), totale: 0 }
        saa.con_lock(funzione: funzione.nome, account_id: saa.account_id, mode: LOCK_MODE_WRITE, enable: !@solo_header, **opts) do # |locks|
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: saa.filtro_segnalazioni, attivita_id: opts[:attivita_id], enable: !@solo_header) do
            Irma.gc
            InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
              lista_file.each_with_index do |file, idx|
                con_parser(file: file, **opts) do |parser|
                  con_import_cache(**opts) do
                    begin
                      saa.db.transaction do
                        res[:"parser_#{idx}"] = parser.parse do |lista_entita_parser|
                          lista_entita_parser.each do |entita_parser|
                            ret = analizza_entita_parser(entita_parser: entita_parser, **opts)
                            res[:entita][ret] += 1
                            case ret
                            when ESITO_ANALISI_ENTITA_OK
                              import_cache[:lista_entita][entita_parser.dist_name] = entita_parser.id
                              aggiorna_database(entita_parser, res[:entita])
                              aggiorna_label_eccezioni(entita_parser, res[:entita]) if saa.archivio == ARCHIVIO_ECCEZIONI
                            when ESITO_ANALISI_ENTITA_DA_IGNORARE
                              # nothing to do
                            else
                              logger.warn("#{opts[:log_prefix]}, scartata entita (#{ret}), info=#{entita_parser.info}")
                            end
                            ip.incr do
                              segnalazione_esecuzione_in_corso("(processate #{ip.total} entità, #{ip.rate.round(0)} entità/s)")
                            end
                          end # lista_entita_parser
                        end # parser
                      end # transaction
                    rescue => e
                      res[:eccezione] = "#{e}: #{e.message} - nella rescue di begin"
                      logger.error("#{@log_prefix} catturata eccezione (#{res})")
                      raise
                    end
                  end # con_import_cache
                end # con_parser
              end # lista_file
              aggiorna_data_ultimo_import_etichette(flag_cancellazione: opts[:flag_cancellazione]) if saa.archivio == ARCHIVIO_ECCEZIONI
              segnalazione_esecuzione_in_corso("(processazione di #{ip.total} entità completato, #{ip.rate.round(0)} entità/s, inizio aggiornamento contatori)")
              res[:totale] = ip.total
              res
            end
            saa_riferimento.aggiorna_contatore_entita(use_pi: @use_pi)
            res[:msg] = 'caricamento eseguito'
            if @solo_header
              save_actual_cache_per_filtro # per salvare l'ultimo actual_cache_per_filtro in cache_per_filtro
              res[:header_per_filtro] = cache_per_filtro
            end
            res
          end # con_segnalazioni
        end # saa_con_lock
        res
      end
    end

    module ImportFormatoUtenteUtil
      def import_formato_utente(lista_file:, **opts)
        begin
          importer_class = Funzioni::ImportFormatoUtente.const_get(opts[:formato].to_s.camelize)
        rescue => e
          raise "Formato '#{opts[:formato]}' non supportato per l'importer in formato utente (#{e})"
        end
        importer_class.new(sistema_ambiente_archivio: self, **opts).esegui(lista_file: lista_file, **opts)
      end
    end
  end
  #
  module Db
    # extend class
    class SistemaAmbienteArchivio
      include Funzioni::ImportFormatoUtenteUtil
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      include Funzioni::ImportFormatoUtenteUtil
    end
  end
end

require_relative 'import_formato_utente/text'
require_relative 'import_formato_utente/xls'
