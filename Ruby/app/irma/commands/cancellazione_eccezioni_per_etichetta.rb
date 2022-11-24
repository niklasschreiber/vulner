# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20181015
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA_LOCK_EXPIRE = :cancellazione_eccezioni_per_etichetta_lock_expire, 600,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di cancellazione eccezioni per etichetta',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:1_800})'

    method_option :sistema_id,  type: :numeric, banner: 'Identificativo del sistema'
    method_option :etichette,   type: :string,  banner: 'Etichetta per le eccezioni'
    method_option :account_id,  type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :archivio,    type: :string,  banner: "Archivio di riferimento delle entita'"
    method_option :lock_expire, type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{IMPORT_METAPARAMETRI_UPDATE_ON_CREATE_LOCK_EXPIRE})"
    common_options 'cancellazione_eccezioni_per_etichetta', "Esegue la cancellazione delle eccezioni su base etichetta"
    
    def cancellazione_eccezioni_per_etichetta
      expire = options[:lock_expire] || config[CANCELLAZIONE_ECCEZIONI_PER_ETICHETTA_LOCK_EXPIRE],
      log_prefix = "Cancellazione eccezioni per etichetta, expire=#{expire}"
      Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: log_prefix) do
        raise "Sistema con id (#{options[:sistema_id]}) non esistente" unless (sistema = Db::Sistema.first(id: options[:sistema_id]))
        res = { 'Etichette' => options[:etichette].map { |et| et == LABEL_NC_DB ? MSG_SENZA_ETICHETTA : et } }
        (entita_label = sistema.entita(archivio: ARCHIVIO_LABEL).first).con_lock do
          (entita_eccezioni = sistema.entita(archivio: ARCHIVIO_ECCEZIONI).first).con_lock do
            res[entita_label.table_name] = { 'del' => 0 }
            res[entita_eccezioni.table_name] = { 'upd' => 0 }
            entita_eccezioni.db.transaction do
              entita_eccezioni.dataset.join(entita_label.dataset.where(label: options[:etichette]).group_by(:dist_name)
                                                        .select(:dist_name, Sequel.lit("array_agg(meta_parametro) as mp")), dist_name: :dist_name).each do |rec|
                par = (rec[:parametri] || {}).delete_if { |k, _v| rec[:mp].include?(k) || (k.index('.') && Regexp.new("^#{rec[:mp].join("|^")}").match(k)) }
                res[entita_eccezioni.table_name]['upd'] += entita_eccezioni.dataset.where(id: rec[:id]).update(parametri: par.to_json, updated_at: Time.now)
              end
              deleted = entita_label.dataset.where(label: options[:etichette]).delete
              res[entita_label.table_name]['del'] = deleted
              # aggiornamento data_ultimo_import nell'anagrafica etichette
              Irma::Db::EtichettaEccezioni.where(nome: options[:etichette] - [LABEL_NC_DB]).update(data_ultimo_import: Time.now.to_s)
            end
          end
        end
        res
      end
    ensure
      cleanup_temp_files
    end

    private

    def pre_cancellazione_eccezioni_per_etichetta
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
 
