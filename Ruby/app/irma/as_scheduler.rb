# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini, G. Cristelli
#
# Creation date: 20160606
#

require 'concurrent'
require 'rufus-scheduler'

module Irma
  #
  DEFAULT_SCHEDULER_SLAVE_POOL_SIZE = [2, Concurrent.processor_count / 2].max
  ESECUZIONE_ESITO_OK = 'OK'.freeze
  ESECUZIONE_ESITO_KO = 'KO'.freeze
  MAX_CARICO = 1_000_000

  #
  module AsSchedulerUtil
    def coda_attivita(nome)
      PREFIX_CODA_ATTIVITA_ASSEGNATE + nome
    end

    def connect_redis
      @redis ||= Redis.connect
    end

    def redis
      connect_redis
    end

    def disconnect_redis
      return nil unless @redis
      @redis.client.disconnect
      @redis = nil
    end

    def main_loop(sleep_time:, mini_sleep: 0.1)
      @logger.info("#{log_prefix} inizio main loop")
      until @stop
        yield if block_given?
        counter = 0
        sleep(mini_sleep) while ((counter += mini_sleep) <= sleep_time) && !@stop
      end
      @logger.info("#{log_prefix} fine main loop")
    rescue => e
      @logger.error("#{log_prefix} fine main loop con eccezione #{e}, backtrace: #{e.backtrace}")
    end

    def stop_ensure
      esegui_con_rescue(msg: "uscita da 'stop' (disconnect_redis)") { disconnect_redis }
    end

    def stop(sleep_seconds: 0.1, max_wait_seconds: 10) # rubocop:disable Metrics/AbcSize
      @logger.info("#{log_prefix} inizio stop main thread (attesa massima #{max_wait_seconds} secondi)")
      @stop = true
      max_time = Time.now + max_wait_seconds
      sleep(sleep_seconds) while running? && (Time.now < max_time)
    rescue => e
      @logger.error("#{log_prefix} stop fallito con eccezione #{e}, backtrace: #{e.backtrace}")
    ensure
      stop_ensure
      if @thread
        esegui_con_rescue(msg: "uscita da 'stop' (kill main thread)") { Thread.kill(@thread) }
        @thread = nil
      end
      @logger.info("#{log_prefix} fine stop main thread")
    end

    def log_prefix
      "#{self.class} #{@nome}"
    end

    def esegui_con_rescue(msg:, log_level: :warn)
      yield
    rescue => e
      @logger.send(log_level, "#{log_prefix} #{msg}, eccezione: #{e}" + ((e.to_s =~ /Error connecting to Redis/) ? '' : ", backtrace: #{e.backtrace}"))
    end
  end

  #
  class AsSchedulerSlave # rubocop:disable Metrics/ClassLength
    include AsSchedulerUtil
    #
    class Info
      attr_reader :server, :host, :data_inizializzazione, :pool_size
      attr_accessor :data_ultimo_aggiornamento, :numero_attivita_in_carico, :peso_attivita_in_carico, :numero_attivita_in_esecuzione, :peso_attivita_in_esecuzione, :esecutore
      attr_accessor :totale_attivita_prese_in_carico, :totale_attivita_eseguite

      def initialize(server:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        @server = server
        @host = opts[:host] || Irma.host_ip
        @data_inizializzazione = opts[:data_inizializzazione] || Time.now
        @data_ultimo_aggiornamento = opts[:data_ultimo_aggiornamento] || Time.now
        @numero_attivita_in_carico = opts[:numero_attivita_in_carico] || 0
        @peso_attivita_in_carico = opts[:peso_attivita_in_carico] || 0
        @numero_attivita_in_esecuzione = opts[:numero_attivita_in_esecuzione] || 0
        @peso_attivita_in_esecuzione = opts[:peso_attivita_in_esecuzione] || 0
        @totale_attivita_prese_in_carico = opts[:totale_attivita_prese_in_carico] || 0
        @totale_attivita_eseguite = opts[:totale_attivita_eseguite] || 0
        @esecutore = opts[:esecutore] || "#{@server}:#{@host}:#{Process.pid}:#{Thread.current.object_id}"
        @pool_size = opts[:pool_size]
      end

      def self.crea_da_json(js)
        new(JSON.parse(js).symbolize_keys)
      end

      def to_hash
        {
          server: server, host: host, esecutore: esecutore, pool_size: pool_size, data_inizializzazione: data_inizializzazione, data_ultimo_aggiornamento: data_ultimo_aggiornamento,
          numero_attivita_in_carico: numero_attivita_in_carico, peso_attivita_in_carico: peso_attivita_in_carico,
          numero_attivita_in_esecuzione: numero_attivita_in_esecuzione, peso_attivita_in_esecuzione: peso_attivita_in_esecuzione,
          totale_attivita_prese_in_carico: totale_attivita_prese_in_carico, totale_attivita_eseguite: totale_attivita_eseguite
        }
      end

      def to_json
        to_hash.to_json
      end
    end

    attr_reader :nome, :slave_pool_size, :running

    def init_slave_pool(opts = {}) # rubocop:disable Metrics/AbcSize
      unless @slave_pool
        @logger.info("#{log_prefix} inizializzazione degli slave pool")
        @slave_pool = {}
        Constant.values(:scheduler_pool).each do |pool_name|
          @slave_pool[pool_name] = Concurrent::FixedThreadPool.new(opts[:pool_size] || @slave_pool_size)
          @logger.info("#{log_prefix} slave pool '#{pool_name}' definito con " \
                       "min_threads = #{@slave_pool[pool_name].min_length}, max_threads = #{@slave_pool[pool_name].max_length}, max_queue = #{@slave_pool[pool_name].max_queue}")
        end
        @logger.info("#{log_prefix} #{@slave_pool.size} slave pool inizializzati")
      end
      @slave_pool
    end

    def reset_slave_pool
      if @slave_pool
        @logger.info("#{log_prefix} inizio reset degli slave pool (#{@slave_pool.size})")
        @slave_pool.each do |pool_name, pool|
          @logger.info("#{log_prefix} shutdown dello slave pool '#{pool_name}'")
          pool.shutdown
          pool.wait_for_termination
        end
        @logger.info("#{log_prefix} reset degli slave pool completato")
        @slave_pool = nil
      end
      self
    end

    def initialize(nome:, **opts) # rubocop:disable Metrics/AbcSize
      raise "Nome server non valido per #{self.class}" if nome.to_s.empty?
      @nome = nome
      @stop = false
      @logger = opts[:logger] || Irma.logger
      @slave_pool_size = opts[:slave_pool_size] || ENV['IRMA_SCHEDULER_SLAVE_POOL_SIZE'] || DEFAULT_SCHEDULER_SLAVE_POOL_SIZE
      @attivita = { in_carico: Concurrent::Hash.new, in_esecuzione: Concurrent::Hash.new, totale_prese_in_carico: Concurrent::AtomicFixnum.new, totale_eseguite: Concurrent::AtomicFixnum.new }
      reset_slave_pool
      @thread = nil
      @info = Info.new(server: @nome, host: opts[:host], esecutore: opts[:esecutore], pool_size: @slave_pool_size, data_inizializzazione: opts[:data_inizializzazione])
    end

    def esecutore
      info.esecutore
    end

    def attivita_in_carico
      @attivita[:in_carico]
    end

    def attivita_in_esecuzione
      @attivita[:in_esecuzione]
    end

    def aggiorna_attivita_in_carico(att)
      attivita_in_carico[att.id] = att
      @attivita[:totale_prese_in_carico].increment
    end

    def aggiorna_attivita_in_esecuzione(att)
      attivita_in_esecuzione[att.id] = att
      @attivita[:totale_eseguite].increment
    end

    def attivita_eseguita(att)
      attivita_in_esecuzione.delete(att.id)
      attivita_in_carico.delete(att.id)
    end

    def totale_attivita_prese_in_carico
      @attivita[:totale_prese_in_carico].value
    end

    def totale_attivita_eseguite
      @attivita[:totale_eseguite].value
    end

    def peso_attivita_in_carico
      _peso_attivita(:in_carico)
    end

    def peso_attivita_in_esecuzione
      _peso_attivita(:in_esecuzione)
    end

    def running?
      (@running && @thread) ? true : false
    end

    def attivita_queue
      @attivita_queue ||= coda_attivita(nome).freeze
    end

    def redis_key
      @redis_key ||= (PREFIX_REDIS_KEY_SCHEDULER_SLAVE + nome).freeze
    end

    def info
      @info.numero_attivita_in_carico = attivita_in_carico.size
      @info.peso_attivita_in_carico = peso_attivita_in_carico
      @info.numero_attivita_in_esecuzione = attivita_in_esecuzione.size
      @info.peso_attivita_in_esecuzione = peso_attivita_in_esecuzione
      @info.totale_attivita_prese_in_carico = totale_attivita_prese_in_carico
      @info.totale_attivita_eseguite = totale_attivita_eseguite
      @info
    end

    def gestisci_messaggio(message) # rubocop:disable Metrics/AbcSize
      att = Db::Attivita.find(id: message.to_i)
      raise "L'attivita' con id=#{message} non esiste nel db" unless att
      @logger.info("#{log_prefix} attivita con id #{att.id} (#{att.descr}) ricevuta in stato #{att.stato}, inizio presa in carico")
      begin
        att.prendi_in_carico!
        aggiorna_attivita_in_carico(att)
      rescue
        raise "L'attivita' (#{message}) non può essere presa in carico (#{att.stato})"
      end
      @logger.info("#{log_prefix} attivita con id #{att.id} (#{att.descr}) in post per l'esecuzione allo slave pool '#{att.scheduler_pool}'")
      @slave_pool[att.scheduler_pool].post do
        esegui_attivita(att)
      end
      att
    end

    def stop_ensure
      esegui_con_rescue(msg: "uscita da 'stop' (reset_slave_pool)") { reset_slave_pool }
      esegui_con_rescue(msg: "uscita da 'stop' (remove redis key #{redis_key})") { redis.del(redis_key) }
      super
    end

    def start(redis_key_expire: 60, redis_key_update: 0.1, # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
              max_redis_key_update: 15, **_opts)
      return @thread if running?
      return nil if @stop
      @logger.info("#{log_prefix} inizio start main thread (redis_key_update: #{redis_key_update})")
      @stop = false
      connect_redis
      @thread = Thread.new do
        begin
          init_slave_pool

          Irma.subscribe(attivita_queue, blocking: false) do |_channel, message|
            begin
              gestisci_messaggio(message)
              yield(message, res) if block_given?
            rescue => e
              @logger.warn("#{log_prefix} gestione messaggio '#{message}' fallita: #{e}, #{e.backtrace}")
            end
          end

          @running = true
          last_info = nil

          main_loop(sleep_time: redis_key_update) do
            if (last_info != info.to_json) || (info.data_ultimo_aggiornamento < Time.now - max_redis_key_update)
              esegui_con_rescue(msg: "aggiornamento redis per la chiave #{redis_key} con expire #{redis_key_expire} fallito") do
                @info.data_ultimo_aggiornamento = Time.now
                redis.psetex(redis_key, (redis_key_expire * 1_000).to_i, last_info = @info.to_json)
              end
              esegui_con_rescue(msg: "rimozione redis lock associati a processi non esistenti sull'host") do
                removed_keys = Irma.rimuovi_locks_per_host(redis: redis)
                @logger.info("#{log_prefix} rimosse #{removed_keys.size} chiavi di lock da redis con un process_pid non esistente: #{removed_keys.join(', ')}") unless removed_keys.empty?
              end
            end
          end

          attivita_in_esecuzione.clear
          attivita_in_carico.clear

          Irma.subscribe_exit(attivita_queue)
        rescue => e
          @logger.error("#{log_prefix} uscita da 'start' con eccezione #{e}, backtrace: #{e.backtrace}")
        ensure
          @running = false
          @thread = nil
        end
      end
      sleep(0.01) until @running || @thread.nil?
      @thread
    end

    def esegui_attivita(att)
      att.reload
      aggiorna_attivita_in_esecuzione(att)
      att.esegui
      @logger.info("#{log_prefix} esecuzione attività con id #{att.id} (#{att.descr}) completata con successo (#{att.risultato})")
    rescue => e
      @logger.error("#{log_prefix} esecuzione attività con id #{att.id} (#{att.descr}) fallita: #{e}, #{e.backtrace}")
    ensure
      attivita_eseguita(att)
    end

    # private
    def _peso_attivita(come)
      @attivita[come].values.inject(0) { |acc, elem| acc + elem.peso.to_i }
    end
  end

  # rubocop:disable Metrics/BlockNesting
  class AsSchedulerMaster # rubocop:disable Metrics/ClassLength
    include AsSchedulerUtil
    attr_reader :attivita_schedulate, :indicatore_slave_piu_scarico

    def running?
      @running ? true : false
    end

    def initialize(nome:, **opts)
      @nome = nome
      @logger = opts[:logger] || Irma.logger
      @stop = false
      @thread = nil
      @attivita_schedulate = Concurrent::Hash.new
      # TODO: in attesa di assegnare correttamente il peso alle attivita' si utilizza come indicatore di default il numero delle attivita' e non il peso
      @indicatore_slave_piu_scarico = opts[:indicatore_slave_piu_scarico] || :numero_attivita_in_carico # :peso_attivita_in_carico
    end

    def slave_servers(reset: false)
      @slave_servers = nil if reset
      @slave_servers ||= redis.keys("#{PREFIX_REDIS_KEY_SCHEDULER_SLAVE}*").shuffle.map do |key|
        AsSchedulerSlave::Info.crea_da_json(redis.get(key))
      end
    end

    def slave_piu_scarico(indicatore:)
      min = MAX_CARICO
      found = nil
      slave_servers.each do |slave_info|
        if slave_info.send(indicatore) < min
          min = slave_info.send(indicatore)
          found = slave_info
        end
      end
      found
    end

    def controllo_attivita_con_slave
      esecutori_attivi = slave_servers.collect(&:esecutore)
      Db::Attivita.where(stato: [ATTIVITA_STATO_ASSEGNATA, ATTIVITA_STATO_PRESA_IN_CARICO, ATTIVITA_STATO_IN_ESECUZIONE]).each do |att|
        # att.riconsidera! if !esecutori_attivi.include?(att.esecutore) || att.expired?
        if att.expired?
          att.abort!
        elsif !esecutori_attivi.include?(att.esecutore)
          att.riconsidera!
        end
      end
      self
    end

    def controllo_attivita_schedulate_expired
      # La query di controllo al momento non serve in quanto la gestione viene eseguita dal metodo Attivita#aggiorna_attivita_schedulata
      # richiamato ad ogni aggiornamento di attivita'.
      # 20180828: Eseguiamo la query per sanare la situazione di attivita' figlie di schedulata-cron terminate male
      #           e quindi non in grado di riportare lo stato_operativo della schedulata da IN_ESECUZIONE a SCHEDULATA.
      Db::AttivitaSchedulata.where(stato_operativo: [ATTIVITA_SCHEDULATA_STATO_OPERATIVO_IN_ESECUZIONE]).each do |att|
        next unless att.cron? # per performance controlliamo solo attivita_schedulate di tipo cron
        begin
          attivita_ultimo_run = Db::Attivita.where(attivita_schedulata_id: att.id).where('pid is null').order(Sequel.desc(:id)).first
          next if attivita_ultimo_run && !attivita_ultimo_run.expired?
          att.termina!
        rescue => e
          @logger.error("Controllo per attivita schedulata expired (#{att.id}) eseguito con errore: #{e}")
        end
      end
      self
    end

    def gestisci_attivita_schedulate # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      att_id_gestite = []
      Db::AttivitaSchedulata.where(stato: [ATTIVITA_SCHEDULATA_STATO_ATTIVA, ATTIVITA_SCHEDULATA_STATO_SOSPESA, ATTIVITA_SCHEDULATA_STATO_OBSOLETA])
                            .exclude(stato_operativo: [ATTIVITA_SCHEDULATA_STATO_OPERATIVO_TERMINATA]).each do |att|
        att_id_gestite << att.id
        gestisci_attivita_schedulata(att)
      end
      # cleanup attivita schedulate terminate o annullate
      (@attivita_schedulate.keys - att_id_gestite).each do |att_id|
        att = Db::AttivitaSchedulata.first(id: att_id)
        if att
          rimuovi_attivita_dallo_scheduler(att) if att.terminata? || att.annullata?
        else
          @attivita_schedulate.delete(att_id)
          @logger.warn("#{log_prefix} rimossa dalle attività schedulate l'id #{att_id} non più associato ad alcuna attività")
        end
      end
      self
    end

    def gestisci_attivita_pendenti(pid: nil)
      query = Db::Attivita.where(stato: [ATTIVITA_STATO_PENDENTE]).order(:id) # prima i contenitori !
      query = query.where(pid: pid) if pid
      query.each do |att|
        gestisci_attivita_pendente(att)
      end
      self
    end

    def start_scheduler(**opts)
      @scheduler ||= Rufus::Scheduler.new(**opts)
    end

    def scheduler
      start_scheduler
    end

    def stop_scheduler
      return nil unless @scheduler
      @logger.info("#{self.class} #{@nome} inizio stop scheduler")
      @scheduler.stop(:kill)
      @logger.info("#{self.class} #{@nome} fine stop scheduler")
      @scheduler = nil
    end

    def stop_ensure
      esegui_con_rescue(msg: "uscita da 'stop' (stop_scheduler)") { stop_scheduler }
      super
    end

    def start(sleep_time: 1) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      sleep_time ||= 1
      return @thread if running?
      @logger.info("#{log_prefix} inizio start main thread (sleep_time: #{sleep_time})")
      connect_redis
      start_scheduler
      @thread = Thread.new do
        @running = true

        main_loop(sleep_time: sleep_time) do
          esegui_con_rescue(msg: 'aggiornamento info slave servers')              { slave_servers(reset: true) }
          esegui_con_rescue(msg: 'controllo attivita con slave fallito')          { controllo_attivita_con_slave }
          esegui_con_rescue(msg: 'controllo attivita schedulate expired fallito') { controllo_attivita_schedulate_expired }
          esegui_con_rescue(msg: 'gestione attivita schedulate fallito')          { gestisci_attivita_schedulate }
          esegui_con_rescue(msg: 'gestione attivita da eseguire fallito')         { gestisci_attivita_pendenti }
        end

        @running = false
        @thread = nil
      end
      sleep(0.01) until @running || @thread.nil?
      @thread
    end

    def ok?
      true
    end

    # hook per gestione runtime (non usato e non testato)
    def gestisci_attivita(att) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      att = Db::Attivita.first(id: att) unless att.is_a?(Db::Attivita)
      return nil unless att
      if att.pendente?
        gestisci_attivita_pendente(att)
      elsif att.terminata_con_successo?
        gestisci_attivita_pendenti(pid: att.pid) unless att.radice?
      elsif att.terminata_con_errore?
        # TODO: implementare il fallimento dell'attivita schedulata
      end
      att
    end

    def gestisci_attivita_pendente(att) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return att unless att.pendente?
      case att.situazione_dipende_da
      when Db::Attivita::DIPENDE_DA_TUTTE_OK
        if att.foglia?
          slave_found = slave_piu_scarico(indicatore: indicatore_slave_piu_scarico)
          if slave_found
            att.assegna!(esecutore: slave_found.esecutore)
            # TODO: implementare l'incremento specifico per gli indicatori, per ora solo il numero di attivita in carico si incrementa di 1
            incremento = indicatore_slave_piu_scarico.to_sym == :numero_attivita_in_carico ? 1 : 10
            slave_found.send("#{indicatore_slave_piu_scarico}=", slave_found.send(indicatore_slave_piu_scarico) + incremento)
            if Irma.publish(coda_attivita(slave_found.server), att.id.to_s).zero?
              @logger.warn("#{log_prefix}, lo slave scheduler #{slave_found.esecutore} non ha ricevuto la pubblicazione di assegnazione dell'attività #{att.id}")
              att.riconsidera!(incr_retry: 0)
            end
          else
            @logger.warn("#{log_prefix}, nessun scheduler slave trovato per l'esecuzione dell'attivita con id #{att.id} (#{slave_servers.size} slaves disponibili)")
          end
        else
          att.inizia_contenitore!
        end
      when Db::Attivita::DIPENDE_DA_IN_CORSO
        # nothing to do
      when Db::Attivita::DIPENDE_DA_CON_KO
        att.dipende_da_con_errore!
      end
      att
    end

    def gestisci_attivita_schedulata(att)
      att.verifica_obsolescenza
      (att.attiva? && att.valida?) ? aggiungi_attivita_allo_scheduler(att) : rimuovi_attivita_dallo_scheduler(att)
    end

    def unschedule_attivita_modifica_periodo(att)
      # se non e' mai stata schedulata o se e' in esecuzione non devo fare nulla
      return self if @attivita_schedulate[att.id].nil? || att.in_esecuzione?
      if @attivita_schedulate[att.id].original.to_s != att.periodo
        @scheduler.unschedule(@attivita_schedulate.delete(att.id))
        # TODO: devo cambiare lo stato operativo prima di darla in pasto ad 'aggiungi_attivita_allo_scheduler' ????
      end
      self
    end

    def aggiungi_attivita_allo_scheduler(att) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      unschedule_attivita_modifica_periodo(att)
      return self if @attivita_schedulate[att.id]
      msg = nil
      msg = "#{log_prefix} schedule dell'attivita con id #{att.id} (#{att.descr}) e periodo '#{att.periodo}'"
      if att.in_esecuzione? && !att.cron?
        @logger.info("#{msg}, già in esecuzione ma non con periodo non cron, inserita nello scheduler come fake job per evitare esecuzioni duplicate")
        @attivita_schedulate[att.id] = scheduler.schedule(0) {}
      else
        att.riconsidera!
        att.schedula!
        @attivita_schedulate[att.id] = scheduler.schedule(att.periodo.to_s) do
          begin
            esegui_attivita_schedulata(att.id)
          rescue => e
            @logger.error("#{msg}, esecuzione attivita schedulata fallita: #{e}")
          end
        end
        @logger.info("#{msg} eseguito (#{@attivita_schedulate.size} totali)")
      end
      self
    rescue => e
      @logger.error("#{msg} fallito: #{e} (#{@attivita_schedulate.size} totali)")
    end

    def rimuovi_attivita_dallo_scheduler(att) # rubocop:disable Metrics/AbcSize
      return self unless @attivita_schedulate[att.id]
      msg = nil
      msg = "#{log_prefix} unschedule dell'attivita con id #{att.id} (#{att.descr}) e periodo '#{att.periodo}'"
      @scheduler.unschedule(@attivita_schedulate.delete(att.id))
      att.annulla! if att.in_attesa? || att.schedulata?
      @logger.info("#{msg} eseguito (#{@attivita_schedulate.size} totali)")
      self
    rescue => e
      @logger.info("#{msg} fallito: #{e} (#{@attivita_schedulate.size} totali)")
    end

    def esegui_attivita_schedulata(att_id) # rubocop:disable Metrics/AbcSize
      att = Db::AttivitaSchedulata.first(id: att_id)
      msg = "#{log_prefix} problemi nell'eseguire l'attivita schedulata con id #{att_id}"
      if att.nil? || ![ATTIVITA_SCHEDULATA_STATO_OPERATIVO_TERMINATA, ATTIVITA_SCHEDULATA_STATO_OPERATIVO_SCHEDULATA].include?(att.stato_operativo)
        msg += att.nil? ? ' (non esistente)' : " (#{att.descr}), stato operativo (#{att.stato_operativo}) incongruente"
        Db::Evento.crea(TIPO_EVENTO_ATTIVITA_SCHEDULATA_NON_ESEGUIBILE, descr: msg)
        @logger.warn(msg)
      else
        begin
          att.esegui!
        rescue => e
          @logger.warn(msg + ", attivita terminata forzatamente, eccezione = #{e}")
          att.annulla!
        end
      end
    end
  end

  #
  class AsScheduler # rubocop:disable Metrics/ClassLength
    include AsSchedulerUtil

    attr_reader :nome, :host, :porta, :descr
    attr_reader :slave, :master, :server
    attr_accessor :logger

    # non viene utilizzato il modulo Singleton per ragioni di test in quanto non sarebbe possibile simulare
    # in piu' thread l'istanziazione di differenti scheduler.
    # Per questo motivo il metodo instance viene definito esplicitamente per mantenere la stessa interfaccia,
    # anche se sara' possibile chiamare il metodo new esplicitamente (cosa non possibile con l'inclusione del modulo).
    def self.instance
      @singleton ||= new
    end

    def running?
      (@running && @thread) ? true : false
    end

    def initialize
      @nome = @server = @slave = @master = nil
      @thread = nil
    end

    def init(nome:, **opts)
      raise "Scheduler già inizializzato con nome #{@nome}" if @nome
      @nome = nome
      @running = false
      @stop = false
      @logger = opts[:logger] || Irma.logger
      @host = opts[:host] || Irma.host_ip
      @porta = (opts[:porta] || 0).to_i
      @descr = opts[:descr]
      self
    end

    def nome
      raise 'Nome dello scheduler non avvalorato' if @nome.to_s.empty?
      @nome
    end

    # solo per test
    def reset
      @nome = nil
      self
    end

    # TODO: aggiungere la creazione del server nel DB a scopo amministrativo per la gui
    def server(create: false)
      @server = Db::Server.first(nome: @nome)
      return @server unless create && !@server
      # @server = DB::Server.create(nome: @nome, host: @host, porta: @porta, descr: @descr)
    end

    def stop_ensure
      esegui_con_rescue(msg: "uscita da 'start' (stop_master)") { stop_master }
      esegui_con_rescue(msg: "uscita da 'start' (stop_slave)") { stop_slave }
      super
    end

    def start(sleep_time: 1, sleep_time_slave: 0.1, sleep_time_master: 1) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return @thread if running?
      @logger.info("#{log_prefix} inizio start main thread (sleep_time: #{sleep_time}, sleep_time_master: #{sleep_time_master}, sleep_time_slave: #{sleep_time_slave})")
      @slave = AsSchedulerSlave.new(nome: nome, host: host, porta: porta, logger: @logger)
      raise 'Impossibile attivare lo scheduler slave' unless @slave.start(redis_key_update: sleep_time_slave)
      @stop = false
      connect_redis
      @thread = Thread.new do
        @running = true
        @thread_id = Thread.current.object_id
        main_loop(sleep_time: sleep_time || 1) do
          esegui_con_rescue(msg: 'errore inatteso nella thread principale') { check_master(sleep_time: sleep_time_master) }
        end

        @running = false
        @thread = nil
      end
      sleep(0.01) until @running || @thread.nil?
      @thread
    end

    def slave_running?
      (@slave && @slave.running?) ? true : false
    end

    def master_running?
      (@master && @master.running?) ? true : false
    end

    def stop_slave
      return unless slave_running?
      @slave.stop
      @slave = nil
    end

    def rimuovi_chiave_scheduler_master
      redis.del(REDIS_KEY_SCHEDULER_MASTER) if redis.get(REDIS_KEY_SCHEDULER_MASTER) == scheduler_master_info
    rescue => e
      @logger.error("#{log_prefix} problemi nella rimozione della key #{REDIS_KEY_SCHEDULER_MASTER}: #{e}")
    end

    def stop_master
      return unless master_running?
      @master.stop
      rimuovi_chiave_scheduler_master
      @master = nil
    end

    def start_master(opts = {})
      return @master if master_running?
      @master = AsSchedulerMaster.new(nome: nome, logger: @logger)
      @master.start(sleep_time: opts[:sleep_time])
    end

    def scheduler_master_info(force = false)
      @scheduler_master_info = nil if force
      @scheduler_master_info ||= { nome: nome, host: host, porta: porta, pid: Process.pid, thread: @thread_id }.to_json
    end

    def check_master(check_sleep: 0.5, sleep_time: 1, expire: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      sleep_time ||= 1
      expire ||= 60

      # @logger.info("#{log_prefix} inizio controllo check_master con sleep_time = #{sleep_time} e expire = #{expire}")
      redis.psetex(REDIS_KEY_SCHEDULER_MASTER, (expire * 1_000).to_i, scheduler_master_info) if (redis.get(REDIS_KEY_SCHEDULER_MASTER) || scheduler_master_info) == scheduler_master_info

      sleep(check_sleep)

      current_master_info = redis.get(REDIS_KEY_SCHEDULER_MASTER)
      # @logger.info("#{log_prefix} controllo current_master_info (#{current_master_info}) con scheduler_master_info (#{scheduler_master_info})")
      if current_master_info != scheduler_master_info
        stop_master
      else
        begin
          start_master(sleep_time: sleep_time)
        rescue => e
          @logger.error("#{log_prefix} start scheduler master fallito: #{e}")
          rimuovi_chiave_scheduler_master
        end
      end
      @master
    end
  end
end
