# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20190326
#

module Irma
  module Db
    class AuditMetaParametro < Model(:audit_meta_parametri)
      plugin :timestamps, update_on_create: true

      include AuditModule

      def self.record_da_object(object) # rubocop:disable Metrics/AbcSize
        record = {}
        fields_mp = object.is_a?(MetaParametro) ? object.values : object
        (columns - [:id, :created_at]).each { |ccc| record[ccc] = fields_mp[ccc] if fields_mp.keys.include?(ccc) }
        record[:meta_parametro_id] = fields_mp[:id]
        vr = VendorRelease.get_by_pk(fields_mp[:vendor_release_id])
        record[:rete_id] = vr.rete_id
        record[:vendor_id] = vr.vendor_id
        record[:vendor_release_descr] = vr.descr
        me = MetaEntita.get_by_pk(fields_mp[:meta_entita_id])
        record[:naming_path] = me.naming_path
        record
      end

      def where_condition_same_object
        id_condition = "meta_parametro_id = #{meta_parametro_id}" if meta_parametro_id
        id_condition_flatten = "(full_name = '#{full_name}' AND"
        id_condition_flatten += " naming_path = '#{naming_path}' AND rete_id = #{rete_id} AND vendor_id = #{vendor_id} AND vendor_release_descr = '#{vendor_release_descr}')"
        if id_condition
          "#{id_condition} OR #{id_condition_flatten}"
        else
          id_condition_flatten
        end
      end
    end
  end
end

# == Schema Information
#
# Tabella: audit_meta_parametri
#
#  cognome_utente       :string(64)
#  created_at           :datetime
#  descr                :string
#  full_name            :string(512)     non nullo
#  genere               :integer
#  id                   :integer         non nullo, default(nextval('audit_meta_parametri_id_seq')), chiave primaria
#  is_forced            :boolean         non nullo, default(false)
#  is_multistruct       :boolean         non nullo, default(false)
#  is_multivalue        :boolean         non nullo, default(false)
#  is_obbligatorio      :boolean         non nullo, default(false)
#  is_predefinito       :boolean         non nullo, default(false)
#  is_prioritario       :boolean         non nullo, default(true)
#  is_restricted        :boolean         non nullo, default(false)
#  is_to_export         :boolean         non nullo, default(false)
#  is_update_on_create  :boolean         non nullo, default(false)
#  latest               :boolean         non nullo, default(true)
#  matricola_utente     :string(64)
#  meta_entita_id       :bigint
#  meta_parametro_id    :bigint
#  multipla             :boolean         non nullo, default(false)
#  naming_path          :string(1024)    non nullo
#  nome                 :string(256)
#  nome_struttura       :string(256)
#  nome_utente          :string(64)
#  operazione           :integer         non nullo
#  pid                  :integer         riferimento a audit_meta_parametri.id
#  profilo              :string(64)
#  regole_calcolo       :json
#  regole_calcolo_ae    :json
#  rete_adj             :string(24)
#  rete_id              :integer         non nullo
#  sorgente             :integer         non nullo, default(0)
#  tags                 :json
#  tipo                 :string(10)
#  vendor_id            :integer         non nullo
#  vendor_release_descr :string(64)      non nullo
#  vendor_release_id    :integer
#
