# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151122
#
# Effettua il popolamento del DB per tutti i modelli che hanno una costante associata,
# rimuovendo alla fine tutti i record presenti nel DB e non nelle costanti.

#
module Irma
  #
  module Db
    to_be_removed = []
    model_classes.sort_by(&:to_s).each do |klass|
      next unless klass.constant_populate?
      output_msg("Popolamento costanti tabella #{klass.table_name} in corso .", new_line: false) if defined?(:output_msg)
      to_be_removed << (res = klass.constant_populate(remove_old: false))
      output_msg(". OK (#{klass.all.size} records, #{res[1].length} da rimuovere)", prefix: false) if defined?(:output_msg)
    end
    unless to_be_removed.map { |x| x[1] }.flatten.empty?
      output_msg('Rimozione record associati alle costanti .', new_line: false) if defined?(:output_msg)
      n_records_removed = 0
      to_be_removed.each do |klass, id_list|
        klass.constant_unpopulate(id_list)
        output_msg('.', prefix: false, new_line: false) if defined?(:output_msg)
        n_records_removed += id_list.size
      end
      output_msg(". OK (#{n_records_removed} record rimossi)", prefix: false) if defined?(:output_msg)
    end
  end
end
