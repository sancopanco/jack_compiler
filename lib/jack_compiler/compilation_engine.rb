module JackCompiler
  #
  # Gets its input from a JackTokenizer and emits a structured
  # printout of the code, wrapped in XML tags
  #
  # Recursive top-down parser
  # The compilation unit is a class
  class CompilationEngine
    attr_reader :tokens, :output, :class_symbol_table
    def initialize(tokens, vm_writer)
      @tokens = tokens
      @current = 0
      path = 'out.xml'
      File.delete(path) if File.exist?(path)
      @output_file = File.open(path, 'a')
      @current_class_name_token = nil
      @vm_writer = vm_writer
      @label_counter = {
        if_id: 0,
        while_id: 0,
        if_end: 0,
        if_false: 0,
        if_true: 0
      }
    end

    def parse
      write_tag '<class>'
      @class_symbol_table = SymbolTable.new
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

      @current_class_name_token = consume(TokenType::IDENTIFIER)
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
      token_kind = advance if check_any?(TokenType::STATIC, TokenType::FIELD)
      token_type = compile_type
      token_name = consume(TokenType::IDENTIFIER) # varName
      @class_symbol_table.define(token_name.lexeme, token_type.lexeme, token_kind.lexeme)

      while match(',') # (',' varName)*
        token_name = consume(TokenType::IDENTIFIER)
        @class_symbol_table.define(token_name.lexeme, token_type.lexeme, token_kind.lexeme)
      end
      consume(';')
      write_tag '</classVarDec>'
    end

    #
    # type: 'int' | 'char' | 'boolean' | className
    # className: identifer
    #
    def compile_type
      return advance if check_any?(TokenType::INT, TokenType::CHAR, TokenType::BOOLEAN)
      consume(TokenType::IDENTIFIER)
    end

    #
    # subRoutineDec: ('constructor' | 'function' | 'method') (void | type)
    # subroutineName '(' parameterlist ')' subroutineBody
    # subroutineName: identifier
    def subroutine_declerations
      write_tag '<subroutineDec>'
      @subroutine_symbol_table = SymbolTable.new(@class_symbol_table)
      @label_counter[:if_id] = 0
      @label_counter[:while_id] = 0

      # ('constructor' | 'function' | 'method')
      if check_any?(TokenType::CONSTRUCTOR, TokenType::FUNCTION, TokenType::METHOD)
        @current_function_kind_token = advance
      end

      funcion_type_token = if check?(TokenType::VOID)
                             advance
                           else
                             compile_type
                           end

      # Every method always contains this object as the first entry of its symbol table
      if %w[method constructor].include?(@current_function_kind_token.lexeme)
        @subroutine_symbol_table.define('this', @current_class_name_token.lexeme, 'argument')
      end

      @current_subroutine_name_token = consume(TokenType::IDENTIFIER)

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
        toke_type = compile_type
        token_name = consume(TokenType::IDENTIFIER) # varName
        @subroutine_symbol_table.define(token_name.lexeme, toke_type.lexeme, 'arg')
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
      # No code generation, only updates symbol table
      compile_var_declaration while check?(TokenType::VAR)

      number_of_locals = @subroutine_symbol_table.var_count('var')
      vm_writer.write_function("#{@current_class_name_token.lexeme}.#{@current_subroutine_name_token.lexeme}", number_of_locals)

      # Compiler generates the code necassary for allocating memory
      # for the newly constructed object -- this = alloc(n)
      # Sets the this pointer (pointer 0) to the base address of the memory block
      # Compiler uses the number and type of class fields to determine how many words
      # are neccesary the object on the host RAM
      if @current_function_kind_token.lexeme == 'constructor'
        number_of_fields = @class_symbol_table.var_count('field')
        @vm_writer.write_push('constant', number_of_fields)
        @vm_writer.write_call('Memory.alloc', 1)
        @vm_writer.write_pop('pointer', 0) # anchors this at the base address
      end

      # Associates this memory segment with the object on which
      # the method is called to operate
      if @current_function_kind_token.lexeme == 'method'
        @vm_writer.write_push('argument', 0)
        @vm_writer.write_pop('pointer', 0) # set THIS = argument 0
      end

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
      type_token = compile_type
      name_token = consume(TokenType::IDENTIFIER)
      @subroutine_symbol_table.define(name_token.lexeme, type_token.lexeme, 'var')
      while check?(',')
        consume(',')
        name_token = consume(TokenType::IDENTIFIER)
        @subroutine_symbol_table.define(name_token.lexeme, type_token.lexeme, 'var')
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
      var_name_token = consume(TokenType::IDENTIFIER)
      # Array assignment
      # let arr[index] = expr, *(arr+index) = expr
      #
      if check?('[')
        consume('[')
        @vm_writer.write_push(@subroutine_symbol_table.segment_of(var_name_token.lexeme),
                              @subroutine_symbol_table.index_of(var_name_token.lexeme))
        compile_expression
        @vm_writer.write_arithmetic('add')
        consume(']')
        consume('=')
        compile_expression
        @vm_writer.write_pop('temp', 0)
        @vm_writer.write_pop('pointer', 1) # Set THAT = stack.pop
        @vm_writer.write_push('temp', 0)
        @vm_writer.write_pop('that', 0)
      else
        # let varName = expr;
        consume('=')
        compile_expression
        @vm_writer.write_pop(@subroutine_symbol_table.segment_of(var_name_token.lexeme),
                             @subroutine_symbol_table.index_of(var_name_token.lexeme))
      end

      consume(';')
      write_tag '</letStatement>'
    end

    #
    # whileStatement: 'while' '(' expression ')' '{' statements '}'
    #
    def compile_while_statement
      write_tag '<whileStatement>'
      consume(TokenType::WHILE)
      @vm_writer.write_label("#{@current_subroutine_name_token.lexeme}$WHILE_EXP_#{@label_counter[:while_id]}")
      consume('(')
      compile_expression
      consume(')')
      consume('{')
      @vm_writer.write_arithmetic('~')
      @vm_writer.write_if("#{@current_subroutine_name_token.lexeme}$WHILE_END_#{@label_counter[:while_id]}")

      compile_statements
      @vm_writer.write_goto("#{@current_subroutine_name_token.lexeme}$WHILE_EXP_#{@label_counter[:while_id]}")
      consume('}')

      @vm_writer.write_label("#{@current_subroutine_name_token.lexeme}$WHILE_END_#{@label_counter[:while_id]}")
      @label_counter[:while_id] += 1
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

      # @vm_writer.write_arithmetic('~')
      @vm_writer.write_if("#{@current_subroutine_name_token.lexeme}$IF_TRUE_#{@label_counter[:if_id]}")
      @vm_writer.write_goto("#{@current_subroutine_name_token.lexeme}$IF_FALSE_#{@label_counter[:if_id]}")
      @vm_writer.write_label("#{@current_subroutine_name_token.lexeme}$IF_TRUE_#{@label_counter[:if_id]}")
      consume(')')
      consume('{')
      compile_statements
      consume('}')
      @vm_writer.write_goto("#{@current_subroutine_name_token.lexeme}$IF_END_#{@label_counter[:if_id]}")
      @vm_writer.write_label("#{@current_subroutine_name_token.lexeme}$IF_FALSE_#{@label_counter[:if_id]}")
      # Else case
      if match(TokenType::ELSE)
        consume('{')
        compile_statements
        consume('}')
      end

      @vm_writer.write_label("#{@current_subroutine_name_token.lexeme}$IF_END_#{@label_counter[:if_id]}")
      @label_counter[:if_id] += 1
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
      # ignored the return value which is always zero
      @vm_writer.write_pop('temp', 0)
      write_tag '</doStatement>'
    end

    #
    # returnStatement: 'return' expression? ';'
    #
    def compile_return_statement
      write_tag '<returnStatement>'
      consume(TokenType::RETURN)
      if check?(';')
        # empty expression case
        # VM methods for void methods and functions must return the consant 0
        @vm_writer.write_push('constant', 0)
      else
        compile_expression
      end

      consume(';')
      @vm_writer.write_return
      write_tag '</returnStatement>'
    end

    # expression: term(op term)*
    # op: '+' | '-' | '/' | '=' | '>' | '<' | '&' | '|' | '*'
    def compile_expression
      write_tag '<expression>'
      compile_term
      # exp1 op exp2
      while check_any?('+', '-', '<', '/', '=', '>', '&', '|', '*')
        op_token = advance
        compile_term
        @vm_writer.write_arithmetic(op_token.lexeme)
      end
      write_tag '</expression>'
    end

    #
    # term: integerConstant | stringConstant | keywordConstant | varName |
    # varName '[' expression ']' | subroutineCall | '(' expression ')' | unaryOp term
    # unaryOp: '-' | '~'
    def compile_term
      write_tag '<term>'
      if check?(TokenType::STING_CONST)
        write_tag '</term>'
        string_token = advance
        # String constants are created using the OS constructor String.new(length)
        # String assignments like x="cc...c" are handled
        # using a series of calls to the OS routine String . appendChar (nextChar).
        string_literal = string_token.literal
        lenght = string_literal.size
        @vm_writer.write_push('constant', lenght)
        @vm_writer.write_call('String.new', 1)
        string_literal.chars.each do |c|
          @vm_writer.write_push('constant', c.ord)
          @vm_writer.write_call('String.appendChar', 2)
        end
        return
      end

      # exp is a number
      if check?(TokenType::INT_CONST)
        write_tag '</term>'
        int_token = advance
        @vm_writer.write_push('constant', int_token.literal)
        return
      end

      if check_any?('true', 'false', 'null', 'this')
        keyword_const_token = consume(TokenType::KEYWORD)

        # true is mapped to constant -1
        # false and null are mapped to 0
        if keyword_const_token.lexeme == 'true'
          @vm_writer.write_push('constant', 0)
          @vm_writer.write_arithmetic('not')
        elsif keyword_const_token.lexeme == 'false' || keyword_const_token.lexeme == 'null'
          @vm_writer.write_push('constant', 0)
        elsif keyword_const_token.lexeme == 'this'
          # return this  constructor use this
          # pointer o contains the base address of this
          @vm_writer.write_push('pointer', 0)
        end
        write_tag '</term>'
        return
      end

      if check?(TokenType::IDENTIFIER)
        if lookahead(1).lexeme == '['
          # Accessing an array entry
          # varName '[' expression ']', a[i]
          var_name_token = consume(TokenType::IDENTIFIER)
          @vm_writer.write_push(@subroutine_symbol_table.segment_of(var_name_token.lexeme),
                                @subroutine_symbol_table.index_of(var_name_token.lexeme))
          consume('[')
          compile_expression
          @vm_writer.write_arithmetic('add')
          @vm_writer.write_pop('pointer', 1) # set THAT = stack.pop()
          @vm_writer.write_push('that', 0) # stack.push(that 0)
          consume(']')
        elsif lookahead(1).lexeme == '.'
          compile_subroutine_call
        else
          # exp is a variable
          var_name_token = consume(TokenType::IDENTIFIER)
          @vm_writer.write_push(@subroutine_symbol_table.segment_of(var_name_token.lexeme),
                                @subroutine_symbol_table.index_of(var_name_token.lexeme))
        end
        write_tag '</term>'
        return
      end

      # (exp)
      if check?('(')
        consume('(')
        compile_expression
        consume(')')
        write_tag '</term>'
        return
      end

      # exp is op(exp1)
      if check_any?('-', '~')
        unary_op_token = consume(TokenType::SYMBOL)
        compile_term

        if unary_op_token.lexeme == '-'
          @vm_writer.write_arithmetic('neg')
        else
          @vm_writer.write_arithmetic('not')
        end
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
      class_or_var_or_subroutine_name_token = consume(TokenType::IDENTIFIER)
      @number_of_args = 0
      if check?('(')
        # method call on instance
        this_type = @subroutine_symbol_table.type_of('this')
        consume('(')
        @vm_writer.write_push('pointer', 0)
        @number_of_args += 1
        compile_expression_list(this_type, class_or_var_or_subroutine_name_token.lexeme)
        consume(')')
      elsif check?('.')
        # (className | varName)
        consume('.')
        subroutine_name_token = consume(TokenType::IDENTIFIER)
        consume('(')

        obj_type = @subroutine_symbol_table.type_of(class_or_var_or_subroutine_name_token.lexeme)
        if obj_type
          # The object is always treated as the first implicit argument
          # foo.bar(v1,v2,...) is translated into push foo, push v1, push v2 ... call bar
          # foo already stored the base address of object
          @vm_writer.write_push(@subroutine_symbol_table.segment_of(class_or_var_or_subroutine_name_token.lexeme),
                                @subroutine_symbol_table.index_of(class_or_var_or_subroutine_name_token.lexeme))
          @number_of_args += 1
          compile_expression_list(obj_type, subroutine_name_token.lexeme)
        else
          # ClassName.methodx
          # static methods aka functions
          compile_expression_list(class_or_var_or_subroutine_name_token.lexeme, subroutine_name_token.lexeme)
        end
        consume(')')
      end
    end

    #
    # expressionList: (expression (',' expression)*)?
    #
    def compile_expression_list(klass_name, subroutine_name)
      write_tag '<expressionList>'

      unless check?(')') # Emptylist
        compile_expression
        @number_of_args += 1
      end

      while match(',')
        compile_expression
        @number_of_args += 1
      end
      @vm_writer.write_call("#{klass_name}.#{subroutine_name}", @number_of_args)
      write_tag '</expressionList>'
    end

    private

    attr_reader :vm_writer

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
      return nil if @current + ll_index >= tokens.size
      tokens[@current + ll_index]
    end

    def at_end?
      @current >= tokens.size
    end
  end
end
