# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation Date: 20151122
#
#

#
Sequel.migration do
  #
  change do
    #
    create_table :app_config do
      primary_key :id
      String      :modulo,               null: false, size: 128
      String      :nome,                 null: false, size: 128
      Integer     :ambito,               null: false, default: APP_CONFIG_AMBITO_GUI
      String      :valore,               null: false, text: true
      String      :valore_di_default,    null: false, text: true
      String      :widget_info,          text: true,  default: ''
      String      :descr,                text: true,  default: ''
      column      :profili,              'json'
      DateTime    :created_at
      DateTime    :updated_at
      #
      index       [:modulo, :nome], unique: true, name: 'uidx_app_config_modulo_nome'
    end

    #
    create_table :tipi_eventi do
      Integer     :id,                  primary_key: true
      String      :categoria,           size: 64, null: false
      String      :nome,                size: 64
      Integer     :gravita,             null: false
      String      :descr,               text: true
      DateTime    :created_at
      DateTime    :updated_at
      #
      index       [:nome, :categoria], unique: true, name: 'uidx_tipi_eventi'
    end

    #
    create_table :eventi do
      #
      primary_key :id, type: :Bignum
      column      :pid, :Bignum
      Integer     :gravita,               null: false
      String      :nome,                  null: false, size: 64
      String      :categoria,             null: false, size: 64
      Integer     :durata
      String      :descr,                 text: true
      foreign_key :tipo_evento_id,        :tipi_eventi, null: false, key: :id

      # alarm reference
      Integer     :id_allarme

      column      :dettaglio,             'json'

      # account fields
      String      :host,                  size: 32
      Integer     :account_id
      String      :matricola,             size: 16
      String      :profilo,               size: 32
      String      :utente_descr,          size: 64
      String      :ambiente,              size: 10

      DateTime    :created_at
      DateTime    :updated_at
      #
      index      [:nome, :categoria], name: 'idx_eventi_nome_categoria'
      index      [:id_allarme],       name: 'idx_eventi_id_allarme'
    end

    create_table :tipi_allarmi do
      Integer     :id,                     primary_key: true
      String      :categoria,              null: false, size: 64
      String      :nome,                   null: false, size: 64
      Integer     :gravita,                null: false
      String      :descr,                  text: true
      String      :formato_id_risorsa,     null: false, size: 64
      Integer     :chiusura_automatica,    null: false, default: 0
      DateTime    :created_at
      DateTime    :updated_at

      index       [:nome, :categoria], unique: true, name: 'uidx_tipi_allarmi'
    end

    [:allarmi, :allarmi_chiusi].each do |t|
      #
      create_table t do
        if t == :allarmi
          primary_key :id, type: :Bignum
        else
          column :id, :Bignum, primary_key: true
        end
        Integer     :pid
        Integer     :gravita,               null: false
        String      :categoria,             null: false,   size: 64
        String      :nome,                  null: false,   size: 64
        String      :id_risorsa,            null: false,   size: 64
        String      :descr,                 text: true
        foreign_key :tipo_allarme_id,       :tipi_allarmi, key: :id

        # event reference
        Integer     :id_evento

        # account fields
        String      :user_name,             size: 32
        String      :user_fullname,         size: 64
        String      :user_funz,             size: 32
        String      :user_type,             size: 1, default: TIPO_UTENTE_NON_AVVALORATO

        #
        Integer     :contatore,             null: false, default: 1
        Integer     :in_carico,             null: false, default: ALLARME_IN_CARICO_NO
        String      :utente_in_carico,      size: 64
        String      :note_in_carico,        text: true
        DateTime    :data_notifica
        DateTime    :data_in_carico

        if t == :allarmi_chiusi
          String      :note_chiusura, text: true
          DateTime    :data_chiusura
        end
        DateTime    :created_at
        DateTime    :updated_at

        if t == :allarmi
          index [:tipo_allarme_id, :id_risorsa], unique: true, name: "uidx_#{t}_tipo_al_ris"
        end
      end
    end

    # ------
    create_table :utenti do
      primary_key :id
      String      :matricola,           size: 64, null: false
      String      :nome,                size: 64, null: false
      String      :cognome,             size: 64, null: false
      String      :dipartimento
      String      :email
      String      :mobile
      DateTime    :created_at
      DateTime    :updated_at

      index [:matricola], unique: true, name: 'uidx_utenti_matricola'
    end

    create_table :funzioni do
      Integer     :id,                  primary_key: true
      String      :nome,                size: 64,  null: false
      String      :descr,               size: 256, null: false
      Integer     :tipo_competenza,     default: TIPO_COMPETENZA_NESSUNA
      column      :dipendenze, 'json'
      DateTime    :created_at
      DateTime    :updated_at
    end

    create_table :profili do
      Integer     :id,                  primary_key: true
      String      :nome,                size: 64, null: false
      String      :descr,               null: false, size: 255
      String      :ambiente,            null: false, size: 10
      String      :funzioni_di_default, null: false, text: true
      String      :funzioni,                         text: true
      DateTime    :created_at
      DateTime    :updated_at

      index [:nome], unique: true, name: 'uidx_profili_nome'
    end

    create_table :accounts do
      primary_key :id
      foreign_key :utente_id, :utenti, key: :id
      foreign_key :profilo_id, :profili, key: :id
      Integer     :num_tentativi_accesso_falliti, null: false, default: 0
      String      :descr,           size: 255
      String      :stato,           size: 20, null: false
      String      :competenze,      text: true
      DateTime    :data_scadenza
      DateTime    :data_ultimo_login
      DateTime    :data_ultima_attivazione
      DateTime    :data_ultima_sospensione
      DateTime    :data_ultima_disattivazione
      column      :preferenze, 'json'
      DateTime    :created_at
      DateTime    :updated_at

      index [:utente_id, :profilo_id], unique: true, name: 'uidx_accounts_utente_profilo'
    end

    %i(sessioni sessioni_chiuse).each do |t|
      create_table t do
        if t == :sessioni
          primary_key :id, type: :Bignum
        else
          column :id, :Bignum
        end
        String      :session_id,     size: 255, null: false
        String      :data,           text: true
        Integer     :account_id
        String      :matricola,      size: 32
        String      :utente_descr,   size: 32
        String      :profilo,        size: 32
        String      :ambiente,       size: 10
        String      :host,           size: 32
        String      :note,           size: 255
        DateTime    :expire_at
        DateTime    :created_at
        DateTime    :updated_at
        DateTime    :ended_at

        if t == :sessioni
          index [:session_id], unique: true, name: 'uidx_sessioni_session_id'
        end
      end
    end
  end
end
