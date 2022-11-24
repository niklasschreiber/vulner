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
    class TipoAttivitaExportReportComparativi < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_REPORT_COMPARATIVI

      config.define EXPIRE_EXPORT_REPORT_COMPARATIVI = :expire_export_report_comparativi, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaExportReportComparativoTotale::Util

      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_ca(idx_f, contenitore, opts = {}, &_block) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            res = []
            info_comando = { 'comando' => COMANDO_CONTEGGIO_ALBERATURE,
                             'parametri_comuni' => { 'out_dir_root'         => opts['out_dir_root'],
                                                     'account_id'           => opts['account_id'],
                                                     'genera_file_filtro'   => opts['genera_file_filtro'] },
                             'info' => { 'key_pid' => contenitore['key'], 'competenze' => opts['competenze'], 'expire_sec' => opts['expire_sec'] || config[EXPIRE_EXPORT_REPORT_COMPARATIVI] }
            }
            info_comando['parametri_comuni']['lista_rc_id'] = opts['lista_rc_id'] if opts['lista_rc_id']
            info_comando['parametri_comuni']['lista_rc_nome'] = opts['lista_rc_nome'] if opts['lista_rc_nome']
            info_comando['parametri_comuni']['np_alberatura'] = opts['np_alberatura'].to_json if opts['np_alberatura']
            info_comando['parametri_comuni']['filtro_metamodello'] = opts['filtro_metamodello'].to_json if opts['filtro_metamodello']
            info_comando['parametri_comuni']['filtro_metamodello_file'] = opts['filtro_metamodello_file'] if opts['filtro_metamodello_file']
            yield(info_comando) if block_given?
            res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + 1}", info_comando['comando'],
                                             parametri_comando: info_comando['parametri_comuni'],
                                             info: info_comando['info'])
            res
          end

          def ia_export_ca(idx_f, contenitore, opts = {}, &block) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
            lista_report_comparativi_obj = opts['lista_rc']
            opts_e_ca = opts['opts_e_ca']
            expire = opts['expire_sec'] || config[EXPIRE_EXPORT_REPORT_COMPARATIVI]
            competenze = opts['competenze'] || competenze_lista_report_comparativi(lista_report_comparativi_obj)

            res = []
            contenitore_ca = crea_contenitore_info_attivita("#{KEY_PREFIX_CONTENITORE}_ca",
                                                            format_msg(:ATTIVITA_COMANDO_CONTEGGIO_ALBERATURE),
                                                            'key_pid' => contenitore['key'],
                                                            'expire_sec' => expire,
                                                            'competenze' => competenze)

            res << contenitore_ca
            # --
            foglie_export_per_ca = []
            lista_report_comparativi_obj.each.with_index do |rc_obj, iii|
              opts_per_export_ca = opts_e_ca.dup
              opts_per_export_ca.update('lista_rc' => [rc_obj])
              opts_per_export_ca.update('tipo_export' => TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE)
              f_e_per_ca = TipoAttivitaExportReportComparativoTotale.ia_export_rc(idx_f + iii + 1, contenitore_ca, opts_per_export_ca, &block).last
              res << f_e_per_ca
              foglie_export_per_ca << "#{PREFIX_KEY_ATTIVITA_NEGATIVA}#{f_e_per_ca['key']}"
            end
            lista_rc_id_str = lista_report_comparativi_obj.map { |rc_a| rc_a[0].id }.join(',')
            lista_rc_id_str = nil if (lista_rc_id_str || '').empty?
            f_e_ca = TipoAttivitaExportReportComparativi.ia_ca(foglia_last_index(res),
                                                               contenitore_ca,
                                                               opts_e_ca.merge('competenze' => competenze, 'lista_rc_id' => lista_rc_id_str, 'expire_sec' => expire)) do |info_c|
                                                                 info_c['info']['dipende_da'] = foglie_export_per_ca
                                                               end.last
            res << f_e_ca
            res
          end
        end
      end

      include Util

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        opts.update('lista_rc' => lista_report_comparativi_id_to_obj(opts['lista_rc_id']))
        lista_report_comparativi_obj = opts['lista_rc']
        # cosa fare?
        check_export = opts['check_export']
        check_export_fu = opts['check_export_fu']
        check_export_ca = opts['check_export_ca']

        if check_export
          opts_e_tot = opts.dup
          opts_e_tot.update('formato' => 'xls', 'tipo_export' => TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE)
        end
        if check_export_fu
          opts_e_fu = opts.dup
          opts_e_fu.update('con_version' => opts['con_version_fu'],
                           'dist_assente_vuoto' => opts['dist_assente_vuoto_fu'],
                           'nascondi_assente_f1' => opts['nascondi_assente_f1_fu'],
                           'nascondi_assente_f2' => opts['nascondi_assente_f2_fu'],
                           'only_to_export_param' => opts['only_to_export_param_fu'],
                           'tipo_export' => TIPO_EXPORT_REPORT_COMPARATIVO_FU)
        end
        if check_export_ca
          opts_e_ca = opts.dup
          opts_e_ca.update('con_version' => opts['con_version_ca'],
                           'dist_assente_vuoto' => opts['dist_assente_vuoto_ca'],
                           'nascondi_assente_f1' => opts['nascondi_assente_f1_ca'],
                           'genera_file_filtro' => opts['genera_file_filtro'],
                           'np_alberatura' => opts['np_alberatura'],
                           'nascondi_assente_f2' => opts['nascondi_assente_f2_ca'],
                           'only_to_export_param' => opts['only_to_export_param_ca'])
        end
        %w(con_version dist_assente_vuoto only_to_export_param nascondi_assente_f2 nascondi_assente_f1).each do |el|
          %w(fu ca).each do |suff|
            (opts_e_tot || {}).delete("#{el}_#{suff}")
            (opts_e_fu || {}).delete("#{el}_#{suff}")
            (opts_e_ca || {}).delete("#{el}_#{suff}")
          end
        end
        (opts_e_tot || {}).delete('np_alberatura')
        (opts_e_fu || {}).delete('np_alberatura')

        # rubocop:disable Style/Next
        expire_s = config[EXPIRE_EXPORT_REPORT_COMPARATIVI] * lista_report_comparativi_obj.count
        le_competenze = competenze_lista_report_comparativi(lista_report_comparativi_obj)
        # root
        res = [contenitore_root = crea_root_info_attivita('expire_sec' => expire_s, 'competenze' => le_competenze)]
        if check_export || check_export_fu
          lista_report_comparativi_obj.each do |rc_obj|
            # export_rc_tot
            if check_export
              opts_e_tot.update('lista_rc' => [rc_obj])
              f_e_tot = TipoAttivitaExportReportComparativoTotale.ia_export_rc(foglia_last_index(res), contenitore_root, opts_e_tot).last
              res << f_e_tot
            end
            # export_rc_fu
            if check_export_fu
              opts_e_fu.update('lista_rc' => [rc_obj])
              f_e_fu = TipoAttivitaExportReportComparativoFu.ia_export_rc(foglia_last_index(res), contenitore_root, opts_e_fu).last
              res << f_e_fu
            end
          end # fine ciclo su lista report_comparativi
        end
        if check_export_ca
          # --------------------------------------------------------------------------------------
          # in parallelo...
          options_per_ca = {}
          options_per_ca['expire_sec'] = expire_s
          options_per_ca['competenze'] = le_competenze
          options_per_ca['opts_e_ca'] = opts_e_ca
          options_per_ca['lista_rc'] = lista_report_comparativi_obj
          attivita_ca = TipoAttivitaExportReportComparativi.ia_export_ca(foglia_last_index(res), contenitore_root, options_per_ca)
          res += attivita_ca
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
