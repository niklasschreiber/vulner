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
      def list_names_with_all
        all = [{ id: format_msg(:STORE_TUTTI_I_PROFILI), descr: format_msg(:STORE_TUTTI_I_PROFILI) }]
        profili = Constant.constants(:profilo).map { |c| { id: c.info[:nome], descr: c.label } }.sort_by { |x| x[:descr] }
        all << profili
        all.flatten
      end

      App.route('profili') do |r|
        r.get('accessibili_da_gui/list') do
          handle_request { Constant.constants(:profilo).select { |c| c.info[:assegnabile_da_gui] }.map { |c| { id: c.value, descr: c.label } }.sort_by { |x| x[:descr] } }
        end
        r.get('value_names_with_all/list') do
          handle_request { list_names_with_all }
        end
      end
    end
  end
end
