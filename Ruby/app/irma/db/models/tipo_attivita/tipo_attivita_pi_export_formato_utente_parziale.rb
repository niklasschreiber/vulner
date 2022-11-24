# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_pi_export_formato_utente.rb')

module Irma
  module Db
    #
    class TipoAttivitaPiExportFormatoUtenteParziale < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_PI_EXPORT_FU_PARZIALE

      config.define EXPIRE_PI_EXPORT_FU = :pi_expire_export_fu, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaPiExportFormatoUtente::Util

      def self.info_attivita(opts = {})
        opts['lista_pi'] = lista_progetti_irma_id_to_obj(opts['lista_pi'])
        info_attivita_pi_export_fu(opts)
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
