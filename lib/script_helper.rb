require 'yaml'

module ScriptHelper
  def self.read_config(binding)
    YAML.load_file(__dir__+'/../scripts/config.yml').each do |key, value|
      binding.local_variable_set(key.to_sym, value)
    end
  end
end
