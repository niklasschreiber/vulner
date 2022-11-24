# vim: set fileencoding=utf-8
#
# Author: C. Pinali
#
# Creation Date: 20171013
#
#
#-------------------------------------------------------
Sequel.migration do
  #
  up do
    alter_table :meta_entita do
      drop_column :opzioni_operazioni_ammesse
      add_column  :tipo_oggetto, Integer, default: 0, null: false
    end

    alter_table :meta_parametri do
      add_column :is_update_on_create, :boolean, default: false
    end

    alter_table :progetti_irma do
      set_column_allow_null :account_id
    end
  end

  down do
    alter_table :progetti_irma do
      set_column_not_null :account_id
    end

    alter_table :meta_parametri do
      drop_column :is_update_on_create
    end

    alter_table :meta_entita do
      add_column :opzioni_operazioni_ammesse, Integer, default: 0
      drop_column :tipo_oggetto
    end
  end
end
