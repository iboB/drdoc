
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

  # element which is simply code
  class Code
    def initialize(code)
      @code = code
    end
    attr_reader :code
  end

  class DocML
    def parse(match, after)
      i = after.index(Config.doc_end)
      raise "bad" if !i
      @code = after[0 .. i]
      after[(i + Config.doc_end.length) .. -1]
    end
  end

  class DocLine
    def parse(match, after)
      i = after.index("\n") | -1
      @code = [after .. i]
      after[i .. -1]
    end
  end

  class StringLiteral
    def parse(match, after)
    end
  end

  def parse(text)
    open = Regexp.union [
      Regexp.quote(Config.doc_start),
      Regexp.quote(Config.doc_line),
      Regexp.quote(Config.doc_line),
      Regexp.quote(Config.string_literal_open),
    ]
    re = /\A(.+?)(#{open.source})(.+?)\z/m

    while text =~ re
      puts $1
      text = $3
    end
  end
end

text = File.open('some_lib.hpp', 'r').read

parser = PreParser.new
parser.parse(text)
