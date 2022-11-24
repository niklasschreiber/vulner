# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180322
#

require 'irma/db'

module Irma
  #
  class Command < Thor
    config.define AGGIORNA_METAMODELLO_FISICO_LOCK_EXPIRE = :aggiorna_metamodello_fisico_lock_expire, 900,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di aggiorna_metamodello_fisico',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :filtro_release,     type: :string, banner: 'filtro release (\'release_descr,vendor\')'
    method_option :id_vendor_release,  type: :string, banner: 'identificativo vendor_release_fisico'
    method_option :aggiorna_anagrafica_vrf,  type: :boolean, banner: 'se true aggiorna vendor_release_fisico da vr logico', default: false
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :account_id,         type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'

    common_options 'aggiorna_metamodello_fisico', "Esegue l'aggiornamento del metamodello da logico a fisico"
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def aggiorna_metamodello_fisico
      start_time = Time.now
      Db.init(env: options[:env], logger: logger, load_models: true)

      res = {}

      @account = options[:account_id].to_i == -1 ? Db::Account.qualsiasi : Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      if options[:aggiorna_anagrafica_vrf]
        res[:anagrafica_vrf] = Db::VendorReleaseFisico.aggiornamento_da_vendor_releases
      end

      agg_opts_comuni = {
        attivita_id:        options[:attivita_id],
        account_id:         @account.id,
        account:            @account,
        tmp_dir:            @tmp_dir,
        expire:             options[:lock_expire] || config[AGGIORNA_METAMODELLO_FISICO_LOCK_EXPIRE],
        logger:             logger
      }
      begin
        vrf_list = determina_vrf_list(id_vendor_release: options[:id_vendor_release], filtro_release: options[:filtro_release])
        res[:vrf_da_aggiornare] = vrf_list.map(&:compact_descr)
      rescue => e
        logger.error "Errore nell'identificare la/le vendor_release_fisico per cui eseguire l'aggiornamento: #{e}"
        res[:vrif_da_aggiornare] = e.to_s
        raise e
      end
      vrf_list.each do |vrf|
        agg_opts = agg_opts_comuni.merge(log_prefix: "Aggiornamento metamodello fisico per vendor_release_fisico #{vrf.full_descr}",
                                         vrf: vrf,
                                         raise_error:       vrf_list.size == 1
                                        )
        res[vrf.compact_descr] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: agg_opts[:log_prefix]) { Funzioni::AggiornaMetamodelloFisico.new(agg_opts).esegui(agg_opts) }
      end

      if options[:aggiorna_anagrafica_vrf]
        res[:anagrafica_vrf][:vrf_cancellate] = Db::VendorReleaseFisico.remove_unused
      end
      res[:durata] = (Time.now - start_time).round(1)
      res
    ensure
      cleanup_temp_files
      FileUtils.rm_rf(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
    end

    private

    include Irma::Funzioni::ImportExportAdrnUtil

    def pre_aggiorna_metamodello_fisico
      Db.init(env: options[:env], logger: logger, load_models: true)
    end

    #------------------------------------------------
    # INTERPRETAZONE options
    # 1. Se options[:filtro_release] OPPURE options[:id_vendor_release] sono avvalorati
    #    si procede a aggiornare la sola vendor release fisico (quella individuata da queste options)
    # 2. options[:filtro_release] = nil AND options[:id_vendor_release] = nil si aggiornano tutte

    def determina_vrf_list(id_vendor_release:, filtro_release:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      ret_vrf_list = [] # array di id

      if filtro_release || id_vendor_release
        vrf_scelto = nil
        if filtro_release
          descr_vendor = filtro_release.split(',')
          raise "Il filtro_release specificato non consente di identificare la release da aggiornare (#{descr('', descr_vendor)})" unless check_rel_ven(descr_vendor)
          id_vrf_scelto = determina_idvrf_da_rel_ven(*descr_vendor)
        elsif id_vendor_release
          id_vrf_scelto = id_vendor_release
        end
        unless check_id_vr(id_vrf_scelto) && (vrf_scelto = Db::VendorReleaseFisico.first(id: id_vendor_release))
          raise "L'id_vendor_release specificato non corrisponde a nessuna vendor_release_fisico (#{descr(id_vrf_scelto, [])})"
        end
        ret_vrf_list = [vrf_scelto]
      else
        # aggiorno tutte le vendor_release_fisico
        ret_vrf_list = Db::VendorReleaseFisico.all
      end
      raise 'Nessuna vendor release identificata per l\'aggiornamento' if ret_vrf_list.empty?
      ret_vrf_list
    end
  end
end
