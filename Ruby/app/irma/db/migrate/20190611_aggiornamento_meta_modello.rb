# vim: set fileencoding=utf-8
#
# Author:        S. Campestrini
#
# Creation Date: 20190611
#
#
#-------------------------------------------------------
Sequel.migration do
  up do
    alter_table :meta_entita do
      add_foreign_key :pid, :meta_entita, type: :Bignum
      add_index [:vendor_release_id, :naming_path], unique: true, name: 'uidx_meta_entita_vr_np'
    end

    alter_table :meta_entita_fisico do
      add_foreign_key :pid, :meta_entita_fisico, type: :Bignum
      add_index [:vendor_release_fisico_id, :naming_path], unique: true, name: 'uidx_meta_entita_fisico_vr_np'
    end

    alter_table :meta_parametri do
      set_column_type :meta_entita_id, :Bignum
    end

    alter_table :meta_parametri_fisico do
      set_column_type :meta_entita_fisico_id, :Bignum
    end
  end

  down do
    alter_table :meta_entita do
      drop_index [:vendor_release_id, :naming_path], unique: true, name: 'uidx_meta_entita_vr_np'
      drop_column :pid
    end

    alter_table :meta_entita_fisico do
      drop_index [:vendor_release_fisico_id, :naming_path], unique: true, name: 'uidx_meta_entita_fisico_vr_np'
      drop_column :pid
    end
  end
end
