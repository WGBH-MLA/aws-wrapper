require_relative '../lib/util/ssh_opter'
require 'optparse'

name = nil
debug = nil
zone_id = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'DNS name of ELB') do |n|
    name = n
  end
  opts.on('--zone ZONE', 'AWS Zone ID') do |z|
    zone_id = z
  end
  opts.on('--debug', 'Turn on debugging') do
    debug = true
  end
  opts.separator('Returns the ssh opts to connect to the instance behind the ELB.')
end

opt_parser.parse!(ARGV)
unless name
  STDERR.puts '--name is required'
  STDERR.puts opt_parser
  exit 1
end

prefix = /^demo\./
if name !~ prefix
  STDERR.puts 'The supplied name must start with "demo.": You should not touch production.'
  exit 1
end

puts SshOpter.new(debug: debug).ssh_opts(zone_id, name)