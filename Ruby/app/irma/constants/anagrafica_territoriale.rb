# vim: set fileencoding=utf-8
# #
# # Author: G. Cristelli
# #
# # Creation date: 20170901
# #
# # ATTENZIONE: non indentare automaticamente !!!!
# #
module Irma
  # rubocop:disable Style/MutableConstant, Style/IndentHash, Style/ClosingParenthesisIndentation, Style/AlignParameters
  class AnagraficaTerritoriale # rubocop:disable Metrics/ClassLength
    Constant.define(:noa,
      undefined: { value: 'undefined', descr: 'Not defined' },
      gos:       { value: 'GOS',       descr: 'Tim in Nave' },
      no:        { value: 'NO',        descr: 'Nord-Ovest' },
      ne:        { value: 'NE',        descr: 'Nord-Est' },
      c:         { value: 'C',         descr: 'Centro' },
      s:         { value: 'S',         descr: 'Sud' }
    )
    @pre_esercizio = (ENV['IRMA_PRE'] || '0') == '1'
    if @pre_esercizio
      Constant.define(:area_territoriale, AREE_TERRITORIALI = {
        'C'  => { regioni: [], range: { RETE_LTE => [[1_000_101, 1_000_300]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_200_001, 1_350_000]] } : {}), province: [], noa: NOA_C },
        'C1' => { regioni: [], range: { RETE_LTE => [[1_000_301, 1_000_400]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_050_001, 1_200_000]] } : {}), province: [], noa: NOA_C },
        'CN' => { regioni: [], range: { RETE_LTE => [[1_000_751, 1_001_000]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_950_001, 2_100_000]] } : {}), province: [], noa: NOA_NE },
        'LO' => { regioni: [], range: { RETE_LTE => [[1_000_401, 1_000_500]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_500_001, 1_650_000]] } : {}), province: [], noa: NOA_NO },
        'NE' => { regioni: [], range: { RETE_LTE => [[1_000_501, 1_000_750]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_800_001, 1_950_000]] } : {}), province: [], noa: NOA_NE },
        'NO' => { regioni: [], range: { RETE_LTE => [[1_000_001, 1_000_100]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[2_100_001, 2_250_000]] } : {}), province: [], noa: NOA_NO },
        'S1' => { regioni: [], range: { RETE_LTE => [[1_001_201, 1_001_500]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_350_001, 1_500_000]] } : {}), province: [], noa: NOA_S },
        'S2' => { regioni: [], range: { RETE_LTE => [[1_001_001, 1_001_200]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_650_001, 1_800_000]] } : {}), province: [], noa: NOA_S },
        'SS' => { regioni: [], range: { RETE_LTE => [[1_001_501, 1_001_600]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[]] } : {}),                     province: [], noa: NOA_GOS },
        'TT' => { regioni: [], range: { RETE_LTE => [[1, 1_000_000]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_049_000, 1_049_999]] } : {}),         province: [], noa: NOA_UNDEFINED }
      })
    else
      Constant.define(:area_territoriale, AREE_TERRITORIALI = {
        'C'  => { regioni: [], range: { RETE_LTE => [[300_001, 400_000], [1_000_101, 1_000_300]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_200_001, 1_350_000]] } : {}),
                  province: [], noa: NOA_C },
        'C1' => { regioni: [], range: { RETE_LTE => [[200_001, 300_000], [1_000_301, 1_000_400]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_050_001, 1_200_000]] } : {}),
                  province: [], noa: NOA_C },
        'CN' => { regioni: [], range: { RETE_LTE => [[800_001, 900_000], [1_000_751, 1_001_000]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_950_001, 2_100_000]] } : {}),
                  province: [], noa: NOA_NE },
        'LO' => { regioni: [], range: { RETE_LTE => [[500_001, 600_000], [1_000_401, 1_000_500]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_500_001, 1_650_000]] } : {}),
                  province: [], noa: NOA_NO },
        'NE' => { regioni: [], range: { RETE_LTE => [[700_001, 800_000], [1_000_501, 1_000_750]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_800_001, 1_950_000]] } : {}),
                  province: [], noa: NOA_NE },
        'NO' => { regioni: [], range: { RETE_LTE => [[900_001, 1_000_000], [1_000_001, 1_000_100]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[2_100_001, 2_250_000]] } : {}),
                  province: [], noa: NOA_NO },
        'S1' => { regioni: [], range: { RETE_LTE => [[400_001, 500_000], [1_001_201, 1_001_500]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_350_001, 1_500_000]] } : {}),
                  province: [], noa: NOA_S },
        'S2' => { regioni: [], range: { RETE_LTE => [[600_001, 700_000], [1_001_001, 1_001_200]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_650_001, 1_800_000]] } : {}),
                  province: [], noa: NOA_S },
        'SS' => { regioni: [], range: { RETE_LTE => [[1_048_001, 1_048_500]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[]] } : {}), province: [], noa: NOA_GOS },
        'TT' => { regioni: [], range: { RETE_LTE => [[1, 100]] }.merge(defined?(RETE_5G) ? { RETE_5G => [[1_049_000, 1_049_999]] } : {}), province: [], noa: NOA_UNDEFINED }
      })
    end

    # TODO: da aggiungere la descrizione dell'area sistema...
    AREE_SISTEMA = { 'TT' => { regioni: [], province: [] } }
    REGIONI = {}
    def self.nuova_regione(regione, at:, as:, **opts)
      REGIONI[regione] = { at: at, as: as, province: [], regioni_confinanti: [] }.merge(opts)
      # as.each { |a| AREE_SISTEMA[a][:regioni] << regione }
      as.each do |a|
        AREE_SISTEMA[a] ||= { regioni: [], province: [], at: [] }
        AREE_SISTEMA[a][:regioni] << regione
      end
      Constant.info(:area_territoriale, at)[:regioni] << regione if at
    end

    def self.regioni_confinanti(r1, r2)
      [r1, r2].each { |regione| raise "Regione #{regione} non definita" unless REGIONI[regione] }
      REGIONI[r1][:regioni_confinanti] << r2
      REGIONI[r2][:regioni_confinanti] << r1
    end

    PROVINCE = {}
    def self.nuova_provincia(pv, regione:, **opts) # rubocop:disable Metrics/AbcSize
      raise "Regione #{regione} non definita" unless REGIONI[regione]
      PROVINCE[pv] = { regione: regione }.merge(opts)
      REGIONI[regione][:province] << pv
      at = REGIONI[regione][:at]
      as = REGIONI[regione][:as]
      as.each { |a| AREE_SISTEMA[a][:province] << pv }
      Constant.info(:area_territoriale, at)[:province] << pv if at
    end

    # popolamento
    nuova_regione('ABRUZZO',          at: AREA_TERRITORIALE_C,  as: ['AM'], label_scc: 'Abruzzo')
    nuova_regione('MOLISE',           at: AREA_TERRITORIALE_C,  as: ['AM'], label_scc: 'Molise')
    nuova_regione('LAZIO',            at: AREA_TERRITORIALE_C,  as: ['LA'], label_scc: 'Lazio')
    nuova_regione('SARDEGNA',         at: AREA_TERRITORIALE_C,  as: ['SA'], label_scc: 'Sardegna')
    nuova_regione('TOSCANA',          at: AREA_TERRITORIALE_C1, as: ['C1'], label_scc: 'Toscana')
    nuova_regione('LIGURIA',          at: AREA_TERRITORIALE_C1, as: ['C1'], label_scc: 'Liguria')
    nuova_regione('EMILIA ROMAGNA',   at: AREA_TERRITORIALE_CN, as: ['ER'], label_scc: 'Emilia')
    nuova_regione('MARCHE',           at: AREA_TERRITORIALE_CN, as: ['MU'], label_scc: 'Marche')
    nuova_regione('UMBRIA',           at: AREA_TERRITORIALE_CN, as: ['MU'], label_scc: 'Umbria')
    nuova_regione('LOMBARDIA',        at: AREA_TERRITORIALE_LO, as: ['LO'], label_scc: 'Lombardia')
    nuova_regione('FRIULI',           at: AREA_TERRITORIALE_NE, as: ['FV'], label_scc: 'Friuli')
    nuova_regione('VENETO',           at: AREA_TERRITORIALE_NE, as: ['VE'], label_scc: 'Veneto')
    nuova_regione('TRENTINO ALTO A.', at: AREA_TERRITORIALE_NE, as: ['TA'], label_scc: 'Trentino')
    nuova_regione('PIEMONTE',         at: AREA_TERRITORIALE_NO, as: ['NO'], label_scc: 'Piemonte')
    nuova_regione('VALLE D\'AOSTA',   at: AREA_TERRITORIALE_NO, as: ['NO'], label_scc: 'VDA')
    nuova_regione('CAMPANIA',         at: AREA_TERRITORIALE_S1, as: ['CB'], label_scc: 'Campania')
    nuova_regione('BASILICATA',       at: AREA_TERRITORIALE_S1, as: ['S1'], label_scc: 'Basilicata')
    nuova_regione('PUGLIA',           at: AREA_TERRITORIALE_S1, as: ['S1'], label_scc: 'Puglia')
    nuova_regione('CALABRIA',         at: AREA_TERRITORIALE_S2, as: ['S2'], label_scc: 'Calabria')
    nuova_regione('SICILIA',          at: AREA_TERRITORIALE_S2, as: ['S2'], label_scc: 'Sicilia')
    nuova_regione('GSM ON THE SHIP',  at: AREA_TERRITORIALE_SS, as: ['SS'], label_scc: 'GSMOTS')
    nuova_regione('SISTEMI SPECIALI', at: nil,                  as: ['SS'], label_scc: 'SS')
    nuova_regione('TEST',             at: AREA_TERRITORIALE_TT, as: ['TT'])

    # rubocop:disable Style/WordArray
    # Regioni confinanti
    [
      ['ABRUZZO', 'GSM ON THE SHIP'],
      ['ABRUZZO', 'LAZIO'],
      ['ABRUZZO', 'MARCHE'],
      ['ABRUZZO', 'MOLISE'],
      ['ABRUZZO', 'SISTEMI SPECIALI'],
      ['BASILICATA', 'CALABRIA'],
      ['BASILICATA', 'CAMPANIA'],
      ['BASILICATA', 'GSM ON THE SHIP'],
      ['BASILICATA', 'PUGLIA'],
      ['BASILICATA', 'SISTEMI SPECIALI'],
      ['CALABRIA', 'GSM ON THE SHIP'],
      ['CALABRIA', 'SICILIA'],
      ['CALABRIA', 'SISTEMI SPECIALI'],
      ['CAMPANIA', 'GSM ON THE SHIP'],
      ['CAMPANIA', 'LAZIO'],
      ['CAMPANIA', 'MOLISE'],
      ['CAMPANIA', 'PUGLIA'],
      ['CAMPANIA', 'SISTEMI SPECIALI'],
      ['EMILIA ROMAGNA', 'GSM ON THE SHIP'],
      ['EMILIA ROMAGNA', 'LIGURIA'],
      ['EMILIA ROMAGNA', 'LOMBARDIA'],
      ['EMILIA ROMAGNA', 'MARCHE'],
      ['EMILIA ROMAGNA', 'PIEMONTE'],
      ['EMILIA ROMAGNA', 'SISTEMI SPECIALI'],
      ['EMILIA ROMAGNA', 'TOSCANA'],
      ['EMILIA ROMAGNA', 'VENETO'],
      ['FRIULI', 'GSM ON THE SHIP'],
      ['FRIULI', 'SISTEMI SPECIALI'],
      ['FRIULI', 'VENETO'],
      ['LAZIO', 'GSM ON THE SHIP'],
      ['LAZIO', 'MARCHE'],
      ['LAZIO', 'MOLISE'],
      ['LAZIO', 'SISTEMI SPECIALI'],
      ['LAZIO', 'TOSCANA'],
      ['LAZIO', 'UMBRIA'],
      ['LIGURIA', 'GSM ON THE SHIP'],
      ['LIGURIA', 'PIEMONTE'],
      ['LIGURIA', 'SISTEMI SPECIALI'],
      ['LIGURIA', 'TOSCANA'],
      ['LOMBARDIA', 'PIEMONTE'],
      ['LOMBARDIA', 'SISTEMI SPECIALI'],
      ['LOMBARDIA', 'TRENTINO ALTO A.'],
      ['LOMBARDIA', 'VENETO'],
      ['MARCHE', 'GSM ON THE SHIP'],
      ['MARCHE', 'SISTEMI SPECIALI'],
      ['MARCHE', 'TOSCANA'],
      ['MARCHE', 'UMBRIA'],
      ['MOLISE', 'GSM ON THE SHIP'],
      ['MOLISE', 'PUGLIA'],
      ['MOLISE', 'SISTEMI SPECIALI'],
      ['PIEMONTE', 'SISTEMI SPECIALI'],
      ['PIEMONTE', 'VALLE D\'AOSTA'],
      ['PUGLIA', 'GSM ON THE SHIP'],
      ['PUGLIA', 'SISTEMI SPECIALI'],
      ['SARDEGNA', 'GSM ON THE SHIP'],
      ['SARDEGNA', 'SISTEMI SPECIALI'],
      ['SICILIA', 'GSM ON THE SHIP'],
      ['SICILIA', 'SISTEMI SPECIALI'],
      ['TOSCANA', 'GSM ON THE SHIP'],
      ['TOSCANA', 'SISTEMI SPECIALI'],
      ['TOSCANA', 'UMBRIA'],
      ['TRENTINO ALTO A.', 'SISTEMI SPECIALI'],
      ['TRENTINO ALTO A.', 'VENETO'],
      ['UMBRIA', 'SISTEMI SPECIALI'],
      ['VALLE D\'AOSTA', 'SISTEMI SPECIALI'],
      ['VENETO', 'GSM ON THE SHIP'],
      ['VENETO', 'SISTEMI SPECIALI'],
      ['SISTEMI SPECIALI', 'GSM ON THE SHIP']
    ].each { |rrr| regioni_confinanti(*rrr) }

    # costante per il metodo validate_constant sul sistema
    aass = {}
    AREE_SISTEMA.each { |as, as_info| aass[as] = { value: as }.merge(as_info) }
    # puts "aree_sistema #{aass}"
    Constant.define(:sistema, aass, :area_sistema)

    # costante per il metodo validate_constant sul anagrafica_enodeb
    Constant.define(:anagrafica_enodeb, AREE_TERRITORIALI, :area_territoriale)

    # costante per il metodo validate_constant sull'anagrafica_gnodeb
    Constant.define(:anagrafica_gnodeb, AREE_TERRITORIALI, :area_territoriale)

    # popolamento province da file
    File.readlines(File.join(__dir__, 'province.csv')).each do |l|
      pv, regione, descr = l.chomp.split(',')
      nuova_provincia(pv, regione: regione, descr: descr)
    end

    # utility
    def self.regioni_per_as(as)
      AREE_SISTEMA.fetch(as)[:regioni]
    end

    def self.province_per_as(as)
      AREE_SISTEMA.fetch(as)[:province]
    end

    def self.province_per_at(at)
      Constant.info(:area_territoriale, at)[:province]
    end

    def self.tutte_le_province_con_at
      res = []
      AREE_TERRITORIALI.each { |_k, v| res |= v[:province] }
      res
    end

    def self.tutte_le_province
      PROVINCE.keys
    end

    # data una provincia ritorna la/le sue area/e_territoriale
    def self.at_di_provincia(prov)
      res = []
      AREE_TERRITORIALI.each do |k, v|
        res |= [k] if v[:province].include?(prov)
      end
      res
    end

    # data un'area_sistema torna l'array delle corrispondenti aree territoriali (in teoria un array con un solo elemento)
    def self.at_di_as(as)
      reg = AREE_SISTEMA.fetch(as)[:regioni]
      reg.map { |r| REGIONI[r][:at] }.uniq
    end

    # data un'area_sistema torna l'array delle corrispondenti noa (in teoria un array con un solo elemento)
    def self.noa_di_as(as)
      at_di_as(as).map { |at| AREE_TERRITORIALI[at][:noa] }.compact.uniq
    end

    def self.info_regione(regione)
      REGIONI[regione] || {}
    end

    def self.confinanti_di_regione(regione)
      (REGIONI[regione] || {})[:regioni_confinanti] || []
    end

    def self.tutte_le_regioni
      REGIONI.keys
    end

    def self.provincia_da_nome_cella(nome_cella)
      return nil if nome_cella.nil? || nome_cella.size < 2 || !tutte_le_province.include?(prov = nome_cella[0..1])
      prov
    end

    def self.regione_da_nome_cella(nome_cella)
      prov = provincia_da_nome_cella(nome_cella.upcase)
      return nil unless prov && (reg = PROVINCE[prov])
      reg[:regione]
    end
  end
end

# esempi di uso
# Irma::AnagraficaTerritoriale.province_per_as('AS1')
# Irma::Constant.info(:sistema, 'AS1', :area_sistema)[:province]
# Irma::Constant.constants(:sistema, :area_sistema)
