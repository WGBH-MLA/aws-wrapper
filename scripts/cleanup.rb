require_relative '../lib/util/cleanuper'
require 'optparse'

name = nil
debug = false
zone_id = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones
# TODO: Maybe a git-ignored config file? or ~/.aws?

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'NAME should be a CNAME managed by AWS, among other things') do |n|
    name = n
  end
  opts.on('--zone ZONE', 'AWS Zone ID') do |z|
    zone_id = z
  end
  opts.on('--debug', 'Turn on debugging') do
    debug = true
  end
  opts.separator('When run, all the AWS stuff for this name is deleted, after a prompt.')
end

opt_parser.parse!(ARGV)
unless name
  puts '--name is missing'
  puts opt_parser
  exit 1
end

print "Really delete everything relating to #{name}? Reenter to confirm: "
unless gets.strip == name
  puts 'Quit without touching anything.'
  exit 1
end 

Cleanuper.new(debug: debug).cleanup(zone_id, name)