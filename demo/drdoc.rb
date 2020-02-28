# kyp for this config style
CONFIG = {
  :doc_start => '/**',
  :doc_inter => '*',
  :doc_end => '*/',
  :doc_line => '///',
  :doc_post => '<',
  :comment_start => '/*',
  :comment_end => '*/',
  :comment_line => '//',
  :statemend_end => ';',
  :scope_type => :block,
  :scope_begin => '{',
  :scope_end => '}',
  :string_literal_open => '"',
  :string_literal_close => '"',
  :string_literal_esacpe => '\\"',
}

Config = Struct.new(*CONFIG.keys).new(*CONFIG.values).freeze

class PreParser
  def initialize
  end

  Openers = {
    Config.doc_start => nil,
    Config.doc_line => :DocLine,
    Config.string_literal_open => :StringElement,
    Config.comment_start => nil,
    Config.comment_line => nil,
  }

  RE_Open = /(#{Regexp.union(Openers.keys)})/

  # element which is simply code
  class Code
    def initialize
      @elements = []
    end

    def parse_line(line)
      index = line =~ RE_Open
      if !index
        @elements << line
        return self
      end

      elem = Openers[$1]

      if elem
        first = line[0..index]
        rest = line[(index + $1.length) .. -1]

        @elements << first
        elem_instance = PreParser.const_get(elem).new(self)
        @elements << elem_instance
        elem_instance.parse_line(rest)
      else
        @elements << line
        self
      end
    end

    attr_reader :elements
  end

  class StringElement
    def initialize(parent)
      @parent = parent
      @contents = ''
    end

    def parse_line(line)
      # TODO: check escape

      i = line.index(Config.string_literal_close)
      if !i
        @contents += line
        self
      else
        first = line[0..i]
        @contents += first
        rest = line[(i + Config.string_literal_close.length) .. -1]
        @parent.parse_line(rest)
      end
    end

    attr_reader :contents
  end

  class DocLine
    def initialize(parent)
      @parent = parent
    end

    def parse_line(line)
      @contents = line
      return @parent
    end

    attr_reader :contents
  end

  #class MultiLineDoc

  def parse(text)
    cur = Code.new
    text.each_line do |line|
      cur = cur.parse_line line
    end
    cur
  end
end

text = File.open('some_lib.hpp', 'r').read

parser = PreParser.new
parser.parse(text).elements.each do |e|
  next if e.class == String
  puts e.contents
end
