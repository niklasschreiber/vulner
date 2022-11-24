# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151123
#

#
module Irma
  #
  module Db
    AppConfig.transaction do
      ModConfig.save_to_db(remove_undefined: true)

      # rimuovo tutti i parametri in moduli non piu' esistenti
      AppConfig.order(%i(modulo nome)).each do |p|
        begin
          mod = class_eval("::#{p.modulo}")
          mod.config[p.nome]
        rescue
          p.logger.warn("Modulo #{p.modulo}, il parametro #{p.nome} non è più definito e viene eliminato dal db")
          p.destroy
        end
      end
    end
  end
end
