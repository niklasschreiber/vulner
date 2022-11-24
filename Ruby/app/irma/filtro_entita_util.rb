# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180529
#

module Irma
  #
  module FiltroEntitaUtil
    def feu_query_per_naming_path(naming_path:, dataset:, filtro_np:, nome_tabella:, use_pid: true)
      query = dataset.where(naming_path: naming_path)
      yyy = feu_where_condition_per_np(naming_path: naming_path, filtro_np: filtro_np, nome_tabella: nome_tabella, use_pid: use_pid)
      query = query.where(yyy) if yyy
      query = query.order(Sequel.lit(%(dist_name COLLATE "C")))
      { feu_query_np: query, feu_filtro_wi: get_hash_filtro_wi(filtro_np) || {} }
    end

    def feu_naming_path_per_livello(naming_path:, filtro_np:) # rubocop:disable Metrics/AbcSize
      livello = naming_path.to_s.split(NAMING_PATH_SEP).size
      dn_per_livello = []
      filtro_np[FILTRO_MM_ENTITA].each do |dn_entita|
        # ---
        # pzs = dn_entita.split(DIST_NAME_SEP).delete_if { |xxx| xxx.end_with?("#{DIST_NAME_VALUE_SEP}*") }
        # ---
        pzs = dn_entita.split(DIST_NAME_SEP)
        idx = pzs.index { |xxx| xxx.end_with?("#{DIST_NAME_VALUE_SEP}#{NOME_ENTITA_ANY}") }
        pzs = idx > 0 ? pzs[0..idx - 1] : [] if idx
        # ---
        return nil if pzs.count == 0
        (dn_per_livello[livello - pzs.count] ||= []) << pzs.join(DIST_NAME_SEP)
      end
      dn_per_livello
    end

    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/CyclomaticComplexity
    def feu_where_condition_per_np(naming_path:, filtro_np:, nome_tabella:, use_pid: true)
      return nil if filtro_np.nil? || filtro_np.is_a?(Array) || filtro_np[FILTRO_MM_ENTITA].nil?
      return "dist_name in ('')" if filtro_np[FILTRO_MM_ENTITA].empty?
      dn_per_livello = feu_naming_path_per_livello(naming_path: naming_path, filtro_np: filtro_np)
      return nil if dn_per_livello.nil?
      where_conditions = []
      str_pid_condition = "pid in (select id from #{nome_tabella} where "

      if use_pid
        dn_per_livello.each.with_index do |dn_list, idx|
          next if dn_list.nil? || dn_list.empty?
          dn_list_for_query = dn_list.uniq.map { |xx| "'#{xx}'" }.join(',')
          str = ''
          idx.times { str += str_pid_condition }
          str += "dist_name in (#{dn_list_for_query})"
          idx.times { str += ')' }
          where_conditions << str
        end
      else
        dn_per_livello.each.with_index do |dn_list, idx|
          next if dn_list.nil? || dn_list.empty?
          dn_list = dn_list.uniq
          if idx == 0
            where_conditions << "dist_name in (#{dn_list.map { |xx| "'#{xx}'" }.join(',')})"
          else
            dn_list.each { |dn| where_conditions << "dist_name like '#{dn}#{DIST_NAME_SEP}%'" }
          end
        end
      end
      where_conditions.join(' OR ')
    end

    # --------------------------------------------------------
    # PROVE PER WILDCARD INTERMEDIA
    def wildcard_intermedia(array)
      idx = ((iii = array.index(NOME_ENTITA_ANY)) && (array[iii..- 1].index { |x| x != NOME_ENTITA_ANY }))
      iii if idx
    end

    def valori_entita(dist_name)
      dist_name.split(Irma::DIST_NAME_SEP).map { |yy| yy.split(Irma::DIST_NAME_VALUE_SEP)[1] }
    end

    def get_hash_filtro_wi(filtro_np)
      return {} if filtro_np.nil? || !filtro_np.is_a?(Hash) || filtro_np[FILTRO_MM_ENTITA].nil?
      ret = {}
      cache_ve = {}
      filtro_np[FILTRO_MM_ENTITA].each do |dist_name|
        ve = valori_entita(dist_name)
        if (iii = wildcard_intermedia(ve))
          ret[ve[0..iii - 1]] ||= []
          ret[ve[0..iii - 1]] << ve
        else
          # le entita non wildcard intermedia le devo rivalutare dopo
          cache_ve[dist_name] = ve
        end
      end
      cache_ve.sort.each do |dist_name, ve|
        (0..(ve.size - 1)).reverse_each do |idx|
          next if ve[idx] == NOME_ENTITA_ANY
          key = ve[0..idx]
          ret[key] << ve if ret[key] && !feu_tengo?(dist_name, ret)
        end
      end
      ret
    end

    def feu_equal_wildcard(array1, array2)
      array1.map.with_index { |x, idx| x == NOME_ENTITA_ANY || x == array2[idx] }.uniq == [true]
    end

    def feu_tengo?(record_dist_name, hash_filtro_extra)
      no_match_key = true
      valori_e = valori_entita(record_dist_name)
      (0..(valori_e.size - 1)).reverse_each do |level| # level = 0, 1, 2,...
        key = valori_e[0..level]
        next unless hash_filtro_extra[key]
        no_match_key = false
        hash_filtro_extra[key].each do |array_filtro|
          return true if feu_equal_wildcard(array_filtro, valori_e)
        end
      end
      no_match_key
    end
    # --------------------------------------------------------
  end
end
