# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20180802
#

module Irma
  module Db
    #
    class CiRegione < Model(:ci_regioni)
      plugin :timestamps, update_on_create: true

      config.define SOGLIA_CI_LIBERI = :soglia_ci_liberi, 20,
                    descr:         'Soglia di warning per la percentuale di CI liberi',
                    widget_info:   'Gui.widget.positiveInteger({minValue:0,maxValue:100})',
                    profili:       PROFILI_PER_PARAMETRO_DI_RPN

      def self.cleanup(_hash = {})
        cleanup_only_rebuild_indexes
      end

      def self.con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_CI_REGIONE, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def self.occupa_free_ci(rete_id:, regione:, ci: nil, enable_lock: true) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        con_lock(enable: enable_lock) do
          transaction do
            ci_reg = if ci
                       where(rete_id: rete_id, regione: regione, ci: ci, busy: CI_REGIONE_BUSY_NO).first
                     else
                       where(rete_id: rete_id, regione: regione, busy: CI_REGIONE_BUSY_NO).order(:ci).first
                     end
            return nil unless ci_reg
            ci_reg.update(busy: CI_REGIONE_BUSY_SI)
            AnagraficaTerritoriale.confinanti_di_regione(regione).each do |regione_conf|
              where(rete_id: rete_id, regione: regione_conf, ci: ci_reg.ci).each do |conf|
                conf.update(busy: CI_REGIONE_BUSY_CONFINANTE)
              end
            end
            ci_reg.ci
          end
        end
      end

      # torna un array con le regioni confinanti e stato CI_REGIONE_BUSY_SI
      def confinanti_busy
        confinanti_busy = []
        return confinanti_busy if busy != CI_REGIONE_BUSY_CONFINANTE
        AnagraficaTerritoriale.confinanti_di_regione(regione).each do |regione_conf|
          x = CiRegione.first(ci: ci, rete_id: rete_id, regione: regione_conf)
          confinanti_busy << regione_conf if x && x.busy == CI_REGIONE_BUSY_SI
        end
        confinanti_busy
      end

      def self.libera_ci(ci:, rete_id:, regione:, enable_lock: true)
        con_lock(enable: enable_lock) do
          transaction do
            ci_reg = first(ci: ci, rete_id: rete_id, regione: regione)
            return nil if ci_reg.nil? || ci_reg.busy != CI_REGIONE_BUSY_SI # gia' libero
            AnagraficaTerritoriale.confinanti_di_regione(regione).each do |regione_conf|
              conf_cir = first(ci: ci, rete_id: rete_id, regione: regione_conf)
              next unless conf_cir
              conf_busy = conf_cir.confinanti_busy
              conf_cir.update(busy: CI_REGIONE_BUSY_NO) if (conf_busy - [regione]).empty?
            end
            ci_reg.update(busy: CI_REGIONE_BUSY_NO)
            ci_reg
          end
        end
      end

      def self.check_consistenza_busy(rete_id: nil, ci: nil, regione: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        result = {}
        reti = rete_id ? [rete_id] :  [RETE_UMTS, RETE_GSM]
        regioni = regione ? [regione] : AnagraficaTerritoriale::REGIONI.keys
        cis = ci ? [ci] : TUTTI_I_CI

        cache = {}
        # where(ci: cis, rete_id: reti).each { |xx| cache[[xx[:ci], xx[:rete_id], xx[:regione]].join('-')] = xx[:busy] }
        each { |xx| cache[[xx[:ci], xx[:rete_id], xx[:regione]].join('-')] = xx[:busy] }
        reti.each do |la_rete|
          regioni.each do |la_regione|
            cis.each do |il_ci|
              # xxx = first(ci: il_ci, rete_id: la_rete, regione: la_regione)
              # next if xxx.nil? || xxx.busy == CI_REGIONE_BUSY_NO
              xxx = cache[[il_ci, la_rete, la_regione].join('-')]
              next if xxx.nil? || xxx == CI_REGIONE_BUSY_NO
              confinanti = AnagraficaTerritoriale.confinanti_di_regione(la_regione)
              if xxx == CI_REGIONE_BUSY_SI
                confinanti_ko = 0
                confinanti.each do |confinante|
                  confinanti_ko += 1 if cache[[il_ci, la_rete, confinante].join('-')] != CI_REGIONE_BUSY_CONFINANTE
                end
                (result["#{la_rete}_#{la_regione}_#{il_ci}"] ||= {})[:confinanti_ko] = confinanti_ko if confinanti_ko > 0
              elsif xxx == CI_REGIONE_BUSY_CONFINANTE
                confinante_busy = nil
                confinanti.each do |confinante|
                  next unless cache[[il_ci, la_rete, confinante].join('-')] == CI_REGIONE_BUSY_SI
                  confinante_busy = confinante
                  break
                end
                (result["#{la_rete}_#{la_regione}_#{il_ci}"] ||= {})[:wrong_busy_confinante] = true unless confinante_busy
              end
            end
          end
        end
        result
      end

      def self.percentuale_ci_liberi(ci_liberi)
        (100.0 * ci_liberi / MAX_CI).round(0)
      end

      def self.soglia_ci_liberi_superata?(percent_ci_liberi)
        percent_ci_liberi <= config[SOGLIA_CI_LIBERI].to_i
      end
    end
  end
end

# == Schema Information
#
# Tabella: ci_regioni
#
#  busy       :integer         non nullo, default(0)
#  ci         :string(6)       non nullo
#  created_at :datetime
#  id         :integer         non nullo, default(nextval('ci_regioni_id_seq')), chiave primaria
#  regione    :string(32)      non nullo
#  rete_id    :integer         non nullo
#  updated_at :datetime
#
# Indici:
#
#  uidx_ci_regioni_rete_regione_ci  (ci,regione,rete_id) UNIQUE
#
