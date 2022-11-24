# vim: set fileencoding=utf-8
#
# Author       : C. Pinali
#
# Creation date: 20190605
#
require 'nokogiri'
#
module Irma
  module Funzioni
    class ImportCostruttore
      #
      class TreGpp < self
        include VerificheImportCostruttore

        def self.formato_audit
          FORMATO_AUDIT_TREGPP
        end

        def self.formato_file_compatibile?(file)
          %w(.zip .gz).include?(File.extname(file.to_s).downcase) ? `zcat "#{file}" |head -2 |grep bulkCmConfigDataFile` : `head -2 "#{file}"|grep bulkCmConfigDataFile`
          $CHILD_STATUS.exitstatus.zero?
        rescue => e
          raise "File #{file} non compatibile con il formato #{formato_audit} (#{e})"
        end

        attr_reader :parser_class
        def initialize(**opts)
          super(**opts)
          @parser_class = opts[:parser_class] || Parser3gppNokogiri
        end

        #
        class ManagedObject < Db::Entita::Record
          attr_reader :linea_file, :dist_name_valid, :info_parametri, :nome_entita
          alias dist_name_valid? dist_name_valid
          alias dist_name_orig dist_name

          def initialize(hash = {})
            super(hash)
            @dist_name_valid = hash[:dist_name_valid] || true
            @linea_file      = hash[:linea_file]
            @info_parametri  = hash[:info_parametri]
            @nome_entita     = hash[:nome_entita]
          end

          def info
            {
              class: 'ManagedObject', linea_file: linea_file, livello: livello, version: version, dist_name: dist_name,
              naming_path: naming_path, meta_entita: meta_entita, valore_entita: valore_entita, parametri: parametri, checksum: checksum
            }
          end

          def rimuovi_parametri(lista_parametri)
            # metodo che, data una lista di parametri (array di nome_struttura.meta_param) li rimuove dalla hash parametri
            lista_parametri.each do |mp|
              values[:parametri].delete(mp)
            end
            values[:parametri]
          end
        end

        class BulkCmConfigDataFile
          attr_reader :lista_xsd
          def initialize(lista_xsd)
            @lista_xsd = lista_xsd # nel formato [['ns1', 'filename1'], ['ns2', 'filename2']]
          end

          def info
            { class: 'BulkCmConfigDataFile', lista_xsd: lista_xsd }
          end
        end

        def formato_audit_info
          saa.formato_audit_info(formato_audit)
        end

        def validazione_file_audit?(file)
          return true unless formato_audit_info && formato_audit_info['validate']
          file_3gpp_valido?(file: file, xsd: formato_audit_info['xsd'].first,
                            nuova_segnalazione_proc: method(:nuova_segnalazione_validazione), nuova_segnalazione_progress_proc: method(:nuova_segnalazione_validazione_progress))
        end

        def con_parser(file:, **opts)
          yield(parser_class.new(file, validate_proc: formato_audit_info['validate'] ? method(:validazione_file_audit?) : nil, **opts))
        end

        def analizza_entita_parser(entita_parser:, **opts)
          case entita_parser
          when ManagedObject
            analizza_managed_object_3gpp(entita_parser, opts)
          when BulkCmConfigDataFile # TODO
            # caricamento xsd per pre_analisi metamodello
          when NilClass
            raise 'Classe 3GPP non valida'
          end
        end

        def analizza_managed_object_3gpp(entita, **opts)
          unless entita.dist_name_valid?
            nuova_segnalazione(TIPO_SEGNALAZIONE_IMPORT_OMC_LOGICO_DATI_IDENTIFICATIVO_ENTITA_NON_VALIDO, meta_entita: entita.meta_entita, naming_path: entita.naming_path, **opts)
            return ESITO_ANALISI_ENTITA_DIST_NAME_NON_VALIDO
          end
          return ESITO_ANALISI_ENTITA_DUPLICATA if entita_duplicata?(entita, **opts)
          return ESITO_ANALISI_ENTITA_METAMODELLO_NON_VALIDO unless opts[:metamodello].nil? || verifica_metamodello?(entita, **opts)
          return ESITO_ANALISI_ENTITA_NODO_NON_VALIDO unless verifica_nodo?(entita, **opts)
          verifica_entita_version(entita: entita, **opts)
          ESITO_ANALISI_ENTITA_OK
        end
      end

      class ParsingException < IrmaException; end
      module ParserMo3gpp # rubocop:disable Metrics/ModuleLength
        XML_3GPP_NAMES = [XML_3GPP_ATTR = 'attributes'.freeze, XML_3GPP_VDC = 'VsDataContainer'.freeze, XML_3GPP_VDT = 'vsDataType'.freeze, XML_3GPP_VDFV = 'vsDataFormatVersion'.freeze,
                          XML_3GPP_ID = 'id'.freeze, XML_3GPP_BULK = 'bulkCmConfigDataFile'.freeze, XML_3GPP_HEADER = 'fileHeader'.freeze, XML_3GPP_CD = 'configData'.freeze,
                          XML_3GPP_FOOTER = 'fileFooter'.freeze].freeze
        XML_3GPP_STATS_P = '_param'.freeze
        XML_3GPP_STATS_S = '_struct'.freeze
        XML_3GPP_STATS_MO = 'mo_3gpp'.freeze

        attr_reader :managed_object, :in_param, :dist_name_arr, :line_number
        def initialize_3gpp
          @in_param = @param_name = @param_value = @managed_object = @entity_name = @struct_name = @in_vdc = @in_vdt = nil
          @dist_name_arr = []
          @line_number = 0
        end

        def start_element_3gpp(name:, attrs: {}, prefix: nil, ns: [], &block) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          case name
          when XML_3GPP_HEADER, XML_3GPP_CD, XML_3GPP_FOOTER  # nothing to do
            @stats[:tags][name] += 1 if @stats
          when XML_3GPP_BULK
            # ns: [['es', 'EricssonSpecificAttributes.xsd'], ['un', 'utranNrm.xsd'], ['xn', 'genericNrm.xsd'], ['gn', 'geranNrm.xsd'], [nil, 'configData.xsd']]
            yield TreGpp::BulkCmConfigDataFile.new(ns || []) if block_given?
            @stats[:calls] += 1 if @stats
            @stats[:tags][name] += 1 if @stats
          when XML_3GPP_ATTR
            # puts "in attributtes -- name = #{name}, attrs: #{attrs}, prefix: #{prefix}"
            @in_param = true unless @in_vdc
            @stats[:tags][name] += 1 if @stats
          when XML_3GPP_VDC
            # puts "in vsDataContainter -- name = #{name}, attrs: #{attrs}, prefix: #{prefix}"
            salva_managed_object(&block) if @managed_object && block_given? # mo precedente da salvare (caso di mo senza parametri)
            @managed_object = { valore_entita: trasforma_valore_entita(attrs[XML_3GPP_ID]), params: {}, info_params: {}, linea_file: line_number }
            @in_vdc = true
            @stats[:tags][name] += 1 if @stats
          when XML_3GPP_VDT
            # puts "in vsDataType -- name = #{name}, attrs: #{attrs}, prefix: #{prefix}"
            @in_vdt = true
            @stats[:tags][name] += 1 if @stats
          when XML_3GPP_VDFV
            @in_vdt = false
            @stats[:tags][name] += 1 if @stats
          else
            # puts "in entita -- name = #{name}, attrs: #{attrs}, prefix: #{prefix}, in_vdc: #{@in_vdc}, in_param: #{@in_param}"
            if prefix && attrs.keys.include?(XML_3GPP_ID) # 1. caso entita non vdc: ho prefix e attributo id
              salva_managed_object(&block) if @managed_object && block_given? # mo precedente da salvare (caso di mo senza parametri)
              valore_entita = trasforma_valore_entita(attrs[XML_3GPP_ID])
              @managed_object = { nome_entita: "#{name}#{DIST_NAME_VALUE_SEP}#{valore_entita}", meta_entita: name, valore_entita: valore_entita, params: {}, info_params: {},
                                  linea_file: line_number }
              @entity_name = name
              @dist_name_arr << @managed_object[:nome_entita]
              @stats[:tags][prefix + XML_3GPP_ID] += 1 if @stats
            elsif @in_vdc && @entity_name == name # 2. caso entita in vdc
              @managed_object[:nome_entita] = "#{@entity_name}#{DIST_NAME_VALUE_SEP}#{@managed_object[:valore_entita]}"
              @managed_object[:meta_entita] = @entity_name
              @dist_name_arr << @managed_object[:nome_entita]
              @in_param = true # le righe successive, se ci sono, sono parametri
              @stats[:tags][prefix + XML_3GPP_ID] += 1 if @stats
            elsif prefix && @in_param # 3. caso parametri
              @stats[:tags][prefix + XML_3GPP_STATS_P] += 1 if @stats
              if @param_name && @struct_name.nil? # se param_name e' gia' avvalorato, significa che name e' il nome del primo parametro in struttura e @param_name e' il nome della struttura
                @struct_name = @param_name
                @managed_object[:params][@struct_name] ||= [] # potrebbe gia' esserci, nel caso di multistruttura
                @managed_object[:params][@struct_name] << {}
              elsif @struct_name
                @managed_object[:params][@struct_name].last.merge(name => nil)
              end
              @param_name = name
            else
              raise(ParsingException, "CASO NON PREVISTO: name = #{name}, attrs: #{attrs}, prefix: #{prefix}, linea_file: #{line_number}")
            end
          end
        end

        XML_3GPP_SLASH_MAP = '|\\'.freeze
        def trasforma_valore_entita(nome)
          return nome unless nome.index(DIST_NAME_SEP)
          nome.gsub(DIST_NAME_SEP, XML_3GPP_SLASH_MAP)
        end

        def end_element_3gpp(name:, prefix: nil, &block) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          case name
          when XML_3GPP_HEADER, XML_3GPP_CD, XML_3GPP_FOOTER, XML_3GPP_VDFV, XML_3GPP_BULK # nothing to do
          when XML_3GPP_ATTR
            # tag di chiusura dei parametri di un'entita, anche in caso di entita vdc, in cui e' chiusura anche dell'entita es
            @in_param = false
            @param_value = nil
            @param_name = nil
            salva_managed_object(&block) if block_given?
          when XML_3GPP_VDC
            @in_vdc = false
            @dist_name_arr.pop # chiusura di vsDataContainer, tolgo l'entita vsData dall'array
            @entity_name = (@dist_name_arr.last || '').split(DIST_NAME_VALUE_SEP).first
          when XML_3GPP_VDT
            @in_vdt = false
          else
            # puts "in end_element con #{name} - entity_name #{@entity_name} - param_name #{@param_name}"
            if name == @entity_name # chiusura di un entita
              unless @in_vdc # se entita normale, la chiusura dell'entita significa che non ho figli, posso togliere l'entita dall'array
                @dist_name_arr.pop
                @entity_name = (@dist_name_arr.last || '').split(DIST_NAME_VALUE_SEP).first
              end
              @in_param = false
            elsif @in_param && @param_name == name && @struct_name # chiusura di un parametro strutturato
              # puts "in end_element con struct @mo[params]: #{@managed_object[:params]}, struct: #{@struct_name}, param_name: #{@param_name}"
              if @managed_object[:params][@struct_name].last[@param_name] # ho gia' in hash il meta_parametro => si tratta di mv
                p_vals = @managed_object[:params][@struct_name].last[@param_name]
                @managed_object[:params][@struct_name].last[@param_name] = [p_vals, @param_value].flatten
              else
                @managed_object[:params][@struct_name].last[@param_name] = @param_value
              end
              @managed_object[:info_params][@struct_name + TEXT_STRUCT_NAME_SEP + name] = line_number # TODO: da sistemare!!!
              @param_name = @param_value = nil
            elsif @in_param && @param_name == name # chiusura di un parametro
              if @managed_object[:params].keys.include?(name) # ho gia' in hash il meta_parametro => si tratta di mv
                p_vals = @managed_object[:params][name]
                @managed_object[:params][name] = [p_vals, @param_value].flatten
              else
                @managed_object[:params][name] = @param_value
              end
              @managed_object[:info_params][name] = line_number # TODO: da sistemare!!!
              @param_name = @param_value = nil
            elsif @in_param && @struct_name == name # chiusura di una struttura
              @stats[:tags][prefix + XML_3GPP_STATS_S] += 1 if @stats
              @struct_name = nil
            else
              raise(ParsingException, "CASO NON PREVISTO: name: #{name}, prefix: #{prefix}, linea_file: #{line_number}")
            end
          end
        end

        def characters_3gpp(text)
          @param_value = text if @in_param
          @entity_name = text if @in_vdt
        end

        def salva_managed_object(&_block) # rubocop:disable Metrics/AbcSize
          yield TreGpp::ManagedObject.new(meta_entita:     @managed_object[:meta_entita],
                                          valore_entita:   @managed_object[:valore_entita],
                                          dist_name:       @dist_name_arr.join(DIST_NAME_SEP),
                                          naming_path:     @dist_name_arr.map { |el| el.split(DIST_NAME_VALUE_SEP).first }.join(NAMING_PATH_SEP),
                                          livello:         @dist_name_arr.size,
                                          linea_file:      @managed_object[:linea_file],
                                          parametri:       trasforma_struttura_parametri(@managed_object[:params]),
                                          info_parametri:  @managed_object[:info_params],
                                          dist_name_valid: @managed_object[:valore_entita] && !@managed_object[:valore_entita].empty?,
                                          nome_entita:     @managed_object[:nome_entita]
                                         )
          @stats[:calls] += 1 if @stats
          @stats[:tags][XML_3GPP_STATS_MO] += 1 if @stats
          @managed_object = nil
        end

        # -- metodo copiato da IdlUtil
        # parametri_in = {
        #     "param_s"=>"aaa",
        #     "param_mv"=>["bbb","ccc"],
        #     "struct1"=>[{"p1"=>["ddd"], "p2"=>["eee"]}],
        #     "struct2"=>[{"p21"=>["fff"], "p22"=>["ggg"]}, {"p21"=>["hhh"], "p22"=>["iii"]}],
        #     "struct3"=>[{"p31"=>["lll","mmm"], "p32"=>["nnn"]}],
        #     "struct4"=>[{"p41"=>["ppp","qqq"], "p42"=>["rrr"]}, {"p41"=>["sss","ttt"], "p42"=>["uuu"]}]
        # }
        #
        # parametri_out = {
        #     "param_s"=>"aaa",
        #     "param_mv"=>["bbb","ccc"],
        #     "struct1.p1"=>["ddd"],
        #     "struct1.p2"=>["eee"],
        #     "struct2.p21"=>["fff","hhh"],
        #     "struct2.p22"=>["ggg","iii"],
        #     "struct3.p31"=>[["lll","mmm"]],
        #     "struct3.p32"=>["nnn"],
        #     "struct4.p41"=>[["ppp","qqq"],["sss","ttt"]],
        #     "struct4.p42"=>["rrr","uuu"]
        # }
        def trasforma_struttura_parametri(parametri_in)
          parametri_out = {}
          parametri_in.each do |kkk, vvv|
            if vvv.is_a?(Array) && !vvv.empty? && vvv[0].is_a?(Hash)
              # parametro strutturato
              vvv.map(&:keys).flatten.uniq.each do |subk|
                parametri_out["#{kkk}#{TEXT_STRUCT_NAME_SEP}#{subk}"] = vvv.map { |x| x[subk] }
              end
            else
              parametri_out[kkk] = vvv
            end
          end
          parametri_out
        end
      end
      #
      class Parser3gpp
        attr_reader :stats, :file
        def initialize(file, **hash)
          @file = file
          @stats = { file: file, lines: 0, calls: 0, tags: Hash.new(0) } if hash[:stats]
          @validate_proc = hash[:validate_proc]
        end

        def parse(&_block)
          raise NotImplementedError, "parse non implementata per la classe #{self.class}"
        end

        def validate
          return true unless @validate_proc
          # TODO: codice di validazione... @validate_proc.call(file)
        end

        # metodo che sostituisce quanto supportato nel metodo Irma.processa_file_per_linea, non utilizzabile per questo parser
        def processa_file(in_file, &_block)
          file_da_processare = in_file
          d = Irma.estrai_archivio(file_da_processare, suffix: 'parse_tregpp')
          if d
            files = Dir["#{d}/**/*.*"]
            raise "Errore in estrazione file #{file}, generati i file #{files}, atteso un solo file" unless files.size == 1 && File.file?(files.first)
            file_da_processare = files.first
          end
          raise "File da processare '#{file_da_processare}' non esistente" unless File.file?(file_da_processare.to_s)
          yield file_da_processare
        ensure
          FileUtils.remove_entry(d) if d
        end
      end
      #
      class Parser3gppNokogiri < Parser3gpp
        def initialize(file, **hash)
          super(file, **hash)
        end

        def parse(&block)
          @document = Document3gppNokogiri.new(stats: @stats, parser_block: block)
          @parser = Nokogiri::XML::SAX::Parser.new(@document)
          begin
            processa_file(file) do |file_da_processare|
              @parser.parse_file(file_da_processare) do |ctx|
                @document.parser_ctx = ctx
              end
            end
          rescue ParsingException => e
            raise "Errore nel parsing del file #{File.basename(file)}: #{e}"
          end
        end
      end
      #
      class Document3gppNokogiri < Nokogiri::XML::SAX::Document
        include ParserMo3gpp

        attr_reader :stats, :parser_block
        attr_accessor :parser_ctx
        def initialize(**hash)
          @stats = hash[:stats]
          @parser_block = hash[:parser_block]
          initialize_3gpp
        end

        def line_number
          @parser_ctx ? @parser_ctx.line : 0
        end

        def start_element_namespace(name, attrs = [], prefix = nil, _uri = nil, ns = [])
          attrs_hash = {}
          attrs_hash[attrs.first.localname] = attrs.first.value if attrs && !attrs.empty?
          start_element_3gpp(name: name, attrs:  attrs_hash, prefix: prefix, ns: ns) do |mo|
            # puts "start_element #{mo.dist_name}" if mo.is_a?(TreGpp::ManagedObject)
            parser_block.call(mo) if parser_block
          end
        end

        def characters(text)
          characters_3gpp(text)
        end

        def error(text)
          raise(ParsingException, text)
        end

        def warning(text)
          puts text
        end

        def end_element_namespace(name, prefix = nil, _uri = nil)
          end_element_3gpp(name: name, prefix: prefix) do |mo|
            # puts "end_element #{mo.dist_name}" if mo.is_a?(TreGpp::ManagedObject)
            parser_block.call(mo) if parser_block
          end
        end

        def end_document
          @stats[:lines] = line_number if @stats
        end
      end
    end
  end
end
