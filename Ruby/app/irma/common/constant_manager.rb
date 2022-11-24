# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20151116
#

module Irma
  # Classe che consente di gestire la definizione di una o piu' costanti legate
  # allo stesso scopo e prefisso.
  #
  # == Esempio
  #
  #  # definizione
  #  class Constant < ConstantManager
  #  end
  #
  #  Constant.define(:evento,{
  #   :debug   => {:value => 0, :color => {:bg => '#FFFFFF', :fg => '#000000'}},
  #   :info    => {:value => 1, :color => {:bg => '#00DD00', :fg => '#000000'}},
  #   :warning => {:value => 2, :color => {:bg => '#FFFF00', :fg => '#000000'}},
  #   :error   => {:value => 3, :color => {:bg => '#FF0000', :fg => '#000000'}},
  #  },:gravita)
  #
  #  # utilizzo
  #  EVENTO_GRAVITA_INFO                                  # => 1
  #  Constant.label(:evento,EVENTO_GRAVITA_INFO,:gravita) # => "INFO"
  #  Constant.key(:evento,EVENTO_GRAVITA_INFO,:gravita)   # => :info
  #  Constant.value(:evento,:info,:gravita)               # => 1
  #  Constant.labels(:evento,:gravita)                    # => ["DEBUG", "INFO", "WARNING", "ERROR"]
  #  Constant.keys(:evento,:gravita)                      # => [:debug,:info,:warning,:error]
  #  Constant.values(:evento,:gravita)                    # => [0,1,2,3]
  #  Constant.info(:evento,:info,:gravita)                # => {:value => 1, :color => {:bg => '#00DD00', :fg => '#000000'}, :key=>:info}
  #  Constant.info(:evento,1,:gravita)                    # => {:value => 1, :color => {:bg => '#00DD00', :fg => '#000000'}, :key=>:info}
  #
  class ConstantManager # rubocop:disable Metrics/ClassLength
    private_class_method :new

    class NotDefined < RuntimeError; end
    class ValueNotDefined < RuntimeError; end

    attr_reader :scope, :prefix, :key, :info, :container

    def self.define(scope, values, prefix = nil) # rubocop:disable Metrics/AbcSize
      @constants ||= {}
      @constants[scope] ||= {}
      @constants[scope][prefix] ||= {}
      @keys ||= {}
      @keys[scope] ||= {}
      @keys[scope][prefix] ||= {}
      values.each do |k, v|
        info = v.is_a?(Hash) ? v.dup : { value: v }
        # autoassign :value using k if not specified
        info[:value] = k unless info.key?(:value)
        # autoassign :key using k if not specified
        info[:key] = k unless info.key?(:key)
        value = info[:value]
        @constants[scope][prefix][k.to_s] = new(scope, prefix, k, info)
        @keys[scope][prefix][value] = k
      end
    end

    def self.exists?(scope, prefix = nil)
      (@constants[scope] && @constants[scope][prefix]) ? true : false
    end

    def self.reset(scope, prefix = nil)
      raise NotDefined, "scopo=#{scope}, prefix=#{prefix}" unless @constants[scope] && @constants[scope][prefix]
      @constants[scope][prefix].values.each(&:undefine_global_constant)
      @constants[scope].delete(prefix)
      @keys[scope].delete(prefix)
    end

    def self.reset_scope(scope)
      raise NotDefined, "scopo=#{scope}" unless @constants[scope]
      @constants[scope].keys.each { |prefix| reset(scope, prefix) }
      @constants.delete(scope)
      @keys.delete(scope)
    end

    def self.reset_all
      @constants.keys.each { |scope| reset_scope(scope) } if @constants
      @constants = {}
      @keys = {}
    end

    def self.scopes
      @constants.keys
    end

    def self.prefixes(scope)
      raise NotDefined, "scopo=#{scope}" unless @constants[scope]
      @constants[scope].keys
    end

    # ritorna la label associata alla costante definita con +scope+, valore +value+ e prefisso +prefix+
    #
    # == Eccezioni
    # * vedi self.key
    #
    def self.label(scope, value, prefix = nil)
      constant(scope, key(scope, value, prefix), prefix).label
    end

    # ritorna la chiave associata alla costante definita con +scope+, valore +value+ e prefisso +prefix+
    #
    # == Eccezioni
    # * NotDefined
    # * ValueNotDefined
    #
    def self.key(scope, value, prefix = nil)
      raise NotDefined, "scopo=#{scope},prefix=#{prefix}" unless @keys[scope] && @keys[scope][prefix]
      k = @keys[scope][prefix][value]
      raise ValueNotDefined, "scopo=#{scope},prefix=#{prefix},value=#{value}" unless k
      k
    end

    # ritorna tutte le chiavi associate allo scopo +scope+ e prefisso +prefix+
    #
    # == Eccezioni
    # * NotDefined
    def self.keys(scope, prefix = nil)
      raise NotDefined, "scopo=#{scope},prefix=#{prefix}" unless @keys[scope] && @keys[scope][prefix]
      @keys[scope][prefix].values
    end

    # ritorna tutte le chiavi associate allo scopo +scope+ e prefisso +prefix+
    #
    # == Eccezioni
    # * vedi self.keys
    def self.labels(scope, prefix = nil)
      constants(scope, prefix).map(&:label)
    end

    # ritorna tutti i valori associati allo scopo +scope+ e prefisso +prefix+
    #
    # == Eccezioni
    # * NotDefined
    def self.values(scope, prefix = nil)
      constants(scope, prefix).map(&:value)
    end

    # ritorna il valore della costante con chiave/valore +x+ nello scopo +scope+ e prefisso +prefix+
    def self.value(scope, x, prefix = nil)
      constant(scope, x, prefix).value
    end

    # ritorna le info della costante con chiave/valore +x+ nello scopo +scope+ e prefisso +prefix+
    def self.info(scope, x, prefix = nil)
      constant(scope, x, prefix).info
    end

    # ritorna l'oggetto Constant con chiave/valore +x+ nello scopo +scope+ e prefisso +prefix+
    #
    # == Eccezioni
    # * NotDefined
    def self.constant(scope, x, prefix = nil) # rubocop:disable Metrics/AbcSize
      raise NotDefined, "scopo=#{scope},prefix=#{prefix}" unless exists?(scope, prefix)
      c = @constants[scope][prefix][x.to_s.downcase]
      unless c
        k = @keys[scope][prefix][x]
        c = @constants[scope][prefix][k.to_s] if k
      end
      raise NotDefined, "scopo=#{scope},prefix=#{prefix},key/value=#{x}" unless c
      c
    end

    # Ritorna tuttle le costanti dello scopo +scope+ e prefisso +prefix+
    def self.constants(scope, prefix = nil)
      raise NotDefined, "scopo=#{scope},prefix=#{prefix}" unless exists?(scope, prefix)
      @constants[scope][prefix].values
    end

    # Ritorna tutte le costanti definite
    def self.all_constants
      @constants.collect { |_scope, v| v.values.map(&:values) }.flatten
    end

    # INSTANCE METHODS
    def initialize(scope, prefix, key, info)
      @scope = scope
      @key = key
      @info = info
      @prefix = prefix
      @container = Kernel
      if prefix.is_a?(Class) || prefix.is_a?(Module)
        @prefix = nil
        @container = prefix
      end
      define_global_constant
    end

    def value
      @info[:value]
    end

    def label
      @info[:label] || @key.to_s.tr('_', ' ').upcase
    end

    def define_global_constant
      @container.send(:const_set, global_constant_name, value)
    end

    def undefine_global_constant
      @container.send(:remove_const, global_constant_name)
    end

    # Costruisce il nome della costante globale in base allo +scope+, +prefix+, +key+ e +value+
    def global_constant_name
      ("#{scope}_" + (prefix ? "#{prefix}_" : '') + key.to_s).upcase
    end
  end
end
