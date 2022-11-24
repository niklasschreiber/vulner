# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151229
#

require 'irma/validatore'
require 'irma/db/audit_model_support'

module Irma
  module Db
    #
    module MetaEntitaCommon
      extends_host_with :ClassMethods
      #
      module ClassMethods
        def cleanup(_hash = {})
          cleanup_only_rebuild_indexes
        end

        def naming_path_padre(np)
          np.to_s.split(NAMING_PATH_SEP)[0..-2].join(NAMING_PATH_SEP)
        end

        def livello(np)
          np.to_s.split(NAMING_PATH_SEP).size
        end
      end

      def fisico?
        self.class.fisico?
      end

      def before_destroy
        kfl = MetaModello.keywords_fisico_logico(fisico?)
        kfl.classe_meta_parametro.where(kfl.field_me_id.to_sym => id).delete
        super
      end

      def livello
        # @livello ||= naming_path.to_s.split(NAMING_PATH_SEP).size
        @livello ||= self.class.livello(naming_path)
      end

      def naming_path_padre
        @naming_path_padre ||= self.class.naming_path_padre(naming_path)
      end

      VS_DATA_REGEXPR = /^vsData(.+)/
      def vs_data?(force = false)
        @vs_data = nil if force
        if @vs_data.nil?
          @vs_data = begin
                       mmm = nome.match(VS_DATA_REGEXPR)
                       return false if mmm.nil?
                       nome_padre = naming_path.split(NAMING_PATH_SEP)[-2]
                       nome_padre == mmm[1]
                     end
        end
        @vs_data
      end

      def meta_entita_ref_array
        @meta_entita_ref_array ||= meta_entita_ref.to_s.split(META_ENTITA_REF_SEP)
      end
    end

    # rubocop:disable Metrics/ClassLength
    class MetaEntita < Model(:meta_entita)
      plugin :timestamps, update_on_create: true

      include MetaEntitaCommon
      include ValidatoreRegoleUtil

      audit_enable Irma::Db::AuditMetaEntita

      # --------------------------------
      # --- class methods
      def self.fisico?
        false
      end

      # -------------------------
      COLUMNS_NO_CHANGEABLE = [:id, :pid, :created_at, :updated_at, :vendor_release_id, :naming_path, :nome].freeze
      COLUMNS_NO_FILE_ADRN  = COLUMNS_NO_CHANGEABLE + [:priorita_fdc, :tipo_oggetto, :versione].freeze
      COLUMNS_FILE_ADRN_MAPPING = {
        descr:              'Descrizione',
        tipo:               'Tipo Valore',
        extra_name:         'Extra Name',
        regole_calcolo:     'Regola Calcolo',
        regole_calcolo_ae:  'Regola Calcolo AE',
        rete_adj:           'Rete Adiacenza',
        meta_entita_ref:    'Entita di Riferimento',
        fase_di_calcolo:    'Fase di Calcolo',
        operazioni_ammesse: 'Operazioni Ammesse',
        tipo_adiacenza:     'Tipo Adiacenza'
      }.freeze

      FILE_ADRN_HEADER_COMMENTS = {
        tipo:               { text: "Valori possibili: \n char \n integer \n float", row2: 4, col2: 2 },
        rete_adj:           { text: "Valori possibili: \n GSM \n UMTS \n LTE \n 5G", row2: 5, col2: 2 },
        tipo_adiacenza:     { text: "Valori possibili: \n" \
                                    " 0 \t (Nessuna) \n" \
                                    " 1 \t (Interna) \n" \
                                    " 2 \t (Esterna) \n" \
                                    " 3 \t (Interna ed Esterna)", row2: 5, col2: 3 },
        operazioni_ammesse: { text: "Valori possibili: \n" \
                                    " 0 \t (Nessuna) \n" \
                                    " 1 \t (Create) \n" \
                                    " 2 \t (Update) \n" \
                                    " 3 \t (Create + Update) \n" \
                                    " 4 \t (Delete) \n" \
                                    " 5 \t (Create + Delete) \n" \
                                    " 6 \t (Update + Delete) \n" \
                                    " 7 \t (Create + Update + Delete)", row2: 9, col2: 3 },
        fase_di_calcolo:    { text: "Valori possibili: \n 0 \t (fase PI) \n 1 \t (fase REF)  \n 2 \t (fase ADJ) \n 3 \t (fase PIALIAS)", row2: 5, col2: 2 },
        meta_entita_ref:    { text: 'Un naming_path esistente', row2: 1, col2: 3 }
      }.freeze

      def self.columns_per_file_adrn
        columns - COLUMNS_NO_FILE_ADRN
      end

      def self.mapped_columns_per_file_adrn
        columns_per_file_adrn.map { |ccc| COLUMNS_FILE_ADRN_MAPPING[ccc] || ccc.to_s }
      end

      def self.invert_mapped_columns_per_file_adrn
        res = {}
        columns_per_file_adrn.each { |ccc| res[COLUMNS_FILE_ADRN_MAPPING[ccc] || ccc.to_s] = ccc }
        res
      end
      # -------------------------

      def self.calcola_extra_name(me_extra_name:, parametri:)
        return nil unless me_extra_name && !(parametri || {}).empty?
        pezzi = me_extra_name.split(EXTRA_NAME_SEP).map { |mp| parametri[mp] }
        pezzi.compact.empty? ? nil : pezzi.join(EXTRA_NAME_SEP)
      end

      def self.copia_meta_parametro(id_mp_sorgente:, id_destinazione:, audit_extra_info: nil)
        transaction do
          cols_mp = MetaParametro.columns - [:id, :created_at, :updated_at, :meta_entita_id, :vendor_release_id] # TODO: sistemare !!!
          mp_sorgente = MetaParametro.first(id: id_mp_sorgente)
          raise "MetaParametro sorgente (id: #{id_mp_sorgente}) inesistente" unless mp_sorgente
          me_dest = first(id: id_destinazione)
          raise "MetaEntita destinazione (id: #{id_destinazione}) inesistente" unless me_dest
          new_mp_attr = {}
          cols_mp.each { |ccc| new_mp_attr[ccc] = mp_sorgente[ccc] }
          new_mp_attr[:meta_entita_id] = me_dest.id
          new_mp_attr[:vendor_release_id] = me_dest.vendor_release_id
          MetaParametro.create_with_audit(audit_extra_info: audit_extra_info, attributes: new_mp_attr)
        end
      end

      def self.sposta_meta_parametro(id_mp_sorgente:, id_destinazione:, audit_extra_info: nil)
        transaction do
          copia_meta_parametro(id_mp_sorgente: id_mp_sorgente, id_destinazione: id_destinazione, audit_extra_info: audit_extra_info)
          MetaParametro.first(id: id_mp_sorgente).destroy_with_audit(audit_extra_info: audit_extra_info)
        end
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def self.copia(id_sorgente:, id_destinazione:, ricorsivo: true, copia_parametri: true, audit_extra_info: nil)
        transaction do
          me_sorgente = first(id: id_sorgente)
          raise "MetaEntita sorgente (id: #{id_sorgente}) inesistente" unless me_sorgente
          me_dest = first(id: id_destinazione)
          raise "MetaEntita destinazione (id: #{id_destinazione}) inesistente" unless me_dest

          # raise 'Impossibile eseguire la copia di rami di meta modello tra vendor release diverse' if me_dest.vendor_release_id != me_sorgente.vendor_release_id

          old_np_root_re = /^#{me_sorgente.naming_path_padre}/
          new_np_root = me_dest.naming_path + (me_sorgente.livello == 1 ? NAMING_PATH_SEP : '')

          xxx = first(naming_path: me_sorgente.naming_path.sub(old_np_root_re, new_np_root),
                      vendor_release_id: me_dest.vendor_release_id)
          raise "La meta_entita destinazione esiste gia'" if xxx

          cols = columns - [:id, :created_at, :updated_at, :naming_path, :pid, :vendor_release_id]

          map_ids = {} # old_id => new_id
          map_ids[me_sorgente.pid] = me_dest.id if me_sorgente.pid
          ([me_sorgente] + (ricorsivo ? me_sorgente.meta_entita_figlie : [])).each do |me|
            new_me_attr = {}
            cols.each { |ccc| new_me_attr[ccc] = me[ccc] }
            new_me_attr[:naming_path] = me.naming_path.sub(old_np_root_re, new_np_root)
            new_me_attr[:vendor_release_id] = me_dest.vendor_release_id
            new_me_attr[:pid] = me.pid.nil? ? nil : map_ids[me.pid]
            new_me = create_with_audit(audit_extra_info: audit_extra_info, attributes: new_me_attr)
            map_ids[me.id] = new_me.id if me.id
            # copia parametri
            next unless copia_parametri
            MetaParametro.where(meta_entita_id: me.id).each do |mp|
              copia_meta_parametro(id_mp_sorgente: mp.id, id_destinazione: new_me.id, audit_extra_info: audit_extra_info)
            end
          end
        end
      end

      def self.sposta(id_sorgente:, id_destinazione:, audit_extra_info: nil)
        raise "MetaEntita sorgente e MetaEntita destinazione coincidono (id: #{id_sorgente}). Spostamento non consentito" if id_sorgente == id_destinazione
        transaction do
          me_sorgente = first(id: id_sorgente)
          copia(id_sorgente: id_sorgente, id_destinazione: id_destinazione, ricorsivo: true, audit_extra_info: audit_extra_info)
          me_sorgente.destroy_con_gerarchia(audit_extra_info: audit_extra_info)
        end
      end

      # utility per verifica consistenza pid
      def self.check_consistenza_pid_me # rubocop:disable Metrics/PerceivedComplexity
        res = { tot: 0, pid_nullo: 0, pid_nullo_non_root: 0, pid_coerente: 0, pid_non_coerente: 0, pid_me_inesistente: 0 }
        Irma::Db::MetaEntita.each do |me|
          res[:tot] += 1
          if me.pid.nil?
            res[:pid_nullo] += 1
            res[:pid_nullo_non_root] += 1 if me.livello > 1
          else
            me_p = Irma::Db::MetaEntita.first(id: me.pid)
            unless me_p
              res[:pid_me_inesistente] += 1
              next
            end
            if me.vendor_release_id == me_p.vendor_release_id && me.naming_path_padre == me_p.naming_path
              res[:pid_coerente] += 1
            else
              res[:pid_non_coerente] += 1
            end
          end
        end
        res
      end

      # --------------------------------
      # --- instance methods
      def vendor_release
        VendorRelease.get_by_pk(vendor_release_id)
      end

      def vendor_release_fisico
        VendorRelease.first(id: vendor_release_id).vendor_release_fisico
      end

      def rete_id
        vr = VendorRelease.get_by_pk(vendor_release_id)
        vr.rete_id if vr
      end

      def meta_entita_fisico
        MetaEntitaFisico.where(vendor_release_fisico_id: (vendor_release_fisico || []).map(&:id), naming_path: naming_path).all
      end

      def aggiorna_meta_entita_fisico(operazione)
        raise "aggiorna_meta_entita_fisico invocata con operazione '#{operazione}' non valida" unless MODEL_OBJECT_OPERATIONS.include?(operazione)
        vrf = vendor_release_fisico
        return if vrf.nil? || vrf.empty?

        mef = meta_entita_fisico
        if operazione == MODEL_OBJECT_OPERATION_CREATE && mef.empty?
          MetaEntitaFisico.crea_da_me_logiche(lista_vrf: vrf, lista_me: [self])
        else
          mef.each(&:aggiorna_da_me_logiche)
        end
      end

      def _verifica_campi_derivati # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        # [:vendor_release_id, :naming_path, :nome, :pid]
        err_msg = 'Errore in creazione meta_entita:'
        raise "#{err_msg} vendor_release_id non specificata" unless vendor_release_id

        # np = naming_path
        # pp = pid
        # nn = nome

        # :naming_path --> :nome, :pid
        if naming_path
          # non posso creare una seconda meta_entita root per la stessa vendor_release
          lvl_np = MetaEntita.livello(naming_path)
          raise "#{err_msg} esiste gia' una meta_entita root per questa release" if lvl_np == 1 && VendorRelease.get_by_pk(vendor_release_id).meta_entita_root
          # coerenza gerarchia 'naming_path'
          parent = MetaEntita.first(vendor_release_id: vendor_release_id, naming_path: self.class.naming_path_padre(naming_path))
          raise "#{err_msg} richiesta creazione di meta_entita in gerarchia inesistente" if parent.nil? && lvl_np != 1
          good_pp = (parent || {})[:id]

          # coerenza 'naming_path' con 'nome'
          good_nn = naming_path.split(NAMING_PATH_SEP).last
          raise "#{err_msg} naming_path '#{naming_path}' e nome '#{nome}' non coerenti" if nome && nome != good_nn
          self.nome = good_nn

          # coerenza 'naming_path' con 'pid'
          if pid
            pp_obj = MetaEntita.first(id: pid)
            raise "#{err_msg} non esiste meta_entita padre con id #{pid}" unless pp_obj
            raise "#{err_msg} naming_path '#{naming_path}' e meta_entita padre '#{pp_obj.naming_path}' (id: #{pid}) non coerenti" if pid != good_pp
          end
          self.pid = good_pp
          return
        elsif pid
          # :pid, :nome --> :naming_path
          pp_obj = MetaEntita.first(id: pid)
          raise "#{err_msg} non esiste meta_entita padre con id #{pid}" unless pp_obj
          raise "#{err_msg} parent_id non e' sufficiente a determinare completamente la meta_entita da creare" if nome.nil?
          self.naming_path = [pp_obj.naming_path, nome].join(NAMING_PATH_SEP)
        end
        raise "#{err_msg} impossibile determinare naming_path" if naming_path.nil?
        raise "#{err_msg} impossibile determinare nome" if nome.nil?
      end

      def valida_rc
        valida_tutte_le_regole do |_key, regola, _rete_adj, is_ae, res|
          raise "Regola di calcolo #{regola}, in #{is_ae ? 'regole_calcolo_ae' : 'regole_calcolo'}, non corretta (#{res})" if (res || {})[:errore]
        end
      end

      def before_create
        _verifica_campi_derivati
        valida_rc
        super
      end

      def before_update
        x = (COLUMNS_NO_CHANGEABLE & changed_columns)
        raise "Non e' consentito modificare il/i campo/i (#{x}) di un MetaEntita" unless x.empty?
        valida_rc unless (changed_columns & [:regole_calcolo, :regole_calcolo_ae]).empty?
        super
      end

      def after_create
        super
        aggiorna_meta_entita_fisico(MODEL_OBJECT_OPERATION_CREATE)
      end

      def after_update
        super
        aggiorna_meta_entita_fisico(MODEL_OBJECT_OPERATION_UPDATE)
      end

      def after_destroy
        super
        aggiorna_meta_entita_fisico(MODEL_OBJECT_OPERATION_DELETE)
      end

      def destroy_meta_parametri(audit_extra_info: nil, filtro: nil)
        qqq = MetaParametro.where(meta_entita_id: id)
        qqq = qqq.where(filtro) if filtro
        qqq.all.each { |mp| mp.destroy_with_audit(audit_extra_info: audit_extra_info) }
      end

      def meta_entita_figlie(rev: false)
        if rev
          MetaEntita.where(vendor_release_id: vendor_release_id).where("naming_path like '#{naming_path}#{NAMING_PATH_SEP}%'").reverse(:naming_path).all
        else
          MetaEntita.where(vendor_release_id: vendor_release_id).where("naming_path like '#{naming_path}#{NAMING_PATH_SEP}%'").order_by(:naming_path).all
        end
      end

      def meta_entita_padre
        return self.class.first(id: pid) if pid
        self.class.first(naming_path: naming_path_padre, vendor_release_id: vendor_release_id)
      end

      def destroy_con_shift_gerarchia(audit_extra_info: nil)
        raise 'Operazione non consentita per meta_entita root' if livello == 1
        me_padre = meta_entita_padre
        raise 'Impossibile identificare meta_entita padre' unless me_padre

        transaction do
          meta_entita_figlie.each { |me| self.class.copia(id_sorgente: me.id, id_destinazione: me_padre.id, audit_extra_info: audit_extra_info) if me.livello == livello + 1 }
          destroy_con_gerarchia(audit_extra_info: audit_extra_info)
        end
      end

      def destroy_con_gerarchia(audit_extra_info: nil)
        res = { cnt_me: 0, cnt_mp: 0 }
        transaction do
          (meta_entita_figlie(rev: true) + [self]).each do |me|
            xp = me.destroy_meta_parametri(audit_extra_info: audit_extra_info)
            xe = me.destroy_with_audit(audit_extra_info: audit_extra_info)
            res[:cnt_mp] += xp.count
            res[:cnt_me] += 1 if xe
          end
        end
        res
      end
    end
  end
