# vim: set fileencoding=utf-8
#
# Author:        S. Campestrini
#
# Creation Date: 20190716
#
#
#-------------------------------------------------------
Sequel.migration do
  up do
    # --------------------------------
    # --- not null per campi boolean
    [:meta_parametri, :meta_parametri_fisico, :audit_meta_parametri].each do |ttt|
      [:is_forced, :is_multistruct, :is_multivalue, :is_obbligatorio, :is_predefinito, :is_prioritario, :is_restricted, :is_to_export, :is_update_on_create].each do |fff|
        alter_table ttt do
          set_column_default fff, fff == :is_prioritario
        end
        run "UPDATE #{ttt} a SET #{fff} = DEFAULT WHERE #{fff} is null"
        alter_table ttt do
          set_column_not_null fff
        end
      end
    end
    [:etichette_eccezioni_eliminate, :etichette_eccezioni].each do |ttt|
      alter_table ttt do
        set_column_not_null :eccezioni_nette
      end
    end
    # ------------------------
    # --- omc_fisico_completo
    create_table :omc_fisici_completi do
      primary_key :id
      String      :nome,            size: 64, null: false
      foreign_key :vendor_id,       :vendors, null: false

      DateTime    :created_at
      DateTime    :updated_at

      index       [:nome], unique: true, name: 'uidx_omc_fisici_completi'
    end

    run 'INSERT INTO omc_fisici_completi(nome, vendor_id, created_at, updated_at) SELECT nome, vendor_id, CURRENT_TIMESTAMP(0), CURRENT_TIMESTAMP(0) FROM omc_fisici'

    alter_table :omc_fisici do
      add_foreign_key :omc_fisico_completo_id, :omc_fisici_completi
    end

    run 'UPDATE omc_fisici a SET omc_fisico_completo_id = (SELECT b.id FROM omc_fisici_completi b where a.nome = b.nome)'

    alter_table :omc_fisici do
      set_column_not_null :omc_fisico_completo_id
    end

    # -----------------------------------------
    # --- sistemi
    alter_table(:sistemi) do
      drop_index [:descr, :vendor_release_id],          name: :uidx_sistemi
      drop_index [:descr, :area_sistema, :rete_id],     name: 'uidx_sistemi_area_rete'
      # --
      add_foreign_key :vendor_id, :vendors
    end

    run 'UPDATE sistemi a SET vendor_id = (SELECT b.vendor_id FROM vendor_releases b where a.vendor_release_id = b.id)'

    alter_table :sistemi do
      set_column_not_null :vendor_id
    end

    # -----------------------------------------
    # --- progetti_radio: colonna sistema_id
    alter_table(:progetti_radio) do
      drop_constraint(:progetti_radio_sistema_id_fkey)
    end
    run 'ALTER TABLE progetti_radio ALTER COLUMN sistema_id TYPE jsonb USING to_jsonb(ARRAY[sistema_id])'
    run 'CREATE INDEX idx_progetti_radio_sistema_id_gin ON progetti_radio USING gin(sistema_id);'
    # --- progetti_radio: colonna omc_fisico_id --> omc_fisico_completo_id
    alter_table(:progetti_radio) do
      drop_constraint(:progetti_radio_omc_fisico_id_fkey)
    end
    run 'UPDATE progetti_radio a SET omc_fisico_id = (SELECT b.omc_fisico_completo_id FROM omc_fisici b where a.omc_fisico_id = b.id)'
    alter_table(:progetti_radio) do
      rename_column :omc_fisico_id, :omc_fisico_completo_id
      add_foreign_key [:omc_fisico_completo_id], :omc_fisici_completi
    end
  end

  down do
    # -----------------------------------------
    # --- progetti_radio: colonna omc_fisico_id --> omc_fisico_completo_id
    alter_table(:progetti_radio) do
      drop_constraint(:progetti_radio_omc_fisico_completo_id_fkey)
    end
    run 'UPDATE progetti_radio a SET omc_fisico_completo_id = (SELECT b.omc_fisico_id FROM sistemi b where (a.sistema_id->>0)::int = b.id)'
    alter_table(:progetti_radio) do
      rename_column :omc_fisico_completo_id, :omc_fisico_id
      add_foreign_key [:omc_fisico_id], :omc_fisici
    end
    # --- progetti_radio: colonna sistema_id
    run 'DROP INDEX idx_progetti_radio_sistema_id_gin'
    run 'ALTER TABLE progetti_radio ALTER COLUMN sistema_id TYPE integer USING (sistema_id::jsonb->>0)::integer'
    alter_table(:progetti_radio) do
      add_foreign_key [:sistema_id], :sistemi, foreign_key_constraint_name: :progetti_radio_sistema_id_fkey
    end

    # -----------------------------------------
    # --- sistemi
    alter_table(:sistemi) do
      drop_column :vendor_id
      add_index [:descr, :vendor_release_id],      unique: true, name: 'uidx_sistemi'
      add_index [:descr, :area_sistema, :rete_id], unique: true, name: 'uidx_sistemi_area_rete'
    end
    # ------------------------
    # --- omc_fisico_completo
    alter_table :omc_fisici do
      drop_foreign_key :omc_fisico_completo_id
    end

    drop_table :omc_fisici_completi
  end
end
