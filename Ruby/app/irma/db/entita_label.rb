# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20160929
#

#
module Irma
  #
  module Db
    # rubocop:disable Metrics/ClassLength
    class EntitaLabel
      # support for export
      include ExportSqlLoader

      TABLE_NAME_PREFIX = 'entita'.freeze
      CONSTANT_KEYS = %i(vendor rete).freeze
      NOT_NULL_KEYS = %i(omc_logico omc_logico_id).freeze
      KEYS = (CONSTANT_KEYS + NOT_NULL_KEYS).freeze
      TABLE_NAME_SEP = '$'.freeze

      attr_reader :logger, :ambiente, :archivio
      attr_reader(*KEYS)

      def initialize(opts) # rubocop:disable Metrics/AbcSize
        CONSTANT_KEYS.each do |k|
          begin
            instance_variable_set("@#{k}", Constant.constant(k, opts[k]).key.to_s)
          rescue
            raise "EntitaLabel: il valore dell'opzione costante :#{k} (#{opts[k]}) non è valido (valori ammessi: #{Constant.values(k).join(', ')})"
          end
        end
        NOT_NULL_KEYS.each do |k|
          raise "EntitaLabel: il valore dell'opzione variable :#{k} (#{opts[k]}) non è valido" if opts[k].to_s.empty?
          instance_variable_set("@#{k}", opts[k])
        end
        @logger = opts[:logger] || Irma.logger
        @archivio = ARCHIVIO_LABEL
      end

      def con_lock(key: LOCK_KEY_ARCHIVIO_LABEL, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **lock_info.merge(opts), &block)
      end

      def lock_info
        { archivio: @archivio, vendor: vendor, rete: rete, omc_logico: omc_logico, omc_logico_id: omc_logico_id }
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
        [TABLE_NAME_PREFIX, @archivio.to_s, vendor.to_s, rete.to_s, omc_logico.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def table_name(table_suffix: nil)
        [TABLE_NAME_PREFIX, @archivio.to_s, omc_logico_id.to_s, table_suffix].compact.join(TABLE_NAME_SEP).downcase.to_sym
      end

      def old_index_prefix # # rubocop:disable Metrics/AbcSize
        # tolgo il timestamp dall'indice dato che la tabella non e' oggetto di caricamento massivo
        ['idx', @archivio.to_s[0..1], vendor.to_s[0..1], rete.to_s, omc_logico.to_s].compact.join(TABLE_NAME_SEP).downcase
      end

      def index_prefix # # rubocop:disable Metrics/AbcSize
        # tolgo il timestamp dall'indice dato che la tabella non e' oggetto di caricamento massivo
        ['idx', @archivio.to_s[0..1], omc_logico_id.to_s].compact.join(TABLE_NAME_SEP).downcase
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
          add_primary_key [:id],             name: "#{ip}$pk"

          add_index       [:dist_name],      name: "#{ip}$distn_idx"
          add_index       [:meta_entita],    name: "#{ip}$metae_idx"
          add_index       [:naming_path],    name: "#{ip}$naminp_idx"
          add_index       [:meta_parametro], name: "#{ip}$metap_idx"
          add_index       [:label],          name: "#{ip}$esitod_idx"

          add_index       [:dist_name, :meta_parametro], unique: true, name: "u#{ip}$dn_mp_idx"
        end
      end

      def drop_table(table_suffix: nil)
        db.drop_table(table_name(table_suffix: table_suffix))
      end

      def drop_table?(table_suffix: nil)
        db.drop_table?(table_name(table_suffix: table_suffix))
      end

      def truncate(table_suffix: nil)
        dataset(table_suffix: table_suffix).truncate
      end

      SCHEMA = [
        ['Bignum',      :id],
        ['String',      :dist_name,             size: 1024, null: false],
        ['String',      :meta_entita,           size: 256, null: false],
        ['String',      :naming_path,           size: 1024, null: false],
        ['String',      :meta_parametro,        size: 256, null: false],
        ['String',      :label,                 size: 256, null: false, default: LABEL_NC_DB],
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
        def to_csv(sep = ',')
          [#{COLUMNS.map { |k| JSON_COLUMNS.include?(k) ? "#{k}_to_json" : "@values[:#{k}]" }.join(',')}].join(sep)
        end
        EOS

        def for_insert
          @values[:created_at] = @values[:updated_at] = Time.now.to_s
          [COLUMNS, COLUMNS.map { |k| @values[k] }]
        end
      end

      def schema
        db.create_table_generator do
          SCHEMA.each do |col_cmd|
            send(*col_cmd)
          end
        end
      end
    end
  end
end
