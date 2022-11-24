# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151123
#

module Irma
  module Db
    #
    class TipoSegnalazione < Model(:tipi_segnalazioni)
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true

      # one_to_many :segnalazioni, class: full_class_for_model(:Segnalazione)
      validates_constant :gravita
      validates_constant :categoria

      def messaggio(hash = {})
        format_msg(identificativo_messaggio, hash)
      end

      def full_nome
        @full_nome ||= [categoria, nome].join('_').upcase
      end
    end
  end
end

# == Schema Information
#
# Tabella: tipi_segnalazioni
#
#  azione_recovery          :string
#  categoria                :string(256)     non nullo
#  created_at               :datetime
#  descr                    :string
#  funzione_id              :integer         riferimento a funzioni.id
#  genere_per_update        :integer
#  gravita                  :integer         non nullo
#  id                       :integer         non nullo, chiave primaria
#  identificativo_messaggio :string(256)     non nullo
#  nome                     :string(256)     non nullo
#  to_update_adrn           :boolean         non nullo, default(false)
#  updated_at               :datetime
#
# Indici:
#
#  uidx_tipi_segnalazioni  (categoria,funzione_id,nome) UNIQUE
#
