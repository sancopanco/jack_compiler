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
      path = 'out.xml'
      File.delete(path) if File.exist?(path)
      @output_file = File.open(path, 'a')
    end

    def parse
      write_tag '<class>'
      compile_class
      write_tag '</class>'
      @output_file.close
    end

    #
    # Program structure
    #
    # class: 'class' className '{' classVarDec* subroutineDec* '}'
    # type: 'int' | 'char' | 'boolean' | className
    # className: identifier
    def compile_class
      consume(TokenType::CLASS)

      consume(TokenType::IDENTIFIER)
      consume('{')

      until check_any?(TokenType::CONSTRUCTOR, TokenType::METHOD, TokenType::FUNCTION)
        class_var_declarations if check_any?(TokenType::STATIC, TokenType::FIELD)
      end

      until check?('}')
        subroutine_declerations if check_any?(TokenType::CONSTRUCTOR, TokenType::METHOD, TokenType::FUNCTION)
      end

      consume('}')
    end

    #
    # classVarDec: ('static' | 'field')type varName(',' varName)* ';'
    def class_var_declarations
      write_tag '<classVarDec>'
      match(TokenType::STATIC, TokenType::FIELD)
      compile_type
      consume(TokenType::IDENTIFIER) # varName
      consume(TokenType::IDENTIFIER) while match(',') # (',' varName)*
      consume(';')
      write_tag '</classVarDec>'
    end

    #
    # type: 'int' | 'char' | 'boolean' | className
    # className: identifer
    #
    def compile_type
      return if match(TokenType::INT, TokenType::CHAR, TokenType::BOOLEAN)
      consume(TokenType::IDENTIFIER)
    end

    #
    # subRoutineDec: ('constructor' | 'function' | 'method') (void | type)
    # subroutineName '(' parameterlist ')' subroutineBody
    # subroutineName: identifier
    def subroutine_declerations
      write_tag '<subroutineDec>'
      match(TokenType::CONSTRUCTOR, TokenType::FUNCTION, TokenType::METHOD) # ('constructor' | 'function' | 'method')
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
      write_tag '</subroutineDec>'
    end

    # paramterList: ((type varName)(',' type varName)*)?
    # varName: identifier
    def compile_parameterlist
      write_tag '<parameterList>'
      until check?(')')
        compile_type
        consume(TokenType::IDENTIFIER) # varName
        break unless check?(',')
        consume(',')
      end
      write_tag '</parameterList>'
    end

    #
    # subroutineBody: '{' varDec* statements '}'
    #
    def compile_subroutine_body
      write_tag '<subroutineBody>'
      consume('{')
      compile_var_declaration while check?(TokenType::VAR)
      compile_statements
      consume('}')
      write_tag '</subroutineBody>'
    end

    #
    # varDec: 'var' type varName(',' varName)* ';'
    #
    def compile_var_declaration
      write_tag '<varDec>'
      consume(TokenType::VAR)
      compile_type
      consume(TokenType::IDENTIFIER)
      while check?(',')
        consume(',')
        consume(TokenType::IDENTIFIER)
        break if check?(';')
      end
      consume(';')
      write_tag '</varDec>'
    end

    #
    # statements: statement*
    #
    def compile_statements
      write_tag '<statements>'
      compile_statement until check?('}')
      write_tag '</statements>'
    end

    #
    # statement: letStatement | ifStatement | whileStatement
    # | doStatement | returnStatement
    #
    def compile_statement
      # write_tag '<statement>'
      return compile_let_statement if check?(TokenType::LET)
      return compile_while_statement if check?(TokenType::WHILE)
      return compile_do_statement if check?(TokenType::DO)
      return compile_return_statement if check?(TokenType::RETURN)
      return compile_if_statement if check?(TokenType::IF)
      # write_tag '</statement>'
    end

    #
    # letStatement: 'let' varName ('[' expression ']')? '=' expression;
    #
    def compile_let_statement
      write_tag '<letStatement>'
      consume(TokenType::LET)
      consume(TokenType::IDENTIFIER) # varName
      if check?('[')
        consume('[')
        compile_expression
        consume(']')
      end
      consume('=')
      compile_expression
      consume(';')
      write_tag '</letStatement>'
    end

    #
    # whileStatement: 'while' '(' expression ')' '{' statements '}'
    #
    def compile_while_statement
      write_tag '<whileStatement>'
      consume(TokenType::WHILE)
      consume('(')
      compile_expression
      consume(')')
      consume('{')
      compile_statements
      consume('}')
      write_tag '</whileStatement>'
    end

    #
    # ifStatement: 'if' '(' expression ')' '{' statements '}'
    # ('else' '{' statements '}')?
    #
    def compile_if_statement
      write_tag '<ifStatement>'
      consume(TokenType::IF)
      consume('(')
      compile_expression
      consume(')')
      consume('{')
      compile_statements
      consume('}')
      # Else case
      if match(TokenType::ELSE)
        consume('{')
        compile_statements
        consume('}')
      end
      write_tag '</ifStatement>'
    end

    #
    # doStatement: 'do' subroutineCall ';'
    #
    def compile_do_statement
      write_tag '<doStatement>'
      consume(TokenType::DO)
      compile_subroutine_call
      consume(';')
      write_tag '</doStatement>'
    end

    #
    # returnStatement: 'return' expression? ';'
    #
    def compile_return_statement
      write_tag '<returnStatement>'
      consume(TokenType::RETURN)
      compile_expression unless check?(';') # empty expression case
      consume(';')
      write_tag '</returnStatement>'
    end

    # expression: term(op term)*
    # op: '+' | '-' | '/' | '=' | '>' | '<' | '&' | '|' | '*'
    def compile_expression
      write_tag '<expression>'
      compile_term
      compile_term while match('+', '-', '<', '/', '=', '>', '&', '|', '*')
      write_tag '</expression>'
    end

    #
    # term: integerConstant | stringConstant | keywordConstant | varName |
    # varName '[' expression ']' | subroutineCall | '(' expression ')' | unaryOp term
    # unaryOp: '-' | '~'
    def compile_term
      write_tag '<term>'
      if match(TokenType::STING_CONST)
        write_tag '</term>'
        return
      end
      if match(TokenType::INT_CONST)
        write_tag '</term>'
        return
      end
      if check_any?('true', 'false', 'null', 'this')
        consume(TokenType::KEYWORD)
        write_tag '</term>'
        return
      end
      if check?(TokenType::IDENTIFIER)
        if lookahead(1).lexeme == '[' # ArrayEntry
          consume(TokenType::IDENTIFIER)
          consume('[')
          compile_expression
          consume(']')
        elsif lookahead(1).lexeme == '.'
          compile_subroutine_call
        else
          consume(TokenType::IDENTIFIER) # variable
        end
        write_tag '</term>'
        return
      end

      if check?('(')
        consume('(')
        compile_expression
        consume(')')
        write_tag '</term>'
        return
      end

      if check_any?('-', '~')
        consume(TokenType::SYMBOL)
        compile_term
      end
      write_tag '</term>'
    end

    #
    # subroutineCall: subroutineName '(' expressionList ')' |
    # (className | varName) '.' subroutineName '(' expressionList ')'
    # className: identifier
    # varName: identifier
    # subroutineName: identifier
    def compile_subroutine_call
      consume(TokenType::IDENTIFIER)
      if check?('(')
        consume('(') # subroutineName
        compile_expression_list
        consume(')')
      elsif check?('.')
        consume('.')
        consume(TokenType::IDENTIFIER) # (className | varName)
        consume('(')
        compile_expression_list
        consume(')')
      end
    end

    #
    # expressionList: (expression (',' expression)*)?
    #
    def compile_expression_list
      write_tag '<expressionList>'
      compile_expression unless check?(')') # Emptylist
      compile_expression while match(',')
      write_tag '</expressionList>'
    end

    private

    class ParserError < StandardError; end

    def write_tag(tag)
      @output_file.write("#{tag} \n")
    end

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

    def check_any?(*token_types)
      token_types.each do |token_type|
        return true if check?(token_type)
      end
      false
    end

    def check?(token_type_or_lexeme)
      return false if at_end?
      return true if lookahead.lexeme == token_type_or_lexeme
      lookahead.type == token_type_or_lexeme
    end

    def consume(token_type_or_lexeme)
      return advance if check?(token_type_or_lexeme)
      error(lookahead)
    end

    def error(token)
      puts "[Line #{token.line}]: Error at #{token.lexeme}"
      ParserError.new
    end

    def advance
      @current += 1 unless at_end?
      write_tag previous.to_xml
      tokens[@current - 1]
    end

    # Most recently consumed one
    def previous
      tokens[@current - 1]
    end

    # The one that we've yet to comsume
    def lookahead(ll_index = 0)
      retun nil if @current + ll_index >= tokens.size
      tokens[@current + ll_index]
    end

    def at_end?
      @current >= tokens.size
    end
  end
end
