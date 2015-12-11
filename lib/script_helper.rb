require 'yaml'

module ScriptHelper
  
  def self.read_defaults(config)
    begin
      defaults = YAML.load_file(__dir__+'/../scripts/defaults.yml')
    rescue 
      STDERR.puts("Error reading config file. Copy from defaults.template.yml and fill in the blanks.")
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
      STDERR.puts "#{required_string} are required, either in defaults.yml or as arguments"
      STDERR.puts opt_parser
      exit 1
    end 
  end
  
end
