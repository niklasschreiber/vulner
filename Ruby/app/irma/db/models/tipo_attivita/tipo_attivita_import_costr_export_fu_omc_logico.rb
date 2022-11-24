# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require File.join(__dir__, 'tipo_attivita_import_costruttore_omc_logico.rb')
require File.join(__dir__, 'tipo_attivita_export_formato_utente_omc_logico.rb')

module Irma
  module Db
    #
    class TipoAttivitaImportCostrExportFuOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_COSTRUTTORE_EXPORT_FORMATO_UTENTE_OMC_LOGICO

      include TipoAttivitaImportCostruttoreOmcLogico::Util
      include TipoAttivitaExportFormatoUtenteOmcLogico::Util

      config.define EXPIRE_IMPORT_COSTRUTTORE = :expire_import_costruttore, 5400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_EXPORT_FU = :expire_export_fu, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      #
      module Util
        extends_host_with :ClassMethod

        #
        module ClassMethod
          def info_attivita_import_c_export_fu_omc_logico(opts = {}, &_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize,  Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            label_contenitore = omc_fisico? ? :ATTIVITA_COMANDO_IMPORT_COSTR_EXPORT_FU_OMC_FISICO : :ATTIVITA_COMANDO_IMPORT_COSTR_EXPORT_FU_OMC_LOGICO
            classe_import = omc_fisico? ? TipoAttivitaImportCostruttoreOmcFisico : TipoAttivitaImportCostruttoreOmcLogico
            classe_export = omc_fisico? ? TipoAttivitaExportFormatoUtenteOmcFisico : TipoAttivitaExportFormatoUtenteOmcLogico
            ic_comuni = {}
            ic_comuni['omc_fisico'] = true if omc_fisico?
            yield(ic_comuni) if block_given?

            res = []
            contenitore_root = crea_root_info_attivita('competenze' => competenze_lista_obj(opts['lista_sistemi']))
            res << contenitore_root

            lista_sistemi = opts['lista_sistemi']
            quanti = lista_sistemi.count
            count_contenitori = 0
            count_foglie = 0
            contenitore = nil
            lista_sistemi.each do |xxx|
              # devo aggiungere I1->E1 se quanti=1, [In->En] altrimenti
              sistema, input_file = xxx
              ic = ic_comuni.merge('sistema' => sistema, 'descr' => sistema.full_descr, 'competenze' => { sistema.tipo_competenza => [sistema.id.to_s] })
              if quanti > 1
                count_contenitori += 1
                contenitore = crea_contenitore_info_attivita("#{KEY_PREFIX_CONTENITORE}#{count_contenitori}",
                                                             format_msg(label_contenitore, descr: sistema.full_descr), 'competenze' => ic['competenze'])
                res << contenitore
              end
              # foglia_import
              f_i = classe_import.ia_import_costruttore(count_foglie, contenitore || contenitore_root, opts.merge('lista_sistemi' => [xxx])) { |iicc| iicc.merge('artifacts' => [input_file]) }.first
              res << f_i
              count_foglie += 1
              # foglia export
              f_e = classe_export.ia_export_fu(count_foglie, contenitore || contenitore_root, opts.merge('lista_sistemi' => [[sistema]])) { |iicc| iicc['info']['dipende_da'] = [f_i['key']] }.first
              res << f_e
              count_foglie += 1
              if f_i['expire_sec'] && f_e['expire_sec']
                contenitore_root['expire_sec'] = f_i['expire_sec'] + f_e['expire_sec']
                contenitore['expire_sec'] = contenitore_root['expire_sec'] if contenitore
              end
            end
            res
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_import_c_export_fu_omc_logico(opts)
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