end

# == Schema Information
#
# Tabella: meta_entita
#
#  created_at         :datetime
#  descr              :string
#  extra_name         :string(256)
#  fase_di_calcolo    :integer
#  id                 :bigint          non nullo, default(nextval('meta_entita_id_seq')), chiave primaria
#  meta_entita_ref    :string(1024)
#  naming_path        :string(1024)    non nullo
#  nome               :string(256)     non nullo
#  operazioni_ammesse :integer         default(0)
#  pid                :bigint          riferimento a meta_entita.id
#  priorita_fdc       :integer         default(0)
#  regole_calcolo     :json
#  regole_calcolo_ae  :json
#  rete_adj           :string(24)
#  tipo               :string(10)      non nullo, default('char')
#  tipo_adiacenza     :integer         default(0)
#  tipo_oggetto       :integer         non nullo, default(0)
#  updated_at         :datetime
#  vendor_release_id  :integer         non nullo, riferimento a vendor_releases.id
#  versione           :string(24)
#
# Indici:
#
#  idx_meta_entita_naming_path     (naming_path)
#  idx_meta_entita_nome            (nome)
#  idx_meta_entita_vendor_release  (vendor_release_id)
#  uidx_meta_entita_vr_np          (naming_path,vendor_release_id) UNIQUE
#
