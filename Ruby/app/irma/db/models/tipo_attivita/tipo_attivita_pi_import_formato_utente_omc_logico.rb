# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaPiImportFormatoUtenteOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_PI_IMPORT_FU_OMC_LOGICO

      config.define EXPIRE_IMPORT_FU = :expire_import_fu, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      #
      module Util
        extends_host_with :ClassMethod

        #
        module ClassMethod
          def ia_pi_import_fu(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            res = []
            parametri_comando_comuni = { 'nome' => opts['nome_progetto_irma'], 'account_id' => opts['account_id'], 'archivio' => opts['archivio'] }
            parametri_comando_comuni.update('flag_cancellazione' => (opts['flag_cancellazione'] ? true : false))
            parametri_comando_comuni.update('flag_update' => (opts['flag_update'] ? true : false))
            parametri_comando_comuni.update('tipo_sorgente' => opts['tipo_sorgente'] || CALCOLO_SORGENTE_OMCLOGICO)
            parametri_comando_comuni.update('sorgente_pi_id' => opts['sorgente_pi_id']) if opts['sorgente_pi_id']
            opts['lista_sistemi'].each_with_index do |xxx, idx|
              sistema, input_file = xxx
              info_xxx = { 'descr' => sistema.full_descr,
                           'key_pid' => contenitore['key'],
                           'artifacts' => [input_file],
                           'expire_sec' => config[EXPIRE_IMPORT_FU],
                           'competenze' => { TIPO_COMPETENZA_SISTEMA => [sistema.id.to_s] } }
              yield info_xxx if block_given?
              parametri_comando = parametri_comando_comuni.merge('sistema_id' => sistema.id, 'input_file' => input_file)
              res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + idx + 1}", COMANDO_PI_IMPORT_FU_OMC_LOGICO,
                                               parametri_comando: parametri_comando, info: info_xxx)
            end
            res
          end

          def info_attivita_pi_import_formato_utente(opts = {}, &block)
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_IMPORT_FU],
                                            'competenze' => competenze_lista_obj(opts['lista_sistemi']))] + ia_pi_import_fu(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_pi_import_formato_utente(opts)
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
