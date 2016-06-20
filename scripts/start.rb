require_relative '../lib/util/starter_stopper'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  ScriptHelper.one_arg_opts(
    opts, config,
    name: 'Name of instance to start',
    availability_zone: 'Availability Zone'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    debug: 'Turn on debug logging'
  )
  opts.separator('Restarts a stopped instance.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :name])

StarterStopper.new(debug: config[:debug], availability_zone: config[:availability_zone])
  .start(config[:name])
