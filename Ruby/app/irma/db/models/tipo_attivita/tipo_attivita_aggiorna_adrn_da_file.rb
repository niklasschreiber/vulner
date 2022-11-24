# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20190709
#

module Irma
  module Db
    #
    class TipoAttivitaAggiornaAdrnDaFile < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_AGGIORNA_ADRN_DA_FILE

      config.define EXPIRE_AGGIORNA_ADRN_DA_FILE = :expire_aggiorna_adrn_da_file, 600,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:7200})'

      # opts: 'input_file', 'account_id', 'operazione', 'vendor_release_id'
      def self.info_attivita(opts = {}) # rubocop:disable Metrics/AbcSize
        vr_id = opts['vendor_release_id'].to_i
        vr = Db::VendorRelease.get_by_pk(vr_id)
        competenze = { TIPO_COMPETENZA_VENDORRELEASE => [vr_id.to_s] }
        res = []
        res << crea_root_info_attivita('expire_sec' => config[EXPIRE_AGGIORNA_ADRN_DA_FILE], 'competenze' => competenze)
        res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}1", COMANDO_AGGIORNA_ADRN_DA_FILE,
                                         parametri_comando: { 'input_file' => opts['input_file'],
                                                              'account_id' => opts['account_id'],
                                                              'operazione' => opts['operazione'],
                                                              'vendor_release_id' => opts['vendor_release_id'] },
                                         info: { 'descr' => vr.descr,
                                                 'expire_sec' => config[EXPIRE_AGGIORNA_ADRN_DA_FILE],
                                                 'artifacts' => [opts['input_file']],
                                                 'competenze' => competenze })
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
