# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20170118
#

# rubocop:disable all
module Irma
  #
  class Command < Thor
    config.define REPORT_COMP_LOCK_EXPIRE = :report_comp_lock_expire, 1800,
      descr:         'Periodo (in sec.) per l\'expire del lock per il comando di report comparativo',
      widget_info:   'Gui.widget.positiveInteger({minValue:60,maxValue:86400})'

    method_option :nome,                    type: :string,  banner: 'Nome del Report Comparativo'
    method_option :account_id,              type: :numeric, banner: 'Identificativo dell\'account che esegue il comando'
    method_option :origine_1,               type: :string,  banner: 'Origine della fonte 1 (sistema_id, omc_fisico_id, pi_id o pi_nome)'
    method_option :valore_1,                type: :string,  banner: 'Identificativo dell\'origine 1'
    method_option :archivio_1,              type: :string,  banner: "Archivio fonte dati 1'", default: ARCHIVIO_RETE
    method_option :origine_2,               type: :string,  banner: 'Origine della fonte 2 (sistema_id, omc_fisico_id, pi_id o pi_nome)'
    method_option :valore_2,                type: :string,  banner: 'Identificativo dell\'origine 2'
    method_option :archivio_2,              type: :string,  banner: "Archivio fonte dati 2'", default: ARCHIVIO_CONF
    method_option :flag_presente,           type: :boolean, banner: 'Vengono confrontate anche le entita uguali', default: false
    method_option :filtro_metamodello_file, type: :string,  banner: 'File contenente filtro su meta_entita e relativi parametri'
    method_option :lock_expire,             type: :numeric, banner: "Secondi per l'expire del lock (default valore di configurazione #{REPORT_COMP_LOCK_EXPIRE})"
    method_option :env, aliases: '-e', type: :string, banner: 'Environment', default: Db.env, enum: %w(production development test)

    common_options 'report_comparativo', "Esegue la comparazione tra due archivi di entita (rete, configurazione o progetti irma)"
    def report_comparativo
      saa = {}
      fonte = {}
      {f1: 1, f2: 2}.each do |k, idx|
        saa[k] = case options[:"origine_#{idx}"]
                   when 'sistema_id'
                     Db::SistemaAmbienteArchivio.new(sistema: options[:"valore_#{idx}"], archivio: options[:"archivio_#{idx}"], account: options[:account_id])
                   when 'omc_fisico_id'
                     Db::OmcFisicoAmbienteArchivio.new(omc_fisico: options[:"valore_#{idx}"], archivio: options[:"archivio_#{idx}"], account: options[:account_id])
                   when 'pi_id', 'pi_nome'
                     value = (options[:"origine_#{idx}"] == 'pi_id') ? options[:"valore_#{idx}"].to_i : options[:"valore_#{idx}"]
                     pi = options[:"origine_#{idx}"] == 'pi_id' ? Db::ProgettoIrma.first(id: value, account_id: options[:account_id]) : Db::ProgettoIrma.first(nome: value, account_id: options[:account_id])
                     raise 'PI non trovato (#{options})' unless pi
                     s = pi.sistema_id ? Db::SistemaAmbienteArchivio.new(sistema: pi.sistema_id, archivio: ARCHIVIO_RETE, account: options[:account_id])
                     : Db::OmcFisicoAmbienteArchivio.new(omc_fisico: pi.omc_fisico_id, archivio: ARCHIVIO_RETE, account: options[:account_id])
                     s.associa_progetto_irma(nome: pi.nome)
                     s
                   end
        next unless saa[k]
        fonte[k] = { ambiente: saa[k].ambiente }
        if saa[k].pi
          fonte[k][:nome_progetto_irma] = saa[k].pi.nome
        else
          fonte[k][:archivio] = saa[k].archivio
        end
        fonte[k][:n_entita] = saa[k].dataset(use_pi: saa[k].pi).count
      end

      raise "Sistema/OmcFisico non validi" unless saa[:f1] && saa[:f2]
      
      # --- Info aggiuntive di report_comparativo
      info = {}
      # - flag_presente
      info[:flag_presente] = options[:flag_presente]
      # - pi_sistema_id
      #   se fonte1 e' un PI             --> sistema_id di fonte1;
      #   altrimenti, se fonte2 e' un PI --> sistema_id di fonte2,
      #   altrimenti                     --> nil
      pi_sistema_id = if saa[:f1].pi
                        saa[:f1].pi.pi_sistema_id
                      elsif saa[:f2].pi
                        saa[:f2].pi.pi_sistema_id
                      end
      info[:pi_sistema_id] = pi_sistema_id if pi_sistema_id
      # -------------------------------------------
      saa[:f1].crea_report_comparativo(nome: options[:nome], account_id: options[:account_id], fonte_1: fonte[:f1], fonte_2: fonte[:f2], info: info )
      rc_opts = { 
        attivita_id:        options[:attivita_id],
        stats:              true,
        expire:             options[:lock_expire] || config[REPORT_COMP_LOCK_EXPIRE],
        flag_presente:      info[:flag_presente],
        filtro_metamodello: determina_filtro_mm(filtro_mm_file: options[:filtro_metamodello_file], filtro_mm: nil)
      }
      rc_opts[:log_prefix] = "Report Comparativo tra la fonte 1 #{saa[:f1].full_descr} e la fonte 2 #{saa[:f2].full_descr} account=#{saa[:f1].account.full_descr}" +
      " expire=#{rc_opts[:expire]}"
      res = {nome_report_comparativo: options[:nome] }
      res.update(Irma.esegui_e_memorizza_durata(logger: logger, log_prefix: rc_opts[:log_prefix]) { saa[:f1].esegui_report_comparativo(saa_delta: saa[:f2], **rc_opts) }) 
      res
    end

    private

    def pre_report_comparativo
      Db.init(env: options[:env], logger: logger, load_models: true)
    end
  end
end
