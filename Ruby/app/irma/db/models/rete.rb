# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

module Irma
  module Db
    #
    class Rete < Model(:reti)
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true

      one_to_many :vendor_releases, class: full_class_for_model(:VendorRelease)
      one_to_many :sistemi, class: full_class_for_model(:Sistema)
    end
  end
end

# == Schema Information
#
# Tabella: reti
#
#  alias      :string(32)      non nullo
#  created_at :datetime
#  descr      :string(64)      non nullo
#  id         :integer         non nullo, chiave primaria
#  nome       :string(32)      non nullo
#  updated_at :datetime
#
# Indici:
#
#  uidx_reti  (nome) UNIQUE
#
