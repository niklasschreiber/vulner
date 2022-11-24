# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160223
#

# rubocop:disable Metrics/LineLength
module Irma
  #
  module Db
    #
    module SaaUtil
      extends_host_with :ClassMethods
      #
      module ClassMethods
      end

      attr_accessor :pi, :ambiente, :archivio, :account, :rc

      def sistema_id
        @sistema_id ||= sistema.id
      end

      def vendor_id
        @vendor_id ||= sistema.vendor_id
      end

      def account_id
        @account_id ||= account.id if account
        @account_id
      end

      def con_lock(opts = {}, &block) # rubocop:disable Metrics/AbcSize
        if archivio == ARCHIVIO_ECCEZIONI
          entita(logger: opts[:logger]).con_lock(opts) do |_lock|
            entita_label(logger: opts[:logger]).con_lock(opts, &block)
          end
        else
          (opts[:use_pi] && pi) ? pi.entita(logger: opts[:logger]).con_lock(opts, &block) : entita(logger: opts[:logger]).con_lock(opts, &block)
        end
      end

      def db
        entita.db
      end

      def dataset(logger: nil, use_pi: false)
        @dataset = (use_pi && pi) ? pi.entita(logger: logger).dataset : entita(logger: logger).dataset
      end

      def con_loader_entita(opts = {}, &block)
        raise 'Richiesto loader per entita ProgettoIrma, con ProgettoIrma non valido' if opts[:use_pi] && pi.nil?
        if opts[:use_pi]
          pi.entita(logger: opts[:logger]).con_loader(opts, &block)
        else
          entita(logger: opts[:logger]).con_loader(opts, &block)
        end
      end

      def vendor_instance(opts = {})
        @vendor_instance ||= Irma::Vendor.instance(vendor: vendor_id, rete: rete_id, **opts)
      end

      def filtro_segnalazioni
        { db_fk => sistema.id, :ambiente => ambiente, :archivio => archivio, :progetto_irma_id => (pi ? pi.id : nil) }
      end

      def crea_progetto_irma(nome:, account_id:, **opts) # rubocop:disable Metrics/AbcSize
        param_input = opts[:parametri_input] || {
          'tipo_sorgente' => opts[:omc_fisico] ? 1 : 0,
          'sorgente' => entita.table_name,
          'per_omcfisico' =>  opts[:omc_fisico] ? sistema.id : nil,
          'descr_sorgente' => "Archivio Rete Omc #{opts[:omc_fisico] ? 'Fisico' : 'Logico'} #{sistema.descr}"
        }
        Db::ProgettoIrma.create(:nome => nome, :account_id => account_id, :ambiente => ambiente, :archivio => archivio, db_fk => sistema.id,
                                :parametri_input => param_input)
      end

      def crea_o_associa_progetto_irma(nome:, **opts)
        acc_id = account_id ? account_id : opts[:account_id]
        self.pi = Db::ProgettoIrma.first(nome: nome, account_id: acc_id)
        self.pi ||= crea_progetto_irma(nome: nome, account_id: acc_id, **opts)
      end

      def associa_progetto_irma(nome:, **opts)
        acc_id = account_id ? account_id : opts[:account_id]
        self.pi = Db::ProgettoIrma.first(nome: nome, account_id: acc_id)
      end

      def con_loader_entita_rc(opts = {}, &block)
        raise 'Richiesto loader per entita ReportComparativo, con ReportComparativo non valido' if rc.nil?
        rc.entita(logger: opts[:logger]).con_loader({ constraint_sleep: 1 }.merge(opts), &block)
      end

      def con_loader_entita_pi(opts = {}, &block)
        raise 'Richiesto loader per entita ProgettoIrma, con ProgettoIrma non valido' if pi.nil?
        pi.entita(logger: opts[:logger]).con_loader(opts, &block)
      end

      def aggiorna_contatore_entita(use_pi: false)
        pi.update(count_entita: pi.entita.dataset.count) if use_pi && pi
      end

      def db_fk
        :sistema_id
      end

      def crea_report_comparativo(nome:, account_id:, fonte_1:, fonte_2:, info: nil)
        self.rc = Db::ReportComparativo.create(nome: nome, account_id: account_id,
                                               ambiente: ambiente, db_fk => sistema.id,
                                               archivio_1: fonte_1.to_json, archivio_2: fonte_2.to_json,
                                               info: (info || {}).to_json)
      end

      def associa_report_comparativo(nome:, **opts)
        acc_id = account_id ? account_id : opts[:account_id]
        self.rc = Db::ReportComparativo.first(nome: nome, account_id: acc_id)
      end
    end

    #
    class SistemaAmbienteArchivio
      include SaaUtil
      attr_reader :sistema

      def initialize(sistema:, archivio:, ambiente: nil, account: nil, check_competenza: true) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        @sistema = sistema.is_a?(Sistema) ? sistema : Sistema.get_by_pk(sistema)

        begin
          @archivio = Constant.value(:archivio, archivio)
        rescue
          raise ArgumentError, "Archivio '#{archivio}' non valido"
        end

        @account = (account.is_a?(Account) ? account : Account.first(id: account)) if account

        raise ArgumentError, "Account '#{account}' non valido" if account && !@account

        # Verifica se l'ambiente e' coerente con quello dell'account
        if @account
          raise ArgumentError, "Ambiente '#{ambiente}' non coerente con quello associato all'account con id #{@account.id}" if ambiente && (ambiente != @account.profilo.ambiente)

          # Verifica se il sistema e' nelle competenze dell'account
          if check_competenza && !@account.sistemi_di_competenza.include?(@sistema.id)
            raise "Il sistema '#{@sistema.id}' non è di competenza dell'account #{@account.id}"
          end

          ambiente ||= @account.ambiente
        end

        begin
          @ambiente = Constant.value(:ambiente, ambiente)
        rescue
          raise ArgumentError, "Ambiente '#{ambiente}' non valido"
        end
      end

      def import_cache_prefix(hash = {})
        @import_cache_prefix ||= "import_#{@ambiente}_#{@archivio}_#{hash[:vendor]}_#{hash[:rete]}_#{hash[:omc_logico]}_"
      end

      def full_descr
        ["sistema=#{sistema.full_descr}", "ambiente=#{ambiente}", pi ? "progetto_irma=#{pi.nome}" : "archivio=#{archivio}"].compact.join(', ')
      end

      def rete_id
        @rete_id ||= sistema.rete_id
      end

      def vendor_release
        sistema.vendor_release
      end

      def rete
        Db::Rete.get_by_pk(rete_id)
      end

      def entita(logger: nil)
        @entita ||= if archivio == ARCHIVIO_ECCEZIONI
                      entita_eccezione
                    else
                      Entita.new(omc_logico_id: sistema.id, omc_logico: sistema.descr, ambiente: ambiente, archivio: archivio, vendor: vendor_id, rete: rete_id, logger: logger)
                    end
      end

      def entita_eccezione(logger: nil)
        @entita_eccezione ||= EntitaEccezione.new(omc_logico_id: sistema.id, omc_logico: sistema.descr, archivio: ARCHIVIO_ECCEZIONI, vendor: vendor_id, rete: rete_id, logger: logger)
      end

      def entita_label(logger: nil)
        @entita_label ||= EntitaLabel.new(omc_logico_id: sistema.id, omc_logico: sistema.descr, archivio: ARCHIVIO_LABEL, vendor: vendor_id, rete: rete_id, logger: logger)
      end

      def formati_audit
        vendor_release.formati_audit.keys
      end

      def formato_audit_info(formato_audit)
        vendor_release.formati_audit[formato_audit]
      end

      def carica_nodi_esterni(opts = {}) # rubocop:disable Metrics/AbcSize
        res = {}
        Irma.esegui_e_memorizza_durata(logger: opts[:logger], log_prefix: "#{opts[:log_prefix]}, caricamento cache nodi esterni") do
          stat = { sistemi: 0, nodi: 0 }
          Db::Sistema.where("id != #{sistema_id}").each do |s|
            stat[:sistemi] += 1
            # fisso la ricerca dei nodi su ARCHIVIO_RETE, che sara' sicuramente popolato
            Db::SistemaAmbienteArchivio.new(sistema: s, ambiente: ambiente, archivio: ARCHIVIO_RETE).dataset.where(nodo: true).select(:dist_name).each do |eee|
              res[eee[:dist_name]] = { riferimento_sistema: "Omc Logico: #{s.descr}, rete: #{Db::Rete.get_by_pk(s.rete_id).nome}" }
            end
          end
          stat[:nodi] = res.size
          stat
        end
        res
      end
    end

    #
    class OmcFisicoAmbienteArchivio
      include SaaUtil
      attr_reader :omc_fisico
      alias sistema omc_fisico

      def initialize(omc_fisico:, archivio:, ambiente: nil, account: nil, check_competenza: true) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        @omc_fisico = omc_fisico.is_a?(OmcFisico) ? omc_fisico : OmcFisico.get_by_pk(omc_fisico)

        begin
          @archivio = Constant.value(:archivio, archivio)
        rescue
          raise ArgumentError, "Archivio '#{archivio}' non valido"
        end

        @account = account.is_a?(Account) ? account : Account.first(id: account)

        raise ArgumentError, "Account '#{account}' non valido" if account && !@account

        # Verifica se l'ambiente e' coerente con quello dell'account
        if @account
          raise ArgumentError, "Ambiente '#{ambiente}' non coerente con quello associato all'account con id #{@account.id}" if ambiente && (ambiente != @account.profilo.ambiente)

          # ---->>> ??? Verifica se l'omcFisico e' nelle competenze dell'account
          if check_competenza && !@account.omc_fisici_di_competenza.include?(@omc_fisico.id)
            raise "L'Omc Fisico '#{@omc_fisico.id}' non è di competenza dell'account #{@account.id}"
          end

          ambiente ||= @account.ambiente
        end

        begin
          @ambiente = Constant.value(:ambiente, ambiente)
        rescue
          raise ArgumentError, "Ambiente '#{ambiente}' non valido"
        end
      end

      def db_fk
        :omc_fisico_id
      end

      def import_cache_prefix(hash = {})
        @import_cache_prefix ||= "import_#{@ambiente}_#{@archivio}_#{hash[:vendor]}_#{hash[:omc_fisico]}_"
      end

      def full_descr
        ["omc_fisico=#{omc_fisico.full_descr}", "ambiente=#{ambiente}", pi ? "progetto_irma=#{pi.nome}" : "archivio=#{archivio}"].compact.join(', ')
      end

      def omc_fisico_id
        @omc_fisico_id ||= omc_fisico.id
      end
      alias sistema_id omc_fisico_id

      def entita(logger: nil)
        @entita ||= EntitaOmcFisico.new(omc_fisico_id: omc_fisico.id, omc_fisico: omc_fisico.nome, ambiente: ambiente, archivio: archivio, vendor: vendor_id, logger: logger)
      end

      def formati_audit
        omc_fisico.formati_audit.keys
      end

      def formato_audit_info(formato_audit)
        omc_fisico.formati_audit[formato_audit]
      end

      def rete_id
        nil
      end

      def vendor_release
        sistema.vendor_release_fisico
      end

      def entita_eccezione(*)
        nil
      end

      def carica_nodi_esterni(opts = {}) # rubocop:disable Metrics/AbcSize
        res = {}
        Irma.esegui_e_memorizza_durata(logger: opts[:logger], log_prefix: "#{opts[:log_prefix]}, caricamento cache nodi esterni") do
          stat = { sistemi: 0, nodi: 0 }
          # Db::OmcFisico.where("id != #{sistema_id}").each do |s|
          Db::OmcFisico.where("id NOT IN (#{omc_fisico.omc_con_gemelli.join(',')})").each do |s|
            stat[:sistemi] += 1
            # fisso la ricerca dei nodi su ARCHIVIO_RETE, che sara' sicuramente popolato
            Db::OmcFisicoAmbienteArchivio.new(omc_fisico: s, ambiente: ambiente, archivio: ARCHIVIO_RETE).dataset.where(nodo: true).select(:dist_name).each do |eee|
              res[eee[:dist_name]] = { riferimento_sistema: "Omc Fisico: #{s.nome}, vendor: #{Db::Vendor.get_by_pk(s.vendor_id).nome}" }
            end
          end
          stat[:nodi] = res.size
          stat
        end
        res
      end
    end

    def self.saa_instance(omc_fisico: false, archivio:, id:, account: nil, ambiente: nil, check_competenza: true) # rubocop:disable Metrics/ParameterLists
      if omc_fisico
        OmcFisicoAmbienteArchivio.new(omc_fisico: id, archivio: archivio, account: account, ambiente: ambiente, check_competenza: check_competenza)
      else
        SistemaAmbienteArchivio.new(sistema: id, archivio: archivio, account: account, ambiente: ambiente, check_competenza: check_competenza)
      end
    end
  end
end

require 'irma/funzioni'
