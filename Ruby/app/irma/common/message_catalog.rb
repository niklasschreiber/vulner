# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151008
#

require 'i18n'

I18n.enforce_available_locales = false
I18n.default_locale = (Irma.get_env('LOCALE') || 'it').to_sym
I18n.load_path = Dir[File.join(File.dirname(File.expand_path(__FILE__)), 'i18n', '*.rb')]

#
module Irma
  #
  module MessageCatalog
    # helper methods (only for test)
    def self.add_key(msg_key, msg)
      I18n.backend.store_translations(I18n.locale, msg_key => msg)
    end

    def self.remove_key(msg_key)
      I18n.backend.store_translations(I18n.locale, msg_key => nil)
    end
  end
end

# global method
def format_msg(msg_key, *args)
  msg = I18n.t(msg_key, *args)
  raise("Messaggio con chiave '#{msg_key}' non definito nel catalogo per il locale '#{I18n.locale}'") if msg =~ /^translation missing:/
  msg
end
