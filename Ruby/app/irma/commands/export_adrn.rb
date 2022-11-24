# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160217
#

# export_adrn
require 'irma/db' # ???

module Irma
  #
  class Command < Thor
    config.define EXPORT_ADRN_LOCK_EXPIRE = :export_adrn_lock_expire, 900,
                  descr:         'Periodo (in sec.) per l\'expire del lock per il comando di export_adrn',
                  widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :account_id,         type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :id_vendor_release,  type: :string, banner: 'identificativo/i vendor_release di irma2, separati da virgola; se vuoto viene eseguito l\'export di tutte le vendor_release'
    method_option :out_dir_root,       type: :string, banner: 'Cartella per cartelle file di export', default: '/tmp/'
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :lock_expire,        type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{EXPORT_ADRN_LOCK_EXPIRE})"

    common_options 'export_adrn', "Esegue l'export del metamodello con regole di calcolo dal db di irma2 per una o piu' vendor_release)"
    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
    def export_adrn
      res = { artifacts: [] }
      Db.init(env: options[:env], logger: logger, load_models: true)

      # check account
      @account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless @account

      @tmp_dir_root = Irma.tmp_sub_dir('temp_export_adrn')

      export_opts_comuni = {
        log_prefix:         options[:log_prefix] || 'Export adrn',
        attivita_id:        options[:attivita_id],
        account_id:         options[:account_id],
        out_dir_root:       options[:out_dir_root] || Irma.tmp_sub_dir('output_export_adrn'),
        account:            @account,
        tmp_dir_root:       @tmp_dir_root,
        expire:             options[:lock_expire] || config[EXPORT_ADRN_LOCK_EXPIRE],
        logger:             logger
      }

      # vendor_release_id richieste
      vr_da_processare = {}
      le_vendor_releases = (options[:id_vendor_release] || '').split(',')
      le_vendor_releases = Db::VendorRelease.select_map(:id) if le_vendor_releases.empty?
      le_vendor_releases.each do |id_vr_input|
        res_check = check_id_vendor_release(id_vr_input)
        raise "Il vendor release id specificato (#{id_vr_input}) non e' corretto" unless res_check
        id_vr, terna = res_check
        descr_vr = compact_descr_vr(terna)
        vr_da_processare[descr_vr] = { id_vendor_release: id_vr, terna_vendor_release: terna }
      end
      vr_da_processare.each do |descr_vr, vr_info|
        terna = vr_info[:terna_vendor_release]
        id_vr = vr_info[:id_vendor_release]
        export_opts = export_opts_comuni.merge(id_vendor_release: id_vr,
                                               terna_vendor_release: terna,
                                               descr_vr: descr_vr,
                                               log_prefix: "Export adrn per vendor release #{descr_vr} (id: #{id_vr})")
        res[descr_vr] = Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: export_opts[:log_prefix]) { Funzioni::ExportAdrn.new(export_opts).esegui(export_opts) }
        res[:artifacts] << [res[descr_vr][:result][:artifacts], 'export_adrn'] if res[descr_vr][:result][:artifacts]
      end
      res
    ensure
      FileUtils.rm_rf(@tmp_dir_root) if @tmp_dir_root && File.exist?(@tmp_dir_root)
    end

    private

    include Irma::Funzioni::ImportExportAdrnUtil

    def pre_export_adrn
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
