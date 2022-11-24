# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20161114
#
require 'irma/cache'
require_relative 'segnalazioni_per_funzione'
require 'set'

module Irma
  #
  module Funzioni
    # rubocop:disable Metrics/ClassLength
    class ImportProgettoRadio
      include SegnalazioniPerFunzione
      include ModConfigEnable

      config.define CONTROLLO_CGI = :controllo_cgi, 1, descr: 'Flag per far eseguire o meno verifica_cgi', widget_info: 'Gui.widget.booleanInteger()'

      PR_SEP = "\t".freeze

      attr_reader :logger, :sistema_ambiente_archivio, :log_prefix, :vendor_instance, :stats
      attr_accessor :header_arr, :header_posizioni, :header_sistema
      alias saa sistema_ambiente_archivio

      OPERAZIONE = [
        TEXT_INSERT = 1,
        TEXT_UPDATE = 2,
        TEXT_DELETE = 3
      ].freeze

      def initialize(sistema_ambiente_archivio:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @sistema_ambiente_archivio = sistema_ambiente_archivio
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Import Progetto Radio (#{sistema_ambiente_archivio.full_descr})"
        @vendor_instance = saa.vendor_instance(opts)
        @delete_no_prog = opts[:delete_no_prog] || false
        @controlli_non_vincolanti = (opts[:controlli_non_vincolanti] || {}).delete_if { |_k, v| (v || []).empty? }
        @stats = nil
        @header_arr = nil
        @header_posizioni = {}
        @header_sistema = ricava_header_sistema
        @cache_cgi = nil
      end

      def ricava_header_sistema
        head_sis = saa.sistema.header_pr || {}
        head_vr = saa.vendor_release.header_pr || {}
        head_sis.merge(head_vr)
      end

      def nome_nodo
        @nome_nodo ||= @vendor_instance.pr_nome_nodo
      end

      def nome_release_nodo
        @nome_release_nodo ||= @vendor_instance.pr_nome_release_nodo
      end

      def campi_adiacenza
        @campi_adiacenza ||= @vendor_instance.pr_campi_adiacenza
      end

      def map_rete_tipo_adj(reti_id)
        (reti_id || []).map { |rete| MAP_CAMPO_ADJ[saa.rete_id][rete] }
      end

      def formato_audit
        self.class.formato_audit
      end

      def import_cache(_hash = {})
        @import_cache ||= {
          lista_celle_totali: {}, # lista di tutte le celle del sistema presenti sul database: chiave nome cella, valore cgi
          lista_celle: {}, # lista delle celle presenti nel file: chiave nome cella, valori hash delle adiacenti e campi legati ai controlli
          info_adiacenti: Cache.instance(key: pr_cache_prefix + 'info_adiacenti', type: :map_db), # chiave nome adiacente, valori i campi di PR dell'adiacente
          lista_adiacenti: Set.new,
          lista_nodi: {},
          lista_enodeb: {},
          enodeb_scartati: []
        }
      end

      def pr_cache_prefix
        # TODO: gestione import per OMC Fisico
        @pr_cache_prefix ||= "progetto_radio_#{saa.sistema_id}"
      end

      def reset_import_cache
        return nil unless @import_cache
        @import_cache[:info_adiacenti].remove
        @import_cache = nil
      end

      def con_import_cache(opts, &_block)
        import_cache(opts)
        res = yield(import_cache)
        res
      ensure
        reset_import_cache
      end

      def con_parser(file:, **opts)
        @file = file
        @stats = { file: @file, lines: 0, calls: 0, celle: Hash.new(0) } if opts[:stats]
        yield(self)
      end

      def analizza_cella_parser(cella_parser:, **_opts)
        return cella_parser.esito_analisi if cella_parser.esito_analisi
        ESITO_ANALISI_ENTITA_OK
      end

      def carica_celle_da_prn
        # TODO: gestione import per OMC Fisico
        # Db::ProgettoRadio.select(:nome_cella, :cgi).where(sistema_id: saa.sistema_id).each { |row| import_cache[:lista_celle_totali][row[:nome_cella]] = row[:cgi] }
        Db::ProgettoRadio.where_sistema_id(saa.sistema_id).select(:nome_cella, :cgi).each { |row| import_cache[:lista_celle_totali][row[:nome_cella]] = row[:cgi] }
      end

      def carica_anagrafica_enodeb
        # carico l'elenco degli enodeb anagrafati per l'area territoriale del sistema per i controlli di ENODEB
        Irma::Db::AnagraficaEnodeb.select(:enodeb_name, :enodeb_id).where(area_territoriale: Irma::AnagraficaTerritoriale.at_di_as(saa.sistema.area_sistema)).each do |row|
          import_cache[:lista_enodeb][row[:enodeb_name]] = row[:enodeb_id]
        end
      end

      def aggiorna_database(cella_obj, res)
        res[cella_obj.id ? :upd : :ins] += 1
        cella_obj.save
      end

      # -------------------------------------------------------------------------
      def carica_info_adiacenti
        import_cache[:lista_adiacenti].sort.each do |adj|
          ttt = map_tipo_adj(adj)
          next if ttt.nil?
          db_cell = Db::ProgettoRadio.first(nome_cella: adj)
          import_cache[:info_adiacenti][adj] = { tipo_adj: ttt,
                                                 valori: db_cell.nil? ? nil : db_cell[:valori] }
        end
      end

      def map_tipo_adj(adj)
        r_id = Irma.rete_da_nome_cella(adj)
        MAP_CAMPO_ADJ[saa.rete_id][r_id] if r_id
      end

      def esegui_controllo_non_vinc(controllo, tipi_adj, **opts)
        send(controllo, tipi_adj, **opts) if respond_to?(controllo)
      end

      def ctrl_nv_adj_inesistenti(tipi_adj, **opts)
        import_cache[:info_adiacenti].each do |adj, hash_valori|
          next unless tipi_adj.include?(hash_valori[:tipo_adj])
          next if hash_valori[:valori]
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_ADIACENZE_MANCANTI,
                             nome_adiacente: adj, lista_celle: ricava_celle_target_da_adiacente(adj, nil).join(','), **opts)
        end
      end

      def ctrl_nv_reciprocita_adj(tipi_adj, **opts) # rubocop:disable Metrics/AbcSize
        return if tipi_adj.empty?
        campi_adiacenza_filtrati = campi_adiacenza.select { |x| x.start_with?(*tipi_adj) }
        import_cache[:info_adiacenti].each do |adj, hash_valori|
          next unless hash_valori[:valori] # cella inesistente
          next unless tipi_adj.include?(hash_valori[:tipo_adj])
          valori = hash_valori[:valori].map { |_k, v| v[0] }
          campi_adiacenza_filtrati.each do |tipo_adj|
            tmp_arr = ricava_celle_target_da_adiacente(adj, tipo_adj)
            diff = tmp_arr - valori
            # puts " *** segnalazione per tipo_adiacente: #{tipo_adj}, nome_adiacente: #{adj}, lista_celle: #{diff.join(',')}" unless diff.empty?
            unless diff.empty?
              nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_RECIPROCITA_ADIACENZE,
                                 tipo_adiacente: tipo_adj, nome_adiacente: adj, lista_celle: diff.join(','), **opts)
            end
          end
        end
      end
      # -------------------------------------------------------------------------

      def controlla_correttezza_pci # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # il controllo si compone di due verifiche:
        # 1- si verifica se la cella LTE di partenza ha un valore PCI (campo di progetto radio) uguale a quello di qualche sua adiacente LTE (ADJ_<n>), a parita' di LAYER (campo EARFCNUL)
        # 2- si verifica se tra le adiacenti LTE della cella LTE di partenza ce ne sono alcune con lo stesso valore di PCI, a parita' id LAYER
        pci_arr = %w(PCI EARFCNUL)
        # prelevo l'intestazione delle celle L2L (ADJ per Nokia e Ericsson, ADJI e ADJS per Huawei): tolgo GADJ e UADJ
        intestazione_adj = campi_adiacenza - %w(GADJ UADJ)
        # recupero i campi in pci_arr dalla lista delle celle adiacenti
        import_cache[:lista_celle].each do |cell, campi|
          # recupero PCI cell
          pci_cell = campi[pci_arr[0]]
          layer_cell = campi[pci_arr[1]]
          if pci_cell.empty? || layer_cell.empty?
            nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_PCI_MANCANTE, linea_file: linea_file, cella: cell)
            next
          end
          # fase 1. verifico se la cella ha un valore PCI e un valore LAYER uguale a quello di qualche sua adiacenza
          lista_pci_adj = {}
          intestazione_adj.each do |tipo_adj|
            campi[tipo_adj].each do |adj|
              pci_adj = lista_pci_adj[adj] ? lista_pci_adj[adj][0] : import_cache[:info_adiacenti][adj][:valori][pci_arr[0]]
              layer_adj = lista_pci_adj[adj] ? lista_pci_adj[adj][1] : import_cache[:info_adiacenti][adj][:valori][pci_arr[1]]
              lista_pci_adj[adj] = [pci_adj, layer_adj] unless lista_pci_adj[adj]
              next if pci_adj.empty? || layer_adj.empty?
              if pci_cell == pci_adj && layer_cell == layer_adj
                nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_PCI_1,
                                   linea_file: linea_file, cella: cell, adiacente: adj, pci: pci_cell, layer: layer_cell)
              end
            end
          end
          # fase 2. verifico se tra le adiacenze della cella ce ne sono alcune con lo stesso valore di PCI e LAYER
          # faccio il reverse della lista_pci_adj
          rev = Hash.new { |h, k| h[k] = [] }
          lista_pci_adj.each { |k, v| rev[v] << k }
          rev.each do |pair, lista_adj|
            next if lista_adj.empty?
            nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_PCI_2,
                               linea_file: linea_file, cella: cell, lista_adiacenti: lista_adj.join(','), pci: pair[0], layer: pair[1])
          end
        end
      end

      def ricava_celle_target_da_adiacente(adj, tipo_adj)
        return calcola_celle_target_da_adiacenze[[adj, tipo_adj]] || [] if tipo_adj
        calcola_celle_target_da_adiacenze[calcola_celle_target_da_adiacenze.keys.detect { |arr| arr[0] == adj }] || []
      end

      def calcola_celle_target_da_adiacenze(force = false)
        @celle_target_da_adiacenze = nil if force
        @celle_target_da_adiacenze ||= begin
                                         res = {} # TODO: inserire tempo inizio e elapsed e stampare in fondo totale adj e elapsed
                                         # puts "calcolo target da adiacenze : startTime = #{start_time}"
                                         import_cache[:lista_celle].each do |cell, hash_adj|
                                           campi_adiacenza.each do |tipo_adj|
                                             next if hash_adj[tipo_adj].nil?
                                             hash_adj[tipo_adj].each do |adj|
                                               res[[adj, tipo_adj]] ||= []
                                               res[[adj, tipo_adj]] << cell
                                             end
                                           end
                                         end
                                         # puts "totale hash = #{res.size} - elapsed = #{Time.now - start_time}"
                                         res
                                       end
      end

      def cancella_celle_non_progettate(res, **opts) # rubocop:disable Metrics/AbcSize
        # date le celle in import_cache[:lista_celle], vanno eliminate dal db quelle presenti sul sistema e non presenti nella lista
        lista_celle_da_cancellare = import_cache[:lista_celle_totali].empty? ? [] : import_cache[:lista_celle_totali].keys - import_cache[:lista_celle].keys
        if !lista_celle_da_cancellare.empty?
          Db::ProgettoRadio.dataset.where(nome_cella: lista_celle_da_cancellare).delete
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_CELLE_CANCELLATE, num_celle: lista_celle_da_cancellare.size, nomi_celle: lista_celle_da_cancellare.join(','), **opts)
        else
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_PROGETTO_RADIO_DATI_CELLE_CANCELLATE_NESSUNA, **opts)
        end
        res[:del] = lista_celle_da_cancellare.size
      end

      def aggiorna_header_sistema
        # saa.sistema.update(header_pr: header_sistema)
        Db::Sistema.sistemi_gemelli(saa.sistema.id).first.each do |sss|
          sss.update(header_pr: header_sistema)
        end
      end

      def nuova_segnalazione(tipo_segnalazione, opts = {})
        tipo_segnalazione += 1 if saa.pi && !TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
        super(tipo_segnalazione, opts)
      end

      def con_lock(**opts, &block) # rubocop:disable Metrics/AbcSize
        if saa.is_a?(Db::SistemaAmbienteArchivio)
          Irma.lock(key: LOCK_KEY_PROGETTO_RADIO_OMC_LOGICO, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), omc_logico: saa.sistema.descr, rete: saa.rete.nome, **opts, &block)
        else
          Irma.lock(key: LOCK_KEY_PROGETTO_RADIO_OMC_FISICO, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), omc_fisico: saa.omc_fisico.nome, **opts, &block)
        end
        # TODO: inserire lock su CALCOLO PI: servirebbe un lock sulla scrittura di nuovi Progetti IRMA per il sistema/omcfisico
      end

      def cache_cgi
        @cache_cgi ||= begin
                         xxx = {}
                         return xxx unless eseguire_verifica_cgi?
                         Db::AnagraficaCgi.where(rete_id: saa.rete_id).each do |record|
                           xxx[record[:nome_cella]] = [record[:ci], record[:lac]]
                         end
                         xxx
                       end
      end

      def eseguire_verifica_cgi?
        (saa.rete_id != RETE_LTE) && (ImportProgettoRadio.config[CONTROLLO_CGI].to_i == 1)
      end

      def esegui(lista_file:, step_info: 1_000, **opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        res = { celle: Hash.new(0), totale: 0 }
        step_progresso = opts[:step_progresso] || 1_000
        funzione = Db::Funzione.get_by_pk(FUNZIONE_IMPORT_PROGETTO_RADIO)
        con_lock(funzione: funzione.nome, account_id: saa.account_id, mode: LOCK_MODE_WRITE, **opts) do # |locks|
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: saa.filtro_segnalazioni, attivita_id: opts[:attivita_id]) do
            Irma.gc
            con_import_cache(**opts) do
              carica_celle_da_prn
              carica_anagrafica_enodeb if saa.rete_id == RETE_LTE
              cache_cgi if eseguire_verifica_cgi?
              # --
              lista_file.each_with_index do |file, idx|
                con_parser(file: file, **opts) do |parser|
                  InfoProgresso.start(log_prefix: opts[:log_prefix], step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
                    begin
                      Db::ProgettoRadio.dataset.db.transaction do
                        res[:"parser_#{idx}"] = parser.parse do |cella_parser|
                          ret = analizza_cella_parser(cella_parser: cella_parser, **opts)
                          res[:celle][ret] += 1
                          ip.incr
                          case ret
                          when ESITO_ANALISI_ENTITA_OK
                            aggiorna_database(cella_parser, res[:celle])
                          when ESITO_ANALISI_ENTITA_RIGA_NON_VALIDA
                            logger.warn("#{opts[:log_prefix]}, scartata cella (#{ret}), info=#{cella_parser.info}")
                          else
                            logger.warn("#{opts[:log_prefix]}, scartata cella (#{ret}), info=#{cella_parser.info}")
                          end
                          res[:totale] += 1
                          segnalazione_esecuzione_in_corso("(aggiornate #{res[:totale]} celle)") if step_progresso > 0 && ((res[:totale] % step_progresso) == 0)
                        end # parser
                        cancella_celle_non_progettate(res[:celle], **opts) if @delete_no_prog
                        aggiorna_header_sistema
                      end # transaction
                    rescue => e
                      res[:eccezione] = "#{e}: #{e.message} - nella rescue di begin"
                      logger.error("#{@log_prefix} catturata eccezione (#{res})")
                      raise
                    end
                  end
                end
              end # lista_file
              # --
              segnalazione_esecuzione_in_corso("(aggiornamento di #{res[:totale]} celle completato)")

              # Controlli NON-Vincolanti
              unless @controlli_non_vincolanti.empty?
                segnalazione_esecuzione_in_corso('(inizio controlli non vincolanti)')
                carica_info_adiacenti
                @controlli_non_vincolanti.each do |controllo, reti_id|
                  tipi_adj = map_rete_tipo_adj(reti_id)
                  segnalazione_esecuzione_in_corso("(inizio controllo non vincolante: #{controllo}, tipo_adj: #{tipi_adj})")
                  # puts "-- CTRL_NV: controllo non vincolante: #{controllo}, tipo_adj: #{tipi_adj}"
                  esegui_controllo_non_vinc(controllo, tipi_adj)
                  segnalazione_esecuzione_in_corso("(fine controllo non vincolante: #{controllo}, tipo_adj: #{tipi_adj})")
                end
                segnalazione_esecuzione_in_corso('(fine controlli non vincolanti)')
              end
              res[:msg] = 'caricamento eseguito'
              res
            end # con_import_cache
          end # con_segnalazioni
        end # saa_con_lock
        res
      end

      def esegui_elimina_celle_da_prn(lista_celle:, **opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        res = { celle: Hash.new(0), totale: lista_celle.size }
        funzione = Db::Funzione.get_by_pk(FUNZIONE_ELIMINA_CELLE_DA_PRN)
        con_lock(funzione: funzione.nome, account_id: saa.account_id, mode: LOCK_MODE_WRITE, **opts) do # |locks|
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: saa.filtro_segnalazioni, attivita_id: opts[:attivita_id]) do
            Irma.gc
            begin
              Db::ProgettoRadio.transaction do
                # query = Db::ProgettoRadio.where(sistema_id: saa.sistema_id)
                query = Db::ProgettoRadio.where_sistema_id(saa.sistema_id)
                query = query.where(nome_cella: lista_celle) if lista_celle && lista_celle != [ALL_PRN_CELLS]
                lista_celle_da_cancellare = query.select_map(:nome_cella).sort
                num_canc = query.delete
                nuova_segnalazione(TIPO_SEGNALAZIONE_ELIMINA_CELLE_DA_PRN_DATI_INFO, num_celle: lista_celle_da_cancellare.size, nomi_celle: lista_celle_da_cancellare.join(', '), **opts)
                res[:celle][:del] = num_canc
              end # transaction
            rescue => e
              res[:eccezione] = "#{e}: #{e.message} - nella rescue di begin"
              logger.error("#{@log_prefix} catturata eccezione (#{res})")
              raise
            end
          end
        end
        res
      end
    end
    #
    module ImportProgettoRadioUtil
      def import_progetto_radio(lista_file:, **opts)
        begin
          importer_class = Funzioni::ImportProgettoRadio.const_get(opts[:formato].to_s.camelize)
        rescue => e
          raise "Formato '#{opts[:formato]}' non supportato per l'importer di Progetto Radio (#{e})"
        end
        importer_class.new(sistema_ambiente_archivio: self, **opts).esegui(lista_file: lista_file, **opts)
      end

      def elimina_celle_da_prn(lista_celle:, **opts)
        Funzioni::ImportProgettoRadio.new(sistema_ambiente_archivio: self, **opts).esegui_elimina_celle_da_prn(lista_celle: lista_celle, **opts)
      end
    end
  end
  #
  module Db
    # extend class
    class SistemaAmbienteArchivio
      include Funzioni::ImportProgettoRadioUtil
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      include Funzioni::ImportProgettoRadioUtil
    end
  end
end

require_relative 'import_progetto_radio/text_cella'
require_relative 'import_progetto_radio/xls_cella'
