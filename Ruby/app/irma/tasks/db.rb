# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151122
#

require 'rake'
require 'terminal-table'

#
module Irma
  #
  module Task
    def self.db_for_current_env
      require 'irma/db'
      require 'irma/db/migrations'
      conn = Irma::Db.init(force: true, load_cache: false, load_models: false).connection
      conn.extension :schema_dumper
      conn
    end

    def self.force_or_different_version(ignore_manifest_error: false)
      unless (ret = ENV['FORCE'] == '1')
        Irma::Db.load_models
        Irma.config.load_from_db
        ret = Irma.config[Irma::VERSIONE] != manifest_info(ignore_error: ignore_manifest_error)[Irma::VERSIONE]
      end
      ret
    end

    def self.manifest_info(ignore_error: false) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      begin
        lines = File.readlines(Irma.get_env('MANIFEST') || File.join(Irma.get_env('HOME'), 'Manifest.txt'))
      rescue
        return { Irma::VERSIONE => Irma::VERSION } if ignore_error
        STDERR.puts(Irma.get_env('HOME') ? 'Manifest.txt non trovato' : "#{ENV_VAR_PREFIX}_HOME non definita")
        exit 1
      end
      m1 = lines[0].match("Version: (.*)\n")
      m2 = lines[1].match('Build info: ([0-9]+), (.*)')
      {
        Irma::VERSIONE             => m1 && m1[1],
        Irma::BUILD_ID             => m2 && m2[1],
        Irma::ULTIMO_AGGIORNAMENTO => m2 && m2[2].split('(').first
      }
    end
  end
end

