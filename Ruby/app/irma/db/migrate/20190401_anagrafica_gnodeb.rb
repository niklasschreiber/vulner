# vim: set fileencoding=utf-8
#
# Author:        R. Scandale
#
# Creation Date: 20190401
#
#
#-------------------------------------------------------
Sequel.migration do
  up do
    create_table :anagrafica_gnodeb do
      primary_key :id
      String      :gnodeb_name,               null: false, size: 128
      String      :gnodeb_id,                 null: false, size: 128
      String      :area_territoriale,         null: false, size: 5

      DateTime    :created_at
      DateTime    :updated_at

      index [:gnodeb_id],   unique: true, name: 'uidx_anagrafica_gnodeb_gnodeb_id'
      index [:gnodeb_name], unique: true, name: 'uidx_anagrafica_gnodeb_gnodeb_name'
    end
  end

  down do
    drop_table :anagrafica_gnodeb
  end
end
