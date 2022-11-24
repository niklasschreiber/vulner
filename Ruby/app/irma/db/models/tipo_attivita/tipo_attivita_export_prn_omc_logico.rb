# vim: set fileencoding=utf-8
#
# Author: R. Scandale
#
# Creation date: 20180116
#

module Irma
  module Db
    #
    class TipoAttivitaExportPrnOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_PRN_OMC_LOGICO

      config.define EXPIRE_EXPORT_PRN_OMC_LOGICO = :expire_export_prn_omc_logico, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                                                        widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        lista_sistemi_id = if opts['export_totale']
                             Sistema.map { |sss| [sss.id] }
                           else
                             opts['lista_sistemi_id']
                           end

        lista_sistemi_id_str = lista_sistemi_id.compact.map(&:first).join(',')
        lista_sistemi = lista_sistemi_id_to_obj(lista_sistemi_id)
        le_competenze = competenze_lista_obj(lista_sistemi)
        expire = config[EXPIRE_EXPORT_PRN_OMC_LOGICO] * lista_sistemi.count

        res = []
        res << crea_root_info_attivita('expire_sec' => expire, 'competenze' => le_competenze)
        parametri_comando = { 'account_id' => opts['account_id'], 'out_dir_root' => opts['out_dir_root'],
                              'formato' => opts['formato'], 'data_aggiornamento' => opts['data_aggiornamento'],
                              'export_totale' => opts['export_totale'],
                              'file_unico' => opts['file_unico'],
                              'sistemi' => lista_sistemi_id_str
        }
        info_opts = { 'descr' => 'Export PRN', 'expire_sec' => expire,
                      'competenze' => le_competenze }
        res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}1", COMANDO_EXPORT_PRN_OMC_LOGICO,
                                         parametri_comando: parametri_comando,
                                         info: info_opts)
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
