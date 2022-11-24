# vim: set fileencoding=utf-8
#
# Author: R. Scandale
#
# Creation date: 20171017
#

module Irma
  module Db
    #
    class TipoAttivitaCreazioneFdcOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_CREAZIONE_FDC_OMC_LOGICO

      config.define EXPIRE_CREAZIONE_FDC = :expire_creazione_fdc, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                                        widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'
      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_creazione_fdc(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            res = []
            comando = omc_fisico? ? COMANDO_CREAZIONE_FDC_OMC_FISICO : COMANDO_CREAZIONE_FDC_OMC_LOGICO
            parametri_comando_comuni = { 'account_id' => opts['account_id'], 'pi_id' => opts['pi_id'], 'label_nome_fdc' => opts['label_nome_fdc'], 'flag_del_crt' => opts['flag_del_crt'] }
            opts['lista_sistemi'].each_with_index do |xxx, idx|
              sistema, input_file_canc = xxx
              parametri_comando = parametri_comando_comuni.merge('input_file_canc' => input_file_canc,
                                                                 'out_dir_root' => opts['out_dir_root'])
              parametri_comando['canc_rel_adj'] = opts['canc_rel_adj'].to_json if opts['canc_rel_adj']
              parametri_comando['formato_fdc'] = opts['formato_audit'] if opts['formato_audit']
              info_opts = { 'descr' => sistema.full_descr, 'expire_sec' => config[EXPIRE_CREAZIONE_FDC],
                            'competenze' => { omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA => [sistema.id.to_s] },
                            'key_pid' => contenitore['key'] }
              info_opts['artifacts'] = [input_file_canc] if input_file_canc
              res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + idx + 1}", comando,
                                               parametri_comando: parametri_comando,
                                               info: info_opts)
            end
            res
          end

          def info_attivita_creazione_fdc(opts = {}, &block)
            [root = crea_root_info_attivita('expire_sec' => config[EXPIRE_CREAZIONE_FDC], 'competenze' => competenze_lista_obj(opts['lista_sistemi']))] + ia_creazione_fdc(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_creazione_fdc(opts)
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
