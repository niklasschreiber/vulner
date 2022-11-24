# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli, P. Cortona
#
# Creation date: 20170418
#

module Irma
  module Web
    module Common
      class WebServiceResponse
        attr_reader :request, :response, :sessione, :logger, :options

        def initialize(request:, response:, logger:, **options)
          @request = request
          @response = response
          @logger = logger
          @options = options
          @sessione = options[:sessione]
        end

        def path
          request.path
        end

        def process
          raise "#process not implemented for class #{self.class}"
        end

        def sessione_valida?
          options[:verifica_sessione] ? (sessione && !sessione_scaduta?) : true
        end

        def sessione_scaduta?
          (sessione && sessione.expired?) ? true : false
        end

        module DataResponse
          def process
            request.halt([HTTP_CODE_NOT_FOUND, { 'Content-Type' => 'text/html' }, [sessione_scaduta? ? STATO_SESSIONE_SCADUTA : STATO_SESSIONE_NON_VALIDA]]) unless sessione_valida?
            yield(self)
          end
        end

        class List < self
          include DataResponse

          def process(&block)
            res = super(&block)
            raise "Tipo risultato #{res.class} non corretto per il list path #{path} (tipo ammesso Array di Hash)" unless res.is_a?(Array) && (res.empty? || res.first.is_a?(Hash))
            res
          end
        end

        class Tag < self # nessuna differenza al momento con la classe List, serve solo per rendere gli url piu espliciti
          include DataResponse

          def process(&block)
            res = super(&block)
            raise "Tipo risultato #{res.class} non corretto per il list path #{path} (tipo ammesso Array di Hash)" unless res.is_a?(Array) && (res.empty? || res.first.is_a?(Hash))
            res
          end
        end

        class Grid < self
          include DataResponse

          def process(&block) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            res = super(&block)
            if res.is_a?(Array) && (res.empty? || res.first.is_a?(Hash))
              { total: res.count, data: res }
            elsif res.is_a?(Hash) && (res[:data] || res['data'])
              res
            else
              raise "Tipo risultato #{res.class} non corretto per il grid path #{path} (tipi ammessi Array di Hash o Hash con campo data)"
            end
          end
        end

        class Json < self
          include DataResponse

          def process(&block)
            res = super(&block)
            raise "Tipo risultato #{res.class} non corretto per il json path #{path} (tipo ammesso Hash)" unless res.is_a?(Hash)
            res
          end
        end

        class Export < self
          def process
            if sessione_valida?
              yield(self)
            else
              sessione_scaduta? ? STATO_SESSIONE_SCADUTA : STATO_SESSIONE_NON_VALIDA
            end
          rescue => e
            logger.warn("#{self.class}: errore in esecuzione azione per il path #{path} con i parametri #{request.params}: #{e}, backtrace: #{e.backtrace}")
            e.to_s
          end
        end

        class Tree < self
          include DataResponse

          def process(&block)
            res = super(&block)
            ok = res[:children] || res['children'] || res[:error] || res['error']
            raise "Tipo risultato #{res.class} non corretto per il tree path #{path} (tipo ammesso Hash con campo children oppure error)" unless ok
            res
          end
        end

        class Action < self
          def process # rubocop:disable Metrics/AbcSize
            if sessione_valida?
              res = yield(self)
              res = { messaggio: res.to_s } unless res.is_a?(Hash)
              { success: true }.merge(res)
            else
              { success: false, messaggio: sessione_scaduta? ? STATO_SESSIONE_SCADUTA : STATO_SESSIONE_NON_VALIDA }
            end
          rescue => e
            logger.warn("#{self.class}: errore in esecuzione azione per il path #{path} con i parametri #{request.params}: #{e}, backtrace: #{e.backtrace}")
            { success: false, messaggio: format_msg(options[:error_msg_key] || :ERRORE_IN_ESECUZIONE_AZIONE, errore: e.to_s) }
          ensure
            response['Content-Type'] = 'text/html'
          end
        end

        AVAILABLE_RESPONSE_CLASSES = descendants.each_with_object({}) do |v, res|
          res[v.to_s.split(':').last.underscore] = v
        end.freeze
      end

      #
      def handle_request(opts = {}, &block) # rubocop:disable Metrics/AbcSize
        options = { verifica_sessione: true, rinnova_sessione: true }.merge(opts)
        options[:sessione] = (@sess = logged_in)

        last_path = request.path.split('/').last
        klass = last_path.split('-')[1]

        response_class = klass ? self.class.class_eval("WebServiceResponse::#{klass}".camelize) : WebServiceResponse::AVAILABLE_RESPONSE_CLASSES.fetch(last_path, WebServiceResponse::Action)
        # logger.info("Processing url #{request.path} with class #{response_class}")
        response_class.new(request: request, response: response, logger: logger, **options).process(&block)
      rescue Sequel::DatabaseConnectionError, Sequel::DatabaseDisconnectError => e
        Irma.logger.error("Problemi di connessione con il DB: #{e}")
        response.status = HTTP_CODE_CUSTOM_SESSION_ERROR
        format_msg(:DB_CONNECTION_ERROR)
      ensure
        renew_session if options[:rinnova_sessione] && response.status != HTTP_CODE_CUSTOM_SESSION_ERROR
      end

      #
      def schedula_attivita
        handle_request(error_msg_key: :SCHEDULAZIONE_ATTIVITA_FALLITA) do |wsr|
          yield(wsr.request.params,
                account_id:              wsr.sessione.account_id,
                ambiente:                wsr.sessione.ambiente,
                archivio:                wsr.request.params['archivio'],
                attivita_schedulata_id:  att_sched_id = Db::AttivitaSchedulata.next_id,
                attivita_schedulata_dir: Irma.shared_relative_attivita_dir(att_sched_id))
          format_msg(:SCHEDULAZIONE_ATTIVITA_ESEGUITA)
        end
      end
    end
  end
end
