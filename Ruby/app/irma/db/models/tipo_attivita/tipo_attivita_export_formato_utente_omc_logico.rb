# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaExportFormatoUtenteOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_FU_OMC_LOGICO

      config.define EXPIRE_EXPORT_FU = :expire_export_fu, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_CA_ADE = :expire_ca_ade, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      #
      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_export_fu(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/MethodLength
            res = []
            comando = if opts['filtro_metamodello'] || opts['filtro_metamodello_file']
                        omc_fisico? ? COMANDO_EXPORT_FU_PARZIALE_OMC_FISICO : COMANDO_EXPORT_FU_PARZIALE_OMC_LOGICO
                      else
                        omc_fisico? ? COMANDO_EXPORT_FU_OMC_FISICO : COMANDO_EXPORT_FU_OMC_LOGICO
                      end
            info_comando = { 'comando' => comando,
                             'tipo_competenza' => omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA,
                             'parametri_comuni' => { 'out_dir_root' => opts['out_dir_root'],
                                                     'account_id' => opts['account_id'],
                                                     'archivio' => opts['archivio'],
                                                     'con_version' => opts['con_version'] || false,
                                                     'indice_etichette' => opts['indice_etichette'] || false,
                                                     'formato' => opts['formato'] || 'txt' },
                             'info' => { 'key_pid' => contenitore['key'], 'expire_sec' => config[EXPIRE_EXPORT_FU] }
            }
            info_comando['parametri_comuni']['omc_fisico'] = true if omc_fisico?
            info_comando['parametri_comuni']['filtro_metamodello'] = opts['filtro_metamodello'].to_json if opts['filtro_metamodello']
            info_comando['parametri_comuni']['filtro_metamodello_file'] = opts['filtro_metamodello_file'] if opts['filtro_metamodello_file']
            info_comando['parametri_comuni']['etichette_eccezioni'] = opts['etichette_eccezioni'] if opts['etichette_eccezioni']
            info_comando['parametri_comuni']['etichette_nette'] = opts['etichette_nette'] if opts['etichette_nette']
            yield(info_comando) if block_given?
            opts['lista_sistemi'].each_with_index do |sistema_a, idx|
              sistema = sistema_a[0]
              pc = info_comando['parametri_comuni'].merge('sistemi' => sistema.id.to_s)
              res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + idx + 1}", info_comando['comando'],
                                               parametri_comando: pc, info: info_comando['info'].merge('descr' => sistema.full_descr,
                                                                                                       'competenze' => { info_comando['tipo_competenza'] => [sistema.id.to_s] }))
            end
            res
          end

          def ia_ca_ade(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/MethodLength
            res = []
            info_comando = { 'comando' => COMANDO_CONTEGGIO_ALBERATURE_ADE,
                             'parametri_comuni' => { 'out_dir_root'    => opts['out_dir_root'], 'account_id' => opts['account_id'],
                                                     'np_alberatura'   => opts['np_alberatura'].to_json },
                             'info' => { 'key_pid' => contenitore['key'], 'competenze' => opts['competenze'], 'expire_sec' => opts['expire_sec'] || config[EXPIRE_CA_ADE] }
            }
            info_comando['parametri_comuni']['filtro_metamodello'] = opts['filtro_metamodello'].to_json if opts['filtro_metamodello']
            info_comando['parametri_comuni']['filtro_metamodello_file'] = opts['filtro_metamodello_file'] if opts['filtro_metamodello_file']
            info_comando['parametri_comuni']['etichette_eccezioni'] = opts['etichette_eccezioni'] if opts['etichette_eccezioni']
            info_comando['parametri_comuni']['etichette_nette'] = opts['etichette_nette'] if opts['etichette_nette']
            info_comando['parametri_comuni']['sistemi_id'] = opts['lista_sistemi'].map { |sss| sss[0].id }.join(',')
            yield(info_comando) if block_given?
            res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + 1}", info_comando['comando'],
                                             parametri_comando: info_comando['parametri_comuni'],
                                             info: info_comando['info'])
            res
          end

          def info_attivita_export_fu(opts = {}, &block) # rubocop:disable Metrics/AbcSize
            # cosa fare ? nel caso di AdE potrebbe essere richiesto anche conteggio alberature
            check_ca = opts['check_ca']

            # opts export fu
            opts_export = opts.dup
            opts_export.delete('np_alberatura')

            # opts ca
            if check_ca
              opts_ca = opts.dup
              # TODO: Verificare la lista delle options da togliere
              %w(con_version formato dir_name_no_date omc_fisico).each { |k| opts_ca.delete(k) }
            end

            expire = config[EXPIRE_EXPORT_FU] + (check_ca ? config[EXPIRE_CA_ADE] : 0)

            res = [contenitore_root = crea_root_info_attivita('expire_sec' => expire, 'competenze' => competenze_lista_obj(opts['lista_sistemi']))]
            res += ia_export_fu(foglia_last_index(res), contenitore_root, opts_export, &block)
            res += ia_ca_ade(foglia_last_index(res), contenitore_root, opts_ca, &block) if check_ca
            res
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_export_fu(opts)
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
