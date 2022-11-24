# vim: set fileencoding=utf-8
#
# Author: R. Scandale
#
# Creation date: 20180605
#

module Irma
  module Db
    #
    class TipoAttivitaEliminaCelleDaPrnOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_ELIMINA_CELLE_DA_PRN_OMC_LOGICO

      config.define EXPIRE_ELIMINA_CELLE_DA_PRN = :expire_elimina_celle_da_prn, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                                                      widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_elimina_celle_da_prn(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize
            res = []
            sistema = opts['lista_sistemi'][0][0]
            parametri_comando = { 'account_id'  => opts['account_id'],
                                  'sistema_id'  => sistema.id.to_s,
                                  'lista_celle' => opts['lista_celle'] }
            parametri_comando['omc_fisico'] = true if omc_fisico?
            res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + 1}", omc_fisico? ? COMANDO_ELIMINA_CELLE_PRN_OMC_FISICO : COMANDO_ELIMINA_CELLE_PRN_OMC_LOGICO,
                                             parametri_comando: parametri_comando,
                                             info: { 'descr' => sistema.full_descr, 'expire_sec' => config[EXPIRE_ELIMINA_CELLE_DA_PRN],
                                                     'competenze' => { omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA => [sistema.id.to_s] },
                                                     'key_pid' => contenitore['key'] })
          end

          def info_attivita_elimina_celle_da_prn(opts = {}, &block)
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_ELIMINA_CELLE_DA_PRN], 'competenze' => competenze_lista_obj(opts['lista_sistemi']))] +
              ia_elimina_celle_da_prn(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj([[opts['sistema_id']]])
        info_attivita_elimina_celle_da_prn(opts)
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
