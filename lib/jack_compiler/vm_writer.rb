module JackCompiler
  class VMWriter
    #
    # Creates a new file and prepares it for writing
    #
    def initialize(path)
      File.delete(path) if File.exist?(path)
      @output = File.new(path, 'w')
    end

    #
    # segment: CONST, ARG, LOCAL, STATIC, THIS, POINTER, TEMP
    # index: integer
    # Writes a VM push comand
    #
    def write_push(segment, index)
      @output.write("push #{segment} #{index}\n")
    end

    def write_pop(segement, index)
      @output.write("pop #{segement} #{index} \n")
    end

    #
    # command: ADD, SUB, NEG, EQ, GT, LT, AND, OR, NOT
    #
    def write_arithmetic(command)
      vm_commands_map = {
        '+' => 'add', '~' => 'not', '/' => 'call Math.divide 2',
        '-' => 'sub', '*' => 'call Math.multiply 2',
        '>' => 'gt', '<' => 'lt', '&' => 'and',
        'neg' => 'neg', 'not' => 'not', '=' => 'eq'
      }
      @output.write("#{vm_commands_map[command] || command}\n")
    end

    #
    # label: string
    # Writes a VM label command
    #
    def write_label(label)
      @output.write("label #{label}\n")
    end

    #
    # name: name of the subroutine
    # nargs : number of arguments
    # Writes a VM call command
    def write_call(name, nargs)
      @output.write("call #{name} #{nargs}\n")
    end

    #
    # name: subroutine name
    # nlocal: number of local variables
    def write_function(name, nlocals)
      @output.write("function #{name} #{nlocals}\n")
    end

    # Writes a VM return command
    def write_return
      @output.write("return\n")
    end

    # Writes a VM if-goto command
    def write_if(label)
      @output.write("if-goto #{label}\n")
    end

    # Writes a VM goto command
    def write_goto(label)
      @output.write("goto #{label}\n")
    end

    #
    # Close the output file
    #
    def close; end
  end
end
