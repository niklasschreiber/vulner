# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151124
#
require 'socket'
require 'ipaddr'
require 'timeout'

#
module Irma
  class InvalidFQDN < IrmaException; end

  include ModConfigEnable

  config.define VERSIONE = :versione, '',
                ambito:        APP_CONFIG_AMBITO_GUI_NON_MODIFICABILE,
                descr:         "Versione dell'applicazione"

  config.define BUILD_ID = :build_id, '',
                ambito:        APP_CONFIG_AMBITO_GUI_NON_MODIFICABILE,
                descr:         "Identificativo del build dell'applicazione"

  config.define ULTIMO_AGGIORNAMENTO = :ultimo_aggiornamento, '',
                ambito:        APP_CONFIG_AMBITO_GUI_NON_MODIFICABILE,
                descr:         "Data dell'ultimo aggiornamento applicativo"

  # Title for GUI
  config.define TITOLO = :titolo, 'Irma', descr: 'Titolo della GUI'

  # Url for GUI
  config.define URL = :url, 'https://irma.telecomitalia.local', descr: 'Url per la GUI'

  # Url for db irma1
  config.define DBURL_IRMA1 = :dburl_irma1, 'jdbc:oracle:thin:SO002706/fra123_@113.212.36.76:1523:irma10',
                descr: 'Url per connessione database esercizio irma1'

  # Default date format string
  config.define GUI_DEFAULT_DATE_FORMAT = :gui_default_date_format, '%Y/%m/%d %H:%M:%S',
                descr:         'Formato della data di default nella gui',
                widget_info:   'Gui.widget.guiDefaultDateFormat()'

  config.define PRECISIONE_DURATA = :precisione_durata, 1,
                descr:         'Numero di decimali da considerare nella registrazione della durata delle esecuzioni',
                widget_info:   'Gui.widget.positiveInteger({minValue:0, maxValue:3})'

  def self.hostname
    Socket.gethostname
  end

  def self.local_ip
    @local_ip ||= IPSocket.getaddress(hostname)
  end

  # Return the IP adress of the request socket or hostName +h+ passed
  def self.host_ip(h = nil)
    h ? IPSocket.getaddress(h) : local_ip
  end

  def self.format_date(data, formato_data = nil)
    data.to_s.empty? ? '' : data.strftime(formato_data || config[GUI_DEFAULT_DATE_FORMAT])
  end

  def self.esegui_e_memorizza_durata(*args, **opts, &_block) # rubocop:disable Metrics/AbcSize
    res = { durata: nil, result: nil }
    start_time = Time.now
    (opts[:logger] || logger).info("#{opts[:log_prefix]}, inizio operazione")
    res[:result] = yield(*args)
    res[:durata] = (Time.now - start_time).round(opts[:precisione] || config[PRECISIONE_DURATA])
    (opts[:logger] || logger).info("#{opts[:log_prefix]}, operazione completata (#{res})")
    res
  rescue => e
    (opts[:logger] || logger).error("#{opts[:log_prefix]}, operazione terminata con eccezione (#{e}), backtrace: #{e.backtrace}")
    raise
  end

  def self.con_dbirma1(url: nil, enable: true, &_block) # rubocop:disable Metrics/AbcSize
    db_irma1 = nil
    if enable
      url_x = url || config[DBURL_IRMA1]
      begin
        logger.info("Trying connection for db IRMA1 (#{url_x})...")
        db_irma1 = Sequel.connect(url_x, fetch_size: 1_000)
        db_irma1.loggers << logger
        logger.info("Connection with db IRMA1 (#{url_x}) established")
      rescue => e
        logger.error("Connessione a db_irma1 (url: #{url_x}) fallita con eccezione (#{e}), backtrace: #{e.backtrace}")
        # raise
      end
    end
    yield db_irma1
  ensure
    db_irma1.disconnect if db_irma1
  end
end
