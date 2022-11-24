# vim: set fileencoding=utf-8

#
Sequel.migration do
  #              NEW                                                 OLD
  change do
    create_table :reti do                                            # rete
      Integer     :id,                   primary_key: true           # id_rete
      String      :nome,                 size: 32, null: false       # rete
      String      :descr,                size: 64, null: false       # desc_rete
      String      :alias,                size: 32, null: false       # nuovo campo per memorizzare 2G, 3G, 4G, ....

      DateTime    :created_at
      DateTime    :updated_at

      index       [:nome], unique: true, name: 'uidx_reti'
    end

    create_table :regioni do                                         # regione
      primary_key  :id                                               # id_regione
      String      :nome,                 size: 32, null: false       # codice_regione
      String      :descr,                size: 64, null: false       # descrizione
      column      :lista_province,       'json'                      # lista delle sigle provincia

      DateTime    :created_at
      DateTime    :updated_at

      index       [:nome], unique: true, name: 'uidx_regioni'
    end

    create_table :vendors do
      Integer     :id,                   primary_key: true           # id_tec
      String      :nome,                 size: 32, null: false       # desc_tec
      String      :sigla,                size: 32, null: false       # tec_code

      DateTime    :created_at
      DateTime    :updated_at

      index       [:sigla], unique: true, name: 'uidx_vendors'
    end

    create_table :vendor_releases do                                 # tec_rel
      primary_key  :id                                               # id_tecrel
      String      :descr,                size: 256, null: false      # desc_rel
      foreign_key :vendor_id,            :vendors,  null: false      # mapping di id_tec, desc_tec, e tec_code in vendors
      foreign_key :rete_id,              :reti,     null: false      # id_rete
      column      :formato_audit,        'json'
      String      :nodo_naming_path,     size: 256
      String      :cella_naming_path,    size: 256
      column      :release_di_nodo,      'json'
      column      :header_pr,            'json'

      DateTime    :created_at
      DateTime    :updated_at

      index [:descr, :vendor_id, :rete_id], unique: true, name: 'uidx_vendor_releases'
    end

    create_table :omc_fisici do                                      # nuova tabella per gestire il campo sistema.nome_omc_fis
      primary_key :id
      String      :nome,            size: 64, null: false
      foreign_key :vendor_id,       :vendors, null: false
      column      :formato_audit,   'json'
      String      :nome_file_audit

      DateTime    :created_at
      DateTime    :updated_at

      index       [:nome], unique: true, name: 'uidx_omc_fisici'
    end

    create_table :sistemi do                                         # sistema
      primary_key  :id                                               # id_sistema
      String      :descr, null: false                                # nome_sistema
      String      :nome_file_audit
      column      :header_pr,                           'json'       # lista dei campi di progetto radio

      foreign_key :vendor_release_id, :vendor_releases, null: false  # id_tecrel
      foreign_key :omc_fisico_id, :omc_fisici,          null: false  # mapping di nome_omc_fis in omc_fisici.id
      foreign_key :regione_id, :regioni,                null: false  # id_regione
      foreign_key :rete_id, :reti,                      null: false  # id_rete

      DateTime    :created_at
      DateTime    :updated_at

      index [:descr, :vendor_release_id],    unique: true, name: 'uidx_sistemi'
      index [:descr, :regione_id, :rete_id], unique: true, name: 'uidx_sistemi_regione_rete'
    end

    create_table :progetti_irma do
      primary_key   :id
      foreign_key   :sistema_id,               :sistemi
      foreign_key   :omc_fisico_id,            :omc_fisici
      foreign_key   :account_id,               :accounts, null: false
      String        :nome,                     size: 256, null: false
      Integer       :count_entita,             null: false, default: 0
      column        :parametri_input,          'json'
      String        :ambiente,                 size: 10, null: false
      String        :archivio,                 size: 10, null: false

      DateTime      :created_at
      DateTime      :updated_at

      index         [:account_id, :nome], unique: true, name: 'uidx_progetti_irma_account_nome'
    end

    create_table :report_comparativi do
      primary_key :id
      foreign_key   :sistema_id,               :sistemi
      foreign_key   :omc_fisico_id,            :omc_fisici
      foreign_key   :account_id,               :accounts, null: false
      String        :nome,                     size: 256, null: false
      Integer       :count_entita,             null: false, default: 0
      column        :archivio_1,               'json' # contiene i riferimenti per riferire un saa: ambiente archivio nome_progetto_irma
      column        :archivio_2,               'json'
      String        :ambiente,                 size: 10, null: false

      DateTime      :created_at
      DateTime      :updated_at

      index         [:account_id, :nome], unique: true, name: 'uidx_report_comparativi_account_nome'
    end

    create_table :tipi_segnalazioni do
      Integer     :id, primary_key: true
      foreign_key :funzione_id, :funzioni
      String      :categoria,                size: 256, null: false
      String      :nome,                     size: 256, null: false
      String      :descr,                    text: true
      String      :azione_recovery,          text: true
      Integer     :gravita,                  null: false
      String      :identificativo_messaggio, size: 256, null: false
      Boolean     :to_update_adrn,           null: false, default: false
      Integer     :genere_per_update

      DateTime    :created_at
      DateTime    :updated_at

      index [:funzione_id, :categoria, :nome], unique: true, name: 'uidx_tipi_segnalazioni'
    end

    create_table :segnalazioni do
      primary_key  :id,                          type: :Bignum
      foreign_key  :tipo_segnalazione_id,        :tipi_segnalazioni, null: false
      foreign_key  :funzione_id,                 :funzioni, null: false
      foreign_key  :profilo_id,                  :profili
      Integer      :attivita_id
      Integer      :gravita,                     null: false
      String       :meta_entita,                 size: 256
      String       :naming_path,                 size: 1024
      String       :meta_parametro,              size: 256
      Integer      :linea_file
      Integer      :account_id,                  null: false # dovrebbe essere una foreign key ma per problemi di test conviene lasciarlo libero
      String       :account_desc,                size: 256
      Integer      :utente_id,                   null: false # dovrebbe essere una foreign key ma per problemi di test conviene lasciarlo libero
      foreign_key  :progetto_irma_id,            :progetti_irma
      foreign_key  :report_comparativo_id,       :report_comparativi
      String       :messaggio,                   text: true
      String       :dettaglio,                   text: true
      Integer      :secondi_da_inizio_esecuzione
      Integer      :sistema_id                   # dovrebbe essere una foreign key ma per problemi di test conviene lasciarlo libero
      Integer      :omc_fisico_id                # dovrebbe essere una foreign key ma per problemi di test conviene lasciarlo libero
      Integer      :vendor_release_id            # dovrebbe essere una foreign key ma per problemi di test conviene lasciarlo libero
      String       :ambiente,                    size: 10
      String       :archivio,                    size: 10
      Boolean      :to_update_adrn,              null: false, default: false

      DateTime     :created_at
      DateTime     :updated_at

      index [:attivita_id],           name: 'idx_segnalazioni_attivita'
      index [:account_id],            name: 'idx_segnalazioni_account'
      index [:utente_id],             name: 'idx_segnalazioni_utente'
      index [:sistema_id],            name: 'idx_segnalazioni_sistema'
      index [:omc_fisico_id],         name: 'idx_segnalazioni_omc_fisico'
      index [:progetto_irma_id],      name: 'idx_segnalazioni_progetto_irma'
      index [:report_comparativo_id], name: 'idx_segnalazioni_report_comparativo'
      index [:vendor_release_id],     name: 'idx_segnalazioni_vendor_release_id'
    end

    create_table :meta_entita do
      primary_key   :id
      foreign_key   :vendor_release_id,        :vendor_releases, null: false
      String        :nome,                     size: 256,  null: false
      String        :naming_path,              size: 1024, null: false
      String        :descr,                    text: true
      String        :tipo,                     size: 10, null: false, default: META_ENTITA_TIPO_CHAR
      String        :versione,                 size: 24
      String        :extra_name,               size: 256

      # { default: [reg0,..., regN], release_nodoX: [reg0,..., regM], release_nodoY: [reg0,..., regP],...}
      # N,M,P possono essere 0 o >0 a seconda che la regola sia multi...
      # le chiavi release_nodo... possono esserci
      column        :regole_calcolo,           'json' # regole di calcolo
      # { reteK: {default: [...], release_nodo: [...]}, reteH: ...}
      column        :regole_calcolo_ae,        'json' # regole calcolo adiacenze esterne
      String        :rete_adj,                 size: 24
      String        :meta_entita_ref,          size: 1024
      Integer       :fase_di_calcolo
      Integer       :operazioni_ammesse,         default: OPERAZIONI_AMMESSE_NESSUNA
      Integer       :opzioni_operazioni_ammesse, default: 0
      Integer       :tipo_adiacenza,             default: TIPO_ADIACENZA_NESSUNA

      DateTime      :created_at
      DateTime      :updated_at
    end

    create_table :meta_parametri do
      primary_key  :id
      foreign_key  :vendor_release_id,         :vendor_releases, null: false
      foreign_key  :meta_entita_id,            :meta_entita, null: false
      String       :nome,                      size: 256, null: false
      String       :nome_struttura,            size: 256
      Boolean      :is_multivalue,             default: false
      Boolean      :is_multistruct,            default: false
      String       :descr,                     text: true
      String       :tipo,                      size: 10, null: false, default: META_PARAMETRO_TIPO_CHAR
      Integer      :genere,                    null: false, default: META_PARAMETRO_GENERE_SEMPLICE

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
    end

    create_table :progetti_radio do
      primary_key :id
      String      :nome_cella,                 null: false, size: 128
      String      :cgi,                        null: false, size: 128
      String      :nome_nodo,                  size: 128
      String      :release_nodo,               size: 128
      foreign_key :omc_fisico_id,              :omc_fisici
      foreign_key :sistema_id,                 :sistemi
      column      :header,                     'json'
      column      :valori,                     'json'

      DateTime    :created_at
      DateTime    :updated_at

      index [:nome_cella], unique: true, name: 'uidx_progetti_radio_nome_cella'
      index [:sistema_id],               name: 'idx_progetti_radio_sistema_id'
      index [:omc_fisico_id],            name: 'idx_progetti_radio_omc_fisico_id'
    end
  end
end
