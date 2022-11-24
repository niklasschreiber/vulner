# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20160129
#

require 'aasm'

module Irma
  module Db
    #
    class Account < Model(:accounts) # rubocop:disable Metrics/ClassLength
      include AASM

      plugin :timestamps, update_on_create: true
      validates_constant :stato

      many_to_one :utente,  class: full_class_for_model(:Utente)
      many_to_one :profilo, class: full_class_for_model(:Profilo)

      config.define AUTENTICAZIONE = :autenticazione, AUTENTICAZIONE_AUTO, ambito: APP_CONFIG_AMBITO_INTERNO

      config.define PERIODO_CONTROLLO_SESSIONE = :periodo_controllo_sessione, 60,
                    descr:         'Secondi fra un controllo e il successivo effettuato dal client della gui per la verifica della validità della sessione',
                    widget_info:   'Gui.widget.positiveInteger({minValue:5, maxValue:900})'

      config.define NUMERO_MASSIMO_TENTATIVI_ACCESSO = :numero_massimo_tentativi_accesso, 4,
                    descr:         "Numero massimo di tentativi falliti consecutivi prima che l'account di un utente venga sospeso",
                    widget_info:   'Gui.widget.positiveInteger({minValue:3, maxValue:100})'

      config.define NUMERO_MASSIMO_DI_GIORNI_SENZA_LOGIN = :numero_massimo_di_giorni_senza_login, 180,
                    descr:         "Numero massimo di giorni entro i quali deve essere effettuato almeno un login per evitare che l'utente venga sospeso",
                    widget_info:   'Gui.widget.positiveInteger({minValue:1, maxValue:1000})'

      config.define CONSENTI_LOGIN_MULTIPLO = :consenti_login_multiplo, 0,
                    descr:         "Flag per consentire l'accesso allo stesso utente da host diversi (dovrebbe essere normalmente impostato a 0)",
                    widget_info:   'Gui.widget.booleanInteger()'

      class ValoreNonValido < IrmaException; end
      class ProfiloNonValido < IrmaException; end

      def before_create
        self.data_ultima_attivazione = Time.now if stato == ACCOUNT_STATO_ATTIVO
        super
      end

      def after_update
        # unless ( (changed_columns & [:profilo_id, :data_scadenza]).empty? )
        #  notifica(EMAIL_TEMPLATE_ACCOUNT_MODIFICATO,stato)
        # end
        super
      end

      def self.qualsiasi(profilo: PROFILO_RPN)
        ret = nil
        p = Profilo.find(id: profilo.to_i) || Profilo.find(nome: profilo.to_s)
        return ret unless p
        where(profilo_id: p.id, stato: ACCOUNT_STATO_ATTIVO).order(:id).each do |aaa|
          return aaa if (aaa.competenze['sistema'] || {}) == COMPETENZA_SU_TUTTI_I_SISTEMI
        end
        ret
      end

      def self.find_by_matricola(matricola)
        where(utente_id: Utente.where(matricola: matricola.upcase).select(:id)).all
      end

      def self.last_used(matricola:, profilo: nil, stato: ACCOUNT_STATO_ATTIVO)
        cond = { stato: stato, utente_id: Utente.where(matricola: matricola.upcase).select(:id) }
        if profilo
          p = Profilo.find(id: profilo.to_i) || Profilo.find(nome: profilo.to_s)
          cond[:profilo_id] = p.id if p
        end
        where(cond).order(Sequel.desc(:data_ultimo_login, nulls: :last)).first
      end

      def notifica(_tpl, nuovo_stato)
        utente = Utente.where(id: utente_id).first
        Allarme.valuta(TIPO_ALLARME_UTENTE_SOSPESO,
                       matricola: utente.matricola,
                       user_name: utente.matricola,
                       user_fullname: utente.fullname,
                       descr: descr
                      ) do
                        nuovo_stato == ACCOUNT_STATO_SOSPESO
                      end
      end

      aasm column: :stato, enum: true do
        state :attivo, initial: true
        state :sospeso
        state :disattivo

        event :attiva do
          before do
            if stato != ACCOUNT_STATO_ATTIVO
              self.num_tentativi_accesso_falliti = 0
              self.descr = ''
              self.data_ultima_attivazione = Time.now
              notifica(EMAIL_TEMPLATE_ACCOUNT_ATTIVATO, ACCOUNT_STATO_ATTIVO)
            end
          end
          transitions from: :sospeso, to: :attivo
        end

        event :sospendi do
          before do
            if stato != ACCOUNT_STATO_SOSPESO
              self.data_ultima_sospensione = Time.now
              notifica(EMAIL_TEMPLATE_ACCOUNT_SOSPESO, ACCOUNT_STATO_SOSPESO)
            end
          end
          transitions from: :attivo, to: :sospeso
        end

        event :disattiva do
          before do
            chiudi_allarmi_aperti('Account disattivato')
            self.data_ultima_disattivazione = Time.now
            notifica(EMAIL_TEMPLATE_ACCOUNT_DISATTIVATO, ACCOUNT_STATO_DISATTIVO)
          end
          transitions from: [:attivo, :sospeso], to: :disattivo
        end
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def self.define(matricola, profilo, options = {})
        matricola = matricola.upcase
        user = Utente.find(matricola: matricola)
        profile = Profilo.find((profilo.to_i.to_s == profilo.to_s ? :id : :nome) => profilo) unless profile.is_a?(Profilo)
        raise ProfiloNonValido unless profile
        account_attributes = options.dup
        account_attributes[:stato] ||= ACCOUNT_STATO_ATTIVO
        transaction do
          account = nil
          account = find(utente_id: user.id, profilo_id: profile.id) if user && profile
          utente = user || Utente.new(matricola: matricola)
          utente_attributes = {}
          Utente.columns.each { |k| utente_attributes[k] = options[k] if k.to_s != 'id' && options[k] }
          utente.update(utente_attributes)
          unless account
            account_attributes[:profilo_id] = profile.id
            account_attributes[:data_ultima_attivazione] = Time.now if account_attributes[:stato] == ACCOUNT_STATO_ATTIVO
            account = new
          end
          account.utente = utente
          account_attributes.each { |k, v| account[k] = v if columns.include?(k.to_sym) }
          account.aggiorna_competenze(account_attributes[:competenze] || account_attributes['competenze'])
          account.notifica(EMAIL_TEMPLATE_ACCOUNT_ATTIVATO, ACCOUNT_STATO_ATTIVO) if account_attributes[:data_ultima_attivazione]
          account.save
          account
        end
      end

      # COMPETENZE
      # Imposta a +v+ le competenze dell'account effettuando la conversione in JSON
      def competenze=(v)
        pd = nil
        begin
          cpt = controlla_competenze_con_profilo(v || {})
          json_value = cpt.to_json
          pd = cpt
        rescue => e
          raise ValoreNonValido, "Account #{id} con competenze non valide: |#{v}| (#{e})"
        end
        super(json_value)
        pd
      end

      # Ritorna il permessi di default del profilo, decodificando il permessi memorizzato realmente nel DB in formato JSON
      def competenze
        v = super
        v = '{}' if v.to_s.empty?
        begin
          controlla_competenze_con_profilo(JSON.parse(v))
        rescue => e
          raise ValoreNonValido, "Account #{id}, attributo competenze non valido: |#{v}| (#{e})"
        end
      end

      def aggiorna_competenze(vvv)
        update(competenze: vvv)
        self
      end

      def aggiorna_sistemi_nelle_competenze
        comp = competenze
        sistemi = (comp && comp['sistema'] && comp['sistema']['sistemi']) || []
        omc_fisici = (comp && comp['sistema'] && comp['sistema']['omc_fisici']) || []
        return self if sistemi.empty? || sistemi == COMPETENZA_TUTTO
        sistemi &= Sistema.select_map(:id)
        comp['sistema']['sistemi'] = sistemi
        unless omc_fisici.empty? || omc_fisici == COMPETENZA_TUTTO
          omc_fisici &= Sistema.where(id: sistemi).select_map(:omc_fisico_id)
          comp['sistema']['omc_fisici'] = omc_fisici
        end
        aggiorna_competenze(comp)
      end

      def controlla_competenze_con_profilo(cpt)
        profilo = Profilo.get_by_pk(profilo_id)
        competenze_profilo = profilo.tipi_competenze
        competenze_profilo.each do |x|
          cpt[x] = {} unless cpt[x]
        end
        cpt.keys.each do |x|
          cpt.delete(x) unless competenze_profilo.member?(x)
        end
        cpt
      end

      def descr_competenze
        pieces = []
        competenze.each do |k, v|
          pieces << "#{k}: #{competenza_to_s(v)}"
        end
        pieces.join("\n")
      end

      def filtro_competenze
        res = {}
        competenze.each do |k, v|
          xx = ((v && !v.empty?) ? "(#{k} in ('#{v.join("'")}'))" : "(#{k} is NULL)")
          res[k] = (v == COMPETENZA_TUTTO || v == [COMPETENZA_TUTTO]) ? nil : xx
        end
        res
      end

      def valori_competenza(force: false)
        @valori_competenza = nil if force
        unless @valori_competenza
          temp_res = { vendors: [], reti: [], omc_fisici: [], sistemi: [], vendor_releases: [] }
          sistemi_di_competenza(force: force).each do |id|
            s = Sistema.get_by_pk(id)
            temp_res[:sistemi] << { id: s.id, descr: s.descr, omc_logico: s.descr, rete: s.rete.nome, rete_id: s.rete_id,
                                    vendor: s.vendor.nome, vendor_id: s.vendor.id, vendor_release_id: s.vendor_release_id, vendor_release: s.vendor_release.descr, full_descr: s.full_descr,
                                    omc_fisico_id: s.omc_fisico_id, omc_fisico: s.omc_fisico.nome, nome_file_audit: s.nome_file_audit }
            temp_res[:reti] << { id: s.rete_id, nome: s.rete.nome }
            temp_res[:vendors] << { id: s.vendor.id, nome: s.vendor.nome }
            temp_res[:vendor_releases] << { id: s.vendor_release_id, descr: s.vendor_release.descr, rete_id: s.vendor_release.rete_id, full_descr: s.vendor_release.full_descr }
          end
          temp_res[:omc_fisici] = omc_fisici_di_competenza(force: force).map do |of_id|
            o = OmcFisico.get_by_pk(of_id)
            { id: o.id, nome: o.nome, full_descr: o.full_descr, vendor_release_id: o.vendor_release_fisico_id, nome_file_audit: o.nome_file_audit }
          end
          res = {}
          temp_res.each do |k, v|
            res[k] = v.sort_by { |x| x[:id] }.uniq
          end
          @valori_competenza = res
        end
        @valori_competenza
      end

      def sistemi_di_competenza(force: false)
        @sistemi_di_competenza = nil if force
        @sistemi_di_competenza ||= if (c = competenze['sistema'])
                                     # { 'sistema' => { vendors: comp_vendor, reti: comp_rete, omc_fisici: comp_omc_fisico, sistemi: comp_sistema } }
                                     filtro = {}
                                     filtro[Sequel.qualify(:vendor_releases, :vendor_id)] = c['vendors'] if c['vendors'] && c['vendors'] != COMPETENZA_TUTTO
                                     filtro[Sequel.qualify(:sistemi, :omc_fisico_id)] = c['omc_fisici'] if c['omc_fisici'] && c['omc_fisici'] != COMPETENZA_TUTTO
                                     filtro[Sequel.qualify(:sistemi, :rete_id)] = c['reti'] if c['reti'] && c['reti'] != COMPETENZA_TUTTO
                                     filtro[Sequel.qualify(:sistemi, :id)] = c['sistemi'] if c['reti'] && c['sistemi'] != COMPETENZA_TUTTO
                                     Sistema.join(VendorRelease.table_name, id: :vendor_release_id).where(filtro).select_map(Sequel.qualify(:sistemi, :id))
                                   else
                                     []
                                   end
      end

      def omc_fisici_di_competenza(force: false)
        @omc_fisici_di_competenza = nil if force
        @omc_fisici_di_competenza ||= sistemi_di_competenza(force: force).map { |s_id| Sistema.get_by_pk(s_id).omc_fisico_id }.uniq
      end

      def vendor_releases_di_competenza(force: false)
        @vendor_releases_di_competenza = nil if force
        @vendor_releases_di_competenza ||= sistemi_di_competenza(force: force).map { |s_id| Sistema.get_by_pk(s_id).vendor_release_id }.uniq
      end

      def nuovo_accesso_fallito(max_fallimenti: nil)
        max_fallimenti ||= config[NUMERO_MASSIMO_TENTATIVI_ACCESSO]
        self.num_tentativi_accesso_falliti ||= 0
        self.num_tentativi_accesso_falliti += 1
        if self.num_tentativi_accesso_falliti >= max_fallimenti
          self.descr = format_msg(:ACCOUNT_BLOCCATO_PER_MAX_ACCESSI_FALLITI, matricola: utente.matricola, profilo: profilo.nome, max_fallimenti: max_fallimenti)
          sospendi
        else
          save
        end
        self
      end

      def verifica_data_scadenza
        if data_scadenza && data_scadenza < Time.now
          self.descr = format_msg(:ACCOUNT_SOSPESO_PER_SCADENZA, matricola: utente.matricola, profilo: profilo.nome, data_scadenza: Irma.format_date(data_scadenza))
          sospendi
        end
        self
      end

      def login
        self.data_ultimo_login = Time.now
        self.num_tentativi_accesso_falliti = 0
        save
        self
      end

      def ambiente
        @ambiente ||= profilo.ambiente
      end

      def full_descr
        @full_descr ||= "#{utente.matricola}, #{profilo.nome} (#{id})"
      end

      def audit_descr
        [
          "utente=#{utente.matricola}",
          "profilo=#{profilo.nome}",
          # "stato=#{self.class.get_constant_label(:stato, stato)}",
          "stato=#{stato}",
          "num_accessi_falliti=#{num_tentativi_accesso_falliti}",
          "data_ultimo_login=#{data_ultimo_login ? data_ultimo_login.strftime(config[GUI_DEFAULT_DATE_FORMAT]) : ''}"
        ].join(', ')
      end

      def chiudi_allarmi_aperti(note_chiusura = 'Account eliminato dal DB')
        # Allarme.all(user_name: utente.matricola, profilo_id: profilo_id).each { |al| al.chiudi(note_chiusura) }
        Allarme.where(user_name: utente.matricola).each { |al| al.chiudi(note_chiusura) }
      end

      def scaduto?
        (data_scadenza && data_scadenza < Time.now) ? true : false
      end

      def inattivo?
        data_minima = Time.now - config[NUMERO_MASSIMO_DI_GIORNI_SENZA_LOGIN] * 86_400
        data_ultimo_login ? (data_ultimo_login <= data_minima) : (updated_at <= data_minima)
      end

      def max_fallimenti_superati?
        num_tentativi_accesso_falliti >= config[NUMERO_MASSIMO_TENTATIVI_ACCESSO]
      end

      def self.sospensione_account_scaduti(_opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        # options = {}.merge(_opts)
        res = { account_sospesi: [] }
        where(stato: ACCOUNT_STATO_ATTIVO).where('data_scadenza is not null and data_scadenza <= ?', Time.now).each do |acc|
          acc.sospendi
          acc.descr = format_msg(:ACCOUNT_SOSPESO_PER_SCADENZA, matricola: acc.utente.matricola, profilo: acc.profilo.nome, data_scadenza: Irma.format_date(acc.data_scadenza))
          acc.save
          res[:account_sospesi] << acc.utente.matricola
        end
        data_minima_login = Time.now - config[NUMERO_MASSIMO_DI_GIORNI_SENZA_LOGIN] * 86_400
        where(stato: ACCOUNT_STATO_ATTIVO).where('data_ultimo_login <= ? or (data_ultimo_login is null and updated_at <= ?)', data_minima_login, data_minima_login).each do |acc|
          acc.sospendi
          acc.descr = format_msg(:ACCOUNT_SOSPESO_PER_INATTIVITA, matricola: acc.utente.matricola, profilo: acc.profilo.nome, max_giorni_senza_login: config[NUMERO_MASSIMO_DI_GIORNI_SENZA_LOGIN])
          acc.save
          res[:account_sospesi] << acc.utente.matricola
        end
        res[:account_sospesi].sort!
        res
      end

      def self.controllo_utenti(_hash = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        res = { processati: 0, verificati: 0, non_verificati: {}, scaduti: [], non_trovati: [] }
        accounts = where(stato: ACCOUNT_STATO_ATTIVO).all
        accounts.each do |acc|
          res[:processati] += 1
          if acc.attivo?
            acc.verifica_data_scadenza
            res[:scaduti] << acc.utente.matricola if acc.sospeso?
          end
        end
        accounts.each_with_index do |acc, idx|
          begin
            acc.utente.update(Utente.ldap_info(acc.utente.matricola))
            res[:verificati] += 1
          rescue DsTi::InvalidUid => _e
            res[:non_trovati] << acc.utente.matricola
            acc.descr = format_msg(:ACCOUNT_SOSPESO_PER_ASSENZA_DA_LDAP, matricola: acc.utente.matricola, profilo: acc.profilo.nome)
            acc.sospendi
            acc.save
          rescue DsTi::ConnectionFailure => e
            res[:non_verificati][e.to_s] = "#{accounts.count - idx} accounts non verificati"
            break
          rescue => e
            (res[:non_verificati][e.to_s] ||= []) << acc.utente.matricola
          end
        end
        logger.warn("Non è stato possibile verificare le informazioni di tutti gli utenti (#{res[:non_verificati].inspect})") unless res[:non_verificati].empty?
        res
      end

      #
      class AuthenticateResult
        attr_accessor :session, :account
        attr_reader   :msg

        def initialize(**opts)
          @session = opts[:session]
          @account = opts[:account]
          @msg     = opts[:msg]
        end

        def aggiorna_msg(v)
          @msg = v
          self
        end

        def ok?
          (account && session && session.account_id && (account.id == session.account_id)) ? true : false
        end
      end

      def self.autenticazione(matricola:, password:, request_host:, **opts)
        matricola = matricola.upcase
        session = opts[:session]
        raise "Invalid session #{opts[:session].inspect}" unless session.is_a?(Sessione) || (session = Sessione.find(session_id: session))
        raise "Invalid session #{session.session_id} (already used)" if session.account_id
        res = AuthenticateResult.new(session: session)
        event_params = (opts[:event_params] || {}).dup

        account = res.account = last_used(matricola: matricola, profilo: opts[:profilo])
        unless res.account
          account_sospeso = last_used(matricola: matricola, profilo: opts[:profilo], stato: ACCOUNT_STATO_SOSPESO)
          return res.aggiorna_msg(format_msg(:ACCOUNT_CREDENZIALI_NON_VALIDE)) unless account_sospeso
          account_info = { matricola: matricola, profilo: account_sospeso.profilo.nome, stato: account_sospeso.stato }
          return res.aggiorna_msg(format_msg(:ACCOUNT_IN_STATO_SOSPESO_PER_SCADENZA, account_info)) if account_sospeso.scaduto?
          return res.aggiorna_msg(format_msg(:ACCOUNT_IN_STATO_SOSPESO_PER_INATTIVITA, account_info)) if account_sospeso.inattivo?
          return res.aggiorna_msg(format_msg(:ACCOUNT_IN_STATO_SOSPESO_PER_MAX_FALLIMENTI, account_info)) if account_sospeso.max_fallimenti_superati?
          return res.aggiorna_msg(format_msg(:ACCOUNT_IN_STATO_NON_ATTIVO, account_info))
        end

        account_info = { matricola: matricola, profilo: account.profilo.nome, stato: account.stato }
        if config[CONSENTI_LOGIN_MULTIPLO].to_i.zero?
          sess = Sessione.find(account_id: account.id)
          if sess && sess.host != request_host
            return AuthenticateResult.new(account: account,
                                          msg: format_msg(:ACCOUNT_GIA_CONNESSO_DA_ALTRO_HOST, account_info.merge(host: sess.host, data_inizio_sessione: Irma.format_date(sess.created_at))))
          end
        end
        event_params.update(account_id: account.id, matricola: matricola, utente_descr: account.utente.fullname, profilo: account.profilo.nome, ambiente: account.ambiente)

        ok = false
        if config[AUTENTICAZIONE] == AUTENTICAZIONE_AUTO
          ok = matricola.casecmp(password).zero?
        else
          begin
            Ds_ti.authenticate(matricola, password)
            ok = true
          rescue DsTi::ConnectionFailure => e
            Evento.crea(TIPO_EVENTO_AUTENTICAZIONE_FALLITA, event_params.merge(descr: "Autenticazione fallita per l'utente con matricola #{matricola} (connessione all'LDAP fallita)"))
            return res.aggiorna_msg(format_msg(:ACCOUNT_CREDENZIALI_NON_VERIFICABILI, errore: e.to_s))
          rescue DsTi::DsTiError
            ok = false
          end
        end

        unless ok
          Evento.crea(TIPO_EVENTO_AUTENTICAZIONE_FALLITA, event_params.merge(descr: "Autenticazione fallita per l'utente con matricola #{matricola} (password errata)"))
          account.nuovo_accesso_fallito
          return res.aggiorna_msg(account.attivo? ? format_msg(:ACCOUNT_CREDENZIALI_NON_VALIDE) : account.descr)
        end

        session.login_ok(event_params.merge(host: request_host, data: account.data_per_sessione))

        account.login
        Evento.crea(TIPO_EVENTO_AUTENTICAZIONE_CORRETTA, event_params.merge(descr: "Autenticazione corretta per l'utente con matricola #{matricola}"))
        res
      end

      def preferenze_per_sessione(force: false)
        (preferenze || {}).merge(
          filtro_sistemi:                         filtro_sistemi(force: force),
          funzioni_selezionate:                   funzioni_selezionate(force: force),
          sistemi_di_competenza_filtrati:         sistemi_di_competenza_filtrati(force: force),
          sistema_unico:                          sistema_unico,
          omc_fisici_di_competenza_filtrati:      omc_fisici_di_competenza_filtrati(reset: true),
          omc_fisico_unico:                       omc_fisico_unico,
          vendor_releases_di_competenza_filtrati: vendor_releases_di_competenza_filtrati(reset: true),
          vendor_release_unica:                   vendor_release_unica,
          vendor_release_fisico_unica:            vendor_release_fisico_unica,
          sistemi_tutti:                          sistemi_tutti,
          omc_fisici_tutti:                       omc_fisici_tutti,
          vendor_releases_tutte:                  vendor_releases_tutte
        )
      end

      def data_per_sessione(force: false)
        {
          competenze:                             competenze,
          sistemi_di_competenza:                  sistemi_di_competenza,
          omc_fisici_di_competenza:               omc_fisici_di_competenza,
          vendor_releases_di_competenza:          vendor_releases_di_competenza,
          preferenze:                             preferenze_per_sessione(force: force),
          valori_competenza:                      valori_competenza(force: force),
          id_profilo_corrente:                    profilo_id,
          altri_profili:                          Account.where(stato: ACCOUNT_STATO_ATTIVO, utente_id: utente_id).select_map(:profilo_id)
                                                         .map { |p| (p == profilo_id) ? nil : [p, Profilo.get_by_pk(p).nome] }.compact.sort_by { |x| x[1] },
          funzioni_abilitate:                     profilo.funzioni
        }
      end

      def sistemi_tutti
        res = false
        num_sistemi_totali = Sistema.count
        if valori_competenza && valori_competenza[:sistemi] && sistemi_di_competenza_filtrati && (sistemi_di_competenza_filtrati.size == num_sistemi_totali)
          res = true
        end
        res
      end

      def omc_fisici_tutti
        res = false
        num_omcfisici_totali = OmcFisico.count
        if valori_competenza && valori_competenza[:omc_fisici] && omc_fisici_di_competenza_filtrati && (omc_fisici_di_competenza_filtrati.size == num_omcfisici_totali)
          res = true
        end
        res
      end

      def vendor_releases_tutte
        res = false
        num_vendorreleases_totali = VendorRelease.count
        if valori_competenza && valori_competenza[:sistemi] && sistemi_di_competenza_filtrati && (sistemi_di_competenza_filtrati.size >= 1)
          vrs = valori_competenza[:sistemi].map { |s| sistemi_di_competenza_filtrati.include?(s[:id]) ? s[:vendor_release_id] : nil }.uniq.compact
          res = true if vrs.size == num_vendorreleases_totali
        end
        res
      end

      def sistema_unico
        res = nil
        if valori_competenza && valori_competenza[:sistemi] && sistemi_di_competenza_filtrati && (sistemi_di_competenza_filtrati.size == 1)
          sistema_id = sistemi_di_competenza_filtrati.first
          res = valori_competenza[:sistemi].find { |s| s[:id] == sistema_id }
        end
        res
      end

      def omc_fisico_unico
        res = nil
        if valori_competenza && valori_competenza[:omc_fisici] && omc_fisici_di_competenza_filtrati && (omc_fisici_di_competenza_filtrati.size == 1)
          omc_fisico_id = omc_fisici_di_competenza_filtrati.first
          res = valori_competenza[:omc_fisici].find { |s| s[:id] == omc_fisico_id }
        end
        res
      end

      def vendor_release_unica
        res = nil
        if valori_competenza && valori_competenza[:sistemi] && sistemi_di_competenza_filtrati && (sistemi_di_competenza_filtrati.size >= 1)
          vrs = valori_competenza[:sistemi].map { |s| sistemi_di_competenza_filtrati.include?(s[:id]) ? s[:vendor_release_id] : nil }.uniq.compact
          if vrs.size == 1
            vr = VendorRelease.get_by_pk(vrs.first)
            res = vr.attributes.merge(full_descr: vr.full_descr)
          end
        end
        res
      end

      def vendor_release_fisico_unica
        res = nil
        if valori_competenza && valori_competenza[:omc_fisici] && omc_fisici_di_competenza_filtrati && (omc_fisici_di_competenza_filtrati.size >= 1)
          vrs = valori_competenza[:omc_fisici].map { |s| omc_fisici_di_competenza_filtrati.include?(s[:id]) ? s[:vendor_release_id] : nil }.uniq.compact
          if vrs.size == 1
            vr = VendorReleaseFisico.get_by_pk(vrs.first)
            res = vr.attributes.merge(full_descr: vr.full_descr)
          end
        end
        res
      end

      def funzioni_selezionate(force: false)
        @funzioni_selezionate = nil if force
        @funzioni_selezionate ||= (preferenze || {})['funzioni_selezionate']
        @funzioni_selezionate ||= { 'lista' => [], 'attiva' => nil }
      end

      def filtro_sistemi(force: false)
        @filtro_sistemi = nil if force
        @filtro_sistemi ||= (preferenze || {})['filtro_sistemi']
        unless @filtro_sistemi
          @filtro_sistemi = {}
          valori_competenza(force: force).each do |k, v|
            @filtro_sistemi[k] = v.map { |x| x[:id] }
          end
        end
        @filtro_sistemi
      end

      def sistemi_di_competenza_filtrati(force: false)
        @sistemi_di_competenza_filtrati = nil if force
        @sistemi_di_competenza_filtrati ||= sistemi_di_competenza.map do |id|
          s = Sistema.get_by_pk(id)
          ok = true
          fs = filtro_sistemi(force: force)
          [%w(vendors vendor_id), %w(reti rete_id), %w(omc_fisici omc_fisico_id), %w(sistemi id)].each do |k, m|
            if fs[k]
              ok = false unless fs[k].include?(s.send(m))
              break unless ok
            end
          end
          ok ? id : nil
        end.compact
      end

      def omc_fisici_di_competenza_filtrati(force: false, reset: false)
        @omc_fisici_di_competenza_filtrati = nil if force || reset
        @omc_fisici_di_competenza_filtrati ||= sistemi_di_competenza_filtrati(force: force).map { |s_id| Sistema.get_by_pk(s_id).omc_fisico_id }.uniq
      end

      def vendor_releases_di_competenza_filtrati(force: false, reset: false)
        @vendor_releases_di_competenza_filtrati = nil if force || reset
        @vendor_releases_di_competenza_filtrati ||= sistemi_di_competenza_filtrati(force: force).map { |s_id| Sistema.get_by_pk(s_id).vendor_release_id }.uniq
      end
    end
  end
end

# == Schema Information
#
# Tabella: accounts
#
#  competenze                    :string
#  created_at                    :datetime
#  data_scadenza                 :datetime
#  data_ultima_attivazione       :datetime
#  data_ultima_disattivazione    :datetime
#  data_ultima_sospensione       :datetime
#  data_ultimo_login             :datetime
#  descr                         :string(255)
#  id                            :integer         non nullo, default(nextval('accounts_id_seq')), chiave primaria
#  num_tentativi_accesso_falliti :integer         non nullo, default(0)
#  preferenze                    :json
#  profilo_id                    :integer         riferimento a profili.id
#  stato                         :string(20)      non nullo
#  updated_at                    :datetime
#  utente_id                     :integer         riferimento a utenti.id
#
# Indici:
#
#  uidx_accounts_utente_profilo  (profilo_id,utente_id) UNIQUE
#
