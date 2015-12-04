require_relative '../lib/util/cleanuper'
require_relative '../lib/script_helper'
require 'optparse'

name = debug = zone_id = nil
ScriptHelper.read_config(binding)

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'NAME should be a CNAME managed by AWS, among other things') do |n|
    name = n
  end
  opts.on('--zone_id ZONE', 'AWS Zone ID') do |z|
    zone_id = z
  end
  opts.on('--debug', 'Turn on debugging') do
    debug = true
  end
  opts.separator('When run, all the AWS stuff for this name is deleted, after a prompt.')
end

opt_parser.parse!(ARGV)
unless name && zone_id
  STDERR.puts '--name and --zone_id are required'
  STDERR.puts opt_parser
  exit 1
end

print "Really delete everything relating to #{name}? Reenter to confirm: "
unless gets.strip == name
  STDERR.puts 'Quit without touching anything.'
  exit 1
end 

Cleanuper.new(debug: debug).cleanup(zone_id, name)