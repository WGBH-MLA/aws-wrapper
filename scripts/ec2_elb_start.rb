require_relative '../lib/elb_swapper'

if ARGV.count != 1
  puts <<EOF
USAGE: #{File.basename(__FILE__)} NAME
  NAME and "demo.NAME" should not already be allocated in our DNS zone.

When run, two EC2/ELB pairs are created, 
along with DNS entries pointing to the ELBs.

When this script completes, elb_swap can be run.
EOF
  exit 1
end

live_name = ARGV.shift
zone_id = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones:

Ec2ElbStarter.new.start(zone_id, live_name)