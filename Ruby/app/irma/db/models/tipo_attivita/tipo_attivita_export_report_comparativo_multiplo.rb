# vim: set fileencoding=utf-8
#
# Author: R. Arcaro
#
# Creation date: 20171120
#

require File.join(__dir__, 'tipo_attivita_export_report_comparativo_fu.rb')
require File.join(__dir__, 'tipo_attivita_export_report_comparativo_totale.rb')

module Irma
  module Db
    #
    class TipoAttivitaExportReportComparativoMultiplo < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_RC_MULTIPLO

      config.define EXPIRE_EXPORT_RC = :expire_export_rc, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaExportReportComparativoTotale::Util

      def self.info_attivita(opts = {}) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
        opts.update('lista_rc' => lista_report_comparativi_id_to_obj(opts['lista_rc_id']))
        lista_report_comparativi_obj = opts['lista_rc']
        opts_e_tot = opts.dup
        opts_e_fu = opts.dup
        opts_e_tot.update('formato' => 'xls', 'tipo_export' => TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE)
        opts_e_fu.update('con_version' => opts['con_version_fu'],
                         'dist_assente_vuoto' => opts['dist_assente_vuoto_fu'],
                         'nascondi_assente_f1' => opts['nascondi_assente_f1_fu'],
                         'nascondi_assente_f2' => opts['nascondi_assente_f2_fu'],
                         'only_to_export_param' => opts['only_to_export_param_fu'],
                         'tipo_export' => TIPO_EXPORT_REPORT_COMPARATIVO_FU)
        %w(con_version_fu dist_assente_vuoto_fu only_to_export_param_fu).each do |el|
          opts_e_tot.delete(el)
          opts_e_fu.delete(el)
        end
        expire_s = config[EXPIRE_EXPORT_RC] + config[EXPIRE_EXPORT_RC]
        # root
        res = [contenitore_root = crea_root_info_attivita('expire_sec' => expire_s, 'competenze' => competenze_lista_report_comparativi(lista_report_comparativi_obj))]
        lista_report_comparativi_obj.each do |rc_obj|
          opts_e_tot.update('lista_rc' => [rc_obj])
          # export_rc_tot
          f_e_tot = TipoAttivitaExportReportComparativoTotale.ia_export_rc(foglia_last_index(res), contenitore_root, opts_e_tot).last
          res << f_e_tot
          # export_rc_fu
          opts_e_fu.update('lista_rc' => [rc_obj])
          f_e_fu = TipoAttivitaExportReportComparativoFu.ia_export_rc(foglia_last_index(res), contenitore_root, opts_e_fu) do |ic|
            ic['info']['dipende_da'] = [f_e_tot['key']]
          end.last
          res << f_e_fu
        end
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
