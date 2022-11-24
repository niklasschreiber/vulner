# vim: set fileencoding=utf-8
#
# Author       : R. Arcaro, G. Cristelli
#
# Creation date: 20170531
#

module Irma
  #
  module Web
    #
    class App < Roda
      def attivita_schedulata_import_adrn(parametri, opts = {}) # rubocop:disable Metrics/AbcSize
        vr = Db::VendorRelease.get_by_pk(parametri['vendor_release_id'])
        opts.update(input_file:        post_locfile_to_shared_fs(locfile: parametri['impUploadFile'], dir: opts[:attivita_schedulata_dir]),
                    filtro_release:    [vr.descr, vr.vendor.nome, vr.rete.nome].join(','),
                    id_vendor_release: vr.id,
                    vr_descr:          vr.descr)
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_IMPORT_ADRN, opts)
      end

      def attivita_schedulata_export_adrn(parametri, opts = {})
        filtro = JSON.parse(parametri['filtro'] || '{}')
        opts.update(id_vendor_release: [filtro['vendor_releases']].flatten.join(','),
                    vr_descr:          Db::VendorRelease.where(id: filtro['vendor_releases']).map(&:full_descr).join(', '),
                    out_dir_root:      DIR_ATTIVITA_TAG)
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_EXPORT_ADRN, opts)
      end

      def attivita_schedulata_ricerca_incongruenze_metamodello_fisico(parametri, opts = {})
        lista_vr_id = parametri['vendor_releases_id']
        raise 'Vendor Release non specificata' if lista_vr_id.nil? || lista_vr_id.empty?
        lista_id = lista_vr_id.to_s.split(',').map { |sss| sss }
        vr = Db::VendorReleaseFisico.where(id: lista_id).all
        raise "Vendor Release non valida (#{vr_id})" unless vr
        opts.update(lista_vr_id:  lista_id, out_dir_root: DIR_ATTIVITA_TAG)
        Db::TipoAttivita.crea_attivita_schedulata(TIPO_ATTIVITA_RICERCA_INCONGRUENZE_METAMODELLO_FISICO, opts)
      end
    end

    App.route('adrn') do |r|
      r.post('import/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_import_adrn(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('export/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_export_adrn(parametri, opzioni_attivita_schedulata)
        end
      end
      r.post('ricerca_incongruenze_metamodello_fisico/schedula') do
        schedula_attivita do |parametri, opzioni_attivita_schedulata|
          attivita_schedulata_ricerca_incongruenze_metamodello_fisico(parametri, opzioni_attivita_schedulata)
        end
      end
    end
  end
end
