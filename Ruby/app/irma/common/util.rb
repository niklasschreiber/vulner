# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151008
#

# rubocop:disable Lint/NestedMethodDefinition
class Module
  def extends_host_with(class_methods)
    @_extension_module = class_methods

    def included(base)
      base.extend(const_get(@_extension_module)) if @_extension_module
    end
  end

  def class_attribute(*a) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    attr_array = [a].flatten
    raise(ArgumentError, "Nessun attributo specificato per la classe #{self}") if attr_array.empty?
    m_d = {}
    attr_array.each do |attr_info|
      if attr_info.is_a?(Symbol)
        m_d[attr_info] = nil
      elsif attr_info.is_a?(Hash)
        attr_info.each { |k, v| m_d[k] = v }
      else
        raise(ArgumentError, "Attributo '#{attr_info}' non corretto per la classe #{self} (sono ammessi simboli ed hash)")
      end
    end
    m_d.each do |m, default_value|
      cv = "@@#{m.to_s.tr('?', '_')}".freeze
      define_method(m) do |v = nil|
        begin
          if v.nil?
            class_variable_get(cv)
          else
            class_variable_set(cv, default_value.is_a?(Proc) ? default_value.call(v) : v)
          end
        rescue NameError
          class_variable_set(cv, default_value.is_a?(Proc) ? default_value.call(v) : default_value)
        end
      end
    end
    self
  end

  def clona_instance_methods_da_class_methods(modulo, num_parametri: [-1, 0])
    modulo.instance_methods.each do |m|
      next unless num_parametri.include?(modulo.instance_method(m).arity)
      define_method(m) do
        self.class.send(m)
      end
    end
  end
end

#
class String
  def numeric?
    !Float(self).nil?
  rescue
    false
  end

  def camelize
    split('_').each(&:capitalize!).join('')
  end

  def camelize!
    replace(camelize)
  end

  def underscore
    scan(/[A-Z][a-z]*/).join('_').downcase
  end

  def underscore!
    replace(underscore)
  end

  # Replace all occurence of a cleartext password in the +msg+ with the pattern +maskPattern+
  def mask_password(pattern = '*****')
    to_s.gsub(/([^<][a-z,_,-,A-Z]+(assword)[^>]*> *)".*"([,}])/, "\\1\"#{pattern}\"\\3")
        .gsub(/(< *[a-z,_,-,A-Z]+(assword)[^>]*>)[^<]*/, "\\1#{pattern}")
        .gsub(/("[^"]+(assword)[^"]+" = ')[^']*'/, "\\1#{pattern}'")
        .gsub(/(&password=)[^&]*/i, "\\1#{pattern}")
  end

  # Parse the string into time object
  def to_time
    raise 'stringa non valida' unless match(/^ *\d/)
    Time.parse(to_s)
  rescue
    raise %(La stringa "#{self}" non può essere convertita in un oggetto Time)
  end

  # Su una stringa 'a;b;c;d'
  # Specificato un carattere separatore (default ';')
  # Restituisce un array di stringhe ['a', 'a;b', 'a;b;c', 'a;b;c;d']
  def np_hierarchy(sep = ';')
    res = []
    idx = -1
    while idx
      idx = index(sep, idx + 1)
      res << (idx.nil? ? self : self[0..idx - 1])
    end
    res
  end

  # Splitta una stringa in base al separatore specificato (',' default)
  # e restituisce un hash con chiavi i pezzi di stringa e 'true' come valore
  # 'aaaSEPbbbSEPccc' -> { 'aaa' => true, 'bbb' => true, 'ccc' => true }
  def split_to_true_hash(sep = ',')
    ret = {}
    split(sep).each { |vvv| ret[vvv] = true }
    ret
  end

  # Toglie da input_str i caratteri non ammessi in un file name
  # '!', ' ', '/'
  def bonifica_filename
    to_s.gsub(%r{[\/! ]}, '')
  end

  # Tronca la stringa alla lunghezza indicata
  def truncate(truncate_at, options = {})
    return dup unless length > truncate_at
    omission = options[:omission] || '...'
    length_with_room_for_omission = truncate_at - omission.length
    stop = if options[:separator]
             rindex(options[:separator], length_with_room_for_omission) || length_with_room_for_omission
           else
             length_with_room_for_omission
           end
    "#{self[0, stop]}#{omission}"
  end
end

require 'ostruct'
#
class OpenStruct
  def [](k)
    send(k)
  end

  def []=(k, v)
    send("#{k}=", v)
  end
end

#
class Object
  # Ritorna la lista dei discendenti
  def self.descendants
    Enumerator.new(ObjectSpace, :each_object, Class).select { |klass| klass < self }
  end

  # Rails blank? compatible method
  # rubocop:disable Style/DoubleNegation
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end
end

require 'time'
#
class Time
  def at_beginning_of_day
    Time.parse("#{year}#{month}#{day}")
  end

  def cronologia
    (tv_sec * 1000) + (usec / 1000)
  end
end

#
class Hash
  def symbolize_keys(recursive = false)
    res = {}
    each_pair { |k, v| res[k.to_s.to_sym] = recursive && v.is_a?(Hash) ? v.symbolize_keys(recursive) : v }
    res
  end

  def stringify_keys(recursive = false)
    res = {}
    each_pair { |k, v| res[k.to_s] = recursive && v.is_a?(Hash) ? v.stringify_keys(recursive) : v }
    res
  end

  def sort_by_key(recursive = false, &block)
    keys.sort(&block).each_with_object({}) do |key, seed|
      seed[key] = self[key]
      if recursive && seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(true, &block)
      end
      seed
    end
  end
end

#
class File
  # aggiunge una stringa ad un nome file, mantenendo eventuale path e suffisso
  def self.add_str_nome_file(in_file, str)
    new_name = basename(in_file, '.*') + str + extname(in_file)
    dirname = dirname(in_file)
    dirname == '.' ? new_name : join(dirname, new_name)
  end
end

#
module Process
  def self.exists?(pid)
    kill(0, pid)
    true
  rescue
    false
  end
end
