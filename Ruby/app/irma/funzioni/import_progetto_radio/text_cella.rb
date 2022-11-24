# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli, C. Pinali
#
# Creation date: 20160816
#
require 'htmlentities'
require 'zlib'
require_relative '../../vendors/base'

module Irma
  #
  module Funzioni
    #
    class ImportProgettoRadio
      #
      class TextCella < self
        def parse(&block) # # rubocop:disable Metrics/MethodLength
          last_line_processed = -1
          Irma.processa_file_per_linea(@file, suffix: 'parse_txt') do |line, n|
            line.chomp!
            last_line_processed = n + 1
            @stats[:lines] += 1 if @stats
            next if line.empty?
            LineaCella.new(line: line, linea_file: last_line_processed, importer: self).analizza(&block)
          end
          @stats
        rescue EsecuzioneScaduta
          raise
        rescue => e
          logger.error("#{@log_prefix} catturata eccezione nella processazione della riga #{last_line_processed}: #{e}, backtrace: #{e.backtrace}")
          raise "Linea #{last_line_processed} non corretta: #{e}"
        end
      end

      # rubocop:disable Metrics/ClassLength
      class LineaCella
        include Irma::Vendor
        attr_reader :import_cache, :line, :linea_file, :importer, :stats, :line_arr, :cella

        def initialize(line:, linea_file:, importer:, **opts)
          @import_cache = importer.import_cache
          @line = line
          @linea_file = linea_file
          @importer = importer
          @stats = importer.stats
          @line_arr = opts[:line_arr] || []
          @cella = opts[:cella_obj]
        end

        def analizza(&block)
          # puts "in analizza linea_file = #{linea_file}, line = #{line}"
          return carica_header if linea_file == 1
          res = analizza_linea(&block)
          @stats[:calls] += 1 if @stats
          res
        end

        def carica_header # # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          @line_arr = line.upcase.split(PR_SEP)
          # puts "sono in carica_header con line = #{line}"
          unless controllo_campi_obbligatori
            raise 'Campi obbligatori non presenti nell\'intestazione'
          end
          # andranno poi aggiunti i controlli rispetto al Template di Progetto Radio
          # 1. presenza di posizione_primo e numero_istanze per i campi di adiacenza nel Template...
          imposta_posizioni_adiacenza
          importer.header_arr = @line_arr
          true
        end

        def controllo_campi_obbligatori
          importer.vendor_instance.pr_campi_obbligatori.each do |campo|
            unless @line_arr.include?(campo)
              importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_CAMPI_OBBLIGATORI_HEAD, campo: campo)
              return false
            end
            importer.header_posizioni[campo] = @line_arr.index(campo)
          end
          true
        end

        def imposta_posizioni_adiacenza
          # intanto estraggo le posizioni dei campi adiacenza dall'intestazione anziche' dal Template
          importer.campi_adiacenza.each do |k|
            importer.header_posizioni[k] = []
            tmp_arr = @line_arr.find_all { |el| el.to_s.start_with?(k) }
            tmp_arr.each { |el| importer.header_posizioni[k] << @line_arr.index(el) }
          end
        end

        def analizza_linea(&_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength #, Metrics/CyclomaticComplexity
          @line_arr = line.split(PR_SEP, -1)
          # verifica che il numero dei campi sulla riga corrisponda al numero di campi dell'intestazione
          if importer.header_arr.size != @line_arr.size
            # puts " ***** in analizza_linea, header_arr= #{importer.header_arr}, line_arr = #{@line_arr}, line =#{line}"
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_NUMERO_CAMPI,
                                        linea_file: linea_file, campi_header: importer.header_arr.size, campi_linea: @line_arr.size)
            raise "Numero campi differente tra intestazione e riga: intestazione = #{importer.header_arr.size}, riga = #{@line_arr.size}"
          end
          @cella = if import_cache[:lista_celle_totali].key?(@line_arr[importer.header_posizioni[PR_CELLA]])
                     Db::PrCella.where(nome_cella: @line_arr[importer.header_posizioni[PR_CELLA]]).first
                   else
                     Db::PrCella.new(nome_cella: @line_arr[importer.header_posizioni[PR_CELLA]])
                   end
          %i(verifica_nome_cella verifica_cgi verifica_competenza_omc verifica_cella_release_nodo controlli_adiacenze).each do |method|
            begin
              send(method)
            rescue => e
              # TODO: impostare nei vari metodi l\'esito analisi corrispondente
              # imposto la cella nella cache per eventuali controlli a posteriori, anche se poi scarto la cella (es: flag_cancellazione, reciprocita adiacenze, ecc...)
              @cella.esito_analisi ||= ESITO_ANALISI_ENTITA_RIGA_NON_VALIDA
              import_cache[:lista_celle][@cella.nome_cella] = { esito: @cella.esito_analisi }
              raise e if @cella.esito_analisi == ESITO_ANALISI_ENTITA_NON_COMPETENTE
              yield @cella
              return false
            end
          end
          # TODO: ex controlli vincolanti:
          # Correttezza Valori => serve il Template: il controllo implica: controllo tipo char/int, controllo eventuale regola validazione, controllo parametri obbligatori (non vuoti)
          # Numero Massimo Adiacenze G2G => specifico GSM
          # Numero Massimo Adiacenze G2U e G2G => specifico GSM
          # 3. verifica che i campi su cui e' impostata una regola di validazione nel template la soddisfino
          # return false unless verifica_regole_validazione
          @cella.valori = imposta_valori_db
          @cella.cgi = @line_arr[importer.header_posizioni[PR_CGI]]
          @cella.header = importer.header_arr
          import_cache[:lista_celle][@cella.nome_cella] = adiacenze.merge(ricava_parametri_per_controlli(@cella.valori))
          yield @cella
          @stats[:celle]['cellaObject'] += 1 if @stats
          @stats
        end

        def ricava_parametri_per_controlli(lista_valori) # rubocop:disable Metrics/AbcSize
          ret = {}
          if importer.vendor_instance.pr_campi_per_controlli
            # TODO: verifica esistenza campi in relazione ai controlli richiesti (es: campo PCI e EARFCNUL in caso di Controllo correttezza PCI)
            importer.vendor_instance.pr_campi_per_controlli.each do |campo|
              unless lista_valori[campo] && !lista_valori[campo][0].to_s.empty?
                importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_CAMPI_OBBLIGATORI_NON_VALORIZZATI,
                                            linea_file: linea_file, cella: @cella.nome_cella, campo: campo)
                raise "Campo '#{campo}' non definito nella lista dei valori per la cella #{@cella.nome_cella}"
              end
              ret[campo] = lista_valori[campo][0]
            end
          end
          ret
        end

        def verifica_competenza_omc # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          omc_logico_in = @line_arr[importer.header_posizioni[PR_SISTEMA]]
          omcl_di_competenza = importer.saa.sistema.descr
          unless omcl_di_competenza.eql?(omc_logico_in)
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_COMPETENZA_OMC,
                                        linea_file: linea_file, tipo_omc: 'Logico', omc_file: omc_logico_in, omc_comp: omcl_di_competenza)
            @cella.esito_analisi = ESITO_ANALISI_ENTITA_NON_COMPETENTE
            raise "Sistema non corrispondente: atteso #{omcl_di_competenza}, trovato #{omc_logico_in}"
          end
          # @cella.sistema_id = importer.saa.sistema_id
          # @cella.sistema_id = [importer.saa.sistema_id]
          @cella.sistema_id = Db::Sistema.sistemi_gemelli_ids(importer.saa.sistema_id).first

          omc_fisico_in = @line_arr[importer.header_posizioni[PR_OMC_FISICO]]
          omcf_di_competenza = importer.saa.sistema.omc_fisico_completo.nome
          unless omcf_di_competenza.eql?(omc_fisico_in)
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_COMPETENZA_OMC,
                                        linea_file: linea_file, tipo_omc: 'Fisico', omc_file: omc_fisico_in, omc_comp: omcf_di_competenza)
            @cella.esito_analisi = ESITO_ANALISI_ENTITA_NON_COMPETENTE
            raise "Omc Fisico Completo non corrispondente: atteso #{omcf_di_competenza}, trovato #{omc_fisico_in}"
          end
          @cella.omc_fisico_completo_id = importer.saa.sistema.omc_fisico_completo.id
          true
        end

        def verifica_nome_cella
          nome_c = @line_arr[importer.header_posizioni[PR_CELLA]]
          return true if nome_c.to_s.match(Irma.reg_expr_nome_cella_per_rete(importer.saa.rete_id))
          importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_NOME_CELLA_NON_CONFORME, linea_file: linea_file, cella: nome_c)
          raise "Nome cella #{nome_c} non conforme"
        end

        def get_anagrafica_cgi(nome_cella)
          # importer.db_irma1[:anag_cgi].select(:ci, :lac).where(id_cella: nome_cella).first
          importer.cache_cgi[nome_cella]
        end

        def verifica_cgi # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          return true unless importer.eseguire_verifica_cgi?
          cella_cgi = @line_arr[importer.header_posizioni[PR_CGI]]
          nome_cella = @line_arr[importer.header_posizioni[PR_CELLA]]
          # Cella in anag_cgi ?
          anag_cgi = get_anagrafica_cgi(nome_cella) # anag_cgi = nil or [anag_ci, anag_lac]
          unless anag_cgi
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_CELLA_NON_ANAGRAFATA_CGI,
                                        linea_file: linea_file, cella: nome_cella)
            @cella.esito_analisi = ESITO_ANALISI_ENTITA_NON_COMPETENTE # per far interrompere l'intero import
            raise "Cella #{nome_cella} non anagrafata in anagrafica cgi"
          end
          anag_ci, anag_lac = anag_cgi
          _x, _y, lac, ci = cella_cgi.to_s.split(CGI_SEP)
          if ci && ci == anag_ci
            if lac.to_s != anag_lac
              # si aggiorna l'anagrafica cgi con il LAC contenuto nel file
              lac_new = Db::AnagraficaCgi.lac_ok(lac.to_s)
              if lac_new
                Db::AnagraficaCgi.first(nome_cella: nome_cella, rete_id: importer.saa.rete_id).update(lac: lac_new)
                importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_LAC_AGGIORNATO,
                                            linea_file: linea_file, cella: nome_cella,
                                            cgi_cella: cella_cgi,
                                            lac_anagrafica: anag_lac, lac_cella: lac_new)
              else
                importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_LAC_ERRATO,
                                            linea_file: linea_file, cella: nome_cella, lac: lac.to_s)
                @cella.esito_analisi = ESITO_ANALISI_ENTITA_RIGA_NON_VALIDA # non blocco l'import
              end
            end
            return true
          end
          importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_CGI_NON_CORRISPONDENTE,
                                      linea_file: linea_file, cella: nome_cella, cgi_cella: cella_cgi,
                                      ci_anagrafica: anag_ci.to_s, ci_cella: ci.to_s,
                                      lac_anagrafica: anag_lac.to_s, lac_cella: lac.to_s)
          @cella.esito_analisi = ESITO_ANALISI_ENTITA_NON_COMPETENTE # per far interrompere l'intero import
          raise 'Cella con valori cgi non corrispondenti a quelli anagrafati'
        end

        def verifica_cella_release_nodo # rubocop:disable Metrics/AbcSize
          @cella.release_nodo = @line_arr[importer.header_posizioni[importer.nome_release_nodo]]
          @cella.nome_nodo = @line_arr[importer.header_posizioni[importer.nome_nodo]]
          rel_ammesse = importer.saa.sistema.release_di_nodo.to_a
          if @cella.release_nodo.nil? || @cella.release_nodo.empty?
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_RELEASE_NODO_MANCANTE, linea_file: linea_file, campo_release: importer.nome_release_nodo)
            return true # la mancanca della release di nodo non e' un errore bloccante
          end
          unless rel_ammesse.include?(@cella.release_nodo)
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_RELEASE_NODO_ERRATA, linea_file: linea_file, rel_nodo: @cella.release_nodo, rel_ammesse: rel_ammesse.join(','))
            @cella.esito_analisi = ESITO_ANALISI_ENTITA_NON_COMPETENTE # blocco l'import
            raise "Release di nodo non corretta: ammesse #{rel_ammesse.join(',')}, trovato #{@cella.release_nodo}"
          end
          # verifica ENDOEBID
          verifica_enodeb(@cella.nome_nodo) if importer.vendor_instance.pr_nome_id_nodo && importer.saa.rete_id == RETE_LTE
          true
        end

        def verifica_enodeb(nome_nodo) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          if import_cache[:enodeb_scartati].include? nome_nodo
            @cella.esito_analisi = ESITO_ANALISI_ENTITA_RIGA_NON_VALIDA # non blocco l'import
            return
          end
          # 1 - controllo che l'enodeb_name sia in anagrafica:
          db_enodeb_id = importer.import_cache[:lista_enodeb][nome_nodo]
          unless db_enodeb_id
            import_cache[:enodeb_scartati] << nome_nodo
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_ENODEB_MANCANTE, linea_file: linea_file, enodeb_name: nome_nodo)
            @cella.esito_analisi = ESITO_ANALISI_ENTITA_RIGA_NON_VALIDA # non blocco l'import
            raise "eNodeB #{nome_nodo} non anagrafato: utilizzare la funzionalita\' Completa ENODEBID"
          end
          # 2 - controllo che enodeb_id in anagrafica sia lo stesso della riga in input
          pr_enodeb_id = @line_arr[importer.header_posizioni[importer.vendor_instance.pr_nome_id_nodo]]
          unless db_enodeb_id.to_s == pr_enodeb_id.to_s
            import_cache[:enodeb_scartati] << nome_nodo
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_ENODEB_DIFFERENTE,
                                        linea_file: linea_file, enodeb_name: nome_nodo, db_enodeb_id: db_enodeb_id, pr_enodeb_id: pr_enodeb_id)
            @cella.esito_analisi = ESITO_ANALISI_ENTITA_RIGA_NON_VALIDA # non blocco l'import
            raise "eNodeB #{nome_nodo} anagrafato con id differente: in anagrafica #{db_enodeb_id}, sul file di PR #{pr_enodeb_id}. Utilizzare la funzionalita\' Completa ENODEBID"
          end
          true
        end

        def adiacenze
          @adiacenze ||= begin
                           @adiacenze = {}
                           importer.campi_adiacenza.each do |adj|
                             @adiacenze[adj] = []
                             importer.header_posizioni[adj].each { |idx| @adiacenze[adj] << @line_arr[idx] }
                           end
                           # puts " *** cella: #{@cella.nome_cella} - adiacenze: #{@adiacenze}"
                           @adiacenze
                         end
        end

        def controlli_adiacenze # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          adiacenze.each do |key_adj, arr_adj|
            arr_adj_compact = arr_adj.map { |aa| aa unless aa.empty? }.compact
            # 1. si deve verificare che la cella non sia presente anche come adiacente
            unless cella_in_adiacenze?(arr_adj_compact)
              importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_CELLA_SERVENTE, linea_file: linea_file, cella: @cella.nome_cella, key_adj: key_adj)
              raise "Cella servente #{@cella.nome_cella} inclusa tra le sue adiacenti di tipo #{key_adj}"
            end
            # 2. controllo adiacenze ripetute: data una adiacenza, questa non deve comparire piu' volte nella sua lista
            ret = verifica_adiacenze_ripetute(arr_adj_compact)
            unless ret.empty?
              importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_ADIACENZE_RIPETUTE, linea_file: linea_file, adj: ret, key_adj: key_adj)
              raise "Adiacenze #{ret} ripetute tra le adiacenti di tipo #{key_adj}"
            end
            # 3. tolto controllo adiacenze consecutive: e' un controllo non vincolante
            # popolo la cache delle adiacenti con chiave il nome della cella adiacente e valore la lista delle celle che la hanno come adiacente
            inserisci_cache_adiacenti(arr_adj_compact)
            # 4. Controllo conformita nomi celle adiacenti
            ret4 = verifica_nome_adiacenti(key_adj, arr_adj_compact)
            next if ret4.empty?
            ret_str = ret4.join(', ')
            importer.nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_NOME_ADIACENTE_NON_CONFORME, linea_file: linea_file, cella: ret_str, key_adj: key_adj)
            raise "Adiacenze #{ret_str} di tipo #{key_adj} hanno nome non conforme"
          end
          true
        end

        def cella_in_adiacenze?(arr_adj)
          # si deve verificare che la cella non sia presente anche come adiacente
          arr_adj.include?(@cella.nome_cella) ? false : true
        end

        def rete_if_from_tipo_adj(t_adj_in)
          t_adj = t_adj_in.to_s
          if t_adj.start_with?('ADJ')
            importer.saa.rete_id
          else
            Irma.rete_from_adj_prefix(t_adj)
          end
        end

        def verifica_nome_adiacenti(key_adj, arr_adj)
          res = []
          rete_id = rete_if_from_tipo_adj(key_adj)
          return res unless rete_id && Irma.reg_expr_nome_cella_per_rete(rete_id)
          arr_adj.each do |e|
            res << e unless e.match(Irma.reg_expr_nome_cella_per_rete(rete_id))
          end
          res
        end

        def verifica_adiacenze_ripetute(arr_adj)
          tmp = Hash.new(0)
          arr_adj.each { |e| tmp[e] += 1 }
          tmp.select { |_k, v| v > 1 }.keys.join(',')
        end

        def adiacenze_consecutive?(arr_adj)
          arr_adj.include?('') ? arr_adj.find_index { |v| v.to_s.empty? } > (arr_adj.rindex { |v| !v.to_s.empty? } || -1) : true
        end

        def inserisci_cache_adiacenti(arr_adj)
          arr_adj.each do |adj|
            import_cache[:lista_adiacenti] << adj # e' un Set, non Array
          end
        end

        def imposta_valori_db # rubocop:disable Metrics/AbcSize
          # la colonna valori e' composta da <nome_campo> => [valore, posizione, tipo]
          valori = {}
          importer.header_arr.each_with_index do |campo, idx|
            importer.header_sistema[campo] = { 'tipo' => Irma.ricava_tipo(@line_arr[idx]) } unless importer.header_sistema[campo]
            valori[campo] = [@line_arr[idx], idx, importer.header_sistema[campo]['tipo']]
          end
          valori
        end
      end
    end
  end
end
