require_relative '../lib/util/ec2_elb_starter'
require_relative '../lib/script_helper'
require 'optparse'

name = debug = zone_id = nil
ScriptHelper.read_config(binding)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'Name to be used for PK, EBS, DNS, etc.',
                         'NAME and "demo.NAME" should not already',
                         'be allocated in our DNS zone.') do |n|
    name = n
  end
  opts.on('--zone_id ZONE', 'AWS Zone ID') do |z|
    zone_id = z
  end
  opts.on('--debug', 'Turn on debugging') do
    debug = true
  end
  opts.separator('When run, two EC2/ELB pairs are created, along with DNS entries pointing to the ELBs.')
  opts.separator('When this script completes, elb_swap can be run.')
end

opt_parser.parse!(ARGV)
unless name && zone_id
  STDERR.puts '--name and --zone_id are required'
  STDERR.puts opt_parser
  exit 1
end

Ec2ElbStarter.new(debug: debug).start(zone_id, name)