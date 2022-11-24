# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20181112
#

require File.join(__dir__, 'tipo_attivita_import_costruttore_omc_fisico.rb')
require File.join(__dir__, 'tipo_attivita_consistency_check.rb')

module Irma
  module Db
    #
    class TipoAttivitaImportCostruttoreEConsistencyCheckTotale < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_COSTRUTTORE_E_CONSISTENCY_CHECK_TOTALE

      config.define EXPIRE_IMPORT_COSTRUTTORE = :expire_import_costruttore, 14_400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:28800})'

      config.define EXPIRE_CONSISTENCY_CHECK = :expire_consistency_check, 14_400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:28800})'

      config.define EXPIRE_SINTESI_CONSISTENCY_CHECK = :expire_sintesi_consistency_check, 900,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:14400})'

      include TipoAttivitaImportCostruttoreOmcFisico::Util
      include TipoAttivitaConsistencyCheck::Util

      def self.info_attivita(options = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        opts = options.dup
        opts['lista_sistemi'] = TipoAttivitaImportCostruttoreOmcFisico.ricalcola_lista_sistemi(opts)
        aggiungi_opzioni_per_account(opts: opts, profilo: PROFILO_RPN)
        opts_root = {
          'expire_sec' => config[EXPIRE_IMPORT_COSTRUTTORE] + config[EXPIRE_CONSISTENCY_CHECK] + config[EXPIRE_SINTESI_CONSISTENCY_CHECK],
          'competenze' => competenze_lista_obj(opts['lista_sistemi'])
        }.merge(seleziona_opzioni_per_account(opts))

        res = [crea_root_info_attivita(opts_root)]
        index_contenitore = 0
        res << (contenitore_ic = crea_contenitore_info_attivita("#{KEY_PREFIX_CONTENITORE}#{index_contenitore += 1}", format_msg(:ATTIVITA_ROOT_IMPORT_COSTRUTTORE_TOTALE_OMC_FISICO),
                                                                'expire_sec' => config[EXPIRE_IMPORT_COSTRUTTORE], 'competenze' => competenze_lista_obj(opts['lista_sistemi'])))
        opts['dipendenze_per_cc'] = {}
        res += TipoAttivitaImportCostruttoreOmcFisico.ia_import_costruttore(foglia_last_index(res), contenitore_ic, opts)
        opts['lista_sistemi'] = lista_sistemi_per_cc(opts)
        res << (contenitore_cc = crea_contenitore_info_attivita("#{KEY_PREFIX_CONTENITORE}#{index_contenitore + 1}", format_msg(:ATTIVITA_ROOT_CONSISTENCY_CHECK_TOTALE),
                                                                'expire_sec' => config[EXPIRE_CONSISTENCY_CHECK], 'competenze' => competenze_lista_obj(opts['lista_sistemi'])))
        res += TipoAttivitaConsistencyCheck.ia_consistency_check(foglia_last_index(res), contenitore_cc, opts)
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
