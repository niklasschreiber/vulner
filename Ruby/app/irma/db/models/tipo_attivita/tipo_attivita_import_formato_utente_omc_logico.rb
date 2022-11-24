# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaImportFormatoUtenteOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_FU_OMC_LOGICO

      config.define EXPIRE_IMPORT_FU = :expire_import_fu, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_import_fu(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize
            res = []
            parametri_comando_comuni = { 'account_id' => opts['account_id'], 'archivio' => opts['archivio'], 'flag_cancellazione' => (opts['flag_cancellazione'] ? true : false) }
            parametri_comando_comuni['omc_fisico'] = true if omc_fisico?
            parametri_comando_comuni['label_eccezioni'] = opts['label_eccezioni'] if opts['label_eccezioni']
            opts['lista_sistemi'].each_with_index do |xxx, idx|
              sistema, input_file = xxx
              parametri_comando = parametri_comando_comuni.merge('sistema_id' => sistema.id, 'input_file' => input_file)
              res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + idx + 1}", omc_fisico? ? COMANDO_IMPORT_FU_OMC_FISICO : COMANDO_IMPORT_FU_OMC_LOGICO,
                                               parametri_comando: parametri_comando,
                                               info: { 'descr' => sistema.full_descr, 'expire_sec' => config[EXPIRE_IMPORT_FU], 'artifacts' => [input_file],
                                                       'competenze' => { omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA => [sistema.id.to_s] },
                                                       'key_pid' => contenitore['key'] })
            end
            res
          end

          def info_attivita_import_fu(opts = {}, &block)
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_IMPORT_FU], 'competenze' => competenze_lista_obj(opts['lista_sistemi']))] + ia_import_fu(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_import_fu(opts)
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
