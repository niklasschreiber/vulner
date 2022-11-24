# vim: set fileencoding=utf-8
#
# Author:        R. Scandale
#
# Creation Date: 20181107
#
#
#-------------------------------------------------------
Sequel.migration do
  up do
    alter_table :meta_parametri_fisico do
      add_column :is_prioritario, :boolean, default: true
    end
  end

  down do
    alter_table :meta_parametri_fisico do
      drop_column :is_prioritario
    end
  end
end
