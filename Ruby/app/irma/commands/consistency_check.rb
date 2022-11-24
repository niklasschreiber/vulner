# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180301
#

require 'irma/sintesi_consistency_check'

#
module Irma
  class Command < Thor
    method_option :account_id,              type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,                type: :string,  banner: "Archivio di riferimento delle entita'"
    method_option :omc_id,                  type: :numeric, banner: 'Sistema/OmcFisico per cui effettuare il calcolo' # (id)
    method_option :lock_expire_pi,          type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{CALCOLO_PR_LOCK_EXPIRE})"
    method_option :min_celle_precar,        type: :numeric, banner: "Minimo numero celle per precaricamento (default valore di configurazione #{CALCOLO_PR_MIN_CELLE_PER_PRECARICAMENTO})"
    method_option :nome_progetto_irma,      type: :string,  banner: 'Nome per il ProgettoIrma da creare'
    method_option :omc_fisico,              type: :boolean, banner: 'Attivazione calcolo per Omc Fisico', default: false
    method_option :nome_report_comparativo, type: :string,  banner: 'Nome del Report Comparativo'
    method_option :lock_expire_rc,          type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{REPORT_COMP_LOCK_EXPIRE})"

    common_options 'consistency_check', 'Esegue il calcolo per celle di Progetto Radio ed il Report Comparativo'
    def consistency_check # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      omc = Db::Sistema.first(id: options[:omc_id])
      rete = Db::Rete.get_by_pk(omc.rete_id).nome
      log_prefix = "Calcolo da ProgettoRadio e Report Comparativo Omc #{options[:omc_fisico] ? 'Fisico' : 'Logico'} #{omc.full_descr}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: log_prefix) do
        res = {}
        nome_pi = options[:nome_progetto_irma] || "PI#{RC_CONSISTENCY_CHECK_PATTERN}#{omc.descr}_#{rete}-omcfisico-#{Time.now.strftime('%Y%m%d%H%M%S')}"
        res[:pi] = Command.process([Constant.info(:comando, COMANDO_CALCOLO_PI_OMC_LOGICO)[:command],
                                    '--account_id', options[:account_id], '--archivio', options[:archivio],
                                    '--omc_id', options[:omc_id], '--filtro_metamodello', '', '--lista_celle', ALL_PRN_CELLS,
                                    '--nome_progetto_irma', nome_pi, '--tipo_sorgente', CALCOLO_SORGENTE_OMCFISICO,
                                    '--attivita_id', options[:attivita_id]], logger: Command.logger)
        nome_rc = options[:nome_report_comparativo] || "RC#{RC_CONSISTENCY_CHECK_PATTERN}#{omc.descr}_#{rete}-rete-pi-#{Time.now.strftime('%Y%m%d%H%M%S')}"
        res[:rc] = Command.process([Constant.info(:comando, COMANDO_REPORT_COMPARATIVO_OMC_LOGICO)[:command],
                                    '--nome', nome_rc, '--account_id', options[:account_id],
                                    '--origine_1', 'omc_fisico_id', '--archivio_1', options[:archivio], '--valore_1', omc.omc_fisico_id,
                                    '--origine_2', 'pi_nome', '--archivio_2', 'pi', '--valore_2', nome_pi, '--attivita_id', options[:attivita_id]], logger: Command.logger)
        res[CONSISTENCY_CHECK_SINTESI_KEYWORD.to_sym] = SintesiConsistencyCheck.new(attivita_id: options[:attivita_id]).genera_sintesi(pi_res: res[:pi], rc_res: res[:rc])
        res
      end
    end

    method_option :out_file,                type: :string,  banner: 'Nome del file di sintesi'
    method_option :out_dir_root,            type: :string,  banner: 'Cartella per il file di sintesi'
    common_options 'sintesi_consistency_check', 'Genera il file xlsx con la sintesi di tutti i consistency check effettuati dalle attività parallele'
    def sintesi_consistency_check # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      artifacts = []
      res = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: "Sintesi Consistency Check (attivita con id #{options[:attivita_id]})") do
        @out_dir_root = options[:out_dir_root] || Irma.tmp_sub_dir('sintesi_consistency_check')
        tmp_out_dir = Irma.tmp_sub_dir('temp_sintesi_consistency_check')

        scc = SintesiConsistencyCheck.new(attivita_id: options[:attivita_id])

        # File di sintesi
        out_file = File.join(tmp_out_dir, options[:out_file] || "sintesi_consistency_check_#{Time.now.strftime('%Y%m%d-%H%M')}.xlsx")
        scc.crea_xlsx(file: out_file)
        if File.exist?(out_file)
          target_path = File.join(@out_dir_root, File.basename(out_file))
          # move artifact into out_dir if absolute, otherwise on shared
          Pathname.new(@out_dir_root).relative? ? shared_post_file(out_file, target_path) : FileUtils.mv(out_file, target_path)
          artifacts << [target_path, 'export_sintesi_consistency_check']
        end

        # File cc_filtro_parametri
        out_files_cc_fp = scc.file_cc_filtro_parametri(out_dir: tmp_out_dir)
        (out_files_cc_fp || []).each do |out_file_cc_fp|
          next unless File.exist?(out_file_cc_fp)
          target_path = File.join(@out_dir_root, File.basename(out_file_cc_fp))
          # move artifact into out_dir if absolute, otherwise on shared
          Pathname.new(@out_dir_root).relative? ? shared_post_file(out_file_cc_fp, target_path) : FileUtils.mv(out_file_cc_fp, target_path)
          artifacts << [target_path, 'export_cc_filtro_parametri']
        end

        FileUtils.rm_rf(tmp_out_dir)
        {}
      end
      res.delete(:result)
      res[:artifacts] = artifacts
      res
    end

    private

    def pre_consistency_check
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
