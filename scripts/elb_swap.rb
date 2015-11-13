require_relative '../lib/elb_swapper'

if ARGV.count != 1
  puts <<EOF
USAGE: #{File.basename(__FILE__)} NAME
  NAME should
   - be a CNAME managed by AWS.
   - resolve to an AWS ELB with one EC2 instance behind it.
   - "demo.NAME" should resolve to a separate parallel ELB.

When run, the instances behind the two load balancers are swapped.
EOF
  exit 1
end

live_name = ARGV.shift
zone_id = 'Z1JB6V9RIBL7FX' # https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones:

ElbSwapper.new.swap(zone_id, live_name)