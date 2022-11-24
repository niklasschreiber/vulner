# vim: set fileencoding=utf-8
#
# Author: S. Campestrini
#
# Creation date: 20180918
#

module Irma
  module Db
    #
    class TipoAttivitaCompletaCgiImportProgettoRadio < TipoAttivita
      LABEL_ROOT = :ATTIVITA_ROOT_COMPLETA_CGI_IMPORT_PROGETTO_RADIO

      config.define EXPIRE_C_CGI_IMPORT_PR = :expire_c_cgi_import_pr, 5400, descr: 'Timeout in secondi per l\'esecuzione del comando',
                                                                            widget_info: 'Gui.widget.positiveInteger({minValue:900, maxValue:14400})'

      def self.info_attivita(opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        opts['lista_sistemi'] = lista_sistemi_id_to_obj(opts['lista_sistemi'])
        parametri_comando_comuni = { 'account_id' => opts['account_id'] }

        res = []
        contenitore_root = crea_root_info_attivita('expire_sec' => config[EXPIRE_C_CGI_IMPORT_PR], 'competenze' => competenze_lista_obj(opts['lista_sistemi']))
        res << contenitore_root
        lista_sistemi = opts['lista_sistemi']
        quanti = lista_sistemi.count
        count_contenitori = 0
        count_foglie = 0
        contenitore = nil
        lista_sistemi.each do |xxx|
          # devo aggiungere Compl.1->Import.1 se quanti=1, [Compl.n->Import.n] altrimenti
          sistema, input_file = xxx
          parametri_comando = parametri_comando_comuni.merge('sistema' => sistema, 'descr' => sistema.full_descr, 'competenze' => { sistema.tipo_competenza => [sistema.id.to_s] })
          if quanti > 1
            count_contenitori += 1
            contenitore = crea_contenitore_info_attivita("#{KEY_PREFIX_CONTENITORE}#{count_contenitori}",
                                                         format_msg(label_contenitore, descr: sistema.full_descr), 'competenze' => ic['competenze'])
            res << contenitore
          end
          # foglia_completa
          pc = parametri_comando.merge('sistema_id' => sistema.id, 'input_file' => input_file, 'out_dir_root' => opts['out_dir_root'])
          expire_completa = Db::TipoAttivitaCompletaCgi.config[Db::TipoAttivitaCompletaCgi::EXPIRE_COMPLETA_CGI]
          f_completa = crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{count_foglie}",
                                                 COMANDO_COMPLETA_CGI,
                                                 parametri_comando: pc,
                                                 info: { 'descr'      => sistema.full_descr,
                                                         'expire_sec' => expire_completa,
                                                         'key_pid'    => (contenitore || contenitore_root)['key'],
                                                         'artifacts'  => [input_file],
                                                         'competenze' => { TIPO_COMPETENZA_SISTEMA => [sistema.id.to_s] } })
          res << f_completa
          count_foglie += 1
          # foglia import
          input_file_pr = File.join(opts['out_dir_root'], File.add_str_nome_file(File.basename(input_file), COMPLETA_CGI_FILE_OUT_SUFFIX)).gsub(/.gz$/i, '.zip')
          pc = parametri_comando.merge('sistema_id' => sistema.id, 'input_file' => input_file_pr,
                                       'flag_cancellazione' => (opts['flag_cancellazione'] ? true : false))
          expire_import = Db::TipoAttivitaImportProgettoRadio.config[Db::TipoAttivitaImportProgettoRadio::EXPIRE_IMPORT_PR]
          f_import = crea_foglia_info_attivita("#{KEY_PREFIX_FOGLIA}#{count_foglie}", COMANDO_IMPORT_PROGETTO_RADIO,
                                               parametri_comando: pc,
                                               info: { 'descr' => sistema.full_descr,
                                                       'expire_sec' => expire_import,
                                                       # 'artifacts'  => [input_file_pr],
                                                       'key_pid'    => (contenitore || contenitore_root)['key'],
                                                       'dipende_da' => [f_completa['key']],
                                                       'competenze' => { TIPO_COMPETENZA_SISTEMA => [sistema.id.to_s] } })
          res << f_import
          count_foglie += 1
          if f_completa['expire_sec'] && f_import['expire_sec']
            contenitore_root['expire_sec'] = f_completa['expire_sec'] + f_import['expire_sec']
            contenitore['expire_sec'] = contenitore_root['expire_sec'] if contenitore
          end
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
