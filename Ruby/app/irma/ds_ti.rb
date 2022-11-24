# vim: set fileencoding=utf-8
#
# Singleton per l'interfacciamento con l'DS di TelecomItalia
#
# Author: G. Cristelli
#
# Creation Date: 20151123
#
require 'net/ldap'
require 'timeout'
require 'singleton'
require 'irma/common'

#
module Net
  #
  class LDAP
    def open_conn
      @open_connection = Connection.new(host: @host, port: @port, encryption: @encryption)
    end

    def close_conn
      @open_connection.close
      @open_connection = nil
    end

    # PATCH to avoid deprecation warning in version 0.12.0
    class ConnectionRefusedError < Error
      private

      def warn_deprecation_message
        # warn "Deprecation warning: Net::LDAP::ConnectionRefused will be deprecated. Use Errno::ECONNREFUSED instead."
      end
    end

    #
    class Entry
      alias initialize_without_original_attribute_names initialize

      def initialize(*args)
        @original_attribute_names = []
        initialize_without_original_attribute_names(*args)
      end

      alias aset_without_original_attribute_names :[]=

      def []=(name, value)
        @original_attribute_names << name
        aset_without_original_attribute_names(name, value)
      end

      def original_attribute_names
        @original_attribute_names.compact.uniq
      end

      def each_attribute
        attribute_names.sort_by(&:to_s).each do |name|
          yield name, self[name]
        end
      end
    end
  end
end

