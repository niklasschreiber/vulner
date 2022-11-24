# vim: set fileencoding=utf-8
#
# Author: G.cristelli
#
# Creation date: 20151123
#

require 'json'

# == Scopo
#
# Definisce un parametro di configurazione dell'applicazione
#
# == Utilizzo
#
#   p = AppConfig.define(:nome_modulo, :nome_parametro, 'valore di default')
#   p.save
#
module Irma
  module Db
    #
    class AppConfig < Model(:app_config)
      plugin :timestamps, update_on_create: true

      validates_constant :ambito

      def after_update
        super
        pubblica_sulla_coda(PUB_APP_CONFIG, action: 'update', delay: 1)
      end

      # Il valore del parametro non e' valido
      class ValoreNonValido < IrmaException; end

      # Il parametro richiesto non esiste nel DB
      class NonEsistente < IrmaException; end

      def self.ricarica_dal_db(id)
        p = first(id: id)
        if p
          ModConfig.instance(p.modulo).define(p.nome, p.valore_di_default).model = p
          logger.info("Modulo #{p.modulo}, parametro #{p.nome}, valore ricaricato dal DB: #{p.valore.inspect} (default: #{p.valore_di_default.inspect})")
        end
        p
      end

      # Imposta a +v+ il valore del parametro, effettuando la conversione in JSON
      def valore=(v)
        begin
          @valore = v || valore_di_default
          json_value = [@valore].to_json
        rescue
          raise ValoreNonValido, "AppConfig #{modulo}, parametro #{nome}, assegnazione valore non valida: |#{v}|"
        end
        super(json_value)
        self.valore_di_default = v if valore_di_default.nil?
        @valore
      end

      # Ritorna il valore del parametro, decodificando il valore memorizzato realmente nel DB in formato JSON
      def valore
        unless @valore
          v = super
          return nil if v.nil?
          begin
            @valore = JSON.parse(v)[0]
          rescue => e
            raise ValoreNonValido, "AppConfig #{modulo}, parametro #{nome}, valore non valido: |#{v}| (#{e})"
          end
        end
        @valore
      end

      # Imposta a +v+ il valore del parametro, effettuando la conversione in JSON
      def valore_di_default=(v)
        begin
          json_value = [v].to_json
          @valore_di_default = v
        rescue
          raise ValoreNonValido, "AppConfig #{modulo}, parametro #{nome}, assegnazione valore di default non valida: |#{v}|"
        end
        super(json_value)
        @valore_di_default
      end

      # Ritorna il valore di default del parametro, decodificando il valore memorizzato realmente nel DB in formato JSON
      def valore_di_default
        unless @valore_di_default
          v = super
          return nil if v.nil?
          begin
            @valore_di_default = JSON.parse(v)[0]
          rescue => e
            raise ValoreNonValido, "AppConfig #{modulo}, parametro #{nome}, valore di default non valido: |#{v}| (#{e})"
          end
        end
        @valore_di_default
      end

      # Return the updated DB parameter object
      def refresh # rubocop:disable Metrics/AbcSize
        p = self
        p_old = self.class.get(modulo, nome)
        if p_old
          p_old.ambito = p.ambito
          p_old.widget_info = p.widget_info
          p_old.descr = p.descr
          p_old.valore_di_default = p.valore_di_default
          p_old.profili = p.profili
          p = p_old
        end
        logger.info("AppConfig #{modulo}, parametro #{nome} aggiornato nel DB (valore=#{p.valore}, default=#{p.valore_di_default})") if p.save_changes
        p
      end

      # Definisce un nuovo parametro per il modulo +mod+ con nome +name+ e valore di default +def_value+.
      # +opts+ e' un hash di opzioni:
      # * :ambito
      # * :descr
      # * :widget_info
      def self.define(mod, name, def_value, opts = {})
        options = { ambito: APP_CONFIG_AMBITO_GUI, modulo: mod.to_s, nome: name.to_s, valore: def_value,
                    profili: PROFILI_PER_PARAMETRO_DI_GA }.merge(opts)
        new(options)
      end

      # Ritorna l'oggetto AppConfig con modulo +mod+ e nome +name+ oppure nil se l'oggetto non esiste nel DB
      def self.get(mod, name)
        first(modulo: mod.to_s, nome: name.to_s)
      end

      def self.get_value(p)
        db_param = get(p.modulo, p.nome)
        db_param ? db_param.valore : p.valore
      end

      def self.set_value(mod, name, v)
        db_param = get(mod, name)
        db_param.valore = v
        db_param.save_changes
        db_param
      end
    end
  end
end

# == Schema Information
#
# Tabella: app_config
#
#  ambito            :integer         non nullo, default(2)
#  created_at        :datetime
#  descr             :string          default('')
#  id                :integer         non nullo, default(nextval('app_config_id_seq')), chiave primaria
#  modulo            :string(128)     non nullo
#  nome              :string(128)     non nullo
#  profili           :json
#  updated_at        :datetime
#  valore            :string          non nullo
#  valore_di_default :string          non nullo
#  widget_info       :string          default('')
#
# Indici:
#
#  uidx_app_config_modulo_nome  (modulo,nome) UNIQUE
#
