# vim: set fileencoding=utf-8

#
Sequel.migration do
  up do
    create_table :anagrafica_cgi do
      primary_key :id
      String      :nome_cella, null: false, size: 128
      Integer     :rete_id,    null: false
      String      :regione,    null: false, size: 32
      String      :lac,        null: false, size: 32
      String      :ci,         null: false, size: 6

      DateTime    :created_at
      DateTime    :updated_at

      index [:nome_cella], unique: true, name: 'uidx_anag_cgi_nome_cella'
    end

    create_table :ci_regioni do
      primary_key :id
      Integer     :rete_id,  null: false
      String      :regione,  null: false, size: 32
      String      :ci,       null: false, size: 6
      Integer     :busy,     null: false, default: CI_REGIONE_BUSY_NO

      DateTime    :created_at
      DateTime    :updated_at

      index [:rete_id, :regione, :ci], unique: true, name: 'uidx_ci_regioni_rete_regione_ci'
    end
  end

  down do
    drop_table :ci_regioni
    drop_table :anagrafica_cgi
  end
end
