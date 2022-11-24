# vim: set fileencoding=utf-8

#
Sequel.migration do
  up do
    %i(etichette_eccezioni etichette_eccezioni_eliminate).each do |t|
      create_table t do
        if t == :etichette_eccezioni
          primary_key :id, type: :Bignum
        else
          column :id, :Bignum
        end
        String      :nome,                  null: false, size: 128
        Integer     :tipo,                  null: false
        String      :descr,                 text: true
        Integer     :account_id,            null: false
        String      :matricola,             size: 32
        String      :utente_descr,          size: 32
        String      :matricola_creatore,    size: 32
        String      :utente_creatore_descr, size: 32
        String      :profilo,               size: 32
        Boolean     :eccezioni_nette,       default: false
        column      :variazioni,            'json'
        DateTime    :data_ultimo_import
        DateTime    :created_at
        DateTime    :updated_at
        DateTime    :ended_at

        if t == :etichette_eccezioni
          index [:nome], unique: true, name: 'uidx_etich_eccez_nome'
        end
      end
    end
  end

  down do
    drop_table :etichette_eccezioni_eliminate
    drop_table :etichette_eccezioni
  end
end
