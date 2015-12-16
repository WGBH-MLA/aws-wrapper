require_relative '../lib/util/destroyer'
require_relative '../lib/script_helper'
require 'optparse'

config = {}
ScriptHelper.read_defaults(config)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'NAME should be a CNAME managed by AWS, among other things') do |n|
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
  opts.separator('When run, all the AWS stuff for this name is deleted, after a prompt.')
end

ScriptHelper.read_args(config, opt_parser, [:availability_zone, :zone_id, :name])

print "Really delete everything relating to #{config[:name]}? Reenter to confirm: "
unless gets.strip == config[:name]
  warn 'Quit without touching anything.'
  exit 1
end

Destroyer.new(debug: config[:debug], availability_zone: config[:availability_zone])
  .destroy(config[:zone_id], config[:name])
