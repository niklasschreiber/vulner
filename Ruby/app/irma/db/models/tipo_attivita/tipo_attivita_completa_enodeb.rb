# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20170925
#

module Irma
  module Db
    #
    class TipoAttivitaCompletaEnodeb < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_COMPLETA_ENODEB

      config.define EXPIRE_COMPLETA_ENODEB = :expire_completa_enodebid, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                                              widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/AbcSize
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        res = []
        res << crea_root_info_attivita('expire_sec' => config[EXPIRE_COMPLETA_ENODEB], 'competenze' => competenze_lista_obj(opts['lista_sistemi']))
        parametri_comando_comuni = { 'account_id' => opts['account_id'] }
        opts['lista_sistemi'].each_with_index do |xxx, idx|
          sistema, input_file = xxx
          parametri_comando = parametri_comando_comuni.merge('sistema_id' => sistema.id,
                                                             'input_file' => input_file,
                                                             'out_dir_root' => opts['out_dir_root'])
          res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx + 1}", COMANDO_COMPLETA_ENODEB,
                                           parametri_comando: parametri_comando,
                                           info: { 'descr' => sistema.full_descr, 'expire_sec' => config[EXPIRE_COMPLETA_ENODEB], 'artifacts' => [input_file],
                                                   'competenze' => { TIPO_COMPETENZA_SISTEMA => [sistema.id.to_s] } })
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
