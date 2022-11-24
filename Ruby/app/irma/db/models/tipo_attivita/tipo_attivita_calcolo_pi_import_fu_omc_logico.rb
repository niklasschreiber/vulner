# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_calcolo_pi_omc_logico.rb')
require File.join(__dir__, 'tipo_attivita_pi_import_formato_utente_omc_logico.rb')

module Irma
  module Db
    #
    class TipoAttivitaCalcoloPiImportFuOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_CALCOLO_PI_IMPORT_FU_OMC_LOGICO

      config.define EXPIRE_CALCOLO_PI = :expire_calcolo_pi, 5400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_PI_IMPORT_FORMATO_UTENTE = :expire_pi_import_formato_utente, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaCalcoloPiOmcLogico::Util
      include TipoAttivitaPiImportFormatoUtenteOmcLogico::Util

      def self.info_attivita(opts = {}) # rubocop: disable Metrics/AbcSize
        lista_sistemi = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        expire_s = config[EXPIRE_CALCOLO_PI] + config[EXPIRE_PI_IMPORT_FORMATO_UTENTE]
        # root
        res = [contenitore_root = crea_root_info_attivita('expire_sec' => expire_s, 'competenze' => competenze_lista_obj(lista_sistemi))]
        # calcolo
        opts['omc_id'] = lista_sistemi
        f_c = TipoAttivitaCalcoloPiOmcLogico.ia_calcolo_pi(foglia_last_index(res), contenitore_root, opts).last
        res << f_c
        # pi_import_fu
        f_i = TipoAttivitaPiImportFormatoUtenteOmcLogico.ia_pi_import_fu(foglia_last_index(res), contenitore_root, opts) do |ic|
          ic['dipende_da'] = [f_c['key']]
        end.last
        res << f_i
        res
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
