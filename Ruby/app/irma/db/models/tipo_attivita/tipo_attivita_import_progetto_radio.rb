# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaImportProgettoRadio < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_PROGETTO_RADIO

      config.define EXPIRE_IMPORT_PR = :expire_import_pr, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/AbcSize
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        res = []
        res << crea_root_info_attivita('expire_sec' => config[EXPIRE_IMPORT_PR], 'competenze' => competenze_lista_obj(opts['lista_sistemi']))
        parametri_comando_comuni = { 'account_id' => opts['account_id'], 'flag_cancellazione' => (opts['flag_cancellazione'] ? true : false) }
        parametri_comando_comuni['ctrl_nv_adj_inesistenti'] = opts['ctrl_nv_adj_inesistenti'].to_json if opts['ctrl_nv_adj_inesistenti']
        parametri_comando_comuni['ctrl_nv_reciprocita_adj'] = opts['ctrl_nv_reciprocita_adj'].to_json if opts['ctrl_nv_reciprocita_adj']
        opts['lista_sistemi'].each_with_index do |xxx, idx|
          sistema, input_file = xxx
          parametri_comando = parametri_comando_comuni.merge('sistema_id' => sistema.id, 'input_file' => input_file)
          res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx + 1}", COMANDO_IMPORT_PROGETTO_RADIO,
                                           parametri_comando: parametri_comando,
                                           info: { 'descr' => sistema.full_descr, 'expire_sec' => config[EXPIRE_IMPORT_PR], 'artifacts' => [input_file],
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
