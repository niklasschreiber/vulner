# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190117
#

module Irma
  #
  module Vendor
    module ReteUtil
      # questo modulo deve essere vuoto
    end

    module Rete
      module ReteUtil
        extends_host_with :ClassMethods

        module ClassMethods
          class_attribute :default_cella_naming_path, :default_formato_audit, :default_nodo_naming_path, :rete
        end

        # generazione automatica dei metodi di instanza per tutti i metodi di classe con nessuno o un parametro opzionale
        clona_instance_methods_da_class_methods ClassMethods

        def cella_parent(np)
          default_cella_naming_path.index(np)
        end

        def meta_entita_cella?(me)
          meta_entita_cella(rete).equal?(me)
        end

        def naming_path_cella
          default_cella_naming_path
        end

        def naming_path_cella?(np)
          default_cella_naming_path.eql?(np)
        end

        def naming_path_del_rel_adj
          naming_path_cella
        end
      end
    end
  end
end
