module JackAnalyzer
  # Removes all comments and white space from the input
  # stream and break it into jack tokens, as specified by the jack token
  #
  # Arguments:
  #
  #   input_file : (File)
  class Tokenizer
    attr_reader :source, :tokens

    def initialize(source)
      @source = source
      @current_token = nil
      @start_char_index = 0
      @current_char_index = 0
      @line = 0
      @tokens = []
    end

    def tokenize
      until at_end?
        @start_char_index = @current_char_index
        @current_token = advance
        # p @current_token.to_s
        @tokens << @current_token if @current_token
      end
      tokens
    end

    private

    def has_more_tokens?
      source.size > @current_char_index
    end

    # Gets the next token from the source
    # and makes it the current_token
    def advance
      c = next_char
      return if TokenType.whitespaces.include?(c)
      return new_line if c == "\n"
      return comment if c == '/'
      return symbol if TokenType.symbols.include?(c)
      return integer_constant if digit?(c)
      return string_constant if c == '"'
      return identifer if alpha?(c)
    end

    def new_token(type, literal = nil)
      Token.new(type, token_text, literal,
                line: @line, start_column: @start_char_index, end_column: @current_char_index)
    end

    # consumes the next char and returns it
    def next_char
      @current_char_index += 1
      source[@current_char_index - 1]
    end

    def symbol
      new_token(TokenType::SYMBOL)
    end

    def integer_constant
      next_char while digit?(lookahead)
      integer_literal = token_text
      new_token(TokenType::INT_CONST, integer_literal)
    end

    def comment
      if lookahead == '/'
        next_char
        next_char while lookahead != "\n" && !at_end?
      elsif lookahead == '*'
        if lookahead(1) == '*'
          next_char
          next_char
        end
        next_char # *
        next_char while lookahead != '*'
        next_char # *
        next_char # /
      end
      nil
    end

    def new_line
      @line += 1
      nil
    end

    def string_constant
      next_char while lookahead != '"' && !at_end?
      next_char
      string_literal = source[(@start_char_index + 1)...(@current_char_index - 1)]
      new_token(TokenType::STING_CONST, string_literal)
    end

    def identifer
      next_char while alpha_numeric?(lookahead)
      return new_token(TokenType::KEYWORD) if TokenType.keywords.include?(token_text)
      new_token(TokenType::IDENTIFIER)
    end

    def token_text
      source[@start_char_index...@current_char_index]
    end

    def lookahead(ll_index = 0)
      return "\0" if @current_char_index + ll_index > source.size
      @source[@current_char_index + ll_index]
    end

    def at_end?
      @current_char_index >= source.size
    end

    def alpha_numeric?(c)
      alpha?(c) || digit?(c)
    end

    def alpha?(c)
      (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
    end

    def digit?(c)
      (c >= '0') && (c <= '9')
    end
  end
end
