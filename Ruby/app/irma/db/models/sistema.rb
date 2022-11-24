# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

require 'terminal-table'

module Irma
  module Db
    # rubocop:disable Metrics/ClassLength
    class Sistema < Model(:sistemi)
      plugin :timestamps, update_on_create: true
      plugin :columns_updated

      # many_to_one :vendor_release, class: full_class_for_model(:VendorRelease)
      # many_to_one  :omc_fisico,     class: full_class_for_model(:OmcFisico)
      # many_to_one  :rete,           class: full_class_for_model(:Rete)

      validates_constant :area_sistema

      def self.cleanup(_hash = {}) # rubocop:disable Metrics/AbcSize
        res = { rebuild_indexes: {} }
        start_time = Time.now
        order(:id).each do |s|
          start_time1 = Time.now
          res[:rebuild_indexes][s.full_descr] = {
            rebuild: rebuild_indexes(tables: (s.entita(archivio: ARCHIVIO_ECCEZIONI) + s.entita(archivio: ARCHIVIO_LABEL)).map(&:table_name)),
            elapsed: (Time.now - start_time1).round(1)
          }
        end
        res[:elapsed] = (Time.now - start_time).round(1)
        res
      end

      def self.cache_enabled?
        !@cache_disabled
      end

      def self.load_in_cache(force = false)
        super(force)
        # OmcFisico.load_in_cache(force)
        VendorReleaseFisico.load_in_cache(force)
      end

      def self.pubblica_sulla_coda(coda, opts = {})
        super(coda, opts.reject { |k, _v| %i(header_pr).include?(k) })
      end

      def self.sistemi_gemelli(s_id = nil)
        res = []
        (s_id ? where(id: s_id) : where('1=1')).each { |sss| res << sss.sistemi_gemelli }
        res.uniq
      end

      def self.sistemi_gemelli_ids(s_id = nil)
        sistemi_gemelli(s_id).map { |aaa| aaa.map(&:id).sort }
      end

      # Torna 'true' se tutti gli id contenuti in array_ids_sistemi sono id di sistemi tutti gemelli tra loro
      def self.sistemi_gemelli?(array_ids_sistemi)
        return true if (array_ids_sistemi || []).empty?

        sistemi_ids = where(id: array_ids_sistemi).select_map(:id)
        return false unless sistemi_ids.size == array_ids_sistemi.size # qualche id in array non e' id di sistema
        return true if array_ids_sistemi.size == 1

        aaa = sistemi_gemelli_ids(array_ids_sistemi[0]).first
        array_ids_sistemi.all? { |xx| aaa.include?(xx) }
      end

      def self.tipo_competenza
        TIPO_COMPETENZA_SISTEMA
      end

      def tipo_competenza
        self.class.tipo_competenza
      end

      def competenza
        { tipo_competenza => id.to_s }
      end

      def before_create # rubocop:disable Metrics/AbcSize
        vr = VendorRelease.first(id: vendor_release_id)
        self.vendor_id = vr.vendor_id
        self.rete_id = vr.rete_id

        raise "Violata univocita'(nome_sistema, rete, omc_fisico)" if Sistema.where(descr: descr, rete_id: rete_id, omc_fisico_id: omc_fisico_id).exclude(id: id).first
        raise 'omc_fisico(partizione) non valido per vendor non corrispondente' if OmcFisico.first(id: omc_fisico_id).vendor_id != vendor_id

        if (ENV['IRMA_SISTEMI_GEMELLI'] || '0') == '1'

        else
          omcfc_id = omc_fisico_completo.id
          if Sistema.where(descr: descr, rete_id: rete_id, vendor_id: vendor_id, omc_fisico_id: OmcFisico.where(omc_fisico_completo_id: omcfc_id).map(&:id)).exclude(id: id).first
            raise 'Inibita creazione di sistemi gemelli'
          end
        end
        super
      end

      def after_create
        super
        entita.each(&:create_table)
        crea_empty_pi
        ProgettoRadio.aggiorna_sistema_id(id)
        VendorReleaseFisico.aggiornamento_fisico_da_logico(omc_fisico_id) if omc_fisico_id
      end

      COLUMNS_NO_CHANGEABLE = [:id, :descr, :rete_id, :vendor_id].freeze
      def before_update # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        x = (COLUMNS_NO_CHANGEABLE & changed_columns)
        raise "Non e' consentito modificare il/i campo/i (#{x}) di un Sistema" unless x.empty?

        @id_omc_fisici_changed = nil
        if changed_columns.member?(:vendor_release_id) || changed_columns.member?(:omc_fisico_id)
          old_values = Db::Sistema.first(id: id)
          # vendor_release_id
          if changed_columns.member?(:vendor_release_id)
            vr = Db::VendorRelease.first(id: vendor_release_id)
            raise 'Modifica di vendor_release non valida' if vr.nil? || vr.rete_id != old_values.rete_id || vr.vendor_id != old_values.vendor_id
          end
          if changed_columns.member?(:omc_fisico_id)
            raise 'Modifica di omc_fisico(partizione) non valida per vendor non corrispondenti' if OmcFisico.first(id: omc_fisico_id).vendor_id != vendor_id
          end
          @id_omc_fisici_changed = [old_values[:omc_fisico_id], omc_fisico_id]
        end
        super
      end

      def after_update # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        super
        if columns_updated.include?(:vendor_release_id)
          entita.each do |eee|
            next if (eee.is_a?(EntitaEccezione) || eee.is_a?(EntitaLabel)) && !@azzera_dati_ade
            eee.dataset.truncate
          end
        end
        vendor_release.update(header_pr: (vendor_release.header_pr || {}).merge(header_pr))
        omc_changed_list = @id_omc_fisici_changed || []
        omc_changed_list.compact.uniq.each { |id_omc| VendorReleaseFisico.aggiornamento_fisico_da_logico(id_omc) }
        pubblica_sulla_coda(PUB_CACHE, action: 'update', delay: 1) unless omc_changed_list.empty?
        @id_omc_fisici_changed = nil
        true
      end

      def before_destroy
        entita.each(&:drop_table)
        Segnalazione.where(sistema_id: id).delete
        [ProgettoRadio, ProgettoIrma, ReportComparativo].each { |klass| klass.cancella_sistema(id) }
        begin
          Account.each(&:aggiorna_sistemi_nelle_competenze)
        rescue => e
          logger.error("Fallito aggiornamento sistemi nelle competenze degli account a seguito di eliminazione del sistema #{full_descr} (#{id}): #{e}")
        end
        super
      end

      def vendor
        @vendor ||= vendor_release.vendor
      end

      def vendor_id
        vendor.id
      end

      def rete
        @rete ||= Rete.get_by_pk(rete_id)
      end

      def omc_fisico
        OmcFisico.get_by_pk(omc_fisico_id)
      end

      def omc_fisico_completo
        OmcFisicoCompleto.get_by_pk(omc_fisico.omc_fisico_completo_id)
      end

      def vendor_release
        VendorRelease.get_by_pk(vendor_release_id)
      end

      def sistemi_gemelli
        Sistema.where(descr: descr, rete_id: rete_id, vendor_id: vendor_id).map do |sss|
          sss if sss.omc_fisico_completo.id == omc_fisico_completo.id
        end.compact
      end

      def release_di_nodo
        vendor_release.release_di_nodo
      end

      def azzera_dati_ade(azzera: true)
        @azzera_dati_ade ||= azzera
      end

      def entita(ambiente: nil, archivio: nil, **opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        ent = Constant.values(:ambiente).map do |camb|
          next unless ambiente.nil? || camb == ambiente
          Constant.values(:archivio).map do |carc|
            next unless archivio.nil? || carc == archivio
            next if carc == ARCHIVIO_ECCEZIONI || carc == ARCHIVIO_LABEL
            Entita.new(ambiente: camb, archivio: carc, vendor: vendor_id, rete: rete_id, omc_logico: descr, omc_logico_id: id, **opts)
          end
        end
        ent << EntitaEccezione.new(archivio: ARCHIVIO_ECCEZIONI, vendor: vendor_id, rete: rete_id, omc_logico: descr, omc_logico_id: id, **opts) if archivio.nil? || archivio == ARCHIVIO_ECCEZIONI
        ent << EntitaLabel.new(archivio: ARCHIVIO_LABEL, vendor: vendor_id, rete: rete_id, omc_logico: descr, omc_logico_id: id, **opts) if archivio.nil? || archivio == ARCHIVIO_LABEL
        ent.flatten.compact
      end

      def sigla_retevendor
        Db::Rete.first(id: rete_id).alias + Db::Vendor.first(id: vendor_id).sigla
      end

      def full_descr
        @full_descr ||= "#{descr} (#{rete.nome} #{vendor.nome}, #{vendor_release.descr})"
      end

      def str_descr
        @str_descr ||= "#{descr}_#{rete.nome}_#{vendor.nome}_#{vendor_release.descr}"
      end

      def metamodello(**opts)
        vendor_release.metamodello(**opts)
      end

      def conta_records_entita(ambiente: nil, archivio: nil)
        res = {}
        entita(ambiente: ambiente, archivio: archivio).each do |ent|
          res[ent.table_name] = { ambiente: ent.ambiente, archivio: ent.archivio, records: ent.dataset.count }
        end
        res
      end

      def self.conta_entita(print_table: true)
        rows = []
        order(:rete_id, :descr).all.each do |s|
          s.conta_records_entita.each do |_t_name, t_info|
            rows << [s.full_descr, t_info[:ambiente], t_info[:archivio], t_info[:records]]
          end
        end
        puts Terminal::Table.new(headings: %w(Sistema Ambiente Archivio Records), rows: rows).to_s if print_table
        rows
      end

      def nodo_naming_path
        [vendor_release.nodo_naming_path_real]
      end

      def cella_naming_path
        vendor_release.cella_naming_path_real
      end

      def crea_empty_pi
        return if ProgettoIrma.where(nome: PI_EMPTY_OMCLOGICO, sistema_id: id).first
        input = { nome: PI_EMPTY_OMCLOGICO,
                  par_input: { 'tipo_sorgente' => 0, 'sorgente' => entita(ambiente: AMBIENTE_PROG, archivio: ARCHIVIO_RETE).first.table_name, 'per_omcfisico' => nil,
                               'descr_sorgente' => "Archivio Rete Omc Logico #{descr}" }
        }
        ProgettoIrma.create(nome: input[:nome], sistema_id: id, ambiente: AMBIENTE_PROG, archivio: ARCHIVIO_RETE, parametri_input: input[:par_input])
      end

      def vendor_instance
        vendor_release.vendor_instance
      end

      def province
        AnagraficaTerritoriale.province_per_as(area_sistema)
      end

      def regioni
        AnagraficaTerritoriale.regioni_per_as(area_sistema)
      end

      def at
        AnagraficaTerritoriale.at_di_as(area_sistema)
      end

      def noa
        AnagraficaTerritoriale.noa_di_as(area_sistema)
      end

      def filtri_consistency_check
        vendor_release.filtri_consistency_check
      end
    end
  end
end

# == Schema Information
#
# Tabella: sistemi
#
#  area_sistema      :string(5)       non nullo, default('TT')
#  created_at        :datetime
#  descr             :string          non nullo
#  header_pr         :json
#  id                :integer         non nullo, default(nextval('sistemi_id_seq')), chiave primaria
#  nome_file_audit   :string
#  omc_fisico_id     :integer         non nullo, riferimento a omc_fisici.id
#  rete_id           :integer         non nullo, riferimento a reti.id
#  updated_at        :datetime
#  vendor_id         :integer         non nullo, riferimento a vendors.id
#  vendor_release_id :integer         non nullo, riferimento a vendor_releases.id
#
