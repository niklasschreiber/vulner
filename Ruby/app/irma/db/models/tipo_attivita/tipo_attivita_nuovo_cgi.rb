# vim: set fileencoding=utf-8
#
# Author: R. Arcaro
#
# Creation date: 20170912
#

module Irma
  module Db
    #
    class TipoAttivitaNuovoCgi < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_NUOVO_CGI

      config.define EXPIRE_NUOVO_CGI = :expire_nuovo_cgi, 300, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                               widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:7200})'

      def self.info_attivita(opts = {})
        res = []
        res << crea_root_info_attivita('expire_sec' => config[EXPIRE_NUOVO_CGI]) # , 'competenze' => competenze)
        res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}1", COMANDO_NUOVO_CGI,
                                         parametri_comando: { 'input_file' => opts['input_file'], 'account_id' => opts['account_id'] },
                                         info: { 'expire_sec' => config[EXPIRE_NUOVO_CGI] }) # , 'competenze' => competenze })
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
