module JackAnalyzer
  module TokenType
    KEYWORD = 'keyword'.freeze
    SYMBOL = 'symbol'.freeze
    IDENTIFIER = 'identifier'.freeze
    INT_CONST = 'integerConstant'.freeze
    STING_CONST = 'stringConstant'.freeze

    # Single-character tokens
    # LEFT_PAREN = 'LEFT_PAREN'.freeze
    # RIGHT_PAREN = 'RIGHT_PAREN'.freeze
    # LEFT_BRACE = 'LEFT_BRACE'.freeze
    # RIGHT_BRACE = 'RIGHT_BRACE'.freeze
    # COMMA = 'COMMA'.freeze
    # DOT = 'DOT'.freeze
    # MINUS = 'MINUS'.freeze
    # PLUS = 'PLUS'.freeze
    # SEMICOLON = 'SEMICOLON'.freeze
    # SLASH = 'SLASH'.freeze
    # STAR = 'STAR'.freeze

    # # # One or two character tokens
    # BANG = 'BANG'.freeze
    # BANG_EQUAL = 'BANG_EQUAL'.freeze
    # EQUAL = 'EQUAL'.freeze
    # EQUAL_EQAUL = 'EQUAL_EQAUL'.freeze
    # GREATER = 'GREATER'.freeze
    # GREATER_EQUAL = 'GREATER_EQUAL'.freeze
    # LESS = 'LESS'.freeze
    # LESS_EQUAL = 'LESS_EQUAL'.freeze

    def self.symbols
      ['{', '}', '(', ')', '[', ']', '.', ',', ';', '+', '-', '*', '&',
       '|', '<', '>', '+', '~', '=']
    end

    def self.whitespaces
      ["\t", "\r", ' ']
    end

    #
    # KEYWORDS
    #
    AND = 'and'.freeze
    CLASS = 'class'.freeze
    ELSE = 'else'.freeze
    FALSE = 'false'.freeze
    FUNCTION = 'function'.freeze
    METHOD = 'method'.freeze
    FOR = 'for'.freeze
    IF = 'if'.freeze
    OR = 'or'.freeze
    RETURN = 'return'.freeze
    THIS = 'this'.freeze
    TRUE = 'true'.freeze
    VAR = 'var'.freeze
    WHILE = 'while'.freeze
    CONSTRUCTOR = 'constructor'.freeze
    FIELD = 'field'.freeze
    STATIC = 'static'.freeze
    INT = 'int'.freeze
    CHAR = 'char'.freeze
    BOOLEAN = 'boolean'.freeze
    VOID = 'void'.freeze
    NULL = 'null'.freeze
    LET = 'let'.freeze
    DO = 'do'.freeze

    #
    # Reserved words map
    #
    def self.keywords
      {
        'and' => TokenType::AND,
        'class' => TokenType::CLASS,
        'else' => TokenType::ELSE,
        'if' => TokenType::IF,
        'constructor' => TokenType::CONSTRUCTOR,
        'for' => TokenType::FOR,
        'var' => TokenType::VAR,
        'null' => TokenType::NULL,
        'true' => TokenType::TRUE,
        'false' => TokenType::FALSE,
        'this' => TokenType::THIS,
        'while' => TokenType::WHILE,
        'return' => TokenType::RETURN,
        'or' => TokenType::OR,
        'function' => TokenType::FUNCTION,
        'method' => TokenType::METHOD,
        'field' => TokenType::FIELD,
        'static' => TokenType::STATIC,
        'int' => TokenType::INT,
        'char' => TokenType::CHAR,
        'boolean' => TokenType::BOOLEAN,
        'void' => TokenType::VOID,
        'let' => TokenType::LET,
        'do' => TokenType::DO
      }
    end
  end
end
