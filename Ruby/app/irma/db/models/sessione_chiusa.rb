# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20160315
#

require 'base64'

module Irma
  module Db
    #
    class SessioneChiusa < Model(:sessioni_chiuse)
      #
      configure_retention 180, min: 7, max: 365

      # do not allow update after creation
      def before_update
        false
      end

      def data
        v = super
        v ? Marshal.restore(Base64.decode64(v)) : {}
      end
    end
  end
end

# == Schema Information
#
# Tabella: sessioni_chiuse
#
#  account_id   :integer
#  ambiente     :string(10)
#  created_at   :datetime
#  data         :string
#  ended_at     :datetime
#  expire_at    :datetime
#  host         :string(32)
#  id           :bigint
#  matricola    :string(32)
#  note         :string(255)
#  profilo      :string(32)
#  session_id   :string(255)     non nullo
#  updated_at   :datetime
#  utente_descr :string(32)
#
