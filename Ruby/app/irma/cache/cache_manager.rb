# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160226
#
require 'concurrent'
require_relative 'mapdb'

module Irma
  #
  class CacheManager
    attr_reader :instances
    def initialize
      @instances = Concurrent::Hash.new
    end

    def reset
      while (cache_instance_info = @instances.shift)
        cache_instance_info[1].reset
      end
      @instances
    end

    def remove(cache)
      @instances.delete(cache.respond_to?(:cache_key) ? cache.cache_key : cache)
    end

    def exist?(cache)
      @instances.key?(cache.respond_to?(:cache_key) ? cache.cache_key : cache)
    end

    def available_cache_types
      @available_cache_types ||= self.class.constants.select { |k| k.to_s.match(/^Cache/) }.map { |k| k.to_s.split('Cache').last.underscore.to_sym }
    end

    def instance(key:, type: :hash, **opts)
      raise ArgumentError, "Tipo di cache #{type} non valido, valori ammessi: #{available_cache_types.join(', ')}" unless available_cache_types.include?(type)
      full_key = "#{type}:#{key}"
      @instances[full_key] ||= self.class.class_eval("cache_#{type}".camelize).new(cache_key: full_key, cache_manager: self, **opts)
    end

    #
    module Common
      def cache_manager
        @cache_manager
      end

      def cache_key
        @cache_key
      end

      def remove
        reset
        cache_manager.remove(cache_key)
      end
    end

    #
    class CacheHash < Hash
      include Common

      def initialize(cache_key:, cache_manager:, **_hash)
        @cache_key = cache_key
        @cache_manager = cache_manager
        super()
      end

      def reset
        clear
      end
    end

    #
    class CacheMapDb < Mapdb::HashMap
      include Common

      attr_reader :db

      def initialize(cache_key:, cache_manager:, **_hash)
        @cache_key = cache_key
        @cache_manager = cache_manager
        @db = Mapdb::DB.new(cache_key)
        super(db.mapdb, cache_key)
      end

      def reset
        db.clear if db
      end
    end
  end

  # official Irma cache manager
  Cache = CacheManager.new
end
