# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20151214
#

module Irma
  module Db
    #
    class Server < Model(:servers)
      unrestrict_primary_key

      plugin :timestamps, update_on_create: true

      validates_constant :stato

      def in_stato_attivo(msg)
        self.stato = SERVER_STATO_ATTIVO
        self.data_ultima_verifica = Time.now
        self.msg_ultima_verifica = msg
        self
      end
    end
  end
end

# == Schema Information
#
# Tabella: servers
#
#  created_at           :datetime
#  data_ultima_verifica :datetime
#  descr                :string          default('')
#  host                 :string(128)     non nullo
#  id                   :integer         non nullo, default(nextval('servers_id_seq')), chiave primaria
#  msg_ultima_verifica  :string
#  nome                 :string(128)     non nullo
#  porta                :integer         non nullo
#  stato                :string          default('attivo')
#  updated_at           :datetime
#
# Indici:
#
#  uidx_servers_host_porta  (host,porta) UNIQUE
#  uidx_servers_nome        (nome) UNIQUE
#
