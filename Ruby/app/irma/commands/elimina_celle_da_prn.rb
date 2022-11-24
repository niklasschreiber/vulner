# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20180604
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define ELIMINA_CELLE_DA_PRN_LOCK_EXPIRE = :elimina_celle_da_prn_lock_expire, 600,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di elimina celle da PRN',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:1800})'

    method_option :lista_celle, type: :string,  banner: 'Lista delle celle da cancellare, separate da virgola'
    method_option :sistema_id,  type: :numeric, banner: 'Identificativo del sistema'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,    type: :string,  banner: "Archivio di riferimento delle entita'", default: ARCHIVIO_RETE
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{ELIMINA_CELLE_DA_PRN_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)
    method_option :omc_fisico, type: :boolean, banner: 'Cancellazione celle su OmcFisico', default: false

    common_options 'elimina_celle_da_prn', "Esegue la cancellazione delle celle in input dal Progetto Radio Nazionale"
    def elimina_celle_da_prn
      saa = Db.saa_instance(omc_fisico: options[:omc_fisico], id: options[:sistema_id], account: options[:account_id], archivio: options[:archivio])

      input_opts = { 
        attivita_id:          options[:attivita_id],
        stats:                true,
        expire:               options[:lock_expire] || config[ELIMINA_CELLE_DA_PRN_LOCK_EXPIRE],
        lista_celle:           []
      }

      raise "Lista celle '#{options[:lista_celle]}' non valida" if options[:lista_celle].to_s.empty?

      input_opts[:lista_celle] = options[:lista_celle].split(ARRAY_VAL_SEP)

      # --------------------------------------------------

      input_opts[:log_prefix] = "Elimina celle dal Progetto Radio Nazionale per #{options[:omc_fisico] ? 'omc fisico' : 'sistema'} #{saa.full_descr} (id=#{saa.sistema_id})," +
      " numero celle=#{input_opts[:lista_celle].size}, account=#{saa.account.full_descr} expire=#{input_opts[:expire]}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: input_opts[:log_prefix]) { saa.elimina_celle_da_prn(input_opts) }
    ensure
      cleanup_temp_files
    end

    private

    def pre_elimina_celle_da_prn
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
