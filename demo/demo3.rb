class Split
  def initialize(first, mid, last)
    @first = first
    @mid = mid
    @last = last
  end

  def self.empty
    self.new('', '', '')
  end

  def self.[](s, pos, len)
    self.new(s[0, pos], s[pos, len], s[pos+len .. -1])
  end

  def empty?
    @first.empty? && @mid.empty? && last.empty?
  end

  attr_accessor :first, :mid, :last

  def inspect
    "Split(#{@first.inspect}-#{@mid.inspect}-#{@last.inspect})"
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
    openers << {:instance => instance, :si => i, :slen => $&.length}
  end

  return nil if openers.empty?
  opener = openers.max { |a, b| a[:slen] <=> b[:slen] }

  split = Split[line, opener[:si], opener[:slen]]

  # if the split begins with whitespace, just append it to the mid
  # thus we cary the indentation infromation with the designated element
  # (hacky)
  if split.first.strip.empty?
    split.mid = split.first + split.mid
    split.first = ''
  end

  return {
    :instance => opener[:instance],
    :split => split
  }
end

def do_find_closer(line, instance)
  e = instance[:end] =~ line
  return nil if !e # no end
  split = [e, $&.length]

  # no escape and we're done
  esc = instance[:escape]
  return split if !esc

  s = esc =~ line
  # if no escape and escape is not escaping end return the end
  return split if !s || s + $&.length != e

  # recursively invoke the same function if the escape escapes the end
  split_point = s + $&.length + 1
  split = do_find_closer(line[split_point..-1], instance)
  split[0] += split_point if split
  split
end

def find_closer(line, instance)
  split_data = do_find_closer(line, instance)
  return nil if !split_data
  ret = Split[line, *split_data]
  # since matching newlines with regex is hard,
  # we can just check for a newline here and if the rest of the string is a newline
  # we will just append it to the closer itself
  # (hacky)
  if ret.last == "\n"
    ret.mid += "\n"
    ret.last = ''
  end
  ret
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

# find code, docs, comments and ignore blocks
class Preprocessor
  class Elem
    def initialize(instance, split)
      @instance = instance
      @split = split
    end

    def inspect
      "CP::Elem(#{instance[:type].inspect}, #{@split.inspect})"
    end

    def to_hash
      {:instance => @instance, :split => @split}
    end

    attr_reader :instance, :split
  end

  class Code < Elem
    def initialize(pp, instance, closer)
      super(instance, Split.new('', '', ''))
      @config = pp.config
    end
    def parse_line(line)
      opener = find_opener(line, @config)
      if opener
        @split.mid += opener[:split].first
        return opener
      else
        @split.mid += line
        return nil
      end
    end
  end

  class Block < Elem
    def initialize(pp, instance, opener)
      super(instance, Split.new(opener, '', ''))
    end
    def parse_line(line)
      closing_split = find_closer(line, @instance)
      if closing_split
        @split.mid += closing_split.first
        @split.last = closing_split.mid
        return {:instance => {:type => :code}, :split => closing_split}
      else
        @split.mid += line
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
    :doc => :Block,
    :exclude => :Block,
  }

  def parse_line(line)
    while parse_result = @elems.last.parse_line(line)
      split = parse_result[:split]
      opener = split.mid
      line = split.last
      instance = parse_result[:instance]
      @elems << Preprocessor.const_get(TypeToElem[instance[:type]]).new(self, parse_result[:instance], opener)
    end
  end

  def parse(text)
    @elems = [Code.new(self, {:type => :code}, nil)]
    text.each_line do |line|
      parse_line(line)
    end
    @elems.select { |elem| !elem.split.empty? }.map(&:to_hash)
  end
end

# take care of @ignore stuff:
# mark docs within @ingore - @endignore as mere comments
class Preparser
  def parse(elems)
    comment_instance = {:type => :comment}
    ignoring = false
    elems.each do |elem|
      next if elem[:instance][:type] != :doc
      if ignoring
        elem[:instance] = comment_instance
        if elem[:split].mid =~ /@endignore/
          ignoring = false
        end
      elsif elem[:split].mid =~ /@ignore/
        ignoring = true
        elem[:instance] = comment_instance
      end
    end
  end
end

class Tokenizer

end


# actually parse the code to transform it into scopes, statements and docs
# builds an AST of sorts
class Parser
  # def
  def parse(elems)
    elems.each do |elem|

    end
  end
end

CPP_CONFIG = {
  :comment => [
    { :begin => '/*', :end => '*/' },
    { :begin => '//', :end => /$/, :escape => '\\' },
  ],
  :doc => [
    { :begin => '/**', :end => '*/' },
    { :begin => '///', :end => /$/, :escape => '\\' },
  ],
  :exclude => [
    { :begin => '"', :end => '"', :escape => '\\' },
    { :begin => '\'', :end => '\'', :escape => '\\' }
  ]
}

# prepare_config(CPP_CONFIG).map { |elem|
#   p elem
# }

config = prepare_config(CPP_CONFIG)
# p find_opener(' sdsa   /*"// asd  ""', config)
# p find_closer("sad\n", config[1])

elems = Preprocessor.new(config).parse(File.open('some_lib.hpp', 'r').read)
elems = Preparser.new.parse(elems)

puts elems.map(&:inspect).join("\n")


# p Split["Asd", 1, 2]
