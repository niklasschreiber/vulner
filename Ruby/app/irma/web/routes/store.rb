# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160126
#

module Irma
  #
  module Web
    #
    class App < Roda
      def list_sistemi_omc_fisici_filtrati(allow_blank: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        ofdcf = id_omc_fisici_di_competenza_filtrati
        res = allow_blank ? [{ full_descr: d = FILTRO_SISTEMI_OMC_FISICI_ALL, id: d }] : []
        records_competenza(request, :omc_fisici).sort_by { |x| x[:full_descr] }.select do |r|
          next unless ofdcf.include?(r[:id])
          formati_audit = {}
          vendor_release = Db::VendorReleaseFisico.get_by_pk(r[:vendor_release_id])
          Db::VendorRelease.where(id: Db::OmcFisico.get_by_pk(r[:id]).vendor_release_id).each { |vr| formati_audit.update((vr.formati_audit || {}).dup) }
          res << { descr: d = "[OMC FISICO] #{r[:full_descr]}", id: d, nome: r[:nome], chiave_filtro: 'omc_fisico_id',
                   valore_filtro: r[:id], formati_audit: formati_audit, vendor_release: { id: r[:vendor_release_id], descr: vendor_release.descr } }
        end
        sdcf = id_sistemi_di_competenza_filtrati
        records_competenza(request, :sistemi).sort_by { |x| x[:full_descr] }.select do |r|
          next unless sdcf.include?(r[:id])
          vr = Db::VendorRelease.get_by_pk(r[:vendor_release_id])
          res << { descr: d = "[SISTEMA] #{r[:full_descr]}", id: d, nome: "#{r[:descr]}_#{r[:rete]}",
                   chiave_filtro: 'sistema_id', valore_filtro: r[:id], formati_audit: vr.formati_audit, vendor_release: { id: r[:vendor_release_id], descr: vr.descr } }
        end
        # TODO
        # vdcf = id_vendor_releases_di_competenza_filtrati
        # records_competenza(request, :vendor_releases).sort_by { |x| x[:full_descr] }.select do |r|
        #   res << { descr: d = "[VENDOR RELEASE] #{r[:full_descr]}", id: d, nome: r[:full_descr], chiave_filtro: 'vendor_release_id', valore_filtro: r[:id] } if vdcf.include?(r[:id])
        # end
        res
      end

      def list_ambienti_secondo_profilo
        # sessione = logged_in
        res = list_values_for_constants(scope: :sessione, prefix: :ambiente, allow_blank: true, allow_blank_msg: format_msg(:STORE_TUTTI_GLI_AMBIENTI))
        # if sessione.profilo == Constant.constant(:profilo, :rp).info[:nome]
        #   res.delete(id: 'qual', descr: 'QUAL')
        # end
        # if sessione.profilo == Constant.constant(:profilo, :rq).info[:nome]
        #   res.delete(id: 'prog', descr: 'PROG')
        # end
        res
      end
    end

    App.route('store') do |r|
      verifica_sessione(r)
      r.get('ambienti/list') do
        handle_request { list_values_for_constants(scope: :sessione, prefix: :ambiente, allow_blank: true, allow_blank_msg: format_msg(:STORE_TUTTI_GLI_AMBIENTI)) }
      end
      r.get('ambienti_secondo_profilo/list') do
        handle_request { list_ambienti_secondo_profilo }
      end
      r.get('archivi_attivita/list') do
        handle_request { list_values_for_constants(scope: :attivita_archivio, allow_blank: true, allow_blank_msg: format_msg(:STORE_TUTTI_GLI_ARCHIVI)) }
      end
      r.get('archivi_no_blank/list') do
        handle_request { list_values_for_constants(scope: :archivio) }
      end
      r.get('aree_sistema/list') do
        handle_request { list_values_for_constants(scope: :sistema, prefix: :area_sistema) }
      end
      r.get('aree_territoriali/list') do
        handle_request { list_values_for_constants(scope: :anagrafica_enodeb, prefix: :area_territoriale, allow_blank: true, allow_blank_msg: format_msg(:STORE_TUTTE_LE_AREE_TERRITORIALI)) }
      end
      r.get('formato_export/list') do
        handle_request { list_values_for_constants(scope: :formato_export) }
      end
      r.get('formato_export_esteso/list') do
        handle_request { list_values_for_constants(scope: :formato_export_esteso) }
      end
      r.get('profili_utenti/list') do
        handle_request { list_values_for_constants(scope: :profilo, allow_blank: true, allow_blank_msg: format_msg(:STORE_TUTTI_I_PROFILI)) }
      end
      r.get('sistemi_omc_fisici_filtrati/list') do
        handle_request { list_sistemi_omc_fisici_filtrati }
      end
      r.get('sistemi_omc_fisici_filtrati_con_blank/list') do
        handle_request { list_sistemi_omc_fisici_filtrati(allow_blank: true) }
      end
      r.get('tipi_periodicita/list') do
        handle_request { list_values_for_constants(scope: :tipo_periodicita, allow_blank: true, allow_blank_msg: format_msg(:STORE_TUTTI_TIPI_PERIODICITA)) }
      end
    end
  end
end
