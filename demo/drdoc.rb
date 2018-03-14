
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
    Config.doc_line => nil,
    Config.string_literal_open => :StringElement,
    Config.comment_start => nil,
    Config.comment_line => nil,
    Config.scope_begin => nil,
  }

  RE_Open = /(#{Regexp.union(Openers.keys)})/

  # element which is simply code
  class Code
    def parse_line(line)
      index = line =~ RE_Open
      return self if !index
      rest = line[(index + $1.length) .. -1]
      elem = Openers[$1]
      if elem
        PreParser.const_get(elem).new(self).parse_line(rest)
      else
        puts rest
      end
      self
    end
  end

  class StringElement
    def initialize(parent)
      @parent = parent
    end

    def parse_line(line)
      # TODO: check escape

      i = line.index(Config.string_literal_close)
      return self if !i
      @parent.parse_line(line[(i + Config.string_literal_close.length) .. -1])
    end
  end

  #class MultiLineDoc

  def parse(text)
    cur = Code.new
    text.each_line do |line|
      cur = cur.parse_line line
    end
  end
end

text = File.open('some_lib.hpp', 'r').read

parser = PreParser.new
parser.parse(text)
