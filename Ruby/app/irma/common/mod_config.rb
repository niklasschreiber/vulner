# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Data creazione: 20090827

#
# Class to add a config method to a module, allowing to save/load from DB (using Parameter class)
#
# == Example
#
#  module X
#      def self.config
#           ModConfig.instance(self.to_s)
#      end
#  end
#  X.config.define(:p1,20)
#  X.config[:p1]=10   # set value for :k1 key (module X)
#  X.config[:k1]      # get value for :k1 key (module X)
#  X.config.value     # get all config values for X as an hash
#

require 'ostruct'

#
module Irma
  #
  class ModConfig # rubocop:disable Metrics/ClassLength
    attr_reader :mod, :parameter

    @instances = {}
    @last_parameter_update = nil

    class << self
      attr_reader :instances
      attr_accessor :disable_load_from_db

      def load_from_db_enabled?
        !@disable_load_from_db
      end

      def load_from_db(opts = {})
        @instances.keys.sort_by(&:to_s).each { |m| @instances[m].load_from_db(opts) }
      end

      def save_to_db(opts = {})
        @instances.keys.sort_by(&:to_s).each { |m| @instances[m].save_to_db(opts) }
      end

      def instance(mod_name)
        @instances[mod_name] ||= new(mod_name)
        @instances[mod_name]
      end

      # check for parameter changes. In this case, reload config from DB
      def check_for_db_updates(opts = {})
        new_updated_at = Db::AppConfig.max(:updated_at)
        if @last_parameter_update.nil? || new_updated_at != @last_parameter_update
          opts[:min_updated_at] = @last_parameter_update if @last_parameter_update
          load_from_db(opts)
          @last_parameter_update = new_updated_at
        end
        @last_parameter_update
      end
    end

    def initialize(mod)
      @mod = mod
      @parameter = {}
    end

    def logger
      Irma.logger
    end

    def reset
      @parameter = {}
    end

    # Define a new Parameter instance for the module, using the +name+ and the current config vlaue
    def define(name, def_value, options = {})
      options.delete :valore_di_default
      @parameter[name.to_s] = OpenStruct.new(model: nil, modulo: mod.to_s, nome: name.to_s, valore: def_value, valore_di_default: def_value, options: options)
    end

    def remove(name = nil)
      @parameter.keys.each do |p_name|
        next if name && name.to_s != p_name
        # model = @parameter[p_name].model
        # model.destroy if model
        @parameter.delete(p_name)
      end
    end

    # save to DB all config values with a parameter defined
    def save_to_db(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      options = { remove_undefined: false }.merge(opts)
      @parameter.sort.each do |info|
        begin
          name, p_def = *info
          @parameter[name].model = Db::AppConfig.define(p_def.modulo, p_def.nome, p_def.valore_di_default, p_def.options).refresh
        rescue => e
          msg = "Errore nel salvataggio nel DB del parametro del modulo #{mod}, nome #{p_def.nome}: #{e}"
          logger.error(msg)
          raise e, msg
        end
      end
      if options[:remove_undefined]
        Db::AppConfig.where(['modulo = ?', mod.to_s]).each do |p|
          next if @parameter[p.nome]
          logger.info("Modulo #{mod}, parametro #{p.nome} eliminato (non più definito)")
          p.destroy
          @parameter.delete(p.nome)
        end
      end
      self
    end

    # load from DB all config values, ignoring error if the value is not defined in DB
    def load_from_db(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      options = { remove_undefined: false, silent: false, min_updated_at: nil }.merge(opts)
      return unless self.class.load_from_db_enabled?
      new_params = @parameter.keys
      conditions = ['modulo = ?', mod.to_s]
      if options[:min_updated_at]
        conditions[0] += ' AND updated_at > ?'
        conditions << options[:min_updated_at]
      end
      Db::AppConfig.where(conditions).each do |p|
        if options[:remove_undefined] && !new_params.member?(p.nome)
          p.destroy
          logger.info("Modulo #{mod}, parametro #{p.nome} eliminato (non più definito)") unless options[:silent]
        else
          # define a new config parameter, assigning the model object
          define(p.nome, p.valore_di_default).model = p
          logger.info("Modulo #{mod}, parametro #{p.nome}, valore caricato dal DB: #{p.valore.inspect} (default: #{p.valore_di_default.inspect})") unless options[:silent]
        end
      end
      self
    end

    def parametro(name, fail_on_nil = true)
      p = @parameter[name.to_s]
      raise ArgumentError, "Modulo #{mod}, parametro #{name} non definito" if fail_on_nil && p.nil?
      p
    end

    # change the config value for +name+ into +value+, alias or +setValue+
    def []=(name, value)
      p = parametro(name)
      p.model.nil? ? (p.valore = value) : (p.model.valore = value)
    end

    # return the config value for +name+ , alias for +getValue+
    def [](name)
      p = parametro(name)
      p.model.nil? ? p.valore : p.model.valore
    end

    def set_value(name, v)
      p = parametro(name)
      p.model.valore = v
      p.model.save_changes
      p.model
    end
  end

  #
  module ModConfigEnable
    extends_host_with :ClassMethods
    #
    module ClassMethods
      def config
        ModConfig.instance(to_s)
      end
    end

    def config
      self.class.config
    end
  end
end
