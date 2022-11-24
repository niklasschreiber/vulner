# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation Date: 20180604
#
#
#-------------------------------------------------------
Sequel.migration do
  up do
    alter_table :vendor_releases_fisico do
      set_column_type :reti, :jsonb
      add_index [:descr, :vendor_id, :reti], unique: true, name: 'uidx_vendor_releases_fisico'
      # in futuro
      # set_column_not_null :reti
    end

    create_table :metaparametri_update_on_create do
      primary_key :id
      foreign_key :rete_id,              :reti,            null: false  # id_rete
      foreign_key :vendor_id,            :vendors,         null: false
      String      :naming_path,          size: 1024,       null: false
      String      :full_name,            size: 512,        null: false  # nome_struttura.nome
      column      :vendor_releases,      'json'
    end
  end

  down do
    alter_table :vendor_releases_fisico do
      drop_index [:descr, :vendor_id, :reti], name: 'uidx_vendor_releases_fisico'
      set_column_type :reti, :json
    end

    drop_table :metaparametri_update_on_create
  end
end
