# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170423
#

module Irma
  #
  module Web
    #
    class App < Roda
      App.route('vendors') do |r|
        r.get('competenza/list') do
          handle_request { records_competenza(r, :vendors) }
        end
        r.get('list') do
          handle_request do
            if request.params['filtro']
              filtro = JSON.parse(request.params['filtro'] || '{}')
              Irma.vendors_per_rete(filtro['rete_id'].to_i).map { |r_id| { id: r_id, descr: Constant.label(:vendor, r_id) } }
            else
              list_values_for_constants(scope: :vendor)
            end
          end
        end
      end
    end
  end
end
