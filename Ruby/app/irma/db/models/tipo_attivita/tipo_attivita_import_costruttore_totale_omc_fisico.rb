# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_import_costruttore_omc_logico.rb')

module Irma
  module Db
    #
    class TipoAttivitaImportCostruttoreTotaleOmcFisico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_COSTRUTTORE_TOTALE_OMC_FISICO

      config.define EXPIRE_IMPORT_COSTRUTTORE = :expire_import_costruttore, 14_400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:28800})'

      include TipoAttivitaImportCostruttoreOmcLogico::Util

      def self.omc_fisico?
        true
      end

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = ricalcola_lista_sistemi(opts)
        aggiungi_opzioni_per_account(opts: opts, profilo: PROFILO_RPN)
        info_attivita_import_costruttore(opts)
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
