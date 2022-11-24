# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160217
#

# export_adrn_irma1
require 'irma/db' # ???

module Irma
  #
  class Command < Thor # rubocop:disable Metrics/ClassLength
    method_option :tecrel_irma1, type: :string, banner: 'identificativo tecrel di irma1'
    method_option :filtro_release, type: :string, banner: 'filtro release (\'release_descr,vendor,rete\')'
    # export
    method_option :dburl, aliases: '-d', type: :string, banner: 'JDBC url'
    method_option :fetch_size, aliases: '-b', type: :numeric, banner: 'Dimensione blocco fetch di risultati', default: 1000
    method_option :out_dir_root, aliases: '-o', type: :string, banner: 'Directory per il file che contiene i dati', default: '/tmp/'
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)

    common_options 'export_adrn_irma1', "Esegue l'export del metamodello con regole di calcolo dal db di irma1 (anagCell)"
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def export_adrn_irma1
      start_time = Time.now
      res = {}
      Db.init(env: options[:env], logger: logger, load_models: true)

      @map_rete_id_nome = { '1' => 'GSM', '2' => 'UMTS', '3' => 'LTE' }
      @map_rete_nome_id = { 'GSM' => 1, 'UMTS' => 2, 'LTE' => 3 }

      tecrel_da_esportare = [] # contiene array fatti cosi': [id_tecrel, [desc_rel, vendor, rete]]

      if options[:filtro_release].nil? && options[:tecrel_irma1].nil?
        # se ne' options[:filtro_release] ne' options[:tecrel_irma1], vanno esportate TUTTE le tecrel di irma1
        # --- workaround anag_rete
        # xxx = db.fetch('select b.id_tecrel, a.rete, b.desc_rel, b.desc_tec from anag_rete a, tecrel b where b.id_rete = a.id_rete').all
        xxx = db.fetch('select b.id_tecrel, b.id_rete, b.desc_rel, b.desc_tec from tecrel b').all
        # ---
        xxx.each do |record|
          id_vr_scelto = record[:id_tecrel]
          # --- workaround anag_rete
          # terna = [record[:desc_rel], record[:desc_tec], record[:rete]]
          terna = [record[:desc_rel], record[:desc_tec], @map_rete_id_nome[record[:id_rete].to_s]]
          # ---
          tecrel_da_esportare << [id_vr_scelto, terna] if check_terna(terna) && check_id_vr(id_vr_scelto)
        end
      elsif options[:filtro_release]
        terna = options[:filtro_release].split(',')
        raise "Il filtro_release specificato non consente di identificare la release da esportare (#{options[:filtro_release]})" unless check_terna(terna)
        id_vr_scelto = determina_idtecrel_da_terna(*terna)
        raise "Errore nell'identificare la release da esportare (id: #{id_vr_scelto}, #{compact_descr_vr(terna)})" unless check_terna(terna) && check_id_vr(id_vr_scelto)
        tecrel_da_esportare << [id_vr_scelto, terna]
      elsif options[:tecrel_irma1]
        id_vr_scelto = options[:tecrel_irma1]
        raise "L'id_tecrel specificato non consente di identificare la release da esportare (id: #{id_vr_scelto}, #{compact_descr_vr(terna)}})" unless check_id_vr(id_vr_scelto)
        terna = determina_terna_da_idtecrel(options[:tecrel_irma1])
        raise "Errore nell'identificare la release da esportare (id: #{id_vr_scelto}, #{compact_descr_vr(terna)})" unless check_terna(terna) && check_id_vr(id_vr_scelto)
        tecrel_da_esportare << [id_vr_scelto, terna]
      end

      # puts "XXXXXXXXXXXX #{tecrel_da_esportare}"

      @tmp_dir_root = options[:out_dir_root]

      export_metamodello_irma1
      tecrel_da_esportare.each do |yyy|
        id_vr_scelto, terna = yyy
        begin
          dir_zip = crea_dir_zip(@tmp_dir_root, terna)
          res[compact_descr_vr(terna)] = export_metamodello_per_vr(dir_zip: dir_zip, id_vr: id_vr_scelto, terna: terna)
          res[compact_descr_vr(terna)][:artifact] = zip_dir_zip(dir_zip)
        rescue => e
          msg = "Creazione file di export metamodello da irma1 (id_release: #{id_vr_scelto}, #{compact_descr_vr(terna)}) fallita (#{e.backtrace})"
          out_msg_con_log('error', msg, start_time)
          raise e
        ensure
          FileUtils.rm_rf(dir_zip) if File.exist?(dir_zip)
        end
      end
      res
    end

    private

    include Irma::Funzioni::ImportExportAdrnUtil

    def zip_dir_zip(dir_zip)
      xxx = File.basename(dir_zip)
      yyy = File.dirname(dir_zip)
      zip_file = "#{dir_zip}.zip"
      FileUtils.rm_f(zip_file) if File.exist?(zip_file)
      `cd \"#{yyy}\" && zip -r \"#{File.basename(zip_file)}\" \"#{xxx}\" 2>&1`
      err = $CHILD_STATUS.exitstatus
      raise "Errore nella compressione della directory #{dir_zip} (#{err})" unless err.zero?
      zip_file
    end

    def determina_terna_da_idtecrel(idtecrel)
      # --- workaround anag_rete
      x = db.fetch("select b.id_rete, b.desc_rel, b.desc_tec from tecrel b where b.id_tecrel = #{idtecrel}").first
      raise "L'id_tecrel specificato (#{idtecrel}) non corrisponde a nessuna tecrel su irma1" unless x
      [x[:desc_rel], x[:desc_tec], @map_rete_id_nome[x[:id_rete].to_s]]
      # ---
      # x = db.fetch("select a.rete, b.desc_rel, b.desc_tec from anag_rete a, tecrel b where b.id_rete = a.id_rete and b.id_tecrel = #{idtecrel}").first
      # raise "L'id_tecrel specificato (#{idtecrel}) non corrisponde a nessuna tecrel su irma1" unless x
      # [x[:desc_rel], x[:desc_tec], x[:rete]]
    end

    def determina_idtecrel_da_terna(release_descr, vendor, rete)
      # --- workaround anag_rete
      id_rete = @map_rete_nome_id[rete]
      # rid = db.fetch("select id_rete from anag_rete where rete = '#{rete}'").first
      # raise "La rete specificata nel filtro_release (release: #{release_descr}, vendor: #{vendor}, rete: #{rete}) non corrisponde a nessuna rete anagrafata in irma1" unless rid
      # id_rete = rid[:id_rete]
      # ---
      x = db.fetch("select id_tecrel from tecrel where id_rete = #{id_rete} AND desc_rel = '#{release_descr}' AND desc_tec = '#{vendor}'").first
      raise "Il filtro_release (release: #{release_descr}, vendor: #{vendor}, rete: #{rete}) non corrisponde a nessuna tecrel" unless x
      x[:id_tecrel]
    end

    def pre_export_adrn_irma1
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    def out_msg_con_log(level, msg, start_time = nil)
      elapsed = start_time ? "in #{(Time.now - start_time).round(1)} secondi " : ''
      puts "\n[#{Time.now}]: #{msg} #{elapsed}"
      @logger.send(level, msg) if @logger
    end

    def db
      unless @db
        @db = Sequel.connect(options[:dburl], fetch_size: options[:fetch_size])
        @db.loggers << Logger.new(options[:log_file])
      end
      @db
    end

    def export_metamodello_per_vr(dir_zip:, id_vr:, terna:)
      start_time = Time.now
      @col_meta_entita = colonne_meta_entita
      @col_meta_parametro = colonne_meta_parametro
      @col_json_meta_entita = colonne_json_meta_entita
      @col_json_meta_parametro = colonne_json_meta_parametro

      res = { num_meta_entita: 0, num_meta_parametri: 0 }
      msg = "per vendor release 'id: #{id_vr}, #{compact_descr_vr(terna)}'"
      file_me = File.join(dir_zip, NOME_FILE_EXPORT_ME)
      file_mp = File.join(dir_zip, NOME_FILE_EXPORT_MP)
      out_msg_con_log('info', "Inizio export dati meta_modello da irma1 su file #{file_me} e #{file_mp} #{msg}")
      begin
        map_id_meta_entita = {}
        res[:num_meta_entita] = export_meta_entita(file: file_me, id_vr: id_vr, terna: terna, map_id_meta_entita: map_id_meta_entita)
        res[:num_meta_parametri] = export_meta_parametri(file: file_mp, id_vr: id_vr, map_id_meta_entita: map_id_meta_entita)
      rescue => e
        out_msg_con_log('error', "Export dati meta_modello da irma1 fallito (#{e})", start_time)
        raise e
      end
      out_msg_con_log('info', "Export dati meta_modello da irma1 su file #{file_me} e #{file_mp} #{msg}, terminato con successo", start_time)
      res
    end

    def aggiustamenti_mecontext(nuovo_record)
      # Alias per MeContext
      if nuovo_record[:naming_path] == 'SubNetwork;SubNetwork;MeContext'
        nuovo_record[:regole_calcolo] ||= {}
        nuovo_record[:regole_calcolo][RC_DEFAULT_GRP_KEY] ||= {}
        nuovo_record[:regole_calcolo][RC_DEFAULT_GRP_KEY]['alias'] = ['[AdPR.MECONTEXT]']
      elsif nuovo_record[:naming_path].start_with?('SubNetwork;SubNetwork;MeContext;ManagedElement;NodeBFunction')
        nuovo_record[:fase_di_calcolo] = FASE_CALCOLO_PI_ALIAS
        nuovo_record[:meta_entita_ref] = ['SubNetwork;SubNetwork;MeContext']
      elsif ['SubNetwork;vsDataExternalGsmPlmn', 'SubNetwork;vsDataExternalUtranPlmn'].include?(nuovo_record[:naming_path])
        # MetaEntita obsolete: 'SubNetwork;vsDataExternalGsmPlmn','SubNetwork;vsDataExternalUtranPlmn'
        nuovo_record[:fase_di_calcolo] = nil
      elsif nuovo_record[:fase_di_calcolo] == FASE_CALCOLO_PI && nuovo_record[:naming_path].start_with?('SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataEquipment')
        # MetaEntita SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataEquipment e discendenti
        nuovo_record[:fase_di_calcolo] = FASE_CALCOLO_REF
        nuovo_record[:meta_entita_ref] = ['SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataEquipment']
      end
      nuovo_record
    end

    def sistema_record(record)
      record.each do |k, v|
        record[k] = if v.is_a?(BigDecimal)
                      v.to_f.to_i
                    elsif v.is_a?(String)
                      v.gsub("\n", '\\n').gsub('"', '\"').gsub("\t", '\\t')
                    else
                      v
                    end
      end
      record
    end

    def tipo_valore
      db[:tipo_valore].select(:classe, :valore, :codice).each do |rr|
        begin
          case rr[:classe]
          when 'M_ENTI_TYPE'
            @tipo_valore_entita[rr[:codice]] = case rr[:valore]
                                               when 'INT_TYPE'
                                                 META_ENTITA_TIPO_INTEGER
                                               when 'FLOAT_TYPE'
                                                 META_ENTITA_TIPO_FLOAT
                                               when 'CHAR_TYPE'
                                                 META_ENTITA_TIPO_CHAR
                                               end
          when 'M_PARA_TYPE'
            @tipo_valore_parametro[rr[:codice]] = case rr[:valore]
                                                  when 'INT_TYPE'
                                                    META_PARAMETRO_TIPO_INTEGER
                                                  when 'FLOAT_TYPE'
                                                    META_PARAMETRO_TIPO_FLOAT
                                                  when 'CHAR_TYPE'
                                                    META_PARAMETRO_TIPO_CHAR
                                                  end
          end
        rescue => e
          out_msg_con_log('warn', "Lettura tabella 'tipo_valore' fallito per il record #{rr.inspect}: #{e.backtrace}")
          raise
        end
      end
    end

    def np_per_extra_name
      xxx = db.fetch('select distinct a.naming_path, b.param_value from meta_entita a, parametri_identificativi_ger b where b.ID_M_ENTITA = a.ID_M_ENTITA').all
      xxx.each { |rec| @np_per_extra_name[rec[:naming_path]] = rec[:param_value] }
    end

    MULTI = '1'.freeze
    NON_MULTI = '0'.freeze

    def meta_entita_multi
      @meta_entita_multi = {}
      xxx = db.fetch('select id_m_entita, fl_multi from meta_entita').all
      xxx.each do |rrr|
        sistema_record(rrr)
        @meta_entita_multi[rrr[:id_m_entita]] = rrr[:fl_multi].to_s
      end
    end

    def meta_parametri_multi
      @meta_parametri_multi = {}
      xxx = db.fetch('select id_m_param, is_multi from meta_parametri').all
      xxx.each do |rrr|
        sistema_record(rrr)
        @meta_parametri_multi[rrr[:id_m_param]] = rrr[:is_multi].to_s
      end
    end

    # NOTA: Tutte le query nei metodi seguenti sono suddivise in due step: regola < 4000, regola >= 4000
    # per questioni di performance. Lasciando la sola query lineare (senza to_char...) i tempi sono inaccettabili (ore).

    def regole_calcolo_base(tabella, campo_id, multi_info, hash_regole_calcolo)
      xxx = db.fetch("select #{campo_id}, to_char(regola_calcolo) rg from #{tabella} where length(NVL(regola_calcolo, 'dummy')) < 4000").all
      xxx += db.fetch("select #{campo_id}, regola_calcolo rg from #{tabella} where length(regola_calcolo) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        next unless multi_info[rrr[campo_id.to_sym]] == NON_MULTI
        hash_regole_calcolo[rrr[campo_id.to_sym]] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_DEFAULT_GRP_KEY] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_DEFAULT_GRP_KEY][DEFAULT_KEY] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_DEFAULT_GRP_KEY][DEFAULT_KEY] << Irma.sistema_regola_adj_x_t(rrr[:rg]) unless rrr[:rg].nil? || rrr[:rg] == MULTIVALORE
      end
      # meta_parametri_mv
      xxx = db.fetch("select #{campo_id}, to_char(regola_di_calcolo) rg, posizione from #{tabella}_mv where length(NVL(regola_di_calcolo, 'dummy')) < 4000").all
      xxx += db.fetch("select #{campo_id}, regola_di_calcolo rg, posizione from #{tabella}_mv where length(regola_di_calcolo) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        next unless multi_info[rrr[campo_id.to_sym]] == MULTI
        hash_regole_calcolo[rrr[campo_id.to_sym]] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_DEFAULT_GRP_KEY] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_DEFAULT_GRP_KEY][DEFAULT_KEY] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_DEFAULT_GRP_KEY][DEFAULT_KEY][rrr[:posizione].to_i - 1] = Irma.sistema_regola_adj_x_t(rrr[:rg])
      end
    end

    def regole_calcolo_rnc(tabella, campo_id, multi_info, hash_regole_calcolo)
      tabella_base = tabella.split('_')[0, 2].join('_')
      xxx = db.fetch("select #{campo_id}, id_tecrel, id_rel_rnc, to_char(regola_calcolo) rg from #{tabella} where length(NVL(regola_calcolo, 'dummy')) < 4000").all
      xxx += db.fetch("select #{campo_id}, id_tecrel, id_rel_rnc, regola_calcolo rg from #{tabella} where length(regola_calcolo) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        next unless multi_info[rrr[campo_id.to_sym]] == NON_MULTI
        rnc_key = @rnc["#{rrr[:id_tecrel]}__#{rrr[:id_rel_rnc]}"]
        unless rnc_key
          # puts "XXXXXXXXXXXXX #{rrr[:id_tecrel]}__#{rrr[:id_rel_rnc]}"
          out_msg_con_log('warn', "Ignorata regola di calcolo in #{tabella} (#{rrr.inspect}) perche' non corrisponde a nessun RNC valido")
          next
        end
        hash_regole_calcolo[rrr[campo_id.to_sym]] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_RELNODO_GRP_KEY] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_RELNODO_GRP_KEY][rnc_key] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_RELNODO_GRP_KEY][rnc_key] << Irma.sistema_regola_adj_x_t(rrr[:rg]) unless rrr[:rg].nil? || rrr[:rg] == 'MULTIVALUE'
      end
      # mv
      xxx = db.fetch("select #{campo_id}, id_tecrel, id_rel_rnc, to_char(regola_calcolo) rg, posizione from #{tabella_base}_mv_rnc where length(NVL(regola_calcolo, 'dummy')) < 4000").all
      xxx += db.fetch("select #{campo_id}, id_tecrel, id_rel_rnc, regola_calcolo rg, posizione from #{tabella_base}_mv_rnc where length(regola_calcolo) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        next unless multi_info[rrr[campo_id.to_sym]] == MULTI
        rnc_key = @rnc["#{rrr[:id_tecrel]}__#{rrr[:id_rel_rnc]}"]
        hash_regole_calcolo[rrr[campo_id.to_sym]] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_RELNODO_GRP_KEY] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_RELNODO_GRP_KEY][rnc_key] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][RC_RELNODO_GRP_KEY][rnc_key][rrr[:posizione].to_i - 1] = Irma.sistema_regola_adj_x_t(rrr[:rg])
      end
      # hash_regole_calcolo.each {|k,v| puts "XXXXXXXX #{k}: ### #{v[DEFAULT_KEY]} ###"}
    end

    def regole_calcolo_ae_base(tabella, campo_id, multi_info, hash_regole_calcolo)
      xxx = db.fetch("select #{campo_id}, id_rete, to_char(regola_calcolo) rg from #{tabella} where length(NVL(regola_calcolo, 'dummy')) < 4000").all
      xxx += db.fetch("select #{campo_id}, id_rete, regola_calcolo rg from #{tabella} where length(regola_calcolo) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        hash_regole_calcolo[rrr[campo_id.to_sym]] ||= { rete: rrr[:id_rete], regole: {} }
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_DEFAULT_GRP_KEY] ||= {}
        next unless multi_info[rrr[campo_id.to_sym]] == NON_MULTI
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_DEFAULT_GRP_KEY][DEFAULT_KEY] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_DEFAULT_GRP_KEY][DEFAULT_KEY] << Irma.sistema_regola_adj_x_t(rrr[:rg]) unless rrr[:rg].nil? || rrr[:rg] == MULTIVALORE
      end
      # meta_entita_ae_mv
      if tabella.start_with?('meta_entita')
        tabella_mv = 'meta_entita_ae_mv'
        campo_rg = 'regola_di_calcolo'
      else
        tabella_mv = 'meta_parametri_mv_ae'
        campo_rg = 'regola_calcolo'
      end
      xxx = db.fetch("select #{campo_id}, to_char(#{campo_rg}) rg, posizione from #{tabella_mv} where length(NVL(#{campo_rg}, 'dummy')) < 4000").all
      xxx += db.fetch("select #{campo_id}, #{campo_rg} rg, posizione from #{tabella_mv} where length(#{campo_rg}) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        next unless multi_info[rrr[campo_id.to_sym]] == MULTI
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_DEFAULT_GRP_KEY][DEFAULT_KEY] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_DEFAULT_GRP_KEY][DEFAULT_KEY][rrr[:posizione].to_i - 1] = Irma.sistema_regola_adj_x_t(rrr[:rg])
      end
    end

    #  RC_VENDOR_GRP_KEY = 'rc_vendor'.freeze
    #  RC_VENDORREL_GRP_KEY = 'rc_vendor_release'.freeze
    def regole_calcolo_ae_rc(tabella, campo_id, multi_info, hash_regole_calcolo)
      w_rg_m = "length(NVL(regola_calcolo, 'dummy')) < 4000"
      w_rgdt_m = "length(NVL(regola_calcolo_default_tec, 'dummy')) < 4000"
      w_rg_mm = 'length(regola_calcolo) >= 4000'
      w_rgdt_mm = 'length(regola_calcolo_default_tec) >= 4000'
      from = "from #{tabella}"
      select = "select #{campo_id}, id_tecrel, "
      q1 = "#{select} to_char(regola_calcolo) rg, to_char(regola_calcolo_default_tec) rgdt #{from} where #{w_rg_m} and #{w_rgdt_m}"
      q2 = "#{select} regola_calcolo, to_char(regola_calcolo_default_tec) rgdt #{from} where #{w_rg_mm} and #{w_rgdt_m}"
      q3 = "#{select} to_char(regola_calcolo), regola_calcolo_default_tec rgdt #{from} where #{w_rg_m} and #{w_rgdt_mm}"
      q4 = "#{select} regola_calcolo, regola_calcolo_default_tec rgdt #{from} where #{w_rg_mm} and #{w_rgdt_mm}"
      xxx = db.fetch(q1).all
      xxx += db.fetch(q2).all
      xxx += db.fetch(q3).all
      xxx += db.fetch(q4).all
      xxx.each do |rrr|
        sistema_record(rrr)
        next unless multi_info[rrr[campo_id.to_sym]] == NON_MULTI
        if rrr[:rg]
          rc_grp = RC_VENDORREL_GRP_KEY
          rc_key = @vendor_release_rckey_per_tecrel[rrr[:id_tecrel]] # TODO: sistemare ricerca regole di calcolo !!! vr.full_descr
          rc_rg = rrr[:rg]
        else
          rc_grp = RC_VENDOR_GRP_KEY
          rc_key = @vendor_rckey_per_tecrel[rrr[:id_tecrel]] # TODO: sistemare ricerca regole di calcolo !!! vr.vendor.sigla
          rc_rg = rrr[:rgdt]
        end
        unless hash_regole_calcolo[rrr[campo_id.to_sym]]
          out_msg_con_log('warn', "Ignorata regola di calcolo in #{tabella} (#{rrr.inspect}) perche' #{rrr[campo_id.to_sym]} non e' un parametro/entita con regole di calcolo come adiacenza esterna")
          next
        end
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][rc_grp] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][rc_grp][rc_key] ||= []
        cond = rc_rg.nil? || rc_rg == 'MULTIVALUE' || !hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][rc_grp][rc_key].empty?
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][rc_grp][rc_key] << Irma.sistema_regola_adj_x_t(rc_rg) unless cond
      end
      # mv
      tabella_mv = tabella.gsub('_ae', '_mv_ae')
      xxx = db.fetch("select #{campo_id}, id_tecrel, fl_default, to_char(regola_calcolo) rg, posizione from #{tabella_mv} where length(NVL(regola_calcolo, 'dummy')) < 4000").all
      xxx += db.fetch("select #{campo_id}, id_tecrel, fl_default, regola_calcolo rg, posizione from #{tabella_mv} where length(regola_calcolo) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        next unless multi_info[rrr[campo_id.to_sym]] == MULTI
        if rrr[:fl_default] == 1
          rc_grp = RC_VENDOR_GRP_KEY
          rc_key = @vendor_rckey_per_tecrel[rrr[:id_tecrel]]
        else
          rc_grp = RC_VENDORREL_GRP_KEY
          rc_key = @vendor_release_rckey_per_tecrel[rrr[:id_tecrel]]
        end
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][rc_grp] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][rc_grp][rc_key] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][rc_grp][rc_key][rrr[:posizione].to_i - 1] = Irma.sistema_regola_adj_x_t(rrr[:rg])
      end
    end

    def regole_calcolo_ae_rnc(tabella, campo_id, multi_info, hash_regole_calcolo)
      tabella_base = tabella.split('_')[0, 2].join('_')
      xxx = db.fetch("select #{campo_id}, id_tecrel, id_rel_rnc, to_char(regola_calcolo) rg from #{tabella} where length(regola_calcolo) < 4000").all
      xxx += db.fetch("select #{campo_id}, id_tecrel, id_rel_rnc, regola_calcolo rg from #{tabella} where length(regola_calcolo) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        rnc_key = @rnc["#{rrr[:id_tecrel]}__#{rrr[:id_rel_rnc]}"]
        unless rnc_key
          out_msg_con_log('warn', "Ignorata regola di calcolo in #{tabella} (#{rrr.inspect}) perche' non corrisponde a nessun RNC valido")
          next
        end
        hash_regole_calcolo[rrr[campo_id.to_sym]] ||= { rete: rrr[:id_rete], regole: {} }
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_RELNODO_GRP_KEY] ||= {}
        next unless multi_info[rrr[campo_id.to_sym]] == NON_MULTI
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_RELNODO_GRP_KEY][rnc_key] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_RELNODO_GRP_KEY][rnc_key] << Irma.sistema_regola_adj_x_t(rrr[:rg]) unless rrr[:rg].nil? || rrr[:rg] == 'MULTIVALUE'
      end
      # mv
      xxx = db.fetch("select #{campo_id}, id_tecrel, id_rel_rnc, to_char(regola_calcolo) rg, posizione from #{tabella_base}_mv_rnc_ae where length(NVL(regola_calcolo, 'dummy')) < 4000").all
      xxx += db.fetch("select #{campo_id}, id_tecrel, id_rel_rnc, regola_calcolo rg, posizione from #{tabella_base}_mv_rnc_ae where length(regola_calcolo) >= 4000").all
      xxx.each do |rrr|
        sistema_record(rrr)
        next unless multi_info[rrr[campo_id.to_sym]] == MULTI
        rnc_key = @rnc["#{rrr[:id_tecrel]}__#{rrr[:id_rel_rnc]}"]
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_RELNODO_GRP_KEY] ||= {}
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_RELNODO_GRP_KEY][rnc_key] ||= []
        hash_regole_calcolo[rrr[campo_id.to_sym]][:regole][RC_RELNODO_GRP_KEY][rnc_key][rrr[:posizione].to_i - 1] = Irma.sistema_regola_adj_x_t(rrr[:rg])
      end
    end

    def regole_calcolo_meta_parametri
      meta_parametri_multi
      regole_calcolo_base('meta_parametri', 'id_m_param', @meta_parametri_multi, @regole_calcolo_p)
      regole_calcolo_rnc('meta_parametri_rnc', 'id_m_param', @meta_parametri_multi, @regole_calcolo_p)
      regole_calcolo_ae_base('meta_parametri_ae', 'id_m_param', @meta_parametri_multi, @regole_calcolo_p_ae)
      regole_calcolo_ae_rnc('meta_parametri_rnc_ae', 'id_m_param', @meta_parametri_multi, @regole_calcolo_p_ae)
      regole_calcolo_ae_rc('meta_parametri_rc_ae', 'id_m_param', @meta_parametri_multi, @regole_calcolo_p_ae)
    end

    def regole_calcolo_meta_entita
      meta_entita_multi
      regole_calcolo_base('meta_entita', 'id_m_entita', @meta_entita_multi, @regole_calcolo)
      regole_calcolo_rnc('meta_entita_rnc', 'id_m_entita', @meta_entita_multi, @regole_calcolo)
      regole_calcolo_ae_base('meta_entita_ae', 'id_m_entita', @meta_entita_multi, @regole_calcolo_ae)
      regole_calcolo_ae_rnc('meta_entita_rnc_ae', 'id_m_entita', @meta_entita_multi, @regole_calcolo_ae)
      regole_calcolo_ae_rc('meta_entita_rc_ae', 'id_m_entita', @meta_entita_multi, @regole_calcolo_ae)
    end

    def classi_meta_parametri
      campo_id = 'id_m_param'
      rec = db.fetch("select distinct #{campo_id} from rel_classe_param")
      rec.each do |mp|
        sistema_record(mp)
        @map_classi_meta_parametri[mp[campo_id.to_sym]] = [CLASSE_MP]
      end
    end

    def record_pr_per_loader_irma1(record, tipo)
      # columns = tipo == 'entita' ? PR_COLUMNS_ENTITA_NEW : PR_COLUMNS_PARAMETRI_NEW
      # columns_json = tipo == 'entita' ? PR_COLUMNS_ENTITA_JSON : PR_COLUMNS_PARAMETRI_JSON
      columns = tipo == 'entita' ? @col_meta_entita : @col_meta_parametro
      columns_json = tipo == 'entita' ? @col_json_meta_entita : @col_json_meta_parametro
      pezzi = []
      columns.each { |k| pezzi << (columns_json.member?(k) ? record[k.to_sym].to_json : record[k.to_sym].to_s) }
      pezzi.join(PR_METAMODELLO_FIELD_SEP)
    end

    def export_metamodello_irma1
      @rnc = {}
      db[:release_rnc].select(:id_tecrel, :id_rel_rnc, :desc_rel_rnc).each do |rrr|
        # puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX #{rrr.inspect}"
        sistema_record(rrr)
        @rnc["#{rrr[:id_tecrel]}__#{rrr[:id_rel_rnc]}"] = rrr[:desc_rel_rnc]
      end
      # puts "XXXXXXXXXXXX #{@rnc.inspect}"
      #------------------------------------
      @vendor_rckey_per_tecrel = {}
      @vendor_release_rckey_per_tecrel = {}
      # --- workaround anag_rete
      xxx = db.fetch('select b.id_tecrel, b.id_rete, b.desc_rel, b.desc_tec from tecrel b').all
      xxx.each do |record|
        @vendor_rckey_per_tecrel[record[:id_tecrel]] = record[:desc_tec]
        @vendor_release_rckey_per_tecrel[record[:id_tecrel]] = compact_descr_vr([record[:desc_rel], record[:desc_tec], @map_rete_id_nome[record[:id_rete].to_s]])
      end
      # ---
      # xxx = db.fetch('select b.id_tecrel, a.rete, b.desc_rel, b.desc_tec from anag_rete a, tecrel b where b.id_rete = a.id_rete').all
      # xxx.each do |record|
      #   @vendor_rckey_per_tecrel[record[:id_tecrel]] = compact_descr_vr([record[:desc_rel], record[:desc_tec], record[:rete]])
      #   @vendor_release_rckey_per_tecrel[record[:id_tecrel]] = record[:desc_tec]
      # end
      #------------------------------------
      @regole_calcolo = {}
      @regole_calcolo_ae = {}
      regole_calcolo_meta_entita

      @regole_calcolo_p = {}
      @regole_calcolo_p_ae = {}
      regole_calcolo_meta_parametri

      #------------------------------------
      @tipo_valore_entita = {}
      @tipo_valore_parametro = {}
      tipo_valore

      #------------------------------------
      @np_per_extra_name = {}
      np_per_extra_name

      @map_classi_meta_parametri = {}
      classi_meta_parametri
    end

    def interpreta_fase_calcolo(meta_entita_ref_irma1)
      return [nil, nil, 0] if meta_entita_ref_irma1.nil?
      case meta_entita_ref_irma1.to_s
      when 'PI'
        [FASE_CALCOLO_PI, nil, TIPO_ADIACENZA_NESSUNA]
      when 'PI_ADJ', 'PI_GADJ', 'PI_LADJ', 'PI_UADJ'
        [FASE_CALCOLO_ADJ, nil, TIPO_ADIACENZA_INTERNA]
      else
        [FASE_CALCOLO_REF, meta_entita_ref_irma1, TIPO_ADIACENZA_NESSUNA]
      end
    end

    # rubocop:disable Metrics/LineLength
    def export_meta_entita(file:, id_vr:, terna:, map_id_meta_entita:)
      start_date = Time.now
      n = 0
      map_np_id = {} # naming_path => n

      File.open(file, 'w') do |fd|
        fd.puts(hdr_da_colonne(@col_meta_entita))
        # puts "XXXXXXXXXXX #{n}"
        db[:meta_entita].select(:id_m_entita, :desc_entita, :id_tecrel, :meta_entita, :naming_path, :codice_tipo, :meta_entita_ref, :operazioni_ammesse).where(id_tecrel: id_vr).order_by(:naming_path).each do |rr|
          begin
            sistema_record(rr)
            new_record = {}
            new_record[:nome] = rr[:meta_entita]
            new_record[:descr] = rr[:desc_entita]
            new_record[:naming_path] = rr[:naming_path]
            new_record[:created_at] = start_date.to_s
            new_record[:updated_at] = start_date.to_s
            new_record[:extra_name] = @np_per_extra_name[rr[:naming_path]] if @np_per_extra_name.keys.include?(rr[:naming_path])
            new_record[:vendor_release_id] = TAG_VENDOR_RELEASE
            new_record[:tipo] = @tipo_valore_entita[rr[:codice_tipo]]
            new_record[:versione] = '' # ???
            new_record[:operazioni_ammesse] = rr[:operazioni_ammesse]
            new_record[:fase_di_calcolo], new_record[:meta_entita_ref], new_record[:tipo_adiacenza] = interpreta_fase_calcolo(rr[:meta_entita_ref])
            new_record[:regole_calcolo] = @regole_calcolo[rr[:id_m_entita]]
            if @regole_calcolo_ae[rr[:id_m_entita]] && @regole_calcolo_ae[rr[:id_m_entita]][:regole] != { DEFAULT_KEY => [] }
              new_record[:rete_adj] = @regole_calcolo_ae[rr[:id_m_entita]][:rete]
              new_record[:regole_calcolo_ae] = @regole_calcolo_ae[rr[:id_m_entita]][:regole]
              new_record[:fase_di_calcolo] = FASE_CALCOLO_ADJ
              new_record[:tipo_adiacenza] |= TIPO_ADIACENZA_ESTERNA
            end

            if terna[1] == 'ERICSSON' && terna[2] == 'UMTS'
              aggiustamenti_mecontext(new_record)
            end

            pid = map_np_id[new_record[:naming_path].to_s.split(NAMING_PATH_SEP)[0..-2].join(NAMING_PATH_SEP)]
            new_record[:pid] = "#{TAG_FIRST_ME_ID} + #{pid}" if pid

            if new_record[:vendor_release_id] && new_record[:nome] && new_record[:naming_path] && new_record[:tipo]
              fd.puts(record_pr_per_loader_irma1(new_record, 'entita'))
              n += 1
              map_id_meta_entita[rr[:id_m_entita]] = n
              map_np_id[rr[:naming_path]] = n
            else
              out_msg_con_log('warn', "Export tabella 'meta_entita': scartato record #{rr.inspect}, #{new_record.inspect}")
            end
          rescue => e
            out_msg_con_log('error', "Export tabella 'meta_entita' fallito per il record #{rr}: #{e}")
            raise e
          end
        end
      end
      n
    end

    def export_meta_parametri(file:, id_vr:, map_id_meta_entita:)
      start_date = Time.now
      n = 0
      File.open(file, 'w') do |fd|
        fd.puts(hdr_da_colonne(@col_meta_parametro))
        db[:meta_parametri].select(:id_m_param, :id_m_entita, :nome_struct, :codice_tipo, :is_multi, :meta_param, :desc_param,
                                   :is_predefinito, :tobeexp, :is_obbligatorio, :is_restricted,
                                   :fl_forced).where(id_m_entita: db[:meta_entita].select(:id_m_entita).where(id_tecrel: id_vr)).each do |rr|
          begin
            sistema_record(rr)
            m_e_id = map_id_meta_entita[rr[:id_m_entita]]
            next unless m_e_id
            new_record = {}
            new_record[:descr] = rr[:desc_param]
            new_record[:meta_entita_id] = "#{TAG_FIRST_ME_ID} + #{m_e_id}"
            new_record[:nome] = rr[:meta_param]
            new_record[:nome_struttura] = rr[:nome_struct]
            new_record[:is_predefinito] = rr[:is_predefinito]
            new_record[:is_to_export] = rr[:tobeexp]
            new_record[:is_obbligatorio] = rr[:is_obbligatorio]
            new_record[:is_restricted] = rr[:is_restricted]
            new_record[:is_forced] = rr[:fl_forced]
            new_record[:created_at] = start_date.to_s
            new_record[:updated_at] = start_date.to_s
            new_record[:tags] = @map_classi_meta_parametri[rr[:id_m_param]]
            ismulti = (rr[:is_multi] == 1)
            if rr[:nome_struct].to_s != ''
              new_record[:is_multivalue] = false
              new_record[:is_multistruct] = ismulti
              new_record[:genere] = (ismulti ? META_PARAMETRO_GENERE_MULTI_STRUTTURATO_SEMPLICE : META_PARAMETRO_GENERE_STRUTTURATO_SEMPLICE)
              new_record[:full_name] = "#{rr[:nome_struct]}.#{rr[:meta_param]}"
            else
              new_record[:is_multivalue] = ismulti
              new_record[:is_multistruct] = false
              new_record[:genere] = (ismulti ? META_PARAMETRO_GENERE_MULTIVALORE : META_PARAMETRO_GENERE_SEMPLICE)
              new_record[:full_name] = rr[:meta_param]
            end
            new_record[:tipo] = @tipo_valore_parametro[rr[:codice_tipo]]
            new_record[:vendor_release_id] = TAG_VENDOR_RELEASE
            new_record[:regole_calcolo] = @regole_calcolo_p[rr[:id_m_param]]
            if @regole_calcolo_p_ae[rr[:id_m_param]] && @regole_calcolo_p_ae[rr[:id_m_param]][:regole] != { DEFAULT_KEY => [] }
              new_record[:rete_adj] = @regole_calcolo_p_ae[rr[:id_m_param]][:rete]
              new_record[:regole_calcolo_ae] = @regole_calcolo_p_ae[rr[:id_m_param]][:regole]
            end
            if new_record[:vendor_release_id] && new_record[:nome] && new_record[:meta_entita_id] && new_record[:tipo]
              fd.puts(record_pr_per_loader_irma1(new_record, 'PARAMETRO'))
              n += 1
            else
              out_msg_con_log('warn', "Export tabella 'meta_parametro': scartato record #{rr.inspect}, #{new_record.inspect}")
            end
          rescue => e
            out_msg_con_log('error', "Export tabella 'meta_parametro' fallito per il record #{rr}: #{e}")
            raise e
          end
        end
      end
      n
    end
  end
end
