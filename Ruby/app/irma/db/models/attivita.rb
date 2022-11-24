# vim: set fileencoding=utf-8
#
# Author: S. Campestrini, G. Cristelli
#
# Creation date: 20160704
#

require 'aasm'
#
module Irma
  module Db
    # rubocop:disable Metrics/ClassLength
    class Attivita < Model(:attivita)
      include AASM
      plugin :single_table_inheritance, :kind

      plugin :timestamps, update_on_create: true

      validates_constant :stato

      def attivita_schedulata
        attivita_schedulata_id && AttivitaSchedulata.first(id: attivita_schedulata_id)
      end

      def self.pubblica_sulla_coda(coda, opts = {})
        super(coda, opts.reject { |k, _v| %i(risultato info_comando cronologia_stato).include?(k) })
      end

      def self.query_tree(att_id)
        Attivita.where(Sequel.or(id: att_id) | Sequel.or(root_id: att_id)).order(:id)
      end

      def aggiorna_cronologia_stato(tt: Time.now)
        self.cronologia_stato ||= []
        # Time.at(1472728819068/1000.0) => 2016-09-01 13:20:19 +0200
        # Time.at(1472728819068/1000.0).usec => 68000
        # Time.at(1472728819068/1000.0).strftime("%Y%m%d%H%M%S%L") => "20160901132019068"
        self.cronologia_stato << [stato, tt.cronologia]
      end

      def cronologia_stato_stati
        cronologia_stato.map { |yy| yy[0] }
      end

      def cronologia_stato_tempi
        cronologia_stato.map { |yy| yy[1] }
      end

      def after_create
        super
        pubblica_sulla_coda(PUB_ATTIVITA, action: 'create', delay: 1)
      end

      def before_update
        # aggiorna_attivita_schedulata
        if changed_columns.member?(:stato)
          changed_columns << :cronologia_stato # Sequel BUG: non automatico per campi json
          aggiorna_cronologia_stato
        end
        super
      end

      def after_update
        super
        self.class.pubblica_sulla_coda(PUB_ATTIVITA, id: id, pid: pid, account_id: account_id, stato: stato, descr: descr, action: 'update', competenze: competenze, delay: 1)
      end

      def before_destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        logger.info("Destroy dell'Attivita con id #{id} (#{descr})")
        res = Segnalazione.where(attivita_id: root_id ? id : self.class.query_tree(id).select(:id)).delete
        logger.info("Rimosse #{res} Segnalazioni collegate all'Attivita con id #{id}")
        unless root_id
          res = Attivita.where(root_id: id).delete
          logger.info("Rimosse #{res} Attivita figlie dell'Attivita con id #{id}")
        end
        unless dir.to_s.empty? || dir.to_s == '/'
          begin
            res = shared_remove_path(dir)
            logger.info("Rimozione della directory #{dir} sul server shared_fs (attivita con id #{id}) completata: #{res}")
          rescue => e
            logger.error("Rimozione della directory #{dir} sul server shared_fs (attivita con id #{id}) fallita: #{e}")
          end
        end
        super
      end

      def expired?(t = Time.now)
        ((start_time || ack_time || created_at) + expire_sec) < t ? true : false
      end

      def log_status_change
        logger.info("Eseguita transizione di stato per l'attivita' con id #{id} (#{descr}) a seguito di evento #{aasm(:stato).current_event}" \
                    " da #{aasm(:stato).from_state} a #{aasm(:stato).to_state} (esecutore = #{esecutore})")
      end

      def gestione_errori(e)
        aasm_gestione_errori('stato', e)
      end

      def _termina_esecuzione(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        self.risultato ||= opts[:risultato] || {}
        self.artifacts = (artifacts || []) + (opts[:artifacts] || risultato[:artifacts] || risultato['artifacts'] || [])
        self.start_time ||= opts[:start_time] || Time.now
        self.end_time = opts[:end_time] || Time.now
        self.durata = (end_time - start_time).round(0)
        aggiorna_contatori_gerarchia(nome_contatore: opts[:nome_contatore]) if foglia?
        termina_schedulata if radice?
        self
      rescue => e
        logger.error("Problemi nella terminazione dell'esecuzione dell'attivita' con id #{id}: #{e}, #{e.backtrace}")
      end

      def radice?
        pid.nil?
      end

      def foglia?
        # !info_comando.to_s.empty?
        self.class == AttivitaFoglia
      end

      # Quando l'attivita' viene abortita ed e' un'attivita' padre, lo stato operativo dell'attivita'
      # schedulata collegata va modificato
      def aggiorna_attivita_schedulata
        AttivitaSchedulata.first(id: attivita_schedulata_id).riconsidera! if pid.nil? && abortita?
      end

      def termina_schedulata
        x = AttivitaSchedulata.first(id: attivita_schedulata_id)
        x.termina! if x
      end

      SITUAZIONE_DIPENDE_DA = [DIPENDE_DA_TUTTE_OK = 0, DIPENDE_DA_IN_CORSO = 1, DIPENDE_DA_CON_KO = 2].freeze

      def situazione_dipende_da # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        res = DIPENDE_DA_TUTTE_OK
        dipende_da_positivo = (dipende_da || []).each_with_object({}) { |att_id, tot| tot[att_id.abs] = (att_id > 0) }
        unless dipende_da_positivo.empty?
          Db::Attivita.where(id: dipende_da_positivo.keys).each do |att_dep|
            if dipende_da_positivo[att_dep.id]
              return DIPENDE_DA_CON_KO if att_dep.terminata_con_errore? || att_dep.abortita? || att_dep.non_eseguibile?
              res = DIPENDE_DA_IN_CORSO unless att_dep.terminata_con_successo? || att_dep.terminata_con_segnalazione?
            else
              # nel caso di negativo, ignoro l'errore delle dipendenze
              res = DIPENDE_DA_IN_CORSO unless att_dep.terminata_con_errore? || att_dep.abortita? || att_dep.non_eseguibile? || att_dep.terminata_con_successo? || att_dep.terminata_con_segnalazione?
            end
          end
        end
        res
      end

      def aggiorna_contatori_gerarchia(nome_contatore:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return self unless pid
        contatore = nome_contatore.to_s
        parent = nil
        transaction do
          parent = Attivita.first(id: pid)
          if parent
            parent.lock!
            parent.foglie_stato_finale[contatore] += 1
            logger.info("Incrementato contatore #{contatore} per attivita con id #{parent.id} - #{parent.foglie_stato_finale[contatore]}")
            # ---
            # parent.artifacts = ((parent.artifacts || []) + artifacts).sort.uniq if artifacts
            parent.artifacts = ((parent.artifacts || []) + artifacts).uniq.sort_by { |x|  x.is_a?(Array) ? x[0] : x } if artifacts
            # ---
            err = risultato && (risultato[:errore] || risultato['errore'])
            if err
              parent.risultato ||= {}
              parent.risultato[:errori] ||= []
              parent.risultato[:errori] = parent.risultato[:errori] + [err]
            end
            parent.save
          end
        end
        if parent
          begin
            parent.verifica_completamento_attivita_in_corso
          rescue => e
            logger.error("verifica_completamento_attivita_in_corso fallito per attivita padre (#{parent.id}), #{e}")
          end
          parent.aggiorna_contatori_gerarchia(nome_contatore: nome_contatore)
        end
        self
      end

      def scheduler_pool # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        sp = nil
        if info_comando && !info_comando.to_s.empty?
          c = Constant.constants(:comando).find { |x| x.info[:command] == info_comando.first }
          sp = c.info[:pool] if c
          logger.error("Comando #{info_comando.first} non anagrafato nelle costanti :comando") unless sp || info_comando.first == 'eval'
        end
        sp || SCHEDULER_POOL_SLOW
      end
    end

    #
    class AttivitaFoglia < Attivita
      def before_create
        raise "Una attivita' foglia deve avere un comando associato" if info_comando.to_s.empty?
        aggiorna_cronologia_stato
        self.foglie_stato_finale = {}
        super
      end

      aasm(:stato, column: :stato, enum: true) do
        AttivitaFoglia.constant_keys(:stato).each { |s| state s }

        after_all_transitions :log_status_change
        error_on_all_events :gestione_errori

        event :gerarchia_non_corretta do
          before do |opts|
            self.risultato = { errore: (opts && opts[:errore]) || 'gerarchia attività non corretta' }
          end
          transitions from: :pendente, to: :non_eseguibile
        end
        event :assegna do
          before do |opts|
            self.esecutore = (opts && opts[:esecutore]) || nil
            raise "Esecutore non avvalorato per l'attivita con id #{id}" unless esecutore
          end
          transitions from: :pendente, to: :assegnata
        end
        event :prendi_in_carico do
          before do |opts|
            self.ack_time = (opts && opts[:ack_time]) || Time.now
          end
          transitions from: :assegnata, to: :presa_in_carico
        end
        event :inizia_esecuzione do
          before do |opts|
            self.start_time = (opts && opts[:start_time]) || Time.now
          end
          transitions from: :presa_in_carico, to: :in_esecuzione
        end
        event :abort do
          after do |opts|
            aggiorna_contatori_gerarchia((opts || {}).merge(nome_contatore: :foglie_abort))
            begin
              Irma.rimuovi_locks_per_attivita(id)
            rescue => e
              logger.warn("Problemi nella rimozione dei lock associati all'attività con id #{id}: #{e}")
            end
          end
          transitions from: [:pendente, :assegnata, :presa_in_carico, :in_esecuzione], to: :abortita
        end
        event :riconsidera do
          before do |opts|
            options = opts || {}
            self.ack_time = self.start_time = self.esecutore = nil
            self.num_retry ||= 0
            self.max_retry ||= 1
            self.num_retry += (options[:incr_retry] || 1)
            aggiorna_contatori_gerarchia((opts || {}).merge(nome_contatore: :foglie_abort)) if self.num_retry >= self.max_retry
            begin
              Irma.rimuovi_locks_per_attivita(id)
            rescue => e
              logger.warn("Problemi nella rimozione dei lock associati all'attività con id #{id}: #{e}")
            end
          end
          transitions from: [:assegnata, :presa_in_carico, :in_esecuzione], to: :pendente, if: proc { |*_args| max_retry && (num_retry < max_retry) }
          transitions from: [:assegnata, :presa_in_carico, :in_esecuzione], to: :abortita, if: proc { |*_args| max_retry && (num_retry >= max_retry) }
        end
        event :elimina do
          before do |opts|
            aggiorna_contatori_gerarchia((opts || {}).merge(nome_contatore: :foglie_eliminate))
          end
          transitions from: [:pendente, :assegnata, :presa_in_carico], to: :eliminata
        end
        event :dipende_da_con_errore do
          before do |opts|
            aggiorna_contatori_gerarchia((opts || {}).merge(nome_contatore: :foglie_non_eseguibili))
          end
          transitions from: [:pendente], to: :non_eseguibile
        end
        event :termina_con_successo do
          before do |opts|
            _termina_esecuzione((opts || {}).merge(nome_contatore: :foglie_terminate_ok))
          end
          transitions from: [:in_esecuzione], to: :terminata_con_successo
        end
        event :termina_con_segnalazione do
          before do |opts|
            _termina_esecuzione((opts || {}).merge(nome_contatore: :foglie_terminate_con_segnalazione))
          end
          transitions from: [:in_esecuzione], to: :terminata_con_segnalazione
        end
        event :termina_con_errore do
          before do |opts|
            _termina_esecuzione((opts || {}).merge(nome_contatore: :foglie_terminate_ko)) unless terminata_con_errore?
          end
          transitions from: [:in_esecuzione], to: :terminata_con_errore
        end
      end

      def self.aasm_stati_finali
        %w(terminate_ok terminate_ko terminate_con_segnalazione non_eseguibili eliminate abort)
      end

      def find_all_values_for(hash, key)
        ret = []
        ret << hash[key] if hash[key]
        hash.any? { |_k, v| ret += find_all_values_for(v, key) if v.is_a? Hash }
        ret.compact
      end

      def ci_sono_segnalazioni?(res)
        xx = find_all_values_for(res, :segnalazioni)
        tot = 0
        xx.each do |sss|
          tot += (sss[:ripartizione]['WARNING'].to_i + sss[:ripartizione]['ERROR'].to_i) if sss.is_a?(Hash) && sss[:ripartizione]
        end
        tot > 0
      end

      def esegui(opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        inizia_esecuzione!
        res = info_comando.first.casecmp('eval').zero? ? send(:eval, info_comando[1]) : Irma::Command.process(info_comando + ['--attivita_id', id], logger: opts[:logger] || Irma.logger)
        reload
        unless in_esecuzione?
          # durante l'esecuzione del comando l'attivita e' stata abortita o terminata dallo scheduler...
          logger.warn("Attivita' con id #{id} risulta in stato #{stato} al termine dell'esecuzione del comando.")
          return
        end
        termina = (ci_sono_segnalazioni?(res) || res[TERMINATA_WARNING]) ? 'termina_con_segnalazione!' : 'termina_con_successo!'
        send(termina, risultato: res, artifacts: (res[:artifacts] || res['artifacts'] || []))
      rescue => e
        begin
          reload
        rescue
          logger.warn("Attivita' con id #{id} non ricaricata: #{e}")
        end
        termina_con_errore!(risultato: { errore: e.to_s }) if in_esecuzione?
        raise
      end
    end

    #
    class AttivitaContenitore < Attivita
      def before_create
        raise "Una attivita' contenitore non puo' avere un comando associato" unless info_comando.to_s.empty?
        aggiorna_cronologia_stato
        self.foglie_stato_finale = self.class.foglie_stato_finale_init
        super
      end

      def self.foglie_stato_finale_init
        h = {}
        AttivitaFoglia.aasm_stati_finali.each { |xx| h["foglie_#{xx}"] = 0 }
        h
      end

      aasm(:stato, column: :stato, enum: true) do
        AttivitaContenitore.constant_keys(:stato).each { |s| state s }

        after_all_transitions :log_status_change
        error_on_all_events :gestione_errori

        event :gerarchia_non_corretta do
          before do |opts|
            self.risultato =  { errore: (opts && opts[:errore]) || 'gerarchia attività non corretta' }
          end
          transitions from: :pendente, to: :non_eseguibile
        end
        event :inizia_contenitore do
          before do |opts|
            self.start_time = (opts && opts[:start_time]) || Time.now
          end
          transitions from: :pendente, to: :in_corso
        end
        event :elimina do
          transitions from: [:pendente], to: :eliminata
        end
        event :in_corso_con_errore do
          transitions from: [:in_corso, :in_corso_con_errore], to: :in_corso_con_errore
        end
        event :termina_con_successo do
          before do |opts|
            _termina_esecuzione((opts || {}).merge(nome_contatore: :foglie_terminate_ok))
          end
          transitions from: [:in_corso], to: :terminata_con_successo
        end
        event :termina_con_segnalazione do
          before do |opts|
            _termina_esecuzione((opts || {}).merge(nome_contatore: :foglie_terminate_con_segnalazione))
          end
          transitions from: [:in_corso], to: :terminata_con_segnalazione
        end
        event :termina_con_errore do
          before do |opts|
            _termina_esecuzione((opts || {}).merge(nome_contatore: :foglie_terminate_ko)) unless terminata_con_errore?
          end
          transitions from: [:in_corso, :in_corso_con_errore], to: :terminata_con_errore
        end
        event :termina_per_timeout do
          before do |opts|
            _termina_esecuzione((opts || {}).merge(nome_contatore: :foglie_abort)) unless terminata_per_timeout?
          end
          transitions from: [:in_corso, :in_corso_con_errore], to: :terminata_per_timeout
        end
      end

      # common method with AttivitaFoglia
      def abortita?
        terminata_per_timeout?
      end

      def foglie_terminate
        foglie_stato_finale.values.inject(0, &:+)
      end

      def foglie_stato_finale_ko
        foglie_terminate - foglie_stato_finale['foglie_terminate_ok'] - foglie_stato_finale['foglie_terminate_con_segnalazione']
      end

      def verifica_completamento_attivita_in_corso # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return self if foglie_totali <= 0
        # se sono un contenitore e contengo qualcosa...
        if foglie_terminate == foglie_totali
          # esecuzione terminata
          if foglie_terminate == foglie_stato_finale['foglie_terminate_ok'] # sono finite tutte 'OK'
            termina_con_successo!
          elsif foglie_stato_finale_ko > 0
            foglie_stato_finale['foglie_abort'] > 0 ? termina_per_timeout! : termina_con_errore!
          elsif foglie_stato_finale['foglie_terminate_con_segnalazione'] > 0
            termina_con_segnalazione!
          end
        elsif foglie_stato_finale_ko > 0 # ancora qualche foglia in corso...e almeno 1 finita male
          in_corso_con_errore!
        end
        self
      end
    end
  end
end

# == Schema Information
#
# Tabella: attivita
#
#  account_id             :integer         riferimento a accounts.id
#  ack_time               :datetime
#  ambiente               :string(10)
#  archivio               :string(10)
#  artifacts              :json
#  attivita_schedulata_id :integer         riferimento a attivita_schedulate.id
#  competenze             :json
#  created_at             :datetime
#  cronologia_stato       :json
#  descr                  :string
#  dipende_da             :json
#  dir                    :string(256)
#  durata                 :integer
#  end_time               :datetime
#  esecutore              :string(128)
#  expire_sec             :integer
#  foglie_stato_finale    :json
#  foglie_totali          :integer         default(0)
#  id                     :bigint          non nullo, default(nextval('attivita_id_seq')), chiave primaria
#  info_comando           :json
#  kind                   :string
#  max_retry              :integer         default(3)
#  num_retry              :integer         default(0)
#  peso                   :integer
#  pid                    :bigint
#  profilo_id             :integer         riferimento a profili.id
#  risultato              :json
#  root_id                :bigint          riferimento a attivita.id
#  start_time             :datetime
#  stato                  :string(32)      default('pendente')
#  updated_at             :datetime
#  utente_id              :integer         riferimento a utenti.id
#
# Indici:
#
#  idx_attivita_account              (account_id)
#  idx_attivita_attivita_schedulata  (attivita_schedulata_id)
#  idx_attivita_root_id              (root_id)
#  idx_attivita_stato                (stato)
#
