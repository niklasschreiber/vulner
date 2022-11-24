# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20171119
#

require 'irma/db'

module Irma
  #
  class Command < Thor
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Irma::Db.env, enum: %w(production development test)
    common_options 'verifica_accounts', 'Controlla gli accounts applicativi'
    def verifica_accounts
      {
        controllo_utenti: Db::Account.controllo_utenti,
        sospensione_account_scaduti: Db::Account.sospensione_account_scaduti
      }
    end

    private

    def pre_verifica_accounts
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
