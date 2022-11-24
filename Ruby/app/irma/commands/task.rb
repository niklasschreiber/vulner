# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151210
#

require 'irma/db'

#
module Irma
  #
  class Command < Thor
    method_option :env,    aliases: '-e', type: :string, banner: 'Environment', default: Irma::Db.env, enum: %w(production development test)
    common_options 'task', 'Esegue il task specificato'
    def task(*args) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      old_argv = ARGV.dup
      require 'irma/tasks'
      # simulate -T rake command
      args[0] = '-T' if args.empty? || args[0] == '-h' || args[0] == '-help' || args[0] == '--help'
      # simulate -D rake command
      if args.length == 2 && args[1] == '-D'
        args[1] = args[0]
        args[0] = '-D'
      end
      ARGV.clear
      args.each { |x| ARGV << x }
      Rake.application.init(args.first)
      Rake.application.top_level
    ensure
      ARGV.clear
      old_argv.each { |x| ARGV << x }
    end

    private

    def pre_task
      self.creazione_eventi = false
      Db.init(env: options[:env], logger: logger, load_models: false)
    end
  end
end
