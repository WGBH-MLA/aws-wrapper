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
    zone_id: 'AWS Zone ID',
    availability_zone: 'Availability Zone',
    size_in_gb: 'Size in GB',
    device_name: 'Device for EBS',
    mount_path: 'Path for EBS',
    instance_type: 'EC2 instance type',
    snapshot_id: 'Snapshot ID of attached volume',
    image_id: 'Amazon machine image ID'
  )
  ScriptHelper.no_arg_opts(
    opts, config,
    debug: 'Turn on debug logging',
    skip_updates: 'Skip updates'
  )
  opts.separator('When run, two EC2/ELB pairs are created, along with DNS entries pointing to the ELBs.')
  opts.separator('When this script completes, swap can be run.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name, :size_in_gb, :device_name, :mount_path, :instance_type])

Builder.new(debug: config[:debug], availability_zone: config[:availability_zone])
  .build(config)
