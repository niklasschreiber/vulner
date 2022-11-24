# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20190326
#

require 'irma/db/audit_model_support'

module Irma
  module Db
    #
    class AuditMetaEntita < Model(:audit_meta_entita)
      plugin :timestamps, update_on_create: true
      include AuditModule

      def self.record_da_object(meta_entita) # rubocop:disable Metrics/AbcSize
        record = {}
        fields_me = meta_entita.is_a?(MetaEntita) ? meta_entita.values : meta_entita
        (columns - [:id, :created_at, :pid]).each { |ccc| record[ccc] = fields_me[ccc] if fields_me.keys.include?(ccc) }
        record[:meta_entita_id] = fields_me[:id]
        vr = VendorRelease.get_by_pk(fields_me[:vendor_release_id])
        record[:rete_id] = vr.rete_id
        record[:vendor_id] = vr.vendor_id
        record[:vendor_release_descr] = vr.descr

        record
      end

      def where_condition_same_object
        # meta_entita_id OR (naming_path AND rete_id AND vendor_id AND vendor_release_descr)
        id_condition = "meta_entita_id = #{meta_entita_id}" if meta_entita_id
        id_condition_flatten = "(naming_path = '#{naming_path}' AND rete_id = #{rete_id} AND vendor_id = #{vendor_id} AND vendor_release_descr = '#{vendor_release_descr}')"
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
# Tabella: audit_meta_entita
#
#  cognome_utente       :string(64)
#  created_at           :datetime
#  descr                :string
#  extra_name           :string(256)
#  fase_di_calcolo      :integer
#  id                   :integer         non nullo, default(nextval('audit_meta_entita_id_seq')), chiave primaria
#  latest               :boolean         non nullo, default(true)
#  matricola_utente     :string(64)
#  meta_entita_id       :bigint
#  meta_entita_ref      :string(1024)
#  multipla             :boolean         non nullo, default(false)
#  naming_path          :string(1024)    non nullo
#  nome                 :string(256)
#  nome_utente          :string(64)
#  operazione           :integer         non nullo
#  operazioni_ammesse   :integer
#  pid                  :integer         riferimento a audit_meta_entita.id
#  priorita_fdc         :integer
#  profilo              :string(64)
#  regole_calcolo       :json
#  regole_calcolo_ae    :json
#  rete_adj             :string(24)
#  rete_id              :integer         non nullo
#  sorgente             :integer         non nullo, default(0)
#  tipo                 :string(10)
#  tipo_adiacenza       :integer
#  tipo_oggetto         :integer
#  vendor_id            :integer         non nullo
#  vendor_release_descr :string(64)      non nullo
#  vendor_release_id    :integer
#  versione             :string(24)
#
