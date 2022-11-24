# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20160315
#

require 'base64'

module Irma
  module Db
    # rubocop:disable Metrics/ClassLength
    class Sessione < Model(:sessioni)
      plugin :timestamps, update_on_create: true

      config.define TIMEOUT_SESSIONE = :timeout_sessione, 15 * 60,
                    descr:         'Timeout (in secondi) della sessione in caso di non utilizzo della GUI',
                    widget_info:   'Gui.widget.positiveInteger({minValue: 60, maxValue:864000})'

      # validates_constant(:ambiente)

      def self.cleanup(_hash = {})
        cleanup_only_rebuild_indexes
      end

      def before_destroy
        crea_sessione_chiusa
        pubblica_sulla_coda(PUB_SESSIONI, action: 'destroy')
      end

      def after_create
        pubblica_sulla_coda(PUB_SESSIONI, action: 'create')
      end

      def account
        Account.find(id: account_id)
      end

      def login_ok(account_id:, matricola:, profilo:, ambiente:, utente_descr:, **opts) # rubocop:disable Metrics/ParameterLists
        begin
          update(account_id: account_id, matricola: matricola, profilo: profilo, ambiente: ambiente, utente_descr: utente_descr,
                 **opts.select { |k, _v| columns.include?(k) })
          renew
        rescue => e
          logger.error("Unexpected error updating session: #{e}, session inspect: #{inspect}")
          raise
        end
        self
      end

      def expired?
        (id.nil? || expire_at.nil? || (expire_at < Time.now)) ? true : false
      end

      def renew(opts = {})
        update({ expire_at: Time.now + config[TIMEOUT_SESSIONE] }.merge(opts))
        self
      end

      def logout(note: '')
        self.note = note
        begin
          destroy
        rescue => e
          logger.error("Unexpected error during session logout: #{e}")
          raise
        end
        self
      end

      def crea_sessione_chiusa
        if account_id
          begin
            SessioneChiusa.create(attributes.merge(ended_at: Time.now))
          rescue => e
            logger.error("Unexpected error logging session: #{e}")
          end
        end
        true
      end

      def data=(v)
        @data_value = v || {}
        super(Base64.encode64(Marshal.dump(@data_value)))
      end

      def data
        @data_value ||= begin
                          v = super
                          v ? Marshal.restore(Base64.decode64(v)) : {}
                        end
      end

      def self.rimozione_sessioni_scadute(expire_date: nil)
        res = { sessioni_rimosse: 0 }
        expire_date ||= Time.now
        cond = "(expire_at is null or expire_at < '#{expire_date}')"
        # logger.info("Rimozione sessioni scadute, inizio verifica (#{cond})")
        where(cond).each do |sess|
          begin
            sess.logout(note: format_msg(:SESSIONE_SCADUTA_RIMOSSA_AUTOMATICAMENTE))
            res[:sessioni_rimosse] += 1
          rescue => e
            # nothing to do
            logger.debug("Session logout exception: #{e}")
          end
        end
        res[:description] = format('Rimosse %{sessioni} sessioni (data scadenza %{expire_date})', sessioni: res[:sessioni_rimosse], expire_date: expire_date)
        # logger.info("Rimozione sessioni scadute, verifica completata (#{res})")
        res
      end

      def runtime # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        {
          session_id:                    session_id,
          version:                       Irma.config[Irma::VERSIONE],
          title:                         Db.production? ? Irma.config[Irma::TITOLO] : "#{Irma.config[Irma::TITOLO]} dev (#{Irma.config[Irma::VERSIONE]})",
          build_id:                      Irma.config[Irma::BUILD_ID],
          account_id:                    account_id,
          matricola:                     matricola,
          utente_descr:                  utente_descr,
          profilo:                       profilo,
          ambiente:                      ambiente,
          competenze:                    data[:competenze],
          preferenze:                    data[:preferenze],
          sistemi_di_competenza:         data[:sistemi_di_competenza],
          omc_fisici_di_competenza:      data[:omc_fisici_di_competenza],
          vendor_releases_di_competenza: data[:vendor_releases_di_competenza],
          valori_competenza:             data[:valori_competenza],
          id_profilo_corrente:           data[:id_profilo_corrente],
          altri_profili:                 data[:altri_profili],
          funzioni_abilitate:            data[:funzioni_abilitate]
        }
      end

      def funzione_abilitata?(f)
        (data[:funzioni_abilitate] || []).include?(f)
      end
    end
  end
end

# == Schema Information
#
# Tabella: sessioni
#
#  account_id   :integer
#  ambiente     :string(10)
#  created_at   :datetime
#  data         :string
#  ended_at     :datetime
#  expire_at    :datetime
#  host         :string(32)
#  id           :bigint          non nullo, default(nextval('sessioni_id_seq')), chiave primaria
#  matricola    :string(32)
#  note         :string(255)
#  profilo      :string(32)
#  session_id   :string(255)     non nullo
#  updated_at   :datetime
#  utente_descr :string(32)
#
# Indici:
#
#  uidx_sessioni_session_id  (session_id) UNIQUE
#
