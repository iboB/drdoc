class Split
  def initialize(position, length)
    @position = position
    @length = length
  end

  attr_reader :position, :length

  def first_of(s)
    s[0, @position]
  end

  def mid_of(s)
    s[@position, @length]
  end

  def last_of(s)
    s[@position+@length .. -1]
  end

  def shift_by!(n)
    @position += n
  end

  def inspect
    "Split(pos:#{@position}, len:#{@length})"
  end
end

def find_opener(line, elems)
  # find all openers at the best posible index
  best_index = line.length
  openers = []

  elems.each do |instance|
    i = instance[:begin] =~ line
    next if !i
    next if i > best_index
    if i < best_index
      # we found a better index, so ignore everything up until now
      best_index = i
      openers = []
    end
    openers << {:instance => instance, :split => Split.new(i, $&.length)}
  end

  return nil if openers.empty?
  openers.max { |a, b| a[:split].length <=> b[:key_len] }
end

def find_closer(line, instance)
  e = instance[:end] =~ line
  return nil if !e # no end
  split = Split.new(e, $&.length)

  # no escape and we're done
  esc = instance[:escape]
  return split if !esc

  s = esc =~ line
  # if no escape and escape is not escaping end return the end
  return split if !s || s + $&.length != e

  # recursively invoke the same function if the escape escapes the end
  split_point = s + $&.length + 1
  closer = find_closer(line[split_point..-1], instance)
  closer.shift_by!(split_point) if closer
  closer
end

def prepare_config(config)
  ret = []
  config.each do |type, element|
    ret.concat(element.map { |instance|
      clone = instance.transform_values { |v|
        if !v.is_a?(Regexp)
          # make it a Regexp if it already isn't
          if v.is_a?(Array)
            Regexp.new(Regexp.union(v))
          else
            Regexp.new(Regexp.quote(v))
          end
        else
          v
        end
      }
      clone[:begin] = /^/ if !instance[:begin]
      clone[:end] = /$/ if !instance[:end]
      clone[:type] = type
      clone
    })
  end
  ret
end

class CodePreprocessor
  class Elem
    def initialize(type, opener)
      @type = type
      @opener = opener
      @buf = ''
    end

    def inspect
      "CP::Elem(#{@type.inspect}, #{@opener.inspect}-#{@buf.inspect}-#{@closer.inspect})"
    end
    attr_reader :type, :opener, :buf, :closer
  end

  class Code < Elem
    def initialize(pp, instance, closer)
      super(:code, '')
      @config = pp.config
      @closer = ''
    end
    def parse_line(line)
      opener = find_opener(line, @config)
      if opener
        @buf += opener[:split].first_of(line)
        return opener
      else
        @buf += line
        return nil
      end
    end
  end

  class Block < Elem
    def initialize(pp, instance, opener)
      super(instance[:type], opener)
      @instance = instance
    end
    def parse_line(line)
      split = find_closer(line, @instance)
      if split
        @buf += split.first_of(line)
        @closer = split.mid_of(line)
        return {:instance => {:type => :code}, :split => split}
      else
        @buf += line
        return nil
      end
    end
  end

  def initialize(config)
    @config = config
  end

  attr_reader :config, :elems

  TypeToElem = {
    :code => :Code,
    :comment => :Block,
    :exclude => :Block,
  }

  def parse_line(line)
    while parse_result = @elems.last.parse_line(line)
      split = parse_result[:split]
      opener = split.mid_of(line)
      line = split.last_of(line)
      break if line.empty?
      instance = parse_result[:instance]
      @elems << CodePreprocessor.const_get(TypeToElem[instance[:type]]).new(self, parse_result[:instance], opener)
    end
  end

  def parse(text)
    @elems = [Code.new(self, nil, nil)]
    text.each_line do |line|
      parse_line(line)
    end
  end
end

CPP_CONFIG = {
  :comment => [
    { :begin => '/*', :end => '*/' },
    { :begin => '//', :end => /$/, :escape => '\\' },
  ],
  :exclude => [
    { :begin => '"', :end => '"', :escape => '\\' }
  ]
}

# prepare_config(CPP_CONFIG).map { |elem|
#   p elem
# }

config = prepare_config(CPP_CONFIG)
# p find_opener(' sdsa   /*"// asd  ""', config)
# str = 'dsad"'
# s = find_closer(str, config[2])
# p s.first_of(str)
# p s.mid_of(str)
# p s.last_of(str)

CodePreprocessor.new(config).parse(File.open('some_lib.hpp', 'r').read)

