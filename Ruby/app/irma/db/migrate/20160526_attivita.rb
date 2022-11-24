# vim: set fileencoding=utf-8
#
# Author: G. Cristelli, S. Campestrini
#
# Creation Date: 20160208
#
#
#-------------------------------------------------------
Sequel.migration do
  #
  change do
    #
    create_table :servers do
      primary_key :id
      String      :nome,                null: false, size: 128
      String      :host,                null: false, size: 128
      Integer     :porta,               null: false
      String      :descr,               text: true,  default: ''
      String      :stato,               string: 32,  default: SERVER_STATO_ATTIVO
      DateTime    :data_ultima_verifica
      String      :msg_ultima_verifica, text: true
      DateTime    :created_at
      DateTime    :updated_at
      #
      index       [:nome], unique: true, name: 'uidx_servers_nome'
      index       [:host, :porta], unique: true, name: 'uidx_servers_host_porta'
    end

    #
    create_table :tipi_attivita do
      Integer     :id,              primary_key: true
      String      :nome,            null: false, size: 128
      String      :descr,           text: true, default: ''
      String      :kind
      String      :stato,           size: 32, default: TIPO_ATTIVITA_STATO_ATTIVO
      Boolean     :broadcast,       null: false, default: false
      Boolean     :singleton,       null: false, default: false
      DateTime    :created_at
      DateTime    :updated_at
      #
      index       [:kind], unique: true, name: 'uidx_tipo_attivita_kind'
    end

    create_table :attivita_schedulate do
      primary_key :id
      String      :descr,           text: true
      String      :periodo,         size: 256
      String      :stato,           size: 32, default: ATTIVITA_SCHEDULATA_STATO_ATTIVA
      String      :stato_operativo, size: 32, default: ATTIVITA_SCHEDULATA_STATO_OPERATIVO_IN_ATTESA
      column      :cronologia_stato_operativo, 'json' # [ [stato_init,time], [nuovo_stato, time],...]
      DateTime    :inizio_validita
      DateTime    :fine_validita
      # [
      # {key: 'a00', label: 'Root',          competenze: {sistema: ['1','3'], omc_fisico: ['4']}},
      # {key: 'a01', label: 'Import',        pid: 'a00', competenze: {sistema: ['1','3'], omc_fisico: ['4']}},
      # {key: 'a02', label: 'Import S1',     pid: 'a01', info_comando: [cmd, param1, v1,..., paramN, vN], dipende_da: [], competenze: {sistema: ['1'], omc_fisico: ['4']}},
      # {key: 'a03', label: 'Import S2',     pid: 'a01', info_comando: [cmd, param1, v1,..., paramN, vN], dipende_da: [], competenze: {sistema: ['3'], omc_fisico: ['4']}},
      # {key: 'a04', label: 'Export totale', pid: 'a00', info_comando: [cmd1, param1, v1,..., paramN, vN], dipende_da: ['a01'], competenze: {sistema: ['1', '3'], omc_fisico: ['4']}},
      # {key: 'a05', label: 'Altro',         pid: 'a00', info_comando: [cmd2, param1, v1,..., paramN, vN], dipende_da: [], competenze: {}},
      # ]
      foreign_key :tipo_attivita_id, :tipi_attivita, null: false
      column      :opts_info_attivita, 'json', null: false
      column      :competenze,    'json' # join di tutti i campi competenze di info_attivita

      String      :archivio,      size: 10
      String      :ambiente,      size: 10
      foreign_key :account_id,    :accounts
      foreign_key :utente_id,     :utenti
      foreign_key :profilo_id,    :profili

      DateTime    :created_at
      DateTime    :updated_at
    end

    create_table :attivita do
      primary_key :id, type: :Bignum
      String      :kind
      String      :descr,        text: true
      String      :esecutore,    size: 128
      String      :stato,        size: 32, default: ATTIVITA_STATO_PENDENTE
      column      :cronologia_stato, 'json' # [ [stato_init,time], [nuovo_stato, time],...]
      Integer     :peso
      Integer     :pid
      foreign_key :root_id, :attivita, type: :Bignum
      String      :dir, size: 256
      foreign_key :attivita_schedulata_id, :attivita_schedulate
      column      :info_comando, 'json' # [comando, param1, val_param1,..., paramN, val_paramN]
      column      :dipende_da,   'json' # [id_attivita_1, id_attivita_2, ..., id_attivita_N] array di id attivita da eseguire prima
      column      :competenze,   'json'
      DateTime    :ack_time
      DateTime    :start_time
      DateTime    :end_time
      Integer     :durata

      # contatori per le attivita non foglie
      Integer     :foglie_totali, default: 0
      column      :foglie_stato_finale, 'json'

      column      :risultato,    'json'
      column      :artifacts,    'json'
      Integer     :num_retry,    default: 0
      Integer     :max_retry,    default: 3

      String      :archivio,      size: 10
      String      :ambiente,      size: 10
      foreign_key :account_id,    :accounts
      foreign_key :utente_id,     :utenti
      foreign_key :profilo_id,    :profili

      Integer     :expire_sec
      DateTime    :created_at
      DateTime    :updated_at

      index       [:root_id],                name: 'idx_attivita_root_id'
      index       [:stato],                  name: 'idx_attivita_stato'
      index       [:account_id],             name: 'idx_attivita_account'
      index       [:attivita_schedulata_id], name: 'idx_attivita_attivita_schedulata'
    end
  end
end
