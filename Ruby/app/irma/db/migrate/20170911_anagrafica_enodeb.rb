# vim: set fileencoding=utf-8

#
Sequel.migration do
  up do
    alter_table :sistemi do
      drop_column :regione_id
      add_column  :area_sistema, String, size: 5, null: false, default: SISTEMA_AREA_SISTEMA_TT
      add_index   [:descr, :area_sistema, :rete_id], unique: true, name: 'uidx_sistemi_area_rete'
    end

    [ # descr,          rete_id,   area_sistema
      ['OMCR1_FI',      RETE_GSM,  SISTEMA_AREA_SISTEMA_NO],
      ['JM20PA001_IDL', RETE_UMTS, SISTEMA_AREA_SISTEMA_S2],
      ['JM20CA001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_SA],
      ['JM20PE001_IDL', RETE_UMTS, SISTEMA_AREA_SISTEMA_AM],
      ['JM20CA001_IDL', RETE_UMTS, SISTEMA_AREA_SISTEMA_SA],
      ['OMCR1_MI',      RETE_GSM,  SISTEMA_AREA_SISTEMA_LO],
      ['OMCR1_NA',      RETE_GSM,  SISTEMA_AREA_SISTEMA_CB],
      ['OMCR1_RM',      RETE_GSM,  SISTEMA_AREA_SISTEMA_LA],
      ['OMCR1_TO',      RETE_GSM,  SISTEMA_AREA_SISTEMA_NO],
      ['OMCR1_DG',      RETE_GSM,  SISTEMA_AREA_SISTEMA_TT],
      ['rmkomc_R',      RETE_LTE,  SISTEMA_AREA_SISTEMA_LA],
      ['JNATVE001',     RETE_GSM,  SISTEMA_AREA_SISTEMA_VE],
      ['JNATTA001',     RETE_GSM,  SISTEMA_AREA_SISTEMA_TA],
      ['JNATFV001',     RETE_GSM,  SISTEMA_AREA_SISTEMA_FV],
      ['JNATER001',     RETE_GSM,  SISTEMA_AREA_SISTEMA_ER],
      ['JNATMU001',     RETE_GSM,  SISTEMA_AREA_SISTEMA_MU],
      ['tokomc_R',      RETE_LTE,  SISTEMA_AREA_SISTEMA_NO],
      ['JM20NA001_IDL', RETE_GSM,  SISTEMA_AREA_SISTEMA_S1],
      ['JRANHQ001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_TT],
      ['rmjomc_R',      RETE_LTE,  SISTEMA_AREA_SISTEMA_CB],
      ['fikomc_R',      RETE_LTE,  SISTEMA_AREA_SISTEMA_C1],
      ['JM20NA001_IDL', RETE_UMTS, SISTEMA_AREA_SISTEMA_S1],
      ['JM20PE001_IDL', RETE_GSM,  SISTEMA_AREA_SISTEMA_AM],
      ['mikomc_R',      RETE_LTE,  SISTEMA_AREA_SISTEMA_LO],
      ['JM20NA001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_S1],
      ['JM20PA001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_S2],
      ['JM20CA001_IDL', RETE_GSM,  SISTEMA_AREA_SISTEMA_SA],
      ['JNATER001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_ER],
      ['JNATFV001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_FV],
      ['JNATMU001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_MU],
      ['JNATTA001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_TA],
      ['JNATVE001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_VE],
      ['tokomc_R',      RETE_UMTS, SISTEMA_AREA_SISTEMA_NO],
      ['rmjomc_R',      RETE_UMTS, SISTEMA_AREA_SISTEMA_S1],
      ['mikomc_R',      RETE_UMTS, SISTEMA_AREA_SISTEMA_LO],
      ['rmkomc_R',      RETE_UMTS, SISTEMA_AREA_SISTEMA_LA],
      ['fikomc_R',      RETE_UMTS, SISTEMA_AREA_SISTEMA_C1],
      ['JRANHQ001',     RETE_UMTS, SISTEMA_AREA_SISTEMA_TT],
      ['JNATER001',     RETE_UMTS, SISTEMA_AREA_SISTEMA_ER],
      ['JNATMU001',     RETE_UMTS, SISTEMA_AREA_SISTEMA_MU],
      ['JNATVE001',     RETE_UMTS, SISTEMA_AREA_SISTEMA_VE],
      ['JNATFV001',     RETE_UMTS, SISTEMA_AREA_SISTEMA_FV],
      ['JNATTA001',     RETE_UMTS, SISTEMA_AREA_SISTEMA_TA],
      ['JM20PE001',     RETE_LTE,  SISTEMA_AREA_SISTEMA_AM],
      ['JM20PA001_IDL', RETE_GSM,  SISTEMA_AREA_SISTEMA_S2]
    ].each do |descr, rete_id, area_sistema|
      run "UPDATE sistemi SET area_sistema = '#{area_sistema}' where descr = '#{descr}' and rete_id = #{rete_id}"
    end

    drop_table :regioni

    create_table :anagrafica_enodeb do
      primary_key :id
      String      :enodeb_name,               null: false, size: 128
      String      :enodeb_id,                 null: false, size: 128
      String      :area_territoriale,         null: false, size: 5

      DateTime    :created_at
      DateTime    :updated_at

      index [:enodeb_id],   unique: true, name: 'uidx_anagrafica_enodeb_enodeb_id'
      index [:enodeb_name], unique: true, name: 'uidx_anagrafica_enodeb_enodeb_name'
    end
  end

  down do
    drop_table :anagrafica_enodeb

    create_table :regioni do                                         # regione
      primary_key :id                                                # id_regione
      String      :nome,                 size: 32, null: false       # codice_regione
      String      :descr,                size: 64, null: false       # descrizione
      column      :lista_province,       'json'                      # lista delle sigle provincia

      DateTime    :created_at
      DateTime    :updated_at

      index       [:nome], unique: true, name: 'uidx_regioni'
    end

    alter_table :sistemi do
      drop_column      :area_sistema
      add_foreign_key  :regione_id, :regioni
      add_index        [:descr, :regione_id, :rete_id], unique: true, name: 'uidx_sistemi_regione_rete'
    end
  end
end
