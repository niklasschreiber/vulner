# vim: set fileencoding=utf-8
#
# Author       : R. Scandale
#
# Creation date: 20180301
#

module Irma
  module Db
    #
    class TipoAttivitaConsistencyCheck < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_CONSISTENCY_CHECK

      config.define EXPIRE_CONSISTENCY_CHECK = :expire_consistency_check, 5_400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:28800})'

      config.define EXPIRE_SINTESI_CONSISTENCY_CHECK = :expire_sintesi_consistency_check, 900,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:60, maxValue:7_200})'

      #
      module Util
        extends_host_with :ClassMethod

        # override default, removing all PI and RC generated before removing Attivita records
        def rimuovi_attivita_obsolete(obsolete_date) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
          super(obsolete_date) do |att_root|
            Attivita.where(root_id: att_root.id).each do |att|
              ic = att.info_comando
              next unless ic
              idx_account_id = ic.index('--account_id')
              next unless idx_account_id && (acc_id = ic[idx_account_id + 1])
              att_result = (att.risultato && att.risultato['result']) || att.risultato
              if (nome_pi = att_result && att_result['pi'] && att_result['pi']['nome_progetto_irma'])
                pi = ProgettoIrma.first(account_id: acc_id, nome: nome_pi)
                pi.destroy if pi
              end
              next unless (nome_rc = att_result && att_result['rc'] && att_result['rc']['nome_report_comparativo'])
              rc = ReportComparativo.first(account_id: acc_id, nome: nome_rc)
              rc.destroy if rc
            end
          end
        end

        #
        module ClassMethod
          def ia_consistency_check(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
            res = []
            info_comando = {
              'parametri_comuni' => { 'account_id' => opts['account_id'], 'archivio' => opts['archivio'] || ARCHIVIO_RETE },
              'info'             => { 'key_pid' => contenitore['key'], 'expire_sec' => config[EXPIRE_CONSISTENCY_CHECK] }.merge(seleziona_opzioni_per_account(opts))
            }
            index_foglia = idx_f
            sintesi_dipende_da = []
            opts['lista_sistemi'].each do |xxx|
              omc = xxx[0]
              info_comando['parametri_comuni'].update('omc_id' => omc.id.to_s)
              info_comando['parametri_comuni'].update('nome_progetto_irma' => opts['nome_progetto_irma']) if opts['nome_progetto_irma']
              info_comando['parametri_comuni'].update('nome_report_comparativo' => opts['nome_report_comparativo']) if opts['nome_report_comparativo']
              if opts['dipendenze_per_cc'] && opts['dipendenze_per_cc'][omc.omc_fisico_id]
                info_comando['info']['dipende_da'] = ["#{PREFIX_KEY_ATTIVITA_NEGATIVA}#{opts['dipendenze_per_cc'][omc.omc_fisico_id]}"]
              end
              res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{index_foglia += 1}", COMANDO_CONSISTENCY_CHECK,
                                               parametri_comando: info_comando['parametri_comuni'],
                                               info: info_comando['info'].merge('descr' => omc.full_descr, 'competenze' => { TIPO_COMPETENZA_SISTEMA => [omc.id.to_s] }))
              sintesi_dipende_da << "#{PREFIX_KEY_ATTIVITA_NEGATIVA}#{res.last['key']}"
            end
            res << crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{index_foglia += 1}", COMANDO_SINTESI_CONSISTENCY_CHECK,
                                             parametri_comando: { 'out_dir_root' => opts['out_dir_root'] || DIR_ATTIVITA_TAG },
                                             info: {
                                               'key_pid'    => contenitore['key'],
                                               'expire_sec' => config[EXPIRE_SINTESI_CONSISTENCY_CHECK],
                                               'competenze' => competenze_lista_obj(opts['lista_sistemi']),
                                               'dipende_da' => sintesi_dipende_da
                                             }.merge(seleziona_opzioni_per_account(opts)))
            res
          end

          def info_attivita_consistency_check(opts = {}, &block)
            aggiungi_opzioni_per_account(opts: opts)
            opts_root = {
              'expire_sec' => config[EXPIRE_CONSISTENCY_CHECK],
              'competenze' => competenze_lista_obj(opts['lista_sistemi'])
            }.merge(seleziona_opzioni_per_account(opts))
            [root = crea_root_info_attivita(opts_root)] + ia_consistency_check(0, root, opts, &block)
          end

          def lista_sistemi_per_cc(opts = {}) # rubocop:disable Metrics/AbcSize
            res = {}
            if opts['quali_sistemi'].nil?
              # rimozione dei sistemi di test e quelli HUAWEI GSM (fino al momento del porting dei template gerarchici)
              # ProgettoRadio.join(:sistemi, id: :sistema_id)
              #              .distinct
              #              .exclude(area_sistema: 'TT')
              #              .exclude(vendor_release_id: Irma::Db::VendorRelease.where(vendor_id: VENDOR_HUAWEI, rete_id: RETE_GSM).select_map(:id))
              #              .order(:descr, :rete_id).select(:sistema_id, :descr, :rete_id).each { |r| res[r[:sistema_id]] = r[:descr] }
              Sistema.exclude(area_sistema: 'TT')
                     .exclude(vendor_release_id: Irma::Db::VendorRelease.where(vendor_id: VENDOR_HUAWEI, rete_id: RETE_GSM).select_map(:id))
                     .order(:descr, :rete_id).select(:id, :descr, :rete_id)
                     .each { |r| res[r[:id]] = r[:descr] if ProgettoRadio.where_sistema_id(r[:id]).count > 0 }

            else
              Sistema.where(id: opts['quali_sistemi']).distinct.order(:descr, :rete_id).select(:id, :descr, :rete_id).each { |r| res[r[:id]] = r[:descr] }
              raise 'Specificare sistemi esistenti' if res == {}
            end
            lista_sistemi_id_to_obj(res.keys.map { |sistema_id| [sistema_id] })
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_consistency_check(opts)
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
