# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170501
#

module Irma
  #
  module Web
    #
    class App < Roda
    end

    App.route('funzioni') do |r|
      r.get('list') do
        handle_request do
          filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
          records_funzioni(filtro: filtro).map { |f| { id: f[:value], nome: f[:nome] } }.sort_by { |h| h[:nome] }
        end
      end
    end
  end
end
