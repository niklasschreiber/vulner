# vim: set fileencoding=utf-8
#
# Author: R. Arcaro
#
# Creation date: 20180116
#

module Irma
  module Db
    #
    class TipoAttivitaCalcoloPiCopia < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_CALCOLO_PI_COPIA

      config.define EXPIRE_CALCOLO_PI_COPIA = :expire_calcolo_pi_copia, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                                              widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:7200})'

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/AbcSize
        info_comando = { 'tipo_competenza' => opts['omc_fisico'] ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA }
        @omc_fisico = opts['omc_fisico']
        omc = lista_sistemi_id_to_obj([[opts['omc_id']]])
        competenze = competenze_lista_obj(omc)
        res = []
        res << crea_root_info_attivita('expire_sec' => config[EXPIRE_CALCOLO_PI_COPIA], 'competenze' => competenze)
        res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}1", COMANDO_CALCOLO_PI_COPIA,
                                         parametri_comando: { 'nome_pi_target' => opts['nome_progetto_irma'], 'id_pi_sorgente' => opts['id_pi_sorgente'],
                                                              'nome_pi_src' => opts['nome_pi_src'], 'account_id' => opts['account_id'],
                                                              'omc_id' => opts['omc_id'], 'archivio' => opts['archivio'], 'omc_fisico' => opts['omc_fisico'] ? true : false },
                                         info: { 'descr' => opts['nome_pi_src'], 'expire_sec' => config[EXPIRE_CALCOLO_PI_COPIA],
                                                 'competenze' => { info_comando['tipo_competenza'] => [opts['omc_id'].to_s] } })
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
