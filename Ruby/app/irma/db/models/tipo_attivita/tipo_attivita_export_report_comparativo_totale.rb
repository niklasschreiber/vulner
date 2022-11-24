# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaExportReportComparativoTotale < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_EXPORT_RC_TOTALE

      config.define EXPIRE_EXPORT_RC = :expire_export_rc, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      #
      module Util
        extends_host_with :ClassMethod
        #
        module ClassMethod
          def ia_export_rc(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
            res = []
            comando = opts['tipo_export'] == TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE ? COMANDO_EXPORT_RC_TOT : COMANDO_EXPORT_RC_FU
            info_comando = { 'comando' => comando,
                             'parametri_comuni' => { 'out_dir_root'         => opts['out_dir_root'],
                                                     'account_id'           => opts['account_id'],
                                                     'tipo_export'          => opts['tipo_export'],
                                                     'formato'              => opts['formato'] || 'xls',
                                                     'con_version'          => opts['con_version'],
                                                     'only_to_export_param' => opts['only_to_export_param'],
                                                     'nascondi_assente_f1'  => opts['nascondi_assente_f1'],
                                                     'nascondi_assente_f2'  => opts['nascondi_assente_f2'],
                                                     'dist_assente_vuoto'   => opts['dist_assente_vuoto'] },
                             'info' => { 'key_pid' => contenitore['key'], 'expire_sec' => config[EXPIRE_EXPORT_RC] }
            }
            info_comando['parametri_comuni']['filtro_version'] = opts['filtro_version'] if opts['filtro_version']
            info_comando['parametri_comuni']['filtro_metamodello'] = opts['filtro_metamodello'].to_json if opts['filtro_metamodello']
            info_comando['parametri_comuni']['filtro_metamodello_file'] = opts['filtro_metamodello_file'] if opts['filtro_metamodello_file']
            info_comando['parametri_comuni']['cc_mode'] = opts['cc_mode'] if opts['cc_mode']
            info_comando['parametri_comuni']['solo_calcolabili'] = opts['solo_calcolabili'] if opts['solo_calcolabili']
            info_comando['parametri_comuni']['solo_prioritari'] = opts['solo_prioritari'] if opts['solo_prioritari']
            info_comando['parametri_comuni']['np_alberatura'] = opts['np_alberatura'].to_json if opts['np_alberatura']
            yield(info_comando) if block_given?
            opts['lista_rc'].each_with_index do |rc_a, idx|
              rc = rc_a[0]
              info_comando['tipo_competenza'] = rc.tipo_competenza
              pc = info_comando['parametri_comuni'].merge('report_comparativo_nome' => rc.nome)
              info_foglia = info_comando['info'].merge('descr' => rc.nome, 'competenze' => rc.competenza)
              info_foglia['label'] = "Conteggio disallineamenti da Report Comparativo #{rc.nome}" if opts['np_alberatura']
              res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + idx + 1}", info_comando['comando'],
                                               parametri_comando: pc, info: info_foglia)
            end
            res
          end

          def info_attivita_export_rc(opts = {}, &block)
            root = crea_root_info_attivita('expire_sec' => config[EXPIRE_EXPORT_RC], 'competenze' => competenze_lista_report_comparativi(opts['lista_rc']))
            [root] + ia_export_rc(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_rc'] = lista_report_comparativi_id_to_obj(opts['lista_rc_id'])
        opts['tipo_export'] = TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE
        info_attivita_export_rc(opts)
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
