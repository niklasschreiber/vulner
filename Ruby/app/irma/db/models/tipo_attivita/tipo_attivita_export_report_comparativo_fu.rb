# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_export_report_comparativo_totale.rb')

module Irma
  module Db
    #
    class TipoAttivitaExportReportComparativoFu < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_RC_FU

      config.define EXPIRE_EXPORT_RC = :expire_export_rc, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaExportReportComparativoTotale::Util

      def self.info_attivita(opts = {})
        opts['lista_rc'] = lista_report_comparativi_id_to_obj(opts['lista_rc_id'])
        opts['tipo_export'] = TIPO_EXPORT_REPORT_COMPARATIVO_FU
        info_attivita_export_rc(opts)
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
