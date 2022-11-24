# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180322
#

module Irma
  module Db
    #
    class MetaParametroFisico < Model(:meta_parametri_fisico)
      plugin :timestamps, update_on_create: true

      include MetaParametroCommon

      def self.fisico?
        true
      end

      def before_create
        self.full_name ||= [nome_struttura, nome].compact.join('.')
        super
      end

      UPD_MPF_KEYS = [:descr, :tipo, :genere,
                      :is_to_export, :is_obbligatorio, :is_forced, :is_restricted,
                      :is_multivalue, :is_multistruct, :is_update_on_create, :is_prioritario].freeze
      def self.updates_da_lista_mp(mp_list)
        return {} if (mp_list || []).empty?
        updates = { reti: [] }
        mp_list.each do |mp|
          updates[:reti] << mp.rete_id
          UPD_MPF_KEYS.each { |kkk| updates[kkk] ||= mp[kkk] }
        end
        updates[:reti].uniq!
        updates
      end

      def self.lista_mp_ok?(mef_id, lista_mp)
        c1 = lista_mp.map(&:full_name).uniq.count == 1
        c2 = (lista_mp.map(&:meta_entita_id) - MetaEntitaFisico.first(id: mef_id).meta_entita_logiche.map(&:id)).empty?
        c1 && c2
      end

      def self.crea_da_mp_logici(mef_id:, lista_mp:, vrf_id: nil, check_lista_ok: true)
        return if (lista_mp || []).empty?
        if check_lista_ok && !lista_mp_ok?(mef_id, lista_mp)
          logger.error "meta_parametri #{lista_mp} non coerenti per creazione di meta_parametro_fisico per meta_entita_fisico #{mef_id}"
          return
        end

        vrf_idid = vrf_id || MetaEntitaFisico.first(id: mef_id).vendor_release_fisico_id
        attributes = { vendor_release_fisico_id: vrf_idid, meta_entita_fisico_id: mef_id }
        [:nome, :nome_struttura, :full_name].each { |fff| attributes[fff] = lista_mp[0][fff] }
        create(attributes.merge(updates_da_lista_mp(lista_mp)))
      end

      def meta_parametri_logici
        mef = MetaEntitaFisico.first(id: meta_entita_fisico_id)
        return [] unless mef
        MetaParametro.where(meta_entita_id: mef.meta_entita_logiche.map(&:id), full_name: full_name).all
      end

      def aggiorna_da_mp_logici
        if meta_parametri_logici.empty?
          destroy
        else
          updates = self.class.updates_da_lista_mp(meta_parametri_logici)
          update(updates) unless updates.empty?
        end
      end
    end
  end
end

# == Schema Information
#
# Tabella: meta_parametri_fisico
#
#  created_at               :datetime
#  descr                    :string
#  full_name                :string(512)
#  genere                   :integer         non nullo, default(1)
#  id                       :bigint          non nullo, default(nextval('meta_parametri_fisico_id_seq')), chiave primaria
#  is_forced                :boolean         non nullo, default(false)
#  is_multistruct           :boolean         non nullo, default(false)
#  is_multivalue            :boolean         non nullo, default(false)
#  is_obbligatorio          :boolean         non nullo, default(false)
#  is_predefinito           :boolean         non nullo, default(false)
#  is_prioritario           :boolean         non nullo, default(true)
#  is_restricted            :boolean         non nullo, default(false)
#  is_to_export             :boolean         non nullo, default(false)
#  is_update_on_create      :boolean         non nullo, default(false)
#  meta_entita_fisico_id    :bigint          non nullo, riferimento a meta_entita_fisico.id
#  nome                     :string(256)     non nullo
#  nome_struttura           :string(256)
#  regole_calcolo           :json
#  regole_calcolo_ae        :json
#  rete_adj                 :string(24)
#  reti                     :json
#  tags                     :json
#  tipo                     :string(10)      non nullo, default('char')
#  updated_at               :datetime
#  vendor_release_fisico_id :integer         non nullo, riferimento a vendor_releases_fisico.id
#
# Indici:
#
#  idx_meta_parametri_fisico_full_name              (full_name)
#  idx_meta_parametri_fisico_meta_entita_fisico     (meta_entita_fisico_id)
#  idx_meta_parametri_fisico_vendor_release_fisico  (vendor_release_fisico_id)
#
