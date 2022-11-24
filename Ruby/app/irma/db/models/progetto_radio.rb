# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

module Irma
  module Db
    #
    class ProgettoRadio < Model(:progetti_radio)
      plugin :timestamps, update_on_create: true

      def self.cleanup(_hash = {})
        cleanup_only_rebuild_indexes
      end

      def self.aggiorna_sistema_id(s_id = nil)
        Sistema.sistemi_gemelli_ids(s_id).each do |gemelli_id|
          next if (gemelli_id || []).empty?
          where_sistema_id(gemelli_id.first).each do |cella|
            cella.update(sistema_id: gemelli_id)
          end
        end
      end

      def self.cancella_sistema(s_id)
        transaction do
          where_sistema_id(s_id).each do |pr_obj|
            if pr_obj.sistema_id == [s_id]
              pr_obj.destroy
            else
              new_sid = pr_obj.sistema_id - [s_id]
              pr_obj.update(sistema_id: new_sid)
            end
          end
        end
      end

      def self.check_coerenza_sistema_id # rubocop:disable Metrics/AbcSize
        # 'non_coerenti': id di sistemi non gemelli tra loro
        # 'non_completi': sistemi gemelli tra loro ma manca qualche gemello rispetto all'anagrafica...
        res = { non_coerenti: [], non_completi: [] }
        select_map(:sistema_id).map(&:sort).uniq.each do |sistemi_ids|
          sistemi_ids.sort!
          unless Sistema.sistemi_gemelli?(sistemi_ids)
            res[:non_coerenti] << sistemi_ids unless res[:non_coerenti].include?(sistemi_ids)
            next
          end
          gemelli_anag = Sistema.sistemi_gemelli_ids(sistemi_ids[0])
          if sistemi_ids.size < gemelli_anag.size
            res[:non_completi] << sistemi_ids unless res[:non_completi].include?(sistemi_ids)
          end
        end
        res
      end

      def self.where_sistema_id(s_id)
        where("sistema_id @> '#{s_id}'::jsonb")
      end

      def self.check_sistema_id(sistema_id_input)
        sistema_id_val = sistema_id_input.to_a unless sistema_id_input.class == Array
        raise 'Il campo sistema_id deve contenere almeno un sistema' if (sistema_id_val || []).empty?
        sistema_id_val.each { |ssiidd| raise "L'id #{ssiidd} non corrisponde a nessun sistema" unless Sistema.first(id: ssiidd) }
        raise "I sistemi #{sistema_id_val} non sono gemelli tra loro" unless Sistema.sistemi_gemelli?(sistema_id_val)
      end

      def before_create
        self.class.check_sistema_id(sistema_id)
        super
      end

      def before_update
        self.class.check_sistema_id(sistema_id) if changed_columns.member?(:sistema_id)
        super
      end

      def rete
        sss = Sistema.get_by_pk(sistema_id.first)
        sss ? sss.rete : nil
      end

      def vendor
        sss = Sistema.get_by_pk(sistema_id.first)
        sss ? sss.vendor : nil
      end

      # TODO_GEMELLI: NON VA PIU' BENE !!!!!!
      #        usata in load_gruppo_celle in calcolo_da_prn
      def vendor_release
        sss = Sistema.get_by_pk(sistema_id.first)
        sss ? sss.vendor_release : nil
      end

      def adiacenze(flag_omcfisico = false) # rubocop:disable Metrics/AbcSize
        ret = { ADJ_INTERNA.to_s => [], ADJ_ESTERNA.to_s => [] }
        adiacenze = valori.select { |k, _v| k.to_s.start_with?(*PREFISSI_ADIACENZA) }.map do |_hdr, xxx|
          xxx[0] if xxx && !xxx[0].to_s.empty?
        end.compact
        ProgettoRadio.where(nome_cella: adiacenze).each do |adj|
          cond = if flag_omcfisico
                   adj.omc_fisico_completo_id == omc_fisico_completo_id
                 else
                   adj.sistema_id == sistema_id
                 end
          key = cond ? ADJ_INTERNA : ADJ_ESTERNA
          ret[key.to_s] << adj
        end
        ret
      end

      def adiacenze_esterne(flag_omcfisico = false)
        adiacenze(flag_omcfisico)[ADJ_ESTERNA.to_s]
      end

      def nome_adiacenze_esterne(flag_omcfisico = false)
        adiacenze(flag_omcfisico)[ADJ_ESTERNA.to_s].map(&:nome_cella)
      end

      def adiacenze_interne(flag_omcfisico = false)
        adiacenze(flag_omcfisico)[ADJ_INTERNA.to_s]
      end

      def nome_adiacenze_interne(flag_omcfisico = false)
        adiacenze(flag_omcfisico)[ADJ_INTERNA.to_s].map(&:nome_cella)
      end
    end
    #
    class PrCella < Db::ProgettoRadio
      attr_accessor :linea_file, :esito_analisi

      def initialize(hash = {})
        @linea_file      = hash.delete(:linea_file)
        @esito_analisi   = hash.delete(:esito_analisi)
        super(hash)
        self.header ||= []
        self.valori ||= []
      end

      def aggiorna_db
        action = nil
        db_cella = self.class.first(nome_cella: nome_cella)
        if db_cella
          db_cella.update(attributes)
          action = :upd
        else
          db_cella = save
          action = :ins
        end
        [db_cella, action]
      end

      def info
        {
          class: self.class.to_s, linea_file: linea_file, nome_cella: nome_cella, cgi: cgi, nome_nodo: nome_nodo, release_nodo: release_nodo, esito_analisi: esito_analisi
        }
      end
    end # fine
  end
end

# == Schema Information
#
# Tabella: progetti_radio
#
#  cgi                    :string(128)     non nullo
#  created_at             :datetime
#  header                 :json
#  id                     :integer         non nullo, default(nextval('progetti_radio_id_seq')), chiave primaria
#  nome_cella             :string(128)     non nullo
#  nome_nodo              :string(128)
#  omc_fisico_completo_id :integer         riferimento a omc_fisici_completi.id
#  release_nodo           :string(128)
#  sistema_id             :jsonb
#  updated_at             :datetime
#  valori                 :json
#
# Indici:
#
#  idx_progetti_radio_omc_fisico_id   (omc_fisico_completo_id)
#  idx_progetti_radio_sistema_id      (sistema_id)
#  idx_progetti_radio_sistema_id_gin  (sistema_id)
#  uidx_progetti_radio_nome_cella     (nome_cella) UNIQUE
#
