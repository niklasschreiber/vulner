# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160217
#

require 'irma/db'

module Irma
  #
  class Command < Thor
    common_options 'lista_competenza_vendor', 'Fornisce la lista dei possibili vendor da specificare come competenza'
    def lista_competenza_vendor
      Db::Vendor.map(&:nome)
    end
    common_options 'lista_competenza_rete', 'Fornisce la lista delle possibili reti da specificare come competenza'
    def lista_competenza_rete
      Db::Rete.map(&:nome)
    end
    common_options 'lista_competenza_omcfisico', 'Fornisce la lista dei possibili omc_fisici da specificare come competenza'
    def lista_competenza_omcfisico
      Db::OmcFisico.map(&:nome)
    end
    method_option :matricola, aliases: '-m', type: :string, banner: 'Matricola dell\'utente da creare'
    method_option :profilo, aliases: '-p', type: :string, banner: 'Profilo da associare all\'utente (nome profilo oppure profilo_id)'
    method_option :competenze_rete, aliases: '-r', type: :string, banner: 'Array competenze rete (nome o id)', default: COMPETENZA_TUTTO
    method_option :competenze_vendor, aliases: '-v', type: :string, banner: 'Array competenze vendor (nome o id)', default: COMPETENZA_TUTTO
    method_option :competenze_omc_fisico, aliases: '-f', type: :string, banner: 'Array competenze omc_fisico (nome o id)', default: COMPETENZA_TUTTO
    method_option :competenze_sistema, aliases: '-s', type: :string, banner: 'Array competenze sistema (id)', default: COMPETENZA_TUTTO
    method_option :ignora_errore_ldap, aliases: '-i', type: :boolean, banner: 'Ignora errore ldap', default: false
    common_options 'crea_account', 'Crea un nuovo account per il sistema Irma'
    def crea_account # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      start_time = Time.now
      matricola = options[:matricola]
      competenze = determina_competenze(options[:competenze_rete], options[:competenze_vendor], options[:competenze_omc_fisico], options[:competenze_sistema])
      u = Db::Utente.first(matricola: matricola)
      user_info = if u
                    u.attributes.select { |k, _v| %i(nome cognome dipartimento email).include?(k) }
                  else
                    begin
                      ui = Ds_ti.get_user_info(matricola, %w(cn givenName sn department mail mobile))
                      { 'nome' => ui['givenName'], 'cognome' => ui['sn'], 'dipartimento' => ui['department'], 'email' => ui['mail'], 'mobile' => ui['mobile'] }
                    rescue
                      raise unless options[:ignora_errore_ldap]
                      { 'nome' => matricola, 'cognome' => matricola }
                    end
                  end
      acc = Db::Account.define(matricola, options[:profilo], user_info.merge(competenze: competenze).symbolize_keys)
      puts "Creato account per matricola #{matricola} (#{Constant.key(:profilo, acc.profilo_id)}) con competenze: #{competenze} in #{(Time.now - start_time).round(1)} secondi"
    end

    private

    def pre_crea_account
      Db.init(env: options[:env], logger: logger, load_models: true)
      ModConfig.load_from_db
    end

    def traduci_competenze(classe, dati)
      return COMPETENZA_TUTTO if dati == COMPETENZA_TUTTO
      (dati.is_a?(Array) ? dati : dati.split(',')).map do |xx|
        if xx.to_i.to_s == xx.to_s
          xx.to_i
        else
          s = classe.where(nome: xx).first
          s.id if s
        end
      end.compact.uniq
    end

    def determina_competenze(rete, vendor, omc, sist)
      comp_rete = traduci_competenze(Db::Rete, rete)
      comp_vendor = traduci_competenze(Db::Vendor, vendor)
      comp_omc_fisico = traduci_competenze(Db::OmcFisico, omc)
      comp_sistema = traduci_competenze(Db::Sistema, sist)
      { 'sistema' => { vendors: comp_vendor, reti: comp_rete, omc_fisici: comp_omc_fisico, sistemi: comp_sistema } }
    end
  end
end
