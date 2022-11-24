# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160424
#

if Irma.sse?
  require 'json'
  module Irma
    #
    module Web
      #
      class SSE
        def initialize(io)
          @io = io
        end

        def write(object, options = {})
          options.each do |k, v|
            @io.write "#{k}: #{v}\n"
          end
          @io.write "data: #{object}\n\n"
        end

        def close
          @io.close
        end
      end

      # rubocop:disable Lint/HandleExceptions
      App.route('sse') do |r|
        r.on do
          # SSE expects the `text/event-stream` content type
          response.headers['Content-Type'] = 'text/event-stream'
          response.expires 1, public: true, no_cache: true

          stream do |out|
            sse = SSE.new(out)
            begin
              Irma.subscribe(PUB_ATTIVITA, blocking: true) do |channel, message|
                sse.write(message, event: channel)
              end
            rescue IOError, Puma::ThreadPool::ForceShutdown
              # When the client disconnects, we'll get an IOError on write
            ensure
              sse.close
            end
          end
        end
      end
    end
  end
end
