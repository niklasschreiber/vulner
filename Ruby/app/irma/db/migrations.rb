# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151119
#
#

Sequel.extension :migration
require_relative 'storage'

module Irma
  module Db
    #
    class Migrations
      class << self
        def migrate(version = nil)
          opts = {}
          opts[:target] = version.to_i if version
          ::Sequel::Migrator.run(Db.connection, migrations_dir, opts)
        end
        alias migrate_up! migrate
        alias migrate_down! migrate

        def migrations_dir
          MIGRATE_DIR
        end

        def pending_migrations?
          return false unless available_migrations?
          !::Sequel::Migrator.is_current?(Db.connection, migrations_dir)
        end

        def dump_schema_information(opts = {})
          sql = opts.fetch :sql
          adapter = Db::Storage.adapter_for(Db.env)
          db = Db.connection
          res = ''
          if available_migrations?
            migrator_class = ::Sequel::Migrator.send(:migrator_class, migrations_dir)
            migrator = migrator_class.new db, migrations_dir
            res << adapter.schema_information_dump(migrator, sql)
          end
          res
        end

        def current?
          return unless available_migrations?
          migrator_class = ::Sequel::Migrator.send(:migrator_class, migrations_dir)
          migrator = migrator_class.new Db.connection, migrations_dir
          migrator.is_current?
        end

        def current_migration
          return unless available_migrations?
          migrator_class = ::Sequel::Migrator.send(:migrator_class, migrations_dir)
          migrator = migrator_class.new Db.connection, migrations_dir
          if migrator.respond_to?(:applied_migrations)
            migrator.applied_migrations.last
          elsif migrator.respond_to?(:current_version)
            migrator.current_version
          end
        end

        def previous_migration
          return unless available_migrations?

          migrator_class = ::Sequel::Migrator.send(:migrator_class, migrations_dir)
          migrator = migrator_class.new Db.connection, migrations_dir
          if migrator.respond_to?(:applied_migrations)
            migrator.applied_migrations[-2] || '0'
          elsif migrator.respond_to?(:current_version)
            migrator.current_version - 1
          end
        end

        def available_migrations?
          File.exist?(migrations_dir) && Dir[File.join(migrations_dir, '*')].any?
        end
      end
    end
  end
end

# PATCH for Sequel 4.26 json column type dump
#
require 'sequel/extensions/schema_dumper'
# rubocop:disable all
module Sequel
  module SchemaDumper
    # Convert the column schema information to a hash of column options, one of which must
    # be :type.  The other options added should modify that type (e.g. :size).  If a
    # database type is not recognized, return it as a String type.
    def column_schema_to_ruby_type(schema)
      case schema[:db_type].downcase
      when /\A(medium|small)?int(?:eger)?(?:\((\d+)\))?( unsigned)?\z/o
        if !$1 && $2 && $2.to_i >= 10 && $3
          # Unsigned integer type with 10 digits can potentially contain values which
          # don't fit signed integer type, so use bigint type in target database.
          {:type=>:Bignum}
        else
          {:type=>Integer}
        end
      when /\Atinyint(?:\((\d+)\))?(?: unsigned)?\z/o
        {:type =>schema[:type] == :boolean ? TrueClass : Integer}
      when /\Abigint(?:\((?:\d+)\))?(?: unsigned)?\z/o
        {:type=>:Bignum}
      when /\A(?:real|float|double(?: precision)?|double\(\d+,\d+\)(?: unsigned)?)\z/o
        {:type=>Float}
      when 'boolean', 'bit', 'bool'
        {:type=>TrueClass}
      when /\A(?:(?:tiny|medium|long|n)?text|clob)\z/o
        {:type=>String, :text=>true}
      when 'date'
        {:type=>Date}
      when /\A(?:small)?datetime\z/o
        {:type=>DateTime}
      when /\Atimestamp(?:\((\d+)\))?(?: with(?:out)? time zone)?\z/o
        {:type=>DateTime, :size=>($1.to_i if $1)}
      when /\Atime(?: with(?:out)? time zone)?\z/o
        {:type=>Time, :only_time=>true}
      when /\An?char(?:acter)?(?:\((\d+)\))?\z/o
        {:type=>String, :size=>($1.to_i if $1), :fixed=>true}
      when /\A(?:n?varchar|character varying|bpchar|string)(?:\((\d+)\))?\z/o
        {:type=>String, :size=>($1.to_i if $1)}
      when /\A(?:small)?money\z/o
        {:type=>BigDecimal, :size=>[19,2]}
      when /\A(?:decimal|numeric|number)(?:\((\d+)(?:,\s*(\d+))?\))?\z/o
        s = [($1.to_i if $1), ($2.to_i if $2)].compact
        {:type=>BigDecimal, :size=>(s.empty? ? nil : s)}
      when /\A(?:bytea|(?:tiny|medium|long)?blob|(?:var)?binary)(?:\((\d+)\))?\z/o
        {:type=>File, :size=>($1.to_i if $1)}
      when /\A(?:year|(?:int )?identity)\z/o
        {:type=>Integer}
      # -------------------------- THIS IS THE PATCH!!
      when 'json'
        {:type=>:json}
      # ______________________________________________
      else
        {:type=>String}
      end
    end
  end
end
# rubocop:enable all
