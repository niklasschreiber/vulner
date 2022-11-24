# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20171010
#
require_relative 'segnalazioni_per_funzione'
require_relative 'import_formato_utente/text'
require_relative 'import_formato_utente/xls'
require_relative 'creazione_fdc/writer'
require_relative 'creazione_fdc_cna'

module Irma
  #
  module Funzioni
    # rubocop:disable Metrics/ClassLength, Metrics/MethodLength
    class CreazioneFdc
      include SegnalazioniPerFunzione
      include RelazioniAdj

      attr_reader :logger, :sistema_ambiente_archivio, :saa_master, :metamodello, :vendor_instance, :funzione, :log_prefix
      attr_reader :lista_entita_canc, :entita_ok

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def initialize(sistema_ambiente_archivio:, **opts)
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @funzione           = Db::Funzione.get_by_pk(opts[:funzione])
        @saa_master         = sistema_ambiente_archivio
        @saa_rif            = opts[:saa_rif]
        @vendor_instance    = opts[:vendor_instance] || @saa_master.vendor_instance
        @scrivi_version     = @vendor_instance.version_in_fdc?
        # TODO: Valutare la numrosita' per usare eventualmente hash non in memoria (MapDb...)
        @lista_entita_canc  = nil
        @entita_ok          = { MANAGED_OBJECT_OPERATION_CREATE => {},
                                MANAGED_OBJECT_OPERATION_UPDATE => {},
                                MANAGED_OBJECT_OPERATION_DELETE => {}
        }
        @op_non_ammessa = { MANAGED_OBJECT_OPERATION_CREATE => {},
                            MANAGED_OBJECT_OPERATION_UPDATE => {},
                            MANAGED_OBJECT_OPERATION_DELETE => {}
        }
        @entita_del_crt = {}
        #
        @entita_no_update = {}
        #
        @lista_file_canc    = opts[:lista_file_canc]
        @formato_file_canc  = opts[:formato_file_canc]
        @solo_delete        = opts[:solo_delete]
        #
        # { RETE_GSM => [...], RETE_LTE => [...], RETE_UMTS => [...] }
        # una o piu' chiavi possono mancare...
        # gli array possono essere vuoti o contenere uno o piu' parole chiave: 'ALL', 'INTRA', 'INTER'
        @cancellazione_relazioni_adj = opts[:canc_rel_adj]
        #
        @writer_opts = {
          out_dir:         opts[:out_dir],
          label_nome_file: opts[:label_nome_file],
          modo_creazione:  opts[:modo_creazione_fdc],
          formato:         opts[:formato_fdc]
        }
        #
        @flag_del_crt       = opts[:flag_del_crt]
        @metamodello        = opts[:metamodello]
        @logger             = opts[:logger] || Irma.logger
        @log_prefix         = opts[:log_prefix] || "Creazione FdC (#{@saa_master.full_descr})"
      end

      def nuova_segnalazione(tipo_segnalazione, opts = {})
        tipo_segnalazione += 1 if funzione.id == FUNZIONE_CREAZIONE_FDC_OMC_FISICO && !TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
        super(tipo_segnalazione, opts)
      end

      def dataset_master
        raise 'Fonte master non specificata' unless @saa_master
        @dataset_master ||= @saa_master.dataset(use_pi: true)
      end

      def dataset_rif
        raise 'Fonte riferimento non specificata' unless @saa_rif
        @dataset_rif ||= @saa_rif.dataset(use_pi: @saa_rif.pi.nil? ? false : true)
      end

      def table_name_master
        raise 'Fonte master non specificata' unless @saa_master
        @table_name_master ||= @saa_master.pi.entita.table_name
      end

      def table_name_rif
        raise 'Fonte riferimento non specificata' unless @saa_rif
        @table_name_rif ||= @saa_rif.pi.nil? ? @saa_rif.entita.table_name : @saa_rif.pi.entita.table_name
      end

      def parametri_per_create(parametri:, naming_path:)
        return {} unless parametri
        parametri.select { |k, _v| metamodello.meta_parametri_fdc[naming_path][:is_to_export][k] }
      end

      def parametri_per_update_on_create(parametri:, naming_path:, dist_name:)
        return {} unless parametri
        ppp = parametri.select { |k, _v| metamodello.meta_parametri_fdc[naming_path][:upd_on_crt][k] }
        # completo strutturati
        buchi = {}
        completa_strutturati(naming_path, parametri, ppp, buchi)
        # check completezza strutture
        check_completezza_strutture(dist_name, buchi)
        ppp
      end

      def parametri_per_update(naming_path:, parametri:, parametri_rif:, dist_name:)
        mp_fdc = metamodello.meta_parametri_fdc[naming_path]
        return {} unless parametri
        # 1. tengo solo i parametri is_to_export, non avvalorati in parametri_rif, o con valore diverso
        ppp = parametri.select { |k, v| mp_fdc[:is_to_export][k] && (parametri_rif.nil? || parametri_rif[k].nil? || (parametri_rif[k] && parametri_rif[k] != v)) }
        # 2. nil --> '' e check is_restricted
        (ppp || {}).keys.each do |k|
          ppp[k] = '' if ppp[k].nil?
          next if mp_fdc[:no_restricted][k]
          nuova_segnalazione(TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_UPDATE_PARAM_RESTRICTED, dn: dist_name, parametro: k)
          ppp.delete(k)
        end
        # 3. aggiungo eventuali is_forced
        unless ppp.empty?
          (mp_fdc[:is_forced] || {}).keys.each do |p_name|
            val_master = parametri.keys.include?(p_name) ? (parametri[p_name] || '') : nil
            ppp[p_name] = val_master || parametri_rif[p_name] || ''
          end
        end
        # 4. completo strutturati
        buchi = {}
        completa_strutturati(naming_path, parametri, ppp, buchi)
        # 5. check completezza strutture
        check_completezza_strutture(dist_name, buchi)
        ppp
      end

      def completa_strutturati(naming_path, parametri, ppp, buchi = {})
        mp_fdc = metamodello.meta_parametri_fdc[naming_path]
        (ppp || {}).keys.each do |p_name|
          next if (mp_fdc[:strutturati_con_ibridi][p_name] || {}).empty? # p_name non e' uno strutturato
          nome_struttura = mp_fdc[:strutturati_con_ibridi][p_name].keys.first
          next if buchi[nome_struttura] # struttura gia' completata
          buchi[nome_struttura] = []
          mp_fdc[:strutturati_con_ibridi][p_name][nome_struttura].each do |p_name_struct|
            val_master = parametri.keys.include?(p_name_struct) ? (parametri[p_name_struct] || '') : nil
            if val_master
              ppp[p_name_struct] = val_master
            else
              buchi[nome_struttura] << p_name_struct
            end
          end
        end
      end

      def check_completezza_strutture(dist_name, buchi)
        (buchi || {}).each do |nome_struct, params_mancanti|
          next if params_mancanti.empty?
          nuova_segnalazione(TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_STRUTTURATO_NON_COMPLETO,
                             dn: dist_name, struct: nome_struct,
                             p_mancanti: params_mancanti.map(&:to_s).join(','))
        end
      end

      class ManagedObjectFdc < OpenStruct
        def initialize(dist_name:, naming_path:, is_relazione_adj:, version: nil, parametri: {})
          me = naming_path.split(NAMING_PATH_SEP).last
          super(dist_name:        dist_name,
                naming_path:      naming_path,
                version:          version,
                meta_entita:      me,
                is_relazione_adj: is_relazione_adj,
                parametri:        parametri
               )
        end
        # operazione, scarto, tipo_segnalazione, opts_segnalazione, auto_canc_rel_adj

        def scarto?
          scarto ? true : false
        end

        def da_creare?
          operazione == MANAGED_OBJECT_OPERATION_CREATE && !scarto
        end

        def auto_canc_rel_adj?
          auto_canc_rel_adj ? true : false
        end
      end

      def elabora_da_cancellare(dist_name:, naming_path:, **hash)
        nuova_entita = ManagedObjectFdc.new(dist_name: dist_name, naming_path: naming_path,
                                            is_relazione_adj: metamodello.meta_entita_fdc['relazioni_adj'][naming_path])
        nuova_entita.operazione = MANAGED_OBJECT_OPERATION_DELETE
        unless  hash[:skip_check_dataset_rif]
          unless dataset_rif.where(dist_name: dist_name).first
            puts "XXX #{dist_name}: scarto in delete perche' non presente in dataset_rif..." if ENV['PUTS_FDC']
            nuova_entita.scarto = true
            return nuova_entita
          end
        end
        unless metamodello.meta_entita_fdc[OPERAZIONI_AMMESSE_DELETE.to_s][naming_path]
          puts "XXX #{dist_name}: scarto in delete per operazioni_ammesse..." if ENV['PUTS_FDC']
          nuova_entita.scarto = true
          unless @op_non_ammessa[MANAGED_OBJECT_OPERATION_DELETE][naming_path]
            nuova_entita.tipo_segnalazione = TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_NODELETE_OP_NON_AMMESSA
            @op_non_ammessa[MANAGED_OBJECT_OPERATION_DELETE][naming_path] = true
          end
          return nuova_entita
        end
        # if @entita_ok[MANAGED_OBJECT_OPERATION_CREATE][dist_name] || @entita_ok[MANAGED_OBJECT_OPERATION_UPDATE][dist_name]
        unless hash[:delete_in_delcrt]
          # questo controllo non va fatto se si tratta di delete in delete/create
          if dataset_master.where(dist_name: dist_name).first
            puts "XXX #{dist_name}: scarto in delete per entita presente in fonte master..." if ENV['PUTS_FDC']
            nuova_entita.scarto = true
            nuova_entita.tipo_segnalazione = TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_NODELETE_IN_MASTER
            return nuova_entita
          end
        end
        nuova_entita
      end

      # TODO: Pensare ad un modo di ricerca piu' performante...
      def entita_figlia_di_cancellata(dist_name)
        @entita_ok[MANAGED_OBJECT_OPERATION_DELETE].keys.find { |parent| dist_name.start_with?(parent + DIST_NAME_SEP) }
      end

      def relazioni_adj(me_sorgente, delete_in_delcrt: false)
        me_list = []
        flag = vendor_instance.imposta_flag_cell_adj(me_sorgente.naming_path)
        mo = ImportFormatoUtente::Text::ManagedObject.new(dist_name: me_sorgente.dist_name)
        entita_in_relazioni_adj = cancella_relazioni_adj_da_sorgente(entita_sorgente: mo,
                                                                     saa: @saa_rif,
                                                                     vendor_instance: vendor_instance,
                                                                     dataset: dataset_rif,
                                                                     flag_cell_adj: flag,
                                                                     esegui_delete: false)
        entita_in_relazioni_adj.each do |ent_in_relazione|
          dn, np, _vvv = ent_in_relazione
          me_delete_rel = elabora_da_cancellare(dist_name: dn, naming_path: np,  delete_in_delcrt: delete_in_delcrt)
          me_list << me_delete_rel # if me_delete_rel.operazione == MANAGED_OBJECT_OPERATION_DELETE
        end
        me_list
      end

      def cella_reparented(dist_name)
        vendor_instance.cella_reparented(dist_name, dataset_rif)
      end

      def entita_da_cancellare(writer:, res:, info_progresso:)
        logger.info("#{log_prefix}. Inizio elaborazione entita' per DELETE")
        puts "XXX @lista_entita_canc: #{@lista_entita_canc}" if ENV['PUTS_FDC']
        puts "XXX @entita_del_crt: #{@entita_del_crt.keys}"  if ENV['PUTS_FDC']
        # le cancellazioni vanno fatte in ordine di dist_name (prima i padri o poi i figli), ma con priority (se presente) inversa.
        @vendor_instance.fdc_sort_by_priority(@lista_entita_canc | @entita_del_crt.keys, invert: true).each do |dn_canc|
          del_crt = (@flag_del_crt && @entita_del_crt[dn_canc] ? true : false)
          np = dn_canc.split(DIST_NAME_SEP).map { |el| el.split(DIST_NAME_VALUE_SEP).fetch(0) }.join(NAMING_PATH_SEP)
          # delete 'normale'
          next if entita_figlia_di_cancellata(dn_canc)
          me_list = []
          me_delete = elabora_da_cancellare(dist_name: dn_canc, naming_path: np, delete_in_delcrt: del_crt)
          me_list << me_delete
          me_list += relazioni_adj(me_delete, delete_in_delcrt: del_crt) unless me_delete.scarto?
          me_list.each do |eee|
            gestisci_entita(entita: eee, writer: writer, res: res)
          end
          info_progresso.incr if info_progresso
        end
        logger.info("#{log_prefix}. Terminata elaborazione entita' per DELETE")
      end

      def elabora_presente_assente(dist_name:, naming_path:, version:, parametri: {}, **hash)
        mp_fdc = metamodello.meta_parametri_fdc[naming_path]
        nuova_entita = ManagedObjectFdc.new(dist_name: dist_name, naming_path: naming_path, version: version, is_relazione_adj: metamodello.meta_entita_fdc['relazioni_adj'][naming_path])
        if metamodello.meta_entita_fdc[OPERAZIONI_AMMESSE_CREATE.to_s][naming_path]
          # create
          ppp = parametri_per_create(parametri: parametri, naming_path: naming_path)
          p_obbl = mp_fdc[:is_obbligatorio].keys - (ppp.keys & mp_fdc[:is_obbligatorio].keys)
          unless p_obbl.empty?
            puts "XXX #{dist_name}: scarto per is_obbligatorio mancante (#{p_obbl})." if ENV['PUTS_FDC']
            nuova_entita.tipo_segnalazione = TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_NOCREATE_PARAM_OBBLIG
            nuova_entita.opts_segnalazione = { parametro: p_obbl }
            nuova_entita.operazione = MANAGED_OBJECT_OPERATION_CREATE
            nuova_entita.scarto = true
            return nuova_entita
          end
          # CREATE
          nuova_entita.parametri  = ppp
          nuova_entita.operazione = MANAGED_OBJECT_OPERATION_CREATE
          puts "XXX #{dist_name}: ok per operazioni_create..." if ENV['PUTS_FDC']
        elsif !hash[:no_create_update] &&
              metamodello.meta_entita_fdc[OPERAZIONI_AMMESSE_UPDATE.to_s][naming_path] &&
              !(mp_fdc[:upd_on_crt] || {}).empty? &&
              !(ppp = parametri_per_update_on_create(parametri: parametri, naming_path: naming_path, dist_name: dist_name)).empty?
          # UPDATE ON CREATE
          nuova_entita.parametri  = ppp
          nuova_entita.operazione = MANAGED_OBJECT_OPERATION_UPDATE
        else
          puts "XXX #{dist_name}: scarto per operazioni_ammesse...create" if ENV['PUTS_FDC']
          unless @op_non_ammessa[MANAGED_OBJECT_OPERATION_CREATE][naming_path]
            nuova_entita.tipo_segnalazione = TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_NOCREATE_OP_NON_AMMESSA
            @op_non_ammessa[MANAGED_OBJECT_OPERATION_CREATE][naming_path] = true
          end
          nuova_entita.operazione = MANAGED_OBJECT_OPERATION_CREATE
          nuova_entita.scarto = true
        end
        nuova_entita
      end

      def entita_presenti_assenti_del_crt(writer:, res:, info_progresso:)
        logger.info("#{log_prefix}. Inizio elaborazione entita' per CREATE")
        celle_in_reparenting = []
        return unless @flag_del_crt && !@entita_del_crt.empty?
        last_idx = 0
        entita_del_crt_arr = @vendor_instance.fdc_sort_by_priority(@entita_del_crt.keys)
        entita_assenti_arr = []
        query = @vendor_instance.query_fdc_presenti_assenti(table_name_master: table_name_master, table_name_rif: table_name_rif)
        begin
          dataset_master.db.transaction do
            dataset_master.db[query].select([:dist_name, :naming_path, :version, :parametri]).each do |dd|
              # puts "passo 1, dd= #{dd[:dist_name]}, d_dc= #{entita_del_crt_arr[last_idx]}"
              while trova_precedenza_dn(entita_del_crt_arr[last_idx], dd[:dist_name]) == -1
                # puts "dentro il while con dn = #{entita_del_crt_arr[last_idx]}"
                dn_del_crt = entita_del_crt_arr[last_idx]
                ppp = @entita_del_crt[dn_del_crt]
                vvv = (ppp || {}).delete('version')
                nnp = (ppp || {}).delete('naming_path')
                me = elabora_presente_assente(dist_name: dn_del_crt, naming_path: nnp, version: vvv, parametri: ppp)
                gestisci_entita(entita: me, writer: writer, res: res)
                info_progresso.incr if info_progresso
                last_idx += 1
              end
              # controllo se l'entita in del_crt e' anche in create, in questo caso non e' una vera del_crt in quanto assente sulla fonte di riferimento, non si dovra' quindi chiamare la delete.
              # Al termine della query, si toglie da @entita_del_crt le entita su cui non va chiamata la cancellazione (entita_assenti_arr)
              if entita_del_crt_arr[last_idx] == dd[:dist_name]
                entita_assenti_arr << dd[:dist_name]
                last_idx += 1
              end
              # scrivo dd
              # puts "fuori il while con dn = #{dd[:dist_name]}"
              dn = dd[:dist_name]
              np = dd[:naming_path]
              vv = dd[:version]
              params = dd[:parametri]
              me = elabora_presente_assente(dist_name: dn, naming_path: np, version: vv, parametri: params)
              gestisci_entita(entita: me, writer: writer, res: res)
              # ------------
              # REPARENTING
              if @vendor_instance.naming_path_cella?(me.naming_path) && me.da_creare? && (cella_old = cella_reparented(me.dist_name))
                puts "XXX Reparenting: cella riparentata: #{me.dist_name}" if ENV['PUTS_FDC']
                celle_in_reparenting << [cella_old, dd]
              end
              # ------------
              info_progresso.incr if info_progresso
            end
            # scrivo eventuali entita_del_crt ancora non scodate
            (last_idx..entita_del_crt_arr.size - 1).each do |idx|
              # puts "fuori tutto con idx = #{idx} e dn = #{entita_del_crt_arr[idx]}"
              dn_del_crt = entita_del_crt_arr[idx]
              ppp = @entita_del_crt[dn_del_crt]
              vvv = (ppp || {}).delete('version')
              nnp = (ppp || {}).delete('naming_path')
              me = elabora_presente_assente(dist_name: dn_del_crt, naming_path: nnp, version: vvv, parametri: ppp)
              gestisci_entita(entita: me, writer: writer, res: res)
              info_progresso.incr if info_progresso
            end
            entita_assenti_arr.each { |dn| @entita_del_crt.delete(dn) }
            elabora_celle_riparentate(celle_in_reparenting: celle_in_reparenting, writer: writer, res: res) unless celle_in_reparenting.empty?
          end
          logger.info("#{log_prefix}. Terminata elaborazione entita' per CREATE")
        rescue => e
          res[:eccezione] = "#{e}: #{e.message} - db.transaction in entita_presenti_assenti"
          logger.error("#{@log_prefix} catturata eccezione (#{res})")
          raise
        end
      end

      def trova_precedenza_dn(dn_a, dn_b)
        return nil if dn_a.to_s.empty? || dn_b.to_s.empty?
        ret = 0
        return ret if dn_a == dn_b
        first_dn = @vendor_instance.fdc_sort_by_priority([dn_a, dn_b]).first
        first_dn == dn_a ? ret -= 1 : ret += 1
        ret
      end

      def entita_presenti_assenti(writer:, res:, info_progresso:)
        logger.info("#{log_prefix}. Inizio elaborazione entita' per CREATE")
        celle_in_reparenting = []
        query = @vendor_instance.query_fdc_presenti_assenti(table_name_master: table_name_master, table_name_rif: table_name_rif)

        #-----------------------------------------------------------------------------------------------------
        begin
          dataset_master.db.transaction do
            dataset_master.db[query].select([:dist_name, :naming_path, :version, :parametri]).each do |dd|
              dn = dd[:dist_name]
              np = dd[:naming_path]
              vv = dd[:version]
              params = dd[:parametri]
              me = elabora_presente_assente(dist_name: dn, naming_path: np, version: vv, parametri: params)
              gestisci_entita(entita: me, writer: writer, res: res)
              # ------------
              # REPARENTING
              if @vendor_instance.naming_path_cella?(np) && me.da_creare? && (cella_old = cella_reparented(dn))
                puts "XXX Reparenting: cella riparentata: #{dn}" if ENV['PUTS_FDC']
                celle_in_reparenting << [cella_old, dd]
              end
              # ------------
              info_progresso.incr if info_progresso
            end
            elabora_celle_riparentate(celle_in_reparenting: celle_in_reparenting, writer: writer, res: res) unless celle_in_reparenting.empty?
          end
          logger.info("#{log_prefix}. Terminata elaborazione entita' per CREATE")
        rescue => e
          res[:eccezione] = "#{e}: #{e.message} - db.transaction in entita_presenti_assenti"
          logger.error("#{@log_prefix} catturata eccezione (#{res})")
          raise
        end
      end

      def elabora_celle_riparentate(celle_in_reparenting:, writer:, res:)
        puts "XXX Reparenting: celle riparentate: #{celle_in_reparenting.count}" if ENV['PUTS_FDC']
        @vendor_instance.entita_per_reparenting(celle_in_reparenting: celle_in_reparenting, dataset_master: dataset_master, dataset_rif: dataset_rif) do |eee|
          puts "XXX Reparenting: cella in #{eee[:operazione]}: #{eee[:dist_name]}" if ENV['PUTS_FDC']
          case eee[:operazione]
          when MANAGED_OBJECT_OPERATION_DELETE
            me_d = elabora_da_cancellare(dist_name: eee[:dist_name], naming_path: eee[:naming_path], skip_check_dataset_rif: true, delete_in_delcrt: true)
            gestisci_entita(entita: me_d, writer: writer, res: res)
          when MANAGED_OBJECT_OPERATION_CREATE
            me_c = elabora_presente_assente(dist_name: eee[:dist_name], naming_path: eee[:dist_name], version: eee[:version] || '',
                                            parametri: eee[:parametri] || {}, no_create_update: true)
            gestisci_entita(entita: me_c, writer: writer, res: res)
            # memorizzo dist_name per evitare update
            @entita_no_update[eee[:dist_name]] = true
          end
        end
      end

      def elabora_differente(dist_name:, naming_path:, version:, parametri:, parametri_rif:)
        nuova_entita = ManagedObjectFdc.new(dist_name: dist_name, naming_path: naming_path, version: version, is_relazione_adj: metamodello.meta_entita_fdc['relazioni_adj'][naming_path])
        nuova_entita.operazione = MANAGED_OBJECT_OPERATION_UPDATE
        # Se l'entita' e' da cancellare, non la inserisco in update
        # in caso di flag_del_crt, oltre all'entita da cancellare devo prendere anche gli eventuali figli da ricreare...
        if @flag_del_crt && @entita_del_crt.include?(dist_name)
          # puts "in elabora_differente dist_name upd da mettere in del/crea: #{dist_name}"
          nuova_entita.scarto = true
          return nuova_entita
        end
        if metamodello.meta_entita_fdc[OPERAZIONI_AMMESSE_UPDATE.to_s][naming_path]
          ppp = parametri_per_update(naming_path: naming_path,
                                     parametri: parametri, parametri_rif: parametri_rif,
                                     dist_name: dist_name)

          # esistenza parametri da scrivere
          if ppp.empty?
            nuova_entita.scarto = true
          else
            nuova_entita.parametri = ppp
          end
        else
          puts "XXX #{dist_name}: scarto in update per operazioni_ammesse..." if ENV['PUTS_FDC']
          unless @op_non_ammessa[MANAGED_OBJECT_OPERATION_UPDATE][naming_path]
            nuova_entita.tipo_segnalazione = TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_NOUPDATE_OP_NON_AMMESSA
            @op_non_ammessa[MANAGED_OBJECT_OPERATION_UPDATE][naming_path] = true
          end
          nuova_entita.scarto = true
        end
        nuova_entita
      end

      def entita_differenti(writer:, res:, info_progresso:)
        query = 'select a.dist_name, a.naming_path, a.version, a.parametri as p_master, b.parametri as p_rif'
        query += " from #{table_name_master} a join #{table_name_rif} b on a.dist_name=b.dist_name"
        query += ' where a.parametri::jsonb!=b.parametri::jsonb order by a.livello, a.dist_name COLLATE "C"'

        logger.info("#{log_prefix}. Inizio elaborazione entita' per UPDATE")
        puts "XXX entita_no_update: #{@entita_no_update}" if ENV['PUTS_FDC']
        begin
          dataset_master.db.transaction do
            dataset_master.db[query].each do |row|
              dn = row[:dist_name]
              np = row[:naming_path]
              vv = row[:version]
              p_master = row[:p_master] || {}
              p_rif = row[:p_rif] || {}
              next if p_master.empty? && p_rif.empty?
              puts "XXX skip update per: #{dn}" if @entita_no_update[dn] && ENV['PUTS_FDC']
              next if @entita_no_update[dn]
              me = elabora_differente(dist_name: dn, naming_path: np, version: vv, parametri: p_master, parametri_rif: p_rif)
              gestisci_entita(entita: me, writer: writer, res: res)
              info_progresso.incr if info_progresso
            end
          end
          logger.info("#{log_prefix}. Inizio elaborazione entita' per UPDATE")
        rescue => e
          res[:eccezione] = "#{e}: #{e.message} - db.transaction in entita_differenti"
          logger.error("#{@log_prefix} catturata eccezione (#{res})")
          raise
        end
      end

      def elabora_cancellazione_rel_adj(dist_name:, naming_path:)
        nuova_entita = ManagedObjectFdc.new(dist_name: dist_name, naming_path: naming_path, is_relazione_adj: metamodello.meta_entita_fdc['relazioni_adj'][naming_path])
        nuova_entita.auto_canc_rel_adj = true

        nuova_entita.operazione = MANAGED_OBJECT_OPERATION_DELETE
        unless metamodello.meta_entita_fdc[OPERAZIONI_AMMESSE_DELETE.to_s][naming_path]
          puts "XXX #{dist_name}: scarto in delete per operazioni_ammesse..." if ENV['PUTS_FDC']
          nuova_entita.scarto = true
          nuova_entita.tipo_segnalazione = TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_NODELETE_OP_NON_AMMESSA
          return nuova_entita
        end
        if dataset_master.where(dist_name: dist_name).first
          puts "XXX #{dist_name}: scarto in delete per entita presente in fonte master..." if ENV['PUTS_FDC']
          nuova_entita.scarto = true
          # nuova_entita.tipo_segnalazione = TIPO_SEGNALAZIONE_CREAZIONE_FDC_OMC_LOGICO_DATI_NODELETE_IN_MASTER
          return nuova_entita
        end
        nuova_entita
      end

      def np_cancellazione_rel_adj
        np_ret = []
        # [ "rete_id_1,flag_1", "rete_id_2,flag_2", ... ] dove rete_id_X e' uno dei valori RETE_GSM, RETE_LTE, ...  e flag_Y e' uno dei valori FLAG_CANCELLAZIONE_XXX
        return np_ret if @cancellazione_relazioni_adj.nil? || @cancellazione_relazioni_adj.empty?
        @cancellazione_relazioni_adj.each do |k|
          next if k.to_s.empty?
          rete, flag = k.split(',').map(&:to_i)
          if rete == @vendor_instance.rete
            np_ret |= (@vendor_instance.meta_entita_relazioni_adiacenza_intra || {}).keys if (flag & FLAG_CANCELLAZIONE_INTRA) > 0
            np_ret |= (@vendor_instance.meta_entita_relazioni_adiacenza_inter || {}).keys if (flag & FLAG_CANCELLAZIONE_INTER) > 0
            np_ret |= (@vendor_instance.meta_entita_relazioni_adiacenza[rete] || {}).keys if flag == FLAG_CANCELLAZIONE_ALL
          elsif flag == FLAG_CANCELLAZIONE_ALL
            np_ret |= (@vendor_instance.meta_entita_relazioni_adiacenza[rete] || {}).keys
          end
        end
        np_ret
      end

      def cancella_relazioni_adj(writer:, res:)
        return if @cancellazione_relazioni_adj.nil? || @cancellazione_relazioni_adj.empty?
        logger.info("#{log_prefix}. Inizio elaborazione cancellazione relazioni di adiacenza")
        end_msg = "#{log_prefix}. Terminata elaborazione cancellazione relazioni di adiacenza"
        celle = dataset_master.where(naming_path: @vendor_instance.naming_path_del_rel_adj).select_map(:dist_name)
        np_rel_adj = np_cancellazione_rel_adj
        puts "XXX np_rel_adj: #{np_rel_adj}" if ENV['PUTS_FDC']
        puts "XXX num celle: #{celle.count}" if ENV['PUTS_FDC']
        puts "XXX naming_path_cella: #{@vendor_instance.naming_path_del_rel_adj}" if ENV['PUTS_FDC']
        if np_rel_adj.empty? || celle.empty?
          logger.info("#{end_msg} (Nessuna relazione di adiacenza da cancellare)")
          return
        end

        res[KEY_AUTO_CANC_REL_ADJ][:numero_celle] = celle.count
        res[KEY_AUTO_CANC_REL_ADJ][:rel_adj_da_cancellare] = 0
        res[KEY_AUTO_CANC_REL_ADJ][:rel_adj_scartate] = 0
        begin
          query = @vendor_instance.query_rel_adj(table_name: table_name_rif, naming_path_list: np_rel_adj,
                                                 table_name_master: table_name_master, celle: celle)
          dataset_rif.db.transaction do
            dataset_rif.db[query].select_map([:dist_name, :naming_path]).each do |row|
              dn, np = row
              me = elabora_cancellazione_rel_adj(dist_name: dn, naming_path: np)
              gestisci_entita(entita: me, writer: writer, res: res)
            end
          end
          logger.info(end_msg)
        rescue => e
          res[:eccezione] = "#{e}: #{e.message} - db.transaction in cancella_relazioni_adj"
          logger.error("#{@log_prefix} catturata eccezione (#{res})")
          raise
        end
        res
      end

      def con_parser(file:, **opts)
        importer_class = Funzioni::ImportFormatoUtente.const_get(opts[:formato_file_canc].to_s.camelize)
        importer = importer_class.new(sistema_ambiente_archivio: @saa_master, file: file, **opts)
        importer.con_segnalazioni(funzione: FUNZIONE_PI_IMPORT_FORMATO_UTENTE,
                                  account: @saa_master.account,
                                  filtro: @saa_master.filtro_segnalazioni,
                                  attivita_id: opts[:attivita_id]) do
                                    importer.con_parser(file: file, **opts) do |parser|
                                      yield(parser)
                                    end
                                  end
      end

      def entita_del_crt?(dn)
        @lista_entita_del_crt ||= @lista_entita_canc.sort.dup
        # puts "YYYYYYYYYYYYYYYYY #{dn}: @lista_entita_del_crt = #{@lista_entita_del_crt}"
        return false if @lista_entita_del_crt.nil? || @lista_entita_del_crt.empty?
        return false if dn < @lista_entita_del_crt.first
        return true if @lista_entita_del_crt.include?(dn)
        @lista_entita_del_crt.each.with_index do |dn_canc, idx|
          if dn < dn_canc + DIST_NAME_SEP
            @lista_entita_del_crt = @lista_entita_del_crt[idx..-1]
            return false
          end
          return true if dn.start_with?(dn_canc + DIST_NAME_SEP)
        end
        false
      end

      def check_entita_del_crt(row, res)
        return unless row
        res ||= {}
        dn = row[:dist_name]
        return unless entita_del_crt?(dn)
        np = row[:naming_path]
        vv = row[:version]
        params = row[:parametri]
        res[dn] = parametri_per_create(naming_path: np, parametri: params)
        res[dn]['version'] = vv
        res[dn]['naming_path'] = np
      end

      def old_get_entita_del_crt
        res = {}
        @lista_entita_canc.each do |dist_name_canc|
          dataset_master.select(:dist_name, :naming_path, :version, :parametri).where("dist_name = '#{dist_name_canc}' OR dist_name like '#{dist_name_canc}#{DIST_NAME_SEP}%'").each do |row|
            dn = row[:dist_name]
            np = row[:naming_path]
            vv = row[:version]
            params = row[:parametri]
            res[dn] = parametri_per_create(naming_path: np, parametri: params)
            res[dn]['version'] = vv
            res[dn]['naming_path'] = np
          end
        end
        res
      end

      def get_entita_del_crt(lista_entita: nil)
        # nuovo modo, piu' performante, per ottenere lista entita_del_crt
        res = {}
        if lista_entita
          lista_entita.each do |row|
            check_entita_del_crt(row, res)
          end
        else
          test_cnt = 0
          Db.connection.transaction do
            dataset_master.db["SELECT dist_name, naming_path, version, parametri FROM #{table_name_master} ORDER BY dist_name"].select([:dist_name, :naming_path, :version, :parametri]).each do |row|
              test_cnt += 1
              check_entita_del_crt(row, res)
            end
          end
        end
        res
      end

      def leggi_file_canc(opts)
        return {} if @lista_entita_canc
        res = {}
        lista_dn = []
        (@lista_file_canc || []).each.with_index do |file_canc, idx|
          res[:"parser_#{idx}"] = con_parser(file: file_canc, flag_cancellazione: true, metamodello: metamodello, **opts) do |parser|
            begin
              @saa_master.db.transaction do
                parser.parse do |lista_entita_parser|
                  lista_entita_parser.each do |entita_parser|
                    lista_dn << entita_parser.dist_name
                  end # lista_entita_parser
                end # parser
              end # transaction
            rescue => e
              res[:eccezione] = "#{e}: #{e.message} - nella rescue di begin"
              logger.error("#{@log_prefix} catturata eccezione (#{res})")
              raise
            end
          end # con_parser
        end
        @lista_entita_canc = lista_dn
        if @flag_del_crt
          # preparo la lista anche i figli con i dati per la create
          s_time = Time.now
          @entita_del_crt = {}
          @entita_del_crt = (ENV['NEW_GET_ENTITA_DEL_CRT'] || '0') == '1' ? get_entita_del_crt : old_get_entita_del_crt
          puts "XXX Preparata lista entita del_crt (#{@entita_del_crt.count}) in #{(Time.now - s_time).round(1)} sec." if ENV['PUTS_FDC']
        end
        res
      end

      def gestisci_entita(entita:, writer:, res:)
        if entita.scarto?
          puts "XXX SCARTO IN #{entita.operazione.to_s.upcase}: #{entita.dist_name}" if ENV['PUTS_FDC']
          res[entita.operazione][:entita_scartate] += 1
          res[KEY_AUTO_CANC_REL_ADJ][:rel_adj_scartate] += 1 if entita.auto_canc_rel_adj?
          nuova_segnalazione(entita.tipo_segnalazione, (entita.opts_segnalazione || {}).merge(dn: entita.dist_name, np: entita.naming_path)) if entita.tipo_segnalazione
        else
          puts "XXX #{entita.operazione.to_s.upcase}:           #{entita.dist_name}" if ENV['PUTS_FDC']
          res[entita.operazione][entita.is_relazione_adj ? :entita_da_scrivere_adj : :entita_da_scrivere] += 1
          res[KEY_AUTO_CANC_REL_ADJ][:rel_adj_da_cancellare] += 1 if entita.auto_canc_rel_adj?
          if writer
            entita.version = nil unless @scrivi_version
            writer.scrivi_entita(entita: entita,
                                 operazione: entita.operazione,
                                 flag_adj:  entita.is_relazione_adj
                                )
          end
          @entita_ok[entita.operazione][entita.dist_name] = true
        end
        res
      end

      def con_writer
        mio_writer = nil
        mio_writer = WriterFdc.new(**@writer_opts)
        mio_writer.open
        yield mio_writer
      ensure
        mio_writer.close if mio_writer
      end

      def con_lock(**opts, &block)
        @saa_master.con_lock(mode: LOCK_MODE_READ, use_pi: true, **opts) do |_lock|
          @saa_rif.con_lock(mode: LOCK_MODE_READ, use_pi: @saa_rif.pi.nil? ? false : true, **opts, &block)
        end
      end

      KEY_AUTO_CANC_REL_ADJ = 'auto_canc_rel_adj'.freeze
      def esegui(opts)
        res = { MANAGED_OBJECT_OPERATION_CREATE => { entita_da_scrivere: 0, entita_da_scrivere_adj: 0, entita_scartate: 0 },
                MANAGED_OBJECT_OPERATION_UPDATE => { entita_da_scrivere: 0, entita_da_scrivere_adj: 0, entita_scartate: 0 },
                MANAGED_OBJECT_OPERATION_DELETE => { entita_da_scrivere: 0, entita_da_scrivere_adj: 0, entita_scartate: 0 },
                KEY_AUTO_CANC_REL_ADJ           => {} }
        fs = @saa_master.filtro_segnalazioni.dup
        step_info = opts[:step_info] || 100_000
        %i(archivio progetto_irma_id).each { |k| fs.delete(k) }
        con_lock(account_id: @saa_master.account_id, **opts) do |_locks|
          con_segnalazioni(funzione: funzione, account: @saa_master.account, filtro: fs, attivita_id: opts[:attivita_id]) do
            Irma.gc
            InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
              res[:file_cancellazione] = leggi_file_canc(opts)
              # return res # TEST!!!!!!!!

              con_writer do |writer|
                unless @solo_delete
                  # create
                  if @flag_del_crt && !@entita_del_crt.empty?
                    entita_presenti_assenti_del_crt(writer: writer, res: res, info_progresso: ip)
                  else
                    entita_presenti_assenti(writer: writer, res: res, info_progresso: ip)
                  end
                  # update
                  entita_differenti(writer: writer, res: res, info_progresso: ip)
                end
                unless @lista_entita_canc.empty?
                  entita_da_cancellare(writer: writer, res: res, info_progresso: ip)
                end
                cancella_relazioni_adj(writer: writer, res: res)
              end # con_writer
            end # info_progresso
            res
          end # con_segnalazioni
        end # con_lock
        res
      end
    end
  end
  #
  module Db
    # extend class
    class SistemaAmbienteArchivio
      def esegui_creazione_fdc(opts)
        case opts[:formato_fdc]
        when FORMATO_AUDIT_IDL
          opts.update(funzione: FUNZIONE_CREAZIONE_FDC_OMC_LOGICO)
          Funzioni::CreazioneFdc.new(sistema_ambiente_archivio: self, **opts).esegui(**opts)
        when FORMATO_AUDIT_CNA
          opts.update(funzione: FUNZIONE_CREAZIONE_FDC_CNA_LOGICO)
          Funzioni::CreazioneFdcCna.new(sistema_ambiente_archivio: self, **opts).esegui(**opts)
        end
      end
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      def esegui_creazione_fdc(opts)
        case opts[:formato_fdc]
        when FORMATO_AUDIT_IDL
          opts.update(funzione: FUNZIONE_CREAZIONE_FDC_OMC_FISICO)
          Funzioni::CreazioneFdc.new(sistema_ambiente_archivio: self, **opts).esegui(**opts)
        when FORMATO_AUDIT_CNA
          opts.update(funzione: FUNZIONE_CREAZIONE_FDC_CNA_FISICO)
          Funzioni::CreazioneFdcCna.new(sistema_ambiente_archivio: self, **opts).esegui(**opts)
        end
      end
    end
  end
end
