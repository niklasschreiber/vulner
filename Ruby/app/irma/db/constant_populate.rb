# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151119
#

#
module Sequel
  #
  module Plugins
    #
    module ConstantPopulate
      #
      module ClassMethods
        def constant_populate?
          Irma::Constant.exists?(scope)
        end

        def scope
          name.to_s.split(':').last.underscore.to_sym
        end

        # popola nel db le constanti definite per la classe, ritornando la lista delle primary_keys
        # degli oggetti da rimuovere/rimossi (in base al flag +:remove_old+ e' false)
        def constant_populate(opts = {}) # rubocop:disable Metrics/AbcSize
          options = { scope: scope, prefix: nil, class_name: nil, remove_old: true }.merge(opts)
          pk = { old: map(primary_key).map(&:to_s) }
          pk[:new] = Irma::Constant.constants(options[:scope], options[:prefix]).map do |c|
            define_opts = {}
            c.info.each { |k, v| define_opts[k] = v if columns.member?(k.to_sym) }
            define(c.value.to_s, define_opts, c.info).pk.to_s
          end
          to_be_removed = pk[:old] - pk[:new]
          constant_unpopulate(to_be_removed) if options[:remove_old]
          [self, to_be_removed]
        end

        # Elimina gli elementi dal DB con id nell'array +to_be_deleted+
        def constant_unpopulate(to_be_removed)
          # li elimino in ordine inverso per sicurezza
          to_be_removed.reverse_each do |pk|
            begin
              first(primary_key => pk).destroy
            rescue => e
              STDERR.puts "Rimozione record con pk #{pk} di classe #{self} fallito: #{e}"
            end
          end
        end

        # definisce un oggetto in base all'id e alle opzioni +define_opts+
        def define(pk, define_opts, _opts = {})
          o = first(primary_key => pk)
          if o.nil?
            o = new(define_opts.merge(primary_key => pk))
          else
            define_opts.each { |k, v| o.send("#{k}=", v) }
          end
          yield(o) if block_given?
          o.save_changes || o
        end

        # definiti come costanti
        def validates_constant(field, opts = {}) # rubocop:disable Metrics/AbcSize
          options = { scope: scope, prefix: field }.merge(opts)
          allowed_values = Irma::Constant.values(options[:scope], options[:prefix]).sort_by(&:to_s)
          msg = allowed_values.map { |v| "#{v} (#{Irma::Constant.key(options[:scope], v, options[:prefix])})" }.join(', ')
          validates_inclusion_of field, in: allowed_values, message: "invalido per #{to_s.split(':').last}, valori ammessi: #{msg}"
        end

        [:value, :label, :key, :info].each do |k|
          define_method("constant_#{k}") do |field, v, opts = {}|
            Irma::Constant.send(k, (opts[:scope] || scope), v, (opts[:prefix] || field))
          end
        end

        # Ritorna true/false se esiste una costante per il campo +field+
        def constant_exists?(field, opts = {})
          Irma::Constant.exists?((opts[:scope] || scope), (opts[:prefix] || field))
        end

        # Ritorna tutti i valori per il campo +field+
        def constant_values(field, opts = {})
          Irma::Constant.values((opts[:scope] || scope), (opts[:prefix] || field))
        end

        # Ritorna tutte le chiavi per il campo +field+
        def constant_keys(field, opts = {})
          Irma::Constant.keys((opts[:scope] || scope), (opts[:prefix] || field))
        end
      end
    end
  end
end
