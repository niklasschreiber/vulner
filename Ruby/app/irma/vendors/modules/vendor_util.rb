# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190117
#

module Irma
  #
  module Vendor
    def self.const_per_tutte_le_reti(v, default_value:)
      mea = {}
      Constant.values(:rete).each { |k| mea[k] = (v || {})[k] || default_value }
      mea
    end

    module Rete
      module VendorUtil
        # questo modulo deve essere vuoto
      end
    end
    module VendorUtil
      extends_host_with :ClassMethods

      module ClassMethods
        def assegna_meta_entita_cella
          mec = Constant.values(:rete).each_with_object({}) do |rete, res|
            res[rete] = (np = default_cella_naming_path_rete[rete]) && np[np.rindex(NAMING_PATH_SEP) + 1, np.length]
          end
          class_variable_set(:@@meta_entita_cella, mec)
        end

        def classi_rete # rubocop:disable Metrics/AbcSize
          nome_classe_vendor = Constant.key(:vendor, vendor).to_s.camelize
          @classi_rete ||= Constant.constant(:vendor, vendor).info[:reti].map do |rete_id|
            nome_classe_vendor_rete = nome_classe_vendor + Constant.label(:rete, rete_id).capitalize
            raise "Classe vendor #{nome_classe_vendor_rete} non definita nel file #{Constant.key(:vendor, vendor)}.rb" unless Vendor.const_defined?(nome_classe_vendor_rete)
            vendor_rete_class = Vendor.class_eval(nome_classe_vendor_rete)
            raise "Classe vendor #{nome_classe_vendor_rete} non figlia di #{self}" unless vendor_rete_class.superclass == self
            vendor_rete_class
          end
        end

        def meta_entita_cella(rete)
          class_variable_get(:@@meta_entita_cella)[rete]
        end

        def popola_meta_entita_adiacenza_per_omc_fisico # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          tmp_rel = {}
          tmp_adj = Hash.new([])
          tmp_mera = {}
          descendants.each do |klass|
            Constant.values(:rete).each do |rete|
              tmp_rel[rete] ||= {}
              tmp_rel[rete].update(klass.meta_entita_relazioni_adiacenza[rete] || {})
              tmp_adj[rete] |= (klass.meta_entita_adiacenza[rete] || [])
            end
            ki = klass.new
            (klass.meta_entita_relazioni_adiacenza || {}).values.each { |np_info| np_info.keys.each { |np| tmp_mera[np] = ki.method(:estrai_cs_ca_da_relazione) } }
          end
          meta_entita_relazioni_adiacenza tmp_rel.freeze
          meta_entita_adiacenza tmp_adj.freeze
          mera tmp_mera.freeze
          self
        end

        class_attribute :default_cella_naming_path_rete, :default_formato_audit_of, :default_formato_audit_rete, :default_nodo_naming_path_rete, :vendor,
                        meta_entita_relazioni_adiacenza_inter:  {},
                        meta_entita_relazioni_adiacenza_intra:  {},
                        mera:                                   {},
                        meta_entita_adiacenza:                  ->(v) { Vendor.const_per_tutte_le_reti(v, default_value: []) },
                        meta_entita_relazioni_adiacenza:        ->(v) { Vendor.const_per_tutte_le_reti(v, default_value: {}) },
                        meta_entita_relazioni_adiacenza_prefix: ->(v) { Vendor.const_per_tutte_le_reti(v, default_value: {}) }
      end

      # generazione automatica dei metodi di instanza per tutti i metodi di classe con nessuno o un parametro opzionale
      clona_instance_methods_da_class_methods ClassMethods

      def cella_parent(np)
        default_cella_naming_path_rete.values.flatten.find { |np_cell| np_cell.index(np) }
      end

      def estrai_cs_ca_da_relazione(entita)
        m = self.class.mera[entita.naming_path]
        m ? m.call(entita) : []
      end

      def get_rete_from_meta_entita_adj(np_adj)
        meta_entita_adiacenza.each { |k, v| return k if v.include?(np_adj) }
      end

      def get_rete_from_meta_entita_rel_adj(np_adj)
        meta_entita_relazioni_adiacenza.each { |k, v| return k if v.key?(np_adj) }
      end

      def get_rete_from_np(np)
        Constant.values(:rete).each do |rete|
          return rete if (dnnp = default_nodo_naming_path_rete[rete]) && np.start_with?(dnnp)
        end
        nil
      end

      def imposta_flag_cell_adj(np)
        if naming_path_cella?(np)
          FLAG_CELL
        elsif meta_entita_adiacenza?(np)
          FLAG_ADJ_EXT
        elsif cella_parent(np)
          meta_entita_adiacenza.values.flatten.find { |np_adj| np_adj.index(np) } ? FLAG_GENERIC_PARENT : FLAG_CELL_PARENT
        elsif  meta_entita_adiacenza.values.flatten.find { |np_adj| np_adj.index(np) }
          FLAG_ADJ_EXT_PARENT
        else
          NO_FLAG
        end
      end

      def meta_entita_adiacenza?(me)
        (@meta_entita_lista_adiacenze ||= meta_entita_adiacenza.values.flatten).include?(me)
      end

      def meta_entita_cella(rete)
        self.class.meta_entita_cella(rete)
      end

      def meta_entita_relazione?(me)
        (@meta_entita_relazione ||= meta_entita_relazioni_adiacenza.values.map(&:keys).flatten).include?(me)
      end

      def naming_path_cella?(np)
        default_cella_naming_path_rete.values.include?(np)
      end
    end
  end
end
