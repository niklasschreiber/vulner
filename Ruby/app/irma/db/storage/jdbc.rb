# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151121
#
#
require_relative 'abstract'

#
module Irma
  #
  module Db
    #
    module Storage
      #
      class Jdbc < Abstract
        def _is_mysql?
          config[:adapter].start_with?('jdbc:mysql')
        end

        def _is_postgres?
          config[:adapter].start_with?('jdbc:postgresql')
        end

        def _is_sqlite?
          config[:adapter].start_with?('jdbc:sqlite')
        end

        def _root_url
          config[:url].scan(%r{^jdbc:mysql://[\w\.]*:?\d*}).first
        end

        def db_name
          config[:database]
        end

        def _params
          config[:url].scan(/\?.*$/).first
        end

        def _create # rubocop:disable Metrics/AbcSize
          if _is_sqlite?
            return if in_memory?
            ::Sequel.connect config[:url]
          elsif _is_mysql?
            ::Sequel.connect("#{_root_url}#{_params}") { |db| db.execute("CREATE DATABASE IF NOT EXISTS `#{db_name}` DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}") }
          elsif _is_postgres?
            adapter = Storage::Postgres.new(config)
            adapter._create
          end
        end

        def _drop # rubocop:disable Metrics/AbcSize
          if _is_sqlite?
            return if in_memory?
            FileUtils.rm db_name if File.exist? db_name
          elsif _is_mysql?
            ::Sequel.connect("#{_root_url}#{_params}") { |db| db.execute("DROP DATABASE IF EXISTS `#{db_name}`") }
          elsif _is_postgres?
            adapter = Storage::Postgres.new(config)
            adapter._drop
          end
        end

        def _dump(filename)
          raise NotImplementedError unless _is_postgres?
          adapter = Storage::Postgres.new(config)
          adapter._dump(filename)
        end

        def _load(filename)
          raise NotImplementedError unless _is_postgres?
          adapter = Storage::Postgres.new(config)
          adapter._load(filename)
        end

        def schema_information_dump(migrator, sql_dump)
          if _is_postgres?
            schema_information_dump_with_search_path(migrator, sql_dump)
          else
            super
          end
        end

        private

        def collation
          @collation ||= super || 'utf8_unicode_ci'
        end

        def in_memory?
          return false unless _is_sqlite?
          database == ':memory:'
        end
      end
    end
  end
end
