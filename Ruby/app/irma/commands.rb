# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151008
#
require 'thor'
require 'pp'
require 'pathname'
require 'irma/common'
require 'irma/shared_fs'

#
module Irma
  # rubocop:disable Metrics/BlockNesting
  class Command < Thor # rubocop:disable Metrics/ClassLength
    include ModConfigEnable
    include SharedFs::Util

    attr_accessor :creazione_eventi # default = true

    class << self
      attr_accessor :logger
    end

    map %w(--version -v) => :version

    desc '--version, -v', 'print the version'
    def version
      puts "IRMA v. #{VERSION}"
    end

    def self.default_log_file(command)
      Irma.log_file_name("irma_#{command}.log")
    end

    def self.log_a_separator_line(c, len = 70)
      logger.info(c * len) if logger
    end

    def self.common_options(command, descr = nil)
      desc(command, descr) if descr
      # method_option :help,        aliases: '-h', type: :boolean, banner: 'Help'
      method_option :log_file,     type: :string,  banner: 'Path file di log', default: default_log_file(command)
      method_option :log_level,    type: :string,  banner: 'Livello di log',   default: 'info', enum: %w(info debug)
      method_option :attivita_id,  type: :numeric, banner: 'Identificativo attività associata al comando'
    end

    def self.process(args, config = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      cmd = nil
      eventi = true
      start_time = Time.now
      e = nil
      level = :info
      ev_opts = {}
      config[:shell] ||= Thor::Base.shell.new
      res = nil
      # special handling for -h or --help options
      if args.include?('-h') || args.include?('--help')
        meth = retrieve_command_name(args.dup)
        command = all_commands[normalize_command_name(meth)]
        command_help(config[:shell], command.name)
      else
        res = dispatch(nil, args.dup, nil, config) do |thor_instance|
          eventi = thor_instance.creazione_eventi = true
          self.logger = config[:logger] || Irma.open_logger(thor_instance.options[:log_file], Logger.class_eval((thor_instance.options[:log_level] || 'info').upcase))
          log_a_separator_line('=')
          logger.info("Inizio esecuzione comando con args #{args} (options: #{thor_instance.options})")
          ev_opts[:nome] = args.first
          meth = retrieve_command_name(args.dup)
          cmd = all_commands[normalize_command_name(meth)]
          pre_cmd = "pre_#{cmd.name}".to_sym
          thor_instance.send(pre_cmd) if private_instance_methods.include?(pre_cmd)
          eventi = thor_instance.creazione_eventi
          if eventi && defined?(Db::Evento) && defined?(Db::TipoEvento)
            begin
              # extract attivita_id from command arguments
              ev_opts[:attivita_id] = (idx = args.index('--attivita_id')) && args[idx + 1]
              # extract account info from command arguments
              if (idx = args.index('--account_id')) && (account = Db::Account.first(id: args[idx + 1].to_i))
                utente = account.utente
                ev_opts[:account_id]   = account.id
                ev_opts[:profilo]      = account.profilo.nome
                ev_opts[:matricola]    = utente.matricola
                ev_opts[:utente_descr] = utente.fullname
              end
            rescue => e_acc
              logger.warn("Ignorato errore nel recupero informazioni per l'account dai parametri #{args}: #{e_acc}")
            end
            ev = Db::Evento.crea(TIPO_EVENTO_INIZIO_ESECUZIONE_COMANDO, ev_opts.merge(descr: format_msg(:INIZIO_ESECUZIONE_COMANDO, parametri: args, opzioni: thor_instance.options)))
            ev_opts[:pid] = ev.pid
          end
        end
      end
      res
    rescue StandardError, java.lang.Throwable => e
      res = { eccezione: e.to_s, backtrace: e.backtrace }
      level = :error
      # HOOK per mostrare un messaggio migliore all'utente in caso di lock
      msg = if e.is_a?(LockAlreadyAcquired)
              begin
                m = e.to_s.match('\((.*)\)')
                if m
                  lock_info = JSON.parse(m[1])
                  "perchè l'attività con id #{lock_info['attivita_id']} ne blocca l'esecuzione: #{m[1]}"
                end
              rescue => e1
                parse_error = "Unexpected lock info parsing error for #{e}: #{e1}"
                logger ? logger.error(parse_error) : STDERR.puts(parse_error)
                "(#{e})"
              end
            else
              "(#{e})"
            end
      raise "Errore in esecuzione comando #{args[0]} #{msg}"
    rescue SystemExit => e
      res = { eccezione: e.to_s }
      level = :warn
    ensure
      res ||= {}
      unless res.is_a?(Hash)
        res = { bad_command_result: res, eccezione: "il ritorno '#{res}' ha classe #{res.class} diversa da Hash" }
        level = :error
      end
      ev_opts[:durata] = (Time.now - start_time).round(0)
      log_msg = "Esecuzione comando #{args[0]} completata res = #{res} (#{ev_opts[:durata]} sec.)"
      if logger
        logger.send(level, log_msg)
      else
        level == :error ? STDERR.puts(log_msg) : STDOUT.puts(log_msg)
      end
      if eventi && defined?(Db::Evento) && defined?(Db::TipoEvento)
        Db::Evento.crea(res[:eccezione] ? TIPO_EVENTO_FALLIMENTO_ESECUZIONE_COMANDO : TIPO_EVENTO_FINE_ESECUZIONE_COMANDO,
                        ev_opts.merge(dettaglio: res, descr: format_msg(e ? :FALLIMENTO_ESECUZIONE_COMANDO : :FINE_ESECUZIONE_COMANDO, parametri: args, errore: res[:eccezione])))
      end
      log_a_separator_line('_')
    end

    private

    def logger
      self.class.logger
    end

    def pre_version
      self.creazione_eventi = false
    end

    def out_msg(msg, start_time = nil)
      elapsed = start_time ? "in #{(Time.now - start_time).round(1)} secondi " : ''
      puts "\n[#{Time.now}]: #{msg} #{elapsed}"
    end

    def cleanup_temp_files
      FileUtils.rm_rf(@unzip_dir) if @unzip_dir
      FileUtils.rm_f(@input_file) if @input_file && Irma.tmp_path?(@input_file)
    end
  end
end

cmds = %w(server)
unless Irma.shared_fs? && !Irma.as?
  cmds += %w(common_commands_methods
             console task import_costruttore crea_account
             export_formato_utente export_filtro_formato_utente
             import_formato_utente import_filtro_formato_utente
             import_filtro_alberatura conteggio_alberature
             conteggio_alberature_ade
             pi_import_formato_utente pi_export_formato_utente
             rimozione_sessioni_scadute cleanup_db verifica_accounts
             creazione_fdc
             aggiorna_adrn
             aggiorna_adrn_da_file export_adrn_su_file
             aggiorna_metamodello_fisico ricerca_incongruenze_metamodello
             export_adrn_irma1 export_adrn import_adrn elimina_celle_da_prn
             import_progetto_radio report_comparativo completa_enodeb nuovo_enodebid import_enodeb
             calcolo_da_progetto_radio export_report_comparativo
             calcolo_pi_copia export_progetto_radio consistency_check export_db
             import_metaparametri_update_on_create
             nuovo_cgi completa_cgi cancellazione_eccezioni_per_etichetta
             import_metaparametri_secondari nuovo_gnodebid)
end
cmds.each do |f|
  require_relative "commands/#{f}"
end
