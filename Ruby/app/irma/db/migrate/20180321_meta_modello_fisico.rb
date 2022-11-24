# vim: set fileencoding=utf-8

#
Sequel.migration do
  down do
    drop_table :meta_parametri_fisico
    drop_table :meta_entita_fisico

    alter_table :omc_fisici do
      drop_column :vendor_release_fisico_id
    end

    drop_table :vendor_releases_fisico

    alter_table :report_comparativi do
      drop_column :info
    end

    alter_table :meta_entita do
      drop_index   [:vendor_release_id], name: 'idx_meta_entita_vendor_release'
      drop_index   [:naming_path], name: 'idx_meta_entita_naming_path'
      drop_index   [:nome], name: 'idx_meta_entita_nome'
    end

    alter_table :meta_parametri do
      drop_index   [:vendor_release_id], name: 'idx_meta_parametri_vendor_release'
      drop_index   [:meta_entita_id], name: 'idx_meta_parametri_meta_entita'
      drop_index   [:full_name], name: 'idx_meta_parametri_full_name'
    end
  end

  up do
    alter_table :meta_entita do
      add_index   [:vendor_release_id], name: 'idx_meta_entita_vendor_release'
      add_index   [:naming_path], name: 'idx_meta_entita_naming_path'
      add_index   [:nome], name: 'idx_meta_entita_nome'
    end

    alter_table :meta_parametri do
      add_index   [:vendor_release_id], name: 'idx_meta_parametri_vendor_release'
      add_index   [:meta_entita_id], name: 'idx_meta_parametri_meta_entita'
      add_index   [:full_name], name: 'idx_meta_parametri_full_name'
    end

    create_table :vendor_releases_fisico do
      primary_key :id
      String      :descr,                size: 256, null: false
      foreign_key :vendor_id,            :vendors,  null: false
      column      :formato_audit,        'json'
      String      :nodo_naming_path,     size: 256
      String      :cella_naming_path,    size: 256
      column      :release_di_nodo,      'json'
      column      :header_pr,            'json'

      DateTime    :created_at
      DateTime    :updated_at

      index [:descr, :vendor_id], unique: true, name: 'uidx_vendor_releases_fisico'
    end

    alter_table :omc_fisici do
      add_foreign_key :vendor_release_fisico_id, :vendor_releases_fisico, not_valid: true
    end

    create_table :meta_entita_fisico do
      primary_key   :id
      foreign_key   :vendor_release_fisico_id,        :vendor_releases_fisico, null: false
      String        :nome,                     size: 256,  null: false
      String        :naming_path,              size: 1024, null: false
      String        :descr,                    text: true
      String        :tipo,                     size: 10, null: false, default: META_ENTITA_TIPO_CHAR
      String        :versione,                 size: 24
      String        :extra_name,               size: 256
      column        :reti,                     'json' # array di rete_id
      column        :regole_calcolo,           'json' # regole di calcolo
      column        :regole_calcolo_ae,        'json' # regole calcolo adiacenze esterne
      String        :rete_adj,                 size: 24
      String        :meta_entita_ref,          size: 1024
      Integer       :fase_di_calcolo
      Integer       :operazioni_ammesse,         default: OPERAZIONI_AMMESSE_NESSUNA
      Integer       :opzioni_operazioni_ammesse, default: 0
      Integer       :tipo_adiacenza,             default: TIPO_ADIACENZA_NESSUNA

      DateTime      :created_at
      DateTime      :updated_at

      index   [:vendor_release_fisico_id], name: 'idx_meta_entita_fisico_vendor_release_fisico'
      index   [:naming_path], name: 'idx_meta_entita_fisico_naming_path'
      index   [:nome], name: 'idx_meta_entita_fisico_nome'
    end

    create_table :meta_parametri_fisico do
      primary_key  :id
      foreign_key  :vendor_release_fisico_id,  :vendor_releases_fisico, null: false
      foreign_key  :meta_entita_fisico_id,     :meta_entita_fisico, null: false
      String       :nome,                      size: 256, null: false
      String       :nome_struttura,            size: 256
      Boolean      :is_multivalue,             default: false
      Boolean      :is_multistruct,            default: false
      String       :descr,                     text: true
      String       :tipo,                      size: 10, null: false, default: META_PARAMETRO_TIPO_CHAR
      Integer      :genere,                    null: false, default: META_PARAMETRO_GENERE_SEMPLICE
      column       :reti,                      'json' # array di rete_id

      column        :regole_calcolo,           'json' # regole di calcolo
      column        :regole_calcolo_ae,        'json' # regole calcolo adiacenze esterne
      String        :rete_adj,                 size: 24
      Boolean       :is_predefinito,           default: false
      Boolean       :is_to_export,             default: false
      Boolean       :is_obbligatorio,          default: false
      Boolean       :is_restricted,            default: false
      Boolean       :is_forced,                default: false
      column        :tags,                     'json' # classi
      String        :full_name,                size: 512 # nome_struttura.nome

      DateTime      :created_at
      DateTime      :updated_at

      index   [:vendor_release_fisico_id], name: 'idx_meta_parametri_fisico_vendor_release_fisico'
      index   [:meta_entita_fisico_id], name: 'idx_meta_parametri_fisico_meta_entita_fisico'
      index   [:full_name], name: 'idx_meta_parametri_fisico_full_name'
    end

    alter_table :attivita do
      set_column_type :pid, :Bignum
    end

    alter_table :report_comparativi do
      add_column :info, :json
    end
  end
end
