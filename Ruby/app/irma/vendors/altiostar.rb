# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190115
#

module Irma
  module Vendor
    #
    definisci_classe_vendor(vendor: VENDOR_ALTIOSTAR) do
      default_formato_audit_of DEFAULT_FORMATO_AUDIT_IDL

      next unless defined?(RETE_5G)
      definisci_classe_rete(rete: RETE_5G) do
        # TODO
      end
    end
  end
end
