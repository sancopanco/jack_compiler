# For each Xxx.jack input file, the compiler creates a jack_tokenizer
# and an output Xxx.vm file
require 'jack_compiler/runner'
require 'jack_compiler/token_type'
require 'jack_compiler/token'
require 'jack_compiler/tokenizer'
require 'jack_compiler/vm_writer'
require 'jack_compiler/compilation_engine'
require 'jack_compiler/symbol_table'

module JackCompiler
  def self.main
    Runner.run
  end

  def self.run(content, output_path)
    tokens = Tokenizer.new(content).tokenize
    vm_writer = VMWriter.new(output_path)
    ce = CompilationEngine.new(tokens, vm_writer)
    ce.parse
    # puts ce.class_symbol_table.inspect
  end
end
