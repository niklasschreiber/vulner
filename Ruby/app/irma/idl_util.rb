# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20170921
#

java_import 'javax.xml.parsers.SAXParserFactory'
java_import 'javax.xml.validation.SchemaFactory'
java_import 'javax.xml.transform.stream.StreamSource'
java_import 'org.xml.sax.InputSource'
java_import 'org.xml.sax.ErrorHandler'

#
module Irma
  #
  module IdlUtil
    extends_host_with :ClassMethods
    IDL_NAMES = [IDL_LOG = 'log'.freeze, IDL_NAME_MANAGED_OBJECT = 'managedObject'.freeze, IDL_NAME_P = 'p'.freeze, IDL_NAME_LIST = 'list'.freeze,
                 IDL_NAME_ITEM = 'item'.freeze, IDL_CMDATA = 'cmData'.freeze].freeze

    module ClassMethods
      def formato_audit
        FORMATO_AUDIT_IDL
      end

      def formato_file_compatibile?(file)
        %w(.zip .gz).include?(File.extname(file.to_s).downcase) ? `zcat "#{file}" |head -3 |grep raml2` : `head -3 "#{file}"|grep raml2`
        $CHILD_STATUS.exitstatus.zero?
      end
    end

    #
    class ManagedObject < Db::Entita::Record
      attr_reader :linea_file, :info_parametri, :dist_name_orig, :dist_name_orig_padre, :dist_name_padre, :dist_name_valid, :meta_entita
      alias dist_name_valid? dist_name_valid

      IDL_DIST_NAME_SEP = '/'.freeze
      IDL_DIST_NAME_VAL_SEP = '-'.freeze

      def initialize(hash = {})
        super(hash)
        @dist_name_orig  = hash[:dist_name_orig]
        @linea_file      = hash[:linea_file]
        @info_parametri  = hash[:info_parametri]
        @dist_name_valid = false
        elabora_dist_name_orig
      end

      def elabora_dist_name_orig # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
        return if @dist_name_orig.nil? || @dist_name_orig.empty? # || @dist_name_orig.match(DIST_NAME_INVALID_REG_EXP)

        dist_name_orig_arr = @dist_name_orig.split(IDL_DIST_NAME_SEP)
        values[:livello] = dist_name_orig_arr.count
        @dist_name_orig_padre = dist_name_orig_arr[0..-2].join(IDL_DIST_NAME_SEP)
        dist_name_padre_arr = []
        naming_path_arr = []
        dist_name_orig_arr.each_with_index do |item, idx|
          sep_idx = item.index(IDL_DIST_NAME_VAL_SEP)
          return false unless sep_idx
          me = item[0..sep_idx - 1]
          naming_path_arr << me
          ve = item[sep_idx + 1..item.length]
          if ve.empty?
            values[:naming_path] = naming_path_arr.join(NAMING_PATH_SEP)
            values[:meta_entita] = @meta_entita = me
            return false
          end
          current_item = me + DIST_NAME_VALUE_SEP + ve
          if idx == values[:livello] - 1
            @dist_name_padre = dist_name_padre_arr.join(DIST_NAME_SEP)
            values[:valore_entita] = ve
            values[:meta_entita] = @meta_entita = me
            values[:dist_name] = @dist_name_padre + (@dist_name_padre.empty? ? '' : DIST_NAME_SEP) + current_item
          else
            dist_name_padre_arr << current_item
          end
        end
        values[:naming_path] = naming_path_arr.join(NAMING_PATH_SEP)
        @dist_name_valid = true
      end

      def rimuovi_parametri(lista_parametri)
        # metodo che, data una lista di parametri (array di nome_struttura.meta_param) li rimuove dalla hash parametri
        lista_parametri.each do |mp|
          values[:parametri].delete(mp)
        end
        values[:parametri]
      end

      def info
        {
          class: 'ManagedObject', linea_file: linea_file,
          livello: livello, version: version,
          dist_name_orig: dist_name_orig, dist_name_orig_padre: dist_name_orig_padre, dist_name: dist_name, dist_name_padre: dist_name_padre,
          naming_path: naming_path, meta_entita: meta_entita, valore_entita: valore_entita, parametri: parametri, checksum: checksum
        }
      end
    end

    #
    class Log
      attr_reader :date_time
      def initialize(date_time)
        @date_time = date_time
      end

      def info
        { class: 'Log', date_time: date_time }
      end
    end

    #
    class CmData
      attr_reader :type
      def initialize(type)
        @type = type
      end

      def info
        { class: 'CmData', type: type }
      end
    end

    #
    class Parser # rubocop:disable Metrics/ClassLength
      IDL_TAG = [
        IDL_TAG_P = "<#{IDL_NAME_P}>".freeze,
        IDL_TAG_P_NAME = "<#{IDL_NAME_P} name=".freeze,
        IDL_TAG_ITEM = "<#{IDL_NAME_ITEM}>".freeze,
        IDL_TAG_LIST = "<#{IDL_NAME_LIST} name=\"".freeze,
        IDL_TAG_MANAGED_OBJECT = "<#{IDL_NAME_MANAGED_OBJECT} ".freeze
      ].freeze
      IDL_REGEXP = [
        IDL_REGEXP_P                    = %r{<p>(.*)<\/p>},
        IDL_REGEXP_P_NAME               = %r{<p name="(.*)">(.*)<\/p>},
        IDL_REGEXP_TAG_END              = %r{^\s*<\/(.*)>},
        IDL_REGEXP_OTHER                = /<([a-z][^ >]+) *(.*>)/
      ].freeze
      IDL_MANAGED_OBJECT_END_CHAR = '/'.freeze
      SEP_ATTR = '" '.freeze
      SEP_ATTR_NAME_VALUE = '="'.freeze
      SEP_ATTR_VALUE = '"'.freeze
      SEP_P_NAME_VALUE = '>'.freeze
      SEP_P_NAME       = '"'.freeze
      SEP_P_VALUE      = '<'.freeze
      SEP_LIST_NAME    = '"'.freeze

      attr_reader :stats, :file
      def initialize(file, **hash)
        @stats = { file: file, lines: 0, calls: 0, tags: Hash.new(0) } if hash[:stats]
        @file = file
        @managed_object = @elems = @info_elems = @line_number = nil
        @htmlentities = HTMLEntities.new
        @validate_proc = hash[:validate_proc]
      end

      # rubocop:disable Lint/AssignmentInCondition, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def parse(&block)
        last_line_processed = -1
        Irma.processa_file_per_linea(@file, suffix: 'parse_idl', validate_proc: @validate_proc) do |line, n|
          last_line_processed = n
          @stats[:lines] += 1 if @stats
          # puts "line: #{line}"
          if line.index(IDL_TAG_P_NAME)
            el = line.split(SEP_P_NAME_VALUE)
            nome = el[0].split(SEP_P_NAME)[1]
            @elems.last[nome] = param_value(el[1].split(SEP_P_VALUE)[0])
            @info_elems.last[nome] = last_line_processed + 1
            # ------
            # slow code
            # m = line.match(IDL_REGEXP_P)
            # @params[m[1]] = param_value(m[2])
            # ______
            @stats[:tags][IDL_NAME_P] += 1 if @stats
          elsif line.index(IDL_TAG_MANAGED_OBJECT)
            @managed_object = { attrs: estrai_attributi(line), params: {}, info_params: {} }
            @elems = [@managed_object[:params]]
            @info_elems = [@managed_object[:info_params]] # INFO_ELEM
            @stats[:tags][IDL_NAME_MANAGED_OBJECT] += 1 if @stats
            @line_number = n + 1
            salva_managed_object(&block) if line[-3] == IDL_MANAGED_OBJECT_END_CHAR
          elsif line.index(IDL_TAG_ITEM)
            @elems.last << (new_elem = {})
            @elems << new_elem
            @info_elems.last << (new_info_elem = {}) # INFO_ELEM
            @info_elems << new_info_elem # INFO_ELEM
            @stats[:tags][IDL_NAME_ITEM] += 1 if @stats
          elsif line.index(IDL_TAG_LIST)
            # <list name="xxxxx">
            @elems << (@elems.last[line.split(SEP_LIST_NAME)[1]] = [])
            @info_elems << (@info_elems.last[line.split(SEP_LIST_NAME)[1]] = []) # INFO_ELEM
            @stats[:tags][IDL_NAME_LIST] += 1 if @stats
          elsif m = line.match(IDL_REGEXP_TAG_END)
            case m[1]
            when IDL_NAME_MANAGED_OBJECT
              salva_managed_object(&block)
            when IDL_NAME_ITEM
              @elems.pop
              @info_elems.pop # INFO_ELEM
            when IDL_NAME_LIST
              @elems.pop
              @info_elems.pop # INFO_ELEM
            end
          elsif line.index(IDL_TAG_P)
            m = line.match(IDL_REGEXP_P)
            @elems.last << param_value(m[1])
            @info_elems.last << last_line_processed + 1 # INFO_ELEM
            @stats[:tags][IDL_NAME_P] += 1 if @stats
          elsif m = line.match(IDL_REGEXP_OTHER)
            if m[1] == IDL_LOG
              yield Log.new(estrai_attributi(m[2])['dateTime'])
              @stats[:calls] += 1 if @stats
            elsif m[1] == IDL_CMDATA
              yield CmData.new(estrai_attributi(m[2])['type'])
            end
            @stats[:tags][m[1]] += 1 if @stats
          end
        end
        @stats
      rescue EsecuzioneScaduta
        raise
      rescue => e
        raise "Linea #{last_line_processed}: #{e}"
      end
      # rubocop:enable all

      def estrai_attributi(s)
        attrs = {}
        s.split(SEP_ATTR).each do |t|
          el = t.split(SEP_ATTR_NAME_VALUE)
          attrs[el[0].split(' '.freeze).last] = param_value(el[1].split(SEP_ATTR_VALUE).first) if el.size > 1
        end
        attrs
      end

      def param_value(v)
        v.index('&') ? @htmlentities.decode(v) : v
      end

      # ------------------------------------------------
      # parametri_in = {
      #     "param_s"=>"aaa",
      #     "param_mv"=>["bbb","ccc"],
      #     "struct1"=>[{"p1"=>"ddd", "p2"=>"eee"}],
      #     "struct2"=>[{"p21"=>"fff", "p22"=>"ggg"}, {"p21"=>"hhh", "p22"=>"iii"}],
      #     "struct3"=>[{"p31"=>["lll","mmm"], "p32"=>"nnn"}],
      #     "struct4"=>[{"p41"=>["ppp","qqq"], "p42"=>"rrr"}, {"p41"=>["sss","ttt"], "p42"=>"uuu"}]
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

      def salva_managed_object(&_block)
        yield ManagedObject.new(meta_entita:    @managed_object[:attrs]['class'],
                                dist_name_orig: @managed_object[:attrs]['distName'],
                                version:        @managed_object[:attrs]['version'],
                                linea_file:     @line_number,
                                parametri:      trasforma_struttura_parametri(@managed_object[:params]),
                                info_parametri: trasforma_struttura_parametri(@managed_object[:info_params])
                               )
        @stats[:calls] += 1 if @stats
        @managed_object = @elems = @info_elems = @line_number = nil
      end
    end

    class SimpleErrorHandler
      attr_reader :numero_segnalazioni
      def initialize(nuova_segnalazione_proc: nil)
        @nuova_segnalazione_proc = nuova_segnalazione_proc
        @numero_segnalazioni = 0
      end

      def warning(e)
        # puts "WARNING: #{e}"
        crea_segnalazione(livello: 'WARNING', eccezione: e)
      end

      def error(e)
        # puts "ERROR: #{e}"
        crea_segnalazione(livello: 'ERROR', eccezione: e)
      end

      def fatal_error(e)
        # puts "FATAL: #{e}"
        crea_segnalazione(livello: 'FATAL', eccezione: e)
      end

      def crea_segnalazione(livello:, eccezione:)
        @nuova_segnalazione_proc.call(livello: livello, linea_file: eccezione.get_line_number, msg_eccezione: eccezione.get_message) if @nuova_segnalazione_proc
        @numero_segnalazioni += 1
      end
    end

    module Validate
      def file_idl_valido?(file:, xsd:, nuova_segnalazione_proc: nil, # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
                           nuova_segnalazione_progress_proc: nil, errorHandlerClass: SimpleErrorHandler)
        start_time = Time.now

        factory = SAXParserFactory.newInstance
        factory.setValidating(true)
        factory.setNamespaceAware(true)

        parser = factory.newSAXParser
        reader = parser.getXMLReader
        reader.setFeature('http://xml.org/sax/features/validation', true)
        reader.setFeature('http://apache.org/xml/features/validation/schema', true)
        reader.setFeature('http://apache.org/xml/features/validation/schema-full-checking', true)

        [xsd, xsd.gsub(/xsd$/, 'dtd')].each do |f|
          file_da_copiare = File.join(Irma.xsd_dir, f)
          raise "File xsd/dtd #{file_da_copiare} non trovato" unless File.exist?(file_da_copiare)
          FileUtils.cp(file_da_copiare, File.dirname(file))
        end

        reader.setProperty('http://apache.org/xml/properties/schema/external-noNamespaceSchemaLocation', File.join(File.dirname(file), xsd))

        seh = errorHandlerClass.new(nuova_segnalazione_proc: nuova_segnalazione_proc)
        reader.setErrorHandler(seh)
        begin
          reader.parse(InputSource.new(file))
        rescue
          raise unless seh.numero_segnalazioni > 0
        end

        return false if seh.numero_segnalazioni > 0
        nuova_segnalazione_progress_proc.call(durata: (Time.now - start_time).round(1), progress: true) if nuova_segnalazione_progress_proc
        true
      end
    end
    include Validate

    #
    # generic IDL writer
    #
    class Writer
      MODES = [MODE_DIRECT = :direct, MODE_XML = :xml].freeze

      def self.create(file:, mode: MODE_DIRECT, **opts, &_block)
        raise ArgumentError, "Idl::Writer error, invalid mode '#{mode}' (allowed modes: #{MODES.join('|')})" unless MODES.include?(mode.to_sym)
        writer = class_eval(mode.to_s.camelize).new(file: file, **opts)
        if block_given?
          yield(writer)
          writer.close
          file
        else
          writer
        end
      end

      attr_reader :file, :create_time

      def initialize(file:, **opts)
        # try file writing
        @fd = File.open(file, 'w')
        @file = file
        @create_time = opts[:create_time] || Time.now
      rescue => e
        raise "Idl::Writer error, invalid file '#{file}': #{e}"
      end

      def self.log_time_string(time = Time.now)
        (time || Time.now).strftime('%Y-%m-%dT%H:%M:%S')
      end

      def close
        return unless @fd
        @fd.flush
        @fd.close
        @fd = nil
      end

      def translate_dist_name(dist_name)
        dist_name.tr(DIST_NAME_VALUE_SEP, ManagedObject::IDL_DIST_NAME_VAL_SEP)
      end

      # API
      #
      # @abstract Subclass is expected to implement #handle_managed_object
      # @!method handle_managed_object(mo:, oper:, &_block)

      def create_managed_object(mo, **_opts)
        handle_managed_object(mo: mo, oper: MANAGED_OBJECT_OPERATION_CREATE)
      end

      def delete_managed_object(mo, **_opts)
        handle_managed_object(mo: mo, oper: MANAGED_OBJECT_OPERATION_DELETE)
      end

      def update_managed_object(mo, **_opts)
        handle_managed_object(mo: mo, oper: MANAGED_OBJECT_OPERATION_UPDATE)
      end

      #
      # Specific implementation
      #
      XML_INDENT_NUM = 4
      XML_INDENT = ' ' * XML_INDENT_NUM
      def spacing(level)
        XML_INDENT * level
      end

      #
      class Direct < self
        def initialize(file:, **opts)
          super(file: file, **opts)
          write_header
        end

        SPACING_LEVEL = [
          SPACING_LEVEL_RAML   = 0,
          SPACING_LEVEL_CMDATA = SPACING_LEVEL_RAML + 1,
          SPACING_LEVEL_HEADER = SPACING_LEVEL_CMDATA + 1,
          SPACING_LEVEL_LOG    = SPACING_LEVEL_HEADER + 1,
          SPACING_LEVEL_MO     = SPACING_LEVEL_HEADER,
          SPACING_LEVEL_PARAMS = SPACING_LEVEL_MO + 1
        ].freeze

        def write(s, flush: false)
          raise "Idl::Writer error, file #{@file} not open" unless @fd
          @fd.write(s)
          @fd.flush if flush
          self
        end

        def puts(s)
          write(s + "\n", flush: true)
        end

        def write_header
          puts %(<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE raml SYSTEM "raml20.dtd">
#{spacing(SPACING_LEVEL_RAML)}<raml version="2.0" xmlns="raml20.xsd">
#{spacing(SPACING_LEVEL_CMDATA)}<#{IDL_CMDATA} type="plan">
#{spacing(SPACING_LEVEL_HEADER)}<header>
#{spacing(SPACING_LEVEL_LOG)}<#{IDL_LOG} action="create" appInfo="ActualExporter" dateTime="#{self.class.log_time_string(@create_time)}"/>
#{spacing(SPACING_LEVEL_HEADER)}</header>)
        end

        def write_footer
          write <<EOS
#{spacing(SPACING_LEVEL_CMDATA)}</#{IDL_CMDATA}>
#{spacing(SPACING_LEVEL_RAML)}</raml>
EOS
        end

        def close
          write_footer if @fd
          super
        end

        class StructParams
          def self.p_value_to_xml(value:, name: nil)
            "<#{IDL_NAME_P}" + (name ? " name=\"#{name}\"" : '') + (value.to_s.empty? ? '/>' : ">#{value}</#{IDL_NAME_P}>")
          end

          attr_reader :name, :params
          def initialize(name)
            @name = name
            @params = {}
          end

          def []=(k, v)
            @params[k] = v.is_a?(Array) ? v : [v]
          end

          def to_xml(base_indent:, indent:) # rubocop:disable Metrics/AbcSize
            s = %(#{base_indent}<#{IDL_NAME_LIST} name="#{@name}">\n)
            unless @params.empty?
              item_indent = base_indent + indent
              p_indent = item_indent + indent
              mv = @params.first[1].size
              mv.times do |idx|
                s += %(#{item_indent}<#{IDL_NAME_ITEM}>\n)
                @params.each do |k, v|
                  s += %(#{p_indent}#{self.class.p_value_to_xml(name: k, value: v[idx])}\n)
                end
                s += %(#{item_indent}</#{IDL_NAME_ITEM}>\n)
              end
            end
            s += %(#{base_indent}</#{IDL_NAME_LIST}>\n)
          end
        end

        def _params_to_xml(parametri) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          return nil unless parametri
          base_spacing_level = SPACING_LEVEL_PARAMS
          struct_params = nil
          s = ''
          parametri.keys.sort_by(&:to_s).each do |k|
            v = parametri[k]
            struct, name = k.to_s.split('.')
            name, struct = struct, name  unless name
            if struct
              if struct_params && struct_params.name != struct
                s += struct_params.to_xml(base_indent: spacing(base_spacing_level), indent: XML_INDENT)
                struct_params = nil
              end
              struct_params ||= StructParams.new(struct)
              struct_params[name] = v
            else
              if struct_params
                s += struct_params.to_xml(base_indent: spacing(base_spacing_level), indent: XML_INDENT)
                struct_params = nil
              end
              s += if v.is_a?(Array)
                     p_spacing = spacing(base_spacing_level + 1)
                     params = p_spacing + v.map { |value| StructParams.p_value_to_xml(value: value) + "\n" }.join(p_spacing)
                     %(#{spacing(base_spacing_level)}<#{IDL_NAME_LIST} name="#{k}">\n#{params}#{spacing(base_spacing_level)}</#{IDL_NAME_LIST}>\n)
                   else
                     %(#{spacing(base_spacing_level)}#{StructParams.p_value_to_xml(name: name, value: v)}\n)
                   end
            end
          end
          s += struct_params.to_xml(base_indent: spacing(base_spacing_level), indent: XML_INDENT) if struct_params
          s
        end

        #
        # API implementation
        #
        def handle_managed_object(mo:, oper:, &_block) # rubocop:disable Metrics/AbcSize
          body = if block_given?
                   yield
                 else
                   oper.to_sym == MANAGED_OBJECT_OPERATION_DELETE ? nil : _params_to_xml(mo[:parametri])
                 end
          write(%(#{spacing(SPACING_LEVEL_MO)}<#{IDL_NAME_MANAGED_OBJECT} class="#{mo[:meta_entita]}" distName="#{translate_dist_name(mo[:dist_name])}" operation="#{oper}") +
                ((oper.to_sym == MANAGED_OBJECT_OPERATION_CREATE && !mo[:version].to_s.empty?) ? " version=\"#{mo[:version]}\"" : '') +
                (body.to_s.empty? ? "/>\n" : ">\n#{body}#{spacing(SPACING_LEVEL_MO)}</#{IDL_NAME_MANAGED_OBJECT}>\n"), flush: true)
        end
      end

      #
      class Xml < self
        attr_reader :xml
        def initialize(file:, **opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          require 'nokogiri'
          super(file: file, **opts)
          # we use another way to write into file
          close
          @xml = Nokogiri::XML::Builder.with(@doc = Nokogiri::XML('<?xml version = "1.0" encoding = "UTF-8"?>'))
          @doc.create_internal_subset('raml', nil, 'raml20.dtd')
          @doc.add_child(raml = Nokogiri::XML::Node.new('raml', @doc))
          raml[:xmlns] = 'raml20.xsd'
          raml[:version] = '2.0'
          raml.add_child(@cm_data = Nokogiri::XML::Node.new(IDL_CMDATA, @doc))
          @cm_data[:type] = 'plan'
          @cm_data.add_child(header = Nokogiri::XML::Node.new('header', @doc))
          log = Nokogiri::XML::Node.new(IDL_LOG, @doc)
          log[:action] = 'create'
          log[:appInfo] = 'ActualExporter'
          log[:dateTime] = self.class.log_time_string(@create_time)
          header.add_child(log)
        end

        def close
          super
          File.open(@file, 'w') { |fd| fd.write(@xml.to_xml(indent: XML_INDENT_NUM).sub('"UTF-8"', '"UTF-8" standalone="no"')) } if @xml
          @xml = nil
        end

        class StructParams
          attr_reader :name, :params
          def initialize(name)
            @name = name
            @params = {}
          end

          def []=(k, v)
            @params[k.to_s] = v.is_a?(Array) ? v : [v]
          end

          def to_node(doc)
            node = Nokogiri::XML::Node.new(IDL_NAME_LIST, doc)
            node[:name] = @name
            unless @params.empty?
              mv = @params.first[1].size
              mv.times do |idx|
                node.add_child(item = Nokogiri::XML::Node.new(IDL_NAME_ITEM, doc))
                @params.each do |k, v|
                  item.add_child(p = Nokogiri::XML::Node.new(IDL_NAME_P, doc))
                  p[:name] = k
                  p.content = v[idx]
                end
              end
            end
            node
          end
        end

        def _add_params(node, parametri) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          return node unless parametri
          struct_params = nil
          parametri.keys.sort_by(&:to_s).each do |k|
            v = parametri[k]
            struct, name = k.to_s.split('.')
            name, struct = struct, name  unless name
            if struct
              if struct_params && struct_params.name != struct
                node.add_child(struct_params.to_node(node.document))
                struct_params = nil
              end
              struct_params ||= StructParams.new(struct)
              struct_params[name] = v
            else
              if struct_params
                node.add_child(struct_params.to_node(node.document))
                struct_params = nil
              end
              if v.is_a?(Array)
                node.add_child(list = Nokogiri::XML::Node.new(IDL_NAME_LIST, node.document))
                list[:name] = k
                v.each do |value|
                  list.add_child(p = Nokogiri::XML::Node.new(IDL_NAME_P, node.document))
                  p.content = value
                end
              else
                node.add_child(p = Nokogiri::XML::Node.new(IDL_NAME_P, node.document))
                p[:name] = k
                p.content = v
              end
            end
          end
          node.add_child(struct_params.to_node(node.document)) if struct_params
          node
        end

        #
        # API implementation
        #
        def handle_managed_object(mo:, oper:, &_block) # rubocop:disable Metrics/AbcSize
          node = block_given? ? yield : Nokogiri::XML::Node.new(IDL_NAME_MANAGED_OBJECT, @doc)
          node[:class] = mo[:meta_entita]
          node[:distName] = translate_dist_name(mo[:dist_name])
          node[:operation] = oper
          node[:version] = mo[:version] if (oper.to_sym == MANAGED_OBJECT_OPERATION_CREATE) && !mo[:version].to_s.empty?
          _add_params(node, mo[:parametri]) unless oper == MANAGED_OBJECT_OPERATION_DELETE
          @cm_data.add_child(node)
        end
      end
    end
  end
end
