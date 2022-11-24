# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160217
#

require 'irma/db'

module Irma
  #
  class Command < Thor
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Irma::Db.env, enum: %w(production development test)
    common_options 'cleanup_db', 'Rimuove record fuori retention in DB'
    def cleanup_db
      res = {}
      Db.model_classes.sort_by(&:to_s).each do |klass|
        res[klass.to_s.split('::').last.to_s] = klass.cleanup
      end
      res.delete_if { |_k, v| (v || {}).empty? }
    end

    private

    def pre_cleanup_db
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
