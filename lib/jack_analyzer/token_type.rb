module JackAnalyzer
  module TokenType
    KEYWORD = 'keyword'.freeze
    SYMBOL = 'symbol'.freeze
    IDENTIFIER = 'identifier'.freeze
    INT_CONST = 'int_const'.freeze
    STING_CONST = 'string_const'.freeze

    def self.symbols
      ['{', '}', '(', ')', '[', ']', '.', ',', ';', '+', '-', '*', '/', '&',
       '|', '<', '>', '+', '~']
    end

    def self.whitespaces
      ["\t", "\r", ' ']
    end

    def self.keywords
      %w[class constructor function method field static var int
         char boolean void true false null this let do if else while do]
    end
  end
end
