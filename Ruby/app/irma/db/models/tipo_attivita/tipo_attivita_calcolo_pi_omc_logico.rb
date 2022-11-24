# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaCalcoloPiOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_CALCOLO_PI_OMC_LOGICO

      config.define EXPIRE_CALCOLO_PI = :expire_calcolo_pi, 5400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      #
      module Util
        extends_host_with :ClassMethod

        #
        module ClassMethod
          def ia_calcolo_pi(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, PerceivedComplexity
            res = []
            comando = omc_fisico? ? COMANDO_CALCOLO_PI_OMC_FISICO : COMANDO_CALCOLO_PI_OMC_LOGICO
            omc = opts['omc_id'][0][0]
            info_comando = { 'comando' => comando,
                             'tipo_competenza' => omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA,
                             'parametri_comuni' => { 'nome_progetto_irma' => opts['nome'],
                                                     'omc_id' => omc.id.to_s,
                                                     'tipo_sorgente' => opts['tipo_sorgente'] || CALCOLO_SORGENTE_OMCLOGICO,
                                                     'account_id' => opts['account_id'],
                                                     'archivio' => opts['archivio'],
                                                     'lista_celle' => opts['lista_celle'] },
                             'info' => { 'key_pid' => contenitore['key'], 'expire_sec' => config[EXPIRE_CALCOLO_PI] }
            }
            info_comando['parametri_comuni']['omc_fisico'] = true if omc_fisico?
            info_comando['parametri_comuni']['sorgente_pi_id'] = opts['sorgente_pi_id'] if opts['sorgente_pi_id']
            info_comando['parametri_comuni']['celle_adiacenti'] = (opts['celle_adiacenti'] == true)
            info_comando['parametri_comuni']['no_eccezioni'] = (opts['no_eccezioni'] == true)
            info_comando['parametri_comuni']['filtro_metamodello'] = opts['filtro_metamodello'].to_json if opts['filtro_metamodello']
            info_comando['parametri_comuni']['filtro_metamodello_file'] = opts['filtro_metamodello_file'] if opts['filtro_metamodello_file']
            yield(info_comando) if block_given?
            res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + 1}", info_comando['comando'],
                                             parametri_comando: info_comando['parametri_comuni'],
                                             info: info_comando['info'].merge('descr' => omc.full_descr,
                                                                              'competenze' => { info_comando['tipo_competenza'] => [omc.id.to_s] }))
            res
          end

          def info_attivita_calcolo_pi(opts = {}, &block)
            opts['omc_id'] = lista_sistemi_id_to_obj([[opts['omc_id']]])
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_CALCOLO_PI], 'competenze' => competenze_lista_obj(opts['omc_id']))] + ia_calcolo_pi(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        info_attivita_calcolo_pi(opts)
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
