require_relative '../lib/util/elb_swapper'
require_relative '../lib/script_helper'
require 'optparse'

name = debug = zone_id = availability_zone = nil
ScriptHelper.read_config(binding)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'NAME should be a CNAME managed by AWS,',
                         'resolve to an AWS ELB with one EC2 instance behind it,',
                         'and "demo.NAME" should resolve to a separate parallel ELB.') do |n|
    name = n
  end
  opts.on('--zone_id ZONE', 'AWS Zone ID') do |z|
    zone_id = z
  end
  opts.on('--availability_zone', 'Availability Zone') do |z|
    availability_zone = z
  end
  opts.on('--debug', 'Turn on debugging') do
    debug = true
  end
  opts.separator('When run, the instances behind the two load balancers are swapped.')
end

opt_parser.parse!(ARGV)
unless name && zone_id
  STDERR.puts '--name and --zone_id are required'
  STDERR.puts opt_parser
  exit 1
end

ElbSwapper.new(debug: debug, availability_zone: availability_zone).swap(zone_id, name)