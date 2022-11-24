# vim: set fileencoding=utf-8
#
# Author: C. Pinali
#
# Creation date: 20161220
#

module Irma
  module Db
    #
    class TipoAttivitaReportComparativoOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_REPORT_COMPARATIVO_OMC_LOGICO

      config.define EXPIRE_REPORT_COMP = :expire_report_comp, 3600, descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'
      #
      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_report_comparativo(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            res = []
            comando = omc_fisico? ? COMANDO_REPORT_COMPARATIVO_OMC_FISICO : COMANDO_REPORT_COMPARATIVO_OMC_LOGICO
            omc = opts['omc_id'][0][0]
            info_comando = { 'comando' => comando,
                             'tipo_competenza' => omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA,
                             'parametri_comuni' => { 'account_id' => opts['account_id'],
                                                     'nome'       => opts['nome'],
                                                     'origine_1'  => opts['origine_1'],
                                                     'valore_1'   => opts['valore_1'],
                                                     'origine_2'  => opts['origine_2'],
                                                     'valore_2'   => opts['valore_2'],
                                                     'archivio_1' => opts['archivio_1'],
                                                     'archivio_2' => opts['archivio_2'] },
                             'info' => { 'key_pid' => contenitore['key'], 'expire_sec' => config[EXPIRE_REPORT_COMP] }
            }
            info_comando['parametri_comuni'].update('flag_presente' => (opts['flag_presente'] ? true : false))
            info_comando['parametri_comuni']['filtro_metamodello_file'] = opts['filtro_metamodello_file'] if opts['filtro_metamodello_file']
            yield(info_comando) if block_given?
            res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + 1}", info_comando['comando'],
                                             parametri_comando: info_comando['parametri_comuni'],
                                             info: info_comando['info'].merge('descr' => omc.full_descr, 'competenze' => { info_comando['tipo_competenza'] => [omc.id.to_s] }))
            res
          end

          def info_attivita_report_comparativo(opts = {}, &block)
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_REPORT_COMP], 'competenze' => competenze_lista_obj(opts['omc_id']))] + ia_report_comparativo(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['omc_id'] = lista_sistemi_id_to_obj([[opts['omc_id']]])
        info_attivita_report_comparativo(opts)
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
