# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20151216
#

require 'irma/record_formatter'

module Irma
  module Db
    #
    class Segnalazione < Model(:segnalazioni)
      plugin :timestamps, update_on_create: true

      validates_constant :gravita

      def self.cleanup(_hash = {})
        cleanup_only_rebuild_indexes
      end

      def self.crea(tipo_segnalazione, hash = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        tipo_segnalazione = TipoSegnalazione.get_by_pk(tipo_segnalazione.is_a?(TipoSegnalazione) ? tipo_segnalazione.id : tipo_segnalazione)
        segnalazione_incompatibile = hash[:funzione_id] && tipo_segnalazione.funzione_id && (hash[:funzione_id] != tipo_segnalazione.funzione_id)
        raise "Funzione id (#{hash[:funzione_id]}) incompatibile con quella del tipo_segnalazione #{tipo_segnalazione.id} (#{tipo_segnalazione.funzione_id})" if segnalazione_incompatibile
        begin
          o = new({ tipo_segnalazione_id: tipo_segnalazione.id, funzione_id: tipo_segnalazione.funzione_id,
                    gravita: tipo_segnalazione.gravita, to_update_adrn: tipo_segnalazione.to_update_adrn,
                    messaggio: tipo_segnalazione.messaggio(hash) }.merge(hash.select { |k, _v| columns.include?(k.to_sym) }))
          o.save
          logger.send(tipo_segnalazione.gravita == TIPO_SEGNALAZIONE_GRAVITA_INFO ? :info : :warn,
                      "Creata segnalazione #{o.id}, attivita_id=#{o.attivita_id}, account=#{o.account_desc} (#{o.account_id}), sistema_id=#{o.sistema_id}, omc_fisico_id=#{o.omc_fisico_id}," \
                      " progetto_irma_id=#{o.progetto_irma_id}, report_comparativo_id=#{o.report_comparativo_id}," \
                      " ambiente=#{o.ambiente}, archivio=#{o.archivio}, tipo=#{tipo_segnalazione.identificativo_messaggio}, messaggio='#{o.messaggio.to_s.gsub("\n", '\n')}'")
          Irma.publish(PUB_ATTIVITA, { id: o.attivita_id, action: 'in_progress' }.to_json, delay: 1) if o.attivita_id && hash[:progress]
          o
        rescue => e
          raise "Parametri obbligatori assenti nella creazione della segnalazione (#{e})"
        end
      end

      def to_export # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return nil unless to_update_adrn
        meta_parametro_genere = (meta_parametro && gu = Constant.info(:tipo_segnalazione, tipo_segnalazione_id)[:genere_per_update]) && Constant.info(:meta_parametro, gu, :genere)
        meta_parametro_pieces = meta_parametro && meta_parametro.split(TEXT_STRUCT_NAME_SEP)
        [
          meta_parametro ? naming_path : naming_path.split(NAMING_PATH_SEP)[0..-2].join(NAMING_PATH_SEP),       # NAMING_PATH
          (meta_parametro_pieces && meta_parametro_pieces[-1]) || meta_entita,                                  # OGGETTO
          meta_parametro ? 0 : 1,                                                                               # ENTITA'
          (meta_parametro_genere && meta_parametro_genere[:value] == META_PARAMETRO_GENERE_SEMPLICE) ? 1 : 0,   # PARAM_SEMPLICI
          (meta_parametro_pieces && meta_parametro_pieces.size > 1 && meta_parametro_pieces[0]) || 0,           # PARAM_STRUTTURATI
          # (meta_parametro_genere && meta_parametro_genere[:multivalore]) ? 1 : 0,                               # PARAM_MULTIVALORE
          # TODO: da togliere a valle della dismissione di IRMA1 e ripristinare la riga precedente: PARAM_MULTIVALORE e MULTISTRUTTURATO per IRMA1
          (meta_parametro_genere && (meta_parametro_genere[:multivalore] || meta_parametro_genere[:value] == META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE)) ? 1 : 0,
          0                                                                                                     # PARAM_READ_ONLY
        ]
      end

      TO_EXPORT_FIELDS = %w(naming_path oggetto entita param_semplici param_strutturati param_multivalore param_read_only).freeze
      def to_export_hash
        vals = to_export
        return vals unless vals
        Hash[TO_EXPORT_FIELDS.zip(vals)]
      end

      class RecordFormatterTxt < RecordFormatter::Txt
        def header
          @header ||= %w(NAMING_PATH OGGETTO ENTITA' PARAM_SEMPLICI PARAM_STRUTTURATI PARAM_MULTIVALORE PARAM_READ_ONLY).join("\t")
        end

        def add_record_values(record, _values)
          record.to_update_adrn ? add_line(record.to_export.join("\t")) : false
        end
      end
    end
  end
end

# == Schema Information
#
# Tabella: segnalazioni
#
#  account_desc                 :string(256)
#  account_id                   :integer         non nullo
#  ambiente                     :string(10)
#  archivio                     :string(10)
#  attivita_id                  :integer
#  created_at                   :datetime
#  dettaglio                    :string
#  funzione_id                  :integer         non nullo, riferimento a funzioni.id
#  gravita                      :integer         non nullo
#  id                           :bigint          non nullo, default(nextval('segnalazioni_id_seq')), chiave primaria
#  linea_file                   :integer
#  messaggio                    :string
#  meta_entita                  :string(256)
#  meta_parametro               :string(256)
#  naming_path                  :string(1024)
#  omc_fisico_id                :integer
#  profilo_id                   :integer         riferimento a profili.id
#  progetto_irma_id             :integer         riferimento a progetti_irma.id
#  report_comparativo_id        :integer         riferimento a report_comparativi.id
#  secondi_da_inizio_esecuzione :integer
#  sistema_id                   :integer
#  tipo_segnalazione_id         :integer         non nullo, riferimento a tipi_segnalazioni.id
#  to_update_adrn               :boolean         non nullo, default(false)
#  updated_at                   :datetime
#  utente_id                    :integer         non nullo
#  vendor_release_id            :integer
#
# Indici:
#
#  idx_segnalazioni_account             (account_id)
#  idx_segnalazioni_attivita            (attivita_id)
#  idx_segnalazioni_omc_fisico          (omc_fisico_id)
#  idx_segnalazioni_progetto_irma       (progetto_irma_id)
#  idx_segnalazioni_report_comparativo  (report_comparativo_id)
#  idx_segnalazioni_sistema             (sistema_id)
#  idx_segnalazioni_utente              (utente_id)
#  idx_segnalazioni_vendor_release_id   (vendor_release_id)
#
