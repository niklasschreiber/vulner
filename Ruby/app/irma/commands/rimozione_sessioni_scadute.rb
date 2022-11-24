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
    common_options 'rimozione_sessioni_scadute', 'Rimuove le sessioni scadute'
    def rimozione_sessioni_scadute
      Db::Sessione.rimozione_sessioni_scadute
    end

    private

    def pre_rimozione_sessioni_scadute
      self.creazione_eventi = false
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
