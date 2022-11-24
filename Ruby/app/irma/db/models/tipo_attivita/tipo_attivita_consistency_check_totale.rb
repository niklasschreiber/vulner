# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180305
#

require File.join(__dir__, 'tipo_attivita_consistency_check.rb')

module Irma
  module Db
    #
    class TipoAttivitaConsistencyCheckTotale < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_CONSISTENCY_CHECK_TOTALE

      config.define EXPIRE_CONSISTENCY_CHECK = :expire_consistency_check, 14_400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:28800})'

      config.define EXPIRE_SINTESI_CONSISTENCY_CHECK = :expire_sintesi_consistency_check, 3_600,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:14400})'

      include TipoAttivitaConsistencyCheck::Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_per_cc(opts)
        info_attivita_consistency_check(opts)
      end
    end
  end
end

# == Schema Information
#
# Tabella: tipi_attivita
#
#  broadcast  :boolean         non nullo, default(false)
#  created_at :datetime
#  descr      :string          default('')
#  id         :integer         non nullo, chiave primaria
#  kind       :string
#  nome       :string(128)     non nullo
#  singleton  :boolean         non nullo, default(false)
#  stato      :string(32)      default('attivo')
#  updated_at :datetime
#
# Indici:
#
#  uidx_tipo_attivita_kind  (kind) UNIQUE
#
