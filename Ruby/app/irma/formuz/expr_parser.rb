# vim: set fileencoding=utf-8
#
# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170210
#
require 'ffi'

# rubocop:disable Metrics/BlockNesting
module Irma
  def self.expr_parser(type: :native)
    case type
    when :native
      NativeExprParser.new
    else
      raise "Unsupported type '#{type}' for expr_parser"
    end
  end

  def self.pr_cells(type: :native)
    case type
    when :native
      NativeExprParser::PrCells.new
    else
      raise "Unsupported type '#{type}' for pr_cells"
    end
  end
end

#
module Irma
  PARSER_NULLS = [
    PARSER_NULL_INTEGER = -11_111.to_s.freeze,
    PARSER_NULL_FLOAT   = format('%g', -11_111.1).freeze,
    PARSER_NULL_CHAR    = 'NULLTHENNOSAVE'.freeze
  ].freeze

  DECLARED_VAR_TYPES = [
    DECLARED_VAR_TYPE_NOT = 0,
    DECLARED_VAR_TYPE_STR = 1,
    DECLARED_VAR_TYPE_NBR = 2,
    DECLARED_VAR_TYPE_INT = 3
  ].freeze

  # TIPO_VALORE_XXX constants should be defined outside
  unless defined?(TIPO_VALORE_CHAR)
    TIPO_VALORE_CHAR    = 'char'.freeze
    TIPO_VALORE_INTEGER = 'integer'.freeze
    TIPO_VALORE_FLOAT   = 'float'.freeze
  end

  TIPO_VALORE_MAP = {
    TIPO_VALORE_CHAR    => DECLARED_VAR_TYPE_STR,
    TIPO_VALORE_INTEGER => DECLARED_VAR_TYPE_INT,
    TIPO_VALORE_FLOAT   => DECLARED_VAR_TYPE_NBR
  }.freeze

  DECLARED_VAR_TYPE_MAP = TIPO_VALORE_MAP.invert

  TIPO_VALORE_DEFAULT_VAL = {
    TIPO_VALORE_CHAR    => '12345678901234',
    TIPO_VALORE_INTEGER => '1234',
    TIPO_VALORE_FLOAT   => '11.22'
  }.freeze

  # rubocop:disable Metrics/ClassLength
  class NativeExprParser
    extend FFI::Library
    ffi_lib 'IrmaFormuz'

    if ENV['OUTPUT_FOR_TEST_LIB_IRMAFORMUZ']
      TEST_FILE_FOR_LIB_IRMAFORMUZ = ENV['OUTPUT_FOR_TEST_LIB_IRMAFORMUZ']
      File.open(TEST_FILE_FOR_LIB_IRMAFORMUZ, 'w') do |fd|
        fd.puts %(// Automatically generated by #{__FILE__} on #{Time.now}
#include "test.h"
#include <stdio.h>
int main() {
  long ctx;
  CellVariables** pr_cells;
  CellVariables* cv;
  DeclaredVar* dv;
        )
      end

      def self.write_testfile_for_lib_irmaformuz(s)
        @fd_test_file_for_lib_irmaformuz ||= File.open(TEST_FILE_FOR_LIB_IRMAFORMUZ, 'a+')
        @fd_test_file_for_lib_irmaformuz.write(s)
        @fd_test_file_for_lib_irmaformuz.flush
      end

      def self.write_testfile_for_lib_irmaformuz_method_call(m, first_param, *args) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        start_method_call = case m
                            when :cells_init
                              "  pr_cells = #{m}("
                            when :createCellVariables, :cells_add, :cells_get
                              "  cv = #{m}("
                            when :cells_add_var, :cells_get_var
                              "  dv = #{m}("
                            when :initParser
                              @init_counter ||= 0
                              "  printf(\"#{format('%03d initParser\n', (@init_counter += 1))}\");\n  ctx = #{m}("
                            else
                              "  #{m}("
                            end
        write_testfile_for_lib_irmaformuz start_method_call
        args.map.with_index do |ma, idx|
          if idx == 0 && first_param
            write_testfile_for_lib_irmaformuz first_param
          else
            write_testfile_for_lib_irmaformuz ',' if idx > 0
            if (m == :loadDeclaredVar && idx == 3) || (m == :cells_add_var && idx == 3)
              write_testfile_for_lib_irmaformuz "(VarType) #{ma}"
            elsif m == :cells_add && idx == 1
              write_testfile_for_lib_irmaformuz "(char *) \"#{ma}\""
            elsif m == :configurePR
              write_testfile_for_lib_irmaformuz idx == 1 ? 'pr_cells' : "(char *) \"#{ma}\""
            else
              case ma
              when CellVariables
                write_testfile_for_lib_irmaformuz %i(cells_add_var cells_get_var).include?(m) ? 'cv' : 'pr_cells'
              when false, true
                write_testfile_for_lib_irmaformuz ma
              else
                write_testfile_for_lib_irmaformuz '"' + ma.to_s.gsub('"', '\"').split("\n").join("\\n\"\n\"") + '"'
              end
            end
          end
        end
        write_testfile_for_lib_irmaformuz ");\n"
      end
    end

    VarType = enum(
      :type_err,      -1,
      :type_not,      DECLARED_VAR_TYPE_NOT,
      :type_str,      DECLARED_VAR_TYPE_STR,
      :type_nbr,      DECLARED_VAR_TYPE_NBR,
      :type_int,      DECLARED_VAR_TYPE_INT,
      :type_str_list, 21,
      :type_nbr_list, 22,
      :type_int_list, 23
    )

    class VarValue < FFI::Union
      layout :iVal, :int, :dVal, :double, :sVal, :string
    end

    class Variable < FFI::Struct
      layout :value, VarValue, :type, VarType, :sep, [:char, 2]

      def to_s(force = false) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        @to_s = nil if force
        @to_s ||= case self[:type]
                  when :type_str
                    self[:value][:sVal].to_s
                  when :type_int
                    (s = self[:value][:iVal].to_s) == PARSER_NULL_INTEGER ? PARSER_NULL_CHAR : s
                  when :type_nbr
                    # format('%f', self[:value][:dVal])
                    (s = format('%g', self[:value][:dVal])) == PARSER_NULL_FLOAT ? PARSER_NULL_CHAR : s
                  when :type_not
                    PARSER_NULL_CHAR
                  else
                    raise "Unexpected #{self[:type]} type for variable"
                  end
      end

      alias value to_s

      def tipo_valore(force = false)
        @tipo_valore = nil if force
        @tipo_valore ||= DECLARED_VAR_TYPE_MAP[VarType[self[:type]]]
      end

      def tipo_valore_compatibile?(t) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if t == TIPO_VALORE_CHAR || tipo_valore == t || (tipo_valore == TIPO_VALORE_INTEGER && t == TIPO_VALORE_FLOAT) || (tipo_valore == TIPO_VALORE_CHAR && (value == format('%g', value.to_f)))
          true
        else
          false
        end
      end

      def parser_null?
        (to_s == PARSER_NULL_CHAR) ? true : false
      end
    end

    class DeclaredVar < FFI::Struct
      layout :name, :string, :v, Variable

      def name
        self[:name].to_s
      end

      def value
        self[:v].value
      end

      def tipo_valore
        self[:v].tipo_valore
      end

      def tipo_valore_compatibile?(tipo)
        self[:v].tipo_valore_compatibile?(tipo)
      end
    end

    class Result < FFI::Struct
      layout :v, Variable.ptr, :error, :string, :conditional, :int, :inRange, :int

      def value
        @value ||= begin
                     raise "Error returned from rule evaluation: #{error}" unless ok?
                     self[:v].to_s
                   end
      end

      def tipo_valore
        @tipo_valore ||= begin
                           raise "Error returned from rule evaluation: #{error}" unless ok?
                           self[:v].tipo_valore
                         end
      end

      def null_no_save?
        ok? && (self[:v].null? || self[:v].parser_null?)
      end

      def tipo_valore_compatibile?(tipo)
        ok? && self[:v].tipo_valore_compatibile?(tipo)
      end

      def ok?
        error.empty?
      end

      def error
        @error ||= self[:error].to_s
      end

      def to_json
        (ok? ? { value: value, tipo_valore: tipo_valore } : { error: error }).to_json
      end
    end

    class DeclaredVarList < FFI::Struct
      layout :size, :int, :declaredVar, DeclaredVar.ptr
    end

    class CellVariables < FFI::Struct
      layout :name, [:char, 32], :declaredVarList, DeclaredVarList, :hh, :pointer

      extend FFI::Library
      ffi_lib 'IrmaFormuz'

      class <<self
        extend FFI::Library
        ffi_lib 'IrmaFormuz'

        attach_function :createCellVariables, [:string], CellVariables.ptr
        alias create createCellVariables

        if ENV['OUTPUT_FOR_TEST_LIB_IRMAFORMUZ']
          # attenzione all'alias che non fa intercettare il metodo ffi direttamente se chiamato tramite create
          %i(createCellVariables create).each do |m|
            alias_method "#{m}_orig".to_sym, m
            define_method(m) do |*args|
              NativeExprParser.write_testfile_for_lib_irmaformuz_method_call(:createCellVariables, nil, *args)
              send("#{m}_orig".to_sym, *args)
            end
          end
        end
      end

      attach_function :freeCellVariables,  [CellVariables.ptr],                            :void
      attach_function :cells_add_var,      [CellVariables.ptr, :string, :string, VarType], DeclaredVar.ptr
      attach_function :cells_get_var,      [CellVariables.ptr, :string],                   DeclaredVar.ptr

      if ENV['OUTPUT_FOR_TEST_LIB_IRMAFORMUZ']
        %i(freeCellVariables cells_add_var cells_get_var).each do |m|
          alias_method "#{m}_orig".to_sym, m
          define_method(m) do |*args|
            NativeExprParser.write_testfile_for_lib_irmaformuz_method_call(m, 'cv', *args)
            send("#{m}_orig".to_sym, *args)
          end
        end
      end

      def free
        freeCellVariables(self)
      end

      def name
        self[:name].to_s
      end

      def add(name:, value:, type: nil, tipo_valore: nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if value.nil? || value == ''
          value = PARSER_NULL_CHAR
          type = DECLARED_VAR_TYPE_STR
        end
        type ||= tipo_valore ? TIPO_VALORE_MAP[tipo_valore] : nil
        raise "CellVariables#add type '#{type}' is invalid" unless type.nil? || DECLARED_VAR_TYPES.include?(type)
        res = cells_add_var(self, name.to_s, value.to_s, type || DECLARED_VAR_TYPE_STR)
        res.null? ? nil : res
      end

      def get(name)
        res = cells_get_var(self, name.upcase)
        res.null? ? nil : res
      end
    end

    class PrCells
      extend FFI::Library
      ffi_lib 'IrmaFormuz'

      attach_function :cells_init,    [],                                             CellVariables.ptr
      attach_function :cells_free,    [CellVariables.ptr],                            :void
      attach_function :cells_count,   [CellVariables.ptr],                            :int
      attach_function :cells_add,     [CellVariables.ptr, :pointer, :bool],           CellVariables.ptr
      attach_function :cells_get,     [CellVariables.ptr, :pointer],                  CellVariables.ptr

      if ENV['OUTPUT_FOR_TEST_LIB_IRMAFORMUZ']
        %i(cells_init cells_free cells_add cells_get).each do |m|
          alias_method "#{m}_orig".to_sym, m
          define_method(m) do |*args|
            NativeExprParser.write_testfile_for_lib_irmaformuz_method_call(m, 'pr_cells', *args)
            send("#{m}_orig".to_sym, *args)
          end
        end
      end

      attr_reader :pr

      def initialize
        @pr = cells_init
      end

      def free
        cells_free(@pr) if @pr
        @pr = nil
      end

      def count
        @pr ? cells_count(@pr) : 0
      end

      alias size count

      def add(name, check_existance: false)
        res = cells_add(@pr, name.upcase, check_existance ? true : false)
        res.null? ? nil : res
      end

      def get(name)
        res = cells_get(@pr, name.upcase)
        res.null? ? nil : res
      end
    end

    #
    attach_function :cacheHits,       [:long],                                      :long
    attach_function :configurePR,     [:long, CellVariables.ptr, :string, :string], Result.ptr
    attach_function :parserCacheSize, [:long],                                      :long
    attach_function :formuz,          [:long, :pointer],                            Result.ptr
    attach_function :formuzForPrCell, [:long, :pointer, CellVariables.ptr, :string, :string], Result.ptr
    attach_function :initParser,      [],                                           :long
    attach_function :freeParser,      [:long],                                      :void
    attach_function :freeParserCache, [:long],                                      :void
    attach_function :loadDeclaredVar, [:long, :pointer, :pointer, VarType],         DeclaredVar.ptr
    attach_function :resetParser,     [:long, :bool],                               :long
    attach_function :searchVariable,  [:long, :string],                             Variable.ptr

    if ENV['OUTPUT_FOR_TEST_LIB_IRMAFORMUZ']
      %i(configurePR formuz formuzForPrCell initParser freeParser freeParserCache loadDeclaredVar resetParser).each do |m|
        alias_method "#{m}_orig".to_sym, m
        define_method(m) do |*args|
          NativeExprParser.write_testfile_for_lib_irmaformuz_method_call(m, 'ctx', *args)
          send("#{m}_orig".to_sym, *args)
        end
      end
    end

    attr_reader :result

    def initialize
      @evaluate_calls = 0
    end

    def context
      @context ||= initParser
      @context
    end

    # IMPORTANT: always call this method when done with the instance
    def free
      freeParser(@context) if @context
      @context = nil
      self
    end

    def reset(full: false)
      @result = nil
      resetParser(@context, full ? true : false) if @context
      self
    end

    def load_declared_var(name:, value:, type: nil, tipo_valore: nil, replace_empty: true) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if replace_empty && (value.nil? || value == '')
        value = PARSER_NULL_CHAR
        type = DECLARED_VAR_TYPE_STR
      end
      type ||= tipo_valore ? TIPO_VALORE_MAP[tipo_valore] : nil
      raise "load_declared_var type '#{type}' is invalid" unless type.nil? || DECLARED_VAR_TYPES.include?(type)
      res = loadDeclaredVar(context, name.upcase, value.to_s, type || DECLARED_VAR_TYPE_STR)
      res.null? ? nil : res
    end

    def load_variables(variables = {})
      reset(full: true)
      load_declared_var(name: 'NULL', value: PARSER_NULL_CHAR)
      load_declared_var(name: 'EMPTY', value: '', replace_empty: false)
      n = 0
      variables.each do |v, v_info|
        next unless v_info.is_a?(Array)
        load_declared_var(name: v, value: v_info[0], tipo_valore: v_info[1])
        n += 1
      end
      n
    end

    def search_variable(name)
      res = searchVariable(context, name)
      res.null? ? nil : res
    end

    def configure_pr(pr:, cell: nil, adj: nil)
      res = configurePR(context, pr.is_a?(PrCells) ? pr.pr : pr, cell, adj)
      raise res.error unless res.null? || res.ok?
    end

    def evaluate_formula(rule)
      @evaluate_calls += 1
      reset
      @result = formuz(context, rule)
    rescue StandardError, java.lang.Throwable => e
      raise "unexpected exception in evaluate_formula #{rule.gsub("\n", '\n')}: #{e}"
    end

    # optimized call
    def evaluate_formula_for_pr_cell(rule:, pr:, cell: nil, adj: nil)
      @evaluate_calls += 1
      @result = formuzForPrCell(context, rule, pr.is_a?(PrCells) ? pr.pr : pr, cell, adj)
    rescue StandardError, java.lang.Throwable => e
      raise "unexpected exception in evaluate_formula #{rule.gsub("\n", '\n')}: #{e}"
    end

    def free_cache
      freeParserCache(context)
    end

    def cache_size
      parserCacheSize(context)
    end

    def cache_hits
      cacheHits(context)
    end

    def stats
      { evaluate_calls: @evaluate_calls, cache_size: cache_size, cache_hits: cache_hits }
    end
  end
end
