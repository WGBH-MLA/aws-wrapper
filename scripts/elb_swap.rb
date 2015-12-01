require_relative '../lib/util/elb_swapper'
require 'optparse'

name = nil
debug = false
zone_id = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)}"
  opts.on('--name NAME', 'NAME should',
                         '- be a CNAME managed by AWS.',
                         '- resolve to an AWS ELB with one EC2 instance behind it.',
                         '- "demo.NAME" should resolve to a separate parallel ELB.') do |n|
    name = n
  end
  opts.on('--zone ZONE', 'AWS Zone ID') do |z|
    zone_id = z
  end
  opts.on('--debug', 'Turn on debugging') do
    debug = true
  end
  opts.separator('When run, the instances behind the two load balancers are swapped.')
end

opt_parser.parse!(ARGV)
unless name
  puts '--name is missing'
  puts opt_parser
  exit 1
end

ElbSwapper.new(debug: debug).swap(zone_id, name)