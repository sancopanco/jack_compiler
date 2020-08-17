module JackAnalyzer
  # A Token represents a atom of code at a specific place in the source text
  class Token
    attr_reader :type, :lexeme, :literal, :line, :start_column, :end_column

    def initialize(type, lexeme, literal, options = {})
      @type = type
      @lexeme = lexeme
      @literal = literal
      @line = line
      # need to tell users where error occurred
      @line = options.fetch(:line, nil)
      @start_column = options.fetch(:start_column, nil)
      @end_column = options.fetch(:end_column, nil)
    end

    def to_s
      "#{type} #{lexeme} #{line}:#{start_column}:#{end_column}"
    end

    def to_xml
      tag_text = literal || lexeme
      "<#{type}>#{tag_text}</#{type}>"
    end
  end
end
