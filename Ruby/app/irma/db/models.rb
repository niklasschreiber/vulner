# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151127
#

require 'sequel'
require_relative 'constant_populate'
require 'irma/shared_fs'
require 'tempfile'
require_relative 'audit_model_support'

#
module Irma
  raise 'Unable to load database models (have you called Db.init ?)' unless Db.initialized?

  Sequel::Model.plugin :validation_class_methods
  Sequel::Model.plugin :constant_populate
  Sequel.extension :pg_json_ops

  #
  module Db
    #
    def self.Model(source)
      Sequel.Model(source)
    end

    Model = Sequel::Model
    #
    class Model # rubocop:disable Metrics/ClassLength
      include ModConfigEnable
      include SharedFs::Util

      class <<self
        attr_accessor :cache_disabled
        attr_reader :cache

        def audit_enabled?
          false
        end

        def create_with_audit(audit_extra_info: nil, attributes: {}) # rubocop:disable Lint/UnusedMethodArgument
          new(attributes).save
        end
        #---------------------
        attr_reader :audit_class
        def audit_enable(audit_class)
          return false unless (ENV['IRMA_AUDIT_ENABLE'] || '0') == '1'
          @audit_class = audit_class
          include AuditModelCommon
          true
        end
        #---------------------

        def configure_retention(default_value, min: 0, max: 365, use_orm_for_cleanup: false)
          config.define :retention, default_value,
                        descr: "Numero di giorni di retention per la tabella #{table_name}",
                        widget_info: "Gui.widget.positiveInteger({minValue: #{min},maxValue:#{max}})"
          @use_orm_for_cleanup = use_orm_for_cleanup
        end

        def retention
          config.parametro(:retention, false) && config[:retention]
        end

        # extension to support various class and instance methods like activerecord
        def connection
          db
        end

        def transaction(opts = {}, &block)
          db.transaction(opts, &block)
        end

        def logger
          Irma::Db.logger
        end

        def delete_all
          dataset.delete
        end

        def truncate(hash = {})
          dataset.truncate({ cascade: true }.merge(hash))
        end

        def reset_cache
          logger.info("#{self}: reset_cache (#{@cache ? @cache.size : 0} elementi)")
          @cache = nil
        end

        def cache_enabled?
          !@cache_disabled && constant_populate?
        end

        def load_in_cache(force = false)
          if cache_enabled? && (@cache.nil? || force)
            @cache = {}
            each { |obj| @cache[obj.pk.to_s] = obj }
            logger.info("#{self} caricato in cache (#{@cache.size} elementi), force = #{force}")
          end
          @cache
        end

        def all_using_cache
          if @cache
            @cache.dup
          else
            res = {}
            each { |obj| res[obj.pk.to_s] = obj }
            res
          end
        end

        def get_by_pk(v)
          (@cache && @cache[v.to_s]) || first(primary_key => v) || raise("Nessuna istanza di #{self} è definita con #{primary_key} #{v}")
        end

        def remove_obsolete_record(limit_date:, col:, **opts)
          query = where("#{col} < ?", limit_date)
          opts[:use_orm] ? query.map(&:destroy).size : query.delete
        end

        def remove_records(limit_date, hash = {}) # rubocop:disable Metrics/AbcSize
          opts = { date_field: :created_at, rebuild_indexes: false }.merge(hash)
          opts[:use_orm] = @use_orm_for_cleanup ? true : false if opts[:use_orm].nil?
          log_prefix = "#{self}: remove_records (limit_date = #{limit_date}, use_orm = #{opts[:use_orm]}, hash = #{hash})"
          col = columns.find { |c| c == opts[:date_field].to_sym }
          raise "Invalid value for cleanup_records :date_fields options (#{opts[:date_field]}), no column defined in class #{self}" unless col
          start_time = Time.now
          logger.info("#{log_prefix} con condizioni |#{col} < #{limit_date}| in corso")
          res = remove_obsolete_record(limit_date: limit_date, col: col, **opts)
          rebuild_indexes if opts[:rebuild_indexes] && res > 0
          logger.info("#{log_prefix} completato in #{(Time.now - start_time).round(1)} secondi (#{res})")
          res
        end

        def rebuild_indexes(tables: [table_name], **_hash) # rubocop:disable Metrics/AbcSize
          log_prefix = "#{self}: rebuild_indexes"
          start_time = Time.now
          logger.info("#{log_prefix} inizio")
          case connection.url
          when /postgres/
            tables.each { |t| connection.run("REINDEX TABLE #{t}") }
            logger.info("#{log_prefix} completato il rebuild degli indici in #{(Time.now - start_time).to_i} secondi")
            true
          else
            logger.info("#{log_prefix} non supportato per la connessione #{conn_url_no_pwd}")
            false
          end
        end

        def cleanup(hash = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          opts = { retention: nil, now: Time.now, rebuild_indexes: true }.merge(hash)
          opts[:retention] ||= retention
          opts[:use_orm] = @use_orm_for_cleanup if opts[:use_orm].nil?
          res = {}
          msg = "#{self}: cleanup non eseguito, retention nulla"
          if opts[:retention] && opts[:retention].to_i.nonzero?
            start_time = Time.now
            res[:tabella] = table_name
            res[:retention] = opts[:retention].to_i
            res[:use_orm] = opts[:use_orm]
            res[:obsolete_date] = opts[:now] - res[:retention] * 86_400
            res[:records] = remove_records(res[:obsolete_date], opts)
            res[:elapsed] = (Time.now - start_time).round(1)
            msg = "#{self}: cleanup completato (#{res})"
          end
          logger.info(msg)
          res
        end

        def cleanup_only_rebuild_indexes
          res = {}
          start_time = Time.now
          res[:rebuild_indexes] = rebuild_indexes
          res[:elapsed] = (Time.now - start_time).round(1)
          res
        end

        def full_class_for_model(model_class)
          "Irma::Db::#{model_class}".to_sym
        end

        def aasm_to_plantuml(campo, options: PLANTUML_DEFAULT_OPTIONS) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          return '' unless respond_to?(:aasm) && aasm(campo)
          sm  = aasm(campo)
          res = ['@startuml', options].compact
          res << "[*] --> #{sm.initial_state}"
          state_transitions = {}
          sm.states.map(&:name).each do |s|
            res << "state #{s}"
            state_transitions[s] = false
          end
          sm.events.each do |ev|
            ev.transitions.each do |ev_tr|
              res << "#{ev_tr.from} --> #{ev_tr.to} : #{ev.name}"
              state_transitions[ev_tr.from] = true
            end
          end
          state_transitions.each { |ev_name, flag| res << "#{ev_name} --> [*]" unless flag }
          res << '@enduml'
          res.join("\n")
        end

        def pubblica_sulla_coda(coda, opts = {})
          delay = opts.delete(:delay)
          opts.delete(:kind)
          Irma.publish(coda, { klass: to_s }.merge(opts).to_json, delay: delay)
        rescue => e
          logger.warn("#{self}, fallita la pubblicazione sulla coda #{coda} del messaggio #{opts}: #{e}")
        end

        include ExportSqlLoader
      end

      def pubblica_sulla_coda(coda, opts = {})
        self.class.pubblica_sulla_coda(coda, attributes.merge(opts))
      end

      DELAY_CACHE_AFTER_DESTROY = 5
      DELAY_CACHE_DEFAULT = 1

      def destroy_with_audit(audit_extra_info: nil) # rubocop:disable Lint/UnusedMethodArgument
        destroy
      end

      def update_with_audit(audit_extra_info: nil, attributes: {}) # rubocop:disable Lint/UnusedMethodArgument
        update(attributes)
      end

      def audit_in_hook(operation)
        return unless self.class.audit_enabled?
        audit_class = self.class.audit_class
        audit_class.create(audit_class.record_da_object(self).merge(audit_info || {}).merge(operazione: operation))
      end

      def refresh_cache_queue(action:, delay: DELAY_CACHE_DEFAULT)
        pubblica_sulla_coda(PUB_CACHE, action: action, delay: delay) if self.class.cache_enabled?
      end

      def after_create
        super
        refresh_cache_queue(action: 'create')
        audit_in_hook(AUDIT_META_ENTITA_OPERAZIONE_CREATE)
      end

      def after_update
        super
        refresh_cache_queue(action: 'update')
        audit_in_hook(AUDIT_META_ENTITA_OPERAZIONE_UPDATE)
      end

      def after_destroy
        super
        refresh_cache_queue(action: 'destroy', delay: DELAY_CACHE_AFTER_DESTROY)
        audit_in_hook(AUDIT_META_ENTITA_OPERAZIONE_DELETE)
      end

      def transaction(opts = {}, &block)
        self.class.transaction(opts, &block)
      end

      def logger
        self.class.logger
      end

      def attributes
        values
      end

      def aasm_gestione_errori(campo, errore) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        return '' unless respond_to?(:aasm) && aasm(campo)
        sm = aasm(campo)
        classe = self.class
        msg = "per #{classe} con id #{id} a seguito di evento '#{sm.current_event}' da #{campo} '#{self[campo.to_sym]}'"
        msg += " a '#{sm.to_state}'" unless sm.to_state.to_s.empty?
        if errore.class.to_s == 'AASM::InvalidTransition'
          begin
            Db::Evento.crea(TIPO_EVENTO_AASM_INVALID_TRANSITION, descr: "AASM: Richiesta transazione NON VALIDA #{msg}")
          rescue => ee
            logger.warn("Errore (#{ee}) nel gestire l'errore in AASM transition (#{errore}) #{msg}")
          end
          logger.error("Richiesta transizione di stato NON VALIDA #{msg}")
        else
          logger.warn("Errore in AASM transition (#{errore}) #{msg}, backtrace: #{errore.backtrace}")
        end
        raise errore
      end
    end

    relative_path = (mdm = MODELS_DIR.match('irma/db/models')) ? mdm[0] : MODELS_DIR
    DB_MODELS.each do |m|
      begin
        require File.join(relative_path, m)
      rescue => e
        STDERR.puts "Error loading model #{m}: #{e}, #{e.backtrace}"
        # raise
      end
    end

    Irma::MetaModello.keywords_fisico_logico

    require_relative 'jdbc_postgresql_patch.rb'
  end
end
