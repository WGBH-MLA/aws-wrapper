require_relative '../lib/util/builder'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  ScriptHelper.one_arg_opts(
    opts, config,
    name: 'Name to be used for PK, EBS, DNS, etc.',
    zone_name: 'AWS Route 53 zone name',
    availability_zone: 'Availability Zone',
    instance_type: 'EC2 instance type',
    image_id: 'Amazon machine image ID'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    just_one: 'Create only a single instance',
    setup_load_balancer: 'Do not create instances, but instead set up ELBs for existing',
    debug: 'Turn on debug logging',
    skip_updates: 'Skip updates'
  )
  opts.separator('With "--just_one", creates a single instance.')
  opts.separator('Without "--just_one", creates a pair of instances,')
  opts.separator('typically followed by "--setup_load_balancer":')
  opts.separator('After load balancer is set up, swap can be run.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_name, :name, :instance_type])

builder = Builder.new(debug: config[:debug], availability_zone: config[:availability_zone])

if config[:setup_load_balancer]
  builder.setup_load_balancer(config)
else
  builder.build(config)
end
