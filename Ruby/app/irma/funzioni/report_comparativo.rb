# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20161220
#
require 'irma/cache'
require 'irma/filtro_entita_util'
require_relative 'segnalazioni_per_funzione'

module Irma
  #
  module Funzioni
    # rubocop:disable Metrics/ClassLength
    class ReportComparativo
      include SegnalazioniPerFunzione
      include FiltroEntitaUtil
      #
      class ManagedObjectRepComp < Db::EntitaRepComp::Record
        def initialize(hash = {})
          super(hash)
          @dist_name = hash[:dist_name]
          elabora_dist_name
        end

        def info
          {
            class: 'ManagedObjectRepComp', livello: livello, dist_name: dist_name, esito_diff: esito_diff,
            naming_path: naming_path, meta_entita: meta_entita, fonte_1: fonte_1, fonte_2: fonte_2
          }
        end

        def elabora_dist_name # rubocop:disable Metrics/AbcSize
          return if @dist_name.nil? || @dist_name.empty?
          # dato il dist_name si possono ricavare i seguenti attributi di MO:
          # naming_path
          # meta_entita
          # livello
          arr_dn = @dist_name.split(DIST_NAME_SEP)
          values[:livello] ||= arr_dn.size
          tmp = arr_dn.last.split(DIST_NAME_VALUE_SEP)
          values[:meta_entita] ||= tmp[0]
          values[:valore_entita] ||= tmp[1]
          values[:naming_path] ||= arr_dn.map { |el| el.split(DIST_NAME_VALUE_SEP).fetch(0) }.join(NAMING_PATH_SEP)
        end
      end

      attr_reader :logger, :sistema_ambiente_archivio, :metamodello, :log_prefix, :archivio_1, :archivo_2, :saa_delta, :filtro_metamodello
      alias saa sistema_ambiente_archivio

      def initialize(sistema_ambiente_archivio:, saa_delta:, **opts) # rubocop:disable Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity, Metrics/AbcSize #, Metrics/MethodLength
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        unless saa_delta.is_a?(Db::SistemaAmbienteArchivio) || saa_delta.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro saa_delta '#{saa_delta}' non valido"
        end
        @sistema_ambiente_archivio = sistema_ambiente_archivio
        @saa_delta = saa_delta
        @metamodello = opts[:metamodello] || saa.sistema.metamodello
        @filtro_metamodello = opts[:filtro_metamodello] || {}
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Report Comparativo (#{saa.full_descr} vs #{saa_delta.full_descr})"
        @hash_filtro_wi = {}
      end

      def dataset_1
        @dataset_1 ||= @sistema_ambiente_archivio.dataset(use_pi: @sistema_ambiente_archivio.pi.nil? ? false : true)
      end

      def dataset_2
        @dataset_2 ||= @saa_delta.dataset(use_pi: @saa_delta.pi.nil? ? false : true)
      end

      def table_name_1
        @table_name_1 ||= saa.pi.nil? ? saa.entita.table_name : saa.pi.entita.table_name
      end

      def table_name_2
        @table_name_2 ||= saa_delta.pi.nil? ? saa_delta.entita.table_name : saa_delta.pi.entita.table_name
      end

      def trova_entita_assenti(fonte_idx:, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
        pre_dist_name = 'tmp'
        pre_livello = 0
        first_tn, second_tn = ''
        opts = {}
        if fonte_idx == 1
          first_tn = table_name_1
          second_tn = table_name_2
          opts = { esito_diff: REP_COMP_ESITO_ASSENTE_2, fonte_1: REP_COMP_KEY_PRESENTE, fonte_2: REP_COMP_KEY_ASSENTE }
        end
        if fonte_idx == 2
          first_tn = table_name_2
          second_tn = table_name_1
          opts = { esito_diff: REP_COMP_ESITO_ASSENTE_1, fonte_2: REP_COMP_KEY_PRESENTE, fonte_1: REP_COMP_KEY_ASSENTE }
        end
        query = "select a.dist_name, a.extra_name, a.livello from #{first_tn} a left outer join"
        query += " #{second_tn} b on a.dist_name = b.dist_name where b.dist_name is null order by a.dist_name COLLATE \"C\", a.livello"
        saa.dataset.db.transaction do
          saa.dataset.db[query].select([:dist_name, :livello, :extra_name]).each do |row|
            dist_name = row[:dist_name]
            livello = row[:livello]
            if livello == 1 # se la root e' assente significa che un archivio e' vuoto
              yield ManagedObjectRepComp.new(opts.merge(dist_name: dist_name))
              break
            end
            if livello >= pre_livello && !dist_name.start_with?(pre_dist_name + DIST_NAME_SEP) # se aumento di livello inserisco nella lista finale solo se si tratta di una entita non figlia
              yield ManagedObjectRepComp.new(opts.merge(dist_name: dist_name, extra_name: row[:extra_name]))
              pre_dist_name = dist_name # diventa un dist_name padre
              pre_livello = livello
            end
            next if livello >= pre_livello
            yield ManagedObjectRepComp.new(opts.merge(dist_name: dist_name, extra_name: row[:extra_name]))
            pre_dist_name = dist_name
            pre_livello = livello
          end
        end
      end

      def trova_entita_uguali(&_block)
        query = "select a.dist_name dist_name, a.extra_name as ex1, b.extra_name as ex2 from #{table_name_1} a join #{table_name_2} b on a.dist_name=b.dist_name"
        query += " where (coalesce(a.version, '') = coalesce(b.version, '')) and a.parametri::jsonb = b.parametri::jsonb"
        dataset_1.db.transaction do
          dataset_1.db[query].select([:dist_name, :ex1, :ex2]).each do |row|
            yield ManagedObjectRepComp.new(dist_name: row[:dist_name], fonte_1: REP_COMP_KEY_PRESENTE, fonte_2: REP_COMP_KEY_PRESENTE, esito_diff: REP_COMP_ESITO_UGUALE,
                                           extra_name: row[:ex2] || row[:ex1])
          end
        end
      end

      def trova_entita_differenti(&_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # le entita possono differire su version e paramerti
        query = 'select a.dist_name, a.extra_name as ex1, b.extra_name as ex2, a.naming_path, a.version as v1, a.parametri as p1, b.version as v2, b.parametri as p2'
        query += " from #{table_name_1} a join #{table_name_2} b on a.dist_name=b.dist_name"
        query += " where coalesce(a.version, '') != coalesce(b.version, '') or a.parametri::jsonb!=b.parametri::jsonb"
        indici_fonte = [fonte1 = 1, fonte2 = 2]
        dataset_1.db.transaction do
          dataset_1.db[query].select([:dist_name, :ex1, :ex2, :naming_path, :v1, :p1, :v2, :p2]).each do |row|
            fonte = {}
            indici_fonte.each { |f| fonte[f] = {} }

            # controllo versione
            # unless row[:v1] == row[:v2]
            fonte[fonte1][:version] = row[:v1]
            fonte[fonte2][:version] = row[:v2]
            # end

            parametri = { fonte1 => row[:p1] || {}, fonte2 => row[:p2] || {} }

            unless parametri[fonte1] == parametri[fonte2]
              indici_fonte.each { |f| fonte[f][:parametri] = {} }

              # vanno elencati solamente i parametri con valorizzazioni differenti
              # per i parametri strutturati, se c'e' una modifica in un parametro della struttura, devo comunque salvare tutti i parametri della struttura
              # per consentirne l'export FU e quindi li metto tutti
              #
              if @metamodello.meta_parametri_strutturati[row[:naming_path]]
                mp_struct = {}
                indici_fonte.each { |f| mp_struct[f] = {} }
                @metamodello.meta_parametri_strutturati[row[:naming_path]].each do |mp|
                  indici_fonte.each do |f|
                    mp_struct[f][mp] = parametri[f][mp] || REP_COMP_KEY_ASSENTE
                    parametri[f].delete(mp)
                  end
                end
                indici_fonte.each { |f| fonte[f][:parametri] = mp_struct[f] } unless mp_struct[fonte1] == mp_struct[fonte2]
              end
              #
              # parametri con valorizzazioni differenti tra fonte 1 e 2
              #
              parametri[fonte1].each do |param, val|
                next if parametri[fonte2][param] == val
                fonte[fonte1][:parametri][param] = val
                fonte[fonte2][:parametri][param] = parametri[fonte2][param] || REP_COMP_KEY_ASSENTE
              end

              parametri[fonte2].each do |param, val|
                # ignoro tutti i parametri presenti in fonte1 (li ho gia' controllati)
                next if parametri[fonte1][param]
                fonte[fonte1][:parametri][param] = REP_COMP_KEY_ASSENTE
                fonte[fonte2][:parametri][param] = val
              end
            end
            yield ManagedObjectRepComp.new(dist_name: row[:dist_name], fonte_1: fonte[fonte1], fonte_2: fonte[fonte2], esito_diff: REP_COMP_ESITO_DIFFERENZE, extra_name: row[:ex2] || row[:ex1])
          end
        end
      end

      def nuova_entita_per_loader(loader, entita, res, step_progresso, ip)
        loader << entita
        res[:entita][entita.esito_diff] += 1
        res[:totale] += 1
        segnalazione_esecuzione_in_corso("(inserite #{res[:totale]} entità)") if step_progresso > 0 && ((res[:totale] % step_progresso) == 0)
        ip.incr
        entita
      end

      def con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_REPORT_COMPARATIVO, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), **opts) do |_locks1|
          saa.con_lock(mode: LOCK_MODE_READ, use_pi: true, **opts) do |_locks2|
            saa_delta.con_lock(mode: LOCK_MODE_READ, use_pi: true, **opts, &block)
          end
        end
      end

      def aggiungi_entita(mo, res, step_progresso, ip, loader) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        naming_path = mo.values[:naming_path]
        if filtro_metamodello.empty?
          nuova_entita_per_loader(loader, mo, res, step_progresso, ip)
          res[:generato_con_filtro_metamodello] = false
        elsif filtro_metamodello.keys.include?(naming_path)
          res[:generato_con_filtro_metamodello] = true
          filtro_params = filtro_metamodello[naming_path][FILTRO_MM_PARAMETRI]
          condizione_filtro = mo.values[:fonte_1].is_a?(Hash) && mo.values[:fonte_1][:parametri] && (param_keys = mo.values[:fonte_1][:parametri].keys) && filtro_params
          if condizione_filtro && filtro_params.empty?
            [mo.values[:fonte_1], mo.values[:fonte_2]].each { |f| f.delete(:parametri) }
          elsif condizione_filtro && filtro_params != [META_PARAMETRO_ANY]
            param_keys.each do |param|
              next if filtro_params.include?(param)
              mo.values[:fonte_1][:parametri].delete(param)
              mo.values[:fonte_2][:parametri].delete(param)
            end
          end
          if filtro_metamodello[naming_path][FILTRO_MM_ENTITA].nil?
            nuova_entita_per_loader(loader, mo, res, step_progresso, ip)
          else
            entita_ok = false
            feu_naming_path_per_livello(naming_path: naming_path, filtro_np: filtro_metamodello[naming_path]).each.with_index do |dn_list, idx|
              break if entita_ok
              next if dn_list.nil? || dn_list.empty?
              dn_list = dn_list.uniq
              if idx == 0 && dn_list.include?(mo.values[:dist_name])
                entita_ok = true
                break
              end
              dn_list.each do |dn|
                next unless mo.values[:dist_name].include?("#{dn}#{DIST_NAME_SEP}")
                entita_ok = true
                break
              end
            end
            hfwi = (@hash_filtro_wi[naming_path] ||= get_hash_filtro_wi(filtro_metamodello[naming_path] || {}))
            nuova_entita_per_loader(loader, mo, res, step_progresso, ip) if entita_ok && feu_tengo?(mo.values[:dist_name], hfwi || {})
          end
        end
      end

      def esegui(step_info: 10_000, **opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        res = { entita: Hash.new(0), totale: 0 }
        step_progresso = opts[:step_progresso] || 100_000
        funzione = Db::Funzione.get_by_pk(opts[:funzione])
        con_lock(funzione: funzione.nome, account_id: saa.account_id, id: saa.rc.id, **opts) do |_locks|
          fs = saa.filtro_segnalazioni.dup
          %i(archivio progetto_irma_id).each { |k| fs.delete(k) }
          fs[:report_comparativo_id] = saa.rc.id
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: fs, attivita_id: opts[:attivita_id]) do
            Irma.gc
            res[:loader] = saa.con_loader_entita_rc(funzione: funzione.nome, account_id: saa.account_id, lock: false, **opts) do |loader|
              InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
                begin
                  if dataset_1.count > 0 && dataset_2.count > 0
                    [1, 2].each do |idx|
                      trova_entita_assenti(fonte_idx: idx) { |mo| aggiungi_entita(mo, res, step_progresso, ip, loader) }
                    end
                    methods = %i(trova_entita_differenti)
                    methods << 'trova_entita_uguali'.to_sym if opts[:flag_presente]
                    methods.each do |method|
                      send(method) { |mo| aggiungi_entita(mo, res, step_progresso, ip, loader) }
                    end
                  else # uno dei due archivi e' vuoto
                    [[saa, dataset_1], [saa_delta, dataset_2]].each do |s, ds|
                      ts = saa.is_a?(Db::OmcFisicoAmbienteArchivio) ? TIPO_SEGNALAZIONE_REPORT_COMPARATIVO_OMC_FISICO_DATI_NON_PRESENTI : TIPO_SEGNALAZIONE_REPORT_COMPARATIVO_DATI_NON_PRESENTI
                      nuova_segnalazione(ts, nome_archivio: s.pi ? s.pi.nome : s.archivio, descr: s.sistema.full_descr) if ds.count == 0
                    end
                  end
                rescue => e
                  res[:eccezione] = "#{e}: #{e.message} - nella rescue di begin"
                  logger.error("#{@log_prefix} catturata eccezione (#{res})")
                  raise
                end
                segnalazione_esecuzione_in_corso("(aggiornamento di #{res[:totale]} entità completato, inizio caricamento db)")
                res[:msg] = 'caricamento eseguito'
                res
              end
            end # saa.con_loader_entita_rc
            saa.rc.update(count_entita: saa.rc.entita.dataset.count)
            res
          end # con_segnalazioni
        end # con_lock
        res
      end
    end
  end

  #
  module Db
    # extend class
    class SistemaAmbienteArchivio
      def esegui_report_comparativo(saa_delta:, **opts)
        opts.update(funzione: FUNZIONE_REPORT_COMPARATIVO)
        Funzioni::ReportComparativo.new(sistema_ambiente_archivio: self, saa_delta: saa_delta, **opts).esegui(**opts)
      end
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      def esegui_report_comparativo(saa_delta:, **opts)
        opts.update(funzione: FUNZIONE_REPORT_COMPARATIVO_OMC_FISICO)
        Funzioni::ReportComparativo.new(sistema_ambiente_archivio: self, saa_delta: saa_delta, **opts).esegui(**opts)
      end
    end
  end
end
