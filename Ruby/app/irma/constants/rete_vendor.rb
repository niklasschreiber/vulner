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
  reti = {
    gsm:           { value: 1, nome: 'GSM',  alias: '2G', descr: 'Accesso mobile 2G',   reg_expr_nome_cella: '[A-Z][0-9A-Z][0-9A-F][0-9A-F][DS][0-9A-Z]', adj_prefix: 'GADJ' },
    umts:          { value: 2, nome: 'UMTS', alias: '3G', descr: 'Accesso mobile 3G',   reg_expr_nome_cella: '[A-Z][0-9A-Z][0-9A-F][0-9A-F][UW][0-9A-Z]', adj_prefix: 'UADJ' },
    lte:           { value: 3, nome: 'LTE',  alias: '4G', descr: 'Long Term Evolution', reg_expr_nome_cella: '[A-Z][0-9A-Z][0-9A-F][0-9A-F][LTEFNPM][0-9A-Z]', adj_prefix: 'LADJ' }
  }
  if (ENV['RETE_5G'] || '1') == '1'
    reti['5g'.to_sym] = { value: 4, nome: '5G', alias: '5G', descr: 'Accesso mobile 5G', adj_prefix: '5ADJ',
                          reg_expr_nome_nodo: '^' + (rnm = '[A-Z][0-9A-Z][0-9A-F][0-9A-F][VGB]') + '$', reg_expr_nome_cella: rnm + '[0-9A-Z]' }
  end
  Constant.define(:rete, reti)

  tutte_le_reti = Constant.values(:rete)
  rete_5g = defined?(RETE_5G) ? [RETE_5G] : []
  reti_senza_5g = tutte_le_reti - rete_5g
  vendors = {
    huawei:   { value: 1, nome: 'HUAWEI',   sigla: 'HUA', reti: reti_senza_5g },
    ericsson: { value: 2, nome: 'ERICSSON', sigla: 'ERI', reti: tutte_le_reti },
    nokia:    { value: 3, nome: 'NOKIA',    sigla: 'NOK', reti: tutte_le_reti }
  }
  vendors[:altiostar] = { value: 4, nome: 'ALTIOSTAR', sigla: 'ALT', reti: rete_5g } if ENV['VENDOR_ALTIOSTAR'] == '1'
  Constant.define(:vendor, vendors)

  vendors_per_rete = {}
  rpv = {}
  Constant.constants(:vendor).each do |c|
    rpv[c.value] = c.info[:reti]
    c.info[:reti].each do |rete_id|
      vendors_per_rete[rete_id] ||= []
      vendors_per_rete[rete_id] << c.value
    end
  end
  RETI_PER_VENDOR = rpv.freeze

  vpr = {}
  Constant.constants(:rete).each do |c|
    c.info[:vendors] = vendors_per_rete[c.value]
    vpr[c.value] = c.info[:vendors]
  end
  VENDORS_PER_RETE = vpr.freeze

  mca = {}
  rete_from_adj_prefix = {}
  Constant.constants(:rete).each do |r|
    mca[r.value] = {}
    Constant.constants(:rete).each do |rr|
      mca[r.value][rr.value] = 'ADJ' if r == rr
      mca[r.value][rr.value] = rr.info[:adj_prefix] if r != rr
    end
    rete_from_adj_prefix[r.info[:adj_prefix]] = r.value
  end
  MAP_CAMPO_ADJ = mca.freeze
  RETE_FROM_ADJ_PREFIX = rete_from_adj_prefix.freeze

  def self.rete_from_adj_prefix(adj_prefix)
    RETE_FROM_ADJ_PREFIX[adj_prefix]
  end

  def self.vendors_per_rete(rete)
    VENDORS_PER_RETE[rete] || []
  end

  def self.reti_per_vendor(vendor)
    RETI_PER_VENDOR[vendor] || []
  end

  Constant.define(:formato_audit,
    idl:    { value: 'idl', descr: 'Formato generico xml IDL' },
    cna:    { value: 'cna', descr: 'Formato testuale CNA' },
    xml:    { value: 'xml', descr: 'Formato xml' },
    tregpp: { value: '3gpp', descr: 'Formato xml 3gpp' }
  )
  DEFAULT_FORMATO_AUDIT_IDL = { FORMATO_AUDIT_IDL => { 'validate' => true, 'xsd' => ['raml20.xsd'] } }.freeze

  include ModConfigEnable
  REG_EXPR_NOME_CELLA_PREFIX = 'reg_expr_nome_cella_'.freeze

  Constant.constants(:rete).each do |c|
    config.define REG_EXPR_NOME_CELLA_PREFIX + c.label, c.info[:reg_expr_nome_cella],
                  descr: 'Regular Expression per validazione del nome della cella per la rete ' + c.label,
                  widget_info: 'Gui.widget.string()',
                  profili: PROFILI_PER_PARAMETRO_DI_RPN
  end

  def self.reg_expr_nome_cella_per_rete(rete_id)
    config[REG_EXPR_NOME_CELLA_PREFIX + Constant.label(:rete, rete_id)]
  end

  def reg_expr_nome_cella_per_rete(rete_id)
    self.class.reg_expr_nome_cella_per_rete(rete_id)
  end

  def self.rete_da_nome_cella(nome_cella)
    r_id = nil
    Constant.constants(:rete).map(&:value).each do |rete_id|
      next unless nome_cella.to_s.match(reg_expr_nome_cella_per_rete(rete_id))
      r_id = rete_id
    end
    r_id
  end
end
