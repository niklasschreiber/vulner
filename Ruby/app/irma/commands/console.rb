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
    method_option :env,         aliases: '-e', type: :string, banner: 'Environment', default: Irma::Db.env, enum: %w(production development test)
    method_option :execute,     aliases: '-x', type: :string, banner: 'Command to be executed', default: ''
    method_option :init_db,                    type: :boolean, banner: 'Inizialize db', default: true
    method_option :exit,                       type: :boolean, banner: 'Exit immediately after initialization', default: false, hide: true
    common_options 'console', 'Attiva la console interattiva'
    def console # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
      if options[:execute].to_s.empty?
        require 'irb'
        require 'irb/completion'
        msg = ('*' * 10) + " IRMA CONSOLE (#{Db.env}, #{Db.conn_url_no_pwd}) " + (options[:init_db] ? '' : ' DB NON INIZIALIZZATO ') + ('*' * 10)
        logger.info(msg)
        puts(msg)
        ModConfig.check_for_db_updates if options[:init_db]
        ARGV.clear
        IRB.setup(nil) unless IRB.conf[:IRB_NAME] == 'irb'
        irb = IRB::Irb.new(IRB::WorkSpace.new)
        IRB.conf[:MAIN_CONTEXT] = irb.context
        if options[:exit]
          # IRB.conf[:PROMPT] = :NULL
          msg = 'Autoexiting!'
          logger.info(msg)
          puts(msg)
        else
          catch(:IRB_EXIT) { irb.eval_input }
        end
      else
        _execute_console_command(options[:execute])
      end
      {}
    end

    private

    def pre_console
      self.creazione_eventi = false
      Db.init(env: options[:env], logger: logger, sql_log: true) if options[:init_db]
    end

    def _execute_console_command(cmd_string)
      # override default logger to use the console command logger
      Kernel.const_set('DEFAULT_LOGGER', logger)
      ARGV.clear
      split_char = cmd_string[0]
      command_pieces = cmd_string.split(split_char)
      cmd = command_pieces[1]
      command_pieces[2..-1].each { |x| ARGV << x }
      cmd = "./#{cmd}" unless ['.', '/', '~'].include?(cmd[0])
      $0 = cmd
      load cmd
      {}
    end
  end
end
