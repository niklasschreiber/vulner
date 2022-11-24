# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaCleanupDb < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_CLEANUP_DB

      def self.info_attivita(opts = {})
        [crea_root_info_attivita(opts.merge('competenze' => { TIPO_COMPETENZA_ADMIN => COMPETENZA_TUTTO })),
         crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}1", COMANDO_CLEANUP_DB,
                                   parametri_comando: {}, info: { 'competenze' => { TIPO_COMPETENZA_ADMIN => COMPETENZA_TUTTO } })]
      end
    end
  end
end

# == Schema Information
#
# Tabella: tipi_attivita
#
#  broadcast  :boolean         non nullo, default(false)
#  created_at :datetime
#  descr      :string          default('')
#  id         :integer         non nullo, chiave primaria
#  kind       :string
#  nome       :string(128)     non nullo
#  singleton  :boolean         non nullo, default(false)
#  stato      :string(32)      default('attivo')
#  updated_at :datetime
#
# Indici:
#
#  uidx_tipo_attivita_kind  (kind) UNIQUE
#
