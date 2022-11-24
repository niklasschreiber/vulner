# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20120430
#

require 'rake'
require 'terminal-table'

#
module Irma
  #
  module Task
    #
    module Info
      def self.ruby(_hash = {})
        rows = [
          ['jruby_version', JRUBY_VERSION],
          ['ruby_version',  "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL}"],
          ['gems',          Gem::VERSION]
        ]
        Gem::Specification.find_all { true }.sort_by(&:name).each { |x| rows << ["  #{x.name}", x.version.to_s] }
        "Info Ruby: #{rows.count} totali\n" + Terminal::Table.new(headings: %w(Tool Version), rows: rows).to_s
      end

      def self.tools(_hash = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        rows = []
        [
          ['java_runtime', 'java',   -> { java.lang.System.getProperties['java.runtime.version'] + ' / ' + java.lang.System.getProperties['java.runtime.name'] }],
          ['java_vm',      'java',   -> { java.lang.System.getProperties['java.vm.version'] + ' / ' + java.lang.System.getProperties['java.vm.name'] }],
          ['postgresql',   nil,      lambda do
            x = `psql --version 2>/dev/null`
            $CHILD_STATUS.success? ? x.split("\n")[0].split[2] : raise('NON INSTALLATO')
          end]
        ].each do |tool, require_file, cmd|
          begin
            require require_file if require_file
            ver = cmd.call
          rescue => e
            ver = "N/A - #{e}"
          ensure
            rows << [tool, ver]
          end
        end
        "Info tools: #{rows.count} totali\n" + Terminal::Table.new(headings: %w(Tool Version), rows: rows).to_s
      end

      def self.db(hash = {})
        "Info migrazioni:\n#{Irma::Db.migrate_status(hash)}\n\n#{Irma::Db.space_used(hash)}"
      end
    end
  end
end

namespace :info do
  desc 'Mostra le versioni di jruby, ruby e delle gem disponibili'
  task :ruby do
    puts Irma::Task::Info.ruby
  end

  desc 'Mostra le versioni dei tool esterni'
  task :tools do
    puts Irma::Task::Info.tools
  end

  desc 'Mostra le migrazioni del DB'
  task :db do
    puts Irma::Task::Info.db
  end

  task :all do
    %w(ruby tools db).each do |t|
      puts ''
      Rake::Task["info:#{t}"].invoke
    end
  end
end

desc 'Info totali'
task info: 'info:all'
