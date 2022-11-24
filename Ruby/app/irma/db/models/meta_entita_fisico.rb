# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180322
#

module Irma
  module Db
    #
    class MetaEntitaFisico < Model(:meta_entita_fisico)
      plugin :timestamps, update_on_create: true

      include MetaEntitaCommon

      def self.fisico?
        true
      end

      def vendor_release_fisico
        VendorReleaseFisico.first(id: vendor_release_fisico_id)
      end

      def meta_entita_logiche
        MetaEntita.where(naming_path: naming_path, vendor_release_id: vendor_release_fisico.vendor_releases).all
      end

      UPD_MEF_KEYS = [:fase_di_calcolo, :operazioni_ammesse, :tipo, :extra_name].freeze
      def self.updates_da_lista_me(me_list)
        return {} if (me_list || []).empty?
        updates = { reti: [] }
        me_list.each do |me|
          updates[:reti] << me.rete_id
          UPD_MEF_KEYS.each { |kkk| updates[kkk] ||= me[kkk] }
        end
        updates[:reti].uniq!
        updates
      end

      def aggiorna_da_me_logiche
        if meta_entita_logiche.empty?
          destroy
        else
          updates = self.class.updates_da_lista_me(meta_entita_logiche)
          update(updates) unless updates.empty?
        end
      end

      def self.lista_me_ok?(vendor_release_fisico, lista_me)
        c1 = lista_me.map(&:naming_path).uniq.count == 1
        c2 = lista_me.map(&:nome).uniq.count == 1
        c3 = (lista_me.map(&:vendor_release_id) - vendor_release_fisico.vendor_releases).empty?
        c1 && c2 && c3
      end

      def self.crea_da_me_logiche(lista_vrf:, lista_me:, check_lista_ok: true) # rubocop:disable Metrics/AbcSize
        res = []
        return res if (lista_me || []).empty?
        lista_vrf.each do |vrf|
          if check_lista_ok && !lista_me_ok?(vrf, lista_me)
            logger.error "meta_entita #{lista_me} non coerenti per creazione di meta_entita_fisico per vendor_release_fisico #{vrf.str_descr}"
            next
          end
          attributes = { vendor_release_fisico_id: vrf.id }
          [:nome, :naming_path].each { |fff| attributes[fff] = lista_me[0][fff] }
          res << create(attributes.merge(updates_da_lista_me(lista_me)))
        end
        res
      end
    end
  end
end

# == Schema Information
#
# Tabella: meta_entita_fisico
#
#  created_at               :datetime
#  descr                    :string
#  extra_name               :string(256)
#  fase_di_calcolo          :integer
#  id                       :bigint          non nullo, default(nextval('meta_entita_fisico_id_seq')), chiave primaria
#  meta_entita_ref          :string(1024)
#  naming_path              :string(1024)    non nullo
#  nome                     :string(256)     non nullo
#  operazioni_ammesse       :integer         default(0)
#  pid                      :bigint          riferimento a meta_entita_fisico.id
#  priorita_fdc             :integer         default(0)
#  regole_calcolo           :json
#  regole_calcolo_ae        :json
#  rete_adj                 :string(24)
#  reti                     :json
#  tipo                     :string(10)      non nullo, default('char')
#  tipo_adiacenza           :integer         default(0)
#  tipo_oggetto             :integer         non nullo, default(0)
#  updated_at               :datetime
#  vendor_release_fisico_id :integer         non nullo, riferimento a vendor_releases_fisico.id
#  versione                 :string(24)
#
# Indici:
#
#  idx_meta_entita_fisico_naming_path            (naming_path)
#  idx_meta_entita_fisico_nome                   (nome)
#  idx_meta_entita_fisico_vendor_release_fisico  (vendor_release_fisico_id)
#  uidx_meta_entita_fisico_vr_np                 (naming_path,vendor_release_fisico_id) UNIQUE
#
