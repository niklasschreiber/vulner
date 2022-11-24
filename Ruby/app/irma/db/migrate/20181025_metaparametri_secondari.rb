# vim: set fileencoding=utf-8
#
# Author:        R. Scandale
#
# Creation Date: 20181025
#
#
#-------------------------------------------------------
Sequel.migration do
  up do
    # struttura tabella uguale a metaparametri_update_on_create, mantenerle allineate
    create_table :metaparametri_secondari do
      primary_key :id
      foreign_key :rete_id,              :reti,            null: false  # id_rete
      foreign_key :vendor_id,            :vendors,         null: false
      String      :naming_path,          size: 1024,       null: false
      String      :full_name,            size: 512,        null: false  # nome_struttura.nome
      column      :vendor_releases,      'json'
    end

    alter_table :meta_parametri do
      add_column :is_prioritario, :boolean, default: true
    end
  end

  down do
    alter_table :meta_parametri do
      drop_column :is_prioritario
    end

    drop_table :metaparametri_secondari
  end
end
