# vim: set fileencoding=utf-8
#
# Author       : S. Campestrini
#
# Creation date: 20171026
#

require 'irma/idl_util'

module Irma
  #
  module Funzioni
    #
    class CreazioneFdc
      #
      class WriterFdc
        attr_reader :out_dir, :logger, :log_prefix
        attr_reader :stat

        LABEL_FIXED = '__LABEL_FIXED__'.freeze
        LABEL_FILE_UNICO = '__LABEL_FILE_UNICO__'.freeze
        NOMI_FILE_FDC = {
          MODO_CREAZIONE_FDC_TUTTO_SEPARATO => {
            MANAGED_OBJECT_OPERATION_CREATE => { AMBITO_FDC_ADJ   => "CRE_ADJ_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "CRE_#{LABEL_FIXED}" },
            MANAGED_OBJECT_OPERATION_UPDATE => { AMBITO_FDC_ADJ   => "UPD_ADJ_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "UPD_#{LABEL_FIXED}" },
            MANAGED_OBJECT_OPERATION_DELETE => { AMBITO_FDC_ADJ   => "DEL_ADJ_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "DEL_#{LABEL_FIXED}" }
          },
          MODO_CREAZIONE_FDC_FILE_UNICO => {
            MANAGED_OBJECT_OPERATION_CREATE => { AMBITO_FDC_ADJ => LABEL_FILE_UNICO, AMBITO_FDC_NOADJ => LABEL_FILE_UNICO },
            MANAGED_OBJECT_OPERATION_UPDATE => { AMBITO_FDC_ADJ => LABEL_FILE_UNICO, AMBITO_FDC_NOADJ => LABEL_FILE_UNICO },
            MANAGED_OBJECT_OPERATION_DELETE => { AMBITO_FDC_ADJ => LABEL_FILE_UNICO, AMBITO_FDC_NOADJ => LABEL_FILE_UNICO }
          },
          MODO_CREAZIONE_FDC_PER_OPERAZIONE => {
            MANAGED_OBJECT_OPERATION_CREATE => { AMBITO_FDC_ADJ   => "CRE_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "CRE_#{LABEL_FIXED}" },
            MANAGED_OBJECT_OPERATION_UPDATE => { AMBITO_FDC_ADJ   => "UPD_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "UPD_#{LABEL_FIXED}" },
            MANAGED_OBJECT_OPERATION_DELETE => { AMBITO_FDC_ADJ   => "DEL_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "DEL_#{LABEL_FIXED}" }
          },
          MODO_CREAZIONE_FDC_PER_AMBITO => {
            MANAGED_OBJECT_OPERATION_CREATE => { AMBITO_FDC_ADJ   => "CRE_UPD_DEL_ADJ_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "CRE_UPD_DEL_#{LABEL_FIXED}" },
            MANAGED_OBJECT_OPERATION_UPDATE => { AMBITO_FDC_ADJ   => "CRE_UPD_DEL_ADJ_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "CRE_UPD_DEL_#{LABEL_FIXED}" },
            MANAGED_OBJECT_OPERATION_DELETE => { AMBITO_FDC_ADJ   => "CRE_UPD_DEL_ADJ_#{LABEL_FIXED}", AMBITO_FDC_NOADJ => "CRE_UPD_DEL_#{LABEL_FIXED}" }
          }
        }.freeze
        def initialize(**opts) # rubocop:disable Metrics/AbcSize
          @out_dir = opts[:out_dir]
          raise "#{self} inizialize: output directory '#{out_dir}' non esistente" unless File.directory?(out_dir)
          @modo_creazione  = opts[:modo_creazione]
          @formato         = opts[:formato]

          # TODO: Da sistemare quando verranno gestiti altri formati
          suffix = opts[:formato] == FORMATO_AUDIT_IDL ? 'xml' : 'txt'
          @nomi_file = stabilisci_nomi_file(label: opts[:label_nome_file], suffix: suffix)
          #
          @writers = {}
          #
          @logger = opts[:logger] || Irma.logger
          @log_prefix = opts[:log_prefix]
        end

        def stabilisci_nomi_file(label:, suffix:)
          fixed = "#{label}.#{suffix}"
          file_unico = "FDC_UNICO_#{fixed}"
          xxx = {}
          NOMI_FILE_FDC[@modo_creazione].each do |op, val1|
            xxx[op] ||= {}
            val1.each do |amb, nome_file|
              xxx[op][amb] = nome_file.gsub(LABEL_FIXED, fixed).gsub(LABEL_FILE_UNICO, file_unico)
            end
          end
          xxx
        end

        def key_op_amb(operazione, ambito)
          "#{operazione}__#{ambito}"
        end

        def writer_class
          case @formato
          when FORMATO_AUDIT_IDL
            IdlUtil::Writer
          else
            raise "Formato audit #{@formato} non gestito"
          end
        end

        def open(_opts = {})
          @writers = {}    # operazione__ambito => WriterObj
          file_creati = {} # nome_file => WriterObj
          @nomi_file.each do |operazione, yyy|
            yyy.each do |ambito, nome_file|
              file_creati[nome_file] ||= writer_class.create(file: File.join(out_dir, nome_file))
              @writers[key_op_amb(operazione, ambito)] = file_creati[nome_file]
            end
          end
        end

        def close(_opts = {})
          @writers.each do |k, v|
            next unless v
            v.close
            @writers[k] = nil
          end
        end

        def scrivi_entita(opts)
          # TODO: Sistemare un po e mettere controlli su opts!!!
          op = opts[:operazione]
          amb = opts[:flag_adj] ? AMBITO_FDC_ADJ : AMBITO_FDC_NOADJ
          @writers[key_op_amb(op, amb)].handle_managed_object(mo: opts[:entita], oper: op)
        end
      end
    end
  end
end
