# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_report_comparativo_omc_logico.rb')

module Irma
  module Db
    #
    class TipoAttivitaReportComparativoOmcFisico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_REPORT_COMPARATIVO_OMC_FISICO

      config.define EXPIRE_REPORT_COMP = :expire_report_comp, 3600,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaReportComparativoOmcLogico::Util

      def self.omc_fisico?
        true
      end

      def self.info_attivita(opts = {})
        opts['omc_id'] = lista_sistemi_id_to_obj([[opts['omc_id']]])
        info_attivita_report_comparativo(opts)
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
