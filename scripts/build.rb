require_relative '../lib/util/builder'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'Name to be used for PK, EBS, DNS, etc.',
          'NAME and "demo.NAME" should not already',
          'be allocated in our DNS zone.') do |n|
    config[:name] = n
  end
  opts.on('--zone_id ZONE', 'AWS Zone ID') do |z|
    config[:zone_id] = z
  end
  opts.on('--availability_zone', 'Availability Zone') do |z|
    config[:availability_zone] = z
  end
  opts.on('--debug', 'Turn on debugging') do
    config[:debug] = true
  end
  opts.on('--skip_updates', 'Skip yum updates') do
    config[:skip_updates] = true
  end
  opts.on('--size_in_gb', 'Size of EBS volume, in GB') do |s|
    config[:size_in_gb] = s
  end
  opts.separator('When run, two EC2/ELB pairs are created, along with DNS entries pointing to the ELBs.')
  opts.separator('When this script completes, elb_swap can be run.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name, :size_in_gb])

Builder.new(debug: config[:debug], availability_zone: config[:availability_zone]).build(config[:zone_id], config[:name], config[:size_in_gb], config[:skip_updates])
