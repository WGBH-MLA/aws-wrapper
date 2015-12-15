require_relative '../lib/util/swapper'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'NAME should be a CNAME managed by AWS,',
          'resolve to an AWS ELB with one EC2 instance behind it,',
          'and "demo.NAME" should resolve to a separate parallel ELB.') do |n|
    config[:name] = n
  end
  opts.on('--zone_id ZONE', 'AWS Zone ID') do |z|
    config[:zone_id] = z
  end
  opts.on('--availability_zone', 'Availability Zone') do |z|
    config[:availability_zone] = z
  end
  opts.on('--mount_path', 'Path for EBS') do |m|
    config[:mount_path] = m
  end
  opts.on('--debug', 'Turn on debugging') do
    config[:debug] = true
  end
  opts.separator('When run, the instances behind the two load balancers are swapped.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name, :mount_path])

Swapper.new(debug: config[:debug], availability_zone: config[:availability_zone]).swap(config[:zone_id], config[:name], config[:mount_path])
