# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20170831
#
# ATTENZIONE: non indentare automaticamente !!!!
#

#
module Irma
  Constant.define(:evento, GRAVITA_EVENTO = {
    debug:   { value: 0, descr: 'Debug',        color: { bg: '#FFFFFF', fg: '#000000' } },
    info:    { value: 1, descr: 'Informazione', color: { bg: '#00DD00', fg: '#000000' } },
    warning: { value: 2, descr: 'Warning',      color: { bg: '#FFFF00', fg: '#000000' } },
    error:   { value: 3, descr: 'Errore',       color: { bg: '#FF0000', fg: '#000000' } }
  }.freeze, :gravita)

  Constant.define(:tipo_evento, GRAVITA_EVENTO, :gravita)

  #
  # Tipi Eventi
  #
  te = {}
  class <<te
    def _add(id, k, opts = {})
      options = { frequenza: 0 }.merge(opts.dup)
      m = k.to_s.upcase.match(/([^_]+)_(.*)$/)
      info = { value: id, categoria: m[1], nome: m[2].tr('_', ' '), gravita: TIPO_EVENTO_GRAVITA_INFO }.merge(options)
      info[:nome_completo] = "#{info[:categoria]}:#{info[:nome]}".tr(' ', '_')
      self[k] = info
    end

    def info(id, k, opts = {})
      _add(id, k, opts.merge(gravita: TIPO_EVENTO_GRAVITA_INFO))
    end

    def warning(id, k, opts = {})
      _add(id, k, opts.merge(gravita: TIPO_EVENTO_GRAVITA_WARNING))
    end

    def error(id, k, opts = {})
      _add(id, k, opts.merge(gravita: TIPO_EVENTO_GRAVITA_ERROR))
    end
  end

  te.info     1, :creazione_record,                            categoria: 'CREAZIONE', nome: '', descr: "Segnala la creazione di un nuovo record per l'entità indicata nel campo nome"
  te.info     2, :aggiornamento_record,                        categoria: 'AGGIORNAMENTO', nome: '', descr: "Segnala l'aggiornamento del record per l'entità indicata nel campo nome"
  te.info     3, :eliminazione_record,                         categoria: 'ELIMINAZIONE',  nome: '', descr: "Segnala l'eliminazione del record per l'entità indicata nel campo nome"
  te.info     4, :inizio_esecuzione_comando,                   categoria: 'INIZIO_ESECUZIONE_COMANDO', nome: '', descr: "Segnala l'inizio dell'esecuzione del comando indicato nel campo nome"
  te.info     5, :fine_esecuzione_comando,                     categoria: 'FINE_ESECUZIONE_COMANDO', nome: '', descr: "Segnala la fine dell'esecuzione del comando indicato nel campo nome"
  te.warning  6, :fallimento_esecuzione_comando,               categoria: 'FALLIMENTO_ESECUZIONE_COMANDO', nome: '', descr: "Segnala il fallimento dell'esecuzione del comando indicato nel campo nome"
  te.info     7, :autenticazione_corretta,                     descr: 'Segnala che un utente si e\' autenticato correttamente'
  te.warning  8, :autenticazione_fallita,                      descr: "Segnala che un utente ha fallito l'autenticazione"
  te.info     9, :lock_acquisito,                              descr: "Segnala che un lock e\' stato acquisito correttamente"
  te.info    10, :lock_rilasciato,                             descr: "Segnala che un lock e\' stato rilasciato"
  te.error   11, :aasm_invalid_transition,                     descr: 'Richiesta una transizione non consentita per macchina a stati'
  te.warning 12, :attivita_schedulata_non_eseguibile,          categoria: 'ATTIVITA_SCHEDULATA', nome: 'NON_ESEGUIBILE', descr: "Impossibile eseguire attivita' schedulata"
  te.warning 13, :attivita_schedulata_gerarchia_errata,        categoria: 'ATTIVITA_SCHEDULATA', nome: 'GERARCHIA_ERRATA', descr: "Impossibile creare gerarchia attivita'"
  te.warning 14, :attivita_opzioni_non_supportate_dal_comando, categoria: 'ATTIVITA', nome: 'OPZIONI_NON_SUPPORTATE_DAL_COMANDO', descr: "Il comando dell'attività contiene opzioni non supportate"
  Constant.define(:tipo_evento, TIPI_EVENTO = te.freeze)
end
