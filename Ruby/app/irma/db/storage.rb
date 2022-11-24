# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151121
#

require_relative 'storage/jdbc'
require_relative 'storage/postgres'

module Irma
  module Db
    #
    module Storage
      def self.create_all
        with_local_repositories { |config| create_environment(config) }
      end

      def self.drop_all
        with_local_repositories { |config| drop_environment(config) }
      end

      def self.create_environment(config_or_env)
        adapter_for(config_or_env).create
      end

      def self.drop_environment(config_or_env)
        adapter = adapter_for(config_or_env)
        adapter.close_connections
        adapter.drop
      end

      def self.dump_environment(config_or_env, filename)
        adapter_for(config_or_env).dump(filename)
      end

      def self.load_environment(config_or_env, filename)
        adapter_for(config_or_env).load(filename)
      end

      def self.close_all_connections
        with_all_repositories { |config| close_connections_environment(config) }
      end

      def self.close_connections_environment(config_or_env)
        adapter_for(config_or_env).close_connections
      end

      def self.adapter_for(config_or_env)
        config = if config_or_env.is_a? Hash
                   config_or_env
                 else
                   environments[config_or_env.to_s]
                 end
        lookup_class(config[:adapter]).new config
      end

      def self.with_local_repositories
        environments.each_value do |config|
          next if config[:database].blank? || config[:adapter].blank?
          if config[:host].blank? || %w(127.0.0.1 localhost).include?(config[:host])
            yield config
          else
            warn "This task only modifies local databases. #{config[:database]} is on a remote host."
          end
        end
      end

      def self.with_all_repositories
        environments.each_value do |config|
          next if config[:database].blank? || config[:adapter].blank?
          yield config
        end
      end

      def self.lookup_class(adapter)
        raise 'Adapter not specified in config, please set the :adapter key.' unless adapter
        return Jdbc if adapter =~ /jdbc/

        klass_name = adapter.camelize.to_sym
        unless const_defined?(klass_name)
          raise "Adapter #{adapter} not supported (#{klass_name.inspect})"
        end

        const_get klass_name
      end

      def self.environment_for(name)
        environments[name.to_s] || environments[name.to_sym]
      end

      def self.environments
        unless @enviroments
          @environments = {}
          Db.configurations.each do |name, config|
            @environments[name] = normalize_repository_config(config)
          end
        end
        @environments
      end

      def self.connect(environment)
        normalized_config = environment_for environment

        unless (normalized_config.keys & %w(adapter url)).any?
          raise "Database not configured.\n" \
            'Please create config/database.yml or set DATABASE_URL in environment.'
        end

        if normalized_config[:url]
          ::Sequel.connect normalized_config[:url], normalized_config
        else
          ::Sequel.connect normalized_config
        end.tap { after_connect.call if after_connect.respond_to?(:call) }
      end

      def self.normalize_repository_config(hash)
        config = Config.new hash, root: ROOT_DIR

        url = ENV['DATABASE_URL']
        config[:url] ||= url if url

        # create the url if neccessary
        config[:url] ||= config.url if config[:adapter] =~ /^(jdbc|do):/

        config
      end
    end
  end
end
