# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20180521
#

require 'irma/db'

module Irma
  # rubocop:disable Metrics/ClassLength
  class Command < Thor
    method_option :env,              aliases: '-e', type: :string, banner: 'Environment', default: Irma::Db.env, enum: %w(production development test)
    method_option :what,             type: :string, banner: "Cosa esportare (#{Db::EXPORT_FOR_SQL_LOADER.join(',')}), vuoto per tutto", default: ''
    method_option :out_dir,          type: :string, banner: 'Subdir di export o path assoluto per il posizionamento dei file generati', default: 'db_export'
    method_option :out_file_pattern, type: :string, banner: 'Pattern per la costruzione del nome del file', default: 'db_export_@WHAT@_@DATE@.sql.gz'
    common_options 'export_db', "Esegue l'export delle tabelle principali del DB in formato sql loader"
    def export_db # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      whats = options[:what].split(',')
      whats = Db::EXPORT_FOR_SQL_LOADER if whats.empty?
      date =  Time.now.strftime('%Y%m%d_%H%M%S')
      todo = whats.each_with_object({}) { |what, ret| ret[what] = options[:out_file_pattern].gsub('@WHAT@', what).gsub('@DATE@', date) }
      out_dir = if Pathname.new(options[:out_dir] || '').relative?
                  File.join(EXPORT_DIR_NAME, options[:out_dir] || '')
                else
                  FileUtils.mkdir_p(options[:out_dir])
                  options[:out_dir]
                end
      log_prefix = "Export db (#{whats.join(',')}) in file sql loader (output dir = #{out_dir})"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: log_prefix) do
        res = { files: {} }
        todo.each do |what, file|
          begin
            start_time = Time.now
            gz_name = File.join(Irma.tmp_dir, file)
            target_file = File.join(out_dir, File.basename(gz_name))
            res[:files][what] = target_file
            logger.info("#{log_prefix}, inizio export db #{what} nel file #{target_file}")
            Zlib::GzipWriter.open(gz_name) { |gz| Db.export_for_sql_loader(what: what, fd: gz) }
            if Pathname.new(out_dir).relative?
              shared_post_file(gz_name, target_file)
              FileUtils.rm_f(gz_name)
            else
              FileUtils.mv(gz_name, target_file)
            end
            logger.info("#{log_prefix}, fine export db #{what} nel file #{target_file} (#{(Time.now - start_time).round(1)} sec.)")
          rescue => e
            logger.error("Unexpected error during export_db #{what} into file #{gz_name}: #{e}")
          end
        end
        res
      end
    end

    method_option :env,              aliases: '-e', type: :string, banner: 'Environment', default: Irma::Db.env, enum: %w(production development test)
    method_option :what,             type: :string, banner: "Cosa importare (#{Db::EXPORT_FOR_SQL_LOADER.join(',')}), vuoto per tutto", default: ''
    method_option :input_dir,        type: :string, banner: 'Path assoluto della directory contentente i file di export del DB'
    common_options 'import_db', "Esegue l'import del DB di tutti i file presenti nella directory di input"
    def import_db # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      whats = options[:what].split(',')
      whats = Db::EXPORT_FOR_SQL_LOADER if whats.empty?
      input_dir = options[:input_dir]
      raise "Input dir '#{input_dir}' not found" unless File.directory?(input_dir)

      db_config = Db.config(options[:env])
      raise "Db config not available for env '#{options[:env]}'" unless db_config

      file = nil
      log_prefix = "Import db (#{whats.join(',')}) da file sql loader (input dir = #{input_dir})"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: log_prefix) do
        res = { files: {}, errors: [] }
        Db::EXPORT_FOR_SQL_LOADER.each do |what|
          begin
            next unless whats.include?(what)

            # use the last file ordered by date
            file_pattern = "#{input_dir}/*#{what}*.gz"
            file = Dir[file_pattern].sort.reverse.first

            res[:files][what] = file

            if file
              start_time = Time.now
              logger.info("#{log_prefix}, inizio import #{what}, db file #{file}")

              ret = `gunzip "#{file}" -c | psql --port #{db_config['port']} --username #{db_config['username']} #{db_config['database']} 2>&1`
              if ret =~ /ERROR:/ || !$CHILD_STATUS.exitstatus.zero?
                res[:errors] << ret
                logger.error("#{log_prefix}, fine import db file #{file} con errori: #{ret}")
              else
                # adjust creation for entity tables
                if what == Db::EXPORT_FOR_SQL_LOADER_ANAGRAFICA
                  logger.info("#{log_prefix}, sql file caricato in #{(Time.now - start_time).round(1)} sec., aggiustamento tabelle sistema e omc_fisico")
                  start_time1 = Time.now
                  { Db::Sistema => [:descr, :rete_id], Db::OmcFisico => [:nome] }.each do |klass, order_by|
                    klass.order(order_by).each do |o|
                      logger.info("#{log_prefix}, (#{klass}) aggiustamento #{o.full_descr} (#{o.id})")
                      o.entita.each(&:create_table)
                      o.crea_empty_pi
                    end
                  end
                  logger.info("#{log_prefix}, aggiustamento tabelle completato in #{(Time.now - start_time1).round(1)} sec., inizio aggiornamento metamodello fisico")
                  start_time1 = Time.now
                  Db::VendorRelease.load_in_cache(true)
                  Db::VendorReleaseFisico.aggiornamento_fisico_da_logico
                  logger.info("#{log_prefix}, aggiornamento metamodello fisico completato in #{(Time.now - start_time1).round(1)} sec.")
                end
                logger.info("#{log_prefix}, fine import #{what}, db file #{file} (#{(Time.now - start_time).round(1)} sec.)")
              end
            else
              logger.warn("#{log_prefix}, nessun file per #{what} trovato con pattern #{file_pattern}")
            end
          rescue => e
            logger.error("Unexpected error during import_db #{what} from file '#{file}': #{e}")
          end
        end
        res
      end
    end

    private

    def pre_export_db
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def pre_import_db
      self.creazione_eventi = false
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
