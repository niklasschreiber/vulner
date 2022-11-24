# vim: set fileencoding=utf-8
#
# Author: R. Scandale
#
# Creation date: 20181015
#

module Irma
  module Db
    #
    class TipoAttivitaCancellazioneEccezioniPerEtichetta < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA

      config.define EXPIRE_CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA = :expire_cancellazione_eccezioni_per_etichetta, 600, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                                                                                       widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:1_800})'

      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_cancellazione_eccezioni(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize
            res = []
            parametri_comando_comuni = { 'account_id' => opts['account_id'], 'archivio' => opts['archivio'],
                                         'lock_expire' => config[EXPIRE_CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA] + RITARDO_LOCK_EXPIRE_PER_SCHEDULER }
            parametri_comando_comuni['omc_fisico'] = true if omc_fisico?
            parametri_comando_comuni['etichette'] = opts['etichette'] if opts['etichette']
            opts['lista_sistemi'].each_with_index do |xxx, idx|
              sistema = xxx[0]
              parametri_comando = parametri_comando_comuni.merge('sistema_id' => sistema.id)
              res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + idx + 1}", COMANDO_CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA,
                                               parametri_comando: parametri_comando,
                                               info: { 'descr' => sistema.full_descr, 'expire_sec' => config[EXPIRE_CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA],
                                                       'competenze' => { omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA => [sistema.id.to_s] },
                                                       'key_pid' => contenitore['key'] })
            end
            res
          end

          def info_attivita_cancellazione_eccezioni(opts = {}, &block)
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA] * opts['lista_sistemi'].count,
                                            'competenze' => competenze_lista_obj(opts['lista_sistemi']))] + ia_cancellazione_eccezioni(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_cancellazione_eccezioni(opts)
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
