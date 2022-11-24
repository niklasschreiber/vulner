# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151229
#
require 'irma/validatore'

module Irma
  module Db
    #
    module MetaParametroCommon
      extends_host_with :ClassMethods
      #
      module ClassMethods
        def cleanup(_hash = {})
          cleanup_only_rebuild_indexes
        end

        def crea(meta_entita, hash = {}) # rubocop:disable Metrics/AbcSize
          kfl = MetaModello.keywords_fisico_logico(fisico?)
          meta_entita = kfl.classe_meta_entita.get_by_pk(meta_entita.is_a?(kfl.classe_meta_entita) ? meta_entita.id : meta_entita)
          begin
            new({ kfl.field_me_id.to_sym => meta_entita.id }.merge(hash.select { |k, _v| columns.include?(k.to_sym) })).save
          rescue => e
            raise "Parametri obbligatori assenti (#{e})"
          end
        end
      end

      def fisico?
        self.class.fisico?
      end

      REGOLE_CALCOLO_DEFAULT_VUOTO = { RC_DEFAULT_GRP_KEY => { DEFAULT_KEY => [] } }.freeze
      def da_calcolare?
        @da_calcolare = (!regole_calcolo.nil? && regole_calcolo != REGOLE_CALCOLO_DEFAULT_VUOTO) if @da_calcolare.nil?
        @da_calcolare
      end

      def da_calcolare_ae?
        @da_calcolare_ae = !regole_calcolo_ae.nil? && regole_calcolo_ae != REGOLE_CALCOLO_DEFAULT_VUOTO if @da_calcolare_ae.nil?
        @da_calcolare_ae
      end

      def determina_valore(valori)
        is_struct = !nome_struttura.nil?
        # ---------------------------------------------------------------------
        # is_multistruct | is_multivalue | is_struct |   [v]   | [v1, v2,...]
        # ---------------------------------------------------------------------
        #       -        |       f       |     f     |    v    |     ///
        # ---------------------------------------------------------------------
        #       -        |       t       |     f     |   [v]   |  [v1, v2,...]
        # ---------------------------------------------------------------------
        #       f        |       f       |     t     |   [v]   |     ///
        # ---------------------------------------------------------------------
        #       f        |       t       |     t     |  [[v]]  | [[v1, v2,...]]
        # ---------------------------------------------------------------------
        #       t        |       f       |     t     |   ///   |  [v1, v2,...]
        # ---------------------------------------------------------------------
        #       t        |       t       |     t     |   ///   |     ///
        # ---------------------------------------------------------------------
        return valori[0] if is_multivalue == false && is_struct == false
        return [valori] if is_multivalue == true && is_struct == true && is_multistruct == false
        valori
      end
    end

    # rubocop:disable Style/DoubleNegation
    class MetaParametro < Model(:meta_parametri) # rubocop:disable Metrics/ClassLength
      plugin :timestamps, update_on_create: true

      include MetaParametroCommon
      include ValidatoreRegoleUtil

      audit_enable Irma::Db::AuditMetaParametro

      def self.fisico?
        false
      end

      # -------------------------
      COLUMNS_NO_CHANGEABLE = [:id, :created_at, :updated_at, :vendor_release_id, :meta_entita_id, :nome, :full_name, :nome_struttura].freeze
      COLUMNS_NO_FILE_ADRN  = COLUMNS_NO_CHANGEABLE + [:genere, :tags].freeze
      COLUMNS_FILE_ADRN_MAPPING = {
        is_multivalue:       'Multi Valore',
        is_multistruct:      'Multi Struttura',
        tipo:                'Tipo Valore',
        regole_calcolo:      'Regola Calcolo',
        regole_calcolo_ae:   'Regola Calcolo AE',
        rete_adj:            'Rete Adiacenza',
        is_predefinito:      'Predefinito',
        is_to_export:        'To Export',
        is_obbligatorio:     'Obbligatorio',
        is_restricted:       'Restricted',
        is_forced:           'Forced',
        is_update_on_create: 'Update On Create',
        is_prioritario:      'Prioritario',
        descr:               'Descrizione'
      }.freeze

      FILE_ADRN_HEADER_COMMENTS = {
        is_prioritario:      { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        is_update_on_create: { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        is_forced:           { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        is_restricted:       { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        is_obbligatorio:     { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        is_to_export:        { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        is_predefinito:      { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        is_multivalue:       { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        is_multistruct:      { text: "Valori possibili: \n true \n false", row2: 3, col2: 2 },
        tipo:                { text: "Valori possibili: \n char \n integer \n float", row2: 4, col2: 2 },
        rete_adj:            { text: "Valori possibili: \n GSM \n UMTS \n LTE \n 5G", row2: 5, col2: 2 }
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

      def meta_entita
        MetaEntita.get_by_pk(meta_entita_id)
      end

      def naming_path
        # MetaEntita.get_by_pk(meta_entita_id).naming_path
        meta_entita.naming_path
      end

      def meta_entita_nome
        # MetaEntita.get_by_pk(meta_entita_id).nome
        meta_entita.nome
      end

      def tipo_adiacenza
        meta_entita.tipo_adiacenza
      end

      def rete_id
        vr = VendorRelease.get_by_pk(vendor_release_id)
        vr.rete_id if vr
      end

      def vendor_release
        VendorRelease.get_by_pk(vendor_release_id)
      end

      def vendor_release_fisico
        vendor_release.vendor_release_fisico
      end

      def meta_entita_fisico
        MetaEntita.first(id: meta_entita_id).meta_entita_fisico
      end

      def meta_parametro_fisico
        res = {}
        meta_entita_fisico.each do |mef|
          res[mef.id] = MetaParametroFisico.where(meta_entita_fisico_id: mef.id, full_name: full_name).first
        end
        res
      end

      def aggiorna_meta_parametro_fisico(operazione)
        raise "aggiorna_meta_parametro_fisico invocata con operazione '#{operazione}' non valida" unless MODEL_OBJECT_OPERATIONS.include?(operazione)
        vrf = vendor_release_fisico
        return if (vrf || []).empty?

        mmppff = meta_parametro_fisico
        mmppff.each do |mef_id, mpf|
          if operazione == MODEL_OBJECT_OPERATION_CREATE && mpf.nil?
            MetaParametroFisico.crea_da_mp_logici(mef_id: mef_id, lista_mp: [self])
          else
            mpf.aggiorna_da_mp_logici
          end
        end
      end

      def _verifica_campi_derivati # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        # [:vendor_release_id, :meta_entita_id, :nome, :full_name, :nome_struttura]
        err_msg = 'Errore in creazione meta_parametro:'
        raise "#{err_msg} vendor_release_id non specificata" unless vendor_release_id
        raise "#{err_msg} meta_entita_id non specificata" unless meta_entita_id

        expected_me = MetaEntita.first(id: meta_entita_id)
        raise "#{err_msg} meta_entita_id inesistente" unless expected_me
        raise "#{err_msg} meta_entita_id relativa a vendor_release diversa (#{expected_me.vendor_release_id}, #{vendor_release_id})" if expected_me.vendor_release_id != vendor_release_id

        # nn = nome
        # fn = full_name
        # ns = nome_struttura

        # :full_name --> :nome, :nome_struttura
        if full_name
          x = full_name.split(TEXT_STRUCT_NAME_SEP)
          good_ns, good_nn = if x.size == 2
                               x
                             else
                               [nil, x.first]
                             end
          raise "#{err_msg} nome '#{nome}' e full_name '#{full_name}' non coerenti" if nome && nome != good_nn
          self.nome = good_nn
          raise "#{err_msg} full_name '#{full_name}' e nome_struttura '#{nome_struttura}' non coerenti" if nome_struttura && nome_struttura != good_ns
          self.nome_struttura = good_ns
          return
        end
        raise "#{err_msg} nome non avvalorato" if nome.nil?
        self.full_name ||= [nome_struttura, nome].compact.join(TEXT_STRUCT_NAME_SEP)
      end

      def genere_da_flags(multi_value, multi_struct, nome_struct)
        META_PARAMETRO_FLAGS_TO_GENERE[[multi_value, multi_struct, !!nome_struct]]
      end

      def flags_da_genere(genere)
        META_PARAMETRO_GENERE_TO_FLAGS[genere]
      end

      def imposta_genere_flags(genere_changed: true) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        nome_struttura_empty = (nome_struttura || '').empty?
        if genere && genere_changed
          # comanda genere
          self.is_multivalue, self.is_multistruct, ns = flags_da_genere(genere)
          raise "Parametro con genere 'strutturato' (#{Constant.label(:meta_parametro, genere, :genere)}) ma nome struttura non avvalorato" if ns && nome_struttura_empty
          raise "Parametro con genere 'non strutturato' (#{Constant.label(:meta_parametro, genere, :genere)}) ma nome struttura avvalorato" if !ns && nome_struttura
        else
          # comandano flags
          ggg = genere_da_flags(p1 = is_multivalue || self.class.db_schema[:is_multivalue][:ruby_default],
                                p2 = is_multistruct || self.class.db_schema[:is_multistruct][:ruby_default],
                                !nome_struttura_empty)
          raise "Nessun genere individuabile per il meta_parametro avente flags multivalue: '#{p1}', multistruct: '#{p2}' e nome_struttura: '#{nome_struttura}'" unless ggg
          self.genere = ggg
        end
      end

      def valida_rc
        valida_tutte_le_regole do |_key, regola, _rete_adj, is_ae, res|
          raise "Regola di calcolo #{regola}, in #{is_ae ? 'regole_calcolo_ae' : 'regole_calcolo'}, non corretta (#{res})" if (res || {})[:errore]
        end
      end

      def before_create
        _verifica_campi_derivati
        imposta_genere_flags
        valida_rc
        super
      end

      def before_update
        x = (COLUMNS_NO_CHANGEABLE & changed_columns)
        raise "Non e' consentito modificare il/i campo/i (#{x}) di un MetaParametro" unless x.empty?
        valida_rc unless (changed_columns & [:regole_calcolo, :regole_calcolo_ae]).empty?
        imposta_genere_flags(genere_changed: changed_columns.include?(:genere)) unless (changed_columns & [:genere, :is_multivalue, :is_multistruct]).empty?
        super
      end

      def after_create
        super
        aggiorna_meta_parametro_fisico(MODEL_OBJECT_OPERATION_CREATE)
      end

      def after_update
        super
        aggiorna_meta_parametro_fisico(MODEL_OBJECT_OPERATION_UPDATE)
      end

      def after_destroy
        super
        aggiorna_meta_parametro_fisico(MODEL_OBJECT_OPERATION_DELETE)
      end
    end
  end
end

# == Schema Information
#
# Tabella: meta_parametri
#
#  created_at          :datetime
#  descr               :string
#  full_name           :string(512)
#  genere              :integer         non nullo, default(1)
#  id                  :bigint          non nullo, default(nextval('meta_parametri_id_seq')), chiave primaria
#  is_forced           :boolean         non nullo, default(false)
#  is_multistruct      :boolean         non nullo, default(false)
#  is_multivalue       :boolean         non nullo, default(false)
#  is_obbligatorio     :boolean         non nullo, default(false)
#  is_predefinito      :boolean         non nullo, default(false)
#  is_prioritario      :boolean         non nullo, default(true)
#  is_restricted       :boolean         non nullo, default(false)
#  is_to_export        :boolean         non nullo, default(false)
#  is_update_on_create :boolean         non nullo, default(false)
#  meta_entita_id      :bigint          non nullo, riferimento a meta_entita.id
#  nome                :string(256)     non nullo
#  nome_struttura      :string(256)
#  regole_calcolo      :json
#  regole_calcolo_ae   :json
#  rete_adj            :string(24)
#  tags                :json
#  tipo                :string(10)      non nullo, default('char')
#  updated_at          :datetime
#  vendor_release_id   :integer         non nullo, riferimento a vendor_releases.id
#
# Indici:
#
#  idx_meta_parametri_full_name       (full_name)
#  idx_meta_parametri_meta_entita     (meta_entita_id)
#  idx_meta_parametri_vendor_release  (vendor_release_id)
#
