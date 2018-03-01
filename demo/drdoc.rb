
CONFIG = {
  :doc_start => '/**',
  :doc_inter => '*',
  :doc_end => '*/',
  :doc_line => '///',
  :doc_post => '<',
  :comment_start => '/*',
  :comment_end => '*/',
  :comment_line => '//',
  :scope_type => :block,
  :scope_begin => '{',
  :scope_end => '}',
  :string_literal_open => '"',
  :string_literal_close => '"',
  :string_literal_esacpe => '\\"',
}

Config = Struct.new(*CONFIG.keys).new(*CONFIG.values).freeze

# parse into abstract syntax sequence
# ASS :D
class PreParser
  def initialize

  end

  # element which is simply code
  #~ class Code
    #~ def parse


  def parse(text)
    multiline_comment = false
    text.each_line do |line|
      if multiline_comment
        multiline_comment = false if line[Config.comment_end]
      else
        line.lstrip!
        if line.start_with?(Config.doc_start)
          p line
        end
      end
    end
  end
end

text = File.open('some_lib.hpp', 'r').read

parser = Parser.new
parser.parse(text)
