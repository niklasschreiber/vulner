# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini, G. Cristelli
#
# Creation date: 20160401
#

require_relative 'segnalazioni_per_funzione'
require_relative 'basic_importer'
require_relative 'basic_formatter'

module Irma
  #
  module Funzioni
    #
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ClassLength, Metrics/ModuleLength
    module ImportExportAdrnUtil
      def opzioni_con_segnalazioni(opts)
        { account: Db::Account.first(id: opts[:account_id]), filtro: { vendor_release_id: opts[:id_vendor_release] }, attivita_id: opts[:attivita_id] }
      end

      PR_COLUMNS_HDR_CHAR = '#'.freeze
      PR_COLUMNS_HDR_SEP = ','.freeze
      def colonne_da_hdr(input_line)
        return nil unless (input_line || '').start_with?(PR_COLUMNS_HDR_CHAR) # non e' un header
        in_ln = input_line[1..-1]
        in_ln.chomp!
        in_ln.split(PR_COLUMNS_HDR_SEP).map { |x| x.delete(' ') }.map(&:to_sym)
      end

      def hdr_da_colonne(array_col)
        "#{PR_COLUMNS_HDR_CHAR}#{array_col.join(PR_COLUMNS_HDR_SEP)}"
      end

      def colonne_meta_entita
        Db::MetaEntita.columns - [:id, :tipo_oggetto] # :tipo_oggetto per problemi di not-null value...TDB: da sistemare
      end

      def colonne_json_meta_entita
        colonne_meta_entita & Db::MetaEntita.columns.select { |ccc| Db::MetaEntita.db_schema[ccc][:type] == :json }
      end

      def colonne_meta_parametro
        Db::MetaParametro.columns - [:id, :is_prioritario, :is_update_on_create]
      end

      def colonne_json_meta_parametro
        colonne_meta_entita & Db::MetaParametro.columns.select { |ccc| Db::MetaParametro.db_schema[ccc][:type] == :json }
      end

      def check_id_vendor_release(idid, is_fisico: false)
        unless idid && idid.to_i.to_s == idid.to_s
          logger.warn "L'id_vendor_release specificato (#{idid}) non e' un valore corretto"
          return nil
        end
        id_vr = idid.to_i
        terna = determina_terna_da_idvr(id_vr, is_fisico)
        unless terna
          logger.warn "L'id_vendor_release specificato (#{id_vr}) non corrisponde a nessuna vendor_release su irma2"
          return nil
        end
        [id_vr, terna]
      end

      def crea_dir_zip(dir, terna)
        dir_zip = File.join(dir, nome_dir_zip(terna))
        FileUtils.rm_rf(dir_zip) if File.exist?(dir_zip)
        FileUtils.mkdir_p(dir_zip)
        dir_zip
      end

      def determina_terna_da_idvr(idvr, is_fisico)
        x = Db::VendorRelease.first(id: idvr) unless is_fisico
        x = Db::VendorReleaseFisico.first(id: idvr) if is_fisico
        # x.nil? ? nil : [x.descr, x.vendor.nome, x.rete.nome]
        x.nil? ? nil : x.terna
      end

      def deduci_terna_da_file_zip(file_zip)
        File.basename(file_zip || '').sub('.zip', '').split(SEP_DIR_ZIP)
      end

      def determina_idvrf_da_rel_ven(release_descr, vendor)
        vid = Db::Vendor.first(nome: vendor)
        unless vid
          logger.warn "Il vendor specificato nel filtro_release (release: #{release_descr}, vendor: #{vendor}) non corrisponde a nessun vendor anagrafato in irma2"
          return nil
        end
        id_vendor = vid.id
        x = Db::VendorReleaseFisico.first(descr: release_descr, vendor_id: id_vendor)
        unless x
          logger.warn "Il filtro_release (release: #{release_descr}, vendor: #{vendor}) non corrisponde a nessuna vendor_release_fisico"
          return nil
        end
        x.id
      end

      def determina_idvr_da_terna(release_descr, vendor, rete) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # transitorio per gestire import meta_modello 5G
        rete = '5G' if (release_descr || '').index('5G')

        rid = Db::Rete.first(nome: rete)
        unless rid
          logger.warn "La rete specificata nel filtro_release (release: #{release_descr}, vendor: #{vendor}, rete: #{rete}) non corrisponde a nessuna rete anagrafata in irma2"
          return nil
        end
        id_rete = rid.id
        vid = Db::Vendor.first(nome: vendor)
        unless vid
          logger.warn "Il vendor specificato nel filtro_release (release: #{release_descr}, vendor: #{vendor}, rete: #{rete}) non corrisponde a nessun vendor anagrafato in irma2"
          return nil
        end
        id_vendor = vid.id
        x = Db::VendorRelease.first(descr: release_descr, vendor_id: id_vendor, rete_id: id_rete)
        if x.nil? && id_rete == RETE_5G # transitorio per gestire import meta_modello 5G
          new_rel_descr = release_descr.chomp('_5G')
          x = Db::VendorRelease.first(descr: new_rel_descr, vendor_id: id_vendor, rete_id: id_rete) if x.nil? && id_rete == RETE_5G
        end
        unless x
          logger.warn "Il filtro_release (release: #{release_descr}, vendor: #{vendor}, rete: #{rete}) non corrisponde a nessuna vendor_release"
          return nil
        end
        x.id
      end

      def check_id_vr(idid)
        idid && idid.to_i.to_s == idid.to_s
      end

      # terna e' un array di 3 elementi non nulli e non stringhe vuote
      def check_terna(terna)
        terna && terna.select { |x| x && !x.to_s.empty? }.count == 3
      end

      def check_release_vendor(rel_ven)
        rel_ven && rel_ven.select { |x| x && !x.to_s.empty? }.count == 2
      end

      def check_id_file_zip(file_z)
        file_z && File.file?(file_z)
      end

      def check_import_info(terna:, file_zip:, vr_id:)
        check_1 = check_terna(terna)
        logger.warn "La terna '#{descr_terna(terna)}' non e' corretta" unless check_1
        check_2 = check_id_vr(vr_id)
        logger.warn "L'id vendor release '#{vr_id}' non e' corretto" unless check_2
        check_3 = check_id_file_zip(file_zip)
        logger.warn "Il file zip per import '#{file_zip}' non e' corretto" unless check_3
        check_1 && check_2 && check_3
      end

      def nome_dir_zip(terna)
        terna.join(SEP_DIR_ZIP)
      end

      def compact_descr_vr(terna)
        terna.join(SEP_VR_TERNA)
      end

      def comprimi_e_sposta_dirzip(dirzip)
        zip_file = "#{dirzip}.zip"
        FileUtils.rm_f(zip_file) if File.exist?(zip_file)
        `cd \"#{File.dirname(dirzip)}\" && zip -r \"#{File.basename(zip_file)}\" \"#{File.basename(dirzip)}\" 2>&1`
        err = $CHILD_STATUS.exitstatus
        raise "Errore nella compressione della directory #{dirzip} (#{err})" unless err.zero?

        # move artifact into out_dir if absolute, otherwise on shared
        target_path = File.join(@out_dir_root, File.basename(zip_file))
        Pathname.new(@out_dir_root).relative? ? shared_post_file(zip_file, target_path) : FileUtils.mv(zip_file, target_path)
        target_path
      end
    end
    #
    class ExportAdrn # rubocop:disable Metrics/ClassLength
      include SegnalazioniPerFunzione
      include ImportExportAdrnUtil
      include SharedFs::Util

      attr_reader :logger, :log_prefix

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'Export adrn'
        @tmp_dir_root = opts[:tmp_dir_root]
        @out_dir_root = opts[:out_dir_root]
        @col_meta_entita = colonne_meta_entita
        @col_meta_parametro = colonne_meta_parametro
        @col_json_meta_entita = colonne_json_meta_entita
        @col_json_meta_parametro = colonne_json_meta_parametro
      end

      def con_lock(key: LOCK_KEY_META_MODELLO, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def esegui(**opts)
        res = { artifacts: [] }
        funzione = Db::Funzione.get_by_pk(FUNZIONE_EXPORT_ADRN)
        con_lock(funzione: funzione.nome, account_id: opts[:account_id], enable: opts.fetch(:lock, true), logger: logger, log_prefix: log_prefix, **opts) do |_locks|
          con_segnalazioni(funzione: funzione, **opzioni_con_segnalazioni(opts)) do
            @map_id_meta_entita_per_vr = {}
            id_vr = opts[:id_vendor_release]
            terna = opts[:terna_vendor_release]
            descr_vr = opts[:descr_vr]
            begin
              xxx = export_per_vr(id_vr, terna, descr_vr)
              res[:artifacts] = xxx[:target_path]
              [:num_meta_entita, :num_meta_parametri].each { |k| res[k] = xxx[k] }
            rescue => e
              nuova_segnalazione(TIPO_SEGNALAZIONE_EXPORT_ADRN_DATI_EXPORT_VR_FALLITO, descr_vr: descr_vr, err_msg: e)
              next
            end
            res
          end # con_segnalazioni
        end # con_lock
      end
      #------------------------------------------------

      def export_per_vr(id_vr, terna, descr_vr)
        res = { target_path: nil, num_meta_parametri: 0, num_meta_entita: 0 }
        dir_zip = crea_dir_zip(@tmp_dir_root, terna)
        @map_id_meta_entita_per_vr[id_vr] = {}
        #---------------------------
        start_time_export = Time.now
        logger.info "Inizio export dati meta_modello da irma2 per vendor release '#{descr_vr}'"
        begin
          Db.connection.transaction do
            res[:num_meta_entita] = export_meta_entita_2(dir_zip, id_vr, start_time_export)
            res[:num_meta_parametri] = export_meta_parametri_2(dir_zip, id_vr, start_time_export)
          end
        rescue => e
          logger.error "Export dati meta_modello da irma2 per vendor release #{descr_vr} fallito (#{e}) in #{(Time.now - start_time_export).round(1)} secondi"
          raise
        end
        logger.info "Export dati meta_modello da irma2 per vendor release '#{descr_vr}', terminato con successo in #{(Time.now - start_time_export).round(1)} secondi"
        res[:target_path] = comprimi_e_sposta_dirzip(dir_zip)
        res
      end

      def record_pr_per_loader(record, tipo)
        # columns = tipo == 'entita' ? PR_COLUMNS_ENTITA_NEW : PR_COLUMNS_PARAMETRI_NEW
        # columns_json = tipo == 'entita' ? PR_COLUMNS_ENTITA_JSON : PR_COLUMNS_PARAMETRI_JSON
        columns = tipo == 'entita' ? @col_meta_entita : @col_meta_parametro
        columns_json = tipo == 'entita' ? @col_json_meta_entita : @col_json_meta_parametro
        pezzi = []
        columns.each do |k|
          ppp = if columns_json.member?(k)
                  record[k.to_sym].to_json.gsub('\"', '\\\\\"').gsub('\n', '\\\\\n').gsub('\t', '\\\\\t')
                else
                  record[k.to_sym].to_s.gsub("\n", '\\n').gsub('"', '\"').gsub("\t", '\\t')
                end
          pezzi << ppp
        end
        pezzi.join(PR_METAMODELLO_FIELD_SEP)
      end

      def export_meta_entita_2(dir_zip, id_vr, created_at_date)
        created_at_date_s = created_at_date.to_s
        n = 0
        map_np_id = {}
        File.open(File.join(dir_zip, NOME_FILE_EXPORT_ME), 'w') do |fd|
          fd.puts(hdr_da_colonne(@col_meta_entita))
          Db::MetaEntita.where(vendor_release_id: id_vr).order_by(:naming_path).each do |rr|
            new_record = {}
            (Db::MetaEntita.columns - [:id, :vendor_release_id, :created_at, :updated_at]).each do |col|
              new_record[col] = rr[col]
            end
            new_record[:vendor_release_id] = TAG_VENDOR_RELEASE
            new_record[:created_at] = created_at_date_s
            new_record[:updated_at] = created_at_date_s
            pid = map_np_id[Db::MetaEntita.naming_path_padre(new_record[:naming_path])]
            new_record[:pid] = "#{TAG_FIRST_ME_ID} + #{pid}" if pid
            fd.puts(record_pr_per_loader(new_record, 'entita'))
            n += 1
            @map_id_meta_entita_per_vr[id_vr][rr.id] = n
            map_np_id[rr[:naming_path]] = n
          end
        end
        n
      end

      def export_meta_parametri_2(dir_zip, id_vr, created_at_date)
        n = 0
        File.open(File.join(dir_zip, NOME_FILE_EXPORT_MP), 'w') do |fd|
          fd.puts(hdr_da_colonne(@col_meta_parametro))
          Db::MetaParametro.where(vendor_release_id: id_vr).each do |rr|
            m_e_id = @map_id_meta_entita_per_vr[id_vr][rr.meta_entita_id]
            next unless m_e_id

            new_record = {}
            (Db::MetaParametro.columns - [:id, :meta_entita_id, :vendor_release_id, :created_at, :updated_at]).each do |col|
              new_record[col] = rr[col]
            end
            new_record[:meta_entita_id] = "#{TAG_FIRST_ME_ID} + #{m_e_id}"
            new_record[:vendor_release_id] = TAG_VENDOR_RELEASE
            new_record[:created_at] = created_at_date
            new_record[:updated_at] = created_at_date
            fd.puts(record_pr_per_loader(new_record, 'PARAMETRO'))
            n += 1
          end
        end
        n
      end
      #------------------------------------------------
    end

    class ImportAdrn # rubocop:disable Metrics/ClassLength
      include SegnalazioniPerFunzione
      include ImportExportAdrnUtil

      attr_reader :logger, :log_prefix
      attr_reader :account_id

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'Import adrn'
        @tmp_dir = opts[:tmp_dir]
        @account_id = opts[:account_id]
      end

      def con_lock(key: LOCK_KEY_META_MODELLO, mode: LOCK_MODE_WRITE, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def esegui(**opts)
        res = {}
        funzione = Db::Funzione.get_by_pk(FUNZIONE_IMPORT_ADRN)
        con_lock(funzione: funzione.nome, account_id: opts[:account_id], enable: opts.fetch(:lock, true), logger: logger, log_prefix: log_prefix, **opts) do |_locks|
          con_segnalazioni(funzione: funzione, **opzioni_con_segnalazioni(opts)) do
            import_res = res[opts[:vr_descr]] = import_adrn_per_vr(opts[:id_vendor_release], opts[:descr_vr], opts[:file_zip])
            raise import_res[:errore] if import_res[:errore] && opts[:raise_error]
            res[opts[:vr_descr]] = import_res
          end # con_segnalazioni
          res
        end # con_lock
        res
      end

      def unzip_file(file_z) # file_z full path
        FileUtils.cp(file_z, tmp_file_z = File.join(@tmp_dir, File.basename(file_z)))
        `cd \"#{@tmp_dir}\" && unzip \"#{File.basename(file_z)}\" 2>&1`
        err = $CHILD_STATUS.exitstatus
        raise "Errore nell'unzip del file #{tmp_file_z} (#{err})" unless err.zero?
        unzipped_dir = tmp_file_z.sub(/.zip$/, '')
        unless File.directory?(unzipped_dir)
          unzipped_dir = (Dir["#{@tmp_dir}/*"] - [tmp_file_z]).first
          raise 'Directory dei file di loader non presente nel file zip' unless File.directory?(unzipped_dir)
        end
        unzipped_dir
      end

      def load_meta_modello(nome_dir, id_vr, id_me_0) # rubocop:disable Metrics/CyclomaticComplexity
        res = { meta_entita: 0, meta_parametri: 0 }
        bbb = binding
        bbb.local_variable_set(TAG_VENDOR_RELEASE, id_vr)
        valore_id_vr = bbb.eval TAG_VENDOR_RELEASE
        bbb.local_variable_set(TAG_FIRST_ME_ID, id_me_0)
        bbb.eval TAG_FIRST_ME_ID

        reg_exp = "(#{TAG_FIRST_ME_ID}) \\+ ([0-9]+)"

        # --- meta_entita
        le_colonne = PR_COLUMNS_ENTITA_NEW
        first_line = nil

        File.open(File.join(nome_dir, NOME_FILE_EXPORT_ME), 'r') do |fd_in|
          first_line = fd_in.gets
          col = colonne_da_hdr(first_line)
          if col
            le_colonne = col
            first_line = nil
          end
          Db::Model.db.copy_into(:meta_entita, columns: le_colonne, options: PR_METAMODELLO_OPTIONS) do
            line = first_line || fd_in.gets
            next unless line
            first_line = nil
            res[:meta_entita] += 1
            tmp_line = Irma.sistema_regola_adj_x_t(line)
            ERB.new(tmp_line.gsub(/#{TAG_VENDOR_RELEASE}/, valore_id_vr).gsub(/#{reg_exp}/, '<%= \\1 + \\2 %>'), 4).result(bbb)
          end
        end

        # --- meta_parametri
        le_colonne = PR_COLUMNS_PARAMETRI_NEW
        first_line = nil
        File.open(File.join(nome_dir, NOME_FILE_EXPORT_MP), 'r') do |fd_in|
          first_line = fd_in.gets
          col = colonne_da_hdr(first_line)
          if col
            le_colonne = col
            first_line = nil
          end

          Db::Model.db.copy_into(:meta_parametri, columns: le_colonne, options: PR_METAMODELLO_OPTIONS) do
            line = first_line || fd_in.gets
            next unless line
            first_line = nil
            res[:meta_parametri] += 1
            tmp_line = Irma.sistema_regola_adj_x_t(line)
            ERB.new(tmp_line.gsub(/#{TAG_VENDOR_RELEASE}/, valore_id_vr).gsub(/#{reg_exp}/, '<%= \\1 + \\2 %>'), 4).result(bbb)
          end
        end
        res
      end

      def import_adrn_per_vr(id_vr, descr_vr, file_zip)
        ret = { esito: nil }
        msg = "per vendor_release '#{descr_vr}' (id #{id_vr}) da file #{file_zip}"
        logger.info "Inizio import dati meta_modello #{msg}"
        begin
          tmp_dir_data = unzip_file(file_zip)
          Db.connection.transaction do
            audit_extra_info = {
              account_id: @account_id,
              multipla: false,
              sorgente: AUDIT_SORGENTE_IMPORT_LOADER
            }
            Db::MetaParametro.where(vendor_release_id: id_vr).each do |new_obj|
              new_obj.destroy_with_audit(audit_extra_info: audit_extra_info)
            end
            Db::MetaEntita.where(vendor_release_id: id_vr).reverse(:naming_path).each do |new_obj|
              new_obj.destroy_with_audit(audit_extra_info: audit_extra_info)
            end
            seq_info = Db.connection.fetch('select last_value, is_called from meta_entita_id_seq').first
            id_me_0 = seq_info[:is_called] ? seq_info[:last_value] : seq_info[:last_value] - 1
            ret.update(load_meta_modello(tmp_dir_data, id_vr, id_me_0))
            [Db::MetaEntita, Db::MetaParametro].each do |classe|
              next unless classe.audit_enabled?
              classe.where(vendor_release_id: id_vr).each do |new_obj|
                new_obj.setta_audit_info(audit_extra_info)
                new_obj.audit_in_hook(AUDIT_META_ENTITA_OPERAZIONE_CREATE)
              end
            end
          end
          [Db::MetaparametroUpdateOnCreate, Db::MetaparametroSecondario].each { |t| t.imposta_metaparametri(id_vendor_release: id_vr, mm_fisico: false) }
          imposta_parametri_dchno(id_vr)
          imposta_fase_alias(id_vr)
        rescue => e
          ret[:errore] = e.message + e.backtrace.to_s
        end
        if ret[:errore]
          ret[:esito] = 'KO'
          logger.error "Import dati metamodello #{msg} fallito (#{ret[:errore]}) in #{ret[:durata]} secondi"
          nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_ADRN_DATI_IMPORT_VR_FALLITO, descr_vr: descr_vr, err_msg: ret[:errore])
        else
          ret[:esito] = 'OK'
          logger.info "Import dati metamodello #{msg} terminato con successo in #{ret[:durata]} secondi"
        end
        ret
      end

      def imposta_parametri_dchno(id_vr) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        vr = Db::VendorRelease.get_by_pk(id_vr)
        file_csv = File.join((Irma.get_env('HOME') || '/tmp'), 'csv', 'parametri_dchno.csv')
        file_csv = File.join(__dir__, 'csv', 'parametri_dchno.csv') unless File.exist?(file_csv)
        raise 'File per impostazione parametri dchno non trovato' unless File.exist?(file_csv)
        File.readlines(file_csv).each do |l|
          next if l.empty?
          r, v, np, p, rc = l.chomp.split(',')
          next if r != vr.rete.nome || v != vr.vendor.nome
          next if vr.descr != 'RC17B' && vr.descr != 'RC18B'
          me = Db::MetaEntita.where(vendor_release_id: id_vr, naming_path: np).first
          next if me.nil?
          rc_field = { 'rc_default' => { 'default' => [rc.to_s.tr('@', "\n")] } }
          Db::MetaParametro.where(nome: p, meta_entita_id: me.id).update(regole_calcolo: rc_field.to_json)
        end
      end

      def imposta_fase_alias(id_vr)
        vr = Db::VendorRelease.get_by_pk(id_vr)
        return unless vr.rete_id == RETE_UMTS && vr.vendor_id == VENDOR_ERICSSON
        ['SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataSystemFunctions;vsDataLm',
         'SubNetwork;SubNetwork;MeContext;ManagedElement;vsDataSystemFunctions;vsDataLm;vsDataFeatureState'].each do |np|
          Db::MetaEntita.where(vendor_release_id: id_vr, naming_path: np).update(fase_di_calcolo: FASE_CALCOLO_PI_ALIAS, meta_entita_ref: 'SubNetwork;SubNetwork;MeContext')
        end
      end
    end

    # ------------------------------------------------
    # --- FILE ADRN
    FILE_ADRN_FIXED_FIELDS = [
      FILE_ADRN_FIXED_FIELD_TIPO_OBJ = 'Tipo'.freeze,
      FILE_ADRN_FIXED_FIELD_NP = 'NamingPath'.freeze,
      FILE_ADRN_FIXED_FIELD_NOME = 'Nome'.freeze
    ].freeze
    FILE_ADRN_FIXED_FIELD_TIPO_OBJ_ENTITA = '0'.freeze
    FILE_ADRN_FIXED_FIELD_TIPO_OBJ_PARAMETRO = '1'.freeze

    FILE_ADRN_FIXED_FIELD_POS_TIPO_OBJ = FILE_ADRN_FIXED_FIELDS.index(FILE_ADRN_FIXED_FIELD_TIPO_OBJ)
    FILE_ADRN_FIXED_FIELD_POS_NP       = FILE_ADRN_FIXED_FIELDS.index(FILE_ADRN_FIXED_FIELD_NP)
    FILE_ADRN_FIXED_FIELD_POS_NOME     = FILE_ADRN_FIXED_FIELDS.index(FILE_ADRN_FIXED_FIELD_NOME)

    FILE_ADRN_FIXED_FIELD_COMMENTS = {
      FILE_ADRN_FIXED_FIELD_TIPO_OBJ => { text: "Valori possibili: \n #{FILE_ADRN_FIXED_FIELD_TIPO_OBJ_ENTITA} \t (Meta Entita) \n" \
                                                " #{FILE_ADRN_FIXED_FIELD_TIPO_OBJ_PARAMETRO} (Meta Parametro)", row2: 3, col2: 3 },
      FILE_ADRN_FIXED_FIELD_NP       => { text: "Per Meta Parametro: naming_path della Meta Entita relativa \n" \
                                                'per Meta Entita: naming_path della Meta Entita padre', row2: 4, col2: 6 },
      FILE_ADRN_FIXED_FIELD_NOME     => { text: "Nome di Meta Entita o di Meta Parametro, \n" \
                                                "(per Meta Parametro nome completo, \n" \
                                                'ovvero nome_struttura.nome_parametro nel caso di strutturati)', row2: 5, col2: 6 }
    }.freeze

    # ------------------------------------------------
    # AGGIORNAMENTO ADRN DA FILE
    class AggiornaAdrnDaFile
      include SegnalazioniPerFunzione
      include Irma::Funzioni::BasicImporter

      class TxtImporter < BasicImporter::TxtImporter
        # Trasforma linea letta da formato segnalazioni metamodello/incongruenze:
        #      NAMING_PATH OGGETTO ENTITA' PARAM_SEMPLICI PARAM_STRUTTURATI PARAM_MULTIVALORE PARAM_READ_ONLY
        # a formato file adrn:
        #      TIPO_OBJ NAMING_PATH NOME MULTI_VALORE MULTI_STRUTTURA
        def pre_processing_linea(line:, line_number:) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          mv = Db::MetaParametro::COLUMNS_FILE_ADRN_MAPPING[:is_multivalue]
          ms = Db::MetaParametro::COLUMNS_FILE_ADRN_MAPPING[:is_multistruct]
          if line_number == 1
            # header
            @hdr = FILE_ADRN_FIXED_FIELDS + [mv, ms]
          else
            record = []
            pezzi = line.split("\t")
            is_file_incongruenze = pezzi.count == 6
            is_mp = (pezzi[2] == '0')
            nome_struct = pezzi[4] if is_mp && pezzi[4] != '0'
            record[FILE_ADRN_FIXED_FIELD_POS_TIPO_OBJ] = (is_mp ? FILE_ADRN_FIXED_FIELD_TIPO_OBJ_PARAMETRO : FILE_ADRN_FIXED_FIELD_TIPO_OBJ_ENTITA)
            record[FILE_ADRN_FIXED_FIELD_POS_NP] = if is_file_incongruenze
                                                     Db::MetaEntita.naming_path_padre(pezzi[0])
                                                   else
                                                     pezzi[0]
                                                   end
            record[FILE_ADRN_FIXED_FIELD_POS_NOME] = if is_mp
                                                       [nome_struct, pezzi[1]].compact.join(TEXT_STRUCT_NAME_SEP)
                                                     else
                                                       pezzi[1]
                                                     end
            record[@hdr.index(mv)] = (pezzi[5] == '1').to_s
            record[@hdr.index(ms)] = (is_mp && nome_struct && record[@hdr.index(mv)] == 'true') ? 'true' : 'false' # gli strutturati multivalore di irma1 sono multistrutturati multivalore in irma2 !
            record
          end
        end
      end

      MM_ENTITA = :entita
      MM_PARAMETRI = :parametro

      attr_reader :logger, :log_prefix
      attr_reader :metamodello
      attr_reader :num_linea_header, :campi_header, :campi_header_entita, :campi_header_parametro, :cache_dati
      attr_reader :validatore_campi_me, :validatore_campi_mp

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'Aggiornamento adrn da file'
        @vendor_release = opts[:vendor_release]
        @account = opts[:account]
        @input_file = opts[:input_file]
        @operazione = opts[:operazione]
        @num_linea_header = opts[:num_linea_header] || 1
        @linea_num = -1
        # --
        @campi_header = []
        @campi_header_entita = []
        @campi_header_parametro = []
        @cache_dati = {}
        # --
        @audit_info = {
          account_id: @account.id,
          multipla: false,
          sorgente: AUDIT_SORGENTE_FILE
        }
        init_validatori
      end

      # ------------- validatori campi
      # rubocop:disable Style/RescueModifier
      def init_validatori # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        validatore_per_tipo = {
          integer: ->(val) { val.to_s.numeric? },
          string: ->(val) { val.to_s == val },
          boolean: ->(val) { %w(true false 0 1).include?(val.to_s.downcase) },
          json: ->(val) { JSON.parse(val) rescue false }
        }

        # ---------
        @validatore_campi_me = {
          fase_di_calcolo: ->(val) { val.to_s.numeric? && Constant.values(:fase_calcolo).include?(val.to_i) }
        }
        Db::MetaEntita.columns.each do |col|
          @validatore_campi_me[col] ||= if Constant.exists?(:meta_entita, col)
                                          # ->(val) { Constant.values(:meta_entita, col).include?(val) }
                                          lambda do |val|
                                            val_mod = case Db::MetaEntita.db_schema[col][:type]
                                                      when :integer
                                                        val.to_i
                                                        # when :boolean
                                                        # TODO: vedere come fare....
                                                      else
                                                        val
                                                      end
                                            Constant.values(:meta_entita, col).include?(val_mod)
                                          end
                                        else
                                          validatore_per_tipo[Db::MetaEntita.db_schema[col][:type]]
                                        end
        end

        # ---------
        @validatore_campi_mp = {}
        Db::MetaParametro.columns.each do |col|
          @validatore_campi_mp[col] ||= if Constant.exists?(:meta_parametro, col)
                                          lambda do |val|
                                            val_mod = case Db::MetaParametro.db_schema[col][:type]
                                                      when :integer
                                                        val.to_i
                                                        # when :boolean
                                                        # TODO: vedere come fare....
                                                      else
                                                        val
                                                      end
                                            Constant.values(:meta_parametro, col).include?(val_mod)
                                          end
                                        else
                                          validatore_per_tipo[Db::MetaParametro.db_schema[col][:type]]
                                        end
        end
      end

      def mod_value(val)
        return nil if val == ''
        return true if val == 'true'
        return false if val == 'false'
        val
      end

      def campo_ok?(tipo:, ident:, campo:, valore:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return false if valore == TEXT_NO_MOD # non va considerato perche' non lo voglio considerare
        check_valid = if valore.nil?
                        (tipo == MM_ENTITA ? Db::MetaEntita : Db::MetaParametro).db_schema[campo][:allow_null]
                      else
                        validatore = (tipo == MM_ENTITA ? @validatore_campi_me : @validatore_campi_mp)[campo]
                        validatore ? validatore.call(valore) : false
                      end
        unless check_valid
          # non lo considero perche' non e' coerente per tipo o range di valori
          nuova_segnalazione(TIPO_SEGNALAZIONE_AGGIORNA_ADRN_DA_FILE_DATI_VALORE_ERRATO,
                             tipo: tipo, ident: ident, campo: campo, valore: valore,
                             sheet_name: @sheet_name, linea_num: @linea_num)
          return false
        end
        true
      end
      # -------------------------------------------------------------------------------------------------

      def metamodello
        @metamodello ||= vendor_release.metamodello
      end

      def con_lock(key: LOCK_KEY_META_MODELLO, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def con_parser(file_da_processare:, **opts, &block)
        if File.extname(file_da_processare) =~ /\.xls/i
          BasicImporter.get_importer(:xls, file_da_processare: file_da_processare, **opts, &block)
        else
          importer = TxtImporter.new(file_da_processare: file_da_processare, **opts)
          yield(importer)
        end
      end

      def elabora_header(values)
        res = {}
        num_fixed_fields = FILE_ADRN_FIXED_FIELDS.size
        # puts "XXXX HEADER: #{values}"
        if (values || []).size < num_fixed_fields
          nuova_segnalazione(TIPO_SEGNALAZIONE_AGGIORNA_ADRN_DA_FILE_DATI_HEADER_FILE_NON_CORRETTO, valori: values)
          res[:error] = "Header (#{values}) non corretto"
          return res
        end
        # TODO: Aggiungere eventuali altri controlli sulla correttezza dell'header...
        @campi_header = values
        @campi_header[num_fixed_fields..-1].each.with_index do |hhh, idx|
          @campi_header_entita << [hhh, idx + num_fixed_fields] if Db::MetaEntita.invert_mapped_columns_per_file_adrn.include?(hhh)
          @campi_header_parametro << [hhh, idx + num_fixed_fields] if Db::MetaParametro.invert_mapped_columns_per_file_adrn.include?(hhh)
        end
        res
      end

      # restituisce i campi relativi al meta_parametro/meta_entita letti dalla riga del file
      def campi_da_riga(tipo:, valori:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        valori_out = {}
        valori_out[:vendor_release_id] = @vendor_release.id
        campi_hdr = (tipo == MM_ENTITA ? @campi_header_entita : @campi_header_parametro)
        np_obj = nil
        if tipo == MM_ENTITA
          valori_out[:nome] = valori[FILE_ADRN_FIXED_FIELD_POS_NOME]
          np_in = valori[FILE_ADRN_FIXED_FIELD_POS_NP]
          valori_out[:naming_path] = (np_in || '').empty? ? valori_out[:nome] : [np_in, valori_out[:nome]].join(NAMING_PATH_SEP)
          np_obj = valori_out[:naming_path]
        else
          valori_out[:full_name] = valori[FILE_ADRN_FIXED_FIELD_POS_NOME]
          fn_pcz = valori_out[:full_name].split(TEXT_STRUCT_NAME_SEP)
          valori_out[:nome_struttura], valori_out[:nome] = if fn_pcz.size == 1
                                                             [nil, fn_pcz[0]]
                                                           else
                                                             fn_pcz
                                                           end
          np_obj = valori[FILE_ADRN_FIXED_FIELD_POS_NP]
        end
        ident = tipo == MM_ENTITA ? valori_out[:naming_path] : valori_out[:full_name]
        campi_hdr.each do |xxx|
          valore = mod_value(valori[xxx[1]])
          # campo = xxx[0].to_sym
          campo = (tipo == MM_ENTITA ? Db::MetaEntita : Db::MetaParametro).invert_mapped_columns_per_file_adrn[xxx[0]]
          valori_out[campo] = valore if campo_ok?(tipo: tipo, ident: ident, campo: campo, valore: valore)
        end
        # Validazione regole_calcolo/_ae
        validazione_regole(tipo, np_obj, valori_out) if valori_out[:regole_calcolo] || valori_out[:regole_calcolo_ae]
        valori_out
      end

      def validazione_regole(tipo, np, valori_out) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        new_attr = {}
        if tipo == MM_ENTITA
          ident = valori_out[:naming_path]
          obj_db = Db::MetaEntita.where(vendor_release_id: @vendor_release.id, naming_path: ident).first
          Db::MetaEntita.columns_per_file_adrn.each do |col|
            new_attr[col] = valori_out[col] || (obj_db || {})[col] || Db::MetaEntita.db_schema[col][:ruby_default]
          end
        else
          ident = valori_out[:full_name]
          me_id = (Db::MetaEntita.first(vendor_release_id: @vendor_release.id, naming_path: np) || {})[:id]
          obj_db = Db::MetaParametro.where(vendor_release_id: @vendor_release.id, full_name: ident, meta_entita_id: me_id).first
          Db::MetaParametro.columns_per_file_adrn.each do |col|
            new_attr[col] = valori_out[col] || (obj_db || {})[col] || Db::MetaParametro.db_schema[col][:ruby_default]
          end
        end
        obj = (tipo == MM_ENTITA ? Db::MetaEntita : Db::MetaParametro).new(valori_out.merge(new_attr))

        regole_ko = {}
        obj.valida_tutte_le_regole do |_key, regola, _rete_adj, is_ae, res|
          res_err = (res || {})[:errore]
          res_warn = (res || {})[:warning]
          if res_err || res_warn
            campo = is_ae ? :regole_calcolo_ae : :regole_calcolo
            regole_ko[campo] = true if res_err
            nuova_segnalazione(TIPO_SEGNALAZIONE_AGGIORNA_ADRN_DA_FILE_DATI_REGOLA_CALCOLO_NON_CORRETTA,
                               tipo: tipo, ident: "#{ident} (naming_path: #{np}", campo: campo, regola: regola, errore: res_err.to_s + res_warn.to_s,
                               sheet_name: @sheet_name, linea_num: @linea_num)
          end
        end
        regole_ko.keys.each { |rk| valori_out.delete(rk) }
      end

      def check_campi_linea(valori:, err_msg:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        mmm = nil
        if (valori || []).size < FILE_ADRN_FIXED_FIELDS.size
          mmm = 'Campi insufficienti'
        end
        unless mmm
          tipo_obj = valori[FILE_ADRN_FIXED_FIELD_POS_TIPO_OBJ]
          np_input = valori[FILE_ADRN_FIXED_FIELD_POS_NP]
          nome = valori[FILE_ADRN_FIXED_FIELD_POS_NOME]
          # -- check tipo_obj
          unless [TIPO_OBJ_MM_ENTITA, TIPO_OBJ_MM_PARAMETRO].include?(tipo_obj)
            mmm = "TIPO: '#{tipo_obj}' non corretto. Valori validi: meta_entita (#{TIPO_OBJ_MM_ENTITA}), meta_parametro (#{TIPO_OBJ_MM_PARAMETRO})"
          end
        end
        # -- check nome
        mmm = "NOME: '#{nome}' non corretto." if mmm.nil? && (nome || '').empty?
        # -- check np_input
        # np_input puo' essere vuoto solo per la meta_entita root...
        mmm = "NAMING_PATH: '#{np_input}' non corretto." if mmm.nil? && (tipo_obj != TIPO_OBJ_MM_ENTITA && (np_input || '').empty?)

        if mmm
          nuova_segnalazione(TIPO_SEGNALAZIONE_AGGIORNA_ADRN_DA_FILE_DATI_LINEA_FILE_NON_CORRETTA,
                             valori: valori, msg: mmm,
                             sheet_name: @sheet_name,
                             linea_num: @linea_num)
          err_msg[:error] = format_msg(:AGGIORNA_ADRN_DA_FILE_DATI_LINEA_FILE_NON_CORRETTA,
                                       valori: valori, msg: mmm,
                                       sheet_name: @sheet_name,
                                       linea_num: @linea_num)
          return []
        end
        [tipo_obj, np_input, nome]
      end

      def elabora_linea(values) # rubocop:disable Metrics/CyclomaticComplexity
        res = {}
        # puts "XXXX linea: #{values}"
        tipo_obj, np_input, nome = check_campi_linea(valori: values, err_msg: res)
        return res unless (res[:error] || '').empty?
        case tipo_obj
        when TIPO_OBJ_MM_ENTITA
          np = (np_input || '').empty? ? nome : [np_input, nome].join(NAMING_PATH_SEP) # per la root
          @cache_dati[np] ||= {}
          @cache_dati[np][MM_ENTITA] = campi_da_riga(tipo: MM_ENTITA, valori: values)
        when TIPO_OBJ_MM_PARAMETRO
          np = np_input
          @cache_dati[np] ||= {}
          @cache_dati[np][MM_PARAMETRI] ||= {}
          @cache_dati[np][MM_PARAMETRI][nome] = campi_da_riga(tipo: MM_PARAMETRI, valori: values)
        end
        res
      end

      def processa_linea_input(linea_input, res)
        if @linea_num == @num_linea_header
          result = elabora_header(linea_input)
          res[result[:error] ? :linee_header_scartate : :linee_header_ok] += 1
          # return false unless result[:error].nil? # se l'header non e' valido mi fermo
        else
          result = elabora_linea(linea_input)
          res[result[:error] ? :linee_scartate : :linee_ok] += 1
        end
        # mi fermo in caso di header non valido e anche in caso di linea non corretta
        unless result[:error].nil?
          res[:error] = result[:error]
          return false
        end
        true
      end

      def cancella_mm_entita(me, res)
        x = me.destroy_con_gerarchia(audit_extra_info: @audit_info)
        res[:me_cancellate] += x[:cnt_me]
        res[:mp_cancellati] += x[:cnt_mp]
      end

      def crea_mm_entita(dati)
        Db::MetaEntita.create_with_audit(audit_extra_info: @audit_info, attributes: dati)
      rescue => e
        raise format_msg(:ERRORE_DB_AGGIORNAMENTO_ADRN_FILE, tipo: MM_ENTITA, oper: 'create', dati: dati, err_msg: e.message)
      end

      def aggiorna_mm_entita(me, dati)
        me.update_with_audit(audit_extra_info: @audit_info, attributes: dati)
      rescue => e
        raise format_msg(:ERRORE_DB_AGGIORNAMENTO_ADRN_FILE, tipo: MM_ENTITA, oper: 'update', dati: dati, err_msg: e.message)
      end

      def crea_mm_parametro(dati)
        Db::MetaParametro.create_with_audit(audit_extra_info: @audit_info, attributes: dati)
      rescue => e
        raise format_msg(:ERRORE_DB_AGGIORNAMENTO_ADRN_FILE, tipo: MM_PARAMETRI, oper: 'create', dati: dati, err_msg: e.message)
      end

      def aggiorna_mm_parametro(mp, dati)
        mp.update_with_audit(audit_extra_info: @audit_info, attributes: dati)
      rescue => e
        raise format_msg(:ERRORE_DB_AGGIORNAMENTO_ADRN_FILE, tipo: MM_PARAMETRI, oper: 'update', dati: dati, err_msg: e.message)
      end

      def aggiorna_adrn_per_delete(res)
        res[:mp_cancellati] ||= 0
        @cache_dati.sort.each do |np, dati|
          me = Db::MetaEntita.where(vendor_release_id: @vendor_release.id, naming_path: np).first
          next unless me
          if dati[MM_ENTITA]
            cancella_mm_entita(me, res)
            next
          end
          next unless dati[MM_PARAMETRI]
          # devo cancellare meta_parametri
          f_names = dati[MM_PARAMETRI].keys
          res[:mp_cancellati] += me.destroy_meta_parametri(audit_extra_info: @audit_info, filtro: { full_name: f_names }).count
        end
      end

      def me_da_db(np)
        Db::MetaEntita.where(vendor_release_id: @vendor_release.id, naming_path: np).first
      end

      def np_da_db(np, full_name_list)
        me = me_da_db(np)
        mp_db = {}
        Db::MetaParametro.where(meta_entita_id: me.id, full_name: full_name_list).each { |mmpp| mp_db[mmpp.full_name] = mmpp } if me
        mp_db
      end

      def aggiorna_adrn_per_insert(res) # rubocop:disable Metrics/CyclomaticComplexity
        @cache_dati.sort.each do |np, dati|
          me = me_da_db(np)
          if dati[MM_ENTITA] && me.nil?
            crea_mm_entita(dati[MM_ENTITA])
            res[:me_create] += 1
            me = me_da_db(np) # reload
          end
          next unless me
          next if (dati[MM_PARAMETRI] || {}).empty?
          mp_db = np_da_db(np, dati[MM_PARAMETRI].keys)
          dati[MM_PARAMETRI].each do |f_name, dati_mp|
            mp = mp_db[f_name]
            next if mp
            crea_mm_parametro(dati_mp.merge(meta_entita_id: me.id))
            res[:mp_creati] += 1
          end
        end
      end

      def aggiorna_adrn_per_insert_or_update(res) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        @cache_dati.sort.each do |np, dati|
          me = me_da_db(np)
          if dati[MM_ENTITA] # riga me
            if me
              o = aggiorna_mm_entita(me, dati[MM_ENTITA])
              res[:me_aggiornate] += 1 if o
            else
              crea_mm_entita(dati[MM_ENTITA])
              res[:me_create] += 1
            end
          end
          me = me_da_db(np) # reload
          next unless me
          next if (dati[MM_PARAMETRI] || {}).empty?
          mp_db = np_da_db(np, dati[MM_PARAMETRI].keys)
          dati[MM_PARAMETRI].each do |f_name, dati_mp|
            mp = mp_db[f_name]
            if mp
              o = aggiorna_mm_parametro(mp, dati_mp)
              res[:mp_aggiornati] += 1 if o
            else
              crea_mm_parametro(dati_mp.merge(meta_entita_id: me.id))
              res[:mp_creati] += 1
            end
          end
        end
      end

      def aggiorna_adrn # rubocop:disable Metrics/CyclomaticComplexity
        res = {}
        [:me_cancellate, :me_create, :me_aggiornate, :mp_cancellati, :mp_creati, :mp_aggiornati].each do |kkk|
          res[kkk] = 0
        end
        if (@cache_dati || {}).empty?
          nuova_segnalazione(TIPO_SEGNALAZIONE_AGGIORNA_ADRN_DA_FILE_DATI_NESSUN_AGGIORNAMENTO)
          return res
        end

        begin
          Db.connection.transaction do
            case @operazione
            when AGGIORNA_ADRN_OPERATION_DELETE
              aggiorna_adrn_per_delete(res)
            when AGGIORNA_ADRN_OPERATION_INSERT
              aggiorna_adrn_per_insert(res)
            when AGGIORNA_ADRN_OPERATION_INSERT_OR_UPDATE
              aggiorna_adrn_per_insert_or_update(res)
            end
          end
        rescue => e
          nuova_segnalazione(TIPO_SEGNALAZIONE_AGGIORNA_ADRN_DA_FILE_DATI_ERRORE_AGGIORNAMENTO_DB, err_msg: e.message)
          res[:eccezione] = "#{e}: #{e.message}"
        end
        res
      end

      def esegui(**opts)
        res = {}
        funzione = Db::Funzione.get_by_pk(FUNZIONE_AGGIORNA_ADRN_DA_FILE)
        con_lock(funzione: funzione.nome, account_id: opts[:account_id], enable: opts.fetch(:lock, true), logger: logger, log_prefix: log_prefix, **opts) do |_locks|
          con_segnalazioni(funzione: funzione,
                           account: opts[:account] || account,
                           filtro: { vendor_release_id: (opts[:vendor_release] || vendor_release || {})[:id] },
                           attivita_id: opts[:attivita_id]) do
            # --- lettura file
            con_parser(file_da_processare: @input_file, **opts) do |parser|
              res_p = { linee_header_ok: 0, linee_header_scartate: 0, linee_ok: 0, linee_scartate: 0 }
              begin
                res[:parser] = parser.parse do |linea_input, linea_num, sheet_name|
                  @linea_num = linea_num
                  @sheet_name = sheet_name
                  # puts "RRRRRRRR #{sheet_name} - n. #{linea_num}, '#{linea_input}'"
                  processa_linea_input(linea_input, res_p)
                end # parse
                res[:parser] = res[:parser].merge(res_p)
              rescue => e
                res[:eccezione] = "#{e}: #{e.message} - nella rescue di begin"
                logger.error("#{@log_prefix} catturata eccezione (#{res_p})")
                raise
              end # begin
            end # parser
            # --- aggiornamento adrn
            res[:aggiornamento_adrn] = aggiorna_adrn
            res
          end # con_segnalazioni
        end # con_lock
      end
    end

    #------------------------------------------------
    # EXPORT ADRN SU FILE
    class ExportAdrnSuFile
      include SegnalazioniPerFunzione
      include Irma::Funzioni::BasicFormatter

      class XlsFormatter < BasicFormatter::XlsFormatter
        def add_conditional_formatting(**opts)
          my_cond_format_layer = @sheet.get_sheet_conditional_formatting
          column_rule = org.apache.poi.hssf.util.CellReference.convert_num_to_col_string(FILE_ADRN_FIXED_FIELD_POS_TIPO_OBJ)
          rule_str = "OR($#{column_rule}1 = \"#{FILE_ADRN_FIXED_FIELD_TIPO_OBJ_ENTITA}\",$#{column_rule}1 = #{FILE_ADRN_FIXED_FIELD_TIPO_OBJ_ENTITA.to_i})"

          my_rule = my_cond_format_layer.create_conditional_formatting_rule(rule_str)

          color = java.lang.Object.org.apache.poi.ss.usermodel.IndexedColors::AQUA.get_index
          my_rule_pattern = my_rule.create_pattern_formatting
          my_rule_pattern.set_fill_background_color(color)
          column_end_range = org.apache.poi.hssf.util.CellReference.convert_num_to_col_string(opts[:campi_linea] ? (opts[:campi_linea].size - 1) : 21)
          my_data_range = org.apache.poi.ss.util.CellRangeAddress.value_of("A1:#{column_end_range}10000")
          my_cond_format_layer.add_conditional_formatting([my_data_range].to_java(org.apache.poi.ss.util.CellRangeAddress), my_rule)
        end
      end

      attr_reader :logger, :log_prefix
      attr_reader :filtro_metamodello, :metamodello, :campi_header
      attr_reader :campi_m_entita, :campi_m_parametro

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'Aggiornamento adrn da file'
        @vendor_release = opts[:vendor_release]
        @account = opts[:account]
        @filtro_metamodello = opts[:filtro_metamodello]
        @campi_header = nil
        @campi_m_entita = opts[:campi_m_entita]
        @campi_m_parametro = opts[:campi_m_parametro]
      end

      def out_file_name(time: Time.now.strftime('%Y%m%d%H%M'))
        "export_adrn_#{@vendor_release.compact_descr}_#{time}.xlsx"
      end

      def con_formatter(out_file:, &block)
        BasicFormatter.get_formatter(FORMATO_EXPORT_XLS, out_file: out_file, class_formatter: self.class::XlsFormatter,
                                                         logger: logger, log_prefix: log_prefix,
                                                         autosize: true, locked_columns: FILE_ADRN_FIXED_FIELDS.size, &block)
      end

      def campi_header
        return @campi_header if @campi_header
        me_col_ok = Db::MetaEntita.mapped_columns_per_file_adrn
        mp_col_ok = Db::MetaParametro.mapped_columns_per_file_adrn
        cm = campi_m_entita ? (campi_m_entita & me_col_ok) : me_col_ok
        cp = campi_m_parametro ? (campi_m_parametro & mp_col_ok) : mp_col_ok
        # @campi_header = (cm + cp).sort.uniq
        @campi_header = (cm + cp).uniq
        @campi_header
      end

      def metamodello
        @metamodello ||= @vendor_release.metamodello
      end

      def np_da_considerare
        @np_da_considerare ||= filtro_metamodello ? (metamodello.meta_entita.keys & filtro_metamodello.keys) : metamodello.meta_entita.keys
      end

      def mp_da_considerare(np) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        filtro = filtro_metamodello && filtro_metamodello[np] && filtro_metamodello[np][FILTRO_MM_PARAMETRI]
        if filtro && filtro != [META_PARAMETRO_ANY]
          (metamodello.meta_parametri[np] || {}).keys & filtro
        else
          (metamodello.meta_parametri[np] || {}).keys
        end
      end

      def prepara_linea_entita(np)
        me = metamodello.meta_entita[np]
        return nil unless me
        res = [TIPO_OBJ_MM_ENTITA, me.naming_path_padre, me.nome]
        @campi_header.each.with_index do |mapped_fff_hdr, idx|
          fff_hdr = Db::MetaEntita.invert_mapped_columns_per_file_adrn[mapped_fff_hdr]
          val = if me[fff_hdr].nil?
                  ''
                elsif Db::MetaEntita.db_schema[fff_hdr][:type] == :json
                  me[fff_hdr].to_json
                else
                  me[fff_hdr]
                end
          res[FILE_ADRN_FIXED_FIELDS.size + idx] = val
        end
        res
      end

      def prepara_linea_parametro(np, fn)
        mp = (metamodello.meta_parametri[np] || {})[fn]
        return nil unless mp
        res = [TIPO_OBJ_MM_PARAMETRO, np, fn]
        @campi_header.each.with_index do |mapped_fff_hdr, idx|
          fff_hdr = Db::MetaParametro.invert_mapped_columns_per_file_adrn[mapped_fff_hdr]
          val = if mp[fff_hdr].nil?
                  ''
                elsif Db::MetaParametro.db_schema[fff_hdr][:type] == :json
                  mp[fff_hdr].to_json
                else
                  mp[fff_hdr]
                end
          res[FILE_ADRN_FIXED_FIELDS.size + idx] =  val
        end
        res
      end

      def comments_header(campi)
        res = campi.map do |ccc|
          comment_me = Db::MetaEntita::FILE_ADRN_HEADER_COMMENTS[Db::MetaEntita::COLUMNS_FILE_ADRN_MAPPING.invert[ccc]]
          comment_mp = Db::MetaParametro::FILE_ADRN_HEADER_COMMENTS[Db::MetaParametro::COLUMNS_FILE_ADRN_MAPPING.invert[ccc]]
          FILE_ADRN_FIXED_FIELD_COMMENTS[ccc] || comment_me || comment_mp
        end
        res
      end

      def esegui(**opts)
        res = { meta_parametri_scritti: 0, meta_entita_scritte: 0 }
        funzione = Db::Funzione.get_by_pk(FUNZIONE_EXPORT_ADRN_SU_FILE)
        ref_date_str = Time.now.strftime('%Y%m%d%H%M')
        out_file = File.join(opts[:out_dir], out_file_name(time: ref_date_str))
        con_segnalazioni(funzione: funzione, account: opts[:account] || account, attivita_id: opts[:attivita_id]) do
          con_formatter(out_file: out_file) do |formatter|
            campi_hdr = FILE_ADRN_FIXED_FIELDS + campi_header.map(&:to_s)
            formatter.scrivi_header(campi_linea: campi_hdr, comments: comments_header(campi_hdr))
            np_da_considerare.each do |np|
              lll = prepara_linea_entita(np)
              next unless lll
              formatter.scrivi_linea(campi_linea: lll)
              res[:meta_entita_scritte] += 1
              mp_da_considerare(np).each do |f_name|
                lll = prepara_linea_parametro(np, f_name)
                next unless lll
                formatter.scrivi_linea(campi_linea: lll)
                res[:meta_parametri_scritti] += 1
              end
            end
          end
          res
        end
        res
      end
    end

    # -------------------------------------------------
    # AGGIORNAMENTO METAMODELLO FISICO
    class AggiornaMetamodelloFisico
      include SegnalazioniPerFunzione
      include ImportExportAdrnUtil

      attr_reader :logger, :log_prefix

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'Aggiorna Metamodello Fisico'
      end

      def con_lock(key: LOCK_KEY_META_MODELLO_FISICO, mode: LOCK_MODE_WRITE, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def esegui(**opts)
        res = {}
        funzione = Db::Funzione.get_by_pk(FUNZIONE_AGGIORNA_METAMODELLO_FISICO)
        con_lock(funzione: funzione.nome, account_id: opts[:account_id], enable: opts.fetch(:lock, true), logger: logger, log_prefix: log_prefix, **opts) do |_locks|
          con_segnalazioni(funzione: funzione, **opzioni_con_segnalazioni(opts)) do
            import_res = res[opts[:vrf].compact_descr] = aggiorna_metamodello_fisico_per_vrf(opts[:vrf])
            raise import_res[:errore] if import_res[:errore] && opts[:raise_error]
            res[opts[:vrf].compact_descr] = import_res
          end # con_segnalazioni
          res
        end # con_lock
        res
      end

      def aggiorna_metamodello_fisico_per_vrf(vrf)
        ret = { esito: nil }
        msg = "per vendor_release_fisico '#{vrf.compact_descr}' (id #{vrf.id})"
        logger.info "Inizio aggiornamento metamodello fisico #{msg}"
        begin
          ret[:elaborazione] = vrf.aggiorna_metamodello_da_logico
        rescue => e
          ret[:errore] = e.message + e.backtrace.to_s
        end
        if ret[:errore]
          ret[:esito] = 'KO'
          logger.error "Aggiornamento metamodello fisico #{msg} fallito (#{ret[:errore]}) in #{ret[:durata]} secondi"
          # nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_ADRN_DATI_IMPORT_VR_FALLITO, descr_vr: descr_vr, err_msg: ret[:errore])
        else
          ret[:esito] = 'OK'
          logger.info "Aggiornamento metamodello fisico #{msg} terminato con successo in #{ret[:durata]} secondi"
        end
        ret
      end
    end

    class ExportIncongruenzeMetamodello
      include SegnalazioniPerFunzione
      include ImportExportAdrnUtil
      include SharedFs::Util

      attr_reader :logger, :log_prefix

      INTESTAZIONE_FILE_IRMA1 = ['NAMING_PATH', 'OGGETTO', 'ENTITA\'', 'PARAM_SEMPLICI', 'PARAM_STRUTTURATI', 'PARAM_MULTIVALORE'].freeze
      FILE_PREFIX_INCR = 'Incongruenze'.freeze

      def initialize(**opts)
        @logger = opts[:logger] || Irma.logger
        @log_prefix = opts[:log_prefix] || 'Export incongruenze adrn'
        @tmp_dir_root = opts[:tmp_dir_root]
        @out_dir_root = opts[:out_dir_root]
        @is_fisico = opts[:is_fisico]
        @is_fisico = true if @is_fisico.nil?
        @vr_id = opts[:vendor_release_id]
        @archivio = opts[:archivio] || ARCHIVIO_RETE
        @ambiente = opts[:ambiente] || AMBIENTE_PROG
        @out_file = nil
      end

      def con_lock(key: LOCK_KEY_META_MODELLO, mode: LOCK_MODE_READ, **opts, &block)
        Irma.lock(key: key, mode: mode, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def vendor_release
        begin
          @vendor_release ||= (@is_fisico ? Db::VendorReleaseFisico.get_by_pk(@vr_id) : Db::VendorRelease.get_by_pk(@vr_id))
        rescue => e
          raise "vendor_release_id '#{@vr_id}' non agganciato a nessuna vendor release, #{e}"
        end
        @vendor_release
      end

      def metamodello
        @metamodello ||= vendor_release.metamodello
      end

      def esegui(**opts)
        res = { artifacts: [] }
        funzione = Db::Funzione.get_by_pk(FUNZIONE_EXPORT_INCONGRUENZE_METAMODELLO)
        con_lock(funzione: funzione.nome, account_id: opts[:account_id], enable: opts.fetch(:lock, true), logger: logger, log_prefix: log_prefix, **opts) do |_locks|
          con_segnalazioni(funzione: funzione, **opzioni_con_segnalazioni(opts)) do
            start_time_export = Time.now
            logger.info "Inizio export incongruenze metamodello vendor release '#{vendor_release.descr}'"
            begin
              ret = export_incongruenze
              res[:artifacts] = ret[:target_path]
              [:num_meta_entita, :num_meta_parametri].each { |k| res[k] = ret[k] }
            rescue => e
              # nuova_segnalazione(TIPO_SEGNALAZIONE_EXPORT_INCONGRUENZE_METAMODELLO_DATI_FALLITO, descr_vr: vendor_release.descr, err_msg: e)
              raise e
            end
            logger.info "Export incongruenze metamodello vendor release '#{vendor_release.descr}', terminato con successo in #{(Time.now - start_time_export).round(1)} secondi"
            res
          end
          res
        end
        res
      end

      #------------------------------------------------
      def export_incongruenze
        res = { target_path: nil, num_meta_parametri: 0, num_meta_entita: 0 }
        cnt = 0
        lista_archivi.each { |arch| cnt += arch.dataset.count }
        if cnt == 0
          nuova_segnalazione(TIPO_SEGNALAZIONE_EXPORT_INCONGRUENZE_METAMODELLO_DATI_ARCHIVI_VUOTI, descr_vr: vendor_release.descr)
          raise 'Archivi di rete vuoti'
        end
        dir_zip = crea_dir_zip(@tmp_dir_root, [FILE_PREFIX_INCR, vendor_release.descr, vendor_release.vendor.nome])
        @out_file = File.join(dir_zip, [FILE_PREFIX, vendor_release.descr, Time.now.strftime('%Y%m%d%H%M')].compact.join('_') + '.txt')
        begin
          Db.connection.transaction do
            res[:num_meta_entita] = scrivi_entita_assenti
            res[:num_meta_parametri] = scrivi_parametri_assenti
          end
        rescue => e
          logger.error "Export incongruenze metamodello fallito (#{e})"
          raise
        end
        res[:target_path] = comprimi_e_sposta_dirzip(dir_zip)
        res
      end

      def lista_archivi
        @lista_archivi ||= begin
                              if @is_fisico
                                vendor_release.omc_fisici.map { |of| of.entita(archivio: @archivio) }.flatten
                              else
                                vendor_release.sistemi.map { |s| s.entita(archivio: @archivio, ambiente: @ambiente) }.flatten
                              end
                            end
        @lista_archivi
      end

      def np_in_archivio
        @np_in_archivio ||= begin
                              ret = lista_archivi.map do |ent|
                                ent.dataset.distinct.select_map(:naming_path)
                              end.flatten.uniq
                              ret
                            end
      end

      FILE_PREFIX = 'RicercaIncongruenze'.freeze
      FILE_ARRAY_ENTITA_FISSE = %w(1 0 0 0).freeze

      def scrivi_entita_assenti
        np_assenti = (metamodello.meta_entita.keys - np_in_archivio).sort
        return 0 if np_assenti.empty?
        File.open(@out_file, 'w') do |fd|
          fd.puts(INTESTAZIONE_FILE_IRMA1.join(PR_METAMODELLO_FIELD_SEP))
          np_assenti.each do |np|
            new_record = []
            new_record << np
            new_record << np.split(NAMING_PATH_SEP).last
            new_record.concat(FILE_ARRAY_ENTITA_FISSE)
            fd.puts(new_record.join(PR_METAMODELLO_FIELD_SEP))
          end
        end
        np_assenti.size
      end

      def scrivi_parametri_assenti # rubocop:disable Metrics/CyclomaticComplexity
        count = 0
        scrivi_intestaz = !File.exist?(@out_file)
        File.open(@out_file, 'a') do |fd|
          fd.puts(INTESTAZIONE_FILE_IRMA1.join(PR_METAMODELLO_FIELD_SEP)) if scrivi_intestaz
          np_in_archivio.sort.each do |np|
            next unless metamodello.meta_parametri[np]
            mp_in_archivio = []
            lista_archivi.each do |ent|
              mp_in_archivio |= ent.dataset.with_sql("select distinct json_object_keys(parametri) as key from #{ent.table_name} where naming_path = '#{np}'").map { |k| k[:key] }
            end
            # mp_in_archivio.uniq!
            mp_assenti = metamodello.meta_parametri[np].keys - mp_in_archivio
            next if mp_assenti.empty?
            count += mp_assenti.size
            mp_assenti.each do |mp|
              new_record = []
              new_record << np
              new_record << metamodello.meta_parametri[np][mp].nome
              new_record << '0' # ENTITA
              new_record << (metamodello.meta_parametri[np][mp].is_multivalue ? '0' : '1') # PARAM_SEMPLICI
              new_record << (metamodello.meta_parametri[np][mp].nome_struttura.to_s.empty? ? 0 : metamodello.meta_parametri[np][mp].nome_struttura) # PARAM_STRUTTURATI
              new_record << (metamodello.meta_parametri[np][mp].is_multivalue ? '1' : '0') # PARAM_MULTIVALORE
              fd.puts(new_record.join(PR_METAMODELLO_FIELD_SEP))
            end
          end
        end
        count
      end
    end
  end
end
