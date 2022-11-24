# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180117
#

require_relative 'segnalazioni_per_funzione'
require_relative 'export_progetto_radio/formatter'

module Irma
  #
  module Funzioni
    #
    class ExportProgettoRadio
      include SegnalazioniPerFunzione

      attr_reader :logger, :log_prefix, :out_dir, :sistemi, :data_aggiornamento

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || "Export prn per i sistemi (#{@sistemi})"
        @sistemi = opts[:sistemi]
        @data_aggiornamento = opts[:data_aggiornamento]
        @file_unico = opts[:file_unico]
        @out_dir = opts[:out_dir]
        @formato = opts[:formato]
      end

      def con_formatter(type_export:, out_file:, &block)
        Formatter.get_formatter(type_export, out_file: out_file, logger: logger, log_prefix: log_prefix, &block)
      end

      def con_lock(**opts, &block)
        sistemi_lock_keys = Db::Sistema.where(id: (opts[:sistemi] || [])).map { |sss| Irma.lock_full_keys(key: LOCK_KEY_PROGETTO_RADIO_OMC_LOGICO, omc_logico: sss.descr, rete: sss.rete.nome).first }
        Irma.lock(key: sistemi_lock_keys, mode: LOCK_MODE_READ, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def export_prn_sistema(sistema_id:, formatter:, res:, con_header: true) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        sistema = Db::Sistema.get_by_pk(sistema_id)
        unless sistema
          nuova_segnalazione(TIPO_SEGNALAZIONE_EXPORT_PROGETTO_RADIO_DATI_SISTEMA_NON_CORRETTO, sistema: sistema_id, messaggio: "Sistema con id #{sistema_id} inesistente")
          return
        end
        header = (sistema.header_pr || {}).keys - [''] # !!!!!!!!!!!! 20190819
        if header.empty?
          nuova_segnalazione(TIPO_SEGNALAZIONE_EXPORT_PROGETTO_RADIO_DATI_SISTEMA_NON_CORRETTO,
                             sistema: sistema_id,
                             messaggio: "Intestazione del Progetto Radio vuota per il sistema #{sistema.full_descr}")
          return
        end

        start_time = Time.now
        num_celle = 0
        segnalazione_esecuzione_in_corso("(Inizio generazione export prn per il sistema #{sistema.full_descr})")
        # puts "XXXXXXXXXXXXX inizio generazione export prn per il sistema #{sistema.full_descr}"
        formatter.scrivi_header(campi_linea: header + (data_aggiornamento ? ['Data aggiornamento'] : []), nome_foglio: sistema.vendor_release.full_descr) if con_header
        # query = Db::ProgettoRadio.where(sistema_id: sistema_id)
        query = Db::ProgettoRadio.where_sistema_id(sistema_id)
        query = data_aggiornamento ? query.select(:valori, :updated_at) : query.select(:valori)
        query = query.order_by(:nome_cella)
        query.each do |progetto_radio|
          riga = header.map { |p| ((progetto_radio[:valori][p] || [])[0]).to_s }
          riga << progetto_radio[:updated_at].to_s if data_aggiornamento
          formatter.scrivi_linea(campi_linea: riga)
          num_celle += 1
        end
        res[:progetti_radio] += num_celle
        segnalazione_esecuzione_in_corso("(Terminata generazione export prn per il sistema #{sistema.full_descr}, esportate #{num_celle} celle in #{(Time.now - start_time).round(1)} sec.)")
        # puts "XXXXXXXXXXXXX terminata generazione export prn per il sistema #{sistema.full_descr}, esportate #{num_celle} celle in #{(Time.now - start_time).round(1)} sec."
      end

      def out_file_name(sistema_descr: nil, formato: FORMATO_EXPORT_XLS, time: Time.now.strftime('%Y%m%d%H%M'))
        "prn_#{sistema_descr || 'multi_sistema'}_#{time}.#{formato.gsub(/xls$/, 'xlsx')}"
      end

      def raggruppa_sistemi_per_vr(sistemi)
        res = {}
        sistemi.each do |sss|
          sistema = Db::Sistema.first(id: sss)
          res[sistema.vendor_release_id] ||= []
          res[sistema.vendor_release_id] << sss
        end
        res
      end

      def esegui(**opts) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        res = { progetti_radio: 0 }
        funzione = Db::Funzione.get_by_pk(FUNZIONE_EXPORT_PROGETTO_RADIO)
        @account = Db::Account.first(id: opts[:account_id])
        @attivita_id = opts[:attivita_id]

        con_lock(funzione: funzione.nome, account_id: @account.id, logger: logger, log_prefix: log_prefix, **opts) do |locks|
          res[:locks] = locks
          start_time_tot = Time.now
          con_segnalazioni(funzione: funzione, account: @account, attivita_id: @attivita_id) do
            ref_date_str = Time.now.strftime('%Y%m%d%H%M')
            Db::ProgettoRadio.transaction do
              if @file_unico && sistemi.count > 1
                start_time = Time.now
                out_file = File.join(opts[:out_dir], out_file_name(formato: opts[:formato], time: ref_date_str))
                sistemi_per_vr = raggruppa_sistemi_per_vr(sistemi)
                con_formatter(type_export: opts[:formato], out_file: out_file) do |formatter|
                  Irma.gc
                  sistemi_per_vr.each do |_vr_id, ssss|
                    ssss.each.with_index { |sisid, idx| export_prn_sistema(sistema_id: sisid, formatter: formatter, con_header: idx == 0, res: res) }
                  end
                  # sistemi.each { |sisid| export_prn_sistema(sistema_id: sisid, formatter: formatter, con_header: true, res: res) }
                end
              else
                sistemi.each do |sisid|
                  sistema = Db::Sistema.first(id: sisid)
                  out_file = File.join(opts[:out_dir], out_file_name(sistema_descr: sistema.str_descr, formato: opts[:formato], time: ref_date_str))
                  con_formatter(type_export: opts[:formato], out_file: out_file) do |formatter|
                    start_time = Time.now
                    Irma.gc
                    export_prn_sistema(sistema_id: sisid, formatter: formatter, res: res)
                  end
                end
              end # if file_unico
            end # transaction
            res[:durata] = (Time.now - start_time_tot).round(1)
            res
          end # con_segnalazioni
        end # con_lock
        res
      end
    end
  end
end
