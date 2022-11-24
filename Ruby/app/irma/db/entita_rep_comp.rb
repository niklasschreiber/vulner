# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160223
#

#
module Irma
  #
  module Db
    #
    class EntitaRepComp
      # support for export
      include ExportSqlLoader

      TABLE_NAME_PREFIX = 'rc'.freeze
      TABLE_NAME_SEP = '$'.freeze
      NOT_NULL_KEYS = %i(id).freeze

      attr_reader :logger
      attr_reader(*NOT_NULL_KEYS)

      def initialize(opts) # # rubocop:disable Metrics/AbcSize
        NOT_NULL_KEYS.each do |k|
          raise "EntitaRepComp: il valore dell'opzione variable :#{k} (#{opts[k]}) non è valido" if opts[k].to_s.empty?
          instance_variable_set("@#{k}", opts[k])
        end
        @logger = opts[:logger] || Irma.logger
      end

      def con_lock(key: LOCK_KEY_REPORT_COMPARATIVO, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **lock_info.merge(opts), &block)
      end

      def lock_info
        { id: id }
      end

      def db
        Db.connection
      end

      def dataset(table_suffix: nil)
        db[table_name(table_suffix: table_suffix)]
      end

      def copy_into(table_suffix: nil, **opts, &block)
        db.copy_into(table_name(table_suffix: table_suffix), opts, &block)
      end

      def copy_table(table_suffix: nil, **opts, &block)
        db.copy_table(table_name(table_suffix: table_suffix), opts, &block)
      end

      def table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, id.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def index_prefix # # rubocop:disable Metrics/AbcSize
        ['idx', 'rc', id.to_s, Time.now.tv_sec.to_s].compact.join(TABLE_NAME_SEP).downcase
      end

      def create_table(table_suffix: nil, constraints: true)
        db.create_table(table_name(table_suffix: table_suffix), generator: schema)
        create_constraints(table_suffix: table_suffix) if constraints
      end

      def create_constraints(table_suffix: nil)
        t = table_name(table_suffix: table_suffix)
        ip = index_prefix
        db.alter_table(t) do
          add_primary_key [:id],          name: "#{ip}$pk"

          add_index       [:meta_entita], name: "#{ip}$metae_idx"
          add_index       [:dist_name],   name: "#{ip}$distn_uidx", unique: true
          add_index       [:naming_path], name: "#{ip}$naminp_idx"
          add_index       [:esito_diff],  name: "#{ip}$esitod_idx"
        end
      end

      def drop_table(table_suffix: nil)
        db.drop_table(table_name(table_suffix: table_suffix))
      end

      def drop_table?(table_suffix: nil)
        db.drop_table?(table_name(table_suffix: table_suffix))
      end

      SCHEMA = [
        ['Bignum',      :id],
        ['Integer',     :livello,               null: false],
        ['String',      :dist_name,             size: 1024, null: false],
        ['String',      :extra_name,            size: 256],
        ['String',      :meta_entita,           size: 256, null: false],
        ['String',      :naming_path,           size: 1024, null: false],
        ['String',      :valore_entita,         size: 256, null: false],
        ['Integer',     :esito_diff,            null: false],
        ['column',      :fonte_1,               'json'],
        ['column',      :fonte_2,               'json']
      ].freeze

      COLUMNS = SCHEMA.map { |col_cmd| col_cmd[1] }.freeze
      JSON_COLUMNS = SCHEMA.map { |col_cmd| col_cmd[1] if col_cmd[2] == 'json' }.compact.freeze

      #
      class Record
        attr_reader :values
        def initialize(hash = {})
          @values = hash
        end

        def [](k)
          @values[k]
        end

        def []=(k, v)
          @values[k] = v
        end

        COLUMNS.each do |col|
          define_method(col) do
            @values[col]
          end
          define_method("#{col}=") do |v|
            @values[col] = v
          end
        end

        def extra_name=(value)
          @values[:extra_name] = value
        end

        class_eval <<-EOS
        def to_csv(sep = ',')
          [#{COLUMNS.map { |k| JSON_COLUMNS.include?(k) ? "#{k}_to_json" : "@values[:#{k}]" }.join(',')}].join(sep)
        end
        EOS

        private

        def fonte_1_to_json
          @fonte_1_to_json = @values[:fonte_1].to_json
        end

        def fonte_2_to_json
          @fonte_2_to_json = @values[:fonte_2].to_json
        end
      end

      def schema
        db.create_table_generator do
          SCHEMA.each do |col_cmd|
            send(*col_cmd)
          end
        end
      end

      def con_loader(opts = {}, &block)
        Loader.new(entita: self, **{ logger: logger }.merge(opts)).start(**opts, &block)
      end

      # rubocop:disable Metrics/ClassLength
      class Loader
        LOADER_TOTALE_FIELD_SEP = "\t".freeze
        LOADER_TOTALE_COLUMNS = COLUMNS
        LOADER_TOTALE_OPTIONS = "format csv, header false, quote e'\\x01', delimiter E'#{LOADER_TOTALE_FIELD_SEP}', null ''".freeze

        attr_reader :entita, :eliminazione_temp_files, :temp_dir, :lock, :logger
        attr_reader :files, :fd, :cache, :numero_variazioni

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        def initialize(entita:, **opts)
          raise ArgumentError, "Opzione :entita (#{entita}) non valida per il loader" unless entita.is_a?(EntitaRepComp)
          @entita = entita
          @eliminazione_temp_files = opts.fetch(:eliminazione_temp_files, true)
          @lock = opts.fetch(:lock, true)
          @temp_dir = opts[:temp_dir]
          @remove_temp_dir = opts[:temp_dir].nil?
          @files = nil
          @fd = nil
          @cache = nil
          @counter = 0
          @logger = opts[:logger] || Irma.logger
          @log_prefix = "Loader per entita #{entita.table_name}:"
          @loader_time = Time.now.to_s
          @copier = nil
          @numero_variazioni = 0
          @usa_files_temporanei = opts[:usa_files_temporanei]
        end

        def lock_info
          entita.lock_info
        end

        def clear
          # remove global cache
          if @cache
            @cache.each do |_k, c|
              c.remove if c
            end
            @cache.clear
            @cache = nil
          end
          close_fd
          return false unless eliminazione_temp_files
          if @remove_temp_dir && @temp_dir
            FileUtils.rm_rf(@temp_dir)
          elsif @files
            @files.each { |_op, f| FileUtils.rm_rf(f[:name]) }
          end
        end

        # # rubocop:disable Metrics/BlockNesting
        def <<(record)
          record.id = (@counter += 1)

          if @usa_files_temporanei
            @fd[:totale].puts(record.to_csv(LOADER_TOTALE_FIELD_SEP))
          else
            @copier.writeToCopy(s = (record.to_csv(LOADER_TOTALE_FIELD_SEP) << "\n").to_java_bytes, 0, s.length)
          end
          self
        end
        # rubocop:enable all

        def carica_cache # # rubocop:disable Metrics/AbcSize
          res = { n: 0, msg: 'nessun caricamento eseguito' }
          res
        end

        def inizializza_files_temporanei
          unless @files
            @fd = {}
            @files = {}
            @temp_dir ||= Dir.mktmpdir('loader_', Irma.loader_dir)
            @files[:totale] = File.join(@temp_dir, "#{entita.table_name}.totale")
            @fd[:totale] = File.open(@files[:totale], 'w')
          end
          @files
        end

        def esegui_step(res, step_name, &block)
          res[step_name] = Irma.esegui_e_memorizza_durata(logger: @logger, log_prefix: "#{@log_prefix} #{step_name}", &block)
        end

        def start(**opts, &_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          res = { eccezione: nil }
          constraint_sleep = opts.delete(:constraint_sleep) || 0
          entita.con_lock(mode: LOCK_MODE_READ, enable: lock, log_prefix:  @log_prefix, **opts) do |locks|
            res[:locks] = locks
            if @usa_files_temporanei
              esegui_step(res, :caricamento_cache) { carica_cache }
              esegui_step(res, :files_temporanei) { inizializza_files_temporanei }
              esegui_step(res, :processazione) { yield(self) }
              esegui_step(res, :caricamento_db) { processa_files_temporanei }
            else
              temp_table_opts = { table_suffix: 'tmp' }
              begin
                entita.drop_table?(temp_table_opts)
                entita.create_table(temp_table_opts.merge(constraints: false))
                proc_exception = nil
                esegui_step(res, :processazione_e_caricamento_db) do
                  entita.db.con_copier(entita.table_name(temp_table_opts), columns: LOADER_TOTALE_COLUMNS, options: LOADER_TOTALE_OPTIONS) do |c|
                    @copier = c
                    # spawn a new thread to allow use of other database connections, otherwise copier connection will lock everything using db
                    Thread.new do
                      begin
                        yield(self)
                      rescue => e
                        proc_exception = e
                        # ignore error, will be raised outside
                      end
                    end.join
                  end
                  logger.info("#{@log_prefix} creazione indici e constraints sulla tabella temporanea")
                  sleep(constraint_sleep) if constraint_sleep > 0
                  entita.create_constraints(temp_table_opts)
                  { tabella: entita.table_name, modo: :totale, records: @counter }
                end
                raise proc_exception if proc_exception
                entita.db.transaction do
                  entita.db.run("ALTER TABLE #{entita.table_name} RENAME TO #{entita.table_name}$old")
                  entita.db.run("ALTER TABLE #{entita.table_name(temp_table_opts)} RENAME TO #{entita.table_name}")
                end
              ensure
                @copier = nil
                entita.drop_table?(table_suffix: 'old')
                entita.drop_table?(temp_table_opts)
              end
            end
          end
          res
        rescue => e
          @eliminazione_temp_files = false
          res[:eccezione] = "#{e}: #{e.message}"
          logger.error("#{@log_prefix} catturata eccezione (#{res})")
          raise
        ensure
          @usa_files_temporanei = nil
          clear
        end

        def processa_files_temporanei # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          res = { tabella: entita.table_name, modo: nil, records: 0 }
          close_fd
          res[:modo] = :totale
          temp_table_opts = { table_suffix: 'tmp' }
          begin
            entita.drop_table?(temp_table_opts)
            entita.create_table(temp_table_opts.merge(constraints: false))
            if @usa_copy_into # old code
              File.open(@files[:totale], 'r') do |fd_in|
                entita.db.copy_into(entita.table_name(temp_table_opts), columns: LOADER_TOTALE_COLUMNS, options: LOADER_TOTALE_OPTIONS) do
                  res[:records] += 1 if (l = fd_in.gets)
                  l
                end
              end
            else
              entita.db.copy_into_from_file(entita.table_name(temp_table_opts), @files[:totale], columns: LOADER_TOTALE_COLUMNS, options: LOADER_TOTALE_OPTIONS)
              logger.info("#{@log_prefix} creazione indici e constraints  sulla tabella temporanea")
              entita.create_constraints(temp_table_opts)
              res[:records] = @counter
            end
            entita.db.transaction do
              entita.db.run("ALTER TABLE #{entita.table_name} RENAME TO #{entita.table_name}$old")
              entita.db.run("ALTER TABLE #{entita.table_name(temp_table_opts)} RENAME TO #{entita.table_name}")
            end
          ensure
            entita.drop_table?(table_suffix: 'old')
            entita.drop_table?(temp_table_opts)
          end
          res
        end

        def close_fd
          return false unless @fd
          @fd.values.each { |f| f.close if f }
          @fd = nil
          true
        end
      end
    end
  end
end
