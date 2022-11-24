# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151008
#

%w(constant_manager util message_catalog mod_config redis lock).each do |f|
  require_relative "common/#{f}"
end
