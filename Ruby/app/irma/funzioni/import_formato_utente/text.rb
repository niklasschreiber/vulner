# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli, C. Pinali
#
# Creation date: 20160816
#
require 'htmlentities'
require 'zlib'

module Irma
  #
  module Funzioni
    #
    class ImportFormatoUtente
      #
      class Text < self
        #
        class ManagedObject < Db::Entita::Record
          attr_reader :linea_file, :operazione
          attr_accessor :esito_analisi, :parametri_label

          def initialize(hash = {})
            super(hash)
            @linea_file      = hash[:linea_file]
            @esito_analisi   = hash[:esito_analisi]
            @valore_entita   = hash[:valore_entita]
            @operazione      = hash[:operazione]
            @parametri_label = hash[:parametri_label] || {}
          end

          def info
            {
              class: 'ManagedObject', linea_file: linea_file, livello: livello, version: version, dist_name: dist_name,
              naming_path: naming_path, meta_entita: meta_entita, valore_entita: valore_entita, parametri: parametri, checksum: checksum, esito_analisi: esito_analisi
            }
          end

          def elabora_dist_name # rubocop:disable Metrics/AbcSize
            # dato il dist_name si possono ricavare i seguenti attributi di MO:
            # naming_path
            # meta_entita
            # valore_entita
            # livello
            arr_dn = dist_name.split(DIST_NAME_SEP)
            values[:livello] ||= arr_dn.size
            tmp = arr_dn.last.split(DIST_NAME_VALUE_SEP)
            values[:meta_entita] ||= tmp[0]
            values[:valore_entita] ||= tmp[1]
            values[:naming_path] ||= arr_dn.map { |el| el.split(DIST_NAME_VALUE_SEP).fetch(0) }.join(NAMING_PATH_SEP)
          end
        end # fine ManagedObject

        # metodi classe Text
        attr_reader :stats, :file, :to_delete, :only_update
        attr_accessor :livello_entita, :header_arr, :naming_path, :last_id
        def initialize(sistema_ambiente_archivio:, **opts)
          super(sistema_ambiente_archivio: sistema_ambiente_archivio, **opts)
          @stats = nil
          @file = nil
          @livello_entita = 0
          @naming_path = nil
          @header_arr = nil
          @to_delete = opts[:flag_cancellazione] || false
          @only_update = opts[:flag_update] || false
          @last_id = opts[:last_id] || dataset.max(:id) || 0
        end

        def con_parser(file:, **opts)
          @file = file
          @stats = { file: @file, lines: 0, calls: 0, tags: Hash.new(0) } if opts[:stats]
          @solo_header = opts[:solo_header]
          @per_filtro_entita = opts[:per_filtro_entita]
          yield(self)
        end

        def parse(&block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          last_line_processed = -1
          Irma.processa_file_per_linea(@file, suffix: 'parse_txt') do |line, n|
            line.chomp!
            last_line_processed = n + 1
            @stats[:lines] += 1 if @stats
            next if line.empty?
            # passo la riga intera come stringa, lo split lo faccio dentro i metodi di LineaText per gestire bene gli strutturati
            res_analizza = LineaText.new(linea: line, linea_file: last_line_processed, importer: self, per_filtro_entita: @per_filtro_entita).analizza(&block)
            unless res_analizza
              break if @solo_header
              raise "Linea #{last_line_processed} non corretta"
            end
          end
          @stats
        rescue EsecuzioneScaduta
          raise
        rescue => e
          logger.error("#{log_prefix}, errore nella processazione della linea #{last_line_processed}: #{e}, backtrace #{e.backtrace}")
          raise "Linea #{last_line_processed}: #{e}"
        end

        class LineaText # rubocop:disable Metrics/ClassLength
          attr_reader :import_cache, :line, :linea_file, :importer, :stats, :metamodello, :line_arr, :mo_per_database
          def initialize(linea:, linea_file:, importer:, **opts)
            @import_cache = importer.import_cache
            @line = linea
            @linea_file = linea_file
            @importer = importer
            @stats = importer.stats
            @metamodello = importer.metamodello
            @line_arr = opts[:line_arr] || []
            @to_delete = opts[:to_delete] || importer.to_delete
            @only_update = opts[:only_update] || importer.only_update
            @per_filtro_entita = opts[:per_filtro_entita] || false
            @mo_per_database = []
          end

          def analizza(linea_hdr: 1, &block)
            # puts "in analizza linea_file = #{linea_file}, linea = #{line}"
            return carica_header if linea_file == linea_hdr
            res = analizza_linea(&block)
            @stats[:calls] += 1 if @stats
            res
          end

          def carica_header # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            # dato l'header, costruisce il metamodello di riferimento con i puntamenti alle colonne del file, segnalando eventuali parametri mancanti
            raise 'Metamodello mancante' unless metamodello
            actual_np = ''
            last_idx = 0

            importer.with_version = false

            # uniformo i separatori di colonne, compreso il separatore dei parametri strutturati: ogni parametro strutturato diventa una colonna a se stante
            linea = line.gsub(TEXT_STRUCT_SEP, TEXT_HEADER_ROW_SEP).split(TEXT_HEADER_ROW_SEP)
            import_cache[:meta_modello_header] = {}
            # puts "sono in carica_header con linea = #{linea}"
            stop_ricerca_meta_ent = false
            linea.each_with_index do |obj, index|
              # puts " index = #{index}, obj = #{obj}, stop_ricerca_meta_ent = #{stop_ricerca_meta_ent}"
              # 1. dato un obj, si verifica se e' un'entita del metamodello, il metodo restitusce il naming_path
              meta_ent = actual_np.empty? ? metamodello.verifica_entita(obj) : metamodello.verifica_entita(actual_np + NAMING_PATH_SEP + obj)
              meta_ent = nil if importer.solo_header && stop_ricerca_meta_ent
              if meta_ent
                # 1.1 se e' un'entita, metto in hash con chiave l'indice e valori la meta_entita e il np
                actual_np = meta_ent.naming_path
                last_idx = index
                import_cache[:meta_modello_header][index] = { name: obj, naming_path: actual_np, extra_name: meta_ent.extra_name }
              elsif obj && obj.end_with?('_*') # gestione update massivo su entita con naming <nome>_<progressivo>, es: n_cell_1, n_cell_2, n_cell_3
                raise 'gestione update massivo non ancora implementata'
              elsif obj == TEXT_VERSION_ENTITA
                # 2. se non e' entita, si verifica se corrisponde al campo version, se corrisponde, si imposta il campo nella cache e si passa al successivo
                import_cache[:meta_modello_header][index] = { name: obj, naming_path: actual_np, is_version: true }
                importer.with_version = true
                next
              else
                # 2.1 se non corrisponde si verifica se e' un parametro del metamodello, se e' un parametro metto in hash con chiave l'indice e valori il mp, il np, e la colonna
                # dell'entita di riferimento, altrimenti traccio segnalazione di warning
                genere = metamodello.verifica_esistenza_parametro(actual_np, obj)
                if genere.nil? && obj != META_PARAMETRO_ANY
                  if importer.solo_header
                    importer.logger.warn("File con intestazione non corretta. naming_path: '#{actual_np}', parametro: '#{obj}'")
                    stop_ricerca_meta_ent = true
                    # return false
                  else
                    importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_FORMATO_UTENTE_METAMODELLO_OGGETTO_INESISTENTE, param: obj)
                  end
                  next
                end
                import_cache[:meta_modello_header][index] = { name: obj, naming_path: actual_np, entita_col_num: last_idx, genere: genere }
              end
            end
            if last_idx != 0 # caso non root
              # va controllato che tutti i parametri siano riferiti all'ultima entita: gli elementi nella cache in posizione < last_idx devono essere entita
              import_cache[:meta_modello_header].keys[0..last_idx - 1].each do |elem|
                # puts "trovato elemento #{elem} corrispondente a #{import_cache[:meta_modello_header][elem][:name]}"
                unless import_cache[:meta_modello_header][elem][:entita_col_num].nil?
                  importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_FORMATO_UTENTE_DATI_POSIZIONE_HEADER, param: import_cache[:meta_modello_header][elem][:name])
                  raise 'Intestazione con parametri non associati all\'entita' unless importer.solo_header
                end
              end
            end
            importer.livello_entita = last_idx + 1
            return false if importer.solo_header && actual_np.empty?
            importer.naming_path = actual_np
            importer.popola_cache_per_filtro if importer.solo_header
            importer.header_arr = @line.split(TEXT_HEADER_ROW_SEP)
            importer.flag_cell_adj = (importer.livello_entita > 1 ? importer.vendor_instance.imposta_flag_cell_adj(actual_np) : Vendor::NO_FLAG)
            true
          end

          def analizza_linea(&_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            @line_arr = split_linea
            # unless importer.solo_header
            #   if import_cache[:meta_modello_header].keys.size != @line_arr.size
            #    importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_FORMATO_UTENTE_DATI_NUMERO_CAMPI,
            #                                linea_file: linea_file, campi_header: import_cache[:meta_modello_header].keys.size, campi_linea: @line_arr.size)
            #    return false
            #  end
            # end
            # si costruisce il dist_name ciclando sulle prime colonne fino a livello_entita
            dist_name = ''
            np = ''
            importer.livello_entita.to_i.times do |idx|
              next unless import_cache[:meta_modello_header][idx]
              dist_name = dist_name + import_cache[:meta_modello_header][idx][:name] + DIST_NAME_VALUE_SEP + @line_arr[idx] + DIST_NAME_SEP
              np = np + import_cache[:meta_modello_header][idx][:name] + NAMING_PATH_SEP
              next if @line_arr[idx] != TEXT_NO_MOD
              next if importer.solo_header
              importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_FORMATO_UTENTE_DATI_IDENTIFICATIVO_ENTITA_NON_VALIDO,
                                          meta_entita: import_cache[:meta_modello_header][idx][:name], naming_path_con_id: dist_name.gsub(TEXT_NO_MOD, ''))
              return false
            end
            dist_name = dist_name.chomp(DIST_NAME_SEP)
            np = np.chomp(NAMING_PATH_SEP)
            # puts "linea #{linea_file} dist_name: #{dist_name}"
            if importer.solo_header
              importer.naming_path = np
              importer.popola_cache_per_filtro(dist_name)
              return true
            else
              @mo_per_database << ManagedObject.new(dist_name: dist_name, naming_path: importer.naming_path, operazione: TEXT_DELETE) if @to_delete
              analizza_entita_text(dist_name) unless @to_delete
              yield @mo_per_database
              @stats[:tags]['managedObject'] += @mo_per_database.size if @stats
            end
            @stats
          end

          def split_linea(l = nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            l ||= @line
            return l.split(TEXT_DATA_ROW_SEP, -1) if importer.livello_entita <= 1

            # in caso di header s.a&s.b&s.c e valore ASSENTE o TEXT_NO_MOD va inserita la chiave per ogni parametro in modo da avere ASSENTE&ASSENTE&
            # 1. sostituisco i separatori consecutivi inserendo la chiave TEXT_NO_MOD, compreso il caso del separatore come ultimo carattere della riga
            ll = l.gsub(TEXT_DATA_ROW_SEP + TEXT_DATA_ROW_SEP, sep = TEXT_DATA_ROW_SEP + TEXT_NO_MOD + TEXT_DATA_ROW_SEP).gsub(TEXT_DATA_ROW_SEP + TEXT_DATA_ROW_SEP, sep)
            ll += TEXT_NO_MOD if ll.end_with?(TEXT_DATA_ROW_SEP)
            # 2. scorro i parametri dell'intestazione verifico se ci sono strutturati, se si, allineo anche i valori della riga
            # puts "in struttura parametri importer.header_arr = #{importer.header_arr}"
            ll_arr = ll.split(TEXT_DATA_ROW_SEP)
            res = ll_arr[0..(importer.livello_entita - 1)]
            indice = importer.livello_entita - 1
            importer.header_arr[importer.livello_entita..-1].each do |vv|
              indice += 1
              # puts "head: #{vv}, line: #{ll_arr[indice]}, index: #{indice}"
              if vv.index(TEXT_STRUCT_SEP) && ll_arr[indice]
                num_struct_values = vv.split(TEXT_STRUCT_SEP).size
                struct_values = if ll_arr[indice].index(TEXT_STRUCT_SEP)
                                  ll_arr[indice].split(TEXT_STRUCT_SEP)
                                elsif [TEXT_PARAMETRO_ASSENTE, TEXT_NO_MOD, TEXT_PARAMETRO_ASSENTE_IN_PI].include?(ll_arr[indice])
                                  Array.new(num_struct_values, ll_arr[indice])
                                else
                                  []
                                end
                raise 'Errore di sintassi nei parametri strutturati' if num_struct_values != struct_values.size
                res += struct_values
              else
                res << ll_arr[indice]
              end
            end
            res
          end

          def analizza_entita_text(dist_name) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            # il metodo controlla e crea i ManagedObject cono l'operazione opportuna
            mo_opts = { dist_name: dist_name, meta_entita: import_cache[:meta_modello_header][importer.livello_entita - 1][:name], naming_path: importer.naming_path,
                        valore_entita: @line_arr[importer.livello_entita - 1], livello: importer.livello_entita }
            me_extra = import_cache[:meta_modello_header][importer.livello_entita - 1][:extra_name]
            me_version = importer.with_version? ? ricava_version_da_fu(@line_arr[importer.livello_entita]) : nil
            db_ent = @importer.dataset.select(:parametri, :version).first(dist_name: dist_name)
            unless db_ent.nil? # caso update, verifico se c'e' qualcosa da aggiornare
              parametri_fu = estrai_parametri_da_fu
              parametri_db = db_ent[:parametri] || {}
              parametri_mo = parametri_merge(parametri_db, parametri_fu)
              if @importer.saa.archivio == ARCHIVIO_ECCEZIONI
                # puts " in analizza_entita_text: parametri_db #{parametri_db}, parametri_mo: #{parametri_mo}, parametri_fu: #{parametri_fu}"
                # TODO: spostare questa parte in un metodino ad hoc e inserire i test"
                mo_opts[:parametri_label] = { parametri_tot: parametri_mo.keys.map { |pp| pp.include?(TEXT_STRUCT_NAME_SEP) ? pp.split(TEXT_STRUCT_NAME_SEP).first + TEXT_STRUCT_NAME_SEP : pp }.uniq,
                                              parametri_rimossi:  parametri_fu.select { |_k, v| v.eql?(TEXT_KEY_ASSENTE) }.keys }
                mo_opts[:parametri_label][:parametri_fu] = parametri_fu.delete_if { |_k, v| v.eql?(TEXT_KEY_ASSENTE) }.keys.map do |pp|
                  pp.include?(TEXT_STRUCT_NAME_SEP) ? pp.split(TEXT_STRUCT_NAME_SEP).first + TEXT_STRUCT_NAME_SEP : pp
                end.uniq
              end
              unless parametri_mo == db_ent[:parametri] # se i parametri non cambiano, non faccio nulla
                mo_opts[:parametri] = parametri_mo
                mo_opts[:operazione] = TEXT_UPDATE
                mo_opts[:version] = me_version.nil? ? db_ent[:version] : me_version
                mo = ManagedObject.new(mo_opts)
                # mo.extra_name = me_extra.split(EXTRA_NAME_SEP).map { |mp| mo.parametri[mp] }.join(EXTRA_NAME_SEP) if me_extra
                mo.extra_name = Db::MetaEntita.calcola_extra_name(me_extra_name: me_extra, parametri:  mo.parametri)
                @mo_per_database << mo
                return
              end
              unless me_version == db_ent[:version]
                mo_opts[:operazione] = TEXT_UPDATE_VER
                mo_opts[:version] = me_version
                mo = ManagedObject.new(mo_opts)
                @mo_per_database << mo
                return
              end
              # se sto importando sull'archivio delle eccezioni, aggiorno la label
              if @importer.saa.archivio == ARCHIVIO_ECCEZIONI
                mo_opts[:operazione] = TEXT_UPDATE_LABEL
                mo = ManagedObject.new(mo_opts)
                @mo_per_database << mo
                return
              end
              return
            end
            return (@mo_per_database << ManagedObject.new(mo_opts.update(esito_analisi: ESITO_ANALISI_ENTITA_DA_IGNORARE))) if @only_update == true
            # se sono in insert devo verificare se esiste il padre, altrimenti devo creare anche quello.
            mo_opts[:pid] = verifica_e_inserisci_padri(dist_name)
            mo_opts[:id] = @importer.last_id += 1
            mo_opts[:nodo] = @importer.saa.sistema.nodo_naming_path.include?(@importer.naming_path)
            mo_opts[:parametri] = estrai_parametri_da_fu.delete_if { |_k, v| v.eql?(TEXT_KEY_ASSENTE) }
            # mo_opts[:extra_name] = me_extra.split(EXTRA_NAME_SEP).map { |mp| mo_opts[:parametri][mp] }.join(EXTRA_NAME_SEP) if me_extra
            mo_opts[:extra_name] = Db::MetaEntita.calcola_extra_name(me_extra_name: me_extra, parametri: mo_opts[:parametri])
            mo_opts[:version] = me_version unless me_version.nil?
            mo_opts[:operazione] = TEXT_INSERT
            if @importer.saa.archivio == ARCHIVIO_ECCEZIONI
              mo_opts[:parametri_label] = {
                parametri_tot: mo_opts[:parametri].keys.map { |pp| pp.include?(TEXT_STRUCT_NAME_SEP) ? pp.split(TEXT_STRUCT_NAME_SEP).first + TEXT_STRUCT_NAME_SEP : pp }.uniq }
            end
            # puts mo_opts
            @mo_per_database << ManagedObject.new(mo_opts)
          end

          def ricava_version_da_fu(fu_version)
            me_version = fu_version.eql?(TEXT_NO_VAL) ? '' : fu_version
            me_version = nil if fu_version.eql?(TEXT_NO_MOD)
            me_version
          end

          def parametri_merge(parametri_1, parametri_2)
            # se parametri_2 e' non vuoto, aggiorna la hash parametri_1 con le variazioni contenuti in parametri_2
            parametri_2 ||= {}
            parametri_1 ||= {}
            return parametri_1 if parametri_1 == parametri_2
            parametri_1.merge(parametri_2).delete_if { |_k, v| v.eql?(TEXT_KEY_ASSENTE) }
          end

          def verifica_e_inserisci_padri(dist_name) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            # dato il dist_name costruisco tutti i padri possibili e li metto in un array ordinato a paritire dal padre, padre del padre...
            p_arr = dist_name.split(DIST_NAME_SEP)
            cnt = p_arr.size - 1
            padri = []
            id_padre = nil
            cnt.times { |i| padri << p_arr[0, i + 1].join(DIST_NAME_SEP) }
            return id_padre if padri.empty? # caso root
            padri.reverse!
            obj_to_create = []
            # a partire del padre diretto verifico se esiste sulla tabella o in cache, se si: torno l'id, se no, continuo la ricerca sul padre del padre
            padri.each do |dnp|
              db_padre = @importer.import_cache[:lista_entita][dnp].nil? ? @importer.dataset.select(:id).first(dist_name: dnp) : { id:  @importer.import_cache[:lista_entita][dnp] }
              unless db_padre.nil?
                id_padre = db_padre[:id]
                @importer.import_cache[:lista_entita][dnp] = id_padre
                break
              end
              obj_to_create.unshift(dnp)
            end
            return id_padre if obj_to_create.empty?
            obj_to_create.each do |dn|
              mo = ManagedObject.new(dist_name: dn, pid: id_padre, id: @importer.last_id += 1, parametri: {}, operazione: TEXT_INSERT)
              @stats[:tags]['managedObject'] += 1 if @stats
              mo.elabora_dist_name
              mo.nodo = @importer.saa.sistema.nodo_naming_path.include?(mo.naming_path)
              @importer.import_cache[:lista_entita][dn] = mo.id
              @mo_per_database << mo
              id_padre = mo.id
            end
            id_padre
          end

          # PARAMETRI
          # posso avere i seguenti casi:
          #  parametro semplice
          #   "aaa"        --> "param_s"=>"aaa"
          #   NO_VAL       --> "param_s"=> ""
          #   ASSENTE      --> "param_s" da cancellare se esistente sul db
          #  parametro multivalore
          #   "bbb|ccc"      --> "param_mv"=>["bbb","ccc"]
          #   NO_VAL         --> "param_mv" => []
          #   1|2|NO_VAL|3   --> "param_mv" => ["1","2","","3"] oppure  ["1","2",nil,"3"]
          #   ASSENTE        --> "param_mv da cancellare se esistente sul db
          #  parametro strutturato semplice
          #   aaa&bbb      --> "struct1.p1"=> ["aaa"], "struct1.p2"=> ["bbb"]
          #   aaa&NO_VAL   --> "struct1.p1"=> ["aaa"], "struct1.p2" => []
          #   aaa&ASSENTE  --> "struct1.p1"=> ["aaa"], "struct1.p2" da cancellare se esistente sul db
          #   ASSENTE      --> tutti i parametri di struct1 da cancellare se esistenti sul db
          #  parametro strutturato multivalore
          #   "aa|bb&cc|dd"     --> "struct2.p1"=>[["aa","bb"]], "struct2.p2" => [["cc","dd"]]
          #   NO_VAL&NO_VAL     --> "struct2.p1" => [[]] o nil, "strcut2.p2" => [[]] o nil
          #   "aa|NO_VAL&&cc|dd --> "struct2.p1" => [["aa",nil]], "strcut2.p2" => [["cc","dd"]]
          #   ASSENTE           --> struct2 da cancellare se esistente sul db
          #   "aa|bb&ASSENTE"   --> "struct2.p1"=>[["aa","bb"]], "struct2.p2" da cancellare se esistente sul db
          #  parametro multi strutturato semplice (il separatore di multi struttura e' |
          #   "aa|bb&cc|dd"                --> "struct2.p1"=>["aa","bb"], "struct2.p2" => ["cc","dd"]
          #   NO_VAL|NO_VAL&NO_VAL|NO_VAL  --> "struct2.p1" => [], "strcut2.p2" => []
          #   "aa|NO_VAL&&cc|dd            --> "struct2.p1" => ["aa",''], "strcut2.p2" => ["cc","dd"]
          #   ASSENTE                      --> tutti i parametri di struct2 da cancellare se esistente sul db
          #   "aa|bb&ASSENTE"              --> "struct2.p1"=>["aa","bb"], "struct2.p2" da cancellare se esistente sul db
          #   "aa|ASSENTE&ASSENTE"         --> "struct2.p1"=>["aa"], "struct2.p2" da cancellare se esistente sul db
          #  parametro multi strutturato multivalore (il separatore di multi struttura e' !  e | quello di multivalore
          #   "aa|ab!bb|bc&cc|cd!dd|de"   --> "struct2.p1"=>[["aa","ab"],["bb","bc]], "struct2.p2" => [["cc","cd"],["dd",de]]
          #   NO_VAL!NO_VAL&NO_VAL!NO_VAL --> "struct2.p1" => [[],[]], "struct2.p2" => [[],[]]
          #   "aa|ab!NO_VAL&&cc|dd        --> "struct2.p1" => [["aa","ab"],[]], "strcut2.p2" => [["cc"],["dd"]]
          #   ASSENTE                     --> tutti i parametri di struct2 da cancellare se esistente sul db
          #   "ASSENTE&cc|cd!dd|de"       --> "struct2.p1" da cancellare se esistente sul db, "struct2.p2=>[["cc", "cd"],["dd", "de"]], "struct2.p2" da cancellare se esistente sul db

          def estrai_parametri_da_fu # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            # trasformo i parametri del FU nella hash  - i valori ASSENTE li copio cosi come sono
            # Attenzione: ASSENTE senza apici corrisponde alla costante TEXT_PARAMETRO_ASSENTE, il valore con apici corrisponde ad avvalorare per il parametro con la stringa assente
            parametri_fu = {}
            # puts "linea.size = #{@line_arr.size} - livello_entita: #{importer.livello_entita}"
            # puts "linea = #{@line} -linea_file: #{@linea_file}"
            # se c'e' la colonna version, il giro sui parametri deve partire da idx + 1 e fare un giro in meno
            count_version = importer.with_version? ? 1 : 0
            (@line_arr.size - importer.livello_entita - count_version).times do |idx|
              indice_param = importer.livello_entita + idx + count_version
              next unless import_cache[:meta_modello_header][indice_param] # in caso di metaparametro non esistente nel metamodello
              valore_param = @line_arr[indice_param]
              next if valore_param.eql?(TEXT_NO_MOD)
              next if valore_param.eql?(TEXT_PARAMETRO_IGNORATO) # per import da export eccezioni per parametri di label da nascondere
              # in caso di import fu su archivio non di eccezioni, la chiave TEXT_PARAMETRO_ASSENTE_IN_PI corrisponde a TEXT_PARAMETRO_ASSENTE
              valore_param = TEXT_PARAMETRO_ASSENTE if valore_param.eql?(TEXT_PARAMETRO_ASSENTE_IN_PI) && @importer.saa.archivio != ARCHIVIO_ECCEZIONI
              meta_param = import_cache[:meta_modello_header][indice_param][:name]
              # ---> TODO da inserire la verifica del tipo valore del parametro int, char, float rispetto al metamodello
              # puts " meta_param #{meta_param} - valore_param #{valore_param} - indice_param = #{indice_param} - genere: #{import_cache[:meta_modello_header][indice_param][:genere]}"
              case import_cache[:meta_modello_header][indice_param][:genere]
              when META_PARAMETRO_GENERE_SEMPLICE
                parametri_fu[meta_param] = valore_param unless valore_param.eql?(TEXT_NO_VAL) || valore_param.eql?(TEXT_PARAMETRO_ASSENTE)
                parametri_fu[meta_param] = '' if valore_param.eql?(TEXT_NO_VAL)
                parametri_fu[meta_param] = TEXT_KEY_ASSENTE if valore_param.eql?(TEXT_PARAMETRO_ASSENTE)
                @stats[:tags]['p'] += 1 if @stats
              when META_PARAMETRO_GENERE_MULTIVALORE
                parametri_fu[meta_param] = valore_param.split(TEXT_ARRAY_ELEM_SEP).map { |pp| pp.eql?(TEXT_NO_VAL) ? '' : pp }
                parametri_fu[meta_param] = TEXT_KEY_ASSENTE if valore_param.eql?(TEXT_PARAMETRO_ASSENTE)
                @stats[:tags]['list'] += 1 if @stats
              when META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE
                parametri_fu[meta_param] = [valore_param.eql?(TEXT_NO_VAL) ? '' : @line_arr[indice_param]]
                parametri_fu[meta_param] = TEXT_KEY_ASSENTE if valore_param.eql?(TEXT_PARAMETRO_ASSENTE)
                @stats[:tags]['p'] += 1 if @stats
              when META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE
                parametri_fu[meta_param] = [valore_param.split(TEXT_ARRAY_ELEM_SEP).map { |pp| pp.eql?(TEXT_NO_VAL) ? '' : pp }]
                parametri_fu[meta_param] = TEXT_KEY_ASSENTE if valore_param.eql?(TEXT_PARAMETRO_ASSENTE)
                @stats[:tags]['list'] += 1 if @stats
              when META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE
                # "aa|bb"                --> "struct.p"=>["aa","bb"]
                # "aa|ASSENTE"           --> "struct.p"=>["aa"]
                tmp_val = valore_param.split(TEXT_ARRAY_ELEM_SEP).map { |pp| pp.eql?(TEXT_NO_VAL) ? '' : pp }
                tmp_val.delete(TEXT_PARAMETRO_ASSENTE)
                parametri_fu[meta_param] = tmp_val
                parametri_fu[meta_param] = TEXT_KEY_ASSENTE if valore_param.eql?(TEXT_PARAMETRO_ASSENTE)
                @stats[:tags]['p'] += 1 if @stats
              when META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE
                # "aa|ab!bb|bc"   --> "struct.p"=>[["aa","ab"],["bb","bc]]
                parametri_fu[meta_param] = valore_param.split(TEXT_SUB_ARRAY_ELEM_SEP).map do |pmv|
                  pmv.split(TEXT_ARRAY_ELEM_SEP).map { |pp| pp.eql?(TEXT_NO_VAL) ? '' : pp }
                end
                parametri_fu[meta_param] = TEXT_KEY_ASSENTE if valore_param.eql?(TEXT_PARAMETRO_ASSENTE)
                @stats[:tags]['list'] += 1 if @stats
              when nil
                raise 'Errore nella lettura dei parametri da fu'
              end
            end
            parametri_fu.each do |p, val|
              # puts "#{p} ==> #{val}"
            end
            parametri_fu
          end

          # metodo copiato da idl.rb... dove mettere a fattor comune? metamodello?
          def ricava_genere_da_valori(meta_param, valori)
            return (valori.is_a?(Array) ? META_PARAMETRO_GENERE_MULTIVALORE : META_PARAMETRO_GENERE_SEMPLICE) unless meta_param.index('.')
            return (valori[0].is_a?(Array) ? META_PARAMETRO_GENERE_STRUTTURATO_MULTIVALORE : META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE) if valori.count == 1
            valori[0].is_a?(Array) ? META_PARAMETRO_GENERE_MULTI_STRUTTURATO_MULTIVALORE : META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE
          end
        end # fine classe LineaText

        def analizza_entita_parser(entita_parser:, **opts)
          return entita_parser.esito_analisi if entita_parser.esito_analisi
          return ESITO_ANALISI_ENTITA_NODO_NON_VALIDO unless verifica_nodo?(entita_parser, **opts)
          verifica_entita_version(entita: entita_parser, **opts) if with_version?
          ESITO_ANALISI_ENTITA_OK
        end
      end
    end
  end
end
