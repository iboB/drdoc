
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

open = Regexp.union [
  Config.doc_start,
  Config.doc_line,
  Config.string_literal_open,
  Config.scope_begin,
  Config.comment_start,
  Config.comment_line,
]

RE_Open = /(#{open.source})/

class PreParser
  def initialize
  end

  # element which is simply code
  class Code
    def parse_line(line)
      index = line =~ RE_Open
      return self if !index
      rest = line[(index + $1.length) .. -1]
      puts rest
      # if
      self
    end
  end

  class String
    def initialize(parent)
      @paren = parent
    end

    def parse_line(line)
      # TODO: check escape

      i = line.index(Config.string_literal_close)
      return self if !i
      parent.parse_line(line[(i + Config.string_literal_close) .. -1])
    end
  end

  SubParser = {
    Config.string_literal_open => String
  }

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
