# vim: set fileencoding=utf-8
#
# Author: R. Arcaro, G. Cristelli
#
# Creation date: 20170607
#

module Irma
  module Db
    #
    class TipoAttivitaImportAdrn < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_ADRN

      config.define EXPIRE_IMPORT_ADRN = :expire_import_adrn, 600, descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:7200})'

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/AbcSize
        competenze = { TIPO_COMPETENZA_VENDORRELEASE => opts['id_vendor_release'].to_s.split(',') }
        res = []
        res << crea_root_info_attivita('expire_sec' => config[EXPIRE_IMPORT_ADRN], 'competenze' => competenze)
        res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}1", COMANDO_IMPORT_ADRN,
                                         parametri_comando: { 'import_file_zip' => opts['input_file'], 'account_id' => opts['account_id'], 'filtro_release' => opts['filtro_release'] },
                                         info: { 'descr' => opts['vr_descr'], 'expire_sec' => config[EXPIRE_IMPORT_ADRN], 'artifacts' => [opts['input_file']], 'competenze' => competenze })
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
