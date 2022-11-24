# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20161220
#

require 'terminal-table'

module Irma
  module Db
    #
    class ReportComparativo < Model(:report_comparativi)
      plugin :timestamps, update_on_create: true

      configure_retention 15, min: 3, max: 365, use_orm_for_cleanup: true

      def self.cancella_sistema(s_id)
        each { |rc_obj| rc_obj.destroy if rc_obj.sistema_id == s_id || (rc_obj[:info] || {})['pi_sistema_id'] == s_id }
      end

      def before_create
        raise 'Sistema id o OMC Fisico id non avvalorati' unless sistema_id || omc_fisico_id
        raise 'Sistema id e OMC Fisico id avvalorati contemporaneamente' if sistema_id && omc_fisico_id
        raise "Ambiente #{ambiente} non valido" unless Constant.values(:ambiente).include?(ambiente)
      end

      def after_create
        entita.create_table
      end

      def before_destroy
        entita.drop_table
        [Segnalazione].each { |klass| klass.where(report_comparativo_id: id).delete }
      end

      def entita(opts = {})
        EntitaRepComp.new(id: id, **opts)
      end

      def tipo_competenza
        raise 'Sistema id o OMC Fisico id non avvalorati' unless sistema_id || omc_fisico_id
        sistema_id ? TIPO_COMPETENZA_SISTEMA : TIPO_COMPETENZA_OMCFISICO
      end

      def competenza
        { tipo_competenza => [(sistema_id || omc_fisico_id).to_s] }
      end

      def conta_records_entita
        res = {}
        entita.each do |ent|
          res[ent.table_name] = { ambiente: ent.ambiente, records: ent.dataset.count }
        end
        res
      end

      def full_descr
        @full_descr ||= nome
      end

      def filtro_segnalazioni
        { sistema_id: sistema_id, omc_fisico_id: omc_fisico_id, ambiente: ambiente }
      end

      def self.conta_entita(print_table: true)
        rows = []
        order(:id, :nome).all.each do |s|
          s.conta_records_entita.each do |_t_name, t_info|
            rows << [s.full_descr, t_info[:ambiente], t_info[:records]]
          end
        end
        puts Terminal::Table.new(headings: %w(Sistema Ambiente Records), rows: rows).to_s if print_table
        rows
      end

      # record: record di report_comparativo
      # filtro_version: { 'version1' => true, 'version2' => true, ... }
      def self.ignora_per_filtro_version(record, filtro_version) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        return false if filtro_version.empty? || record.nil?
        v1 = (record[RECORD_FIELDS_FONTE[0]] || {})[RECORD_FIELD_VERSION]
        v2 = (record[RECORD_FIELDS_FONTE[1]] || {})[RECORD_FIELD_VERSION]
        (v1 && filtro_version[v1]) || (v2 && filtro_version[v2])
      end
    end
  end
end

# == Schema Information
#
# Tabella: report_comparativi
#
#  account_id    :integer         non nullo, riferimento a accounts.id
#  ambiente      :string(10)      non nullo
#  archivio_1    :json
#  archivio_2    :json
#  count_entita  :integer         non nullo, default(0)
#  created_at    :datetime
#  id            :integer         non nullo, default(nextval('report_comparativi_id_seq')), chiave primaria
#  info          :json
#  nome          :string(256)     non nullo
#  omc_fisico_id :integer         riferimento a omc_fisici.id
#  sistema_id    :integer         riferimento a sistemi.id
#  updated_at    :datetime
#
# Indici:
#
#  uidx_report_comparativi_account_nome  (account_id,nome) UNIQUE
#
