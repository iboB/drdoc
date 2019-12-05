class Preprocessor
  def initialize(config)
    @config = {}
    config.each do |type, element|
      @config[type] = element.map { |item|
        clone = {}
        item.each do |k, v|
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
        clone[:begin] = /^/ if !item[:begin]
        clone[:end] = /$/ if !item[:end]
        clone
      }
    end
  end

  # ElementPerConfigType = {
  #   :doc => Doc,
  #   :exclude => Exclude,
  #   :statement => Statement,
  #   :scope => Scope,
  # }

  def find_opener(line)
    # find all openers at the best posible index
    best_index = line.length
    openers = []
    @config.each do |type, element|
      element.each do |item|
        i = item[:begin] =~ line
        next if !i
        next if i > best_index
        if i < best_index
          best_index = i
          openers = []
        end
        openers << {:type => type, :key => $&}
      end
    end
    # the best match is the longest opener
    best_match = openers.max { |a, b| a[:key].length <=> b[:key].length }

    # now that we have it, we can construct the object
  end

  def parse_line(line)
    f = find_opener(line)
  end

  def parse(text)
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

pp.parse_line('/** hello')

# text = File.open('simple.hpp', 'r').read
# pp.parse(text)
