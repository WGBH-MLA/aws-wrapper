require_relative '../lib/util/ssh_opter'
require_relative '../lib/script_helper'
require 'optparse'

name = debug = zone_id = availability_zone = nil
ScriptHelper.read_config(binding)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'DNS name of ELB') do |n|
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
  opts.separator('Returns the ssh opts to connect to the instance behind the ELB.')
end

opt_parser.parse!(ARGV)
unless name && zone_id
  STDERR.puts '--name and --zone_id are required'
  STDERR.puts opt_parser
  exit 1
end

prefix = /^demo\./
if name !~ prefix
  STDERR.puts 'The supplied name must start with "demo.": You should not touch production.'
  exit 1
end

puts SshOpter.new(debug: debug, availability_zone: availability_zone).ssh_opts(zone_id, name)