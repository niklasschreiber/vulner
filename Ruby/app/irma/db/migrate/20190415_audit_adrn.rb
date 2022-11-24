# vim: set fileencoding=utf-8

#
module Sequel
  module Postgres
    class CreateTableGenerator # Sequel::JDBC::Database
      def audit_schema_base(table)
        primary_key :id
        Boolean     :latest,           null: false, default: true
        # --------------------------
        # link a modifica precedente
        foreign_key :pid,       table
        # --------------------------
        # chi ha fatto la modifica
        String      :matricola_utente, size: 64
        String      :nome_utente,      size: 64
        String      :cognome_utente,   size: 64
        String      :profilo,          size: 64
        # --------------------------
        # quando
        DateTime    :created_at
        # --------------------------
        # come
        Integer     :operazione, null: false
        Boolean     :multipla,   null: false, default: false
        Integer     :sorgente,   null: false, default: AUDIT_SORGENTE_GUI
      end
    end
  end
end

Sequel.migration do
  down do
    drop_table :audit_meta_parametri
    drop_table :audit_meta_entita
  end

  up do
    create_table :audit_meta_entita do
      audit_schema_base(:audit_meta_entita)
      # --------------------------
      # campi identificativi oggetto
      # - vendor_release
      Integer     :rete_id, null: false
      Integer     :vendor_id, null: false
      String      :vendor_release_descr, size: 64, null: false
      # OR
      Integer     :vendor_release_id

      # - identificativo proprio
      String      :naming_path,          size: 1024, null: false
      # OR
      column      :meta_entita_id,       :Bignum    # ???
      # --------------------------
      # info oggetto
      String      :descr
      String      :extra_name,        size: 256
      Integer     :fase_di_calcolo
      String      :meta_entita_ref,   size: 1024
      String      :nome,              size: 256
      Integer     :operazioni_ammesse
      Integer     :priorita_fdc
      column      :regole_calcolo,    'json'
      column      :regole_calcolo_ae, 'json'
      String      :rete_adj,          size: 24
      String      :tipo,              size: 10
      Integer     :tipo_adiacenza
      Integer     :tipo_oggetto
      String      :versione,          size: 24
    end

    create_table :audit_meta_parametri do
      audit_schema_base(:audit_meta_parametri)
      # --------------------------
      # campi identificativi oggetto
      # - vendor_release
      Integer     :rete_id,                        null: false
      Integer     :vendor_id,                      null: false
      String      :vendor_release_descr, size: 64, null: false
      # ??? OR ???
      Integer     :vendor_release_id

      # - meta_entita
      String      :naming_path,          size: 1024, null: false
      # ??? OR ???
      column      :meta_entita_id,    :Bignum

      # - identificativo proprio
      String      :full_name,            size: 512,  null: false
      # ??? OR ???
      column      :meta_parametro_id, :Bignum # ???
      # --------------------------
      # info oggetto
      String      :nome,              size: 256
      String      :nome_struttura,    size: 256
      String      :descr
      Integer     :genere
      column      :regole_calcolo,    'json'
      column      :regole_calcolo_ae, 'json'
      String      :rete_adj,          size: 24
      column      :tags,              'json'
      String      :tipo,              size: 10
      Boolean     :is_forced
      Boolean     :is_multistruct
      Boolean     :is_multivalue
      Boolean     :is_obbligatorio
      Boolean     :is_predefinito
      Boolean     :is_prioritario
      Boolean     :is_restricted
      Boolean     :is_to_export
      Boolean     :is_update_on_create
    end
  end
end
