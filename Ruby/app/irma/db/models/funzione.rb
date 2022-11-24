# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151123
#

module Irma
  module Db
    #
    class Funzione < Model(:funzioni)
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true
    end
  end
end

# == Schema Information
#
# Tabella: funzioni
#
#  created_at      :datetime
#  descr           :string(256)     non nullo
#  dipendenze      :json
#  id              :integer         non nullo, chiave primaria
#  nome            :string(64)      non nullo
#  tipo_competenza :integer         default(0)
#  updated_at      :datetime
#
