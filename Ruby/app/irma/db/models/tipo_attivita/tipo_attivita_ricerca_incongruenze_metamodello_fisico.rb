# vim: set fileencoding=utf-8
#
# Author:        R. Scandale
#
# Creation date: 20180619
#

module Irma
  module Db
    #
    class TipoAttivitaRicercaIncongruenzeMetamodelloFisico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_RICERCA_INCONGRUENZE_METAMODELLO_FISICO

      config.define EXPIRE_RICERCA_INCONGRUENZE_METAMODELLO_FISICO = :expire_ricerca_incongruenze_metamodello_fisico, 1800,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/AbcSize
        lista_omcfisici_id = opts['lista_vr_id'].map { |vr_id| VendorReleaseFisico.get_by_pk(vr_id).omc_fisici.map { |omcf| omcf.id.to_s } }.flatten
        # res = [crea_root_info_attivita('expire_sec' => config[EXPIRE_RICERCA_INCONGRUENZE_METAMODELLO_FISICO], 'competenze' => { TIPO_COMPETENZA_VENDORRELEASEFISICO => opts['lista_vr_id'] })]
        res = [crea_root_info_attivita('expire_sec' => config[EXPIRE_RICERCA_INCONGRUENZE_METAMODELLO_FISICO], 'competenze' => { TIPO_COMPETENZA_OMCFISICO => lista_omcfisici_id })]
        opts['lista_vr_id'].each_with_index do |vr_id, idx|
          id = vr_id
          vr = VendorReleaseFisico.get_by_pk(vr_id)
          res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx + 1}", COMANDO_RICERCA_INCONGRUENZE_METAMODELLO_FISICO,
                                           parametri_comando: { 'account_id' => opts['account_id'], 'id_vendor_release' => id.to_s, 'out_dir_root' => opts['out_dir_root'] },
                                           info: { 'descr' => vr.full_descr, 'expire_sec' => config[EXPIRE_RICERCA_INCONGRUENZE_METAMODELLO_FISICO],
                                                   'competenze' => { TIPO_COMPETENZA_OMCFISICO => vr.omc_fisici.map { |omcf| omcf.id.to_s } } })
        end
        res
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
