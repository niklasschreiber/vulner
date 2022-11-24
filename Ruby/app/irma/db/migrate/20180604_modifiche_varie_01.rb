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
    alter_table :eventi do
      add_column :attivita_id, :Bignum
    end

    alter_table :vendor_releases do
      add_column :cc_filtro_release, :json
      add_column :cc_filtro_parametri, File
    end

    alter_table :vendor_releases_fisico do
      drop_index [:vendor_releases_fisico], name: 'uidx_vendor_releases_fisico'
      add_column :reti, :json
      # in futuro
      # set_column_not_null :reti
      # add_index [:descr, :vendor_id, :reti], unique: true, name: 'uidx_vendor_releases_fisico'
    end

    %i(meta_entita meta_entita_fisico).each do |t|
      alter_table t do
        add_column :priorita_fdc, Integer, default: 0
      end
    end
  end

  down do
    %i(meta_entita meta_entita_fisico).each do |t|
      alter_table t do
        drop_column :priorita_fdc
      end
    end

    alter_table :vendor_releases_fisico do
      add_index [:descr, :vendor_id], unique: true, name: 'uidx_vendor_releases_fisico'
      drop_column :reti
    end

    alter_table :vendor_releases do
      drop_column :cc_filtro_release
      drop_column :cc_filtro_parametri
    end

    alter_table :eventi do
      drop_column :attivita_id
    end
  end
end
