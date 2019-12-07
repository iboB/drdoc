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
    openers << {:instance => instance, :key_len => $&.length}
  end

  return nil if openers.empty?
  best = openers.max { |a, b| a[:key_len] <=> b[:key_len] }
  return {
    :instance => best[:instance],
    :split => [best_index, best_index + best[:key_len]]
  }
end

def find_closer(line, instance)
  e = instance[:end] =~ line
  return nil if !e # no end
  past_end = e + $&.length

  # no escape and we're done
  esc = instance[:escape]
  return [e, past_end] if !esc

  s = esc =~ line
  # if no escape and escape is not escaping end return the end
  return [e, past_end] if !s || s + $&.length != e

  # recursively invoke the same function if the escape escapes the end
  split_point = s + $&.length + 1
  close = find_closer(line[split_point..-1], instance)
  close.map! { |i| i + split_point } if close
  close
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
    attr_reader :type, :opener, :buf, :closer
  end

  class Code < Elem
    def initialize(pp, instance, closer)
      super(:code, '')
      @config = pp.config
    end
    def parse_line(line)
      opener = find_opener(line, @config)
      if opener
        @buf += line[0..opener[:split][0]]
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
      closer = find_closer(line, @instance)
      if closer
        @buf += line[0..closer[0]]
        @closer = line[closer[0]..closer[1]]
        return {:instance => {:type => :code}, :split => closer}
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
      opener = line[split[0]...split[1]]
      line = line[split[1]..-1]
      instance = parse_result[:instance]
      @elems << CodePreprocessor.const_get(TypeToElem[instance[:type]]).new(self, parse_result[:instance], opener)
    end
  end

  def parse(text)
    @elems = [Code.new(self, nil, nil)]
    text.each_line do |line|
      parse_line(line)
    end
    @elems.each do |e|
      p e
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
# p find_closer('dsad \" a\sd"', config[2])

CodePreprocessor.new(config).parse("xxx\n\"dasd\"")
