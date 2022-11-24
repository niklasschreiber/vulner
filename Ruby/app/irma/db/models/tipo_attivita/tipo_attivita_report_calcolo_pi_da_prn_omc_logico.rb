# vim: set fileencoding=utf-8
#
# Author: R. Scandale
#
# Creation date: 20171020
#

require File.join(__dir__, 'tipo_attivita_import_costruttore_omc_logico.rb')
require File.join(__dir__, 'tipo_attivita_calcolo_pi_omc_logico.rb')
require File.join(__dir__, 'tipo_attivita_pi_import_formato_utente_omc_logico.rb')
require File.join(__dir__, 'tipo_attivita_report_comparativo_omc_logico.rb')
require File.join(__dir__, 'tipo_attivita_export_report_comparativo_totale.rb')
require File.join(__dir__, 'tipo_attivita_export_report_comparativi.rb')
module Irma
  module Db
    #
    class TipoAttivitaReportCalcoloPiDaPrnOmcLogico < TipoAttivita # rubocop:disable Metrics/ClassLength
      LABEL_ROOT = :ATTIVITA_ROOT_REPORT_CALCOLO_PI_DA_PRN_OMC_LOGICO

      config.define EXPIRE_IMPORT_COSTRUTTORE = :expire_import_costruttore, 5400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_CALCOLO_PI = :expire_calcolo_pi, 5400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_IMPORT_FU = :expire_import_fu, 5400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_REPORT_COMP = :expire_report_comp, 3600,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      config.define EXPIRE_EXPORT_RC = :expire_export_rc, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando',
                    widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      include TipoAttivitaImportCostruttoreOmcLogico::Util
      include TipoAttivitaCalcoloPiOmcLogico::Util
      include TipoAttivitaPiImportFormatoUtenteOmcLogico::Util
      include TipoAttivitaReportComparativoOmcLogico::Util
      include TipoAttivitaExportReportComparativoTotale::Util

      def self.foglie_export_rc(flag, idx, cont_root, opts, &block)
        if flag == 'conteggio_alberature'
          opts['opts_e_ca'] = opts
          TipoAttivitaExportReportComparativi.ia_export_ca(idx, cont_root, opts, &block)
        else
          TipoAttivitaExportReportComparativoTotale.ia_export_rc(idx, cont_root, opts, &block)
        end
      end

      def self.info_attivita(opts = {}) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        lista_sistemi = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        expire_s = 0
        # root
        res = [contenitore_root = crea_root_info_attivita('competenze' => competenze_lista_obj(lista_sistemi))]
        base_opts = { 'account_id'   => opts['account_id'],
                      'out_dir_root' => opts['out_dir_root'],
                      'archivio'     => opts['archivio']
                    }
        # import costruttore
        ultime_foglie = nil
        if opts['import_costruttore']
          expire_s += config[EXPIRE_IMPORT_COSTRUTTORE]
          cmd_opts = base_opts.dup.merge('lista_sistemi' => opts['lista_sistemi'], 'check_data' => (opts['check_data'] == true))
          res += (ultime_foglie = TipoAttivitaImportCostruttoreOmcLogico.ia_import_costruttore(foglia_last_index(res), contenitore_root, cmd_opts))
        end
        # calcolo pi
        cmd_opts = base_opts.dup.merge('omc_id'             => lista_sistemi,
                                       'nome'               => opts['nome'],
                                       'nome_progetto_irma' => nome_progetto_irma = opts['nome_progetto_irma'],
                                       'lista_celle'        => opts['lista_celle'],
                                       'tipo_sorgente'      => opts['tipo_sorgente'] || CALCOLO_SORGENTE_OMCLOGICO)
        cmd_opts.update('sorgente_pi_id' => opts['sorgente_pi_id']) if opts['sorgente_pi_id']
        cmd_opts.update('celle_adiacenti' => opts['celle_adiacenti'] == true)
        cmd_opts.update('no_eccezioni' => opts['no_eccezioni'] == true)
        cmd_opts.update('filtro_metamodello' => opts['filtro_metamodello_pi']) if opts['filtro_metamodello_pi']
        cmd_opts.update('filtro_metamodello_file' => opts['filtro_metamodello_file_pi']) if opts['filtro_metamodello_file_pi']
        expire_s += config[EXPIRE_CALCOLO_PI]
        ultime_foglie = TipoAttivitaCalcoloPiOmcLogico.ia_calcolo_pi(foglia_last_index(res), contenitore_root, cmd_opts) do |ic|
          ic['info']['dipende_da'] = [ultime_foglie.last['key']] if ultime_foglie
        end
        res += ultime_foglie
        # aggiorna pi
        if opts['aggiorna_pi']
          expire_s += config[EXPIRE_IMPORT_FU]
          cmd_opts = base_opts.dup.merge('lista_sistemi'      => lista_sistemi_id_to_obj(opts['lista_sistemi_update_pi']),
                                         'omc_id'             => lista_sistemi,
                                         'nome_progetto_irma' => nome_progetto_irma,
                                         'flag_cancellazione' => opts['flag_cancellazione'],
                                         'flag_update'        => opts['flag_update'])
          ultime_foglie = TipoAttivitaPiImportFormatoUtenteOmcLogico.ia_pi_import_fu(foglia_last_index(res), contenitore_root, cmd_opts) do |ic|
            ic['dipende_da'] = [ultime_foglie.last['key']] if ultime_foglie
          end
          res += ultime_foglie
        end
        # report comparativo
        cmd_opts = base_opts.dup.merge('omc_id'        => lista_sistemi,
                                       'nome'          => opts['nome_report'],
                                       'archivio_1'    => opts['archivio_1'],
                                       'archivio_2'    => opts['archivio_2'],
                                       'origine_1'     => opts['origine_1'],
                                       'origine_2'     => opts['origine_2'],
                                       'valore_1'      => opts['valore_1'],
                                       'valore_2'      => nome_progetto_irma,
                                       'flag_presente' => opts['flag_presente'])
        expire_s += config[EXPIRE_REPORT_COMP]
        ultime_foglie = TipoAttivitaReportComparativoOmcLogico.ia_report_comparativo(foglia_last_index(res), contenitore_root, cmd_opts) do |ic|
          ic['info']['dipende_da'] = [ultime_foglie.last['key']] if ultime_foglie
        end
        res += ultime_foglie

        # visualizza rc
        foglia_report_comparativo = ultime_foglie.last
        cmd_opts = base_opts.merge('tipo_export'          => opts['tipo_export'],
                                   'con_version'          => opts['con_version'],
                                   'filtro_version'       => opts['filtro_version'],
                                   'only_to_export_param' => opts['only_to_export_param'],
                                   'dist_assente_vuoto'   => opts['dist_assente_vuoto'])
        cmd_opts = cmd_opts.update('cc_mode' => opts['cc_mode']) if opts['cc_mode']
        cmd_opts = cmd_opts.update('solo_calcolabili' => opts['solo_calcolabili']) if opts['solo_calcolabili']
        cmd_opts = cmd_opts.update('filtro_metamodello' => opts['filtro_metamodello_rc']) if opts['filtro_metamodello_rc']
        cmd_opts = cmd_opts.update('filtro_metamodello_file' => opts['filtro_metamodello_file_rc']) if opts['filtro_metamodello_file_rc']
        cmd_opts = cmd_opts.update('solo_prioritari' => opts['solo_prioritari']) if opts['solo_prioritari']
        cmd_opts = cmd_opts.update('lista_rc' => [[Db::ReportComparativo.new(nome: opts['nome_report'], sistema_id: lista_sistemi[0][0].id)]])
        {
          'export_totale'      => { 'tipo_export'          => TIPO_EXPORT_REPORT_COMPARATIVO_TOTALE,
                                    'con_version'          => opts['con_version'],
                                    'only_to_export_param' => opts['only_to_export_param'],
                                    'dist_assente_vuoto'   => opts['dist_assente_vuoto'],
                                    'nascondi_assente_f1'  => opts['nascondi_assente_f1'],
                                    'nascondi_assente_f2'  => opts['nascondi_assente_f2']
                                  },
          'export_parziale_fu' => { 'tipo_export'          => TIPO_EXPORT_REPORT_COMPARATIVO_FU,
                                    'con_version'          => opts['con_version_fu'],
                                    'only_to_export_param' => opts['only_to_export_param_fu'],
                                    'dist_assente_vuoto'   => opts['dist_assente_vuoto_fu'],
                                    'formato'              => opts['formato_fu'],
                                    'nascondi_assente_f1'  => opts['nascondi_assente_f1_fu'],
                                    'nascondi_assente_f2'  => opts['nascondi_assente_f2_fu']
                                  },
          'conteggio_alberature' => { 'lista_rc_nome'        => opts['nome_report'],
                                      'np_alberatura'        => opts['np_alberatura'],
                                      'genera_file_filtro'   => opts['genera_file_filtro'],
                                      'con_version'          => opts['con_version_ca'],
                                      'only_to_export_param' => opts['only_to_export_param_ca'],
                                      'dist_assente_vuoto'   => opts['dist_assente_vuoto_ca'],
                                      'nascondi_assente_f1'  => opts['nascondi_assente_f1_ca'],
                                      'nascondi_assente_f2'  => opts['nascondi_assente_f2_ca']
                                    }
        }.each do |flag, flag_opts|
          next unless opts[flag]
          cmd_opts = cmd_opts.update(flag_opts)
          expire_s += config[EXPIRE_EXPORT_RC]
          ultime_foglie = foglie_export_rc(flag, foglia_last_index(res), contenitore_root, cmd_opts) do |ic|
            ic['info']['dipende_da'] = [foglia_report_comparativo['key']] if foglia_report_comparativo
          end
          res += ultime_foglie
        end
        contenitore_root['expire_sec'] = expire_s
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
