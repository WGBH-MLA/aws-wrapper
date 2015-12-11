require 'yaml'

module ScriptHelper
  
  YAML_PATH = File.absolute_path(__dir__+'/../scripts/defaults.yml')
  
  def self.read_defaults(config)
    begin
      defaults = YAML.load_file(YAML_PATH)
    rescue 
      STDERR.puts("Error reading config file. Copy template to #{YAML_PATH}.")
      STDERR.puts("#{$!} at #{$@.first}")
      exit 1
    end
    defaults.each do |key, value|
      config[key.to_sym] = value
    end
  end
  
  def self.read_args(config, opt_parser, required)
    begin
      opt_parser.parse!(ARGV)
    rescue OptionParser::InvalidOption
      STDERR.puts $!
      STDERR.puts opt_parser
      exit 1
    end
    unless ARGV.empty?
      STDERR.puts "Unexpected argument '#{ARGV.join(' ')}'"
      STDERR.puts opt_parser
      exit 1
    end
    unless (required - config.keys).empty?
      required_string = required.map { |k| "--#{k}"}.join(', ')
      STDERR.puts "#{required_string} are required, either in #{YAML_PATH} or as arguments"
      STDERR.puts opt_parser
      exit 1
    end 
  end
  
end
