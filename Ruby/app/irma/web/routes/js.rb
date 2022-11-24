# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160214
#
module Irma
  #
  module Web
    App.route('js') do |r|
      common_dir = File.join(opts[:root], 'common')
      r.get 'aes_info.js' do
        response.expires 1, public: true, no_cache: true
        aes_info = { key: session[:key].bytes, iv: session[:iv].bytes }.to_json
        ERB.new(File.read(File.join(common_dir, 'aes_info.js.erb'))).result(binding)
      end
      r.get 'runtime.js' do
        response.expires 1, public: true, no_cache: true
        sess = logged_in
        if sess
          "Irma.runtime = #{sess.runtime.to_json};"
        else
          "document.location='/login';"
        end
      end
      r.get 'common.js' do
        response.expires 1, public: true, no_cache: true
        ERB.new(File.read(File.join(common_dir, 'common.js.erb'))).result(binding)
      end
    end
  end
end
