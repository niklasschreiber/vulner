# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20190709
#

module Irma
  module Db
    #
    class TipoAttivitaExportAdrnSuFile < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_ADRN_SU_FILE

      config.define EXPIRE_EXPORT_ADRN_SU_FILE = :expire_export_adrn_su_file, 300,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:7200})'

      # opts: 'account_id', 'vendor_release_id',
      #       'campi_m_entita', 'campi_m_parametro', array di campi di meta_entita/meta_parametro
      #       'out_dir_root'
      def self.info_attivita(opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        vr_id = opts['vendor_release_id'].to_i
        vr = Db::VendorRelease.get_by_pk(vr_id)
        competenze = { TIPO_COMPETENZA_VENDORRELEASE => [vr_id.to_s] }

        res = []
        res << crea_root_info_attivita('expire_sec' => config[EXPIRE_EXPORT_ADRN_SU_FILE], 'competenze' => competenze)
        parametri_cmd = { 'account_id' => opts['account_id'],
                          'vendor_release_id' => vr_id,
                          'campi_m_entita' => opts['campi_m_entita'],
                          'campi_m_parametro' => opts['campi_m_parametro'],
                          'out_dir_root' => opts['out_dir_root'] }
        parametri_cmd['filtro_metamodello'] = opts['filtro_metamodello'].to_json if opts['filtro_metamodello']
        parametri_cmd['filtro_metamodello_file'] = opts['filtro_metamodello_file'] if opts['filtro_metamodello_file']

        res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}1", COMANDO_EXPORT_ADRN_SU_FILE,
                                         parametri_comando: parametri_cmd,
                                         info: { 'descr' => vr.descr, 'expire_sec' => config[EXPIRE_EXPORT_ADRN_SU_FILE], 'competenze' => competenze })
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
