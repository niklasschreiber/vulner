# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20180314
#
# Stats utilities

require 'terminal-table'

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/ModuleLength
module Irma
  #
  module Task
    #
    module Stats
      AVAILABLE = [:omc_fisici, :sistemi, :entita_omc_logico, :entita_omc_fisico, :app_config, :allarmi_aperti, :allarmi_chiusi, :eventi, :segnalazioni].freeze

      def self.query_db_records(order_by: nil)
        <<-EOS
               SELECT relname relation, trunc(reltuples) records, pg_total_relation_size(C.oid)/1024 size
                FROM pg_class C
           LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
               WHERE nspname NOT IN ('pg_catalog', 'information_schema')
                 AND C.relkind <> 'i'
                 AND C.relkind <> 'S'
                 AND nspname !~ '^pg_toast'
            ORDER BY #{order_by || 'relation'}, relation
        EOS
      end

      def self.db_records(order_by: nil, format: nil)
        records = Db.connection[query_db_records(order_by: order_by)].select_all.all
        case format.to_s
        when 'json'
          records
        else
          headings = %w(Relation Records Size)
          rows = records.map { |record| [record[:relation], record[:records].to_i, record[:size].to_i] }
          t = Terminal::Table.new(headings: headings, rows: rows)
          [1, 2].each { |idx| t.align_column idx, :right }
          format.to_s == 'html' ? "<pre>#{t}</pre>" : t.to_s
        end
      end

      def self.omc_fisici
        headings = %w(Id OmcFisico Vendor Audit)
        rows = Db::OmcFisico.order(%i(nome)).map do |s|
          [s.id, s.nome, s.vendor.nome, s.nome_file_audit]
        end
        t = Terminal::Table.new(headings: headings, rows: rows)
        [0].each { |idx| t.align_column idx, :right }
        "Situazione OmcFisici: #{Db::OmcFisico.count} totali\n" + t.to_s
      end

      def self.sistemi
        headings = %w(Id OmcLogico Rete Vendor Release OmcFisico Audit)
        rows = Db::Sistema.order(%i(id)).map do |s|
          [s.id, s.descr, s.rete.nome, s.vendor.nome, s.vendor_release.descr, s.omc_fisico.nome, s.nome_file_audit]
        end
        t = Terminal::Table.new(headings: headings, rows: rows)
        [0].each { |idx| t.align_column idx, :right }
        "Situazione sistemi: #{Db::Sistema.count} totali\n" + t.to_s
      end

      def self.entita_omc_logico
        t = ''
        rows = []
        headings = nil
        fixed_headings = %w(Id Rete OmcLogico Vendor Release OmcFisico)
        totals = Hash.new(0)
        Db::Sistema.order((ENV['ORDER_ENTITA'] || 'rete_id,descr').split(',').map(&:to_sym)).all.each do |s|
          row = [s.id, s.rete.nome, s.descr, s.vendor.nome, s.vendor_release.descr, s.omc_fisico.nome]
          new_headings = fixed_headings.dup unless headings
          sum = 0
          s.conta_records_entita.each do |_t_name, t_info|
            k = "#{t_info[:ambiente]}-#{t_info[:archivio]}"
            new_headings << k unless headings
            row << t_info[:records]
            sum += t_info[:records]
            totals[k] += t_info[:records]
          end
          totals[:totale] += sum
          row << sum
          new_headings << '# records' unless headings
          rows << row
          headings ||= new_headings
        end
        if headings
          rows << :separator
          rows << ([{ value: 'Records totali', colspan: fixed_headings.size, alignment: :center }] + totals.values.map { |v| { value: v, alignment: :right } })
          t = Terminal::Table.new(headings: headings, rows: rows)
          ([0] + (fixed_headings.size..headings.size - 1).to_a).each { |idx| t.align_column idx, :right }
        end
        "Situazione Entita OmcLogico: #{Db::Sistema.count} sistemi totali\n" + t.to_s
      end

      def self.entita_omc_fisico
        t = ''
        rows = []
        headings = nil
        fixed_headings = %w(Id OmcFisico Vendor)
        totals = Hash.new(0)
        Db::OmcFisico.order((ENV['ORDER_ENTITA'] || 'nome').split(',').map(&:to_sym)).all.each do |s|
          row = [s.id, s.nome, s.vendor.nome]
          new_headings = fixed_headings.dup unless headings
          sum = 0
          s.conta_records_entita.each do |_t_name, t_info|
            k = t_info[:archivio]
            new_headings << k unless headings
            row << t_info[:records]
            sum += t_info[:records]
            totals[k] += t_info[:records]
          end
          totals[:totale] += sum
          row << sum
          new_headings << '# records' unless headings
          rows << row
          headings ||= new_headings
        end
        if headings
          rows << :separator
          rows << ([{ value: 'Records totali', colspan: fixed_headings.size, alignment: :center }] + totals.values.map { |v| { value: v, alignment: :right } })
          t = Terminal::Table.new(headings: headings, rows: rows)
          ([0] + (fixed_headings.size..headings.size - 1).to_a).each { |idx| t.align_column idx, :right }
        end
        "Situazione Entita OmcFisico: #{Db::OmcFisico.count} sistemi totali\n" + t.to_s
      end

      def self.app_config
        rows = Db::AppConfig.order(%w(modulo nome)).map do |p|
          [p.modulo, p.nome, (p.valore == p.valore_di_default) ? p.valore : "#{p.valore} (#{p.valore_di_default})"]
        end
        "Situazione parametri: #{Db::AppConfig.count} totali\n" + Terminal::Table.new(headings: %w(Modulo Nome Valore), rows: rows).to_s
      end

      def self.format_group_records(pre_msg, group_query)
        res = [pre_msg]
        records = Db.connection[group_query].all
        records.sort_by { |x| x[1] }.reverse_each { |x| res << format('%8d (%s)', x[:count], x[:group]) }
        res.join("\n")
      end

      def self.allarmi_aperti
        format_group_records "Situazione allarmi aperti: #{Db::Allarme.count} totali",
                             "select categoria||' - '||nome as group, count(*) from allarmi_chiusi group by 1"
      end

      def self.allarmi_chiusi
        format_group_records "Situazione allarmi chiusi: #{Db::AllarmeChiuso.count} totali",
                             "select categoria||' - '||nome as group, count(*) from allarmi_chiusi group by 1"
      end

      def self.eventi
        format_group_records "Situazione eventi: #{Db::Evento.count} totali",
                             "select categoria||', '||regexp_replace(nome,' - .*','') as group, count(*) from eventi group by 1"
      end

      def self.segnalazioni
        format_group_records "Situazione segnalazioni: #{Db::Segnalazione.count} totali",
                             "select ts.categoria||' - '||ts.nome as group, count(*) from tipi_segnalazioni ts, segnalazioni s where s.tipo_segnalazione_id = ts.id group by 1 order by 2"
      end

      def self.all
        res = [('-' * 10) + " Statistiche DB #{Db.env} (#{Time.now}) " + ('-' * 10)]
        AVAILABLE.each do |t|
          res << Task::Stats.send(t)
          res << ('.' * 79)
        end
        res.join("\n")
      end
    end
  end
end
