# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20190424
#
require 'irma/formuz/expr_parser'

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
module Irma
  #
  module CalcolatoreUtil
    #
    class RuleResult
      attr_reader :valore, :tipo_errore, :err_msg

      REGOLA_NULL = '[NULL]'.freeze
      VAR_BEGIN = '['.freeze

      def self.crea_da_regola(regola:, tipo_atteso: TIPO_VALORE_CHAR, parametro: nil)
        return nil if regola.to_s.empty?
        return regola if regola.is_a?(self)
        if regola == REGOLA_NULL
          new(valore: nil, tipo_atteso: tipo_atteso, parametro: parametro)
        elsif !regola.index(VAR_BEGIN)
          new(valore: regola.delete("'").delete("\n").strip, tipo_atteso: tipo_atteso, parametro: parametro)
        end
      end

      def initialize(error: nil, valore: nil, tipo_valore: nil, tipo_atteso: TIPO_VALORE_CHAR, parametro: nil) # rubocop:disable Metrics/PerceivedComplexity
        @tipo_valore = tipo_valore || Irma.ricava_tipo(valore)
        if error
          @err_msg = error
          # 20190111 non piu': Per i parametri va ignorato l'errore 'Variable XXX not found'
          # @tipo_errore = (parametro && @err_msg.start_with?('Variable ')) ? ESITO_CALCOLO_NULL_NO_SAVE : ESITO_CALCOLO_ERRORE_CALCOLATORE
          @tipo_errore = ESITO_CALCOLO_ERRORE_CALCOLATORE
        elsif valore.nil?
          @err_msg = "Risultato del calcolo e' null (-> no_save)"
          @tipo_errore = parametro ? ESITO_CALCOLO_NULL_NO_SAVE : ESITO_CALCOLO_VALORE_VUOTO
        elsif valore == ''
          @tipo_errore = parametro ? ESITO_CALCOLO_OK : ESITO_CALCOLO_VALORE_VUOTO
          if @tipo_errore == ESITO_CALCOLO_OK
            @valore = valore
          else
            @err_msg = "Risultato del calcolo e' una stringa vuota"
          end
        elsif !valore.ascii_only?
          @tipo_errore = ESITO_CALCOLO_NULL_NO_SAVE
          @err_msg = "Risultato del calcolo e' una stringa con caratteri non ascii"
        elsif !tipo_valore_compatibile?(tipo_atteso)
          @valore = valore
          @tipo_errore = ESITO_CALCOLO_ERRORE_TIPO
          @err_msg = "Risultato del calcolo (#{valore}) non e' del tipo atteso (#{tipo_atteso})"
        else
          @tipo_errore = ESITO_CALCOLO_OK
          @valore = valore
        end
        if ENV['DEBUG_RESULT']
          puts "ANALISI '#{valore}', tipo_valore: #{@tipo_valore}, error: '#{error}', tipo_atteso: #{tipo_atteso}, parametro: #{parametro} " \
          " => valore: #{@valore}, tipo_errore: #{@tipo_errore}, err_msg: #{@err_msg}"
        end
        self
      end

      def ok?
        (@tipo_errore == ESITO_CALCOLO_OK) ? true : false
      end

      def tipo_valore_compatibile?(t) # rubocop:disable Metrics/PerceivedComplexity
        if t == TIPO_VALORE_CHAR || @tipo_valore == t || (@tipo_valore == TIPO_VALORE_INTEGER && t == TIPO_VALORE_FLOAT) ||
           (@tipo_valore == TIPO_VALORE_CHAR && (@valore == format('%g', @valore.to_f)))
          true
        else
          false
        end
      end

      def to_json
        { valore: @valore, tipo_valore: @tipo_valore, tipo_errore: @tipo_errore, err_msg: @err_msg }.to_json
      end
    end

    #
    class Calcolatore
      attr_reader :parser, :pr_cells, :logger, :log_prefix, :stats

      def initialize(logger: nil, log_prefix: nil, **_opts)
        @logger = logger || Irma.logger
        @log_prefix = log_prefix
        @parser = Irma.expr_parser
        @pr_cells = nil
        @stats = { regole: 0, calcoli: 0 }
        @puts_calcolo = (ENV['PUTS_CALCOLO'] || '0') == '1'
      end

      def reset
        @pr_cells.free if @pr_cells
        if @parser
          @stats[:parser] = @parser.stats
          @logger.info("#{@log_prefix}, free del parser del calcolatore (#{@parser.stats})")
          @parser.free
        end
        self
      end

      def carica_variabili_pr_cella(nome_cella:, variabili:)
        @pr_cells ||= Irma.pr_cells
        c = @pr_cells.add(nome_cella)
        variabili.each do |v_name, v_info|
          a_info = v_info.is_a?(Array) ? v_info : [v_info]
          puts "CONFIGURE PR variable = #{v_name}, value = #{a_info[0]}, tipo_valore = #{a_info[2]}" if @puts_calcolo
          begin
            c.add(name: v_name, value: a_info[0], tipo_valore: a_info[2] || TIPO_VALORE_CHAR)
          rescue
            raise "Errore nella impostazione della variabile di PR #{v_name} per la cella #{nome_cella}, valore non valido"
          end
        end
        self
      end

      def carica_variabili(hash = {})
        @parser.load_variables(hash)
      end

      # Ritorna una istanza di RuleResult
      def calcola_regola(info_calcolo:, regola:)
        @stats[:regole] += 1
        if regola.is_a?(RuleResult)
          puts "Regola precalcolata: #{regola.to_json}" if @puts_calcolo
          regola
        else
          @stats[:calcoli] += 1
          res = @parser.evaluate_formula_for_pr_cell(rule: regola, pr: @pr_cells, cell: info_calcolo.nome_cella, adj: info_calcolo.nome_cella_adiacente)
          r = analisi_res_calcolo(res_calcolo: res, parametro: info_calcolo.meta_parametro, tipo_atteso: info_calcolo.tipo_atteso)
          puts "Regola calcolata: #{r.to_json}" if @puts_calcolo
          r
        end
      end

      def analisi_res_calcolo(res_calcolo:, tipo_atteso:, parametro:)
        opts = { tipo_atteso: tipo_atteso, parametro: parametro }
        if res_calcolo.ok?
          opts[:valore] = res_calcolo.null_no_save? ? nil : res_calcolo.value
        else
          opts[:error] = res_calcolo.error
        end
        RuleResult.new(opts)
      end
    end

    #
    CALC_SPECIAL_VARS = [
      CALC_SPECIAL_VAR_ADJ_HDR = 'ADJ_HDR'.freeze,  # Adj full header
      CALC_SPECIAL_VAR_ADJ_IDX = 'ADJ_IDX'.freeze,  # Adj numeric index extracted from full header
      CALC_SPECIAL_VAR_C_P     = 'C_P'.freeze,      # Entity name (char format)
      CALC_SPECIAL_VAR_C_PP    = 'C_PP'.freeze,     # Parent entity name (char format)
      CALC_SPECIAL_VAR_P       = 'P'.freeze,        # Entity name (integer format if available)
      CALC_SPECIAL_VAR_PP      = 'PP'.freeze        # Parent entity name (integer format if available)
    ].freeze

    RULE_FIELDS = %i(regole_calcolo regole_calcolo_ae).freeze
  end
end
