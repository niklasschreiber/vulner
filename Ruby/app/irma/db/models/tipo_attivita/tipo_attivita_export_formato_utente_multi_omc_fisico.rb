# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_export_formato_utente_multi_omc_logico.rb')

module Irma
  module Db
    #
    # 20180226 - TipoAttivita OBSOLETA
    class TipoAttivitaExportFormatoUtenteMultiOmcFisico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_FU_MULTI_OMC_FISICO

      config.define EXPIRE_EXPORT_FU = :expire_export_fu, 3600, descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaExportFormatoUtenteMultiOmcLogico::Util

      def self.omc_fisico?
        true
      end

      def self.info_attivita(opts = {})
        info_attivita_export_fu_multi(opts) do |info_comando|
          info_comando['comando'] = COMANDO_EXPORT_FU_MULTI_OMC_FISICO
          info_comando['parametri_comuni']['omc_fisico'] = true
        end
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
