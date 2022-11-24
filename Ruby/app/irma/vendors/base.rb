# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151116
#

module Irma
  #
  (VENDOR_MODULES = %w(vendor_util rete_util calcolo_util pr_util fdc_util).freeze).each { |f| require_relative "modules/#{f}" }
  module Vendor
    class VendorNonDefinito < IrmaException; end

    # rubocop:disable Metrics/AbcSize
    def self.instance(vendor:, rete: nil, **hash)
      options = { vendor: vendor, rete: rete }
      hash.each { |k, v| options[k.to_sym] = v }
      vc = nil
      begin
        options[:vendor] = Constant.value(:vendor, vendor.downcase) unless vendor.is_a?(Integer)
        options[:rete] = Constant.value(:rete, rete.downcase) if rete && !rete.is_a?(Integer)
        klass_name = [Constant.key(:vendor, options[:vendor]).to_s]
        klass_name << Constant.key(:rete, options[:rete]).to_s if options[:rete]

        vc = class_eval(klass_name.join('_').camelize)

      rescue => e
        raise VendorNonDefinito, ("Vendor: nessuna classe definita per gestire il vendor \"#{vendor}\", rete \"#{rete}\": #{e}")
      end
      vc.new(options)
    end

    FLAG_ADJ_CELL = [
      NO_FLAG             = 0,
      FLAG_CELL           = 1,
      FLAG_ADJ_EXT        = 2,
      FLAG_CELL_PARENT    = 3,
      FLAG_ADJ_EXT_PARENT = 4,
      FLAG_GENERIC_PARENT = 5
    ].freeze

    class Base
      attr_accessor :logger
      attr_reader :options, :log_prefix

      def initialize(hash = {})
        @options                   = OpenStruct.new(hash)
        @logger                    = @options[:logger] || Irma.logger
        @log_prefix                = @options[:log_prefix]
      end

      def root_entita(_formato_audit)
        nil
      end

      def competenza_base_sistema?(_mo, _saa)
        true
      end

      def self.definisci_classe_rete(rete:, &block)
        klass = Vendor.const_set("#{Constant.key(:vendor, vendor)}_#{Constant.key(:rete, rete)}".camelize, Class.new(self))
        VENDOR_MODULES.each { |vm| klass.include Vendor::Rete.const_get(vm.camelize) }
        # le inizializzazioni comuni pre blocco vanno inserite qui
        klass.rete rete
        klass.class_eval(&block)  if block_given?
        # le inizializzazioni comuni post blocco vanno inserite qui
        klass
      end
    end # fine class Base

    def self.definisci_classe_vendor(vendor:, &block)
      klass = Vendor.const_set(Constant.key(:vendor, vendor).to_s.camelize, Class.new(Base))
      VENDOR_MODULES.each { |vm| klass.include Vendor.const_get(vm.camelize) }
      # le inizializzazioni comuni pre blocco vanno inserite qui
      klass.vendor vendor
      klass.class_eval(&block) if block_given?
      # le inizializzazioni comuni post blocco vanno inserite qui
      cr = klass.classi_rete
      klass.default_nodo_naming_path_rete(cr.each_with_object({}) { |v, res| res[v.rete] = v.default_nodo_naming_path })
      klass.default_cella_naming_path_rete(cr.each_with_object({}) { |v, res| res[v.rete] = v.default_cella_naming_path })
      klass.default_formato_audit_rete(cr.each_with_object({}) { |v, res| res[v.rete] = v.default_formato_audit })
      klass.assegna_meta_entita_cella
      klass.popola_meta_entita_adiacenza_per_omc_fisico
      klass
    end

    Constant.constants(:vendor).each do |c|
      begin
        require_relative c.key.to_s.downcase
        nome_classe_vendor = c.key.to_s.capitalize
        raise "Classe vendor #{nome_classe_vendor} non definita nel file #{c.key}.rb" unless const_defined?(nome_classe_vendor)
        vendor_class = class_eval(nome_classe_vendor)
        raise "Classe vendor #{nome_classe_vendor} non figlia di Base" unless vendor_class.superclass == Base
        raise "Classe vendor #{nome_classe_vendor} non creata correttamente (definisci_classe_vendor non utilizzato)" unless vendor_class.vendor
      rescue => e
        STDERR.puts "WARNING: implementazione vendor #{c.key} non caricata correttamente: #{e}"
        raise
      end
    end
  end
end
