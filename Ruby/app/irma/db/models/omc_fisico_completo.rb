# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

module Irma
  module Db
    class OmcFisicoCompleto < Model(:omc_fisici_completi)
      plugin :timestamps, update_on_create: true

      def self.cache_enabled?
        !@cache_disabled
      end

      COLUMNS_NO_CHANGEABLE = [:vendor_id].freeze
      def before_update
        x = (COLUMNS_NO_CHANGEABLE & changed_columns)
        raise "Non e' consentito modificare il/i campo/i (#{x}) di un #{self.class}" unless x.empty?
        super
      end

      def before_destroy
        raise "OmcFisicoCompleto #{id} (#{nome}) utilizzato da almeno un omc fisico parziale" if omc_fisici_parziali.count > 0
        ProgettoRadio.where(omc_fisico_completo_id: id).delete
        super
      end

      # def self.tipo_competenza
      #   TIPO_COMPETENZA_OMCFISICO
      # end

      # def tipo_competenza
      #   self.class.tipo_competenza
      # end

      # def competenza
      #   { tipo_competenza => id.to_s }
      # end

      def descr
        nome
      end

      def full_descr
        @full_descr ||= "#{nome} (#{vendor.nome})"
      end

      def str_descr
        @str_descr ||= "#{nome}_#{vendor.nome}"
      end

      def vendor
        @vendor ||= Vendor.find(id: vendor_id)
      end

      def omc_fisici_parziali
        @omc_fisici_parziali ||= OmcFisico.where(omc_fisico_completo_id: id).all
      end

      def sistemi
        @sistemi ||= Sistema.where(omc_fisico_id: omc_fisici_parziali.map(&:id)).all
      end

      def vendor_instance
        @vendor_instance ||= Irma::Vendor.instance(vendor: vendor_id)
      end
    end
  end
end

# == Schema Information
#
# Tabella: omc_fisici_completi
#
#  created_at :datetime
#  id         :integer         non nullo, default(nextval('omc_fisici_completi_id_seq')), chiave primaria
#  nome       :string(64)      non nullo
#  updated_at :datetime
#  vendor_id  :integer         non nullo, riferimento a vendors.id
#
# Indici:
#
#  uidx_omc_fisici_completi  (nome) UNIQUE
#
