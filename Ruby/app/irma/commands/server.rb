# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151121
#

require 'irma/db'

#
module Irma
  #
  class Command < Thor
    method_option :env,                  aliases: '-e', type: :string,  banner: 'Environment', default: Irma::Db.env, enum: %w(production development test)
    method_option :port,                 aliases: '-p', type: :numeric, banner: 'Port', default: (ENV['AS_PORT'] || 8080).to_i
    method_option :root,                 aliases: '-r', type: :string,  banner: 'Root', default: ENV['IRMA_WEB_ROOT'] || File.join(ENV['IRMA_HOME'] || '', 'as')
    method_option :max_threads,          aliases: '-m', type: :numeric, banner: 'MaxThreads', default: (ENV['IRMA_SERVER_MAX_THREADS'] || 32).to_i
    method_option :force_shutdown_after, aliases: '-f', type: :numeric, banner: 'ForceShutdownAfter', default: (ENV['IRMA_SERVER_FORCE_SHUTDOWN_AFTER'] || 3).to_i
    method_option :max_exit_sleep,       aliases: '-s', type: :numeric, banner: 'MaxExitSleep', default: (ENV['IRMA_EXIT_SLEEP'] || '1').to_i
    method_option :id,                   aliases: '-i', type: :string,  banner: 'Name', default: ENV['AS_ID'] || Irma.hostname
    method_option :descr,                aliases: '-d', type: :string,  banner: 'Description', default: ENV['AS_DESCR']
    common_options 'server', 'Attiva il server web'
    def server
      ENV['IRMA_WEB_ROOT'] = options[:root]
      require 'irma/web/app'
      Web::App.start(options.merge(logger: logger))
    end

    private

    def pre_server
      if Irma.as?
        Db.init(env: options[:env], logger: logger)
      else
        Db.logger = logger
      end
    end
  end
end
