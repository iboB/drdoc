class Preprocessor
  attr_reader :config

  def initialize(config)
    @config = {}
    config.each do |type, element|
      @config[type] = element.map { |instance|
        clone = {}
        instance.each do |k, v|
          val = if !v.is_a?(Regexp)
            # make it a Regexp if it already isn't
            if v.is_a?(Array)
              Regexp.new(Regexp.union(v))
            else
              Regexp.new(Regexp.quote(v))
            end
          end
          clone[k] = val
        end
        # add optional but needed keys
        clone[:begin] = /^/ if !instance[:begin]
        clone[:end] = /$/ if !instance[:end]
        clone
      }
    end

    @stack = []
  end

  StackElementPerConfigType = {
    :doc => :StackDoc,
    :exclude => :StackExclude,
    :statement => :StackStatement,
    :scope => :StackScope,
  }

  def push(elem)
    @stack << elem
  end

  def pop()
    @stack.pop()
  end

  class StackCode
    def initialize(pp)
      @config = pp.config
      @pp = pp
    end

    def parse_line(line)
      opener = find_opener(line)
      # now that we have the opener, we can construct the stack object
      # and push in onto the stack
      stack_elem = Preprocessor.const_get(StackElementPerConfigType[opener[:type]]).new(self, opener)
      @pp.push(stack_elem)

      return rest_of_line = line[(opener[:index] + opener[:key].length)..-1]
    end

    def find_opener(line)
      # find all openers at the best posible index
      best_index = line.length
      openers = []
      @config.each do |type, element|
        element.each do |instance|
          i = instance[:begin] =~ line
          next if !i
          next if i > best_index
          if i < best_index
            best_index = i
            openers = []
          end
          openers << {:type => type, :instance => instance, :key => $&, :index => i}
        end
      end
      # the best match is the longest opener
      openers.max { |a, b| a[:key].length <=> b[:key].length }
    end
  end

  class StackDoc
    def initialize(pp, opener)
    end
  end

  class StackExclude
    def initialize(pp, opener)
    end
  end

  class StackStatement
    def initialize(pp, opener)
    end
  end

  class StackScope
    def initialize(pp, opener)
    end
  end

  def parse_line(line)
    @stack.last.parse_line(line)
  end

  def parse(text)
    @stack = [StackCode.new(self)]

    text.each_line do |line|
      parse_line line
    end
  end
end

PP_CONFIG = {
  :doc => [
    { :begin => '/**', :end => '*/', :inter => '*' },
    { :begin => '///' },
  ],
  :exclude => [
    { :begin => '/*', :end => '*/' },
    { :begin => '"',  :end => '"', :escape => '\\' },
    { :begin => '//', :escape => '\\' },
  ],
  :statement => [
    { :end => [';', ',', '\\'] },
    { :begin => '#' }
  ],
  :scope => [
    { :begin => '{', :end => '}' },
  ],
}

pp = Preprocessor.new(PP_CONFIG)

pp.parse("/** hello\n#sad")

# text = File.open('simple.hpp', 'r').read
# pp.parse(text)
