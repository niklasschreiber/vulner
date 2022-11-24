# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170423
#

module Irma
  #
  module Web
    #
    class App < Roda
      def list_reti_competenza
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        fs = filtro[:sistemi] || filtro_sistemi
        Db::Sistema.select(:rete_id).distinct.where(id: fs).map do |record|
          { id: record[:rete_id], full_descr: Constant.label(:rete, record[:rete_id]) }
        end
      end

      def list_reti_per_vendor_releases # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        if filtro[:vendor_releases]
          Db::VendorRelease.select(:rete_id).distinct.where(id: filtro[:vendor_releases]).map do |record|
            { id: record[:rete_id], full_descr: Constant.label(:rete, record[:rete_id]) }
          end
        else
          list_reti_competenza
        end
      end
    end

    App.route('reti') do |r|
      r.get('list') do
        handle_request { list_values_for_constants(scope: :rete) }
      end
      r.get('competenza_non_filtrate/list') do
        handle_request { records_competenza(r, :reti) }
      end
      r.get('competenza/list') do
        handle_request { list_reti_competenza }
      end
      r.get('per_vendor_releases/list') do
        handle_request { list_reti_per_vendor_releases }
      end
    end
  end
end
