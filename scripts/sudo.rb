require_relative '../lib/util/sudoer'
require_relative '../lib/script_helper'
require 'optparse'

name = debug = availability_zone = zone_id = command = nil
ScriptHelper.read_config(binding)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'A demo.* name') do |n|
    name = n
  end
  opts.on('--command COMMAND', 'A command to run as sudo on the remote machine') do |c|
    command = c
  end
  opts.on('--debug', 'Turn on debugging') do
    debug = true
  end
  opts.separator('SSH and do what needs to be done.')
end

opt_parser.parse!(ARGV)
unless name && command
  STDERR.puts '--name and --command are required'
  STDERR.puts opt_parser
  exit 1
end

Sudoer.new(debug: debug, availability_zone: availability_zone).sudo(zone_id, name, command)