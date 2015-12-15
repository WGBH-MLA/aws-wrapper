require_relative '../lib/util/lister'
require_relative '../lib/script_helper'
require 'optparse'
require 'json'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'Name to be used for PK, EBS, DNS, etc.') do |n|
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
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name])

puts JSON.pretty_generate(Lister.new(debug: config[:debug], availability_zone: config[:availability_zone]).list(config[:zone_id], config[:name]))
