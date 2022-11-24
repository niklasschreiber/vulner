# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20190424
#
require 'irma/calcolatore_util'

## rubocop:disable Metrics/ModuleLength, Style/ClassVars, Lint/UnifiedInteger
module Irma
  #
  module ValidatoreRegoleUtil
    #
    VALIDATORE_ESITI_OK = [ESITO_CALCOLO_OK, ESITO_CALCOLO_VALORE_VUOTO, ESITO_CALCOLO_NULL_NO_SAVE].freeze
    class RegolaPerValidatore
      attr_reader :key_1, :key_2, :regola
      def initialize(key_1:, key_2:, regola:)
        @key_1 = key_1
        @key_2 = key_2
        @regola = regola
      end
    end

    def valida_regola(rpv:, is_ae: false)
      raise ArgumentError, "Parametro rpv non della classe RegolaPerValidatore (#{rpv.inspect})" unless rpv.is_a?(RegolaPerValidatore)
      ValidatoreRegole.new(vendor_release: vendor_release).valida_regola(rpv: rpv, is_ae: is_ae, nome: nome, tipo: tipo, rete_adj: rete_adj)
    end

    def valida_tutte_le_regole(&_block) # rubocop:disable Metrics/AbcSize
      # in me e mp giro su regole_calcolo e regole_calcolo_ae
      { false => regole_calcolo, true => regole_calcolo_ae }.each do |is_ae, regole|
        (regole || {}).each do |key_1, val|
          val.each do |key_2, rc|
            rc.each_with_index do |regola, idx|
              res = valida_regola(rpv: RegolaPerValidatore.new(key_1: key_1, key_2: key_2, regola: regola), is_ae: is_ae)
              yield key_1 + SEP_VR_TERNA + key_2 + SEP_VR_TERNA + idx.to_s, regola, rete_adj, is_ae, formatta_risultato(res) if block_given?
            end
          end
        end
      end
    end

    def formatta_risultato(out_msg) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      # out_msg in input e' l'esito di valida_regola
      # vengono tolti dall'out_msg gli esiti ok per il validatore (contenuti nella costante VALIDATORE_ESITI_OK)
      return out_msg if out_msg.empty?
      res = {}
      res[:warning] = out_msg[:warning] unless out_msg[:warning].empty?
      return res unless out_msg[:risultato] && !out_msg[:risultato].empty?
      res[:risultato] = []
      res[:errore] = []
      out_msg[:risultato].each_with_index do |ris, idx|
        unless VALIDATORE_ESITI_OK.include?(ris)
          res[:risultato] << ris
          res[:errore] << out_msg[:errore][idx]
        end
      end
      if res[:risultato].empty?
        res.delete(:risultato)
        res.delete(:errore)
      end
      res
    end
  end

  class ValidatoreRegole # rubocop:disable Metrics/ClassLength
    include CalcolatoreUtil
    include ValidatoreRegoleUtil

    attr_reader :result

    def initialize(vendor_release:)
      raise "Vendor Release in input #{vendor_release} non corretta" unless vendor_release.is_a?(Db::VendorRelease)
      @vendor_release = vendor_release
      @result = {}
    end

    def get_calcolatore(hash)
      Calcolatore.new(hash)
    end

    def calcolatore(hash = {})
      @calcolatore ||= get_calcolatore(hash)
    end

    def reset_calcolatore
      return nil unless @calcolatore
      @calcolatore.reset
    ensure
      @calcolatore = nil
    end

    #
    class InfoCalcolo < Hash
      %i(nome_cella nome_cella_adiacente meta_parametro
         nome_meta_obj tipo_atteso rete_adj chiave_vr_ae).each do |m|
        define_method(m) do
          self[m]
        end
        define_method("#{m}=") do |v|
          self[m] = v
        end
      end
    end

    # metodo che valida le regole, il parametro in input regola e' un istanza di RegolaPerValidatore
    def valida_regola(nome:, tipo:, rpv:, rete_adj:, is_ae: false) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      raise ArgumentError, "Parametro rpv non della classe RegolaPerValidatore (#{rpv.inspect})" unless rpv.is_a?(RegolaPerValidatore)
      @result = { warning: [], risultato: [], errore: [] }
      return @result if (rpv.regola || '').empty?
      info_calcolo = InfoCalcolo[nome_cella: 'dummy_cell']
      info_calcolo.nome_meta_obj = nome
      info_calcolo.rete_adj = Irma::Constant.value(:rete, rete_adj) if rete_adj
      info_calcolo.tipo_atteso = tipo
      info_calcolo.nome_cella_adiacente = 'dummy_cell_ae' if rete_adj
      # se la regola non contiene variabili, risolvo subito
      rr = RuleResult.crea_da_regola(regola: rpv.regola, tipo_atteso: tipo)
      if rr
        ret = calcola(regola: rpv.regola, info_calcolo: info_calcolo)
        @result[:risultato] << ret.tipo_errore
        @result[:errore] << ret.err_msg
      elsif is_ae && [RC_DEFAULT_GRP_KEY, RC_RELNODO_GRP_KEY].include?(rpv.key_1)
        # in questo caso devo validare la regola per tutti i vendor_rete
        (VENDORS_PER_RETE[info_calcolo.rete_adj] || []).each do |vendor|
          info_calcolo.chiave_vr_ae = Db::Vendor.get_by_pk(vendor).nome + SEP_VR_TERNA + rete_adj
          ret = calcola(regola: rpv.regola, info_calcolo: info_calcolo)
          @result[:risultato] << ret.tipo_errore
          @result[:errore] << (ret.err_msg ? "calcolo per vr: #{info_calcolo.chiave_vr_ae} err: #{ret.err_msg}" : nil)
          # TODO: gestire ret e, a meno di errori sintattici, avvalorare eventuali errori come warning
        end
      else
        info_calcolo.chiave_vr_ae = imposta_chiave_vr_adj(key_1: rpv.key_1, key_2: rpv.key_2, rete_adj: info_calcolo.rete_adj) if rete_adj
        ret = calcola(regola: rpv.regola, info_calcolo: info_calcolo)
        @result[:risultato] << ret.tipo_errore
        @result[:errore] << ret.err_msg
      end
      @result
    end

    def calcola(regola:, info_calcolo:) # rubocop:disable Metrics/AbcSize
      return 'Nessuna regola da analizzare' if regola.nil?
      reset_calcolatore # TODO: da capire dove mettere il reset del calcolatore
      hash_campi_ss = imposta_variabili_speciali # da valutare se verificarne la presenza nella regola di calcolo...
      calcolatore.carica_variabili(hash_campi_ss)
      # controllo e avvaloro i campi_pr presenti nell'header_pr
      input_vars = completa_campi_pr_da_template(lista_campi_pr:  campi_pr_da_regola(rc: regola, chiave_vr: @vendor_release.compact_descr))
      calcolatore.carica_variabili_pr_cella(nome_cella: info_calcolo.nome_cella, variabili: input_vars)
      # impostazioni campi di pr ae
      if info_calcolo.rete_adj
        input_vars_ae = completa_campi_pr_da_template(lista_campi_pr: campi_pr_da_regola(rc: regola, is_adj: true, chiave_vr: info_calcolo.chiave_vr_ae))
        calcolatore.carica_variabili_pr_cella(nome_cella: info_calcolo.nome_cella_adiacente, variabili: input_vars_ae)
      end
      calcolatore.calcola_regola(regola: regola, info_calcolo: info_calcolo)
    end

    def campi_pr_da_regola(rc:, is_adj: false, chiave_vr:) # rubocop:disable Metrics/AbcSize
      hash_out = { chiave_vr => [] }
      return {} if rc.nil? || (chiave_vr || '').empty?
      lista_campi = rc.scan(/\[[aA][dD][pP][rR].\w+\]/).uniq
      if is_adj # considero le variabili di pr con _N
        lista_campi.select { |c| c.end_with?('_N]') }.each do |campo|
          hash_out[chiave_vr] << campo.split('.').last.chomp('_N]').upcase
        end
      else # considero le variabili di pr senza _N
        lista_campi.select { |c| !c.end_with?('_N]') }.each do |campo|
          hash_out[chiave_vr] << campo.split('.').last.chomp(']').upcase
        end
      end
      hash_out
    end

    def imposta_chiave_vr_adj(key_1:, key_2:, rete_adj:)
      out = ''
      case key_1
      when RC_DEFAULT_GRP_KEY, RC_RELNODO_GRP_KEY
        out = @vendor_release.vendor.nome + SEP_VR_TERNA + Constant.label(:rete, rete_adj)
      when RC_VENDORREL_GRP_KEY
        out = key_2
      when RC_VENDOR_GRP_KEY
        out = key_2 + SEP_VR_TERNA + Constant.label(:rete, rete_adj)
      end
      out
    end

    def completa_campi_pr_da_template(lista_campi_pr: {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      # lista_campi_pr: { 'vendor_release.compact_descr' = ['c1', 'c2'...], 'vendor-rete' => ['c3','c4'...],..}
      res = {} # { 'c1' => ['valore', nil, tipo_valore], 'c2' => ['valore', nil, tipo_valore]
      campi_assenti = []
      lista_campi_pr.each do |compact_vr, lista_cp|
        next if lista_cp && lista_cp.empty?
        # data la vendor_release o la vendor_instance (in caso di vendor-rete) chiamo un metodo che, data la lista di campi, li torna (per quelli che esistono) con il tipo_valore
        terna = compact_vr.split(SEP_VR_TERNA)
        vr = Db::VendorRelease.first(descr: terna[0], vendor_id: Db::Vendor.first(nome: terna[1]).id, rete_id: Db::Rete.first(nome: terna[2]).id) if terna.size == 3
        vr = Db::VendorRelease.last(vendor_id:  Db::Vendor.first(nome: terna[0]).id, rete_id:  Db::Rete.first(nome: terna[1]).id) if terna.size == 2
        # valorizzo ciascun parametro per poi passare la regola al parser per la validazione
        if vr.nil?
          @result[:warning] << "Nessuna vendor_release per #{compact_vr}"
          campi_assenti |= lista_cp
        end
        next unless vr && !(vr.header_pr || {}).empty?
        out = vr.valorizza_e_completa_campi_pr(lista_cp)
        res.merge!(out)
        next if (arr_diff = lista_cp - out.keys).empty?
        @result[:warning] |= ["I seguenti campi PR '#{arr_diff.join(ARRAY_VAL_SEP)}' non sono presenti sulla vendor_release #{vr.compact_descr}"]
        # cerco se ci sono sul @vendor e rete, per impostare il tipo corretto, altrimenti metto il default char
        tmp_out = Db::VendorRelease.last(vendor_id: @vendor_release.vendor.id, rete_id: vr.rete_id).valorizza_e_completa_campi_pr(arr_diff)
        res.merge!(tmp_out)
        campi_assenti |= (arr_diff - tmp_out.keys)
      end
      campi_assenti.each { |k| res.merge!(k => [TIPO_VALORE_DEFAULT_VAL[TIPO_VALORE_CHAR], nil, TIPO_VALORE_CHAR]) }
      res
    end

    SPECIAL_VARS = {
      CALC_SPECIAL_VAR_C_P =>  ['222222', TIPO_VALORE_CHAR],
      CALC_SPECIAL_VAR_C_PP => ['222222', TIPO_VALORE_CHAR],
      CALC_SPECIAL_VAR_P =>   ['11111', TIPO_VALORE_INTEGER],
      CALC_SPECIAL_VAR_PP =>   ['11111', TIPO_VALORE_INTEGER],
      CALC_SPECIAL_VAR_ADJ_HDR => ['aaa_2', TIPO_VALORE_CHAR],
      CALC_SPECIAL_VAR_ADJ_IDX => ['2', TIPO_VALORE_CHAR]
    }.freeze

    def imposta_variabili_speciali # rubocop:disable Metrics/AbcSize
      # restitusce una hash con chiave il nome della variabile speciale e valore l'array del valore fittizio e del tipo_valore
      res = SPECIAL_VARS.dup
      if @vendor_release.vendor_instance.prefissi_variabili_speciali_per_calcolatore
        values = Irma::Vendor::VAR_INFO.keys.each_with_object({}) { |k, ret| ret[k] = %w(1 2 3 4) }
        Irma::Vendor::VAR_INFO.each do |k, info|
          last_idx = info[:first_index] - 1
          values[k].each do |v|
            last_idx += 1
            res[format(info[:format], last_idx)] = [v, info[:tipo_valore]]
          end
          # fill remaining values with nill
          res[format(info[:format], last_idx)] = [nil] while (last_idx += 1) <= info[:last_index]
        end
      end
      res
    end
  end
end
