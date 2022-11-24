# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151206
#

require 'rack'
require 'rack/file'

# rack patch to autoremove temporary files sent with send_file
module Rack
  class File
    # this is body from rack-1.6.4
    # rubocop:disable all
    def each
      F.open(@path, "rb") do |file|
        file.seek(@range.begin)
        remaining_len = @range.end-@range.begin+1
        while remaining_len > 0
          part = file.read([8192, remaining_len].min)
          break unless part
          remaining_len -= part.length

          yield part
        end
      end
    ensure
      FileUtils.rm_f(@path) if Irma.tmp_path?(@path)
    end
    # rubocop:enable all
  end
end

begin
  require 'puma'
rescue LoadError
  require 'webrick'
end
require 'roda'
require 'openssl'

if Irma.as? && !Irma.sse?
  require 'message_bus'
  MessageBus.configure(backend: :memory, chunked_encoding_enabled: true)
end

require 'irma/shared_fs'

module Irma
  module Web
    #
    class App < Roda # rubocop:disable Metrics/ClassLength
      class << self
        attr_accessor :logger, :as_id, :as_descr, :as_port
      end

      use Rack::Session::Cookie, key: WEB_KEY, secret: WEB_SECRET
      use Rack::CommonLogger, (Irma::Command.logger || Irma.logger)

      opts[:root] = ENV['IRMA_WEB_ROOT'] if ENV['IRMA_WEB_ROOT']
      plugin :multi_route
      plugin :sinatra_helpers
      plugin :streaming
      plugin :all_verbs
      plugin :cookies, path: '/'

      def invia_file(f, **opts)
        response.set_cookie('fileDownload', 'true')
        send_file(f, **opts)
      end

      if Irma.as?
        unless Irma.sse?
          use MessageBus::Rack::Middleware
          MessageBus.logger = Irma.logger
        end

        plugin :static, ['/.sencha', '/login/', '/bootstrap.js', '/bootstrap.css', '/ext/', '/app.js', '/app/', '/build/', '/classic', '/resources/', '/Irma', '/common/'], root: ''
        plugin :json
        plugin :caching

        Dir[File.join(__dir__, 'common/*.rb')].each { |f| require f }
        include Common
        Dir[File.join(__dir__, 'routes/*.rb')].each { |f| require f }
      end

      # always require test route
      require File.join(__dir__, 'routes/test.rb')

      include SharedFs::RodaRoute

      route do |r|
        r.multi_route

        if Irma.as?
          r.root do
            r.redirect('/login') unless logged_in
            if ENV['PUTS_FUNZIONI_ACCOUNT'] == '1'
              puts "Funzioni abilitate per l'account #{logged_in.matricola} - #{logged_in.profilo} :"
              logged_in.data[:funzioni_abilitate].each do |f|
                puts format('%-30s: %s', Constant.label(:funzione, f), funzione_abilitata?(f).to_s)
              end
            end
            response.expires 1, public: true, no_cache: true
            File.read(File.join(opts[:root], 'index.html')).gsub('_dc=DC', "_dc=#{Time.now.tv_sec}")
          end
          r.is 'login' do
            r.redirect('/') if logged_in
            # lazy loading session assigning cipher info
            cipher = OpenSSL::Cipher::AES.new(128, :OFB)
            session[:key] = cipher.random_key
            session[:iv] = cipher.random_iv
            response.expires 1, public: true, no_cache: true
            File.read(File.join(opts[:root], 'login.html')).gsub('<LANG>', Irma.get_env('LANG') || 'it').gsub('_dc=DC', "_dc=#{Time.now.tv_sec}")
          end
          r.is 'logout' do
            s = logged_in
            begin
              session.destroy
            rescue => e
              Irma.logger.warn("Unable to destroy web session #{session}: #{e}")
            end
            begin
              s.logout if s
            ensure
              @sess = nil
              r.redirect('/login')
            end
          end
          r.on 'doc', String, method: :get do |path|
            verifica_sessione(r)
            f = File.join(opts[:root], rel_path = File.join('doc', path))
            r.halt([HTTP_CODE_NOT_FOUND, { 'Content-Type' => 'text/html' }, [format_msg(:FILE_NON_TROVATO, path: rel_path)]]) unless File.file?(f)
            invia_file(f, filename: path)
          end
        end
      end

      def logged_in
        @sess ||= session[:session_id] && Db::Sessione.find(session_id: session[:session_id])
      end

      def verifica_sessione(r)
        r.halt([HTTP_CODE_NOT_FOUND, { 'Content-Type' => 'text/html' }, [STATO_SESSIONE_NON_VALIDA]]) unless (@sess = logged_in)
      rescue Sequel::DatabaseConnectionError, Sequel::DatabaseDisconnectError => e
        Irma.logger.error("Problemi nella verifica della sessione: #{e}, #{e.backtrace}")
        r.halt([HTTP_CODE_CUSTOM_SESSION_ERROR, { 'Content-Type' => 'text/html' }, [format_msg(:DB_CONNECTION_ERROR)]])
      end

      def renew_session(force: false, **opts)
        s = logged_in
        return false unless s && s.exists? && (force || (session[:next_renew] && (session[:next_renew] < Time.now)))
        s.renew(**opts)
        session[:next_renew] = Time.now + 60
        true
      end

      def funzione_abilitata?(f)
        logged_in && logged_in.funzione_abilitata?(f)
      end

      def logger
        self.class.logger
      end

      def self.start(options = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        # to handle graceful stop inside code assign @server instance variable during start
        hash = options.dup.merge(app: app, Port: options[:port], environment: options[:env], debug: ENV['RACK_DEBUG'] == '1', quiet: true)
        max_exit_sleep = hash.delete(:max_exit_sleep)
        self.logger = hash[:logger]
        self.as_port = hash[:port]
        self.as_id = hash[:id]
        self.as_descr = hash[:descr]

        Rack::Server.new(Hash[hash.map { |k, v| [k.to_sym, v] }]).start do |srv|
          at_exit do
            App.stop(max_exit_sleep: max_exit_sleep)
          end
          @server = srv
          if Irma.as?
            Irma.logger.info("Starting server with shared_fs #{Irma.shared_fs_url.empty? ? "support using base dir #{Irma.shared_dir}" : "remote on url #{Irma.shared_fs_url}"}")
            ManagerSegnalazioni.instance.start
            start_scheduler
            start_subscribe
          else
            Irma.logger.info("Starting shared_fs server (port=#{as_port})")
          end
        end
      end

      def self.halt
        @stop = true
        if @server
          @server.respond_to?(:halt) ? @server.halt : stop
        end
      rescue => e
        Irma.logger.warn("Unable to halt server correctly: #{e}")
      end

      def self.stop(max_exit_sleep: nil)
        @stop = true
        if Irma.as?
          stop_scheduler
          stop_subscribe(max_exit_sleep: max_exit_sleep)
          ManagerSegnalazioni.instance.stop
        else
          Irma.logger.info("Stopping shared_fs server (port=#{as_port})")
        end
        @server.stop if @server
      rescue => e
        Irma.logger.warn("Unable to stop server correctly: #{e}")
      end

      def self.stop_subscribe(max_exit_sleep: nil)
        Irma.unsubscribe_all(max_wait: max_exit_sleep)
        unless Irma.sse?
          begin
            MessageBus.destroy
          rescue => e
            Irma.logger.warn("Unable to stop message bus correctly: #{e}")
          end
        end
        Irma.logger.info('Server subscribe terminato')
      end

      def self.start_subscribe # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
        ModConfig.load_from_db
        code = []
        unless Irma.sse?
          code = [PUB_ATTIVITA, PUB_APP_CONFIG, PUB_CACHE, PUB_SESSIONI].compact
          if MessageBus::BACKENDS[:memory] && MessageBus.reliable_pub_sub
            MessageBus.reliable_pub_sub.max_backlog_size = 0
            MessageBus.reliable_pub_sub.max_global_backlog_size = 0
          end
        end
        # force assignment for subscribe_exit_message to avoid problems with multithread
        Irma.subscribe_exit_message
        Irma.subscribe(code) do |channel, message|
          begin
            case channel
            when PUB_ATTIVITA, PUB_SESSIONI
              Irma.logger.info("Pubblicazione sulla coda '#{channel}' di un nuovo messaggio: #{message[0..200]}...")
              MessageBus.publish(channel, message)
            when PUB_APP_CONFIG
              Db::AppConfig.ricarica_dal_db(JSON.parse(message)['id'])
            when PUB_CACHE
              klass = class_eval(JSON.parse(message)['klass'])
              klass.load_in_cache(true)
            end
          rescue => e
            Irma.logger.warn("Errore inatteso nella pubblicazione sul channel #{channel} del messaggio #{message}: #{e}")
          end
        end
        Irma.logger.info("Server attivato con pub/sub basato su #{Irma.sse? ? 'SSE' : 'MessageBus'} sulle code #{code}")
      end

      def self.stop_scheduler
        AsScheduler.instance.stop
      end

      def self.start_scheduler # rubocop:disable Metrics/AbcSize
        as = AsScheduler.instance.reset.init(nome: as_id, porta: as_port, descr: as_descr)
        res = as.start(sleep_time_master: (ENV['AS_SLEEP_TIME_MASTER'] || 1).to_f, # 1 fino al momento di utilizzo del pub/sub anche per il master
                       sleep_time_slave: (ENV['AS_SLEEP_TIME_SLAVE'] || 1).to_f,
                       sleep_time: (ENV['AS_SLEEP_TIME'] || 1).to_f)

        Irma.logger.info(res ? "Scheduler #{as_id}:#{as_port} attivato (master = #{as.master_running?}, esecutore slave = #{as.slave.esecutore})" : "Scheduler #{as_id}:#{as_port} non attivato")
      end
    end
  end
end
