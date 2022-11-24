# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20190417
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define AGGIORNA_ADRN_DA_FILE_LOCK_EXPIRE = :aggiorna_adrn_da_file_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di aggiornamento adrn da file',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :account_id,          type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :vendor_release_id,   type: :numeric, banner: 'Identificativo vendor_release destinazione degli aggiornamenti adrn', default: nil
    method_option :input_file, type: :string,  banner: 'Nome file zip di input'
    method_option :operazione,        type: :string,  banner: 'Operazione di aggiornamento da eseguire'

    method_option :lock_expire,         type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{AGGIORNA_ADRN_DA_FILE_LOCK_EXPIRE})"
    method_option :env, aliases: '-e',  type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)

    common_options 'aggiorna_adrn_da_file', "Aggiorna adrn da file"
    def aggiorna_adrn_da_file
      res = { artifacts: [] }

      # Account
      account = Db::Account.find(id: options[:account_id])
      raise "Nessun account definito con id '#{options[:account_id]}'" unless account

      # Vendor Release
      vr = Db::VendorRelease.first(id: options[:vendor_release_id] || -1)
      raise "Non esiste vendor release #{options[:omc_fisico] ? 'fisico' : ''} con id '#{options[:vendor_release_id]}'" unless vr

      # Input file
      in_file = absolute_file_path(options[:input_file])
      raise "Input file '#{in_file}' non trovato" unless File.exist?(in_file)
      raise "Input file '#{in_file}' deve essere un file excel o txt" unless File.extname(in_file).match(/\.(xls|txt)/i)

      # Operazione
      oper = options[:operazione]
      raise "Operazione #{oper} non consentita per aggiornamento adrn da file" unless Constant.values(:aggiorna_adrn_operation).include?(oper)

      function_opts = { 
        attivita_id:    options[:attivita_id],
        account:        account,
        vendor_release: vr,
        input_file:     in_file,
        operazione:     oper,
        expire:         options[:lock_expire] || config[AGGIORNA_ADRN_DA_FILE_LOCK_EXPIRE]
      }

      lp = "Aggiornamento adrn, operazione #{oper}, da file #{in_file},"
      lp += " su vendor release #{vr.full_descr}"
      lp += " expire=#{function_opts[:expire]}"
      function_opts[:log_prefix] = lp

      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: function_opts[:log_prefix]) do
        res[:elaborazione] = Funzioni::AggiornaAdrnDaFile.new(function_opts).esegui(function_opts)
      end
      res
    end

    private

    def pre_aggiorna_adrn_da_file
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
