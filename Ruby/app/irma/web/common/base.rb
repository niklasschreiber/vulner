# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli, P. Cortona
#
# Creation date: 20170418
#

require 'irma/record_formatter'

module Irma
  module Web
    # rubocop:disable Metrics/ModuleLength
    module Common
      PARAM_SEP = ','.freeze
      FILTRI_COMPETENZA = {
        vendors:    fcv = [],
        reti:       fcr = (fcv + [['vendors', :vendor_id]]),
        omc_fisici: fco = (fcr + [['reti', :rete_id]]),
        sistemi:    fco + [['omc_fisici', :omc_fisico_id]]
      }.freeze
      FILTRO_COMPETENZA_SELEZIONE_ON = 'on'.freeze

      CAST_METHOD = { 'char' => :to_s, 'integer' => :to_i, 'float' => :to_f }.freeze
      OPERATOR_MAPPING = { '=' => '==', '<>' => '!=', OPERATORI_INIZIA_CON => 'start_with?', OPERATORI_FINISCE_CON => 'end_with?', OPERATORI_CONTIENE => 'include?' }.freeze
      CUSTOM_COLUMNS = ['version'].freeze
      FONTE_MAPPING = { fonte_1: 'f1', fonte_2: 'f2' }.freeze

      def _handle_wildcards(field:, input:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        gestione_spazio = opts.fetch(:gestione_spazio, GESTIONE_SPAZIO_LISTA_ESATTA)
        input = input.chomp.gsub(/\\\s+/, ',') if gestione_spazio == GESTIONE_SPAZIO_VIRGOLA
        if gestione_spazio == GESTIONE_SPAZIO_LISTA_ESATTA && input.include?(' ')
          input = input.chomp.gsub(/\\\s+/, '\$,\^')
          input = '\^' + input unless input[1] == '^'
          input += '\$' unless input[-1] == '$'
        end
        (input.is_a?(String) ? input.split(opts[:sep] || ',') : input).each do |s|
          s = if s.start_with?('\\^') && s.end_with?('\\$')
                s.sub(/\\\^/, '').gsub(/(\\\$)\Z/, '')
              else
                (s.include?('*') ? s : "*#{s}*")
              end
          s = s.tr('*', '%')
          s = s.gsub(/\\\+/, ' ')
          yield(s.include?('%') ? Sequel.like(field, s) : Sequel::SQL::BooleanExpression.new(:'=', field, s))
        end
      end

      def _gestione_regexp_star(input)
        '^' + input.gsub(/(\\\*)+/, '.*') + '$'
      end

      def records_competenza(request, what) # rubocop:disable Metrics/AbcSize
        res = []
        if (sess = logged_in)
          filtro = JSON.parse(request.params['filtro'] || '{}')
          res = sess.data[:valori_competenza][what].select do |r|
            ret = r
            FILTRI_COMPETENZA[what].each do |k, field|
              if filtro[k] && !filtro[k].include?(r[field])
                ret = nil
                break
              end
            end
          end.compact
        end
        res
      end

      #
      def descrizione_utente_per_gui(user_id)
        if user_id
          utente = user_id && Db::Utente.get_by_pk(user_id)
          utente.formato_per_gui if utente
        else
          ''
        end
      end

      def timestamp_to_string(ts)
        ts ? Time.at(ts).strftime(Irma.config[Irma::GUI_DEFAULT_DATE_FORMAT]) : ''
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      def add_like_conditions(query:, field:, pattern:, case_insensitive: true, extra_field: nil, **opts)
        q = nil
        unless pattern.to_s.empty?
          input = Regexp.escape(case_insensitive ? pattern.downcase : pattern).gsub(/(\\\*)+/, '*')
          _handle_wildcards(field: case_insensitive ? Sequel.function(:lower, field) : field, input: input, **opts) do |y|
            q = q ? q | y : y
          end
          if extra_field
            ef_array = [extra_field].flatten
            ef_array.each do |ef|
              _handle_wildcards(field: case_insensitive ? Sequel.function(:lower, ef) : ef, input: input, **opts) do |y|
                q = q ? q | y : y
              end
            end
          end
        end
        q ? query.where(q) : query
      end
      # rubocop:enable all

      def add_regexp_conditions(input:, case_insensitive: true, **re_opts) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        gestione_spazio = re_opts.fetch(:gestione_spazio, GESTIONE_SPAZIO_LISTA_ESATTA)
        input = input.chomp.gsub(/\s+/, ',') if gestione_spazio == GESTIONE_SPAZIO_VIRGOLA
        if gestione_spazio == GESTIONE_SPAZIO_LISTA_ESATTA && input.include?(' ')
          input = input.chomp.gsub(/\s+/, '$,^')
          input = '^' + input unless input[0] == '^'
          input += '$' unless input[-1] == '$'
        end
        res = Regexp.escape(input).split(',').map do |pattern|
          pattern = (pattern.start_with?('\^') && pattern.end_with?('\$')) ? pattern.sub(/(\\\^)/, '^').gsub(/(\\\$)\Z/, '$') : pattern
          pattern.include?('*') ? _gestione_regexp_star(pattern) : pattern
        end
        /#{case_insensitive ? '(?i)' : ''}#{res.join('|')}/
      end

      def post_locfile_to_shared_fs(locfile:, dir:)
        local_file = nil
        local_file = locfile[:tempfile].path
        shared_post_file(local_file, input_file = File.join(dir, locfile[:filename]))
        input_file
      rescue => e
        raise "Errore di post sul shared_fs server del file locale #{local_file || locfile.inspect} nella directory #{dir}: #{e}"
      end

      def records_with_export(request_params, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        export = (request_params[:export_format] || request_params['export_format']).to_s
        case export
        when 'txt', 'xls'
          # TODO: eventualmente gestire il flag opts[export] == false come negazione dell'export
          formatter_class = opts[export] || Irma.class_eval("RecordFormatter::#{export.capitalize}")
          f = formatter_class.new(**opts.merge(format: export,
                                               sheet_name: request_params[:sheet_name] || request_params['sheet_name'] || '',
                                               export_columns: (request_params[:export_columns] || request_params['export_columns'])).symbolize_keys).create_temp_file do |formatter|
            yield(formatter)
          end
          invia_file(f, filename: (opts[:filename] || opts['filename'] || File.basename(f)).gsub('@FULL_DATE@', Time.now.strftime('%Y%m%d_%H%M%S')).gsub('@ESTENSIONE@', File.extname(f)))
        when ''
          records = RecordFormatter::Array.new.create_array do |formatter|
            yield(formatter)
          end
          { data: records, total: records.size }
        else
          raise "Formato #{export} non supportato"
        end
      end

      def sistema_o_omc_fisico(record)
        if record[:sistema_id]
          Db::Sistema.get_by_pk(record[:sistema_id])
        elsif record[:omc_fisico_id]
          Db::OmcFisico.get_by_pk(record[:omc_fisico_id])
        end
      end

      def sistema_o_omc_fisico_o_vendor_release(record)
        if record[:sistema_id]
          Db::Sistema.get_by_pk(record[:sistema_id])
        elsif record[:omc_fisico_id]
          Db::OmcFisico.get_by_pk(record[:omc_fisico_id])
        elsif record[:vendor_release_id]
          Db::VendorRelease.get_by_pk(record[:vendor_release_id])
        end
      end

      #
      def aggiungi_filtro_data(query, filtro_data, field, oper, table: nil)
        if filtro_data
          data = Time.at(filtro_data / 1000)
          query = table ? query.where { "\"#{table}\".\"#{field}\" #{oper} \'#{data}\'" } : query.where { "\"#{field}\" #{oper} \'#{data}\'" }
        end
        query
      end

      def list_values_for_constants(scope:, prefix: nil, allow_blank: false, allow_blank_msg: '')
        res = Constant.constants(scope, prefix).map { |c| { id: c.value, descr: c.label } }.sort_by { |x| x[:descr] }
        res.unshift(descr: allow_blank_msg, id: allow_blank_msg) if allow_blank
        res
      end

      def id_sistemi_di_competenza_filtrati
        (((sess = logged_in) && sess.data[:preferenze]) || {})[:sistemi_di_competenza_filtrati] || []
      end

      def id_omc_fisici_di_competenza_filtrati
        (((sess = logged_in) && sess.data[:preferenze]) || {})[:omc_fisici_di_competenza_filtrati] || []
      end

      def id_vendor_releases_di_competenza_filtrati
        (((sess = logged_in) && sess.data[:preferenze]) || {})[:vendor_releases_di_competenza_filtrati] || []
      end

      def filtro_sistemi
        sdcf = id_sistemi_di_competenza_filtrati
        sdcf = records_competenza(request, :sistemi).map { |record| record[:id] } if sdcf.empty?
        sdcf
      end

      def filtro_omc_fisico
        omcf = id_omc_fisici_di_competenza_filtrati
        omcf = records_competenza(request, :omc_fisici).map { |record| record[:id] } if omcf.empty?
        omcf
      end

      def _account_ids_matricola(pattern, extra_field: nil, **opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        query = Db::Account.join(Db::Utente.table_name, id: :utente_id).select(Sequel.qualify(:accounts, :id))
        q = nil
        unless pattern.to_s.empty?
          input = Regexp.escape(pattern.downcase).gsub(/(\\\*)+/, '*')
          _handle_wildcards(field: Sequel.function(:lower, :matricola), input: input, **opts) do |y|
            q = q ? q | y : y
          end
          if extra_field
            ef_array = [extra_field].flatten
            ef_array.each do |ef|
              _handle_wildcards(field: Sequel.function(:lower, ef), input: input, **opts) do |y|
                q = q ? q | y : y
              end
            end
          end
        end
        query = query.where(q) if q
        query.select_map(Sequel.qualify(:accounts, :id))
      end

      def applica_filtro_tipo_account_matricola(query, filtro_tipo_account, filtro_matricola) # rubocop:disable Metrics/AbcSize
        sessione = logged_in
        if filtro_matricola && !filtro_matricola.empty?
          query = query.where(account_id: _account_ids_matricola(filtro_matricola,
                                                                 extra_field: Sequel.function(:concat, Sequel.qualify(:utenti, :nome), ' ', :cognome)))
        end
        case filtro_tipo_account
        when FILTRO_SEGNALAZIONI_UTENTE_MINE
          query.where(account_id: sessione.account_id)
        when FILTRO_SEGNALAZIONI_UTENTE_MINEOTHER
          query.where(account_id: _account_ids_matricola(sessione.matricola)).exclude(account_id: sessione.account_id)
        when FILTRO_SEGNALAZIONI_UTENTE_OTHER
          query.where(Sequel.or(account_id: nil) | Sequel.~(account_id: _account_ids_matricola(sessione.matricola)))
        else
          query
        end
      end
    end
  end
end
