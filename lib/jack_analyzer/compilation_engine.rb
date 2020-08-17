module JackAnalyzer
  #
  # Gets its input from a JackTokenizer and emits a structured
  # printout of the code, wrapped in XML tags
  #
  # Recursive top-down parser
  # The compilation unit is a class
  class CompilationEngine
    attr_reader :tokens, :output
    def initialize(tokens)
      @tokens = tokens
      @current = 0
      @output = []
    end

    def parse
      compile_class
    end

    #
    # Program structure
    #
    # class: 'class' className '{' classVarDec* subroutineDec* '}'
    # type: 'int' | 'char' | 'boolean' | className
    # className: identifier
    def compile_class
      consume(TokenType::CLASS)
      output << '<class>'
      consume(TokenType::IDENTIFIER)
      consume('{')
      class_var_declarations
      subroutine_declerations if match(TokenType::CONSTRUCTOR, TokenType::METHOD, TokenType::FUNCTION)
      output << '</class>'
    end

    #
    # classVarDec: ('static' | 'field')type varName(',' varName)* ';'
    def class_var_declarations
      'var_decs'
    end

    #
    # subRoutineDec: ('constructor' | 'function' | 'method') (void | type)
    # subroutineName '(' parameterlist ')' subroutineBody
    # subroutineName: identifier
    def subroutine_declerations
      output << '<subroutineDec>'
      if check?(TokenType::VOID)
        advance
      else
        compile_type
      end
      consume(TokenType::IDENTIFIER) # subroutineName
      consume('(')
      compile_parameterlist
      consume(')')
      compile_subroutine_body
      output << '</subroutineDec>'
    end

    # paramterList: ((type varName)(',' type varName)*)?
    # varName: identifier
    def compile_parameterlist
      output << '<parameterList>'
      until check?(')')
        compile_type
        consume(TokenType::IDENTIFIER) # varName
        break unless check?(',')
        consume(',')
      end
      output << '</parameterList>'
    end

    #
    # subroutineBody: '{' varDec* statements '}'
    #
    def compile_subroutine_body
      output << '<subroutineBody>'
      consume('{')
      compile_var_declaration while check?(TokenType::VAR)
      compile_statements
      consume('}')
      output << '</subroutineBody>'
    end

    #
    # varDec: 'var' type varName(',' varName)* ';'
    #
    def compile_var_declaration
      output << '<varDec>'
      consume(TokenType::VAR)
      compile_type
      consume(TokenType::IDENTIFIER)
      while check?(',')
        consume(',')
        consume(TokenType::IDENTIFIER)
        break if check?(';')
      end
      consume(';')
      output << '</varDec>'
    end

    #
    # statements: statement*
    #
    def compile_statements
      output << '<statements>'
      compile_statement until check?('}')
      output << '</statements>'
    end

    #
    # statement: letStatement | ifStatement | whileStatement
    # | doStatement | returnStatement
    #
    def compile_statement
      compile_let_statement if check?(TokenType::LET)
    end

    # letStatement: 'let' varName ('[' expression ']')? '=' expression;
    def compile_let_statement
      output << '<letStatement>'
      consume('let')
      consume(TokenType::IDENTIFIER) # varName
      consume('=')
      compile_expression
      consume(';')
      output << '</letStatement>'
    end

    # expression: term(op term)*
    def compile_expression
      compile_term
      # compile_term while match('+')
    end

    #
    # term: integerConstant | stringConstant | keywordConstant | varName |
    # varName '[' expression ']' | subroutineCall
    #
    def compile_term
      return if match(TokenType::STING_CONST)
      return if match(TokenType::INT_CONST)
      # return if match(TokenType::IDENTIFIER) # varName
      compile_subroutine_call
    end

    #
    # subroutineCall: subroutineName '(' expressionList ')' |
    # (className | varName) '.' subroutineName '(' expressionList ')'
    # className: identifier
    # varName: identifier
    # subroutineName: identifier
    def compile_subroutine_call
      consume(TokenType::IDENTIFIER)
      consume('.')
      consume(TokenType::IDENTIFIER)
      consume('(')
      compile_expression_list
      consume(')')
    end

    #
    # expressionList: (expression (',' expression)*)?
    #
    def compile_expression_list
      compile_expression
      compile_expression while match(',')
    end

    #
    # type: 'int' | 'char' | 'boolean' | className
    # className: identifer
    #
    def compile_type
      return if match(TokenType::INT, TokenType::CHAR, TokenType::BOOLEAN)
      consume(TokenType::IDENTIFIER)
    end

    private

    def match_keyword(*keywords)
      keywords.each do |keyword|
        if !at_end? && lookahead.lexeme == keyword
          advance
          return true
        end
      end
      false
    end

    #
    # Check if there is any match
    #
    def match(*token_types)
      token_types.each do |token_type|
        if check?(token_type)
          advance
          return true
        end
      end
      false
    end

    def check?(token_type_or_lexeme)
      return false if at_end?
      return true if lookahead.lexeme == token_type_or_lexeme
      lookahead.type == token_type_or_lexeme
    end

    def consume(token_type_or_lexeme)
      if check?(token_type_or_lexeme)
        advance
      else
        puts 'error'
      end
    end

    def advance
      @current += 1 unless at_end?
      output << previous.to_xml
      tokens[@current - 1]
    end

    # Most recently consumed one
    def previous
      tokens[@current - 1]
    end

    # The one that we've yet to comsume
    def lookahead
      tokens[@current]
    end

    def at_end?
      @current >= tokens.size
    end
  end
end
