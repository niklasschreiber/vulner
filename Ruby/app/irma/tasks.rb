# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151121
#
require 'rake'

%w(db doc info stats).each do |f|
  require_relative "tasks/#{f}"
end
