# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190402
#

module Irma
  module Db
    #
    class TipoAttivitaNuovoGnodebid < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_NUOVO_GNODEBID

      config.define EXPIRE_NUOVO_GNODEBID = :expire_nuovo_gnodebid, 300, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                                         widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:7200})'

      def self.info_attivita(opts = {})
        res = [crea_root_info_attivita('expire_sec' => config[EXPIRE_NUOVO_GNODEBID], 'competenze' => { TIPO_COMPETENZA_SISTEMA => COMPETENZA_TUTTO })]
        res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}1", COMANDO_NUOVO_GNODEBID,
                                         parametri_comando: { 'input_file' => opts['input_file'], 'account_id' => opts['account_id'],
                                                              'lock_expire' => config[EXPIRE_NUOVO_GNODEBID] },
                                         info: { 'expire_sec' => config[EXPIRE_NUOVO_GNODEBID], 'competenze' => { TIPO_COMPETENZA_SISTEMA => COMPETENZA_TUTTO } })
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
