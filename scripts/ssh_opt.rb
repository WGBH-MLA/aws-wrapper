require_relative '../lib/util/ssh_opter'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'DNS name of ELB') do |n|
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
  opts.separator('Returns the ssh opts to connect to the instance behind the ELB.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name])

prefix = /^demo\./
if config[:name] !~ prefix
  STDERR.puts 'The supplied name must start with "demo.": You should not touch production.'
  exit 1
end

puts SshOpter.new(debug: config[:debug], availability_zone: config[:availability_zone]).ssh_opts(config[:zone_id], config[:name])