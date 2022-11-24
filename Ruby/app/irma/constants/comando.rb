# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20170831
#
# ATTENZIONE: non indentare automaticamente !!!!
#

# rubocop:disable Style/ClosingParenthesisIndentation, Style/AlignParameters
module Irma
  Constant.define(:scheduler_pool,
    normal: 'normal',
    slow:   'slow'
  )

  #
  comandi = {}
  class <<comandi
    def add(key, opts = {})
      pool = opts[:pool] || SCHEDULER_POOL_SLOW
      raise "Invalid pool #{pool} for command #{key}" unless Constant.values(:scheduler_pool).include?(pool)
      self[key] = {
        command:      (opts[:command] || key).to_s,
        msg_attivita: (opts[:msg_attivita] || "ATTIVITA_COMANDO_#{key}".upcase.to_sym),
        pool:         pool
      }
    end
  end
  comandi.add :aggiorna_adrn_da_file,           command: :aggiorna_adrn_da_file
  comandi.add :aggiorna_metamodello_fisico,     command: :aggiorna_metamodello_fisico
  comandi.add :calcolo_pi_copia,                command: :calcolo_pi_copia
  comandi.add :calcolo_pi_omc_logico,           command: :calcolo_da_progetto_radio
  comandi.add :calcolo_pi_omc_fisico,           command: :calcolo_da_progetto_radio # 20180712 NON ATTUALMENTE UTILIZZATO
  comandi.add :cancellazione_eccezioni_per_etichetta, command: :cancellazione_eccezioni_per_etichetta
  comandi.add :cleanup_db,                      command: :cleanup_db,                 pool: SCHEDULER_POOL_NORMAL
  comandi.add :completa_cgi,                    command: :completa_cgi
  comandi.add :completa_enodeb,                 command: :completa_enodeb
  comandi.add :consistency_check,               command: :consistency_check
  comandi.add :conteggio_alberature,            command: :conteggio_alberature
  comandi.add :conteggio_alberature_ade,        command: :conteggio_alberature_ade
  comandi.add :creazione_fdc_omc_fisico,        command: :creazione_fdc
  comandi.add :creazione_fdc_omc_logico,        command: :creazione_fdc
  comandi.add :elimina_celle_prn_omc_logico,    command: :elimina_celle_da_prn
  comandi.add :elimina_celle_prn_omc_fisico,    command: :elimina_celle_da_prn # 20180712 NON ATTUALMENTE UTILIZZATO
  comandi.add :export_adrn,                     command: :export_adrn,                pool: SCHEDULER_POOL_NORMAL
  comandi.add :export_adrn_su_file,             command: :export_adrn_su_file
  comandi.add :export_db,                       command: :export_db,                  pool: SCHEDULER_POOL_NORMAL
  comandi.add :export_filtro_fu,                command: :export_filtro_formato_utente
  comandi.add :export_fu_omc_logico,            command: :export_formato_utente
  comandi.add :export_fu_omc_fisico,            command: :export_formato_utente
  comandi.add :export_fu_multi_omc_logico,      command: :export_formato_utente # 2018026 OBSOLETO
  comandi.add :export_fu_multi_omc_fisico,      command: :export_formato_utente # 2018026 OBSOLETO
  comandi.add :export_fu_parziale_omc_logico,   command: :export_formato_utente
  comandi.add :export_fu_parziale_omc_fisico,   command: :export_formato_utente
  comandi.add :export_prn_omc_logico,           command: :export_progetto_radio
  comandi.add :export_rc_fu,                    command: :export_report_comparativo
  comandi.add :export_rc_tot,                   command: :export_report_comparativo
  comandi.add :import_adrn,                     command: :import_adrn,                pool: SCHEDULER_POOL_NORMAL
  comandi.add :import_costruttore_omc_logico,   command: :import_costruttore
  comandi.add :import_costruttore_omc_fisico,   command: :import_costruttore
  comandi.add :import_filtro_fu,                command: :import_filtro_formato_utente
  comandi.add :import_filtro_alberatura,        command: :import_filtro_alberatura
  comandi.add :import_fu_omc_fisico,            command: :import_formato_utente
  comandi.add :import_fu_omc_logico,            command: :import_formato_utente
  comandi.add :import_metaparametri_secondari,  command: :import_metaparametri_secondari
  comandi.add :import_metap_upd_on_crt,         command: :import_metaparametri_update_on_create
  comandi.add :import_progetto_radio,           command: :import_progetto_radio
  comandi.add :nuovo_enodebid,                  command: :nuovo_enodebid,             pool: SCHEDULER_POOL_NORMAL
  comandi.add :nuovo_cgi,                       command: :nuovo_cgi,                  pool: SCHEDULER_POOL_NORMAL
  comandi.add :nuovo_gnodebid,                  command: :nuovo_gnodebid,             pool: SCHEDULER_POOL_NORMAL
  comandi.add :pi_export_fu,                    command: :pi_export_formato_utente
  comandi.add :pi_export_fu_parziale,           command: :pi_export_formato_utente
  comandi.add :pi_import_fu_omc_logico,         command: :pi_import_formato_utente
  comandi.add :report_comparativo_omc_logico,   command: :report_comparativo
  comandi.add :report_comparativo_omc_fisico,   command: :report_comparativo
  comandi.add :ricerca_incongruenze_metamodello_fisico, command: :ricerca_incongruenze_metamodello
  comandi.add :rimozione_sessioni_scadute,      command: :rimozione_sessioni_scadute, pool: SCHEDULER_POOL_NORMAL
  comandi.add :sintesi_consistency_check,       command: :sintesi_consistency_check,  pool: SCHEDULER_POOL_NORMAL
  comandi.add :verifica_accounts,               command: :verifica_accounts,          pool: SCHEDULER_POOL_NORMAL
  Constant.define(:comando, comandi)
end
