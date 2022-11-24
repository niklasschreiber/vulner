# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli, C. Pinali
#
# Creation date: 20160524
#
require 'htmlentities'
require 'zlib'
require_relative 'verifiche_import_costruttore'

module Irma
  #
  module Funzioni
    #
    class ImportCostruttore
      #
      class Cna < self
        include VerificheImportCostruttore

        def self.formato_audit
          FORMATO_AUDIT_CNA
        end

        def self.formato_file_compatibile?(file)
          h = %w(.zip .gz).include?(File.extname(file.to_s).downcase) ? `zcat "#{file}" |head -2` : `head -2 "#{file}"`
          raise "Impossibile aprire il file #{file}, verificare che non sia corrotto" if h.to_s.empty?
          ($CHILD_STATUS.exitstatus.zero? && h.split("\n").last.match('---')) ? true : false
        rescue => e
          raise "File #{file} non compatibile con il formato #{formato_audit} (#{e})"
        end

        CNA_COL_SEP = "\001".freeze
        CNA_NULL = 'NULL'.freeze

        #
        class ManagedObject < Db::Entita::Record
          attr_reader :linea_file, :dist_name_valid
          attr_accessor :esito_analisi
          alias dist_name_valid? dist_name_valid
          alias dist_name_orig dist_name

          def initialize(hash = {})
            super(hash)
            @dist_name_valid = false
            @linea_file      = hash[:linea_file]
            @esito_analisi   = hash[:esito_analisi]
            @valore_entita   = hash[:valore_entita]
          end

          def info
            {
              class: 'ManagedObject', linea_file: linea_file, livello: livello, version: version, dist_name: dist_name,
              naming_path: naming_path, meta_entita: meta_entita, valore_entita: valore_entita, parametri: parametri, checksum: checksum, esito_analisi: esito_analisi
            }
          end
        end

        # metodi classe Cna
        attr_reader :stats, :file
        def initialize(sistema_ambiente_archivio:, **opts)
          super(sistema_ambiente_archivio: sistema_ambiente_archivio, **opts)
          @stats = nil
          @file = nil
        end

        def con_parser(file:, **opts)
          @file = file
          @stats = { file: @file, lines: 0, calls: 0, tags: Hash.new(0) } if opts[:stats]
          yield(self)
        end

        def parse(&block)
          last_line_processed = -1
          Irma.processa_file_per_linea(@file, suffix: 'parse_cna') do |line, n|
            line.chomp!
            last_line_processed = n
            @stats[:lines] += 1 if @stats
            next if line.empty?
            linea = line.gsub("\t", CNA_COL_SEP).gsub(' ', CNA_COL_SEP).gsub('""', CNA_NULL)
            LineaCna.new(linea: linea.split(CNA_COL_SEP), linea_file: n + 1, importer: self).analizza(&block)
          end
          @stats
        rescue EsecuzioneScaduta
          raise
        rescue => e
          raise "Linea #{last_line_processed}: #{e}"
        end

        def param_value(v)
          v.index('&') ? @htmlentities.decode(v) : v
        end

        # rubocop:disable Metrics/ClassLength
        class LineaCna
          ENTITA_MANDATORIE = %w(NW MSC BSC SITE CELL).freeze

          attr_reader :import_cache, :linea, :linea_file, :importer, :stats, :metamodello
          def initialize(linea:, linea_file:, importer:)
            @import_cache = importer.import_cache
            @linea = linea
            @linea_file = linea_file
            @importer = importer
            @stats = importer.stats
            @metamodello = importer.metamodello
            @entita_presenti = {}
            @entita_scartate = {}
          end

          def analizza(&block)
            if linea_file < 3
              carica_header if linea_file == 1
            else
              analizza_linea(&block)
              @stats[:calls] += 1 if @stats
            end
          end

          def carica_header # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
            # dato l'header, costruisce il metamodello di riferimento con i puntamenti alle colonne del file, segnalando eventuali entita/parametri mancanti
            raise 'Metamodello mancante' unless metamodello
            entita_mandatorie_presenti = []
            actual_np = ''
            actual_idx = 0
            linea.each_with_index do |obj, index|
              # 1. dato un obj, si verifica se e' un'entita del metamodello, il metodo restitusce il naming_path
              np = metamodello.verifica_entita_per_nome(obj)
              if np
                # 1.1 se e' un'entita, metto in hash con chiave la meta_entita, valori il np e l'indice di split
                actual_np = np
                actual_idx = index
                import_cache[:meta_modello_header][index] = { name: obj, naming_path: actual_np, is_valid: true, extra_name: metamodello.verifica_entita(actual_np).extra_name }
                entita_mandatorie_presenti << obj if ENTITA_MANDATORIE.include?(obj)
              else
                # 2. se non e' entita, si verifica se e' un parametro del metamodello, se e' un parametro, metto in hash con chiave me.mp e valori il np, l'indice di split e la colonna
                # dell'entita di riferimento e is_valid a seconda se c'e' nel metamodello oppure no (il tracciamento va fatto solo se c'e' qualche valorizzazione nei dati)
                import_cache[:meta_modello_header][index] = { name: obj, naming_path: actual_np,
                                                              is_valid: !metamodello.verifica_esistenza_parametro(actual_np, obj).nil?, entita_col_num: actual_idx }
              end
            end
            # al termine del caricamento verifico che ci siano le entita mandatorie, se ne mancano, errore bloccante
            ENTITA_MANDATORIE.each do |k|
              next if entita_mandatorie_presenti.include?(k)
              importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_METAMODELLO_META_ENTITA_OBBL_MANCANTE, meta_entita: k, naming_path: k, linea_file: 1)
              raise "Entita mandatoria #{k} mancante nell\'header del file"
            end
            true
          end

          def analizza_linea(&_block) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            if import_cache[:meta_modello_header].keys.size != linea.size
              # puts " numero campi intestazione: #{@import_cache[:meta_modello_header].keys.size} --- numero campi riga #{linea_file}: #{linea.size}"
              importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_NUMERO_CAMPI,
                                          linea_file: linea_file, campi_header: import_cache[:meta_modello_header].keys.size, campi_linea: linea.size)
              return
            end
            mo = nil
            linea.each_with_index do |item, idx|
              # idx corrisponde alla key nell'header_cache
              # puts "linea_file: #{linea_file} -- item #{item} --- idx #{idx}"
              if import_cache[:meta_modello_header][idx][:entita_col_num].nil? # sono nel caso entita
                # torno la meta entita precedente
                if mo && mo.esito_analisi.nil?
                  # (me_ex = metamodello.verifica_entita(mo.naming_path).extra_name) ? mo.extra_name = me_ex.split(EXTRA_NAME_SEP).map { |mp| mo.parametri[mp] }.join(EXTRA_NAME_SEP) : nil
                  (me_ex = metamodello.verifica_entita(mo.naming_path).extra_name) ? mo.extra_name = Db::MetaEntita.calcola_extra_name(me_extra_name: me_ex, parametri: mo.parametri) : nil
                  yield mo
                  @stats[:tags]['managedObject'] += 1 if @stats
                end
                mo = analizza_entita_cna(item, idx)
                # puts "mo: #{mo.dist_name} --- esito_analisi: #{mo.esito_analisi}"
                if mo && mo.esito_analisi
                  yield mo
                  @stats[:tags]['managedObject'] += 1 if @stats
                  break if mo.esito_analisi == ESITO_ANALISI_ENTITA_SENZA_PADRE
                end
              else # sono nel caso parametri
                next if mo.nil? || mo.esito_analisi
                next if item.eql?(CNA_NULL)
                # puts "in parametri: --- distname: #{mo.dist_name} -- meta_param = #{import_cache[:meta_modello_header][idx][:name]} "
                mo.parametri[import_cache[:meta_modello_header][idx][:name]] = item if verifica_parametro_cna(idx, mo, linea_file)
                @stats[:tags]['p'] += 1 if @stats
              end
            end
            # torno l'ultimo mo
            yield mo if mo && mo.esito_analisi.nil?
            @stats[:tags]['managedObject'] += 1 if @stats && mo && mo.esito_analisi.nil?
            @stats
          end

          def analizza_entita_cna(item, idx) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            meta_entita = import_cache[:meta_modello_header][idx][:name]
            naming_path = import_cache[:meta_modello_header][idx][:naming_path]
            curr_entita = meta_entita + DIST_NAME_VALUE_SEP + item
            mo_opts = { meta_entita: meta_entita, naming_path: naming_path, valore_entita: item, linea_file: linea_file, dist_name: curr_entita }
            if naming_path.index(NAMING_PATH_SEP).nil? # e' root
              @entita_presenti[naming_path] = curr_entita
              return nil if import_cache[:entita_trovate][curr_entita]
              return ManagedObject.new(mo_opts.merge(parametri: {}, dist_name_valid: true, livello: 1))
            end
            # devo risalire al distname padre verificando la meta_entita_padre
            naming_path_padre = naming_path.split(NAMING_PATH_SEP)[0..-2].join(NAMING_PATH_SEP)
            # prendo il dist_name corrispondente al naming_path padre nella hash delle entita trovate
            dist_name_padre = @entita_presenti[naming_path_padre]
            if dist_name_padre
              curr_dist_name = dist_name_padre + DIST_NAME_SEP + curr_entita
              mo_opts[:pid] = import_cache[:entita_trovate][dist_name_padre]
              if import_cache[:entita_trovate][curr_dist_name]
                @entita_presenti[naming_path] = curr_dist_name
                return nil
              end
              if item.eql?(CNA_NULL) # se ho il dist_name_padre e l'entita e' NULL passo alla successiva senza segnalazione
                @entita_scartate[naming_path] = curr_dist_name
                return ManagedObject.new(mo_opts.merge(dist_name: curr_dist_name, esito_analisi: ESITO_ANALISI_ENTITA_DA_IGNORARE))
              else
                @entita_presenti[naming_path] = curr_dist_name
                return ManagedObject.new(mo_opts.merge(dist_name: curr_dist_name, parametri: {}, dist_name_valid: true, livello: naming_path.split(NAMING_PATH_SEP).count))
              end
            elsif item.eql?(CNA_NULL) # se non ho il dist_name_padre e l'entita e' null scarto senza segnalazione
              return ManagedObject.new(mo_opts.merge(esito_analisi: ESITO_ANALISI_ENTITA_DA_IGNORARE))
            else # se non ho il dist_name_padre e l'entita non e' NULL, traccio la segnalazione e interrompo poi la lettura della linea
              importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_PADRE_NULL,
                                          meta_entita: meta_entita, naming_path: naming_path, istanza_entita: curr_entita,
                                          dist_name_padre: @entita_scartate[naming_path_padre], linea_file: linea_file)
              return ManagedObject.new(mo_opts.merge(dist_name: @entita_scartate[naming_path_padre] + DIST_NAME_SEP + curr_entita, esito_analisi: ESITO_ANALISI_ENTITA_SENZA_PADRE))
            end
            nil
          end

          def verifica_parametro_cna(indice_header, mo, linea_file) # rubocop:disable Metrics/AbcSize
            # in caso di meta_parametro mancante (is_valid: false) traccio la segnalazione solo se non ho gia segnalato
            meta_parametro = import_cache[:meta_modello_header][indice_header][:name]
            return true if import_cache[:meta_modello_header][indice_header][:is_valid] || import_cache[:meta_parametro_mancante]["#{mo.naming_path}.#{meta_parametro}"]
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_METAMODELLO_META_PARAMETRO_SEMPLICE_MANCANTE,
                                        meta_entita: mo.meta_entita, naming_path: mo.naming_path,
                                        meta_parametro: meta_parametro, naming_path_con_id: mo.dist_name, linea_file: linea_file)
            import_cache[:meta_parametro_mancante]["#{mo.naming_path}.#{meta_parametro}"] = true
            false
          end
        end # fine classe LineaCna

        def analizza_entita_parser(entita_parser:, **opts)
          return entita_parser.esito_analisi if entita_parser.esito_analisi
          return ESITO_ANALISI_ENTITA_NODO_NON_VALIDO unless verifica_nodo?(entita_parser, **opts)
          ESITO_ANALISI_ENTITA_OK
        end
      end
    end
  end
end
