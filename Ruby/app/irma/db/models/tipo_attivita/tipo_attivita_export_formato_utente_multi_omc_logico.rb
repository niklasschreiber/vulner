# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    # 20180226 - TipoAttivita OBSOLETA
    class TipoAttivitaExportFormatoUtenteMultiOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_FU_MULTI_OMC_LOGICO

      config.define EXPIRE_EXPORT_FU = :expire_export_fu, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      #
      module Util
        extends_host_with :ClassMethod

        #
        module ClassMethod
          def ia_export_fu_multi(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            lista_sistemi = opts['lista_sistemi'].map(&:first) # array di array con primo elemento un oggetto sistema
            res = []
            info_comando = { 'comando' => omc_fisico? ? COMANDO_EXPORT_FU_MULTI_OMC_FISICO : COMANDO_EXPORT_FU_MULTI_OMC_LOGICO,
                             'tipo_competenza' => omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA,
                             'info' => { 'key_pid' => contenitore['key'] },
                             'parametri_comuni' => { 'sistemi' => llss = lista_sistemi.map(&:id).join(','),
                                                     'out_dir_root' => opts['out_dir_root'],
                                                     'con_version' => opts['con_version'],
                                                     'formato' => opts['formato'] || 'txt',
                                                     'account_id' => opts['account_id'],
                                                     'archivio' => opts['archivio'] }
            }
            info_comando['parametri_comuni']['omc_fisico'] = true if omc_fisico?
            yield(info_comando) if block_given?

            descr = lista_sistemi.map(&:full_descr).join(' - ')
            res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + 1}", info_comando['comando'],
                                             parametri_comando: info_comando['parametri_comuni'],
                                             info: info_comando['info'].merge('sistemi' => llss, 'descr' => descr, 'expire_sec' => config[EXPIRE_EXPORT_FU] * opts['lista_sistemi'].size,
                                                                              'competenze' => competenze_lista_obj(opts['lista_sistemi'])))
            res
          end

          def info_attivita_export_fu_multi(opts = {}, &block)
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_EXPORT_FU] * opts['lista_sistemi'].size,
                                            'competenze' => competenze_lista_obj(opts['lista_sistemi']))] + ia_export_fu_multi(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_export_fu_multi(opts)
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