namespace :db do
  task :environment do
    Irma::Task.db_for_current_env
  end

  task :minimal_environment do
    require 'irma/db'
    require 'irma/db/migrations'
  end

  namespace :lock do
    desc 'Mostra tutti i lock per il db (LOCK_PATTERN="*")'
    task :show do
      lock_key_pattern = Irma::LOCK_KEY_PREFIX + (ENV['LOCK_PATTERN'] || '*')
      lock_keys = Redis.current.keys(lock_key_pattern)
      if lock_keys.empty?
        puts "Nessun lock con pattern '#{lock_key_pattern}'."
      else
        puts "Trovati #{lock_keys.size} lock con pattern '#{lock_key_pattern}':"
        lock_keys.each do |lock_key|
          puts format('%40s: %s', lock_key, Redis.current.get(lock_key))
        end
      end
      lock_keys
    end

    desc 'Rimuove tutti i lock per il db (LOCK_PATTERN="*")'
    task :remove do
      lock_key_pattern = Irma::LOCK_KEY_PREFIX + (ENV['LOCK_PATTERN'] || '*')
      lock_keys = Redis.current.keys(lock_key_pattern)
      if lock_keys.empty?
        puts "Nessun lock da rimuovere con pattern '#{lock_key_pattern}'."
      else
        Redis.current.del(lock_keys)
        puts "Rimossi #{lock_keys.size} lock con pattern '#{lock_key_pattern}': #{lock_keys}"
      end
      lock_keys
    end
  end

  desc 'Mostra/modifica la versione del sistema presente nel file Manifest.txt e memorizzata nei parametri del db (opzioni AGGIORNA=false)'
  task versione_sistema: :environment do
    aggiorna = %w(1 true).include?(ENV['AGGIORNA'] || 'false')
    if Irma::Task.force_or_different_version(ignore_manifest_error: !aggiorna)
      if aggiorna
        Irma::Db.load_models
        Irma.config.load_from_db
        Irma::Task.manifest_info.each { |k, v| Irma.config.set_value(k, v) if v }
      end
    else
      Irma::Db.load_models
    end
    Irma.config.load_from_db
    puts "#{Irma.config[Irma::VERSIONE]} (build id=#{Irma.config[Irma::BUILD_ID]}, ultimo aggiornamento=#{Irma.config[Irma::ULTIMO_AGGIORNAMENTO]})"
  end

  desc 'Popola il db con i dati di base'
  task populate: :environment do
    if Irma::Task.force_or_different_version(ignore_manifest_error: true)
      task_names = Rake::Task.tasks.select { |t| t.to_s.match(/:populate:\d+_/) }.map(&:to_s)
      task_names.sort.each do |t|
        Rake::Task[t].invoke
      end
    else
      puts "Versione del sistema già aggiornata (#{Irma.config[Irma::VERSIONE]}), per forzare il popolamento dati specificare l'opzione FORCE=1"
    end
  end

  namespace :populate do
    task common: :environment do
      Irma::Db.load_models
    end

    Irma::Db::DB_MODELS.sort.each do |f|
      scope = f.to_sym
      next unless Irma::Constant.exists?(scope)

      desc "Popolamento #{scope}"
      task scope => :common do
        klass = Irma::Db.class_eval(scope.to_s.camelize)
        output_msg("Popolamento tabella #{klass.table_name} in corso .", new_line: false)
        Irma::Db.connection.transaction do
          klass.constant_populate
        end
        output_msg(". OK (#{klass.count} records)", prefix: false)
      end
    end

    Dir[File.join(Irma::Db::POPULATE_DIR, '*.rb')].sort.each do |f|
      task_name = File.split(f)[-1].gsub(/.rb$/, '')
      table_name = (task_name =~ /constant|upgrade/) ? nil : task_name.match(/\d+_(.*)/)[1]
      if table_name
        # desc "Popolamento #{table_name.gsub('_',' ')}"
        task table_name => task_name
      else
        # desc "Popolamento modelli predefiniti con costanti"
        task task_name.split('_')[-1] => task_name
      end

      # hidden task if table_name is defined
      task task_name => :common do
        if table_name
          klass = Irma::Db.class_eval(table_name.camelize)
          output_msg("Popolamento tabella #{klass.table_name} in corso .", new_line: false)
        end
        load f
        output_msg(". OK (#{klass.count} records)", prefix: false) if table_name
      end
    end
  end

  desc 'Retrieves the current schema migration version'
  task version: :environment do
    require 'irma/db/migrations'
    puts Irma::Db::Migrations.current_migration.to_s.split('_').first
  end

  # desc "Raises an error if there are pending migrations"
  task abort_if_pending_migrations: [:environment, 'db:migrate:load'] do
    if Irma::Db::Migrations.pending_migrations?
      warn 'You have pending migrations:'
      abort 'Run `rake db:migrate` to update your database then try again.'
    end
  end

  namespace :schema do
    # desc 'Create a db/schema.rb file that can be portably used against any DB supported by Sequel'
    task dump: :environment do
      Irma::Task.db_for_current_env.extension :schema_dumper
      File.open(Irma::Db::SCHEMA, 'w') do |file|
        file << Irma::Task.db_for_current_env.dump_schema_migration(same_db: false)
      end
      Rake::Task['db:schema:dump'].reenable
    end

    # desc 'Load a schema.rb file into the database'
    task load: :environment do
      if File.exist?(Irma::Db::SCHEMA)
        require 'sequel/extensions/migration'
        load(Irma::Db::SCHEMA)
        ::Sequel::Migration.descendants.each { |m| m.apply(Irma::Task.db_for_current_env, :up) }
      else
        abort "#{file} doesn't exist yet. Run 'rake db:migrate' to create it, then try again."
      end
    end
  end

  namespace :structure do
    # desc 'Dump the database structure to db/structure.sql'
    task :dump, [:env] => :environment do |_t, args|
      args.with_defaults(env: Irma::Db.env)

      filename = Irma::Db::STRUCTURE
      if Irma::Db::Storage.dump_environment args.env, filename
        ::File.open filename, 'a' do |file|
          file << Irma::Db::Migrations.dump_schema_information(sql: true)
        end
      else
        abort "Could not dump structure for #{args.env}."
      end

      Rake::Task['db:structure:dump'].reenable
    end

    task :load, [:env] => :environment do |_t, args|
      args.with_defaults(env: Irma::Db.env)

      unless Irma::Db::Storage.load_environment args.env, filename
        abort "Could not load structure for #{args.env}."
      end
    end
  end

  task dump: :environment do
    case (@schema_format ||= :ruby)
    when :ruby
      Rake::Task['db:schema:dump'].invoke
    when :sql
      Rake::Task['db:structure:dump'].invoke
    else
      abort "unknown schema format #{@schema_format}"
    end
  end

  task load: :environment do
    case (@schema_format ||= :ruby)
    when :ruby
      Rake::Task['db:schema:load'].invoke
    when :sql
      Rake::Task['db:structure:load'].invoke
    else
      abort "unknown schema format #{@schema_format}"
    end
  end

  namespace :create do
    # desc 'Create all the local databases defined in config/database.yml'
    task all: :minimal_environment do
      ok = true
      begin
        ok = Irma::Db::Storage.create_all
      rescue
        ok = false
      end
      abort 'ERROR: Could not create all databases.' unless ok
    end
  end

  desc "Create the database defined in config/database.yml for the env specified (or the default #{Irma::Db.env})"
  task :create, [:env] => :minimal_environment do |_t, args|
    args.with_defaults(env: Irma::Db.env)
    ok = true
    begin
      ok = Irma::Db::Storage.create_environment(args.env)
    rescue
      ok = false
    end
    abort "ERROR: Could not create database for #{args.env}." unless ok
  end

  namespace :drop do
    # desc 'Drops all the local databases defined in config/database.yml'
    task :all do
      ok = true
      begin
        Irma::Task.db_for_current_env
        ok = Irma::Db::Storage.drop_all
      rescue
        ok = false
      end
      warn "WARNING: Couldn't drop all databases" unless ok
    end
  end

  # desc "Drop the database defined in config/database.yml for the env specified (or the default #{Irma::Db.env})"
  task :drop, [:env] do |_t, args|
    args.with_defaults(env: Irma::Db.env)

    ok = true
    begin
      Irma::Task.db_for_current_env
      ok = Irma::Db::Storage.drop_environment(args.env)
    rescue
      ok = false
    end
    warn "WARNING: Couldn't drop database for environment #{args.env}" unless ok
  end

  namespace :migrate do
    task load: :environment do
    end

    desc "Mostra lo stato delle migrazioni for the env specified (or the default #{Irma::Db.env})"
    task :status, [:env] => :environment do |_t, args|
      Irma::Db.env(args[:env])
      puts "\n" + Irma::Db.migrate_status + "\n"
    end

    # desc 'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
    task redo: :load do
      if ENV['VERSION']
        Rake::Task['db:migrate:down'].invoke
        Rake::Task['db:migrate:up'].invoke
      else
        Rake::Task['db:rollback'].invoke
        Rake::Task['db:migrate'].invoke
      end
    end

    # desc 'Resets your database using your migrations for the current environment'
    task reset: %w(db:drop db:create db:migrate)

    # desc 'Runs the "up" for a given migration VERSION.'
    task up: :load do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version
      Irma::Db::Migrations.migrate_up!(version)
      # Rake::Task['db:dump'].invoke if Irma::Db.configuration.schema_dump
    end

    # desc 'Runs the "down" for a given migration VERSION.'
    task down: :load do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version
      Irma::Db::Migrations.migrate_down!(version)
    end
  end

  desc "Migrate the database to the latest version for the env specified (or the default #{Irma::Db.env})"
  task :migrate, [:env] do |_t, args|
    Rake::Task['db:environment'].reenable
    Irma::Db.env(args[:env])
    Rake::Task['db:migrate:load'].invoke
    if (ENV['FORCE'] == '1') || ENV['VERSION'] || Irma::Db.actual_migration.to_s.empty? || !Irma::Db::Migrations.current?
      Irma::Db::Migrations.migrate_up!(ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
    end
    puts "Migrazione corrente: #{Irma::Db::Migrations.current_migration}"
  end

  # desc "Rollback the latest migration file or down to specified VERSION=x for the env specified (or the default #{Irma::Db.env})"
  task :rollback, [:env] => 'migrate:load' do |_t, args|
    Rake::Task['db:environment'].reenable
    Irma::Db.env(args[:env])
    version = if ENV['VERSION']
                ENV['VERSION'].to_i
              else
                Irma::Db::Migrations.previous_migration
              end
    Irma::Db::Migrations.migrate_down! version
  end

  namespace :cgi do
    task :common do
      ENV['EXPORT_CGI_DIR'] ||= Irma.tmp_dir
    end

    task popola_ci_regione: :common do
      Irma::Task.db_for_current_env
      Irma::Db.load_models

      output_msg('Inizializzazione CiRegione .', new_line: false)
      file_ci_regione = File.join(ENV['EXPORT_CGI_DIR'], Irma::NOME_FILE_EXPORT_INIT_CI_REGIONE)
      ref_date = Time.now.to_s
      FileUtils.rm_f(file_ci_regione) if File.exist?(file_ci_regione)

      File.open(file_ci_regione, 'w') do |fd|
        [RETE_UMTS, RETE_GSM].each do |rete|
          Irma::AnagraficaTerritoriale::REGIONI.keys.each do |regione|
            TUTTI_I_CI.each do |ci|
              new_record = { ci: ci, regione: regione, rete_id: rete, busy: CI_REGIONE_BUSY_NO,
                             updated_at: ref_date, created_at: ref_date }
              pezzi = []
              Irma::PR_COLUMNS_CI_REGIONE.each { |k| pezzi << (Irma::PR_COLUMNS_CI_REGIONE_JSON.member?(k) ? new_record[k.to_sym].to_json : new_record[k.to_sym].to_s) }

              fd.puts(pezzi.join(Irma::PR_CGI_FIELD_SEP))
            end
          end
        end
      end

      # Irma::Command.process(['export_cgi_irma1', '--empty_data', 'true', '--out_dir_root', ENV['EXPORT_CGI_DIR']])
      Irma::Db::CiRegione.truncate
      File.open(File.join(ENV['EXPORT_CGI_DIR'], Irma::NOME_FILE_EXPORT_INIT_CI_REGIONE), 'r') do |fd_in|
        Irma::Db::Model.db.copy_into(:ci_regioni, columns: Irma::PR_COLUMNS_CI_REGIONE, options: Irma::PR_CGI_OPTIONS) do
          fd_in.gets
        end
      end
      output_msg('. OK', prefix: false)
    end
  end

  # desc "Import database export files found in EXPORT_DB_DIR, choosing WHAT_TO_IMPORT (default #{Irma::Db::EXPORT_FOR_SQL_LOADER_ANAGRAFICA})"
  task :import_from_export_sql do
    what = ENV['WHAT_TO_IMPORT'] || Irma::Db::EXPORT_FOR_SQL_LOADER_ANAGRAFICA # Irma::Db::EXPORT_FOR_SQL_LOADER_PRN
    raise 'WHAT_TO_IMPORT env variable not set' unless ENV['WHAT_TO_IMPORT']
    raise 'EXPORT_DB_DIR env variable not set' unless ENV['EXPORT_DB_DIR']
    Irma::Db.disconnect
    saved_logger = Irma::Db.logger
    output_msg("Import DB (#{what}) dalla directory #{ENV['EXPORT_DB_DIR']} .", new_line: false)
    begin
      Irma::Db.logger = nil
      cmd_args = ['import_db', '--what', what, '--input_dir', ENV['EXPORT_DB_DIR'], '--env', ENV['IRMA_ENV'] || 'production']
      cmd_args += ['--log_file', File.absolute_path(File.join(ENV['REPORT_DIR'], 'irma_import_db.log'))] if ENV['REPORT_DIR']
      Irma::Command.process(cmd_args)
    ensure
      Irma::Db.logger = saved_logger
    end
    raise "ERRORE: l'anagrafica non è stata importata correttamente (controllare la directory #{ENV['EXPORT_DB_DIR']})" unless Irma::Db::Account.count > 0
    output_msg('. OK', prefix: false)
    output_msg('Configurazione autenticazione automatica .', new_line: false)
    Irma::ModConfig.check_for_db_updates
    Irma::Db::Account.config.set_value(Irma::Db::Account::AUTENTICAZIONE, AUTENTICAZIONE_AUTO)
    output_msg('. OK', prefix: false)
    Rake::Task['db:populate'].invoke
    Rake::Task['db:crea_utenti_dev'].invoke unless (ENV['SKIP_CREA_UTENTI_DEV'] || '0') == '1'
    output_msg('Aggiornamento versione sistema in corso ...')
    if ENV['IRMA_HOME'] || ENV['IRMA_MANIFEST']
      ENV['AGGIORNA'] = '1'
      Rake::Task['db:versione_sistema'].invoke
    end
  end

  task :crea_utenti_dev do
    output_msg('Aggiunta account per utenti dev .', new_line: false)
    %w(SO000009 SO000169 SO000226 SO000291 SO000431).each do |matricola| # TODO: aggiungere matricole UE...
      Irma::Constant.values(:profilo).each do |profilo|
        Irma::Command.process(['crea_account', '-m', matricola, '-p', profilo, '-i', true])
      end
    end
    output_msg('. OK', prefix: false)
  end

  task :setup_for_acceptance do
    ENV['WHAT_TO_IMPORT'] = [Irma::Db::EXPORT_FOR_SQL_LOADER_ANAGRAFICA, Irma::Db::EXPORT_FOR_SQL_LOADER_PRN].join(',')
    output_msg('Creazione DB e migrazione dello schema ... ')
    Rake::Task['db:migrate:reset'].invoke
    Irma::Db::Migrations.migrate_down!(ENV['DB_EXPORT_MIGRATE_VERSION']) if ENV['DB_EXPORT_MIGRATE_VERSION']
    Rake::Task['db:import_from_export_sql'].invoke
    Irma::Db::Migrations.migrate_up! if ENV['DB_EXPORT_MIGRATE_VERSION']
  end

  # desc 'Create the database for dev and test, loading import data for anagrafica'
  task setup_for_development: ['db:migrate:reset', 'db:test:prepare'] do
    ENV['WHAT_TO_IMPORT'] ||= Irma::Db::EXPORT_FOR_SQL_LOADER_ANAGRAFICA
    output_msg('Creazione DB e migrazione dello schema ... ')
    Rake::Task['db:migrate:reset'].invoke
    output_msg('Creazione DB di test e migrazione dello schema ... ')
    Rake::Task['db:test:prepare'].invoke
    Rake::Task['db:import_from_export_sql'].invoke
  end

  task aggiorna_etichette_eccezioni: :environment do
    raise 'SISTEMA_ID env variable not set' unless ENV['SISTEMA_ID']
    Irma::Db.load_models
    query = Irma::Db::Sistema
    query = query.where(id: ENV['SISTEMA_ID'].split(',')) unless ENV['SISTEMA_ID'] == '-1' || ENV['SISTEMA_ID'] == 'all'
    query.order(:id).each do |s|
      s_descr = "#{s.full_descr} (id=#{s.id})"
      start_time = Time.now
      dataset_label = s.entita(ambiente: nil, archivio: ARCHIVIO_LABEL).first.dataset
      dataset_label.truncate if ENV['RESET_LABELS'] == '1'
      idx = dataset_label.count
      if idx > 0
        output_msg("Popolamento archivio label da archivio eccezioni per il sistema #{s_descr} non eseguito, #{idx} righe presenti", new_line: true) if defined?(:output_msg)
        next
      end

      dataset_label.db.transaction do
        begin
          s.entita(ambiente: nil, archivio: ARCHIVIO_ECCEZIONI).first.dataset.select(:dist_name, :meta_entita, :naming_path, :parametri).each do |row|
            next unless row[:parametri]
            mp_list = row[:parametri].keys.map { |pp| pp.split(Irma::TEXT_STRUCT_NAME_SEP).first }.uniq
            mp_list.each do |mp|
              ent_label = Irma::Db::EntitaLabel::Record.new(id: idx += 1, dist_name: row[:dist_name], meta_entita: row[:meta_entita], naming_path: row[:naming_path], meta_parametro: mp)
              dataset_label.insert(*ent_label.for_insert)
            end
          end
          elapsed = (Time.now - start_time).round(1)
          output_msg("Popolamento archivio label da archivio eccezioni per il sistema #{s_descr} completato in #{elapsed} secondi, inserite #{idx} righe", new_line: true) if defined?(:output_msg)
        rescue => e
          output_msg("Popolamento archivio label da archivio eccezioni per il sistema #{s_descr} fallito (#{e})", new_line: true) if defined?(:output_msg)
        end
      end
    end
  end

  task bonifica_etichette_eccezioni: :environment do
    raise 'SISTEMA_ID env variable not set' unless ENV['SISTEMA_ID']
    Irma::Db.load_models
    query = Irma::Db::Sistema
    query = query.where(id: ENV['SISTEMA_ID'].split(',')) unless ENV['SISTEMA_ID'] == '-1' || ENV['SISTEMA_ID'] == 'all'
    query.order(:id).each do |s|
      s_descr = "#{s.full_descr} (id=#{s.id})"
      start_time = Time.now
      ent_label = s.entita(ambiente: nil, archivio: ARCHIVIO_LABEL).first
      ent_ecc = s.entita(ambiente: nil, archivio: ARCHIVIO_ECCEZIONI).first
      mm_keys = s.metamodello.meta_parametri_strutturati_per_struttura.flat_map { |k, v| v.keys.map { |x| "#{k}-#{x}" } }
      begin
        idx_before = ent_label.dataset.count
        # 1. cancello righe non presenti nella rispettiva tabella eccezioni
        count = ent_label.dataset.where("dist_name not in (select dist_name from #{ent_ecc.table_name})").delete
        # 2. ripulisco dalle righe doppie
        actu_dn = ''
        actu_param = ''
        lista_id_da_cancellare = []
        ent_label.dataset.select(:id, :dist_name, :meta_parametro).order(:dist_name, :meta_parametro, :updated_at).each do |row|
          if actu_dn != row[:dist_name]
            actu_dn = row[:dist_name]
            actu_param = row[:meta_parametro]
            next
          end
          if actu_param == row[:meta_parametro]
            lista_id_da_cancellare << row[:id]
            next
          end
          actu_param = row[:meta_parametro]
        end
        count += ent_label.dataset.where(id: lista_id_da_cancellare).delete
        # 3. sistemo gli strutturati
        Irma::Db.connection.run("update #{ent_label.table_name} set meta_parametro=meta_parametro || '.' where naming_path || '-' || meta_parametro in ('#{mm_keys.join("','")}')")
        # 4. indice unique dist_name - meta_parametro
        Irma::Db.connection.run("create unique index if not exists u#{ent_label.index_prefix}$dn_mp_idx on #{ent_label.table_name} (dist_name, meta_parametro)")
        # 5. default LABEL_NC_DB per la colonna label not null
        Irma::Db.connection.run("update #{ent_label.table_name} set label = '#{Irma::LABEL_NC_DB}' where label is null;")
        Irma::Db.connection.run("alter table #{ent_label.table_name} alter column label set default '#{Irma::LABEL_NC_DB}'")
        Irma::Db.connection.run("alter table #{ent_label.table_name} alter column label set not null")
        idx_after = ent_label.dataset.count
        elapsed = (Time.now - start_time).round(1)
        msg = "Bonifica archivio label per il sistema #{s_descr} completato in #{elapsed} secondi, righe iniziali: #{idx_before} - righe finali: #{idx_after}, righe cancellate: #{count}"
        output_msg(msg, new_line: true) if defined?(:output_msg)
      rescue => e
        output_msg("Bonifica archivio label per il sistema #{s_descr} fallito (#{e})", new_line: true) if defined?(:output_msg)
      end
    end
  end

  task bonifica_etichette_eccezioni_2: :environment do
    raise 'SISTEMA_ID env variable not set' unless ENV['SISTEMA_ID']
    Irma::Db.load_models
    query = Irma::Db::Sistema
    query = query.where(id: ENV['SISTEMA_ID'].split(',')) unless ENV['SISTEMA_ID'] == '-1' || ENV['SISTEMA_ID'] == 'all'
    query.order(:id).each do |s|
      s_descr = "#{s.full_descr} (id=#{s.id})"
      start_time = Time.now
      ent_label = s.entita(ambiente: nil, archivio: ARCHIVIO_LABEL).first
      ent_ecc = s.entita(ambiente: nil, archivio: ARCHIVIO_ECCEZIONI).first
      begin
        count = 0
        idx_before = ent_label.dataset.count
        ent_ecc.dataset.select(:dist_name, :parametri).order(:dist_name).each do |row|
          delete_query = ent_label.dataset.where(dist_name: row[:dist_name])
          p_ecc = (row[:parametri] || {}).keys.map { |pp| pp.include?(Irma::TEXT_STRUCT_NAME_SEP) ? pp.split(Irma::TEXT_STRUCT_NAME_SEP).first + Irma::TEXT_STRUCT_NAME_SEP : pp }.uniq
          delete_query = delete_query.exclude(meta_parametro: p_ecc) unless p_ecc.empty?
          count += delete_query.delete
        end
        idx_after = ent_label.dataset.count
        elapsed = (Time.now - start_time).round(1)
        msg = "Bonifica_2 archivio label per il sistema #{s_descr} completato in #{elapsed} secondi, righe iniziali: #{idx_before} - righe finali: #{idx_after}, righe cancellate: #{count}"
        output_msg(msg, new_line: true) if defined?(:output_msg)
      rescue => e
        output_msg("Bonifica_2 archivio label per il sistema #{s_descr} fallito (#{e})", new_line: true) if defined?(:output_msg)
      end
    end
  end

  task accounts_di_un_sistema: :environment do
    raise 'SISTEMA_DESCR_RETE env variable not set (e.g. JNATTTA001 or JNATTA001,UMTS)' unless ENV['SISTEMA_DESCR_RETE']
    Irma::Db.load_models
    filtro = {}
    filtro[:descr], rete = ENV['SISTEMA_DESCR_RETE'].split(',')
    filtro[:rete_id] = Irma::Constant.value(:rete, rete) if rete
    sistemi_id = Irma::Db::Sistema.where(filtro).select_map(:id)
    raise "Nessun sistema trovato con #{ENV['SISTEMA_DESCR_RETE']}, filtro: #{filtro}" if sistemi_id.empty?
    superuser_profiles = [PROFILO_SUPERUSER_PROG, PROFILO_SUPERUSER_QUAL, PROFILO_SUPERUSER_RO_PROG, PROFILO_SUPERUSER_RO_QUAL]
    res = []
    Irma::Db::Account.each do |acc|
      next if (acc.sistemi_di_competenza & sistemi_id).empty? || ((ENV['EXCLUDE_SUPERUSERS'] || '1') == '1' && superuser_profiles.include?(acc.profilo_id))
      utente = acc.utente
      (acc.sistemi_di_competenza & sistemi_id).each do |sistema_id|
        sistema = Irma::Db::Sistema.get_by_pk(sistema_id)
        res << [sistema.descr, Irma::Constant.label(:rete, sistema.rete_id), utente.cognome, utente.nome, utente.matricola, utente.dipartimento, utente.email, acc.profilo.nome, acc.stato]
      end
    end
    puts '# Sistema, Rete, Cognome, Nome, Matricola, Dipartimento, E-Mail, Profilo, Stato Account'
    puts res.sort.map { |x| x.join(',') }.join("\n")
  end

  task valida_regole_calcolo: :environment do
    raise 'VENDOR_RELEASE_DESCR env variable not set (e.g. ERICSSON,RC17B,LTE)' unless ENV['VENDOR_RELEASE_DESCR']
    Irma::Db.load_models
    filtro = {}
    vendor, filtro[:descr], rete = ENV['VENDOR_RELEASE_DESCR'].split(',')
    filtro[:vendor_id] = Irma::Db::Vendor.first(nome: vendor).id
    filtro[:rete_id] = Irma::Constant.value(:rete, rete) if rete
    vr = Irma::Db::VendorRelease.where(filtro).first
    raise "Nessuna VendorRelease trovata con #{ENV['VENDOR_RELEASE_DESCR']}, filtro: #{filtro}" if vr.nil?
    count_me = 0
    count_mp = 0
    results = { meta_entita: [], meta_parametri: [] }
    Irma::Db::MetaEntita.where(vendor_release_id: vr.id).exclude(fase_di_calcolo: nil).each do |me|
      # puts "meta_entita: #{me.nome} - rete_adj: #{me.rete_adj}"
      count_me += 1
      me.valida_tutte_le_regole do |key_prefix, _regola, rete_adj, is_ae, outmsg|
        unless outmsg.empty?
          results[:meta_entita] << { nome: me.nome, chiave_rc: key_prefix, rete_adj: rete_adj, is_ae: is_ae, esito_validazione: outmsg }
        end
      end
      Irma::Db::MetaParametro.where(vendor_release_id: vr.id, meta_entita_id: me.id).each do |mp|
        # puts "meta_parametro: #{mp.nome} - rete_adj: #{mp.rete_adj}"
        count_mp += 1
        mp.valida_tutte_le_regole do |key_prefix, _regola, rete_adj, is_ae, outmsg|
          unless outmsg.empty?
            results[:meta_parametri] << { nome: mp.nome, chiave_rc: key_prefix, rete_adj: rete_adj, is_ae: is_ae, esito_validazione: outmsg }
          end
        end
      end
    end
    puts "**** Validazione regole calcolo per la VendorRelease #{vr.compact_descr}:"
    puts "Totale meta_entita verificate: #{count_me}, di cui le seguenti #{results[:meta_entita].size} da verificare:"
    puts results[:meta_entita]
    puts '------------------------------'
    puts "Totale meta_parametri verificati: #{count_mp}, di cui i seguenti #{results[:meta_parametri].size} da verificare:"
    puts results[:meta_parametri]
  end

  # desc 'Create the database, load the schema, and initialize with the seed data'
  task setup: %w(db:create db:load)

  # desc 'Drops and recreates the database from db/schema.rb for the current environment'
  task reset: %w(db:drop db:setup)

  # desc 'Forcibly close any open connections to the current env database (PostgreSQL specific)'
  task :force_close_open_connections, [:env] => :environment do |_t, args|
    Irma::Db::Storage.close_connections_environment({ env: Irma::Db.env }.merge(args))
  end

  namespace :test do
    desc 'Prepare test database (ensure all migrations ran, drop and re-create database then load schema and populate schema_migrations table)'
    task old_prepare: 'db:abort_if_pending_migrations' do
      Rake::Task['db:schema:dump'].execute
      previous_env = Irma::Db.env
      previous_migrations = Irma::Db.connection[:schema_migrations].map(:filename)
      Irma::Db.env('test')
      Rake::Task['db:drop'].execute
      Rake::Task['db:create'].execute
      Rake::Task['db:load'].execute
      # update the schema_migrations
      previous_migrations.each { |r| Irma::Db.connection[:schema_migrations].insert(r) }
      Sequel::DATABASES.each(&:disconnect)
      Irma::Db.env(previous_env)
    end
    task prepare: 'db:abort_if_pending_migrations' do
      previous_env = Irma::Db.env
      begin
        Irma::Db.disconnect
        Sequel::DATABASES.each(&:disconnect)
        Irma::Db.env('test')
        Rake::Task['db:drop'].execute
        Rake::Task['db:create'].execute
        Rake::Task['db:migrate'].execute
      ensure
        Irma::Db.disconnect
        Sequel::DATABASES.each(&:disconnect)
        Irma::Db.env(previous_env)
      end
    end
  end
end

namespace :redis do
  task :keys do
    keys = Redis.current.keys
    if keys.empty?
      puts 'Nessuna chiave in REDIS'
    else
      puts "REDIS contiene #{keys.size} chiavi:"
      puts '-' * 70
      keys.sort.each do |key|
        puts format('%-40s: %s', key, Redis.current.get(key))
      end
      puts '_' * 70
    end
    keys
  end
  task :info do
    puts 'REDIS info:'
    puts '-' * 70
    Redis.current.info.sort.each do |k, v|
      puts format('%-30s: %s', k, v)
    end
    puts '_' * 70
  end
  task locks: 'db:lock:show'
end

task 'test:prepare' => 'db:test:prepare'
