# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20160704
#

module Irma
  module Db
    #
    class TipoAttivitaImportCostruttoreOmcLogico < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_IMPORT_COSTRUTTORE_OMC_LOGICO

      config.define EXPIRE_IMPORT_COSTRUTTORE = :expire_import_costruttore, 5400,
                    descr: 'Timeout in secondi per l\'esecuzione del comando', widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      #
      module Util
        extends_host_with :ClassMethod

        #
        module ClassMethod
          include SharedFs::Util
          def ia_import_costruttore(idx_f, contenitore, opts = {}, &_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            res = []
            ic = { 'comando' => omc_fisico? ? COMANDO_IMPORT_COSTRUTTORE_OMC_FISICO : COMANDO_IMPORT_COSTRUTTORE_OMC_LOGICO,
                   'tipo_competenza' => omc_fisico? ? TIPO_COMPETENZA_OMCFISICO : TIPO_COMPETENZA_SISTEMA,
                   'info' => { 'key_pid' => contenitore['key'], 'expire_sec' => config[EXPIRE_IMPORT_COSTRUTTORE] }.merge(seleziona_opzioni_per_account(opts)),
                   'parametri_comuni' => { 'account_id' => opts['account_id'], 'archivio' => opts['archivio'] }
            }
            ic['parametri_comuni']['omc_fisico'] = true if omc_fisico?
            ic['parametri_comuni']['check_data'] = opts['check_data'] unless opts['check_data'].nil?
            ic['parametri_comuni']['ambiente'] = opts['ambiente'] if opts['ambiente']
            yield(ic) if block_given?

            opts['lista_sistemi'].each_with_index do |xxx, idx|
              sistema, input_file = xxx
              pc = ic['parametri_comuni'].merge('sistema_id' => sistema.id.to_i, 'input_file' => input_file)
              info_foglia = ic['info'].merge('descr' => sistema.full_descr, 'artifacts' => [input_file],
                                             'competenze' => { ic['tipo_competenza'] => [sistema.id.to_s] })

              res << (ultima_foglia = crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{idx_f + idx + 1}", ic['comando'], parametri_comando: pc, info: info_foglia))
              opts['dipendenze_per_cc'][sistema.id.to_i] = ultima_foglia['key'] if opts['dipendenze_per_cc']
            end
            res
          end

          # Ritorna un array di array, dove ogni sub-array e' [ sistema, input_file_audit ]
          # input_file_audit viene recuperato in remoto e messo nella dir di lavoro
          # Se opts['quali_sistemi'] e' una array di id di sistemi o omc_logici usa questa lista
          # altrimenti tutti
          def ricalcola_lista_sistemi(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            lista_sistemi = []
            classe = omc_fisico? ? OmcFisico : Sistema
            i_sistemi = opts['quali_sistemi'].nil? ? classe : classe.where(id: opts['quali_sistemi'])

            i_sistemi.order(:id).each do |sistema|
              if sistema.nome_file_audit.to_s.empty?
                logger.warn("Sistema #{sistema.full_descr} (#{sistema.id}) ignorato per l'attivita #{self} in quanto non è stato definito l'attributo nome_file_audit")
                next
              end
              remote_file = Irma.shared_relative_audit_file(sistema.nome_file_audit)
              begin
                input_file = nil
                input_file = Irma.replace_date_tags(File.join(opts['dir_attivita'], sistema.nome_file_audit))
                show_file = JSON.parse(shared_show_files(remote_file))
                shared_copy_file(remote_file, input_file)
                lista_sistemi << [sistema, input_file, show_file['dimensione']]
              rescue => e
                logger.warn("Sistema #{sistema.full_descr} (#{sistema.id}), riscontrato errore di put sullo shared_fs server del file di audit #{remote_file} come #{input_file} fallito (#{e}), " \
                            "utilizzo del #{remote_file} come input_file per consentire la schedulazione dell'attivita' e la conseguente generazione di errore")
                lista_sistemi << [sistema, remote_file, 0]
              end
            end
            lista_sistemi.sort_by { |x| x[2] }.reverse # sort by third element which is the size of file
          end

          def info_attivita_import_costruttore(opts = {}, &block)
            opts_root = {
              'expire_sec' => config[EXPIRE_IMPORT_COSTRUTTORE],
              'competenze' => competenze_lista_obj(opts['lista_sistemi'])
            }.merge(seleziona_opzioni_per_account(opts))
            [root = crea_root_info_attivita(opts_root)] + ia_import_costruttore(0, root, opts, &block)
          end
        end
      end

      include Util

      def self.info_attivita(opts = {})
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        info_attivita_import_costruttore(opts)
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
