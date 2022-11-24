# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20190401
#
#

module Irma
  module Db
    #
    class AuditExtraInfo < Hash
      # rubocop:disable Style/GuardClause
      def initialize(account, multipla, sorgente)
        self[:multipla] = multipla
        self[:sorgente] = sorgente
        acc = account.is_a?(Account) ? account : Account.first(id: account || -1)
        if acc
          self[:matricola_utente] = acc.utente.matricola
          self[:nome_utente] = acc.utente.nome
          self[:cognome_utente] = acc.utente.cognome
          self[:profilo] = acc.profilo.nome
        end
      end
    end
    #
    module AuditModelCommon
      attr_accessor :audit_info

      extends_host_with :ClassMethods
      #
      module ClassMethods
        def audit_enabled?
          true
        end

        def with_audit(instance: nil, operazione: AUDIT_META_ENTITA_OPERAZIONE_CREATE,
                       audit_extra_info: nil,
                       attributes: {})
          transaction do
            instance ||= new(attributes)
            instance.setta_audit_info(audit_extra_info)
            case operazione
            when AUDIT_META_ENTITA_OPERAZIONE_CREATE
              instance.save
            when AUDIT_META_ENTITA_OPERAZIONE_UPDATE
              instance.update(attributes)
            when AUDIT_META_ENTITA_OPERAZIONE_DELETE
              instance.destroy
            else
              raise "with_audit invocata con operazione #{operazione} non valida"
            end
          end
        end

        def create_with_audit(audit_extra_info: nil, attributes: {})
          with_audit(audit_extra_info: audit_extra_info, attributes: attributes)
        end
      end

      def update_with_audit(audit_extra_info: nil, attributes: {})
        self.class.with_audit(instance: self, operazione: AUDIT_META_ENTITA_OPERAZIONE_UPDATE, audit_extra_info: audit_extra_info, attributes: attributes)
      end

      def destroy_with_audit(audit_extra_info: nil)
        self.class.with_audit(instance: self, operazione: AUDIT_META_ENTITA_OPERAZIONE_DELETE, audit_extra_info: audit_extra_info)
      end

      def setta_audit_info(audit_extra_info)
        info = audit_extra_info || {}
        @audit_info = if info.is_a?(AuditExtraInfo)
                        info
                      else
                        AuditExtraInfo.new(info[:account_id],
                                           info[:multipla] || false,
                                           info[:sorgente] || AUDIT_SORGENTE_GUI)
                      end
      end

      def delete
        raise "'delete' non consentita per #{self.class} essendo sottoposto ad auding" unless caller_locations.map(&:label).include?('destroy')
        this.delete
      end
    end

    #
    module AuditModule
      extends_host_with :ClassMethods
      #
      module ClassMethods
        def self.cleanup(_hash = {})
          logger.warn("Funzione di cleanup da implementare per la classe #{itself}")
        end
      end

      def latest_for_my_object
        self.class.where(latest: true).where(where_condition_same_object).first
      end

      def before_update
        raise "Aggiornamento #{self.class} non consentito per policy di sicurezza" unless changed_columns.empty? || changed_columns == [:latest]
      end

      def before_create
        lt = latest_for_my_object
        if lt
          lt.update(latest: false)
          self.pid = lt.id
        end
        self.latest = true
        super
      end
    end
  end
end
