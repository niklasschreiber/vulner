# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160126
#

module Irma
  #
  module Web
    #
    class App < Roda
      # rubocop:disable Metrics/AbcSize
      def decifratura_user_password(r)
        plain = {}
        [:username, :password].each do |k|
          decipher = OpenSSL::Cipher::AES.new(128, :OFB)
          decipher.decrypt
          decipher.padding = 0
          decipher.key = session[:key]
          decipher.iv  = session[:iv]
          plain[k] = decipher.update(JSON.parse(r.params[k.to_s]).pack('C*')) + decipher.final
        end
        plain
      end

      def request_host(r)
        r.env['HTTP_X_FORWARDED_FOR'] ? r.env['HTTP_X_FORWARDED_FOR'].split(',')[0].strip : r.ip
      end

      def verifica_autenticazione(r)
        res = {}
        plain = {}
        begin
          plain = decifratura_user_password(r)
          auth_res = Db::Account.autenticazione(matricola: plain[:username], password: plain[:password], profilo: r['profilo'], request_host: request_host(r),
                                                session: Db::Sessione.new(session_id: session['session_id']))
          res = { esito: auth_res.ok?, messaggio: auth_res.msg }
          session[:next_renew] = Time.now + 60
        rescue => e
          res[:esito] = false
          res = { messaggio: "Eccezione: #{e}" }
          Irma.logger.warn("Autenticazione fallita per la matricola #{plain[:username]} per eccezione: #{e}, backtrace: #{e.backtrace}")
        end
        res[:codice] = res[:esito] ? 0 : 1
        res
      end
      # rubocop:enable all
    end

    App.route('authenticate') do |r|
      r.get('controllo_sessione') do
        begin
          s = logged_in
          if s && s.exists? && !s.expired?
            renew_session if r.params['renew'] == 'true'
            begin
              Redis.current.get('dummy')
              STATO_SESSIONE_OK
            rescue => _e
              response.status = 599
              format_msg(:REDIS_SERVER_NON_ATTIVO)
            end
          else
            (s && s.expired?) ? STATO_SESSIONE_SCADUTA : STATO_SESSIONE_NON_VALIDA
          end
        rescue Sequel::DatabaseConnectionError, Sequel::DatabaseDisconnectError => e
          response.status = HTTP_CODE_CUSTOM_SESSION_ERROR
          Irma.logger.error("Problemi nella verifica della sessione: #{e}, #{e.backtrace}")
          format_msg(:DB_CONNECTION_ERROR)
        end
      end
      r.post('cambio_profilo') do
        s = logged_in
        if s && !s.expired?
          s.logout(note: format_msg(:SESSIONE_CHIUSA_PER_RICHIESTA_ACCESSO_CON_ALTRO_PROFILO, nuovo_profilo: r['profilo']))
          res = verifica_autenticazione(r)
        else
          res = { esito: false, codice: 1, messaggio: format_msg(:SESSIONE_NON_VALIDA) }
        end
        res
      end
      r.post do
        verifica_autenticazione(r)
      end
    end
  end
end
