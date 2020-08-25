# This module provides services for creating ans using a symbol table
module JackCompiler
  #
  # Each symbol has a scope from which it is visible in the source code
  # Associates the identifier names found in the program with the identifier
  # properties needed for the compilation: type, kind, and runnung index
  # Symbol tables for the jack programs has two nested scopes(class/subroutine)
  class SymbolTable
    attr_reader :class_scope, :subroutine_scope
    def initialize
      @class_scope = {}
      @subroutine_scope = {}
      @index_counter = {}
    end

    # Resets the subroutine index table
    def start_subroutine
      @subroutine_scope = {}
    end

    def define_in_subroutine(name, type, kind)
      @subroutine_scope[name.to_sym] = { type: type, kind: kind, index: var_count(kind) }
    end

    def define_in_class(name, type, kind)
      @class_scope[name.to_sym] = { type: type, kind: kind, index: var_count(kind) }
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
      (@subroutine_scope[name.to_sym] || @class_scope[name.to_sym]).index
    end

    # Returns the type of the named identifier in the current scope
    def type_of(name)
      (@subroutine_scope[name.to_sym] || @class_scope[name.to_sym]).type
    end

    private

    attr_writer :class_scope, :subroutine_scope
  end
end
