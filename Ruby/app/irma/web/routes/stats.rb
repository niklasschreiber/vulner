# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20180312
#

require 'irma/tasks/stats_util'

module Irma
  #
  module Web
    #
    class App < Roda
      def _format_shared_file_list(list_entry:, format:, level: 0) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        case (f = (format || 'html').to_s.to_sym)
        when :raw
          list_entry
        when :html, :text
          space = f == :html ? '&nbsp;' : ' '
          res = ''
          extra_info = list_entry['leaf'] ? "#{space}(#{list_entry['dimensione'] / 1024} Kb, #{list_entry['data_file']})" : ''
          res += (space * (4 * level)) + list_entry['descr'] + extra_info + (f == :html ? '<br>' : "\n")
          (list_entry['children'] || []).each do |child|
            res += _format_shared_file_list(list_entry: child, format: format, level: level + 1)
          end
          res
        end
      end

      def _date_for_file(format: '%Y%m%d_%H%M%S')
        Time.now.strftime(format)
      end
    end

    App.route('stats') do |r|
      # verifica_sessione(r)
      r.post('cmd') do
        begin
          case r.params['command']
          when 'db_records'
            Task::Stats.db_records(order_by: r.params['order_by'], format: r.params['format'] || 'html')
          when 'all_stats'
            out_file = File.join(Irma.tmp_dir, (r.params['file'] || 'stats_@DATE@.txt').gsub('@DATE@', _date_for_file))
            out_dir = File.join(EXPORT_DIR_NAME, r.params['dir'] || '')
            Thread.start do
              begin
                File.open(out_file, 'w') { |fd| fd.puts Task::Stats.all }
                shared_post_file(out_file, File.join(out_dir, File.basename(out_file)))
                FileUtils.rm_f(out_file)
              rescue => e
                Irma.logger.error("Unexpected error during all_stats into file #{out_file}: #{e}")
              end
            end
            "Scheduled creation of all_stats (output dir=#{out_dir}, file=#{File.basename(out_file)})"
          when 'show_shared_dir'
            json_file_list = shared_show_files(r.params['dir'] || EXPORT_DIR_NAME)
            _format_shared_file_list(list_entry: JSON.parse(json_file_list), format: r.params['format']).to_s
          when 'remove_shared_file'
            r.halt([HTTP_CODE_NOT_FOUND, { 'Content-Type' => 'text/html' }, ["Bad file '#{r.params['file']}' param"]]) unless r.params['file']
            shared_remove_path(File.join(EXPORT_DIR_NAME, r.params['file']))
          when 'get_shared_file'
            r.halt([HTTP_CODE_NOT_FOUND, { 'Content-Type' => 'text/html' }, ["Bad file '#{r.params['file']}' param"]]) unless r.params['file']
            invia_file shared_get_file(File.join(r.params['dir'] || EXPORT_DIR_NAME, r.params['file'])), filename: File.basename(r.params['file'])
          when 'db_export'
            whats = (r.params['what'] || '').split(',')
            whats = Db::EXPORT_FOR_SQL_LOADER if whats.empty?
            date = _date_for_file
            todo = whats.map { |what| [what, (r.params['file'] || 'db_export_@WHAT@_@DATE@.sql.gz').gsub('@WHAT@', what).gsub('@DATE@', date)] }
            out_dir = File.join(EXPORT_DIR_NAME, r.params['dir'] || '')
            Thread.start do
              begin
                todo.each do |what, file|
                  gz_name = File.join(Irma.tmp_dir, file)
                  Zlib::GzipWriter.open(gz_name) { |gz| Db.export_for_sql_loader(what: what, fd: gz) }
                  shared_post_file(gz_name, File.join(out_dir, File.basename(gz_name)))
                  FileUtils.rm_f(gz_name)
                end
              rescue => e
                Irma.logger.error("Unexpected error during db_export #{what} into file #{gz_name}: #{e}")
              end
            end
            "Scheduled creation of db_export files (output dir=#{out_dir}, files=#{todo.to_h})"
          else
            r.halt([HTTP_CODE_NOT_FOUND, { 'Content-Type' => 'text/html' }, ["Command #{r.params['command']} not supported"]])
          end
        rescue => e
          r.halt([500, { 'Content-Type' => 'text/html' }, [e.to_s + " backtrace: #{e.backtrace}"]])
        end
      end
    end
  end
end