module Irma
  #
  # Questo singleton consente di accedere all'LDAP di TelecomItalia, con la possibilita'
  # di specificare i parametri di connessione
  #
  # == Attributi
  # * +host+ -- indirizzo host
  # * +ports+ -- port
  # * +name+ -- nome utente per bind
  # * +password+ -- password utente per per bind
  #--
  # I metodi di questo oggetto sono stati estratti dalla definizione successiva al fine
  # di generare la documentazione correttamente
  #
  class DsTi # rubocop:disable Metrics/ClassLength
    include Singleton
    include ModConfigEnable

    config.define HOST = :host,         '156.54.242.110',         descr: "Indirizzo dell'LDAP server"
    config.define PORT = :port,         636,                      descr: "Porta per l'LDAP server", widget_info: 'Gui.widget.ldapPorts()'
    config.define PROTOCOL = :protocol, 'ldaps',                  descr: 'Protocollo di comunicazione', widget_info: 'Gui.widget.ldapProtocol()'
    config.define BASE = :base,         'O=Telecom Italia Group', descr: 'Percorso di base per la ricerca delle matricole'
    config.define USER = :user,         'Anonymous',              descr: "Utente per l'accesso in lettura", widget_info: 'Gui.widget.string()'
    config.define PASSWORD = :password, '',                       descr: "Password per l'utente", widget_info: 'Gui.widget.string()'
    config.define ALLARMI = :allarmi,   0,                        descr: 'Generazione allarmi per problemi di connessione', widget_info: 'Gui.widget.booleanInteger()'
    config.define TIMEOUT = :timeout,   30,
                  descr:       'Timeout in secondi per considerare fallita la connessione al server',
                  widget_info: 'Gui.widget.positiveInteger({maxValue:864000})'
    config.define EXPIRE_CONN_TIMEOUT = :expire_conn_timeout, 60,
                  descr:       'Timeout in secondi per mantenere attiva la connessione stabilita',
                  widget_info: 'Gui.widget.positiveInteger({maxValue:864000})'

    # Parametro non usato
    # config.define CREATE_EVENT_ON_EVERY_CONNECTION_FAILURE=:create_event_on_every_connection_failure, 1,
    #   widget_info: => %q@Gui.widget.booleanInteger()@      # Intero positivo nel range [0..1] / utilizzato come boolean

    # classe di errore generica e superclasse di tutti gli errori generati da DsTi
    class DsTiError < StandardError; end

    # errore dovuto all'incorretto inserimento di parametri di connessione: host, port
    class ConnectionFailure < DsTiError; end

    # errore in autenticazione - password errata
    class AuthenticationFailure < DsTiError; end

    # errore dovuto all'errato passaggio della lista degli attributi ricercati nell'Ldap
    class InvalidAttributeList < DsTiError; end

    # errore record vuoto - nessun utente trovato nell'ldap
    class InvalidUid < DsTiError; end

    # password scaduta
    class PasswordExpired < DsTiError; end

    # timeout error
    class TimeoutError < DsTiError; end

    attr_accessor :mutex

    def logger
      Irma.logger
    end

    #
    def close_connection
      @conn.close_conn if @conn
    rescue
      # nothing to do
      @conn = nil
    ensure
      @conn = nil
    end

    def execute(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      h = { genera_allarmi: (config[ALLARMI] == 1), max_retries: 2 }.merge(opts)
      params = {}
      begin
        ip_address = config[HOST]
        retries = 0
        begin
          res = nil
          Timeout.timeout(config[TIMEOUT]) do
            mutex.synchronize do
              logger.debug("Connection nil?  #{@conn.nil?}, expired? #{(!@conn_expire_time.nil? && @conn_expire_time < Time.now)}")
              if @conn.nil? || (!@conn_expire_time.nil? && @conn_expire_time < Time.now)
                close_connection unless @conn.nil?
                params = { host: ip_address, port: config[PORT], auth: { method: :anonymous } }.merge(h)
                params[:encryption] = :simple_tls if config[PROTOCOL] == 'ldaps'
                logger.debug("Opening connection, retry #{retries}, parametri:\n#{params.inspect}")
                @conn = Net::LDAP.new(params)
                @conn.open_conn
                @conn_expire_time = Time.now + config[EXPIRE_CONN_TIMEOUT].to_i
              end
            end
            res = yield(@conn)
            if h[:genera_allarmi]
              Db::Allarme.valuta(TIPO_ALLARME_LDAP_SERVER_NON_DISPONIBILE, {}) { |_opzioni_allarme| false }
            end
            res
          end
        rescue AuthenticationFailure => e
          raise e
        rescue InvalidUid => e
          raise e
        rescue DsTiError => e
          logger.error("DsTi exception raised: #{e}")
          raise e
        rescue Timeout::Error => e
          msg = "timeout connessione (#{config[TIMEOUT]} sec) con indirizzo #{params[:host]} sulla porta #{params[:port]}"
          mutex.synchronize { close_connection }
          raise TimeoutError, msg
        rescue => e
          logger.debug("Unexpected exception, closing LDAP connection with DsTi connection (#{e.class}): #{e}")
          mutex.synchronize { close_connection }
          unless e.class == Net::LDAP::Error && e.to_s == 'no connection to server'
            retries += 1
            retry if retries < h[:max_retries]
          end
          raise e
        end
      rescue DsTiError => e
        raise e
      rescue => e
        logger.error("Connessione AD/AM fallita: #{e}\nParametri:\n#{params.inspect}")
        msg = "Connessione AD/AM fallita (#{ip_address}): #{e}".mask_password
        if h[:genera_allarmi]
          Db::Allarme.valuta(TIPO_ALLARME_LDAP_SERVER_NON_DISPONIBILE, {}) do |opzioni_allarme|
            opzioni_allarme[:descr] = msg
            true
          end
        end
        raise ConnectionFailure, msg
      end
    end

    # Get authentication for +uid+ and password +pass+. Search for the dn associated with +uid+
    # unless +uid+ begins with <code>uid=</code>
    #
    # == Exceptions
    # * +InvalidUid+
    # * +AuthenticationFailure+
    # * +ConnectionFailure+
    #
    # Return nil or the uid contained in the +dn+
    def uid_from_dn(dn)
      return nil unless dn
      match = dn.match(/^uid=([^,]+),.*/i)
      match.nil? ? nil : match[1].rstrip
    end

    # Authenticate the user with uid=+uid+ using password +pass+
    #
    # == Exceptions
    # - +InvalidUid+
    # - +AuthenticationFailure+
    # - +PasswordExpired+
    #
    def authenticate(uid, pass, h = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      logger.info("DsTi Authenticate on uid #{uid}")
      raise AuthenticationFailure if pass.empty?
      execute(h) do |conn|
        tig_pwd_expiration_date = nil
        dn = uid_from_dn(uid).nil? ? nil : uid
        if dn.nil?
          filter = Net::LDAP::Filter.eq('uid', uid)
          conn.search(base: config[BASE], filter: filter) do |entry|
            unless entry.nil?
              tig_pwd_expiration_date = entry.tigPwdExpirationDate[0]
              dn = entry.dn
            end
          end
        end

        raise InvalidUid, "uid=#{uid}" if dn.nil?
        conn.auth(dn, pass)
        raise AuthenticationFailure unless conn.bind

        if tig_pwd_expiration_date.nil?
          filter = Net::LDAP::Filter.eq('uid', uid_from_dn(dn))
          conn.search(base: config[BASE], filter: filter) do |entry|
            tig_pwd_expiration_date = entry.tigPwdExpirationDate[0] unless entry.nil?
          end
        end
        exp_date = Time.now
        exp_date = translate_expiration_date_from_ldap(tig_pwd_expiration_date.to_i) unless tig_pwd_expiration_date.nil?
        raise PasswordExpired if Time.now >= exp_date
        true
      end
    end

    # Return the hash of +attributes+ values retrieved from DS TI for user with the specified +uid+
    # +attributes+ can be a single value or an array
    #
    # == Exceptions
    # - +UserNotFound+
    # - +InvalidAttributeList+
    #
    def get_user_info(uid, attributes) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      raise InvalidUid, 'DS TelecomItalia: user null not valid' if uid.nil?
      execute do |conn|
        attributes = [attributes] unless attributes.is_a?(Array)
        logger.debug("Ldap search: uid=#{uid}, attributes = " + attributes.join(','))
        filter = Net::LDAP::Filter.eq('uid', uid)
        results = conn.search(base: config[BASE], filter: filter, attributes: attributes)
        raise InvalidUid, "DS TelecomItalia: user |#{uid}| not found" if (results == false) || results.empty?

        raise DsTiError, "DS TelecomItalia: more than one result found for user |#{uid}|" if results.length > 1
        res = { 'dn' => results[0].dn }
        attributes.each { |k| res[k] = results[0][k].is_a?(Array) ? results[0][k].first.to_s : results[0][k].to_s }
        res
      end
    end

    def translate_expiration_date_from_ldap(value)
      # Ensure the value is made only of digits
      raise InvalidExpirationDateFormat if !value =~ /\d+/

      # To convert it into seconds elapsed since midnight January 1
      # 1970, we'd have to divide it by 10000000 (ten millions), and
      # then subtract 11644473600 (number of seconds between
      # 1/1/1601 and 1/1/1970).
      v = (value / 10_000_000) - 11_644_473_600

      # The result is the usual number of seconds since Jan 1 1970.
      Time.gm(1970, 'jan', 1, 0, 0, 0) + v
    end
  end
end

# assign singleton
Ds_ti = Irma::DsTi.instance
Ds_ti.mutex = Mutex.new
