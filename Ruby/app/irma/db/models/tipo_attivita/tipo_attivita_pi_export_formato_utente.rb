# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaPiExportFormatoUtente < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_PI_EXPORT_FU

      config.define EXPIRE_PI_EXPORT_FU = :pi_expire_export_fu, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      #
      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_pi_export_fu(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
            res = []
            comando = if opts['filtro_metamodello'] || opts['filtro_metamodello_file']
                        COMANDO_PI_EXPORT_FU_PARZIALE
                      else
                        COMANDO_PI_EXPORT_FU
                      end
            info_comando = { 'comando' => comando,
                             'parametri_comuni' => { 'out_dir_root' => opts['out_dir_root'], 'account_id' => opts['account_id'],
                                                     'archivio' => opts['archivio'],
                                                     'con_version' => opts['con_version'],
                                                     'formato' => opts['formato'] || 'txt' },
                             'info' => { 'key_pid' => contenitore['key'], 'expire_sec' => config[EXPIRE_PI_EXPORT_FU] }
            }
            info_comando['parametri_comuni']['filtro_metamodello'] = opts['filtro_metamodello'].to_json if opts['filtro_metamodello']
            info_comando['parametri_comuni']['filtro_metamodello_file'] = opts['filtro_metamodello_file'] if opts['filtro_metamodello_file']
            yield(info_comando) if block_given?

            opts['lista_pi'].each_with_index do |pi_a, idx|
              pi = pi_a[0]
              info_comando['tipo_competenza'] = pi.tipo_competenza
              pc = info_comando['parametri_comuni'].merge('progetti_irma' => pi.id.to_s)
              pc['omc_fisico'] = true if pi.omc_fisico_id
              omc = "(OMC #{pi.omc_fisico_id ? 'Fisico' : 'Logico'})"
              res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + idx + 1}", info_comando['comando'],
                                               parametri_comando: pc,
                                               info: info_comando['info'].merge('descr' => "#{pi.nome} #{omc}",
                                                                                'competenze' => pi.competenza))
            end
            res
          end

          def info_attivita_pi_export_fu(opts = {}, &block)
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_PI_EXPORT_FU], 'competenze' => competenze_lista_progetti_irma(opts['lista_pi']))] + ia_pi_export_fu(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_pi'] = lista_progetti_irma_id_to_obj(opts['lista_pi'])
        info_attivita_pi_export_fu(opts)
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
