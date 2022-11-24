# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20190205
#
require_relative 'segnalazioni_per_funzione'
require 'irma/poi'
require 'irma/conteggio_eccezioni_util'

# rubocop:disable Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
module Irma
  #
  module Funzioni
    class ConteggioAlberatureAde
      include Irma::PoiUtil
      include SegnalazioniPerFunzione
      include ConteggioEccezioniUtil

      attr_reader :logger, :log_prefix, :stats
      attr_reader :cache_conteggi, :cache_eccezioni, :cache_sistemi
      attr_reader :filtro_metamodello

      def initialize(**opts)
        @stats               = nil
        @logger              = opts[:logger] || Irma.logger
        @log_prefix          = opts[:log_prefix] || 'Conteggio alberature'
        @np_alberatura       = opts[:np_alberatura]
        @filtro_metamodello  = opts[:filtro_metamodello]
        @lista_sistemi_id    = opts[:lista_sistemi_id]
        @etichette_eccezioni = (opts[:etichette_eccezioni] || []).compact
        @etichette_nette     = opts[:etichette_nette]
        # output
        @out_file            = opts[:out_file]
        # strutture d'appoggio
        @cache_eccezioni  = {}
        @labels_eccezioni = {}
        @cache_sistemi    = {}
      end

      #--------------------------------------------------------
      def reset_cache
        @cache_eccezioni  = {}
        @labels_eccezioni = {}
        @cache_sistemi    = {}
      end

      def prepara_lista_sistemi(lista_sistemi_id)
        reset_cache
        ss_id_inesistenti = []

        (lista_sistemi_id || []).each do |ss_id|
          ss_id = ss_id.to_i
          ss_obj = Db::Sistema.first(id: ss_id)
          if ss_obj.nil?
            ss_id_inesistenti
          else
            @cache_sistemi[ss_id] = ss_obj
            @cache_eccezioni[ss_id] = {}
          end
        end
        nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_ADE_DATI_SISTEMI_INESISTENTI, lista_sistemi: ss_id_inesistenti.join(',')) unless ss_id_inesistenti.empty?
        nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_ADE_DATI_NO_SISTEMI_OK, lista_sistemi: (lista_sistemi_id || []).join(',')) if @cache_sistemi.empty?
      end

      def sigla_retevendor(rete_id, vendor_id)
        Db::Rete.first(id: rete_id).alias + Db::Vendor.first(id: vendor_id).sigla
      end

      def aggiorna_cache_conteggio_eccez_ade(sistema_id:, counters_eccez:)
        # counters_eccez = { np => { dn1 => {'label1' => 10, 'label2' => 79, ...}, dn1 => {'label1' => 16,...} }, ...}
        rv = @cache_sistemi[sistema_id].sigla_retevendor
        counters_eccez.each do |np, np_info|
          @cache_eccezioni[sistema_id][np] ||= {}
          @labels_eccezioni[rv] ||= {}
          @labels_eccezioni[rv][np] ||= []
          np_info.each do |dn, info|
            info ||= {}
            @labels_eccezioni[rv][np] |= info.keys
            @cache_eccezioni[sistema_id][np][dn] = info
          end
        end
      end

      def add_row(style:, fields_keys:, values: {}, header: false)
        if @riga + 1 >= EXCEL_LIMIT_ROWS
          sn = @sheet.name
          nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_ADE_DATI_SUPERATO_EXCEL_LIMIT_ROWS, book_name: File.basename(@book.filename), sheet_name: sn) unless sn.index(EXCEL_LIMIT_KEYWORD)
          @sheet = @book.worksheets[next_sheet_name_extra_limit(sn)]
          @riga = -1
        end
        @riga += 1
        row = @sheet.new_row(@riga)
        (fields_keys || []).each_with_index do |c, idx|
          row[idx].value = values[c] || ''
          row[idx].style = if header
                             style[:header]
                           else
                             style[values[c].to_s.numeric? ? :right : :left]
                           end
        end
      end

      def valore_na(val)
        (val.nil? || val == -1) ? NOT_AVAILABLE_STR : val
      end

      def load_extra_names_ade(sistema_id, naming_path, array_dist_name)
        res = {}
        return res if array_dist_name.empty? || (omc_id = @cache_sistemi[sistema_id].omc_fisico_id).nil?
        dataset = Db::OmcFisicoAmbienteArchivio.new(omc_fisico: omc_id, archivio: ARCHIVIO_RETE, account: @account.id).dataset
        return res unless dataset
        until array_dist_name.empty?
          dn_sub_list = array_dist_name.shift(1_000)
          dataset.where('extra_name is not NULL').where(naming_path: naming_path).where(dist_name: dn_sub_list).select_map([:dist_name, :extra_name]).each do |xxx|
            res[xxx[0]] = xxx[1]
          end
        end
        res
      end

      CAMPI_CONTEGGIO_ADE = {
        CAMPO_SISTEMA              = :campo_sistema              => 'Sistema'.freeze,
        CAMPO_NAME                 = :campo_name                 => 'Nome'.freeze,
        CAMPO_EXTRA_NAME           = :campo_extra_name           => 'Nome Extra'.freeze,
        CAMPO_ECCEZIONI            = :campo_eccezioni            => 'Eccezioni'.freeze,
        CAMPO_ECCEZIONI_NETTE      = :campo_eccezioni_nette      => 'Eccezioni nette'.freeze,
        CAMPO_SEPARATORE_ECCEZIONI = :campo_separatore_eccezioni => VALORE_CAMPO_SEPARATORE,
        CAMPO_SEPARATORE_NP        = :campo_separatore_np        => VALORE_CAMPO_SEPARATORE
      }.freeze

      def raggruppa_sistemi_per_output
        res = {}
        @cache_sistemi.each do |ss_id, ss_obj|
          key_rv = ss_obj.sigla_retevendor
          res[key_rv] ||= { sistemi: [], np: [] }
          res[key_rv][:np] |= @cache_eccezioni[ss_id].keys
          res[key_rv][:sistemi] << ss_id
        end
        res
      end

      def nome_foglio_ade(me_nome, rete_vendor, used)
        used ||= {}
        nome = "#{rete_vendor}-#{me_nome}"
        ret = if used[nome].nil?
                used[nome] = 0
                nome
              else
                "#{nome}-#{used[nome]}"
              end
        used[nome] += 1
        ret
      end

      def scrivi_file_conteggio_ade(file:)
        reti_vendors = raggruppa_sistemi_per_output

        Irma.export_xls(file) do |xls_book|
          nomi_meta_entita = {}
          @book = xls_book
          stili = crea_stili(@book)
          reti_vendors.each do |key_rv, info_rv|
            info_rv[:np].each do |np|
              # Nuovo sheet per retevendor-np
              meta_entita = np.split(NAMING_PATH_SEP).last
              @sheet = @book.worksheets[nome_sheet(nome_foglio_ade(meta_entita, key_rv, nomi_meta_entita))]
              @riga = -1
              campi_labels_eccezioni = [NO_LABEL] + (@labels_eccezioni[key_rv][np] || []).sort
              campi_pezzi_np = np.split(NAMING_PATH_SEP)

              # --- Header
              hash_hdr = {}
              CAMPI_CONTEGGIO_ADE.each do |k, titolo|
                hash_hdr[k] = titolo
                if k == CAMPO_SEPARATORE_ECCEZIONI
                  campi_labels_eccezioni.each { |label| hash_hdr["#{PREFIX_ECCEZ}_#{label}"] = label }
                elsif k == CAMPO_SEPARATORE_NP
                  campi_pezzi_np.each.with_index { |v, idx| hash_hdr["#{PREFIX_NP}_#{idx}"] = v }
                end
              end
              add_row(style: stili, fields_keys: hash_hdr.keys, values: hash_hdr, header: true)

              # --- Righe dati
              righe_da_scrivere = []
              info_rv[:sistemi].each do |s_id|
                sistema = @cache_sistemi[s_id]
                extra_names = load_extra_names_ade(s_id, np, (@cache_eccezioni[s_id][np] || {}).keys)
                (@cache_eccezioni[s_id][np] || {}).each do |dn, eccez|
                  valori_hash = {
                    CAMPO_EXTRA_NAME       => valore_na(extra_names[dn]),
                    CAMPO_NAME             => dn.split(DIST_NAME_VALUE_SEP).last,
                    CAMPO_SISTEMA          => sistema.full_descr,
                    CAMPO_ECCEZIONI        => (eccez && eccezioni_totali(conters_per_etichetta: eccez)) || 0,
                    CAMPO_ECCEZIONI_NETTE  => (eccez && eccezioni_nette(conters_per_etichetta: eccez, labels_nette: @labels_nette)) || 0,
                    CAMPO_SEPARATORE_ECCEZIONI => '',
                    CAMPO_SEPARATORE_NP => ''
                  }
                  campi_labels_eccezioni.each do |label|
                    valori_hash["#{PREFIX_ECCEZ}_#{label}"] = (eccez && eccez[label]) || 0
                  end
                  pezzi_dn = dn.split(DIST_NAME_SEP).map { |el| el.split(DIST_NAME_VALUE_SEP).fetch(1) }
                  campi_pezzi_np.each.with_index do |_v, idx|
                    valori_hash["#{PREFIX_NP}_#{idx}"] = pezzi_dn[idx]
                  end
                  righe_da_scrivere << valori_hash
                end
              end
              righe_da_scrivere.sort_by { |x| x[CAMPO_ECCEZIONI] }.reverse_each do |vals_hash|
                add_row(style: stili, fields_keys: hash_hdr.keys, values: vals_hash)
              end
            end
          end
        end
      end

      def conteggio_eccezioni_ade(sistema:)
        res = {}
        edc = Db::EtichettaEccezioni.etichette_da_considerare(sistema: sistema,
                                                              filtro_etichette: @etichette_eccezioni,
                                                              flag_nette: @etichette_nette)
        # @np_alberatura.each do |np|
        (@np_alberatura & sistema.metamodello.meta_entita.keys).each do |np|
          res[np] = conteggio_eccezioni_per_etichetta(sistema: sistema, np_root: np, filtro_metamodello: filtro_metamodello, filtro_etichette: edc)
        end
        res
      end

      def esegui_conteggi_eccezioni_ade
        @labels_nette = Db::EtichettaEccezioni.load_hash_labels_nette
        @cache_sistemi.each do |s_id, s_obj|
          begin
            cnt_eccez = conteggio_eccezioni_ade(sistema: s_obj)
          rescue => e
            cnt_eccez = nil
            nuova_segnalazione(TIPO_SEGNALAZIONE_CONTEGGIO_ALBERATURE_ADE_DATI_ERRORE_CONTEGGIO_ECCEZ, sistema: s_obj.full_descr, msg: e.message)
          end
          next unless cnt_eccez
          aggiorna_cache_conteggio_eccez_ade(sistema_id: s_id, counters_eccez: cnt_eccez)
        end
      end
      #--------------------------------------------------------

      def esegui(**opts)
        res = {}
        funzione = Db::Funzione.get_by_pk(FUNZIONE_CONTEGGIO_ALBERATURE_ADE)
        @account = Db::Account.first(id: opts[:account_id])
        @attivita_id = opts[:attivita_id]

        con_segnalazioni(funzione: funzione, account: @account, attivita_id: opts[:attivita_id]) do
          reset_cache
          prepara_lista_sistemi(@lista_sistemi_id)
          next res if (@cache_sistemi || {}).empty?
          res[:sistemi_analizzati] = @cache_sistemi.size
          esegui_conteggi_eccezioni_ade
          scrivi_file_conteggio_ade(file: @out_file)
          res
        end # con_segnalazioni
        res
      end
    end
  end
end
