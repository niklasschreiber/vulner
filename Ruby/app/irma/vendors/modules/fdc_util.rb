# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190117
#

module Irma
  module Vendor
    module Rete
      module FdcUtil
        def flag_cancellazioni_ammesse(rete_id_input, result_type: :simple) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          res = []
          if rete_id_input == rete
            res << FLAG_CANCELLAZIONE_INTRA unless meta_entita_relazioni_adiacenza_intra.empty?
            res << FLAG_CANCELLAZIONE_INTER unless meta_entita_relazioni_adiacenza_inter.empty?
          end
          res << FLAG_CANCELLAZIONE_ALL if res.empty?
          if result_type == :simple
            res
          else
            res.map { |v| { id: "#{rete_id_input},#{v}", full_descr: (v == FLAG_CANCELLAZIONE_ALL) ? Constant.label(:rete, rete_id_input) : Constant.label(:flag_cancellazione, v) } }
          end
        end
      end
    end

    module FdcUtil
      FDC_PRIORITY_DIGIT = 5
      FDC_PRIORITY_FORMAT = "%0#{FDC_PRIORITY_DIGIT}d".freeze
      MAX_FDC_PRIORITY = 10**FDC_PRIORITY_DIGIT - 1

      def cella_reparented(*)
        nil
      end

      def entita_per_reparenting(*) end

      def fdc_priority
        {}
      end

      def fdc_prio_str_pattern(me)
        "/#{me}="
      end

      def fdc_prio_str_replacement(me, prio, invert: false)
        "/#{format(FDC_PRIORITY_FORMAT, invert ? (MAX_FDC_PRIORITY + 1 - prio) : prio)}#{me}="
      end

      def fdc_sort_by_priority(array, invert: false)
        (array || []).sort_by do |x|
          y = x.dup
          fdc_priority.each { |me, prio| y.gsub!(fdc_prio_str_pattern(me), fdc_prio_str_replacement(me, prio, invert: invert)) }
          y
        end
      end

      def meta_entita_relazioni_adj_fdc
        meta_entita_relazioni_adiacenza.map { |_k, v| v.keys }.flatten.uniq
      end

      def query_fdc_presenti_assenti(table_name_master:, table_name_rif:)
        priorita = fdc_priority
        order_by_condition = 'a.dist_name'
        priorita.each do |me, prio|
          order_by_condition = 'replace(' + order_by_condition + ", '#{fdc_prio_str_pattern(me)}', '#{fdc_prio_str_replacement(me, prio)}')"
        end
        query = "select a.dist_name, a.version, a.livello, a.naming_path, a.parametri from #{table_name_master} a"
        query += " left outer join #{table_name_rif} b on a.dist_name = b.dist_name where b.dist_name is null"
        query += (" order by (#{order_by_condition}" + ' COLLATE "C"), a.livello')
        query
      end

      def query_rel_adj(table_name:, naming_path_list:, **opts)
        query = "select dist_name, naming_path from #{table_name}"
        query += " where naming_path in (#{naming_path_list.map { |np| "'#{np}'" }.join(',')})"
        query += " and cella_sorgente in (select dist_name from #{opts[:table_name_master]} where naming_path = '#{naming_path_del_rel_adj}')"
        query
      end

      def version_in_fdc?
        true
      end
    end
  end
end
