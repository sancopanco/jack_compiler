require_relative 'jack_analyzer/token_type'
require_relative 'jack_analyzer/token'
require_relative 'jack_analyzer/tokenizer'

# The main JackAnalyzer driver
module JackAnalyzer
  def self.main
    if ARGV.size > 1
      puts 'Usage: jack_analyzer [xxx.jack]'
      exit 64
    end
    if ARGV.size == 1
      run_file(ARGV[0])
    else
      run_prompt
    end
  end

  def self.run_file(path)
    content = File.read(path)
    run(content)
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
    puts tokens
  end
end
