# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151119
#

require 'yaml'
require 'sequel'
require 'terminal-table'
require 'erb'

require 'irma/common'
require_relative 'db/config'

#
module Irma
  #
  module Db # rubocop:disable Metrics/ModuleLength
    def self.logger=(new_logger)
      @logger = new_logger
    end

    def self.logger
      @logger
    end

    class DbException < IrmaException; end

    ROOT_DIR     = File.join(File.dirname(__FILE__), '/db')
    MODELS_DIR   = ENV['MODELS_DIR'] || File.join(ROOT_DIR, 'models')
    MIGRATE_DIR  = ENV['MIGRATE_DIR'] || File.join(ROOT_DIR, 'migrate')
    POPULATE_DIR = ENV['POPULATE_DIR'] || File.join(ROOT_DIR, 'populate')
    SCHEMA       = ENV['SCHEMA'] || Irma.full_file_name(Irma.tmp_dir, 'irma_schema.rb')
    SCHEMA_CACHE = ENV['SCHEMA_CACHE'] || Irma.full_file_name(Irma.tmp_dir, 'irma_schema.dump')
    STRUCTURE    = ENV['STRUCTURE'] || Irma.full_file_name(Irma.tmp_dir, 'irma_structure.sql')
    DB_MODELS    = Dir[MODELS_DIR + '/*.rb'].sort.map { |f| File.basename(f).gsub(File.extname(f), '') }

    # Ritorna il nome del file di configurazione del database, il valore di default e' dato dalla variabile di environment
    # <tt>IRMA_DATABASE_CONFIGURATION_FILE</tt>
    def self.database_file
      ENV[ENV_VAR_PREFIX + '_DATABASE_CONFIGURATION_FILE'] ||= Irma.config_file_name('database.yml')
    end

    def self.configurations(force = false)
      @configurations = nil if force
      @configurations ||= YAML.load(ERB.new(File.read(database_file)).result)
    rescue => e
      STDERR.puts "Error loading database configurations from file #{database_file}: #{e}"
      raise
    end

    # Ritorna l'environment da utilizzare, il valore di default e' dato dalla variabile di environment
    # <tt>IRMA_ENV</tt>. Se non definito viene utilizzato +production+
    def self.env(what = nil)
      @env = what.to_s if what
      unless @env
        what ||= Irma.get_env('ENV')
        what ||= 'production'
        @env = what
      end
      @env
    end

    def self.config(what = nil)
      configurations[env(what)] || configurations[env(what).to_sym]
    end

    def self.establish_connection(hash = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      disconnect if hash[:force]
      unless @db
        retries = 1
        begin
          db_config = Config.new(config(hash[:env]))
          @db = Sequel::Model.db = Sequel.connect(db_config.url, max_connections: db_config[:max_connections], fetch_size: hash.fetch(:fetch_size, 10_000))
          special_connection_settings(hash)
          if hash[:load_models]
            # connection.load_schema_cache?(SCHEMA_CACHE)
            @db.tables
            load_models
            model_classes.each(&:load_in_cache) if hash[:load_cache]
          end
        rescue => e
          retries += 1
          retry if retries <= (hash[:max_retries] || 3)
          raise "Error establishing DB connection for url #{conn_url_no_pwd}: #{e}, #{e.backtrace}"
        end
      end
      @db
    end

    def self.disconnect
      @db.disconnect if @db
      self
    rescue
      # ignore error
      self
    ensure
      @db = nil
    end

    def self.production?
      env == 'production'
    end

    def self.connection(hash = {})
      establish_connection(hash)
    end

    def self.conn_url_no_pwd
      (config['url'] || (@db && @db.url) || Config.new(config).url).mask_password
    end

    def self.model_classes
      load_models
      Model.descendants.select(&:name)
    end

    def self.load_models
      require_relative 'db/models'
      # connection.dump_schema_cache?(SCHEMA_CACHE)
    end

    def self.reset_cache
      model_classes.each(&:reset_cache)
    end

    def self.init(hash = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      options = { force: false, env: nil, logger: nil, load_models: true, load_cache: true, log_file_name: nil, sql_log: nil, fetch_size: 10_000 }.merge(hash)
      if options[:force] || !initialized?
        env(options[:env])
        self.logger ||= options[:logger] || Irma.open_logger(options[:log_file_name] || Irma.log_file_name("irma_#{env}.log"), production? ? Logger::INFO : Logger::DEBUG)
        establish_connection(force: options[:force], load_models: options[:load_models], load_cache: options[:load_cache],
                             sql_log: options[:sql_log].nil? ? !production? : options[:sql_log], fetch_size: options[:fetch_size])
      end
      self
    end

    def self.initialized?
      @db ? true : false
    end

    def self.special_connection_settings(hash)
      return unless @db
      @db.loggers = [logger] if logger && hash[:sql_log]
      # since Sequel 4.46.0 this is needed to allow sql literal fragments in where conditions
      @db.extension :auto_literal_strings
      # @db.fetch_size = hash[:fetch_size] || 1_000
      case @db.url
      when /postgres/
        @db.extension :pg_json
        # @db.extension :schema_caching
      end
    end

    def self.actual_migrations
      connection[:schema_migrations].select_map(:filename).sort.reverse
    end

    def self.actual_migration
      actual_migrations.first
    rescue
      nil
    end

    def self.current_migration_version
      actual_migration.to_s.split('_').first
    end

    def self.migrate_status(_hash = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      migrations = { available: Dir[MIGRATE_DIR + '/*.rb'].map { |f| File.basename(f) }.sort.reverse }
      res = nil
      begin
        migrations[:actual] = actual_migrations
      rescue
        res = 'schema_migrations table does not exist yet.'
      end

      unless res
        rows = []
        migrations[:available].each do |m|
          actual = migrations[:actual].delete(m)
          rows << [m, actual ? 'up' : 'down']
        end
        migrations[:actual].each do |m|
          rows << [m, '*** NO FILE ***']
        end
        res = Terminal::Table.new(headings: %w(Filename Stato), rows: rows).to_s
      end
      "database: #{config['database'] || config['username']} (#{env}), #{conn_url_no_pwd}\n#{res}"
    end

    def self.aggiornamento_statistiche(_hash = {})
      # opts = { table_name: nil, percentage: 5, cascade: true, rebuild_indexes: true, skip_index_rebuild_for_partitioned_tables: true}.merge(hash)
      res = case connection.url
            when /postgres/
              Db.connection.run('ANALYZE')
            else
              "Nessun aggiornamento statistiche per la connessione con url #{conn_url_no_pwd}"
            end
      { note: res }
    end

    def self.space_used(_hash = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      case connection.url
      when /postgres/
        t_query = %(
            SELECT relname as tabella, trunc(reltuples) as records, pg_total_relation_size(C.oid)/1024 as size
              FROM pg_class C
         LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
             WHERE nspname NOT IN ('pg_catalog', 'information_schema')
               AND C.relkind <> 'i'
               AND C.relkind <> 'S'
               AND nspname !~ '^pg_toast'
          ORDER BY pg_total_relation_size(C.oid) DESC
        )
        rows = connection.fetch(t_query).map { |r| [r[:tabella], r[:records].to_i, r[:size].to_i] }
        t = Terminal::Table.new(headings: ['Tabella', '# records', 'Spazio (MB)'], rows: rows)
        (1..2).each { |idx| t.align_column idx, :right }
        "Records tabelle:\n" + t.to_s
      else
        "Non calcolato per la connessione con url #{conn_url_no_pwd}"
      end
    end

    # rubocop:disable Metrics/LineLength
    module ExportSqlLoader
      #
      # export/import sql per loader
      #
      EXPORT_RECORD_SEPARATOR = "\n".freeze
      EXPORT_FIELD_SEPARATOR = "\t".freeze

      def esporta_sql_per_loader(fd: nil, change_record_proc: nil, no_primary_key: false, no_timestamps: false, order_by: nil, ignored_fields: [], order_fields: []) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists
        db_schema = db.schema(table_name).to_h
        pk = db_schema.select { |_c, c_info| c_info[:primary_key] }.keys.first
        fd ||= StringIO.new
        n = 0
        ignored_columns = (ignored_fields.map(&:to_sym) + [no_primary_key ? pk : nil] + db_schema.map { |c, c_info| (no_timestamps && c_info[:type] == :datetime) ? c : nil }).compact
        output_columns = (order_fields.map(&:to_sym) + [pk] + (dataset.columns - [pk] - order_fields.map(&:to_sym)).sort - ignored_columns).compact
        # 1. dump header
        header = "COPY #{table_name} (#{output_columns.join(', ')}) FROM stdin;#{EXPORT_RECORD_SEPARATOR}"
        fd.write(change_record_proc ? change_record_proc.call(header) : header)
        # 2. dump data in a transaction to use a cursor
        db.transaction do
          dataset.select(*output_columns).order(order_by || pk).each do |record|
            row = output_columns.map do |c|
              if (v = record[c]).nil?
                '\N'
              else
                (db_schema[c][:type] == :json) ? v.to_json.gsub('\\', '\\\\\\') : v.to_s.gsub(EXPORT_RECORD_SEPARATOR, '\\\n').gsub(EXPORT_FIELD_SEPARATOR, '\\\t')
              end
            end
            rc = row.join(EXPORT_FIELD_SEPARATOR) + EXPORT_RECORD_SEPARATOR
            fd.write(change_record_proc ? change_record_proc.call(rc) : rc)
            n += 1
          end
        end

        # 3. dump footer
        fd.write('\.' + EXPORT_RECORD_SEPARATOR)
        if !no_primary_key && pk && (primary_key_seq = (default_for_pk = db_schema[pk][:default]) && (m = default_for_pk.match(/nextval\('(.*)'/)) && m[1])
          fd.write "#{EXPORT_RECORD_SEPARATOR}SELECT pg_catalog.setval('#{primary_key_seq}', #{max(pk) || 1}, true);#{EXPORT_RECORD_SEPARATOR}"
        end
        if fd.respond_to?(:string)
          fd.close
          fd.string
        else
          n
        end
      end

      def importa_da_sql_per_loader(sql)
        fd = Tempfile.new('sql_per_loader_')
        fd.write(sql)
        fd.close
        `psql --port #{Db.config['port']} --username #{Db.config['username']} #{Db.config['database']} --file #{fd.path} 2>&1`
      ensure
        fd.delete if fd
      end
    end

    EXPORT_FOR_SQL_LOADER = [
      EXPORT_FOR_SQL_LOADER_ANAGRAFICA = 'anagrafica'.freeze,
      EXPORT_FOR_SQL_LOADER_PRN        = 'prn'.freeze,
      EXPORT_FOR_SQL_LOADER_ECCEZIONI  = 'eccezioni'.freeze
    ].freeze

    def self.export_for_sql_loader(what:, fd: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      whats = [what].flatten
      ok = (EXPORT_FOR_SQL_LOADER & whats).sort == whats.sort
      raise "Parametro what (#{what}) non valido per l'export_for_sql_loader (valori ammessi: #{EXPORT_FOR_SQL_LOADER.sort.join(', ')})" unless ok
      raise "Il parametro fd (#{fd}) non supporta i metodi richiesti (:path, :write)" if fd && !(fd.respond_to?(:write) && fd.respond_to?(:path))
      start_time = Time.now
      klasses = whats.map do |w|
        case w
        when EXPORT_FOR_SQL_LOADER_ANAGRAFICA
          [
            Utente, Profilo, Account, AppConfig, Funzione,
            TipoAllarme, TipoAttivita, TipoEvento, TipoSegnalazione,
            Rete, Vendor, VendorRelease, VendorReleaseFisico, OmcFisicoCompleto, OmcFisico, Sistema,
            MetaEntita, MetaEntitaFisico, MetaParametro, MetaParametroFisico, MetaparametroUpdateOnCreate,
            EtichettaEccezioni, EtichettaEccezioniEliminata, MetaparametroSecondario, AttivitaSchedulata
          ]
        when EXPORT_FOR_SQL_LOADER_ECCEZIONI
          Sistema.order(:descr, :rete_id).flat_map { |s| [s.entita(archivio: ARCHIVIO_ECCEZIONI).first, s.entita(archivio: ARCHIVIO_LABEL).first] }
        when EXPORT_FOR_SQL_LOADER_PRN
          [AnagraficaCgi, CiRegione, AnagraficaEnodeb, ProgettoRadio, AnagraficaGnodeb]
        end
      end.flatten
      logger.info("export_for_sql_loader: inizio export #{what} (#{klasses.size} tabelle)" + (fd ? " nel file #{fd.path}" : ''))
      res = fd ? 0 : ''
      klasses.each_with_index do |klass, idx|
        start_time1 = Time.now
        res += klass.esporta_sql_per_loader(fd: fd)
        logger.info("export_for_sql_loader: (#{format('%2d', idx + 1)} / #{klasses.size}) tabella #{klass.table_name} processata in #{(Time.now - start_time1).round(1)} sec.")
      end
      logger.info("export_for_sql_loader: completato export #{what} (#{klasses.size} tabelle) in #{(Time.now - start_time).round(1)} sec." + (fd ? " (#{res} records)" : ''))
      res
    end

    # To include all the DB models without the full namespace prefix
    module Models
      def self.included(_base)
        Db.model_classes.map do |klass|
          const_set(klass.to_s.split(':').last.to_sym, klass)
        end
      end
    end
  end
end

# special general model-like class
unless Irma.shared_fs? && !Irma.as?
  require_relative 'db/entita'
  require_relative 'db/entita_label'
  require_relative 'db/entita_rep_comp'
  require_relative 'db/sistema_ambiente_archivio'
end
