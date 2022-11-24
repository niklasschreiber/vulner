# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160217
#

# import_adrn
require 'irma/db'

module Irma
  # rubocop:disable Metrics/ClassLength
  class Command < Thor
    config.define IMPORT_ADRN_LOCK_EXPIRE = :import_adrn_lock_expire, 900,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di import_adrn',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :filtro_release,     type: :string, banner: 'filtro release (\'release_descr,vendor,id_rete\')'
    method_option :id_vendor_release,  type: :string, banner: 'identificativo vendor_release di irma2'
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :import_file_zip,    type: :string, banner: 'File zip, full path o relative, con dati da importare, anche wildcard'
    method_option :account_id,         type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'

    common_options 'import_adrn', "Esegue l'import del metamodello con regole di calcolo dal/i file specificati"
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def import_adrn
      start_time = Time.now
      Db.init(env: options[:env], logger: logger, load_models: true)

      res = {}

      @account = options[:account_id].to_i == -1 ? Db::Account.qualsiasi : Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      @tmp_dir = Irma.tmp_sub_dir('temp_import_adrn')
      @input_file = absolute_file_path(options[:import_file_zip] || '')

      import_opts_comuni = {
        attivita_id:        options[:attivita_id],
        account_id:         @account.id,
        account:            @account,
        tmp_dir:            @tmp_dir,
        expire:             options[:lock_expire] || config[IMPORT_ADRN_LOCK_EXPIRE],
        logger:             logger
      }
      begin
        vr_list = determina_vr_list(id_vendor_release: options[:id_vendor_release], filtro_release: options[:filtro_release])
        res[:vr_da_importare] = vr_list.keys
      rescue => e
        logger.error "Errore nell'identificare la/le vendor release per cui eseguire l'import: #{e}"
        res[:vr_da_importare] = e.to_s
        raise e
      end

      vr_list.each do |vr_descr, vr_info|
        import_opts = import_opts_comuni.merge(log_prefix:        "Import adrn per vendor_release #{vr_descr}",
                                               id_vendor_release: vr_info[:vr_id],
                                               file_zip:          vr_info[:file_zip],
                                               descr_vr:          vr_descr,
                                               raise_error:       vr_list.size == 1
                                              )
        res[vr_descr] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: import_opts[:log_prefix]) { Funzioni::ImportAdrn.new(import_opts).esegui(import_opts) }
        # remove temporary files
        Dir["#{@tmp_dir}/*"].each { |f| FileUtils.rm_rf(f) }
      end

      # Aggiornamento meta_modello fisico
      #   Per questioni di performance, se eseguito import_adrn per UNA SOLA vendor_release,
      #   allora si aggiorna il metamodello fisico della sole vendor_release_fisico relative a questa vr logica
      #   altrimenti si aggiorna l'intero metamodello fisico
      cmd_aggiorna_mm_fisico = [Constant.info(:comando, COMANDO_AGGIORNA_METAMODELLO_FISICO)[:command], # 'aggiorna_metamodello_fisico',
                                '--aggiorna_anagrafica_vrf', 'true', '--account_id', @account.id]
      res[:mm_fisico] = {}
      if vr_list.size == 1
        vvvrrr = Db::VendorRelease.first(id: vr_list.first[1][:vr_id])
        vr_fisico_list = vvvrrr.vendor_release_fisico
        (vr_fisico_list || []).each do |vrf|
          res[:mm_fisico][vrf.full_descr] = Command.process(cmd_aggiorna_mm_fisico + ['--id_vendor_release', vrf.id], logger: Command.logger)
        end
      else
        res[:mm_fisico] = Command.process(cmd_aggiorna_mm_fisico, logger: Command.logger)
      end
      res[:durata] = (Time.now - start_time).round(1)
      res
    ensure
      cleanup_temp_files
      FileUtils.rm_rf(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
    end

    private

    include Irma::Funzioni::ImportExportAdrnUtil

    def pre_import_adrn
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    #------------------------------------------------
    # INTERPRETAZONE options
    # 1. Se options[:filtro_release] OPPURE options[:id_vendor_release] sono avvalorati
    #    si procede a importare i dati per una sola vendor release (quella individuata da queste options)
    #    1.1 Se options[:import_file_zip] corrisponde ad un file preciso, si usa il file specificato,
    #    1.2                  se corrisponde ad un gruppo di file (wildcard)si usa,
    #                                            1.2.1 se c'e' il file zip di default per quella vendor release
    #                                            1.2.2 se non c'e' non si fa nulla
    #    1.3 se non c'e' non si fa nulla.
    # 2. options[:filtro_release] = nil AND options[:id_vendor_release] = nil
    #    2.1 Se options[:import_file_zip] e' avvalorato,
    #        2.1.1 e corrisponde a un file zip preciso con naming di default
    #              Si deduce dal nome la vendor_release e si procede all'import
    #        2.2.2 e corrisponde a n file (uso di wildcard) allora per quelli con naming di default
    #              Si deduce dal nome la vendor_release e si procede all'import
    #    2.2 options[:import_file_zip] = nil
    #        Nulla da fare

    def determina_vr_list(id_vendor_release:, filtro_release:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      ret_vr_list = {} # hash { descr_vr1 => { vr_id: vr_id1, file_zip: file_zip1, terna: [vr_descr1, vendor1, rete1]}, descr_vr2 => {}...}

      xxx = File.directory?(@input_file) ? File.join(@input_file, '*.zip') : @input_file
      files_zip_potenziali = Dir[xxx || ''].select { |f| File.file?(f) }
      raise 'Nessun file zip presente per import' if files_zip_potenziali.count == 0

      if filtro_release || id_vendor_release
        terna = nil
        id_vr_scelto = nil
        if filtro_release
          terna = filtro_release.split(',')
          raise "Il filtro_release specificato non consente di identificare la release da importare (#{descr('', terna)})" unless check_terna(terna)
          id_vr_scelto = determina_idvr_da_terna(*terna)
        elsif id_vendor_release
          id_vr_scelto = id_vendor_release
          raise "L'id_vendor_release specificato non corrisponde a nessuna vendor_release (#{descr(id_vr_scelto, [])})" unless check_id_vr(id_vr_scelto)
          terna = determina_terna_da_idvr(id_vendor_release)
        end
        file_zip = determina_file_zip(files_zip_potenziali, "#{nome_dir_zip(terna)}.zip")
        raise 'Impossibile determinare informazioni sufficienti per eseguire import' unless check_import_info(terna: terna, file_zip: file_zip, vr_id: id_vr_scelto)
        ret_vr_list[compact_descr_vr(terna)] = { vr_id: id_vr_scelto.to_s, terna: terna, file_zip: file_zip }
      else # deduco terna e id_vr_scelto da nome file zip, potrebbero essere piu' di uno
        files_zip_potenziali.each do |file_zip_x|
          # puts "XXX file potenziale: #{file_zip_x}"
          terna = nil
          id_vr_scelto = nil
          terna = deduci_terna_da_file_zip(file_zip_x)
          unless check_terna(terna)
            logger.warn "Il file zip #{file_zip_x} non consente di identificare la release da importare"
            next
          end
          id_vr_scelto = determina_idvr_da_terna(*terna)
          unless check_import_info(terna: terna, file_zip: file_zip_x, vr_id: id_vr_scelto.to_s)
            logger.warn "Impossibile determinare informazioni sufficienti per eseguire import dal file #{file_zip_x}"
            next
          end
          ret_vr_list[compact_descr_vr(terna)] = { vr_id: id_vr_scelto.to_s, terna: terna, file_zip: file_zip_x }
        end
      end
      raise 'Nessuna vendor release identificata per import' if ret_vr_list.empty?
      ret_vr_list
    end

    def determina_file_zip(lista_file, basename)
      return nil if lista_file.nil? || lista_file.empty?
      return lista_file.first if lista_file.count == 1
      lista_file.select { |f| File.basename(f) == basename }.first
    end
  end
end
