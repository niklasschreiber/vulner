# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190117
#

module Irma
  #
  module Vendor
    PR_CAMPI_OBBLIGATORI = [
      PR_OMC_FISICO = 'OMC_FISICO'.freeze,
      PR_SISTEMA    = 'SISTEMA'.freeze,
      PR_CELLA      = 'CELLA'.freeze,
      PR_CGI        = 'CGI'.freeze
    ].freeze

    module PrUtil
    end

    module Rete
      module PrUtil
        extends_host_with :ClassMethods

        module ClassMethods
          class_attribute :pr_campi_adiacenza, :pr_campi_per_controlli, :pr_nome_id_nodo, :pr_nome_nodo, :pr_nome_release_nodo
        end

        # generazione automatica dei metodi di instanza per tutti i metodi di classe con nessuno o un parametro opzionale
        clona_instance_methods_da_class_methods ClassMethods

        def pr_campi_obbligatori
          campi_obbligatori = []
          PR_CAMPI_OBBLIGATORI.each { |c| campi_obbligatori << c }
          campi_obbligatori.concat([pr_nome_nodo, pr_nome_release_nodo, pr_nome_id_nodo]).compact
        end
      end
    end
  end
end
