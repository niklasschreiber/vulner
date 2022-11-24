# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

module Irma
  module Db
    # rubocop:disable Metrics/ClassLength
    class OmcFisico < Model(:omc_fisici)
      plugin :timestamps, update_on_create: true

      def self.cache_enabled?
        !@cache_disabled
      end

      def self.aggiorna_vendor_release_fisico_da_logico
        aggiornati = 0
        each { |omc| aggiornati += 1 if omc.aggiorna_vendor_release_fisico_da_logico }
        aggiornati
      end

      def self.tipo_competenza
        TIPO_COMPETENZA_OMCFISICO
      end

      def tipo_competenza
        self.class.tipo_competenza
      end

      def competenza
        { tipo_competenza => id.to_s }
      end

      def omc_con_gemelli
        tutti_i_gemelli = []
        sistemi_per_omc_fisico.each do |mio_sistema_id|
          tutti_i_gemelli += Sistema.sistemi_gemelli_ids(mio_sistema_id).first
        end
        Sistema.where(id: tutti_i_gemelli.compact.uniq).select_map(:omc_fisico_id).uniq
      end

      def aggiorna_vendor_release_fisico_da_logico
        old_vrfid = vendor_release_fisico_id

        vr_for_descr = VendorRelease.where(id: vendor_release_id).order(:created_at).last
        new_vrfid = if vr_for_descr
                      vrf = VendorReleaseFisico.first(vendor_id: vendor_id, descr: vr_for_descr.descr)
                      vrf.id if vrf
                    end
        update(vendor_release_fisico_id: new_vrfid) if (aggiorna = old_vrfid != new_vrfid)
        aggiorna
      end

      def province
        tot = []
        Sistema.where(omc_fisico_id: id).map { |ss| tot |= Irma::AnagraficaTerritoriale.province_per_as(ss.area_sistema) }
        tot
      end

      def after_create
        super
        entita.each(&:create_table)
        crea_empty_pi
      end

      def before_create
        omcfc_vendor = OmcFisicoCompleto.first(id: omc_fisico_completo_id).vendor_id
        self.vendor_id ||= omcfc_vendor
        raise 'Vendor diverso da vendor del proprio omc_fisico_completo' if vendor_id != omcfc_vendor
        super
      end

      COLUMNS_NO_CHANGEABLE = [:vendor_id].freeze
      def before_update
        # non posso cambiare vendor_id
        x = (COLUMNS_NO_CHANGEABLE & changed_columns)
        raise "Non e' consentito modificare il/i campo/i (#{x}) di un #{self.class}" unless x.empty?
        # posso cambiare omc_fisico_completo solo se stesso vendor
        raise 'OmcFisicoCompleto ha vendor non compatibile' if changed_columns.include?(:omc_fisico_completo_id) && vendor_id != OmcFisicoCompleto.first(id: omc_fisico_completo_id).vendor_id
        super
      end

      def before_destroy # rubocop:disable Metrics/AbcSize
        raise "OmcFisico #{id} (#{nome}) utilizzato da almeno un sistema" if sistemi.count > 0
        entita.each(&:drop_table)
        Segnalazione.where(omc_fisico_id: id).delete
        [ProgettoIrma, ReportComparativo].each { |klass| klass.where(omc_fisico_id: id).each(&:destroy) }
        super
      end

      def entita(archivio: nil, **opts)
        Constant.values(:archivio).map do |carc|
          next unless archivio.nil? || carc == archivio
          next if carc == ARCHIVIO_ECCEZIONI || carc == ARCHIVIO_LABEL
          EntitaOmcFisico.new(archivio: carc, vendor: vendor_id, omc_fisico: nome, omc_fisico_id: id, **opts)
        end.flatten.compact
      end

      def descr
        nome
      end

      def full_descr
        @full_descr ||= "#{nome} (#{vendor.nome})"
      end

      def str_descr
        @str_descr ||= "#{nome}_#{vendor.nome}"
      end

      def vendor
        @vendor ||= Vendor.find(id: vendor_id)
      end

      def conta_records_entita(archivio: nil, **_opts)
        res = {}
        entita(archivio: archivio).each do |ent|
          res[ent.table_name] = { archivio: ent.archivio, records: ent.dataset.count }
        end
        res
      end

      def sistemi
        @sistemi ||= Sistema.where(omc_fisico_id: id).all
      end

      def sistemi_per_omc_fisico
        sistemi.map(&:id)
      end

      def vendor_release_id
        @vendor_release_id ||= sistemi.sort_by(&:rete_id).map(&:vendor_release_id).uniq
      end

      def vendor_release_id_da_vrf
        vrf_descr = Db::VendorReleaseFisico.where(id: vendor_release_fisico_id).select_map(:descr).first
        if vrf_descr
          Db::VendorRelease.where(id: vendor_release_id).where("descr = '#{vrf_descr}'").select_map(:id)
        else
          vendor_release_id
        end
      end

      def vendor_release_fisico
        VendorReleaseFisico.get_by_pk(vendor_release_fisico_id)
      end

      def nodo_naming_path
        vendor_release_id.map do |id|
          VendorRelease.get_by_pk(id).nodo_naming_path_real
        end.uniq
      end

      def crea_empty_pi
        return if ProgettoIrma.where(nome: PI_EMPTY_OMCFISICO, omc_fisico_id: id).first
        input = { nome: PI_EMPTY_OMCFISICO,
                  par_input: { 'tipo_sorgente' => 1, 'sorgente' => entita(ambiente: AMBIENTE_PROG, archivio: ARCHIVIO_RETE).first.table_name, 'per_omcfisico' => id,
                               'descr_sorgente' => "Archivio Rete Omc Fisico #{descr}" }
        }
        ProgettoIrma.create(nome: input[:nome], omc_fisico_id: id, ambiente: AMBIENTE_PROG, archivio: ARCHIVIO_RETE, parametri_input: input[:par_input])
      end

      def self.conta_entita(print_table: true)
        rows = []
        order(:vendor_id, :nome).all.each do |s|
          s.conta_records_entita.each do |_t_name, t_info|
            rows << [s.full_descr, t_info[:ambiente], t_info[:archivio], t_info[:records]]
          end
        end
        puts Terminal::Table.new(headings: %w(OmcFisico Ambiente Archivio Records), rows: rows).to_s if print_table
        rows
      end

      def metamodello(**opts)
        @metamodello = vendor_release_fisico.metamodello(**opts)
      end

      def metamodello_da_logico(**opts)
        @metamodello = MetaModello.meta_modello_merged(vendor_release_id_list: vendor_release_id_da_vrf, is_fisico: false, **opts)
      end

      def vendor_instance
        @vendor_instance ||= Irma::Vendor.instance(vendor: vendor_id)
      end

      def formati_audit
        @formati_audit ||= (formato_audit || vendor_instance.default_formato_audit_of)
      end

      def release_di_nodo
        @release_di_nodo ||= vendor_release_id.map do |id|
          vr = VendorRelease.get_by_pk(id)
          vr.release_di_nodo
        end.flatten.uniq
      end
    end
  end
end

# == Schema Information
#
# Tabella: omc_fisici
#
#  created_at               :datetime
#  formato_audit            :json
#  id                       :integer         non nullo, default(nextval('omc_fisici_id_seq')), chiave primaria
#  nome                     :string(64)      non nullo
#  nome_file_audit          :string
#  omc_fisico_completo_id   :integer         non nullo, riferimento a omc_fisici_completi.id
#  updated_at               :datetime
#  vendor_id                :integer         non nullo, riferimento a vendors.id
#  vendor_release_fisico_id :integer         riferimento a vendor_releases_fisico.id
#
# Indici:
#
#  uidx_omc_fisici  (nome) UNIQUE
#
