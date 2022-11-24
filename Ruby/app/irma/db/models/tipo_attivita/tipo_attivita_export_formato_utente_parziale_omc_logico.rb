# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_export_formato_utente_omc_logico.rb')

module Irma
  module Db
    #
    class TipoAttivitaExportFormatoUtenteParzialeOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_FU_PARZIALE_OMC_LOGICO

      config.define EXPIRE_EXPORT_FU = :expire_export_fu, 3600,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_CA_ADE = :expire_ca_ade, 3600,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaExportFormatoUtenteOmcLogico::Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_export_fu(opts)
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
