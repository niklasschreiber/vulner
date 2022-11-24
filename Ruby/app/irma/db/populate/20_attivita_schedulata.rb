# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151122
#
#
module Irma
  #
  module Db
    Irma::Constant.constants(:tipo_attivita).each do |ttaa|
      next unless ttaa.info[:singleton] && ttaa.info[:periodo]
      next if AttivitaSchedulata.where(tipo_attivita_id: ttaa.info[:value]).first # devo creare AttivitaSchedulata solo se non c'e'

      options = { attivita_schedulata_id: AttivitaSchedulata.next_id,
                  competenze:             { TIPO_COMPETENZA_ADMIN => COMPETENZA_TUTTO },
                  no_account:             true
                }.merge(ttaa.info)
      options.update(descr: ttaa.info[:archivio] ? (ttaa.info[:nome] + ' ' + ttaa.info[:archivio]).upcase : ttaa.info[:nome],
                     stato: ttaa.info[:stato_as] || ATTIVITA_SCHEDULATA_STATO_SOSPESA)
      TipoAttivita.crea_attivita_schedulata(ttaa.value, options)
    end
  end
end
