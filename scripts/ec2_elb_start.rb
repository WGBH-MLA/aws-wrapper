require_relative '../lib/ec2_elb_starter'
require 'optparse'
require 'ostruct'
require 'optparse/time'
require 'pp'

name = nil
debug = false
zone_id = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'Name to be used for PK, EBS, DNS, etc.',
                         'NAME and "demo.NAME" should not already',
                         'be allocated in our DNS zone.') do |n|
    name = n
  end
  opts.on('--zone ZONE', 'AWS Zone ID') do |z|
    zone_id = z
  end
  opts.on('--debug', 'Turn on debugging') do
    debug = true
  end
  opts.separator('When run, two EC2/ELB pairs are created, along with DNS entries pointing to the ELBs.')
  opts.separator('When this script completes, elb_swap can be run.')
end

opt_parser.parse!(ARGV)
unless name
  puts '--name is missing'
  puts opt_parser
  exit 1
end

Ec2ElbStarter.new(debug: debug).start(zone_id, name)