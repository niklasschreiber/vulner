# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190117
#

# rubocop:disable Metrics/ModuleLength
module Irma
  AZIONI_CALCOLO_ENTITA = [
    AZIONE_CALCOLO_ENTITA_OK    = 'ok'.freeze,
    AZIONE_CALCOLO_ENTITA_SKIP  = 'skip'.freeze,
    AZIONE_CALCOLO_ENTITA_ABORT = 'abort'.freeze
  ].freeze

  class EsitoCalcoloEntita
    attr_reader :tipo_segnalazione, :azione
    def initialize(tipo_segnalazione: nil, azione:)
      raise "Azione per esito calcolo '#{azione}' non valida. Valori ammessi: #{AZIONI_CALCOLO_ENTITA}" unless AZIONI_CALCOLO_ENTITA.include?(azione)
      @tipo_segnalazione = tipo_segnalazione
      @azione = azione
    end

    def abort?
      @azione == AZIONE_CALCOLO_ENTITA_ABORT
    end

    def ok?
      @azione == AZIONE_CALCOLO_ENTITA_OK
    end

    def skip?
      @azione == AZIONE_CALCOLO_ENTITA_SKIP
    end
  end

  COMPORTAMENTO_ASSENZA_REGOLE_CALCOLO_ENTITA = {
    FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                    tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_REGOLE_CALCOLO_ASSENTI),
    FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
    FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
    FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                    tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_REGOLE_CALCOLO_ASSENTI)
  }.freeze

  COMPORTAMENTO_RESULT_CALCOLO_PARAMETRO = {
    REGOLA_CALCOLO_NON_MULTI => xxx = {
      ESITO_CALCOLO_OK => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK)
      },
      ESITO_CALCOLO_ERRORE_CALCOLATORE => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_PARAM),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_PARAM),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_PARAM),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_PARAM)
      },
      ESITO_CALCOLO_ERRORE_TIPO => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_PARAM_TIPO_ERRATO),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_PARAM_TIPO_ERRATO),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_PARAM_TIPO_ERRATO),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_PARAM_TIPO_ERRATO)
      },
      ESITO_CALCOLO_VALORE_VUOTO => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK)
      },
      ESITO_CALCOLO_NULL_NO_SAVE => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP)
      }
    },
    REGOLA_CALCOLO_MULTI => Marshal.load(Marshal.dump(xxx))
  }.freeze

  COMPORTAMENTO_RESULT_CALCOLO_ENTITA = {
    # ---
    REGOLA_CALCOLO_NON_MULTI => {
      ESITO_CALCOLO_OK => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK)
      },
      ESITO_CALCOLO_ERRORE_CALCOLATORE => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA)
      },
      ESITO_CALCOLO_ERRORE_TIPO => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_TIPO_ERRATO),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_TIPO_ERRATO),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_TIPO_ERRATO),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_TIPO_ERRATO)
      },
      ESITO_CALCOLO_VALORE_VUOTO => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_VALORE_VUOTO),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP)
      }
    },
    #---
    REGOLA_CALCOLO_MULTI => {
      ESITO_CALCOLO_OK => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK)
      },
      ESITO_CALCOLO_ERRORE_CALCOLATORE => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ERRORE_CALCOLO_ENTITA)
      },
      ESITO_CALCOLO_ERRORE_TIPO => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_TIPO_ERRATO),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_TIPO_ERRATO),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_TIPO_ERRATO),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK,
                                                        tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_TIPO_ERRATO)
      },
      ESITO_CALCOLO_VALORE_VUOTO => {
        FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
        FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
        FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
        FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP)
      }
    }
  }.freeze

  COMPORTAMENTO_ERRORE_TOTALE_MULTI = {
    FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT,
                                                    tipo_segnalazione: TIPO_SEGNALAZIONE_PI_CALCOLO_CALCOLO_ENTITA_MULTI_ERRORE_TOTALE),
    FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
    FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP),
    FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP)
  }.freeze

  COMPORTAMENTO_NESSUN_PADRE = {
    FASE_CALCOLO_PI       => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT),
    FASE_CALCOLO_PI_ALIAS => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
    FASE_CALCOLO_REF      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_OK),
    FASE_CALCOLO_ADJ      => EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_ABORT)
  }.freeze

  module Vendor
    module CalcoloUtil
      extends_host_with :ClassMethods

      module ClassMethods
        class_attribute calcolo_alias?:                              false,
                        calcolo_vs_data?:                            false,
                        comportamento_assenza_regole_calcolo_entita: COMPORTAMENTO_ASSENZA_REGOLE_CALCOLO_ENTITA,
                        comportamento_errore_totale_multi:           COMPORTAMENTO_ERRORE_TOTALE_MULTI,
                        comportamento_nessun_padre:                  COMPORTAMENTO_NESSUN_PADRE,
                        comportamento_result_calcolo_entita:         COMPORTAMENTO_RESULT_CALCOLO_ENTITA,
                        comportamento_result_calcolo_parametro:      COMPORTAMENTO_RESULT_CALCOLO_PARAMETRO
      end

      clona_instance_methods_da_class_methods ClassMethods
      def calcolo_adj_da_scartare?(*)
        false
      end

      def calcolo_fase_pi_extra?(*)
        false
      end

      def determina_comportamento_assenza_regole_calcolo_entita(info_calcolo:)
        comportamento_assenza_regole_calcolo_entita[info_calcolo.fase]
      end

      def determina_comportamento_errore_totale_multi(info_calcolo:)
        comportamento_errore_totale_multi[info_calcolo.fase]
      end

      def determina_comportamento_nessun_padre(info_calcolo:)
        comportamento_nessun_padre[info_calcolo.fase]
      end

      def determina_comportamento_result_calcolo(info_calcolo:, tipo_errore:)
        if info_calcolo.meta_parametro
          determina_comportamento_result_calcolo_parametro(info_calcolo: info_calcolo, tipo_errore: tipo_errore)
        else
          determina_comportamento_result_calcolo_entita(info_calcolo: info_calcolo, tipo_errore: tipo_errore)
        end
      end

      def determina_comportamento_result_calcolo_entita(info_calcolo:, tipo_errore:)
        comportamento_result_calcolo_entita[info_calcolo.multi][tipo_errore][info_calcolo.fase]
      end

      def determina_comportamento_result_calcolo_parametro(info_calcolo:, tipo_errore:)
        comportamento_result_calcolo_parametro[info_calcolo.multi][tipo_errore][info_calcolo.fase]
      end

      def prefissi_variabili_speciali_per_calcolatore(*)
        nil
      end

      def reset_calcolo_fase_pi_extra
        @calcolo_fase_pi_extra = nil
      end

      def salva_parametri_entita?(*)
        false
      end

      def variabili_speciali_per_calcolatore(*)
        {}
      end
    end

    module Rete
      module CalcoloUtil
        # Eventuali metodi da ridefinire per i figli delle classi Vendor
      end
    end
  end
end
