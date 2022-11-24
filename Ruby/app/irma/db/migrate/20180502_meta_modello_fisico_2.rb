# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation Date: 20180502
#
#
#-------------------------------------------------------
Sequel.migration do
  #
  up do
    alter_table :meta_entita do
      set_column_type :id, :Bignum
    end

    alter_table :meta_parametri do
      set_column_type :id, :Bignum
    end

    alter_table :meta_entita_fisico do
      set_column_type :id, :Bignum
      drop_column :opzioni_operazioni_ammesse
      add_column  :tipo_oggetto, Integer, default: 0, null: false
    end

    alter_table :meta_parametri_fisico do
      set_column_type :id, :Bignum
      add_column :is_update_on_create, :boolean, default: false
    end
  end

  down do
    alter_table :meta_parametri_fisico do
      drop_column :is_update_on_create
    end

    alter_table :meta_entita_fisico do
      add_column :opzioni_operazioni_ammesse, Integer, default: 0
      drop_column :tipo_oggetto
    end
  end
end
