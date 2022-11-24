# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20151123
#

module Irma
  module Db
    #
    class AllarmeChiuso < Model(:allarmi_chiusi)
      unrestrict_primary_key

      many_to_one :tipo_allarme, class: full_class_for_model(:TipoAllarme)

      # do not allow update (a trigger in the db should be created too)
      def before_update
        raise 'Aggiornamento evento non consentito per policy di sicurezza'
      end

      def self.crea(hash)
        attrs = hash.dup.merge(data_chiusura: Time.now)
        create(attrs)
      end
    end
  end
end

# == Schema Information
#
# Tabella: allarmi_chiusi
#
#  categoria        :string(64)      non nullo
#  contatore        :integer         non nullo, default(1)
#  created_at       :datetime
#  data_chiusura    :datetime
#  data_in_carico   :datetime
#  data_notifica    :datetime
#  descr            :string
#  gravita          :integer         non nullo
#  id               :bigint          non nullo, chiave primaria
#  id_evento        :integer
#  id_risorsa       :string(64)      non nullo
#  in_carico        :integer         non nullo, default(0)
#  nome             :string(64)      non nullo
#  note_chiusura    :string
#  note_in_carico   :string
#  pid              :integer
#  tipo_allarme_id  :integer         riferimento a tipi_allarmi.id
#  updated_at       :datetime
#  user_fullname    :string(64)
#  user_funz        :string(32)
#  user_name        :string(32)
#  user_type        :string(1)       default('')
#  utente_in_carico :string(64)
#
