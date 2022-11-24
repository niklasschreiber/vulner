# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160226
#

%w(cache_manager).each do |f|
  require_relative "cache/#{f}"
end
