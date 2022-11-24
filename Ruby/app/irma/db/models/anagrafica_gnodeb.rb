# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20190402
#

require 'irma/db/nodi_nodeb'
module Irma
  class GnodebGiaAnagrafato < IrmaException; end
  class GnodebNameNonCorretto < IrmaException; end
  class GnodebNameNoProvincia < IrmaException; end
  class GnodebNameNoAreaTerritoriale < IrmaException; end
  class GnodebNoIdLiberi < IrmaException; end
  module Db
    #
    class AnagraficaGnodeb < Model(:anagrafica_gnodeb)
      include NodoNodeb
      plugin :timestamps, update_on_create: true
      validates_constant :area_territoriale

      if defined?(RETE_5G)
        config.define REG_EXPR_NOME_GNODEB = 'reg_expr_nome_gnodeb'.freeze, Constant.info(:rete, RETE_5G)[:reg_expr_nome_nodo],
                      descr: 'Regular Expression per validazione del nome del gnodeb',
                      widget_info: 'Gui.widget.string()',
                      profili: PROFILI_PER_PARAMETRO_DI_RPN
      end

      def before_create
        gnodeb_name.upcase!
      end

      def self.nodeb_rete
        RETE_5G
      end

      def self.nodeb_field_id
        :gnodeb_id
      end

      def self.nodeb_field_name
        :gnodeb_name
      end

      def self.con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_ANAGRAFICA_GNODEB, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def self.nuovo_nodo(nome_nodo:, id_nodo: nil, lock: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        nome_nodo = (nome_nodo || '').upcase
        raise GnodebGiaAnagrafato, format_msg(:NUOVO_GNODEBID_DATI_GNODEB_GIA_ANAGRAFATO, gnodeb_name: nome_nodo) if where(gnodeb_name: nome_nodo).first
        raise GnodebNameNonCorretto, format_msg(:NUOVO_GNODEBID_DATI_GNODEB_ERRATO, gnodeb_name: nome_nodo) unless nome_nodo.match(config[REG_EXPR_NOME_GNODEB])
        prov = Irma::AnagraficaTerritoriale.provincia_da_nome_cella(nome_nodo)
        raise GnodebNameNoProvincia, format_msg(:NUOVO_GNODEBID_DATI_GNODEB_NO_PROVINCIA, gnodeb_name: nome_nodo) unless prov
        at = Irma::AnagraficaTerritoriale.at_di_provincia(prov).first
        raise GnodebNameNoAreaTerritoriale, format_msg(:NUOVO_GNODEBID_DATI_GNODEB_NO_AT, gnodeb_name: nome_nodo) unless at
        con_lock(enable: lock, logger: logger) do
          new_id = new_id_anagrafica(area_terr: at, id_nodo: id_nodo)
          raise GnodebNoIdLiberi, format_msg(:NUOVO_GNODEBID_DATI_GNODEB_NO_ID_LIBERI, area_territoriale: at) unless new_id
          create(gnodeb_name: nome_nodo, gnodeb_id: new_id, area_territoriale: at)
        end
      end
    end
  end
end

# == Schema Information
#
# Tabella: anagrafica_gnodeb
#
#  area_territoriale :string(5)       non nullo
#  created_at        :datetime
#  gnodeb_id         :string(128)     non nullo
#  gnodeb_name       :string(128)     non nullo
#  id                :integer         non nullo, default(nextval('anagrafica_gnodeb_id_seq')), chiave primaria
#  updated_at        :datetime
#
# Indici:
#
#  uidx_anagrafica_gnodeb_gnodeb_id    (gnodeb_id) UNIQUE
#  uidx_anagrafica_gnodeb_gnodeb_name  (gnodeb_name) UNIQUE
#
