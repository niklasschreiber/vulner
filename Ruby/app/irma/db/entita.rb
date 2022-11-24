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
    # rubocop:disable Metrics/ClassLength
    class Entita
      # support for export
      include ExportSqlLoader

      TABLE_NAME_PREFIX = 'entita'.freeze
      TABLE_NAME_SEP = '$'.freeze
      CONSTANT_KEYS = %i(ambiente archivio vendor rete).freeze
      NOT_NULL_KEYS = %i(omc_logico omc_logico_id).freeze
      KEYS = (CONSTANT_KEYS + NOT_NULL_KEYS).freeze

      attr_reader :logger
      attr_reader(*KEYS)

      def initialize(opts) # rubocop:disable Metrics/AbcSize
        CONSTANT_KEYS.each do |k|
          begin
            instance_variable_set("@#{k}", Constant.constant(k, opts[k]).key.to_s)
          rescue
            raise "Entita: il valore dell'opzione costante :#{k} (#{opts[k]}) non è valido (valori ammessi: #{Constant.values(k).join(', ')})"
          end
        end
        NOT_NULL_KEYS.each do |k|
          raise "Entita: il valore dell'opzione variable :#{k} (#{opts[k]}) non è valido" if opts[k].to_s.empty?
          instance_variable_set("@#{k}", opts[k])
        end
        @logger = opts[:logger] || Irma.logger
      end

      def con_lock(key: LOCK_KEY_AMBIENTE_ARCHIVIO_SISTEMA, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **lock_info.merge(opts), &block)
      end

      def lock_info
        { ambiente: ambiente, archivio: archivio, vendor: vendor, rete: rete, omc_logico: omc_logico, omc_logico_id: omc_logico_id }
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

      def old_table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, ambiente.to_s, archivio.to_s, vendor.to_s, rete.to_s, omc_logico.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, ambiente.to_s, archivio.to_s, omc_logico_id.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def old_index_prefix # rubocop:disable Metrics/AbcSize
        ['e', ambiente.to_s[0..1], archivio.to_s[0..1], vendor.to_s[0..1], rete.to_s[0..1], omc_logico.to_s, Time.now.tv_sec.to_s].compact.join(TABLE_NAME_SEP).downcase
      end

      def index_prefix
        ['e', ambiente.to_s[0..1], archivio.to_s[0..1], omc_logico_id.to_s, Time.now.tv_sec.to_s].compact.join(TABLE_NAME_SEP).downcase
      end

      def create_table(table_suffix: nil, constraints: true)
        return if db.table_exists?(table_name(table_suffix: table_suffix))
        db.create_table(table_name(table_suffix: table_suffix), generator: schema)
        create_constraints(table_suffix: table_suffix) if constraints
      end

      def create_constraints(table_suffix: nil)
        t = table_name(table_suffix: table_suffix)
        ip = index_prefix
        db.alter_table(t) do
          add_primary_key [:id],          name: "#{ip}$pk"
          add_foreign_key [:pid], t,      name: "#{ip}$pid_fk",     on_delete: :cascade
          add_foreign_key [:nodo_id], t,  name: "#{ip}$nodo_fk",    on_delete: :cascade
          # foreign_key indexes not automatically created by the constraint
          add_index       [:pid],         name: "#{ip}$pid_idx"
          add_index       [:nodo_id],     name: "#{ip}$nodo_id_idx"

          add_index       [:meta_entita], name: "#{ip}$metae_idx"
          add_index       [:cella_adiacente], name: "#{ip}$cellaa_idx"
          add_index       [:dist_name],   name: "#{ip}$nodo_idx",   where: 'nodo IS TRUE'
          add_index       [:dist_name],   name: "#{ip}$distn_uidx", unique: true
          add_index       [:naming_path], name: "#{ip}$naminp_idx"
        end
      end

      def drop_table(table_suffix: nil)
        db.drop_table(table_name(table_suffix: table_suffix))
      end

      def drop_table?(table_suffix: nil)
        db.drop_table?(table_name(table_suffix: table_suffix)) || [table_name(table_suffix: table_suffix)]
      end

      def truncate(table_suffix: nil)
        dataset(table_suffix: table_suffix).truncate
      end

      SCHEMA = [
        ['Bignum',      :id],
        ['Bignum',      :pid],
        ['Integer',     :livello,               null: false],
        ['boolean',     :nodo,                  null: false],
        ['Bignum',      :nodo_id],
        ['String',      :dist_name,             size: 1024, null: false],
        ['String',      :version,               size: 64],
        ['String',      :meta_entita,           size: 256, null: false],
        ['String',      :naming_path,           size: 1024, null: false],
        ['String',      :valore_entita,         size: 256, null: false],
        ['String',      :extra_name,            size: 256],
        ['String',      :cella_sorgente,        size: 1024],
        ['String',      :cella_adiacente,       size: 1024],
        ['column',      :parametri,             'json'],
        ['String',      :checksum,              size: 32,  null: false],
        ['DateTime',    :created_at],
        ['DateTime',    :updated_at]
      ].freeze

      COLUMNS = SCHEMA.map { |col_cmd| col_cmd[1] }.freeze
      JSON_COLUMNS = SCHEMA.map { |col_cmd| col_cmd[1] if col_cmd[2] == 'json' }.compact.freeze

      #
      class Record
        attr_reader :values
        def initialize(hash = {})
          @values = hash
          # temporary
          @values[:nodo] ||= false
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

        class_eval <<-EOS
        def to_csv(sep = ',', mode = :crc32)
          checksum(mode)
          [#{COLUMNS.map { |k| JSON_COLUMNS.include?(k) ? "#{k}_to_json" : "@values[:#{k}]" }.join(',')}].join(sep)
        end
        EOS

        def for_insert(mode = :crc32)
          checksum(mode)
          @values[:created_at] = @values[:updated_at] = Time.now.to_s
          [COLUMNS, COLUMNS.map { |k| JSON_COLUMNS.include?(k) ? @values[k].to_json : @values[k] }]
        end

        def checksum(_mode = :crc32)
          # Impostato a 0 in attesa di rimuovere la colonna checksum dalla tabella in quanto non piu' utile nelle elaborazioni
          # (i parametri si possono confrontare direttamente sia in ruby come hash che in postgresql utilizzando l'operatore ::json)
          #  @values[:checksum] ||= calcolo_checksum(mode)
          @values[:checksum] ||= 0
        end

        def calcolo_checksum(mode = :crc32)
          (mode == :md5) ? Digest::MD5.new.hexdigest(string_for_checksum) : Zlib.crc32(string_for_checksum).to_s
        end

        def extra_name=(value)
          @values[:extra_name] = value
        end

        def avvalora_campi_adiacenza(vendor_instance)
          return unless vendor_instance.meta_entita_relazione?(@values[:naming_path])
          cc = vendor_instance.estrai_cs_ca_da_relazione(self)
          return if cc.empty? || cc.size != 2
          @values[:cella_sorgente] = cc[0]
          @values[:cella_adiacente] = cc[1]
        end

        private

        def string_for_checksum
          @values[:version].to_s + parametri_to_json
        end

        def parametri_to_json
          # non server piu' il sort visto che non si calcola il checksum
          # @parametri_to_json = (@values[:parametri] ? @values[:parametri].sort_by_key(true) : @values[:parametri]).to_json
          @parametri_to_json ||= @values[:parametri].to_json
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

      # # rubocop:disable Metrics/ClassLength
      class Loader
        LOADER_TOTALE_RECORD_SEP = "\n".freeze
        LOADER_TOTALE_FIELD_SEP = "\t".freeze
        LOADER_TOTALE_COLUMNS = COLUMNS
        LOADER_TOTALE_OPTIONS = "format csv, header false, quote e'\\x01', delimiter E'#{LOADER_TOTALE_FIELD_SEP}', null ''".freeze

        attr_reader :entita, :delta, :max_variazioni_per_delta, :eliminazione_temp_files, :temp_dir, :lock, :logger
        attr_reader :files, :fd, :cache, :numero_variazioni

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        def initialize(entita:, delta: true, **opts)
          raise ArgumentError, "Opzione :entita (#{entita}) non valida per il loader" unless entita.is_a?(Entita)
          @entita = entita
          @delta = delta ? true : false
          @max_variazioni_per_delta = opts.fetch(:max_variazioni_per_delta, 10_000)
          @eliminazione_temp_files = opts.fetch(:eliminazione_temp_files, true)
          @lock = opts.fetch(:lock, true)
          @temp_dir = opts[:temp_dir]
          @remove_temp_dir = opts[:temp_dir].nil?
          @files = nil
          @fd = nil
          @cache = nil
          @counter = @delta ? entita.dataset.count : 0
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
          @files = nil
        end

        # rubocop:disable Metrics/BlockNesting
        def <<(record)
          record.id = (@counter += 1)
          record.created_at = record.updated_at = @loader_time

          if delta || @usa_files_temporanei
            # TODO: capire come gestire il cambio di :id  per il delta
            @fd[:totale].puts(record.to_csv(LOADER_TOTALE_FIELD_SEP))

            if delta && @cache && (@numero_variazioni < max_variazioni_per_delta)
              unless @cache && @cache[:entita_in_db][record.dist_name] && record.checksum == @cache[:entita_in_db][record.dist_name][1]
                @numero_variazioni += 1
                # TODO: scrivere nel file di variazioni nel formato corretto, aggiungere le variazioni di DELETE alla fine della processazione
                @fd[:delta].puts(@cache[:entita_in_db][record.dist_name] ? "UPDATE: #{record.inspect}" : "INSERT: #{record.inspect}")
              end
            end
          else
            @copier.writeToCopy(s = (record.to_csv(LOADER_TOTALE_FIELD_SEP) << LOADER_TOTALE_RECORD_SEP).to_java_bytes, 0, s.length)
          end
          self
        end
        # rubocop:enable all

        def carica_cache # rubocop:disable Metrics/AbcSize
          res = { n: 0, msg: 'nessun caricamento eseguito' }
          if delta
            @cache = {
              entita_in_db: Cache.instance(key: "#{entita.table_name}_in_db", type: :map_db)
            }
            # NOTE: start a transaction to avoit auto commit set to true, because in PostgreSQL this ignores the fetch_size
            entita.db.transaction do
              entita.dataset.select(:id, :dist_name, :checksum).each do |r|
                @cache[:entita_in_db][r[:dist_name]] = [r[:id], r[:checksum]]
                res[:n] += 1
              end
            end
            res[:msg] = 'caricamento eseguito'
          end
          res
        end

        def inizializza_files_temporanei
          unless @files
            @fd = {}
            @files = {}
            @temp_dir ||= Dir.mktmpdir('loader_', Irma.loader_dir)
            %i(totale delta).each do |op|
              next if (op == :delta) && !delta
              @files[op] = File.join(@temp_dir, "#{entita.table_name}.#{op}")
              @fd[op] = File.open(@files[op], 'w')
            end
          end
          @files
        end

        def esegui_step(res, step_name, &block)
          res[step_name] = Irma.esegui_e_memorizza_durata(logger: @logger, log_prefix: "#{@log_prefix} #{step_name}", &block)
        end

        def start(**opts, &_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          res = { eccezione: nil }
          entita.con_lock(mode: LOCK_MODE_WRITE, enable: lock, log_prefix:  @log_prefix, **opts) do |locks|
            res[:locks] = locks
            if delta || @usa_files_temporanei
              esegui_step(res, :caricamento_cache) { carica_cache }
              esegui_step(res, :inizializza_files_temporanei) { inizializza_files_temporanei }
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
                  raise proc_exception if proc_exception
                  start_time = Time.now
                  entita.create_constraints(temp_table_opts)
                  logger.info("#{@log_prefix} creazione indici e constraints sulla tabella temporanea #{entita.table_name(temp_table_opts)} completato in #{(Time.now - start_time).round(1)} sec.," \
                              ' inizio sostituzione tabella originaria con quella temporanea')
                  { tabella: entita.table_name, modo: :totale, records: @counter }
                end
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
          if delta && (numero_variazioni < max_variazioni_per_delta)
            res[:modo] = :delta
            # TODO: implementare il delta
            logger.warn("#{@log_prefix} loader delta non implementato")
          else
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
                start_time = Time.now
                entita.db.copy_into_from_file(entita.table_name(temp_table_opts), @files[:totale], columns: LOADER_TOTALE_COLUMNS, options: LOADER_TOTALE_OPTIONS)
                logger.info("#{@log_prefix} caricamento records nella tabella temporanea #{entita.table_name(temp_table_opts)} completato in #{(Time.now - start_time).round(1)} sec.," \
                            ' inizio creazione indici e constraints sulla tabella temporanea')
                start_time = Time.now
                entita.create_constraints(temp_table_opts)
                logger.info("#{@log_prefix} creazione indici e constraints sulla tabella temporanea #{entita.table_name(temp_table_opts)} completato in #{(Time.now - start_time).round(1)} sec.," \
                            ' inizio sostituzione tabella originaria con quella temporanea')
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

    #
    class EntitaOmcFisico < Entita
      TABLE_NAME_PREFIX = 'omc'.freeze
      CONSTANT_KEYS = %i(archivio vendor).freeze
      NOT_NULL_KEYS = %i(omc_fisico omc_fisico_id).freeze
      KEYS = (CONSTANT_KEYS + NOT_NULL_KEYS).freeze

      attr_reader :logger
      attr_reader(*KEYS)

      def initialize(opts) # rubocop:disable Metrics/AbcSize
        CONSTANT_KEYS.each do |k|
          begin
            instance_variable_set("@#{k}", Constant.constant(k, opts[k]).key.to_s)
          rescue
            raise "Entita: il valore dell'opzione costante :#{k} (#{opts[k]}) non è valido (valori ammessi: #{Constant.values(k).join(', ')})"
          end
        end
        NOT_NULL_KEYS.each do |k|
          raise "Entita: il valore dell'opzione variable :#{k} (#{opts[k]}) non è valido" if opts[k].to_s.empty?
          instance_variable_set("@#{k}", opts[k])
        end
        @logger = opts[:logger] || Irma.logger
      end

      def con_lock(key: LOCK_KEY_ARCHIVIO_OMCFISICO, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **lock_info.merge(opts), &block)
      end

      def lock_info
        { archivio: archivio, vendor: vendor, omc_fisico: omc_fisico, omc_fisico_id: omc_fisico_id }
      end

      def old_table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, archivio.to_s, vendor.to_s, omc_fisico.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, archivio.to_s, omc_fisico_id.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def index_prefix_old
        ['o', archivio.to_s[0..1], vendor.to_s[0..1], omc_fisico.to_s, Time.now.tv_sec.to_s].compact.join(TABLE_NAME_SEP).downcase
      end

      def index_prefix
        ['o', archivio.to_s[0..1], omc_fisico_id.to_s, Time.now.tv_sec.to_s].compact.join(TABLE_NAME_SEP).downcase
      end
    end

    #
    class EntitaPi < Entita
      TABLE_NAME_PREFIX = 'pi'.freeze
      NOT_NULL_KEYS = %i(id).freeze

      attr_reader :logger
      attr_reader(*NOT_NULL_KEYS)
      def initialize(opts)
        NOT_NULL_KEYS.each do |k|
          raise "Entita: il valore dell'opzione variable :#{k} (#{opts[k]}) non è valido" if opts[k].to_s.empty?
          instance_variable_set("@#{k}", opts[k])
        end
        @logger = opts[:logger] || Irma.logger
      end

      def con_lock(key: LOCK_KEY_PROGETTO_IRMA, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **lock_info.merge(opts), &block)
      end

      def lock_info
        { id: id }
      end

      def table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, id.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def index_prefix
        ['idx', 'pi', id.to_s, Time.now.tv_sec.to_s].compact.join(TABLE_NAME_SEP).downcase
      end
    end

    #
    class EntitaEccezione < Entita
      TABLE_NAME_PREFIX = 'entita'.freeze
      CONSTANT_KEYS = %i(vendor rete).freeze
      NOT_NULL_KEYS = %i(omc_logico omc_logico_id).freeze
      KEYS = (CONSTANT_KEYS + NOT_NULL_KEYS).freeze

      attr_reader :logger, :archivio
      attr_reader(*KEYS)

      def initialize(opts) # rubocop:disable Metrics/AbcSize
        CONSTANT_KEYS.each do |k|
          begin
            instance_variable_set("@#{k}", Constant.constant(k, opts[k]).key.to_s)
          rescue
            raise "Entita: il valore dell'opzione costante :#{k} (#{opts[k]}) non è valido (valori ammessi: #{Constant.values(k).join(', ')})"
          end
        end
        NOT_NULL_KEYS.each do |k|
          raise "Entita: il valore dell'opzione variable :#{k} (#{opts[k]}) non è valido" if opts[k].to_s.empty?
          instance_variable_set("@#{k}", opts[k])
        end
        @logger = opts[:logger] || Irma.logger
        @archivio = ARCHIVIO_ECCEZIONI
      end

      def con_lock(key: LOCK_KEY_ARCHIVIO_ECCEZIONI, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **lock_info.merge(opts), &block)
      end

      def lock_info
        { archivio: archivio, vendor: vendor, rete: rete, omc_logico: omc_logico, omc_logico_id: omc_logico_id }
      end

      def old_table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, archivio.to_s, vendor.to_s, rete.to_s, omc_logico.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, archivio.to_s, omc_logico_id.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def old_index_prefix # rubocop:disable Metrics/AbcSize
        ['e', archivio.to_s[0..1], vendor.to_s[0..1], rete.to_s, omc_logico.to_s, Time.now.tv_sec.to_s].compact.join(TABLE_NAME_SEP).downcase
      end

      def index_prefix
        ['e', archivio.to_s[0..1], omc_logico_id.to_s, Time.now.tv_sec.to_s].compact.join(TABLE_NAME_SEP).downcase
      end
    end
  end
end
