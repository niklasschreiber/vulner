# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20151123
#

module Irma
  module Db
    #
    class Profilo < Model(:profili)
      plugin :timestamps, update_on_create: true

      # has_many :accounts
      unrestrict_primary_key

      validates_constant :ambiente

      # Il valore dell'attributo non e' valido
      class ValoreNonValido < IrmaException; end

      # Imposta a +v+ il funzioni, effettuando la conversione in JSON
      def funzioni=(v)
        p = nil
        begin
          p = v || funzioni_di_default
          json_value = [p].flatten.to_json
        rescue
          raise ValoreNonValido, "Permesso #{nome}, assegnazione funzioni non valida: |#{v}|"
        end
        super(json_value)
        self.funzioni_di_default = v if funzioni_di_default.nil?
        p
      end

      # Ritorna il funzioni del profilo, decodificando il funzioni memorizzato realmente nel DB in formato JSON
      def funzioni
        v = super
        return funzioni_di_default unless v
        begin
          JSON.parse(v)
        rescue => e
          raise ValoreNonValido, "Permesso #{nome}, attributo funzioni non valido: |#{v}| (#{e})"
        end
      end

      # Imposta a +v+ il funzioni del profilo, effettuando la conversione in JSON
      def funzioni_di_default=(v)
        pd = nil
        begin
          json_value = [v].flatten.to_json
          pd = v
        rescue
          raise ValoreNonValido, "Permesso #{nome} assegnazione funzioni di default non valida: |#{v}|"
        end
        super(json_value)
        pd
      end

      # Ritorna il funzioni di default del profilo, decodificando il funzioni memorizzato realmente nel DB in formato JSON
      def funzioni_di_default
        v = super
        return nil if v.nil?
        begin
          JSON.parse(v)
        rescue => e
          raise ValoreNonValido, "Permesso #{nome}, attributo funzioni_di_default non valido: |#{v}| (#{e})"
        end
      end

      def traduci_tipi_competenza(tipo_comp)
        return [] unless tipo_comp
        Constant.values(:tipo_competenza).map do |tc|
          Constant.info(:tipo_competenza, tc)[:descr] if (tipo_comp & tc) > 0
        end.compact
      end

      def tipi_competenze
        funzioni.collect { |f| traduci_tipi_competenza(Constant.info(:funzione, f)[:tipo_competenza]) || [] }.flatten.uniq
      end
    end
  end
end

# == Schema Information
#
# Tabella: profili
#
#  ambiente            :string(10)      non nullo
#  created_at          :datetime
#  descr               :string(255)     non nullo
#  funzioni            :string
#  funzioni_di_default :string          non nullo
#  id                  :integer         non nullo, chiave primaria
#  nome                :string(64)      non nullo
#  updated_at          :datetime
#
# Indici:
#
#  uidx_profili_nome  (nome) UNIQUE
#
