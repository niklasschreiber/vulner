# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20170831
#
# ATTENZIONE: non indentare automaticamente !!!!
#

# rubocop:disable Style/IndentHash
module Irma
  Constant.define(:allarme, GRAVITA_ALLARME = {
    warning:  { value: 1, color: { bg: '#00FFFF', fg: '#000000' } },
    minor:    { value: 2, color: { bg: '#FFFF00', fg: '#000000' } },
    major:    { value: 3, color: { bg: '#FFA000', fg: '#000000' } },
    critical: { value: 4, color: { bg: '#FF0000', fg: '#000000' } }
  }.freeze, :gravita)

  Constant.define(:allarme, { no: 0, si: 1 }, :aperto)

  Constant.define(:allarme, { no: 0, si: 1 }, :in_carico)

  Constant.define(:tipo_allarme, GRAVITA_ALLARME, :gravita)

  # combinazione a bit
  Constant.define(:tipo_allarme, {
    nessuna: 0,
    email:   1,
    sms:     2
  }, :notifica)

  #
  # Tipi Allarmi
  #
  ta = {}
  class <<ta
    def _add(id, k, opts = {})
      opts = { formato_id_risorsa: '#{ctx[:apparato]}:#{ctx[:porta]}', chiusura_automatica: 0 }.merge(opts.dup)
      m = k.to_s.upcase.match(/([^_]+)_(.*)$/)
      info = { value: id, categoria: m[1], nome: m[2].tr('_', ' '), gravita: TIPO_ALLARME_GRAVITA_WARNING }.merge(opts)
      info[:nome_completo] = "#{info[:categoria]}:#{info[:nome]}".tr(' ', '_')
      self[k] = info
    end

    def warning(id, k, opts = {})
      _add(id, k, opts.merge(gravita: TIPO_ALLARME_GRAVITA_WARNING))
    end

    def minor(id, k, opts = {})
      _add(id, k, opts.merge(gravita: TIPO_ALLARME_GRAVITA_MINOR))
    end

    def major(id, k, opts = {})
      _add(id, k, opts.merge(gravita: TIPO_ALLARME_GRAVITA_MAJOR))
    end

    def critical(id, k, opts = {})
      _add(id, k, opts.merge(gravita: TIPO_ALLARME_GRAVITA_CRITICAL))
    end
  end

  chiusura_automatica_dopo_un_giorno = 86_400 # secondi
  ta.critical  1, :mail_server_non_disponibile, formato_id_risorsa: 'smtp_server', chiusura_automatica: chiusura_automatica_dopo_un_giorno
  ta.critical  2, :ldap_server_non_disponibile, formato_id_risorsa: 'ldap_server', chiusura_automatica: chiusura_automatica_dopo_un_giorno
  ta.minor     3, :utente_sospeso,              formato_id_risorsa: '#{ctx[:matricola]}'

  Constant.define(:tipo_allarme, TIPI_ALLARME = ta.freeze)
end
