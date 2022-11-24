# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

require 'terminal-table'

module Irma
  module Db
    #
    class ProgettoIrma < Model(:progetti_irma)
      plugin :timestamps, update_on_create: true

      configure_retention 15, min: 7, max: 365, use_orm_for_cleanup: true

      class <<self
        def remove_obsolete_record(limit_date:, col:, **opts)
          query = where("#{col} < ?", limit_date)
          # avoid remove for predefined values
          query = query.exclude(account_id: nil)
          opts[:use_orm] ? query.map(&:destroy).size : query.delete
        end
      end

      def self.cancella_sistema(s_id, cancel_empty_pi: true)
        (cancel_empty_pi ? all : exclude(nome: PI_EMPTY_OMCLOGICO)).each do |pi_obj|
          pi_obj.destroy if pi_obj.sistema_id == s_id || (pi_obj[:parametri_input] || {})['sistema_id'] == s_id
        end
      end

      def before_create # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        raise 'Sistema id o OMC Fisico id non avvalorati' unless sistema_id || omc_fisico_id
        raise 'Sistema id e OMC Fisico id avvalorati contemporaneamente' if sistema_id && omc_fisico_id
        raise "Ambiente #{ambiente} non valido" unless Constant.values(:ambiente).include?(ambiente)
        raise "Archivio #{archivio} non valido" unless Constant.values(:archivio).include?(archivio)
      end

      def after_create
        entita.create_table
      end

      def before_destroy
        entita.drop_table
        [Segnalazione].each { |klass| klass.where(progetto_irma_id: id).delete }
      end

      def entita(opts = {})
        EntitaPi.new(id: id, **opts)
      end

      def tipo_competenza
        raise 'Sistema id o OMC Fisico id non avvalorati' unless sistema_id || omc_fisico_id
        sistema_id ? TIPO_COMPETENZA_SISTEMA : TIPO_COMPETENZA_OMCFISICO
      end

      def competenza
        { tipo_competenza => [(sistema_id || omc_fisico_id).to_s] }
      end

      def saa(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        raise 'Sistema id o OMC Fisico id non avvalorati' unless sistema_id || omc_fisico_id
        return @saa if @saa
        acc_id = opts[:account_id] || account_id
        @saa = Db::OmcFisicoAmbienteArchivio.new(omc_fisico: omc_fisico_id, archivio: archivio, account: acc_id) if omc_fisico_id
        @saa ||= Db::SistemaAmbienteArchivio.new(sistema: sistema_id, archivio: archivio, account: acc_id) if sistema_id
        @saa.pi = self
        @saa
      end

      def metamodello(**opts)
        raise 'Sistema id o OMC Fisico id non avvalorati' unless sistema_id || omc_fisico_id
        obj = if sistema_id
                Db::Sistema.first(id: sistema_id)
              else
                Db::OmcFisico.first(id: omc_fisico_id)
              end
        obj.metamodello(**opts) if obj
      end

      def conta_records_entita
        res = {}
        entita.each do |ent|
          res[ent.table_name] = { ambiente: ent.ambiente, archivio: ent.archivio, records: ent.dataset.count }
        end
        res
      end

      def full_descr
        @full_descr ||= "#{nome} (#{saa.full_descr})"
      end

      def per_omcfisico
        omc_fisico_id || ((parametri_input || {})['per_omcfisico'] if sistema_id)
        # (omc_fisico_id || (sistema_id && (parametri_input || {})['per_omcfisico'] == true)) ? true : false
      end

      def tipo_sorgente
        (parametri_input || {})['tipo_sorgente'] || (sistema_id ? CALCOLO_SORGENTE_OMCLOGICO : CALCOLO_SORGENTE_OMCFISICO)
      end

      def pi_sistema_id
        sistema_id || (parametri_input || {})['sistema_id']
      end

      def copia(nome:, account_id:, **opts)
        transaction do
          pi_copy = self.class.create(values.reject { |k| k == :id }.merge(account_id: account_id, nome: nome).merge(opts))
          Db.connection.run("insert into #{pi_copy.entita.table_name} select * from #{entita.table_name}")
          pi_copy
        end
      end

      def self.conta_entita(print_table: true)
        rows = []
        order(:id, :nome).all.each do |s|
          s.conta_records_entita.each do |_t_name, t_info|
            rows << [s.full_descr, t_info[:ambiente], t_info[:archivio], t_info[:records]]
          end
        end
        puts Terminal::Table.new(headings: %w(Sistema Ambiente Archivio Records), rows: rows).to_s if print_table
        rows
      end
    end
  end
end

# == Schema Information
#
# Tabella: progetti_irma
#
#  account_id      :integer         riferimento a accounts.id
#  ambiente        :string(10)      non nullo
#  archivio        :string(10)      non nullo
#  count_entita    :integer         non nullo, default(0)
#  created_at      :datetime
#  id              :integer         non nullo, default(nextval('progetti_irma_id_seq')), chiave primaria
#  nome            :string(256)     non nullo
#  omc_fisico_id   :integer         riferimento a omc_fisici.id
#  parametri_input :json
#  sistema_id      :integer         riferimento a sistemi.id
#  updated_at      :datetime
#
# Indici:
#
#  uidx_progetti_irma_account_nome  (account_id,nome) UNIQUE
#
