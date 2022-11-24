# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151204
#

require 'irma/db/nodi_nodeb'
module Irma
  class EnodebGiaAnagrafato < IrmaException; end
  class EnodebNameNonCorretto < IrmaException; end
  class EnodebNameNoProvincia < IrmaException; end
  class EnodebNameNoAreaTerritoriale < IrmaException; end
  class EnodebNoIdLiberi < IrmaException; end
  module Db
    #
    class AnagraficaEnodeb < Model(:anagrafica_enodeb)
      include NodoNodeb
      plugin :timestamps, update_on_create: true
      validates_constant :area_territoriale

      # TODO: allineare la regexpr all'approccio usato per il 5G
      config.define REG_EXPR_NOME_ENODEB = 'reg_expr_nome_enodeb'.freeze, '^[A-Z][0-9A-Z][0-9A-F][0-9A-F][LTEFNPM]$',
                    descr: 'Regular Expression per validazione del nome dell\'enodeb',
                    widget_info: 'Gui.widget.string()',
                    profili: PROFILI_PER_PARAMETRO_DI_RPN

      def before_create
        enodeb_name.upcase!
      end

      def self.nodeb_rete
        RETE_LTE
      end

      def self.nodeb_field_id
        :enodeb_id
      end

      def self.nodeb_field_name
        :enodeb_name
      end

      def self.con_lock(**opts, &block)
        Irma.lock(key: LOCK_KEY_ANAGRAFICA_ENODEB, mode: LOCK_MODE_WRITE, logger: opts.fetch(:logger, logger), **opts, &block)
      end

      def self.nuovo_nodo(nome_nodo:, id_nodo: nil, lock: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        nome_nodo = (nome_nodo || '').upcase
        raise EnodebGiaAnagrafato, format_msg(:NUOVO_ENODEBID_DATI_ENODEB_GIA_ANAGRAFATO, enodeb_name: nome_nodo) if where(enodeb_name: nome_nodo).first
        raise EnodebNameNonCorretto, format_msg(:NUOVO_ENODEBID_DATI_ENODEB_ERRATO, enodeb_name: nome_nodo) unless nome_nodo.match(config[REG_EXPR_NOME_ENODEB])
        prov = Irma::AnagraficaTerritoriale.provincia_da_nome_cella(nome_nodo)
        raise EnodebNameNoProvincia, format_msg(:NUOVO_ENODEBID_DATI_ENODEB_NO_PROVINCIA, enodeb_name: nome_nodo) unless prov
        at = Irma::AnagraficaTerritoriale.at_di_provincia(prov).first
        raise EnodebNameNoAreaTerritoriale, format_msg(:NUOVO_ENODEBID_DATI_ENODEB_NO_AT, enodeb_name: nome_nodo) unless at
        con_lock(enable: lock, logger: logger) do
          new_id = new_id_anagrafica(area_terr: at, id_nodo: id_nodo)
          raise EnodebNoIdLiberi, format_msg(:NUOVO_ENODEBID_DATI_ENODEB_NO_ID_LIBERI, area_territoriale: at) unless new_id
          create(enodeb_name: nome_nodo, enodeb_id: new_id, area_territoriale: at)
        end
      end
    end
  end
end

# == Schema Information
#
# Tabella: anagrafica_enodeb
#
#  area_territoriale :string(5)       non nullo
#  created_at        :datetime
#  enodeb_id         :string(128)     non nullo
#  enodeb_name       :string(128)     non nullo
#  id                :integer         non nullo, default(nextval('anagrafica_enodeb_id_seq')), chiave primaria
#  updated_at        :datetime
#
# Indici:
#
#  uidx_anagrafica_enodeb_enodeb_id    (enodeb_id) UNIQUE
#  uidx_anagrafica_enodeb_enodeb_name  (enodeb_name) UNIQUE
#
