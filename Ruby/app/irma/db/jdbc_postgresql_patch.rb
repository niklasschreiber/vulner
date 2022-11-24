# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160307
#
# PATCH del metodo estratto dalla sequel gem, file adapters/jdbc/postgresql.rb

Sequel.require 'adapters/jdbc/transactions'

# rubocop:disable all
module Sequel
  #
  module JDBC

    class Database < Sequel::Database
      # PATCH GC: enable transaction methods missing from jdbc/postgresql.rb
      include ::Sequel::JDBC::Transactions
    end

    #
    module Postgres
      #
      module DatabaseMethods
        # See Sequel::Postgres::Adapter#copy_into
        def copy_into(table, opts=OPTS)
          data = opts[:data]
          data = Array(data) if data.is_a?(String)

          if block_given? && data
            raise Error, "Cannot provide both a :data option and a block to copy_into"
          elsif !block_given? && !data
            raise Error, "Must provide either a :data option or a block to copy_into"
          end

          synchronize(opts) do |conn|
            begin
              copier = nil # PATCH GC
              copy_manager = org.postgresql.copy.CopyManager.new(conn)
              copier = copy_manager.copy_in(copy_into_sql(table, opts))
              if block_given?
                while buf = yield
                  copier.writeToCopy(s = buf.to_java_bytes, 0, s.length)
                end
              else
                data.each { |d| copier.writeToCopy(d.to_java_bytes, 0, d.length) }
              end
            rescue Exception => e
              if copier # PATCH GC
                copier.cancelCopy rescue nil
              end
              raise
            ensure
              unless e
                begin
                  copier.endCopy
                rescue NativeException => e2
                  raise_error(e2)
                end
              end
            end
          end
        end

        def copy_into_from_file(table, file, opts=OPTS)
          synchronize(opts) do |conn|
            copy_manager = org.postgresql.copy.CopyManager.new(conn)
            file_reader = java.io.FileReader.new(file)
            copy_manager.copy_in(copy_into_sql(table, opts), file_reader)
          end
        end

        def con_copier(table, opts=OPTS)
          synchronize(opts) do |conn|
            copier = nil
            begin
              copy_manager = org.postgresql.copy.CopyManager.new(conn)
              copier = copy_manager.copy_in(copy_into_sql(table, opts))
              yield(copier)
            rescue Exception => e
              if copier # PATCH GC
                copier.cancelCopy rescue nil
              end
              raise
            ensure
              unless e
                begin
                  copier.endCopy
                rescue NativeException => e2
                  raise_error(e2)
                end
              end
            end
          end
        end
      end
    end
  end
end
# rubocop:enable all
