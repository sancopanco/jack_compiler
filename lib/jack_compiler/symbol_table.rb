# This module provides services for creating ans using a symbol table
module JackCompiler
  #
  # Each symbol has a scope from which it is visible in the source code
  # Associates the identifier names found in the program with the identifier
  # properties needed for the compilation: type, kind, and runnung index
  # Symbol tables for the jack programs has two nested scopes(class/subroutine)
  class SymbolTable
    attr_reader :scope
    def initialize
      @scope = {}
      @index_counter = {}
    end

    # Resets the subroutine symbol table
    def start_subroutine
      self.class.new
    end

    def define(name, type, kind)
      @scope[name.to_sym] = { type: type, kind: kind, index: var_count(kind) }
    end

    # Returns the number of variables of the given kind already defined in the
    # current_scope
    def var_count(kind)
      unless @index_counter[kind]
        @index_counter[kind] = 0
        return 0
      end
      @index_counter[kind] += 1
    end

    # Returns the index assigned to the named indentifer
    def index_of(name)
      @scope[name.to_sym][:index]
    end

    # Returns the type of the named identifier in the current scope
    def type_of(name)
      @scope[name.to_sym][:type]
    end

    # Returns the kins of the named identifier(static, field, var, arg, none)
    def kinds_of(name)
      @scope[name.to_sym][:kind]
    end

    # Returns the mapped memory segement
    def segment_of(name)
      {
        arg: 'argument',
        var: 'local'
      }[kinds_of(name).to_sym]
    end
  end
end
