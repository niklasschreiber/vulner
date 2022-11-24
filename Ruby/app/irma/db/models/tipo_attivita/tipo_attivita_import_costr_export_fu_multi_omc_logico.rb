# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_import_costruttore_omc_logico.rb')
require File.join(__dir__, 'tipo_attivita_export_formato_utente_multi_omc_logico')

module Irma
  module Db
    #
    # 20180226 - OBSOLETA
    class TipoAttivitaImportCostrExportFuMultiOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_COSTRUTTORE_EXPORT_FORMATO_UTENTE_MULTI_OMC_LOGICO

      config.define EXPIRE_IMPORT_COSTRUTTORE = :expire_import_costruttore, 5400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_EXPORT_FU = :expire_export_fu, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaImportCostruttoreOmcLogico::Util
      include TipoAttivitaExportFormatoUtenteMultiOmcLogico::Util

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        res = [contenitore_root = crea_root_info_attivita('expire_sec' => (config[EXPIRE_IMPORT_COSTRUTTORE] + config[EXPIRE_EXPORT_FU] * opts['lista_sistemi'].size),
                                                          'competenze' => competenze_lista_obj(opts['lista_sistemi']))]

        lista_sistemi_id = []
        descr = []
        opts['lista_sistemi'].each do |xxx|
          sss = xxx[0]
          lista_sistemi_id << sss.id
          descr << sss.full_descr
        end
        descr_tot = descr.join(' - ')

        # import: [I1,I2,...,In]
        contenitore = crea_contenitore_info_attivita("#{KEY_PREFIX_CONTENITORE}1",
                                                     format_msg(:ATTIVITA_COMANDO_IMPORT_COSTRUTTORE_OMC_LOGICO, descr: descr_tot),
                                                     'expire_sec' => config[EXPIRE_IMPORT_COSTRUTTORE], 'competenze' => competenze_lista_obj(opts['lista_sistemi']))
        res << contenitore
        res += TipoAttivitaImportCostruttoreOmcLogico.ia_import_costruttore(foglia_last_index(res), contenitore, opts)

        # export: E_multi
        # f_e = TipoAttivitaExportFormatoUtenteMultiOmcLogico.ia_export_fu_multi(foglia_last_index(res), root, opts.merge('lista_sistemi' => lista_sistemi_id)) do |ic|
        f_e = TipoAttivitaExportFormatoUtenteMultiOmcLogico.ia_export_fu_multi(foglia_last_index(res), contenitore_root, opts) do |ic|
          ic['info']['dipende_da'] = [contenitore['key']]
        end
        res += f_e
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
