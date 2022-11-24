# vim: set fileencoding=utf-8
#
# Author: R. Scandale
#
# Creation date: 20180604
#

require File.join(__dir__, 'tipo_attivita_import_formato_utente_omc_logico.rb')

module Irma
  module Db
    #
    class TipoAttivitaImportFormatoUtenteOmcFisico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_FU_OMC_FISICO

      config.define EXPIRE_IMPORT_FU = :expire_import_fu, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaImportFormatoUtenteOmcLogico::Util

      def self.omc_fisico?
        true
      end

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_import_fu(opts)
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
