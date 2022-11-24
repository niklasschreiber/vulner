# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160226
#
require 'forwardable'
require 'json'
require_relative File.basename(Dir[File.join(File.dirname(__FILE__), '*.jar')].first)

# Code rewritten from https://github.com/cmichon/jruby-mapdb (1.2.0)
module Irma
  module Mapdb
    #
    module ClassMethods
      include Enumerable
      extend Forwardable

      def encode(key, value)
        @mapdb_obj.put(key, Marshal.dump(value).to_java_bytes)
      end

      def decode(key)
        stored = @mapdb_obj.get(key)
        stored.nil? ? nil : Marshal.load(String.from_java_bytes(stored))
      end

      def each
        @mapdb_obj.each_pair { |key, value| yield(key, Marshal.load(String.from_java_bytes(value))) }
      end

      def keys
        @mapdb_obj.key_set.to_a
      end

      def_delegator :@mapdb_obj, :clear,    :clear
      def_delegator :@mapdb_obj, :has_key?, :key?
      def_delegator :@mapdb_obj, :count,    :size
      alias []=   encode
      alias []    decode
      alias count size
    end

    #
    class HashMap
      include ClassMethods
      attr_reader :mapdb, :mapdb_obj
      def initialize(mapdb, k)
        @mapdb = mapdb
        @mapdb_obj = @mapdb.getHashMap(k.to_s)
      end
    end

    #
    class TreeMap
      extend ClassMethods
      attr_reader :mapdb, :mapdb_obj
      def initialize(mapdb, k)
        @mapdb = mapdb
        @mapdb_obj = @mapdb.getTreeMap(k.to_s)
      end
    end

    #
    class DB
      extend Forwardable
      attr_reader :mapdb, :type

      def initialize(dbname = nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        if dbname.nil?
          @type = :MemoryDB
          @mapdb = Java::OrgMapdb::DBMaker.newMemoryDB
                                          .closeOnJvmShutdown
                                          .make
        else
          @type = :FileDB
          @full_path = File.join(Irma.cache_dir, "#{dbname}-#{Time.now.strftime('%Y%m%d_%H%M%S')}-#{$PID}-#{Thread.current.object_id}.cache")
          @mapdb = Java::OrgMapdb::DBMaker.newFileDB(Java::JavaIo::File.new(@full_path))
                                          .closeOnJvmShutdown
                                          .deleteFilesAfterClose
                                          .transactionDisable
                                          .mmapFileEnable
                                          .asyncWriteEnable
                                          .make
        end
      end

      def clear
        close
        [@full_path, "#{@full_path}.p"].each { |f| FileUtils.rm_f(f) } if @full_path
      end

      def hash_map(k)
        HashMap.new(@mapdb, k)
      end

      def tree_map(k)
        TreeMap.new(@mapdb, k)
      end

      def maps
        Hash[*@mapdb.getAll.map(&:first).map(&:to_sym).zip(@mapdb.getAll.map(&:last).map(&:size)).flatten]
      end

      def_delegators :@mapdb, :close, :closed?, :compact
    end
  end
end
