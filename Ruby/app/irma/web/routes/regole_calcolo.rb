# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20171207
#

module Irma
  #
  module Web
    #
    class App < Roda
      def _json_levels_regole_calcolo # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        res = {}
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        vr = Db::VendorRelease.first(id: filtro[:vendor_release_id])
        raise 'Nessuna Vendor Release specificata (vendor_release_id)' unless vr
        fs = id_sistemi_di_competenza_filtrati
        fs &= JSON.parse(request.params['filter_sistemi_id']).map(&:to_i) if request.params['filter_sistemi_id']
        vr_sistemi_filtrati = []
        vr_sistemi = []
        Db::Sistema.all_using_cache.values.map do |record|
          vr_sistemi_filtrati << record[:vendor_release_id] if fs.include?(record[:id])
          vr_sistemi << record[:vendor_release_id]
        end
        vr_sistemi_filtrati.uniq!
        vr_sistemi.uniq!
        sess = logged_in
        reti = sess.data[:valori_competenza][:reti].map { |v| v[:id] }
        vendors = sess.data[:valori_competenza][:vendors].map { |v| v[:id] }
        vendor_releases = []
        release_nodo = []
        meta_obj = filtro[:meta_parametro_id] ? Db::MetaParametro.first(id: filtro[:meta_parametro_id]) : Db::MetaEntita.first(id: filtro[:meta_entita_id])
        regole = if meta_obj
                   filtro[:campo_regola] == 'regole_calcolo_ae' ? meta_obj[:regole_calcolo_ae] : meta_obj[:regole_calcolo]
                 else
                   {}
                 end
        regole ||= {}
        regole_vr = regole['rc_vendor_release'] || {}
        Db::VendorRelease.all_using_cache.values.map do |record|
          next unless vr_sistemi_filtrati.include?(record.id) ||
                      (!request.params['filter_sistemi_id'] && funzione_abilitata?(FUNZIONE_GESTIONE_ANAGRAFICA) &&
                      !vr_sistemi.include?(record.id) && reti.include?(record.rete_id) && vendors.include?(record.vendor_id))
          vendor_releases << { descr: record.descr, id: record.id } if (vr && record.descr != vr.descr) && (!regole_vr || !regole_vr[record.descr])
        end
        vendor_releases = vendor_releases.sort_by { |k| k[:descr] }
        vendor_releases = vendor_releases.uniq { |el| el[:descr] }
        regole_rn = regole['rc_release_nodo'] || {}
        if vr && vr[:release_di_nodo]
          vr[:release_di_nodo].map do |el|
            release_nodo << { descr: el, id: el } if !regole_rn || !regole_rn[el]
          end
        end
        release_nodo = release_nodo.sort_by { |k| k[:descr] }
        res['vendor_releases'] = vendor_releases
        res['release_nodo'] = release_nodo
        res
      end

      def verifica_regole_calcolo # rubocop:disable Metrics/AbcSize
        filtro = JSON.parse(request.params['filtro'] || '{}').symbolize_keys
        is_me = filtro[:id_mp].nil?
        regola = filtro[:regola]
        klass = is_me ? Db::MetaEntita : Db::MetaParametro
        obj = klass.first(id: (is_me ? filtro[:id_me] : filtro[:id_mp]))
        rpv = ValidatoreRegoleUtil::RegolaPerValidatore.new(key_1: regola['primo_livello'], key_2: regola['secondo_livello'], regola: regola['regola'])
        obj.formatta_risultato(obj.valida_regola(rpv: rpv, is_ae: filtro[:is_ae]))
      end
    end

    App.route('regole_calcolo') do |r|
      r.get('levels/json') do
        handle_request { _json_levels_regole_calcolo }
      end
      r.post('verifica') do
        handle_request { verifica_regole_calcolo }
      end
    end
  end
end
