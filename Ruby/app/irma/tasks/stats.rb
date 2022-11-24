# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151125
#
# Task to print database table statistics

require 'rake'
require 'terminal-table'
require_relative 'stats_util'

module Irma
  #
  module Task
    #
    module Stats
    end
  end
end

namespace :stats do
  task :common do
    require 'irma/db'
    Irma::Db.init
    Irma::Db.load_models
  end

  Irma::Task::Stats::AVAILABLE.each do |k|
    desc "Situazione #{k}"
    task k => :common do
      puts Irma::Task::Stats.send(k)
    end
  end

  task all: :common do
    puts Irma::Task::Stats.all
  end

  task 'db_records' => :common do
    puts Irma::Task::Stats.db_records(order_by: ENV['ORDER_BY'], format: ENV['FORMAT'])
  end
end

desc 'Situazione totale'
task stats: 'stats:all'
