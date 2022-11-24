# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

module Irma
  module Db
    #
    class Vendor < Model(:vendors)
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true

      one_to_many :vendor_releases, class: full_class_for_model(:VendorRelease)
      one_to_many :omc_fisici, class: full_class_for_model(:OmcFisico)
    end
  end
end

# == Schema Information
#
# Tabella: vendors
#
#  created_at :datetime
#  id         :integer         non nullo, chiave primaria
#  nome       :string(32)      non nullo
#  sigla      :string(32)      non nullo
#  updated_at :datetime
#
# Indici:
#
#  uidx_vendors  (sigla) UNIQUE
#
