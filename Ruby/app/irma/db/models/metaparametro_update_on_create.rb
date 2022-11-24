# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180625
#

require 'irma/db/metaparametri_flag_speciali'
module Irma
  module Db
    #
    class MetaparametroUpdateOnCreate < Model(:metaparametri_update_on_create)
      include MetaparametroFlagSpeciali

      def self.fisico?
        false
      end

      def self.imposta_metaparametri(id_vendor_release: nil, mm_fisico: true)
        common_opts = { flag: :is_update_on_create, default_value: false, new_value: true }
        aggiorna_flag_metaparametri(id_vendor_release: id_vendor_release, **common_opts)
        aggiorna_flag_metaparametri_fisici(common_opts) if mm_fisico
      end
    end
  end
end

# == Schema Information
#
# Tabella: metaparametri_update_on_create
#
#  full_name       :string(512)     non nullo
#  id              :integer         non nullo, default(nextval('metaparametri_update_on_create_id_seq')), chiave primaria
#  naming_path     :string(1024)    non nullo
#  rete_id         :integer         non nullo, riferimento a reti.id
#  vendor_id       :integer         non nullo, riferimento a vendors.id
#  vendor_releases :json
#
