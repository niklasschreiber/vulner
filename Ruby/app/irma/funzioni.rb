# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160521
#

unless Irma.shared_fs? && !Irma.as?
  require_relative 'funzioni/import_costruttore'
  require_relative 'funzioni/export_formato_utente'
  require_relative 'funzioni/import_formato_utente'
  require_relative 'funzioni/import_progetto_radio'
  require_relative 'funzioni/report_comparativo'
  require_relative 'funzioni/calcolo_da_progetto_radio'
  require_relative 'funzioni/conteggio_alberature'
  require_relative 'funzioni/conteggio_alberature_ade'
  require_relative 'funzioni/export_report_comparativo'
  require_relative 'funzioni/adrn'
  require_relative 'funzioni/completa_enodeb'
  require_relative 'funzioni/nuovo_enodebid'
  require_relative 'funzioni/completa_cgi'
  require_relative 'funzioni/nuovo_cgi'
  require_relative 'funzioni/creazione_fdc'
  require_relative 'funzioni/aggiorna_adrn'
  require_relative 'funzioni/calcolo_pi_copia'
  require_relative 'funzioni/export_progetto_radio'
  require_relative 'funzioni/creazione_fdc_cna'
  require_relative 'funzioni/import_filtro_alberatura'
  require_relative 'funzioni/nuovo_gnodebid'
end
