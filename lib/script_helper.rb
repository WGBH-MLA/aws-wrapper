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
    rescue OptionParser::InvalidOption => e
      warn e
      warn $ERROR_INFO
      warn opt_parser
      exit 1
    end
    unless ARGV.empty?
      # I think this only catches arguments without dashes at the end of the list.
      warn "unexpected argument: '#{ARGV.join(' ')}'"
      warn opt_parser
      exit 1
    end
    missing = required - config.keys
    unless missing.empty?
      required_args = missing.map { |k| "--#{k}" }.join(', ')
      warn "#{required_args} #{missing.count > 1 ? 'are' : 'is'} required, either as params, or in #{YAML_PATH}."
      warn opt_parser
      exit 1
    end
  end

  def self.one_arg_opts(opts, config, kv)
    kv.each do |key, blurb|
      flag = "--#{key}"
      dummy = "#{key.to_s.gsub(/(.*_)?/, '').upcase}"
      opts.on("#{flag} #{dummy}", blurb) do |n|
        config[key] = n
      end
    end
  end

  def self.no_arg_opts(opts, config, kv)
    kv.each do |key, blurb|
      flag = "--#{key}"
      opts.on(flag, blurb) do |_n|
        config[key] = true
      end
    end
  end
end
