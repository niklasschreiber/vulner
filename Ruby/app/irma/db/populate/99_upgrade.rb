# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation Date: 20180219
#
#
#-------------------------------------------------------

module Irma
  #
  module Db
    # -------------------------------------------------------------------------
    Sistema.each do |sss|
      sss.entita.each do |eee|
        next unless  Db.connection.table_exists?(eee.old_table_name)
        Db.connection.rename_table(eee.old_table_name, eee.table_name)
        eee.truncate if [ARCHIVIO_RETE, ARCHIVIO_CONF].include?(eee.archivio)
      end
    end
    OmcFisico.each do |ooo|
      ooo.entita.each do |eee|
        Db.connection.rename_table(eee.old_table_name, eee.table_name) if Db.connection.table_exists?(eee.old_table_name)
      end
    end
    # -------------------------------------------------------------------------
  end
end
