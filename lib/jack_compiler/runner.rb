module JackCompiler
  module Runner
    module_function

    def run
      if ARGV.size > 1
        puts 'Usage: jack_compiler [Xxx.jack]'
        exit 64
      end
      if ARGV.size == 1
        path = ARGV[0]
        if File.directory?(path)
          run_dir(path)
        else
          run_file(path)
        end
      end
    end

    def run_file(path)
      content = File.read(path)
      dir_name = File.dirname(path)
      base_name = File.basename(path, '.jack')
      output_path = "#{dir_name}/#{base_name}.vm"
      JackCompiler.run(content, output_path)
    end

    def run_dir(path)
      Dir["#{path}/*.jack"].each do |file|
        run_file(file)
      end
    end
  end
end
