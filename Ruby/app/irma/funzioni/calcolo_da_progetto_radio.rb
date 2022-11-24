# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini, G. Cristelli
#
# Creation date: 20161216
#
require 'irma/cache'
require_relative 'segnalazioni_per_funzione'
# require 'irma/formuz/expr_parser'
require 'irma/conteggio_eccezioni_util'
require 'irma/calcolatore_util'

# rubocop:disable Metrics/BlockNesting, Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
module Irma
  #
  module Funzioni
    #
    # rubocop:disable Metrics/ClassLength
    class CalcoloDaProgettoRadio
      include SegnalazioniPerFunzione
      include ConteggioEccezioniUtil
      include CalcolatoreUtil

      attr_reader :logger, :sistema_ambiente_archivio, :metamodello, :log_prefix, :vendor_instance, :namingpath_root, :celle_per_il_calcolo, :saa_celle, :stats
      alias saa sistema_ambiente_archivio

      CAMPI_CELLA_PR_MAPPING = [
        CAMPO_CELLA_PR_NOME_CELLA,
        CAMPO_CELLA_PR_NOME_NODO,
        CAMPO_CELLA_PR_RELEASE_NODO,
        CAMPO_CELLA_PR_OMC_FISICO_ID,
        CAMPO_CELLA_PR_SISTEMA_ID
      ].each_with_object({}) { |k, res| res[k.to_sym] = k }.freeze

      PR_KEYS_CHECK_ADJ = [PR_KEY_CHECK_ADJ_SISTEMA = CAMPO_CELLA_PR_SISTEMA_ID, PR_KEY_CHECK_ADJ_OMC_FISICO = CAMPO_CELLA_PR_OMC_FISICO_ID].freeze

      SKIP_PADRI = ['SKIP'.freeze].freeze

      def initialize(sistema_ambiente_archivio:, saa_riferimento:, **opts) # rubocop:disable Metrics/PerceivedComplexity
        [sistema_ambiente_archivio, saa_riferimento].each do |k|
          unless k.is_a?(Db::SistemaAmbienteArchivio) || k.is_a?(Db::OmcFisicoAmbienteArchivio)
            raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
          end
        end
        @sistema_ambiente_archivio = saa_riferimento
        @per_omcfisico = opts[:per_omcfisico] || false
        # quando per_omcfisico vale true, il sistema di riferimento per il calcolo diventa l'omc fisico,
        # ma le celle del PR e il metamodello sono comunque da riferirsi all'omc logico => utilizzo @saa_celle per queste info
        @saa_celle = sistema_ambiente_archivio
        @sorgente = opts[:sorgente] # sorgente per i predefiniti, inteso come oggetto (saa, omcsaa, pi, che offrono i metodi 'dataset' e 'id')
        @label_sorgente = opts[:label_sorgente]

        @filtro_metamodello = opts[:filtro_metamodello] # { np1: [param1, param2,...], np2: [p,...] } filtro su meta_entita(np1, np2) e relativi parametri...
        @metamodello = opts[:metamodello] || @saa_celle.sistema.metamodello(per_calcolo: true, per_export: false, filtro_metamodello: @filtro_metamodello) # saa riferito a sistema

        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Calcolo da Progetto Radio per (#{sistema_ambiente_archivio.full_descr})"
        @precalcolo_regole = opts.fetch(:precalcolo_regole, false)
        @vendor_instance = @saa_celle.vendor_instance(opts) # saa riferito a sistema
        @prefissi_variabili_speciali_per_calcolatore = vendor_instance.prefissi_variabili_speciali_per_calcolatore
        @metaentita_per_fase = {}
        @parametri_predefiniti = nil
        @loader = nil
        @namingpath_root = {}
        @pr_key_check_adj = @per_omcfisico ? PR_KEY_CHECK_ADJ_OMC_FISICO : PR_KEY_CHECK_ADJ_SISTEMA
        @cache_segnalazioni = {}
        @celle_per_il_calcolo = []
        @celle_filtrate = [] # filtro_versione da cc
        @variabili_speciali_per_calcolatore = {}
        @header_pr = {}
        @aggiungi_celle_adiacenti_per_il_calcolo = opts[:aggiungi_celle_adiacenti_per_il_calcolo]
        @stats = { celle_da_calcolare: 0, celle_progetto_radio: 0, entita_create: 0, parametri_predefiniti: 0, eccezioni_parametri: 0,
                   rule_result_replace_meta_entita: 0, rule_result_replace_meta_parametro: 0 }
        @puts_calcolo = (ENV['PUTS_CALCOLO'] || '0') == '1'
        @no_eccezioni = opts[:no_eccezioni] || false
      end

      def dataset
        @dataset ||= saa.dataset(use_pi: true)
      end

      def dataset_source
        @dataset_source ||= @sorgente.dataset(use_pi: @sorgente.pi)
      end

      def dataset_eccezione
        @dataset_eccezione ||= @saa_celle.entita_eccezione.dataset if @saa_celle.entita_eccezione
      end

      def filtro_release
        @filtro_release ||= (@saa_celle.vendor_release || {})[:cc_filtro_release] || []
      end

      def header_pr(vr)
        return @header_pr[vr] if @header_pr[vr]
        @header_pr[vr] = {}
        (vr.header_pr || {}).each_key { |k| @header_pr[vr][k] = nil unless k.start_with?(*PREFISSI_ADIACENZA) } if vr
        @header_pr[vr]
      end

      # ---------------------------------------------------------------------------
      # Carica nelle variabili del calcolatore per il PR tutti i valori non relativi alle adiacenze, considerando anche quelli dell'header del sistema
      # Mette nella cache i campi che servono di PR e l'array delle adiacenze (hdr1, nome_cella1, hdr2, nome_cella2, ....) non vuote
      def load_cella(cella_pr:, add_special_vars:, info:) # rubocop:disable Metrics/PerceivedComplexity
        CAMPI_CELLA_PR_MAPPING.each { |key, key_map| info[key_map] = cella_pr[key] }
        pr_vars = header_pr(cella_pr.vendor_release).dup
        adjs = []
        cella_pr.valori.each do |k, v|
          if k.start_with?(*PREFISSI_ADIACENZA)
            if v && !v.first.to_s.empty?
              adjs << k
              adjs << v.first
              pr_vars[k] = v.first
            end
          else
            pr_vars[k] = v
            # vengono mantenuti nella cache anche tutti i valori che servono per le variabili speciali per il calcolatore
            info[k] = v if add_special_vars && @prefissi_variabili_speciali_per_calcolatore && k.start_with?(*@prefissi_variabili_speciali_per_calcolatore)
          end
        end
        info[CAMPO_CELLA_PR_ADJS] = adjs
        puts "cella: #{cella_pr.nome_cella}, info: #{info}, pr_vars: #{pr_vars}" if @puts_calcolo
        calcolatore.carica_variabili_pr_cella(nome_cella: cella_pr.nome_cella, variabili: pr_vars)
        @celle_progetto_radio[cella_pr.nome_cella] = info
      end

      def load_gruppo_celle(condition:, add_special_vars: false)
        Db::ProgettoRadio.db.transaction do
          # Db::ProgettoRadio.where(sistema_id: @saa_celle.sistema_id).each do |cella|
          query = condition.keys == [:sistema_id] ? Db::ProgettoRadio.where_sistema_id(condition[:sistema_id]) : Db::ProgettoRadio.where(condition)
          # Db::ProgettoRadio.where(condition).each do |cella|
          query.each do |cella|
            cella_in_cache = load_cella(cella_pr:         cella,
                                        add_special_vars: add_special_vars,
                                        info:             {
                                          CAMPO_CELLA_PR_RETE                          => cella.rete.nome,
                                          CAMPO_CELLA_PR_VENDOR_RELEASE_COMPACT_DESCR  => cella.vendor_release.compact_descr,
                                          CAMPO_CELLA_PR_VENDOR_SIGLA                  => cella.vendor.sigla,
                                          CAMPO_CELLA_PR_VENDOR_NOME                   => cella.vendor.nome
                                        })
            yield(cella_in_cache) if block_given?
          end
        end
      end

      def imposta_celle_per_calcolo(hash_cella)
        if filtro_release.include?(hash_cella[CAMPO_CELLA_PR_RELEASE_NODO])
          @celle_filtrate << hash_cella[CAMPO_CELLA_PR_NOME_CELLA]
        else
          @celle_per_il_calcolo << hash_cella[CAMPO_CELLA_PR_NOME_CELLA]
        end
      end

      def load_celle_progetto_radio(lista_nomi_celle) # # rubocop:disable Metrics/PerceivedComplexity
        @celle_per_il_calcolo = []
        @celle_filtrate = []
        return @celle_progetto_radio if @celle_progetto_radio
        start_time = Time.now
        Irma.lock(key: LOCK_KEY_PROGETTO_RADIO_OMC_LOGICO, mode: LOCK_MODE_READ, expire: 300, logger: @logger, omc_logico: @saa_celle.sistema.descr, rete: @saa_celle.rete.nome) do # saa di sistema
          @celle_progetto_radio = Cache.instance(key: "calcolo_pi_#{saa.pi.id}_celle_progetto_radio", type: :hash)
          nomi_celle_adj = []
          load_gruppo_celle(condition: { sistema_id: @saa_celle.sistema_id }, add_special_vars: true) do |cella_in_cache|
            next unless lista_nomi_celle.include?(cella_in_cache[CAMPO_CELLA_PR_NOME_CELLA])
            imposta_celle_per_calcolo(cella_in_cache)
            nomi_celle_adj |= cella_in_cache[CAMPO_CELLA_PR_ADJS].each_slice(2).map { |_hdr_adj, nome_adj| nome_adj }
          end

          nomi_adj_aggiunte = []
          if @aggiungi_celle_adiacenti_per_il_calcolo
            # si aggiungono le adiacenti dello stesso sistema a @celle_per_il_calcolo e a @celle_progetto_radio le celle adiacenti delle adiacenti aggiunte
            (@celle_progetto_radio.keys - lista_nomi_celle || []).each do |nome_cella_adj|
              lista_adj = @celle_progetto_radio[nome_cella_adj][CAMPO_CELLA_PR_ADJS].each_slice(2).map { |_hdr_adj, nome_adj| nome_adj }
              if lista_adj.index { |nome_cella| lista_nomi_celle.include?(nome_cella) }
                imposta_celle_per_calcolo(@celle_progetto_radio[nome_cella_adj])
                nomi_adj_aggiunte |= lista_adj
              end
            end
          end

          nomi_celle_adiacenti_fuori_sistema = (nomi_celle_adj + nomi_adj_aggiunte) - @celle_progetto_radio.keys
          load_gruppo_celle(condition: { nome_cella: nomi_celle_adiacenti_fuori_sistema }, add_special_vars: true) unless nomi_celle_adiacenti_fuori_sistema.empty?
        end
        @celle_per_il_calcolo.sort!
        @stats[:celle_da_calcolare] = @celle_per_il_calcolo.size + @celle_filtrate.size
        @stats[:celle_filtrate]     = @celle_filtrate.size
        @stats[:celle_progetto_radio] = @celle_progetto_radio.size
        logger.info("#{@log_prefix}, caricamento celle di progetto radio completato in #{(Time.now - start_time).round(1)} sec. " \
                    "(#{@stats[:celle_da_calcolare]} celle da calcolare, #{@stats[:celle_progetto_radio]} celle di progetto radio in cache)")
        @celle_progetto_radio
      end

      def reset_cache_celle_progetto_radio
        return nil unless @celle_progetto_radio
        @celle_progetto_radio.remove
        @celle_progetto_radio = nil
      end

      def con_cache_celle_progetto_radio(lista_nomi_celle, &_block)
        yield load_celle_progetto_radio(lista_nomi_celle)
      ensure
        reset_cache_celle_progetto_radio
      end

      # ---------------------------------------------------------------------------
      # cache entita

      def cache_entita(_hash = {})
        @cache_entita ||= {
          entita_create: Cache.instance(key: "calcolo_pi_#{saa.pi.id}_entita", type: :map_db)
        }
      end

      def reset_cache_entita
        return nil unless @cache_entita
        @cache_entita[:entita_create].remove
        @cache_entita = nil
      end

      def con_cache_entita(opts = {}, &_block)
        cache_entita(opts)
        res = yield(cache_entita)
        res
      ensure
        reset_cache_entita
      end

      # ---------------------------------------------------------------------------
      # calcolatore

      class InfoCalcolo < Hash
        %i(cella cella_adiacente fase multi is_adiacenza_interna
           meta_entita nome_entita dist_name_entita dist_name_padre meta_parametro
           cache_per_naming_path hdr_cella_adiacente).each do |m|
          define_method(m) do
            self[m]
          end
          define_method("#{m}=") do |v|
            self[m] = v
          end
        end
        attr_reader :naming_path, :naming_path_padre, :nome_meta_entita

        def self.[](v)
          me = v[:meta_entita]
          o = super(v)
          o.meta_entita = me if me
          o
        end

        def meta_entita=(me)
          self[:meta_entita] = me
          @naming_path = me && me.naming_path
          @naming_path_padre = @naming_path && @naming_path.to_s.split(NAMING_PATH_SEP)[0..-2].join(NAMING_PATH_SEP)
          @nome_meta_entita = me && me.nome
          me
        end

        def nome_cella
          cella ? cella[CAMPO_CELLA_PR_NOME_CELLA] : nil
        end

        def nome_cella_adiacente
          cella_adiacente ? cella_adiacente[CAMPO_CELLA_PR_NOME_CELLA] : nil
        end

        def nome_parametro
          (meta_parametro || {})[:nome]
        end

        def ae?
          cella_adiacente && !is_adiacenza_interna
        end

        def tipo_atteso
          (meta_parametro || meta_entita).tipo
        end

        def release_nodo
          cella && cella[CAMPO_CELLA_PR_RELEASE_NODO]
        end

        def aggiorna_cache_per_naming_path(is_alias: false)
          cache_per_naming_path && cache_per_naming_path.aggiorna(naming_path: naming_path, dist_name: dist_name_entita, fase: fase, is_alias: is_alias)
        end

        def reset_adiacente_cache_per_naming_path
          cache_per_naming_path.reset_adiacente
        end

        def get_from_cache_per_naming_path(naming_path:, is_alias: false)
          cache_per_naming_path.get(naming_path: naming_path, fase: fase, meta_entita_ref: meta_entita.meta_entita_ref, is_alias: is_alias)
        end

        def regole_calcolo(metaobj: nil) # rubocop:disable Metrics/PerceivedComplexity
          metaobj ||= (meta_parametro || meta_entita)
          if ae?
            return [] if cella_adiacente.nil? || metaobj.regole_calcolo_ae.nil?
            the_grp_key, the_key = if metaobj.regole_calcolo_ae[RC_VENDORREL_GRP_KEY] &&
                                      metaobj.regole_calcolo_ae[RC_VENDORREL_GRP_KEY].keys.include?(x = cella_adiacente[CAMPO_CELLA_PR_VENDOR_RELEASE_COMPACT_DESCR])
                                     [RC_VENDORREL_GRP_KEY, x]
                                   elsif metaobj.regole_calcolo_ae[RC_VENDOR_GRP_KEY] &&
                                         metaobj.regole_calcolo_ae[RC_VENDOR_GRP_KEY].keys.include?(y = cella_adiacente[CAMPO_CELLA_PR_VENDOR_NOME])
                                     [RC_VENDOR_GRP_KEY, y]
                                   elsif release_nodo &&
                                         metaobj.regole_calcolo_ae[RC_RELNODO_GRP_KEY] &&
                                         metaobj.regole_calcolo_ae[RC_RELNODO_GRP_KEY].keys.include?(release_nodo)
                                     [RC_RELNODO_GRP_KEY, release_nodo]
                                   else
                                     [RC_DEFAULT_GRP_KEY, DEFAULT_KEY]
                                   end
            (metaobj.regole_calcolo_ae[the_grp_key] || {})[the_key] || []
          else
            return [] unless metaobj.regole_calcolo
            if release_nodo && metaobj.regole_calcolo[RC_RELNODO_GRP_KEY] && metaobj.regole_calcolo[RC_RELNODO_GRP_KEY][release_nodo]
              metaobj.regole_calcolo[RC_RELNODO_GRP_KEY][release_nodo] || []
            elsif metaobj.regole_calcolo[RC_DEFAULT_GRP_KEY]
              metaobj.regole_calcolo[RC_DEFAULT_GRP_KEY][DEFAULT_KEY] || []
            else
              []
            end
          end
        end

        def msg_cella
          cella && "#{nome_cella} (#{release_nodo})"
        end

        def msg_cella_adiacente
          cella_adiacente && ", cella adiacente #{nome_cella_adiacente} (#{cella_adiacente[CAMPO_CELLA_PR_VENDOR_RELEASE_COMPACT_DESCR]})"
        end
      end

      class CachePerNamingPath
        attr_reader :entita_per_naming_path, :entita_per_naming_path_adiacente, :entita_per_naming_path_alias
        def initialize(naming_path_root = nil)
          @entita_per_naming_path = (naming_path_root || {}).dup
          reset_alias
          reset_adiacente
        end

        def reset_adiacente
          @entita_per_naming_path_adiacente = {}
        end

        def reset_alias
          @entita_per_naming_path_alias = {}
        end

        def aggiorna(naming_path:, dist_name:, fase:, is_alias: false)
          if is_alias
            @entita_per_naming_path_alias[naming_path] ||= []
            @entita_per_naming_path_alias[naming_path] << dist_name
          else
            @entita_per_naming_path[naming_path] ||= []
            @entita_per_naming_path[naming_path] << dist_name
          end
          aggiorna_adiacente(naming_path: naming_path, dist_name: dist_name) if fase == FASE_CALCOLO_ADJ
        end

        def keys
          @entita_per_naming_path.keys
        end

        def [](k)
          @entita_per_naming_path[k]
        end

        def aggiorna_adiacente(naming_path:, dist_name:)
          @entita_per_naming_path_adiacente[naming_path] ||= []
          @entita_per_naming_path_adiacente[naming_path] << dist_name
        end

        def get(naming_path:, fase:, meta_entita_ref: nil, is_alias: false) # rubocop:disable Metrics/PerceivedComplexity
          if fase == FASE_CALCOLO_PI_ALIAS || is_alias
            # -----------------------------------------------------------------------
            # ???????????????????????????????????????????????????????????????????????
            # primo livello sotto entita alias
            padri = @entita_per_naming_path_alias[naming_path]
            return padri if padri && !padri.empty?
            # livelli successivi
            padri_potenziali = @entita_per_naming_path[naming_path]
            if padri_potenziali.nil?
              return nil unless @entita_per_naming_path_alias.empty?
              return SKIP_PADRI
            end

            # TODO: ipotizzo meta_entita_ref con un solo elemento!!! ...poi vediamo...
            me_ref = (meta_entita_ref || '').split(',')
            ancestor_alias = @entita_per_naming_path_alias[me_ref[0]]
            padri_potenziali.each do |ppp|
              # ci sono padri...li tengo solo se sono discendenti di alias...
              (padri ||= []) << ppp if ppp.start_with?(*ancestor_alias)
            end
            padri
            # ???????????????????????????????????????????????????????????????????????
            # -----------------------------------------------------------------------
          elsif fase == FASE_CALCOLO_PI || fase == FASE_CALCOLO_REF
            @entita_per_naming_path[naming_path]
          elsif fase == FASE_CALCOLO_ADJ
            x = @entita_per_naming_path_adiacente[naming_path]
            x.nil? || x.empty? ? @entita_per_naming_path[naming_path] : x
          end
        end
      end

      # metodo a supporto del test, per permettere di utilizzare una classe diversa da CalcolatoreDummy...
      def get_calcolatore(hash)
        Calcolatore.new(hash)
      end

      def calcolatore(hash = {})
        @calcolatore ||= get_calcolatore(hash)
      end

      def reset_calcolatore
        return nil unless @calcolatore
        @calcolatore.reset
      ensure
        @calcolatore = nil
      end

      def con_calcolatore(opts = {}, &_block)
        calcolatore(opts)
        res = yield(calcolatore)
        res
      ensure
        reset_calcolatore
      end

      # ---------------------------------------------------------------------------
      # load parametri

      # parametri predefiniti da 'sorgente'

      # meta_parametri_calcolo = { np1 => {predefiniti: {nome_pp1 => pp1_obj, nome_pp2 => pp2_obj,...],...}}
      def load_parametri_predefiniti
        start_time = Time.now
        # lock per comandi che modificano archivio 'sorgente'...
        pp = Cache.instance(key: "calcolo_pi_#{saa.pi.id}_parametri_predefiniti", type: :map_db)
        mp_per_naming_path = {}
        meta_parametri_calcolo.each do |naming_path, mp_info|
          mp_per_naming_path[naming_path] = mp_info[:predefiniti].keys unless (mp_info[:predefiniti] || {}).empty?
        end

        n = 0
        @stats[:parametri_predefiniti] = 0
        dataset_source.db.transaction do
          dataset_source.where(naming_path: mp_per_naming_path.keys).select(:dist_name, :parametri, :naming_path).each do |record|
            next unless record[:parametri]
            pp[record[:dist_name]] = (mp_per_naming_path[record[:naming_path]] || []).each_with_object({}) do |p, res|
              if record[:parametri][p]
                res[p] = record[:parametri][p]
                @stats[:parametri_predefiniti] += 1
              end
            end
            n += 1
          end
        end
        logger.info("#{@log_prefix}, precaricamento in cache dei parametri predefiniti completato in #{(Time.now - start_time).round(1)} sec. " \
                    "(#{@stats[:parametri_predefiniti]} parametri, #{n} dist_name in cache, #{mp_per_naming_path.size} meta entità)")
        pp
      end

      def reset_cache_parametri_predefiniti
        return nil unless @parametri_predefiniti
        @parametri_predefiniti.remove
        @parametri_predefiniti = nil
      end

      def con_cache_parametri_predefiniti(pre_caricamento: true, &_block)
        @parametri_predefiniti = pre_caricamento ? load_parametri_predefiniti : nil
        yield @parametri_predefiniti
      ensure
        reset_cache_parametri_predefiniti
      end

      def load_archivio_eccezioni
        start_time = Time.now
        # lock per comandi che modificano archivio eccezioni...
        pp = Cache.instance(key: "calcolo_pi_#{saa.pi.id}_eccezione_parametri", type: :hash)

        n = 0
        @stats[:eccezioni_parametri] = 0
        @stats[:eccezioni_parametri_per_sintesi] = {}
        dataset_eccezione.db.transaction do
          dataset_eccezione.select(:dist_name, :parametri, :naming_path).each do |record|
            next unless record[:parametri]
            # already_counted = {}
            res = {}
            record[:parametri].each do |p, v|
              next unless v
              res[p] = v
              @stats[:eccezioni_parametri] += 1
              # p_for_count = p.split(TEXT_STRUCT_NAME_SEP).first
              # @stats[:eccezioni_parametri_per_sintesi] += 1 unless already_counted[p_for_count]
              # already_counted[p_for_count] = true
            end
            pp[record[:dist_name]] = res
            n += 1
          end
          @stats[:eccezioni_parametri_per_sintesi] = conteggio_eccezioni_per_etichetta_totale(sistema: @saa_celle.sistema)
        end
        logger.info("#{@log_prefix}, precaricamento in cache eccezioni parametri completato in #{(Time.now - start_time).round(1)} sec. " \
                    "(#{@stats[:eccezioni_parametri]} eccezioni parametri, #{n} dist_name in cache)")
        pp
      end

      def reset_cache_archivio_eccezioni
        return nil unless @archivio_eccezioni
        @archivio_eccezioni.remove
        @archivio_eccezioni = nil
      end

      def archivio_eccezioni(pre_caricamento: true)
        @archivio_eccezioni ||= (pre_caricamento ? load_eccezione_parametri : nil)
      end

      def con_cache_archivio_eccezioni(pre_caricamento: true, &_block)
        @archivio_eccezioni = pre_caricamento ? load_archivio_eccezioni : nil
        yield @archivio_eccezioni
      ensure
        reset_cache_archivio_eccezioni
      end

      def rule_result_replace(meta_obj, parametro: false) # rubocop:disable Metrics/PerceivedComplexity
        RULE_FIELDS.each do |k|
          (meta_obj.send(k) || {}).each_value do |k_hash|
            k_hash.each_value do |values|
              next unless values
              values.map! do |v|
                rr = RuleResult.crea_da_regola(regola: v, tipo_atteso: meta_obj.tipo, parametro: parametro)
                if rr
                  @stats[parametro ? :rule_result_replace_meta_parametro : :rule_result_replace_meta_entita] += 1
                  puts "#{parametro ? "MetaParametro #{meta_obj.full_name}" : "MetaEntita #{meta_obj.nome}"} rule_result_replace '#{v}' => #{rr.to_json}" if @puts_calcolo
                end
                rr || v
              end
            end
          end
        end
        meta_obj
      end

      def meta_entita_calcolo
        @meta_entita_calcolo ||= begin
                                   if @precalcolo_regole
                                     # puts "BEFORE (Metamodello meta_entita): #{metamodello.meta_entita_calcolo}"
                                     metamodello.meta_entita_calcolo.each_value do |np_hash|
                                       np_hash.each_value { |meta_obj| rule_result_replace(meta_obj, parametro: false) }
                                     end
                                   end
                                   # puts "AFTER (Metamodello meta_entita): #{metamodello.meta_entita_calcolo}"
                                   metamodello.meta_entita_calcolo
                                 end
      end

      def meta_parametri_calcolo
        @meta_parametri_calcolo ||= begin
                                      if @precalcolo_regole
                                        metamodello.meta_parametri_calcolo.each_value do |k_hash|
                                          k_hash.each_value { |p_hash| p_hash.each_value { |mo| rule_result_replace(mo, parametro: true) } }
                                        end
                                      end
                                      metamodello.meta_parametri_calcolo
                                    end
      end

      # ---------------------------------------------------------------------------
      # gestione risultato di calcolo per entita

      # rubocop:disable Metrics/PerceivedComplexity
      def gestisci_calcolo(info_calcolo:, regola:)
        begin
          ret = calcolatore.calcola_regola(regola: regola, info_calcolo: info_calcolo)
          return ret.valore if ret.ok?
          comportamento = vendor_instance.determina_comportamento_result_calcolo(info_calcolo: info_calcolo, tipo_errore: ret.tipo_errore)
          # --- segnalazione
          if comportamento.tipo_segnalazione
            nuova_segnalazione(comportamento.tipo_segnalazione,
                               cella: info_calcolo.msg_cella, cella_adiacente: info_calcolo.msg_cella_adiacente,
                               meta_entita: info_calcolo.nome_meta_entita, entita: info_calcolo.dist_name_entita || info_calcolo.nome_entita,
                               meta_parametro: info_calcolo.nome_parametro,
                               dist_name_padre: info_calcolo.dist_name_padre, naming_path: info_calcolo.naming_path, err_msg: ret.err_msg + "\n\nRegola:\n#{regola.to_s.truncate(256)}")
          end
          # --- log
          if ENV['LOG_ERRORE_CALCOLO'] || comportamento.tipo_segnalazione
            msg = "cella #{info_calcolo.msg_cella}#{info_calcolo.msg_cella_adiacente}"
            msg += ", dist_name_padre #{info_calcolo.dist_name_padre}" if info_calcolo.dist_name_padre
            msg += " =>  Errore nel calcolare la regola #{regola.to_json.gsub("\n", '\n')}, "
            msg += info_calcolo.meta_parametro ? "per meta_parametro #{info_calcolo.nome_parametro}: " : "per meta_entita #{info_calcolo.naming_path}: "
            msg += "#{ret.err_msg} (risultato = #{ret.to_json})"

            logger.send(ret.tipo_errore == ESITO_CALCOLO_ERRORE_CALCOLATORE ? :error : :warn, "#{@log_prefix}, #{msg}")
          end
        rescue => e
          msg = "Eccezione nel calcolo della regola #{regola.to_json.gsub("\n", '\n')} per la cella #{info_calcolo.msg_cella}#{info_calcolo.msg_cella_adiacente}"
          logger.error("#{@log_prefix}, #{msg}: #{e}")
          raise
        end

        # ATTENZIONE: messaggio collegato al calcolo alias
        raise "Errore in calcolo #{info_calcolo.meta_parametro ? 'parametro' : 'entita\''}" if comportamento.abort?
        comportamento.ok? ? ret.valore : nil
      end

      # ---------------------------------------------------------------------------
      # calcolo parametri
      def get_parametri_da_archivio_eccezioni(dist_name)
        (@archivio_eccezioni ? @archivio_eccezioni[dist_name] : (dataset_eccezione.first(dist_name: dist_name) || {})[:parametri]) || {}
      end

      def get_parametri_entita(dist_name)
        (@parametri_predefiniti ? @parametri_predefiniti[dist_name] : (dataset_source.first(dist_name: dist_name) || {})[:parametri]) || {}
      end

      def calcola_parametri(info_calcolo:) # rubocop:disable Metrics/PerceivedComplexity
        # saved for ensure
        multi_orig = info_calcolo.multi

        i_parametri = {}
        meta_p = meta_parametri_calcolo[info_calcolo.naming_path]
        # imposto di base i parametri con la valorizzazione delle eccezioni, poi aggiungo eventuali ulteriori parametri
        i_parametri = get_parametri_da_archivio_eccezioni(info_calcolo.dist_name_entita) unless @no_eccezioni
        return i_parametri if meta_p.nil? || meta_p.empty? # TODO: Aggiungere un log warning ?

        predefiniti = get_parametri_entita(info_calcolo.dist_name_entita) unless (meta_p[:predefiniti] || {}).empty?

        # 1. controllo prima i predefiniti
        (meta_p[:predefiniti] || {}).each_key do |p_name|
          next if i_parametri[p_name] || predefiniti[p_name].nil?
          i_parametri[p_name] = predefiniti[p_name]
        end

        # 2. controllo tutti quelli da calcolare (inclusi i predefiniti)
        first_time = true
        (meta_p[info_calcolo.ae? ? :da_calcolare_ae : :da_calcolare] || {}).each do |p_name, p_obj|
          next if i_parametri[p_name]

          info_calcolo.meta_parametro = p_obj
          info_calcolo.multi = p_obj.is_multivalue ? REGOLA_CALCOLO_MULTI : REGOLA_CALCOLO_NON_MULTI

          rc = info_calcolo.regole_calcolo
          next if rc.empty?

          # 3. imposto le variabili del calcolatore solo al primo parametro da calcolare
          if first_time
            calcolatore.carica_variabili(variabili_per_calcolatore(info_calcolo.dist_name_entita, info_calcolo.naming_path, info_calcolo.hdr_cella_adiacente))
            first_time = false
          end

          values = rc.map do |regola_calcolo|
            gestisci_calcolo(info_calcolo: info_calcolo, regola: regola_calcolo)
          end.compact
          #-----------------------------------------------------------------------------------------
          # La generazione di questa eccezione e' da rivedere, al momento (20170517) non si fa.
          # if values.size > 1 && values.compact.empty? && p_obj.is_multistruct
          #   nuova_segnalazione(TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_PARAM_STRUTTURATO,
          #                      meta_parametro: p_name, meta_entita: info_calcolo.nome_meta_entita, entita: info_calcolo.dist_name_entita,
          #                      cella: info_calcolo.nome_cella, cella_adiacente: info_calcolo.nome_cella_adiacente,
          #                      err_msg: 'Nessun campo del parametro e\' stato calcolato correttamente')
          # end
          #-----------------------------------------------------------------------------------------
          next if values.empty?
          i_parametri[p_name] = p_obj.determina_valore(values)
        end
        # tolgo i parametri con valore TEXT_PARAMETRO_ASSENTE_IN_PI: impostazione che si puo' trovare solo nell'archivio delle eccezioni
        i_parametri.delete_if { |_k, v| v.is_a?(Array) ? v.first.eql?(TEXT_PARAMETRO_ASSENTE_IN_PI) : v.eql?(TEXT_PARAMETRO_ASSENTE_IN_PI) }
      ensure
        info_calcolo.meta_parametro = nil
        info_calcolo.multi = multi_orig
      end

      # ---------------------------------------------------------------------------
      # fasi di calcolo
      def calcolo_root(cella:)
        meroot = meta_entita_calcolo[MetaModello::ROOT]
        raise 'MetaEntita di fase PI non conformi (Non esiste MetaEntita root)' if meroot.nil? || meroot.empty?
        _np, me = meroot.first

        info_calcolo = InfoCalcolo[cella: cella, meta_entita: me, fase: FASE_CALCOLO_PI, multi: REGOLA_CALCOLO_NON_MULTI]
        rc = info_calcolo.regole_calcolo
        if rc.empty?
          gestisci_assenza_regole_calcolo_entita(info_calcolo: info_calcolo)
          return
        end
        calcolatore.carica_variabili
        info_calcolo.nome_entita = gestisci_calcolo(info_calcolo: info_calcolo, regola: rc[0])
        return unless info_calcolo.nome_entita

        info_calcolo.dist_name_entita = costruisci_dist_name(nil, me.nome, info_calcolo.nome_entita)
        parametri = calcola_parametri(info_calcolo: info_calcolo)
        nuova_entita_per_loader(entita_record: crea_entita(info_calcolo: info_calcolo, parametri: parametri), info_calcolo: info_calcolo)
        @namingpath_root = { me.naming_path => [info_calcolo.dist_name_entita] }
      end

      def calcolo_cella(cella:, pr:)
        info_calcolo = InfoCalcolo[cella: cella, cache_per_naming_path: CachePerNamingPath.new(@namingpath_root)]
        @variabili_speciali_per_calcolatore = vendor_instance.variabili_speciali_per_calcolatore(nome_cella: info_calcolo.nome_cella, pr: pr)
        puts "#{info_calcolo.nome_cella}, variabili speciali: #{@variabili_speciali_per_calcolatore}" if @puts_calcolo
        calcolo_fase_pi(info_calcolo: info_calcolo)
        calcolo_fase_pi_alias(info_calcolo: info_calcolo)
        calcolo_fase_adj(info_calcolo: info_calcolo)
        calcolo_fase_ref(info_calcolo: info_calcolo)
      end

      def calcolo_fase_pi(info_calcolo:)
        info_calcolo.fase = FASE_CALCOLO_PI
        meta_entita_calcolo[FASE_CALCOLO_PI.to_s].each do |_np, me|
          info_calcolo.meta_entita = me
          calcola(info_calcolo: info_calcolo)
        end
      end

      def calcolo_fase_pi_alias(info_calcolo:)
        info_calcolo.fase = FASE_CALCOLO_PI_ALIAS
        meta_entita_calcolo[FASE_CALCOLO_PI_ALIAS.to_s].each do |_np, me|
          info_calcolo.meta_entita = me
          calcola(info_calcolo: info_calcolo, is_alias: true)
        end
      end

      def calcolo_fase_ref(info_calcolo:)
        info_calcolo.fase = FASE_CALCOLO_REF
        meta_entita_calcolo[FASE_CALCOLO_REF.to_s].each do |_np, me|
          info_calcolo.meta_entita = me
          ok = (@filtro_metamodello || {}).empty?
          if ok
            me.meta_entita_ref_array.each do |mer|
              if info_calcolo.cache_per_naming_path[mer]
                ok = false
                break
              end
            end
          end
          next if ok
          puts "FASE REF meta_entita: #{me.naming_path}" if @puts_calcolo
          calcola(info_calcolo: info_calcolo)
        end
      end

      def calcolo_fase_adj(info_calcolo:)
        info_calcolo.fase = FASE_CALCOLO_ADJ
        me_fase_adj = meta_entita_calcolo[FASE_CALCOLO_ADJ.to_s]
        return if me_fase_adj.empty?
        adiacenze = celle_adiacenti(info_calcolo.cella)
        [TIPO_ADIACENZA_ESTERNA, TIPO_ADIACENZA_INTERNA].each do |tipo_adj|
          info_calcolo.is_adiacenza_interna = TIPO_ADIACENZA_INTERNA == tipo_adj
          adiacenze[tipo_adj].each do |hdr, cella_adj|
            puts "FASE ADJ #{Constant.key(:tipo_adiacenza, tipo_adj)} #{info_calcolo.nome_cella}, check" if @puts_calcolo
            info_calcolo.reset_adiacente_cache_per_naming_path
            me_fase_adj.each do |np, me|
              next if me.rete_adj != cella_adj[CAMPO_CELLA_PR_RETE] # && is_ae # skip per rete_adj anche per adiacenze INTERNE, vericare con attenzione in caso di calcolo per omc_fisico !!!!
              next if (me.tipo_adiacenza & tipo_adj) != tipo_adj
              next if vendor_instance.calcolo_adj_da_scartare?(np: np, me: me, hdr: hdr)
              info_calcolo.meta_entita         = me
              info_calcolo.cella_adiacente     = cella_adj
              info_calcolo.hdr_cella_adiacente = hdr
              puts "FASE ADJ #{Constant.key(:tipo_adiacenza, tipo_adj)} #{info_calcolo.nome_cella_adiacente}, calcolo per meta_entita_fase_adj: #{me.naming_path}" if @puts_calcolo
              calcola(info_calcolo: info_calcolo)
            end
          end
        end
      ensure
        info_calcolo.cella_adiacente = nil
        info_calcolo.is_adiacenza_interna = nil
        info_calcolo.hdr_cella_adiacente = nil
      end

      # restituisce l'hash con chiavi CALC_SPECIAL_VARS
      def variabili_per_calcolatore(dist_name, naming_path, hdr_adiacenza = nil) # rubocop:disable Metrics/PerceivedComplexity
        calc_var = {}

        if hdr_adiacenza
          calc_var[CALC_SPECIAL_VAR_ADJ_HDR] = [hdr_adiacenza, TIPO_VALORE_CHAR]
          calc_var[CALC_SPECIAL_VAR_ADJ_IDX] = [hdr_adiacenza.split('_')[1], TIPO_VALORE_CHAR]
        end

        me = metamodello.meta_entita[naming_path]
        ne = nome_entita(dist_name).to_s
        if me && !ne.empty?
          calc_var[CALC_SPECIAL_VAR_C_P] = [ne, TIPO_VALORE_CHAR]
          int_value = ne.to_i
          calc_var[CALC_SPECIAL_VAR_P] = [int_value, TIPO_VALORE_INTEGER] if int_value != 0 || ne == '0'
        end

        np_ancestor = naming_path_padre(naming_path)
        unless np_ancestor.empty?
          me_ancestor = metamodello.meta_entita[np_ancestor]
          ne_ancestor = nome_entita_padre(dist_name).to_s
          if me_ancestor && !ne_ancestor.empty?
            calc_var[CALC_SPECIAL_VAR_C_PP] = [ne_ancestor, TIPO_VALORE_CHAR]
            int_value = ne_ancestor.to_i
            calc_var[CALC_SPECIAL_VAR_PP] = [int_value, TIPO_VALORE_INTEGER] if int_value != 0 || ne_ancestor == '0'
          end
        end
        puts "variabili_per_calcolatore: #{calc_var}" if @puts_calcolo
        calc_var.update(@variabili_speciali_per_calcolatore)
      end

      def nuova_entita_calcolata(info_calcolo:, is_alias: false)
        info_calcolo.dist_name_entita = costruisci_dist_name(info_calcolo.dist_name_padre, info_calcolo.nome_meta_entita, info_calcolo.nome_entita)
        # if info_calcolo.nome_meta_entita == 'EXCCG' || info_calcolo.nome_meta_entita == 'EXGCE'
        #   puts "RRRRRRRR dn entita creata: #{info_calcolo.dist_name_entita} cella: #{info_calcolo.nome_cella} fase: #{info_calcolo.fase} naming_path: #{info_calcolo.naming_path}"
        # end
        if cache_entita[:entita_create][info_calcolo.dist_name_entita]
          # questa entita e' gia' stata creata precedentemente, aggiorno solo cache namingpath
          info_calcolo.aggiorna_cache_per_naming_path(is_alias: is_alias)
        else
          parametri = calcola_parametri(info_calcolo: info_calcolo)
          id_entita_padre = cache_entita[:entita_create][info_calcolo.dist_name_padre]
          raise "Entita padre '#{info_calcolo.dist_name_padre}' non esiste" unless id_entita_padre
          er = crea_entita(info_calcolo: info_calcolo, id_entita_padre: id_entita_padre, parametri: parametri)
          nuova_entita_per_loader(entita_record: er, info_calcolo: info_calcolo, is_alias: is_alias)
        end
        info_calcolo.dist_name_entita
      end

      def calcola_padri(info_calcolo:, is_alias: false)
        puts "--> calcola_padri cella #{info_calcolo.nome_cella}, naming_path = #{info_calcolo.naming_path}" if @puts_calcolo
        me = metamodello.meta_entita[info_calcolo.naming_path_padre]
        info_calcolo_padre = info_calcolo.dup
        info_calcolo_padre.meta_entita = me
        res = calcola(info_calcolo: info_calcolo_padre, is_alias: is_alias)
        puts "<-- calcola_padri cella #{info_calcolo.nome_cella}, naming_path = #{info_calcolo.naming_path}: #{res}" if @puts_calcolo
        res
      end

      #
      def calcola(info_calcolo:, is_alias: false) # rubocop:disable Metrics/PerceivedComplexity
        # saved for ensure
        multi_orig = info_calcolo.multi
        #
        info_calcolo.multi = REGOLA_CALCOLO_NON_MULTI

        res_dn_entita_create = []

        # calcolo speciale per vsData
        calcolo_vs_data = vendor_instance.calcolo_vs_data? && info_calcolo.meta_entita.vs_data?
        puts "CELLA: #{info_calcolo.nome_cella}, ADJ: #{info_calcolo.nome_cella_adiacente}, meta_entita con vs_data #{info_calcolo.nome_meta_entita}" if calcolo_vs_data && @puts_calcolo
        unless calcolo_vs_data
          # regola/e di calcolo
          rc = info_calcolo.regole_calcolo
          if rc.empty?
            gestisci_assenza_regole_calcolo_entita(info_calcolo: info_calcolo)
            return res_dn_entita_create
          end

          info_calcolo.multi = rc.count > 1 ? REGOLA_CALCOLO_MULTI : REGOLA_CALCOLO_NON_MULTI

          rc_alias = ((info_calcolo.meta_entita.regole_calcolo || {})[RC_DEFAULT_GRP_KEY] || {})[ALIAS_KEY] if calcolo_alias?
        end

        # padre/i
        padri = info_calcolo.get_from_cache_per_naming_path(naming_path: info_calcolo.naming_path_padre, is_alias: is_alias)
        if padri.nil? || padri.empty?
          # comportamento = vendor_instance.comportamento_nessun_padre[info_calcolo.fase]
          comportamento = vendor_instance.determina_comportamento_nessun_padre(info_calcolo: info_calcolo)
          return res_dn_entita_create if comportamento.skip?
          raise "Nessuna entita padre per naming_path #{info_calcolo.naming_path}" if comportamento.abort?
          padri = calcola_padri(info_calcolo: info_calcolo, is_alias: is_alias) # if ccc.ok?
        elsif padri == SKIP_PADRI # skip forzato per alias...
          padri = []
        end

        padri.each do |distname_entita_padre|
          info_calcolo.dist_name_padre = distname_entita_padre
          if calcolo_vs_data
            info_calcolo.nome_entita = nome_entita(distname_entita_padre)
            dn = nuova_entita_calcolata(info_calcolo: info_calcolo, is_alias: is_alias)
            res_dn_entita_create << dn
          else
            counter_rc_ok = 0
            vpc = variabili_per_calcolatore(distname_entita_padre, info_calcolo.naming_path_padre, info_calcolo.hdr_cella_adiacente)
            # ==================================================================================================================
            # regole di calcolo standard
            rc.each do |regola_calcolo|
              calcolatore.carica_variabili(vpc)
              info_calcolo.nome_entita = gestisci_calcolo(info_calcolo: info_calcolo, regola: regola_calcolo)
              next unless info_calcolo.nome_entita
              # --
              counter_rc_ok += 1
              dn = nuova_entita_calcolata(info_calcolo: info_calcolo, is_alias: is_alias)
              res_dn_entita_create << dn
              # --
            end
            # regola multivalore e tutte ko
            if info_calcolo.multi == REGOLA_CALCOLO_MULTI && counter_rc_ok == 0
              gestisci_calcolo_entita_multi_errore_totale(info_calcolo: info_calcolo)
            end
            # ==================================================================================================================
            # TODO: blocco simile a regole_calcolo_standard...se tutto funziona va fatto refactoring...
            # regole di calcolo alias
            if calcolo_alias? && rc_alias
              (rc_alias || []).each do |regola_calcolo|
                calcolatore.carica_variabili(vpc)
                info_calcolo.nome_entita = nil
                begin
                  info_calcolo.nome_entita = gestisci_calcolo(info_calcolo: info_calcolo, regola: regola_calcolo)
                rescue => e
                  # TODO: agganciare a costante il messaggio di errore
                  raise e unless e.message == "Errore in calcolo entita'"
                end
                next unless info_calcolo.nome_entita
                # --
                counter_rc_ok += 1
                dn = nuova_entita_calcolata(info_calcolo: info_calcolo, is_alias: true)
                res_dn_entita_create << dn
                # --
              end
            end
            # ==================================================================================================================
          end # calcolo vsData
        end # ciclo su padri
        res_dn_entita_create
      ensure
        info_calcolo.multi = multi_orig
      end

      # def gestisci_calcolo_entita_multi_errore_totale(fase:, meta_entita:)
      def gestisci_calcolo_entita_multi_errore_totale(info_calcolo:)
        # comportamento = vendor_instance.comportamento_errore_totale_multi[info_calcolo.fase]
        comportamento = vendor_instance.determina_comportamento_errore_totale_multi(info_calcolo: info_calcolo)
        if comportamento.tipo_segnalazione
          nuova_segnalazione(comportamento.tipo_segnalazione,
                             dist_name_padre: info_calcolo.dist_name_padre,
                             meta_entita:     info_calcolo.nome_meta_entita,
                             cella:           info_calcolo.nome_cella,
                             naming_path:     info_calcolo.naming_path)
        end
        raise "Errore in calcolo di tutte le entita' di una multistanziata (#{info_calcolo.naming_path})" if comportamento.abort?
        comportamento
      end

      # def gestisci_assenza_regole_calcolo_entita(fase:, meta_entita:, nome_cella: nil, nome_cella_adiacente: nil)
      def gestisci_assenza_regole_calcolo_entita(info_calcolo:)
        # comportamento = vendor_instance.comportamento_assenza_regole_calcolo_entita[info_calcolo.fase]
        comportamento = vendor_instance.determina_comportamento_assenza_regole_calcolo_entita(info_calcolo: info_calcolo)
        raise "Regole di calcolo assenti per meta_entita: #{info_calcolo.meta_entita.naming_path}" if comportamento.nil? || comportamento.abort?
        unless comportamento.ok? || info_calcolo.fase == FASE_CALCOLO_PI_ALIAS
          logger.warn("#{@log_prefix}, regole assenti per meta_entita (#{info_calcolo.naming_path}), (cella: #{info_calcolo.nome_cella}, cella_adiacente: #{info_calcolo.nome_cella_adiacente})")
        end
        if comportamento.tipo_segnalazione
          nuova_segnalazione(comportamento.tipo_segnalazione,
                             dist_name_padre: info_calcolo.dist_name_padre,
                             meta_entita:     info_calcolo.nome_meta_entita,
                             cella:           info_calcolo.nome_cella,
                             naming_path:     info_calcolo.naming_path)
        end
        comportamento
      end

      # ---------------------------------------------------------------------------
      # util varie

      def calcolo_alias?
        vendor_instance.calcolo_alias?
      end

      def celle_adiacenti(cella)
        adiacenze = { TIPO_ADIACENZA_INTERNA => {}, TIPO_ADIACENZA_ESTERNA => {} }
        (cella[CAMPO_CELLA_PR_ADJS] || []).each_slice(2).each do |hdr, nome_cella_adiacente|
          cella_adj = @celle_progetto_radio[nome_cella_adiacente]
          if cella_adj.nil?
            nuova_segnalazione(TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ADIACENTE_INESISTENTE, nome_cella: cella[CAMPO_CELLA_PR_NOME_CELLA], cella_adiacente: "#{hdr} = #{nome_cella_adiacente}")
            next
          end
          tp = cella[@pr_key_check_adj] == cella_adj[@pr_key_check_adj] ? TIPO_ADIACENZA_INTERNA : TIPO_ADIACENZA_ESTERNA
          adiacenze[tp][hdr] = cella_adj
        end
        adiacenze
      end

      def naming_path_padre(naming_path)
        naming_path.split(NAMING_PATH_SEP)[0..-2].join(NAMING_PATH_SEP)
      end

      def dist_name_padre(dist_name)
        dist_name.to_s.split(DIST_NAME_SEP)[0..-2].join(DIST_NAME_SEP)
      end

      def nome_entita(dist_name)
        dist_name.to_s.split(DIST_NAME_VALUE_SEP).last
      end

      def nome_entita_padre(dist_name)
        nome_entita(dist_name_padre(dist_name))
      end

      def costruisci_dist_name(dist_name_padre, nome_meta_entita, nome_entita)
        s = dist_name_padre.nil? ? '' : (dist_name_padre + DIST_NAME_SEP)
        s << nome_meta_entita << DIST_NAME_VALUE_SEP << nome_entita
      end

      def crea_entita(info_calcolo:, parametri:, id_entita_padre: nil)
        record_fields = {}
        record_fields[:pid]           = id_entita_padre
        record_fields[:livello]       = info_calcolo.meta_entita.livello
        record_fields[:nodo]          = saa.sistema.nodo_naming_path.include?(info_calcolo.naming_path)
        record_fields[:dist_name]     = info_calcolo.dist_name_entita
        record_fields[:meta_entita]   = info_calcolo.nome_meta_entita
        record_fields[:naming_path]   = info_calcolo.naming_path
        record_fields[:valore_entita] = info_calcolo.nome_entita
        record_fields[:extra_name]    = Db::MetaEntita.calcola_extra_name(me_extra_name: info_calcolo.meta_entita.extra_name, parametri: parametri)
        record_fields[:parametri]     = parametri
        record_fields[:nodo_id]       = determina_nodo_id(record_fields)
        record_fields[:version]       = (record_fields[:nodo_id] || record_fields[:nodo] == true) ? info_calcolo.release_nodo : nil
        x = Db::Entita::Record.new(record_fields)
        x.avvalora_campi_adiacenza(vendor_instance)
        x
      end

      def determina_nodo_id(hash = {})
        return nil if hash[:nodo] == true # E' lei stessa un nodo

        nodo_np = saa.sistema.nodo_naming_path.detect { |np| hash[:naming_path].index(np) == 0 }
        return nil if nodo_np.nil? # Non e' figlia di nodo

        dist_name_nodo = hash[:dist_name].split(DIST_NAME_SEP).take(nodo_np.count(NAMING_PATH_SEP) + 1).join(DIST_NAME_SEP)
        cache_entita[:entita_create][dist_name_nodo]
      end

      # def calcola_extra_name(meta_entita:, parametri:)
      #   meta_entita[:extra_name] ? meta_entita[:extra_name].split(EXTRA_NAME_SEP).map { |mp| parametri[mp] }.join(EXTRA_NAME_SEP) : nil
      # end

      def nuova_entita_per_loader(entita_record:, info_calcolo:, is_alias: false)
        begin
          @stats[:entita_create] += 1
          @loader << entita_record
        rescue => e
          logger.error("#{@log_prefix} catturata eccezione nel caricare entita #{entita_record.dist_name} nel loader. (#{e})")
          raise e
        end
        cache_entita[:entita_create][entita_record.dist_name] = entita_record.id
        info_calcolo.aggiorna_cache_per_naming_path(is_alias: is_alias)
        entita_record
      end

      def check_cella_in(nome_cella_in)
        cella_in = @celle_progetto_radio[nome_cella_in]
        unless cella_in
          logger.warn("#{@log_prefix}, non esiste la cella '#{nome_cella_in}' in ProgettoRadio")
          nuova_segnalazione(TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_CELLA_INESISTENTE, nome_cella: nome_cella_in)
          return nil
        end
        nome_nodo_in = cella_in[CAMPO_CELLA_PR_NOME_NODO]
        raise "NomeNodo non avvalorato per la cella #{nome_cella_in}" if nome_nodo_in.to_s.empty?
        logger.warn("#{@log_prefix}, release di nodo non specificata per la cella '#{nome_cella_in}'") unless cella_in[CAMPO_CELLA_PR_RELEASE_NODO]
        cella_in
      end

      def nuova_segnalazione(ts, opts = {})
        if opts[:naming_path] # controllo se c'e' naming_path altrimenti le segnalazioni non vanno ignorate (es: inesistenza celle adiacenti)
          k = "#{ts}-#{opts[:naming_path]}-#{opts[:meta_parametro]}"
          # controllo per evitare duplicazioni di segnalazioni ad eccezione di quelle di esecuzione in corso
          return nil if @cache_segnalazioni[k]
          @cache_segnalazioni[k] = (ts != TIPO_SEGNALAZIONE_ESECUZIONE_FUNZIONE_IN_CORSO)
        end
        super(ts, opts)
      end

      # ---------------------------------------------------------------------------
      def progress_msg(num_celle_calcolate:, rate:)
        "#{num_celle_calcolate} celle calcolate, #{@stats[:entita_create]} entita create, #{calcolatore.stats[:regole]} regole, #{calcolatore.stats[:calcoli]} calcoli, #{rate.round(2)} celle/s"
      end

      def esegui(lista_celle:, step_info: 100, **opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        res = { celle_richieste: lista_celle.size }
        funzione = Db::Funzione.get_by_pk(FUNZIONE_PI_CALCOLO)
        saa.con_lock(funzione: funzione.nome, account_id: saa.account_id, mode: LOCK_MODE_READ, **opts.merge(use_pi: false)) do
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: saa.filtro_segnalazioni, attivita_id: opts[:attivita_id]) do
            begin
              con_calcolatore(opts) do
                Irma.gc

                con_cache_celle_progetto_radio(lista_celle) do |cpr|
                  # controllo che dall'applicazione dei filtri negativi non esca un elenco vuoto di celle da calcolare
                  if celle_per_il_calcolo.empty?
                    nuova_segnalazione(TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_NESSUNA_CELLA, release: filtro_release.join(','))
                    break
                  end

                  segnalazione_esecuzione_in_corso("(calcolo di #{@stats[:celle_da_calcolare]} celle, #{@stats[:celle_progetto_radio]} celle di progetto radio caricate, sorgente #{@label_sorgente})")
                  con_cache_archivio_eccezioni do
                    con_cache_parametri_predefiniti(pre_caricamento: (celle_per_il_calcolo.count >= (opts[:precaricamento] || 0))) do
                      res[:loader] = saa.con_loader_entita_pi(funzione: funzione.nome, delta: opts[:delta], account_id: saa.account_id, lock: false, **opts) do |il_loader|
                        @loader = il_loader
                        con_cache_entita(**opts) do
                          calcolo_root(cella: check_cella_in(celle_per_il_calcolo.first))
                          InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
                            celle_per_il_calcolo.each do |nome_cella_in|
                              puts "PROCESSING CELLA: #{nome_cella_in}" if @puts_calcolo
                              next unless (cella = check_cella_in(nome_cella_in))
                              calcolo_cella(cella: cella, pr: cpr)
                              ip.incr { segnalazione_esecuzione_in_corso(progress_msg(num_celle_calcolate: ip.total, rate: ip.rate)) }
                            end # lista_celle
                            @stats[:calcolatore] = calcolatore.stats
                            res[:celle_calcolate] = celle_per_il_calcolo.size
                            res[:summary] = progress_msg(num_celle_calcolate: ip.total, rate: ip.rate)
                            segnalazione_esecuzione_in_corso("(#{res[:summary]}, inizio caricamento db)")
                          end # info_progresso
                          res[:stats] = @stats
                        end # con_cache_entita
                      end # con_loader_entita
                    end # con_cache_parametri_predefiniti
                  end # con_cache_archivio_eccezioni
                end # con_cache_celle_progetto_radio
              end # con_calcolatore
            rescue => e
              res[:eccezione] = "#{e}: #{e.message}"
              logger.error("#{@log_prefix} catturata eccezione (#{res})")
              raise
            ensure
              @loader = nil
            end
            res
          end # con_segnalazioni
          saa.pi.update(count_entita: saa.pi.entita.dataset.count)
        end # saa.con_lock
        res
      end
    end
  end

  module Db
    # extend class
    class SistemaAmbienteArchivio
      def calcolo_da_progetto_radio(**opts)
        Funzioni::CalcoloDaProgettoRadio.new(sistema_ambiente_archivio: self, saa_riferimento: opts[:saa_riferimento], **opts).esegui(**opts)
      end
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      def calcolo_da_progetto_radio(**opts)
        Funzioni::CalcoloDaProgettoRadio.new(sistema_ambiente_archivio: self, saa_riferimento: opts[:saa_riferimento], **opts).esegui(**opts)
      end
    end
  end
end
