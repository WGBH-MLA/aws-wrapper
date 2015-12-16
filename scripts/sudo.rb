require_relative '../lib/util/sudoer'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'A demo.* name') do |n|
    config[:name] = n
  end
  opts.on('--command COMMAND', 'A command to run as sudo on the remote machine') do |c|
    config[:command] = c
  end
  opts.on('--debug', 'Turn on debugging') do
    config[:debug] = true
  end
  opts.separator('SSH and do what needs to be done.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name, :command])

Sudoer.new(debug: config[:debug], availability_zone: config[:availability_zone])
  .sudo(config[:zone_id], config[:name], config[:command])
