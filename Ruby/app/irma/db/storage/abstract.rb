# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151121
#
#

module Irma
  module Db
    module Storage
      # Taken from shellwords.rb (Ruby 2.0.0p247)
      class Shellwords
        def self.shellescape(str)
          str = str.to_s

          # An empty argument will be skipped, so return empty quotes.
          return "''" if str.empty?

          str = str.dup

          # Treat multibyte characters as is.  It is caller's responsibility
          # to encode the string in the right encoding for the shell
          # environment.
          str.gsub!(%r{([^A-Za-z0-9_\-.,:\/@\n])}, '\\\\\\1')

          # A LF cannot be escaped with a backslash because a backslash + LF
          # combo is regarded as line continuation and simply ignored.
          str.gsub!(/\n/, "'\n'")

          str
        end

        def self.shelljoin(array)
          array.map { |arg| shellescape(arg) }.join(' ')
        end
      end

      #
      class Abstract # rubocop:disable Metrics/ClassLength
        attr_reader :config

        def initialize(config)
          @config = config
        end

        def create
          res = _create
          warn "[sequel] Created database '#{database}'" if res
          res
        end

        def drop
          ::Sequel::Model.db.disconnect
          res = _drop
          warn "[sequel] Dropped database '#{database}'" if res
          res
        end

        def dump(filename)
          res = _dump filename
          warn "[sequel] Dumped structure of database '#{database}' to '#{filename}'" if res
          res
        end

        def load(filename)
          res = _load filename
          warn "[sequel] Loaded structure of database '#{database}' from '#{filename}'" if res
          res
        end

        # To be overriden by subclasses
        def close_connections
          true
        end

        def database
          @database ||= config[:database] || config[:path]
        end

        def username
          @username ||= config[:username] || config[:user] || ''
        end

        def password
          @password ||= config[:password] || ''
        end

        def host
          @host ||= config[:host] || ''
        end

        def port
          @port ||= config[:port] || ''
        end

        def owner
          @owner ||= config[:owner] || ''
        end

        def charset
          @charset ||= config[:charset] || ENV['CHARSET'] || 'utf8'
        end

        def collation
          @collation ||= config[:collation] || ENV['COLLATION']
        end

        def search_path
          @search_path ||= config[:search_path] || '"$user", public'
        end

        def schema_information_dump(migrator, sql_dump)
          res = ''
          inserts = schema_information_inserts(migrator, sql_dump)
          if inserts.any?
            res = inserts.join("\n")
            unless sql_dump
              res = <<-EOS.strip_heredoc
              Sequel.migration do
                change do
              #{res}
                end
              end
              EOS
            end
          end
          res
        end

        private

        def add_option(commands, name, value)
          return nil if value.to_s.empty?
          separator = name[0, 2] == '--' ? '=' : ' '
          commands << "#{name}#{separator}#{value}"
        end

        def add_flag(commands, flag)
          commands << flag
        end

        def exec(escaped_command)
          `#{escaped_command}`

          # Evaluate command status as a boolean like `system` does.
          $CHILD_STATUS.exitstatus.zero?
        end

        def safe_exec(args)
          exec Shellwords.shelljoin(Array(args))
        end

        def schema_information_inserts(migrator, sql_dump)
          migrator.ds.map do |hash|
            insert = migrator.ds.insert_sql(hash)
            sql_dump ? "#{insert};" : "self << #{insert.inspect}"
          end
        end

        def schema_information_dump_with_search_path(migrator, sql_dump) # rubocop:disable Metrics/MethodLength
          res = ''
          inserts = schema_information_inserts(migrator, sql_dump)
          if inserts.any?
            set_search_path_sql = "SET search_path TO #{search_path}"
            res = inserts.join("\n")
            res = if sql_dump
                    "#{set_search_path_sql};\n#{res}"
                  else
                    res = <<-EOS.strip_heredoc
                      Sequel.migration do
                        change do
                          self << #{set_search_path_sql.inspect}
                          #{res}
                        end
                      end
                    EOS
                  end
          end
          res
        end
      end
    end
  end
end
