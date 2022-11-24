# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180202
#

module Irma
  #
  module Web
    #
    class App < Roda
      def _get_date_format_and_icon(json)
        json['data_file'] = timestamp_to_string(Time.parse(json['data_file']))
        json['iconCls'] = json['leaf'] ? 'tree_browsing_file' : 'tree_browsing_directory_collassata'
        json['children'].each { |ch| _get_date_format_and_icon(ch) } unless json['children'].nil? || json['children'].empty?
      end

      def tree_root_file # rubocop:disable Metrics/AbcSize
        raise 'Nessuna directory specificata' unless request.params['dir']
        dir = shared_show_files(request.params['dir'])
        dir = JSON.parse(dir)
        _get_date_format_and_icon(dir)
        { success: true, descr: 'root', expanded: true, children: dir['leaf'] ? [dir] : dir['children'] }
      rescue => e
        { success: false, error: "Errore di show per il path '#{request.params['dir']}' sullo shared_fs server: #{e}" }
      end
    end

    App.route('browsing') do |r|
      r.get('root/tree') do
        handle_request { tree_root_file }
      end
    end
  end
end
