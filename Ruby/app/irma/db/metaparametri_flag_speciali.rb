# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20181029
#

module Irma
  module Db
    #
    module MetaparametroFlagSpeciali
      extends_host_with :ClassMethods
      #
      module ClassMethods
        def cleanup(_hash = {})
          cleanup_only_rebuild_indexes
        end

        def aggiorna_flag_metaparametri(id_vendor_release: nil, flag:, default_value:, new_value:) # rubocop:disable Metrics/AbcSize
          MetaParametro.transaction do
            updated_at_time = Time.now
            query = MetaParametro
            query = query.where(vendor_release_id: id_vendor_release) if id_vendor_release
            query.where(flag => new_value).update(flag => default_value)
            each do |mp|
              vr_id = mp.vendor_releases_id
              vr_id &= [id_vendor_release.to_i].flatten if id_vendor_release
              next if vr_id.empty?
              MetaEntita.where(naming_path: mp.naming_path, vendor_release_id: vr_id).each do |me|
                MetaParametro.where(full_name: mp.full_name, meta_entita_id: me.id).update(flag => new_value, updated_at: updated_at_time)
              end
            end
          end
        end

        def aggiorna_flag_metaparametri_fisici(flag:, default_value:, new_value:)
          MetaParametroFisico.transaction do
            updated_at_time = Time.now
            MetaParametroFisico.where(flag => new_value).update(flag => default_value)
            each do |mp|
              vr_id = mp.vendor_releases_id(fisico: true)
              next if vr_id.empty?
              MetaEntitaFisico.where(naming_path: mp.naming_path, vendor_release_fisico_id: vr_id).each do |me|
                MetaParametroFisico.where(full_name: mp.full_name, meta_entita_fisico_id: me.id).update(flag => new_value, updated_at: updated_at_time)
              end
            end
          end
        end
      end

      def fisico?
        self.class.fisico?
      end

      VENDOR_RELEASES_SEP = ','.freeze

      def vendor_releases_id(fisico: false) # rubocop:disable Metrics/AbcSize
        @vendor_releases_id ||= begin
                                  query = if fisico
                                            Db::VendorReleaseFisico.where(vendor_id: vendor_id).where("reti::jsonb @> '[#{rete_id}]'")
                                          else
                                            Db::VendorRelease.where(rete_id: rete_id, vendor_id: vendor_id)
                                          end
                                  query = query.where(descr: vendor_releases.join(VENDOR_RELEASES_SEP).tr('*', '%').split(VENDOR_RELEASES_SEP)) unless vendor_releases.to_s.empty?
                                  query.select_map(:id)
                                end
      end
    end
  end
end
