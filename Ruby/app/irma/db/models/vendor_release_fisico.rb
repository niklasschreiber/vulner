# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

module Irma
  module Db
    # rubocop:disable Metrics/ClassLength
    class VendorReleaseFisico < Model(:vendor_releases_fisico)
      plugin :timestamps, update_on_create: true

      one_to_many :omc_fisici, class: full_class_for_model(:OmcFisico)

      def self.cache_enabled?
        !@cache_disabled
      end

      def self.load_in_cache(force = false)
        super(force)
        OmcFisico.load_in_cache(force)
      end

      def self.pubblica_sulla_coda(coda, opts = {})
        super(coda, opts.reject { |k, _v| %i(header_pr).include?(k) })
      end

      # ------------------------------------------------------------------------------------
      def self.group_vr_list(vr_id_list) # rubocop:disable Metrics/AbcSize
        ret = {} # <descr>_<vendor_id>: [rete_id1,...]
        (vr_id_list || []).each do |vr_id|
          vr = VendorRelease.first(id: vr_id)
          next unless vr
          key = [vr.descr, vr.vendor_id.to_s].join('-')
          ret[key] ||= { descr: vr.descr, vendor_id: vr.vendor_id, reti: [] }
          ret[key][:reti] << vr.rete_id
          ret[key][:reti].sort!
          ret[key][:created_at] = vr.created_at if vr.created_at > (ret[key][:created_at] || Time.at(0))
        end
        ret
      end

      def self.aggiornamento_da_vendor_releases(omc_id = nil) # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
        ret = { vr_fisico_trovate: [], vr_fisico_nuove: [], omc_fisico_aggiornati: 0 }
        omc_list = omc_id ? [OmcFisico.first(id: omc_id.to_i)] : OmcFisico.all
        omc_list.each do |omc_f|
          # puts "OmcFisico: #{omc_f.full_descr}:"
          vr_id_list = (omc_f.sistemi || []).map(&:vendor_release_id).uniq
          grouped_vr = group_vr_list(vr_id_list)
          # puts "         vr_id_list: #{vr_id_list}"
          # puts "         grouped_vr: #{grouped_vr}"

          vr_f = nil
          date = Time.at(0)
          grouped_vr.each do |_k, vr|
            next unless vr[:created_at] > date
            date = vr[:created_at]
            vr_f = vr
          end
          # puts "         vr_f: #{vr_f}"

          if vr_f
            x = VendorReleaseFisico.where(descr: vr_f[:descr], vendor_id: vr_f[:vendor_id]).where("reti::text = '[#{reti_to_str(vr_f[:reti])}]'").first
            if x.nil?
              x = VendorReleaseFisico.create(descr: vr_f[:descr], vendor_id: vr_f[:vendor_id], reti: vr_f[:reti].sort)
              ret[:vr_fisico_nuove] << x[:id]
            end
            ret[:vr_fisico_trovate] |= [x[:id]]
          else
            x = {} # per annullare vendor_release_fisico_id di omc_fisico senza vendor_release (sistemi)
          end
          if omc_f.vendor_release_fisico_id != x[:id]
            omc_f.update(vendor_release_fisico_id: x[:id])
            ret[:omc_fisico_aggiornati] += 1
          end
        end
        ret
      end

      def self.reti_to_str(array_reti = nil)
        (array_reti || []).join(ARRAY_VAL_SEP + ' ')
      end

      def reti_to_str
        self.class.reti_to_str(reti)
      end

      def reti_obj
        reti.map { |r_id| Rete.first(id: r_id) }
      end

      def unused?
        return true if reti_to_str.to_s.empty? # per eliminare quelle senza reti...
        # vendor_releases.empty? &&
        # MetaParametroFisico.where(vendor_release_fisico_id: id).count == 0 &&
        # MetaEntitaFisico.where(vendor_release_fisico_id: id).count == 0 &&
        OmcFisico.where(vendor_release_fisico_id: id).count == 0
      end

      def self.remove_unused
        tot = 0
        each do |vrf|
          next unless vrf.unused?
          MetaParametroFisico.where(vendor_release_fisico_id: vrf.id).delete
          MetaEntitaFisico.where(vendor_release_fisico_id: vrf.id).delete
          vrf.destroy
          tot += 1
        end
        tot
      end

      def self.aggiornamento_fisico_da_logico(omc_id = nil)
        # aggiornamento_da_vendor_releases: per ogni omc_fisico, deduce vr_fisica, eventualmente la crea e la associa a omc
        ret = aggiornamento_da_vendor_releases(omc_id)
        # per ogni vrf aggiorna metamodello_fisico
        where(id: ret[:vr_fisico_trovate]).each(&:aggiorna_metamodello_da_logico)
        # se aggiornamento totale (omc_id == nil) rimuove vrf unused
        ret[:vr_fisico_cancellate] = remove_unused if omc_id.nil?
        ret
      end
      # ------------------------------------------------------------------------------------

      def before_destroy
        raise "VendorReleaseFisico #{id} (#{descr}) utilizzata da almeno un omc_fisico" if omc_fisici.count > 0
        [MetaParametroFisico, MetaEntitaFisico].each { |klass| klass.where(vendor_release_fisico_id: id).delete }
        super
      end

      def metamodello(**opts)
        MetaModello.new(is_fisico: true).carica_da_db(self, **opts)
      end

      def vendor_releases
        qqq = VendorRelease.where(descr: descr, vendor_id: vendor_id)
        qqq = qqq.where("rete_id in (#{reti_to_str})") if reti_to_str && !reti_to_str.empty?
        @vendor_releases ||= qqq.select_map(:id)
      end

      def vendor
        @vendor ||= vendor_id ? Vendor.get_by_pk(vendor_id) : nil
      end

      def full_descr
        @full_descr ||= "#{descr} (#{vendor.nome}_#{reti_obj.map(&:nome).join('-')})"
      end

      def terna
        @terna ||= [descr, vendor.nome, reti_obj.map(&:nome).join('-')]
      end

      def compact_descr
        @compact_descr ||= terna.join(SEP_VR_TERNA)
      end

      def aggiorna_metamodello_da_logico # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        ret = {}
        transaction do
          MetaParametroFisico.where(vendor_release_fisico_id: id).delete
          MetaEntitaFisico.where(vendor_release_fisico_id: id).delete

          map_meid_fisico = {} # me_id_fisico => [me1_id, me2_id,...]
          map_vr_rete = {}
          vendor_releases.each do |vrid|
            vr = VendorRelease.first(id: vrid)
            map_vr_rete[vrid] = vr.rete_id if vr
          end
          select_field_me = [:id, :vendor_release_id, :nome, :naming_path, :tipo, :extra_name, :fase_di_calcolo, :operazioni_ammesse]
          last_np = nil
          new_me_group = []
          MetaEntita.where(vendor_release_id: vendor_releases).select(*select_field_me).order(:naming_path).each do |me|
            if last_np != me.naming_path
              unless new_me_group.empty?
                mef = MetaEntitaFisico.crea_da_me_logiche(lista_vrf: [self], lista_me: new_me_group, check_lista_ok: false).first
                map_meid_fisico[mef.id] ||= []
                map_meid_fisico[mef.id] = new_me_group.map(&:id)
              end
              last_np = me.naming_path
              new_me_group = [me]
            end
            new_me_group << me
          end
          unless new_me_group.empty?
            mef = MetaEntitaFisico.crea_da_me_logiche(lista_vrf: [self], lista_me: new_me_group, check_lista_ok: false).first
            map_meid_fisico[mef.id] ||= []
            map_meid_fisico[mef.id] = new_me_group.map(&:id)
          end

          # --- meta_parametri
          select_fields_flags = [:is_to_export, :is_obbligatorio, :is_forced, :is_restricted,
                                 :is_multivalue, :is_multistruct, :is_update_on_create, :is_prioritario]
          select_fields_1 = [:nome, :nome_struttura, :full_name, :descr, :tipo, :genere]
          select_fields_2 = [:vendor_release_id, :meta_entita_id]
          select_field_mp = select_fields_1 + select_fields_2 + select_fields_flags
          MetaEntitaFisico.where(vendor_release_fisico_id: id).each do |mefx|
            last_fullname = nil
            new_mp_group = []
            MetaParametro.where(meta_entita_id: map_meid_fisico[mefx.id]).select(*select_field_mp).order(:full_name).each do |mp|
              if last_fullname != mp.full_name
                unless (new_mp_group || []).empty?
                  MetaParametroFisico.crea_da_mp_logici(mef_id: mefx.id, lista_mp: new_mp_group, vrf_id: id, check_lista_ok: false)
                  new_mp_group = []
                end
                last_fullname = mp.full_name
                new_mp_group = [mp]
              end
              new_mp_group << mp
            end
            unless (new_mp_group || []).empty?
              MetaParametroFisico.crea_da_mp_logici(mef_id: mefx.id, lista_mp: new_mp_group, vrf_id: id, check_lista_ok: false)
              new_mp_group = []
            end
          end
        end
        ret[:meta_parametri_fisico] = MetaParametroFisico.where(vendor_release_fisico_id: id).count
        ret[:meta_entita_fisico] = MetaEntitaFisico.where(vendor_release_fisico_id: id).count
        ret
      end

      def copia(descr:, copy_meta_modello:, **opts) # rubocop:disable Metrics/AbcSize
        transaction do
          unless self.descr != descr
            raise "Esiste già una Vendor Release Fisico con nome #{descr}, associata al vendor #{Constant.label(:vendor, vendor_id)}."
          end

          # opts.update(release_di_nodo: opts[:release_di_nodo] ? opts[:release_di_nodo].split(',') : nil)
          # opts.update(nodo_naming_path: (opts[:nodo_naming_path] != default_nodo_naming_path) ? opts[:nodo_naming_path] : nil)
          # opts.update(cella_naming_path: (opts[:cella_naming_path] != default_cella_naming_path) ? opts[:cella_naming_path] : nil)
          # opts.update(formato_audit: (opts[:formato_audit] != default_formati_audit.to_json) ? opts[:formato_audit] : nil)

          vr_copy = self.class.create(values.reject { |k| k == :id }.merge(descr: descr).merge(opts))

          if copy_meta_modello == true
            begin
              copia_meta_modello(vr_target: vr_copy)
            rescue
              raise "Errore in fase di copia del meta modello. Non è possibile completare l\' operazione di copia della vendor release fisico."
            end
          end
          vr_copy
        end
      end

      def copia_meta_modello(vr_target:) # rubocop:disable Metrics/AbcSize
        Db::MetaEntitaFisico.where(vendor_release_fisico_id: id).all do |me_record|
          id_me_src = me_record.id
          meta_entita_copia = Db::MetaEntitaFisico.create(me_record.values.reject { |k| %i(id).include?(k) }.merge(vendor_release_fisico_id: vr_target.id))
          id_me_target = meta_entita_copia.id
          Db::MetaParametroFisico.where(meta_entita_fisico_id: id_me_src).all do |mp_record|
            Db::MetaParametroFisico.create(mp_record.values.reject { |k| %i(id).include?(k) }.merge(vendor_release_fisico_id: vr_target.id, meta_entita_fisico_id: id_me_target))
          end
        end
      end
    end
  end
end

# == Schema Information
#
# Tabella: vendor_releases_fisico
#
#  cella_naming_path :string(256)
#  created_at        :datetime
#  descr             :string(256)     non nullo
#  formato_audit     :json
#  header_pr         :json
#  id                :integer         non nullo, default(nextval('vendor_releases_fisico_id_seq')), chiave primaria
#  nodo_naming_path  :string(256)
#  release_di_nodo   :json
#  reti              :jsonb
#  updated_at        :datetime
#  vendor_id         :integer         non nullo, riferimento a vendors.id
#
# Indici:
#
#  uidx_vendor_releases_fisico  (descr,reti,vendor_id) UNIQUE
#
