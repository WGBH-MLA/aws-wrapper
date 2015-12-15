require 'yaml'

module ScriptHelper
  YAML_PATH = File.absolute_path(__dir__ + '/../scripts/defaults.yml')

  def self.read_defaults(config)
    begin
      defaults = YAML.load_file(YAML_PATH)
    rescue
      warn "Error reading config file. Copy template to #{YAML_PATH}."
      warn "#{$ERROR_INFO} at #{$ERROR_POSITION.first}"
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
      warn $ERROR_INFO
      warn opt_parser
      exit 1
    end
    unless ARGV.empty?
      warn "Unexpected argument '#{ARGV.join(' ')}'"
      warn opt_parser
      exit 1
    end
    unless (required - config.keys).empty?
      required_string = required.map { |k| "--#{k}" }.join(', ')
      warn "#{required_string} are required, either in #{YAML_PATH} or as arguments."
      warn opt_parser
      exit 1
    end
  end
end
