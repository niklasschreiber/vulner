# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180802
#

module Irma
  class CellaGiaAnagrafataCgi < IrmaException; end
  class NomeCellaNonCorretto < IrmaException; end
  class NomeCellaNoRegione < IrmaException; end
  class NomeCellaNoRete < IrmaException; end
  class ValoreLacNonCorretto < IrmaException; end

  module Db
    #
    class AnagraficaCgi < Model(:anagrafica_cgi)
      plugin :timestamps, update_on_create: true

      def before_update # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        raise 'Non e\' consentito modificare i campi \'rete_id\' e \'regione\'' unless (changed_columns & [:rete_id, :regione]).empty?
        if changed_columns.member?(:nome_cella)
          diff_rete = (Irma.rete_da_nome_cella(nome_cella) != rete_id)
          diff_regione = (Irma::AnagraficaTerritoriale.regione_da_nome_cella(nome_cella) != regione)
          raise "Modifica di nome_cella non valida (implica cambio di #{diff_rete ? 'rete' : ''} #{diff_regione ? 'regione' : ''})" if diff_rete || diff_regione
        end
        super
      end

      def self.cleanup(_hash = {})
        cleanup_only_rebuild_indexes
      end

      def self.con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_ANAGRAFICA_CGI, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), enable: opts.fetch(:enable, true), **opts) do
          CiRegione.con_lock(enable: opts.fetch(:enable, true), **opts, &block)
        end
      end

      def self.cella_ok?(nome_cella)
        mm = nome_cella.to_s.match("^#{Irma.reg_expr_nome_cella_per_rete(RETE_GSM)}$") || nome_cella.to_s.match("^#{Irma.reg_expr_nome_cella_per_rete(RETE_UMTS)}$")
        return true if mm
        false
      end

      def self.lac_ok(valore_lac)
        return nil if !valore_lac.to_s.numeric? || valore_lac.to_i < 1 || valore_lac.to_i > 65_499
        format('%05d', valore_lac.to_i)
      end

      def self.update_lac(nome_cella:, nuovo_lac:)
        x = where(nome_cella: nome_cella).first
        raise "Cella #{nome_cella} non anagrafata" unless x
        raise ValoreLacNonCorretto, format_msg(:NUOVO_CGI_DATI_LAC_ERRATO, lac: nuovo_lac) unless lac_ok(nuovo_lac)
        x.update(lac: nuovo_lac)
      end

      def self.nuova_cella(nome_cella:, lac:, ci: nil, enable_lock: true) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
        new_ci = nil
        con_lock(enable: enable_lock, logger: logger) do
          # ---------------------
          nome_cella = nome_cella.to_s.upcase
          x = first(nome_cella: nome_cella)
          raise CellaGiaAnagrafataCgi, format_msg(:NUOVO_CGI_DATI_CELLA_GIA_ANAGRAFATA, nome_cella: nome_cella, lac: lac.to_s) if x
          # ---------------------
          # Check valore lac
          x_lac = lac_ok(lac)
          raise ValoreLacNonCorretto, format_msg(:NUOVO_CGI_DATI_LAC_ERRATO, lac: lac) unless x_lac

          # ---------------------
          # Check nome_cella
          raise NomeCellaNonCorretto, format_msg(:NUOVO_CGI_DATI_NOME_CELLA_ERRATO, nome_cella: nome_cella) unless cella_ok?(nome_cella)
          rete = Irma.rete_da_nome_cella(nome_cella)
          regione = Irma::AnagraficaTerritoriale.regione_da_nome_cella(nome_cella)
          raise NomeCellaNoRegione, format_msg(:NUOVO_CGI_DATI_NOME_CELLA_NO_REGIONE, nome_cella: nome_cella) unless regione

          # ---------------------
          transaction do
            new_ci = Db::CiRegione.occupa_free_ci(rete_id: rete, regione: regione, ci: ci, enable_lock: false)
            unless new_ci
              msg = ci ? "Valore ci richiesto '#{ci}' non" : 'Nessun valore ci'
              raise "#{msg} disponibile per la regione #{regione} e rete #{rete}"
            end
            create(nome_cella: nome_cella, rete_id: rete, regione: regione, ci: new_ci, lac: x_lac)
          end
        end
        new_ci
      end

      def self.elimina_cella(hash)
        # hash = { id: 72637, nome_cella: 'CHxxx'}
        # TODO: Valutare altre condizioni di cancellazione oltre l'id
        raise "Condizioni di cancellazione cgi non valide (#{hash})" if ((hash || {}).keys & [:id]).empty?
        con_lock(logger: logger) do
          x = first(hash)
          return unless x
          # TODO: Valutare se chiamare il libera_ci nell'after_delete di anagrafica_cgi
          transaction do
            CiRegione.libera_ci(ci: x.ci, rete_id: x.rete_id, regione: Irma::AnagraficaTerritoriale.regione_da_nome_cella(x.nome_cella), enable_lock: false)
            x.destroy
          end
        end
      end
    end
  end
end

# == Schema Information
#
# Tabella: anagrafica_cgi
#
#  ci         :string(6)       non nullo
#  created_at :datetime
#  id         :integer         non nullo, default(nextval('anagrafica_cgi_id_seq')), chiave primaria
#  lac        :string(32)      non nullo
#  nome_cella :string(128)     non nullo
#  regione    :string(32)      non nullo
#  rete_id    :integer         non nullo
#  updated_at :datetime
#
# Indici:
#
#  uidx_anag_cgi_nome_cella  (nome_cella) UNIQUE
#
