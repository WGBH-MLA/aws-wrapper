require_relative '../lib/util/swapper'
require_relative '../lib/util/rsyncer'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  ScriptHelper.one_arg_opts(
    opts, config,
    name: 'Name to be used for PK, EBS, DNS, etc.',
    zone_id: 'AWS Zone ID',
    availability_zone: 'Availability Zone',
    device_name: 'Device for EBS',
    mount_path: 'Path for EBS'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    debug: 'Turn on debug logging'
  )
  opts.separator('When run, the instances behind the two load balancers are swapped.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name, :mount_path, :device_name])

Swapper.new(debug: config[:debug], availability_zone: config[:availability_zone])
  .swap(config[:zone_id], config[:name], config[:device_name])
Rsyncer.new(debug: config[:debug], availability_zone: config[:availability_zone])
  .rsync(config[:zone_id], config[:name], config[:mount_path])
