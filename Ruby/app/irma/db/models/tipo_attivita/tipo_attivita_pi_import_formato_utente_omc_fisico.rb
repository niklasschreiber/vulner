# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20161014
#

require File.join(__dir__, 'tipo_attivita_calcolo_pi_omc_logico.rb')

module Irma
  module Db
    #
    class TipoAttivitaPiImportFormatoUtenteOmcFisico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_PI_IMPORT_FU_OMC_FISICO

      # include TipoAttivitaPiImportFormatoUtenteOmcLogico::Util

      def self.omc_fisico?
        true
      end

      def self.info_attivita(_opts = {})
        raise "#{self}.info_attivita not yet implemented"
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
