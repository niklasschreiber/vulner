# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20151123
#
# Notes: original code from annotate gem 2.0.2
#
module Irma
  module Db
    #
    module AnnotateModels # rubocop:disable Metrics/ModuleLength
      #
      class << self
        attr_accessor :model_dir

        # Annotate Models plugin use this header
        COMPAT_PREFIX = '== Schema Info'.freeze
        PREFIX = '== Schema Information'.freeze

        # Simple quoting for the default column value
        def quote(value)
          case value
          when NilClass                 then 'NULL'
          when TrueClass                then 'TRUE'
          when FalseClass               then 'FALSE'
          when Float, Integer           then value
            # BigDecimals need to be output in a non-normalized form and quoted.
          when BigDecimal               then value.to_s('F')
          else
            value.to_s.sub(/::(text|character varying|regclass)/, '')
          end
        end

        def compute_col_type(v)
          col_type = ((v[:db_type] == 'bigint') ? v[:db_type] : (v[:type] || v[:db_type])).to_s
          if col_type == 'decimal'
            # col_type << "(#{col.precision}, #{col.scale})"
            col_type = 'float'
          elsif v[:max_length]
            col_type << "(#{v[:max_length]})"
          end
          col_type
        end

        # Use the column information in an ActiveRecord class
        # to create a comment block containing a line for
        # each column. The line contains the column name,
        # the type (and length), and any optional attributes
        def get_schema_info(klass, header, options = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
          info = "# #{header}\n#\n"
          info << "# Tabella: #{klass.table_name}\n#\n"

          max_size = klass.columns.collect { |name| name.to_s.size }.max + 1
          fks = {}
          if options[:show_foreign_keys]
            klass.connection.foreign_key_list(klass.table_name).each { |fk| fks[fk[:columns].join(',')] = fk[:table].to_s + '.' + fk[:key].join(',') }
          end

          klass.db_schema.sort_by { |k, _v| k.to_s }.each do |k, v|
            col_name = k.to_s
            attrs = []
            attrs << 'non nullo'                       unless v[:allow_null]
            attrs << "default(#{quote(v[:default])})"  if v[:default]
            attrs << 'chiave primaria'                 if v[:primary_key]
            attrs << "riferimento a #{fks[col_name]}"  if fks[col_name]

            info << format("#  %-#{max_size}.#{max_size}s:%-15.15s %s", col_name, compute_col_type(v), attrs.join(', ')).rstrip + "\n"
          end
          info << get_index_info(klass) if options[:show_indexes]
          info << "#\n"
        end

        def get_index_info(klass) # rubocop:disable Metrics/AbcSize
          indexes = klass.connection.indexes(klass.table_name)
          return '' if indexes.empty?

          index_info = "#\n# Indici:\n#\n"
          max_size = indexes.collect { |index, _info| index.to_s.size }.max + 1
          indexes.each do |index, info|
            index_info << format("#  %-#{max_size}.#{max_size}s %s %s", index, "(#{info[:columns].sort.join(',')})", info[:unique] ? 'UNIQUE' : '').rstrip + "\n"
          end
          index_info
        end

        # Add a schema block to a file. If the file already contains
        # a schema info block (a comment starting with "== Schema Information"), check if it
        # matches the block that is already there. If so, leave it be. If not, remove the old
        # info block and write a new one.
        # Returns true or false depending on whether the file was modified.
        #
        # === Options (opts)
        #  :position<Symbol>:: where to place the annotated section in fixture or model file,
        #                      "before" or "after". Default is "before".
        #  :position_in_class<Symbol>:: where to place the annotated section in model file
        #  :position_in_fixture<Symbol>:: where to place the annotated section in fixture file
        #
        def annotate_one_file(file_name, info_block, options = {}) # rubocop:disable Metrics/AbcSize
          return false unless File.exist?(file_name)
          old_content = File.read(file_name)

          # Ignore the Schema version line because it changes with each migration
          header = Regexp.new(/(^# Tabella:.*?\n(#.*\n)*)/)
          old_header = old_content.match(header).to_s
          new_header = info_block.match(header).to_s

          return false if old_header == new_header

          # Remove old schema info
          old_content.sub!(/^[\n\s]*# #{COMPAT_PREFIX}.*?\n(#.*\n)*/, '')

          # Write it back
          new_content = ((options[:position] || :before).to_sym == :before) ? (info_block + old_content) : (old_content + "\n" + info_block)

          File.open(file_name, 'wb') { |f| f.puts new_content }
          true
        end

        def remove_annotation_of_file(file_name)
          return unless File.exist?(file_name)
          old_content = File.read(file_name)

          content = old_content.sub(/[\n\s]*^# #{COMPAT_PREFIX}.*?\n(#.*\n)*/, '')

          if content != old_content
            File.open(file_name, 'wb') { |f| f.puts content }
            true
          else
            false
          end
        end

        # Given the name of an ActiveRecord class, create a schema
        # info block (basically a comment containing information
        # on the columns and their types) and put it at the front
        # of the model and fixture source files.
        # Returns true or false depending on whether the source
        # files were modified.
        def annotate(klass, file, header, options = {})
          info = get_schema_info(klass, header, options)
          annotated = false
          model_file_name = File.join(model_dir, file)
          annotated = true if annotate_one_file(model_file_name, info, options.merge(position: (options[:position_in_class] || options[:position])))
          annotated
        end

        # Return a list of the model files to annotate. If we have
        # command line arguments, they're assumed to be either
        # the underscore or CamelCase versions of model names.
        # Otherwise we take all the model files in the
        # model_dir directory.
        def model_files
          models = []
          Dir.chdir(model_dir) do
            models = Dir['**/*.rb'].sort
          end
          models
        end

        # Retrieve the classes belonging to the model names we're asked to process
        # Check for namespaced models in subdirectories as well as models
        # in subdirectories without namespacing.
        def get_model_class(file, opts = {})
          require "#{model_dir}/#{file}" if opts[:require_file]
          model = File.basename(file).gsub(/\.rb$/, '').camelize
          class_eval(model)
        end

        # We're passed a name of things that might be
        # ActiveRecord models. If we can find the class, and
        # if its a subclass of ActiveRecord::Base,
        # then pas it to the associated block
        def do_annotations(options = {}) # rubocop:disable Metrics/AbcSize
          header = PREFIX.dup

          self.model_dir = options[:model_dir] if options[:model_dir]

          annotated = []
          model_files.each do |file|
            begin
              klass = get_model_class(file, require_file: options[:require_file])
              annotated << klass if klass < Model && annotate(klass, file, header, options)
            rescue => e
              puts "Unable to annotate #{file}: #{e.message} (#{e.backtrace.first})"
            end
          end
          puts annotated.empty? ? 'Nothing annotated!' : "Annotated (#{annotated.length}): #{annotated.join(', ')}"
        end

        def remove_annotations(options = {}) # rubocop:disable Metrics/AbcSize
          # p options
          self.model_dir = options[:model_dir] if options[:model_dir]
          deannotated = []
          model_files.each do |file|
            begin
              klass = get_model_class(file, require_file: options[:require_file])
              if klass < Model
                deannotated << klass if remove_annotation_of_file(File.join(model_dir, file))
              end
            rescue => e
              puts "Unable to annotate #{file}: #{e.message}"
            end
          end
          puts deannotated.empty? ? 'Nothing deannotated!' : "Deannotated (#{deannotated.length}): #{deannotated.join(', ')}"
        end
      end
    end
  end
end
