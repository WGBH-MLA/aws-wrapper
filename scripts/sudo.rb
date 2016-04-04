require_relative '../lib/util/sudoer'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  ScriptHelper.one_arg_opts(
    opts, config,
    name: 'Name to be used for PK, EBS, DNS, etc.',
    command: 'A command to run as sudo on the remote machine'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    debug: 'Turn on debug logging'
  )
  opts.separator('SSH and sudo what needs to be sudone.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_name, :name, :command])

Sudoer.new(debug: config[:debug], availability_zone: config[:availability_zone])
  .sudo(config[:zone_name], config[:name], config[:command])
