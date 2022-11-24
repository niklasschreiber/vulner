# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151123
#

module Irma
  module Db
    # rubocop:disable Security/Eval
    class TipoAllarme < Model(:tipi_allarmi)
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true

      one_to_many :allarmi, class: full_class_for_model(:Allarme)

      validates_constant :gravita

      class FormatoIdRisorsaNonValido < IrmaException; end

      # Crea l'id_resource per un allarme usando l'hash +alarm_params+
      #
      # == Eccezioni
      # * FormatoIdRisorsaNonValido
      #
      def build_id_risorsa(alarm_params)
        raise FormatoIdRisorsaNonValido unless formato_id_risorsa
        # create format context variables
        ctx = alarm_params.dup
        begin
          res = eval %("#{formato_id_risorsa}")
          raise "Empty id_resource computed using format #{formato_id_risorsa} and context #{ctx.inspect}" if res == ''
        rescue => e
          raise FormatoIdRisorsaNonValido, e.to_s
        end
        res
      end
    end
  end
end

# == Schema Information
#
# Tabella: tipi_allarmi
#
#  categoria           :string(64)      non nullo
#  chiusura_automatica :integer         non nullo, default(0)
#  created_at          :datetime
#  descr               :string
#  formato_id_risorsa  :string(64)      non nullo
#  gravita             :integer         non nullo
#  id                  :integer         non nullo, chiave primaria
#  nome                :string(64)      non nullo
#  updated_at          :datetime
#
# Indici:
#
#  uidx_tipi_allarmi  (categoria,nome) UNIQUE
#
