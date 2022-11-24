# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

require 'tempfile'
require 'aasm'

module Irma
  module Db
    #
    class AttivitaSchedulata < Model(:attivita_schedulate) # rubocop:disable Metrics/ClassLength
      unrestrict_primary_key
      plugin :timestamps, update_on_create: true

      configure_retention 15, use_orm_for_cleanup: true

      config.define DEFAULT_EXPIRE_ATTIVITA = :default_expire_attivita, 3600,
                    descr: 'Default timeout in secondi per l\'esecuzione del comando di una attività',
                    widget_info: 'Gui.widget.positiveInteger({minValue:30, maxValue:86400})'

      ID_SEQUENCE = connection.schema(table_name).find { |x| x[0] == :id }[1][:default]

      include AASM

      def retention_tipo_attivita
        Constant.info(:tipo_attivita, tipo_attivita_id)[:retention] || self.class.retention
      end

      def passata?(t = Time.now)
        # ha una fine validita' e questa e' passata
        # non e' cron e il periodo o e' nullo o e' nel passato
        obsoleta? || (!cron? && Rufus::Scheduler.parse(periodo.to_s.empty? ? t - 1 : periodo.to_s) < t)
      end

      def to_be_destroy?
        passata? && !in_esecuzione? # ??
      end

      def self.remove_obsolete_record(limit_date:, col:, **opts)
        res = 0
        query = where("#{col} < ?", limit_date)
        query = query.where(tipo_attivita_id: opts[:tipo_attivita_id]) if opts[:tipo_attivita_id]
        query.each do |record|
          if record.to_be_destroy?
            record.destroy
            res += 1
          end
        end
        res
      end

      def self.cleanup(opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        res = {}
        start_time = Time.now
        msg = "#{self}: cleanup non eseguito, retention nulla (opts = #{opts})"
        if retention.to_i.nonzero?
          res[:tabella] = table_name
          Constant.constants(:tipo_attivita).sort_by(&:key).each do |ccc|
            next if opts[:tipo_attivita] && ![opts[:tipo_attivita]].flatten.include?(ccc.value)
            la_retention = ccc.info[:retention] || retention
            ta = TipoAttivita.get_by_pk(ccc.value)
            obsolete_date = Time.now - la_retention * 86_400
            res[ta.nome] = {
              retention:             la_retention,
              obsolete_date:         obsolete_date,
              records_attivita_root: ta.rimuovi_attivita_obsolete(obsolete_date)
            }
            res[ta.nome][:records] = remove_records(obsolete_date, tipo_attivita_id: ta.id, rebuild_indexes: false)
          end
          res[:rebuild_indexes_segnalazioni] = Segnalazione.rebuild_indexes
          res[:rebuild_indexes_attivita] = Attivita.rebuild_indexes
          res[:rebuild_indexes_attivita_schedulate] = rebuild_indexes
          res[:elapsed] = (Time.now - start_time).round(1)
          msg = "#{self}: cleanup completato (opts = #{opts}, res = #{res})"
        end
        logger.info(msg)
        res
      end

      def self.cron?(s)
        Rufus::Scheduler.parse(s.to_s).is_a?(Rufus::Scheduler::CronLine)
      end

      def cron?
        self.class.cron?(periodo)
      end

      def self.datetime?(s)
        datetime_regex = Regexp.new(DATE_TIME_REGEXPR)
        !datetime_regex.match(s).nil?
      end

      def datetime?
        self.class.datetime?(periodo)
      end

      def self.next_id
        next_id = nil
        connection.fetch("select #{ID_SEQUENCE} as nextval") do |row|
          next_id = row[:nextval]
        end
        next_id
      end

      def before_create
        check_opts_info_attivita
        aggiorna_cronologia_stato_operativo
        super
      end

      def before_update
        _controllo_intervallo_di_validita(inizio_validita, fine_validita)
        if changed_columns.member?(:stato_operativo)
          changed_columns << :cronologia_stato_operativo # Sequel BUG: non automatico per campi json
          aggiorna_cronologia_stato_operativo
        end
        check_opts_info_attivita if changed_columns.member?(:opts_info_attivita)
        super
      end

      def after_create
        Irma.publish(PUB_ATTIVITA_SCHEDULATA, { action: :create, id: id }.to_json)
        super
      end

      def after_update
        super
        Irma.publish(PUB_ATTIVITA_SCHEDULATA, { action: :update, id: id }.to_json)
      end

      def before_destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        if id
          logger.info("Destroy dell'AttivitaSchedulata con id #{id}")
          query_attivita = Attivita.where(attivita_schedulata_id: id)
          res = Segnalazione.where(attivita_id: query_attivita.select(:id)).delete
          logger.info("Rimosse #{res} Segnalazioni collegate all'AttivitaSchedulata con id #{id}")
          res = query_attivita.delete
          logger.info("Rimosse #{res} Attivita collegate all'AttivitaSchedulata con id #{id}")
          dir = Irma.shared_relative_attivita_dir(id)
          begin
            res = shared_remove_path(dir)
            logger.info("Rimozione della directory #{dir} sul server shared_fs (AttivitaSchedulata con id #{id}) completata: #{res}")
          rescue => e
            logger.error("Rimozione della directory #{dir} sul server shared_fs (AttivitaSchedulata con id #{id}) fallita: #{e}")
          end
        end
        super
      end

      def inizio_validita=(v)
        _controllo_intervallo_di_validita(v, fine_validita)
        super(v)
      end

      def fine_validita=(v)
        _controllo_intervallo_di_validita(inizio_validita, v)
        super(v)
      end

      validates_constant :stato

      aasm(:stato, column: :stato, enum: true) do
        AttivitaSchedulata.constant_keys(:stato).each { |s| state s }

        after_all_transitions :log_status_change
        error_on_all_events :gestione_errori_aasm_event_stato

        event :sospendi do
          transitions from: [:obsoleta, :attiva], to: :sospesa
        end
        event :attiva do
          transitions from: [:obsoleta, :sospesa], to: :attiva
        end
        event :rendi_obsoleta do
          transitions from: [:attiva, :sospesa], to: :obsoleta
        end
        event :completa do
          transitions from: [:attiva, :sospesa], to: :completata
        end
      end

      validates_constant :stato_operativo

      def check_opts_info_attivita
        opts_info_attivita.is_a?(Hash) && !opts_info_attivita.empty? # TODO: aggiungere requisiti minimi per opts_info_attivita
      end

      def aggiorna_cronologia_stato_operativo(tt: Time.now) # rubocop:disable Metrics/AbcSize
        self.cronologia_stato_operativo ||= []
        # per evitare che l'array diventi troppo grande, cancello gli elementi piu' vecchi di 7 giorni
        retention = Constant.info(:tipo_attivita, tipo_attivita_id)[:retention_cronologia_so] || 7
        tt_retention = tt - (86_400 * retention)
        self.cronologia_stato_operativo.delete_if { |xx| xx[1] < tt_retention.cronologia }
        self.cronologia_stato_operativo << [stato_operativo, tt.cronologia]
      end

      def errore_in_esegui(e)
        if e.is_a?(AASM::InvalidTransition)
          gestione_errori_aasm_event_oper_stato(e)
          raise e
        end
        @eccezione = e
        msg = "Problemi nella creazione gerarchia attivita' per l'attivita' schedulata con id #{id} e info_attivita #{@info_att}, eccezione #{e}"
        Db::Evento.crea(TIPO_EVENTO_ATTIVITA_SCHEDULATA_GERARCHIA_ERRATA, descr: msg)
      end

      aasm(:stato_operativo, column: :stato_operativo, enum: true) do
        AttivitaSchedulata.constant_keys(:stato_operativo).each { |s| state s }

        after_all_transitions :log_oper_status_change
        error_on_all_events :gestione_errori_aasm_event_oper_stato

        event :schedula do
          transitions from: [:in_attesa], to: :schedulata
        end
        event :esegui, error: :errore_in_esegui do
          after_transaction -> { raise @eccezione if @eccezione }
          transitions from: [:schedulata, :terminata], to: :in_esecuzione, if: proc { |*_args| crea_gerarchia_attivita ? true : false }
        end
        event :termina do
          # se cron? 'stato_operativo' passa in 'schedulata'
          # altrimenti 1. 'stato_operativo' passa in 'terminata' e 2. 'stato' in 'completata'
          transitions from: [:in_esecuzione], to: :terminata, if: proc { |*_args| cron? ? false : completa }
          transitions from: [:in_esecuzione], to: :schedulata, if: proc { |*_args| cron? }
        end
        event :annulla do
          transitions from: [:in_attesa, :schedulata], to: :annullata
        end
        event :riconsidera do
          transitions from: [:annullata, :in_attesa, :schedulata, :in_esecuzione], to: :in_attesa
        end
      end

      def log_status_change
        logger.info("Eseguita transizione di stato per l'attivita' schedulata con id #{id} (#{descr})" \
                    " a seguito di evento #{aasm(:stato).current_event} da #{aasm(:stato).from_state} a #{aasm(:stato).to_state}")
      end

      def log_oper_status_change
        logger.info("Eseguita transizione di stato operativo per l'attivita' schedulata con id #{id} (#{descr})" \
                    " a seguito di evento #{aasm(:stato_operativo).current_event} da #{aasm(:stato_operativo).from_state} a #{aasm(:stato_operativo).to_state}")
      end

      def gestione_errori_aasm_event_stato(e)
        aasm_gestione_errori('stato', e)
      end

      def gestione_errori_aasm_event_oper_stato(e)
        aasm_gestione_errori('stato_operativo', e)
      end

      def _controllo_intervallo_di_validita(inizio, fine)
        raise "Il campo inizio_validita (#{inizio}) non può essere superiore a fine_validita (#{fine}) per l'attivita_schedulata con id #{id}" if inizio && fine && (fine < inizio)
      end

      def valida?(t = Time.now)
        (inizio_validita.nil? || (inizio_validita <= t)) && (fine_validita.nil? || (fine_validita >= t)) ? true : false
      end

      def verifica_obsolescenza(t = Time.now)
        rendi_obsoleta! if fine_validita && (fine_validita < t)
        self
      end

      def aggiorna_competenze(opts = {})
        nuove_competenze = opts[:competenze] || opts['competenze'] || info_attivita(opts).first['competenze'] # info_attivita.first e' la root
        update(competenze: nuove_competenze)
      end

      def tipo_attivita
        TipoAttivita.where(id: tipo_attivita_id).first
      end

      def check_info_attivita(info_att) # rubocop:disable Metrics/CyclomaticComplexity
        return false if info_att.nil? || !info_att.respond_to?(:[]) || info_att.empty?
        info_att.each { |ia| return false unless ia.is_a?(Hash) }
        return false if info_att.size == 1 && info_att[0]['info_comando'].nil?
        true
      end

      def info_attivita(opts = {})
        @info_attivita ||= (opts_info_attivita['info_attivita'] || tipo_attivita.class.info_attivita(opts.merge(Marshal.load(Marshal.dump(opts_info_attivita)))))
        raise "info_attivita non corrette per l'attivita schedulata (#{id}): #{@info_attivita}" unless check_info_attivita(@info_attivita)
        @info_attivita
      end

      def crea_gerarchia_attivita(opts = {}) # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
        e = nil
        @info_att = {}
        begin
          dir_attivita = opts[:dir_attivita] || directory_attivita
          array_info_attivita = opts[:info_attivita] || opts_info_attivita['info_attivita'] || info_attivita(opts.merge('dir_attivita' => dir_attivita)) # NB: per facilitare test
          aggiorna_dipendenze_info_attivita(array_info_attivita)
        rescue => e
          logger.error("Errore in crea_gerarchia_attivita per l'attività schedulata con id #{id} nel recupero info_attivita: #{e}, #{e.backtrace}")
        end

        unless e
          map_id = {}
          transaction(auto_savepoint: true) do
            (array_info_attivita || []).each do |ia|
              @info_att = ia
              classe = ia['info_comando'].to_s.empty? ? AttivitaContenitore : AttivitaFoglia
              unless ia['info_comando'].to_s.empty?
                ia['info_comando'] = ia['info_comando'].map { |xx| [true, false].include?(xx) ? xx.to_s : xx }
                ia['info_comando'] = ia['info_comando'].map { |xx| xx.is_a?(String) ? xx.gsub(/#{DIR_ATTIVITA_TAG}/, dir_attivita.to_s) : xx }
              end

              transaction do
                begin
                  map_id[ia['key']] = classe.create(
                    descr:                  ia['pid'] ? ia['label'] : descr,
                    artifacts:              ia['artifacts'],
                    peso:                   ia['peso'] || 0,
                    pid:                    map_id[ia['pid']],
                    root_id:                map_id[ATTIVITA_ROOT_KEY],
                    dir:                    dir_attivita,
                    attivita_schedulata_id: id,
                    info_comando:           ia['info_comando'],
                    dipende_da:             ia['dipende_da'].map do |orig_dip|
                                              # nel caso di dipendenza negativa l'id viene messo negativo
                                              dip = key_dipende_da_positiva(orig_dip)
                                              (dip_id = map_id[dip]) && ((dip == orig_dip) ? dip_id : -dip_id)
                                            end.compact,
                    competenze:             ia['competenze'],
                    max_retry:              ia['max_retry'] || opts[:max_retry] || 3,
                    expire_sec:             ia['expire_sec'] || opts[:expire_sec] || config[DEFAULT_EXPIRE_ATTIVITA],
                    ambiente:               ambiente,
                    archivio:               archivio,
                    account_id:             ia['account_id'] || account_id,
                    utente_id:              ia['utente_id'] || utente_id,
                    profilo_id:             ia['profilo_id'] || profilo_id,
                    foglie_totali:          ia['foglie_totali']
                  ).id
                rescue => e
                  logger.error("Errore in crea_gerarchia_attivita per l'attività schedulata con id #{id}: #{e}")
                  raise Sequel::Rollback
                end
              end
              break if e
            end
            if e
              begin
                map_id.each do |_k, att_id|
                  Attivita.first(id: att_id).gerarchia_non_corretta!(errore: e.to_s)
                end
              rescue => e1
                logger.error("Errore in cleanup crea_gerarchia_attivita per l'attività schedulata con id #{id}: #{e1}")
              end
            end
          end
        end
        raise e if e
        self
      end

      def aggiorna_dipendenze_info_attivita(tmp_info_attivita) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        ga = {}
        (tmp_info_attivita || []).each do |ia|
          ga[ia['key']] = ia
          ia['label'] ||= (ia['info_comando'] || [])[0] || ia['key']
          ia['dipendenze'] = []
          (ia['dipende_da'] ||= []).each do |orig_dip|
            dip = key_dipende_da_positiva(orig_dip)
            raise "L'info_attivita #{ia['key']} ha una dipendenza #{dip} che non e' definita" unless ga[dip]
            # controllo di coerenza dipendenze (devono avere lo stesso pid)
            # raise "L'info_attivita #{ia['key']} ha una dipendenza #{dip} che non condivide lo stesso pid (#{ia['pid']} != #{ga[dip]['pid']})" if ia['pid'] != ga[dip]['pid']
            ga[dip]['dipendenze'] << ia['key']
          end
          ia['foglie_totali'] = 0
          parent_id = ia['pid']
          # controllo coerenza figli e foglie
          raise "L'info_attivita #{ia['key']} ha un pid #{parent_id} che e' foglia" if parent_id && !ga[parent_id]['info_comando'].to_s.empty?
          next if ia['info_comando'].to_s.empty?
          while parent_id
            ga[parent_id]['foglie_totali'] += 1
            parent_id = ga[parent_id]['pid']
          end
        end
        tmp_info_attivita
      end

      #
      # GENERAZIONE UML/SVG DELLA GERARCHIA
      #
      GA_START = '_start'.freeze
      GA_STOP = '_stop'.freeze

      def gerarchia_attivita # rubocop:disable Metrics/AbcSize
        aggiorna_dipendenze_info_attivita(info_attivita)
        @gerarchia_attivita ||= begin
                                  ga = {}
                                  (info_attivita || []).each { |ia| ga[ia['key']] = ia }
                                  ga[GA_START] = { 'dipende_da' => [], 'dipendenze' => ga.select { |_k, v| v['pid'] && !v['info_comando'].to_s.empty? && v['dipende_da'].empty? }.keys }
                                  ga[GA_STOP] = { 'dipende_da' => ga.select { |_k, v| v['pid'] && v['dipendenze'].empty? && ga[v['pid']]['dipendenze'].empty? }.keys, 'dipendenze' => [] }
                                  ga
                                end
      end

      def _add_to_plantuml_lines(res, new)
        res << new unless res.index(new) && new.include?('-->')
      end

      def to_plantuml(options: PLANTUML_DEFAULT_OPTIONS, title: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        res = ['@startuml', options, title ? "title #{title}" : nil].compact
        barra_sync = {}

        if gerarchia_attivita[GA_START]['dipendenze'].size > 1
          barra_sync[GA_START] = '===START==='
          _add_to_plantuml_lines res, "(*) --> #{barra_sync[GA_START]}"
        end
        if gerarchia_attivita[GA_STOP]['dipende_da'].size > 1
          barra_sync[GA_STOP] = '===STOP==='
          _add_to_plantuml_lines res, "#{barra_sync[GA_STOP]} --> (*)"
        end

        gerarchia_attivita.each do |key, ia|
          next if [GA_START, GA_STOP].include?(key)
          next unless ia['dipende_da'].size > 1 && !ia['info_comando'].to_s.empty?
          container_padre = (ia['pid'] && gerarchia_attivita[ia['pid']]['pid']) ? true : false
          _add_to_plantuml_lines res, "partition #{gerarchia_attivita[ia['pid']]['label']} {" if container_padre
          barra_sync[key] = "===#{ia['dipende_da'].join('_')}==="
          _add_to_plantuml_lines res, "#{barra_sync[key]} --> #{[GA_START, GA_STOP].include?(key) ? '(*)' : "\"#{ia['label']}\""}"
          _add_to_plantuml_lines res, '}' if container_padre
        end

        gerarchia_attivita.each do |key, ia|
          # avoid root processing
          next unless ia['pid'] || [GA_START, GA_STOP].include?(key)

          container_padre = (ia['pid'] && gerarchia_attivita[ia['pid']]['pid']) ? true : false
          # puts "processing #{key} (#{ia.inspect}), container_padre = #{container_padre}, barra_sync = #{barra_sync[key]}"

          _add_to_plantuml_lines res, "partition #{gerarchia_attivita[ia['pid']]['label']} {" if container_padre

          if ia['info_comando'].to_s.empty? && ![GA_START, GA_STOP].include?(key)
            # container
            _add_to_plantuml_lines res, "partition #{ia['label']} {\n}"
            barra_sync[key] = "===#{key}===" unless ia['dipendenze'].empty?
          else
            ia['dipendenze'].each do |dip|
              _add_to_plantuml_lines res, "#{[GA_START, GA_STOP].include?(key) ? (barra_sync[key] || '(*)') : "\"#{ia['label']}\""} --> #{barra_sync[dip] || "\"#{gerarchia_attivita[dip]['label']}\""}"
            end
            if container_padre && barra_sync[ia['pid']] && ia['dipendenze'].empty?
              _add_to_plantuml_lines res, "\"#{ia['label']}\" --> #{barra_sync[ia['pid']]}"
            end
          end
          _add_to_plantuml_lines res, '}' if container_padre
        end

        gerarchia_attivita.each do |key, ia|
          next unless ia['info_comando'].to_s.empty? && ![GA_START, GA_STOP].include?(key) && !ia['dipendenze'].empty?
          container_padre = (ia['pid'] && gerarchia_attivita[ia['pid']]['pid']) ? true : false
          _add_to_plantuml_lines res, "partition #{gerarchia_attivita[ia['pid']]['label']} {" if container_padre
          ia['dipendenze'].each do |dip|
            _add_to_plantuml_lines res, "#{barra_sync[key]} --> #{barra_sync[dip] || "\"#{gerarchia_attivita[dip]['label']}\""}"
          end
          _add_to_plantuml_lines res, '}' if container_padre
        end

        gerarchia_attivita[GA_STOP]['dipende_da'].each do |key|
          _add_to_plantuml_lines res, "\"#{gerarchia_attivita[key]['label']}\" --> #{barra_sync[GA_STOP] || '(*)'}"
        end

        _add_to_plantuml_lines res, '@enduml'
        res.join("\n")
      end

      def to_svg(title: nil, output: nil)
        res = nil
        svg_file = output
        Tempfile.open('attivita_schedulata_to_svg') do |f|
          f.puts(to_plantuml(title: title))
          f.close
          `plantuml.sh #{f.path}`
          res = File.read(svg_file = f.path + '.svg')
        end
        res
      ensure
        FileUtils.rm_f(svg_file) if svg_file && !output
      end

      def directory_attivita(att_id = Time.now.strftime('%Y%m%d%H%M%S'))
        (tipo_attivita_id.nil? || Constant.info(:tipo_attivita, tipo_attivita_id)[:create_dir_attivita]) ? Irma.shared_relative_attivita_dir("#{id}/#{att_id}") : nil
      end
    end
  end
end

# == Schema Information
#
# Tabella: attivita_schedulate
#
#  account_id                 :integer         riferimento a accounts.id
#  ambiente                   :string(10)
#  archivio                   :string(10)
#  competenze                 :json
#  created_at                 :datetime
#  cronologia_stato_operativo :json
#  descr                      :string
#  fine_validita              :datetime
#  id                         :integer         non nullo, default(nextval('attivita_schedulate_id_seq')), chiave primaria
#  inizio_validita            :datetime
#  opts_info_attivita         :json            non nullo
#  periodo                    :string(256)
#  profilo_id                 :integer         riferimento a profili.id
#  stato                      :string(32)      default('attiva')
#  stato_operativo            :string(32)      default('in_attesa')
#  tipo_attivita_id           :integer         non nullo, riferimento a tipi_attivita.id
#  updated_at                 :datetime
#  utente_id                  :integer         riferimento a utenti.id
#
