# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini, G. Cristelli
#
# Creation date: 20160401
#

require_relative 'segnalazioni_per_funzione'
require_relative 'export_formato_utente/formatter'
require 'irma/filtro_entita_util'
require 'irma/conteggio_eccezioni_util'

module Irma
  #
  module Funzioni
    #
    # rubocop:disable Metrics/ClassLength
    class ExportFormatoUtente
      include SegnalazioniPerFunzione
      include FiltroEntitaUtil
      include ConteggioEccezioniUtil

      FORMATTERS = Formatter::Base.descendants.map { |k| k.to_s.split(':').last.downcase }

      attr_reader :logger, :sistema_ambiente_archivio, :metamodello, :filtro_metamodello, :log_prefix, :funzione
      alias saa sistema_ambiente_archivio

      def initialize(sistema_ambiente_archivio:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
        unless sistema_ambiente_archivio.is_a?(Db::SistemaAmbienteArchivio) || sistema_ambiente_archivio.is_a?(Db::OmcFisicoAmbienteArchivio)
          raise ArgumentError, "Parametro sistema_ambiente_archivio '#{sistema_ambiente_archivio}' non valido"
        end
        @sistema_ambiente_archivio = sistema_ambiente_archivio
        @metamodello = opts[:metamodello]
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Export formato utente (#{sistema_ambiente_archivio.full_descr})"
        @meta_parametri_strutturati = {}
        @filtro_metamodello = opts[:filtro_metamodello]
        @con_version = opts[:con_version]
        @use_pi = opts[:use_pi] || false
        @solo_header = opts[:solo_header]

        # solo per ARCHIVIO_ECCEZIONI
        @contatori = {}
        @filtro_parametri_sempre_assenti = {}

        @etichette_eccezioni = (opts[:etichette_eccezioni] || []).compact
        @etichette_nette = opts[:etichette_nette]
        @indice_etichette = opts[:indice_etichette]
        @info_etichette = {}
      end

      def dataset
        @dataset ||= saa.dataset(use_pi: @use_pi)
      end

      # parametri: { 'p1' => ['p1'], 'p2' => ['p2'], ..., 'ps.a1&ps.a2' => ['ps.a1', 'ps.a2'], ... }
      # filtro: ['p1', ..., 'ps.a1']
      def parametro_da_scartare?(param, filtro)
        !filtro.member?(param) && filtro.select { |xxx| param.start_with?(xxx.split(TEXT_STRUCT_NAME_SEP).first + TEXT_STRUCT_NAME_SEP) }.empty?
      end

      def meta_parametri_strutturati_me(mps, fm, sempre_assenti) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        fm_wildcard = ((fm || [])[0] == META_PARAMETRO_ANY)
        return { META_PARAMETRO_ANY => [] } if fm_wildcard && @solo_header
        ret_params = {}
        (mps || {}).each do |k, v|
          next if fm && !fm_wildcard && parametro_da_scartare?(k, fm)
          next if (sempre_assenti || []).include?(k)
          ret_params[k] = v
        end
        ret_params
      end

      def meta_parametri_strutturati(me) # rubocop:disable Metrics/AbcSize
        # filtro = filtro_metamodello && filtro_metamodello[me.naming_path]
        filtro = if filtro_metamodello && filtro_metamodello[me.naming_path]
                   if filtro_metamodello[me.naming_path].is_a?(Array)
                     filtro_metamodello[me.naming_path]
                   else
                     filtro_metamodello[me.naming_path][FILTRO_MM_PARAMETRI]
                   end
                 end
        @meta_parametri_strutturati[me.id] ||= begin
                                                 x = meta_parametri_strutturati_me(metamodello.meta_parametri_fu[me.naming_path],
                                                                                   filtro,
                                                                                   @filtro_parametri_sempre_assenti[me.naming_path])
                                                 x ||= {}
                                                 { meta_p: x, hdr: x.keys.sort_by(&:downcase) }
                                               end
      end

      def header_campi_parametro(me)
        meta_parametri_strutturati(me)[:hdr]
      end

      def header(me)
        x = me.naming_path.split(NAMING_PATH_SEP)
        x += [TEXT_VERSION_ENTITA] if @con_version
        x += header_campi_parametro(me)
        x
      end

      def campi_entita(dist_name)
        dist_name.split(DIST_NAME_SEP).map { |p| p.split(DIST_NAME_VALUE_SEP)[1] }
      end

      def sistema_parametri_assente(pezzi) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        # una struttura con tutti parametri 'ASSENTE' si traduce nella stringa 'ASSENTE'
        # da ASSENTE&ASSENTE&... ---> ASSENTE
        return [TEXT_PARAMETRO_ASSENTE] if pezzi.uniq == [TEXT_PARAMETRO_ASSENTE]
        # una struttura con tutti parametri '--' si traduce nella stringa '--'
        # da --&--&... ---> --
        return [TEXT_PARAMETRO_IGNORATO] if pezzi.uniq == [TEXT_PARAMETRO_IGNORATO]
        # se uno dei parametri della struttura multiistanziata non figura in nessuna istanza,
        # 'TEXT_NO_VAL' va ripetuto per il numero di istanze
        # da <> ---> <>|<>|...
        if pezzi.count > 1 && pezzi.member?(TEXT_NO_VAL) && (max = pezzi.map { |pp| pp.split(TEXT_ARRAY_ELEM_SEP).count }.max) > 1
          pezzi.map! { |pp| pp == TEXT_NO_VAL ? ([TEXT_NO_VAL] * max).join(TEXT_ARRAY_ELEM_SEP) : pp }
        end
        pezzi
      end

      def campi_parametri(mps:, param:, aggiorna_info_etichette: false, dist_name: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        parametri = (param || {})
        mps[:hdr].map do |cc|
          label = nil
          pezzi = (mps[:meta_p][cc]).map do |ppp|
            valore_parametro = if saa.archivio == ARCHIVIO_ECCEZIONI && parametri[ppp] && (label = parametro_con_etichetta_ok(ppp, dist_name)).nil?
                                 TEXT_PARAMETRO_IGNORATO
                               else
                                 parametri[ppp]
                               end
            # aggiorna_info_etichette(dist_name, ppp, label, valore_parametro) if aggiorna_info_etichette
            MetaModello.parametro_to_s(valore_parametro)
          end
          xxx = sistema_parametri_assente(pezzi).join(TEXT_STRUCT_SEP)
          aggiorna_info_etichette(dist_name, cc, label, xxx) if aggiorna_info_etichette && label
          xxx
        end
      end

      def aggiorna_info_etichette(dn, param, label, valore)
        return unless @indice_etichette && @info_etichette
        return if valore.nil? || valore == TEXT_PARAMETRO_IGNORATO
        @info_etichette[dn] ||= {}
        @info_etichette[dn][label] ||= []
        @info_etichette[dn][label] << param
      end

      def table_name
        saa.pi.nil? ? saa.entita.table_name : saa.pi.entita.table_name
      end

      def suffisso_nome_file
        saa.is_a?(Db::SistemaAmbienteArchivio) ? "#{saa.vendor_release.descr}_#{saa.rete.nome}" : saa.omc_fisico.nome
      end

      def con_formatter(type:, out_dir:, &block)
        Formatter.with(type, out_dir: out_dir, logger: logger, log_prefix: log_prefix,
                             suffisso_nome_file: suffisso_nome_file, solo_header: @solo_header, indice_etichette: @indice_etichette, &block)
      end

      def nuova_segnalazione(tipo_segnalazione, opts = {})
        return nil if @solo_header
        unless TIPO_SEGNALAZIONE_GENERICA.include?(tipo_segnalazione)
          case funzione.id
          when FUNZIONE_EXPORT_FORMATO_UTENTE_PARZIALE
            tipo_segnalazione += 1
          when FUNZIONE_EXPORT_FU_OMC_FISICO
            tipo_segnalazione += 10
          when FUNZIONE_EXPORT_FU_OMC_FISICO_PARZIALE
            tipo_segnalazione += 11
          end
        end
        super(tipo_segnalazione, opts)
      end

      def parametro_con_etichetta_ok(parametro, dist_name)
        xxx = parametro.split(TEXT_STRUCT_NAME_SEP)
        @entita_label[key_entita_label(dist_name, xxx.first + (xxx.count > 1 ? TEXT_STRUCT_NAME_SEP : ''))]
      end

      def conteggio_parametri(meta_entita:, feu_info:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        np = meta_entita.naming_path
        @contatori[np] = {}
        header_campi_parametro(meta_entita).each { |ppp| @contatori[np][ppp] = 0 }
        saa.db.transaction do
          query = feu_info[:feu_query_np]
          filtro_wi = feu_info[:feu_filtro_wi]

          query.each do |record|
            next if !filtro_wi.empty? && !feu_tengo?(record[:dist_name], filtro_wi)
            parametri = campi_parametri(mps: meta_parametri_strutturati(meta_entita), param: record[:parametri], dist_name: record[:dist_name])
            header_campi_parametro(meta_entita).each_with_index do |ppp, idx|
              @contatori[np][ppp] += 1 unless parametri[idx] == TEXT_PARAMETRO_ASSENTE || parametri[idx] == TEXT_PARAMETRO_IGNORATO
            end
          end
          unless !@contatori[np].empty? && @contatori[np].values.min > 0 # neppure un param con contatore = 0
            @filtro_parametri_sempre_assenti[np] = []
            @contatori[np].each do |ppp, count|
              @filtro_parametri_sempre_assenti[np] << ppp if count == 0
            end
          end
          @meta_parametri_strutturati.delete(meta_entita.id) # reset per prossimo giro
        end
      end

      def export_dati(meta_entita:, feu_info:, formatter:, info_progresso:, res:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        res[:meta_entita] ||= 0
        np = meta_entita.naming_path
        return if saa.archivio == ARCHIVIO_ECCEZIONI && header_campi_parametro(meta_entita).empty?
        query = feu_info[:feu_query_np]
        filtro_wi = feu_info[:feu_filtro_wi]
        done = nil
        saa.db.transaction do
          query.each do |record|
            next if !filtro_wi.empty? && !feu_tengo?(record[:dist_name], filtro_wi)
            unless done
              res[:meta_entita] += formatter.nuova_meta_entita(meta_entita: meta_entita, header: header(meta_entita),
                                                               header_campi_param: header_campi_parametro(meta_entita),
                                                               contatori: @contatori[np])
              done = true
            end
            campi = campi_entita(record[:dist_name])
            campi += [record[:version]] if @con_version
            ccpp = campi_parametri(mps: meta_parametri_strutturati(meta_entita), param: record[:parametri], dist_name: record[:dist_name], aggiorna_info_etichette: true)
            # Per archivio eccezioni evitare scrittura di righe con tutti parametri ASSENTE o --
            next if saa.archivio == ARCHIVIO_ECCEZIONI && ((ccpp || []).uniq - [TEXT_PARAMETRO_ASSENTE, TEXT_PARAMETRO_IGNORATO]).empty?
            campi += ccpp
            n = formatter.nuovi_parametri(campi)
            next unless info_progresso
            info_progresso.incr(n) { segnalazione_esecuzione_in_corso("(processate #{info_progresso.total} entita' e #{res[:meta_entita]} meta entita', #{info_progresso.rate.round(0)} entita'/s)") }
          end
        end
      end

      def esegui_export_filtro_fu(np, formatter, res) # rubocop:disable Metrics/AbcSize
        meta_entita = metamodello.meta_entita[np]
        return unless meta_entita
        res[:meta_entita] += formatter.nuova_meta_entita(meta_entita: meta_entita, header: header(meta_entita), header_campi_param: header_campi_parametro(meta_entita), contatori: {})
        return if filtro_metamodello.nil? || filtro_metamodello[np].nil? || filtro_metamodello[np].is_a?(Array)
        (filtro_metamodello[np][FILTRO_MM_ENTITA] || []).each do |record|
          campi = campi_entita(record)
          formatter.nuovi_parametri(campi)
        end
      end

      def np_da_considerare
        @np_da_considerare ||= filtro_metamodello ? (metamodello.meta_entita.keys & filtro_metamodello.keys) : metamodello.meta_entita.keys
      end
      # ------------------------------------------------
      SEP_KEY_ENTITA_LABEL = '___'.freeze

      def key_entita_label(dist_name, parametro)
        "#{dist_name}#{SEP_KEY_ENTITA_LABEL}#{parametro}"
      end

      def carica_entita_label(array_labels) # rubocop:disable Metrics/AbcSize
        ret = {}
        return ret if (array_labels || []).empty?
        dataset_el = Db::EntitaLabel.new(archivio: ARCHIVIO_LABEL,
                                         vendor: saa.sistema.vendor_id, rete: saa.sistema.rete_id,
                                         omc_logico: saa.sistema.descr, omc_logico_id: saa.sistema.id).dataset
        dataset_el.db.transaction do
          dataset_el.where(label: array_labels).each do |record|
            ret[key_entita_label(record[:dist_name], record[:meta_parametro])] = (record[:label] == LABEL_NC_DB ? NO_LABEL : record[:label])
          end
        end
        ret
      end
      # ------------------------------------------------

      def esegui(out_dir:, step_info: 100_000, **opts) # rubocop:disable  Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        res = { meta_entita: 0, entita: 0, msg: '' }
        @funzione = Db::Funzione.get_by_pk(opts[:funzione])
        saa.con_lock(funzione: funzione.nome, account_id: saa.account_id, enable: opts.fetch(:lock, !@solo_header), logger: logger, log_prefix: log_prefix, **opts) do |locks|
          con_segnalazioni(funzione: funzione, account: saa.account, filtro: saa.filtro_segnalazioni, attivita_id: opts[:attivita_id], enable: !@solo_header) do
            raise "MetaModello non valido per il sistema #{sistema_ambiente_archivio.full_descr}" unless metamodello
            con_formatter(type: opts[:formato] || :txt, out_dir: out_dir) do |formatter|
              # vendor_release_descr = sistema_ambiente_archivio.vendor_release.descr
              logger.info("#{log_prefix}, inizio esecuzione con formatter #{formatter}")
              segnalazione_esecuzione_in_corso("(generazione file in formato #{opts[:formato]})")
              Irma.gc
              #------------------------
              if @solo_header
                np_da_considerare.each do |np|
                  next unless esegui_export_filtro_fu(np, formatter, res)
                end
                #------------------------
              else
                res[:locks] = locks
                InfoProgresso.start(logger: logger, log_prefix: log_prefix, step_info: step_info, res: res, attivita_id: opts[:attivita_id]) do |ip|
                  # ---------------------------------------------------------------------------------------
                  if saa.archivio == ARCHIVIO_ECCEZIONI
                    edc = Db::EtichettaEccezioni.etichette_da_considerare(sistema: saa.sistema,
                                                                          filtro_etichette: @etichette_eccezioni,
                                                                          flag_nette: @etichette_nette)
                    @entita_label = carica_entita_label(edc)
                  end
                  # ---------------------------------------------------------------------------------------
                  np_da_considerare.each do |np|
                    feu = feu_query_per_naming_path(naming_path: np, dataset: dataset,
                                                    filtro_np: (filtro_metamodello || {})[np],
                                                    nome_tabella: table_name)
                    meta_entita = metamodello.meta_entita[np]
                    next unless meta_entita
                    # Primo giro per conteggio parametri
                    conteggio_parametri(meta_entita: meta_entita, feu_info: feu) if saa.archivio == ARCHIVIO_ECCEZIONI
                    # Secondo giro per export dati
                    export_dati(meta_entita: meta_entita, feu_info: feu, formatter: formatter, info_progresso: ip, res: res)
                  end # ciclo su np_da_considerare
                  formatter.aggiorna_info_etichette(@info_etichette)
                  # ---------------------------------------------------------------------------------------
                  res[:entita] = ip.total
                  segnalazione_esecuzione_in_corso("(processazione di #{res[:entita]} entita' e #{res[:meta_entita]} meta entita' completata, #{ip.rate.round(0)} entità/s)")
                end # InfoProgresso
                nuova_segnalazione(TIPO_SEGNALAZIONE_EXPORT_FORMATO_UTENTE_DATI_NON_PRESENTI) if res[:entita].zero?
              end # solo_header
            end # con_formatter
            res
          end
        end
      end
    end
  end

  #
  module Db
    # extend class
    class SistemaAmbienteArchivio
      def export_formato_utente(out_dir:, **opts)
        opts.update(funzione: opts[:filtro_metamodello] ? FUNZIONE_EXPORT_FORMATO_UTENTE_PARZIALE : FUNZIONE_EXPORT_FORMATO_UTENTE)
        Funzioni::ExportFormatoUtente.new(sistema_ambiente_archivio: self, **opts).esegui(out_dir: out_dir, **opts)
      end
    end
    # extend class
    class OmcFisicoAmbienteArchivio
      def export_formato_utente(out_dir:, **opts)
        opts.update(funzione: opts[:filtro_metamodello] ? FUNZIONE_EXPORT_FU_OMC_FISICO_PARZIALE : FUNZIONE_EXPORT_FU_OMC_FISICO)
        Funzioni::ExportFormatoUtente.new(sistema_ambiente_archivio: self, **opts).esegui(out_dir: out_dir, **opts)
      end
    end
  end
end
