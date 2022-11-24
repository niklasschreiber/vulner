# vim: set fileencoding=utf-8
#
# Author: R. Scandale
#
# Creation date: 20181002
#

module Irma
  module Db
    #
    class EtichettaEccezioniEliminata < Model(:etichette_eccezioni_eliminate)
      # do not allow update after creation
      def before_update
        false
      end
    end
  end
end

# == Schema Information
#
# Tabella: etichette_eccezioni_eliminate
#
#  account_id            :integer         non nullo
#  created_at            :datetime
#  data_ultimo_import    :datetime
#  descr                 :string
#  eccezioni_nette       :boolean         non nullo, default(false)
#  ended_at              :datetime
#  id                    :bigint
#  matricola             :string(32)
#  matricola_creatore    :string(32)
#  nome                  :string(128)     non nullo
#  profilo               :string(32)
#  tipo                  :integer         non nullo
#  updated_at            :datetime
#  utente_creatore_descr :string(32)
#  utente_descr          :string(32)
#  variazioni            :json
#
