# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151123
#

module Irma
  module Db
    #
    class TipoEvento < Model(:tipi_eventi)
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true

      one_to_many :eventi, class: full_class_for_model(:Evento)

      validates_constant :gravita
    end
  end
end

# == Schema Information
#
# Tabella: tipi_eventi
#
#  categoria  :string(64)      non nullo
#  created_at :datetime
#  descr      :string
#  gravita    :integer         non nullo
#  id         :integer         non nullo, chiave primaria
#  nome       :string(64)
#  updated_at :datetime
#
# Indici:
#
#  uidx_tipi_eventi  (categoria,nome) UNIQUE
#
