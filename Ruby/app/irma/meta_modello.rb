# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20151229
#

module Irma
  # rubocop:disable Metrics/ClassLength
  class MetaModello
    ROOT = 'root'.freeze

    attr_reader :vendor_release, :logger
    attr_accessor :meta_entita # lista di oggetti MetaEntita con chiave naming_path
    attr_accessor :meta_entita_mapping # intesa come lista di naming_path
    attr_accessor :meta_entita_progettazione # lista di naming_path con fase di calcolo non nil
    attr_accessor :meta_parametri #  lista di oggetti MetaParametro, chiave naming_path e sottochiave stringa struttura.parametro
    attr_accessor :meta_parametri_fu # per meta_entita_id: hash di [struct.p1&struct.p2...] => [struct.p1,struct.p2]
    attr_accessor :meta_parametri_strutturati # per naming_path: array [struct.p1,struct.p2]
    attr_accessor :meta_parametri_strutturati_per_struttura # per naming_path: hash struct => [struct.p1,struct.p2]
    attr_accessor :meta_entita_calcolo # hash per fase piu' 'root'; { root: { me_root_np => me_root_obj}, fase_pi: {me1_np => me1_obj,...}, fase_ref: {...}, fase_adj: {...} }
    attr_accessor :meta_parametri_calcolo # hash per naming_path; { naming_path: { predefiniti: {nome_p1 => p1_obj,...}, da_calcolare: {...}, da_calcolare_ae: {...} } }
    attr_accessor :meta_entita_fdc # hash per operazione_ammessa me1.np => me1.id,...
    attr_accessor :meta_parametri_fdc

    def initialize(is_fisico: false, **opts)
      @is_fisico = is_fisico
      @kfl = self.class.keywords_fisico_logico(@is_fisico)
      @meta_entita = {}
      @meta_parametri = {}
      @meta_parametri_fu = {}
      @meta_parametri_strutturati = {}
      @meta_parametri_strutturati_per_struttura = {}
      @meta_entita_mapping = {}
      @meta_entita_progettazione = []
      @meta_entita_calcolo = {}
      @meta_parametri_calcolo = {}
      @meta_entita_fdc = {}
      @meta_parametri_fdc = {}
      @logger = opts[:logger] || Irma.logger
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def carica_da_db(vendor_release, per_export: true, per_calcolo: false, per_fdc: false, **opts)
      vendor_release = @kfl.classe_vendor_release.get_by_pk(vendor_release) unless vendor_release.is_a?(@kfl.classe_vendor_release)
      @vendor_release = vendor_release
      start_time = Time.now
      log_prefix = "Caricamento metamodello per la vendor release #{vendor_release.descr}" \
                   " (rete = #{(vendor_release.respond_to?(:rete) && vendor_release.rete) ? vendor_release.rete.nome : 'N/A'}," \
                   " vendor = #{vendor_release.vendor ? vendor_release.vendor.nome : 'N/A'})"
      logger.info("#{log_prefix}: inizio")
      @meta_entita.clear
      @meta_parametri.clear
      @meta_entita_mapping.clear
      @meta_entita_progettazione.clear
      @meta_parametri_fu.clear
      @meta_parametri_strutturati.clear
      @meta_parametri_strutturati_per_struttura.clear
      @meta_entita_calcolo.clear
      @meta_parametri_calcolo.clear
      @meta_entita_fdc.clear
      @meta_parametri_fdc.clear
      @kfl.classe_meta_entita.where(@kfl.field_vr_id.to_sym => vendor_release.id).each do |me|
        @meta_entita_mapping[me.id] = me.naming_path
        @meta_entita[me.naming_path] = me
        @meta_entita_progettazione << me.naming_path unless me.fase_di_calcolo.nil?
      end

      n_parametri = 0
      @kfl.classe_meta_parametro.where(@kfl.field_vr_id.to_sym => vendor_release.id).order(@kfl.field_me_id.to_sym, :full_name).each do |mp|
        @meta_parametri[@meta_entita_mapping[mp[@kfl.field_me_id.to_sym]]] ||= {}
        @meta_parametri[@meta_entita_mapping[mp[@kfl.field_me_id.to_sym]]][mp.full_name] = (opts[:load_mp_solo_nome] ? '' : mp)
        n_parametri += 1
      end

      if per_export
        carica_meta_parametri_fu
        carica_meta_parametri_strutturati
      end

      if per_fdc
        carica_meta_entita_fdc
        carica_meta_parametri_fdc
      end

      unless @is_fisico
        if per_calcolo
          carica_meta_entita_calcolo(filtro_metamodello: opts[:filtro_metamodello])
          carica_meta_parametri_calcolo(filtro_metamodello: opts[:filtro_metamodello])
        end
      end

      logger.info("#{log_prefix}: completato in #{(Time.now - start_time).round(1)} secondi (#{@meta_entita.size} meta_entita, #{n_parametri} meta_parametri)")
      self
    end

    # TODO: Questo modo di trovare le entita che sono relazioni di adj verra' cambiato...
    def util_figlia_di_lista_np(lista_np, np)
      lista_np.each { |parent| return true if np.start_with?(parent) }
      false
    end

    def carica_meta_entita_fdc
      rete_id = vendor_release.respond_to?(:rete_id) ? vendor_release.rete_id : nil
      vi = Irma::Vendor.instance(vendor: vendor_release.vendor_id, rete: rete_id)
      np_relazioni_adj = vi.meta_entita_relazioni_adj_fdc
      @meta_entita_fdc['relazioni_adj'] = {}
      @meta_entita.each { |k, _v| @meta_entita_fdc['relazioni_adj'][k] = util_figlia_di_lista_np(np_relazioni_adj, k) }

      Constant.constants(:operazioni_ammesse).map(&:value).each do |oper|
        xxx = {}
        @meta_entita.each { |k, v| xxx[k] = v.id if v.operazioni_ammesse && (v.operazioni_ammesse & oper) > 0 }
        @meta_entita_fdc[oper.to_s] ||= xxx.sort_by_key
      end
    end

    def carica_meta_parametri_fdc # rubocop:disable Metrics/AbcSize
      np_me = @meta_entita_fdc.values.map(&:keys).flatten.uniq
      @meta_parametri.each do |np, params|
        next unless np_me.member?(np)
        # puts "CCCCCCC np #{np}"
        @meta_parametri_fdc[np] ||= { is_obbligatorio: {}, is_to_export: {}, is_forced: {},
                                      upd_on_crt: {}, no_restricted: {},
                                      strutturati_con_ibridi: {} }
        strutture = {}
        params.each do |p_name, p_obj|
          next unless p_obj.is_to_export
          @meta_parametri_fdc[np][:is_to_export][p_name] = p_obj.id
          @meta_parametri_fdc[np][:is_obbligatorio][p_name] = p_obj.id if p_obj[:is_obbligatorio]
          @meta_parametri_fdc[np][:is_forced][p_name] = p_obj.id if p_obj[:is_forced]
          @meta_parametri_fdc[np][:no_restricted][p_name] = p_obj.id unless p_obj[:is_restricted]
          @meta_parametri_fdc[np][:upd_on_crt][p_name] = p_obj.id if p_obj[:is_update_on_create]
          next unless p_obj.nome_struttura
          # puts "CCCCCCC (#{p_name}): p_obj.nome_struttura #{p_obj.nome_struttura}"
          strutture[p_obj.nome_struttura] ||= {}
          strutture[p_obj.nome_struttura][p_name] = p_obj.id
        end
        strutture.keys.each do |nome_s|
          params.each do |p_name, p_obj|
            strutture[nome_s][p_name] = p_obj.id if p_name.start_with?(nome_s + '_') && p_obj.is_to_export
          end
        end
        # puts "CCCCCCC strutture #{strutture}"
        strutture.each do |nome_struttura, parametri_in_struct|
          parametri_in_struct.each do |p_name, _p_id|
            @meta_parametri_fdc[np][:strutturati_con_ibridi][p_name] = { nome_struttura => parametri_in_struct.keys - [p_name] }
          end
        end
      end
      (np_me - @meta_parametri_fdc.keys).each do |np|
        @meta_parametri_fdc[np] ||= { is_obbligatorio: {}, is_to_export: {}, is_forced: {},
                                      upd_on_crt: {}, no_restricted: {}, strutturati_con_ibridi: {} }
      end
    end

    def carica_meta_entita_calcolo(filtro_metamodello: nil) # rubocop:disable Metrics/AbcSize
      # { 'root' => { me_root_np => me_root_obj}, '0'(fase_pi) => {me1_np => me1_obj,...}, fase_ref: {...}, fase_adj: {...} }
      @meta_entita_calcolo = {}
      fm = filtro_metamodello || {}
      np_da_considerare = nil
      unless fm.empty?
        np_da_considerare = []
        fm.keys.each { |nnpp| np_da_considerare |= nnpp.np_hierarchy }
      end

      Constant.constants(:fase_calcolo).map(&:value).each do |fase|
        @meta_entita_calcolo[fase.to_s] = @meta_entita.select { |k, v| v.fase_di_calcolo == fase && (np_da_considerare.nil? || np_da_considerare.include?(k)) }.sort_by_key
        next unless fase == FASE_CALCOLO_PI && @meta_entita_calcolo[ROOT].nil?
        xxx = @meta_entita_calcolo[fase.to_s].first
        if xxx && xxx[1].livello == 1
          @meta_entita_calcolo[fase.to_s].shift
          @meta_entita_calcolo[ROOT] = { xxx[0] => xxx[1] }
        else
          @meta_entita_calcolo[ROOT] = {}
        end
      end
      @meta_entita_calcolo
    end

    def carica_meta_parametri_calcolo(filtro_metamodello: nil) # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/CyclomaticComplexity
      # { naming_path: { predefiniti: {nome_p1 => p1_obj,...}, da_calcolare: {...}, da_calcolare_ae: {...} } }
      carica_meta_parametri_strutturati # serve per completa_lista_parametri
      @meta_parametri_calcolo = {}
      @meta_entita_calcolo.values.map(&:keys).flatten.uniq.each do |np|
        # fm = (filtro_metamodello || {}).empty? ? nil : (filtro_metamodello[np] || [])
        fm = unless (filtro_metamodello || {}).empty?
               if (filtro_metamodello[np] || []).is_a?(Array)
                 filtro_metamodello[np] || []
               else
                 filtro_metamodello[np][FILTRO_MM_PARAMETRI] || []
               end
             end
        # no filter or wildcard means no filtering
        fm = nil if fm && fm.first == META_PARAMETRO_ANY

        # completo il filtro con parametri strutturati presenti parzialmente
        fm = completa_lista_parametri(np, fm)

        (@meta_parametri[np] || {}).each do |p_name, p_obj|
          next unless fm.nil? || fm.include?(p_name)
          @meta_parametri_calcolo[np] ||= { predefiniti: {}, da_calcolare: {}, da_calcolare_ae: {} }
          @meta_parametri_calcolo[np][:predefiniti][p_name] = p_obj if p_obj[:is_predefinito] == true
          @meta_parametri_calcolo[np][:da_calcolare][p_name] = p_obj if p_obj.da_calcolare?
          @meta_parametri_calcolo[np][:da_calcolare_ae][p_name] = p_obj if p_obj.da_calcolare_ae?
        end
      end
      @meta_parametri_calcolo
    end

    def carica_meta_parametri_fu # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      current_struct = ''
      struct_mp_progress = []
      @meta_parametri.each do |me_np, m_params|
        @meta_parametri_fu[me_np] ||= {}
        struct_mp_progress = []
        current_struct = ''
        m_params.keys.sort.each do |meta_param|
          mp = meta_param.split(TEXT_STRUCT_NAME_SEP)
          if mp.size == 1
            @meta_parametri_fu[me_np][mp[0]] = [mp[0]]
            unless struct_mp_progress.empty?
              @meta_parametri_fu[me_np][struct_mp_progress.join(TEXT_STRUCT_SEP)] = struct_mp_progress
              current_struct = ''
              struct_mp_progress = []
            end
          elsif mp[0] == current_struct
            struct_mp_progress << meta_param
          else
            @meta_parametri_fu[me_np][struct_mp_progress.join(TEXT_STRUCT_SEP)] = struct_mp_progress unless struct_mp_progress.empty?
            current_struct = mp[0]
            struct_mp_progress = [meta_param]
          end
        end
        @meta_parametri_fu[me_np][struct_mp_progress.join(TEXT_STRUCT_SEP)] = struct_mp_progress unless struct_mp_progress.empty?
      end
    end

    def carica_meta_parametri_strutturati
      @meta_parametri.each do |me_np, m_paramlist|
        m_paramlist.keys.each do |m_param|
          if m_param.include?(TEXT_STRUCT_NAME_SEP)
            @meta_parametri_strutturati[me_np] ||= []
            @meta_parametri_strutturati[me_np] << m_param
          end
        end
        next unless @meta_parametri_strutturati[me_np]
        @meta_parametri_strutturati_per_struttura[me_np] = {}
        @meta_parametri_strutturati[me_np].sort.each do |mp|
          struttura = mp.split(TEXT_STRUCT_NAME_SEP)[0]
          @meta_parametri_strutturati_per_struttura[me_np][struttura] ||= []
          @meta_parametri_strutturati_per_struttura[me_np][struttura] << mp
        end
      end
    end

    def verifica_entita(np)
      np = np.naming_path if np.is_a?(@kfl.classe_meta_entita)
      return meta_entita[np] if meta_entita && meta_entita[np]
      false
    end

    def verifica_entita_per_nome(me)
      if meta_entita
        return me if meta_entita[me] # caso root
        idx = meta_entita.keys.find_index { |np| np.end_with?NAMING_PATH_SEP + me.to_s }
        return meta_entita.keys[idx] unless idx.nil?
      end
      false
    end

    def verifica_esistenza_parametro(naming_path, struct_e_param)
      # struct_e_param e' un array [struct,param]
      return meta_parametri[naming_path][struct_e_param][:genere] if meta_parametri && meta_parametri[naming_path] && meta_parametri[naming_path][struct_e_param]
      nil
    end

    # [px, py, s.p1] ---> [px, py, s.p1, s. ..., s.pn]
    def completa_lista_parametri(naming_path, array_param)
      return array_param unless array_param
      ret = []
      mps = @meta_parametri_strutturati[naming_path]
      sss = @meta_parametri_strutturati_per_struttura[naming_path]
      if mps && sss
        (array_param || []).each do |param|
          next unless mps.include?(param)
          ret |= sss[param.split(TEXT_STRUCT_NAME_SEP)[0]] || []
        end
      end
      array_param | ret
    end

    def info_valore_parametro(valore)
      case valore
      when Hash
        META_PARAMETRO_STRUTTURATO
      when Array
        META_PARAMETRO_MULTIVALORE
      else
        META_PARAMETRO_SEMPLICE
      end
    end

    #     "param_s"=>"aaa"  ----->  "aaa"
    #     "param_s"=>""     ----->  NO_VAL
    #     "param_mv"=>["bbb","ccc"], ---> "bbb|ccc"
    #     "param_mv"=>[]             ---> NO_VAL
    #     "struct1.p1"=>["ddd"],     ---> "ddd"
    #     "struct2.p21"=>["fff","hhh"], ---> "fff|hhh"
    #     "struct2.p22=>["xxx",nil], ---> "xxx|NO_VAL"
    #     "struct2.p23=>[nil, "xxx"], ---> "NO_VAL|xxx"
    #     "struct2.p24=>['yyy', nil, "xxx"], ---> "yyy|NO_VAL|xxx"
    #
    #     "struct3.p31"=>[["lll","mmm"]],    ---> "lll|mmm"
    #     "struct3.p11"=>[[nil,"mmm"]],    ---> "NO_VAL|mmm"
    #     "struct4.p41"=>[["ppp","qqq"],["sss","ttt"]], ---> "ppp|qqq!sss|ttt"
    def self.parametro_to_s(param_value, fu_mode = true) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/MethodLength
      no_val = fu_mode ? TEXT_NO_VAL : ''
      parametro_assente = fu_mode ? TEXT_PARAMETRO_ASSENTE : ''
      return parametro_assente if param_value.nil?
      return (param_value.empty? ? no_val : param_value) if param_value.is_a?(String)
      # a questo punto param_value deve essere un Array...
      return no_val if param_value.empty?
      array_di_array = false
      param_value.map do |sub|
        sub = no_val if sub.nil? || sub.empty?
        if sub.is_a?(Array)
          array_di_array = true
          sub.map do |subsub|
            subsub = no_val if subsub.nil? || subsub.empty?
            subsub
          end.join(TEXT_ARRAY_ELEM_SEP)
        else
          sub
        end
      end.join(array_di_array ? TEXT_SUB_ARRAY_ELEM_SEP : TEXT_ARRAY_ELEM_SEP)
    end

    def self.keywords_fisico_logico(is_fisico = false)
      @keywords_fisico_logico ||= { true => OpenStruct.new(classe_vendor_release: Db::VendorReleaseFisico,
                                                           field_vr_id: 'vendor_release_fisico_id',
                                                           classe_meta_entita: Db::MetaEntitaFisico,
                                                           field_me_id: 'meta_entita_fisico_id',
                                                           classe_meta_parametro: Db::MetaParametroFisico),
                                    false => OpenStruct.new(classe_vendor_release: Db::VendorRelease,
                                                            field_vr_id: 'vendor_release_id',
                                                            classe_meta_entita: Db::MetaEntita,
                                                            field_me_id: 'meta_entita_id',
                                                            classe_meta_parametro: Db::MetaParametro)
      }
      @keywords_fisico_logico[is_fisico]
    end

    def naming_path_alberatura(np_root)
      (meta_entita || {}).keys.select { |np| np.start_with?("#{np_root}#{NAMING_PATH_SEP}") }
    end

    # meta_modello mergiato per piu' vendor_release/vendor_release_fisico
    def self.meta_modello_merged(vendor_release_id_list:, is_fisico: false, **opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      # metamodello e poi si fa il merge
      x_metamodello = MetaModello.new(is_fisico: is_fisico)
      vendor_release_id_list.each do |id_vr|
        mm = MetaModello.new(is_fisico: is_fisico).carica_da_db(id_vr, **opts)
        x_metamodello.meta_entita.update(mm.meta_entita)
        x_metamodello.meta_entita_mapping.update(mm.meta_entita_mapping)
        mm.meta_parametri.each do |np, m_params|
          x_metamodello.meta_parametri[np] ||= {}
          x_metamodello.meta_parametri[np].update(m_params)
        end
        # per_export
        mm.meta_parametri_fu.each do |np, m_params|
          x_metamodello.meta_parametri_fu[np] ||= {}
          x_metamodello.meta_parametri_fu[np].update(m_params)
        end
        mm.meta_parametri_strutturati.each do |np, m_params|
          x_metamodello.meta_parametri_strutturati[np] ||= []
          x_metamodello.meta_parametri_strutturati[np] |= m_params
        end
        # per_fdc
        x_metamodello.meta_entita_fdc['relazioni_adj'] ||= {}
        x_metamodello.meta_entita_fdc['relazioni_adj'].update(mm.meta_entita_fdc['relazioni_adj'] || {})
        Constant.constants(:operazioni_ammesse).map(&:value).each do |oper|
          oper_s = oper.to_s
          x_metamodello.meta_entita_fdc[oper_s] ||= {}
          x_metamodello.meta_entita_fdc[oper_s].update(mm.meta_entita_fdc[oper_s] || {})
        end
        mm.meta_parametri_fdc.each do |np, info_param|
          x_metamodello.meta_parametri_fdc[np] ||= {}
          info_param.keys.each do |kkk|
            x_metamodello.meta_parametri_fdc[np][kkk] ||= {}
            x_metamodello.meta_parametri_fdc[np][kkk].update(mm.meta_parametri_fdc[np][kkk] || {})
          end
        end
      end
      x_metamodello
    end
  end
end
