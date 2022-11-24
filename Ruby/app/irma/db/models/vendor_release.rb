# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

module Irma
  module Db
    # rubocop:disable Metrics/ClassLength
    class VendorRelease < Model(:vendor_releases)
      plugin :timestamps, update_on_create: true

      # many_to_one :vendor, class: full_class_for_model(:Vendor)
      # many_to_one :rete, class: full_class_for_model(:Rete)
      one_to_many :sistemi, class: full_class_for_model(:Sistema)

      def self.cache_enabled?
        !@cache_disabled
      end

      def self.load_in_cache(force = false)
        super(force)
        Sistema.load_in_cache(force)
      end

      def self.pubblica_sulla_coda(coda, opts = {})
        super(coda, opts.reject { |k, _v| %i(cc_filtro_release cc_filtro_parametri header_pr).include?(k) })
      end

      def before_destroy
        raise "VendorRelease #{id} (#{descr}) utilizzata da almeno un sistema" if sistemi.count > 0
        [MetaParametro, MetaEntita, Segnalazione].each { |klass| klass.where(vendor_release_id: id).delete }
        super
      end

      def _carica_release_nodo_e_filtro_release
        self.release_di_nodo = (release_di_nodo || []).sort.uniq
        self.cc_filtro_release = (release_di_nodo || []) & (cc_filtro_release || [])
        self
      end

      def before_create
        _carica_release_nodo_e_filtro_release
        super
      end

      def before_update
        _carica_release_nodo_e_filtro_release
        super
      end

      def metamodello(**opts)
        MetaModello.new.carica_da_db(self, **opts)
      end

      def formati_audit
        @formati_audit ||= (formato_audit || vendor_instance.default_formato_audit)
      end

      def default_formati_audit
        vendor_instance.default_formato_audit
      end

      def default_cella_naming_path
        vendor_instance.default_cella_naming_path
      end

      def default_nodo_naming_path
        vendor_instance.default_nodo_naming_path
      end

      def rete
        @rete ||= rete_id ? Rete.get_by_pk(rete_id) : nil
      end

      def vendor
        @vendor ||= vendor_id ? Vendor.get_by_pk(vendor_id) : nil
      end

      def vendor_instance
        @vendor_instance ||= Irma::Vendor.instance(vendor: vendor_id, rete: rete_id)
      end

      def vendor_release_fisico
        VendorReleaseFisico.where(descr: descr, vendor_id: vendor_id).all.select { |vrf| (vrf.reti || []).include?(rete_id) }
      end

      def full_descr
        @full_descr ||= "#{descr} (#{rete.nome}_#{vendor.nome})" # ||= "#{descr}_#{rete.nome}_#{vendor.sigla}"
      end

      def terna
        @terna ||= [descr, vendor.nome, rete.nome]
      end

      def compact_descr
        @compact_descr ||= terna.join(SEP_VR_TERNA)
      end

      def meta_entita_root
        # TODO: 20190613 Funzionera' in futuro senza order_by, quando solo le root saranno con pid=nil
        MetaEntita.where(vendor_release_id: id).where('pid is null').order_by(:naming_path).first
      end

      def ricalcola_header_pr
        final_head = {}
        sistemi.sort_by(&:id).each { |s| final_head.merge(s.header_pr || {}) }
        update(header_pr: final_head)
      end

      def propaga_header_pr
        sistemi.each { |s| s.update(header_pr: header_pr) }
      end

      def valorizza_e_completa_campi_pr(array_campi)
        out_hash = {}
        (array_campi || []).each do |campo|
          # tolgo l'eventuale _N
          c = campo.chomp('_N')
          out_hash[campo] = [TIPO_VALORE_DEFAULT_VAL[header_pr[c]['tipo']], nil, header_pr[c]['tipo']] if (header_pr || {}).keys.include?(c)
        end
        out_hash
      end

      def nodo_naming_path_real
        @nodo_naming_path_real ||= nodo_naming_path.to_s.empty? ? default_nodo_naming_path : nodo_naming_path
      rescue => e
        raise "Impossibile ottenere il naming_path per il nodo sulla vendor_release #{full_descr} (#{id}): #{e}"
      end

      def cella_naming_path_real
        @cella_naming_path ||= cella_naming_path.to_s.empty? ? [default_cella_naming_path] : [cella_naming_path]
      rescue => e
        raise "Impossibile ottenere il naming_path per la cella sulla vendor_release #{full_descr} (#{id}): #{e}"
      end

      def copia(descr:, copy_meta_modello:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        vr_copy = nil
        transaction do
          unless self.descr != descr
            raise "Esiste già una Vendor Release con nome #{descr}, associata alla rete #{Constant.label(:rete, rete_id)} ed al vendor #{Constant.label(:vendor, vendor_id)}."
          end

          opts.update(release_di_nodo: opts[:release_di_nodo] ? opts[:release_di_nodo].split(',') : nil)
          opts.update(nodo_naming_path: (opts[:nodo_naming_path] != default_nodo_naming_path) ? opts[:nodo_naming_path] : nil)
          opts.update(cella_naming_path: (opts[:cella_naming_path] != default_cella_naming_path) ? opts[:cella_naming_path] : nil)
          opts.update(formato_audit: (opts[:formato_audit] != default_formati_audit.to_json) ? opts[:formato_audit] : nil)

          vr_copy = self.class.create(values.reject { |k| %i(id created_at updated_at).include?(k) }.merge(descr: descr).merge(opts))

          if copy_meta_modello == true
            begin
              copia_meta_modello(vr_target: vr_copy)
            rescue => e
              raise "Errore in fase di copia del meta modello. Non è possibile completare l\' operazione di copia della vendor release: #{e}"
            end
          end
        end
        vr_copy.refresh_cache_queue(action: 'create') if vr_copy
        vr_copy
      end

      def copia_meta_modello(vr_target:) # rubocop:disable Metrics/AbcSize
        Db::MetaEntita.where(vendor_release_id: id).order_by(:naming_path).all do |me_record|
          id_me_src = me_record.id
          meta_entita_copia = Db::MetaEntita.create(me_record.values.reject { |k| %i(id pid created_at updated_at).include?(k) }.merge(vendor_release_id: vr_target.id))
          id_me_target = meta_entita_copia.id
          Db::MetaParametro.where(meta_entita_id: id_me_src).all do |mp_record|
            Db::MetaParametro.create(mp_record.values.reject { |k| %i(id created_at updated_at).include?(k) }.merge(vendor_release_id: vr_target.id, meta_entita_id: id_me_target))
          end
        end
      end

      def aggiorna_cc_filtro_release(str)
        update(cc_filtro_release: str ? str.split(',') : nil)
        self
      end

      def aggiorna_cc_filtro_parametri(file_name)
        update(cc_filtro_parametri: file_name ? Marshal.dump(File.read(file_name)) : nil)
        self
      end

      def extract_file_cc_filtro_parametri(out_dir: nil, out_name: nil)
        return nil unless cc_filtro_parametri
        file = File.join(out_dir || Irma.tmp_dir, out_name || "cc_filtro_parametri_#{compact_descr}_#{Time.now.strftime('%Y%m%d-%H%M')}.xlsx")
        File.open(file, 'wb') { |fd| fd.write(Marshal.restore(cc_filtro_parametri)) }
        file
      end

      def filtri_consistency_check # rubocop:disable Metrics/AbcSize
        res = { cc_filtro_release: cc_filtro_release || [], cc_filtro_parametri: {} }
        if cc_filtro_parametri
          begin
            File.open(file = Dir::Tmpname.make_tmpname(File.join(Irma.tmp_dir, '/'), 'cc_filtro_parametri.xlsx'), 'wb') { |fd| fd.write(Marshal.restore(cc_filtro_parametri)) }
            opts = [Constant.info(:comando, COMANDO_IMPORT_FILTRO_FU)[:command],
                    '--input_file', file, '--vendor_release_id', id]
            ret = Command.process(opts, logger: logger)
            res[:cc_filtro_parametri] = ret[:result][:header_per_filtro]
          ensure
            FileUtils.rm_f(file)
          end
        end
        res
      end
    end
  end
end

# == Schema Information
#
# Tabella: vendor_releases
#
#  cc_filtro_parametri :blob
#  cc_filtro_release   :json
#  cella_naming_path   :string(256)
#  created_at          :datetime
#  descr               :string(256)     non nullo
#  formato_audit       :json
#  header_pr           :json
#  id                  :integer         non nullo, default(nextval('vendor_releases_id_seq')), chiave primaria
#  nodo_naming_path    :string(256)
#  release_di_nodo     :json
#  rete_id             :integer         non nullo, riferimento a reti.id
#  updated_at          :datetime
#  vendor_id           :integer         non nullo, riferimento a vendors.id
#
# Indici:
#
#  uidx_vendor_releases  (descr,rete_id,vendor_id) UNIQUE
#
