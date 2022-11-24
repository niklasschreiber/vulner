# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151119
#
#

#
module Irma
  #
  module Db
    #
    class Config < Hash
      def initialize(raw, opts = {}) # rubocop: disable Metrics/AbcSize
        @jruby = opts.fetch(:jruby, defined?(JRUBY_VERSION))
        merge! raw.map { |k, v| [k.to_sym, v] }.to_h
        self[:port] = port.to_i if include? :port
        self[:max_connections] = delete(:pool) if include? :pool
        normalize_adapter if include? :adapter
        normalize_db opts[:root] if include? :database
      end

      # allow easier access
      def method_missing(key, *a)
        return self[key] if a.empty? && include?(key)
        super
      end

      def respond_to_missing?(key, include_private = false)
        include?(key) || super
      end

      def url
        # the gsub transforms foo:/bar
        # (which jdbc doesn't like)
        # into foo:///bar
        self[:url] || make_url.to_s.gsub(%r{:/(?=\w)}, ':///')
      end

      private

      ADAPTER_MAPPING = {
        'sqlite3' => 'sqlite',
        'postgresql' => 'postgres'
      }.freeze

      def normalize_adapter
        self[:adapter] = ADAPTER_MAPPING[adapter.to_s] || adapter.to_s
        jdbcify_adapter if @jruby
      end

      def jdbcify_adapter
        return if adapter =~ /^jdbc:/
        self[:adapter] = 'postgresql' if adapter == 'postgres'
        self[:adapter] = 'jdbc:' + adapter
      end

      def normalize_db(root)
        return unless include? :adapter
        return unless root
        return unless adapter.include?('sqlite') && database != ':memory:'
        # sqlite expects path as the database name
        self[:database] = File.expand_path database.to_s, root
      end

      def make_url
        if adapter =~ /^(jdbc|do):/
          scheme, subadapter = adapter.split ':'
          URI::Generic.build(scheme: scheme, opaque: build_url(to_hash.merge(adapter: subadapter)).to_s)
        else
          build_url to_hash
        end
      end

      def build_url(cfg) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        if (adapter = cfg[:adapter]) =~ /sqlite/ && (database = cfg[:database]) =~ /^:/
          # magic sqlite databases
          return URI::Generic.build(scheme: adapter, opaque: database)
        end

        # these four are handled separately
        params = cfg.reject { |k, _| %w(adapter host port database).include? k.to_s }

        if (v = params[:search_path])
          # make sure there's no whitespace
          v = v.split(',').map(&:strip) unless v.respond_to? :join
          params[:search_path] = v.join(',')
        end

        path = cfg[:database].to_s
        path = "/#{path}" if path =~ %r{^(?!/)}

        q = URI.encode_www_form(params)
        q = nil if q.empty?

        URI::Generic.build(scheme: cfg[:adapter], host: cfg[:host], port: cfg[:port], path: path, query: q)
      end
    end
  end
end
