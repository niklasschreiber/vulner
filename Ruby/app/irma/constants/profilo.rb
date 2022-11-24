# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20170831
#
# ATTENZIONE: non indentare automaticamente !!!!
#

# rubocop:disable Metrics/LineLength, Metrics/ModuleLength
module Irma
  #
  TIPI_AMBIENTE_EXTENDED = TIPI_AMBIENTE.merge(nodef: { value: 'nodef', descr: 'Ambiente non definito' })
  Constant.define(:sessione, TIPI_AMBIENTE_EXTENDED, :ambiente)
  Constant.define(:sessione_chiusa, TIPI_AMBIENTE_EXTENDED, :ambiente)
  Constant.define(:profilo, TIPI_AMBIENTE_EXTENDED, :ambiente)

  Constant.define(:profilo,
                  ggu: {
                    value:               1,
                    nome:                'GGU',
                    descr:               'Gestisce gli account',
                    ambiente:            PROFILO_AMBIENTE_NODEF,
                    funzioni_di_default: tutte_le_funzioni(FUNZIONE_GESTIONE_ACCOUNTS, FUNZIONE_LISTA_SESSIONI),
                    assegnabile_da_gui:  true,
                    con_competenze:      false
                  },
                  ga: {
                    value:               2,
                    nome:                'GA',
                    descr:               'Gestione applicazione',
                    ambiente:            PROFILO_AMBIENTE_NODEF,
                    funzioni_di_default: tutte_le_funzioni(FUNZIONE_LISTA_SESSIONI, FUNZIONE_GESTIONE_ALLARMI, FUNZIONE_LISTA_EVENTI, FUNZIONE_GESTIONE_APP_CONFIG,
                                                           FUNZIONE_LISTA_STORICO_ATTIVITA, FUNZIONE_GESTIONE_ATTIVITA_SCHEDULATE),
                    assegnabile_da_gui:  true,
                    con_competenze:      false
                  },
                  superuser_prog: {
                    value:               3,
                    nome:                'SUPERUSER_PROG',
                    descr:               'Superuser progettazione',
                    ambiente:            PROFILO_AMBIENTE_PROG,
                    funzioni_di_default: fsp = tutte_le_funzioni(FUNZIONE_LISTA_SESSIONI, FUNZIONE_GESTIONE_ALLARMI, FUNZIONE_LISTA_EVENTI,
                                                                 FUNZIONE_GESTIONE_ACCOUNTS, FUNZIONE_GESTIONE_APP_CONFIG, FUNZIONE_GESTIONE_SEGNALAZIONI, FUNZIONE_GESTIONE_ANAGRAFICA,
                                                                 FUNZIONE_IMPORT_OMC_LOGICO, FUNZIONE_EXPORT_FORMATO_UTENTE, FUNZIONE_EXPORT_FORMATO_UTENTE_PARZIALE,
                                                                 FUNZIONE_IMPORT_OMC_FISICO, FUNZIONE_EXPORT_FU_OMC_FISICO, FUNZIONE_EXPORT_FU_OMC_FISICO_PARZIALE,
                                                                 FUNZIONE_IMPORT_FORMATO_UTENTE, FUNZIONE_PI_CALCOLO, FUNZIONE_PI_VISUALIZZA, FUNZIONE_PI_IMPORT_FORMATO_UTENTE,
                                                                 FUNZIONE_IMPORT_PROGETTO_RADIO, FUNZIONE_VISUALIZZA_PRN, FUNZIONE_REPORT_COMPARATIVO, FUNZIONE_REPORT_COMPARATIVO_OMC_FISICO,
                                                                 FUNZIONE_VISUALIZZA_REPORT_COMPARATIVO,
                                                                 FUNZIONE_IMPORT_ADRN,
                                                                 FUNZIONE_LISTA_STORICO_ATTIVITA, FUNZIONE_GESTIONE_META_MODELLO, FUNZIONE_GESTIONE_ATTIVITA_SCHEDULATE, FUNZIONE_LISTA_TEMPLATE_PR,
                                                                 FUNZIONE_COMPLETA_ENODEBID, FUNZIONE_CANCELLAZIONE_ENODEB, FUNZIONE_CREAZIONE_FDC_OMC_LOGICO,
                                                                 FUNZIONE_REPORT_CALCOLO_PI_DA_PRN_OMC_LOGICO, FUNZIONE_BROWSING, FUNZIONE_PI_EXPORT_FU_TOTALE, FUNZIONE_CONSISTENCY_CHECK,
                                                                 FUNZIONE_IMPORT_FU_OMC_FISICO, FUNZIONE_ELIMINA_CELLE_DA_PRN, FUNZIONE_EXPORT_INCONGRUENZE_METAMODELLO, FUNZIONE_FLAG_UPDATE_ON_CREATE,
                                                                 FUNZIONE_CANCELLAZIONE_CGI, FUNZIONE_COMPLETA_CGI, FUNZIONE_AGGIORNA_ECCEZIONI, FUNZIONE_ELIMINA_ECCEZIONI, FUNZIONE_METAPARAMETRI_SECONDARI,
                                                                 FUNZIONE_CANCELLAZIONE_GNODEB),
                    assegnabile_da_gui:  false,
                    con_competenze:      false
                  },
                  superuser_ro_prog: {
                    value:               4,
                    nome:                'SUPERUSER_RO_PROG',
                    descr:               'Superuser progettazione read-only',
                    ambiente:            PROFILO_AMBIENTE_PROG,
                    funzioni_di_default: fsrp = tutte_le_funzioni(FUNZIONE_LISTA_SESSIONI, FUNZIONE_LISTA_ALLARMI, FUNZIONE_LISTA_APP_CONFIG,
                                                                  FUNZIONE_LISTA_ACCOUNTS, FUNZIONE_LISTA_SEGNALAZIONI, FUNZIONE_LISTA_ANAGRAFICA, FUNZIONE_LISTA_STORICO_ATTIVITA,
                                                                  FUNZIONE_EXPORT_ADRN, FUNZIONE_LISTA_ATTIVITA_SCHEDULATE, FUNZIONE_LISTA_META_MODELLO, FUNZIONE_LISTA_TEMPLATE_PR, FUNZIONE_BROWSING),
                    assegnabile_da_gui:  false,
                    con_competenze:      false
                  },
                  rpn: {
                    value:               5,
                    nome:               'RPN',
                    descr:              'RPN',
                    ambiente:            PROFILO_AMBIENTE_PROG,
                    funzioni_di_default: tutte_le_funzioni(FUNZIONE_LISTA_SESSIONI, FUNZIONE_GESTIONE_APP_CONFIG, FUNZIONE_LISTA_ALLARMI, FUNZIONE_IMPORT_OMC_LOGICO, FUNZIONE_EXPORT_FORMATO_UTENTE,  FUNZIONE_EXPORT_FORMATO_UTENTE_PARZIALE,
                                                           FUNZIONE_GESTIONE_SEGNALAZIONI, FUNZIONE_GESTIONE_ANAGRAFICA, FUNZIONE_IMPORT_OMC_FISICO, FUNZIONE_EXPORT_FU_OMC_FISICO, FUNZIONE_EXPORT_FU_OMC_FISICO_PARZIALE, FUNZIONE_IMPORT_FORMATO_UTENTE,
                                                           FUNZIONE_PI_CALCOLO, FUNZIONE_PI_VISUALIZZA, FUNZIONE_PI_IMPORT_FORMATO_UTENTE, FUNZIONE_VISUALIZZA_PRN, FUNZIONE_REPORT_COMPARATIVO,
                                                           FUNZIONE_REPORT_COMPARATIVO_OMC_FISICO, FUNZIONE_VISUALIZZA_REPORT_COMPARATIVO, FUNZIONE_LISTA_STORICO_ATTIVITA, FUNZIONE_GESTIONE_META_MODELLO,
                                                           FUNZIONE_IMPORT_ADRN, FUNZIONE_GESTIONE_ATTIVITA_SCHEDULATE, FUNZIONE_LISTA_TEMPLATE_PR, FUNZIONE_CANCELLAZIONE_ENODEB, FUNZIONE_CREAZIONE_FDC_OMC_LOGICO,
                                                           FUNZIONE_REPORT_CALCOLO_PI_DA_PRN_OMC_LOGICO, FUNZIONE_BROWSING, FUNZIONE_PI_EXPORT_FU_TOTALE, FUNZIONE_CONSISTENCY_CHECK, FUNZIONE_IMPORT_FU_OMC_FISICO,
                                                           FUNZIONE_EXPORT_INCONGRUENZE_METAMODELLO, FUNZIONE_FLAG_UPDATE_ON_CREATE,
                                                           FUNZIONE_CANCELLAZIONE_CGI, FUNZIONE_VISUALIZZA_ECCEZIONI, FUNZIONE_METAPARAMETRI_SECONDARI, FUNZIONE_CANCELLAZIONE_GNODEB),
                    assegnabile_da_gui:  true,
                    con_competenze:      true
                  },
                  rp: {
                    value:               6,
                    nome:                'RP',
                    descr:               'RP',
                    ambiente:            PROFILO_AMBIENTE_PROG,
                    funzioni_di_default: frp = tutte_le_funzioni(FUNZIONE_LISTA_ANAGRAFICA, FUNZIONE_LISTA_ALLARMI,
                                                                 FUNZIONE_IMPORT_OMC_LOGICO, FUNZIONE_EXPORT_FORMATO_UTENTE, FUNZIONE_EXPORT_FORMATO_UTENTE_PARZIALE, FUNZIONE_IMPORT_FORMATO_UTENTE,
                                                                 FUNZIONE_LISTA_SEGNALAZIONI, FUNZIONE_EXPORT_FU_OMC_FISICO, FUNZIONE_EXPORT_FU_OMC_FISICO_PARZIALE, FUNZIONE_PI_CALCOLO, FUNZIONE_PI_VISUALIZZA, FUNZIONE_PI_IMPORT_FORMATO_UTENTE,
                                                                 FUNZIONE_IMPORT_PROGETTO_RADIO, FUNZIONE_VISUALIZZA_PRN, FUNZIONE_REPORT_COMPARATIVO, FUNZIONE_VISUALIZZA_REPORT_COMPARATIVO,
                                                                 FUNZIONE_REPORT_COMPARATIVO_OMC_FISICO, FUNZIONE_LISTA_STORICO_ATTIVITA, FUNZIONE_GESTIONE_ATTIVITA_SCHEDULATE, FUNZIONE_EXPORT_ADRN,
                                                                 FUNZIONE_LISTA_META_MODELLO, FUNZIONE_LISTA_TEMPLATE_PR, FUNZIONE_COMPLETA_ENODEBID, FUNZIONE_INSERIMENTO_ENODEB, FUNZIONE_CREAZIONE_FDC_OMC_LOGICO,
                                                                 FUNZIONE_REPORT_CALCOLO_PI_DA_PRN_OMC_LOGICO, FUNZIONE_PI_EXPORT_FU_TOTALE, FUNZIONE_ELIMINA_CELLE_DA_PRN, FUNZIONE_FLAG_UPDATE_ON_CREATE,
                                                                 FUNZIONE_INSERIMENTO_CGI, FUNZIONE_COMPLETA_CGI, FUNZIONE_AGGIORNA_ECCEZIONI, FUNZIONE_ELIMINA_ECCEZIONI, FUNZIONE_METAPARAMETRI_SECONDARI, FUNZIONE_INSERIMENTO_GNODEB),
                    assegnabile_da_gui:  true,
                    con_competenze:      true
                  },
                  rq: {
                    value:               7,
                    nome:                'RQ',
                    descr:               'R Qualita\'',
                    ambiente:            PROFILO_AMBIENTE_QUAL,
                    funzioni_di_default: frp - tutte_le_funzioni_richieste_da(FUNZIONE_IMPORT_PROGETTO_RADIO, FUNZIONE_COMPLETA_ENODEBID, FUNZIONE_INSERIMENTO_ENODEB, FUNZIONE_CREAZIONE_FDC_OMC_LOGICO,
                                                                              FUNZIONE_ELIMINA_CELLE_DA_PRN, FUNZIONE_INSERIMENTO_CGI, FUNZIONE_COMPLETA_CGI, FUNZIONE_AGGIORNA_ECCEZIONI, FUNZIONE_ELIMINA_ECCEZIONI,
                                                                              FUNZIONE_INSERIMENTO_GNODEB),
                    assegnabile_da_gui:  true,
                    con_competenze:      true
                  },
                  superuser_qual: {
                    value:               8,
                    nome:                'SUPERUSER_QUAL',
                    descr:               'Superuser Qualità',
                    ambiente:            PROFILO_AMBIENTE_QUAL,
                    funzioni_di_default: fsp - tutte_le_funzioni_richieste_da(FUNZIONE_CREAZIONE_FDC_OMC_LOGICO, FUNZIONE_CANCELLAZIONE_CGI, FUNZIONE_COMPLETA_CGI),
                    assegnabile_da_gui:  false,
                    con_competenze:      false
                  },
                  superuser_ro_qual: {
                    value:               9,
                    nome:                'SUPERUSER_RO_QUAL',
                    descr:               'Superuser qualità read-only',
                    ambiente:            PROFILO_AMBIENTE_QUAL,
                    funzioni_di_default: fsrp,
                    assegnabile_da_gui:  false,
                    con_competenze:      false
                  }
                 )
  PROFILI_SUPERUSER = [PROFILO_SUPERUSER_PROG.to_s, PROFILO_SUPERUSER_RO_PROG.to_s, PROFILO_SUPERUSER_QUAL.to_s, PROFILO_SUPERUSER_RO_QUAL.to_s].freeze
  PROFILI_PER_PARAMETRO_DI_RPN = ([PROFILO_RPN.to_s] + PROFILI_SUPERUSER).freeze
  PROFILI_PER_PARAMETRO_DI_GA = ([PROFILO_GA.to_s] + PROFILI_SUPERUSER).freeze
end
