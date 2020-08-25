require_relative 'jack_analyzer/token_type'
require_relative 'jack_analyzer/token'
require_relative 'jack_analyzer/tokenizer'
require_relative 'jack_analyzer/xml_builder'
require_relative 'jack_analyzer/compilation_engine'

#
# Top-level driver that setup and invokes the other modules
#
module JackAnalyzer
  def self.main
    if ARGV.size > 1
      puts 'Usage: jack_analyzer [xxx.jack]'
      exit 64
    end
    if ARGV.size == 1
      path = ARGV[0]
      if File.directory?(path)
        run_dir(ARGV[0])
      else
        run_file(ARGV[0])
      end

    else
      run_prompt
    end
  end

  def self.run_file(path)
    content = File.read(path)
    run(content)
  end

  def self.run_dir(path)
    Dir["#{path}/*.jack"].each do |file|
      run_file(file)
    end
  end

  def self.run_prompt
    loop do
      p '>'
      run(STDIN.gets)
    end
  end

  def self.run(content)
    tokenizer = JackAnalyzer::Tokenizer.new(content)
    tokens = tokenizer.tokenize
    # p tokens
    # puts XmlBuilder.to_xml(tokens)
    CompilationEngine.new(tokens).parse
  end
end
