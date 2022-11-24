# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180619
#

module Irma
  #
  module Web
    class App < Roda
      def list_competenza_vendor_releases_fisico # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        fo = id_omc_fisici_di_competenza_filtrati
        vr_omc_fisici_filtrati = []
        vr_omc_fisici = []
        Db::OmcFisico.all_using_cache.values.map do |record|
          vr_omc_fisici_filtrati << record[:vendor_release_fisico_id] if fo.include?(record[:id])
          vr_omc_fisici << record[:vendor_release_fisico_id]
        end
        vr_omc_fisici_filtrati.uniq!
        vr_omc_fisici.uniq!
        reti = logged_in.data[:valori_competenza][:reti].map { |v| v[:id] }
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        vendors = logged_in.data[:valori_competenza][:vendors].map do |v|
          v[:id] if filtro[:vendor_id].nil? || filtro[:vendor_id].include?(v[:id])
        end.compact
        res = []
        Db::VendorReleaseFisico.all_using_cache.values.each do |record|
          next unless vendors.include?(record.vendor_id) && !record.unused? && (vr_omc_fisici_filtrati.include?(record.id) ||
                      (funzione_abilitata?(FUNZIONE_GESTIONE_ANAGRAFICA) && !vr_omc_fisici.include?(record.id) &&
                      !(reti & record.reti).empty?))
          res << { full_descr: record.full_descr, id: record.id, descr: record.descr }
        end
        res.sort_by { |k| k[:full_descr] }
      end
    end

    App.route('vendor_releases_fisico') do |r|
      r.get('competenza/list') do
        handle_request { list_competenza_vendor_releases_fisico }
      end
    end
  end
end
